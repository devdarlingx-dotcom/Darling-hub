--[[
    Masterclass v6: SOLID REWORK // TRANSCENDENT VOID SOVEREIGN CHARIOT & HEAVEN-SPLITTER RAY
    Darling Hub - King's Throne Module (Cosmic Sovereign Chariot)

    Features:
    1. ZERO PUFFY MINECRAFT TNT SMOKE BALLS: 100% SOLID geometric visual effects.
    2. THE SUPER EPIC HEAVEN-SPLITTER SKY RAY: 2000 studs tall striking from cosmos with
       inner white-hot laser core, outer neon plasma aura, animated plasma beam, climbing
       rings, and 4 fractal branching lightning thunderbolts.
    3. SOLID UNDER-SEAT PROPULSION: Dual concentric neon hover rings in contrarotation,
       downward SpotLight, vertical starlight spark jets (TEX_SPARK), and glints.
    4. 32-STUD CATHEDRAL THRONE: 3-tiered crystalline dais, 8 corner obelisks, royal cushion,
       authentic Roblox seat, carved armrests, 12 cosmic wing blades (42 studs wingspan),
       nested Genesis Void Diamond core, dual 3D starlight halos, sovereign crown, and 8 familiars.
    5. SEATING & PROMPT FIX: ProximityPrompt is strictly DISABLED while seated so it never
       blocks the screen. Dismount safely restores avatar forward without character fling.
    6. SLEEK DISMOUNT HUD: Minimal dark pill button matching Celestial Dragon style.
    7. AUDIO: Montagem Topaz (d_def47db76206) background streaming.
    8. 0 Emojis, clean ASCII, localized across 5 languages.
]]--

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = nil
if LocalPlayer then
    PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
end

local camera = Workspace.CurrentCamera
while not camera do
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
    camera = Workspace.CurrentCamera
end

-- ============================================================================
-- GLOBAL ASSET IDENTIFIERS & TEXTURES
-- ============================================================================
local AUDIO_CINEMATIC = "rbxassetid://90089940136467"
local AUDIO_METEOR_BOOM = "rbxassetid://157878578"
local AUDIO_RUMBLE = "rbxassetid://9114223171"
local MONTAGEM_TOPAZ_ID = "d_def47db76206"

local TEX_SPARK = "rbxassetid://2581273950"
local TEX_GLINT = "rbxassetid://94431438472232"
local TEX_BEAM = "rbxassetid://6034176465"
local MESH_DIAMOND = "rbxassetid://9756362"

-- Color Helper for Cosmic Void Palette
local function voidPaletteColor(t, offset)
    local phase = ((t or 0) + (offset or 0)) % 1
    if phase < 0.25 then
        local p = phase / 0.25
        return Color3.fromRGB(160, 35, 255):Lerp(Color3.fromRGB(0, 240, 255), p)
    elseif phase < 0.50 then
        local p = (phase - 0.25) / 0.25
        return Color3.fromRGB(0, 240, 255):Lerp(Color3.fromRGB(255, 30, 180), p)
    elseif phase < 0.75 then
        local p = (phase - 0.50) / 0.25
        return Color3.fromRGB(255, 30, 180):Lerp(Color3.fromRGB(75, 12, 150), p)
    else
        local p = (phase - 0.75) / 0.25
        return Color3.fromRGB(75, 12, 150):Lerp(Color3.fromRGB(160, 35, 255), p)
    end
end

-- Keyframe Helpers
local function makeKeyframeNumberSeq(points)
    local keypoints = {}
    for _, pt in ipairs(points) do
        table.insert(keypoints, NumberSequenceKeypoint.new(pt[1], pt[2], pt[3] or 0))
    end
    return NumberSequence.new(keypoints)
end

local function makeColorSeq(color1, color2)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(0.5, color2 or color1),
        ColorSequenceKeypoint.new(1, color1)
    })
end

-- ============================================================================
-- LOCALIZATION (5 LANGUAGES)
-- ============================================================================
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

-- ============================================================================
-- MUSIC CONTROLLER (MONTAGEM TOPAZ)
-- ============================================================================
local function playThroneMusic()
    pcall(function()
        local dm = rawget(_G, "DarlingMusic")
        if dm and dm.playStream then
            dm.playStream(MONTAGEM_TOPAZ_ID, "Montagem Topaz")
            return
        end

        local snd = Workspace:FindFirstChild("DarlingThroneMusic")
        if not snd then
            snd = Instance.new("Sound")
            snd.Name = "DarlingThroneMusic"
            snd.Volume = 0.8
            snd.Looped = true
            snd.Parent = Workspace
        end
        local url = "https://darling-media-api.onrender.com/stream/" .. MONTAGEM_TOPAZ_ID .. "?k=darling_secret_key"
        snd.SoundId = url
        pcall(function() snd:Play() end)
    end)
end

local function stopThroneMusic()
    pcall(function()
        local snd = Workspace:FindFirstChild("DarlingThroneMusic")
        if snd then
            snd:Stop()
            snd:Destroy()
        end
        local dm = rawget(_G, "DarlingMusic")
        if dm and dm.stop then
            dm.stop()
        end
    end)
end

-- ============================================================================
-- LIGHTING ENVIRONMENT & SCREEN FLASH MANAGER
-- ============================================================================
local LightingManager = {}
LightingManager.__index = LightingManager

function LightingManager.new(screenGui)
    local self = setmetatable({}, LightingManager)
    self.orig = {
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Ambient = Lighting.Ambient,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        FogColor = Lighting.FogColor,
        ExposureCompensation = Lighting.ExposureCompensation
    }
    self.createdEffects = {}

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 2.0
    bloom.Size = 42
    bloom.Threshold = 0.45
    bloom.Parent = Lighting
    table.insert(self.createdEffects, bloom)
    self.bloom = bloom

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.06
    cc.Contrast = 0.32
    cc.Saturation = 0.50
    cc.TintColor = Color3.fromRGB(230, 205, 255)
    cc.Parent = Lighting
    table.insert(self.createdEffects, cc)
    self.cc = cc

    local atmo = Instance.new("Atmosphere")
    atmo.Density = 0.35
    atmo.Offset = 0.25
    atmo.Color = Color3.fromRGB(140, 75, 215)
    atmo.Decay = Color3.fromRGB(55, 12, 115)
    atmo.Glare = 0.4
    atmo.Haze = 0.7
    atmo.Parent = Lighting
    table.insert(self.createdEffects, atmo)
    self.atmo = atmo

    if screenGui then
        local flashFrame = Instance.new("Frame")
        flashFrame.Name = "FlashOverlay"
        flashFrame.Size = UDim2.new(1, 0, 1, 0)
        flashFrame.BackgroundColor3 = Color3.fromRGB(240, 220, 255)
        flashFrame.BackgroundTransparency = 1
        flashFrame.BorderSizePixel = 0
        flashFrame.Parent = screenGui
        self.flashFrame = flashFrame
    end

    return self
end

function LightingManager:SetCosmicMidnight()
    Lighting.ClockTime = 0.0
    Lighting.Brightness = 0.15
    Lighting.OutdoorAmbient = Color3.fromRGB(15, 6, 25)
    Lighting.Ambient = Color3.fromRGB(25, 10, 40)
    Lighting.FogEnd = 450
    Lighting.FogStart = 60
    Lighting.FogColor = Color3.fromRGB(35, 8, 55)
    Lighting.ExposureCompensation = 0.35
end

