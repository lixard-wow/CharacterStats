local ADDON_NAME, ns = ...
local Theme = {}
ns.Theme = Theme
local function Hex(value, alpha)
    return { tonumber(value:sub(2, 3), 16) / 255, tonumber(value:sub(4, 5), 16) / 255, tonumber(value:sub(6, 7), 16) / 255, alpha or 1 }
end
local MEDIA = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\"
local FONTS = MEDIA .. "Fonts\\"
Theme.ART = MEDIA .. "Art\\"
local BARLOW = FONTS .. "Barlow-Regular.ttf"
local BARLOW_SEMI = FONTS .. "Barlow-SemiBold.ttf"
local BARLOW_COND = FONTS .. "BarlowCondensed-Bold.ttf"
local CINZEL = FONTS .. "Cinzel-Bold.ttf"
local SOURCE = FONTS .. "SourceSans3-Regular.ttf"
local SOURCE_BOLD = FONTS .. "SourceSans3-Bold.ttf"
local NON_LATIN = { ruRU = true, koKR = true, zhCN = true, zhTW = true }
local useGameFont = NON_LATIN[GetLocale()] == true
Theme.ORDER = { "workbench", "ledger", "classic" }
Theme.THEMES = {
    workbench = {
        nameKey = "THEME_WORKBENCH", fallbackName = "Workbench",
        descKey = "THEME_WORKBENCH_DESC", fallbackDesc = "Flat charcoal with a green accent.",
        fonts = { body = BARLOW, strong = BARLOW_SEMI, heading = BARLOW_SEMI, title = BARLOW_COND, button = BARLOW_SEMI },
        titleSize = 18, windowRadius = 10, buttonRadius = 4, sizeBoost = 2,
        uppercaseTitle = true, headerFill = true, stripe = true,
        colors = {
            window = Hex("#171a1f"), header = Hex("#1d2127"), nav = Hex("#14171b"), surface = Hex("#1d2127"),
            field = Hex("#121519"), hover = Hex("#262b32"), border = Hex("#2c323a"), line = Hex("#2c323a"),
            accent = Hex("#4fbf8f"), text = Hex("#e8ebee"), muted = Hex("#9aa3ad"), title = Hex("#e8ebee"), heading = Hex("#e8ebee"),
            button = Hex("#262b32"), buttonBorder = Hex("#2c323a"), buttonHover = Hex("#30363f"), buttonText = Hex("#e8ebee"),
            primary = Hex("#2f8f68"), primaryBorder = Hex("#2f8f68"), primaryHover = Hex("#36a377"), primaryText = Hex("#ffffff"),
            disabled = Hex("#5c646d"),
        },
    },
    ledger = {
        nameKey = "THEME_LEDGER", fallbackName = "Artisan Ledger",
        descKey = "THEME_LEDGER_DESC", fallbackDesc = "Walnut and brass with engraved headings.",
        fonts = { body = SOURCE, strong = SOURCE_BOLD, heading = CINZEL, title = CINZEL, button = SOURCE_BOLD },
        titleSize = 15, windowRadius = 4, buttonRadius = 4, sizeBoost = 2,
        innerFrame = true,
        colors = {
            window = Hex("#1c1611"), header = Hex("#1c1611"), nav = Hex("#18130f"), surface = Hex("#241c15"),
            field = Hex("#120e0b"), hover = Hex("#2e241b"), border = Hex("#5a4630"), line = Hex("#3a2e22"),
            accent = Hex("#c9a35a"), text = Hex("#efe6d6"), muted = Hex("#bfb19e"), title = Hex("#e9d9b4"), heading = Hex("#f3e6c8"),
            button = Hex("#241c15"), buttonBorder = Hex("#5a4630"), buttonHover = Hex("#2e241b"), buttonText = Hex("#e9d9b4"),
            primary = Hex("#c9a35a"), primaryBorder = Hex("#e2c07a"), primaryHover = Hex("#d6b06a"), primaryText = Hex("#1c1611"),
            disabled = Hex("#6b5d4e"),
        },
    },
    classic = {
        nameKey = "THEME_CLASSIC", fallbackName = "Lixard Classic",
        descKey = "THEME_CLASSIC_DESC", fallbackDesc = "The original CharacterStats look.",
        titleSize = 16, windowRadius = 0, buttonRadius = 0,
        headerFill = true,
        colors = {
            window = { 0.06, 0.06, 0.06, 0.98 }, header = { 0.08, 0.08, 0.08, 1 }, nav = { 0.045, 0.045, 0.045, 1 }, surface = { 0.07, 0.07, 0.07, 1 },
            field = { 0.10, 0.10, 0.10, 1 }, hover = { 0.12, 0.12, 0.12, 1 }, border = { 0.22, 0.22, 0.22, 1 }, line = { 0.28, 0.28, 0.28, 1 },
            accent = { 0.78, 0.66, 0.22, 1 }, text = { 0.92, 0.91, 0.86, 1 }, muted = { 0.70, 0.70, 0.70, 1 },
            title = { 0.92, 0.91, 0.86, 1 }, heading = { 0.92, 0.91, 0.86, 1 },
            button = { 0.12, 0.12, 0.12, 1 }, buttonBorder = { 0.22, 0.22, 0.22, 1 }, buttonHover = { 0.18, 0.18, 0.18, 1 }, buttonText = { 0.70, 0.70, 0.70, 1 },
            primary = { 0.12, 0.12, 0.12, 1 }, primaryBorder = { 0.78, 0.66, 0.22, 1 }, primaryHover = { 0.18, 0.18, 0.18, 1 }, primaryText = { 0.92, 0.91, 0.86, 1 },
            disabled = { 0.40, 0.40, 0.40, 1 },
        },
    },
}
function Theme.GetName(key)
    local def = Theme.THEMES[key]
    if not def then return key end
    return ns.L[def.nameKey] or def.fallbackName
