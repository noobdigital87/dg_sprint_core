local server_steps = {
	mod_name = {}
}

dg_sprint_core.register_step = function(mod_name, step_name, step_interval, step_callback)  -- function(player, dtime) end
	
	-- Validate parameter types
    	assert(type(step_name) == "string", "Step name must be a string.")
    	assert(type(step_interval) == "number" and step_interval > 0, "Interval must be a positive number.")
    	assert(type(step_callback) == "function", "Callback must be a function.")

    	-- Assert that a step with the given name does not already exist
    	assert(not server_steps[mod_name][step_name], "Step with name '" .. step_name .. "' already exists!")
	
    	server_steps[modname][step_name] = {
        	interval = step_interval,
        	elapsed = 0,
        	callback = step_callback
   	}
end



-- Globalstep: iterate over all registered server steps and trigger callbacks when intervals are met.
core.register_globalstep(function(dtime)
	local players = core.get_connected_players()
	for _, player in ipairs(players) do
    		for name, tick in pairs(server_steps) do
        		tick.elapsed = tick.elapsed + dtime
			local player_data = {
				name = player:get_player_name(),
				pos = player:get_pos(),
				control = player:get_player_control(),
				control_bit = player:get_player_control_bit(),
				
			}
            		if tick.elapsed >= tick.interval then
        			tick.callback(player, player_data, dtime)
        			tick.elapsed = tick.elapsed - tick.interval
            		end
        	end
    	end
end)

dg_sprint_core.getNodeDefinition = function(player, altPos)
  --[[
    This function retrieves the node definition for a given player position.
    It checks if the node below the player (or at the specified alternative position)
    is registered in the core.registered_nodes table and returns the corresponding
    node definition if found.

    Args:
        player: The player object.
        altPos (optional): An alternative position table {x, y, z} to check instead of the player's current position.

    Returns:
        The node definition (table) if found, otherwise nil.
  ]]
	if player and type(player) == "userdata" and core.is_player(player) then
		local playerName = player:get_player_name()
    		local position = player:get_pos()
    		if altPos then
      			assert(
        			type(altPos) == "table" and
        			type(altPos.x) == "number" and
        			type(altPos.y) == "number" and
        			type(altPos.z) == "number", "[dg_lib.getNodeDefinition] Invalid alternative position"
      			)
      			position = altPos
    		end
  
    		local nodeBelow = core.get_node_or_nil(position)
  
    		if nodeBelow then
      			local nodeDefinition = core.registered_nodes[nodeBelow.name]
      			if nodeDefinition then
        			return nodeDefinition
      			end
    		end
	end
	return nil
end
