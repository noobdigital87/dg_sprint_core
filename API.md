# Register a server Step

dg_sprint_core.register_server_step(`name`, `interval`, `callback`)

### Parameters:
  - `name`: A unique identifier for the server step.
  - `interval`: The time interval (in seconds) at which the callback should be executed.
  - `callback`: The function to be called periodically. It takes two parameters:
    - `player`: The player object.
    - `dtime`: The amount of time that has passed since the last global step.

### Description:
  Registers a custom server step with the specified interval and callback function. This allows for periodic execution of code related to players, such as sprinting mechanics.

### Example Usage:

```lua
local mod_name = core.get_current_modname()
-- Register a server step named "sprint_check" that runs every 0.5 seconds.
dg_sprint_core.register_server_step(mod_name .. "sprint_check", 0.5, function(player, dtime)
    -- Your code here to handle sprinting mechanics for the player.
end)

```

# Check if a key is Detected

dg_sprint_core.is_key_detected(`player`)
### Parameters:
  - `player`: The player object.

### Returns:
  A boolean indicating whether the key associated with sprinting has been detected for the given player.

### Description:
  This function checks if the sprinting key (or combination of keys) is currently being pressed by the player. It can be used to determine if the player should enter or exit a sprinting state.

### Example Usage:
```lua
-- Check if the sprinting key is detected for a specific player.
local is_detected = dg_sprint_core.is_key_detected(player)
if is_detected then
    -- Perform actions when the sprinting key is detected.
end
```

# Check if super sprint is active

dg_sprint_core.is_super_sprint_active(`player`)
### Parameters:
  - `player`: The player object.

### Returns:
  A boolean indicating whether the super sprint mode is currently active for the given player.

### Description:
  This function checks if the player has activated the super sprint mode. It can be used to modify player movement or apply special effects when super sprinting is enabled.
### Example Usage:

```lua
-- Check if super sprint is active for a specific player.
local is_super_sprint_active = dg_sprint_core.is_super_sprint_active(player)
if is_super_sprint_active then
    -- Apply super sprint effects or modify movement speed.
end
```

# Enable or disable aux1 key

dg_sprint_core.enable_aux1(`player`, `enable`)
### Parameters:
  - `player`: The player object.
  - `enable`: A boolean indicating whether to enable (`true`) or disable (`false`) the aux1 key.

### Description:
  This function allows you to toggle the use of the aux1 key for a specific player. When enabled, pressing the aux1 key will trigger additional actions defined in your mod.


### Example Usage:
```lua
-- Enable the aux1 key for a specific player.
dg_sprint_core.enable_aux1(player, true)

-- Disable the aux1 key for a specific player.
dg_sprint_core.enable_aux1(player, false)
```

# Enable or disable Super Sprint

dg_sprint_core.enable_ssprint(`player`, `enable`)
### Parameters:
  - `player`: The player object.
  - `enable`: A boolean indicating whether to enable (`true`) or disable (`false`) the super sprint.

### Description:
  This function allows you to toggle super sprint for a specific player.

### Example Usage:
```lua
-- Enable ssprint for a specific player.
dg_sprint_core.enable_ssprint(player, true)

-- Disable ssprint for a specific player.
dg_sprint_core.enable_ssprint(player, false)
```

# Enable or disable double tap

dg_sprint_core.enable_double_tap(`player`, `enable`)
### Parameters:
  - `player`: The player object.
  - `enable`: A boolean indicating whether to enable (`true`) or disable (`false`) the double tap.

### Description:
  This function allows you to toggle the double tap for a specific player.

### Example Usage:
```lua
-- Enable double tap for a specific player.
dg_sprint_core.enable_double_tap(player, true)

-- Disable double tap for a specific player.
dg_sprint_core.enable_double_tap(player, false)
```

# Set the tap interval

dg_sprint_core.set_tap_interval(`player`, `interval`)
### Parameters:
  - `player`: The player object.
  - `interval`: The new tap interval (in seconds).

### Description:
  Sets the tap interval for a specific player. This interval determines the minimum time between valid taps for sprint activation.

### Example Usage:

```lua
-- Set the tap interval for a specific player to 0.3 seconds.
dg_sprint_core.set_tap_interval(player, 0.3)

```

# Check if a player is sprinting

dg_sprint_core.is_sprinting(`player`)

