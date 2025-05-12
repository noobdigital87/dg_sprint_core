--[[
    Author: DiGiTaLNoOb
    Description: A mod that adds sprinting functionality to Minetest with API.
]]--

local player_data = {}
local server_tick = tonumber(core.settings:get("dg_sprint_core.tick")) or 0.5
local mod_name = core.get_current_modname()
dg_sprint_core = {}

local function create_pdata(player)
    return {
        is_sprinting = false,
        key_detected = false,
        cancel_sprint_reasons = {},  -- New table to hold cancellation reasons.
        aux1 = core.settings:get_bool("dg_sprint_core.aux1", true),
        double_tap = core.settings:get_bool("dg_sprint_core.double_tap", true),
        particles = core.settings:get_bool("dg_sprint_core.particles", true),
        enable_ssprint = core.settings:get_bool("dg_sprint_core.supersprint", true),
        last_tap_time = 0,
        is_holding = false,
        aux_pressed = false,
        extra_jump = tonumber(core.settings:get("dg_sprint_core.jump")) or 0.1,
        extra_speed = tonumber(core.settings:get("dg_sprint_core.speed")) or 0.8,
        tap_interval = tonumber(core.settings:get("dg_sprint_core.tap_interval")) or 0.5,
        super_sprint = false,         -- NEW: super sprint toggle state
        super_toggle_press = false,   -- NEW: helper flag for toggle detection
    }
end

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    player_data[name] = create_pdata(player)
end)

core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    player_data[name] = nil
end)

local server_steps = {}

dg_sprint_core.register_server_step = function(mod_name, name, interval, callback)
    local adj_name = mod_name .. ":" .. name
    server_steps[adj_name] = {
        interval = interval,
        elapsed = 0,
        callback = callback
    }
end

core.register_globalstep(function(dtime)
    for name, tick in pairs(server_steps) do
        tick.elapsed = tick.elapsed + dtime
        if tick.elapsed >= tick.interval then
            tick.callback(tick.elapsed)
            tick.elapsed = tick.elapsed - tick.interval
        end
    end
end)

dg_sprint_core.register_server_step(mod_name, "key_step", 0.1, function(current_time)
    for _, player in ipairs(core.get_connected_players()) do
        local p_name = player:get_player_name()
        local p_data = player_data[p_name]
        local p_control_bit = player:get_player_control_bits()
        local current_time_us = core.get_us_time() / 1e6
        if not p_data then return end

        if p_control_bit == 33 and p_data.aux1 then
            p_data.detected = true
            p_data.is_holding = false
            p_data.aux_pressed = true
        elseif p_control_bit == 1 and not p_data.double_tap then
            p_data.detected = false
            p_data.is_holding = false
            p_data.aux_pressed = false
        elseif p_control_bit == 1 and p_data.double_tap then
            if not p_data.is_holding then
                if current_time_us - p_data.last_tap_time < p_data.tap_interval then
                    p_data.detected = true
                end
                p_data.last_tap_time = current_time_us
                p_data.is_holding = true
            end
            p_data.aux_pressed = false
        elseif p_control_bit == 0 or p_control_bit == 32 then
            p_data.detected = false
            p_data.is_holding = false
            p_data.aux_pressed = false
        end

        -- NEW: Check for left and right keys together to toggle super sprint.
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

local pova_mod = core.get_modpath("pova") and core.global_exists("pova")
local armor_mod = core.get_modpath("3d_armor") and core.global_exists("armor") and armor.def
local p_monoids = core.get_modpath("player_monoids") and core.global_exists("player_monoids")

dg_sprint_core.sprint = function(player, sprinting)
     local adj_name = "dg_sprint_core:physics"
     local p_data = player_data[player:get_player_name()]

     p_data.is_sprinting = sprinting

     -- NEW: Calculate sprint speed multiplier based on super sprint toggle.
     local speedMul = 1
     if p_data.super_sprint then
         speedMul = 1.5
     end

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
                speed=armor.def[name].speed,
                jump=armor.def[name].jump,
                gravity=armor.def[name].gravity
            }
        else
            def = {
                speed=1,
                jump=1,
                gravity=1
            }
        end

        if sprinting then
            def.speed = def.speed + p_data.extra_speed * speedMul
            def.jump = def.jump + p_data.extra_jump
        end

        player:set_physics_override(def)
    end

    if p_data.particles and sprinting then
        local pos = player:get_pos()

        local node = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})

        local def = minetest.registered_nodes[node.name] or {}
        local drawtype = def.drawtype

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
                texture = "default_dirt.png" or "smoke_puff.png",
            })
        end
    end
end

dg_sprint_core.register_server_step(mod_name, "sprint_step", server_tick, function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        local p_name = player:get_player_name()
        local p_data = player_data[p_name]
        local detected = p_data and p_data.detected

        -- Check if any cancellation reason is active.
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

dg_sprint_core.is_sprinting = function(player)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    return p_data and p_data.is_sprinting or false
end

dg_sprint_core.set_speed = function(player, extra_speed)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.extra_speed = extra_speed
    end
end

dg_sprint_core.set_jump = function(player, extra_jump)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.extra_jump = extra_jump
    end
end

dg_sprint_core.set_particles = function(player, value)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.particles_enabled = value
    end
end

dg_sprint_core.set_aux1 = function(player, value)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.aux1 = value
    end
end

dg_sprint_core.set_double_tap = function(player, value)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    if p_data then
        p_data.double_tap = value
    end
end

dg_sprint_core.is_supersprinting = function(player)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    return p_data and p_data.super_sprint or false
end