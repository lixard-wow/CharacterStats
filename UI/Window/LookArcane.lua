local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local W, H = 900, 610
local HEADER = 54
local STRIP = 118
local SLOT = 40
local SLOT_GAP = 6
local ARC = { 30, 16, 6, 0, 0, 6, 16, 30 }
local SECONDARY = { "crit", "haste", "mastery", "versatility" }
local C = {
    ground = { 0.051, 0.043, 0.110 },
    header = { 0.071, 0.059, 0.149 },
    edge = { 0.294, 0.247, 0.561 },
    line = { 0.165, 0.141, 0.322 },
    card = { 0.090, 0.075, 0.227 },
    cardEdge = { 0.184, 0.157, 0.392 },
    violet = { 0.486, 0.392, 1 },
    gold = { 0.949, 0.780, 0.361 },
    text = { 0.925, 0.910, 1 },
    muted = { 0.643, 0.624, 0.780 },
    pill = { 0.169, 0.129, 0.388 },
    track = { 0.149, 0.125, 0.333 },
}
local function Text(parent, font, size, color, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(fs, font, size, flags or "")
    fs:SetTextColor(color[1], color[2], color[3])
    return fs
end
local function RoundBox(frame, fill, edge, radius)
    local e = frame:CreateTexture(nil, "BACKGROUND", nil, -2)
    e:SetAllPoints()
    ns.Theme.Shape(e, radius)
    e:SetVertexColor(edge[1], edge[2], edge[3], edge[4] or 1)
    local f = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    f:SetPoint("TOPLEFT", 1, -1)
    f:SetPoint("BOTTOMRIGHT", -1, 1)
    ns.Theme.Shape(f, radius)
    f:SetVertexColor(fill[1], fill[2], fill[3], fill[4] or 1)
    return f, e
end
local function Button(parent, width, height, label)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.fill, b.edge = RoundBox(b, C.card, C.cardEdge, 4)
    b.label = Text(b, "Barlow-SemiBold.ttf", 12, C.text)
    b.label:SetPoint("CENTER")
    b.label:SetText(label or "")
    b:SetScript("OnEnter", function(self) self.edge:SetVertexColor(C.violet[1], C.violet[2], C.violet[3]) end)
    b:SetScript("OnLeave", function(self) if not self.selected then self.edge:SetVertexColor(C.cardEdge[1], C.cardEdge[2], C.cardEdge[3]) end end)
    function b:SetSelected(on)
        self.selected = on
        local fill = on and C.pill or C.card
        local edge = on and C.violet or C.cardEdge
        self.fill:SetVertexColor(fill[1], fill[2], fill[3])
        self.edge:SetVertexColor(edge[1], edge[2], edge[3])
        local tc = on and C.text or C.muted
        self.label:SetTextColor(tc[1], tc[2], tc[3])
    end
    return b
end
local function CircleButton(parent, glyph, tooltip, onClick)
    local b = Button(parent, 28, 28, glyph)
    Parts.SetFont(b.label, "Barlow-SemiBold.ttf", 14, "")
    b:SetScript("OnClick", onClick)
    b:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip, 1, 1, 1)
        GameTooltip:Show()
    end)
    b:HookScript("OnLeave", GameTooltip_Hide)
    return b
