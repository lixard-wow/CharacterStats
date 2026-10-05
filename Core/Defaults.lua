local ADDON_NAME, ns = ...
ns.IsSecretValue = function(value)
    if not issecretvalue then return false end
    local ok, result = pcall(issecretvalue, value)
    return ok and result == true
end
ns.GetPixelPerfectScale = function()
    local physicalHeight = select(2, GetPhysicalScreenSize())
    if not physicalHeight or physicalHeight == 0 then
        return 1
    end
    return 768 / physicalHeight
end
ns.PixelRound = function(value)
    local scale = ns.GetPixelPerfectScale()
    if scale == 0 then return value end
    return math.floor(value / scale + 0.5) * scale
end
ns.movespeedDefault = 100
ns.DEFAULT_STAT_COLORS = {
    ilvl = {1.00, 0.82, 0.00},
    str = {0.78, 0.61, 0.43},
    agi = {1.00, 0.96, 0.41},
    int = {0.25, 0.78, 0.92},
    sta = {1.00, 1.00, 1.00},
    crit = {0.67, 0.83, 0.45},
    haste = {0.00, 0.44, 0.87},
    mastery = {1.00, 0.49, 0.04},
    versatility = {0.53, 0.53, 0.93},
    leech = {0.20, 0.58, 0.50},
    avoidance = {0.75, 0.75, 0.75},
    speed = {1.00, 0.82, 0.35},
    armor = {0.96, 0.55, 0.73},
    stagger = {0.00, 1.00, 0.60},
    dodge = {0.00, 1.00, 0.60},
    parry = {0.77, 0.12, 0.23},
    block = {0.64, 0.19, 0.79},
    manaregen = {0.20, 0.85, 0.85},
    movespeed = {1.00, 1.00, 1.00},
    spirit = {1.00, 0.82, 0.35},
    hit = {0.20, 0.58, 0.50},
    spellhit = {0.53, 0.53, 0.93},
    defense = {0.96, 0.55, 0.73},
    attackpower = {0.77, 0.12, 0.23},
    spellpower = {0.53, 0.53, 0.93},
    expertise = {0.75, 0.75, 0.75},
    pvppower = {0.00, 0.70, 0.00},
    pvpresilience = {0.70, 0.00, 0.70},
    rangedattackpower = {0.67, 0.83, 0.45},
}
ns.DEFAULTS = {
    anchor = "LEFT",
    anchorTo = "LEFT",
    x = 20,
    y = 0,
    width = 200,
    height = 350,
    showFrame = true,
    locked = false,
    showMinimapButton = true,
    paperdollEnabled = true,
    bgAlpha = 1.0,
    borderAlpha = 1.0,
    textAlpha = 1.0,
    borderStyle = "tooltip",
    borderColor = { r = 0.6, g = 0.6, b = 0.6 },
    borderUseClassColor = false,
    uiScale = 1.0,
    theme = "default",
    themeUseClassColor = false,
    fontFace = "default",
    fontSize = 12,
    fontOutline = "",
    labelColor = {1, 1, 1, 1},
    valueColor = {1, 0.82, 0, 1},
    alignMode = "justify",
    orientation = "vertical",
    rowPadding = 0,
    decimals = nil,
    ratingMode = "percent",
    stats = {
        ilvl = true,
        str = true,
        agi = true,
        int = true,
        sta = true,
        spirit = true,
        crit = true,
        haste = true,
        mastery = true,
        versatility = true,
        manaregen = true,
        hit = true,
        spellhit = false,
        attackpower = true,
        spellpower = true,
        expertise = true,
        pvppower = true,
        rangedattackpower = true,
        leech = true,
        avoidance = true,
        speed = false,
        armor = true,
        stagger = true,
        dodge = true,
        parry = true,
        block = true,
        defense = true,
        pvpresilience = true,
        movespeed = true,
    },
    statOrder = {
        "ilvl",
        "str", "agi", "int", "sta",
        "armor", "stagger",
        "manaregen", "spirit",
        "spellpower", "attackpower", "rangedattackpower",
        "crit", "haste", "hit", "expertise", "mastery",
        "versatility",
        "leech", "avoidance", "speed",
        "dodge", "parry", "block",
        "pvpresilience", "pvppower",
        "movespeed",
    },
    statColors = nil,
    useShortNames = false,
    showColon = true,
    showSeparator = false,
    separatorColor = { r = 0.5, g = 0.5, b = 0.5 },
    clampToScreen = true,
}
local function GetLocaleSeparator()
    local locale = GetLocale()
    if locale == "ruRU" or locale == "frFR" then
        return " "
    elseif locale == "deDE" then
        return "."
    end
    return ","
end
ns.FormatNumber = function(value, decimals)
    decimals = decimals or 0
    local fmt = "%." .. tostring(decimals) .. "f"
    if ns.IsSecretValue(value) then
        local ok, text = pcall(string.format, fmt, value)
        return (ok and text) or "0"
    end
    if type(value) ~= "number" then return "0" end
    local ok, formatted = pcall(string.format, fmt, value)
    if not ok or not formatted then return "0" end
    if decimals == 0 and math.abs(value) >= 100 then
        local separator = GetLocaleSeparator()
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1" .. separator .. "%2")
            if k == 0 then break end
        end
    end
    return formatted
end
ns.FormatPercent = function(value, decimals)
    decimals = decimals or 0
    local fmt = "%." .. tostring(decimals) .. "f%%"
    local ok, text = pcall(string.format, fmt, value)
    return (ok and text) or "0%"
