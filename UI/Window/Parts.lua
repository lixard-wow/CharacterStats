local ADDON_NAME, ns = ...
local Parts = {}
ns.WindowParts = Parts
Parts.FONTS = "Interface\\AddOns\\CharacterStats\\Media\\Fonts\\"
Parts.SLOT_NAMES = {
    [1] = "HeadSlot", [2] = "NeckSlot", [3] = "ShoulderSlot", [15] = "BackSlot", [5] = "ChestSlot",
    [4] = "ShirtSlot", [19] = "TabardSlot", [9] = "WristSlot", [10] = "HandsSlot", [6] = "WaistSlot",
    [7] = "LegsSlot", [8] = "FeetSlot", [11] = "Finger0Slot", [12] = "Finger1Slot", [13] = "Trinket0Slot",
    [14] = "Trinket1Slot", [16] = "MainHandSlot", [17] = "SecondaryHandSlot",
}
Parts.LEFT = { 1, 2, 3, 15, 5, 4, 19, 9 }
Parts.RIGHT = { 10, 6, 7, 8, 11, 12, 13, 14 }
Parts.WEAPONS = { 16, 17 }
local GEM_SIZE = 13
local ENCHANT_ICON_SIZE = 14
local slots = {}
local function SetFont(fs, file, size, flags)
    ns.Theme.SetFont(fs, file and (Parts.FONTS .. file) or nil, size, flags or "OUTLINE")
end
Parts.SetFont = SetFont
local function SlotLabel(slot)
    local name = Parts.SLOT_NAMES[slot]
    return name and (rawget(_G, name:upper()) or name) or ""
end
local function ShowSlotTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if not GameTooltip:SetInventoryItem("player", self.slot) then
        GameTooltip:SetText(SlotLabel(self.slot), 1, 1, 1)
    end
    GameTooltip:Show()
end
local function OnSlotClick(self, button)
    local slot = self.slot
    if button == "LeftButton" then
        if IsModifiedClick() then
            local link = GetInventoryItemLink("player", slot)
            if link and HandleModifiedItemClick(link) then return end
        end
        PickupInventoryItem(slot)
    elseif button == "RightButton" and IsModifiedClick("EXPANDITEM") then
        if GetInventoryItemLink("player", slot) then
            SocketInventoryItem(slot)
        end
    end
