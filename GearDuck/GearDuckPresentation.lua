local _, addon = ...
local data = addon.data
local presentation = {}

addon.presentation = presentation

function presentation.FormatScore(score)
    if math.abs(score - math.floor(score + 0.5)) < 0.05 then
        return string.format("%d", math.floor(score + 0.5))
    end
    return string.format("%.1f", score)
end

function presentation.FormatPowerLevelLine(profileName, label, delta)
    local status
    local color

    if delta > 0.05 then
        status = "Upgrade"
        color = "|cff00ff00"
    elseif delta < -0.05 then
        status = "Downgrade"
        color = "|cffff4040"
    else
        delta = 0
        status = "Sidegrade"
        color = "|cffffff00"
    end

    local formattedDelta = presentation.FormatScore(delta)
    if delta > 0 then
        formattedDelta = "+" .. formattedDelta
    end

    return color .. profileName .. " PL: " .. label .. " " .. formattedDelta .. " (" .. status .. ")|r"
end

function presentation.PrintDebug(evaluation)
    local function Print(message)
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r " .. message)
    end

    Print("Item: " .. evaluation.link)
    Print(string.format("Class profile: %s (%s)", evaluation.className, evaluation.classFile))
    Print("Can equip: " .. (evaluation.canEquip == false and ("No (" .. (evaluation.equipRestrictionReason or "restricted") .. ")") or (evaluation.canEquip == true and "Yes" or "Unknown")))
    local raceName, raceFile = UnitRace("player")
    Print(string.format("Race: %s (%s)", raceName or "Unknown", raceFile or "Unknown"))
    Print("Weighted item score = " .. presentation.FormatScore(evaluation.itemScore))

    for statName, result in pairs(evaluation.itemBreakdown) do
        Print(string.format("  %s: %g x %g = %g", statName, result.amount, result.weight, result.contribution))
    end

    Print("Raw item stats:")
    local hasStats = false
    for key, value in pairs(evaluation.itemStats) do
        hasStats = true
        Print(string.format("  %s = %s", key, tostring(value)))
    end
    if not hasStats then
        Print("  (none returned; item data may not be available yet)")
    end

    for _, equipped in ipairs(evaluation.equipped) do
        local slotLabel = data.EQUIP_SLOT_LABELS[equipped.slot] or ("Slot " .. equipped.slot)
        Print(string.format(
            "Equipped %s: %s (weighted score %s)",
            slotLabel,
            equipped.link or "empty",
            presentation.FormatScore(equipped.score)
        ))
    end

    for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
        local hitCap = evaluation.hitCaps[context.key]
        if hitCap ~= nil then
            Print(string.format(
                "%s effective hit cap: %s%%",
                context.name,
                presentation.FormatScore(hitCap)
            ))
        end
    end

    local activeContextProfile
    for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
        activeContextProfile = evaluation.contextScores[context.key]
        if activeContextProfile then
            break
        end
    end
    if activeContextProfile and activeContextProfile.treeName then
        Print(string.format(
            "Active talent profile: %s (%s points; %s)",
            activeContextProfile.treeName,
            tostring(activeContextProfile.treePoints or "?"),
            activeContextProfile.treeKey
        ))
    end
    if evaluation.itemSetID then
        Print(string.format("Item set ID: %d", evaluation.itemSetID))
    end
    if evaluation.enchantID then
        Print(string.format("Enchant ID: %d", evaluation.enchantID))
    end

    for _, comparison in ipairs(evaluation.comparisons) do
        Print(string.format(
            "%s PL vs %s: %s - %s = %s",
            comparison.profileName,
            comparison.label,
            presentation.FormatScore(comparison.itemScore),
            presentation.FormatScore(comparison.equippedScore),
            presentation.FormatScore(comparison.delta)
        ))
    end
end
