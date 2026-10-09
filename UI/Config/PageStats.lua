local addonName, CS = ...
local ConfigPanel = CS.ConfigPanel
local ROW_HEIGHT = 26
local ROW_GAP = 2
local PRIMARY_STATS = { str = true, agi = true, int = true }
local function SetStatEnabled(statId, enabled)
    if not CS.db then return end
    CS.db.stats = CS.db.stats or {}
    CS.db.stats[statId] = enabled
    if PRIMARY_STATS[statId] then
        for primaryId in pairs(PRIMARY_STATS) do
            CS.db.stats[primaryId] = enabled
        end
    end
    ConfigPanel.RefreshStatsFrame()
end
local function MoveStatInOrder(fromIndex, toIndex)
    if not CS.db then return end
    local order = CS.db.statOrder
    if not order or #order == 0 then
        order = {}
        for i, statId in ipairs(CS.DEFAULTS.statOrder) do
            order[i] = statId
        end
    end
    if fromIndex < 1 or fromIndex > #order or toIndex < 1 or toIndex > #order then return end
    local item = table.remove(order, fromIndex)
    table.insert(order, toIndex, item)
    CS.db.statOrder = order
    ConfigPanel.RefreshStatsFrame()
end
local function IsCursorOver(region)
    local left, right, bottom, top = region:GetLeft(), region:GetRight(), region:GetBottom(), region:GetTop()
    if not left then return false end
    local x, y = GetCursorPosition()
    local scale = region:GetEffectiveScale()
    x, y = x / scale, y / scale
    return x >= left and x <= right and y >= bottom and y <= top
