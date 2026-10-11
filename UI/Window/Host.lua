local ADDON_NAME, ns = ...
local Window = {}
ns.Window = Window
local looks = {}
local lookOrder = {}
local frames = {}
local hooked = false
local OUR_SUBFRAMES = { PaperDollFrame = true, ReputationFrame = true }
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
local function ActiveFrame()
    return frames[Window.GetLookId()]
end
function Window.IsActive()
    local frame = ActiveFrame()
    return frame ~= nil and frame:IsShown()
end
local function GetFrame(id)
    local frame = frames[id]
    if frame then return frame end
    local look = looks[id]
    if not look then return nil end
    frame = look.Create()
    frame:Hide()
    frames[id] = frame
    return frame
end
local function HideFrames()
    local wasShown = false
    for _, frame in pairs(frames) do
        if frame:IsShown() then
            wasShown = true
            frame:Hide()
        end
    end
    return wasShown
end
function Window.Sync()
    if not CharacterFrame then return end
    local want = CharacterFrame:IsShown() and Window.IsEnabled()
        and OUR_SUBFRAMES[CharacterFrame.activeSubframe or ""] == true
    if not want then
        if HideFrames() then
            CharacterFrame:SetAlpha(1)
            if CharacterFrame:IsShown() and ns.PaperdollPanel then
                ns.PaperdollPanel:ApplyStyle()
            end
        end
        return
    end
    local id = Window.GetLookId()
    for otherId, other in pairs(frames) do
        if otherId ~= id then other:Hide() end
    end
    local frame = GetFrame(id)
    if not frame then return end
    if ns.CompanionDrawer then
        ns.CompanionDrawer:Hide()
    end
    CharacterFrame:SetAlpha(0)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
    frame:Show()
    if frame.ShowTab then
        frame:ShowTab(CharacterFrame.activeSubframe)
    end
    if frame.Refresh then
        frame:Refresh()
    end
end
function Window.HideAll()
    Window.Sync()
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
    if frame and frame:IsShown() and ns.WindowParts then
        ns.WindowParts.UpdateCooldowns(frame)
    end
end
function Window.Refresh()
    local frame = ActiveFrame()
    if frame and frame:IsShown() and frame.Refresh then
        frame:Refresh()
    end
end
function Window.Apply()
    if not Window.IsSupported() then return end
    if not hooked then
        hooked = true
        CharacterFrame:HookScript("OnShow", Window.Sync)
        CharacterFrame:HookScript("OnHide", Window.Sync)
        hooksecurefunc(CharacterFrame, "ShowSubFrame", Window.Sync)
    end
    if ns.CharacterWidth then
        ns.CharacterWidth.Apply()
    end
    Window.Sync()
end
