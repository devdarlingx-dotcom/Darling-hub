-- movement engine

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FloatingWidget = nil
pcall(function()
    FloatingWidget = (_G.DarlingHub and _G.DarlingHub:Require("modules/pvp/floating_widget.lua"))
end)

local MovementEngine = {
    -- Walk Speed
    WalkSpeedEnabled = false,
    WalkSpeedValue = 16,

    -- Fly
    FlyEnabled = false,
    FlySpeed = 70,
    FlyBodyVelocity = nil,
    FlyBodyGyro = nil,
    FlyWidget = nil,
    FlyKeybind = nil, -- Unbound by default (X is a Blox Fruits skill key)

    -- Noclip
    NoclipEnabled = false,
    NoclipConn = nil,

    -- Dash Distance
    DashDistanceEnabled = false,
    DashDistanceValue = 50,
    DashLoop = nil,

    -- Infinite Jump
    InfiniteJumpEnabled = false,
    LastJumpTime = 0,
    JumpRequestConn = nil,

    -- Super Jump
    SuperJumpEnabled = false,
    SuperJumpPower = 500,
    SuperJumpWidget = nil,

    -- Walk on Water
    WalkOnWaterEnabled = false,
    WaterPlatform = nil,
    WaterLoop = nil,

    SteppedConn = nil,
}

-- ========================================================================
-- 1. WALK SPEED (BLOXPBYPASS)
-- ========================================================================
function MovementEngine.setWalkSpeed(enabled, value)
    MovementEngine.WalkSpeedEnabled = enabled
    if value then MovementEngine.WalkSpeedValue = value end
end

-- ========================================================================
-- 2. FLY SYSTEM
-- ========================================================================
local flyKeys = { W = false, A = false, S = false, D = false, Space = false, LeftShift = false }

local function updateFlyMovement()
    if not MovementEngine.FlyEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or not MovementEngine.FlyBodyVelocity or not MovementEngine.FlyBodyGyro then return end

    local cam = Workspace.CurrentCamera or Camera
    MovementEngine.FlyBodyGyro.CFrame = cam.CFrame

    local moveDir = Vector3.new(0, 0, 0)
    local camCF = cam.CFrame

    -- Mobile thumbstick and PC WASD unified via Humanoid.MoveDirection
    local m = hum.MoveDirection
    if m.Magnitude > 0 then
        local fwd = m:Dot(camCF.LookVector)
        local rgt = m:Dot(camCF.RightVector)
        moveDir = (camCF.LookVector * fwd + camCF.RightVector * rgt)
    end

    -- PC Keyboard Direct Controls
    if flyKeys.W then moveDir = moveDir + camCF.LookVector end
    if flyKeys.S then moveDir = moveDir - camCF.LookVector end
    if flyKeys.A then moveDir = moveDir - camCF.RightVector end
    if flyKeys.D then moveDir = moveDir + camCF.RightVector end
    if flyKeys.Space then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if flyKeys.LeftShift then moveDir = moveDir - Vector3.new(0, 1, 0) end

    if moveDir.Magnitude > 0 then
        MovementEngine.FlyBodyVelocity.Velocity = moveDir.Unit * MovementEngine.FlySpeed
    else
        MovementEngine.FlyBodyVelocity.Velocity = Vector3.new(0, 0.1, 0)
    end

    hum:ChangeState(Enum.HumanoidStateType.Swimming)
end

function MovementEngine.startFly()
    if MovementEngine.FlyEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    MovementEngine.FlyEnabled = true

    local cam = Workspace.CurrentCamera or Camera

    local bv = Instance.new("BodyVelocity")
    bv.Name = "DarlingFlyVelocity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0.1, 0)
    bv.Parent = hrp
    MovementEngine.FlyBodyVelocity = bv

    local bg = Instance.new("BodyGyro")
    bg.Name = "DarlingFlyGyro"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 9e4
    bg.CFrame = cam.CFrame
    bg.Parent = hrp
    MovementEngine.FlyBodyGyro = bg

    hum.PlatformStand = true
    hum:ChangeState(Enum.HumanoidStateType.Swimming)

    if not MovementEngine.FlyWidget and FloatingWidget then
        MovementEngine.FlyWidget = FloatingWidget.create({
            Id = "FlyWidget",
            Label = "FLY",
            Type = "Toggle",
            Default = true,
            Position = UDim2.new(0.35, 0, 0.46, 0),
            AccentColor = Color3.fromRGB(168, 85, 247),
            Callback = function(state)
                if state then
                    MovementEngine.startFly()
                else
                    MovementEngine.stopFly()
                end
            end
        })
    elseif MovementEngine.FlyWidget then
        MovementEngine.FlyWidget:Set(true, true)
        MovementEngine.FlyWidget:SetVisible(true)
    end
end