end
local function BuildHeader(f)
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(HEADER)
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(C.header[1], C.header[2], C.header[3])
    local line = header:CreateTexture(nil, "BORDER")
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)
    line:SetColorTexture(C.line[1], C.line[2], C.line[3])
    local halo = header:CreateTexture(nil, "ARTWORK", nil, 0)
    halo:SetTexture(ns.Theme.ART .. "glow_radial")
    halo:SetSize(64, 64)
    halo:SetPoint("LEFT", 2, 0)
    halo:SetVertexColor(C.gold[1], C.gold[2], C.gold[3], 0.5)
    halo:SetBlendMode("ADD")
    local crest = header:CreateTexture(nil, "ARTWORK", nil, 2)
    crest:SetSize(34, 34)
    crest:SetPoint("CENTER", halo)
    crest:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.crest = crest
    f.nameText = Text(header, "BarlowCondensed-Bold.ttf", 22, C.text)
    f.nameText:SetPoint("TOPLEFT", crest, "TOPRIGHT", 14, 2)
    f.subText = Text(header, "Barlow-Regular.ttf", 12, C.muted)
    f.subText:SetPoint("TOPLEFT", f.nameText, "BOTTOMLEFT", 0, -2)
    local pill = CreateFrame("Frame", nil, header)
    pill:SetSize(330, 36)
    pill:SetPoint("CENTER", header, "CENTER", 40, 0)
    RoundBox(pill, { 0.039, 0.031, 0.086 }, C.line, 10)
    local tabs = {
        { key = "PaperDollFrame", label = ns.L.WINDOW_TAB_CHARACTER or "Character" },
        { key = "ReputationFrame", label = ns.L.WINDOW_TAB_REPUTATION or "Reputation" },
        { key = "TokenFrame", label = ns.L.WINDOW_TAB_CURRENCY or "Currency" },
    }
    f.tabs = {}
    for i, tab in ipairs(tabs) do
        local b = Button(pill, 104, 28, tab.label)
        b:SetPoint("LEFT", pill, "LEFT", 4 + (i - 1) * 108, 0)
        b:SetScript("OnClick", function() ns.Window.ShowTab(tab.key) end)
        b:SetSelected(tab.key == "PaperDollFrame")
        f.tabs[tab.key] = b
    end
    local close = Button(header, 30, 30, "X")
    close:SetPoint("RIGHT", -12, 0)
    close:SetScript("OnClick", ns.Window.Close)
    f.setsButton = Button(header, 64, 30, ns.L.WINDOW_PANE_SETS or "Sets")
    f.setsButton:SetPoint("RIGHT", close, "LEFT", -6, 0)
    f.setsButton:SetScript("OnClick", function() f:TogglePanel("sets") end)
    f.titlesButton = Button(header, 64, 30, ns.L.WINDOW_PANE_TITLES or "Titles")
    f.titlesButton:SetPoint("RIGHT", f.setsButton, "LEFT", -6, 0)
    f.titlesButton:SetScript("OnClick", function() f:TogglePanel("titles") end)
end
local function BuildStage(f)
    local stage = CreateFrame("Frame", nil, f)
    stage:SetPoint("TOPLEFT", 1, -(HEADER + 1))
    stage:SetPoint("BOTTOMRIGHT", -1, STRIP)
    f.stage = stage
    local glow = stage:CreateTexture(nil, "BACKGROUND", nil, 1)
    glow:SetTexture(ns.Theme.ART .. "glow_radial")
    glow:SetSize(560, 440)
    glow:SetPoint("CENTER", stage, "CENTER", 0, -10)
    glow:SetVertexColor(0.30, 0.20, 0.70, 0.55)
    f.ilvlLabel = Text(stage, "Barlow-SemiBold.ttf", 10, C.muted)
    f.ilvlLabel:SetPoint("TOP", stage, "TOP", 0, -10)
    f.ilvlLabel:SetText((ns.L.STAT_ILVL or "Item Level"):upper())
    f.ilvlValue = Text(stage, "BarlowCondensed-Bold.ttf", 30, C.gold)
    f.ilvlValue:SetPoint("TOP", f.ilvlLabel, "BOTTOM", 0, -1)
    f.ilvlBags = Text(stage, "Barlow-Regular.ttf", 11, C.muted)
    f.ilvlBags:SetPoint("TOP", f.ilvlValue, "BOTTOM", 0, -1)
    f.model = Parts.CreateModel(stage)
    f.model:SetSize(250, 300)
    f.model:SetPoint("BOTTOM", stage, "BOTTOM", 0, 62)
    local ring = stage:CreateTexture(nil, "ARTWORK")
    ring:SetTexture(ns.Theme.ART .. "ring_floor")
    ring:SetSize(300, 38)
    ring:SetPoint("CENTER", f.model, "BOTTOM", 0, 8)
    ring:SetVertexColor(C.violet[1], C.violet[2], C.violet[3], 0.9)
    ring:SetBlendMode("ADD")
    f.slotButtons = {}
    local function Column(list, side)
        for i, slot in ipairs(list) do
            local b = Parts.CreateSlot(stage, slot, {
                size = SLOT, side = side, radius = 4, glow = { 0.5, 0.35, 1, 0.35 },
                numberFont = "Barlow-SemiBold.ttf", textFont = "Barlow-Regular.ttf",
                ilvlSize = 13, rankSize = 11, detailSize = 11, emptyBorder = C.cardEdge,
                missingColor = { 1, 0.48, 0.42 },
            })
            local y = -14 - (i - 1) * (SLOT + SLOT_GAP)
            if side == "right" then
                b:SetPoint("TOPLEFT", stage, "TOPLEFT", 22 + ARC[i], y)
            else
                b:SetPoint("TOPRIGHT", stage, "TOPRIGHT", -22 - ARC[i], y)
            end
            f.slotButtons[#f.slotButtons + 1] = b
        end
    end
    Column(Parts.LEFT, "right")
    Column(Parts.RIGHT, "left")
    for i, slot in ipairs(Parts.WEAPONS) do
        local b = Parts.CreateSlot(stage, slot, {
            size = SLOT + 4, side = i == 1 and "left" or "right", radius = 4, glow = { 0.5, 0.35, 1, 0.35 },
            numberFont = "Barlow-SemiBold.ttf", textFont = "Barlow-Regular.ttf",
            ilvlSize = 13, rankSize = 11, detailSize = 11, emptyBorder = C.cardEdge, missingColor = { 1, 0.48, 0.42 },
        })
        b:SetPoint("BOTTOM", stage, "BOTTOM", (i == 1 and -1 or 1) * (SLOT / 2 + 6), 10)
        f.slotButtons[#f.slotButtons + 1] = b
    end
    local left = CircleButton(stage, "<", ns.L.WINDOW_ROTATE_LEFT or "Rotate left", function() f.model:Rotate(-0.3) end)
    left:SetPoint("BOTTOM", stage, "BOTTOM", -(SLOT + 52), 18)
    local right = CircleButton(stage, ">", ns.L.WINDOW_ROTATE_RIGHT or "Rotate right", function() f.model:Rotate(0.3) end)
    right:SetPoint("BOTTOM", stage, "BOTTOM", SLOT + 52, 18)
    local reset = CircleButton(stage, "o", ns.L.WINDOW_RESET_CAMERA or "Reset camera", function() f.model:Reset() end)
    reset:SetPoint("LEFT", right, "RIGHT", 6, 0)
end
local function BuildPanel(f)
    local panel = CreateFrame("Frame", nil, f)
    panel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -(HEADER + 8))
    panel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, STRIP + 8)
    panel:SetWidth(270)
    panel:SetFrameLevel(f:GetFrameLevel() + 30)
    panel:EnableMouse(true)
    RoundBox(panel, { 0.067, 0.055, 0.165, 0.97 }, C.violet, 10)
    local inner = CreateFrame("Frame", nil, panel)
    inner:SetPoint("TOPLEFT", 8, -10)
    inner:SetPoint("BOTTOMRIGHT", -6, 6)
    local ui = {
        Text = Text, Button = Button, text = C.text, muted = C.muted, accent = C.gold,
        bodyFont = "Barlow-Regular.ttf", boldFont = "Barlow-SemiBold.ttf", buttonWidth = 118,
    }
    f.panes = {
        titles = Parts.CreateTitlesPane(inner, ui),
        sets = Parts.CreateSetsPane(inner, ui),
    }
    panel:Hide()
    f.panel = panel
