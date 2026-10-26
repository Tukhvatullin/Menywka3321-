-- ==============================================================================
-- Clean 3D Menu Library for Skeetparser by Fliriz (GitHub Module: Menywka3321-)
-- ==============================================================================
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

if _G.Clean3DMenuCleanup then
    pcall(_G.Clean3DMenuCleanup)
end

local UI = {
    IsOpen = false,
    Unloaded = false,
    Flags = {},
    Items = {},
    UnloadCallbacks = {},
    Tabs3D = {},
    ActiveTab = "Combat"
}

local connections = {}
local instancesToDestroy = {}
local allRows = {}

-- Конфигурация сохранения позиций окна и настроек функций
local CONFIG_FILE = "Clean3DMenu_PosConfig.json"
local SETTINGS_FOLDER = "Skeetparser3D_Configs"
local configData = {
    mainPos = {x = 0.5, y = 0.5, ox = -380, oy = -280},
    mainSize = {w = 760, h = 560},
    tabsOffset = {x = -2.15, y = 0, z = -3.8},
    tabsScale = 1.0
}

pcall(function()
    if makefolder and isfolder and not isfolder(SETTINGS_FOLDER) then
        makefolder(SETTINGS_FOLDER)
    end
end)

local function saveWindowPosConfig()
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(configData))
        end
    end)
end

local function loadWindowPosConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if decoded then configData = decoded end
        end
    end)
end
loadWindowPosConfig()

if not configData.mainPos or math.abs(configData.mainPos.y or 0) > 2 or math.abs(configData.mainPos.x or 0) > 2 then
    configData.mainPos = {x = 0.5, y = 0.5, ox = -380, oy = -280}
end
if not configData.mainSize then configData.mainSize = {w = 760, h = 560} end
if not configData.tabsOffset then configData.tabsOffset = {x = -2.15, y = 0, z = -3.8} end
if not configData.tabsScale then configData.tabsScale = 1.0 end

-- 1. Блюр фона
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "MenuSnowBlur"
blurEffect.Size = 0
blurEffect.Parent = Lighting
table.insert(instancesToDestroy, blurEffect)

-- 2. ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Main2DMenuGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.Enabled = false
screenGui.Parent = PlayerGui
table.insert(instancesToDestroy, screenGui)
UI.ScreenGui = screenGui

local modalShield = Instance.new("TextButton")
modalShield.Name = "ModalShield"
modalShield.Size = UDim2.new(1, 0, 1, 0)
modalShield.BackgroundTransparency = 1
modalShield.Text = ""
modalShield.AutoButtonColor = false
modalShield.Modal = true
modalShield.ZIndex = 1
modalShield.Parent = screenGui

-- 3. Снежинки
local snowContainer = Instance.new("Frame")
snowContainer.Name = "SnowLayer"
snowContainer.Size = UDim2.new(1, 0, 1, 0)
snowContainer.BackgroundTransparency = 1
snowContainer.Active = false
snowContainer.ZIndex = 2
snowContainer.Parent = screenGui

local snowflakes = {}
for i = 1, 50 do
    local flake = Instance.new("Frame")
    local size = math.random(3, 7)
    flake.Size = UDim2.new(0, size, 0, size)
    flake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flake.BackgroundTransparency = math.random(30, 70) / 100
    flake.BorderSizePixel = 0
    flake.Active = false
    flake.ZIndex = 2
    flake.Parent = snowContainer
    Instance.new("UICorner", flake).CornerRadius = UDim.new(1, 0)

    table.insert(snowflakes, {
        ui = flake,
        x = math.random() * 1.0,
        y = math.random() * 1.0,
        speedY = (math.random(10, 25) / 100),
        swaySpeed = math.random(10, 30) / 10,
        swayAmp = math.random(5, 18) / 1000,
        phase = math.random() * 6.28
    })
end

-- 4. Фото справа снизу экрана
local IMAGE_URL = "https://i.pinimg.com/736x/85/f7/b8/85f7b8894224fd0068d1dab7ea742517.jpg"
local IMAGE_ASSET_ID = nil

local animeImage = Instance.new("ImageLabel")
animeImage.Name = "BottomRightPhoto"
local PHOTO_SIZE = 260
local vp0 = (Camera and Camera.ViewportSize) or Vector2.new(1920, 1080)
if not configData.photoPos then
    configData.photoPos = {
        x = 1 - (PHOTO_SIZE / 2 + 20) / vp0.X,
        y = 1 - (PHOTO_SIZE / 2 + 10) / vp0.Y
    }
end
animeImage.AnchorPoint = Vector2.new(0.5, 0.5)
animeImage.Size = UDim2.new(0, PHOTO_SIZE, 0, PHOTO_SIZE)
animeImage.Position = UDim2.fromScale(configData.photoPos.x, configData.photoPos.y)
animeImage.Active = true
animeImage.BackgroundTransparency = 1
animeImage.BorderSizePixel = 0
animeImage.ImageTransparency = 0
animeImage.ScaleType = Enum.ScaleType.Fit
animeImage.ZIndex = 30
animeImage.Parent = screenGui

task.spawn(function()
    if IMAGE_ASSET_ID then
        animeImage.Image = IMAGE_ASSET_ID
        return
    end
    local getAsset = getcustomasset or getsynasset
    local httpFn = (syn and syn.request) or request or http_request or (http and http.request)
    if writefile and getAsset and httpFn then
        pcall(function()
            local res = httpFn({Url = IMAGE_URL, Method = "GET"})
            if res and res.Body and #res.Body > 0 then
                local ext = IMAGE_URL:lower():match("%.(%w+)$") or "png"
                local fileName = "Clean3DMenu_Photo." .. ext
                writefile(fileName, res.Body)
                animeImage.Image = getAsset(fileName)
            end
        end)
    end
end)

