local server_steps = {}

dg_sprint_core.register_step = function(name, interval, callback)
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





