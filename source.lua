local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local FlurioreLib = {
    Flags = {},
    Themes = {
        Black = {
            Name = "Black",
            Background = Color3.fromRGB(15, 15, 15),
            Container = Color3.fromRGB(20, 20, 20),
            ContainerTransparency = 0.1,
            Border = Color3.fromRGB(30, 30, 30),
            Text = Color3.fromRGB(255, 255, 255),
            SubText = Color3.fromRGB(180, 180, 180),
            Accent = Color3.fromRGB(200, 200, 200),
            ToggleOn = Color3.fromRGB(200, 200, 200),
            ToggleOff = Color3.fromRGB(80, 80, 80),
            SliderBar = Color3.fromRGB(60, 60, 60),
            InputBg = Color3.fromRGB(25, 25, 25),
            DropdownArrow = Color3.fromRGB(180, 180, 180),
            TitleAccent = Color3.fromRGB(200, 200, 200), -- color for description line
        }
    },
    CurrentTheme = "Black",
}

local Theme = FlurioreLib.Themes[FlurioreLib.CurrentTheme]

-- [[ Helper Functions ]]
local function CircleClick(Button, X, Y)
    Button.ClipsDescendants = true
    local Circle = Instance.new("ImageLabel")
    Circle.Image = "rbxassetid://266543268"
    Circle.ImageColor3 = Color3.fromRGB(255,255,255)
    Circle.ImageTransparency = 0.9
    Circle.BackgroundTransparency = 1
    Circle.ZIndex = 10
    Circle.Size = UDim2.new(0,0,0,0)
    Circle.AnchorPoint = Vector2.new(0.5,0.5)
    Circle.Position = UDim2.new(0, X - Button.AbsolutePosition.X, 0, Y - Button.AbsolutePosition.Y)
    Circle.Parent = Button

    local Size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5
    local tween = TweenService:Create(Circle, TweenInfo.new(0.5), {
        Size = UDim2.new(0, Size, 0, Size),
        Position = UDim2.new(0.5, -Size/2, 0.5, -Size/2),
        ImageTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function() Circle:Destroy() end)
end

local function MakeDraggable(topbar, object)
    local dragConn, moveConn
    local startPos, dragStart

    dragConn = topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = object.Position

            local inputEnded
            inputEnded = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragConn:Disconnect()
                    if moveConn then moveConn:Disconnect() end
                    inputEnded:Disconnect()
                end
            end)

            moveConn = topbar.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                    local delta = moveInput.Position - dragStart
                    object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end
    end)
end

local function AddResizeHandle(object, minWidth, minHeight)
    local handle = Instance.new("Frame")
    handle.AnchorPoint = Vector2.new(1,1)
    handle.BackgroundColor3 = Color3.new(1,1,1)
    handle.BackgroundTransparency = 0.999
    handle.Size = UDim2.new(0,40,0,40)
    handle.Position = UDim2.new(1,20,1,20)
    handle.Name = "ResizeHandle"
    handle.Parent = object

    local dragging, startPos, startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startSize = object.Size
            local inputEnded
            inputEnded = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    inputEnded:Disconnect()
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - startPos
            local newWidth = math.max(minWidth, startSize.X.Offset + delta.X)
            local newHeight = math.max(minHeight, startSize.Y.Offset + delta.Y)
            object.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)
end

-- [[ Save Manager ]]
local function SaveSettings()
    local success, result = pcall(function()
        local data = {}
        for flagName, flag in pairs(FlurioreLib.Flags) do
            data[flagName] = flag.Value
        end
        if writefile then
            writefile("FlurioreLib_Settings.json", HttpService:JSONEncode(data))
        end
    end)
    if not success then warn("Save failed: " .. tostring(result)) end
end

local function LoadSettings()
    local success, result = pcall(function()
        if not readfile then return end
        local content = readfile("FlurioreLib_Settings.json")
        if content then
            local data = HttpService:JSONDecode(content)
            for flagName, value in pairs(data) do
                if FlurioreLib.Flags[flagName] then
                    FlurioreLib.Flags[flagName]:Set(value, true) -- skip callback to avoid loops
                end
            end
        end
    end)
    if not success then warn("Load failed: " .. tostring(result)) end
end

LoadSettings()

-- [[ Notify ]]
function FlurioreLib:MakeNotify(config)
    config = config or {}
    config.Title = config.Title or "Notification"
    config.Content = config.Content or ""
    config.Duration = config.Duration or 5
    config.Color = config.Color or Theme.Accent

    local gui = Instance.new("ScreenGui")
    gui.Name = "NotifyGui_" .. tick()
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local layout = Instance.new("Frame")
    layout.AnchorPoint = Vector2.new(1,1)
    layout.BackgroundTransparency = 1
    layout.Position = UDim2.new(1, -20, 1, -20)
    layout.Size = UDim2.new(0, 280, 1, 0)
    layout.Name = "NotifyLayout"
    layout.Parent = gui

    local count = 0
    layout.ChildRemoved:Connect(function()
        count = 0
        for _, child in ipairs(layout:GetChildren()) do
            if child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(0, 0, 1, -((child.Size.Y.Offset + 12) * count))
                }):Play()
                count = count + 1
            end
        end
    end)

    local NotifyFrame = Instance.new("Frame")
    NotifyFrame.BackgroundColor3 = Theme.Container
    NotifyFrame.BorderSizePixel = 0
    NotifyFrame.Size = UDim2.new(1, 0, 0, 0)
    NotifyFrame.Name = "NotifyFrame"
    NotifyFrame.Parent = layout
    NotifyFrame.AnchorPoint = Vector2.new(0,1)
    NotifyFrame.Position = UDim2.new(0,0,1,-(#layout:GetChildren() * 65))

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0,6)
    UICorner.Parent = NotifyFrame

    local Top = Instance.new("Frame")
    Top.BackgroundTransparency = 1
    Top.Size = UDim2.new(1,0,0,28)
    Top.Parent = NotifyFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = config.Title
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1,-30,1,0)
    TitleLabel.Position = UDim2.new(0,10,0,0)
    TitleLabel.Parent = Top

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Font = Enum.Font.SourceSans
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Theme.Text
    CloseBtn.TextSize = 14
    CloseBtn.AnchorPoint = Vector2.new(1,0.5)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1,-5,0.5,0)
    CloseBtn.Size = UDim2.new(0,25,0,25)
    CloseBtn.Parent = Top

    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.Font = Enum.Font.Gotham
    ContentLabel.Text = config.Content
    ContentLabel.TextColor3 = Theme.SubText
    ContentLabel.TextSize = 12
    ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.TextWrapped = true
    ContentLabel.Position = UDim2.new(0,10,0,30)
    ContentLabel.Size = UDim2.new(1,-20,0,0)
    ContentLabel.Parent = NotifyFrame

    -- Auto-size
    ContentLabel.Size = UDim2.new(1,-20,0,ContentLabel.TextBounds.Y + 5)
    NotifyFrame.Size = UDim2.new(1,0,0,ContentLabel.Size.Y.Offset + 35)

    local function close()
        TweenService:Create(NotifyFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(1,40, NotifyFrame.Position.Y.Scale, NotifyFrame.Position.Y.Offset)
        }):Play()
        task.wait(0.3)
        NotifyFrame:Destroy()
    end

    CloseBtn.MouseButton1Down:Connect(close)
    task.delay(config.Duration, close)

    -- Entrance animation
    NotifyFrame.Position = UDim2.new(1,40,1,0)
    TweenService:Create(NotifyFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0,0,1,-(#layout:GetChildren() * 65))
    }):Play()

    return { Close = close }
end

