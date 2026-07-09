-- ============================================
-- 秋雨脚本 - 完整整合版
-- 所有功能 + 3D面板(角色两侧不遮挡)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local char, root, hum

local function SetupChar()
    char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
end
SetupChar()
LocalPlayer.CharacterAdded:Connect(SetupChar)

-- ==================== 状态管理 ====================
local State = {
    Flying = false, Spinning = false, Circling = false,
    NoClip = false, InfJump = false, Speed = 1,
    ESP = false, ESPBox = false, ESPName = false, ESPHealth = false, ESPDistance = false, ESPTracers = false,
    Aimbot = false, AimbotVisible = false, Hitbox = false, HitboxSize = 5,
    Minimized = false, PanelVisible = true,
}

local Comp = {
    FlyBV = nil, FlyConn = nil, FlyK1 = nil, FlyK2 = nil,
    SpinAV = nil, CircleConn = nil, CircleTarget = nil, CircleAngle = 0, CircleSpeed = 2,
    JumpConn = nil, NoClipConn = nil, SelTarget = nil, ESPConns = {},
    AimbotConn = nil, HitboxConn = nil, HitboxParts = {}, TrollObjs = {},
}

-- ==================== 全部功能函数 ====================
local function StartFly()
    if State.Flying then return end; State.Flying = true
    local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1,1,1)*50000; bv.Velocity = Vector3.zero; bv.Parent = root; Comp.FlyBV = bv
    local md, ud, sp = Vector3.zero, 0, 50
    Comp.FlyConn = RunService.Heartbeat:Connect(function()
        if not State.Flying or not Comp.FlyBV then return end; local cam = Camera; if not cam then return end
        local fw = cam.CFrame.LookVector * Vector3.new(1,0,1); local rt = cam.CFrame.RightVector * Vector3.new(1,0,1)
        local mv = (fw * -md.Z) + (rt * md.X) + Vector3.new(0, ud, 0)
        Comp.FlyBV.Velocity = mv.Magnitude > 0.1 and mv.Unit * sp or Vector3.zero
    end)
    Comp.FlyK1 = UserInputService.InputBegan:Connect(function(i,g) if g then return end
        if i.KeyCode == Enum.KeyCode.W then md += Vector3.new(0,0,-1) elseif i.KeyCode == Enum.KeyCode.S then md += Vector3.new(0,0,1)
        elseif i.KeyCode == Enum.KeyCode.A then md += Vector3.new(-1,0,0) elseif i.KeyCode == Enum.KeyCode.D then md += Vector3.new(1,0,0)
        elseif i.KeyCode == Enum.KeyCode.Space then ud = 1 elseif i.KeyCode == Enum.KeyCode.LeftControl then ud = -1 end end)
    Comp.FlyK2 = UserInputService.InputEnded:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.W then md -= Vector3.new(0,0,-1) elseif i.KeyCode == Enum.KeyCode.S then md -= Vector3.new(0,0,1)
        elseif i.KeyCode == Enum.KeyCode.A then md -= Vector3.new(-1,0,0) elseif i.KeyCode == Enum.KeyCode.D then md -= Vector3.new(1,0,0)
        elseif i.KeyCode == Enum.KeyCode.Space then ud = 0 elseif i.KeyCode == Enum.KeyCode.LeftControl then ud = 0 end end)
end
local function StopFly() State.Flying = false; if Comp.FlyBV then Comp.FlyBV:Destroy(); Comp.FlyBV = nil end; if Comp.FlyConn then Comp.FlyConn:Disconnect(); Comp.FlyConn = nil end; if Comp.FlyK1 then Comp.FlyK1:Disconnect(); Comp.FlyK1 = nil end; if Comp.FlyK2 then Comp.FlyK2:Disconnect(); Comp.FlyK2 = nil end end