end
local function ShowEnchantTooltip(self)
    if not self.enchantName then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.enchantName, 0.35, 0.95, 0.35)
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
function Parts.CreateSlot(parent, slot, style)
    local size = style.size or 42
    local b = CreateFrame("Button", nil, parent)
    b.slot = slot
    b.style = style
    b:SetSize(size, size)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetColorTexture(0, 0, 0, 0.6)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if style.glow then
        b.glow = b:CreateTexture(nil, "BACKGROUND", nil, -2)
        b.glow:SetTexture(ns.Theme.ART .. "glow_radial")
        b.glow:SetPoint("TOPLEFT", -14, 14)
        b.glow:SetPoint("BOTTOMRIGHT", 14, -14)
        b.glow:SetVertexColor(style.glow[1], style.glow[2], style.glow[3], style.glow[4] or 0.5)
        b.glow:SetBlendMode("ADD")
    end
    b.border = b:CreateTexture(nil, "BORDER")
    b.border:SetAllPoints()
    ns.Theme.Shape(b.border, style.radius)
    b.highlight = b:CreateTexture(nil, "HIGHLIGHT")
    b.highlight:SetPoint("TOPLEFT", 2, -2)
    b.highlight:SetPoint("BOTTOMRIGHT", -2, 2)
    b.highlight:SetColorTexture(1, 1, 1, 0.15)
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cooldown:SetPoint("TOPLEFT", 2, -2)
    b.cooldown:SetPoint("BOTTOMRIGHT", -2, 2)
    local textLayer = CreateFrame("Frame", nil, b)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(b.cooldown:GetFrameLevel() + 2)
    b.ilvl = textLayer:CreateFontString(nil, "OVERLAY")
    SetFont(b.ilvl, style.numberFont, style.ilvlSize or 13)
    b.ilvl:SetPoint("TOP", b, "TOP", 0, -2)
    b.rank = textLayer:CreateFontString(nil, "OVERLAY")
    SetFont(b.rank, style.numberFont, style.rankSize or 11)
    b.rank:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
    local side = style.side or "right"
    local outward = side == "left" and -1 or 1
    local near = side == "left" and "RIGHT" or "LEFT"
    local far = side == "left" and "LEFT" or "RIGHT"
    b.gems = {}
    for i = 1, 3 do
        local gem = CreateFrame("Frame", nil, b)
        gem:SetSize(GEM_SIZE, GEM_SIZE)
        gem:EnableMouse(true)
        gem.icon = gem:CreateTexture(nil, "ARTWORK")
        gem.icon:SetAllPoints()
        gem.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        gem:SetScript("OnEnter", ShowGemTooltip)
        gem:SetScript("OnLeave", GameTooltip_Hide)
        if side == "top" then
            gem:SetPoint("BOTTOMLEFT", b, "TOPLEFT", (i - 1) * (GEM_SIZE + 2), 4)
        elseif i == 1 then
            gem:SetPoint("TOP" .. near, b, "TOP" .. far, outward * 6, -2)
        else
            gem:SetPoint(near, b.gems[i - 1], far, outward * 2, 0)
        end
        gem:Hide()
        b.gems[i] = gem
    end
    b.enchantIcon = CreateFrame("Frame", nil, b)
    b.enchantIcon:SetSize(ENCHANT_ICON_SIZE, ENCHANT_ICON_SIZE)
    b.enchantIcon:EnableMouse(true)
    b.enchantIcon.texture = b.enchantIcon:CreateTexture(nil, "ARTWORK")
    b.enchantIcon.texture:SetAllPoints()
    b.enchantIcon:SetScript("OnEnter", ShowEnchantTooltip)
    b.enchantIcon:SetScript("OnLeave", GameTooltip_Hide)
    b.enchantText = b:CreateFontString(nil, "OVERLAY")
    SetFont(b.enchantText, style.textFont, style.detailSize or 11)
    b.enchantText:SetWordWrap(false)
    if side == "top" then
        b.enchantIcon:SetPoint("BOTTOMRIGHT", b, "TOPRIGHT", 0, 4)
        b.enchantText:SetPoint("BOTTOM", b, "TOP", 0, 22)
    else
        b.enchantIcon:SetPoint("BOTTOM" .. near, b, "BOTTOM" .. far, outward * 6, 2)
        b.enchantText:SetPoint("BOTTOM" .. near, b, "BOTTOM" .. far, outward * 6, 3)
    end
    b.enchantIcon:Hide()
    b:SetScript("OnEnter", ShowSlotTooltip)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnDragStart", function(self) PickupInventoryItem(self.slot) end)
    b:SetScript("OnReceiveDrag", function(self) PickupInventoryItem(self.slot) end)
    b:SetScript("OnClick", OnSlotClick)
    slots[#slots + 1] = b
    return b
end
local function UpgradeText(entry, db)
    if not entry or not entry.trackRank or not entry.trackMax then return nil end
    local rank = string.format("%d/%d", entry.trackRank, entry.trackMax)
    if (db.gearUpgradeDisplay or "rank") == "rank" or not entry.track then return rank end
    local name = ns.L["TRACK_" .. entry.track:upper()]
    return name and (rank .. " " .. name) or rank
end
local function GemIcon(gemId)
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, gemId)
        if ok and icon then return icon end
    end
    return nil
