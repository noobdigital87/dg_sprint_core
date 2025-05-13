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
dg_sprint_core.register_server_step(mod_name, "liquid_cancel", liquid_tick, function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        p_data = player_data[player:get_player_name()]
        if p_data and p_data.liquid_cancel then
            local p_pos = player:get_pos()
            local node = core.get_node_or_nil(pos)
            if node then
                local def = core.registered_nodes[node.name]
                local drawtype = def.drawtype
                if drawtype == "liquid" and drawtype == "flowingliquid" then
                    dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:liquid")
                else
                    dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:liquid")
                end
            end
        end
    end
end)

-- Snowy cancelation
local snowy_tick = 0.2
dg_sprint_core.register_server_step(mod_name, "snowy_cancel", snowy_tick, function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        p_data = player_data[player:get_player_name()]
        if p_data and p_data.snowy_cancel then
            local p_pos = player:get_pos()
            local node = core.get_node_or_nil({x = p_pos.x, y = p_pos.y + 0.2, z = p_pos.z})
            if node then
                local def_group = core.registered_nodes[node.name].groups

                if def_group == "snowy" then
                    dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:snowy")
                else
                    dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:snowy")
                end
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