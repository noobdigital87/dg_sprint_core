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

local STEP_NAME1 = "STEP1" -- MAKE SURE IT IS UNQIUE WHEN ADDING MORE STEPS
local STEP_NAME2 = "STEP2"

local STEP_INTERVAL1 = 1
local STEP_INTERVAL2 = 0.5

local function step1(player, player_data, dtime)
    local name = player:get_player_name()

    -- player_data is an empty table that persists and can be used to store variables
    -- In this example I will add 1 to the counter every 0.5 seconds and display it to the chat
    if not player_data.count then
        player_data.count = 0
    else
        player_data.count = player_data.count + 1
    end
end

local function step2(player, player_data, dtime)
    local name = player:get_player_name()

    -- We can retreive the count value we stored in the other step
    local get_number_as_string = tostring(player_data.count)

    core.chat_send_player(name, get_number_as_string)
end
dg_sprint_core.register_server_step(mod_name, STEP_NAME, )

```

### 2. ***dg_sprint_core.sprint_key_detected(***`player`, `enable_aux1`, `enable_double_tap`, `interval`***)***

## TOOLS
