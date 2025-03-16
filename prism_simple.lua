--[[
    Prism Analytics Simple Version
    
    This is a standalone version of Prism Analytics with ESP features.
    All code is contained in a single file for maximum compatibility.
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ViewportSize = Camera.ViewportSize

-- Settings
local Settings = {
    Enabled = true,
    BoxESP = true,
    NameESP = true,
    HealthESP = true,
    TeamCheck = true,
    TeamColor = true,
    MaxDistance = 1000,
    RefreshRate = 10, -- Hz
    ToggleKey = Enum.KeyCode.RightShift,
    BoxColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    ShowUI = true,
    HighlightESP = false
}

-- Create main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PrismAnalytics"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Try to parent to CoreGui with fallbacks
local success = pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not success then
    pcall(function()
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
end

-- Create ESP container
local ESPContainer = Instance.new("Folder")
ESPContainer.Name = "ESPContainer"
ESPContainer.Parent = ScreenGui

-- Create UI container
local UIContainer = Instance.new("Frame")
UIContainer.Name = "UIContainer"
UIContainer.Size = UDim2.new(0, 250, 0, 300)
UIContainer.Position = UDim2.new(0, 10, 0.5, -150)
UIContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
UIContainer.BorderSizePixel = 0
UIContainer.Visible = Settings.ShowUI
UIContainer.Parent = ScreenGui

-- Add UI corner
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 5)
UICorner.Parent = UIContainer

-- Add title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.BorderSizePixel = 0
Title.Text = "Prism Analytics"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = UIContainer

-- Add title corner
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 5)
TitleCorner.Parent = Title

-- Add settings container
local SettingsContainer = Instance.new("ScrollingFrame")
SettingsContainer.Name = "SettingsContainer"
SettingsContainer.Size = UDim2.new(1, -20, 1, -40)
SettingsContainer.Position = UDim2.new(0, 10, 0, 35)
SettingsContainer.BackgroundTransparency = 1
SettingsContainer.BorderSizePixel = 0
SettingsContainer.ScrollBarThickness = 4
SettingsContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
SettingsContainer.CanvasSize = UDim2.new(0, 0, 0, 200)
SettingsContainer.Parent = UIContainer

-- Function to create toggle
local function CreateToggle(name, default, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name .. "Toggle"
    ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
    ToggleFrame.Position = UDim2.new(0, 0, 0, #SettingsContainer:GetChildren() * 35)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Parent = SettingsContainer
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Name = "Label"
    ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = name
    ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleLabel.Font = Enum.Font.SourceSans
    ToggleLabel.TextSize = 16
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleFrame
    
    local ToggleButton = Instance.new("Frame")
    ToggleButton.Name = "Button"
    ToggleButton.Size = UDim2.new(0, 40, 0, 20)
    ToggleButton.Position = UDim2.new(0.85, 0, 0.5, -10)
    ToggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = ToggleFrame
    
    local ToggleButtonCorner = Instance.new("UICorner")
    ToggleButtonCorner.CornerRadius = UDim.new(0, 10)
    ToggleButtonCorner.Parent = ToggleButton
    
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "Circle"
    ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    ToggleCircle.Position = UDim2.new(default and 0.6 or 0, 2, 0, 2)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleCircle.BorderSizePixel = 0
    ToggleCircle.Parent = ToggleButton
    
    local ToggleCircleCorner = Instance.new("UICorner")
    ToggleCircleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCircleCorner.Parent = ToggleCircle
    
    local isEnabled = default
    
    local function UpdateToggle()
        isEnabled = not isEnabled
        ToggleCircle:TweenPosition(
            UDim2.new(isEnabled and 0.6 or 0, 2, 0, 2),
            Enum.EasingDirection.InOut,
            Enum.EasingStyle.Quad,
            0.15,
            true
        )
        ToggleButton.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
        callback(isEnabled)
    end
    
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UpdateToggle()
        end
    end)
    
    return {
        Frame = ToggleFrame,
        SetState = function(state)
            if state ~= isEnabled then
                UpdateToggle()
            end
        end
    }
end

-- Create toggles
local Toggles = {
    CreateToggle("ESP Enabled", Settings.Enabled, function(state)
        Settings.Enabled = state
    end),
    CreateToggle("Box ESP", Settings.BoxESP, function(state)
        Settings.BoxESP = state
    end),
    CreateToggle("Name ESP", Settings.NameESP, function(state)
        Settings.NameESP = state
    end),
    CreateToggle("Health ESP", Settings.HealthESP, function(state)
        Settings.HealthESP = state
    end),
    CreateToggle("Team Check", Settings.TeamCheck, function(state)
        Settings.TeamCheck = state
    end),
    CreateToggle("Team Color", Settings.TeamColor, function(state)
        Settings.TeamColor = state
    end),
    CreateToggle("Highlight ESP", Settings.HighlightESP, function(state)
        Settings.HighlightESP = state
    end)
}

-- Update canvas size
SettingsContainer.CanvasSize = UDim2.new(0, 0, 0, #SettingsContainer:GetChildren() * 35 + 10)

-- ESP functions
local function GetPlayerColor(player)
    if Settings.TeamColor and player.Team then
        return player.TeamColor.Color
    end
    return Settings.BoxColor
end

local function IsPlayerValid(player)
    if player == LocalPlayer then return false end
    if Settings.TeamCheck and player.Team and player.Team == LocalPlayer.Team then return false end
    return true
end

local function CreateESPItems(player)
    local ESPFolder = Instance.new("Folder")
    ESPFolder.Name = player.Name
    ESPFolder.Parent = ESPContainer
    
    -- Box ESP
    local BoxOutline = Instance.new("Frame")
    BoxOutline.Name = "BoxOutline"
    BoxOutline.BackgroundTransparency = 1
    BoxOutline.BorderSizePixel = 3
    BoxOutline.BorderColor3 = Color3.new(0, 0, 0)
    BoxOutline.Size = UDim2.new(0, 0, 0, 0)
    BoxOutline.Parent = ESPFolder
    
    local Box = Instance.new("Frame")
    Box.Name = "Box"
    Box.BackgroundTransparency = 1
    Box.BorderSizePixel = 1
    Box.Size = UDim2.new(0, 0, 0, 0)
    Box.Parent = ESPFolder
    
    -- Name ESP
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "NameLabel"
    NameLabel.BackgroundTransparency = 1
    NameLabel.Size = UDim2.new(0, 200, 0, 20)
    NameLabel.Font = Enum.Font.SourceSansBold
    NameLabel.TextSize = 14
    NameLabel.TextStrokeTransparency = 0.4
    NameLabel.Parent = ESPFolder
    
    -- Health ESP
    local HealthBarOutline = Instance.new("Frame")
    HealthBarOutline.Name = "HealthBarOutline"
    HealthBarOutline.BorderSizePixel = 0
    HealthBarOutline.BackgroundColor3 = Color3.new(0, 0, 0)
    HealthBarOutline.Size = UDim2.new(0, 3, 0, 0)
    HealthBarOutline.Parent = ESPFolder
    
    local HealthBar = Instance.new("Frame")
    HealthBar.Name = "HealthBar"
    HealthBar.BorderSizePixel = 0
    HealthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    HealthBar.AnchorPoint = Vector2.new(0, 1)
    HealthBar.Size = UDim2.new(0, 1, 0, 0)
    HealthBar.Parent = HealthBarOutline
    
    -- Health Text
    local HealthLabel = Instance.new("TextLabel")
    HealthLabel.Name = "HealthLabel"
    HealthLabel.BackgroundTransparency = 1
    HealthLabel.Size = UDim2.new(0, 200, 0, 20)
    HealthLabel.Font = Enum.Font.SourceSansBold
    HealthLabel.TextSize = 14
    HealthLabel.TextStrokeTransparency = 0.4
    HealthLabel.Parent = ESPFolder
    
    -- Highlight (Chams)
    local Highlight = Instance.new("Highlight")
    Highlight.Name = "Highlight"
    Highlight.FillTransparency = 0.5
    Highlight.OutlineTransparency = 0
    Highlight.Parent = ESPFolder
    
    return ESPFolder
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if not IsPlayerValid(player) then
            local existingESP = ESPContainer:FindFirstChild(player.Name)
            if existingESP then
                existingESP:Destroy()
            end
            continue
        end
        
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
            continue
        end
        
        local humanoidRootPart = character.HumanoidRootPart
        local humanoid = character.Humanoid
        local head = character:FindFirstChild("Head")
        
        -- Check distance
        local distance = (humanoidRootPart.Position - Camera.CFrame.Position).Magnitude
        if distance > Settings.MaxDistance then
            local existingESP = ESPContainer:FindFirstChild(player.Name)
            if existingESP then
                existingESP.Visible = false
            end
            continue
        end
        
        -- Get or create ESP items
        local espFolder = ESPContainer:FindFirstChild(player.Name)
        if not espFolder then
            espFolder = CreateESPItems(player)
        end
        
        -- Update visibility
        espFolder.Visible = Settings.Enabled
        
        if not Settings.Enabled then
            continue
        end
        
        -- Get player color
        local playerColor = GetPlayerColor(player)
        
        -- Update box ESP
        if Settings.BoxESP and head then
            local box = espFolder:FindFirstChild("Box")
            local boxOutline = espFolder:FindFirstChild("BoxOutline")
            
            -- Calculate box positions
            local rootPos, rootVis = Camera:WorldToViewportPoint(humanoidRootPart.Position)
            if rootVis then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))
                
                local boxSize = Vector2.new(1000 / rootPos.Z, headPos.Y - legPos.Y)
                local boxPosition = Vector2.new(rootPos.X - boxSize.X / 2, rootPos.Y - boxSize.Y / 2)
                
                box.Size = UDim2.new(0, boxSize.X, 0, boxSize.Y)
                box.Position = UDim2.new(0, boxPosition.X, 0, boxPosition.Y)
                box.BorderColor3 = playerColor
                box.Visible = true
                
                boxOutline.Size = UDim2.new(0, boxSize.X, 0, boxSize.Y)
                boxOutline.Position = UDim2.new(0, boxPosition.X, 0, boxPosition.Y)
                boxOutline.Visible = true
            else
                box.Visible = false
                boxOutline.Visible = false
            end
        else
            local box = espFolder:FindFirstChild("Box")
            local boxOutline = espFolder:FindFirstChild("BoxOutline")
            if box then box.Visible = false end
            if boxOutline then boxOutline.Visible = false end
        end
        
        -- Update name ESP
        if Settings.NameESP and head then
            local nameLabel = espFolder:FindFirstChild("NameLabel")
            
            local headPos, headVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
            if headVis then
                nameLabel.Text = player.Name
                nameLabel.Position = UDim2.new(0, headPos.X - nameLabel.TextBounds.X / 2, 0, headPos.Y - 35)
                nameLabel.TextColor3 = playerColor
                nameLabel.Visible = true
            else
                nameLabel.Visible = false
            end
        else
            local nameLabel = espFolder:FindFirstChild("NameLabel")
            if nameLabel then nameLabel.Visible = false end
        end
        
        -- Update health ESP
        if Settings.HealthESP and humanoid then
            local healthBar = espFolder:FindFirstChild("HealthBarOutline")
            local healthLabel = espFolder:FindFirstChild("HealthLabel")
            
            local rootPos, rootVis = Camera:WorldToViewportPoint(humanoidRootPart.Position)
            if rootVis then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))
                
                local boxSize = Vector2.new(1000 / rootPos.Z, headPos.Y - legPos.Y)
                local boxPosition = Vector2.new(rootPos.X - boxSize.X / 2, rootPos.Y - boxSize.Y / 2)
                
                -- Health bar
                healthBar.Size = UDim2.new(0, 3, 0, boxSize.Y)
                healthBar.Position = UDim2.new(0, boxPosition.X - 5, 0, boxPosition.Y)
                healthBar.Visible = true
                
                local healthFill = healthBar:FindFirstChild("HealthBar")
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                healthFill.Size = UDim2.new(0, 1, healthPercent, 0)
                healthFill.Position = UDim2.new(0, 1, 1, 0)
                
                -- Health color gradient (green to red)
                healthFill.BackgroundColor3 = Color3.fromRGB(
                    255 * (1 - healthPercent),
                    255 * healthPercent,
                    0
                )
                
                -- Health text
                healthLabel.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                healthLabel.Position = UDim2.new(0, boxPosition.X - 5 - healthLabel.TextBounds.X / 2, 0, boxPosition.Y + boxSize.Y + 2)
                healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                healthLabel.Visible = true
            else
                healthBar.Visible = false
                healthLabel.Visible = false
            end
        else
            local healthBar = espFolder:FindFirstChild("HealthBarOutline")
            local healthLabel = espFolder:FindFirstChild("HealthLabel")
            if healthBar then healthBar.Visible = false end
            if healthLabel then healthLabel.Visible = false end
        end
        
        -- Update highlight (Chams)
        local highlight = espFolder:FindFirstChild("Highlight")
        if highlight then
            highlight.FillColor = playerColor
            highlight.OutlineColor = playerColor
            highlight.Enabled = Settings.HighlightESP
            highlight.Adornee = character
        end
    end
