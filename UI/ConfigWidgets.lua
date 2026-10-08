local addonName, CS = ...
local Widgets = {}
CS.ConfigWidgets = Widgets
local THEME_KEYS = {
    background = "window",
    backgroundLight = "hover",
    textPrimary = "text",
    textMuted = "muted",
    accentGold = "accent",
    border = "border",
    divider = "line",
}
local function ThemeColor(key)
    local _, C = CS.Theme.Get()
    return C[THEME_KEYS[key] or key] or C.text
end
local function Paint(tex, key, alpha)
    local c = ThemeColor(key)
    tex:SetVertexColor(c[1], c[2], c[3], alpha or c[4] or 1)
end
local function Radius()
    local T = CS.Theme.Get()
    return T.buttonRadius or 0
end
Widgets.Paint = Paint
function Widgets.BindEscapeToClose(popup, onEscape)
    popup:EnableKeyboard(true)
    if not InCombatLockdown() then
        popup:SetPropagateKeyboardInput(true)
    end
    popup:SetScript("OnKeyDown", function(self, key)
        local isEscape = key == "ESCAPE"
        if not InCombatLockdown() then
            self:SetPropagateKeyboardInput(not isEscape)
        end
        if isEscape then
            onEscape(self)
        end
    end)
end
local accentTextures = {}
local accentFontStrings = {}
function Widgets.RegisterAccentTexture(tex, alpha)
    if tex then accentTextures[tex] = alpha or 1 end
end
function Widgets.RegisterAccentFontString(fs, alpha)
    if fs then accentFontStrings[fs] = alpha or 1 end
end
function Widgets.RefreshThemeColors()
    CS.Theme.Load()
    local c = Widgets.GetColor("accentGold")
    for tex, alpha in pairs(accentTextures) do
        if tex and tex.SetColorTexture then
            tex:SetColorTexture(c.r, c.g, c.b, alpha)
        end
    end
    for fs, alpha in pairs(accentFontStrings) do
        if fs and fs.SetTextColor then
            fs:SetTextColor(c.r, c.g, c.b, alpha)
        end
    end
end
function Widgets.GetColor(key)
    local c = ThemeColor(key)
    return { r = c[1], g = c[2], b = c[3] }
end
function Widgets.ApplyFontColor(fs, colorKey, alpha)
    if not fs or not fs.SetTextColor then return end
    local c = Widgets.GetColor(colorKey)
    fs:SetTextColor(c.r, c.g, c.b, alpha or 1)
end
function Widgets.ApplyTextureColor(tex, colorKey, alpha)
    if not tex or not tex.SetColorTexture then return end
    local c = Widgets.GetColor(colorKey)
    tex:SetColorTexture(c.r, c.g, c.b, alpha or 1)
end
function Widgets.CreateBorder(frame, thickness)
    local t = thickness or 1
    local c = Widgets.GetColor("border")
    local border = {}
    border.top = frame:CreateTexture(nil, "BORDER")
    border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border.top:SetHeight(t)
    border.top:SetColorTexture(c.r, c.g, c.b, 1)
    border.bottom = frame:CreateTexture(nil, "BORDER")
    border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border.bottom:SetHeight(t)
    border.bottom:SetColorTexture(c.r, c.g, c.b, 1)
    border.left = frame:CreateTexture(nil, "BORDER")
    border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border.left:SetWidth(t)
    border.left:SetColorTexture(c.r, c.g, c.b, 1)
    border.right = frame:CreateTexture(nil, "BORDER")
    border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border.right:SetWidth(t)
    border.right:SetColorTexture(c.r, c.g, c.b, 1)
    frame._border = border
    return border
end
function Widgets.SetBorderColor(frame, colorKey, alpha)
    if not frame then return end
    local c = Widgets.GetColor(colorKey)
    local a = alpha or 1
    local edge = rawget(frame, "edge")
    if edge then
        edge:SetVertexColor(c.r, c.g, c.b, a)
        return
    end
    local b = rawget(frame, "_border")
    if not b then return end
    if b.top then b.top:SetColorTexture(c.r, c.g, c.b, a) end
    if b.bottom then b.bottom:SetColorTexture(c.r, c.g, c.b, a) end
    if b.left then b.left:SetColorTexture(c.r, c.g, c.b, a) end
    if b.right then b.right:SetColorTexture(c.r, c.g, c.b, a) end
