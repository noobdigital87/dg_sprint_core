if core and type(core.modify_physics) == "function" then return end
    -- core.modify_physics already exists
local stored_physics = {}     -- Will store each player's original physics values.
local applied_deltas = {}     -- Tracks applied delta changes per player.
local suppressed_players = {} -- If a player is suppressed, this table holds their custom override values.
local absolute_overrides = {}  -- Per-player backup for absolute override

function core.set_absolute_physics(player, override)
    local name = player:get_player_name()
    -- Backup current state if not already overridden
    if not absolute_overrides[name] then
        absolute_overrides[name] = {
            stored = stored_physics[name],
            deltas = applied_deltas[name],
            suppressed = suppressed_players[name],
            prev_override = player:get_physics_override()
        }
    end
    player:set_physics_override(override)
end

function core.remove_absolute_physics(player)
    local name = player:get_player_name()
    local backup = absolute_overrides[name]
    if backup then
        -- Restore suppression if it was active
        if backup.suppressed then
            suppressed_players[name] = backup.suppressed
            player:set_physics_override(backup.suppressed)
        elseif backup.stored then
            -- Restore previous physics (including deltas)
            stored_physics[name] = backup.stored
            applied_deltas[name] = backup.deltas
            local new_override = compute_new_override(name)
            player:set_physics_override(new_override)
        else
            -- Fall back to previous override if nothing else
            player:set_physics_override(backup.prev_override or {speed=1, jump=1, gravity=1})
        end
        absolute_overrides[name] = nil
    else
        minetest.log("info", "[PhysicsAPI] No absolute override to remove for player " .. name)
    end
end
-- Initialize physics tracking for a player.
function core.init_physics_tracking(player)
    local name = player:get_player_name()
    if not stored_physics[name] then
        local def = player:get_physics_override()
        stored_physics[name] = {speed = def.speed, jump = def.jump, gravity = def.gravity}
        applied_deltas[name] = {speed = 0, jump = 0, gravity = 0}
    end
end

local function compute_new_override(name)
    if absolute_overrides and absolute_overrides[name] then
        return absolute_overrides[name].override
    end
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
function core.modify_physics(player, delta)
    local name = player:get_player_name()
    core.init_physics_tracking(player)

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

-- Resets a player's physics to the original stored values.
function core.reset_physics(player)
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
function core.suppress_physics(player, override)
    local name = player:get_player_name()
    local suppress_override = override
    if not suppress_override or type(suppress_override) ~= "table" then
        suppress_override = core.default_suppressed
    end
    suppressed_players[name] = suppress_override
    player:set_physics_override(suppress_override)
end

-- Sets custom suppression values per player.
function core.set_player_suppression_values(player, override)
    local name = player:get_player_name()
    if suppressed_players[name] then
        if override and type(override) == "table" then
            suppressed_players[name] = override
            player:set_physics_override(override)
        else
            minetest.log("warning", "[PhysicsAPI] Invalid override provided to set_player_suppression_values for player " .. name)
        end
    else
        minetest.log("info", "[PhysicsAPI] Player " .. name .. " is not suppressed. Use core.suppress_physics() first.")
    end
end

-- Restores a player's physics by removing any suppression.
function core.restore_physics(player)
    local name = player:get_player_name()
    suppressed_players[name] = nil
    local new_override = compute_new_override(name)
    player:set_physics_override(new_override)
end
-- Example chat commands for testing custom suppression features:
--[[
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
        core.suppress_physics(player, override)
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
            core.set_player_suppression_values(player, override)
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
        core.restore_physics(player)
        minetest.chat_send_player(name, "Physics restored!")
    end,
})

minetest.register_chatcommand("dg_sprint_core.reset_physics", {
    params = "",
    description = "Reset your physics settings to original values.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        local reset = core.reset_physics(player)
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

minetest.register_chatcommand("dg_sprint_core.modify_physics", {
    params = "delta_speed delta_jump delta_gravity",
    description = "Modify your physics values by providing delta values (e.g., 0.5 0 0 to increase speed by 0.5).",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            minetest.chat_send_player(name, "Player not found.")
            return
        end
        local values = {}
        for value in param:gmatch("%S+") do
            table.insert(values, tonumber(value))
        end
        if #values == 3 then
            local delta = {speed = values[1], jump = values[2], gravity = values[3]}
            local result = core.modify_physics(player, delta)
            minetest.chat_send_player(
                name,
                "Physics modified! Δspeed="..delta.speed..", Δjump="..delta.jump..", Δgravity="..delta.gravity..
                " | New: speed="..result.new_override.speed..", jump="..result.new_override.jump..", gravity="..result.new_override.gravity
            )
        else
            minetest.chat_send_player(name, "Provide exactly 3 numeric delta values (delta_speed delta_jump delta_gravity).")
        end
    end,
})

]]
