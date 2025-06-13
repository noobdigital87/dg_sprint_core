-- stored_physics and applied_deltas hold original physics and cumulative delta modifications.
local stored_physics = {}
local applied_deltas = {}

-- suppressed_players now holds a list (stack) of overrides per player:
local suppressed_players = {}

-- Initialize physics tracking for a player.
local function init_physics_tracking(player)
    local name = player:get_player_name()
    if not stored_physics[name] then
        local def = player:get_physics_override()
        stored_physics[name] = { speed = def.speed, jump = def.jump, gravity = def.gravity }
        applied_deltas[name] = { speed = 0, jump = 0, gravity = 0 }
    end
end

-- Computes the composite override using a weighted average strategy.
local function compute_composite_override(name)
    -- Start with the base physics (original + any applied deltas)
    local base = stored_physics[name]
    local deltas = applied_deltas[name]
    local composite = {
        speed   = base.speed   + deltas.speed,
        jump    = base.jump    + deltas.jump,
        gravity = base.gravity + deltas.gravity,
    }

    -- If there are active overrides, accumulate them.
    if suppressed_players[name] and #suppressed_players[name] > 0 then
        local sum = { speed = 0, jump = 0, gravity = 0 }
        local totalWeight = { speed = 0, jump = 0, gravity = 0 }
        for _, entry in ipairs(suppressed_players[name]) do
            local over = entry.override
            local weight = entry.weight or 1
            if over.speed then
                sum.speed = sum.speed + over.speed * weight
                totalWeight.speed = totalWeight.speed + weight
            end
            if over.jump then
                sum.jump = sum.jump + over.jump * weight
                totalWeight.jump = totalWeight.jump + weight
            end
            if over.gravity then
                sum.gravity = sum.gravity + over.gravity * weight
                totalWeight.gravity = totalWeight.gravity + weight
            end
        end

        -- Add contributions from each active override.
        if totalWeight.speed > 0 then
            composite.speed = composite.speed + (sum.speed / totalWeight.speed)
        end
        if totalWeight.jump > 0 then
            composite.jump = composite.jump + (sum.jump / totalWeight.jump)
        end
        if totalWeight.gravity > 0 then
            composite.gravity = composite.gravity + (sum.gravity / totalWeight.gravity)
        end
    end

    return composite
end

-- Applies delta changes; note that this function doesn’t deal with suppression directly.
function core.modify_physics(player, delta)
    local name = player:get_player_name()
    init_physics_tracking(player)

    delta.speed   = delta.speed   or 0
    delta.jump    = delta.jump    or 0
    delta.gravity = delta.gravity or 0

    applied_deltas[name].speed   = applied_deltas[name].speed   + delta.speed
    applied_deltas[name].jump    = applied_deltas[name].jump    + delta.jump
    applied_deltas[name].gravity = applied_deltas[name].gravity + delta.gravity

    local new_override = compute_composite_override(name)
    player:set_physics_override(new_override)
    return { delta = delta, new_override = new_override }
end

-- Adds a new composite override from a mod. Each override should include its modID and optionally, a weight.
function core.suppress_physics(player, override, modID, weight)
    local name = player:get_player_name()
    init_physics_tracking(player)

    if type(override) ~= "table" then
        override = core.default_suppressed
    end

    if not suppressed_players[name] then
        suppressed_players[name] = {}
    end

    table.insert(suppressed_players[name], { id = modID, override = override, weight = weight or 1 })

    -- Recompute and apply the composite override.
    local new_override = compute_composite_override(name)
    player:set_physics_override(new_override)
end

-- Removes a specific mod's override.
function core.restore_physics(player, modID)
    local name = player:get_player_name()
    if not suppressed_players[name] then return end

    for i = #suppressed_players[name], 1, -1 do
        if suppressed_players[name][i].id == modID then
            table.remove(suppressed_players[name], i)
            break
        end
    end

    local new_override = compute_composite_override(name)
    player:set_physics_override(new_override)
end
