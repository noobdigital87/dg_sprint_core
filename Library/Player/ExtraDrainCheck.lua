dg_sprint_core.ExtraDrainCheck = function(player)
	local should_still_drain = true
        if not dg_sprint_core.IsMoving(player) then
		should_still_drain = false
	elseif
		local pos = player:get_pos()
   		if not dg_sprint_core.IsNodeWalkable(pos) or not dg_sprint_core.IsNodeLiquid(pos) then
			should_still_drain = false
		else
	end
	return should_still_drain
end