end
ns.FormatRating = function(ratingId, value)
    local rating = value
    if ns.IsSecretValue(rating) then
        local ok, text = pcall(string.format, "(%.0f)", rating)
        return (ok and text) or nil, rating, true
    end
    if rating == nil and ratingId and GetCombatRating then
        local ok, result = pcall(GetCombatRating, ratingId)
        if ok then rating = result end
    end
    if ns.IsSecretValue(rating) then
        local ok, text = pcall(string.format, "(%.0f)", rating)
        return (ok and text) or nil, rating, true
    end
    if type(rating) ~= "number" then
        return nil, nil, false
    end
    local ok, text = pcall(string.format, "(%.0f)", rating)
    if not ok then return nil, nil, false end
    return text, rating, false
end
local CR_CRIT = 9
local CR_HASTE = 18
local CR_MASTERY = 26
local CR_VERSATILITY = 29
local lastGoodVersatility = nil

local versaRatio = nil
ns.InvalidateVersatilityCalibration = function()
    versaRatio = nil
end
local function GetEquippedVersatilityRating()
    local getStats = (C_Item and C_Item.GetItemStats) or rawget(_G, "GetItemStats")
    if not getStats then return nil end
    local total, found = 0, false
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local ok, stats = pcall(getStats, link)
            if ok and type(stats) == "table" then
                for statKey, statValue in pairs(stats) do
                    if type(statKey) == "string" and statKey:find("VERSATILITY") and type(statValue) == "number" then
                        total = total + statValue
                        found = true
                    end
                end
            end
        end
    end
    return found and total or nil
end
local CR_HIT_MELEE = 6
local CR_HIT_RANGED = 7
local CR_HIT_SPELL = 8
local BASE_SPEED = BASE_MOVEMENT_SPEED or 7
local function ypsToPercent(yps)
    if type(yps) ~= "number" then return nil end
    if ns.IsSecretValue(yps) then return nil end
    if yps <= 0 then return nil end
    local ok, result = pcall(function() return (yps / BASE_SPEED) * 100 end)
    return (ok and type(result) == "number") and result or nil
end
local cachedClassToken = nil
local cachedSpecId = nil
local function RefreshPlayerIdentityCache()
    local _, classToken = UnitClass("player")
    cachedClassToken = classToken
    cachedSpecId = ns.GetCurrentSpecId and ns.GetCurrentSpecId() or nil
    if not cachedSpecId then
        local specIndex = GetSpecialization and GetSpecialization() or nil
        if specIndex and GetSpecializationInfo then
            cachedSpecId = GetSpecializationInfo(specIndex)
        end
    end
end
local function GetCachedClassToken()
    if not cachedClassToken then
        RefreshPlayerIdentityCache()
    end
    return cachedClassToken
end
local function GetCachedSpecId()
    if not cachedClassToken and not cachedSpecId then
        RefreshPlayerIdentityCache()
    end
    return cachedSpecId
end
ns.InvalidatePlayerIdentityCache = function()
    cachedClassToken = nil
    cachedSpecId = nil
end
local function NormalizePercentValue(value)
    if type(value) ~= "number" then return nil end
    local ok, isFraction = pcall(function() return value >= 0 and value <= 1 end)
    if ok and isFraction then return value * 100 end
    return value
