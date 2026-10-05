local ADDON_NAME, ns = ...
local pairs, ipairs, type = pairs, ipairs, type
local wipe = wipe
local pcall = pcall
local GetTime = GetTime
local string_upper = string.upper
local Stats = {}
ns.Stats = Stats
local cache = {}
local filteredCache = {}
local statEntryPool = {}
local filteredDirty = true
local lastFilteredIlvl = nil
local lastUpdate = 0
local dirty = true
local seenNonZero = {}
local UPDATE_THROTTLE = 0.05
local function IsEffectivelyZero(v)
    if ns.IsSecretValue(v) then return false end
    if not v then return true end
    if type(v) == "number" then return math.abs(v) < 0.01 end
    local ok, result = pcall(function() return math.abs(v) < 0.01 end)
    if ok then return result end
    local ok2, n = pcall(function() return tonumber(string.format("%.4f", v)) end)
    if ok2 and n ~= nil then return math.abs(n) < 0.01 end
    return false
end
local labelKeyCache = {}
local function GetLabelKey(statId)
    local key = labelKeyCache[statId]
    if not key then
        key = "STAT_" .. string_upper(statId)
        labelKeyCache[statId] = key
    end
    return key
end
local roleContext = nil
local function GetRoleContext()
    if roleContext then return roleContext end
    local role = ns.GetPlayerRole and ns.GetPlayerRole() or "DAMAGER"
    roleContext = {
        specPrimaryStat = ns.GetSpecPrimaryStat and ns.GetSpecPrimaryStat() or nil,
        role = role,
        isTank = (role == "TANK"),
        isHealer = (role == "HEALER"),
        isCaster = ns.IsCaster and ns.IsCaster() or false,
        isRanged = ns.IsRanged and ns.IsRanged() or false,
    }
    return roleContext
end
local function ClearRoleContext()
    roleContext = nil
end
ns.GetCachedRoleContext = function()
    return GetRoleContext()
end
local function IsInPvPContent()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "pvp" or instanceType == "arena") then
        return true
    end
    if UnitIsPVP and UnitIsPVP("player") then
        return true
    end
    return false
end
local function ShouldFilterStatByRole(statId, def, ctx)
    if def and def.category == "primary" and def.primary then
        if ctx.specPrimaryStat and statId ~= ctx.specPrimaryStat then
            return true
        end
    end
    if statId == "spirit" then
        if not ctx.isHealer and not ctx.isCaster then
            return true
        end
    elseif statId == "manaregen" then
        if not ctx.isHealer then
            return true
        end
    elseif statId == "spellpower" then
        if not ctx.isCaster and not ctx.isHealer then
            return true
        end
    elseif statId == "attackpower" or statId == "expertise" then
        if ctx.isCaster or ctx.isRanged then
            return true
        end
    elseif statId == "rangedattackpower" then
        if not ctx.isRanged then
            return true
        end
    elseif statId == "spellhit" then
        return true
    elseif statId == "dodge" or statId == "parry" then
        if not ctx.isTank then
            return true
        end
    elseif statId == "pvppower" or statId == "pvpresilience" then
        if not IsInPvPContent() then
            return true
        end
    end
    return false
end
local function ShouldShowStat(statId, statValue, def, ctx)
    if def and def.alwaysShow then
        return true
    end
    if def and def.hideIfZero then
        if IsEffectivelyZero(statValue) then
            return false
        end
    end
    if ShouldFilterStatByRole(statId, def, ctx) then
        return false
    end
    if statId == "dodge" or statId == "parry" then
        if IsEffectivelyZero(statValue) then
            return false
        end
    end
    if statId == "block" then
        if not ns.HasShieldEquipped() then
            return false
        end
        if IsEffectivelyZero(statValue) then
            return false
        end
    end
    if statId == "stagger" then
        if not ns.IsSecretValue(statValue) and statValue == nil then
            return false
        end
    end
    if ns.IS_CLASSIC then
        if IsEffectivelyZero(statValue) then
            return false
        end
    end
    return true
