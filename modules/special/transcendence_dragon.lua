--[[
    Masterclass v31: TRANSCENDENCE 1000X // THE ULTIMATE CELESTIAL TITAN CINEMA
    Major Architectural Upgrades:
    1. Act I (0.0s - 6.0s) - Macro-to-Wide Astrolabe Awakening:
       - Initial macro close-up of Genesis Diamond prism facets whip-panning out to full 130-stud arena.
       - 6 Radiant Laser Leylines shooting from the central diamond into the ground mandala.
       - Dual gyroscopic counter-rotating starlight halos (+35 deg and -35 deg).
       - Soft rolling circular ground mist (TEX_MIST) and starlight sparks (TEX_SPARK).
    2. Act II (6.0s - 14.0s) - Colossal 130-Stud 5-Ray Celestial Star & Climbing Plasma Rings:
       - 65.0-stud radius (130-stud diameter) colossal pentagram star with reinforced laser chords.
       - Sequential energy pulse lighting up pentagram chords in star sequence (1->3->5->2->4->1).
       - 5 Towering 36-stud Crystal Monoliths (MeshId = 9756362) with spinning diamond capstones.
       - 5 Colossal Sky Rays (1600 studs tall) with climbing horizontal plasma rings racing to stratosphere.
       - Inter-monolith ground lightning arcs crackling between star points.
       - High-altitude aerial crane camera swooping to 130 studs height in 360-degree rotation.
    3. Act III (14.0s - 21.0s) - Relativistic Singularity & Triple-Accretion Supernova:
       - Inward relativistic singularity suction with desaturated chromatic tension drop.
       - ZERO diamond models in center.
       - TRIPLE 3D Gyroscopic Accretion Rings (72 Arc Segments across 3 tilted rotating axes: Horizontal, +38 deg, and -38 deg).
       - 64 Colossal Radial Laser Needles (increased from 48 to 64).
       - 48 Supersonic Flying 3D Diamond Shards tumbling into deep space.
       - 600+ Starlight Sparks and 4-Point Glints.
    4. Act IV (21.0s - 27.5s) - Dragon Hypersonic Re-Entry & Monumental Touchdown Flare:
       - Hypersonic stratospheric dive with dual wingtip atmospheric re-entry plasma trails.
       - 16 Diamond Star Escorts flying in aerodynamic delta formation.
       - Ground deceleration flare at Y + 38.0 studs above player feet.
       - Wing Downwash Ground Shockwave: Multi-layered mist shockwave (TEX_MIST), spark rings (TEX_SPARK), and diamond glints (TEX_GLINT) sweeping the ground beneath the dragon!
       - Celestial roar & soaring helical column of diamond fire breath.
       - Studio-grade head and chest illumination highlighting textured scales, claws, and wings.
       - 6 Dorsal Celestial Crystal Spines along dragon back.
    5. Act V (27.5s - 34.0s) - Double-Helix Guardian Ascension & Flawless Hand-Off:
       - 12 Escort crystals execute an elegant double-helix DNA spiral ascent into the stratosphere.
       - 4 Guardian crystals establish permanent orbital shield around the hovering titan.
       - 360-degree hero orbit camera circling player and dragon.
       - Natural lighting restoration and camera interpolation into player's third-person perspective over final 2.5s (0 abrupt cuts, 0 sudden pops!).
       - Permanent companion active in Workspace.Destiny_DragonCompanion at Y + 38.0 studs.
    6. Clean Standards: Zero branding text, zero letterbox bars, zero skip button, zero Destiny UI popup, clean ASCII, 0 emojis.
--]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

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
-- GLOBAL ASSET IDENTIFIERS & AUDIO IDS
-- ============================================================================
local AUDIO_CINEMATIC = "rbxassetid://90089940136467"
local AUDIO_METEOR_BOOM = "rbxassetid://157878578"
local AUDIO_CELESTIAL_ROAR = "rbxassetid://9069609200"
local AUDIO_RUMBLE = "rbxassetid://9114223171"

-- Verified High-Detail Textures
local TEX_SPARK = "rbxassetid://2581273950"          -- Starlight spark
local TEX_MIST = "rbxassetid://12865656309"          -- High-detail cinematic smoke mist
local TEX_GLINT = "rbxassetid://94431438472232"      -- Radiant 4-point starlight glint
local TEX_BEAM = "rbxassetid://6034176465"           -- Moving plasma energy beam texture

-- Authentic 3D Roblox SpecialMeshes
local MESH_DIAMOND = "rbxassetid://9756362"         -- Faceted Diamond Matrix
local MESH_DRAGON = "rbxassetid://94316226"         -- Ghost Titan Dragon
local TEX_DRAGON = "rbxassetid://94257533"          -- Dragon Texture

-- Helper for Keyframe Sequences
local function makeKeyframeNumberSeq(points)
    local keypoints = {}
    for _, pt in ipairs(points) do
        table.insert(keypoints, NumberSequenceKeypoint.new(pt[1], pt[2]))
    end
    return NumberSequence.new(keypoints)
end

-- Vibrant Prismatic Color Helper
local function rainbowColor(offset, speed, s, v)
    local t = tick() * (speed or 0.3) + (offset or 0)
    local h = t % 1
    return Color3.fromHSV(h, s or 0.95, v or 1.0)
end

local function rainbowSeq(offset, speed)
    local t = tick() * (speed or 0.3) + (offset or 0)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(t % 1, 0.95, 1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV((t + 0.33) % 1, 0.95, 1)),
        ColorSequenceKeypoint.new(0.66, Color3.fromHSV((t + 0.66) % 1, 0.95, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(t % 1, 0.95, 1))
    })
end

-- Safe UI Tweener
local function uiTween(instance, duration, properties, style, dir)
    if not instance then return end
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(instance, info, properties)
    tw:Play()
    return tw
end

-- Forward declaration of playCinematicIntro

local Transcendence = {
    IsPlaying = false,
    IsRiding = false,
    DragonBody = nil,
    DragonFolder = nil,
    DragonSpines = {},
    DragonEscorts = {},
    DragonSaddle = nil,
    FlightConn = nil,
}

local playCinematicIntro = nil

