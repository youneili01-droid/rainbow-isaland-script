-- 初始化参数
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- 1. 定义 3D 正方体的 8 个顶点坐标
local vertices = {
    {x = -1, y = -1, z = -1}, -- 1
    {x =  1, y = -1, z = -1}, -- 2
    {x =  1, y =  1, z = -1}, -- 3
    {x = -1, y =  1, z = -1}, -- 4
    {x = -1, y = -1, z =  1}, -- 5
    {x =  1, y = -1, z =  1}, -- 6
    {x =  1, y =  1, z =  1}, -- 7
    {x = -1, y =  1, z =  1}  -- 8
}

-- 2. 定义 12 条边（索引从 1 开始）
local edges = {
    {1, 2}, {2, 3}, {3, 4}, {4, 1},
    {5, 6}, {6, 7}, {7, 8}, {8, 5},
    {1, 5}, {2, 6}, {3, 7}, {4, 8}
}

-- 3. 创建 Drawing 2D 线条（每条边需要两层线来实现霓虹发光）
local lines = {}
for i = 1, #edges do
    -- 外层粗线（用于模拟发光）
    local glowLine = Drawing.new("Line")
    glowLine.Thickness = 12
    glowLine.Transparency = 0.25
    glowLine.Visible = true
    
    -- 内层细线（核心高亮）
    local coreLine = Drawing.new("Line")
    coreLine.Thickness = 3
    coreLine.Transparency = 1
    coreLine.Visible = true
    
    table.insert(lines, {glow = glowLine, core = coreLine})
end

-- 旋转控制变量
local angleX = 0
local angleY = 0
local rotateSpeed = 0.015
local hue = 0
local rainbowSpeed = 0.002

-- 旋转矩阵函数
local function rotateX(p, angle)
    local cos, sin = Math.cos(angle), Math.sin(angle)
    return {
        x = p.x,
        y = p.y * cos - p.z * sin,
        z = p.y * sin + p.z * cos
    }
end

local function rotateY(p, angle)
    local cos, sin = Math.cos(angle), Math.sin(angle)
    return {
        x = p.x * cos + p.z * sin,
        y = p.y,
        z = -p.x * sin + p.z * cos
    }
end

-- 主渲染循环
local connection
connection = RunService.RenderStepped:Connect(function()
    -- 安全退出检测：如果脚本创建的某条线被意外销毁则停止循环
    if not lines[1] or not lines[1].core then 
        connection:Disconnect() 
        return 
    end

    -- 更新旋转角度与颜色
    angleX = angleX + rotateSpeed
    angleY = angleY + rotateSpeed * 0.7
    hue = (hue + rainbowSpeed) % 1
    local color = Color3.fromHSV(hue, 1, 1)

    -- 计算屏幕中心和缩放
    local viewportSize = Camera.ViewportSize
    local cx = viewportSize.X / 2
    local cy = viewportSize.Y / 2
    local scale = Math.min(viewportSize.X, viewportSize.Y) * 0.25

    -- 计算 3D 到 2D 投影点
    local screenPoints = {}
    for i = 1, #vertices do
        local p = rotateX(vertices[i], angleX)
        p = rotateY(p, angleY)

        local distance = 4
        local perspective = distance / (distance - p.z)
        
        screenPoints[i] = Vector2.new(
            cx + p.x * scale * perspective,
            cy + p.y * scale * perspective
        )
    end

    -- 更新所有线条的坐标与颜色
    for i, edge in ipairs(edges) do
        local p1 = screenPoints[edge[1]]
        local p2 = screenPoints[edge[2]]
        local element = lines[i]

        -- 外层发光线
        element.glow.From = p1
        element.glow.To = p2
        element.glow.Color = color

        -- 内层核心线
        element.core.From = p1
        element.core.To = p2
        element.core.Color = Color3.new(1, 1, 1) -- 白色核心能让霓虹质感更好
    end
end)