end
function Parts.UpdateSlot(b, entry, db)
    local slot = b.slot
    local style = b.style
    local texture = GetInventoryItemTexture("player", slot)
    if texture then
        b.icon:SetTexture(texture)
    else
        local _, emptyTexture = GetInventorySlotInfo(Parts.SLOT_NAMES[slot])
        b.icon:SetTexture(emptyTexture)
    end
    b.icon:SetDesaturated(IsInventoryItemLocked(slot) and true or false)
    if GetInventoryItemBroken("player", slot) then
        b.icon:SetVertexColor(0.9, 0.1, 0.1)
    else
        b.icon:SetVertexColor(1, 1, 1)
    end
    local quality = texture and GetInventoryItemQuality("player", slot)
    local r, g, bl = 0.25, 0.25, 0.25
    if quality and C_Item and C_Item.GetItemQualityColor then
        r, g, bl = C_Item.GetItemQualityColor(quality)
    elseif style.emptyBorder then
        r, g, bl = style.emptyBorder[1], style.emptyBorder[2], style.emptyBorder[3]
    end
    b.border:SetVertexColor(r, g, bl, texture and 1 or 0.6)
    local glow = rawget(b, "glow")
    if glow then glow:SetShown(texture ~= nil) end
    local start, duration, enable = GetInventoryItemCooldown("player", slot)
    if start and duration and duration > 0 and enable and enable ~= 0 then
        b.cooldown:SetCooldown(start, duration)
    else
        b.cooldown:Clear()
    end
    if style.plain then
        b.ilvl:Hide()
        b.rank:Hide()
        for _, gem in ipairs(b.gems) do gem:Hide() end
        b.enchantIcon:Hide()
        b.enchantText:SetText("")
        return
    end
    local tr, tg, tb = 1, 1, 1
    if entry and ns.GearBadges then
        tr, tg, tb = ns.GearBadges.GetTrackColor(db, entry.track)
    end
    if entry and entry.link and entry.itemLevel then
        b.ilvl:SetText(string.format("%d", entry.itemLevel))
        b.ilvl:SetTextColor(tr, tg, tb)
        b.ilvl:Show()
    else
        b.ilvl:Hide()
    end
    local upgrade = entry and entry.link and UpgradeText(entry, db)
    if upgrade then
        b.rank:SetText(upgrade)
        b.rank:SetTextColor(tr, tg, tb)
        b.rank:Show()
    else
        b.rank:Hide()
    end
    for i, gem in ipairs(b.gems) do
        local gemId = entry and entry.link and entry.gems and entry.gems[i]
        if gemId == nil then
            gem:Hide()
        else
            gem.gemId = gemId or nil
            gem.icon:SetTexture(gemId and GemIcon(gemId) or "Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
            gem:Show()
        end
    end
    b.enchantIcon:Hide()
    b.enchantText:SetText("")
    if entry and entry.link then
        if entry.missingEnchant then
            b.enchantText:SetText(ns.L.GEAR_MISSING_ENCHANT or "Missing enchant")
            local c = style.missingColor or { 0.91, 0.42, 0.32 }
            b.enchantText:SetTextColor(c[1], c[2], c[3])
        elseif entry.enchantText then
            local atlas = entry.enchantText:match("|A:([^:|]+)")
            b.enchantIcon.enchantName = entry.enchantText:gsub("%s*|A:.-|a", ""):match("^%s*(.-)%s*$")
            if atlas and b.enchantIcon.texture.SetAtlas then
                b.enchantIcon.texture:SetAtlas(atlas)
            else
                b.enchantIcon.texture:SetTexture("Interface\\Icons\\Trade_Engraving")
            end
            b.enchantIcon:Show()
        end
    end
end
function Parts.RefreshSlots(owner)
    local db = ns.db
    if not db or not owner.slotButtons then return end
    local results = ns.Gear and ns.Gear.Scan() or {}
    for _, b in ipairs(owner.slotButtons) do
        Parts.UpdateSlot(b, results[b.slot], db)
    end
end
function Parts.UpdateCooldowns(owner)
    if not owner.slotButtons then return end
    for _, b in ipairs(owner.slotButtons) do
        local start, duration, enable = GetInventoryItemCooldown("player", b.slot)
        if start and duration and duration > 0 and enable and enable ~= 0 then
            b.cooldown:SetCooldown(start, duration)
        else
            b.cooldown:Clear()
        end
    end
end
local function TryAutoEquip()
    if CursorHasItem() and C_PaperDollInfo.CanAutoEquipCursorItem() then
        AutoEquipCursorItem()
        return true
    end
    return false
end
function Parts.CreateModel(parent)
    local m = CreateFrame("DressUpModel", nil, parent)
    m.zoom = 1
    m:EnableMouse(true)
    m:EnableMouseWheel(true)
    local function Rotate(self)
        local x = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        self.facing = (self.facing or 0) + (x - (self.lastX or x)) / scale * 0.012
        self.lastX = x
        self:SetFacing(self.facing)
    end
    m:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or TryAutoEquip() then return end
        self.lastX = GetCursorPosition()
        self:SetScript("OnUpdate", Rotate)
    end)
    m:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    m:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    m:SetScript("OnReceiveDrag", TryAutoEquip)
    m:SetScript("OnMouseWheel", function(self, delta)
        self.zoom = math.max(0.55, math.min(1.4, self.zoom - delta * 0.08))
        self:SetCamDistanceScale(self.zoom)
    end)
    function m:Reset()
        self.facing = 0
        self.zoom = 1
        self:SetFacing(0)
        self:SetCamDistanceScale(1)
    end
    function m:Rotate(amount)
        self.facing = (self.facing or 0) + amount
        self:SetFacing(self.facing)
    end
    function m:Load()
        self:SetUnit("player")
        self:SetPortraitZoom(0)
        self:SetCamDistanceScale(self.zoom)
        self:SetFacing(self.facing or 0)
    end
    return m
