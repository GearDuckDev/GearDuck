local _, addon = ...
local data = addon.data
local profiles = {}

addon.profiles = profiles

local function CopyWeights(weights)
    local copy = {}
    for statName, weight in pairs(weights) do
        copy[statName] = weight
    end
    return copy
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

function profiles.NormalizeDatabase(database)
    if type(database) ~= "table" then
        database = {}
    end
    if type(database.weights) ~= "table" then
        database.weights = {}
    end
    if type(database.talentWeights) ~= "table" then
        database.talentWeights = {}
    end
    if type(database.itemBonuses) ~= "table" then
        database.itemBonuses = {}
    end
    if type(database.enchantBonuses) ~= "table" then
        database.enchantBonuses = {}
    end
    if type(database.setBonuses) ~= "table" then
        database.setBonuses = {}
    end

    EnsureUpgradeArrowSetting(database)
    EnsureContextSettings(database)
    rawset(_G, "GearDuckDB", database)
    return database
end

function profiles.EnsureActivityWeightProfiles(legacyDatabase)
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
            profile.weights = profiles.EnsureWeightProfile(profile.weights, defaults.weights)

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
                profile.talentWeights[treeKey] = profiles.EnsureWeightProfile(treeProfile, defaults.weights)
            end
        end
    end

    rawset(_G, "GearDuckWeightsDB", weightDatabase)
    return weightDatabase
end

function profiles.GetTalentWeightProfile(weightDatabase, classFile, contextKey, treeKey)
    local activityProfile = weightDatabase.profiles[classFile][contextKey]
    if not treeKey then
        return activityProfile.weights
    end

    local defaults = data.CLASS_ACTIVITY_DEFAULTS[classFile][contextKey].weights
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
                            profiles.EnsureWeightProfile(CopyWeights(treeWeights), defaults.weights)
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
