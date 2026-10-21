--[[
    Darling Hub - Skill Blacklist Module
    Allows selective exclusion of skills from aimbot redirection.
]]--

local Blacklist = {}
local Core = nil

local function getCore()
    if Core then return Core end
    local env = (getgenv and getgenv()) or _G
    if env.DarlingCombatCore then
        Core = env.DarlingCombatCore
        return Core
    end
    if _G.DarlingCombatCore then
        Core = _G.DarlingCombatCore
        return Core
    end
    local hub = env.DarlingHub or _G.DarlingHub
    if hub and hub.Require then
        local ok, res = pcall(function()
            return hub:Require("modules/combat/aimbot_core.lua")
        end)
        if ok and res then
            Core = res
            env.DarlingCombatCore = Core
            _G.DarlingCombatCore = Core
            return Core
        end
    end
    for _, p in ipairs({ "modules/combat/aimbot_core.lua", "darling-hub/modules/combat/aimbot_core.lua" }) do
        if isfile and isfile(p) then
            local ok, res = pcall(function() return loadstring(readfile(p))() end)
            if ok and res then
                Core = res
                _G.DarlingCombatCore = Core
                return Core
            end
        end
    end
    return nil
end

function Blacklist.set(category, key, state)
    local core = getCore()
    local boolState = (state == true)

    if core and core.BlacklistedKeys[category] and core.BlacklistedKeys[category][key] ~= nil then
        core.BlacklistedKeys[category][key] = boolState
    end

    if _G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Blacklist then
        local b = _G.DarlingHub.Settings.Blacklist
        if b[category] and b[category][key] ~= nil then
            b[category][key] = boolState
        end
    end
end

function Blacklist.get(category, key)
    local core = getCore()
    if core and core.BlacklistedKeys[category] and core.BlacklistedKeys[category][key] ~= nil then
        return core.BlacklistedKeys[category][key]
    end
    if _G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Blacklist then
        local b = _G.DarlingHub.Settings.Blacklist
        if b[category] and b[category][key] ~= nil then
            return b[category][key]
        end
    end
    return false
end

function Blacklist.reset()
    local core = getCore()
    if core then
        for cat, keys in pairs(core.BlacklistedKeys) do
            for k, _ in pairs(keys) do
                core.BlacklistedKeys[cat][k] = false
            end
        end
    end
    if _G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Blacklist then
        local b = _G.DarlingHub.Settings.Blacklist
        for cat, keys in pairs(b) do
            for k, _ in pairs(keys) do
                b[cat][k] = false
            end
        end
    end
end

-- Applies array of strings like {"Melee Z", "Fruit C", "Sword X"}
function Blacklist.apply(selection)
    Blacklist.reset()
    if type(selection) ~= "table" then return end
    for _, item in ipairs(selection) do
        if type(item) == "string" then
            local cat, key = item:match("^(%a+)%s+(%a+)$")
            if cat and key then
                Blacklist.set(cat, key, true)
            end
        end
    end
end

function Blacklist.getTable()
    local core = getCore()
    if core then return core.BlacklistedKeys end
    if _G.DarlingHub and _G.DarlingHub.Settings then
        return _G.DarlingHub.Settings.Blacklist
    end
    return nil
end

return Blacklist
