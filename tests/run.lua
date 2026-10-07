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

C_Item = {
    GetItemInfoInstant = function(itemLink)
        local itemID = tonumber(itemLink:match("item:(%d+)"))
        local item = itemData[itemID]
        if not item then
            return nil
        end
        return itemID, nil, nil, item.equipLocation, nil, item.classID, item.subclassID
    end,
    GetItemInfo = function(itemLink)
        local itemID = tonumber(itemLink:match("item:(%d+)"))
        local item = itemData[itemID]
        if not item then
            return nil
        end
        return "Test item", itemLink, 1, 1, 1, nil, nil, nil, item.equipLocation,
            nil, nil, item.classID, item.subclassID, nil, nil, item.setID
    end,
    GetItemStats = function(itemLink)
        local itemID = tonumber(itemLink:match("item:(%d+)"))
        return itemData[itemID] and itemData[itemID].stats or {}
    end,
}

function UnitClass()
    return "Warrior", "WARRIOR"
end

function UnitRace()
    return "Human", "Human"
end

function UnitLevel()
    return 60
end

function GetInventoryItemLink(_, slot)
    return slot == 5 and "item:2" or nil
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

-- Tools and stat-less items are ignored
itemData[3] = { equipLocation = "INVTYPE_CHEST", classID = 4, subclassID = 0, stats = {} }
itemData[4] = { equipLocation = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 20, stats = { ITEM_MOD_STRENGTH_SHORT = 5 } }
itemData[5] = { equipLocation = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 14, stats = {} }
equal(evaluateItem("item:3"), nil, "stat-less item has no evaluation")
equal(evaluateItem("item:4"), nil, "fishing pole has no evaluation")
equal(evaluateItem("item:5"), nil, "mining pick has no evaluation")
equal(evaluateItem("item:2") ~= nil, true, "item with stats still evaluated")

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

print(string.format("GearDuck Lua tests passed (%d assertions).", passed))
