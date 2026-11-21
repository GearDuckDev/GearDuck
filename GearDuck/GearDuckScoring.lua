local _, addon = ...
local scoring = {}

addon.scoring = scoring

local data = addon.data
local hit = addon.hit
local equipment = addon.equipment
local items = addon.items
local warnedExpertiseFallback = false
local dpsKeys = {
    INVTYPE_RANGED = "RangedWeaponDPS", INVTYPE_RANGEDRIGHT = "RangedWeaponDPS",
    INVTYPE_THROWN = "RangedWeaponDPS", INVTYPE_WEAPON = "WeaponDPS",
    INVTYPE_2HWEAPON = "WeaponDPS", INVTYPE_WEAPONMAINHAND = "WeaponDPS",
    INVTYPE_WEAPONOFFHAND = "WeaponDPS",
}

local function ExpertiseRatingToPercent(rating)
    if rating == 0 then return 0 end
    local convert = rawget(_G, "GetCombatRatingBonusForCombatRatingValue")
    local result = convert and convert(rawget(_G, "CR_EXPERTISE") or 24, rating)
    if type(result) == "number" and result ~= 0 then return result end
    if not warnedExpertiseFallback then
        warnedExpertiseFallback = true
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Expertise rating conversion unavailable; using 10 rating per 1%.")
        end
    end
    return rating / 10
end

local function AddStatContribution(breakdown, statName, amount, weight)
    if amount == 0 or weight == 0 then
        return 0
    end
    local contribution = amount * weight
    breakdown[statName] = {
        amount = amount,
        weight = weight,
        contribution = contribution,
    }
    return contribution
end

function scoring.ScoreItem(database, itemLink, weights, precomputedStats)
    if not itemLink then
        return 0, {}, {}
    end

    local stats = precomputedStats or items.GetItemStats(itemLink)
    local score = 0
    local breakdown = {}

    for statName, weight in pairs(weights) do
        if weight ~= 0 then
            local amount = 0
            if statName == "Hit" then
                amount = hit.GetItemHitPercent(itemLink) or 0
            elseif statName == "Expertise" then
                local extra = items.GetExtraStats(itemLink)
                if extra and extra.expertise ~= 0 then
                    amount = extra.expertise
                else
                    amount = ExpertiseRatingToPercent(tonumber(stats.ITEM_MOD_EXPERTISE_RATING_SHORT) or 0)
                end
            elseif statName == "Haste" then
                for _, key in ipairs(data.STAT_KEYS.Haste) do
                    if stats[key] ~= nil then
                        amount = tonumber(stats[key]) or 0
                        break
                    end
                end
            else
                local statKeys = data.STAT_KEYS[statName]
                if statKeys then
                    for _, key in ipairs(statKeys) do
                        amount = amount + (tonumber(stats[key]) or 0)
                    end
                end
            end

            local contribution = amount * weight
            score = score + contribution
            breakdown[statName] = {
                amount = amount,
                weight = weight,
                contribution = contribution,
            }
        end
    end

    score = score + AddStatContribution(
        breakdown, "SpellPowerHealing", tonumber(stats.ITEM_MOD_SPELL_POWER_SHORT) or 0, weights.Healing or 0
    )

    local itemClassID, weaponSubClassID, equipLoc = equipment.GetItemClassInfo(itemLink)
    local weaponData = itemClassID == 2 and items.GetWeaponData(itemLink) or nil
    local dpsKey = dpsKeys[equipLoc]
    local dpsWeight = dpsKey and (weights[dpsKey] or 0) or 0
    if weaponData then
        if dpsWeight ~= 0 then
            local contribution = weaponData.dps * dpsWeight
            score = score + contribution
            breakdown[dpsKey] = {
                amount = weaponData.dps,
                weight = dpsWeight,
                contribution = contribution,
            }
        end
        local speedWeight = weights.WeaponSpeed or 0
        if speedWeight ~= 0 then
            local contribution = weaponData.speed * speedWeight
            score = score + contribution
            breakdown.WeaponSpeed = {
                amount = weaponData.speed,
                weight = speedWeight,
                contribution = contribution,
            }
        end
    end

    if itemClassID == 2 and weaponSubClassID then
        local effects = equipment.GetWeaponTalentEffects()[weaponSubClassID]
        if effects then
            score = score + AddStatContribution(breakdown, "WeaponSkill", effects.skill, weights.WeaponSkill or 0)
            score = score + AddStatContribution(breakdown, "WeaponCritPercent", effects.critPercent, weights.WeaponCritPercent or 0)
            score = score + AddStatContribution(breakdown, "WeaponExtraAttackPercent", effects.extraAttackPercent, weights.WeaponExtraAttackPercent or 0)

            if effects.damagePercent ~= 0 and weaponData and dpsWeight ~= 0 then
                local dpsIncrease = weaponData.dps * effects.damagePercent / 100
                local contribution = dpsIncrease * dpsWeight
                score = score + contribution
                breakdown.WeaponDamageTalent = {
                    amount = dpsIncrease,
                    weight = dpsWeight,
                    contribution = contribution,
                }
            end
        end
    end

    local itemID = items.GetItemMetadata(itemLink)
    local itemBonus = tonumber(itemID and database.itemBonuses[itemID]) or 0
    if itemBonus ~= 0 then
        score = score + itemBonus
        breakdown.ItemEffectBonus = {
            amount = itemBonus,
            weight = 1,
            contribution = itemBonus,
        }
    end

    local _, enchantID = items.GetUnenchantedItemLink(itemLink)
    if enchantID and enchantID ~= "" then
        local enchantBonus = database.enchantBonuses[enchantID] or 0
        if enchantBonus ~= 0 then
            score = score + enchantBonus
            breakdown.EnchantEffectBonus = {
                amount = enchantBonus,
                weight = 1,
                contribution = enchantBonus,
            }
        end
    end

    return score, breakdown, stats
end
