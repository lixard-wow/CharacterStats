local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local Rep = {}
ns.WindowReputation = Rep
local ROW = 30
local KIND_STANDARD, KIND_FRIEND, KIND_MAJOR = 1, 2, 3
local function KindOf(data)
    local friend = C_GossipInfo and C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(data.factionID)
    if friend and friend.friendshipFactionID and friend.friendshipFactionID > 0 then
        return KIND_FRIEND, friend
    end
    if C_Reputation.IsMajorFaction(data.factionID) then
        return KIND_MAJOR
    end
    return KIND_STANDARD
end
local function Progress(current, max)
    return string.format(REPUTATION_PROGRESS_FORMAT or "%s / %s", BreakUpLargeNumbers(current), BreakUpLargeNumbers(max))
end
function Rep.BarInfo(data)
    local kind, friend = KindOf(data)
    local info = { kind = kind }
    if kind == KIND_FRIEND then
        local capped = friend.nextThreshold == nil
        local min, max, cur = 0, 1, 1
        if not capped then
            min, max, cur = friend.reactionThreshold, friend.nextThreshold, friend.standing
        end
        info.max, info.value = max - min, cur - min
        info.progress = not capped and Progress(info.value, info.max) or nil
        info.standing = friend.reaction
        info.color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[5]
    elseif kind == KIND_MAJOR then
        local major = C_MajorFactions.GetMajorFactionData(data.factionID)
        local capped = C_MajorFactions.HasMaximumRenown(data.factionID)
        local max, cur = 1, 1
        if not capped then
            max = major and major.renownLevelThreshold or 0
            cur = major and major.renownReputationEarned or 0
        end
        info.max, info.value = max, cur
        info.progress = not capped and Progress(cur, max) or nil
        info.standing = string.format(RENOWN_LEVEL_LABEL or "Renown %d", major and major.renownLevel or 0)
        info.color = BLUE_FONT_COLOR
    else
        local capped = data.reaction == MAX_REPUTATION_REACTION
        local min, max, cur = 0, 1, 1
        if not capped then
            min, max, cur = data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
        end
        info.max, info.value = max - min, cur - min
        info.progress = not capped and Progress(info.value, info.max) or nil
        info.standing = GetText("FACTION_STANDING_LABEL" .. (data.reaction or 4), UnitSex("player"))
        info.color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[data.reaction or 4]
    end
    info.color = info.color or { r = 0.6, g = 0.6, b = 0.6 }
    return info
