local ADDON_NAME, ns = ...
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local wipe = wipe
local BLIZZARD_STAT_KEYS = {
    ilvl        = "ITEMLEVEL",
    str         = "STRENGTH",
    agi         = "AGILITY",
    int         = "INTELLECT",
    sta         = "STAMINA",
    crit        = "CRITCHANCE",
    haste       = "HASTE",
    mastery     = "MASTERY",
    versatility = "VERSATILITY",
    leech       = "LIFESTEAL",
    avoidance   = "AVOIDANCE",
    speed       = "SPEED",
    armor       = "ARMOR",
    stagger     = "STAGGER",
    dodge       = "DODGE",
    parry       = "PARRY",
    block       = "BLOCK",
    movespeed   = "MOVESPEED",
    manaregen   = "MANAREGEN",
}
local noop = function() end
local mockFontString = { SetText = noop, SetShown = noop }
local statProxy = {}
local function TryShowBlizzardTooltip(hoverFrame, statId)
    if not PAPERDOLL_STATINFO then return false end
    local key = BLIZZARD_STAT_KEYS[statId]
    if not key then return false end
    local info = PAPERDOLL_STATINFO[key]
    if not info or not info.updateFunc then return false end
    wipe(statProxy)
    statProxy.Value = mockFontString
    statProxy.Label = mockFontString
    statProxy.Background = mockFontString
    statProxy.Show = noop
    statProxy.Hide = noop
    local ok = pcall(info.updateFunc, statProxy, "player")
    if not ok then return false end
    if statProxy.onEnterFunc then
        local copied = {}
        for k, v in pairs(statProxy) do
            if hoverFrame[k] == nil then
                hoverFrame[k] = v
                copied[k] = true
            end
        end
        local success = pcall(statProxy.onEnterFunc, hoverFrame)
        for k in pairs(copied) do
            hoverFrame[k] = nil
        end
        if not success then return false end
    else
        if not statProxy.tooltip then return false end
        GameTooltip:SetOwner(hoverFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(statProxy.tooltip)
        if statProxy.tooltip2 then
            GameTooltip:AddLine(statProxy.tooltip2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        end
        if statProxy.tooltip3 then
            GameTooltip:AddLine(statProxy.tooltip3, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        end
        GameTooltip:Show()
    end
    return true
end
local function GetLocaleFontSize()
    return 10, 12
end
local function GetLocaleColon()
    local locale = GetLocale()
    if locale == "zhCN" or locale == "zhTW" then
        return "："
    else
        return ":"
    end
end
local PaperdollPanel = {}
ns.PaperdollPanel = PaperdollPanel
local function GetCharacterStatsPane()
    local pane = _G and rawget(_G, "CharacterStatsPane")
    if pane then return pane end
    return _G and rawget(_G, "CharacterAttributesFrame")
end
local panel
local isAttached = false
local itemLevelFrame
local attributesHeader
local attrSepTop, attrSepBottom
local attrHeaderBg
local attrBraceLeft, attrBraceRight
local enhSepTop, enhSepBottom
local enhHeaderBg
local enhBraceLeft, enhBraceRight
local statLines = {}
local MAX_STAT_LINES = 15
local lastStatLayout = {}
local cachedFontPath = nil
local cachedFontSize = nil
local hiddenStatsPaneChildren = {}
local hiddenStatsPaneRegions = {}
local function HideStatsPaneChildren(captureRestoreSet)
    local statsPane = GetCharacterStatsPane()
    if not statsPane then return end
    if captureRestoreSet then
        wipe(hiddenStatsPaneChildren)
        wipe(hiddenStatsPaneRegions)
    end
    for _, child in ipairs({statsPane:GetChildren()}) do
        if child ~= panel and child:IsShown() then
            hiddenStatsPaneChildren[child] = true
            child:Hide()
        end
    end
    for _, region in ipairs({statsPane:GetRegions()}) do
        if region:IsShown() then
            hiddenStatsPaneRegions[region] = true
            region:Hide()
        end
    end
end
local function ShowStatsPaneChildren()
    for child in pairs(hiddenStatsPaneChildren) do
        if child and child.Show then
            child:Show()
        end
    end
    for region in pairs(hiddenStatsPaneRegions) do
        if region and region.Show then
            region:Show()
        end
    end
    wipe(hiddenStatsPaneChildren)
    wipe(hiddenStatsPaneRegions)
end
local function GetEquippedItemLevel()
    local overall, equipped = GetAverageItemLevel()
    return equipped or overall or 0
end
function PaperdollPanel:Create()
    if panel then return panel end
    local statsPane = GetCharacterStatsPane()
    if not statsPane then return nil end
    panel = CreateFrame("Frame", "CharacterStatsCustomPanel", statsPane)
    panel:SetAllPoints(statsPane)
    panel:SetFrameLevel(statsPane:GetFrameLevel() + 50)
    panel:Hide()
    local yOffset = -42
    local _, headerFontSize = GetLocaleFontSize()
    itemLevelFrame = CreateFrame("Frame", nil, panel)
    itemLevelFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, yOffset)
    itemLevelFrame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, yOffset)
    itemLevelFrame:SetHeight(29)
    itemLevelFrame:EnableMouse(true)
    itemLevelFrame.highlight = itemLevelFrame:CreateTexture(nil, "BACKGROUND")
    itemLevelFrame.highlight:SetPoint("TOPLEFT", itemLevelFrame, "TOPLEFT", 16, 0)
    itemLevelFrame.highlight:SetPoint("TOPRIGHT", itemLevelFrame, "TOPRIGHT", -13, 0)
    itemLevelFrame.highlight:SetHeight(30)
    itemLevelFrame.highlight:SetColorTexture(1, 1, 1, 0.06)
    itemLevelFrame:SetScript("OnEnter", function(self)
        if TryShowBlizzardTooltip(self, "ilvl") then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local title = HIGHLIGHT_FONT_COLOR_CODE .. (ns.L.STAT_ILVL or "Item Level") .. ": " .. string.format("%.2f", GetEquippedItemLevel()) .. FONT_COLOR_CODE_CLOSE
        GameTooltip:SetText(title)
        local r, g, b = NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b
        GameTooltip:AddLine(ns.L.STAT_ILVL_TT or "The average item level of your equipped gear.", r, g, b, true)
        GameTooltip:Show()
    end)
    itemLevelFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    itemLevelFrame.header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemLevelFrame.header:SetFont(STANDARD_TEXT_FONT, headerFontSize, "")
    itemLevelFrame.header:SetPoint("TOP", panel, "TOP", 0, -15)
    itemLevelFrame.header:SetText(ns.L.STAT_ILVL or "Item Level")
    local ar, ag, ab = ns.GetAccentColor()
    itemLevelFrame.header:SetTextColor(ar, ag, ab)
    itemLevelFrame.headerBg = itemLevelFrame:CreateTexture(nil, "BACKGROUND")
    itemLevelFrame.headerBg:SetPoint("LEFT", itemLevelFrame, "LEFT", 5, 0)
    itemLevelFrame.headerBg:SetPoint("RIGHT", itemLevelFrame, "RIGHT", -5, 0)
    itemLevelFrame.headerBg:SetPoint("TOP", itemLevelFrame.header, "TOP", 0, 5)
    itemLevelFrame.headerBg:SetPoint("BOTTOM", itemLevelFrame.header, "BOTTOM", 0, -5)
    itemLevelFrame.headerBg:SetColorTexture(0.35, 0.30, 0.25, 0.12)
    itemLevelFrame.sepTop = itemLevelFrame:CreateTexture(nil, "ARTWORK")
    itemLevelFrame.sepTop:SetPoint("LEFT", itemLevelFrame, "LEFT", 10, 0)
    itemLevelFrame.sepTop:SetPoint("RIGHT", itemLevelFrame, "RIGHT", -10, 0)
    itemLevelFrame.sepTop:SetPoint("BOTTOM", itemLevelFrame.header, "TOP", 0, 6)
    itemLevelFrame.sepTop:SetHeight(1)
    itemLevelFrame.sepTop:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    itemLevelFrame.sepBottom = itemLevelFrame:CreateTexture(nil, "ARTWORK")
    itemLevelFrame.sepBottom:SetPoint("LEFT", itemLevelFrame, "LEFT", 10, 0)
    itemLevelFrame.sepBottom:SetPoint("RIGHT", itemLevelFrame, "RIGHT", -10, 0)
    itemLevelFrame.sepBottom:SetPoint("TOP", itemLevelFrame.header, "BOTTOM", 0, -8)
    itemLevelFrame.sepBottom:SetHeight(1)
    itemLevelFrame.sepBottom:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    itemLevelFrame.braceLeft = itemLevelFrame:CreateFontString(nil, "ARTWORK")
    itemLevelFrame.braceLeft:SetFont(STANDARD_TEXT_FONT, 16, "")
    itemLevelFrame.braceLeft:SetPoint("LEFT", itemLevelFrame, "LEFT", 2, 0)
    itemLevelFrame.braceLeft:SetPoint("TOP", itemLevelFrame.header, "TOP", 0, 2)
    itemLevelFrame.braceLeft:SetPoint("BOTTOM", itemLevelFrame.header, "BOTTOM", 0, -2)
    itemLevelFrame.braceLeft:SetText("{")
    itemLevelFrame.braceLeft:SetTextColor(0.4, 0.4, 0.4, 0.5)
    itemLevelFrame.braceLeft:Hide()
    itemLevelFrame.braceRight = itemLevelFrame:CreateFontString(nil, "ARTWORK")
    itemLevelFrame.braceRight:SetFont(STANDARD_TEXT_FONT, 16, "")
    itemLevelFrame.braceRight:SetPoint("RIGHT", itemLevelFrame, "RIGHT", -2, 0)
    itemLevelFrame.braceRight:SetPoint("TOP", itemLevelFrame.header, "TOP", 0, 2)
    itemLevelFrame.braceRight:SetPoint("BOTTOM", itemLevelFrame.header, "BOTTOM", 0, -2)
    itemLevelFrame.braceRight:SetText("}")
    itemLevelFrame.braceRight:SetTextColor(0.4, 0.4, 0.4, 0.5)
    itemLevelFrame.braceRight:Hide()
    itemLevelFrame.value = itemLevelFrame:CreateFontString(nil, "OVERLAY")
    itemLevelFrame.value:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
    itemLevelFrame.value:SetPoint("CENTER", itemLevelFrame, "CENTER", 0, -1)
    itemLevelFrame.value:SetTextColor(1, 1, 1)
    itemLevelFrame.value:SetText("0")
    yOffset = -84
    local _, headerFontSize = GetLocaleFontSize()
    attributesHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    attributesHeader:SetFont(STANDARD_TEXT_FONT, headerFontSize, "")
    attributesHeader:SetPoint("TOP", panel, "TOP", 0, yOffset - 12)
    attributesHeader:SetText(ns.L.HEADER_ATTRIBUTES or "Attributes")
    local ar2, ag2, ab2 = ns.GetAccentColor()
    attributesHeader:SetTextColor(ar2, ag2, ab2)
    attrHeaderBg = panel:CreateTexture(nil, "BACKGROUND")
    attrHeaderBg:SetPoint("LEFT", panel, "LEFT", 5, 0)
    attrHeaderBg:SetPoint("RIGHT", panel, "RIGHT", -5, 0)
    attrHeaderBg:SetPoint("TOP", attributesHeader, "TOP", 0, 5)
    attrHeaderBg:SetPoint("BOTTOM", attributesHeader, "BOTTOM", 0, -5)
    attrHeaderBg:SetColorTexture(0.35, 0.30, 0.25, 0.12)
    attrSepTop = panel:CreateTexture(nil, "ARTWORK")
    attrSepTop:SetPoint("LEFT", panel, "LEFT", 10, 0)
    attrSepTop:SetPoint("RIGHT", panel, "RIGHT", -10, 0)
    attrSepTop:SetPoint("BOTTOM", attributesHeader, "TOP", 0, 6)
    attrSepTop:SetHeight(1)
    attrSepTop:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    attrSepBottom = panel:CreateTexture(nil, "ARTWORK")
    attrSepBottom:SetPoint("LEFT", panel, "LEFT", 10, 0)
    attrSepBottom:SetPoint("RIGHT", panel, "RIGHT", -10, 0)
    attrSepBottom:SetPoint("TOP", attributesHeader, "BOTTOM", 0, -8)
    attrSepBottom:SetHeight(1)
    attrSepBottom:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    attrBraceLeft = panel:CreateFontString(nil, "ARTWORK")
    attrBraceLeft:SetFont(STANDARD_TEXT_FONT, 16, "")
    attrBraceLeft:SetPoint("LEFT", panel, "LEFT", 2, 0)
    attrBraceLeft:SetPoint("TOP", attributesHeader, "TOP", 0, 2)
    attrBraceLeft:SetPoint("BOTTOM", attributesHeader, "BOTTOM", 0, -2)
    attrBraceLeft:SetText("{")
    attrBraceLeft:SetTextColor(0.4, 0.4, 0.4, 0.5)
    attrBraceLeft:Hide()
    attrBraceRight = panel:CreateFontString(nil, "ARTWORK")
    attrBraceRight:SetFont(STANDARD_TEXT_FONT, 16, "")
    attrBraceRight:SetPoint("RIGHT", panel, "RIGHT", -2, 0)
    attrBraceRight:SetPoint("TOP", attributesHeader, "TOP", 0, 2)
    attrBraceRight:SetPoint("BOTTOM", attributesHeader, "BOTTOM", 0, -2)
    attrBraceRight:SetText("}")
    attrBraceRight:SetTextColor(0.4, 0.4, 0.4, 0.5)
    attrBraceRight:Hide()
    yOffset = yOffset - 32
    local statFontSize, _ = GetLocaleFontSize()
    for i = 1, MAX_STAT_LINES do
        local line = {}
        line.frame = CreateFrame("Frame", nil, panel)
        line.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, yOffset - ((i - 1) * 15))
        line.frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, yOffset - ((i - 1) * 15))
        line.frame:SetHeight(15)
        line.frame:EnableMouse(true)
        line.highlight = line.frame:CreateTexture(nil, "BACKGROUND")
        line.highlight:SetPoint("TOPLEFT", line.frame, "TOPLEFT", 11, 0)
        line.highlight:SetPoint("BOTTOMRIGHT", line.frame, "BOTTOMRIGHT", -8, 0)
        line.highlight:SetColorTexture(1, 1, 1, 0.06)
        line.highlight:Hide()
        line.frame:SetScript("OnEnter", function(self)
            if self.statId and TryShowBlizzardTooltip(self, self.statId) then return end
            if self.tooltipTitle then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local title = HIGHLIGHT_FONT_COLOR_CODE .. self.tooltipTitle
                if self.tooltipValue then
                    title = title .. ": " .. self.tooltipValue
                end
                GameTooltip:SetText(title .. FONT_COLOR_CODE_CLOSE)
                if self.tooltipText and self.tooltipText ~= "" then
                    local r, g, b = NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b
                    GameTooltip:AddLine(self.tooltipText, r, g, b, true)
                end
                GameTooltip:Show()
            end
        end)
        line.frame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        line.label = line.frame:CreateFontString(nil, "OVERLAY")
        line.label:SetFont(STANDARD_TEXT_FONT, statFontSize, "")
        line.label:SetPoint("LEFT", line.frame, "LEFT", 11, 0)
        line.label:SetJustifyH("LEFT")
        line.label:SetTextColor(1, 1, 1)
        line.value = line.frame:CreateFontString(nil, "OVERLAY")
        line.value:SetFont(STANDARD_TEXT_FONT, statFontSize, "")
        line.value:SetPoint("RIGHT", line.frame, "RIGHT", -8, 0)
        line.value:SetJustifyH("RIGHT")
        line.value:SetTextColor(1, 1, 1)
        line.isHeader = false
        line.frame:Hide()
        statLines[i] = line
    end
    enhSepTop = panel:CreateTexture(nil, "ARTWORK")
    enhSepTop:SetHeight(1)
    enhSepTop:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    enhSepTop:Hide()
    enhSepBottom = panel:CreateTexture(nil, "ARTWORK")
    enhSepBottom:SetHeight(1)
    enhSepBottom:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    enhSepBottom:Hide()
    enhHeaderBg = panel:CreateTexture(nil, "BACKGROUND")
    enhHeaderBg:SetColorTexture(0.35, 0.30, 0.25, 0.12)
    enhHeaderBg:Hide()
    enhBraceLeft = panel:CreateFontString(nil, "ARTWORK")
    enhBraceLeft:SetFont(STANDARD_TEXT_FONT, 16, "")
    enhBraceLeft:SetText("{")
    enhBraceLeft:SetTextColor(0.4, 0.4, 0.4, 0.5)
    enhBraceLeft:Hide()
    enhBraceRight = panel:CreateFontString(nil, "ARTWORK")
    enhBraceRight:SetFont(STANDARD_TEXT_FONT, 16, "")
    enhBraceRight:SetText("}")
    enhBraceRight:SetTextColor(0.4, 0.4, 0.4, 0.5)
    enhBraceRight:Hide()
    return panel
