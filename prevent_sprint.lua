local mod_name = core.get_current_modname()

local player_data = {}

core.register_on_joinplayer(function(player)
    player_data[player:get_player_name()] = {
        liquid_cancel = core.settings:get_bool("dg_sprint_core.liquid", false),
        snowy_cancel = core.settings:get_bool("dg_sprint_core.snowy", false),
    }
end)

core.register_on_leaveplayer(function(player)
    player_data[player:get_player_name()] = nil
end)

-- Liquid cancelation
local liquid_tick = 0.3

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

dg_sprint_core.register_server_step(mod_name, "liquid_cancel", liquid_tick, function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        local p_data = player_data[player:get_player_name()]
        if p_data and p_data.liquid_cancel then
                if is_in_liquid(player) then
                    dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:liquid")
                else
                    dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:liquid")
                end
        end
    end
end)

-- Snowy cancelation
local snowy_tick = 0.2

local on_snow = function(player)
    local pos = player:get_pos()
    local node_below = core.get_node_or_nil({x = pos.x, y = pos.y + 0.2, z = pos.z })
    if node_below and node_below.name == "default:snow" then
        return true
    end
    return false
end

dg_sprint_core.register_server_step(mod_name, "snowy_cancel", snowy_tick, function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        local p_data = player_data[player:get_player_name()]
        if p_data and p_data.snowy_cancel then
            if on_snow(player) then
                dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:snowy")
            else
                dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:snowy")
            end
        end
    end
end)

dg_sprint_core.liquid_cancel = function(player, cancel)
    player_data[player:get_player_name()].liquid_cancel = cancel
end

dg_sprint_core.snowy_cancel = function(player, cancel)
    player_data[player:get_player_name()].snowy_cancel = cancel
end