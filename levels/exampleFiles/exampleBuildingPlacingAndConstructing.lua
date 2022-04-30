-- includes the file startPoint.lua to the script (if you dont do this, the framework will not be loaded)
include("_fr/startPoint.lua")

local towerX, towerY = 20000, 0

-- We will create some hut plans for blue and send people to harvest and build
BlueAI = AI:new(TRIBE_BLUE)

local buildPlacer = AIModuleBuildingPlacer:new()
local populationManager = AIModulePopulationManager:new()
local towerPlace = BuildPlace:new(nil, BlueAI:getTribe(), M_BUILDING_DRUM_TOWER, util.create_Coord2D(towerX, towerY))

-- Print some messages so you see them on screen
towerPlace:onBuiltSubscribe(function(buildingplace, plan)
    logger.msgLog("Built tower plan")
    logger.msgLog("Placing huts...")
end)
towerPlace:onPlaceSubscribe(function(buildingplace, plan)
    logger.msgLog("Placed tower plan")
    logger.msgLog("Building...")
end)

local hut1 = BuildPlace:new(nil, BlueAI:getTribe(), M_BUILDING_TEPEE , util.create_Coord2D(towerX + 512 * 5, towerY), nil, nil, {towerPlace})
local hut2 = BuildPlace:new(nil, BlueAI:getTribe(), M_BUILDING_TEPEE , util.create_Coord2D(towerX - 512 * 5, towerY), nil, nil, {towerPlace})
local hut3 = BuildPlace:new(nil, BlueAI:getTribe(), M_BUILDING_TEPEE , util.create_Coord2D(towerX, towerY  + 512 * 5), nil, nil, {towerPlace, hut1, hut2})

buildPlacer:addBuildPlace(towerPlace)
buildPlacer:addBuildPlace(hut1)
buildPlacer:addBuildPlace(hut2)
buildPlacer:addBuildPlace(hut3)


-- We add and enable all modules so they can start working
BlueAI:setModule(1, buildPlacer)
BlueAI:setModule(2, populationManager)

-- This code will ba placed on another place later on, now, it is here so it is seen clearly
subscribe_OnCreateThing(function (thing)
    if (thing.Type == T_SHAPE) then
        logger.msgLog("A shape was placed")

        local tree_found = false
        local treeThing = nil
        ProcessGlobalSpecialList(TRIBE_HOSTBOT, WOODLIST, function(__t)
          if (get_world_dist_xyz(__t.Pos.D3,thing.Pos.D3) < 512*12) then
            tree_found = true
            treeThing = __t
            return false
          end
          
          return true
        end)



        local braves = populationManager:getIdlePeople(2, M_PERSON_BRAVE)
        for i = 1, #braves, 1 do
            logger.msgLog("Sending a brave to harvest and build...")
            util.sendPersonToBuild(braves[i], thing, treeThing)
        end
    end
end)