end

-- Toggle UI visibility
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.ToggleKey then
        Settings.ShowUI = not Settings.ShowUI
        UIContainer.Visible = Settings.ShowUI
    end
end)

-- Clean up ESP when player leaves
Players.PlayerRemoving:Connect(function(player)
    local espFolder = ESPContainer:FindFirstChild(player.Name)
    if espFolder then
        espFolder:Destroy()
    end
end)

-- Main ESP loop
local lastUpdateTime = 0
RunService.RenderStepped:Connect(function(deltaTime)
    local currentTime = tick()
    if currentTime - lastUpdateTime >= (1 / Settings.RefreshRate) then
        UpdateESP()
        lastUpdateTime = currentTime
    end
end)

-- Notification
local function Notify(title, text, duration)
    duration = duration or 5
    
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "PrismNotification"
    
    -- Try to parent to CoreGui
    pcall(function()
        notifGui.Parent = CoreGui
    end)
    
    -- If failed, try PlayerGui
    if not notifGui.Parent then
        pcall(function()
            notifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(0.5, -150, 0.8, -40)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.1
    frame.Parent = notifGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Text = title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 40)
    messageLabel.Position = UDim2.new(0, 10, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.Text = text
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextWrapped = true
    messageLabel.Parent = frame
    
    -- Animation
    frame.Position = UDim2.new(0.5, -150, 1, 20)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(frame, tweenInfo, {Position = UDim2.new(0.5, -150, 0.8, -40)})
    tween:Play()
    
    -- Auto remove
    task.delay(duration, function()
        local fadeOut = game:GetService("TweenService"):Create(frame, tweenInfo, {Position = UDim2.new(0.5, -150, 1, 20)})
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            notifGui:Destroy()
        end)
    end)
end

-- Show welcome notification
Notify("Prism Analytics", "ESP loaded successfully! Press Right Shift to toggle UI.", 5)

print("Prism Analytics Simple Version loaded successfully!")
