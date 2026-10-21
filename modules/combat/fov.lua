--[[
    Darling Hub - FOV Circle Module
    Handles real-time rendering and configuration of the Aimbot FOV Circle.
]]--

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local FOV = {}
local Core = nil

local function getCore()
    if Core then return Core end
    if _G.DarlingCombatCore then
        Core = _G.DarlingCombatCore
        return Core
    end

    local paths = {
        "modules/combat/aimbot_core.lua",
        "darling-hub/modules/combat/aimbot_core.lua",
    }

    for _, p in ipairs(paths) do
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

local drawingCircle = nil
local renderConnection = nil
local isDrawingSupported = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")

local function getCircle()
    if drawingCircle then return drawingCircle end
    if isDrawingSupported then
        local ok, c = pcall(function()
            local circle = Drawing.new("Circle")
            circle.Thickness = 1.5
            circle.NumSides = 64
            circle.Filled = false
            circle.Transparency = 1
            circle.Color = Color3.fromRGB(255, 60, 60)
            circle.Visible = false
            return circle
        end)
        if ok and c then
            drawingCircle = c
            return drawingCircle
        end
    end
    return nil
end

local function onRender()
    local core = getCore()
    local circle = getCircle()
    if not circle or not core then return end

    if not core.FOV.Visible then
        circle.Visible = false
        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        circle.Visible = false
        return
    end

    local center = nil
    if core.FOV.Mode == "Mouse" then
        center = UserInputService:GetMouseLocation()
    else
        center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    end

    circle.Position = center
    circle.Radius = core.FOV.Radius
    circle.Color = core.FOV.Color
    circle.Thickness = core.FOV.Thickness
    circle.Visible = true
end

function FOV.setVisible(state)
    local core = getCore()
    if core then
        core.FOV.Visible = state
    end

    if state then
        getCircle()
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(onRender)
        end
    else
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        if drawingCircle then
            drawingCircle.Visible = false
        end
    end
end

function FOV.setRadius(radius)
    local core = getCore()
    if core and type(radius) == "number" then
        core.FOV.Radius = radius
        if drawingCircle then
            drawingCircle.Radius = radius
        end
    end
end

function FOV.setMode(mode)
    local core = getCore()
    if core and (mode == "Center" or mode == "Mouse") then
        core.FOV.Mode = mode
    end
end

function FOV.setColor(color)
    local core = getCore()
    if core and typeof(color) == "Color3" then
        core.FOV.Color = color
        if drawingCircle then
            drawingCircle.Color = color
        end
    end
end

function FOV.destroy()
    FOV.setVisible(false)
    if drawingCircle then
        pcall(function() drawingCircle:Remove() end)
        drawingCircle = nil
    end
end

return FOV
