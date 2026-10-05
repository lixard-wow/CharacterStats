local ADDON_NAME, ns = ...
local Share = {}
ns.Share = Share
local pcall = pcall
local wipe = wipe
local GetTime = GetTime
local BNSendWhisper = BNSendWhisper
local sharePopup = nil
local SHARE_INTERVAL = 0.5
local shareSessions = {}
local shareScheduled = false
local function RunShareScheduler()
    shareScheduled = false
    if InCombatLockdown() then
        if #shareSessions > 0 and C_Timer and C_Timer.After then
            shareScheduled = true
            C_Timer.After(1, RunShareScheduler)
        end
        return
    end
    local now = GetTime()
    local nextWake
    local i = 1
    while i <= #shareSessions do
        local s = shareSessions[i]
        if not s or s.nextIndex > s.count then
            table.remove(shareSessions, i)
        else
            if now >= s.nextTime then
                local msg = s.lines[s.nextIndex]
                if type(msg) == "string" and msg ~= "" then
                    if s.kind == "CHAT" and SendChatMessage then
                        local ok
                        if s.channel == "WHISPER" and s.target then
                            ok = pcall(SendChatMessage, msg, "WHISPER", nil, s.target)
                        elseif s.channel then
                            ok = pcall(SendChatMessage, msg, s.channel)
                        end
                        if not ok then
                            wipe(shareSessions)
                            ns.PrintMsg(ns.L.SHARE_FAILED or "Sharing stopped: chat is restricted right now.", "error")
                            return
                        end
                    elseif s.kind == "BNET" and BNSendWhisper and s.target then
                        pcall(BNSendWhisper, s.target, msg)
                    end
                end
                s.nextIndex = s.nextIndex + 1
                s.nextTime = s.nextTime + SHARE_INTERVAL
            end
            if s.nextIndex > s.count then
                table.remove(shareSessions, i)
            else
                if not nextWake or s.nextTime < nextWake then
                    nextWake = s.nextTime
                end
                i = i + 1
            end
        end
    end
    if #shareSessions > 0 and C_Timer and C_Timer.After then
        local delay = (nextWake and (nextWake - now)) or SHARE_INTERVAL
        if delay < 0 then delay = 0 end
        shareScheduled = true
        C_Timer.After(delay, RunShareScheduler)
    end
end
local function EnqueueShareSession(kind, channel, target, statLines)
    if type(statLines) ~= "table" or #statLines == 0 then return end
    if kind == "CHAT" then
        local sendChatMessage = _G and rawget(_G, "SendChatMessage")
        if not sendChatMessage then return end
        if channel == "WHISPER" and not target then return end
    elseif kind == "BNET" then
        if not BNSendWhisper or not target then return end
    else
        return
    end
    local now = GetTime()
    shareSessions[#shareSessions + 1] = {
        kind = kind,
        channel = channel,
        target = target,
        lines = statLines,
        nextIndex = 1,
        count = #statLines,
        nextTime = now,
    }
    if not shareScheduled and C_Timer and C_Timer.After then
        shareScheduled = true
        C_Timer.After(0, RunShareScheduler)
    end
