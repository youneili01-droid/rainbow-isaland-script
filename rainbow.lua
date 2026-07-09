-- ============================================
-- 3D 可旋转内容面板（SurfaceGUI 版）
-- 修复旋转滑动条 + 增添 ESP / 功能 / 娱乐面板
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local root = (player.Character or player.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local rotateAngle = 0  -- 当前旋转角度（-180 到 180）

-- ==================== 创建单个 SurfaceGui 面板 ====================
local function createPanel()
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = false; p.CastShadow = false
    p.Size = Vector3.new(4, 6, 0.08); p.Transparency = 1
    p.Parent = workspace

    local function addFace(face)
        local gui = Instance.new("SurfaceGui")
        gui.Face = face; gui.AlwaysOnTop = false; gui.LightInfluence = 0
        gui.CanvasSize = Vector2.new(400, 600)
        gui.Parent = p

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 30)
        corner.Parent = frame

        -- ============ 标题栏 ============
        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 42)
        topBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        topBar.BackgroundTransparency = 0.92
        topBar.BorderSizePixel = 0
        topBar.Parent = frame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -16, 1, 0)
        title.Position = UDim2.new(0, 8, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "RAINBOW PANEL"
        title.TextColor3 = Color3.fromRGB(200, 220, 255)
        title.TextSize = 14; title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = topBar

        -- ============ 内容区域 ============
        local content = Instance.new("ScrollingFrame")
        content.Size = UDim2.new(1, -16, 1, -130)
        content.Position = UDim2.new(0, 8, 0, 48)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 3
        content.ScrollBarImageColor3 = Color3.fromRGB(60, 100, 200)
        content.CanvasSize = UDim2.new(0, 0, 0, 600)
        content.Parent = frame

        local contentList = Instance.new("UIListLayout")
        contentList.SortOrder = Enum.SortOrder.LayoutOrder
        contentList.Padding = UDim.new(0, 8)
        contentList.Parent = content

        contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 16)
        end)

        -- ============ 功能按钮 ============
        local function addButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 42)
            btn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
            btn.BackgroundTransparency = 0.4
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(200, 220, 255)
            btn.TextSize = 13; btn.Font = Enum.Font.GothamMedium
            btn.BorderSizePixel = 0
            btn.Parent = content
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
            local st = Instance.new("UIStroke")
            st.Color = Color3.fromRGB(60, 120, 255); st.Thickness = 1; st.Transparency = 0.5
            st.Parent = btn
            btn.MouseButton1Click:Connect(callback)
            return btn
        end

        local function addLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Color3.fromRGB(150, 170, 220)
            lbl.TextSize = 11; lbl.Font = Enum.Font.GothamMedium
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = content
            return lbl
        end

        -- 添加一些内容到面板
        addLabel("—— 功能列表 ——")
        addButton("开启飞行", function() print("飞行已开启") end)
        addButton("开启ESP", function() print("ESP已开启") end)
        addButton("开启自瞄", function() print("自瞄已开启") end)
        addLabel("—— 玩家列表 ——")
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player then
                addButton(pl.Name, function() print("选中: " .. pl.Name) end)
            end
        end

        -- ============ 底部收起按钮 ============
        local bottomBar = Instance.new("Frame")
        bottomBar.Size = UDim2.new(1, 0, 0, 60)
        bottomBar.Position = UDim2.new(0, 0, 1, -60)
        bottomBar.BackgroundTransparency = 1
        bottomBar.Parent = frame

        local open = true
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 140, 0, 44)
        toggleBtn.Position = UDim2.new(0.5, -70, 0, 8)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        toggleBtn.Text = "收起"
        toggleBtn.TextScaled = true
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Parent = bottomBar
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 22)

        toggleBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                toggleBtn.Text = "收起"
                TweenService:Create(frame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)}):Play()
            else
                toggleBtn.Text = "展开"
                TweenService:Create(frame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)}):Play()
            end
        end)
    end

    addFace(Enum.NormalId.Front)
    addFace(Enum.NormalId.Back)
    addFace(Enum.NormalId.Left)
    addFace(Enum.NormalId.Right)

    return p
