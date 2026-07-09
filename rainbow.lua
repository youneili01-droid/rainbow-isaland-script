-- ============================================
-- Rainbow Island - 调整版
-- 正方体小+上移 | 进度条下移 | 字下移 | 卡密深色
-- ============================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== 3D立方体 - 变小 ====================
local cubeSize = 1.4
local half = cubeSize / 2

local vertices = {
    Vector3.new(-half, -half, -half), Vector3.new(half, -half, -half),
    Vector3.new(half, half, -half),   Vector3.new(-half, half, -half),
    Vector3.new(-half, -half, half),  Vector3.new(half, -half, half),
    Vector3.new(half, half, half),    Vector3.new(-half, half, half)
}

local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}

local layers = {glow1={}, glow2={}, glow3={}, glow4={}, core={}}
for i = 1, 12 do
    for layerName, thickness in pairs({glow1=18, glow2=11, glow3=6, glow4=3, core=1.5}) do
        local line = Drawing.new("Line")
        line.Visible = true
        line.Thickness = thickness
        line.Transparency = 1
        table.insert(layers[layerName], line)
    end
end

-- ==================== 星星粒子 ====================
local stars = {}
for i = 1, 1000 do
    local s = Drawing.new("Circle")
    s.Filled = true
    s.Radius = math.random(1, 3)
    s.Transparency = 0.5
    s.Color = Color3.fromHSV(math.random(), 0.8, 1)
    table.insert(stars, {
        obj = s,
        x = math.random(0, Camera.ViewportSize.X),
        y = math.random(-100, Camera.ViewportSize.Y),
        vx = math.random(-0.4, 0.4),
        vy = -0.6 - math.random() * 1.5,
        twinkle = math.random() * 6.28,
        baseRadius = s.Radius
    })
end

-- ==================== 进度条（纯Drawing） ====================
local progBg = Drawing.new("Square")
progBg.Visible = true; progBg.Filled = true
progBg.Color = Color3.fromRGB(20, 20, 38)
progBg.Size = Vector2.new(280, 4)
progBg.Transparency = 1

local progFill = Drawing.new("Square")
progFill.Visible = true; progFill.Filled = true
progFill.Color = Color3.fromRGB(90, 160, 255)
progFill.Size = Vector2.new(0, 4)
progFill.Transparency = 0

local progText = Drawing.new("Text")
progText.Visible = true; progText.Text = ""
progText.Size = 13; progText.Color = Color3.fromRGB(180, 200, 255)
progText.Center = true; progText.Font = 3; progText.Transparency = 1

local statusText = Drawing.new("Text")
statusText.Visible = true; statusText.Text = ""
statusText.Size = 12; statusText.Color = Color3.fromRGB(140, 170, 240)
statusText.Center = true; statusText.Font = 2; statusText.Transparency = 1

local bigTitle = Drawing.new("Text")
bigTitle.Visible = true; bigTitle.Text = "RAINBOW ISLAND"
bigTitle.Size = 38; bigTitle.Color = Color3.fromRGB(255, 255, 255)
bigTitle.Center = true; bigTitle.Font = 3; bigTitle.Transparency = 1

-- ==================== 动画 ====================
local time = 0; local hue = 0
local phase = 0; local phaseTimer = 0; local progress = 0

local function project3D(point)
    local rotX = CFrame.fromEulerAnglesXYZ(time * 0.7, 0, 0)
    local rotY = CFrame.fromEulerAnglesXYZ(0, time * 0.9, 0)
    local p = rotY * rotX * point
    local dist = 6.5
    local scale = math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 0.16
    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2 - 80
    local persp = dist / (dist - p.Z)
    return Vector2.new(cx + p.X * scale * persp, cy + p.Y * scale * persp)
end

