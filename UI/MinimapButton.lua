local ADDON_NAME, ns = ...
local MinimapButton = {}
ns.MinimapButton = MinimapButton
local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local icon = LDB and LibStub("LibDBIcon-1.0", true)
local ICON_TEXTURE = "Interface\\AddOns\\CharacterStats\\Assets\\CharacterStats_minimap_32x32.tga"
local function UpdateButtonPosition(button)
    if not button or not button.db then return end
    local angle = math.rad(button.db.minimapPos or 225)
    local radius = (Minimap:GetWidth() / 2) + 8
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
if LDB and icon then
    local dataObj = LDB:NewDataObject("CharacterStats", {
        type = "launcher",
        text = "CharacterStats",
        icon = ICON_TEXTURE,
        OnClick = function(self, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    ns.StatsFrame:ResetPosition()
                    ns.PrintMsg(ns.L.MSG_RESET or "Position reset.")
                else
                    ns.ConfigPanel:Toggle()
                end
            elseif button == "RightButton" then
                ns.StatsFrame:Toggle()
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("|cffff8000" .. (ns.L.ADDON_TITLE or "CharacterStats") .. "|r")
            tooltip:AddLine(" ")
            local L = ns.L
            tooltip:AddDoubleLine(L.TIP_LEFT_CLICK or "Left-click", L.TIP_OPTIONS or "Options", 1, 0.8, 0, 0.9, 0.9, 0.9)
            tooltip:AddDoubleLine(L.TIP_RIGHT_CLICK or "Right-click", L.TIP_TOGGLE_STATS or "Toggle stats", 1, 0.8, 0, 0.9, 0.9, 0.9)
            tooltip:AddDoubleLine(L.TIP_SHIFT_CLICK or "Shift-click", L.TIP_RESET_POSITION or "Reset position", 1, 0.8, 0, 0.9, 0.9, 0.9)
        end,
    })
    function MinimapButton:Show()
        if not ns.db.minimap then
            ns.db.minimap = {
                hide = false,
                minimapPos = 225,
                lock = false,
            }
        end
        if ns.db.minimap.minimapPos == nil then
            ns.db.minimap.minimapPos = 225
        end
        if not icon:IsRegistered("CharacterStats") then
            icon:Register("CharacterStats", dataObj, ns.db.minimap)
            local iconButton = icon:GetMinimapButton("CharacterStats")
            if iconButton then
                iconButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                iconButton:EnableMouse(true)
                if iconButton.icon then
                    iconButton.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
                end
                UpdateButtonPosition(iconButton)
            end
        else
            local iconButton = icon:GetMinimapButton("CharacterStats")
            if iconButton then
                UpdateButtonPosition(iconButton)
            end
        end
        icon:Show("CharacterStats")
        ns.db.minimap.hide = false
    end
    function MinimapButton:Hide()
        if icon:IsRegistered("CharacterStats") then
            icon:Hide("CharacterStats")
            if ns.db.minimap then
                ns.db.minimap.hide = true
            end
        end
    end
    function MinimapButton:Toggle()
        if self:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    end
    function MinimapButton:IsShown()
        if icon:IsRegistered("CharacterStats") then
            return not ns.db.minimap or not ns.db.minimap.hide
        end
        return false
    end
    function MinimapButton:ResetPosition()
        if ns.db.minimap then
            ns.db.minimap.minimapPos = 225
            ns.db.minimap.lock = false
            if icon:IsRegistered("CharacterStats") then
                local iconButton = icon:GetMinimapButton("CharacterStats")
                if iconButton then
                    UpdateButtonPosition(iconButton)
                end
            end
        end
    end
end