local draggingPhoto = false
local photoMouseStart, photoCenterStart

animeImage.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local vp = workspace.CurrentCamera.ViewportSize
        draggingPhoto = true
        photoMouseStart = UserInputService:GetMouseLocation()
        photoCenterStart = Vector2.new(animeImage.Position.X.Scale * vp.X, animeImage.Position.Y.Scale * vp.Y)
    end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if draggingPhoto and input.UserInputType == Enum.UserInputType.MouseMovement then
        local vp = workspace.CurrentCamera.ViewportSize
        local half = animeImage.AbsoluteSize / 2
        local target = photoCenterStart + (UserInputService:GetMouseLocation() - photoMouseStart)
        local cx = math.clamp(target.X, half.X, math.max(half.X, vp.X - half.X))
        local cy = math.clamp(target.Y, half.Y, math.max(half.Y, vp.Y - half.Y))
        animeImage.Position = UDim2.fromScale(cx / vp.X, cy / vp.Y)
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if draggingPhoto and input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingPhoto = false
        configData.photoPos = {x = animeImage.Position.X.Scale, y = animeImage.Position.Y.Scale}
        saveWindowPosConfig()
    end
end))

-- 5. Основная панель меню
local mainPanel = Instance.new("CanvasGroup")
mainPanel.Name = "MainPanel"
mainPanel.GroupTransparency = 0
mainPanel.Size = UDim2.new(0, configData.mainSize.w, 0, configData.mainSize.h)
mainPanel.Position = UDim2.new(configData.mainPos.x, configData.mainPos.ox, configData.mainPos.y, configData.mainPos.oy)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
mainPanel.BackgroundTransparency = 0.22
mainPanel.BorderSizePixel = 0
mainPanel.Active = true
mainPanel.ZIndex = 5
mainPanel.Parent = screenGui
UI.MainPanel = mainPanel

Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 16)
local panelHome = mainPanel.Position

local dragBar = Instance.new("TextButton")
dragBar.Size = UDim2.new(1, -200, 0, 60)
dragBar.BackgroundTransparency = 1
dragBar.Text = ""
dragBar.AutoButtonColor = false
dragBar.ZIndex = 10
dragBar.Parent = mainPanel

local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0, 22, 0, 22)
resizeHandle.Position = UDim2.new(1, -22, 1, -22)
resizeHandle.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
resizeHandle.BackgroundTransparency = 0.5
resizeHandle.Text = ""
resizeHandle.AutoButtonColor = false
resizeHandle.ZIndex = 20
resizeHandle.Parent = mainPanel
Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 6)

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.5, 0, 0, 40)
headerTitle.Position = UDim2.new(0, 30, 0, 24)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "Combat"
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 26
headerTitle.TextColor3 = Color3.fromRGB(245, 245, 250)
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.ZIndex = 6
headerTitle.Parent = mainPanel

local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(0, 150, 0, 32)
unloadBtn.Position = UDim2.new(1, -180, 0, 26)
unloadBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
unloadBtn.BackgroundTransparency = 0.25
unloadBtn.BorderSizePixel = 0
unloadBtn.Text = "UNLOAD [END]"
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.TextSize = 12
unloadBtn.TextColor3 = Color3.fromRGB(255, 110, 120)
unloadBtn.AutoButtonColor = false
unloadBtn.ZIndex = 12
unloadBtn.Parent = mainPanel
Instance.new("UICorner", unloadBtn).CornerRadius = UDim.new(0, 8)

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -60, 0, 1)
divider.Position = UDim2.new(0, 30, 0, 76)
divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider.BackgroundTransparency = 0.9
divider.BorderSizePixel = 0
divider.ZIndex = 6
divider.Parent = mainPanel

local itemsList = Instance.new("ScrollingFrame")
itemsList.Size = UDim2.new(1, -48, 1, -100)
itemsList.Position = UDim2.new(0, 24, 0, 88)
itemsList.BackgroundTransparency = 1
itemsList.BorderSizePixel = 0
itemsList.ScrollBarThickness = 3
itemsList.ScrollBarImageColor3 = Color3.fromRGB(110, 110, 125)
itemsList.CanvasSize = UDim2.new(0, 0, 0, 0)
itemsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemsList.ZIndex = 6
itemsList.Parent = mainPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = itemsList

local dragging, resizing = false, false
local dragStart, startPos, startSize

dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainPanel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                panelHome = mainPanel.Position
                configData.mainPos = {x = mainPanel.Position.X.Scale, ox = mainPanel.Position.X.Offset, y = mainPanel.Position.Y.Scale, oy = mainPanel.Position.Y.Offset}
                saveWindowPosConfig()
            end
        end)
    end
end)

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        dragStart = input.Position
        startSize = mainPanel.AbsoluteSize
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                configData.mainSize = {w = mainPanel.AbsoluteSize.X, h = mainPanel.AbsoluteSize.Y}
                saveWindowPosConfig()
            end
        end)
    end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragging then
            local delta = input.Position - dragStart
            mainPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif resizing then
            local delta = input.Position - dragStart
            local newW = math.clamp(startSize.X + delta.X, 580, 1100)
            local newH = math.clamp(startSize.Y + delta.Y, 420, 800)
            mainPanel.Size = UDim2.new(0, newW, 0, newH)
        end
    end
end))

