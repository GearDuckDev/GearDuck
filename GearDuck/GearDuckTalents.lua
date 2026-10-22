local _, addon = ...
local talents = {}

addon.talents = talents

local activeTalentTreeCache
local activeTalentTreeScanned = false

function talents.ResetActiveTalentTreeCache()
    activeTalentTreeCache = nil
    activeTalentTreeScanned = false
end

function talents.GetActiveTalentTree()
    if activeTalentTreeScanned then
        return activeTalentTreeCache and activeTalentTreeCache.key,
            activeTalentTreeCache and activeTalentTreeCache.name,
            activeTalentTreeCache and activeTalentTreeCache.points,
            activeTalentTreeCache and activeTalentTreeCache.configID
    end

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
            activeTalentTreeScanned = true
            return activeTalentTreeCache.key, activeTalentTreeCache.name,
                activeTalentTreeCache.points, activeTalentTreeCache.configID
        end
    end

    local getNumTalentTabs = rawget(_G, "GetNumTalentTabs")
    local getTalentTabInfo = rawget(_G, "GetTalentTabInfo")
    if getNumTalentTabs and getTalentTabInfo then
        local numTabs = getNumTalentTabs() or 0
        local bestIndex
        local bestName
        local bestPoints = 0
        for index = 1, numTabs do
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
            activeTalentTreeScanned = true
            return activeTalentTreeCache.key, activeTalentTreeCache.name, activeTalentTreeCache.points, nil
        end
        local playerLevel = tonumber(UnitLevel and UnitLevel("player")) or 0
        if numTabs > 0 and playerLevel > 0 and playerLevel < 10 then
            activeTalentTreeScanned = true
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
                activeTalentTreeScanned = true
                return activeTalentTreeCache.key, activeTalentTreeCache.name, nil, nil
            end
        end
    end

    if not getActiveConfigID and not getNumTalentTabs and not getSpecialization then
        activeTalentTreeScanned = true
    end

    return nil, nil
end

function talents.ForEachActiveTalent(callback)
    local _, _, _, configID = talents.GetActiveTalentTree()
    local traits = rawget(_G, "C_Traits")
    local getTreeNodes = traits and rawget(traits, "GetTreeNodes")
    local getNodeInfo = traits and rawget(traits, "GetNodeInfo")
    local getEntryInfo = traits and rawget(traits, "GetEntryInfo")
    local getDefinitionInfo = traits and rawget(traits, "GetDefinitionInfo")
    local getSpellInfo = rawget(_G, "GetSpellInfo")

    if configID and getTreeNodes and getNodeInfo and getEntryInfo and getDefinitionInfo then
        local configInfo = traits.GetConfigInfo(configID)
        local treeIDs = configInfo and configInfo.treeIDs or {}
        if #treeIDs > 0 then
            for _, treeID in ipairs(treeIDs) do
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
                        callback(talentName, rank)
                    end
                end
            end
            return true
        end
    end

    local getNumTalentTabs = rawget(_G, "GetNumTalentTabs")
    local getNumTalents = rawget(_G, "GetNumTalents")
    local getTalentInfo = rawget(_G, "GetTalentInfo")
    if getNumTalentTabs and getNumTalents and getTalentInfo then
        local numTabs = getNumTalentTabs() or 0
        if numTabs <= 0 then
            return false
        end
        for tabIndex = 1, numTabs do
            for talentIndex = 1, getNumTalents(tabIndex) do
                local talentName, _, _, _, rank = getTalentInfo(tabIndex, talentIndex)
                callback(talentName, rank)
            end
        end
        return true
    end

    return true
end
