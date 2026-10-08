local ADDON_NAME, ns = ...
local Styles = ns.Styles
local ipairs = ipairs
local ROW_HEIGHT = 15
local BAR_ROW_HEIGHT = 20
local FONT_SIZE = 10
local SCHOOL_COLORS = {
    fire = { 1, 0.5, 0 },
    frost = { 0.5, 1, 1 },
    nature = { 0.3, 1, 0.3 },
    shadow = { 0.5, 0.5, 1 },
    arcane = { 1, 0.5, 1 },
    holy = { 1, 0.9, 0.5 },
}
local function CreateItemLevelBlock(container, Paperdoll)
    local ilvl = CreateFrame("Frame", nil, container)
    ilvl:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -10)
    ilvl:SetPoint("TOPRIGHT", container, "TOPRIGHT", -8, -10)
    ilvl:SetHeight(60)
    ilvl:EnableMouse(true)
    ilvl.caption = ilvl:CreateFontString(nil, "OVERLAY")
    ilvl.caption:SetFont(STANDARD_TEXT_FONT, 11, "")
    ilvl.caption:SetPoint("TOP", ilvl, "TOP", 0, 0)
    ilvl.caption:SetText(ns.L.STAT_ILVL or "Item Level")
    ilvl.value = ilvl:CreateFontString(nil, "OVERLAY")
    ilvl.value:SetFont(STANDARD_TEXT_FONT, 22, "OUTLINE")
    ilvl.value:SetPoint("TOP", ilvl.caption, "BOTTOM", 0, -3)
    ilvl.sub = ilvl:CreateFontString(nil, "OVERLAY")
    ilvl.sub:SetFont(STANDARD_TEXT_FONT, 9, "")
    ilvl.sub:SetPoint("TOP", ilvl.value, "BOTTOM", 0, -3)
    ilvl.sub:SetTextColor(0.55, 0.55, 0.55)
    ilvl.gear = ilvl:CreateFontString(nil, "OVERLAY")
    ilvl.gear:SetFont(STANDARD_TEXT_FONT, 9, "")
    ilvl.divider = ilvl:CreateTexture(nil, "ARTWORK")
    ilvl.divider:SetPoint("BOTTOMLEFT", ilvl, "BOTTOMLEFT", 0, 0)
    ilvl.divider:SetPoint("BOTTOMRIGHT", ilvl, "BOTTOMRIGHT", 0, 0)
    ilvl.divider:SetHeight(1)
    ilvl.divider:SetColorTexture(0.35, 0.35, 0.35, 0.6)
    ilvl:SetScript("OnEnter", function(self)
        Paperdoll.ShowStatTooltip(self, "ilvl", ns.L.STAT_ILVL or "Item Level", self.tooltipValue, ns.L.STAT_ILVL_TT)
    end)
    ilvl:SetScript("OnLeave", GameTooltip_Hide)
    return ilvl
