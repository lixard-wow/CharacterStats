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
local function LevelNotOnIcon(db)
    return db.gearBadges == false or (db.gearLevelPlace or "icon") ~= "icon"
end
local function UpgradeOff(db)
    return db.gearUpgrade ~= true
end
local function UpgradeNotOnIcon(db)
    return db.gearUpgrade ~= true or (db.gearUpgradePlace or "icon") ~= "icon"
end
local function IconPositions(L)
    return {
        { value = "TOPLEFT", text = L.POS_TOPLEFT or "Top Left" },
        { value = "TOP", text = L.POS_TOP or "Top" },
        { value = "TOPRIGHT", text = L.POS_TOPRIGHT or "Top Right" },
        { value = "LEFT", text = L.POS_LEFT or "Left" },
        { value = "CENTER", text = L.POS_CENTER or "Center" },
        { value = "RIGHT", text = L.POS_RIGHT or "Right" },
        { value = "BOTTOMLEFT", text = L.POS_BOTTOMLEFT or "Bottom Left" },
        { value = "BOTTOM", text = L.POS_BOTTOM or "Bottom" },
        { value = "BOTTOMRIGHT", text = L.POS_BOTTOMRIGHT or "Bottom Right" },
    }
end
local function TrackColorsOff(db)
    return db.gearBadges == false and db.gearUpgrade ~= true
end
local function DetailsOff(db)
    return db.gearDetails == false
