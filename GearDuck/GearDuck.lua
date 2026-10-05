local _, addon = ...
local data = addon.data
local profiles = addon.profiles
local talents = addon.talents
local presentation = addon.presentation
local hit = addon.hit
local equipment = addon.equipment

local SCORING_CONTEXTS = data.SCORING_CONTEXTS
local SCORING_CONTEXT_ORDER = data.SCORING_CONTEXT_ORDER

local lastEvaluation
local lastTooltip
local optionsPanel
local optionsCategory
local upgradeUI
local EvaluateItem
local ClearEvaluationCache
local SetEvaluationDatabases

local function InvalidateEvaluationCache()
    if ClearEvaluationCache then
        ClearEvaluationCache()
    end
    if upgradeUI then
        upgradeUI.RefreshAfterEvaluationInvalidated()
    end
end

local function ResolveCharacterDatabases()
    local rootDB = profiles.NormalizeDatabase(rawget(_G, "GearDuckDB"))
    local rootWeightsDB = rawget(_G, "GearDuckWeightsDB")
    local characterDB, characterWeightsDB, normalizedRootWeightsDB =
        profiles.GetCharacterDatabases(rootDB, rootWeightsDB, profiles.GetCharacterKey())
    rawset(_G, "GearDuckWeightsDB", normalizedRootWeightsDB)
    return characterDB, characterWeightsDB
end

local gearDuckDB, gearDuckWeightsDB = ResolveCharacterDatabases()
EvaluateItem, ClearEvaluationCache, SetEvaluationDatabases =
    addon.evaluation.Create(gearDuckDB, gearDuckWeightsDB)

optionsPanel, optionsCategory = addon.options.Create(gearDuckDB, gearDuckWeightsDB, InvalidateEvaluationCache)

local function OpenOptionsPanel()
    local settings = rawget(_G, "Settings")
    local openToCategory = settings and rawget(settings, "OpenToCategory")
    if openToCategory and optionsCategory and optionsCategory.GetID then
        openToCategory(optionsCategory:GetID())
        return true
    end

    local openLegacy = rawget(_G, "InterfaceOptionsFrame_OpenToCategory")
    if openLegacy and optionsPanel then
        openLegacy(optionsPanel)
        openLegacy(optionsPanel)
        return true
    end

    return false
end

local onboardingUI = addon.onboarding.Create({
    getDatabases = function()
        return gearDuckDB, gearDuckWeightsDB
    end,
    onChanged = function()
        InvalidateEvaluationCache()
        if optionsPanel and optionsPanel:IsShown() and optionsPanel.RefreshGearDuckOptions then
            optionsPanel:RefreshGearDuckOptions()
        end
    end,
    openOptions = OpenOptionsPanel,
})

local playerBuildFrame = CreateFrame("Frame")
playerBuildFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerBuildFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
playerBuildFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
playerBuildFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
playerBuildFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
playerBuildFrame:SetScript("OnEvent", function()
    talents.ResetActiveTalentTreeCache()
    equipment.ResetTalentCache()
    hit.ResetTalentCache()
    InvalidateEvaluationCache()
    if optionsPanel and optionsPanel:IsShown() and optionsPanel.RefreshGearDuckOptions then
        optionsPanel:RefreshGearDuckOptions()
    end
end)

upgradeUI = addon.upgradeIndicators.Initialize(gearDuckDB, EvaluateItem, InvalidateEvaluationCache)

local function IsComparisonTooltip(tooltip)
    if not tooltip then
        return false
    end
    local name = tooltip.GetName and tooltip:GetName()
    if name and string.find(name, "ShoppingTooltip", 1, true) then
        return true
    end
    return tooltip.IsEmbedded == true or tooltip.isShoppingTooltip == true
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    if hit.IsScannerTooltip(tooltip) or IsComparisonTooltip(tooltip) then
        return
    end

    local owner = tooltip and tooltip.GetOwner and tooltip:GetOwner()
    if upgradeUI.IsCharacterPaneFrame(owner) then
        upgradeUI.UpdateUpgradeIndicator(owner, nil)
        return
    end

    local itemLink = upgradeUI.GetTooltipItemLink(tooltip, data)
    local evaluation = EvaluateItem(itemLink)
    upgradeUI.UpdateUpgradeIndicator(owner, evaluation)

    if evaluation then
        lastEvaluation = evaluation
        lastTooltip = tooltip
        if evaluation.canEquip == false then
            local reason = evaluation.equipRestrictionReason
            tooltip:AddLine("|cffff4040Cannot Use" .. (reason and (": " .. reason) or "") .. "|r")
            tooltip:Show()
            return
        end

        for _, comparison in ipairs(evaluation.comparisons) do
            if evaluation.isEnchantedWeapon then
                tooltip:AddLine(presentation.FormatPowerLevelLine(comparison.profileName, comparison.label .. " (without enchant)", comparison.deltaWithoutEnchant))
                tooltip:AddLine(presentation.FormatPowerLevelLine(comparison.profileName, comparison.label .. " (with enchant)", comparison.delta))
            else
                tooltip:AddLine(presentation.FormatPowerLevelLine(comparison.profileName, comparison.label, comparison.delta))
            end
        end
        tooltip:Show()
    end