end
function Parts.CreateStats(parent, opts)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetAllPoints(parent)
    holder.renderer = ns.Styles.CreateListPaperdollRenderer(holder, opts or { bars = true, gearSummary = true })
    holder.renderer:Show()
    function holder:Refresh()
        if ns.Stats and ns.Stats.Invalidate then
            ns.Stats:Invalidate()
        end
        self.renderer:Refresh(ns.db)
    end
    return holder
end
function Parts.GetHeaderInfo()
    local info = {}
    local ok, pvpName = pcall(UnitPVPName, "player")
    info.name = (ok and pvpName) or UnitName("player") or ""
    info.plainName = UnitName("player") or ""
    info.level = UnitLevel("player") or 0
    local className, classFile = UnitClass("player")
    info.className = className or ""
    local color = classFile and C_ClassColor and C_ClassColor.GetClassColor(classFile)
    info.classColor = color or { r = 1, g = 1, b = 1 }
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then
        local _, specName, _, specIcon = GetSpecializationInfo(specIndex)
        info.specName = specName
        info.specIcon = specIcon
    end
    local guild = GetGuildInfo("player")
    info.guild = guild
    local overall, equipped = GetAverageItemLevel()
    info.equipped = equipped or overall or 0
    info.overall = overall or info.equipped
    return info
end
function Parts.SlotLabel(slot)
    return SlotLabel(slot)
end
function Parts.ItemName(slot)
    local link = GetInventoryItemLink("player", slot)
    if not link then return nil end
    local name = link:match("%[(.-)%]")
    return name
end
function Parts.FormatItemLevel(value)
    return string.format("%.2f", value or 0)
