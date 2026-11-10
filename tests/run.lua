local passed = 0

local function equal(actual, expected, message)
    assert(actual == expected, string.format(
        "%s: expected %s, got %s",
        message,
        tostring(expected),
        tostring(actual)
    ))
    passed = passed + 1
end

function wipe(value)
    for key in pairs(value) do
        value[key] = nil
    end
    return value
end

local itemData = {
    [1] = {
        equipLocation = "INVTYPE_CHEST",
        classID = 4,
        subclassID = 4,
        setID = 99,
        stats = { ITEM_MOD_STRENGTH_SHORT = 10 },
    },
    [2] = {
        equipLocation = "INVTYPE_CHEST",
        classID = 4,
        subclassID = 4,
        setID = nil,
        stats = { ITEM_MOD_STRENGTH_SHORT = 5 },
    },
}

local tooltipLinesByItemID = {
    [1] = { { leftText = "(2) Set: +5 Strength" } },
}
local itemStatsCalls = 0
local inventoryLinkCalls = 0

C_Item = {
    GetItemInfoInstant = function(itemLink)
        local itemID = tonumber(itemLink and itemLink:match("item:(%d+)"))
        local item = itemData[itemID]
        if not item then
            return nil
        end
        return itemID, nil, nil, item.equipLocation, nil, item.classID, item.subclassID
    end,
    GetItemInfo = function(itemLink)
        local itemID = tonumber(itemLink and itemLink:match("item:(%d+)"))
        local item = itemData[itemID]
        if not item or item.unloaded then
            return nil
        end
        return "Test item", itemLink, 1, 1, 1, nil, nil, nil, item.equipLocation,
            nil, nil, item.classID, item.subclassID, nil, nil, item.setID
    end,
    GetItemStats = function(itemLink)
        itemStatsCalls = itemStatsCalls + 1
        local itemID = tonumber(itemLink and itemLink:match("item:(%d+)"))
        return itemData[itemID] and itemData[itemID].stats or {}
    end,
}

C_TooltipInfo = {
    GetHyperlink = function(itemLink)
        local itemID = tonumber(itemLink and itemLink:match("item:(%d+)"))
        local lines = tooltipLinesByItemID[itemID]
        if not lines and (not itemData[itemID] or itemData[itemID].unloaded) then
            return nil
        end
        return { lines = lines or { { leftText = "Test item" } } }
    end,
}

local currentClassName, currentClassFile = "Warrior", "WARRIOR"
function UnitClass()
    return currentClassName, currentClassFile
end

function UnitRace()
    return "Human", "Human"
end

function UnitLevel()
    return 60
end

local equippedBySlot = { [5] = "item:2" }
function GetInventoryItemLink(_, slot)
    inventoryLinkCalls = inventoryLinkCalls + 1
    return equippedBySlot[slot]
end

function CreateFrame()
    return {
        SetOwner = function() end,
        ClearLines = function() end,
        SetHyperlink = function() end,
        NumLines = function() return 0 end,
        Hide = function() end,
    }
end

local addon = {}
local moduleFiles = {
    "GearDuckData.lua",
    "GearDuckItems.lua",
    "GearDuckSets.lua",
    "GearDuckProfiles.lua",
    "GearDuckTalents.lua",
    "GearDuckEquipment.lua",
    "GearDuckHit.lua",
    "GearDuckScoring.lua",
    "GearDuckEvaluation.lua",
    "GearDuckPresentation.lua",
    "GearDuckOptions.lua",
    "GearDuckUpgradeIndicators.lua",
    "GearDuckOnboarding.lua",
}

for _, fileName in ipairs(moduleFiles) do
    local chunk, err = loadfile("GearDuck\\" .. fileName)
    assert(chunk, err)
    chunk("GearDuck", addon)
end

local mainChunk, mainError = loadfile("GearDuck\\GearDuck.lua")
assert(mainChunk, mainError)

GearDuckDB = {
    weights = { WARRIOR = { Strength = 3 } },
    hitCaps = { QUEST = 12 },
    itemBonuses = {},
    enchantBonuses = {},
    setBonuses = {},
}
GearDuckWeightsDB = {}

local database = addon.profiles.NormalizeDatabase(GearDuckDB)
equal(database.upgradeArrowPosition, "TOPRIGHT", "existing saves default to top-right arrows")
for _, position in ipairs({ "TOPRIGHT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT", "CENTER" }) do
    local saved = addon.profiles.NormalizeDatabase({ upgradeArrowPosition = position })
    equal(saved.upgradeArrowPosition, position, position .. " survives normalization")
end
for _, invalid in ipairs({ "INVALID", false, 42, {} }) do
    local saved = addon.profiles.NormalizeDatabase({ upgradeArrowPosition = invalid })
    equal(saved.upgradeArrowPosition, "TOPRIGHT", "invalid arrow position defaults to top right")
end
local weightDatabase = addon.profiles.EnsureActivityWeightProfiles(database)
equal(weightDatabase.profiles.WARRIOR.QUEST.weights.Strength, 3, "legacy weight migration")
equal(weightDatabase.profiles.WARRIOR.QUEST.hitCaps.physical, 12, "legacy hit-cap migration")
equal(weightDatabase.profiles.WARRIOR.QUEST.hitCaps.spell, 12, "legacy hit-cap migration")
equal(addon.data.CLASS_ACTIVITY_DEFAULTS.WARRIOR.RAID.weights.Hit, 1.3 * 1.1, "raid class weights adjust hit")
equal(addon.data.CLASS_ACTIVITY_DEFAULTS.WARRIOR.PVP.weights.Stamina, 0.7 * 1.35, "pvp class weights adjust stamina")
for classFile, treeNames in pairs(addon.data.CLASS_TALENT_TREE_NAMES) do
    for treeKey in pairs(treeNames) do
        for _, context in ipairs(addon.data.SCORING_CONTEXT_ORDER) do
            equal(
                type(addon.data.CLASS_TALENT_DEFAULTS[classFile][context.key][treeKey]),
                "table",
                classFile .. " " .. treeKey .. " " .. context.key .. " starter weights"
            )
        end
    end
end

local armsWeights = addon.profiles.GetTalentWeightProfile(weightDatabase, "WARRIOR", "QUEST", "TREE_1")
local protectionWeights = addon.profiles.GetTalentWeightProfile(weightDatabase, "WARRIOR", "QUEST", "TREE_3")
equal(armsWeights.Strength, 2.2, "arms tree starter weights")
equal(protectionWeights.Defense, 1.2, "protection tree starter weights")
local raidArmsWeights = addon.profiles.GetTalentWeightProfile(weightDatabase, "WARRIOR", "RAID", "TREE_1")
equal(raidArmsWeights.Hit, 1.4 * 1.1, "tree starter weights vary by activity")
armsWeights.Strength = 7
addon.profiles.EnsureActivityWeightProfiles(database, weightDatabase)
equal(
    addon.profiles.GetTalentWeightProfile(weightDatabase, "WARRIOR", "QUEST", "TREE_1").Strength,
    7,
    "saved tree weights survive profile normalization"
)

local oldTreeProfile = {}
local oldClassProfile = {}
for statName, weight in pairs(addon.data.CLASS_WEIGHTS.WARRIOR) do
    oldTreeProfile[statName] = weight
    oldClassProfile[statName] = weight
end
oldTreeProfile.Strength = 9
oldClassProfile.Strength = 8
local oldWeightDatabase = {
    profiles = {
        WARRIOR = {
            QUEST = {
                weights = {},
                talentWeights = { TREE_1 = oldTreeProfile },
            },
            RAID = {
                weights = oldClassProfile,
                talentWeights = {},
            },
        },
    },
}
addon.profiles.EnsureActivityWeightProfiles(
    { weights = {}, talentWeights = {}, hitCaps = {} },
    oldWeightDatabase
)
equal(oldClassProfile.Hit, 1.3 * 1.1, "old activity defaults updated")
equal(oldClassProfile.Strength, 8, "custom class weight preserved during migration")
equal(oldTreeProfile.Hit, 1.4, "old tree defaults updated")
equal(oldTreeProfile.Strength, 9, "custom tree weight preserved during migration")
oldTreeProfile.Hit = 1.3
addon.profiles.EnsureActivityWeightProfiles(
    { weights = {}, talentWeights = {}, hitCaps = {} },
    oldWeightDatabase
)
equal(oldTreeProfile.Hit, 1.3, "migrated custom weights are preserved on later loads")

