local ADDON_NAME, ns = ...
local PROJECT_MAINLINE = 1
local projectId = WOW_PROJECT_ID or PROJECT_MAINLINE
ns.IS_RETAIL = (projectId == PROJECT_MAINLINE)
ns.IS_CLASSIC = (projectId ~= PROJECT_MAINLINE)
if ns.IS_CLASSIC then
    if not GetVersatilityBonus then
        GetVersatilityBonus = function() return 0 end
    end
    if not GetAvoidance then
        GetAvoidance = function() return 0 end
    end
    if not GetLifesteal then
        GetLifesteal = function() return 0 end
    end
    if not GetSpeed then
        GetSpeed = function() return 0 end
    end
    if not C_PlayerInfo then
        C_PlayerInfo = {}
    end
    if not C_PlayerInfo.GetGlidingInfo then
        C_PlayerInfo.GetGlidingInfo = function() return false, false, 0 end
    end
    if not GetPhysicalScreenSize then
        GetPhysicalScreenSize = function()
            return GetScreenWidth(), GetScreenHeight()
        end
    end
    if not CR_CRIT_MELEE then CR_CRIT_MELEE = 9 end
    if not CR_CRIT_RANGED then CR_CRIT_RANGED = 10 end
    if not CR_CRIT_SPELL then CR_CRIT_SPELL = 11 end
    if not CR_HASTE_MELEE then CR_HASTE_MELEE = 18 end
    if not CR_HASTE_RANGED then CR_HASTE_RANGED = 19 end
    if not CR_HASTE_SPELL then CR_HASTE_SPELL = 20 end
    local originalGetCombatRating = GetCombatRating
    if originalGetCombatRating then
        GetCombatRating = function(ratingId)
            local ok, result = pcall(originalGetCombatRating, ratingId)
            if ok then return result end
            return 0
        end
    else
        GetCombatRating = function() return 0 end
    end
    if not GetCombatRatingBonus then
        GetCombatRatingBonus = function() return 0 end
    end
end
ns.STAT_AVAILABILITY = {
    ilvl        = { true, true },
    str         = { true, true },
    agi         = { true, true },
    int         = { true, true },
    sta         = { true, true },
    spirit      = { false, true },
    crit        = { true, true },
    haste       = { true, true },
    mastery     = { true, true },
    manaregen   = { true, true },
    versatility = { true, false },
    hit         = { false, true },
    spellhit    = { false, true },
    expertise   = { false, true },
    attackpower = { false, true },
    spellpower  = { false, true },
    pvppower    = { false, true },
    rangedattackpower = { false, true },
    leech       = { true, false },
    avoidance   = { true, false },
    speed       = { true, false },
    armor       = { true, true },
    defense     = { false, false },
    dodge       = { true, true },
    parry       = { true, true },
    block       = { true, true },
    stagger     = { true, true },
    pvpresilience = { false, true },
    movespeed   = { true, true },
}
ns.IsStatAvailable = function(statId)
    local avail = ns.STAT_AVAILABILITY[statId]
    if not avail then return true end
    if ns.IS_RETAIL then
        return avail[1]
    else
        return avail[2]
    end
end
local function HasSpell(spellId)
    if not spellId then return false end
    if C_Spell and C_Spell.IsSpellKnown then
        local ok, known = pcall(C_Spell.IsSpellKnown, spellId)
        if ok then return known == true end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellId)
        if ok then return known == true end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellId, false)
        if ok then return known == true end
    end
    return false
