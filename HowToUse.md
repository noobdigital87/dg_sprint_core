## How to sprint example

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
local step_name = mod_name .. ":SPRINT" -- This will result in "modname:SPRINT".

-- Set the step interval in seconds.
local interval = 0.5

dg_sprint_core.register_step(step_name, interval, function(player, dtime)

    -- It checks if the player has pressed the sprint key or activated double tap
    local sprint_key_detected = dg_sprint_core.is_key_detected()
    
    -- When detected you can let the player sprint
    if sprint_key_detected then
        dg_sprint_core.sprint(player, true) -- Enable sprinting for this player.
    else
        dg_sprint_core.sprint(player, false) -- Disable sprinting for this player.
    end
end)
```