database.itemBonuses[1] = 2
local score = addon.scoring.ScoreItem(database, "item:1", { Strength = 1 })
equal(score, 12, "weighted stats plus manual item bonus")

itemData[20] = {
    stats = {
        ITEM_MOD_STAMINA_SHORT = 3,
        ITEM_MOD_SPIRIT_SHORT = -3,
    },
}
local negativeStatScore, negativeStatBreakdown = addon.scoring.ScoreItem(
    database,
    "item:20",
    { Stamina = 1, Spirit = 2 }
)
equal(negativeStatScore, -3, "negative item stats reduce the weighted score")
equal(negativeStatBreakdown.Spirit.amount, -3, "negative item stat amount is preserved")
equal(negativeStatBreakdown.Spirit.contribution, -6, "negative item stat contribution is preserved")

database.setBonuses[99] = { [2] = 20 }
equal(
    addon.sets.GetSetBonusDelta(database, 99, {}, { [99] = 1 }),
    20,
    "set bonus threshold crossing"
)

database.displayContexts = { QUEST = true, RAID = false, PVP = false }
database.itemBonuses[1] = nil
local questWeights = weightDatabase.profiles.WARRIOR.QUEST.weights
for statName in pairs(questWeights) do
    questWeights[statName] = 0
end
questWeights.Strength = 1

local evaluateItem, clearCache = addon.evaluation.Create(database, weightDatabase)
local evaluation = evaluateItem("item:1")
equal(evaluation.canEquip, true, "candidate equip eligibility")
equal(evaluation.comparisons[1].delta, 5, "candidate versus equipped item")

itemData[1].stats.ITEM_MOD_STRENGTH_SHORT = 15
equal(evaluateItem("item:1").comparisons[1].delta, 5, "evaluation cache stability")
clearCache()
equal(evaluateItem("item:1").comparisons[1].delta, 10, "evaluation cache invalidation")

-- Tools and stat-less items are ignored and cached negatively
itemData[3] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 0, stats = {} }
itemData[4] = { equipLocation = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 20, stats = { ITEM_MOD_STRENGTH_SHORT = 5 } }
itemData[5] = { equipLocation = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 14, stats = {} }
equal(evaluateItem("item:3"), nil, "stat-less item has no evaluation")
local statsCallsAfterFirstStatless = itemStatsCalls
equal(evaluateItem("item:3"), nil, "stat-less item negative cache hit")
equal(itemStatsCalls, statsCallsAfterFirstStatless, "negative cache avoids re-fetching stats")
equal(evaluateItem("item:4"), nil, "fishing pole has no evaluation")
equal(evaluateItem("item:5"), nil, "mining pick has no evaluation")
equal(evaluateItem("item:2") ~= nil, true, "item with stats still evaluated")

-- Equipped state is cached across multiple candidate evaluations
clearCache()
inventoryLinkCalls = 0
evaluateItem("item:1")
local callsAfterFirstEval = inventoryLinkCalls
evaluateItem("item:2")
equal(inventoryLinkCalls, callsAfterFirstEval, "equipped inventory links are cached across evaluations")

-- Candidate comparisons must not cache incomplete equipped-item data.
local originalGetItemStats = C_Item.GetItemStats
C_Item.GetItemStats = function(itemLink)
    if itemLink == "item:2" and itemData[2].unloaded then
        return {}
    end
    return originalGetItemStats(itemLink)
end
itemData[2].unloaded = true
clearCache()
equal(evaluateItem("item:1").comparisons[1].delta, 15, "comparison before equipped item loads")
itemData[2].unloaded = false
equal(evaluateItem("item:1").comparisons[1].delta, 10, "comparison updates after equipped item loads")
C_Item.GetItemStats = originalGetItemStats

-- Weapon damage + rightText speed parsing and statless white weapon evaluation
itemData[6] = { equipLocation = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 7, stats = {} }
tooltipLinesByItemID[6] = {
    { leftText = "40 - 60 Damage", rightText = "Speed 2.50" },
}
questWeights.WeaponDPS = 2
clearCache()
local weaponData = addon.items.GetWeaponData("item:6")
equal(weaponData ~= nil, true, "weapon data parsed when speed is in rightText")
equal(weaponData.dps, 20, "weapon DPS calculated from min/max and rightText speed")
equal(weaponData.speed, 2.5, "weapon speed parsed from rightText")
local whiteWeaponEval = evaluateItem("item:6")
equal(whiteWeaponEval ~= nil, true, "white weapon with no primary stats is still evaluated")

-- Spell hit and multi-line hit parsing + unloaded item cache protection
itemData[7] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 1, stats = {}, unloaded = true }
equal(addon.hit.GetItemHitPercent("item:7"), nil, "unloaded item returns nil hit")
itemData[7].unloaded = false
tooltipLinesByItemID[7] = {
    { leftText = "Equip: Improves your chance to hit with spells by 2%." },
    { leftText = "+1% Hit" },
}
equal(addon.hit.GetItemHitPercent("item:7"), 3, "spell hit and enchant hit are parsed after item loads")

