local player_data = {}

local mod_name = core.get_current_modname()

local pova_mod = core.get_modpath("pova") and core.global_exists("pova")
local armor_mod = core.get_modpath("3d_armor") and core.global_exists("armor") and armor.def
local p_monoids = core.get_modpath("player_monoids") and core.global_exists("player_monoids")

local function create_pdata(player)
    return {           
        cancel_sprint_reasons = {},
        settings = {
            extra_jump = tonumber(core.settings:get("dg_sprint_core.jump")) or 0.1,   -- Additional jump power for sprinting
            extra_speed = tonumber(core.settings:get("dg_sprint_core.speed")) or 0.8, -- Additional speed for sprinting
            particles = core.settings:get_bool("dg_sprint_core.particles", true), -- Enable/disable particle effects during sprinting
        },
        states = {
            is_sprinting = false,
        }
    }
end

-- Add/Remove player data on join/leave.

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    player_data[name] = create_pdata(player)
end)


core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    player_data[name] = nil
end)

local function show_particles(pos)
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
            texture = "default_dirt.png" or "smoke_puff.png",
        })
    end
end


----------------------------------------------------------------------------------------------------------------------------------------------------------
--[[ API ]]--

dg_sprint_core.sprint = function(player, sprinting)
    local adj_name = mod_name .. ":physics"
    local p_data = player_data[player:get_player_name()]

    -- If super sprint is active, increase speed multiplier
    local speedMul = 1
    if dg_sprint_core.is_super_sprint_active(player) then
        speedMul = 1.5
    end

    -- Apply physics modifications using available mods
    if p_monoids then
        if sprinting then
            player_monoids.speed:add_change(player, 1 + p_data.settings.extra_speed * speedMul, adj_name)
            player_monoids.jump:add_change(player, 1 + p_data.settings.extra_jump, adj_name)
        else
            player_monoids.speed:del_change(player, adj_name)
            player_monoids.jump:del_change(player, adj_name)
        end
    elseif pova_mod then
        if sprinting then
            pova.add_override(player:get_player_name(), adj_name,
                    {speed = p_data.extra_speed * speedMul, jump = p_data.settings.extra_jump})
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
            def.speed = def.speed + p_data.settings.extra_speed * speedMul
            def.jump = def.jump + p_data.settings.extra_jump
        end

        player:set_physics_override(def)
    end
end
-------------------------------------------------------------------------------------------------------------------------------
--[[ SERVER STEPS ]]--

local STEPS = {
    DETECTION_STEP = {
        INTERVAL = tonumber(core.settings:get(mod_name .. ".detection_step_interval")) or 0.2,
        NAME = mod_name .. ":DETECTION_STEP",
        CALLBACK = function(player, dtime)

            local p_name = player:get_player_name()
            local p_data = player_data[p_name]
            
            if not p_data then return end
            
            local cancel_active = false
            
            if p_data.cancel_sprint_reasons then
                for reason, _ in pairs(p_data.cancel_sprint_reasons) do
                    cancel_active = true
                    break
                end
            end
        
            local key_detected =  dg_sprint_core.is_key_detected(player) and not player:get_attach() and not cancel_active
        
            if key_detected then
                p_data.states.is_sprinting = true
            else
                p_data.states.is_sprinting = false
            end
        end
            
    },
    SPRINT_STEP = {
        INTERVAL = tonumber(core.settings:get(mod_name .. ".sprint_step_interval")) or 0.5,
        NAME = mod_name .. ":SPRINT_STEP",
        CALLBACK = function(player, dtime)
            if dg_sprint_core.is_sprinting(player) then
                dg_sprint_core.sprint(player, true)
                
            else
                dg_sprint_core.sprint(player, false)
            end
        end
    },
    PARTICLE_STEP = {
        INTERVAL = tonumber(core.settings:get(mod_name .. ".particle_step_interval")) or 0.5,
        NAME = mod_name .. ":PARTICLE_STEP",
        CALLBACK = function(player, dtime)
            local p_name = player:get_player_name()
            local p_data = player_data[p_name]
            if not p_data then return end
            if p_data.settings.particles and p_data.states.is_sprinting then
                local pos = player:get_pos()
                show_particles(pos)
            end
        end
    }
}

for _, step in pairs(STEPS) do
    dg_sprint_core.register_server_step(step.NAME, step.INTERVAL, step.CALLBACK)
end


-----------------------------------------------------------------------------------------
--[[ API ]]--

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

dg_sprint_core.set_speed = function(player, extra_speed)
    local name = player:get_player_name()
    if player_data[name] then
        player_data[name].extra_speed = extra_speed
    end
end

dg_sprint_core.set_jump = function(player, extra_jump)
    local name = player:get_player_name()
    if player_data[name] then
        player_data[name].extra_jump = extra_jump
    end
end

dg_sprint_core.enable_particles = function(player, enable)
    local name = player:get_player_name()
    if player_data[name] then
        player_data[name].settings.particles = enable
    end
end

dg_sprint_core.is_sprinting = function(player)
local name = player:get_player_name()
local p_data = player_data[name]
    if p_data then
        if p_data.states.is_sprinting then
            return true
        end
    end
    return false
end