-- 6. Левые 3D-Вкладки (адаптировано под 8 вкладок)
local PART_SIZE = Vector3.new(1.5, 2.75, 0.05)
local CANVAS_SIZE = Vector2.new(300, 560)

local tabsPart = Instance.new("Part")
tabsPart.Name = "Menu3DTabsPart"
tabsPart.Size = PART_SIZE
tabsPart.Transparency = 1
tabsPart.CanCollide = false
tabsPart.CanQuery = false
tabsPart.CanTouch = false
tabsPart.Anchored = true
tabsPart.Parent = workspace
table.insert(instancesToDestroy, tabsPart)

local tabsSurface = Instance.new("SurfaceGui")
tabsSurface.Name = "Tabs3DSurface"
tabsSurface.ResetOnSpawn = false
tabsSurface.Adornee = tabsPart
tabsSurface.Face = Enum.NormalId.Back
tabsSurface.CanvasSize = CANVAS_SIZE
tabsSurface.AlwaysOnTop = true
tabsSurface.LightInfluence = 0
tabsSurface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
tabsSurface.Enabled = false
tabsSurface.Parent = PlayerGui
table.insert(instancesToDestroy, tabsSurface)

local tabsHolder = Instance.new("Frame")
tabsHolder.Size = UDim2.new(1, 0, 1, 0)
tabsHolder.BackgroundTransparency = 1
tabsHolder.Parent = tabsSurface

local tabsDragArea = Instance.new("TextButton")
tabsDragArea.Size = UDim2.new(1, 0, 0, 30)
tabsDragArea.BackgroundTransparency = 1
tabsDragArea.Text = ""
tabsDragArea.ZIndex = 50
tabsDragArea.Parent = tabsHolder

local isDraggingTabs = false
local tabsDragStart = nil

tabsDragArea.MouseButton1Down:Connect(function()
    isDraggingTabs = true
    tabsDragStart = UserInputService:GetMouseLocation()
end)

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and isDraggingTabs then
        isDraggingTabs = false
        saveWindowPosConfig()
    end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and isDraggingTabs then
        local currentMouse = UserInputService:GetMouseLocation()
        local delta = currentMouse - tabsDragStart
        tabsDragStart = currentMouse
        configData.tabsOffset.x = configData.tabsOffset.x + (delta.X * 0.003)
        configData.tabsOffset.y = configData.tabsOffset.y - (delta.Y * 0.003)
    elseif input.UserInputType == Enum.UserInputType.MouseWheel and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        configData.tabsScale = math.clamp(configData.tabsScale + (input.Position.Z > 0 and 0.05 or -0.05), 0.7, 1.6)
        tabsPart.Size = PART_SIZE * configData.tabsScale
        saveWindowPosConfig()
    end
end))

local tabButtons3D = {}

function UI:SwitchTab(newTabName)
    UI.ActiveTab = newTabName
    headerTitle.Text = newTabName
    for _, item in ipairs(allRows) do
        item.ui.Visible = (item.category == newTabName)
    end
end

