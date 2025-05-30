dg_sprint_core.IsPlayerHangGliding = function(player)
	local children = player:get_children()
	for _, child in ipairs(children) do
		local properties = child:get_properties()
		if properties.mesh == "hangglider.obj" then
			return true
		end
	end
	return false
end

dg_sprint_core.v2.player_is_hanggliding = dg_sprint_core.IsPlayerHangGliding
