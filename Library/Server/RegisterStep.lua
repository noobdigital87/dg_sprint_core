local server_steps = {}

local function validate_step_parameters(mod_name, step_name, step_interval, step_callback)
    assert(type(step_name) == "string", "Step name must be a string.")
    assert(type(step_interval) == "number" and step_interval > 0, "Interval must be a positive number.")
    assert(type(step_callback) == "function", "Callback must be a function.")
end

dg_sprint_core.register_step = function(mod_name, step_name, step_interval, step_callback)
    validate_step_parameters(mod_name, step_name, step_interval, step_callback)

    -- Initialize mod table if it doesn't exist
    if not server_steps[mod_name] then
        server_steps[mod_name] = {}
    end

    -- Check if step already exists for the given mod name
    if server_steps[mod_name][step_name] then
        error("Step with name '" .. step_name .. "' already exists for mod '" .. mod_name .. "'.")
    end

    server_steps[mod_name][step_name] = {
        interval = step_interval,
        elapsed = 0,
        callback = step_callback
    }
end


local player_info = {}
local player_states = {}

core.register_on_joinplayer(function(player, last_login)
    if not player then return end

    local name = player:get_player_name()

    if not player_states[name] then
        player_states[name] = {}
    end

    if last_login == nil then
        player_states[name].new_user = true
    else
        player_states[name].new_user = false
    end

    player_info[name] = {
        name = name,
        pos = player:get_pos(),
        control = player:get_player_control(),
        control_bit = player:get_player_control_bits(),
    }
    
end)

core.register_on_leaveplayer(function(player)
    if not player then return end
    local name = player:get_player_name()
    player_info[name] = nil
    player_states[name] = nil
end)


core.register_globalstep(function(dtime)
    for mod, steps in pairs(server_steps) do
        for step_name, tick in pairs(steps) do
            tick.elapsed = tick.elapsed + dtime
            if tick.elapsed >= tick.interval then
                -- Get the connected players
                local players = core.get_connected_players()

                -- Iterate over the connected players
                for _, player in ipairs(players) do
                    local name = player:get_player_name()

                    -- Check if the player exists in player_info
                    if player_info[name] then
                        -- Get the player's information and states
                        local p_info = player_info[name]
                        local p_states = player_states[name]

                        -- Call the step callback with the player, info, states, and dtime
                        tick.callback(player, p_info, p_states, dtime)

                        -- Reset the elapsed time
                        tick.elapsed = tick.elapsed - tick.interval
                    end
                end
            end
        end
    end
end)