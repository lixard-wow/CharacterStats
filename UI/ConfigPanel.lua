local addonName, CS = ...
local ConfigPanel = {}
CS.ConfigPanel = ConfigPanel
local Widgets
local L
local frame
local TAB_KEYS = { "Display", "Layout", "Profiles", "Themes", "Info" }
local MIN_WIDTH = 550
local MIN_HEIGHT = 400
local DEFAULT_WIDTH = 600
local DEFAULT_HEIGHT = 500
local CreateMainFrame
local CreateDisplayPanel
local CreateLayoutPanel
local CreateProfilesPanel
local CreateThemesPanel
local CreateInfoPanel
local SaveFrameSize
local function RefreshStatsFrame()
    if CS.Stats and CS.Stats.Invalidate then
        CS.Stats:Invalidate()
    end
    if CS.StatsFrame then
        if CS.StatsFrame.ApplyStyle then CS.StatsFrame:ApplyStyle() end
        if CS.StatsFrame.Refresh then CS.StatsFrame:Refresh() end
    end
    if CS.PaperdollPanel and CS.PaperdollPanel.IsAttached and CS.PaperdollPanel:IsAttached() then
        CS.PaperdollPanel:Refresh()
    end
    if CS.MarkProfileDirty then
        CS.MarkProfileDirty()
    end
end
local function ResolveCurrentClassColor()
    if type(UnitClass) ~= "function" then return nil end
    local _, classFile = UnitClass("player")
    if not classFile then return nil end
    if C_ClassColor and C_ClassColor.GetClassColor then
        local c = C_ClassColor.GetClassColor(classFile)
        if c then
            if c.r and c.g and c.b then
                return c.r, c.g, c.b
            end
            if c.GetRGB then
                local r, g, b = c:GetRGB()
                if r and g and b then
                    return r, g, b
                end
            end
        end
    end
    local customColors = _G and rawget(_G, "CUSTOM_CLASS_COLORS")
    local custom = customColors and customColors[classFile]
    if custom and custom.r and custom.g and custom.b then
        return custom.r, custom.g, custom.b
    end
    local fallback = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if fallback and fallback.r and fallback.g and fallback.b then
        return fallback.r, fallback.g, fallback.b
    end
    return nil
end
CreateMainFrame = function()
    if frame then return frame end
    Widgets = CS.ConfigWidgets
    L = CS.L or {}
    frame = CreateFrame("Frame", "CharacterStatsConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:Hide()
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0.06, 0.06, 0.06, 0.98)
    Widgets.CreateBorder(frame, 1)
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.titleBar:SetHeight(32)
    frame.titleBar:EnableMouse(true)
    frame.titleBar:RegisterForDrag("LeftButton")
    frame.titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    frame.titleBar.bg = frame.titleBar:CreateTexture(nil, "BACKGROUND")
    frame.titleBar.bg:SetAllPoints()
    frame.titleBar.bg:SetColorTexture(0.08, 0.08, 0.08, 1)
    frame.title = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", frame.titleBar, "LEFT", 12, 0)
    frame.title:SetText(L.ADDON_TITLE or "CharacterStats")
    Widgets.ApplyFontColor(frame.title, "textPrimary")
    frame.closeBtn = CreateFrame("Button", nil, frame.titleBar, "BackdropTemplate")
    frame.closeBtn:SetSize(24, 24)
    frame.closeBtn:SetPoint("RIGHT", frame.titleBar, "RIGHT", -8, 0)
    frame.closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame.closeBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    frame.closeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    frame.closeBtn.text = frame.closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.closeBtn.text:SetPoint("CENTER", 0, 0)
    frame.closeBtn.text:SetFont(STANDARD_TEXT_FONT, 18, "")
    frame.closeBtn.text:SetText("×")
    frame.closeBtn.text:SetTextColor(0.8, 0.8, 0.8)
    frame.closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.5, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        self.text:SetTextColor(1, 1, 1)
    end)
    frame.closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        self.text:SetTextColor(0.8, 0.8, 0.8)
    end)
    frame.closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.tabBar = CreateFrame("Frame", nil, frame)
    frame.tabBar:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 12, -4)
    frame.tabBar:SetPoint("TOPRIGHT", frame.titleBar, "BOTTOMRIGHT", -12, -4)
    frame.tabBar:SetHeight(28)
    frame.tabButtons = {}
    local tabX = 0
    for i, tabName in ipairs(TAB_KEYS) do
        local btn = Widgets.CreateTabButton(frame.tabBar, L["TAB_" .. tabName:upper()] or tabName)
        btn:SetPoint("LEFT", frame.tabBar, "LEFT", tabX, 0)
        btn._tabName = tabName
        btn:SetScript("OnClick", function()
            ConfigPanel.ShowTab(tabName)
        end)
        frame.tabButtons[tabName] = btn
        tabX = tabX + btn:GetWidth() + 8
    end
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame.tabBar, "BOTTOMLEFT", 0, -8)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 40)
    frame.footer = CreateFrame("Frame", nil, frame)
    frame.footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)
    frame.footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 8)
    frame.footer:SetHeight(28)
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
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
    end
    CreateDisplayPanel()
    CreateLayoutPanel()
    CreateProfilesPanel()
    CreateThemesPanel()
    CreateInfoPanel()
    local maxFooterWidth = MIN_WIDTH
    if frame.layoutPanel and frame.layoutPanel._footerWidth then
        maxFooterWidth = math.max(maxFooterWidth, frame.layoutPanel._footerWidth)
    end
    if frame.profilesPanel and frame.profilesPanel._footerWidth then
        maxFooterWidth = math.max(maxFooterWidth, frame.profilesPanel._footerWidth)
    end
    if frame.SetResizeBounds and maxFooterWidth > MIN_WIDTH then
        frame:SetResizeBounds(maxFooterWidth, MIN_HEIGHT)
        if frame:GetWidth() < maxFooterWidth then
            frame:SetWidth(maxFooterWidth)
        end
    end
    tinsert(UISpecialFrames, "CharacterStatsConfigFrame")
    return frame
end
SaveFrameSize = function()
    local settings = CS.db
    if not settings then return end
    settings.ui = settings.ui or {}
    settings.ui.configWidth = frame:GetWidth()
    settings.ui.configHeight = frame:GetHeight()
