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
function BlizzardStats.IsPercentText(key, text)
    if text and not ns.IsSecretValue(text) and type(text) == "string" then
        percentByKey[key] = text:find("%%%s*$") ~= nil
    end
    return percentByKey[key] == true
end
function BlizzardStats.ReadForStat(key)
    local label, text, numeric = BlizzardStats.Capture(key, "player")
    if not text then return nil end
    if type(numeric) ~= "number" then
        numeric = 1
    end
    return numeric, text, label
end
function BlizzardStats.ReadResistance(damageClassName)
    local damageClass = Enum and Enum.Damageclass and Enum.Damageclass[damageClassName]
    if not damageClass or not UnitResistance then return nil end
    local ok, _, effective = pcall(UnitResistance, "player", damageClass)
    if not ok or type(effective) ~= "number" then return nil end
    return effective
end
