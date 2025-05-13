--[[
    Author: DiGiTaLNoOb
    Description: A mod that adds sprinting functionality to Minetest with API.
]]--

-- Table to store sprint-related data for each connected player
local player_data = {}

-- Server tick interval (default value 0.5 seconds if not set in settings)
local server_tick = tonumber(core.settings:get("dg_sprint_core.tick")) or 0.5

-- Get current mod name for namespacing our server step registrations
local mod_name = core.get_current_modname()

-- Main table for our sprint mod API
dg_sprint_core = {}

--[[ 
    Create initial player sprint data.
    This includes flags for sprinting state, key inputs and configurable parameters
    like extra speed/jump, tap interval for double tap, particle effects and supersprint.
]]
local function create_pdata(player)
    return {
        is_sprinting = false,              -- Is the player currently sprinting?
        key_detected = false,              -- Has the sprint key been detected?
        cancel_sprint_reasons = {},        -- Reasons to cancel sprinting (e.g., attached to something)
        aux1 = core.settings:get_bool("dg_sprint_core.aux1", true),           -- Auxiliary sprint key enabled from settings
        double_tap = core.settings:get_bool("dg_sprint_core.double_tap", true), -- Enable double-tap to sprint
        particles = core.settings:get_bool("dg_sprint_core.particles", true),   -- Enable sprint particles effect
        enable_ssprint = core.settings:get_bool("dg_sprint_core.supersprint", true), -- Enable super sprint (further speed boost)
        last_tap_time = 0,                 -- Timestamp of the last tap (for double-tap detection)
        is_holding = false,                -- Is the sprint key being held down?
        aux_pressed = false,               -- Flag when auxiliary key is pressed
        extra_jump = tonumber(core.settings:get("dg_sprint_core.jump")) or 0.1,   -- Additional jump power for sprinting
        extra_speed = tonumber(core.settings:get("dg_sprint_core.speed")) or 0.8, -- Additional speed for sprinting
        tap_interval = tonumber(core.settings:get("dg_sprint_core.tap_interval")) or 0.5,  -- Maximum interval between taps for double tap
        super_sprint = false,              -- Flag for super sprint mode (toggleable using left+right press)
        super_toggle_press = false,        -- Prevents multiple toggles on single press
    }
end

-- On player join: initialize their sprint data.
core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    player_data[name] = create_pdata(player)
end)

-- On player leave: remove the stored sprint data.
core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    player_data[name] = nil
end)

-- Table to store scheduled server step functions.
local server_steps = {}

--[[ 
    Register a custom server step (periodic callback).
    mod_name and name are concatenated for namespacing; interval is the callback period,
    and callback is the function to be executed.
]]
dg_sprint_core.register_server_step = function(mod_name, name, interval, callback)
    local adj_name = mod_name .. ":" .. name
    server_steps[adj_name] = {
        interval = interval,
        elapsed = 0,
        callback = callback
    }
end

-- Globalstep: iterate over all registered server steps and trigger callbacks when intervals are met.
core.register_globalstep(function(dtime)
    for name, tick in pairs(server_steps) do
        tick.elapsed = tick.elapsed + dtime
        if tick.elapsed >= tick.interval then
            tick.callback(tick.elapsed)
            tick.elapsed = tick.elapsed - tick.interval
        end
    end
end)

--[[ 
    Server step to handle key inputs for sprint detection.
    Runs every 0.1 seconds and sets flags based on player control bits.
    It also checks for the supersprint toggle when both left and right keys are pressed.
]]
dg_sprint_core.register_server_step(mod_name, "key_step", 0.1, function(current_time)
    for _, player in ipairs(core.get_connected_players()) do
        local p_name = player:get_player_name()
        local p_data = player_data[p_name]
        local p_control_bit = player:get_player_control_bits()
        local current_time_us = core.get_us_time() / 1e6
        if not p_data then return end

        -- Check for aux1 sprint key (represented by control bit 33)
        if p_control_bit == 33 and p_data.aux1 then
            p_data.detected = true
            p_data.is_holding = false
            p_data.aux_pressed = true
        -- If not using double tap and key equals 1 (typical jump key), then disable sprint detection
        elseif p_control_bit == 1 and not p_data.double_tap then
            p_data.detected = false
            p_data.is_holding = false
            p_data.aux_pressed = false
        -- Using double tap method: detect successive taps within the tap interval
        elseif p_control_bit == 1 and p_data.double_tap then
            if not p_data.is_holding then
                if current_time_us - p_data.last_tap_time < p_data.tap_interval then
                    p_data.detected = true
                end
                p_data.last_tap_time = current_time_us
                p_data.is_holding = true
            end
            p_data.aux_pressed = false
        -- When no control or when control bit is 0/32, reset detection flags.
        elseif p_control_bit == 0 or p_control_bit == 32 then
            p_data.detected = false
            p_data.is_holding = false
            p_data.aux_pressed = false
        end

        -- Check for super sprint toggle: if supersprint is enabled and both left and right are pressed
        local controls = player:get_player_control()
        if p_data.enable_ssprint and (controls.left and controls.right) then
            if not p_data.super_toggle_press then
                p_data.super_sprint = not p_data.super_sprint
                p_data.super_toggle_press = true
            end
        else
            p_data.super_toggle_press = false
        end
    end
end)

--[[ 
    Check for additional mods that modify player physics.
    pova, armor_mod, and player_monoids are optional dependencies that alter how physics
    (speed and jump) are overridden.
]]
local pova_mod = core.get_modpath("pova") and core.global_exists("pova")
local armor_mod = core.get_modpath("3d_armor") and core.global_exists("armor") and armor.def
local p_monoids = core.get_modpath("player_monoids") and core.global_exists("player_monoids")

