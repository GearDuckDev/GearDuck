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
    local equippedStateCache

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

    local function GetEquippedState()
        if equippedStateCache then
            return equippedStateCache
        end

        local equippedLinks = {}
        local setCounts = {}
        local equippedHit = 0
        local allEquippedLoaded = true
        for slot = 1, 19 do
            local equippedLink = GetInventoryItemLink("player", slot)
            equippedLinks[slot] = equippedLink
            if equippedLink then
                if not items.IsItemInfoLoaded(equippedLink) then
                    allEquippedLoaded = false
                end
                equippedHit = equippedHit + (hit.GetItemHitPercent(equippedLink) or 0)
                local _, setID = items.GetItemMetadata(equippedLink)
                if setID then
                    setCounts[setID] = (setCounts[setID] or 0) + 1
                end
            end
        end

        local mainHandClassID, _, mainHandEquipLoc = equipment.GetItemClassInfo(equippedLinks[16])
        local offHandClassID = equipment.GetItemClassInfo(equippedLinks[17])
        local state = {
            allEquippedLoaded = allEquippedLoaded,
            equippedLinks = equippedLinks,
            setCounts = setCounts,
            equippedHit = equippedHit,
            mainHandIsWeapon = mainHandClassID == 2,
            offHandIsWeapon = offHandClassID == 2,
            mainHandIsTwoHander = mainHandEquipLoc == "INVTYPE_2HWEAPON",
            slotItemsByContext = {},
        }
        if allEquippedLoaded then
            equippedStateCache = state
        end
        return state
    end

    local function GetEquippedSlotItem(equippedState, contextKey, slot, classWeights)
        local contextSlots = equippedState.slotItemsByContext[contextKey]
        if not contextSlots then
            contextSlots = {}
            equippedState.slotItemsByContext[contextKey] = contextSlots
        end
        local cachedSlotItem = contextSlots[slot]
        if cachedSlotItem then
            return cachedSlotItem
        end

        local equippedLink = equippedState.equippedLinks[slot]
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
        contextSlots[slot] = equippedItem
        return equippedItem
    end

    local function CacheAndReturnNil(itemLink)
        if items.IsItemInfoLoaded(itemLink) then
            evaluationCache[itemLink] = false
        end
        return nil
    end

    local function EvaluateItem(itemLink)
        if not itemLink then
            return nil
        end
        local cachedEvaluation = evaluationCache[itemLink]
        if cachedEvaluation ~= nil then
            return cachedEvaluation or nil
        end

        local slots, replacesBothWeaponSlots = items.GetReplacementSlots(itemLink)
        if not slots then
            return CacheAndReturnNil(itemLink)
        end

        local className, classFile = UnitClass("player")
        local itemClassID, itemSubClassID = equipment.GetItemClassInfo(itemLink)
        if itemClassID == 2 and (itemSubClassID == 14 or itemSubClassID == 20) then
            -- Profession tools (mining picks, skinning knives) and fishing poles are not gear.
            return CacheAndReturnNil(itemLink)
        end

        local itemID, itemSetID = items.GetItemMetadata(itemLink)
        local rawItemStats = items.GetItemStats(itemLink)
        local weaponData = itemClassID == 2 and items.GetWeaponData(itemLink) or nil
        if next(rawItemStats) == nil
            and not weaponData
            and not (itemID and gearDuckDB.itemBonuses[itemID]) then
            -- Decorative items such as tabards have nothing to compare.
            return CacheAndReturnNil(itemLink)
        end

        local canEquip, equipRestrictionReason = equipment.CanPlayerEquipItem(itemLink)
        local unenchantedLink, enchantID = items.GetUnenchantedItemLink(itemLink)
        local isEnchantedWeapon = itemClassID == 2 and enchantID ~= nil

        local equippedState = GetEquippedState()
        local setCounts = equippedState.setCounts
        local equippedHit = equippedState.equippedHit
        local itemHitPercent = hit.GetItemHitPercent(itemLink) or 0
        local unenchantedHitPercent = isEnchantedWeapon and (hit.GetItemHitPercent(unenchantedLink) or 0) or itemHitPercent

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
                    scoring.ScoreItem(gearDuckDB, itemLink, classWeights, rawItemStats)
                local currentItemScoreWithoutEnchant = currentItemScore
                if isEnchantedWeapon then
                    currentItemScoreWithoutEnchant = scoring.ScoreItem(
                        gearDuckDB,
                        unenchantedLink,
                        classWeights
                    )
                end

                local canClassDualWieldForHit = classFileForContext == "WARRIOR"
                    or classFileForContext == "ROGUE"
                    or (classFileForContext == "SHAMAN" and hit.GetTalentBonuses().dualWield)
                local dualWielding = false
                if canClassDualWieldForHit and not replacesBothWeaponSlots then
                    local replacesOnlyOffHandWithNonWeapon = #slots == 1 and slots[1] == 17 and itemClassID ~= 2
                    if not replacesOnlyOffHandWithNonWeapon then
                        dualWielding = equippedState.mainHandIsWeapon and equippedState.offHandIsWeapon
                    end
                end

                local hitCap = hit.GetEffectiveHitCap(
                    classFileForContext,
                    context.key,
                    activityProfile,
                    dualWielding,
                    classWeights
                )
                hitCaps[context.key] = hitCap

                local contextEquipped = {}
                local slotComparisons = {}
                for _, slot in ipairs(slots) do
                    local equippedItem = GetEquippedSlotItem(equippedState, context.key, slot, classWeights)
                    contextEquipped[#contextEquipped + 1] = equippedItem
                    if not replacesBothWeaponSlots then
                        local replacedItems = { equippedItem }
                        local equippedScore = equippedItem.score
                        if slot == 17 and equippedState.mainHandIsTwoHander then
                            local mainHandItem = GetEquippedSlotItem(equippedState, context.key, 16, classWeights)
                            replacedItems = { mainHandItem, equippedItem }
                            equippedScore = mainHandItem.score + equippedItem.score
                        end
                        slotComparisons[#slotComparisons + 1] = {
                            label = EQUIP_SLOT_LABELS[slot] or ("Slot " .. slot),
                            equippedScore = equippedScore,
                            replacedItems = replacedItems,
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

                local cappedCurrentEquippedHit = math.min(hitCap, math.max(0, equippedHit))
                local hitWeight = classWeights.Hit or 0
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
                    local cappedHitDelta = math.min(hitCap, math.max(0, equippedHit - replacementHit + itemHitPercent))
                        - cappedCurrentEquippedHit
                    comparison.delta = currentItemScore - comparison.equippedScore
                        + (cappedHitDelta - (itemHitPercent - replacementHit)) * hitWeight
                        + setBonusDelta
                    if isEnchantedWeapon then
                        local cappedUnenchantedHitDelta = math.min(hitCap, math.max(0, equippedHit - replacementHit + unenchantedHitPercent))
                            - cappedCurrentEquippedHit
                        comparison.deltaWithoutEnchant = currentItemScoreWithoutEnchant - comparison.equippedScore
                            + (cappedUnenchantedHitDelta - (unenchantedHitPercent - replacementHit)) * hitWeight
                            + setBonusDelta
                    end
                    comparisons[#comparisons + 1] = comparison
                end
            end
        end

        local evaluationResult = {
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
        if canEquip ~= nil and equippedState.allEquippedLoaded and (not getItemInfo or getItemInfo(itemLink)) then
            evaluationCache[itemLink] = evaluationResult
        end
        return evaluationResult
    end

    local function ClearCache()
        wipe(evaluationCache)
        equippedStateCache = nil
        if items.ClearCache then
            items.ClearCache()
        end
        if hit.ClearItemCache then
            hit.ClearItemCache()
        end
    end

    local function SetDatabases(newDatabase, newWeightDatabase)
        gearDuckDB = newDatabase
        gearDuckWeightsDB = newWeightDatabase
        ClearCache()
    end

    return EvaluateItem, ClearCache, SetDatabases
end
