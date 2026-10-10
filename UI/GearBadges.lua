local ADDON_NAME, ns = ...
local GearBadges = {}
ns.GearBadges = GearBadges
local SLOT_BUTTONS = {
    [1] = "CharacterHeadSlot",
    [2] = "CharacterNeckSlot",
    [3] = "CharacterShoulderSlot",
    [15] = "CharacterBackSlot",
    [5] = "CharacterChestSlot",
    [9] = "CharacterWristSlot",
    [10] = "CharacterHandsSlot",
    [6] = "CharacterWaistSlot",
    [7] = "CharacterLegsSlot",
    [8] = "CharacterFeetSlot",
    [11] = "CharacterFinger0Slot",
    [12] = "CharacterFinger1Slot",
    [13] = "CharacterTrinket0Slot",
    [14] = "CharacterTrinket1Slot",
    [16] = "CharacterMainHandSlot",
    [17] = "CharacterSecondaryHandSlot",
    [18] = "CharacterRangedSlot",
}
local DETAIL_RIGHT = {
    [1] = true, [2] = true, [3] = true, [15] = true, [5] = true, [9] = true, [17] = true, [18] = true,
}
local GEM_SIZE = 11
local MAX_GEMS = 3
local DETAIL_WIDTH = 105
local WEAPON_DETAIL_WIDTH = 90
local WEAPON_SLOTS = {
    [16] = true, [17] = true, [18] = true,
}
local EMPTY_SOCKET_TEXTURE = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic"
local ENCHANT_COLOR = { 0.35, 0.95, 0.35 }
local badges = {}
local retryPending = false
local ENCHANT_FALLBACK_ICON = "Interface\\Icons\\Trade_Engraving"
local ENCHANT_ICON_SIZE = 14
local SIDE_GAP = 7
local EDGE_INSET = 3
local function ShowEnchantTooltip(self)
    local spell, item
    if self.enchantId then
        spell, item = ns.GetEnchantSource(self.enchantId)
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if spell then
        GameTooltip:SetSpellByID(spell)
    elseif item then
        GameTooltip:SetItemByID(item)
    elseif self.enchantName then
        GameTooltip:SetText(self.enchantName, ENCHANT_COLOR[1], ENCHANT_COLOR[2], ENCHANT_COLOR[3])
    else
        return
    end
    GameTooltip:Show()
end
local function ShowGemTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.gemId then
        GameTooltip:SetItemByID(self.gemId)
    else
        GameTooltip:SetText(ns.L.GEAR_EMPTY_SOCKET or "Empty socket", 1, 1, 1)
    end
    GameTooltip:Show()
end
local function CreateDetail(badge, button, side, width)
    local detail = CreateFrame("Frame", nil, badge)
    detail:SetAllPoints(badge)
    detail.side = side
    detail.button = button
    detail.enchant = detail:CreateFontString(nil, "OVERLAY")
    detail.enchant:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    detail.enchant:SetWidth(width)
    detail.enchant:SetWordWrap(false)
    detail.enchant:SetJustifyH(side == "left" and "RIGHT" or "LEFT")
    detail.enchantIcon = CreateFrame("Frame", nil, detail)
    detail.enchantIcon:SetSize(ENCHANT_ICON_SIZE, ENCHANT_ICON_SIZE)
    detail.enchantIcon:EnableMouse(true)
    detail.enchantIcon.texture = detail.enchantIcon:CreateTexture(nil, "OVERLAY")
    detail.enchantIcon.texture:SetAllPoints()
    detail.enchantIcon:SetScript("OnEnter", ShowEnchantTooltip)
    detail.enchantIcon:SetScript("OnLeave", GameTooltip_Hide)
    detail.enchantIcon:Hide()
    detail.gems = {}
    for index = 1, MAX_GEMS do
        local gem = CreateFrame("Frame", nil, detail)
        gem:SetSize(GEM_SIZE, GEM_SIZE)
        gem:EnableMouse(true)
        gem.icon = gem:CreateTexture(nil, "OVERLAY")
        gem.icon:SetAllPoints()
        gem.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        gem:SetScript("OnEnter", ShowGemTooltip)
        gem:SetScript("OnLeave", GameTooltip_Hide)
        gem:Hide()
        detail.gems[index] = gem
    end
    return detail
