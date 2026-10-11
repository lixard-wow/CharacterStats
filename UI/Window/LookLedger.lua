local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local W, H = 920, 620
local BOOK_PAD = 14
local RIGHT_PAGE = 410
local ROW = 29
local ICON = 24
local RIBBON_W = 66
local FELL = "IMFellEnglish-Regular.ttf"
local FELL_ITALIC = "IMFellEnglish-Italic.ttf"
local FELL_SC = "IMFellEnglishSC-Regular.ttf"
local SANS = "AlegreyaSans-Regular.ttf"
local SANS_BOLD = "AlegreyaSans-Bold.ttf"
local C = {
    leather = { 0.231, 0.141, 0.078 },
    leatherEdge = { 0.353, 0.227, 0.125 },
    page = { 0.914, 0.859, 0.725 },
    rule = { 0.651, 0.541, 0.353 },
    dots = { 0.761, 0.671, 0.490 },
    ink = { 0.173, 0.125, 0.078 },
    inkMuted = { 0.361, 0.275, 0.188 },
    heading = { 0.478, 0.227, 0.078 },
    brass = { 0.478, 0.353, 0.110 },
    good = { 0.169, 0.416, 0.106 },
    bad = { 0.639, 0.157, 0.102 },
    track = { 0.831, 0.757, 0.580 },
}
local QUALITY = {
    [0] = { 0.37, 0.35, 0.32 }, [1] = { 0.30, 0.27, 0.22 }, [2] = { 0.12, 0.45, 0.08 }, [3] = { 0.0, 0.33, 0.62 },
    [4] = { 0.42, 0.18, 0.69 }, [5] = { 0.66, 0.32, 0.0 }, [6] = { 0.55, 0.45, 0.15 }, [7] = { 0.0, 0.45, 0.62 },
}
local TRACK = {
    myth = { 0.66, 0.32, 0.0 }, crafted = { 0.66, 0.32, 0.0 }, hero = { 0.42, 0.18, 0.69 }, champion = { 0.17, 0.48, 0.11 },
    veteran = { 0.07, 0.46, 0.43 }, adventurer = { 0.10, 0.35, 0.70 }, explorer = { 0.37, 0.35, 0.32 },
}
local ORDER = { 1, 2, 3, 15, 5, 4, 19, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17 }
local function Text(parent, font, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(fs, font, size, "")
    fs:SetTextColor(color[1], color[2], color[3])
    return fs
end
local function Solid(parent, color, layer, sublevel)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return t
end
local function Rule(parent, color, height)
    local t = Solid(parent, color, "BORDER")
    t:SetHeight(height or 1)
    return t
end
local function Button(parent, width, height, label)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.fill = Solid(b, C.leather)
    b.fill:SetAllPoints()
    b.edge = {}
    for i, spec in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local e = Solid(b, C.brass, "BORDER")
        e:SetPoint(spec[1])
        e:SetPoint(spec[2])
        if i <= 2 then e:SetHeight(1) else e:SetWidth(1) end
        b.edge[i] = e
    end
    b.label = Text(b, FELL_SC, 15, { 0.945, 0.886, 0.741 })
    b.label:SetPoint("CENTER", 0, 1)
    b.label:SetText(label or "")
    b:SetScript("OnEnter", function(self) self.fill:SetColorTexture(C.leatherEdge[1], C.leatherEdge[2], C.leatherEdge[3]) end)
    b:SetScript("OnLeave", function(self) if not self.selected then self.fill:SetColorTexture(C.leather[1], C.leather[2], C.leather[3]) end end)
    function b:SetSelected(on)
        self.selected = on
        local c = on and C.leatherEdge or C.leather
        self.fill:SetColorTexture(c[1], c[2], c[3])
    end
    return b
end
local function Page(parent)
    local page = CreateFrame("Frame", nil, parent)
    Solid(page, C.page):SetAllPoints()
    local grain = page:CreateTexture(nil, "BACKGROUND", nil, 1)
    grain:SetAllPoints()
    grain:SetTexture(ns.Theme.ART .. "parchment_grain", "REPEAT", "REPEAT")
    grain:SetHorizTile(true)
    grain:SetVertTile(true)
    local edges = page:CreateTexture(nil, "BACKGROUND", nil, 2)
    edges:SetAllPoints()
    edges:SetTexture(ns.Theme.ART .. "page_edges")
    return page
end
local function BuildRibbons(f)
    local ribbons = {
        { key = "PaperDollFrame", label = ns.L.WINDOW_TAB_CHARACTER or "Character", color = { 0.549, 0.184, 0.137 } },
        { key = "ReputationFrame", label = ns.L.WINDOW_TAB_REPUTATION or "Reputation", color = { 0.184, 0.290, 0.227 } },
        { key = "TokenFrame", label = ns.L.WINDOW_TAB_CURRENCY or "Currency", color = { 0.478, 0.353, 0.110 } },
    }
    f.tabs = {}
    for i, info in ipairs(ribbons) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(RIBBON_W, 82)
        b:SetPoint("TOPLEFT", f, "TOPRIGHT", -4, -56 - (i - 1) * 92)
        b:SetFrameLevel(f:GetFrameLevel() + 1)
        local band = Solid(b, info.color)
        band:SetPoint("TOPLEFT")
        band:SetPoint("BOTTOMRIGHT", 0, 12)
        local tailLeft = Solid(b, info.color)
        tailLeft:SetPoint("BOTTOMLEFT")
        tailLeft:SetSize(RIBBON_W / 2 - 4, 12)
        local tailRight = Solid(b, info.color)
        tailRight:SetPoint("BOTTOMRIGHT")
        tailRight:SetSize(RIBBON_W / 2 - 4, 12)
        b.label = Text(b, FELL_SC, 14, { 0.965, 0.902, 0.769 })
        b.label:SetPoint("CENTER", 2, 6)
        b.label:SetWidth(RIBBON_W - 8)
        b.label:SetText(info.label)
        b:SetScript("OnClick", function() ns.Window.ShowTab(info.key) end)
        b:SetAlpha(info.key == "PaperDollFrame" and 1 or 0.82)
        f.tabs[info.key] = b
    end
end
local function BuildGearPage(f, page)
    f.ilvlLine = Text(page, FELL_ITALIC, 16, C.inkMuted)
    f.ilvlLine:SetPoint("TOPRIGHT", page, "TOPRIGHT", -24, -24)
    local title = Text(page, FELL, 26, C.leather)
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 26, -18)
    title:SetText(ns.L.WINDOW_EQUIPMENT or "Equipment")
    local rule = Rule(page, C.rule)
    rule:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -50)
    rule:SetPoint("TOPRIGHT", page, "TOPRIGHT", -22, -50)
    f.slotButtons = {}
    f.rows = {}
    for i, slot in ipairs(ORDER) do
        local row = CreateFrame("Frame", nil, page)
        row:SetHeight(ROW)
        row:SetPoint("TOPLEFT", page, "TOPLEFT", 26, -56 - (i - 1) * ROW)
        row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -22, -56 - (i - 1) * ROW)
        local dots = Rule(row, C.dots)
        dots:SetPoint("BOTTOMLEFT")
        dots:SetPoint("BOTTOMRIGHT")
        local b = Parts.CreateSlot(row, slot, { size = ICON + 2, plain = true, emptyBorder = C.rule })
        b:SetPoint("LEFT", row, "LEFT", 0, 0)
        f.slotButtons[#f.slotButtons + 1] = b
        row.ilvl = Text(row, SANS_BOLD, 15, C.ink)
        row.ilvl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.ilvl:SetWidth(36)
        row.ilvl:SetJustifyH("RIGHT")
        row.detail = Text(row, FELL_ITALIC, 13, C.good)
        row.detail:SetPoint("RIGHT", row.ilvl, "LEFT", -8, 0)
        row.detail:SetJustifyH("RIGHT")
        row.gems = {}
        for g = 1, 3 do
            local gem = CreateFrame("Frame", nil, row)
            gem:SetSize(13, 13)
            gem.icon = gem:CreateTexture(nil, "ARTWORK")
            gem.icon:SetAllPoints()
            gem.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            gem:EnableMouse(true)
            gem:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.gemId then GameTooltip:SetItemByID(self.gemId) else GameTooltip:SetText(ns.L.GEAR_EMPTY_SOCKET or "Empty socket", 1, 1, 1) end
                GameTooltip:Show()
            end)
            gem:SetScript("OnLeave", GameTooltip_Hide)
            gem:Hide()
            row.gems[g] = gem
        end
        row.name = Text(row, SANS_BOLD, 14, C.ink)
        row.name:SetPoint("TOPLEFT", b, "TOPRIGHT", 9, 1)
        row.name:SetPoint("RIGHT", row.detail, "LEFT", -40, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.sub = Text(row, SANS, 12, C.inkMuted)
        row.sub:SetPoint("BOTTOMLEFT", b, "BOTTOMRIGHT", 9, -1)
        row.slot = slot
        f.rows[i] = row
    end
end
local function BuildCharacterPage(f, page)
    local crest = page:CreateTexture(nil, "ARTWORK")
    crest:SetSize(40, 40)
    crest:SetPoint("TOPLEFT", page, "TOPLEFT", 22, -18)
    crest:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.crest = crest
    f.nameText = Text(page, FELL, 24, C.leather)
    f.nameText:SetPoint("TOPLEFT", crest, "TOPRIGHT", 10, 2)
    f.nameText:SetPoint("RIGHT", page, "RIGHT", -50, 0)
    f.nameText:SetJustifyH("LEFT")
    f.nameText:SetWordWrap(false)
    f.subText = Text(page, SANS, 13, C.inkMuted)
    f.subText:SetPoint("TOPLEFT", f.nameText, "BOTTOMLEFT", 0, -2)
    local close = Button(page, 26, 26, "x")
    close:SetPoint("TOPRIGHT", page, "TOPRIGHT", -16, -18)
    close:SetScript("OnClick", ns.Window.Close)
    local portrait = CreateFrame("Frame", nil, page)
    portrait:SetPoint("TOPLEFT", page, "TOPLEFT", 22, -70)
    portrait:SetPoint("TOPRIGHT", page, "TOPRIGHT", -22, -70)
    portrait:SetHeight(220)
    Solid(portrait, C.brass, "BACKGROUND", 0):SetAllPoints()
    local inner = Solid(portrait, { 0.172, 0.145, 0.200 }, "BACKGROUND", 1)
    inner:SetPoint("TOPLEFT", 3, -3)
    inner:SetPoint("BOTTOMRIGHT", -3, 3)
    f.model = Parts.CreateModel(portrait)
    f.model:SetPoint("TOPLEFT", 4, -4)
    f.model:SetPoint("BOTTOMRIGHT", -4, 4)
    local right = Button(portrait, 26, 26, ">")
    right:SetPoint("BOTTOMRIGHT", -10, 10)
    right:SetFrameLevel(f.model:GetFrameLevel() + 2)
    right:SetScript("OnClick", function() f.model:Rotate(0.3) end)
    local left = Button(portrait, 26, 26, "<")
    left:SetPoint("RIGHT", right, "LEFT", -6, 0)
    left:SetFrameLevel(f.model:GetFrameLevel() + 2)
    left:SetScript("OnClick", function() f.model:Rotate(-0.3) end)
    local lower = CreateFrame("Frame", nil, page)
    lower:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 0, -10)
    lower:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -22, 56)
    f.lower = lower
    local stats = CreateFrame("Frame", nil, lower)
    stats:SetAllPoints()
    local attrTitle = Text(stats, FELL_SC, 18, C.heading)
    attrTitle:SetPoint("TOPLEFT", 0, 0)
    attrTitle:SetText(ns.L.WINDOW_ATTR_DEFENSE or "Attributes & Defense")
    local attrRule = Rule(stats, C.rule)
    attrRule:SetPoint("TOPLEFT", 0, -20)
    attrRule:SetPoint("TOPRIGHT", 0, -20)
    f.basicRows = {}
    for i = 1, 6 do
        local row = CreateFrame("Frame", nil, stats)
        row:SetSize((RIGHT_PAGE - 44 - 20) / 2, 19)
        local col = (i - 1) % 2
        local line = math.floor((i - 1) / 2)
        row:SetPoint("TOPLEFT", stats, "TOPLEFT", col * ((RIGHT_PAGE - 44) / 2 + 10), -25 - line * 20)
        row:EnableMouse(true)
        local dots = Rule(row, C.dots)
        dots:SetPoint("BOTTOMLEFT")
        dots:SetPoint("BOTTOMRIGHT")
        row.label = Text(row, SANS, 14, C.inkMuted)
        row.label:SetPoint("LEFT")
        row.value = Text(row, SANS_BOLD, 14, C.ink)
        row.value:SetPoint("RIGHT")
        row:SetScript("OnEnter", function(self)
            if self.stat then ns.PaperdollPanel.ShowStatTooltip(self, self.stat.id, self.stat.label, self.valueText, self.stat.tooltip) end
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        f.basicRows[i] = row
    end
    local enhTitle = Text(stats, FELL_SC, 18, C.heading)
    enhTitle:SetPoint("TOPLEFT", 0, -92)
    enhTitle:SetText(ns.L.HEADER_ENHANCEMENTS or "Enhancements")
    local enhRule = Rule(stats, C.rule)
    enhRule:SetPoint("TOPLEFT", 0, -112)
    enhRule:SetPoint("TOPRIGHT", 0, -112)
    f.enhRows = {}
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, stats)
        row:SetHeight(19)
        row:SetPoint("TOPLEFT", stats, "TOPLEFT", 0, -118 - (i - 1) * 21)
        row:SetPoint("TOPRIGHT", stats, "TOPRIGHT", 0, -118 - (i - 1) * 21)
        row:EnableMouse(true)
        row.label = Text(row, SANS_BOLD, 14, C.ink)
        row.label:SetPoint("LEFT")
        row.label:SetWidth(112)
        row.label:SetJustifyH("LEFT")
        row.value = Text(row, SANS_BOLD, 14, C.ink)
        row.value:SetPoint("RIGHT")
        row.value:SetWidth(62)
        row.value:SetJustifyH("RIGHT")
        row.track = Solid(row, C.track, "ARTWORK")
        row.track:SetPoint("LEFT", row, "LEFT", 118, 0)
        row.track:SetPoint("RIGHT", row, "RIGHT", -70, 0)
        row.track:SetHeight(6)
        row.trackWidth = RIGHT_PAGE - 44 - 118 - 70
        row.fill = Solid(row, C.ink, "ARTWORK", 1)
        row.fill:SetPoint("LEFT", row.track, "LEFT")
        row.fill:SetHeight(6)
        row.marker = Solid(row, C.leather, "ARTWORK", 2)
        row.marker:SetSize(2, 12)
        row:SetScript("OnEnter", function(self)
            if self.stat then ns.PaperdollPanel.ShowStatTooltip(self, self.stat.id, self.stat.label, self.valueText, self.stat.tooltip) end
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        f.enhRows[i] = row
    end
    f.statsPane = stats
    local ui = {
        Text = function(parent, font, size, color) return Text(parent, font, size, color) end,
        Button = Button, text = C.ink, muted = C.inkMuted, accent = C.heading,
        bodyFont = SANS, boldFont = SANS_BOLD, buttonWidth = 150,
    }
    f.panes = { titles = Parts.CreateTitlesPane(lower, ui), sets = Parts.CreateSetsPane(lower, ui) }
    f.panes.titles:Hide()
    f.panes.sets:Hide()
    f.titlesButton = Button(page, 176, 32, ns.L.WINDOW_PANE_TITLES or "Titles")
    f.titlesButton:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 22, 16)
    f.titlesButton:SetScript("OnClick", function() f:ShowLower("titles") end)
    f.setsButton = Button(page, 176, 32, ns.L.WINDOW_SETS or "Equipment Sets")
    f.setsButton:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -22, 16)
    f.setsButton:SetScript("OnClick", function() f:ShowLower("sets") end)
