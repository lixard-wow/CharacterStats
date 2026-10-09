local ADDON_NAME, ns = ...
local StylePicker = {}
ns.StylePicker = StylePicker
local ipairs, pairs, wipe = ipairs, pairs, wipe
local CARD_WIDTH = 158
local CARD_HEIGHT = 196
local CARD_GAP = 10
local PREVIEW_HEIGHT = 112
local PAD = 16
local SAMPLE = {
    { id = "ilvl", label = "Item Level", short = "iLvl", value = "276.4" },
    { id = "crit", label = "Crit", short = "Crit", value = "18.4%", pct = 18.4 },
    { id = "haste", label = "Haste", short = "Haste", value = "24.1%", pct = 24.1 },
    { id = "mastery", label = "Mastery", short = "Mast", value = "41.3%", pct = 41.3 },
    { id = "versatility", label = "Vers", short = "Vers", value = "9.9%", pct = 9.9 },
}
local DESCRIPTION_KEYS = {
    original = "STYLE_ORIGINAL_DESC",
    ledger = "STYLE_LEDGER_DESC",
    meters = "STYLE_METERS_DESC",
    companion = "STYLE_COMPANION_DESC",
}
local DESCRIPTION_FALLBACKS = {
    original = "The classic list from earlier versions.",
    ledger = "Big item level, stats grouped under headers.",
    meters = "A colored bar under every stat.",
    companion = "Compact cells, plus a gear drawer on the character frame.",
}
local frame
local cards = {}
local selected
local originalStyle
local committed = false
local function Text(parent, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, size, "")
    fs:SetTextColor(r or 1, g or 1, b or 1)
    return fs
end
local function StatColor(id)
    return ns.GetStatColor(id)
end
local function DrawListPreview(preview, grouped)
    local y = -8
    if grouped then
        local big = Text(preview, 16, StatColor("ilvl"))
        big:SetPoint("TOP", preview, "TOP", 0, y)
        big:SetText(SAMPLE[1].value)
        y = y - 22
        local header = Text(preview, 8, ns.GetAccentColor())
        header:SetPoint("TOPLEFT", preview, "TOPLEFT", 10, y)
        header:SetText(ns.L.GROUP_SECONDARY or "Secondary")
        local line = preview:CreateTexture(nil, "ARTWORK")
        line:SetPoint("LEFT", header, "RIGHT", 4, 0)
        line:SetPoint("RIGHT", preview, "RIGHT", -10, 0)
        line:SetHeight(1)
        local ar, ag, ab = ns.GetAccentColor()
        line:SetColorTexture(ar, ag, ab, 0.3)
        y = y - 14
    end
    for i = grouped and 2 or 1, #SAMPLE do
        local s = SAMPLE[i]
        local r, g, b = StatColor(s.id)
        local label = Text(preview, 10, r, g, b)
        label:SetPoint("TOPLEFT", preview, "TOPLEFT", 10, y)
        label:SetText(s.label .. ":")
        local value = Text(preview, 10, r, g, b)
        value:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -10, y)
        value:SetText(s.value)
        y = y - 15
    end
end
local function DrawMetersPreview(preview)
    local y = -8
    for i = 2, #SAMPLE do
        local s = SAMPLE[i]
        local r, g, b = StatColor(s.id)
        local label = Text(preview, 10, r, g, b)
        label:SetPoint("TOPLEFT", preview, "TOPLEFT", 10, y)
        label:SetText(s.label)
        local value = Text(preview, 10, r, g, b)
        value:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -10, y)
        value:SetText(s.value)
        local track = preview:CreateTexture(nil, "ARTWORK")
        track:SetPoint("TOPLEFT", preview, "TOPLEFT", 10, y - 14)
        track:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -10, y - 14)
        track:SetHeight(3)
        track:SetColorTexture(1, 1, 1, 0.08)
        local fill = preview:CreateTexture(nil, "OVERLAY")
        fill:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
        fill:SetHeight(3)
        fill:SetWidth((CARD_WIDTH - 40) * s.pct / 50)
        fill:SetColorTexture(r, g, b, 0.9)
        y = y - 25
    end