end
ns.STAT_DEFS = {
    ilvl = {
        label = "Item Level",
        shortLabel = "iLvl",
        category = "general",
        alwaysShow = true,
        useDecimals = true,
        tooltipKey = "STAT_ILVL_TT",
        api = function()
            local overall, equipped = GetAverageItemLevel()
            return equipped or overall or 0
        end,
    },
    str = {
        label = "Strength",
        shortLabel = "Str",
        category = "primary",
        primary = true,
        tooltipKey = "STAT_STR_TT",
        api = function()
            local base, stat = UnitStat("player", 1)
            return stat or base or 0
        end,
    },
    agi = {
        label = "Agility",
        shortLabel = "Agi",
        category = "primary",
        primary = true,
        tooltipKey = "STAT_AGI_TT",
        api = function()
            local base, stat = UnitStat("player", 2)
            return stat or base or 0
        end,
    },
    int = {
        label = "Intellect",
        shortLabel = "Int",
        category = "primary",
        primary = true,
        tooltipKey = "STAT_INT_TT",
        api = function()
            local base, stat = UnitStat("player", 4)
            return stat or base or 0
        end,
    },
    sta = {
        label = "Stamina",
        shortLabel = "Sta",
        category = "primary",
        alwaysShow = true,
        tooltipKey = "STAT_STA_TT",
        api = function()
            local base, stat = UnitStat("player", 3)
            return stat or base or 0
        end,
    },
    crit = {
        label = ns.IS_CLASSIC and "Crit Chance" or "Critical Strike",
        shortLabel = "Crit",
        category = "secondary",
        percent = true,
        ratingId = CR_CRIT,
        tooltipKey = "STAT_CRIT_TT",
        api = function()
            local ctx = ns.GetCachedRoleContext and ns.GetCachedRoleContext()
            local isCaster = ctx and ctx.isCaster or (ns.IsCaster and ns.IsCaster())
            local isRanged = ctx and ctx.isRanged or (ns.IsRanged and ns.IsRanged())
            if isCaster and GetSpellCritChance then
                local maxCrit = 0
                for school = 2, 7 do
                    local ok, crit = pcall(GetSpellCritChance, school)
                    if ok and type(crit) == "number" then
                        if ns.IsSecretValue(crit) then
                            return crit
                        elseif crit > maxCrit then
                            maxCrit = crit
                        end
                    end
                end
                if maxCrit > 0 then return maxCrit end
            elseif isRanged then
                if GetRangedCritChance then
                    local ok, crit = pcall(GetRangedCritChance)
                    if ok and type(crit) == "number" then
                        return crit
                    end
                end
            end
            return GetCritChance() or 0
        end,
    },
    haste = {
        label = "Haste",
        shortLabel = "Haste",
        category = "secondary",
        percent = true,
        ratingId = CR_HASTE,
        tooltipKey = "STAT_HASTE_TT",
        api = function()
            local ctx = ns.GetCachedRoleContext and ns.GetCachedRoleContext()
            local isCaster = ctx and ctx.isCaster or (ns.IsCaster and ns.IsCaster())
            if isCaster and UnitSpellHaste then
                local value = UnitSpellHaste("player")
                if type(value) == "number" then
                    return value
                end
            end
            if GetHaste then
                local value = GetHaste()
                if type(value) == "number" then
                    return value
                end
            end
            return 0
        end,
    },
    mastery = {
        label = "Mastery",
        shortLabel = "Mast",
        category = "secondary",
        percent = true,
        ratingId = CR_MASTERY,
        tooltipKey = "STAT_MASTERY_TT",
        api = function()
            return GetMasteryEffect() or 0
        end,
    },
    versatility = {
        label = "Versatility",
        shortLabel = "Vers",
        category = "secondary",
        percent = true,
        hideIfZero = true,
        ratingId = CR_VERSATILITY,
        tooltipKey = "STAT_VERSATILITY_TT",
        api = function()
            local okBase, base = pcall(GetCombatRatingBonus, CR_VERSATILITY)
            local okBonus, bonus = false, nil
            if GetVersatilityBonus then
                okBonus, bonus = pcall(GetVersatilityBonus, CR_VERSATILITY)
            end
            local baseSecret = okBase and type(base) == "number" and ns.IsSecretValue(base)
            local bonusSecret = okBonus and type(bonus) == "number" and ns.IsSecretValue(bonus)
            if baseSecret or bonusSecret then

                if versaRatio then
                    local gearRating = GetEquippedVersatilityRating()
                    if gearRating then
                        return versaRatio * gearRating
                    end
                end
                if lastGoodVersatility then
                    return lastGoodVersatility
                end
                return baseSecret and base or bonus
            end
            base = (okBase and type(base) == "number") and base or 0
            bonus = (okBonus and type(bonus) == "number") and bonus or 0
            local total = base + bonus
            lastGoodVersatility = total
            if not versaRatio then
                local gearRating = GetEquippedVersatilityRating()
                if gearRating and gearRating > 0 then
                    versaRatio = total / gearRating
                end
            end
            return total
        end,
    },
    manaregen = {
        label = "Mana Regen",
        shortLabel = "MP5",
        category = "secondary",
        hideIfZero = true,
        manaOnly = true,
        tooltipKey = "STAT_MANAREGEN_TT",
        api = function()
            if UnitPowerType then
                local powerType = UnitPowerType("player")
                if powerType ~= 0 then return nil end
            end
            local regen = nil
            if GetPowerRegen then
                local ok, base = pcall(GetPowerRegen)
                if ok and ns.IsSecretValue(base) then return base end
                if ok and type(base) == "number" then
                    regen = base
                end
            end
            local unitPowerRegen = _G and rawget(_G, "UnitPowerRegen")
            if regen == nil and unitPowerRegen then
                local ok, base = pcall(unitPowerRegen, "player")
                if ok and ns.IsSecretValue(base) then return base end
                if ok and type(base) == "number" then
                    regen = base
                end
            end
            if regen == nil and GetManaRegen then
                local ok, base, casting = pcall(GetManaRegen)
                if ok and ns.IsSecretValue(base) then return base end
                if ok and ns.IsSecretValue(casting) then return casting end
                if ok and type(base) == "number" then
                    regen = base
                elseif ok and type(casting) == "number" then
                    regen = casting
                end
            end
            if type(regen) == "number" then
                return math.floor(regen * 5)
            end
            return nil
        end,
    },
    leech = {
        label = "Leech",
        shortLabel = "Leech",
        category = "tertiary",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_LEECH_TT",
        api = function()
            return GetLifesteal() or 0
        end,
    },
    avoidance = {
        label = "Avoidance",
        shortLabel = "Avoid",
        category = "tertiary",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_AVOIDANCE_TT",
        api = function()
            return GetAvoidance() or 0
        end,
    },
    speed = {
        label = "Speed",
        shortLabel = "Speed",
        category = "tertiary",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_SPEED_TT",
        api = function()
            return GetSpeed()
        end,
    },
    armor = {
        label = "Armor",
        shortLabel = "Armor",
        category = "defense",
        alwaysShow = true,
        tooltipKey = "STAT_ARMOR_TT",
        api = function()
            local base, effectiveArmor = UnitArmor("player")
            return effectiveArmor or base or 0
        end,
    },
    stagger = {
        label = "Stagger",
        shortLabel = "Stagger",
        category = "defense",
        percent = true,
        hideIfZero = true,
        brewmasterOnly = true,
        tooltipKey = "STAT_STAGGER_TT",
        api = function()
            local classToken = GetCachedClassToken()
            if classToken ~= "MONK" then return nil end
            local specId = GetCachedSpecId()
            if specId ~= 268 then return nil end
            if C_PaperDollInfo and C_PaperDollInfo.GetStaggerPercentage then
                local ok, value = pcall(C_PaperDollInfo.GetStaggerPercentage, "player")
                if ok then
                    local normalized = NormalizePercentValue(value)
                    if normalized ~= nil then return normalized end
                end
            end
            local getStaggerPaperDoll = _G and rawget(_G, "PaperDollFrame_GetStaggerPercentage")
            if getStaggerPaperDoll then
                local ok, value = pcall(getStaggerPaperDoll)
                if ok then
                    local normalized = NormalizePercentValue(value)
                    if normalized ~= nil then return normalized end
                end
            end
            local getStagger = _G and rawget(_G, "GetStaggerPercentage")
            if getStagger then
                local ok, value = pcall(getStagger)
                if ok then
                    local normalized = NormalizePercentValue(value)
                    if normalized ~= nil then return normalized end
                end
            end
            if UnitStagger and UnitHealthMax then
                local _ok, result = pcall(function()
                    local stagger = UnitStagger("player")
                    local maxHP = UnitHealthMax("player")
                    if type(stagger) == "number" and type(maxHP) == "number" and maxHP > 0 then
                        return (stagger / maxHP) * 100
                    end
                end)
                if _ok and result then return result end
            end
            return 0
        end,
    },
    dodge = {
        label = "Dodge",
        shortLabel = "Dodge",
        category = "defense",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_DODGE_TT",
        api = function()
            return GetDodgeChance() or 0
        end,
    },
    parry = {
        label = "Parry",
        shortLabel = "Parry",
        category = "defense",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_PARRY_TT",
        api = function()
            return GetParryChance() or 0
        end,
    },
    block = {
        label = "Block",
        shortLabel = "Block",
        category = "defense",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_BLOCK_TT",
        api = function()
            return GetBlockChance() or 0
        end,
    },
    movespeed = {
        label = "Movement Speed",
        shortLabel = "Speed",
        category = "other",
        percent = true,
        alwaysShow = true,
        tooltipKey = "STAT_MOVESPEED_TT",
        api = function()
            local inInstance = ns._inInstance
            if inInstance then

                local inVehicle = UnitInVehicle and UnitInVehicle("player")
                local unit = inVehicle and "vehicle" or "player"
                local ok, _, runSpeed = pcall(GetUnitSpeed, unit)
                local result = ok and ypsToPercent(runSpeed) or nil
                if result and result > 0 then
                    ns.movespeedDefault = result
                end
                return ns.movespeedDefault
            end
            local best = 0
            if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
                local okGlide, _, _, forwardSpeed = pcall(C_PlayerInfo.GetGlidingInfo)
                if okGlide and type(forwardSpeed) == "number" and not ns.IsSecretValue(forwardSpeed) and forwardSpeed > 0 then
                    local ok, result = pcall(function() return (forwardSpeed / BASE_SPEED) * 100 end)
                    if ok and type(result) == "number" and result > best then best = result end
                end
            end
            local unit = (UnitInVehicle and UnitInVehicle("player")) and "vehicle" or "player"
            local ok, currentSpeed, runSpeed = pcall(GetUnitSpeed, unit)
            if ok then
                local result = ypsToPercent(currentSpeed) or ypsToPercent(runSpeed)
                if result and result > best then best = result end
            end
            if best > 0 then
                ns.movespeedDefault = best
                return best
            end
            return ns.movespeedDefault
        end,
    },
    spirit = {
        label = "Spirit",
        shortLabel = "Spi",
        category = "primary",
        tooltipKey = "STAT_SPIRIT_TT",
        api = function()
            local base, stat = UnitStat("player", 5)
            return stat or base or 0
        end,
    },
    hit = {
        label = "Hit Chance",
        shortLabel = "Hit",
        category = "secondary",
        percent = true,
        tooltipKey = "STAT_HIT_TT",
        api = function()
            local ctx = ns.GetCachedRoleContext and ns.GetCachedRoleContext()
            local isCaster = ctx and ctx.isCaster or (ns.IsCaster and ns.IsCaster())
            local isRanged = ctx and ctx.isRanged or (ns.IsRanged and ns.IsRanged())
            if isCaster then
                local total = 0
                if GetCombatRatingBonus then
                    local ok, value = pcall(GetCombatRatingBonus, CR_HIT_SPELL)
                    if ok and type(value) == "number" then
                        total = total + value
                    end
                end
                if GetSpellHitModifier then
                    local ok, value = pcall(GetSpellHitModifier)
                    if ok and type(value) == "number" then
                        total = total + value
                    end
                end
                return total
            elseif isRanged then
                local total = 0
                if GetCombatRatingBonus then
                    local ok, value = pcall(GetCombatRatingBonus, CR_HIT_RANGED)
                    if ok and type(value) == "number" then
                        total = total + value
                    end
                end
                return total
            else
                local total = 0
                if GetCombatRatingBonus then
                    local ok, value = pcall(GetCombatRatingBonus, CR_HIT_MELEE)
                    if ok and type(value) == "number" then
                        total = total + value
                    end
                end
                if GetHitModifier then
                    local ok, value = pcall(GetHitModifier)
                    if ok and type(value) == "number" then
                        total = total + value
                    end
                end
                return total
            end
        end,
    },
    spellhit = {
        label = "Spell Hit",
        shortLabel = "SpHit",
        category = "secondary",
        percent = true,
        tooltipKey = "STAT_SPELLHIT_TT",
        api = function()
            if GetSpellHitModifier then
                local ok, value = pcall(GetSpellHitModifier)
                if ok and type(value) == "number" then
                    return value
                end
            end
            if GetCombatRatingBonus then
                local ok, value = pcall(GetCombatRatingBonus, 8)
                if ok and type(value) == "number" then
                    return value
                end
            end
            return 0
        end,
    },
    defense = {
        label = "Defense",
        shortLabel = "Def",
        category = "defense",
        tooltipKey = "STAT_DEFENSE_TT",
        api = function()
            local getDefense = _G and rawget(_G, "GetDefense")
            if getDefense then
                local ok, base, modifier = pcall(getDefense)
                if ok and type(base) == "number" then
                    return base + (modifier or 0)
                end
            end
            return 0
        end,
    },
    attackpower = {
        label = "Attack Power",
        shortLabel = "AP",
        category = "secondary",
        tooltipKey = "STAT_ATTACKPOWER_TT",
        api = function()
            if not UnitAttackPower then return nil end
            local ok, base, positive, negative = pcall(UnitAttackPower, "player")
            if not ok then return nil end
            if ns.IsSecretValue(base) then return base end
            if ns.IsSecretValue(positive) then return positive end
            if ns.IsSecretValue(negative) then return negative end
            if type(base) ~= "number" then return nil end
            positive = type(positive) == "number" and positive or 0
            negative = type(negative) == "number" and negative or 0
            return base + positive + negative
        end,
    },
    spellpower = {
        label = "Spell Power",
        shortLabel = "SP",
        category = "secondary",
        tooltipKey = "STAT_SPELLPOWER_TT",
        api = function()
            if not GetSpellBonusDamage then return 0 end
            local maxSP = 0
            for school = 2, 7 do
                local ok, sp = pcall(GetSpellBonusDamage, school)
                if ok then
                    if ns.IsSecretValue(sp) then
                        return sp
                    elseif type(sp) == "number" and sp > maxSP then
                        maxSP = sp
                    end
                end
            end
            return maxSP
        end,
    },
    expertise = {
        label = "Expertise",
        shortLabel = "Exp",
        category = "secondary",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_EXPERTISE_TT",
        api = function()
            if GetExpertise then
                local ok, mainhand, offhand = pcall(GetExpertise)
                if ok and type(mainhand) == "number" then
                    return mainhand
                end
            end
            return 0
        end,
    },
    pvppower = {
        label = "PvP Power",
        shortLabel = "PvP Pow",
        category = "secondary",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_PVPPOWER_TT",
        api = function()
            if GetPvpPowerDamage then
                local ok, value = pcall(GetPvpPowerDamage)
                if ok and type(value) == "number" then
                    return value
                end
            end
            if GetCombatRatingBonus then
                local CR_PVP_POWER = 27
                local ok, value = pcall(GetCombatRatingBonus, CR_PVP_POWER)
                if ok and type(value) == "number" then
                    return value
                end
            end
            return 0
        end,
    },
    pvpresilience = {
        label = "PvP Resilience",
        shortLabel = "Resil",
        category = "defense",
        percent = true,
        hideIfZero = true,
        tooltipKey = "STAT_PVPRESILIENCE_TT",
        api = function()
            local getPvPResilienceBonus = _G and rawget(_G, "GetPvPResilienceBonus")
            if getPvPResilienceBonus then
                local ok, value = pcall(getPvPResilienceBonus)
                if ok and type(value) == "number" then
                    return value
                end
            end
            if GetCombatRatingBonus then
                local CR_RESILIENCE_CRIT_TAKEN = 16
                local CR_RESILIENCE_PLAYER_DAMAGE_TAKEN = 17
                local ok, value = pcall(GetCombatRatingBonus, CR_RESILIENCE_PLAYER_DAMAGE_TAKEN)
                if ok and type(value) == "number" then
                    local _ok, isPositive = pcall(function() return value > 0 end)
                    if _ok and isPositive then return value end
                end
                ok, value = pcall(GetCombatRatingBonus, CR_RESILIENCE_CRIT_TAKEN)
                if ok and type(value) == "number" then
                    return value
                end
            end
            return 0
        end,
    },
    rangedattackpower = {
        label = "Ranged Attack Power",
        shortLabel = "RAP",
        category = "secondary",
        hideIfZero = true,
        tooltipKey = "STAT_RANGEDATTACKPOWER_TT",
        api = function()
            if UnitRangedAttackPower then
                local ok, base, positive, negative = pcall(UnitRangedAttackPower, "player")
                if ok and type(base) == "number" then
                    return (base or 0) + (positive or 0) + (negative or 0)
                end
            end
            return 0
        end,
    },
}
local CLASS_PRIMARY = {
    WARRIOR = "str",
    DEATHKNIGHT = "str",
    HUNTER = "agi",
    ROGUE = "agi",
    DEMONHUNTER = nil,
    MAGE = "int",
    PRIEST = "int",
    WARLOCK = "int",
    EVOKER = "int",
    PALADIN = nil,
    DRUID = nil,
    SHAMAN = nil,
    MONK = nil,
}
local SPEC_PRIMARY = {
    [71] = "str",
    [72] = "str",
    [73] = "str",
    [65] = "int",
    [66] = "str",
    [70] = "str",
    [253] = "agi",
    [254] = "agi",
    [255] = "agi",
    [259] = "agi",
    [260] = "agi",
    [261] = "agi",
    [256] = "int",
    [257] = "int",
    [258] = "int",
    [250] = "str",
    [251] = "str",
    [252] = "str",
    [262] = "int",
    [263] = "agi",
    [264] = "int",
    [62] = "int",
    [63] = "int",
    [64] = "int",
    [265] = "int",
    [266] = "int",
    [267] = "int",
    [268] = "agi",
    [269] = "agi",
    [270] = "int",
    [102] = "int",
    [103] = "agi",
    [104] = "agi",
    [105] = "int",
    [577] = "agi",
    [581] = "agi",
    [1480] = "int",
    [1467] = "int",
    [1468] = "int",
    [1473] = "int",
}
local function GetHighestStatFallback()
    if not UnitStat then return nil end
    local _, str = UnitStat("player", 1)
    local _, agi = UnitStat("player", 2)
    local _, int = UnitStat("player", 4)
    str = str or 0
    agi = agi or 0
    int = int or 0
    if int >= str and int >= agi then return "int" end
    if agi >= str and agi >= int then return "agi" end
    return "str"