end
function Parts.GetTitles()
    local list = { { id = -1, name = PLAYER_TITLE_NONE or "No Title" } }
    for id = 1, GetNumTitles() do
        if IsTitleKnown(id) then
            local name = GetTitleName(id)
            if name and name ~= "" then
                list[#list + 1] = { id = id, name = strtrim(name) }
            end
        end
    end
    table.sort(list, function(a, b)
        if a.id == -1 then return true end
        if b.id == -1 then return false end
        return a.name < b.name
    end)
    return list
end
function Parts.GetEquipmentSets()
    local list = {}
    for _, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs() or {}) do
        local name, icon, setID, isEquipped, numItems, numEquipped, numInInventory, numLost = C_EquipmentSet.GetEquipmentSetInfo(id)
        if name then
            list[#list + 1] = {
                id = setID or id, name = name, icon = icon, equipped = isEquipped,
                missing = numLost or 0, spec = C_EquipmentSet.GetEquipmentSetAssignedSpec(id),
            }
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end
StaticPopupDialogs["CHARACTERSTATS_NEW_EQUIPMENT_SET"] = {
    text = EQUIPMENT_SET_NAME or "Equipment set name",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 16,
    OnAccept = function(self)
        local box = self.editBox or self.EditBox
        local name = box and strtrim(box:GetText() or "")
        if name and name ~= "" then
            local specIndex = GetSpecialization and GetSpecialization()
            local icon = specIndex and select(4, GetSpecializationInfo(specIndex)) or 134400
            C_EquipmentSet.CreateEquipmentSet(name, icon)
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["CHARACTERSTATS_NEW_EQUIPMENT_SET"].OnAccept(parent)
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
StaticPopupDialogs["CHARACTERSTATS_DELETE_EQUIPMENT_SET"] = {
    text = CONFIRM_DELETE_EQUIPMENT_SET or "Delete equipment set %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data then C_EquipmentSet.DeleteEquipmentSet(data) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
StaticPopupDialogs["CHARACTERSTATS_SAVE_EQUIPMENT_SET"] = {
    text = CONFIRM_SAVE_EQUIPMENT_SET or "Save equipment set %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data then C_EquipmentSet.SaveEquipmentSet(data) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
function Parts.EquipSet(id)
    if id and not InCombatLockdown() then
        C_EquipmentSet.UseEquipmentSet(id)
    end
end
function Parts.NewSet()
    StaticPopup_Show("CHARACTERSTATS_NEW_EQUIPMENT_SET")
end
function Parts.SaveSet(id, name)
    if id then StaticPopup_Show("CHARACTERSTATS_SAVE_EQUIPMENT_SET", name, nil, id) end
end
function Parts.DeleteSet(id, name)
    if id then StaticPopup_Show("CHARACTERSTATS_DELETE_EQUIPMENT_SET", name, nil, id) end
end
function Parts.CreateTitlesPane(parent, ui)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)
    pane.list = Parts.CreateList(pane, 22, function(listParent)
        local row = CreateFrame("Button", nil, listParent)
        row.hl = row:CreateTexture(nil, "HIGHLIGHT")
        row.hl:SetAllPoints()
        row.hl:SetColorTexture(1, 1, 1, 0.06)
        row.text = ui.Text(row, ui.bodyFont, 13, ui.text)
        row.text:SetPoint("LEFT", 8, 0)
        row.text:SetPoint("RIGHT", -8, 0)
        row.text:SetJustifyH("LEFT")
        row:SetScript("OnClick", function(self) SetCurrentTitle(self.titleId) end)
        return row
    end, function(row, item)
        row.titleId = item.id
        row.text:SetText(item.name)
        local current = GetCurrentTitle()
        local selected = item.id == current or (item.id == -1 and (current == nil or current <= 0))
        local c = selected and ui.accent or ui.text
        row.text:SetTextColor(c[1], c[2], c[3])
    end)
    function pane:Refresh() self.list:SetData(Parts.GetTitles()) end
    return pane
end
function Parts.CreateSetsPane(parent, ui)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)
    local listHolder = CreateFrame("Frame", nil, pane)
    listHolder:SetPoint("TOPLEFT")
    listHolder:SetPoint("BOTTOMRIGHT", 0, 70)
    pane.list = Parts.CreateList(listHolder, 34, function(listParent)
        local row = CreateFrame("Button", nil, listParent)
        row:RegisterForDrag("LeftButton")
        row.hl = row:CreateTexture(nil, "HIGHLIGHT")
        row.hl:SetAllPoints()
        row.hl:SetColorTexture(1, 1, 1, 0.06)
        row.sel = row:CreateTexture(nil, "BACKGROUND")
        row.sel:SetAllPoints()
        row.sel:SetColorTexture(ui.accent[1], ui.accent[2], ui.accent[3], 0.18)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(26, 26)
        row.icon:SetPoint("LEFT", 6, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.text = ui.Text(row, ui.boldFont, 13, ui.text)
        row.text:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 0)
        row.sub = ui.Text(row, ui.bodyFont, 11, ui.muted)
        row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 0)
        row:SetScript("OnClick", function(self)
            pane.selected = self.setId
            pane.selectedName = self.setName
            pane:Refresh()
        end)
        row:SetScript("OnDoubleClick", function(self) Parts.EquipSet(self.setId) end)
        row:SetScript("OnDragStart", function(self) C_EquipmentSet.PickupEquipmentSet(self.setId) end)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetEquipmentSet(self.setId)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        return row
    end, function(row, item)
        row.setId = item.id
        row.setName = item.name
        row.icon:SetTexture(item.icon)
        row.text:SetText(item.name)
        if item.missing > 0 then
            row.sub:SetText(string.format(ns.L.WINDOW_SET_MISSING or "%d missing", item.missing))
            row.sub:SetTextColor(0.91, 0.42, 0.32)
        else
            row.sub:SetText(item.equipped and (ns.L.WINDOW_SET_EQUIPPED or "Equipped") or "")
            row.sub:SetTextColor(ui.muted[1], ui.muted[2], ui.muted[3])
        end
        row.sel:SetShown(pane.selected == item.id)
    end)
    local width = ui.buttonWidth or 110
    local equip = ui.Button(pane, width, 26, ns.L.WINDOW_SET_EQUIP or "Equip")
    equip:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 6, 38)
    equip:SetScript("OnClick", function() Parts.EquipSet(pane.selected) end)
    local save = ui.Button(pane, width, 26, ns.L.WINDOW_SET_SAVE or "Save")
    save:SetPoint("LEFT", equip, "RIGHT", 6, 0)
    save:SetScript("OnClick", function() Parts.SaveSet(pane.selected, pane.selectedName) end)
    local new = ui.Button(pane, width, 26, ns.L.WINDOW_SET_NEW or "New Set")
    new:SetPoint("TOPLEFT", equip, "BOTTOMLEFT", 0, -6)
    new:SetScript("OnClick", Parts.NewSet)
    local delete = ui.Button(pane, width, 26, ns.L.WINDOW_SET_DELETE or "Delete")
    delete:SetPoint("LEFT", new, "RIGHT", 6, 0)
    delete:SetScript("OnClick", function() Parts.DeleteSet(pane.selected, pane.selectedName) end)
    function pane:Refresh()
        local data = Parts.GetEquipmentSets()
        local found = false
        for _, item in ipairs(data) do
            if item.id == self.selected then found = true end
        end
        if not found then self.selected, self.selectedName = nil, nil end
        self.list:SetData(data)
    end
    return pane