end
function Widgets.CreateFlatButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 80, height or 22)
    btn.bg = CS.Theme.Box(btn, "button", "buttonBorder", Radius())
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text.themeRole = "button"
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text or "")
    Widgets.ApplyFontColor(btn.text, "buttonText")
    btn:SetScript("OnEnter", function(self)
        Paint(self.bg, "buttonHover")
        Widgets.ApplyFontColor(self.text, "text")
    end)
    btn:SetScript("OnLeave", function(self)
        Paint(self.bg, "button")
        Widgets.SetBorderColor(self, "buttonBorder")
        Widgets.ApplyFontColor(self.text, "buttonText")
    end)
    btn:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            Paint(self.bg, "field")
        end
    end)
    btn:SetScript("OnMouseUp", function(self)
        if self:IsEnabled() then
            Paint(self.bg, "buttonHover")
        end
    end)
    function btn:SetText(t)
        self.text:SetText(t or "")
    end
    return btn
end
function Widgets.NormalizeButtonWidths(buttons, padding)
    if not buttons or #buttons == 0 then return end
    padding = padding or 16
    local maxWidth = 0
    for _, btn in ipairs(buttons) do
        if btn and btn.text then
            local textWidth = btn.text:GetStringWidth() or 0
            if textWidth > maxWidth then
                maxWidth = textWidth
            end
        end
    end
    local finalWidth = maxWidth + (padding * 2)
    for _, btn in ipairs(buttons) do
        if btn then
            btn:SetWidth(finalWidth)
        end
    end
    return finalWidth
end
function Widgets.CreateToggle(parent, labelText)
    local toggle = CreateFrame("Button", nil, parent)
    toggle:SetHeight(18)
    toggle:EnableMouse(true)
    toggle:RegisterForClicks("LeftButtonUp")
    local BOX_SIZE = 14
    local CHECK_INSET = 3
    toggle.box = CreateFrame("Frame", nil, toggle)
    toggle.box:SetPoint("LEFT", toggle, "LEFT", 0, 0)
    toggle.box:SetSize(BOX_SIZE, BOX_SIZE)
    toggle.box.bg = toggle.box:CreateTexture(nil, "BACKGROUND")
    toggle.box.bg:SetAllPoints()
    toggle.box.bg:SetColorTexture(1, 1, 1, 1)
    Paint(toggle.box.bg, "field")
    Widgets.CreateBorder(toggle.box, 1)
    toggle.check = toggle.box:CreateTexture(nil, "ARTWORK")
    toggle.check:SetPoint("TOPLEFT", toggle.box, "TOPLEFT", CHECK_INSET, -CHECK_INSET)
    toggle.check:SetPoint("BOTTOMRIGHT", toggle.box, "BOTTOMRIGHT", -CHECK_INSET, CHECK_INSET)
    Widgets.ApplyTextureColor(toggle.check, "accentGold", 0.85)
    Widgets.RegisterAccentTexture(toggle.check, 0.85)
    toggle.check:Hide()
    toggle.text = toggle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggle.text:SetPoint("LEFT", toggle.box, "RIGHT", 6, 0)
    toggle.text:SetText(labelText or "")
    Widgets.ApplyFontColor(toggle.text, "textMuted")
    toggle:SetWidth(BOX_SIZE + 6 + (toggle.text:GetStringWidth() or 0) + 8)
    toggle._checked = false
    function toggle:SetChecked(checked)
        self._checked = checked == true
        self.check:SetShown(self._checked)
    end
    function toggle:GetChecked()
        return self._checked == true
    end
    function toggle:SetOnClick(handler)
        self._clickHandler = handler
    end
    toggle:SetScript("OnClick", function(self)
        self:SetChecked(not self:GetChecked())
        if self._clickHandler then
            self._clickHandler(self)
        end
    end)
    return toggle
