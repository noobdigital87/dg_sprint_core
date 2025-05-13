local mod_name = core.get_current_modname()

local liquid_tick = 0.3

dg_sprint_core.register_server_step(mod_name, "liquid_cancel", liquid_tick, function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
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
end)