end
local function StatCard(parent, width)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(width, STRIP - 22)
    RoundBox(card, C.card, C.cardEdge, 10)
    card:EnableMouse(true)
    card:SetScript("OnLeave", GameTooltip_Hide)
    return card
end
local function BuildStrip(f)
    local strip = CreateFrame("Frame", nil, f)
    strip:SetPoint("BOTTOMLEFT", 1, 1)
    strip:SetPoint("BOTTOMRIGHT", -1, 1)
    strip:SetHeight(STRIP)
    local bg = strip:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.059, 0.047, 0.133)
    local line = strip:CreateTexture(nil, "BORDER")
    line:SetPoint("TOPLEFT")
    line:SetPoint("TOPRIGHT")
    line:SetHeight(1)
    line:SetColorTexture(C.line[1], C.line[2], C.line[3])
    local gap = 10
    local listWidth = 162
    local cardWidth = math.floor((W - 2 - 32 - listWidth * 2 - gap * 5) / 4)
    local function ListCard(title)
        local card = StatCard(strip, listWidth)
        card.title = Text(card, "BarlowCondensed-Bold.ttf", 13, C.gold)
        card.title:SetPoint("TOPLEFT", 12, -9)
        card.title:SetText(title)
        card.rows = {}
        for i = 1, 4 do
            local row = CreateFrame("Frame", nil, card)
            row:SetSize(listWidth - 24, 16)
            row:SetPoint("TOPLEFT", 12, -28 - (i - 1) * 16)
            row:EnableMouse(true)
            row.label = Text(row, "Barlow-Regular.ttf", 12, C.text)
            row.label:SetPoint("LEFT")
            row.value = Text(row, "Barlow-SemiBold.ttf", 12, C.text)
            row.value:SetPoint("RIGHT")
            row:SetScript("OnEnter", function(self)
                if self.stat then
                    ns.PaperdollPanel.ShowStatTooltip(self, self.stat.id, self.stat.label, self.valueText, self.stat.tooltip)
                end
            end)
            row:SetScript("OnLeave", GameTooltip_Hide)
            card.rows[i] = row
        end
        return card
    end
    f.attrCard = ListCard(ns.L.HEADER_ATTRIBUTES or "Attributes")
    f.attrCard:SetPoint("TOPLEFT", strip, "TOPLEFT", 16, -11)
    f.secondaryCards = {}
    local previous = f.attrCard
    for i = 1, 4 do
        local card = StatCard(strip, cardWidth)
        card:SetPoint("LEFT", previous, "RIGHT", gap, 0)
        card.label = Text(card, "Barlow-Regular.ttf", 12, C.text)
        card.label:SetPoint("TOPLEFT", 12, -10)
        card.value = Text(card, "BarlowCondensed-Bold.ttf", 24, C.text)
        card.value:SetPoint("TOPLEFT", card.label, "BOTTOMLEFT", 0, -4)
        card.track = card:CreateTexture(nil, "ARTWORK")
        card.track:SetPoint("TOPLEFT", card.value, "BOTTOMLEFT", 0, -7)
        card.track:SetSize(cardWidth - 24, 5)
        card.trackWidth = cardWidth - 24
        card.track:SetColorTexture(C.track[1], C.track[2], C.track[3])
        card.fill = card:CreateTexture(nil, "ARTWORK", nil, 1)
        card.fill:SetPoint("LEFT", card.track, "LEFT")
        card.fill:SetHeight(5)
        card.marker = card:CreateTexture(nil, "ARTWORK", nil, 2)
        card.marker:SetSize(2, 11)
        card.marker:SetPoint("CENTER", card.track, "LEFT", (cardWidth - 24) * 0.6, 0)
        card.marker:SetColorTexture(C.gold[1], C.gold[2], C.gold[3])
        card.note = Text(card, "Barlow-Regular.ttf", 10, C.muted)
        card.note:SetPoint("TOPLEFT", card.track, "BOTTOMLEFT", 0, -5)
        card.note:SetWidth(cardWidth - 24)
        card.note:SetJustifyH("LEFT")
        card.note:SetWordWrap(false)
        card:SetScript("OnEnter", function(self)
            if self.stat then
                ns.PaperdollPanel.ShowStatTooltip(self, self.stat.id, self.stat.label, self.valueText, self.stat.tooltip)
            end
        end)
        f.secondaryCards[i] = card
        previous = card
    end
    f.otherCard = ListCard(ns.L.WINDOW_OTHER_STATS or "Defense & Utility")
    f.otherCard:SetPoint("LEFT", previous, "RIGHT", gap, 0)