local function StartSpin() if State.Spinning then return end; State.Spinning = true; hum.AutoRotate = false; if root:FindFirstChild("SpinRotator") then root.SpinRotator:Destroy() end; local av = Instance.new("BodyAngularVelocity"); av.Name = "SpinRotator"; av.MaxTorque = Vector3.new(0,math.huge,0); av.AngularVelocity = Vector3.new(0,70,0); av.Parent = root; Comp.SpinAV = av end
local function StopSpin() State.Spinning = false; if Comp.SpinAV then Comp.SpinAV:Destroy(); Comp.SpinAV = nil end; hum.AutoRotate = true end

local function StartCircle(target) if State.Circling then StopCircle() end; if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") or not root then return end; State.Circling = true; Comp.CircleTarget = target; Comp.CircleAngle = math.random()*math.pi*2; local r, ho, sm = 8, 3, 0.5; Comp.CircleConn = RunService.Heartbeat:Connect(function() if not State.Circling or not Comp.CircleTarget then StopCircle(); return end; local tc = Comp.CircleTarget.Character; if not tc then StopCircle(); return end; local tr = tc:FindFirstChild("HumanoidRootPart"); if not tr or not root or not root.Parent then StopCircle(); return end; Comp.CircleAngle += Comp.CircleSpeed * 0.05; local tp = tr.Position; root.CFrame = CFrame.new(root.Position:Lerp(Vector3.new(tp.X+r*math.cos(Comp.CircleAngle), tp.Y+ho, tp.Z+r*math.sin(Comp.CircleAngle)), sm)) end) end
local function StopCircle() State.Circling = false; Comp.CircleTarget = nil; if Comp.CircleConn then Comp.CircleConn:Disconnect(); Comp.CircleConn = nil end end

local function ToggleInfJump() State.InfJump = not State.InfJump; if State.InfJump then Comp.JumpConn = RunService.Heartbeat:Connect(function() if not State.InfJump or not hum or not hum.Parent then return end; local s = hum:GetState(); if s == Enum.HumanoidStateType.Freefall or s == Enum.HumanoidStateType.Jumping then hum.Jump = true end end) else if Comp.JumpConn then Comp.JumpConn:Disconnect(); Comp.JumpConn = nil end end end
local function ToggleNoClip() State.NoClip = not State.NoClip; if State.NoClip then for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end; Comp.NoClipConn = char.DescendantAdded:Connect(function(p) if p:IsA("BasePart") and State.NoClip then p.CanCollide = false end end) else for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end; if Comp.NoClipConn then Comp.NoClipConn:Disconnect(); Comp.NoClipConn = nil end end end
local function CycleSpeed() local speeds = {1,2,4,8,16}; local idx = 1; for i,v in ipairs(speeds) do if v == State.Speed then idx = i; break end end; idx = idx % #speeds + 1; State.Speed = speeds[idx]; hum.WalkSpeed = 16 * State.Speed end
local function StopAll() if State.Flying then StopFly() end; if State.Spinning then StopSpin() end; if State.Circling then StopCircle() end; if State.InfJump then ToggleInfJump() end; if State.NoClip then ToggleNoClip() end; if State.Aimbot then ToggleAimbot() end; if State.Hitbox then ToggleHitbox() end; ClearTroll(); if State.Speed ~= 1 then State.Speed = 1; hum.WalkSpeed = 16 end end
local function TeleportToPlayer(tp) if not tp or not root then return false end; local tc = tp.Character; if tc and tc:FindFirstChild("HumanoidRootPart") then root.CFrame = tc.HumanoidRootPart.CFrame + Vector3.new(0,3,0); return true end; return false end
local function GetTarget() return Comp.SelTarget end

