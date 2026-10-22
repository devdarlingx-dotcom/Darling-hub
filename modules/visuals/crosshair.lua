--[[
    Darling Hub - Animated Crosshair (Love Breeze Engine)
    Customizable spinning and dynamic resizing crosshair with PC & Mobile support.
]]--

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Crosshair = {
    Enabled = false,
    RefreshRate = 0,
    Mode = "Center", -- "Center" or "Mouse"
    Position = Vector2.new(0, 0),

    Width = 1.5,
    Length = 10,
    Radius = 11,
    Color = Color3.fromRGB(199, 110, 255),

    Spin = true,
    SpinSpeed = 150,
    SpinMax = 340,
    SpinStyle = Enum.EasingStyle.Sine,

    Resize = true,
    ResizeSpeed = 150,
    ResizeMin = 5,
    ResizeMax = 22,

    ShowText = true,
    TextString = "LOVE BREEZE",

    Connection = nil,
    LastRender = 0,
    Drawings = nil,
    FallbackGui = nil,
}

local function solve(angle, radius)
    return Vector2.new(
        math.sin(math.rad(angle)) * radius,
        math.cos(math.rad(angle)) * radius
    )
end

local function initDrawingLines()
    if Crosshair.Drawings then return true end
    local ok, _ = pcall(function() return Drawing and Drawing.new end)
    if not (ok and Drawing and Drawing.new) then return false end

    local d = {
        crosshair = {},
        text = {
            Drawing.new("Text"),
            Drawing.new("Text")
        }
    }

    d.text[1].Size = 13
    d.text[1].Font = 2
    d.text[1].Outline = true
    d.text[1].Text = ". "
    d.text[1].Color = Color3.new(1, 1, 1)

    d.text[2].Size = 13
    d.text[2].Font = 2
    d.text[2].Outline = true
    d.text[2].Text = Crosshair.TextString
    d.text[2].Color = Crosshair.Color

    for idx = 1, 8 do
        d.crosshair[idx] = Drawing.new("Line")
    end

    Crosshair.Drawings = d
    return true
end

function Crosshair.step()
    if not Crosshair.Enabled then return end
    local now = tick()
    if now - Crosshair.LastRender < Crosshair.RefreshRate then return end
    Crosshair.LastRender = now

    local cam = Workspace.CurrentCamera or Camera
    if not cam then return end

    local position = (
        Crosshair.Mode == "Center" and (cam.ViewportSize / 2) or
        Crosshair.Mode == "Mouse" and UserInputService:GetMouseLocation() or
        Crosshair.Position
    )

    if Crosshair.Drawings then
        local d = Crosshair.Drawings
        d.text[1].Visible = Crosshair.Enabled and Crosshair.ShowText
        d.text[2].Visible = Crosshair.Enabled and Crosshair.ShowText
        d.text[2].Text = Crosshair.TextString
        d.text[2].Color = Crosshair.Color

        if Crosshair.ShowText then
            local text_x = d.text[1].TextBounds.X + d.text[2].TextBounds.X
            d.text[1].Position = position + Vector2.new(-text_x / 2, Crosshair.Radius + (Crosshair.Resize and Crosshair.ResizeMax or Crosshair.Length) + 12)
            d.text[2].Position = d.text[1].Position + Vector2.new(d.text[1].TextBounds.X, 0)
        end

        for idx = 1, 4 do
            local outline = d.crosshair[idx]
            local inline = d.crosshair[idx + 4]

            local angle = (idx - 1) * 90
            local length = Crosshair.Length

            if Crosshair.Spin then
                local spin_angle = -now * Crosshair.SpinSpeed % Crosshair.SpinMax
                angle = angle + TweenService:GetValue(spin_angle / 360, Crosshair.SpinStyle, Enum.EasingDirection.InOut) * 360
            end

            if Crosshair.Resize then
                local resize_length = now * Crosshair.ResizeSpeed % 180
                length = Crosshair.ResizeMin + math.sin(math.rad(resize_length)) * Crosshair.ResizeMax
            end

            inline.Visible = true
            inline.Color = Crosshair.Color
            inline.From = position + solve(angle, Crosshair.Radius)
            inline.To = position + solve(angle, Crosshair.Radius + length)
            inline.Thickness = Crosshair.Width

            outline.Visible = true
            outline.Color = Color3.fromRGB(0, 0, 0)
            outline.From = position + solve(angle, Crosshair.Radius - 1)
            outline.To = position + solve(angle, Crosshair.Radius + length + 1)
            outline.Thickness = Crosshair.Width + 1.5
        end
    end
end

function Crosshair.setEnabled(state)
    Crosshair.Enabled = state
    if state then
        initDrawingLines()
        if not Crosshair.Connection then
            Crosshair.Connection = RunService.PostSimulation:Connect(Crosshair.step)
        end
    else
        if Crosshair.Connection then
            pcall(function() Crosshair.Connection:Disconnect() end)
            Crosshair.Connection = nil
        end
        if Crosshair.Drawings then
            pcall(function()
                Crosshair.Drawings.text[1].Visible = false
                Crosshair.Drawings.text[2].Visible = false
                for idx = 1, 8 do
                    Crosshair.Drawings.crosshair[idx].Visible = false
                end
            end)
        end
    end
end

return Crosshair
