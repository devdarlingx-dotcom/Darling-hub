-- ========================================================================
-- Darling Hub - Combat Tracker (Project Spooky Engine)
-- Sticky target tracking: locks onto nearest enemy player, matches velocity,
-- and glues character behind target at customizable distance.
-- ========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Tracker = {
    Enabled = false,
    Active = false,
    Distance = 3.5,
    MaxRange = 650,
    LockedChar = nil,
    Connection = nil,
    Widget = nil,
}

local function getFloatingWidget()
    local env = (getgenv and getgenv()) or _G
    local hub = env.DarlingHub or _G.DarlingHub
    if hub and hub.Require then
        local ok, mod = pcall(function() return hub:Require("modules/pvp/floating_widget.lua") end)
        if ok and mod then return mod end
    end
    for _, p in ipairs({ "modules/pvp/floating_widget.lua", "darling-hub/modules/pvp/floating_widget.lua" }) do
        if isfile and isfile(p) then
            local ok, mod = pcall(function() return loadstring(readfile(p))() end)
            if ok and mod then return mod end
        end
    end
    return nil
end

function Tracker.startTracking()
    Tracker.Active = true
    if Tracker.Widget then Tracker.Widget:Set(true, true) end
    if Tracker.Connection then
        Tracker.Connection:Disconnect()
        Tracker.Connection = nil
    end

    Tracker.Connection = RunService.Stepped:Connect(function()
        if not Tracker.Active then
            Tracker.stopTracking()
            return
        end

        local char = LocalPlayer.Character
        local myHRP = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not myHRP then return end
        myHRP.CanCollide = false

        local targetChar = nil
        if Tracker.LockedChar and Tracker.LockedChar.Parent and Tracker.LockedChar:FindFirstChild("HumanoidRootPart") then
            local hum = Tracker.LockedChar:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                targetChar = Tracker.LockedChar
            end
        end

        if not targetChar then
            local closest = nil
            local closestDist = Tracker.MaxRange or 650
            local blacklist = _G.DarlingBlacklistedPlayers or _G.PlayerBlacklist or {}

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    if not (blacklist[p.UserId] or blacklist[p.Name]) then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local d = (p.Character.HumanoidRootPart.Position - myHRP.Position).Magnitude
                            if d < closestDist then
                                closest = p.Character
                                closestDist = d
                            end
                        end
                    end
                end
            end
            Tracker.LockedChar = closest
            targetChar = closest
        end

        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
            local tHrp = targetChar.HumanoidRootPart
            local tHum = targetChar:FindFirstChildOfClass("Humanoid")
            if tHum and tHum.Health > 0 and (myHRP.Position - tHrp.Position).Magnitude <= ((Tracker.MaxRange or 650) + 100) then
                local dist = tonumber(Tracker.Distance) or 3.5
                myHRP.CFrame = tHrp.CFrame * CFrame.new(0, 0, dist)
                myHRP.AssemblyLinearVelocity = tHrp.AssemblyLinearVelocity
            else
                Tracker.LockedChar = nil
            end
        end
    end)
end

function Tracker.stopTracking()
    Tracker.Active = false
    Tracker.LockedChar = nil
    if Tracker.Connection then
        Tracker.Connection:Disconnect()
        Tracker.Connection = nil
    end
    if Tracker.Widget then Tracker.Widget:Set(false, true) end
end

function Tracker.toggleTracking()
    if Tracker.Active then
        Tracker.stopTracking()
    else
        Tracker.startTracking()
    end
    return Tracker.Active
end

function Tracker.enable()
    Tracker.Enabled = true
    local FW = getFloatingWidget()
    if FW and not Tracker.Widget then
        Tracker.Widget = FW.create({
            Id = "TrackerWidget",
            Label = "TRACKER",
            Type = "Toggle",
            Position = UDim2.new(0.02, 0, 0.42, 0),
            AccentColor = Color3.fromRGB(255, 75, 145),
            Callback = function(state)
                if state then
                    Tracker.startTracking()
                else
                    Tracker.stopTracking()
                end
            end
        })
    elseif Tracker.Widget then
        Tracker.Widget:SetVisible(true)
    end
    return true
end

function Tracker.disable()
    Tracker.Enabled = false
    Tracker.stopTracking()
    if Tracker.Widget then
        Tracker.Widget:SetVisible(false)
    end
end

function Tracker.setDistance(dist)
    Tracker.Distance = tonumber(dist) or 3.5
end

function Tracker.setFloatingVisible(visible)
    if Tracker.Widget then
        Tracker.Widget:SetVisible(visible)
    end
end

function Tracker.destroy()
    Tracker.disable()
    if Tracker.Widget and Tracker.Widget.Destroy then
        Tracker.Widget:Destroy()
        Tracker.Widget = nil
    end
end

function Tracker.getDiagnostics()
    return {
        Name = "Tracker",
        Enabled = Tracker.Enabled,
        Active = Tracker.Active,
        Distance = Tracker.Distance,
        Locked = Tracker.LockedChar and Tracker.LockedChar.Name or "None",
    }
end

_G.DarlingTracker = Tracker
return Tracker