end
CreateDisplayPanel = function()
    local panel = CreateFrame("Frame", nil, frame.content)
    panel:SetAllPoints()
    panel:Hide()
    frame.displayPanel = panel
    local scroll = Widgets.CreateScrollFrame(panel)
    scroll:SetAllPoints()
    panel.scroll = scroll
    local content = scroll.content
    local y = -8
    local GROUP_GAP_Y = 6
    local GROUP_TOP_PAD = 24
    local GROUP_BOTTOM_PAD = 2
    local function ApplyDisplayGroupPadding(group)
        if not group or not group.content then
            return
        end
        group.content:ClearAllPoints()
        group.content:SetPoint("TOPLEFT", group, "TOPLEFT", 8, -GROUP_TOP_PAD)
        group.content:SetPoint("BOTTOMRIGHT", group, "BOTTOMRIGHT", -8, GROUP_BOTTOM_PAD)
    end
    local slidersGroup = Widgets.CreateGroupBox(content, L.GROUP_SLIDERS or "Sliders")
    slidersGroup:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y)
    slidersGroup:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y)
    ApplyDisplayGroupPadding(slidersGroup)
    local sliderY = -8
    local SLIDER_ROW_H = 36
    local SLIDER_ROW_GAP = 8
    local SLIDER_LABEL_OFFSET = 6
    local function CreateSliderRow(yOffset)
        local row = CreateFrame("Frame", nil, slidersGroup.content)
        row:SetPoint("TOPLEFT", slidersGroup.content, "TOPLEFT", 8, yOffset)
        row:SetPoint("TOPRIGHT", slidersGroup.content, "TOPRIGHT", -8, yOffset)
        row:SetHeight(SLIDER_ROW_H)
        return row
    end
    local function PlaceLeftSlider(slider, row)
        slider:ClearAllPoints()
        slider:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        slider:SetPoint("TOPRIGHT", row, "TOP", -4, 0)
        slider:SetHeight(SLIDER_ROW_H)
    end
    local function PlaceRightSlider(slider, row)
        slider:ClearAllPoints()
        slider:SetPoint("TOPLEFT", row, "TOP", 4, 0)
        slider:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
        slider:SetHeight(SLIDER_ROW_H)
    end
    local sliderRow1 = CreateSliderRow(sliderY)
    local scaleSlider = Widgets.CreateSlider(sliderRow1, {
        label = L.LABEL_SCALE or "UI Scale",
        labelAboveTrackOffset = SLIDER_LABEL_OFFSET,
        valueAboveTrackOffset = SLIDER_LABEL_OFFSET,
        min = 0.5, max = 1.5, step = 0.05,
        format = "%.2f",
        value = 1.0,
        onChange = function(val)
            if CS.db then
                CS.db.uiScale = val
                if frame then
                    frame:SetScale(val)
                end
                RefreshStatsFrame()
            end
        end
    })
    PlaceLeftSlider(scaleSlider, sliderRow1)
    panel.scaleSlider = scaleSlider
    local bgOpacitySlider = Widgets.CreateSlider(sliderRow1, {
        label = L.LABEL_BG_OPACITY or "Background Opacity",
        labelAboveTrackOffset = SLIDER_LABEL_OFFSET,
        valueAboveTrackOffset = SLIDER_LABEL_OFFSET,
        min = 0, max = 1, step = 0.05,
        format = "%.0f%%",
        formatValue = function(v) return string.format("%.0f%%", v * 100) end,
        value = 0.85,
        onChange = function(val)
            if CS.db then
                CS.db.bgAlpha = val
                RefreshStatsFrame()
            end
        end
    })
    PlaceRightSlider(bgOpacitySlider, sliderRow1)
    panel.bgOpacitySlider = bgOpacitySlider
    sliderY = sliderY - (SLIDER_ROW_H + SLIDER_ROW_GAP)
    local sliderRow2 = CreateSliderRow(sliderY)
    local fontSizeSlider = Widgets.CreateSlider(sliderRow2, {
        label = L.LABEL_FONT_SIZE or "Font Size",
        labelAboveTrackOffset = SLIDER_LABEL_OFFSET,
        valueAboveTrackOffset = SLIDER_LABEL_OFFSET,
        min = 8, max = 16, step = 1,
        format = "%.0f",
        value = 11,
        onChange = function(val)
            if CS.db then
                CS.db.fontSize = val
                RefreshStatsFrame()
            end
        end
    })
    PlaceLeftSlider(fontSizeSlider, sliderRow2)
    panel.fontSizeSlider = fontSizeSlider
    local borderOpacitySlider = Widgets.CreateSlider(sliderRow2, {
        label = L.LABEL_BORDER_OPACITY or "Border Opacity",
        labelAboveTrackOffset = SLIDER_LABEL_OFFSET,
        valueAboveTrackOffset = SLIDER_LABEL_OFFSET,
        min = 0, max = 1, step = 0.05,
        format = "%.0f%%",
        formatValue = function(v) return string.format("%.0f%%", v * 100) end,
        value = 1,
        onChange = function(val)
            if CS.db then
                CS.db.borderAlpha = val
                RefreshStatsFrame()
            end
        end
    })
    PlaceRightSlider(borderOpacitySlider, sliderRow2)
    panel.borderOpacitySlider = borderOpacitySlider
    sliderY = sliderY - (SLIDER_ROW_H + SLIDER_ROW_GAP)
    local sliderRow3 = CreateSliderRow(sliderY)
    local rowSpacingSlider = Widgets.CreateSlider(sliderRow3, {
        label = L.LABEL_ROW_SPACING or "Row Spacing",
        labelAboveTrackOffset = SLIDER_LABEL_OFFSET,
        valueAboveTrackOffset = SLIDER_LABEL_OFFSET,
        min = -3, max = 3, step = 1,
        format = "%.0f",
        formatValue = function(v)
            return string.format("%.0f %s", v, L.UNIT_PX or "px")
        end,
        value = 0,
        onChange = function(val)
            if CS.db then
                CS.db.rowPadding = val
                RefreshStatsFrame()
            end
        end
    })
    PlaceLeftSlider(rowSpacingSlider, sliderRow3)
    panel.rowSpacingSlider = rowSpacingSlider
    local textOpacitySlider = Widgets.CreateSlider(sliderRow3, {
        label = L.LABEL_TEXT_OPACITY or "Text Opacity",
        labelAboveTrackOffset = SLIDER_LABEL_OFFSET,
        valueAboveTrackOffset = SLIDER_LABEL_OFFSET,
        min = 0, max = 1, step = 0.05,
        format = "%.0f%%",
        formatValue = function(v) return string.format("%.0f%%", v * 100) end,
        value = 1,
        onChange = function(val)
            if CS.db then
                CS.db.textAlpha = val
                RefreshStatsFrame()
            end
        end
    })
    PlaceRightSlider(textOpacitySlider, sliderRow3)
    panel.textOpacitySlider = textOpacitySlider
    local sliderContentHeight = 8 + (SLIDER_ROW_H * 3) + (SLIDER_ROW_GAP * 2) + 14
    local sliderGroupHeight = sliderContentHeight + GROUP_TOP_PAD + GROUP_BOTTOM_PAD
    slidersGroup:SetHeight(sliderGroupHeight)
    y = y - (sliderGroupHeight + GROUP_GAP_Y)
    local dropdownsGroup = Widgets.CreateGroupBox(content, L.GROUP_DROPDOWNS or "Options")
    dropdownsGroup:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y)
    dropdownsGroup:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y)
    ApplyDisplayGroupPadding(dropdownsGroup)
    local dropY = -8
    local function CreateDropdownRow(labelText, yOffset, dropOpts)
        local row = CreateFrame("Frame", nil, dropdownsGroup.content)
        row:SetPoint("TOPLEFT", dropdownsGroup.content, "TOPLEFT", 8, yOffset)
        row:SetPoint("TOPRIGHT", dropdownsGroup.content, "TOPRIGHT", -8, yOffset)
        row:SetHeight(22)
        local label, dropdown = Widgets.CreateDropdown(row, labelText, 150, dropOpts)
        if label then
            label:ClearAllPoints()
            label:SetPoint("LEFT", row, "LEFT", 0, 0)
            if label.SetJustifyV then
                label:SetJustifyV("MIDDLE")
            end
        end
        if dropdown then
            dropdown:ClearAllPoints()
            dropdown:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
            dropdown:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        end
        return label, dropdown, row
    end
    local fontFaceLabel, fontFaceDrop = CreateDropdownRow(L.LABEL_FONT_FACE or "Font", dropY, { maxWidth = 350 })
    local LSM = CS.GetLSM and CS.GetLSM() or nil
    local fontItems = {
        { value = "default", text = L.FONT_DEFAULT or "Default" },
    }
    if LSM then
        local fonts = LSM:List("font")
        for _, fontName in ipairs(fonts) do
            table.insert(fontItems, { value = fontName, text = fontName })
        end
    else
        table.insert(fontItems, { value = "Fonts\\ARIALN.TTF", text = L.FONT_ARIAL or "Arial Narrow" })
        table.insert(fontItems, { value = "Fonts\\skurri.ttf", text = L.FONT_SKURRI or "Skurri" })
        table.insert(fontItems, { value = "Fonts\\MORPHEUS.TTF", text = L.FONT_MORPHEUS or "Morpheus" })
    end
    fontFaceDrop:SetItems(fontItems)
    local currentFont = CS.db and CS.db.fontFace or "default"
    local displayText = currentFont == "default" and (L.FONT_DEFAULT or "Default") or currentFont
    fontFaceDrop:SetValue(currentFont, displayText)
    fontFaceDrop:SetOnChange(function(val)
        if CS.db then
            CS.db.fontFace = val
            RefreshStatsFrame()
        end
    end)
    panel.fontFaceDrop = fontFaceDrop
    dropY = dropY - 28
    local borderStyleLabel, borderStyleDrop = CreateDropdownRow(L.LABEL_BORDER_STYLE or "Border Style", dropY)
    borderStyleDrop:SetItems({
        { value = "none", text = L.BORDER_NONE or "None" },
        { value = "thin", text = L.BORDER_THIN or "Thin" },
        { value = "thick", text = L.BORDER_THICK or "Thick" },
        { value = "tooltip", text = L.BORDER_TOOLTIP or "Tooltip" },
        { value = "dialog", text = L.BORDER_DIALOG or "Dialog" },
    })
    borderStyleDrop:SetValue("thin", L.BORDER_THIN or "Thin")
    borderStyleDrop:SetOnChange(function(val)
        if CS.db then
            CS.db.borderStyle = val
            RefreshStatsFrame()
        end
    end)
    panel.borderStyleDrop = borderStyleDrop
    dropY = dropY - 28
    local decimalsLabel, decimalsDrop = CreateDropdownRow(L.LABEL_DECIMALS or "Decimal Places", dropY)
    decimalsDrop:SetItems({
        { value = 0, text = "0" },
        { value = 1, text = "1" },
        { value = 2, text = "2" },
    })
    local defaultDec = CS.IS_RETAIL and 0 or 2
    decimalsDrop:SetValue(defaultDec, tostring(defaultDec))
    decimalsDrop:SetOnChange(function(val)
        if CS.db then
            CS.db.decimals = val
            RefreshStatsFrame()
        end
    end)
    panel.decimalsDrop = decimalsDrop
    dropY = dropY - 28
    local modeLabel, modeDrop = CreateDropdownRow(L.LABEL_DISPLAY_MODE or "Display Mode", dropY)
    modeDrop:SetItems({
        { value = "percent", text = L.MODE_PERCENT or "Percent" },
        { value = "rating", text = L.MODE_RATING or "Rating" },
        { value = "both", text = L.MODE_BOTH or "Both" },
    })
    modeDrop:SetValue("percent", L.MODE_PERCENT or "Percent")
    modeDrop:SetOnChange(function(val)
        if CS.db then
            CS.db.ratingMode = val
            RefreshStatsFrame()
        end
    end)
    panel.modeDrop = modeDrop
    dropY = dropY - 28
    local alignLabel, alignDrop = CreateDropdownRow(L.LABEL_ALIGNMENT or "Alignment", dropY)
    alignDrop:SetItems({
        { value = "left", text = L.ALIGN_LEFT or "Left" },
        { value = "center", text = L.ALIGN_CENTER or "Center" },
        { value = "right", text = L.ALIGN_RIGHT or "Right" },
        { value = "justify", text = L.ALIGN_JUSTIFY or "Justify" },
    })
    alignDrop:SetValue("justify", L.ALIGN_JUSTIFY or "Justify")
    alignDrop:SetOnChange(function(val)
        if CS.db then
            CS.db.alignMode = val
            RefreshStatsFrame()
        end
    end)
    panel.alignDrop = alignDrop
    panel.alignLabel = alignLabel
    dropY = dropY - 28
    local orientLabel, orientDrop = CreateDropdownRow(L.LABEL_ORIENTATION or "Layout Direction", dropY)
    orientDrop:SetItems({
        { value = "vertical", text = L.ORIENT_VERTICAL or "Vertical" },
        { value = "horizontal", text = L.ORIENT_HORIZONTAL or "Horizontal" },
    })
    orientDrop:SetValue("vertical", L.ORIENT_VERTICAL or "Vertical")
    orientDrop:SetOnChange(function(val)
        if CS.db then
            CS.db.orientation = val
            if val == "horizontal" then
                if panel.alignDrop then
                    panel.alignDrop:Disable()
                end
                if panel.alignLabel then
                    panel.alignLabel:SetTextColor(0.4, 0.4, 0.4)
                end
            else
                if panel.alignDrop then
                    panel.alignDrop:Enable()
                end
                if panel.alignLabel then
                    Widgets.ApplyFontColor(panel.alignLabel, "textMuted")
                end
            end
            RefreshStatsFrame()
        end
    end)
    panel.orientDrop = orientDrop
    panel.orientLabel = orientLabel
    panel._allDropdowns = {
        fontFaceDrop,
        borderStyleDrop,
        decimalsDrop,
        modeDrop,
        alignDrop,
        orientDrop,
    }
    panel._normalizedWidth = Widgets.NormalizeDropdownWidths(panel._allDropdowns, 120, 350)
    local dropContentHeight = 8 + (22 * 6) + (6 * 5) + 8
    local dropGroupHeight = dropContentHeight + GROUP_TOP_PAD + GROUP_BOTTOM_PAD
    dropdownsGroup:SetHeight(dropGroupHeight)
    y = y - (dropGroupHeight + GROUP_GAP_Y)
    local colorsGroup = Widgets.CreateGroupBox(content, L.GROUP_COLORS or "Colors")
    colorsGroup:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y)
    colorsGroup:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y)
    ApplyDisplayGroupPadding(colorsGroup)
    local colorY = -10
    local COLOR_ROW_H = 24
    local function CreateColorRow(yOffset)
        local row = CreateFrame("Frame", nil, colorsGroup.content)
        row:SetPoint("TOPLEFT", colorsGroup.content, "TOPLEFT", 8, yOffset)
        row:SetPoint("TOPRIGHT", colorsGroup.content, "TOPRIGHT", -8, yOffset)
        row:SetHeight(COLOR_ROW_H)
        return row
    end
    local colorRow = CreateColorRow(colorY)
    local borderColorLabel = colorRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    borderColorLabel:SetPoint("LEFT", colorRow, "LEFT", 0, 0)
    borderColorLabel:SetText(L.LABEL_BORDER_COLOR or "Border Color")
    Widgets.ApplyFontColor(borderColorLabel, "textMuted")
    if borderColorLabel.SetJustifyV then
        borderColorLabel:SetJustifyV("MIDDLE")
    end
    local borderColorSwatch = CreateFrame("Button", nil, colorRow)
    borderColorSwatch:SetSize(16, 16)
    borderColorSwatch:SetPoint("RIGHT", colorRow, "RIGHT", 0, 0)
    borderColorSwatch:RegisterForClicks("LeftButtonUp")
    Widgets.CreateBorder(borderColorSwatch, 1)
    borderColorSwatch.tex = borderColorSwatch:CreateTexture(nil, "ARTWORK")
    borderColorSwatch.tex:SetPoint("TOPLEFT", 1, -1)
    borderColorSwatch.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    borderColorSwatch.tex:SetColorTexture(1, 1, 1, 1)
    borderColorSwatch.disabled = borderColorSwatch:CreateTexture(nil, "OVERLAY")
    borderColorSwatch.disabled:SetAllPoints()
    borderColorSwatch.disabled:SetColorTexture(0, 0, 0, 0.5)
    borderColorSwatch.disabled:Hide()
    borderColorSwatch:SetScript("OnClick", function()
        if not ColorPickerFrame then return end
        local color = CS.db.borderColor or { r = 1, g = 1, b = 1 }
        local info = {
            r = color.r,
            g = color.g,
            b = color.b,
            hasOpacity = false,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                CS.db.borderColor = { r = r, g = g, b = b }
                borderColorSwatch.tex:SetColorTexture(r, g, b, 1)
                if CS.StatsFrame and CS.StatsFrame.ApplyStyle then
                    CS.StatsFrame:ApplyStyle()
                end
                if CS.MarkProfileDirty then CS.MarkProfileDirty() end
            end,
            cancelFunc = function(prev)
                CS.db.borderColor = { r = prev.r, g = prev.g, b = prev.b }
                borderColorSwatch.tex:SetColorTexture(prev.r, prev.g, prev.b, 1)
                if CS.StatsFrame and CS.StatsFrame.ApplyStyle then
                    CS.StatsFrame:ApplyStyle()
                end
            end,
        }
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow(info)
        else
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.previousValues = { r = info.r, g = info.g, b = info.b }
            ColorPickerFrame.func = info.swatchFunc
            ColorPickerFrame.cancelFunc = function() info.cancelFunc(ColorPickerFrame.previousValues) end
            ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        end
    end)
    panel.borderColorSwatch = borderColorSwatch
    panel.borderColorLabel = borderColorLabel
    colorY = colorY - COLOR_ROW_H - 4
    local sepColorRow = CreateColorRow(colorY)
    local sepColorLabel = sepColorRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sepColorLabel:SetPoint("LEFT", sepColorRow, "LEFT", 0, 0)
    sepColorLabel:SetText(L.LABEL_SEPARATOR_COLOR or "Separator Color")
    Widgets.ApplyFontColor(sepColorLabel, "textMuted")
    if sepColorLabel.SetJustifyV then
        sepColorLabel:SetJustifyV("MIDDLE")
    end
    local sepColorSwatch = CreateFrame("Button", nil, sepColorRow)
    sepColorSwatch:SetSize(16, 16)
    sepColorSwatch:SetPoint("RIGHT", sepColorRow, "RIGHT", 0, 0)
    sepColorSwatch:RegisterForClicks("LeftButtonUp")
    Widgets.CreateBorder(sepColorSwatch, 1)
    sepColorSwatch.tex = sepColorSwatch:CreateTexture(nil, "ARTWORK")
    sepColorSwatch.tex:SetPoint("TOPLEFT", 1, -1)
    sepColorSwatch.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    sepColorSwatch.tex:SetColorTexture(0.5, 0.5, 0.5, 1)
    sepColorSwatch:SetScript("OnClick", function()
        if not ColorPickerFrame then return end
        local color = CS.db.separatorColor or { r = 0.5, g = 0.5, b = 0.5 }
        local info = {
            r = color.r,
            g = color.g,
            b = color.b,
            hasOpacity = false,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                CS.db.separatorColor = { r = r, g = g, b = b }
                sepColorSwatch.tex:SetColorTexture(r, g, b, 1)
                RefreshStatsFrame()
            end,
            cancelFunc = function(prev)
                CS.db.separatorColor = { r = prev.r, g = prev.g, b = prev.b }
                sepColorSwatch.tex:SetColorTexture(prev.r, prev.g, prev.b, 1)
                RefreshStatsFrame()
            end,
        }
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow(info)
        else
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.previousValues = { r = info.r, g = info.g, b = info.b }
            ColorPickerFrame.func = info.swatchFunc
            ColorPickerFrame.cancelFunc = function() info.cancelFunc(ColorPickerFrame.previousValues) end
            ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        end
    end)
    panel.sepColorSwatch = sepColorSwatch
    panel.sepColorLabel = sepColorLabel
    local colorContentHeight = 10 + COLOR_ROW_H + 4 + COLOR_ROW_H + 8
    local colorGroupHeight = colorContentHeight + GROUP_TOP_PAD + GROUP_BOTTOM_PAD
    colorsGroup:SetHeight(colorGroupHeight)
    y = y - (colorGroupHeight + GROUP_GAP_Y)
    local checksGroup = Widgets.CreateGroupBox(content, L.GROUP_CHECKBOXES or "Toggles")
    checksGroup:SetPoint("TOPLEFT", content, "TOPLEFT", 8, y)
    checksGroup:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, y)
    ApplyDisplayGroupPadding(checksGroup)
    local checkY = -10
    local checkSpacing = 24
    local CHECK_ROW_H = 20
    local function CreateToggleRow(yOffset)
        local row = CreateFrame("Frame", nil, checksGroup.content)
        row:SetPoint("TOPLEFT", checksGroup.content, "TOPLEFT", 8, yOffset)
        row:SetPoint("TOPRIGHT", checksGroup.content, "TOPRIGHT", -8, yOffset)
        row:SetHeight(CHECK_ROW_H)
        return row
    end
    local checkRow1 = CreateToggleRow(checkY)
    local showFrameCheck = Widgets.CreateToggle(checkRow1, L.LABEL_SHOW_FRAME or "Show Stats Frame")
    showFrameCheck:SetPoint("LEFT", checkRow1, "LEFT", 0, 0)
    showFrameCheck:SetChecked(true)
    showFrameCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.showFrame = self:GetChecked()
            if CS.StatsFrame then
                if self:GetChecked() then
                    CS.StatsFrame:Show()
                else
                    CS.StatsFrame:Hide()
                end
            end
            if CS.MarkProfileDirty then CS.MarkProfileDirty() end
        end
    end)
    panel.showFrameCheck = showFrameCheck
    local shortNamesCheck = Widgets.CreateToggle(checkRow1, L.LABEL_SHORT_NAMES or "Use Short Names")
    shortNamesCheck:SetPoint("LEFT", checkRow1, "CENTER", 8, 0)
    shortNamesCheck:SetChecked(false)
    shortNamesCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.useShortNames = self:GetChecked()
            RefreshStatsFrame()
        end
    end)
    panel.shortNamesCheck = shortNamesCheck
    checkY = checkY - checkSpacing
    local checkRow2 = CreateToggleRow(checkY)
    local lockCheck = Widgets.CreateToggle(checkRow2, L.LABEL_LOCK or "Lock Position")
    lockCheck:SetPoint("LEFT", checkRow2, "LEFT", 0, 0)
    lockCheck:SetChecked(false)
    lockCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.locked = self:GetChecked()
            RefreshStatsFrame()
        end
    end)
    panel.lockCheck = lockCheck
    local outlineCheck = Widgets.CreateToggle(checkRow2, L.LABEL_OUTLINE or "Font Outline")
    outlineCheck:SetPoint("LEFT", checkRow2, "CENTER", 8, 0)
    outlineCheck:SetChecked(false)
    outlineCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.fontOutline = self:GetChecked() and "OUTLINE" or ""
            RefreshStatsFrame()
        end
    end)
    panel.outlineCheck = outlineCheck
    checkY = checkY - checkSpacing
    local checkRow3 = CreateToggleRow(checkY)
    local clampCheck = Widgets.CreateToggle(checkRow3, L.LABEL_CLAMP or "Clamp to Screen")
    clampCheck:SetPoint("LEFT", checkRow3, "LEFT", 0, 0)
    clampCheck:SetChecked(true)
    clampCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.clampToScreen = self:GetChecked()
            if CS.StatsFrame and CS.StatsFrame.GetFrame then
                local f = CS.StatsFrame:GetFrame()
                if f then f:SetClampedToScreen(self:GetChecked()) end
            end
            if CS.MarkProfileDirty then CS.MarkProfileDirty() end
        end
    end)
    panel.clampCheck = clampCheck
    local paperdollCheck = Widgets.CreateToggle(checkRow3, L.LABEL_PAPERDOLL or "Replace Paperdoll Stats")
    paperdollCheck:SetPoint("LEFT", checkRow3, "CENTER", 8, 0)
    paperdollCheck:SetChecked(true)
    paperdollCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.paperdollEnabled = self:GetChecked()
            if CS.PaperdollPanel then
                if self:GetChecked() then
                    CS.PaperdollPanel:Init()
                else
                    CS.PaperdollPanel:Detach()
                end
            end
            if CS.MarkProfileDirty then CS.MarkProfileDirty() end
        end
    end)
    panel.paperdollCheck = paperdollCheck
    checkY = checkY - checkSpacing
    local checkRow4 = CreateToggleRow(checkY)
    local showMinimapCheck = Widgets.CreateToggle(checkRow4, L.LABEL_SHOW_MINIMAP or "Show Minimap Button")
    showMinimapCheck:SetPoint("LEFT", checkRow4, "LEFT", 0, 0)
    showMinimapCheck:SetChecked(true)
    showMinimapCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.showMinimapButton = self:GetChecked()
            if CS.MinimapButton then
                if self:GetChecked() then
                    CS.MinimapButton:Show()
                else
                    CS.MinimapButton:Hide()
                end
            end
            if CS.MarkProfileDirty then CS.MarkProfileDirty() end
        end
    end)
    panel.showMinimapCheck = showMinimapCheck
    local classColorCheck = Widgets.CreateToggle(checkRow4, L.LABEL_CLASS_COLOR or "Use Class Color for Border")
    classColorCheck:SetPoint("LEFT", checkRow4, "CENTER", 8, 0)
    classColorCheck:SetChecked(false)
    classColorCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.borderUseClassColor = self:GetChecked()
            RefreshStatsFrame()
        end
        local disabled = self:GetChecked() == true
        if borderColorLabel then
            if disabled then
                borderColorLabel:SetTextColor(0.4, 0.4, 0.4)
            else
                Widgets.ApplyFontColor(borderColorLabel, "textMuted")
            end
        end
        if borderColorSwatch then
            borderColorSwatch:EnableMouse(not disabled)
            if borderColorSwatch.disabled then
                borderColorSwatch.disabled:SetShown(disabled)
            end
            if borderColorSwatch.tex then
                if disabled then
                    local r, g, b = ResolveCurrentClassColor()
                    if r and g and b then
                        borderColorSwatch.tex:SetColorTexture(r, g, b, 0.85)
                    else
                        borderColorSwatch.tex:SetColorTexture(1, 1, 1, 0.6)
                    end
                else
                    local color = (CS.db and CS.db.borderColor) or { r = 1, g = 1, b = 1 }
                    borderColorSwatch.tex:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, 1)
                end
            end
        end
    end)
    panel.classColorCheck = classColorCheck
    checkY = checkY - checkSpacing
    local checkRow5 = CreateToggleRow(checkY)
    local showColonCheck = Widgets.CreateToggle(checkRow5, L.LABEL_SHOW_COLON or "Show Colon After Label")
    showColonCheck:SetPoint("LEFT", checkRow5, "LEFT", 0, 0)
    showColonCheck:SetChecked(true)
    showColonCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.showColon = self:GetChecked()
            RefreshStatsFrame()
        end
    end)
    panel.showColonCheck = showColonCheck
    local showSeparatorCheck = Widgets.CreateToggle(checkRow5, L.LABEL_SHOW_SEPARATOR or "Show Separator (Horizontal)")
    showSeparatorCheck:SetPoint("LEFT", checkRow5, "CENTER", 8, 0)
    showSeparatorCheck:SetChecked(false)
    showSeparatorCheck:SetOnClick(function(self)
        if CS.db then
            CS.db.showSeparator = self:GetChecked()
            RefreshStatsFrame()
        end
    end)
    panel.showSeparatorCheck = showSeparatorCheck
    local checkContentHeight = 10 + (CHECK_ROW_H * 5) + (4 * 4) + 8
    local checkGroupHeight = checkContentHeight + GROUP_TOP_PAD + GROUP_BOTTOM_PAD
    checksGroup:SetHeight(checkGroupHeight)
    y = y - checkGroupHeight
    content:SetHeight(math.abs(y) + 4)