end
local function GetGemIcon(gemId)
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, gemId)
        if ok and icon then return icon end
    end
    local getIcon = rawget(_G, "GetItemIcon")
    if getIcon then
        local ok, icon = pcall(getIcon, gemId)
        if ok then return icon end
    end
    return nil
end
local function UpdateDetail(detail, entry, db)
    local hasContent = false
    local icon = detail.enchantIcon
    local iconMode = db.enchantDisplay ~= "text"
    icon:Hide()
    icon.texture:Show()
    if entry.missingEnchant and iconMode and db.gearFlags ~= false then
        local r, g, b = GearBadges.GetColor(db, "gearColorEnchant")
        detail.enchant:SetText(ns.L.GEAR_MISSING_ENCHANT or "Missing enchant")
        detail.enchant:SetTextColor(r, g, b)
        hasContent = true
    elseif entry.enchantText and iconMode then
        local atlas = entry.enchantText:match("|A:([^:|]+)")
        icon.enchantId = entry.enchantId
        icon.enchantName = entry.enchantText:gsub("%s*|A:.-|a", ""):match("^%s*(.-)%s*$")
        if atlas and icon.texture.SetAtlas then
            icon.texture:SetTexCoord(0, 1, 0, 1)
            icon.texture:SetAtlas(atlas)
        else
            icon.texture:SetTexture(ENCHANT_FALLBACK_ICON)
            icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        icon:Show()
        detail.enchant:SetText("")
        hasContent = true
    elseif entry.enchantText then
        detail.enchant:SetText(entry.enchantText)
        detail.enchant:SetTextColor(ENCHANT_COLOR[1], ENCHANT_COLOR[2], ENCHANT_COLOR[3])
        hasContent = true
    elseif entry.missingEnchant and not iconMode then
        detail.enchant:SetText(ns.L.GEAR_NO_ENCHANT or "No enchant")
        detail.enchant:SetTextColor(GearBadges.GetColor(db, "gearColorEnchant"))
        hasContent = true
    else
        detail.enchant:SetText("")
    end
    for index, gem in ipairs(detail.gems) do
        local gemId = entry.gems[index]
        if gemId == nil then
            gem:Hide()
        else
            gem.gemId = gemId
            gem.icon:SetTexture(gemId and GetGemIcon(gemId) or EMPTY_SOCKET_TEXTURE)
            gem:Show()
            hasContent = true
        end
    end
    detail:SetShown(hasContent)
end
local LEVEL_INSET = 2
local ITEM_GAP = 3
local ROW_HEIGHT = 16
local PLACE_VERTICAL = { top = "TOP", middle = "", bottom = "BOTTOM" }
local PLACE_INSET = { top = -EDGE_INSET, middle = 0, bottom = EDGE_INSET }
local PLACE_ROW = { bottom = 0, middle = 1, top = 2 }
local PLACE_ORDER = { "top", "middle", "bottom" }
local function ApplyLevelLayout(badge, db)
    local size = db.gearLevelSize or 11
    local anchor = db.gearLevelAnchor or "TOPRIGHT"
    local x, y = db.gearLevelX or 0, db.gearLevelY or 0
    local key = size .. anchor .. x .. ":" .. y
    if badge.levelLayout == key then return end
    badge.levelLayout = key
    badge.level:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    badge.upgrade:SetFont(STANDARD_TEXT_FONT, math.max(6, math.floor(size * 0.8 + 0.5)), "OUTLINE")
end
local function GetUpgradeText(entry, mode)
    if mode == "off" or not entry.trackRank or not entry.trackMax then return nil end
    local rank = string.format("%d/%d", entry.trackRank, entry.trackMax)
    if mode == "rank" or not entry.track then return rank end
    local name = ns.L["TRACK_" .. entry.track:upper()]
    return name and (rank .. " " .. name) or rank
end
local function PlaceOnIcon(badge, db)
    local anchor = db.gearLevelAnchor or "TOPRIGHT"
    local x, y = db.gearLevelX or 0, db.gearLevelY or 0
    local insetX = anchor:find("LEFT") and 1 or (anchor:find("RIGHT") and -1 or 0)
    local insetY = anchor:find("TOP") and -LEVEL_INSET or (anchor:find("BOTTOM") and LEVEL_INSET or 0)
    badge.level:ClearAllPoints()
    badge.level:SetPoint(anchor, badge, anchor, insetX + x, insetY + y)
