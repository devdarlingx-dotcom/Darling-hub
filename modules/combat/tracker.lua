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

function Tracker.destroyWidget()
    if Tracker.Widget then
        pcall(function()
            if Tracker.Widget.Destroy then
                Tracker.Widget:Destroy()
            elseif Tracker.Widget.Pill and Tracker.Widget.Pill.Parent then
                Tracker.Widget.Pill:Destroy()
            end
        end)
        Tracker.Widget = nil
    end
    -- Also clean up any lingering widget in shared ScreenGui
    pcall(function()
        local env = (getgenv and getgenv()) or _G
        local hub = env.DarlingHub or _G.DarlingHub
        local overlay = (hub and hub.GetOverlay and hub:GetOverlay())
        if overlay then
            local leftover = overlay:FindFirstChild("TrackerWidget")
            if leftover then leftover:Destroy() end
        end
        local CoreGui = game:GetService("CoreGui")
        local sg = CoreGui:FindFirstChild("DarlingHub_FloatingWidgets")
        if sg then
            local w = sg:FindFirstChild("TrackerWidget")
            if w then w:Destroy() end
        end
    end)
end

function Tracker.setWidgetVisible(visible)
    if not visible then
        Tracker.destroyWidget()
    else
        if not Tracker.Widget then
            local FW = getFloatingWidget()
            if FW then
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
                if Tracker.Active and Tracker.Widget then
                    Tracker.Widget:Set(true, true)
                end
            end
        else
            Tracker.Widget:SetVisible(true)
        end
    end
end

function Tracker.enable()
    Tracker.Enabled = true
    return true
end

function Tracker.disable()
    Tracker.Enabled = false
    Tracker.stopTracking()
    Tracker.destroyWidget()
    return true
end

function Tracker.setDistance(dist)
    Tracker.Distance = tonumber(dist) or 3.5
end

function Tracker.setFloatingVisible(visible)
    Tracker.setWidgetVisible(visible)
end

function Tracker.destroy()
    Tracker.disable()
    Tracker.destroyWidget()
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
