local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local W, H = 900, 590
local RAIL = 74
local HEADER = 66
local ASIDE = 250
local SLOT = 40
local SLOT_GAP = 6
local C = {
    ground = { 0.04, 0.04, 0.035 },
    frame = { 0.102, 0.090, 0.075 },
    rail = { 0.075, 0.067, 0.055 },
    header = { 0.125, 0.106, 0.078 },
    stage = { 0.133, 0.114, 0.169 },
    aside = { 0.110, 0.094, 0.078 },
    gold = { 0.79, 0.63, 0.29 },
    goldBright = { 0.95, 0.84, 0.54 },
    line = { 0.29, 0.24, 0.153 },
    text = { 0.94, 0.89, 0.77 },
    muted = { 0.66, 0.60, 0.48 },
    button = { 0.173, 0.141, 0.090 },
}
local function Fill(parent, color, layer, sublevel)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return t
end
local function Border(parent, color, size)
    size = size or 1
    local edges = {}
    for i, spec in ipairs({
        { "TOPLEFT", "TOPRIGHT", nil, size }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, size },
        { "TOPLEFT", "BOTTOMLEFT", size, nil }, { "TOPRIGHT", "BOTTOMRIGHT", size, nil },
    }) do
        local t = Fill(parent, color, "BORDER")
        t:SetPoint(spec[1])
        t:SetPoint(spec[2])
        if spec[3] then t:SetWidth(spec[3]) else t:SetHeight(spec[4]) end
        edges[i] = t
    end
    return edges
end
local function Text(parent, font, size, color, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(fs, font, size, flags or "")
    fs:SetTextColor(color[1], color[2], color[3])
    return fs
end
local function Button(parent, width, height, label)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.bg = Fill(b, C.button)
    b.bg:SetAllPoints()
    b.edges = Border(b, C.line)
    b.label = Text(b, "SourceSans3-Bold.ttf", 12, C.goldBright)
    b.label:SetPoint("CENTER")
    b.label:SetText(label or "")
    b:SetScript("OnEnter", function(self) for _, e in ipairs(self.edges) do e:SetColorTexture(C.gold[1], C.gold[2], C.gold[3]) end end)
    b:SetScript("OnLeave", function(self) if not self.selected then for _, e in ipairs(self.edges) do e:SetColorTexture(C.line[1], C.line[2], C.line[3]) end end end)
    function b:SetSelected(on)
        self.selected = on
        local c = on and C.gold or C.line
        for _, e in ipairs(self.edges) do e:SetColorTexture(c[1], c[2], c[3]) end
        self.label:SetTextColor((on and C.goldBright or C.muted)[1], (on and C.goldBright or C.muted)[2], (on and C.goldBright or C.muted)[3])
    end
    return b
end
local function IconButton(parent, glyph, tooltip, onClick)
    local b = Button(parent, 26, 26, glyph)
    Parts.SetFont(b.label, "SourceSans3-Bold.ttf", 14, "")
    b:SetScript("OnClick", onClick)
    b:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip, 1, 1, 1)
        GameTooltip:Show()
    end)
    b:HookScript("OnLeave", GameTooltip_Hide)
    return b
end
local function BuildRail(f)
    local rail = CreateFrame("Frame", nil, f)
    rail:SetPoint("TOPLEFT", 2, -2)
    rail:SetPoint("BOTTOMLEFT", 2, 2)
    rail:SetWidth(RAIL)
    Fill(rail, C.rail):SetAllPoints()
    local divider = Fill(rail, C.line, "BORDER")
    divider:SetPoint("TOPRIGHT")
    divider:SetPoint("BOTTOMRIGHT")
    divider:SetWidth(1)
    local tabs = {
        { key = "PaperDollFrame", label = ns.L.WINDOW_TAB_CHARACTER or CHARACTER or "Character" },
        { key = "ReputationFrame", label = ns.L.WINDOW_TAB_REPUTATION or REPUTATION or "Reputation" },
        { key = "TokenFrame", label = ns.L.WINDOW_TAB_CURRENCY or CURRENCY or "Currency" },
    }
    f.tabs = {}
    for i, tab in ipairs(tabs) do
        local b = Button(rail, RAIL - 14, 54, tab.label)
        b:SetPoint("TOP", rail, "TOP", -1, -(HEADER + 10) - (i - 1) * 62)
        b.label:SetWidth(RAIL - 18)
        b:SetScript("OnClick", function() ns.Window.ShowTab(tab.key) end)
        b:SetSelected(tab.key == "PaperDollFrame")
        f.tabs[tab.key] = b
    end