function UI:CreateTab(name)
    local index = #tabButtons3D + 1
    local yPos = 18 + (index - 1) * 65
    local defaultPos = UDim2.new(0, 25, 0, yPos)
    local hoverPos = UDim2.new(0, 40, 0, yPos - 2)

    local btn = Instance.new("Frame")
    btn.Name = name
    btn.Size = UDim2.new(0, 240, 0, 52)
    btn.Position = defaultPos
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.38
    btn.BorderSizePixel = 0
    btn.ZIndex = 5
    btn.Parent = tabsHolder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    local neonGlow = Instance.new("Frame")
    neonGlow.Size = UDim2.new(1, 16, 1, 16)
    neonGlow.Position = UDim2.new(0, -8, 0, -8)
    neonGlow.BackgroundColor3 = Color3.fromRGB(220, 225, 235)
    neonGlow.BackgroundTransparency = 1
    neonGlow.ZIndex = 3
    neonGlow.Parent = btn
    Instance.new("UICorner", neonGlow).CornerRadius = UDim.new(0, 16)

    local neonStroke = Instance.new("UIStroke")
    neonStroke.Thickness = 3
    neonStroke.Color = Color3.fromRGB(220, 225, 235)
    neonStroke.Transparency = 1
    neonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    neonStroke.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -25, 1, 0)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.fromRGB(25, 28, 35)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 6
    lbl.Parent = btn

    local tabObj = {
        name = name,
        button = btn,
        stroke = neonStroke,
        glow = neonGlow,
        defaultPos = defaultPos,
        hoverPos = hoverPos,
        xMin = 25,
        xMax = 25 + 240,
        yMin = yPos,
        yMax = yPos + 52,
        isHovered = false
    }

    function tabObj:SetHover(state)
        if self.isHovered == state then return end
        self.isHovered = state
        if state then
            TweenService:Create(self.stroke, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {Transparency = 0}):Play()
            TweenService:Create(self.glow, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.55}):Play()
            TweenService:Create(self.button, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = self.hoverPos,
                Size = UDim2.new(0, 255, 0, 56),
                BackgroundTransparency = 0.05
            }):Play()
        else
            TweenService:Create(self.stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
            TweenService:Create(self.glow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
            TweenService:Create(self.button, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = self.defaultPos,
                Size = UDim2.new(0, 240, 0, 52),
                BackgroundTransparency = 0.38
            }):Play()
        end
    end

    table.insert(tabButtons3D, tabObj)
    if index == 1 then
        UI:SwitchTab(name)
    end
    return name
end

-- ==============================================================================
-- 7. КОМПОНЕНТЫ ИНТЕРФЕЙСА (TOGGLE, SLIDER, DROPDOWN, KEYBIND, COLOR, BUTTON)
-- ==============================================================================
local NEON = Color3.fromRGB(150, 205, 255)
local rowCounter = 0

local function makeBaseRow(tabCategory, title, desc, height)
    rowCounter = rowCounter + 1
    local row = Instance.new("Frame")
    row.LayoutOrder = rowCounter
    row.Size = UDim2.new(1, -12, 0, height or 56)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    row.BackgroundTransparency = 0.35
    row.BorderSizePixel = 0
    row.Visible = (tabCategory == UI.ActiveTab)
    row.ZIndex = 7
    row.Parent = itemsList
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

    local tLabel = Instance.new("TextLabel")
    tLabel.Size = UDim2.new(0.6, 0, 0, 22)
    tLabel.Position = UDim2.new(0, 18, 0, 7)
    tLabel.BackgroundTransparency = 1
    tLabel.Text = title
    tLabel.Font = Enum.Font.GothamSemibold
    tLabel.TextSize = 15
    tLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.ZIndex = 8
    tLabel.Parent = row

    local dLabel = Instance.new("TextLabel")
    dLabel.Size = UDim2.new(0.6, 0, 0, 16)
    dLabel.Position = UDim2.new(0, 18, 0, 30)
    dLabel.BackgroundTransparency = 1
    dLabel.Text = desc or ""
    dLabel.Font = Enum.Font.Gotham
    dLabel.TextSize = 12
    dLabel.TextColor3 = Color3.fromRGB(140, 140, 152)
    dLabel.TextXAlignment = Enum.TextXAlignment.Left
    dLabel.ZIndex = 8
    dLabel.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.Color = NEON
    rowStroke.Transparency = 1
    rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rowStroke.Parent = row

    local textStroke = Instance.new("UIStroke")
    textStroke.Thickness = 1.3
    textStroke.Color = NEON
    textStroke.Transparency = 1
    textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    textStroke.Parent = tLabel

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(rowStroke, TweenInfo.new(0.18), {Transparency = 0.72}):Play()
        TweenService:Create(textStroke, TweenInfo.new(0.18), {Transparency = 0.15}):Play()
    end)

    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.35}):Play()
        TweenService:Create(rowStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        TweenService:Create(textStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
    end)

    table.insert(allRows, {ui = row, category = tabCategory})
    return row, tLabel, dLabel
end

-- 7.1 TOGGLE
function UI:AddToggle(tabCategory, flag, title, desc, default, callback)
    local row = makeBaseRow(tabCategory, title, desc, 54)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 9
    clickBtn.Parent = row

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 48, 0, 26)
    switchBg.Position = UDim2.new(1, -66, 0.5, -13)
    switchBg.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    switchBg.BorderSizePixel = 0
    switchBg.ZIndex = 8
    switchBg.Parent = row
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(185, 185, 195)
    knob.BorderSizePixel = 0
    knob.ZIndex = 9
    knob.Parent = switchBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default == true
    UI.Flags[flag] = state

    local itemObj = { Type = "Toggle", Value = state }
    function itemObj:Set(val)
        state = val == true
        UI.Flags[flag] = state
        itemObj.Value = state
        if state then
            TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(210, 215, 225)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -23, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(20, 20, 24)
            }):Play()
        else
            TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(48, 48, 56)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(185, 185, 195)
            }):Play()
        end
        if callback then pcall(callback, state) end
    end

    clickBtn.MouseButton1Click:Connect(function()
        itemObj:Set(not state)
    end)

    if state then itemObj:Set(true) end
    UI.Items[flag] = itemObj
    return itemObj
end

-- 7.2 SLIDER
function UI:AddSlider(tabCategory, flag, title, desc, minVal, maxVal, defaultVal, rounding, callback)
    local row = makeBaseRow(tabCategory, title, desc, 64)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 120, 0, 20)
    valLabel.Position = UDim2.new(1, -138, 0, 8)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 14
    valLabel.TextColor3 = NEON
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.ZIndex = 9
    valLabel.Parent = row

    local barBg = Instance.new("TextButton")
    barBg.Size = UDim2.new(0, 220, 0, 8)
    barBg.Position = UDim2.new(1, -238, 0, 36)
    barBg.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    barBg.BorderSizePixel = 0
    barBg.Text = ""
    barBg.AutoButtonColor = false
    barBg.ZIndex = 9
    barBg.Parent = row
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0.5, 0, 1, 0)
    barFill.BackgroundColor3 = NEON
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 10
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local curVal = defaultVal or minVal
    UI.Flags[flag] = curVal
    local itemObj = { Type = "Slider", Value = curVal }

    local function roundNumber(num)
        if not rounding or rounding <= 0 then
            return math.floor(num + 0.5)
        end
        local mult = 10 ^ rounding
        return math.floor(num * mult + 0.5) / mult
    end

    function itemObj:Set(v)
        curVal = math.clamp(roundNumber(tonumber(v) or minVal), minVal, maxVal)
        UI.Flags[flag] = curVal
        itemObj.Value = curVal
        local pct = math.clamp((curVal - minVal) / math.max(maxVal - minVal, 0.0001), 0, 1)
        barFill.Size = UDim2.new(pct, 0, 1, 0)
        valLabel.Text = tostring(curVal)
        if callback then pcall(callback, curVal) end
    end

    local sliding = false
    local function updateFromMouse()
        local mPos = UserInputService:GetMouseLocation()
        local relX = mPos.X - barBg.AbsolutePosition.X
        local pct = math.clamp(relX / math.max(barBg.AbsoluteSize.X, 1), 0, 1)
        itemObj:Set(minVal + (maxVal - minVal) * pct)
    end

    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            updateFromMouse()
        end
    end)

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end))

    itemObj:Set(curVal)
    UI.Items[flag] = itemObj
    return itemObj
