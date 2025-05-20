local server_steps = {}

dg_sprint_core.register_step = function(mod_name, step_name, step_interval, step_callback)  -- function(player, dtime) end
	
	-- Validate parameter types
    	assert(type(name) == "string", "Step name must be a string.")
    	assert(type(interval) == "number" and interval > 0, "Interval must be a positive number.")
    	assert(type(callback) == "function", "Callback must be a function.")

    	-- Assert that a step with the given name does not already exist
    	assert(not server_steps[name], "Step with name '" .. name .. "' already exists!")
	
    	server_steps[modname.. ":" .. step_name] = {
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
