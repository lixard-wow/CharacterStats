local ADDON_NAME, ns = ...
local StatsFrame = {}
ns.StatsFrame = StatsFrame
local ipairs, pairs, pcall = ipairs, pairs, pcall
local wipe = wipe
local frame
local renderers = {}
local activeRenderer = nil
local hasMoveSpeed = false
local lastDisplayedStats = {}
local lastStatOrder = {}
local moveSpeedStat = { id = "movespeed", percent = true }
local moveSpeedElapsed = 0
local MOVE_SPEED_UPDATE_INTERVAL = 0.1
local BG_FILE = "Interface\\Buttons\\WHITE8x8"
local BORDER_MUTE = 0.65
local BORDERS = {
    thin = { backdrop = { edgeFile = BG_FILE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } }, mute = true },
    thick = { backdrop = { edgeFile = BG_FILE, edgeSize = 2, insets = { left = 2, right = 2, top = 2, bottom = 2 } }, mute = true },
    tooltip = { backdrop = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } } },
    dialog = { backdrop = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, insets = { left = 5, right = 5, top = 5, bottom = 5 } } },
}
local function GetActiveRenderer()
    local style = ns.Styles.GetActive()
    local renderer = renderers[style.id]
    if not renderer then
        renderer = style.CreateStatsRenderer(frame)
        renderers[style.id] = renderer
    end
    if activeRenderer ~= renderer then
        if activeRenderer then
            activeRenderer:Hide()
        end
        activeRenderer = renderer
        wipe(lastStatOrder)
    end
    renderer:Show()
    return renderer
end
local function LayoutChanged(stats)
    if #stats ~= #lastStatOrder then return true end
    for i, stat in ipairs(stats) do
        if lastStatOrder[i] ~= stat.id then return true end
    end
    return false
end
local lastDisplayedText = {}
local function ValueChanged(stat)
    if stat.isSecret then return true end
    if stat.text then
        if ns.IsSecretValue(stat.text) then
            lastDisplayedText[stat.id] = nil
            return true
        end
        if lastDisplayedText[stat.id] ~= stat.text then
            lastDisplayedText[stat.id] = stat.text
            return true
        end
        return false
    end
    local lastVal = lastDisplayedStats[stat.id]
    if not lastVal then return true end
    local ok, result = pcall(function()
        local wasZero = math.abs(lastVal) < 0.01
        local nowZero = math.abs(stat.value) < 0.01
        if wasZero ~= nowZero then return true end
        return math.abs(stat.value - lastVal) >= 0.01
    end)
    return not ok or result
end
local function GetBorderColor(db)
    if db.borderUseClassColor then
        local classColors = rawget(_G, "CUSTOM_CLASS_COLORS") or RAID_CLASS_COLORS
        local classColor = classColors and classColors[select(2, UnitClass("player"))]
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
    elseif db.borderColor then
        return db.borderColor.r, db.borderColor.g, db.borderColor.b
    end
    return 1, 1, 1
