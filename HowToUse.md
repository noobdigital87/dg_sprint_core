## How to use

```lua

--[[
    1. When a player joins give him the appropiate settings
]]
-- Enable sprinting features when a player joins
-- Each player can have customized sprinting settings
core.register_on_joinplayer(function(player)
    dg_sprint_core.enable_aux1(player, true) -- Enable sprinting with the auxiliary key
    dg_sprint_core.enable_double_tap(player, true) -- Enable sprinting with double-tap
    dg_sprint_core.enable_particles(player, true) -- Enable sprint particle effects
    dg_sprint_core.enable_drain(player, true) -- Enable the drain mechanics
end)

--[[
    2. Check if a sprint key or double tap have been triggered and let the player sprint
]]

-- Create a unique step name using the mod name
local mod_name = core.get_current_modname()
local step_name_1 = mod_name .. ":SPRINT" -- Results in "modname:SPRINT"

-- Set the sprinting check interval (in seconds)
local sprint_interval = 0.5

-- Register a step that manages sprinting mechanics
dg_sprint_core.register_step(step_name_1, sprint_interval, function(player, dtime)

    -- Check if the player has activated sprinting (via sprint key or double tap)
    local sprint_key_detected = dg_sprint_core.is_key_detected()

    -- Enable or disable sprinting based on the input
    if sprint_key_detected then
        dg_sprint_core.sprint(player, true) -- Enable sprinting for this player
    else
        dg_sprint_core.sprint(player, false) -- Disable sprinting for this player
    end

    -- Check if the player is sprinting, then perform additional effects or logic
    if dg_sprint_core.is_sprinting(player) then
        -- Add custom sprint-related mechanics here
    end
end)


--[[
    3. Checks if the player is sprinting and not moving. When both are true the draining is enabled and you caN add your logic
]]
-- Sprinting automatically enables draining (e.g., stamina/hunger reduction)
-- Drain prevention is built-in when the player is not moving

-- Create a unique step name for draining functionality
local step_name_2 = mod_name .. ":DRAIN"

-- Set the draining check interval (in seconds)
local drain_interval = 0.2

-- Register a step that manages stamina/hunger drain
dg_sprint_core.register_step(step_name_2, drain_interval, function(player, dtime)
    -- Check if the player should lose stamina/hunger while sprinting
    local should_drain = dg_sprint_core.is_draining(player)

    if should_drain then
        -- Add custom draining logic here
    end
end)
```

## Defaulted settings in code:

- tap interval = 0.5 
- extra_speed = 0.8
- extra_jump = 0.1



