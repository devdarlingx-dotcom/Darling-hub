-- ========================================================================
-- Darling Hub - Combat Tracers
-- Hardware 3D Beam + 2D Body-to-Body SnapLines (Nameless & Spooky Engine)
-- ========================================================================

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Tracers = {}
local Core = nil

local function getCore()
    if Core then return Core end
    local env = (getgenv and getgenv()) or _G
    if env.DarlingCombatCore then
        Core = env.DarlingCombatCore
        return Core
    end
    if _G.DarlingCombatCore then
        Core = _G.DarlingCombatCore
        return Core
    end
    local hub = env.DarlingHub or _G.DarlingHub
    if hub and hub.Require then
        local ok, res = pcall(function()
            return hub:Require("modules/combat/aimbot_core.lua")
        end)
        if ok and res then
            Core = res
            env.DarlingCombatCore = Core
            _G.DarlingCombatCore = Core
            return Core
        end
    end
    for _, p in ipairs({ "modules/combat/aimbot_core.lua", "darling-hub/modules/combat/aimbot_core.lua" }) do
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

local isEnabled = false
local renderConnection = nil

-- Configuration State
local tracerSettings = {
    Type = "3D Beam", -- "3D Beam", "2D Line", "Both"
    Origin = "Player", -- "Player", "Bottom", "Center"
    Color = Color3.fromRGB(255, 255, 255),
    Thickness = 1.5,
    BeamWidth = 0.25,
}

-- 3D Hardware Beam References (Terrain-anchored like Project Spooky & Nameless)
local tracerBeam = nil
local tracerAtt0 = nil
local tracerAtt1 = nil

local function getOrCreateTracerBeam()
    if tracerBeam and tracerBeam.Parent and tracerAtt0 and tracerAtt0.Parent and tracerAtt1 and tracerAtt1.Parent then
        return tracerBeam
    end
    pcall(function()
        local parentObj = Workspace:FindFirstChildOfClass("Terrain") or Workspace
        if not tracerAtt0 or not tracerAtt0.Parent then
            tracerAtt0 = Instance.new("Attachment")
            tracerAtt0.Name = "DarlingTracer_Att0"
            tracerAtt0.Parent = parentObj
        end
        if not tracerAtt1 or not tracerAtt1.Parent then
            tracerAtt1 = Instance.new("Attachment")
            tracerAtt1.Name = "DarlingTracer_Att1"
            tracerAtt1.Parent = parentObj
        end
        if not tracerBeam or not tracerBeam.Parent then
            tracerBeam = Instance.new("Beam")
            tracerBeam.Name = "DarlingTracer_Beam"
            tracerBeam.Attachment0 = tracerAtt0
            tracerBeam.Attachment1 = tracerAtt1
            tracerBeam.FaceCamera = true
            tracerBeam.Width0 = tracerSettings.BeamWidth or 0.25
            tracerBeam.Width1 = tracerSettings.BeamWidth or 0.25
            tracerBeam.Segments = 1
            tracerBeam.Color = ColorSequence.new(tracerSettings.Color or Color3.fromRGB(255, 255, 255))
            tracerBeam.Transparency = NumberSequence.new(0.05)
            tracerBeam.Enabled = false
            tracerBeam.Parent = parentObj
        end
    end)
    return tracerBeam
end

local function destroyTracerBeam()
    pcall(function()
        if tracerBeam then tracerBeam:Destroy(); tracerBeam = nil end
        if tracerAtt0 then tracerAtt0:Destroy(); tracerAtt0 = nil end
        if tracerAtt1 then tracerAtt1:Destroy(); tracerAtt1 = nil end
    end)
end

-- 2D ScreenGui Elements
local overlayGui = nil
local guiLine = nil

-- 2D Drawing API
local drawingLine = nil
local hasDrawing = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")

local function getOverlayGui()
    if overlayGui and overlayGui.Parent then return overlayGui end
    local env = (getgenv and getgenv()) or _G
    local hub = env.DarlingHub or _G.DarlingHub
    if hub and hub.GetOverlay then
        local ok, g = pcall(function() return hub:GetOverlay() end)
        if ok and g then
            overlayGui = g
            return overlayGui
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "DarlingHub_Tracers_Overlay"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483000
    pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    local parented = false
    if gethui then parented = pcall(function() gui.Parent = gethui() end) end
    if not parented then parented = pcall(function() gui.Parent = CoreGui end) end
    if not parented and LocalPlayer then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    overlayGui = gui
    return overlayGui
