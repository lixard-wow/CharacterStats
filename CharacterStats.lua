local ADDON_NAME, ns = ...
local function GetAddOnMetadataSafe(name, field)
    local addonApi = _G and rawget(_G, "C_AddOns")
    local getMeta = addonApi and addonApi.GetAddOnMetadata
    if type(getMeta) == "function" then
        return getMeta(name, field)
    end
    local fn = _G and rawget(_G, "GetAddOnMetadata")
    if type(fn) == "function" then
        return fn(name, field)
    end
    return nil
end
ns.VERSION = GetAddOnMetadataSafe(ADDON_NAME, "Version") or "Unknown"
ns.AUTHOR = GetAddOnMetadataSafe(ADDON_NAME, "Author") or "Unknown"
ns.db = nil
ns._playerMoving = false
local function EnsureTableDefaults(db, defaults, key)
    if not rawget(db, key) then
        db[key] = {}
    end
    for k, v in pairs(defaults[key]) do
        if db[key][k] == nil then
            db[key][k] = v
        end
    end
end
local function EnsureArrayCopy(db, defaults, key)
    if not rawget(db, key) then
        db[key] = { unpack(defaults[key]) }
    end
end
local function EnsureColorCopy(db, defaults, key)
    if not rawget(db, key) then
        local c = defaults[key]
        db[key] = { r = c.r, g = c.g, b = c.b }
    end
end
local MSG_COLORS = {
    success = "|cff00ff00",
    error = "|cffFF0000",
    warning = "|cffFFAA00",
}
local function PrintMsg(msg, colorType)
    local color = MSG_COLORS[colorType] or MSG_COLORS.success
    print(color .. "CharacterStats:|r " .. msg)
end
ns.PrintMsg = PrintMsg
local function SafeToString(value)
    if ns.IsSecretValue(value) then
        return "<secret>"
    end
    local ok, text = pcall(tostring, value)
    return ok and text or "<unreadable>"
end
local function FormatProbeValue(value)
    local valueType = type(value)
    local secret = ns.IsSecretValue(value)
    return string.format("type=%s secret=%s value=%s", valueType, secret and "yes" or "no", SafeToString(value))
end
local function ProbeMoveSpeed()
    print("Movement speed live-path probe:")
    print("  InCombatLockdown(): " .. tostring(InCombatLockdown and InCombatLockdown()))
    print("  ns._inInstance: " .. tostring(ns._inInstance))
    local inVehicle = UnitInVehicle and UnitInVehicle("player")
    print("  UnitInVehicle: " .. tostring(inVehicle))
    print("  IsMounted(): " .. tostring(IsMounted and IsMounted()))
    local unit = inVehicle and "vehicle" or "player"
    local ok, _, runSpeed = pcall(GetUnitSpeed, unit)
    print(string.format("  GetUnitSpeed(%s): ok=%s runSpeed=%s", unit, tostring(ok), FormatProbeValue(runSpeed)))
    print("  Cached ns.movespeedDefault: " .. tostring(ns.movespeedDefault))
    local def = ns.STAT_DEFS and ns.STAT_DEFS.movespeed
    if def and def.api then
        local ok4, live = pcall(def.api)
        print("  movespeed stat's live api() result: ok=" .. tostring(ok4) .. " value=" .. tostring(live))
    end
end
local HELP_KEYS = {
    "CMD_TOGGLE",
    "CMD_CONFIG",
    "CMD_STYLE",
    "CMD_THEME",
    "CMD_RESET",
    "CMD_RESET_MINIMAP",
    "CMD_SHOW",
    "CMD_HIDE",
    "CMD_REFRESH",
}
SLASH_CHARACTERSTATS1 = "/cs"
SLASH_CHARACTERSTATS2 = "/charstats"
SLASH_CHARACTERSTATS3 = "/cstats"
SLASH_CHARACTERSTATSDEBUG1 = "/csdebug"
SlashCmdList["CHARACTERSTATS"] = function(msg)
    msg = string.lower(string.trim(msg or ""))
    if msg == "config" or msg == "options" or msg == "opt" then
        ns.ConfigPanel:Open()
    elseif msg == "style" or msg == "look" then
        ns.StylePicker.Show()
    elseif msg == "theme" then
        ns.Theme.Cycle()
        PrintMsg(string.format(ns.L.MSG_THEME_SET or "Window theme: %s", ns.Theme.GetName(ns.Theme.key)))
    elseif msg == "toggle" then
        ns.StatsFrame:Toggle()
    elseif msg == "show" then
        ns.StatsFrame:Show()
    elseif msg == "hide" then
        ns.StatsFrame:Hide()
    elseif msg == "reset" then
        ns.StatsFrame:ResetPosition()
        PrintMsg(ns.L.MSG_RESET or "Position reset.")
    elseif msg == "resetminimap" or msg == "resetmm" then
        if ns.MinimapButton and ns.MinimapButton.ResetPosition then
            ns.MinimapButton:ResetPosition()
            PrintMsg(ns.L.MSG_MINIMAP_RESET or "Minimap button position reset to default.")
        else
            PrintMsg(ns.L.MSG_MINIMAP_MISSING or "Minimap button not available.", "error")
        end
    elseif msg == "refresh" then
        if ns.RefreshNow then
            ns.RefreshNow({ reason = "slash" })
        else
            ns.Stats:Invalidate()
            if ns.StatsFrame and ns.StatsFrame:IsShown() then
                ns.StatsFrame:Refresh()
            end
        end
        PrintMsg(ns.L.MSG_REFRESHED or "Stats refreshed.")
    elseif msg == "help" or msg == "?" then
        PrintMsg(ns.L.MSG_COMMANDS or "Commands:")
        for _, key in ipairs(HELP_KEYS) do
            print("  " .. (ns.L[key] or key))
        end
    else
        ns.StatsFrame:Toggle()
    end
