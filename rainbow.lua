-- ============================================
-- 3D霓虹发光正方体 - 粗线发光版
-- ============================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 正方体参数
local cubeSize = 2
local halfSize = cubeSize / 2

-- 8个顶点
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

-- 12条边
local edges = {
    {1, 2}, {2, 3}, {3, 4}, {4, 1},
    {5, 6}, {6, 7}, {7, 8}, {8, 5},
    {1, 5}, {2, 6}, {3, 7}, {4, 8},
}

-- 创建线条 - 双层模拟发光
local lines = {}
local glows = {}
for i = 1, 12 do
    -- 外层发光（粗+透明）
    local glow = Drawing.new("Line")
    glow.Visible = true
    glow.Color = Color3.fromRGB(255, 0, 0)
    glow.Thickness = 8
    glow.Transparency = 0.6
    table.insert(glows, glow)
    
    -- 内层实线（细+不透明）
    local line = Drawing.new("Line")
    line.Visible = true
    line.Color = Color3.fromRGB(255, 255, 255)
    line.Thickness = 4
    line.Transparency = 0
    table.insert(lines, line)
end

-- UI
local SplashScreen = Instance.new("ScreenGui")
SplashScreen.Name = "Splash"
SplashScreen.Parent = LocalPlayer:WaitForChild("PlayerGui")
SplashScreen.ResetOnSpawn = false
SplashScreen.DisplayOrder = 999

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 36)
titleLabel.Position = UDim2.new(0, 0, 0.76, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "新项目"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 26
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Parent = SplashScreen

local loadBarBg = Instance.new("Frame")
loadBarBg.Size = UDim2.new(0, 160, 0, 3)
loadBarBg.Position = UDim2.new(0.5, -80, 0.86, 0)
loadBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
loadBarBg.BorderSizePixel = 0
loadBarBg.Parent = SplashScreen
Instance.new("UICorner", loadBarBg).CornerRadius = UDim.new(1, 0)

local loadBar = Instance.new("Frame")
loadBar.Size = UDim2.new(0, 0, 1, 0)
loadBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
loadBar.BorderSizePixel = 0
loadBar.Parent = loadBarBg
Instance.new("UICorner", loadBar).CornerRadius = UDim.new(1, 0)

-- 动画
local hue = 0
local angleX = 0
local angleY = 0
local loadProgress = 0

local function rotateX(p, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {x = p.x, y = p.y * c - p.z * s, z = p.y * s + p.z * c}
end

local function rotateY(p, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return {x = p.x * c + p.z * s, y = p.y, z = -p.x * s + p.z * c}
end

local connection = RunService.RenderStepped:Connect(function(dt)
    angleX = angleX + 0.015
    angleY = angleY + 0.015 * 0.7
    hue = (hue + 0.5) % 360
    local col = Color3.fromHSV(hue / 360, 1, 1)
    local colBright = Color3.fromHSV(hue / 360, 0.6, 1)
    
    loadProgress = math.min(loadProgress + dt * 0.3, 1)
    loadBar.Size = UDim2.new(loadProgress, 0, 1, 0)
    loadBar.BackgroundColor3 = col
    
    -- 计算屏幕坐标
    local screenPoints = {}
    local scale = math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 0.22
    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    
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
        
        -- 外层发光
        glows[j].From = Vector2.new(p1.x, p1.y)
        glows[j].To = Vector2.new(p2.x, p2.y)
        glows[j].Color = col
        
        -- 内层白线
        lines[j].From = Vector2.new(p1.x, p1.y)
        lines[j].To = Vector2.new(p2.x, p2.y)
        lines[j].Color = Color3.fromRGB(255, 255, 255)
    end
    
    titleLabel.TextTransparency = 0.1 + math.sin(angleX * 2) * 0.1
end)

task.wait(3)
connection:Disconnect()

-- 淡出
local ts = TweenService
local fi = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
ts:Create(titleLabel, fi, {TextTransparency = 1}):Play()
ts:Create(loadBarBg, fi, {BackgroundTransparency = 1}):Play()
ts:Create(loadBar, fi, {BackgroundTransparency = 1}):Play()

task.wait(0.5)
for i = 1, 12 do
    lines[i]:Remove()
    glows[i]:Remove()
end
SplashScreen:Destroy()
print("完成!")
