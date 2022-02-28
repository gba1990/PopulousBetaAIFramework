import(Module_Math)
import(Module_Map)
import(Module_DataTypes)

-- Maximun degrees of the ingame angles
-- Seem to be 2069, but it is a param in case it needs to be changed
local INGAME_ANGLE_MAX = 2069
local INGAME_COORDINATE_MAX = 32768


local function degToIngameAngle(angleInDegrees)
    return angleInDegrees * INGAME_ANGLE_MAX/360
end

local function ingameAngleToDeg(angleInIngameAngle)
    return angleInIngameAngle * 360/INGAME_ANGLE_MAX
end

-- Returns the hypothenuse of the triangle of sides cathetus1 and cathetus2
local function hypotenuse(c1, c2)
    return math.sqrt(c1^2 + c2^2)
end

local function normalizeVector(x, y)
    local length = math.sqrt((x * x) + (y * y))
    return x/length, y/length
end

-- Returns an angle 90º from @param angle, clockwise if direction = 1 or nil and counterclockwise if direction = -1
-- angle must be in ingame angles (those that range from 0 to 2070 or something like that)
local function orthogonalAngle(angle, direction)
    if (direction == nil) then
        direction = 1
    end
    return angle + direction * INGAME_ANGLE_MAX/4
end

-- Returns the angle that is 180º the other way (in ingame angles)
local function oppositeAngle(angle)
    return orthogonalAngle(orthogonalAngle(angle))
end

-- We dont consider borders, so I guess this function is bugged with points within the map
local function squareWorldDistance(c1, c2)
    local rX = math.pow(c1.Xpos - c2.Xpos, 2)
    local rY = math.pow(c1.Ypos - c2.Ypos, 2)
    local rZ = math.pow(c1.Zpos - c2.Zpos, 2)
    return rX+rY+rZ
end

local function worldDistance(c1, c2)
    c1 = util.to_coord2D(c1)
    c2 = util.to_coord2D(c2)
    return get_world_dist_xz_quick(c1, c2)
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

-- HELPER function
local function _calculateClosestPointHavingInMindMapBorders(p1, p2)
    local points = {}
    local up, down, right, left, 
        upright, downright, downleft, upleft = 
            {Xpos = p2.Xpos, Ypos = 0, Zpos = p2.Zpos},{Xpos = p2.Xpos, Ypos = 0, Zpos = p2.Zpos},{Xpos = p2.Xpos, Ypos = 0, Zpos = p2.Zpos},{Xpos = p2.Xpos, Ypos = 0, Zpos = p2.Zpos},
            {Xpos = p2.Xpos, Ypos = 0, Zpos = p2.Zpos},{Xpos = p2.Xpos, Ypos = 0, Zpos = p2.Zpos},{Xpos = p2.Xpos, Ypos = 0, Zpos = p2.Zpos},{Xpos = p2.Xpos, Ypos = 0, Zpos = p2.Zpos}
    
    local multiplier = 2

    down.Xpos = down.Xpos + INGAME_COORDINATE_MAX*multiplier
    up.Xpos = up.Xpos - INGAME_COORDINATE_MAX*multiplier

    left.Zpos = left.Zpos + INGAME_COORDINATE_MAX*multiplier
    right.Zpos = right.Zpos - INGAME_COORDINATE_MAX*multiplier

    upright.Xpos = upright.Xpos + INGAME_COORDINATE_MAX*multiplier
    upright.Zpos = upright.Zpos + INGAME_COORDINATE_MAX*multiplier
    
    downright.Xpos = downright.Xpos - INGAME_COORDINATE_MAX*multiplier
    downright.Zpos = downright.Zpos + INGAME_COORDINATE_MAX*multiplier

    downleft.Xpos = downleft.Xpos - INGAME_COORDINATE_MAX*multiplier
    downleft.Zpos = downleft.Zpos - INGAME_COORDINATE_MAX*multiplier

    upleft.Xpos = upleft.Xpos + INGAME_COORDINATE_MAX*multiplier
    upleft.Zpos = upleft.Zpos - INGAME_COORDINATE_MAX*multiplier
    
    table.insert(points, up)
    table.insert(points, down)
    table.insert(points, right)
    table.insert(points, left)
    table.insert(points, upright)
    table.insert(points, downright)
    table.insert(points, downleft)
    table.insert(points, upleft)

    local bestDistance = frameworkMath.squareWorldDistance(p1, p2)
    local bestPoint = p2
    for i = 1, #(points), 1 do
        local dist = frameworkMath.squareWorldDistance(p1, points[i])
        if (dist < bestDistance) then
            bestDistance = dist
            bestPoint = (points[i])
        end
    end
    return bestPoint
