-- ship painter

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local ShipPainter = {
    CurrentShip = nil,
    IsRainbow = false,
    CurrentColor = Color3.fromRGB(255, 255, 255),
    HeartbeatConnection = nil,
}

function ShipPainter.findPlayerShip()
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
            ShipPainter.CurrentShip = model
            ShipPainter.saveOriginalColors(model)
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
            ShipPainter.CurrentShip = model
            ShipPainter.saveOriginalColors(model)
            return model
        end

        local topAncestor = closestSeat
        while topAncestor.Parent and topAncestor.Parent ~= Workspace do
            topAncestor = topAncestor.Parent
        end
        ShipPainter.CurrentShip = topAncestor
        ShipPainter.saveOriginalColors(topAncestor)
        return topAncestor
    end

    return nil
end

function ShipPainter.saveOriginalColors(ship)
    if not ship then return end
    ShipPainter.CachedParts = {
        BaseParts = {},
        Surfaces = {},
        Decals = {}
    }
    ShipPainter.CachedShip = ship
    for _, part in ipairs(ship:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(ShipPainter.CachedParts.BaseParts, part)
            if not part:GetAttribute("OrigColor") then
                part:SetAttribute("OrigColor", part.Color)
            end
            if not part:GetAttribute("OrigMaterial") then
                part:SetAttribute("OrigMaterial", part.Material.Name)
            end
        elseif part:IsA("Decal") or part:IsA("Texture") then
            table.insert(ShipPainter.CachedParts.Decals, part)
            if not part:GetAttribute("OrigTransparency") then
                part:SetAttribute("OrigTransparency", part.Transparency)
            end
        elseif part:IsA("SurfaceAppearance") then
            table.insert(ShipPainter.CachedParts.Surfaces, part)
        end
    end
end

function ShipPainter.paintShip(color)
    if not ShipPainter.CurrentShip then
        ShipPainter.findPlayerShip()
    end
    if not ShipPainter.CurrentShip then return false end
    ShipPainter.CurrentColor = color

    if not ShipPainter.CachedParts or ShipPainter.CachedShip ~= ShipPainter.CurrentShip then
        ShipPainter.saveOriginalColors(ShipPainter.CurrentShip)
    end

    local cached = ShipPainter.CachedParts
    if cached then
        for _, part in ipairs(cached.BaseParts) do
            pcall(function()
                part.Color = color
                part.Material = Enum.Material.Neon
            end)
        end
        for _, surf in ipairs(cached.Surfaces) do
            pcall(function() surf.Color = color end)
        end
        for _, dec in ipairs(cached.Decals) do
            pcall(function() dec.Transparency = 1 end)
        end
    end
    return true
end

function ShipPainter.resetShip()
    ShipPainter.setRainbow(false)
    if not ShipPainter.CurrentShip then
        ShipPainter.findPlayerShip()
    end
    if not ShipPainter.CurrentShip then return false end

    for _, part in ipairs(ShipPainter.CurrentShip:GetDescendants()) do
        if part:IsA("BasePart") then
            local oColor = part:GetAttribute("OrigColor")
            local oMat = part:GetAttribute("OrigMaterial")
            if oColor then part.Color = oColor end
            if oMat then pcall(function() part.Material = Enum.Material[oMat] end) end
        elseif part:IsA("SurfaceAppearance") then
            pcall(function() part.Color = Color3.fromRGB(255, 255, 255) end)
        elseif part:IsA("Decal") or part:IsA("Texture") then
            local oTrans = part:GetAttribute("OrigTransparency")
            if oTrans then part.Transparency = oTrans end
        end
    end
    ShipPainter.CachedParts = nil
    ShipPainter.CachedShip = nil
    return true
end

function ShipPainter.setRainbow(state)
    ShipPainter.IsRainbow = state
    if state and not ShipPainter.HeartbeatConnection then
        ShipPainter.HeartbeatConnection = RunService.Heartbeat:Connect(function()
            if ShipPainter.IsRainbow and ShipPainter.CurrentShip then
                local rc = Color3.fromHSV((os.clock() % 5) / 5, 1, 1)
                ShipPainter.paintShip(rc)
            end
        end)
    elseif not state and ShipPainter.HeartbeatConnection then
        pcall(function() ShipPainter.HeartbeatConnection:Disconnect() end)
        ShipPainter.HeartbeatConnection = nil
    end
end

function ShipPainter.destroy()
    ShipPainter.setRainbow(false)
    ShipPainter.resetShip()
    ShipPainter.CurrentShip = nil
    ShipPainter.CachedParts = nil
    ShipPainter.CachedShip = nil
end

function ShipPainter.getDiagnostics()
    return {
        Name = "ShipPainter",
        Active = ShipPainter.IsRainbow or (ShipPainter.CurrentShip ~= nil),
        Connections = ShipPainter.HeartbeatConnection and 1 or 0,
        Threads = 0,
    }
end

return ShipPainter