local function TrollHandsUp(target) if not target then return end; local ch = target.Character; if not ch then return end; local hum = ch:FindFirstChild("Humanoid"); if not hum then return end; hum.PlatformStand = true; task.wait(0.1); local torso = ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"); if torso then local rs = torso:FindFirstChild("Right Shoulder") or torso:FindFirstChild("RightUpperArm"); local ls = torso:FindFirstChild("Left Shoulder") or torso:FindFirstChild("LeftUpperArm"); if rs then rs.CurrentAngle = math.rad(180) end; if ls then ls.CurrentAngle = math.rad(180) end end end
local function TrollSit(target) if not target then return end; local ch = target.Character; if not ch then return end; local hum = ch:FindFirstChild("Humanoid"); if not hum then return end; hum.Sit = true end
local function TrollFreeze(target) if not target then return end; local ch = target.Character; if not ch then return end; local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end; for _, o in pairs(Comp.TrollObjs) do if o and o.Parent then o:Destroy() end end; Comp.TrollObjs = {}; local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1,1,1)*999999; bv.Velocity = Vector3.zero; bv.Parent = hrp; local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(1,1,1)*999999; bg.CFrame = hrp.CFrame; bg.Parent = hrp; table.insert(Comp.TrollObjs, bv); table.insert(Comp.TrollObjs, bg) end
local function TrollFling(target) if not target then return end; local ch = target.Character; if not ch then return end; local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1,1,1)*999999; bv.Velocity = Vector3.new(math.random(-300,300), 800, math.random(-300,300)); bv.Parent = hrp; table.insert(Comp.TrollObjs, bv); task.wait(1); if bv and bv.Parent then bv:Destroy() end end
local function TrollSpin(target) if not target then return end; local ch = target.Character; if not ch then return end; local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(1,1,1)*999999; bg.CFrame = hrp.CFrame; bg.Parent = hrp; table.insert(Comp.TrollObjs, bg); task.spawn(function() while bg and bg.Parent do bg.CFrame = bg.CFrame * CFrame.Angles(0, math.rad(20), 0); task.wait() end end) end
local function TrollFlip(target) if not target then return end; local ch = target.Character; if not ch then return end; local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(1,1,1)*999999; bg.CFrame = hrp.CFrame * CFrame.Angles(math.rad(180), 0, 0); bg.Parent = hrp; table.insert(Comp.TrollObjs, bg) end
local function ClearTroll() for _, o in pairs(Comp.TrollObjs) do if o and o.Parent then o:Destroy() end end; Comp.TrollObjs = {}; local t = GetTarget(); if not t then return end; local ch = t.Character; if not ch then return end; local hum = ch:FindFirstChild("Humanoid"); if hum then hum.PlatformStand = false; hum.Sit = false end end

local function GetClosestPlayer() local cl, sd = nil, math.huge; for _, pl in pairs(Players:GetPlayers()) do if pl == LocalPlayer then continue end; local tc = pl.Character; if not tc then continue end; local hd = tc:FindFirstChild("Head"); if not hd then continue end; if State.AimbotVisible then local _, os = Camera:WorldToViewportPoint(hd.Position); if not os then continue end; local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {char}; rp.FilterType = Enum.RaycastFilterType.Blacklist; local ry = workspace:Raycast(Camera.CFrame.Position, (hd.Position - Camera.CFrame.Position).Unit * 500, rp); if ry then local hc = ry.Instance:FindFirstAncestorOfClass("Model"); if hc ~= pl.Character then continue end end end; local sp, os = Camera:WorldToViewportPoint(hd.Position); if os then local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2); local d = (Vector2.new(sp.X, sp.Y) - sc).Magnitude; if d < sd then sd = d; cl = pl end end end; return cl end
local function ToggleAimbot() State.Aimbot = not State.Aimbot; if State.Aimbot then Comp.AimbotConn = RunService.Heartbeat:Connect(function() if not State.Aimbot then return end; local t = GetClosestPlayer(); if t and t.Character and t.Character:FindFirstChild("Head") then Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Character.Head.Position) end end) else if Comp.AimbotConn then Comp.AimbotConn:Disconnect(); Comp.AimbotConn = nil end end end
local function ExpandHitbox(ch) local pts = {}; for _, p in pairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then local os = p.Size; p.Size = os * State.HitboxSize; p.Transparency = 0.7; p.CanCollide = true; table.insert(pts, {part = p, oldSize = os}) end end; return pts end
local function RestoreHitbox(pts) for _, d in pairs(pts) do if d.part and d.part.Parent then d.part.Size = d.oldSize end end end
local function ToggleHitbox() State.Hitbox = not State.Hitbox; if State.Hitbox then for _, pl in pairs(Players:GetPlayers()) do if pl ~= LocalPlayer and pl.Character then Comp.HitboxParts[pl] = ExpandHitbox(pl.Character) end end; Comp.HitboxConn = Players.PlayerAdded:Connect(function(pl) pl.CharacterAdded:Connect(function(ch) task.wait(0.5); if State.Hitbox then Comp.HitboxParts[pl] = ExpandHitbox(ch) end end) end) else for _, pts in pairs(Comp.HitboxParts) do RestoreHitbox(pts) end; Comp.HitboxParts = {}; if Comp.HitboxConn then Comp.HitboxConn:Disconnect(); Comp.HitboxConn = nil end end end

