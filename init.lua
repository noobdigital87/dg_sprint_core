local mod_name = core.get_current_modname()

dg_sprint_core = {}

dofile(core.get_modpath(mod_name) .. "/steps/register_server_step.lua")
dofile(core.get_modpath(mod_name) .. "/steps/keyboard.lua")
dofile(core.get_modpath(mod_name) .. "/steps/sprint.lua")
dofile(core.get_modpath(mod_name) .. "/modules/prevent_sprint.lua")
dofile(core.get_modpath(mod_name) .. "/modules/should_drain.lua")