end
CreateLayoutPanel = function()
    local panel = CreateFrame("Frame", nil, frame.content)
    panel:SetAllPoints()
    panel:Hide()
    frame.layoutPanel = panel
    panel.scroll = Widgets.CreateScrollFrame(panel)
    panel.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -8)
    panel.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 8)
    panel.statRows = {}
    panel.enableAllBtn = Widgets.CreateFlatButton(frame.footer, 90, 22, L.BTN_ENABLE_ALL or "Enable All")
    panel.enableAllBtn:SetPoint("LEFT", frame.footer, "LEFT", 0, 0)
    panel.enableAllBtn:SetScript("OnClick", function()
        ConfigPanel.SetAllStats(true)
    end)
    panel.enableAllBtn:Hide()
    panel.disableAllBtn = Widgets.CreateFlatButton(frame.footer, 90, 22, L.BTN_DISABLE_ALL or "Disable All")
    panel.disableAllBtn:SetPoint("LEFT", panel.enableAllBtn, "RIGHT", 6, 0)
    panel.disableAllBtn:SetScript("OnClick", function()
        ConfigPanel.SetAllStats(false)
    end)
    panel.disableAllBtn:Hide()
    panel.resetColorsBtn = Widgets.CreateFlatButton(frame.footer, 90, 22, L.BTN_RESET_COLORS or "Reset Colors")
    panel.resetColorsBtn:SetPoint("LEFT", panel.disableAllBtn, "RIGHT", 6, 0)
    panel.resetColorsBtn:SetScript("OnClick", function()
        ConfigPanel.ResetStatColors()
    end)
    panel.resetColorsBtn:Hide()
    panel.resetOrderBtn = Widgets.CreateFlatButton(frame.footer, 90, 22, L.BTN_RESET_ORDER or "Reset Order")
    panel.resetOrderBtn:SetPoint("LEFT", panel.resetColorsBtn, "RIGHT", 6, 0)
    panel.resetOrderBtn:SetScript("OnClick", function()
        ConfigPanel.ResetStatOrder()
    end)
    panel.resetOrderBtn:Hide()
    local btnWidth = Widgets.NormalizeButtonWidths({
        panel.enableAllBtn,
        panel.disableAllBtn,
        panel.resetColorsBtn,
        panel.resetOrderBtn,
    })
    panel._footerWidth = (btnWidth * 4) + (6 * 3) + 24
