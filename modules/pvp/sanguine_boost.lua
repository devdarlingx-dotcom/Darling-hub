--[[
    Darling Hub - Sanguine Z Boost Module
    Applies a powerful linear velocity launch in camera look direction on Z skill activation.
]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FloatingWidget = nil
pcall(function()
    FloatingWidget = (_G.DarlingHub and _G.DarlingHub:Require("modules/pvp/floating_widget.lua"))
end)

local SanguineBoost = {
    Enabled = false,
    VelocityPower = 400,
    BoostDuration = 0.9,
    Cooldown = 0.35,
    LastBoost = 0,
    Widget = nil,
    Connection = nil,
}

function SanguineBoost.doBoost()
    local now = os.clock()
    if now - SanguineBoost.LastBoost < SanguineBoost.Cooldown then return end
    SanguineBoost.LastBoost = now

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local cam = Workspace.CurrentCamera or Camera
    local dir = cam.CFrame.LookVector

    local att = Instance.new("Attachment")
    att.Name = "SanguineBoostAttachment"
    att.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Name = "SanguineBoostVelocity"
    lv.MaxForce = math.huge
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.VectorVelocity = dir * SanguineBoost.VelocityPower
    lv.Attachment0 = att
    lv.Parent = hrp

    task.delay(SanguineBoost.BoostDuration, function()
        pcall(function()
            if lv and lv.Parent then lv:Destroy() end
            if att and att.Parent then att:Destroy() end
        end)
    end)
end

function SanguineBoost.enable()
    if SanguineBoost.Enabled then return end
    SanguineBoost.Enabled = true

    if not SanguineBoost.Connection then
        SanguineBoost.Connection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not SanguineBoost.Enabled then return end
            if input.KeyCode == Enum.KeyCode.Z then
                SanguineBoost.doBoost()
            end
        end)
    end

    if not SanguineBoost.Widget and FloatingWidget then
        SanguineBoost.Widget = FloatingWidget.create({
            Id = "SanguineZBoostWidget",
            Title = "Sanguine Z Boost",
            Subtitle = "Burst Key [Z]",
            Default = true,
            Position = UDim2.new(0.35, 0, 0.22, 0),
            AccentColor = Color3.fromRGB(192, 132, 252),
            Callback = function(state)
                if state then
                    SanguineBoost.enable()
                else
                    SanguineBoost.disable()
                end
            end
        })
    elseif SanguineBoost.Widget then
        SanguineBoost.Widget:Set(true, true)
        SanguineBoost.Widget:SetVisible(true)
    end
end

function SanguineBoost.disable()
    SanguineBoost.Enabled = false
    if SanguineBoost.Connection then
        pcall(function() SanguineBoost.Connection:Disconnect() end)
        SanguineBoost.Connection = nil
    end
    if SanguineBoost.Widget then
        SanguineBoost.Widget:Set(false, true)
    end
end

function SanguineBoost.toggle()
    if SanguineBoost.Enabled then
        SanguineBoost.disable()
    else
        SanguineBoost.enable()
    end
    return SanguineBoost.Enabled
end

function SanguineBoost.setFloatingVisible(visible)
    if SanguineBoost.Widget then
        SanguineBoost.Widget:SetVisible(visible)
    end
end

return SanguineBoost
