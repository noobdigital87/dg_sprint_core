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


---- NEW API
--local server_data = {}
--local player_data = {}
--
--dg_sprint_core.register_step = function(name, interval, callback)
--
--    server_data[name] = {
--        interval = interval,
--        elapsed = 0,
--        callback = callback,
--        data = player_data
--    }
--end
--
---- Add/Remove player data on join/leave.
--
--core.register_on_joinplayer(function(player)
--    local name = player:get_player_name()
--    player_data[name] = {
--            setting = {
--                aux1 = core.settings:get_bool("dg_sprint_core.aux1", true),
--                double_tap = core.settings:get_bool("dg_sprint_core.double_tap", true),
--                supersprint = core.settings:get_bool("dg_sprint_core.supersprint", true),
--                tap_interval = tonumber(core.settings:get("dg_sprint_core.tap_interval")) or 0.5,
--            },
--            state = {
--                detected = false,
--            }
--            other = {
--                last_tap_time = 0,
--                is_holding = false, 
--                super_sprint = false,
--                super_toggle_press = false,
--            }
--    }
--end)
--
--
--core.register_on_leaveplayer(function(player)
--    local name = player:get_player_name()
--    player_data[name] = nil
--end)
--
--core.register_globalstep(function(dtime)
--    for name, tick in pairs(server_steps) do
--    	local players = core.get_connected_players()
--    	for _, player in ipairs(players) do
--        	if core.is_player(player) then
--            	tick.elapsed = tick.elapsed + dtime
--            	if tick.elapsed >= tick.interval then
--                	local rv = tick.callback(player, tick.data, dtime)
--                	if rv ~= nil and type(rv) == "table" then
--                    	tick.data = rv
--                	end
--                	tick.elapsed = tick.elapsed - tick.interval
--            	end
--        	end
--    	end
--    end
--end)