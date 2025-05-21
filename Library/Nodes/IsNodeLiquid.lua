dg_sprint_core.IsNodeLiquid = function(player, altPos)
	local def = dg_sprint_core.getNodeDefinition(player, altPos)
	if def and ( def.drawtype == "liquid" or def.drawtype == "flowingliquid" )
		return true
	end
	return false
end
