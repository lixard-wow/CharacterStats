local ADDON_NAME, ns = ...
local Styles = ns.Styles
local ipairs, pairs, wipe = ipairs, pairs, wipe
local PAD = 10
local H_PAD = 6
local H_GAP = 5
local H_SPACING = 14
local HEADER_GAP = 4
local function CreateLine(parent)
    local line = {}
    line.frame = CreateFrame("Frame", nil, parent)
    line.label = line.frame:CreateFontString(nil, "OVERLAY")
    line.value = line.frame:CreateFontString(nil, "OVERLAY")
    line.frame:Hide()
    return line
end
local function CreateHeadline(parent)
    local headline = {}
    headline.frame = CreateFrame("Frame", nil, parent)
    headline.value = headline.frame:CreateFontString(nil, "OVERLAY")
    headline.value:SetPoint("TOP", headline.frame, "TOP", 0, 0)
    headline.caption = headline.frame:CreateFontString(nil, "OVERLAY")
    headline.caption:SetPoint("TOP", headline.value, "BOTTOM", 0, -2)
    headline.divider = headline.frame:CreateTexture(nil, "ARTWORK")
    headline.divider:SetPoint("BOTTOMLEFT", headline.frame, "BOTTOMLEFT", 0, 0)
    headline.divider:SetPoint("BOTTOMRIGHT", headline.frame, "BOTTOMRIGHT", 0, 0)
    headline.divider:SetHeight(1)
    headline.divider:SetColorTexture(0.35, 0.35, 0.35, 0.6)
    headline.frame:Hide()
    return headline
