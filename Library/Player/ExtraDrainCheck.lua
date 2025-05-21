dg_sprint_core.ExtraDrainCheck = function(player)	
        if not dg_sprint_core.IsMoving(player) then
		should_still_drain = false
	elseif
		local pos = player:get_pos()
   		if not dg_sprint_core.IsNodeWalkable(pos) then
		end
	end
	return should_still_drain
end