end
SlashCmdList["CHARACTERSTATSDEBUG"] = function(msg)
    msg = string.lower(string.trim(msg or ""))
    if msg == "movespeed" then
        ProbeMoveSpeed()
    else
        PrintMsg("Debug commands:")
        print("  /csdebug movespeed - Walk the movement speed calculation path step by step")
    end
end
local eventFrame = CreateFrame("Frame")
local UNIT_EVENTS = {
    "UNIT_STATS",
    "UNIT_AURA",
    "UNIT_DAMAGE",
    "UNIT_ATTACK_SPEED",
    "UNIT_RANGEDDAMAGE",
    "UNIT_ATTACK",
    "UNIT_RANGED_ATTACK_POWER",
    "UNIT_SPELL_HASTE",
    "UNIT_MAXHEALTH",
    "UNIT_RESISTANCES",
    "UNIT_INVENTORY_CHANGED",
    "UNIT_MAXPOWER",
    "UNIT_DISPLAYPOWER",
}
local UNIT_REFRESH_EVENTS = {}
local UNIT_REFRESH_DELAY = 0.15
for _, event in ipairs(UNIT_EVENTS) do
    UNIT_REFRESH_EVENTS[event] = true
end
local EVENTS = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_LOGOUT",
    "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_AVG_ITEM_LEVEL_UPDATE",
    "COMBAT_RATING_UPDATE",
    "MASTERY_UPDATE",
    "SPEED_UPDATE",
    "LIFESTEAL_UPDATE",
    "AVOIDANCE_UPDATE",
    "PLAYER_DAMAGE_DONE_MODS",
    "SPELL_POWER_CHANGED",
    "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "UPDATE_SHAPESHIFT_FORM",
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_SPECIALIZATION_CHANGED",
    "PLAYER_STARTED_MOVING",
    "PLAYER_STOPPED_MOVING",
    "CHALLENGE_MODE_START",
    "ADDON_RESTRICTION_STATE_CHANGED",
    "CHARACTER_ITEM_FIXUP_NOTIFICATION",
}
local function SafeRegisterEvent(frame, event)
    local ok = pcall(frame.RegisterEvent, frame, event)
    return ok
end
local function SafeRegisterUnitEvent(frame, event, unit)
    if frame.RegisterUnitEvent then
        local ok = pcall(frame.RegisterUnitEvent, frame, event, unit)
        if ok then return true end
    end
    return SafeRegisterEvent(frame, event)
end
for _, event in ipairs(UNIT_EVENTS) do
    SafeRegisterUnitEvent(eventFrame, event, "player")
end
for _, event in ipairs(EVENTS) do
    SafeRegisterEvent(eventFrame, event)
end
local refreshPending = false
local pendingRefreshOpts = nil
local function MergeRefreshOptions(base, incoming)
    if not base then
        base = {}
    end
    incoming = incoming or {}
    base.reason = incoming.reason or base.reason
    base.role = base.role or incoming.role
    base.wipeValues = base.wipeValues or incoming.wipeValues
    base.retryDelay = base.retryDelay or incoming.retryDelay
    return base
end
function ns.RefreshNow(opts)
    opts = opts or {}
    if opts.role then
        ns.Stats:InvalidateRole(opts.wipeValues)
    else
        ns.Stats:Invalidate()
    end
    if ns.StatsFrame and ns.StatsFrame:IsShown() then
        ns.StatsFrame:Refresh()
    end
    if ns.PaperdollPanel and ns.PaperdollPanel:IsAttached() then
        ns.PaperdollPanel:Refresh()
    end