end
local function BuildHeader(f)
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", RAIL + 2, -2)
    header:SetPoint("TOPRIGHT", -2, -2)
    header:SetHeight(HEADER)
    Fill(header, C.header):SetAllPoints()
    local line = Fill(header, C.line, "BORDER")
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)
    local ring = Fill(header, C.gold, "ARTWORK", 0)
    ring:SetSize(46, 46)
    ring:SetPoint("LEFT", 14, 0)
    local crest = header:CreateTexture(nil, "ARTWORK", nil, 2)
    crest:SetSize(42, 42)
    crest:SetPoint("CENTER", ring)
    crest:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.crest = crest
    f.nameText = Text(header, "Cinzel-Bold.ttf", 20, C.goldBright)
    f.nameText:SetPoint("TOPLEFT", ring, "TOPRIGHT", 12, 2)
    f.subText = Text(header, "SourceSans3-Regular.ttf", 13, C.muted)
    f.subText:SetPoint("TOPLEFT", f.nameText, "BOTTOMLEFT", 0, -4)
    local close = Button(header, 26, 26, "X")
    close:SetPoint("RIGHT", -12, 0)
    close:SetScript("OnClick", ns.Window.Close)
    f.ilvlValue = Text(header, "Cinzel-Bold.ttf", 24, { 0.77, 0.55, 1 })
    f.ilvlValue:SetPoint("RIGHT", close, "LEFT", -18, -2)
    f.ilvlLabel = Text(header, "SourceSans3-Bold.ttf", 10, C.muted)
    f.ilvlLabel:SetPoint("BOTTOMRIGHT", f.ilvlValue, "TOPRIGHT", 0, 1)
    f.ilvlLabel:SetText((ns.L.STAT_ILVL or "Item Level"):upper())
    f.ilvlBags = Text(header, "SourceSans3-Regular.ttf", 11, C.muted)
    f.ilvlBags:SetPoint("TOPRIGHT", f.ilvlValue, "BOTTOMRIGHT", 0, -1)
