import(Module_Math)
import(Module_Map)
import(Module_DataTypes)

local INGAME_ANGLE_MAX = 2069
local INGAME_COORDINATE_MAX = 32768


local function degToIngameAngle(angleInDegrees)
    return angleInDegrees * INGAME_ANGLE_MAX/360
end

local function ingameAngleToDeg(angleInIngameAngle)
    return angleInIngameAngle * 360/INGAME_ANGLE_MAX
end

local function hypotenuse(c1, c2)
    return math.sqrt(c1^2 + c2^2)
end

local function calculateMoveDistance(speed, time)
    return speed * time
end

--TODO -- Check: Velocity is kept even when thing stops (?) weird
local function calculateMoveDistanceWithVelocity(velocityX, velocityZ, time)
    local movedX = calculateMoveDistance(velocityX, time)
    local movedZ = calculateMoveDistance(velocityZ, time)
    return hypotenuse(movedX, movedZ)
end

local function calculateThingMoveDistance(thing, time)
    --[[
        With velocity:
        local v = thing.Move.Velocity
        return calculateMoveDistanceWithVelocity(v.X, v.Z, time)
    ]]

    return calculateMoveDistance(thing.Move.SelfPowerSpeed, time)
end

local function calculateThingPositionAfterTime(thing, time)
    --[[
        With velocity:
        local v = thing.Move.Velocity
        local movedX = calculateMoveDistance(v.X, time)
        local movedZ = calculateMoveDistance(v.Z, time)
    
        return util.add_coord3D(thing.Pos.D3, util.create_Coord3D(movedX, 0, movedZ))
    ]]

    local distance = calculateThingMoveDistance(thing, time)
    local angle = thing.AngleXZ
    return frameworkMath.calculatePosition(thing.Pos.D3, angle, distance)
end

local function orthogonalAngle(angle, direction)
    if (direction == nil) then
        direction = 1
    end
    return angle + direction * INGAME_ANGLE_MAX/4
end

local function oppositeAngle(angle)
    return orthogonalAngle(orthogonalAngle(angle))
end

local function squareWorldDistance(c1, c2)
    local rX = math.pow(c1.Xpos - c2.Xpos, 2)
    local rY = math.pow(c1.Ypos - c2.Ypos, 2)
    local rZ = math.pow(c1.Zpos - c2.Zpos, 2)
    return rX+rY+rZ
end

-- TODO
local function angleBetweenPoints(p1, p2)

end

local function calculatePosition(startPosition, angle, distance)
    -- distance = a
    -- x = b
    -- z = c
    -- a/sin(90) = b/sin(angle) = c/sin(90-angle) -> Law of sines

    -- Angles to degrees then to radians
    local _angle = ingameAngleToDeg(angle)
    _angle = math.rad(_angle)

    -- a/sin(90) to get the ratio
    local _ratio = distance/math.sin(90)

    local _x = math.sin(_angle) * _ratio
    local _z = math.sin(math.rad(90) - _angle) * _ratio

    -- calculate new position
    local _result = Coord3D.new()
    if (not (_x ~= _x or _z ~= _z)) then -- NaN check, happens if both points are the same --TODO return nil or something
        _result.Xpos = (math.ceil(_x + startPosition.Xpos))
        _result.Zpos = (math.ceil(_z + startPosition.Zpos))
    end

    return _result
end

-- Approximate value
local function calculateSpellCastTimeToReachPosition(startPos, endPos)
    local s = util.to_coord2D(startPos)
    local e = util.to_coord2D(endPos)
    local distance = get_world_dist_xz(s, e)

    -- m = 1400, more or less
    return (distance/1400) + 6
end

-- TODO -- now it just calculates the range according to the "step", better to smooth the function so it is no longer an approx
local function calculateSpellRangeFromPosition(position, spell, isFromTower)
    local MAX_LAND_HEIGHT = 1024
    local spellRange = spells_type_info()[spell].WorldCoordRange

    local altBand = constants().AltBandSpellRadiusAffectPer256
    local height = point_altitude(position.Xpos, position.Zpos)

    local index = math.floor(height/128)
    return (altBand[index]/256) * spellRange * 0.9
end

-- TODO
local function furthestInlandPointTowardsAngle(startPoint, angle, maxCheckDistance, distanceStep)
    
end

-- TODO
local function furthestInlandPointTowardsAngleAccurate(startPoint, angle, maxCheckDistance)

end

frameworkMath = {}
frameworkMath.hypotenuse = hypotenuse
frameworkMath.calculatePosition = calculatePosition
frameworkMath.calculateSpellCastTimeToReachPosition = calculateSpellCastTimeToReachPosition
frameworkMath.calculateThingPositionAfterTime = calculateThingPositionAfterTime
frameworkMath.calculateSpellRangeFromPosition = calculateSpellRangeFromPosition