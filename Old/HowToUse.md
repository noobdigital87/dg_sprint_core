## How to use

```lua

--[[
    1. When a player joins give him the appropiate settings.
]]

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
    3. Checks if the player is sprinting and moving. When both are true the draining is enabled and you caN add your logic
]]

local step_name_2 = mod_name .. ":DRAIN"
local drain_interval = 0.2

dg_sprint_core.register_step(step_name_2, drain_interval, function(player, dtime)

    -- Check if the player should lose stamina/hunger while sprinting
    local should_drain = dg_sprint_core.is_draining(player)

    if should_drain then
        -- Add custom draining logic here
    end
end)

--[[
    4. Prevent key detection
        When preventing a key it will completely cancel the sprint and the detection.
        You need to press the sprint button again to sprint again.
]]

local step_name_3 = mod_name .. ":PREVENTION"
local prevention_interval = 0.2

dg_sprint_core.register_step(step_name_3, prevention_interval, function(player, dtime)
    -- Get the players health
    local health = player:get_hp()

    -- Check if the players health is lower then 5 points
    if health < 5 then
        dg_sprint_core.prevent_detection(player, true, mod_name .. ":step_name_3")
    else
        dg_sprint_core.prevent_detection(player, false, mod_name .. ":step_name_3") -- Do not forget to add this when detection needs to work again.
    end
end)

--[[
    5. Sprint cancellations
    When cancelling the player will also stop sprinting but the sprint key is still detected. Maybe when you are in the air and what to cancel the sprint but when on te ground it should continue sprinting.
]]

local step_name_4 = mod_name .. ":CANCELLATION"
local cancellation_interval = 0.2

dg_sprint_core.register_step(step_name_3, cancellation_interval, function(player, dtime)
    -- Get the players health
    local health = player:get_hp()

    -- Check if the players health is lower then 5 points
    if health < 5 then
        dg_sprint_core.cancel_sprint(player, true, mod_name .. ":step_name_4")
    else
        dg_sprint_core.cancel_sprint(player, false, mod_name .. ":step_name_4") -- Do not forget to add this when detection needs to work again.
    end
end)

```

## Default settings in code:

- tap interval = 0.5 
- extra_speed = 0.8
- extra_jump = 0.1



