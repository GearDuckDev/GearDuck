-- Rough level-60 Classic PvE starting weights, not simulation-derived values.
-- Tune these profiles for your class, specialization, and content.
local STAT_KEYS = {
    Strength = { "ITEM_MOD_STRENGTH_SHORT" },
    Agility = {
        "ITEM_MOD_AGILITY_SHORT",
    },
    Stamina = { "ITEM_MOD_STAMINA_SHORT" },
    Intellect = { "ITEM_MOD_INTELLECT_SHORT" },
    Spirit = { "ITEM_MOD_SPIRIT_SHORT" },
    Hit = {
        "ITEM_MOD_HIT_RATING_SHORT",
        "ITEM_MOD_HIT_MELEE_RATING_SHORT",
        "ITEM_MOD_HIT_SPELL_RATING_SHORT",
    },
    Crit = {
        "ITEM_MOD_CRIT_RATING_SHORT",
        "ITEM_MOD_CRIT_MELEE_RATING_SHORT",
        "ITEM_MOD_CRIT_SPELL_RATING_SHORT",
    },
    AttackPower = { "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_ATTACK_POWER" },
    RangedAttackPower = { "ITEM_MOD_RANGED_ATTACK_POWER_SHORT" },
    SpellPower = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" },
    Healing = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT" },
    ManaRegen = { "ITEM_MOD_MANA_REGENERATION_SHORT" },
    Defense = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT" },
    Dodge = { "ITEM_MOD_DODGE_RATING_SHORT" },
    Parry = { "ITEM_MOD_PARRY_RATING_SHORT" },
    Armor = { "RESISTANCE0_NAME" },
    WeaponDPS = {},
    WeaponSpeed = {},
    WeaponSkill = {},
    WeaponCritPercent = {},
    WeaponExtraAttackPercent = {},
}

local CLASS_WEIGHTS = {
    WARRIOR = {
        Strength = 2.0, Agility = 0.7, Stamina = 0.7, Hit = 1.3,
        Crit = 1.0, AttackPower = 0.8, Defense = 0.6, Dodge = 0.4,
        Parry = 0.4, Armor = 0.05, WeaponDPS = 2.0, WeaponSkill = 0.7,
        WeaponCritPercent = 3.0, WeaponExtraAttackPercent = 4.0,
    },
    PALADIN = {
        Strength = 1.3, Agility = 0.3, Stamina = 0.7, Intellect = 0.8,
        Spirit = 0.3, Hit = 0.7, Crit = 0.6, AttackPower = 0.8,
        SpellPower = 0.6, Healing = 0.5, ManaRegen = 0.4,
        Defense = 0.5, Armor = 0.05, WeaponDPS = 1.5, WeaponSkill = 0.5,
    },
    HUNTER = {
        Agility = 2.0, Stamina = 0.6, Intellect = 0.5, Spirit = 0.2,
        Hit = 1.2, Crit = 1.1, AttackPower = 0.8, RangedAttackPower = 1.3,
        WeaponDPS = 1.8, WeaponSkill = 0.5,
    },
    ROGUE = {
        Agility = 2.0, Stamina = 0.5, Hit = 1.5, Crit = 1.0,
        AttackPower = 1.0, WeaponDPS = 2.0, WeaponSkill = 0.7,
        WeaponCritPercent = 3.0, WeaponExtraAttackPercent = 4.0,
    },
    PRIEST = {
        Stamina = 0.6, Intellect = 1.2, Spirit = 0.9, Hit = 0.3,
        Crit = 0.4, SpellPower = 1.2, Healing = 1.0, ManaRegen = 0.7,
    },
    SHAMAN = {
        Strength = 0.7, Agility = 0.8, Stamina = 0.7, Intellect = 0.9,
        Spirit = 0.3, Hit = 0.8, Crit = 0.7, AttackPower = 0.7,
        SpellPower = 0.8, Healing = 0.6, ManaRegen = 0.5, WeaponDPS = 1.2,
        WeaponSkill = 0.4,
    },
    MAGE = {
        Stamina = 0.6, Intellect = 1.4, Spirit = 0.5, Hit = 1.0,
        Crit = 0.8, SpellPower = 1.4, ManaRegen = 0.4,
    },
    WARLOCK = {
        Stamina = 0.7, Intellect = 1.1, Spirit = 0.3, Hit = 1.0,
        Crit = 0.7, SpellPower = 1.5, ManaRegen = 0.3,
    },
    DRUID = {
        Strength = 0.7, Agility = 0.9, Stamina = 0.7, Intellect = 0.9,
        Spirit = 0.5, Hit = 0.6, Crit = 0.6, AttackPower = 0.6,
        SpellPower = 0.8, Healing = 0.7, ManaRegen = 0.5,
        Defense = 0.2, Dodge = 0.2, Armor = 0.03, WeaponDPS = 1.0,
        WeaponSkill = 0.3,
    },
}

local CLASS_ACTIVITY_HIT_CAPS = {
    QUEST = { physical = 5, spell = 3 },
    RAID = { physical = 9, spell = 16 },
    PVP = { physical = 5, spell = 3 },
}

local CLASSIC_DEFAULT_WEIGHTS = {
    Strength = 0.8, Agility = 0.8, Stamina = 0.5, Intellect = 0.5,
    Spirit = 0.3, Hit = 0.8, Crit = 0.7, AttackPower = 0.7,
    RangedAttackPower = 0.7, SpellPower = 0.7, Healing = 0.7,
    ManaRegen = 0.3, Defense = 0.2, Dodge = 0.2, Parry = 0.2,
    Armor = 0.02, WeaponSkill = 0.4,
    WeaponCritPercent = 0, WeaponExtraAttackPercent = 0,
}

local STAT_ORDER = {
    "Strength", "Agility", "Stamina", "Intellect", "Spirit", "Hit", "Crit",
    "AttackPower", "RangedAttackPower", "SpellPower", "Healing", "ManaRegen",
    "Defense", "Dodge", "Parry", "Armor", "WeaponDPS", "WeaponSpeed", "WeaponSkill",
    "WeaponCritPercent", "WeaponExtraAttackPercent",
}

local STAT_LABELS = {
    AttackPower = "Attack Power",
    RangedAttackPower = "Ranged Attack Power",
    SpellPower = "Spell Power / Damage",
    ManaRegen = "Mana Regeneration",
    WeaponDPS = "Weapon DPS",
    WeaponSpeed = "Weapon Speed Preference",
    WeaponSkill = "Weapon Skill",
    WeaponCritPercent = "Weapon-Specific Crit %",
    WeaponExtraAttackPercent = "Weapon-Specific Extra Attack %",
}

local CLASS_OPTIONS = {
    { file = "WARRIOR", name = "Warrior" },
    { file = "PALADIN", name = "Paladin" },
    { file = "HUNTER", name = "Hunter" },
    { file = "ROGUE", name = "Rogue" },
    { file = "PRIEST", name = "Priest" },
    { file = "SHAMAN", name = "Shaman" },
    { file = "MAGE", name = "Mage" },
    { file = "WARLOCK", name = "Warlock" },
    { file = "DRUID", name = "Druid" },
}

local EQUIP_SLOTS = {
    INVTYPE_HEAD = { 1 },
    INVTYPE_NECK = { 2 },
    INVTYPE_SHOULDER = { 3 },
    INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 },
    INVTYPE_2HWEAPON = { 16, 17 },
    INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_SHIELD = { 17 },
    INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 18 },
    INVTYPE_RANGEDRIGHT = { 18 },
    INVTYPE_THROWN = { 18 },
    INVTYPE_RELIC = { 18 },
}

local EQUIP_SLOT_LABELS = {
    [1] = "Head",
    [2] = "Neck",
    [3] = "Shoulder",
    [4] = "Shirt",
    [5] = "Chest",
    [6] = "Waist",
    [7] = "Legs",
    [8] = "Feet",
    [9] = "Wrist",
    [10] = "Hands",
    [11] = "Ring 1",
    [12] = "Ring 2",
    [13] = "Trinket 1",
    [14] = "Trinket 2",
    [15] = "Back",
    [16] = "Main Hand",
    [17] = "Off Hand",
    [18] = "Ranged",
}

local lastEvaluation
local lastTooltip
local optionsPanel
local optionsCategory
local activeTalentTreeCache
local activeTalentTreeScanned = false
local weaponTalentEffectsCache
local hitTalentBonusesCache
local itemHitPercentCache = {}
local shamanTwoHandedWeaponTalentActive = false

local RACIAL_WEAPON_SKILL = {
    Human = { [4] = 5, [5] = 5, [7] = 5, [8] = 5 },
    Dwarf = { [3] = 5 },
    Orc = { [0] = 5, [1] = 5, [13] = 5 },
    Troll = { [2] = 5, [16] = 5 },
}

local TALENT_WEAPON_EFFECTS = {
    ["weapon expertise"] = {
        ROGUE = { skillRanks = { 3, 5 }, subclasses = { 7, 8, 13, 15 } },
    },
    ["mace specialization"] = {
        ROGUE = { skillPerRank = 1, subclasses = { 4, 5 } },
    },
    ["axe specialization"] = {
        WARRIOR = { critPerRank = 1, subclasses = { 0, 1 } },
    },
    ["polearm specialization"] = {
        WARRIOR = { critPerRank = 1, subclasses = { 6 } },
    },
    ["sword specialization"] = {
        WARRIOR = { extraAttackPerRank = 2, subclasses = { 7, 8 } },
        ROGUE = { extraAttackPerRank = 1, subclasses = { 7, 8 } },
    },
    ["dagger specialization"] = {
        ROGUE = { critPerRank = 1, subclasses = { 15 } },
    },
    ["fist weapon specialization"] = {
        ROGUE = { critPerRank = 1, subclasses = { 13 } },
    },
    ["two-handed weapon specialization"] = {
        WARRIOR = { damagePerRank = 1, subclasses = { 1, 5, 6, 8, 10 } },
        PALADIN = { damagePerRank = 2, subclasses = { 1, 5, 6, 8, 10 } },
    },
    ["one-handed weapon specialization"] = {
        WARRIOR = { damagePerRank = 2, subclasses = { 0, 4, 7, 13, 15 } },
        PALADIN = { damagePerRank = 2, subclasses = { 0, 4, 7, 13, 15 } },
    },
    ["ranged weapon specialization"] = {
        HUNTER = { damagePerRank = 1, subclasses = { 2, 3, 18 } },
    },
}