end
CreateProfilesPanel = function()
    local panel = CreateFrame("Frame", nil, frame.content)
    panel:SetAllPoints()
    panel:Hide()
    frame.profilesPanel = panel
    local inset = Widgets.CreateGroupBox(panel, L.HEADER_PROFILES or "Profiles")
    inset:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    inset:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
    inset:SetHeight(250)
    local y = -8
    local profileLabel, profileDrop = Widgets.CreateDropdown(inset.content, L.LABEL_ACTIVE_PROFILE or "Active Profile", 180)
    profileLabel:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 8, y)
    profileDrop:SetPoint("TOPRIGHT", inset.content, "TOPRIGHT", -8, y)
    panel.profileDrop = profileDrop
    y = y - 32
    local specCheck = Widgets.CreateToggle(inset.content, L.LABEL_SPEC_AUTO_SWITCH or "Automatically switch by specialization")
    specCheck:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 4, y)
    panel.specCheck = specCheck
    y = y - 28
    panel.specDropdowns = {}
    panel.specLabels = {}
    local specs = CS.GetSpecNames()
    if not specs or #specs == 0 then
        specs = {}
    end
    for i, specName in ipairs(specs) do
        local specLabel, specDrop = Widgets.CreateDropdown(inset.content, specName, 180)
        specLabel:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 24, y)
        specDrop:SetPoint("TOPRIGHT", inset.content, "TOPRIGHT", -8, y)
        panel.specDropdowns[specName] = specDrop
        panel.specLabels[specName] = specLabel
        y = y - 32
    end
    local function BuildUniqueName(base)
        local profiles = CS.GetProfileList()
        local taken = {}
        for _, name in ipairs(profiles) do
            taken[name:lower()] = true
        end
        local candidate = base
        local i = 2
        while taken[candidate:lower()] do
            candidate = base .. " " .. i
            i = i + 1
        end
        return candidate
    end
    local function GetSpecNameSet()
        local set = {}
        for _, name in ipairs(specs) do
            set[name] = true
        end
        return set
    end
    local function RefreshProfiles()
        local profiles = CS.GetProfileList()
        local specNameSet = GetSpecNameSet()
        local globalItems = {}
        for _, name in ipairs(profiles) do
            if not specNameSet[name] then
                local displayName = (name == "Default") and (L.PROFILE_DEFAULT or "Default") or name
                globalItems[#globalItems + 1] = { value = name, text = displayName }
            end
        end
        local specItems = {}
        for _, specName in ipairs(specs) do
            specItems[#specItems + 1] = { value = specName, text = specName }
        end
        profileDrop:SetItems(globalItems)
        local active = CS.GetActiveProfile()
        if specNameSet[active] then
            profileDrop:SetValue("Default", L.PROFILE_DEFAULT or "Default")
        else
            local activeDisplay = (active == "Default") and (L.PROFILE_DEFAULT or "Default") or active
            profileDrop:SetValue(active, activeDisplay)
        end
        for specName, drop in pairs(panel.specDropdowns) do
            drop:SetItems(specItems)
            local specProfile = CS.GetSpecProfile(specName)
            local specProfileDisplay = (specProfile == "Default") and (L.PROFILE_DEFAULT or "Default") or specProfile
            drop:SetValue(specProfile, specProfileDisplay)
        end
        if frame.displayPanel and frame.displayPanel._normalizedWidth then
            local w = frame.displayPanel._normalizedWidth
            profileDrop:SetWidth(w)
            for _, drop in pairs(panel.specDropdowns) do
                drop:SetWidth(w)
            end
        end
        local specEnabled = CS.IsSpecProfilesEnabled()
        specCheck:SetChecked(specEnabled)
        local function SetButtonEnabled(btn, enabled)
            if not btn then return end
            if enabled then
                btn:Enable()
                if btn.text then btn.text:SetTextColor(0.9, 0.9, 0.9) end
            else
                btn:Disable()
                if btn.text then btn.text:SetTextColor(0.4, 0.4, 0.4) end
            end
        end
        if specEnabled then
            profileDrop:Disable()
            profileLabel:SetTextColor(0.5, 0.5, 0.5)
            SetButtonEnabled(panel.newBtn, false)
            SetButtonEnabled(panel.copyBtn, false)
            SetButtonEnabled(panel.deleteBtn, false)
        else
            profileDrop:Enable()
            local c = Widgets.GetColor("accentGold")
            profileLabel:SetTextColor(c.r, c.g, c.b)
            SetButtonEnabled(panel.newBtn, true)
            SetButtonEnabled(panel.copyBtn, true)
            SetButtonEnabled(panel.deleteBtn, true)
        end
        for specName, drop in pairs(panel.specDropdowns) do
            if specEnabled then
                drop:Show()
                panel.specLabels[specName]:Show()
            else
                drop:Hide()
                panel.specLabels[specName]:Hide()
            end
        end
    end
    panel.RefreshProfiles = RefreshProfiles
    profileDrop:SetCallback(function(value)
        CS.SwitchProfile(value)
        if CS.StatsFrame then
            CS.StatsFrame:RestorePosition()
            CS.StatsFrame:ApplyStyle()
            CS.StatsFrame:Refresh()
        end
        if CS.PaperdollPanel then
            CS.PaperdollPanel:Refresh()
        end
    end)
    specCheck:SetOnClick(function(self)
        CS.SetSpecProfilesEnabled(self:GetChecked())
        RefreshProfiles()
        if CS.StatsFrame then
            CS.StatsFrame:ApplyStyle()
            CS.StatsFrame:Refresh()
        end
    end)
    for specName, drop in pairs(panel.specDropdowns) do
        drop:SetCallback(function(value)
            CS.SetSpecProfile(specName, value)
            if specName == CS.GetCurrentSpecName() then
                CS.SwitchProfile(value)
                if CS.StatsFrame then
                    CS.StatsFrame:RestorePosition()
                    CS.StatsFrame:ApplyStyle()
                    CS.StatsFrame:Refresh()
                end
            end
        end)
    end
    panel.newBtn = Widgets.CreateFlatButton(frame.footer, 90, 22, L.BTN_NEW or "New")
    panel.newBtn:SetPoint("LEFT", frame.footer, "LEFT", 0, 0)
    panel.newBtn:Hide()
    panel.copyBtn = Widgets.CreateFlatButton(frame.footer, 90, 22, L.BTN_COPY or "Copy")
    panel.copyBtn:SetPoint("LEFT", panel.newBtn, "RIGHT", 6, 0)
    panel.copyBtn:Hide()
    panel.deleteBtn = Widgets.CreateFlatButton(frame.footer, 90, 22, L.BTN_DELETE or "Delete")
    panel.deleteBtn:SetPoint("LEFT", panel.copyBtn, "RIGHT", 6, 0)
    panel.deleteBtn:Hide()
    panel.resetBtn = Widgets.CreateFlatButton(frame.footer, 90, 22, L.BTN_RESET or "Reset")
    panel.resetBtn:SetPoint("LEFT", panel.deleteBtn, "RIGHT", 6, 0)
    panel.resetBtn:Hide()
    local btnWidth = Widgets.NormalizeButtonWidths({
        panel.newBtn,
        panel.copyBtn,
        panel.deleteBtn,
        panel.resetBtn,
    })
    panel._footerWidth = (btnWidth * 4) + (6 * 3) + 24
    panel.newBtn:SetScript("OnClick", function()
        local defaultName = BuildUniqueName(L.PROFILE_NEW_BASE or "New Profile")
        Widgets.CreateInputPopup(
            L.POPUP_NEW_PROFILE_TITLE or "New Profile",
            L.POPUP_NEW_PROFILE_DESC or "Enter a name for the new profile.",
            defaultName,
            function(name)
                local specNameSet = GetSpecNameSet()
                if specNameSet[name] then
                    return false
                end
                if CS.CreateProfile(name) then
                    CS.SwitchProfile(name)
                    RefreshProfiles()
                    if CS.StatsFrame then
                        CS.StatsFrame:RestorePosition()
                        CS.StatsFrame:ApplyStyle()
                        CS.StatsFrame:Refresh()
                    end
                    return true
                end
                return false
            end,
            L.BTN_OK or "OK",
            L.BTN_CANCEL or "Cancel"
        )
    end)
    panel.copyBtn:SetScript("OnClick", function()
        local active = CS.GetActiveProfile()
        local specNameSet = GetSpecNameSet()
        local source = active
        if specNameSet[active] then
            source = "Default"
        end
        local baseName = string.format(L.PROFILE_COPY_BASE or "Copy of %s", source)
        local defaultName = BuildUniqueName(baseName)
        Widgets.CreateInputPopup(
            L.POPUP_COPY_PROFILE_TITLE or "Copy Profile",
            L.POPUP_COPY_PROFILE_DESC or "Copy the current profile to a new one.",
            defaultName,
            function(name)
                if specNameSet[name] then
                    return false
                end
                if CS.CopyProfile(source, name) then
                    RefreshProfiles()
                    return true
                end
                return false
            end,
            L.BTN_OK or "OK",
            L.BTN_CANCEL or "Cancel"
        )
    end)
    panel.deleteBtn:SetScript("OnClick", function()
        local profiles = CS.GetProfileList()
        local active = CS.GetActiveProfile()
        local specNameSet = GetSpecNameSet()
        local deletable = {}
        for _, name in ipairs(profiles) do
            if name ~= "Default" and not specNameSet[name] then
                deletable[#deletable + 1] = { value = name, text = name }
            end
        end
        if #deletable == 0 then
            Widgets.CreatePopup(
                L.POPUP_DELETE_PROFILE_TITLE or "Delete Profile",
                "No profiles to delete. Default and spec profiles cannot be deleted.",
                nil,
                L.BTN_OK or "OK",
                nil
            )
            return
        end
        Widgets.CreateSelectPopup(
            L.POPUP_DELETE_PROFILE_TITLE or "Delete Profile",
            "Select a profile to delete:",
            deletable,
            deletable[1].value,
            function(name)
                if name and name ~= "Default" and not specNameSet[name] and CS.db and CS.db.profiles then
                    if name == active then
                        CS.SwitchProfile("Default")
                    end
                    CS.db.profiles[name] = nil
                    RefreshProfiles()
                    if CS.StatsFrame then
                        CS.StatsFrame:RestorePosition()
                        CS.StatsFrame:ApplyStyle()
                        CS.StatsFrame:Refresh()
                    end
                    return true
                end
                return false
            end,
            L.BTN_DELETE or "Delete",
            L.BTN_CANCEL or "Cancel"
        )
    end)
    panel.resetBtn:SetScript("OnClick", function()
        Widgets.CreatePopup(
            L.POPUP_RESET_PROFILES_TITLE or "Reset Profiles",
            L.POPUP_RESET_PROFILES_DESC or "Reset all profiles? This cannot be undone.",
            function()
                if CS.db and CS.ResetToDefaults then
                    CS.ResetToDefaults()
                    RefreshProfiles()
                    if CS.StatsFrame then
                        CS.StatsFrame:RestorePosition()
                        CS.StatsFrame:ApplyStyle()
                        CS.StatsFrame:Refresh()
                    end
                    if CS.PaperdollPanel then
                        CS.PaperdollPanel:Refresh()
                    end
                end
            end,
            L.BTN_RESET or "Reset",
            L.BTN_CANCEL or "Cancel"
        )
    end)
    panel:SetScript("OnShow", RefreshProfiles)
end
CreateThemesPanel = function()
    local panel = CreateFrame("Frame", nil, frame.content)
    panel:SetAllPoints()
    panel:Hide()
    frame.themesPanel = panel
    local inset = Widgets.CreateGroupBox(panel, L.HEADER_THEMES or "Themes")
    inset:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    inset:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
    inset:SetHeight(90)
    local y = -8
    local themeRow = CreateFrame("Frame", nil, inset.content)
    themeRow:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 8, y)
    themeRow:SetPoint("TOPRIGHT", inset.content, "TOPRIGHT", -8, y)
    themeRow:SetHeight(22)
    local themeLabel, themeDrop = Widgets.CreateDropdown(themeRow, L.LABEL_THEME or "Theme", 180)
    themeLabel:SetPoint("LEFT", themeRow, "LEFT", 0, 0)
    themeDrop:ClearAllPoints()
    themeDrop:SetPoint("RIGHT", themeRow, "RIGHT", 0, 0)
    panel.themeDrop = themeDrop
    panel.themeLabel = themeLabel
    y = y - 28
    local classColorToggle = Widgets.CreateToggle(inset.content, L.LABEL_THEME_USE_CLASS or "Use my class color")
    classColorToggle:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 4, y)
    panel.classColorToggle = classColorToggle
    local function BuildThemeItems()
        local items = {}
        for _, theme in ipairs(CS.THEMES) do
            local name = CS.GetThemeName(theme.id)
            items[#items + 1] = { value = theme.id, text = name }
        end
        return items
    end
    local function RefreshThemes()
        local db = CS.db or CS.DEFAULTS
        local themeId = db.theme or "default"
        local useClassColor = db.themeUseClassColor or false
        themeDrop:SetItems(BuildThemeItems())
        themeDrop:SetValue(themeId, CS.GetThemeName(themeId))
        if frame.displayPanel and frame.displayPanel._normalizedWidth then
            themeDrop:SetWidth(frame.displayPanel._normalizedWidth)
        end
        classColorToggle:SetChecked(useClassColor)
        if useClassColor then
            themeDrop:Disable()
            if panel.themeLabel then
                panel.themeLabel:SetTextColor(0.5, 0.5, 0.5)
            end
        else
            themeDrop:Enable()
            if panel.themeLabel then
                Widgets.ApplyFontColor(panel.themeLabel, "textMuted")
            end
        end
    end
    panel.RefreshThemes = RefreshThemes
    local function ApplyAndRefresh()
        RefreshThemes()
        Widgets.RefreshThemeColors()
        if frame.tabButtons then
            for _, tab in pairs(frame.tabButtons) do
                if tab.RefreshTheme then
                    tab:RefreshTheme()
                end
            end
        end
        if CS.StatsFrame then
            CS.StatsFrame:ApplyStyle()
            CS.StatsFrame:Refresh()
        end
        if CS.PaperdollPanel then
            CS.PaperdollPanel:Refresh()
        end
    end
    themeDrop:SetCallback(function(value)
        if CS.db then CS.db.theme = value end
        ApplyAndRefresh()
    end)
    classColorToggle:SetOnClick(function(self)
        if CS.db then CS.db.themeUseClassColor = self:GetChecked() end
        ApplyAndRefresh()
    end)
    panel:SetScript("OnShow", RefreshThemes)
end
CreateInfoPanel = function()
    local panel = CreateFrame("Frame", nil, frame.content)
    panel:SetAllPoints()
    panel:Hide()
    frame.infoPanel = panel
    local inset = Widgets.CreateGroupBox(panel, L.HEADER_INFO or "About")
    inset:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    inset:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
    inset:SetHeight(172)
    local y = -8
    local version = inset.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    version:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 0, y)
    version:SetJustifyH("LEFT")
    version:SetText((L.LABEL_VERSION or "Version") .. ": " .. (CS.VERSION or "1.0"))
    Widgets.ApplyFontColor(version, "textPrimary")
    y = y - 18
    local author = inset.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    author:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 0, y)
    author:SetJustifyH("LEFT")
    author:SetText((L.LABEL_AUTHOR or "Author") .. ": " .. (CS.AUTHOR or L.UNKNOWN or "Unknown"))
    Widgets.ApplyFontColor(author, "textMuted")
    y = y - 18
    local desc = inset.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 0, y)
    desc:SetPoint("TOPRIGHT", inset.content, "TOPRIGHT", 0, y)
    desc:SetJustifyH("LEFT")
    desc:SetText(L.ADDON_DESC or "A lightweight character stats addon.")
    Widgets.ApplyFontColor(desc, "textMuted", 0.8)
    y = y - 32
    local cmdsHeader = inset.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cmdsHeader:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 0, y)
    cmdsHeader:SetJustifyH("LEFT")
    cmdsHeader:SetText(L.HEADER_COMMANDS or "Slash Commands")
    Widgets.ApplyFontColor(cmdsHeader, "accentGold")
    Widgets.RegisterAccentFontString(cmdsHeader, 1)
    y = y - 18
    local cmds = inset.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cmds:SetPoint("TOPLEFT", inset.content, "TOPLEFT", 0, y)
    cmds:SetPoint("TOPRIGHT", inset.content, "TOPRIGHT", 0, y)
    cmds:SetJustifyH("LEFT")
    cmds:SetText((L.CMD_TOGGLE or "/cs - Toggle stats frame") .. "\n" .. (L.CMD_CONFIG or "/cs config - Open options"))
    Widgets.ApplyFontColor(cmds, "textMuted")