end
function Widgets.CreateSlider(parent, opts)
    opts = opts or {}
    local s = CreateFrame("Frame", opts.name, parent)
    s:SetSize(opts.width or 200, opts.height or 32)
    s.min = opts.min or 0
    s.max = opts.max or 100
    s.step = opts.step or 1
    s.value = s.min
    s.label = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s.label:SetPoint("TOPLEFT", s, "TOPLEFT", 0, opts.labelOffsetY or 0)
    s.label:SetText(opts.label or "")
    Widgets.ApplyFontColor(s.label, "textMuted")
    s.valueText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s.valueText:SetPoint("TOPRIGHT", s, "TOPRIGHT", 0, opts.valueOffsetY or 0)
    s.valueText:SetJustifyH("RIGHT")
    Widgets.ApplyFontColor(s.valueText, "textMuted")
    local trackHeight = 4
    s.track = CreateFrame("Frame", nil, s)
    s.track:SetPoint("BOTTOMLEFT", s, "BOTTOMLEFT", 0, 0)
    s.track:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 0, 0)
    s.track:SetHeight(trackHeight)
    if opts.labelAboveTrackOffset ~= nil then
        s.label:ClearAllPoints()
        s.label:SetPoint("BOTTOMLEFT", s.track, "TOPLEFT", 0, opts.labelAboveTrackOffset)
    end
    if opts.valueAboveTrackOffset ~= nil then
        s.valueText:ClearAllPoints()
        s.valueText:SetPoint("BOTTOMRIGHT", s.track, "TOPRIGHT", 0, opts.valueAboveTrackOffset)
    end
    s.track.bg = s.track:CreateTexture(nil, "BACKGROUND")
    s.track.bg:SetAllPoints()
    s.track.bg:SetColorTexture(1, 1, 1, 1)
    Paint(s.track.bg, "hover", 0.9)
    Widgets.CreateBorder(s.track, 1)
    s.fill = s.track:CreateTexture(nil, "ARTWORK")
    s.fill:SetPoint("LEFT", s.track, "LEFT", 0, 0)
    s.fill:SetHeight(trackHeight)
    Widgets.ApplyTextureColor(s.fill, "accentGold", 0.7)
    Widgets.RegisterAccentTexture(s.fill, 0.7)
    s.thumb = CreateFrame("Frame", nil, s.track)
    s.thumb:SetSize(12, 12)
    s.thumb:SetFrameLevel(s.track:GetFrameLevel() + 1)
    s.thumb.bg = s.thumb:CreateTexture(nil, "ARTWORK")
    s.thumb.bg:SetAllPoints()
    Widgets.ApplyTextureColor(s.thumb.bg, "accentGold", 0.95)
    Widgets.RegisterAccentTexture(s.thumb.bg, 0.95)
    s.thumb.mask = s.thumb:CreateMaskTexture()
    s.thumb.mask:SetAllPoints(s.thumb.bg)
    s.thumb.mask:SetTexture("Interface\\Masks\\CircleMaskScalable", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    s.thumb.bg:AddMaskTexture(s.thumb.mask)
    s.hit = CreateFrame("Button", nil, s.track)
    s.hit:SetPoint("TOPLEFT", s.track, "TOPLEFT", -4, 6)
    s.hit:SetPoint("BOTTOMRIGHT", s.track, "BOTTOMRIGHT", 4, -6)
    s.hit:EnableMouse(true)
    s.hit:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    local function UpdateVisuals()
        local w = s.track:GetWidth()
        if not w or w <= 1 then return end
        local range = s.max - s.min
        local t = (range > 0) and ((s.value - s.min) / range) or 0
        t = math.max(0, math.min(1, t))
        s.fill:SetWidth(math.max(w * t, 1))
        s.thumb:ClearAllPoints()
        s.thumb:SetPoint("CENTER", s.track, "LEFT", w * t, 0)
        if opts.formatValue then
            s.valueText:SetText(opts.formatValue(s.value))
        else
            s.valueText:SetText(string.format(opts.format or "%.0f", s.value))
        end
    end
    local function RoundToStep(val)
        if s.step and s.step > 0 then
            local steps = math.floor((val - s.min) / s.step + 0.5)
            return s.min + steps * s.step
        end
        return val
    end
    function s:SetValue(val, fromUser)
        val = tonumber(val) or s.min
        val = math.max(s.min, math.min(s.max, val))
        val = RoundToStep(val)
        s.value = val
        UpdateVisuals()
        if fromUser and opts.onChange then
            opts.onChange(val)
        end
    end
    function s:GetValue()
        return s.value
    end
    local function ValueFromCursor()
        local x = select(1, GetCursorPosition())
        local scale = s.hit:GetEffectiveScale()
        x = x / scale
        local left = s.hit:GetLeft() or 0
        local right = s.hit:GetRight() or 1
        if right <= left then return s.min end
        local t = (x - left) / (right - left)
        t = math.max(0, math.min(1, t))
        return s.min + t * (s.max - s.min)
    end
    local dragging = false
    s.hit:SetScript("OnMouseDown", function()
        dragging = true
        s:SetValue(ValueFromCursor(), true)
        s:SetScript("OnUpdate", function()
            if dragging then
                s:SetValue(ValueFromCursor(), true)
            end
        end)
    end)
    s.hit:SetScript("OnMouseUp", function()
        dragging = false
        s:SetScript("OnUpdate", nil)
    end)
    s.track:HookScript("OnSizeChanged", UpdateVisuals)
    s:SetValue(opts.value or opts.min or 0, false)
    return s
end
function Widgets.CreateDropdown(parent, labelText, width, opts)
    opts = opts or {}
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetText(labelText or "")
    Widgets.ApplyFontColor(label, "textMuted")
    local dropdown = CreateFrame("Button", nil, parent)
    dropdown:SetSize(width or 150, 22)
    dropdown:EnableMouse(true)
    dropdown:RegisterForClicks("AnyUp")
    dropdown.bg = CS.Theme.Box(dropdown, "field", "border", Radius())
    dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dropdown.text:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
    dropdown.text:SetPoint("RIGHT", dropdown, "RIGHT", -20, 0)
    dropdown.text:SetJustifyH("LEFT")
    Widgets.ApplyFontColor(dropdown.text, "textMuted")
    dropdown.arrow = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dropdown.arrow:SetPoint("RIGHT", dropdown, "RIGHT", -6, 0)
    dropdown.arrow:SetText("v")
    Widgets.ApplyFontColor(dropdown.arrow, "textMuted")
    dropdown._items = {}
    dropdown._value = nil
    dropdown._open = false
    dropdown:HookScript("OnEnter", function(self)
        Widgets.SetBorderColor(self, "accentGold", 0.65)
    end)
    dropdown:HookScript("OnLeave", function(self)
        if not self._open then
            Widgets.SetBorderColor(self, "border")
        end
    end)
    function dropdown:SetItems(items)
        self._items = items or {}
        if not opts.fixedWidth then
            local maxWidth = 0
            for _, item in ipairs(self._items) do
                local text = item.text or item.value or ""
                self.text:SetText(text)
                local textWidth = self.text:GetStringWidth() or 0
                if textWidth > maxWidth then
                    maxWidth = textWidth
                end
            end
            local newWidth = maxWidth + 38
            local minWidth = opts.minWidth or 120
            local maxWidthLimit = opts.maxWidth or 300
            newWidth = math.max(minWidth, math.min(maxWidthLimit, newWidth))
            self:SetWidth(newWidth)
            if self._value then
                for _, item in ipairs(self._items) do
                    if item.value == self._value then
                        self.text:SetText(item.text or tostring(self._value))
                        break
                    end
                end
            else
                self.text:SetText("")
            end
        end
    end
    function dropdown:SetValue(value, displayText)
        self._value = value
        self.text:SetText(displayText or tostring(value or ""))
    end
    function dropdown:GetValue()
        return self._value
    end
    function dropdown:SetOnChange(handler)
        self._onChange = handler
    end
    local function CloseMenu()
        if dropdown.overlay then
            dropdown.overlay:Hide()
        end
        if dropdown.menu then
            dropdown.menu:Hide()
        end
        dropdown._open = false
        Widgets.SetBorderColor(dropdown, "border")
    end
    local function ShowMenu()
        local items = dropdown._items
        local itemHeight = 22
        local menuWidth = dropdown:GetWidth()
        local maxHeight = 260
        local totalHeight = #items * (itemHeight + 2)
        local needsScroll = totalHeight > maxHeight
        if not dropdown.overlay then
            dropdown.overlay = CreateFrame("Button", nil, UIParent)
            dropdown.overlay:SetFrameStrata("DIALOG")
            dropdown.overlay:SetAllPoints(UIParent)
            dropdown.overlay:SetScript("OnClick", CloseMenu)
        end
        dropdown.overlay:Show()
        if not dropdown.menu then
            dropdown.menu = CreateFrame("Frame", nil, UIParent)
            dropdown.menu:SetFrameStrata("TOOLTIP")
            dropdown.menu:SetClampedToScreen(true)
            dropdown.menu:EnableMouse(true)
            dropdown.menu.bg = CS.Theme.Box(dropdown.menu, "window", "border", Radius())
            dropdown.menu.rows = {}
        end
        local parent = dropdown.menu
        local scrollBarWidth = 6
        if needsScroll then
            if not dropdown.menu.scroll then
                local scroll = CreateFrame("ScrollFrame", nil, dropdown.menu)
                scroll:SetPoint("TOPLEFT", 1, -1)
                scroll:SetPoint("BOTTOMRIGHT", -scrollBarWidth - 3, 1)
                dropdown.menu.scroll = scroll
                local content = CreateFrame("Frame", nil, scroll)
                scroll:SetScrollChild(content)
                dropdown.menu.scrollContent = content
                local track = dropdown.menu:CreateTexture(nil, "BACKGROUND", nil, 1)
                track:SetPoint("TOPRIGHT", -1, -1)
                track:SetPoint("BOTTOMRIGHT", -1, 1)
                track:SetWidth(scrollBarWidth)
                track:SetColorTexture(1, 1, 1, 1)
                Paint(track, "line")
                dropdown.menu.track = track
                local thumb = CreateFrame("Button", nil, dropdown.menu)
                thumb:SetWidth(scrollBarWidth)
                thumb:SetPoint("TOPRIGHT", -1, -1)
                thumb.tex = thumb:CreateTexture(nil, "ARTWORK")
                thumb.tex:SetAllPoints()
                thumb.tex:SetColorTexture(1, 1, 1, 1)
                Paint(thumb.tex, "muted")
                dropdown.menu.thumb = thumb
                thumb:EnableMouse(true)
                thumb:SetScript("OnMouseDown", function() thumb.dragging = true end)
                thumb:SetScript("OnMouseUp", function() thumb.dragging = false end)
                thumb:SetScript("OnUpdate", function(self)
                    if self.dragging then
                        local _, cursorY = GetCursorPosition()
                        local scale = dropdown.menu:GetEffectiveScale()
                        local top = dropdown.menu:GetTop() * scale - 1
                        local trackH = (maxHeight - 2) * scale
                        local thumbH = self:GetHeight() * scale
                        local pct = 1 - ((cursorY - (top - trackH + thumbH/2)) / (trackH - thumbH))
                        pct = math.max(0, math.min(1, pct))
                        dropdown.menu.scroll:SetVerticalScroll(pct * (totalHeight - maxHeight + 2))
                    end
                end)
                scroll:EnableMouseWheel(true)
                scroll:SetScript("OnMouseWheel", function(self, delta)
                    local current = self:GetVerticalScroll()
                    local newScroll = current - delta * itemHeight * 4
                    newScroll = math.max(0, math.min(totalHeight - maxHeight + 2, newScroll))
                    self:SetVerticalScroll(newScroll)
                end)
            end
            dropdown.menu.scroll:Show()
            dropdown.menu.track:Show()
            dropdown.menu.thumb:Show()
            dropdown.menu.scrollContent:SetSize(menuWidth - scrollBarWidth - 4, totalHeight)
            dropdown.menu.scroll:SetVerticalScroll(0)
            local thumbH = math.max(20, (maxHeight / totalHeight) * (maxHeight - 2))
            dropdown.menu.thumb:SetHeight(thumbH)
            dropdown.menu.scroll:SetScript("OnScrollRangeChanged", function() end)
            dropdown.menu.scroll:SetScript("OnVerticalScroll", function(self, offset)
                local maxScroll = totalHeight - maxHeight + 2
                local pct = maxScroll > 0 and (offset / maxScroll) or 0
                local trackH = maxHeight - 2
                local thumbH = dropdown.menu.thumb:GetHeight()
                dropdown.menu.thumb:SetPoint("TOPRIGHT", -1, -1 - pct * (trackH - thumbH))
            end)
            parent = dropdown.menu.scrollContent
        elseif dropdown.menu.scroll then
            dropdown.menu.scroll:Hide()
            dropdown.menu.track:Hide()
            dropdown.menu.thumb:Hide()
        end
        local rowWidth = menuWidth - (needsScroll and (scrollBarWidth + 6) or 2)
        for i, item in ipairs(items) do
            local row = dropdown.menu.rows[i]
            if not row then
                row = Widgets.CreateFlatButton(parent, rowWidth, itemHeight, "")
                dropdown.menu.rows[i] = row
            end
            row:SetParent(parent)
            row:SetText(item.text or item.value or "")
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i-1) * (itemHeight + 2))
            row:SetWidth(rowWidth)
            row:Show()
            row._isSelected = (item.value == dropdown._value)
            if row._isSelected then
                Widgets.ApplyFontColor(row.text, "accentGold")
            else
                Widgets.ApplyFontColor(row.text, "textMuted")
            end
            row:SetScript("OnEnter", function(self)
                if self.bg then
                    Paint(self.bg, "buttonHover")
                end
                Widgets.SetBorderColor(self, "accentGold", 0.95)
                if self._isSelected then
                    Widgets.ApplyFontColor(self.text, "accentGold")
                else
                    Widgets.ApplyFontColor(self.text, "textPrimary")
                end
            end)
            row:SetScript("OnLeave", function(self)
                if self.bg then
                    Paint(self.bg, "button")
                end
                Widgets.SetBorderColor(self, "border")
                if self._isSelected then
                    Widgets.ApplyFontColor(self.text, "accentGold")
                else
                    Widgets.ApplyFontColor(self.text, "textMuted")
                end
            end)
            row:SetScript("OnClick", function()
                dropdown:SetValue(item.value, item.text)
                CloseMenu()
                if dropdown._onChange then
                    dropdown._onChange(item.value, item.text)
                end
            end)
        end
        for i = #items + 1, #dropdown.menu.rows do
            dropdown.menu.rows[i]:Hide()
        end
        CS.Theme.ApplyFonts(dropdown.menu)
        local menuHeight = needsScroll and maxHeight or (totalHeight + 2)
        dropdown.menu:SetScale(dropdown:GetEffectiveScale() / UIParent:GetEffectiveScale())
        dropdown.menu:SetSize(menuWidth, menuHeight)
        dropdown.menu:ClearAllPoints()
        dropdown.menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
        dropdown.menu:Show()
        dropdown._open = true
        Widgets.SetBorderColor(dropdown, "accentGold", 0.95)
    end
    dropdown:SetScript("OnClick", function(self)
        if self._open then
            CloseMenu()
        else
            ShowMenu()
        end
    end)
    dropdown:HookScript("OnHide", CloseMenu)
    function dropdown:SetCallback(handler)
        self._onChange = handler
    end
    function dropdown:Disable()
        self._disabled = true
        self:EnableMouse(false)
        Paint(self.bg, "field", 0.5)
        Widgets.ApplyFontColor(self.text, "disabled")
        Widgets.ApplyFontColor(self.arrow, "disabled")
    end
    function dropdown:Enable()
        self._disabled = false
        self:EnableMouse(true)
        Paint(self.bg, "field")
        Widgets.ApplyFontColor(self.text, "textMuted")
        Widgets.ApplyFontColor(self.arrow, "textMuted")
    end
    return label, dropdown
