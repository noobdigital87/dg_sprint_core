

local mod_name = core.get_current_modname()
local pova_mod = core.get_modpath("pova") and core.global_exists("pova")
local armor_mod = core.get_modpath("3d_armor") and core.global_exists("armor") and armor.def
local p_monoids = core.get_modpath("player_monoids") and core.global_exists("player_monoids")
local playerph = core.get_modpath("playerphysics")

if playerph and core.get_game_info().title == "mineclonia" then
	core.register_on_respawnplayer(function(player)
		playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")
	end)

	core.register_on_leaveplayer(function(player)
		playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")
	end)
end

if playerph and core.get_game_info().title == "mineclone2" then
	core.register_on_respawnplayer(function(player)
		mcl_fovapi.remove_modifier(player, "sprint")
	end)

	core.register_on_leaveplayer(function(player)
		mcl_fovapi.remove_modifier(player, "sprint")
	end)
end
----------------------------------------------------------------------------------------------------------------------------------------------------------
--[[ API ]]--

dg_sprint_core.Sprint = function(mod_name, player, sprinting, physics_table)
	-- Validate inputs.
    	assert(type(mod_name) == "string" and mod_name ~= "", "dg_sprint_core.Sprint: 'mod_name' must be a non-empty string.")
    	assert(type(sprinting) == "boolean", "dg_sprint_core.Sprint: 'sprinting' must be a boolean.")
    	assert(type(physics_table) == "table", "dg_sprint_core.Sprint: 'physics_table' must be a table.")
    	assert(type(physics_table.speed) == "number", "dg_sprint_core.Sprint: 'physics_table.speed' must be a number.")
    	assert(type(physics_table.jump) == "number", "dg_sprint_core.Sprint: 'physics_table.jump' must be a number.")

    	local adj_name = mod_name .. ":physics"
	
    	if p_monoids then
        	if sprinting then
            		player_monoids.speed:add_change(player, 1 + physics_table.speed, adj_name)
            		player_monoids.jump:add_change(player, 1 + physics_table.jump, adj_name)
        	else
            		player_monoids.speed:del_change(player, adj_name)
            		player_monoids.jump:del_change(player, adj_name)
        	end
    	elseif pova_mod then
        	if sprinting then
            		pova.add_override(player:get_player_name(), adj_name, {speed = physics_table.speed, jump = physics_table.jump})
            		pova.do_override(player)
        	else
            		pova.del_override(player:get_player_name(), adj_name)
            		pova.do_override(player)
        	end
    	else
        	local def
        	if armor_mod then
            		local name = player:get_player_name()
            		def = {
                		speed = armor.def[name].speed,
                		jump = armor.def[name].jump,
                		gravity = armor.def[name].gravity
            		}
        	else
            		def = {
                		speed = 1,
                		jump = 1,
                		gravity = 1
            		}
        	end
        	if sprinting then
            		def.speed = def.speed + physics_table.speed
            		def.jump = def.jump + physics_table.jump
        	end
        	player:set_physics_override(def)
    end
end

dg_sprint_core.VoxeLibreSprint = function(player, sprint)
	if sprint then
		playerphysics.add_physics_factor(player, "speed", "mcl_sprint:sprint", mcl_sprint.SPEED)
            	mcl_fovapi.apply_modifier(player, "sprint")
        else
            	playerphysics.remove_physics_factor(player, "speed", "mcl_sprint:sprint")
            	mcl_fovapi.remove_modifier(player, "sprint")
        end
end

dg_sprint_core.McSprint = function(player, sprinting)
	if sprinting then
		playerphysics.add_physics_factor(player, "speed", "mcl_sprint:sprint", mcl_sprint.SPEED)
		playerphysics.add_physics_factor(player, "fov", "mcl_sprint:sprint", 1.1)
	else
		playerphysics.remove_physics_factor(player, "speed", "mcl_sprint:sprint")
		playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")
	end
end

dg_sprint_core.McSpeed = function(speed)
	assert(type(speed) == "number", "dg_sprint_core.McSpeed: 'speed' must be a number.")
	mcl_sprint.SPEED = speed
end


------V2
local players = {}
local installed_mods = {
	pova =  core.get_modpath("pova") and core.global_exists("pova"),
	player_monoids =  core.get_modpath("player_monoids") and core.global_exists("player_monoids"),
	playerphysics = core.get_modpath("playerphysics"),
}
local no_special_physics = function()
	if installed_mods.pova or installed_mods.player_monoids or installed_mods.playerphysics then
		return false
	end
	return true 
end
dg_sprint_core.v2 = {
	sprint = function(modname, player, sprinting, override_table )
		if not player then return end
		if dg_sprint_core.IsPlayerHangGliding(player) and no_special_physics() then
			sprinting = false
		end
		local name = player:get_player_name()
		
		if not players[name] then
			players[name] = {}
		end
		
		local def = player:get_physics_override()
	
		if sprinting == true and not players[name].is_sprinting then
			if installed_mods.pova then
				pova.add_override(name, modname .. ":sprint", { speed = override_table.speed, jump = override_table.jump })
				pova.do_override(player)
			elseif installed_mods.player_monoids then
				players[name].sprint = player_monoids.speed:add_change(player, def.speed + override_table.speed)
				players[name].jump = player_monoids.jump:add_change(player, def.jump + override_table.jump)
			elseif installed_mods.playerphysics then
				playerphysics.add_physics_factor(player, "speed",  modname .. ":sprint", def.speed + override_table.speed)
				playerphysics.add_physics_factor(player, "jump",  modname .. ":jump", def.jump + override_table.jump)
			else
				player:set_physics_override({ speed = def.speed + SPEED_BOOST, jump = def.jump + override_table.jump })

			end
			players[name].is_sprinting = true
		elseif sprinting == false and players[name].is_sprinting then

			if installed_mods.pova then
				pova.del_override(name, modname ..":sprint")
				pova.do_override(player)
			elseif installed_mods.player_monoids then
				player_monoids.speed:del_change(player, players[name].sprint)
				player_monoids.jump:del_change(player, players[name].jump)
			elseif installed_mods.playerphysics then
				playerphysics.remove_physics_factor(player, modname ..":sprint")
				playerphysics.remove_physics_factor(player, modname ..":jump")
			else
				player:set_physics_override({ speed = def.speed - override_table.speed, jump = def.jump - override_table.jump })
			end
			players[name].is_sprinting = false
		end
		return players[name].is_sprinting
	end,
	player_is_sprinting = function(player)
		if not player then return false end
		if not players[name] then
			players[name] = { is_sprinting = false }
		end
		
		return players[name].is_sprinting
	end,
	
}