end
function ConfigPanel.ShowTab(tabName)
    if not frame then return end
    if frame.displayPanel then
        frame.displayPanel:Hide()
    end
    if frame.layoutPanel then
        frame.layoutPanel:Hide()
        if frame.layoutPanel.enableAllBtn then frame.layoutPanel.enableAllBtn:Hide() end
        if frame.layoutPanel.disableAllBtn then frame.layoutPanel.disableAllBtn:Hide() end
        if frame.layoutPanel.resetColorsBtn then frame.layoutPanel.resetColorsBtn:Hide() end
        if frame.layoutPanel.resetOrderBtn then frame.layoutPanel.resetOrderBtn:Hide() end
    end
    if frame.profilesPanel then
        frame.profilesPanel:Hide()
        if frame.profilesPanel.newBtn then frame.profilesPanel.newBtn:Hide() end
        if frame.profilesPanel.copyBtn then frame.profilesPanel.copyBtn:Hide() end
        if frame.profilesPanel.deleteBtn then frame.profilesPanel.deleteBtn:Hide() end
        if frame.profilesPanel.resetBtn then frame.profilesPanel.resetBtn:Hide() end
    end
    if frame.themesPanel then frame.themesPanel:Hide() end
    if frame.infoPanel then frame.infoPanel:Hide() end
    for name, btn in pairs(frame.tabButtons) do
        btn:SetActive(name == tabName)
    end
    if tabName == "Display" and frame.displayPanel then
        frame.displayPanel:Show()
        ConfigPanel.RefreshDisplayPanel()
    elseif tabName == "Layout" and frame.layoutPanel then
        frame.layoutPanel:Show()
        if frame.layoutPanel.enableAllBtn then frame.layoutPanel.enableAllBtn:Show() end
        if frame.layoutPanel.disableAllBtn then frame.layoutPanel.disableAllBtn:Show() end
        if frame.layoutPanel.resetColorsBtn then frame.layoutPanel.resetColorsBtn:Show() end
        if frame.layoutPanel.resetOrderBtn then frame.layoutPanel.resetOrderBtn:Show() end
        ConfigPanel.RefreshLayoutPanel()
    elseif tabName == "Profiles" and frame.profilesPanel then
        frame.profilesPanel:Show()
        if frame.profilesPanel.newBtn then frame.profilesPanel.newBtn:Show() end
        if frame.profilesPanel.copyBtn then frame.profilesPanel.copyBtn:Show() end
        if frame.profilesPanel.deleteBtn then frame.profilesPanel.deleteBtn:Show() end
        if frame.profilesPanel.resetBtn then frame.profilesPanel.resetBtn:Show() end
    elseif tabName == "Themes" and frame.themesPanel then
        frame.themesPanel:Show()
    elseif tabName == "Info" and frame.infoPanel then
        frame.infoPanel:Show()
    end
    frame._activeTab = tabName