end
function Widgets.CreateStatRow(parent, index, height)
    height = height or 24
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(height)
    row:EnableMouse(true)
    row:SetMovable(true)
    row:RegisterForDrag("LeftButton")
    row.alt = row:CreateTexture(nil, "BACKGROUND")
    row.alt:SetAllPoints()
    row.alt:SetColorTexture(1, 1, 1, 1)
    Paint(row.alt, "surface", 0.7)
    row.alt:Hide()
    row.hover = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(1, 1, 1, 1)
    Paint(row.hover, "hover", 0.8)
    row.hover:Hide()
    row.grip = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.grip:SetPoint("LEFT", row, "LEFT", 8, 0)
    row.grip:SetText(":::")
    Widgets.ApplyFontColor(row.grip, "textMuted", 0.5)
    row.toggle = Widgets.CreateToggle(row, "")
    row.toggle:SetPoint("LEFT", row.grip, "RIGHT", 6, 0)
    row.swatch = CreateFrame("Button", nil, row)
    row.swatch:SetSize(16, 16)
    row.swatch:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    Widgets.CreateBorder(row.swatch, 1)
    row.swatch.tex = row.swatch:CreateTexture(nil, "ARTWORK")
    row.swatch.tex:SetPoint("TOPLEFT", 1, -1)
    row.swatch.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    row.swatch.tex:SetColorTexture(1, 0.82, 0, 1)
    row:SetScript("OnEnter", function(self)
        self.hover:Show()
        Widgets.ApplyFontColor(self.grip, "textMuted", 0.8)
    end)
    row:SetScript("OnLeave", function(self)
        if not self._dragging then
            self.hover:Hide()
        end
        Widgets.ApplyFontColor(self.grip, "textMuted", 0.5)
    end)
    row:SetScript("OnDragStart", function(self)
        self._dragging = true
        self:SetFrameLevel(self:GetFrameLevel() + 10)
        self:SetAlpha(0.7)
        self:StartMoving()
        if self._onDragStart then self._onDragStart(self) end
    end)
    row:SetScript("OnDragStop", function(self)
        self._dragging = false
        self:StopMovingOrSizing()
        self:SetAlpha(1)
        self:SetFrameLevel(self:GetFrameLevel() - 10)
        self.hover:Hide()
        if self._onDragStop then self._onDragStop(self) end
    end)
    function row:SetAlt(show)
        self.alt:SetShown(show)
    end
    return row
