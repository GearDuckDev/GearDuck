local _, addon = ...
local sets = {}

addon.sets = sets

local items = addon.items

local PRIMARY_STATS = { "Strength", "Agility", "Stamina", "Intellect", "Spirit" }
local ATTACK_POWER_LABELS = {
    AttackPower = { key = "ITEM_MOD_ATTACK_POWER_SHORT", fallback = "Attack Power" },
    RangedAttackPower = { key = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", fallback = "Ranged Attack Power" },
}
local EFFECT_FORMATS = {
    Armor = { "Increases armor by %d." },
    AttackPower = { "Increases attack power by %d.", "Increases your attack power by %d." },
    RangedAttackPower = { "Increases ranged attack power by %d." },
    SpellPower = { "Increases damage and healing done by magical spells and effects by up to %d." },
    Healing = { "Increases healing done by spells and effects by up to %d." },
    ManaRegen = { "Restores %d mana per 5 sec." },
    Defense = { "Increased Defense +%d." },
    Hit = { "Improves your chance to hit by %d%%.", "Increases your chance to hit by %d%%." },
    Crit = { "Improves your chance to get a critical strike by %d%%." },
    Dodge = { "Increases your chance to dodge an attack by %d%%." },
    Parry = { "Increases your chance to parry an attack by %d%%." },
}

local function ParseBonusStats(text)
    text = text:match("^%s*(.-)%s*$"):gsub("%.$", "")
    for index, statName in ipairs(PRIMARY_STATS) do
        local label = rawget(_G, "SPELL_STAT" .. index .. "_NAME") or statName
        local values = items.MatchFormatLine(text, "%d " .. label)
        if values then
            local amount = tonumber(values[1])
            return amount and { [statName] = amount } or nil
        end
    end
    for statName, label in pairs(ATTACK_POWER_LABELS) do
        local values = items.MatchFormatLine(text, "%d " .. (rawget(_G, label.key) or label.fallback))
        if values then
            local amount = tonumber(values[1])
            return amount and { [statName] = amount } or nil
        end
    end
    local armor = items.MatchFormatLine(text, rawget(_G, "ARMOR_TEMPLATE") or "%s Armor")
    if armor and tonumber(armor[1]) then
        return { Armor = tonumber(armor[1]) }
    end
    for statName, formats in pairs(EFFECT_FORMATS) do
        for _, formatString in ipairs(formats) do
            local values = items.MatchFormatLine(text, (formatString:gsub("%.$", "")))
            if values then
                local amount = tonumber(values[1])
                return amount and { [statName] = amount } or nil
            end
        end
    end
    return nil
end

local function ResolveLearnedThreshold(learned, text)
    local match
    for threshold, descriptions in pairs(learned) do
        if type(descriptions) == "table" and tonumber(threshold) then
            for _, description in ipairs(descriptions) do
                if description == text then
                    if match and match ~= tonumber(threshold) then
                        return nil
                    end
                    match = tonumber(threshold)
                end
            end
        end
    end
    return match
end

function sets.GetItemSetBonuses(itemLink, database)
    local getHyperlink = C_TooltipInfo and rawget(C_TooltipInfo, "GetHyperlink")
    local tooltipData = itemLink and getHyperlink and getHyperlink(itemLink)
    local bonuses = {}
    if not tooltipData or type(tooltipData.lines) ~= "table" then
        return bonuses, false
    end
    local _, setID = items.GetItemMetadata(itemLink)
    local savedThresholds = database and database.setBonusThresholds
    local learned = savedThresholds and setID and savedThresholds[setID] or {}
    if type(learned) ~= "table" then
        learned = {}
    end
    local numbered = {}
    for _, line in ipairs(tooltipData.lines) do
        local threshold, text = items.GetSetBonusLine(line.leftText)
        if threshold then
            numbered[threshold] = numbered[threshold] or {}
            numbered[threshold][#numbered[threshold] + 1] = text
        end
    end
    for threshold, descriptions in pairs(numbered) do
        learned[threshold] = descriptions
    end
    if savedThresholds and setID and next(numbered) then
        savedThresholds[setID] = learned
    end
    local unresolved = false
    for _, line in ipairs(tooltipData.lines) do
        local threshold, text = items.GetSetBonusLine(line.leftText)
        if text and not threshold then
            threshold = ResolveLearnedThreshold(learned, text)
            if not threshold then
                unresolved = true
            end
        end
        if threshold then
            local stats = ParseBonusStats(text)
            local existing = bonuses[threshold]
            if existing then
                existing.text = existing.text .. " / " .. text
                if existing.stats and stats then
                    for statName, amount in pairs(stats) do
                        existing.stats[statName] = (existing.stats[statName] or 0) + amount
                    end
                else
                    existing.stats = nil
                end
            else
                bonuses[threshold] = { stats = stats, text = text }
            end
        end
    end
    return bonuses, not unresolved and next(bonuses) ~= nil
end

function sets.GetEquippedSetCounts()
    local counts = {}
    for slot = 1, 19 do
        local itemLink = GetInventoryItemLink("player", slot)
        local _, setID = items.GetItemMetadata(itemLink)
        if setID then
            counts[setID] = (counts[setID] or 0) + 1
        end
    end
    return counts
end

local function GetManualBonus(database, setID, threshold)
    local bonuses = database.setBonuses[setID]
    if type(bonuses) == "table" then
        local value = bonuses[threshold]
        if value == nil then
            value = bonuses[tostring(threshold)]
        end
        return tonumber(value)
    end
end

function sets.GetActiveSetHit(database, setCounts, setBonuses)
    local hit = 0
    for setID, count in pairs(setCounts) do
        for threshold, bonus in pairs(setBonuses[setID] or {}) do
            if count >= threshold and bonus.stats and GetManualBonus(database, setID, threshold) == nil then
                hit = hit + (bonus.stats.Hit or 0)
            end
        end
    end
    return hit
end

function sets.GetSetBonusDelta(database, itemSetID, replacedItems, setCounts, weights, setBonuses)
    weights = weights or {}
    setBonuses = setBonuses or {}
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
    local hitDelta = 0
    local unscored = {}
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
        local thresholds = {}
        for threshold in pairs(setBonuses[setID] or {}) do
            thresholds[threshold] = true
        end
        for threshold in pairs(database.setBonuses[setID] or {}) do
            if tonumber(threshold) then
                thresholds[tonumber(threshold)] = true
            end
        end
        for threshold in pairs(thresholds) do
            local change = (newCount >= threshold and 1 or 0) - (currentCount >= threshold and 1 or 0)
            if change ~= 0 then
                local manual = GetManualBonus(database, setID, threshold)
                local bonus = setBonuses[setID] and setBonuses[setID][threshold]
                if manual ~= nil then
                    delta = delta + change * manual
                elseif bonus and bonus.stats then
                    for statName, amount in pairs(bonus.stats) do
                        if statName == "Hit" then
                            hitDelta = hitDelta + change * amount
                        else
                            delta = delta + change * amount * (weights[statName] or 0)
                        end
                    end
                elseif bonus then
                    unscored[#unscored + 1] = { setID = setID, threshold = threshold, text = bonus.text }
                end
            end
        end
    end
    return delta, hitDelta, unscored
end
