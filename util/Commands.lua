

-- From war of the gods (ty Impboy & Kosjak)
local function cmd_gather_wood(tree,flag)
    local cmd = Commands.new()
    cmd.Flags = cmd.Flags | CMD_FLAG_WOOD_TREE
    if (flag) then
        cmd.Flags = cmd.Flags | CMD_FLAG_CONTINUE_CMD
    end
    cmd.CommandType = CMD_GET_WOOD
    cmd.u.TargetCoord = tree.Pos.D2
    return cmd
end

-- From war of the gods (ty Impboy & Kosjak)
local function cmd_build(shape)
    local cmd = Commands.new()
    cmd.CommandType = CMD_BUILD_BUILDING
    cmd.u.TMIdxs.TargetIdx:set(shape.ThingNum)
    cmd.u.TMIdxs.MapIdx = world_coord2d_to_map_idx(cmd.u.TMIdxs.TargetIdx:get().Pos.D2)
    return cmd
end

local function cmd_dismantle(shape)
    local cmd = Commands.new()
    cmd.CommandType = CMD_DISMANTLE_BUILDING
    cmd.u.TMIdxs.TargetIdx:set(shape.ThingNum)
    cmd.u.TMIdxs.MapIdx = world_coord2d_to_map_idx(cmd.u.TMIdxs.TargetIdx:get().Pos.D2)
    return cmd
end

local function cmd_goto(coord)
    coord = util.to_coord2D(coord)
    local cmd = Commands.new()
    cmd.CommandType = CMD_GOTO_POINT
    cmd.u.TargetCoord = coord
    return cmd
end

local function cmd_patrol(coord)
    coord = util.to_coord2D(coord)
    local cmd = Commands.new()
    cmd.CommandType = CMD_GUARD_AREA_PATROL
    cmd.u.TargetCoord = coord
    return cmd
end

local function cmd_pray(head)
    local cmd = Commands.new()
    cmd.CommandType = CMD_HEAD_PRAY
    cmd.u.TMIdxs.TargetIdx:set(head.ThingNum)
    cmd.u.TMIdxs.MapIdx = world_coord2d_to_map_idx(cmd.u.TMIdxs.TargetIdx:get().Pos.D2)
    return cmd
end

local function cmd_go_in_bldg(bldg)
    local cmd = Commands.new()
    cmd.CommandType = CMD_GO_IN_BLDG
    cmd.u.TargetIdx:set(bldg.ThingNum)
    return cmd
end

-- From war of the gods (ty Impboy & Kosjak)
local function reset_person_cmds(thing)
    remove_all_persons_commands(thing)
    thing.Flags = thing.Flags | TF_RESET_STATE
end


commands = {}
commands.cmd_build = cmd_build
commands.cmd_dismantle = cmd_dismantle
commands.cmd_gather_wood = cmd_gather_wood
commands.cmd_goto = cmd_goto
commands.cmd_patrol = cmd_patrol
commands.cmd_pray = cmd_pray
commands.cmd_go_in_bldg =cmd_go_in_bldg
commands.reset_person_cmds = reset_person_cmds