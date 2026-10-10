local ADDON_NAME, ns = ...
local CharacterWidth = {}
ns.CharacterWidth = CharacterWidth
local MODEL_X, MODEL_Y = 52, -66
local BACKGROUND_LEFT_WIDTH = 212
local WEAPON_X, WEAPON_Y = 130, 16
local applied = 0
local layoutExtra = 0
local hooked = false
local function GetExtra()
    local db = ns.db
    if not db or ns.IS_CLASSIC then return 0 end
    if CharacterFrame.activeSubframe ~= "PaperDollFrame" then return 0 end
    if ns.Integrations and ns.Integrations.CharacterFrameTaken() then return 0 end
    return math.max(0, math.floor(db.characterFrameExtraWidth or 0))
end
local function Layout(extra)
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
        weapon:SetPoint("BOTTOMLEFT", weapon:GetParent(), "BOTTOMLEFT", WEAPON_X + math.floor(extra / 2), WEAPON_Y)
    end
end
local function OnUpdateSize(frame)
    local extra = GetExtra()
    applied = extra
    if frame.activeSubframe ~= "PaperDollFrame" then return end
    if extra > 0 then
        frame:SetWidth(frame:GetWidth() + extra)
    end
    Layout(extra)
end
function CharacterWidth.Apply()
    if ns.IS_CLASSIC or not CharacterFrame or not CharacterFrame.UpdateSize or not CharacterFrame.Inset then return end
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