end
ns.GetSpecPrimaryStat = function()
    local classToken = GetCachedClassToken()
    if not classToken then return nil end
    local specId = GetCachedSpecId()
    if specId and SPEC_PRIMARY[specId] then
        return SPEC_PRIMARY[specId]
    end
    if CLASS_PRIMARY[classToken] then
        return CLASS_PRIMARY[classToken]
    end
    if classToken == "PALADIN" or classToken == "DRUID" or
       classToken == "SHAMAN" or classToken == "MONK" or
       classToken == "DEMONHUNTER" then
        return GetHighestStatFallback()
    end
    return nil
end
ns.LSM = nil
ns._ilvlColorCache = nil
ns._ilvlColorDirty = true
ns.InvalidateIlvlColor = function()
    ns._ilvlColorDirty = true
end
ns.GetAverageItemQualityColor = function()
    if not ns._ilvlColorDirty and ns._ilvlColorCache then
        return ns._ilvlColorCache[1], ns._ilvlColorCache[2], ns._ilvlColorCache[3]
    end
    local totalQuality, count = 0, 0
    local getQuality = C_Item and C_Item.GetInventoryItemQuality or GetInventoryItemQuality
    local getLink = C_Item and C_Item.GetInventoryItemLink or GetInventoryItemLink
    for slot = 1, 19 do
        if slot ~= 4 and slot ~= 19 then
            local quality = getQuality and getQuality("player", slot)
            if not quality and getLink then
                local link = getLink("player", slot)
                if link then
                    if C_Item and C_Item.GetItemInfo then
                        local _, _, itemQuality = C_Item.GetItemInfo(link)
                        quality = itemQuality
                    else
                        local _, _, itemQuality = GetItemInfo(link)
                        quality = itemQuality
                    end
                end
            end
            if quality then
                if quality > 4 then quality = 4 end
                totalQuality = totalQuality + quality
                count = count + 1
            end
        end
    end
    if count == 0 then
        local qc = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[4]
        if qc and type(qc.r) == "number" and type(qc.g) == "number" and type(qc.b) == "number" then
            return qc.r, qc.g, qc.b
        end
        return 0.64, 0.21, 0.93
    end
    local avgQuality = math.floor(totalQuality / count + 0.5)
    if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[avgQuality] then
        local qc = ITEM_QUALITY_COLORS[avgQuality]
        if qc and type(qc.r) == "number" and type(qc.g) == "number" and type(qc.b) == "number" then
            ns._ilvlColorCache = { qc.r, qc.g, qc.b }
        else
            ns._ilvlColorCache = { 1, 0.82, 0 }
        end
    else
        ns._ilvlColorCache = { 1, 0.82, 0 }
    end
    ns._ilvlColorDirty = false
    return ns._ilvlColorCache[1], ns._ilvlColorCache[2], ns._ilvlColorCache[3]
