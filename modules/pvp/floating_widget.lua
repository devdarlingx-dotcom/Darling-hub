--[[
    Darling Hub - Unified Floating Widget Toggle Component
    Provides a standardized, draggable, responsive floating pill widget.
]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local FloatingWidget = {}
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

function FloatingWidget.create(config)
    config = config or {}
    local id = config.Id or ("Widget_" .. tostring(os.clock()))
    local title = config.Title or "Feature Toggle"
    local subtitle = config.Subtitle or "Darling Hub"
    local enabled = config.Default == true
    local accentColor = config.AccentColor or Color3.fromRGB(56, 189, 248)
    local defaultPos = config.Position or UDim2.new(0.5, -85, 0.2, 0)
    local callback = config.Callback or function() end

    local screenGui = getSharedScreenGui()

    -- Remove any previous widget with the same ID
    local oldPill = screenGui:FindFirstChild(id)
    if oldPill then oldPill:Destroy() end

    -- Pill Button Container
    local pill = Instance.new("TextButton")
    pill.Name = id
    pill.Size = UDim2.fromOffset(170, 40)
    pill.Position = defaultPos
    pill.BackgroundColor3 = Color3.fromRGB(16, 14, 22)
    pill.BackgroundTransparency = 0.25
    pill.BorderSizePixel = 0
    pill.AutoButtonColor = false
    pill.Text = ""
    pill.Active = true
    pill.Parent = screenGui

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(0, 20)
    pillCorner.Parent = pill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Name = "BorderStroke"
    pillStroke.Thickness = 1.4
    pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pillStroke.Parent = pill

    -- Status Dot
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.fromOffset(10, 10)
    statusDot.Position = UDim2.fromOffset(14, 15)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = pill

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -65, 0, 16)
    titleLabel.Position = UDim2.fromOffset(32, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 11
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Text = title
    titleLabel.Parent = pill

    -- Subtitle Label
    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "SubLabel"
    subLabel.Size = UDim2.new(1, -65, 0, 12)
    subLabel.Position = UDim2.fromOffset(32, 22)
    subLabel.BackgroundTransparency = 1
    subLabel.Font = Enum.Font.GothamMedium
    subLabel.TextSize = 8
    subLabel.TextColor3 = Color3.fromRGB(145, 140, 155)
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.TextTruncate = Enum.TextTruncate.AtEnd
    subLabel.Text = subtitle
    subLabel.Parent = pill

    -- State Pill Badge
    local stateBadge = Instance.new("Frame")
    stateBadge.Name = "StateBadge"
    stateBadge.Size = UDim2.fromOffset(32, 18)
    stateBadge.Position = UDim2.new(1, -42, 0.5, -9)
    stateBadge.BorderSizePixel = 0
    stateBadge.Parent = pill

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 9)
    badgeCorner.Parent = stateBadge

    local badgeText = Instance.new("TextLabel")
    badgeText.Name = "BadgeText"
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Font = Enum.Font.GothamBold
    badgeText.TextSize = 9
    badgeText.Parent = stateBadge

    local self = setmetatable({
        Id = id,
        Enabled = enabled,
        Pill = pill,
        PillStroke = pillStroke,
        StatusDot = statusDot,
        TitleLabel = titleLabel,
        SubLabel = subLabel,
        StateBadge = stateBadge,
        BadgeText = badgeText,
        AccentColor = accentColor,
        Callback = callback,
        Connections = {},
    }, FloatingWidget)

    local function updateVisuals()
        if self.Enabled then
            pillStroke.Color = self.AccentColor
            statusDot.BackgroundColor3 = Color3.fromRGB(56, 224, 128)
            stateBadge.BackgroundColor3 = Color3.fromRGB(24, 60, 40)
            badgeText.Text = "ON"
            badgeText.TextColor3 = Color3.fromRGB(72, 235, 140)
            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            pillStroke.Color = Color3.fromRGB(48, 46, 60)
            statusDot.BackgroundColor3 = Color3.fromRGB(244, 63, 94)
            stateBadge.BackgroundColor3 = Color3.fromRGB(40, 32, 42)
            badgeText.Text = "OFF"
            badgeText.TextColor3 = Color3.fromRGB(180, 170, 190)
            titleLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
    end

    self.UpdateVisuals = updateVisuals
    updateVisuals()

    -- Non-stick Dragging with Tap-to-Toggle Distinction
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local moved = false

    table.insert(self.Connections, pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = pill.Position
        end
    end))

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then
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
                if not moved then
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

function FloatingWidget:SetText(title, subtitle)
    if title and self.TitleLabel then self.TitleLabel.Text = title end
    if subtitle and self.SubLabel then self.SubLabel.Text = subtitle end
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