-- [[ CreateWindow ]]
function FlurioreLib:CreateWindow(config)
    config = config or {}
    config.Name = config.Name or "Fluriore Hub"
    config.Description = config.Description or ""
    config.TabWidth = config.TabWidth or 120
    config.Theme = config.Theme or FlurioreLib.CurrentTheme -- allow per-window theme

    local theme = FlurioreLib.Themes[config.Theme] or FlurioreLib.Themes.Black

    local windowGui = Instance.new("ScreenGui")
    windowGui.Name = "Window_" .. config.Name
    windowGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    windowGui.Parent = CoreGui
    windowGui.Enabled = true

    -- DropShadow holder
    local DropShadowHolder = Instance.new("Frame")
    DropShadowHolder.BackgroundTransparency = 1
    DropShadowHolder.Size = UDim2.new(0, 550, 0, 350)
    DropShadowHolder.Position = UDim2.new(0.5, -275, 0.5, -175)
    DropShadowHolder.Name = "MainFrame"
    DropShadowHolder.Parent = windowGui

    local DropShadow = Instance.new("ImageLabel")
    DropShadow.Image = "rbxassetid://6015897843"
    DropShadow.ImageColor3 = Color3.new(0,0,0)
    DropShadow.ImageTransparency = 0.5
    DropShadow.ScaleType = Enum.ScaleType.Slice
    DropShadow.SliceCenter = Rect.new(49,49,450,450)
    DropShadow.AnchorPoint = Vector2.new(0.5,0.5)
    DropShadow.BackgroundTransparency = 1
    DropShadow.Position = UDim2.new(0.5,0,0.5,0)
    DropShadow.Size = UDim2.new(1,47,1,47)
    DropShadow.ZIndex = 0
    DropShadow.Parent = DropShadowHolder

    local Main = Instance.new("Frame")
    Main.BackgroundColor3 = theme.Background
    Main.BackgroundTransparency = theme.ContainerTransparency
    Main.BorderSizePixel = 0
    Main.Size = UDim2.new(1,-47,1,-47)
    Main.Position = UDim2.new(0,0,0,0)
    Main.Parent = DropShadow
    Main.AnchorPoint = Vector2.new(0,0)
    Main.ZIndex = 1

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0,6)
    UICorner.Parent = Main

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = theme.Border
    UIStroke.Thickness = 1.6
    UIStroke.Parent = Main

    -- Top bar
    local Top = Instance.new("Frame")
    Top.BackgroundTransparency = 1
    Top.Size = UDim2.new(1,0,0,38)
    Top.Name = "TopBar"
    Top.Parent = Main

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = config.Name
    TitleLabel.TextColor3 = theme.Text
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1,-100,1,0)
    TitleLabel.Position = UDim2.new(0,10,0,0)
    TitleLabel.Parent = Top

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Font = Enum.Font.GothamBold
    DescLabel.Text = config.Description
    DescLabel.TextColor3 = theme.TitleAccent
    DescLabel.TextSize = 14
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.BackgroundTransparency = 1
    DescLabel.Size = UDim2.new(1,-TitleLabel.TextBounds.X - 20,1,0)
    DescLabel.Position = UDim2.new(0, TitleLabel.TextBounds.X + 15,0,0)
    DescLabel.Parent = Top

    -- Window controls
    local Close = Instance.new("TextButton")
    Close.Font = Enum.Font.SourceSans
    Close.Text = ""
    Close.AnchorPoint = Vector2.new(1,0.5)
    Close.BackgroundTransparency = 1
    Close.Position = UDim2.new(1,-8,0.5,0)
    Close.Size = UDim2.new(0,25,0,25)
    Close.Name = "Close"
    Close.Parent = Top
    local CloseImg = Instance.new("ImageLabel")
    CloseImg.Image = "rbxassetid://9886659671"
    CloseImg.AnchorPoint = Vector2.new(0.5,0.5)
    CloseImg.BackgroundTransparency = 1
    CloseImg.Size = UDim2.new(1,-8,1,-8)
    CloseImg.Position = UDim2.new(0.5,0,0.5,0)
    CloseImg.Parent = Close

    local MaxRestore = Instance.new("TextButton")
    MaxRestore.Font = Enum.Font.SourceSans
    MaxRestore.Text = ""
    MaxRestore.AnchorPoint = Vector2.new(1,0.5)
    MaxRestore.BackgroundTransparency = 1
    MaxRestore.Position = UDim2.new(1,-42,0.5,0)
    MaxRestore.Size = UDim2.new(0,25,0,25)
    MaxRestore.Name = "MaxRestore"
    MaxRestore.Parent = Top
    local MaxImg = Instance.new("ImageLabel")
    MaxImg.Image = "rbxassetid://9886659406"
    MaxImg.AnchorPoint = Vector2.new(0.5,0.5)
    MaxImg.BackgroundTransparency = 1
    MaxImg.Size = UDim2.new(1,-8,1,-8)
    MaxImg.Position = UDim2.new(0.5,0,0.5,0)
    MaxImg.Parent = MaxRestore

    local Min = Instance.new("TextButton")
    Min.Font = Enum.Font.SourceSans
    Min.Text = ""
    Min.AnchorPoint = Vector2.new(1,0.5)
    Min.BackgroundTransparency = 1
    Min.Position = UDim2.new(1,-76,0.5,0)
    Min.Size = UDim2.new(0,25,0,25)
    Min.Name = "Minimize"
    Min.Parent = Top
    local MinImg = Instance.new("ImageLabel")
    MinImg.Image = "rbxassetid://9886659276"
    MinImg.AnchorPoint = Vector2.new(0.5,0.5)
    MinImg.BackgroundTransparency = 1
    MinImg.Size = UDim2.new(1,-9,1,-9)
    MinImg.Position = UDim2.new(0.5,0,0.5,0)
    MinImg.Parent = Min

    -- Tab area
    local LayersTab = Instance.new("Frame")
    LayersTab.BackgroundTransparency = 1
    LayersTab.Position = UDim2.new(0,9,0,50)
    LayersTab.Size = UDim2.new(0, config.TabWidth, 1, -59)
    LayersTab.Name = "TabSidebar"
    LayersTab.Parent = Main

    local ScrollTab = Instance.new("ScrollingFrame")
    ScrollTab.BackgroundTransparency = 1
    ScrollTab.ScrollBarThickness = 0
    ScrollTab.Size = UDim2.new(1,0,1,-50)
    ScrollTab.Position = UDim2.new(0,0,0,0)
    ScrollTab.CanvasSize = UDim2.new(0,0,0,0)
    ScrollTab.Parent = LayersTab

    local UIListLayout_Tabs = Instance.new("UIListLayout")
    UIListLayout_Tabs.Padding = UDim.new(0,3)
    UIListLayout_Tabs.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_Tabs.Parent = ScrollTab

    -- Info section (player info at bottom of sidebar)
    local Info = Instance.new("Frame")
    Info.AnchorPoint = Vector2.new(1,1)
    Info.BackgroundColor3 = theme.Container
    Info.BackgroundTransparency = 0.95
    Info.BorderSizePixel = 0
    Info.Position = UDim2.new(1,0,1,0)
    Info.Size = UDim2.new(1,0,0,40)
    Info.Parent = LayersTab
    local UICorner_Info = Instance.new("UICorner")
    UICorner_Info.CornerRadius = UDim.new(0,5)
    UICorner_Info.Parent = Info

    local LogoFrame = Instance.new("Frame")
    LogoFrame.AnchorPoint = Vector2.new(0,0.5)
    LogoFrame.BackgroundColor3 = theme.Container
    LogoFrame.BackgroundTransparency = 0.95
    LogoFrame.BorderSizePixel = 0
    LogoFrame.Position = UDim2.new(0,5,0.5,0)
    LogoFrame.Size = UDim2.new(0,30,0,30)
    LogoFrame.Parent = Info
    local UICorner_Logo = Instance.new("UICorner")
    UICorner_Logo.CornerRadius = UDim.new(0,1000)
    UICorner_Logo.Parent = LogoFrame

    local Logo = Instance.new("ImageLabel")
    Logo.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"
    Logo.AnchorPoint = Vector2.new(0.5,0.5)
    Logo.BackgroundTransparency = 1
    Logo.Size = UDim2.new(1,-5,1,-5)
    Logo.Position = UDim2.new(0.5,0,0.5,0)
    Logo.Parent = LogoFrame
    local UICorner_LogoImg = Instance.new("UICorner")
    UICorner_LogoImg.CornerRadius = UDim.new(0,1000)
    UICorner_LogoImg.Parent = Logo

    local NamePlayer = Instance.new("TextLabel")
    NamePlayer.Font = Enum.Font.GothamBold
    NamePlayer.Text = LocalPlayer.Name
    NamePlayer.TextColor3 = theme.SubText
    NamePlayer.TextSize = 12
    NamePlayer.TextXAlignment = Enum.TextXAlignment.Left
    NamePlayer.BackgroundTransparency = 1
    NamePlayer.Position = UDim2.new(0,40,0,0)
    NamePlayer.Size = UDim2.new(1,-45,1,0)
    NamePlayer.Parent = Info

    -- Content area
    local Layers = Instance.new("Frame")
    Layers.BackgroundTransparency = 1
    Layers.Position = UDim2.new(0, config.TabWidth + 18, 0, 50)
    Layers.Size = UDim2.new(1, -(config.TabWidth + 27), 1, -59)
    Layers.Parent = Main

    local TabNameLabel = Instance.new("TextLabel")
    TabNameLabel.Font = Enum.Font.GothamBold
    TabNameLabel.Text = ""
    TabNameLabel.TextColor3 = theme.Text
    TabNameLabel.TextSize = 24
    TabNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabNameLabel.BackgroundTransparency = 1
    TabNameLabel.Size = UDim2.new(1,0,0,30)
    TabNameLabel.Parent = Layers

    local LayersReal = Instance.new("Frame")
    LayersReal.AnchorPoint = Vector2.new(0,1)
    LayersReal.BackgroundTransparency = 1
    LayersReal.ClipsDescendants = true
    LayersReal.Position = UDim2.new(0,0,1,0)
    LayersReal.Size = UDim2.new(1,0,1,-33)
    LayersReal.Parent = Layers

    local LayersFolder = Instance.new("Folder")
    LayersFolder.Name = "LayersFolder"
    LayersFolder.Parent = LayersReal

    local LayersPageLayout = Instance.new("UIPageLayout")
    LayersPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LayersPageLayout.TweenTime = 0.3
    LayersPageLayout.EasingDirection = Enum.EasingDirection.InOut
    LayersPageLayout.EasingStyle = Enum.EasingStyle.Quad
    LayersPageLayout.Parent = LayersFolder

    -- Make window draggable and resizable
    MakeDraggable(Top, DropShadowHolder)
    AddResizeHandle(DropShadowHolder, 500, 300)

    -- Window state management
    local isMaximized = false
    local oldPos, oldSize
    local function maximize()
        if not isMaximized then
            oldPos = DropShadowHolder.Position
            oldSize = DropShadowHolder.Size
            TweenService:Create(DropShadowHolder, TweenInfo.new(0.3), {
                Position = UDim2.new(0,0,0,0),
                Size = UDim2.new(1,0,1,0)
            }):Play()
            MaxImg.Image = "rbxassetid://9886659001"
            isMaximized = true
        else
            TweenService:Create(DropShadowHolder, TweenInfo.new(0.3), {
                Position = oldPos,
                Size = oldSize
            }):Play()
            MaxImg.Image = "rbxassetid://9886659406"
            isMaximized = false
        end
    end
    MaxRestore.MouseButton1Down:Connect(function()
        CircleClick(MaxRestore, Mouse.X, Mouse.Y)
        maximize()
    end)

    Min.MouseButton1Down:Connect(function()
        CircleClick(Min, Mouse.X, Mouse.Y)
        windowGui.Enabled = false
    end)

    Close.MouseButton1Down:Connect(function()
        CircleClick(Close, Mouse.X, Mouse.Y)
        windowGui:Destroy()
    end)

    -- Toggle UI with RightShift
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            windowGui.Enabled = not windowGui.Enabled
        end
    end)

    -- Tab system
    local window = {
        Tabs = {},
        Flags = {}, -- local flags (will still register globally)
        WindowGui = windowGui,
        Destroy = function() windowGui:Destroy() end,
        ToggleUI = function() windowGui.Enabled = not windowGui.Enabled end
    }

    local firstTab = true
    local chooseFrame -- the highlight bar for tabs

    function window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        tabConfig.Name = tabConfig.Name or "Tab"
        tabConfig.Icon = tabConfig.Icon or ""

        local tabIndex = #window.Tabs

        -- Create ScrollingFrame for this tab's sections
        local ScrolLayers = Instance.new("ScrollingFrame")
        ScrolLayers.BackgroundTransparency = 1
        ScrolLayers.ScrollBarThickness = 0
        ScrolLayers.Size = UDim2.new(1,0,1,0)
        ScrolLayers.LayoutOrder = tabIndex
        ScrolLayers.Parent = LayersFolder

        local UIListLayout_Sections = Instance.new("UIListLayout")
        UIListLayout_Sections.Padding = UDim.new(0,3)
        UIListLayout_Sections.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_Sections.Parent = ScrolLayers

        -- Tab button
        local TabButton = Instance.new("Frame")
        TabButton.BackgroundColor3 = theme.Container
        TabButton.BackgroundTransparency = tabIndex == 0 and 0.92 or 0.999
        TabButton.BorderSizePixel = 0
        TabButton.LayoutOrder = tabIndex
        TabButton.Size = UDim2.new(1,0,0,30)
        TabButton.Name = "Tab_" .. tabConfig.Name
        TabButton.Parent = ScrollTab

        local UICorner_Tab = Instance.new("UICorner")
        UICorner_Tab.CornerRadius = UDim.new(0,4)
        UICorner_Tab.Parent = TabButton

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Image = tabConfig.Icon
        TabIcon.BackgroundTransparency = 1
        TabIcon.Size = UDim2.new(0,16,0,16)
        TabIcon.Position = UDim2.new(0,9,0,7)
        TabIcon.Parent = TabButton

        local TabName = Instance.new("TextLabel")
        TabName.Font = Enum.Font.GothamBold
        TabName.Text = tabConfig.Name
        TabName.TextColor3 = theme.Text
        TabName.TextSize = 13
        TabName.TextXAlignment = Enum.TextXAlignment.Left
        TabName.BackgroundTransparency = 1
        TabName.Position = UDim2.new(0,30,0,0)
        TabName.Size = UDim2.new(1,-35,1,0)
        TabName.Parent = TabButton

        local TapButton = Instance.new("TextButton")
        TapButton.Font = Enum.Font.SourceSans
        TapButton.Text = ""
        TapButton.BackgroundTransparency = 1
        TapButton.Size = UDim2.new(1,0,1,0)
        TapButton.Parent = TabButton

        if tabIndex == 0 then
            LayersPageLayout:JumpToIndex(0)
            TabNameLabel.Text = tabConfig.Name
            chooseFrame = Instance.new("Frame")
            chooseFrame.BackgroundColor3 = theme.TitleAccent
            chooseFrame.BorderSizePixel = 0
            chooseFrame.Position = UDim2.new(0,2,0,9)
            chooseFrame.Size = UDim2.new(0,1,0,12)
            chooseFrame.Name = "ChooseFrame"
            chooseFrame.Parent = TabButton
            local UICorner_choose = Instance.new("UICorner")
            UICorner_choose.Parent = chooseFrame
        end

        TapButton.MouseButton1Down:Connect(function()
            CircleClick(TapButton, Mouse.X, Mouse.Y)
            if chooseFrame and TabButton.LayoutOrder ~= LayersPageLayout.CurrentPage.LayoutOrder then
                -- Deselect all tabs
                for _, tabFrame in ipairs(ScrollTab:GetChildren()) do
                    if tabFrame:IsA("Frame") then
                        TweenService:Create(tabFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {BackgroundTransparency = 0.999}):Play()
                    end
                end
                -- Select this tab
                TweenService:Create(TabButton, TweenInfo.new(0.4), {BackgroundTransparency = 0.92}):Play()
                -- Animate highlight
                TweenService:Create(chooseFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(0,2,0,9 + (33 * TabButton.LayoutOrder))
                }):Play()
                LayersPageLayout:JumpToIndex(TabButton.LayoutOrder)
                TabNameLabel.Text = tabConfig.Name
                task.wait(0.05)
                TweenService:Create(chooseFrame, TweenInfo.new(0.25), {Size = UDim2.new(0,1,0,20)}):Play()
                task.wait(0.15)
                TweenService:Create(chooseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0,1,0,12)}):Play()
            end
        end)

        -- Canvas auto-size
        local function updateCanvas()
            local y = 0
            for _, child in ipairs(ScrolLayers:GetChildren()) do
                if child:IsA("Frame") then
                    y = y + 3 + child.Size.Y.Offset
                end
            end
            ScrolLayers.CanvasSize = UDim2.new(0,0,0,y)
        end
        ScrolLayers.ChildAdded:Connect(updateCanvas)
        ScrolLayers.ChildRemoved:Connect(updateCanvas)

        -- Sections
        local sections = {}
        function sections:AddSection(title)
            title = title or "Section"

            local Section = Instance.new("Frame")
            Section.BackgroundTransparency = 1
            Section.Size = UDim2.new(1,0,0,30)
            Section.LayoutOrder = 1
            Section.ClipsDescendants = true
            Section.Name = "Section"
            Section.Parent = ScrolLayers

            local SectionReal = Instance.new("Frame")
            SectionReal.BackgroundColor3 = theme.Container
            SectionReal.BackgroundTransparency = 0.935
            SectionReal.BorderSizePixel = 0
            SectionReal.LayoutOrder = 1
            SectionReal.Size = UDim2.new(1,0,0,30)
            SectionReal.Parent = Section

            local UICorner_Sec = Instance.new("UICorner")
            UICorner_Sec.CornerRadius = UDim.new(0,4)
            UICorner_Sec.Parent = SectionReal

            local SectionButton = Instance.new("TextButton")
            SectionButton.BackgroundTransparency = 1
            SectionButton.Size = UDim2.new(1,0,1,0)
            SectionButton.Parent = SectionReal

            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Font = Enum.Font.GothamBold
            SectionTitle.Text = title
            SectionTitle.TextColor3 = theme.Text
            SectionTitle.TextSize = 13
            SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Position = UDim2.new(0,10,0,0)
            SectionTitle.Size = UDim2.new(1,-50,0,30)
            SectionTitle.Parent = SectionReal

            local FeatureFrame = Instance.new("Frame")
            FeatureFrame.AnchorPoint = Vector2.new(1,0.5)
            FeatureFrame.BackgroundTransparency = 1
            FeatureFrame.Position = UDim2.new(1,-5,0.5,0)
            FeatureFrame.Size = UDim2.new(0,20,0,20)
            FeatureFrame.Parent = SectionReal

            local FeatureImg = Instance.new("ImageLabel")
            FeatureImg.Image = "rbxassetid://16851841101"
            FeatureImg.AnchorPoint = Vector2.new(0.5,0.5)
            FeatureImg.BackgroundTransparency = 1
            FeatureImg.Rotation = -90
            FeatureImg.Size = UDim2.new(1,6,1,6)
            FeatureImg.Position = UDim2.new(0.5,0,0.5,0)
            FeatureImg.Parent = FeatureFrame

            local SectionDecideFrame = Instance.new("Frame")
            SectionDecideFrame.BackgroundColor3 = theme.Accent
            SectionDecideFrame.BorderSizePixel = 0
            SectionDecideFrame.AnchorPoint = Vector2.new(0.5,0)
            SectionDecideFrame.Position = UDim2.new(0.5,0,0,33)
            SectionDecideFrame.Size = UDim2.new(1,0,0,2)
            SectionDecideFrame.Parent = Section

            local UICorner_Dec = Instance.new("UICorner")
            UICorner_Dec.Parent = SectionDecideFrame

            -- Items container
            local SectionAdd = Instance.new("Frame")
            SectionAdd.BackgroundTransparency = 1
            SectionAdd.AnchorPoint = Vector2.new(0.5,0)
            SectionAdd.Position = UDim2.new(0.5,0,0,38)
            SectionAdd.Size = UDim2.new(1,0,0,0)
            SectionAdd.ClipsDescendants = true
            SectionAdd.Parent = Section

            local UIListLayout_Items = Instance.new("UIListLayout")
            UIListLayout_Items.Padding = UDim.new(0,3)
            UIListLayout_Items.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_Items.Parent = SectionAdd

            local open = true
            local function updateSize()
                if not open then return end
                local itemHeight = 0
                for _, item in ipairs(SectionAdd:GetChildren()) do
                    if item:IsA("Frame") then
                        itemHeight = itemHeight + item.Size.Y.Offset + 3
                    end
                end
                TweenService:Create(FeatureFrame, TweenInfo.new(0.5), {Rotation = 90}):Play()
                TweenService:Create(Section, TweenInfo.new(0.5), {Size = UDim2.new(1,0,0, 38 + itemHeight)}):Play()
                TweenService:Create(SectionAdd, TweenInfo.new(0.5), {Size = UDim2.new(1,0,0, itemHeight)}):Play()
                TweenService:Create(SectionDecideFrame, TweenInfo.new(0.5), {Size = UDim2.new(1,0,0,2)}):Play()
                task.wait(0.5)
                updateCanvas()
            end

            SectionButton.MouseButton1Down:Connect(function()
                CircleClick(SectionButton, Mouse.X, Mouse.Y)
                if open then
                    open = false
                    TweenService:Create(FeatureFrame, TweenInfo.new(0.5), {Rotation = 0}):Play()
                    TweenService:Create(Section, TweenInfo.new(0.5), {Size = UDim2.new(1,0,0,30)}):Play()
                    TweenService:Create(SectionDecideFrame, TweenInfo.new(0.5), {Size = UDim2.new(0,0,0,2)}):Play()
                    task.wait(0.5)
                    updateCanvas()
                else
                    open = true
                    updateSize()
                end
            end)
            SectionAdd.ChildAdded:Connect(function() if open then updateSize() end end)
            SectionAdd.ChildRemoved:Connect(function() if open then updateSize() end end)

            local items = {}
            local function addFlagSupport(elementFunc, config)
                if config.Flag then
                    FlurioreLib.Flags[config.Flag] = elementFunc
                    window.Flags[config.Flag] = elementFunc
                    local oldSet = elementFunc.Set
                    elementFunc.Set = function(value, noCallback)
                        oldSet(value)
                        if not noCallback and config.Callback then
                            config.Callback(value)
                        end
                        SaveSettings()
                    end
                end
            end

            -- AddParagraph
            function items:AddParagraph(config)
                config = config or {}
                config.Title = config.Title or "Title"
                config.Content = config.Content or "Content"

                local Paragraph = Instance.new("Frame")
                Paragraph.BackgroundColor3 = theme.Container
                Paragraph.BackgroundTransparency = 0.935
                Paragraph.BorderSizePixel = 0
                Paragraph.LayoutOrder = 1
                Paragraph.Size = UDim2.new(1,0,0,46)
                Paragraph.Parent = SectionAdd

                local UICorner_Para = Instance.new("UICorner")
                UICorner_Para.CornerRadius = UDim.new(0,4)
                UICorner_Para.Parent = Paragraph

                local ParaTitle = Instance.new("TextLabel")
                ParaTitle.Font = Enum.Font.GothamBold
                ParaTitle.Text = config.Title
                ParaTitle.TextColor3 = theme.Text
                ParaTitle.TextSize = 13
                ParaTitle.TextXAlignment = Enum.TextXAlignment.Left
                ParaTitle.BackgroundTransparency = 1
                ParaTitle.Position = UDim2.new(0,10,0,10)
                ParaTitle.Size = UDim2.new(1,-16,0,13)
                ParaTitle.Parent = Paragraph

                local ParaContent = Instance.new("TextLabel")
                ParaContent.Font = Enum.Font.Gotham
                ParaContent.Text = config.Content
                ParaContent.TextColor3 = theme.SubText
                ParaContent.TextSize = 12
                ParaContent.TextTransparency = 0.6
                ParaContent.TextXAlignment = Enum.TextXAlignment.Left
                ParaContent.BackgroundTransparency = 1
                ParaContent.Position = UDim2.new(0,10,0,23)
                ParaContent.Size = UDim2.new(1,-16,0,0)
                ParaContent.TextWrapped = true
                ParaContent.Parent = Paragraph

                -- Auto-size content
                local function resize()
                    ParaContent.TextWrapped = false
                    ParaContent.Size = UDim2.new(1,-16,0, ParaContent.TextBounds.Y)
                    Paragraph.Size = UDim2.new(1,0,0, ParaContent.TextBounds.Y + 33)
                    ParaContent.TextWrapped = true
                end
                ParaContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
                task.defer(resize)

                return {
                    Set = function(newConfig)
                        if newConfig.Title then ParaTitle.Text = newConfig.Title end
                        if newConfig.Content then
                            ParaContent.Text = newConfig.Content
                            resize()
                        end
                    end
                }
            end

            -- AddButton
            function items:AddButton(config)
                config = config or {}
                config.Title = config.Title or "Button"
                config.Content = config.Content or ""
                config.Icon = config.Icon or "rbxassetid://16932740082"
                config.Callback = config.Callback or function() end

                local Button = Instance.new("Frame")
                Button.BackgroundColor3 = theme.Container
                Button.BackgroundTransparency = 0.935
                Button.BorderSizePixel = 0
                Button.LayoutOrder = 1
                Button.Size = UDim2.new(1,0,0,46)
                Button.Parent = SectionAdd

                local UICorner_Btn = Instance.new("UICorner")
                UICorner_Btn.CornerRadius = UDim.new(0,4)
                UICorner_Btn.Parent = Button

                local BtnTitle = Instance.new("TextLabel")
                BtnTitle.Font = Enum.Font.GothamBold
                BtnTitle.Text = config.Title
                BtnTitle.TextColor3 = theme.Text
                BtnTitle.TextSize = 13
                BtnTitle.TextXAlignment = Enum.TextXAlignment.Left
                BtnTitle.BackgroundTransparency = 1
                BtnTitle.Position = UDim2.new(0,10,0,10)
                BtnTitle.Size = UDim2.new(1,-100,0,13)
                BtnTitle.Parent = Button

                local BtnContent = Instance.new("TextLabel")
                BtnContent.Font = Enum.Font.Gotham
                BtnContent.Text = config.Content
                BtnContent.TextColor3 = theme.SubText
                BtnContent.TextSize = 12
                BtnContent.TextTransparency = 0.6
                BtnContent.TextXAlignment = Enum.TextXAlignment.Left
                BtnContent.BackgroundTransparency = 1
                BtnContent.Position = UDim2.new(0,10,0,23)
                BtnContent.Size = UDim2.new(1,-100,0,0)
                BtnContent.TextWrapped = true
                BtnContent.Parent = Button

                local function resize()
                    BtnContent.TextWrapped = false
                    BtnContent.Size = UDim2.new(1,-100,0, BtnContent.TextBounds.Y)
                    Button.Size = UDim2.new(1,0,0, BtnContent.TextBounds.Y + 33)
                    BtnContent.TextWrapped = true
                end
                BtnContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
                task.defer(resize)

                local BtnButton = Instance.new("TextButton")
                BtnButton.BackgroundTransparency = 1
                BtnButton.Size = UDim2.new(1,0,1,0)
                BtnButton.Parent = Button

                local IconFrame = Instance.new("Frame")
                IconFrame.AnchorPoint = Vector2.new(1,0.5)
                IconFrame.BackgroundTransparency = 1
                IconFrame.Position = UDim2.new(1,-15,0.5,0)
                IconFrame.Size = UDim2.new(0,25,0,25)
                IconFrame.Parent = Button

                local Icon = Instance.new("ImageLabel")
                Icon.Image = config.Icon
                Icon.AnchorPoint = Vector2.new(0.5,0.5)
                Icon.BackgroundTransparency = 1
                Icon.Size = UDim2.new(1,0,1,0)
                Icon.Position = UDim2.new(0.5,0,0.5,0)
                Icon.Parent = IconFrame

                BtnButton.MouseButton1Click:Connect(function()
                    CircleClick(BtnButton, Mouse.X, Mouse.Y)
                    config.Callback()
                end)

                return {}
            end

            -- AddToggle
            function items:AddToggle(config)
                config = config or {}
                config.Title = config.Title or "Toggle"
                config.Content = config.Content or ""
                config.Default = config.Default or false
                config.Flag = config.Flag
                config.Callback = config.Callback or function() end

                local ToggleValue = config.Default
                local ToggleFunc = { Value = ToggleValue }

                local Toggle = Instance.new("Frame")
                Toggle.BackgroundColor3 = theme.Container
                Toggle.BackgroundTransparency = 0.935
                Toggle.BorderSizePixel = 0
                Toggle.LayoutOrder = 1
                Toggle.Size = UDim2.new(1,0,0,46)
                Toggle.Parent = SectionAdd

                local UICorner_Tog = Instance.new("UICorner")
                UICorner_Tog.CornerRadius = UDim.new(0,4)
                UICorner_Tog.Parent = Toggle

                local TogTitle = Instance.new("TextLabel")
                TogTitle.Font = Enum.Font.GothamBold
                TogTitle.Text = config.Title
                TogTitle.TextColor3 = theme.Text
                TogTitle.TextSize = 13
                TogTitle.TextXAlignment = Enum.TextXAlignment.Left
                TogTitle.BackgroundTransparency = 1
                TogTitle.Position = UDim2.new(0,10,0,10)
                TogTitle.Size = UDim2.new(1,-100,0,13)
                TogTitle.Parent = Toggle

                local TogContent = Instance.new("TextLabel")
                TogContent.Font = Enum.Font.Gotham
                TogContent.Text = config.Content
                TogContent.TextColor3 = theme.SubText
                TogContent.TextSize = 12
                TogContent.TextTransparency = 0.6
                TogContent.TextXAlignment = Enum.TextXAlignment.Left
                TogContent.BackgroundTransparency = 1
                TogContent.Position = UDim2.new(0,10,0,23)
                TogContent.Size = UDim2.new(1,-100,0,0)
                TogContent.TextWrapped = true
                TogContent.Parent = Toggle

                local function resize()
                    TogContent.TextWrapped = false
                    TogContent.Size = UDim2.new(1,-100,0, TogContent.TextBounds.Y)
                    Toggle.Size = UDim2.new(1,0,0, TogContent.TextBounds.Y + 33)
                    TogContent.TextWrapped = true
                end
                TogContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
                task.defer(resize)

                local ToggleButton = Instance.new("TextButton")
                ToggleButton.BackgroundTransparency = 1
                ToggleButton.Size = UDim2.new(1,0,1,0)
                ToggleButton.Parent = Toggle

                -- Switch UI
                local SwitchFrame = Instance.new("Frame")
                SwitchFrame.AnchorPoint = Vector2.new(1,0.5)
                SwitchFrame.BackgroundColor3 = theme.ToggleOff
                SwitchFrame.BackgroundTransparency = 0.92
                SwitchFrame.BorderSizePixel = 0
                SwitchFrame.Position = UDim2.new(1,-30,0.5,0)
                SwitchFrame.Size = UDim2.new(0,30,0,15)
                SwitchFrame.Parent = Toggle

                local UICorner_Switch = Instance.new("UICorner")
                UICorner_Switch.CornerRadius = UDim.new(0,8)
                UICorner_Switch.Parent = SwitchFrame

                local SwitchStroke = Instance.new("UIStroke")
                SwitchStroke.Color = theme.Border
                SwitchStroke.Thickness = 2
                SwitchStroke.Transparency = 0.9
                SwitchStroke.Parent = SwitchFrame

                local Knob = Instance.new("Frame")
                Knob.BackgroundColor3 = theme.Text
                Knob.BorderSizePixel = 0
                Knob.Size = UDim2.new(0,14,0,14)
                Knob.Position = UDim2.new(0,0,0,0)
                Knob.Parent = SwitchFrame
                local UICorner_Knob = Instance.new("UICorner")
                UICorner_Knob.CornerRadius = UDim.new(0,15)
                UICorner_Knob.Parent = Knob

                function ToggleFunc:Set(value, noCallback)
                    ToggleValue = value
                    self.Value = value
                    if value then
                        TweenService:Create(TogTitle, TweenInfo.new(0.2), {TextColor3 = theme.Accent}):Play()
                        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0,15,0,0)}):Play()
                        TweenService:Create(SwitchStroke, TweenInfo.new(0.2), {Color = theme.Accent, Transparency = 0}):Play()
                        TweenService:Create(SwitchFrame, TweenInfo.new(0.2), {BackgroundColor3 = theme.Accent, BackgroundTransparency = 0}):Play()
                    else
                        TweenService:Create(TogTitle, TweenInfo.new(0.2), {TextColor3 = theme.Text}):Play()
                        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0,0,0,0)}):Play()
                        TweenService:Create(SwitchStroke, TweenInfo.new(0.2), {Color = theme.Border, Transparency = 0.9}):Play()
                        TweenService:Create(SwitchFrame, TweenInfo.new(0.2), {BackgroundColor3 = theme.ToggleOff, BackgroundTransparency = 0.92}):Play()
                    end
                    if not noCallback then config.Callback(value) end
                    SaveSettings()
                end

                ToggleButton.MouseButton1Click:Connect(function()
                    CircleClick(ToggleButton, Mouse.X, Mouse.Y)
                    ToggleValue = not ToggleValue
                    ToggleFunc:Set(ToggleValue)
                end)

                ToggleFunc:Set(ToggleValue, true) -- initial set without callback
                addFlagSupport(ToggleFunc, config)
                return ToggleFunc
            end

            -- AddSlider
            function items:AddSlider(config)
                config = config or {}
                config.Title = config.Title or "Slider"
                config.Content = config.Content or ""
                config.Min = config.Min or 0
                config.Max = config.Max or 100
                config.Increment = config.Increment or 1
                config.Default = config.Default or 50
                config.Flag = config.Flag
                config.Callback = config.Callback or function() end

                local SliderValue = config.Default
                local SliderFunc = { Value = SliderValue }

                local Slider = Instance.new("Frame")
                Slider.BackgroundColor3 = theme.Container
                Slider.BackgroundTransparency = 0.935
                Slider.BorderSizePixel = 0
                Slider.LayoutOrder = 1
                Slider.Size = UDim2.new(1,0,0,46)
                Slider.Parent = SectionAdd

                local UICorner_Sli = Instance.new("UICorner")
                UICorner_Sli.CornerRadius = UDim.new(0,4)
                UICorner_Sli.Parent = Slider

                local SliTitle = Instance.new("TextLabel")
                SliTitle.Font = Enum.Font.GothamBold
                SliTitle.Text = config.Title
                SliTitle.TextColor3 = theme.Text
                SliTitle.TextSize = 13
                SliTitle.TextXAlignment = Enum.TextXAlignment.Left
                SliTitle.BackgroundTransparency = 1
                SliTitle.Position = UDim2.new(0,10,0,10)
                SliTitle.Size = UDim2.new(1,-180,0,13)
                SliTitle.Parent = Slider

                local SliContent = Instance.new("TextLabel")
                SliContent.Font = Enum.Font.Gotham
                SliContent.Text = config.Content
                SliContent.TextColor3 = theme.SubText
                SliContent.TextSize = 12
                SliContent.TextTransparency = 0.6
                SliContent.TextXAlignment = Enum.TextXAlignment.Left
                SliContent.BackgroundTransparency = 1
                SliContent.Position = UDim2.new(0,10,0,23)
                SliContent.Size = UDim2.new(1,-180,0,0)
                SliContent.TextWrapped = true
                SliContent.Parent = Slider

                local function resize()
                    SliContent.TextWrapped = false
                    SliContent.Size = UDim2.new(1,-180,0, SliContent.TextBounds.Y)
                    Slider.Size = UDim2.new(1,0,0, SliContent.TextBounds.Y + 33)
                    SliContent.TextWrapped = true
                end
                SliContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
                task.defer(resize)

                local InputBoxFrame = Instance.new("Frame")
                InputBoxFrame.AnchorPoint = Vector2.new(0,0.5)
                InputBoxFrame.BackgroundColor3 = theme.Accent
                InputBoxFrame.BorderSizePixel = 0
                InputBoxFrame.Position = UDim2.new(1,-155,0.5,0)
                InputBoxFrame.Size = UDim2.new(0,28,0,20)
                InputBoxFrame.Parent = Slider
                local UICorner_IB = Instance.new("UICorner")
                UICorner_IB.CornerRadius = UDim.new(0,2)
                UICorner_IB.Parent = InputBoxFrame

                local TextBox = Instance.new("TextBox")
                TextBox.Font = Enum.Font.GothamBold
                TextBox.Text = tostring(config.Default)
                TextBox.TextColor3 = theme.Text
                TextBox.TextSize = 13
                TextBox.BackgroundTransparency = 1
                TextBox.TextWrapped = true
                TextBox.Size = UDim2.new(1,0,1,0)
                TextBox.Parent = InputBoxFrame

                local SliderFrame = Instance.new("Frame")
                SliderFrame.AnchorPoint = Vector2.new(1,0.5)
                SliderFrame.BackgroundColor3 = theme.SliderBar
                SliderFrame.BackgroundTransparency = 0.8
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Position = UDim2.new(1,-20,0.5,0)
                SliderFrame.Size = UDim2.new(0,100,0,3)
                SliderFrame.Parent = Slider

                local UICorner_SF = Instance.new("UICorner")
                UICorner_SF.Parent = SliderFrame

                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0,0.5)
                Fill.BackgroundColor3 = theme.Accent
                Fill.BorderSizePixel = 0
                Fill.Position = UDim2.new(0,0,0.5,0)
                Fill.Size = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), 0, 0, 1)
                Fill.Parent = SliderFrame

                local Knob2 = Instance.new("Frame")
                Knob2.AnchorPoint = Vector2.new(1,0.5)
                Knob2.BackgroundColor3 = theme.Accent
                Knob2.BorderSizePixel = 0
                Knob2.Position = UDim2.new(1,4,0.5,0)
                Knob2.Size = UDim2.new(0,8,0,8)
                Knob2.Parent = Fill
                local UICorner_Knob2 = Instance.new("UICorner")
                UICorner_Knob2.CornerRadius = UDim.new(0,4)
                UICorner_Knob2.Parent = Knob2

                local function round(n, inc)
                    return math.floor(n/inc + 0.5) * inc
                end

                function SliderFunc:Set(value, noCallback)
                    value = math.clamp(round(value, config.Increment), config.Min, config.Max)
                    SliderValue = value
                    self.Value = value
                    TextBox.Text = tostring(value)
                    local scale = (value - config.Min) / (config.Max - config.Min)
                    TweenService:Create(Fill, TweenInfo.new(0.2), {Size = UDim2.new(scale, 0, 0, 1)}):Play()
                    if not noCallback then config.Callback(value) end
                    SaveSettings()
                end

                local dragging = false
                SliderFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local scale = math.clamp((input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
                        SliderFunc:Set(config.Min + (config.Max - config.Min) * scale)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                TextBox.FocusLost:Connect(function()
                    local num = tonumber(TextBox.Text) or config.Min
                    SliderFunc:Set(num)
                end)

                SliderFunc:Set(config.Default, true)
                addFlagSupport(SliderFunc, config)
                return SliderFunc
            end

            -- AddInput
            function items:AddInput(config)
                config = config or {}
                config.Title = config.Title or "Input"
                config.Content = config.Content or ""
                config.Placeholder = config.Placeholder or "..."
                config.Callback = config.Callback or function() end
                config.Flag = config.Flag

                local InputValue = ""
                local InputFunc = { Value = InputValue }

                local Input = Instance.new("Frame")
                Input.BackgroundColor3 = theme.Container
                Input.BackgroundTransparency = 0.935
                Input.BorderSizePixel = 0
                Input.LayoutOrder = 1
                Input.Size = UDim2.new(1,0,0,46)
                Input.Parent = SectionAdd

                local UICorner_Inp = Instance.new("UICorner")
                UICorner_Inp.CornerRadius = UDim.new(0,4)
                UICorner_Inp.Parent = Input

                local InpTitle = Instance.new("TextLabel")
                InpTitle.Font = Enum.Font.GothamBold
                InpTitle.Text = config.Title
                InpTitle.TextColor3 = theme.Text
                InpTitle.TextSize = 13
                InpTitle.TextXAlignment = Enum.TextXAlignment.Left
                InpTitle.BackgroundTransparency = 1
                InpTitle.Position = UDim2.new(0,10,0,10)
                InpTitle.Size = UDim2.new(1,-180,0,13)
                InpTitle.Parent = Input

                local InpContent = Instance.new("TextLabel")
                InpContent.Font = Enum.Font.Gotham
                InpContent.Text = config.Content
                InpContent.TextColor3 = theme.SubText
                InpContent.TextSize = 12
                InpContent.TextTransparency = 0.6
                InpContent.TextXAlignment = Enum.TextXAlignment.Left
                InpContent.BackgroundTransparency = 1
                InpContent.Position = UDim2.new(0,10,0,23)
                InpContent.Size = UDim2.new(1,-180,0,0)
                InpContent.TextWrapped = true
                InpContent.Parent = Input

                local function resize()
                    InpContent.TextWrapped = false
                    InpContent.Size = UDim2.new(1,-180,0, InpContent.TextBounds.Y)
                    Input.Size = UDim2.new(1,0,0, InpContent.TextBounds.Y + 33)
                    InpContent.TextWrapped = true
                end
                InpContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
                task.defer(resize)

                local InputFrame = Instance.new("Frame")
                InputFrame.AnchorPoint = Vector2.new(1,0.5)
                InputFrame.BackgroundColor3 = theme.InputBg
                InputFrame.BackgroundTransparency = 0.05
                InputFrame.BorderSizePixel = 0
                InputFrame.ClipsDescendants = true
                InputFrame.Position = UDim2.new(1,-7,0.5,0)
                InputFrame.Size = UDim2.new(0,148,0,30)
                InputFrame.Parent = Input

                local UICorner_IF = Instance.new("UICorner")
                UICorner_IF.CornerRadius = UDim.new(0,4)
                UICorner_IF.Parent = InputFrame

                local InputBox = Instance.new("TextBox")
                InputBox.Font = Enum.Font.Gotham
                InputBox.PlaceholderText = config.Placeholder
                InputBox.PlaceholderColor3 = Color3.fromRGB(120,120,120)
                InputBox.Text = ""
                InputBox.TextColor3 = theme.Text
                InputBox.TextSize = 12
                InputBox.TextXAlignment = Enum.TextXAlignment.Left
                InputBox.BackgroundTransparency = 1
                InputBox.Size = UDim2.new(1,-10,1,-8)
                InputBox.Position = UDim2.new(0,5,0,0)
                InputBox.Parent = InputFrame

                function InputFunc:Set(value, noCallback)
                    InputValue = value
                    self.Value = value
                    InputBox.Text = value
                    if not noCallback then config.Callback(value) end
                    SaveSettings()
                end

                InputBox.FocusLost:Connect(function()
                    InputFunc:Set(InputBox.Text)
                end)

                addFlagSupport(InputFunc, config)
                return InputFunc
            end

            -- AddDropdown
            function items:AddDropdown(config)
                config = config or {}
                config.Title = config.Title or "Dropdown"
                config.Content = config.Content or ""
                config.Multi = config.Multi or false
                config.Options = config.Options or {}
                config.Default = config.Default or {}
                config.Callback = config.Callback or function() end
                config.Flag = config.Flag

                local Selected = config.Default
                local Options = config.Options
                local DropdownFunc = { Value = Selected, Options = Options }

                local Dropdown = Instance.new("Frame")
                Dropdown.BackgroundColor3 = theme.Container
                Dropdown.BackgroundTransparency = 0.935
                Dropdown.BorderSizePixel = 0
                Dropdown.LayoutOrder = 1
                Dropdown.Size = UDim2.new(1,0,0,46)
                Dropdown.Parent = SectionAdd

                local UICorner_Drop = Instance.new("UICorner")
                UICorner_Drop.CornerRadius = UDim.new(0,4)
                UICorner_Drop.Parent = Dropdown

                local DropTitle = Instance.new("TextLabel")
                DropTitle.Font = Enum.Font.GothamBold
                DropTitle.Text = config.Title
                DropTitle.TextColor3 = theme.Text
                DropTitle.TextSize = 13
                DropTitle.TextXAlignment = Enum.TextXAlignment.Left
                DropTitle.BackgroundTransparency = 1
                DropTitle.Position = UDim2.new(0,10,0,10)
                DropTitle.Size = UDim2.new(1,-180,0,13)
                DropTitle.Parent = Dropdown

                local DropContent = Instance.new("TextLabel")
                DropContent.Font = Enum.Font.Gotham
                DropContent.Text = config.Content
                DropContent.TextColor3 = theme.SubText
                DropContent.TextSize = 12
                DropContent.TextTransparency = 0.6
                DropContent.TextXAlignment = Enum.TextXAlignment.Left
                DropContent.BackgroundTransparency = 1
                DropContent.Position = UDim2.new(0,10,0,23)
                DropContent.Size = UDim2.new(1,-180,0,0)
                DropContent.TextWrapped = true
                DropContent.Parent = Dropdown

                local function resize()
                    DropContent.TextWrapped = false
                    DropContent.Size = UDim2.new(1,-180,0, DropContent.TextBounds.Y)
                    Dropdown.Size = UDim2.new(1,0,0, DropContent.TextBounds.Y + 33)
                    DropContent.TextWrapped = true
                end
                DropContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
                task.defer(resize)

                local SelectFrame = Instance.new("Frame")
                SelectFrame.AnchorPoint = Vector2.new(1,0.5)
                SelectFrame.BackgroundColor3 = theme.InputBg
                SelectFrame.BackgroundTransparency = 0.05
                SelectFrame.BorderSizePixel = 0
                SelectFrame.Position = UDim2.new(1,-7,0.5,0)
                SelectFrame.Size = UDim2.new(0,148,0,30)
                SelectFrame.Parent = Dropdown

                local UICorner_Sel = Instance.new("UICorner")
                UICorner_Sel.CornerRadius = UDim.new(0,4)
                UICorner_Sel.Parent = SelectFrame

                local SelectBtn = Instance.new("TextButton")
                SelectBtn.BackgroundTransparency = 1
                SelectBtn.Size = UDim2.new(1,0,1,0)
                SelectBtn.Parent = SelectFrame

                local SelectedText = Instance.new("TextLabel")
                SelectedText.Font = Enum.Font.Gotham
                SelectedText.Text = "Select..."
                SelectedText.TextColor3 = theme.SubText
                SelectedText.TextSize = 12
                SelectedText.TextXAlignment = Enum.TextXAlignment.Left
                SelectedText.BackgroundTransparency = 1
                SelectedText.Position = UDim2.new(0,5,0,0)
                SelectedText.Size = UDim2.new(1,-30,1,0)
                SelectedText.Parent = SelectFrame

                local Arrow = Instance.new("ImageLabel")
                Arrow.Image = "rbxassetid://16851841101"
                Arrow.ImageColor3 = theme.DropdownArrow
                Arrow.AnchorPoint = Vector2.new(1,0.5)
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(1,0,0.5,0)
                Arrow.Size = UDim2.new(0,25,0,25)
                Arrow.Parent = SelectFrame

                -- Dropdown list (reuse single global? For simplicity, we create a overlay frame inside the window)
                local DropList = Instance.new("Frame")
                DropList.BackgroundColor3 = theme.Container
                DropList.BorderSizePixel = 0
                DropList.Size = UDim2.new(0,160,0,0)
                DropList.Visible = false
                DropList.ZIndex = 5
                DropList.Parent = windowGui

                local UICorner_DL = Instance.new("UICorner")
                UICorner_DL.CornerRadius = UDim.new(0,4)
                UICorner_DL.Parent = DropList

                local ScrollDrop = Instance.new("ScrollingFrame")
                ScrollDrop.BackgroundTransparency = 1
                ScrollDrop.ScrollBarThickness = 3
                ScrollDrop.Size = UDim2.new(1,0,1,0)
                ScrollDrop.CanvasSize = UDim2.new(0,0,0,0)
                ScrollDrop.Parent = DropList

                local UIListLayout_Drop = Instance.new("UIListLayout")
                UIListLayout_Drop.Padding = UDim.new(0,2)
                UIListLayout_Drop.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout_Drop.Parent = ScrollDrop

                local function updateDropCanvas()
                    local y = 0
                    for _, child in ipairs(ScrollDrop:GetChildren()) do
                        if child:IsA("Frame") then
                            y = y + 2 + child.Size.Y.Offset
                        end
                    end
                    ScrollDrop.CanvasSize = UDim2.new(0,0,0,y)
                end

                local function refreshOptions()
                    ScrollDrop:ClearAllChildren()
                    for _, optionName in ipairs(Options) do
                        local Option = Instance.new("Frame")
                        Option.BackgroundColor3 = theme.Container
                        Option.BackgroundTransparency = 0.99
                        Option.BorderSizePixel = 0
                        Option.Size = UDim2.new(1,0,0,26)
                        Option.Name = "Option"
                        Option.Parent = ScrollDrop

                        local UICorner_Opt = Instance.new("UICorner")
                        UICorner_Opt.CornerRadius = UDim.new(0,3)
                        UICorner_Opt.Parent = Option

                        local OptionBtn = Instance.new("TextButton")
                        OptionBtn.BackgroundTransparency = 1
                        OptionBtn.Size = UDim2.new(1,0,1,0)
                        OptionBtn.Parent = Option

                        local OptText = Instance.new("TextLabel")
                        OptText.Font = Enum.Font.Gotham
                        OptText.Text = optionName
                        OptText.TextColor3 = theme.Text
                        OptText.TextSize = 12
                        OptText.TextXAlignment = Enum.TextXAlignment.Left
                        OptText.BackgroundTransparency = 1
                        OptText.Position = UDim2.new(0,8,0,0)
                        OptText.Size = UDim2.new(1,-16,1,0)
                        OptText.Parent = Option

                        local Highlight = Instance.new("Frame")
                        Highlight.BackgroundColor3 = theme.Accent
                        Highlight.BorderSizePixel = 0
                        Highlight.Position = UDim2.new(0,2,0,0)
                        Highlight.Size = UDim2.new(0,0,0,0)
                        Highlight.Parent = Option
                        local UICorner_HL = Instance.new("UICorner")
                        UICorner_HL.Parent = Highlight

                        local isSelected = table.find(Selected, optionName) ~= nil
                        if isSelected then
                            Option.BackgroundTransparency = 0.935
                            Highlight.Size = UDim2.new(0,1,0,12)
                            Highlight.Position = UDim2.new(0,2,0,7)
                        end

                        OptionBtn.MouseButton1Click:Connect(function()
                            if config.Multi then
                                if isSelected then
                                    table.remove(Selected, table.find(Selected, optionName))
                                else
                                    table.insert(Selected, optionName)
                                end
                            else
                                Selected = {optionName}
                            end
                            DropdownFunc:Set(Selected)
                            refreshOptions()
                        end)
                    end
                    updateDropCanvas()
                end

                function DropdownFunc:Set(value, noCallback)
                    Selected = value
                    self.Value = value
                    local text = table.concat(value, ", ")
                    if text == "" then text = "Select..." end
                    SelectedText.Text = text
                    refreshOptions()
                    if not noCallback then config.Callback(value) end
                    SaveSettings()
                end

                SelectBtn.MouseButton1Click:Connect(function()
                    if DropList.Visible then
                        DropList.Visible = false
                    else
                        -- Position under select frame
                        local pos = SelectFrame.AbsolutePosition
                        DropList.Position = UDim2.new(0, pos.X, 0, pos.Y + SelectFrame.AbsoluteSize.Y + 2)
                        DropList.Size = UDim2.new(0,160,0, math.min(#Options * 28, 150))
                        DropList.Visible = true
                    end
                end)

                -- Close when clicking outside
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and DropList.Visible then
                        local abs = DropList.AbsolutePosition
                        local size = DropList.AbsoluteSize
                        local mousePos = UserInputService:GetMouseLocation()
                        if mousePos.X < abs.X or mousePos.X > abs.X + size.X or mousePos.Y < abs.Y or mousePos.Y > abs.Y + size.Y then
                            DropList.Visible = false
                        end
                    end
                end)

                refreshOptions()
                DropdownFunc:Set(Selected, true)
                addFlagSupport(DropdownFunc, config)
                return DropdownFunc
            end

            -- Return items interface
            updateCanvas()
            return items
        end

        -- Return sections interface
        table.insert(window.Tabs, { Name = tabConfig.Name, Sections = sections, TabIndex = tabIndex })
        updateCanvas()
        return sections
    end

    return window
end

return FlurioreLib