end
local ApplyStatColor = Styles.ApplyStatColor
local function CreateStatsRenderer(parent, original)
    local r = {
        lines = {},
        headers = {},
        separators = {},
        byId = {},
        cachedWidth = 0,
        cachedPercentWidth = nil,
        useHeadline = false,
    }
    r.container = CreateFrame("Frame", nil, parent)
    r.container:SetAllPoints(parent)
    r.headline = CreateHeadline(r.container)
    local function AcquireLine(index)
        local line = r.lines[index]
        if not line then
            line = CreateLine(r.container)
            r.lines[index] = line
        end
        return line
    end
    local function AcquireHeader(index)
        local header = r.headers[index]
        if not header then
            header = Styles.CreateHeader(r.container)
            r.headers[index] = header
        end
        return header
    end
    function r:Show()
        self.container:Show()
    end
    function r:Hide()
        self.container:Hide()
    end
    function r:Reset()
        self.cachedWidth = 0
        self.cachedPercentWidth = nil
    end
    function r:UpdateStat(stat, db)
        if stat.id == "ilvl" and self.useHeadline then
            self.headline.value:SetText(Styles.FormatValue(stat, db))
            return
        end
        local line = self.byId[stat.id]
        if line then
            line.value:SetText(Styles.FormatStatValue(stat, db, not original))
        end
    end
    function r:UpdateColor(stat, db)
        if stat.id == "ilvl" and self.useHeadline then
            ApplyStatColor(stat, db, self.headline.value)
            return
        end
        local line = self.byId[stat.id]
        if line then
            ApplyStatColor(stat, db, line.label, line.value)
        end
    end
    local function LayoutLineText(line, stat, db, fontPath, alignMode, isHorizontal)
        line.label:SetFont(fontPath, db.fontSize, db.fontOutline)
        line.value:SetFont(fontPath, db.fontSize, db.fontOutline)
        line.label:ClearAllPoints()
        line.value:ClearAllPoints()
        if alignMode == "left" then
            line.label:SetPoint("LEFT", line.frame, "LEFT", isHorizontal and H_PAD or 0, 0)
            line.label:SetJustifyH("LEFT")
            line.value:SetPoint("LEFT", line.label, "RIGHT", isHorizontal and H_GAP or 5, 0)
            line.value:SetJustifyH("LEFT")
        elseif alignMode == "right" then
            line.label:SetPoint("RIGHT", line.frame, "RIGHT", 0, 0)
            line.label:SetJustifyH("RIGHT")
            line.value:SetPoint("RIGHT", line.label, "LEFT", -5, 0)
            line.value:SetJustifyH("RIGHT")
        elseif alignMode == "justify" then
            line.label:SetPoint("LEFT", line.frame, "LEFT", 0, 0)
            line.label:SetJustifyH("LEFT")
            line.value:SetPoint("RIGHT", line.frame, "RIGHT", 0, 0)
            line.value:SetJustifyH("RIGHT")
        else
            line.label:SetJustifyH("LEFT")
            line.value:SetJustifyH("LEFT")
        end
        ApplyStatColor(stat, db, line.label, line.value)
        local labelText = db.useShortNames and stat.shortLabel or stat.label
        if db.showColon ~= false then
            labelText = labelText .. ":"
        end
        line.label:SetText(labelText)
        line.value:SetText(Styles.FormatStatValue(stat, db, not original))
        local valueWidth = Styles.SafeStringWidth(line.value, 0)
        if stat.id == "movespeed" and alignMode ~= "center" then
            local saved = line.value:GetText()
            line.value:SetText("999.99%")
            valueWidth = Styles.SafeStringWidth(line.value, valueWidth)
            line.value:SetText(saved)
        end
        local labelWidth = Styles.SafeStringWidth(line.label, 0)
        if alignMode == "center" then
            local gap = 4
            local total = labelWidth + gap + valueWidth
            line.label:SetPoint("LEFT", line.frame, "CENTER", -total / 2, 0)
            line.value:SetPoint("LEFT", line.label, "RIGHT", gap, 0)
        end
        return labelWidth, valueWidth
    end
    local function LayoutHorizontal(self, stats, db, fontPath, rowHeight)
        local textAlpha = db.textAlpha or 1
        local x = PAD
        local count = 0
        for index, stat in ipairs(stats) do
            count = count + 1
            local line = AcquireLine(count)
            self.byId[stat.id] = line
            line.frame:ClearAllPoints()
            line.frame:SetHeight(rowHeight)
            line.frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, -PAD)
            local labelWidth, valueWidth = LayoutLineText(line, stat, db, fontPath, "left", true)
            line.frame:Show()
            local statWidth = H_PAD + labelWidth + H_GAP + valueWidth + H_PAD
            line.frame:SetWidth(statWidth)
            x = x + statWidth
            if db.showSeparator and index < #stats then
                local sep = self.separators[index]
                if not sep then
                    sep = self.container:CreateFontString(nil, "OVERLAY")
                    self.separators[index] = sep
                end
                sep:SetFont(fontPath, db.fontSize, db.fontOutline)
                sep:SetText("|")
                local c = db.separatorColor or { r = 0.5, g = 0.5, b = 0.5 }
                sep:SetTextColor(c.r, c.g, c.b, textAlpha)
                sep:ClearAllPoints()
                sep:SetPoint("LEFT", self.container, "TOPLEFT", x + (H_SPACING / 2) - (Styles.SafeStringWidth(sep, 0) / 2), -PAD - (rowHeight / 2))
                sep:Show()
            end
            x = x + H_SPACING
        end
        if count == 0 then return 0, 0 end
        return x - H_SPACING + H_PAD + PAD, rowHeight + PAD * 2
    end
    local function LayoutVertical(self, stats, db, fontPath, rowHeight)
        local grouped = not original and db.groupedLayout ~= false
        local alignMode = db.alignMode or "justify"
        local y = -PAD
        local maxWidth = 0
        local lineCount, headerCount = 0, 0
        local lastGroup = nil
        local textAlpha = db.textAlpha or 1
        for _, stat in ipairs(stats) do
            if stat.id == "ilvl" and grouped then
                local headline = self.headline
                local bigSize = db.fontSize + 9
                local captionSize = math.max(8, db.fontSize - 2)
                headline.value:SetFont(fontPath, bigSize, db.fontOutline)
                headline.value:SetText(Styles.FormatValue(stat, db))
                ApplyStatColor(stat, db, headline.value)
                headline.caption:SetFont(fontPath, captionSize, db.fontOutline)
                headline.caption:SetText(stat.label)
                headline.caption:SetTextColor(0.6, 0.6, 0.6, textAlpha)
                local height = bigSize + captionSize + 10
                headline.frame:ClearAllPoints()
                headline.frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", PAD, y)
                headline.frame:SetPoint("TOPRIGHT", self.container, "TOPRIGHT", -PAD, y)
                headline.frame:SetHeight(height)
                headline.frame:Show()
                self.useHeadline = true
                local width = math.max(Styles.SafeStringWidth(headline.value, 0), Styles.SafeStringWidth(headline.caption, 0))
                if width + 10 > maxWidth then maxWidth = width + 10 end
                y = y - height - HEADER_GAP
            else
                local group = Styles.GetGroupKey(stat)
                if grouped and group ~= lastGroup then
                    headerCount = headerCount + 1
                    local header = AcquireHeader(headerCount)
                    if lastGroup ~= nil then
                        y = y - HEADER_GAP
                    end
                    local headerHeight, width = Styles.PlaceHeader(header, self.container, PAD, y, Styles.GetGroupLabel(group), fontPath, db)
                    if width > maxWidth then maxWidth = width end
                    y = y - headerHeight
                    lastGroup = group
                end
                lineCount = lineCount + 1
                local line = AcquireLine(lineCount)
                self.byId[stat.id] = line
                line.frame:ClearAllPoints()
                line.frame:SetHeight(rowHeight)
                line.frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", PAD, y)
                line.frame:SetPoint("TOPRIGHT", self.container, "TOPRIGHT", -PAD, y)
                local labelWidth, valueWidth = LayoutLineText(line, stat, db, fontPath, alignMode, false)
                line.frame:Show()
                if stat.percent then
                    if not self.cachedPercentWidth then
                        local saved = line.value:GetText()
                        line.value:SetText("1000.00%")
                        self.cachedPercentWidth = Styles.SafeStringWidth(line.value, 60)
                        line.value:SetText(saved)
                    end
                    if (db.ratingMode or "percent") == "percent" or not Styles.HasRating(stat) then
                        valueWidth = math.max(valueWidth, self.cachedPercentWidth)
                    end
                end
                local width = labelWidth + valueWidth + 10
                if width > maxWidth then maxWidth = width end
                y = y - rowHeight
            end
        end
        if lineCount == 0 and not self.useHeadline then return 0, 0 end
        local contentWidth = maxWidth + PAD * 2
        if contentWidth > self.cachedWidth then
            self.cachedWidth = contentWidth
        end
        return self.cachedWidth, math.abs(y) + PAD
    end
    function r:Layout(stats, db)
        for _, line in ipairs(self.lines) do line.frame:Hide() end
        for _, header in ipairs(self.headers) do header.frame:Hide() end
        for _, sep in pairs(self.separators) do sep:Hide() end
        self.headline.frame:Hide()
        self.useHeadline = false
        wipe(self.byId)
        local fontPath = ns.GetFontPath(db.fontFace)
        local rowHeight = db.fontSize + (db.rowPadding or 0)
        if db.orientation == "horizontal" then
            return LayoutHorizontal(self, stats, db, fontPath, rowHeight)
        end
        return LayoutVertical(self, stats, db, fontPath, rowHeight)
    end
    return r
end
Styles.Register("ledger", {
    order = 1,
    label = ns.L.STYLE_LEDGER or "Ledger",
    labelKey = "STYLE_LEDGER",
    CreateStatsRenderer = CreateStatsRenderer,
    CreatePaperdollRenderer = function(panel)
        return Styles.CreateListPaperdollRenderer(panel, { gearSummary = true })
    end,
    replacesPaperdollPane = true,
})
Styles.Register("original", {
    order = 0,
    label = ns.L.STYLE_ORIGINAL or "Original",
    labelKey = "STYLE_ORIGINAL",
    CreateStatsRenderer = function(parent)
        return CreateStatsRenderer(parent, true)
    end,
    CreatePaperdollRenderer = function(panel)
        return Styles.CreateListPaperdollRenderer(panel, { gearSummary = true })
    end,
    replacesPaperdollPane = true,
})