local SCORING_CONTEXTS = {
    RAID = "Raid",
    QUEST = "Questing",
    PVP = "PvP",
}

local SCORING_CONTEXT_ORDER = {
    { key = "QUEST", name = "Questing" },
    { key = "RAID", name = "Raid" },
    { key = "PVP", name = "PvP" },
}

local function CopyWeights(weights)
    local copy = {}
    for statName, weight in pairs(weights) do
        copy[statName] = weight
    end
    return copy
end

local CLASS_ACTIVITY_DEFAULTS = {}
for classFile, classWeights in pairs(CLASS_WEIGHTS) do
    CLASS_ACTIVITY_DEFAULTS[classFile] = {}
    for _, context in ipairs(SCORING_CONTEXT_ORDER) do
        CLASS_ACTIVITY_DEFAULTS[classFile][context.key] = {
            weights = CopyWeights(classWeights),
            hitCaps = {
                physical = CLASS_ACTIVITY_HIT_CAPS[context.key].physical,
                spell = CLASS_ACTIVITY_HIT_CAPS[context.key].spell,
            },
        }
    end
end

local function EnsureWeightProfile(profile, defaults)
    if type(profile) ~= "table" then
        profile = {}
    end

    for statName in pairs(STAT_KEYS) do
        if type(profile[statName]) ~= "number" then
            profile[statName] = defaults[statName] or 0
        end
    end

    return profile
end

local function EnsureContextSettings(database)
    if type(database.hitCaps) ~= "table" then
        database.hitCaps = {}
    end
    for _, context in ipairs(SCORING_CONTEXT_ORDER) do
        if type(database.hitCaps[context.key]) ~= "number" then
            database.hitCaps[context.key] = 0
        end
    end

    if type(database.displayContexts) ~= "table" then
        database.displayContexts = {}
        for _, context in ipairs(SCORING_CONTEXT_ORDER) do
            database.displayContexts[context.key] = context.key == "QUEST"
        end
    else
        local hasDisplayedContext = false
        for _, context in ipairs(SCORING_CONTEXT_ORDER) do
            database.displayContexts[context.key] = database.displayContexts[context.key] == true
            hasDisplayedContext = hasDisplayedContext or database.displayContexts[context.key]
        end
        if not hasDisplayedContext then
            database.displayContexts.QUEST = true
        end
    end

    if not SCORING_CONTEXTS[database.hitCapContext] then
        database.hitCapContext = "QUEST"
    end
end

local function EnsureActivityWeightProfiles(legacyDatabase)
    local weightDatabase = rawget(_G, "GearDuckWeightsDB")
    if type(weightDatabase) ~= "table" then
        weightDatabase = {}
    end
    if type(weightDatabase.profiles) ~= "table" then
        weightDatabase.profiles = {}
    end

    local legacyWeights = type(legacyDatabase.weights) == "table" and legacyDatabase.weights or {}
    local legacyTalentWeights = type(legacyDatabase.talentWeights) == "table"
        and legacyDatabase.talentWeights or {}
    local legacyHitCaps = type(legacyDatabase.hitCaps) == "table" and legacyDatabase.hitCaps or {}

    for classFile, contextDefaults in pairs(CLASS_ACTIVITY_DEFAULTS) do
        if type(weightDatabase.profiles[classFile]) ~= "table" then
            weightDatabase.profiles[classFile] = {}
        end
        for _, context in ipairs(SCORING_CONTEXT_ORDER) do
            local contextKey = context.key
            local defaults = contextDefaults[contextKey]
            local profile = weightDatabase.profiles[classFile][contextKey]
            if type(profile) ~= "table" then
                profile = {}
                weightDatabase.profiles[classFile][contextKey] = profile
            end

            if type(profile.weights) ~= "table" then
                local legacyProfile = legacyWeights[classFile]
                profile.weights = CopyWeights(type(legacyProfile) == "table" and legacyProfile or defaults.weights)
            end
            profile.weights = EnsureWeightProfile(profile.weights, defaults.weights)

            if type(profile.hitCaps) ~= "table" then
                profile.hitCaps = {
                    physical = defaults.hitCaps.physical,
                    spell = defaults.hitCaps.spell,
                }
                local migratedHitCap = tonumber(legacyHitCaps[contextKey])
                if migratedHitCap and migratedHitCap > 0 then
                    profile.hitCaps.physical = migratedHitCap
                    profile.hitCaps.spell = migratedHitCap
                end
            else
                for _, hitType in ipairs({ "physical", "spell" }) do
                    if type(profile.hitCaps[hitType]) ~= "number" then
                        profile.hitCaps[hitType] = defaults.hitCaps[hitType]
                    end
                end
            end

            if type(profile.talentWeights) ~= "table" then
                profile.talentWeights = {}
                local legacyProfiles = legacyTalentWeights[classFile]
                if type(legacyProfiles) == "table" then
                    for treeKey, legacyProfile in pairs(legacyProfiles) do
                        if type(legacyProfile) == "table" then
                            profile.talentWeights[treeKey] = CopyWeights(legacyProfile)
                        end
                    end
                end
            end

            for treeKey, treeProfile in pairs(profile.talentWeights) do
                profile.talentWeights[treeKey] = EnsureWeightProfile(treeProfile, defaults.weights)
            end
        end
    end

    rawset(_G, "GearDuckWeightsDB", weightDatabase)
    return weightDatabase
end

local function MigrateLegacyWeightProfiles(legacyDatabase, weightDatabase)
    local legacyWeights = type(legacyDatabase.weights) == "table" and legacyDatabase.weights or {}
    local legacyTalentWeights = type(legacyDatabase.talentWeights) == "table"
        and legacyDatabase.talentWeights or {}
    local legacyHitCaps = type(legacyDatabase.hitCaps) == "table" and legacyDatabase.hitCaps or {}

    for classFile, contextDefaults in pairs(CLASS_ACTIVITY_DEFAULTS) do
        local legacyClassWeights = legacyWeights[classFile]
        local legacyClassTalentWeights = legacyTalentWeights[classFile]
        for _, context in ipairs(SCORING_CONTEXT_ORDER) do
            local profile = weightDatabase.profiles[classFile][context.key]
            local defaults = contextDefaults[context.key]
            if type(legacyClassWeights) == "table" then
                profile.weights = EnsureWeightProfile(CopyWeights(legacyClassWeights), defaults.weights)
            end
            if type(legacyClassTalentWeights) == "table" then
                for treeKey, treeWeights in pairs(legacyClassTalentWeights) do
                    if type(treeWeights) == "table" then
                        profile.talentWeights[treeKey] = EnsureWeightProfile(CopyWeights(treeWeights), defaults.weights)
                    end
                end
            end

            local legacyHitCap = tonumber(legacyHitCaps[context.key])
            if legacyHitCap and legacyHitCap > 0 then
                profile.hitCaps.physical = legacyHitCap
                profile.hitCaps.spell = legacyHitCap
            end
        end
    end
end

local gearDuckDB = rawget(_G, "GearDuckDB")
if type(gearDuckDB) ~= "table" then
    gearDuckDB = {}
end
if type(gearDuckDB.weights) ~= "table" then
    gearDuckDB.weights = {}
end
if type(gearDuckDB.talentWeights) ~= "table" then
    gearDuckDB.talentWeights = {}
end
if type(gearDuckDB.itemBonuses) ~= "table" then
    gearDuckDB.itemBonuses = {}
end
if type(gearDuckDB.enchantBonuses) ~= "table" then
    gearDuckDB.enchantBonuses = {}
end
if type(gearDuckDB.setBonuses) ~= "table" then
    gearDuckDB.setBonuses = {}
end
EnsureContextSettings(gearDuckDB)
local gearDuckWeightsDB = EnsureActivityWeightProfiles(gearDuckDB)
rawset(_G, "GearDuckDB", gearDuckDB)

