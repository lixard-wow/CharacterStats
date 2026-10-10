local addonName, CS = ...
local ConfigPanel = {}
CS.ConfigPanel = ConfigPanel
local MIN_WIDTH = 560
local MIN_HEIGHT = 420
local DEFAULT_WIDTH = 640
local DEFAULT_HEIGHT = 520
local NAV_WIDTH = 140
local TITLE_HEIGHT = 32
local CONTENT_PAD = 14
local frame
local pages = {}
local pageOrder = {}
function ConfigPanel.RegisterPage(key, def)
    def.key = key
    pages[key] = def
    pageOrder[#pageOrder + 1] = def
    table.sort(pageOrder, function(a, b)
        return (a.order or 99) < (b.order or 99)
    end)
end
function ConfigPanel.RefreshStatsFrame()
    if CS.Stats and CS.Stats.Invalidate then
        CS.Stats:Invalidate()
    end
    if CS.StatsFrame then
        if CS.StatsFrame.ApplyStyle then
            CS.StatsFrame:ApplyStyle()
        elseif CS.StatsFrame.Refresh then
            CS.StatsFrame:Refresh()
        end
    end
    if CS.PaperdollPanel and CS.PaperdollPanel.IsAttached and CS.PaperdollPanel:IsAttached() then
        CS.PaperdollPanel:Refresh()
    end
    if CS.MarkProfileDirty then
        CS.MarkProfileDirty()
    end
end
function ConfigPanel.ApplyStyleChange()
    if CS.StatsFrame then
        CS.StatsFrame:ApplyStyle()
    end
    if CS.PaperdollPanel then
        CS.PaperdollPanel:ApplyStyle()
    end
    if CS.MarkProfileDirty then
        CS.MarkProfileDirty()
    end
end
function ConfigPanel.RefreshAfterProfileChange()
    if CS.Stats and CS.Stats.Invalidate then
        CS.Stats:Invalidate()
    end
    if CS.StatsFrame then
        CS.StatsFrame:RestorePosition()
        CS.StatsFrame:ApplyStyle()
    end
    if CS.PaperdollPanel and CS.PaperdollPanel.IsAttached and CS.PaperdollPanel:IsAttached() then
        CS.PaperdollPanel:Refresh()
    end
    if frame then
        frame:SetScale((CS.db and CS.db.uiScale) or 1.0)
    end
end
function ConfigPanel.ResolveCurrentClassColor()
    local _, classFile = UnitClass("player")
    if not classFile then return nil end
    if C_ClassColor and C_ClassColor.GetClassColor then
        local c = C_ClassColor.GetClassColor(classFile)
        if c and c.r and c.g and c.b then
            return c.r, c.g, c.b
        end
    end
    local customColors = rawget(_G, "CUSTOM_CLASS_COLORS")
    local custom = customColors and customColors[classFile]
    if custom and custom.r then
        return custom.r, custom.g, custom.b
    end
    local fallback = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if fallback and fallback.r then
        return fallback.r, fallback.g, fallback.b
    end
    return nil
end
function ConfigPanel.RefreshTheme()
    local Widgets = CS.ConfigWidgets
    Widgets.RefreshThemeColors()
    if frame and frame.navButtons then
        for _, btn in pairs(frame.navButtons) do
            btn:RefreshTheme()
        end
    end
end
function ConfigPanel.CreateScrollPage(container)
    local scroll = CS.ConfigWidgets.CreateScrollFrame(container)
    scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    local width = frame and frame.content and frame.content:GetWidth()
    if width and width > 1 then
        scroll.content:SetWidth(width)
    end
    return scroll, scroll.content
end
local function SaveFrameSize()
    local db = CS.db
    if not db then return end
    db.ui = db.ui or {}
    db.ui.configWidth = frame:GetWidth()
    db.ui.configHeight = frame:GetHeight()
end
local function CreateCloseButton(parent, glyph)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(20, 20)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    btn.mask = btn:CreateMaskTexture()
    btn.mask:SetAllPoints(btn.bg)
    btn.mask:SetTexture("Interface\\Masks\\CircleMaskScalable", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    btn.bg:AddMaskTexture(btn.mask)
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    btn.text:SetPoint("CENTER", 0, 1)
    btn.text:SetFont(STANDARD_TEXT_FONT, 16, "")
    btn.text:SetText(glyph or "\195\151")
    btn.text:SetTextColor(0.8, 0.8, 0.8)
    btn:SetScript("OnEnter", function(self)
        if glyph then
            self.bg:SetColorTexture(0.3, 0.3, 0.3, 1)
        else
            self.bg:SetColorTexture(0.5, 0.1, 0.1, 1)
        end
        self.text:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    return btn
end
local function CreateMainFrame()
    local themeKey = CS.Theme.Get() and CS.Theme.key
    if frame and frame.themeKey == themeKey then
        return frame
    end
    if frame then
        frame:Hide()
    end
    local Widgets = CS.ConfigWidgets
    local L = CS.L
    frame = CreateFrame("Frame", "CharacterStatsConfigFrame", UIParent)
    frame.themeKey = themeKey
    local savedUi = CS.db and CS.db.ui
    local savedWidth = savedUi and tonumber(savedUi.configWidth)
    local savedHeight = savedUi and tonumber(savedUi.configHeight)
    frame:SetSize(math.max(savedWidth or DEFAULT_WIDTH, MIN_WIDTH), math.max(savedHeight or DEFAULT_HEIGHT, MIN_HEIGHT))
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
    end
    frame:Hide()
    CS.Theme.Window(frame, TITLE_HEIGHT + 1, true)
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.titleBar:SetHeight(TITLE_HEIGHT)
    frame.titleBar:EnableMouse(true)
    frame.titleBar:RegisterForDrag("LeftButton")
    frame.titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    frame.title = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", frame.titleBar, "LEFT", 12, 0)
    CS.Theme.SetTitle(frame.title, L.ADDON_TITLE or "CharacterStats")
    Widgets.ApplyFontColor(frame.title, "title")
    frame.version = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.version:SetPoint("LEFT", frame.title, "RIGHT", 8, -1)
    frame.version:SetText(CS.VERSION or "")
    Widgets.ApplyFontColor(frame.version, "textMuted", 0.7)
    if CS.Theme.key == "classic" then
        frame.closeBtn = CreateCloseButton(frame.titleBar)
    else
        frame.closeBtn = CS.Theme.CloseButton(frame.titleBar, 22)
    end
    frame.closeBtn:SetPoint("RIGHT", frame.titleBar, "RIGHT", -8, 0)
    frame.closeBtn:SetScript("OnClick", function()
        ConfigPanel.Hide()
    end)
    if CS.Theme.key == "classic" then
        frame.minBtn = CreateCloseButton(frame.titleBar, "-")
    else
        frame.minBtn = CS.Theme.IconButton(frame.titleBar, 22, "icon_minus")
    end
    frame.minBtn:SetPoint("RIGHT", frame.closeBtn, "LEFT", -6, 0)
    frame.minBtn:SetScript("OnClick", function()
        ConfigPanel.SetMinimized(not frame._minimized)
    end)
    frame.minBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(frame._minimized and (L.TIP_EXPAND or "Expand") or (L.TIP_MINIMIZE or "Minimize"), 1, 1, 1)
        GameTooltip:Show()
    end)
    frame.minBtn:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.nav = CreateFrame("Frame", nil, frame)
    frame.nav:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 0, 0)
    frame.nav:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    frame.nav:SetWidth(NAV_WIDTH)
    CS.Theme.CornerFill(frame.nav, "nav", (CS.Theme.Get()).windowRadius)
    frame.nav.divider = frame.nav:CreateTexture(nil, "ARTWORK")
    frame.nav.divider:SetPoint("TOPRIGHT", frame.nav, "TOPRIGHT", 0, 0)
    frame.nav.divider:SetPoint("BOTTOMRIGHT", frame.nav, "BOTTOMRIGHT", 0, 0)
    frame.nav.divider:SetWidth(1)
    Widgets.ApplyTextureColor(frame.nav.divider, "border", 1)
    frame.navButtons = {}
    local navY = -8
    for _, def in ipairs(pageOrder) do
        local btn = Widgets.CreateNavButton(frame.nav, (def.labelKey and CS.L[def.labelKey]) or def.label)
        btn:SetPoint("TOPLEFT", frame.nav, "TOPLEFT", 0, navY)
        btn:SetPoint("TOPRIGHT", frame.nav, "TOPRIGHT", -1, navY)
        btn:SetScript("OnClick", function()
            ConfigPanel.ShowPage(def.key)
        end)
        frame.navButtons[def.key] = btn
        navY = navY - 28
    end
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame.nav, "TOPRIGHT", CONTENT_PAD, -CONTENT_PAD)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_PAD, CONTENT_PAD)
    frame.pageFrames = {}
    frame.resizeHandle = CreateFrame("Button", nil, frame)
    frame.resizeHandle:SetSize(16, 16)
    frame.resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    frame.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    frame.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    frame.resizeHandle:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    frame.resizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SaveFrameSize()
    end)
    tinsert(UISpecialFrames, "CharacterStatsConfigFrame")
    frame:SetScript("OnHide", function()
        if CS.FlushProfileSave then
            CS.FlushProfileSave()
        end
    end)
    CS.Theme.ApplyFonts(frame)
    return frame