end
ns.GetStatColor = function(statId)
    local db = ns.db
    if db and db.statColors and db.statColors[statId] then
        local c = db.statColors[statId]
        return c.r, c.g, c.b
    end
    if statId == "ilvl" then
        return ns.GetAverageItemQualityColor()
    end
    local default = ns.DEFAULT_STAT_COLORS[statId]
    if default then
        return default[1], default[2], default[3]
    end
    return 1, 0.82, 0
end
ns.GetLSM = function()
    if not ns.LSM and LibStub then
        ns.LSM = LibStub("LibSharedMedia-3.0", true)
    end
    return ns.LSM
end
ns.GetFontPath = function(fontName)
    local LSM = ns.GetLSM()
    if not fontName or fontName == "default" then
        return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end
    if LSM then
        local path = LSM:Fetch("font", fontName)
        if path then
            return path
        end
    end
    if type(fontName) == "string" and (fontName:match("\\") or fontName:match("/")) then
        return fontName
    end
    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end
ns.GetDecimals = function(dbValue)
    if dbValue ~= nil then
        return dbValue
    end
    return ns.IS_RETAIL and 0 or 2
end
local shieldCache = nil
ns.HasShieldEquipped = function()
    if shieldCache ~= nil then return shieldCache end
    local offhandLink = GetInventoryItemLink("player", 17)
    if not offhandLink then
        shieldCache = false
        return false
    end
    local subType
    if C_Item and C_Item.GetItemInfo then
        local _, _, _, _, _, _, itemSubType = C_Item.GetItemInfo(offhandLink)
        subType = itemSubType
    end
    if not subType then
        local _, _, _, _, _, _, itemSubType = GetItemInfo(offhandLink)
        subType = itemSubType
    end
    shieldCache = subType and (subType == "Shields" or subType == "Shield") or false
    return shieldCache