end

local function ensureGuiLine()
    if guiLine and guiLine.Parent then return guiLine end
    local overlay = getOverlayGui()
    if not overlay then return nil end

    local line = Instance.new("Frame")
    line.Name = "TracerLine"
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = tracerSettings.Color or Color3.fromRGB(255, 255, 255)
    line.Visible = false
    line.Parent = overlay

    guiLine = line
    return guiLine
end

local function ensureDrawingLine()
    if not hasDrawing then return nil end
    if drawingLine then return drawingLine end
    local ok, l = pcall(function()
        local line = Drawing.new("Line")
        line.Thickness = tracerSettings.Thickness or 1.5
        line.Transparency = 1
        line.Color = tracerSettings.Color or Color3.fromRGB(255, 255, 255)
        line.Visible = false
        return line
    end)
    if ok and l then
        drawingLine = l
        return drawingLine
    end
    return nil
end

-- Helper: resolve exact torso center position of any character model
local function resolveTorsoPosition(part)
    if not part or not part.Parent then return nil end
    local model = part.Parent
    if model:IsA("Accessory") and model.Parent then
        model = model.Parent
    end
    local torso = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("LowerTorso")
        or part
    return torso.Position
end

-- Helper: resolve local player torso center position
local function getMyTorsoPosition()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil end
    local torso = char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
    return torso and torso.Position
end

local function hideAllTracers()
    if tracerBeam then tracerBeam.Enabled = false end
    if drawingLine then drawingLine.Visible = false end
    if guiLine then guiLine.Visible = false end
end

local function onRender()
    if not isEnabled then
        hideAllTracers()
        return
    end

    local core = getCore()
    local globalSettings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Tracers)
        or (core and core.Tracers)
    if globalSettings then
        if globalSettings.Color then tracerSettings.Color = globalSettings.Color end
        if globalSettings.Thickness then tracerSettings.Thickness = globalSettings.Thickness end
        if globalSettings.Type then tracerSettings.Type = globalSettings.Type end
        if globalSettings.Origin then tracerSettings.Origin = globalSettings.Origin end
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        hideAllTracers()
        return
    end

    local myTorsoPos = getMyTorsoPosition()
    local targetPos = nil

    if core then
        local activePart = core.CurrentTargetPart
        if activePart and activePart.Parent then
            targetPos = resolveTorsoPosition(activePart)
        elseif core.resolveAnyTarget then
            local part = core.resolveAnyTarget()
            if part and part.Parent then
                targetPos = resolveTorsoPosition(part)
            end
        end
    end

    if not targetPos then
        hideAllTracers()
        return
    end

    local color = tracerSettings.Color or Color3.fromRGB(255, 255, 255)
    local thickness = tracerSettings.Thickness or 1.5
    local currentType = tracerSettings.Type or "3D Beam"

    -- ====================================================================
    -- 1. HARDWARE 3D BEAM TRACER (Physical world-space body-to-body link)
    -- ====================================================================
    local beamActive = false
    if currentType == "3D Beam" or currentType == "Both" then
        if myTorsoPos and targetPos then
            local beam = getOrCreateTracerBeam()
            if beam and tracerAtt0 and tracerAtt1 then
                pcall(function()
                    tracerAtt0.WorldPosition = myTorsoPos
                    tracerAtt1.WorldPosition = targetPos
                    beam.Color = ColorSequence.new(color)
                    beam.Width0 = math.clamp(thickness * 0.15, 0.1, 1.0)
                    beam.Width1 = math.clamp(thickness * 0.15, 0.1, 1.0)
                    beam.Enabled = true
                    beamActive = true
                end)
            end
        end
    end
    if not beamActive and tracerBeam then
        tracerBeam.Enabled = false
    end

    -- ====================================================================
    -- 2. 2D SCREEN SNAPLINE (Drawing API or ScreenGui fallback)
    -- ====================================================================
    if currentType == "2D Line" or currentType == "Both" then
        local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
        local vp = camera.ViewportSize

        if not onScreen or screenPos.Z <= 0 then
            if drawingLine then drawingLine.Visible = false end
            if guiLine then guiLine.Visible = false end
            return
        end

        local toPos = Vector2.new(screenPos.X, screenPos.Y)
        local fromPos = nil

        local originMode = tracerSettings.Origin or "Player"
        if originMode == "Player" then
            if myTorsoPos then
                local myScreenPos, myOnScreen = camera:WorldToViewportPoint(myTorsoPos)
                if myOnScreen and myScreenPos.Z > 0 then
                    fromPos = Vector2.new(myScreenPos.X, myScreenPos.Y)
                else
                    fromPos = Vector2.new(vp.X * 0.5, vp.Y)
                end
            else
                fromPos = Vector2.new(vp.X * 0.5, vp.Y)
            end
        elseif originMode == "Bottom" then
            fromPos = Vector2.new(vp.X * 0.5, vp.Y)
        else
            fromPos = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        end

        if hasDrawing then
            local line = ensureDrawingLine()
            if line then
                line.From = fromPos
                line.To = toPos
                line.Color = color
                line.Thickness = thickness
                line.Visible = true
            end
            if guiLine then guiLine.Visible = false end
        else
            local line = ensureGuiLine()
            if line then
                local delta = toPos - fromPos
                local dist = delta.Magnitude
                local angle = math.atan2(delta.Y, delta.X)

                line.AnchorPoint = Vector2.new(0.5, 0.5)
                line.Size = UDim2.fromOffset(dist, thickness)
                line.Position = UDim2.fromOffset((fromPos.X + toPos.X) * 0.5, (fromPos.Y + toPos.Y) * 0.5)
                line.Rotation = math.deg(angle)
                line.BackgroundColor3 = color
                line.Visible = true
            end
            if drawingLine then drawingLine.Visible = false end
        end
    else
        if drawingLine then drawingLine.Visible = false end
        if guiLine then guiLine.Visible = false end
    end