end
local function DrawCompanionPreview(preview)
    local cellWidth = (CARD_WIDTH - 20) / 3
    for i = 1, 6 do
        local s = SAMPLE[((i - 1) % 4) + 2]
        if i == 1 then s = SAMPLE[1] end
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        local r, g, b = StatColor(s.id)
        local label = Text(preview, 8, r, g, b)
        label:SetAlpha(0.7)
        label:SetPoint("TOP", preview, "TOPLEFT", 10 + cellWidth * (col + 0.5), -12 - row * 34)
        label:SetText(s.short)
        local value = Text(preview, 11, r, g, b)
        value:SetPoint("TOP", label, "BOTTOM", 0, -2)
        value:SetText(s.value)
    end
    local drawer = preview:CreateTexture(nil, "ARTWORK")
    drawer:SetPoint("BOTTOMLEFT", preview, "BOTTOMLEFT", 10, 8)
    drawer:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", -10, 8)
    drawer:SetHeight(18)
    drawer:SetColorTexture(1, 1, 1, 0.05)
    local drawerText = Text(preview, 8, 0.7, 0.7, 0.7)
    drawerText:SetPoint("CENTER", drawer, "CENTER", 0, 0)
    drawerText:SetText(ns.L.STYLE_PREVIEW_DRAWER or "+ Gear drawer")
end
local PREVIEWS = {
    original = function(preview) DrawListPreview(preview, false) end,
    ledger = function(preview) DrawListPreview(preview, true) end,
    meters = DrawMetersPreview,
    companion = DrawCompanionPreview,
}
local function UpdateCards()
    for id, card in pairs(cards) do
        if id == selected then
            ns.ConfigWidgets.SetBorderColor(card, "accentGold", 1)
            ns.ConfigWidgets.ApplyFontColor(card.name, "accentGold")
        else
            ns.ConfigWidgets.SetBorderColor(card, "border", 1)
            ns.ConfigWidgets.ApplyFontColor(card.name, "textPrimary")
        end
    end
end
local function MarkSeen()
    if ns.db then
        ns.db.stylePickerSeen = true
    end
end
local function PreviewStyle(id)
    if not ns.db or not id then return end
    ns.db.style = id
    if ns.StatsFrame then
        ns.StatsFrame:ApplyStyle()
    end
    if ns.PaperdollPanel then
        ns.PaperdollPanel:ApplyStyle()
    end
end
local function RevertPreview()
    if committed or not ns.db or not originalStyle then return end
    if ns.db.style ~= originalStyle then
        PreviewStyle(originalStyle)
    end
end
local function Apply()
    committed = true
    if ns.db and selected then
        ns.db.style = selected
        if ns.ConfigPanel and ns.ConfigPanel.ApplyStyleChange then
            ns.ConfigPanel.ApplyStyleChange()
            ns.ConfigPanel.RefreshActivePage()
        end
    end
    MarkSeen()
    frame:Hide()
end
local HEADER_HEIGHT = 44
local rebuilding = false
local themeButtons = {}
local function UpdateThemeButtons()
    local Widgets = ns.ConfigWidgets
    for key, button in pairs(themeButtons) do
        if key == ns.Theme.key then
            Widgets.SetBorderColor(button, "accentGold", 1)
            Widgets.ApplyFontColor(button.text, "accentGold")
        else
            Widgets.SetBorderColor(button, "buttonBorder", 1)
            Widgets.ApplyFontColor(button.text, "buttonText")
        end
    end
end
local function StylePrimary(button)
    local Widgets = ns.ConfigWidgets
    Widgets.Paint(button.bg, "primary")
    Widgets.SetBorderColor(button, "primaryBorder", 1)
    Widgets.ApplyFontColor(button.text, "primaryText")
    button:SetScript("OnEnter", function(self)
        Widgets.Paint(self.bg, "primaryHover")
    end)
    button:SetScript("OnLeave", function(self)
        Widgets.Paint(self.bg, "primary")
        Widgets.SetBorderColor(self, "primaryBorder", 1)
        Widgets.ApplyFontColor(self.text, "primaryText")
    end)