end
ns.InvalidateShieldCache = function()
    shieldCache = nil
end
ns.THEMES = {
    { id = "default", color = { 0.78, 0.66, 0.22 } },
    { id = "DEATHKNIGHT", class = true },
    { id = "DEMONHUNTER", class = true },
    { id = "DRUID", class = true },
    { id = "EVOKER", class = true },
    { id = "HUNTER", class = true },
    { id = "MAGE", class = true },
    { id = "MONK", class = true },
    { id = "PALADIN", class = true },
    { id = "PRIEST", class = true },
    { id = "ROGUE", class = true },
    { id = "SHAMAN", class = true },
    { id = "WARLOCK", class = true },
    { id = "WARRIOR", class = true },
}
local function MuteColor(r, g, b, amount)
    amount = amount or 0.15
    local gray = 0.5
    return r + (gray - r) * amount,
           g + (gray - g) * amount,
           b + (gray - b) * amount
end
ns.GetClassColor = function(classToken)
    if not classToken then return nil end
    local key = classToken:upper()
    if C_ClassColor and C_ClassColor.GetClassColor then
        local c = C_ClassColor.GetClassColor(key)
        if c then return c.r, c.g, c.b end
    end
    local fallback = RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]
    if fallback then return fallback.r, fallback.g, fallback.b end
    return nil
end
ns.GetMutedClassColor = function(classToken)
    local r, g, b = ns.GetClassColor(classToken)
    if r then
        return MuteColor(r, g, b, 0.2)
    end
    return nil
end
ns.GetThemeColor = function(themeId)
    local db = ns.db
    if db and db.themeUseClassColor then
        local r, g, b = ns.GetMutedClassColor(select(2, UnitClass("player")))
        if r then return r, g, b end
    end
    for _, theme in ipairs(ns.THEMES) do
        if theme.id == themeId then
            if theme.class then
                local r, g, b = ns.GetMutedClassColor(theme.id)
                if r then return r, g, b end
            elseif theme.color then
                return theme.color[1], theme.color[2], theme.color[3]
            end
        end
    end
    return 0.78, 0.66, 0.22
