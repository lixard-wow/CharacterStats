local ADDON_NAME, ns = ...
local Drawer = {}
ns.CompanionDrawer = Drawer
local ipairs, wipe = ipairs, wipe
local DRAWER_WIDTH = 280
local TAB_HEIGHT = 22
local GEAR_ROW_HEIGHT = 30
local RATING_ROW_HEIGHT = 20
local TAB_KEYS = { "stats", "gear", "ratings" }
local SLOT_NAMES = {
    [1] = "HEADSLOT", [2] = "NECKSLOT", [3] = "SHOULDERSLOT", [15] = "BACKSLOT", [5] = "CHESTSLOT",
    [9] = "WRISTSLOT", [10] = "HANDSSLOT", [6] = "WAISTSLOT", [7] = "LEGSSLOT", [8] = "FEETSLOT",
    [11] = "FINGER0SLOT", [12] = "FINGER1SLOT", [13] = "TRINKET0SLOT", [14] = "TRINKET1SLOT",
    [16] = "MAINHANDSLOT", [17] = "SECONDARYHANDSLOT", [18] = "RANGEDSLOT",
}
local RATING_STATS = {
    { id = "crit", ratingId = 9 },
    { id = "haste", ratingId = 18 },
    { id = "mastery", ratingId = 26 },
    { id = "versatility", ratingId = 29 },
}
local CLASSIC_RATINGS = {
    { key = "CR_DEFENSE_SKILL", index = 2, id = "defense", name = "Defense Rating" },
    { key = "CR_DODGE", index = 3, id = "dodge", name = "Dodge Rating" },
    { key = "CR_PARRY", index = 4, id = "parry", name = "Parry Rating" },
    { key = "CR_BLOCK", index = 5, id = "block", name = "Block Rating" },
    { key = "CR_HIT_MELEE", index = 6, id = "hit", name = "Hit Rating" },
    { key = "CR_HIT_RANGED", index = 7, id = "hit", name = "Ranged Hit Rating", sameAs = 6 },
    { key = "CR_HIT_SPELL", index = 8, id = "hit", name = "Spell Hit Rating", sameAs = 6 },
    { key = "CR_CRIT_MELEE", index = 9, id = "crit", name = "Crit Rating" },
    { key = "CR_CRIT_RANGED", index = 10, id = "crit", name = "Ranged Crit Rating", sameAs = 9 },
    { key = "CR_CRIT_SPELL", index = 11, id = "crit", name = "Spell Crit Rating", sameAs = 9 },
    { key = "CR_HASTE_MELEE", index = 18, id = "haste", name = "Haste Rating" },
    { key = "CR_HASTE_RANGED", index = 19, id = "haste", name = "Ranged Haste Rating", sameAs = 18 },
    { key = "CR_HASTE_SPELL", index = 20, id = "haste", name = "Spell Haste Rating", sameAs = 18 },
    { key = "CR_EXPERTISE", index = 24, id = "expertise", name = "Expertise Rating" },
    { key = "CR_ARMOR_PENETRATION", index = 25, id = "armorpenetration", name = "Armor Penetration Rating" },
}
local function UsesClassicRatings()
    return not ns.IS_RETAIL
