-- race awakening

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer

local RaceAwakening = {
    AutoV3 = false,
    AutoV4 = false,
    AntiStun = false,
    V3HealthThreshold = 75, -- Trigger when HP falls below 75%
    V3LastActivated = 0,
    V3Cooldown = 15,
    V4LastChecked = 0,
    V3Thread = nil,
    V4Thread = nil,
    AntiStunConnection = nil,
}

local function triggerV3Remotes()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local commE = remotes:FindFirstChild("CommE")
            if commE and commE:IsA("RemoteEvent") then
                commE:FireServer("ActivateAbility")
            end
            local commF = remotes:FindFirstChild("CommF_")
            if commF and commF:IsA("RemoteFunction") then
                commF:InvokeServer("ActivateAbility")
            end
        end
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
        end
    end)
end

local function triggerV4Remotes()
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            local v4Event = events:FindFirstChild("ActivateRaceV4")
            if v4Event and v4Event:IsA("BindableEvent") then
                v4Event:Fire()
            end
        end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local awakening = remotes:FindFirstChild("Awakening")
            if awakening then
                local rf = awakening:FindFirstChildOfClass("RemoteFunction")
                if rf then
                    rf:InvokeServer(true)
                end
            end
        end
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Y, false, game)
        end
    end)
end

function RaceAwakening.setAutoV3(state)
    RaceAwakening.AutoV3 = state
    if state and not RaceAwakening.V3Thread then
        RaceAwakening.V3Thread = task.spawn(function()
            while RaceAwakening.AutoV3 do
                task.wait(0.5)
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health <= 0 then return end

                    local hpPercent = (hum.Health / hum.MaxHealth) * 100
                    local now = os.clock()
                    if hpPercent <= RaceAwakening.V3HealthThreshold and (now - RaceAwakening.V3LastActivated > RaceAwakening.V3Cooldown) then
                        RaceAwakening.V3LastActivated = now
                        triggerV3Remotes()
                    end
                end)
            end
            RaceAwakening.V3Thread = nil
        end)
    elseif not state and RaceAwakening.V3Thread then
        pcall(function() task.cancel(RaceAwakening.V3Thread) end)
        RaceAwakening.V3Thread = nil
    end
end

function RaceAwakening.setAutoV4(state)
    RaceAwakening.AutoV4 = state
    if state and not RaceAwakening.V4Thread then
        RaceAwakening.V4Thread = task.spawn(function()
            while RaceAwakening.AutoV4 do
                task.wait(0.5)
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end

                    local energy = char:FindFirstChild("RaceEnergy")
                    local transformed = char:FindFirstChild("RaceTransformed")
                    local isTransformed = (transformed and transformed:IsA("BoolValue") and transformed.Value)
                    
                    if energy and not isTransformed then
                        local energyVal = tonumber(energy.Value) or 0
                        -- Meter is ready at 1 (or 100)
                        if energyVal >= 1 then
                            triggerV4Remotes()
                        end
                    end
                end)
            end
            RaceAwakening.V4Thread = nil
        end)
    elseif not state and RaceAwakening.V4Thread then
        pcall(function() task.cancel(RaceAwakening.V4Thread) end)
        RaceAwakening.V4Thread = nil
    end
end

function RaceAwakening.setAntiStun(state)
    RaceAwakening.AntiStun = state
    if state and not RaceAwakening.AntiStunConnection then
        RaceAwakening.AntiStunConnection = RunService.Stepped:Connect(function()
            if not RaceAwakening.AntiStun then return end
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end

                -- Clear internal Stun value
                local stun = char:FindFirstChild("Stun")
                if stun and stun:IsA("NumberValue") and stun.Value > 0 then
                    stun.Value = 0
                end
                local busy = char:FindFirstChild("Busy")
                if busy and busy:IsA("BoolValue") and busy.Value then
                    busy.Value = false
                end

                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if hum.PlatformStand then hum.PlatformStand = false end
                    if hum.Sit then hum.Sit = false end
                end

                -- Remove hostile BodyMovers placed on HumanoidRootPart by enemies
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, child in ipairs(hrp:GetChildren()) do
                        local name = child.Name
                        -- Preserve our own flight / boost / dash movers
                        if (child:IsA("BodyVelocity") or child:IsA("BodyPosition") or child:IsA("BodyGyro"))
                            and not string.find(name, "Darling")
                            and not string.find(name, "Sanguine")
                            and not string.find(name, "NinjaDash")
                            and not string.find(name, "Fly") then
                            child:Destroy()
                        end
                    end
                end
            end)
        end)
    elseif not state and RaceAwakening.AntiStunConnection then
        pcall(function() RaceAwakening.AntiStunConnection:Disconnect() end)
        RaceAwakening.AntiStunConnection = nil
    end
end

function RaceAwakening.destroy()
    RaceAwakening.setAutoV3(false)
    RaceAwakening.setAutoV4(false)
    RaceAwakening.setAntiStun(false)
end

function RaceAwakening.getDiagnostics()
    local connCount = RaceAwakening.AntiStunConnection and 1 or 0
    local threadCount = 0
    if RaceAwakening.V3Thread then threadCount = threadCount + 1 end
    if RaceAwakening.V4Thread then threadCount = threadCount + 1 end
    return {
        Connections = connCount,
        Threads = threadCount,
        Active = RaceAwakening.AutoV3 or RaceAwakening.AutoV4 or RaceAwakening.AntiStun,
    }
end

return RaceAwakening
