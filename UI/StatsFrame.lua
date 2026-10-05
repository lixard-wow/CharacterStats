local ADDON_NAME, ns = ...
local StatsFrame = {}
ns.StatsFrame = StatsFrame
local ipairs, type = ipairs, type
local wipe = wipe
local string_format = string.format
local GetTime = GetTime
local function SafeStringWidth(fontString, fallback)
    local ok, w = pcall(function() return fontString:GetStringWidth() end)
    if not ok or not w then return fallback or 0 end
    local ok2, n = pcall(function() return tonumber(string_format("%.4f", w)) end)
    return (ok2 and n) or fallback or 0
end
local pcall = pcall
local BNSendWhisper = BNSendWhisper
local frame
local lines = {}
local separators = {}
local MAX_LINES = 25
local moveSpeedLineIndex = nil
local cachedWidth = 0
local cachedPercentWidth = nil
local sharePopup = nil
local lastFontSettings = {}
local lastDisplayedStats = {}
local lastStatOrder = {}
local moveSpeedElapsed = 0
local MOVE_SPEED_UPDATE_INTERVAL = 0.1
local H_PAD = 6
local H_GAP = 5
local H_SPACING = 14
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
    result[#result + 1] = string.format("[CharacterStats] %s - Lvl %d %s", playerName, level, className or "")
    local currentLine = ""
    local separator = " || "
    for _, stat in ipairs(stats) do
        if stat.id ~= "movespeed" then
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
        ns.PrintMsg("No stats to share", "error")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        ns.PrintMsg("Cannot share stats during combat", "error")
        return
    end
    if channel == "RAID" then
        EnqueueShareSession("CHAT", "RAID", nil, statLines)
        ns.PrintMsg(string.format("%d lines shared to raid", #statLines))
    elseif channel == "PARTY" then
        EnqueueShareSession("CHAT", "PARTY", nil, statLines)
        ns.PrintMsg(string.format("%d lines shared to party", #statLines))
    elseif channel == "WHISPER" then
        local targetName = explicitTarget or UnitName("target")
        if targetName then
            EnqueueShareSession("CHAT", "WHISPER", targetName, statLines)
            ns.PrintMsg(string.format("%d lines shared to %s", #statLines, targetName))
        else
            ns.PrintMsg("No target selected for whisper", "error")
        end
    end
end
local function ShareStatsToBNet(accountId)
    if not accountId then return end
    local statLines = BuildShareLines()
    if #statLines == 0 then
        ns.PrintMsg("No stats to share", "error")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        ns.PrintMsg("Cannot share stats during combat", "error")
        return
    end
    if BNSendWhisper then
        EnqueueShareSession("BNET", nil, accountId, statLines)
        ns.PrintMsg(string.format("%d lines shared to BNet friend", #statLines))
    else
        ns.PrintMsg("BNet whisper not available", "error")
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
        local friends = self._friends or {}
        local contentHeight = math.max(#friends * 22, 22)
        self.friendMenu.content:SetHeight(contentHeight)
        if #friends == 0 then
            local noFriends = self.friendMenu.buttons[1]
            if not noFriends then
                noFriends = self.friendMenu.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                self.friendMenu.buttons[1] = noFriends
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
            if not btn or btn.SetText == nil then
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
    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    sharePopup = popup
    return popup
end
local function ShowSharePopup()
    if InCombatLockdown and InCombatLockdown() then
        ns.PrintMsg("Cannot open menu during combat", "error")
        return
    end
    local popup = CreateSharePopup()
    if popup:IsShown() then
        popup:Hide()
    else
        popup:Show()
    end
end
function StatsFrame:Create()
    if frame then return frame end
    local db = ns.db or ns.DEFAULTS
    frame = CreateFrame("Frame", "CharacterStatsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(150, 200)
    local anchor = db.anchor or "LEFT"
    local anchorTo = db.anchorTo or "LEFT"
    frame:SetPoint(anchor, UIParent, anchorTo, ns.PixelRound(db.x), ns.PixelRound(db.y))
    frame:SetMovable(true)
    frame:SetClampedToScreen(db.clampToScreen ~= false)
    frame:EnableMouse(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if ns.db.locked then return end
            self:StartMoving()
            self._isUserMoving = true
        end
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            if self._isUserMoving then
                self:StopMovingOrSizing()
                self._isUserMoving = false
                StatsFrame:SavePosition()
            end
        elseif button == "RightButton" then
            ShowSharePopup()
        end
    end)
    for i = 1, MAX_LINES do
        lines[i] = self:CreateLine(frame, i)
    end
    self:ApplyStyle()
    frame:SetScript("OnShow", function()
        StatsFrame:Refresh()
    end)
    return frame
end
function StatsFrame:CreateLine(parent, index)
    local line = {}
    local db = ns.db or ns.DEFAULTS
    local rowHeight = db.fontSize + (db.rowPadding or 0)
    local yOffset = -10 - ((index - 1) * rowHeight)
    line.frame = CreateFrame("Frame", nil, parent)
    line.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    line.frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, yOffset)
    line.frame:SetHeight(rowHeight)
    line.label = line.frame:CreateFontString(nil, "OVERLAY")
    line.label:SetFont(ns.GetFontPath(db.fontFace), db.fontSize, db.fontOutline)
    line.label:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
    line.label:SetJustifyH("LEFT")
    line.value = line.frame:CreateFontString(nil, "OVERLAY")
    line.value:SetFont(ns.GetFontPath(db.fontFace), db.fontSize, db.fontOutline)
    line.value:SetPoint("RIGHT", line.frame, "RIGHT", 0, 0)
    line.value:SetJustifyH("RIGHT")
    line.frame:Hide()
    return line
end
function StatsFrame:ApplyStyle()
    if not frame then return end
    cachedWidth = 0
    wipe(lastStatOrder)
    wipe(lastDisplayedStats)
    ns.Stats:Invalidate()
    local db = ns.db or ns.DEFAULTS
    frame:SetScale(1)
    local bgR, bgG, bgB = 0.05, 0.05, 0.08
    frame.bg:SetColorTexture(bgR, bgG, bgB, db.bgAlpha)
    local borderR, borderG, borderB = 1, 1, 1
    if db.borderUseClassColor then
        local customColors = _G and rawget(_G, "CUSTOM_CLASS_COLORS")
        local classColors = customColors or RAID_CLASS_COLORS
        local classColor = classColors and classColors[select(2, UnitClass("player"))]
        if classColor then
            borderR, borderG, borderB = classColor.r, classColor.g, classColor.b
        end
    elseif db.borderColor then
        borderR, borderG, borderB = db.borderColor.r, db.borderColor.g, db.borderColor.b
    end
    local BORDER_MUTE = 0.65
    local BG_FILE = "Interface\\Buttons\\WHITE8x8"
    if db.borderStyle == "none" then
        frame:SetBackdrop(nil)
    elseif db.borderStyle == "thick" then
        frame:SetBackdrop({ edgeFile = BG_FILE, edgeSize = 2, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        frame:SetBackdropBorderColor(borderR * BORDER_MUTE, borderG * BORDER_MUTE, borderB * BORDER_MUTE, db.borderAlpha or 1)
    elseif db.borderStyle == "tooltip" then
        frame:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
        frame:SetBackdropBorderColor(borderR, borderG, borderB, db.borderAlpha or 1)
    elseif db.borderStyle == "dialog" then
        frame:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
        frame:SetBackdropBorderColor(borderR, borderG, borderB, db.borderAlpha or 1)
    else
        frame:SetBackdrop({ edgeFile = BG_FILE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        frame:SetBackdropBorderColor(borderR * BORDER_MUTE, borderG * BORDER_MUTE, borderB * BORDER_MUTE, db.borderAlpha or 1)
    end
    local fontPath = ns.GetFontPath(db.fontFace)
    local fontOutline = db.fontOutline or ""
    local fontSize = db.fontSize or 11
    local fontChanged = lastFontSettings.fontPath ~= fontPath
        or lastFontSettings.fontOutline ~= fontOutline
        or lastFontSettings.fontSize ~= fontSize
    if #lines == 0 then
        for i = 1, MAX_LINES do
            lines[i] = StatsFrame:CreateLine(frame, i)
        end
    end
    if fontChanged then
        lastFontSettings.fontPath = fontPath
        lastFontSettings.fontOutline = fontOutline
        lastFontSettings.fontSize = fontSize
        cachedPercentWidth = nil
        cachedWidth = 0
    end
    if frame:IsShown() then
        StatsFrame:Refresh()
    end
end
local function LayoutChanged(stats)
    if #stats ~= #lastStatOrder then return true end
    for i, stat in ipairs(stats) do
        if lastStatOrder[i] ~= stat.id then return true end
    end
    return false
end
local function FormatStatValue(stat, db)
    local dec = ns.GetDecimals(db.decimals)
    local ratingMode = db.ratingMode or "percent"
    local percentText = ns.FormatPercent(stat.value, dec)
    if stat.percent and stat.ratingId and stat.ratingId <= 32 then
        local ratingText = ns.FormatRating(stat.ratingId)
        if ratingMode == "rating" then
            return ratingText or percentText
        elseif ratingMode == "both" then
            return ratingText and (ratingText .. " " .. percentText) or percentText
        else
            return percentText
        end
    elseif stat.percent then
        return percentText
    else
        return ns.FormatNumber(stat.value, stat.useDecimals and dec or 0)
    end
end
function StatsFrame:RefreshValuesOnly()
    if not frame or not frame:IsShown() then return end
    local db = ns.db or ns.DEFAULTS
    local stats = ns.Stats:CollectFiltered(true)
    if LayoutChanged(stats) then
        return self:Refresh()
    end
    local ilvlColorDirty = ns._ilvlColorDirty
    local textAlpha = db.textAlpha or 1
    for i, stat in ipairs(stats) do
        local lastVal = lastDisplayedStats[stat.id]
        local valueChanged
        if stat.isSecret then
            valueChanged = true
        elseif not lastVal then
            valueChanged = true
        else
            local ok, result = pcall(function()
                local wasZero = math.abs(lastVal) < 0.01
                local nowZero = math.abs(stat.value) < 0.01
                if wasZero ~= nowZero then return true end
                return math.abs(stat.value - lastVal) >= 0.01
            end)
            valueChanged = not ok or result
        end
        local colorChanged = ilvlColorDirty and stat.id == "ilvl"
        if valueChanged or colorChanged then
            local line = lines[i]
            if line then
                if valueChanged then
                    line.value:SetText(FormatStatValue(stat, db))
                    if not stat.isSecret then
                        lastDisplayedStats[stat.id] = stat.value
                    end
                end
                if colorChanged then
                    local sr, sg, sb = ns.GetStatColor(stat.id)
                    line.label:SetTextColor(sr, sg, sb, textAlpha)
                    line.value:SetTextColor(sr, sg, sb, textAlpha)
                end
            end
        end
    end
end
function StatsFrame:Refresh()
    if not frame or not frame:IsShown() then return end
    local db = ns.db or ns.DEFAULTS
    local stats = ns.Stats:CollectFiltered(true)
    if not LayoutChanged(stats) and #lastStatOrder > 0 then
        return self:RefreshValuesOnly()
    end
    local rowHeight = db.fontSize + (db.rowPadding or 0)
    local fontPath = ns.GetFontPath(db.fontFace)
    if #lines == 0 then
        for i = 1, MAX_LINES do
            lines[i] = self:CreateLine(frame, i)
        end
    end
    for i = 1, MAX_LINES do
        if lines[i] then
            lines[i].frame:Hide()
        end
        if separators[i] then
            separators[i]:Hide()
        end
    end
    wipe(lastStatOrder)
    wipe(lastDisplayedStats)
    local orientation = db.orientation or "vertical"
    local isHorizontal = orientation == "horizontal"
    local yPosition = -10
    local xPosition = 10
    local lineIndex = 0
    local maxWidth = 0
    local maxHeight = 0
    moveSpeedLineIndex = nil
    for _, stat in ipairs(stats) do
        lineIndex = lineIndex + 1
        if lineIndex > MAX_LINES then break end
        lastStatOrder[lineIndex] = stat.id
        if not stat.isSecret then
            lastDisplayedStats[stat.id] = stat.value
        end
        if stat.id == "movespeed" then
            moveSpeedLineIndex = lineIndex
        end
        local line = lines[lineIndex]
        if not line then break end
        line.frame:ClearAllPoints()
        line.frame:SetHeight(rowHeight)
        if isHorizontal then
            line.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", xPosition, yPosition)
        else
            line.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yPosition)
            line.frame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, yPosition)
        end
        line.label:SetFont(fontPath, db.fontSize, db.fontOutline)
        line.value:SetFont(fontPath, db.fontSize, db.fontOutline)
        line.label:ClearAllPoints()
        line.value:ClearAllPoints()
        local alignMode = isHorizontal and "left" or (db.alignMode or "justify")
        if alignMode == "left" then
            local leftOffset = isHorizontal and H_PAD or 0
            local gap = isHorizontal and H_GAP or 5
            line.label:SetPoint("LEFT", line.frame, "LEFT", leftOffset, 0)
            line.label:SetJustifyH("LEFT")
            line.value:SetPoint("LEFT", line.label, "RIGHT", gap, 0)
            line.value:SetJustifyH("LEFT")
        elseif alignMode == "right" then
            line.label:SetPoint("RIGHT", line.frame, "RIGHT", 0, 0)
            line.label:SetJustifyH("RIGHT")
            line.value:SetPoint("RIGHT", line.label, "LEFT", -5, 0)
            line.value:SetJustifyH("RIGHT")
        elseif alignMode == "center" then
            line.label:SetJustifyH("LEFT")
            line.value:SetJustifyH("LEFT")
        else
            line.label:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
            line.label:SetJustifyH("LEFT")
            line.value:SetPoint("RIGHT", line.frame, "RIGHT", 0, 0)
            line.value:SetJustifyH("RIGHT")
        end
        local textAlpha = db.textAlpha or 1
        local sr, sg, sb = ns.GetStatColor(stat.id)
        line.label:SetTextColor(sr, sg, sb, textAlpha)
        line.value:SetTextColor(sr, sg, sb, textAlpha)
        local labelText = db.useShortNames and stat.shortLabel or stat.label
        if db.showColon ~= false then
            labelText = labelText .. ":"
        end
        line.label:SetText(labelText)
        line.value:SetText(FormatStatValue(stat, db))
        local valueWidth = SafeStringWidth(line.value, 0)
        if stat.id == "movespeed" and alignMode ~= "center" then
            local savedText = line.value:GetText()
            line.value:SetText("999.99%")
            valueWidth = SafeStringWidth(line.value, valueWidth)
            line.value:SetText(savedText)
        end
        if alignMode == "center" then
            local labelWidth = SafeStringWidth(line.label, 0)
            local gap = 4
            local totalWidth = labelWidth + gap + valueWidth
            local startX = -totalWidth / 2
            line.label:SetPoint("LEFT", line.frame, "CENTER", startX, 0)
            line.value:SetPoint("LEFT", line.label, "RIGHT", gap, 0)
        end
        line.frame:Show()
        local labelWidth = SafeStringWidth(line.label, 0)
        valueWidth = SafeStringWidth(line.value, 0)
        if stat.percent and not isHorizontal then
            if not cachedPercentWidth then
                local savedText = line.value:GetText()
                line.value:SetText("1000.00%")
                cachedPercentWidth = SafeStringWidth(line.value, 60)
                line.value:SetText(savedText)
            end
            valueWidth = cachedPercentWidth
        end
        local lineWidth = labelWidth + valueWidth + 10
        if lineWidth > maxWidth then
            maxWidth = lineWidth
        end
        if rowHeight > maxHeight then
            maxHeight = rowHeight
        end
        if isHorizontal then
            local statWidth = H_PAD + labelWidth + H_GAP + valueWidth + H_PAD
            line.frame:SetWidth(statWidth)
            xPosition = xPosition + statWidth
            if db.showSeparator and lineIndex < #stats then
                local sep = separators[lineIndex]
                if not sep then
                    sep = frame:CreateFontString(nil, "OVERLAY")
                    separators[lineIndex] = sep
                end
                sep:SetFont(fontPath, db.fontSize, db.fontOutline)
                sep:SetText("|")
                local sepColor = db.separatorColor or { r = 0.5, g = 0.5, b = 0.5 }
                sep:SetTextColor(sepColor.r, sepColor.g, sepColor.b, textAlpha)
                sep:ClearAllPoints()
                sep:SetPoint("LEFT", frame, "TOPLEFT", xPosition + (H_SPACING / 2) - (SafeStringWidth(sep, 0) / 2), yPosition - (rowHeight / 2))
                sep:Show()
            end
            xPosition = xPosition + H_SPACING
        else
            yPosition = yPosition - rowHeight
        end
    end
    if lineIndex == 0 then
        frame:SetSize(0, 0)
        return
    end
    local padding = 20
    local finalWidth, finalHeight
    if isHorizontal then
        finalWidth = xPosition - H_SPACING + H_PAD + 10
        finalHeight = maxHeight + padding
    else
        local contentWidth = maxWidth + padding
        if contentWidth > cachedWidth then
            cachedWidth = contentWidth
        end
        finalWidth = cachedWidth
        finalHeight = (lineIndex * rowHeight) + padding
    end
    frame:SetSize(ns.PixelRound(finalWidth), ns.PixelRound(finalHeight))
end
function StatsFrame:RefreshMovementSpeedOnly()
    if not frame or not frame:IsShown() then return end
    if not moveSpeedLineIndex then return end
    local line = lines[moveSpeedLineIndex]
    if not line then return end
    local db = ns.db or ns.DEFAULTS
    local fontPath = ns.GetFontPath(db.fontFace)
    line.value:SetFont(fontPath, db.fontSize, db.fontOutline or "")
    local def = ns.STAT_DEFS and ns.STAT_DEFS.movespeed
    if not def or not def.api then return end
    local ok, value = pcall(def.api)
    if not ok or value == nil then return end
    line.value:SetText(ns.FormatPercent(value, ns.GetDecimals(db.decimals)))
end
function StatsFrame:SavePosition()
    if not frame or not ns.db then return end
    local frameWidth, frameHeight = frame:GetSize()
    local frameLeft, frameBottom = frame:GetLeft(), frame:GetBottom()
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local anchor = ns.db.anchor or "LEFT"
    local x, y
    if anchor == "LEFT" or anchor == "TOPLEFT" or anchor == "BOTTOMLEFT" then
        x = frameLeft
    elseif anchor == "RIGHT" or anchor == "TOPRIGHT" or anchor == "BOTTOMRIGHT" then
        x = frameLeft + frameWidth - screenWidth
    else
        x = frameLeft + frameWidth/2 - screenWidth/2
    end
    if anchor == "TOP" or anchor == "TOPLEFT" or anchor == "TOPRIGHT" then
        y = frameBottom + frameHeight - screenHeight
    elseif anchor == "BOTTOM" or anchor == "BOTTOMLEFT" or anchor == "BOTTOMRIGHT" then
        y = frameBottom
    else
        y = frameBottom + frameHeight/2 - screenHeight/2
    end
    ns.db.x = ns.PixelRound(x)
    ns.db.y = ns.PixelRound(y)
    if ns.MarkProfileDirty then
        ns.MarkProfileDirty()
    end
end
function StatsFrame:RestorePosition()
    if not frame or not ns.db then return end
    frame:ClearAllPoints()
    local anchor = ns.db.anchor or "LEFT"
    local anchorTo = ns.db.anchorTo or "LEFT"
    frame:SetPoint(anchor, UIParent, anchorTo, ns.PixelRound(ns.db.x), ns.PixelRound(ns.db.y))
end
function StatsFrame:ResetPosition()
    if not ns.db then return end
    ns.db.anchor = ns.DEFAULTS.anchor
    ns.db.anchorTo = ns.DEFAULTS.anchorTo
    ns.db.x = ns.DEFAULTS.x
    ns.db.y = ns.DEFAULTS.y
    self:RestorePosition()
    self:Refresh()
end
local function OnMoveSpeedUpdate()
    if not frame or not frame:IsShown() then return end
    if moveSpeedLineIndex then
        ns.StatsFrame:RefreshMovementSpeedOnly()
    elseif ns._playerMoving then
        ns.Stats:Invalidate()
        ns.StatsFrame:Refresh()
    end
end
local function OnFrameUpdate(_, elapsed)
    moveSpeedElapsed = moveSpeedElapsed + (elapsed or 0)
    if moveSpeedElapsed < MOVE_SPEED_UPDATE_INTERVAL then return end
    moveSpeedElapsed = 0
    OnMoveSpeedUpdate()
end
function StatsFrame:Show()
    if not frame then
        self:Create()
    end
    frame:Show()
    ns.db.showFrame = true
    self:Refresh()
    moveSpeedElapsed = MOVE_SPEED_UPDATE_INTERVAL
    frame:SetScript("OnUpdate", OnFrameUpdate)
end
function StatsFrame:Hide()
    if frame then
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
    end
    ns.db.showFrame = false
end
function StatsFrame:Toggle()
    if frame and frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
function StatsFrame:IsShown()
    return frame and frame:IsShown()
end
function StatsFrame:GetFrame()
    return frame
end
