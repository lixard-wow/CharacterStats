local ADDON_NAME, ns = ...

if GetLocale() ~= "enGB" then return end

local L = ns.L

local translations = {
}

for k, v in pairs(translations) do
    L[k] = v
end
