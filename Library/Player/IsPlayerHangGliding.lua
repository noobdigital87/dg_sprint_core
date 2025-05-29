local mod = core.get_modpath("hangglider")
if mod then
local players = {}

dg_sprint_core.IsPlayerHangGliding = function(player)
    local name = player:get_player_name()
    return players[name].is_hanggliding == true
end

local function GetNodeDefinition(player, altPos)
	local playerName = player:get_player_name()
    	local position = player:get_pos()
    	if altPos then
      		assert(
        		type(altPos) == "table" and
        		type(altPos.x) == "number" and
        		type(altPos.y) == "number" and
        		type(altPos.z) == "number", "[dg_lib.getNodeDefinition] Invalid alternative position"
      		)
		position = altPos
    	end
  
    	local nodeBelow = core.get_node_or_nil(position)
  
    	if nodeBelow then
		local nodeDefinition = core.registered_nodes[nodeBelow.name]
      		if nodeDefinition then
        		return nodeDefinition
      		end
    	end
	return nil
end

local function IsNodeWalkable(player, altPos)
	local def = GetNodeDefinition(player, altPos)
	if def and def.walkable then
		return true
	end
	return false
end

core.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()

        if not players[name] then
            players[name] = { is_hanggliding = false, used_hangglider = false }
        end
        if players[name].used_hangglider then
            local pos = player:get_pos()

            -- Check if player is on the ground and reset hangglider usage
            if IsNodeWalkable(player, {x = pos.x, y = pos.y - 0.1, z=pos.z}) then
                players[name].used_hangglider = false
                players[name].is_hanggliding = false
                break
            end

            -- Detect if hangglider is being used
            local found_hangglider = false
            for obj in core.objects_inside_radius(pos, 1) do
                local properties = obj:get_properties()
                if properties.mesh == "hangglider.obj" then
                    found_hangglider = true
                    break
                end
            end

            if players[name].used_hangglider then
                -- Only send messages when the state changes
                if found_hangglider and not players[name].is_hanggliding then
                    players[name].is_hanggliding = true
                elseif not found_hangglider and players[name].is_hanggliding then
                    players[name].is_hanggliding = false
                    players[name].used_hangglider = false
                end
            end
        end
    end
end)

local original_on_use = minetest.registered_items["hangglider:hangglider"].on_use

minetest.override_item("hangglider:hangglider", {
    on_use = function(stack, player)
        local name = player:get_player_name()

        if not players[name] then
            players[name] = {}
        end

        players[name].used_hangglider = true

        return original_on_use(stack, player)
    end,
})
end
