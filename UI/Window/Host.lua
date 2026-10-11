local ADDON_NAME, ns = ...
local Window = {}
ns.Window = Window
local looks = {}
local lookOrder = {}
local frames = {}
local hooked = false
local pending = false
local OUR_SUBFRAMES = { PaperDollFrame = true }
function Window.RegisterLook(id, def)
    if not looks[id] then
        lookOrder[#lookOrder + 1] = id
    end
    def.id = id
    looks[id] = def
end
function Window.GetLooks()
    local list = {}
    for _, id in ipairs(lookOrder) do
        list[#list + 1] = looks[id]
    end
    return list
end
function Window.GetLookId()
    local db = ns.db
    local id = db and db.characterWindowLook
    if id and looks[id] then return id end
    return lookOrder[1]
end
function Window.IsSupported()
    return ns.IS_RETAIL and CharacterFrame ~= nil and CharacterFrame.ShowSubFrame ~= nil
end
function Window.IsEnabled()
    local db = ns.db
    if not db or not db.characterWindow or not Window.IsSupported() then return false end
    if ns.Integrations and ns.Integrations.CharacterFrameTaken() then return false end
    return true
end
local function Wanted()
    return Window.IsEnabled() and OUR_SUBFRAMES[CharacterFrame.activeSubframe or ""] == true
end
local function ActiveFrame()
    return frames[Window.GetLookId()]
end
function Window.IsActive()
    local frame = ActiveFrame()
    return frame ~= nil and frame:IsVisible()
end
local function GetFrame(id)
    local frame = frames[id]
    if frame then return frame end
    local look = looks[id]
    if not look or InCombatLockdown() then return nil end
    frame = look.Create()
    frame:Hide()
    frame:SetParent(CharacterFrame)
    frame:SetIgnoreParentAlpha(true)
    frame:SetFrameStrata("HIGH")
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
    frames[id] = frame
    return frame
end
local function UpdateBlizzardAlpha()
    if not CharacterFrame then return end
    local covering = Window.IsActive()
    CharacterFrame:SetAlpha(covering and 0 or 1)
    if covering then
        if ns.CompanionDrawer then ns.CompanionDrawer:Hide() end
    elseif CharacterFrame:IsShown() and ns.PaperdollPanel then
        ns.PaperdollPanel:ApplyStyle()
    end
end
function Window.Sync()
    if not CharacterFrame then return end
    local want = Wanted()
    local id = Window.GetLookId()
    if InCombatLockdown() then
        local frame = frames[id]
        local shownFlag = frame and frame:IsShown()
        if (want and not shownFlag) or (not want and shownFlag) then
            pending = true
        end
        for otherId, other in pairs(frames) do
            if otherId ~= id and other:IsShown() then pending = true end
        end
        UpdateBlizzardAlpha()
        return
    end
    pending = false
    for otherId, other in pairs(frames) do
        if otherId ~= id then other:Hide() end
    end
    local frame = want and GetFrame(id) or frames[id]
    if frame then
        frame:SetShown(want)
    end
    UpdateBlizzardAlpha()
    if want and frame and CharacterFrame:IsShown() and frame.Refresh then
        frame:Refresh()
    end
end
function Window.OnBlizzardHidden()
    if CharacterFrame then
        CharacterFrame:SetAlpha(1)
    end
end
function Window.Close()
    if CharacterFrame and CharacterFrame:IsShown() then
        HideUIPanel(CharacterFrame)
    end
end
function Window.ShowTab(subFrame)
    if CharacterFrame and CharacterFrame:IsShown() and CharacterFrame.activeSubframe ~= subFrame then
        ToggleCharacter(subFrame, true)
    end
end
function Window.UpdateCooldowns()
    local frame = ActiveFrame()
    if frame and frame:IsVisible() and ns.WindowParts then
        ns.WindowParts.UpdateCooldowns(frame)
    end
end
function Window.Refresh()
    local frame = ActiveFrame()
    if frame and frame:IsVisible() and frame.Refresh then
        frame:Refresh()
    end
end
function Window.Apply()
    if not Window.IsSupported() then return end
    if not hooked then
        hooked = true
        CharacterFrame:HookScript("OnShow", Window.Sync)
        CharacterFrame:HookScript("OnHide", Window.OnBlizzardHidden)
        hooksecurefunc(CharacterFrame, "ShowSubFrame", Window.Sync)
        local events = CreateFrame("Frame")
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        events:SetScript("OnEvent", function()
            if pending then
                Window.Sync()
            end
        end)
    end
    if Window.IsEnabled() and not InCombatLockdown() then
        GetFrame(Window.GetLookId())
    end
    Window.Sync()
end
function Window.HideAll()
    Window.Sync()
end