-- ESP
local ESPDrawings = {}
local function CreateESP(player) local d = {}; d.Box = Drawing.new("Square"); d.Box.Visible = false; d.Box.Color = Color3.fromRGB(255,255,255); d.Box.Thickness = 1.5; d.Box.Filled = false; d.Box.Transparency = 0.7; d.Name = Drawing.new("Text"); d.Name.Visible = false; d.Name.Color = Color3.fromRGB(255,255,255); d.Name.Size = 13; d.Name.Center = true; d.Name.Outline = true; d.Name.Font = 3; d.HBg = Drawing.new("Square"); d.HBg.Visible = false; d.HBg.Color = Color3.fromRGB(30,30,30); d.HBg.Thickness = 1; d.HBg.Filled = true; d.HBar = Drawing.new("Square"); d.HBar.Visible = false; d.HBar.Color = Color3.fromRGB(0,255,0); d.HBar.Thickness = 1; d.HBar.Filled = true; d.Dist = Drawing.new("Text"); d.Dist.Visible = false; d.Dist.Color = Color3.fromRGB(255,255,255); d.Dist.Size = 12; d.Dist.Center = true; d.Dist.Outline = true; d.Dist.Font = 3; d.Tracer = Drawing.new("Line"); d.Tracer.Visible = false; d.Tracer.Color = Color3.fromRGB(255,255,255); d.Tracer.Thickness = 1; d.Tracer.Transparency = 0.5; ESPDrawings[player] = d end
local function UpdateESP() for player, d in pairs(ESPDrawings) do if not player or not player.Parent then for _, v in pairs(d) do v:Remove() end; ESPDrawings[player] = nil; continue end; local ch = player.Character; if not ch or not ch:FindFirstChild("HumanoidRootPart") or not ch:FindFirstChild("Humanoid") then for _, v in pairs(d) do v.Visible = false end; continue end; if not root then continue end; local tr = ch.HumanoidRootPart; local th = ch.Humanoid; local pos, os = Camera:WorldToViewportPoint(tr.Position); if not os then for _, v in pairs(d) do v.Visible = false end; continue end; local dist = (root.Position - tr.Position).Magnitude; local scale = math.clamp(1/(dist*0.05),0.5,2); local bs = Vector2.new(40*scale, 60*scale); local bp = Vector2.new(pos.X-bs.X/2, pos.Y-bs.Y/2); if State.ESPBox then d.Box.Visible = true; d.Box.Size = bs; d.Box.Position = bp; d.Box.Color = (player.TeamColor and player.TeamColor.Color) or Color3.fromRGB(255,255,255) else d.Box.Visible = false end; if State.ESPName then d.Name.Visible = true; d.Name.Position = Vector2.new(pos.X, bp.Y-18); d.Name.Text = player.Name else d.Name.Visible = false end; if State.ESPHealth then local h = th.Health; local mh = th.MaxHealth; local hp = math.clamp(h/mh,0,1); d.HBg.Visible = true; d.HBg.Size = Vector2.new(3, bs.Y); d.HBg.Position = Vector2.new(bp.X-6, bp.Y); d.HBar.Visible = true; d.HBar.Size = Vector2.new(3, bs.Y*hp); d.HBar.Position = Vector2.new(bp.X-6, bp.Y+bs.Y*(1-hp)); d.HBar.Color = hp>0.6 and Color3.fromRGB(0,255,0) or (hp>0.3 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0)) else d.HBg.Visible = false; d.HBar.Visible = false end; if State.ESPDistance then d.Dist.Visible = true; d.Dist.Position = Vector2.new(pos.X, bp.Y+bs.Y+4); d.Dist.Text = math.floor(dist).."m" else d.Dist.Visible = false end; if State.ESPTracers then d.Tracer.Visible = true; d.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); d.Tracer.To = Vector2.new(pos.X, bp.Y+bs.Y); d.Tracer.Color = Color3.fromRGB(255,255,255) else d.Tracer.Visible = false end end end
RunService.RenderStepped:Connect(function() if State.ESP then UpdateESP() end end)
local function ToggleESP() State.ESP = not State.ESP; if State.ESP then for _, pl in pairs(Players:GetPlayers()) do if pl ~= LocalPlayer then CreateESP(pl) end end; local pa = Players.PlayerAdded:Connect(function(pl) if pl ~= LocalPlayer then task.wait(1); CreateESP(pl) end end); table.insert(Comp.ESPConns, pa); local pr = Players.PlayerRemoving:Connect(function(pl) if ESPDrawings[pl] then for _, v in pairs(ESPDrawings[pl]) do v:Remove() end; ESPDrawings[pl] = nil end end); table.insert(Comp.ESPConns, pr) else for _, d in pairs(ESPDrawings) do for _, v in pairs(d) do v:Remove() end end; ESPDrawings = {}; for _, c in pairs(Comp.ESPConns) do c:Disconnect() end; Comp.ESPConns = {} end end

