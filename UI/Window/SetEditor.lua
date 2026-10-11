local ADDON_NAME, ns = ...
local Parts = ns.WindowParts
local Editor = {}
ns.WindowSetEditor = Editor
local COLS, ROWS, CELL = 8, 6, 36
local dialog, menu
local icons
local function BuildIcons()
    local list, seen = {}, {}
    local function Add(icon)
        if not icon then return end
        if type(icon) == "string" and not icon:find("[\\/]") then
            icon = "Interface\\Icons\\" .. icon
        end
        if not seen[icon] then
            seen[icon] = true
            list[#list + 1] = icon
        end
    end
    for slot = 1, 19 do
        Add(GetInventoryItemTexture("player", slot))
    end
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then Add(select(4, GetSpecializationInfo(specIndex))) end
    local scratch = {}
    if GetLooseMacroIcons then GetLooseMacroIcons(scratch) end
    if GetMacroIcons then GetMacroIcons(scratch) end
    for _, icon in ipairs(scratch) do Add(icon) end
    wipe(scratch)
    if GetMacroItemIcons then GetMacroItemIcons(scratch) end
    for _, icon in ipairs(scratch) do Add(icon) end
    return list
end
local function Style(frame, ui)
    frame.edge = rawget(frame, "edge") or Parts.Solid(frame, ui.accent, "BACKGROUND", 0)
    frame.edge:SetAllPoints()
    frame.edge:SetColorTexture(ui.accent[1], ui.accent[2], ui.accent[3])
    frame.fill = rawget(frame, "fill") or Parts.Solid(frame, { 0.06, 0.055, 0.05, 0.97 }, "BACKGROUND", 1)
    frame.fill:SetPoint("TOPLEFT", 1, -1)
    frame.fill:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.fill:SetColorTexture(0.06, 0.055, 0.05, 0.97)
end
local function CreateDialog()
    if dialog then return dialog end
    dialog = CreateFrame("Frame", "CharacterStatsSetEditor", UIParent)
    dialog:SetSize(COLS * CELL + 28, ROWS * CELL + 150)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    dialog:EnableMouse(true)
    dialog:SetClampedToScreen(true)
    dialog:Hide()
    dialog.offset = 0
    dialog.icon = false
    dialog.setID = false
    dialog.okUi = false
    tinsert(UISpecialFrames, "CharacterStatsSetEditor")
    dialog.title = dialog:CreateFontString(nil, "OVERLAY")
    dialog.title:SetPoint("TOPLEFT", 14, -12)
    dialog.nameLabel = dialog:CreateFontString(nil, "OVERLAY")
    dialog.nameLabel:SetPoint("TOPLEFT", 14, -38)
    dialog.box = CreateFrame("EditBox", nil, dialog)
    dialog.box:SetSize(COLS * CELL - 46, 24)
    dialog.box:SetPoint("TOPLEFT", 14, -56)
    dialog.box:SetFontObject(GameFontHighlight)
    dialog.box:SetAutoFocus(false)
    dialog.box:EnableMouse(true)
    dialog.box:EnableKeyboard(true)
    dialog.box:SetMaxLetters(16)
    dialog.box:SetTextInsets(6, 6, 0, 0)
    dialog.box:SetTextColor(1, 1, 1)
    dialog.box:SetScript("OnMouseDown", function(self) self:SetFocus() end)
    dialog.box.edge = Parts.Solid(dialog.box, { 0.45, 0.45, 0.45 })
    dialog.box.edge:SetAllPoints()
    dialog.box.bg = Parts.Solid(dialog.box, { 0, 0, 0, 0.85 }, "BACKGROUND", 1)
    dialog.box.bg:SetPoint("TOPLEFT", 1, -1)
    dialog.box.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    dialog.box:SetScript("OnEscapePressed", function() dialog:Hide() end)
    dialog.box:SetScript("OnEnterPressed", function() Editor.Accept() end)
    dialog.preview = dialog:CreateTexture(nil, "ARTWORK")
    dialog.preview:SetSize(32, 32)
    dialog.preview:SetPoint("LEFT", dialog.box, "RIGHT", 10, 0)
    dialog.preview:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    dialog.grid = CreateFrame("Frame", nil, dialog)
    dialog.grid:SetSize(COLS * CELL, ROWS * CELL)
    dialog.grid:SetPoint("TOPLEFT", 14, -92)
    dialog.grid:EnableMouseWheel(true)
    dialog.grid:SetScript("OnMouseWheel", function(_, delta) Editor.Scroll(-delta) end)
    dialog.cells = {}
    for i = 1, COLS * ROWS do
        local cell = CreateFrame("Button", nil, dialog.grid)
        cell:SetSize(CELL - 4, CELL - 4)
        cell:SetPoint("TOPLEFT", ((i - 1) % COLS) * CELL + 2, -math.floor((i - 1) / COLS) * CELL - 2)
        cell.icon = cell:CreateTexture(nil, "ARTWORK")
        cell.icon:SetAllPoints()
        cell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        cell.sel = Parts.Solid(cell, { 1, 0.82, 0, 1 }, "OVERLAY")
        cell.sel:SetPoint("TOPLEFT", -2, 2)
        cell.sel:SetPoint("BOTTOMRIGHT", 2, -2)
        cell.sel:SetDrawLayer("BACKGROUND")
        cell.hl = cell:CreateTexture(nil, "HIGHLIGHT")
        cell.hl:SetAllPoints()
        cell.hl:SetColorTexture(1, 1, 1, 0.2)
        cell:SetScript("OnClick", function(self)
            dialog.icon = self.iconValue
            Editor.Render()
        end)
        dialog.cells[i] = cell
    end
    dialog.pos = dialog:CreateFontString(nil, "OVERLAY")
    dialog.pos:SetPoint("TOPRIGHT", dialog.grid, "BOTTOMRIGHT", 0, -6)
    return dialog
end
function Editor.Scroll(rows)
    if not dialog or not icons then return end
    local maxOffset = math.max(0, math.ceil(#icons / COLS) - ROWS)
    dialog.offset = math.max(0, math.min(maxOffset, (dialog.offset or 0) + rows * 2))
    Editor.Render()
end
function Editor.Render()
    local start = (dialog.offset or 0) * COLS
    for i, cell in ipairs(dialog.cells) do
        local icon = icons[start + i]
        cell.iconValue = icon
        if icon then
            cell.icon:SetTexture(icon)
            cell.sel:SetShown(icon == dialog.icon)
            cell:Show()
        else
            cell:Hide()
        end
    end
    dialog.preview:SetTexture(dialog.icon or 134400)
    local totalRows = math.ceil(#icons / COLS)
    dialog.pos:SetText(string.format("%d / %d", math.min(totalRows, (dialog.offset or 0) + ROWS), totalRows))
end
function Editor.Accept()
    local name = strtrim(dialog.box:GetText() or "")
    if name == "" then return end
    local icon = dialog.icon or 134400
    if dialog.setID then
        C_EquipmentSet.ModifyEquipmentSet(dialog.setID, name, icon)
    else
        if C_EquipmentSet.GetEquipmentSetID(name) then
            UIErrorsFrame:AddMessage(EQUIPMENT_SETS_TOO_MANY or "A set with that name already exists.", 1, 0.1, 0.1, 1)
            return
        end
        C_EquipmentSet.CreateEquipmentSet(name, icon)
    end
    dialog:Hide()
end
function Editor.Open(setID, ui)
    CreateDialog()
    icons = BuildIcons()
    Style(dialog, ui)
    local function Font(fs, size, font, color)
        Parts.SetFont(fs, font, size, "")
        fs:SetTextColor(color[1], color[2], color[3])
    end
    Font(dialog.title, 16, ui.headerFont or ui.boldFont, { 1, 0.82, 0.35 })
    Font(dialog.nameLabel, 12, ui.bodyFont, { 0.72, 0.70, 0.66 })
    Font(dialog.pos, 11, ui.bodyFont, { 0.72, 0.70, 0.66 })
    dialog.nameLabel:SetText(ns.L.WINDOW_SET_NAME or "Name")
    if dialog.okUi ~= ui then
        if rawget(dialog, "ok") then dialog.ok:Hide() dialog.cancel:Hide() end
        dialog.okUi = ui
        dialog.ok = ui.Button(dialog, 110, 26, ACCEPT or "Okay")
        dialog.ok:SetPoint("BOTTOMRIGHT", -14, 12)
        dialog.ok:SetScript("OnClick", Editor.Accept)
        dialog.cancel = ui.Button(dialog, 110, 26, CANCEL or "Cancel")
        dialog.cancel:SetPoint("RIGHT", dialog.ok, "LEFT", -6, 0)
        dialog.cancel:SetScript("OnClick", function() dialog:Hide() end)
    end
    dialog.setID = setID or false
    if setID then
        local name, icon = C_EquipmentSet.GetEquipmentSetInfo(setID)
        dialog.title:SetText(ns.L.WINDOW_SET_EDIT or "Edit Equipment Set")
        dialog.box:SetText(name or "")
        dialog.icon = icon
    else
        dialog.title:SetText(ns.L.WINDOW_SET_NEW or "New Set")
        dialog.box:SetText("")
        dialog.icon = icons[1]
    end
    dialog.offset = 0
    dialog:ClearAllPoints()
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    dialog:Show()
    Editor.Render()
    dialog.box:SetFocus()
    C_Timer.After(0, function()
        if dialog:IsShown() then dialog.box:SetFocus() end
    end)
end
local function CreateMenu()
    if menu then return menu end
    menu = CreateFrame("Frame", "CharacterStatsSetMenu", UIParent)
    menu:SetFrameStrata("DIALOG")
    menu:SetToplevel(true)
    menu:EnableMouse(true)
    menu:SetClampedToScreen(true)
    menu:Hide()
    tinsert(UISpecialFrames, "CharacterStatsSetMenu")
    menu.items = {}
    menu:SetScript("OnLeave", function(self)
        C_Timer.After(0.4, function()
            if self:IsShown() and not self:IsMouseOver() then self:Hide() end
        end)
    end)
    return menu
end
function Editor.OpenMenu(anchor, setID, ui, onChange)
    CreateMenu()
    Style(menu, ui)
    local entries = {
        { text = ns.L.WINDOW_SET_EDIT or "Edit Equipment Set", run = function() Editor.Open(setID, ui) end },
        { header = ns.L.WINDOW_SET_ASSIGN or "Assign to specialization" },
    }
    local assigned = C_EquipmentSet.GetEquipmentSetAssignedSpec(setID)
    for i = 1, (GetNumSpecializations and GetNumSpecializations() or 0) do
        local _, specName, _, specIcon = GetSpecializationInfo(i)
        entries[#entries + 1] = {
            text = specName, icon = specIcon, checked = assigned == i,
            run = function() C_EquipmentSet.AssignSpecToEquipmentSet(setID, i) end,
        }
    end
    entries[#entries + 1] = {
        text = NONE or "None", checked = assigned == nil,
        run = function() C_EquipmentSet.UnassignEquipmentSetSpec(setID) end,
    }
    local y = -6
    for i, entry in ipairs(entries) do
        local item = menu.items[i]
        if not item then
            item = CreateFrame("Button", nil, menu)
            item:SetHeight(22)
            item.hl = item:CreateTexture(nil, "HIGHLIGHT")
            item.hl:SetAllPoints()
            item.hl:SetColorTexture(1, 1, 1, 0.08)
            item.mark = Parts.Solid(item, { 1, 1, 1 }, "ARTWORK")
            item.mark:SetSize(8, 8)
            item.mark:SetPoint("LEFT", 8, 0)
            item.icon = item:CreateTexture(nil, "ARTWORK")
            item.icon:SetSize(16, 16)
            item.icon:SetPoint("LEFT", 22, 0)
            item.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            item.text = item:CreateFontString(nil, "OVERLAY")
            menu.items[i] = item
        end
        item:ClearAllPoints()
        item:SetPoint("TOPLEFT", 4, y)
        item:SetPoint("TOPRIGHT", -4, y)
        Parts.SetFont(item.text, entry.header and (ui.headerFont or ui.boldFont) or ui.bodyFont, entry.header and 12 or 13, "")
        local c = entry.header and { 1, 0.82, 0.35 } or { 0.92, 0.90, 0.85 }
        item.text:SetTextColor(c[1], c[2], c[3])
        item.text:SetText(entry.text or entry.header)
        item.text:ClearAllPoints()
        item.text:SetPoint("LEFT", item, "LEFT", entry.icon and 44 or (entry.checked ~= nil and 22 or 8), 0)
        item.icon:SetShown(entry.icon ~= nil)
        if entry.icon then item.icon:SetTexture(entry.icon) end
        item.mark:SetShown(entry.checked == true)
        item.mark:SetColorTexture(ui.accent[1], ui.accent[2], ui.accent[3])
        item:EnableMouse(entry.run ~= nil)
        item:SetScript("OnClick", function()
            menu:Hide()
            if entry.run then entry.run() end
            if onChange then onChange() end
        end)
        item:Show()
        y = y - 22
    end
    for i = #entries + 1, #menu.items do menu.items[i]:Hide() end
    menu:SetSize(220, -y + 6)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, 0)
    menu:Show()
end
