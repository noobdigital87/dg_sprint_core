dg_sprint_core.ExtraDrainCheck = function(player)

        if not dg_sprint_core.IsMoving(player) then
		should_still_drain = false
	elseif
        	local def = dg_lib.getNodeDefinition(player, {x = pos.x, y = pos.y - 1, z = pos.z})
        	if def then
			if not def.walkable then
            			should_still_drain = false
			end
        	end
	end
	return should_still_drain
end
