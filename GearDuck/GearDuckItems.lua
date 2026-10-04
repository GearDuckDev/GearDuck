local _, addon = ...
local items = {}

addon.items = items

local data = addon.data

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

function items.GetWeaponData(itemLink)
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

function items.GetReplacementSlots(itemLink)
    local fetchInfo = (C_Item and rawget(C_Item, "GetItemInfoInstant")) or rawget(_G, "GetItemInfoInstant")
    if not fetchInfo then
        return nil
    end
    local _, _, _, equipLocation = fetchInfo(itemLink)
    local slots = data.EQUIP_SLOTS[equipLocation]
    if not slots then
        return nil
    end

    return slots, equipLocation == "INVTYPE_2HWEAPON"
end