end
function StatsFrame:Create()
    if frame then return frame end
    local db = ns.db or ns.DEFAULTS
    frame = CreateFrame("Frame", "CharacterStatsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(150, 200)
    frame:SetPoint(db.anchor or "LEFT", UIParent, db.anchorTo or "LEFT", ns.PixelRound(db.x), ns.PixelRound(db.y))
    frame:SetMovable(true)
    frame:SetClampedToScreen(db.clampToScreen ~= false)
    frame:EnableMouse(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not ns.db.locked then
            self:StartMoving()
            self._isUserMoving = true
        end
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            if self._isUserMoving then
                self:StopMovingOrSizing()
                self._isUserMoving = false
                StatsFrame:SavePosition()
            end
        elseif button == "RightButton" and ns.Share then
            ns.Share.TogglePopup()
        end
    end)
    self:ApplyStyle()
    frame:SetScript("OnShow", function()
        StatsFrame:Refresh()
    end)
    return frame
end
function StatsFrame:ApplyStyle()
    if not frame then return end
    wipe(lastStatOrder)
    wipe(lastDisplayedStats)
    ns.Stats:Invalidate()
    local db = ns.db or ns.DEFAULTS
    frame:SetScale(1)
    frame.bg:SetColorTexture(0.05, 0.05, 0.08, db.bgAlpha)
    local border = BORDERS[db.borderStyle]
    if db.borderStyle == "none" or not border then
        frame:SetBackdrop(nil)
    else
        frame:SetBackdrop(border.backdrop)
        local r, g, b = GetBorderColor(db)
        local mute = border.mute and BORDER_MUTE or 1
        frame:SetBackdropBorderColor(r * mute, g * mute, b * mute, db.borderAlpha or 1)
    end
    for _, renderer in pairs(renderers) do
        renderer:Reset()
    end
    if frame:IsShown() then
        StatsFrame:Refresh()
    end
end
function StatsFrame:RefreshValuesOnly()
    if not frame or not frame:IsShown() then return end
    local stats = ns.Stats:CollectFiltered(true)
    if LayoutChanged(stats) then
        return self:Refresh()
    end
    local db = ns.db or ns.DEFAULTS
    local renderer = GetActiveRenderer()
    local ilvlColorDirty = ns._ilvlColorDirty
    for _, stat in ipairs(stats) do
        if ValueChanged(stat) then
            renderer:UpdateStat(stat, db)
            if not stat.isSecret then
                lastDisplayedStats[stat.id] = stat.value
            end
        end
        if ilvlColorDirty and stat.id == "ilvl" then
            renderer:UpdateColor(stat, db)
        end
    end
end
function StatsFrame:Refresh()
    if not frame or not frame:IsShown() then return end
    local stats = ns.Stats:CollectFiltered(true)
    local renderer = GetActiveRenderer()
    if not LayoutChanged(stats) and #lastStatOrder > 0 then
        return self:RefreshValuesOnly()
    end
    local db = ns.db or ns.DEFAULTS
    wipe(lastStatOrder)
    wipe(lastDisplayedStats)
    hasMoveSpeed = false
    for i, stat in ipairs(stats) do
        lastStatOrder[i] = stat.id
        if not stat.isSecret then
            lastDisplayedStats[stat.id] = stat.value
        end
        if stat.id == "movespeed" then
            hasMoveSpeed = true
        end
    end
    local width, height = renderer:Layout(stats, db)
    if not width or width <= 0 then
        frame:SetSize(1, 1)
        return
    end
    frame:SetSize(ns.PixelRound(width), ns.PixelRound(height))
end
function StatsFrame:RefreshMovementSpeedOnly()
    if not frame or not frame:IsShown() or not hasMoveSpeed or not activeRenderer then return end
    local def = ns.STAT_DEFS and ns.STAT_DEFS.movespeed
    if not def or not def.api then return end
    local ok, value = pcall(def.api)
    if not ok or value == nil then return end
    moveSpeedStat.value = value
    activeRenderer:UpdateStat(moveSpeedStat, ns.db or ns.DEFAULTS)
end
function StatsFrame:SavePosition()
    if not frame or not ns.db then return end
    local frameWidth, frameHeight = frame:GetSize()
    local frameLeft, frameBottom = frame:GetLeft(), frame:GetBottom()
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local anchor = ns.db.anchor or "LEFT"
    local x, y
    if anchor == "LEFT" or anchor == "TOPLEFT" or anchor == "BOTTOMLEFT" then
        x = frameLeft
    elseif anchor == "RIGHT" or anchor == "TOPRIGHT" or anchor == "BOTTOMRIGHT" then
        x = frameLeft + frameWidth - screenWidth
    else
        x = frameLeft + frameWidth / 2 - screenWidth / 2
    end
    if anchor == "TOP" or anchor == "TOPLEFT" or anchor == "TOPRIGHT" then
        y = frameBottom + frameHeight - screenHeight
    elseif anchor == "BOTTOM" or anchor == "BOTTOMLEFT" or anchor == "BOTTOMRIGHT" then
        y = frameBottom
    else
        y = frameBottom + frameHeight / 2 - screenHeight / 2
    end
    ns.db.x = ns.PixelRound(x)
    ns.db.y = ns.PixelRound(y)
    if ns.MarkProfileDirty then
        ns.MarkProfileDirty()
    end
end
function StatsFrame:RestorePosition()
    if not frame or not ns.db then return end
    frame:ClearAllPoints()
    frame:SetPoint(ns.db.anchor or "LEFT", UIParent, ns.db.anchorTo or "LEFT", ns.PixelRound(ns.db.x), ns.PixelRound(ns.db.y))
end
function StatsFrame:ResetPosition()
    if not ns.db then return end
    ns.db.anchor = ns.DEFAULTS.anchor
    ns.db.anchorTo = ns.DEFAULTS.anchorTo
    ns.db.x = ns.DEFAULTS.x
    ns.db.y = ns.DEFAULTS.y
    self:RestorePosition()
    self:Refresh()
end
local function IsAirborne()
    return (IsFlying and IsFlying()) or (IsFalling and IsFalling()) or false
end
local function OnFrameUpdate(self, elapsed)
    moveSpeedElapsed = moveSpeedElapsed + (elapsed or 0)
    if moveSpeedElapsed < MOVE_SPEED_UPDATE_INTERVAL then return end
    moveSpeedElapsed = 0
    StatsFrame:RefreshMovementSpeedOnly()
    if not ns._playerMoving and not IsAirborne() then
        self:SetScript("OnUpdate", nil)
    end
end
function StatsFrame:UpdateMovementTracking()
    if not frame then return end
    if frame:IsShown() and (ns._playerMoving or IsAirborne()) and not frame:GetScript("OnUpdate") then
        moveSpeedElapsed = MOVE_SPEED_UPDATE_INTERVAL
        frame:SetScript("OnUpdate", OnFrameUpdate)
    end
end
function StatsFrame:Show()
    if not frame then
        self:Create()
    end
    frame:Show()
    ns.db.showFrame = true
    self:Refresh()
    self:UpdateMovementTracking()
end
function StatsFrame:Hide()
    if frame then
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
    end
    ns.db.showFrame = false
end
function StatsFrame:Toggle()
    if frame and frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
function StatsFrame:IsShown()
    return frame and frame:IsShown()
end
function StatsFrame:GetFrame()
    return frame
end
