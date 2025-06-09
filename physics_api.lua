dg_sprint_core.physics = {
    _identifier = "shared_physics_api", -- Unique identifier for detection
    -- Global default suppression values (used if no custom override is provided)
    default_suppressed = {speed = 1, jump = 1, gravity = 1},
}

-- Check if another mod has already registered the shared API
for key, value in pairs(_G) do
    if type(value) == "table" and value._identifier == "shared_physics_api" then
        dg_sprint_core.physics = value
        minetest.log("warning", "[PhysicsAPI] Another mod has already registered a shared physics API under '" .. key .. "'. Using that instance.")
        break
    end
end

local physics_api = dg_sprint_core.physics -- Alias for easier reference

local stored_physics = {}     -- Will store each player's original physics values.
local applied_deltas = {}     -- Tracks applied delta changes per player.
local suppressed_players = {} -- If a player is suppressed, this table holds their custom override values.

-- Initialize physics tracking for a player.
function physics_api.init_physics_tracking(player)
    local name = player:get_player_name()
    if not stored_physics[name] then
        local def = player:get_physics_override()
        stored_physics[name] = {speed = def.speed, jump = def.jump, gravity = def.gravity}
        applied_deltas[name] = {speed = 0, jump = 0, gravity = 0}
    end
end

-- Computes the new physics override for a player.
local function compute_new_override(name)
    if suppressed_players[name] then
        return suppressed_players[name]
    end
    return {
        speed   = stored_physics[name].speed + applied_deltas[name].speed,
        jump    = stored_physics[name].jump + applied_deltas[name].jump,
        gravity = stored_physics[name].gravity + applied_deltas[name].gravity,
    }
end

-- Modifies physics values with delta tracking.
function physics_api.modify_physics(player, delta)
    local name = player:get_player_name()
    physics_api.init_physics_tracking(player)
    
    delta.speed   = delta.speed   or 0
    delta.jump    = delta.jump    or 0
    delta.gravity = delta.gravity or 0

    applied_deltas[name].speed   = applied_deltas[name].speed   + delta.speed
    applied_deltas[name].jump    = applied_deltas[name].jump    + delta.jump
    applied_deltas[name].gravity = applied_deltas[name].gravity + delta.gravity

    local new_override = compute_new_override(name)
    player:set_physics_override(new_override)
    return { delta = delta, new_override = new_override }
end

-- Removes a specific physics delta for a player.
function physics_api.remove_physics_delta(player, delta)
    local name = player:get_player_name()
    if not applied_deltas[name] then return end

    delta.speed   = delta.speed   or 0
    delta.jump    = delta.jump    or 0
    delta.gravity = delta.gravity or 0

    applied_deltas[name].speed   = applied_deltas[name].speed   - delta.speed
    applied_deltas[name].jump    = applied_deltas[name].jump    - delta.jump
    applied_deltas[name].gravity = applied_deltas[name].gravity - delta.gravity

    local new_override = compute_new_override(name)
    player:set_physics_override(new_override)
    return { delta = delta, new_override = new_override }
end

-- Resets a player's physics to the original stored values.
function physics_api.reset_physics(player)
    local name = player:get_player_name()
    local reset_values = {}
    if stored_physics[name] then
        reset_values = stored_physics[name]
        player:set_physics_override(reset_values)
        stored_physics[name] = nil
        applied_deltas[name] = nil
        suppressed_players[name] = nil -- Remove any suppression.
    else
        reset_values = {speed = 1, jump = 1, gravity = 1}
        player:set_physics_override(reset_values)
    end
    return reset_values
end

-- Suppresses a player's physics.
function physics_api.suppress_physics(player, override)
    local name = player:get_player_name()
    local suppress_override = override
    if not suppress_override or type(suppress_override) ~= "table" then
        suppress_override = physics_api.default_suppressed
    end
    suppressed_players[name] = suppress_override
    player:set_physics_override(suppress_override)
end

