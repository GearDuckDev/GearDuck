local _, addon = ...
local scoring = {}

addon.scoring = scoring

local data = addon.data
local hit = addon.hit
local equipment = addon.equipment
local items = addon.items

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

    local itemClassID, weaponSubClassID = equipment.GetItemClassInfo(itemLink)
    local weaponData = itemClassID == 2 and items.GetWeaponData(itemLink) or nil
    if weaponData then
        local dpsWeight = weights.WeaponDPS or 0
        if dpsWeight ~= 0 then
            local contribution = weaponData.dps * dpsWeight
            score = score + contribution
            breakdown.WeaponDPS = {
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

            local dpsWeight = weights.WeaponDPS or 0
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