--[[ 
    Toggle sprinting for a player.
    This function sets sprint physics (speed & jump) based on whether sprinting is activated,
    using different modifications depending on the available mods. Also handles particle effects.
]]
dg_sprint_core.sprint = function(player, sprinting)
    local adj_name = "dg_sprint_core:physics"
    local p_data = player_data[player:get_player_name()]

    p_data.is_sprinting = sprinting

    -- If super sprint is active, increase speed multiplier
    local speedMul = 1
    if p_data.super_sprint then
        speedMul = 1.5
    end

    -- Apply physics modifications using available mods
    if p_monoids then
        if sprinting then
            player_monoids.speed:add_change(player, 1 + p_data.extra_speed * speedMul, adj_name)
            player_monoids.jump:add_change(player, 1 + p_data.extra_jump, adj_name)
        else
            player_monoids.speed:del_change(player, adj_name)
            player_monoids.jump:del_change(player, adj_name)
        end
    elseif pova_mod then
        if sprinting then
            pova.add_override(player:get_player_name(), adj_name,
                    {speed = p_data.extra_speed * speedMul, jump = p_data.extra_jump})
            pova.do_override(player)
        else
            pova.del_override(player:get_player_name(), adj_name)
            pova.do_override(player)
        end
    else
        local def
        if armor_mod then
            local name = player:get_player_name()
            def = {
                speed = armor.def[name].speed,
                jump = armor.def[name].jump,
                gravity = armor.def[name].gravity
            }
        else
            def = {
                speed = 1,
                jump = 1,
                gravity = 1
            }
        end

        if sprinting then
            def.speed = def.speed + p_data.extra_speed * speedMul
            def.jump = def.jump + p_data.extra_jump
        end

        player:set_physics_override(def)
    end

    -- Spawn sprint particle effects if enabled and player is sprinting.
    if p_data.particles and sprinting then
        local pos = player:get_pos()

        local node = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})

        local def = minetest.registered_nodes[node.name] or {}
        local drawtype = def.drawtype

        -- Only add particles when not above air or liquid nodes.
        if drawtype ~= "airlike" and drawtype ~= "liquid" and drawtype ~= "flowingliquid" then
            minetest.add_particlespawner({
                amount = 5,
                time = 0.01,
                minpos = {x = pos.x - 0.25, y = pos.y + 0.1, z = pos.z - 0.25},
                maxpos = {x = pos.x + 0.25, y = pos.y + 0.1, z = pos.z + 0.25},
                minvel = {x = -0.5, y = 1, z = -0.5},
                maxvel = {x = 0.5, y = 2, z = 0.5},
                minacc = {x = 0, y = -5, z = 0},
                maxacc = {x = 0, y = -12, z = 0},
                minexptime = 0.25,
                maxexptime = 0.5,
                minsize = 0.5,
                maxsize = 1.0,
                vertical = false,
                collisiondetection = false,
                texture = "default_dirt.png" or "smoke_puff.png", -- Texture for the particle
            })
        end
    end
end

--[[ 
    Register a server step (using our previously defined server_tick interval)
    to update each player's sprint status based on:
      - Detected sprint key press (p_data.detected)
      - Whether the player is attached (e.g., riding an object)
      - Any active sprint cancel reasons.
]]
dg_sprint_core.register_server_step(mod_name, "sprint_step", server_tick, function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        local p_name = player:get_player_name()
        local p_data = player_data[p_name]
        local detected = p_data and p_data.detected

        local cancel_active = false
        if p_data.cancel_sprint_reasons then
            for reason, _ in pairs(p_data.cancel_sprint_reasons) do
                cancel_active = true
                break
            end
        end

        local can_sprint = detected and not player:get_attach() and not cancel_active

        if can_sprint then
            dg_sprint_core.sprint(player, true)
        else
            dg_sprint_core.sprint(player, false)
        end
    end
end)

--[[ 
    Mark or unmark a reason to cancel sprinting for a player.
    Other mods or game events can call this to temporarily disable sprinting.
]]
dg_sprint_core.cancel_sprint = function(player, cancel, reason)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.cancel_sprint_reasons = p_data.cancel_sprint_reasons or {}
        if cancel then
            p_data.cancel_sprint_reasons[reason] = true
        else
            p_data.cancel_sprint_reasons[reason] = nil
        end
    end
end

-- Return whether the player is currently sprinting.
dg_sprint_core.is_sprinting = function(player)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    return p_data and p_data.is_sprinting or false
end

--[[ 
    Helper function to update the extra speed boost for sprinting.
    Other mods or settings can use this to adjust sprint acceleration.
]]
dg_sprint_core.set_speed = function(player, extra_speed)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.extra_speed = extra_speed
    end
end

-- Helper function to update the extra jump boost for sprinting.
dg_sprint_core.set_jump = function(player, extra_jump)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.extra_jump = extra_jump
    end
end

-- Helper function to enable or disable particle effects for sprinting.
dg_sprint_core.set_particles = function(player, value)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.particles_enabled = value
    end
end

-- Helper function to set the aux1 (auxiliary sprint key) option.
dg_sprint_core.set_aux1 = function(player, value)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.aux1 = value
    end
end

-- Helper function to enable or disable the double-tap sprint option.
dg_sprint_core.set_double_tap = function(player, value)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.double_tap = value
    end
end

-- Return whether the player currently has supersprint enabled.
dg_sprint_core.is_supersprinting = function(player)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    return p_data and p_data.super_sprint or false
end
