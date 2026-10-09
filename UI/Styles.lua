local ADDON_NAME, ns = ...
local Styles = {}
ns.Styles = Styles
local pcall, tonumber = pcall, tonumber
local string_format = string.format
local registry = {}
local order = {}
Styles.DEFAULT = "original"
function Styles.Register(id, def)
    def.id = id
    registry[id] = def
    order[#order + 1] = def
    table.sort(order, function(a, b)
        return (a.order or 99) < (b.order or 99)
    end)
end
function Styles.Get(id)
    return registry[id]
end
function Styles.List()
    return order
end
function Styles.GetActive()
    local db = ns.db or ns.DEFAULTS
    return registry[db.style] or registry[Styles.DEFAULT]
end
function Styles.SafeStringWidth(fontString, fallback)
    local ok, w = pcall(fontString.GetStringWidth, fontString)
    if not ok or not w then return fallback or 0 end
    local ok2, n = pcall(function() return tonumber(string_format("%.4f", w)) end)
    return (ok2 and n) or fallback or 0
end
function Styles.HasRating(stat)
    return stat.percent and stat.ratingId and stat.ratingId <= 32
end
function Styles.FormatValue(stat, db)
    if stat.text then
        return stat.text
    end
    local dec = ns.GetDecimals(db.decimals)
    if stat.percent then
        return ns.FormatPercent(stat.value, dec)
    end
    return ns.FormatNumber(stat.value, stat.useDecimals and dec or 0)
end
function Styles.FormatStatValue(stat, db, dimRating)
    if stat.text then
        return stat.text
    end
    local ratingMode = db.ratingMode or "percent"
    local valueText = Styles.FormatValue(stat, db)
    if ratingMode == "percent" or not Styles.HasRating(stat) then
        return valueText
    end
    local ratingText = ns.FormatRating(stat.ratingId)
    if not ratingText then
        return valueText
    end
    if ratingMode == "rating" then
        return ratingText
    end
    if dimRating then
        return "|cff8c8c8c" .. ratingText .. "|r " .. valueText
    end
    return ratingText .. " " .. valueText
end
function Styles.GetGroupKey(stat)
    local category = stat.category
    if category == "tertiary" or category == "other" then
        return "utility"
    end
    return category
end
local GROUP_LABEL_KEYS = {
    general = "GROUP_GENERAL",
    weapons = "GROUP_WEAPONS",
    resistance = "GROUP_RESISTANCE",
    primary = "GROUP_PRIMARY",
    secondary = "GROUP_SECONDARY",
    utility = "GROUP_UTILITY",
    defense = "GROUP_DEFENSE",
}
local GROUP_FALLBACKS = {
    general = "General",
    weapons = "Weapons",
    resistance = "Resistance",
    primary = "Primary",
    secondary = "Secondary",
    utility = "Utility",
    defense = "Defense",
}
function Styles.GetGroupLabel(groupKey)
    return ns.L[GROUP_LABEL_KEYS[groupKey] or ""] or GROUP_FALLBACKS[groupKey] or groupKey
end
function Styles.ApplyStatColor(stat, db, ...)
    local r, g, b = ns.GetStatColor(stat.id)
    local alpha = db.textAlpha or 1
    for i = 1, select("#", ...) do
        select(i, ...):SetTextColor(r, g, b, alpha)
    end
end
function Styles.CreateHeader(parent)
    local header = {}
    header.frame = CreateFrame("Frame", nil, parent)
    header.text = header.frame:CreateFontString(nil, "OVERLAY")
    header.text:SetPoint("LEFT", header.frame, "LEFT", 0, 0)
    header.line = header.frame:CreateTexture(nil, "ARTWORK")
    header.line:SetPoint("LEFT", header.text, "RIGHT", 6, 0)
    header.line:SetPoint("RIGHT", header.frame, "RIGHT", 0, 0)
    header.line:SetHeight(1)
    header.frame:Hide()
    return header
end
function Styles.PlaceHeader(header, container, pad, y, label, fontPath, db)
    local size = math.max(8, db.fontSize - 2)
    local height = size + 6
    local alpha = db.textAlpha or 1
    local r, g, b = ns.GetAccentColor()
    header.text:SetFont(fontPath, size, db.fontOutline)
    header.text:SetText(label)
    header.text:SetTextColor(r, g, b, alpha)
    header.line:SetColorTexture(r, g, b, 0.25 * alpha)
    header.frame:ClearAllPoints()
    header.frame:SetPoint("TOPLEFT", container, "TOPLEFT", pad, y)
    header.frame:SetPoint("TOPRIGHT", container, "TOPRIGHT", -pad, y)
    header.frame:SetHeight(height)
    header.frame:Show()
    return height, Styles.SafeStringWidth(header.text, 0) + 20
end
local function EnsureOverflow(bar)
    local existing = rawget(bar, "over")
    if existing then return existing end
    local over = CreateFrame("StatusBar", nil, bar)
    over:SetAllPoints(bar)
    over:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    over:SetFrameLevel(bar:GetFrameLevel() + 1)
    bar.over = over
    return over
end
local function SetDiminishingBar(bar, statId)
    local db = ns.db
    if db and db.showDiminishing == false then return false end
    local DR = ns.Diminishing
    local ratingId = DR and statId and DR.RatingFor(statId)
    local threshold = ratingId and DR.FirstThreshold(ratingId)
    if not threshold or not GetCombatRatingBonus then return false end
    local ok, bonus = pcall(GetCombatRatingBonus, ratingId)
    if not ok or type(bonus) ~= "number" then return false end
    local over = EnsureOverflow(bar)
    bar:SetMinMaxValues(0, threshold)
    if not pcall(bar.SetValue, bar, bonus) then
        bar:SetValue(0)
    end
    over:SetMinMaxValues(threshold, threshold * 2)
    if not pcall(over.SetValue, over, bonus) then
        over:SetValue(threshold)
    end
    local r, g, b, a = bar:GetStatusBarColor()
    over:SetStatusBarColor((r or 1) * 0.5, (g or 1) * 0.5, (b or 1) * 0.5, a or 1)
    over:Show()
    return true
end
function Styles.BarHeight(db, key, fallback)
    local value = db and db[key]
    if type(value) ~= "number" then
        return fallback
    end
    return math.max(1, math.floor(value + 0.5))
end
function Styles.SetBarValue(bar, stat, maxValue)
    if SetDiminishingBar(bar, stat.id) then return end
    local over = rawget(bar, "over")
    if over then
        over:Hide()
    end
    bar:SetMinMaxValues(0, maxValue)
    local ok = pcall(bar.SetValue, bar, stat.value)
    if not ok then
        bar:SetValue(0)
    end
end
function Styles.HasBar(stat)
    return stat.percent == true and stat.id ~= "movespeed"
end
function Styles.GetBarScale(stats)
    local maxValue = 50
    for _, stat in ipairs(stats) do
        if Styles.HasBar(stat) and not stat.isSecret and type(stat.value) == "number" and stat.value > maxValue then
            maxValue = stat.value
        end
    end
    return math.ceil(maxValue / 10) * 10
end