function MovementEngine.stopFly()
    MovementEngine.FlyEnabled = false
    if MovementEngine.FlyBodyVelocity and MovementEngine.FlyBodyVelocity.Parent then
        MovementEngine.FlyBodyVelocity:Destroy()
    end
    MovementEngine.FlyBodyVelocity = nil

    if MovementEngine.FlyBodyGyro and MovementEngine.FlyBodyGyro.Parent then
        MovementEngine.FlyBodyGyro:Destroy()
    end
    MovementEngine.FlyBodyGyro = nil

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
    end

    if MovementEngine.FlyWidget then
        MovementEngine.FlyWidget:Set(false, true)
        MovementEngine.FlyWidget:SetVisible(false)
    end
end

function MovementEngine.toggleFly()
    if MovementEngine.FlyEnabled then
        MovementEngine.stopFly()
    else
        MovementEngine.startFly()
    end
    return MovementEngine.FlyEnabled
end

-- ========================================================================
-- 3. NOCLIP SYSTEM
-- ========================================================================
function MovementEngine.setNoclip(state)
    MovementEngine.NoclipEnabled = state
    if state and not MovementEngine.NoclipConn then
        MovementEngine.NoclipConn = RunService.Stepped:Connect(function()
            if not MovementEngine.NoclipEnabled then return end
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    elseif not state and MovementEngine.NoclipConn then
        pcall(function() MovementEngine.NoclipConn:Disconnect() end)
        MovementEngine.NoclipConn = nil
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ========================================================================
-- 4. DASH DISTANCE
-- ========================================================================
function MovementEngine.setDashDistance(state, dist)
    MovementEngine.DashDistanceEnabled = state
    if dist then MovementEngine.DashDistanceValue = dist end

    if state and not MovementEngine.DashLoop then
        MovementEngine.DashLoop = task.spawn(function()
            while MovementEngine.DashDistanceEnabled do
                task.wait(0.2)
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local d = MovementEngine.DashDistanceValue
                        if char:GetAttribute("DashLength") ~= d then char:SetAttribute("DashLength", d) end
                        if char:GetAttribute("DashLengthAir") ~= d then char:SetAttribute("DashLengthAir", d) end
                    end
                end)
            end
            MovementEngine.DashLoop = nil
        end)
    end
end

-- infinite air jump
function MovementEngine.doAirJump()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end

    -- Reset Blox Fruits Geppo jump counter
    local jumps = char:FindFirstChild("Jumps")
    if jumps and jumps:IsA("IntValue") then
        jumps.Value = 0
    end

    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    hum.Jump = true

    local power = hum.UseJumpPower ~= false and hum.JumpPower or math.sqrt(2 * Workspace.Gravity * hum.JumpHeight)
    power = math.max(power, 70)

    local vel = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(vel.Y, power), vel.Z)
end

function MovementEngine.setInfiniteJump(state)
    MovementEngine.InfiniteJumpEnabled = state
    if state and not MovementEngine.JumpRequestConn then
        MovementEngine.JumpRequestConn = UserInputService.JumpRequest:Connect(function()
            if not MovementEngine.InfiniteJumpEnabled then return end
            local now = os.clock()
            if now - MovementEngine.LastJumpTime < 0.08 then return end
            MovementEngine.LastJumpTime = now
            MovementEngine.doAirJump()
        end)
    elseif not state and MovementEngine.JumpRequestConn then
        pcall(function() MovementEngine.JumpRequestConn:Disconnect() end)
        MovementEngine.JumpRequestConn = nil
    end
end

-- ========================================================================
-- 6. SUPER JUMP
-- ========================================================================
function MovementEngine.doSuperJump()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local power = tonumber(MovementEngine.SuperJumpPower) or 500
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)

    -- Clean up any lingering jump force
    local existing = hrp:FindFirstChild("DarlingSuperJump")
    if existing then pcall(function() existing:Destroy() end) end

    -- Sustained upward velocity force so Blox Fruits physics clamps don't nullify jump
    local bv = Instance.new("BodyVelocity")
    bv.Name = "DarlingSuperJump"
    bv.MaxForce = Vector3.new(0, 1e7, 0)
    bv.Velocity = Vector3.new(0, power, 0)
    bv.Parent = hrp

    local vel = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, power, vel.Z)
    pcall(function() hrp.Velocity = Vector3.new(vel.X, power, vel.Z) end)

    task.delay(0.2, function()
        if bv and bv.Parent then
            pcall(function() bv:Destroy() end)
        end
    end)
end

