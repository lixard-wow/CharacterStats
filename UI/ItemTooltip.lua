local ADDON_NAME, ns = ...
local ItemTooltip = {}
ns.ItemTooltip = ItemTooltip
local pcall, pairs, ipairs, type = pcall, pairs, ipairs, type
local STATS = {
    { pattern = "CRIT_RATING", id = "crit" },
    { pattern = "HASTE_RATING", id = "haste" },
    { pattern = "MASTERY_RATING", id = "mastery" },
    { pattern = "VERSATILITY", id = "versatility" },
    { pattern = "LIFESTEAL", id = "leech" },
    { pattern = "AVOIDANCE", id = "avoidance" },
    { pattern = "CR_SPEED", id = "speed" },
}
local EQUIP_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }
local LOSS_COLOR = "|cffff8080"
local amounts = {}
local function IsEquipped(link)
    for _, slot in ipairs(EQUIP_SLOTS) do
        if GetInventoryItemLink("player", slot) == link then
            return true
        end
    end
    return false
end
local function ReadAmounts(link)
    for key in pairs(amounts) do amounts[key] = nil end
    local getStats = (C_Item and C_Item.GetItemStats) or rawget(_G, "GetItemStats")
    if not getStats then return false end
    local ok, stats = pcall(getStats, link)
    if not ok or type(stats) ~= "table" then return false end
    local found = false
    for key, value in pairs(stats) do
        if type(key) == "string" and type(value) == "number" and value > 0 then
            for _, info in ipairs(STATS) do
                if key:find(info.pattern, 1, true) then
                    amounts[info.id] = (amounts[info.id] or 0) + value
                    found = true
                    break
                end
            end
        end
    end
    return found
end
local function GainText(DR, ratingId, base, amount, equipped)
    local perPercent = DR.RatingPerPercent(ratingId)
    if not perPercent then return nil end
    local before, after
    if equipped then
        before, after = DR.EffectivePercent(ratingId, base - amount), DR.EffectivePercent(ratingId, base)
    else
        before, after = DR.EffectivePercent(ratingId, base), DR.EffectivePercent(ratingId, base + amount)
    end
    if not before or not after then return nil end
    local gain = after - before
    local lost = amount / perPercent - gain
    local text = string.format("+%.2f%%", gain)
    if lost >= 0.01 then
        text = text .. "  " .. LOSS_COLOR .. string.format("-%.2f%%", lost) .. "|r"
    end
    return text
end
local function IsWatchedTooltip(tooltip)
    return tooltip == GameTooltip or tooltip == rawget(_G, "ItemRefTooltip")
        or tooltip == rawget(_G, "ShoppingTooltip1") or tooltip == rawget(_G, "ShoppingTooltip2")
end
function ItemTooltip.OnItem(tooltip)
    local db = ns.db
    local DR = ns.Diminishing
    if not ns.IS_RETAIL or not db or db.itemTooltipDR == false or not DR then return end
    if not IsWatchedTooltip(tooltip) then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    local ok, _, link = pcall(tooltip.GetItem, tooltip)
    if not ok or type(link) ~= "string" or (ns.IsSecretValue and ns.IsSecretValue(link)) then return end
    if not ReadAmounts(link) then return end
    local equipped = IsEquipped(link)
    local L = ns.L
    local header = false
    for _, info in ipairs(STATS) do
        local amount = amounts[info.id]
        local ratingId = amount and DR.RatingFor(info.id)
        local current = ratingId and DR.Info(ratingId)
        local text = current and GainText(DR, ratingId, current.rating, amount, equipped)
        if text then
            if not header then
                tooltip:AddLine(" ")
                tooltip:AddLine(L.ITEM_TRUE_VALUE or "After diminishing returns", 1, 0.82, 0)
                header = true
            end
            local def = ns.STAT_DEFS[info.id]
            tooltip:AddDoubleLine(L["STAT_" .. info.id:upper()] or (def and def.label) or info.id, text, 1, 1, 1, 1, 1, 1)
        end
    end
    if header then
        tooltip:Show()
    end
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
        ItemTooltip.OnItem(tooltip)
    end)
end
