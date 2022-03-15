AIShamanSpellManagerBucket = AIShamanSpellManager:new()

local function initBucketCount()
    local result = {}
    for i = 1, NUM_SPELL_TYPES, 1 do
        result[i] = 1
    end
    return result 
end

local function initBucketList()
    local result = {}
    for i = 1, NUM_SPELL_TYPES, 1 do
        result[i] = {shots = 0, turns = 0}
    end
    return result
end

function AIShamanSpellManagerBucket:new(o)
    local o = o or AIShamanSpellManager:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil

    o.bucketCount = initBucketCount()
    o.spellsBucket = initBucketList()
    o.bucketMultiplier = 64 -- Bucket For Spell * bucketMultiplier = delay for that spell

    o.bucketReducerSubscribeIndex = ""
    o.afterCastSubscribeIndex = ""
    o:enable()

    return o
end

function AIShamanSpellManagerBucket:castSpell(spell, location)
    return self:castSpellAffectingAllRestrictions(spell, location)
end

function AIShamanSpellManagerBucket:castSpellAffectingAllRestrictions(spell, location)
    local shaman = getShaman(self.aiModuleShaman.ai:getTribe())
    local checks = not self:couldSpellBeCasted(spell) or
            not self:checkCastDistance(spell, location)
    
    if (checks) then
        -- Checks did not pass, cannot legally cast a spell
        return nil
    end

    if (self.aiModuleShaman:doIHaveSingleShot(spell)) then
        local spellCost = spells_type_info()[spell].Cost
        GIVE_MANA_TO_PLAYER(self.aiModuleShaman.ai:getTribe(), spellCost) -- Refund the cost
        self.aiModuleShaman:removeSingleShotFromSpell(spell) -- Mark the spell as shot
    end

    -- Bucket will be updated on the OnCreateThing, no need to update here
    self:updateManaAfterCast(spell)
    return createThing(T_SPELL, spell, self.aiModuleShaman.ai:getTribe(), util.to_coord3D(location), false, false)
end


function AIShamanSpellManager:couldSpellBeCasted(spell)
    local result = getShaman(self.aiModuleShaman.ai:getTribe()) ~= nil and 
                self:checkCastSpellAvailable(spell) and
                (self:checkCastMana(spell) or self.aiModuleShaman:doIHaveSingleShot(spell)) and
                self:checkCastBucket(spell) and
                self:checkCastShamanCooldown() and
                self:checkCastShamanStatus()
    return result
end

-- Updaters
function AIShamanSpellManagerBucket:updateManaAfterCast(spell)
    local spellCost = spells_type_info()[spell].Cost
    GIVE_MANA_TO_PLAYER(self.aiModuleShaman.ai:getTribe(), spellCost*-1)
end

function AIShamanSpellManagerBucket:updateBucketAfterCast(spell)
    local entry = self.spellsBucket[spell]
    local maxShots = spells_type_info()[spell].OneOffMaximum
    local bucketForSpell = self.bucketCount[spell]
    if (entry.shots > 0 ) then
        entry = {shots = entry.shots + 1, turns = entry.turns}
    else
        entry = {shots = entry.shots + 1, turns = bucketForSpell * self.bucketMultiplier}
    end
    self.spellsBucket[spell] = entry
end

function AIShamanSpellManagerBucket:updateBucketCounts()
    local result = {}
    for i = 1, NUM_SPELL_TYPES, 1 do
        result[i] = math.ceil(util.estimateTimeToChargeOneShot(self.aiModuleShaman.ai:getTribe(), i)/self.bucketMultiplier)
    end

    self.bucketCount = result
end

local function updateBucketCountsInvoker(o)
    o:updateBucketCounts()
    o.updateBucketCountSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + 128, function ()
        updateBucketCountsInvoker(o)
    end)
end

-- Checks
function AIShamanSpellManagerBucket:checkCastBucket(spell)
    local entry = self.spellsBucket[spell]
    local maxShots = spells_type_info()[spell].OneOffMaximum
    if (entry.shots < maxShots) then
        return true -- Can be cast as we still have "charged" shots
    end

    return entry.turns <= 0
end

-- Enable disable

function AIShamanSpellManagerBucket:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    -- Reduce bucket
    self.bucketReducerSubscribeIndex = subscribe_OnTurn(function ()
        for i = 1, NUM_SPELL_TYPES, 1 do
            local entry = self.spellsBucket[i]
            if (entry.turns > 0) then
                entry.turns = entry.turns - 1
                if (entry.shots > 0 and entry.turns == 0) then
                    entry.shots = entry.shots - 1
                    entry.turns = self.bucketCount[i] * self.bucketMultiplier
                end
            end
            if (entry.shots == 0) then
                entry.turns = 0
            end
            self.spellsBucket[i] = entry
        end
    end)
    -- Update buckets as population increases/decreases
    self.updateBucketCountSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + 12, function ()
        updateBucketCountsInvoker(self)
    end)
    -- AfterCast event
    self.afterCastSubscribeIndex = subscribe_OnCreateThing(function (thing)
        if (thing.Type == T_SPELL and thing.Owner == self.aiModuleShaman.ai:getTribe()) then
            self:updateBucketAfterCast(thing.Model)
        end
    end)
end

function AIShamanSpellManagerBucket:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_OnTurn(self.bucketReducerSubscribeIndex)
    unsubscribe_ExecuteOnTurn(self.updateBucketCountSubscriberIndex)
    unsubscribe_OnCreateThing(self.afterCastSubscribeIndex)
end