end
local function PlaceUnderLevel(badge, side, levelBeside)
    local horizontal
    if levelBeside then
        horizontal = side == "left" and "RIGHT" or "LEFT"
    else
        local anchor = ns.db.gearLevelAnchor or "TOPRIGHT"
        horizontal = anchor:match("LEFT") or anchor:match("RIGHT") or ""
        if anchor:find("BOTTOM") then
            badge.upgrade:SetJustifyH(horizontal == "" and "CENTER" or horizontal)
            badge.upgrade:ClearAllPoints()
            badge.upgrade:SetPoint("BOTTOM" .. horizontal, badge.level, "TOP" .. horizontal, 0, 1)
            return
        end
    end
    badge.upgrade:SetJustifyH(horizontal == "" and "CENTER" or horizontal)
    badge.upgrade:ClearAllPoints()
    badge.upgrade:SetPoint("TOP" .. horizontal, badge.level, "BOTTOM" .. horizontal, 0, -1)
end
local function PlaceInChain(region, side, place, previous, button)
    region:ClearAllPoints()
    if side == "top" then
        if previous then
            region:SetPoint("BOTTOMLEFT", previous, "BOTTOMRIGHT", ITEM_GAP, 0)
        else
            region:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, SIDE_GAP + PLACE_ROW[place] * ROW_HEIGHT)
        end
        return
    end
    local vertical = PLACE_VERTICAL[place]
    local near = side == "left" and "RIGHT" or "LEFT"
    local far = side == "left" and "LEFT" or "RIGHT"
    if previous then
        region:SetPoint(vertical .. near, previous, vertical .. far, side == "left" and -ITEM_GAP or ITEM_GAP, 0)
    else
        region:SetPoint(vertical .. near, button, vertical .. far, side == "left" and -SIDE_GAP or SIDE_GAP, PLACE_INSET[place])
    end
