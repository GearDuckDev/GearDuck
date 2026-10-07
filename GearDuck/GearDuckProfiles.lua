local _, addon = ...
local data = addon.data
local profiles = {}

addon.profiles = profiles

-- Older SavedVariables contain class-only defaults; this tracks the preset migration.
local WEIGHT_DEFAULTS_VERSION = 1

local function CopyWeights(weights)
    local copy = {}
    for statName, weight in pairs(weights) do
        copy[statName] = weight
    end
    return copy
end

local function GetTalentDefaults(classFile, contextKey, treeKey)
    local classDefaults = data.CLASS_TALENT_DEFAULTS[classFile]
    local contextDefaults = classDefaults and classDefaults[contextKey]
    return (contextDefaults and contextDefaults[treeKey])
        or data.CLASS_ACTIVITY_DEFAULTS[classFile][contextKey].weights
end

function profiles.EnsureWeightProfile(profile, defaults)
    if type(profile) ~= "table" then
        profile = {}
    end

    for statName in pairs(data.STAT_KEYS) do
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
    for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
        if type(database.hitCaps[context.key]) ~= "number" then
            database.hitCaps[context.key] = 0
        end
    end

    if type(database.displayContexts) ~= "table" then
        database.displayContexts = {}
        for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
            database.displayContexts[context.key] = context.key == "QUEST"
        end
    else
        local hasDisplayedContext = false
        for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
            database.displayContexts[context.key] = database.displayContexts[context.key] == true
            hasDisplayedContext = hasDisplayedContext or database.displayContexts[context.key]
        end
        if not hasDisplayedContext then
            database.displayContexts.QUEST = true
        end
    end

    if not data.SCORING_CONTEXTS[database.hitCapContext] then
        database.hitCapContext = "QUEST"
    end
end

local function EnsureUpgradeArrowSetting(database)
    if database.upgradeArrowDefaultApplied ~= true then
        database.showUpgradeArrows = true
        database.upgradeArrowDefaultApplied = true
    elseif type(database.showUpgradeArrows) ~= "boolean" then
        database.showUpgradeArrows = true
    end
end

local SHARED_DATABASE_KEYS = { itemBonuses = true, enchantBonuses = true, setBonuses = true }

function profiles.NormalizeDatabase(database, isCharacterDatabase)
    if type(database) ~= "table" then
        database = {}
    end
    if type(database.weights) ~= "table" then
        database.weights = {}
    end
    if type(database.talentWeights) ~= "table" then
        database.talentWeights = {}
    end
    if not isCharacterDatabase then
        for key in pairs(SHARED_DATABASE_KEYS) do
            if type(database[key]) ~= "table" then
                database[key] = {}
            end
        end
    end

    EnsureUpgradeArrowSetting(database)
    EnsureContextSettings(database)
    if not isCharacterDatabase then
        if type(database.characters) ~= "table" then
            database.characters = {}
        end
        rawset(_G, "GearDuckDB", database)
    end
    return database
end

function profiles.GetCharacterKey()
    local name = UnitName and UnitName("player")
    local realm = GetRealmName and GetRealmName()
    return string.format("%s-%s", tostring(name or "Unknown"), tostring(realm or "Unknown"))
end

-- Settings and weights are per character; item/enchant/set bonuses stay shared through the root database.
function profiles.GetCharacterDatabases(rootDatabase, rootWeightDatabase, characterKey)
    if type(rootWeightDatabase) ~= "table" then
        rootWeightDatabase = {}
    end
    if type(rootWeightDatabase.characters) ~= "table" then
        rootWeightDatabase.characters = {}
    end
    if type(rootDatabase.characters) ~= "table" then
        rootDatabase.characters = {}
    end

    local database = rootDatabase.characters[characterKey]
    if type(database) ~= "table" then
        database = {}
        rootDatabase.characters[characterKey] = database
    end
    for key in pairs(SHARED_DATABASE_KEYS) do
        database[key] = nil
    end
    profiles.NormalizeDatabase(database, true)
    setmetatable(database, {
        __index = function(_, key)
            if SHARED_DATABASE_KEYS[key] then
                return rootDatabase[key]
            end
        end,
    })

    local state = database.onboarding
    if type(state) ~= "table" then
        state = {}
        database.onboarding = state
    end
    state.completed = state.completed == true
    if type(state.contexts) ~= "table" then
        state.contexts = {}
    end
    if state.weightMode ~= "default" and state.weightMode ~= "custom" then
        state.weightMode = nil
    end
    if type(state.arrows) ~= "boolean" then
        state.arrows = nil
    end
    if type(state.page) ~= "number" then
        state.page = nil
    end

    local weightDatabase = rootWeightDatabase.characters[characterKey]
    if type(weightDatabase) ~= "table" then
        weightDatabase = {}
        rootWeightDatabase.characters[characterKey] = weightDatabase
    end
    profiles.EnsureActivityWeightProfiles(database, weightDatabase)
    return database, weightDatabase, rootWeightDatabase
end

