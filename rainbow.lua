-- ============================================
-- 3D霓虹正方体 - Roblox预加载画面
-- ============================================

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SplashScreen = Instance.new("ScreenGui")
SplashScreen.Name = "NeonSplash"
SplashScreen.Parent = LocalPlayer:WaitForChild("PlayerGui")
SplashScreen.ResetOnSpawn = false
SplashScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SplashScreen.DisplayOrder = 999

-- 背景
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
bg.BorderSizePixel = 0
bg.Parent = SplashScreen

-- 3D正方体用ViewportFrame
local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(0, 300, 0, 300)
viewport.Position = UDim2.new(0.5, -150, 0.4, -150)
viewport.BackgroundTransparency = 1
viewport.BorderSizePixel = 0
viewport.Parent = SplashScreen

-- 正方体模型
local cubeModel = Instance.new("Model")
cubeModel.Name = "NeonCube"
cubeModel.Parent = viewport

-- 12条边用细Part
local edgeParts = {}
local edges = {
    {0,1},{1,2},{2,3},{3,0},
    {4,5},{5,6},{6,7},{7,4},
    {0,4},{1,5},{2,6},{3,7}
}
local verts = {
    Vector3.new(-2, -2, -2), Vector3.new(2, -2, -2),
    Vector3.new(2, 2, -2),   Vector3.new(-2, 2, -2),
    Vector3.new(-2, -2, 2),  Vector3.new(2, -2, 2),
    Vector3.new(2, 2, 2),    Vector3.new(-2, 2, 2)
}

for _, edge in ipairs(edges) do
    local p1 = verts[edge[1] + 1]
    local p2 = verts[edge[2] + 1]
    local mid = (p1 + p2) / 2
    local length = (p2 - p1).Magnitude
    local dir = (p2 - p1).Unit
    
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.12, 0.12, length)
    part.CFrame = CFrame.new(mid, mid + dir)
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new("Really blue")
    part.Parent = cubeModel
    
    -- 发光
    local glow = Instance.new("PointLight")
    glow.Brightness = 0.5
    glow.Range = 4
    glow.Color = Color3.fromRGB(100, 150, 255)
    glow.Parent = part
    
    table.insert(edgeParts, {part = part, glow = glow})
end

-- 顶点球体
for _, v in ipairs(verts) do
    local sphere = Instance.new("Part")
    sphere.Size = Vector3.new(0.3, 0.3, 0.3)
    sphere.Shape = Enum.PartType.Ball
    sphere.Position = v
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Material = Enum.Material.Neon
    sphere.BrickColor = BrickColor.new("White")
    sphere.Parent = cubeModel
    
    local glow = Instance.new("PointLight")
    glow.Brightness = 1
    glow.Range = 5
    glow.Color = Color3.fromRGB(200, 200, 255)
    glow.Parent = sphere
end

-- 相机
local cam = Instance.new("Camera")
cam.Parent = viewport
cam.CFrame = CFrame.new(Vector3.new(0, 0, 10), Vector3.new(0, 0, 0))
viewport.CurrentCamera = cam

-- 标题
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0.62, 0)
title.BackgroundTransparency = 1
title.Text = "新项目"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 28
title.Font = Enum.Font.GothamBlack
title.TextStrokeTransparency = 0
title.TextStrokeColor3 = Color3.fromRGB(50, 100, 255)
title.Parent = SplashScreen

-- 加载条
local loadBg = Instance.new("Frame")
loadBg.Size = UDim2.new(0, 180, 0, 4)
loadBg.Position = UDim2.new(0.5, -90, 0.7, 0)
loadBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
loadBg.BorderSizePixel = 0
loadBg.Parent = SplashScreen
Instance.new("UICorner", loadBg).CornerRadius = UDim.new(1, 0)

local loadBar = Instance.new("Frame")
loadBar.Size = UDim2.new(0, 0, 1, 0)
loadBar.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
loadBar.BorderSizePixel = 0
loadBar.Parent = loadBg
Instance.new("UICorner", loadBar).CornerRadius = UDim.new(1, 0)

local loadGlow = Instance.new("UIStroke")
loadGlow.Color = Color3.fromRGB(150, 200, 255)
loadGlow.Thickness = 1.5
loadGlow.Transparency = 0.3
loadGlow.Parent = loadBar

-- 动画
local totalTime = 0
local hue = 0
local progress = 0

local conn = RunService.RenderStepped:Connect(function(dt)
    totalTime += dt
    progress = math.min(progress + dt * 0.35, 1)
    loadBar.Size = UDim2.new(progress, 0, 1, 0)
    
    -- 旋转正方体
    local rotY = totalTime * 1.5
    local rotX = totalTime * 1.0
    cubeModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(rotX, rotY, 0))
    
    -- 彩虹色
    hue = (hue + dt * 60) % 360
    local r, g, b = Color3.fromHSV(hue / 360, 1, 1).R, Color3.fromHSV(hue / 360, 1, 1).G, Color3.fromHSV(hue / 360, 1, 1).B
    
    for _, data in ipairs(edgeParts) do
        data.part.Color = Color3.fromRGB(r * 255, g * 255, b * 255)
        data.glow.Color = Color3.fromRGB(r * 255, g * 255, b * 255)
    end
    
    -- 标题呼吸
    title.TextTransparency = 0.1 + math.sin(totalTime * 1.5) * 0.1
    loadGlow.Thickness = 1.5 + math.sin(totalTime * 4) * 0.8
end)

-- 2.5秒后淡出
task.wait(2.5)
local fi = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(bg, fi, {BackgroundTransparency = 1}):Play()
TweenService:Create(title, fi, {TextTransparency = 1}):Play()
TweenService:Create(loadBg, fi, {BackgroundTransparency = 1}):Play()
TweenService:Create(loadBar, fi, {BackgroundTransparency = 1}):Play()
task.wait(0.5)
conn:Disconnect()
SplashScreen:Destroy()

print("3D霓虹正方体加载完成!")