end
local function SidePlaces(L, first)
    local items = {}
    if first then items[1] = first end
    items[#items + 1] = { value = "top", text = L.PLACE_TOP or "Beside icon, top" }
    items[#items + 1] = { value = "middle", text = L.PLACE_MIDDLE or "Beside icon, middle" }
    items[#items + 1] = { value = "bottom", text = L.PLACE_BOTTOM or "Beside icon, bottom" }
    return items
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
                if CS.CharacterWidth then CS.CharacterWidth.Apply() end
                ApplyGearBadges()
            end,
        },
        {
            kind = "slider", key = "characterFrameExtraWidth", label = L.LABEL_CHARACTER_WIDTH or "Extra Character Frame Width",
            min = 0, max = 120, step = 5, retailOnly = true,
            formatValue = function(v) return string.format("%.0f %s", v, L.UNIT_PX or "px") end,
            onChange = function()
                if CS.CharacterWidth then CS.CharacterWidth.Apply() end
                MarkDirty()
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
        {
            kind = "slider", key = "gearLevelSize", label = L.LABEL_GEAR_LEVEL_SIZE or "Item Level Size",
            min = 6, max = 20, step = 1, format = "%.0f", onChange = ApplyGearBadges, disabled = LevelsOff,
        },
        {
            kind = "dropdown", key = "gearLevelPlace", label = L.LABEL_GEAR_LEVEL_PLACE or "Item Level Placement",
            items = SidePlaces(L, { value = "icon", text = L.PLACE_ICON or "On the icon" }),
            onChange = ApplyGearBadges, disabled = LevelsOff,
        },
        {
            kind = "dropdown", key = "gearLevelAnchor", label = L.LABEL_GEAR_LEVEL_POSITION or "Item Level Position",
            items = IconPositions(L), onChange = ApplyGearBadges, disabled = LevelNotOnIcon,
        },
        {
            kind = "slider", key = "gearLevelX", label = L.LABEL_GEAR_LEVEL_X or "Horizontal Offset",
            min = -20, max = 20, step = 1,
            formatValue = function(v) return string.format("%.0f %s", v, L.UNIT_PX or "px") end,
            onChange = ApplyGearBadges, disabled = LevelNotOnIcon,
        },
        {
            kind = "slider", key = "gearLevelY", label = L.LABEL_GEAR_LEVEL_Y or "Vertical Offset",
            min = -20, max = 20, step = 1,
            formatValue = function(v) return string.format("%.0f %s", v, L.UNIT_PX or "px") end,
            onChange = ApplyGearBadges, disabled = LevelNotOnIcon,
        },
        { kind = "toggle", key = "gearUpgrade", label = L.LABEL_GEAR_UPGRADE_SHOW or "Show Upgrade Level on Gear Slots (4/6 Hero)", fullRow = true, onChange = ApplyGearBadges },
        {
            kind = "dropdown", key = "gearUpgradeDisplay", label = L.LABEL_GEAR_UPGRADE or "Upgrade Level",
            items = {
                { value = "full", text = L.UPGRADE_DISPLAY_FULL or "Rank and track (4/6 Hero)" },
                { value = "rank", text = L.UPGRADE_DISPLAY_RANK or "Rank only (4/6)" },
            },
            onChange = ApplyGearBadges, disabled = UpgradeOff,
        },
        {
            kind = "slider", key = "gearUpgradeSize", label = L.LABEL_GEAR_UPGRADE_SIZE or "Upgrade Level Size",
            min = 6, max = 20, step = 1, format = "%.0f", onChange = ApplyGearBadges, disabled = UpgradeOff,
        },
        {
            kind = "dropdown", key = "gearUpgradePlace", label = L.LABEL_GEAR_UPGRADE_PLACE or "Upgrade Level Placement",
            items = SidePlaces(L, { value = "icon", text = L.PLACE_ICON or "On the icon" }),
            onChange = ApplyGearBadges, disabled = UpgradeOff,
        },
        {
            kind = "dropdown", key = "gearUpgradeAnchor", label = L.LABEL_GEAR_UPGRADE_POSITION or "Upgrade Level Position",
            items = IconPositions(L), onChange = ApplyGearBadges, disabled = UpgradeNotOnIcon,
        },
        {
            kind = "slider", key = "gearUpgradeX", label = L.LABEL_GEAR_LEVEL_X or "Horizontal Offset",
            min = -20, max = 20, step = 1,
            formatValue = function(v) return string.format("%.0f %s", v, L.UNIT_PX or "px") end,
            onChange = ApplyGearBadges, disabled = UpgradeNotOnIcon,
        },
        {
            kind = "slider", key = "gearUpgradeY", label = L.LABEL_GEAR_LEVEL_Y or "Vertical Offset",
            min = -20, max = 20, step = 1,
            formatValue = function(v) return string.format("%.0f %s", v, L.UNIT_PX or "px") end,
            onChange = ApplyGearBadges, disabled = UpgradeNotOnIcon,
        },
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
        {
            kind = "dropdown", key = "gearEnchantPlace", label = L.LABEL_GEAR_ENCHANT_PLACE or "Enchant Placement",
            items = SidePlaces(L), onChange = ApplyGearBadges, disabled = DetailsOff,
        },
        {
            kind = "dropdown", key = "gearGemPlace", label = L.LABEL_GEAR_GEM_PLACE or "Gem Placement",
            items = SidePlaces(L), onChange = ApplyGearBadges, disabled = DetailsOff,
        },
        { kind = "header", label = L.SECTION_GEAR_COLORS or "Gear Slot Colors" },
        { kind = "color", key = "gearColorMyth", label = L.TRACK_MYTH or "Myth", onChange = ApplyGearBadges, disabled = TrackColorsOff },
        { kind = "color", key = "gearColorCrafted", label = L.TRACK_CRAFTED or "Crafted", onChange = ApplyGearBadges, disabled = TrackColorsOff },
        { kind = "color", key = "gearColorHero", label = L.TRACK_HERO or "Hero", onChange = ApplyGearBadges, disabled = TrackColorsOff },
        { kind = "color", key = "gearColorChampion", label = L.TRACK_CHAMPION or "Champion", onChange = ApplyGearBadges, disabled = TrackColorsOff },
        { kind = "color", key = "gearColorVeteran", label = L.TRACK_VETERAN or "Veteran", onChange = ApplyGearBadges, disabled = TrackColorsOff },
        { kind = "color", key = "gearColorAdventurer", label = L.TRACK_ADVENTURER or "Adventurer", onChange = ApplyGearBadges, disabled = TrackColorsOff },
        { kind = "color", key = "gearColorExplorer", label = L.TRACK_EXPLORER or "Explorer", onChange = ApplyGearBadges, disabled = TrackColorsOff },
        { kind = "color", key = "gearColorOther", label = L.TRACK_OTHER or "No Upgrade Track", onChange = ApplyGearBadges, disabled = TrackColorsOff },
        { kind = "color", key = "gearColorEnchant", label = L.LABEL_GEAR_COLOR_ENCHANT or "Missing Enchant", onChange = ApplyGearBadges, disabled = FlagsOff },
        { kind = "color", key = "gearColorSocket", label = L.LABEL_GEAR_COLOR_SOCKET or "Empty Gem Socket Dot", onChange = ApplyGearBadges, disabled = FlagsOff },
    }
end
ConfigPanel.RegisterPage("character", {
    label = CS.L.NAV_CHARACTER or "Character Frame",
    labelKey = "NAV_CHARACTER",
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
                if CS.CharacterWidth then CS.CharacterWidth.Apply() end
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