end

-- TODO
local function angleBetweenPoints(p1, p2)
    -- Important note, as the map is a square of 128x128 centered on 0,0
    -- Two points at coords (0, 32000) and (0, -32000) are 1000 units appart (more or less)
    -- This method will solve that calculating first all points adding/substracting 32000 to every
    -- axis in order to calculate the closest 2 points and then the angle among those
    -- in order to bypass this issue
    p2 = _calculateClosestPointHavingInMindMapBorders(p1, p2)

    local _v1x = (p1.Xpos - p2.Xpos)
    local _v1y = (p1.Zpos - p2.Zpos)

    local _v2x = -1 -- I dont understand math, but if it is 1, the vector is flipped??
    local _v2y = 0

    _v1x, _v1y = normalizeVector(_v1x, _v1y)

    -- Producto escalar: v1·v2
    local dotProduct = _v1x * _v2x + _v1y * _v2y

    -- Producto de modulos: |v1|, |v2|
    local modV1 = math.sqrt( _v1x^2 + _v1y^2 )
    local modV2 = math.sqrt( _v2x^2 + _v2y^2 )

    -- If dotProduct > 0 -> agudo
    -- If dotProduct == 0 -> Recto
    -- If dotProduct < 0 --> Obtuso

    -- cos(angulo) = dotProduct / (modV1 * modV2)
    local cosAngle = dotProduct / (modV1 * modV2)
    local angle = math.deg(math.acos(cosAngle))
    local result = nil
    local _quadrant = nil

    -- North should be angle zero and +x 90º, thats why I rotate whith the 90º things
    if(dotProduct > 0) then
        -- 1º o 2º cuadrante
        if (_v1y < 0) then
            -- 1º
            result = 90 - angle
            _quadrant = 1
        else
            -- 2º
            result = 90 + angle
            _quadrant = 2
        end
    else
        -- 3º o 4º cuadrante
        if (_v1y < 0) then
            -- 4º
            result = 450 - angle
            _quadrant = 4
        else
            -- 3º
            result = 90 + angle
            _quadrant = 3
        end
    end
    
    return degToIngameAngle(result), _quadrant
end

-- Returns Coord3D which represent new coordinates @param distance away from @param startPosition at an angle of @param angle.
-- startPosition can be Coord2D or Coord3D
-- angle must be in ingame angles (those that range from 0 to 2070 or something like that)
-- distance in world distance
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

-- Returns an approximate value of how long a spell cast will reach endPos from startPos.
-- This has been tested with lightning and rarely misses on spell range, on larger distances it may not
-- be calculated so accurately
local function calculateSpellCastTimeToReachPosition(startPos, endPos)
    local s = util.to_coord2D(startPos)
    local e = util.to_coord2D(endPos)
    local distance = get_world_dist_xz(s, e)

    -- m = 1400, more or less
    return (distance/1400) + 6
end

