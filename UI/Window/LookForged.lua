local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local W, H = 920, 610
local EDGE = 9
local RAIL = 82
local HEADER = 74
local ASIDE = 256
local SLOT = 44
local SLOT_GAP = 5
local ART = ns.Theme.ART
local C = {
    gold = { 0.86, 0.68, 0.30 },
    goldBright = { 1.0, 0.88, 0.55 },
    text = { 0.95, 0.91, 0.80 },
    muted = { 0.72, 0.66, 0.53 },
    goldLine = { 0.62, 0.47, 0.19 },
}
local function Text(parent, font, size, color, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(fs, font, size, flags or "")
    fs:SetTextColor(color[1], color[2], color[3])
    return fs
end
local function Slice(tex, file, margin)
    tex:SetTexture(ART .. file)
    if tex.SetTextureSliceMargins then
        tex:SetTextureSliceMargins(margin, margin, margin, margin)
        if Enum and Enum.UITextureSliceMode and tex.SetTextureSliceMode then
            tex:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    end
    return tex
end
local function Stone(parent, shade, layer, sublevel)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    t:SetTexture(ART .. "forged_stone", "REPEAT", "REPEAT")
    t:SetHorizTile(true)
    t:SetVertTile(true)
    t:SetVertexColor(shade, shade, shade)
    return t
end
local function Shade(parent, alpha, layer, sublevel)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 1)
    t:SetTexture(ART .. "page_edges")
    t:SetVertexColor(0, 0, 0, alpha or 0.8)
    return t
end
local function Plaque(parent, layer, sublevel)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    return Slice(t, "forged_plaque", 12)
end
local function GoldLine(parent, vertical)
    local t = parent:CreateTexture(nil, "BORDER")
    t:SetColorTexture(C.goldLine[1], C.goldLine[2], C.goldLine[3], 0.9)
    if vertical then t:SetWidth(1) else t:SetHeight(1) end
    return t
end
local function Filigree(parent, width)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(ART .. "forged_divider")
    t:SetSize(width, 14)
    return t
end
local function Button(parent, width, height, label)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.glow = b:CreateTexture(nil, "BACKGROUND", nil, -1)
    b.glow:SetTexture(ART .. "glow_radial")
    b.glow:SetPoint("TOPLEFT", -10, 8)
    b.glow:SetPoint("BOTTOMRIGHT", 10, -8)
    b.glow:SetVertexColor(1, 0.75, 0.3, 0.55)
    b.glow:SetBlendMode("ADD")
    b.glow:Hide()
    b.plate = Plaque(b, "BACKGROUND", 0)
    b.plate:SetAllPoints()
    b.label = Text(b, "Cinzel-Bold.ttf", 12, C.goldBright)
    b.label:SetPoint("CENTER", 0, 1)
    b.label:SetText(label or "")
    b:SetScript("OnEnter", function(self) self.plate:SetVertexColor(1.25, 1.2, 1.1) end)
    b:SetScript("OnLeave", function(self) if not self.selected then self.plate:SetVertexColor(1, 1, 1) end end)
    function b:SetSelected(on)
        self.selected = on
        self.glow:SetShown(on and true or false)
        self.plate:SetVertexColor(on and 1.25 or 1, on and 1.2 or 1, on and 1.1 or 1)
        local c = on and C.goldBright or C.muted
        self.label:SetTextColor(c[1], c[2], c[3])
    end
    return b
end
local function IconButton(parent, glyph, tooltip, onClick)
    local b = Button(parent, 28, 28, glyph)
    Parts.SetFont(b.label, "SourceSans3-Bold.ttf", 15, "")
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
        size = size, side = side, bezel = ART .. "forged_bezel", iconInset = 5, borderInset = 4,
        numberFont = "SourceSans3-Bold.ttf", textFont = "SourceSans3-Regular.ttf",
        ilvlSize = 13, rankSize = 11, detailSize = 11, emptyBorder = { 0.25, 0.22, 0.18 },
        flyoutEdge = C.gold, flyoutFill = { 0.07, 0.06, 0.05 },
    }
