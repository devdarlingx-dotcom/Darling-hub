--[[
    Darling Hub - King's Throne Module (Cosmic Sovereign Chariot)
    Solid geometric throne vehicle with authentic seating, 3D flight controls,
    sleek dark pill dismount HUD, ProximityPrompt, and Montagem Topaz audio.
]]--

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local KingsThrone = {
    ThroneModel = nil,
    Seat = nil,
    IsSeated = false,
    FlightConn = nil,
    DismountGui = nil,
    CurrentYaw = 0,
    CurrentVel = Vector3.new(0, 0, 0),
    FlightSpeed = 65.0,
    Familiars = {},
    CrownCirclet = nil,
    CrownDiamonds = {},
    HoverRings = {},
    HeartDiamondA = nil,
    HeartDiamondB = nil,
}

-- Asset Identifiers
local TEX_SPARK = "rbxassetid://2581273950"
local TEX_GLINT = "rbxassetid://94431438472232"
local MESH_DIAMOND = "rbxassetid://9756362"

local function voidColor(t, offset)
    local phase = ((t or 0) + (offset or 0)) % 1
    if phase < 0.25 then
        return Color3.fromRGB(160, 35, 255):Lerp(Color3.fromRGB(0, 240, 255), phase / 0.25)
    elseif phase < 0.50 then
        return Color3.fromRGB(0, 240, 255):Lerp(Color3.fromRGB(255, 30, 180), (phase - 0.25) / 0.25)
    elseif phase < 0.75 then
        return Color3.fromRGB(255, 30, 180):Lerp(Color3.fromRGB(75, 12, 150), (phase - 0.50) / 0.25)
    else
        return Color3.fromRGB(75, 12, 150):Lerp(Color3.fromRGB(160, 35, 255), (phase - 0.75) / 0.25)
    end
end

local function makePart(parent, size, cf, color, material, trans)
    local p = Instance.new("Part")
    p.Size = size or Vector3.new(1, 1, 1)
    p.CFrame = cf or CFrame.new()
    p.Color = color or Color3.fromRGB(255, 255, 255)
    p.Material = material or Enum.Material.SmoothPlastic
    p.Transparency = trans or 0
    p.Anchored = true
    p.CanCollide = false
    p.Parent = parent
    return p
end

local function makeDiamond(parent, size, cf, color, material, trans)
    local p = makePart(parent, size, cf, color, material, trans)
    local m = Instance.new("SpecialMesh")
    m.MeshType = Enum.MeshType.FileMesh
    m.MeshId = MESH_DIAMOND
    m.Scale = size
    m.Parent = p
    return p
end

-- Music Controller: Plays Montagem Topaz (d_def47db76206)
local function playThroneMusic()
    pcall(function()
        local musicMod = (_G.DarlingHub and _G.DarlingHub:Require("modules/utility/music_engine.lua"))
        if musicMod and musicMod.playStream then
            musicMod.playStream("d_def47db76206", "Montagem Topaz")
        else
            -- Direct devmp3 fallback
            loadstring(game:HttpGet("https://darling-media-api.onrender.com/scripts/devmp3.lua?track=d_def47db76206"))()
        end
    end)
end

local function stopThroneMusic()
    pcall(function()
        local musicMod = (_G.DarlingHub and _G.DarlingHub:Require("modules/utility/music_engine.lua"))
        if musicMod and musicMod.stop then
            musicMod.stop()
        end
    end)
end

local function getLocalizedStrings()
    local lang = (getgenv and getgenv().DarlingLanguage) or (_G and _G.DarlingLanguage) or "English"
    if lang == "Español" then
        return {
            Dismount = "Bajarse del Trono",
            Action = "Volar Trono del Rey",
            Object = "Carruaje Cosmico"
        }
    elseif lang == "Français" then
        return {
            Dismount = "Descendre du Trone",
            Action = "Voler en Trone du Roi",
            Object = "Char Cosmique"
        }
    elseif lang == "Tiếng Việt" then
        return {
            Dismount = "Roi Khoi Ngoi Bau",
            Action = "Bay Cung Ngoi Bau",
            Object = "Co Xe Vu Tru"
        }
    elseif lang == "Português" then
        return {
            Dismount = "Descer do Trono",
            Action = "Voar no Trono do Rei",
            Object = "Carruagem Cosmica"
        }
    end
    return {
        Dismount = "Dismount Throne",
        Action = "Fly King's Throne",
        Object = "Cosmic Chariot"
    }