function profiles.ResetWeightsToDefaults(weightDatabase)
    weightDatabase.profiles = {}
    for classFile, contextDefaults in pairs(data.CLASS_ACTIVITY_DEFAULTS) do
        weightDatabase.profiles[classFile] = {}
        for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
            local defaults = contextDefaults[context.key]
            weightDatabase.profiles[classFile][context.key] = {
                weights = profiles.EnsureWeightProfile(CopyWeights(defaults.weights), defaults.weights),
                hitCaps = {
                    physical = defaults.hitCaps.physical,
                    spell = defaults.hitCaps.spell,
                },
                talentWeights = {},
            }
        end
    end
end

function profiles.EnsureActivityWeightProfiles(legacyDatabase, characterWeightDatabase)
    local weightDatabase = characterWeightDatabase or rawget(_G, "GearDuckWeightsDB")
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

    for classFile, contextDefaults in pairs(data.CLASS_ACTIVITY_DEFAULTS) do
        if type(weightDatabase.profiles[classFile]) ~= "table" then
            weightDatabase.profiles[classFile] = {}
        end
        for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
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
            if profile.weightDefaultsVersion ~= WEIGHT_DEFAULTS_VERSION then
                local oldDefaults = data.CLASS_WEIGHTS[classFile]
                for statName in pairs(data.STAT_KEYS) do
                    if type(profile.weights[statName]) == "number"
                        and profile.weights[statName] == (oldDefaults[statName] or 0) then
                        profile.weights[statName] = defaults.weights[statName] or 0
                    end
                end
            end
            profile.weights = profiles.EnsureWeightProfile(profile.weights, defaults.weights)
            profile.weightDefaultsVersion = WEIGHT_DEFAULTS_VERSION

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

            local migrateTalentDefaults = profile.talentDefaultsVersion ~= WEIGHT_DEFAULTS_VERSION
            for treeKey, treeProfile in pairs(profile.talentWeights) do
                if type(treeProfile) ~= "table" then
                    treeProfile = {}
                end
                local treeDefaults = GetTalentDefaults(classFile, contextKey, treeKey)
                if migrateTalentDefaults then
                    local oldDefaults = data.CLASS_WEIGHTS[classFile]
                    for statName in pairs(data.STAT_KEYS) do
                        if type(treeProfile[statName]) == "number"
                            and treeProfile[statName] == (oldDefaults[statName] or 0) then
                            treeProfile[statName] = treeDefaults[statName] or 0
                        end
                    end
                end
                profile.talentWeights[treeKey] = profiles.EnsureWeightProfile(
                    treeProfile,
                    treeDefaults
                )
            end
            profile.talentDefaultsVersion = WEIGHT_DEFAULTS_VERSION
        end
    end

    if not characterWeightDatabase then
        rawset(_G, "GearDuckWeightsDB", weightDatabase)
    end
    return weightDatabase
end

function profiles.GetTalentWeightProfile(weightDatabase, classFile, contextKey, treeKey)
    local activityProfile = weightDatabase.profiles[classFile][contextKey]
    if not treeKey then
        return activityProfile.weights
    end

    local defaults = GetTalentDefaults(classFile, contextKey, treeKey)
    activityProfile.talentWeights[treeKey] = profiles.EnsureWeightProfile(
        activityProfile.talentWeights[treeKey],
        defaults
    )
    return activityProfile.talentWeights[treeKey]
end

function profiles.GetActivityWeightProfile(weightDatabase, classFile, contextKey)
    local defaults = data.CLASS_ACTIVITY_DEFAULTS[classFile]
    if not defaults or not defaults[contextKey] then
        return nil
    end

    local classProfiles = weightDatabase.profiles[classFile]
    if type(classProfiles) ~= "table" then
        classProfiles = {}
        weightDatabase.profiles[classFile] = classProfiles
    end

    local profile = classProfiles[contextKey]
    if type(profile) ~= "table" then
        profile = {}
        classProfiles[contextKey] = profile
    end
    profile.weights = profiles.EnsureWeightProfile(profile.weights, defaults[contextKey].weights)
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

function profiles.MigrateLegacyWeightProfiles(legacyDatabase, weightDatabase)
    local legacyWeights = type(legacyDatabase.weights) == "table" and legacyDatabase.weights or {}
    local legacyTalentWeights = type(legacyDatabase.talentWeights) == "table"
        and legacyDatabase.talentWeights or {}
    local legacyHitCaps = type(legacyDatabase.hitCaps) == "table" and legacyDatabase.hitCaps or {}

    for classFile, contextDefaults in pairs(data.CLASS_ACTIVITY_DEFAULTS) do
        local legacyClassWeights = legacyWeights[classFile]
        local legacyClassTalentWeights = legacyTalentWeights[classFile]
        for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
            local profile = weightDatabase.profiles[classFile][context.key]
            local defaults = contextDefaults[context.key]
            if type(legacyClassWeights) == "table" then
                profile.weights = profiles.EnsureWeightProfile(CopyWeights(legacyClassWeights), defaults.weights)
            end
            if type(legacyClassTalentWeights) == "table" then
                for treeKey, treeWeights in pairs(legacyClassTalentWeights) do
                    if type(treeWeights) == "table" then
                        profile.talentWeights[treeKey] =
                            profiles.EnsureWeightProfile(
                                CopyWeights(treeWeights),
                                GetTalentDefaults(classFile, context.key, treeKey)
                            )
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