end
function Widgets.CreateScrollFrame(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll.content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(scroll.content)
    scroll.content:SetPoint("TOPLEFT")
    scroll.content:SetWidth(1)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = math.max(0, (self.content:GetHeight() or 0) - self:GetHeight())
        local new = math.max(0, math.min(maxScroll, current - delta * 40))
        self:SetVerticalScroll(new)
    end)
    scroll:HookScript("OnSizeChanged", function(self)
        self.content:SetWidth(self:GetWidth())
    end)
    return scroll
end
function Widgets.OpenColorPicker(r, g, b, onChange, onCancel)
    if not ColorPickerFrame then return end
    local info = {
        r = r,
        g = g,
        b = b,
        hasOpacity = false,
        swatchFunc = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            onChange(nr, ng, nb)
        end,
        cancelFunc = function(prev)
            if onCancel and prev then
                onCancel(prev.r, prev.g, prev.b)
            end
        end,
    }
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow(info)
    else
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = { r = r, g = g, b = b }
        ColorPickerFrame.func = info.swatchFunc
        ColorPickerFrame.cancelFunc = function() info.cancelFunc(ColorPickerFrame.previousValues) end
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end
function Widgets.CreateSwatch(parent)
    local swatch = CreateFrame("Button", nil, parent)
    swatch:SetSize(16, 16)
    swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    Widgets.CreateBorder(swatch, 1)
    swatch.tex = swatch:CreateTexture(nil, "ARTWORK")
    swatch.tex:SetPoint("TOPLEFT", 1, -1)
    swatch.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    swatch.tex:SetColorTexture(1, 1, 1, 1)
    swatch.disabled = swatch:CreateTexture(nil, "OVERLAY")
    swatch.disabled:SetAllPoints()
    swatch.disabled:SetColorTexture(0, 0, 0, 0.55)
    swatch.disabled:Hide()
    function swatch:SetColor(r, g, b, a)
        self.tex:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    end
    function swatch:SetDisabled(disabled)
        self:EnableMouse(not disabled)
        self.disabled:SetShown(disabled)
    end
    return swatch
