if core and type(core.modify_physics) == "function" then return end

-- Store each player's base/original physics values.
local base_physics = {}

-- Tracks cumulative delta adjustments for each player.
local cumulative_deltas = {}

-- Each player's active override contributions (as a stack of effect entries).
local active_overrides = {}

-- Initialize physics tracking for a player.
function init_physics_tracking(player)
    local name = player:get_player_name()
    if not base_physics[name] then
        local def = player:get_physics_override()
        base_physics[name] = { speed = def.speed, jump = def.jump, gravity = def.gravity }
        cumulative_deltas[name] = { speed = 0, jump = 0, gravity = 0 }
    end
end

-- Composite calculation: blending base physics, delta adjustments, and active overrides.
local function compute_composite_override(name)
    local base = base_physics[name]
    local deltas = cumulative_deltas[name]
    local composite = {
        speed   = base.speed   + deltas.speed,
        jump    = base.jump    + deltas.jump,
        gravity = base.gravity + deltas.gravity,
    }
    if active_overrides[name] and #active_overrides[name] > 0 then
        local sum = { speed = 0, jump = 0, gravity = 0 }
        local totalWeight = { speed = 0, jump = 0, gravity = 0 }
        for _, entry in ipairs(active_overrides[name]) do
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

-- Modifies physics using delta adjustments.
function core.modify_physics(player, delta)
    local name = player:get_player_name()
    init_physics_tracking(player)
    delta.speed   = delta.speed   or 0
    delta.jump    = delta.jump    or 0
    delta.gravity = delta.gravity or 0
    cumulative_deltas[name].speed   = cumulative_deltas[name].speed   + delta.speed
    cumulative_deltas[name].jump    = cumulative_deltas[name].jump    + delta.jump
    cumulative_deltas[name].gravity = cumulative_deltas[name].gravity + delta.gravity
    local new_override = compute_composite_override(name)
    player:set_physics_override(new_override)
    return { delta = delta, new_override = new_override }
end

-- Applies a new override contribution from a mod.
function core.apply_override(player, override, modID, weight)
    local name = player:get_player_name()
    init_physics_tracking(player)
    if type(override) ~= "table" then
        override = core.default_suppressed
    end
    if not active_overrides[name] then
        active_overrides[name] = {}
    end
    table.insert(active_overrides[name], { id = modID, override = override, weight = weight or 1 })
    local new_override = compute_composite_override(name)
    player:set_physics_override(new_override)
end

-- Removes a specific override contribution.
function core.remove_override(player, modID)
    local name = player:get_player_name()
    if not active_overrides[name] then return end
    for i = #active_overrides[name], 1, -1 do
        if active_overrides[name][i].id == modID then
            table.remove(active_overrides[name], i)
            break
        end
    end
    local new_override = compute_composite_override(name)
    player:set_physics_override(new_override)
end