end

-- ==================== 创建两个面板 ====================
local leftPanel = createPanel()
local rightPanel = createPanel()

local startCF = root.CFrame
local forward = startCF.LookVector
local rightVec = startCF.RightVector

local leftOffset = forward * 5 - rightVec * 2.5 + Vector3.new(0, -1.3, 0)
local rightOffset = forward * 5 + rightVec * 2.5 + Vector3.new(0, -1.3, 0)

local leftCF = CFrame.lookAt(root.Position + leftOffset, root.Position) * CFrame.Angles(0, math.rad(165), 0)
local rightCF = CFrame.lookAt(root.Position + rightOffset, root.Position) * CFrame.Angles(0, math.rad(195), 0)

local leftRotation = leftCF - leftCF.Position
local rightRotation = rightCF - rightCF.Position

-- ==================== 顶部滑动条 ====================
local sliderPart = Instance.new("Part")
sliderPart.Anchored = true; sliderPart.CanCollide = false; sliderPart.CastShadow = false
sliderPart.Transparency = 1; sliderPart.Size = Vector3.new(3.5, 0.35, 0.08)
sliderPart.Parent = workspace

local sliderGui = Instance.new("SurfaceGui")
sliderGui.Face = Enum.NormalId.Front; sliderGui.AlwaysOnTop = false; sliderGui.LightInfluence = 0
sliderGui.CanvasSize = Vector2.new(350, 50)
sliderGui.Parent = sliderPart

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(1, 1)
bar.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
bar.BackgroundTransparency = 0.1
bar.BorderSizePixel = 0
bar.Parent = sliderGui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 20)

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(60, 120, 255); barStroke.Thickness = 1; barStroke.Transparency = 0.5
barStroke.Parent = bar

-- 角度显示
local angleLabel = Instance.new("TextLabel")
angleLabel.Size = UDim2.new(1, 0, 1, 0)
angleLabel.BackgroundTransparency = 1
angleLabel.Text = "0°"
angleLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
angleLabel.TextSize = 12; angleLabel.Font = Enum.Font.GothamBold
angleLabel.Parent = bar

-- 旋钮
local knob = Instance.new("TextButton")
knob.Size = UDim2.new(0, 60, 1, 0)
knob.Position = UDim2.new(0.5, -30, 0, 0)
knob.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
knob.Text = "↔"
knob.TextScaled = true
knob.TextColor3 = Color3.new(1, 1, 1)
knob.Parent = bar
Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 20)

-- 滑动逻辑（修复版）
local dragging = false
local startMouseX = 0
local startAngle = 0

knob.MouseButton1Down:Connect(function()
    dragging = true
    startMouseX = UserInputService:GetMouseLocation().X
    startAngle = rotateAngle
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local deltaX = UserInputService:GetMouseLocation().X - startMouseX
        -- 滑动条总宽度约350px，对应-180到180度
        local newAngle = startAngle + (deltaX / 350) * 360
        rotateAngle = math.clamp(newAngle, -180, 180)
        
        -- 更新旋钮位置
        local pos = (rotateAngle + 180) / 360
        knob.Position = UDim2.new(pos, -30, 0, 0)
        angleLabel.Text = math.floor(rotateAngle) .. "°"
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ==================== 每帧更新面板位置 ====================
RunService.RenderStepped:Connect(function()
    if not root or not root.Parent then return end

    local rotateCF = CFrame.Angles(0, math.rad(rotateAngle), 0)

    -- 更新面板
    leftPanel.CFrame = rotateCF * leftRotation + (root.Position + leftOffset)
    rightPanel.CFrame = rotateCF * rightRotation + (root.Position + rightOffset)

    -- 更新滑条
    sliderPart.CFrame = CFrame.new(root.Position + forward * 5 + Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, math.rad(180), 0)
end)

print("3D 旋转内容面板 + 滑动条 - 加载完成")
