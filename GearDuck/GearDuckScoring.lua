local _, addon = ...
local scoring = {}

addon.scoring = scoring

local data = addon.data
local hit = addon.hit
local equipment = addon.equipment
local items = addon.items

function scoring.ScoreItem(database, itemLink, weights)
    local stats = items.GetItemStats(itemLink)
    local score = 0
    local breakdown = {}

    for statName, weight in pairs(weights) do
        if weight ~= 0 then
            local amount = 0
            if statName == "Hit" then
                amount = hit.GetItemHitPercent(itemLink) or 0
            else
                for _, key in ipairs(data.STAT_KEYS[statName]) do
                    amount = amount + (tonumber(stats[key]) or 0)
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

    local weaponData = items.GetWeaponData(itemLink)
    if weaponData then
        for statName, value in pairs({ WeaponDPS = weaponData.dps, WeaponSpeed = weaponData.speed }) do
            local weight = weights[statName] or 0
            if weight ~= 0 then
                local contribution = value * weight
                score = score + contribution
                breakdown[statName] = {
                    amount = value,
                    weight = weight,
                    contribution = contribution,
                }
            end
        end
    end

    local itemClassID, weaponSubClassID = equipment.GetItemClassInfo(itemLink)
    if itemClassID == 2 and weaponSubClassID then
        local effects = equipment.GetWeaponTalentEffects()[weaponSubClassID]
        if effects then
            local effectWeights = {
                WeaponSkill = { effects.skill, weights.WeaponSkill or 0 },
                WeaponCritPercent = { effects.critPercent, weights.WeaponCritPercent or 0 },
                WeaponExtraAttackPercent = { effects.extraAttackPercent, weights.WeaponExtraAttackPercent or 0 },
            }
            for effectName, effect in pairs(effectWeights) do
                local amount, weight = effect[1], effect[2]
                if amount ~= 0 and weight ~= 0 then
                    local contribution = amount * weight
                    score = score + contribution
                    breakdown[effectName] = {
                        amount = amount,
                        weight = weight,
                        contribution = contribution,
                    }
                end
            end

            if effects.damagePercent ~= 0 and weaponData and (weights.WeaponDPS or 0) ~= 0 then
                local dpsIncrease = weaponData.dps * effects.damagePercent / 100
                local contribution = dpsIncrease * weights.WeaponDPS
                score = score + contribution
                breakdown.WeaponDamageTalent = {
                    amount = dpsIncrease,
                    weight = weights.WeaponDPS,
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
    local enchantBonus = tonumber(enchantID and database.enchantBonuses[enchantID]) or 0
    if enchantBonus ~= 0 then
        score = score + enchantBonus
        breakdown.EnchantEffectBonus = {
            amount = enchantBonus,
            weight = 1,
            contribution = enchantBonus,
        }
    end

    return score, breakdown, stats
end
