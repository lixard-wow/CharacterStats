local ADDON_NAME, ns = ...
local Window = {}
ns.Window = Window
local looks = {}
local lookOrder = {}
local frames = {}
local hooked = false
local OUR_SUBFRAMES = { PaperDollFrame = true, ReputationFrame = true, TokenFrame = true }
local blizzardOverride
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
local function SavePosition()
    local db = ns.db
    if not db or not CharacterFrame then return end
    local left, top = CharacterFrame:GetLeft(), CharacterFrame:GetTop()
    if left and top then
        db.characterWindowPos = { x = math.floor(left + 0.5), y = math.floor(top + 0.5) }
    end
end
local function RestorePosition()
    local pos = ns.db and ns.db.characterWindowPos
    if not pos or not CharacterFrame then return end
    CharacterFrame:ClearAllPoints()
    CharacterFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
end
local function OnDragStart()
    if not CharacterFrame then return end
    CharacterFrame:SetMovable(true)
    CharacterFrame:SetClampedToScreen(true)
    CharacterFrame:StartMoving()
end
local function OnDragStop()
    if not CharacterFrame then return end
    CharacterFrame:StopMovingOrSizing()
    CharacterFrame:SetUserPlaced(false)
    SavePosition()
end
local function OnResetClick(_, button)
    if button == "RightButton" and ns.db and ns.db.characterWindowPos then
        ns.db.characterWindowPos = nil
        ns.PrintMsg(ns.L.WINDOW_POSITION_RESET or "Character window position reset. It returns to its default spot next time you open it.")
    end
end
function Window.MakeDraggable(frame)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", OnDragStart)
    frame:SetScript("OnDragStop", OnDragStop)
    frame:SetScript("OnMouseUp", OnResetClick)
end
local function GetFrame(id)
    local frame = frames[id]
    if frame then return frame end
    local look = looks[id]
    if not look then return nil end
    frame = look.Create()
    Window.MakeDraggable(frame)
    if frame.rep then Window.MakeDraggable(frame.rep) end
    if frame.cur then Window.MakeDraggable(frame.cur) end
    frame:Hide()
    frames[id] = frame
    return frame
end
local function HideFrames()
    if ns.WindowFlyout then ns.WindowFlyout.Hide() end
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
    local sub = CharacterFrame.activeSubframe or ""
    if not CharacterFrame:IsShown() or (blizzardOverride and blizzardOverride ~= sub) then
        blizzardOverride = nil
    end
    local want = CharacterFrame:IsShown() and Window.IsEnabled()
        and OUR_SUBFRAMES[sub] == true and blizzardOverride ~= sub
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
    if not frame:IsShown() then
        RestorePosition()
    end
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
function Window.ShowBlizzard(subFrame)
    blizzardOverride = subFrame
    Window.Sync()
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
