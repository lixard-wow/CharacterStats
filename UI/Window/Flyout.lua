local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local Flyout = {}
ns.WindowFlyout = Flyout
local SIZE = 36
local GAP = 4
local PER_ROW = 5
local PER_PAGE = 20
local PLACE_IN_BAGS = -1
local frame
local hovered
local locations = {}
local scratch = {}
local function CombatBlocked(slot)
    return UnitAffectingCombat("player") and not (INVSLOTS_EQUIPABLE_IN_COMBAT and INVSLOTS_EQUIPABLE_IN_COMBAT[slot])
end
local function OnItemClick(self)
    local slot = frame.slotButton and frame.slotButton.slot
    if not slot or not self.location then return end
    if CombatBlocked(slot) then
        UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1, 0.1, 0.1, 1)
        return
    end
    local action
    if self.location == PLACE_IN_BAGS then
        action = EquipmentManager_UnequipItemInSlot(slot)
    else
        action = EquipmentManager_EquipItemByLocation(self.location, slot)
    end
    if action then
        EquipmentManager_RunAction(action)
    end
    frame:Hide()
end
local function OnItemEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.location == PLACE_IN_BAGS then
        GameTooltip:SetText(EQUIPMENT_MANAGER_PLACE_IN_BAGS or "Place in bags", 1, 1, 1)
    elseif self.setTooltip then
        self.setTooltip()
    end
    GameTooltip:Show()
