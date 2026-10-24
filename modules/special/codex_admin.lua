--[[
    Darling Hub - Admin Animation
    Cinematic admin cutscene with custom lighting and camera angles.
]]--

local CodexAdmin = {
    ActiveSession = nil,
}

local function runAnimation(customConfig)
    --[[
     CELESTIAL SOVEREIGN V2.2 -- inicio inmediato y carga de avatares en segundo plano.
     Ejecutar entero en el cliente / LocalScript en StarterPlayerScripts, modo Play.
     Sin textos, nombres flotantes, botones, barras ni franjas de cine.
     X cancela. Reejecutar reemplaza la escena anterior y restaura sus cambios.
     _G.DarlingSovereign.Stop() tambien cancela.
     Avatares reales, poses procedurales R6/R15, estrella solida, rayos volumetricos,
     plasma texturizado, cristales facetados, vapor, estelas y 12 tomas de camara.
     Referencias estudiadas: transcendence_dragon.lua y kings_throne.lua de Darling-hub.
     Sus texturas/audio se precargan; ningun Lua remoto se descarga o ejecuta.
     Las replicas y la destruccion son visuales: no afectan a otros jugadores.
    ]]
    local CONFIG = {
        GiantHeight = 650, OwnerHeight = 48, Duration = 40,
        Quality = "High",
        Audio = true, HideGameUI = true,
        Music = "rbxassetid://90089940136467",
        Impact = "rbxassetid://157878578", Roar = "rbxassetid://9069609200",
        Rumble = "rbxassetid://9114223171",
    }
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do CONFIG[k] = v end
    end
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local UserInputService = game:GetService("UserInputService")
    local HttpService = game:GetService("HttpService")
    local ContentProvider = game:GetService("ContentProvider")
    local player = Players.LocalPlayer
    if not player then warn("[Sovereign] Ejecutar en el CLIENTE de Roblox."); return end
    local env = _G
    if type(getgenv) == "function" then local ok, e = pcall(getgenv); if ok and type(e) == "table" then env = e end end
    local old = env.DarlingSovereign or _G.DarlingSovereign
    if type(old) == "table" and type(old.Stop) == "function" then pcall(old.Stop) end
    local api = { IsPlaying = true, Version = 2.2, Status = "starting" }
    env.DarlingSovereign, _G.DarlingSovereign = api, api
    env.DarlingSovereignLastError, _G.DarlingSovereignLastError = nil, nil
    
    local V3, CF, PI = Vector3.new, CFrame.new, math.pi
    local WHITE = Color3.fromRGB(255, 251, 238)
    local GOLD = Color3.fromRGB(255, 176, 53)
    local CYAN = Color3.fromRGB(70, 218, 255)
    local PURPLE = Color3.fromRGB(142, 54, 255)
    local METAL = Color3.fromRGB(142, 105, 51)
    local rng, low = Random.new(), CONFIG.Quality == "Low"
    local TEX = { spark = "rbxassetid://2581273950", mist = "rbxassetid://12865656309",
        glint = "rbxassetid://94431438472232", plasma = "rbxassetid://6034176465" }
    local dead, accepting, bound, elapsed, started = false, true, false, 0, nil
    local scene, gui, screenFlash, cam, character, root, humanoid, base
    local cleanupItems, connections, hiddenParts, hiddenGuis, rigs = {}, {}, {}, {}, {}
    local saved, incoming, effects, flags, S = {}, {}, {}, {}, {}
    local bindName = "SovereignV2_" .. HttpService:GenerateGUID(false)
    local flashPower, shake = 0, 0
    local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
    local function ease(x) x = clamp(x, 0, 1); return x*x*(3-2*x) end
    local function phase(t,a,b) return ease((t-a)/(b-a)) end
    local function mix(a,b,t) return a+(b-a)*t end
    local function angles(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
    local function out(x) return 1-(1-clamp(x,0,1))^4 end
    local function world(x,y,z) return base * V3(x,y,z) end
    local function keep(o) cleanupItems[#cleanupItems+1]=o; return o end
    local function connect(signal, fn) local c=signal:Connect(fn); connections[#connections+1]=c; return c end
    local function make(class, props, parent)
        local obj=Instance.new(class)
        for k,v in pairs(props or {}) do obj[k]=v end
        obj.Parent=parent; return obj
    end
    local function stop(reason)
        if dead then return end
        dead, accepting, api.IsPlaying = true, false, false
        api.Status=reason=="finished" and "finished" or "stopped"
        if reason and reason~="finished" and reason~="cancelled" then
            api.LastError=tostring(reason)
            env.DarlingSovereignLastError=api.LastError
            _G.DarlingSovereignLastError=api.LastError
        end
        if bound then pcall(function() RunService:UnbindFromRenderStep(bindName) end) end
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        for _,o in ipairs(cleanupItems) do pcall(function() o:Destroy() end) end
        for _,o in pairs(incoming) do pcall(function() o:Destroy() end) end
        for p,v in pairs(hiddenParts) do pcall(function() p.LocalTransparencyModifier=v end) end
        for g,v in pairs(hiddenGuis) do pcall(function() g.Enabled=v end) end
        if saved.root then pcall(function() saved.root.Anchored=saved.anchored end) end
        if saved.humanoid then pcall(function()
            saved.humanoid.WalkSpeed=saved.walkSpeed; saved.humanoid.AutoRotate=saved.autoRotate
            saved.humanoid.JumpPower=saved.jumpPower; saved.humanoid.JumpHeight=saved.jumpHeight
        end) end
        if saved.camera then pcall(function()
            saved.camera.CameraType=saved.cameraType; saved.camera.CameraSubject=saved.subject
            saved.camera.CFrame=saved.cameraCF; saved.camera.FieldOfView=saved.fov; saved.camera.Focus=saved.focus
        end) end
        for key,value in pairs(saved.lighting or {}) do pcall(function() Lighting[key]=value end) end
        for obj,values in pairs(saved.atmospheres or {}) do
            for key,value in pairs(values) do pcall(function() obj[key]=value end) end
        end
        for obj,value in pairs(saved.postFX or {}) do pcall(function() obj.Enabled=value end) end
        if env.DarlingSovereign==api then env.DarlingSovereign=nil end
        if _G.DarlingSovereign==api then _G.DarlingSovereign=nil end
        if reason and reason~="finished" and reason~="cancelled" then warn("[Sovereign] "..tostring(reason)) end
    end
    api.Stop=function() stop("cancelled") end
    local function part(name,color,size,parent,class)
        return make(class or "Part", { Name=name, Anchored=true, CanCollide=false, CanQuery=false,
            CanTouch=false, CastShadow=false, Material=Enum.Material.Neon, Color=color,
            Size=size or V3(1,1,1), Transparency=1,
            TopSurface=Enum.SurfaceType.Smooth, BottomSurface=Enum.SurfaceType.Smooth }, parent or scene)
    end
    local function ball(name,color)
        local p=part(name,color); p.Shape=Enum.PartType.Ball; return p
    end
    local function orb(p,position,size,alpha)
        size=math.max(0.05,size); p.Size=V3(size,size,size); p.CFrame=CF(position); p.Transparency=1-clamp(alpha,0,1)
    end
    -- Cilindro con volumen. No barras rectangulares ni circulos de segmentos.
    local function tube(p,a,b,width,alpha)
        local len=(b-a).Magnitude
        if len<0.001 or alpha<=0 then p.Transparency=1; return end
        p.Shape=Enum.PartType.Cylinder
        p.Size=V3(math.min(len,2048),math.max(0.03,width),math.max(0.03,width))
        p.CFrame=CFrame.lookAt((a+b)*0.5,b)*angles(0,90,0)
        p.Transparency=1-clamp(alpha,0,1)
    end
    local function flash(power,kick) flashPower=math.max(flashPower,power); shake=math.max(shake,kick or 0) end
    local function sound(id,volume,looped)
        if not CONFIG.Audio or id=="" then return nil end
        return make("Sound",{SoundId=id,Volume=volume,Looped=looped or false},gui)
    end
    local function play(s) if s then pcall(function() s.TimePosition=0; s:Play() end) end end
    local function event(name,time,fn)
        if elapsed>=time and not flags[name] then flags[name]=true; fn() end
    end
    local function every(name,period,fn)
        if not flags[name] or elapsed-flags[name]>=period then flags[name]=elapsed; fn() end
    end
    local function seq(points)
        local result={}; for _,p in ipairs(points) do result[#result+1]=NumberSequenceKeypoint.new(p[1],p[2]) end
        return NumberSequence.new(result)
    end
    local function emitter(parent,kind,color,size,speed,life,rate)
        return make("ParticleEmitter",{
            Texture=TEX[kind], Color=ColorSequence.new(WHITE,color), LightEmission=1,
            LightInfluence=0, Lifetime=NumberRange.new(life*0.65,life),
            Speed=NumberRange.new(speed*0.5,speed), SpreadAngle=Vector2.new(180,180),
            Size=seq({{0,size*0.25},{0.15,size},{0.65,size*0.6},{1,0}}),
            Transparency=seq({{0,0.1},{0.6,0.25},{1,1}}), Drag=1.5,
            Rotation=NumberRange.new(-180,180), RotSpeed=NumberRange.new(-60,60),
            Rate=(rate or 0)*(low and 0.45 or 1), Enabled=false,
        },parent)
    end
    local function spray(position,color,size,count,speed,kind)
        local holder=part("Burst",color); holder.CFrame=CF(position)
        local e=emitter(holder,kind or "spark",color,size,speed,2.1,0)
        e:Emit(math.floor(count*(low and 0.45 or 1)))
        effects[#effects+1]={obj=holder,born=elapsed,life=2.5}
    end
    local function mist(position,size,color,count)
        local p=part("LuminousVapor",color); p.CFrame=CF(position)
        local e=emitter(p,"mist",color,size,size*0.3,4,0)
        e.LightEmission=0.65; e.Drag=0.5; e.Acceleration=V3(0,10,0)
        e.Size=seq({{0,size*0.2},{0.3,size},{1,size*1.6}})
        e.Transparency=seq({{0,0.82},{0.25,0.68},{1,1}})
        e:Emit(math.floor(count*(low and 0.5 or 1)))
        effects[#effects+1]={obj=p,born=elapsed,life=4.2}
    end
    -- Faceta solida: doble piramide de cuatro caras, construida con WedgeParts.
    -- Permanece visible aunque no carguen meshes externos.
    local function crystal(name,color,parent)
        local m=make("Model",{Name=name},parent or scene)
        if S.diamondReady then
            local p=part("FacetedDiamondMesh",color,nil,m)
            local mesh=make("SpecialMesh",{MeshType=Enum.MeshType.FileMesh,MeshId="rbxassetid://9756362"},p)
            return {model=m,part=p,mesh=mesh,color=color}
        end
        local faces={}
        for i=1,8 do faces[i]=part("Facet",color,nil,m,"WedgePart") end
        return {model=m,faces=faces,color=color}
    end
    local function drawCrystal(c,frame,width,length,alpha,metal)
        if c.mesh then
            c.part.CFrame=frame
            c.mesh.Scale=V3(math.max(width,0.05),math.max(length,0.05),math.max(width,0.05))
            c.part.Transparency=1-clamp(alpha,0,1)
            c.part.Material=metal and Enum.Material.Metal or Enum.Material.Neon
            return
        end
        local half=math.max(length*0.5,0.05); local r=math.max(width*0.5,0.05)
        for i,p in ipairs(c.faces) do
            local top=i<=4; local side=(i-1)%4
            p.Size=V3(r,half,r)
            p.CFrame=frame*angles(0,side*90,0)*CF(r*0.5,(top and 1 or -1)*half*0.5,0)
                *(top and CF() or angles(180,0,0))
            p.Transparency=1-clamp(alpha,0,1)
            p.Material=metal and Enum.Material.Metal or Enum.Material.Neon
            p.Color=c.color:Lerp(WHITE,(i%4)*0.09)
        end
    end
    local function plasma(color,width,parent)
        local a=part("PlasmaAnchorA",color,nil,parent)
        local b=part("PlasmaAnchorB",color,nil,parent)
        local aa=make("Attachment",{},a); local ab=make("Attachment",{},b)
        local beam=make("Beam",{Attachment0=aa,Attachment1=ab,Texture=TEX.plasma,
            TextureMode=Enum.TextureMode.Wrap,TextureLength=32,TextureSpeed=4.5,
            Color=ColorSequence.new(WHITE,color),LightEmission=1,LightInfluence=0,
            FaceCamera=true,Width0=width,Width1=width,Segments=24,
            Transparency=NumberSequence.new(1)},a)
        return {a=a,b=b,beam=beam}
    end
    local function drawPlasma(p,a,b,width,alpha,bend)
        p.a.CFrame=CF(a); p.b.CFrame=CF(b)
        p.beam.Width0=width; p.beam.Width1=width*0.75
        p.beam.CurveSize0=bend or 0; p.beam.CurveSize1=-(bend or 0)
        p.beam.Transparency=NumberSequence.new(1-clamp(alpha,0,1))
    end
    local function bolt(color,count)
        local b={pieces={},color=color,count=count or (low and 14 or 22)}
        for i=1,b.count do b.pieces[i]={core=part("LightningCore",WHITE),glow=part("LightningCorona",color)} end
        return b
    end
    local function drawBolt(b,a,z,width,alpha,seed)
        if alpha<=0 then for _,p in ipairs(b.pieces) do p.core.Transparency=1; p.glow.Transparency=1 end; return end
        local len=(z-a).Magnitude; if len<0.1 then return end
        local axis=CFrame.lookAt(a,z); local previous=a
        local frame=math.floor(elapsed*24)
        for i,p in ipairs(b.pieces) do
            local t=i/b.count
            local jag=math.sin(t*PI)*len*0.035
            local point=a+(z-a)*t+axis.RightVector*math.noise(i*3.7,frame,seed)*jag
                +axis.UpVector*math.noise(seed,i*7.3,frame)*jag
            tube(p.core,previous,point,width,alpha)
            tube(p.glow,previous,point,width*3.5,alpha*0.24)
            previous=point
        end
    end
    local function detonation(position,radius,color,life,kind)
        -- Fractura volumetrica irregular. Ninguna esfera ni superficie circular.
        local ground=kind=="ground"
        local group=make("Folder",{Name=ground and "ShatteredGround" or "StellarFracture"},scene)
        local fx={obj=group,fracture=true,born=elapsed,life=life or 1.6,pos=position,
            radius=radius,ground=ground,shards={},cracks={}}
        local count=low and 12 or (ground and 32 or 26)
        for i=1,count do
            local direction=V3(rng:NextNumber(-1,1),rng:NextNumber(ground and 0.25 or -0.9,1),rng:NextNumber(-1,1))
            if direction.Magnitude<0.1 then direction=V3(0,1,0) end
            direction=direction.Unit
            local width=radius*rng:NextNumber(0.008,0.022)
            local length=width*rng:NextNumber(2.5,5)
            local c=crystal(ground and "BrokenStone" or "SolarSplinter",ground and Color3.fromRGB(66,62,73) or (i%3==0 and WHITE or color),group)
            local wake=plasma(i%3==0 and CYAN or color,width*0.45,group)
            local origin=position+V3(rng:NextNumber(-1,1),ground and 0 or rng:NextNumber(-1,1),rng:NextNumber(-1,1))*radius*0.08
            fx.shards[i]={c=c,wake=wake,direction=direction,origin=origin,width=width,length=length,
                speed=radius*rng:NextNumber(0.28,0.65),spin=V3(rng:NextNumber(-160,160),rng:NextNumber(-160,160),rng:NextNumber(-160,160))}
            if ground and i%5==0 then
                mist(origin,math.min(65,radius*0.09),Color3.fromRGB(190,183,170),4)
            end
        end
        if ground then
            for i=1,low and 5 or 9 do
                local direction=V3(rng:NextNumber(-1,1),0,rng:NextNumber(-1,1))
                if direction.Magnitude<0.1 then direction=V3(1,0,0) end
                direction=direction.Unit
                local points={position+V3(0,0.5,0)}
                local reach=radius*rng:NextNumber(0.2,0.75)
                local side=V3(-direction.Z,0,direction.X)
                local beams={}
                for j=1,4 do
                    points[j+1]=position+direction*(reach*j/4)+side*rng:NextNumber(-reach*0.09,reach*0.09)+V3(0,0.5,0)
                    beams[j]=plasma(j%2==0 and WHITE or color,math.max(0.5,radius*0.004),group)
                end
                fx.cracks[i]={points=points,beams=beams}
            end
        end
        effects[#effects+1]=fx
        spray(position,color,math.min(14,radius*0.018),low and 100 or 220,radius*0.35,"spark")
        spray(position,WHITE,math.min(28,radius*0.025),low and 24 or 55,radius*0.25,"glint")
    end
    local function cloneCharacter()
        local arch=character.Archivable; character.Archivable=true
        local ok,model=pcall(function() return character:Clone() end)
        character.Archivable=arch
        if not ok or not model then error("No se pudo copiar tu avatar real.") end
        return model
    end
    
    local function prepareRig(model, scale, label, color)
        keep(model)
        model.Name = label
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") or obj:IsA("Tool") or obj:IsA("Animator")
                or obj:IsA("Sound") or obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                or obj:IsA("Beam") or obj:IsA("Highlight") or obj:IsA("BillboardGui")
                or obj:IsA("ForceField") then obj:Destroy() end
        end
        local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
        if not hrp then error("Avatar sin raiz: " .. label) end
        model.PrimaryPart = hrp
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.AutoRotate = false
            hum.BreakJointsOnDeath = false
            hum.RequiresNeck = false
        end
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
                p.LocalTransparencyModifier = 0
                p.AssemblyLinearVelocity, p.AssemblyAngularVelocity = V3(0, 0, 0), V3(0, 0, 0)
            end
        end
        -- Normaliza altura corporal, independientemente de la escala previa del juego.
        local minY,maxY=math.huge,-math.huge
        for _,p in ipairs(model:GetChildren()) do
            if p:IsA("BasePart") and p~=hrp then
                minY=math.min(minY,p.Position.Y-p.Size.Y*0.5)
                maxY=math.max(maxY,p.Position.Y+p.Size.Y*0.5)
            end
        end
        if scale then
            model:ScaleTo(model:GetScale()*scale/math.max(1,maxY-minY))
        end
        scale=model:GetScale()
        local rig = { model = model, root = hrp, parts = {}, edges = {}, loose = {}, scale = scale, alpha = -1, color = color }
        local links, joints = {}, {}
        local bottom = hrp.Position.Y
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                rig.parts[obj] = obj == hrp and 1 or obj.Transparency
                if obj.Parent == model then bottom = math.min(bottom, obj.Position.Y - obj.Size.Y * 0.5) end
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                rig.parts[obj] = obj.Transparency
            elseif obj:IsA("JointInstance") or obj:IsA("WeldConstraint") then
                joints[#joints + 1] = obj
                local a, b = obj.Part0, obj.Part1
                if a and b and a:IsDescendantOf(model) and b:IsDescendantOf(model) then
                    local c0, c1 = a.CFrame:ToObjectSpace(b.CFrame), CF()
                    if obj:IsA("JointInstance") then c0, c1 = obj.C0, obj.C1 end
                    links[#links + 1] = { a = a, b = b, c0 = c0, c1 = c1,
                        name = obj.Name:gsub("%s", ""), motor = obj:IsA("Motor6D") }
                end
            end
        end
        rig.height = hrp.Position.Y - bottom
        local reached = { [hrp] = true }
        local changed = true
        while changed do
            changed = false
            for _, link in ipairs(links) do
                if reached[link.a] and not reached[link.b] then
                    rig.edges[#rig.edges + 1] = link; reached[link.b] = true; changed = true
                elseif reached[link.b] and not reached[link.a] then
                    rig.edges[#rig.edges + 1] = { a = link.b, b = link.a, c0 = link.c1, c1 = link.c0, name = link.name, reverse = true, motor = link.motor }
                    reached[link.a] = true; changed = true
                end
            end
        end
        for p in pairs(rig.parts) do
            if p:IsA("BasePart") and not reached[p] then rig.loose[p] = hrp.CFrame:ToObjectSpace(p.CFrame) end
        end
        for _, joint in ipairs(joints) do joint:Destroy() end
        -- Estos actores estan anclados; ninguna constraint debe arrastrarlos.
        for _, obj in ipairs(model:GetDescendants()) do if obj:IsA("Constraint") then obj:Destroy() end end
        rig.highlight = make("Highlight", {
            FillColor = color, OutlineColor = WHITE, FillTransparency = 0.97,
            OutlineTransparency = 0.7, DepthMode = Enum.HighlightDepthMode.Occluded, Enabled = false,
        }, model)
        for p in pairs(rig.parts) do p.Transparency = 1 end
        model.Parent = scene
        rigs[#rigs + 1] = rig
        return rig
    end
    
    local function visibility(rig, alpha)
        alpha = clamp(alpha, 0, 1)
        if math.abs(rig.alpha - alpha) < 0.0001 then return end
        rig.alpha = alpha
        for p, original in pairs(rig.parts) do p.Transparency = 1 - (1 - original) * alpha end
        rig.highlight.Enabled = alpha > 0.05
        rig.highlight.OutlineTransparency = 1 - 0.3 * alpha
    end
    
    
    
    local function poseRig(rig,frame,mode,a,t,groundY)
        rig.root.CFrame=frame
        local p={}
        local breathing=math.sin(t*1.8)*1.8
        p.Neck=angles(breathing,0,0)
        p.RightShoulder=angles(0,0,4+breathing)
        p.LeftShoulder=angles(0,0,-4-breathing)
        if mode=="invoke" then
            local wind=phase(t,0.4,2); local release=phase(t,2,3.35)
            p.RootJoint=angles(12*wind-20*release,0,0)
            p.Waist=angles(8*wind-18*release,0,0)
            p.Neck=angles(-32*release,0,0)
            p.RightShoulder=angles(mix(-30,-172,release)*a,0,mix(30,8,release)*a)
            p.LeftShoulder=angles(-42*wind*a,0,-36*wind*a)
            p.RightElbow=angles(-60*(1-release)*a,0,0)
            p.LeftElbow=angles(-45*wind*a,0,0)
        elseif mode=="emerge" then
            p.RootJoint=angles(-9*a,0,0); p.Waist=angles(-10*a,0,0)
            p.RightShoulder=angles(-28*a,0,72*a); p.LeftShoulder=angles(-28*a,0,-72*a)
            p.RightElbow=angles(-15*a,0,0); p.LeftElbow=angles(-15*a,0,0)
            p.RightHip=angles(-15*a,0,7*a); p.LeftHip=angles(12*a,0,-7*a)
            p.RightKnee=angles(18*a,0,0); p.Neck=angles(-22*a,0,0)
        elseif mode=="land" then
            p.RootJoint=angles(20*a,0,0); p.Waist=angles(15*a,0,0)
            p.RightHip=angles(-24*a,0,6*a); p.LeftHip=angles(-24*a,0,-6*a)
            p.RightKnee=angles(42*a,0,0); p.LeftKnee=angles(42*a,0,0)
            p.RightShoulder=angles(-12*a,0,26*a); p.LeftShoulder=angles(-12*a,0,-26*a)
        elseif mode=="kneel" then
            local bow=phase(t,23.05,24.5)
            -- Ejes Roblox: +X lleva el muslo hacia delante (-Z).
            -- Rodilla izquierda abajo; pie derecho delante. El torso se inclina
            -- hacia el gigante DESPUES de apoyar la pierna, no hacia atras.
            p.RootJoint=angles(-4*a,0,0); p.Root=angles(-4*a,0,0)
            p.Waist=angles(-19*bow,0,0); p.Neck=angles(-27*bow,0,0)
            p.RightHip=angles(94*a,0,0); p.LeftHip=angles(4*a,0,0)
            p.RightKnee=angles(-90*a,0,0); p.LeftKnee=angles(-96*a,0,0)
            p.RightAnkle=CF(); p.LeftAnkle=angles(90*a,0,0)
            p.RightShoulder=angles(55*a,0,-8*a); p.LeftShoulder=angles(35*a,0,8*a)
            p.RightElbow=angles(58*a,0,0); p.LeftElbow=angles(78*a,0,0)
            p.RightWrist=angles(-15*a,0,0); p.LeftWrist=angles(-12*a,0,0)
        elseif mode=="snap" then
            local recoil=math.exp(-math.max(0,t-29.65)*12)*(t>=29.65 and 1 or 0)
            p.RightShoulder=angles(-103*a,-12*a,18*a)
            p.RightElbow=angles(-70*a,0,0)
            p.RightWrist=angles(-18*recoil,0,28*a-52*recoil)
            p.Neck=angles(17*a,-14*a,0); p.Waist=angles(0,-6*a,0)
        end
        for _,edge in ipairs(rig.edges) do
            local rotation=(edge.motor and p[edge.name]) or CF()
            local basis=edge.c0-edge.c0.Position
            local transform=basis:Inverse()*rotation*basis
            if edge.reverse then transform=transform:Inverse() end
            edge.b.CFrame=edge.a.CFrame*edge.c0*transform*edge.c1:Inverse()
        end
        for part0,relative in pairs(rig.loose) do part0.CFrame=frame*relative end
        if mode=="kneel" and groundY then
            -- Apoyo calculado con la geometria y la rotacion reales de los pies
            -- y la rodilla: evita flotar o atravesar el suelo al doblar el rig.
            local lowest=math.huge
            for _,name in ipairs({"RightFoot","LeftFoot","LeftLowerLeg","Right Leg","Left Leg"}) do
                local part0=rig.model:FindFirstChild(name)
                if part0 then
                    local half=math.abs(part0.CFrame.RightVector.Y)*part0.Size.X*0.5
                        +math.abs(part0.CFrame.UpVector.Y)*part0.Size.Y*0.5
                        +math.abs(part0.CFrame.LookVector.Y)*part0.Size.Z*0.5
                    lowest=math.min(lowest,part0.Position.Y-half)
                end
            end
            if lowest<math.huge then
                local shift=V3(0,groundY+0.12-lowest,0)
                for part0 in pairs(rig.parts) do
                    if part0:IsA("BasePart") then part0.CFrame=part0.CFrame+shift end
                end
            end
        end
    end
    
    -- Apariencias publicas consultadas el 24-10-2026. Solo se usan si falla
    -- la consulta de la descripcion actual. Sin maniquies de piezas inventados.
    local OWNER_DATA={
        {name="mygame43",id=912348,colors={21,21,21,21,21,21},
            properties={Shirt=3039069,Pants=3369926,Head=14488197116,HatAccessory="1098272",FaceAccessory="137807345212186"}},
        {name="rip_indra",id=3095250,colors={5,106,5,5,26,26},
            properties={HatAccessory="1031429",FaceAccessory="10911979"}},
    }
    local function cachedDescription(data)
        local d=Instance.new("HumanoidDescription")
        for k,v in pairs(data.properties) do d[k]=v end
        local keys={"HeadColor","TorsoColor","RightArmColor","LeftArmColor","RightLegColor","LeftLegColor"}
        for i,k in ipairs(keys) do d[k]=BrickColor.new(data.colors[i]).Color end
        return d
    end
    local function fetchOwner(i,data,cached)
        local desc,model
        local ok,err=pcall(function()
            if cached then
                desc=cachedDescription(data)
            else
                local got,result=pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(data.id) end)
                if not got then got,result=pcall(function() return Players:GetHumanoidDescriptionFromUserId(data.id) end) end
                desc=got and result or cachedDescription(data)
            end
            if dead or not accepting then return end
            -- R15 para poder doblar rodilla/codo; conserva ropa, cabeza y accesorios.
            local made,result=pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15) end)
            if not made then made,result=pcall(function() return Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15) end) end
            if not made then made,result=pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(data.id) end) end
            if not made then error(result) end
            model=result
        end)
        if desc then pcall(function() desc:Destroy() end) end
        if model then
            if not dead and accepting and not incoming[i] then incoming[i]=model else model:Destroy() end
        elseif not ok then warn("[Sovereign] "..data.name..": "..tostring(err)) end
    end
    
    local function adoptOwners()
        if dead then return end
        for i,data in ipairs(OWNER_DATA) do
            if incoming[i] and not S.owners[i] then
                local model=incoming[i]; incoming[i]=nil
                local ok,rig=pcall(prepareRig,model,CONFIG.OwnerHeight,data.name,i==1 and CYAN or PURPLE)
                if ok then
                    rig.arrivalTime=math.max(20+(i-1)*0.35,elapsed)
                    S.owners[i]=rig
                else
                    pcall(function() model:Destroy() end)
                    warn("[Sovereign] No se pudo preparar "..data.name..": "..tostring(rig))
                end
            end
        end
        if S.owners[1] and S.owners[2] then accepting=false end
    end
    
    local function trailOn(part0,color,width)
        local a=make("Attachment",{Position=V3(-width*0.5,0,0)},part0)
        local b=make("Attachment",{Position=V3(width*0.5,0,0)},part0)
        return make("Trail",{Attachment0=a,Attachment1=b,Lifetime=0.8,MinLength=0.1,
            FaceCamera=true,LightEmission=1,Texture=TEX.plasma,TextureLength=20,
            Color=ColorSequence.new(WHITE,color),Transparency=seq({{0,0.1},{0.6,0.4},{1,1}}),
            WidthScale=NumberSequence.new(1,0),Enabled=false},part0)
    end
    local function buildScene()
        S.actor=prepareRig(cloneCharacter(),nil,player.Name.."_Witness",GOLD)
        S.giant=prepareRig(cloneCharacter(),CONFIG.GiantHeight,player.Name.."_Sovereign",GOLD)
        S.owners={}
        adoptOwners()
        S.star={core=crystal("FivePointStar_Heart",WHITE),spikes={},rays={},plasma={}}
        for i=1,5 do
            S.star.spikes[i]={outer=crystal("SolarPoint_"..i,GOLD),inner=crystal("WhiteHotPoint_"..i,WHITE)}
        end
        for i=1,low and 16 or 32 do S.star.rays[i]=crystal("CoronalBlade",i%3==0 and CYAN or GOLD) end
        for i=1,5 do S.star.plasma[i]=plasma(i%2==0 and CYAN or GOLD,30) end
        S.star.anchor=part("StarRadiance",GOLD)
        S.star.sparks=emitter(S.star.anchor,"spark",GOLD,14,180,3,90)
        S.star.glints=emitter(S.star.anchor,"glint",WHITE,60,100,2,35)
        S.star.vapor=emitter(S.star.anchor,"mist",GOLD,180,90,4,8)
        S.star.vapor.Transparency=seq({{0,1},{0.25,0.82},{1,1}})
        S.star.light=make("PointLight",{Color=GOLD,Brightness=0,Range=60,Shadows=false},S.star.anchor)
    
        S.charge={core=crystal("GenesisCrystal",WHITE),shards={},streamers={}}
        for i=1,low and 8 or 14 do S.charge.shards[i]=crystal("GatheringCrystal",i%2==0 and CYAN or GOLD) end
        for i=1,6 do S.charge.streamers[i]=plasma(i%2==0 and CYAN or GOLD,1.5) end
        S.beam={core=part("HeavenSplitterCore",WHITE),mid=part("HeavenSplitterInner",CYAN),outer=part("HeavenSplitterCorona",PURPLE),plasma={},bolts={}}
        for i=1,4 do S.beam.plasma[i]=plasma(i%2==0 and GOLD or CYAN,42); S.beam.bolts[i]=bolt(CYAN) end
        S.levitation={}
        for i=1,low and 16 or 28 do
            local p=part("FloatingDebris",Color3.fromRGB(55,54,66),V3(2+(i%4),3+(i%3),2+(i%4)))
            p.Material=Enum.Material.Slate; S.levitation[i]=p
        end
    
        -- Corona escultorica: puntas solidas, metales y aristas luminosas.
        S.crown={spikes={},base={}}
        for i=1,11 do
            S.crown.spikes[i]=crystal("Crown_SolidSpire",i%2==0 and GOLD or METAL)
            S.crown.base[i]=part("Crown_GoldSetting",METAL,V3(16,10,14),nil,"WedgePart")
            S.crown.base[i].Material=Enum.Material.Metal
        end
        S.back={}
        for i=1,8 do S.back[i]=plasma(i%2==0 and GOLD or CYAN,32) end
        S.shoulders={}
        for i=1,6 do S.shoulders[i]=crystal("SolarShoulderFacet",i%3==0 and WHITE or GOLD) end
        S.wristTrails={}
        for _,name in ipairs({"RightHand","LeftHand","Right Arm","Left Arm","RightFoot","LeftFoot"}) do
            local p=S.giant.model:FindFirstChild(name)
            if p then S.wristTrails[#S.wristTrails+1]=trailOn(p,GOLD,p.Size.X*0.8) end
        end
        S.bodyEmitters={}
        for _,name in ipairs({"UpperTorso","Torso","RightHand","LeftHand","Right Arm","Left Arm"}) do
            local p=S.giant.model:FindFirstChild(name)
            if p then
                local e=emitter(p,"glint",GOLD,14,18,2.5,8)
                S.bodyEmitters[#S.bodyEmitters+1]=e
            end
        end
        S.dust={}
        for i=1,low and 8 or 18 do
            local anchor=part("AtmosphericEmbers",GOLD)
            local a=i*2.399
            anchor.CFrame=CF(world(math.cos(a)*370,20+(i%6)*80,-500+math.sin(a)*300))
            local e=emitter(anchor,"spark",i%2==0 and CYAN or GOLD,4,12,4,8)
            S.dust[i]=e
        end
        S.fingers={}
        for i=1,8 do
            local p=part("ArticulatedAstralFinger",WHITE); p.Shape=Enum.PartType.Ball
            S.fingers[i]=p
        end
        S.snapOrb=ball("SnapSingularity",WHITE)
        S.judgement={}
        for i=1,2 do S.judgement[i]={bolt=bolt(GOLD,26),sky=bolt(CYAN,26),beam=plasma(GOLD,20)} end
        S.meteors={}
        for i=1,low and 12 or 24 do S.meteors[i]=crystal("SolarEjecta",i%2==0 and GOLD or CYAN) end
        S.ownerPortals={}
        for i=1,2 do
            S.ownerPortals[i]={spines={}}
            for j=1,5 do S.ownerPortals[i].spines[j]=crystal("ArrivalCrystal",i==1 and CYAN or PURPLE) end
        end
        S.audio={impact=sound(CONFIG.Impact,1.1),roar=sound(CONFIG.Roar,0.8),rumble=sound(CONFIG.Rumble,0.45,true),
            snap=sound("rbxasset://sounds/switch.wav",1.4),music=sound(CONFIG.Music,0.7)}
    end
    
    local function annihilate(rig)
        -- Desintegra la geometria REAL (ropa, MeshParts y accesorios), no cubos.
        local count=0
        for p,original in pairs(rig.parts) do
            if p:IsA("BasePart") and original<0.95 and count<(low and 22 or 55) then
                count=count+1
                local copy=p:Clone()
                for _,child in ipairs(copy:GetDescendants()) do
                    if child:IsA("JointInstance") or child:IsA("Constraint") or child:IsA("LuaSourceContainer")
                        or child:IsA("SurfaceAppearance") or child:IsA("Decal") then child:Destroy() end
                end
                if copy:IsA("MeshPart") then copy.TextureID="" end
                for _,mesh in ipairs(copy:GetChildren()) do if mesh:IsA("SpecialMesh") then mesh.TextureId="" end end
                copy.Material=Enum.Material.Neon; copy.Color=count%2==0 and GOLD or WHITE
                copy.Transparency=0; copy.Anchored=true; copy.CanCollide=false; copy.Parent=scene
                local dust=emitter(copy,"spark",GOLD,4,55,1.8,0); dust:Emit(low and 12 or 28)
                effects[#effects+1]={obj=copy,body=true,born=elapsed,life=2.2+rng:NextNumber()*0.7,
                    origin=p.CFrame,velocity=V3(rng:NextNumber(-45,45),rng:NextNumber(35,80),rng:NextNumber(-45,45)),size=p.Size}
            end
        end
        visibility(rig,0)
        detonation(rig.root.Position,180,GOLD,1.25)
    end
    
    local function updateEffects()
        for i=#effects,1,-1 do
            local e=effects[i]; local age=elapsed-e.born; local t=age/e.life
            if t>=1 then
                if e.obj then e.obj:Destroy() end; if e.core then e.core:Destroy() end
                table.remove(effects,i)
            elseif e.fracture then
                local alpha=1-phase(t,0.45,1)
                for j,s in ipairs(e.shards) do
                    local distance=s.speed*age*(e.ground and 1 or (0.55+t*0.8))
                    local pos=s.origin+s.direction*distance
                    if e.ground then
                        pos=pos-V3(0,e.radius*0.12*age*age,0)
                        pos=V3(pos.X,math.max(e.pos.Y+s.width*0.5,pos.Y),pos.Z)
                    end
                    local f=CFrame.lookAt(pos,pos+s.direction)*angles(90+s.spin.X*age,s.spin.Y*age,s.spin.Z*age)
                    drawCrystal(s.c,f,s.width*(1-t*0.35),s.length*(1-t*0.25),alpha,e.ground)
                    local tail=pos-s.direction*math.min(distance,s.length*(2+t*3))
                    drawPlasma(s.wake,tail,pos,s.width*(e.ground and 0.2 or 0.5),alpha*0.7,0)
                end
                for _,crack in ipairs(e.cracks) do
                    for j,p in ipairs(crack.beams) do
                        local reveal=phase(t,0.025*(j-1),0.025*j+0.06)
                        drawPlasma(p,crack.points[j],crack.points[j+1],math.max(0.5,e.radius*0.004),reveal*alpha*0.85,0)
                    end
                end
            elseif e.body then
                e.obj.CFrame=(e.origin+e.velocity*age+V3(0,20*age*age,0))*angles(t*150,t*220,0)
                e.obj.Size=e.size*math.max(0.02,1-t*0.94)
                e.obj.Transparency=t^0.55
            end
        end
    end
    
    -- Camara: cortes deliberados, orbitas, contrapicados y cambios de velocidad.
    -- Camera.Value+10 gana a la camara normal; no se acumula error de interpolacion.
    local function cinematicCamera(t,dt)
        local position,focus,fov,roll
        roll=0
        local head=S.giant.model:FindFirstChild("Head") or S.giant.root
        if t<3.35 then
            local p=clamp(t/3.35,0,1); local a=-1.4+p*3.7
            local r=15-5*p
            position=world(math.sin(a)*r,3+7*p,math.cos(a)*r)
            focus=world(0,5+p*3,0); fov=74-p*16; roll=math.sin(p*PI)*-9
        elseif t<6 then
            local p=out((t-3.35)/2.65)
            position=world(mix(6,95,p),mix(8,160,p),mix(12,130,p))
            focus=world(0,mix(10,820,p),0); fov=mix(58,100,p); roll=mix(-10,6,p)
        elseif t<8.4 then
            local p=(t-6)/2.4; local a=-0.5+p*1.9
            position=world(math.sin(a)*390,650+p*180, -760+math.cos(a)*480)
            focus=S.starPos; fov=94-20*p; roll=10-20*p
        elseif t<11.6 then
            local p=clamp((t-8.4)/3.2,0,1); local retreat=out(p)
            position=world(mix(25,900,retreat),mix(780,460,retreat),mix(-340,1250,retreat))
            focus=world(0,mix(850,520,p),-650); fov=62+32*retreat; roll=-12*(1-p)
        elseif t<16 then
            -- Media orbita completa: el mundo y las estelas pasan junto a la lente.
            local p=(t-11.6)/4.4; local a=0.48+p*2.65
            position=world(math.sin(a)*1000,mix(550,125,p),-600+math.cos(a)*1000)
            focus=S.giantPos+V3(0,75,0); fov=84+6*math.sin(p*PI); roll=math.sin(p*PI)*9
        elseif t<18.5 then
            -- Los pies ocupan el primer plano; el craneo sube centenares de studs.
            local p=phase(t,16,18.5)
            position=world(mix(-210,210,p),mix(14,90,p),mix(-330,-180,p))
            focus=world(0,mix(95,300,p),-600); fov=100-16*p; roll=-6+9*p
        elseif t<21 then
            local p=phase(t,18.5,21); local a=-0.6+p*1.1
            position=world(math.sin(a)*480,80+420*p,-600+math.cos(a)*460)
            focus=world(0,mix(250,560,p),-600); fov=80-20*p; roll=5*math.sin(p*PI)
        elseif t<24.6 then
            -- Ambos owners en primer plano y el gigante llenando el fondo.
            local p=(t-21)/3.6
            position=world(mix(-145,155,p),20+18*math.sin(p*PI),-215)
            focus=world(0,65,-425); fov=90; roll=2*math.sin(p*PI*2)
        elseif t<27.1 then
            local p=phase(t,24.6,27.1)
            position=world(mix(155,350,p),mix(38,185,p),mix(-215,120,p))
            focus=world(0,mix(65,285,p),-520); fov=90-18*p; roll=-5*math.sin(p*PI)
        elseif t<29.9 then
            local p=phase(t,27.1,28.8)
            local handClose=S.handPos+base.RightVector*90-base.LookVector*150+V3(0,35,0)
            position=world(350,185,120):Lerp(handClose,p)
            focus=world(0,285,-520):Lerp(S.handPos,p); fov=mix(72,42,p)
            roll=4*math.sin((t-27.1)*1.7)
        elseif t<31 then
            -- Corte al impacto, inmediatamente seguido de un retroceso violento.
            local p=out((t-29.9)/1.1)
            position=world(mix(110,750,p),mix(35,360,p),mix(-150,850,p))
            focus=world(0,140,-420); fov=78+24*p; roll=10*(1-p)
        elseif t<35.5 then
            local p=(t-31)/4.5; local a=0.48+p*1.7
            position=world(math.sin(a)*1250,360+160*math.sin(p*PI),-600+math.cos(a)*1250)
            focus=world(0,310,-600); fov=94-16*p; roll=-4*math.sin(p*PI)
        else
            local p=phase(t,35.5,40)
            local start=world(math.sin(2.18)*1250,360,-600+math.cos(2.18)*1250)
            position=start:Lerp(saved.cameraCF.Position,p)
            focus=world(0,310,-600):Lerp(saved.cameraCF.Position+saved.cameraCF.LookVector*30,p)
            fov=mix(78,saved.fov,p); roll=0
        end
        local movingShake=shake+(t>3.35 and t<8.4 and 0.9 or 0)
        local n=V3(math.noise(t*28,5),math.noise(7,t*31),math.noise(t*25,11))*movingShake
        cam.CameraType=Enum.CameraType.Scriptable
        cam.CFrame=CFrame.lookAt(position,focus)*angles(0,0,roll)*CF(n)
        cam.Focus=CF(focus); cam.FieldOfView=fov
        shake=math.max(0,shake-dt*8)
    end
    
    local function animate(dt)
        if dead then return end
        if not root.Parent or humanoid.Health<=0 or Workspace.CurrentCamera~=cam then stop("cancelled"); return end
        elapsed=os.clock()-started
        local t=elapsed
        if t>=CONFIG.Duration then stop("finished"); return end
        adoptOwners()
        local fade=1-phase(t,36.2,39.5)
        flashPower=math.max(0,flashPower-dt*3.4)
        screenFlash.BackgroundTransparency=1-clamp(flashPower,0,0.88)
        S.bloom.Intensity=1.15+flashPower*1.2
        S.grade.Brightness=0.04+flashPower*0.1
        S.grade.Contrast=0.16+flashPower*0.22
    
        local charge=phase(t,0,1.5)*(1-phase(t,4.5,6))
        poseRig(S.actor,base*CF(0,S.actor.height+phase(t,1.5,3.5)*2*(1-phase(t,5,6)),0),"invoke",1-phase(t,4.5,6),t)
        visibility(S.actor,1)
        local heroHand=S.actor.model:FindFirstChild("RightHand") or S.actor.model:FindFirstChild("Right Arm") or S.actor.root
        local genesis=heroHand.Position+V3(0,3,0)
        drawCrystal(S.charge.core,CF(genesis)*angles(t*130,t*160,15),1+3*charge,2+7*charge,charge)
        for i,c in ipairs(S.charge.shards) do
            local travel=(t*(0.45+i%3*0.1)+i*0.37)%1
            local scatter=V3(math.sin(i*4.7)*26,math.cos(i*2.3)*17+5,math.sin(i*7.1)*23)
            local p=genesis+scatter*(1-travel)^1.5
            drawCrystal(c,CF(p)*angles(t*140,i*30,t*100),0.5+charge,2+charge*3,charge*0.95)
        end
        for i,p in ipairs(S.charge.streamers) do
            local from=world(math.sin(i*5.3)*25,1+(i%3)*4,math.cos(i*3.7)*23)
            drawPlasma(p,from,genesis,0.6+charge*2,charge*0.8,8*math.sin(t*2+i))
        end
        for i,p in ipairs(S.levitation) do
            local a=i*2.399+t*0.25; local rise=phase(t,0.5,3.35)
            p.CFrame=base*CF(math.cos(a)*(15+i%7*3),rise*(3+i%6*3),math.sin(a)*(15+i%7*3))*angles(t*35+i*17,t*25,0)
            p.Transparency=1-charge*0.9
        end
    
        -- Rayo de 1.800 studs con nucleo, corona, 4 capas de plasma y rayos fractales.
        local firing=phase(t,3.3,3.42)*(1-phase(t,7.3,8.5))
        local beamA=world(0,9,0); local beamB=world(0,9+1800*phase(t,3.3,3.6),0)
        tube(S.beam.core,beamA,beamB,10+firing*13,firing*0.97)
        tube(S.beam.mid,beamA,beamB,35+firing*22,firing*0.28)
        tube(S.beam.outer,beamA,beamB,65+firing*20,firing*0.1)
        for i,p in ipairs(S.beam.plasma) do
            local a=i*PI/2+t*3; local offset=V3(math.cos(a)*24,0,math.sin(a)*24)
            drawPlasma(p,beamA+offset,beamB-offset,42,firing*0.8,80*math.sin(t*2+i))
            drawBolt(S.beam.bolts[i],beamA+offset*2,beamB-offset*3,1.3,firing,i*7)
        end
    
        -- Estrella 3D: cinco puntas con ocho facetas, fotosfera y eyecciones.
        local starAlpha=phase(t,6,7.5)*(1-phase(t,13.3,16.5))
        local starGrow=0.25+0.75*out((t-6)/2.6)
        local starFrame=base*CF(0,950,-780)*angles(0,0,8*math.sin(t*0.3))
        S.starPos=starFrame.Position
        drawCrystal(S.star.core,starFrame*angles(t*18,t*23,0),240*starGrow,360*starGrow,starAlpha)
        for i,point in ipairs(S.star.spikes) do
            local a=(i-1)*2*PI/5+PI/2
            local f=starFrame*CF(math.cos(a)*170*starGrow,math.sin(a)*170*starGrow,0)*angles(0,0,math.deg(a)-90)
            drawCrystal(point.outer,f,100*starGrow,450*starGrow,starAlpha*0.95)
            drawCrystal(point.inner,f*CF(0,15,0),43*starGrow,370*starGrow,starAlpha)
            local tip=starFrame*V3(math.cos(a)*390*starGrow,math.sin(a)*390*starGrow,0)
            local to=starFrame*V3(math.cos(a)*(650+math.sin(t*4+i)*80),math.sin(a)*(650+math.sin(t*4+i)*80),-30)
            drawPlasma(S.star.plasma[i],tip,to,35*starGrow,starAlpha*0.75,60)
        end
        for i,c in ipairs(S.star.rays) do
            local a=i*2.399+t*0.07; local r=390+(i%5)*20
            local f=starFrame*CF(math.cos(a)*r,math.sin(a)*r,math.sin(i*7)*90)*angles(0,0,math.deg(a)-90)
            drawCrystal(c,f,9+(i%3)*4,65+(i%6)*18,starAlpha*0.75)
        end
        S.star.anchor.CFrame=CF(S.starPos)
        S.star.sparks.Enabled=starAlpha>0.1; S.star.glints.Enabled=starAlpha>0.1; S.star.vapor.Enabled=starAlpha>0.1
        S.star.light.Brightness=starAlpha*10
    
        local emergence=phase(t,8.5,11.6)
        local descent=phase(t,11.8,17.4)
        local landing=phase(t,17.05,17.45)*(1-phase(t,17.5,18.6))
        local giantY=mix(960,S.giant.height,descent)-landing*18
        local giantZ=mix(-770,-600,emergence)
        S.giantPos=world(0,giantY,giantZ)
        local turn=mix(155,180,phase(t,8.5,13))
        local giantFrame=base*CF(0,giantY,giantZ)*angles(0,turn,0)
        local snap=phase(t,26.5,28.7)*(1-phase(t,31.5,33.5))
        local mode,amount="emerge",1-phase(t,13.5,17)
        if t>=17 and t<20 then mode,amount="land",landing
        elseif t>=26.5 then mode,amount="snap",snap end
        poseRig(S.giant,giantFrame,mode,amount,t)
        local giantAlpha=phase(t,8.55,9.9)*fade
        visibility(S.giant,giantAlpha)
        for _,e in ipairs(S.bodyEmitters) do e.Enabled=giantAlpha>0.1 end
        for _,trail in ipairs(S.wristTrails) do trail.Enabled=giantAlpha>0.1 and t<34 end
        for _,e in ipairs(S.dust) do e.Enabled=t>8.5 and t<37 end
    
        local head=S.giant.model:FindFirstChild("Head") or S.giant.root
        local crownFrame=CF(head.Position+V3(0,head.Size.Y*0.62,0))*(base-base.Position)*angles(0,180,0)
        for i,c in ipairs(S.crown.spikes) do
            local a=(i-1)*2*PI/11
            local r=head.Size.X*0.57
            local f=crownFrame*CF(math.cos(a)*r,26,math.sin(a)*r)*angles(8*math.sin(a),0,-8*math.cos(a))
            drawCrystal(c,f,12,i%2==0 and 80 or 55,giantAlpha,true)
            local setting=S.crown.base[i]
            setting.CFrame=crownFrame*CF(math.cos(a)*r,0,math.sin(a)*r)*angles(0,-math.deg(a),0)
            setting.Transparency=1-giantAlpha
        end
        local torso=S.giant.model:FindFirstChild("UpperTorso") or S.giant.model:FindFirstChild("Torso") or S.giant.root
        for i,p in ipairs(S.back) do
            local side=i%2==0 and 1 or -1; local level=math.ceil(i/2)
            local a=torso.CFrame*V3(side*torso.Size.X*0.42,torso.Size.Y*0.2,torso.Size.Z*0.55)
            local b=torso.CFrame*V3(side*(90+level*30+math.sin(t*1.4+i)*25),-80-level*55,120+level*30)
            drawPlasma(p,a,b,18+level*8,giantAlpha*0.65,side*(80+math.sin(t*1.8+i)*40))
        end
        for i,c in ipairs(S.shoulders) do
            local side=i<=3 and -1 or 1; local tier=(i-1)%3
            local f=torso.CFrame*CF(side*(torso.Size.X*0.5+8+tier*11),torso.Size.Y*0.4,0)*angles(0,0,-side*(20+tier*12))
            drawCrystal(c,f,14,65-tier*9,giantAlpha*0.92)
        end
    
        -- Llegan en dos columnas de plasma; rodilla derecha al suelo, cabeza baja.
        for i=1,2 do
            local rig=S.owners[i]
            if rig then
            local arrival=phase(t,rig.arrivalTime,rig.arrivalTime+1.4)
            local kneel=phase(t-(i-1)*0.12,22,23.65)
            local x=i==1 and -80 or 80
            -- Punto delante del gigante, mirando a su posicion actual. No depende
            -- de la direccion inicial del jugador ni de una rotacion fija de 180.
            local groundPoint=S.giantPos
            groundPoint=V3(groundPoint.X,base.Position.Y,groundPoint.Z)
            local front=giantFrame.LookVector*V3(1,0,1)
            front=front.Magnitude>0.001 and front.Unit or -base.LookVector
            local ownerGround=groundPoint+front*220+base.RightVector*x
            local facing=CFrame.lookAt(ownerGround,groundPoint)
            local float=(1-arrival)*60
            local frame=facing*CF(0,rig.height-kneel*CONFIG.OwnerHeight*0.25+float,0)
            poseRig(rig,frame,"kneel",kneel,t-(i-1)*0.12,ownerGround.Y+float)
            visibility(rig,arrival*(t>=30.05 and 0 or 1)*fade)
            local portal=S.ownerPortals[i]
            local portalAlpha=arrival*(1-phase(t,21.7,22.8))
            for j,c in ipairs(portal.spines) do
                local a=j*2*PI/5+t*1.4
                local f=base*CF(x+math.cos(a)*36,32+math.sin(a*2)*8,-380+math.sin(a)*36)*angles(0,t*100,0)
                drawCrystal(c,f,5,80,portalAlpha)
            end
            end
        end
    
        local hand=S.giant.model:FindFirstChild("RightHand") or S.giant.model:FindFirstChild("Right Arm") or S.giant.root
        local handFrame=hand.CFrame*CF(0,-hand.Size.Y*0.5,0)
        S.handPos=handFrame.Position
        local unit=CONFIG.GiantHeight/650
        local snapped=phase(t,29.62,29.72)
        -- Dedos redondeados articulados, escala anatomica respecto a la mano.
        for i=1,4 do
            local x=(i-2.5)*6*unit
            local curl=i==3 and mix(0.9,0.1,snapped) or (i==1 and 0.8 or 0.4)
            local a=handFrame*V3(x,0,0)
            local b=handFrame*V3(x,-12*unit,-curl*9*unit)
            local c=handFrame*V3(x+(i==1 and 6 or 0)*unit,-22*unit+curl*8*unit,-curl*17*unit)
            tube(S.fingers[i*2-1],a,b,5.5*unit,snap*giantAlpha*0.72)
            tube(S.fingers[i*2],b,c,4.5*unit,snap*giantAlpha*0.72)
        end
        orb(S.snapOrb,S.handPos+V3(0,-10,0),6+phase(t,28.5,29.6)*8,snap*(1-phase(t,29.65,29.85))*0.8)
        local judgement=phase(t,30.03,30.1)*(1-phase(t,31.3,32))
        for i,fx in ipairs(S.judgement) do
            local rig=S.owners[i]
            local destination=rig and rig.root.Position or world(i==1 and -80 or 80,20,-380)
            local active=rig and judgement or 0
            drawBolt(fx.bolt,S.handPos,destination,3,active,i*15)
            drawBolt(fx.sky,destination+V3(0,1600,0),destination,5,active,i*27)
            drawPlasma(fx.beam,S.handPos,destination,22,active*0.9,0)
        end
    
        -- Eyecciones solidas atraviesan el espacio, con cambio de escala real.
        local eject=clamp((t-8.45)/4.5,0,1)
        local nova=clamp((t-30.05)/3.8,0,1)
        for i,c in ipairs(S.meteors) do
            local direction=V3(math.cos(i*2.399)*0.8,math.sin(i*1.7)*0.65,math.sin(i*2.399)).Unit
            local active=t<20 and eject or nova
            local center=t<20 and S.starPos or world(0,70,-380)
            local pos=center+direction*(40+active*1500)
            local alpha=(t<20 and phase(t,8.45,8.6) or phase(t,30.05,30.2))*(1-active)
            drawCrystal(c,CFrame.lookAt(pos,pos+direction)*angles(90,t*130,0),12,60,alpha)
        end
    
        event("charge",0.8,function() spray(genesis,GOLD,1.2,60,20); play(S.audio.rumble) end)
        event("fire",3.35,function()
            flash(0.75,2.5); play(S.audio.impact)
            detonation(world(0,0.3,0),100,CYAN,1.3,"ground"); mist(world(0,1,0),22,WHITE,8)
        end)
        event("starIgnition",6.05,function()
            flash(0.3,1.5); spray(S.starPos,GOLD,18,260,320,"glint")
        end)
        event("supernova",8.45,function()
            flash(0.88,6); play(S.audio.impact); play(S.audio.roar)
            detonation(S.starPos,900,GOLD,3)
            mist(S.starPos,70,WHITE,8)
        end)
        event("touchdown",17.4,function()
            flash(0.5,8); play(S.audio.impact)
            detonation(world(-65,0.3,-600),380,GOLD,2.1,"ground")
            detonation(world(65,0.3,-590),350,CYAN,1.9,"ground")
        end)
        event("ownerA",20.2,function() spray(world(-80,30,-380),CYAN,8,190,90,"glint"); mist(world(-80,5,-380),45,CYAN,10) end)
        event("ownerB",20.55,function() spray(world(80,30,-380),PURPLE,8,190,90,"glint"); mist(world(80,5,-380),45,PURPLE,10) end)
        event("silence",29.15,function()
            if S.audio.music then S.audio.music.Volume=0.08 end
            if S.audio.rumble then S.audio.rumble.Volume=0 end
        end)
        event("snap",29.65,function()
            play(S.audio.snap); flash(0.4,0.7)
            spray(S.handPos,WHITE,6,140,70,"glint")
        end)
        event("erase",30.05,function()
            flash(0.88,10); play(S.audio.impact); play(S.audio.roar)
            if S.audio.music then S.audio.music.Volume=0.8 end
            for _,rig in pairs(S.owners) do annihilate(rig) end
            detonation(world(0,35,-380),1050,GOLD,3.8)
        end)
        if t>3.35 and t<7.5 then every("rayDust",0.32,function()
            spray(beamA,CYAN,3,35,100,"spark")
        end) end
        if t>9 and t<17 then every("solarDust",0.8,function()
            mist(S.giantPos+V3(0,-60,0),85,GOLD,6)
        end) end
        if t>30.05 and t<31.5 then every("electricBurst",0.35,function()
            for _,rig in pairs(S.owners) do spray(rig.root.Position,WHITE,7,55,125,"glint") end
        end) end
        if S.audio.music and t>36 then S.audio.music.Volume=0.7*fade end
        if S.audio.rumble and t>34 then S.audio.rumble.Volume=0 end
        cinematicCamera(t,dt)
        updateEffects()
    end
    
    local function prepareLighting()
        saved.lighting={}; saved.atmospheres={}; saved.postFX={}
        for _,key in ipairs({"ClockTime","Brightness","Ambient","OutdoorAmbient","FogStart","FogEnd","FogColor","ExposureCompensation"}) do saved.lighting[key]=Lighting[key] end
        -- Evita que el postprocesado del mapa o de otra animacion apague los VFX.
        for _,o in ipairs(Lighting:GetChildren()) do
            if o:IsA("PostEffect") then saved.postFX[o]=o.Enabled; o.Enabled=false end
            if o:IsA("Atmosphere") then
                saved.atmospheres[o]={Density=o.Density,Haze=o.Haze,Glare=o.Glare}
                o.Density=0.12; o.Haze=0.3; o.Glare=0.4
            end
        end
        Lighting.ClockTime=17.25; Lighting.Brightness=3
        Lighting.Ambient=Color3.fromRGB(135,120,155); Lighting.OutdoorAmbient=Color3.fromRGB(145,150,175)
        Lighting.ExposureCompensation=0.15; Lighting.FogStart=5000; Lighting.FogEnd=20000
        Lighting.FogColor=Color3.fromRGB(177,169,202)
        S.bloom=keep(make("BloomEffect",{Name="SovereignBloom",Intensity=1.15,Size=44,Threshold=0.65},Lighting))
        S.grade=keep(make("ColorCorrectionEffect",{Name="SovereignGrade",Brightness=0.04,Contrast=0.16,Saturation=0.2,TintColor=Color3.fromRGB(255,243,236)},Lighting))
        keep(make("SunRaysEffect",{Name="SovereignSun",Intensity=0.18,Spread=0.85},Lighting))
    end
    local function setup()
        character=player.Character or player.CharacterAdded:Wait()
        if dead then return end
        root=character:WaitForChild("HumanoidRootPart",8)
        humanoid=character:FindFirstChildOfClass("Humanoid")
        local playerGui=player:WaitForChild("PlayerGui",8)
        cam=Workspace.CurrentCamera
        if dead then return end
        if not root or not humanoid or humanoid.Health<=0 or not playerGui or not cam then error("Espera a aparecer antes de ejecutar.") end
        scene=keep(make("Folder",{Name="DarlingSovereign_Local"},Workspace))
        gui=keep(make("ScreenGui",{Name="SovereignFullScreenVFX",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=999999},playerGui))
        -- Unico elemento 2D: pulso de luz blanca. Nada de bandas, texto o botones.
        screenFlash=make("Frame",{Name="LightPulse",Size=UDim2.fromScale(1,1),BorderSizePixel=0,
            BackgroundColor3=WHITE,BackgroundTransparency=1},gui)
        connect(UserInputService.InputBegan,function(input,processed)
            if not processed and input.KeyCode==Enum.KeyCode.X then api.Stop() end
        end)
        connect(player.CharacterRemoving,function(c) if c==character then api.Stop() end end)
        connect(humanoid.Died,api.Stop)
    
        -- Carga en paralelo sin frenar la camara una vez iniciada la escena.
        for i,data in ipairs(OWNER_DATA) do task.spawn(function() fetchOwner(i,data,false) end) end
        task.spawn(function()
            pcall(function() ContentProvider:PreloadAsync({"rbxassetid://9756362"},function(_,status)
                S.diamondReady=status==Enum.AssetFetchStatus.Success
            end) end)
            S.meshPreloaded=true
            local fallbacks={spark="rbxasset://textures/particles/sparkles_main.dds",mist="rbxasset://textures/particles/smoke_main.dds",glint="rbxasset://textures/particles/sparkles_main.dds"}
            for key,id in pairs(TEX) do
                pcall(function() ContentProvider:PreloadAsync({id},function(_,status)
                    if status==Enum.AssetFetchStatus.Failure and fallbacks[key] then TEX[key]=fallbacks[key] end
                end) end)
                if dead then return end
            end
        end)
        -- Ni un mesh pendiente ni un endpoint de avatares bloquean el inicio.
        -- Reintentos en segundo plano, usando las apariencias reales guardadas.
        for _,delaySeconds in ipairs({5,11,17}) do
            task.delay(delaySeconds,function()
                if dead or not accepting then return end
                for i,data in ipairs(OWNER_DATA) do
                    if not incoming[i] and not (S.owners and S.owners[i]) then
                        task.spawn(function() fetchOwner(i,data,true) end)
                    end
                end
            end)
        end
        if dead then return end
        local look=root.CFrame.LookVector*V3(1,0,1)
        if look.Magnitude<0.001 then look=V3(0,0,-1) end
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={character,scene}
        local hit=Workspace:Raycast(root.Position+V3(0,2,0),V3(0,-160,0),params)
        local ground=hit and hit.Position or root.Position-V3(0,3,0)
        base=CFrame.lookAt(ground,ground+look.Unit)
        S.starPos=world(0,950,-780)
        buildScene()
        if dead then return end
    
        saved.camera=cam; saved.cameraType=cam.CameraType; saved.cameraCF=cam.CFrame
        saved.fov=cam.FieldOfView; saved.focus=cam.Focus; saved.subject=cam.CameraSubject
        saved.root=root; saved.anchored=root.Anchored
        saved.humanoid=humanoid; saved.walkSpeed=humanoid.WalkSpeed; saved.autoRotate=humanoid.AutoRotate
        saved.jumpPower=humanoid.JumpPower; saved.jumpHeight=humanoid.JumpHeight
        root.Anchored=true; humanoid.WalkSpeed=0; humanoid.JumpPower=0; humanoid.JumpHeight=0; humanoid.AutoRotate=false
        local function hide(p) if p:IsA("BasePart") then hiddenParts[p]=p.LocalTransparencyModifier; p.LocalTransparencyModifier=1 end end
        for _,p in ipairs(character:GetDescendants()) do hide(p) end
        connect(character.DescendantAdded,hide)
        if CONFIG.HideGameUI then
            for _,g in ipairs(playerGui:GetChildren()) do
                if g:IsA("ScreenGui") and g~=gui and g.Enabled then hiddenGuis[g]=true; g.Enabled=false end
            end
        end
        prepareLighting()
        cam.CameraType=Enum.CameraType.Scriptable
        play(S.audio.music)
        started=os.clock(); bound=true; api.Status="playing"
        RunService:BindToRenderStep(bindName,Enum.RenderPriority.Camera.Value+10,function(dt)
            local ok,err=xpcall(function() animate(dt) end,debug.traceback)
            if not ok then stop(err) end
        end)
        task.delay(CONFIG.Duration+3,function() if not dead then stop("finished") end end)
    end
    local ok,err=xpcall(setup,debug.traceback)
    if not ok then stop(err) end
    return api
    

end

function CodexAdmin.play(customConfig)
    CodexAdmin.stop()
    local cfg = (type(customConfig) == "table" and customConfig) or {}
    if CodexAdmin.CustomMusicId and #CodexAdmin.CustomMusicId > 0 then
        cfg.Music = CodexAdmin.CustomMusicId
    end
    local session = runAnimation(cfg)
    CodexAdmin.ActiveSession = session
    return session
end

function CodexAdmin.enable()
    return CodexAdmin.play()
end

function CodexAdmin.stop()
    if CodexAdmin.ActiveSession and type(CodexAdmin.ActiveSession.Stop) == "function" then
        pcall(CodexAdmin.ActiveSession.Stop)
        CodexAdmin.ActiveSession = nil
    end
    local env = (getgenv and getgenv()) or _G
    if env.DarlingSovereign and type(env.DarlingSovereign.Stop) == "function" then
        pcall(env.DarlingSovereign.Stop)
    end
    if _G.DarlingSovereign and type(_G.DarlingSovereign.Stop) == "function" then
        pcall(_G.DarlingSovereign.Stop)
    end
end

function CodexAdmin.dismiss()
    CodexAdmin.stop()
end

function CodexAdmin.destroy()
    CodexAdmin.stop()
end

function CodexAdmin.isPlaying()
    if CodexAdmin.ActiveSession and CodexAdmin.ActiveSession.IsPlaying then
        return true
    end
    local env = (getgenv and getgenv()) or _G
    return (env.DarlingSovereign and env.DarlingSovereign.IsPlaying) or false
end

_G.CodexAdminAnimation = CodexAdmin
return CodexAdmin
