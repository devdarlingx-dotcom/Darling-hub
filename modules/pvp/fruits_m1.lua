-- fruits m1

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local FloatingWidget = nil
pcall(function()
    FloatingWidget = (_G.DarlingHub and _G.DarlingHub:Require("modules/pvp/floating_widget.lua"))
end)

local FruitsM1 = {
    Enabled = false,
    AttackPlayers = true,
    AttackMobs = true,
    MaxDistance = 500,
    BurstDelay = 0.08,
    Widget = nil,
    Thread = nil,
}

local function getEquippedFruit()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == "Blox Fruit" or tool:FindFirstChild("FruitM1") or tool:GetAttribute("Fruit") or string.find(string.lower(tool.Name), "fruit") or string.find(string.lower(tool.Name), "kitsune")) then
            return tool
        end
    end
    -- Fallback: any tool in character with a RemoteEvent
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChildOfClass("RemoteEvent") then
            return tool
        end
    end
    return nil
end

local function getClosestTarget()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closestDist = FruitsM1.MaxDistance
    local bestTarget = nil

    if FruitsM1.AttackPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local eHRP = p.Character:FindFirstChild("HumanoidRootPart")
                local eHum = p.Character:FindFirstChildOfClass("Humanoid")
                if eHRP and eHum and eHum.Health > 0 then
                    local dist = (hrp.Position - eHRP.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        bestTarget = eHRP
                    end
                end
            end
        end
    end

    if not bestTarget and FruitsM1.AttackMobs then
        local enemiesFolder = Workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, mob in ipairs(enemiesFolder:GetChildren()) do
                local mHRP = mob:FindFirstChild("HumanoidRootPart")
                local mHum = mob:FindFirstChildOfClass("Humanoid")
                if mHRP and mHum and mHum.Health > 0 then
                    local dist = (hrp.Position - mHRP.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        bestTarget = mHRP
                    end
                end
            end
        end
    end

    return bestTarget
end

function FruitsM1.attackOnce()
    local tool = getEquippedFruit()
    if not tool then return end

    local targetHRP = getClosestTarget()
    local targetPos = targetHRP and targetHRP.Position or (Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position + Workspace.CurrentCamera.CFrame.LookVector * 100)
    if not targetPos then return end

    pcall(function()
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            -- Standard Blox Fruits Fruit M1 remote signature
            remote:FireServer("TAP", targetPos)
            remote:FireServer(Vector3.new(9e30, 9e30, 9e30), 5, false)
        end

        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
        if remotesFolder then
            local validator = remotesFolder:FindFirstChild("Validator2")
            if validator and validator:IsA("RemoteEvent") then
                validator:FireServer(15627583, 1)
            end
        end
    end)
end

function FruitsM1.enable()
    if FruitsM1.Enabled then return end
    FruitsM1.Enabled = true

    if not FruitsM1.Thread then
        FruitsM1.Thread = task.spawn(function()
            while FruitsM1.Enabled do
                FruitsM1.attackOnce()
                task.wait(FruitsM1.BurstDelay)
            end
            FruitsM1.Thread = nil
        end)
    end

    if not FruitsM1.Widget and FloatingWidget then
        FruitsM1.Widget = FloatingWidget.create({
            Id = "FruitsM1Widget",
            Label = "M1",
            Type = "Toggle",
            Default = true,
            Position = UDim2.new(0.35, 0, 0.40, 0),
            AccentColor = Color3.fromRGB(249, 115, 22),
            Callback = function(state)
                if state then
                    FruitsM1.enable()
                else
                    FruitsM1.disable()
                end
            end
        })
    elseif FruitsM1.Widget then
        FruitsM1.Widget:Set(true, true)
        FruitsM1.Widget:SetVisible(true)
    end
end

function FruitsM1.disable()
    FruitsM1.Enabled = false
    if FruitsM1.Widget then
        FruitsM1.Widget:Set(false, true)
        FruitsM1.Widget:SetVisible(false)
    end
end

function FruitsM1.toggle()
    if FruitsM1.Enabled then
        FruitsM1.disable()
    else
        FruitsM1.enable()
    end
    return FruitsM1.Enabled
end

function FruitsM1.setFloatingVisible(visible)
    if FruitsM1.Widget then
        FruitsM1.Widget:SetVisible(visible)
    end
end

return FruitsM1
