dg_sprint_core.IsNodeWalkable = function(player, altPos)
	local def = dg_sprint_core.getNodeDefinition(player, altPos)
	if def and def.walkable then
		return true
	end
	return false
end