end
ns.GetCurrentThemeColor = function()
    local db = ns.db
    local themeId = db and db.theme or "default"
    return ns.GetThemeColor(themeId)
end
ns.GetAccentColor = function()
    return ns.GetCurrentThemeColor()
end
ns.GetThemeName = function(themeId)
    local L = ns.L or {}
    for _, theme in ipairs(ns.THEMES) do
        if theme.id == themeId then
            if themeId == "default" then
                return L.THEME_DEFAULT or "Default"
            end
            if theme.class then
                local localized = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[themeId]
                return localized or themeId
            end
        end
    end
    return themeId
end
ns.GetProfileList = function()
    local profiles = {"Default"}
    local db = ns.db
    if db and db.profiles then
        local specProfileNames = {}
        if db.specProfiles and db.specProfiles.map then
            for _, profileName in pairs(db.specProfiles.map) do
                specProfileNames[profileName] = true
            end
        end
        for name in pairs(db.profiles) do
            if name ~= "Default" and not specProfileNames[name] then
                profiles[#profiles + 1] = name
            end
        end
        table.sort(profiles, function(a, b)
            if a == "Default" then return true end
            if b == "Default" then return false end
            return a < b
        end)
    end
    return profiles
end
ns.GetActiveProfile = function()
    local db = ns.db
    return db and db.activeProfile or "Default"
end
local CLASS_SPECS = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    HUNTER = { "Beast Mastery", "Marksmanship", "Survival" },
    ROGUE = { "Assassination", "Combat", "Subtlety" },
    PRIEST = { "Discipline", "Holy", "Shadow" },
    DEATHKNIGHT = { "Blood", "Frost", "Unholy" },
    SHAMAN = { "Elemental", "Enhancement", "Restoration" },
    MAGE = { "Arcane", "Fire", "Frost" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
    MONK = { "Brewmaster", "Mistweaver", "Windwalker" },
    DRUID = { "Balance", "Feral", "Guardian", "Restoration" },
    DEMONHUNTER = { "Havoc", "Vengeance" },
    EVOKER = { "Devastation", "Preservation", "Augmentation" },
}
ns.IsOtherClassSpecName = function(name)
    if not name then return false end
    local mySpecs = ns.GetSpecNames and ns.GetSpecNames() or {}
    for _, specName in ipairs(mySpecs) do
        if specName == name then return false end
    end
    for _, classSpecs in pairs(CLASS_SPECS) do
        for _, specName in ipairs(classSpecs) do
            if specName == name then return true end
        end
    end
    return false
end
ns.GetCurrentSpecName = function()
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            local _, name = GetSpecializationInfo(specIndex)
            if name then
                return name
            end
        end
    end
    local specIndex = ns.GetCurrentSpecIndex and ns.GetCurrentSpecIndex()
    if specIndex then
        local _, classToken = UnitClass("player")
        if classToken and CLASS_SPECS[classToken] then
            return CLASS_SPECS[classToken][specIndex]
        end
    end
    return nil
end
ns.GetSpecNames = function()
    local specs = {}
    if GetNumSpecializations and GetSpecializationInfo then
        local numSpecs = GetNumSpecializations() or 0
        if numSpecs > 0 then
            for i = 1, numSpecs do
                local _, name = GetSpecializationInfo(i)
                if name then
                    specs[i] = name
                end
            end
            if #specs > 0 then
                return specs
            end
        end
    end
    local _, classToken = UnitClass("player")
    if classToken and CLASS_SPECS[classToken] then
        for i, name in ipairs(CLASS_SPECS[classToken]) do
            specs[i] = name
        end
    end
    return specs
end
local function DeepCopy(src, visited)
    if type(src) ~= "table" then return src end
    visited = visited or {}
    if visited[src] then
        return {}
    end
    visited[src] = true
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v, visited)
    end
    return copy
end
ns.CreateProfile = function(name)
    if not name or name == "" then return false end
    local db = ns.db
    if not db then return false end
    db.profiles = db.profiles or {}
    if db.profiles[name] then return false end
    db.profiles[name] = DeepCopy(ns.DEFAULTS)
    if db.profiles[name].statColors and db.profiles[name].statColors.ilvl then
        db.profiles[name].statColors.ilvl = nil
    end
    if db.stats then
        local primaryStats = { "str", "agi", "int" }
        local anyDisabled = false
        for _, statId in ipairs(primaryStats) do
            if db.stats[statId] == false then
                anyDisabled = true
                break
            end
        end
        if anyDisabled then
            for _, statId in ipairs(primaryStats) do
                db.profiles[name].stats[statId] = false
            end
        end
    end
    return true
end
ns.CopyProfile = function(sourceName, destName)
    if not destName or destName == "" then return false end
    local db = ns.db
    if not db then return false end
    db.profiles = db.profiles or {}
    if db.profiles[destName] then return false end
    local source = db.profiles[sourceName]
    if not source then
        ns.PrintMsg(string.format("Source profile '%s' not found, using default settings", sourceName or "nil"), "warning")
        source = ns.DEFAULTS
    end
    db.profiles[destName] = DeepCopy(source)
    return true
