local settings = {}
local data = {}

-- START OF KEYBOARD
----------------------------------------------------------------------------------------
data.player_key_callbacks = {}
data.player_key_data = {}


settings.keyboard = {
    double_tap = core.settings:get_bool("dg_sprint_core.double_tap", true),
    aux1 = core.settings:get_bool("dg_sprint_core.aux1", true),
    tap_interval = tonumber(core.settings:get("dg_sprint_core.tap_interval")) or 0.5,
}

local function register_on_detection(callback)
    if type(callback) == "function" then
        table.insert(data.player_key_callbacks, callback)
    end
end

local function key_detection(player)

    local p_name = player:get_player_name()
    local current_time = core.get_us_time() / 1e6

    if not data.player_key_data[p_name] then
        data.player_key_data[p_name] = {
            detected = false,
            is_holding = false,
            aux_pressed = false,
            last_tap_time = 0,
        }
    end

    local p_data = data.player_key_data[p_name]
    local p_control_bit = player:get_player_control_bits()

    if settings.keyboard.aux1 and p_control_bit == 33 then
        p_data.detected = true
        p_data.is_holding = false
        p_data.aux_pressed = true
    elseif p_control_bit == 1 then
        if settings.keyboard.double_tap then
            if not p_data.is_holding then
                if current_time - p_data.last_tap_time < settings.keyboard.tap_interval then
                    p_data.detected = true
                end

                p_data.last_tap_time = current_time
                p_data.is_holding = true
            end

            p_data.aux_pressed = false
        else
            p_data.detected = false
            p_data.is_holding = false
        end
    elseif p_control_bit == 0 or p_control_bit == 32 then
        p_data.detected = false
        p_data.is_holding = false
        p_data.aux_pressed = false
    end

    for _, callback in ipairs(data.player_key_callbacks) do
        callback(player, p_data.detected, p_data.aux_pressed)
    end
end

local function is_player(player)
	return (
		core.is_player(player) and
		not player.is_fake_player
	)
end

local timer = 0
local tick = 0.5

if settings.keyboard.double_tap then
    tick = 0.1
end

core.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 0.1 then
        timer = 0  -- Reset the timer
        local players = core.get_connected_players()
        for _, player in ipairs(players) do
            if player and is_player(player) then
                key_detection(player)
            end
        end
    end
end)
---------------------------------------------------------------------------
-- END OF KEYBOARD

-- START OF SPRINTING
----------------------------------------------------------------------------
data.player_sprint_callbacks = {}

settings.sprinting = {
    armor_mod = core.get_modpath("3d_armor") and core.global_exists("armor") and armor.def,
    player_monoids = core.get_modpath("player_monoids") and core.global_exists("player_monoids"),
    pova = core.get_modpath("pova") and core.global_exists("pova"),
    extra_speed = tonumber(core.settings:get("dg_sprint_core.speed")) or 0.8,
    extra_jump = tonumber(core.settings:get("dg_sprint_core.jump")) or 0.1,
    particles = core.settings:get_bool("dg_sprint_core.particles", true),
}


local function sprint(player, sprinting)
	for _, fun in ipairs(data.player_sprint_callbacks) do
		local rv = fun(player, sprinting)
		if rv == true then
			return
		end
	end
	if settings.sprinting.player_monoids then
		if sprinting then
			player_monoids.speed:add_change(player, 1 + settings.sprinting.extra_speed, "dg_sprint_core:physics")
			player_monoids.jump:add_change(player, 1 + settings.sprinting.extra_jump, "dg_sprint_core:physics")
		else
			player_monoids.speed:del_change(player, "dg_sprint_core:physics")
			player_monoids.jump:del_change(player, "dg_sprint_core:physics")
		end
	elseif settings.sprinting.pova then
		if sprinting then
			pova.add_override(player:get_player_name(), "dg_sprint_core:physics",
					{speed = settings.sprinting.extra_speed, jump = settings.sprinting.sprint_jump})
			pova.do_override(player)
		else
			pova.del_override(player:get_player_name(), "dg_sprint_core:physics")
			pova.do_override(player)
		end
	else
		local def
		if settings.sprinting.armor_mod then
			local name = player:get_player_name()
			def = {
				speed=armor.def[name].speed,
				jump=armor.def[name].jump,
				gravity=armor.def[name].gravity
			}
		else
			def = {
				speed=1,
				jump=1,
				gravity=1
			}
		end

		if sprinting then
			def.speed = def.speed + settings.sprinting.extra_speed
			def.jump = def.jump + settings.sprinting.extra_jump
		end

		player:set_physics_override(def)
	end

	if settings.sprinting.particles and sprinting then
		local pos = player:get_pos()
		local node = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
		local def = minetest.registered_nodes[node.name] or {}
		local drawtype = def.drawtype
		if drawtype ~= "airlike" and drawtype ~= "liquid" and drawtype ~= "flowingliquid" then
			minetest.add_particlespawner({
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
				texture = "default_dirt.png" or "smoke_puff.png",
			})
		end
	end
end

local function register_on_sprinting(fun)
	table.insert(data.player_sprint_callbacks, fun)
end

data.player_sprint_cancelations = {}

local function cancel_sprint(player_name)
    data.player_sprint_cancelations[player_name] = true
end

register_on_detection(function(player, detected, aux)
    local player_name = player:get_player_name()

    if not data.player_sprint_cancelations[player_name] then
        data.player_sprint_cancelations[player_name] = false
    end

    if detected and not player:get_attach() and not data.player_sprint_cancelations[player_name] then
        sprint(player, true)
    else
        if data.player_sprint_cancelations[player_name] then
            data.player_sprint_cancelations[player_name] = false
        end
        sprint(player, false)
    end
end)

------------------------------------------------------------------------------------
-- END OF SPRINTING


-- START OF API
---------------------------------------------------------------------------------------
dg_sprint_core = {
    settings = settings,
    register_on_sprinting = register_on_sprinting,
    cancel_sprint = cancel_sprint,
}
----------------------------------------------------------------------------------------
-- END OF API