playCinematicIntro = function(onComplete)
    local char = LocalPlayer and LocalPlayer.Character
    if not char then
        char = LocalPlayer and LocalPlayer.CharacterAdded:Wait()
    end
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChildWhichIsA("BasePart"))
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp then
        if onComplete then onComplete() end
        return
    end

    local isDone = false
    local renderConn = nil

    -- Anchor character safely
    hrp.Anchored = true
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end

    -- Camera state backup
    local cam = Workspace.CurrentCamera
    local oldCameraType = cam.CameraType
    local oldCameraCF = cam.CFrame
    local oldCameraFOV = cam.FieldOfView
    cam.CameraType = Enum.CameraType.Scriptable

    -- Lighting state backup
    local oldClockTime = Lighting.ClockTime
    local oldBrightness = Lighting.Brightness
    local oldAmbient = Lighting.Ambient
    local oldOutdoorAmbient = Lighting.OutdoorAmbient
    local oldFogEnd = Lighting.FogEnd
    local oldFogColor = Lighting.FogColor
    local oldExposure = Lighting.ExposureCompensation

    -- Hide game UI
    local hiddenGuis = {}
    local function setGameGuisVisible(visible)
        if not PlayerGui then return end
        if not visible then
            for _, gui in ipairs(PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "SpookyCinematicScreen" and not gui.Name:find("Chat") then
                    table.insert(hiddenGuis, gui)
                    gui.Enabled = false
                end
            end
        else
            for _, gui in ipairs(hiddenGuis) do
                if gui and gui.Parent then
                    gui.Enabled = true
                end
            end
            hiddenGuis = {}
        end
    end
    setGameGuisVisible(false)

    -- Fullscreen ScreenGui (Zero Letterbox, Zero Branding Text)
    local cinemaScreen = Instance.new("ScreenGui")
    cinemaScreen.Name = "SpookyCinematicScreen"
    cinemaScreen.ResetOnSpawn = false
    cinemaScreen.IgnoreGuiInset = true
    cinemaScreen.DisplayOrder = 999999
    cinemaScreen.Parent = PlayerGui

    -- Flash Overlay (Clean White / Violet Pulses)
    local flashFrame = Instance.new("Frame")
    flashFrame.Name = "FlashOverlay"
    flashFrame.Size = UDim2.new(1, 0, 1, 0)
    flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flashFrame.BackgroundTransparency = 1
    flashFrame.BorderSizePixel = 0
    flashFrame.Parent = cinemaScreen

    -- Lighting Modifiers
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 1.3
    bloom.Size = 32
    bloom.Threshold = 0.55
    bloom.Parent = Lighting

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness = 0.05
    colorCorrection.Contrast = 0.18
    colorCorrection.Saturation = 0.35
    colorCorrection.Parent = Lighting

    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.25
    sunRays.Spread = 0.8
    sunRays.Parent = Lighting

    local atmo = Instance.new("Atmosphere")
    atmo.Density = 0.32
    atmo.Offset = 0.2
    atmo.Color = Color3.fromRGB(210, 200, 255)
    atmo.Decay = Color3.fromRGB(150, 110, 220)
    atmo.Glare = 0.25
    atmo.Haze = 0.6
    atmo.Parent = Lighting

    -- Audio Instances
    local cinematicSound = Instance.new("Sound")
    cinematicSound.Name = "CinematicSoundtrack"
    cinematicSound.SoundId = AUDIO_CINEMATIC
    cinematicSound.Volume = 0.95
    cinematicSound.Looped = false
    cinematicSound.Parent = cinemaScreen
    cinematicSound:Play()

    local boomSound = Instance.new("Sound")
    boomSound.Name = "MeteorBoom"
    boomSound.SoundId = AUDIO_METEOR_BOOM
    boomSound.Volume = 1.0
    boomSound.Parent = cinemaScreen

    local celestialRoarSound = Instance.new("Sound")
    celestialRoarSound.Name = "CelestialRoar"
    celestialRoarSound.SoundId = AUDIO_CELESTIAL_ROAR
    celestialRoarSound.Volume = 1.0
    celestialRoarSound.Parent = cinemaScreen

    local rumbleSound = Instance.new("Sound")
    rumbleSound.Name = "LowEndRumble"
    rumbleSound.SoundId = AUDIO_RUMBLE
    rumbleSound.Volume = 0.85
    rumbleSound.Looped = true
    rumbleSound.Parent = cinemaScreen

    -- VFX Folder (Temporary Cutscene VFX)
    local vfxFolder = Instance.new("Folder")
    vfxFolder.Name = "Spooky_TranscendenceVFX"
    vfxFolder.Parent = Workspace

    -- Permanent Companion Folder
    local companionFolder = Workspace:FindFirstChild("Destiny_DragonCompanion")
    if companionFolder then companionFolder:Destroy() end
    companionFolder = Instance.new("Folder")
    companionFolder.Name = "Destiny_DragonCompanion"
    companionFolder.Parent = Workspace

    -- Spatial Anchors
    local targetPos = hrp.Position
    local lookVec = hrp.CFrame.LookVector
    local rightVec = hrp.CFrame.RightVector
    local centerRitualPos = targetPos + lookVec * 20.0
    local skyDetonationPos = centerRitualPos + Vector3.new(0, 220.0, 0)

    -- ========================================================================
    -- 1. GROUND SACRED MANDALA & GENESIS CORE WITH DUAL HALOS (ACT I)
    -- ========================================================================
    local astrolabeRoot = Instance.new("Part")
    astrolabeRoot.Name = "AstrolabeRoot"
    astrolabeRoot.Size = Vector3.new(1, 1, 1)
    astrolabeRoot.CFrame = CFrame.new(centerRitualPos)
    astrolabeRoot.Transparency = 1
    astrolabeRoot.CanCollide = false
    astrolabeRoot.CanTouch = false
    astrolabeRoot.CanQuery = false
    astrolabeRoot.Anchored = true
    astrolabeRoot.Parent = vfxFolder

    -- Concentric Laser Circles
    local NUM_SEGS = 16
    local CIRCLE_RADIUS = 24.0
    local groundCircleSegments = {}
    for i = 1, NUM_SEGS do
        local ang0 = (i - 1) * (math.pi * 2 / NUM_SEGS)
        local ang1 = i * (math.pi * 2 / NUM_SEGS)
        local p0 = centerRitualPos + Vector3.new(math.cos(ang0) * CIRCLE_RADIUS, 0.05, math.sin(ang0) * CIRCLE_RADIUS)
        local p1 = centerRitualPos + Vector3.new(math.cos(ang1) * CIRCLE_RADIUS, 0.05, math.sin(ang1) * CIRCLE_RADIUS)

        local seg = Instance.new("Part")
        seg.Name = "GroundCircleSeg_" .. i
        seg.Material = Enum.Material.Neon
        seg.Color = rainbowColor(i / NUM_SEGS, 0.2)
        seg.Size = Vector3.new(0.18, 0.04, (p1 - p0).Magnitude)
        seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
        seg.Transparency = 0.2
        seg.CanCollide = false
        seg.CanTouch = false
        seg.CanQuery = false
        seg.Anchored = true
        seg.Parent = vfxFolder
        table.insert(groundCircleSegments, seg)
    end

    local INNER_RADIUS = 14.0
    local groundInnerCircle = {}
    for i = 1, NUM_SEGS do
        local ang0 = (i - 1) * (math.pi * 2 / NUM_SEGS)
        local ang1 = i * (math.pi * 2 / NUM_SEGS)
        local p0 = centerRitualPos + Vector3.new(math.cos(ang0) * INNER_RADIUS, 0.05, math.sin(ang0) * INNER_RADIUS)
        local p1 = centerRitualPos + Vector3.new(math.cos(ang1) * INNER_RADIUS, 0.05, math.sin(ang1) * INNER_RADIUS)

        local seg = Instance.new("Part")
        seg.Name = "GroundInnerSeg_" .. i
        seg.Material = Enum.Material.Neon
        seg.Color = rainbowColor(1 - i / NUM_SEGS, 0.2)
        seg.Size = Vector3.new(0.16, 0.04, (p1 - p0).Magnitude)
        seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
        seg.Transparency = 0.25
        seg.CanCollide = false
        seg.CanTouch = false
        seg.CanQuery = false
        seg.Anchored = true
        seg.Parent = vfxFolder
        table.insert(groundInnerCircle, seg)
    end

    -- 6 Radiant Laser Leylines shooting from Genesis Core to Ground Inner Circle
    local groundLeylines = {}
    for i = 1, 6 do
        local ang = (i - 1) * (math.pi / 3)
        local pOuter = centerRitualPos + Vector3.new(math.cos(ang) * INNER_RADIUS, 0.06, math.sin(ang) * INNER_RADIUS)
        local pInner = centerRitualPos + Vector3.new(0, 0.06, 0)
        local ley = Instance.new("Part")
        ley.Name = "GroundLeyline_" .. i
        ley.Material = Enum.Material.Neon
        ley.Color = rainbowColor(i / 6, 0.25)
        ley.Size = Vector3.new(0.20, 0.04, (pOuter - pInner).Magnitude)
        ley.CFrame = CFrame.lookAt((pInner + pOuter) / 2, pOuter)
        ley.Transparency = 0.3
        ley.CanCollide = false
        ley.CanTouch = false
        ley.CanQuery = false
        ley.Anchored = true
        ley.Parent = vfxFolder
        table.insert(groundLeylines, ley)
    end

    -- Genesis Diamond Core
    local genesisCore = Instance.new("Part")
    genesisCore.Name = "GenesisDiamondCore"
    genesisCore.Size = Vector3.new(1, 1, 1)
    genesisCore.CFrame = CFrame.new(centerRitualPos + Vector3.new(0, 3.5, 0))
    genesisCore.Material = Enum.Material.Neon
    genesisCore.Color = Color3.fromRGB(255, 255, 255)
    genesisCore.Transparency = 0
    genesisCore.CanCollide = false
    genesisCore.CanTouch = false
    genesisCore.CanQuery = false
    genesisCore.Anchored = true
    genesisCore.Parent = vfxFolder

    local genesisMesh = Instance.new("SpecialMesh")
    genesisMesh.MeshType = Enum.MeshType.FileMesh
    genesisMesh.MeshId = MESH_DIAMOND
    genesisMesh.Scale = Vector3.new(2.8, 4.2, 2.8)
    genesisMesh.Parent = genesisCore

    local coreLight = Instance.new("PointLight")
    coreLight.Color = Color3.fromRGB(220, 180, 255)
    coreLight.Range = 36
    coreLight.Brightness = 2.2
    coreLight.Parent = genesisCore

    -- Dual Counter-Rotating 3D Starlight Halos
    local HALO_SEGS = 12
    local HALO_RAD_A = 5.2
    local HALO_RAD_B = 6.4

    local haloSegsA = {}
    for h = 1, HALO_SEGS do
        local hSeg = Instance.new("Part")
        hSeg.Name = "GenesisHaloA_" .. h
        hSeg.Material = Enum.Material.Neon
        hSeg.Color = rainbowColor(h / HALO_SEGS, 0.25)
        hSeg.Size = Vector3.new(0.18, 0.18, 1)
        hSeg.Transparency = 0.35
        hSeg.CanCollide = false
        hSeg.CanTouch = false
        hSeg.CanQuery = false
        hSeg.Anchored = true
        hSeg.Parent = vfxFolder
        table.insert(haloSegsA, hSeg)
    end

    local haloSegsB = {}
    for h = 1, HALO_SEGS do
        local hSeg = Instance.new("Part")
        hSeg.Name = "GenesisHaloB_" .. h
        hSeg.Material = Enum.Material.Neon
        hSeg.Color = rainbowColor(1 - h / HALO_SEGS, 0.25)
        hSeg.Size = Vector3.new(0.16, 0.16, 1)
        hSeg.Transparency = 0.40
        hSeg.CanCollide = false
        hSeg.CanTouch = false
        hSeg.CanQuery = false
        hSeg.Anchored = true
        hSeg.Parent = vfxFolder
        table.insert(haloSegsB, hSeg)
    end

    -- High-Detail Ground Atmosphere
    local groundMistEmitter = Instance.new("ParticleEmitter")
    groundMistEmitter.Name = "GroundMist"
    groundMistEmitter.Texture = TEX_MIST
    groundMistEmitter.LightEmission = 0.55
    groundMistEmitter.Color = rainbowSeq(0.4, 0.1)
    groundMistEmitter.Size = makeKeyframeNumberSeq({{0, 4.0}, {0.5, 9.0}, {1, 15.0}})
    groundMistEmitter.Transparency = makeKeyframeNumberSeq({{0, 0.92}, {0.5, 0.86}, {1, 1}})
    groundMistEmitter.Lifetime = NumberRange.new(3.0, 5.0)
    groundMistEmitter.Rate = 18
    groundMistEmitter.Speed = NumberRange.new(1.0, 3.0)
    groundMistEmitter.SpreadAngle = Vector2.new(90, 90)
    groundMistEmitter.EmissionDirection = Enum.NormalId.Top
    groundMistEmitter.Parent = astrolabeRoot

    local groundEmberEmitter = Instance.new("ParticleEmitter")
    groundEmberEmitter.Name = "GroundEmbers"
    groundEmberEmitter.Texture = TEX_SPARK
    groundEmberEmitter.LightEmission = 1
    groundEmberEmitter.Color = rainbowSeq(0, 0.25)
    groundEmberEmitter.Size = makeKeyframeNumberSeq({{0, 0.6}, {0.5, 1.4}, {1, 0.1}})
    groundEmberEmitter.Transparency = makeKeyframeNumberSeq({{0, 0.1}, {0.7, 0.3}, {1, 1}})
    groundEmberEmitter.Lifetime = NumberRange.new(2.0, 3.8)
    groundEmberEmitter.Rate = 45
    groundEmberEmitter.Speed = NumberRange.new(3.0, 7.5)
    groundEmberEmitter.SpreadAngle = Vector2.new(35, 35)
    groundEmberEmitter.EmissionDirection = Enum.NormalId.Top
    groundEmberEmitter.Parent = astrolabeRoot

    -- ========================================================================
    -- 2. THE COLOSSAL 5-RAY CELESTIAL STAR FORMATION (ACT II)
    -- Monumental 65.0-stud Radius (130 studs diameter across the arena!)
    -- ========================================================================
    local STAR_RADIUS = 65.0
    local starPoints = {}
    for i = 1, 5 do
        local ang = (i - 1) * (2 * math.pi / 5) - math.pi / 2
        local p = centerRitualPos + Vector3.new(math.cos(ang) * STAR_RADIUS, 0, math.sin(ang) * STAR_RADIUS)
        table.insert(starPoints, { pos = p, angle = ang, index = i })
    end

    -- 5 Inscribed Pentagram Laser Chords (1->3->5->2->4->1)
    local pentagramChords = {}
    local pentagramPairs = {{1, 3}, {3, 5}, {5, 2}, {2, 4}, {4, 1}}
    for idx, pair in ipairs(pentagramPairs) do
        local pA = starPoints[pair[1]].pos
        local pB = starPoints[pair[2]].pos
        local chord = Instance.new("Part")
        chord.Name = "StarPentagramChord_" .. idx
        chord.Material = Enum.Material.Neon
        chord.Color = rainbowColor(idx / 5, 0.25)
        chord.Size = Vector3.new(0.38, 0.12, (pB - pA).Magnitude)
        chord.CFrame = CFrame.lookAt((pA + pB) / 2, pB)
        chord.Transparency = 1
        chord.CanCollide = false
        chord.CanTouch = false
        chord.CanQuery = false
        chord.Anchored = true
        chord.Parent = vfxFolder
        table.insert(pentagramChords, chord)
    end

    -- 5 Outer Pentagon Laser Chords (1->2->3->4->5->1)
    local pentagonChords = {}
    local pentagonPairs = {{1, 2}, {2, 3}, {3, 4}, {4, 5}, {5, 1}}
    for idx, pair in ipairs(pentagonPairs) do
        local pA = starPoints[pair[1]].pos
        local pB = starPoints[pair[2]].pos
        local chord = Instance.new("Part")
        chord.Name = "StarPentagonChord_" .. idx
        chord.Material = Enum.Material.Neon
        chord.Color = rainbowColor(idx / 5 + 0.5, 0.25)
        chord.Size = Vector3.new(0.32, 0.10, (pB - pA).Magnitude)
        chord.CFrame = CFrame.lookAt((pA + pB) / 2, pB)
        chord.Transparency = 1
        chord.CanCollide = false
        chord.CanTouch = false
        chord.CanQuery = false
        chord.Anchored = true
        chord.Parent = vfxFolder
        table.insert(pentagonChords, chord)
    end

    -- 5 Monumental Crystal Monoliths & 5 Colossal Sky Rays at the 5 Star Points
    local starMonoliths = {}
    local starRays = {}
    local starLightningBolts = {}
    local starClimbingRings = {}

    for i = 1, 5 do
        local pt = starPoints[i]

        -- Scaled up Monolith Obelisk (36 studs tall!)
        local monolith = Instance.new("Part")
        monolith.Name = "StarMonolith_" .. i
        monolith.Material = Enum.Material.Neon
        monolith.Color = rainbowColor(i / 5, 0.3)
        monolith.Size = Vector3.new(2.4, 34.0, 2.4)
        monolith.CFrame = CFrame.new(pt.pos.X, pt.pos.Y + 17.0, pt.pos.Z)
        monolith.Transparency = 1
        monolith.CanCollide = false
        monolith.CanTouch = false
        monolith.CanQuery = false
        monolith.Anchored = true
        monolith.Parent = vfxFolder

        local smMonolith = Instance.new("SpecialMesh")
        smMonolith.MeshType = Enum.MeshType.FileMesh
        smMonolith.MeshId = MESH_DIAMOND
        smMonolith.Scale = Vector3.new(3.0, 36.0, 3.0)
        smMonolith.Parent = monolith

        -- Scaled up Spinning Capstone
        local capstone = Instance.new("Part")
        capstone.Name = "StarCapstone_" .. i
        capstone.Material = Enum.Material.Neon
        capstone.Color = rainbowColor(i / 5 + 0.3, 0.35)
        capstone.Size = Vector3.new(1.8, 1.8, 1.8)
        capstone.CFrame = CFrame.new(pt.pos.X, pt.pos.Y + 39.0, pt.pos.Z)
        capstone.Transparency = 1
        capstone.CanCollide = false
        capstone.CanTouch = false
        capstone.CanQuery = false
        capstone.Anchored = true
        capstone.Parent = vfxFolder

        local smCap = Instance.new("SpecialMesh")
        smCap.MeshType = Enum.MeshType.FileMesh
        smCap.MeshId = MESH_DIAMOND
        smCap.Scale = Vector3.new(2.4, 4.2, 2.4)
        smCap.Parent = capstone

        local capGlintEmitter = Instance.new("ParticleEmitter")
        capGlintEmitter.Name = "StarGlints"
        capGlintEmitter.Texture = TEX_GLINT
        capGlintEmitter.LightEmission = 1
        capGlintEmitter.Color = rainbowSeq(i / 5, 0.3)
        capGlintEmitter.Size = makeKeyframeNumberSeq({{0, 1.2}, {0.5, 3.0}, {1, 0.3}})
        capGlintEmitter.Transparency = makeKeyframeNumberSeq({{0, 0.1}, {0.7, 0.35}, {1, 1}})
        capGlintEmitter.Lifetime = NumberRange.new(1.5, 3.2)
        capGlintEmitter.Rate = 25
        capGlintEmitter.Speed = NumberRange.new(5.0, 12.0)
        capGlintEmitter.SpreadAngle = Vector2.new(25, 25)
        capGlintEmitter.EmissionDirection = Enum.NormalId.Top
        capGlintEmitter.Parent = capstone

        table.insert(starMonoliths, {
            monolith = monolith,
            capstone = capstone,
            pos = pt.pos,
            index = i
        })

        -- Colossal Sky Ray for each Star Point (1600 studs tall!)
        local rayCore = Instance.new("Part")
        rayCore.Name = "StarSkyRayCore_" .. i
        rayCore.Shape = Enum.PartType.Cylinder
        rayCore.Material = Enum.Material.Neon
        rayCore.Color = Color3.fromRGB(255, 255, 255)
        rayCore.Size = Vector3.new(0.1, 0.1, 0.1)
        rayCore.CFrame = CFrame.new(pt.pos) * CFrame.Angles(0, 0, math.rad(90))
        rayCore.Transparency = 1
        rayCore.CanCollide = false
        rayCore.CanTouch = false
        rayCore.CanQuery = false
        rayCore.Anchored = true
        rayCore.Parent = vfxFolder

        local rayAura = Instance.new("Part")
        rayAura.Name = "StarSkyRayAura_" .. i
        rayAura.Shape = Enum.PartType.Cylinder
        rayAura.Material = Enum.Material.Neon
        rayAura.Color = rainbowColor(i / 5, 0.3)
        rayAura.Size = Vector3.new(0.1, 0.1, 0.1)
        rayAura.CFrame = rayCore.CFrame
        rayAura.Transparency = 1
        rayAura.CanCollide = false
        rayAura.CanTouch = false
        rayAura.CanQuery = false
        rayAura.Anchored = true
        rayAura.Parent = vfxFolder

        -- Animated Plasma Beam for this ray
        local bAtt0 = Instance.new("Attachment")
        bAtt0.Position = Vector3.new(0, 0, 0)
        bAtt0.Parent = capstone

        local rayTop = Instance.new("Part")
        rayTop.Name = "RayTop_" .. i
        rayTop.Size = Vector3.new(1, 1, 1)
        rayTop.CFrame = CFrame.new(pt.pos + Vector3.new(0, 1600, 0))
        rayTop.Transparency = 1
        rayTop.CanCollide = false
        rayTop.CanTouch = false
        rayTop.CanQuery = false
        rayTop.Anchored = true
        rayTop.Parent = vfxFolder

        local bAtt1 = Instance.new("Attachment")
        bAtt1.Position = Vector3.new(0, 0, 0)
        bAtt1.Parent = rayTop

        local pBeam = Instance.new("Beam")
        pBeam.Name = "PlasmaRay_" .. i
        pBeam.Attachment0 = bAtt0
        pBeam.Attachment1 = bAtt1
        pBeam.Texture = TEX_BEAM
        pBeam.TextureSpeed = 4.5
        pBeam.TextureLength = 22.0
        pBeam.Color = rainbowSeq(i / 5, 0.35)
        pBeam.LightEmission = 1.0
        pBeam.Width0 = 16.0
        pBeam.Width1 = 16.0
        pBeam.Transparency = NumberSequence.new(1)
        pBeam.Parent = capstone

        table.insert(starRays, {
            core = rayCore,
            aura = rayAura,
            beam = pBeam,
            pt = pt.pos,
            index = i
        })

        -- Climbing Horizontal Plasma Rings ascending the beam into the sky!
        local climbRing = Instance.new("Part")
        climbRing.Name = "StarClimbRing_" .. i
        climbRing.Shape = Enum.PartType.Cylinder
        climbRing.Material = Enum.Material.Neon
        climbRing.Color = rainbowColor(i / 5 + 0.4, 0.35)
        climbRing.Size = Vector3.new(2.5, 34, 34)
        climbRing.CFrame = CFrame.new(pt.pos) * CFrame.Angles(0, 0, math.rad(90))
        climbRing.Transparency = 1
        climbRing.CanCollide = false
        climbRing.CanTouch = false
        climbRing.CanQuery = false
        climbRing.Anchored = true
        climbRing.Parent = vfxFolder
        table.insert(starClimbingRings, climbRing)

        -- Branching lightning for this star ray
        local rayBolts = {}
        for b = 1, 3 do
            local segs = {}
            for s = 1, 8 do
                local lp = Instance.new("Part")
                lp.Name = "StarLightning_" .. i .. "_" .. b .. "_" .. s
                lp.Material = Enum.Material.Neon
                lp.Color = rainbowColor(i / 5 + s / 40, 0.35)
                lp.Size = Vector3.new(0.45, 0.45, 35)
                lp.Transparency = 1
                lp.CanCollide = false
                lp.CanTouch = false
                lp.CanQuery = false
                lp.Anchored = true
                lp.Parent = vfxFolder
                table.insert(segs, lp)
            end
            table.insert(rayBolts, segs)
        end
        table.insert(starLightningBolts, rayBolts)
    end

    -- Central Heaven Splitter Ray uniting the 5 rays
    local centerBeam = Instance.new("Part")
    centerBeam.Name = "CenterHeavenSplitter"
    centerBeam.Shape = Enum.PartType.Cylinder
    centerBeam.Material = Enum.Material.Neon
    centerBeam.Color = Color3.fromRGB(255, 255, 255)
    centerBeam.Size = Vector3.new(0.1, 0.1, 0.1)
    centerBeam.CFrame = CFrame.new(centerRitualPos) * CFrame.Angles(0, 0, math.rad(90))
    centerBeam.Transparency = 1
    centerBeam.CanCollide = false
    centerBeam.CanTouch = false
    centerBeam.CanQuery = false
    centerBeam.Anchored = true
    centerBeam.Parent = vfxFolder

    local centerBeamAura = Instance.new("Part")
    centerBeamAura.Name = "CenterHeavenSplitterAura"
    centerBeamAura.Shape = Enum.PartType.Cylinder
    centerBeamAura.Material = Enum.Material.Neon
    centerBeamAura.Color = rainbowColor(0.5, 0.25)
    centerBeamAura.Size = Vector3.new(0.1, 0.1, 0.1)
    centerBeamAura.CFrame = centerBeam.CFrame
    centerBeamAura.Transparency = 1
    centerBeamAura.CanCollide = false
    centerBeamAura.CanTouch = false
    centerBeamAura.CanQuery = false
    centerBeamAura.Anchored = true
    centerBeamAura.Parent = vfxFolder

    -- ========================================================================
    -- 3. TRIPLE 3D GYROSCOPIC ACCRETION SUPERNOVA (ACT III)
    -- 72 Arc Segments across 3 Tilted Rotating Axes! ZERO Diamond Models in Center!
    -- ========================================================================
    local SKY_RING_SEGS = 24

    -- Ring A: Horizontal expanding axis
    local skyAccretionRingA = {}
    for i = 1, SKY_RING_SEGS do
        local seg = Instance.new("Part")
        seg.Name = "SkyAccretionA_" .. i
        seg.Material = Enum.Material.Neon
        seg.Color = rainbowColor(i / SKY_RING_SEGS, 0.25)
        seg.Size = Vector3.new(2.6, 0.8, 1)
        seg.CFrame = CFrame.new(skyDetonationPos)
        seg.Transparency = 1
        seg.CanCollide = false
        seg.CanTouch = false
        seg.CanQuery = false
        seg.Anchored = true
        seg.Parent = vfxFolder
        table.insert(skyAccretionRingA, seg)
    end

    -- Ring B: Tilted +38 deg gyroscopic axis
    local skyAccretionRingB = {}
    for i = 1, SKY_RING_SEGS do
        local seg = Instance.new("Part")
        seg.Name = "SkyAccretionB_" .. i
        seg.Material = Enum.Material.Neon
        seg.Color = rainbowColor(1 - i / SKY_RING_SEGS, 0.25)
        seg.Size = Vector3.new(2.4, 0.7, 1)
        seg.CFrame = CFrame.new(skyDetonationPos)
        seg.Transparency = 1
        seg.CanCollide = false
        seg.CanTouch = false
        seg.CanQuery = false
        seg.Anchored = true
        seg.Parent = vfxFolder
        table.insert(skyAccretionRingB, seg)
    end

    -- Ring C: Counter-tilted -38 deg gyroscopic axis (Completes 3D Accretion Sphere!)
    local skyAccretionRingC = {}
    for i = 1, SKY_RING_SEGS do
        local seg = Instance.new("Part")
        seg.Name = "SkyAccretionC_" .. i
        seg.Material = Enum.Material.Neon
        seg.Color = rainbowColor(i / SKY_RING_SEGS + 0.5, 0.25)
        seg.Size = Vector3.new(2.2, 0.7, 1)
        seg.CFrame = CFrame.new(skyDetonationPos)
        seg.Transparency = 1
        seg.CanCollide = false
        seg.CanTouch = false
        seg.CanQuery = false
        seg.Anchored = true
        seg.Parent = vfxFolder
        table.insert(skyAccretionRingC, seg)
    end

    -- 64 Colossal Radial Supernova Spikes (Maximum celestial needle density!)
    local supernovaRays = {}
    for r = 1, 64 do
        local rayPart = Instance.new("Part")
        rayPart.Name = "SupernovaRay_" .. r
        rayPart.Shape = Enum.PartType.Cylinder
        rayPart.Material = Enum.Material.Neon
        rayPart.Color = rainbowColor(r / 64, 0.3)
        rayPart.Size = Vector3.new(1, 1, 1)
        rayPart.CFrame = CFrame.new(skyDetonationPos)
        rayPart.Transparency = 1
        rayPart.CanCollide = false
        rayPart.CanTouch = false
        rayPart.CanQuery = false
        rayPart.Anchored = true
        rayPart.Parent = vfxFolder

        local theta = math.acos(1 - 2 * (r / 64))
        local phi = math.sqrt(64 * math.pi) * theta
        local rayDir = Vector3.new(math.sin(theta) * math.cos(phi), math.cos(theta), math.sin(theta) * math.sin(phi)).Unit
        table.insert(supernovaRays, { part = rayPart, dir = rayDir })
    end

    -- 48 Supersonic Flying Faceted Diamond Shards (Flying AWAY from center)
    local blastShards = {}
    for s = 1, 48 do
        local sp = Instance.new("Part")
        sp.Name = "BlastShard_" .. s
        sp.Material = Enum.Material.Neon
        sp.Color = rainbowColor(s / 48, 0.3)
        sp.Size = Vector3.new(2.0, 3.5, 2.0)
        sp.CFrame = CFrame.new(skyDetonationPos)
        sp.Transparency = 1
        sp.CanCollide = false
        sp.CanTouch = false
        sp.CanQuery = false
        sp.Anchored = true
        sp.Parent = vfxFolder

        local smShard = Instance.new("SpecialMesh")
        smShard.MeshType = Enum.MeshType.FileMesh
        smShard.MeshId = MESH_DIAMOND
        smShard.Scale = Vector3.new(2.0, 3.6, 2.0)
        smShard.Parent = sp

        local rndAng = s * (math.pi * 2 / 48)
        local rndPitch = (s % 7 - 3) * 0.28
        local sDir = Vector3.new(math.cos(rndAng), rndPitch, math.sin(rndAng)).Unit
        table.insert(blastShards, { part = sp, dir = sDir })
    end

    -- Particle Detonation
    local blastEmitterRoot = Instance.new("Part")
    blastEmitterRoot.Name = "BlastEmitterRoot"
    blastEmitterRoot.Size = Vector3.new(1, 1, 1)
    blastEmitterRoot.CFrame = CFrame.new(skyDetonationPos)
    blastEmitterRoot.Transparency = 1
    blastEmitterRoot.CanCollide = false
    blastEmitterRoot.CanTouch = false
    blastEmitterRoot.CanQuery = false
    blastEmitterRoot.Anchored = true
    blastEmitterRoot.Parent = vfxFolder

    local blastSparksEmitter = Instance.new("ParticleEmitter")
    blastSparksEmitter.Name = "SupernovaSparks"
    blastSparksEmitter.Texture = TEX_SPARK
    blastSparksEmitter.LightEmission = 1
    blastSparksEmitter.Color = rainbowSeq(0.2, 0.5)
    blastSparksEmitter.Size = makeKeyframeNumberSeq({{0, 1.5}, {0.3, 4.2}, {1, 0.1}})
    blastSparksEmitter.Transparency = makeKeyframeNumberSeq({{0, 0.05}, {0.7, 0.35}, {1, 1}})
    blastSparksEmitter.Lifetime = NumberRange.new(2.5, 4.5)
    blastSparksEmitter.Rate = 0
    blastSparksEmitter.Speed = NumberRange.new(70, 220)
    blastSparksEmitter.SpreadAngle = Vector2.new(180, 180)
    blastSparksEmitter.Parent = blastEmitterRoot

    local blastGlintEmitter = Instance.new("ParticleEmitter")
    blastGlintEmitter.Name = "SupernovaGlints"
    blastGlintEmitter.Texture = TEX_GLINT
    blastGlintEmitter.LightEmission = 1
    blastGlintEmitter.Color = rainbowSeq(0.5, 0.3)
    blastGlintEmitter.Size = makeKeyframeNumberSeq({{0, 2.0}, {0.4, 5.2}, {1, 0.2}})
    blastGlintEmitter.Transparency = makeKeyframeNumberSeq({{0, 0.05}, {0.8, 0.4}, {1, 1}})
    blastGlintEmitter.Lifetime = NumberRange.new(3.0, 5.5)
    blastGlintEmitter.Rate = 0
    blastGlintEmitter.Speed = NumberRange.new(45, 160)
    blastGlintEmitter.SpreadAngle = Vector2.new(180, 180)
    blastGlintEmitter.Parent = blastEmitterRoot

    -- ========================================================================
    -- 4. CELESTIAL TITAN DRAGON & RE-ENTRY PLASMA TRAILS (ACT IV & V)
    -- ========================================================================
    local dragonBody = Instance.new("Part")
    dragonBody.Name = "CelestialTitanDragon"
    dragonBody.Size = Vector3.new(12, 10, 36)
    dragonBody.Material = Enum.Material.SmoothPlastic
    dragonBody.Color = Color3.fromRGB(255, 255, 255)
    dragonBody.Transparency = 1
    dragonBody.CanCollide = false
    dragonBody.CanTouch = false
    dragonBody.CanQuery = false
    dragonBody.Anchored = true
    dragonBody.Parent = companionFolder

    Transcendence.DragonBody = dragonBody
    Transcendence.DragonFolder = companionFolder

    -- Rideable Saddle & Interaction Prompt
    local saddle = Instance.new("Seat")
    saddle.Name = "DragonSaddle"
    saddle.Size = Vector3.new(2, 1, 2)
    saddle.Transparency = 1
    saddle.CanCollide = false
    saddle.Anchored = false
    saddle.Parent = companionFolder

    local saddleWeld = Instance.new("WeldConstraint")
    saddleWeld.Part0 = dragonBody
    saddleWeld.Part1 = saddle
    saddleWeld.Parent = saddle
    saddle.CFrame = dragonBody.CFrame * CFrame.new(0, 3.8, -1.0)
    Transcendence.DragonSaddle = saddle

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "DragonMountPrompt"
    prompt.ActionText = "Ride Celestial Dragon"
    prompt.ObjectText = "Titan Companion"
    prompt.MaxActivationDistance = 45
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    prompt.Parent = dragonBody

    prompt.Triggered:Connect(function(plr)
        if plr == LocalPlayer then
            Transcendence.mount()
        end
    end)

    local dragonMesh = Instance.new("SpecialMesh")
    dragonMesh.MeshType = Enum.MeshType.FileMesh
    dragonMesh.MeshId = MESH_DRAGON
    dragonMesh.TextureId = TEX_DRAGON
    dragonMesh.Scale = Vector3.new(36, 36, 36)
    dragonMesh.Parent = dragonBody

    -- Studio Lights
    local dragonHeadLight = Instance.new("PointLight")
    dragonHeadLight.Name = "DragonHeadLight"
    dragonHeadLight.Color = Color3.fromRGB(245, 250, 255)
    dragonHeadLight.Range = 40
    dragonHeadLight.Brightness = 2.4
    dragonHeadLight.Parent = dragonBody

    local dragonChestLight = Instance.new("PointLight")
    dragonChestLight.Name = "DragonChestLight"
    dragonChestLight.Color = Color3.fromRGB(230, 240, 255)
    dragonChestLight.Range = 60
    dragonChestLight.Brightness = 1.8
    dragonChestLight.Parent = dragonBody

    -- 6 Dorsal Spines
    local dragonSpines = {}
    Transcendence.DragonSpines = dragonSpines
    for sp = 1, 6 do
        local spinePart = Instance.new("Part")
        spinePart.Name = "DragonDorsalSpine_" .. sp
        spinePart.Material = Enum.Material.Neon
        spinePart.Color = rainbowColor(sp / 6, 0.35)
        spinePart.Size = Vector3.new(1, 1, 1)
        spinePart.Transparency = 1
        spinePart.CanCollide = false
        spinePart.CanTouch = false
        spinePart.CanQuery = false
        spinePart.Anchored = true
        spinePart.Parent = companionFolder

        local smSpine = Instance.new("SpecialMesh")
        smSpine.MeshType = Enum.MeshType.FileMesh
        smSpine.MeshId = MESH_DIAMOND
        smSpine.Scale = Vector3.new(1.4, 4.0, 1.4)
        smSpine.Parent = spinePart

        table.insert(dragonSpines, {
            part = spinePart,
            zOffset = ((sp / 6) - 0.5) * 24.0,
            yOffset = 4.2 + (sp % 2) * 0.8,
            index = sp
        })
    end

    -- Wingtip Re-entry Plasma Trail Emitters
    local wingAttLeft = Instance.new("Attachment")
    wingAttLeft.Position = Vector3.new(-18.0, 2.0, 6.0)
    wingAttLeft.Parent = dragonBody

    local wingAttRight = Instance.new("Attachment")
    wingAttRight.Position = Vector3.new(18.0, 2.0, 6.0)
    wingAttRight.Parent = dragonBody

    local function makeWingPlasmaEmitter(parentAtt)
        local pe = Instance.new("ParticleEmitter")
        pe.Name = "WingPlasmaTrail"
        pe.Texture = TEX_GLINT
        pe.LightEmission = 1.0
        pe.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 240, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 140, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 180))
        })
        pe.Size = makeKeyframeNumberSeq({{0, 2.5}, {0.5, 6.0}, {1, 0.1}})
        pe.Transparency = makeKeyframeNumberSeq({{0, 0.1}, {0.6, 0.35}, {1, 1}})
        pe.Lifetime = NumberRange.new(0.8, 1.6)
        pe.Rate = 0
        pe.Speed = NumberRange.new(15, 35)
        pe.SpreadAngle = Vector2.new(15, 15)
        pe.Parent = parentAtt
        return pe
    end

    local wingPlasmaLeft = makeWingPlasmaEmitter(wingAttLeft)
    local wingPlasmaRight = makeWingPlasmaEmitter(wingAttRight)

    -- Dragon Mouth Fire Emitter
    local dragonBreathAtt = Instance.new("Attachment")
    dragonBreathAtt.Name = "DragonMouthAttachment"
    dragonBreathAtt.Position = Vector3.new(0, 1.2, -18.5)
    dragonBreathAtt.Parent = dragonBody

    local dragonFireEmitter = Instance.new("ParticleEmitter")
    dragonFireEmitter.Name = "CelestialDiamondFire"
    dragonFireEmitter.Texture = TEX_SPARK
    dragonFireEmitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(160, 220, 255)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(220, 140, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 160))
    })
    dragonFireEmitter.Size = makeKeyframeNumberSeq({{0, 2.4}, {0.4, 6.2}, {1, 0}})
    dragonFireEmitter.Transparency = makeKeyframeNumberSeq({{0, 0.1}, {0.6, 0.3}, {1, 1}})
    dragonFireEmitter.Lifetime = NumberRange.new(1.2, 2.5)
    dragonFireEmitter.Rate = 55
    dragonFireEmitter.Speed = NumberRange.new(22, 48)
    dragonFireEmitter.SpreadAngle = Vector2.new(22, 22)
    dragonFireEmitter.LightEmission = 0.95
    dragonFireEmitter.Parent = dragonBreathAtt

    -- Ground Downwash Shockwave Root (Under Dragon Hover Station)
    local downwashRoot = Instance.new("Part")
    downwashRoot.Name = "DragonDownwashRoot"
    downwashRoot.Size = Vector3.new(1, 1, 1)
    downwashRoot.CFrame = CFrame.new(targetPos + rightVec * 28.0 + lookVec * 8.0)
    downwashRoot.Transparency = 1
    downwashRoot.CanCollide = false
    downwashRoot.CanTouch = false
    downwashRoot.CanQuery = false
    downwashRoot.Anchored = true
    downwashRoot.Parent = vfxFolder

    local downwashMist = Instance.new("ParticleEmitter")
    downwashMist.Name = "DownwashMist"
    downwashMist.Texture = TEX_MIST
    downwashMist.LightEmission = 0.55
    downwashMist.Color = rainbowSeq(0.3, 0.2)
    downwashMist.Size = makeKeyframeNumberSeq({{0, 3.5}, {0.5, 14.0}, {1, 24.0}})
    downwashMist.Transparency = makeKeyframeNumberSeq({{0, 0.15}, {0.5, 0.55}, {1, 1}})
    downwashMist.Lifetime = NumberRange.new(2.2, 3.8)
    downwashMist.Rate = 0
    downwashMist.Speed = NumberRange.new(30, 75)
    downwashMist.SpreadAngle = Vector2.new(90, 90)
    downwashMist.EmissionDirection = Enum.NormalId.Top
    downwashMist.Parent = downwashRoot

    local downwashSparks = Instance.new("ParticleEmitter")
    downwashSparks.Name = "DownwashSparks"
    downwashSparks.Texture = TEX_SPARK
    downwashSparks.LightEmission = 1
    downwashSparks.Color = rainbowSeq(0.5, 0.3)
    downwashSparks.Size = makeKeyframeNumberSeq({{0, 1.4}, {0.5, 3.2}, {1, 0.1}})
    downwashSparks.Transparency = makeKeyframeNumberSeq({{0, 0.08}, {0.7, 0.3}, {1, 1}})
    downwashSparks.Lifetime = NumberRange.new(1.6, 3.0)
    downwashSparks.Rate = 0
    downwashSparks.Speed = NumberRange.new(35, 90)
    downwashSparks.SpreadAngle = Vector2.new(85, 85)
    downwashSparks.EmissionDirection = Enum.NormalId.Top
    downwashSparks.Parent = downwashRoot

    local downwashGlints = Instance.new("ParticleEmitter")
    downwashGlints.Name = "DownwashGlints"
    downwashGlints.Texture = TEX_GLINT
    downwashGlints.LightEmission = 1
    downwashGlints.Color = rainbowSeq(0.2, 0.4)
    downwashGlints.Size = makeKeyframeNumberSeq({{0, 1.8}, {0.5, 4.0}, {1, 0.2}})
    downwashGlints.Transparency = makeKeyframeNumberSeq({{0, 0.05}, {0.7, 0.35}, {1, 1}})
    downwashGlints.Lifetime = NumberRange.new(1.8, 3.2)
    downwashGlints.Rate = 0
    downwashGlints.Speed = NumberRange.new(25, 70)
    downwashGlints.SpreadAngle = Vector2.new(90, 90)
    downwashGlints.EmissionDirection = Enum.NormalId.Top
    downwashGlints.Parent = downwashRoot

    -- Swarm of 16 Diamond Star Escorts
    local ESCORT_COUNT = 16
    local dragonEscortCrystals = {}
    Transcendence.DragonEscorts = dragonEscortCrystals
    for e = 1, ESCORT_COUNT do
        local ePart = Instance.new("Part")
        ePart.Name = "DragonEscortCrystal_" .. e
        ePart.Material = Enum.Material.Neon
        ePart.Color = rainbowColor(e / ESCORT_COUNT, 0.45)
        ePart.Size = Vector3.new(2.4, 5.2, 2.4)
        ePart.Transparency = 1
        ePart.CanCollide = false
        ePart.CanTouch = false
        ePart.CanQuery = false
        ePart.Anchored = true
        ePart.Parent = companionFolder

        local smEscort = Instance.new("SpecialMesh")
        smEscort.MeshType = Enum.MeshType.FileMesh
        smEscort.MeshId = MESH_DIAMOND
        smEscort.Scale = Vector3.new(2.2, 4.8, 2.2)
        smEscort.Parent = ePart

        table.insert(dragonEscortCrystals, {
            part = ePart,
            index = e,
            basePhase = (e / ESCORT_COUNT) * math.pi * 2,
            axialOffset = ((e / ESCORT_COUNT) - 0.5) * 36.0,
            orbitRadius = 16.0 + (e % 3) * 3.5
        })
    end

    -- ========================================================================
    -- CINEMATIC CLEANUP & COMPANION LIFECYCLE (34.0 SECONDS TOTAL)
    -- ========================================================================
    local TOTAL_DURATION = 34.0

    local function endCinematic()
        if isDone then return end
        isDone = true
        if renderConn then renderConn:Disconnect() end

        pcall(function()
            if cinemaScreen then cinemaScreen:Destroy() end
            if vfxFolder then vfxFolder:Destroy() end
            if bloom then bloom:Destroy() end
            if colorCorrection then colorCorrection:Destroy() end
            if sunRays then sunRays:Destroy() end
            if atmo then atmo:Destroy() end
        end)

        pcall(function()
            Lighting.ClockTime = oldClockTime
            Lighting.Brightness = oldBrightness
            Lighting.Ambient = oldAmbient
            Lighting.OutdoorAmbient = oldOutdoorAmbient
            Lighting.FogEnd = oldFogEnd
            Lighting.FogColor = oldFogColor
            Lighting.ExposureCompensation = oldExposure
        end)

        local liveChar = LocalPlayer and LocalPlayer.Character or char
        local liveHrp = liveChar and (liveChar:FindFirstChild("HumanoidRootPart") or liveChar:FindFirstChild("Torso") or liveChar:FindFirstChildWhichIsA("BasePart"))
        local liveHum = liveChar and liveChar:FindFirstChildOfClass("Humanoid")
        if liveHrp then
            liveHrp.Anchored = false
        end
        if liveHum then
            liveHum.WalkSpeed = 16
            liveHum.JumpPower = 50
        end

        cam.CameraType = oldCameraType
        if oldCameraCF and liveHrp then
            cam.CFrame = CFrame.lookAt(
                liveHrp.Position - liveHrp.CFrame.LookVector * 18 + Vector3.new(0, 5.0, 0),
                liveHrp.Position + Vector3.new(0, 1.8, 0)
            )
            cam.FieldOfView = oldCameraFOV
        end

        setGameGuisVisible(true)

        -- PERMANENT DRAGON COMPANION BESIDE PLAYER (Y + 38.0 STUDS)
        task.spawn(function()
            local companionConn = nil
            companionConn = RunService.Heartbeat:Connect(function()
                local cChar = LocalPlayer and LocalPlayer.Character or char
                local cHrp = cChar and (cChar:FindFirstChild("HumanoidRootPart") or cChar:FindFirstChild("Torso") or cChar:FindFirstChildWhichIsA("BasePart"))
                if not cHrp or not companionFolder or not companionFolder.Parent then
                    if companionConn then companionConn:Disconnect() end
                    return
                end

                if Transcendence.IsRiding then
                    return
                end

                local now = tick()
                -- Elevated hover at Y + 38.0 studs above player feet!
                local targetFollowPos = cHrp.Position + cHrp.CFrame.RightVector * 28 + cHrp.CFrame.LookVector * 8 + Vector3.new(0, 38.0 + math.sin(now * 2.2) * 1.8, 0)
                local bodyPos = dragonBody.Position:Lerp(targetFollowPos, 0.08)

                local targetLook = cHrp.Position + cHrp.CFrame.LookVector * 65 + Vector3.new(0, 15, 0)
                local baseCF = CFrame.lookAt(bodyPos, targetLook)
                local bankAngle = math.sin(now * 1.8) * 0.06
                local pitchAngle = math.rad(10) + math.cos(now * 2.2) * 0.04
                dragonBody.CFrame = baseCF * CFrame.Angles(pitchAngle, 0, bankAngle)
                dragonBody.Transparency = 0.05

                -- Update Dorsal Spines
                for _, sData in ipairs(dragonSpines) do
                    if sData.part then
                        sData.part.CFrame = baseCF * CFrame.new(0, sData.yOffset, sData.zOffset) * CFrame.Angles(math.rad(25), 0, 0)
                        sData.part.Transparency = 0.15
                        sData.part.Color = rainbowColor(sData.index / 6 + now * 0.25, 0.4)
                    end
                end

                -- 4 Orbiting Familiar Crystals
                for idx = 1, 4 do
                    local eData = dragonEscortCrystals[idx]
                    if eData and eData.part then
                        local eAng = now * 2.5 + (idx / 4) * math.pi * 2
                        local ePos = bodyPos + Vector3.new(math.cos(eAng) * 20.0, math.sin(now * 3.0 + idx) * 2.5, math.sin(eAng) * 20.0)
                        eData.part.CFrame = CFrame.new(ePos) * CFrame.Angles(now * 3, eAng, 0)
                        eData.part.Transparency = 0.15
                        eData.part.Color = rainbowColor(idx / 4 + now * 0.2, 0.4)
                    end
                end
            end)
        end)

        if onComplete then
            onComplete()
        end
    end

    -- Flags
    local didStarEruption = false
    local didDetonation = false
    local didLandingRoar = false
    local shakeIntensity = 0.0

    -- ========================================================================
    -- THE 34-SECOND STREAMLINED RENDER LOOP
    -- ========================================================================
    local startTime = tick()
    renderConn = RunService.RenderStepped:Connect(function(dt)
        local elapsed = tick() - startTime
        local now = tick()

        if elapsed >= TOTAL_DURATION then
            endCinematic()
            return
        end

        local stepOk, stepErr = pcall(function()
            -----------------------------------------------------------------
            -- ACT I (0.0s - 6.0s): GROUND SACRED MANDALA & DUAL HALOS (6.0s)
            -- Macro-to-Wide Camera Whip-Pan + 6 Radiant Leylines!
            -----------------------------------------------------------------
            if elapsed < 6.0 then
                local p = elapsed / 6.0
                local easeP = p * p * (3 - 2 * p)

                Lighting.ClockTime = 0.0
                Lighting.Brightness = 0.05
                Lighting.Ambient = Color3.fromRGB(15, 0, 25)
                Lighting.OutdoorAmbient = Color3.fromRGB(10, 0, 20)
                Lighting.FogEnd = 400
                Lighting.FogColor = Color3.fromRGB(20, 2, 35)

                -- Genesis Diamond Core Floating
                genesisCore.Transparency = math.clamp(0.65 - easeP * 0.6, 0.05, 0.65)
                genesisCore.Color = Color3.fromRGB(255, 255, 255):Lerp(rainbowColor(elapsed * 0.3, 0.3), 0.35)
                genesisCore.CFrame = CFrame.new(centerRitualPos + Vector3.new(0, 3.5 + math.sin(elapsed * 2.2) * 0.4, 0)) * CFrame.Angles(0, elapsed * 1.5, 0)
                coreLight.Color = rainbowColor(elapsed * 0.3, 0.25)

                -- Dual 3D Starlight Halos
                local tiltA = CFrame.Angles(math.rad(35), elapsed * 1.8, 0)
                for h = 1, HALO_SEGS do
                    local ang0 = (h - 1) * (math.pi * 2 / HALO_SEGS)
                    local ang1 = h * (math.pi * 2 / HALO_SEGS)
                    local hp0 = genesisCore.Position + tiltA * Vector3.new(math.cos(ang0) * HALO_RAD_A, 0, math.sin(ang0) * HALO_RAD_A)
                    local hp1 = genesisCore.Position + tiltA * Vector3.new(math.cos(ang1) * HALO_RAD_A, 0, math.sin(ang1) * HALO_RAD_A)
                    local hSeg = haloSegsA[h]
                    hSeg.Size = Vector3.new(0.18, 0.18, (hp1 - hp0).Magnitude)
                    hSeg.CFrame = CFrame.lookAt((hp0 + hp1) / 2, hp1)
                    hSeg.Color = rainbowColor((h / HALO_SEGS) + elapsed * 0.25, 0.35)
                    hSeg.Transparency = math.clamp(0.65 - easeP * 0.4, 0.15, 0.7)
                end

                local tiltB = CFrame.Angles(math.rad(-35), -elapsed * 1.6, 0)
                for h = 1, HALO_SEGS do
                    local ang0 = (h - 1) * (math.pi * 2 / HALO_SEGS)
                    local ang1 = h * (math.pi * 2 / HALO_SEGS)
                    local hp0 = genesisCore.Position + tiltB * Vector3.new(math.cos(ang0) * HALO_RAD_B, 0, math.sin(ang0) * HALO_RAD_B)
                    local hp1 = genesisCore.Position + tiltB * Vector3.new(math.cos(ang1) * HALO_RAD_B, 0, math.sin(ang1) * HALO_RAD_B)
                    local hSeg = haloSegsB[h]
                    hSeg.Size = Vector3.new(0.16, 0.16, (hp1 - hp0).Magnitude)
                    hSeg.CFrame = CFrame.lookAt((hp0 + hp1) / 2, hp1)
                    hSeg.Color = rainbowColor((1 - h / HALO_SEGS) - elapsed * 0.25, 0.35)
                    hSeg.Transparency = math.clamp(0.70 - easeP * 0.4, 0.20, 0.75)
                end

                -- Outer & Inner Laser Rings
                for i, seg in ipairs(groundCircleSegments) do
                    local ang0 = (i - 1) * (math.pi * 2 / NUM_SEGS) + elapsed * 0.35
                    local ang1 = i * (math.pi * 2 / NUM_SEGS) + elapsed * 0.35
                    local p0 = centerRitualPos + Vector3.new(math.cos(ang0) * CIRCLE_RADIUS, 0.05, math.sin(ang0) * CIRCLE_RADIUS)
                    local p1 = centerRitualPos + Vector3.new(math.cos(ang1) * CIRCLE_RADIUS, 0.05, math.sin(ang1) * CIRCLE_RADIUS)
                    seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
                    seg.Color = rainbowColor((i / NUM_SEGS) + elapsed * 0.2, 0.3)
                    seg.Transparency = math.clamp(0.6 - easeP * 0.4, 0.15, 0.6)
                end

                for i, seg in ipairs(groundInnerCircle) do
                    local ang0 = (i - 1) * (math.pi * 2 / NUM_SEGS) - elapsed * 0.45
                    local ang1 = i * (math.pi * 2 / NUM_SEGS) - elapsed * 0.45
                    local p0 = centerRitualPos + Vector3.new(math.cos(ang0) * INNER_RADIUS, 0.05, math.sin(ang0) * INNER_RADIUS)
                    local p1 = centerRitualPos + Vector3.new(math.cos(ang1) * INNER_RADIUS, 0.05, math.sin(ang1) * INNER_RADIUS)
                    seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
                    seg.Color = rainbowColor((1 - i / NUM_SEGS) - elapsed * 0.2, 0.3)
                    seg.Transparency = math.clamp(0.65 - easeP * 0.4, 0.2, 0.65)
                end

                -- 6 Radiant Laser Leylines pulsing with light
                for i, ley in ipairs(groundLeylines) do
                    ley.Transparency = math.clamp(0.6 - easeP * 0.35, 0.15, 0.6)
                    ley.Color = rainbowColor(i / 6 + elapsed * 0.3, 0.35)
                end

                -- Macro-to-Wide Dynamic Whip-Pan Camera
                local pullDist = 8.0 + easeP * 46.0
                local pullHeight = 2.5 + easeP * 13.5
                local camOrbit = (elapsed / 6.0) * 0.45 - math.pi * 0.12
                local camOffset = -lookVec * (math.cos(camOrbit) * pullDist) + rightVec * (math.sin(camOrbit) * pullDist) + Vector3.new(0, pullHeight, 0)
                local camPos = targetPos + camOffset
                local targetFocus = centerRitualPos + Vector3.new(0, 3.5, 0)
                cam.CFrame = CFrame.lookAt(camPos, targetFocus)
                cam.FieldOfView = 68 + easeP * 16

            -----------------------------------------------------------------
            -- ACT II (6.0s - 14.0s): THE COLOSSAL 130-STUD 5-RAY CELESTIAL STAR (8.0s)
            -- Sequential Chord Pulse + 5 Monoliths + 5 Sky Rays + Climbing Plasma Rings!
            -----------------------------------------------------------------
            elseif elapsed < 14.0 then
                local pAct2 = (elapsed - 6.0) / 8.0
                local beamP = math.clamp((elapsed - 6.0) / 2.0, 0, 1)

                if not didStarEruption then
                    didStarEruption = true
                    pcall(function() boomSound:Play() end)
                    pcall(function() rumbleSound:Play() end)

                    flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    flashFrame.BackgroundTransparency = 0.25
                    uiTween(flashFrame, 0.7, { BackgroundTransparency = 1 })
                end

                local dayP = math.clamp(pAct2 * 1.15, 0, 1)
                Lighting.ClockTime = dayP * 14.0
                Lighting.Brightness = 0.05 + dayP * 2.2
                Lighting.Ambient = Color3.fromRGB(15, 0, 25):Lerp(Color3.fromRGB(140, 110, 155), dayP)
                Lighting.OutdoorAmbient = Color3.fromRGB(10, 0, 20):Lerp(Color3.fromRGB(155, 120, 175), dayP)
                Lighting.FogEnd = 400 + dayP * 9600
                Lighting.FogColor = Color3.fromRGB(20, 2, 35):Lerp(Color3.fromRGB(235, 210, 255), dayP)

                -- 1. Display Titanic 5-Pointed Star Pentagram & Pentagon Chords with Sequential Surge
                local chordPulse = (elapsed * 3.5) % 5
                for idx, chord in ipairs(pentagramChords) do
                    local isPulse = math.abs(chordPulse - idx) < 0.8
                    chord.Transparency = isPulse and 0.05 or math.clamp(0.15 + (1 - beamP) * 0.6, 0.15, 0.8)
                    chord.Color = rainbowColor(idx / 5 + elapsed * 0.25, 0.35)
                end
                for idx, chord in ipairs(pentagonChords) do
                    chord.Transparency = math.clamp(0.25 + (1 - beamP) * 0.6, 0.25, 0.9)
                    chord.Color = rainbowColor(idx / 5 + 0.5 + elapsed * 0.25, 0.35)
                end

                -- 2. Display 5 Monoliths & Spinning Capstones
                for _, mData in ipairs(starMonoliths) do
                    mData.monolith.Transparency = math.clamp(0.15 + (1 - beamP) * 0.7, 0.15, 0.8)
                    mData.monolith.Color = rainbowColor(mData.index / 5 + elapsed * 0.2, 0.3)
                    mData.capstone.Transparency = math.clamp(0.10 + (1 - beamP) * 0.6, 0.10, 0.8)
                    mData.capstone.Color = rainbowColor(mData.index / 5 + 0.3 + elapsed * 0.3, 0.4)
                    mData.capstone.CFrame = CFrame.new(mData.pos.X, mData.pos.Y + 39.0 + math.sin(elapsed * 3.0 + mData.index) * 1.0, mData.pos.Z) * CFrame.Angles(elapsed * 2.5, elapsed * 1.8, 0)
                end

                -- 3. Erupt 5 Colossal Sky Rays (1600 studs tall!) + Climbing Plasma Rings
                local rayH = math.min(beamP * 1600, 1600)
                for idx, rData in ipairs(starRays) do
                    rData.core.Size = Vector3.new(rayH, 9, 9)
                    rData.core.CFrame = CFrame.new(rData.pt.X, rData.pt.Y + rayH / 2, rData.pt.Z) * CFrame.Angles(0, 0, math.rad(90))
                    rData.core.Color = Color3.fromRGB(255, 255, 255):Lerp(rainbowColor(idx / 5 + elapsed * 0.2, 0.3), 0.25)
                    rData.core.Transparency = math.clamp(0.08 + (1 - beamP) * 0.5, 0.08, 0.8)

                    rData.aura.Size = Vector3.new(rayH, 24, 24)
                    rData.aura.CFrame = rData.core.CFrame
                    rData.aura.Color = rainbowColor(idx / 5 + elapsed * 0.25 + 0.4, 0.3)
                    rData.aura.Transparency = math.clamp(0.25 + (1 - beamP) * 0.6, 0.25, 0.9)

                    rData.beam.Transparency = NumberSequence.new(math.clamp(0.1 + (1 - beamP) * 0.8, 0.1, 1))
                    rData.beam.Color = rainbowSeq(idx / 5 + elapsed * 0.3, 0.35)

                    -- Climbing Plasma Ring racing to stratosphere
                    local cRing = starClimbingRings[idx]
                    local ringY = (now * 160 + idx * 250) % 1500
                    cRing.CFrame = CFrame.new(rData.pt.X, rData.pt.Y + ringY, rData.pt.Z) * CFrame.Angles(0, 0, math.rad(90))
                    cRing.Transparency = math.clamp(0.2 + (1 - beamP) * 0.6, 0.15, 0.85)
                    cRing.Color = rainbowColor(idx / 5 + ringY / 500, 0.4)
                end

                -- 4. Branching Lightning along all 5 rays
                for rIdx, boltGroup in ipairs(starLightningBolts) do
                    local rPos = starPoints[rIdx].pos
                    for bIdx, boltSegs in ipairs(boltGroup) do
                        local bAng = (bIdx - 1) * (math.pi * 2 / 3) + elapsed * 1.5
                        local bRad = 14.0 + math.sin(elapsed * 8 + bIdx) * 4.0
                        for sIdx, seg in ipairs(boltSegs) do
                            local sP0 = (sIdx - 1) / #boltSegs
                            local sP1 = sIdx / #boltSegs
                            local y0 = math.min(sP0 * rayH, 1500)
                            local y1 = math.min(sP1 * rayH, 1500)

                            local j0 = math.sin(now * 35 + sIdx * 3 + bIdx) * 4.5
                            local j1 = math.cos(now * 40 + sIdx * 4 + bIdx) * 4.5
                            local p0 = rPos + Vector3.new(math.cos(bAng) * bRad + j0, y0, math.sin(bAng) * bRad + j0)
                            local p1 = rPos + Vector3.new(math.cos(bAng) * bRad + j1, y1, math.sin(bAng) * bRad + j1)

                            local segLen = (p1 - p0).Magnitude
                            seg.Size = Vector3.new(0.45, 0.45, segLen)
                            seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
                            seg.Color = rainbowColor(rIdx / 5 + sIdx / 30 + elapsed * 0.3, 0.4)
                            seg.Transparency = math.clamp((1 - beamP) * 0.5, 0.1, 0.8)
                        end
                    end
                end

                -- 5. Central Heaven Splitter Beam
                centerBeam.Size = Vector3.new(rayH, 12, 12)
                centerBeam.CFrame = CFrame.new(centerRitualPos.X, centerRitualPos.Y + rayH / 2, centerRitualPos.Z) * CFrame.Angles(0, 0, math.rad(90))
                centerBeam.Transparency = math.clamp(0.08 + (1 - beamP) * 0.5, 0.08, 0.8)

                centerBeamAura.Size = Vector3.new(rayH, 28, 28)
                centerBeamAura.CFrame = centerBeam.CFrame
                centerBeamAura.Color = rainbowColor(elapsed * 0.3 + 0.5, 0.3)
                centerBeamAura.Transparency = math.clamp(0.25 + (1 - beamP) * 0.6, 0.25, 0.9)

                genesisCore.CFrame = CFrame.new(centerRitualPos + Vector3.new(0, 3.5 + pAct2 * 80.0, 0)) * CFrame.Angles(0, elapsed * 4.0, 0)
                genesisCore.Transparency = 0.05

                shakeIntensity = 1.8 * (1 - beamP * 0.25)

                -- 6. EXPANDED AERIAL CRANE CAMERA FRAMING THE TITANIC 130-STUD STAR!
                local camOrbit = (elapsed - 6.0) * 0.32 - math.pi * 0.35
                local camDist = 135.0 + pAct2 * 45.0
                local camHeight = 40.0 + pAct2 * 90.0
                local camPos = centerRitualPos + Vector3.new(math.sin(camOrbit) * camDist, camHeight, math.cos(camOrbit) * camDist)
                local lookFocus = centerRitualPos + Vector3.new(0, 25.0 + pAct2 * 55.0, 0)
                cam.CFrame = CFrame.lookAt(camPos, lookFocus)
                cam.FieldOfView = 86

            -----------------------------------------------------------------
            -- ACT III (14.0s - 21.0s): TRIPLE-RING ACCRETION SUPERNOVA (7.0s)
            -- 14.0s - 14.8s: Relativistic Singularity Suction
            -- 14.8s - 21.0s: Triple 3D Gyroscopic Accretion Rings (72 Arcs) + 64 Laser Needles + 48 Shards
            -- ZERO DIAMOND MODELS IN THE MIDDLE! Pure blinding astrophysical energy!
            -----------------------------------------------------------------
            elseif elapsed < 21.0 then
                local pAct3 = (elapsed - 14.0) / 7.0

                -- Hide Act II Rays, Star Chords, Monoliths, and Climbing Rings
                centerBeam.Transparency = 1
                centerBeamAura.Transparency = 1
                for _, rData in ipairs(starRays) do
                    rData.core.Transparency = 1
                    rData.aura.Transparency = 1
                    rData.beam.Transparency = NumberSequence.new(1)
                end
                for _, cRing in ipairs(starClimbingRings) do cRing.Transparency = 1 end
                for _, chord in ipairs(pentagramChords) do chord.Transparency = 1 end
                for _, chord in ipairs(pentagonChords) do chord.Transparency = 1 end
                for _, mData in ipairs(starMonoliths) do
                    mData.monolith.Transparency = 1
                    mData.capstone.Transparency = 1
                end
                for _, boltGroup in ipairs(starLightningBolts) do
                    for _, segs in ipairs(boltGroup) do
                        for _, seg in ipairs(segs) do seg.Transparency = 1 end
                    end
                end
                for _, seg in ipairs(groundCircleSegments) do seg.Transparency = 1 end
                for _, seg in ipairs(groundInnerCircle) do seg.Transparency = 1 end
                for _, ley in ipairs(groundLeylines) do ley.Transparency = 1 end
                for _, hSeg in ipairs(haloSegsA) do hSeg.Transparency = 1 end
                for _, hSeg in ipairs(haloSegsB) do hSeg.Transparency = 1 end
                genesisCore.Transparency = 1

                -- 14.0s - 14.8s: Relativistic Singularity Collapse
                if elapsed < 14.8 then
                    local pSing = (elapsed - 14.0) / 0.8
                    shakeIntensity = 1.0 + pSing * 2.5
                    colorCorrection.Contrast = 0.4 + pSing * 0.55

                    local camPos = skyDetonationPos - lookVec * 55.0 + Vector3.new(0, 12.0, 0)
                    cam.CFrame = CFrame.lookAt(camPos, skyDetonationPos)
                    cam.FieldOfView = 80 - pSing * 12

                -- 14.8s - 21.0s: TRIPLE ACCRETION SUPERNOVA DETONATION
                else
                    local pDet = (elapsed - 14.8) / 6.2
                    local easeExp = pDet * pDet * (3 - 2 * pDet)

                    if not didDetonation then
                        didDetonation = true
                        pcall(function() boomSound:Play() end)
                        pcall(function() celestialRoarSound:Play() end)
                        blastSparksEmitter:Emit(500)
                        blastGlintEmitter:Emit(400)

                        flashFrame.BackgroundColor3 = Color3.fromRGB(255, 245, 255)
                        flashFrame.BackgroundTransparency = 0.15
                        uiTween(flashFrame, 0.7, { BackgroundTransparency = 1 })

                        colorCorrection.Contrast = 0.85
                        bloom.Intensity = 2.0
                        uiTween(colorCorrection, 2.0, { Contrast = 0.18 })
                        uiTween(bloom, 2.0, { Intensity = 0.85 })
                    end

                    -- 1. Triple 3D Gyroscopic Accretion Rings (72 Arc Segments Total!)
                    local radA = 20 + easeExp * 1050
                    for i, seg in ipairs(skyAccretionRingA) do
                        local a0 = (i - 1) * (math.pi * 2 / SKY_RING_SEGS)
                        local a1 = i * (math.pi * 2 / SKY_RING_SEGS)
                        local p0 = skyDetonationPos + Vector3.new(math.cos(a0) * radA, 0, math.sin(a0) * radA)
                        local p1 = skyDetonationPos + Vector3.new(math.cos(a1) * radA, 0, math.sin(a1) * radA)
                        local chordLen = (p1 - p0).Magnitude
                        seg.Size = Vector3.new(math.max((1 - pDet) * 4.5, 0.8), 1.0, chordLen)
                        seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
                        seg.Color = rainbowColor(i / SKY_RING_SEGS + elapsed * 0.3, 0.35)
                        seg.Transparency = math.clamp(pDet * 0.8, 0.05, 0.85)
                    end

                    local radB = 15 + easeExp * 900
                    local tiltCF = CFrame.Angles(math.rad(38), elapsed * 0.8, 0)
                    for i, seg in ipairs(skyAccretionRingB) do
                        local a0 = (i - 1) * (math.pi * 2 / SKY_RING_SEGS)
                        local a1 = i * (math.pi * 2 / SKY_RING_SEGS)
                        local lp0 = tiltCF * Vector3.new(math.cos(a0) * radB, 0, math.sin(a0) * radB)
                        local lp1 = tiltCF * Vector3.new(math.cos(a1) * radB, 0, math.sin(a1) * radB)
                        local p0 = skyDetonationPos + lp0
                        local p1 = skyDetonationPos + lp1
                        local chordLen = (p1 - p0).Magnitude
                        seg.Size = Vector3.new(math.max((1 - pDet) * 3.5, 0.6), 0.8, chordLen)
                        seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
                        seg.Color = rainbowColor(1 - i / SKY_RING_SEGS + elapsed * 0.3, 0.35)
                        seg.Transparency = math.clamp(pDet * 0.85, 0.08, 0.9)
                    end

                    local radC = 18 + easeExp * 950
                    local tiltCFC = CFrame.Angles(math.rad(-38), -elapsed * 0.75, 0)
                    for i, seg in ipairs(skyAccretionRingC) do
                        local a0 = (i - 1) * (math.pi * 2 / SKY_RING_SEGS)
                        local a1 = i * (math.pi * 2 / SKY_RING_SEGS)
                        local lp0 = tiltCFC * Vector3.new(math.cos(a0) * radC, 0, math.sin(a0) * radC)
                        local lp1 = tiltCFC * Vector3.new(math.cos(a1) * radC, 0, math.sin(a1) * radC)
                        local p0 = skyDetonationPos + lp0
                        local p1 = skyDetonationPos + lp1
                        local chordLen = (p1 - p0).Magnitude
                        seg.Size = Vector3.new(math.max((1 - pDet) * 3.2, 0.6), 0.8, chordLen)
                        seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
                        seg.Color = rainbowColor(i / SKY_RING_SEGS + 0.5 + elapsed * 0.3, 0.35)
                        seg.Transparency = math.clamp(pDet * 0.85, 0.08, 0.9)
                    end

                    -- 2. 64 Colossal Radial Supernova Spikes
                    local rayLen = easeExp * 800
                    local rayWidth = math.max((1 - pDet) * 14.0, 0.4)
                    for rIdx, rayData in ipairs(supernovaRays) do
                        rayData.part.Size = Vector3.new(rayLen, rayWidth, rayWidth)
                        rayData.part.CFrame = CFrame.lookAt(skyDetonationPos + rayData.dir * (rayLen / 2), skyDetonationPos + rayData.dir * rayLen) * CFrame.Angles(0, 0, math.rad(90))
                        rayData.part.Color = rainbowColor(rIdx / 64 + elapsed * 0.3, 0.35)
                        rayData.part.Transparency = math.clamp(pDet * 0.9, 0.05, 0.95)
                    end

                    -- 3. 48 Supersonic Flying Faceted Diamond Shards (Flying AWAY into deep space!)
                    local shardDist = easeExp * 600
                    for _, bData in ipairs(blastShards) do
                        local sPos = skyDetonationPos + bData.dir * shardDist
                        bData.part.CFrame = CFrame.lookAt(sPos, sPos + bData.dir) * CFrame.Angles(elapsed * 18, elapsed * 14, 0)
                        bData.part.Transparency = math.clamp(pDet * 0.85, 0.05, 0.9)
                        bData.part.Color = rainbowColor(pDet + elapsed * 0.3, 0.45)
                    end

                    shakeIntensity = 4.5 * (1 - pDet)

                    -- Panoramic recoil camera
                    local recoilDist = 65 + easeExp * 55
                    local boomCamPos = skyDetonationPos - lookVec * recoilDist + Vector3.new(0, 16.0, 0)
                    cam.CFrame = CFrame.lookAt(boomCamPos, skyDetonationPos)
                    cam.FieldOfView = 88 + easeExp * 10
                end

            -----------------------------------------------------------------
            -- ACT IV (21.0s - 27.5s): DRAGON HYPERSONIC RE-ENTRY & GROUND FLARE (6.5s)
            -- 21.0s - 24.5s: Stratospheric Dive with Wingtip Plasma Trails
            -- 24.5s - 27.5s: Ground Flare, Downwash Shockwave, Celestial Roar, Helical Fire!
            -----------------------------------------------------------------
            elseif elapsed < 27.5 then
                local liveChar = LocalPlayer and LocalPlayer.Character or char
                local liveHrp = liveChar and (liveChar:FindFirstChild("HumanoidRootPart") or liveChar:FindFirstChild("Torso") or liveChar:FindFirstChildWhichIsA("BasePart"))
                local currentHrpPos = liveHrp and liveHrp.Position or targetPos

                -- High-altitude hover target: Y + 38.0 studs above player feet!
                local besidePlayerPos = currentHrpPos + rightVec * 28.0 + lookVec * 8.0 + Vector3.new(0, 38.0, 0)

                -- Keep persistent supernova rings coasting
                local pCoast = (elapsed - 21.0) / 6.5
                local coastRadA = 1050 + pCoast * 350
                for i, seg in ipairs(skyAccretionRingA) do
                    local a0 = (i - 1) * (math.pi * 2 / SKY_RING_SEGS)
                    local a1 = i * (math.pi * 2 / SKY_RING_SEGS)
                    local p0 = skyDetonationPos + Vector3.new(math.cos(a0) * coastRadA, 0, math.sin(a0) * coastRadA)
                    local p1 = skyDetonationPos + Vector3.new(math.cos(a1) * coastRadA, 0, math.sin(a1) * coastRadA)
                    local chordLen = (p1 - p0).Magnitude
                    seg.Size = Vector3.new(0.6, 0.8, chordLen)
                    seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
                    seg.Color = rainbowColor(i / SKY_RING_SEGS + elapsed * 0.3, 0.35)
                    seg.Transparency = math.clamp(0.80 + pCoast * 0.20, 0.80, 1.0)
                end
                for _, seg in ipairs(skyAccretionRingB) do
                    seg.Transparency = math.clamp(0.85 + pCoast * 0.15, 0.85, 1.0)
                end
                for _, seg in ipairs(skyAccretionRingC) do
                    seg.Transparency = math.clamp(0.85 + pCoast * 0.15, 0.85, 1.0)
                end
                for _, rayData in ipairs(supernovaRays) do rayData.part.Transparency = 1 end
                for _, bData in ipairs(blastShards) do bData.part.Transparency = 1 end

                -- Phase A (21.0s - 24.5s): Hypersonic Stratospheric Soar
                if elapsed < 24.5 then
                    local pDive = (elapsed - 21.0) / 3.5
                    local easeDive = pDive * pDive * (3 - 2 * pDive)

                    local soarStart = skyDetonationPos + lookVec * 110.0 + Vector3.new(0, 120, 0)
                    local soarMid = centerRitualPos + lookVec * 45.0 + rightVec * -15.0 + Vector3.new(0, 60.0, 0)
                    local curDPos = soarStart:Lerp(soarMid, easeDive)

                    local baseCF = CFrame.lookAt(curDPos, curDPos + (soarMid - soarStart).Unit * 50)
                    local bankAngle = math.sin(elapsed * 4) * 0.22
                    local pitchAngle = math.rad(6)
                    dragonBody.CFrame = baseCF * CFrame.Angles(pitchAngle, 0, bankAngle)
                    dragonBody.Transparency = math.clamp(1 - pDive * 2.5, 0.05, 1)

                    -- Activate Wingtip Re-entry Plasma Trails
                    wingPlasmaLeft.Rate = 45
                    wingPlasmaRight.Rate = 45

                    -- Dorsal Spines
                    for _, sData in ipairs(dragonSpines) do
                        sData.part.CFrame = baseCF * CFrame.new(0, sData.yOffset, sData.zOffset) * CFrame.Angles(math.rad(25), 0, 0)
                        sData.part.Transparency = math.clamp(1 - pDive * 2.5, 0.15, 1)
                        sData.part.Color = rainbowColor(sData.index / 6 + elapsed * 0.35, 0.45)
                    end

                    -- 16 Escorts in Aerodynamic Delta Formation
                    for _, eData in ipairs(dragonEscortCrystals) do
                        local orbitAngle = elapsed * 5.0 + eData.basePhase
                        local ePos = curDPos + baseCF.RightVector * (math.cos(orbitAngle) * eData.orbitRadius) + baseCF.UpVector * (math.sin(orbitAngle) * eData.orbitRadius) + baseCF.LookVector * eData.axialOffset
                        eData.part.CFrame = CFrame.new(ePos) * CFrame.Angles(elapsed * 4, orbitAngle, 0)
                        eData.part.Transparency = math.clamp(1 - pDive * 2.0, 0.05, 1)
                        eData.part.Color = rainbowColor(eData.index / ESCORT_COUNT + elapsed * 0.4, 0.45)
                    end

                    shakeIntensity = 1.6 * (1 - pDive * 0.3)

                    local camPos = currentHrpPos - lookVec * 65.0 + Vector3.new(0, 24, 0)
                    cam.CFrame = CFrame.lookAt(camPos, curDPos)
                    cam.FieldOfView = 85

                -- Phase B (24.5s - 27.5s): Ground Deceleration Flare & Touchdown Shockwave!
                else
                    local pSettle = (elapsed - 24.5) / 3.0
                    local easeSettle = pSettle * pSettle * (3 - 2 * pSettle)

                    -- Fade out wing plasma
                    wingPlasmaLeft.Rate = 0
                    wingPlasmaRight.Rate = 0

                    local soarMid = centerRitualPos + lookVec * 45.0 + rightVec * -15.0 + Vector3.new(0, 60.0, 0)
                    local curDPos = soarMid:Lerp(besidePlayerPos, easeSettle)

                    -- Celestial Roar & Multi-Layer Downwash Shockwaves on arrival!
                    if not didLandingRoar and pSettle > 0.4 then
                        didLandingRoar = true
                        pcall(function() celestialRoarSound:Play() end)
                        downwashMist:Emit(80)
                        downwashSparks:Emit(100)
                        downwashGlints:Emit(50)

                        flashFrame.BackgroundColor3 = Color3.fromRGB(240, 220, 255)
                        flashFrame.BackgroundTransparency = 0.40
                        uiTween(flashFrame, 0.5, { BackgroundTransparency = 1 })
                    end

                    local targetLook = currentHrpPos + currentHrpPos.Unit * 45 + Vector3.new(0, 18, 0)
                    local baseCF = CFrame.lookAt(curDPos, targetLook)
                    local bankAngle = math.sin((1 - pSettle) * math.pi) * 0.25
                    local pitchAngle = math.rad(10) + math.sin(elapsed * 3.0) * (0.05 * (1 - easeSettle * 0.5))
                    dragonBody.CFrame = baseCF * CFrame.Angles(pitchAngle, 0, bankAngle)
                    dragonBody.Transparency = 0.05

                    -- Dorsal Spines
                    for _, sData in ipairs(dragonSpines) do
                        sData.part.CFrame = baseCF * CFrame.new(0, sData.yOffset, sData.zOffset) * CFrame.Angles(math.rad(25), 0, 0)
                        sData.part.Transparency = 0.15
                        sData.part.Color = rainbowColor(sData.index / 6 + elapsed * 0.35, 0.45)
                    end

                    -- Escort crystals settle into orbital guardian halo
                    for _, eData in ipairs(dragonEscortCrystals) do
                        local orbitAngle = elapsed * 3.0 + eData.basePhase
                        local ePos = curDPos + baseCF.RightVector * (math.cos(orbitAngle) * (eData.orbitRadius + 4)) + baseCF.UpVector * (math.sin(orbitAngle) * (eData.orbitRadius + 4)) + baseCF.LookVector * (eData.axialOffset * 0.5)
                        eData.part.CFrame = CFrame.new(ePos) * CFrame.Angles(elapsed * 3, orbitAngle, 0)
                        eData.part.Transparency = math.clamp(0.1 + (1 - easeSettle) * 0.4, 0.1, 0.9)
                        eData.part.Color = rainbowColor(eData.index / ESCORT_COUNT + elapsed * 0.3, 0.45)
                    end

                    shakeIntensity = 2.0 * (1 - pSettle)

                    -- Low-Angle Hero Shot framing the majestic dragon flaring its wings above player
                    local camAngle = math.rad(-30) + pSettle * math.rad(45)
                    local camDist = 85.0 - pSettle * 20.0
                    local camHeight = 16.0 + pSettle * 10.0
                    local camPos = currentHrpPos + Vector3.new(math.sin(camAngle) * camDist, camHeight, math.cos(camAngle) * camDist)
                    local lookCenter = (currentHrpPos + besidePlayerPos) / 2 + Vector3.new(0, 8.0, 0)
                    cam.CFrame = CFrame.lookAt(camPos, lookCenter)
                    cam.FieldOfView = 84
                end

            -----------------------------------------------------------------
            -- ACT V (27.5s - 34.0s): TITAN GUARDIAN CEREMONY & SEAMLESS HAND-OFF (6.5s)
            -- Double-Helix Escort Ascension + 360-Deg Orbit Camera + Smooth 2.5s Hand-Off
            -----------------------------------------------------------------
            else
                local liveChar = LocalPlayer and LocalPlayer.Character or char
                local liveHrp = liveChar and (liveChar:FindFirstChild("HumanoidRootPart") or liveChar:FindFirstChild("Torso") or liveChar:FindFirstChildWhichIsA("BasePart"))
                local currentHrpPos = liveHrp and liveHrp.Position or targetPos

                -- Permanent companion station at Y + 38.0 studs above player feet
                local companionPos = currentHrpPos + rightVec * 28.0 + lookVec * 8.0 + Vector3.new(0, 38.0 + math.sin(elapsed * 2.2) * 1.8, 0)
                local targetLook = currentHrpPos + currentHrpPos.Unit * 45 + Vector3.new(0, 18, 0)
                local baseCF = CFrame.lookAt(companionPos, targetLook)
                local bankAngle = math.sin(elapsed * 1.8) * 0.06
                local pitchAngle = math.rad(10) + math.cos(elapsed * 2.2) * 0.04
                dragonBody.CFrame = baseCF * CFrame.Angles(pitchAngle, 0, bankAngle)
                dragonBody.Transparency = 0.05

                -- Dorsal Spines
                for _, sData in ipairs(dragonSpines) do
                    sData.part.CFrame = baseCF * CFrame.new(0, sData.yOffset, sData.zOffset) * CFrame.Angles(math.rad(25), 0, 0)
                    sData.part.Transparency = 0.15
                    sData.part.Color = rainbowColor(sData.index / 6 + elapsed * 0.25, 0.4)
                end

                -- 4 Orbiting Familiar Crystals remain in permanent orbit
                for idx = 1, 4 do
                    local eData = dragonEscortCrystals[idx]
                    if eData and eData.part then
                        local eAng = elapsed * 2.5 + (idx / 4) * math.pi * 2
                        local ePos = companionPos + Vector3.new(math.cos(eAng) * 20.0, math.sin(elapsed * 3.0 + idx) * 2.5, math.sin(eAng) * 20.0)
                        eData.part.CFrame = CFrame.new(ePos) * CFrame.Angles(now * 3, eAng, 0)
                        eData.part.Transparency = 0.15
                        eData.part.Color = rainbowColor(idx / 4 + elapsed * 0.2, 0.4)
                    end
                end

                -- 12 Escort Crystals execute a Double-Helix DNA spiral ascent into stratosphere!
                local pAscend = math.clamp((elapsed - 27.5) / 5.0, 0, 1)
                for idx = 5, ESCORT_COUNT do
                    local eData = dragonEscortCrystals[idx]
                    if eData and eData.part then
                        local strandSign = (idx % 2 == 0) and 1 or -1
                        local aAng = elapsed * 4.5 + eData.basePhase * strandSign
                        local aRad = 22.0 + pAscend * 75.0
                        local aY = pAscend * 380.0
                        local ePos = companionPos + Vector3.new(math.cos(aAng) * aRad, aY, math.sin(aAng) * aRad)
                        eData.part.CFrame = CFrame.new(ePos) * CFrame.Angles(elapsed * 6, aAng, 0)
                        eData.part.Transparency = math.clamp(0.15 + pAscend * 0.85, 0.15, 1.0)
                    end
                end

                -- Smooth Lighting Restoration during final 2.5s (31.5s - 34.0s)
                if elapsed >= 31.5 then
                    local pLightBack = (elapsed - 31.5) / 2.5
                    Lighting.ClockTime = (14.0):Lerp(oldClockTime, pLightBack)
                    Lighting.Brightness = (2.2):Lerp(oldBrightness, pLightBack)
                    Lighting.Ambient = Color3.fromRGB(140, 110, 155):Lerp(oldAmbient, pLightBack)
                    Lighting.OutdoorAmbient = Color3.fromRGB(155, 120, 175):Lerp(oldOutdoorAmbient, pLightBack)
                    Lighting.FogEnd = (10000):Lerp(oldFogEnd, pLightBack)
                    Lighting.FogColor = Color3.fromRGB(235, 210, 255):Lerp(oldFogColor, pLightBack)

                    bloom.Intensity = (1.3):Lerp(0, pLightBack)
                    colorCorrection.Contrast = (0.18):Lerp(0, pLightBack)
                    colorCorrection.Brightness = (0.05):Lerp(0, pLightBack)
                end

                -- Smooth Camera Hand-Off (32.0s - 34.0s)
                if elapsed < 32.0 then
                    -- 360-Degree Hero Orbit Camera
                    local orbitAng = (elapsed - 27.5) * 0.45 - math.pi * 0.2
                    local camDist = 65.0
                    local camHeight = 14.0 + math.sin((elapsed - 27.5) * 1.5) * 4.0
                    local camPos = currentHrpPos + Vector3.new(math.sin(orbitAng) * camDist, camHeight, math.cos(orbitAng) * camDist)
                    local lookCenter = (currentHrpPos + companionPos) / 2 + Vector3.new(0, 6.0, 0)
                    cam.CFrame = CFrame.lookAt(camPos, lookCenter)
                    cam.FieldOfView = 82
                else
                    -- Seamless Interpolation from Orbit Shot into Player Third-Person View!
                    local pCamBack = (elapsed - 32.0) / 2.0
                    local easeCam = pCamBack * pCamBack * (3 - 2 * pCamBack)

                    local lastOrbitAng = (32.0 - 27.5) * 0.45 - math.pi * 0.2
                    local startPos = currentHrpPos + Vector3.new(math.sin(lastOrbitAng) * 65.0, 14.0, math.cos(lastOrbitAng) * 65.0)
                    local startFocus = (currentHrpPos + companionPos) / 2 + Vector3.new(0, 6.0, 0)
                    local startCF = CFrame.lookAt(startPos, startFocus)

                    local normalCamPos = currentHrpPos - liveHrp.CFrame.LookVector * 18 + Vector3.new(0, 5.0, 0)
                    local normalFocus = currentHrpPos + Vector3.new(0, 1.8, 0)
                    local targetCF = CFrame.lookAt(normalCamPos, normalFocus)

                    cam.CFrame = startCF:Lerp(targetCF, easeCam)
                    cam.FieldOfView = (82):Lerp(oldCameraFOV, easeCam)
                end
            end

            -- Camera shake application
            if shakeIntensity > 0.02 then
                local sX = (math.random() - 0.5) * 2 * shakeIntensity * 0.18
                local sY = (math.random() - 0.5) * 2 * shakeIntensity * 0.18
                local sZ = (math.random() - 0.5) * 2 * shakeIntensity * 0.18
                cam.CFrame = cam.CFrame * CFrame.Angles(sX * 0.02, sY * 0.02, sZ * 0.02) + Vector3.new(sX, sY, sZ)
            end
        end)

        if not stepOk then
            -- Fallback protection
        end
    end)
