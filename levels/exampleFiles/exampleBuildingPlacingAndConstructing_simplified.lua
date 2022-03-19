-- includes the file startPoint.lua to the script (if you dont do this, the framework will not be loaded)
include("_fr/startPoint.lua")

--[[ Create the AI using this method. It will add and enable all modules already:
    - AIModuleBuildingManager
    - AIModuleBuildingPlacer
    - AIModuleTreeManager
    - AIModulePopulationManager
    ...
]]
local blueAI = createAI(TRIBE_BLUE)

local towerX, towerY = 20000, 0

-- We add a location to look for trees
table.insert(blueAI.treeManager.treeSearchLocations, {centre = util.create_Coord2D(towerX, towerY), radius = 10000})

-- Add all the buildings we want them to build
local towerPlace = BuildPlace:new(nil, blueAI:getTribe(), M_BUILDING_DRUM_TOWER, util.create_Coord2D(towerX, towerY))
local hut1 = BuildPlace:new(nil, blueAI:getTribe(), M_BUILDING_TEPEE , util.create_Coord2D(towerX + 512 * 5, towerY), nil, nil, {towerPlace})
local hut2 = BuildPlace:new(nil, blueAI:getTribe(), M_BUILDING_TEPEE , util.create_Coord2D(towerX - 512 * 5, towerY), nil, nil, {towerPlace})
local hut3 = BuildPlace:new(nil, blueAI:getTribe(), M_BUILDING_TEPEE , util.create_Coord2D(towerX, towerY  + 512 * 5), nil, nil, {towerPlace, hut1, hut2})

blueAI.buildingPlacer:addBuildPlace(towerPlace)
blueAI.buildingPlacer:addBuildPlace(hut1)
blueAI.buildingPlacer:addBuildPlace(hut2)
blueAI.buildingPlacer:addBuildPlace(hut3)