end
local function CreateItemButton(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(SIZE, SIZE)
    b.border = Parts.Solid(b, { 1, 1, 1 }, "BORDER")
    b.border:SetAllPoints()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.hl = b:CreateTexture(nil, "HIGHLIGHT")
    b.hl:SetAllPoints(b.icon)
    b.hl:SetColorTexture(1, 1, 1, 0.18)
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cooldown:SetAllPoints(b.icon)
    b.count = b:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(b.count, nil, 11, "OUTLINE")
    b.count:SetPoint("BOTTOMRIGHT", -2, 2)
    b.ilvl = b:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(b.ilvl, nil, 11, "OUTLINE")
    b.ilvl:SetPoint("TOP", 0, -2)
    b:SetScript("OnClick", OnItemClick)
    b:SetScript("OnEnter", OnItemEnter)
    b:SetScript("OnLeave", function()
        GameTooltip:Hide()
        Flyout.ScheduleHide()
    end)
    return b
end
local function Create()
    if frame then return frame end
    frame = CreateFrame("Frame", "CharacterStatsWindowFlyout", UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame.edge = Parts.Solid(frame, { 0.79, 0.63, 0.29 }, "BACKGROUND", 0)
    frame.edge:SetAllPoints()
    frame.fill = Parts.Solid(frame, { 0.06, 0.055, 0.05, 0.96 }, "BACKGROUND", 1)
    frame.fill:SetPoint("TOPLEFT", 1, -1)
    frame.fill:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.buttons = {}
    frame.prev = CreateFrame("Button", nil, frame)
    frame.prev:SetSize(20, 18)
    frame.prev.text = frame.prev:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(frame.prev.text, nil, 13, "OUTLINE")
    frame.prev.text:SetPoint("CENTER")
    frame.prev.text:SetText("<")
    frame.prev:SetScript("OnClick", function() Flyout.Page(-1) end)
    frame.next = CreateFrame("Button", nil, frame)
    frame.next:SetSize(20, 18)
    frame.next.text = frame.next:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(frame.next.text, nil, 13, "OUTLINE")
    frame.next.text:SetPoint("CENTER")
    frame.next.text:SetText(">")
    frame.next:SetScript("OnClick", function() Flyout.Page(1) end)
    frame.pageText = frame:CreateFontString(nil, "OVERLAY")
    Parts.SetFont(frame.pageText, nil, 11, "OUTLINE")
    frame:SetScript("OnLeave", Flyout.ScheduleHide)
    frame:SetScript("OnHide", function() frame.slotButton = nil end)
    frame:Hide()
    return frame
end
local function Collect(slot)
    wipe(locations)
    wipe(scratch)
    GetInventoryItemsForSlot(slot, scratch)
    for location in pairs(scratch) do
        if (location - slot) ~= ITEM_INVENTORY_LOCATION_PLAYER then
            locations[#locations + 1] = location
        end
    end
    table.sort(locations)
    if GetInventoryItemID("player", slot) then
        locations[#locations + 1] = PLACE_IN_BAGS
    end
end
local function Layout()
    local total = #locations
    local pages = math.max(1, math.ceil(total / PER_PAGE))
    frame.page = math.max(1, math.min(frame.page or 1, pages))
    local first = (frame.page - 1) * PER_PAGE + 1
    local count = math.min(PER_PAGE, total - first + 1)
    for i = 1, count do
        local b = frame.buttons[i]
        if not b then
            b = CreateItemButton(frame)
            frame.buttons[i] = b
        end
        local location = locations[first + i - 1]
        b.location = location
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", 6 + ((i - 1) % PER_ROW) * (SIZE + GAP), -6 - math.floor((i - 1) / PER_ROW) * (SIZE + GAP))
        b.count:SetText("")
        b.ilvl:SetText("")
        b.cooldown:Clear()
        if location == PLACE_IN_BAGS then
            b.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
            b.icon:SetVertexColor(1, 1, 1)
            b.border:SetColorTexture(0.5, 0.5, 0.5)
            b.setTooltip = nil
        else
            local itemID, _, texture, stack, durability, maxDurability, _, locked, start, duration, enable, setTooltip, quality = EquipmentManager_GetItemInfoByLocation(location)
            b.icon:SetTexture(texture)
            b.icon:SetDesaturated(locked and true or false)
            if maxDurability and durability == 0 then
                b.icon:SetVertexColor(0.9, 0, 0)
            else
                b.icon:SetVertexColor(1, 1, 1)
            end
            local r, g, bl = 0.4, 0.4, 0.4
            if quality and C_Item and C_Item.GetItemQualityColor then
                r, g, bl = C_Item.GetItemQualityColor(quality)
            end
            b.border:SetColorTexture(r, g, bl)
            if stack and stack > 1 then b.count:SetText(stack) end
            if start and duration and duration > 0 and enable and enable ~= 0 then
                b.cooldown:SetCooldown(start, duration)
            end
            local data = EquipmentManager_GetLocationData and EquipmentManager_GetLocationData(location)
            if data and data.isBags and C_Item.GetCurrentItemLevel and ItemLocation and ItemLocation.CreateFromBagAndSlot then
                local loc = ItemLocation:CreateFromBagAndSlot(data.bag, data.slot)
                if loc and loc:IsValid() then
                    local ok, level = pcall(C_Item.GetCurrentItemLevel, loc)
                    if ok and level then b.ilvl:SetText(level) end
                end
            end
            b.setTooltip = setTooltip
            b.itemID = itemID
        end
        b:Show()
    end
    for i = count + 1, #frame.buttons do frame.buttons[i]:Hide() end
    local cols = math.min(PER_ROW, math.max(1, count))
    local rows = math.max(1, math.ceil(count / PER_ROW))
    local width = 12 + cols * SIZE + (cols - 1) * GAP
    local height = 12 + rows * SIZE + (rows - 1) * GAP
    local paged = pages > 1
    frame.prev:SetShown(paged)
    frame.next:SetShown(paged)
    frame.pageText:SetShown(paged)
    if paged then
        width = math.max(width, 12 + PER_ROW * SIZE + (PER_ROW - 1) * GAP)
        height = height + 22
        frame.prev:ClearAllPoints()
        frame.prev:SetPoint("BOTTOMLEFT", 6, 4)
        frame.next:ClearAllPoints()
        frame.next:SetPoint("BOTTOMRIGHT", -6, 4)
        frame.pageText:ClearAllPoints()
        frame.pageText:SetPoint("BOTTOM", 0, 7)
        frame.pageText:SetText(string.format("%d / %d", frame.page, pages))
        frame.prev:SetEnabled(frame.page > 1)
        frame.next:SetEnabled(frame.page < pages)
    end
    frame:SetSize(width, height)
end
function Flyout.Page(delta)
    if not frame or not frame:IsShown() then return end
    frame.page = (frame.page or 1) + delta
    Layout()
end
function Flyout.Show(slotButton)
    Create()
    local slot = slotButton.slot
    Collect(slot)
    if #locations == 0 then
        frame:Hide()
        return
    end
    if frame.slotButton ~= slotButton then frame.page = 1 end
    frame.slotButton = slotButton
    local edge = slotButton.style and slotButton.style.flyoutEdge
    if edge then frame.edge:SetColorTexture(edge[1], edge[2], edge[3]) end
    local fill = slotButton.style and slotButton.style.flyoutFill
    if fill then frame.fill:SetColorTexture(fill[1], fill[2], fill[3], fill[4] or 0.96) end
    Layout()
    frame:ClearAllPoints()
    local side = slotButton.style and slotButton.style.side or "right"
    if side == "left" then
        frame:SetPoint("TOPRIGHT", slotButton, "TOPLEFT", -4, 0)
    elseif side == "top" then
        frame:SetPoint("BOTTOMLEFT", slotButton, "TOPLEFT", 0, 4)
    else
        frame:SetPoint("TOPLEFT", slotButton, "TOPRIGHT", 4, 0)
    end
    frame:Show()
end
function Flyout.Hide()
    if frame then frame:Hide() end
end
function Flyout.ScheduleHide()
    C_Timer.After(0.15, function()
        if not frame or not frame:IsShown() then return end
        if frame:IsMouseOver() then return end
        if frame.slotButton and frame.slotButton:IsMouseOver() and IsModifiedClick("SHOWITEMFLYOUT") then return end
        frame:Hide()
    end)
end
function Flyout.OnSlotEnter(slotButton)
    hovered = slotButton
    if IsModifiedClick("SHOWITEMFLYOUT") then
        Flyout.Show(slotButton)
    end
end
function Flyout.OnSlotLeave(slotButton)
    if hovered == slotButton then hovered = nil end
    Flyout.ScheduleHide()
end
local events = CreateFrame("Frame")
events:RegisterEvent("MODIFIER_STATE_CHANGED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if event == "MODIFIER_STATE_CHANGED" then
        if hovered and hovered:IsVisible() and hovered:IsMouseOver() then
            if IsModifiedClick("SHOWITEMFLYOUT") then
                Flyout.Show(hovered)
            elseif frame and frame:IsShown() and not frame:IsMouseOver() then
                frame:Hide()
            end
        end
        return
    end
    if frame and frame:IsShown() and frame.slotButton then
        Flyout.Show(frame.slotButton)
    end
end)
