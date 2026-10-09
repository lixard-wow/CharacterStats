local addonName, CS = ...
local ConfigPanel = CS.ConfigPanel
local function AddText(parent, anchor, text, colorKey, alpha, gap)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -(gap or 6))
    fs:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    CS.ConfigWidgets.ApplyFontColor(fs, colorKey, alpha)
    return fs
end
local function CreateAboutPage(container)
    local Widgets = CS.ConfigWidgets
    local L = CS.L
    local header = Widgets.CreateSectionHeader(container, L.HEADER_INFO or "About")
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -4)
    header:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -4)
    local version = AddText(container, header, string.format("%s: %s", L.LABEL_VERSION or "Version", CS.VERSION or ""), "textPrimary", 1, 8)
    local author = AddText(container, version, string.format("%s: %s", L.LABEL_AUTHOR or "Author", CS.AUTHOR or L.UNKNOWN or "Unknown"), "textMuted")
    local desc = AddText(container, author, L.ADDON_DESC or "A lightweight character stats addon.", "textMuted", 0.8, 10)
    local cmdHeader = Widgets.CreateSectionHeader(container, L.HEADER_COMMANDS or "Slash Commands")
    cmdHeader:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -18)
    cmdHeader:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    AddText(container, cmdHeader, (L.CMD_TOGGLE or "/cs - Toggle stats frame") .. "\n" .. (L.CMD_CONFIG or "/cs config - Open options") .. "\n" .. (L.CMD_STYLE or "/cs style - Choose a look"), "textMuted", 1, 8)
    return {}
end
ConfigPanel.RegisterPage("about", {
    label = CS.L.NAV_ABOUT or "About",
    labelKey = "NAV_ABOUT",
    order = 5,
    create = CreateAboutPage,
})
