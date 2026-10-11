local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local Cur = {}
ns.WindowCurrency = Cur
Cur.title = ns.L.WINDOW_TAB_CURRENCY or "Currency"
local ROW = 28
local function Amount(n)
    return BreakUpLargeNumbers(n or 0)
end
function Cur.GetRows()
    local rows = {}
    for index = 1, C_CurrencyInfo.GetCurrencyListSize() do
        local data = C_CurrencyInfo.GetCurrencyListInfo(index)
        if data then
            data.currencyIndex = index
            rows[#rows + 1] = data
        end
    end
    return rows
end
local function MaxWatched()
    if BackpackTokenFrame and BackpackTokenFrame.GetMaxTokensWatched then
        return BackpackTokenFrame:GetMaxTokensWatched()
    end
    return 3
end
local function NumWatched()
    if GetNumWatchedTokens then return GetNumWatchedTokens() end
    return 0
end
function Cur.SetWatched(index, watched)
    if watched and NumWatched() >= MaxWatched() then
        UIErrorsFrame:AddMessage(string.format(TOO_MANY_WATCHED_TOKENS or "You can only track %d currencies.", MaxWatched()), 1, 0.1, 0.1, 1)
        return false
    end
    C_CurrencyInfo.SetCurrencyBackpack(index, watched)
    if BackpackTokenFrame and BackpackTokenFrame.Update then
        BackpackTokenFrame:Update()
    end
    return true
end
local function ShowTooltip(row)
    local data = row.data
    if not data or data.isHeader then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetCurrencyToken(data.currencyIndex)
    if data.isAccountTransferable and data.transferPercentage then
        local lost = 100 - data.transferPercentage
        if lost > 0 and CURRENCY_TRANSFER_LOSS then
            GameTooltip:AddLine(string.format(CURRENCY_TRANSFER_LOSS, math.ceil(lost)), 1, 0.82, 0)
        end
    end
    GameTooltip:Show()
end
function Cur.Create(parent, ui)
    local cur = CreateFrame("Frame", nil, parent)
    cur:EnableMouse(true)
    cur.list = CreateFrame("Frame", nil, cur)
    cur.detail = CreateFrame("Frame", nil, cur)
    cur.selected = false
    cur.selectedID = false
    cur.showLog = false
    local bar = CreateFrame("Frame", nil, cur.list)
    bar:SetPoint("TOPLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", 0, 0)
    bar:SetHeight(28)
    cur.filterText = ui.Text(bar, ui.bodyFont, 12, ui.muted)
    cur.filterText:SetPoint("LEFT", bar, "LEFT", 2, 0)
    cur.blizzard = ui.Button(bar, 170, 24, ns.L.WINDOW_CUR_FILTER_TRANSFER or "Filter & Transfer")
    cur.blizzard:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    cur.blizzard:SetScript("OnClick", function() ns.Window.ShowBlizzard("TokenFrame") end)
    cur.blizzard:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(ns.L.WINDOW_CUR_FILTER_TRANSFER or "Filter & Transfer", 1, 1, 1)
        GameTooltip:AddLine(ns.L.WINDOW_CUR_BLIZZARD_TIP or "Opens Blizzard's currency page to change the filter or transfer currency. Your window returns when you switch tabs or reopen it.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    cur.blizzard:HookScript("OnLeave", GameTooltip_Hide)
    cur.logButton = ui.Button(bar, 110, 24, ns.L.WINDOW_CUR_LOG or "Transfer Log")
    cur.logButton:SetPoint("RIGHT", cur.blizzard, "LEFT", -6, 0)
    cur.logButton:SetScript("OnClick", function()
        cur.showLog = not cur.showLog
        cur:RefreshDetail()
    end)
    cur.loading = ui.Text(cur.list, ui.bodyFont, 13, ui.muted)
    cur.loading:SetPoint("TOP", cur.list, "TOP", 0, -60)
    cur.loading:SetText(ns.L.WINDOW_CUR_LOADING or "Loading warband currencies...")
    local listArea = CreateFrame("Frame", nil, cur.list)
    listArea:SetPoint("TOPLEFT", 0, -34)
    listArea:SetPoint("BOTTOMRIGHT", 0, 0)
    cur.scroll = Parts.CreateList(listArea, ROW, function(listParent)
        local row = CreateFrame("Button", nil, listParent)
        row:RegisterForClicks("LeftButtonUp")
        row.bg = Parts.Solid(row, ui.rowFill or { 1, 1, 1, 0.03 })
        row.bg:SetPoint("TOPLEFT", 0, -1)
        row.bg:SetPoint("BOTTOMRIGHT", 0, 1)
        row.sel = Parts.Solid(row, { ui.accent[1], ui.accent[2], ui.accent[3], 0.16 }, "BACKGROUND", 1)
        row.sel:SetAllPoints(row.bg)
        row.hl = row:CreateTexture(nil, "HIGHLIGHT")
        row.hl:SetAllPoints(row.bg)
        row.hl:SetColorTexture(1, 1, 1, 0.06)
        row.toggle = ui.Text(row, ui.boldFont, 15, ui.accent)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.name = ui.Text(row, ui.bodyFont, 13, ui.text)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.tag = ui.Text(row, ui.bodyFont, 11, ui.muted)
        row.amount = ui.Text(row, ui.boldFont, 13, ui.text)
        row.amount:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.amount:SetJustifyH("RIGHT")
        row.watch = Parts.Solid(row, ui.accent, "ARTWORK")
        row.watch:SetSize(4, 18)
        row.watch:SetPoint("LEFT", row, "LEFT", 0, 0)
        row:SetScript("OnClick", function(self)
            local data = self.data
            if not data then return end
            if data.isHeader then
                C_CurrencyInfo.ExpandCurrencyList(data.currencyIndex, not data.isHeaderExpanded)
                cur:Refresh()
                return
            end
            if IsModifiedClick("CHATLINK") then
                local link = C_CurrencyInfo.GetCurrencyListLink(data.currencyIndex)
                if link and HandleModifiedItemClick(link) then return end
            end
            if IsModifiedClick("TOKENWATCHTOGGLE") then
                Cur.SetWatched(data.currencyIndex, not data.isShowInBackpack)
                cur:Refresh()
                return
            end
            cur.selectedID = cur.selectedID ~= data.currencyID and data.currencyID or false
            cur.showLog = false
            GameTooltip:Hide()
            cur:Refresh()
        end)
        row:SetScript("OnEnter", function(self)
            if cur.selectedID ~= (self.data and self.data.currencyID) then ShowTooltip(self) end
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        return row
    end, function(row, data)
        row.data = data
        local depth = data.currencyListDepth or 0
        local indent = depth * 14
        row.toggle:ClearAllPoints()
        row.toggle:SetPoint("LEFT", row, "LEFT", indent + 6, 0)
        row.toggle:SetText(data.isHeader and (data.isHeaderExpanded and "-" or "+") or "")
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", row, "LEFT", indent + 10, 0)
        row.icon:SetShown(not data.isHeader)
        row.icon:SetTexture(data.iconFileID)
        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row, "LEFT", indent + (data.isHeader and 24 or 38), 0)
        row.name:SetPoint("RIGHT", row.amount, "LEFT", -80, 0)
        row.name:SetText(data.name or "")
        local top = data.isHeader and depth == 0
        Parts.SetFont(row.name, top and (ui.headerFont or ui.boldFont) or ui.bodyFont, top and 15 or 13, ui.textFlags or "")
        local nc = data.isHeader and ui.accent or ui.text
        if not data.isHeader and data.quality and C_Item and C_Item.GetItemQualityColor and ui.qualityColors then
            local r, g, b = C_Item.GetItemQualityColor(data.quality)
            nc = { r, g, b }
        end
        row.name:SetTextColor(nc[1], nc[2], nc[3])
        row.bg:SetShown(not top)
        row.sel:SetShown(not data.isHeader and cur.selectedID == data.currencyID)
        row.watch:SetShown(not data.isHeader and data.isShowInBackpack)
        if data.isHeader then
            row.amount:SetText("")
            row.tag:SetText("")
            return
        end
        local amount = Amount(data.quantity)
        if data.maxQuantity and data.maxQuantity > 0 then
            amount = amount .. " / " .. Amount(data.maxQuantity)
        end
        row.amount:SetText(amount)
        local tags = {}
        if data.isAccountWide then tags[#tags + 1] = ns.L.WINDOW_REP_WARBAND or "Warband"
        elseif data.isAccountTransferable then tags[#tags + 1] = ns.L.WINDOW_CUR_TRANSFERABLE or "Transferable" end
        row.tag:ClearAllPoints()
        row.tag:SetPoint("RIGHT", row.amount, "LEFT", -10, 0)
        row.tag:SetText(table.concat(tags, " · "))
    end)
    local d = cur.detail
    d.icon = d:CreateTexture(nil, "ARTWORK")
    d.icon:SetSize(36, 36)
    d.icon:SetPoint("TOPLEFT", 4, -4)
    d.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    d.title = ui.Text(d, ui.headerFont or ui.boldFont, 17, ui.accent)
    d.title:SetPoint("TOPLEFT", d.icon, "TOPRIGHT", 10, 0)
    d.title:SetPoint("RIGHT", d, "RIGHT", -4, 0)
    d.title:SetJustifyH("LEFT")
    d.amount = ui.Text(d, ui.boldFont, 14, ui.text)
    d.amount:SetPoint("BOTTOMLEFT", d.icon, "BOTTOMRIGHT", 10, 0)
    d.lines = ui.Text(d, ui.bodyFont, 13, ui.text)
    d.lines:SetPoint("TOPLEFT", d.icon, "BOTTOMLEFT", 0, -12)
    d.lines:SetPoint("RIGHT", d, "RIGHT", -4, 0)
    d.lines:SetJustifyH("LEFT")
    d.lines:SetSpacing(3)
    d.desc = ui.Text(d, ui.bodyFont, 12, ui.muted)
    d.desc:SetPoint("TOPLEFT", d.lines, "BOTTOMLEFT", 0, -10)
    d.desc:SetPoint("RIGHT", d, "RIGHT", -4, 0)
    d.desc:SetJustifyH("LEFT")
    d.desc:SetHeight(120)
    d.desc:SetJustifyV("TOP")
    d.unused = Parts.CreateCheck(d, ui, UNUSED or "Unused", function()
        local data = cur.selected
        if data then C_CurrencyInfo.SetCurrencyUnused(data.currencyIndex, not data.isTypeUnused) end
        cur:Refresh()
    end)
    d.unused:SetPoint("TOPLEFT", d.desc, "BOTTOMLEFT", 0, -8)
    d.backpack = Parts.CreateCheck(d, ui, SHOW_ON_BACKPACK or "Show on Backpack", function()
        local data = cur.selected
        if data then Cur.SetWatched(data.currencyIndex, not data.isShowInBackpack) end
        cur:Refresh()
    end)
    d.backpack:SetPoint("TOPLEFT", d.unused, "BOTTOMLEFT", 0, -6)
    d.transfer = ui.Button(d, 170, 26, ns.L.WINDOW_CUR_TRANSFER or "Transfer...")
    d.transfer:SetPoint("TOPLEFT", d.backpack, "BOTTOMLEFT", 0, -12)
    d.transfer:SetScript("OnClick", function() ns.Window.ShowBlizzard("TokenFrame") end)
    d.empty = ui.Text(d, ui.bodyFont, 13, ui.muted)
    d.empty:SetPoint("TOPLEFT", 4, -8)
    d.empty:SetPoint("RIGHT", -4, 0)
    d.empty:SetJustifyH("LEFT")
    d.empty:SetText(ns.L.WINDOW_CUR_PICK or "Select a currency to see its details and options.")
    d.log = ui.Text(d, ui.bodyFont, 12, ui.text)
    d.log:SetPoint("TOPLEFT", 4, -30)
    d.log:SetPoint("RIGHT", -4, 0)
    d.log:SetJustifyH("LEFT")
    d.log:SetJustifyV("TOP")
    d.log:SetSpacing(4)
    d.logTitle = ui.Text(d, ui.headerFont or ui.boldFont, 17, ui.accent)
    d.logTitle:SetPoint("TOPLEFT", 4, -4)
    d.logTitle:SetText(ns.L.WINDOW_CUR_LOG or "Transfer Log")
    local function ShowParts(list, shown)
        for _, part in ipairs(list) do part:SetShown(shown) end
    end
    function cur:RefreshDetail()
        local details = { d.icon, d.title, d.amount, d.lines, d.desc, d.unused, d.backpack }
        if self.showLog then
            ShowParts(details, false)
            d.transfer:Hide()
            d.empty:Hide()
            d.logTitle:Show()
            d.log:Show()
            local entries = C_CurrencyInfo.FetchCurrencyTransferTransactions and C_CurrencyInfo.FetchCurrencyTransferTransactions() or {}
            local lines = {}
            for i = #entries, math.max(1, #entries - 14), -1 do
                local t = entries[i]
                local info = C_CurrencyInfo.GetCurrencyInfo(t.currencyType)
                lines[#lines + 1] = string.format("%s x%s  %s > %s", info and info.name or "?", Amount(t.quantityTransferred), t.sourceCharacterName or "?", t.destinationCharacterName or "?")
            end
            d.log:SetText(#lines > 0 and table.concat(lines, "\n") or (ns.L.WINDOW_CUR_LOG_EMPTY or "No transfers yet."))
            return
        end
        d.logTitle:Hide()
        d.log:Hide()
        local data = self.selected
        d.empty:SetShown(not data)
        ShowParts(details, data and true or false)
        d.transfer:Hide()
        if not data then return end
        d.icon:SetTexture(data.iconFileID)
        d.title:SetText(data.name)
        d.amount:SetText(Amount(data.quantity) .. ((data.maxQuantity and data.maxQuantity > 0) and (" / " .. Amount(data.maxQuantity)) or ""))
        local lines = {}
        if data.canEarnPerWeek and data.maxWeeklyQuantity and data.maxWeeklyQuantity > 0 then
            lines[#lines + 1] = string.format(ns.L.WINDOW_CUR_WEEKLY or "This week: %s / %s", Amount(data.quantityEarnedThisWeek), Amount(data.maxWeeklyQuantity))
        end
        if data.useTotalEarnedForMaxQty and data.maxQuantity and data.maxQuantity > 0 then
            lines[#lines + 1] = string.format(ns.L.WINDOW_CUR_TOTAL or "Total earned: %s / %s", Amount(data.totalEarned), Amount(data.maxQuantity))
        end
        if data.isAccountWide then
            lines[#lines + 1] = ns.L.WINDOW_CUR_ACCOUNT_WIDE or "Shared by your warband"
        elseif data.isAccountTransferable then
            local lost = data.transferPercentage and (100 - data.transferPercentage) or 0
            lines[#lines + 1] = lost > 0 and string.format(ns.L.WINDOW_CUR_TRANSFER_LOSS or "Transferable (%d%% lost)", math.ceil(lost)) or (ns.L.WINDOW_CUR_TRANSFERABLE or "Transferable")
        end
        d.lines:SetText(table.concat(lines, "\n"))
        d.desc:SetText(data.description or "")
        d.unused:SetState(data.isTypeUnused, true)
        d.backpack:SetState(data.isShowInBackpack, true)
        d.transfer:SetShown(data.isAccountTransferable and not data.isAccountWide and true or false)
    end
    function cur:Refresh()
        local filter = C_CurrencyInfo.GetCurrencyFilter and C_CurrencyInfo.GetCurrencyFilter()
        local onlyCharacter = Enum.CurrencyFilterType and filter == Enum.CurrencyFilterType.DiscoveredOnly
        self.filterText:SetText(onlyCharacter and string.format(ns.L.WINDOW_CUR_FILTER_CHAR or "Showing: %s", UnitName("player") or "")
            or (CURRENCY_FILTER_TYPE_TRANSFERABLE or ""))
        local needsAccount = C_CurrencyInfo.DoesCurrentFilterRequireAccountCurrencyData()
        local ready = not needsAccount or C_CurrencyInfo.IsAccountCharacterCurrencyDataReady()
        if not ready and C_CurrencyInfo.RequestCurrencyDataForAccountCharacters then
            C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
        end
        self.loading:SetShown(not ready)
        local rows = ready and Cur.GetRows() or {}
        self.selected = false
        for _, data in ipairs(rows) do
            if not data.isHeader and data.currencyID == self.selectedID then self.selected = data end
        end
        if not self.selected then self.selectedID = false end
        self.scroll:SetData(rows)
        self:RefreshDetail()
    end
    return cur
end