local function GetActiveTalentTree()
    if activeTalentTreeScanned then
        return activeTalentTreeCache and activeTalentTreeCache.key,
            activeTalentTreeCache and activeTalentTreeCache.name,
            activeTalentTreeCache and activeTalentTreeCache.points,
            activeTalentTreeCache and activeTalentTreeCache.configID
    end

    activeTalentTreeScanned = true
    local classTalents = rawget(_G, "C_ClassTalents")
    local traits = rawget(_G, "C_Traits")
    local getActiveConfigID = classTalents and rawget(classTalents, "GetActiveConfigID")
    local getConfigInfo = traits and rawget(traits, "GetConfigInfo")
    local getTreeNodes = traits and rawget(traits, "GetTreeNodes")
    local getNodeInfo = traits and rawget(traits, "GetNodeInfo")
    if getActiveConfigID and getConfigInfo and getTreeNodes and getNodeInfo then
        local configID = getActiveConfigID()
        local configInfo = configID and getConfigInfo(configID)
        local treeIDs = configInfo and configInfo.treeIDs
        if type(treeIDs) == "table" and #treeIDs > 0 then
            local points = 0
            for _, treeID in ipairs(treeIDs) do
                local nodeIDs = getTreeNodes(treeID) or {}
                for _, nodeID in ipairs(nodeIDs) do
                    local nodeInfo = getNodeInfo(configID, nodeID)
                    if nodeInfo then
                        points = points + (tonumber(nodeInfo.ranksPurchased) or 0)
                    end
                end
            end

            local treeName
            local specializationInfo = rawget(_G, "C_SpecializationInfo")
            local getSpecialization = specializationInfo and rawget(specializationInfo, "GetSpecialization")
            local getSpecializationInfo = specializationInfo and rawget(specializationInfo, "GetSpecializationInfo")
            if getSpecialization and getSpecializationInfo then
                local specialization = getSpecialization()
                if specialization then
                    local _, name = getSpecializationInfo(specialization)
                    treeName = name
                end
            end
            treeName = treeName or configInfo.name or "Active talent build"

            local treeKeyParts = {}
            for _, treeID in ipairs(treeIDs) do
                treeKeyParts[#treeKeyParts + 1] = tostring(treeID)
            end
            activeTalentTreeCache = {
                key = "TRAIT_" .. table.concat(treeKeyParts, "_"),
                name = treeName,
                points = points,
                configID = configID,
                treeIDs = treeIDs,
            }
            return activeTalentTreeCache.key, activeTalentTreeCache.name,
                activeTalentTreeCache.points, activeTalentTreeCache.configID
        end
    end

    local getNumTalentTabs = rawget(_G, "GetNumTalentTabs")
    local getTalentTabInfo = rawget(_G, "GetTalentTabInfo")
    if getNumTalentTabs and getTalentTabInfo then
        local bestIndex
        local bestName
        local bestPoints = 0
        for index = 1, getNumTalentTabs() do
            local first, second, third, _, fifth = getTalentTabInfo(index)
            local name
            local pointsSpent
            if type(first) == "number" then
                name = second
                pointsSpent = tonumber(fifth) or tonumber(third) or 0
            else
                name = first
                pointsSpent = tonumber(third) or 0
            end

            if pointsSpent > bestPoints then
                bestIndex = index
                bestName = name
                bestPoints = pointsSpent
            end
        end
        if bestIndex then
            activeTalentTreeCache = {
                key = "TREE_" .. bestIndex,
                name = bestName or ("Talent Tree " .. bestIndex),
                points = bestPoints,
            }
            return activeTalentTreeCache.key, activeTalentTreeCache.name, activeTalentTreeCache.points, nil
        end
    end

    local getSpecialization = rawget(_G, "GetSpecialization")
    local getSpecializationInfo = rawget(_G, "GetSpecializationInfo")
    if getSpecialization and getSpecializationInfo then
        local specialization = getSpecialization()
        if specialization then
            local _, name = getSpecializationInfo(specialization)
            if name then
                activeTalentTreeCache = { key = "SPEC_" .. specialization, name = name, points = nil }
                return activeTalentTreeCache.key, activeTalentTreeCache.name, nil, nil
            end
        end
    end

    return nil, nil
end

local function GetTalentWeightProfile(classFile, contextKey, treeKey)
    local defaults = CLASS_ACTIVITY_DEFAULTS[classFile][contextKey].weights
    local activityProfile = gearDuckWeightsDB.profiles[classFile][contextKey]
    if not treeKey then
        return activityProfile.weights
    end

    activityProfile.talentWeights[treeKey] = EnsureWeightProfile(
        activityProfile.talentWeights[treeKey],
        defaults
    )
    return activityProfile.talentWeights[treeKey]
end

local function GetActivityWeightProfile(classFile, contextKey)
    local defaults = CLASS_ACTIVITY_DEFAULTS[classFile]
    if not defaults or not defaults[contextKey] then
        return nil
    end

    local classProfiles = gearDuckWeightsDB.profiles[classFile]
    if type(classProfiles) ~= "table" then
        classProfiles = {}
        gearDuckWeightsDB.profiles[classFile] = classProfiles
    end

    local profile = classProfiles[contextKey]
    if type(profile) ~= "table" then
        profile = {}
        classProfiles[contextKey] = profile
    end
    profile.weights = EnsureWeightProfile(profile.weights, defaults[contextKey].weights)
    if type(profile.hitCaps) ~= "table" then
        profile.hitCaps = {}
    end
    for _, hitType in ipairs({ "physical", "spell" }) do
        if type(profile.hitCaps[hitType]) ~= "number" then
            profile.hitCaps[hitType] = defaults[contextKey].hitCaps[hitType]
        end
    end
    if type(profile.talentWeights) ~= "table" then
        profile.talentWeights = {}
    end
    return profile
end

local function GetPlayerClassWeights(contextKey)
    local className, classFile
    if UnitClass then
        className, classFile = UnitClass("player")
    end

    if classFile and CLASS_ACTIVITY_DEFAULTS[classFile] then
        local treeKey, treeName, treePoints = GetActiveTalentTree()
        local profile = GetTalentWeightProfile(classFile, contextKey, treeKey)
        return className or classFile, classFile, profile, treeKey, treeName, treePoints
    end

    return "Classic default", "DEFAULT", CLASSIC_DEFAULT_WEIGHTS, nil, nil
end

local function GetWeaponTalentEffects()
    if weaponTalentEffectsCache then
        return weaponTalentEffectsCache
    end

    local bonuses = {}

    local function GetSubclassBonus(subclassID)
        if type(bonuses[subclassID]) ~= "table" then
            bonuses[subclassID] = {
                skill = 0,
                critPercent = 0,
                extraAttackPercent = 0,
                damagePercent = 0,
            }
        end
        return bonuses[subclassID]
    end

    local _, raceFile = UnitRace("player")
    local racialBonuses = RACIAL_WEAPON_SKILL[raceFile]
    if racialBonuses then
        for subclassID, skill in pairs(racialBonuses) do
            GetSubclassBonus(subclassID).skill = skill
        end
    end

    local _, classFile = UnitClass("player")
    local function ApplyTalent(talentName, rank)
        local normalizedTalentName = string.lower(talentName or ""):gsub("%W", "")
        if classFile == "SHAMAN" and normalizedTalentName == "twohandedaxesandmaces" and (tonumber(rank) or 0) > 0 then
            shamanTwoHandedWeaponTalentActive = true
        end

        local classDefinitions = talentName and TALENT_WEAPON_EFFECTS[string.lower(talentName)]
        local definition = classDefinitions and classDefinitions[classFile]
        rank = tonumber(rank) or 0
        if not definition or rank <= 0 then
            return
        end

        local skill = definition.skillRanks and definition.skillRanks[rank]
            or (definition.skillPerRank and definition.skillPerRank * rank)
            or 0
        local critPercent = (definition.critPerRank or 0) * rank
        local extraAttackPercent = (definition.extraAttackPerRank or 0) * rank
        local damagePercent = (definition.damagePerRank or 0) * rank
        for _, subclassID in ipairs(definition.subclasses) do
            local bonus = GetSubclassBonus(subclassID)
            bonus.skill = bonus.skill + skill
            bonus.critPercent = bonus.critPercent + critPercent
            bonus.extraAttackPercent = bonus.extraAttackPercent + extraAttackPercent
            bonus.damagePercent = bonus.damagePercent + damagePercent
        end
    end

    local _, _, _, configID = GetActiveTalentTree()
    local traits = rawget(_G, "C_Traits")
    local getTreeNodes = traits and rawget(traits, "GetTreeNodes")
    local getNodeInfo = traits and rawget(traits, "GetNodeInfo")
    local getEntryInfo = traits and rawget(traits, "GetEntryInfo")
    local getDefinitionInfo = traits and rawget(traits, "GetDefinitionInfo")
    local getSpellInfo = rawget(_G, "GetSpellInfo")
    local scannedModernConfig = false

    if configID and getTreeNodes and getNodeInfo and getEntryInfo and getDefinitionInfo then
        local configInfo = traits.GetConfigInfo(configID)
        for _, treeID in ipairs(configInfo and configInfo.treeIDs or {}) do
            for _, nodeID in ipairs(getTreeNodes(treeID) or {}) do
                local nodeInfo = getNodeInfo(configID, nodeID)
                local activeEntry = nodeInfo and nodeInfo.activeEntry
                local rank = tonumber(activeEntry and activeEntry.rank)
                    or tonumber(nodeInfo and nodeInfo.ranksPurchased)
                    or 0
                local entryID = activeEntry and activeEntry.entryID
                if entryID and rank > 0 then
                    local entryInfo = getEntryInfo(configID, entryID)
                    local definitionInfo = entryInfo and entryInfo.definitionID
                        and getDefinitionInfo(entryInfo.definitionID)
                    local talentName = definitionInfo and definitionInfo.overrideName
                    if not talentName and definitionInfo and definitionInfo.spellID and getSpellInfo then
                        talentName = getSpellInfo(definitionInfo.spellID)
                    end
                    ApplyTalent(talentName, rank)
                end
            end
        end
        scannedModernConfig = true
    end

    local getNumTalentTabs = rawget(_G, "GetNumTalentTabs")
    local getNumTalents = rawget(_G, "GetNumTalents")
    local getTalentInfo = rawget(_G, "GetTalentInfo")
    if not scannedModernConfig and classFile and getNumTalentTabs and getNumTalents and getTalentInfo then
        for tabIndex = 1, getNumTalentTabs() do
            for talentIndex = 1, getNumTalents(tabIndex) do
                local talentName, _, _, _, rank = getTalentInfo(tabIndex, talentIndex)
                ApplyTalent(talentName, rank)
            end
        end
    end

    weaponTalentEffectsCache = bonuses
    return weaponTalentEffectsCache
end

local function GetItemStats(itemLink)
    local fetchStats = (C_Item and rawget(C_Item, "GetItemStats")) or rawget(_G, "GetItemStats")
    if not itemLink or not fetchStats then
        return {}
    end
    return fetchStats(itemLink) or {}
end

local hitTooltipScanner
local function GetItemHitPercent(itemLink)
    if not itemLink then
        return nil
    end
    if itemHitPercentCache[itemLink] ~= nil then
        return itemHitPercentCache[itemLink] or nil
    end

    if not hitTooltipScanner then
        hitTooltipScanner = CreateFrame("GameTooltip", "GearDuckHitTooltipScanner", UIParent, "GameTooltipTemplate")
        hitTooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
    end
    hitTooltipScanner:ClearLines()
    hitTooltipScanner:SetHyperlink(itemLink)

    local hitPercent
    for lineIndex = 1, hitTooltipScanner:NumLines() do
        local line = _G["GearDuckHitTooltipScannerTextLeft" .. lineIndex]
        local text = line and line:GetText()
        if text then
            local normalized = string.lower(text)
            local amount = normalized:match("chance to hit by%s+([%d%.]+)%%")
                or normalized:match("hit chance by%s+([%d%.]+)%%")
            if amount then
                hitPercent = tonumber(amount)
                break
            end
        end
    end
    hitTooltipScanner:Hide()
    if hitPercent then
        itemHitPercentCache[itemLink] = hitPercent
    else
        itemHitPercentCache[itemLink] = false
    end
    return hitPercent
end

local HIT_TALENT_EFFECTS = {
    precision = {
        WARRIOR = { physicalPerRank = 1, maxRanks = 3 },
        PALADIN = { physicalPerRank = 1, spellPerRank = 1, maxRanks = 3 },
        ROGUE = { physicalPerRank = 1, maxRanks = 3 },
    },
    surefooted = { HUNTER = { physicalPerRank = 1, maxRanks = 3 } },
    ["arcane focus"] = { MAGE = { spellPerRank = 2, maxRanks = 5 } },
    ["shadow focus"] = { PRIEST = { spellPerRank = 2, maxRanks = 5 } },
    suppression = { WARLOCK = { spellPerRank = 2, maxRanks = 5 } },
    ["balance of power"] = { DRUID = { spellPerRank = 2, maxRanks = 2 } },
    ["elemental precision"] = { SHAMAN = { spellPerRank = 1, maxRanks = 3 } },
}

local CLASS_HIT_TYPES = {
    WARRIOR = { physical = true },
    PALADIN = { physical = true, spell = true },
    HUNTER = { physical = true },
    ROGUE = { physical = true },
    PRIEST = { spell = true },
    SHAMAN = { physical = true, spell = true },
    MAGE = { spell = true },
    WARLOCK = { spell = true },
    DRUID = { physical = true, spell = true },
}

local function ForEachActiveTalent(callback)
    local _, _, _, configID = GetActiveTalentTree()
    local traits = rawget(_G, "C_Traits")
    local getTreeNodes = traits and rawget(traits, "GetTreeNodes")
    local getNodeInfo = traits and rawget(traits, "GetNodeInfo")
    local getEntryInfo = traits and rawget(traits, "GetEntryInfo")
    local getDefinitionInfo = traits and rawget(traits, "GetDefinitionInfo")
    local scannedModernConfig = false

    if configID and getTreeNodes and getNodeInfo and getEntryInfo and getDefinitionInfo then
        local configInfo = traits.GetConfigInfo(configID)
        for _, treeID in ipairs(configInfo and configInfo.treeIDs or {}) do
            for _, nodeID in ipairs(getTreeNodes(treeID) or {}) do
                local nodeInfo = getNodeInfo(configID, nodeID)
                local activeEntry = nodeInfo and nodeInfo.activeEntry
                local rank = tonumber(activeEntry and activeEntry.rank)
                    or tonumber(nodeInfo and nodeInfo.ranksPurchased)
                    or 0
                local entryID = activeEntry and activeEntry.entryID
                if entryID and rank > 0 then
                    local entryInfo = getEntryInfo(configID, entryID)
                    local definitionInfo = entryInfo and entryInfo.definitionID
                        and getDefinitionInfo(entryInfo.definitionID)
                    local talentName = definitionInfo and definitionInfo.overrideName
                    if not talentName and definitionInfo and definitionInfo.spellID and GetSpellInfo then
                        talentName = GetSpellInfo(definitionInfo.spellID)
                    end
                    callback(talentName, rank)
                end
            end
        end
        scannedModernConfig = true
    end

    local getNumTalentTabs = rawget(_G, "GetNumTalentTabs")
    local getNumTalents = rawget(_G, "GetNumTalents")
    local getTalentInfo = rawget(_G, "GetTalentInfo")
    if not scannedModernConfig and getNumTalentTabs and getNumTalents and getTalentInfo then
        for tabIndex = 1, getNumTalentTabs() do
            for talentIndex = 1, getNumTalents(tabIndex) do
                local talentName, _, _, _, rank = getTalentInfo(tabIndex, talentIndex)
                callback(talentName, rank)
            end
        end
    end
end

local function GetHitTalentBonuses()
    if hitTalentBonusesCache then
        return hitTalentBonusesCache
    end

    local _, classFile = UnitClass("player")
    local bonuses = { physical = 0, spell = 0, dualWield = false }
    ForEachActiveTalent(function(talentName, rank)
        local normalizedName = string.lower(talentName or "")
        rank = tonumber(rank) or 0
        local classEffect = HIT_TALENT_EFFECTS[normalizedName]
            and HIT_TALENT_EFFECTS[normalizedName][classFile]
        if classEffect and rank > 0 then
            bonuses.physical = bonuses.physical
                + math.min(rank, classEffect.maxRanks) * (classEffect.physicalPerRank or 0)
            bonuses.spell = bonuses.spell
                + math.min(rank, classEffect.maxRanks) * (classEffect.spellPerRank or 0)
        end
        if classFile == "SHAMAN" and normalizedName == "dual wield" and rank > 0 then
            bonuses.dualWield = true
        end
    end)
    hitTalentBonusesCache = bonuses
    return bonuses
end

local function GetEffectiveHitCap(classFile, contextKey, activityProfile, dualWielding)
    local caps = activityProfile.hitCaps
    local talentBonuses = GetHitTalentBonuses()
    local hitTypes = CLASS_HIT_TYPES[classFile] or { physical = true }
    local physicalCap = math.max(0, caps.physical - talentBonuses.physical)
    if contextKey == "RAID" and dualWielding then
        physicalCap = math.max(0, math.max(caps.physical, 27) - talentBonuses.physical)
    end
    local spellCap = math.max(0, caps.spell - talentBonuses.spell)
    local effectiveCap = 0
    if hitTypes.physical then
        effectiveCap = math.max(effectiveCap, physicalCap)
    end
    if hitTypes.spell then
        effectiveCap = math.max(effectiveCap, spellCap)
    end
    return effectiveCap
end

local function GetItemMetadata(itemLink)
    local itemID = tonumber(itemLink and itemLink:match("item:(%d+)"))
    local getItemInfo = (C_Item and rawget(C_Item, "GetItemInfo")) or rawget(_G, "GetItemInfo")
    local setID
    if itemLink and getItemInfo then
        local _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, itemSetID = getItemInfo(itemLink)
        setID = tonumber(itemSetID)
    end
    return itemID, setID
end

local function GetItemClassInfo(itemLink)
    local fetchInfo = (C_Item and rawget(C_Item, "GetItemInfoInstant")) or rawget(_G, "GetItemInfoInstant")
    if not itemLink or not fetchInfo then
        return nil, nil
    end
    local _, _, _, _, _, classID, subClassID = fetchInfo(itemLink)
    return classID, subClassID
end

local WEAPON_SUBCLASS_NAMES = {
    [0] = "Axes",
    [1] = "Two-Handed Axes",
    [2] = "Bows",
    [3] = "Guns",
    [4] = "Maces",
    [5] = "Two-Handed Maces",
    [6] = "Polearms",
    [7] = "Swords",
    [8] = "Two-Handed Swords",
    [10] = "Staves",
    [13] = "Fist Weapons",
    [15] = "Daggers",
    [16] = "Thrown Weapons",
    [17] = "Spears",
    [18] = "Crossbows",
    [19] = "Wands",
    [20] = "Fishing Poles",
}

local CLASS_WEAPON_PROFICIENCIES = {
    WARRIOR = {
        [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true,
        [6] = 20, [7] = true, [8] = true, [10] = true, [13] = true, [15] = true,
        [16] = true, [17] = 20, [18] = true, [20] = true,
    },
    PALADIN = {
        [0] = true, [1] = true, [4] = true, [5] = true, [6] = 20, [7] = true,
        [8] = true, [17] = 20, [20] = true,
    },
    HUNTER = {
        [0] = true, [1] = true, [2] = true, [3] = true, [6] = 20, [7] = true,
        [8] = true, [10] = true, [13] = true, [15] = true, [16] = true,
        [17] = 20, [18] = true, [20] = true,
    },
    ROGUE = {
        [2] = true, [3] = true, [4] = true, [7] = true, [13] = true, [15] = true,
        [16] = true, [18] = true, [20] = true,
    },
    PRIEST = { [4] = true, [10] = true, [15] = true, [19] = true, [20] = true },
    SHAMAN = {
        [0] = true, [1] = "talent", [4] = true, [5] = "talent", [10] = true,
        [13] = true, [15] = true, [20] = true,
    },
    MAGE = { [7] = true, [10] = true, [15] = true, [19] = true, [20] = true },
    WARLOCK = { [7] = true, [10] = true, [15] = true, [19] = true, [20] = true },
    DRUID = {
        [4] = true, [5] = true, [6] = 20, [10] = true, [13] = true, [15] = true,
        [17] = 20, [20] = true,
    },
}

local CLASS_ARMOR_PROFICIENCIES = {
    WARRIOR = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true },
    PALADIN = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true },
    HUNTER = { [0] = true, [1] = true, [2] = true, [3] = true, [5] = true },
    ROGUE = { [0] = true, [1] = true, [2] = true, [5] = true },
    PRIEST = { [0] = true, [1] = true, [5] = true },
    SHAMAN = { [0] = true, [1] = true, [2] = true, [3] = true, [5] = true, [6] = true, [9] = true },
    MAGE = { [0] = true, [1] = true, [5] = true },
    WARLOCK = { [0] = true, [1] = true, [5] = true },
    DRUID = { [0] = true, [1] = true, [2] = true, [5] = true, [8] = true },
}

