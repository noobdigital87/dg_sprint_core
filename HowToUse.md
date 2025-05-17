## How to use

```lua

-- When a player joins, enable sprinting features
-- It is possible to change the features for each player individually
core.register_on_joinplayer(function(player)
    dg_sprint_core.enable_aux1(player, true)
    dg_sprint_core.enable_double_tap(player, true)
    dg_sprint_core.enable_particles(player, true)
end)

-- Make your step name unique
local mod_name = core.get_current_modname()
local step_name_1 = mod_name .. ":SPRINT" -- This will result in "modname:SPRINT".

-- Set the step interval in seconds.
local sprint_interval = 0.5

dg_sprint_core.register_step(step_name_1, sprint_interval, function(player, dtime)

    -- It checks if the player has pressed the sprint key or activated double tap
    local sprint_key_detected = dg_sprint_core.is_key_detected()
    
    -- When detected you can let the player sprint
    if sprint_key_detected then
        dg_sprint_core.sprint(player, true) -- Enable sprinting for this player.
    else
        dg_sprint_core.sprint(player, false) -- Disable sprinting for this player.
    end

    -- when the API dg_sprint_core.sprint gets called you can check the state if a player is sprinting and do some magic
    if dg_sprint_core.is_sprinting(player) then
        -- Do the magic
    end
end)

-- When you are sprinting the draining will set to true automaticly.
-- It has a built in prevention from draining when not moving.

local step_name_2 = mod_name .. ":DRAIN"
local drain_interval = 0.2

dg_sprint_core.register_step(step_name_2, drain_interval, function(player, dtime)
    -- check if the player should drain stamina/hunger etc.
    local should_drain = dg_sprint_core.is_draining(player)

    if should_drain then
        -- Do your magic
    end
end)

```