function LightingManager:TriggerMeganovaFlash()
    if not self.flashFrame then return end
    self.flashFrame.BackgroundTransparency = 0.0
    self.bloom.Intensity = 8.5
    self.cc.Brightness = 0.75

    local twInfo = TweenInfo.new(1.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(self.flashFrame, twInfo, {BackgroundTransparency = 1.0}):Play()
    TweenService:Create(self.bloom, twInfo, {Intensity = 2.2}):Play()
    TweenService:Create(self.cc, twInfo, {Brightness = 0.06}):Play()
end

function LightingManager:SmoothRestore(duration)
    duration = duration or 3.0
    local twInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(Lighting, twInfo, {
        ClockTime = self.orig.ClockTime,
        Brightness = self.orig.Brightness,
        OutdoorAmbient = self.orig.OutdoorAmbient,
        Ambient = self.orig.Ambient,
        FogEnd = self.orig.FogEnd,
        FogStart = self.orig.FogStart,
        FogColor = self.orig.FogColor,
        ExposureCompensation = self.orig.ExposureCompensation
    }):Play()

    task.delay(duration, function()
        for _, eff in ipairs(self.createdEffects) do
            pcall(function() eff:Destroy() end)
        end
        self.createdEffects = {}
    end)
end

function LightingManager:Restore()
    pcall(function()
        Lighting.ClockTime = self.orig.ClockTime
        Lighting.Brightness = self.orig.Brightness
        Lighting.OutdoorAmbient = self.orig.OutdoorAmbient
        Lighting.Ambient = self.orig.Ambient
        Lighting.FogEnd = self.orig.FogEnd
        Lighting.FogStart = self.orig.FogStart
        Lighting.FogColor = self.orig.FogColor
        Lighting.ExposureCompensation = self.orig.ExposureCompensation
    end)
    for _, eff in ipairs(self.createdEffects) do
        pcall(function() eff:Destroy() end)
    end
    self.createdEffects = {}
end

-- ============================================================================
-- HIGH-ALTITUDE PANORAMIC CINEMA CAMERA
-- ============================================================================
local CinemaCamera = {}
CinemaCamera.__index = CinemaCamera

function CinemaCamera.new(cameraInstance, originCFrame, groundY)
    local self = setmetatable({}, CinemaCamera)
    self.cam = cameraInstance
    self.origCFrame = cameraInstance.CFrame
    self.origType = cameraInstance.CameraType
    self.origFOV = cameraInstance.FieldOfView
    self.origin = originCFrame
    self.groundY = groundY
    self.shakeIntensity = 0
    self.noiseSeed = math.random() * 1000

    self.cam.CameraType = Enum.CameraType.Scriptable
    return self
end

function CinemaCamera:AddShake(amount)
    self.shakeIntensity = math.clamp(self.shakeIntensity + amount, 0, 10.0)
end

function CinemaCamera:Update(elapsed, dt, playerHrpPos, thronePos, skyRayPos)
    self.shakeIntensity = math.max(0, self.shakeIntensity - dt * 2.2)
    local shakeOffset = Vector3.new(0, 0, 0)
    if self.shakeIntensity > 0.01 then
        local t = elapsed * 32 + self.noiseSeed
        shakeOffset = Vector3.new(
            (math.noise(t, 0, 0) - 0.5) * self.shakeIntensity * 0.5,
            (math.noise(0, t, 0) - 0.5) * self.shakeIntensity * 0.5,
            (math.noise(0, 0, t) - 0.5) * self.shakeIntensity * 0.5
        )
    end

    local lookVec = self.origin.LookVector
    local rightVec = self.origin.RightVector
    local upVec = Vector3.new(0, 1, 0)

    local targetCF = self.cam.CFrame
    local targetFOV = 70
    local camPos = self.cam.CFrame.Position
    local lookAt = thronePos

    if elapsed < 8.0 then
        local p = elapsed / 8.0
        local angle = -0.3 + p * 1.4
        local camDist = 35.0 + p * 125.0
        local camHeight = 20.0 + p * 60.0
        local orbitOffset = (rightVec * math.cos(angle) - lookVec * math.sin(angle)) * camDist + upVec * camHeight
        camPos = playerHrpPos + orbitOffset
        lookAt = thronePos:Lerp(skyRayPos, p * 0.45)
        targetFOV = 72 + p * 14
    elseif elapsed < 16.0 then
        local p = (elapsed - 8.0) / 8.0
        local angle = 1.1 + p * 1.6
        local camDist = 160.0 + p * 80.0
        local camHeight = 80.0 + p * 20.0
        local orbitOffset = (rightVec * math.cos(angle) + lookVec * math.sin(angle)) * camDist + upVec * camHeight
        camPos = thronePos + orbitOffset
        lookAt = thronePos + upVec * (15.0 + p * 15.0)
        targetFOV = 86 + p * 4
    elseif elapsed < 25.0 then
        local p = (elapsed - 16.0) / 9.0
        local angle = 2.7 + p * 1.5
        local camDist = 240.0 * (1.0 - p * 0.72)
        local camHeight = 100.0 * (1.0 - p * 0.75) + 18.0
        local orbitOffset = (rightVec * math.cos(angle) + lookVec * math.sin(angle)) * camDist + upVec * camHeight
        camPos = thronePos + orbitOffset
        lookAt = thronePos + upVec * 12.0
        targetFOV = 88 - p * 12
    elseif elapsed < 33.0 then
        local p = (elapsed - 25.0) / 8.0
        local angle = 0.4 + p * 1.6
        local camDist = 65.0 + p * 285.0
        local camHeight = 25.0 + p * 95.0
        local orbitOffset = (rightVec * math.cos(angle) + lookVec * math.sin(angle)) * camDist + upVec * camHeight
        camPos = thronePos + orbitOffset
        lookAt = thronePos + upVec * 16.0
        targetFOV = 76 + p * 16
    else
        local p = (elapsed - 33.0) / 7.0
        local angle = 2.0 + p * (math.pi * 2.0)
        local camDist = 48.0 - p * 12.0
        local camHeight = 15.0 + math.sin(p * math.pi) * 3.0
        local orbitOffset = (rightVec * math.cos(angle) + lookVec * math.sin(angle)) * camDist + upVec * camHeight
        camPos = thronePos + orbitOffset
        lookAt = thronePos + upVec * 5.5
        targetFOV = 80 - p * 8
    end

    local minSafeY = self.groundY + 15.0
    if camPos.Y < minSafeY then
        camPos = Vector3.new(camPos.X, minSafeY, camPos.Z)
    end

    targetCF = CFrame.lookAt(camPos, lookAt)
    self.cam.CFrame = targetCF + shakeOffset
    self.cam.FieldOfView = targetFOV
end

function CinemaCamera:SmoothHandOff(playerHrpPos, duration)
    duration = duration or 2.5
    local startCF = self.cam.CFrame
    local startFOV = self.cam.FieldOfView
    local endLookAt = playerHrpPos + Vector3.new(0, 2.5, 0)
    local endPos = playerHrpPos + self.origin.LookVector * -16.0 + Vector3.new(0, 6.0, 0)
    local endCF = CFrame.lookAt(endPos, endLookAt)

    local handOffStart = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local t = math.clamp((os.clock() - handOffStart) / duration, 0, 1)
        local smoothT = TweenService:GetValue(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        self.cam.CFrame = startCF:Lerp(endCF, smoothT)
        self.cam.FieldOfView = startFOV + (70 - startFOV) * smoothT

        if t >= 1 then
            conn:Disconnect()
            self.cam.CameraType = Enum.CameraType.Custom
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    self.cam.CameraSubject = LocalPlayer.Character.Humanoid
                end
            end)
        end
    end)
end

function CinemaCamera:Restore()
    pcall(function()
        self.cam.CameraType = self.origType or Enum.CameraType.Custom
        self.cam.FieldOfView = self.origFOV or 70
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            self.cam.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end)
end

-- ============================================================================
-- PROCEDURAL 3D GEOMETRY BUILDER
-- ============================================================================
local GeoBuilder = {}

function GeoBuilder.createPart(parent, size, cframe, color, material, trans)
    local part = Instance.new("Part")
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Transparency = trans or 0
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function GeoBuilder.createDiamond(parent, size, cframe, color, material, trans)
    local part = GeoBuilder.createPart(parent, size, cframe, color, material or Enum.Material.Glass, trans or 0)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = MESH_DIAMOND
    mesh.Scale = size
    mesh.Parent = part
    return part, mesh
end

function GeoBuilder.createParticleEmitter(parent, texture, rate, speed, sizeSeq, colorSeq, transSeq, lifeSeq)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = texture
    emitter.Rate = rate
    emitter.Speed = speed
    emitter.Size = sizeSeq
    emitter.Color = colorSeq
    emitter.Transparency = transSeq
    emitter.Lifetime = lifeSeq
    emitter.LightEmission = 1
    emitter.LightInfluence = 0
    emitter.LockedToPart = false
    emitter.Parent = parent
    return emitter
end

function GeoBuilder.createLightningBolt(parent, numSegs, thickness, color)
    local parts = {}
    for i = 1, numSegs do
        local p = GeoBuilder.createPart(parent, Vector3.new(thickness, thickness, 1), CFrame.new(), color, Enum.Material.Neon, 0)
        table.insert(parts, p)
    end
    return {
        parts = parts,
        numSegs = numSegs,
        update = function(self, startPos, endPos, jitterAmount, seed)
            local delta = endPos - startPos
            local step = delta / self.numSegs
            local current = startPos
            local now = os.clock()

            for i = 1, self.numSegs do
                local nextTarget = startPos + step * i
                if i < self.numSegs then
                    local noiseX = (math.noise(i * 1.8, now * 28, seed) - 0.5) * jitterAmount
                    local noiseY = (math.noise(i * 1.8, now * 28 + 50, seed) - 0.5) * jitterAmount
                    local noiseZ = (math.noise(i * 1.8, now * 28 + 100, seed) - 0.5) * jitterAmount
                    nextTarget = nextTarget + Vector3.new(noiseX, noiseY, noiseZ)
                end

                local mid = (current + nextTarget) / 2
                local dist = (nextTarget - current).Magnitude
                local p = self.parts[i]
                p.Size = Vector3.new(p.Size.X, p.Size.Y, dist)
                p.CFrame = CFrame.lookAt(mid, nextTarget)
                current = nextTarget
            end
        end,
        setTransparency = function(self, trans)
            for _, p in ipairs(self.parts) do
                p.Transparency = trans
            end
        end
    }
end

-- ============================================================================
-- KINGS THRONE MODULE STATE
-- ============================================================================
local KingsThrone = {
    ThroneFolder = nil,
    ThroneRoot = nil,
    Seat = nil,
    SeatPrompt = nil,
    IsFlying = false,
    FlightConn = nil,
    CinematicConn = nil,
    DismountGui = nil,
    CrownCirclet = nil,
    CrownDiamonds = {},
    Familiars = {},
    HoverRings = {},
    HaloArcsA = {},
    HaloArcsB = {},
    SunburstRays = {},
    HeartDiamondA = nil,
    HeartDiamondB = nil,
}

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

-- ============================================================================
-- FORCE SIT PLAYER WITH ROBUST WELD FALLBACK & PROMPT HIDING
-- ============================================================================
local function forceSitPlayer(realSeat, seatPlayerCF, hrp, humanoid)
    if not humanoid or not hrp or not realSeat then return end

    -- STRICT FIX: Immediately hide ProximityPrompt so it never shows while sitting!
    if KingsThrone.SeatPrompt then
        KingsThrone.SeatPrompt.Enabled = false
    end

    pcall(function()
        hrp.Anchored = false
        hrp.CFrame = seatPlayerCF * CFrame.new(0, 1.2, 0)
        realSeat:Sit(humanoid)
    end)

    task.delay(0.15, function()
        if not humanoid.Sit and realSeat.Occupant ~= humanoid then
            humanoid.Sit = true
            local existingWeld = realSeat:FindFirstChild("SeatWeldFallback")
            if not existingWeld then
                local w = Instance.new("Weld")
                w.Name = "SeatWeldFallback"
                w.Part0 = realSeat
                w.Part1 = hrp
                w.C0 = CFrame.new(0, 1.8, 0)
                w.Parent = realSeat
            end
        end
        if KingsThrone.SeatPrompt then
            KingsThrone.SeatPrompt.Enabled = false
        end
    end)
