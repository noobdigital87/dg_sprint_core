-- Table to store scheduled server step functions.
local server_steps = {}

--[[ 
    Register a custom server step (periodic callback).
    mod_name and name are concatenated for namespacing; interval is the callback period,
    and callback is the function to be executed.
]]
dg_sprint_core.register_server_step = function(name, interval, callback)
    server_steps[name] = {
        interval = interval,
        elapsed = 0,
        callback = callback
    }
end

-- Globalstep: iterate over all registered server steps and trigger callbacks when intervals are met.
core.register_globalstep(function(dtime)
    for name, tick in pairs(server_steps) do
        local players = core.get_connected_players()
        for _, player in ipairs(players) do
            tick.elapsed = tick.elapsed + dtime
            if tick.elapsed >= tick.interval then
                tick.callback(player, dtime)
                tick.elapsed = tick.elapsed - tick.interval
            end
        end
    end
end)





