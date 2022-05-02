import(Module_Map)
import(Module_Game)

-- Global, cause its useful
function GetTurn()
    return getTurn()
end

local function randomItemFromTable(t)
  if (#t == 0) then
    return nil
  end

  local idx = math.random(1, #t)
  return t[idx], idx
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

local function objectListToTable(objectList)
  local result = {}
  for i = 0, objectList:count() - 1, 1 do
    table.insert(result, objectList:getNth(i))
  end
  return result
end

-- S click effect (if target is shaman)
local function spellTargetThing(spellThing, targetThing)
  spellThing.u.Spell.TargetThingIdx:set(targetThing.ThingNum)
end

local function _movePersonToPointCallbackChecker(thing, point, time, callback, delta)
  -- thing died or similar or time run out
  if (thing == nil or time <= 0) then
    callback(false)
    return
  end

  local distance = get_world_dist_xyz(thing.Pos.D3, util.to_coord3D(point))
  if (distance <= delta) then
    callback(true)
    return
  end

  -- Check again in 12 turns
  local checkInterval = 12
  subscribe_ExecuteOnTurn(GetTurn() + checkInterval, function()
    _movePersonToPointCallbackChecker(thing, point, time - checkInterval, callback, delta)
  end)
end

local function commandPersonGoToPoint(thing, point, time, callback, delta)
  delta = delta or 600
  local p = util.to_coord2D(point)
  command_person_go_to_coord2d(thing, p)
  subscribe_ExecuteOnTurn(GetTurn()+12, function()
    _movePersonToPointCallbackChecker(thing, point, time, callback, delta)
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

-- value is a boolean, if true or nil the thing will be dismantled, if false it will be unmarked (in other words, will be built)
local function markBuildingToDismantle(thing, value)
  if (value or value == nil) then
    -- Mark to dismantle
    thing.u.Bldg.Flags = thing.u.Bldg.Flags | TF_BACKWARDS_MOTION
  else
    -- Mark to build (If it is already being built, dont toggle, leave it as is)
    if (thing.u.Bldg.Flags & TF_BACKWARDS_MOTION ~= 0) then
      thing.u.Bldg.Flags = thing.u.Bldg.Flags ~ TF_BACKWARDS_MOTION
    end
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

local function shamanGotoSpellCastPoint(tribe, coordinates)
  local shaman = getShaman(tribe)
  if (shaman == nil) then
    return
  end

  command_person_go_to_coord2d(shaman, util.to_coord2D(coordinates))
  local idx = subscribe_ExecuteOnTurn(GetTurn(), function ()
    local shaman = getShaman(tribe)
    if (shaman ~= nil) then
      shaman.State = S_PERSON_GOTO_SPELL_CAST_POINT
      shaman.SubState = 0
    end
  end)

  return idx 
end

local function setSprogFlag(thing)
  thing.u.Bldg.Flags = thing.u.Bldg.Flags | BF_DO_A_SPROGG
end

local function hutForceSprog(thing)
  -- Sprogging only processed every 4 turns, with and offset depending on hut model
  local multiple = 0
  multiple = (GetTurn()+3) + 4 - 1; -- We consider we are 3 turns ahead from now (if this turn would be a valid one, we would execute the stuff 1 turn late)
  multiple = multiple - (multiple % 4);
  
  if (thing.Model == M_BUILDING_TEPEE) then
    multiple = multiple - 1
  elseif (thing.Model == M_BUILDING_TEPEE_2) then
    multiple = multiple - 2
  elseif (thing.Model == M_BUILDING_TEPEE_3) then
    multiple = multiple - 2
  end
  subscribe_ExecuteOnTurn(multiple, function ()
    if (thing ~= nil and thing.u.Bldg ~= nil) then
      util.setSprogFlag(GetThing(thing.ThingNum))
    end
  end)
end

local function gotoBuilding(person, building)
  commands.reset_person_cmds(person)
  add_persons_command(person, commands.cmd_go_in_bldg(building), 0)
end

local function gotoTrain(person, building)
  util.gotoBuilding(person, building)
end

util = {}
util.tableLength = tableLength
util.tableContains = tableContains
util.doesExist = tableContains
util.objectListToTable = objectListToTable
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
util.shamanGotoSpellCastPoint = shamanGotoSpellCastPoint
util.setSprogFlag = setSprogFlag
util.hutForceSprog = hutForceSprog
util.gotoBuilding = gotoBuilding
util.gotoTrain = gotoTrain

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