local function CanPlayerEquipItem(itemLink)
    if not itemLink then
        return nil, nil
    end

    local className, classFile = UnitClass("player")
    local classID, subClassID = GetItemClassInfo(itemLink)
    local playerLevel = tonumber(UnitLevel("player")) or 0

    local fetchItemInfo = (C_Item and rawget(C_Item, "GetItemInfo")) or rawget(_G, "GetItemInfo")
    if fetchItemInfo then
        local _, _, _, _, requiredLevel = fetchItemInfo(itemLink)
        requiredLevel = tonumber(requiredLevel)
        if requiredLevel and playerLevel < requiredLevel then
            return false, string.format("Item requires level %d", requiredLevel)
        end
    end

    if classID == 2 then
        local proficiencies = CLASS_WEAPON_PROFICIENCIES[classFile]
        local proficiency = subClassID and proficiencies and proficiencies[subClassID]
        local weaponName = WEAPON_SUBCLASS_NAMES[subClassID] or "this weapon type"
        if proficiency == "talent" then
            GetWeaponTalentEffects()
            if classFile ~= "SHAMAN" or not shamanTwoHandedWeaponTalentActive then
                return false, "Requires the Two-Handed Axes and Maces talent"
            end
        elseif type(proficiency) == "number" and playerLevel < proficiency then
            return false, string.format("%s training requires level %d", weaponName, proficiency)
        elseif not proficiency then
            return false, string.format("%s cannot equip %s", className or "This class", weaponName)
        end
    elseif classID == 4 then
        local proficiencies = CLASS_ARMOR_PROFICIENCIES[classFile]
        if not proficiencies or not proficiencies[subClassID] then
            return false, string.format("%s cannot use this armor type", className or "This class")
        end

        local requiredLevel
        if subClassID == 3 and (classFile == "HUNTER" or classFile == "SHAMAN") then
            requiredLevel = 40
        elseif subClassID == 4 and (classFile == "WARRIOR" or classFile == "PALADIN") then
            requiredLevel = 40
        end
        if requiredLevel and playerLevel < requiredLevel then
            local armorName = subClassID == 3 and "Mail" or "Plate"
            return false, string.format("%s armor requires level %d", armorName, requiredLevel)
        end
    end

    return true, nil
