local _, addon = ...
local sets = {}

addon.sets = sets

local items = addon.items

function sets.GetEquippedSetCounts()
    local counts = {}
    for slot = 1, 19 do
        local itemLink = GetInventoryItemLink("player", slot)
        local _, setID = items.GetItemMetadata(itemLink)
        if setID then
            counts[setID] = (counts[setID] or 0) + 1
        end
    end
    return counts
end

local function GetSetBonusScore(database, setID, pieceCount)
    local bonuses = setID and database.setBonuses[setID]
    local score = 0
    if type(bonuses) == "table" then
        for threshold, value in pairs(bonuses) do
            if tonumber(threshold) and pieceCount >= tonumber(threshold) then
                score = score + (tonumber(value) or 0)
            end
        end
    end
    return score
end

function sets.GetSetBonusDelta(database, itemSetID, replacedItems, setCounts)
    local affectedSets = {}
    if itemSetID then
        affectedSets[itemSetID] = true
    end
    for _, equippedItem in ipairs(replacedItems) do
        if equippedItem.setID then
            affectedSets[equippedItem.setID] = true
        end
    end

    local delta = 0
    for setID in pairs(affectedSets) do
        local currentCount = setCounts[setID] or 0
        local replacedCount = 0
        for _, equippedItem in ipairs(replacedItems) do
            if equippedItem.setID == setID then
                replacedCount = replacedCount + 1
            end
        end
        local newCount = currentCount - replacedCount
        if itemSetID == setID then
            newCount = newCount + 1
        end
        delta = delta + GetSetBonusScore(database, setID, newCount)
            - GetSetBonusScore(database, setID, currentCount)
    end
    return delta
end
