local ADDON_NAME, ns = ...
local Gear = {}
ns.Gear = Gear
local pcall, pairs, ipairs, type, tonumber, wipe = pcall, pairs, ipairs, type, tonumber, wipe
local SLOTS = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17 }
if not ns.IS_RETAIL then
    SLOTS[#SLOTS + 1] = 18
end
local ENCHANT_SLOTS_RETAIL = {
    [1] = true,
    [3] = true,
    [5] = true,
    [8] = true,
    [11] = true,
    [12] = true,
    [16] = true,
    [17] = "weapon",
}
local ENCHANT_SLOTS_MOP = {
    [3] = true,
    [5] = true,
    [7] = true,
    [8] = true,
    [9] = true,
    [10] = true,
    [15] = true,
    [16] = "weapon",
    [17] = true,
}
local ENCHANT_SLOTS_FOREVER = {
    [2] = true,
    [5] = true,
    [8] = true,
    [9] = true,
    [10] = true,
    [15] = true,
    [16] = "weapon",
    [17] = true,
}
local function GetEnchantSlots()
    if ns.IS_RETAIL then return ENCHANT_SLOTS_RETAIL end
    if ns.BlizzardStats and ns.BlizzardStats.IsAvailable() then return ENCHANT_SLOTS_FOREVER end
    return ENCHANT_SLOTS_MOP
end
local ITEM_CLASS_WEAPON = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2
local TRACK_KEYS = { "explorer", "adventurer", "veteran", "champion", "hero", "myth" }
local trackLookup = nil
local function GetTrackLookup()
    if trackLookup then return trackLookup end
    trackLookup = {}
    for _, key in ipairs(TRACK_KEYS) do
        local name = ns.L["TRACK_" .. key:upper()]
        if name then
            trackLookup[name:lower()] = key
        end
    end
    return trackLookup
end
local UPGRADE_LINE_TYPE = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemUpgradeLevel
local function ParseTrackLine(text, lineType)
    if type(text) ~= "string" then return nil end
    local name, rank, maxRank = text:match(":%s*(.-)%s*(%d+)/(%d+)")
    if not name then
        name, rank, maxRank = text:match("\239\188\154%s*(.-)%s*(%d+)/(%d+)")
    end
    if not name then return nil end
    local key = GetTrackLookup()[name:lower()]
    if not key then
        if UPGRADE_LINE_TYPE and lineType == UPGRADE_LINE_TYPE then
            return false, tonumber(rank), tonumber(maxRank)
        end
        return nil
    end
    return key, tonumber(rank), tonumber(maxRank)
end
local ENCHANT_LINE_TYPE = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent
local function StripEnchantPrefix(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local stripped = text:match("^[^:|]+:%s*(.+)$") or text:match("^[^|]-\239\188\154%s*(.+)$") or text
    return stripped:match("^[^|]- %- (.+)$") or stripped
end
local enchantPattern
local function EnchantPattern()
    if enchantPattern == nil then
        local line = rawget(_G, "ENCHANTED_TOOLTIP_LINE")
        if type(line) == "string" and line:find("%s", 1, true) then
            local escaped = line:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
            enchantPattern = "^" .. escaped:gsub("%%%%s", "(.+)", 1) .. "$"
        else
            enchantPattern = false
        end
    end
    return enchantPattern
end
local function IsEnchantLine(line, text)
    if ENCHANT_LINE_TYPE and line.type == ENCHANT_LINE_TYPE then return true end
    local pattern = EnchantPattern()
    return pattern and text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match(pattern) ~= nil
end
local function ReadTooltip(entry, slot, readTrack)
    if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return end
    local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slot)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return end
    local foundTrack = not readTrack
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if type(text) == "string" then
            if not foundTrack then
                local key, rank, maxRank = ParseTrackLine(text, line.type)
                if key ~= nil then
                    entry.track, entry.trackRank, entry.trackMax = key or nil, rank, maxRank
                    foundTrack = true
                end
            end
            if not entry.enchantText and IsEnchantLine(line, text) then
                entry.enchantText = StripEnchantPrefix(text)
            end
        end
    end
end
local function EnchantNameFromSource(enchantId)
    if not ns.GetEnchantSource then return nil end
    local spell, item = ns.GetEnchantSource(enchantId)
    local name
    if spell then
        if C_Spell and C_Spell.GetSpellName then
            name = C_Spell.GetSpellName(spell)
        elseif GetSpellInfo then
            name = GetSpellInfo(spell)
        end
    elseif item then
        if C_Item and C_Item.GetItemNameByID then
            name = C_Item.GetItemNameByID(item)
        elseif GetItemInfo then
            name = GetItemInfo(item)
        end
    end
    if type(name) ~= "string" or name == "" then return nil end
    return name:match("^.- %- (.+)$") or name
end
local function IsCrafted(link)
    local getQuality = C_TradeSkillUI and C_TradeSkillUI.GetItemCraftedQualityByItemInfo
    if not getQuality then return false end
    local ok, quality = pcall(getQuality, link)
    return ok and type(quality) == "number" and quality > 0
end
local results = {}
local summary = { missingEnchants = 0, emptySockets = 0, pending = false }
local dirty = true
local enchantRetries = {}
local ENCHANT_RETRY_LIMIT = 5
Gear.SLOTS = SLOTS
local function GetItemLevel(slot, link)
    if C_Item and C_Item.GetCurrentItemLevel and ItemLocation and ItemLocation.CreateFromEquipmentSlot then
        local ok, location = pcall(ItemLocation.CreateFromEquipmentSlot, ItemLocation, slot)
        if ok and location then
            local okLevel, level = pcall(C_Item.GetCurrentItemLevel, location)
            if okLevel and type(level) == "number" and level > 0 then
                return level
            end
        end
    end
    local getDetailed = (C_Item and C_Item.GetDetailedItemLevelInfo) or rawget(_G, "GetDetailedItemLevelInfo")
    if getDetailed then
        local ok, level = pcall(getDetailed, link)
        if ok and type(level) == "number" and level > 0 then
            return level
        end
    end
    return nil
end
local function SplitItemString(link)
    local itemString = link:match("item:([%-%d:]+)")
    if not itemString then return nil end
    local fields = {}
    for field in (itemString .. ":"):gmatch("([^:]*):") do
        fields[#fields + 1] = field
    end
    return fields
end
local function ReadSockets(entry, link, fields)
    local gems = entry.gems
    wipe(gems)
    if C_Item and C_Item.GetItemNumSockets and C_Item.GetItemGemID then
        local ok, numSockets = pcall(C_Item.GetItemNumSockets, link)
        if ok and type(numSockets) == "number" then
            local empty = 0
            for index = 1, numSockets do
                local okGem, gemId = pcall(C_Item.GetItemGemID, link, index)
                local id = okGem and type(gemId) == "number" and gemId > 0 and gemId or false
                gems[index] = id
                if not id then
                    empty = empty + 1
                end
            end
            return empty
        end
    end
    local empty = 0
    local sockets = 0
    local getStats = (C_Item and C_Item.GetItemStats) or rawget(_G, "GetItemStats")
    if getStats then
        local okStats, stats = pcall(getStats, link)
        if okStats and type(stats) == "table" then
            for key, count in pairs(stats) do
                if type(key) == "string" and key:find("^EMPTY_SOCKET_") and type(count) == "number" then
                    sockets = sockets + count
                end
            end
        end
    end
    for i = 3, 6 do
        local gemId = tonumber(fields[i] or "")
        if gemId and gemId > 0 then
            gems[#gems + 1] = gemId
        end
    end
    for _ = #gems + 1, sockets do
        gems[#gems + 1] = false
        empty = empty + 1
    end
    return empty
end
local function NeedsEnchant(slot, link)
    local rule = GetEnchantSlots()[slot]
    if not rule then return false end
    if rule == "weapon" then
        local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        local ok, _, _, _, _, _, classId = pcall(getInstant, link)
        return ok and classId == ITEM_CLASS_WEAPON
    end
    return true
end
function Gear.Invalidate()
    dirty = true
end
function Gear.Scan()
    if not dirty then return results, summary end
    summary.missingEnchants = 0
    summary.emptySockets = 0
    summary.pending = false
    for _, slot in ipairs(SLOTS) do
        local entry = results[slot] or {}
        results[slot] = entry
        local link = GetInventoryItemLink("player", slot)
        entry.link = link
        entry.itemLevel = nil
        entry.missingEnchant = false
        entry.emptySockets = 0
        entry.track = nil
        entry.trackRank = nil
        entry.trackMax = nil
        entry.enchantText = nil
        entry.enchantId = nil
        entry.gems = entry.gems or {}
        wipe(entry.gems)
        if link then
            local crafted = IsCrafted(link)
            if crafted then
                entry.track = "crafted"
            end
            ReadTooltip(entry, slot, not crafted)
            entry.itemLevel = GetItemLevel(slot, link)
            if not entry.itemLevel then
                summary.pending = true
            end
            local fields = SplitItemString(link)
            if fields then
                local enchantId = tonumber(fields[2] or "")
                if enchantId and enchantId > 0 then
                    entry.enchantId = enchantId
                end
                if NeedsEnchant(slot, link) and not (enchantId and enchantId > 0) then
                    entry.missingEnchant = true
                    summary.missingEnchants = summary.missingEnchants + 1
                elseif enchantId and enchantId > 0 and not entry.enchantText then
                    entry.enchantText = EnchantNameFromSource(enchantId) or ns.L.GEAR_ENCHANTED or "Enchanted"
                    local tries = (enchantRetries[link] or 0) + 1
                    enchantRetries[link] = tries
                    if tries <= ENCHANT_RETRY_LIMIT then
                        summary.pending = true
                    end
                end
                entry.emptySockets = ReadSockets(entry, link, fields)
                summary.emptySockets = summary.emptySockets + entry.emptySockets
            end
        end
    end
    dirty = summary.pending
    return results, summary
end