-- ==================== 3D面板系统（角色两侧，不遮挡） ====================
local rotateAngle = 0
local panelOffsetDistance = 6
local panelHeightOffset = -1
local panelWidthOffset = 3.5

local function AddBtn(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
    btn.BackgroundTransparency = 0.35
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 220, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(60, 120, 255); st.Thickness = 1; st.Transparency = 0.5; st.Parent = btn
    btn.MouseButton1Click:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(30, 200, 80); task.wait(0.15); btn.BackgroundColor3 = Color3.fromRGB(25, 35, 55); callback() end)
    return btn
end

local function AddToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
    container.BackgroundTransparency = 0.35
    container.BorderSizePixel = 0
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(60, 120, 255); st.Thickness = 1; st.Transparency = 0.5; st.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0); label.Position = UDim2.new(0, 8, 0, 0); label.BackgroundTransparency = 1
    label.Text = text; label.TextColor3 = Color3.fromRGB(200, 220, 255); label.TextSize = 12; label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container

    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(0, 42, 0, 22); tb.Position = UDim2.new(1, -50, 0.5, 0); tb.AnchorPoint = Vector2.new(0, 0.5)
    tb.BackgroundColor3 = default and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(100, 100, 120)
    tb.BorderSizePixel = 0; tb.Parent = container
    Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = default and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    circle.AnchorPoint = Vector2.new(0, 0.5); circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0; circle.Parent = tb
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local state = default
    local click = Instance.new("TextButton")
    click.Size = UDim2.new(1, 0, 1, 0); click.BackgroundTransparency = 1; click.Text = ""; click.Parent = container
    click.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(tb, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(100, 100, 120)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}):Play()
        callback(state)
    end)