end


-- ============================================================================
-- TRANSCENDENCE API & 3D DRAGON FLIGHT CONTROLLER
-- ============================================================================

function Transcendence.play(onComplete)
    if Transcendence.IsPlaying then return end
    Transcendence.IsPlaying = true
    playCinematicIntro(function()
        Transcendence.IsPlaying = false
        if onComplete then onComplete() end
    end)
end

function Transcendence.spawnDirect()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChildWhichIsA("BasePart")
    if not hrp then return end

    local companionFolder = Workspace:FindFirstChild("Destiny_DragonCompanion")
    if companionFolder then companionFolder:Destroy() end
    companionFolder = Instance.new("Folder")
    companionFolder.Name = "Destiny_DragonCompanion"
    companionFolder.Parent = Workspace
    Transcendence.DragonFolder = companionFolder

    local dragonBody = Instance.new("Part")
    dragonBody.Name = "CelestialTitanDragon"
    dragonBody.Size = Vector3.new(12, 10, 36)
    dragonBody.Material = Enum.Material.SmoothPlastic
    dragonBody.Color = Color3.fromRGB(255, 255, 255)
    dragonBody.Transparency = 0.05
    dragonBody.CanCollide = false
    dragonBody.Anchored = true
    dragonBody.CFrame = hrp.CFrame * CFrame.new(28, 38, 8)
    dragonBody.Parent = companionFolder
    Transcendence.DragonBody = dragonBody

    local dragonMesh = Instance.new("SpecialMesh")
    dragonMesh.MeshType = Enum.MeshType.FileMesh
    dragonMesh.MeshId = MESH_DRAGON
    dragonMesh.TextureId = TEX_DRAGON
    dragonMesh.Scale = Vector3.new(36, 36, 36)
    dragonMesh.Parent = dragonBody

    local dragonHeadLight = Instance.new("PointLight")
    dragonHeadLight.Range = 40
    dragonHeadLight.Brightness = 2.4
    dragonHeadLight.Parent = dragonBody

    local saddle = Instance.new("Seat")
    saddle.Name = "DragonSaddle"
    saddle.Size = Vector3.new(2, 1, 2)
    saddle.Transparency = 1
    saddle.CanCollide = false
    saddle.Anchored = false
    saddle.Parent = companionFolder

    local saddleWeld = Instance.new("WeldConstraint")
    saddleWeld.Part0 = dragonBody
    saddleWeld.Part1 = saddle
    saddleWeld.Parent = saddle
    saddle.CFrame = dragonBody.CFrame * CFrame.new(0, 3.8, -1.0)
    Transcendence.DragonSaddle = saddle

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "DragonMountPrompt"
    prompt.ActionText = "Ride Celestial Dragon"
    prompt.ObjectText = "Titan Companion"
    prompt.MaxActivationDistance = 45
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    prompt.Parent = dragonBody

    prompt.Triggered:Connect(function(plr)
        if plr == LocalPlayer then
            Transcendence.mount()
        end
    end)

    local dragonSpines = {}
    for sp = 1, 6 do
        local spinePart = Instance.new("Part")
        spinePart.Name = "DragonDorsalSpine_" .. sp
        spinePart.Material = Enum.Material.Neon
        spinePart.Color = rainbowColor(sp / 6, 0.35)
        spinePart.Size = Vector3.new(1, 1, 1)
        spinePart.Transparency = 0.15
        spinePart.CanCollide = false
        spinePart.Anchored = true
        spinePart.Parent = companionFolder

        local smSpine = Instance.new("SpecialMesh")
        smSpine.MeshType = Enum.MeshType.FileMesh
        smSpine.MeshId = MESH_DIAMOND
        smSpine.Scale = Vector3.new(1.4, 4.0, 1.4)
        smSpine.Parent = spinePart

        table.insert(dragonSpines, {
            part = spinePart,
            zOffset = ((sp / 6) - 0.5) * 24.0,
            yOffset = 4.2 + (sp % 2) * 0.8,
            index = sp
        })
    end
    Transcendence.DragonSpines = dragonSpines

    local dragonEscortCrystals = {}
    for idx = 1, 4 do
        local ePart = Instance.new("Part")
        ePart.Name = "DragonEscortCrystal_" .. idx
        ePart.Material = Enum.Material.Neon
        ePart.Color = rainbowColor(idx / 4, 0.4)
        ePart.Size = Vector3.new(2.4, 5.2, 2.4)
        ePart.Transparency = 0.15
        ePart.CanCollide = false
        ePart.Anchored = true
        ePart.Parent = companionFolder

        local smEscort = Instance.new("SpecialMesh")
        smEscort.MeshType = Enum.MeshType.FileMesh
        smEscort.MeshId = MESH_DIAMOND
        smEscort.Scale = Vector3.new(2.2, 4.8, 2.2)
        smEscort.Parent = ePart

        table.insert(dragonEscortCrystals, {
            part = ePart,
            index = idx
        })
    end
    Transcendence.DragonEscorts = dragonEscortCrystals

    -- Follow Loop
    task.spawn(function()
        local companionConn = nil
        companionConn = RunService.Heartbeat:Connect(function()
            local cChar = LocalPlayer and LocalPlayer.Character or char
            local cHrp = cChar and (cChar:FindFirstChild("HumanoidRootPart") or cChar:FindFirstChild("Torso") or cChar:FindFirstChildWhichIsA("BasePart"))
            if not cHrp or not companionFolder or not companionFolder.Parent then
                if companionConn then companionConn:Disconnect() end
                return
            end

            if Transcendence.IsRiding then return end

            local now = tick()
            local targetFollowPos = cHrp.Position + cHrp.CFrame.RightVector * 28 + cHrp.CFrame.LookVector * 8 + Vector3.new(0, 38.0 + math.sin(now * 2.2) * 1.8, 0)
            local bodyPos = dragonBody.Position:Lerp(targetFollowPos, 0.08)

            local targetLook = cHrp.Position + cHrp.CFrame.LookVector * 65 + Vector3.new(0, 15, 0)
            local baseCF = CFrame.lookAt(bodyPos, targetLook)
            local bankAngle = math.sin(now * 1.8) * 0.06
            local pitchAngle = math.rad(10) + math.cos(now * 2.2) * 0.04
            dragonBody.CFrame = baseCF * CFrame.Angles(pitchAngle, 0, bankAngle)
            dragonBody.Transparency = 0.05

            for _, sData in ipairs(dragonSpines) do
                if sData.part then
                    sData.part.CFrame = baseCF * CFrame.new(0, sData.yOffset, sData.zOffset) * CFrame.Angles(math.rad(25), 0, 0)
                    sData.part.Transparency = 0.15
                    sData.part.Color = rainbowColor(sData.index / 6 + now * 0.25, 0.4)
                end
            end

            for idx = 1, 4 do
                local eData = dragonEscortCrystals[idx]
                if eData and eData.part then
                    local eAng = now * 2.5 + (idx / 4) * math.pi * 2
                    local ePos = bodyPos + Vector3.new(math.cos(eAng) * 20.0, math.sin(now * 3.0 + idx) * 2.5, math.sin(eAng) * 20.0)
                    eData.part.CFrame = CFrame.new(ePos) * CFrame.Angles(now * 3, eAng, 0)
                    eData.part.Transparency = 0.15
                    eData.part.Color = rainbowColor(idx / 4 + now * 0.2, 0.4)
                end
            end
        end)
    end)