-- Dual-wield slot filtering and off-hand weapon eligibility
itemData[8] = { equipLocation = "INVTYPE_WEAPON", classID = 2, subclassID = 15, stats = { ITEM_MOD_INTELLECT_SHORT = 10 } }
itemData[9] = { equipLocation = "INVTYPE_WEAPONOFFHAND", classID = 2, subclassID = 15, stats = { ITEM_MOD_INTELLECT_SHORT = 10 } }
currentClassName, currentClassFile = "Mage", "MAGE"
equal(addon.equipment.CanPlayerDualWield(), false, "mage cannot dual-wield")
local mageSlots = addon.items.GetReplacementSlots("item:8")
equal(#mageSlots, 1, "non-dual-wielder compares 1H weapon against main hand only")
equal(mageSlots[1], 16, "non-dual-wielder 1H weapon slot is main hand")
local mageCanEquipOffhandWeapon = addon.equipment.CanPlayerEquipItem("item:9")
equal(mageCanEquipOffhandWeapon, false, "non-dual-wielder cannot equip off-hand weapon")
currentClassName, currentClassFile = "Warrior", "WARRIOR"
equal(addon.equipment.CanPlayerDualWield(), true, "warrior at level 60 can dual-wield")
local warriorSlots = addon.items.GetReplacementSlots("item:8")
equal(#warriorSlots, 2, "dual-wielder compares 1H weapon against both hands")

-- Item-specific class restrictions apply even when the armor type is usable.
itemData[13] = {
    equipLocation = "INVTYPE_CHEST",
    classID = 4,
    subclassID = 2,
    stats = { ITEM_MOD_AGILITY_SHORT = 100 },
}
currentClassName, currentClassFile = "Rogue", "ROGUE"
tooltipLinesByItemID[13] = { { leftText = "Classes: Shaman" } }
local canEquipRestricted, restrictionReason = addon.equipment.CanPlayerEquipItem("item:13")
equal(canEquipRestricted, false, "rogue cannot equip shaman-only leather")
equal(restrictionReason, "Classes: Shaman", "class restriction explains allowed classes")
clearCache()
local restrictedEvaluation = evaluateItem("item:13")
equal(restrictedEvaluation.canEquip, false, "shared evaluation rejects restricted gear")
equal(restrictedEvaluation.equipRestrictionReason, "Classes: Shaman", "tooltip evaluation retains restriction")
equal(restrictedEvaluation.comparisons[1].delta > 0.05, true, "restricted test item would otherwise be an upgrade")
currentClassName, currentClassFile = "Shaman", "SHAMAN"
equal(addon.equipment.CanPlayerEquipItem("item:13"), true, "shaman can equip shaman-only leather")
currentClassName, currentClassFile = "Rogue", "ROGUE"
tooltipLinesByItemID[13] = { { leftText = "Classes: Shaman, |cfffff468Rogue|r, Druid" } }
equal(addon.equipment.CanPlayerEquipItem("item:13"), true, "colored multi-class list includes rogue")
clearCache()
local allowedEvaluation = evaluateItem("item:13")
tooltipLinesByItemID[13] = { { leftText = "Classes: Rogue Apprentice" } }
equal(addon.equipment.CanPlayerEquipItem("item:13"), false, "class names require an exact match")
tooltipLinesByItemID[13] = {
    { leftText = "Test item" },
    { leftText = "Requires Level 60", leftColor = { r = 1, g = 0, b = 0 } },
}
equal(addon.equipment.CanPlayerEquipItem("item:13"), true, "unrelated red text is not a class restriction")
ITEM_CLASSES_ALLOWED = "Allowed classes (%s)"
LOCALIZED_CLASS_NAMES_MALE = { ROGUE = "Localized Rogue" }
LOCALIZED_CLASS_NAMES_FEMALE = { ROGUE = "Localized Rogue Female" }
tooltipLinesByItemID[13] = { { leftText = "Allowed classes (Shaman, Localized Rogue)" } }
equal(addon.equipment.CanPlayerEquipItem("item:13"), true, "localized format and male class name")
tooltipLinesByItemID[13] = { { leftText = "Allowed classes (Localized Rogue Female)" } }
equal(addon.equipment.CanPlayerEquipItem("item:13"), true, "localized female class name")
tooltipLinesByItemID[13] = { { leftText = "Allowed classes (Shaman)" } }
equal(addon.equipment.CanPlayerEquipItem("item:13"), false, "localized class restriction rejects rogue")
ITEM_CLASSES_ALLOWED = nil
LOCALIZED_CLASS_NAMES_MALE = nil
LOCALIZED_CLASS_NAMES_FEMALE = nil

local originalGetHyperlink = C_TooltipInfo.GetHyperlink
C_TooltipInfo.GetHyperlink = function(itemLink)
    if itemLink == "item:13" then
        return nil
    end
    return originalGetHyperlink(itemLink)
end
clearCache()
equal(evaluateItem("item:13").canEquip, nil, "missing tooltip keeps class eligibility pending")
C_TooltipInfo.GetHyperlink = function(itemLink)
    if itemLink == "item:13" then
        return { lines = {} }
    end
    return originalGetHyperlink(itemLink)
end
equal(evaluateItem("item:13").canEquip, nil, "empty tooltip keeps class eligibility pending")
C_TooltipInfo.GetHyperlink = originalGetHyperlink
tooltipLinesByItemID[13] = { { leftText = "Classes: Shaman" } }
equal(evaluateItem("item:13").canEquip, false, "pending class eligibility is not cached")
tooltipLinesByItemID[13] = nil
currentClassName, currentClassFile = "Warrior", "WARRIOR"
clearCache()

-- 2H equipped in main hand vs off-hand item comparison
itemData[10] = { equipLocation = "INVTYPE_2HWEAPON", classID = 2, subclassID = 8, stats = { ITEM_MOD_STRENGTH_SHORT = 50 } }
itemData[11] = { equipLocation = "INVTYPE_SHIELD", classID = 4, subclassID = 6, stats = { ITEM_MOD_STRENGTH_SHORT = 10 } }
equippedBySlot[16] = "item:10"
equippedBySlot[17] = nil
questWeights.WeaponDPS = 0
questWeights.WeaponSkill = 0
clearCache()
local shieldEval = evaluateItem("item:11")
equal(shieldEval.comparisons[1].delta, -40, "off-hand shield accounts for unequipping 2H weapon in main hand")
equippedBySlot[16] = nil

-- Rogue Precision maxRanks and hybrid effective hit cap
equal(addon.data.HIT_TALENT_EFFECTS.precision.ROGUE.maxRanks, 5, "rogue precision supports 5 ranks")
local paladinRaidProfile = addon.data.CLASS_ACTIVITY_DEFAULTS.PALADIN.RAID
equal(
    addon.hit.GetEffectiveHitCap("PALADIN", "RAID", paladinRaidProfile, false, { Strength = 2, AttackPower = 1, SpellPower = 0.4 }),
    9,
    "physical hybrid build uses physical raid hit cap"
)
equal(
    addon.hit.GetEffectiveHitCap("PALADIN", "RAID", paladinRaidProfile, false, { Strength = 0.6, SpellPower = 1.2, Healing = 1.4 }),
    16,
    "caster hybrid build uses spell raid hit cap"
)

-- Per-character databases and onboarding
local rootDatabase = addon.profiles.NormalizeDatabase({ itemBonuses = { [7] = 3 } })
local rootWeights = {}
local dbA, weightsA = addon.profiles.GetCharacterDatabases(rootDatabase, rootWeights, "A-Realm")
local dbB, weightsB = addon.profiles.GetCharacterDatabases(rootDatabase, rootWeights, "B-Realm")
equal(dbA.upgradeArrowPosition, "TOPRIGHT", "new character defaults to top-right arrows")
dbA.upgradeArrowPosition = "CENTER"
equal(dbB.upgradeArrowPosition, "TOPRIGHT", "arrow position is per character")
equal(
    addon.profiles.GetCharacterDatabases(rootDatabase, rootWeights, "A-Realm").upgradeArrowPosition,
    "CENTER",
    "arrow position persists when character databases are reopened"
)
equal(dbA.itemBonuses, rootDatabase.itemBonuses, "shared item bonuses")
equal(rawget(dbA, "itemBonuses"), nil, "item bonuses not duplicated per character")
equal(addon.onboarding.IsComplete(dbA), false, "new character needs onboarding")

local defaultStrength = weightsA.profiles.WARRIOR.QUEST.weights.Strength
addon.onboarding.SetWeightMode(dbA, weightsA, "custom")
weightsA.profiles.WARRIOR.QUEST.weights.Strength = defaultStrength + 5
equal(weightsB.profiles.WARRIOR.QUEST.weights.Strength, defaultStrength, "weights are per character")
equal(dbA.onboarding.weightMode, "custom", "custom weights noted")

addon.onboarding.SetWeightMode(dbA, weightsA, "default")
equal(weightsA.profiles.WARRIOR.QUEST.weights.Strength, defaultStrength, "defaults restored after switching back")
equal(dbA.onboarding.weightMode, "default", "custom marker replaced by default")

addon.onboarding.SetContextSelected(dbA, "RAID", true)
addon.onboarding.SetContextSelected(dbA, "PVP", true)
addon.onboarding.SetContextSelected(dbA, "PVP", false)
equal(dbA.displayContexts.RAID, true, "selected profile applied")
equal(dbA.displayContexts.QUEST, false, "unselected profile hidden")
equal(dbB.displayContexts.QUEST, true, "other character profiles unchanged")

addon.onboarding.SetUpgradeArrows(dbA, false)
equal(dbA.showUpgradeArrows, false, "arrow choice applied")
equal(dbB.showUpgradeArrows, true, "other character arrows unchanged")

equal(addon.onboarding.Finish(dbA, weightsA), false, "finish without custom weights")
equal(addon.onboarding.IsComplete(dbA), true, "onboarding completed")
equal(dbA.showUpgradeArrows, false, "answered arrow choice kept on finish")

equal(addon.onboarding.Finish(dbB, weightsB), false, "skip uses default weights")
equal(dbB.displayContexts.QUEST, true, "skip uses default profile")
equal(dbB.showUpgradeArrows, true, "skip uses default arrows")

local dbC, weightsC = addon.profiles.GetCharacterDatabases(rootDatabase, rootWeights, "C-Realm")
addon.onboarding.SetWeightMode(dbC, weightsC, "custom")
equal(addon.onboarding.Finish(dbC, weightsC), true, "custom weights request options pane")

-- Upgrade-indicator refreshes resolve bank/merchant items and coalesce events.
local originalCreateFrame = CreateFrame
local refreshFrame
CreateFrame = function()
    refreshFrame = {
        RegisterEvent = function() end,
        SetScript = function(self, _, callback) self.onEvent = callback end,
    }
    return refreshFrame
end
local pendingTimers = {}
C_Timer = {
    After = function(_, callback)
        pendingTimers[#pendingTimers + 1] = callback
    end,
}
local function RunRefresh()
    equal(#pendingTimers, 1, "refresh requests coalesced into one timer")
    local callback = table.remove(pendingTimers, 1)
    callback()
end
local function NamedButton(name)
    return { GetName = function() return name end }
end
BankFrameItem1 = NamedButton("BankFrameItem1")
MerchantItem1ItemButton = NamedButton("MerchantItem1ItemButton")
MerchantBuyBackItemItemButton = NamedButton("MerchantBuyBackItemItemButton")
MerchantFrame = { selectedTab = 1 }
C_Container = {
    GetContainerItemLink = function(bagID, slotID)
        equal(bagID, -1, "bank item uses bank container")
        equal(slotID, 1, "bank item uses button slot")
        return "item:1"
    end,
}
GetMerchantItemLink = function(slot)
    equal(slot, 1, "merchant item uses button slot")
    return "item:2"
end
GetBuybackItemLink = function(slot) return "item:" .. (slot + 10) end
GetNumBuybackItems = function() return 2 end
itemData[12] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 4, stats = {} }
local refreshedLinks = {}
local invalidations = 0
local integration = addon.upgradeIndicators.Initialize(
    { showUpgradeArrows = false },
    function(link)
        refreshedLinks[#refreshedLinks + 1] = link
        return allowedEvaluation
    end,
    function() invalidations = invalidations + 1 end
)
local arrowVisible = false
local arrowPoint
local arrowClears = 0
local arrowCreations = 0
local arrow = {
    SetTexture = function() end,
    SetSize = function() end,
    ClearAllPoints = function() arrowClears = arrowClears + 1; arrowPoint = nil end,
    SetPoint = function(_, ...) arrowPoint = { ... } end,
    Show = function() arrowVisible = true end,
    Hide = function() arrowVisible = false end,
}
local itemButton = {
    Icon = { GetObjectType = function() return "Texture" end },
    CreateTexture = function() arrowCreations = arrowCreations + 1; return arrow end,
}
integration.SetDatabase({ showUpgradeArrows = true })
integration.UpdateUpgradeIndicator(itemButton, allowedEvaluation)
equal(arrowVisible, true, "allowed class receives an upgrade arrow")
equal(arrowPoint[1], "TOPRIGHT", "unconfigured arrows use top right")
for _, position in ipairs({
    { "TOPLEFT", 1, -1 },
    { "BOTTOMRIGHT", -1, 1 },
    { "BOTTOMLEFT", 1, 1 },
    { "CENTER", 0, 0 },
    { "TOPRIGHT", -1, -1 },
}) do
    integration.SetDatabase({ showUpgradeArrows = true, upgradeArrowPosition = position[1] })
    integration.UpdateUpgradeIndicator(itemButton, allowedEvaluation)
    equal(arrowPoint[1], position[1], "arrow anchor follows selected position")
    equal(arrowPoint[2], itemButton.Icon, "arrow anchors to the item icon")
    equal(arrowPoint[3], position[1], "relative anchor follows selected position")
    equal(arrowPoint[4], position[2], "arrow horizontal inset")
    equal(arrowPoint[5], position[3], "arrow vertical inset")
end
equal(arrowCreations, 1, "position changes reuse the existing arrow")
equal(arrowClears, 6, "position changes clear previous anchors")
integration.UpdateUpgradeIndicator(itemButton, restrictedEvaluation)
equal(arrowVisible, false, "class-restricted gear hides an existing upgrade arrow")
integration.SetDatabase({ showUpgradeArrows = false })
integration.ScheduleRefresh(2)
integration.ScheduleRefresh(2)
RunRefresh()
equal(refreshedLinks[1], "item:1", "bank item refreshed without hovering")
equal(refreshedLinks[2], "item:2", "merchant item refreshed without hovering")
equal(refreshedLinks[3], "item:12", "latest buyback item refreshed")
equal(#pendingTimers, 0, "loaded items do not trigger redundant retries")
MerchantFrame.selectedTab = 2
refreshedLinks = {}
integration.ScheduleRefresh()
RunRefresh()
equal(refreshedLinks[2], "item:11", "merchant buyback tab resolves buyback links")

refreshFrame.onEvent(refreshFrame, "UNIT_INVENTORY_CHANGED", "player")
equal(invalidations, 1, "first inventory event invalidates evaluations")
refreshFrame.onEvent(refreshFrame, "UNIT_INVENTORY_CHANGED", "player")
refreshFrame.onEvent(refreshFrame, "UNIT_INVENTORY_CHANGED", "target")
equal(invalidations, 1, "unchanged or non-player inventory does not invalidate evaluations")
equippedBySlot[16] = "item:10"
refreshFrame.onEvent(refreshFrame, "UNIT_INVENTORY_CHANGED", "player")
equal(invalidations, 2, "changed equipped link invalidates evaluations")
equippedBySlot[16] = nil

itemData[1].unloaded = true
integration.ScheduleRefresh(1)
RunRefresh()
equal(#pendingTimers, 1, "unloaded visible items trigger a retry")
itemData[1].unloaded = false
RunRefresh()
equal(#pendingTimers, 0, "retry stops after item info loads")

equal(integration.IsCharacterPaneFrame(NamedButton("CharacterHeadSlot")), true, "character equipment excluded")
equal(integration.IsCharacterPaneFrame(NamedButton("CharacterBag0Slot")), false, "bag slots not treated as character equipment")
equal(integration.IsCharacterPaneFrame(NamedButton("InspectHeadSlot")), false, "inspect frame not treated as player equipment")
C_Container = nil
BankFrameItem1 = nil
MerchantFrame = nil
MerchantItem1ItemButton = nil
MerchantBuyBackItemItemButton = nil
GetMerchantItemLink = nil
GetBuybackItemLink = nil
GetNumBuybackItems = nil

itemButton.itemLink = "item:1"
integration.SetDatabase({ showUpgradeArrows = true, upgradeArrowPosition = "CENTER" })
integration.RefreshAfterEvaluationInvalidated()
RunRefresh()
equal(arrowPoint[1], "CENTER", "settings refresh moves an existing arrow without hovering")
itemButton.itemLink = nil

-- Loot-roll icons refresh without hovering and resolve the current roll after gear changes.
local rollShown = true
local rollLinks = { [42] = "item:1", [43] = "item:2" }
GroupLootFrame1 = {
    rollID = 42,
    IsShown = function() return rollShown end,
}
GroupLootFrame1.IconFrame = {
    Icon = itemButton.Icon,
    CreateTexture = function() return arrow end,
    GetParent = function() return GroupLootFrame1 end,
}
GetLootRollItemLink = function(rollID) return rollLinks[rollID] end
local rollIntegration
rollIntegration = addon.upgradeIndicators.Initialize(
    { showUpgradeArrows = true },
    evaluateItem,
    function()
        clearCache()
        rollIntegration.RefreshAfterEvaluationInvalidated()
    end
)
clearCache()
arrowVisible = false
refreshFrame.onEvent(refreshFrame, "START_LOOT_ROLL", 42)
RunRefresh()
equal(arrowVisible, true, "loot-roll upgrade arrow appears without hovering")
equippedBySlot[16] = "item:10"
refreshFrame.onEvent(refreshFrame, "PLAYER_EQUIPMENT_CHANGED", 16)
RunRefresh()
equal(arrowVisible, true, "loot-roll arrow survives an unrelated equipment change")
equippedBySlot[5] = "item:1"
refreshFrame.onEvent(refreshFrame, "PLAYER_EQUIPMENT_CHANGED", 5)
RunRefresh()
equal(arrowVisible, false, "loot-roll arrow disappears when item is no longer an upgrade")
equippedBySlot[5] = "item:2"
refreshFrame.onEvent(refreshFrame, "PLAYER_EQUIPMENT_CHANGED", 5)
RunRefresh()
equal(arrowVisible, true, "loot-roll arrow returns when item becomes an upgrade again")
GroupLootFrame1.rollID = 43
refreshFrame.onEvent(refreshFrame, "START_LOOT_ROLL", 43)
RunRefresh()
equal(arrowVisible, false, "reused loot-roll icon evaluates the new roll")
GroupLootFrame1.rollID = 42
itemData[1].unloaded = true
refreshFrame.onEvent(refreshFrame, "START_LOOT_ROLL", 42)
RunRefresh()
equal(#pendingTimers, 1, "loot-roll item loading schedules a bounded retry")
itemData[1].unloaded = false
RunRefresh()
equal(arrowVisible, true, "loot-roll arrow refreshes after item loads")
rollShown = false
refreshFrame.onEvent(refreshFrame, "CANCEL_LOOT_ROLL", 42)
RunRefresh()
equal(arrowVisible, false, "hidden loot-roll window clears its arrow")
rollShown = true
rollLinks[42] = nil
rollIntegration.UpdateUpgradeIndicator(GroupLootFrame1.IconFrame, allowedEvaluation)
refreshFrame.onEvent(refreshFrame, "CANCEL_LOOT_ROLL", 42)
RunRefresh()
equal(arrowVisible, false, "expired loot roll clears an existing arrow")
equippedBySlot[16] = nil
GroupLootFrame1 = nil
GetLootRollItemLink = nil

-- Baganator may anchor its corner widget before asking GearDuck to update it.
local baganatorUpdate, baganatorInit
local baganatorArrow
local baganatorRefreshes = 0
local baganatorDB = { showUpgradeArrows = true }
Baganator = {
    API = {
        RegisterCornerWidget = function(_, id, onUpdate, onInit, defaultPosition)
            equal(id, "gearduck_upgrade", "existing Baganator widget identity retained")
            equal(defaultPosition.corner, "top_right", "Baganator default corner retained")
            baganatorUpdate, baganatorInit = onUpdate, onInit
        end,
        RequestItemButtonsRefresh = function()
            baganatorRefreshes = baganatorRefreshes + 1
            if baganatorArrow then
                arrow:SetPoint("TOPRIGHT", itemButton, "TOPRIGHT", -2, -2)
                baganatorUpdate(arrow, { itemLink = "item:1" })
            end
        end,
    },
}
local baganatorIntegration = addon.upgradeIndicators.Initialize(
    baganatorDB,
    function() return allowedEvaluation end,
    function() end
)
baganatorArrow = baganatorInit(itemButton)
for _, position in ipairs({ "TOPRIGHT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT", "CENTER" }) do
    baganatorDB.upgradeArrowPosition = position
    baganatorIntegration.RefreshAfterEvaluationInvalidated()
    RunRefresh()
    equal(arrowPoint[1], position, "Baganator arrow follows the selected position on refresh")
    equal(arrowPoint[2], itemButton.Icon, "Baganator arrow anchors to the icon, not its widget container")
    equal(baganatorUpdate(baganatorArrow, { itemLink = "item:1" }), true, "Baganator upgrade still visible")
end
equal(baganatorRefreshes, 6, "position changes request Baganator item-button refreshes")
baganatorDB.showUpgradeArrows = false
equal(baganatorUpdate(baganatorArrow, { itemLink = "item:1" }), false, "disabled Baganator arrows stay hidden")
Baganator = nil

CreateFrame = originalCreateFrame
C_Timer = nil

-- Exercise the options dropdown and character switching with lightweight UI doubles.
local framesByName = {}
local function NewOptionsWidget()
    local widget = {}
    for _, method in ipairs({
        "SetPoint", "SetSize", "SetWidth", "SetAutoFocus", "SetTextInsets",
        "SetCursorPosition", "SetScrollChild", "HookScript",
    }) do
        widget[method] = function() end
    end
    widget.SetText = function(self, text) self.text = text end
    widget.SetChecked = function(self, checked) self.checked = checked end
    widget.SetScript = function(self, script, callback) self[script] = callback end
    widget.CreateFontString = NewOptionsWidget
    return widget
end
CreateFrame = function(_, name)
    local widget = NewOptionsWidget()
    if name then
        framesByName[name] = widget
    end
    return widget
end
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_Initialize = function(widget, callback) widget.initialize = callback end
UIDropDownMenu_SetSelectedValue = function(widget, value) widget.selectedValue = value end
UIDropDownMenu_SetText = function(widget, text) widget.text = text end
UIDropDownMenu_CreateInfo = function() return {} end
local menuEntries
UIDropDownMenu_AddButton = function(info) menuEntries[#menuEntries + 1] = info end
local optionInvalidations = 0
local panel = addon.options.Create(dbB, weightsB, function()
    optionInvalidations = optionInvalidations + 1
end)
local positionDropdown = framesByName.GearDuckArrowPositionDropdown
equal(positionDropdown.selectedValue, "TOPRIGHT", "options initially select top right")
equal(positionDropdown.text, "Top right", "options initially display the default label")
menuEntries = {}
positionDropdown.initialize(positionDropdown, 1)
equal(#menuEntries, 5, "options offer exactly five arrow positions")
for index, expected in ipairs({
    { "TOPRIGHT", "Top right" },
    { "TOPLEFT", "Top left" },
    { "BOTTOMRIGHT", "Bottom right" },
    { "BOTTOMLEFT", "Bottom left" },
    { "CENTER", "Center" },
}) do
    local entry = menuEntries[index]
    equal(entry.value, expected[1], "position menu value")
    equal(entry.text, expected[2], "position menu label")
    equal(entry.checked, index == 1, "position menu marks the current selection")
    entry.func()
    equal(dbB.upgradeArrowPosition, expected[1], "dropdown saves selected position")
    equal(positionDropdown.selectedValue, expected[1], "dropdown updates selected value immediately")
    equal(positionDropdown.text, expected[2], "dropdown updates label immediately")
end
equal(optionInvalidations, 5, "each position selection triggers a refresh")
dbA.upgradeArrowPosition = "BOTTOMLEFT"
panel.SetGearDuckDatabases(dbA, weightsA)
equal(positionDropdown.selectedValue, "BOTTOMLEFT", "character switch refreshes the position dropdown")
equal(positionDropdown.text, "Bottom left", "character switch refreshes the position label")
CreateFrame = originalCreateFrame
UIDropDownMenu_SetWidth = nil
UIDropDownMenu_Initialize = nil
UIDropDownMenu_SetSelectedValue = nil
UIDropDownMenu_SetText = nil
UIDropDownMenu_CreateInfo = nil
UIDropDownMenu_AddButton = nil

do
    local setDB = addon.profiles.NormalizeDatabase({})
    local definitions = {
        { "(2) Set: +5 Agility", "Agility", 5 },
        { "(2) Set: -3 Spirit", "Spirit", -3 },
        { "(2) Set: +10 Strength", "Strength", 10 },
        { "(2) Set: +10 Stamina", "Stamina", 10 },
        { "(2) Set: +10 Intellect.", "Intellect", 10 },
        { "(2) Set: 20 Armor", "Armor", 20 },
        { "(2) Set: Increases armor by 20.", "Armor", 20 },
        { "(2) Set: Increases attack power by 10.", "AttackPower", 10 },
        { "(2) Set: Increases ranged attack power by 10.", "RangedAttackPower", 10 },
        { "(2) Set: Increases damage and healing done by magical spells and effects by up to 10.", "SpellPower", 10 },
        { "(2) Set: Increases healing done by spells and effects by up to 10.", "Healing", 10 },
        { "(2) Set: Restores 3 mana per 5 sec.", "ManaRegen", 3 },
        { "(2) Set: Increased Defense +5.", "Defense", 5 },
        { "(2) Set: Improves your chance to hit by 1%.", "Hit", 1 },
        { "(2) Set: Improves your chance to get a critical strike by 1%.", "Crit", 1 },
        { "(2) Set: Increases your chance to dodge an attack by 1%.", "Dodge", 1 },
        { "(2) Set: Increases your chance to parry an attack by 1%.", "Parry", 1 },
    }
    itemData[100] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 2,
        setID = 77, stats = { ITEM_MOD_AGILITY_SHORT = 1 } }
    for _, definition in ipairs(definitions) do
        tooltipLinesByItemID[100] = { { leftText = definition[1] } }
        local bonuses, loaded = addon.sets.GetItemSetBonuses("item:100")
        equal(loaded, true, "set tooltip is available")
        equal(bonuses[2].stats[definition[2]], definition[3], "supported set stat parsed: " .. definition[2])
    end
    tooltipLinesByItemID[100] = {
        { leftText = "|cff808080(2) Set: +5 Agility|r" },
        { leftText = "(2) Set: +10 Stamina" },
        { leftText = "(3) Set: Increases attack power by 10 for 5 sec after a critical strike." },
        { leftText = "(4) Set: Increases damage done by Nature spells and effects by up to 7." },
        { leftText = "(5) Set: Increased Staves +2." },
        { leftText = "Equip: +100 Agility" },
    }
    local parsed = addon.sets.GetItemSetBonuses("item:100")
    equal(parsed[2].stats.Agility, 5, "color-coded inactive bonus is detected")
    equal(parsed[2].stats.Stamina, 10, "multiple lines at one threshold are combined")
    equal(parsed[3].stats, nil, "conditional bonuses are not guessed")
    equal(parsed[4].stats, nil, "school-specific damage is not treated as generic spell power")
    equal(parsed[5].stats, nil, "weapon-specific skill is not treated as generic stats")
    local localizedSetFormat = rawget(_G, "ITEM_SET_BONUS")
    local localizedAgility = rawget(_G, "SPELL_STAT2_NAME")
    ITEM_SET_BONUS = "(%d) Ensemble : %s"
    SPELL_STAT2_NAME = "Agilite"
    tooltipLinesByItemID[100] = { { leftText = "(2) Ensemble : +5 Agilite" } }
    equal(addon.sets.GetItemSetBonuses("item:100")[2].stats.Agility, 5, "localized set and primary-stat labels")
    ITEM_SET_BONUS = localizedSetFormat
    SPELL_STAT2_NAME = localizedAgility

    local originalGrayFormat = rawget(_G, "ITEM_SET_BONUS_GRAY")
    local originalAttackPowerLabel = rawget(_G, "ITEM_MOD_ATTACK_POWER_SHORT")
    local originalRangedAttackPowerLabel = rawget(_G, "ITEM_MOD_RANGED_ATTACK_POWER_SHORT")
    ITEM_SET_BONUS = "Set: %s"
    ITEM_SET_BONUS_GRAY = "(%d) Set: %s"
    ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power"
    tooltipLinesByItemID[100] = { { leftText = "(3) Set: +10 Attack Power" } }
    local attackPowerBonuses, attackPowerLoaded = addon.sets.GetItemSetBonuses("item:100")
    equal(attackPowerLoaded, true, "numbered set format is recognized when active format has no piece count")
    equal(attackPowerBonuses[3].stats.AttackPower, 10, "attack power is read from the item's short stat line")
    equal(addon.sets.GetSetBonusDelta(setDB, 77, {}, { [77] = 2 },
        { AttackPower = 2 }, { [77] = attackPowerBonuses }), 20,
        "tooltip attack power is weighted when the third piece is equipped")
    equal(addon.sets.GetSetBonusDelta(setDB, nil, { { setID = 77 } }, { [77] = 3 },
        { AttackPower = 2 }, { [77] = attackPowerBonuses }), -20,
        "tooltip attack power is subtracted when the third piece is removed")
    tooltipLinesByItemID[100] = { { leftText = "(3) Set: Increases attack power by 10." } }
    equal(addon.sets.GetItemSetBonuses("item:100")[3].stats.AttackPower, 10,
        "long attack power descriptions use the numbered set format too")
    ITEM_SET_BONUS_GRAY = nil
    tooltipLinesByItemID[100] = { { leftText = "(3) Set: +10 Attack Power" } }
    equal(addon.sets.GetItemSetBonuses("item:100")[3].stats.AttackPower, 10,
        "English numbered format works when the gray format global is absent")
    ITEM_SET_BONUS_GRAY = "(%d) Ensemble : %s"
    ITEM_MOD_ATTACK_POWER_SHORT = "Puissance d'attaque"
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Puissance d'attaque a distance"
    tooltipLinesByItemID[100] = {
        { leftText = "|cff00ff00(3) Ensemble : +10 Puissance d'attaque|r" },
        { leftText = "(4) Ensemble : +12 Puissance d'attaque a distance" },
    }
    local localizedAttackPower = addon.sets.GetItemSetBonuses("item:100")
    equal(localizedAttackPower[3].stats.AttackPower, 10, "localized short attack power stat is detected")
    equal(localizedAttackPower[4].stats.RangedAttackPower, 12, "localized short ranged attack power stat is detected")
    ITEM_SET_BONUS = localizedSetFormat
    ITEM_SET_BONUS_GRAY = originalGrayFormat
    ITEM_MOD_ATTACK_POWER_SHORT = originalAttackPowerLabel
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = originalRangedAttackPowerLabel

    local lines = {
        { leftText = "(2) Set: 10 Armor" },
        { leftText = "(3) Set: +5 Agility" },
        { leftText = "(4) Set: Improves your chance to hit by 1%." },
        { leftText = "(5) Set: Increased Staves +2." },
    }
    tooltipLinesByItemID[100] = lines
    local bonuses = { [77] = addon.sets.GetItemSetBonuses("item:100") }
    local weights = { Agility = 2, Armor = 0.1, Hit = 3 }
    local function SetDelta(setID, replaced, counts)
        return addon.sets.GetSetBonusDelta(setDB, setID, replaced, counts, weights, bonuses)
    end
    equal(SetDelta(77, {}, {}), 0, "first piece does not activate a bonus")
    equal(SetDelta(77, {}, { [77] = 1 }), 1, "second piece activates armor bonus")
    equal(SetDelta(77, {}, { [77] = 2 }), 10, "third piece activates agility bonus only")
    equal(SetDelta(nil, { { setID = 77 } }, { [77] = 3 }), -10, "removing third piece loses agility bonus")
    equal(SetDelta(77, { { setID = 77 } }, { [77] = 3 }), 0, "same-set swap keeps existing bonuses")
    equal(SetDelta(nil, { { setID = 77 }, { setID = 77 } }, { [77] = 3 }), -11,
        "replacing two pieces can lose multiple thresholds")
    bonuses[88] = { [2] = { stats = { Agility = 3 }, text = "+3 Agility" } }
    equal(SetDelta(88, { { setID = 77 } }, { [77] = 3, [88] = 1 }), -4,
        "swapping sets combines the gained and lost bonuses")
    local _, hitDelta = SetDelta(77, {}, { [77] = 3 })
    equal(hitDelta, 1, "hit bonuses are returned separately for cap handling")
    equal(addon.sets.GetActiveSetHit(setDB, { [77] = 4 }, bonuses), 1, "active set hit is included in current hit")
    local _, _, unscored = SetDelta(77, {}, { [77] = 4 })
    equal(#unscored, 1, "unsupported threshold crossing is reported")
    equal(unscored[1].threshold, 5, "unsupported threshold is identified")
    local _, _, unchangedUnscored = SetDelta(77, { { setID = 77 } }, { [77] = 5 })
    equal(#unchangedUnscored, 0, "unchanged unsupported bonuses do not affect a swap")
    setDB.setBonuses[77] = { [3] = 25, [4] = 7, [5] = 9 }
    equal(SetDelta(77, {}, { [77] = 2 }), 25, "manual value replaces rather than adds to automatic bonus")
    local manualHitScore, manualHitDelta = SetDelta(77, {}, { [77] = 3 })
    equal(manualHitScore, 7, "manual hit-bonus override remains fixed PL")
    equal(manualHitDelta, 0, "manual override suppresses automatic hit")
    equal(addon.sets.GetActiveSetHit(setDB, { [77] = 4 }, bonuses), 0, "manual override suppresses current automatic hit")
    local manualScore, _, manualUnscored = SetDelta(77, {}, { [77] = 4 })
    equal(manualScore, 9, "manual values support unknown effects")
    equal(#manualUnscored, 0, "manual override resolves unsupported effect")
    setDB.setBonuses[77][3] = 0
    equal(SetDelta(77, {}, { [77] = 2 }), 0, "zero manual override is respected")
    setDB.setBonuses[77][3] = nil
    equal(SetDelta(77, {}, { [77] = 2 }), 10, "clearing an override restores automatic scoring")
    setDB.setBonuses[77] = nil

    currentClassName, currentClassFile = "Rogue", "ROGUE"
    addon.talents.ResetActiveTalentTreeCache()
    addon.hit.ResetTalentCache()
    local setWeights = addon.profiles.EnsureActivityWeightProfiles(setDB, {})
    for _, context in ipairs(addon.data.SCORING_CONTEXT_ORDER) do
        local profile = setWeights.profiles.ROGUE[context.key]
        for statName in pairs(profile.weights) do
            profile.weights[statName] = 0
        end
        profile.weights.Agility = context.key == "PVP" and 3 or 2
        profile.weights.Armor = 0.1
        profile.weights.Hit = 3
    end
    setDB.displayContexts = { QUEST = true, PVP = true }
    local evaluateSet, clearSetCache = addon.evaluation.Create(setDB, setWeights)
    itemData[101] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 2,
        stats = { ITEM_MOD_AGILITY_SHORT = 3 } }
    for id = 102, 105 do
        itemData[id] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 2,
            setID = id ~= 104 and 77 or nil, stats = {} }
        tooltipLinesByItemID[id] = lines
    end
    equippedBySlot = { [5] = "item:101", [6] = "item:102", [10] = "item:103" }
    local activation = evaluateSet("item:100")
    equal(activation.itemScore, 2, "individual item score excludes set stats")
    equal(activation.comparisons[1].delta, 6, "set completion can turn a lower-stat chest into an upgrade")
    equal(activation.comparisons[1].setBonusDelta, 10, "comparison exposes set contribution")
    equal(activation.comparisons[2].delta, 9, "set stats use each activity profile's weights")
    equal(activation.hasUnscoredSetBonus, false, "inactive unknown thresholds are not reported")
    equal(activation.setBonusDataPending, false, "complete set data is recognized")
    equal(evaluateSet("item:100"), activation, "complete set comparisons are cached")
    do
        local previousSetFormat = rawget(_G, "ITEM_SET_BONUS")
        local previousGrayFormat = rawget(_G, "ITEM_SET_BONUS_GRAY")
        ITEM_SET_BONUS = "Set: %s"
        ITEM_SET_BONUS_GRAY = "(%d) Set: %s"
        lines[2].leftText = "(3) Set: +10 Attack Power"
        setWeights.profiles.ROGUE.QUEST.weights.AttackPower = 2
        setWeights.profiles.ROGUE.PVP.weights.AttackPower = 4
        clearSetCache()
        local attackPowerComparison = evaluateSet("item:100")
        equal(attackPowerComparison.setBonusDataPending, false, "live-style globals do not report missing set data")
        equal(attackPowerComparison.hasUnscoredSetBonus, false, "short attack power bonus needs no manual override")
        equal(attackPowerComparison.comparisons[1].delta, 16, "quest comparison uses detected attack power")
        equal(attackPowerComparison.comparisons[2].delta, 34, "pvp comparison uses its own attack power weight")
        equippedBySlot[5] = "item:100"
        clearSetCache()
        equal(evaluateSet("item:101").comparisons[1].delta, -16, "removing live-style attack power set bonus is scored")
        equippedBySlot[5] = "item:101"
        lines[2].leftText = "(3) Set: +10 Attack Power for 5 sec."
        clearSetCache()
        equal(evaluateSet("item:100").hasUnscoredSetBonus, true, "conditional short attack power is not treated as permanent")
        lines[2].leftText = "(3) Set: +5 Agility"
        setWeights.profiles.ROGUE.QUEST.weights.AttackPower = 0
        setWeights.profiles.ROGUE.PVP.weights.AttackPower = 0
        ITEM_SET_BONUS = previousSetFormat
        ITEM_SET_BONUS_GRAY = previousGrayFormat
    end
    equippedBySlot[5] = "item:100"
    clearSetCache()
    equal(evaluateSet("item:101").comparisons[1].delta, -6, "non-set replacement accounts for losing equipped set bonus")

    equippedBySlot = { [5] = "item:101", [6] = "item:102", [10] = "item:103", [7] = "item:105", [1] = "item:104" }
    itemData[104].stats.ITEM_MOD_HIT_RATING_SHORT = 4
    clearSetCache()
    equal(addon.hit.GetItemHitPercent("item:100"), nil, "inactive set hit is not counted as item hit")
    equal(evaluateSet("item:100").comparisons[1].delta, -1, "new set hit is capped with the complete loadout")
    itemData[104].stats.ITEM_MOD_HIT_RATING_SHORT = 5
    clearSetCache()
    equal(evaluateSet("item:100").comparisons[1].delta, -4, "set hit above cap adds no PL")
    equippedBySlot[5] = "item:100"
    itemData[104].stats.ITEM_MOD_HIT_RATING_SHORT = 4
    clearSetCache()
    equal(evaluateSet("item:101").comparisons[1].delta, 1, "losing active set hit respects the cap")
    itemData[104].stats.ITEM_MOD_HIT_RATING_SHORT = 5
    clearSetCache()
    equal(evaluateSet("item:101").comparisons[1].delta, 4, "losing excess set hit does not subtract PL")

    equippedBySlot[5] = "item:101"
    itemData[104].setID = 77
    clearSetCache()
    local unknown = evaluateSet("item:100")
    equal(unknown.hasUnscoredSetBonus, true, "unsupported activated set effect is exposed to the UI")
    equal(unknown.comparisons[1].unscoredSetBonuses[1].threshold, 5, "debug data identifies unscored effect")
    local debugMessages = {}
    local originalChat = DEFAULT_CHAT_FRAME
    DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) debugMessages[#debugMessages + 1] = message end }
    addon.presentation.PrintDebug(unknown)
    equal(table.concat(debugMessages, "\n"):find("Increased Staves", 1, true) ~= nil, true,
        "debug output explains unsupported set effects")
    DEFAULT_CHAT_FRAME = originalChat

    equippedBySlot = { [5] = "item:101" }
    tooltipLinesByItemID[100] = { { leftText = "Item data still loading" } }
    clearSetCache()
    equal(evaluateSet("item:100").setBonusDataPending, true, "missing candidate set tooltip is reported")
    tooltipLinesByItemID[100] = lines
    equal(evaluateSet("item:100").setBonusDataPending, false, "candidate set data retries without cache invalidation")
    equippedBySlot = { [5] = "item:100" }
    tooltipLinesByItemID[100] = {}
    clearSetCache()
    equal(evaluateSet("item:101").setBonusDataPending, true, "missing equipped set tooltip is reported")
    tooltipLinesByItemID[100] = lines
    equal(evaluateSet("item:101").setBonusDataPending, false, "equipped set data retries without cache invalidation")
    itemData[100].stats = {}
    equippedBySlot = { [6] = "item:102", [10] = "item:103" }
    clearSetCache()
    equal(evaluateSet("item:100").comparisons[1].delta, 10, "statless set piece can complete a bonus")

    itemData[106] = { equipLocation = "INVTYPE_FINGER", classID = 4, subclassID = 0,
        setID = 77, stats = { ITEM_MOD_AGILITY_SHORT = 1 } }
    itemData[107] = { equipLocation = "INVTYPE_FINGER", classID = 4, subclassID = 0,
        stats = { ITEM_MOD_AGILITY_SHORT = 3 } }
    itemData[108] = { equipLocation = "INVTYPE_FINGER", classID = 4, subclassID = 0,
        setID = 77, stats = { ITEM_MOD_AGILITY_SHORT = 3 } }
    tooltipLinesByItemID[106] = lines
    tooltipLinesByItemID[108] = lines
    equippedBySlot = { [6] = "item:102", [11] = "item:107", [12] = "item:108" }
    clearSetCache()
    local ring = evaluateSet("item:106")
    equal(ring.comparisons[1].delta, 6, "first ring comparison can complete a set")
    equal(ring.comparisons[2].delta, -4, "second ring comparison preserves the same set count")
    setDB.setBonuses[77] = { [3] = 30 }
    clearSetCache()
    equal(evaluateSet("item:106").comparisons[1].delta, 26, "override changes refresh cached comparisons")
    setDB.setBonuses[77] = nil
    clearSetCache()
    equal(evaluateSet("item:106").comparisons[1].delta, 6, "cleared override restores automatic cached comparison")

    itemData[112] = { equipLocation = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 15,
        setID = 77, stats = { ITEM_MOD_AGILITY_SHORT = 1 } }
    itemData[113] = { equipLocation = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 15,
        stats = { ITEM_MOD_AGILITY_SHORT = 3 } }
    tooltipLinesByItemID[112] = lines
    equippedBySlot = { [6] = "item:102", [10] = "item:103", [16] = "item:113" }
    setDB.enchantBonuses[123] = 7
    clearSetCache()
    local enchanted = evaluateSet("|Hitem:112:123|h[Test weapon]|h")
    equal(enchanted.comparisons[1].delta, 13, "enchanted comparison includes one set activation")
    equal(enchanted.comparisons[1].deltaWithoutEnchant, 6, "unenchanted comparison includes the same set activation")

    currentClassName, currentClassFile = "Warrior", "WARRIOR"
    addon.talents.ResetActiveTalentTreeCache()
    addon.hit.ResetTalentCache()
    local warriorProfile = setWeights.profiles.WARRIOR.QUEST
    for statName in pairs(warriorProfile.weights) do
        warriorProfile.weights[statName] = 0
    end
    warriorProfile.weights.Agility = 2
    warriorProfile.weights.Armor = 0.1
    setDB.displayContexts = { QUEST = true }
    itemData[109] = { equipLocation = "INVTYPE_2HWEAPON", classID = 2, subclassID = 8,
        stats = { ITEM_MOD_AGILITY_SHORT = 1 } }
    itemData[110] = { equipLocation = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 7,
        setID = 77, stats = { ITEM_MOD_AGILITY_SHORT = 1 } }
    itemData[111] = { equipLocation = "INVTYPE_WEAPONOFFHAND", classID = 2, subclassID = 15,
        setID = 77, stats = { ITEM_MOD_AGILITY_SHORT = 1 } }
    tooltipLinesByItemID[110] = lines
    tooltipLinesByItemID[111] = lines
    equippedBySlot = { [6] = "item:102", [16] = "item:110", [17] = "item:111" }
    clearSetCache()
    equal(evaluateSet("item:109").comparisons[1].delta, -13,
        "two-handed swap loses bonuses from both removed set weapons")

    local getHyperlink = C_TooltipInfo.GetHyperlink
    C_TooltipInfo.GetHyperlink = nil
    local missingBonuses, missingReady = addon.sets.GetItemSetBonuses("item:100")
    equal(next(missingBonuses), nil, "missing tooltip API has no fabricated bonuses")
    equal(missingReady, false, "missing tooltip API is reported as unavailable")
    C_TooltipInfo.GetHyperlink = getHyperlink
end

do
    local originalSetFormat = rawget(_G, "ITEM_SET_BONUS")
    local originalGrayFormat = rawget(_G, "ITEM_SET_BONUS_GRAY")
    ITEM_SET_BONUS = "Set: %s"
    ITEM_SET_BONUS_GRAY = "(%d) Set: %s"
    local learningDB = addon.profiles.NormalizeDatabase({})
    local learningWeights = addon.profiles.EnsureActivityWeightProfiles(learningDB, {})
    currentClassName, currentClassFile = "Rogue", "ROGUE"
    addon.talents.ResetActiveTalentTreeCache()
    addon.hit.ResetTalentCache()
    for statName in pairs(learningWeights.profiles.ROGUE.QUEST.weights) do
        learningWeights.profiles.ROGUE.QUEST.weights[statName] = 0
    end
    learningWeights.profiles.ROGUE.QUEST.weights.Agility = 2
    learningWeights.profiles.ROGUE.QUEST.weights.AttackPower = 1
    itemData[200] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 2,
        setID = 200, stats = { ITEM_MOD_AGILITY_SHORT = 1 } }
    itemData[201] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 2,
        stats = { ITEM_MOD_AGILITY_SHORT = 3 } }
    itemData[202] = { equipLocation = "INVTYPE_WAIST", classID = 4, subclassID = 2,
        setID = 200, stats = {} }
    itemData[203] = { equipLocation = "INVTYPE_HAND", classID = 4, subclassID = 2,
        setID = 200, stats = {} }
    local inactive = {
        { leftText = "(2) Set: +10 Intellect." },
        { leftText = "(3) Set: +10 Attack Power." },
        { leftText = "(4) Set: An unsupported proc." },
    }
    local active = {
        { leftText = "Set: +10 Intellect.", type = 0 },
        { leftText = "Set: +10 Attack Power.", type = 0 },
        { leftText = "(4) Set: An unsupported proc.", type = 42 },
    }
    for _, id in ipairs({ 200, 202, 203 }) do
        tooltipLinesByItemID[id] = active
    end
    equippedBySlot = { [5] = "item:200", [6] = "item:202", [10] = "item:203" }
    local evaluateLearned, clearLearned = addon.evaluation.Create(learningDB, learningWeights)
    local coldComparison = evaluateLearned("item:201")
    equal(coldComparison.setBonusDataPending, true, "unlearned green bonuses cannot silently count as complete data")
    equal(learningDB.setBonusThresholds[200]["4"], nil, "learned thresholds use numeric keys")
    equal(learningDB.setBonusThresholds[200][4][1], "An unsupported proc.", "numbered effects are learned even beside unresolved active effects")
    for _, id in ipairs({ 200, 202, 203 }) do
        tooltipLinesByItemID[id] = inactive
    end
    equippedBySlot = { [6] = "item:202" }
    clearLearned()
    equal(evaluateLearned("item:200").setBonusDataPending, false, "hovering an inactive set piece teaches its thresholds")
    equal(learningDB.setBonusThresholds[200][3][1], "+10 Attack Power.", "attack power threshold comes from tooltip rather than item entries")
    equippedBySlot[10] = "item:203"
    clearLearned()
    equal(evaluateLearned("item:200").comparisons[1].delta, 12, "bag candidate includes newly activated learned attack power")
    equippedBySlot[5] = "item:201"
    clearLearned()
    equal(evaluateLearned("item:200").comparisons[1].delta, 6, "set item in bag beats higher individual stats when activating attack power")
    for _, id in ipairs({ 200, 202, 203 }) do
        tooltipLinesByItemID[id] = active
    end
    equippedBySlot[5] = "item:200"
    clearLearned()
    local reverseComparison = evaluateLearned("item:201")
    equal(reverseComparison.setBonusDataPending, false, "green bonuses resolve using learned thresholds")
    equal(reverseComparison.comparisons[1].setBonusDelta, -10, "removing equipped green three-piece bonus subtracts attack power")
    equal(reverseComparison.comparisons[1].delta, -6, "reverse comparison agrees with bag candidate comparison")
    local reloadedDB = addon.profiles.NormalizeDatabase({
        setBonusThresholds = learningDB.setBonusThresholds,
    })
    local afterReload = addon.evaluation.Create(reloadedDB, learningWeights)
    equal(afterReload("item:201").comparisons[1].delta, -6, "saved learning survives a fresh database and evaluator")
    local charDB = addon.profiles.GetCharacterDatabases(reloadedDB, {}, "SetLearning-Realm")
    equal(charDB.setBonusThresholds, reloadedDB.setBonusThresholds, "learned item-set definitions are shared across characters")
    equal(rawget(charDB, "setBonusThresholds"), nil, "learned definitions are not duplicated into character saves")

    learningDB.setBonusThresholds[200] = {
        [3] = { "+10 Intellect." }, [6] = { "+10 Attack Power." },
    }
    local gapped, gappedLoaded = addon.sets.GetItemSetBonuses("item:200", learningDB)
    equal(gappedLoaded, true, "active bonuses resolve without assuming consecutive thresholds")
    equal(gapped[6].stats.AttackPower, 10, "nonconsecutive learned threshold is preserved")
    learningDB.setBonusThresholds[200][3] = { "+10 Attack Power." }
    local _, ambiguousLoaded = addon.sets.GetItemSetBonuses("item:200", learningDB)
    equal(ambiguousLoaded, false, "ambiguous identical descriptions do not guess an active threshold")

    active[2].leftText = "Set: Improves your chance to hit by 1%."
    learningDB.setBonusThresholds[200] = {
        [2] = { "+10 Intellect." }, [3] = { "Improves your chance to hit by 1%." },
    }
    clearLearned()
    equal(addon.hit.GetItemHitPercent("item:200"), nil, "unnumbered active set hit is excluded from item hit")
    local activeHitBonuses, activeHitLoaded = addon.sets.GetItemSetBonuses("item:200", learningDB)
    equal(activeHitLoaded, true, "active set hit resolves from learned data")
    equal(addon.sets.GetActiveSetHit(learningDB, { [200] = 3 }, { [200] = activeHitBonuses }), 1,
        "active learned set hit is counted once in loadout hit")
    local _, activeText = addon.items.GetSetBonusLine("|cff00ff00Set: +10 Attack Power.|r")
    equal(activeText, "+10 Attack Power.", "active green set line is recognized independently of its threshold")
    ITEM_SET_BONUS = originalSetFormat
    ITEM_SET_BONUS_GRAY = originalGrayFormat
end

print(string.format("GearDuck Lua tests passed (%d assertions).", passed))
