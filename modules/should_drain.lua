local player_data = {}

local mod_name = core.get_current_modname()

local function create_pdata()
    return {
        drain = false,
        prevent_drain_reasons = {},
    }
end

core.register_on_joinplayer(function(player)
    player_data[player:get_player_name()] = create_pdata()
end)

core.register_on_leaveplayer(function(player)
    player_data[player:get_player_name()] = nil
end)

local prevent_drain = function(player, enabled, reason)
    local p_data = player_data[player:get_player_name()]
    if p_data and p_data.prevent_drain_reasons then
        if enabled then
            p_data.prevent_drain_reasons[reason] = true
        else
            p_data.prevent_drain_reasons[reason] = nil
        end
    end
end

dg_sprint_core.register_server_step(mod_name .. "move_drain", 0.5, function(player, dtime)
    local p_pos = player:get_pos()

    local controls = player:get_player_control()

    local is_moving = controls.up or controls.down or controls.left or controls.right

    local velocity = player:get_velocity()  

    velocity.y = 0

    local horizontal_speed = vector.length(velocity)
    local has_velocity = horizontal_speed > 0.05

    if (is_moving and has_velocity) then
        prevent_drain(player, false, mod_name .. ":not_moving")
    else
        prevent_drain(player, true, mod_name .. ":not_moving")
    end
end)

dg_sprint_core.register_server_step(mod_name .. "global_drain", 0.2, function(player, dtime)
    local sprinting = dg_sprint_core.is_sprinting(player)
    local p_data = player_data[player:get_player_name()]

    local cancel_active = false
    if p_data.prevent_drain_reasons then
       for reason, _ in pairs(p_data.prevent_drain_reasons) do
            cancel_active = true
            break
        end
    end
    if sprinting and not cancel_active then
        p_data.drain = true
    else
        p_data.drain = false
    end
end)

dg_sprint_core.is_draining = function(player)
    return player_data[player:get_player_name()].drain or false
end