end
local function BuildRail(f)
    local rail = CreateFrame("Frame", nil, f)
    rail:SetPoint("TOPLEFT", EDGE, -EDGE)
    rail:SetPoint("BOTTOMLEFT", EDGE, EDGE)
    rail:SetWidth(RAIL)
    Stone(rail, 0.62):SetAllPoints()
    local shade = Shade(rail, 0.6)
    shade:SetAllPoints()
    local line = GoldLine(rail, true)
    line:SetPoint("TOPRIGHT")
    line:SetPoint("BOTTOMRIGHT")
    local tabs = {
        { key = "PaperDollFrame", label = ns.L.WINDOW_TAB_CHARACTER or "Character" },
        { key = "ReputationFrame", label = ns.L.WINDOW_TAB_REPUTATION or "Reputation" },
        { key = "TokenFrame", label = ns.L.WINDOW_TAB_CURRENCY or "Currency" },
    }
    f.tabs = {}
    for i, tab in ipairs(tabs) do
        local b = Button(rail, RAIL - 14, 50, tab.label)
        Parts.SetFont(b.label, "Cinzel-Bold.ttf", 8, "")
        b.label:SetWidth(RAIL - 20)
        b:SetPoint("TOP", rail, "TOP", 0, -(HEADER + 4) - (i - 1) * 58)
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
    local plate = Plaque(header)
    plate:SetPoint("TOPLEFT", 8, -8)
    plate:SetPoint("BOTTOMRIGHT", -8, 6)
    local crestGlow = header:CreateTexture(nil, "ARTWORK", nil, 0)
    crestGlow:SetTexture(ART .. "glow_radial")
    crestGlow:SetSize(84, 84)
    crestGlow:SetPoint("LEFT", 2, -1)
    crestGlow:SetVertexColor(1, 0.7, 0.25, 0.45)
    crestGlow:SetBlendMode("ADD")
    local crest = header:CreateTexture(nil, "ARTWORK", nil, 1)
    crest:SetSize(40, 40)
    crest:SetPoint("CENTER", crestGlow)
    crest:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.crest = crest
    local mask = header:CreateMaskTexture()
    mask:SetAllPoints(crest)
    mask:SetTexture("Interface\\Masks\\CircleMaskScalable", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    crest:AddMaskTexture(mask)
    local ring = header:CreateTexture(nil, "ARTWORK", nil, 3)
    ring:SetTexture(ART .. "forged_ring")
    ring:SetSize(54, 54)
    ring:SetPoint("CENTER", crest)
    f.nameText = Text(header, "Cinzel-Bold.ttf", 21, C.goldBright)
    f.nameText:SetPoint("TOPLEFT", crest, "TOPRIGHT", 18, 4)
    f.subText = Text(header, "SourceSans3-Regular.ttf", 13, C.muted)
    f.subText:SetPoint("TOPLEFT", f.nameText, "BOTTOMLEFT", 1, -4)
    local close = IconButton(header, "x", CLOSE or "Close", ns.Window.Close)
    close:SetPoint("RIGHT", -18, 1)
    f.ilvlValue = Text(header, "Cinzel-Bold.ttf", 25, { 0.80, 0.58, 1 })
    f.ilvlValue:SetPoint("RIGHT", close, "LEFT", -20, -4)
    f.ilvlLabel = Text(header, "Cinzel-Bold.ttf", 9, C.muted)
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
            local y = -10 - (i - 1) * (SLOT + SLOT_GAP)
            if side == "right" then
                b:SetPoint("TOPLEFT", body, "TOPLEFT", 12, y)
            else
                b:SetPoint("TOPRIGHT", body, "TOPRIGHT", -12, y)
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
    stage:SetPoint("TOP", body, "TOP", 0, -10)
    stage:SetPoint("BOTTOM", body, "BOTTOM", 0, 108)
    stage:SetWidth(252)
    local plate = Plaque(stage)
    plate:SetAllPoints()
    plate:SetVertexColor(0.85, 0.8, 0.9)
    local glow = stage:CreateTexture(nil, "BACKGROUND", nil, 2)
    glow:SetTexture(ART .. "glow_radial")
    glow:SetPoint("TOPLEFT", 6, -20)
    glow:SetPoint("BOTTOMRIGHT", -6, 20)
    glow:SetVertexColor(1, 0.72, 0.32, 0.30)
    glow:SetBlendMode("ADD")
    local floor = stage:CreateTexture(nil, "BACKGROUND", nil, 3)
    floor:SetTexture(ART .. "ring_floor")
    floor:SetSize(220, 30)
    floor:SetPoint("BOTTOM", stage, "BOTTOM", 0, 10)
    floor:SetVertexColor(1, 0.75, 0.35, 0.55)
    floor:SetBlendMode("ADD")
    f.model = Parts.CreateModel(stage)
    f.model:SetPoint("TOPLEFT", 6, -6)
    f.model:SetPoint("BOTTOMRIGHT", -6, 6)
    local controls = CreateFrame("Frame", nil, body)
    controls:SetSize(260, 30)
    controls:SetPoint("BOTTOM", body, "BOTTOM", 0, 12)
    f.setButton = Button(controls, 150, 28, ns.L.WINDOW_SETS or "Equipment Sets")
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
    Stone(aside, 0.72):SetAllPoints()
    local shade = Shade(aside, 0.55)
    shade:SetAllPoints()
    local line = GoldLine(aside, true)
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
        local b = Button(aside, tabWidth, 28, tab.label)
        b:SetPoint("TOPLEFT", aside, "TOPLEFT", 12 + (i - 1) * (tabWidth + 4), -10)
        b:SetScript("OnClick", function() f:ShowPane(tab.key) end)
        f.paneButtons[tab.key] = b
    end
    local fil = Filigree(aside, ASIDE - 30)
    fil:SetPoint("TOP", aside, "TOP", 0, -44)
    local content = CreateFrame("Frame", nil, aside)
    content:SetPoint("TOPLEFT", aside, "TOPLEFT", 6, -60)
    content:SetPoint("BOTTOMRIGHT", aside, "BOTTOMRIGHT", -4, 6)
    f.panes = {}
    f.panes.stats = Parts.CreateStats(content, { bars = true, gearSummary = true })
    local ui = {
        Text = Text, Button = Button, text = C.text, muted = C.muted, accent = C.goldBright,
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
    local base = Stone(f, 0.85, "BACKGROUND", -8)
    base:SetPoint("TOPLEFT", 4, -4)
    base:SetPoint("BOTTOMRIGHT", -4, 4)
    local vignette = Shade(f, 0.75, "BACKGROUND", -7)
    vignette:SetAllPoints(base)
    BuildRail(f)
    BuildHeader(f)
    BuildAside(f)
    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", EDGE + RAIL, -(EDGE + HEADER))
    body:SetPoint("BOTTOMRIGHT", -(EDGE + ASIDE), EDGE)
    local bodyShade = Shade(body, 0.45)
    bodyShade:SetAllPoints()
    BuildStage(f, body)
    BuildGear(f, body)
    local function TabPanel(module)
        local panel = module.Create(f, {
            Text = Text, Button = Button, text = C.text, muted = C.muted, accent = C.goldBright,
            bodyFont = "SourceSans3-Regular.ttf", boldFont = "SourceSans3-Bold.ttf", headerFont = "Cinzel-Bold.ttf",
            barTrack = { 0.05, 0.045, 0.04, 1 }, rowFill = { 0, 0, 0, 0.25 }, barWidth = 210, boxEdge = C.goldLine,
        })
        panel:SetPoint("TOPLEFT", EDGE + RAIL, -(EDGE + HEADER))
        panel:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
        panel:SetFrameLevel(f:GetFrameLevel() + 40)
        Stone(panel, 0.8):SetAllPoints()
        local shade = Shade(panel, 0.5)
        shade:SetAllPoints()
        local detailBg = Stone(panel, 0.66, "BACKGROUND", 2)
        detailBg:SetPoint("TOPRIGHT")
        detailBg:SetPoint("BOTTOMRIGHT")
        detailBg:SetWidth(ASIDE)
        local detailLine = GoldLine(panel, true)
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
    local trim = CreateFrame("Frame", nil, f)
    trim:SetAllPoints()
    trim:SetFrameLevel(f:GetFrameLevel() + 60)
    local frameArt = trim:CreateTexture(nil, "OVERLAY")
    frameArt:SetPoint("TOPLEFT", -2, 2)
    frameArt:SetPoint("BOTTOMRIGHT", 2, -2)
    Slice(frameArt, "forged_frame", 32)
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
            line = line .. "  |cffb8a77f<" .. info.guild .. ">|r"
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
    label = ns.L.WINDOW_LOOK_FORGED or "Forged Stone",
    labelKey = "WINDOW_LOOK_FORGED",
    Create = Create,
})
