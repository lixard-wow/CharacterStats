local ADDON_NAME, ns = ...
local BlizzardStats = {}
ns.BlizzardStats = BlizzardStats
local pcall, type, wipe = pcall, type, wipe
local noop = function() end
local capturedLabel, capturedValue
local labelString = { SetText = function(_, text) capturedLabel = text end, SetShown = noop, SetTextColor = noop }
local valueString = { SetText = function(_, text) capturedValue = text end, SetShown = noop, SetTextColor = noop }
local proxy = {}
local function ResetProxy()
    wipe(proxy)
    proxy.Label = labelString
    proxy.Value = valueString
    proxy.Background = { SetShown = noop, Show = noop, Hide = noop }
    proxy.Show = noop
    proxy.Hide = noop
    proxy.SetShown = noop
    proxy.IsShown = function() return true end
end
function BlizzardStats.IsAvailable()
    return CharacterFrame ~= nil and CharacterFrame.GetStatsPane ~= nil
end
local percentByKey = {}
function BlizzardStats.SecretsActive()
    if not issecretvalue or not GetCombatRatingBonus then return false end
    local ok, value = pcall(GetCombatRatingBonus, 26)
    return ok and ns.IsSecretValue(value)
end
function BlizzardStats.StripColon(text)
    if type(text) ~= "string" or ns.IsSecretValue(text) then return text end
    text = text:gsub(":%s*$", "")
    return (text:gsub("\239\188\154%s*$", ""))
end
function BlizzardStats.Capture(key, unit, id)
    local info = PAPERDOLL_STATINFO and PAPERDOLL_STATINFO[key]
    if not info or not info.updateFunc then return nil end
    capturedLabel, capturedValue = nil, nil
    ResetProxy()
    local ok, numeric = pcall(info.updateFunc, proxy, unit or "player", id)
    if not ok then return nil end
    if type(numeric) ~= "number" then
        numeric = proxy.numericValue
    end
    return BlizzardStats.StripColon(capturedLabel), capturedValue, numeric
end
local RESISTANCE_INDEX = { Fire = 2, Nature = 3, Frost = 4, Shadow = 5, Arcane = 6 }
local probe
local function GetProbe()
    if probe then return probe end
    local holder = CreateFrame("Frame")
    holder:Hide()
    probe = CreateFrame("Frame", "CharacterStatsStatProbe", holder)
    probe.Label = probe:CreateFontString("CharacterStatsStatProbeLabel", "OVERLAY", "GameFontNormalSmall")
    probe.Value = probe:CreateFontString("CharacterStatsStatProbeStatText", "OVERLAY", "GameFontHighlightSmall")
    return probe
end
function BlizzardStats.CaptureNamed(key, unit)
    local info = PAPERDOLL_STATINFO and PAPERDOLL_STATINFO[key]
    if not info or not info.updateFunc then return nil end
    local frame = GetProbe()
    frame:Show()
    frame.Label:SetText("")
    frame.Value:SetText("")
    frame.numericValue, frame.tooltip, frame.tooltip2 = nil, nil, nil
    local ok, numeric = pcall(info.updateFunc, frame, unit or "player")
    if not ok or not frame:IsShown() then return nil end
    if type(numeric) ~= "number" then
        numeric = frame.numericValue
    end
    local label, value = frame.Label:GetText(), frame.Value:GetText()
    if not label or label == "" or not value or value == "" then return nil end
    return BlizzardStats.StripColon(label), value, numeric, frame.tooltip, frame.tooltip2
end
function BlizzardStats.IsPercentText(key, text)
    if text and not ns.IsSecretValue(text) and type(text) == "string" then
        percentByKey[key] = text:find("%%%s*$") ~= nil
    end
    return percentByKey[key] == true
end
function BlizzardStats.UsesCategories()
    return ns.IS_CLASSIC and not BlizzardStats.IsAvailable()
        and type(PAPERDOLL_STATCATEGORIES) == "table" and type(PAPERDOLL_STATINFO) == "table"
end
function BlizzardStats.ReadForStat(key, mopKey)
    local label, text, numeric
    if BlizzardStats.UsesCategories() then
        if not mopKey then return nil end
        label, text, numeric = BlizzardStats.CaptureNamed(mopKey, "player")
    else
        label, text, numeric = BlizzardStats.Capture(key, "player")
    end
    if not text then return nil end
    if type(numeric) ~= "number" then
        numeric = 1
    end
    return numeric, text, label
end
function BlizzardStats.ReadResistance(damageClassName)
    local damageClass = (Enum and Enum.Damageclass and Enum.Damageclass[damageClassName]) or RESISTANCE_INDEX[damageClassName]
    if not damageClass or not UnitResistance then return nil end
    local ok, _, effective = pcall(UnitResistance, "player", damageClass)
    if not ok or type(effective) ~= "number" then return nil end
    return effective
end
