local old_fov = core.settings:get("fov") or 72

core.register_on_respawnplayer(function(player)
	player:set_fov(old_fov, false, 0.6)
end)

core.register_on_leaveplayer(function(player)
	player:set_fov(0, false)
end)

dg_sprint_core.SetFov = function(player, fov_value, enable_fov, transition_time)
	if enablefov then
		if fov_value > 0 then
			player:set_fov(old_fov + fov_value, false, transition_time)
		end
	  else
		if  fov_value > 0 then
			player:set_fov(old_fov, false, transition_time)
		end
	end
end