end

function Transcendence.startFlightController()
    if Transcendence.FlightConn then
        pcall(function() Transcendence.FlightConn:Disconnect() end)
        Transcendence.FlightConn = nil
    end

    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    Transcendence.FlightConn = RunService.RenderStepped:Connect(function(dt)
        if not Transcendence.IsRiding then return end
        local dragonBody = Transcendence.DragonBody
        local saddle = Transcendence.DragonSaddle
        if not dragonBody or not dragonBody.Parent or not saddle or not saddle.Parent then
            Transcendence.dismount()
            return
        end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or saddle.Occupant ~= hum then
            Transcendence.dismount()
            return
        end

        local cam = Workspace.CurrentCamera
        local camCF = cam.CFrame

        -- 3D Navigation (Unified for Mobile thumbstick & PC WASD)
        local moveDir = Vector3.new(0, 0, 0)
        local m = hum.MoveDirection
        if m.Magnitude > 0 then
            local fwd = m:Dot(camCF.LookVector)
            local rgt = m:Dot(camCF.RightVector)
            moveDir = (camCF.LookVector * fwd + camCF.RightVector * rgt)
        end

        -- Direct PC inputs
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        local speed = 140
        local targetPos = dragonBody.Position
        local targetLook = dragonBody.Position + dragonBody.CFrame.LookVector * 10

        if moveDir.Magnitude > 0 then
            local normDir = moveDir.Unit
            targetPos = dragonBody.Position + normDir * (speed * dt)
            targetLook = targetPos + normDir * 20
        else
            targetPos = dragonBody.Position + Vector3.new(0, math.sin(tick() * 3) * 0.1, 0)
        end

        local bankAngle = 0
        if moveDir.Magnitude > 0 then
            local rgt = camCF.RightVector
            local turnAmount = moveDir:Dot(rgt)
            bankAngle = -turnAmount * 0.35
        end

        local baseCF = CFrame.lookAt(targetPos, targetLook) * CFrame.Angles(0, 0, bankAngle)
        dragonBody.CFrame = baseCF
        dragonBody.Transparency = 0.05

        -- Keep character comfortably seated
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.Seated)

        -- Spines & Crystals update
        local now = tick()
        for _, sData in ipairs(Transcendence.DragonSpines) do
            if sData.part and sData.part.Parent then
                sData.part.CFrame = baseCF * CFrame.new(0, sData.yOffset, sData.zOffset) * CFrame.Angles(math.rad(25), 0, 0)
                sData.part.Transparency = 0.15
                sData.part.Color = rainbowColor(sData.index / 6 + now * 0.25, 0.4)
            end
        end

        for idx = 1, 4 do
            local eData = Transcendence.DragonEscorts[idx]
            if eData and eData.part and eData.part.Parent then
                local eAng = now * 2.5 + (idx / 4) * math.pi * 2
                local ePos = targetPos + Vector3.new(math.cos(eAng) * 20.0, math.sin(now * 3.0 + idx) * 2.5, math.sin(eAng) * 20.0)
                eData.part.CFrame = CFrame.new(ePos) * CFrame.Angles(now * 3, eAng, 0)
                eData.part.Transparency = 0.15
                eData.part.Color = rainbowColor(idx / 4 + now * 0.2, 0.4)
            end
        end
    end)
