local ADDON_NAME, ns = ...
local Integrations = {}
ns.Integrations = Integrations
local FULL = "full"
local STATS = "stats"
local SLOTS = "slots"
local FEATURES = {
    [FULL] = { "paperdollEnabled", "gearBadges", "gearUpgrade", "gearFlags", "gearDetails", "characterButton" },
    [STATS] = { "paperdollEnabled" },
    [SLOTS] = { "gearBadges", "gearUpgrade", "gearFlags", "gearDetails" },
}
local function IsLoaded(name)
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or rawget(_G, "IsAddOnLoaded")
    if not isLoaded then return false end
    local ok, loaded = pcall(isLoaded, name)
    return ok and loaded == true
end
local function Walk(root, ...)
    local node = root
    for i = 1, select("#", ...) do
        if type(node) ~= "table" then return nil end
        node = node[select(i, ...)]
    end
    return node
end
local function ElvUIEngine()
    local elv = rawget(_G, "ElvUI")
    return type(elv) == "table" and elv[1] or nil
end
local function EllesmereSheetActive()
    if not IsLoaded("EllesmereUIBlizzardSkin") then return false end
    local db = rawget(_G, "EllesmereUIDB")
    if type(db) ~= "table" or db.themedCharacterSheet == false then return false end
    local profile = Walk(db, "profiles", db.activeProfile or "Default")
    return not (type(profile) == "table" and profile.disableWindowSkins)
end
local function Loaded(folder)
    return function() return IsLoaded(folder) end
end
local RULES = {
    { id = "chonky", name = "ChonkyCharacterSheet", kind = FULL, folder = "ChonkyCharacterSheet", active = Loaded("ChonkyCharacterSheet") },
    {
        id = "gw2", name = "GW2 UI", kind = FULL, folder = "GW2_UI", wholeUI = true,
        active = function()
            if not IsLoaded("GW2_UI") then return false end
            return Walk(rawget(_G, "GW2_ADDON"), "settings", "windows", "character", "enabled") ~= false
        end,
    },
    { id = "ellesmere", name = "EllesmereUI Blizzard Skin", kind = FULL, folder = "EllesmereUIBlizzardSkin", active = EllesmereSheetActive },
    { id = "deja", name = "DejaCharacterStats", kind = STATS, folder = "DejaCharacterStats", active = Loaded("DejaCharacterStats") },
    { id = "deja_slots", name = "DejaCharacterStats", kind = SLOTS, folder = "DejaCharacterStats", active = Loaded("DejaCharacterStats") },
    { id = "ahj", name = "AhjCharacterPanel", kind = STATS, folder = "AhjCharacterPanel", active = Loaded("AhjCharacterPanel") },
    { id = "ahj_slots", name = "AhjCharacterPanel", kind = SLOTS, folder = "AhjCharacterPanel", active = Loaded("AhjCharacterPanel") },
    {
        id = "sle_stats", name = "Shadow & Light", kind = STATS, folder = "ElvUI_SLE",
        active = function()
            return IsLoaded("ElvUI_SLE") and Walk(ElvUIEngine(), "private", "sle", "armory", "stats", "enable") == true
        end,
    },
    {
        id = "sle_slots", name = "Shadow & Light", kind = SLOTS, folder = "ElvUI_SLE",
        active = function()
            return IsLoaded("ElvUI_SLE") and Walk(ElvUIEngine(), "db", "sle", "armory", "character", "enable") == true
        end,
    },
    {
        id = "ndui_stats", name = "NDui", kind = STATS, folder = "NDui", wholeUI = true,
        active = function()
            return IsLoaded("NDui") and Walk(rawget(_G, "NDui"), 2, "db", "Misc", "MissingStats") ~= false
        end,
    },
    {
        id = "ndui_slots", name = "NDui", kind = SLOTS, folder = "NDui", wholeUI = true,
        active = function()
            if not IsLoaded("NDui") then return false end
            local misc = Walk(rawget(_G, "NDui"), 2, "db", "Misc")
            return type(misc) ~= "table" or misc.ItemLevel ~= false or misc.GemNEnchant ~= false
        end,
    },
    {
        id = "elvui_slots", name = "ElvUI", kind = SLOTS, folder = "ElvUI", wholeUI = true,
        active = function()
            return IsLoaded("ElvUI") and Walk(ElvUIEngine(), "db", "general", "itemLevel", "displayCharacterInfo") == true
        end,
    },
    {
        id = "sil", name = "SimpleItemLevel", kind = SLOTS, folder = "SimpleItemLevel",
        active = function()
            return IsLoaded("SimpleItemLevel") and Walk(rawget(_G, "SimpleItemLevelDB"), "character") ~= false
        end,
    },
    { id = "bcp", name = "BetterCharacterPanel", kind = SLOTS, folder = "BetterCharacterPanel", active = Loaded("BetterCharacterPanel") },
    {
        id = "tinyinspect", name = "TinyInspect", kind = SLOTS, folder = "TinyInspect",
        active = function()
            return IsLoaded("TinyInspect") and Walk(rawget(_G, "TinyInspectDB"), "EnableItemLevel") ~= false
        end,
    },
    { id = "tinyinspect_remake", name = "TinyInspect-Remake", kind = SLOTS, folder = "TinyInspect-Remake", active = Loaded("TinyInspect-Remake") },
    {
        id = "kkthnx_slots", name = "KkthnxUI", kind = SLOTS, folder = "KkthnxUI", wholeUI = true,
        active = function()
            return IsLoaded("KkthnxUI") and Walk(rawget(_G, "KkthnxUI"), 2, "Skins", "GearInfo") ~= false
        end,
    },
}
local function Enabled()
    local db = ns.db
    return not db or db.yieldToOtherAddons ~= false
