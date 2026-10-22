local _, addon = ...
local equipment = {}

addon.equipment = equipment

local data = addon.data
local talents = addon.talents
local weaponTalentEffectsCache
local shamanTwoHandedWeaponTalentActive = false
local shamanDualWieldTalentActive = false

function equipment.ResetTalentCache()
    weaponTalentEffectsCache = nil
    shamanTwoHandedWeaponTalentActive = false
    shamanDualWieldTalentActive = false
end

function equipment.GetWeaponTalentEffects()
    if weaponTalentEffectsCache then
        return weaponTalentEffectsCache
    end

    local bonuses = {}
    shamanTwoHandedWeaponTalentActive = false
    shamanDualWieldTalentActive = false

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
    local scanned = talents.ForEachActiveTalent(function(talentName, rank)
        local normalizedTalentName = string.lower(talentName or ""):gsub("%W", "")
        local numericRank = tonumber(rank) or 0
        if classFile == "SHAMAN" and numericRank > 0 then
            if normalizedTalentName == "twohandedaxesandmaces" then
                shamanTwoHandedWeaponTalentActive = true
            elseif normalizedTalentName == "dualwield" then
                shamanDualWieldTalentActive = true
            end
        end

        local classDefinitions = talentName and data.TALENT_WEAPON_EFFECTS[string.lower(talentName)]
        local definition = classDefinitions and classDefinitions[classFile]
        if not definition or numericRank <= 0 then
            return
        end

        local skill = definition.skillRanks and definition.skillRanks[numericRank]
            or (definition.skillPerRank and definition.skillPerRank * numericRank)
            or 0
        local critPercent = (definition.critPerRank or 0) * numericRank
        local extraAttackPercent = (definition.extraAttackPerRank or 0) * numericRank
        local damagePercent = (definition.damagePerRank or 0) * numericRank
        for _, subclassID in ipairs(definition.subclasses) do
            local bonus = GetSubclassBonus(subclassID)
            bonus.skill = bonus.skill + skill
            bonus.critPercent = bonus.critPercent + critPercent
            bonus.extraAttackPercent = bonus.extraAttackPercent + extraAttackPercent
            bonus.damagePercent = bonus.damagePercent + damagePercent
        end
    end)

    if scanned then
        weaponTalentEffectsCache = bonuses
    end
    return bonuses
end

function equipment.CanPlayerDualWield()
    local _, classFile = UnitClass("player")
    local playerLevel = tonumber(UnitLevel and UnitLevel("player")) or 60
    if classFile == "ROGUE" then
        return playerLevel >= 10
    elseif classFile == "WARRIOR" or classFile == "HUNTER" then
        return playerLevel >= 20
    elseif classFile == "SHAMAN" then
        equipment.GetWeaponTalentEffects()
        return shamanDualWieldTalentActive == true
    elseif classFile == "PALADIN"
        or classFile == "PRIEST"
        or classFile == "MAGE"
        or classFile == "WARLOCK"
        or classFile == "DRUID" then
        return false
    end
    return true
end

function equipment.GetItemClassInfo(itemLink)
    local fetchInfo = (C_Item and rawget(C_Item, "GetItemInfoInstant")) or rawget(_G, "GetItemInfoInstant")
    if not itemLink or not fetchInfo then
        return nil, nil, nil
    end
    local _, _, _, equipLocation, _, classID, subClassID = fetchInfo(itemLink)
    return classID, subClassID, equipLocation
end

local function CheckItemClassRestriction(itemLink, className, classFile)
    local getHyperlink = C_TooltipInfo and rawget(C_TooltipInfo, "GetHyperlink")
    if not getHyperlink then
        return true, nil
    end

    local tooltipData = getHyperlink(itemLink)
    if not tooltipData or type(tooltipData.lines) ~= "table" or #tooltipData.lines == 0 then
        return nil, "Item class restrictions are not loaded yet"
    end

    local classFormat = rawget(_G, "ITEM_CLASSES_ALLOWED") or "Classes: %s"
    local classPattern = "^" .. classFormat:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
        :gsub("%%%%s", "(.+)") .. "$"
    local maleClasses = rawget(_G, "LOCALIZED_CLASS_NAMES_MALE")
    local femaleClasses = rawget(_G, "LOCALIZED_CLASS_NAMES_FEMALE")
    for _, line in ipairs(tooltipData.lines) do
        local text = line.leftText
        if type(text) == "string" then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local allowedClasses = text:match(classPattern)
            if allowedClasses then
                for allowedClass in allowedClasses:gmatch("[^,]+") do
                    allowedClass = allowedClass:match("^%s*(.-)%s*$")
                    if allowedClass == className
                        or (maleClasses and allowedClass == maleClasses[classFile])
                        or (femaleClasses and allowedClass == femaleClasses[classFile]) then
                        return true, nil
                    end
                end
                return false, text
            end
        end
    end
    return true, nil
end

function equipment.CanPlayerEquipItem(itemLink)
    if not itemLink then
        return nil, nil
    end

    local className, classFile = UnitClass("player")
    local classID, subClassID, equipLocation = equipment.GetItemClassInfo(itemLink)
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

        if equipLocation == "INVTYPE_WEAPONOFFHAND" and not equipment.CanPlayerDualWield() then
            if classFile == "SHAMAN" then
                return false, "Requires the Dual Wield talent"
            elseif classFile == "ROGUE" then
                return false, "Dual Wield requires level 10"
            elseif classFile == "WARRIOR" or classFile == "HUNTER" then
                return false, "Dual Wield requires level 20"
            end
            return false, string.format("%s cannot dual-wield", className or "This class")
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

    return CheckItemClassRestriction(itemLink, className, classFile)
end
