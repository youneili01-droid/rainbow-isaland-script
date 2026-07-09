-- ============================================
-- 3D霓虹发光正方体 - 精简版（无线条端点）
-- ============================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 正方体参数（缩小）
local cubeSize = 2
local halfSize = cubeSize / 2

-- 8个顶点
local vertices = {
    Vector3.new(-halfSize, -halfSize, -halfSize),
    Vector3.new( halfSize, -halfSize, -halfSize),
    Vector3.new( halfSize,  halfSize, -halfSize),
    Vector3.new(-halfSize,  halfSize, -halfSize),
    Vector3.new(-halfSize, -halfSize,  halfSize),
    Vector3.new( halfSize, -halfSize,  halfSize),
    Vector3.new( halfSize,  halfSize,  halfSize),
    Vector3.new(-halfSize,  halfSize,  halfSize),
}

-- 12条边
local edges = {
    {1, 2}, {2, 3}, {3, 4}, {4, 1},
    {5, 6}, {6, 7}, {7, 8}, {8, 5},
    {1, 5}, {2, 6}, {3, 7}, {4, 8},
}

-- 只创建12条棱（无顶点球）
local edgeParts = {}
for _, edge in ipairs(edges) do
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.05, 0.05, 1)
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(255, 0, 0)
    part.Parent = workspace
    table.insert(edgeParts, part)
end

-- 相机
Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = CFrame.new(Vector3.new(0, 0, 7), Vector3.new(0, 0, 0))
Camera.FieldOfView = 40

-- UI
local SplashScreen = Instance.new("ScreenGui")
SplashScreen.Name = "Splash"
SplashScreen.Parent = LocalPlayer:WaitForChild("PlayerGui")
SplashScreen.ResetOnSpawn = false
SplashScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SplashScreen.DisplayOrder = 999
SplashScreen.IgnoreGuiInset = true

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 36)
titleLabel.Position = UDim2.new(0, 0, 0.75, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "新项目"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 26
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextStrokeTransparency = 0.3
titleLabel.TextStrokeColor3 = Color3.fromRGB(100, 150, 255)
titleLabel.ZIndex = 10
titleLabel.Parent = SplashScreen

local loadBarBg = Instance.new("Frame")
loadBarBg.Size = UDim2.new(0, 180, 0, 3)
loadBarBg.Position = UDim2.new(0.5, -90, 0.86, 0)
loadBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
loadBarBg.BorderSizePixel = 0
loadBarBg.ZIndex = 10
loadBarBg.Parent = SplashScreen
Instance.new("UICorner", loadBarBg).CornerRadius = UDim.new(1, 0)

local loadBar = Instance.new("Frame")
loadBar.Size = UDim2.new(0, 0, 1, 0)
loadBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
loadBar.BorderSizePixel = 0
loadBar.ZIndex = 10
loadBar.Parent = loadBarBg
Instance.new("UICorner", loadBar).CornerRadius = UDim.new(1, 0)

-- 动画
local hue = 0
local angleX = 0
local angleY = 0
local loadProgress = 0

local function rotateX(pos, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return Vector3.new(pos.X, pos.Y * c - pos.Z * s, pos.Y * s + pos.Z * c)
end

local function rotateY(pos, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return Vector3.new(pos.X * c + pos.Z * s, pos.Y, -pos.X * s + pos.Z * c)
end

local connection = RunService.RenderStepped:Connect(function(dt)
    angleX = angleX + 0.015
    angleY = angleY + 0.015 * 0.7
    hue = (hue + 0.5) % 360
    local col = Color3.fromHSV(hue / 360, 1, 1)
    
    loadProgress = math.min(loadProgress + dt * 0.3, 1)
    loadBar.Size = UDim2.new(loadProgress, 0, 1, 0)
    loadBar.BackgroundColor3 = col
    titleLabel.TextStrokeColor3 = col
    
    -- 计算旋转后顶点
    local rv = {}
    local d = 3.5
    for i, v in ipairs(vertices) do
        local p = rotateX(v, angleX)
        p = rotateY(p, angleY)
        local per = d / (d - p.Z)
        rv[i] = Vector3.new(p.X * per, p.Y * per, 0)
    end
    
    -- 更新棱
    for j, edge in ipairs(edges) do
        local p1 = rv[edge[1]]
        local p2 = rv[edge[2]]
        local mid = (p1 + p2) / 2
        local len = (p2 - p1).Magnitude
        
        edgeParts[j].Size = Vector3.new(0.05, 0.05, len)
        edgeParts[j].CFrame = CFrame.new(mid, p2)
        edgeParts[j].Color = col
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
for _, p in ipairs(edgeParts) do ts:Create(p, fi, {Transparency = 1}):Play() end

task.wait(0.5)
for _, p in ipairs(edgeParts) do p:Destroy() end
SplashScreen:Destroy()
Camera.CameraType = Enum.CameraType.Custom
print("3D霓虹正方体 完成!")
