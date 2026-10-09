local ADDON_NAME, ns = ...
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local wipe = wipe
local BLIZZARD_STAT_KEYS = {
    ilvl        = "ITEMLEVEL",
    str         = "STRENGTH",
    agi         = "AGILITY",
    int         = "INTELLECT",
    sta         = "STAMINA",
    crit        = "CRITCHANCE",
    haste       = "HASTE",
    mastery     = "MASTERY",
    versatility = "VERSATILITY",
    leech       = "LIFESTEAL",
    avoidance   = "AVOIDANCE",
    speed       = "SPEED",
    armor       = "ARMOR",
    stagger     = "STAGGER",
    dodge       = "DODGE",
    parry       = "PARRY",
    block       = "BLOCK",
    movespeed   = "MOVESPEED",
    manaregen   = "MANAREGEN",
    health      = "HEALTH",
    power       = "POWER",
    mainhanddamage = "MAINHAND_DAMAGE",
    offhanddamage = "OFFHAND_DAMAGE",
    rangeddamage = "RANGED_DAMAGE",
    attackpower = "ATTACK_AP",
    rangedattackpower = "RANGED_ATTACK_AP",
    hit         = "HITCHANCE",
    spellpower  = "SPELLPOWER",
    spellhealing = "SPELLHEALING",
    spellpenetration = "SPELLPENETRATION",
    armorpenetration = "ARMORPEN",
    expertise   = "EXPERTISE",
    defense     = "DEFENSE",
    spirit      = "SPIRIT",
}
local STAT_ID_BY_BLIZZARD_KEY = {
    MELEE_AP = "attackpower",
    RANGED_AP = "rangedattackpower",
    SPELLDAMAGE = "spellpower",
    SPELLHEALING = "spellhealing",
    SPELL_PENETRATION = "spellpenetration",
    MELEE_DPS = "mainhanddamage",
    MELEE_ATTACKSPEED = "mainhanddamage",
    RANGED_DPS = "rangeddamage",
    RANGED_ATTACKSPEED = "rangeddamage",
    ALTERNATEMANA = "power",
    ENERGY_REGEN = "power",
    FOCUS_REGEN = "power",
    RUNE_REGEN = "power",
    ARCANE = "resarcane",
    FIRE = "resfire",
    FROST = "resfrost",
    NATURE = "resnature",
    SHADOW = "resshadow",
    SPELLCRIT = "crit",
    RANGED_CRITCHANCE = "crit",
    SPELL_HASTE = "haste",
    RANGED_HASTE = "haste",
    SPELL_HITCHANCE = "hit",
    RANGED_HITCHANCE = "hit",
    MANAREGEN = "manaregen",
    COMBATMANAREGEN = "manaregen",
    PVP_POWER = "pvppower",
    RESILIENCE_REDUCTION = "pvpresilience",
    MELEE_DAMAGE = "mainhanddamage",
    RANGED_DAMAGE = "rangeddamage",
}
for statId, key in pairs(BLIZZARD_STAT_KEYS) do
    STAT_ID_BY_BLIZZARD_KEY[key] = statId
end
local CATEGORY_ORDER = { "GENERAL", "ATTRIBUTES", "MELEE", "RANGED", "SPELL", "DEFENSE", "RESISTANCE" }
local RESISTANCE_SCHOOLS = { ARCANE = "arcane", FIRE = "fire", FROST = "frost", NATURE = "nature", SHADOW = "shadow" }
local noop = function() end
local mockFontString = { SetText = noop, SetShown = noop, SetTextColor = noop }
local statProxy = {}
local function ResetProxy(labelString, valueString)
    wipe(statProxy)
    statProxy.Value = valueString
    statProxy.Label = labelString
    statProxy.Background = mockFontString
    statProxy.Show = noop
    statProxy.Hide = noop
    statProxy.SetShown = noop
    statProxy.IsShown = function() return true end