end
function Widgets.CreateNavButton(parent, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(26)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0, 0, 0, 0)
    btn.bar = btn:CreateTexture(nil, "ARTWORK")
    btn.bar:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.bar:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn.bar:SetWidth(2)
    btn.bar:Hide()
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text:SetPoint("LEFT", btn, "LEFT", 12, 0)
    btn.text:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    btn.text:SetJustifyH("LEFT")
    btn.text:SetText(text or "")
    Widgets.ApplyFontColor(btn.text, "textMuted")
    btn._active = false
    function btn:SetActive(active)
        self._active = active == true
        if self._active then
            self.bg:SetColorTexture(1, 1, 1, 1)
            Paint(self.bg, "hover")
            Widgets.ApplyTextureColor(self.bar, "accentGold", 1)
            self.bar:Show()
            Widgets.ApplyFontColor(self.text, "textPrimary")
        else
            self.bg:SetColorTexture(0, 0, 0, 0)
            self.bar:Hide()
            Widgets.ApplyFontColor(self.text, "textMuted")
        end
    end
    function btn:RefreshTheme()
        self:SetActive(self._active)
    end
    btn:SetScript("OnEnter", function(self)
        if not self._active then
            self.bg:SetColorTexture(1, 1, 1, 1)
            Paint(self.bg, "surface")
            Widgets.ApplyFontColor(self.text, "textPrimary", 0.85)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self._active then
            self.bg:SetColorTexture(0, 0, 0, 0)
            Widgets.ApplyFontColor(self.text, "textMuted")
        end
    end)
    return btn