end
local TANK_SPEC_IDS = {
    [73] = true,
    [66] = true,
    [250] = true,
    [268] = true,
    [104] = true,
}
local HEALER_SPEC_IDS = {
    [65] = true,
    [105] = true,
    [256] = true,
    [257] = true,
    [264] = true,
    [270] = true,
}
local SPEC_SPELLS = {
    DRUID = {
        { spec = 1, spells = {24858} },
        { spec = 1, spells = {78674, 93402}, all = true },
        { spec = 4, spells = {18562} },
        { spec = 4, spells = {48438} },
        { spec = 4, spells = {33763} },
        { spec = 3, spells = {62606} },
        { spec = 3, spells = {22842, 33745}, all = true },
        { spec = 2, spells = {5217} },
        { spec = 2, spells = {52610} },
        { spec = 2, spells = {106951} },
    },
    SHAMAN = {
        { spec = 2, spells = {17364, 60103, 51533} },
        { spec = 1, spells = {51505, 8050, 8042} },
        { spec = 3, spells = {61295, 73920, 1064} },
    },
    MONK = {
        { spec = 1, spells = {121253, 115295} },
        { spec = 2, spells = {125953, 116670} },
        { spec = 3, spells = {113656, 107428} },
    },
    PALADIN = {
        { spec = 2, spells = {53600, 26573, 31935, 53595} },
        { spec = 1, spells = {20473, 85222, 82327, 53563} },
        { spec = 3, spells = {85256, 35395, 24275, 20271} },
    },
    PRIEST = {
        { spec = 3, spells = {8092, 589, 34914} },
        { spec = 1, spells = {47540, 17} },
        { spec = 2, spells = {34861, 33076} },
    },
    WARRIOR = {
        { spec = 3, spells = {23922, 20243} },
        { spec = 1, spells = {12294, 86346} },
        { spec = 2, spells = {23881, 85288} },
    },
    DEATHKNIGHT = {
        { spec = 1, spells = {55050, 49998} },
        { spec = 2, spells = {49020, 49184} },
        { spec = 3, spells = {55090, 85948} },
    },
    ROGUE = {
        { spec = 1, spells = {1329, 32645} },
        { spec = 2, spells = {1752, 84617} },
        { spec = 3, spells = {8676, 16511} },
    },
    HUNTER = {
        { spec = 1, spells = {34026, 19574} },
        { spec = 2, spells = {19434, 53209} },
        { spec = 3, spells = {53301, 3674} },
    },
    MAGE = {
        { spec = 1, spells = {30451, 44425} },
        { spec = 2, spells = {11129, 44457} },
        { spec = 3, spells = {30455, 84714} },
    },
    WARLOCK = {
        { spec = 1, spells = {30108, 48181} },
        { spec = 2, spells = {103958, 105174} },
        { spec = 3, spells = {116858, 17962} },
    },
}
local function DetectSpecBySpells(classToken)
    local classSpells = SPEC_SPELLS[classToken]
    if not classSpells then return nil end
    for _, entry in ipairs(classSpells) do
        if entry.all then
            local allMatch = true
            for _, spellId in ipairs(entry.spells) do
                if not HasSpell(spellId) then
                    allMatch = false
                    break
                end
            end
            if allMatch then return entry.spec end
        else
            for _, spellId in ipairs(entry.spells) do
                if HasSpell(spellId) then
                    return entry.spec
                end
            end
        end
    end
    return nil
end
local TANK_CLASSES = {
    WARRIOR = true,
    PALADIN = true,
    DEATHKNIGHT = true,
    MONK = true,
    DRUID = true,
}
local libClassicSpecsCache = nil
local libClassicSpecsChecked = false
local function GetLibClassicSpecs()
    if libClassicSpecsChecked then
        return libClassicSpecsCache
    end
    libClassicSpecsChecked = true
    if not LibStub then
        return nil
    end
    local ok, lib = pcall(LibStub, "LibClassicSpecs", true)
    if not ok or not lib then
        return nil
    end
    if not GetNumTalentTabs then
        return nil
    end
    local callOk = pcall(GetNumTalentTabs)
    if not callOk then
        return nil
    end
    libClassicSpecsCache = lib
    return lib
end
local function GetCurrentSpecIndex()
    if GetSpecialization then
        local specIndex = GetSpecialization()
        if specIndex then
            return specIndex, "API"
        end
    end
    local lib = GetLibClassicSpecs()
    if lib and lib.GetSpecialization then
        local specIndex = lib.GetSpecialization()
        if specIndex then
            return specIndex, "LibClassicSpecs"
        end
    end
    local _, classToken = UnitClass("player")
    if not classToken then return nil, nil end
    local specIndex = DetectSpecBySpells(classToken)
    if specIndex then
        return specIndex, "spell"
    end
    return nil, nil