-- Sets custom suppression values per player.
function physics_api.set_player_suppression_values(player, override)
    local name = player:get_player_name()
    if suppressed_players[name] then
        if override and type(override) == "table" then
            suppressed_players[name] = override
            player:set_physics_override(override)
        else
            minetest.log("warning", "[PhysicsAPI] Invalid override provided to set_player_suppression_values for player " .. name)
        end
    else
        minetest.log("info", "[PhysicsAPI] Player " .. name .. " is not suppressed. Use physics_api.suppress_physics() first.")
    end
end

-- Restores a player's physics by removing any suppression.
function physics_api.restore_physics(player)
    local name = player:get_player_name()
    suppressed_players[name] = nil
    local new_override = compute_new_override(name)
    player:set_physics_override(new_override)
end

-- Example chat commands for testing custom suppression features:

minetest.register_chatcommand("dg_sprint_core.suppress", {
    params = "[speed jump gravity]",
    description = "Suppress physics. Optionally provide custom values.",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local override = nil
        if param and param ~= "" then
            local values = {}
            for value in param:gmatch("%S+") do
                table.insert(values, tonumber(value))
            end
            if #values == 3 then
                override = {speed = values[1], jump = values[2], gravity = values[3]}
            else
                minetest.chat_send_player(name, "Provide exactly 3 numeric values for speed, jump, and gravity.")
                return
            end
        end
        physics_api.suppress_physics(player, override)
        minetest.chat_send_player(name, "Physics suppressed!")
    end,
})

minetest.register_chatcommand("dg_sprint_core.set_suppression", {
    params = "speed jump gravity",
    description = "Update custom suppression values for a suppressed player.",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local values = {}
        for value in param:gmatch("%S+") do
            table.insert(values, tonumber(value))
        end
        if #values == 3 then
            local override = {speed = values[1], jump = values[2], gravity = values[3]}
            physics_api.set_player_suppression_values(player, override)
            minetest.chat_send_player(name, "Suppression override updated!")
        else
            minetest.chat_send_player(name, "Provide exactly 3 numeric values.")
        end
    end,
})

minetest.register_chatcommand("dg_sprint_core.restore", {
    params = "",
    description = "Restore physics for a player.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        physics_api.restore_physics(player)
        minetest.chat_send_player(name, "Physics restored!")
    end,
})

minetest.register_chatcommand("dg_sprint_core.physics_delta", {
    params = "speed jump gravity",
    description = "Apply a delta to your current physics settings.",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local values = {}
        for value in param:gmatch("%S+") do
            table.insert(values, tonumber(value))
        end
        if #values == 3 then
            local delta = {speed = values[1], jump = values[2], gravity = values[3]}
            local result = physics_api.modify_physics(player, delta)
            minetest.chat_send_player(name, "Physics delta applied! New override: speed="..result.new_override.speed..", jump="..result.new_override.jump..", gravity="..result.new_override.gravity)
        else
            minetest.chat_send_player(name, "Provide exactly 3 numeric values.")
        end
    end,
})

minetest.register_chatcommand("dg_sprint_core.remove_delta", {
    params = "speed jump gravity",
    description = "Remove a delta from your current physics settings.",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local values = {}
        for value in param:gmatch("%S+") do
            table.insert(values, tonumber(value))
        end
        if #values == 3 then
            local delta = {speed = values[1], jump = values[2], gravity = values[3]}
            local result = physics_api.remove_physics_delta(player, delta)
            minetest.chat_send_player(name, "Physics delta removed! New override: speed="..result.new_override.speed..", jump="..result.new_override.jump..", gravity="..result.new_override.gravity)
        else
            minetest.chat_send_player(name, "Provide exactly 3 numeric values.")
        end
    end,
})

minetest.register_chatcommand("dg_sprint_core.reset_physics", {
    params = "",
    description = "Reset your physics settings to original values.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        local reset = physics_api.reset_physics(player)
        minetest.chat_send_player(name, "Physics reset! speed="..reset.speed..", jump="..reset.jump..", gravity="..reset.gravity)
    end,
})

minetest.register_chatcommand("dg_sprint_core.show_physics", {
    params = "",
    description = "Display your current physics override values.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        local override = player:get_physics_override()
        minetest.chat_send_player(name, "Current physics: speed="..override.speed..", jump="..override.jump..", gravity="..override.gravity)
    end,
})