end

function Tracers.enable()
    isEnabled = true
    local core = getCore()
    if core and core.Tracers then core.Tracers.Visible = true end

    getOrCreateTracerBeam()
    if hasDrawing then
        ensureDrawingLine()
    else
        ensureGuiLine()
    end

    if not renderConnection then
        renderConnection = RunService.RenderStepped:Connect(onRender)
    end
    return true
end

function Tracers.disable()
    isEnabled = false
    local core = getCore()
    if core then core.Tracers.Visible = false end

    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end

    hideAllTracers()
end

function Tracers.setVisible(state)
    if state then Tracers.enable() else Tracers.disable() end
end

function Tracers.setColor(color)
    if typeof(color) == "Color3" then
        tracerSettings.Color = color
        local core = getCore()
        if core and core.Tracers then core.Tracers.Color = color end
        if _G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Tracers then
            _G.DarlingHub.Settings.Tracers.Color = color
        end
        if tracerBeam then
            tracerBeam.Color = ColorSequence.new(color)
        end
        if drawingLine then
            drawingLine.Color = color
        end
        if guiLine then
            guiLine.BackgroundColor3 = color
        end
    end
end

function Tracers.setThickness(thickness)
    local t = tonumber(thickness) or 1.5
    tracerSettings.Thickness = t
    tracerSettings.BeamWidth = math.clamp(t * 0.15, 0.1, 1.0)
    local core = getCore()
    if core and core.Tracers then core.Tracers.Thickness = t end
    if _G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Tracers then
        _G.DarlingHub.Settings.Tracers.Thickness = t
    end
    if tracerBeam then
        tracerBeam.Width0 = tracerSettings.BeamWidth
        tracerBeam.Width1 = tracerSettings.BeamWidth
    end
    if drawingLine then
        drawingLine.Thickness = t
    end
end

function Tracers.setType(t)
    if t == "3D Beam" or t == "2D Line" or t == "Both" then
        tracerSettings.Type = t
        if _G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Tracers then
            _G.DarlingHub.Settings.Tracers.Type = t
        end
    end
end

function Tracers.setOrigin(origin)
    if origin == "Player" or origin == "Bottom" or origin == "Center" then
        tracerSettings.Origin = origin
        if _G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Tracers then
            _G.DarlingHub.Settings.Tracers.Origin = origin
        end
    end
end

function Tracers.destroy()
    Tracers.disable()
    destroyTracerBeam()
    if guiLine then
        pcall(function() guiLine:Destroy() end)
        guiLine = nil
    end
    if drawingLine then
        pcall(function() drawingLine:Remove() end)
        drawingLine = nil
    end
end

_G.DarlingTracers = Tracers
return Tracers