end
function ConfigPanel.OnThemeChanged()
    local current = frame
    if not current or not current:IsShown() then
        if current then
            current:Hide()
        end
        frame = nil
        return
    end
    local page = current._activePage
    local point, relativeTo, relativePoint, x, y = current:GetPoint(1)
    current:Hide()
    frame = nil
    ConfigPanel.Show()
    if frame and point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, y)
    end
    if page then
        ConfigPanel.ShowPage(page)
    end
end
local function GetPageFrame(key)
    local container = frame.pageFrames[key]
    if container then return container end
    local def = pages[key]
    if not def then return nil end
    container = CreateFrame("Frame", nil, frame.content)
    container:SetAllPoints(frame.content)
    container:Hide()
    container.page = def.create(container) or {}
    CS.Theme.ApplyFonts(container)
    frame.pageFrames[key] = container
    return container
end
function ConfigPanel.ShowPage(key)
    if not frame or not pages[key] then return end
    for pageKey, container in pairs(frame.pageFrames) do
        if pageKey ~= key then
            container:Hide()
        end
    end
    for pageKey, btn in pairs(frame.navButtons) do
        btn:SetActive(pageKey == key)
    end
    local container = GetPageFrame(key)
    container:Show()
    if container.page.Refresh then
        container.page:Refresh()
    end
    frame._activePage = key
