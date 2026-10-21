--[[
    Darling Hub - Tracers Module (Centered Origin)
    Dual-layer line rendering starting strictly from screen center (Camera.ViewportSize / 2)
    pointing directly to the enemy part. ScreenGui ensures 100% visibility on all mobile executors.
]]--

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

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

-- ScreenGui Element References
local overlayGui = nil
local guiLine = nil

-- Drawing API Reference
local drawingLine = nil
local hasDrawing = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")

local function getOverlayGui()
    if overlayGui and overlayGui.Parent then return overlayGui end
    local gui = Instance.new("ScreenGui")
    gui.Name = "DarlingHub_Tracers_Overlay"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483000
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    local parented = false
    if gethui then parented = pcall(function() gui.Parent = gethui() end) end
    if not parented then parented = pcall(function() gui.Parent = CoreGui end) end
    if not parented then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
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
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
        line.Thickness = 1.5
        line.Transparency = 1
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Visible = false
        return line
    end)
    if ok and l then
        drawingLine = l
        return drawingLine
    end
    return nil
end

local function onRender()
    if not isEnabled then return end
    local core = getCore()
    local settings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Tracers)
        or (core and core.Tracers)
        or { Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5 }

    local camera = Workspace.CurrentCamera
    if not camera then return end

    -- Raw target position points directly to enemy part
    local targetPos = nil
    if core and core.CurrentTargetRawPosition then
        targetPos = core.CurrentTargetRawPosition
    elseif core and core.CurrentTargetPart then
        targetPos = core.CurrentTargetPart.Position
    elseif core and core.resolveAnyTarget then
        local part, _, _ = core.resolveAnyTarget()
        if part then targetPos = part.Position end
    end

    if not targetPos then
        if guiLine then guiLine.Visible = false end
        if drawingLine then drawingLine.Visible = false end
        return
    end

    local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
    if not onScreen or screenPos.Z <= 0 then
        if guiLine then guiLine.Visible = false end
        if drawingLine then drawingLine.Visible = false end
        return
    end

    -- Strictly from screen center
    local fromPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local toPos = Vector2.new(screenPos.X, screenPos.Y)
    local color = settings.Color or Color3.fromRGB(255, 255, 255)
    local thickness = settings.Thickness or 1.5

    -- ScreenGui Rotated Line (Guaranteed visible on mobile and PC)
    local line = ensureGuiLine()
    if line then
        local delta = toPos - fromPos
        local distance = delta.Magnitude
        local angle = math.atan2(delta.Y, delta.X)

        line.Size = UDim2.fromOffset(distance, thickness)
        line.Position = UDim2.fromOffset((fromPos.X + toPos.X) / 2, (fromPos.Y + toPos.Y) / 2)
        line.Rotation = math.deg(angle)
        line.BackgroundColor3 = color
        line.Visible = true
    end

    -- Drawing API Line (synced if supported)
    if hasDrawing then
        local dLine = ensureDrawingLine()
        if dLine then
            dLine.From = fromPos
            dLine.To = toPos
            dLine.Color = color
            dLine.Thickness = thickness
            dLine.Visible = true
        end
    end
end

function Tracers.enable()
    isEnabled = true
    local core = getCore()
    if core then core.Tracers.Visible = true end

    ensureGuiLine()
    if hasDrawing then ensureDrawingLine() end

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

    if guiLine then
        guiLine.Visible = false
    end
    if drawingLine then
        drawingLine.Visible = false
    end
end

function Tracers.setVisible(state)
    if state then Tracers.enable() else Tracers.disable() end
end

function Tracers.setColor(color)
    local core = getCore()
    if core and typeof(color) == "Color3" then core.Tracers.Color = color end
    if _G.DarlingHub and _G.DarlingHub.Settings and typeof(color) == "Color3" then
        _G.DarlingHub.Settings.Tracers.Color = color
    end
end

function Tracers.setThickness(thickness)
    local t = tonumber(thickness) or 1.5
    local core = getCore()
    if core then core.Tracers.Thickness = t end
    if _G.DarlingHub and _G.DarlingHub.Settings then
        _G.DarlingHub.Settings.Tracers.Thickness = t
    end
end

function Tracers.destroy()
    Tracers.disable()
    if guiLine then
        pcall(function() guiLine:Destroy() end)
        guiLine = nil
    end
    if drawingLine then
        pcall(function() drawingLine:Remove() end)
        drawingLine = nil
    end
end

return Tracers