end

-- ============================================================================
-- FULL MASTERCLASS V6 THRONE MODEL CONSTRUCTOR
-- ============================================================================
local function buildMasterclassThrone(throneCenterPos, lookVec, groundY)
    local throneCF = CFrame.lookAt(throneCenterPos, throneCenterPos + lookVec)

    local throneFolder = Instance.new("Model")
    throneFolder.Name = "Destiny_GoldenThrone"
    throneFolder.Parent = Workspace

    local throneParts = {}

    -- Primary Root Part for Unified Movement / Flight!
    local throneRoot = GeoBuilder.createPart(throneFolder, Vector3.new(6.0, 1.0, 5.0), CFrame.new(throneCenterPos.X, groundY + 2.5, throneCenterPos.Z), Color3.fromRGB(80, 15, 140), Enum.Material.Foil, 0)
    throneRoot.Name = "ThroneRoot"
    throneFolder.PrimaryPart = throneRoot
    table.insert(throneParts, throneRoot)

    -- 1. 3-Tiered Floating Crystalline Dais (22 studs wide)
    local daisRadii = {12.0, 17.0, 22.0}
    for idx, r in ipairs(daisRadii) do
        local slabY = groundY + (3 - idx) * 0.7 + 0.35
        local slab = GeoBuilder.createPart(throneFolder, Vector3.new(r, 0.7, r), CFrame.new(throneCenterPos.X, slabY, throneCenterPos.Z), Color3.fromRGB(35, 10, 50), Enum.Material.Foil, 0)
        local trim = GeoBuilder.createPart(throneFolder, Vector3.new(r + 0.5, 0.2, r + 0.5), CFrame.new(throneCenterPos.X, slabY + 0.35, throneCenterPos.Z), voidPaletteColor(idx / 3, 0), Enum.Material.Neon, 0)
        table.insert(throneParts, slab)
        table.insert(throneParts, trim)
    end

    -- 8 Corner Obelisks with spinning diamond capstones on dais
    for i = 1, 8 do
        local theta = (i - 1) * (math.pi * 2 / 8)
        local cornerCF = throneCF * CFrame.Angles(0, theta, 0) * CFrame.new(0, 1.2, -8.0)
        local obelisk, _ = GeoBuilder.createDiamond(throneFolder, Vector3.new(1.4, 4.5, 1.4), cornerCF, Color3.fromRGB(110, 20, 180), Enum.Material.Foil, 0)
        local cap, _ = GeoBuilder.createDiamond(throneFolder, Vector3.new(1.0, 2.0, 1.0), cornerCF * CFrame.new(0, 3.2, 0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)
        table.insert(throneParts, obelisk)
        table.insert(throneParts, cap)
    end

    -- 2. Royal Cushion
    local cushion = GeoBuilder.createPart(throneFolder, Vector3.new(4.8, 0.6, 4.0), CFrame.new(throneCenterPos.X, groundY + 3.1, throneCenterPos.Z + 0.1), Color3.fromRGB(160, 20, 95), Enum.Material.SmoothPlastic, 0)
    table.insert(throneParts, cushion)

    -- EXACT SEAT CFRAME FOR ROBLOX SEAT
    local seatPlayerCF = throneCF * CFrame.new(0, 2.4, 0.1)

    -- AUTHENTIC ROBLOX SEAT
    local realSeat = Instance.new("Seat")
    realSeat.Name = "SovereignThroneSeat"
    realSeat.Size = Vector3.new(3.8, 0.6, 3.8)
    realSeat.CFrame = seatPlayerCF
    realSeat.Transparency = 1
    realSeat.CanCollide = true
    realSeat.Anchored = true
    realSeat.Parent = throneFolder

    -- ProximityPrompt on Seat to Re-mount Anytime
    local loc = getLocalizedStrings()
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = loc.Action
    prompt.ObjectText = loc.Object
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 18.0
    prompt.RequiresLineOfSight = false
    prompt.Parent = realSeat

    prompt.Triggered:Connect(function(player)
        if player == LocalPlayer and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                KingsThrone.IsFlying = true
                prompt.Enabled = false
                forceSitPlayer(realSeat, seatPlayerCF, hrp, hum)
                showDismountGui()
            end
        end
    end)

    -- Under-Seat Floor Propulsion Effects
    local hoverEmitterPart = GeoBuilder.createPart(throneFolder, Vector3.new(2, 0.4, 2), CFrame.new(throneCenterPos.X, groundY + 0.5, throneCenterPos.Z), Color3.fromRGB(0, 230, 255), Enum.Material.Neon, 1)
    table.insert(throneParts, hoverEmitterPart)

    local hoverLight = Instance.new("SpotLight")
    hoverLight.Range = 32
    hoverLight.Angle = 85
    hoverLight.Brightness = 5.0
    hoverLight.Color = Color3.fromRGB(0, 240, 255)
    hoverLight.Face = Enum.NormalId.Bottom
    hoverLight.Parent = hoverEmitterPart

    local hoverSparks = GeoBuilder.createParticleEmitter(hoverEmitterPart, TEX_SPARK, 70, NumberRange.new(20, 38),
        makeKeyframeNumberSeq({{0, 1.2}, {0.5, 2.5}, {1, 0}}),
        makeColorSeq(Color3.fromRGB(0, 240, 255), Color3.fromRGB(180, 40, 255)),
        makeKeyframeNumberSeq({{0, 0}, {0.8, 0.1}, {1, 1}}),
        NumberRange.new(0.5, 1.0)
    )
    hoverSparks.EmissionDirection = Enum.NormalId.Bottom
    hoverSparks.SpreadAngle = Vector2.new(25, 25)

    local hoverGlints = GeoBuilder.createParticleEmitter(hoverEmitterPart, TEX_GLINT, 40, NumberRange.new(12, 25),
        makeKeyframeNumberSeq({{0, 1.4}, {0.5, 3.5}, {1, 0}}),
        makeColorSeq(Color3.fromRGB(240, 220, 255), Color3.fromRGB(0, 240, 255)),
        makeKeyframeNumberSeq({{0, 0}, {0.8, 0.1}, {1, 1}}),
        NumberRange.new(0.6, 1.2)
    )
    hoverGlints.EmissionDirection = Enum.NormalId.Bottom
    hoverGlints.SpreadAngle = Vector2.new(35, 35)

    -- Dual Concentric Solid Neon Hover Rings beneath the dais base
    local hoverRings = {}
    for idx, r in ipairs({5.5, 9.5}) do
        local ringArcs = {}
        for i = 1, 16 do
            local theta = (i - 0.5) * (math.pi * 2 / 16)
            local chordLen = 2 * r * math.sin(math.pi / 16) + 0.1
            local arcCF = CFrame.new(throneCenterPos.X, groundY + 0.4, throneCenterPos.Z) * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -r)
            local arc = GeoBuilder.createPart(throneFolder, Vector3.new(0.35, 0.15, chordLen), arcCF, voidPaletteColor(idx / 2, 0), Enum.Material.Neon, 0.1)
            table.insert(ringArcs, {part = arc, baseTheta = theta, r = r})
            table.insert(throneParts, arc)
        end
        table.insert(hoverRings, {arcs = ringArcs, speed = (idx == 1 and 1.2 or -0.9), curRot = 0})
    end

    -- 3. Carved Armrests with Diamond Orbs
    local armL = GeoBuilder.createPart(throneFolder, Vector3.new(0.8, 1.6, 4.4), throneCF * CFrame.new(-2.8, 2.8, 0.1), Color3.fromRGB(80, 15, 140), Enum.Material.Foil, 0)
    local armR = GeoBuilder.createPart(throneFolder, Vector3.new(0.8, 1.6, 4.4), throneCF * CFrame.new(2.8, 2.8, 0.1), Color3.fromRGB(80, 15, 140), Enum.Material.Foil, 0)
    local orbL, _ = GeoBuilder.createDiamond(throneFolder, Vector3.new(1.6, 2.4, 1.6), throneCF * CFrame.new(-2.8, 4.0, -2.0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)
    local orbR, _ = GeoBuilder.createDiamond(throneFolder, Vector3.new(1.6, 2.4, 1.6), throneCF * CFrame.new(2.8, 4.0, -2.0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)
    table.insert(throneParts, armL)
    table.insert(throneParts, armR)
    table.insert(throneParts, orbL)
    table.insert(throneParts, orbR)

    -- 4. Monumental 32-Stud Cathedral Backrest
    local backSlab = GeoBuilder.createPart(throneFolder, Vector3.new(5.2, 18.0, 1.0), throneCF * CFrame.new(0, 11.5, 2.2), Color3.fromRGB(60, 10, 110), Enum.Material.Foil, 0)
    local backArch = GeoBuilder.createPart(throneFolder, Vector3.new(6.4, 3.5, 1.2), throneCF * CFrame.new(0, 21.5, 2.2), Color3.fromRGB(150, 30, 255), Enum.Material.Neon, 0)
    local spireDiamond, _ = GeoBuilder.createDiamond(throneFolder, Vector3.new(4.0, 7.0, 4.0), throneCF * CFrame.new(0, 26.0, 2.2), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)
    table.insert(throneParts, backSlab)
    table.insert(throneParts, backArch)
    table.insert(throneParts, spireDiamond)

    -- 12 Cosmic Wing Blades (42 studs wingspan!)
    local sunburstRays = {}
    for i = 1, 12 do
        local angle = math.rad(-85 + (i - 1) * (170 / 11))
        local rayLen = 7.5 + math.sin(i) * 3.0
        local rayCF = throneCF * CFrame.new(0, 16.5, 2.25) * CFrame.Angles(0, 0, angle) * CFrame.new(0, rayLen / 2, 0)
        local ray = GeoBuilder.createPart(throneFolder, Vector3.new(0.5, rayLen, 0.5), rayCF, voidPaletteColor(i / 12, 0.2), Enum.Material.Neon, 0)
        table.insert(sunburstRays, ray)
        table.insert(throneParts, ray)
    end

    -- 5. Nested Genesis Void Diamond Core
    local heartPos = throneCF * CFrame.new(0, 14.0, 1.6)
    local heartDiamondA, _ = GeoBuilder.createDiamond(throneFolder, Vector3.new(3.5, 6.0, 3.5), heartPos, Color3.fromRGB(240, 220, 255), Enum.Material.Neon, 0)
    local heartDiamondB, _ = GeoBuilder.createDiamond(throneFolder, Vector3.new(2.4, 4.5, 2.4), heartPos, Color3.fromRGB(0, 240, 255), Enum.Material.Glass, 0)
    local heartLight = Instance.new("PointLight")
    heartLight.Color = Color3.fromRGB(180, 80, 255)
    heartLight.Range = 45
    heartLight.Brightness = 6.0
    heartLight.Parent = heartDiamondA
    table.insert(throneParts, heartDiamondA)
    table.insert(throneParts, heartDiamondB)

    -- 6. Dual Counter-Rotating 3D Starlight Halos
    local haloArcsA = {}
    local haloArcsB = {}
    local haloRadA = 8.5
    local haloRadB = 11.0

    for i = 1, 24 do
        local theta = (i - 0.5) * (math.pi * 2 / 24)
        local chordLen = 2 * haloRadA * math.sin(math.pi / 24) + 0.15
        local arcCF = throneCF * CFrame.new(0, 14.0, 2.8) * CFrame.Angles(0, 0, theta) * CFrame.new(0, haloRadA, 0) * CFrame.Angles(0, 0, math.pi / 2)
        local arc = GeoBuilder.createPart(throneFolder, Vector3.new(0.35, 0.35, chordLen), arcCF, Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0.1)
        table.insert(haloArcsA, {part = arc, baseAngle = theta})
        table.insert(throneParts, arc)
    end

    for i = 1, 24 do
        local theta = (i - 0.5) * (math.pi * 2 / 24)
        local chordLen = 2 * haloRadB * math.sin(math.pi / 24) + 0.15
        local arcCF = throneCF * CFrame.new(0, 14.0, 3.1) * CFrame.Angles(0, 0, theta) * CFrame.new(0, haloRadB, 0) * CFrame.Angles(0, 0, math.pi / 2)
        local arc = GeoBuilder.createPart(throneFolder, Vector3.new(0.30, 0.30, chordLen), arcCF, Color3.fromRGB(255, 30, 190), Enum.Material.Neon, 0.2)
        table.insert(haloArcsB, {part = arc, baseAngle = theta})
        table.insert(throneParts, arc)
    end

    -- 7. Sovereign Crown
    local crownFolder = Instance.new("Folder")
    crownFolder.Name = "SovereignCrown"
    crownFolder.Parent = throneFolder

    local crownCirclet = GeoBuilder.createPart(crownFolder, Vector3.new(2.4, 0.35, 2.4), throneCF * CFrame.new(0, 35, 0), Color3.fromRGB(150, 30, 255), Enum.Material.Neon, 0)
    local crownDiamonds = {}
    for i = 1, 8 do
        local theta = (i - 1) * (math.pi * 2 / 8)
        local d, _ = GeoBuilder.createDiamond(crownFolder, Vector3.new(0.6, 1.3, 0.6), crownCirclet.CFrame, Color3.fromRGB(0, 240, 255), Enum.Material.Neon, 0)
        table.insert(crownDiamonds, {part = d, theta = theta})
    end

    -- 8. 8 Guardian Diamond Familiars (Permanent Orbit)
    local familiars = {}
    for i = 1, 8 do
        local fPart, _ = GeoBuilder.createDiamond(throneFolder, Vector3.new(1.6, 3.2, 1.6), throneCF, voidPaletteColor(i / 8, 0), Enum.Material.Neon, 0)
        local _ = GeoBuilder.createParticleEmitter(fPart, TEX_GLINT, 40, NumberRange.new(2.5, 6.0),
            makeKeyframeNumberSeq({{0, 1.2}, {0.5, 3.2}, {1, 0}}),
            makeColorSeq(Color3.fromRGB(0, 240, 255), Color3.fromRGB(255, 30, 200)),
            makeKeyframeNumberSeq({{0, 0}, {0.8, 0.1}, {1, 1}}),
            NumberRange.new(0.8, 1.4)
        )
        table.insert(familiars, {part = fPart, index = i, orbitRadius = 11.0, baseSpeed = 1.9})
    end

    -- Store handles
    KingsThrone.ThroneFolder = throneFolder
    KingsThrone.ThroneRoot = throneRoot
    KingsThrone.Seat = realSeat
    KingsThrone.SeatPrompt = prompt
    KingsThrone.CrownCirclet = crownCirclet
    KingsThrone.CrownDiamonds = crownDiamonds
    KingsThrone.Familiars = familiars
    KingsThrone.HoverRings = hoverRings
    KingsThrone.HaloArcsA = haloArcsA
    KingsThrone.HaloArcsB = haloArcsB
    KingsThrone.SunburstRays = sunburstRays
    KingsThrone.HeartDiamondA = heartDiamondA
    KingsThrone.HeartDiamondB = heartDiamondB

    return {
        throneFolder = throneFolder,
        throneRoot = throneRoot,
        realSeat = realSeat,
        seatPlayerCF = seatPlayerCF,
        throneParts = throneParts,
        prompt = prompt,
        hoverRings = hoverRings,
        haloArcsA = haloArcsA,
        haloArcsB = haloArcsB,
        sunburstRays = sunburstRays,
        heartDiamondA = heartDiamondA,
        heartDiamondB = heartDiamondB,
        crownCirclet = crownCirclet,
        crownDiamonds = crownDiamonds,
        familiars = familiars,
        heartPos = heartPos,
        haloRadA = haloRadA,
        haloRadB = haloRadB
    }
end

-- ============================================================================
-- TRANSCENDENT DYNAMIC FLIGHT CONTROLLER
-- ============================================================================
local function startFlightController(throneFolder, throneRoot, realSeat, prompt, hoverRings, heartDiamondA, heartDiamondB, crownCirclet, crownDiamonds, familiars, groundY, initialYaw, startPos)
    if KingsThrone.FlightConn then
        pcall(function() KingsThrone.FlightConn:Disconnect() end)
        KingsThrone.FlightConn = nil
    end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not hrp or not humanoid then return end

    KingsThrone.IsFlying = true
    showDismountGui()
    if prompt then prompt.Enabled = false end

    local currentFlightPos = startPos or (throneRoot.Position + Vector3.new(0, 2.5, 0))
    local currentFlightYaw = initialYaw or 0
    local currentFlightVel = Vector3.new(0, 0, 0)
    local flightSpeed = 65.0

    -- X Keybind Listener for dismount
    if KingsThrone.XConn then
        pcall(function() KingsThrone.XConn:Disconnect() end)
        KingsThrone.XConn = nil
    end
    local xConn
    xConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.X then
            if realSeat.Occupant == humanoid or humanoid.Sit then
                KingsThrone.dismount()
            end
        end
    end)
    KingsThrone.XConn = xConn

    KingsThrone.FlightConn = RunService.RenderStepped:Connect(function(dt)
        if not throneFolder or not throneFolder.Parent then
            if KingsThrone.FlightConn then
                KingsThrone.FlightConn:Disconnect()
                KingsThrone.FlightConn = nil
            end
            if KingsThrone.XConn then
                KingsThrone.XConn:Disconnect()
                KingsThrone.XConn = nil
            end
            hideDismountGui()
            return
        end

        local isSeated = (realSeat.Occupant == humanoid or humanoid.Sit)

        -- STRICT FIX: When seated, prompt is ALWAYS hidden!
        if prompt then
            prompt.Enabled = not isSeated
        end

        if not isSeated then
            hideDismountGui()
            return
        else
            showDismountGui()
        end

        -- Read WASD Direct Keyboard Polling (Works 100% even with humanoid.Sit = true!)
        local isW = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
        local isS = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)
        local isA = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
        local isD = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)

        local camCF = Workspace.CurrentCamera.CFrame
        local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
        local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit

        local horizMove = Vector3.new(0, 0, 0)
        if isW then horizMove = horizMove + forward end
        if isS then horizMove = horizMove - forward end
        if isA then horizMove = horizMove - right end
        if isD then horizMove = horizMove + right end

        -- Fallback to humanoid.MoveDirection for mobile thumbstick support
        if horizMove.Magnitude == 0 and humanoid.MoveDirection.Magnitude > 0.05 then
            local md = humanoid.MoveDirection
            horizMove = (forward * -md.Z + right * md.X)
        end

        if horizMove.Magnitude > 0.05 then
            horizMove = horizMove.Unit
            currentFlightYaw = math.atan2(-horizMove.X, -horizMove.Z)
        end

        -- Vertical Input (Space = Ascend, Shift/Q/Ctrl = Descend)
        local vertMove = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vertMove = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
            or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            vertMove = -1
        end

        local targetVel = (horizMove + Vector3.new(0, vertMove, 0)) * flightSpeed
        currentFlightVel = currentFlightVel:Lerp(targetVel, math.clamp(dt * 6.0, 0, 1))

        currentFlightPos = currentFlightPos + currentFlightVel * dt

        -- Ground Clamp
        if currentFlightPos.Y < groundY + 3.0 then
            currentFlightPos = Vector3.new(currentFlightPos.X, groundY + 3.0, currentFlightPos.Z)
        end

        -- Aerodynamic Banking Tilt
        local bankAngle = 0
        local pitchAngle = 0
        if isA then bankAngle = math.rad(8)
        elseif isD then bankAngle = -math.rad(8) end
        if isW then pitchAngle = -math.rad(5)
        elseif isS then pitchAngle = math.rad(5) end

        local flightRotCF = CFrame.Angles(0, currentFlightYaw, 0) * CFrame.Angles(pitchAngle, 0, bankAngle)
        local targetThroneCF = CFrame.new(currentFlightPos) * flightRotCF

        -- Move entire throne model and seat smoothly together
        pcall(function()
            throneFolder:PivotTo(targetThroneCF)
        end)

        -- Rotate under-seat propulsion rings
        local t = os.clock()
        for _, ring in ipairs(hoverRings) do
            ring.curRot = ring.curRot + dt * ring.speed
            for _, arc in ipairs(ring.arcs) do
                local curAngle = arc.baseTheta + ring.curRot
                local arcCF = targetThroneCF * CFrame.new(0, -2.0, 0) * CFrame.Angles(0, curAngle, 0) * CFrame.new(0, 0, -arc.r)
                arc.part.CFrame = arcCF
            end
        end

        -- Spin Genesis Diamond & Halos
        if heartDiamondA and heartDiamondA.Parent then
            heartDiamondA.CFrame = targetThroneCF * CFrame.new(0, 14.0, 1.6) * CFrame.Angles(0, t * 2.8, math.sin(t * 1.6) * 0.12)
        end
        if heartDiamondB and heartDiamondB.Parent then
            heartDiamondB.CFrame = targetThroneCF * CFrame.new(0, 14.0, 1.6) * CFrame.Angles(math.rad(45), -t * 3.2, math.cos(t * 1.6) * 0.12)
        end

        -- Update Sovereign Crown above head
        local headPart = character:FindFirstChild("Head") or hrp
        if crownCirclet and crownCirclet.Parent then
            crownCirclet.Transparency = 0
            crownCirclet.CFrame = CFrame.new(headPart.Position.X, headPart.Position.Y + 1.2, headPart.Position.Z) * CFrame.Angles(0, t * 2.2, 0)
            for _, cd in ipairs(crownDiamonds) do
                if cd.part and cd.part.Parent then
                    cd.part.Transparency = 0
                    local dAngle = cd.theta + t * 2.2
                    local dPos = crownCirclet.Position + Vector3.new(math.cos(dAngle) * 1.2, 0.6, math.sin(dAngle) * 1.2)
                    cd.part.CFrame = CFrame.new(dPos) * CFrame.Angles(0, t * 3.0, 0)
                end
            end
        end

        -- 8 Guardian Familiars continuous planetary orbit around throne
        for _, fam in ipairs(familiars) do
            if fam.part and fam.part.Parent then
                local fAngle = fam.index * (math.pi * 2 / 8) + t * fam.baseSpeed
                local bob = math.sin(t * 2.6 + fam.index) * 1.5
                local fPos = currentFlightPos + Vector3.new(math.cos(fAngle) * fam.orbitRadius, 6.0 + bob, math.sin(fAngle) * fam.orbitRadius)
                fam.part.CFrame = CFrame.new(fPos, currentFlightPos + Vector3.new(0, 6.0, 0)) * CFrame.Angles(t * 3.2, t * 2.5, 0)
            end
        end
    end)
