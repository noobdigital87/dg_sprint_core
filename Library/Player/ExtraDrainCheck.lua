dg_sprint_core.ExtraDrainCheck = function(player)
	local pos = player:get_pos()
	local controls = player:get_player_control()
        local is_moving = controls.up or controls.down or controls.left or controls.right
        local velocity = player:get_velocity()  
        velocity.y = 0
	local horizontal_speed = vector.length(velocity)
	local should_still_drain = true
        local has_velocity = horizontal_speed > 0.05
        if not (is_moving and has_velocity) then
		should_still_drain = false
	elseif then
        	local def = dg_lib.getNodeDefinition(player, {x = pos.x, y = pos.y - 1, z = pos.z})
        	if def then
			if def.walkable then
				player_data[name].on_ground = true
        		elseif not def.walkable and player_data[name].on_ground then
            			player_data[name].on_ground = false
			end
        	end
	end
	return should_still_drain
end