function MovementEngine.setSuperJump(state, power)
    MovementEngine.SuperJumpEnabled = state
    if power then MovementEngine.SuperJumpPower = power end

    if state then
        if not MovementEngine.SuperJumpWidget and FloatingWidget then
            MovementEngine.SuperJumpWidget = FloatingWidget.create({
                Id = "SuperJumpWidget",
                Label = "JUMP",
                Type = "Action",
                Position = UDim2.new(0.35, 0, 0.52, 0),
                AccentColor = Color3.fromRGB(34, 197, 94),
                Callback = function()
                    MovementEngine.doSuperJump()
                end
            })
        elseif MovementEngine.SuperJumpWidget then
            MovementEngine.SuperJumpWidget:SetVisible(true)
        end
    else
        if MovementEngine.SuperJumpWidget then
            MovementEngine.SuperJumpWidget:SetVisible(false)
        end
    end
end

-- ========================================================================
-- 7. WALK ON WATER
-- ========================================================================
local function getWaterPlatform()
    if MovementEngine.WaterPlatform and MovementEngine.WaterPlatform.Parent then
        return MovementEngine.WaterPlatform
    end
    local part = Instance.new("Part")
    part.Name = "DarlingWaterPlatform"
    part.Size = Vector3.new(200, 1, 200)
    part.Transparency = 1
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Parent = Workspace
    MovementEngine.WaterPlatform = part
    return part
end

function MovementEngine.setWalkOnWater(state)
    MovementEngine.WalkOnWaterEnabled = state
    local char = LocalPlayer.Character
    if char then
        pcall(function() char:SetAttribute("WaterWalking", state) end)
    end

    if state and not MovementEngine.WaterLoop then
        MovementEngine.WaterLoop = task.spawn(function()
            while MovementEngine.WalkOnWaterEnabled do
                task.wait(0.12)
                pcall(function()
                    local c = LocalPlayer.Character
                    local hrp = c and c:FindFirstChild("HumanoidRootPart")
                    local plat = getWaterPlatform()
                    if hrp and plat then
                        -- Blox Fruits water surface sits around Y = 9.2 in open sea
                        if hrp.Position.Y >= 8.5 then
                            plat.Position = Vector3.new(hrp.Position.X, 8.8, hrp.Position.Z)
                            plat.CanCollide = true
                        else
                            plat.CanCollide = false
                        end
                    elseif plat then
                        plat.CanCollide = false
                    end
                end)
            end
            if MovementEngine.WaterPlatform and MovementEngine.WaterPlatform.Parent then
                MovementEngine.WaterPlatform.CanCollide = false
            end
            MovementEngine.WaterLoop = nil
        end)
    elseif not state and MovementEngine.WaterPlatform then
        MovementEngine.WaterPlatform.CanCollide = false
    end
end

-- ========================================================================
-- GLOBAL RUNTIME TICK & INPUT HOOKS
-- ========================================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if MovementEngine.FlyKeybind and input.KeyCode == MovementEngine.FlyKeybind then
        MovementEngine.toggleFly()
    end
    if input.KeyCode == Enum.KeyCode.W then flyKeys.W = true end
    if input.KeyCode == Enum.KeyCode.A then flyKeys.A = true end
    if input.KeyCode == Enum.KeyCode.S then flyKeys.S = true end
    if input.KeyCode == Enum.KeyCode.D then flyKeys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then
        flyKeys.Space = true
        if MovementEngine.SuperJumpEnabled then
            MovementEngine.doSuperJump()
        end
    end
    if input.KeyCode == Enum.KeyCode.LeftShift then flyKeys.LeftShift = true end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.W then flyKeys.W = false end
    if input.KeyCode == Enum.KeyCode.A then flyKeys.A = false end
    if input.KeyCode == Enum.KeyCode.S then flyKeys.S = false end
    if input.KeyCode == Enum.KeyCode.D then flyKeys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then flyKeys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then flyKeys.LeftShift = false end
end)

MovementEngine.SteppedConn = RunService.Stepped:Connect(function()
    -- WalkSpeed Bypass Tick
    if MovementEngine.WalkSpeedEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum.WalkSpeed = MovementEngine.WalkSpeedValue
            if hum.MoveDirection.Magnitude > 0 and MovementEngine.WalkSpeedValue > 20 then
                hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (MovementEngine.WalkSpeedValue / 100))
            end
        end
    end

    -- Fly Tick
    if MovementEngine.FlyEnabled then
        updateFlyMovement()
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    if MovementEngine.WalkOnWaterEnabled then
        pcall(function() newChar:SetAttribute("WaterWalking", true) end)
    end
    if MovementEngine.DashDistanceEnabled then
        pcall(function()
            newChar:SetAttribute("DashLength", MovementEngine.DashDistanceValue)
            newChar:SetAttribute("DashLengthAir", MovementEngine.DashDistanceValue)
        end)
    end
end)

function MovementEngine.disable()
    MovementEngine.setWalkSpeed(false, 16)
    MovementEngine.setFly(false)
    MovementEngine.setNoclip(false)
    MovementEngine.setDashDistance(false, 50)
    MovementEngine.setInfiniteJump(false)
    MovementEngine.setSuperJump(false)
    MovementEngine.setWalkOnWater(false)
end

return MovementEngine
