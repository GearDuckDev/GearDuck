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

local tooltipLinesByItemID = {}
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
    function(link) refreshedLinks[#refreshedLinks + 1] = link end,
    function() invalidations = invalidations + 1 end
)
local arrowVisible = false
local arrow = {
    SetTexture = function() end,
    SetSize = function() end,
    SetPoint = function() end,
    Show = function() arrowVisible = true end,
    Hide = function() arrowVisible = false end,
}
local itemButton = {
    Icon = { GetObjectType = function() return "Texture" end },
    CreateTexture = function() return arrow end,
}
integration.SetDatabase({ showUpgradeArrows = true })
integration.UpdateUpgradeIndicator(itemButton, allowedEvaluation)
equal(arrowVisible, true, "allowed class receives an upgrade arrow")
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
CreateFrame = originalCreateFrame
C_Timer = nil
C_Container = nil
BankFrameItem1 = nil
MerchantFrame = nil
MerchantItem1ItemButton = nil
MerchantBuyBackItemItemButton = nil
GetMerchantItemLink = nil
GetBuybackItemLink = nil
GetNumBuybackItems = nil

print(string.format("GearDuck Lua tests passed (%d assertions).", passed))