end
function Widgets.CreateSectionHeader(parent, text)
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(18)
    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.text.themeRole = "heading"
    header.text:SetPoint("LEFT", header, "LEFT", 0, 0)
    header.text:SetText(text or "")
    Widgets.ApplyFontColor(header.text, "accentGold")
    Widgets.RegisterAccentFontString(header.text, 1)
    header.line = header:CreateTexture(nil, "ARTWORK")
    header.line:SetPoint("LEFT", header.text, "RIGHT", 8, 0)
    header.line:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    header.line:SetHeight(1)
    Widgets.ApplyTextureColor(header.line, "border", 1)
    return header
end
local activePopup = nil
local function CloseActivePopup()
    if activePopup then
        activePopup:Hide()
        activePopup:SetParent(nil)
        activePopup = nil
    end
end
function Widgets.CreatePopup(title, body, onAccept, okText, cancelText)
    CloseActivePopup()
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetSize(320, 120)
    popup:SetPoint("CENTER")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    CS.Theme.Box(popup, "window", "border", (CS.Theme.Get()).windowRadius)
    local titleFs = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFs.themeRole = "heading"
    titleFs:SetPoint("TOPLEFT", 12, -12)
    titleFs:SetText(title or "")
    Widgets.ApplyFontColor(titleFs, "textPrimary")
    local bodyFs = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyFs:SetPoint("TOPLEFT", 12, -36)
    bodyFs:SetPoint("TOPRIGHT", -12, -36)
    bodyFs:SetJustifyH("LEFT")
    bodyFs:SetText(body or "")
    Widgets.ApplyFontColor(bodyFs, "textMuted")
    local okBtn = Widgets.CreateFlatButton(popup, 80, 22, okText or "OK")
    okBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    local cancelBtn = Widgets.CreateFlatButton(popup, 80, 22, cancelText or "Cancel")
    cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -8, 0)
    okBtn:SetScript("OnClick", function()
        if onAccept then onAccept() end
        CloseActivePopup()
    end)
    cancelBtn:SetScript("OnClick", function()
        CloseActivePopup()
    end)
    Widgets.BindEscapeToClose(popup, CloseActivePopup)
    CS.Theme.ApplyFonts(popup)
    activePopup = popup
    return popup