end

-- ============================================================================
-- FULL 40-SECOND MASTERCLASS V6 CUTSCENE
-- ============================================================================
local function playSolidReworkFlyingThroneIntro(onComplete)
    local character = LocalPlayer.Character
    if not character then
        character = LocalPlayer.CharacterAdded:Wait()
    end
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not hrp or not humanoid then
        if onComplete then onComplete() end
        return
    end

    local originCF = hrp.CFrame
    local groundY = hrp.Position.Y - 2.8
    local lookVec = originCF.LookVector
    local rightVec = originCF.RightVector

    -- THE THRONE IS PLACED 28 STUDS DIRECTLY IN FRONT OF THE PLAYER ON THE FLOOR
    local throneCenterPos = originCF.Position + lookVec * 28.0 + Vector3.new(0, 0.4, 0)
    local throneCF = CFrame.lookAt(throneCenterPos, throneCenterPos + lookVec)
    local skyRayTopPos = throneCenterPos + Vector3.new(0, 2000.0, 0)

    -- Clean any existing previous throne
    KingsThrone.dismiss()

    KingsThrone.CinematicRunId = (KingsThrone.CinematicRunId or 0) + 1
    local myRunId = KingsThrone.CinematicRunId

    -- Build the throne
    local tData = buildMasterclassThrone(throneCenterPos, lookVec, groundY)
    local throneFolder = tData.throneFolder
    local throneRoot = tData.throneRoot
    local realSeat = tData.realSeat
    local seatPlayerCF = tData.seatPlayerCF
    local throneParts = tData.throneParts
    local prompt = tData.prompt
    local hoverRings = tData.hoverRings
    local haloArcsA = tData.haloArcsA
    local haloArcsB = tData.haloArcsB
    local sunburstRays = tData.sunburstRays
    local heartDiamondA = tData.heartDiamondA
    local heartDiamondB = tData.heartDiamondB
    local crownCirclet = tData.crownCirclet
    local crownDiamonds = tData.crownDiamonds
    local familiars = tData.familiars
    local heartPos = tData.heartPos
    local haloRadA = tData.haloRadA
    local haloRadB = tData.haloRadB

    local tempVfxFolder = Instance.new("Folder")
    tempVfxFolder.Name = "Destiny_ThroneTempVFX"
    tempVfxFolder.Parent = Workspace

    -- Screen GUI for Flash Overlay & Cinema
    local cinemaScreen = Instance.new("ScreenGui")
    cinemaScreen.Name = "CosmicVoidScreen"
    cinemaScreen.ResetOnSpawn = false
    cinemaScreen.IgnoreGuiInset = true
    cinemaScreen.DisplayOrder = 999999
    cinemaScreen.Parent = PlayerGui

    local lightingMgr = LightingManager.new(cinemaScreen)
    lightingMgr:SetCosmicMidnight()

    local cinemaCam = CinemaCamera.new(camera, originCF, groundY)

    KingsThrone.ActiveLightingMgr = lightingMgr
    KingsThrone.ActiveCinemaCam = cinemaCam
    KingsThrone.CinematicHrp = hrp
    KingsThrone.TempVfxFolder = tempVfxFolder
    KingsThrone.CinemaScreen = cinemaScreen

    -- Play Montagem Topaz Audio
    playThroneMusic()

    local boomSound = Instance.new("Sound")
    boomSound.SoundId = AUDIO_METEOR_BOOM
    boomSound.Volume = 2.4
    boomSound.Looped = false
    boomSound.Parent = tempVfxFolder

    local rumbleSound = Instance.new("Sound")
    rumbleSound.SoundId = AUDIO_RUMBLE
    rumbleSound.Volume = 1.6
    rumbleSound.Looped = true
    rumbleSound.Parent = tempVfxFolder
    rumbleSound:Play()

    -- ACT I: The Colossal Heaven-Splitter Ray & Fractal Thunderbolts
    local skyRayCore = Instance.new("Part")
    skyRayCore.Name = "HeavenSplitterCore"
    skyRayCore.Shape = Enum.PartType.Cylinder
    skyRayCore.Material = Enum.Material.Neon
    skyRayCore.Color = Color3.fromRGB(255, 255, 255)
    skyRayCore.Size = Vector3.new(2000.0, 10.0, 10.0)
    skyRayCore.CFrame = CFrame.new(throneCenterPos + Vector3.new(0, 1000.0, 0)) * CFrame.Angles(0, 0, math.rad(90))
    skyRayCore.Transparency = 0.1
    skyRayCore.Anchored = true
    skyRayCore.CanCollide = false
    skyRayCore.Parent = tempVfxFolder

    local skyRayAura = Instance.new("Part")
    skyRayAura.Name = "HeavenSplitterAura"
    skyRayAura.Shape = Enum.PartType.Cylinder
    skyRayAura.Material = Enum.Material.Neon
    skyRayAura.Color = Color3.fromRGB(0, 240, 255)
    skyRayAura.Size = Vector3.new(2000.0, 28.0, 28.0)
    skyRayAura.CFrame = skyRayCore.CFrame
    skyRayAura.Transparency = 0.55
    skyRayAura.Anchored = true
    skyRayAura.CanCollide = false
    skyRayAura.Parent = tempVfxFolder

    local bAtt0 = Instance.new("Attachment")
    bAtt0.Position = Vector3.new(0, 0, 0)
    bAtt0.Parent = skyRayCore

    local rayTopPart = Instance.new("Part")
    rayTopPart.Name = "HeavenSplitterTop"
    rayTopPart.Size = Vector3.new(1, 1, 1)
    rayTopPart.CFrame = CFrame.new(skyRayTopPos)
    rayTopPart.Transparency = 1
    rayTopPart.Anchored = true
    rayTopPart.CanCollide = false
    rayTopPart.Parent = tempVfxFolder

    local bAtt1 = Instance.new("Attachment")
    bAtt1.Position = Vector3.new(0, 0, 0)
    bAtt1.Parent = rayTopPart

    local heavenBeam = Instance.new("Beam")
    heavenBeam.Name = "HeavenSplitterPlasmaBeam"
    heavenBeam.Attachment0 = bAtt0
    heavenBeam.Attachment1 = bAtt1
    heavenBeam.Texture = TEX_BEAM
    heavenBeam.TextureSpeed = 5.5
    heavenBeam.TextureLength = 25.0
    heavenBeam.Color = makeColorSeq(Color3.fromRGB(0, 240, 255), Color3.fromRGB(180, 30, 255))
    heavenBeam.LightEmission = 1.0
    heavenBeam.Width0 = 22.0
    heavenBeam.Width1 = 22.0
    heavenBeam.Transparency = NumberSequence.new(0.15)
    heavenBeam.Parent = skyRayCore

    local climbingRings = {}
    for i = 1, 4 do
        local ring = Instance.new("Part")
        ring.Name = "ClimbingRing_" .. i
        ring.Shape = Enum.PartType.Cylinder
        ring.Material = Enum.Material.Neon
        ring.Color = voidPaletteColor(i / 4, 0.2)
        ring.Size = Vector3.new(3.5, 38.0, 38.0)
        ring.CFrame = CFrame.new(throneCenterPos) * CFrame.Angles(0, 0, math.rad(90))
        ring.Transparency = 0.25
        ring.Anchored = true
        ring.CanCollide = false
        ring.Parent = tempVfxFolder
        table.insert(climbingRings, {part = ring, offset = (i - 1) * 0.25})
    end

    local spiralLightning = {}
    for i = 1, 4 do
        local bolt = GeoBuilder.createLightningBolt(tempVfxFolder, 16, 0.85, Color3.fromRGB(0, 240, 255))
        table.insert(spiralLightning, {bolt = bolt, index = i, seed = i * 43.7})
    end

    local mandalaArcs = {}
    local groundRadii = {22.0, 42.0}
    for idx, r in ipairs(groundRadii) do
        local col = voidPaletteColor(idx / 2, 0)
        for i = 1, 24 do
            local theta = (i - 0.5) * (math.pi * 2 / 24)
            local chordLen = 2 * r * math.sin(math.pi / 24) + 0.15
            local arcCF = CFrame.new(throneCenterPos.X, groundY + 0.05, throneCenterPos.Z) * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -r)
            local p = GeoBuilder.createPart(tempVfxFolder, Vector3.new(0.45, 0.08, chordLen), arcCF, col, Enum.Material.Neon, 0.15)
            table.insert(mandalaArcs, {part = p, baseTheta = theta, r = r, speed = (idx == 1 and 0.55 or -0.45)})
        end
    end

    local leylines = {}
    for i = 1, 12 do
        local theta = (i - 1) * (math.pi * 2 / 12)
        local beamLen = 120.0
        local beamCF = CFrame.new(throneCenterPos.X, groundY + 0.06, throneCenterPos.Z) * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0, -beamLen / 2)
        local p = GeoBuilder.createPart(tempVfxFolder, Vector3.new(0.70, 0.08, beamLen), beamCF, voidPaletteColor(i / 12, 0.1), Enum.Material.Neon, 0.2)
        table.insert(leylines, {part = p, theta = theta})
    end

    -- ACT II & III: 16 Diamonds Cascading from Heavens
    local cascadingDiamonds = {}
    for i = 1, 16 do
        local dPart, dMesh = GeoBuilder.createDiamond(tempVfxFolder, Vector3.new(3.6, 7.2, 3.6), CFrame.new(skyRayTopPos), voidPaletteColor(i / 16, 0), Enum.Material.Glass, 0)
        local glintEmitter = GeoBuilder.createParticleEmitter(dPart, TEX_GLINT, 45, NumberRange.new(3, 8),
            makeKeyframeNumberSeq({{0, 1.5}, {0.5, 4.0}, {1, 0}}),
            makeColorSeq(Color3.fromRGB(0, 240, 255), Color3.fromRGB(255, 220, 255)),
            makeKeyframeNumberSeq({{0, 0}, {0.8, 0.1}, {1, 1}}),
            NumberRange.new(0.8, 1.4)
        )
        table.insert(cascadingDiamonds, {part = dPart, mesh = dMesh, emitter = glintEmitter, index = i})
    end

    -- Initially transparent for dramatic arrival assembly
    for _, part in ipairs(throneParts) do
        part.Transparency = 1
    end
    crownCirclet.Transparency = 1
    for _, cd in ipairs(crownDiamonds) do cd.part.Transparency = 1 end

    -- ACT IV: Tractor Beam, Crown & Supernova Shockwaves
    local tractorBeam = GeoBuilder.createPart(tempVfxFolder, Vector3.new(10.0, 320.0, 10.0), CFrame.new(originCF.Position.X, groundY + 160.0, originCF.Position.Z), Color3.fromRGB(0, 230, 255), Enum.Material.Neon, 1)

    local supernovaFolder = Instance.new("Folder")
    supernovaFolder.Name = "SupernovaVFX"
    supernovaFolder.Parent = tempVfxFolder

    local accretionArcs = {}
    local function makeAccretionRing(axisTilt, rotSpeed, color1)
        local ringArcs = {}
        for i = 1, 24 do
            local theta = (i - 0.5) * (math.pi * 2 / 24)
            local p = GeoBuilder.createPart(supernovaFolder, Vector3.new(2.2, 0.5, 6.5), throneCF, color1, Enum.Material.Neon, 1)
            table.insert(ringArcs, {part = p, theta = theta})
        end
        table.insert(accretionArcs, {arcs = ringArcs, axisTilt = axisTilt, rotSpeed = rotSpeed, curRot = 0})
    end
    makeAccretionRing(CFrame.Angles(0, 0, 0), 1.6, Color3.fromRGB(0, 240, 255))
    makeAccretionRing(CFrame.Angles(math.rad(40), 0, math.rad(18)), -1.9, Color3.fromRGB(180, 40, 255))
    makeAccretionRing(CFrame.Angles(math.rad(-40), 0, math.rad(-18)), 2.2, Color3.fromRGB(255, 30, 180))

    local radialNeedles = {}
    for i = 1, 120 do
        local theta = math.random() * math.pi * 2
        local phi = (math.random() - 0.5) * math.pi
        local dir = Vector3.new(math.cos(phi) * math.cos(theta), math.sin(phi), math.cos(phi) * math.sin(theta)).Unit
        local p = GeoBuilder.createPart(supernovaFolder, Vector3.new(1.0, 1.0, 24.0), throneCF, voidPaletteColor(i / 120, 0), Enum.Material.Neon, 1)
        table.insert(radialNeedles, {part = p, dir = dir, speed = 175 + math.random() * 125, dist = 0})
    end

    local diamondShards = {}
    for i = 1, 72 do
        local theta = math.random() * math.pi * 2
        local phi = math.random() * (math.pi * 0.48)
        local dir = Vector3.new(math.cos(phi) * math.cos(theta), math.sin(phi), math.cos(phi) * math.sin(theta)).Unit
        local p, _ = GeoBuilder.createDiamond(supernovaFolder, Vector3.new(2.4, 4.8, 2.4), throneCF, Color3.fromRGB(0, 240, 255), Enum.Material.Glass, 1)
        table.insert(diamondShards, {part = p, dir = dir, speed = 135 + math.random() * 110, dist = 0, rotVel = Vector3.new(math.random() * 12, math.random() * 12, math.random() * 12)})
    end

    local detonationPart = GeoBuilder.createPart(supernovaFolder, Vector3.new(1, 1, 1), CFrame.new(throneCenterPos.X, groundY + 0.2, throneCenterPos.Z), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, 1)
    local detonationSparks = GeoBuilder.createParticleEmitter(detonationPart, TEX_SPARK, 0, NumberRange.new(55, 125),
        makeKeyframeNumberSeq({{0, 2.0}, {0.6, 4.5}, {1, 0}}),
        makeColorSeq(Color3.fromRGB(0, 240, 255), Color3.fromRGB(255, 30, 190)),
        makeKeyframeNumberSeq({{0, 0}, {0.8, 0.1}, {1, 1}}),
        NumberRange.new(1.4, 2.5)
    )
    detonationSparks.SpreadAngle = Vector2.new(180, 45)

    local detonationGlints = GeoBuilder.createParticleEmitter(detonationPart, TEX_GLINT, 0, NumberRange.new(45, 105),
        makeKeyframeNumberSeq({{0, 2.8}, {0.5, 8.0}, {1, 0}}),
        makeColorSeq(Color3.fromRGB(255, 240, 255), Color3.fromRGB(0, 240, 255)),
        makeKeyframeNumberSeq({{0, 0}, {0.8, 0.1}, {1, 1}}),
        NumberRange.new(1.6, 2.8)
    )
    detonationGlints.SpreadAngle = Vector2.new(180, 65)

    -- Runtime loop
    local startTime = os.clock()
    local TOTAL_DURATION = 40.0
    local supernovaTriggered = false
    local didLightingRestore = false
    local playerSeated = false
    local initialPlayerPos = hrp.Position

    hrp.Anchored = true

    KingsThrone.CinematicConn = RunService.RenderStepped:Connect(function(dt)
        local elapsed = os.clock() - startTime

        if elapsed >= TOTAL_DURATION then
            if KingsThrone.CinematicConn then
                KingsThrone.CinematicConn:Disconnect()
                KingsThrone.CinematicConn = nil
            end
            return
        end

        cinemaCam:Update(elapsed, dt, hrp.Position, throneCenterPos, skyRayTopPos)

        -- Act I (0s - 14s): Heaven-Splitter Ray
        if elapsed < 14.0 then
            for _, cr in ipairs(climbingRings) do
                local prog = ((elapsed * 0.45 + cr.offset) % 1)
                local curY = groundY + prog * 1800.0
                cr.part.CFrame = CFrame.new(throneCenterPos.X, curY, throneCenterPos.Z) * CFrame.Angles(0, 0, math.rad(90))
                cr.part.Transparency = 0.2 + prog * 0.6
            end
            for _, bData in ipairs(spiralLightning) do
                local ang = bData.index * (math.pi / 2) + elapsed * 3.5
                local r = 18.0 + math.sin(elapsed * 4.0 + bData.index) * 6.0
                local pStart = skyRayTopPos + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
                local pEnd = throneCenterPos + Vector3.new(math.cos(ang + math.pi) * 8.0, 5.0, math.sin(ang + math.pi) * 8.0)
                bData.bolt:update(pStart, pEnd, 22.0, bData.seed)
            end
            for _, arc in ipairs(mandalaArcs) do
                local curAngle = arc.baseTheta + elapsed * arc.speed
                local arcCF = CFrame.new(throneCenterPos.X, groundY + 0.05, throneCenterPos.Z) * CFrame.Angles(0, curAngle, 0) * CFrame.new(0, 0, -arc.r)
                arc.part.CFrame = arcCF
            end
            for _, line in ipairs(leylines) do
                local pulse = math.sin(elapsed * 8.0 + line.theta * 3.0)
                line.part.Transparency = 0.15 + pulse * 0.12
            end
        else
            skyRayCore.Transparency = math.min(1, skyRayCore.Transparency + dt * 1.5)
            skyRayAura.Transparency = math.min(1, skyRayAura.Transparency + dt * 1.5)
            heavenBeam.Transparency = NumberSequence.new(math.min(1, skyRayCore.Transparency))
            for _, cr in ipairs(climbingRings) do cr.part.Transparency = 1 end
            for _, b in ipairs(spiralLightning) do b.bolt:setTransparency(1) end
            for _, arc in ipairs(mandalaArcs) do arc.part.Transparency = math.min(1, arc.part.Transparency + dt * 1.5) end
            for _, line in ipairs(leylines) do line.part.Transparency = math.min(1, line.part.Transparency + dt * 1.5) end
        end

        -- Rotate Under-Seat Hover Rings
        for _, ring in ipairs(hoverRings) do
            ring.curRot = ring.curRot + dt * ring.speed
            for _, arc in ipairs(ring.arcs) do
                local curAngle = arc.baseTheta + ring.curRot
                local arcCF = CFrame.new(throneCenterPos.X, groundY + 0.4, throneCenterPos.Z) * CFrame.Angles(0, curAngle, 0) * CFrame.new(0, 0, -arc.r)
                arc.part.CFrame = arcCF
            end
        end

        -- Act III: Materialization & Wing Blades
        if elapsed >= 16.0 and elapsed < 25.0 then
            local p = (elapsed - 16.0) / 9.0
            for _, d in ipairs(cascadingDiamonds) do
                local theta = d.index * (math.pi * 2 / 16) + elapsed * 3.5
                local radius = 60.0 * (1.0 - p) + 3.0
                local height = 320.0 * (1.0 - p) + 8.0
                local dPos = throneCenterPos + Vector3.new(math.cos(theta) * radius, height, math.sin(theta) * radius)
                d.part.CFrame = CFrame.new(dPos) * CFrame.Angles(elapsed * 4, elapsed * 3, 0)
            end
            local throneTrans = math.max(0, 1.0 - (elapsed - 17.5) / 4.0)
            for _, part in ipairs(throneParts) do
                part.Transparency = throneTrans
            end
            for i, ray in ipairs(sunburstRays) do
                local targetAngle = math.rad(-85 + (i - 1) * (170 / 11))
                local curAngle = targetAngle * math.clamp((elapsed - 18.0) / 4.5, 0, 1)
                local rayLen = 7.5 + math.sin(i) * 3.0
                ray.CFrame = throneCF * CFrame.new(0, 16.5, 2.25) * CFrame.Angles(0, 0, curAngle) * CFrame.new(0, rayLen / 2, 0)
            end
        elseif elapsed >= 25.0 then
            for _, d in ipairs(cascadingDiamonds) do
                d.part.Transparency = 1
                d.emitter.Enabled = false
            end
            for _, part in ipairs(throneParts) do
                part.Transparency = 0
            end
        end

        -- Continuous Spin for Genesis Diamonds & Halos
        if elapsed >= 18.0 then
            heartDiamondA.CFrame = heartPos * CFrame.Angles(0, elapsed * 3.5, math.sin(elapsed * 2.0) * 0.15)
            heartDiamondB.CFrame = heartPos * CFrame.Angles(math.rad(45), -elapsed * 4.0, math.cos(elapsed * 2.0) * 0.15)
            for _, h in ipairs(haloArcsA) do
                local curAngle = h.baseAngle - elapsed * 1.2
                h.part.CFrame = throneCF * CFrame.new(0, 14.0, 2.8) * CFrame.Angles(0, 0, curAngle) * CFrame.new(0, haloRadA, 0) * CFrame.Angles(0, 0, math.pi / 2)
            end
            for _, h in ipairs(haloArcsB) do
                local curAngle = h.baseAngle + elapsed * 1.0
                h.part.CFrame = throneCF * CFrame.new(0, 14.0, 3.1) * CFrame.Angles(0, 0, curAngle) * CFrame.new(0, haloRadB, 0) * CFrame.Angles(0, 0, math.pi / 2)
            end
        end

        -- Act IV: Tractor Beam, Crown & Meganova
        if elapsed >= 25.0 and elapsed < 33.0 then
            local p = (elapsed - 25.0) / 8.0
            local tractorPos = initialPlayerPos:Lerp(seatPlayerCF.Position, math.clamp(p / 0.6, 0, 1))
            tractorBeam.CFrame = CFrame.new(tractorPos.X, groundY + 160.0, tractorPos.Z)
            tractorBeam.Transparency = math.clamp(1.0 - math.sin(p * math.pi) * 0.85, 0.15, 1)

            if p < 0.45 then
                local levP = p / 0.45
                local easeLev = TweenService:GetValue(levP, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                local curPos = initialPlayerPos + Vector3.new(0, easeLev * 8.0, 0)
                hrp.CFrame = CFrame.lookAt(curPos, curPos + lookVec)
            elseif p < 0.65 then
                local moveP = (p - 0.45) / 0.20
                local easeMove = TweenService:GetValue(moveP, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                local startAirPos = initialPlayerPos + Vector3.new(0, 8.0, 0)
                local targetAirPos = seatPlayerCF.Position + Vector3.new(0, 1.2, 0)
                local curPos = startAirPos:Lerp(targetAirPos, easeMove)
                hrp.CFrame = CFrame.lookAt(curPos, curPos + lookVec)

                if not playerSeated and moveP >= 0.75 then
                    playerSeated = true
                    forceSitPlayer(realSeat, seatPlayerCF, hrp, humanoid)
                end
            end

            -- Descend Crown
            local crownP = math.clamp((elapsed - 27.5) / 2.5, 0, 1)
            local easeCrown = TweenService:GetValue(crownP, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
            local headPart = character:FindFirstChild("Head") or hrp
            local targetCrownY = headPart.Position.Y + 1.2
            local curCrownY = targetCrownY + (1.0 - easeCrown) * 22.0

            crownCirclet.Transparency = math.max(0, 1.0 - crownP * 1.5)
            crownCirclet.CFrame = CFrame.new(headPart.Position.X, curCrownY, headPart.Position.Z) * CFrame.Angles(0, elapsed * 2.8, 0)

            for _, cd in ipairs(crownDiamonds) do
                cd.part.Transparency = crownCirclet.Transparency
                local dAngle = cd.theta + elapsed * 2.8
                local dPos = crownCirclet.Position + Vector3.new(math.cos(dAngle) * 1.2, 0.6, math.sin(dAngle) * 1.2)
                cd.part.CFrame = CFrame.new(dPos) * CFrame.Angles(0, elapsed * 3.5, 0)
            end

            -- Meganova Flash at 29.5s
            if not supernovaTriggered and elapsed >= 29.5 then
                supernovaTriggered = true
                lightingMgr:TriggerMeganovaFlash()
                cinemaCam:AddShake(7.5)
                boomSound:Play()
                detonationSparks:Emit(180)
                detonationGlints:Emit(110)
            end

            if supernovaTriggered then
                local snP = (elapsed - 29.5) / 3.5
                local easeR = TweenService:GetValue(snP, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                local currentAccretionRadius = 35.0 + easeR * 965.0

                for _, ring in ipairs(accretionArcs) do
                    ring.curRot = ring.curRot + dt * ring.rotSpeed
                    local planeCF = throneCF * ring.axisTilt * CFrame.Angles(0, ring.curRot, 0)
                    for _, arc in ipairs(ring.arcs) do
                        arc.part.Transparency = math.clamp(snP * 1.2, 0, 0.95)
                        local arcCF = planeCF * CFrame.Angles(0, arc.theta, 0) * CFrame.new(0, 0, -currentAccretionRadius)
                        local chordLen = 2 * currentAccretionRadius * math.sin(math.pi / 24) + 0.8
                        arc.part.Size = Vector3.new(2.8 + snP * 5.0, 0.6 + snP * 1.2, chordLen)
                        arc.part.CFrame = arcCF
                    end
                end

                for _, needle in ipairs(radialNeedles) do
                    needle.dist = needle.dist + needle.speed * dt
                    needle.part.Transparency = math.clamp(snP * 1.3, 0, 1)
                    needle.part.CFrame = CFrame.new(throneCenterPos + needle.dir * needle.dist, throneCenterPos + needle.dir * (needle.dist + 16.0))
                end

                for _, shard in ipairs(diamondShards) do
                    shard.dist = shard.dist + shard.speed * dt
                    shard.part.Transparency = math.clamp(snP * 1.2, 0, 1)
                    local rotCF = CFrame.Angles(elapsed * shard.rotVel.X, elapsed * shard.rotVel.Y, elapsed * shard.rotVel.Z)
                    shard.part.CFrame = CFrame.new(throneCenterPos + shard.dir * shard.dist) * rotCF
                end
            end
        elseif elapsed >= 33.0 then
            tractorBeam.Transparency = 1
            pcall(function() supernovaFolder:Destroy() end)

            local headPart = character:FindFirstChild("Head") or hrp
            crownCirclet.Transparency = 0
            crownCirclet.CFrame = CFrame.new(headPart.Position.X, headPart.Position.Y + 1.2, headPart.Position.Z) * CFrame.Angles(0, elapsed * 2.8, 0)
            for _, cd in ipairs(crownDiamonds) do
                cd.part.Transparency = 0
                local dAngle = cd.theta + elapsed * 2.8
                local dPos = crownCirclet.Position + Vector3.new(math.cos(dAngle) * 1.2, 0.6, math.sin(dAngle) * 1.2)
                cd.part.CFrame = CFrame.new(dPos) * CFrame.Angles(0, elapsed * 3.5, 0)
            end
        end

        -- Act V: 8 Familiars Orbit
        if elapsed >= 31.0 then
            for _, fam in ipairs(familiars) do
                local fAngle = fam.index * (math.pi * 2 / 8) + elapsed * fam.baseSpeed
                local bob = math.sin(elapsed * 3.0 + fam.index) * 1.8
                local fPos = throneCenterPos + Vector3.new(math.cos(fAngle) * fam.orbitRadius, 6.0 + bob, math.sin(fAngle) * fam.orbitRadius)
                fam.part.CFrame = CFrame.new(fPos, throneCenterPos + Vector3.new(0, 6.0, 0)) * CFrame.Angles(elapsed * 4.0, elapsed * 3.0, 0)
            end
        end

        if elapsed >= 37.0 and not didLightingRestore then
            didLightingRestore = true
            lightingMgr:SmoothRestore(3.0)
        end
    end)

    KingsThrone.CinematicThread = task.delay(TOTAL_DURATION, function()
        if KingsThrone.CinematicRunId ~= myRunId then return end
        KingsThrone.CinematicThread = nil
        KingsThrone.CinematicConn = nil
        KingsThrone.ActiveLightingMgr = nil
        KingsThrone.ActiveCinemaCam = nil
        KingsThrone.CinematicHrp = nil
        KingsThrone.TempVfxFolder = nil
        KingsThrone.CinemaScreen = nil

        pcall(function() tempVfxFolder:Destroy() end)
        pcall(function() cinemaScreen:Destroy() end)

        cinemaCam:SmoothHandOff(hrp.Position, 2.5)

        forceSitPlayer(realSeat, seatPlayerCF, hrp, humanoid)

        local initialYaw = math.atan2(-lookVec.X, -lookVec.Z)
        startFlightController(throneFolder, throneRoot, realSeat, prompt, hoverRings, heartDiamondA, heartDiamondB, crownCirclet, crownDiamonds, familiars, groundY, initialYaw, throneCenterPos + Vector3.new(0, 3.5, 0))

        if onComplete then onComplete() end
    end)
end

-- ============================================================================
-- EXPORTED PUBLIC API
-- ============================================================================

-- Instant Mount King's Throne (Cosmic Chariot)
function KingsThrone.mount()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return false end

    KingsThrone.dismiss()

    local originCF = hrp.CFrame
    local groundY = hrp.Position.Y - 2.8
    local lookVec = originCF.LookVector
    local spawnPos = originCF.Position + lookVec * 16.0 + Vector3.new(0, 0.4, 0)

    local tData = buildMasterclassThrone(spawnPos, lookVec, groundY)
    for _, part in ipairs(tData.throneParts) do
        part.Transparency = 0
    end
    tData.crownCirclet.Transparency = 0
    for _, cd in ipairs(tData.crownDiamonds) do
        cd.part.Transparency = 0
    end

    playThroneMusic()

    forceSitPlayer(tData.realSeat, tData.seatPlayerCF, hrp, humanoid)

    local initialYaw = math.atan2(-lookVec.X, -lookVec.Z)
    startFlightController(tData.throneFolder, tData.throneRoot, tData.realSeat, tData.prompt, tData.hoverRings, tData.heartDiamondA, tData.heartDiamondB, tData.crownCirclet, tData.crownDiamonds, tData.familiars, groundY, initialYaw, spawnPos + Vector3.new(0, 3.5, 0))

    return true
end

-- Full Masterclass v6 Cinematic Arrival
function KingsThrone.playCinematic()
    playSolidReworkFlyingThroneIntro(function()
        print("King's Throne cinematic arrival complete!")
    end)
    return true
end

-- Safely Dismount from King's Throne
function KingsThrone.dismount()
    KingsThrone.IsFlying = false
    hideDismountGui()

    if KingsThrone.XConn then
        pcall(function() KingsThrone.XConn:Disconnect() end)
        KingsThrone.XConn = nil
    end

    -- STRICT FIX: Re-enable prompt so user can walk up and re-mount
    if KingsThrone.SeatPrompt then
        KingsThrone.SeatPrompt.Enabled = true
    end

    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if KingsThrone.Seat then
        local fallback = KingsThrone.Seat:FindFirstChild("SeatWeldFallback")
        if fallback then
            pcall(function() fallback:Destroy() end)
        end
    end

    pcall(function()
        if hum then
            hum.Sit = false
        end
        if hrp and KingsThrone.ThroneRoot and KingsThrone.ThroneRoot.Parent then
            hrp.CFrame = KingsThrone.ThroneRoot.CFrame * CFrame.new(0, 1.5, -12.0)
        elseif hrp then
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 1.5, -8.0)
        end
    end)
end

-- Completely Dismiss and Despawn King's Throne
function KingsThrone.dismiss()
    KingsThrone.CinematicRunId = (KingsThrone.CinematicRunId or 0) + 1

    if KingsThrone.CinematicThread then
        pcall(function() task.cancel(KingsThrone.CinematicThread) end)
        KingsThrone.CinematicThread = nil
    end

    KingsThrone.dismount()

    if KingsThrone.FlightConn then
        pcall(function() KingsThrone.FlightConn:Disconnect() end)
        KingsThrone.FlightConn = nil
    end
    if KingsThrone.CinematicConn then
        pcall(function() KingsThrone.CinematicConn:Disconnect() end)
        KingsThrone.CinematicConn = nil
    end
    if KingsThrone.XConn then
        pcall(function() KingsThrone.XConn:Disconnect() end)
        KingsThrone.XConn = nil
    end

    if KingsThrone.ActiveCinemaCam then
        pcall(function() KingsThrone.ActiveCinemaCam:Restore() end)
        KingsThrone.ActiveCinemaCam = nil
    else
        pcall(function()
            if camera.CameraType == Enum.CameraType.Scriptable then
                camera.CameraType = Enum.CameraType.Custom
            end
        end)
    end

    if KingsThrone.ActiveLightingMgr then
        pcall(function() KingsThrone.ActiveLightingMgr:Restore() end)
        KingsThrone.ActiveLightingMgr = nil
    end

    if KingsThrone.CinematicHrp and KingsThrone.CinematicHrp.Parent then
        pcall(function() KingsThrone.CinematicHrp.Anchored = false end)
        KingsThrone.CinematicHrp = nil
    end

    pcall(function()
        if KingsThrone.CinemaScreen and KingsThrone.CinemaScreen.Parent then
            KingsThrone.CinemaScreen:Destroy()
        end
    end)
    KingsThrone.CinemaScreen = nil

    pcall(function()
        if KingsThrone.TempVfxFolder and KingsThrone.TempVfxFolder.Parent then
            KingsThrone.TempVfxFolder:Destroy()
        end
    end)
    KingsThrone.TempVfxFolder = nil

    pcall(function()
        if KingsThrone.ThroneFolder and KingsThrone.ThroneFolder.Parent then
            KingsThrone.ThroneFolder:Destroy()
        end
    end)
    pcall(function()
        local existing = Workspace:FindFirstChild("Destiny_GoldenThrone")
        if existing then existing:Destroy() end
    end)
    pcall(function()
        local existingVfx = Workspace:FindFirstChild("Destiny_ThroneTempVFX")
        if existingVfx then existingVfx:Destroy() end
    end)

    stopThroneMusic()
    hideDismountGui()

    KingsThrone.ThroneFolder = nil
    KingsThrone.ThroneRoot = nil
    KingsThrone.Seat = nil
    KingsThrone.SeatPrompt = nil
    KingsThrone.CrownCirclet = nil
    KingsThrone.CrownDiamonds = {}
    KingsThrone.Familiars = {}
    KingsThrone.HoverRings = {}
end

function KingsThrone.destroy()
    return KingsThrone.dismiss()
end

function KingsThrone.getDiagnostics()
    local connCount = 0
    if KingsThrone.FlightConn then connCount = connCount + 1 end
    if KingsThrone.CinematicConn then connCount = connCount + 1 end
    if KingsThrone.XConn then connCount = connCount + 1 end
    local threadCount = 0
    if KingsThrone.CinematicThread then threadCount = threadCount + 1 end
    return {
        Connections = connCount,
        Threads = threadCount,
        Active = (KingsThrone.ThroneFolder ~= nil) or KingsThrone.IsFlying or (KingsThrone.CinematicConn ~= nil) or (KingsThrone.CinematicThread ~= nil),
    }
end

return KingsThrone
