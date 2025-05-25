dg_sprint_core.ExtraSprintCheck = function(player)
	local should_still_sprint = true
	if not dg_sprint_core.IsMoving(player) or not player:get_attach() then
		should_still_sprint = false
	end
	return should_still_sprint
end
