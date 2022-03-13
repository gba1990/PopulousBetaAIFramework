import(Module_Map)
import(Module_Game)

-- Global, cause its useful
function GetTurn()
    return getTurn()
end

-- War of the gods
function everyPow(a,b)
  if (GetTurn() % a^b == 0) then
    return true else return false
  end
end

-- War of the gods
function every2Pow(a)
  if (GetTurn() % 2^a == 0) then
    return true else return false
  end
end

local function randomItemFromTable(t)
  if (#t == 0) then
    return nil
  end

  return t[math.random(1, #t)]
end

-- War of the gods
local function tableContains(table, input)
  for i,v in ipairs(table) do
    if (v == input) then
      return true
    end
  end

  return false
end

-- S click effect (if target is shaman)
local function spellTargetThing(spellThing, targetThing)
  spellThing.u.Spell.TargetThingIdx:set(targetThing.ThingNum)
end

local function _movePersonToPointCallbackChecker(thing, point, time, callback)
  -- thing died or similar or time run out
  if (thing == nil or time <= 0) then
    callback(false)
    return
  end

  local distance = get_world_dist_xyz(thing.Pos.D3, util.coord2D_to_coord3D(point))
  if (distance <= 600) then
    callback(true)
    return
  end

  -- Check again in 12 turns
  local checkInterval = 12
  subscribe_ExecuteOnTurn(GetTurn() + checkInterval, function()
    _movePersonToPointCallbackChecker(thing, point, time - checkInterval, callback)
  end)
end

local function commandPersonGoToPoint(thing, point, time, callback)
  local p = util.to_coord2D(point)
  command_person_go_to_coord2d(thing, p)
  subscribe_ExecuteOnTurn(GetTurn()+12, function()
    _movePersonToPointCallbackChecker(thing, point, time, callback)
  end)
end

local function commandPersonToPatrol(thing, ...)
  commands.reset_person_cmds(thing)
  for i = 1, select('#', ...), 1 do
    local p = select(i, ...)
    add_persons_command(thing, commands.cmd_patrol(p), i-1)
  end
end

local function placePlan(coordinates, bldg_model, owner, orientation)
  if (orientation == nil) then
    orientation = util.randomItemFromTable({0,1,2,3})
  end

  local ret = process_shape_map_elements(world_coord2d_to_map_idx(util.to_coord2D(coordinates)), bldg_model, orientation, owner, SHME_MODE_SET_PERM)
end

-- War of the gods
local function sendPersonToBuild(personThing, shapeThing, treeToHarvest)
  commands.reset_person_cmds(personThing)
  local idx = 0
  if (treeToHarvest ~= nil) then
    add_persons_command(personThing, commands.cmd_gather_wood(treeToHarvest, true), idx)
    idx = idx + 1
  end
  add_persons_command(personThing, commands.cmd_build(shapeThing), idx)
end

local function sendPersonToDismantle(personThing, shapeThing)
  commands.reset_person_cmds(personThing)
  add_persons_command(personThing, commands.cmd_dismantle(shapeThing), 0)
end

-- ty kosjak
local function tableLength(te)
  local count = 0
  for _ in pairs(te) do count = count + 1 end
  return count
end

local function clone_Coord3D(coord)
  local result = Coord3D.new()
  result.Xpos = coord.Xpos
  result.Ypos = coord.Ypos
  result.Zpos = coord.Zpos
  return result
end

local function clone_Coord2D(coord)
  local result = Coord2D.new()
  result.Xpos = coord.Xpos
  result.Zpos = coord.Zpos
  return result
end

local function create_Coord2D(Xpos, Zpos)
  local result = Coord2D.new()
  result.Xpos = Xpos
  result.Zpos = Zpos
  return result
end

local function create_Coord3D(Xpos, Ypos, Zpos)
  local result = Coord3D.new()
  result.Xpos = Xpos
  result.Ypos = Ypos
  result.Zpos = Zpos
  return result
end

local function c3D_to_c2D(_3d)
  local result = Coord2D.new()
  coord3D_to_coord2D(_3d, result)
  return result
end

local function c2D_to_c3D(_2d)
  local result = Coord3D.new()
  coord2D_to_coord3D(_2d, result)
  return result
end

local function to_c3D(_coord)
  local result = Coord3D.new()
  result.Xpos = _coord.Xpos
  result.Ypos = 0
  result.Zpos = _coord.Zpos

  if (_coord.Ypos ~= nil) then
    result.Ypos = _coord.Ypos
  end

  return result
end

local function to_c2D(_coord)
  local result = Coord2D.new()
  result.Xpos = _coord.Xpos
  result.Zpos = _coord.Zpos
  return result
end

local function add_c3D(c1, c2)
  local result = Coord3D.new()
  result.Xpos = c1.Xpos + c2.Xpos
  result.Ypos = c1.Ypos + c2.Ypos
  result.Zpos = c1.Zpos + c2.Zpos
  return result
end

local function mapCellToCoord2D(cellX, cellY)
  return util.to_coord2D(MAP_XZ_2_WORLD_XYZ(cellX, cellY))
end

local function isPersonInHut(thing)
  return (TF_BLDG_DWELLER & thing.Flags) > 0 and 
          is_person_in_drum_tower(thing) == 0 and 
          is_person_currently_attacking_a_building(thing) == 0 and 
          is_person_in_training_bldg(thing) == 0 and
          is_person_in_bldg_training(thing) == 0
end

local function markBuildingToDismantle(thing, value)
  if (value or value == nil) then
    thing.u.Bldg.Flags = thing.u.Bldg.Flags | TF_BACKWARDS_MOTION
  else
    thing.u.Bldg.Flags = thing.u.Bldg.Flags ~ TF_BACKWARDS_MOTION
  end
end

local function isMarkedAsDismantle(thing)
  return thing.u.Bldg.Flags & TF_BACKWARDS_MOTION > 0
end

local function isPersonDismantlingBuilding(personThing, buildingThing)
  if (personThing == nil or buildingThing == nil) then
    return false
  end

  local commands = get_thing_curr_cmd_list_ptr(personThing)
  if (commands ~= nil and commands.CommandType == CMD_DISMANTLE_BUILDING) then
    local target = commands.u.TMIdxs.TargetIdx:get()
    if (target ~= nil and buildingThing.ThingNum == target.ThingNum) then
      return true
    end
  end
  return false
end

local function getMaxPopulationOfTribe(tribe)
  local result = 5 -- Minimun population on any level
  local player = getPlayer(tribe)
  
  result = result + player.NumBuildingsOfType[M_BUILDING_TEPEE] * 3
  result = result + player.NumBuildingsOfType[M_BUILDING_TEPEE_2] * 5
  result = result + player.NumBuildingsOfType[M_BUILDING_TEPEE_3] * 7

  return result
end

local function estimateTimeToChargeOneShot(tribe, spell)
  local p = getPlayer(tribe)
  local spellCost = spells_type_info()[spell].Cost
  local manaUpdateInterval = 4
  return (spellCost/p.LastManaIncr) * manaUpdateInterval
end

-- Fisher-Yates shuffle: https://gist.github.com/Uradamus/10323382
local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end


local function isShamanCasting(shaman)
  return shaman.State == S_PERSON_SPELL_TRANCE
end

-- Useful to randomly set patrols in an area, making them not to close to the water
local function randomLandPointSurroundedByLandInArea(center, radius)
  center = util.to_coord3D(center)
  local allLandPoints = {}
  SearchMapCells(CIRCULAR, 0, 0, math.ceil(radius/512), world_coord3d_to_map_idx(center), function(me)
    local c2 = Coord2D.new()
    map_ptr_to_world_coord2d(me, c2)

    local isValid = true
    isValid = isValid and is_map_elem_all_land(me) == 1
    isValid = isValid and is_building_on_map_cell(world_coord2d_to_map_idx(c2)) == 0
    isValid = isValid and is_map_cell_obstacle_free(world_coord2d_to_map_idx(c2)) == 1
    isValid = isValid and are_surround_cells_all_land(world_coord2d_to_map_idx(c2)) == 1

    if (isValid) then
      table.insert(allLandPoints, c2)
    end

    return true
  end)
  return util.randomItemFromTable(allLandPoints)
end

local function findPeopleInArea(center, radius, criteria)
  center = util.to_coord3D(center)
  local result = {}
  SearchMapCells(CIRCULAR, 0, 0, math.ceil(radius/512), world_coord3d_to_map_idx(center), function(me)
    me.MapWhoList:processList(function(t)
      if (criteria(t)) then
        table.insert(result, t)
      end
      return true
    end)
    return true
  end)
  return result
end

util = {}
util.tableLength = tableLength
util.tableContains = tableContains
util.doesExist = tableContains
util.spellTargetThing = spellTargetThing
util.commandPersonGoToPoint = commandPersonGoToPoint
util.commandPersonToPatrol = commandPersonToPatrol
util.placePlan = placePlan
util.sendPersonToBuild = sendPersonToBuild
util.sendPersonToDismantle = sendPersonToDismantle
util.isPersonInHut = isPersonInHut
util.markBuildingToDismantle = markBuildingToDismantle
util.isMarkedAsDismantle = isMarkedAsDismantle
util.isPersonDismantlingBuilding = isPersonDismantlingBuilding
util.getMaxPopulationOfTribe = getMaxPopulationOfTribe
util.estimateTimeToChargeOneShot = estimateTimeToChargeOneShot
util.shuffle = shuffle
util.isShamanCasting = isShamanCasting
util.randomLandPointSurroundedByLandInArea = randomLandPointSurroundedByLandInArea
util.findPeopleInArea = findPeopleInArea

-- Miscellaneous
util.randomItemFromTable = randomItemFromTable
util.clone_Coord2D = clone_Coord2D
util.clone_Coord3D = clone_Coord3D
util.create_Coord2D = create_Coord2D
util.create_Coord3D = create_Coord3D
util.coord3D_to_coord2D = c3D_to_c2D
util.coord2D_to_coord3D = c2D_to_c3D
util.to_coord3D = to_c3D
util.to_coord2D = to_c2D
util.add_coord3D = add_c3D
util.mapCellToCoord2D = mapCellToCoord2D
