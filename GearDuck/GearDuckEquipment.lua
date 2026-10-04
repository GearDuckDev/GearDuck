local _, addon = ...
local equipment = {}

addon.equipment = equipment

local data = addon.data
local talents = addon.talents
local weaponTalentEffectsCache
local shamanTwoHandedWeaponTalentActive = false

function equipment.ResetTalentCache()
    weaponTalentEffectsCache = nil
    shamanTwoHandedWeaponTalentActive = false
end

function equipment.GetWeaponTalentEffects()
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
    local racialBonuses = data.RACIAL_WEAPON_SKILL[raceFile]
    if racialBonuses then
        for subclassID, skill in pairs(racialBonuses) do
            GetSubclassBonus(subclassID).skill = skill
        end
    end

    local _, classFile = UnitClass("player")
    talents.ForEachActiveTalent(function(talentName, rank)
        local normalizedTalentName = string.lower(talentName or ""):gsub("%W", "")
        if classFile == "SHAMAN" and normalizedTalentName == "twohandedaxesandmaces" and (tonumber(rank) or 0) > 0 then
            shamanTwoHandedWeaponTalentActive = true
        end

        local classDefinitions = talentName and data.TALENT_WEAPON_EFFECTS[string.lower(talentName)]
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
    end)

    weaponTalentEffectsCache = bonuses
    return weaponTalentEffectsCache
end

function equipment.GetItemClassInfo(itemLink)
    local fetchInfo = (C_Item and rawget(C_Item, "GetItemInfoInstant")) or rawget(_G, "GetItemInfoInstant")
    if not itemLink or not fetchInfo then
        return nil, nil
    end
    local _, _, _, _, _, classID, subClassID = fetchInfo(itemLink)
    return classID, subClassID
end

function equipment.CanPlayerEquipItem(itemLink)
    if not itemLink then
        return nil, nil
    end

    local className, classFile = UnitClass("player")
    local classID, subClassID = equipment.GetItemClassInfo(itemLink)
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
        local proficiencies = data.CLASS_WEAPON_PROFICIENCIES[classFile]
        local proficiency = subClassID and proficiencies and proficiencies[subClassID]
        local weaponName = data.WEAPON_SUBCLASS_NAMES[subClassID] or "this weapon type"
        if proficiency == "talent" then
            equipment.GetWeaponTalentEffects()
            if classFile ~= "SHAMAN" or not shamanTwoHandedWeaponTalentActive then
                return false, "Requires the Two-Handed Axes and Maces talent"
            end
        elseif type(proficiency) == "number" and playerLevel < proficiency then
            return false, string.format("%s training requires level %d", weaponName, proficiency)
        elseif not proficiency then
            return false, string.format("%s cannot equip %s", className or "This class", weaponName)
        end
    elseif classID == 4 then
        local proficiencies = data.CLASS_ARMOR_PROFICIENCIES[classFile]
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
