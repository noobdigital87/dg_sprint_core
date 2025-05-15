local mod_name = core.get_current_modname()

local settings = {
    liquid_cancel = core.settings:get_bool("dg_sprint_core.liquid", false),
    snowy_cancel = core.settings:get_bool("dg_sprint_core.snowy", false),
    hp_cancel = core.settings:get_bool("dg_sprint_core.hp", false),
    hp_threshold = tonumber(core.settings:get("dg_sprint_core.hp_threshold")) or 6.0,
    climbable_cancel = core.settings:get_bool("dg_sprint_core.climbable", false),
    wall_cancel = core.settings:get_bool("dg_sprint_core.wall", false),
}

local intervals = 0.5

local STEPS = {
    LIQUID_STEP = {
        INTERVAL = intervals,
        NAME = mod_name ..":LIQUID_STEP",
        CALLBACK = function(player, dtime)
            if settings.liquid_cancel then
                local pos = player:get_pos()
                local node_below = core.get_node_or_nil(pos)
                if node_below then
                    local def = minetest.registered_nodes[node_below.name] or {}
                    local drawtype = def.drawtype
                    local is_liquid = drawtype == "liquid" or drawtype == "flowingliquid"
                    if is_liquid then
                        dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:liquid")
                    else
                        dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:liquid")
                    end
                end
            end
        end
    },
    SNOWY_STEP = {
        INTERVAL = intervals,
        NAME = mod_name ..":SNOWY_STEP",
        CALLBACK = function(player, dtime)
            if settings.snowy_cancel then
                local pos = player:get_pos()
                local check_pos = { x = pos.x, y = pos.y + 0.5, z = pos.z }
                local node = core.get_node_or_nil(check_pos)
                if node then
                    local def = core.registered_nodes[node.name] or {}
                    if def and def.groups and def.groups.snowy and def.groups.snowy > 0 then
                        dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:snowy")
                    else
                        dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:snowy")
                    end
                end
            end
        end
    },
    LOW_HP_STEP = {
        INTERVAL = intervals,
        NAME = mod_name ..":LOW_HP_STEP",
        CALLBACK = function(player, dtime)
            if settings.hp_cancel then
                if player:get_hp() < settings.hp_threshold then
                    dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:low_hp")
                else
                    dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:low_hp")
                end
            end
        end     
    },
    CLIMBABLE_STEP = {
        INTERVAL = intervals,
        NAME = mod_name ..":CLIMBABLE_STEP",
        CALLBACK = function(player, dtime)
            if settings.climbable_cancel then
                local pos = player:get_pos()
                local node_below = core.get_node_or_nil(pos)
                if node_below then
                    local def = minetest.registered_nodes[node_below.name] or {}
                    if def and def.climbable then
                        dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:climbable")
                    else
                        dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:climbable")
                    end
                end
            end
        end     
    },
    WALL_STEP = {
        INTERVAL = intervals,
        NAME = mod_name ..":WALL_STEP",
        CALLBACK = function(player, dtime)
            if settings.wall_cancel then
                    -- Get the player's base position.
                local base_pos = player:get_pos()
                local properties = player:get_properties()
                local eye_height = (properties and properties.eye_height) or 0.5 -- Fallback in case eye_height is not set

                -- Define two positions:
                -- Lower position uses a fixed offset of 0.5.
                local lower_pos = {
                    x = base_pos.x,
                    y = base_pos.y + 0.5,
                    z = base_pos.z
                }
                -- Upper position uses the player's eye height.
                local upper_pos = {
                    x = base_pos.x,
                    y = base_pos.y + eye_height,
                    z = base_pos.z
                }
            
                -- Calculate horizontal direction (ignoring any vertical tilt).
                local angle = player:get_look_horizontal()
                local direction = vector.rotate_around_axis(
                    {x = 0, y = 0, z = 1},
                    {x = 0, y = 0, z = 0},
                    angle
                )
                direction = vector.normalize(direction)
            
                -- Calculate target positions (one node ahead) for both lower and upper checks.
                local target_lower = vector.round(vector.add(lower_pos, direction))
                local target_upper = vector.round(vector.add(upper_pos, direction))
            
                -- Get the nodes at the target positions.
                local node_lower = minetest.get_node(target_lower)
                local node_upper = minetest.get_node(target_upper)
            
                -- Retrieve registered node definitions (these contain properties such as walkability).
                local reg_node_lower = minetest.registered_nodes[node_lower.name]
                local reg_node_upper = minetest.registered_nodes[node_upper.name]
            
                -- Check conditions for each node:
            
                local lower_is_wall = reg_node_lower and reg_node_lower.walkable
                local upper_is_wall = reg_node_upper and reg_node_upper.walkable
            
                if (lower_is_wall or upper_is_wall) then
                    dg_sprint_core.cancel_sprint(player, true, "dg_sprint_core:wall")
                else
                    dg_sprint_core.cancel_sprint(player, false, "dg_sprint_core:wall")
                end
            end
        end
    }
}


for _, step in pairs(STEPS) do
    dg_sprint_core.register_server_step(step.NAME, step.INTERVAL, step.CALLBACK)
end
