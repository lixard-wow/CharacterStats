local addonName, CS = ...
local ConfigPanel = CS.ConfigPanel
local ROW_HEIGHT = 22
local ROW_GAP = 6
local function DisplayName(name)
    if name == "Default" then
        return CS.L.PROFILE_DEFAULT or "Default"
    end
    local className = UnitClass("player")
    if className and CS.GetSpecNames then
        local format = CS.L.PROFILE_SPEC_CLASS or "%s %s"
        for _, specName in ipairs(CS.GetSpecNames()) do
            if name == string.format(format, specName, className) or name == specName .. " " .. className then
                return specName
            end
        end
    end
    return name
end
local function SetButtonEnabled(btn, enabled)
    if enabled then
        btn:Enable()
        CS.ConfigWidgets.ApplyFontColor(btn.text, "textMuted")
    else
        btn:Disable()
        btn.text:SetTextColor(0.4, 0.4, 0.4)
    end
end
local function GetSpecProfileNameSet(specs)
    local set = {}
    for _, specName in ipairs(specs) do
        set[specName] = true
        set[CS.GetSpecProfile(specName)] = true
    end
    return set
end
local function BuildUniqueName(base)
    local taken = {}
    for name in pairs((CS.db and CS.db.profiles) or {}) do
        taken[name:lower()] = true
    end
    local candidate = base
    local i = 2
    while taken[candidate:lower()] do
        candidate = base .. " " .. i
        i = i + 1
    end
    return candidate
end
local function SwitchTo(name)
    CS.SwitchProfile(name)
    ConfigPanel.RefreshAfterProfileChange()
end
local function CreateDropdownRow(parent, labelText, y)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    row:SetHeight(ROW_HEIGHT)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetPoint("RIGHT", row, "CENTER", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)
    CS.ConfigWidgets.ApplyFontColor(label, "textMuted")
    local _, dropdown = CS.ConfigWidgets.CreateDropdown(row, "", 150, { fixedWidth = true })
    dropdown:ClearAllPoints()
    dropdown:SetPoint("LEFT", row, "CENTER", 8, 0)
    dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    dropdown:SetHeight(ROW_HEIGHT)
    return row, label, dropdown
