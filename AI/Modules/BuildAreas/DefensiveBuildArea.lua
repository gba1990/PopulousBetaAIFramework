DefensiveBuildArea = BuildArea:new()

function DefensiveBuildArea:new(center, radius)
    local o = BuildArea:new(center, radius)
    setmetatable(o, self)
    self.__index = self
    
    -- % of land that should be covered in towers
    o.towerPercentage = 2.5 -- 2.5 Seems quite a balanced value on average
    o.numPlacedTowers = 0

    return o
end

function BuildArea:estimateNumberOfTowers()
    self.numberOfTowersToBuild = 0
    self.numPlacedTowers = 0
    self.buildableLocations = {}
        
    local numBuildableCells = 0
    local tribe = self.ai:getTribe()
    SearchMapCells(CIRCULAR, 0, 0, math.ceil(self.radius / 512), world_coord2d_to_map_idx(util.to_coord2D(self.center)), function(me)
        local c2 = Coord2D.new()
        map_ptr_to_world_coord2d(me, c2)
        local map_idx = world_coord2d_to_map_idx(c2)
        
        for i = 0, 3, 1 do
            if (util.canPlayerPlacePlanAtPos(map_idx, M_BUILDING_DRUM_TOWER, i, tribe) > 0) then
                table.insert(self.buildableLocations, {coords = c2, map_idx = map_idx})
                numBuildableCells = numBuildableCells + 1
                break -- We just need 1 orientation to be true
            end
        end

        -- Now we update the number of towers we in area
        me.MapWhoList:processList(function (t)
            if (t.Owner == tribe) then
                if (t.Type == T_BUILDING and t.Model == M_BUILDING_DRUM_TOWER) then
                    self.numPlacedTowers = self.numPlacedTowers + 1
                elseif (t.Type == T_SHAPE and t.u.Shape.BldgModel == M_BUILDING_DRUM_TOWER) then
                    self.numPlacedTowers = self.numPlacedTowers + 1
                end
            end
            return true
        end)

        return true
    end)

    self.numberOfTowersToBuild = math.ceil(numBuildableCells * self.towerPercentage/100)
end

function BuildArea:determineNewTowerLocation()
    local entry = nil
    local idx = nil
    
    while (#self.buildableLocations > 0 and entry == nil) do
        -- Get a random entry of a place where we can build a tower
        entry, idx = util.randomItemFromTable(self.buildableLocations)
        table.remove(self.buildableLocations, idx)
        
        -- Set a random orientation to that building
        local orientatations = {}
        for i = 0, 3, 1 do
            if (util.canPlayerPlacePlanAtPos(entry.map_idx, M_BUILDING_DRUM_TOWER, i, self.ai:getTribe()) > 0) then
                table.insert(orientatations, i)
            end
        end

        if (#orientatations > 0) then
            -- Set the orientation
            entry.orientation = util.randomItemFromTable(orientatations)
        else
            -- If we cannot place the build in that cell, well... try again
            entry = nil
        end
    end

    return entry
end

function BuildArea:queueTowerIfRequired()
    if (self.numberOfTowersToBuild > self.numPlacedTowers) then
        local newTowerEntry = self:determineNewTowerLocation()
        local buildPlace = BuildPlace:new(nil, self.ai:getTribe(), M_BUILDING_DRUM_TOWER, newTowerEntry.coords, newTowerEntry.orientation)
        self.ai:getModule(AI_MODULE_BUILDING_PLACER_ID):addBuildPlace(buildPlace)
        self.numPlacedTowers = self.numPlacedTowers + 1
    end
end

function BuildArea:updateAndProcess()
    self:estimateNumberOfTowers()
    self:queueTowerIfRequired()
end