--- TODO now it just calculates the range according to the "step", better to smooth the function so it is no longer an approx
local function calculateSpellRangeFromPosition(position, spell, isFromTower)
    local MAX_LAND_HEIGHT = 1024
    local spellRange = spells_type_info()[spell].WorldCoordRange

    local altBand = constants().AltBandSpellRadiusAffectPer256
    local height = point_altitude(position.Xpos, position.Zpos)
    local towerIncrement = 0

    local index = math.floor(height/128)
    local multiplier = 0.9
    if (isFromTower) then
        local dtIncrease = constants().MedicineManDtRadius
        towerIncrement = dtIncrease * 512
    end

    return (altBand[index]/256) * spellRange * multiplier + towerIncrement
end

local function furthestInlandPointTowardsAngle(startPoint, angle, maxCheckDistance, distanceStep)
    local result = startPoint
    local distanceAppart = 0

    for i = 1, maxCheckDistance, distanceStep do
        local closer = frameworkMath.calculatePosition(startPoint, angle, i)
        if (point_altitude(closer.Xpos, closer.Zpos) > 1) then
            result = closer
            distanceAppart = i
        else
            return result, distanceAppart -- We encountered water, stop b4 the function finds an island
        end
    end
    return result, distanceAppart
end

--- From startPoint towards angle, calculate the coast point which is furthest away
--- This function is more precise. than the otehr one and hence recommended
--- Use a low intialDistanceStep for small water gaps, if water is too thin, a large step may skip it and consider it land
--- Returns the coordinate and the distance away
---@param startPoint Coord2D/Coord3D
---@param angle number (ingame angle)
---@param maxCheckDistance number (world coordinates) Optional (default of 30000)
---@param intialDistanceStep number (world coordinates) Optional (default of 5000)
---@param minDistanceStep number (world coordinates) Optional (default of 50)
---@return Coord3D, number
local function furthestInlandPointTowardsAngleAccurate(startPoint, angle, maxCheckDistance, intialDistanceStep, minDistanceStep)
    if (maxCheckDistance == nil) then
        maxCheckDistance = 30000
    end
    if (intialDistanceStep == nil) then
        intialDistanceStep = 5000
    end
    if (minDistanceStep == nil) then
        minDistanceStep = 50
    end

    local STEP_REDUCE_PER_ITERATION = 2
    local result = startPoint
    local newBest = nil
    local distanceStep = intialDistanceStep
    local distanceAppart = 0

    while(distanceStep > minDistanceStep)
    do
        newBest, distanceAppart = furthestInlandPointTowardsAngle(result, angle, maxCheckDistance, distanceStep)

        maxCheckDistance = maxCheckDistance - distanceAppart
        result = newBest

        distanceStep = distanceStep / STEP_REDUCE_PER_ITERATION
    end

    return result, get_world_dist_xyz(startPoint, result)

end

frameworkMath = {}
frameworkMath.INGAME_ANGLE_MAX = INGAME_ANGLE_MAX
frameworkMath.INGAME_COORDINATE_MAX  = INGAME_COORDINATE_MAX 

frameworkMath.calculatePosition = calculatePosition
frameworkMath.normalizeVector = normalizeVector
frameworkMath.orthogonalAngle = orthogonalAngle
frameworkMath.oppositeAngle = oppositeAngle
frameworkMath.hypotenuse = hypotenuse
frameworkMath.worldDistance = worldDistance
frameworkMath.squareWorldDistance = squareWorldDistance
frameworkMath.angleBetweenPoints = angleBetweenPoints
frameworkMath.calculateMoveDistance = calculateMoveDistance
frameworkMath.calculateMoveDistanceWithVelocity = calculateMoveDistanceWithVelocity
frameworkMath.calculateThingMoveDistance = calculateThingMoveDistance
frameworkMath.calculateThingPositionAfterTime = calculateThingPositionAfterTime
frameworkMath.calculateSpellCastTimeToReachPosition = calculateSpellCastTimeToReachPosition
frameworkMath.calculateSpellRangeFromPosition = calculateSpellRangeFromPosition
frameworkMath.furthestInlandPointTowardsAngle = furthestInlandPointTowardsAngle
frameworkMath.furthestInlandPointTowardsAngleAccurate = furthestInlandPointTowardsAngleAccurate