end
function Stats:Collect(ignoreEnabled)
    local now = GetTime()
    if not dirty and (now - lastUpdate) < UPDATE_THROTTLE and #cache > 0 and not ignoreEnabled then
        return cache
    end
    wipe(cache)
    local db = ns.db
    if not db then return cache end
    local order = db.statOrder or ns.DEFAULTS.statOrder
    local enabled = db.stats or ns.DEFAULTS.stats
    local L = ns.L
    local IS_CLASSIC = ns.IS_CLASSIC
    local cacheIndex = 0
    for _, statId in ipairs(order) do
        if (ignoreEnabled or enabled[statId]) and ns.IsStatAvailable(statId) then
            local def = ns.STAT_DEFS[statId]
            if not def then
                if enabled[statId] then
                    ns.PrintMsg(string.format("Warning: Stat '%s' is enabled but has no definition", statId), "warning")
                end
            elseif def and def.api then
                local ok, rawValue = pcall(def.api)
                local value = nil
                local hasValue = false
                local readSecret = false
                if ok then
                    readSecret = ns.IsSecretValue(rawValue)
                    if readSecret then
                        if not def.hideIfZero or seenNonZero[statId] ~= false then
                            value = rawValue
                            hasValue = true
                        end
                    elseif rawValue ~= nil then
                        if type(rawValue) == "number" then
                            local okNum, n = pcall(function() return rawValue + 0 end)
                            if okNum and type(n) == "number" then
                                value = n
                                hasValue = true
                                if def.hideIfZero then
                                    seenNonZero[statId] = math.abs(n) >= 0.001
                                end
                            end
                        end
                    end
                end
                if not hasValue and def.alwaysShow then
                    value = 0
                    hasValue = true
                end
                if hasValue then
                    local labelKey = GetLabelKey(statId)
                    local label = def.label
                    local classicKey = labelKey .. "_CLASSIC"
                    if IS_CLASSIC and L[classicKey] then
                        label = L[classicKey]
                    elseif L[labelKey] then
                        label = L[labelKey]
                    end
                    local shortLabel = def.shortLabel or def.label
                    local abbrKey = labelKey .. "_ABBR"
                    local classicAbbrKey = labelKey .. "_CLASSIC_ABBR"
                    if IS_CLASSIC and L[classicAbbrKey] then
                        shortLabel = L[classicAbbrKey]
                    elseif L[abbrKey] then
                        shortLabel = L[abbrKey]
                    end
                    cacheIndex = cacheIndex + 1
                    local entry = statEntryPool[cacheIndex]
                    if not entry then
                        entry = {}
                        statEntryPool[cacheIndex] = entry
                    end
                    entry.id = statId
                    entry.label = label
                    entry.shortLabel = shortLabel
                    entry.value = value
                    entry.isSecret = readSecret
                    entry.percent = def.percent or false
                    entry.useDecimals = def.useDecimals or false
                    entry.category = def.category or "other"
                    entry.isHeader = false
                    entry.ratingId = def.ratingId
                    entry.tooltip = (def.tooltipKey and L[def.tooltipKey]) or def.tooltip or ""
                    cache[cacheIndex] = entry
                end
            end
        end
    end
    lastUpdate = now
    dirty = false
    return cache
end
function Stats:Invalidate()
    dirty = true
    filteredDirty = true
end
function Stats:InvalidateRole()
    ClearRoleContext()
    dirty = true
    filteredDirty = true
end
function Stats:UpdateMovementSpeed()
    for _, stat in ipairs(cache) do
        if stat.id == "movespeed" then
            local def = ns.STAT_DEFS.movespeed
            if def and def.api then
                local ok, value = pcall(def.api)
                if ok then
                    stat.value = value
                end
            end
            break
        end
    end