end
local function FillGearRows(f, db)
    local results = ns.Gear and ns.Gear.Scan() or {}
    for _, row in ipairs(f.rows) do
        local entry = results[row.slot]
        local link = GetInventoryItemLink("player", row.slot)
        local name = Parts.ItemName(row.slot)
        if link and name then
            row.name:SetText(name)
            local quality = GetInventoryItemQuality("player", row.slot)
            local qc = QUALITY[quality or 1] or C.ink
            row.name:SetTextColor(qc[1], qc[2], qc[3])
        else
            row.name:SetText(Parts.SlotLabel(row.slot))
            row.name:SetTextColor(C.inkMuted[1], C.inkMuted[2], C.inkMuted[3])
        end
        local subText = link and Parts.SlotLabel(row.slot) or (ns.L.WINDOW_EMPTY_SLOT or "Empty")
        local tc = entry and TRACK[entry.track or ""] or C.inkMuted
        if entry and entry.link and entry.track then
            local trackName = ns.L["TRACK_" .. entry.track:upper()] or entry.track
            if entry.trackRank and entry.trackMax then
                trackName = string.format("%s %d/%d", trackName, entry.trackRank, entry.trackMax)
            end
            subText = string.format("%s  |cff%02x%02x%02x%s|r", subText, math.floor(tc[1] * 255), math.floor(tc[2] * 255), math.floor(tc[3] * 255), trackName)
        end
        row.sub:SetText(subText)
        if entry and entry.link and entry.itemLevel then
            row.ilvl:SetText(string.format("%d", entry.itemLevel))
            row.ilvl:SetTextColor(tc[1], tc[2], tc[3])
        else
            row.ilvl:SetText("")
        end
        row.detail:SetText("")
        if entry and entry.link then
            if entry.missingEnchant then
                row.detail:SetText(ns.L.GEAR_MISSING_ENCHANT or "Missing enchant")
                row.detail:SetTextColor(C.bad[1], C.bad[2], C.bad[3])
            elseif entry.enchantText then
                row.detail:SetText((entry.enchantText:gsub("%s*|A:.-|a", "")))
                row.detail:SetTextColor(C.good[1], C.good[2], C.good[3])
            end
        end
        local anchor = row.detail
        local anchorPoint = row.detail:GetText() ~= "" and "LEFT" or "RIGHT"
        for g, gem in ipairs(row.gems) do
            local gemId = entry and entry.link and entry.gems and entry.gems[g]
            if gemId == nil then
                gem:Hide()
            else
                gem.gemId = gemId or nil
                gem.icon:SetTexture(gemId and C_Item.GetItemIconByID(gemId) or "Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
                gem:ClearAllPoints()
                gem:SetPoint("RIGHT", anchor, anchorPoint, -4, 0)
                gem:Show()
                anchor, anchorPoint = gem, "LEFT"
            end
        end
    end
end
local function FillStats(f, db)
    if ns.Stats and ns.Stats.Invalidate then ns.Stats:Invalidate() end
    local attributes, enhancements = ns.Stats:CollectByCategory()
    local basic, enh = {}, {}
    for _, stat in ipairs(attributes) do basic[#basic + 1] = stat end
    local defensive = { dodge = true, parry = true, block = true, pvpresilience = true }
    for _, stat in ipairs(enhancements) do
        if defensive[stat.id] then basic[#basic + 1] = stat else enh[#enh + 1] = stat end
    end
    for i, row in ipairs(f.basicRows) do
        local stat = basic[i]
        row.stat = stat
        if stat then
            local value = ns.Styles.FormatValue(stat, db)
            row.valueText = value
            row.label:SetText(stat.label)
            row.value:SetText(value)
            local r, g, b = ns.GetStatColor(stat.id)
            row.value:SetTextColor(r * 0.6, g * 0.6, b * 0.6)
            row:Show()
        else
            row:Hide()
        end
    end
    local D = ns.Diminishing
    for i, row in ipairs(f.enhRows) do
        local stat = enh[i]
        row.stat = stat
        if stat then
            local value = ns.Styles.FormatValue(stat, db)
            row.valueText = value
            local r, g, b = ns.GetStatColor(stat.id)
            r, g, b = r * 0.6, g * 0.6, b * 0.6
            row.label:SetText(stat.label)
            row.label:SetTextColor(r, g, b)
            row.value:SetText(value)
            row.value:SetTextColor(r, g, b)
            row.fill:SetColorTexture(r, g, b)
            local ratingId = D and D.RatingFor(stat.id)
            local info = ratingId and D.Info(ratingId)
            local threshold = ratingId and D.FirstThreshold(ratingId)
            local width = row.trackWidth
            if info and threshold and threshold > 0 and width and width > 0 then
                row.fill:SetWidth(math.max(1, width * math.min(1, info.raw / (threshold / 0.6))))
                row.marker:ClearAllPoints()
                row.marker:SetPoint("CENTER", row.track, "LEFT", width * 0.6, 0)
                row.fill:Show()
                row.marker:Show()
                row.track:Show()
            else
                row.fill:Hide()
                row.marker:Hide()
                row.track:Hide()
            end
            row:Show()
        else
            row:Hide()
        end
    end
end
local function Create()
    local f = CreateFrame("Frame", "CharacterStatsWindowLedger", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    Solid(f, C.leather, "BACKGROUND", -8):SetAllPoints()
    local stitch = Solid(f, C.leatherEdge, "BACKGROUND", -7)
    stitch:SetPoint("TOPLEFT", 4, -4)
    stitch:SetPoint("BOTTOMRIGHT", -4, 4)
    local stitchInner = Solid(f, C.leather, "BACKGROUND", -6)
    stitchInner:SetPoint("TOPLEFT", 6, -6)
    stitchInner:SetPoint("BOTTOMRIGHT", -6, 6)
    BuildRibbons(f)
    local left = Page(f)
    left:SetPoint("TOPLEFT", BOOK_PAD, -BOOK_PAD)
    left:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(BOOK_PAD + RIGHT_PAGE), BOOK_PAD)
    local right = Page(f)
    right:SetPoint("TOPRIGHT", -BOOK_PAD, -BOOK_PAD)
    right:SetPoint("BOTTOMRIGHT", -BOOK_PAD, BOOK_PAD)
    right:SetWidth(RIGHT_PAGE)
    local spine = Solid(f, { 0.42, 0.30, 0.15, 0.7 }, "ARTWORK")
    spine:SetPoint("TOPLEFT", right, "TOPLEFT", -1, 0)
    spine:SetPoint("BOTTOMLEFT", right, "BOTTOMLEFT", -1, 0)
    spine:SetWidth(2)
    BuildGearPage(f, left)
    BuildCharacterPage(f, right)
    local rep = ns.WindowReputation.Create(f, {
        Text = function(parent, font, size, color) return Text(parent, font, size, color) end,
        Button = Button, text = C.ink, muted = C.inkMuted, accent = C.heading,
        bodyFont = SANS, boldFont = SANS_BOLD, headerFont = FELL_SC,
        barTrack = { 0.80, 0.72, 0.53, 1 }, rowFill = { 0.55, 0.42, 0.22, 0.08 }, barWidth = 170,
        boxEdge = C.brass, boxFill = { 0.96, 0.92, 0.82, 1 },
    })
    rep:SetPoint("TOPLEFT", BOOK_PAD, -BOOK_PAD)
    rep:SetPoint("BOTTOMRIGHT", -BOOK_PAD, BOOK_PAD)
    rep:SetFrameLevel(f:GetFrameLevel() + 40)
    local repLeft = Page(rep)
    repLeft:SetPoint("TOPLEFT")
    repLeft:SetPoint("BOTTOMRIGHT", rep, "BOTTOMRIGHT", -RIGHT_PAGE, 0)
    repLeft:SetFrameLevel(rep:GetFrameLevel())
    local repRight = Page(rep)
    repRight:SetPoint("TOPRIGHT")
    repRight:SetPoint("BOTTOMRIGHT")
    repRight:SetWidth(RIGHT_PAGE)
    repRight:SetFrameLevel(rep:GetFrameLevel())
    local repTitle = Text(repLeft, FELL, 26, C.leather)
    repTitle:SetPoint("TOPLEFT", 26, -18)
    repTitle:SetText(ns.L.WINDOW_TAB_REPUTATION or "Reputation")
    rep.list:SetFrameLevel(rep:GetFrameLevel() + 5)
    rep.detail:SetFrameLevel(rep:GetFrameLevel() + 5)
    rep.list:SetPoint("TOPLEFT", repLeft, "TOPLEFT", 24, -56)
    rep.list:SetPoint("BOTTOMRIGHT", repLeft, "BOTTOMRIGHT", -20, 16)
    rep.detail:SetPoint("TOPLEFT", repRight, "TOPLEFT", 24, -24)
    rep.detail:SetPoint("BOTTOMRIGHT", repRight, "BOTTOMRIGHT", -24, 20)
    local close = Button(repRight, 26, 26, "x")
    close:SetPoint("TOPRIGHT", repRight, "TOPRIGHT", -16, -18)
    close:SetFrameLevel(rep:GetFrameLevel() + 8)
    close:SetScript("OnClick", ns.Window.Close)
    rep:Hide()
    f.rep = rep
    f.activeTab = "PaperDollFrame"
    function f:ShowTab(sub)
        self.activeTab = sub
        self.rep:SetShown(sub == "ReputationFrame")
        for key, b in pairs(self.tabs) do b:SetAlpha(key == sub and 1 or 0.82) end
    end
    f.lowerKey = false
    function f:ShowLower(key)
        if self.lowerKey == key then key = false end
        self.lowerKey = key
        self.statsPane:SetShown(not key)
        for paneKey, pane in pairs(self.panes) do pane:SetShown(paneKey == key) end
        self.titlesButton:SetSelected(key == "titles")
        self.setsButton:SetSelected(key == "sets")
        if key then self.panes[key]:Refresh() else FillStats(self, ns.db) end
    end
    function f:Refresh()
        local db = ns.db
        local info = Parts.GetHeaderInfo()
        self.nameText:SetText(info.name)
        local cc = info.classColor
        local spec = info.specName and (info.specName .. " ") or ""
        self.subText:SetText(string.format("%s %d  |cff%02x%02x%02x%s%s|r", LEVEL or "Level", info.level,
            math.floor(cc.r * 160), math.floor(cc.g * 160), math.floor(cc.b * 160), spec, info.className))
        self.crest:SetTexture(info.specIcon or 134400)
        local ilvlText = string.format("%s %s", ns.L.STAT_ILVL or "Item Level", Parts.FormatItemLevel(info.equipped))
        if info.overall and info.overall > info.equipped + 0.005 then
            ilvlText = ilvlText .. "  ·  " .. string.format(ns.L.PAPERDOLL_ILVL_BAGS or "%s in bags", string.format("%.1f", info.overall))
        end
        self.ilvlLine:SetText(ilvlText)
        if self.activeTab == "ReputationFrame" then
            self.rep:Refresh()
            return
        end
        Parts.RefreshSlots(self)
        FillGearRows(self, db)
        self.model:Load()
        if self.lowerKey then
            self.panes[self.lowerKey]:Refresh()
        else
            FillStats(self, db)
        end
    end
    return f
end
ns.Window.RegisterLook("ledger", {
    label = ns.L.WINDOW_LOOK_LEDGER or "Adventurer's Ledger",
    labelKey = "WINDOW_LOOK_LEDGER",
    Create = Create,
})