end
local function FillList(card, stats, db)
    for i, row in ipairs(card.rows) do
        local stat = stats[i]
        row.stat = stat
        if stat then
            local value = ns.Styles.FormatValue(stat, db)
            local r, g, b = ns.GetStatColor(stat.id)
            row.label:SetText(stat.label)
            row.label:SetTextColor(r, g, b)
            row.value:SetText(value)
            row.value:SetTextColor(r, g, b)
            row.valueText = value
            row:Show()
        else
            row:Hide()
        end
    end
end
local function FillSecondary(card, stat, db)
    card.stat = stat
    if not stat then
        card:Hide()
        return
    end
    card:Show()
    local r, g, b = ns.GetStatColor(stat.id)
    local value = ns.Styles.FormatValue(stat, db)
    card.valueText = value
    card.label:SetText(stat.label)
    card.label:SetTextColor(r, g, b)
    card.value:SetText(value)
    card.value:SetTextColor(r, g, b)
    card.fill:SetColorTexture(r, g, b)
    local D = ns.Diminishing
    local ratingId = D and D.RatingFor(stat.id)
    local info = ratingId and D.Info(ratingId)
    local threshold = ratingId and D.FirstThreshold(ratingId)
    local width = card.trackWidth
    if info and threshold and threshold > 0 then
        local fraction = math.min(1, info.raw / (threshold / 0.6))
        card.fill:SetWidth(math.max(1, width * fraction))
        card.fill:Show()
        card.marker:Show()
        if info.penalty > 0 then
            card.note:SetText(string.format(ns.L.WINDOW_DR_PENALTY or "%d%% penalty", math.floor(info.penalty * 100 + 0.5)))
        elseif info.toNext then
            card.note:SetText(string.format(ns.L.WINDOW_DR_TO_NEXT or "%s rating to penalty", ns.FormatNumber(info.toNext, 0)))
        else
            card.note:SetText("")
        end
    else
        card.fill:Hide()
        card.marker:Hide()
        card.note:SetText("")
    end