### Parameters:
- `player`: The player object.

### Returns:
- A boolean indicating whether the player is currently sprinting.

### Description:
This function checks whether the player is currently in a sprinting state. It uses internal player data to determine the sprinting status and can be useful for conditionally applying movement modifiers or visual effects based on the player's current action.

### Example Usage:
```lua
-- Check if the player is sprinting.
local is_sprinting = dg_sprint_core.is_sprinting(player)
if is_sprinting then
    -- Apply sprinting effects or modify movement speed.
end
```

# Set Sprint State

dg_sprint_core.sprint(`player`, sprinting)

### Parameters:
- `player`: The player object.
- `sprinting`: A boolean indicating whether the player should be set to sprinting (`true`) or not sprinting (`false`).

### Description:
This function sets the sprinting state of a player. It modifies the player's physics properties such as speed and jump height based on the sprinting status. If the player is already in the desired sprinting state, this function has no effect.

# Cancel sprint

dg_sprint_core.cancel_sprint(`player`, cancel, reason)

### Parameters:
- `player`: The player object.
- `cancel`: A boolean indicating whether to cancel the sprint (`true`) or not (`false`).
- `reason`: A string describing the reason for cancelling the sprint.

### Description:
This function manages the cancellation of a sprint. It records the reasons why a sprint was cancelled and can be used to track multiple cancellation reasons simultaneously. If the player is already in the desired state (either sprinting or not), this function has no effect.

# Example Usage

```lua
local player = minetest.get_player_by_name("example_player")
if player then
    dg_sprint_core.sprint(player, true)  -- Start sprinting
    minetest.after(10, function()
       dg_sprint_core.cancel_sprint(player, true, "timeout")  -- Cancel sprint after 10 seconds
    end)
    -- It will keep cancelling the sprint until dg_sprint_core.cancel_sprint(player, false, "timeout") 
end
```

# Set extra speed

dg_sprint_core.set_speed(`player`, `extra_speed`)

### Parameters:
- `player`: The player object.
- `extra_speed`: A number representing the additional speed to be applied during sprinting.

### Description:
This function sets an additional speed multiplier for a player when they are sprinting. This can be used to enhance the sprinting experience by making it faster.

### Example:

```lua
local player = minetest.get_player_by_name("example_player")
if player then
   dg_sprint_core.set_speed(player, 1.5)  -- Set extra speed multiplier to 1.5x
end
```

# Set extra jump height

dg_sprint_core.set_jump(`player`, `extra_jump`)

### Parameters:
- `player`: The player object.
- `extra_jump`: A number representing the additional jump height to be applied during sprinting.

### Description:
This function sets an additional jump height multiplier for a player when they are sprinting. This can be used to enhance the sprinting experience by making jumps higher.
### Example:
```lua
local player = minetest.get_player_by_name("example_player")
if player then
  dg_sprint_core.set_jump(player, 1.2)  -- Set extra jump height multiplier to 1.2x
end
```
# Enable or disable sprint particles

dg_sprint_core.enable_particles(`player`, `enable`)

### Parameters:
- `player`: The player object.
- `enable`: A boolean value (`true` or `false`) indicating whether to enable or disable sprint particles.

### Description:
This function enables or disables the visual particles that appear when a player is sprinting. This can be used to customize the appearance of the sprinting effect in the game.
### Example:
```lua 
local player = minetest.get_player_by_name("example_player")
if player then
  dg_sprint_core.enable_particles(player, true)  -- Enable sprint particles
end
```

Sure! Here's the updated API documentation with the new function `dg_sprint_core.is_draining` added, including its explanation:

---

# Check if a player's sprint is draining

dg_sprint_core.is_draining(`player`)

### Parameters:
- `player`: The player object.

### Returns:
- A boolean indicating whether the player's sprint resource is currently being drained.

### Description:
This function checks whether a player's sprint stamina or resource is being depleted. It retrieves the relevant data from the `player_data` table associated with the player’s name. This can be useful for implementing stamina-based sprint mechanics or triggering effects when a player's sprinting energy is low.

### Example Usage:
```lua
-- Check if a player's sprint is currently draining.
local is_draining = dg_sprint_core.is_draining(player)
if is_draining then
    -- Apply stamina drain effects or reduce movement speed.
end
```

---