end

-- 7.3 DROPDOWN (SINGLE & MULTI)
function UI:AddDropdown(tabCategory, flag, title, desc, values, defaultIdxOrVal, isMulti, callback)
    local row = makeBaseRow(tabCategory, title, desc, 56)

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0, 210, 0, 32)
    dropBtn.Position = UDim2.new(1, -228, 0.5, -16)
    dropBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    dropBtn.BorderSizePixel = 0
    dropBtn.Font = Enum.Font.GothamSemibold
    dropBtn.TextSize = 12
    dropBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
    dropBtn.TextTruncate = Enum.TextTruncate.AtEnd
    dropBtn.AutoButtonColor = false
    dropBtn.ZIndex = 9
    dropBtn.Parent = row
    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 8)

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, -24, 0, 0)
    listFrame.Position = UDim2.new(0, 12, 0, 54)
    listFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    listFrame.BorderSizePixel = 0
    listFrame.ClipsDescendants = true
    listFrame.Visible = false
    listFrame.ZIndex = 15
    listFrame.Parent = row
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)

    local listLayoutInner = Instance.new("UIListLayout")
    listLayoutInner.Padding = UDim.new(0, 3)
    listLayoutInner.Parent = listFrame

    local expanded = false
    local currentValues = values or {}
    local itemObj = { Type = isMulti and "MultiDropdown" or "Dropdown", Values = currentValues }

    local selectedMulti = {}
    local selectedSingle = currentValues[1] or ""
    if type(defaultIdxOrVal) == "number" and currentValues[defaultIdxOrVal] then
        selectedSingle = currentValues[defaultIdxOrVal]
    elseif type(defaultIdxOrVal) == "string" then
        selectedSingle = defaultIdxOrVal
    end

    local function updateHeaderText()
        if isMulti then
            local names = {}
            for k, v in pairs(selectedMulti) do
                if v then table.insert(names, k) end
            end
            dropBtn.Text = (#names > 0 and table.concat(names, ", ") or "None") .. " ▾"
        else
            dropBtn.Text = tostring(selectedSingle) .. " ▾"
        end
    end

    local function rebuildOptions()
        for _, ch in ipairs(listFrame:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, optName in ipairs(currentValues) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 26)
            optBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
            optBtn.BorderSizePixel = 0
            optBtn.Font = Enum.Font.GothamMedium
            optBtn.TextSize = 12
            optBtn.AutoButtonColor = false
            optBtn.ZIndex = 16
            optBtn.Parent = listFrame
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)

            local function refreshOptVisual()
                local active = isMulti and selectedMulti[optName] or (selectedSingle == optName)
                optBtn.Text = (active and "✓ " or "") .. tostring(optName)
                optBtn.TextColor3 = active and NEON or Color3.fromRGB(200, 200, 210)
            end
            refreshOptVisual()

            optBtn.MouseButton1Click:Connect(function()
                if isMulti then
                    selectedMulti[optName] = not selectedMulti[optName]
                    UI.Flags[flag] = selectedMulti
                    itemObj.Value = selectedMulti
                    refreshOptVisual()
                    updateHeaderText()
                    if callback then pcall(callback, selectedMulti) end
                else
                    itemObj:Set(optName)
                    expanded = false
                    listFrame.Visible = false
                    row.Size = UDim2.new(1, -12, 0, 56)
                end
            end)
        end
    end

    function itemObj:Set(val)
        if isMulti and type(val) == "table" then
            selectedMulti = val
            UI.Flags[flag] = selectedMulti
            itemObj.Value = selectedMulti
            rebuildOptions()
            updateHeaderText()
            if callback then pcall(callback, selectedMulti) end
        elseif not isMulti then
            selectedSingle = tostring(val)
            UI.Flags[flag] = selectedSingle
            itemObj.Value = selectedSingle
            rebuildOptions()
            updateHeaderText()
            if callback then pcall(callback, selectedSingle) end
        end
    end

    function itemObj:SetValues(newList)
        currentValues = newList or {}
        rebuildOptions()
        if expanded then
            local h = math.min(#currentValues * 29 + 6, 180)
            listFrame.Size = UDim2.new(1, -24, 0, h)
            row.Size = UDim2.new(1, -12, 0, 62 + h)
        end
    end

    dropBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            rebuildOptions()
            local h = math.min(#currentValues * 29 + 6, 180)
            listFrame.Visible = true
            listFrame.Size = UDim2.new(1, -24, 0, h)
            row.Size = UDim2.new(1, -12, 0, 62 + h)
        else
            listFrame.Visible = false
            row.Size = UDim2.new(1, -12, 0, 56)
        end
    end)

    if isMulti then
        itemObj:Set({})
    else
        itemObj:Set(selectedSingle)
    end
    UI.Items[flag] = itemObj
    return itemObj
end

-- 7.4 KEYPICKER / KEYBIND
function UI:AddKeybind(tabCategory, flag, title, desc, defaultKeyName, callback)
    local row = makeBaseRow(tabCategory, title, desc, 54)

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 120, 0, 30)
    keyBtn.Position = UDim2.new(1, -138, 0.5, -15)
    keyBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    keyBtn.BorderSizePixel = 0
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 12
    keyBtn.TextColor3 = NEON
    keyBtn.AutoButtonColor = false
    keyBtn.ZIndex = 9
    keyBtn.Parent = row
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 8)

    local curKey = defaultKeyName or "None"
    local binding = false
    UI.Flags[flag] = curKey
    local itemObj = { Type = "Keybind", Value = curKey }

    function itemObj:Set(kName)
        curKey = tostring(kName or "None")
        UI.Flags[flag] = curKey
        itemObj.Value = curKey
        keyBtn.Text = "[" .. curKey .. "]"
        if callback then pcall(callback, curKey) end
    end

    keyBtn.MouseButton1Click:Connect(function()
        binding = true
        keyBtn.Text = "[Press Key...]"
    end)

    table.insert(connections, UserInputService.InputBegan:Connect(function(input)
        if not binding then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            binding = false
            local k = input.KeyCode.Name
            if k == "Escape" or k == "Backspace" then k = "None" end
            itemObj:Set(k)
        end
    end))

    itemObj:Set(curKey)
    UI.Items[flag] = itemObj
    return itemObj