end
local function IsIgnored(rule)
    local ignored = ns.db and ns.db.conflictsIgnored
    return type(ignored) == "table" and ignored[rule.id] == true
end
local function IsRuleActive(rule)
    local ok, active = pcall(rule.active)
    return ok and active == true
end
local function OursEnabled(kind)
    local db = ns.db
    if not db then return false end
    for _, key in ipairs(FEATURES[kind]) do
        if db[key] ~= false then
            return true
        end
    end
    return false
end
local function AnyBlocking(kind)
    for _, rule in ipairs(RULES) do
        if rule.kind == kind and not IsIgnored(rule) and IsRuleActive(rule) then
            return true
        end
    end
    return false
end
function Integrations.CharacterFrameTaken()
    if not Enabled() then return false end
    return AnyBlocking(FULL)
end
function Integrations.StatsPaneTaken()
    if not Enabled() then return false end
    return AnyBlocking(FULL) or AnyBlocking(STATS)
end
function Integrations.SlotInfoTaken()
    if not Enabled() then return false end
    return AnyBlocking(FULL) or AnyBlocking(SLOTS)
end
function Integrations.Describe()
    local found = {}
    for _, rule in ipairs(RULES) do
        if IsRuleActive(rule) then
            found[#found + 1] = rule
        end
    end
    return found
end
function Integrations.IsIgnored(rule)
    return IsIgnored(rule)
end
function Integrations.GetConflicts()
    local conflicts = {}
    if not Enabled() then return conflicts end
    for _, rule in ipairs(RULES) do
        if not IsIgnored(rule) and OursEnabled(rule.kind) and IsRuleActive(rule) then
            conflicts[#conflicts + 1] = rule
        end
    end
    return conflicts
end
function Integrations.KindLabel(kind)
    local L = ns.L
    if kind == FULL then return L.CONFLICT_FULL or "character window" end
    if kind == STATS then return L.CONFLICT_STATS or "stat list" end
    return L.CONFLICT_SLOTS or "gear slot info"
end
function Integrations.ResetIgnored()
    if ns.db then
        ns.db.conflictsIgnored = nil
    end
end
local function RefreshCharacterFrame()
    if ns.PaperdollPanel then ns.PaperdollPanel:ApplyStyle() end
    if ns.GearBadges then ns.GearBadges.Apply() end
    if ns.CharacterButton then ns.CharacterButton.Apply() end
    if ns.CharacterWidth then ns.CharacterWidth.Apply() end
end
local function TurnOffOurs(conflicts)
    local db = ns.db
    if not db then return end
    for _, rule in ipairs(conflicts) do
        for _, key in ipairs(FEATURES[rule.kind]) do
            db[key] = false
        end
    end
    if ns.FlushProfileSave then ns.FlushProfileSave() end
    ReloadUI()
end
local function DisableTheirs(conflicts)
    local disable = (C_AddOns and C_AddOns.DisableAddOn) or rawget(_G, "DisableAddOn")
    if not disable then return end
    local character = UnitName("player")
    local done = {}
    for _, rule in ipairs(conflicts) do
        if rule.folder and not done[rule.folder] then
            done[rule.folder] = true
            pcall(disable, rule.folder, character)
        end
    end
    ReloadUI()
end
local function KeepBoth(conflicts)
    local db = ns.db
    if not db then return end
    db.conflictsIgnored = db.conflictsIgnored or {}
    for _, rule in ipairs(conflicts) do
        db.conflictsIgnored[rule.id] = true
    end
    RefreshCharacterFrame()
end
local popup
local POPUP_HEADER = 40
local function CreatePopup()
    if popup and popup.themeKey == ns.Theme.key then return popup end
    if popup then popup:Hide() end
    local Widgets = ns.ConfigWidgets
    popup = CreateFrame("Frame", "CharacterStatsConflictPopup", UIParent)
    popup.themeKey = ns.Theme.key
    popup:SetSize(460, 220)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    ns.Theme.Window(popup, POPUP_HEADER)
    popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    popup.title:SetPoint("LEFT", popup, "TOPLEFT", 16, -POPUP_HEADER / 2)
    popup.title.themeRole = "title"
    Widgets.ApplyFontColor(popup.title, "title")
    popup.body = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.body:SetPoint("TOPLEFT", popup, "TOPLEFT", 16, -(POPUP_HEADER + 12))
    popup.body:SetPoint("RIGHT", popup, "RIGHT", -16, 0)
    popup.body:SetJustifyH("LEFT")
    popup.body:SetSpacing(2)
    Widgets.ApplyFontColor(popup.body, "textMuted")
    popup.oursButton = Widgets.CreateFlatButton(popup, 140, 24, "")
    popup.theirsButton = Widgets.CreateFlatButton(popup, 140, 24, "")
    popup.keepButton = Widgets.CreateFlatButton(popup, 100, 24, "")
    Widgets.BindEscapeToClose(popup, function(self) self:Hide() end)
    popup:Hide()
    return popup
end
function Integrations.ShowConflictPopup(conflicts)
    conflicts = conflicts or Integrations.GetConflicts()
    if #conflicts == 0 then return false end
    local L = ns.L
    local frame = CreatePopup()
    ns.Theme.SetTitle(frame.title, L.CONFLICT_TITLE or "Character frame conflict")
    local lines = { L.CONFLICT_INTRO or "These addons also change the character frame. Using both can overlap or break the layout, so one of them should be turned off:" }
    local names, seen, wholeUINames = {}, {}, {}
    for _, rule in ipairs(conflicts) do
        lines[#lines + 1] = string.format(L.CONFLICT_LINE or "  - %s also handles the %s", rule.name, Integrations.KindLabel(rule.kind))
        if rule.folder and not seen[rule.folder] then
            seen[rule.folder] = true
            names[#names + 1] = rule.name
            if rule.wholeUI then
                wholeUINames[#wholeUINames + 1] = rule.name
            end
        end
    end
    if #wholeUINames > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format(L.CONFLICT_WHOLE_UI_HINT or "Disabling %s turns off that entire UI. To keep it, turn off just this feature in its own settings instead.", table.concat(wholeUINames, ", "))
    end
    frame.body:SetText(table.concat(lines, "\n"))
    local Widgets = ns.ConfigWidgets
    frame.oursButton:SetText(L.CONFLICT_TURN_OFF_OURS or "Turn Off CharacterStats' Part & Reload")
    frame.theirsButton:SetText(string.format(L.CONFLICT_DISABLE_THEIRS or "Disable %s & Reload", table.concat(names, ", ")))
    frame.keepButton:SetText(L.CONFLICT_KEEP_BOTH or "Keep Both")
    local buttons = { frame.oursButton }
    if #names > 0 then
        buttons[#buttons + 1] = frame.theirsButton
        frame.theirsButton:Show()
    else
        frame.theirsButton:Hide()
    end
    buttons[#buttons + 1] = frame.keepButton
    Widgets.NormalizeButtonWidths(buttons, 10)
    local previous
    for i = #buttons, 1, -1 do
        local button = buttons[i]
        button:ClearAllPoints()
        if previous then
            button:SetPoint("RIGHT", previous, "LEFT", -8, 0)
        else
            button:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 14)
        end
        previous = button
    end
    frame.oursButton:SetScript("OnClick", function() TurnOffOurs(conflicts) end)
    frame.theirsButton:SetScript("OnClick", function() DisableTheirs(conflicts) end)
    frame.keepButton:SetScript("OnClick", function()
        KeepBoth(conflicts)
        frame:Hide()
    end)
    local width = 32
    for _, button in ipairs(buttons) do
        width = width + button:GetWidth() + 8
    end
    ns.Theme.ApplyFonts(frame)
    frame:SetWidth(math.max(460, width))
    frame:SetHeight(math.max(160, (frame.body:GetStringHeight() or 80) + POPUP_HEADER + 80))
    frame:Show()
    return true
end
function Integrations.CheckOnLogin()
    if not Enabled() then return end
    if InCombatLockdown() or (CharacterStatsStylePicker and CharacterStatsStylePicker:IsShown()) then
        C_Timer.After(3, Integrations.CheckOnLogin)
        return
    end
    Integrations.ShowConflictPopup()
end
function Integrations.ElvUISkinActive()
    if not IsLoaded("ElvUI") then return false end
    local skins = Walk(ElvUIEngine(), "private", "skins", "blizzard")
    return type(skins) == "table" and skins.enable ~= false and skins.character ~= false
end
function Integrations.StyleButtonForElvUI(button)
    if not Integrations.ElvUISkinActive() or button.elvStyled then return end
    if type(button.CreateBackdrop) ~= "function" then return end
    local ok = pcall(button.CreateBackdrop, button)
    if not ok then return end
    button.elvStyled = true
    if button.bg then button.bg:SetAlpha(0) end
    if button.border then button.border:SetAlpha(0) end
    if button.highlight then button.highlight:SetColorTexture(1, 1, 1, 0.2) end
    if button.icon then
        button.icon:ClearAllPoints()
        button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end