end
local function CreateRow(container, Paperdoll)
    local row = CreateFrame("Frame", nil, container)
    row:EnableMouse(true)
    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(1, 1, 1, 0.05)
    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(STANDARD_TEXT_FONT, FONT_SIZE, "")
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -2)
    row.label:SetJustifyH("LEFT")
    row.value = row:CreateFontString(nil, "OVERLAY")
    row.value:SetFont(STANDARD_TEXT_FONT, FONT_SIZE, "")
    row.value:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -2)
    row.value:SetJustifyH("RIGHT")
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 2)
    row.bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 2)
    row.bar:SetHeight(3)
    row.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    row.bar.bg = row.bar:CreateTexture(nil, "BACKGROUND")
    row.bar.bg:SetAllPoints()
    row.bar.bg:SetColorTexture(1, 1, 1, 0.08)
    row.bar:Hide()
    row:SetScript("OnEnter", function(self)
        if self.blizzardRow then
            Paperdoll.ShowBlizzardRowTooltip(self, self.blizzardRow)
        elseif self.statId then
            Paperdoll.ShowStatTooltip(self, self.statId, self.tooltipTitle, self.tooltipValue, self.tooltipText)
        end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    return row
end
function Styles.CreateListPaperdollRenderer(panel, opts)
    opts = opts or {}
    local Paperdoll = ns.PaperdollPanel
    local Widgets = ns.ConfigWidgets
    local r = { rows = {}, headers = {} }
    r.container = CreateFrame("Frame", nil, panel)
    r.container:SetAllPoints(panel)
    r.ilvl = CreateItemLevelBlock(r.container, Paperdoll)
    r.scroll = Widgets.CreateScrollFrame(r.container)
    r.content = r.scroll.content
    local function AcquireHeader(index)
        local header = r.headers[index]
        if not header then
            header = Widgets.CreateSectionHeader(r.content, "", true)
            r.headers[index] = header
        end
        return header
    end
    local function AcquireRow(index)
        local row = r.rows[index]
        if not row then
            row = CreateRow(r.content, Paperdoll)
            r.rows[index] = row
        end
        return row
    end
    local function FillRow(row, stat, db, colon, striped, barScale)
        local dec = ns.GetDecimals(db.decimals)
        row.label:SetText(stat.label:gsub("%s+$", "") .. colon)
        local valueText = Styles.FormatValue(stat, db)
        local ratingText = Styles.HasRating(stat) and ns.FormatRating(stat.ratingId) or nil
        if ratingText and not opts.bars then
            row.value:SetText("|cff7a7a7a" .. ratingText .. "|r  " .. valueText)
        else
            row.value:SetText(valueText)
        end
        local sr, sg, sb = ns.GetStatColor(stat.id)
        row.label:SetTextColor(sr, sg, sb)
        row.value:SetTextColor(sr, sg, sb)
        row.highlight:SetShown(striped)
        local hasBar = opts.bars and Styles.HasBar(stat)
        if hasBar then
            row.bar:SetStatusBarColor(sr, sg, sb, 0.9)
            Styles.SetBarValue(row.bar, stat, barScale)
            row.bar:Show()
        else
            row.bar:Hide()
        end
        row:SetHeight(hasBar and BAR_ROW_HEIGHT or ROW_HEIGHT)
        row.blizzardRow = nil
        row.statId = stat.id
        row.tooltipTitle = stat.label
        row.tooltipText = stat.tooltip or ""
        if stat.percent then
            row.tooltipValue = ns.FormatPercent(stat.value, math.max(dec, 2)) .. (ratingText and (" " .. ratingText) or "")
        else
            row.tooltipValue = ns.FormatNumber(stat.value, 0)
        end
        return hasBar and BAR_ROW_HEIGHT or ROW_HEIGHT
    end
    local barProxy = {}
    local function FillBlizzardRow(row, item, colon, striped, barScale)
        local labelText = item.label .. colon
        if item.atlas and CreateAtlasMarkup then
            labelText = CreateAtlasMarkup(item.atlas, 12, 12) .. " " .. labelText
        end
        row.label:SetText(labelText)
        row.value:SetText(item.value)
        local schoolColor = item.school and SCHOOL_COLORS[item.school:lower()]
        if schoolColor then
            row.label:SetTextColor(schoolColor[1], schoolColor[2], schoolColor[3])
            row.value:SetTextColor(schoolColor[1], schoolColor[2], schoolColor[3])
        elseif item.statId then
            local sr, sg, sb = ns.GetStatColor(item.statId)
            row.label:SetTextColor(sr, sg, sb)
            row.value:SetTextColor(sr, sg, sb)
        else
            row.label:SetTextColor(0.82, 0.82, 0.82)
            row.value:SetTextColor(1, 1, 1)
        end
        row.highlight:SetShown(striped)
        local hasBar = opts.bars and item.isPercent and item.numericValue and true or false
        if hasBar then
            local sr, sg, sb = ns.GetStatColor(item.statId or "crit")
            barProxy.value = item.numericValue
            row.bar:SetStatusBarColor(sr, sg, sb, 0.9)
            Styles.SetBarValue(row.bar, barProxy, barScale)
            row.bar:Show()
        else
            row.bar:Hide()
        end
        local height = hasBar and BAR_ROW_HEIGHT or ROW_HEIGHT
        row:SetHeight(height)
        row.blizzardRow = item
        row.statId = nil
        return height
    end
    local function GetBlizzardBarScale(sections)
        local maxValue = 50
        for _, section in ipairs(sections) do
            for _, item in ipairs(section.rows) do
                local numeric = item.numericValue
                if item.isPercent and type(numeric) == "number" and not ns.IsSecretValue(numeric) and numeric > maxValue and numeric < 1000 then
                    maxValue = numeric
                end
            end
        end
        return math.ceil(maxValue / 10) * 10
    end
    function r:Show()
        self.container:Show()
    end
    function r:Hide()
        self.container:Hide()
    end
    function r:BuildGearText(db)
        if not opts.gearSummary or db.gearFlags == false or not ns.Gear then return nil end
        local _, summary = ns.Gear.Scan()
        local function Colored(key, text)
            local cr, cg, cb = ns.GearBadges.GetColor(db, key)
            return string.format("|cff%02x%02x%02x%s|r", cr * 255, cg * 255, cb * 255, text)
        end
        local parts = {}
        if summary.missingEnchants > 0 then
            parts[#parts + 1] = Colored("gearColorEnchant", string.format(ns.L.GEAR_MISSING_ENCHANTS or "Enchants: %d", summary.missingEnchants))
        end
        if summary.emptySockets > 0 then
            parts[#parts + 1] = Colored("gearColorSocket", string.format(ns.L.GEAR_EMPTY_SOCKETS or "Gems: %d", summary.emptySockets))
        end
        if #parts == 0 then
            return "|cff5fbf6a" .. (ns.L.GEAR_ALL_GOOD or "Enchants and gems: all set") .. "|r"
        end
        return "|cff8c8c8c" .. (ns.L.GEAR_MISSING or "Missing") .. ":|r " .. table.concat(parts, "  ")
    end
    function r:Refresh(db)
        local colon = Paperdoll.GetLocaleColon()
        local ar, ag, ab = ns.GetAccentColor()
        local equipped, overall = Paperdoll.GetItemLevels()
        self.ilvl.caption:SetTextColor(ar, ag, ab)
        self.ilvl.value:SetText(string.format("%.2f", equipped))
        local ir, ig, ib = ns.GetStatColor("ilvl")
        self.ilvl.value:SetTextColor(ir or 1, ig or 1, ib or 1)
        self.ilvl.tooltipValue = string.format("%.2f", equipped)
        if overall and overall > equipped + 0.005 then
            self.ilvl.sub:SetText(string.format(ns.L.PAPERDOLL_ILVL_BAGS or "%s in bags", string.format("%.1f", overall)))
            self.ilvl.sub:Show()
        else
            self.ilvl.sub:Hide()
        end
        local gearText = self:BuildGearText(db)
        local gear = self.ilvl.gear
        gear:ClearAllPoints()
        gear:SetPoint("TOP", self.ilvl.sub:IsShown() and self.ilvl.sub or self.ilvl.value, "BOTTOM", 0, -3)
        gear:SetText(gearText or "")
        gear:SetShown(gearText ~= nil)
        local extra = (gearText and self.ilvl.sub:IsShown()) and 12 or 0
        self.ilvl:SetHeight(60 + extra)
        self.scroll:ClearAllPoints()
        self.scroll:SetPoint("TOPLEFT", self.container, "TOPLEFT", 0, -78 - extra)
        self.scroll:SetPoint("BOTTOMRIGHT", self.container, "BOTTOMRIGHT", 0, 4)
        local content = self.content
        local width = panel:GetWidth()
        if width and width > 1 then
            content:SetWidth(width)
        end
        local y = 0
        local rowIndex, headerIndex = 0, 0
        local function AddHeader(title)
            headerIndex = headerIndex + 1
            local header = AcquireHeader(headerIndex)
            header.text:SetText(title or "")
            header.text:SetTextColor(ar, ag, ab)
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y)
            header:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y)
            header:Show()
            y = y - 20
        end
        local function PlaceRow()
            rowIndex = rowIndex + 1
            local row = AcquireRow(rowIndex)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y)
            row:Show()
            return row
        end
        if Paperdoll.UsesBlizzardStatList() then
            local sections = Paperdoll.CollectBlizzardSections()
            local barScale = opts.bars and GetBlizzardBarScale(sections) or 100
            for _, section in ipairs(sections) do
                if #section.rows > 0 then
                    AddHeader(section.title)
                    for i, item in ipairs(section.rows) do
                        y = y - FillBlizzardRow(PlaceRow(), item, colon, i % 2 == 1, barScale)
                    end
                    y = y - 8
                end
            end
        else
            local attributes, enhancements = ns.Stats:CollectByCategory()
            local barScale = opts.bars and Styles.GetBarScale(enhancements) or 100
            local function AddSection(title, stats)
                if #stats == 0 then return end
                AddHeader(title)
                for i, stat in ipairs(stats) do
                    y = y - FillRow(PlaceRow(), stat, db, colon, i % 2 == 1, barScale)
                end
                y = y - 8
            end
            AddSection(ns.L.HEADER_ATTRIBUTES or "Attributes", attributes)
            AddSection(ns.L.HEADER_ENHANCEMENTS or "Enhancements", enhancements)
        end
        content:SetHeight(math.max(1, math.abs(y)))
        for i = rowIndex + 1, #self.rows do self.rows[i]:Hide() end
        for i = headerIndex + 1, #self.headers do self.headers[i]:Hide() end
    end
    return r
end