end

local function CreatePanel(side)
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = false; p.CastShadow = false
    p.Size = Vector3.new(4, 6, 0.06); p.Transparency = 1; p.Parent = workspace

    for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
        local gui = Instance.new("SurfaceGui")
        gui.Face = face; gui.AlwaysOnTop = true; gui.LightInfluence = 0
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 100
        gui.CanvasSize = Vector2.new(400, 600); gui.Parent = p

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
        frame.BackgroundTransparency = 0.05
        frame.BorderSizePixel = 0; frame.Active = true; frame.Parent = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(60, 120, 255); stroke.Thickness = 1.5; stroke.Transparency = 0.4; stroke.Parent = frame

        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 36)
        topBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255); topBar.BackgroundTransparency = 0.92
        topBar.BorderSizePixel = 0; topBar.Parent = frame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -12, 1, 0); title.Position = UDim2.new(0, 6, 0, 0); title.BackgroundTransparency = 1
        title.Text = (side == "left") and "👥 玩家列表" or "⚙️ 功能控制"
        title.TextColor3 = Color3.fromRGB(200, 220, 255); title.TextSize = 14; title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = topBar

        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(1, -16, 0, 1); divider.Position = UDim2.new(0, 8, 0, 36)
        divider.BackgroundColor3 = Color3.fromRGB(80, 120, 200); divider.BackgroundTransparency = 0.6
        divider.BorderSizePixel = 0; divider.Parent = frame

        local content = Instance.new("ScrollingFrame")
        content.Size = UDim2.new(1, -12, 1, -44); content.Position = UDim2.new(0, 6, 0, 40)
        content.BackgroundTransparency = 1; content.BorderSizePixel = 0
        content.ScrollBarThickness = 3; content.ScrollBarImageColor3 = Color3.fromRGB(60, 120, 255)
        content.ScrollBarImageTransparency = 0.5; content.CanvasSize = UDim2.new(0, 0, 0, 800)
        content.ScrollingDirection = Enum.ScrollingDirection.Y; content.Parent = frame

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0, 5); list.Parent = content
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
        end)

        -- 填充内容
        if side == "left" then
            local function refresh()
                for _, c in ipairs(content:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer then
                        AddBtn(content, " " .. pl.Name, function() TeleportToPlayer(pl) end)
                    end
                end
            end
            refresh()
            Players.PlayerAdded:Connect(refresh)
            Players.PlayerRemoving:Connect(refresh)
        elseif side == "right" then
            -- ESP
            local espLabel = Instance.new("TextLabel")
            espLabel.Size = UDim2.new(1, 0, 0, 20)
            espLabel.BackgroundTransparency = 1
            espLabel.Text = "—— 👁️ ESP透视 ——"
            espLabel.TextColor3 = Color3.fromRGB(150, 180, 220)
            espLabel.TextSize = 11; espLabel.Font = Enum.Font.GothamBold
            espLabel.Parent = content

            AddToggle(content, "ESP总开关", false, function(v) ToggleESP() end)
            AddToggle(content, "方框", false, function(v) State.ESPBox = v end)
            AddToggle(content, "名字", false, function(v) State.ESPName = v end)
            AddToggle(content, "血量", false, function(v) State.ESPHealth = v end)
            AddToggle(content, "距离", false, function(v) State.ESPDistance = v end)
            AddToggle(content, "射线", false, function(v) State.ESPTracers = v end)

            -- 功能
            local funcLabel = Instance.new("TextLabel")
            funcLabel.Size = UDim2.new(1, 0, 0, 20)
            funcLabel.BackgroundTransparency = 1
            funcLabel.Text = "—— ⚙️ 功能 ——"
            funcLabel.TextColor3 = Color3.fromRGB(150, 180, 220)
            funcLabel.TextSize = 11; funcLabel.Font = Enum.Font.GothamBold
            funcLabel.Parent = content

            AddToggle(content, "飞行 (WASD/Space/Ctrl)", false, function(v) if v then StartFly() else StopFly() end end)
            AddToggle(content, "自转", false, function(v) if v then StartSpin() else StopSpin() end end)
            AddToggle(content, "无限跳跃", false, function(v) ToggleInfJump() end)
            AddToggle(content, "穿墙", false, function(v) ToggleNoClip() end)
            AddBtn(content, "加速 (" .. State.Speed .. "x)", function() CycleSpeed() end)

            -- 娱乐
            local trollLabel = Instance.new("TextLabel")
            trollLabel.Size = UDim2.new(1, 0, 0, 20)
            trollLabel.BackgroundTransparency = 1
            trollLabel.Text = "—— 🎮 娱乐 ——"
            trollLabel.TextColor3 = Color3.fromRGB(150, 180, 220)
            trollLabel.TextSize = 11; trollLabel.Font = Enum.Font.GothamBold
            trollLabel.Parent = content

            AddBtn(content, " 绕圈", function() if State.Circling then StopCircle() elseif GetTarget() then StartCircle(GetTarget()) end end)
            AddBtn(content, " 举手", function() TrollHandsUp(GetTarget()) end)
            AddBtn(content, " 摔倒", function() TrollSit(GetTarget()) end)
            AddBtn(content, " 冻结", function() TrollFreeze(GetTarget()) end)
            AddBtn(content, " 弹飞", function() TrollFling(GetTarget()) end)
            AddBtn(content, " 转圈", function() TrollSpin(GetTarget()) end)
            AddBtn(content, " 倒立", function() TrollFlip(GetTarget()) end)
            AddBtn(content, " 恢复", function() ClearTroll() end)

            -- 战斗
            local combatLabel = Instance.new("TextLabel")
            combatLabel.Size = UDim2.new(1, 0, 0, 20)
            combatLabel.BackgroundTransparency = 1
            combatLabel.Text = "—— ⚔️ 战斗 ——"
            combatLabel.TextColor3 = Color3.fromRGB(150, 180, 220)
            combatLabel.TextSize = 11; combatLabel.Font = Enum.Font.GothamBold
            combatLabel.Parent = content

            AddToggle(content, " 自瞄", false, function(v) ToggleAimbot() end)
            AddToggle(content, " 可视检查", false, function(v) State.AimbotVisible = v end)
            AddToggle(content, " 范围伤害", false, function(v) ToggleHitbox() end)
            AddBtn(content, "🔺 范围+", function() State.HitboxSize = math.min(State.HitboxSize+1, 20); if State.Hitbox then ToggleHitbox(); ToggleHitbox() end end)
            AddBtn(content, "🔻 范围-", function() State.HitboxSize = math.max(State.HitboxSize-1, 2); if State.Hitbox then ToggleHitbox(); ToggleHitbox() end end)

            -- 其他
            local otherLabel = Instance.new("TextLabel")
            otherLabel.Size = UDim2.new(1, 0, 0, 20)
            otherLabel.BackgroundTransparency = 1
            otherLabel.Text = "—— 📌 其他 ——"
            otherLabel.TextColor3 = Color3.fromRGB(150, 180, 220)
            otherLabel.TextSize = 11; otherLabel.Font = Enum.Font.GothamBold
            otherLabel.Parent = content

            AddBtn(content, "⏹ 停止全部", function() StopAll() end)
            AddBtn(content, " 复制QQ群: 1051933529", function() if setclipboard then setclipboard("1051933529") end end)
        end
    end
    return p
end

local leftPanel = CreatePanel("left")
local rightPanel = CreatePanel("right")

-- 面板位置更新
local function UpdatePanelPositions()
    if not root or not root.Parent then return end
    local fw = root.CFrame.LookVector
    local rv = root.CFrame.RightVector
    local lo = fw * panelOffsetDistance - rv * panelWidthOffset + Vector3.new(0, panelHeightOffset, 0)
    local ro = fw * panelOffsetDistance + rv * panelWidthOffset + Vector3.new(0, panelHeightOffset, 0)
    local rc = CFrame.Angles(0, math.rad(rotateAngle), 0)
    local lcf = CFrame.lookAt(root.Position + lo, root.Position) * CFrame.Angles(0, math.rad(160), 0)
    local rcf = CFrame.lookAt(root.Position + ro, root.Position) * CFrame.Angles(0, math.rad(200), 0)
    leftPanel.CFrame = rc * (lcf - lcf.Position) + (root.Position + lo)
    rightPanel.CFrame = rc * (rcf - rcf.Position) + (root.Position + ro)
end

-- 滑条
local sliderPart = Instance.new("Part")
sliderPart.Anchored = true; sliderPart.CanCollide = false; sliderPart.CastShadow = false
sliderPart.Transparency = 1; sliderPart.Size = Vector3.new(3, 0.3, 0.06); sliderPart.Parent = workspace

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front; sg.AlwaysOnTop = true; sg.LightInfluence = 0
sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 100
sg.CanvasSize = Vector2.new(300, 40); sg.Parent = sliderPart

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(1, 1); bar.BackgroundColor3 = Color3.fromRGB(15, 15, 28)
bar.BackgroundTransparency = 0.06; bar.BorderSizePixel = 0; bar.Active = true; bar.Parent = sg
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 16)
local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(60, 120, 255); bs.Thickness = 1; bs.Transparency = 0.4; bs.Parent = bar

