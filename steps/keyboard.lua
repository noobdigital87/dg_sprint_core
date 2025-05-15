

local player_data = {}

local mod_name = core.get_current_modname()

local KEY_STEP_INTERVAL = tonumber(core.settings:get(mod_name .. ".key_step_interval")) or 0.15

local function is_player(player)

	if player and type(player) == "userdata" and core.is_player(player) then
		return true
	end
end

-- Helper function to create player data structure.

local function create_pdata(player)
    return {
        settings = {
            aux1 = core.settings:get_bool("dg_sprint_core.aux1", false),
            double_tap = core.settings:get_bool("dg_sprint_core.double_tap", false),
            enable_ssprint = core.settings:get_bool("dg_sprint_core.supersprint", false),
            tap_interval = tonumber(core.settings:get("dg_sprint_core.tap_interval")) or 0.5,
        },
        states = {
            is_sprinting = false,
            detected = false,
            last_tap_time = 0,
            is_holding = false, 
            super_sprint = false,
            super_toggle_press = false,
            aux_pressed = false,
        },
        prevent_detection_reasons = {},
    }
end


-- Add/Remove player data on join/leave.

core.register_on_joinplayer(function(player)

    local name = player:get_player_name()
    player_data[name] = create_pdata(player)

end)


core.register_on_leaveplayer(function(player)

    local name = player:get_player_name()

    player_data[name] = nil

end)


-- Register a function to prevent or allow draining based on reasons
dg_sprint_core.prevent_detection = function(player, enabled, reason)
    local p_data = player_data[player:get_player_name()]
    if p_data and p_data.prevent_detection_reasons then
        if enabled then
            p_data.prevent_detection_reasons[reason] = true
        else
            p_data.prevent_detection_reasons[reason] = nil
        end
    end
end


dg_sprint_core.register_server_step(mod_name ..":KEY_STEP", KEY_STEP_INTERVAL, function(player, dtime)
    local p_name = player:get_player_name()
    local p_data = player_data[p_name]
    local p_control_bit = player:get_player_control_bits()
    local current_time_us = core.get_us_time() / 1e6
   
    if not p_data then return end
    local cancel_active = false
    if p_data.prevent_detection_reasons then
        for reason, _ in pairs(p_data.prevent_detection_reasons) do
            cancel_active = true
            break
        end
    end

    if not cancel_active then
        if p_control_bit == (32 + 1) and p_data.settings.aux1 then
            p_data.states.detected = true
            p_data.states.is_holding = false
            p_data.states.aux_pressed = true
        elseif p_control_bit == 1 and not p_data.settings.double_tap then
            p_data.states.detected = false
            p_data.states.is_holding = false
            p_data.states.aux_pressed = false
        elseif p_control_bit == 1 and p_data.settings.double_tap then
            if not p_data.states.is_holding then
                if current_time_us - p_data.states.last_tap_time < p_data.settings.tap_interval  then
                    p_data.states.detected = true
                end
                p_data.states.last_tap_time = current_time_us
                p_data.states.is_holding = true
            end
            p_data.states.aux_pressed = false
        elseif p_control_bit == 0 or p_control_bit == 32 then
            p_data.states.detected = false
            p_data.states.is_holding = false
            p_data.states.aux_pressed = false
        
        end
        local controls = player:get_player_control()

        if p_data.settings.enable_ssprint and (controls.left and controls.right) and not controls.up then
            if not p_data.states.super_toggle_press then

                p_data.states.super_sprint = not p_data.states.super_sprint
                p_data.states.super_toggle_press = true
            end
        else
            p_data.states.super_toggle_press = false
        end
    else
        p_data.states.detected = false
        p_data.states.is_holding = false
        p_data.states.aux_pressed = false
    end
end)

-- API

dg_sprint_core.is_key_detected = function(player)
 if not is_player(player) then 
    return false 
end
    local name = player:get_player_name()
    return player_data[name].states.detected
end

dg_sprint_core.is_super_sprint_active = function(player)
    if not is_player(player) then 
        return false 
    end
    local name = player:get_player_name()
    return player_data[name].states.super_sprint
end

dg_sprint_core.enable_aux1 = function(player, enable)
 if not is_player(player) then return end
    local name = player:get_player_name()
    if player_data[name] then
        player_data[name].settings.aux1 = enable
    end
end

dg_sprint_core.enable_ssprint = function(player, enable)
 if not is_player(player) then return end
    local name = player:get_player_name()
    if player_data[name] then
        player_data[name].settings.ssprint = enable
    end
end

dg_sprint_core.enable_double_tap = function(player, enable)
 if not is_player(player) then return end
    local name = player:get_player_name()
    if player_data[name] then
        player_data[name].settings.double_tap = enable
    end
end

dg_sprint_core.set_tap_interval = function(player, interval)
    if not is_player(player) then 
        return
    end
    local name = player:get_player_name()
    if player_data[name] then
        player_data[name].settings.tap_interval = interval
    end
end

