local ADDON_NAME, ns = ...
local Window = {}
ns.Window = Window
local looks = {}
local lookOrder = {}
local frames = {}
local activeFrame
local hooked = false
local pendingShow = false
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
function Window.IsActive()
    return activeFrame ~= nil and activeFrame:IsShown()
end
local function GetFrame(id)
    local frame = frames[id]
    if frame then return frame end
    local look = looks[id]
    if not look or InCombatLockdown() then return nil end
    frame = look.Create()
    frame:Hide()
    frames[id] = frame
    return frame
end
local function RestoreBlizzard()
    if CharacterFrame then
        CharacterFrame:SetAlpha(1)
    end
    if ns.PaperdollPanel and CharacterFrame and CharacterFrame:IsShown() then
        ns.PaperdollPanel:ApplyStyle()
    end
end
function Window.HideAll()
    for _, frame in pairs(frames) do
        frame:Hide()
    end
    if activeFrame then
        activeFrame = nil
        RestoreBlizzard()
    end
end
function Window.Sync()
    if not CharacterFrame or not CharacterFrame:IsShown() or not Window.IsEnabled()
        or not OUR_SUBFRAMES[CharacterFrame.activeSubframe or ""] then
        Window.HideAll()
        return
    end
    local id = Window.GetLookId()
    local frame = GetFrame(id)
    if not frame then
        pendingShow = true
        Window.HideAll()
        return
    end
    for otherId, other in pairs(frames) do
        if otherId ~= id then other:Hide() end
    end
    if ns.CompanionDrawer then
        ns.CompanionDrawer:Hide()
    end
    CharacterFrame:SetAlpha(0)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
    activeFrame = frame
    frame:Show()
    if frame.Refresh then
        frame:Refresh()
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
    if activeFrame and activeFrame:IsShown() and ns.WindowParts then
        ns.WindowParts.UpdateCooldowns(activeFrame)
    end
end
function Window.Refresh()
    if activeFrame and activeFrame:IsShown() and activeFrame.Refresh then
        activeFrame:Refresh()
    end
end
function Window.Apply()
    if not Window.IsSupported() then return end
    if not hooked then
        hooked = true
        CharacterFrame:HookScript("OnShow", Window.Sync)
        CharacterFrame:HookScript("OnHide", Window.HideAll)
        hooksecurefunc(CharacterFrame, "ShowSubFrame", Window.Sync)
        local events = CreateFrame("Frame")
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        events:SetScript("OnEvent", function()
            if pendingShow then
                pendingShow = false
                Window.Sync()
            end
        end)
    end
    if Window.IsEnabled() and not InCombatLockdown() then
        GetFrame(Window.GetLookId())
    end
    Window.Sync()
end
