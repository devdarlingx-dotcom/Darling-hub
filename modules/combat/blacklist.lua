--[[
    Darling Hub - Skill Blacklist Module
    Allows selective exclusion of skills from aimbot redirection.
]]--

local Blacklist = {}
local Core = nil

local function getCore()
    if Core then return Core end
    if _G.DarlingCombatCore then
        Core = _G.DarlingCombatCore
        return Core
    end

    local paths = {
        "modules/combat/aimbot_core.lua",
        "darling-hub/modules/combat/aimbot_core.lua",
    }

    for _, p in ipairs(paths) do
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
    if not core then return end
    if core.BlacklistedKeys[category] and core.BlacklistedKeys[category][key] ~= nil then
        core.BlacklistedKeys[category][key] = (state == true)
    end
end

function Blacklist.get(category, key)
    local core = getCore()
    if not core then return false end
    if core.BlacklistedKeys[category] and core.BlacklistedKeys[category][key] ~= nil then
        return core.BlacklistedKeys[category][key]
    end
    return false
end

function Blacklist.reset()
    local core = getCore()
    if not core then return end
    for cat, keys in pairs(core.BlacklistedKeys) do
        for k, _ in pairs(keys) do
            core.BlacklistedKeys[cat][k] = false
        end
    end
end

function Blacklist.getTable()
    local core = getCore()
    if core then
        return core.BlacklistedKeys
    end
    return nil
end

return Blacklist