end
local chains = { top = {}, middle = {}, bottom = {} }
local function AddToChain(place, region)
    local chain = chains[place]
    if chain then
        chain[#chain + 1] = region
    end
end
local function LayoutSlot(badge, db)
    for _, place in ipairs(PLACE_ORDER) do
        wipe(chains[place])
    end
    local detail = badge.detail
    local side, button = detail.side, detail.button
    local levelPlace = db.gearLevelPlace or "icon"
    local upgradePlace = db.gearUpgradePlace or "under"
    if badge.level:IsShown() then
        if levelPlace == "icon" then
            PlaceOnIcon(badge, db)
        else
            AddToChain(levelPlace, badge.level)
        end
    end
    if badge.upgrade:IsShown() then
        if upgradePlace == "under" then
            PlaceUnderLevel(badge, side, levelPlace ~= "icon")
        else
            badge.upgrade:SetJustifyH("LEFT")
            AddToChain(upgradePlace, badge.upgrade)
        end
    end
    if detail:IsShown() then
        local gemPlace = db.gearGemPlace or "bottom"
        for _, gem in ipairs(detail.gems) do
            if gem:IsShown() then
                AddToChain(gemPlace, gem)
            end
        end
        local enchantPlace = db.gearEnchantPlace or "top"
        if detail.enchantIcon:IsShown() then
            AddToChain(enchantPlace, detail.enchantIcon)
        elseif detail.enchant:GetText() ~= "" then
            AddToChain(enchantPlace, detail.enchant)
        end
    end
    for _, place in ipairs(PLACE_ORDER) do
        local previous
        for _, region in ipairs(chains[place]) do
            PlaceInChain(region, side, place, previous, button)
            previous = region
        end
    end
end
local function GetBadge(slot)
    local badge = badges[slot]
    if badge then return badge end
    local button = rawget(_G, SLOT_BUTTONS[slot])
    if not button then return nil end
    badge = CreateFrame("Frame", nil, button)
    badge:SetAllPoints(button)
    badge:SetFrameLevel(button:GetFrameLevel() + 5)
    badge.level = badge:CreateFontString(nil, "OVERLAY")
    badge.upgrade = badge:CreateFontString(nil, "OVERLAY")
    badge.upgrade:SetWordWrap(false)
    badge.flag = badge:CreateTexture(nil, "OVERLAY")
    badge.flag:SetSize(8, 8)
    badge.flag:SetPoint("TOPLEFT", badge, "TOPLEFT", 2, -2)
    badge.flag:SetTexture("Interface\\Buttons\\WHITE8x8")
    badge.flagMask = badge:CreateMaskTexture()
    badge.flagMask:SetAllPoints(badge.flag)
    badge.flagMask:SetTexture("Interface\\Masks\\CircleMaskScalable", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    badge.flag:AddMaskTexture(badge.flagMask)
    local side = DETAIL_RIGHT[slot] and "right" or "left"
    if WEAPON_SLOTS[slot] and rawget(_G, SLOT_BUTTONS[18]) then
        side = "top"
    end
    badge.detail = CreateDetail(badge, button, side, WEAPON_SLOTS[slot] and WEAPON_DETAIL_WIDTH or DETAIL_WIDTH)
    badges[slot] = badge
    return badge
end
function GearBadges.GetColor(db, key)
    local c = db[key] or ns.DEFAULTS[key]
    return c.r, c.g, c.b
end
local TRACK_COLOR_KEYS = {
    myth = "gearColorMyth",
    crafted = "gearColorCrafted",
    hero = "gearColorHero",
    champion = "gearColorChampion",
    veteran = "gearColorVeteran",
    adventurer = "gearColorAdventurer",
    explorer = "gearColorExplorer",
}
function GearBadges.GetTrackColor(db, track)
    return GearBadges.GetColor(db, TRACK_COLOR_KEYS[track] or "gearColorOther")
end
local function HideAll()
    for _, badge in pairs(badges) do
        badge:Hide()
    end
end
function GearBadges.IsEnabled()
    local db = ns.db
    return db and (db.gearBadges ~= false or db.gearFlags ~= false or db.gearDetails ~= false)
end
function GearBadges.Refresh()
    local db = ns.db
    if not db or not PaperDollFrame or not PaperDollFrame:IsShown() then return end
    local showLevels = db.gearBadges ~= false
    local showFlags = db.gearFlags ~= false
    local showDetails = db.gearDetails ~= false
    if ns.Integrations and ns.Integrations.SlotInfoTaken() then
        HideAll()
        return
    end
    if not showLevels and not showFlags and not showDetails then
        HideAll()
        return
    end
    local results, summary = ns.Gear.Scan()
    for slot in pairs(SLOT_BUTTONS) do
        local badge = GetBadge(slot)
        local entry = results[slot]
        if badge then
            if entry and entry.link then
                if showLevels and entry.itemLevel then
                    ApplyLevelLayout(badge, db)
                    badge.level:SetText(string.format("%d", entry.itemLevel))
                    local r, g, b = GearBadges.GetTrackColor(db, entry.track)
                    badge.level:SetTextColor(r, g, b)
                    badge.level:Show()
                    local upgrade = GetUpgradeText(entry, db.gearUpgradeDisplay)
                    if upgrade then
                        badge.upgrade:SetText(upgrade)
                        badge.upgrade:SetTextColor(r, g, b)
                        badge.upgrade:Show()
                    else
                        badge.upgrade:Hide()
                    end
                else
                    badge.level:Hide()
                    badge.upgrade:Hide()
                end
                local flagKey = nil
                if showFlags and not showDetails then
                    if entry.missingEnchant then
                        flagKey = "gearColorEnchant"
                    elseif entry.emptySockets > 0 then
                        flagKey = "gearColorSocket"
                    end
                end
                if flagKey then
                    local r, g, b = GearBadges.GetColor(db, flagKey)
                    badge.flag:SetVertexColor(r, g, b, 1)
                    badge.flag:Show()
                else
                    badge.flag:Hide()
                end
                if showDetails then
                    UpdateDetail(badge.detail, entry, db)
                else
                    badge.detail:Hide()
                end
                LayoutSlot(badge, db)
                badge:Show()
            else
                badge:Hide()
            end
        end
    end
    if summary.pending and not retryPending then
        retryPending = true
        C_Timer.After(1, function()
            retryPending = false
            GearBadges.Refresh()
        end)
    end
end
function GearBadges.OnEquipmentChanged()
    ns.Gear.Invalidate()
    GearBadges.Refresh()
end
local initialized = false
function GearBadges.Init()
    if initialized or not PaperDollFrame then return end
    initialized = true
    PaperDollFrame:HookScript("OnShow", GearBadges.Refresh)
end
function GearBadges.Apply()
    GearBadges.Init()
    if GearBadges.IsEnabled() then
        GearBadges.Refresh()
    else
        HideAll()
    end
end
