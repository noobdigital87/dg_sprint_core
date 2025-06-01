# DG SPRINT: CORE
A full set of API calls and tools for modders who need to adds sprint without any hassle

## API

### 1. ***dg_sprint_core.register_server_step(***`mod_name`, `step_name`, `step_interval`, `step_callback`***)***

When you register a step using this function, it integrates into the global step process, which is the game's continuous update loop. 

Every time the global step runs, it checks all registered steps and executes them at their defined intervals.

So, instead of modifying the global step directly, you use this system to neatly insert your custom logic at controlled time intervals. 

This helps prevent performance issues while ensuring your mod’s functions execute reliably.

#### Example:
```lua

-- retrieve your mod name
local mod_name = core.get_current_modname()

local STEP_NAME = "STEP" -- MAKE SURE IT IS UNQIUE WHEN ADDING MORE STEPS
local STEP_INTERVAL = 0.5

dg_sprint_core.register_server_step(mod_name, STEP_NAME, )

```

### 2. ***dg_sprint_core.sprint_key_detected(***`player`, `enable_aux1`, `enable_double_tap`, `interval`***)***

## TOOLS