end
local function Create()
    local f = CreateFrame("Frame", "CharacterStatsWindowArcane", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    RoundBox(f, C.ground, C.edge, 10)
    BuildHeader(f)
    BuildStage(f)
    BuildStrip(f)
    BuildPanel(f)
    local rep = ns.WindowReputation.Create(f, {
        Text = Text, Button = Button, text = C.text, muted = C.muted, accent = C.gold,
        bodyFont = "Barlow-Regular.ttf", boldFont = "Barlow-SemiBold.ttf", headerFont = "BarlowCondensed-Bold.ttf",
        barTrack = C.track, rowFill = { 0.090, 0.075, 0.227, 0.6 }, barWidth = 220, boxEdge = C.cardEdge,
        boxFill = C.card,
    })
    rep:SetPoint("TOPLEFT", 1, -(HEADER + 1))
    rep:SetPoint("BOTTOMRIGHT", -1, 1)
    rep:SetFrameLevel(f:GetFrameLevel() + 50)
    local repBg = rep:CreateTexture(nil, "BACKGROUND")
    repBg:SetAllPoints()
    repBg:SetColorTexture(C.ground[1], C.ground[2], C.ground[3])
    local detailBox = CreateFrame("Frame", nil, rep)
    detailBox:SetPoint("TOPRIGHT", -14, -14)
    detailBox:SetPoint("BOTTOMRIGHT", -14, 14)
    detailBox:SetWidth(280)
    RoundBox(detailBox, C.card, C.violet, 10)
    rep.list:SetPoint("TOPLEFT", 18, -16)
    rep.list:SetPoint("BOTTOMRIGHT", -310, 14)
    rep.detail:SetPoint("TOPLEFT", detailBox, "TOPLEFT", 14, -14)
    rep.detail:SetPoint("BOTTOMRIGHT", detailBox, "BOTTOMRIGHT", -12, 12)
    rep:Hide()
    f.rep = rep
    f.activeTab = "PaperDollFrame"
    function f:ShowTab(sub)
        self.activeTab = sub
        self.rep:SetShown(sub == "ReputationFrame")
        for key, b in pairs(self.tabs) do b:SetSelected(key == sub) end
        self.titlesButton:SetShown(sub == "PaperDollFrame")
        self.setsButton:SetShown(sub == "PaperDollFrame")
        if sub ~= "PaperDollFrame" and self.panel:IsShown() then
            self.panel:Hide()
            self.activePanel = nil
        end
    end
    function f:TogglePanel(key)
        if self.panel:IsShown() and self.activePanel == key then
            self.panel:Hide()
            self.activePanel = nil
        else
            self.activePanel = key
            for paneKey, pane in pairs(self.panes) do pane:SetShown(paneKey == key) end
            self.panel:Show()
            self.panes[key]:Refresh()
        end
        self.titlesButton:SetSelected(self.panel:IsShown() and key == "titles" and self.activePanel == "titles")
        self.setsButton:SetSelected(self.panel:IsShown() and key == "sets" and self.activePanel == "sets")
    end
    function f:RefreshStats()
        local db = ns.db
        if ns.Stats and ns.Stats.Invalidate then ns.Stats:Invalidate() end
        local attributes, enhancements = ns.Stats:CollectByCategory()
        local byId, others = {}, {}
        for _, stat in ipairs(enhancements) do byId[stat.id] = stat end
        for _, stat in ipairs(enhancements) do
            local secondary = false
            for _, id in ipairs(SECONDARY) do
                if stat.id == id then secondary = true end
            end
            if not secondary then others[#others + 1] = stat end
        end
        FillList(self.attrCard, attributes, db)
        for i, id in ipairs(SECONDARY) do
            FillSecondary(self.secondaryCards[i], byId[id], db)
        end
        FillList(self.otherCard, others, db)
    end
    function f:Refresh()
        local info = Parts.GetHeaderInfo()
        self.nameText:SetText(info.name)
        local cc = info.classColor
        local spec = info.specName and (info.specName .. " ") or ""
        self.subText:SetText(string.format("%s %d  |cff%02x%02x%02x%s%s|r", LEVEL or "Level", info.level,
            math.floor(cc.r * 255), math.floor(cc.g * 255), math.floor(cc.b * 255), spec, info.className)
            .. (info.guild and ("  <" .. info.guild .. ">") or ""))
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
        Parts.RefreshSlots(self)
        self.model:Load()
        self:RefreshStats()
        if self.panel:IsShown() and self.activePanel then
            self.panes[self.activePanel]:Refresh()
        end
    end
    return f
end
ns.Window.RegisterLook("arcane", {
    label = ns.L.WINDOW_LOOK_ARCANE or "Midnight Arcane",
    labelKey = "WINDOW_LOOK_ARCANE",
    Create = Create,
})
