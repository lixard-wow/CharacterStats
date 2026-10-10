local addonName, CS = ...
local ConfigPanel = CS.ConfigPanel
local function MarkDirty()
    if CS.MarkProfileDirty then
        CS.MarkProfileDirty()
    end
end
local function BuildEntries(L)
    return {
        { kind = "header", label = L.SECTION_BEHAVIOR or "Behavior" },
        {
            kind = "toggle", key = "showFrame", label = L.LABEL_SHOW_FRAME or "Show Stats Frame",
            onChange = function(value)
                if CS.StatsFrame then
                    if value then CS.StatsFrame:Show() else CS.StatsFrame:Hide() end
                end
                MarkDirty()
            end,
        },
        { kind = "toggle", key = "locked", label = L.LABEL_LOCK or "Lock Position" },
        {
            kind = "toggle", key = "clampToScreen", label = L.LABEL_CLAMP or "Clamp to Screen",
            onChange = function(value)
                local f = CS.StatsFrame and CS.StatsFrame.GetFrame and CS.StatsFrame:GetFrame()
                if f then f:SetClampedToScreen(value) end
                MarkDirty()
            end,
        },
        {
            kind = "toggle", key = "showMinimapButton", label = L.LABEL_SHOW_MINIMAP or "Show Minimap Button",
            onChange = function(value)
                if CS.MinimapButton then
                    if value then CS.MinimapButton:Show() else CS.MinimapButton:Hide() end
                end
                MarkDirty()
            end,
        },
        { kind = "header", label = L.SECTION_VALUES or "Values" },
        {
            kind = "dropdown", key = "ratingMode", label = L.LABEL_DISPLAY_MODE or "Display Mode",
            items = {
                { value = "percent", text = L.MODE_PERCENT or "Percent" },
                { value = "rating", text = L.MODE_RATING or "Rating" },
                { value = "both", text = L.MODE_BOTH or "Both" },
            },
        },
        {
            kind = "dropdown", key = "decimals", label = L.LABEL_DECIMALS or "Decimal Places",
            items = {
                { value = 0, text = "0" },
                { value = 1, text = "1" },
                { value = 2, text = "2" },
            },
            get = function(db) return CS.GetDecimals(db.decimals) end,
        },
        { kind = "toggle", key = "itemTooltipDR", label = L.LABEL_ITEM_TOOLTIP_DR or "Show Value After Diminishing Returns on Item Tooltips", retailOnly = true, fullRow = true },
        { kind = "header", label = L.SECTION_LANGUAGE or "Language" },
        {
            kind = "dropdown", key = "localeOverride", label = L.LABEL_ADDON_LANGUAGE or "Addon Language (reloads the UI)",
            items = function() return CS.LocalePicker.Items() end,
            get = function() return (CharacterStatsDB and CharacterStatsDB.localeOverride) or "game" end,
            set = function(_, value)
                if value ~= ((CharacterStatsDB and CharacterStatsDB.localeOverride) or "game") then
                    CS.LocalePicker.Choose(value ~= "game" and value or nil)
                end
            end,
        },
    }
end
ConfigPanel.RegisterPage("general", {
    label = CS.L.NAV_GENERAL or "General",
    labelKey = "NAV_GENERAL",
    order = 1,
    create = function(container)
        local _, content = ConfigPanel.CreateScrollPage(container)
        local page = CS.ConfigBuilder.Build(content, BuildEntries(CS.L), {
            onChange = ConfigPanel.RefreshStatsFrame,
        })
        content:SetHeight(page.height)
        return page
    end,
})
