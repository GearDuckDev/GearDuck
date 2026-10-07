local _, addon = ...
local data = addon.data
local profiles = addon.profiles
local onboarding = {}

addon.onboarding = onboarding

local SCORING_CONTEXT_ORDER = data.SCORING_CONTEXT_ORDER

local function ApplyContextSelection(database)
    local state = database.onboarding
    local anySelected = false
    for _, context in ipairs(SCORING_CONTEXT_ORDER) do
        anySelected = anySelected or state.contexts[context.key] == true
    end
    for _, context in ipairs(SCORING_CONTEXT_ORDER) do
        if anySelected then
            database.displayContexts[context.key] = state.contexts[context.key] == true
        else
            database.displayContexts[context.key] = context.key == "QUEST"
        end
    end
end

function onboarding.IsComplete(database)
    return database.onboarding.completed == true
end

function onboarding.SetWeightMode(database, weightDatabase, mode)
    if mode ~= "default" and mode ~= "custom" then
        return
    end
    -- Switching back to defaults discards the pending custom marker and restores default weights.
    if mode == "default" then
        profiles.ResetWeightsToDefaults(weightDatabase)
    end
    database.onboarding.weightMode = mode
end

function onboarding.SetContextSelected(database, contextKey, selected)
    if not data.SCORING_CONTEXTS[contextKey] then
        return
    end
    database.onboarding.contexts[contextKey] = selected == true
    ApplyContextSelection(database)
end

function onboarding.SetUpgradeArrows(database, enabled)
    database.onboarding.arrows = enabled == true
    database.showUpgradeArrows = enabled == true
end

-- Fills every unanswered question with its default. Returns true when custom weights were requested.
function onboarding.Finish(database, weightDatabase)
    local state = database.onboarding
    if state.weightMode == nil then
        onboarding.SetWeightMode(database, weightDatabase, "default")
    end

    local anyContext = false
    for _, context in ipairs(SCORING_CONTEXT_ORDER) do
        anyContext = anyContext or state.contexts[context.key] == true
    end
    if not anyContext then
        state.contexts.QUEST = true
    end
    ApplyContextSelection(database)

    if state.arrows == nil then
        onboarding.SetUpgradeArrows(database, true)
    end

    state.completed = true
    return state.weightMode == "custom"
end

local PAGES = {
    {
        title = "Welcome to GearDuck",
        text = "Thanks for installing GearDuck!\n\nGearDuck helps you decide which gear to wear by turning every item into a single number you can compare at a glance.\n\nThis short setup takes about a minute. You can skip it at any time and GearDuck will use its recommended defaults.",
    },
    {
        title = "What is Power Level?",
        text = "Power Level is GearDuck's score for how good an item is for your character. A higher number means a stronger item for you.\n\nInstead of judging gear by item level or a single stat, GearDuck adds up everything an item gives you, counting each stat by how much it matters to your class and talent tree.",
    },
    {
        title = "How is it calculated?",
        text = "Every stat has a stat weight: how many Power Level points one point of that stat is worth.\n\nAn item's Power Level is each stat amount multiplied by its weight, added together. Weapon DPS and speed, talent-boosted weapon effects, and any manual bonuses you set for procs or set bonuses are included too.\n\nHit stops adding value once you reach your hit cap, so extra hit beyond the cap is not counted.",
    },
    {
        title = "How the addon works",
        text = "Hover over any item and GearDuck adds a line to its tooltip comparing it with what you have equipped: Upgrade, Sidegrade, or Downgrade, plus the Power Level difference.\n\nRings, trinkets, and one-handed weapons show a comparison for each slot. Items you cannot use say Cannot Use. Your active talent tree is detected automatically and has its own weights.\n\nYou can change anything later with /gd options.",
    },
    {
        title = "Stat weights",
        text = "Which stat weights would you like to use?",
        widgets = "weights",
    },
    {
        title = "Tooltip profiles",
        text = "Which profiles should GearDuck show on item tooltips? Choose one or more.",
        widgets = "profiles",
    },
    {
        title = "Upgrade arrows",
        text = "GearDuck can show a small arrow on item icons in your bags and other panels when an item is an upgrade. Would you like to see them?",
        widgets = "arrows",
    },
    {
        title = "Thank you!",
        text = "Thank you for installing GearDuck!\n\nYour settings are saved for this character. Other characters get their own setup and their own stat weights.\n\nYou can reopen this guide any time with /gd setup, and open the settings with /gd options. Happy hunting!",
    },
}
onboarding.PAGES = PAGES

local function TryCreateFrame(frameType, name, parent, template)
    local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
    if ok then
        return frame
    end
    return nil
end

