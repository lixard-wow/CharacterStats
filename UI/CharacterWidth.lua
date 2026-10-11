local ADDON_NAME, ns = ...
local CharacterWidth = {}
ns.CharacterWidth = CharacterWidth
local MODEL_X, MODEL_Y = 52, -66
local BACKGROUND_LEFT_WIDTH = 212
local WEAPON_Y = 16
local FOREVER_PANE_WIDTH = 398
local FOREVER_BG_RIGHT = 79
local FOREVER_BG_BOTTOM = 129
local applied = 0
local layoutExtra = 0
local hooked = false
local paneTextures
local function IsForever()
    return not ns.IS_RETAIL and ns.BlizzardStats and ns.BlizzardStats.IsAvailable()
end
function CharacterWidth.IsSupported()
    if ns.IS_RETAIL or IsForever() then return true end
    return CharacterFrame ~= nil and CharacterFrame.Inset ~= nil
end
local function GetExtra()
    local db = ns.db
    if not db or not CharacterWidth.IsSupported() then return 0 end
    if CharacterFrame.activeSubframe ~= "PaperDollFrame" then return 0 end
    if ns.Integrations and ns.Integrations.CharacterFrameTaken() then return 0 end
    return math.max(0, math.floor(db.characterFrameExtraWidth or 50))
end
local function LayoutStandard(extra)
    local frame = CharacterFrame
    frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", PANEL_DEFAULT_WIDTH + PANEL_INSET_RIGHT_OFFSET + extra, PANEL_INSET_BOTTOM_OFFSET)
    if extra == layoutExtra then return end
    layoutExtra = extra
    local model = rawget(_G, "CharacterModelScene")
    if model then
        local half = math.floor(extra / 2)
        model:ClearAllPoints()
        model:SetPoint("TOPLEFT", model:GetParent(), "TOPLEFT", MODEL_X + half, MODEL_Y)
        if model.BackgroundTopLeft then
            model.BackgroundTopLeft:SetWidth(BACKGROUND_LEFT_WIDTH + extra)
            model.BackgroundTopLeft:ClearAllPoints()
            model.BackgroundTopLeft:SetPoint("TOPLEFT", model, "TOPLEFT", -half, 0)
        end
        if model.BackgroundBotLeft then model.BackgroundBotLeft:SetWidth(BACKGROUND_LEFT_WIDTH + extra) end
    end
    local weapon = rawget(_G, "CharacterMainHandSlot")
    if weapon then
        weapon:ClearAllPoints()
        weapon:SetPoint("BOTTOMLEFT", weapon:GetParent(), "BOTTOMLEFT", (ns.IS_RETAIL and 130 or 106) + math.floor(extra / 2), WEAPON_Y)
    end
end
local function GetPaneTextures(host)
    if paneTextures then return paneTextures end
    paneTextures = {}
    for _, region in ipairs({ host:GetRegions() }) do
        if region:IsObjectType("Texture") then
            paneTextures[#paneTextures + 1] = { texture = region, width = region:GetWidth() }
        end
    end
    return paneTextures
end
local function LayoutForever(extra)
    local host = CharacterFrame.LeftPaneHost
    if not host then return end
    host:SetWidth(FOREVER_PANE_WIDTH + extra)
    if extra == layoutExtra then return end
    layoutExtra = extra
    for _, info in ipairs(GetPaneTextures(host)) do
        info.texture:SetWidth(info.width + extra)
    end
    local model = rawget(_G, "CharacterModelScene")
    local stripHost = model and model:GetParent().TopBackgroundStripHost
    local strip = stripHost and stripHost.TopBackgroundStrip
    if not strip then return end
    local half = math.floor(extra / 2)
    model:ClearAllPoints()
    model:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", half, 0)
    model:SetPoint("TOPRIGHT", strip, "BOTTOMRIGHT", -half, 0)
    model:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -half, 0)
    local topLeft, topRight = model.BackgroundTopLeft, model.BackgroundTopRight
    local botLeft, botRight = model.BackgroundBotLeft, model.BackgroundBotRight
    if topLeft then
        topLeft:ClearAllPoints()
        topLeft:SetPoint("TOPLEFT", model, "TOPLEFT", -half, 0)
        topLeft:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", half - FOREVER_BG_RIGHT, FOREVER_BG_BOTTOM)
    end
    if topRight then
        topRight:ClearAllPoints()
        topRight:SetPoint("TOPRIGHT", model, "TOPRIGHT", half, 0)
        topRight:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", half, FOREVER_BG_BOTTOM)
    end
    if botLeft then
        botLeft:ClearAllPoints()
        botLeft:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", -half, 0)
        botLeft:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", half - FOREVER_BG_RIGHT, 0)
    end
    if botRight then
        botRight:ClearAllPoints()
        botRight:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", half, 0)
    end
    if model.BackgroundOverlay and topLeft and botRight then
        model.BackgroundOverlay:ClearAllPoints()
        model.BackgroundOverlay:SetPoint("TOPLEFT", topLeft, "TOPLEFT")
        model.BackgroundOverlay:SetPoint("BOTTOMRIGHT", botRight, "BOTTOMRIGHT")
    end
end
local function Layout(extra)
    if IsForever() then
        LayoutForever(extra)
    else
        LayoutStandard(extra)
    end
end
local function OnUpdateSize(frame)
    local extra = GetExtra()
    applied = extra
    if frame.activeSubframe ~= "PaperDollFrame" then
        if IsForever() then
            LayoutForever(0)
        end
        return
    end
    if extra > 0 then
        frame:SetWidth(frame:GetWidth() + extra)
    end
    Layout(extra)
end
function CharacterWidth.Apply()
    if not CharacterWidth.IsSupported() or not CharacterFrame or not CharacterFrame.UpdateSize then return end
    if not hooked then
        hooked = true
        hooksecurefunc(CharacterFrame, "UpdateSize", OnUpdateSize)
    end
    if CharacterFrame.activeSubframe ~= "PaperDollFrame" then return end
    local extra = GetExtra()
    if extra ~= applied then
        CharacterFrame:SetWidth(CharacterFrame:GetWidth() - applied + extra)
        applied = extra
    end
    Layout(extra)
end