local connection
connection = RunService.RenderStepped:Connect(function(dt)
    time = time + dt; phaseTimer = phaseTimer + dt
    hue = (hue + 0.35) % 360
    local col = Color3.fromHSV(hue/360, 1, 1)
    local vw = Camera.ViewportSize.X; local vh = Camera.ViewportSize.Y

    if phase == 0 and phaseTimer > 1.0 then phase = 1; phaseTimer = 0 end
    if phase == 1 and phaseTimer > 2.5 then phase = 2 end

    if phase >= 2 then
        progress = math.min(phaseTimer / 3.0, 1)
        progFill.Size = Vector2.new(280 * progress, 4)
        progFill.Color = col
        progText.Text = math.floor(progress * 100) .. "%"
        progText.Transparency = 0
        statusText.Text = progress >= 0.92 and "READY" or "LOADING..."
        statusText.Transparency = 0
        if progress >= 1 and phaseTimer > 3.5 then phase = 3 end
    end

    -- 位置调整：进度条下移，字下移
    progBg.Position = Vector2.new(vw/2 - 140, vh * 0.82)
    progFill.Position = Vector2.new(vw/2 - 140, vh * 0.82)
    progBg.Transparency = (phase >= 2) and 0 or 1
    progText.Position = Vector2.new(vw/2, vh * 0.78)
    statusText.Position = Vector2.new(vw/2, vh * 0.87)
    bigTitle.Position = Vector2.new(vw/2, vh * 0.70)
    
    if phase >= 1 then bigTitle.Transparency = math.max(0, bigTitle.Transparency - dt * 1.5) end

    local points = {}
    for _, v in ipairs(vertices) do table.insert(points, project3D(v)) end
    for i, edge in ipairs(edges) do
        local p1 = points[edge[1]]; local p2 = points[edge[2]]
        layers.glow1[i].From = p1; layers.glow1[i].To = p2; layers.glow1[i].Color = col; layers.glow1[i].Transparency = 0.85
        layers.glow2[i].From = p1; layers.glow2[i].To = p2; layers.glow2[i].Color = col; layers.glow2[i].Transparency = 0.7
        layers.glow3[i].From = p1; layers.glow3[i].To = p2; layers.glow3[i].Color = col; layers.glow3[i].Transparency = 0.5
        layers.glow4[i].From = p1; layers.glow4[i].To = p2; layers.glow4[i].Color = col; layers.glow4[i].Transparency = 0.25
        layers.core[i].From = p1; layers.core[i].To = p2; layers.core[i].Color = Color3.new(1,1,1); layers.core[i].Transparency = 0
    end

    for _, s in ipairs(stars) do
        s.x = s.x + s.vx; s.y = s.y + s.vy; s.twinkle = s.twinkle + 0.06
        if s.y < -50 then s.y = vh + 50; s.x = math.random(0, vw) end
        s.obj.Position = Vector2.new(s.x, s.y)
        s.obj.Transparency = 0.2 + math.sin(s.twinkle) * 0.4
        s.obj.Color = col
        s.obj.Radius = s.baseRadius + math.sin(s.twinkle * 1.8) * 1.0
    end

    if phase == 3 then
        local fade = dt * 2.5
        bigTitle.Transparency = math.min(1, bigTitle.Transparency + fade)
        statusText.Transparency = math.min(1, statusText.Transparency + fade)
        progText.Transparency = math.min(1, progText.Transparency + fade)
        progBg.Transparency = math.min(1, progBg.Transparency + fade)
        progFill.Transparency = math.min(1, progFill.Transparency + fade)
        for _, layer in pairs(layers) do for _, line in ipairs(layer) do line.Transparency = math.min(1, line.Transparency + fade * 1.2) end end
        for _, s in ipairs(stars) do s.obj.Transparency = math.min(1, s.obj.Transparency + fade * 1.5) end
        if bigTitle.Transparency >= 1 then
            connection:Disconnect()
            for _, layer in pairs(layers) do for _, line in ipairs(layer) do line:Remove() end end
            for _, s in ipairs(stars) do s.obj:Remove() end
            progBg:Remove(); progFill:Remove(); progText:Remove(); statusText:Remove(); bigTitle:Remove()
        end
    end
end)