end
function ConfigPanel.RefreshDisplayPanel()
    local panel = frame and frame.displayPanel
    if not panel then return end
    local db = CS.db or CS.DEFAULTS
    if panel.scaleSlider then
        panel.scaleSlider:SetValue(db.uiScale or 1.0, false)
    end
    if panel.fontSizeSlider then
        panel.fontSizeSlider:SetValue(db.fontSize or 11, false)
    end
    if panel.rowSpacingSlider then
        panel.rowSpacingSlider:SetValue(db.rowPadding or 0, false)
    end
    if panel.bgOpacitySlider then
        panel.bgOpacitySlider:SetValue(db.bgAlpha or 0.85, false)
    end
    if panel.borderOpacitySlider then
        panel.borderOpacitySlider:SetValue(db.borderAlpha or 1, false)
    end
    if panel.textOpacitySlider then
        panel.textOpacitySlider:SetValue(db.textAlpha or 1, false)
    end
    if panel.fontFaceDrop then
        local font = db.fontFace or "default"
        local fontText = font == "default" and (L.FONT_DEFAULT or "Default") or font
        panel.fontFaceDrop:SetValue(font, fontText)
    end
    if panel.borderStyleDrop then
        local style = db.borderStyle or "tooltip"
        local styleText = L["BORDER_" .. string.upper(style)] or style
        panel.borderStyleDrop:SetValue(style, styleText)
    end
    if panel.decimalsDrop then
        local dec = db.decimals
        if dec == nil or type(dec) ~= "number" then
            dec = CS.IS_RETAIL and 0 or 2
            if db.decimals ~= nil then
                db.decimals = dec
            end
        end
        panel.decimalsDrop:SetValue(dec, tostring(dec))
    end
    if panel.modeDrop then
        local mode = db.ratingMode or "percent"
        local modeText = L["MODE_" .. string.upper(mode)] or mode
        panel.modeDrop:SetValue(mode, modeText)
    end
    if panel.alignDrop then
        local align = db.alignMode or "justify"
        local alignTexts = {
            left = L.ALIGN_LEFT or "Left",
            center = L.ALIGN_CENTER or "Center",
            right = L.ALIGN_RIGHT or "Right",
            justify = L.ALIGN_JUSTIFY or "Justify",
        }
        panel.alignDrop:SetValue(align, alignTexts[align] or (L.ALIGN_JUSTIFY or "Justify"))
    end
    if panel.orientDrop then
        local orient = db.orientation or "vertical"
        local orientTexts = {
            vertical = L.ORIENT_VERTICAL or "Vertical",
            horizontal = L.ORIENT_HORIZONTAL or "Horizontal",
        }
        panel.orientDrop:SetValue(orient, orientTexts[orient] or (L.ORIENT_VERTICAL or "Vertical"))
        if orient == "horizontal" then
            if panel.alignDrop then
                panel.alignDrop:Disable()
            end
            if panel.alignLabel then
                panel.alignLabel:SetTextColor(0.4, 0.4, 0.4)
            end
        else
            if panel.alignDrop then
                panel.alignDrop:Enable()
            end
            if panel.alignLabel then
                Widgets.ApplyFontColor(panel.alignLabel, "textMuted")
            end
        end
    end
    if panel.borderColorSwatch and panel.borderColorSwatch.tex then
        if db.borderUseClassColor == true then
            local r, g, b = ResolveCurrentClassColor()
            if r and g and b then
                panel.borderColorSwatch.tex:SetColorTexture(r, g, b, 0.85)
            else
                panel.borderColorSwatch.tex:SetColorTexture(1, 1, 1, 0.6)
            end
        else
            local color = db.borderColor or { r = 1, g = 1, b = 1 }
            panel.borderColorSwatch.tex:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, 1)
        end
    end
    if panel.sepColorSwatch and panel.sepColorSwatch.tex then
        local color = db.separatorColor or { r = 0.5, g = 0.5, b = 0.5 }
        panel.sepColorSwatch.tex:SetColorTexture(color.r or 0.5, color.g or 0.5, color.b or 0.5, 1)
    end
    if panel.showFrameCheck then
        panel.showFrameCheck:SetChecked(db.showFrame ~= false)
    end
    if panel.lockCheck then
        panel.lockCheck:SetChecked(db.locked == true)
    end
    if panel.showMinimapCheck then
        panel.showMinimapCheck:SetChecked(db.showMinimapButton ~= false)
    end
    if panel.clampCheck then
        panel.clampCheck:SetChecked(db.clampToScreen ~= false)
    end
    if panel.shortNamesCheck then
        panel.shortNamesCheck:SetChecked(db.useShortNames == true)
    end
    if panel.showColonCheck then
        panel.showColonCheck:SetChecked(db.showColon ~= false)
    end
    if panel.showSeparatorCheck then
        panel.showSeparatorCheck:SetChecked(db.showSeparator == true)
    end
    if panel.outlineCheck then
        panel.outlineCheck:SetChecked(db.fontOutline == "OUTLINE")
    end
    if panel.paperdollCheck then
        panel.paperdollCheck:SetChecked(db.paperdollEnabled ~= false)
    end
    if panel.classColorCheck then
        panel.classColorCheck:SetChecked(db.borderUseClassColor == true)
    end
    if panel.borderColorSwatch and panel.borderColorSwatch.disabled and panel.borderColorLabel then
        local disabled = db.borderUseClassColor == true
        panel.borderColorSwatch:EnableMouse(not disabled)
        panel.borderColorSwatch.disabled:SetShown(disabled)
        if disabled then
            panel.borderColorLabel:SetTextColor(0.4, 0.4, 0.4)
        else
            Widgets.ApplyFontColor(panel.borderColorLabel, "textMuted")
        end
    end
