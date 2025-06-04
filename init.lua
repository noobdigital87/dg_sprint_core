dg_sprint_core = {}

local api = dg_sprint_core

local old_fov = core.settings:get("fov") or 72

local mod = {
	
	pova = core.get_modpath("pova") and core.global_exists("pova"),
    	monoids = core.get_modpath("player_monoids") and core.global_exists("player_monoids"),
    	physics = core.get_modpath("playerphysics") and core.global_exists("playerphysics"),
    	armor = core.get_modpath("3d_armor") and core.global_exists("armor") and armor.def,
    	hangglider = core.get_modpath("hangglider"),
}

local data = {
	
	keyboard = {},
    	cancel_reasons = {},
    	server_steps = {},
    	players = {},
    	states = {},
    	physics_pool = {},
	physics_reasons = {},
}

--[[-----------------------------------------------------------------------------------------------------------
	HELPER FUNCTIONS
]]
local function summed_mod_defs()
	
	local sum = {
		speed = 0,
		jump = 0,
		gravity = 0,
	}
	
	if mod.armor then
        	sum.speed = sum.speed + (armor.def[name].speed - 1)
            	sum.jump = sum.jump + (armor.def[name].jump - 1)
            	sum.gravity = sum.gravity + (armor.def[name].gravity - 1)
	end

	return sum
end

local function get_node_definition(player, altPos)
	local playerName = player:get_player_name()
    	local position = player:get_pos()
    	local nodeBelow = core.get_node_or_nil(position)

    	if nodeBelow then
		local nodeDefinition = core.registered_nodes[nodeBelow.name]
      		if nodeDefinition then
        		return nodeDefinition
      		end
    	end

	return nil
end

local function init_data()
    	return {
        	detected = false,
        	last_tap_time = 0,
        	is_holding = false,
        	aux_pressed = false,
    	}
end

local function player_is_gliding(player)
	local children = player:get_children()
	for _, child in ipairs(children) do
		local properties = child:get_properties()
		if properties.mesh == "hangglider.obj" then
			return true
		end
	end
	return false
end

local function physics_mod_is_installed()
	if mod.pova or mod.monoids or mod.physics then
		return true
	end
	return false
end

local function player_is_moving(player)
	local p_pos = player:get_pos()

	local controls = player:get_player_control()

    	local is_moving = controls.up or controls.down or controls.left or controls.right

    	local velocity = player:get_velocity()

    	velocity.y = 0

    	local horizontal_speed = vector.length(velocity)
	local has_velocity = horizontal_speed > 0.05

	local is_moving = true

    	if not (is_moving and has_velocity) then
		is_moving = false
	end

	return is_moving
end

local function prevent_detect(player)
    	if player:get_attach() then return true end

    	if not player_is_moving(player) then return true end

    	if mod.hangglider then
        	if player_is_gliding(player) and not physics_mod_is_installed() then return true end
    	end

    	return false
end


local function get_darkened_texture_from_node(pos, darkness)
	local node = core.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})

	if not node then return "[fill:2x16:0,0:#8B4513" end

    	local def = core.registered_nodes[node.name]

	if not def or not def.tiles or not def.tiles[1] then return "[fill:2x16:0,0:#8B4513" end

    	local base_texture = def.tiles[1]

    	if type(base_texture) == "table" then return "smoke_puff.png" end

    	return base_texture .. "^[colorize:#000000:" .. tostring(darkness or 80)
end

local function ground_particles(player)
	local pos = player:get_pos()
    	local texture = get_darkened_texture_from_node(pos, 80)
    	local node = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
	local def = minetest.registered_nodes[node.name] or {}
    	local drawtype = def.drawtype
    	if drawtype == "airlike" or drawtype == "liquid" or drawtype == "flowingliquid" then return end
    	core.add_particlespawner({
        	amount = 5,
        	time = 0.01,
        	minpos = {x = pos.x - 0.25, y = pos.y + 0.1, z = pos.z - 0.25},
        	maxpos = {x = pos.x + 0.25, y = pos.y + 0.1, z = pos.z + 0.25},
        	minvel = {x = -0.5, y = 1, z = -0.5},
        	maxvel = {x = 0.5, y = 2, z = 0.5},
        	minacc = {x = 0, y = -5, z = 0},
        	maxacc = {x = 0, y = -12, z = 0},
        	minexptime = 0.25,
        	maxexptime = 0.5,
        	minsize = 0.5,
        	maxsize = 1.0,
        	vertical = false,
        	collisiondetection = false,
        	texture = texture
    	})
