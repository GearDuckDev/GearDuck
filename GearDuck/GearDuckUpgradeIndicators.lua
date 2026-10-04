local _, addon = ...
local upgradeIndicatorsModule = {}

addon.upgradeIndicators = upgradeIndicatorsModule

function upgradeIndicatorsModule.Initialize(database, evaluateItem, invalidateEvaluationCache)
    local gearDuckDB = database
    local upgradeIndicators = setmetatable({}, { __mode = "k" })
    local ScheduleUpgradeIndicatorRefresh
    local RequestBaganatorRefresh

    local function GetTooltipItemLink(tooltip, data)
        local itemLink = data and data.hyperlink
        if not itemLink and tooltip and tooltip.GetItem then
            local _, tooltipItemLink = tooltip:GetItem()
            itemLink = tooltipItemLink
        end
        if not itemLink and data and tonumber(data.id) then
            itemLink = "item:" .. tostring(data.id)
        end
        return itemLink
    end

    local function IsCharacterPaneFrame(frame)
        while frame do
            local name = frame.GetName and frame:GetName()
            if name then
                name = string.lower(name)
                if string.find(name, "character", 1, true) or string.find(name, "paperdoll", 1, true) then
                    return true
                end
            end
            frame = frame.GetParent and frame:GetParent()
        end
        return false
    end

    local function GetItemIconRegion(owner)
        if not owner then
            return nil
        end

        local iconFields = { "Icon", "icon", "IconTexture", "iconTexture", "ItemIcon", "itemIcon", "texture", "Texture" }
        for _, field in ipairs(iconFields) do
            local region = owner[field]
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                return region
            end
        end

        local name = owner.GetName and owner:GetName()
        if name then
            for _, suffix in ipairs({ "IconTexture", "Icon", "icon", "Texture" }) do
                local region = _G[name .. suffix]
                if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                    return region
                end
            end
        end

        if owner.CreateTexture and owner.GetWidth and owner.GetHeight then
            local width, height = owner:GetWidth(), owner:GetHeight()
            if width >= 12 and height >= 12 and width <= 256 and height <= 256
                and width / height >= 0.5 and width / height <= 2 then
                return owner
            end
        end
        return nil
    end

    local function IsFrameAccessible(frame)
        if not frame then
            return false
        end
        local isForbidden = frame.IsForbidden
        return not isForbidden or not isForbidden(frame)
    end

    local function UpdateUpgradeIndicator(owner, evaluation)
        if not IsFrameAccessible(owner) or owner == UIParent then
            return
        end

        local indicator = upgradeIndicators[owner]
        if not gearDuckDB.showUpgradeArrows then
            if indicator then
                indicator:Hide()
            end
            return
        end
        if IsCharacterPaneFrame(owner) then
            if indicator then
                indicator:Hide()
            end
            return
        end

        local isUpgrade = evaluation and evaluation.canEquip == true
        if isUpgrade then
            isUpgrade = false
            for _, comparison in ipairs(evaluation.comparisons) do
                if comparison.delta > 0.05 then
                    isUpgrade = true
                    break
                end
            end
        end

        if not isUpgrade then
            if indicator then
                indicator:Hide()
            end
            return
        end

        local iconRegion = GetItemIconRegion(owner)
        if not iconRegion or not owner.CreateTexture then
            return
        end

        if not indicator then
            indicator = owner:CreateTexture(nil, "OVERLAY")
            indicator:SetTexture("Interface\\AddOns\\GearDuck\\Textures\\arrow.tga")
            indicator:SetSize(14, 14)
            indicator:SetPoint("TOPRIGHT", iconRegion, "TOPRIGHT", -1, -1)
            upgradeIndicators[owner] = indicator
        end
        indicator:Show()
    end

    local function GetFrameItemLink(frame)
        local link = frame.itemLink or frame.itemHyperlink or frame.hyperlink or frame.link or frame.item
        if type(link) == "string" and link:match("item:%d+") then
            return link
        end

        local frameName = frame.GetName and frame:GetName()
        local bagID = tonumber(frame.bagID)
        local slotID = tonumber(frame.slotID)
        if not bagID and frame.GetBagID then
            local frameBagID = frame:GetBagID()
            bagID = tonumber(frameBagID)
        end
        if not slotID and frame.GetID then
            local frameSlotID = frame:GetID()
            slotID = tonumber(frameSlotID)
        end
        if frameName then
            local containerIndex, namedSlotID = frameName:match("^ContainerFrame(%d+)Item(%d+)$")
            if containerIndex then
                slotID = slotID or tonumber(namedSlotID)
                local containerFrame = rawget(_G, "ContainerFrame" .. containerIndex)
                local getContainerID = rawget(_G, "ContainerFrame_GetContainerID")
                if not bagID and containerFrame and getContainerID then
                    local resolvedBagID = getContainerID(containerFrame)
                    bagID = tonumber(resolvedBagID)
                end
                if not bagID and containerFrame and containerFrame.GetID then
                    local containerID = containerFrame:GetID()
                    bagID = tonumber(containerID)
                end
                if not bagID then
                    bagID = tonumber(containerIndex) - 1
                end
            end
        end
        if not bagID and frame.GetParent then
            local parent = frame:GetParent()
            local parentName = parent and parent.GetName and parent:GetName()
            local containerIndex = parentName and parentName:match("^ContainerFrame(%d+)$")
            if containerIndex then
                local getContainerID = rawget(_G, "ContainerFrame_GetContainerID")
                if getContainerID then
                    local resolvedBagID = getContainerID(parent)
                    bagID = tonumber(resolvedBagID)
                end
                if not bagID and parent.GetID then
                    local parentID = parent:GetID()
                    bagID = tonumber(parentID)
                end
                if not bagID then
                    bagID = tonumber(containerIndex) - 1
                end
            end
            if not slotID and frame.GetID then
                local frameSlotID = frame:GetID()
                slotID = tonumber(frameSlotID)
            end
        end
        if bagID and slotID
            and bagID >= 0 and bagID <= 4294967295 and bagID == math.floor(bagID)
            and slotID >= 1 and slotID <= 4294967295 and slotID == math.floor(slotID) then
            local container = C_Container or _G
            local getContainerItemLink = container.GetContainerItemLink
            if getContainerItemLink then
                link = getContainerItemLink(bagID, slotID)
                if type(link) == "string" and link:match("item:%d+") then
                    return link
                end
            end
            return nil
        end
        if frame.type and slotID then
            local getQuestItemLink
            if QuestInfoFrame and QuestInfoFrame.questLog then
                getQuestItemLink = rawget(_G, "GetQuestLogItemLink")
                if getQuestItemLink then
                    link = getQuestItemLink(frame.type, slotID, frame.questID)
                end
            else
                getQuestItemLink = rawget(_G, "GetQuestItemLink")
                if getQuestItemLink then
                    link = getQuestItemLink(frame.type, slotID)
                end
            end
            if type(link) == "string" and link:match("item:%d+") then
                return link
            end
        end
        local mailIndex = tonumber(frame.mailIndex) or tonumber(frame.mailID) or tonumber(frame.inboxIndex)
        local attachmentIndex = tonumber(frame.attachmentIndex) or tonumber(frame.itemIndex)
        if frameName then
            attachmentIndex = attachmentIndex or tonumber(frameName:match("^OpenMailAttachmentButton(%d+)$"))
            local tradeSlot = tonumber(frameName:match("^TradePlayerItem(%d+)$"))
                or tonumber(frameName:match("^TradeRecipientItem(%d+)$"))
            if tradeSlot then
                local getTradeItemLink = rawget(_G, frameName:match("^TradePlayerItem") and "GetTradePlayerItemLink" or "GetTradeTargetItemLink")
                if getTradeItemLink then
                    link = getTradeItemLink(tradeSlot)
                    if type(link) == "string" and link:match("item:%d+") then
                        return link
                    end
                end
            end
        end
        if not mailIndex and attachmentIndex and frameName and frameName:match("^OpenMailAttachmentButton") then
            local openMailFrame = rawget(_G, "OpenMailFrame")
            mailIndex = tonumber(openMailFrame and openMailFrame.openMailID)
        end
        local getInboxItemLink = rawget(_G, "GetInboxItemLink")
        if mailIndex and attachmentIndex and getInboxItemLink then
            link = getInboxItemLink(mailIndex, attachmentIndex)
            if type(link) == "string" and link:match("item:%d+") then
                return link
            end
        end

        local itemID = tonumber(frame.itemID) or tonumber(frame.itemId)
        if not itemID and type(frame.BGR) == "table" then
            link = frame.BGR.itemLink
            if type(link) == "string" and link:match("item:%d+") then
                return link
            end
            itemID = tonumber(frame.BGR.itemID)
        end
        if itemID then
            return "item:" .. tostring(itemID)
        end
        return nil
    end

    local function RefreshUpgradeIndicators()
        local function RefreshItemButton(button)
            if not IsFrameAccessible(button) or (button.IsShown and not button:IsShown()) then
                return
            end
            local itemLink = GetFrameItemLink(button)
            if itemLink then
                UpdateUpgradeIndicator(button, evaluateItem(itemLink))
            elseif upgradeIndicators[button] then
                upgradeIndicators[button]:Hide()
            end
        end

        local enumerateContainers = rawget(_G, "ContainerFrameUtil_EnumerateContainerFrames")
        if enumerateContainers then
            for _, containerFrame in enumerateContainers() do
                if IsFrameAccessible(containerFrame) and containerFrame.EnumerateValidItems then
                    for _, itemButton in containerFrame:EnumerateValidItems() do
                        RefreshItemButton(itemButton)
                    end
                end
            end
        end

        local combinedBags = rawget(_G, "ContainerFrameCombinedBags")
        if IsFrameAccessible(combinedBags) and combinedBags.EnumerateValidItems
            and (not combinedBags.IsShown or combinedBags:IsShown()) then
            for _, itemButton in combinedBags:EnumerateValidItems() do
                RefreshItemButton(itemButton)
            end
        end

        for _, rewardsFrameName in ipairs({
            "QuestInfoRewardsFrame",
            "MapQuestInfoRewardsFrame",
        }) do
            local rewardsFrame = rawget(_G, rewardsFrameName)
            local rewardButtons = rewardsFrame and rewardsFrame.RewardButtons
            if type(rewardButtons) == "table" then
                for _, rewardButton in pairs(rewardButtons) do
                    RefreshItemButton(rewardButton)
                end
            end
        end

        local explicitItemButtons = {}
        local function AddNamedButtons(prefix, first, last)
            for index = first, last do
                local button = rawget(_G, prefix .. index)
                if button then
                    explicitItemButtons[button] = true
                end
            end
        end
        AddNamedButtons("OpenMailAttachmentButton", 1, 12)
        AddNamedButtons("TradePlayerItem", 1, 6)
        AddNamedButtons("TradeRecipientItem", 1, 6)
        AddNamedButtons("QuestInfoRewardsFrameQuestInfoItem", 1, 30)
        AddNamedButtons("MapQuestInfoRewardsFrameQuestInfoItem", 1, 30)

        for button in pairs(explicitItemButtons) do
            RefreshItemButton(button)
        end

        for owner, indicator in pairs(upgradeIndicators) do
            if IsFrameAccessible(owner) and (not owner.IsVisible or not owner:IsVisible()) then
                indicator:Hide()
            end
        end
    end

    local upgradeRefreshPending = false
    local upgradeRefreshRetries = 0
    ScheduleUpgradeIndicatorRefresh = function(retries)
        upgradeRefreshRetries = math.max(upgradeRefreshRetries, tonumber(retries) or 0)
        if upgradeRefreshPending then
            return
        end
        upgradeRefreshPending = true
        C_Timer.After(0.2, function()
            upgradeRefreshPending = false
            RefreshUpgradeIndicators()
            if upgradeRefreshRetries > 0 then
                upgradeRefreshRetries = upgradeRefreshRetries - 1
                ScheduleUpgradeIndicatorRefresh(upgradeRefreshRetries)
            end
        end)
    end

    local itemRefreshFrame = CreateFrame("Frame")
    local baganatorWidgetRegistered = false
    local function RegisterBaganatorUpgradeWidget()
        local baganator = rawget(_G, "Baganator")
        local api = baganator and baganator.API
        if not api or not api.RegisterCornerWidget or baganatorWidgetRegistered then
            return
        end

        api.RegisterCornerWidget(
            "GearDuck upgrade",
            "gearduck_upgrade",
            function(_, details)
                if not gearDuckDB.showUpgradeArrows then
                    return false
                end
                local evaluation = details and evaluateItem(details.itemLink)
                if evaluation and evaluation.canEquip then
                    for _, comparison in ipairs(evaluation.comparisons) do
                        if comparison.delta > 0.05 then
                            return true
                        end
                    end
                end
                return false
            end,
            function(itemButton)
                local arrow = itemButton:CreateTexture(nil, "OVERLAY")
                arrow:SetTexture("Interface\\AddOns\\GearDuck\\Textures\\arrow.tga")
                arrow:SetSize(14, 14)
                return arrow
            end,
            { corner = "top_right", priority = 4 },
            true
        )
        baganatorWidgetRegistered = true
        RequestBaganatorRefresh = function()
            if api.RequestItemButtonsRefresh then
                api.RequestItemButtonsRefresh()
            end
        end
        RequestBaganatorRefresh()
    end

    local function InstallUIRefreshHooks()
        if not hooksecurefunc then
            return
        end
        local containerMixin = rawget(_G, "ContainerFrameMixin")
        if containerMixin then
            for _, methodName in ipairs({ "OnShow", "UpdateItems", "UpdateIfShown" }) do
                if type(containerMixin[methodName]) == "function" then
                    hooksecurefunc(containerMixin, methodName, function()
                        ScheduleUpgradeIndicatorRefresh(3)
                    end)
                end
            end
        end
        local combinedBagsMixin = rawget(_G, "ContainerFrameCombinedBagsMixin")
        if combinedBagsMixin then
            for _, methodName in ipairs({ "OnShow", "UpdateItems", "UpdateIfShown" }) do
                if type(combinedBagsMixin[methodName]) == "function" then
                    hooksecurefunc(combinedBagsMixin, methodName, function()
                        ScheduleUpgradeIndicatorRefresh(3)
                    end)
                end
            end
        end
        local combinedBags = rawget(_G, "ContainerFrameCombinedBags")
        if combinedBags then
            if combinedBags.HookScript then
                combinedBags:HookScript("OnShow", function()
                    ScheduleUpgradeIndicatorRefresh(3)
                end)
            end
            if type(combinedBags.UpdateItems) == "function" then
                hooksecurefunc(combinedBags, "UpdateItems", function()
                    ScheduleUpgradeIndicatorRefresh(3)
                end)
            end
        end
        local questShowRewards = rawget(_G, "QuestInfo_ShowRewards")
        if type(questShowRewards) == "function" then
            hooksecurefunc("QuestInfo_ShowRewards", ScheduleUpgradeIndicatorRefresh)
        end
        local questGetRewardButton = rawget(_G, "QuestInfo_GetRewardButton")
        if type(questGetRewardButton) == "function" then
            hooksecurefunc("QuestInfo_GetRewardButton", ScheduleUpgradeIndicatorRefresh)
        end
    end
    InstallUIRefreshHooks()
    RegisterBaganatorUpgradeWidget()
    for _, event in ipairs({
        "ADDON_LOADED",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_EQUIPMENT_CHANGED",
        "UNIT_INVENTORY_CHANGED",
        "PLAYER_LEVEL_UP",
        "GET_ITEM_INFO_RECEIVED",
        "BAG_OPEN",
        "BAG_CLOSED",
        "BAG_UPDATE_DELAYED",
        "BANKFRAME_OPENED",
        "BANKFRAME_CLOSED",
        "MAIL_SHOW",
        "MAIL_INBOX_UPDATE",
        "MAIL_SEND_INFO_UPDATE",
        "MAIL_CLOSED",
        "QUEST_LOG_UPDATE",
        "QUEST_DETAIL",
        "QUEST_COMPLETE",
        "QUEST_FINISHED",
        "TRADE_SHOW",
        "TRADE_UPDATE",
        "TRADE_ACCEPT_UPDATE",
        "TRADE_CLOSED",
        "MERCHANT_SHOW",
        "MERCHANT_UPDATE",
        "MERCHANT_CLOSED",
    }) do
        itemRefreshFrame:RegisterEvent(event)
    end
    itemRefreshFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "ADDON_LOADED" then
            if unit == "Blizzard_UIPanels_Game" then
                InstallUIRefreshHooks()
                ScheduleUpgradeIndicatorRefresh()
            elseif unit == "Baganator" then
                RegisterBaganatorUpgradeWidget()
            end
            return
        end
        if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then
            return
        end
        if event == "PLAYER_ENTERING_WORLD"
            or event == "PLAYER_EQUIPMENT_CHANGED"
            or event == "UNIT_INVENTORY_CHANGED"
            or event == "PLAYER_LEVEL_UP"
            or event == "GET_ITEM_INFO_RECEIVED" then
            invalidateEvaluationCache()
        elseif event == "BAG_OPEN" or event == "BAG_UPDATE_DELAYED" then
            ScheduleUpgradeIndicatorRefresh(3)
        else
            ScheduleUpgradeIndicatorRefresh()
        end
    end)

    local integration = {
        GetTooltipItemLink = GetTooltipItemLink,
        UpdateUpgradeIndicator = UpdateUpgradeIndicator,
        ScheduleRefresh = ScheduleUpgradeIndicatorRefresh,
        SetDatabase = function(newDatabase)
            gearDuckDB = newDatabase
        end,
        RefreshAfterEvaluationInvalidated = function()
            if RequestBaganatorRefresh then
                RequestBaganatorRefresh()
            end
            ScheduleUpgradeIndicatorRefresh()
        end,
    }
    return integration
end
