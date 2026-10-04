local _, addon = ...
local data = addon.data
local profiles = addon.profiles
local talents = addon.talents
local hit = addon.hit
local equipment = addon.equipment
local items = addon.items
local sets = addon.sets
local scoring = addon.scoring
local evaluation = {}

addon.evaluation = evaluation

local CLASSIC_DEFAULT_WEIGHTS = data.CLASSIC_DEFAULT_WEIGHTS
local CLASS_ACTIVITY_DEFAULTS = data.CLASS_ACTIVITY_DEFAULTS
local EQUIP_SLOT_LABELS = data.EQUIP_SLOT_LABELS
local SCORING_CONTEXT_ORDER = data.SCORING_CONTEXT_ORDER

function evaluation.Create(database, weightDatabase)
    local gearDuckDB = database
    local gearDuckWeightsDB = weightDatabase
    local evaluationCache = {}

    local function GetPlayerClassWeights(contextKey)
        local className, classFile
        if UnitClass then
            className, classFile = UnitClass("player")
        end
    
        if classFile and CLASS_ACTIVITY_DEFAULTS[classFile] then
            local treeKey, treeName, treePoints = talents.GetActiveTalentTree()
            local profile = profiles.GetTalentWeightProfile(
                gearDuckWeightsDB,
                classFile,
                contextKey,
                treeKey
            )
            return className or classFile, classFile, profile, treeKey, treeName, treePoints
        end
    
        return "Classic default", "DEFAULT", CLASSIC_DEFAULT_WEIGHTS, nil, nil
    end
    
    local function EvaluateItem(itemLink)
        if not itemLink then
            return nil
        end
        local cachedEvaluation = evaluationCache[itemLink]
        if cachedEvaluation then
            return cachedEvaluation
        end
    
        local slots, replacesBothWeaponSlots = items.GetReplacementSlots(itemLink)
        if not slots then
            return nil
        end
    
        local className, classFile = UnitClass("player")
        local canEquip, equipRestrictionReason = equipment.CanPlayerEquipItem(itemLink)
        local itemClassID = equipment.GetItemClassInfo(itemLink)
        local unenchantedLink, enchantID = items.GetUnenchantedItemLink(itemLink)
        local isEnchantedWeapon = itemClassID == 2 and enchantID ~= nil
        local itemID, itemSetID = items.GetItemMetadata(itemLink)
        local equippedLinks = {}
        local setCounts = sets.GetEquippedSetCounts()
        local equippedHit = 0
        for slot = 1, 19 do
            local equippedLink = GetInventoryItemLink("player", slot)
            equippedLinks[slot] = equippedLink
            equippedHit = equippedHit + (hit.GetItemHitPercent(equippedLink) or 0)
        end
        local comparisons = {}
        local hitCaps = {}
        local contextScores = {}
        local equipped = {}
        local itemStats
        local itemScore
        local itemBreakdown
        local itemScoreWithoutEnchant
        for _, context in ipairs(SCORING_CONTEXT_ORDER) do
            if gearDuckDB.displayContexts[context.key] then
                local classNameForContext, classFileForContext, classWeights, treeKey, treeName, treePoints =
                    GetPlayerClassWeights(context.key)
                local activityProfile = profiles.GetActivityWeightProfile(
                    gearDuckWeightsDB,
                    classFileForContext,
                    context.key
                )
                local currentItemScore, currentBreakdown, currentItemStats =
                    scoring.ScoreItem(gearDuckDB, itemLink, classWeights)
                local currentItemScoreWithoutEnchant = currentItemScore
                if isEnchantedWeapon then
                    currentItemScoreWithoutEnchant = scoring.ScoreItem(
                        gearDuckDB,
                        unenchantedLink,
                        classWeights
                    )
                end
                local dualWielding = false
                if (classFileForContext == "WARRIOR" or classFileForContext == "ROGUE"
                    or (classFileForContext == "SHAMAN" and hit.GetTalentBonuses().dualWield))
                    and equippedLinks[16] and equippedLinks[17] then
                    local mainHandClassID = equipment.GetItemClassInfo(equippedLinks[16])
                    local offHandClassID = equipment.GetItemClassInfo(equippedLinks[17])
                    dualWielding = mainHandClassID == 2 and offHandClassID == 2
                end
                local hitCap = hit.GetEffectiveHitCap(
                    classFileForContext,
                    context.key,
                    activityProfile,
                    dualWielding
                )
                hitCaps[context.key] = hitCap
    
                local contextEquipped = {}
                local slotComparisons = {}
                for _, slot in ipairs(slots) do
                    local equippedLink = equippedLinks[slot]
                    local score, breakdown, stats = scoring.ScoreItem(
                        gearDuckDB,
                        equippedLink,
                        classWeights
                    )
                    local equippedItemID, equippedSetID = items.GetItemMetadata(equippedLink)
                    local equippedItem = {
                        slot = slot,
                        link = equippedLink,
                        itemID = equippedItemID,
                        setID = equippedSetID,
                        score = score,
                        breakdown = breakdown,
                        stats = stats,
                        hitPercent = hit.GetItemHitPercent(equippedLink) or 0,
                    }
                    contextEquipped[#contextEquipped + 1] = equippedItem
                    if not replacesBothWeaponSlots then
                        slotComparisons[#slotComparisons + 1] = {
                            label = EQUIP_SLOT_LABELS[slot] or ("Slot " .. slot),
                            equippedScore = score,
                            replacedItems = { equippedItem },
                        }
                    end
                end
                if replacesBothWeaponSlots then
                    local equippedScore = 0
                    for _, equippedItem in ipairs(contextEquipped) do
                        equippedScore = equippedScore + equippedItem.score
                    end
                    slotComparisons[1] = {
                        label = "Both Hands",
                        equippedScore = equippedScore,
                        replacedItems = contextEquipped,
                    }
                end
    
                if not itemScore then
                    className = classNameForContext or className
                    classFile = classFileForContext
                    itemStats = currentItemStats
                    itemScore = currentItemScore
                    itemBreakdown = currentBreakdown
                    itemScoreWithoutEnchant = currentItemScoreWithoutEnchant
                    equipped = contextEquipped
                end
                contextScores[context.key] = {
                    itemScore = currentItemScore,
                    itemScoreWithoutEnchant = currentItemScoreWithoutEnchant,
                    treeKey = treeKey,
                    treeName = treeName,
                    treePoints = treePoints,
                }
    
                for _, slotComparison in ipairs(slotComparisons) do
                    local comparison = {
                        profileKey = context.key,
                        profileName = context.name,
                        label = slotComparison.label,
                        equippedScore = slotComparison.equippedScore,
                        itemScore = currentItemScore,
                        replacedItems = slotComparison.replacedItems,
                    }
                    local setBonusDelta = sets.GetSetBonusDelta(
                        gearDuckDB,
                        itemSetID,
                        comparison.replacedItems,
                        setCounts
                    )
                    local replacementHit = 0
                    for _, replacedItem in ipairs(comparison.replacedItems) do
                        replacementHit = replacementHit + (replacedItem.hitPercent or 0)
                    end
                    local itemHitPercent = hit.GetItemHitPercent(itemLink) or 0
                    local cappedHitDelta = math.min(hitCap, math.max(0, equippedHit - replacementHit + itemHitPercent))
                        - math.min(hitCap, math.max(0, equippedHit))
                    comparison.delta = currentItemScore - comparison.equippedScore
                        + (cappedHitDelta - (itemHitPercent - replacementHit)) * (classWeights.Hit or 0)
                        + setBonusDelta
                    if isEnchantedWeapon then
                        local unenchantedHitPercent = hit.GetItemHitPercent(unenchantedLink) or 0
                        local cappedUnenchantedHitDelta = math.min(hitCap, math.max(0, equippedHit - replacementHit + unenchantedHitPercent))
                            - math.min(hitCap, math.max(0, equippedHit))
                        comparison.deltaWithoutEnchant = currentItemScoreWithoutEnchant - comparison.equippedScore
                            + (cappedUnenchantedHitDelta - (unenchantedHitPercent - replacementHit)) * (classWeights.Hit or 0)
                            + setBonusDelta
                    end
                    comparisons[#comparisons + 1] = comparison
                end
            end
        end
    
        local evaluation = {
            link = itemLink,
            canEquip = canEquip,
            equipRestrictionReason = equipRestrictionReason,
            itemID = itemID,
            itemSetID = itemSetID,
            enchantID = enchantID,
            isEnchantedWeapon = isEnchantedWeapon,
            itemScoreWithoutEnchant = itemScoreWithoutEnchant,
            slots = slots,
            itemScore = itemScore,
            itemBreakdown = itemBreakdown,
            itemStats = itemStats,
            className = className,
            classFile = classFile,
            contextScores = contextScores,
            hitCaps = hitCaps,
            equipped = equipped,
            comparisons = comparisons,
        }
        local getItemInfo = (C_Item and rawget(C_Item, "GetItemInfo")) or rawget(_G, "GetItemInfo")
        if getItemInfo and getItemInfo(itemLink) then
            evaluationCache[itemLink] = evaluation
        end
        return evaluation
    end
    
    local function ClearCache()
        wipe(evaluationCache)
    end

    local function SetDatabases(newDatabase, newWeightDatabase)
        gearDuckDB = newDatabase
        gearDuckWeightsDB = newWeightDatabase
        ClearCache()
    end

    return EvaluateItem, ClearCache, SetDatabases
end
