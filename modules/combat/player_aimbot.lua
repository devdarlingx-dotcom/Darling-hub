--[[
    Darling Hub - Player Aimbot Module
    Dedicated module for Player Silent Aim, hitboxes, priority, and modes.
]]--

local Players = game:GetService("Players")

local PlayerAimbot = {}
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

function PlayerAimbot.enable()
    local core = getCore()
    if not core then return false end
    core.PlayerAimEnabled = true
    core.startLoop()
    return true
end

function PlayerAimbot.disable()
    local core = getCore()
    if not core then return end
    core.PlayerAimEnabled = false
    core.stopLoop()
end

function PlayerAimbot.setHitbox(part)
    local core = getCore()
    if core and type(part) == "string" then
        core.TargetHitbox = part
    end
end

function PlayerAimbot.setPriority(prio)
    local core = getCore()
    if core and type(prio) == "string" then
        core.TargetPriority = prio
    end
end

function PlayerAimbot.setAimMode(mode)
    local core = getCore()
    if core and type(mode) == "string" then
        core.AimMode = mode
    end
end

function PlayerAimbot.setSelectedPlayer(name)
    local core = getCore()
    if not core then return end
    if not name or name == "" or name == "None" then
        core.SelectedPlayer = nil
    else
        core.SelectedPlayer = Players:FindFirstChild(name)
    end
end

function PlayerAimbot.setMaxRange(range)
    local core = getCore()
    if core and type(range) == "number" then
        core.MaxRange = range
    end
end

function PlayerAimbot.setPrediction(enabled, amount)
    local core = getCore()
    if core then
        if enabled ~= nil then core.PredictionEnabled = enabled end
        if type(amount) == "number" then core.PredictionAmount = amount end
    end
end

function PlayerAimbot.isEnabled()
    local core = getCore()
    return core and core.PlayerAimEnabled or false
end

return PlayerAimbot
