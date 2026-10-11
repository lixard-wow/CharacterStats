local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local W, H = 920, 610
local EDGE = 6
local RAIL = 82
local HEADER = 70
local ASIDE = 256
local SLOT = 42
local SLOT_GAP = 6
local RADIUS = 4
local ART = ns.Theme.ART
local P = ns.Theme.THEMES.ledger.colors
local C = {
    window = P.window, surface = P.surface, nav = P.nav, field = P.field, hover = P.hover,
    border = P.border, line = P.line, accent = P.accent, text = P.text, muted = P.muted,
    title = P.title, heading = P.heading, buttonText = P.buttonText,
}
local function Rgb(c, alpha)
    return c[1], c[2], c[3], alpha or c[4] or 1
end
local function Box(frame, fill, edge, radius, sublevel)
    local base = sublevel or 0
    local e = frame:CreateTexture(nil, "BACKGROUND", nil, base)
    e:SetAllPoints()
    ns.Theme.Shape(e, radius or RADIUS)
    e:SetVertexColor(Rgb(edge))
    local f = frame:CreateTexture(nil, "BACKGROUND", nil, base + 1)
    f:SetPoint("TOPLEFT", 1, -1)
    f:SetPoint("BOTTOMRIGHT", -1, 1)
    ns.Theme.Shape(f, radius or RADIUS)
    f:SetVertexColor(Rgb(fill))
    return f, e
end
local function Line(parent, vertical, color)
    local t = parent:CreateTexture(nil, "BORDER")
    t:SetColorTexture(Rgb(color or C.line))
    if vertical then t:SetWidth(1) else t:SetHeight(1) end
    return t
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
    b.fill, b.edge = Box(b, C.surface, C.border)
    b.label = Text(b, "SourceSans3-Bold.ttf", 12, C.buttonText)
    b.label:SetPoint("CENTER", 0, 0)
    b.label:SetText(label or "")
    b:SetScript("OnEnter", function(self)
        if not self.selected then self.fill:SetVertexColor(Rgb(C.hover)) end
    end)
    b:SetScript("OnLeave", function(self)
        if not self.selected then self.fill:SetVertexColor(Rgb(C.surface)) end
    end)
    function b:SetSelected(on)
        self.selected = on
        self.fill:SetVertexColor(Rgb(on and C.hover or C.surface))
        self.edge:SetVertexColor(Rgb(on and C.accent or C.border))
        local c = on and C.title or C.muted
        self.label:SetTextColor(c[1], c[2], c[3])
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
local function SlotStyle(side, size)
    return {
        size = size, side = side, radius = RADIUS, iconInset = 3, borderInset = 1,
        numberFont = "SourceSans3-Bold.ttf", textFont = "SourceSans3-Regular.ttf",
        ilvlSize = 13, rankSize = 11, detailSize = 11, emptyBorder = C.border,
        flyoutEdge = C.border, flyoutFill = C.window,
    }
end
local function BuildRail(f)
    local rail = CreateFrame("Frame", nil, f)
    rail:SetPoint("TOPLEFT", EDGE, -EDGE)
    rail:SetPoint("BOTTOMLEFT", EDGE, EDGE)
    rail:SetWidth(RAIL)
    local bg = rail:CreateTexture(nil, "BACKGROUND", nil, 4)
    bg:SetAllPoints()
    bg:SetColorTexture(Rgb(C.nav))
    local line = Line(rail, true)
    line:SetPoint("TOPRIGHT")
    line:SetPoint("BOTTOMRIGHT")
    local tabs = {
        { key = "PaperDollFrame", label = ns.L.WINDOW_TAB_CHARACTER or "Character" },
        { key = "ReputationFrame", label = ns.L.WINDOW_TAB_REPUTATION or "Reputation" },
        { key = "TokenFrame", label = ns.L.WINDOW_TAB_CURRENCY or "Currency" },
    }
    f.tabs = {}
    for i, tab in ipairs(tabs) do
        local b = Button(rail, RAIL - 14, 44, tab.label)
        Parts.SetFont(b.label, "SourceSans3-Bold.ttf", 12, "")
        b.label:SetWidth(RAIL - 18)
        b:SetPoint("TOP", rail, "TOP", 0, -(HEADER + 6) - (i - 1) * 50)
        b:SetScript("OnClick", function() ns.Window.ShowTab(tab.key) end)
        b:SetSelected(tab.key == "PaperDollFrame")
        f.tabs[tab.key] = b
    end
