local ADDON_NAME, ns = ...
local CharacterButton = {}
ns.CharacterButton = CharacterButton
local TAB_TEXTURE = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs"
local ICON_TEXTURE = "Interface\\AddOns\\CharacterStats\\Assets\\CharacterStats_minimap_32x32.tga"
local TAB_MARGIN = 30
local TAB_GAP = 4
local button
local originalTabs
local function GetLastTab()
    local last
    for index = 1, 8 do
        local tab = rawget(_G, "PaperDollSidebarTab" .. index)
        if not tab then break end
        if index == 1 or tab:IsShown() then
            if not last or (tab:GetRight() or 0) >= (last:GetRight() or 0) then
                last = tab
            end
        end
    end
    return last or rawget(_G, "PaperDollSidebarTab3")
end
local function BuildRetailLook(btn)
    btn:SetSize(33, 35)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetTexture(TAB_TEXTURE)
    btn.bg:SetSize(50, 43)
    btn.bg:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", -9, -2)
    btn.bg:SetTexCoord(0.015625, 0.796875, 0.61328125, 0.78125)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetTexture(ICON_TEXTURE)
    btn.icon:SetSize(24, 24)
    btn.icon:SetPoint("BOTTOM", btn, "BOTTOM", 1, 3)
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetTexture(TAB_TEXTURE)
    btn.highlight:SetSize(31, 31)
    btn.highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -3)
    btn.highlight:SetTexCoord(0.015625, 0.5, 0.1953125, 0.31640625)
end
local function BuildForeverLook(btn)
    btn:SetSize(42, 42)
    btn.icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.icon:SetTexture(ICON_TEXTURE)
    btn.icon:SetSize(30, 30)
    btn.icon:SetPoint("CENTER")
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetAtlas("UI-Character-Info-StatTab", true)
    btn.border:SetPoint("CENTER")
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAtlas("UI-Character-Info-StatTab-Selected", true)
    btn.highlight:SetPoint("CENTER")
    btn.highlight:SetAlpha(0.6)
end
local function Create()
    if button then return button end
    local tabs = rawget(_G, "PaperDollSidebarTabs")
    if not tabs or not GetLastTab() then return nil end
    button = CreateFrame("Button", "CharacterStatsSidebarButton", tabs)
    if ns.PaperdollPanel and ns.PaperdollPanel.UsesBlizzardStatList() then
        BuildForeverLook(button)
        button.gap = 0
    else
        BuildRetailLook(button)
        button.gap = 4
    end
    button:SetScript("OnClick", function()
        if ns.ConfigPanel then
            ns.ConfigPanel:Toggle()
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.L.ADDON_TITLE or "CharacterStats", 1, 0.5, 0)
        GameTooltip:AddLine(ns.L.TIP_OPEN_OPTIONS or "Open options", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    tabs:HookScript("OnShow", CharacterButton.Apply)
    return button
end
local function CenterTabs(on)
    local tabs = rawget(_G, "PaperDollSidebarTabs")
    local last = rawget(_G, "PaperDollSidebarTab3")
    if not tabs or not last or not button then return end
    local forever = ns.PaperdollPanel and ns.PaperdollPanel.UsesBlizzardStatList()
    local inset = rawget(_G, "CharacterFrameInsetRight")
    if not forever and not inset then return end
    if on and not forever and GetLastTab() ~= last then on = false end
    if not originalTabs then
        if not on then return end
        originalTabs = {
            width = tabs:GetWidth(),
            tabsPoint = { tabs:GetPoint(1) },
            lastPoint = { last:GetPoint(1) },
        }
    end
    local extra = button.gap + button:GetWidth()
    tabs:ClearAllPoints()
    if forever then
        local point, relativeTo, relativePoint, x, y = unpack(originalTabs.tabsPoint)
        tabs:SetPoint(point, relativeTo, relativePoint, (x or 0) - (on and extra / 2 or 0), y or 0)
        return
    end
    last:ClearAllPoints()
    if on then
        local groupWidth = last:GetWidth() * 3 + TAB_GAP * 2 + extra
        tabs:SetWidth(groupWidth + TAB_MARGIN * 2)
        tabs:SetPoint("BOTTOM", inset, "TOP", 0, originalTabs.tabsPoint[5] or 0)
        last:SetPoint("BOTTOMRIGHT", tabs, "BOTTOMRIGHT", -(TAB_MARGIN + extra), 0)
    else
        tabs:SetWidth(originalTabs.width)
        tabs:SetPoint(unpack(originalTabs.tabsPoint))
        last:SetPoint(unpack(originalTabs.lastPoint))
    end
end
function CharacterButton.Place()
    if not button then return end
    CenterTabs(true)
    local anchor = GetLastTab()
    button:ClearAllPoints()
    button:SetPoint("LEFT", anchor, "RIGHT", button.gap or 4, 0)
end
function CharacterButton.Apply()
    local db = ns.db
    local show = db and db.characterButton ~= false
    if show and ns.Integrations and ns.Integrations.CharacterFrameTaken() then
        show = false
    end
    if not show then
        if button then button:Hide() end
        CenterTabs(false)
        return
    end
    if Create() then
        if ns.Integrations then
            ns.Integrations.StyleButtonForElvUI(button)
        end
        CharacterButton.Place()
        button:Show()
    end
end