end
local function GetCurrentSpecId()
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            local specId = GetSpecializationInfo(specIndex)
            if specId then
                return specId, "API"
            end
        end
    end
    local lib = GetLibClassicSpecs()
    if lib and lib.GetSpecialization and lib.GetSpecializationInfo then
        local specIndex = lib.GetSpecialization()
        if specIndex then
            local specId = lib.GetSpecializationInfo(specIndex)
            if specId then
                return specId, "LibClassicSpecs"
            end
        end
    end
    local specIndex, method = GetCurrentSpecIndex()
    if not specIndex then return nil, nil end
    local _, classToken = UnitClass("player")
    if not classToken then return nil, nil end
    local SPEC_INDEX_TO_ID = {
        WARRIOR = { 71, 72, 73 },
        PALADIN = { 65, 66, 70 },
        HUNTER = { 253, 254, 255 },
        ROGUE = { 259, 260, 261 },
        PRIEST = { 256, 257, 258 },
        DEATHKNIGHT = { 250, 251, 252 },
        SHAMAN = { 262, 263, 264 },
        MAGE = { 62, 63, 64 },
        WARLOCK = { 265, 266, 267 },
        MONK = { 268, 270, 269 },
        DRUID = { 102, 103, 104, 105 },
    }
    local classSpecs = SPEC_INDEX_TO_ID[classToken]
    if classSpecs and classSpecs[specIndex] then
        return classSpecs[specIndex], method or "index_map"
    end
    return nil, nil
end
ns.GetCurrentSpecIndex = GetCurrentSpecIndex
ns.GetCurrentSpecId = GetCurrentSpecId
ns.GetPlayerRole = function()
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            local specId, _, _, _, role = GetSpecializationInfo(specIndex)
            if role then
                return role
            end
        end
    end
    local lib = GetLibClassicSpecs()
    if lib and lib.GetSpecialization and lib.GetSpecializationRole then
        local specIndex = lib.GetSpecialization()
        if specIndex then
            local role = lib.GetSpecializationRole(specIndex)
            if role then
                return role
            end
        end
    end
    local specId = GetCurrentSpecId()
    if specId then
        if TANK_SPEC_IDS[specId] then return "TANK" end
        if HEALER_SPEC_IDS[specId] then return "HEALER" end
        return "DAMAGER"
    end
    local _, classToken = UnitClass("player")
    local offhandLink = GetInventoryItemLink("player", 17)
    if offhandLink then
        local _, _, _, _, _, _, subType = GetItemInfo(offhandLink)
        if subType and (subType == "Shields" or subType == "Shield") then
            if TANK_CLASSES[classToken] then
                return "TANK"
            end
        end
    end
    return "DAMAGER"
end
ns.IsCaster = function()
    local _, classToken = UnitClass("player")
    if classToken == "MAGE" or classToken == "WARLOCK" then
        return true
    end
    if classToken == "PRIEST" then
        return true
    end
    local lib = GetLibClassicSpecs()
    if lib and lib.GetSpecialization and lib.GetSpecializationInfo then
        local specIndex = lib.GetSpecialization()
        if specIndex then
            local _, _, _, _, _, _, primaryStat = lib.GetSpecializationInfo(specIndex)
            if primaryStat == 4 then
                return true
            elseif primaryStat then
                return false
            end
        end
    end
    local spellSpecs = {
        [62] = true, [63] = true, [64] = true,
        [265] = true, [266] = true, [267] = true,
        [256] = true, [257] = true, [258] = true,
        [102] = true,
        [105] = true,
        [262] = true,
        [264] = true,
        [65] = true,
        [270] = true,
    }
    local specId = GetCurrentSpecId()
    if specId then
        return spellSpecs[specId] == true
    end
    if classToken == "DRUID" or classToken == "SHAMAN" or
       classToken == "PALADIN" or classToken == "MONK" then
        if UnitStat then
            local _, str = UnitStat("player", 1)
            local _, agi = UnitStat("player", 2)
            local _, int = UnitStat("player", 4)
            str = tonumber(str) or 0
            agi = tonumber(agi) or 0
            int = tonumber(int) or 0
            if int > str and int > agi then
                return true
            end
        end
    end
    return false
end
ns.IsRanged = function()
    local _, classToken = UnitClass("player")
    return classToken == "HUNTER"
end
