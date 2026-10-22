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
    FlyKeybind = Enum.KeyCode.X,

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
    if MovementEngine.updateSteppedState then MovementEngine.updateSteppedState() end
    if not enabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
        end
    end
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
    if MovementEngine.updateSteppedState then MovementEngine.updateSteppedState() end

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
    if MovementEngine.updateSteppedState then MovementEngine.updateSteppedState() end
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
local noclipParts = {}
local noclipDescAddedConn = nil
local noclipDescRemovingConn = nil

local function rebuildNoclipParts(char)
    table.clear(noclipParts)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(noclipParts, part)
        end
    end
end

local function cleanupNoclipConns()
    if noclipDescAddedConn then
        pcall(function() noclipDescAddedConn:Disconnect() end)
        noclipDescAddedConn = nil
    end
    if noclipDescRemovingConn then
        pcall(function() noclipDescRemovingConn:Disconnect() end)
        noclipDescRemovingConn = nil
    end
end

function MovementEngine.setNoclip(state)
    MovementEngine.NoclipEnabled = state
    if state then
        cleanupNoclipConns()
        local char = LocalPlayer.Character
        rebuildNoclipParts(char)
        if char then
            noclipDescAddedConn = char.DescendantAdded:Connect(function(desc)
                if desc:IsA("BasePart") then
                    table.insert(noclipParts, desc)
                end
            end)
            noclipDescRemovingConn = char.DescendantRemoving:Connect(function(desc)
                if desc:IsA("BasePart") then
                    local idx = table.find(noclipParts, desc)
                    if idx then table.remove(noclipParts, idx) end
                end
            end)
        end

        if not MovementEngine.NoclipConn then
            MovementEngine.NoclipConn = RunService.Stepped:Connect(function()
                if not MovementEngine.NoclipEnabled then return end
                for i = #noclipParts, 1, -1 do
                    local part = noclipParts[i]
                    if part and part.Parent then
                        part.CanCollide = false
                    else
                        table.remove(noclipParts, i)
                    end
                end
            end)
        end
    else
        cleanupNoclipConns()
        if MovementEngine.NoclipConn then
            pcall(function() MovementEngine.NoclipConn:Disconnect() end)
            MovementEngine.NoclipConn = nil
        end
        for _, part in ipairs(noclipParts) do
            if part and part.Parent and part.Name ~= "HumanoidRootPart" then
                pcall(function() part.CanCollide = true end)
            end
        end
        table.clear(noclipParts)
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
-- 6. SUPER JUMP (SACRED AHK ENGINE)
-- ========================================================================
function MovementEngine.doSuperJump()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local vel = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, MovementEngine.SuperJumpPower, vel.Z)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
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
-- 7. WALK ON WATER (JESUS ENGINE)
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
function MovementEngine.updateSteppedState()
    local needsStepped = MovementEngine.WalkSpeedEnabled or MovementEngine.FlyEnabled
    if needsStepped and not MovementEngine.SteppedConn then
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
    elseif not needsStepped and MovementEngine.SteppedConn then
        pcall(function() MovementEngine.SteppedConn:Disconnect() end)
        MovementEngine.SteppedConn = nil
    end
end

MovementEngine.InputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == MovementEngine.FlyKeybind then
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

MovementEngine.InputEndedConn = UserInputService.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.W then flyKeys.W = false end
    if input.KeyCode == Enum.KeyCode.A then flyKeys.A = false end
    if input.KeyCode == Enum.KeyCode.S then flyKeys.S = false end
    if input.KeyCode == Enum.KeyCode.D then flyKeys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then flyKeys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then flyKeys.LeftShift = false end
end)

MovementEngine.CharAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
    if MovementEngine.NoclipEnabled then
        cleanupNoclipConns()
        rebuildNoclipParts(newChar)
        if newChar then
            noclipDescAddedConn = newChar.DescendantAdded:Connect(function(desc)
                if desc:IsA("BasePart") then table.insert(noclipParts, desc) end
            end)
            noclipDescRemovingConn = newChar.DescendantRemoving:Connect(function(desc)
                if desc:IsA("BasePart") then
                    local idx = table.find(noclipParts, desc)
                    if idx then table.remove(noclipParts, idx) end
                end
            end)
        end
    end
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

function MovementEngine.destroy()
    MovementEngine.setWalkSpeed(false)
    MovementEngine.stopFly()
    MovementEngine.setNoclip(false)
    MovementEngine.setDashDistance(false)
    MovementEngine.setInfiniteJump(false)
    MovementEngine.setSuperJump(false)
    MovementEngine.setWalkOnWater(false)

    if MovementEngine.SteppedConn then
        pcall(function() MovementEngine.SteppedConn:Disconnect() end)
        MovementEngine.SteppedConn = nil
    end
    if MovementEngine.InputBeganConn then
        pcall(function() MovementEngine.InputBeganConn:Disconnect() end)
        MovementEngine.InputBeganConn = nil
    end
    if MovementEngine.InputEndedConn then
        pcall(function() MovementEngine.InputEndedConn:Disconnect() end)
        MovementEngine.InputEndedConn = nil
    end
    if MovementEngine.CharAddedConn then
        pcall(function() MovementEngine.CharAddedConn:Disconnect() end)
        MovementEngine.CharAddedConn = nil
    end
    if MovementEngine.FlyWidget then
        pcall(function() MovementEngine.FlyWidget:Destroy() end)
        MovementEngine.FlyWidget = nil
    end
    if MovementEngine.SuperJumpWidget then
        pcall(function() MovementEngine.SuperJumpWidget:Destroy() end)
        MovementEngine.SuperJumpWidget = nil
    end
    if MovementEngine.WaterPlatform and MovementEngine.WaterPlatform.Parent then
        pcall(function() MovementEngine.WaterPlatform:Destroy() end)
        MovementEngine.WaterPlatform = nil
    end
end

function MovementEngine.getDiagnostics()
    local connCount = 0
    if MovementEngine.SteppedConn then connCount = connCount + 1 end
    if MovementEngine.InputBeganConn then connCount = connCount + 1 end
    if MovementEngine.InputEndedConn then connCount = connCount + 1 end
    if MovementEngine.CharAddedConn then connCount = connCount + 1 end
    if MovementEngine.NoclipConn then connCount = connCount + 1 end
    if MovementEngine.JumpRequestConn then connCount = connCount + 1 end
    if noclipDescAddedConn then connCount = connCount + 1 end
    if noclipDescRemovingConn then connCount = connCount + 1 end

    local threadCount = 0
    if MovementEngine.DashLoop then threadCount = threadCount + 1 end
    if MovementEngine.WaterLoop then threadCount = threadCount + 1 end

    local isActive = MovementEngine.WalkSpeedEnabled or MovementEngine.FlyEnabled or MovementEngine.NoclipEnabled or MovementEngine.DashDistanceEnabled or MovementEngine.InfiniteJumpEnabled or MovementEngine.SuperJumpEnabled or MovementEngine.WalkOnWaterEnabled

    return {
        Connections = connCount,
        Threads = threadCount,
        Active = isActive,
    }
end

return MovementEngine
