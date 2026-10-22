-- ship resizer

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

    -- Fast path: if player is sitting on the ship seat
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        local seat = hum.SeatPart
        local model = seat
        while model.Parent and model.Parent ~= Workspace and not model:IsA("Model") do
            model = model.Parent
        end
        if model:IsA("Model") then
            ShipResizer.CurrentShip = model
            return model
        end
    end

    local closestSeat = nil
    local minDist = math.huge

    -- Check Workspace.Boats or Workspace.Ships first before full scan
    local searchContainer = Workspace:FindFirstChild("Boats") or Workspace:FindFirstChild("Ships") or Workspace:FindFirstChild("Vehicles")
    local candidates = searchContainer and searchContainer:GetDescendants() or nil

    if candidates then
        for _, obj in ipairs(candidates) do
            if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                local dist = (obj.Position - root.Position).Magnitude
                if dist < minDist and dist < 500 then
                    minDist = dist
                    closestSeat = obj
                end
            end
        end
    end

    if not closestSeat then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                local dist = (obj.Position - root.Position).Magnitude
                if dist < minDist and dist < 500 then
                    minDist = dist
                    closestSeat = obj
                end
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

    if ShipResizer.CurrentScale > 1 then
        if not ShipResizer.HeartbeatConnection then
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
                    if ShipResizer.HeartbeatConnection then
                        pcall(function() ShipResizer.HeartbeatConnection:Disconnect() end)
                        ShipResizer.HeartbeatConnection = nil
                    end
                end
            end)
        end
    else
        if ShipResizer.HeartbeatConnection then
            pcall(function() ShipResizer.HeartbeatConnection:Disconnect() end)
            ShipResizer.HeartbeatConnection = nil
        end
    end
    return true
end

function ShipResizer.resetShipSize()
    ShipResizer.CurrentScale = 1
    if ShipResizer.HeartbeatConnection then
        pcall(function() ShipResizer.HeartbeatConnection:Disconnect() end)
        ShipResizer.HeartbeatConnection = nil
    end

    if not ShipResizer.CurrentShip then
        ShipResizer.findPlayerShip()
    end
    if not ShipResizer.CurrentShip then return false end

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

function ShipResizer.destroy()
    ShipResizer.resetShipSize()
    ShipResizer.CurrentShip = nil
end

function ShipResizer.getDiagnostics()
    return {
        Name = "ShipResizer",
        Active = (ShipResizer.CurrentScale ~= 1) or (ShipResizer.CurrentShip ~= nil),
        Connections = ShipResizer.HeartbeatConnection and 1 or 0,
        Threads = 0,
    }
end

return ShipResizer