end
function Stats:CollectFiltered(includeIlvl, ignoreEnabled)
    if not filteredDirty and lastFilteredIlvl == includeIlvl and #filteredCache > 0 and not ignoreEnabled then
        return filteredCache
    end
    local allStats = self:Collect(ignoreEnabled)
    wipe(filteredCache)
    local ctx = GetRoleContext()
    for _, stat in ipairs(allStats) do
        if not stat.isHeader then
            if stat.id == "ilvl" then
                if includeIlvl then
                    filteredCache[#filteredCache + 1] = stat
                end
            elseif ShouldShowStat(stat.id, stat.value, ns.STAT_DEFS[stat.id], ctx) then
                filteredCache[#filteredCache + 1] = stat
            end
        end
    end
    filteredDirty = false
    lastFilteredIlvl = includeIlvl
    return filteredCache
end
function Stats:CollectByCategory()
    local filtered = self:CollectFiltered(false, true)
    local staminaStat = nil
    local primaryStat = nil
    local armorStat = nil
    local spiritStat = nil
    local staggerStat = nil
    local manaRegenStat = nil
    local moveSpeedStat = nil
    local enhancements = {}
    local defensives = {}
    local defensiveIds = {
        dodge = true,
        parry = true,
        block = true,
        pvpresilience = true,
    }
    for _, stat in ipairs(filtered) do
        if stat.category == "primary" then
            if stat.id == "sta" then
                staminaStat = stat
            elseif stat.id == "spirit" then
                spiritStat = stat
            else
                primaryStat = stat
            end
        elseif stat.id == "armor" then
            armorStat = stat
        elseif stat.id == "stagger" then
            staggerStat = stat
        elseif stat.id == "manaregen" then
            manaRegenStat = stat
        elseif stat.id == "movespeed" then
            moveSpeedStat = stat
        elseif defensiveIds[stat.id] then
            table.insert(defensives, stat)
        else
            table.insert(enhancements, stat)
        end
    end
    local attributes = {}
    if primaryStat then table.insert(attributes, primaryStat) end
    if staminaStat then table.insert(attributes, staminaStat) end
    if armorStat then table.insert(attributes, armorStat) end
    if staggerStat then table.insert(attributes, staggerStat) end
    if manaRegenStat then table.insert(attributes, manaRegenStat) end
    if spiritStat then table.insert(attributes, spiritStat) end
    for _, stat in ipairs(defensives) do
        table.insert(enhancements, stat)
    end
    if moveSpeedStat and ns.IS_CLASSIC then
        table.insert(enhancements, moveSpeedStat)
    end
    return attributes, enhancements
end
function Stats:GetLayoutList()
    local db = ns.db
    if not db then return {} end
    local order = db.statOrder or ns.DEFAULTS.statOrder
    local enabled = db.stats or ns.DEFAULTS.stats
    local ctx = GetRoleContext()
    local list = {}
    for i, statId in ipairs(order) do
        local def = ns.STAT_DEFS[statId]
        if def and ns.IsStatAvailable(statId) then
            local statValue
            if def.api then
                local ok, val = pcall(def.api)
                if ok then statValue = val end
            end
            if ShouldShowStat(statId, statValue, def, ctx) then
                local labelKey = "STAT_" .. string.upper(statId)
                local classicKey = labelKey .. "_CLASSIC"
                local label = def.label
                if ns.IS_CLASSIC and ns.L[classicKey] then
                    label = ns.L[classicKey]
                elseif ns.L[labelKey] then
                    label = ns.L[labelKey]
                end
                table.insert(list, {
                    id = statId,
                    label = label,
                    shortLabel = ns.L[labelKey .. "_ABBR"] or def.shortLabel or def.label,
                    enabled = enabled[statId] == true,
                    category = def.category,
                    orderIndex = i,
                })
            end
        end
    end
    return list
end
function Stats:SetEnabled(statId, state)
    local db = ns.db
    if not db then return end
    if not db.stats then
        db.stats = {}
        for k, v in pairs(ns.DEFAULTS.stats) do
            db.stats[k] = v
        end
    end
    if state == nil then
        db.stats[statId] = not db.stats[statId]
    else
        db.stats[statId] = state
    end
    local primaryIds = { str = true, agi = true, int = true }
    if primaryIds[statId] then
        local val = db.stats[statId]
        for pStat in pairs(primaryIds) do
            db.stats[pStat] = val
        end
    end
    self:Invalidate()
end