end
function PaperdollPanel:Attach()
    if not PaperDollFrame then return end
    if isAttached then
        self:Refresh()
        return
    end
    if not panel then
        self:Create()
    end
    if not panel then return end
    HideStatsPaneChildren(true)
    panel:Show()
    if ns.Stats and ns.Stats.Invalidate then
        ns.Stats:Invalidate()
    end
    isAttached = true
    self:Refresh()
end
function PaperdollPanel:Detach()
    if not isAttached then return end
    isAttached = false
    if panel then
        panel:Hide()
    end
    cachedFontPath = nil
    cachedFontSize = nil
    ShowStatsPaneChildren()
end
function PaperdollPanel:Toggle()
    if isAttached then
        self:Detach()
    else
        self:Attach()
    end
end
function PaperdollPanel:IsAttached()
    return isAttached
end
function PaperdollPanel:Refresh()
    if not isAttached or not panel or not panel:IsShown() then return end
    local statFontSize, headerFontSize = GetLocaleFontSize()
    local statFont = STANDARD_TEXT_FONT
    local colon = GetLocaleColon()
    local fontChanged = cachedFontPath ~= statFont or cachedFontSize ~= statFontSize
    if fontChanged then
        cachedFontPath = statFont
        cachedFontSize = statFontSize
    end
    local ar, ag, ab = ns.GetAccentColor()
    if itemLevelFrame and itemLevelFrame.header then
        itemLevelFrame.header:SetTextColor(ar, ag, ab)
    end
    if attributesHeader then
        attributesHeader:SetTextColor(ar, ag, ab)
    end
    local ilvl = GetEquippedItemLevel()
    if itemLevelFrame and itemLevelFrame.value then
        itemLevelFrame.value:SetText(string.format("%.2f", ilvl))
        local ir, ig, ib = ns.GetStatColor("ilvl")
        if ir and ig and ib then
            itemLevelFrame.value:SetTextColor(ir, ig, ib)
        end
    end
    local attributes, enhancements = ns.Stats:CollectByCategory()
    local newLayout = {}
    for i, stat in ipairs(attributes) do
        newLayout[i] = stat.id
    end
    if #enhancements > 0 then
        newLayout[#attributes + 1] = "__HEADER__"
        for i, stat in ipairs(enhancements) do
            newLayout[#attributes + 1 + i] = stat.id
        end
    end
    local layoutChanged = #newLayout ~= #lastStatLayout
    if not layoutChanged then
        for i = 1, #newLayout do
            if newLayout[i] ~= lastStatLayout[i] then
                layoutChanged = true
                break
            end
        end
    end
    if layoutChanged then
        for i = 1, MAX_STAT_LINES do
            if statLines[i] then
                statLines[i].frame:Hide()
            end
        end
        if enhSepTop then enhSepTop:Hide() end
        if enhSepBottom then enhSepBottom:Hide() end
        if enhHeaderBg then enhHeaderBg:Hide() end
        if enhBraceLeft then enhBraceLeft:Hide() end
        if enhBraceRight then enhBraceRight:Hide() end
        lastStatLayout = newLayout
    end
    local lineIndex = 0
    local yOffset = -84
    local rowCount = 1
    if #attributes > 0 then
        if attributesHeader then
            if layoutChanged then
                attributesHeader:ClearAllPoints()
                attributesHeader:SetPoint("TOP", panel, "TOP", 0, yOffset)
            end
        end
        yOffset = yOffset - 29
        for _, stat in ipairs(attributes) do
            lineIndex = lineIndex + 1
            if lineIndex > MAX_STAT_LINES then break end
            rowCount = rowCount + 1
            local line = statLines[lineIndex]
            if not line then break end
            if layoutChanged then
                line.frame:ClearAllPoints()
                line.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, yOffset)
                line.frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, yOffset)
                line.label:ClearAllPoints()
                line.label:SetPoint("LEFT", line.frame, "LEFT", 11, 0)
                line.label:SetJustifyH("LEFT")
            end
            if fontChanged then
                line.label:SetFont(statFont, statFontSize, "")
                line.value:SetFont(statFont, statFontSize, "")
            end
            local labelText = stat.label:gsub("%s+$", "")
            line.label:SetText(labelText .. colon)
            if stat.percent then
                local decimals = ns.IS_CLASSIC and 2 or 0
                line.value:SetText(ns.FormatPercent(stat.value, decimals))
            else
                line.value:SetText(ns.FormatNumber(stat.value, 0))
            end
            local sr, sg, sb = ns.GetStatColor(stat.id)
            line.label:SetTextColor(sr, sg, sb)
            line.value:SetTextColor(sr, sg, sb)
            if line.highlight then
                if rowCount % 2 == 1 then
                    line.highlight:Show()
                else
                    line.highlight:Hide()
                end
            end
            line.frame.statId = stat.id
            line.frame.tooltipTitle = stat.label
            line.frame.tooltipText = stat.tooltip or ""
            if stat.percent then
                line.frame.tooltipValue = ns.FormatPercent(stat.value, 2)
            else
                line.frame.tooltipValue = ns.FormatNumber(stat.value, 0)
            end
            line.frame:Show()
            yOffset = yOffset - 15
        end
    end
    if #enhancements > 0 then
        yOffset = yOffset - 10
        lineIndex = lineIndex + 1
        if lineIndex <= MAX_STAT_LINES then
            local line = statLines[lineIndex]
            if not line then return end
            if layoutChanged then
                line.frame:ClearAllPoints()
                line.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, yOffset)
                line.frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, yOffset)
                line.frame:SetHeight(18)
                line.label:ClearAllPoints()
                line.label:SetPoint("CENTER", line.frame, "CENTER", 0, 0)
                line.label:SetJustifyH("CENTER")
                line.label:SetFont(STANDARD_TEXT_FONT, headerFontSize, "")
            end
            line.label:SetText(ns.L.HEADER_ENHANCEMENTS or "Enhancements")
            local er, eg, eb = ns.GetAccentColor()
            line.label:SetTextColor(er, eg, eb)
            line.value:SetText("")
            line.frame.statId = nil
            line.frame.tooltipTitle = nil
            line.frame.tooltipText = nil
            line.frame.tooltipValue = nil
            if line.highlight then line.highlight:Hide() end
            if layoutChanged then
                if enhSepTop then
                    enhSepTop:ClearAllPoints()
                    enhSepTop:SetPoint("LEFT", panel, "LEFT", 10, 0)
                    enhSepTop:SetPoint("RIGHT", panel, "RIGHT", -10, 0)
                    enhSepTop:SetPoint("BOTTOM", line.label, "TOP", 0, 6)
                end
                if enhSepBottom then
                    enhSepBottom:ClearAllPoints()
                    enhSepBottom:SetPoint("LEFT", panel, "LEFT", 10, 0)
                    enhSepBottom:SetPoint("RIGHT", panel, "RIGHT", -10, 0)
                    enhSepBottom:SetPoint("TOP", line.label, "BOTTOM", 0, -8)
                end
                if enhHeaderBg then
                    enhHeaderBg:ClearAllPoints()
                    enhHeaderBg:SetPoint("LEFT", panel, "LEFT", 5, 0)
                    enhHeaderBg:SetPoint("RIGHT", panel, "RIGHT", -5, 0)
                    enhHeaderBg:SetPoint("TOP", line.label, "TOP", 0, 5)
                    enhHeaderBg:SetPoint("BOTTOM", line.label, "BOTTOM", 0, -5)
                end
                if enhBraceLeft then
                    enhBraceLeft:ClearAllPoints()
                    enhBraceLeft:SetPoint("LEFT", panel, "LEFT", 2, 0)
                    enhBraceLeft:SetPoint("TOP", line.label, "TOP", 0, 2)
                    enhBraceLeft:SetPoint("BOTTOM", line.label, "BOTTOM", 0, -2)
                end
                if enhBraceRight then
                    enhBraceRight:ClearAllPoints()
                    enhBraceRight:SetPoint("RIGHT", panel, "RIGHT", -2, 0)
                    enhBraceRight:SetPoint("TOP", line.label, "TOP", 0, 2)
                    enhBraceRight:SetPoint("BOTTOM", line.label, "BOTTOM", 0, -2)
                end
            end
            if enhSepTop then enhSepTop:Show() end
            if enhSepBottom then enhSepBottom:Show() end
            if enhHeaderBg then enhHeaderBg:Show() end
            line.frame:Show()
        end
        yOffset = yOffset - 31
        local enhancementRowIndex = 0
        for _, stat in ipairs(enhancements) do
            lineIndex = lineIndex + 1
            if lineIndex > MAX_STAT_LINES then break end
            enhancementRowIndex = enhancementRowIndex + 1
            local line = statLines[lineIndex]
            if not line then break end
            if layoutChanged then
                line.frame:ClearAllPoints()
                line.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, yOffset)
                line.frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, yOffset)
                line.label:ClearAllPoints()
                line.label:SetPoint("LEFT", line.frame, "LEFT", 11, 0)
                line.label:SetJustifyH("LEFT")
            end
            if fontChanged then
                line.label:SetFont(statFont, statFontSize, "")
                line.value:SetFont(statFont, statFontSize, "")
            end
            local labelText = stat.label:gsub("%s+$", "")
            line.label:SetText(labelText .. colon)
            if stat.percent then
                local decimals = ns.IS_CLASSIC and 2 or 0
                line.value:SetText(ns.FormatPercent(stat.value, decimals))
            else
                line.value:SetText(ns.FormatNumber(stat.value, 0))
            end
            local sr, sg, sb = ns.GetStatColor(stat.id)
            line.label:SetTextColor(sr, sg, sb)
            line.value:SetTextColor(sr, sg, sb)
            if line.highlight then
                if enhancementRowIndex % 2 == 0 then
                    line.highlight:Show()
                else
                    line.highlight:Hide()
                end
            end
            local ratingText = nil
            if stat.ratingId and stat.ratingId <= 32 then
                ratingText = ns.FormatRating(stat.ratingId)
            end
            line.frame.statId = stat.id
            line.frame.tooltipTitle = stat.label
            line.frame.tooltipText = stat.tooltip or ""
            if stat.percent then
                if ratingText then
                    line.frame.tooltipValue = ns.FormatPercent(stat.value, 2) .. " " .. ratingText
                else
                    line.frame.tooltipValue = ns.FormatPercent(stat.value, 2)
                end
            else
                line.frame.tooltipValue = ns.FormatNumber(stat.value, 0)
            end
            line.frame:Show()
            yOffset = yOffset - 15
        end
    end
