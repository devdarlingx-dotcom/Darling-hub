--[[
    Darling Hub - NPC Aimbot Module
    Dedicated module for NPC / Mob Silent Aim in Blox Fruits.
]]--

local NPCAimbot = {}
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

function NPCAimbot.enable()
    local core = getCore()
    if not core then return false end
    core.NPCAimEnabled = true
    core.startLoop()
    return true
end

function NPCAimbot.disable()
    local core = getCore()
    if not core then return end
    core.NPCAimEnabled = false
    core.stopLoop()
end

function NPCAimbot.setMaxRange(range)
    local core = getCore()
    if core and type(range) == "number" then
        core.MaxRange = range
    end
end

function NPCAimbot.isEnabled()
    local core = getCore()
    return core and core.NPCAimEnabled or false
end

return NPCAimbot
