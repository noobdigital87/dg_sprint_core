dg_sprint_core = {}

--[[ START LIB INIT ]]--
local mod_name = core.get_current_modname()

local mod_dir = core.get_modpath(mod_name) .. "/"

local lib_dir = mod_dir .. "Library/"

dofile(lib_dir .. "init.lua")
--[[ END LIB INIT ]]


