if core and type(core.modify_physics) == "function" then return end

-- core.modify_physics already exists
local stored_physics = {}     -- Will store each player's original physics values.
local applied_deltas = {}     -- Tracks applied delta changes per player.
local suppressed_players = {} -- If a player is suppressed, this table holds their custom override values.

-- Initialize physics tracking for a player.
function init_physics_tracking(player)
    local name = player:get_player_name()
    if not stored_physics[name] then
        local def = player:get_physics_override()
        stored_physics[name] = {speed = def.speed, jump = def.jump, gravity = def.gravity}
        applied_deltas[name] = {speed = 0, jump = 0, gravity = 0}
    end
end

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
function core.modify_physics(player, delta)
    local name = player:get_player_name()
    init_physics_tracking(player)

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

-- Restores a player's physics by removing any suppression.
function core.restore_physics(player)
    local name = player:get_player_name()
    suppressed_players[name] = nil
    local new_override = compute_new_override(name)
    player:set_physics_override(new_override)
end