end

-- 7.5 COLOR PICKER (PRESET + HSV CYCLER)
local COLOR_PALETTE = {
    {Name = "Red", Col = Color3.fromRGB(255, 75, 75)},
    {Name = "Green", Col = Color3.fromRGB(0, 255, 110)},
    {Name = "Neon Mint", Col = Color3.fromRGB(0, 255, 160)},
    {Name = "Cyan", Col = Color3.fromRGB(0, 230, 255)},
    {Name = "Blue", Col = Color3.fromRGB(40, 140, 255)},
    {Name = "Purple", Col = Color3.fromRGB(190, 60, 255)},
    {Name = "Pink", Col = Color3.fromRGB(255, 90, 200)},
    {Name = "Yellow", Col = Color3.fromRGB(255, 225, 60)},
    {Name = "Orange", Col = Color3.fromRGB(255, 140, 40)},
    {Name = "White", Col = Color3.fromRGB(255, 255, 255)},
}

function UI:AddColorPicker(tabCategory, flag, title, desc, defaultColor, callback)
    local row = makeBaseRow(tabCategory, title, desc, 54)

    local colBtn = Instance.new("TextButton")
    colBtn.Size = UDim2.new(0, 110, 0, 28)
    colBtn.Position = UDim2.new(1, -128, 0.5, -14)
    colBtn.BackgroundColor3 = defaultColor or Color3.fromRGB(0, 255, 150)
    colBtn.BorderSizePixel = 0
    colBtn.Text = "Change Color"
    colBtn.Font = Enum.Font.GothamBold
    colBtn.TextSize = 11
    colBtn.TextColor3 = Color3.fromRGB(15, 15, 20)
    colBtn.AutoButtonColor = false
    colBtn.ZIndex = 9
    colBtn.Parent = row
    Instance.new("UICorner", colBtn).CornerRadius = UDim.new(0, 8)

    local curColor = defaultColor or Color3.fromRGB(0, 255, 150)
    local paletteIdx = 1
    UI.Flags[flag] = curColor
    local itemObj = { Type = "Color", Value = curColor }

    function itemObj:Set(c)
        if typeof(c) == "Color3" then
            curColor = c
        elseif type(c) == "table" and c.r and c.g and c.b then
            curColor = Color3.new(c.r, c.g, c.b)
        end
        UI.Flags[flag] = curColor
        itemObj.Value = curColor
        colBtn.BackgroundColor3 = curColor
        if callback then pcall(callback, curColor) end
    end

    colBtn.MouseButton1Click:Connect(function()
        paletteIdx = paletteIdx + 1
        if paletteIdx > #COLOR_PALETTE then paletteIdx = 1 end
        itemObj:Set(COLOR_PALETTE[paletteIdx].Col)
    end)

    itemObj:Set(curColor)
    UI.Items[flag] = itemObj
    return itemObj
end

-- 7.6 BUTTON
function UI:AddButton(tabCategory, title, desc, btnText, callback)
    local row = makeBaseRow(tabCategory, title, desc, 54)

    local actBtn = Instance.new("TextButton")
    actBtn.Size = UDim2.new(0, 140, 0, 32)
    actBtn.Position = UDim2.new(1, -158, 0.5, -16)
    actBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
    actBtn.BorderSizePixel = 0
    actBtn.Text = btnText or "Execute"
    actBtn.Font = Enum.Font.GothamBold
    actBtn.TextSize = 12
    actBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
    actBtn.AutoButtonColor = false
    actBtn.ZIndex = 9
    actBtn.Parent = row
    Instance.new("UICorner", actBtn).CornerRadius = UDim.new(0, 8)

    actBtn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
    return actBtn
end

-- 7.7 TEXT INPUT
function UI:AddInput(tabCategory, flag, title, desc, placeholder, defaultText, callback)
    local row = makeBaseRow(tabCategory, title, desc, 54)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 180, 0, 30)
    box.Position = UDim2.new(1, -198, 0.5, -15)
    box.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder or "Enter value..."
    box.Text = defaultText or ""
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 12
    box.TextColor3 = Color3.fromRGB(240, 240, 250)
    box.ClearTextOnFocus = false
    box.ZIndex = 9
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

    local itemObj = { Type = "Input", Value = defaultText or "" }
    function itemObj:Set(txt)
        box.Text = tostring(txt or "")
        UI.Flags[flag] = box.Text
        itemObj.Value = box.Text
        if callback then pcall(callback, box.Text) end
    end

    box.FocusLost:Connect(function()
        itemObj:Set(box.Text)
    end)

    itemObj:Set(defaultText or "")
    UI.Items[flag] = itemObj
    return itemObj
