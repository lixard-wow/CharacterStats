local addonName, CS = ...
local ConfigPanel = CS.ConfigPanel
local function MarkDirty()
    if CS.MarkProfileDirty then
        CS.MarkProfileDirty()
    end
end
local function ApplyGearBadges()
    if CS.GearBadges then
        CS.GearBadges.Apply()
    end
    if CS.PaperdollPanel then
        CS.PaperdollPanel:Refresh()
    end
    MarkDirty()
end
local function LevelsOff(db)
    return db.gearBadges == false
end
local function FlagsOff(db)
    return db.gearFlags == false
end
local function BuildEntries(L)
    return {
        { kind = "header", label = L.SECTION_CHARACTER_PANEL or "Character Panel" },
        {
            kind = "toggle", key = "paperdollEnabled", label = L.LABEL_PAPERDOLL or "Replace Paperdoll Stats", fullRow = true,
            onChange = function(value)
                if CS.PaperdollPanel then
                    if value then CS.PaperdollPanel:Init() else CS.PaperdollPanel:Detach() end
                end
                MarkDirty()
            end,
        },
        {
            kind = "toggle", key = "characterButton", label = L.LABEL_CHARACTER_BUTTON or "Show Options Button on Character Frame", fullRow = true,
            onChange = function()
                if CS.CharacterButton then
                    CS.CharacterButton.Apply()
                end
                MarkDirty()
            end,
        },
        {
            kind = "toggle", key = "yieldToOtherAddons", label = L.LABEL_YIELD or "Check for Conflicting Character Frame Addons", fullRow = true,
            onChange = function()
                if CS.PaperdollPanel then CS.PaperdollPanel:ApplyStyle() end
                if CS.CharacterButton then CS.CharacterButton.Apply() end
                ApplyGearBadges()
            end,
        },
        {
            kind = "slider", key = "paperdollBarHeight", label = L.LABEL_PAPERDOLL_BAR_HEIGHT or "Stat Bar Thickness",
            min = 1, max = 10, step = 1,
            formatValue = function(v) return string.format("%.0f %s", v, L.UNIT_PX or "px") end,
            disabled = function() return CS.Styles.GetActive().id ~= "meters" end,
            onChange = function()
                if CS.PaperdollPanel then CS.PaperdollPanel:Refresh() end
                MarkDirty()
            end,
        },
        { kind = "header", label = L.SECTION_GEAR_SLOTS or "Gear Slots" },
        { kind = "toggle", key = "gearBadges", label = L.LABEL_GEAR_BADGES or "Show Item Level on Gear Slots", fullRow = true, onChange = ApplyGearBadges },
        { kind = "toggle", key = "gearFlags", label = L.LABEL_GEAR_FLAGS or "Flag Missing Enchants and Empty Gem Sockets", fullRow = true, onChange = ApplyGearBadges },
        { kind = "toggle", key = "gearDetails", label = L.LABEL_GEAR_DETAILS or "Show Enchants and Gems Next to Gear Slots", fullRow = true, onChange = ApplyGearBadges },
        {
            kind = "dropdown", key = "enchantDisplay", label = L.LABEL_ENCHANT_DISPLAY or "Show Enchants As",
            items = {
                { value = "icon", text = L.ENCHANT_DISPLAY_ICON or "Quality icon (name on hover)" },
                { value = "text", text = L.ENCHANT_DISPLAY_TEXT or "Enchant name" },
            },
            onChange = ApplyGearBadges,
            disabled = function(db) return db.gearDetails == false end,
        },
        { kind = "header", label = L.SECTION_GEAR_COLORS or "Gear Slot Colors" },
        { kind = "color", key = "gearColorMyth", label = L.TRACK_MYTH or "Myth", onChange = ApplyGearBadges, disabled = LevelsOff },
        { kind = "color", key = "gearColorCrafted", label = L.TRACK_CRAFTED or "Crafted", onChange = ApplyGearBadges, disabled = LevelsOff },
        { kind = "color", key = "gearColorHero", label = L.TRACK_HERO or "Hero", onChange = ApplyGearBadges, disabled = LevelsOff },
        { kind = "color", key = "gearColorChampion", label = L.TRACK_CHAMPION or "Champion", onChange = ApplyGearBadges, disabled = LevelsOff },
        { kind = "color", key = "gearColorVeteran", label = L.TRACK_VETERAN or "Veteran", onChange = ApplyGearBadges, disabled = LevelsOff },
        { kind = "color", key = "gearColorAdventurer", label = L.TRACK_ADVENTURER or "Adventurer", onChange = ApplyGearBadges, disabled = LevelsOff },
        { kind = "color", key = "gearColorExplorer", label = L.TRACK_EXPLORER or "Explorer", onChange = ApplyGearBadges, disabled = LevelsOff },
        { kind = "color", key = "gearColorOther", label = L.TRACK_OTHER or "No Upgrade Track", onChange = ApplyGearBadges, disabled = LevelsOff },
        { kind = "color", key = "gearColorEnchant", label = L.LABEL_GEAR_COLOR_ENCHANT or "Missing Enchant", onChange = ApplyGearBadges, disabled = FlagsOff },
        { kind = "color", key = "gearColorSocket", label = L.LABEL_GEAR_COLOR_SOCKET or "Empty Gem Socket Dot", onChange = ApplyGearBadges, disabled = FlagsOff },
    }
