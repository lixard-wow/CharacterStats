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
}
local DETAIL_RIGHT = {
    [1] = true, [2] = true, [3] = true, [15] = true, [5] = true, [9] = true, [17] = true,
}
local GEM_SIZE = 11
local MAX_GEMS = 3
local DETAIL_WIDTH = 105
local WEAPON_DETAIL_WIDTH = 90
local WEAPON_SLOTS = {
    [16] = true, [17] = true,
}
local EMPTY_SOCKET_TEXTURE = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic"
local ENCHANT_COLOR = { 0.35, 0.95, 0.35 }
local badges = {}
local retryPending = false
local ENCHANT_FALLBACK_ICON = "Interface\\Icons\\Trade_Engraving"
local ENCHANT_ICON_SIZE = 14
local function SplitEnchant(text)
    local atlas = text:match("|A:([^:|]+)")
    local name = text:gsub("%s*|A:.-|a", "")
    name = name:match("^%s*(.-)%s*$")
    return name, atlas
end
local function ShowEnchantTooltip(self)
    if not self.enchantName then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.isMissing then
        GameTooltip:SetText(self.enchantName, self.missingR, self.missingG, self.missingB)
        GameTooltip:Show()
        return
    end
    GameTooltip:SetText(self.enchantName, ENCHANT_COLOR[1], ENCHANT_COLOR[2], ENCHANT_COLOR[3])
    if self.enchantAtlas then
        GameTooltip:AddLine(CreateAtlasMarkup and CreateAtlasMarkup(self.enchantAtlas, 16, 16) or "", 1, 1, 1)
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
local function CreateDetail(badge, button, onRight, width)
    local detail = CreateFrame("Frame", nil, badge)
    detail:SetAllPoints(badge)
    detail.enchant = detail:CreateFontString(nil, "OVERLAY")
    detail.enchant:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    detail.enchant:SetWidth(width)
    detail.enchant:SetWordWrap(false)
    if onRight then
        detail.enchant:SetJustifyH("LEFT")
        detail.enchant:SetPoint("LEFT", button, "RIGHT", 5, 0)
    else
        detail.enchant:SetJustifyH("RIGHT")
        detail.enchant:SetPoint("RIGHT", button, "LEFT", -5, 0)
    end
    detail.enchantIcon = CreateFrame("Frame", nil, detail)
    detail.enchantIcon:SetSize(ENCHANT_ICON_SIZE, ENCHANT_ICON_SIZE)
    detail.enchantIcon:EnableMouse(true)
    detail.enchantIcon:SetPoint("CENTER", button, "BOTTOMLEFT", 2, 2)
    detail.enchantIcon.texture = detail.enchantIcon:CreateTexture(nil, "OVERLAY")
    detail.enchantIcon.texture:SetAllPoints()
    detail.enchantIcon.missing = detail.enchantIcon:CreateTexture(nil, "OVERLAY")
    detail.enchantIcon.missing:SetSize(10, 10)
    detail.enchantIcon.missing:SetPoint("CENTER")
    detail.enchantIcon.missing:SetTexture("Interface\\Buttons\\WHITE8x8")
    detail.enchantIcon.missingMask = detail.enchantIcon:CreateMaskTexture()
    detail.enchantIcon.missingMask:SetAllPoints(detail.enchantIcon.missing)
    detail.enchantIcon.missingMask:SetTexture("Interface\\Masks\\CircleMaskScalable", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    detail.enchantIcon.missing:AddMaskTexture(detail.enchantIcon.missingMask)
    detail.enchantIcon.missing:Hide()
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
        gem:SetPoint("CENTER", button, "BOTTOMRIGHT", -2 - (index - 1) * (GEM_SIZE + 1), 2)
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
    icon.isMissing = false
    icon.missing:Hide()
    icon.texture:Show()
    if entry.missingEnchant and iconMode and db.gearFlags ~= false then
        local r, g, b = GearBadges.GetColor(db, "gearColorEnchant")
        icon.isMissing = true
        icon.enchantName = ns.L.GEAR_NO_ENCHANT or "No enchant"
        icon.missingR, icon.missingG, icon.missingB = r, g, b
        icon.texture:Hide()
        icon.missing:SetVertexColor(r, g, b, 1)
        icon.missing:Show()
        icon:Show()
        detail.enchant:SetText(ns.L.GEAR_MISSING_ENCHANT or "Missing enchant")
        detail.enchant:SetTextColor(r, g, b)
        hasContent = true
    elseif entry.enchantText and iconMode then
        local name, atlas = SplitEnchant(entry.enchantText)
        icon.enchantName = name
        icon.enchantAtlas = atlas
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
local function GetBadge(slot)
    local badge = badges[slot]
    if badge then return badge end
    local button = rawget(_G, SLOT_BUTTONS[slot])
    if not button then return nil end
    badge = CreateFrame("Frame", nil, button)
    badge:SetAllPoints(button)
    badge:SetFrameLevel(button:GetFrameLevel() + 5)
    badge.level = badge:CreateFontString(nil, "OVERLAY")
    badge.level:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    badge.level:SetPoint("TOPRIGHT", badge, "TOPRIGHT", -1, -2)
    badge.flag = badge:CreateTexture(nil, "OVERLAY")
    badge.flag:SetSize(8, 8)
    badge.flag:SetPoint("TOPLEFT", badge, "TOPLEFT", 2, -2)
    badge.flag:SetTexture("Interface\\Buttons\\WHITE8x8")
    badge.flagMask = badge:CreateMaskTexture()
    badge.flagMask:SetAllPoints(badge.flag)
    badge.flagMask:SetTexture("Interface\\Masks\\CircleMaskScalable", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    badge.flag:AddMaskTexture(badge.flagMask)
    badge.detail = CreateDetail(badge, button, DETAIL_RIGHT[slot] == true, WEAPON_SLOTS[slot] and WEAPON_DETAIL_WIDTH or DETAIL_WIDTH)
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
                    badge.level:SetText(string.format("%d", entry.itemLevel))
                    badge.level:SetTextColor(GearBadges.GetTrackColor(db, entry.track))
                    badge.level:Show()
                else
                    badge.level:Hide()
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