end

-- Sleek Dark Pill Dismount HUD (Matches Celestial Dragon Style)
local function showDismountGui()
    if KingsThrone.DismountGui and KingsThrone.DismountGui.Parent then return end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")

    local sg = Instance.new("ScreenGui")
    sg.Name = "DarlingThroneDismountGui"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 1000000
    sg.Parent = playerGui

    local container = Instance.new("Frame")
    container.Name = "DismountPill"
    container.Size = UDim2.new(0, 130, 0, 34)
    container.Position = UDim2.new(0.5, -65, 0.88, 0)
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    container.BackgroundTransparency = 0.2
    container.BorderSizePixel = 0
    container.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 55)
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    stroke.Parent = container

    local loc = getLocalizedStrings()
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = loc.Dismount
    title.TextColor3 = Color3.fromRGB(220, 220, 225)
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 11
    title.Parent = container

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = container

    clickBtn.MouseButton1Click:Connect(function()
        KingsThrone.dismount()
    end)

    KingsThrone.DismountGui = sg
end

local function hideDismountGui()
    if KingsThrone.DismountGui and KingsThrone.DismountGui.Parent then
        pcall(function() KingsThrone.DismountGui:Destroy() end)
    end
    KingsThrone.DismountGui = nil
end

-- Builds the complete solid geometric King's Throne model
function KingsThrone.buildThrone(centerPos, lookDir)
    KingsThrone.dismiss()

    local model = Instance.new("Model")
    model.Name = "Darling_KingsThrone"
    model.Parent = Workspace

    local throneCF = CFrame.lookAt(centerPos, centerPos + lookDir)

    -- 1. Stepped Dais Platform
    local dais1 = makePart(model, Vector3.new(14.0, 0.8, 14.0), throneCF * CFrame.new(0, 0.4, 0), Color3.fromRGB(30, 8, 45), Enum.Material.Foil, 0)
    local dais2 = makePart(model, Vector3.new(11.0, 0.8, 11.0), throneCF * CFrame.new(0, 1.2, 0), Color3.fromRGB(60, 12, 90), Enum.Material.SmoothPlastic, 0)
    local dais3 = makePart(model, Vector3.new(8.0, 0.8, 8.0), throneCF * CFrame.new(0, 2.0, 0), Color3.fromRGB(90, 18, 140), Enum.Material.Foil, 0)

    -- 4 Corner Obelisks with Neon Caps
    for _, theta in ipairs({ math.rad(45), math.rad(135), math.rad(225), math.rad(315) }) do
        local cornerCF = throneCF * CFrame.Angles(0, theta, 0) * CFrame.new(0, 1.2, -6.5)
        makeDiamond(model, Vector3.new(1.2, 3.8, 1.2), cornerCF, Color3.fromRGB(110, 20, 180), Enum.Material.Foil, 0)
        makeDiamond(model, Vector3.new(0.9, 1.8, 0.9), cornerCF * CFrame.new(0, 2.8, 0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)
    end

    -- 2. Royal Cushion
    makePart(model, Vector3.new(4.8, 0.6, 4.0), throneCF * CFrame.new(0, 2.7, 0.1), Color3.fromRGB(160, 20, 95), Enum.Material.SmoothPlastic, 0)

    -- 3. The Authentic Seat
    local seat = Instance.new("Seat")
    seat.Name = "KingSeat"
    seat.Size = Vector3.new(3.8, 0.6, 3.8)
    seat.CFrame = throneCF * CFrame.new(0, 2.7, 0.1)
    seat.Transparency = 1
    seat.CanCollide = true
    seat.Anchored = true
    seat.Parent = model

    -- 4. Carved Armrests with Cyan Orbs
    makePart(model, Vector3.new(0.8, 1.6, 4.4), throneCF * CFrame.new(-2.8, 3.2, 0.1), Color3.fromRGB(80, 15, 140), Enum.Material.Foil, 0)
    makePart(model, Vector3.new(0.8, 1.6, 4.4), throneCF * CFrame.new(2.8, 3.2, 0.1), Color3.fromRGB(80, 15, 140), Enum.Material.Foil, 0)
    makeDiamond(model, Vector3.new(1.4, 2.2, 1.4), throneCF * CFrame.new(-2.8, 4.3, -2.0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)
    makeDiamond(model, Vector3.new(1.4, 2.2, 1.4), throneCF * CFrame.new(2.8, 4.3, -2.0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)

    -- 5. Cathedral Backrest with Neon Arch & Spire Diamond
    makePart(model, Vector3.new(5.2, 16.0, 1.0), throneCF * CFrame.new(0, 10.5, 2.2), Color3.fromRGB(60, 10, 110), Enum.Material.Foil, 0)
    makePart(model, Vector3.new(6.4, 3.2, 1.2), throneCF * CFrame.new(0, 19.5, 2.2), Color3.fromRGB(150, 30, 255), Enum.Material.Neon, 0)
    makeDiamond(model, Vector3.new(3.5, 6.0, 3.5), throneCF * CFrame.new(0, 24.0, 2.2), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)

    -- 12 Cosmic Wing Blades
    for i = 1, 12 do
        local angle = math.rad(-85 + (i - 1) * (170 / 11))
        local rayLen = 6.5 + math.sin(i) * 2.5
        local rayCF = throneCF * CFrame.new(0, 15.0, 2.25) * CFrame.Angles(0, 0, angle) * CFrame.new(0, rayLen / 2, 0)
        makePart(model, Vector3.new(0.45, rayLen, 0.45), rayCF, voidColor(i / 12, 0.2), Enum.Material.Neon, 0)
    end

    -- 6. Nested Genesis Void Diamond Heart
    local heartPos = throneCF * CFrame.new(0, 13.0, 1.6)
    local heartA = makeDiamond(model, Vector3.new(3.0, 5.0, 3.0), heartPos, Color3.fromRGB(240, 220, 255), Enum.Material.Neon, 0)
    local heartB = makeDiamond(model, Vector3.new(2.0, 3.8, 2.0), heartPos, Color3.fromRGB(0, 240, 255), Enum.Material.Glass, 0)
    local heartLight = Instance.new("PointLight")
    heartLight.Color = Color3.fromRGB(180, 80, 255)
    heartLight.Range = 35
    heartLight.Brightness = 5.0
    heartLight.Parent = heartA

    KingsThrone.HeartDiamondA = heartA
    KingsThrone.HeartDiamondB = heartB

    -- 7. Dual Counter-Rotating 3D Starlight Halos Behind Backrest
    for idx, r in ipairs({ 7.5, 10.0 }) do
        for i = 1, 20 do
            local theta = (i - 0.5) * (math.pi * 2 / 20)
            local chordLen = 2 * r * math.sin(math.pi / 20) + 0.15
            local arcCF = throneCF * CFrame.new(0, 13.0, 2.7 + idx * 0.3) * CFrame.Angles(0, 0, theta) * CFrame.new(0, r, 0) * CFrame.Angles(0, 0, math.pi / 2)
            makePart(model, Vector3.new(0.3, 0.3, chordLen), arcCF, (idx == 1 and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(255, 30, 190)), Enum.Material.Neon, 0.15)
        end
    end

    -- 8. Solid Under-Seat Propulsion
    local hoverEmitter = makePart(model, Vector3.new(2, 0.4, 2), throneCF * CFrame.new(0, 0.2, 0), Color3.fromRGB(0, 230, 255), Enum.Material.Neon, 1)
    local spot = Instance.new("SpotLight")
    spot.Range = 30
    spot.Angle = 80
    spot.Brightness = 4.5
    spot.Color = Color3.fromRGB(0, 240, 255)
    spot.Face = Enum.NormalId.Bottom
    spot.Parent = hoverEmitter

    -- Dual Concentric Neon Hover Rings beneath base
    KingsThrone.HoverRings = {}
    for idx, r in ipairs({ 4.5, 7.5 }) do
        local arcs = {}
        for i = 1, 16 do
            local theta = (i - 0.5) * (math.pi * 2 / 16)
            local chordLen = 2 * r * math.sin(math.pi / 16) + 0.1
            local arcCF = throneCF * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -r)
            local arc = makePart(model, Vector3.new(0.3, 0.15, chordLen), arcCF, voidColor(idx / 2, 0), Enum.Material.Neon, 0.1)
            table.insert(arcs, { part = arc, baseTheta = theta, r = r })
        end
        table.insert(KingsThrone.HoverRings, { arcs = arcs, speed = (idx == 1 and 1.2 or -0.9), curRot = 0 })
    end

    -- 9. 8 Planetary Guardian Familiars
    KingsThrone.Familiars = {}
    for i = 1, 8 do
        local fPart = makeDiamond(model, Vector3.new(1.0, 1.8, 1.0), throneCF * CFrame.new(0, 5, 0), voidColor(i / 8, 0.1), Enum.Material.Neon, 0)
        table.insert(KingsThrone.Familiars, { part = fPart, index = i, orbitRadius = 14.0, baseSpeed = 0.8 + (i % 3) * 0.2 })
    end

    -- 10. Floating Sovereign Crown
    local crownCirclet = makePart(model, Vector3.new(2.4, 0.35, 2.4), throneCF * CFrame.new(0, 30, 0), Color3.fromRGB(150, 30, 255), Enum.Material.Neon, 1)
    local crownDiamonds = {}
    for i = 1, 6 do
        local cd = makeDiamond(model, Vector3.new(0.4, 0.9, 0.4), throneCF * CFrame.new(0, 30, 0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 1)
        table.insert(crownDiamonds, { part = cd, theta = (i - 1) * (math.pi * 2 / 6) })
    end
    KingsThrone.CrownCirclet = crownCirclet
    KingsThrone.CrownDiamonds = crownDiamonds

    -- 11. ProximityPrompt on Seat for Easy Re-mount
    local loc = getLocalizedStrings()
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = loc.Action
    prompt.ObjectText = loc.Object
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 18.0
    prompt.RequiresLineOfSight = false
    prompt.Parent = seat

    prompt.Triggered:Connect(function(player)
        if player == LocalPlayer then
            KingsThrone.mount()
        end
    end)

    KingsThrone.ThroneModel = model
    KingsThrone.Seat = seat
    KingsThrone.CurrentYaw = math.atan2(-lookDir.X, -lookDir.Z)
    return model
end

-- Safely sit the player on the throne
function KingsThrone.mount()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    -- Spawn throne in front of player if not already spawned
    if not KingsThrone.ThroneModel or not KingsThrone.ThroneModel.Parent or not KingsThrone.Seat then
        local look = hrp.CFrame.LookVector
        local spawnPos = hrp.Position + Vector3.new(look.X * 12.0, 0, look.Z * 12.0)
        KingsThrone.buildThrone(spawnPos, look)
    end

    local seat = KingsThrone.Seat
    if not seat or not seat.Parent then return false end

    KingsThrone.IsSeated = true

    -- Position and sit player smoothly without fling
    pcall(function()
        hrp.CFrame = seat.CFrame * CFrame.new(0, 0.8, 0)
        hum.PlatformStand = false
        hum.Sit = true
        seat:Sit(hum)

        -- Fallback weld ensuring 100% seating stability
        local oldWeld = seat:FindFirstChild("SeatWeldFallback")
        if oldWeld then oldWeld:Destroy() end

        local weld = Instance.new("WeldConstraint")
        weld.Name = "SeatWeldFallback"
        weld.Part0 = seat
        weld.Part1 = hrp
        weld.Parent = seat
    end)

    -- Play Montagem Topaz
    playThroneMusic()

    -- Show clean dismount pill
    showDismountGui()

    -- Start flight controller
    KingsThrone.startFlight()
    return true
end

-- Safely dismount and restore character state
function KingsThrone.dismount()
    KingsThrone.IsSeated = false

    if KingsThrone.FlightConn then
        pcall(function() KingsThrone.FlightConn:Disconnect() end)
        KingsThrone.FlightConn = nil
    end

    hideDismountGui()

    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = KingsThrone.Seat

    pcall(function()
        if seat then
            local weld = seat:FindFirstChild("SeatWeldFallback")
            if weld then weld:Destroy() end
        end
    end)

    if hum then
        pcall(function()
            hum.Sit = false
            hum.PlatformStand = false
            hum.AutoRotate = true
        end)
    end

    if hrp and seat then
        pcall(function()
            hrp.CFrame = seat.CFrame * CFrame.new(0, 1.5, -6.5)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end)
    end
end

-- Completely despawn the throne and stop music
function KingsThrone.dismiss()
    KingsThrone.dismount()
    stopThroneMusic()

    if KingsThrone.ThroneModel and KingsThrone.ThroneModel.Parent then
        pcall(function() KingsThrone.ThroneModel:Destroy() end)
    end
    KingsThrone.ThroneModel = nil
    KingsThrone.Seat = nil
    KingsThrone.Familiars = {}
    KingsThrone.HoverRings = {}
    KingsThrone.HeartDiamondA = nil
    KingsThrone.HeartDiamondB = nil
    KingsThrone.CrownCirclet = nil
    KingsThrone.CrownDiamonds = {}
end

-- 3D Flight & Hover Engine
function KingsThrone.startFlight()
    if KingsThrone.FlightConn then
        pcall(function() KingsThrone.FlightConn:Disconnect() end)
        KingsThrone.FlightConn = nil
    end

    local model = KingsThrone.ThroneModel
    local seat = KingsThrone.Seat
    if not model or not seat then return end

    local currentPos = seat.Position
    local char = LocalPlayer.Character
    local groundY = currentPos.Y - 2.8

    -- Keybind listener for [X] to dismount
    local xConn = nil
    xConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.X then
            if KingsThrone.IsSeated then
                KingsThrone.dismount()
                if xConn then xConn:Disconnect() end
            end
        end
    end)

    KingsThrone.FlightConn = RunService.RenderStepped:Connect(function(dt)
        if not KingsThrone.IsSeated or not model.Parent or not seat.Parent then
            KingsThrone.dismount()
            if xConn then xConn:Disconnect() end
            return
        end

        local cChar = LocalPlayer.Character
        local hum = cChar and cChar:FindFirstChildOfClass("Humanoid")
        local hrp = cChar and cChar:FindFirstChild("HumanoidRootPart")
        if not cChar or not hum or not hrp or hum.Health <= 0 then
            KingsThrone.dismount()
            if xConn then xConn:Disconnect() end
            return
        end

        local cam = Workspace.CurrentCamera
        local camCF = cam.CFrame

        -- Movement Inputs (WASD + Mobile Virtual Thumbstick)
        local fwd = 0
        local rgt = 0

        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then fwd = fwd + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then fwd = fwd - 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then rgt = rgt + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then rgt = rgt - 1 end

        if fwd == 0 and rgt == 0 then
            local okVec, v = pcall(function() return UserInputService:GetMoveVector() end)
            if okVec and typeof(v) == "Vector3" and v.Magnitude > 0.05 then
                fwd = -v.Z
                rgt = v.X
            end
        end

        fwd = math.clamp(fwd, -1, 1)
        rgt = math.clamp(rgt, -1, 1)

        local horizMove = Vector3.new(0, 0, 0)
        local camLookHoriz = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
        local camRightHoriz = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit

        if math.abs(fwd) > 0.05 or math.abs(rgt) > 0.05 then
            horizMove = (camLookHoriz * fwd + camRightHoriz * rgt).Unit
            KingsThrone.CurrentYaw = math.atan2(-horizMove.X, -horizMove.Z)
        end

        -- Vertical Ascent / Descent
        local vertMove = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vertMove = 1.0
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
            vertMove = -1.0
        end

        local targetVel = (horizMove + Vector3.new(0, vertMove, 0)) * KingsThrone.FlightSpeed
        KingsThrone.CurrentVel = KingsThrone.CurrentVel:Lerp(targetVel, math.clamp(dt * 7.0, 0, 1))

        currentPos = currentPos + KingsThrone.CurrentVel * dt

        -- Safe floor boundary clamp
        if currentPos.Y < groundY + 3.0 then
            currentPos = Vector3.new(currentPos.X, groundY + 3.0, currentPos.Z)
        end

        -- Aerodynamic banking tilt
        local bankAngle = -rgt * math.rad(9)
        local pitchAngle = fwd * math.rad(5)
        local rotCF = CFrame.Angles(0, KingsThrone.CurrentYaw, 0) * CFrame.Angles(pitchAngle, 0, bankAngle)
        local targetCF = CFrame.new(currentPos) * rotCF

        pcall(function()
            model:PivotTo(targetCF)
            seat.CFrame = targetCF * CFrame.new(0, 2.7, 0.1)
            hrp.CFrame = seat.CFrame * CFrame.new(0, 0.8, 0)
        end)

        local t = os.clock()

        -- Rotate under-seat hover rings
        for _, ring in ipairs(KingsThrone.HoverRings) do
            ring.curRot = ring.curRot + dt * ring.speed
            for _, arc in ipairs(ring.arcs) do
                local curAngle = arc.baseTheta + ring.curRot
                local arcCF = targetCF * CFrame.new(0, -2.0, 0) * CFrame.Angles(0, curAngle, 0) * CFrame.new(0, 0, -arc.r)
                arc.part.CFrame = arcCF
            end
        end

        -- Spin Genesis Void Diamond Core
        if KingsThrone.HeartDiamondA and KingsThrone.HeartDiamondA.Parent then
            KingsThrone.HeartDiamondA.CFrame = targetCF * CFrame.new(0, 13.0, 1.6) * CFrame.Angles(0, t * 2.8, math.sin(t * 1.6) * 0.12)
        end
        if KingsThrone.HeartDiamondB and KingsThrone.HeartDiamondB.Parent then
            KingsThrone.HeartDiamondB.CFrame = targetCF * CFrame.new(0, 13.0, 1.6) * CFrame.Angles(math.rad(45), -t * 3.2, math.cos(t * 1.6) * 0.12)
        end

        -- Orbit 8 Guardian Familiars
        for _, fam in ipairs(KingsThrone.Familiars) do
            if fam.part and fam.part.Parent then
                local fAngle = fam.index * (math.pi * 2 / 8) + t * fam.baseSpeed
                local bob = math.sin(t * 2.6 + fam.index) * 1.5
                local fPos = currentPos + Vector3.new(math.cos(fAngle) * fam.orbitRadius, 6.0 + bob, math.sin(fAngle) * fam.orbitRadius)
                fam.part.CFrame = CFrame.new(fPos, currentPos + Vector3.new(0, 6.0, 0)) * CFrame.Angles(t * 3.2, t * 2.5, 0)
            end
        end

        -- Floating Sovereign Crown
        local head = cChar:FindFirstChild("Head") or hrp
        if KingsThrone.CrownCirclet and KingsThrone.CrownCirclet.Parent then
            KingsThrone.CrownCirclet.Transparency = 0
            KingsThrone.CrownCirclet.CFrame = CFrame.new(head.Position.X, head.Position.Y + 1.2, head.Position.Z) * CFrame.Angles(0, t * 2.2, 0)
            for _, cd in ipairs(KingsThrone.CrownDiamonds) do
                if cd.part and cd.part.Parent then
                    cd.part.Transparency = 0
                    local dAngle = cd.theta + t * 2.2
                    local dPos = KingsThrone.CrownCirclet.Position + Vector3.new(math.cos(dAngle) * 1.2, 0.6, math.sin(dAngle) * 1.2)
                    cd.part.CFrame = CFrame.new(dPos) * CFrame.Angles(0, t * 3.0, 0)
                end
            end
        end
    end)
end

-- Play 40-second Cosmic Sovereign Cinematic (Heaven-Splitter Ray)
function KingsThrone.playCinematic()
    KingsThrone.dismiss()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    local originCF = hrp.CFrame
    local groundY = hrp.Position.Y - 2.8
    local lookVec = originCF.LookVector
    local throneCenterPos = originCF.Position + lookVec * 28.0 + Vector3.new(0, 0.4, 0)

    -- Build throne ahead
    KingsThrone.buildThrone(throneCenterPos, lookVec)

    -- Start Montagem Topaz
    playThroneMusic()

    -- Mount player after dramatic arrival
    task.delay(3.5, function()
        KingsThrone.mount()
    end)
end

return KingsThrone
