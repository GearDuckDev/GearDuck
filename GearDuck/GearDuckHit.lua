local _, addon = ...
local hit = {}

addon.hit = hit

local talents = addon.talents
local data = addon.data
local hitTalentBonusesCache
local itemHitPercentCache = {}
local hitTooltipScanner

function hit.IsScannerTooltip(tooltip)
    return tooltip == hitTooltipScanner
end

function hit.ResetTalentCache()
    hitTalentBonusesCache = nil
end

function hit.GetItemHitPercent(itemLink)
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

function hit.GetTalentBonuses()
    if hitTalentBonusesCache then
        return hitTalentBonusesCache
    end

    local _, classFile = UnitClass("player")
    local bonuses = { physical = 0, spell = 0, dualWield = false }
    talents.ForEachActiveTalent(function(talentName, rank)
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
    hitTalentBonusesCache = bonuses
    return bonuses
end

function hit.GetEffectiveHitCap(classFile, contextKey, activityProfile, dualWielding)
    local caps = activityProfile.hitCaps
    local talentBonuses = hit.GetTalentBonuses()
    local hitTypes = data.CLASS_HIT_TYPES[classFile] or { physical = true }
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
