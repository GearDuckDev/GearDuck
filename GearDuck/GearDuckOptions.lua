local _, addon = ...
local data = addon.data
local profiles = addon.profiles
local talents = addon.talents
local options = {}

addon.options = options

local STAT_ORDER = data.STAT_ORDER
local STAT_LABELS = data.STAT_LABELS
local CLASS_OPTIONS = data.CLASS_OPTIONS
local CLASS_ACTIVITY_DEFAULTS = data.CLASS_ACTIVITY_DEFAULTS
local SCORING_CONTEXTS = data.SCORING_CONTEXTS
local SCORING_CONTEXT_ORDER = data.SCORING_CONTEXT_ORDER

function options.Create(gearDuckDB, gearDuckWeightsDB, invalidateEvaluationCache)
    local optionsPanel
    local optionsCategory
    local function CreateOptionsPanel()
        local panel = CreateFrame("Frame")
        panel.name = "GearDuck"
        optionsPanel = panel

        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
        title:SetText("GearDuck Power Level Profiles")

        local classLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        classLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -54)
        classLabel:SetText("Class profile:")

        local upgradeArrowsCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        upgradeArrowsCheckbox:SetSize(24, 24)
        upgradeArrowsCheckbox:SetPoint("TOPLEFT", panel, "TOPLEFT", 355, -48)
        upgradeArrowsCheckbox:SetChecked(gearDuckDB.showUpgradeArrows)
        local upgradeArrowsLabel = upgradeArrowsCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        upgradeArrowsLabel:SetPoint("LEFT", upgradeArrowsCheckbox, "RIGHT", 2, 0)
        upgradeArrowsLabel:SetText("Show upgrade arrows")
        upgradeArrowsCheckbox:SetScript("OnClick", function(self)
            gearDuckDB.showUpgradeArrows = self:GetChecked() == true
            invalidateEvaluationCache()
        end)

        local _, playerClassFile = UnitClass("player")
        local selectedClassFile = CLASS_ACTIVITY_DEFAULTS[playerClassFile] and playerClassFile or "ROGUE"
        local activeTreeKey = talents.GetActiveTalentTree()
        local selectedTreeKey = selectedClassFile == playerClassFile and activeTreeKey or nil
        local selectedActivityKey = gearDuckDB.hitCapContext
        if not CLASS_ACTIVITY_DEFAULTS[selectedClassFile][selectedActivityKey] then
            selectedActivityKey = "QUEST"
            gearDuckDB.hitCapContext = selectedActivityKey
        end
        local editBoxes = {}
        local profileCheckboxes = {}
        local physicalHitCapEditBox
        local spellHitCapEditBox
        local activityDropdown
        local scrollFrame
        local refreshPanelOnUpdate = false

        local function FormatWeight(value)
            local formatted = string.format("%.3f", tonumber(value) or 0)
            formatted = formatted:gsub("0+$", "")
            formatted = formatted:gsub("%.$", "")
            return formatted
        end

        local function GetEditBoxValue(editBox)
            if editBox.hitType then
                local activityProfile = profiles.GetActivityWeightProfile(
                    gearDuckWeightsDB,
                    editBox.profileClass,
                    editBox.profileContext
                )
                return activityProfile and activityProfile.hitCaps[editBox.hitType]
            end

            local profile = profiles.GetTalentWeightProfile(
                gearDuckWeightsDB,
                editBox.profileClass,
                editBox.profileContext,
                editBox.profileTree
            )
            return profile[editBox.statName]
        end

        local function SaveEditBox(editBox)
            local value = tonumber(editBox:GetText())
            if editBox.hitType then
                if value and value == value and value >= 0 and value <= 100 then
                    local activityProfile = profiles.GetActivityWeightProfile(
                        gearDuckWeightsDB,
                        editBox.profileClass,
                        editBox.profileContext
                    )
                    if activityProfile then
                        activityProfile.hitCaps[editBox.hitType] = value
                    end
                end
            elseif value and value == value and math.abs(value) <= 1000 then
                profiles.GetTalentWeightProfile(
                    gearDuckWeightsDB,
                    editBox.profileClass,
                    editBox.profileContext,
                    editBox.profileTree
                )[editBox.statName] = value
            end

            editBox:SetText(FormatWeight(GetEditBoxValue(editBox)))
            invalidateEvaluationCache()
        end

        local function RefreshEditBoxes()
            local defaults = CLASS_ACTIVITY_DEFAULTS[selectedClassFile][selectedActivityKey]
            for _, editBox in ipairs(editBoxes) do
                editBox.profileClass = selectedClassFile
                editBox.profileContext = selectedActivityKey
                editBox.profileTree = selectedTreeKey
                local defaultValue = editBox.hitType
                    and defaults.hitCaps[editBox.hitType]
                    or defaults.weights[editBox.statName]
                editBox:SetText(FormatWeight(GetEditBoxValue(editBox) or defaultValue))
                editBox:SetCursorPosition(0)
            end
        end

        local function CommitEditBoxes()
            for _, editBox in ipairs(editBoxes) do
                SaveEditBox(editBox)
            end
        end

        local dropdown = CreateFrame("Frame", "GearDuckClassDropdown", panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", panel, "TOPLEFT", 118, -44)
        UIDropDownMenu_SetWidth(dropdown, 150)
        UIDropDownMenu_Initialize(dropdown, function(self, level)
            for _, classInfo in ipairs(CLASS_OPTIONS) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = classInfo.name
                info.value = classInfo.file
                info.checked = selectedClassFile == classInfo.file
                info.func = function()
                    CommitEditBoxes()
                    selectedClassFile = classInfo.file
                    local activeKey = talents.GetActiveTalentTree()
                    selectedTreeKey = classInfo.file == playerClassFile and activeKey or nil
                    UIDropDownMenu_SetSelectedValue(dropdown, selectedClassFile)
                    RefreshEditBoxes()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        UIDropDownMenu_SetSelectedValue(dropdown, selectedClassFile)

        local profilesLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        profilesLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -84)
        profilesLabel:SetText("Show in tooltips:")

        for index, context in ipairs(SCORING_CONTEXT_ORDER) do
            local contextKey = context.key
            local contextName = context.name
            local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            checkbox:SetSize(24, 24)
            checkbox:SetPoint("TOPLEFT", panel, "TOPLEFT", 142 + (index - 1) * 100, -78)
            local label = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
            label:SetText(contextName)
            checkbox:SetChecked(gearDuckDB.displayContexts[contextKey])
            checkbox:SetScript("OnClick", function(self)
                local checkedCount = 0
                for _, option in ipairs(SCORING_CONTEXT_ORDER) do
                    if option.key ~= contextKey and gearDuckDB.displayContexts[option.key] then
                        checkedCount = checkedCount + 1
                    end
                end
                if not self:GetChecked() and checkedCount == 0 then
                    self:SetChecked(true)
                    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffGearDuck:|r Select at least one tooltip profile.")
                    return
                end

                gearDuckDB.displayContexts[contextKey] = self:GetChecked() == true
                invalidateEvaluationCache()
            end)
            profileCheckboxes[context.key] = checkbox
        end

        local activityLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        activityLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -114)
        activityLabel:SetText("Edit activity:")

        activityDropdown = CreateFrame("Frame", "GearDuckActivityProfileDropdown", panel, "UIDropDownMenuTemplate")
        activityDropdown:SetPoint("TOPLEFT", panel, "TOPLEFT", 120, -104)
        UIDropDownMenu_SetWidth(activityDropdown, 170)
        UIDropDownMenu_Initialize(activityDropdown, function(self, level)
            for _, context in ipairs(SCORING_CONTEXT_ORDER) do
                local contextKey = context.key
                local contextName = context.name
                local info = UIDropDownMenu_CreateInfo()
                info.text = contextName
                info.value = contextKey
                info.checked = selectedActivityKey == contextKey
                info.func = function()
                    CommitEditBoxes()
                    selectedActivityKey = contextKey
                    gearDuckDB.hitCapContext = contextKey
                    UIDropDownMenu_SetSelectedValue(activityDropdown, selectedActivityKey)
                    UIDropDownMenu_SetText(activityDropdown, contextName)
                    RefreshEditBoxes()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        UIDropDownMenu_SetSelectedValue(activityDropdown, selectedActivityKey)
        UIDropDownMenu_SetText(activityDropdown, SCORING_CONTEXTS[selectedActivityKey])

        local physicalHitCapLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        physicalHitCapLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -145)
        physicalHitCapLabel:SetText("Physical hit cap (%):")

        physicalHitCapEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        physicalHitCapEditBox:SetSize(60, 22)
        physicalHitCapEditBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 155, -142)
        physicalHitCapEditBox:SetAutoFocus(false)
        physicalHitCapEditBox:SetTextInsets(5, 5, 0, 0)
        physicalHitCapEditBox:SetScript("OnEnterPressed", function(self)
            SaveEditBox(self)
            RefreshEditBoxes()
            self:ClearFocus()
        end)
        physicalHitCapEditBox:SetScript("OnEditFocusLost", SaveEditBox)
        physicalHitCapEditBox:SetScript("OnEscapePressed", function()
            RefreshEditBoxes()
            physicalHitCapEditBox:ClearFocus()
        end)
        physicalHitCapEditBox.hitType = "physical"
        editBoxes[#editBoxes + 1] = physicalHitCapEditBox

        local spellHitCapLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        spellHitCapLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 250, -145)
        spellHitCapLabel:SetText("Spell hit cap (%):")

        spellHitCapEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        spellHitCapEditBox:SetSize(60, 22)
        spellHitCapEditBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 380, -142)
        spellHitCapEditBox:SetAutoFocus(false)
        spellHitCapEditBox:SetTextInsets(5, 5, 0, 0)
        spellHitCapEditBox:SetScript("OnEnterPressed", function(self)
            SaveEditBox(self)
            RefreshEditBoxes()
            self:ClearFocus()
        end)
        spellHitCapEditBox:SetScript("OnEditFocusLost", SaveEditBox)
        spellHitCapEditBox:SetScript("OnEscapePressed", function()
            RefreshEditBoxes()
            spellHitCapEditBox:ClearFocus()
        end)
        spellHitCapEditBox.hitType = "spell"
        editBoxes[#editBoxes + 1] = spellHitCapEditBox
        RefreshEditBoxes()

        local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        resetButton:SetSize(150, 24)
        resetButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 460, -142)
        resetButton:SetText("Restore defaults")
        resetButton:SetScript("OnClick", function()
            local defaults = CLASS_ACTIVITY_DEFAULTS[selectedClassFile][selectedActivityKey]
            local profile = profiles.GetTalentWeightProfile(
                gearDuckWeightsDB,
                selectedClassFile,
                selectedActivityKey,
                selectedTreeKey
            )
            for _, statName in ipairs(STAT_ORDER) do
                profile[statName] = defaults.weights[statName] or 0
            end
            local activityProfile = profiles.GetActivityWeightProfile(
                gearDuckWeightsDB,
                selectedClassFile,
                selectedActivityKey
            )
            if activityProfile then
                activityProfile.hitCaps.physical = defaults.hitCaps.physical
                activityProfile.hitCaps.spell = defaults.hitCaps.spell
            end
            invalidateEvaluationCache()
            RefreshEditBoxes()
        end)

        local helpText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        helpText:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -175)
        helpText:SetWidth(410)
        helpText:SetText("Active talent weights are detected automatically. Hit caps subtract recognized talent bonuses; buffs are not included.")

        scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -206)
        scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -34, 18)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(560, #STAT_ORDER * 30)
        scrollFrame:SetScrollChild(scrollChild)

        for index, statName in ipairs(STAT_ORDER) do
            local rowTop = -((index - 1) * 30)
            local label = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            label:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, rowTop - 4)
            label:SetText(STAT_LABELS[statName] or statName)

            local editBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            editBox:SetSize(90, 22)
            editBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 300, rowTop - 1)
            editBox:SetAutoFocus(false)
            editBox:SetTextInsets(5, 5, 0, 0)
            editBox.statName = statName
            editBox.profileClass = selectedClassFile
            editBox.profileContext = selectedActivityKey
            editBox.profileTree = selectedTreeKey
            editBox:SetScript("OnEnterPressed", function(self)
                SaveEditBox(self)
                self:ClearFocus()
            end)
            editBox:SetScript("OnEditFocusLost", SaveEditBox)
            editBox:SetScript("OnEscapePressed", function(self)
                RefreshEditBoxes()
                self:ClearFocus()
            end)
            editBoxes[#editBoxes + 1] = editBox
        end

        RefreshEditBoxes()
        local settings = rawget(_G, "Settings")
        local registerCanvas = settings and rawget(settings, "RegisterCanvasLayoutCategory")
        local registerAddonCategory = settings and rawget(settings, "RegisterAddOnCategory")
        if registerCanvas and registerAddonCategory then
            optionsCategory = registerCanvas(panel, panel.name)
            registerAddonCategory(optionsCategory)
        else
            optionsCategory = panel
            local registerLegacy = rawget(_G, "InterfaceOptions_AddCategory")
            if registerLegacy then
                registerLegacy(panel)
            end
        end

        local function RefreshOptionsPanel()
            local activeKey = talents.GetActiveTalentTree()
            selectedTreeKey = selectedClassFile == playerClassFile and activeKey or nil
            selectedActivityKey = gearDuckDB.hitCapContext
            if not CLASS_ACTIVITY_DEFAULTS[selectedClassFile][selectedActivityKey] then
                selectedActivityKey = "QUEST"
                gearDuckDB.hitCapContext = selectedActivityKey
            end
            for _, context in ipairs(SCORING_CONTEXT_ORDER) do
                profileCheckboxes[context.key]:SetChecked(gearDuckDB.displayContexts[context.key])
            end
            upgradeArrowsCheckbox:SetChecked(gearDuckDB.showUpgradeArrows)
            UIDropDownMenu_SetSelectedValue(activityDropdown, selectedActivityKey)
            UIDropDownMenu_SetText(activityDropdown, SCORING_CONTEXTS[selectedActivityKey] or "Unknown")
            UIDropDownMenu_SetSelectedValue(dropdown, selectedClassFile)
            for _, classInfo in ipairs(CLASS_OPTIONS) do
                if classInfo.file == selectedClassFile then
                    UIDropDownMenu_SetText(dropdown, classInfo.name)
                    break
                end
            end

            RefreshEditBoxes()
        end
        panel.RefreshGearDuckOptions = RefreshOptionsPanel

        panel:HookScript("OnShow", function()
            refreshPanelOnUpdate = true
        end)
        panel:SetScript("OnUpdate", function(self)
            if refreshPanelOnUpdate and self:IsVisible() and self:GetWidth() > 0 then
                refreshPanelOnUpdate = false
                RefreshOptionsPanel()
            end
        end)
    end

    CreateOptionsPanel()
    optionsPanel.SetGearDuckDatabases = function(database, weightDatabase)
        gearDuckDB = database
        gearDuckWeightsDB = weightDatabase
    end
    return optionsPanel, optionsCategory
end
