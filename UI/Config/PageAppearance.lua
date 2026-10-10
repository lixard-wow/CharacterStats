local addonName, CS = ...
local ConfigPanel = CS.ConfigPanel
local function FormatPercentValue(v)
    return string.format("%.0f%%", v * 100)
end
local function BuildFontItems(L)
    local items = { { value = "default", text = L.FONT_DEFAULT or "Default" } }
    local LSM = CS.GetLSM and CS.GetLSM()
    if LSM then
        for _, fontName in ipairs(LSM:List("font")) do
            items[#items + 1] = { value = fontName, text = fontName }
        end
    else
        items[#items + 1] = { value = "Fonts\\ARIALN.TTF", text = L.FONT_ARIAL or "Arial Narrow" }
        items[#items + 1] = { value = "Fonts\\skurri.ttf", text = L.FONT_SKURRI or "Skurri" }
        items[#items + 1] = { value = "Fonts\\MORPHEUS.TTF", text = L.FONT_MORPHEUS or "Morpheus" }
    end
    return items
end
local function IsHorizontal(db)
    return db.orientation == "horizontal"
end
local function IsLedger()
    local id = CS.Styles.GetActive().id
    return id == "ledger" or id == "original"
end
local function BuildStyleItems()
    local items = {}
    for _, style in ipairs(CS.Styles.List()) do
        items[#items + 1] = { value = style.id, text = CS.Styles.Label(style) }
    end
    return items
end
local function BuildEntries(L)
    local fontItems
    return {
        { kind = "header", label = L.SECTION_STYLE or "Style" },
        {
            kind = "dropdown", key = "style", label = L.LABEL_STYLE or "Look",
            items = BuildStyleItems,
            get = function() return CS.Styles.GetActive().id end,
            onChange = ConfigPanel.ApplyStyleChange,
        },
        { kind = "header", label = L.SECTION_TEXT or "Text" },
        {
            kind = "dropdown", key = "fontFace", label = L.LABEL_FONT_FACE or "Font",
            items = function()
                fontItems = fontItems or BuildFontItems(L)
                return fontItems
            end,
        },
        { kind = "slider", key = "fontSize", label = L.LABEL_FONT_SIZE or "Font Size", min = 4, max = 16, step = 1, format = "%.0f" },
        {
            kind = "slider", key = "textAlpha", label = L.LABEL_TEXT_OPACITY or "Text Opacity",
            min = 0, max = 1, step = 0.05, formatValue = FormatPercentValue,
        },
        {
            kind = "toggle", key = "fontOutline", label = L.LABEL_OUTLINE or "Font Outline",
            get = function(db) return db.fontOutline == "OUTLINE" end,
            set = function(db, value) db.fontOutline = value and "OUTLINE" or "" end,
        },
        { kind = "toggle", key = "useShortNames", label = L.LABEL_SHORT_NAMES or "Use Abbreviated Names" },
        { kind = "toggle", key = "showColon", label = L.LABEL_SHOW_COLON or "Show Colon After Label" },
        { kind = "header", label = L.SECTION_LAYOUT or "Layout" },
        {
            kind = "dropdown", key = "orientation", label = L.LABEL_ORIENTATION or "Layout Direction",
            items = {
                { value = "vertical", text = L.ORIENT_VERTICAL or "Vertical" },
                { value = "horizontal", text = L.ORIENT_HORIZONTAL or "Horizontal" },
            },
        },
        {
            kind = "dropdown", key = "alignMode", label = L.LABEL_ALIGNMENT or "Alignment",
            items = {
                { value = "left", text = L.ALIGN_LEFT or "Left" },
                { value = "center", text = L.ALIGN_CENTER or "Center" },
                { value = "right", text = L.ALIGN_RIGHT or "Right" },
                { value = "justify", text = L.ALIGN_JUSTIFY or "Justify" },
            },
            disabled = function(db) return IsHorizontal(db) or not IsLedger(db) end,
        },
        {
            kind = "toggle", key = "groupedLayout", label = L.LABEL_GROUPED_LAYOUT or "Group Stats Under Headers", fullRow = true,
            disabled = function(db)
                local id = CS.Styles.GetActive().id
                return IsHorizontal(db) or (id ~= "ledger" and id ~= "meters")
            end,
        },
        {
            kind = "slider", key = "rowPadding", label = L.LABEL_ROW_SPACING or "Row Spacing",
            min = -3, max = 3, step = 1,
            formatValue = function(v) return string.format("%.0f %s", v, L.UNIT_PX or "px") end,
        },
        {
            kind = "slider", key = "statBarHeight", label = L.LABEL_BAR_HEIGHT or "Bar Thickness",
            min = 1, max = 12, step = 1,
            formatValue = function(v) return string.format("%.0f %s", v, L.UNIT_PX or "px") end,
            disabled = function() return CS.Styles.GetActive().id ~= "meters" end,
        },
        {
            kind = "toggle", key = "showDiminishing", label = L.LABEL_SHOW_DIMINISHING or "Show Diminishing Returns on Bars", fullRow = true,
            retailOnly = true,
            disabled = function() return CS.Styles.GetActive().id ~= "meters" end,
            onChange = function()
                ConfigPanel.RefreshStatsFrame()
                if CS.PaperdollPanel then CS.PaperdollPanel:Refresh() end
            end,
        },
        {
            kind = "toggle", key = "showSeparator", label = L.LABEL_SHOW_SEPARATOR or "Show Separator (Horizontal)", fullRow = true,
            disabled = function(db) return not IsHorizontal(db) or not IsLedger(db) end,
        },
        {
            kind = "color", key = "separatorColor", label = L.LABEL_SEPARATOR_COLOR or "Separator Color",
            disabled = function(db) return not IsHorizontal(db) or not IsLedger(db) or not db.showSeparator end,
        },
        { kind = "header", label = L.SECTION_BACKGROUND or "Background & Border" },
        {
            kind = "slider", key = "bgAlpha", label = L.LABEL_BG_OPACITY or "Background Opacity",
            min = 0, max = 1, step = 0.05, formatValue = FormatPercentValue,
        },
        {
            kind = "dropdown", key = "borderStyle", label = L.LABEL_BORDER_STYLE or "Border Style",
            items = {
                { value = "none", text = L.BORDER_NONE or "None" },
                { value = "thin", text = L.BORDER_THIN or "Thin" },
                { value = "thick", text = L.BORDER_THICK or "Thick" },
                { value = "tooltip", text = L.BORDER_TOOLTIP or "Tooltip" },
                { value = "dialog", text = L.BORDER_DIALOG or "Dialog" },
            },
        },
        {
            kind = "slider", key = "borderAlpha", label = L.LABEL_BORDER_OPACITY or "Border Opacity",
            min = 0, max = 1, step = 0.05, formatValue = FormatPercentValue,
            disabled = function(db) return db.borderStyle == "none" end,
        },
        {
            kind = "toggle", key = "borderUseClassColor", label = L.LABEL_CLASS_COLOR or "Use Class Color for Border", fullRow = true,
            disabled = function(db) return db.borderStyle == "none" end,
        },
        {
            kind = "color", key = "borderColor", label = L.LABEL_BORDER_COLOR or "Border Color",
            disabled = function(db) return db.borderStyle == "none" or db.borderUseClassColor == true end,
            displayColor = function(db)
                if db.borderUseClassColor then
                    local r, g, b = ConfigPanel.ResolveCurrentClassColor()
                    if r then return r, g, b, 0.85 end
                end
            end,
        },
    }
end
ConfigPanel.RegisterPage("appearance", {
    label = CS.L.NAV_APPEARANCE or "Appearance",
    labelKey = "NAV_APPEARANCE",
    order = 3,
    create = function(container)
        local _, content = ConfigPanel.CreateScrollPage(container)
        local page = CS.ConfigBuilder.Build(content, BuildEntries(CS.L), {
            onChange = ConfigPanel.RefreshStatsFrame,
        })
        content:SetHeight(page.height)
        return page
    end,
})
