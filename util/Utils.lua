import(Module_Map)
import(Module_Game)

-- Global, cause its useful
function GetTurn()
    return getTurn()
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


util = {}
util.tableLength = tableLength
util.clone_Coord2D = clone_Coord2D
util.clone_Coord3D = clone_Coord3D
util.create_Coord2D = create_Coord2D
util.create_Coord3D = create_Coord3D
util.coord3D_to_coord2D = c3D_to_c2D
util.coord2D_to_coord3D = c2D_to_c3D
util.to_coord3D = to_c3D
util.to_coord2D = to_c2D
util.add_coord3D = add_c3D
