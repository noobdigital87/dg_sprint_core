dg_sprint_core = {}

--[[ START LIB INIT ]]--
local mod_name = core.get_current_modname()

local mod_dir = core.get_modpath(mod_name) .. "/"

local lib_dir = mod_dir .. "Library/"

dofile(lib_dir .. "init.lua")
--[[ END LIB INIT ]]


--[[ START EXAMPLE USE ]]--

local your_mod_name = core.get_current_modname()
dg_sprint_core.settings = {
	enable_sprint = true,
    	aux1 = true,
    	double_tap = true,
    	particles = true,
    	tap_interval = 0.5,
}

dg_sprint_core.RegisterStep(your_mod_name, "DETECT_SPRINT")


--[[ END EXAMPLE USE ]]--



--[[
dg_sprint_core.settings = {
	enable_sprint = core.settings:get_bool(mod_name .. ".sprint", true),
    	aux1 = core.settings:get_bool(mod_name .. ".aux1", true),
    	double_tap = core.settings:get_bool(mod_name .. ".double_tap", true),
    	particles = core.settings:get_bool(mod_name .. ".particles", true),
    	tap_interval = tonumber(core.settings:get_bool(mod_name .. ".double_tap", true)) or 0.5,
}

dg_sprint_core.register_step(mod_name, "keyboard", 0.1, function(player, info, state, dtime)
    	if dg_sprint_core.IsSprintKeyDetected(player, dg_sprint_core.settings.aux1, dg_sprint_core.settings.double_tap, dg_sprint_core.settings.tap_interval) then
        	state.is_sprinting = true
    	else
        	state.is_sprinting = false
    	end
	local control = player:get_player_control()
	if state.is_sprinting and control.down then
		dg_sprint_core.prevent_detection(player, true, mod_name .. ":BACKWARDS")
	else
		dg_sprint_core.prevent_detection(player, false, mod_name .. ":BACKWARDS")
	end
	
end)

dg_sprint_core.register_step(mod_name, "should_drain", 0.2, function(player, info, state, dtime)
    	if state.is_sprinting then
		p_pos = player:get_pos()
		local controls = player:get_player_control()
            	local is_moving = controls.up or controls.down or controls.left or controls.right
            	local velocity = player:get_velocity()  

            	velocity.y = 0

            	local horizontal_speed = vector.length(velocity)
            	local has_velocity = horizontal_speed > 0.05

            	if (is_moving and has_velocity) then
			state.should_drain = true
		else
			state.should_drain = false
		end
    	end
end)

dg_sprint_core.register_step(mod_name, "sprint", 0.3, function(player, info, state, dtime)
    dg_sprint_core.Sprint(mod_name, player, state.is_sprinting, {speed = 0.8, jump = 0.1})
end)

dg_sprint_core.register_step(mod_name, "particles", 0.5, function(player, info, state, dtime)
	if state.is_sprinting and dg_sprint_core.settings.particles then
    		dg_sprint_core.ShowParticles(player:get_pos())
	end
end)
]]--