end
function Widgets.CreateInputPopup(title, body, defaultText, onAccept, okText, cancelText)
    CloseActivePopup()
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetSize(320, 140)
    popup:SetPoint("CENTER")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    CS.Theme.Box(popup, "window", "border", (CS.Theme.Get()).windowRadius)
    local titleFs = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFs.themeRole = "heading"
    titleFs:SetPoint("TOPLEFT", 12, -12)
    titleFs:SetText(title or "")
    Widgets.ApplyFontColor(titleFs, "textPrimary")
    local bodyFs = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyFs:SetPoint("TOPLEFT", 12, -36)
    bodyFs:SetPoint("TOPRIGHT", -12, -36)
    bodyFs:SetJustifyH("LEFT")
    bodyFs:SetText(body or "")
    Widgets.ApplyFontColor(bodyFs, "textMuted")
    local editBox = CreateFrame("EditBox", nil, popup)
    editBox:SetSize(296, 24)
    editBox:SetPoint("TOPLEFT", 12, -60)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    CS.Theme.Box(editBox, "field", "border", Radius())
    local fieldText = Widgets.GetColor("text")
    editBox:SetTextColor(fieldText.r, fieldText.g, fieldText.b)
    editBox:SetTextInsets(6, 6, 0, 0)
    editBox:SetText(defaultText or "")
    local okBtn = Widgets.CreateFlatButton(popup, 80, 22, okText or "OK")
    okBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    local cancelBtn = Widgets.CreateFlatButton(popup, 80, 22, cancelText or "Cancel")
    cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -8, 0)
    local function DoAccept()
        local text = editBox:GetText():match("^%s*(.-)%s*$")
        if text == "" then return end
        if onAccept then
            local ok = onAccept(text)
            if ok == false then return end
        end
        CloseActivePopup()
    end
    okBtn:SetScript("OnClick", DoAccept)
    editBox:SetScript("OnEnterPressed", DoAccept)
    cancelBtn:SetScript("OnClick", function()
        CloseActivePopup()
    end)
    editBox:SetScript("OnEscapePressed", function()
        CloseActivePopup()
    end)
    Widgets.BindEscapeToClose(popup, CloseActivePopup)
    CS.Theme.ApplyFonts(popup)
    editBox:SetFocus()
    editBox:HighlightText()
    activePopup = popup
    return popup
end
function Widgets.CreateSelectPopup(title, body, items, defaultValue, onAccept, okText, cancelText)
    CloseActivePopup()
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetSize(320, 140)
    popup:SetPoint("CENTER")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    CS.Theme.Box(popup, "window", "border", (CS.Theme.Get()).windowRadius)
    local titleFs = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFs.themeRole = "heading"
    titleFs:SetPoint("TOPLEFT", 12, -12)
    titleFs:SetText(title or "")
    Widgets.ApplyFontColor(titleFs, "textPrimary")
    local bodyFs = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyFs:SetPoint("TOPLEFT", 12, -36)
    bodyFs:SetPoint("TOPRIGHT", -12, -36)
    bodyFs:SetJustifyH("LEFT")
    bodyFs:SetText(body or "")
    Widgets.ApplyFontColor(bodyFs, "textMuted")
    local _, dropdown = Widgets.CreateDropdown(popup, "", 200)
    dropdown:SetPoint("TOPLEFT", 12, -60)
    dropdown:SetItems(items or {})
    local displayText = defaultValue
    if items then
        for _, item in ipairs(items) do
            if item.value == defaultValue then
                displayText = item.text or defaultValue
                break
            end
        end
    end
    dropdown:SetValue(defaultValue, displayText)
    local okBtn = Widgets.CreateFlatButton(popup, 80, 22, okText or "OK")
    okBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    local cancelBtn = Widgets.CreateFlatButton(popup, 80, 22, cancelText or "Cancel")
    cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -8, 0)
    okBtn:SetScript("OnClick", function()
        local value = dropdown:GetValue()
        if onAccept then
            local ok = onAccept(value)
            if ok == false then return end
        end
        CloseActivePopup()
    end)
    cancelBtn:SetScript("OnClick", function()
        CloseActivePopup()
    end)
    Widgets.BindEscapeToClose(popup, CloseActivePopup)
    CS.Theme.ApplyFonts(popup)
    activePopup = popup
    return popup
end
return Widgets