end
function Theme.GetDescription(key)
    local def = Theme.THEMES[key]
    if not def then return "" end
    return ns.L[def.descKey] or def.fallbackDesc
end
function Theme.DefaultKey(freshInstall)
    if not freshInstall then return "classic" end
    if ns.BlizzardStats and ns.BlizzardStats.IsAvailable() then return "ledger" end
    return "workbench"
end
function Theme.Load()
    local db = ns.db
    local key = db and db.uiTheme
    if not Theme.THEMES[key] then key = "classic" end
    Theme.key = key
    Theme.T = Theme.THEMES[key]
    local C = {}
    for k, v in pairs(Theme.T.colors) do C[k] = v end
    if key == "classic" and ns.GetCurrentThemeColor then
        local r, g, b = ns.GetCurrentThemeColor()
        if r then
            C.accent = { r, g, b, 1 }
            C.primaryBorder = C.accent
        end
    end
    Theme.C = C
end
function Theme.Get()
    if not Theme.C then Theme.Load() end
    return Theme.T, Theme.C
end
local listeners = {}
function Theme.OnChange(fn)
    listeners[#listeners + 1] = fn
end
function Theme.Set(key)
    if not Theme.THEMES[key] or not ns.db then return end
    ns.db.uiTheme = key
    Theme.Load()
    for _, fn in ipairs(listeners) do
        local ok, err = pcall(fn, key)
        if not ok then
            geterrorhandler()(err)
        end
    end
end
function Theme.Cycle()
    local current = Theme.key or "classic"
    for i, key in ipairs(Theme.ORDER) do
        if key == current then
            Theme.Set(Theme.ORDER[i % #Theme.ORDER + 1])
            return
        end
    end
    Theme.Set(Theme.ORDER[1])
end
local pendingFonts = {}
local retrying = false
local function Redraw(fs)
    local text = fs:GetText()
    if text then
        fs:SetText("")
        fs:SetText(text)
    end
end
local function RetryFonts()
    retrying = false
    for fs, req in pairs(pendingFonts) do
        req.tries = req.tries + 1
        if fs:SetFont(req.file, req.size, req.flags) or req.tries > 10 then
            pendingFonts[fs] = nil
        end
        Redraw(fs)
    end
    if next(pendingFonts) then
        retrying = true
        C_Timer.After(0.3, RetryFonts)
    end
end
function Theme.SetFont(fs, file, size, flags)
    flags = flags or ""
    if not file or useGameFont then
        fs:SetFont(STANDARD_TEXT_FONT, size, flags)
        return
    end
    if fs:SetFont(file, size, flags) then
        pendingFonts[fs] = nil
        Redraw(fs)
        return
    end
    fs:SetFont(STANDARD_TEXT_FONT, size, flags)
    Redraw(fs)
    pendingFonts[fs] = { file = file, size = size, flags = flags, tries = 0 }
    if not retrying then
        retrying = true
        C_Timer.After(0.3, RetryFonts)
    end
end
function Theme.FontFor(role)
    local T = Theme.Get()
    return T.fonts and (T.fonts[role] or T.fonts.body) or nil
end
local function ApplyFontTo(fs, T)
    if not T.fonts then return end
    local _, size, flags = fs:GetFont()
    size = size or 12
    local role = fs.themeRole or "body"
    if role == "title" then
        size = T.titleSize or size
    elseif not fs.themeSized then
        fs.themeSized = true
        size = size + (T.sizeBoost or 0)
        fs.themeSize = size
    else
        size = fs.themeSize or size
    end
    Theme.SetFont(fs, T.fonts[role] or T.fonts.body, math.floor(size + 0.5), flags)
    if role == "title" and fs.rawTitle then
        fs:SetText(T.uppercaseTitle and fs.rawTitle:upper() or fs.rawTitle)
    end
end
function Theme.ApplyFonts(root)
    local T = Theme.Get()
    if not T.fonts or not root then return end
    for _, region in ipairs({ root:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "FontString" and not region.themeSkip then
            ApplyFontTo(region, T)
        end
    end
    for _, child in ipairs({ root:GetChildren() }) do
        Theme.ApplyFonts(child)
    end
end
function Theme.SetTitle(fs, text)
    fs.themeRole = "title"
    fs.rawTitle = text
    local T = Theme.Get()
    fs:SetText(T.uppercaseTitle and text:upper() or text)
end
function Theme.Shape(tex, radius)
    if radius and radius > 0 and tex.SetTextureSliceMargins then
        tex:SetTexture(Theme.ART .. "round" .. radius)
        tex:SetTextureSliceMargins(radius, radius, radius, radius)
        if Enum and Enum.UITextureSliceMode and tex.SetTextureSliceMode then
            tex:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    else
        if tex.SetTextureSliceMargins then
            tex:SetTextureSliceMargins(0, 0, 0, 0)
        end
        tex:SetColorTexture(1, 1, 1, 1)
    end
end
function Theme.Tint(tex, c, alpha)
    if not tex or not c then return end
    tex:SetVertexColor(c[1], c[2], c[3], alpha or c[4] or 1)
end
function Theme.Box(frame, fillKey, borderKey, radius, sublevel)
    local _, C = Theme.Get()
    local base = sublevel or 0
    local edge = frame:CreateTexture(nil, "BACKGROUND", nil, base - 2)
    edge:SetAllPoints()
    local fill = frame:CreateTexture(nil, "BACKGROUND", nil, base - 1)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    Theme.Shape(edge, radius)
    Theme.Shape(fill, radius)
    Theme.Tint(edge, C[borderKey or "border"])
    Theme.Tint(fill, C[fillKey or "window"])
    frame.edge, frame.fill = edge, fill
    return fill, edge
end
function Theme.CornerFill(frame, colorKey, radius, layer, sublevel)
    local _, C = Theme.Get()
    local c = C[colorKey]
    local textures = {}
    local function Square()
        local t = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
        t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        textures[#textures + 1] = t
        return t
    end
    if not radius or radius <= 0 then
        Square():SetAllPoints()
        return textures
    end
    local round = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    round:SetAllPoints()
    Theme.Shape(round, radius)
    Theme.Tint(round, c)
    textures[#textures + 1] = round
    local upper = Square()
    upper:SetPoint("TOPLEFT")
    upper:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, radius)
    local lower = Square()
    lower:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", radius, 0)
    lower:SetPoint("BOTTOMRIGHT")
    lower:SetHeight(radius)
    return textures
end
function Theme.Window(frame, headerHeight, noRing)
    local T, C = Theme.Get()
    Theme.Box(frame, "window", "border", T.windowRadius)
    if T.headerFill then
        local header = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        header:SetPoint("TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", -1, -1)
        header:SetHeight(headerHeight - 1)
        Theme.Shape(header, T.windowRadius)
        Theme.Tint(header, C.header)
        local square = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        square:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
        square:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
        square:SetHeight(math.min(headerHeight - 1, T.windowRadius or 0))
        square:SetColorTexture(C.header[1], C.header[2], C.header[3], 1)
    end
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetPoint("TOPLEFT", 1, -headerHeight)
    line:SetPoint("TOPRIGHT", -1, -headerHeight)
    line:SetHeight(1)
    line:SetColorTexture(C.line[1], C.line[2], C.line[3], 1)
    if T.stripe then
        local stripe = frame:CreateTexture(nil, "BORDER", nil, 1)
        stripe:SetPoint("TOPLEFT", 1, -headerHeight)
        stripe:SetSize(48, 2)
        stripe:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    if T.innerFrame and not noRing then
        local ring = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
        ring:SetPoint("TOPLEFT", 4, -4)
        ring:SetPoint("BOTTOMRIGHT", -4, 4)
        Theme.Shape(ring, T.windowRadius)
        Theme.Tint(ring, C.line)
        local ringFill = frame:CreateTexture(nil, "BACKGROUND", nil, 3)
        ringFill:SetPoint("TOPLEFT", ring, 1, -1)
        ringFill:SetPoint("BOTTOMRIGHT", ring, -1, 1)
        Theme.Shape(ringFill, T.windowRadius)
        Theme.Tint(ringFill, C.window)
    end
    frame.headerLine = line
end
function Theme.CloseButton(parent, size)
    local _, C = Theme.Get()
    local T = Theme.T
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    local fill = Theme.Box(button, "button", "buttonBorder", T.buttonRadius)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(Theme.ART .. "icon_close")
    icon:SetSize(math.floor(size * 0.5 + 0.5), math.floor(size * 0.5 + 0.5))
    icon:SetPoint("CENTER")
    Theme.Tint(icon, C.muted)
    button:SetScript("OnEnter", function()
        Theme.Tint(fill, Theme.C.buttonHover)
        Theme.Tint(icon, Theme.C.text)
    end)
    button:SetScript("OnLeave", function()
        Theme.Tint(fill, Theme.C.button)
        Theme.Tint(icon, Theme.C.muted)
    end)
    return button
end