end

-- 7.8 СИСТЕМА СОХРАНЕНИЯ И ЗАГРУЗКИ КОНФИГОВ (ВКЛЮЧАЯ БИНДЫ)
function UI:SaveConfig(cfgName)
    pcall(function()
        if not writefile then return end
        local data = {}
        for flag, item in pairs(UI.Items) do
            if item.Type == "Color" then
                local c = item.Value
                data[flag] = {__type = "Color3", r = c.R, g = c.G, b = c.B}
            else
                data[flag] = item.Value
            end
        end
        writefile(SETTINGS_FOLDER .. "/" .. (cfgName or "default") .. ".json", HttpService:JSONEncode(data))
    end)
end

function UI:LoadConfig(cfgName)
    pcall(function()
        local path = SETTINGS_FOLDER .. "/" .. (cfgName or "default") .. ".json"
        if readfile and isfile and isfile(path) then
            local decoded = HttpService:JSONDecode(readfile(path))
            if type(decoded) == "table" then
                for flag, val in pairs(decoded) do
                    local item = UI.Items[flag]
                    if item then
                        if type(val) == "table" and val.__type == "Color3" then
                            item:Set(Color3.new(val.r, val.g, val.b))
                        else
                            item:Set(val)
                        end
                    end
                end
            end
        end
    end)
end

-- Курсор
local customCursor = Instance.new("Frame")
customCursor.Size = UDim2.new(0, 8, 0, 8)
customCursor.AnchorPoint = Vector2.new(0.5, 0.5)
customCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
customCursor.Active = false
customCursor.ZIndex = 100
customCursor.Parent = screenGui
Instance.new("UICorner", customCursor).CornerRadius = UDim.new(1, 0)

local cursorRing = Instance.new("Frame")
cursorRing.Size = UDim2.new(0, 20, 0, 20)
cursorRing.AnchorPoint = Vector2.new(0.5, 0.5)
cursorRing.Position = UDim2.new(0.5, 0, 0.5, 0)
cursorRing.BackgroundTransparency = 1
cursorRing.Active = false
cursorRing.ZIndex = 99
cursorRing.Parent = customCursor
Instance.new("UICorner", cursorRing).CornerRadius = UDim.new(1, 0)

local ringStroke = Instance.new("UIStroke")
ringStroke.Thickness = 1.5
ringStroke.Color = Color3.fromRGB(210, 215, 225)
ringStroke.Parent = cursorRing

-- Расчет наведения на 3D вкладки
local currentHoveredTab = nil

local function update3DMouseHover(mousePos)
    Camera = workspace.CurrentCamera
    if not Camera then return end

    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local currentPartSize = PART_SIZE * configData.tabsScale
    local planeOrigin = (tabsPart.CFrame * CFrame.new(0, 0, currentPartSize.Z / 2)).Position
    local planeNormal = tabsPart.CFrame.LookVector

    local denom = planeNormal:Dot(ray.Direction)
    if math.abs(denom) > 1e-5 then
        local t = (planeOrigin - ray.Origin):Dot(planeNormal) / denom
        if t > 0 then
            local hitWorld = ray.Origin + ray.Direction * t
            local localHit = tabsPart.CFrame:PointToObjectSpace(hitWorld)

            local u = (localHit.X / currentPartSize.X) + 0.5
            local v = 0.5 - (localHit.Y / currentPartSize.Y)

            local canvasX = u * CANVAS_SIZE.X
            local canvasY = v * CANVAS_SIZE.Y

            local foundTab = nil
            for _, tab in ipairs(tabButtons3D) do
                if canvasX >= tab.xMin and canvasX <= tab.xMax and canvasY >= tab.yMin and canvasY <= tab.yMax then
                    foundTab = tab
                    break
                end
            end

            for _, tab in ipairs(tabButtons3D) do
                tab:SetHover(tab == foundTab)
            end
            currentHoveredTab = foundTab
            return
        end
    end

    for _, tab in ipairs(tabButtons3D) do
        tab:SetHover(false)
    end
    currentHoveredTab = nil
end

local function setInputFreeze(freeze)
    if freeze then
        ContextActionService:BindAction("FreezeMenuControl", function()
            return Enum.ContextActionResult.Sink
        end, false,
        Enum.UserInputType.MouseButton2,
        Enum.UserInputType.MouseWheel,
        Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space)
    else
        ContextActionService:UnbindAction("FreezeMenuControl")
    end
end

local closing = false
local isLoading = true
local animToken = 0
local startTime = tick()

local renderConn = RunService.RenderStepped:Connect(function(dt)
    if not (UI.IsOpen or closing) then return end

    Camera = workspace.CurrentCamera
    if Camera then
        tabsPart.Size = PART_SIZE * configData.tabsScale
        local offset = CFrame.new(configData.tabsOffset.x, configData.tabsOffset.y, configData.tabsOffset.z) * CFrame.Angles(0, math.rad(35), 0)
        tabsPart.CFrame = Camera.CFrame * offset
    end

    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    local mPos = UserInputService:GetMouseLocation()
    customCursor.Position = UDim2.new(0, mPos.X, 0, mPos.Y)

    update3DMouseHover(mPos)

    local elapsed = tick() - startTime
    for _, f in ipairs(snowflakes) do
        f.y = f.y + f.speedY * dt
        if f.y > 1.05 then
            f.y = -0.05
            f.x = math.random()
        end
        local currentX = f.x + math.sin(elapsed * f.swaySpeed + f.phase) * f.swayAmp
        f.ui.Position = UDim2.new(currentX, 0, f.y, 0)
    end
end)
table.insert(connections, renderConn)

