-- ============================================
-- 3D霓虹正方体 - 屏幕绘制版（跟随视角）
-- ============================================

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 正方体参数
local cubeSize = 2.5
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

-- 创建12条线的Drawing对象
local lines = {}
for i = 1, 12 do
    local line = Drawing.new("Line")
    line.Visible = true
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 2.5
    line.Transparency = 0
    table.insert(lines, line)
end

-- UI
local SplashScreen = Instance.new("ScreenGui")
SplashScreen.Name = "Splash"
SplashScreen.Parent = LocalPlayer:WaitForChild("PlayerGui")
SplashScreen.ResetOnSpawn = false
SplashScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SplashScreen.DisplayOrder = 999

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 36)
titleLabel.Position = UDim2.new(0, 0, 0.78, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "加载中..."
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Parent = SplashScreen

local loadBarBg = Instance.new("Frame")
loadBarBg.Size = UDim2.new(0, 180, 0, 3)
loadBarBg.Position = UDim2.new(0.5, -90, 0.88, 0)
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
    
    -- 正方体放在屏幕正前方，用世界坐标计算
    local viewportSize = Camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    
    -- 在相机前方8个单位处放置正方体
    local cubeCenter = Camera.CFrame.Position + Camera.CFrame.LookVector * 8
    
    -- 计算旋转后顶点，投影到屏幕
    local sv = {}
    for i, v in ipairs(vertices) do
        local p = rotateX(v, angleX)
        p = rotateY(p, angleY)
        -- 转换到世界坐标（基于相机朝向）
        local worldPos = cubeCenter + Camera.CFrame.RightVector * p.X + Camera.CFrame.UpVector * p.Y - Camera.CFrame.LookVector * p.Z
        local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
        sv[i] = screenPos
    end
    
    -- 更新线条，让正方体在屏幕中心显示
    for j, edge in ipairs(edges) do
        local p1 = sv[edge[1]]
        local p2 = sv[edge[2]]
        lines[j].From = Vector2.new(p1.X, p1.Y)
        lines[j].To = Vector2.new(p2.X, p2.Y)
        lines[j].Color = col
    end
    
    -- 标题随颜色变化
    if loadProgress < 0.3 then titleLabel.Text = "加载中..."
    elseif loadProgress < 0.6 then titleLabel.Text = "初始化..."
    elseif loadProgress < 0.9 then titleLabel.Text = "渲染中..."
    else titleLabel.Text = "即将完成" end
end)

task.wait(3)
loadBar.Size = UDim2.new(1, 0, 1, 0)
task.wait(0.5)
connection:Disconnect()

-- 淡出
for _, line in ipairs(lines) do line:Remove() end
SplashScreen:Destroy()
print("3D霓虹正方体 完成!")
