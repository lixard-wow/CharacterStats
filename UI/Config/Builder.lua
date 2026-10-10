local addonName, CS = ...
local Builder = {}
CS.ConfigBuilder = Builder
local ROW_GAP = 4
local SECTION_GAP = 14
local ROW_HEIGHTS = {
    header = 18,
    slider = 22,
    dropdown = 22,
    toggle = 20,
    color = 20,
}
local DISABLED_TEXT = { r = 0.4, g = 0.4, b = 0.4 }
local function GetDB()
    return CS.db or CS.DEFAULTS
end
local function ReadValue(entry, db)
    if entry.get then
        return entry.get(db)
    end
    local value = db[entry.key]
    if value == nil then
        value = entry.default
        if value == nil and CS.DEFAULTS then
            value = CS.DEFAULTS[entry.key]
        end
    end
    return value
end
local function WriteValue(entry, value)
    local db = CS.db
    if not db then return end
    if entry.set then
        entry.set(db, value)
    else
        db[entry.key] = value
    end
end
local function ResolveItems(entry)
    if type(entry.items) == "function" then
        return entry.items()
    end
    return entry.items or {}
end
local function TextForValue(items, value)
    for _, item in ipairs(items) do
        if item.value == value then
            return item.text
        end
    end
    return value ~= nil and tostring(value) or ""
end
local function SetLabelEnabled(label, enabled)
    if not label then return end
    if enabled then
        CS.ConfigWidgets.ApplyFontColor(label, "textMuted")
    else
        label:SetTextColor(DISABLED_TEXT.r, DISABLED_TEXT.g, DISABLED_TEXT.b)
    end