end

function Transcendence.mount()
    local char = LocalPlayer and LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not char or not hum or not hrp then return false end

    if not Transcendence.DragonBody or not Transcendence.DragonBody.Parent then
        Transcendence.spawnDirect()
        task.wait(0.2)
    end

    local saddle = Transcendence.DragonSaddle
    if not saddle or not saddle.Parent then return false end

    Transcendence.IsRiding = true
    hrp.CFrame = saddle.CFrame * CFrame.new(0, 1.5, 0)
    task.wait(0.05)
    saddle:Sit(hum)

    Transcendence.startFlightController()
    return true
end

function Transcendence.dismount()
    Transcendence.IsRiding = false
    if Transcendence.FlightConn then
        pcall(function() Transcendence.FlightConn:Disconnect() end)
        Transcendence.FlightConn = nil
    end

    local char = LocalPlayer and LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if hum then
        hum.Sit = false
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    if hrp and Transcendence.DragonBody and Transcendence.DragonBody.Parent then
        hrp.CFrame = Transcendence.DragonBody.CFrame * CFrame.new(0, 8, 12)
    end
end

function Transcendence.toggleMount()
    if Transcendence.IsRiding then
        Transcendence.dismount()
        return false
    else
        return Transcendence.mount()
    end
end

return Transcendence
