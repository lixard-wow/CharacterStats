local ADDON_NAME, ns = ...
local Diminishing = {}
ns.Diminishing = Diminishing
local pcall, type, ipairs = pcall, type, ipairs
local SECONDARY = {
    { upto = 30, penalty = 0 },
    { upto = 40, penalty = 0.1 },
    { upto = 50, penalty = 0.2 },
    { upto = 60, penalty = 0.3 },
    { upto = 80, penalty = 0.4 },
    { upto = 200, penalty = 0.5 },
}
local TERTIARY = {
    { upto = 10, penalty = 0 },
    { upto = 15, penalty = 0.2 },
    { upto = 20, penalty = 0.4 },
    { upto = 100, penalty = 0.6 },
}
local RATING_BY_STAT = {
    crit = 9,
    haste = 18,
    mastery = 26,
    versatility = 29,
    leech = 17,
    avoidance = 21,
    speed = 14,
}
local BRACKETS_BY_RATING = {
    [9] = SECONDARY,
    [18] = SECONDARY,
    [26] = SECONDARY,
    [29] = SECONDARY,
    [17] = TERTIARY,
    [21] = TERTIARY,
    [14] = TERTIARY,
}
local conversion = {}
local conversionLevel
local lastInfo = {}
local function IsSecret(value)
    return ns.IsSecretValue and ns.IsSecretValue(value)
end
function Diminishing.StatsHidden()
    if C_Secrets and C_Secrets.ShouldUnitStatsBeSecret then
        local ok, hidden = pcall(C_Secrets.ShouldUnitStatsBeSecret, "player")
        if ok and type(hidden) == "boolean" then
            return hidden
        end
    end
    return ns.BlizzardStats and ns.BlizzardStats.SecretsActive() or false
end
function Diminishing.RatingFor(statId)
    if not ns.IS_RETAIL then return nil end
    return RATING_BY_STAT[statId]
end
function Diminishing.Brackets(ratingId)
    return BRACKETS_BY_RATING[ratingId]
end
function Diminishing.FirstThreshold(ratingId)
    local brackets = BRACKETS_BY_RATING[ratingId]
    return brackets and brackets[1].upto or nil
end
local function RatingPerPercent(ratingId)
    local level = UnitLevel and UnitLevel("player") or 0
    if level ~= conversionLevel then
        conversion = {}
        conversionLevel = level
    end
    if conversion[ratingId] then
        return conversion[ratingId]
    end
    if not GetCombatRatingBonusForCombatRatingValue then return nil end
    local ok, bonus = pcall(GetCombatRatingBonusForCombatRatingValue, ratingId, 1)
    if not ok or type(bonus) ~= "number" or IsSecret(bonus) or bonus <= 0 then return nil end
    conversion[ratingId] = 1 / bonus
    return conversion[ratingId]
end
local function Compute(ratingId, rating, perPercent)
    local brackets = BRACKETS_BY_RATING[ratingId]
    local raw = rating / perPercent
    local effective, lower = 0, 0
    for index, bracket in ipairs(brackets) do
        local span = bracket.upto - lower
        if raw < bracket.upto or index == #brackets then
            local into = math.max(0, math.min(raw, bracket.upto) - lower)
            effective = effective + into * (1 - bracket.penalty)
            local nextBracket = brackets[index + 1]
            return {
                rating = rating,
                raw = raw,
                effective = effective,
                penalty = bracket.penalty,
                nextPenalty = nextBracket and nextBracket.penalty or nil,
                toNext = nextBracket and math.max(0, (bracket.upto - raw) * perPercent) or nil,
                lostRating = rating - effective * perPercent,
            }
        end
        effective = effective + span * (1 - bracket.penalty)
        lower = bracket.upto
    end
end
function Diminishing.Info(ratingId)
    if not ns.IS_RETAIL or not BRACKETS_BY_RATING[ratingId] then return nil end
    if Diminishing.StatsHidden() then
        return lastInfo[ratingId], true
    end
    if not GetCombatRating then return nil end
    local ok, rating = pcall(GetCombatRating, ratingId)
    if not ok or type(rating) ~= "number" or IsSecret(rating) then
        return lastInfo[ratingId], true
    end
    local perPercent = RatingPerPercent(ratingId)
    if not perPercent then return nil end
    local info = Compute(ratingId, rating, perPercent)
    lastInfo[ratingId] = info
    return info, false
end
local function Percent(value)
    return string.format("%d%%", math.floor(value * 100 + 0.5))
end
function Diminishing.AddTooltipLines(tooltip, statId)
    local ratingId = Diminishing.RatingFor(statId)
    if not ratingId or not tooltip then return false end
    local info, stale = Diminishing.Info(ratingId)
    if not info then return false end
    local L = ns.L
    local nr, ng, nb = 1, 0.82, 0
    local hr, hg, hb = 1, 1, 1
    tooltip:AddLine(" ")
    tooltip:AddLine(L.DR_TITLE or "Diminishing Returns", nr, ng, nb)
    if info.penalty > 0 then
        tooltip:AddDoubleLine(L.DR_PENALTY or "Current penalty", Percent(info.penalty), hr, hg, hb, 1, 0.45, 0.35)
    else
        tooltip:AddDoubleLine(L.DR_PENALTY or "Current penalty", L.DR_NONE or "None", hr, hg, hb, 0.4, 1, 0.4)
    end
    if info.toNext and info.nextPenalty then
        tooltip:AddDoubleLine(string.format(L.DR_NEXT or "Rating until %s penalty", Percent(info.nextPenalty)), ns.FormatNumber(info.toNext, 0), hr, hg, hb, hr, hg, hb)
    end
    if info.lostRating >= 1 then
        tooltip:AddDoubleLine(L.DR_EFFECTIVE or "Effective rating", ns.FormatNumber(info.rating - info.lostRating, 0) .. " / " .. ns.FormatNumber(info.rating, 0), hr, hg, hb, hr, hg, hb)
    end
    if stale then
        tooltip:AddLine(L.DR_STALE or "Stats are hidden right now, showing the last known values.", 0.6, 0.6, 0.6, true)
    end
    return true
end
function Diminishing.RatingPerPercent(ratingId)
    return RatingPerPercent(ratingId)
end
function Diminishing.EffectivePercent(ratingId, rating)
    local perPercent = RatingPerPercent(ratingId)
    if not perPercent or not BRACKETS_BY_RATING[ratingId] or type(rating) ~= "number" then return nil end
    return Compute(ratingId, math.max(0, rating), perPercent).effective
end
function Diminishing.MarginalPerPercent(ratingId)
    local info = Diminishing.Info(ratingId)
    local perPercent = RatingPerPercent(ratingId)
    if not info or not perPercent or info.penalty >= 1 then return nil end
    return perPercent / (1 - info.penalty)
end