end
local GLOBAL_SETTINGS = {
    profiles = true,
    activeProfile = true,
    specProfiles = true,
    minimap = true,
    theme = true,
    themeUseClassColor = true,
}
local saveTimer = nil
local SAVE_DELAY = 1.0
ns.ResetToDefaults = function()
    local db = ns.db
    if not db then return end
    if saveTimer then
        saveTimer:Cancel()
        saveTimer = nil
    end
    db.profiles = nil
    db.activeProfile = "Default"
    db.specProfiles = nil
    local keysToRemove = {}
    for k in pairs(db) do
        if not GLOBAL_SETTINGS[k] then
            keysToRemove[#keysToRemove + 1] = k
        end
    end
    for _, k in ipairs(keysToRemove) do
        db[k] = nil
    end
    for k, v in pairs(ns.DEFAULTS) do
        if not GLOBAL_SETTINGS[k] then
            if type(v) == "table" then
                db[k] = DeepCopy(v)
            else
                db[k] = v
            end
        end
    end
    ns.CreateProfile("Default")
    db.activeProfile = "Default"
end
ns.SaveToActiveProfile = function()
    local db = ns.db
    if not db then return end
    local profileName = db.activeProfile or "Default"
    db.profiles = db.profiles or {}
    if not db.profiles[profileName] then
        db.profiles[profileName] = DeepCopy(ns.DEFAULTS)
    end
    for k, v in pairs(db) do
        if not GLOBAL_SETTINGS[k] then
            if k == "statColors" and type(v) == "table" then
                local colorsCopy = DeepCopy(v)
                colorsCopy.ilvl = nil
                db.profiles[profileName][k] = colorsCopy
            else
                db.profiles[profileName][k] = DeepCopy(v)
            end
        end
    end
end
ns.MarkProfileDirty = function()
    if saveTimer then
        saveTimer:Cancel()
        saveTimer = nil
    end
    if C_Timer and C_Timer.NewTimer then
        saveTimer = C_Timer.NewTimer(SAVE_DELAY, function()
            ns.SaveToActiveProfile()
            saveTimer = nil
        end)
    end
end
ns.FlushProfileSave = function()
    if saveTimer then
        saveTimer:Cancel()
        saveTimer = nil
    end
    if ns.db then
        ns.SaveToActiveProfile()
    end
end
ns.SwitchProfile = function(name)
    local db = ns.db
    if not db then return false end
    db.profiles = db.profiles or {}
    if not db.profiles["Default"] then
        db.profiles["Default"] = DeepCopy(ns.DEFAULTS)
    end
    if not db.profiles[name] then
        db.profiles[name] = DeepCopy(ns.DEFAULTS)
    end
    if db.profiles[name] and db.profiles[name].statColors and db.profiles[name].statColors.ilvl then
        db.profiles[name].statColors.ilvl = nil
    end
    ns.FlushProfileSave()
    local profile = db.profiles[name]
    if profile then
        for k, v in pairs(profile) do
            if not GLOBAL_SETTINGS[k] then
                db[k] = DeepCopy(v)
            end
        end
    end
    if db.stats then
        local primaryStats = { "str", "agi", "int" }
        local anyDisabled = false
        for _, statId in ipairs(primaryStats) do
            if db.stats[statId] == false then
                anyDisabled = true
                break
            end
        end
        if anyDisabled then
            for _, statId in ipairs(primaryStats) do
                db.stats[statId] = false
            end
        end
    end
    if db.statColors and db.statColors.ilvl then
        db.statColors.ilvl = nil
    end
    db.activeProfile = name
    return true
end
ns.IsSpecProfilesEnabled = function()
    local db = ns.db
    return db and db.specProfiles and db.specProfiles.enabled
end
ns.SetSpecProfilesEnabled = function(enabled)
    local db = ns.db
    if not db then return end
    db.specProfiles = db.specProfiles or { enabled = false, map = {} }
    db.specProfiles.enabled = enabled
    if enabled then
        db.specProfiles.lastGlobalProfile = db.activeProfile
        local specs = ns.GetSpecNames()
        if not specs or #specs == 0 then
            return
        end
        for _, specName in ipairs(specs) do
            if specName then
                ns.CreateProfile(specName)
                db.specProfiles.map = db.specProfiles.map or {}
                if not db.specProfiles.map[specName] then
                    db.specProfiles.map[specName] = specName
                end
            end
        end
        local currentSpec = ns.GetCurrentSpecName()
        if currentSpec and db.specProfiles.map[currentSpec] then
            ns.SwitchProfile(db.specProfiles.map[currentSpec])
            if ns.StatsFrame and ns.StatsFrame.RestorePosition then
                ns.StatsFrame:RestorePosition()
            end
        end
    else
        local restoreTo = db.specProfiles.lastGlobalProfile or "Default"
        if not db.profiles or not db.profiles[restoreTo] then
            restoreTo = "Default"
        end
        ns.SwitchProfile(restoreTo)
        if ns.StatsFrame and ns.StatsFrame.RestorePosition then
            ns.StatsFrame:RestorePosition()
        end
    end
end
ns.GetSpecProfile = function(specName)
    local db = ns.db
    if not db or not specName then return specName end
    db.specProfiles = db.specProfiles or { enabled = false, map = {} }
    db.specProfiles.map = db.specProfiles.map or {}
    if not db.specProfiles.map[specName] then
        ns.CreateProfile(specName)
        db.specProfiles.map[specName] = specName
    end
    return db.specProfiles.map[specName]
end
ns.SetSpecProfile = function(specName, profileName)
    local db = ns.db
    if not db then return end
    db.specProfiles = db.specProfiles or { enabled = false, map = {} }
    db.specProfiles.map = db.specProfiles.map or {}
    db.specProfiles.map[specName] = profileName
end
ns.OnSpecChanged = function()
    if not ns.IsSpecProfilesEnabled() then return end
    local specName = ns.GetCurrentSpecName()
    if specName then
        local profileName = ns.GetSpecProfile(specName)
        if profileName and profileName ~= ns.GetActiveProfile() then
            ns.SwitchProfile(profileName)
            if ns.StatsFrame then
                ns.StatsFrame:RestorePosition()
                ns.StatsFrame:ApplyStyle()
                ns.StatsFrame:Refresh()
            end
            if ns.PaperdollPanel then
                ns.PaperdollPanel:Refresh()
            end
        end
    end
end