end
local function ClassicRatingList()
    local list = {}
    for _, info in ipairs(CLASSIC_RATINGS) do
        local index = rawget(_G, info.key) or info.index
        local label = rawget(_G, "COMBAT_RATING_NAME" .. index) or info.name
        list[#list + 1] = { id = info.id, ratingId = index, label = label, sameAs = info.sameAs }
    end
    return list
end
local frame, toggleButton
local pages = {}
local tabs = {}
local activeTab = nil
local function GetDB()
    return ns.db or ns.DEFAULTS
end
local function IsOpen()
    return GetDB().drawerOpen ~= false
end
local function SafeNumber(value)
    if value == nil or ns.IsSecretValue(value) or type(value) ~= "number" then return nil end
    return value
end
local function ColorText(r, g, b, text)
    return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end
local function CreateGearPage(parent)
    local Widgets = ns.ConfigWidgets
    local page = { rows = {} }
    local scroll = Widgets.CreateScrollFrame(parent)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    local content = scroll.content
    page.summary = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    page.summary:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -6)
    page.summary:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -6)
    page.summary:SetJustifyH("LEFT")
    local function AcquireRow(index)
        local row = page.rows[index]
        if row then return row end
        row = CreateFrame("Frame", nil, content)
        row:SetHeight(GEAR_ROW_HEIGHT)
        row:EnableMouse(true)
        row.stripe = row:CreateTexture(nil, "BACKGROUND")
        row.stripe:SetAllPoints()
        row.stripe:SetColorTexture(1, 1, 1, 0.03)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.level = row:CreateFontString(nil, "OVERLAY")
        row.level:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        row.level:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -3)
        row.status = row:CreateFontString(nil, "OVERLAY")
        row.status:SetFont(STANDARD_TEXT_FONT, 9, "")
        row.status:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 3)
        row.name = row:CreateFontString(nil, "OVERLAY")
        row.name:SetFont(STANDARD_TEXT_FONT, 11, "")
        row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, 0)
        row.name:SetPoint("RIGHT", row.level, "LEFT", -6, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.sub = row:CreateFontString(nil, "OVERLAY")
        row.sub:SetFont(STANDARD_TEXT_FONT, 9, "")
        row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 6, 0)
        row.sub:SetPoint("RIGHT", row.status, "LEFT", -6, 0)
        row.sub:SetJustifyH("LEFT")
        row.sub:SetWordWrap(false)
        row.sub:SetTextColor(0.6, 0.6, 0.6)
        row:SetScript("OnEnter", function(self)
            if self.slot then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetInventoryItem("player", self.slot)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        page.rows[index] = row
        return row
    end
    function page:Refresh(db)
        local L = ns.L
        local results, summary = ns.Gear.Scan()
        local GearBadges = ns.GearBadges
        local y = -26
        local count = 0
        for _, slot in ipairs(ns.Gear.SLOTS) do
            local entry = results[slot]
            if entry and entry.link then
                count = count + 1
                local row = AcquireRow(count)
                row.slot = slot
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
                row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
                row.stripe:SetShown(count % 2 == 0)
                row.icon:SetTexture(GetInventoryItemTexture("player", slot))
                row.name:SetText((entry.link:gsub("[%[%]]", "")))
                local slotName = rawget(_G, SLOT_NAMES[slot]) or ""
                local trackText = ""
                if entry.track == "crafted" then
                    trackText = L.TRACK_CRAFTED or "Crafted"
                elseif entry.track then
                    trackText = L["TRACK_" .. entry.track:upper()] or entry.track
                    if entry.trackRank and entry.trackMax then
                        trackText = string.format("%s %d/%d", trackText, entry.trackRank, entry.trackMax)
                    end
                end
                if trackText ~= "" then
                    local tr, tg, tb = GearBadges.GetTrackColor(db, entry.track)
                    row.sub:SetText(slotName .. "  " .. ColorText(tr, tg, tb, trackText))
                else
                    row.sub:SetText(slotName)
                end
                if entry.itemLevel then
                    row.level:SetText(string.format("%d", entry.itemLevel))
                    row.level:SetTextColor(GearBadges.GetTrackColor(db, entry.track))
                else
                    row.level:SetText("")
                end
                if entry.missingEnchant then
                    local r, g, b = GearBadges.GetColor(db, "gearColorEnchant")
                    row.status:SetText(ColorText(r, g, b, L.GEAR_NO_ENCHANT or "No enchant"))
                elseif entry.emptySockets > 0 then
                    local r, g, b = GearBadges.GetColor(db, "gearColorSocket")
                    row.status:SetText(ColorText(r, g, b, L.GEAR_EMPTY_SOCKET or "Empty socket"))
                else
                    row.status:SetText("")
                end
                row:Show()
                y = y - GEAR_ROW_HEIGHT
            end
        end
        for i = count + 1, #self.rows do self.rows[i]:Hide() end
        local parts = {}
        if summary.missingEnchants > 0 then
            local r, g, b = GearBadges.GetColor(db, "gearColorEnchant")
            parts[#parts + 1] = ColorText(r, g, b, string.format(L.GEAR_MISSING_ENCHANTS or "Enchants: %d", summary.missingEnchants))
        end
        if summary.emptySockets > 0 then
            local r, g, b = GearBadges.GetColor(db, "gearColorSocket")
            parts[#parts + 1] = ColorText(r, g, b, string.format(L.GEAR_EMPTY_SOCKETS or "Gems: %d", summary.emptySockets))
        end
        if #parts > 0 then
            page.summary:SetText((L.GEAR_MISSING or "Missing") .. "  " .. table.concat(parts, "  "))
        else
            page.summary:SetText(ColorText(0.37, 0.75, 0.42, L.GEAR_ALL_GOOD or "All set"))
        end
        content:SetHeight(math.abs(y) + 6)
        if summary.pending and not page.retry then
            page.retry = true
            C_Timer.After(1, function()
                page.retry = false
                if frame and frame:IsShown() and activeTab == "gear" then
                    Drawer:Refresh()
                end
            end)
        end
    end
    return page
end
local function CreateRatingsPage(parent)
    local Widgets = ns.ConfigWidgets
    local L = ns.L
    local page = { rows = {} }
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -8)
    header:SetHeight(16)
    local columns = { L.RATING_COL_RATING or "Rating", L.RATING_COL_BONUS or "Bonus", L.RATING_COL_PER_PERCENT or "Per 1%" }
    local COLUMN_X = { -128, -66, 0 }
    local function CreateCells(rowFrame, size)
        local cells = {}
        cells.name = rowFrame:CreateFontString(nil, "OVERLAY")
        cells.name:SetFont(STANDARD_TEXT_FONT, size, "")
        cells.name:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
        for i, x in ipairs(COLUMN_X) do
            local fs = rowFrame:CreateFontString(nil, "OVERLAY")
            fs:SetFont(STANDARD_TEXT_FONT, size, "")
            fs:SetPoint("RIGHT", rowFrame, "RIGHT", x, 0)
            fs:SetJustifyH("RIGHT")
            cells[i] = fs
        end
        return cells
    end
    local headerCells = CreateCells(header, 9)
    for i, text in ipairs(columns) do
        headerCells[i]:SetText(text)
        headerCells[i]:SetTextColor(0.6, 0.6, 0.6)
    end
    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    line:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    line:SetHeight(1)
    Widgets.ApplyTextureColor(line, "border", 1)
    local classic = UsesClassicRatings()
    local defs = classic and ClassicRatingList() or RATING_STATS
    for _, def in ipairs(defs) do
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(RATING_ROW_HEIGHT)
        row.cells = CreateCells(row, 11)
        row.def = def
        page.rows[#page.rows + 1] = row
    end
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    hint:SetJustifyH("LEFT")
    if classic then
        hint:SetText(L.HINT_RATINGS_CLASSIC or "Combat ratings from your gear and the bonus they give at your level. Ratings you have none of are hidden.")
    else
        hint:SetText(L.HINT_RATINGS or "Per 1% is the average rating per 1% at your current total, after diminishing returns. Values hidden by the game in combat show as a dash.")
    end
    Widgets.ApplyFontColor(hint, "textMuted", 0.8)
    local function ReadRating(ratingId)
        if not GetCombatRating then return nil, nil end
        local okRating, rating = pcall(GetCombatRating, ratingId)
        local okBonus, bonus = false, nil
        if GetCombatRatingBonus then
            okBonus, bonus = pcall(GetCombatRatingBonus, ratingId)
        end
        return okRating and SafeNumber(rating) or nil, okBonus and SafeNumber(bonus) or nil
    end
    function page:Refresh()
        local y = -30
        local seen = {}
        for _, row in ipairs(self.rows) do
            local def = row.def
            local rating, bonus = ReadRating(def.ratingId)
            seen[def.ratingId] = rating
            local visible
            local label
            if classic then
                visible = rating ~= nil and rating > 0 and not (def.sameAs and seen[def.sameAs] == rating)
                label = def.label
            else
                local statDef = ns.STAT_DEFS[def.id]
                visible = statDef ~= nil and ns.IsStatAvailable(def.id)
                label = (statDef and ns.L["STAT_" .. def.id:upper()]) or (statDef and statDef.label) or def.id
            end
            if visible then
                local r, g, b = ns.GetStatColor(def.id)
                row.cells.name:SetText(label)
                row.cells.name:SetTextColor(r, g, b)
                row.cells[1]:SetText(rating and BreakUpLargeNumbers(math.floor(rating + 0.5)) or "-")
                row.cells[2]:SetText(bonus and string.format("%.2f%%", bonus) or "-")
                if rating and bonus and bonus > 0 then
                    row.cells[3]:SetText(string.format("%.1f", rating / bonus))
                else
                    row.cells[3]:SetText("-")
                end
                for i = 1, 3 do
                    row.cells[i]:SetTextColor(0.9, 0.9, 0.9)
                end
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
                row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
                y = y - RATING_ROW_HEIGHT
            end
            row:SetShown(visible)
        end
        hint:ClearAllPoints()
        hint:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y - 10)
        hint:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    end
    return page
end
local function CreateStatsPage(parent)
    local renderer = ns.Styles.CreateListPaperdollRenderer(parent, {})
    return {
        Refresh = function(_, db)
            renderer:Refresh(db)
        end,
    }
end
local PAGE_BUILDERS = {
    stats = CreateStatsPage,
    gear = CreateGearPage,
    ratings = CreateRatingsPage,
}
local TAB_LABEL_KEYS = {
    stats = "DRAWER_TAB_STATS",
    gear = "DRAWER_TAB_GEAR",
    ratings = "DRAWER_TAB_RATINGS",
}
local TAB_FALLBACKS = { stats = "Stats", gear = "Gear", ratings = "Ratings" }
local function SideOffset()
    local modeTabs = CharacterFrame and rawget(CharacterFrame, "ModeTabs")
    if modeTabs and modeTabs.IsShown and modeTabs:IsShown() then
        return modeTabs:GetWidth() or 0
    end
    return 0
end
local function AnchorFrame()
    if not frame then return end
    local offset = SideOffset()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 2 + offset, -2)
    frame:SetPoint("BOTTOMLEFT", CharacterFrame, "BOTTOMRIGHT", 2 + offset, 2)
end
local function UpdateToggleButton()
    if not toggleButton then return end
    AnchorFrame()
    toggleButton:ClearAllPoints()
    if IsOpen() then
        toggleButton:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, -40)
        toggleButton.icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    else
        toggleButton:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", SideOffset(), -40)
        toggleButton.icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    end
