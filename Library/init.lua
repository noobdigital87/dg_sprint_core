local mod_name = core.get_current_modname()

local mod_dir = core.get_modpath(mod_name) .. "/"

local server_lib_dir = mod_dir .. "Library/Server/"
local keyboard_lib_dir = mod_dir .. "Library/Keyboard/"
local nodes_lib_dir = mod_dir .. "Library/Nodes/"
local player_lib_dir = mod_dir .. "Library/Player/"
local version_2_dir = mod_dir .. "Library/V2/"
-- Keyboard Library
dofile(keyboard_lib_dir .. "IsSprintKeyDetected.lua")

-- Nodes
dofile(nodes_lib_dir .. "GetNodeDefinition.lua")
dofile(nodes_lib_dir .. "IsNodeWalkable.lua")
dofile(nodes_lib_dir .. "IsNodeLiquid.lua")
dofile(nodes_lib_dir .. "IsNodeSnow.lua")
-- Server
dofile(server_lib_dir .. "RegisterStep.lua")

-- Player
dofile(player_lib_dir .. "Sprint.lua")
dofile(player_lib_dir .. "ShowParticles.lua")
dofile(player_lib_dir .. "IsMoving.lua")
dofile(player_lib_dir .. "ExtraDrainCheck.lua")
dofile(player_lib_dir .. "ExtraSprintCheck.lua")
dofile(player_lib_dir .. "SetFov.lua")
dofile(player_lib_dir .. "IsPlayerHangGliding.lua")

dofile(version_2_dir .. "init.lua")
