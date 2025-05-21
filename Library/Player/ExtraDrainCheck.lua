dg_sprint_core.ExtraDrainCheck = function(player)
	p_pos = player:get_pos()
	local controls = player:get_player_control()
        local is_moving = controls.up or controls.down or controls.left or controls.right
        local velocity = player:get_velocity()  
        velocity.y = 0
	local horizontal_speed = vector.length(velocity)
	local should_still_drain = true
        local has_velocity = horizontal_speed > 0.05
        if not (is_moving and has_velocity) then
		should_still_drain = false
	end
	return should_still_drain
end