end)

SLASH_GEARDUCK1 = "/gearduck"
SLASH_GEARDUCK2 = "/gd"
local function PrintHelp()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck commands:|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd help|r - Show this command list.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd debug|r - Print the hovered item's stats and Power Level math.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd options|r - Open GearDuck's AddOns settings panel.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd setup|r - Reopen the first-time setup guide.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd profile <raid|quest|pvp>|r - Show only the selected profile.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd hitcap <value>|r - Set both hit caps for the selected class/activity.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd hitcap <physical|spell> <value>|r - Set one hit cap as a percentage.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd itembonus <value|clear>|r - Set/clear the hovered item's manual effect score.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd enchantbonus <value|clear>|r - Set/clear a proc-only bonus for the hovered enchant.")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00/gd setbonus <pieces> <value|clear>|r - Set/clear a hovered set's threshold score.")
    DEFAULT_CHAT_FRAME:AddMessage("Use |cffffff00/gearduck|r as an alias for |cffffff00/gd|r.")
end

local function RefreshLastEvaluation()
    if lastEvaluation then
        lastEvaluation = EvaluateItem(lastEvaluation.link)
    end
end

local function GetVisibleTooltipEvaluation()
    local tooltips = {}
    if lastTooltip then
        tooltips[#tooltips + 1] = lastTooltip
    end

    local gameTooltip = rawget(_G, "GameTooltip")
    if gameTooltip and gameTooltip ~= lastTooltip then
        tooltips[#tooltips + 1] = gameTooltip
    end
    local itemRefTooltip = rawget(_G, "ItemRefTooltip")
    if itemRefTooltip and itemRefTooltip ~= lastTooltip and itemRefTooltip ~= gameTooltip then
        tooltips[#tooltips + 1] = itemRefTooltip
    end

    for _, tooltip in ipairs(tooltips) do
        if tooltip.IsShown and tooltip:IsShown() and tooltip.GetItem then
            local _, itemLink = tooltip:GetItem()
            local evaluation = EvaluateItem(itemLink)
            if evaluation then
                return evaluation
            end
        end
    end
    return nil
end

SlashCmdList.GEARDUCK = function(message)
    local command = string.lower(message or "")
    command = command:match("^%s*(.-)%s*$") or ""

    if command == "debug" then
        local evaluation = GetVisibleTooltipEvaluation() or lastEvaluation
        if evaluation then
            lastEvaluation = evaluation
            presentation.PrintDebug(evaluation)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hover an item first, then run /gd debug.")
        end
        return
    end

    if command == "options" then
        if not OpenOptionsPanel() then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Could not open the AddOns settings panel.")
        end
        return
    end

    if command == "setup" then
        onboardingUI.Show()
        return
    end

    local profileName = command:match("^profile%s+(%a+)$")
    if profileName then
        local profileKey = string.upper(profileName)
        if SCORING_CONTEXTS[profileKey] then
            for _, context in ipairs(SCORING_CONTEXT_ORDER) do
                gearDuckDB.displayContexts[context.key] = context.key == profileKey
            end
            InvalidateEvaluationCache()
            if optionsPanel and optionsPanel.RefreshGearDuckOptions then
                optionsPanel:RefreshGearDuckOptions()
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Showing only the " .. SCORING_CONTEXTS[profileKey] .. " profile.")
            RefreshLastEvaluation()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Choose raid, quest, or pvp.")
        end
        return
    end

    local hitCapType, typedHitCapValue = command:match("^hitcap%s+(%a+)%s+([%+%-]?[%d%.]+)$")
    if hitCapType ~= "physical" and hitCapType ~= "spell" then
        hitCapType = nil
        typedHitCapValue = nil
    end
    local legacyHitCapValue = command:match("^hitcap%s+([%+%-]?[%d%.]+)$")
    local hitCapValue = typedHitCapValue or legacyHitCapValue
    if hitCapValue then
        local value = tonumber(hitCapValue)
        if value and value >= 0 and value <= 100 then
            local _, classFile = UnitClass("player")
            local contextKey = gearDuckDB.hitCapContext
            local hitCaps = gearDuckWeightsDB.profiles[classFile][contextKey].hitCaps
            if hitCapType then
                hitCaps[hitCapType] = value
            else
                hitCaps.physical = value
                hitCaps.spell = value
            end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r %s %s hit cap set to %s%%.", SCORING_CONTEXTS[contextKey], hitCapType or "physical and spell", value))
            InvalidateEvaluationCache()
            RefreshLastEvaluation()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hit cap must be between 0 and 100 percent.")
        end
        return
    end

    local itemBonusValue = command:match("^itembonus%s+([%w%+%-%.]+)$")
    if itemBonusValue then
        if not lastEvaluation or not lastEvaluation.itemID then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hover an item first, then set its effect bonus.")
            return
        end
        if itemBonusValue == "clear" then
            gearDuckDB.itemBonuses[lastEvaluation.itemID] = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Cleared the hovered item's manual effect bonus.")
        else
            local value = tonumber(itemBonusValue)
            if not value or math.abs(value) > 100000 then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Item bonus must be between -100000 and 100000.")
                return
            end
            gearDuckDB.itemBonuses[lastEvaluation.itemID] = value
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Item %d effect bonus set to %s Power Level.", lastEvaluation.itemID, value))
        end
        InvalidateEvaluationCache()
        RefreshLastEvaluation()
        return
    end

    local enchantBonusValue = command:match("^enchantbonus%s+([%w%+%-%.]+)$")
    if enchantBonusValue then
        local enchantID = tonumber(lastEvaluation and lastEvaluation.enchantID)
        if not enchantID then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hover an enchanted weapon first.")
            return
        end
        if enchantBonusValue == "clear" then
            gearDuckDB.enchantBonuses[enchantID] = nil
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Cleared enchant %d's manual bonus.", enchantID))
        else
            local value = tonumber(enchantBonusValue)
            if not value or math.abs(value) > 100000 then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Enchant bonus must be between -100000 and 100000.")
                return
            end
            gearDuckDB.enchantBonuses[enchantID] = value
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Enchant %d bonus set to %s Power Level.", enchantID, value))
        end
        InvalidateEvaluationCache()
        RefreshLastEvaluation()
        return
    end

    local setPieces, setBonusValue = command:match("^setbonus%s+(%d+)%s+([%w%+%-%.]+)$")
    if setPieces and setBonusValue then
        local threshold = tonumber(setPieces)
        local setID = tonumber(lastEvaluation and lastEvaluation.itemSetID)
        if not setID then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Hover an item from a set first. Use /gd debug to see its set ID.")
            return
        end
        if not threshold or threshold < 2 or threshold > 20 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Set threshold must be between 2 and 20 pieces.")
            return
        end
        local bonuses = gearDuckDB.setBonuses[setID] or {}
        if setBonusValue == "clear" then
            bonuses[threshold] = nil
            gearDuckDB.setBonuses[setID] = bonuses
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Cleared set %d's %d-piece bonus.", setID, threshold))
        else
            local value = tonumber(setBonusValue)
            if not value or math.abs(value) > 100000 then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Set bonus must be between -100000 and 100000.")
                return
            end
            bonuses[threshold] = value
            gearDuckDB.setBonuses[setID] = bonuses
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ccffGearDuck:|r Set %d's %d-piece bonus set to %s Power Level.", setID, threshold, value))
        end
        InvalidateEvaluationCache()
        RefreshLastEvaluation()
        return
    end

    PrintHelp()
end

local function ApplyCharacterDatabases()
    gearDuckDB, gearDuckWeightsDB = ResolveCharacterDatabases()
    SetEvaluationDatabases(gearDuckDB, gearDuckWeightsDB)
    optionsPanel.SetGearDuckDatabases(gearDuckDB, gearDuckWeightsDB)
    upgradeUI.SetDatabase(gearDuckDB)
    if optionsPanel and optionsPanel:IsShown() and optionsPanel.RefreshGearDuckOptions then
        optionsPanel:RefreshGearDuckOptions()
    end
end

local function ShowOnboardingIfNeeded()
    if addon.onboarding.IsComplete(gearDuckDB) or onboardingUI.IsShown() then
        return
    end
    local ok, err = pcall(onboardingUI.Show)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Could not open setup: " .. tostring(err))
    end
end

local loaderFrame = CreateFrame("Frame")
loaderFrame:RegisterEvent("ADDON_LOADED")
loaderFrame:RegisterEvent("PLAYER_LOGIN")
loaderFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loaderFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        -- The player name can be unavailable at ADDON_LOADED, which would key every character the same.
        ApplyCharacterDatabases()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        -- Wait a moment so the UI has finished loading before showing the window.
        if C_Timer and C_Timer.After then
            C_Timer.After(1, ShowOnboardingIfNeeded)
        else
            ShowOnboardingIfNeeded()
        end
        return
    end

    if addonName == "GearDuck" then
        ApplyCharacterDatabases()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
