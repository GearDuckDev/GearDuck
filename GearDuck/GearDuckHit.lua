local _, addon = ...
local hit = {}

addon.hit = hit

local talents = addon.talents
local data = addon.data
local hitTalentBonusesCache
local itemHitPercentCache = {}
local hitTooltipScanner

function hit.IsScannerTooltip(tooltip)
    return tooltip ~= nil and tooltip == hitTooltipScanner
end

function hit.ClearItemCache()
    wipe(itemHitPercentCache)
end

function hit.ResetTalentCache()
    hitTalentBonusesCache = nil
end

local function ParseHitLine(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end
    local normalized = string.lower(text)
    local amount = normalized:match("chance to hit.-by%s+([%d%.]+)%%")
        or normalized:match("hit chance.-by%s+([%d%.]+)%%")
        or normalized:match("^%+([%d%.]+)%%%s*hit")
        or normalized:match("^%+([%d%.]+)%%%s*spell hit")
        or normalized:match("^hit%s*%+([%d%.]+)%%")
    return amount and tonumber(amount) or nil
end

function hit.GetItemHitPercent(itemLink)
    if not itemLink then
        return nil
    end
    if itemHitPercentCache[itemLink] ~= nil then
        return itemHitPercentCache[itemLink] or nil
    end

    local totalHit = 0
    local scannedTooltip = false
    local getHyperlink = C_TooltipInfo and rawget(C_TooltipInfo, "GetHyperlink")
    if getHyperlink then
        local tooltipData = getHyperlink(itemLink)
        if tooltipData and type(tooltipData.lines) == "table" and #tooltipData.lines > 0 then
            scannedTooltip = true
            for _, line in ipairs(tooltipData.lines) do
                local amount = ParseHitLine(line.leftText)
                if amount then
                    totalHit = totalHit + amount
                end
            end
        end
    end

    if not scannedTooltip then
        if not hitTooltipScanner then
            hitTooltipScanner = CreateFrame("GameTooltip", "GearDuckHitTooltipScanner", UIParent, "GameTooltipTemplate")
            hitTooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
        end
        hitTooltipScanner:ClearLines()
        hitTooltipScanner:SetHyperlink(itemLink)

        for lineIndex = 1, hitTooltipScanner:NumLines() do
            local line = _G["GearDuckHitTooltipScannerTextLeft" .. lineIndex]
            local text = line and line:GetText()
            local amount = ParseHitLine(text)
            if amount then
                totalHit = totalHit + amount
            end
        end
        hitTooltipScanner:Hide()
    end

    if totalHit <= 0 and addon.items and addon.items.GetItemStats then
        local stats = addon.items.GetItemStats(itemLink)
        for _, key in ipairs(data.STAT_KEYS.Hit) do
            totalHit = totalHit + (tonumber(stats[key]) or 0)
        end
    end

    if totalHit > 0 then
        itemHitPercentCache[itemLink] = totalHit
        return totalHit
    end

    if not addon.items or not addon.items.IsItemInfoLoaded or addon.items.IsItemInfoLoaded(itemLink) then
        itemHitPercentCache[itemLink] = false
    end
    return nil
end

function hit.GetTalentBonuses()
    if hitTalentBonusesCache then
        return hitTalentBonusesCache
    end

    local _, classFile = UnitClass("player")
    local bonuses = { physical = 0, spell = 0, dualWield = false }
    local scanned = talents.ForEachActiveTalent(function(talentName, rank)
        local normalizedName = string.lower(talentName or "")
        rank = tonumber(rank) or 0
        local classEffect = data.HIT_TALENT_EFFECTS[normalizedName]
            and data.HIT_TALENT_EFFECTS[normalizedName][classFile]
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
    if scanned then
        hitTalentBonusesCache = bonuses
    end
    return bonuses
end

function hit.GetEffectiveHitCap(classFile, contextKey, activityProfile, dualWielding, weights)
    local caps = activityProfile.hitCaps
    local talentBonuses = hit.GetTalentBonuses()
    local hitTypes = data.CLASS_HIT_TYPES[classFile] or { physical = true }
    local physicalCap = math.max(0, caps.physical - talentBonuses.physical)
    if contextKey == "RAID" and dualWielding then
        physicalCap = math.max(0, math.max(caps.physical, 27) - talentBonuses.physical)
    end
    local spellCap = math.max(0, caps.spell - talentBonuses.spell)

    if hitTypes.physical and hitTypes.spell and type(weights) == "table" then
        local physicalWeight = (weights.Strength or 0)
            + (weights.Agility or 0)
            + (weights.AttackPower or 0)
            + (weights.RangedAttackPower or 0)
        local spellWeight = (weights.SpellPower or 0) + (weights.Healing or 0)
        if physicalWeight > 0 or spellWeight > 0 then
            if spellWeight > physicalWeight then
                return spellCap
            end
            return physicalCap
        end
    end

    local effectiveCap = 0
    if hitTypes.physical then
        effectiveCap = math.max(effectiveCap, physicalCap)
    end
    if hitTypes.spell then
        effectiveCap = math.max(effectiveCap, spellCap)
    end
    return effectiveCap
end