local al = Instance.new("TextLabel")
al.Size = UDim2.new(1, 0, 1, 0); al.BackgroundTransparency = 1
al.Text = "↔ 旋转 | 0°"; al.TextColor3 = Color3.fromRGB(180, 200, 255)
al.TextSize = 10; al.Font = Enum.Font.GothamBold; al.Parent = bar

local knob = Instance.new("TextButton")
knob.Size = UDim2.new(0, 50, 1, 0); knob.Position = UDim2.new(0.5, -25, 0, 0)
knob.BackgroundColor3 = Color3.fromRGB(0, 140, 255); knob.Text = "↔"; knob.TextScaled = true
knob.TextColor3 = Color3.new(1, 1, 1); knob.Active = true; knob.Parent = bar
Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 16)

local dragging = false; local smx, sa = 0, 0
knob.MouseButton1Down:Connect(function() dragging = true; smx = UserInputService:GetMouseLocation().X; sa = rotateAngle end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local dx = UserInputService:GetMouseLocation().X - smx; rotateAngle = math.clamp(sa + (dx / 300) * 360, -180, 180); local pos = (rotateAngle + 180) / 360; knob.Position = UDim2.new(pos, -25, 0, 0); al.Text = "↔ 旋转 | " .. math.floor(rotateAngle) .. "°" end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

RunService.RenderStepped:Connect(function()
    UpdatePanelPositions()
    if root and root.Parent then
        local fw = root.CFrame.LookVector
        sliderPart.CFrame = CFrame.new(root.Position + fw * 5 + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, math.rad(180), 0)
    end
end)

print("✅ 秋雨脚本 完整版 + 3D面板 加载完成!")
print("📋 左侧面板: 玩家列表(点击传送)")
print("⚙️ 右侧面板: 全部功能")
print("   - ESP: 总开关/方框/名字/血量/距离/射线")
print("   - 功能: 飞行/自转/无限跳/穿墙/加速")
print("   - 娱乐: 绕圈/举手/摔倒/冻结/弹飞/转圈/倒立/恢复")
print("   - 战斗: 自瞄/可视检查/范围伤害")
print("   - 其他: 停止全部/QQ群")