end
function ConfigPanel.RefreshLayoutPanel()
    local panel = frame and frame.layoutPanel
    if not panel then return end
    local layoutStats = CS.Stats:GetLayoutList()
    local content = panel.scroll.content
    local rowHeight = 26
    local rowGap = 2
    local y = -4
    panel._statOrderIndices = {}
    panel._rowHeight = rowHeight
    panel._rowGap = rowGap
    local rowIndex = 0
    for i, stat in ipairs(layoutStats) do
        local key = stat.id
        local isEnabled = stat.enabled
        local label = stat.label
        rowIndex = rowIndex + 1
        panel._statOrderIndices[rowIndex] = stat.orderIndex
        local row = panel.statRows[rowIndex]
        if not row then
            row = Widgets.CreateStatRow(content, rowIndex, rowHeight)
            panel.statRows[rowIndex] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
        row:SetHeight(rowHeight)
        row:Show()
        row:SetAlt(rowIndex % 2 == 0)
        row.toggle.text:SetText(label)
        row.toggle:SetChecked(isEnabled)
        row.toggle:SetWidth(14 + 6 + row.toggle.text:GetStringWidth() + 8)
        row._statKey = key
        row._visualIndex = rowIndex
        row._orderIndex = stat.orderIndex
        row.toggle:SetOnClick(function(self)
            if CS.db then
                CS.db.stats = CS.db.stats or {}
                local val = self:GetChecked()
                CS.db.stats[key] = val
                local primaryIds = { str = true, agi = true, int = true }
                if primaryIds[key] then
                    for pStat in pairs(primaryIds) do
                        CS.db.stats[pStat] = val
                    end
                end
                RefreshStatsFrame()
            end
        end)
        row:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and not self._dragging then
                local mouseX, mouseY = GetCursorPosition()
                local scale = self:GetEffectiveScale()
                mouseX = mouseX / scale
                mouseY = mouseY / scale
                local swatchLeft = self.swatch:GetLeft()
                local swatchRight = self.swatch:GetRight()
                local swatchBottom = self.swatch:GetBottom()
                local swatchTop = self.swatch:GetTop()
                if swatchLeft and swatchRight and swatchBottom and swatchTop then
                    if mouseX >= swatchLeft and mouseX <= swatchRight and
                       mouseY >= swatchBottom and mouseY <= swatchTop then
                        return
                    end
                end
                local isChecked = self.toggle:GetChecked()
                self.toggle:SetChecked(not isChecked)
                if CS.db then
                    CS.db.stats = CS.db.stats or {}
                    local val = not isChecked
                    CS.db.stats[key] = val
                    local primaryIds = { str = true, agi = true, int = true }
                    if primaryIds[key] then
                        for pStat in pairs(primaryIds) do
                            CS.db.stats[pStat] = val
                        end
                    end
                    RefreshStatsFrame()
                end
            end
        end)
        local sr, sg, sb = CS.GetStatColor(key)
        row.swatch.tex:SetColorTexture(sr, sg, sb, 1)
        if key == "ilvl" then
            row.swatch:SetScript("OnClick", nil)
            row.swatch:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Item Level color is automatic based on item quality", nil, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            row.swatch:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        else
            row.swatch:SetScript("OnClick", function(self, button)
                if button == "RightButton" then
                    if CS.db then
                        CS.db.statColors = CS.db.statColors or {}
                        CS.db.statColors[key] = nil
                        local dr, dg, db = CS.GetStatColor(key)
                        self.tex:SetColorTexture(dr, dg, db, 1)
                        RefreshStatsFrame()
                    end
                else
                    ConfigPanel.OpenStatColorPicker(key, self)
                end
            end)
        end
        row.swatch:Show()
        row._onDragStart = function(self)
            panel._dragRow = self
            panel._dragStartVisualIndex = self._visualIndex
            panel._dragStartOrderIndex = self._orderIndex
        end
        row._onDragStop = function(self)
            if not panel._dragRow then return end
            local targetVisualIndex = ConfigPanel.GetDragTargetVisualIndex(panel)
            if targetVisualIndex and targetVisualIndex ~= panel._dragStartVisualIndex then
                local targetOrderIndex = panel._statOrderIndices[targetVisualIndex]
                if targetOrderIndex then
                    ConfigPanel.MoveStatInOrder(panel._dragStartOrderIndex, targetOrderIndex)
                end
            end
            panel._dragRow = nil
            panel._dragStartVisualIndex = nil
            panel._dragStartOrderIndex = nil
            ConfigPanel.RefreshLayoutPanel()
        end
        y = y - rowHeight - rowGap
    end
    panel._visibleRowCount = rowIndex
    for i = rowIndex + 1, #panel.statRows do
        if panel.statRows[i] then
            panel.statRows[i]:Hide()
        end
    end
    content:SetHeight(math.abs(y) + 20)