end
local function BuildGear(f, body)
    f.slotButtons = {}
    local function Column(list, side)
        for i, slot in ipairs(list) do
            local b = Parts.CreateSlot(body, slot, {
                size = SLOT, side = side, numberFont = "SourceSans3-Bold.ttf", textFont = "SourceSans3-Regular.ttf",
                ilvlSize = 13, rankSize = 11, detailSize = 11, emptyBorder = C.line,
            })
            local y = -12 - (i - 1) * (SLOT + SLOT_GAP)
            if side == "right" then
                b:SetPoint("TOPLEFT", body, "TOPLEFT", 14, y)
            else
                b:SetPoint("TOPRIGHT", body, "TOPRIGHT", -14, y)
            end
            f.slotButtons[#f.slotButtons + 1] = b
        end
    end
    Column(Parts.LEFT, "right")
    Column(Parts.RIGHT, "left")
    for i, slot in ipairs(Parts.WEAPONS) do
        local b = Parts.CreateSlot(body, slot, {
            size = SLOT + 4, side = i == 1 and "left" or "right", numberFont = "SourceSans3-Bold.ttf",
            textFont = "SourceSans3-Regular.ttf", ilvlSize = 13, rankSize = 11, detailSize = 11, emptyBorder = C.line,
        })
        b:SetPoint("BOTTOM", body, "BOTTOM", (i == 1 and -1 or 1) * (SLOT / 2 + 5), 48)
        f.slotButtons[#f.slotButtons + 1] = b
    end
end
local function BuildStage(f, body)
    local stage = CreateFrame("Frame", nil, body)
    stage:SetPoint("TOP", body, "TOP", 0, -10)
    stage:SetPoint("BOTTOM", body, "BOTTOM", 0, 104)
    stage:SetWidth(250)
    Fill(stage, C.stage):SetAllPoints()
    Border(stage, { 0.23, 0.20, 0.27 })
    f.model = Parts.CreateModel(stage)
    f.model:SetPoint("TOPLEFT", 2, -2)
    f.model:SetPoint("BOTTOMRIGHT", -2, 2)
    local controls = CreateFrame("Frame", nil, body)
    controls:SetSize(250, 28)
    controls:SetPoint("BOTTOM", body, "BOTTOM", 0, 12)
    f.setButton = Button(controls, 150, 26, ns.L.WINDOW_SETS or "Equipment Sets")
    f.setButton:SetPoint("LEFT", controls, "LEFT", 0, 0)
    f.setButton:SetScript("OnClick", function() f:ShowPane("sets") end)
    local reset = IconButton(controls, "o", ns.L.WINDOW_RESET_CAMERA or "Reset camera", function() f.model:Reset() end)
    reset:SetPoint("RIGHT", controls, "RIGHT", 0, 0)
    local right = IconButton(controls, ">", ns.L.WINDOW_ROTATE_RIGHT or "Rotate right", function() f.model:Rotate(0.3) end)
    right:SetPoint("RIGHT", reset, "LEFT", -6, 0)
    local left = IconButton(controls, "<", ns.L.WINDOW_ROTATE_LEFT or "Rotate left", function() f.model:Rotate(-0.3) end)
    left:SetPoint("RIGHT", right, "LEFT", -6, 0)
end
local function BuildAside(f)
    local aside = CreateFrame("Frame", nil, f)
    aside:SetPoint("TOPRIGHT", -2, -(HEADER + 2))
    aside:SetPoint("BOTTOMRIGHT", -2, 2)
    aside:SetWidth(ASIDE)
    Fill(aside, C.aside):SetAllPoints()
    local divider = Fill(aside, C.line, "BORDER")
    divider:SetPoint("TOPLEFT")
    divider:SetPoint("BOTTOMLEFT")
    divider:SetWidth(1)
    local paneTabs = {
        { key = "stats", label = ns.L.WINDOW_PANE_STATS or "Stats" },
        { key = "titles", label = ns.L.WINDOW_PANE_TITLES or "Titles" },
        { key = "sets", label = ns.L.WINDOW_PANE_SETS or "Sets" },
    }
    f.paneButtons = {}
    local tabWidth = math.floor((ASIDE - 24 - 8) / 3)
    for i, tab in ipairs(paneTabs) do
        local b = Button(aside, tabWidth, 24, tab.label)
        b:SetPoint("TOPLEFT", aside, "TOPLEFT", 12 + (i - 1) * (tabWidth + 4), -10)
        b:SetScript("OnClick", function() f:ShowPane(tab.key) end)
        f.paneButtons[tab.key] = b
    end
    local content = CreateFrame("Frame", nil, aside)
    content:SetPoint("TOPLEFT", aside, "TOPLEFT", 6, -42)
    content:SetPoint("BOTTOMRIGHT", aside, "BOTTOMRIGHT", -4, 6)
    f.panes = {}
    f.panes.stats = Parts.CreateStats(content, { bars = true, gearSummary = true })
    local titles = CreateFrame("Frame", nil, content)
    titles:SetAllPoints(content)
    titles.list = Parts.CreateList(titles, 22, function(parent)
        local row = CreateFrame("Button", nil, parent)
        row.hl = Fill(row, { 1, 1, 1, 0.06 }, "HIGHLIGHT")
        row.hl:SetAllPoints()
        row.text = Text(row, "SourceSans3-Regular.ttf", 13, C.text)
        row.text:SetPoint("LEFT", 8, 0)
        row.text:SetPoint("RIGHT", -8, 0)
        row.text:SetJustifyH("LEFT")
        row:SetScript("OnClick", function(self) SetCurrentTitle(self.titleId) end)
        return row
    end, function(row, item)
        row.titleId = item.id
        row.text:SetText(item.name)
        local current = GetCurrentTitle()
        local selected = item.id == current or (item.id == -1 and (current == nil or current <= 0))
        local c = selected and C.goldBright or C.text
        row.text:SetTextColor(c[1], c[2], c[3])
    end)
    function titles:Refresh() self.list:SetData(Parts.GetTitles()) end
    f.panes.titles = titles
    local sets = CreateFrame("Frame", nil, content)
    sets:SetAllPoints(content)
    local listHolder = CreateFrame("Frame", nil, sets)
    listHolder:SetPoint("TOPLEFT")
    listHolder:SetPoint("BOTTOMRIGHT", 0, 70)
    sets.list = Parts.CreateList(listHolder, 34, function(parent)
        local row = CreateFrame("Button", nil, parent)
        row:RegisterForDrag("LeftButton")
        row.hl = Fill(row, { 1, 1, 1, 0.06 }, "HIGHLIGHT")
        row.hl:SetAllPoints()
        row.sel = Fill(row, { C.gold[1], C.gold[2], C.gold[3], 0.18 })
        row.sel:SetAllPoints()
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(26, 26)
        row.icon:SetPoint("LEFT", 6, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.text = Text(row, "SourceSans3-Bold.ttf", 13, C.text)
        row.text:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0)
        row.sub = Text(row, "SourceSans3-Regular.ttf", 11, C.muted)
        row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 0)
        row:SetScript("OnClick", function(self)
            sets.selected = self.setId
            sets.selectedName = self.setName
            sets:Refresh()
        end)
        row:SetScript("OnDoubleClick", function(self) Parts.EquipSet(self.setId) end)
        row:SetScript("OnDragStart", function(self) C_EquipmentSet.PickupEquipmentSet(self.setId) end)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetEquipmentSet(self.setId)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        return row
    end, function(row, item)
        row.setId = item.id
        row.setName = item.name
        row.icon:SetTexture(item.icon)
        row.text:SetText(item.name)
        if item.missing > 0 then
            row.sub:SetText(string.format(ns.L.WINDOW_SET_MISSING or "%d missing", item.missing))
            row.sub:SetTextColor(0.91, 0.42, 0.32)
        else
            row.sub:SetText(item.equipped and (ns.L.WINDOW_SET_EQUIPPED or "Equipped") or "")
            row.sub:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
        end
        row.sel:SetShown(sets.selected == item.id)
    end)
    local equip = Button(sets, 110, 26, ns.L.WINDOW_SET_EQUIP or EQUIPSET_EQUIP or "Equip")
    equip:SetPoint("BOTTOMLEFT", sets, "BOTTOMLEFT", 6, 38)
    equip:SetScript("OnClick", function() Parts.EquipSet(sets.selected) end)
    local save = Button(sets, 110, 26, ns.L.WINDOW_SET_SAVE or SAVE or "Save")
    save:SetPoint("LEFT", equip, "RIGHT", 6, 0)
    save:SetScript("OnClick", function() Parts.SaveSet(sets.selected, sets.selectedName) end)
    local new = Button(sets, 110, 26, ns.L.WINDOW_SET_NEW or "New Set")
    new:SetPoint("TOPLEFT", equip, "BOTTOMLEFT", 0, -6)
    new:SetScript("OnClick", Parts.NewSet)
    local delete = Button(sets, 110, 26, ns.L.WINDOW_SET_DELETE or DELETE or "Delete")
    delete:SetPoint("LEFT", new, "RIGHT", 6, 0)
    delete:SetScript("OnClick", function() Parts.DeleteSet(sets.selected, sets.selectedName) end)
    function sets:Refresh()
        local data = Parts.GetEquipmentSets()
        local found = false
        for _, item in ipairs(data) do
            if item.id == self.selected then found = true end
        end
        if not found then self.selected, self.selectedName = nil, nil end
        self.list:SetData(data)
    end
    f.panes.sets = sets
    f.activePane = "stats"
end
local function Create()
    local f = CreateFrame("Frame", "CharacterStatsWindowForged", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    Fill(f, C.frame, "BACKGROUND", -8):SetAllPoints()
    Border(f, { 0.42, 0.34, 0.19 }, 2)
    BuildRail(f)
    BuildHeader(f)
    BuildAside(f)
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", RAIL + 2, -(HEADER + 2))
    body:SetPoint("BOTTOMRIGHT", -(ASIDE + 2), 2)
    Fill(body, { 0.082, 0.071, 0.059 }):SetAllPoints()
    BuildStage(f, body)
    BuildGear(f, body)
    function f:ShowPane(key)
        self.activePane = key
        for paneKey, pane in pairs(self.panes) do
            pane:SetShown(paneKey == key)
        end
        for paneKey, b in pairs(self.paneButtons) do
            b:SetSelected(paneKey == key)
        end
        local pane = self.panes[key]
        if pane and pane.Refresh then pane:Refresh() end
    end
    function f:Refresh()
        local info = Parts.GetHeaderInfo()
        self.nameText:SetText(info.name)
        local cc = info.classColor
        local spec = info.specName and (info.specName .. " ") or ""
        local line = string.format("%s %d  |cff%02x%02x%02x%s%s|r", LEVEL or "Level", info.level, math.floor(cc.r * 255), math.floor(cc.g * 255), math.floor(cc.b * 255), spec, info.className)
        if info.guild then
            line = line .. "  |cffa8987a<" .. info.guild .. ">|r"
        end
        self.subText:SetText(line)
        self.crest:SetTexture(info.specIcon or 134400)
        self.ilvlValue:SetText(Parts.FormatItemLevel(info.equipped))
        if info.overall and info.overall > info.equipped + 0.005 then
            self.ilvlBags:SetText(string.format(ns.L.PAPERDOLL_ILVL_BAGS or "%s in bags", string.format("%.1f", info.overall)))
            self.ilvlBags:Show()
        else
            self.ilvlBags:Hide()
        end
        Parts.RefreshSlots(self)
        self.model:Load()
        self:ShowPane(self.activePane or "stats")
    end
    f:SetScript("OnShow", function(self) self:ShowPane(self.activePane or "stats") end)
    return f
end
ns.Window.RegisterLook("forged", {
    label = ns.L.WINDOW_LOOK_FORGED or "Forged Stone",
    labelKey = "WINDOW_LOOK_FORGED",
    Create = Create,
})
