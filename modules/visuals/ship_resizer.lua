--[[
    Darling Hub - Sacred Ship Resizer Module
    Dynamically scales the player's ship between 1x and 20x using ScaleTo with anti-reversion loop.
]]--

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local ShipResizer = {
    CurrentShip = nil,
    CurrentScale = 1,
    HeartbeatConnection = nil,
}

function ShipResizer.findPlayerShip()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closestSeat = nil
    local minDist = math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
            local dist = (obj.Position - root.Position).Magnitude
            if dist < minDist and dist < 500 then
                minDist = dist
                closestSeat = obj
            end
        end
    end

    if closestSeat then
        local model = closestSeat
        while model.Parent and model.Parent ~= Workspace and not model:IsA("Model") do
            model = model.Parent
        end
        if model:IsA("Model") then
            ShipResizer.CurrentShip = model
            return model
        end

        local topAncestor = closestSeat
        while topAncestor.Parent and topAncestor.Parent ~= Workspace do
            topAncestor = topAncestor.Parent
        end
        ShipResizer.CurrentShip = topAncestor
        return topAncestor
    end

    return nil
end

function ShipResizer.setShipSize(multiplier)
    if not ShipResizer.CurrentShip then
        ShipResizer.findPlayerShip()
    end
    if not ShipResizer.CurrentShip then return false end
    ShipResizer.CurrentScale = math.clamp(multiplier, 0.5, 20)

    if ShipResizer.CurrentShip:IsA("Model") then
        if not ShipResizer.CurrentShip.PrimaryPart then
            local pp = ShipResizer.CurrentShip:FindFirstChildWhichIsA("BasePart")
            if pp then ShipResizer.CurrentShip.PrimaryPart = pp end
        end
        pcall(function()
            ShipResizer.CurrentShip:ScaleTo(ShipResizer.CurrentScale)
        end)
    else
        for _, part in ipairs(ShipResizer.CurrentShip:GetDescendants()) do
            if part:IsA("BasePart") then
                local oSize = part:GetAttribute("OriginalSize") or part.Size
                part:SetAttribute("OriginalSize", oSize)
                pcall(function()
                    part.Size = oSize * ShipResizer.CurrentScale
                end)
            end
        end
    end

    if not ShipResizer.HeartbeatConnection and ShipResizer.CurrentScale > 1 then
        ShipResizer.HeartbeatConnection = RunService.Heartbeat:Connect(function()
            if ShipResizer.CurrentShip and ShipResizer.CurrentShip.Parent then
                if ShipResizer.CurrentScale > 1 and ShipResizer.CurrentShip:IsA("Model") then
                    pcall(function()
                        if not ShipResizer.CurrentShip:GetScale() or ShipResizer.CurrentShip:GetScale() ~= ShipResizer.CurrentScale then
                            ShipResizer.CurrentShip:ScaleTo(ShipResizer.CurrentScale)
                        end
                    end)
                end
            else
                ShipResizer.CurrentShip = nil
            end
        end)
    end
    return true
end

function ShipResizer.resetShipSize()
    ShipResizer.CurrentScale = 1
    if not ShipResizer.CurrentShip then
        ShipResizer.findPlayerShip()
    end
    if not ShipResizer.CurrentShip then return false end

    if ShipResizer.HeartbeatConnection then
        pcall(function() ShipResizer.HeartbeatConnection:Disconnect() end)
        ShipResizer.HeartbeatConnection = nil
    end

    if ShipResizer.CurrentShip:IsA("Model") then
        pcall(function()
            ShipResizer.CurrentShip:ScaleTo(1)
        end)
    else
        for _, part in ipairs(ShipResizer.CurrentShip:GetDescendants()) do
            if part:IsA("BasePart") then
                local oSize = part:GetAttribute("OriginalSize")
                if oSize then
                    pcall(function()
                        part.Size = oSize
                    end)
                end
            end
        end
    end
    return true
end

return ShipResizer