function onboarding.Create(env)
    local frame
    local pageIndex = 1
    local finishing = false
    local choiceWidgets = {}
    local weightRadios = {}
    local arrowRadios = {}
    local contextChecks = {}

    local function Databases()
        return env.getDatabases()
    end

    local function CreateRadio(parent, label, x, y, onClick)
        local radio = TryCreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
        if not radio then
            radio = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        end
        radio:SetSize(24, 24)
        radio:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        local text = radio:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", radio, "RIGHT", 4, 0)
        text:SetText(label)
        radio:SetScript("OnClick", onClick)
        return radio
    end

    local function RefreshChoices()
        local database = Databases()
        local state = database.onboarding
        weightRadios.default:SetChecked(state.weightMode == "default")
        weightRadios.custom:SetChecked(state.weightMode == "custom")
        arrowRadios.yes:SetChecked(state.arrows == true)
        arrowRadios.no:SetChecked(state.arrows == false)
        for _, context in ipairs(SCORING_CONTEXT_ORDER) do
            contextChecks[context.key]:SetChecked(state.contexts[context.key] == true)
        end
    end

    local function ShowPage(index)
        pageIndex = math.max(1, math.min(#PAGES, index))
        local page = PAGES[pageIndex]
        frame.pageTitle:SetText(page.title)
        frame.pageText:SetText(page.text)
        frame.pageCounter:SetText(string.format("Page %d of %d", pageIndex, #PAGES))

        for key, widgets in pairs(choiceWidgets) do
            for _, widget in ipairs(widgets) do
                if key == page.widgets then
                    widget:Show()
                else
                    widget:Hide()
                end
            end
        end
        RefreshChoices()

        if pageIndex == 1 then
            frame.skipButton:Show()
            frame.backButton:Hide()
        else
            frame.skipButton:Hide()
            frame.backButton:Show()
        end
        frame.nextButton:SetText(pageIndex == #PAGES and "Finish" or "Next")
    end

    local function Finish()
        if finishing then
            return
        end
        finishing = true
        local database, weightDatabase = Databases()
        local openCustom = onboarding.Finish(database, weightDatabase)
        env.onChanged()
        if openCustom then
            -- Defer so the settings panel opens after this window has finished hiding.
            if C_Timer and C_Timer.After then
                C_Timer.After(0, env.openOptions)
            else
                env.openOptions()
            end
        end
    end

    local function BuildFrame()
        frame = TryCreateFrame("Frame", "GearDuckOnboardingFrame", UIParent, "BasicFrameTemplateWithInset")
        if not frame then
            frame = CreateFrame("Frame", "GearDuckOnboardingFrame", UIParent, "BackdropTemplate")
            frame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 },
            })
        end
        frame:SetSize(520, 400)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetFrameStrata("DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:Hide()

        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOP", frame, "TOP", 0, frame.CloseButton and -5 or -14)
        header:SetText("GearDuck Setup")

        local closeButton = frame.CloseButton
        if not closeButton then
            closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
            closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
        end
        closeButton:SetScript("OnClick", function()
            frame:Hide()
        end)

        frame.pageTitle = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        frame.pageTitle:SetPoint("TOP", frame, "TOP", 0, -46)

        frame.pageText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        frame.pageText:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -82)
        frame.pageText:SetWidth(460)
        frame.pageText:SetJustifyH("LEFT")
        frame.pageText:SetJustifyV("TOP")
        frame.pageText:SetSpacing(3)

        frame.pageCounter = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        frame.pageCounter:SetPoint("BOTTOM", frame, "BOTTOM", 0, 52)

        local function CreateNavButton(label, anchor, x)
            local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            button:SetSize(120, 24)
            button:SetPoint(anchor, frame, anchor, x, 18)
            button:SetText(label)
            return button
        end

        frame.skipButton = CreateNavButton("Skip Setup", "BOTTOMLEFT", 24)
        frame.skipButton:SetScript("OnClick", function()
            frame:Hide()
        end)
        frame.backButton = CreateNavButton("Back", "BOTTOMLEFT", 24)
        frame.backButton:SetScript("OnClick", function()
            ShowPage(pageIndex - 1)
        end)
        frame.nextButton = CreateNavButton("Next", "BOTTOMRIGHT", -24)
        frame.nextButton:SetScript("OnClick", function()
            if pageIndex == #PAGES then
                frame:Hide()
            else
                ShowPage(pageIndex + 1)
            end
        end)

        local function Choice(group, widget)
            choiceWidgets[group] = choiceWidgets[group] or {}
            table.insert(choiceWidgets[group], widget)
            return widget
        end

        local function ChooseWeights(mode)
            local database, weightDatabase = Databases()
            onboarding.SetWeightMode(database, weightDatabase, mode)
            env.onChanged()
            RefreshChoices()
        end
        weightRadios.default = Choice("weights", CreateRadio(frame, "Use the default stat weights (recommended)", 50, -170, function()
            ChooseWeights("default")
        end))
        weightRadios.custom = Choice("weights", CreateRadio(frame, "Use custom stat weights", 50, -204, function()
            ChooseWeights("custom")
        end))
        local customNote = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        customNote:SetPoint("TOPLEFT", frame, "TOPLEFT", 82, -232)
        customNote:SetWidth(400)
        customNote:SetJustifyH("LEFT")
        customNote:SetText("The settings panel will open when you finish setup so you can edit your weights.")
        Choice("weights", customNote)

        for index, context in ipairs(SCORING_CONTEXT_ORDER) do
            local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
            check:SetSize(26, 26)
            check:SetPoint("TOPLEFT", frame, "TOPLEFT", 50, -150 - (index - 1) * 34)
            local label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            label:SetPoint("LEFT", check, "RIGHT", 4, 0)
            label:SetText(context.name)
            check:SetScript("OnClick", function(self)
                onboarding.SetContextSelected(Databases(), context.key, self:GetChecked() == true)
                env.onChanged()
            end)
            contextChecks[context.key] = Choice("profiles", check)
        end

        local function ChooseArrows(enabled)
            onboarding.SetUpgradeArrows(Databases(), enabled)
            env.onChanged()
            RefreshChoices()
        end
        arrowRadios.yes = Choice("arrows", CreateRadio(frame, "Yes, show upgrade arrows", 50, -170, function()
            ChooseArrows(true)
        end))
        arrowRadios.no = Choice("arrows", CreateRadio(frame, "No, do not show upgrade arrows", 50, -204, function()
            ChooseArrows(false)
        end))

        frame:SetScript("OnHide", function()
            Finish()
        end)
        table.insert(UISpecialFrames, "GearDuckOnboardingFrame")
    end

    local controller = {}
    function controller.Show()
        if not frame then
            BuildFrame()
        end
        finishing = false
        ShowPage(1)
        frame:Show()
    end
    function controller.IsShown()
        return frame ~= nil and frame:IsShown()
    end
    return controller
end
