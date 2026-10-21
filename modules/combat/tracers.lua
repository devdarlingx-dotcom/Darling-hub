--[[
    Darling Hub - Tracers Module (Centered Origin)
    Renders targeting tracers originating strictly from the middle of the screen.
]]--

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Tracers = {}
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

local drawingLine = nil
local renderConnection = nil
local isDrawingSupported = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")

local function getLine()
    if drawingLine then return drawingLine end
    if isDrawingSupported then
        local ok, l = pcall(function()
            local line = Drawing.new("Line")
            line.Thickness = 1.5
            line.Transparency = 1
            line.Color = Color3.fromRGB(255, 50, 50)
            line.Visible = false
            return line
        end)
        if ok and l then
            drawingLine = l
            return drawingLine
        end
    end
    return nil
end

local function onRender()
    local core = getCore()
    local line = getLine()
    if not line or not core then return end

    if not core.Tracers.Visible or not core.CurrentTargetPosition then
        line.Visible = false
        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        line.Visible = false
        return
    end

    local targetPos, onScreen = camera:WorldToViewportPoint(core.CurrentTargetPosition)
    if not onScreen then
        line.Visible = false
        return
    end

    -- Strictly origin in the center of the viewport (crosshair position)
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    line.From = screenCenter
    line.To = Vector2.new(targetPos.X, targetPos.Y)
    line.Color = core.Tracers.Color
    line.Thickness = core.Tracers.Thickness
    line.Visible = true
end

function Tracers.setVisible(state)
    local core = getCore()
    if core then
        core.Tracers.Visible = state
    end

    if state then
        getLine()
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(onRender)
        end
    else
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        if drawingLine then
            drawingLine.Visible = false
        end
    end
end

function Tracers.setColor(color)
    local core = getCore()
    if core and typeof(color) == "Color3" then
        core.Tracers.Color = color
        if drawingLine then
            drawingLine.Color = color
        end
    end
end

function Tracers.setThickness(thickness)
    local core = getCore()
    if core and type(thickness) == "number" then
        core.Tracers.Thickness = thickness
        if drawingLine then
            drawingLine.Thickness = thickness
        end
    end
end

function Tracers.destroy()
    Tracers.setVisible(false)
    if drawingLine then
        pcall(function() drawingLine:Remove() end)
        drawingLine = nil
    end
end

return Tracers
