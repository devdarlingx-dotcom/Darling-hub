--[[
    Darling Hub - Compact Mobile & PC Floating Widget Component
    Supports direct one-click action buttons (e.g. Sanguine Z, Ninja Dash, Super Jump)
    and continuous toggle buttons (Fly, Soru TP, Fast Attack), with draggable locking.
]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local FloatingWidget = {
    Locked = false,
    AllWidgets = {},
}
FloatingWidget.__index = FloatingWidget

local function getGuiContainer()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    local ok2, c = pcall(function() return CoreGui end)
    if ok2 and c then return c end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local SharedScreenGui = nil

local function getSharedScreenGui()
    if SharedScreenGui and SharedScreenGui.Parent then
        return SharedScreenGui
    end

    local parent = getGuiContainer()
    local existing = parent:FindFirstChild("DarlingFloatingWidgets")
    if existing then
        SharedScreenGui = existing
        return SharedScreenGui
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "DarlingFloatingWidgets"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 2147482000
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    gui.Parent = parent
    SharedScreenGui = gui
    return SharedScreenGui
end

function FloatingWidget.LockAll(locked)
    FloatingWidget.Locked = (locked == true)
end

function FloatingWidget.create(config)
    config = config or {}
    local id = config.Id or ("Widget_" .. tostring(os.clock()))
    local label = config.Label or config.Title or "ACT"
    local widgetType = config.Type or "Toggle" -- "Action" (one-click instant tap) or "Toggle" (on/off)
    local enabled = config.Default == true
    local accentColor = config.AccentColor or Color3.fromRGB(192, 132, 252)
    local defaultPos = config.Position or UDim2.new(0.4, 0, 0.25, 0)
    local callback = config.Callback or function() end

    local screenGui = getSharedScreenGui()

    -- Remove any previous widget with the same ID
    local oldPill = screenGui:FindFirstChild(id)
    if oldPill then oldPill:Destroy() end

    -- Compact Mobile-Friendly Frame Container
    local pill = Instance.new("TextButton")
    pill.Name = id
    pill.Size = UDim2.fromOffset(58, 38)
    pill.Position = defaultPos
    pill.BackgroundColor3 = Color3.fromRGB(18, 16, 26)
    pill.BackgroundTransparency = 0.15
    pill.BorderSizePixel = 0
    pill.AutoButtonColor = false
    pill.Text = ""
    pill.Active = true
    pill.Visible = config.Visible ~= false
    pill.Parent = screenGui

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(0, 10)
    pillCorner.Parent = pill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Name = "BorderStroke"
    pillStroke.Thickness = 1.4
    pillStroke.Color = accentColor
    pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pillStroke.Parent = pill

    -- Action / Status Text Label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "MainText"
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = (string.len(label) > 3) and 11 or 15
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = label
    textLabel.Parent = pill

    -- Subtle Status Dot (for Toggle types)
    local statusDot = nil
    if widgetType == "Toggle" then
        statusDot = Instance.new("Frame")
        statusDot.Name = "StatusDot"
        statusDot.Size = UDim2.fromOffset(6, 6)
        statusDot.Position = UDim2.fromOffset(6, 6)
        statusDot.BorderSizePixel = 0
        statusDot.BackgroundColor3 = enabled and Color3.fromRGB(56, 224, 128) or Color3.fromRGB(244, 63, 94)
        statusDot.Parent = pill

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = statusDot
    end

    local self = setmetatable({
        Id = id,
        Type = widgetType,
        Enabled = enabled,
        Pill = pill,
        PillStroke = pillStroke,
        TextLabel = textLabel,
        StatusDot = statusDot,
        AccentColor = accentColor,
        BaseLabel = label,
        Callback = callback,
        Cooldown = false,
        Connections = {},
    }, FloatingWidget)

    table.insert(FloatingWidget.AllWidgets, self)

    local function updateVisuals()
        if self.Type == "Toggle" then
            if self.Enabled then
                pillStroke.Color = self.AccentColor
                if self.StatusDot then self.StatusDot.BackgroundColor3 = Color3.fromRGB(56, 224, 128) end
                textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                pillStroke.Color = Color3.fromRGB(60, 56, 75)
                if self.StatusDot then self.StatusDot.BackgroundColor3 = Color3.fromRGB(244, 63, 94) end
                textLabel.TextColor3 = Color3.fromRGB(160, 155, 175)
            end
        else
            pillStroke.Color = self.AccentColor
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    self.UpdateVisuals = updateVisuals
    updateVisuals()

    -- Trigger Action with visual feedback
    function self:TriggerAction()
        if self.Cooldown then return end
        self.Cooldown = true

        -- Immediate Callback Execution
        if self.Callback then
            self.Callback(true)
        end

        -- Visual feedback: flash green with "!" for 0.35s
        pcall(function()
            pill.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
            textLabel.Text = "!"
            pillStroke.Color = Color3.fromRGB(110, 255, 140)
        end)

        task.delay(0.35, function()
            pcall(function()
                if pill and pill.Parent then
                    pill.BackgroundColor3 = Color3.fromRGB(18, 16, 26)
                    textLabel.Text = self.BaseLabel
                    pillStroke.Color = self.AccentColor
                end
            end)
            self.Cooldown = false
        end)
    end

    -- Non-stick Dragging with Tap Distinction
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local moved = false

    table.insert(self.Connections, pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not FloatingWidget.Locked then
                dragging = true
                moved = false
                dragStart = input.Position
                startPos = pill.Position
            end
        end
    end))

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and not FloatingWidget.Locked and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                moved = true
                pill.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end))

    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
            end
            if not moved then
                if self.Type == "Action" then
                    self:TriggerAction()
                else
                    self:Toggle()
                end
            end
        end
    end))

    return self
end

function FloatingWidget:Set(state, suppressCallback)
    self.Enabled = (state == true)
    self.UpdateVisuals()
    if not suppressCallback and self.Callback then
        self.Callback(self.Enabled)
    end
end

function FloatingWidget:Toggle()
    self:Set(not self.Enabled)
end

function FloatingWidget:SetVisible(visible)
    if self.Pill and self.Pill.Parent then
        self.Pill.Visible = (visible == true)
    end
end

function FloatingWidget:SetLabel(lbl)
    self.BaseLabel = lbl
    if self.TextLabel then
        self.TextLabel.Text = lbl
    end
end

function FloatingWidget:Destroy()
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(self.Connections)
    if self.Pill and self.Pill.Parent then
        self.Pill:Destroy()
    end
end

return FloatingWidget