end
local function BuildHeader(f)
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", EDGE + RAIL, -EDGE)
    header:SetPoint("TOPRIGHT", -EDGE, -EDGE)
    header:SetHeight(HEADER)
    local line = Line(header, false)
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    local accent = header:CreateTexture(nil, "BORDER", nil, 1)
    accent:SetPoint("BOTTOMLEFT", 16, 0)
    accent:SetSize(56, 1)
    accent:SetColorTexture(Rgb(C.accent))
    local crestBox = CreateFrame("Frame", nil, header)
    crestBox:SetSize(46, 46)
    crestBox:SetPoint("LEFT", 16, 0)
    Box(crestBox, C.field, C.border)
    local crest = crestBox:CreateTexture(nil, "ARTWORK")
    crest:SetPoint("TOPLEFT", 3, -3)
    crest:SetPoint("BOTTOMRIGHT", -3, 3)
    crest:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.crest = crest
    f.nameText = Text(header, "Cinzel-Bold.ttf", 19, C.title)
    f.nameText:SetPoint("TOPLEFT", crestBox, "TOPRIGHT", 14, -2)
    f.subText = Text(header, "SourceSans3-Regular.ttf", 13, C.muted)
    f.subText:SetPoint("TOPLEFT", f.nameText, "BOTTOMLEFT", 0, -5)
    local close = IconButton(header, "x", CLOSE or "Close", ns.Window.Close)
    close:SetPoint("RIGHT", -14, 2)
    f.ilvlValue = Text(header, "Cinzel-Bold.ttf", 22, C.accent)
    f.ilvlValue:SetPoint("RIGHT", close, "LEFT", -18, -4)
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
            local b = Parts.CreateSlot(body, slot, SlotStyle(side, SLOT))
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
        local b = Parts.CreateSlot(body, slot, SlotStyle(i == 1 and "left" or "right", SLOT + 4))
        b:SetPoint("BOTTOM", body, "BOTTOM", (i == 1 and -1 or 1) * (SLOT / 2 + 6), 52)
        f.slotButtons[#f.slotButtons + 1] = b
    end
end
local function BuildStage(f, body)
    local stage = CreateFrame("Frame", nil, body)
    stage:SetPoint("TOP", body, "TOP", 0, -12)
    stage:SetPoint("BOTTOM", body, "BOTTOM", 0, 108)
    stage:SetWidth(250)
    Box(stage, C.field, C.border)
    local glow = stage:CreateTexture(nil, "BACKGROUND", nil, 3)
    glow:SetTexture(ART .. "glow_radial")
    glow:SetPoint("TOPLEFT", 10, -30)
    glow:SetPoint("BOTTOMRIGHT", -10, 30)
    glow:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.12)
    glow:SetBlendMode("ADD")
    local floor = stage:CreateTexture(nil, "BACKGROUND", nil, 4)
    floor:SetTexture(ART .. "ring_floor")
    floor:SetSize(210, 26)
    floor:SetPoint("BOTTOM", stage, "BOTTOM", 0, 12)
    floor:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.35)
    floor:SetBlendMode("ADD")
    f.model = Parts.CreateModel(stage)
    f.model:SetPoint("TOPLEFT", 4, -4)
    f.model:SetPoint("BOTTOMRIGHT", -4, 4)
    local controls = CreateFrame("Frame", nil, body)
    controls:SetSize(260, 28)
    controls:SetPoint("BOTTOM", body, "BOTTOM", 0, 14)
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
    aside:SetPoint("TOPRIGHT", -EDGE, -(EDGE + HEADER))
    aside:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
    aside:SetWidth(ASIDE)
    local bg = aside:CreateTexture(nil, "BACKGROUND", nil, 4)
    bg:SetAllPoints()
    bg:SetColorTexture(Rgb(C.surface))
    local line = Line(aside, true)
    line:SetPoint("TOPLEFT")
    line:SetPoint("BOTTOMLEFT")
    local paneTabs = {
        { key = "stats", label = ns.L.WINDOW_PANE_STATS or "Stats" },
        { key = "titles", label = ns.L.WINDOW_PANE_TITLES or "Titles" },
        { key = "sets", label = ns.L.WINDOW_PANE_SETS or "Sets" },
    }
    f.paneButtons = {}
    local tabWidth = math.floor((ASIDE - 24 - 8) / 3)
    for i, tab in ipairs(paneTabs) do
        local b = Button(aside, tabWidth, 26, tab.label)
        b:SetPoint("TOPLEFT", aside, "TOPLEFT", 12 + (i - 1) * (tabWidth + 4), -12)
        b:SetScript("OnClick", function() f:ShowPane(tab.key) end)
        f.paneButtons[tab.key] = b
    end
    local sep = Line(aside, false)
    sep:SetPoint("TOPLEFT", 12, -48)
    sep:SetPoint("TOPRIGHT", -12, -48)
    local content = CreateFrame("Frame", nil, aside)
    content:SetPoint("TOPLEFT", aside, "TOPLEFT", 6, -54)
    content:SetPoint("BOTTOMRIGHT", aside, "BOTTOMRIGHT", -4, 6)
    f.panes = {}
    f.panes.stats = Parts.CreateStats(content, { bars = true, gearSummary = true })
    local ui = {
        Text = Text, Button = Button, text = C.text, muted = C.muted, accent = C.accent,
        bodyFont = "SourceSans3-Regular.ttf", boldFont = "SourceSans3-Bold.ttf", headerFont = "Cinzel-Bold.ttf",
    }
    f.panes.titles = Parts.CreateTitlesPane(content, ui)
    f.panes.sets = Parts.CreateSetsPane(content, ui)
    f.activePane = "stats"