end

local function GetUnenchantedItemLink(itemLink)
    if type(itemLink) ~= "string" then
        return itemLink, nil
    end

    local prefix, itemData, suffix = itemLink:match("^(.-|H)item:([^|]+)(|h.*)$")
    if not prefix then
        return itemLink, nil
    end

    local fields = {}
    for field in (itemData .. ":"):gmatch("(.-):") do
        fields[#fields + 1] = field
    end
    local enchantID = tonumber(fields[2]) or 0
    if enchantID == 0 then
        return itemLink, nil
    end

    fields[2] = "0"
    return prefix .. "item:" .. table.concat(fields, ":") .. suffix, enchantID
end

local function ParseFormatLine(text, formatString)
    if type(text) ~= "string" or type(formatString) ~= "string" then
        return nil
    end

    local pattern = "^"
    local index = 1
    local captures = 0
    while index <= #formatString do
        local character = formatString:sub(index, index)
        if character == "%" then
            if formatString:sub(index + 1, index + 1) == "%" then
                pattern = pattern .. "%%"
                index = index + 2
            else
                local conversionEnd = index + 1
                while conversionEnd <= #formatString and not formatString:sub(conversionEnd, conversionEnd):match("%a") do
                    conversionEnd = conversionEnd + 1
                end
                if conversionEnd > #formatString then
                    return nil
                end
                pattern = pattern .. "([%d%.,]+)"
                captures = captures + 1
                index = conversionEnd + 1
            end
        else
            if string.find("^$().[]*+-?", character, 1, true) then
                pattern = pattern .. "%"
            end
            pattern = pattern .. character
            index = index + 1
        end
    end
    pattern = pattern .. "$"

    local values = { text:match(pattern) }
    if #values ~= captures then
        return nil
    end

    for valueIndex, value in ipairs(values) do
        values[valueIndex] = tonumber((value:gsub(",", ".")))
        if not values[valueIndex] then
            return nil
        end
    end
    return values
end

local function GetWeaponData(itemLink)
    local getHyperlink = C_TooltipInfo and rawget(C_TooltipInfo, "GetHyperlink")
    if not itemLink or not getHyperlink then
        return nil
    end

    local tooltipData = getHyperlink(itemLink)
    if not tooltipData or type(tooltipData.lines) ~= "table" then
        return nil
    end

    local damageFormat = rawget(_G, "DAMAGE_TEMPLATE") or "%s - %s Damage"
    local speedFormat = rawget(_G, "ITEM_SPEED") or "Speed %.2f"
    local minimumDamage
    local maximumDamage
    local speed

    for _, line in ipairs(tooltipData.lines) do
        local text = line.leftText or ""
        local damageValues = ParseFormatLine(text, damageFormat)
        if damageValues and #damageValues >= 2 then
            minimumDamage = damageValues[1]
            maximumDamage = damageValues[2]
        end

        local speedValues = ParseFormatLine(text, speedFormat)
        if speedValues and speedValues[1] then
            speed = speedValues[1]
        end
    end

    if minimumDamage and maximumDamage and speed and speed > 0 then
        return {
            dps = ((minimumDamage + maximumDamage) / 2) / speed,
            speed = speed,
            minimumDamage = minimumDamage,
            maximumDamage = maximumDamage,
        }
    end
    return nil
end

local function ScoreItem(itemLink, weights)
    local stats = GetItemStats(itemLink)
    local score = 0
    local breakdown = {}

    for statName, weight in pairs(weights) do
        if weight ~= 0 then
            local amount = 0
            if statName == "Hit" then
                amount = GetItemHitPercent(itemLink) or 0
            else
                for _, key in ipairs(STAT_KEYS[statName]) do
                    amount = amount + (tonumber(stats[key]) or 0)
                end
            end

            local contribution = amount * weight
            score = score + contribution
            breakdown[statName] = {
                amount = amount,
                weight = weight,
                contribution = contribution,
            }
        end
    end

    local weaponData = GetWeaponData(itemLink)
    if weaponData then
        for statName, value in pairs({ WeaponDPS = weaponData.dps, WeaponSpeed = weaponData.speed }) do
            local weight = weights[statName] or 0
            if weight ~= 0 then
                local contribution = value * weight
                score = score + contribution
                breakdown[statName] = {
                    amount = value,
                    weight = weight,
                    contribution = contribution,
                }
            end
        end
    end

    local itemClassID, weaponSubClassID = GetItemClassInfo(itemLink)
    if itemClassID == 2 and weaponSubClassID then
        local effects = GetWeaponTalentEffects()[weaponSubClassID]
        if effects then
            local effectWeights = {
                WeaponSkill = { effects.skill, weights.WeaponSkill or 0 },
                WeaponCritPercent = { effects.critPercent, weights.WeaponCritPercent or 0 },
                WeaponExtraAttackPercent = { effects.extraAttackPercent, weights.WeaponExtraAttackPercent or 0 },
            }
            for effectName, effect in pairs(effectWeights) do
                local amount, weight = effect[1], effect[2]
                if amount ~= 0 and weight ~= 0 then
                    local contribution = amount * weight
                    score = score + contribution
                    breakdown[effectName] = {
                        amount = amount,
                        weight = weight,
                        contribution = contribution,
                    }
                end
            end

            if effects.damagePercent ~= 0 and weaponData and (weights.WeaponDPS or 0) ~= 0 then
                local dpsIncrease = weaponData.dps * effects.damagePercent / 100
                local contribution = dpsIncrease * weights.WeaponDPS
                score = score + contribution
                breakdown.WeaponDamageTalent = {
                    amount = dpsIncrease,
                    weight = weights.WeaponDPS,
                    contribution = contribution,
                }
            end
        end
    end

    local itemID = GetItemMetadata(itemLink)
    local itemBonus = tonumber(itemID and gearDuckDB.itemBonuses[itemID]) or 0
    if itemBonus ~= 0 then
        score = score + itemBonus
        breakdown.ItemEffectBonus = {
            amount = itemBonus,
            weight = 1,
            contribution = itemBonus,
        }
    end

    local _, enchantID = GetUnenchantedItemLink(itemLink)
    local enchantBonus = tonumber(enchantID and gearDuckDB.enchantBonuses[enchantID]) or 0
    if enchantBonus ~= 0 then
        score = score + enchantBonus
        breakdown.EnchantEffectBonus = {
            amount = enchantBonus,
            weight = 1,
            contribution = enchantBonus,
        }
    end

    return score, breakdown, stats
end

local function GetEquippedSetCounts()
    local counts = {}
    for slot = 1, 19 do
        local itemLink = GetInventoryItemLink("player", slot)
        local _, setID = GetItemMetadata(itemLink)
        if setID then
            counts[setID] = (counts[setID] or 0) + 1
        end
    end
    return counts
end

local function GetSetBonusScore(setID, pieceCount)
    local bonuses = setID and gearDuckDB.setBonuses[setID]
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

local function GetSetBonusDelta(itemSetID, replacedItems, setCounts)
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
        delta = delta + GetSetBonusScore(setID, newCount) - GetSetBonusScore(setID, currentCount)
    end
    return delta
end

local function FormatScore(score)
    if math.abs(score - math.floor(score + 0.5)) < 0.05 then
        return string.format("%d", math.floor(score + 0.5))
    end
    return string.format("%.1f", score)
end

local function FormatPowerLevelLine(profileName, label, delta)
    local status
    local color

    if delta > 0.05 then
        status = "Upgrade"
        color = "|cff00ff00"
    elseif delta < -0.05 then
        status = "Downgrade"
        color = "|cffff4040"
    else
        delta = 0
        status = "Sidegrade"
        color = "|cffffff00"
    end

    local formattedDelta = FormatScore(delta)
    if delta > 0 then
        formattedDelta = "+" .. formattedDelta
    end

    return color .. profileName .. " PL: " .. label .. " " .. formattedDelta .. " (" .. status .. ")|r"
end

local function GetReplacementSlots(itemLink)
    local fetchInfo = (C_Item and rawget(C_Item, "GetItemInfoInstant")) or rawget(_G, "GetItemInfoInstant")
    if not fetchInfo then
        return nil
    end
    local _, _, _, equipLocation = fetchInfo(itemLink)
    local slots = EQUIP_SLOTS[equipLocation]
    if not slots then
        return nil
    end

    return slots, equipLocation == "INVTYPE_2HWEAPON"
end

local function EvaluateItem(itemLink)
    if not itemLink then
        return nil
    end

    local slots, replacesBothWeaponSlots = GetReplacementSlots(itemLink)
    if not slots then
        return nil
    end

    local className, classFile = UnitClass("player")
    local canEquip, equipRestrictionReason = CanPlayerEquipItem(itemLink)
    local itemClassID = GetItemClassInfo(itemLink)
    local unenchantedLink, enchantID = GetUnenchantedItemLink(itemLink)
    local isEnchantedWeapon = itemClassID == 2 and enchantID ~= nil
    local itemID, itemSetID = GetItemMetadata(itemLink)
    local equippedLinks = {}
    local setCounts = GetEquippedSetCounts()
    local equippedHit = 0
    for slot = 1, 19 do
        local equippedLink = GetInventoryItemLink("player", slot)
        equippedLinks[slot] = equippedLink
        equippedHit = equippedHit + (GetItemHitPercent(equippedLink) or 0)
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
            local activityProfile = GetActivityWeightProfile(classFileForContext, context.key)
            local currentItemScore, currentBreakdown, currentItemStats = ScoreItem(itemLink, classWeights)
            local currentItemScoreWithoutEnchant = currentItemScore
            if isEnchantedWeapon then
                currentItemScoreWithoutEnchant = ScoreItem(unenchantedLink, classWeights)
            end
            local dualWielding = false
            if (classFileForContext == "WARRIOR" or classFileForContext == "ROGUE"
                or (classFileForContext == "SHAMAN" and GetHitTalentBonuses().dualWield))
                and equippedLinks[16] and equippedLinks[17] then
                local mainHandClassID = GetItemClassInfo(equippedLinks[16])
                local offHandClassID = GetItemClassInfo(equippedLinks[17])
                dualWielding = mainHandClassID == 2 and offHandClassID == 2
            end
            local hitCap = GetEffectiveHitCap(classFileForContext, context.key, activityProfile, dualWielding)
            hitCaps[context.key] = hitCap

            local contextEquipped = {}
            local slotComparisons = {}
            for _, slot in ipairs(slots) do
                local equippedLink = equippedLinks[slot]
                local score, breakdown, stats = ScoreItem(equippedLink, classWeights)
                local equippedItemID, equippedSetID = GetItemMetadata(equippedLink)
                local equippedItem = {
                    slot = slot,
                    link = equippedLink,
                    itemID = equippedItemID,
                    setID = equippedSetID,
                    score = score,
                    breakdown = breakdown,
                    stats = stats,
                    hitPercent = GetItemHitPercent(equippedLink) or 0,
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
                local setBonusDelta = GetSetBonusDelta(itemSetID, comparison.replacedItems, setCounts)
                local replacementHit = 0
                for _, replacedItem in ipairs(comparison.replacedItems) do
                    replacementHit = replacementHit + (replacedItem.hitPercent or 0)
                end
                local itemHitPercent = GetItemHitPercent(itemLink) or 0
                local cappedHitDelta = math.min(hitCap, math.max(0, equippedHit - replacementHit + itemHitPercent))
                    - math.min(hitCap, math.max(0, equippedHit))
                comparison.delta = currentItemScore - comparison.equippedScore
                    + (cappedHitDelta - (itemHitPercent - replacementHit)) * (classWeights.Hit or 0)
                    + setBonusDelta
                if isEnchantedWeapon then
                    local unenchantedHitPercent = GetItemHitPercent(unenchantedLink) or 0
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

    return {
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
end

local function PrintDebug(evaluation)
    local function Print(message)
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r " .. message)
    end

    Print("Item: " .. evaluation.link)
    Print(string.format("Class profile: %s (%s)", evaluation.className, evaluation.classFile))
    Print("Can equip: " .. (evaluation.canEquip == false and ("No (" .. (evaluation.equipRestrictionReason or "restricted") .. ")") or (evaluation.canEquip == true and "Yes" or "Unknown")))
    local raceName, raceFile = UnitRace("player")
    Print(string.format("Race: %s (%s)", raceName or "Unknown", raceFile or "Unknown"))
    Print("Weighted item score = " .. FormatScore(evaluation.itemScore))

    for statName, result in pairs(evaluation.itemBreakdown) do
        Print(string.format("  %s: %g x %g = %g", statName, result.amount, result.weight, result.contribution))
    end

    Print("Raw item stats:")
    local hasStats = false
    for key, value in pairs(evaluation.itemStats) do
        hasStats = true
        Print(string.format("  %s = %s", key, tostring(value)))
    end
    if not hasStats then
        Print("  (none returned; item data may not be available yet)")
    end

    for _, equipped in ipairs(evaluation.equipped) do
        local slotLabel = EQUIP_SLOT_LABELS[equipped.slot] or ("Slot " .. equipped.slot)
        Print(string.format("Equipped %s: %s (weighted score %s)", slotLabel, equipped.link or "empty", FormatScore(equipped.score)))
    end

    for _, context in ipairs(SCORING_CONTEXT_ORDER) do
        local hitCap = evaluation.hitCaps[context.key]
        if hitCap ~= nil then
            Print(string.format("%s effective hit cap: %s%%", context.name, FormatScore(hitCap)))
        end
    end
    local activeContextProfile
    for _, context in ipairs(SCORING_CONTEXT_ORDER) do
        activeContextProfile = evaluation.contextScores[context.key]
        if activeContextProfile then
            break
        end
    end
    if activeContextProfile and activeContextProfile.treeName then
        Print(string.format("Active talent profile: %s (%s points; %s)", activeContextProfile.treeName, tostring(activeContextProfile.treePoints or "?"), activeContextProfile.treeKey))
    end
    if evaluation.itemSetID then
        Print(string.format("Item set ID: %d", evaluation.itemSetID))
    end
    if evaluation.enchantID then
        Print(string.format("Enchant ID: %d", evaluation.enchantID))
    end

    for _, comparison in ipairs(evaluation.comparisons) do
        Print(string.format("%s PL vs %s: %s - %s = %s", comparison.profileName, comparison.label, FormatScore(comparison.itemScore), FormatScore(comparison.equippedScore), FormatScore(comparison.delta)))
    end
end

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "GearDuck"
    optionsPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText("GearDuck Power Level Profiles")

    local classLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    classLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -54)
    classLabel:SetText("Class profile:")

    local _, playerClassFile = UnitClass("player")
    local selectedClassFile = CLASS_ACTIVITY_DEFAULTS[playerClassFile] and playerClassFile or "ROGUE"
    local activeTreeKey = GetActiveTalentTree()
    local selectedTreeKey = selectedClassFile == playerClassFile and activeTreeKey or nil
    local selectedActivityKey = gearDuckDB.hitCapContext
    if not CLASS_ACTIVITY_DEFAULTS[selectedClassFile][selectedActivityKey] then
        selectedActivityKey = "QUEST"
        gearDuckDB.hitCapContext = selectedActivityKey
    end
    local editBoxes = {}
    local profileCheckboxes = {}
    local physicalHitCapEditBox
    local spellHitCapEditBox
    local activityDropdown
    local scrollFrame
    local refreshPanelOnUpdate = false

    local function FormatWeight(value)
        local formatted = string.format("%.3f", tonumber(value) or 0)
        formatted = formatted:gsub("0+$", "")
        formatted = formatted:gsub("%.$", "")
        return formatted
    end

    local function GetEditBoxValue(editBox)
        if editBox.hitType then
            local activityProfile = GetActivityWeightProfile(
                editBox.profileClass,
                editBox.profileContext
            )
            return activityProfile.hitCaps[editBox.hitType]
        end

        local profile = GetTalentWeightProfile(
            editBox.profileClass,
            editBox.profileContext,
            editBox.profileTree
        )
        return profile[editBox.statName]
    end

    local function SaveEditBox(editBox)
        local value = tonumber(editBox:GetText())
        if editBox.hitType then
            if value and value == value and value >= 0 and value <= 100 then
                GetActivityWeightProfile(
                    editBox.profileClass,
                    editBox.profileContext
                ).hitCaps[editBox.hitType] = value
            end
        elseif value and value == value and math.abs(value) <= 1000 then
            GetTalentWeightProfile(
                editBox.profileClass,
                editBox.profileContext,
                editBox.profileTree
            )[editBox.statName] = value
        end

        editBox:SetText(FormatWeight(GetEditBoxValue(editBox)))
    end

    local function RefreshEditBoxes()
        local defaults = CLASS_ACTIVITY_DEFAULTS[selectedClassFile][selectedActivityKey]
        for _, editBox in ipairs(editBoxes) do
            editBox.profileClass = selectedClassFile
            editBox.profileContext = selectedActivityKey
            editBox.profileTree = selectedTreeKey
            local defaultValue = editBox.hitType
                and defaults.hitCaps[editBox.hitType]
                or defaults.weights[editBox.statName]
            editBox:SetText(FormatWeight(GetEditBoxValue(editBox) or defaultValue))
            editBox:SetCursorPosition(0)
        end
    end

    local function CommitEditBoxes()
        for _, editBox in ipairs(editBoxes) do
            SaveEditBox(editBox)
        end
    end

    local dropdown = CreateFrame("Frame", "GearDuckClassDropdown", panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", panel, "TOPLEFT", 118, -44)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, classInfo in ipairs(CLASS_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = classInfo.name
            info.value = classInfo.file
            info.checked = selectedClassFile == classInfo.file
            info.func = function()
                CommitEditBoxes()
                selectedClassFile = classInfo.file
                local activeKey = GetActiveTalentTree()
                selectedTreeKey = classInfo.file == playerClassFile and activeKey or nil
                UIDropDownMenu_SetSelectedValue(dropdown, selectedClassFile)
                RefreshEditBoxes()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropdown, selectedClassFile)

    local profilesLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profilesLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -84)
    profilesLabel:SetText("Show in tooltips:")

    for index, context in ipairs(SCORING_CONTEXT_ORDER) do
        local contextKey = context.key
        local contextName = context.name
        local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        checkbox:SetSize(24, 24)
        checkbox:SetPoint("TOPLEFT", panel, "TOPLEFT", 142 + (index - 1) * 100, -78)
        local label = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
        label:SetText(contextName)
        checkbox:SetChecked(gearDuckDB.displayContexts[contextKey])
        checkbox:SetScript("OnClick", function(self)
            local checkedCount = 0
            for _, option in ipairs(SCORING_CONTEXT_ORDER) do
                if option.key ~= contextKey and gearDuckDB.displayContexts[option.key] then
                    checkedCount = checkedCount + 1
                end
            end
            if not self:GetChecked() and checkedCount == 0 then
                self:SetChecked(true)
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Select at least one tooltip profile.")
                return
            end

            gearDuckDB.displayContexts[contextKey] = self:GetChecked() == true
            if lastEvaluation then
                lastEvaluation = EvaluateItem(lastEvaluation.link)
            end
        end)
        profileCheckboxes[context.key] = checkbox
    end

    local activityLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    activityLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -114)
    activityLabel:SetText("Edit activity:")

    activityDropdown = CreateFrame("Frame", "GearDuckActivityProfileDropdown", panel, "UIDropDownMenuTemplate")
    activityDropdown:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -104)
    UIDropDownMenu_SetWidth(activityDropdown, 170)
    UIDropDownMenu_Initialize(activityDropdown, function(self, level)
        for _, context in ipairs(SCORING_CONTEXT_ORDER) do
            local contextKey = context.key
            local contextName = context.name
            local info = UIDropDownMenu_CreateInfo()
            info.text = contextName
            info.value = contextKey
            info.checked = selectedActivityKey == contextKey
            info.func = function()
                CommitEditBoxes()
                selectedActivityKey = contextKey
                gearDuckDB.hitCapContext = contextKey
                UIDropDownMenu_SetSelectedValue(activityDropdown, selectedActivityKey)
                UIDropDownMenu_SetText(activityDropdown, contextName)
                RefreshEditBoxes()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetSelectedValue(activityDropdown, selectedActivityKey)
    UIDropDownMenu_SetText(activityDropdown, SCORING_CONTEXTS[selectedActivityKey])

    local physicalHitCapLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    physicalHitCapLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -145)
    physicalHitCapLabel:SetText("Physical hit cap (%):")

    physicalHitCapEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    physicalHitCapEditBox:SetSize(60, 22)
    physicalHitCapEditBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 155, -142)
    physicalHitCapEditBox:SetAutoFocus(false)
    physicalHitCapEditBox:SetTextInsets(5, 5, 0, 0)
    physicalHitCapEditBox:SetScript("OnEnterPressed", function(self)
        SaveEditBox(self)
        RefreshEditBoxes()
        self:ClearFocus()
    end)
    physicalHitCapEditBox:SetScript("OnEditFocusLost", SaveEditBox)
    physicalHitCapEditBox:SetScript("OnEscapePressed", function()
        RefreshEditBoxes()
        physicalHitCapEditBox:ClearFocus()
    end)
    physicalHitCapEditBox.hitType = "physical"
    editBoxes[#editBoxes + 1] = physicalHitCapEditBox

    local spellHitCapLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    spellHitCapLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 250, -145)
    spellHitCapLabel:SetText("Spell hit cap (%):")

    spellHitCapEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    spellHitCapEditBox:SetSize(60, 22)
    spellHitCapEditBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 380, -142)
    spellHitCapEditBox:SetAutoFocus(false)
    spellHitCapEditBox:SetTextInsets(5, 5, 0, 0)
    spellHitCapEditBox:SetScript("OnEnterPressed", function(self)
        SaveEditBox(self)
        RefreshEditBoxes()
        self:ClearFocus()
    end)
    spellHitCapEditBox:SetScript("OnEditFocusLost", SaveEditBox)
    spellHitCapEditBox:SetScript("OnEscapePressed", function()
        RefreshEditBoxes()
        spellHitCapEditBox:ClearFocus()
    end)
    spellHitCapEditBox.hitType = "spell"
    editBoxes[#editBoxes + 1] = spellHitCapEditBox
    RefreshEditBoxes()

    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetSize(150, 24)
    resetButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 460, -142)
    resetButton:SetText("Restore defaults")
    resetButton:SetScript("OnClick", function()
        local defaults = CLASS_ACTIVITY_DEFAULTS[selectedClassFile][selectedActivityKey]
        local profile = GetTalentWeightProfile(
            selectedClassFile,
            selectedActivityKey,
            selectedTreeKey
        )
        for _, statName in ipairs(STAT_ORDER) do
            profile[statName] = defaults.weights[statName] or 0
        end
        local activityProfile = GetActivityWeightProfile(selectedClassFile, selectedActivityKey)
        activityProfile.hitCaps.physical = defaults.hitCaps.physical
        activityProfile.hitCaps.spell = defaults.hitCaps.spell
        RefreshEditBoxes()
    end)

    local helpText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -175)
    helpText:SetWidth(410)
    helpText:SetText("Active talent weights are detected automatically. Hit caps subtract recognized talent bonuses; buffs are not included.")

    scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -206)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -34, 18)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(560, #STAT_ORDER * 30)
    scrollFrame:SetScrollChild(scrollChild)

    for index, statName in ipairs(STAT_ORDER) do
        local rowTop = -((index - 1) * 30)
        local label = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, rowTop - 4)
        label:SetText(STAT_LABELS[statName] or statName)

        local editBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
        editBox:SetSize(90, 22)
        editBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 300, rowTop - 1)
        editBox:SetAutoFocus(false)
        editBox:SetTextInsets(5, 5, 0, 0)
        editBox.statName = statName
        editBox.profileClass = selectedClassFile
        editBox.profileContext = selectedActivityKey
        editBox.profileTree = selectedTreeKey
        editBox:SetScript("OnEnterPressed", function(self)
            SaveEditBox(self)
            self:ClearFocus()
        end)
        editBox:SetScript("OnEditFocusLost", SaveEditBox)
        editBox:SetScript("OnEscapePressed", function(self)
            RefreshEditBoxes()
            self:ClearFocus()
        end)
        editBoxes[#editBoxes + 1] = editBox
    end

    RefreshEditBoxes()
    local settings = rawget(_G, "Settings")
    local registerCanvas = settings and rawget(settings, "RegisterCanvasLayoutCategory")
    local registerAddonCategory = settings and rawget(settings, "RegisterAddOnCategory")
    if registerCanvas and registerAddonCategory then
        optionsCategory = registerCanvas(panel, panel.name)
        registerAddonCategory(optionsCategory)
    else
        optionsCategory = panel
        local registerLegacy = rawget(_G, "InterfaceOptions_AddCategory")
        if registerLegacy then
            registerLegacy(panel)
        end
    end

    local function RefreshOptionsPanel()
        local activeKey = GetActiveTalentTree()
        selectedTreeKey = selectedClassFile == playerClassFile and activeKey or nil
        selectedActivityKey = gearDuckDB.hitCapContext
        if not CLASS_ACTIVITY_DEFAULTS[selectedClassFile][selectedActivityKey] then
            selectedActivityKey = "QUEST"
            gearDuckDB.hitCapContext = selectedActivityKey
        end
        for _, context in ipairs(SCORING_CONTEXT_ORDER) do
            profileCheckboxes[context.key]:SetChecked(gearDuckDB.displayContexts[context.key])
        end
        UIDropDownMenu_SetSelectedValue(activityDropdown, selectedActivityKey)
        UIDropDownMenu_SetText(activityDropdown, SCORING_CONTEXTS[selectedActivityKey] or "Unknown")
        UIDropDownMenu_SetSelectedValue(dropdown, selectedClassFile)
        for _, classInfo in ipairs(CLASS_OPTIONS) do
            if classInfo.file == selectedClassFile then
                UIDropDownMenu_SetText(dropdown, classInfo.name)
                break
            end
        end

        RefreshEditBoxes()
    end
    panel.RefreshGearDuckOptions = RefreshOptionsPanel

    panel:HookScript("OnShow", function()
        refreshPanelOnUpdate = true
    end)
    panel:SetScript("OnUpdate", function(self)
        if refreshPanelOnUpdate and self:IsVisible() and self:GetWidth() > 0 then
            refreshPanelOnUpdate = false
            RefreshOptionsPanel()
        end
    end)
end

CreateOptionsPanel()

local playerBuildFrame = CreateFrame("Frame")
playerBuildFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerBuildFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
playerBuildFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
playerBuildFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
playerBuildFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
playerBuildFrame:SetScript("OnEvent", function()
    activeTalentTreeCache = nil
    activeTalentTreeScanned = false
    weaponTalentEffectsCache = nil
    hitTalentBonusesCache = nil
    shamanTwoHandedWeaponTalentActive = false
    if optionsPanel and optionsPanel:IsShown() and optionsPanel.RefreshGearDuckOptions then
        optionsPanel:RefreshGearDuckOptions()
    end
end)

local function GetTooltipItemLink(tooltip, data)
    local itemLink = data and data.hyperlink
    if not itemLink and tooltip and tooltip.GetItem then
        local _, tooltipItemLink = tooltip:GetItem()
        itemLink = tooltipItemLink
    end
    if not itemLink and data and tonumber(data.id) then
        itemLink = "item:" .. tostring(data.id)
    end
    return itemLink
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    if tooltip == hitTooltipScanner then
        return
    end

    local itemLink = GetTooltipItemLink(tooltip, data)
    local evaluation = EvaluateItem(itemLink)

    if evaluation then
        lastEvaluation = evaluation
        lastTooltip = tooltip
        if evaluation.canEquip == false then
            local reason = evaluation.equipRestrictionReason
            tooltip:AddLine("|cffff4040Cannot Use" .. (reason and (": " .. reason) or "") .. "|r")
            tooltip:Show()
            return
        end

        for _, comparison in ipairs(evaluation.comparisons) do
            if evaluation.isEnchantedWeapon then
                tooltip:AddLine(FormatPowerLevelLine(comparison.profileName, comparison.label .. " (without enchant)", comparison.deltaWithoutEnchant))
                tooltip:AddLine(FormatPowerLevelLine(comparison.profileName, comparison.label .. " (with enchant)", comparison.delta))
            else
                tooltip:AddLine(FormatPowerLevelLine(comparison.profileName, comparison.label, comparison.delta))
            end
        end
        tooltip:Show()
    end
end)

