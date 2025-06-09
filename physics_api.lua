physics_api = {
    _identifier = "shared_physics_api", -- Unique identifier for detection
}

for key, value in pairs(_G) do
    if type(value) == "table" and value._identifier == "shared_physics_api_v1" then
        -- Found another instance of the same API, use it instead of redefining
        physics_api = value
        minetest.log("warning",
                        "[PhysicsAPI] Another mod has already registered a shared physics API under '" ..
                        key .. "'. Using that instance."
                    )
        break
    end
end

-- If no existing API was found, register this one globally
_G.physics_api = physics_api

local stored_physics = {}
local applied_deltas = {}

-- Function to initialize physics tracking for a player
function physics_api.init_physics_tracking(player)
    local name = player:get_player_name()
    if not stored_physics[name] then
        local def = player:get_physics_override()
        stored_physics[name] = {speed = def.speed, jump = def.jump, gravity = def.gravity}
        applied_deltas[name] = {speed = 0, jump = 0, gravity = 0}
    end
end

-- Function to safely compute the new physics override based on stored values and applied deltas.
local function compute_new_override(name)
    return {
        speed   = stored_physics[name].speed + applied_deltas[name].speed,
        jump    = stored_physics[name].jump + applied_deltas[name].jump,
        gravity = stored_physics[name].gravity + applied_deltas[name].gravity,
    }
end

-- Function to modify physics with delta tracking and return what was changed.
function physics_api.modify_physics(player, delta)
    local name = player:get_player_name()
    physics_api.init_physics_tracking(player)

    -- Ensure delta values exist
    delta.speed   = delta.speed   or 0
    delta.jump    = delta.jump    or 0
    delta.gravity = delta.gravity or 0

    -- Apply the delta change
    applied_deltas[name].speed   = applied_deltas[name].speed   + delta.speed
    applied_deltas[name].jump    = applied_deltas[name].jump    + delta.jump
    applied_deltas[name].gravity = applied_deltas[name].gravity + delta.gravity

    -- Compute the new physics override from the stored base plus all applied deltas.
    local new_override = compute_new_override(name)
    player:set_physics_override(new_override)

    -- Return what was applied and the new override values.
    return { delta = delta, new_override = new_override }
end

-- Function to remove a specific physics delta and return the change.
function physics_api.remove_physics_delta(player, delta)
    local name = player:get_player_name()
    if not applied_deltas[name] then return end

    -- Ensure delta values exist
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

-- Function to reset physics to original values and return the reset state.
function physics_api.reset_physics(player)
    local name = player:get_player_name()
    local reset_values = {}
    if stored_physics[name] then
        reset_values = stored_physics[name]
        player:set_physics_override(reset_values)
        stored_physics[name] = nil
        applied_deltas[name] = nil
    else
        reset_values = {speed = 1, jump = 1, gravity = 1}
        player:set_physics_override(reset_values)
    end
    return reset_values
end

-- Register the API globally
_G.physics_api = physics_api

