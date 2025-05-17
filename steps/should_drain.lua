local player_data = {}

local mod_name = core.get_current_modname()

-- Function to create the initial data structure for each player's state
local function create_pdata()
    return {
        drain = false,
        enable_drain = true,
        prevent_drain_reasons = {},
    }
end


-- Initialize/reset the player's data when they join or leave the game
core.register_on_joinplayer(function(player)
    player_data[player:get_player_name()] = create_pdata()
end)

core.register_on_leaveplayer(function(player)
    player_data[player:get_player_name()] = nil
end)


-- Register a function to prevent or allow draining based on reasons
dg_sprint_core.prevent_drain = function(player, enabled, reason)
    local p_data = player_data[player:get_player_name()]
    if p_data and p_data.prevent_drain_reasons then
        if enabled then
            p_data.prevent_drain_reasons[reason] = true
        else
            p_data.prevent_drain_reasons[reason] = nil
        end
    end
end

-- Register server steps for draining logic
local STEPS = {
    MOVE_DRAIN_STEP = {
        INTERVAL = 0.5,
        NAME = mod_name .. ":MOVE_DRAIN_STEP",
        CALLBACK = function(player, dtime)
            local p_pos = player:get_pos()

            local controls = player:get_player_control()

            local is_moving = controls.up or controls.down or controls.left or controls.right

            local velocity = player:get_velocity()  

            velocity.y = 0

            local horizontal_speed = vector.length(velocity)
            local has_velocity = horizontal_speed > 0.05

            if (is_moving and has_velocity) then
                dg_sprint_core.prevent_drain(player, false, mod_name .. ":not_moving")
            else
                dg_sprint_core.prevent_drain(player, true, mod_name .. ":not_moving")
            end
        end
    },
    DRAIN_STEP = {
        INTERVAL = 0.5,
        NAME = mod_name .. ":DRAIN_STEP",
        CALLBACK = function(player, dtime)
            local sprinting = dg_sprint_core.is_sprinting(player)
            local p_data = player_data[player:get_player_name()]

            local cancel_active = false

            if p_data.prevent_drain_reasons then
                for reason, _ in pairs(p_data.prevent_drain_reasons) do
                    cancel_active = true
                    break
                end
            end

            if p_data.enable_drain and sprinting and not cancel_active then
                p_data.drain = true
            else
                p_data.drain = false
            end
        end
    },
}

-- Register server steps for each defined step.
for _, step in pairs(STEPS) do
    dg_sprint_core.register_step(step.NAME, step.INTERVAL, step.CALLBACK)
end

--[[ API ]]--

-- Check if a player should be draining stamina.
dg_sprint_core.is_draining = function(player)
    return player_data[player:get_player_name()].drain or false
end

dg_sprint_core.enable_drain = function(player, value)
    local p_data = player_data[player:get_player_name()]
    if p_data then
        p_data.enable_drain = value
    end
end