SLASH_GEARDUCK1 = "/gearduck"
SLASH_GEARDUCK2 = "/gd"
local function PrintHelp()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck commands:|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd help|r - Show this command list.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd debug|r - Print the hovered item's stats and Power Level math.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd options|r - Open GearDuck's AddOns settings panel.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd profile <raid|quest|pvp>|r - Show only the selected profile.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd hitcap <value>|r - Set both hit caps for the selected class/activity.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd hitcap <physical|spell> <value>|r - Set one hit cap as a percentage.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd itembonus <value|clear>|r - Set/clear the hovered item's manual effect score.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd enchantbonus <value|clear>|r - Set/clear a proc-only bonus for the hovered enchant.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd setbonus <pieces> <value|clear>|r - Set/clear a hovered set's threshold score.")
    DEFAULT_CHAT_FRAME:AddMessage("Use |cffffff00/gearduck|r as an alias for |cffffff00/gd|r.")
end

local function OpenOptionsPanel()
    local settings = rawget(_G, "Settings")
    local openToCategory = settings and rawget(settings, "OpenToCategory")
    if openToCategory and optionsCategory and optionsCategory.GetID then
        openToCategory(optionsCategory:GetID())
        return true
    end

    local openLegacy = rawget(_G, "InterfaceOptionsFrame_OpenToCategory")
    if openLegacy and optionsPanel then
        openLegacy(optionsPanel)
        return true
    end

    return false