end
function ConfigPanel.RefreshActivePage()
    if not frame or not frame:IsShown() or not frame._activePage then return end
    local container = frame.pageFrames[frame._activePage]
    if container and container.page.Refresh then
        container.page:Refresh()
    end
end
function ConfigPanel.GetFrame()
    return frame
end
local function PinTopLeft()
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then return nil end
    local scale = frame:GetScale()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    return left * scale, top * scale
end
local SCALE_ANIM_TIME = 0.18
function ConfigPanel.SetWindowScale(scale)
    if not frame or not scale then return end
    local from = frame:GetScale()
    if math.abs(scale - from) < 0.001 then return end
    local screenLeft, screenTop = PinTopLeft()
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local t = math.min(elapsed / SCALE_ANIM_TIME, 1)
        local eased = 1 - (1 - t) * (1 - t)
        local s = from + (scale - from) * eased
        self:SetScale(s)
        if screenLeft then
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", screenLeft / s, screenTop / s)
        end
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end
function ConfigPanel.SetMinimized(on)
    if not frame then return end
    on = on and true or false
    if (frame._minimized or false) == on then return end
    PinTopLeft()
    frame._minimized = on
    frame.nav:SetShown(not on)
    frame.content:SetShown(not on)
    frame.resizeHandle:SetShown(not on)
    if on then
        frame._expandedHeight = frame:GetHeight()
        if frame.SetResizeBounds then
            frame:SetResizeBounds(MIN_WIDTH, TITLE_HEIGHT + 2)
        end
        frame:SetHeight(TITLE_HEIGHT + 2)
    else
        frame:SetHeight(math.max(frame._expandedHeight or DEFAULT_HEIGHT, MIN_HEIGHT))
        if frame.SetResizeBounds then
            frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
        end
    end
    local btn = frame.minBtn
    if btn.icon then
        btn.icon:SetTexture(CS.Theme.ART .. (on and "icon_chevron_down" or "icon_minus"))
    elseif btn.text then
        btn.text:SetText(on and "+" or "-")
    end
end
function ConfigPanel.Open()
    ConfigPanel.Show()
end
function ConfigPanel.Show()
    if InCombatLockdown() then
        CS.PrintMsg(CS.L.MSG_COMBAT_OPTIONS or "Cannot open options during combat", "error")
        return
    end
    CreateMainFrame()
    frame:SetScript("OnUpdate", nil)
    frame:SetScale((CS.db and CS.db.uiScale) or 1.0)
    ConfigPanel.SetMinimized(false)
    frame:Show()
    ConfigPanel.RefreshTheme()
    ConfigPanel.ShowPage(frame._activePage or (pageOrder[1] and pageOrder[1].key))
end
function ConfigPanel.Hide()
    if frame then
        frame:Hide()
    end
end
function ConfigPanel.Toggle()
    if frame and frame:IsShown() then
        ConfigPanel.Hide()
    else
        ConfigPanel.Show()
    end
end
function ConfigPanel.IsShown()
    return frame and frame:IsShown()
end
CS.Theme.OnChange(ConfigPanel.OnThemeChanged)
return ConfigPanel
