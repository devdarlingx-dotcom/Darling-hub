-- fov

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local FOV = {}
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
local guiFrame = nil
local guiStroke = nil

-- Drawing API Reference
local drawingCircle = nil
local hasDrawing = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")

local function getOverlayGui()
    if overlayGui and overlayGui.Parent then return overlayGui end
    local gui = Instance.new("ScreenGui")
    gui.Name = "DarlingHub_FOV_Overlay"
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

local function ensureGuiCircle()
    if guiFrame and guiFrame.Parent then return guiFrame end
    local overlay = getOverlayGui()
    if not overlay then return nil end

    local frame = Instance.new("Frame")
    frame.Name = "FOVCircle"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = overlay

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = frame

    guiFrame = frame
    guiStroke = stroke
    return guiFrame
end

local function ensureDrawingCircle()
    if not hasDrawing then return nil end
    if drawingCircle then return drawingCircle end
    local ok, c = pcall(function()
        local circle = Drawing.new("Circle")
        circle.Thickness = 1.5
        circle.NumSides = 64
        circle.Filled = false
        circle.Transparency = 1
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Visible = false
        return circle
    end)
    if ok and c then
        drawingCircle = c
        return drawingCircle
    end
    return nil
end

local function onRender()
    if not isEnabled then return end
    local core = getCore()
    local aimSettings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Aim)
    local aimMode = (aimSettings and aimSettings.Mode) or (core and core.AimMode) or "FOV"

    -- If Aim Mode is not "FOV", do not display FOV circle
    if aimMode ~= "FOV" then
        if guiFrame then guiFrame.Visible = false end
        if drawingCircle then drawingCircle.Visible = false end
        return
    end

    local settings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.FOV)
        or (core and core.FOV)
        or { Radius = 100, Mode = "Center", Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5 }

    local camera = Workspace.CurrentCamera
    if not camera then return end

    local center = nil
    if settings.Mode == "Mouse" then
        center = UserInputService:GetMouseLocation()
    else
        center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    end

    local radius = settings.Radius or 100
    local color = settings.Color or Color3.fromRGB(255, 255, 255)
    local thickness = settings.Thickness or 1.5

    -- ScreenGui (Guaranteed visibility across all mobile and PC executors)
    local frame = ensureGuiCircle()
    if frame and guiStroke then
        frame.Position = UDim2.fromOffset(center.X, center.Y)
        frame.Size = UDim2.fromOffset(radius * 2, radius * 2)
        guiStroke.Color = color
        guiStroke.Thickness = thickness
        frame.Visible = true
    end

    -- Drawing API Circle (synced if supported)
    if hasDrawing then
        local dCircle = ensureDrawingCircle()
        if dCircle then
            dCircle.Position = center
            dCircle.Radius = radius
            dCircle.Color = color
            dCircle.Thickness = thickness
            dCircle.Visible = true
        end
    end
end

function FOV.enable()
    isEnabled = true
    local core = getCore()
    if core then core.FOV.Visible = true end

    ensureGuiCircle()
    if hasDrawing then ensureDrawingCircle() end

    if not renderConnection then
        renderConnection = RunService.RenderStepped:Connect(onRender)
    end
    return true
end

function FOV.disable()
    isEnabled = false
    local core = getCore()
    if core then core.FOV.Visible = false end

    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end

    if guiFrame then
        guiFrame.Visible = false
    end
    if drawingCircle then
        drawingCircle.Visible = false
    end
end

function FOV.setVisible(state)
    if state then FOV.enable() else FOV.disable() end
end

function FOV.setRadius(radius)
    local r = tonumber(radius) or 100
    local core = getCore()
    if core then core.FOV.Radius = r end
    if _G.DarlingHub and _G.DarlingHub.Settings then
        _G.DarlingHub.Settings.FOV.Radius = r
    end
end

function FOV.setMode(mode)
    local m = (mode == "Mouse" or mode == "Center") and mode or "Center"
    local core = getCore()
    if core then core.FOV.Mode = m end
    if _G.DarlingHub and _G.DarlingHub.Settings then
        _G.DarlingHub.Settings.FOV.Mode = m
    end
end

function FOV.setColor(color)
    local core = getCore()
    if core and typeof(color) == "Color3" then core.FOV.Color = color end
    if _G.DarlingHub and _G.DarlingHub.Settings and typeof(color) == "Color3" then
        _G.DarlingHub.Settings.FOV.Color = color
    end
end

function FOV.setThickness(thickness)
    local t = tonumber(thickness) or 1.5
    local core = getCore()
    if core then core.FOV.Thickness = t end
    if _G.DarlingHub and _G.DarlingHub.Settings then
        _G.DarlingHub.Settings.FOV.Thickness = t
    end
end

function FOV.destroy()
    FOV.disable()
    if guiFrame then
        pcall(function() guiFrame:Destroy() end)
        guiFrame = nil
    end
    if drawingCircle then
        pcall(function() drawingCircle:Remove() end)
        drawingCircle = nil
    end
end

return FOV
