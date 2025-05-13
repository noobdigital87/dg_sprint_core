local mod_name = core.get_current_modname()

local player_data = {}

core.register_on_joinplayer(function(player)
    player_data[player:get_player_name()] = {
        liquid_cancel = core.settings:get_bool("dg_sprint_core.liquid", false),
        snowy_cancel = core.settings:get_bool("dg_sprint_core.snowy", false),
        hp_cancel = core.settings:get_bool("dg_sprint_core.hp", false),
        hp_threshold = tonumber(core.settings:get("dg_sprint_core.hp_threshold")) or 6.0,
        climbable_cancel = core.settings:get_bool("dg_sprint_core.climbable", false),
        wall_cancel = core.settings:get_bool("dg_sprint_core.wall", false),
    }
end)

core.register_on_leaveplayer(function(player)
    player_data[player:get_player_name()] = nil
end)

-- Liquid cancelation
local liquid_tick = 0.5

local is_in_liquid = function(player)
    local pos = player:get_pos()
    local node_below = core.get_node_or_nil(pos)
    if node_below then
        local def = minetest.registered_nodes[node_below.name] or {}
        local drawtype = def.drawtype
        local is_liquid = drawtype == "liquid" or drawtype == "flowingliquid"
        return is_liquid
    else
        return false
    end
end

dg_sprint_core.register_server_step(mod_name .. "liquid_cancel", liquid_tick, function(player, dtime)
    local p_data = player_data[player:get_player_name()]
    if p_data and p_data.liquid_cancel then
        if is_in_liquid(player) then
            dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:liquid")
        else
            dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:liquid")
        end
    end
end)

-- Snowy cancelation
local snowy_tick = 0.5

local on_snow = function(player)
    local pos = player:get_pos()
    local node_below = core.get_node_or_nil({x = pos.x, y = pos.y + 0.2, z = pos.z })
    if node_below and node_below.name == "default:snow" then
        return true
    end
    return false
end

dg_sprint_core.register_server_step(mod_name ..  "snowy_cancel", snowy_tick, function(player, dtime)
    local p_data = player_data[player:get_player_name()]
    if p_data and p_data.snowy_cancel then
        if on_snow(player) then
            dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:snowy")
        else
            dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:snowy")
        end
    end
end)

-- Low HP cancel
local low_health_tick = 0.5
dg_sprint_core.register_server_step(mod_name ..  "low_health_cancel", low_health_tick, function(player, dtime)
    local p_data = player_data[player:get_player_name()]
    if p_data and p_data.hp_cancel and player:get_hp() < p_data.hp_threshold then
        dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:low_health")
    else
        dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:low_health")
    end
end)

-- Climbable cancelation
local climbable_tick = 0.5

local on_climbable = function(player)
    local pos = player:get_pos()
    local node_below = core.get_node_or_nil(pos)
    if node_below then
        local def = minetest.registered_nodes[node_below.name] or {}
        if def and def.climbable then
            return true
        else
            return false
        end
    end
end

dg_sprint_core.register_server_step(mod_name ..  "climbable_cancel", climbable_tick, function(player, dtime)

    local p_data = player_data[player:get_player_name()]
    if p_data and p_data.climbable_cancel then
        if on_climbable(player) then
            dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:climbable")
        else
            dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:climbable")
        end
    end
end)

-- Wall cancelation
local wall_tick = 0.1

local on_wall = function(player)
    -- Get the player's base position.
    local base_pos = player:get_pos()
    local properties = player:get_properties()
    local eye_height = (properties and properties.eye_height) or 0.5 -- Fallback in case eye_height is not set

    -- Define two positions:
    -- Lower position uses a fixed offset of 0.5.
    local lower_pos = {
        x = base_pos.x,
        y = base_pos.y + 0.5,
        z = base_pos.z
    }
    -- Upper position uses the player's eye height.
    local upper_pos = {
        x = base_pos.x,
        y = base_pos.y + eye_height,
        z = base_pos.z
    }

    -- Calculate horizontal direction (ignoring any vertical tilt).
    local angle = player:get_look_horizontal()
    local direction = vector.rotate_around_axis(
        {x = 0, y = 0, z = 1},
        {x = 0, y = 0, z = 0},
        angle
    )
    direction = vector.normalize(direction)

    -- Calculate target positions (one node ahead) for both lower and upper checks.
    local target_lower = vector.round(vector.add(lower_pos, direction))
    local target_upper = vector.round(vector.add(upper_pos, direction))

    -- Get the nodes at the target positions.
    local node_lower = minetest.get_node(target_lower)
    local node_upper = minetest.get_node(target_upper)

    -- Retrieve registered node definitions (these contain properties such as walkability).
    local reg_node_lower = minetest.registered_nodes[node_lower.name]
    local reg_node_upper = minetest.registered_nodes[node_upper.name]

    -- Check conditions for each node:

    local lower_is_wall = reg_node_lower and reg_node_lower.walkable
    local upper_is_wall = reg_node_upper and reg_node_upper.walkable

    if (lower_is_wall or upper_is_wall) then
        return true
    else
        return false
    end
end

dg_sprint_core.register_server_step(mod_name .. "wall_cancel", wall_tick, function(player, dtime)
    local p_data = player_data[player:get_player_name()]
    if p_data and p_data.wall_cancel then
        if on_wall(player) then
            dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:wall")
        else
            dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:wall")
        end
    end
end)