end
local function CreateStatsPage(container)
    local Widgets = CS.ConfigWidgets
    local L = CS.L
    local page = { rows = {}, orderIndices = {} }
    local header = Widgets.CreateSectionHeader(container, L.SECTION_SHOWN_STATS or "Shown Stats")
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -4)
    header:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -4)
    local hint = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    hint:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -6)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.HINT_STATS or "Drag to reorder. Click a color to change it, right-click to reset it.")
    Widgets.ApplyFontColor(hint, "textMuted", 0.8)
    local buttonBar = CreateFrame("Frame", nil, container)
    buttonBar:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    buttonBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    buttonBar:SetHeight(22)
    local buttons = {
        Widgets.CreateFlatButton(buttonBar, 90, 22, L.BTN_ENABLE_ALL or "Enable All"),
        Widgets.CreateFlatButton(buttonBar, 90, 22, L.BTN_DISABLE_ALL or "Disable All"),
        Widgets.CreateFlatButton(buttonBar, 90, 22, L.BTN_RESET_COLORS or "Reset Colors"),
        Widgets.CreateFlatButton(buttonBar, 90, 22, L.BTN_RESET_ORDER or "Reset Order"),
    }
    Widgets.NormalizeButtonWidths(buttons, 10)
    for i, btn in ipairs(buttons) do
        if i == 1 then
            btn:SetPoint("LEFT", buttonBar, "LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", buttons[i - 1], "RIGHT", 6, 0)
        end
    end
    local listFrame = CreateFrame("Frame", nil, container)
    listFrame:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8)
    listFrame:SetPoint("BOTTOMRIGHT", buttonBar, "TOPRIGHT", 0, 8)
    Widgets.CreateBorder(listFrame, 1)
    local scroll, content = ConfigPanel.CreateScrollPage(listFrame)
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 1, -1)
    scroll:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -1, 1)
    local function GetDragTargetIndex()
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / scroll:GetEffectiveScale()
        local localY = (content:GetTop() or 0) - cursorY
        local target = math.floor(localY / (ROW_HEIGHT + ROW_GAP)) + 1
        return math.max(1, math.min(page.visibleCount or 1, target))
    end
    function page:Refresh()
        local layoutStats = CS.Stats:GetLayoutList()
        local y = -2
        wipe(self.orderIndices)
        for index, stat in ipairs(layoutStats) do
            local key = stat.id
            self.orderIndices[index] = stat.orderIndex
            local row = self.rows[index]
            if not row then
                row = Widgets.CreateStatRow(content, index, ROW_HEIGHT)
                self.rows[index] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
            row:Show()
            row:SetAlt(index % 2 == 0)
            row.toggle.text:SetText(stat.label)
            row.toggle:SetChecked(stat.enabled)
            row.toggle:SetWidth(20 + row.toggle.text:GetStringWidth() + 8)
            row._visualIndex = index
            row._orderIndex = stat.orderIndex
            row.toggle:SetOnClick(function(toggle)
                SetStatEnabled(key, toggle:GetChecked())
                page:Refresh()
            end)
            row:SetScript("OnMouseUp", function(self, button)
                if button ~= "LeftButton" or self._dragging or IsCursorOver(self.swatch) then return end
                SetStatEnabled(key, not self.toggle:GetChecked())
                page:Refresh()
            end)
            local r, g, b = CS.GetStatColor(key)
            row.swatch.tex:SetColorTexture(r, g, b, 1)
            if key == "ilvl" then
                row.swatch:SetScript("OnClick", nil)
                row.swatch:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(L.TIP_ILVL_COLOR or "Item Level color is automatic based on item quality", nil, nil, nil, nil, true)
                    GameTooltip:Show()
                end)
                row.swatch:SetScript("OnLeave", GameTooltip_Hide)
            else
                row.swatch:SetScript("OnEnter", nil)
                row.swatch:SetScript("OnLeave", nil)
                row.swatch:SetScript("OnClick", function(swatch, button)
                    if not CS.db then return end
                    if button == "RightButton" then
                        if CS.db.statColors then
                            CS.db.statColors[key] = nil
                        end
                        swatch.tex:SetColorTexture(CS.GetStatColor(key))
                        ConfigPanel.RefreshStatsFrame()
                        return
                    end
                    local cr, cg, cb = CS.GetStatColor(key)
                    Widgets.OpenColorPicker(cr, cg, cb, function(nr, ng, nb)
                        CS.db.statColors = CS.db.statColors or {}
                        CS.db.statColors[key] = { r = nr, g = ng, b = nb }
                        swatch.tex:SetColorTexture(nr, ng, nb, 1)
                        ConfigPanel.RefreshStatsFrame()
                    end, function(pr, pg, pb)
                        CS.db.statColors = CS.db.statColors or {}
                        CS.db.statColors[key] = { r = pr, g = pg, b = pb }
                        swatch.tex:SetColorTexture(pr, pg, pb, 1)
                        ConfigPanel.RefreshStatsFrame()
                    end)
                end)
            end
            row._onDragStart = function(self)
                page.dragFrom = self._orderIndex
                page.dragFromVisual = self._visualIndex
            end
            row._onDragStop = function()
                if not page.dragFrom then return end
                local target = GetDragTargetIndex()
                if target ~= page.dragFromVisual and page.orderIndices[target] then
                    MoveStatInOrder(page.dragFrom, page.orderIndices[target])
                end
                page.dragFrom = nil
                page.dragFromVisual = nil
                page:Refresh()
            end
            y = y - ROW_HEIGHT - ROW_GAP
        end
        self.visibleCount = #layoutStats
        for i = #layoutStats + 1, #self.rows do
            self.rows[i]:Hide()
        end
        content:SetHeight(math.abs(y) + 4)
        CS.Theme.ApplyFonts(content)
    end
    buttons[1]:SetScript("OnClick", function()
        if not CS.db then return end
        CS.db.stats = CS.db.stats or {}
        for statId in pairs(CS.STAT_DEFS) do
            CS.db.stats[statId] = true
        end
        ConfigPanel.RefreshStatsFrame()
        page:Refresh()
    end)
    buttons[2]:SetScript("OnClick", function()
        if not CS.db then return end
        CS.db.stats = CS.db.stats or {}
        for statId in pairs(CS.STAT_DEFS) do
            CS.db.stats[statId] = false
        end
        ConfigPanel.RefreshStatsFrame()
        page:Refresh()
    end)
    buttons[3]:SetScript("OnClick", function()
        if CS.db then
            CS.db.statColors = nil
        end
        if CS.InvalidateIlvlColor then
            CS.InvalidateIlvlColor()
        end
        ConfigPanel.RefreshStatsFrame()
        page:Refresh()
    end)
    buttons[4]:SetScript("OnClick", function()
        if CS.db then
            local order = {}
            for i, statId in ipairs(CS.DEFAULTS.statOrder) do
                order[i] = statId
            end
            CS.db.statOrder = order
        end
        ConfigPanel.RefreshStatsFrame()
        page:Refresh()
    end)
    return page
end
ConfigPanel.RegisterPage("stats", {
    label = CS.L.NAV_STATS or "Stats",
    order = 2,
    create = CreateStatsPage,
})
