local _, addon = ...
local items = {}

addon.items = items

local data = addon.data
local formatPatternCache = {}
local weaponDataCache = {}
local unenchantedLinkCache = {}
local MAIN_HAND_ONLY_SLOTS = { 16 }

function items.ClearCache()
    wipe(weaponDataCache)
    wipe(unenchantedLinkCache)
end

function items.IsItemInfoLoaded(itemLink)
    if not itemLink then
        return false
    end
    local getItemInfo = (C_Item and rawget(C_Item, "GetItemInfo")) or rawget(_G, "GetItemInfo")
    if not getItemInfo then
        return true
    end
    return getItemInfo(itemLink) ~= nil
end

function items.GetItemStats(itemLink)
    local fetchStats = (C_Item and rawget(C_Item, "GetItemStats")) or rawget(_G, "GetItemStats")
    if not itemLink or not fetchStats then
        return {}
    end
    return fetchStats(itemLink) or {}
end

function items.GetItemMetadata(itemLink)
    local itemID = tonumber(itemLink and itemLink:match("item:(%d+)"))
    local getItemInfo = (C_Item and rawget(C_Item, "GetItemInfo")) or rawget(_G, "GetItemInfo")
    local setID
    if itemLink and getItemInfo then
        local _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, itemSetID = getItemInfo(itemLink)
        setID = tonumber(itemSetID)
    end
    return itemID, setID
end

function items.GetUnenchantedItemLink(itemLink)
    if type(itemLink) ~= "string" then
        return itemLink, nil
    end

    local cached = unenchantedLinkCache[itemLink]
    if cached then
        return cached.link, cached.enchantID
    end

    local prefix, itemData, suffix = itemLink:match("^(.-|H)item:([^|]+)(|h.*)$")
    if not prefix then
        unenchantedLinkCache[itemLink] = { link = itemLink, enchantID = nil }
        return itemLink, nil
    end

    local fields = {}
    for field in (itemData .. ":"):gmatch("(.-):") do
        fields[#fields + 1] = field
    end
    local enchantID = tonumber(fields[2]) or 0
    if enchantID == 0 then
        unenchantedLinkCache[itemLink] = { link = itemLink, enchantID = nil }
        return itemLink, nil
    end

    fields[2] = "0"
    local unenchanted = prefix .. "item:" .. table.concat(fields, ":") .. suffix
    unenchantedLinkCache[itemLink] = { link = unenchanted, enchantID = enchantID }
    return unenchanted, enchantID
end

local function GetCompiledFormatPattern(formatString)
    local cached = formatPatternCache[formatString]
    if cached ~= nil then
        return cached or nil
    end

    local parts = { "^" }
    local index = 1
    local captures = 0
    while index <= #formatString do
        local character = formatString:sub(index, index)
        if character == "%" then
            if formatString:sub(index + 1, index + 1) == "%" then
                parts[#parts + 1] = "%%"
                index = index + 2
            else
                local conversionEnd = index + 1
                while conversionEnd <= #formatString and not formatString:sub(conversionEnd, conversionEnd):match("%a") do
                    conversionEnd = conversionEnd + 1
                end
                if conversionEnd > #formatString then
                    formatPatternCache[formatString] = false
                    return nil
                end
                parts[#parts + 1] = "([%d%.,]+)"
                captures = captures + 1
                index = conversionEnd + 1
            end
        else
            if string.find("^$().[]*+-?", character, 1, true) then
                parts[#parts + 1] = "%"
            end
            parts[#parts + 1] = character
            index = index + 1
        end
    end
    parts[#parts + 1] = "$"

    local compiled = {
        pattern = table.concat(parts),
        captures = captures,
    }
    formatPatternCache[formatString] = compiled
    return compiled
end

local function ParseFormatLine(text, formatString)
    if type(text) ~= "string" or type(formatString) ~= "string" or text == "" then
        return nil
    end

    local compiled = GetCompiledFormatPattern(formatString)
    if not compiled then
        return nil
    end

    local values = { text:match(compiled.pattern) }
    if #values ~= compiled.captures then
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

function items.GetWeaponData(itemLink)
    if not itemLink then
        return nil
    end
    if weaponDataCache[itemLink] ~= nil then
        return weaponDataCache[itemLink] or nil
    end

    if addon.equipment and addon.equipment.GetItemClassInfo then
        local classID = addon.equipment.GetItemClassInfo(itemLink)
        if classID and classID ~= 2 then
            weaponDataCache[itemLink] = false
            return nil
        end
    end

    local getHyperlink = C_TooltipInfo and rawget(C_TooltipInfo, "GetHyperlink")
    if not getHyperlink then
        return nil
    end

    local tooltipData = getHyperlink(itemLink)
    if not tooltipData or type(tooltipData.lines) ~= "table" then
        return nil
    end

    local damageFormat = rawget(_G, "DAMAGE_TEMPLATE") or "%s - %s Damage"
    local singleDamageFormat = rawget(_G, "SINGLE_DAMAGE_TEMPLATE") or "%s Damage"
    local speedLabel = rawget(_G, "SPEED") or "Speed"
    local speedFormat = rawget(_G, "ITEM_SPEED") or (speedLabel .. " %.2f")
    local minimumDamage
    local maximumDamage
    local speed

    for _, line in ipairs(tooltipData.lines) do
        local leftText = line.leftText or ""
        local rightText = line.rightText or ""

        if not minimumDamage then
            local damageValues = ParseFormatLine(leftText, damageFormat)
            if damageValues and #damageValues >= 2 then
                minimumDamage = damageValues[1]
                maximumDamage = damageValues[2]
            else
                local singleValues = ParseFormatLine(leftText, singleDamageFormat)
                if singleValues and singleValues[1] then
                    minimumDamage = singleValues[1]
                    maximumDamage = singleValues[1]
                end
            end
        end

        if not speed then
            local speedValues = ParseFormatLine(rightText, speedFormat) or ParseFormatLine(leftText, speedFormat)
            if speedValues and speedValues[1] then
                speed = speedValues[1]
            end
        end
    end

    if minimumDamage and maximumDamage and speed and speed > 0 then
        local weaponData = {
            dps = ((minimumDamage + maximumDamage) / 2) / speed,
            speed = speed,
            minimumDamage = minimumDamage,
            maximumDamage = maximumDamage,
        }
        weaponDataCache[itemLink] = weaponData
        return weaponData
    end

    if items.IsItemInfoLoaded(itemLink) and #tooltipData.lines > 0 then
        weaponDataCache[itemLink] = false
    end
    return nil
end

function items.GetReplacementSlots(itemLink)
    local fetchInfo = (C_Item and rawget(C_Item, "GetItemInfoInstant")) or rawget(_G, "GetItemInfoInstant")
    if not itemLink or not fetchInfo then
        return nil
    end
    local _, _, _, equipLocation = fetchInfo(itemLink)
    local slots = data.EQUIP_SLOTS[equipLocation]
    if not slots then
        return nil
    end

    if equipLocation == "INVTYPE_WEAPON"
        and addon.equipment
        and addon.equipment.CanPlayerDualWield
        and not addon.equipment.CanPlayerDualWield() then
        return MAIN_HAND_ONLY_SLOTS, false
    end

    return slots, equipLocation == "INVTYPE_2HWEAPON"
end