end
local function Create()
    if frame and frame.themeKey == ns.Theme.key then return frame end
    local Widgets = ns.ConfigWidgets
    local L = ns.L
    local styles = ns.Styles.List()
    local width = PAD * 2 + #styles * CARD_WIDTH + (#styles - 1) * CARD_GAP
    wipe(cards)
    wipe(themeButtons)
    frame = CreateFrame("Frame", "CharacterStatsStylePicker", UIParent)
    frame.themeKey = ns.Theme.key
    frame:SetSize(width, HEADER_HEIGHT + 68 + CARD_HEIGHT + 52)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    ns.Theme.Window(frame, HEADER_HEIGHT)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", frame, "TOPLEFT", PAD, -HEADER_HEIGHT / 2)
    ns.Theme.SetTitle(title, L.PICKER_TITLE or "Choose a look for CharacterStats")
    Widgets.ApplyFontColor(title, "title")
    local themeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    themeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(HEADER_HEIGHT + 18))
    themeLabel:SetText(L.PICKER_THEME or "Window theme")
    Widgets.ApplyFontColor(themeLabel, "textMuted")
    local previous
    for _, key in ipairs(ns.Theme.ORDER) do
        local button = Widgets.CreateFlatButton(frame, 110, 24, ns.Theme.GetName(key))
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        else
            button:SetPoint("LEFT", themeLabel, "RIGHT", 12, 0)
        end
        button:SetScript("OnClick", function()
            if ns.Theme.key ~= key then
                ns.Theme.Set(key)
            end
        end)
        themeButtons[key] = button
        previous = button
    end
    local buttonList = {}
    for _, key in ipairs(ns.Theme.ORDER) do
        buttonList[#buttonList + 1] = themeButtons[key]
    end
    Widgets.NormalizeButtonWidths(buttonList, 12)
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(HEADER_HEIGHT + 44))
    subtitle:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(L.PICKER_SUBTITLE or "Click a look to preview it live, then click Use This Look to keep it. Change it any time with /cs style.")
    Widgets.ApplyFontColor(subtitle, "textMuted")
    for index, style in ipairs(styles) do
        local card = CreateFrame("Button", nil, frame)
        card:SetSize(CARD_WIDTH, CARD_HEIGHT)
        card:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + (index - 1) * (CARD_WIDTH + CARD_GAP), -(HEADER_HEIGHT + 68))
        card.bg = card:CreateTexture(nil, "BACKGROUND")
        card.bg:SetAllPoints()
        card.bg:SetColorTexture(1, 1, 1, 1)
        Widgets.Paint(card.bg, "surface")
        Widgets.CreateBorder(card, 1)
        local preview = CreateFrame("Frame", nil, card)
        preview:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
        preview:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -8)
        preview:SetHeight(PREVIEW_HEIGHT)
        preview.bg = preview:CreateTexture(nil, "BACKGROUND")
        preview.bg:SetAllPoints()
        preview.bg:SetColorTexture(0.03, 0.03, 0.04, 1)
        local draw = PREVIEWS[style.id]
        if draw then
            draw(preview)
        end
        for _, region in ipairs({ preview:GetRegions() }) do
            region.themeSkip = true
        end
        card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.name.themeRole = "heading"
        card.name:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 2, -10)
        card.name:SetText(style.label)
        card.desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.desc:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
        card.desc:SetPoint("RIGHT", card, "RIGHT", -10, 0)
        card.desc:SetJustifyH("LEFT")
        card.desc:SetText(L[DESCRIPTION_KEYS[style.id] or ""] or DESCRIPTION_FALLBACKS[style.id] or "")
        Widgets.ApplyFontColor(card.desc, "textMuted")
        card:SetScript("OnClick", function()
            selected = style.id
            UpdateCards()
            PreviewStyle(style.id)
        end)
        card:SetScript("OnDoubleClick", function()
            selected = style.id
            Apply()
        end)
        cards[style.id] = card
    end
    local useButton = Widgets.CreateFlatButton(frame, 140, 26, L.PICKER_USE or "Use This Look")
    useButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    StylePrimary(useButton)
    useButton:SetScript("OnClick", Apply)
    local laterButton = Widgets.CreateFlatButton(frame, 110, 26, L.PICKER_LATER or "Pick Later")
    laterButton:SetPoint("RIGHT", useButton, "LEFT", -8, 0)
    laterButton:SetScript("OnClick", function()
        MarkSeen()
        frame:Hide()
    end)
    Widgets.NormalizeButtonWidths({ useButton, laterButton }, 14)
    Widgets.BindEscapeToClose(frame, function(self)
        MarkSeen()
        self:Hide()
    end)
    frame:SetScript("OnHide", function()
        if not rebuilding then
            RevertPreview()
        end
    end)
    ns.Theme.ApplyFonts(frame)
    UpdateThemeButtons()
    frame:Hide()
    return frame
end
local function OnThemeChanged()
    if not frame or not frame:IsShown() then return end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    rebuilding = true
    frame:Hide()
    rebuilding = false
    Create()
    if point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, y)
    end
    UpdateCards()
    frame:Show()
end
ns.Theme.OnChange(OnThemeChanged)
function StylePicker.Show()
    if InCombatLockdown() then
        ns.PrintMsg(ns.L.MSG_COMBAT_OPTIONS or "Cannot open options during combat.", "error")
        return
    end
    Create()
    selected = ns.Styles.GetActive().id
    originalStyle = selected
    committed = false
    UpdateCards()
    frame:Show()
end
function StylePicker.ShowIfFirstRun()
    if not ns.db or ns.db.stylePickerSeen then return end
    if InCombatLockdown() then
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            StylePicker.ShowIfFirstRun()
        end)
        return
    end
    StylePicker.Show()
end