end
function ns.QueueRefresh(reason, opts)
    opts = opts or {}
    opts.reason = reason or opts.reason
    pendingRefreshOpts = MergeRefreshOptions(pendingRefreshOpts, opts)
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(opts.delay or 0, function()
        local runOpts = pendingRefreshOpts or {}
        pendingRefreshOpts = nil
        refreshPending = false
        ns.RefreshNow(runOpts)
        if runOpts.retryDelay then
            local retryOpts = {
                reason = (runOpts.reason or "refresh") .. "_retry",
                role = runOpts.role,
                wipeValues = false,
            }
            C_Timer.After(runOpts.retryDelay, function()
                ns.RefreshNow(retryOpts)
            end)
        end
    end)
end
eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        local freshInstall = CharacterStatsDB == nil
        if not CharacterStatsDB then
            CharacterStatsDB = {}
        end
        if CharacterStatsDB.uiTheme == nil and ns.Theme then
            CharacterStatsDB.uiTheme = ns.Theme.DefaultKey(freshInstall)
        end
        for k, v in pairs(ns.DEFAULTS) do
            if CharacterStatsDB[k] == nil then
                if type(v) ~= "table" then
                    CharacterStatsDB[k] = v
                end
            end
        end
        ns.db = CharacterStatsDB
        EnsureTableDefaults(ns.db, ns.DEFAULTS, "stats")
        if not rawget(ns.db, "statOrder") then
            ns.db.statOrder = {}
        end
        local orderSet = {}
        for _, v in ipairs(ns.db.statOrder) do
            orderSet[v] = true
        end
        for _, v in ipairs(ns.DEFAULTS.statOrder) do
            if not orderSet[v] then
                table.insert(ns.db.statOrder, v)
            end
        end
        local validOrder = {}
        for _, statId in ipairs(ns.db.statOrder) do
            if ns.STAT_DEFS and ns.STAT_DEFS[statId] then
                table.insert(validOrder, statId)
            end
        end
        ns.db.statOrder = validOrder
        local order = ns.db.statOrder
        local staIndex, primaryAfterSta = nil, false
        local primaryStats = { str = true, agi = true, int = true }
        for i, statId in ipairs(order) do
            if statId == "sta" then
                staIndex = i
            elseif staIndex and primaryStats[statId] then
                primaryAfterSta = true
                break
            end
        end
        if staIndex and primaryAfterSta then
            local newOrder = {}
            local primaryFound = {}
            for _, statId in ipairs(order) do
                if primaryStats[statId] then
                    table.insert(primaryFound, statId)
                end
            end
            for _, statId in ipairs(order) do
                if primaryStats[statId] then
                elseif statId == "sta" then
                    for _, pStat in ipairs(primaryFound) do
                        table.insert(newOrder, pStat)
                    end
                    table.insert(newOrder, statId)
                else
                    table.insert(newOrder, statId)
                end
            end
            ns.db.statOrder = newOrder
        end
        EnsureArrayCopy(ns.db, ns.DEFAULTS, "labelColor")
        EnsureArrayCopy(ns.db, ns.DEFAULTS, "valueColor")
        EnsureColorCopy(ns.db, ns.DEFAULTS, "borderColor")
        if ns.db.statColors and ns.db.statColors.ilvl then
            ns.db.statColors.ilvl = nil
        end
        if ns.db.profiles then
            for profileName, profile in pairs(ns.db.profiles) do
                if type(profile) == "table" and profile.statColors and profile.statColors.ilvl then
                    profile.statColors.ilvl = nil
                end
            end
        end
        ns.db.cachedStatValues = nil
        local addonName = ns.L.ADDON_TITLE or "CharacterStats"
        print(string.format(ns.L.MSG_LOADED or "|cffff8000%s|r loaded. Type /cs to toggle.", addonName))
        return
    end
    if event == "PLAYER_LOGIN" then
        if not ns.db.profiles then
            ns.db.profiles = {}
            ns.CreateProfile("Default")
            ns.db.activeProfile = "Default"
        end
        if ns.IsSpecProfilesEnabled and ns.IsSpecProfilesEnabled() then
            local specs = ns.GetSpecNames and ns.GetSpecNames() or {}
            ns.db.specProfiles = ns.db.specProfiles or { enabled = true, map = {} }
            ns.db.specProfiles.map = ns.db.specProfiles.map or {}
            for _, specName in ipairs(specs) do
                if specName then
                    ns.GetSpecProfile(specName)
                end
            end
        end
        if ns.db.activeProfile and ns.SwitchProfile then
            ns.SwitchProfile(ns.db.activeProfile)
        end
        if ns.OnSpecChanged then
            ns.OnSpecChanged()
            ns.Stats:InvalidateRole(true)
        end
        if not ns.IsSpecProfilesEnabled or not ns.IsSpecProfilesEnabled() then
            if ns.IsOtherClassSpecName and ns.IsOtherClassSpecName(ns.db.activeProfile) then
                ns.SwitchProfile("Default")
            end
        end
        if ns.db.paperdollEnabled then
            ns.PaperdollPanel:Init()
        end
        if ns.db.showFrame then
            ns.StatsFrame:Show()
        end
        if ns.GearBadges then
            ns.GearBadges.Apply()
        end
        if ns.CharacterButton then
            ns.CharacterButton.Apply()
        end
        if ns.StylePicker then
            C_Timer.After(2, ns.StylePicker.ShowIfFirstRun)
        end
        if ns.Integrations then
            C_Timer.After(4, ns.Integrations.CheckOnLogin)
        end
        if ns.db.showMinimapButton then
            ns.MinimapButton:Show()
        end
        return
    end
    if event == "PLAYER_LOGOUT" then
        if ns.FlushProfileSave then
            ns.FlushProfileSave()
        end
        return
    end
    if event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" and ns.Gear then
            ns.Gear.Invalidate()
            if ns.GearBadges then ns.GearBadges.Refresh() end
            if ns.PaperdollPanel then ns.PaperdollPanel:Refresh() end
        end
        return
    end
    if UNIT_REFRESH_EVENTS[event] then
        if arg1 == "player" then
            ns.QueueRefresh(event, { delay = UNIT_REFRESH_DELAY })
        end
        return
    end
    if event == "PLAYER_EQUIPMENT_CHANGED" or
       event == "PLAYER_AVG_ITEM_LEVEL_UPDATE" or
       event == "CHARACTER_ITEM_FIXUP_NOTIFICATION" then
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            if ns.GearBadges then ns.GearBadges.OnEquipmentChanged() end
            ns.InvalidateIlvlColor()
            if ns.InvalidateShieldCache then ns.InvalidateShieldCache() end
        end
        ns.QueueRefresh(event, { retryDelay = 0.2 })
        return
    end
    if event == "COMBAT_RATING_UPDATE" or
       event == "MASTERY_UPDATE" or
       event == "SPEED_UPDATE" or
       event == "LIFESTEAL_UPDATE" or
       event == "AVOIDANCE_UPDATE" or
       event == "PLAYER_DAMAGE_DONE_MODS" or
       event == "SPELL_POWER_CHANGED" then
        ns.QueueRefresh(event)
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        if ns.InvalidatePlayerIdentityCache then ns.InvalidatePlayerIdentityCache() end
        ns._inInstance = IsInInstance and select(1, IsInInstance()) or false
        ns.Stats:InvalidateRole()
        ns.movespeedDefault = 100
        ns.QueueRefresh(event, { role = true, delay = 0.1, retryDelay = 0.3 })
        return
    end
    if event == "ZONE_CHANGED_NEW_AREA" then

        local wasInInstance = ns._inInstance
        ns._inInstance = IsInInstance and select(1, IsInInstance()) or false
        if ns._inInstance ~= wasInInstance then
            ns.QueueRefresh(event)
        end
        return
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" or
       event == "PLAYER_TALENT_UPDATE" or
       event == "ACTIVE_TALENT_GROUP_CHANGED" or
       event == "UPDATE_SHAPESHIFT_FORM" then
        if ns.InvalidatePlayerIdentityCache then ns.InvalidatePlayerIdentityCache() end
        if event == "PLAYER_SPECIALIZATION_CHANGED" and ns.OnSpecChanged then
            ns.OnSpecChanged()
        end
        ns.Stats:InvalidateRole(event == "PLAYER_SPECIALIZATION_CHANGED")
        ns.QueueRefresh(event, { role = true, wipeValues = event == "PLAYER_SPECIALIZATION_CHANGED" })
        return
    end
    if event == "CHALLENGE_MODE_START" then
        ns.Stats:InvalidateRole()
        ns.QueueRefresh(event, { role = true, delay = 0.1 })
        return
    end
    if event == "ADDON_RESTRICTION_STATE_CHANGED" then
        local restrictionActive = false
        local checked = false
        if C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive then
            local ok, active = pcall(C_RestrictedActions.IsAddOnRestrictionActive, arg1)
            if not ok then
                ok, active = pcall(C_RestrictedActions.IsAddOnRestrictionActive)
            end
            if ok then
                checked = true
                restrictionActive = active == true
            end
        end
        if not checked or not restrictionActive then
            ns.QueueRefresh(event)
        end
        return
    end
    if event == "PLAYER_STARTED_MOVING" then
        ns._playerMoving = true
        if ns.StatsFrame and ns.StatsFrame.UpdateMovementTracking then
            ns.StatsFrame:UpdateMovementTracking()
        end
        return
    end
    if event == "PLAYER_STOPPED_MOVING" then
        ns._playerMoving = false
        ns.RefreshNow({ reason = event })
        return
    end
end)
CharacterStatsAddon = ns