-- ==================== 卡密弹窗（深色，非白色） ====================
local function ShowPremiumKeyWindow(callback)
    local keyGui = Instance.new("ScreenGui")
    keyGui.ResetOnSpawn = false; keyGui.DisplayOrder = 1001
    keyGui.Parent = LocalPlayer.PlayerGui

    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 400, 0, 240)
    popup.Position = UDim2.new(0.5, -200, 1, 30)
    popup.BackgroundColor3 = Color3.fromRGB(14, 14, 30)
    popup.BackgroundTransparency = 0.04
    popup.BorderSizePixel = 0
    popup.Parent = keyGui
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 20)

    local ps1 = Instance.new("UIStroke")
    ps1.Color = Color3.fromRGB(80, 140, 255); ps1.Thickness = 2; ps1.Transparency = 0.45; ps1.Parent = popup
    local ps2 = Instance.new("UIStroke")
    ps2.Color = Color3.fromRGB(150, 200, 255); ps2.Thickness = 1; ps2.Transparency = 0.25; ps2.Parent = popup

    TweenService:Create(popup, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -200, 0.5, -120)}):Play()

    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1,0,0,45); keyTitle.Text = "输入密钥"
    keyTitle.TextColor3 = Color3.new(1,1,1); keyTitle.TextSize = 24
    keyTitle.Font = Enum.Font.GothamBlack; keyTitle.BackgroundTransparency = 1; keyTitle.Parent = popup

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0, 320, 0, 48); inputFrame.Position = UDim2.new(0.5, -160, 0, 70)
    inputFrame.BackgroundColor3 = Color3.fromRGB(20,20,38); inputFrame.BorderSizePixel = 0; inputFrame.Parent = popup
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0,12)
    local is = Instance.new("UIStroke")
    is.Color = Color3.fromRGB(70, 130, 240); is.Thickness = 1; is.Transparency = 0.5; is.Parent = inputFrame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1,-20,1,0); input.Position = UDim2.new(0,10,0,0)
    input.PlaceholderText = "ENTER YOUR KEY HERE"; input.Text = ""
    input.TextColor3 = Color3.new(1,1,1); input.PlaceholderColor3 = Color3.fromRGB(130,140,190)
    input.BackgroundTransparency = 1; input.Font = Enum.Font.GothamMedium; input.TextSize = 15; input.Parent = inputFrame

    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1,0,0,20); errorLabel.Position = UDim2.new(0,0,0,130)
    errorLabel.BackgroundTransparency = 1; errorLabel.Text = ""
    errorLabel.TextColor3 = Color3.fromRGB(255,100,100); errorLabel.TextSize = 12
    errorLabel.Font = Enum.Font.GothamMedium; errorLabel.Parent = popup

    local confirm = Instance.new("TextButton")
    confirm.Size = UDim2.new(0, 150, 0, 44); confirm.Position = UDim2.new(0.5, -75, 1, -60)
    confirm.BackgroundColor3 = Color3.fromRGB(50, 110, 230); confirm.Text = "VERIFY KEY"
    confirm.TextColor3 = Color3.new(1,1,1); confirm.Font = Enum.Font.GothamBold; confirm.TextSize = 14
    confirm.BorderSizePixel = 0; confirm.Parent = popup
    Instance.new("UICorner", confirm).CornerRadius = UDim.new(0,12)
    local cs = Instance.new("UIStroke")
    cs.Color = Color3.fromRGB(130, 180, 255); cs.Thickness = 1.5; cs.Transparency = 0.3; cs.Parent = confirm

    local function submit()
        local key = input.Text
        if key == "" then errorLabel.Text = "PLEASE ENTER A KEY"; return end
        confirm.Text = "VERIFYING..."; confirm.BackgroundColor3 = Color3.fromRGB(80,80,80)
        local success, data = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/youneili01-droid/qiuyu-script/main/keys.txt") end)
        if success and data and data:find(key) then
            TweenService:Create(popup, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, -200, -1, 0)}):Play()
            task.wait(0.6); keyGui:Destroy()
            if callback then callback(true) end
        else
            errorLabel.Text = "INVALID KEY"; input.Text = ""
            confirm.Text = "VERIFY KEY"; confirm.BackgroundColor3 = Color3.fromRGB(50, 110, 230)
        end
    end
    confirm.MouseButton1Click:Connect(submit)
    input.FocusLost:Connect(function(ep) if ep then submit() end end)
end

task.spawn(function()
    repeat task.wait() until phase == 3
    task.wait(0.6)
    ShowPremiumKeyWindow(function() print("✅ 验证成功!") end)
end)

print("🌈 Rainbow Island - 调整版就绪")
