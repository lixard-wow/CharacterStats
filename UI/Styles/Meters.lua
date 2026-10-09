local ADDON_NAME, ns = ...
local Styles = ns.Styles
local ipairs, wipe = ipairs, wipe
local PAD = 10
local MIN_WIDTH = 170
local CELL_WIDTH = 74
local CELL_GAP = 8
local BAR_GAP = 3
local HEADER_GAP = 4
local function CreateMeter(parent)
    local meter = {}
    meter.frame = CreateFrame("Frame", nil, parent)
    meter.label = meter.frame:CreateFontString(nil, "OVERLAY")
    meter.value = meter.frame:CreateFontString(nil, "OVERLAY")
    meter.bar = CreateFrame("StatusBar", nil, meter.frame)
    meter.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    meter.bar.bg = meter.bar:CreateTexture(nil, "BACKGROUND")
    meter.bar.bg:SetAllPoints()
    meter.bar.bg:SetColorTexture(1, 1, 1, 0.08)
    meter.frame:Hide()
    return meter
end
local function CreateStatsRenderer(parent)
    local r = {
        meters = {},
        headers = {},
        byId = {},
        barScale = 50,
        cachedWidth = 0,
    }
    r.container = CreateFrame("Frame", nil, parent)
    r.container:SetAllPoints(parent)
    local function AcquireMeter(index)
        local meter = r.meters[index]
        if not meter then
            meter = CreateMeter(r.container)
            r.meters[index] = meter
        end
        return meter
    end
    local function AcquireHeader(index)
        local header = r.headers[index]
        if not header then
            header = Styles.CreateHeader(r.container)
            r.headers[index] = header
        end
        return header
    end
    local function FillMeter(meter, stat, db, fontPath, valueSize)
        meter.label:SetFont(fontPath, db.fontSize, db.fontOutline)
        meter.value:SetFont(fontPath, valueSize or db.fontSize, db.fontOutline)
        local labelText = db.useShortNames and stat.shortLabel or stat.label
        meter.label:SetText(labelText)
        meter.value:SetText(Styles.FormatStatValue(stat, db, true))
        Styles.ApplyStatColor(stat, db, meter.label, meter.value)
        local hasBar = Styles.HasBar(stat)
        if hasBar then
            meter.bar:SetHeight(Styles.BarHeight(db, "statBarHeight", 4))
            local sr, sg, sb = ns.GetStatColor(stat.id)
            meter.bar:SetStatusBarColor(sr, sg, sb, 0.9 * (db.textAlpha or 1))
            Styles.SetBarValue(meter.bar, stat, r.barScale)
            meter.bar:Show()
        else
            meter.bar:Hide()
        end
        meter.hasBar = hasBar
        return Styles.SafeStringWidth(meter.label, 0), Styles.SafeStringWidth(meter.value, 0)
    end
    function r:Show()
        self.container:Show()
    end
    function r:Hide()
        self.container:Hide()
    end
    function r:Reset()
        self.cachedWidth = 0
    end
    function r:UpdateStat(stat, db)
        local meter = self.byId[stat.id]
        if not meter then return end
        meter.value:SetText(Styles.FormatStatValue(stat, db, true))
        if meter.hasBar then
            Styles.SetBarValue(meter.bar, stat, self.barScale)
        end
    end
    function r:UpdateColor(stat, db)
        local meter = self.byId[stat.id]
        if meter then
            Styles.ApplyStatColor(stat, db, meter.label, meter.value)
        end
    end
    local function LayoutVertical(self, stats, db, fontPath)
        local grouped = db.groupedLayout ~= false
        local rowGap = math.max(0, db.rowPadding or 0) + 2
        local y = -PAD
        local maxWidth = MIN_WIDTH
        local count, headerCount = 0, 0
        local lastGroup = nil
        for _, stat in ipairs(stats) do
            local group = Styles.GetGroupKey(stat)
            if grouped and stat.id ~= "ilvl" and group ~= lastGroup then
                headerCount = headerCount + 1
                if lastGroup ~= nil then
                    y = y - HEADER_GAP
                end
                local height, width = Styles.PlaceHeader(AcquireHeader(headerCount), self.container, PAD, y, Styles.GetGroupLabel(group), fontPath, db)
                if width > maxWidth then maxWidth = width end
                y = y - height
                lastGroup = group
            end
            count = count + 1
            local meter = AcquireMeter(count)
            self.byId[stat.id] = meter
            local isIlvl = stat.id == "ilvl"
            local labelWidth, valueWidth = FillMeter(meter, stat, db, fontPath, isIlvl and (db.fontSize + 4) or nil)
            local textHeight = isIlvl and (db.fontSize + 6) or (db.fontSize + 2)
            local height = textHeight + (meter.hasBar and (BAR_GAP + Styles.BarHeight(db, "statBarHeight", 4)) or 0)
            meter.frame:ClearAllPoints()
            meter.frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", PAD, y)
            meter.frame:SetPoint("TOPRIGHT", self.container, "TOPRIGHT", -PAD, y)
            meter.frame:SetHeight(height)
            meter.label:ClearAllPoints()
            meter.label:SetPoint("TOPLEFT", meter.frame, "TOPLEFT", 0, 0)
            meter.value:ClearAllPoints()
            meter.value:SetPoint("BOTTOMRIGHT", meter.frame, "TOPRIGHT", 0, -textHeight + 2)
            meter.bar:ClearAllPoints()
            meter.bar:SetPoint("BOTTOMLEFT", meter.frame, "BOTTOMLEFT", 0, 0)
            meter.bar:SetPoint("BOTTOMRIGHT", meter.frame, "BOTTOMRIGHT", 0, 0)
            meter.frame:Show()
            local width = labelWidth + valueWidth + 16
            if width > maxWidth then maxWidth = width end
            y = y - height - rowGap
            if isIlvl then
                y = y - 2
            end
        end
        if count == 0 then return 0, 0 end
        local contentWidth = maxWidth + PAD * 2
        if contentWidth > self.cachedWidth then
            self.cachedWidth = contentWidth
        end
        return self.cachedWidth, math.abs(y) - rowGap + PAD
    end
    local function LayoutHorizontal(self, stats, db, fontPath)
        local x = PAD
        local count = 0
        local cellHeight = db.fontSize * 2 + 6 + BAR_GAP + Styles.BarHeight(db, "statBarHeight", 4)
        for _, stat in ipairs(stats) do
            count = count + 1
            local meter = AcquireMeter(count)
            self.byId[stat.id] = meter
            local labelWidth, valueWidth = FillMeter(meter, stat, db, fontPath)
            local width = math.max(CELL_WIDTH, labelWidth + 4, valueWidth + 4)
            meter.frame:ClearAllPoints()
            meter.frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, -PAD)
            meter.frame:SetSize(width, cellHeight)
            meter.label:ClearAllPoints()
            meter.label:SetPoint("TOPLEFT", meter.frame, "TOPLEFT", 0, 0)
            meter.value:ClearAllPoints()
            meter.value:SetPoint("TOPLEFT", meter.label, "BOTTOMLEFT", 0, -3)
            meter.bar:ClearAllPoints()
            meter.bar:SetPoint("BOTTOMLEFT", meter.frame, "BOTTOMLEFT", 0, 0)
            meter.bar:SetPoint("BOTTOMRIGHT", meter.frame, "BOTTOMRIGHT", 0, 0)
            meter.frame:Show()
            x = x + width + CELL_GAP
        end
        if count == 0 then return 0, 0 end
        return x - CELL_GAP + PAD, cellHeight + PAD * 2
    end
    function r:Layout(stats, db)
        for _, meter in ipairs(self.meters) do meter.frame:Hide() end
        for _, header in ipairs(self.headers) do header.frame:Hide() end
        wipe(self.byId)
        self.barScale = Styles.GetBarScale(stats)
        local fontPath = ns.GetFontPath(db.fontFace)
        if db.orientation == "horizontal" then
            return LayoutHorizontal(self, stats, db, fontPath)
        end
        return LayoutVertical(self, stats, db, fontPath)
    end
    return r
end
Styles.Register("meters", {
    order = 2,
    label = ns.L.STYLE_METERS or "Meters",
    CreateStatsRenderer = CreateStatsRenderer,
    CreatePaperdollRenderer = function(panel)
        return Styles.CreateListPaperdollRenderer(panel, { bars = true, gearSummary = true })
    end,
    replacesPaperdollPane = true,
})
