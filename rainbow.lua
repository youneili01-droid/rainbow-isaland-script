-- ============================================
-- 3D霓虹发光正方体 - 终极版 + 圆角容器背景
-- ============================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- 隐藏鼠标
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

-- 全屏深色背景
local bg = Drawing.new("Square")
bg.Visible = true
bg.Filled = true
bg.Color = Color3.fromRGB(5, 5, 12)
bg.Size = Vector2.new(5000, 5000)
bg.Position = Vector2.new(-1000, -1000)

-- ==================== 圆角容器背景 ====================
local container = Instance.new("ScreenGui")
container.Name = "SplashContainer"
container.Parent = LocalPlayer:WaitForChild("PlayerGui")
container.ResetOnSpawn = false
container.DisplayOrder = 998

-- 外层发光
local containerGlow = Instance.new("Frame")
containerGlow.Size = UDim2.new(0, 480, 0, 280)
containerGlow.Position = UDim2.new(0.5, -240, 0.5, -140)
containerGlow.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
containerGlow.BackgroundTransparency = 0.2
containerGlow.BorderSizePixel = 0
containerGlow.Parent = container
Instance.new("UICorner", containerGlow).CornerRadius = UDim.new(0, 24)

-- 发光边框
local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Color3.fromRGB(80, 120, 255)
containerStroke.Thickness = 1.5
containerStroke.Transparency = 0.5
containerStroke.Parent = containerGlow

-- 内层
local containerInner = Instance.new("Frame")
containerInner.Size = UDim2.new(1, -8, 1, -8)
containerInner.Position = UDim2.new(0, 4, 0, 4)
containerInner.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
containerInner.BackgroundTransparency = 0.15
containerInner.BorderSizePixel = 0
containerInner.Parent = containerGlow
Instance.new("UICorner", containerInner).CornerRadius = UDim.new(0, 20)

-- 顶部标题栏
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
topBar.BackgroundTransparency = 0.92
topBar.BorderSizePixel = 0
topBar.Parent = containerInner
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 20)

local topTitle = Instance.new("TextLabel")
topTitle.Size = UDim2.new(1, -20, 1, 0)
topTitle.Position = UDim2.new(0, 10, 0, 0)
topTitle.BackgroundTransparency = 1
topTitle.Text = "YOUR PROJECT"
topTitle.TextColor3 = Color3.fromRGB(200, 210, 255)
topTitle.TextSize = 14
topTitle.Font = Enum.Font.GothamBold
topTitle.TextXAlignment = Enum.TextXAlignment.Left
topTitle.Parent = topBar

-- 版本号
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 60, 1, 0)
versionLabel.Position = UDim2.new(1, -70, 0, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.0"
versionLabel.TextColor3 = Color3.fromRGB(120, 140, 200)
versionLabel.TextSize = 11
versionLabel.Font = Enum.Font.GothamMedium
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = topBar

-- 底部状态栏
local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(1, 0, 0, 32)
bottomBar.Position = UDim2.new(0, 0, 1, -32)
bottomBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bottomBar.BackgroundTransparency = 0.92
bottomBar.BorderSizePixel = 0
bottomBar.Parent = containerInner

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 1, 0)
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "LOADING..."
statusLabel.TextColor3 = Color3.fromRGB(150, 170, 220)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = bottomBar

-- ==================== 正方体参数 ====================
local cubeSize = 2.5
local halfSize = cubeSize / 2

local vertices = {
    {x = -halfSize, y = -halfSize, z = -halfSize},
    {x =  halfSize, y = -halfSize, z = -halfSize},
    {x =  halfSize, y =  halfSize, z = -halfSize},
    {x = -halfSize, y =  halfSize, z = -halfSize},
    {x = -halfSize, y = -halfSize, z =  halfSize},
    {x =  halfSize, y = -halfSize, z =  halfSize},
    {x =  halfSize, y =  halfSize, z =  halfSize},
    {x = -halfSize, y =  halfSize, z =  halfSize},
}

local edges = {
    {1, 2}, {2, 3}, {3, 4}, {4, 1},
    {5, 6}, {6, 7}, {7, 8}, {8, 5},
    {1, 5}, {2, 6}, {3, 7}, {4, 8},
}

-- 三层线条
local outerGlows, midGlows, coreLines = {}, {}, {}
for i = 1, 12 do
    local outer = Drawing.new("Line")
    outer.Visible = true; outer.Thickness = 14; outer.Transparency = 0.8
    table.insert(outerGlows, outer)
    local mid = Drawing.new("Line")
    mid.Visible = true; mid.Thickness = 7; mid.Transparency = 0.5
    table.insert(midGlows, mid)
    local core = Drawing.new("Line")
    core.Visible = true; core.Color = Color3.fromRGB(255, 255, 255); core.Thickness = 2.5; core.Transparency = 0
    table.insert(coreLines, core)
end

-- 顶点球
local vertexDots = {}
for i = 1, 8 do
    local dot = Drawing.new("Circle")
    dot.Visible = true; dot.Filled = true; dot.Radius = 5; dot.Color = Color3.fromRGB(255, 255, 255)
    table.insert(vertexDots, dot)
    local dotGlow = Drawing.new("Circle")
    dotGlow.Visible = true; dotGlow.Filled = true; dotGlow.Radius = 12; dotGlow.Transparency = 0.7
    table.insert(vertexDots, dotGlow)