end
local function SelectTab(key)
    activeTab = key
    for tabKey, tab in pairs(tabs) do
        local active = tabKey == key
        tab.bar:SetShown(active)
        if active then
            ns.ConfigWidgets.ApplyFontColor(tab.text, "textPrimary")
            ns.ConfigWidgets.ApplyTextureColor(tab.bar, "accentGold", 1)
        else
            ns.ConfigWidgets.ApplyFontColor(tab.text, "textMuted")
        end
    end
    for pageKey, page in pairs(pages) do
        page.frame:SetShown(pageKey == key)
    end
    if not pages[key] then
        local pageFrame = CreateFrame("Frame", nil, frame.body)
        pageFrame:SetAllPoints(frame.body)
        pages[key] = PAGE_BUILDERS[key](pageFrame)
        pages[key].frame = pageFrame
    end
    pages[key].frame:Show()
    if ns.db then
        ns.db.drawerTab = key
    end
    pages[key]:Refresh(GetDB())
end
local function Create()
    if frame and frame.themeKey == ns.Theme.key then return frame end
    if not CharacterFrame then return nil end
    if frame then
        frame:Hide()
        if toggleButton then toggleButton:Hide() end
        wipe(pages)
        wipe(tabs)
    end
    local Widgets = ns.ConfigWidgets
    frame = CreateFrame("Frame", "CharacterStatsDrawer", CharacterFrame)
    frame.themeKey = ns.Theme.key
    AnchorFrame()
    frame:SetWidth(DRAWER_WIDTH)
    frame:EnableMouse(true)
    ns.Theme.Box(frame, "window", "border", (ns.Theme.Get()).buttonRadius)
    frame.accent = frame:CreateTexture(nil, "ARTWORK")
    frame.accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.accent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.accent:SetWidth(2)
    Widgets.ApplyTextureColor(frame.accent, "accentGold", 1)
    Widgets.RegisterAccentTexture(frame.accent, 1)
    frame.tabBar = CreateFrame("Frame", nil, frame)
    frame.tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    frame.tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    frame.tabBar:SetHeight(TAB_HEIGHT)
    frame.tabBar.line = frame.tabBar:CreateTexture(nil, "ARTWORK")
    frame.tabBar.line:SetPoint("BOTTOMLEFT")
    frame.tabBar.line:SetPoint("BOTTOMRIGHT")
    frame.tabBar.line:SetHeight(1)
    Widgets.ApplyTextureColor(frame.tabBar.line, "border", 1)
    local x = 0
    for _, key in ipairs(TAB_KEYS) do
        local tab = CreateFrame("Button", nil, frame.tabBar)
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tab.text:SetPoint("CENTER", 0, 1)
        tab.text:SetText(ns.L[TAB_LABEL_KEYS[key]] or TAB_FALLBACKS[key])
        tab:SetSize(tab.text:GetStringWidth() + 20, TAB_HEIGHT)
        tab:SetPoint("BOTTOMLEFT", frame.tabBar, "BOTTOMLEFT", x, 0)
        tab.bar = tab:CreateTexture(nil, "OVERLAY")
        tab.bar:SetPoint("BOTTOMLEFT")
        tab.bar:SetPoint("BOTTOMRIGHT")
        tab.bar:SetHeight(2)
        tab:SetScript("OnClick", function()
            SelectTab(key)
        end)
        tabs[key] = tab
        x = x + tab:GetWidth() + 4
    end
    frame.body = CreateFrame("Frame", nil, frame)
    frame.body:SetPoint("TOPLEFT", frame.tabBar, "BOTTOMLEFT", -8, -4)
    frame.body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 4)
    toggleButton = CreateFrame("Button", nil, CharacterFrame)
    toggleButton:SetSize(22, 44)
    ns.Theme.Box(toggleButton, "window", "border", (ns.Theme.Get()).buttonRadius)
    toggleButton.icon = toggleButton:CreateTexture(nil, "ARTWORK")
    toggleButton.icon:SetPoint("CENTER")
    toggleButton.icon:SetSize(22, 22)
    toggleButton:SetScript("OnClick", function()
        if ns.db then
            ns.db.drawerOpen = not IsOpen()
        end
        Drawer:Show()
    end)
    toggleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.L.ADDON_TITLE or "CharacterStats")
        GameTooltip:Show()
    end)
    toggleButton:SetScript("OnLeave", GameTooltip_Hide)
    ns.Theme.ApplyFonts(frame.tabBar)
    frame:Hide()
    toggleButton:Hide()
    return frame
end
function Drawer:Show()
    if not Create() then return end
    toggleButton:Show()
    if IsOpen() then
        frame:Show()
        SelectTab(activeTab or GetDB().drawerTab or "stats")
    else
        frame:Hide()
    end
    UpdateToggleButton()
end
function Drawer:Hide()
    if frame then frame:Hide() end
    if toggleButton then toggleButton:Hide() end
end
function Drawer:IsShown()
    return frame ~= nil and frame:IsShown()
end
function Drawer:Refresh()
    if not frame or not frame:IsShown() or not activeTab or not pages[activeTab] then return end
    pages[activeTab]:Refresh(GetDB())
end
function Drawer:SelectTab(key)
    if frame and frame:IsShown() and PAGE_BUILDERS[key] then
        SelectTab(key)
    end
end
ns.Theme.OnChange(function()
    if frame and frame:IsShown() then
        Drawer:Show()
    end
end)