end
function Parts.CreateList(parent, rowHeight, buildRow, fillRow)
    local scroll = ns.ConfigWidgets.CreateScrollFrame(parent)
    local list = { rows = {}, scroll = scroll, content = scroll.content }
    function list:SetData(data)
        local width = parent:GetWidth()
        if width and not (ns.IsSecretValue and ns.IsSecretValue(width)) and width > 1 then self.content:SetWidth(width) end
        for i, item in ipairs(data) do
            local row = self.rows[i]
            if not row then
                row = buildRow(self.content)
                self.rows[i] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -(i - 1) * rowHeight)
            row:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -(i - 1) * rowHeight)
            row:SetHeight(rowHeight)
            fillRow(row, item, i)
            row:Show()
        end
        for i = #data + 1, #self.rows do self.rows[i]:Hide() end
        self.content:SetHeight(math.max(1, #data * rowHeight))
    end
    return list
end
local events = CreateFrame("Frame")
local function RegisterEvents()
    events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    events:RegisterEvent("ITEM_LOCK_CHANGED")
    events:RegisterEvent("BAG_UPDATE_COOLDOWN")
    events:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    events:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    events:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
    events:RegisterEvent("KNOWN_TITLES_UPDATE")
    events:RegisterEvent("UNIT_NAME_UPDATE")
    events:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
    events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    events:RegisterUnitEvent("UNIT_MODEL_CHANGED", "player")
    events:RegisterEvent("UPDATE_FACTION")
    events:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
    events:RegisterEvent("MAJOR_FACTION_UNLOCKED")
    events:RegisterEvent("QUEST_LOG_UPDATE")
end
local refreshQueued = false
events:SetScript("OnEvent", function(_, event)
    if not ns.Window or not ns.Window.IsActive() then return end
    if event == "BAG_UPDATE_COOLDOWN" then
        ns.Window.UpdateCooldowns()
        return
    end
    if event == "PLAYER_EQUIPMENT_CHANGED" and ns.Gear then
        ns.Gear.Invalidate()
    end
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(0.1, function()
        refreshQueued = false
        ns.Window.Refresh()
    end)
end)
RegisterEvents()
