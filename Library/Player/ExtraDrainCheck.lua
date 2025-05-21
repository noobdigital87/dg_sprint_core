dg_sprint_core.ExtraDrainCheck = function(player)
	local should_still_drain = true
        if not dg_sprint_core.IsMoving(player) then
		should_still_drain = false
	elseif
		local pos = player:get_pos()
   		if not dg_sprint_core.IsNodeWalkable(player, {x=pos.x, y=pos.y-1,z=pos.z}) or not dg_sprint_core.IsNodeLiquid(player) then
			should_still_drain = false
		end
	end
	return should_still_drain
end