end
ConfigPanel.RegisterPage("character", {
    label = CS.L.NAV_CHARACTER or "Character Frame",
    order = 3.5,
    create = function(container)
        local _, content = ConfigPanel.CreateScrollPage(container)
        local page = CS.ConfigBuilder.Build(content, BuildEntries(CS.L), {
            onChange = ConfigPanel.RefreshStatsFrame,
        })
        local hint = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -page.height)
        hint:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        hint:SetJustifyH("LEFT")
        hint:SetText(CS.L.HINT_GEAR_COLORS or "Item level numbers are colored by upgrade track.")
        CS.ConfigWidgets.ApplyFontColor(hint, "textMuted", 0.8)
        local status = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        status:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -10)
        status:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        status:SetJustifyH("LEFT")
        local checkButton = CS.ConfigWidgets.CreateFlatButton(content, 120, 22, CS.L.CONFLICT_CHECK_NOW or "Check Again")
        local resetButton = CS.ConfigWidgets.CreateFlatButton(content, 120, 22, CS.L.CONFLICT_RESET or "Reset Keep-Both Choices")
        CS.ConfigWidgets.NormalizeButtonWidths({ checkButton, resetButton }, 10)
        checkButton:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -10)
        resetButton:SetPoint("LEFT", checkButton, "RIGHT", 6, 0)
        checkButton:SetScript("OnClick", function()
            if not (CS.Integrations and CS.Integrations.ShowConflictPopup()) then
                CS.PrintMsg(CS.L.CONFLICT_NONE_ACTIVE or "No conflicts with CharacterStats' current settings.")
            end
        end)
        resetButton:SetScript("OnClick", function()
            if CS.Integrations then
                CS.Integrations.ResetIgnored()
                if CS.PaperdollPanel then CS.PaperdollPanel:ApplyStyle() end
                if CS.GearBadges then CS.GearBadges.Apply() end
                if CS.CharacterButton then CS.CharacterButton.Apply() end
            end
            page:Refresh()
        end)
        content:SetHeight(page.height + 160)
        local baseRefresh = page.Refresh
        function page:Refresh()
            baseRefresh(self)
            local L = CS.L
            local found = CS.Integrations and CS.Integrations.Describe() or {}
            if #found == 0 then
                status:SetText(L.CONFLICT_NONE or "No other character frame addons detected.")
                CS.ConfigWidgets.ApplyFontColor(status, "textMuted", 0.8)
                return
            end
            local lines = { L.CONFLICT_HEADER or "Detected character frame addons:" }
            for _, rule in ipairs(found) do
                local state = CS.Integrations.IsIgnored(rule) and (L.CONFLICT_STATE_KEPT or "keeping both") or (L.CONFLICT_STATE_YIELD or "CharacterStats steps aside")
                lines[#lines + 1] = string.format("  %s - %s (%s)", rule.name, CS.Integrations.KindLabel(rule.kind), state)
            end
            status:SetText(table.concat(lines, "\n"))
            CS.ConfigWidgets.ApplyFontColor(status, "textPrimary", 0.9)
        end
        return page
    end,
})
