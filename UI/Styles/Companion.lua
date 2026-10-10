local ADDON_NAME, ns = ...
local Styles = ns.Styles
local ipairs, wipe = ipairs, wipe
local PAD = 6
local CELL_PAD = 10
local function CreateCell(parent)
    local cell = {}
    cell.frame = CreateFrame("Frame", nil, parent)
    cell.label = cell.frame:CreateFontString(nil, "OVERLAY")
    cell.label:SetPoint("TOP", cell.frame, "TOP", 0, -4)
    cell.value = cell.frame:CreateFontString(nil, "OVERLAY")
    cell.value:SetPoint("TOP", cell.label, "BOTTOM", 0, -2)
    cell.divider = cell.frame:CreateTexture(nil, "ARTWORK")
    cell.divider:SetWidth(1)
    cell.divider:SetColorTexture(1, 1, 1, 0.12)
    cell.frame:Hide()
    return cell
end
local function CreateStatsRenderer(parent)
    local r = { cells = {}, byId = {}, cachedValueWidth = {} }
    r.container = CreateFrame("Frame", nil, parent)
    r.container:SetAllPoints(parent)
    local function AcquireCell(index)
        local cell = r.cells[index]
        if not cell then
            cell = CreateCell(r.container)
            r.cells[index] = cell
        end
        return cell
    end
    function r:Show()
        self.container:Show()
    end
    function r:Hide()
        self.container:Hide()
    end
    function r:Reset()
        wipe(self.cachedValueWidth)
    end
    function r:UpdateStat(stat, db)
        local cell = self.byId[stat.id]
        if cell then
            cell.value:SetText(Styles.FormatStatValue(stat, db, true))
        end
    end
    function r:UpdateColor(stat, db)
        local cell = self.byId[stat.id]
        if cell then
            Styles.ApplyStatColor(stat, db, cell.value)
        end
    end
    function r:Layout(stats, db)
        for _, cell in ipairs(self.cells) do cell.frame:Hide() end
        wipe(self.byId)
        local fontPath = ns.GetFontPath(db.fontFace)
        local labelSize = math.max(4, db.fontSize - 3)
        local valueSize = db.fontSize + 1
        local cellHeight = labelSize + valueSize + 12
        local horizontal = db.orientation == "horizontal"
        local alpha = db.textAlpha or 1
        local x, y = PAD, -PAD
        local maxCellWidth = 0
        local count = 0
        for index, stat in ipairs(stats) do
            count = count + 1
            local cell = AcquireCell(count)
            self.byId[stat.id] = cell
            cell.label:SetFont(fontPath, labelSize, db.fontOutline)
            cell.value:SetFont(fontPath, valueSize, db.fontOutline)
            cell.label:SetText(stat.shortLabel or stat.label)
            local lr, lg, lb = ns.GetStatColor(stat.id)
            cell.label:SetTextColor(lr, lg, lb, 0.7 * alpha)
            cell.value:SetText(Styles.FormatStatValue(stat, db, true))
            Styles.ApplyStatColor(stat, db, cell.value)
            local valueWidth = Styles.SafeStringWidth(cell.value, 0)
            if stat.percent then
                local saved = cell.value:GetText()
                cell.value:SetText(stat.id == "movespeed" and "999%" or "99.99%")
                valueWidth = math.max(valueWidth, Styles.SafeStringWidth(cell.value, 0))
                cell.value:SetText(saved)
            end
            local width = math.max(Styles.SafeStringWidth(cell.label, 0), valueWidth) + CELL_PAD * 2
            if width > maxCellWidth then maxCellWidth = width end
            cell.frame:ClearAllPoints()
            cell.frame:SetPoint("TOPLEFT", self.container, "TOPLEFT", x, y)
            cell.frame:SetSize(width, cellHeight)
            cell.divider:ClearAllPoints()
            local last = index == #stats
            if horizontal then
                cell.divider:SetPoint("TOPRIGHT", cell.frame, "TOPRIGHT", 0, -4)
                cell.divider:SetPoint("BOTTOMRIGHT", cell.frame, "BOTTOMRIGHT", 0, 4)
                cell.divider:SetWidth(1)
                x = x + width
            else
                cell.divider:SetPoint("BOTTOMLEFT", cell.frame, "BOTTOMLEFT", 4, 0)
                cell.divider:SetPoint("BOTTOMRIGHT", cell.frame, "BOTTOMRIGHT", -4, 0)
                cell.divider:SetHeight(1)
                y = y - cellHeight
            end
            cell.divider:SetShown(not last)
            cell.frame:Show()
        end
        if count == 0 then return 0, 0 end
        if horizontal then
            return x + PAD, cellHeight + PAD * 2
        end
        for i = 1, count do
            self.cells[i].frame:SetWidth(maxCellWidth)
        end
        return maxCellWidth + PAD * 2, math.abs(y) + PAD
    end
    return r
end
Styles.Register("companion", {
    order = 3,
    label = ns.L.STYLE_COMPANION or "Companion",
    labelKey = "STYLE_COMPANION",
    CreateStatsRenderer = CreateStatsRenderer,
    replacesPaperdollPane = false,
    usesDrawer = true,
})