end
function ConfigPanel.GetDragTargetVisualIndex(panel)
    if not panel or not panel.scroll then return nil end
    local _, cursorY = GetCursorPosition()
    local scale = panel.scroll:GetEffectiveScale()
    cursorY = cursorY / scale
    local scrollTop = panel.scroll.content:GetTop() or 0
    local scrollOffset = panel.scroll:GetVerticalScroll() or 0
    local localY = scrollTop - cursorY + scrollOffset
    local stride = (panel._rowHeight or 26) + (panel._rowGap or 2)
    local targetIndex = math.floor(localY / stride) + 1
    local maxIndex = panel._visibleRowCount or 1
    return math.max(1, math.min(maxIndex, targetIndex))
end
function ConfigPanel.MoveStatInOrder(fromIndex, toIndex)
    if not CS.db then return end
    local defaults = CS.DEFAULTS or {}
    local currentOrder = CS.db.statOrder or {}
    if #currentOrder == 0 then
        for _, key in ipairs(defaults.statOrder or {}) do
            currentOrder[#currentOrder + 1] = key
        end
    end
    if fromIndex < 1 or fromIndex > #currentOrder then return end
    if toIndex < 1 or toIndex > #currentOrder then return end
    local item = table.remove(currentOrder, fromIndex)
    table.insert(currentOrder, toIndex, item)
    CS.db.statOrder = currentOrder
    RefreshStatsFrame()
end
function ConfigPanel.OpenStatColorPicker(statKey, swatch)
    if not ColorPickerFrame then return end
    if statKey == "ilvl" then
        return
    end
    local r, g, b = CS.GetStatColor(statKey)
    local info = {
        r = r,
        g = g,
        b = b,
        hasOpacity = false,
        swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            if statKey ~= "ilvl" then
                CS.db.statColors = CS.db.statColors or {}
                CS.db.statColors[statKey] = {r=r, g=g, b=b}
            end
            if swatch and swatch.tex then
                swatch.tex:SetColorTexture(r, g, b, 1)
            end
            RefreshStatsFrame()
        end,
        cancelFunc = function(prev)
            if swatch and swatch.tex then
                swatch.tex:SetColorTexture(prev.r, prev.g, prev.b, 1)
            end
        end,
    }
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow(info)
    else
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = { r = info.r, g = info.g, b = info.b }
        ColorPickerFrame.func = info.swatchFunc
        ColorPickerFrame.cancelFunc = function() info.cancelFunc(ColorPickerFrame.previousValues) end
        ColorPickerFrame:SetColorRGB(info.r, info.g, info.b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end
function ConfigPanel.SetAllStats(enabled)
    if not CS.db then return end
    CS.db.stats = CS.db.stats or {}
    local statDefs = CS.STAT_DEFS
    if statDefs then
        for key in pairs(statDefs) do
            CS.db.stats[key] = enabled
        end
    end
    ConfigPanel.RefreshLayoutPanel()
    RefreshStatsFrame()
end
function ConfigPanel.ResetStatOrder()
    if CS.db and CS.DEFAULTS and CS.DEFAULTS.statOrder then
        local newOrder = {}
        for i, statId in ipairs(CS.DEFAULTS.statOrder) do
            newOrder[i] = statId
        end
        CS.db.statOrder = newOrder
    end
    ConfigPanel.RefreshLayoutPanel()
    RefreshStatsFrame()
end
function ConfigPanel.ResetStatColors()
    if CS.db then
        CS.db.statColors = nil
    end
    if CS.InvalidateIlvlColor then
        CS.InvalidateIlvlColor()
    end
    ConfigPanel.RefreshLayoutPanel()
    RefreshStatsFrame()
end
function ConfigPanel.Open()
    ConfigPanel.Show()
end
function ConfigPanel.Show()
    if InCombatLockdown and InCombatLockdown() then
        CS.PrintMsg("Cannot open options during combat", "error")
        return
    end
    if not frame then
        CreateMainFrame()
    end
    local db = CS.db or CS.DEFAULTS
    frame:SetScale(db.uiScale or 1.0)
    Widgets.RefreshThemeColors()
    if frame.tabButtons then
        for _, tab in pairs(frame.tabButtons) do
            if tab.RefreshTheme then
                tab:RefreshTheme()
            end
        end
    end
    frame:Show()
    ConfigPanel.ShowTab(frame._activeTab or "Display")
end
function ConfigPanel.Hide()
    if frame then
        frame:Hide()
    end
    if CS.FlushProfileSave then
        CS.FlushProfileSave()
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
return ConfigPanel