end

local function RefreshLastEvaluation()
    if lastEvaluation then
        lastEvaluation = EvaluateItem(lastEvaluation.link)
    end
end

local function GetVisibleTooltipEvaluation()
    local tooltips = {}
    if lastTooltip then
        tooltips[#tooltips + 1] = lastTooltip
    end

    local gameTooltip = rawget(_G, "GameTooltip")
    if gameTooltip and gameTooltip ~= lastTooltip then
        tooltips[#tooltips + 1] = gameTooltip
    end
    local itemRefTooltip = rawget(_G, "ItemRefTooltip")
    if itemRefTooltip and itemRefTooltip ~= lastTooltip and itemRefTooltip ~= gameTooltip then
        tooltips[#tooltips + 1] = itemRefTooltip
    end

    for _, tooltip in ipairs(tooltips) do
        if tooltip.IsShown and tooltip:IsShown() and tooltip.GetItem then
            local _, itemLink = tooltip:GetItem()
            local evaluation = EvaluateItem(itemLink)
            if evaluation then
                return evaluation
            end
        end
    end
    return nil
end

SlashCmdList.GEARDUCK = function(message)
    local command = string.lower(message or "")
    command = command:match("^%s*(.-)%s*$") or ""

    if command == "debug" then
        local evaluation = GetVisibleTooltipEvaluation() or lastEvaluation
        if evaluation then
            lastEvaluation = evaluation
            PrintDebug(evaluation)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hover an item first, then run /gd debug.")
        end
        return
    end

    if command == "options" then
        if not OpenOptionsPanel() then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Could not open the AddOns settings panel.")
        end
        return
    end

    local profileName = command:match("^profile%s+(%a+)$")
    if profileName then
        local profileKey = string.upper(profileName)
        if SCORING_CONTEXTS[profileKey] then
            for _, context in ipairs(SCORING_CONTEXT_ORDER) do
                gearDuckDB.displayContexts[context.key] = context.key == profileKey
            end
            if optionsPanel and optionsPanel.RefreshGearDuckOptions then
                optionsPanel:RefreshGearDuckOptions()
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Showing only the " .. SCORING_CONTEXTS[profileKey] .. " profile.")
            RefreshLastEvaluation()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Choose raid, quest, or pvp.")
        end
        return
    end

    local hitCapType, typedHitCapValue = command:match("^hitcap%s+(%a+)%s+([%+%-]?[%d%.]+)$")
    if hitCapType ~= "physical" and hitCapType ~= "spell" then
        hitCapType = nil
        typedHitCapValue = nil
    end
    local legacyHitCapValue = command:match("^hitcap%s+([%+%-]?[%d%.]+)$")
    local hitCapValue = typedHitCapValue or legacyHitCapValue
    if hitCapValue then
        local value = tonumber(hitCapValue)
        if value and value >= 0 and value <= 100 then
            local _, classFile = UnitClass("player")
            local contextKey = gearDuckDB.hitCapContext
            local hitCaps = gearDuckWeightsDB.profiles[classFile][contextKey].hitCaps
            if hitCapType then
                hitCaps[hitCapType] = value
            else
                hitCaps.physical = value
                hitCaps.spell = value
            end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r %s %s hit cap set to %s%%.", SCORING_CONTEXTS[contextKey], hitCapType or "physical and spell", value))
            RefreshLastEvaluation()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hit cap must be between 0 and 100 percent.")
        end
        return
    end

    local itemBonusValue = command:match("^itembonus%s+([%w%+%-%.]+)$")
    if itemBonusValue then
        if not lastEvaluation or not lastEvaluation.itemID then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hover an item first, then set its effect bonus.")
            return
        end
        if itemBonusValue == "clear" then
            gearDuckDB.itemBonuses[lastEvaluation.itemID] = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Cleared the hovered item's manual effect bonus.")
        else
            local value = tonumber(itemBonusValue)
            if not value or math.abs(value) > 100000 then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Item bonus must be between -100000 and 100000.")
                return
            end
            gearDuckDB.itemBonuses[lastEvaluation.itemID] = value
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Item %d effect bonus set to %s Power Level.", lastEvaluation.itemID, value))
        end
        RefreshLastEvaluation()
        return
    end

    local enchantBonusValue = command:match("^enchantbonus%s+([%w%+%-%.]+)$")
    if enchantBonusValue then
        local enchantID = tonumber(lastEvaluation and lastEvaluation.enchantID)
        if not enchantID then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hover an enchanted weapon first.")
            return
        end
        if enchantBonusValue == "clear" then
            gearDuckDB.enchantBonuses[enchantID] = nil
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Cleared enchant %d's manual bonus.", enchantID))
        else
            local value = tonumber(enchantBonusValue)
            if not value or math.abs(value) > 100000 then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Enchant bonus must be between -100000 and 100000.")
                return
            end
            gearDuckDB.enchantBonuses[enchantID] = value
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Enchant %d bonus set to %s Power Level.", enchantID, value))
        end
        RefreshLastEvaluation()
        return
    end

    local setPieces, setBonusValue = command:match("^setbonus%s+(%d+)%s+([%w%+%-%.]+)$")
    if setPieces and setBonusValue then
        local threshold = tonumber(setPieces)
        local setID = tonumber(lastEvaluation and lastEvaluation.itemSetID)
        if not setID then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hover an item from a set first. Use /gd debug to see its set ID.")
            return
        end
        if not threshold or threshold < 2 or threshold > 20 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Set threshold must be between 2 and 20 pieces.")
            return
        end
        local bonuses = gearDuckDB.setBonuses[setID] or {}
        if setBonusValue == "clear" then
            bonuses[threshold] = nil
            gearDuckDB.setBonuses[setID] = bonuses
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Cleared set %d's %d-piece bonus.", setID, threshold))
        else
            local value = tonumber(setBonusValue)
            if not value or math.abs(value) > 100000 then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Set bonus must be between -100000 and 100000.")
                return
            end
            bonuses[threshold] = value
            gearDuckDB.setBonuses[setID] = bonuses
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Set %d's %d-piece bonus set to %s Power Level.", setID, threshold, value))
        end
        RefreshLastEvaluation()
        return
    end

    PrintHelp()
end

local loaderFrame = CreateFrame("Frame")
loaderFrame:RegisterEvent("ADDON_LOADED")
loaderFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "GearDuck" then -- Replace with your exact AddOn folder name if different
        local savedDB = rawget(_G, "GearDuckDB")
        if type(savedDB) == "table" then
            gearDuckDB = savedDB
            
            gearDuckDB.weights = gearDuckDB.weights or {}
            gearDuckDB.talentWeights = gearDuckDB.talentWeights or {}
            gearDuckDB.itemBonuses = gearDuckDB.itemBonuses or {}
            gearDuckDB.enchantBonuses = gearDuckDB.enchantBonuses or {}
            gearDuckDB.setBonuses = gearDuckDB.setBonuses or {}
            EnsureContextSettings(gearDuckDB)

            if not gearDuckWeightsDB.legacyMigrationComplete then
                MigrateLegacyWeightProfiles(gearDuckDB, gearDuckWeightsDB)
                gearDuckWeightsDB.legacyMigrationComplete = true
            end
            gearDuckDB.weights = {}
            gearDuckDB.talentWeights = {}
            gearDuckDB.hitCaps = {}
            gearDuckWeightsDB = EnsureActivityWeightProfiles(gearDuckDB)
            rawset(_G, "GearDuckDB", gearDuckDB)
            if optionsPanel and optionsPanel:IsShown() and optionsPanel.RefreshGearDuckOptions then
                optionsPanel:RefreshGearDuckOptions()
            end
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)