local ADDON_NAME, ns = ...
local LocalePicker = {}
ns.LocalePicker = LocalePicker
local ipairs = ipairs
local LANGUAGES = {
    { code = "enUS", name = "English" },
    { code = "deDE", name = "Deutsch" },
    { code = "esES", name = "Español (España)" },
    { code = "esMX", name = "Español (México)" },
    { code = "frFR", name = "Français" },
    { code = "itIT", name = "Italiano" },
    { code = "ptBR", name = "Português (Brasil)" },
    { code = "ruRU", name = "Русский" },
    { code = "koKR", name = "한국어" },
    { code = "zhCN", name = "简体中文" },
    { code = "zhTW", name = "繁體中文" },
}
local HEADER_HEIGHT = 40
local PAD = 16
local BUTTON_WIDTH = 170
local BUTTON_HEIGHT = 24
local GAP = 6
local frame
local buttons = {}
local function Choose(code)
    if not CharacterStatsDB then return end
    if code == nil or code == ns.GAME_LOCALE then
        CharacterStatsDB.localeOverride = nil
    else
        CharacterStatsDB.localeOverride = code
    end
    ReloadUI()
end
local function UpdateButtons()
    local Widgets = ns.ConfigWidgets
    local active = ns.ACTIVE_LOCALE or ns.GAME_LOCALE
    for _, button in ipairs(buttons) do
        local selected
        if button.code == nil then
            selected = active == ns.GAME_LOCALE
        else
            selected = button.code == active and active ~= ns.GAME_LOCALE
        end
        if selected then
            Widgets.SetBorderColor(button, "accentGold", 1)
            Widgets.ApplyFontColor(button.text, "accentGold")
        else
            Widgets.SetBorderColor(button, "buttonBorder", 1)
            Widgets.ApplyFontColor(button.text, "buttonText")
        end
    end
end
local function Create()
    if frame and frame.themeKey == ns.Theme.key then return frame end
    if frame then frame:Hide() end
    local Widgets = ns.ConfigWidgets
    local L = ns.L
    wipe(buttons)
    frame = CreateFrame("Frame", "CharacterStatsLocalePicker", UIParent)
    frame.themeKey = ns.Theme.key
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    ns.Theme.Window(frame, HEADER_HEIGHT)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", frame, "TOPLEFT", PAD, -HEADER_HEIGHT / 2)
    ns.Theme.SetTitle(title, L.LOCALE_TITLE or "Addon Language")
    Widgets.ApplyFontColor(title, "title")
    local close = ns.Theme.CloseButton(frame, 22)
    close:SetPoint("RIGHT", frame, "TOPRIGHT", -10, -HEADER_HEIGHT / 2)
    close:SetScript("OnClick", function() frame:Hide() end)
    local width = PAD * 2 + BUTTON_WIDTH * 2 + GAP
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(HEADER_HEIGHT + 12))
    hint:SetWidth(width - PAD * 2)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.LOCALE_HINT or "For testing translations. Picking a language reloads the UI. Blizzard's own text stays in your game language, and Korean and Chinese need a game client in that language to show their letters.")
    Widgets.ApplyFontColor(hint, "textMuted")
    local top = HEADER_HEIGHT + 12 + math.ceil(hint:GetStringHeight() or 0) + 12
    local gameButton = Widgets.CreateFlatButton(frame, width - PAD * 2, BUTTON_HEIGHT, string.format("%s (%s)", L.LOCALE_GAME or "Game language", ns.GAME_LOCALE or "?"))
    gameButton:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -top)
    gameButton:SetScript("OnClick", function() Choose(nil) end)
    buttons[#buttons + 1] = gameButton
    top = top + BUTTON_HEIGHT + GAP * 2
    for index, language in ipairs(LANGUAGES) do
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        local button = Widgets.CreateFlatButton(frame, BUTTON_WIDTH, BUTTON_HEIGHT, string.format("%s  (%s)", language.name, language.code))
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + column * (BUTTON_WIDTH + GAP), -(top + row * (BUTTON_HEIGHT + GAP)))
        button.code = language.code
        button.text.themeSkip = true
        button:SetScript("OnClick", function() Choose(language.code) end)
        buttons[#buttons + 1] = button
    end
    local rows = math.ceil(#LANGUAGES / 2)
    frame:SetSize(width, top + rows * (BUTTON_HEIGHT + GAP) - GAP + PAD)
    Widgets.BindEscapeToClose(frame, function(self) self:Hide() end)
    ns.Theme.ApplyFonts(frame)
    frame:Hide()
    return frame
end
LocalePicker.Choose = Choose
function LocalePicker.Items()
    local items = { { value = "game", text = string.format("%s (%s)", ns.L.LOCALE_GAME or "Game language", ns.GAME_LOCALE or "?") } }
    for _, language in ipairs(LANGUAGES) do
        items[#items + 1] = { value = language.code, text = string.format("%s (%s)", language.name, language.code) }
    end
    return items
end
function LocalePicker.Show()
    Create()
    UpdateButtons()
    frame:Show()
end
function LocalePicker.Toggle()
    if frame and frame:IsShown() then
        frame:Hide()
    else
        LocalePicker.Show()
    end
end