end

local function is_3d_armor_item(itemstack)
    local item_name = itemstack:get_name()
    return item_name:match("^3d_armor:") ~= nil
end

--[[-----------------------------------------------------------------------------------------------------------
--[[-----------------------------------------------------------------------------------------------------------
    	[API_NR = 201]
]]
api.register_server_step = function(mod_name, step_name, step_interval, step_callback)
	if not data.server_steps[mod_name] then
		data.server_steps[mod_name] = {}
    	end

    	if data.server_steps[mod_name][step_name] then
        	error("Step with name '" .. step_name .. "' already exists for mod '" .. mod_name .. "'.")
    	end

        data.server_steps[mod_name][step_name] = {
        	interval = step_interval,
        	elapsed = 0,
        	callback = step_callback
    	}
end

core.register_globalstep(function(dtime)
	for mod, steps in pairs(data.server_steps) do
    		for step_name, tick in pairs(steps) do
        		tick.elapsed = tick.elapsed + dtime
        		if tick.elapsed >= tick.interval then
            			for _, player in ipairs(core.get_connected_players()) do
                			local name = player:get_player_name()
                			if data.players[name] then
                    				local player_data = data.players[name]
                    				tick.callback(player, player_data, dtime)
                    				tick.elapsed = tick.elapsed - tick.interval -- Reset elapsed time.
                			end
            			end
        		end
    		end
	end
end)


--[[-----------------------------------------------------------------------------------------------------------
--[[-----------------------------------------------------------------------------------------------------------
    	API [API_NR = 202]
]]
api.sprint_key_detected = function(player, enable_aux1, enable_double_tap, interval)
	local name = player:get_player_name()

    	local k_data = data.keyboard[name]
	local control = player:get_player_control()
    	local control_bit = player:get_player_control_bits()
    	local current_time_us = core.get_us_time() / 1e6
    	local cancel_active = false

    	if data.cancel_reasons[name] then
        	for reason, _ in pairs(data.cancel_reasons[name]) do
            		cancel_active = true
            		break
        	end
	end

	if mod.armor and not physics_mod_is_installed() then
		local wielded_item = player:get_wielded_item()
		if is_3d_armor_item(wielded_item) then
			cancel_active = true
		end

	end

   	if cancel_active or prevent_detect(player) then
        	k_data.detected = false
        	k_data.is_holding = false
        	k_data.aux_pressed = false
        	return false
    	end

    	if enable_aux1 then
        	k_data.detected = true
        	k_data.is_holding = false
        	k_data.aux_pressed = true
    	elseif not enable_double_tap then
        	k_data.detected = false
        	k_data.is_holding = false
        	k_data.aux_pressed = false
    	elseif enable_double_tap then
        	if not k_data.is_holding then
        		if current_time_us - k_data.last_tap_time < interval then
                		k_data.detected = true
            		end
            		k_data.last_tap_time = current_time_us
            		k_data.is_holding = true
        	end
        	k_data.aux_pressed = false
    	elseif control_bit == 0 or control_bit == 32 then
        	k_data.detected = false
        	k_data.is_holding = false
        	k_data.aux_pressed = false
    	end

    	return k_data.detected
end
--[[-----------------------------------------------------------------------------------------------------------
--[[-----------------------------------------------------------------------------------------------------------
    	API [API_NR = 203]
]]
api.set_sprint_cancel = function(player, enabled, reason)
	local name = player:get_player_name()

    	if not data.cancel_reasons[name] then
        	data.cancel_reasons[name] = {}
    	end

    	if enabled then
        	data.cancel_reasons[name][reason] = true
    	else
        	data.cancel_reasons[name][reason] = nil
    	end
end

--[[-----------------------------------------------------------------------------------------------------------
--[[-----------------------------------------------------------------------------------------------------------
	API [API_NR = 207]
]]
local get_physics_def = function(player)
	local def = summed_mod_defs()
	local returned_def = {}
	local name = player:get_player_name()
	returned_def.speed = def.speed + data.physics_pool[name].speed
	returned_def.jump = def.jump + data.physics_pool[name].jump
	returned_def.gravity = def.gravity + data.physics_pool[name].gravity
	return returned_def
end

local add_physics = function(player, def)

	local name = player:get_player_name()

	local SPEED = def.speed or 0
	local JUMP = def.jump or 0
	local GRAVITY = def.gravity or 0

	data.physics_pool[name].speed = data.physics_pool[name].speed + SPEED
	data.physics_pool[name].jump = data.physics_pool[name].jump + JUMP
	data.physics_pool[name].gravity = data.physics_pool[name].gravity + GRAVITY
end


local update_physics = function(player, def, reason)
	local name = player:get_player_name()
	local old_def = data.physics_reasons[name][reason]
	remove_physics(player, old_def)
	data.physics_reasons[name][reason] = new_def
	add_physics(player, new_def)
end

local remove_physics = function(player, def)

	local name = player:get_player_name()

	local SPEED = def.speed or 0
	local JUMP = def.jump or 0
	local GRAVITY = def.gravity or 0

	data.physics_pool[name].speed = data.physics_pool[name].speed - SPEED
	data.physics_pool[name].jump = data.physics_pool[name].jump - JUMP
	data.physics_pool[name].gravity = data.physics_pool[name].gravity - GRAVITY
end

local set_physics = function(player)
	local name = player:get_player_name()
	player:set_physics_override({ speed = 1 + get_physics_def(player).speed, jump = 1 + get_physics_def(player).jump, gravity = 1 + get_physics_def(player).gravity })
end

local change_physics = function(player, def, reason)
	local name = player:get_player_name()

    	-- Ensure physics pool and reasons exist
    	if not data.physics_pool[name] then
        	data.physics_pool[name] = { speed = 0, jump = 0, gravity = 0 }
    	end

    	if not data.physics_reasons[name] then
        	data.physics_reasons[name] = {}
    	end

    	if def.action == "add" then
        	-- Only add if reason isn't already tracked
        	if not data.physics_reasons[name][reason] then
            		data.physics_reasons[name][reason] = def
            		add_physics(player, def)
		else
			update_physics(player, def, reason)
        	end
    	elseif def.action == "remove" then
        	-- Only remove if reason is being tracked
		if data.physics_reasons[name][reason] then
            		remove_physics(player, data.physics_reasons[name][reason])
            		data.physics_reasons[name][reason] = nil
        	end
    	end

	-- Apply updated physics settings
	set_physics(player)
end

--[[-----------------------------------------------------------------------------------------------------------
	API [API_NR = 204]
]]
api.set_sprint = function(modname, player, sprinting, override_table )
	override_table = override_table or {}

    	local name = player:get_player_name()

    	if not data.states[name] then
        	data.states[name] = {}
    	end

    	local SPEED = override_table.speed or 0
    	local JUMP = override_table.jump or 0
    	local PARTICLES = override_table.particles or false
    	local MCL_SPEED = override_table.mcl_speed or 0
    	local FOV = override_table.fov or 0
    	local TRANSITION = override_table.transition or 0

    	if core.get_game_info().title == "Mineclonia" or core.get_game_info().title == "VoxeLibre" then
        	if MCL_SPEED <= 0 then
            		MCL_SPEED = mcl_sprint.SPEED
        	end
    	end

    	if sprinting == true and not data.states[name].is_sprinting then
        	if mod.physics and core.get_game_info().title == "Mineclonia" then
            		playerphysics.add_physics_factor(player, "speed", "mcl_sprint:sprint", MCL_SPEED)
            		playerphysics.add_physics_factor(player, "fov", "mcl_sprint:sprint", 1.1)

        	elseif mod.physics and core.get_game_info().title == "VoxeLibre" then
            		playerphysics.add_physics_factor(player, "speed", "mcl_sprint:sprint", MCL_SPEED)
            		mcl_fovapi.apply_modifier(player, "sprint")

        	elseif mod.monoids then
            		data.states[name].sprint = player_monoids.speed:add_change(player, get_physics_def(player).speed + SPEED)
            		data.states[name].jump = player_monoids.jump:add_change(player, get_physics_def(player).jump + JUMP )

        	elseif mod.pova then
            		pova.add_override(name, modname .. ":sprint", { speed = SPEED, jump = JUMP })
            		pova.do_override(player)
        	else
            		change_physics(player, { action = "add", speed = SPEED, jump = JUMP, gravity = 0 }, "Sprint Boost")
        	end

        	if FOV > 0 and TRANSITION > 0 then
			player:set_fov(old_fov + FOV, false, TRANSITION)
        	end

        	data.states[name].is_sprinting = true

    	elseif sprinting == false and data.states[name].is_sprinting then

        	if mod.physics and core.get_game_info().title == "Mineclonia" then
            		playerphysics.remove_physics_factor(player, "speed", "mcl_sprint:sprint")
            		playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")

		elseif mod.physics and core.get_game_info().title == "VoxeLibre" then
        	    	playerphysics.remove_physics_factor(player, "speed", "mcl_sprint:sprint")
			mcl_fovapi.remove_modifier(player, "sprint")

		elseif mod.monoids then
			player_monoids.speed:del_change(player, data.states[name].sprint)
			player_monoids.jump:del_change(player, data.states[name].jump)
		elseif mod.pova then
			pova.del_override(name, modname ..":sprint")
			pova.do_override(player)
		else
            		change_physics(player, { action = "remove" }, "Sprint Boost")
		end
		if FOV > 0 and TRANSITION > 0 then
			player:set_fov(old_fov, false, TRANSITION)
		end

		data.states[name].is_sprinting = false
	end

	if PARTICLES and data.states[name].is_sprinting then
		ground_particles(player)
	end

	return data.states[name].is_sprinting
end

--[[-----------------------------------------------------------------------------------------------------------
	API [API_NR = 205]
]]
api.is_player_sprinting = function(player)
    	local name = player:get_player_name()
    	if not data.states[name] then return false end
    	return data.states[name].is_sprinting or false
end

--[[-----------------------------------------------------------------------------------------------------------
	API [API_NR = 206]
]]
api.is_player_draining = function(player)
    	local name = player:get_player_name()
    	if api.is_player_sprinting(player) then
        	if mod.hangglider then
            		if player_is_gliding(player) then
                		return false
            		end
        	end
        	return true
    	end
   	return false
end

--[[-----------------------------------------------------------------------------------------------------------
	CREATE/CLEAR DATA/STATES WHEN PLAYER LEAVES/JOINS
]]
core.register_on_joinplayer(function(player)
	if not player then return end
    	local name = player:get_player_name()

        if not data.keyboard[name] then
        	data.keyboard[name] = init_data(player)
    	end

        if not data.physics_pool[name] then
        	data.physics_pool[name] = {speed = 0, jump = 0, gravity = 0}
    	end

        if not data.players[name] then
        	data.players[name] = {}
    	end
end)

core.register_on_leaveplayer(function(player)
	if not player then return end
    	local name = player:get_player_name()

    	data.keyboard[name] = nil

    	data.players[name] = nil

        data.physics_pool[name] = nil
end)

if mod.physics and core.get_game_info().title == "Mineclonia" then
	core.register_on_respawnplayer(function(player)
		playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")
	end)

	core.register_on_leaveplayer(function(player)
		playerphysics.remove_physics_factor(player, "fov", "mcl_sprint:sprint")
	end)
elseif mod.physics and core.get_game_info().title == "VoxeLibre" then
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

--[[
	API TOOLS: EXTRA TOOLS TO MAKE YOUR LIFE EASIER
]]

api.tools = {}

api.tools.is_player_hanggliding = player_is_gliding

api.tools.is_player_moving = player_is_moving

api.tools.node_is_liquid = function(player, altPos)
	local def = get_node_definition(player, altPos)

	if def and ( def.drawtype == "liquid" or def.drawtype == "flowingliquid" ) then
		return true
	end

	return false
end

api.tools.node_is_snowy_group = function(player, altPos)
	local def = get_node_definition(player, altPos)
	if def and def.groups and def.groups and def.groups.snowy and def.groups.snowy > 0  then
		return true
	end
	return false
end

api.tools.node_is_walkable = function(player, altPos)
	local def = get_node_definition(player, altPos)
	if def and def.walkable then
		return true
	end
	return false
end