end
function PaperdollPanel:ApplyStyle()
    if not isAttached or not panel then return end
    cachedFontPath = nil
    cachedFontSize = nil
    lastStatLayout = {}
    self:Refresh()
end
local initialized = false
function PaperdollPanel:Init()
    if initialized then
        self:Attach()
        return
    end
    if not PaperDollFrame then
        local waitFrame = CreateFrame("Frame")
        local attempts = 0
        local maxAttempts = 20
        waitFrame:RegisterEvent("ADDON_LOADED")
        waitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        waitFrame:SetScript("OnEvent", function(self, event, addon)
            attempts = attempts + 1
            if PaperDollFrame then
                self:UnregisterAllEvents()
                PaperdollPanel:Init()
            elseif attempts >= maxAttempts then
                self:UnregisterAllEvents()
                ns.PrintMsg("PaperDollFrame not found, paperdoll integration disabled", "warning")
            end
        end)
        return
    end
    initialized = true
    local function TryAttach()
        if not ns.db or not ns.db.paperdollEnabled then return end
        if isAttached then return end
        PaperdollPanel:Attach()
    end
    if CharacterFrame then
        CharacterFrame:HookScript("OnShow", function()
            C_Timer.After(0, TryAttach)
        end)
        CharacterFrame:HookScript("OnHide", function()
            PaperdollPanel:Detach()
        end)
    end
    PaperDollFrame:HookScript("OnShow", function()
        if not ns.db or not ns.db.paperdollEnabled then return end
        PaperdollPanel:Attach()
    end)
    PaperDollFrame:HookScript("OnHide", function()
        PaperdollPanel:Detach()
    end)
    if PaperDollFrame_UpdateStats then
        hooksecurefunc("PaperDollFrame_UpdateStats", function()
            if isAttached then
                HideStatsPaneChildren(false)
            end
        end)
    end
    C_Timer.After(0, TryAttach)
end