local SLIDE = UDim2.new(0, 0, 0, 26)

function UI:ToggleMenu(state)
    if isLoading or UI.Unloaded then return end
    UI.IsOpen = state
    animToken = animToken + 1
    local token = animToken

    if UI.IsOpen then
        closing = false
        screenGui.Enabled = true
        tabsSurface.Enabled = true
        setInputFreeze(true)
        TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 22}):Play()

        for i, data in ipairs(tabButtons3D) do
            data.button.Position = UDim2.new(0, -250, 0, data.defaultPos.Y.Offset)
            TweenService:Create(data.button, TweenInfo.new(0.3 + (i * 0.04), Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = data.defaultPos
            }):Play()
        end

        mainPanel.GroupTransparency = 1
        mainPanel.Position = panelHome + SLIDE
        TweenService:Create(mainPanel, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            GroupTransparency = 0,
            Position = panelHome
        }):Play()

        animeImage.ImageTransparency = 1
        TweenService:Create(animeImage, TweenInfo.new(0.4), {ImageTransparency = 0}):Play()
        snowContainer.Visible = true
    else
        closing = true
        setInputFreeze(false)
        TweenService:Create(blurEffect, TweenInfo.new(0.32), {Size = 0}):Play()

        for i, data in ipairs(tabButtons3D) do
            data:SetHover(false)
            TweenService:Create(data.button, TweenInfo.new(0.22 + (i * 0.03), Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0, -270, 0, data.defaultPos.Y.Offset)
            }):Play()
        end

        TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            GroupTransparency = 1,
            Position = panelHome + SLIDE
        }):Play()

        TweenService:Create(animeImage, TweenInfo.new(0.28), {ImageTransparency = 1}):Play()
        for _, f in ipairs(snowflakes) do
            TweenService:Create(f.ui, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
        end

        task.delay(0.42, function()
            if animToken == token and not UI.IsOpen and not UI.Unloaded then
                closing = false
                screenGui.Enabled = false
                tabsSurface.Enabled = false
                mainPanel.Position = panelHome
                for _, f in ipairs(snowflakes) do
                    f.ui.BackgroundTransparency = math.random(30, 70) / 100
                end
            end
        end)
    end
end

function UI:OnUnload(fn)
    table.insert(UI.UnloadCallbacks, fn)
end

function UI:Unload()
    if UI.Unloaded then return end
    UI.Unloaded = true
    UI.IsOpen = false
    setInputFreeze(false)
    for _, cb in ipairs(UI.UnloadCallbacks) do
        pcall(cb)
    end
    for _, conn in ipairs(connections) do
        if conn.Connected then conn:Disconnect() end
    end
    for _, inst in ipairs(instancesToDestroy) do
        if inst and inst.Parent then inst:Destroy() end
    end
    _G.Clean3DMenuCleanup = nil
end

_G.Clean3DMenuCleanup = function() UI:Unload() end
unloadBtn.MouseButton1Click:Connect(function() UI:Unload() end)

local function restoreAfterRespawn()
    if UI.Unloaded then return end
    Camera = workspace.CurrentCamera
    if screenGui.Parent ~= PlayerGui then screenGui.Parent = PlayerGui end
    if tabsSurface.Parent ~= PlayerGui then tabsSurface.Parent = PlayerGui end
    if tabsPart.Parent ~= workspace then tabsPart.Parent = workspace end
    tabsSurface.Adornee = tabsPart
    UI:SwitchTab(UI.ActiveTab)

    if UI.IsOpen then
        screenGui.Enabled = true
        tabsSurface.Enabled = true
        mainPanel.GroupTransparency = 0
        mainPanel.Position = panelHome
        animeImage.ImageTransparency = 0
        for _, data in ipairs(tabButtons3D) do
            data.button.Position = data.defaultPos
        end
        setInputFreeze(false)
        setInputFreeze(true)
    end
end

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    restoreAfterRespawn()
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input)
    local menuKey = UI.Flags.MenuKeybind or "RightShift"
    if input.KeyCode.Name == menuKey then
        UI:ToggleMenu(not UI.IsOpen)
    elseif input.KeyCode == Enum.KeyCode.End then
        UI:Unload()
    elseif UI.IsOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if currentHoveredTab and not isDraggingTabs then
            UI:SwitchTab(currentHoveredTab.name)
        end
    end
end))

-- 8. Экран загрузки при запуске
task.spawn(function()
    pcall(function()
        local loaderBlur = Instance.new("BlurEffect")
        loaderBlur.Name = "MenuLoaderBlur"
        loaderBlur.Size = 0
        loaderBlur.Parent = Lighting
        table.insert(instancesToDestroy, loaderBlur)

        local loaderGui = Instance.new("ScreenGui")
        loaderGui.Name = "MenuLoaderGui"
        loaderGui.ResetOnSpawn = false
        loaderGui.IgnoreGuiInset = true
        loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        loaderGui.DisplayOrder = 1000000
        loaderGui.Parent = PlayerGui
        table.insert(instancesToDestroy, loaderGui)

        local dim = Instance.new("Frame")
        dim.Size = UDim2.new(1, 0, 1, 0)
        dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        dim.BackgroundTransparency = 1
        dim.BorderSizePixel = 0
        dim.ZIndex = 1
        dim.Parent = loaderGui

        local card = Instance.new("CanvasGroup")
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.new(0.5, 0, 0.5, 0)
        card.Size = UDim2.new(0, 370, 0, 120)
        card.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
        card.