end
local function CreateProfilesPage(container)
    local Widgets = CS.ConfigWidgets
    local L = CS.L
    local page = { specRows = {} }
    local specs = CS.GetSpecNames() or {}
    local _, content = ConfigPanel.CreateScrollPage(container)
    local y = -4
    local header = Widgets.CreateSectionHeader(content, L.HEADER_PROFILES or "Profiles")
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    y = y - 18 - ROW_GAP
    local _, profileLabel, profileDrop = CreateDropdownRow(content, L.LABEL_ACTIVE_PROFILE or "Active Profile", y)
    y = y - ROW_HEIGHT - ROW_GAP
    local buttonRow = CreateFrame("Frame", nil, content)
    buttonRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    buttonRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    buttonRow:SetHeight(ROW_HEIGHT)
    local newBtn = Widgets.CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_NEW or "New")
    local copyBtn = Widgets.CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_COPY or "Copy")
    local deleteBtn = Widgets.CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_DELETE or "Delete")
    local resetBtn = Widgets.CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_RESET or "Reset")
    local buttons = { newBtn, copyBtn, deleteBtn, resetBtn }
    Widgets.NormalizeButtonWidths(buttons, 10)
    for i, btn in ipairs(buttons) do
        if i == 1 then
            btn:SetPoint("LEFT", buttonRow, "CENTER", 8, 0)
        else
            btn:SetPoint("LEFT", buttons[i - 1], "RIGHT", 6, 0)
        end
    end
    y = y - ROW_HEIGHT - 14
    local specHeader = Widgets.CreateSectionHeader(content, L.HEADER_SPEC_PROFILES or "Specialization Profiles")
    specHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    specHeader:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    y = y - 18 - ROW_GAP
    local specCheck = Widgets.CreateToggle(content, L.LABEL_SPEC_AUTO_SWITCH or "Automatically switch by specialization")
    specCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    y = y - 20 - ROW_GAP
    for _, specName in ipairs(specs) do
        local row, label, drop = CreateDropdownRow(content, specName, y)
        page.specRows[#page.specRows + 1] = { specName = specName, row = row, label = label, drop = drop }
        drop:SetCallback(function(value)
            CS.SetSpecProfile(specName, value)
            if specName == CS.GetCurrentSpecName() and CS.IsSpecProfilesEnabled() then
                SwitchTo(value)
            end
            page:Refresh()
        end)
        y = y - ROW_HEIGHT - ROW_GAP
    end
    content:SetHeight(math.abs(y) + 8)
    function page:Refresh()
        local globalItems = {}
        local allItems = {}
        for _, name in ipairs(CS.GetProfileList()) do
            local item = { value = name, text = DisplayName(name) }
            globalItems[#globalItems + 1] = item
            allItems[#allItems + 1] = item
        end
        for _, specName in ipairs(specs) do
            local name = CS.GetSpecProfile(specName)
            local exists = false
            for _, item in ipairs(allItems) do
                if item.value == name then
                    exists = true
                    break
                end
            end
            if not exists then
                allItems[#allItems + 1] = { value = name, text = DisplayName(name) }
            end
        end
        local active = CS.GetActiveProfile()
        profileDrop:SetItems(globalItems)
        profileDrop:SetValue(active, DisplayName(active))
        local specEnabled = CS.IsSpecProfilesEnabled() == true
        specCheck:SetChecked(specEnabled)
        if specEnabled then
            profileDrop:Disable()
            profileLabel:SetTextColor(0.4, 0.4, 0.4)
        else
            profileDrop:Enable()
            Widgets.ApplyFontColor(profileLabel, "textMuted")
        end
        SetButtonEnabled(newBtn, not specEnabled)
        SetButtonEnabled(copyBtn, not specEnabled)
        SetButtonEnabled(deleteBtn, not specEnabled)
        for _, spec in ipairs(self.specRows) do
            spec.drop:SetItems(allItems)
            local name = CS.GetSpecProfile(spec.specName)
            spec.drop:SetValue(name, DisplayName(name))
            if specEnabled then
                spec.drop:Enable()
                Widgets.ApplyFontColor(spec.label, "textMuted")
            else
                spec.drop:Disable()
                spec.label:SetTextColor(0.4, 0.4, 0.4)
            end
        end
    end
    profileDrop:SetCallback(function(value)
        SwitchTo(value)
        page:Refresh()
    end)
    specCheck:SetOnClick(function(self)
        CS.SetSpecProfilesEnabled(self:GetChecked())
        ConfigPanel.RefreshAfterProfileChange()
        page:Refresh()
    end)
    local function IsReservedName(name)
        return GetSpecProfileNameSet(specs)[name] == true
    end
    newBtn:SetScript("OnClick", function()
        Widgets.CreateInputPopup(
            L.POPUP_NEW_PROFILE_TITLE or "New Profile",
            L.POPUP_NEW_PROFILE_DESC or "Enter a name for the new profile.",
            BuildUniqueName(L.PROFILE_NEW_BASE or "New Profile"),
            function(name)
                if IsReservedName(name) or not CS.CreateProfile(name) then
                    return false
                end
                SwitchTo(name)
                page:Refresh()
                return true
            end,
            L.BTN_OK or "OK",
            L.BTN_CANCEL or "Cancel"
        )
    end)
    copyBtn:SetScript("OnClick", function()
        local source = CS.GetActiveProfile()
        Widgets.CreateInputPopup(
            L.POPUP_COPY_PROFILE_TITLE or "Copy Profile",
            L.POPUP_COPY_PROFILE_DESC or "Copy the current profile to a new one.",
            BuildUniqueName(string.format(L.PROFILE_COPY_BASE or "Copy of %s", DisplayName(source))),
            function(name)
                if IsReservedName(name) then
                    return false
                end
                if CS.FlushProfileSave then
                    CS.FlushProfileSave()
                end
                if not CS.CopyProfile(source, name) then
                    return false
                end
                page:Refresh()
                return true
            end,
            L.BTN_OK or "OK",
            L.BTN_CANCEL or "Cancel"
        )
    end)
    deleteBtn:SetScript("OnClick", function()
        local reserved = GetSpecProfileNameSet(specs)
        local deletable = {}
        for _, name in ipairs(CS.GetProfileList()) do
            if name ~= "Default" and not reserved[name] then
                deletable[#deletable + 1] = { value = name, text = DisplayName(name) }
            end
        end
        if #deletable == 0 then
            Widgets.CreatePopup(
                L.POPUP_DELETE_PROFILE_TITLE or "Delete Profile",
                L.POPUP_DELETE_NONE or "No profiles to delete. Default and specialization profiles cannot be deleted.",
                nil,
                L.BTN_OK or "OK",
                nil
            )
            return
        end
        Widgets.CreateSelectPopup(
            L.POPUP_DELETE_PROFILE_TITLE or "Delete Profile",
            L.POPUP_DELETE_SELECT or "Select a profile to delete:",
            deletable,
            deletable[1].value,
            function(name)
                if not name or name == "Default" or reserved[name] or not (CS.db and CS.db.profiles) then
                    return false
                end
                if name == CS.GetActiveProfile() then
                    SwitchTo("Default")
                end
                CS.db.profiles[name] = nil
                page:Refresh()
                return true
            end,
            L.BTN_DELETE or "Delete",
            L.BTN_CANCEL or "Cancel"
        )
    end)
    resetBtn:SetScript("OnClick", function()
        Widgets.CreatePopup(
            L.POPUP_RESET_PROFILES_TITLE or "Reset Profiles",
            L.POPUP_RESET_PROFILES_DESC or "Reset all profiles? This cannot be undone.",
            function()
                if CS.ResetToDefaults then
                    CS.ResetToDefaults()
                    ConfigPanel.RefreshAfterProfileChange()
                    ConfigPanel.RefreshStatsFrame()
                    page:Refresh()
                end
            end,
            L.BTN_RESET or "Reset",
            L.BTN_CANCEL or "Cancel"
        )
    end)
    return page
end
ConfigPanel.RegisterPage("profiles", {
    label = CS.L.NAV_PROFILES or "Profiles",
    labelKey = "NAV_PROFILES",
    order = 4,
    create = CreateProfilesPage,
})