end
local function TryShowBlizzardTooltipByKey(hoverFrame, key, statIndexId)
    if not PAPERDOLL_STATINFO or not key then return false end
    if ns.BlizzardStats.SecretsActive() then return false end
    local info = PAPERDOLL_STATINFO[key]
    if not info or not info.updateFunc then return false end
    ResetProxy(mockFontString, mockFontString)
    local ok = pcall(info.updateFunc, statProxy, "player", statIndexId)
    if not ok then return false end
    if statProxy.onEnterFunc then
        local copied = {}
        local hadUpdateTooltip = hoverFrame.UpdateTooltip ~= nil
        for k, v in pairs(statProxy) do
            if hoverFrame[k] == nil and k ~= "UpdateTooltip" then
                hoverFrame[k] = v
                copied[k] = true
            end
        end
        local success = pcall(statProxy.onEnterFunc, hoverFrame)
        for k in pairs(copied) do
            hoverFrame[k] = nil
        end
        if not hadUpdateTooltip then
            hoverFrame.UpdateTooltip = nil
        end
        if not success then return false end
    else
        if not statProxy.tooltip then return false end
        GameTooltip:SetOwner(hoverFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(statProxy.tooltip)
        if statProxy.tooltip2 then
            GameTooltip:AddLine(statProxy.tooltip2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        end
        if statProxy.tooltip3 then
            GameTooltip:AddLine(statProxy.tooltip3, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        end
        GameTooltip:Show()
    end
    return true
end
local function TryShowBlizzardTooltip(hoverFrame, statId)
    return TryShowBlizzardTooltipByKey(hoverFrame, BLIZZARD_STAT_KEYS[statId])
end
local PaperdollPanel = {}
function PaperdollPanel.UsesBlizzardStatList()
    return ns.BlizzardStats.IsAvailable()
end
local sections = {}
local sectionPool = {}
local rowPool = {}
function PaperdollPanel.UsesBlizzardCategories()
    return ns.IS_CLASSIC and not ns.BlizzardStats.IsAvailable()
        and type(PAPERDOLL_STATCATEGORIES) == "table" and type(PAPERDOLL_STATINFO) == "table"
end
local function CategoryRelevant(key, ctx)
    if key == "MELEE" then
        return not ctx.isCaster and not ctx.isHealer and not ctx.isRanged
    elseif key == "RANGED" then
        return ctx.isRanged
    elseif key == "SPELL" then
        return ctx.isCaster or ctx.isHealer
    end
    return true
end
local function CanShow(info)
    if not info or not info.canShowFunc then return true end
    local ok, result = pcall(info.canShowFunc)
    return not ok or result ~= false
end
local function IsZero(numeric, text)
    if type(numeric) == "number" then
        return math.abs(numeric) < 0.005
    end
    return type(text) == "string" and text:match("^%s*0[%.,]?0*%s*%%?%s*$") ~= nil
end
local function CollectCategorySections()
    local ctx = ns.GetCachedRoleContext and ns.GetCachedRoleContext() or {}
    local seen = {}
    local sectionCount, rowCount = 0, 0
    for _, key in ipairs(CATEGORY_ORDER) do
        local category = PAPERDOLL_STATCATEGORIES[key]
        if category and type(category.stats) == "table" and CategoryRelevant(key, ctx) and CanShow(category) then
            local section
            for _, statKey in ipairs(category.stats) do
                local statId = STAT_ID_BY_BLIZZARD_KEY[statKey]
                if not seen[statKey] and CanShow(PAPERDOLL_STATINFO[statKey])
                    and not (statId and ns.IsStatFilteredByRole and ns.IsStatFilteredByRole(statId)) then
                    local label, value, numeric, tooltip, tooltip2 = ns.BlizzardStats.CaptureNamed(statKey, "player")
                    if label and not (key ~= "GENERAL" and IsZero(numeric, value)) then
                        seen[statKey] = true
                        if not section then
                            sectionCount = sectionCount + 1
                            section = sectionPool[sectionCount] or {}
                            sectionPool[sectionCount] = section
                            section.title = rawget(_G, "STAT_CATEGORY_" .. key) or key
                            section.rows = section.rows or {}
                            wipe(section.rows)
                            sections[#sections + 1] = section
                        end
                        rowCount = rowCount + 1
                        local row = rowPool[rowCount] or {}
                        rowPool[rowCount] = row
                        wipe(row)
                        row.label, row.value, row.numericValue = label, value, numeric
                        row.tooltip, row.tooltip2 = tooltip, tooltip2
                        row.isPercent = ns.BlizzardStats.IsPercentText(statKey, value)
                        row.statId = statId
                        row.school = key == "RESISTANCE" and RESISTANCE_SCHOOLS[statKey] or nil
                        section.rows[#section.rows + 1] = row
                    end
                end
            end
        end
    end
    return sections
end
function PaperdollPanel.CollectBlizzardSections()
    wipe(sections)
    if PaperdollPanel.UsesBlizzardCategories() then
        return CollectCategorySections()
    end
    if not PaperdollPanel.UsesBlizzardStatList() then return sections end
    local ok, pane = pcall(CharacterFrame.GetStatsPane, CharacterFrame)
    local elements = ok and pane and pane.elementData
    if type(elements) ~= "table" then return sections end
    local section
    local sectionCount, rowCount = 0, 0
    for _, element in ipairs(elements) do
        if element.isHeader then
            sectionCount = sectionCount + 1
            section = sectionPool[sectionCount] or {}
            sectionPool[sectionCount] = section
            section.title = element.name
            section.rows = section.rows or {}
            wipe(section.rows)
            sections[#sections + 1] = section
        elseif section then
            rowCount = rowCount + 1
            local row = rowPool[rowCount] or {}
            rowPool[rowCount] = row
            wipe(row)
            if element.labelText then
                row.label = element.labelText
                row.value = element.valueText
                row.tooltip = element.tooltip
                row.tooltip2 = element.tooltip2
                row.atlas = element.atlas
                row.school = type(element.atlas) == "string" and element.atlas:match("Resistance%-(%a+)$") or nil
            elseif element.name and PAPERDOLL_STATINFO and PAPERDOLL_STATINFO[element.name] then
                row.label, row.value, row.numericValue = ns.BlizzardStats.Capture(element.name, element.unit, element.id)
                row.isPercent = ns.BlizzardStats.IsPercentText(element.name, row.value)
                row.blizzardKey = element.name
                row.statIndexId = element.id
                row.statId = STAT_ID_BY_BLIZZARD_KEY[element.name]
            end
            if row.label and row.value then
                section.rows[#section.rows + 1] = row
            end
        end
    end
    return sections
end
function PaperdollPanel.ShowBlizzardRowTooltip(owner, row)
    if row.blizzardKey and TryShowBlizzardTooltipByKey(owner, row.blizzardKey, row.statIndexId) then return end
    if not row.tooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.tooltip)
    if row.tooltip2 then
        GameTooltip:AddLine(row.tooltip2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    GameTooltip:Show()
end
ns.PaperdollPanel = PaperdollPanel
local function AddDiminishingLines(owner, statId)
    if not ns.Diminishing or not GameTooltip:IsOwned(owner) then return end
    if ns.Diminishing.AddTooltipLines(GameTooltip, statId) then
        GameTooltip:Show()
    end
end
function PaperdollPanel.ShowStatTooltip(owner, statId, title, valueText, bodyText)
    if TryShowBlizzardTooltip(owner, statId) then
        AddDiminishingLines(owner, statId)
        return
    end
    if not title then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if valueText and ns.IsSecretValue(valueText) then
        GameTooltip:SetText(title, 1, 1, 1)
        GameTooltip:AddLine(valueText, 1, 1, 1)
    else
        local header = title
        if valueText then
            header = header .. ": " .. valueText
        end
        GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE .. header .. FONT_COLOR_CODE_CLOSE)
    end
    if bodyText and bodyText ~= "" then
        GameTooltip:AddLine(bodyText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    GameTooltip:Show()
    AddDiminishingLines(owner, statId)
end
function PaperdollPanel.GetLocaleColon()
    local locale = GetLocale()
    if locale == "zhCN" or locale == "zhTW" then
        return "："
    end
    return ":"
end
function PaperdollPanel.GetItemLevels()
    local overall, equipped = GetAverageItemLevel()
    equipped = equipped or overall or 0
    return equipped, overall
end
local function GetCharacterStatsPane()
    if CharacterFrame and CharacterFrame.GetStatsPane then
        local ok, pane = pcall(CharacterFrame.GetStatsPane, CharacterFrame)
        if ok and pane then return pane end
    end
    local pane = rawget(_G, "CharacterStatsPane")
    if pane then return pane end
    return rawget(_G, "CharacterAttributesFrame")
end
local panel
local isAttached = false
local renderers = {}
local activeRenderer = nil
local hiddenStatsPaneChildren = {}
local hiddenStatsPaneRegions = {}
local function HideStatsPaneChildren(captureRestoreSet)
    local statsPane = GetCharacterStatsPane()
    if not statsPane then return end
    if captureRestoreSet then
        wipe(hiddenStatsPaneChildren)
        wipe(hiddenStatsPaneRegions)
    end
    for _, child in ipairs({ statsPane:GetChildren() }) do
        if child ~= panel and child:IsShown() then
            hiddenStatsPaneChildren[child] = true
            child:Hide()
        end
    end
    for _, region in ipairs({ statsPane:GetRegions() }) do
        if region:IsShown() then
            hiddenStatsPaneRegions[region] = true
            region:Hide()
        end
    end
end
local function ShowStatsPaneChildren()
    for child in pairs(hiddenStatsPaneChildren) do
        if child and child.Show then
            child:Show()
        end
    end
    for region in pairs(hiddenStatsPaneRegions) do
        if region and region.Show then
            region:Show()
        end
    end
    wipe(hiddenStatsPaneChildren)
    wipe(hiddenStatsPaneRegions)
end
local function GetActiveRenderer()
    local style = ns.Styles.GetActive()
    if not style.CreatePaperdollRenderer then return nil end
    local renderer = renderers[style.id]
    if not renderer then
        renderer = style.CreatePaperdollRenderer(panel)
        renderers[style.id] = renderer
    end
    if activeRenderer ~= renderer then
        if activeRenderer then
            activeRenderer:Hide()
        end
        activeRenderer = renderer
    end
    renderer:Show()
    return renderer
end
local function ShouldReplacePane()
    local db = ns.db
    if not db or not db.paperdollEnabled then return false end
    if ns.Integrations and ns.Integrations.StatsPaneTaken() then return false end
    return ns.Styles.GetActive().replacesPaperdollPane == true
end
local function ShouldShowDrawer()
    local db = ns.db
    if not db or not db.paperdollEnabled then return false end
    if ns.Integrations and ns.Integrations.CharacterFrameTaken() then return false end
    return ns.Styles.GetActive().usesDrawer == true
end
local function UpdateDrawer()
    local drawer = ns.CompanionDrawer
    if not drawer then return end
    if ShouldShowDrawer() and PaperDollFrame and PaperDollFrame:IsShown() then
        drawer:Show()
    else
        drawer:Hide()
    end
end
function PaperdollPanel:Create()
    if panel then return panel end
    local statsPane = GetCharacterStatsPane()
    if not statsPane then return nil end
    panel = CreateFrame("Frame", "CharacterStatsCustomPanel", statsPane)
    panel:SetAllPoints(statsPane)
    panel:SetFrameLevel(statsPane:GetFrameLevel() + 50)
    panel:Hide()
    return panel
end
function PaperdollPanel:Attach()
    if not PaperDollFrame then return end
    UpdateDrawer()
    if not ShouldReplacePane() then
        self:DetachPane()
        return
    end
    if isAttached then
        self:Refresh()
        return
    end
    if not self:Create() then return end
    HideStatsPaneChildren(true)
    panel:Show()
    if ns.Stats and ns.Stats.Invalidate then
        ns.Stats:Invalidate()
    end
    isAttached = true
    self:Refresh()
    C_Timer.After(0, function()
        PaperdollPanel:Refresh()
    end)
end
function PaperdollPanel:DetachPane()
    if not isAttached then return end
    isAttached = false
    if panel then
        panel:Hide()
    end
    ShowStatsPaneChildren()
end
function PaperdollPanel:Detach()
    if ns.CompanionDrawer then
        ns.CompanionDrawer:Hide()
    end
    self:DetachPane()
end
function PaperdollPanel:Toggle()
    if isAttached then
        self:Detach()
    else
        self:Attach()
    end
end
function PaperdollPanel:IsAttached()
    return isAttached or (ns.CompanionDrawer ~= nil and ns.CompanionDrawer:IsShown())
end
function PaperdollPanel:Refresh()
    if ns.CompanionDrawer and ns.CompanionDrawer:IsShown() then
        ns.CompanionDrawer:Refresh()
    end
    if not isAttached or not panel or not panel:IsShown() then return end
    if not ShouldReplacePane() then
        self:DetachPane()
        return
    end
    local renderer = GetActiveRenderer()
    if renderer then
        renderer:Refresh(ns.db or ns.DEFAULTS)
    end
end
function PaperdollPanel:ApplyStyle()
    if PaperDollFrame and PaperDollFrame:IsShown() then
        self:Attach()
    end
end
local initialized = false
function PaperdollPanel:Init()
    if initialized then
        self:Attach()
        return
    end
    if not PaperDollFrame then
        local waitFrame = CreateFrame("Frame")
        local attempts = 0
        local maxAttempts = 20
        waitFrame:RegisterEvent("ADDON_LOADED")
        waitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        waitFrame:SetScript("OnEvent", function(self)
            attempts = attempts + 1
            if PaperDollFrame then
                self:UnregisterAllEvents()
                PaperdollPanel:Init()
            elseif attempts >= maxAttempts then
                self:UnregisterAllEvents()
                ns.PrintMsg(ns.L.MSG_PAPERDOLL_MISSING or "Character panel not found, character panel stats disabled.", "warning")
            end
        end)
        return
    end
    initialized = true
    local function TryAttach()
        if not ns.db or not ns.db.paperdollEnabled then return end
        if isAttached then return end
        PaperdollPanel:Attach()
    end
    if CharacterFrame then
        CharacterFrame:HookScript("OnShow", function()
            C_Timer.After(0, TryAttach)
        end)
        CharacterFrame:HookScript("OnHide", function()
            PaperdollPanel:Detach()
        end)
    end
    PaperDollFrame:HookScript("OnShow", function()
        if not ns.db or not ns.db.paperdollEnabled then return end
        PaperdollPanel:Attach()
    end)
    PaperDollFrame:HookScript("OnHide", function()
        PaperdollPanel:Detach()
    end)
    if PaperDollFrame_UpdateStats then
        hooksecurefunc("PaperDollFrame_UpdateStats", function()
            if isAttached then
                HideStatsPaneChildren(false)
                if PaperdollPanel.UsesBlizzardStatList() or PaperdollPanel.UsesBlizzardCategories() then
                    PaperdollPanel:Refresh()
                end
            end
        end)
    end
    C_Timer.After(0, TryAttach)
end