end

-- 背景粒子
local bgParticles = {}
for i = 1, 40 do
    local p = Drawing.new("Circle")
    p.Visible = true; p.Filled = true; p.Radius = math.random(1, 2)
    p.Position = Vector2.new(math.random(0, 2000), math.random(0, 2000))
    p.Color = Color3.fromRGB(60 + math.random(0, 30), 60 + math.random(0, 30), 90 + math.random(0, 40))
    p.Transparency = 0.3 + math.random() * 0.5
    table.insert(bgParticles, {dot = p, speed = 0.15 + math.random() * 0.5, x = math.random(0, 2000), y = math.random(0, 2000)})
end

-- 动画
local hue = 0
local angleX = 0
local angleY = 0
local loadProgress = 0
local time = 0

local function rotateX(p, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {x = p.x, y = p.y * c - p.z * s, z = p.y * s + p.z * c}
end

local function rotateY(p, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {x = p.x * c + p.z * s, y = p.y, z = -p.x * s + p.z * c}
end

local connection = RunService.RenderStepped:Connect(function(dt)
    time = time + dt
    angleX = angleX + 0.015
    angleY = angleY + 0.015 * 0.7
    hue = (hue + 0.5) % 360
    local col = Color3.fromHSV(hue / 360, 1, 1)
    
    loadProgress = math.min(loadProgress + dt * 0.25, 1)
    
    -- 状态文字
    if loadProgress < 0.3 then statusLabel.Text = "INITIALIZING..."
    elseif loadProgress < 0.6 then statusLabel.Text = "LOADING ASSETS..."
    elseif loadProgress < 0.9 then statusLabel.Text = "RENDERING..."
    else statusLabel.Text = "READY" end
    
    -- 容器边框颜色
    containerStroke.Color = col
    
    local vw = Camera.ViewportSize.X
    local vh = Camera.ViewportSize.Y
    
    -- 计算屏幕坐标
    local screenPoints = {}
    local scale = math.min(vw, vh) * 0.22
    local cx = vw / 2
    local cy = vh / 2 - 10
    
    for i, v in ipairs(vertices) do
        local p = rotateX(v, angleX)
        p = rotateY(p, angleY)
        local distance = 5
        local perspective = distance / (distance - p.z)
        screenPoints[i] = {
            x = cx + p.x * scale * perspective,
            y = cy + p.y * scale * perspective
        }
    end
    
    -- 更新线条
    for j, edge in ipairs(edges) do
        local p1 = screenPoints[edge[1]]
        local p2 = screenPoints[edge[2]]
        outerGlows[j].From = Vector2.new(p1.x, p1.y); outerGlows[j].To = Vector2.new(p2.x, p2.y); outerGlows[j].Color = col
        midGlows[j].From = Vector2.new(p1.x, p1.y); midGlows[j].To = Vector2.new(p2.x, p2.y); midGlows[j].Color = col
        coreLines[j].From = Vector2.new(p1.x, p1.y); coreLines[j].To = Vector2.new(p2.x, p2.y)
    end
    
    for i = 1, 8 do
        local pos = screenPoints[i]
        vertexDots[(i-1)*2 + 1].Position = Vector2.new(pos.x, pos.y)
        vertexDots[(i-1)*2 + 1].Color = col
        vertexDots[(i-1)*2 + 2].Position = Vector2.new(pos.x, pos.y)
        vertexDots[(i-1)*2 + 2].Color = col
    end
    
    for _, p in ipairs(bgParticles) do
        p.y = p.y - p.speed
        if p.y < -10 then p.y = vh + 10; p.x = math.random(0, vw) end
        p.dot.Position = Vector2.new(p.x, p.y)
        p.dot.Transparency = 0.3 + math.sin(time * 2 + p.x * 0.01) * 0.3
    end
end)

task.wait(3.5)
connection:Disconnect()

-- 淡出
local fadeOut = 0
local fadeConn = RunService.RenderStepped:Connect(function(dt)
    fadeOut = fadeOut + dt * 2
    bg.Transparency = fadeOut
    containerGlow.BackgroundTransparency = 0.2 + fadeOut * 0.8
    containerInner.BackgroundTransparency = 0.15 + fadeOut * 0.85
    containerStroke.Transparency = 0.5 + fadeOut * 0.5
    topTitle.TextTransparency = fadeOut
    versionLabel.TextTransparency = fadeOut
    statusLabel.TextTransparency = fadeOut
    
    for i = 1, 12 do
        outerGlows[i].Transparency = math.min(1, 0.8 + fadeOut)
        midGlows[i].Transparency = math.min(1, 0.5 + fadeOut)
        coreLines[i].Transparency = fadeOut
    end
    for _, dot in ipairs(vertexDots) do dot.Transparency = fadeOut end
    for _, p in ipairs(bgParticles) do p.dot.Transparency = math.min(1, p.dot.Transparency + dt * 2) end
    
    if fadeOut >= 1 then
        fadeConn:Disconnect()
        bg:Remove()
        for i = 1, 12 do outerGlows[i]:Remove(); midGlows[i]:Remove(); coreLines[i]:Remove() end
        for _, dot in ipairs(vertexDots) do dot:Remove() end
        for _, p in ipairs(bgParticles) do p.dot:Remove() end
        container:Destroy()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

print("3D霓虹正方体 + 圆角容器 - 完成!")