end
local function Create()
    local f = CreateFrame("Frame", "CharacterStatsWindowForged", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    Box(f, C.window, C.border, RADIUS, -8)
    local ring = f:CreateTexture(nil, "BACKGROUND", nil, -6)
    ring:SetPoint("TOPLEFT", 4, -4)
    ring:SetPoint("BOTTOMRIGHT", -4, 4)
    ns.Theme.Shape(ring, RADIUS)
    ring:SetVertexColor(Rgb(C.line))
    local ringFill = f:CreateTexture(nil, "BACKGROUND", nil, -5)
    ringFill:SetPoint("TOPLEFT", ring, 1, -1)
    ringFill:SetPoint("BOTTOMRIGHT", ring, -1, 1)
    ns.Theme.Shape(ringFill, RADIUS)
    ringFill:SetVertexColor(Rgb(C.window))
    BuildRail(f)
    BuildHeader(f)
    BuildAside(f)
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", EDGE + RAIL, -(EDGE + HEADER))
    body:SetPoint("BOTTOMRIGHT", -(EDGE + ASIDE), EDGE)
    BuildStage(f, body)
    BuildGear(f, body)
    local function TabPanel(module)
        local panel = module.Create(f, {
            Text = Text, Button = Button, text = C.text, muted = C.muted, accent = C.accent,
            bodyFont = "SourceSans3-Regular.ttf", boldFont = "SourceSans3-Bold.ttf", headerFont = "Cinzel-Bold.ttf",
            barTrack = C.field, rowFill = { C.surface[1], C.surface[2], C.surface[3], 0.7 }, barWidth = 210,
            boxEdge = C.border, boxFill = C.field,
        })
        panel:SetPoint("TOPLEFT", EDGE + RAIL, -(EDGE + HEADER))
        panel:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
        panel:SetFrameLevel(f:GetFrameLevel() + 40)
        local bg = panel:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(Rgb(C.window))
        local detailBg = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
        detailBg:SetPoint("TOPRIGHT")
        detailBg:SetPoint("BOTTOMRIGHT")
        detailBg:SetWidth(ASIDE)
        detailBg:SetColorTexture(Rgb(C.surface))
        local detailLine = Line(panel, true)
        detailLine:SetPoint("TOPRIGHT", -ASIDE, 0)
        detailLine:SetPoint("BOTTOMRIGHT", -ASIDE, 0)
        panel.list:SetPoint("TOPLEFT", 14, -12)
        panel.list:SetPoint("BOTTOMRIGHT", -(ASIDE + 12), 10)
        panel.detail:SetPoint("TOPRIGHT", -14, -14)
        panel.detail:SetPoint("BOTTOMRIGHT", -14, 10)
        panel.detail:SetWidth(ASIDE - 28)
        panel:Hide()
        return panel
    end
    f.rep = TabPanel(ns.WindowReputation)
    f.cur = TabPanel(ns.WindowCurrency)
    f.activeTab = "PaperDollFrame"
    function f:ShowTab(sub)
        self.activeTab = sub
        self.rep:SetShown(sub == "ReputationFrame")
        self.cur:SetShown(sub == "TokenFrame")
        if self.tabs.TokenFrame then
            self.tabs.TokenFrame:SetShown(C_CurrencyInfo.GetCurrencyListSize() > 0)
        end
        for key, b in pairs(self.tabs) do b:SetSelected(key == sub) end
    end
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
            line = line .. "  <" .. info.guild .. ">"
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
        if self.activeTab == "ReputationFrame" then
            self.rep:Refresh()
            return
        end
        if self.activeTab == "TokenFrame" then
            self.cur:Refresh()
            return
        end
        Parts.RefreshSlots(self)
        self.model:Load()
        self:ShowPane(self.activePane or "stats")
    end
    f:SetScript("OnShow", function(self) self:ShowPane(self.activePane or "stats") end)
    return f
end
ns.Window.RegisterLook("forged", {
    label = ns.L.WINDOW_LOOK_FORGED or "Artisan",
    labelKey = "WINDOW_LOOK_FORGED",
    Create = Create,
})