end
function Rep.GetRows()
    local rows = {}
    for index = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(index)
        if data then
            data.factionIndex = index
            rows[#rows + 1] = data
        end
    end
    return rows
end
local function ShowRowTooltip(row)
    local data = row.data
    if not data or data.isHeader and not data.isHeaderWithRep then return end
    local factionID = data.factionID
    if C_Reputation.IsFactionParagonForCurrentPlayer(factionID) and ReputationParagonFrame_SetupParagonTooltip and EmbeddedItemTooltip then
        row.factionID = factionID
        EmbeddedItemTooltip:SetOwner(row, "ANCHOR_RIGHT")
        ReputationParagonFrame_SetupParagonTooltip(row)
        EmbeddedItemTooltip:Show()
        return
    end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    local kind, friend = KindOf(data)
    if kind == KIND_MAJOR and RenownRewardUtil and RenownRewardUtil.AddMajorFactionToTooltip then
        RenownRewardUtil.AddMajorFactionToTooltip(GameTooltip, factionID, function() ShowRowTooltip(row) end)
    elseif kind == KIND_FRIEND then
        local ranks = C_GossipInfo.GetFriendshipReputationRanks(friend.friendshipFactionID)
        local title = friend.name
        if ranks and ranks.maxLevel and ranks.maxLevel > 0 then
            title = string.format("%s (%d / %d)", friend.name, ranks.currentLevel, ranks.maxLevel)
        end
        GameTooltip:SetText(title, 1, 1, 1)
        if ReputationUtil and ReputationUtil.TryAppendAccountReputationLineToTooltip then
            ReputationUtil.TryAppendAccountReputationLineToTooltip(GameTooltip, factionID)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(friend.text, nil, nil, nil, true)
        if friend.nextThreshold then
            GameTooltip:AddLine(string.format("%s (%d / %d)", friend.reaction, friend.standing - friend.reactionThreshold, friend.nextThreshold - friend.reactionThreshold), 1, 1, 1, true)
        else
            GameTooltip:AddLine(friend.reaction, 1, 1, 1, true)
        end
    else
        GameTooltip:SetText(data.name, 1, 1, 1)
        if ReputationUtil and ReputationUtil.TryAppendAccountReputationLineToTooltip then
            ReputationUtil.TryAppendAccountReputationLineToTooltip(GameTooltip, factionID)
        end
    end
    if REPUTATION_BUTTON_TOOLTIP_CLICK_INSTRUCTION then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(REPUTATION_BUTTON_TOOLTIP_CLICK_INSTRUCTION, 0.1, 1, 0.1, true)
    end
    GameTooltip:Show()
end
local function HideRowTooltip()
    GameTooltip:Hide()
    if EmbeddedItemTooltip then EmbeddedItemTooltip:Hide() end
end
local function Solid(parent, color, layer, sublevel)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return t
end
local function CreateCheck(parent, ui, label, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(220, 22)
    b.box = Solid(b, ui.boxEdge or ui.muted, "ARTWORK")
    b.box:SetSize(16, 16)
    b.box:SetPoint("LEFT")
    b.inner = Solid(b, ui.boxFill or { 0, 0, 0, 0.6 }, "ARTWORK", 1)
    b.inner:SetPoint("TOPLEFT", b.box, "TOPLEFT", 1, -1)
    b.inner:SetPoint("BOTTOMRIGHT", b.box, "BOTTOMRIGHT", -1, 1)
    b.mark = Solid(b, ui.accent, "ARTWORK", 2)
    b.mark:SetPoint("TOPLEFT", b.box, "TOPLEFT", 4, -4)
    b.mark:SetPoint("BOTTOMRIGHT", b.box, "BOTTOMRIGHT", -4, 4)
    b.label = ui.Text(b, ui.bodyFont, 13, ui.text)
    b.label:SetPoint("LEFT", b.box, "RIGHT", 8, 0)
    b.label:SetText(label)
    b:SetScript("OnClick", onClick)
    function b:SetState(checked, enabled, color)
        self.mark:SetShown(checked and true or false)
        self:SetEnabled(enabled ~= false)
        local c = (enabled == false) and ui.muted or (color or ui.text)
        self.label:SetTextColor(c[1], c[2], c[3])
        self:SetAlpha(enabled == false and 0.6 or 1)
    end
    return b
end
function Rep.Create(parent, ui)
    local rep = CreateFrame("Frame", nil, parent)
    rep:EnableMouse(true)
    rep.list = CreateFrame("Frame", nil, rep)
    rep.detail = CreateFrame("Frame", nil, rep)
    local filterBar = CreateFrame("Frame", nil, rep.list)
    filterBar:SetPoint("TOPLEFT", 0, 0)
    filterBar:SetPoint("TOPRIGHT", 0, 0)
    filterBar:SetHeight(28)
    rep.filters = {}
    local sortTypes = {
        { value = Enum.ReputationSortType and Enum.ReputationSortType.None or 0, label = REPUTATION_SORT_TYPE_SHOW_ALL or "All" },
        { value = Enum.ReputationSortType and Enum.ReputationSortType.Account or 1, label = REPUTATION_SORT_TYPE_ACCOUNT or "Warband" },
        { value = Enum.ReputationSortType and Enum.ReputationSortType.Character or 2, label = UnitName("player") or "" },
    }
    local previous
    for _, sort in ipairs(sortTypes) do
        local b = ui.Button(filterBar, 92, 24, sort.label)
        if previous then
            b:SetPoint("LEFT", previous, "RIGHT", 4, 0)
        else
            b:SetPoint("LEFT", filterBar, "LEFT", 0, 0)
        end
        b:SetScript("OnClick", function()
            C_Reputation.SetReputationSortType(sort.value)
            rep:Refresh()
        end)
        b.sortType = sort.value
        rep.filters[#rep.filters + 1] = b
        previous = b
    end
    rep.legacy = CreateCheck(filterBar, ui, REPUTATION_CHECKBOX_SHOW_LEGACY_REPUTATIONS or "Show Legacy Reputations", function()
        C_Reputation.SetLegacyReputationsShown(not C_Reputation.AreLegacyReputationsShown())
        rep:Refresh()
    end)
    rep.legacy:SetPoint("LEFT", previous, "RIGHT", 12, 0)
    rep.legacy:SetWidth(200)
    local listArea = CreateFrame("Frame", nil, rep.list)
    listArea:SetPoint("TOPLEFT", 0, -34)
    listArea:SetPoint("BOTTOMRIGHT", 0, 0)
    rep.scroll = Parts.CreateList(listArea, ROW, function(listParent)
        local row = CreateFrame("Button", nil, listParent)
        row:RegisterForClicks("LeftButtonUp")
        row.bg = Solid(row, ui.rowFill or { 1, 1, 1, 0.03 })
        row.bg:SetPoint("TOPLEFT", 0, -1)
        row.bg:SetPoint("BOTTOMRIGHT", 0, 1)
        row.sel = Solid(row, { ui.accent[1], ui.accent[2], ui.accent[3], 0.16 }, "BACKGROUND", 1)
        row.sel:SetAllPoints(row.bg)
        row.hl = row:CreateTexture(nil, "HIGHLIGHT")
        row.hl:SetAllPoints(row.bg)
        row.hl:SetColorTexture(1, 1, 1, 0.06)
        row.toggleButton = CreateFrame("Button", nil, row)
        row.toggleButton:SetSize(22, 22)
        row.toggleButton:SetScript("OnClick", function()
            local data = row.data
            if not data or not data.isHeader then return end
            if data.isCollapsed then C_Reputation.ExpandFactionHeader(data.factionIndex) else C_Reputation.CollapseFactionHeader(data.factionIndex) end
        end)
        row.toggle = ui.Text(row.toggleButton, ui.boldFont, 15, ui.accent)
        row.toggle:SetPoint("CENTER")
        row.name = ui.Text(row, ui.bodyFont, 13, ui.text)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.tag = ui.Text(row, ui.bodyFont, 11, ui.muted)
        row.bar = CreateFrame("StatusBar", nil, row)
        row.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
        row.bar:SetHeight(16)
        row.bar:SetPoint("RIGHT", row, "RIGHT", -30, 0)
        row.bar:SetWidth(ui.barWidth or 180)
        row.bar.bg = Solid(row.bar, ui.barTrack or { 0, 0, 0, 0.5 })
        row.bar.bg:SetAllPoints()
        row.bar.text = ui.Text(row.bar, ui.boldFont, 11, { 1, 1, 1 })
        Parts.SetFont(row.bar.text, ui.boldFont, 11, "OUTLINE")
        row.bar.text:SetPoint("CENTER")
        row.paragon = row:CreateTexture(nil, "ARTWORK")
        row.paragon:SetSize(18, 18)
        row.paragon:SetPoint("LEFT", row.bar, "RIGHT", 6, 0)
        row.paragon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
        row.paragon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.paragonGlow = row:CreateTexture(nil, "ARTWORK", nil, -1)
        row.paragonGlow:SetTexture(ns.Theme.ART .. "glow_radial")
        row.paragonGlow:SetPoint("TOPLEFT", row.paragon, "TOPLEFT", -8, 8)
        row.paragonGlow:SetPoint("BOTTOMRIGHT", row.paragon, "BOTTOMRIGHT", 8, -8)
        row.paragonGlow:SetVertexColor(1, 0.82, 0.2, 0.9)
        row.paragonGlow:SetBlendMode("ADD")
        row:SetScript("OnClick", function(self)
            local data = self.data
            if not data then return end
            if data.isHeader and not data.isHeaderWithRep then
                if data.isCollapsed then C_Reputation.ExpandFactionHeader(data.factionIndex) else C_Reputation.CollapseFactionHeader(data.factionIndex) end
                return
            end
            local selected = C_Reputation.GetSelectedFaction() == data.factionIndex
            C_Reputation.SetSelectedFaction(selected and 0 or data.factionIndex)
            HideRowTooltip()
            rep:Refresh()
        end)
        row:SetScript("OnEnter", function(self)
            if self.progress then self.bar.text:SetText(self.progress) end
            if C_Reputation.GetSelectedFaction() ~= (self.data and self.data.factionIndex) then ShowRowTooltip(self) end
        end)
        row:SetScript("OnLeave", function(self)
            if self.standing then self.bar.text:SetText(self.standing) end
            HideRowTooltip()
        end)
        return row
    end, function(row, data)
        row.data = data
        local topHeader = data.isHeader and not data.isChild
        local subHeader = data.isHeader and data.isChild
        local indent = topHeader and 0 or (subHeader and 14 or (data.isChild and 40 or 18))
        row.toggleButton:ClearAllPoints()
        row.toggleButton:SetPoint("LEFT", row, "LEFT", indent, 0)
        row.toggleButton:SetShown(data.isHeader and true or false)
        row.toggle:SetText(data.isCollapsed and "+" or "-")
        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row, "LEFT", indent + (data.isHeader and 22 or 8), 0)
        row.name:SetText(data.name or "")
        Parts.SetFont(row.name, topHeader and (ui.headerFont or ui.boldFont) or ui.bodyFont, topHeader and 15 or 13, ui.textFlags or "")
        local nc = topHeader and ui.accent or (data.atWarWith and { 1, 0.3, 0.25 } or ui.text)
        row.name:SetTextColor(nc[1], nc[2], nc[3])
        row.bg:SetShown(not topHeader)
        row.sel:SetShown(C_Reputation.GetSelectedFaction() == data.factionIndex)
        local hasBar = not data.isHeader or data.isHeaderWithRep
        row.bar:SetShown(hasBar)
        row.paragon:Hide()
        row.paragonGlow:Hide()
        row.tag:SetText("")
        row.progress, row.standing = nil, nil
        if hasBar then
            local info = Rep.BarInfo(data)
            row.bar:SetMinMaxValues(0, math.max(1, info.max))
            row.bar:SetValue(info.value)
            row.bar:SetStatusBarColor(info.color.r, info.color.g, info.color.b)
            row.standing = info.standing
            row.progress = info.progress
            row.bar.text:SetText(info.standing or "")
            if C_Reputation.IsFactionParagonForCurrentPlayer(data.factionID) then
                local _, _, _, pending, tooLow = C_Reputation.GetFactionParagonInfo(data.factionID)
                C_Reputation.RequestFactionParagonPreloadRewardData(data.factionID)
                row.paragon:Show()
                row.paragonGlow:SetShown(pending and not tooLow)
            end
            local tags = {}
            if data.isAccountWide then tags[#tags + 1] = ns.L.WINDOW_REP_WARBAND or "Warband" end
            if data.hasBonusRepGain then tags[#tags + 1] = ns.L.WINDOW_REP_BONUS or "Bonus" end
            if #tags > 0 then
                row.tag:ClearAllPoints()
                row.tag:SetPoint("RIGHT", row.bar, "LEFT", -8, 0)
                row.tag:SetText(table.concat(tags, " · "))
            end
            row.name:SetPoint("RIGHT", row.bar, "LEFT", #tags > 0 and -70 or -8, 0)
        else
            row.name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        end
    end)
    rep.detail.title = ui.Text(rep.detail, ui.headerFont or ui.boldFont, 18, ui.accent)
    rep.detail.title:SetPoint("TOPLEFT", 4, -4)
    rep.detail.title:SetPoint("TOPRIGHT", -4, -4)
    rep.detail.title:SetJustifyH("LEFT")
    rep.detail.standing = ui.Text(rep.detail, ui.bodyFont, 13, ui.muted)
    rep.detail.standing:SetPoint("TOPLEFT", rep.detail.title, "BOTTOMLEFT", 0, -4)
    rep.detail.desc = ui.Text(rep.detail, ui.bodyFont, 13, ui.text)
    rep.detail.desc:SetPoint("TOPLEFT", rep.detail.standing, "BOTTOMLEFT", 0, -10)
    rep.detail.desc:SetPoint("RIGHT", rep.detail, "RIGHT", -4, 0)
    rep.detail.desc:SetJustifyH("LEFT")
    rep.detail.desc:SetJustifyV("TOP")
    rep.detail.desc:SetHeight(180)
    rep.detail.atWar = CreateCheck(rep.detail, ui, AT_WAR or "At War", function()
        C_Reputation.ToggleFactionAtWar(C_Reputation.GetSelectedFaction())
        rep:Refresh()
    end)
    rep.detail.atWar:SetPoint("TOPLEFT", rep.detail.desc, "BOTTOMLEFT", 0, -10)
    rep.detail.inactive = CreateCheck(rep.detail, ui, MOVE_TO_INACTIVE or "Inactive", function()
        local index = C_Reputation.GetSelectedFaction()
        C_Reputation.SetFactionActive(index, not C_Reputation.IsFactionActive(index))
        rep:Refresh()
    end)
    rep.detail.inactive:SetPoint("TOPLEFT", rep.detail.atWar, "BOTTOMLEFT", 0, -6)
    rep.detail.watch = CreateCheck(rep.detail, ui, SHOW_FACTION_ON_MAINSCREEN or "Show as Experience Bar", function(self)
        local index = C_Reputation.GetSelectedFaction()
        local data = C_Reputation.GetFactionDataByIndex(index)
        C_Reputation.SetWatchedFactionByIndex((data and not data.isWatched) and index or 0)
        rep:Refresh()
    end)
    rep.detail.watch:SetPoint("TOPLEFT", rep.detail.inactive, "BOTTOMLEFT", 0, -6)
    rep.detail.renown = ui.Button(rep.detail, 170, 26, VIEW_RENOWN_BUTTON_LABEL or "View Renown")
    rep.detail.renown:SetPoint("TOPLEFT", rep.detail.watch, "BOTTOMLEFT", 0, -12)
    rep.detail.renown:SetScript("OnClick", function(self)
        if not self.factionID then return end
        if not EncounterJournal and EncounterJournal_LoadUI then EncounterJournal_LoadUI() end
        if EncounterJournal then
            if not EncounterJournal:IsShown() then ShowUIPanel(EncounterJournal) end
            if EJ_ContentTab_Select and EncounterJournal.JourneysTab then
                EJ_ContentTab_Select(EncounterJournal.JourneysTab:GetID())
            end
            if EncounterJournalJourneysFrame and EncounterJournalJourneysFrame.ResetView then
                EncounterJournalJourneysFrame:ResetView(nil, self.factionID)
            end
        end
    end)
    rep.detail.empty = ui.Text(rep.detail, ui.bodyFont, 13, ui.muted)
    rep.detail.empty:SetPoint("TOPLEFT", 4, -8)
    rep.detail.empty:SetPoint("RIGHT", -4, 0)
    rep.detail.empty:SetJustifyH("LEFT")
    rep.detail.empty:SetText(ns.L.WINDOW_REP_PICK or "Select a faction to see its details and options.")
    function rep:RefreshDetail()
        local d = self.detail
        local index = C_Reputation.GetSelectedFaction()
        local data = index and index > 0 and C_Reputation.GetFactionDataByIndex(index)
        local valid = data and data.factionID and data.factionID > 0
        d.empty:SetShown(not valid)
        for _, part in ipairs({ d.title, d.standing, d.desc, d.atWar, d.inactive, d.watch }) do part:SetShown(valid and true or false) end
        d.renown:Hide()
        if not valid then return end
        d.title:SetText(data.name)
        local info = Rep.BarInfo(data)
        d.standing:SetText((info.standing or "") .. (info.progress and ("  ·  " .. info.progress) or ""))
        d.desc:SetText(data.description or "")
        local canWar = data.canToggleAtWar and not data.isHeader
        d.atWar:SetState(data.atWarWith, canWar, canWar and { 1, 0.3, 0.25 } or nil)
        d.inactive:SetState(not C_Reputation.IsFactionActive(index), data.canSetInactive)
        d.watch:SetState(data.isWatched, true)
        if C_Reputation.IsMajorFaction(data.factionID) then
            local major = C_MajorFactions.GetMajorFactionData(data.factionID)
            d.renown.factionID = data.factionID
            d.renown:SetEnabled(major and major.isUnlocked or false)
            d.renown:SetAlpha((major and major.isUnlocked) and 1 or 0.5)
            d.renown:Show()
        end
    end
    function rep:Refresh()
        local sortType = C_Reputation.GetReputationSortType()
        for _, b in ipairs(self.filters) do
            if b.SetSelected then b:SetSelected(b.sortType == sortType) end
        end
        self.legacy:SetShown(GetExpansionLevel() == GetServerExpansionLevel())
        self.legacy:SetState(C_Reputation.AreLegacyReputationsShown(), true)
        self.scroll:SetData(Rep.GetRows())
        self:RefreshDetail()
    end
    return rep
end