end
local function BuildShareLines()
    local result = {}
    local stats = ns.Stats:CollectFiltered(true)
    local MAX_MSG_LEN = 250
    local playerName = UnitName("player") or "Unknown"
    local _, className = UnitClass("player")
    local level = UnitLevel("player") or 0
    result[#result + 1] = string.format(ns.L.SHARE_HEADER or "[CharacterStats] %s - Level %d %s", playerName, level, className or "")
    local currentLine = ""
    local separator = " || "
    for _, stat in ipairs(stats) do
        if stat.id ~= "movespeed" and not stat.isSecret then
            local labelText = stat.shortLabel or stat.label
            local valueText
            if stat.percent then
                valueText = ns.FormatPercent(stat.value, 1)
            else
                valueText = ns.FormatNumber(stat.value, 0)
            end
            local statText = string.format("%s: %s", labelText, valueText)
            if currentLine == "" then
                currentLine = statText
            elseif #currentLine + #separator + #statText <= MAX_MSG_LEN then
                currentLine = currentLine .. separator .. statText
            else
                result[#result + 1] = currentLine
                currentLine = statText
            end
        end
    end
    if currentLine ~= "" then
        result[#result + 1] = currentLine
    end
    return result
end
local function ShareStatsToChannel(channel, explicitTarget)
    local statLines = BuildShareLines()
    if #statLines == 0 then
        ns.PrintMsg(ns.L.SHARE_NOTHING or "No stats to share.", "error")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        ns.PrintMsg(ns.L.SHARE_IN_COMBAT or "Cannot share stats during combat.", "error")
        return
    end
    if channel == "RAID" then
        EnqueueShareSession("CHAT", "RAID", nil, statLines)
        ns.PrintMsg(string.format(ns.L.SHARE_SENT_RAID or "Sharing %d lines to raid.", #statLines))
    elseif channel == "PARTY" then
        EnqueueShareSession("CHAT", "PARTY", nil, statLines)
        ns.PrintMsg(string.format(ns.L.SHARE_SENT_PARTY or "Sharing %d lines to party.", #statLines))
    elseif channel == "WHISPER" then
        local targetName = explicitTarget or UnitName("target")
        if targetName then
            EnqueueShareSession("CHAT", "WHISPER", targetName, statLines)
            ns.PrintMsg(string.format(ns.L.SHARE_SENT_TARGET or "Sharing %d lines with %s.", #statLines, targetName))
        else
            ns.PrintMsg(ns.L.SHARE_NO_TARGET or "No player targeted.", "error")
        end
    end
end
local function ShareStatsToBNet(accountId)
    if not accountId then return end
    local statLines = BuildShareLines()
    if #statLines == 0 then
        ns.PrintMsg(ns.L.SHARE_NOTHING or "No stats to share.", "error")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        ns.PrintMsg(ns.L.SHARE_IN_COMBAT or "Cannot share stats during combat.", "error")
        return
    end
    if BNSendWhisper then
        EnqueueShareSession("BNET", nil, accountId, statLines)
        ns.PrintMsg(string.format(ns.L.SHARE_SENT_FRIEND or "Sharing %d lines with your Battle.net friend.", #statLines))
    else
        ns.PrintMsg(ns.L.SHARE_NO_BNET or "Battle.net whispers are not available.", "error")
    end
end
local function CreateSharePopup()
    if sharePopup then return sharePopup end
    local POPUP_WIDTH = 240
    local TITLE_HEIGHT = 32
    local BTN_HEIGHT = 26
    local BTN_WIDTH = 200
    local BTN_SPACING = 6
    local SECTION_SPACING = 16
    local TOP_PADDING = 12
    local BOTTOM_PADDING = 12
    local FRIEND_LABEL_HEIGHT = 18
    local POPUP_HEIGHT = TITLE_HEIGHT + TOP_PADDING +
                        (BTN_HEIGHT + BTN_SPACING) * 3 +
                        SECTION_SPACING +
                        FRIEND_LABEL_HEIGHT +
                        (BTN_HEIGHT + BTN_SPACING) * 2 +
                        BOTTOM_PADDING
    local popup = CreateFrame("Frame", "CharacterStatsSharePopup", UIParent, "BackdropTemplate")
    popup:SetSize(POPUP_WIDTH, POPUP_HEIGHT)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:Hide()
    popup.bg = popup:CreateTexture(nil, "BACKGROUND")
    popup.bg:SetAllPoints()
    popup.bg:SetColorTexture(0.06, 0.06, 0.06, 0.98)
    ns.ConfigWidgets.CreateBorder(popup)
    popup.titleBar = CreateFrame("Frame", nil, popup)
    popup.titleBar:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, 0)
    popup.titleBar:SetPoint("TOPRIGHT", popup, "TOPRIGHT", 0, 0)
    popup.titleBar:SetHeight(TITLE_HEIGHT)
    popup.titleBar:EnableMouse(true)
    popup.titleBar:RegisterForDrag("LeftButton")
    popup.titleBar:SetScript("OnDragStart", function() popup:StartMoving() end)
    popup.titleBar:SetScript("OnDragStop", function() popup:StopMovingOrSizing() end)
    popup.titleBar.bg = popup.titleBar:CreateTexture(nil, "BACKGROUND")
    popup.titleBar.bg:SetAllPoints()
    popup.titleBar.bg:SetColorTexture(0.08, 0.08, 0.08, 1)
    popup.titleBar.border = popup.titleBar:CreateTexture(nil, "BORDER")
    popup.titleBar.border:SetPoint("BOTTOMLEFT", popup.titleBar, "BOTTOMLEFT", 0, 0)
    popup.titleBar.border:SetPoint("BOTTOMRIGHT", popup.titleBar, "BOTTOMRIGHT", 0, 0)
    popup.titleBar.border:SetHeight(1)
    popup.titleBar.border:SetColorTexture(0.3, 0.3, 0.3, 1)
    popup.title = popup.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popup.title:SetPoint("LEFT", popup.titleBar, "LEFT", 12, 0)
    popup.title:SetText(ns.L and ns.L.SHARE_TITLE or "Share Stats")
    local tr, tg, tb = ns.GetAccentColor()
    popup.title:SetTextColor(tr, tg, tb)
    popup.closeBtn = CreateFrame("Button", nil, popup.titleBar, "BackdropTemplate")
    popup.closeBtn:SetSize(20, 20)
    popup.closeBtn:SetPoint("RIGHT", popup.titleBar, "RIGHT", -6, 0)
    popup.closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup.closeBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    popup.closeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    popup.closeBtn.text = popup.closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popup.closeBtn.text:SetPoint("CENTER", 0, 0)
    popup.closeBtn.text:SetText("×")
    popup.closeBtn.text:SetTextColor(0.8, 0.8, 0.8)
    popup.closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.5, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        self.text:SetTextColor(1, 1, 1)
    end)
    popup.closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    popup.closeBtn:SetScript("OnClick", function() popup:Hide() end)
    local y = -TITLE_HEIGHT - 12
    local function CreateShareButton(text, onClick, isEnabled)
        local btn = CreateFrame("Button", nil, popup, "BackdropTemplate")
        btn:SetSize(BTN_WIDTH, BTN_HEIGHT)
        btn:SetPoint("TOP", popup, "TOP", 0, y)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.12, 0.12, 0.12, 1)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(text)
        btn._isEnabled = isEnabled or function() return true end
        btn:SetScript("OnEnter", function(self)
            if self:IsEnabled() then
                self:SetBackdropColor(0.2, 0.2, 0.2, 1)
                local ar, ag, ab = ns.GetAccentColor()
                self:SetBackdropBorderColor(ar, ag, ab, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.12, 1)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end)
        btn:SetScript("OnClick", function()
            onClick()
            popup:Hide()
        end)
        y = y - (BTN_HEIGHT + BTN_SPACING)
        return btn
    end
    popup.raidBtn = CreateShareButton(ns.L and ns.L.SHARE_RAID or "Share to Raid", function()
        ShareStatsToChannel("RAID")
    end, function() return IsInRaid() end)
    popup.partyBtn = CreateShareButton(ns.L and ns.L.SHARE_PARTY or "Share to Party", function()
        ShareStatsToChannel("PARTY")
    end, function() return IsInGroup() end)
    popup.whisperBtn = CreateShareButton(ns.L and ns.L.SHARE_WHISPER or "Whisper Target", function()
        ShareStatsToChannel("WHISPER")
    end, function() return UnitExists("target") and UnitIsPlayer("target") end)
    y = y - SECTION_SPACING / 2
    local sep = popup:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOP", popup, "TOP", 0, y)
    sep:SetSize(BTN_WIDTH, 1)
    sep:SetColorTexture(0.3, 0.3, 0.3, 1)
    y = y - SECTION_SPACING / 2
    local friendLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    friendLabel:SetPoint("TOP", popup, "TOP", 0, y)
    friendLabel:SetText(ns.L and ns.L.SHARE_FRIENDS or "Send to Friend")
    local fr, fg, fb = ns.GetAccentColor()
    friendLabel:SetTextColor(fr, fg, fb)
    y = y - 18
    popup.friendBtn = CreateFrame("Button", nil, popup, "BackdropTemplate")
    popup.friendBtn:SetSize(BTN_WIDTH, BTN_HEIGHT)
    popup.friendBtn:SetPoint("TOP", popup, "TOP", 0, y)
    popup.friendBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup.friendBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
    popup.friendBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    popup.friendBtn.text = popup.friendBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.friendBtn.text:SetPoint("LEFT", popup.friendBtn, "LEFT", 8, 0)
    popup.friendBtn.text:SetText(ns.L and ns.L.SHARE_SELECT_FRIEND or "Select Friend...")
    popup.friendBtn.text:SetTextColor(0.6, 0.6, 0.6)
    popup.friendBtn.arrow = popup.friendBtn:CreateTexture(nil, "OVERLAY")
    popup.friendBtn.arrow:SetPoint("RIGHT", popup.friendBtn, "RIGHT", -8, 0)
    popup.friendBtn.arrow:SetSize(12, 12)
    popup.friendBtn.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    popup.friendBtn.arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    popup.friendBtn.arrow:SetVertexColor(0.6, 0.6, 0.6)
    popup.friendBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 1)
        local ar, ag, ab = ns.GetAccentColor()
        self:SetBackdropBorderColor(ar, ag, ab, 1)
    end)
    popup.friendBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.12, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    y = y - (BTN_HEIGHT + BTN_SPACING)
    popup.sendBtn = CreateFrame("Button", nil, popup, "BackdropTemplate")
    popup.sendBtn:SetSize(BTN_WIDTH, BTN_HEIGHT)
    popup.sendBtn:SetPoint("TOP", popup, "TOP", 0, y)
    popup.sendBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    popup.sendBtn:SetBackdropColor(0.12, 0.12, 0.12, 1)
    popup.sendBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    popup.sendBtn.text = popup.sendBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.sendBtn.text:SetPoint("CENTER")
    popup.sendBtn.text:SetText(ns.L and ns.L.SHARE_SEND or "Send")
    popup.sendBtn:SetScript("OnEnter", function(self)
        if self:IsEnabled() then
            self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            local ar, ag, ab = ns.GetAccentColor()
            self:SetBackdropBorderColor(ar, ag, ab, 1)
        end
    end)
    popup.sendBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.12, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    popup.sendBtn:SetScript("OnClick", function()
        if popup._selectedFriend then
            local entry = popup._selectedFriend
            if entry.source == "BNET" and entry.accountId then
                ShareStatsToBNet(entry.accountId)
            elseif entry.name then
                ShareStatsToChannel("WHISPER", entry.name)
            end
            popup:Hide()
        end
    end)
    popup.friendMenu = CreateFrame("Frame", nil, popup)
    popup.friendMenu:SetSize(BTN_WIDTH, 150)
    popup.friendMenu:SetPoint("TOP", popup.friendBtn, "BOTTOM", 0, -2)
    popup.friendMenu:SetFrameStrata("TOOLTIP")
    popup.friendMenu:EnableMouse(true)
    popup.friendMenu:Hide()
    popup.friendMenu.bg = popup.friendMenu:CreateTexture(nil, "BACKGROUND")
    popup.friendMenu.bg:SetAllPoints()
    popup.friendMenu.bg:SetColorTexture(0.08, 0.08, 0.08, 1)
    ns.ConfigWidgets.CreateBorder(popup.friendMenu, 1)
    local scrollBarWidth = 6
    popup.friendMenu.scroll = CreateFrame("ScrollFrame", nil, popup.friendMenu)
    popup.friendMenu.scroll:SetPoint("TOPLEFT", 1, -1)
    popup.friendMenu.scroll:SetPoint("BOTTOMRIGHT", -scrollBarWidth - 3, 1)
    popup.friendMenu.content = CreateFrame("Frame", nil, popup.friendMenu.scroll)
    popup.friendMenu.content:SetSize(BTN_WIDTH - scrollBarWidth - 4, 1)
    popup.friendMenu.scroll:SetScrollChild(popup.friendMenu.content)
    local track = popup.friendMenu:CreateTexture(nil, "BACKGROUND", nil, 1)
    track:SetPoint("TOPRIGHT", -1, -1)
    track:SetPoint("BOTTOMRIGHT", -1, 1)
    track:SetWidth(scrollBarWidth)
    track:SetColorTexture(0.15, 0.15, 0.15, 1)
    popup.friendMenu.track = track
    local thumb = CreateFrame("Button", nil, popup.friendMenu)
    thumb:SetWidth(scrollBarWidth)
    thumb:SetPoint("TOPRIGHT", -1, -1)
    thumb.tex = thumb:CreateTexture(nil, "ARTWORK")
    thumb.tex:SetAllPoints()
    thumb.tex:SetColorTexture(0.4, 0.4, 0.4, 1)
    popup.friendMenu.thumb = thumb
    popup.friendMenu.scroll:EnableMouseWheel(true)
    popup.friendMenu.scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - delta * 22))
        self:SetVerticalScroll(newScroll)
    end)
    popup.friendMenu.buttons = {}
    popup.friendBtn:SetScript("OnClick", function()
        if popup.friendMenu:IsShown() then
            popup.friendMenu:Hide()
        else
            popup:BuildFriendMenu()
            popup.friendMenu:Show()
        end
    end)
    function popup:BuildFriendMenu()
        for _, btn in ipairs(self.friendMenu.buttons) do
            btn:Hide()
        end
        if self.friendMenu.emptyText then
            self.friendMenu.emptyText:Hide()
        end
        local friends = self._friends or {}
        local contentHeight = math.max(#friends * 22, 22)
        self.friendMenu.content:SetHeight(contentHeight)
        if #friends == 0 then
            local noFriends = self.friendMenu.emptyText
            if not noFriends then
                noFriends = self.friendMenu.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                self.friendMenu.emptyText = noFriends
            end
            noFriends:SetPoint("CENTER", self.friendMenu.content, "CENTER", 0, 0)
            noFriends:SetText(ns.L and ns.L.SHARE_NO_FRIENDS or "No friends online")
            noFriends:SetTextColor(0.5, 0.5, 0.5)
            noFriends:Show()
            return
        end
        for i, entry in ipairs(friends) do
            local label = entry.name
            if entry.source == "BNET" and entry.bnetName then
                label = label .. " |cff82c5ff(" .. entry.bnetName .. ")|r"
            end
            local btn = self.friendMenu.buttons[i]
            if not btn then
                btn = CreateFrame("Button", nil, self.friendMenu.content)
                btn:SetSize(BTN_WIDTH - 14, 20)
                btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                btn.text:SetPoint("LEFT", btn, "LEFT", 4, 0)
                btn.text:SetJustifyH("LEFT")
                btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
                btn.highlight:SetAllPoints()
                btn.highlight:SetColorTexture(0.2, 0.2, 0.2, 0.8)
                self.friendMenu.buttons[i] = btn
            end
            btn:SetPoint("TOPLEFT", self.friendMenu.content, "TOPLEFT", 0, -(i - 1) * 22)
            btn.text:SetText(label)
            btn:Show()
            btn:SetScript("OnClick", function()
                self._selectedFriend = entry
                self.friendBtn.text:SetText(entry.name)
                self.friendBtn.text:SetTextColor(1, 1, 1)
                self.friendMenu:Hide()
                self:UpdateButtonStates()
            end)
        end
    end
    function popup:UpdateButtonStates()
        if IsInRaid and IsInRaid() then
            self.raidBtn:Enable()
            self.raidBtn.text:SetTextColor(1, 1, 1)
        else
            self.raidBtn:Disable()
            self.raidBtn.text:SetTextColor(0.4, 0.4, 0.4)
        end
        if IsInGroup and IsInGroup() then
            self.partyBtn:Enable()
            self.partyBtn.text:SetTextColor(1, 1, 1)
        else
            self.partyBtn:Disable()
            self.partyBtn.text:SetTextColor(0.4, 0.4, 0.4)
        end
        if UnitExists("target") and UnitIsPlayer("target") then
            self.whisperBtn:Enable()
            self.whisperBtn.text:SetTextColor(1, 1, 1)
        else
            self.whisperBtn:Disable()
            self.whisperBtn.text:SetTextColor(0.4, 0.4, 0.4)
        end
        if self._selectedFriend then
            self.sendBtn:Enable()
            self.sendBtn.text:SetTextColor(1, 1, 1)
        else
            self.sendBtn:Disable()
            self.sendBtn.text:SetTextColor(0.4, 0.4, 0.4)
        end
    end
    function popup:GatherFriends()
        local friends = {}
        if C_FriendList and C_FriendList.GetNumFriends then
            local num = C_FriendList.GetNumFriends()
            for i = 1, num do
                local info = C_FriendList.GetFriendInfoByIndex and C_FriendList.GetFriendInfoByIndex(i)
                if info and info.name and info.connected then
                    friends[#friends + 1] = {
                        name = info.name,
                        source = "WOW",
                    }
                end
            end
        end
        if BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
            local numBNet = BNGetNumFriends()
            for i = 1, numBNet do
                local accInfo = C_BattleNet.GetFriendAccountInfo(i)
                if accInfo and accInfo.gameAccountInfo then
                    local ga = accInfo.gameAccountInfo
                    if ga.isOnline and ga.clientProgram == "WoW" and ga.characterName then
                        local charName = ga.characterName
                        if ga.realmName and ga.realmName ~= "" then
                            charName = charName .. "-" .. ga.realmName
                        end
                        friends[#friends + 1] = {
                            name = charName,
                            source = "BNET",
                            accountId = accInfo.bnetAccountID,
                            bnetName = accInfo.accountName or accInfo.battleTag,
                        }
                    end
                end
            end
        end
        return friends
    end
    popup:SetScript("OnShow", function(self)
        self._selectedFriend = nil
        self.friendBtn.text:SetText(ns.L and ns.L.SHARE_SELECT_FRIEND or "Select Friend...")
        self.friendBtn.text:SetTextColor(0.6, 0.6, 0.6)
        self._friends = self:GatherFriends()
        self:UpdateButtonStates()
        local ar, ag, ab = ns.GetAccentColor()
        if self.title then
            self.title:SetTextColor(ar, ag, ab)
        end
        if C_Timer and C_Timer.NewTicker then
            if self._ticker then self._ticker:Cancel() end
            self._ticker = C_Timer.NewTicker(0.3, function()
                if self:IsShown() then
                    self:UpdateButtonStates()
                end
            end)
        end
    end)
    popup:SetScript("OnHide", function(self)
        if self._ticker then
            self._ticker:Cancel()
            self._ticker = nil
        end
        if self.friendMenu then
            self.friendMenu:Hide()
        end
    end)
    ns.ConfigWidgets.BindEscapeToClose(popup, function(self)
        self:Hide()
    end)
    sharePopup = popup
    return popup
end
local function ShowSharePopup()
    if InCombatLockdown and InCombatLockdown() then
        ns.PrintMsg(ns.L.SHARE_MENU_COMBAT or "Cannot open the share menu during combat.", "error")
        return
    end
    local popup = CreateSharePopup()
    if popup:IsShown() then
        popup:Hide()
    else
        popup:Show()
    end
end
function Share.TogglePopup()
    ShowSharePopup()
end
