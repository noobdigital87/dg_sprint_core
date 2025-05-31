

local mod_name = core.get_current_modname()
local pova_mod = core.get_modpath("pova") and core.global_exists("pova")
local armor_mod = core.get_modpath("3d_armor") and core.global_exists("armor") and armor.def
local p_monoids = core.get_modpath("player_monoids") and core.global_exists("player_monoids")
local playerph = core.get_modpath("playerphysics")


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

------[[API V2]]-----
local players = {}

local old_fov = core.settings:get("fov") or 72

local installed_mods = {
	pova =  core.get_modpath("pova") and core.global_exists("pova"),
	player_monoids =  core.get_modpath("player_monoids") and core.global_exists("player_monoids"),
	playerphysics = core.get_modpath("playerphysics"),
}

local no_special_physics = function()
	if installed_mods.pova or installed_mods.player_monoids then
		return false
	end
	return true
end

if installed_mods.playerphysics and core.get_game_info().title == "Mineclonia" then
	core.register_on_respawnplayer(function(player)
		playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")
	end)

	core.register_on_leaveplayer(function(player)
		playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")
	end)
elseif installed_mods.playerphysics and core.get_game_info().title == "VoxeLibre" then
	core.register_on_respawnplayer(function(player)
		mcl_fovapi.remove_modifier(player, "sprint")
	end)

	core.register_on_leaveplayer(function(player)
		mcl_fovapi.remove_modifier(player, "sprint")
	end)
else
	core.register_on_respawnplayer(function(player)
		player:set_fov(old_fov, false, 0.6)
	end)

	core.register_on_leaveplayer(function(player)
		player:set_fov(0, false)
	end)
end

dg_sprint_core.v2.pool = {}
dg_sprint_core.v2.pool.speed = 0
dg_sprint_core.v2.pool.jump = 0
dg_sprint_core.v2.sprint = function(modname, player, sprinting, override_table )
		override_table = override_table or {}
		local def = player:get_physics_override()
		local name = player:get_player_name()

		if not players[name] then
			players[name] = {}
		end

		local SPEED = override_table.speed or 0
		local JUMP = override_table.jump or 0
		local PARTICLES = override_table.particles or false
		local MCL_SPEED = override_table.mcl_speed or 0
		local FOV = override_table.fov or 0
		local TRANSITION = override_table.transition or 0

		if core.get_game_info().title == "Mineclonia" or core.get_game_info().title == "VoxeLibre" then
			if MCL_SPEED == 0 then
				MCL_SPEED = mcl_sprint.SPEED
			end
		end
		if armor_mod then
			local name = player:get_player_name()
			override_table = {
				speed = armor.def[name].speed,
				jump = armor.def[name].jump,
				gravity = armor.def[name].gravity
			}
		else
			override_table = {
				speed = 1,
				jump = 1,
				gravity = 1
			}
		end
		if sprinting == true and not players[name].is_sprinting then

			dg_sprint_core.v2.pool.speed = dg_sprint_core.v2.pool.speed + SPEED
			dg_sprint_core.v2.pool.jump = dg_sprint_core.v2.pool.jump + JUMP
			if installed_mods.playerphysics and core.get_game_info().title == "Mineclonia" then
				playerphysics.add_physics_factor(player, "speed", "mcl_sprint:sprint", MCL_SPEED)
				playerphysics.add_physics_factor(player, "fov", "mcl_sprint:sprint", 1.1)
			elseif installed_mods.playerphysics and core.get_game_info().title == "VoxeLibre" then
				playerphysics.add_physics_factor(player, "speed", "mcl_sprint:sprint", MCL_SPEED)
				mcl_fovapi.apply_modifier(player, "sprint")
			elseif installed_mods.player_monoids then
				players[name].sprint = player_monoids.speed:add_change(player, def.speed + dg_sprint_core.v2.pool)
				players[name].jump = player_monoids.jump:add_change(player, def.jump + JUMP)
			elseif installed_mods.pova then
				pova.add_override(name, modname .. ":sprint", { speed = SPEED, jump = JUMP })
				pova.do_override(player)
			else
				player:set_physics_override({ speed = override_table.speed + dg_sprint_core.v2.pool.speed, jump = override_table.jump + dg_sprint_core.v2.pool.jump })
			end
			if FOV > 0 and TRANSITION ~= 0 then
				player:set_fov(old_fov + FOV, false, TRANSITION)
			end

			players[name].is_sprinting = true
		elseif sprinting == false and players[name].is_sprinting then

			dg_sprint_core.v2.pool.speed = dg_sprint_core.v2.pool.speed - SPEED
			dg_sprint_core.v2.pool.jump = dg_sprint_core.v2.pool.jump - JUMP
			if installed_mods.playerphysics and core.get_game_info().title == "Mineclonia" then
				playerphysics.remove_physics_factor(player, "speed", "mcl_sprint:sprint")
				playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")
			elseif installed_mods.playerphysics and core.get_game_info().title == "VoxeLibre" then
				playerphysics.remove_physics_factor(player, "speed", "mcl_sprint:sprint")
				mcl_fovapi.remove_modifier(player, "sprint")
			elseif installed_mods.player_monoids then
				player_monoids.speed:del_change(player, players[name].sprint)
				player_monoids.jump:del_change(player, players[name].jump)
			elseif installed_mods.pova then
				pova.del_override(name, modname ..":sprint")
				pova.do_override(player)
			else
				player:set_physics_override({ speed = override_table.speed - dg_sprint_core.v2.pool.speed, jump = override_table.jump - dg_sprint_core.v2.pool.jump })
			end
			if FOV > 0 and TRANSITION ~= 0 then
				player:set_fov(old_fov, false, TRANSITION)
			end

			players[name].is_sprinting = false
		end

		if PARTICLES and players[name].is_sprinting then
			dg_sprint_core.ShowParticles(player:get_pos())
		end

		return players[name].is_sprinting
	end

dg_sprint_core.v2.change_speed_mcl = function(speed)
		mcl_sprint.SPEED = speed
end
