-- ninja dash

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FloatingWidget = nil
pcall(function()
    FloatingWidget = (_G.DarlingHub and _G.DarlingHub:Require("modules/pvp/floating_widget.lua"))
end)

local NinjaDash = {
    Enabled = false,
    DashSpeed = 220,
    DashDuration = 0.18,
    Cooldown = 0.05,
    LastDash = 0,
    Keybind = Enum.KeyCode.F,
    Widget = nil,
    InputConnection = nil,
    ZigZagToggle = false,
}

local function triggerCameraPunch()
    pcall(function()
        local cam = Workspace.CurrentCamera or Camera
        if not cam then return end
        local originalFOV = cam.FieldOfView
        local targetFOV = math.clamp(originalFOV + 12, 70, 95)
        
        local tweenIn = TweenService:Create(cam, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            FieldOfView = targetFOV
        })
        tweenIn:Play()
        
        task.delay(0.12, function()
            local tweenOut = TweenService:Create(cam, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                FieldOfView = originalFOV
            })
            tweenOut:Play()
        end)
    end)
end

function NinjaDash.doDash()
    local now = os.clock()
    if now - NinjaDash.LastDash < NinjaDash.Cooldown then return end
    NinjaDash.LastDash = now

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    -- Reset internal Blox Fruits dash cooldown attribute
    pcall(function()
        char:SetAttribute("DashCooldown", 0)
    end)

    local cam = Workspace.CurrentCamera or Camera
    local moveDir = hum.MoveDirection
    local dashDir = (moveDir.Magnitude > 0) and moveDir or (cam and cam.CFrame.LookVector or hrp.CFrame.LookVector)
    dashDir = Vector3.new(dashDir.X, 0, dashDir.Z).Unit

    -- Calculate alternating zigzag offset
    NinjaDash.ZigZagToggle = not NinjaDash.ZigZagToggle
    local rightVector = Vector3.new(-dashDir.Z, 0, dashDir.X)
    local sideOffset = rightVector * (NinjaDash.ZigZagToggle and 0.35 or -0.35)
    local finalVelocity = (dashDir + sideOffset).Unit * NinjaDash.DashSpeed

    local att = Instance.new("Attachment")
    att.Name = "NinjaDashAttachment"
    att.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Name = "NinjaDashVelocity"
    lv.MaxForce = math.huge
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.VectorVelocity = finalVelocity
    lv.Attachment0 = att
    lv.Parent = hrp

    triggerCameraPunch()

    task.delay(NinjaDash.DashDuration, function()
        pcall(function()
            if lv and lv.Parent then lv:Destroy() end
            if att and att.Parent then att:Destroy() end
        end)
    end)
end

function NinjaDash.enable()
    if NinjaDash.Enabled then
        if NinjaDash.Widget then NinjaDash.Widget:SetVisible(true) end
        return
    end
    NinjaDash.Enabled = true

    if not NinjaDash.InputConnection then
        NinjaDash.InputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not NinjaDash.Enabled then return end
            if input.KeyCode == NinjaDash.Keybind then
                if NinjaDash.Widget then
                    NinjaDash.Widget:TriggerAction()
                else
                    NinjaDash.doDash()
                end
            end
        end)
    end

    if not NinjaDash.Widget and FloatingWidget then
        NinjaDash.Widget = FloatingWidget.create({
            Id = "NinjaDashWidget",
            Label = "F",
            Type = "Action",
            Position = UDim2.new(0.35, 0, 0.28, 0),
            AccentColor = Color3.fromRGB(244, 63, 94),
            Callback = function()
                NinjaDash.doDash()
            end
        })
    elseif NinjaDash.Widget then
        NinjaDash.Widget:SetVisible(true)
    end
end

function NinjaDash.disable()
    NinjaDash.Enabled = false
    if NinjaDash.InputConnection then
        pcall(function() NinjaDash.InputConnection:Disconnect() end)
        NinjaDash.InputConnection = nil
    end
    if NinjaDash.Widget then
        NinjaDash.Widget:SetVisible(false)
    end
end

function NinjaDash.toggle()
    if NinjaDash.Enabled then
        NinjaDash.disable()
    else
        NinjaDash.enable()
    end
    return NinjaDash.Enabled
end

function NinjaDash.setFloatingVisible(visible)
    if NinjaDash.Widget and NinjaDash.Enabled then
        NinjaDash.Widget:SetVisible(visible)
    end
end

return NinjaDash
