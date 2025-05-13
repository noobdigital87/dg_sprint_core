# API Guide

The mod enhances player movement in Minetest by adding sprinting capabilities along with advanced features such as double-tap activation, super sprint mode, and particle effects. This guide explains each global API function available in the mod and shows you how to use them in your own code.

## Overview

The sprint mod introduces a set of global API functions under the `dg_sprint_core` namespace. These functions allow you to:

- **Enable/disable sprinting** for players.
- **Adjust player attributes** like extra speed and jump height during sprint.
- **Control visual effects** such as particles when sprinting.
- **Toggle auxiliary and double-tap sprinting features.**
- **Register custom server steps** for periodic conditions affecting sprinting.

By using these functions, you can easily modify how sprinting behaves in your game to fit your design and gameplay requirements.

## Global API Functions

### 1. `dg_sprint_core.sprint(player, sprinting)`

- **Usage:** Enable or disable sprint mode for the specified player.
- **Parameters:**
	- `player`: The player object.
	- `sprinting`: Boolean (`true` to enable sprint, `false` to disable sprint).
- **Description:**
  This function applies the sprint bonus—adding extra speed and jump—to the player. It supports multiple mods (e.g., `player_monoids` and `pova`), and if none are available, it falls back to directly using physics overrides. If particle effects are enabled, particles are also generated during sprint.

---

### 2. `dg_sprint_core.cancel_sprint(player, cancel, reason)`

- **Usage:** Mark or remove a cancellation reason for sprinting.
- **Parameters:**
	- `player`: The player object.
	- `cancel`: Boolean (`true` to add a cancellation reason; `false` to remove it).
	- `reason`: A string identifier for the reason (e.g., `"attached"`, `"in_air"`).
- **Description:**
  Some situations require that sprinting be disabled temporarily. By using this function, you can add or remove reasons that cancel sprinting, ensuring the player's sprint state is only active when allowed.

---

### 3. `dg_sprint_core.is_sprinting(player)`

- **Usage:** Check if the player is currently sprinting.
- **Parameters:**
  - `player`: The player object.
- **Returns:**
  A boolean value (`true` if sprinting, `false` if not).
- **Description:**
  This function is useful when you need to perform logic based on whether a player is sprinting (for example, toggling effects or behaviors).

---

### 4. `dg_sprint_core.set_speed(player, extra_speed)`

- **Usage:** Adjust the extra speed bonus applied during sprinting.
- **Parameters:**
  - `player`: The player object.
  - `extra_speed`: A numeric value that increases the player's speed when sprinting.
- **Description:**
  Use this function to change the sprint speed bonus dynamically. It lets you tailor sprint behavior or even alter it in response to game events.

---

### 5. `dg_sprint_core.set_jump(player, extra_jump)`

- **Usage:** Adjust the extra jump bonus applied during sprinting.
- **Parameters:**
  - `player`: The player object.
  - `extra_jump`: A numeric value that increases the player's jump height when sprinting.
- **Description:**
  Increase or decrease the jump enhancement provided during sprint, which can help balance gameplay.

---

### 6. `dg_sprint_core.set_particles(player, value)`

- **Usage:** Enable or disable sprint particle effects.
- **Parameters:**
  - `player`: The player object.
  - `value`: Boolean (`true` to enable particles, `false` to disable).
- **Description:**
  Particle effects can be used to visually indicate that sprinting is active. You can control this on a per-player basis.

---

### 7. `dg_sprint_core.set_aux1(player, value)`

- **Usage:** Enable or disable sprint activation via the auxiliary key.
- **Parameters:**
  - `player`: The player object.
  - `value`: Boolean (`true` to enable, `false` to disable).
- **Description:**
  This function controls whether players can use the auxiliary key (often used as an alternative sprint activation method).

---

### 8. `dg_sprint_core.set_double_tap(player, value)`

- **Usage:** Enable or disable double-tap to sprint.
- **Parameters:**
  - `player`: The player object.
  - `value`: Boolean (`true` to enable, `false` to disable).
- **Description:**
  Double-tapping a movement key can trigger sprinting. Use this function to toggle that behavior.

---

### 9. `dg_sprint_core.is_supersprinting(player)`

- **Usage:** Check if the player is in super sprint mode.
- **Parameters:**
  - `player`: The player object.
- **Returns:**
  A boolean indicating super sprint status.
- **Description:**
  Super sprint gives an extra multiplier to the sprint speed. This function lets you query whether that mode is active.

---

### 10. `dg_sprint_core.register_server_step(mod_name, name, interval, callback)`

- **Usage:** Register a new server step (a periodic function call) for customized logic.
- **Parameters:**
  - `mod_name`: The name of your mod.
  - `name`: A unique identifier for your server step.
  - `interval`: The interval (in seconds) at which the callback should run.
  - `callback`: A function that receives the elapsed time as its argument.
- **Description:**
  This function allows you to implement custom conditions that affect sprinting or any other behavior. For example, you can automatically cancel sprint if a player is attached to another object or if certain game conditions are met.

---

## Final Thoughts

This guide has shown you how to integrate the sprint mod’s API into your own modifications. By using these functions, you can:

- Fine-tune the sprinting mechanics (speed, jump, visual effects).
- Control when sprinting should or should not occur using cancellation reasons.
- Leverage custom server steps for periodic checks and additional game logic.

Experiment with these settings to craft engaging movement experiences for your players. You might also consider adding further enhancements, such as integrating with other mods or creating entirely new movement mechanics.

Happy modding!

---