end
local function CreateRowLabel(row, text)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetPoint("RIGHT", row, "CENTER", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    CS.ConfigWidgets.ApplyFontColor(label, "textMuted")
    return label
end
local function BuildControl(page, entry, row)
    local Widgets = CS.ConfigWidgets
    local control = { entry = entry, row = row }
    local kind = entry.kind
    if kind == "header" then
        control.header = Widgets.CreateSectionHeader(row, entry.label)
        control.header:SetAllPoints(row)
    elseif kind == "toggle" then
        local toggle = Widgets.CreateToggle(row, entry.label)
        toggle:SetPoint("LEFT", row, "LEFT", 0, 0)
        toggle:SetOnClick(function(self)
            WriteValue(entry, self:GetChecked())
            page:OnValueChanged(entry, self:GetChecked())
        end)
        control.toggle = toggle
    elseif kind == "slider" then
        control.label = CreateRowLabel(row, entry.label)
        local slider = Widgets.CreateSlider(row, {
            min = entry.min,
            max = entry.max,
            step = entry.step,
            format = entry.format,
            formatValue = entry.formatValue,
            value = entry.min,
            commitOnRelease = entry.commitOnRelease,
            onChange = function(val)
                WriteValue(entry, val)
                page:OnValueChanged(entry, val)
            end,
        })
        slider:ClearAllPoints()
        slider:SetPoint("LEFT", row, "CENTER", 8, 0)
        slider:SetPoint("RIGHT", row, "RIGHT", -48, 0)
        slider:SetHeight(12)
        slider.track:ClearAllPoints()
        slider.track:SetPoint("LEFT", slider, "LEFT", 0, 0)
        slider.track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
        slider.valueText:ClearAllPoints()
        slider.valueText:SetPoint("LEFT", slider.track, "RIGHT", 8, 0)
        slider.valueText:SetWidth(40)
        slider.valueText:SetJustifyH("LEFT")
        control.slider = slider
    elseif kind == "dropdown" then
        control.label = CreateRowLabel(row, entry.label)
        local _, dropdown = Widgets.CreateDropdown(row, "", 150, { fixedWidth = true })
        dropdown:ClearAllPoints()
        dropdown:SetPoint("LEFT", row, "CENTER", 8, 0)
        dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        dropdown:SetHeight(ROW_HEIGHTS.dropdown)
        dropdown:SetItems(ResolveItems(entry))
        dropdown:SetOnChange(function(value)
            WriteValue(entry, value)
            page:OnValueChanged(entry, value)
        end)
        control.dropdown = dropdown
    elseif kind == "color" then
        control.label = CreateRowLabel(row, entry.label)
        local swatch = Widgets.CreateSwatch(row)
        swatch:SetPoint("LEFT", row, "CENTER", 8, 0)
        swatch:SetScript("OnClick", function()
            local db = GetDB()
            local c = ReadValue(entry, db) or { r = 1, g = 1, b = 1 }
            Widgets.OpenColorPicker(c.r or 1, c.g or 1, c.b or 1, function(r, g, b)
                WriteValue(entry, { r = r, g = g, b = b })
                page:OnValueChanged(entry)
            end, function(r, g, b)
                WriteValue(entry, { r = r, g = g, b = b })
                page:OnValueChanged(entry)
            end)
        end)
        control.swatch = swatch
    end
    return control
end
local function RefreshControl(control, db)
    local entry = control.entry
    if entry.kind == "header" then return end
    local value = ReadValue(entry, db)
    local enabled = not (entry.disabled and entry.disabled(db))
    if control.toggle then
        control.toggle:SetChecked(value == true)
        control.toggle:EnableMouse(enabled)
        SetLabelEnabled(control.toggle.text, enabled)
        control.toggle:SetAlpha(enabled and 1 or 0.6)
    elseif control.slider then
        control.slider:SetValue(value, false)
        control.slider.hit:EnableMouse(enabled)
        control.slider:SetAlpha(enabled and 1 or 0.4)
        SetLabelEnabled(control.label, enabled)
    elseif control.dropdown then
        local items = ResolveItems(entry)
        if entry.dynamicItems then
            control.dropdown:SetItems(items)
        end
        control.dropdown:SetValue(value, TextForValue(items, value))
        if enabled then
            control.dropdown:Enable()
        else
            control.dropdown:Disable()
        end
        SetLabelEnabled(control.label, enabled)
    elseif control.swatch then
        local r, g, b, a
        if entry.displayColor then
            r, g, b, a = entry.displayColor(db)
        end
        if not r then
            local c = value or { r = 1, g = 1, b = 1 }
            r, g, b, a = c.r, c.g, c.b, 1
        end
        control.swatch:SetColor(r, g, b, a)
        control.swatch:SetDisabled(not enabled)
        SetLabelEnabled(control.label, enabled)
    end
end
function Builder.Build(parent, entries, opts)
    opts = opts or {}
    local page = {
        controls = {},
        onChange = opts.onChange,
    }
    local y = -(opts.topPadding or 4)
    local leftToggleRowY = nil
    local first = true
    for _, entry in ipairs(entries) do
        if not entry.retailOnly or CS.IS_RETAIL then
            local kind = entry.kind
            local height = ROW_HEIGHTS[kind] or 20
            local row = CreateFrame("Frame", nil, parent)
            local placedRight = false
            if kind == "toggle" and leftToggleRowY and not entry.fullRow then
                row:SetPoint("TOPLEFT", parent, "TOP", 8, leftToggleRowY)
                row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, leftToggleRowY)
                leftToggleRowY = nil
                placedRight = true
            else
                if kind == "header" and not first then
                    y = y - (SECTION_GAP - ROW_GAP)
                end
                row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
                if kind == "toggle" and not entry.fullRow then
                    row:SetPoint("TOPRIGHT", parent, "TOP", -8, y)
                    leftToggleRowY = y
                else
                    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
                    leftToggleRowY = nil
                end
            end
            row:SetHeight(height)
            if not placedRight then
                y = y - height - ROW_GAP
            end
            first = false
            page.controls[#page.controls + 1] = BuildControl(page, entry, row)
        end
    end
    page.height = math.abs(y) + 8
    function page:Refresh()
        local db = GetDB()
        for _, control in ipairs(self.controls) do
            RefreshControl(control, db)
        end
    end
    function page:OnValueChanged(entry, value)
        local themeBefore = CS.Theme.key
        if entry.onChange then
            entry.onChange(value)
        elseif self.onChange then
            self.onChange(entry, value)
        end
        if CS.Theme.key == themeBefore then
            self:Refresh()
        end
    end
    return page
end
return Builder
