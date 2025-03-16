--[[
    Prism Analytics UI Module
    
    This module handles the UI for Prism Analytics.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Load ESP Module
local ESP

-- Try to load ESP module directly
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Amhim123hd/PRismWorld/main/prism_esp.lua"))()
end)

if success then
    ESP = result
    print("Loaded ESP module from GitHub")
else
    warn("Failed to load ESP from GitHub: " .. tostring(result))
    -- Try to load ESP from local require
    pcall(function()
        ESP = require(script.Parent.prism_esp)
        print("Loaded ESP module from local require")
    end)
end

-- Check if ESP module is loaded
if not ESP then
    error("Failed to load ESP module. Aborting.")
end

-- Variables
local localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local PlayerGui

-- Settings
local settings = {
    espEnabled = false,
    boxEsp = false,
    nameEsp = false,
    healthEsp = false,
    chamsEnabled = false,
    highlightEnabled = false,  
    highlightFillColor = Color3.fromRGB(255, 0, 4),
    highlightOutlineColor = Color3.fromRGB(255, 255, 255),
    highlightFillTransparency = 0.5,
    highlightOutlineTransparency = 0,
    teamCheck = true,
    aimbotEnabled = false,
    aimbotKey = Enum.KeyCode.E,
    smoothness = 0.5,
    fov = 100,
    targetPart = "Head"
}

-- UI Configuration
local config = {
    backgroundColor = Color3.fromRGB(25, 25, 25),
    secondaryColor = Color3.fromRGB(35, 35, 35),
    accentColor = Color3.fromRGB(0, 170, 255),
    textColor = Color3.fromRGB(255, 255, 255),
    fontSize = 14,
    toggleOnColor = Color3.fromRGB(0, 170, 255),
    toggleOffColor = Color3.fromRGB(100, 100, 100),
    cornerRadius = UDim.new(0, 5)
}

-- Forward declaration for functions
local updatePlayerList
local createPlayerEntry
local createUI
local toggleUI
local createTab
local createToggle
local createSlider
local createKeybind
local createDropdown

-- Create player entry for the list
createPlayerEntry = function(player, parent, index)
    local entryHeight = 70
    local yPos = (index - 1) * entryHeight
    
    -- Create entry frame
    local entry = Instance.new("Frame")
    entry.Name = player.Name .. "Entry"
    entry.Size = UDim2.new(1, -10, 0, entryHeight - 5)
    entry.Position = UDim2.new(0, 5, 0, yPos)
    entry.BackgroundColor3 = config.backgroundColor
    entry.BackgroundTransparency = 0.5
    entry.BorderSizePixel = 0
    entry.Parent = parent
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = config.cornerRadius
    entryCorner.Parent = entry
    
    -- Create player avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 10, 0, 10)
    avatar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    avatar.BorderSizePixel = 0
    
    -- Try to load player avatar
    local success, content = pcall(function()
        local userId = player.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size420x420
        
        return Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
    end)
    
    if success then
        avatar.Image = content
    end
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = avatar
    
    avatar.Parent = entry
    
    -- Create player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -80, 0, 25)
    nameLabel.Position = UDim2.new(0, 70, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.Text = player.DisplayName or player.Name
    nameLabel.TextColor3 = config.textColor
    nameLabel.TextSize = config.fontSize
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- Create player username
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Name = "UsernameLabel"
    usernameLabel.Size = UDim2.new(1, -80, 0, 20)
    usernameLabel.Position = UDim2.new(0, 70, 0, 30)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Font = Enum.Font.Gotham
    usernameLabel.Text = "@" .. player.Name
    usernameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    usernameLabel.TextSize = config.fontSize - 2
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    usernameLabel.Parent = entry
    
    -- Create status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 100, 0, 20)
    statusLabel.Position = UDim2.new(1, -110, 0, 10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Online"
    statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
    statusLabel.TextSize = config.fontSize - 2
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = entry
    
    return entry
end

-- Update player list
updatePlayerList = function(contentFrame)
    -- Clear existing entries
    for _, child in pairs(contentFrame:GetChildren()) do
        child:Destroy()
    end
    
    -- Get all players
    local playerList = Players:GetPlayers()
    
    -- Create entries for each player
    for i, player in ipairs(playerList) do
        createPlayerEntry(player, contentFrame, i)
    end
    
    -- Update canvas size
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, #playerList * 70)
end

-- Create main UI
createUI = function()
    -- Create ScreenGui
    local screenGui
    
    -- Check if we're in a normal Roblox environment or an executor
    local success, result = pcall(function()
        -- Try to create a ScreenGui as a child of PlayerGui
        if PlayerGui then
            local gui = Instance.new("ScreenGui")
            gui.Name = "PlayerPanel"
            gui.ResetOnSpawn = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.Parent = PlayerGui
            return gui
        else
            -- If PlayerGui doesn't exist, we might be in an executor
            local gui = Instance.new("ScreenGui")
            gui.Name = "PlayerPanel"
            gui.ResetOnSpawn = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            
            -- Try different parent options for executors
            if game:GetService("CoreGui") then
                gui.Parent = game:GetService("CoreGui")
            elseif game.Players.LocalPlayer:FindFirstChild("PlayerGui") then
                gui.Parent = game.Players.LocalPlayer.PlayerGui
            else
                -- Last resort
                gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            end
            
            return gui
        end
    end)
    
    if success then
        screenGui = result
    else
        -- Fallback method for some executors
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PlayerPanel"
        
        -- Try to use protected GUI methods with a defensive approach
        local function tryParentGui()
            local env = getfenv(1)
            
            -- Try Synapse X
            if pcall(function() return env["syn"] and env["syn"]["protect_gui"] end) then
                local protectGui = env["syn"]["protect_gui"]
                protectGui(screenGui)
                screenGui.Parent = game:GetService("CoreGui")
                return true
            end
            
            -- Try other protect_gui implementations
            if pcall(function() return env["protect_gui"] end) then
                local protectGui = env["protect_gui"]
                protectGui(screenGui)
                screenGui.Parent = game:GetService("CoreGui")
                return true
            end
            
            -- Try gethui
            if pcall(function() return env["gethui"] end) then
                local getHui = env["gethui"]
                screenGui.Parent = getHui()
                return true
            end
            
            -- Last resort
            screenGui.Parent = game:GetService("CoreGui")
            return true
        end
        
        pcall(tryParentGui)
    end
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = config.backgroundColor
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = config.cornerRadius
    corner.Parent = mainFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = config.secondaryColor
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 40, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.Text = "Prism Analytics"
    title.TextColor3 = config.textColor
    title.TextSize = config.fontSize + 2
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Create menu button
    local menuButton = Instance.new("ImageButton")
    menuButton.Name = "MenuButton"
    menuButton.Size = UDim2.new(0, 20, 0, 20)
    menuButton.Position = UDim2.new(0, 10, 0, 5)
    menuButton.BackgroundTransparency = 1
    menuButton.Image = "rbxassetid://3926305904"
    menuButton.ImageRectOffset = Vector2.new(604, 684)
    menuButton.ImageRectSize = Vector2.new(36, 36)
    menuButton.ImageColor3 = config.textColor
    menuButton.Parent = titleBar
    
    -- Create close button
    local closeButton = Instance.new("ImageButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -30, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.Image = "rbxassetid://3926305904"
    closeButton.ImageRectOffset = Vector2.new(284, 4)
    closeButton.ImageRectSize = Vector2.new(24, 24)
    closeButton.ImageColor3 = config.textColor
    closeButton.Parent = titleBar
    
    -- Create minimize button
    local minimizeButton = Instance.new("ImageButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 20, 0, 20)
    minimizeButton.Position = UDim2.new(1, -60, 0, 5)
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.Image = "rbxassetid://3926307971"
    minimizeButton.ImageRectOffset = Vector2.new(884, 284)
    minimizeButton.ImageRectSize = Vector2.new(36, 36)
    minimizeButton.ImageColor3 = config.textColor
    minimizeButton.Parent = titleBar
    
    -- Create tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    tabBar.Position = UDim2.new(0, 0, 0, 30)
    tabBar.BackgroundColor3 = config.secondaryColor
    tabBar.BorderSizePixel = 0
    tabBar.Parent = mainFrame
    
    -- Create tab content area
    local tabContentArea = Instance.new("Frame")
    tabContentArea.Name = "TabContentArea"
    tabContentArea.Size = UDim2.new(1, 0, 1, -60)
    tabContentArea.Position = UDim2.new(0, 0, 0, 60)
    tabContentArea.BackgroundColor3 = config.backgroundColor
    tabContentArea.BorderSizePixel = 0
    tabContentArea.Parent = mainFrame
    
    -- Create tabs
    local tabButtons = {}
    local tabContent = {}
    local tabNames = {"Visuals", "Aimbot", "Players"}
    
    for i, tabName in ipairs(tabNames) do
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Button"
        tabButton.Size = UDim2.new(1/#tabNames, 0, 1, 0)
        tabButton.Position = UDim2.new((i-1)/#tabNames, 0, 0, 0)
        tabButton.BackgroundColor3 = config.secondaryColor
        tabButton.BorderSizePixel = 0
        tabButton.Font = Enum.Font.Gotham
        tabButton.Text = tabName
        tabButton.TextColor3 = config.textColor
        tabButton.TextSize = config.fontSize
        tabButton.Parent = tabBar
        tabButtons[i] = tabButton
        
        -- Create tab content
        local content = Instance.new("Frame")
        content.Name = tabName .. "Content"
        content.Size = UDim2.new(1, 0, 1, 0)
        content.Position = UDim2.new(0, 0, 0, 0)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.Visible = false
        content.Parent = tabContentArea
        tabContent[i] = content
    end
    
    -- Create visuals tab content
    local visualsTab = tabContent[1]
    visualsTab.Visible = true -- Make this tab visible by default
    tabButtons[1].BackgroundColor3 = config.accentColor -- Select this tab by default
    
    -- Create a scrolling frame for the visuals tab
    local visualsScroll = Instance.new("ScrollingFrame")
    visualsScroll.Name = "VisualsScroll"
    visualsScroll.Size = UDim2.new(1, -10, 1, -10)
    visualsScroll.Position = UDim2.new(0, 5, 0, 5)
    visualsScroll.BackgroundTransparency = 1
    visualsScroll.BorderSizePixel = 0
    visualsScroll.ScrollBarThickness = 4
    visualsScroll.ScrollBarImageColor3 = config.accentColor
    visualsScroll.CanvasSize = UDim2.new(0, 0, 0, 300) -- Will adjust based on content
    visualsScroll.Parent = visualsTab
    
    -- Create a title for the ESP section
    local espTitle = Instance.new("TextLabel")
    espTitle.Name = "ESPTitle"
    espTitle.Size = UDim2.new(1, -20, 0, 30)
    espTitle.Position = UDim2.new(0, 10, 0, 10)
    espTitle.BackgroundTransparency = 1
    espTitle.Font = Enum.Font.GothamBold
    espTitle.Text = "ESP Options"
    espTitle.TextColor3 = config.accentColor
    espTitle.TextSize = config.fontSize + 2
    espTitle.TextXAlignment = Enum.TextXAlignment.Left
    espTitle.Parent = visualsScroll
    
    -- Main ESP toggle
    local espToggle = Instance.new("Frame")
    espToggle.Name = "ESPToggle"
    espToggle.Size = UDim2.new(1, -20, 0, 30)
    espToggle.Position = UDim2.new(0, 10, 0, 50)
    espToggle.BackgroundColor3 = config.secondaryColor
    espToggle.BorderSizePixel = 0
    espToggle.Parent = visualsScroll
    
    local espToggleCorner = Instance.new("UICorner")
    espToggleCorner.CornerRadius = config.cornerRadius
    espToggleCorner.Parent = espToggle
    
    local espToggleLabel = Instance.new("TextLabel")
    espToggleLabel.Name = "Label"
    espToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    espToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    espToggleLabel.BackgroundTransparency = 1
    espToggleLabel.Font = Enum.Font.Gotham
    espToggleLabel.Text = "ESP Enabled"
    espToggleLabel.TextColor3 = config.textColor
    espToggleLabel.TextSize = config.fontSize
    espToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    espToggleLabel.Parent = espToggle
    
    local espToggleButton = Instance.new("TextButton")
    espToggleButton.Name = "Button"
    espToggleButton.Size = UDim2.new(0, 40, 0, 20)
    espToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    espToggleButton.BackgroundColor3 = settings.espEnabled and config.toggleOnColor or config.toggleOffColor
    espToggleButton.BorderSizePixel = 0
    espToggleButton.Text = ""
    espToggleButton.Parent = espToggle
    
    local espToggleButtonCorner = Instance.new("UICorner")
    espToggleButtonCorner.CornerRadius = UDim.new(1, 0)
    espToggleButtonCorner.Parent = espToggleButton
    
    local espToggleCircle = Instance.new("Frame")
    espToggleCircle.Name = "Circle"
    espToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    espToggleCircle.Position = settings.espEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    espToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    espToggleCircle.BorderSizePixel = 0
    espToggleCircle.Parent = espToggleButton
    
    local espToggleCircleCorner = Instance.new("UICorner")
    espToggleCircleCorner.CornerRadius = UDim.new(1, 0)
    espToggleCircleCorner.Parent = espToggleCircle
    
    -- Box ESP toggle
    local boxEspToggle = Instance.new("Frame")
    boxEspToggle.Name = "BoxESPToggle"
    boxEspToggle.Size = UDim2.new(1, -20, 0, 30)
    boxEspToggle.Position = UDim2.new(0, 10, 0, 90)
    boxEspToggle.BackgroundColor3 = config.secondaryColor
    boxEspToggle.BorderSizePixel = 0
    boxEspToggle.Parent = visualsScroll
    
    local boxEspToggleCorner = Instance.new("UICorner")
    boxEspToggleCorner.CornerRadius = config.cornerRadius
    boxEspToggleCorner.Parent = boxEspToggle
    
    local boxEspToggleLabel = Instance.new("TextLabel")
    boxEspToggleLabel.Name = "Label"
    boxEspToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    boxEspToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    boxEspToggleLabel.BackgroundTransparency = 1
    boxEspToggleLabel.Font = Enum.Font.Gotham
    boxEspToggleLabel.Text = "Box ESP"
    boxEspToggleLabel.TextColor3 = config.textColor
    boxEspToggleLabel.TextSize = config.fontSize
    boxEspToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    boxEspToggleLabel.Parent = boxEspToggle
    
    local boxEspToggleButton = Instance.new("TextButton")
    boxEspToggleButton.Name = "Button"
    boxEspToggleButton.Size = UDim2.new(0, 40, 0, 20)
    boxEspToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    boxEspToggleButton.BackgroundColor3 = settings.boxEsp and config.toggleOnColor or config.toggleOffColor
    boxEspToggleButton.BorderSizePixel = 0
    boxEspToggleButton.Text = ""
    boxEspToggleButton.Parent = boxEspToggle
    
    local boxEspToggleButtonCorner = Instance.new("UICorner")
    boxEspToggleButtonCorner.CornerRadius = UDim.new(1, 0)
    boxEspToggleButtonCorner.Parent = boxEspToggleButton
    
    local boxEspToggleCircle = Instance.new("Frame")
    boxEspToggleCircle.Name = "Circle"
    boxEspToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    boxEspToggleCircle.Position = settings.boxEsp and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    boxEspToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    boxEspToggleCircle.BorderSizePixel = 0
    boxEspToggleCircle.Parent = boxEspToggleButton
    
    local boxEspToggleCircleCorner = Instance.new("UICorner")
    boxEspToggleCircleCorner.CornerRadius = UDim.new(1, 0)
    boxEspToggleCircleCorner.Parent = boxEspToggleCircle
    
    -- Name ESP toggle
    local nameEspToggle = Instance.new("Frame")
    nameEspToggle.Name = "NameESPToggle"
    nameEspToggle.Size = UDim2.new(1, -20, 0, 30)
    nameEspToggle.Position = UDim2.new(0, 10, 0, 130)
    nameEspToggle.BackgroundColor3 = config.secondaryColor
    nameEspToggle.BorderSizePixel = 0
    nameEspToggle.Parent = visualsScroll
    
    local nameEspToggleCorner = Instance.new("UICorner")
    nameEspToggleCorner.CornerRadius = config.cornerRadius
    nameEspToggleCorner.Parent = nameEspToggle
    
    local nameEspToggleLabel = Instance.new("TextLabel")
    nameEspToggleLabel.Name = "Label"
    nameEspToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    nameEspToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    nameEspToggleLabel.BackgroundTransparency = 1
    nameEspToggleLabel.Font = Enum.Font.Gotham
    nameEspToggleLabel.Text = "Name ESP"
    nameEspToggleLabel.TextColor3 = config.textColor
    nameEspToggleLabel.TextSize = config.fontSize
    nameEspToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameEspToggleLabel.Parent = nameEspToggle
    
    local nameEspToggleButton = Instance.new("TextButton")
    nameEspToggleButton.Name = "Button"
    nameEspToggleButton.Size = UDim2.new(0, 40, 0, 20)
    nameEspToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    nameEspToggleButton.BackgroundColor3 = settings.nameEsp and config.toggleOnColor or config.toggleOffColor
    nameEspToggleButton.BorderSizePixel = 0
    nameEspToggleButton.Text = ""
    nameEspToggleButton.Parent = nameEspToggle
    
    local nameEspToggleButtonCorner = Instance.new("UICorner")
    nameEspToggleButtonCorner.CornerRadius = UDim.new(1, 0)
    nameEspToggleButtonCorner.Parent = nameEspToggleButton
    
    local nameEspToggleCircle = Instance.new("Frame")
    nameEspToggleCircle.Name = "Circle"
    nameEspToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    nameEspToggleCircle.Position = settings.nameEsp and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    nameEspToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    nameEspToggleCircle.BorderSizePixel = 0
    nameEspToggleCircle.Parent = nameEspToggleButton
    
    local nameEspToggleCircleCorner = Instance.new("UICorner")
    nameEspToggleCircleCorner.CornerRadius = UDim.new(1, 0)
    nameEspToggleCircleCorner.Parent = nameEspToggleCircle
    
    -- Health ESP toggle
    local healthEspToggle = Instance.new("Frame")
    healthEspToggle.Name = "HealthESPToggle"
    healthEspToggle.Size = UDim2.new(1, -20, 0, 30)
    healthEspToggle.Position = UDim2.new(0, 10, 0, 170)
    healthEspToggle.BackgroundColor3 = config.secondaryColor
    healthEspToggle.BorderSizePixel = 0
    healthEspToggle.Parent = visualsScroll
    
    local healthEspToggleCorner = Instance.new("UICorner")
    healthEspToggleCorner.CornerRadius = config.cornerRadius
    healthEspToggleCorner.Parent = healthEspToggle
    
    local healthEspToggleLabel = Instance.new("TextLabel")
    healthEspToggleLabel.Name = "Label"
    healthEspToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    healthEspToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    healthEspToggleLabel.BackgroundTransparency = 1
    healthEspToggleLabel.Font = Enum.Font.Gotham
    healthEspToggleLabel.Text = "Health ESP"
    healthEspToggleLabel.TextColor3 = config.textColor
    healthEspToggleLabel.TextSize = config.fontSize
    healthEspToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    healthEspToggleLabel.Parent = healthEspToggle
    
    local healthEspToggleButton = Instance.new("TextButton")
    healthEspToggleButton.Name = "Button"
    healthEspToggleButton.Size = UDim2.new(0, 40, 0, 20)
    healthEspToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    healthEspToggleButton.BackgroundColor3 = settings.healthEsp and config.toggleOnColor or config.toggleOffColor
    healthEspToggleButton.BorderSizePixel = 0
    healthEspToggleButton.Text = ""
    healthEspToggleButton.Parent = healthEspToggle
    
    local healthEspToggleButtonCorner = Instance.new("UICorner")
    healthEspToggleButtonCorner.CornerRadius = UDim.new(1, 0)
    healthEspToggleButtonCorner.Parent = healthEspToggleButton
    
    local healthEspToggleCircle = Instance.new("Frame")
    healthEspToggleCircle.Name = "Circle"
    healthEspToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    healthEspToggleCircle.Position = settings.healthEsp and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    healthEspToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    healthEspToggleCircle.BorderSizePixel = 0
    healthEspToggleCircle.Parent = healthEspToggleButton
    
    local healthEspToggleCircleCorner = Instance.new("UICorner")
    healthEspToggleCircleCorner.CornerRadius = UDim.new(1, 0)
    healthEspToggleCircleCorner.Parent = healthEspToggleCircle
    
    -- Highlight ESP toggle
    local highlightEspToggle = Instance.new("Frame")
    highlightEspToggle.Name = "HighlightESPToggle"
    highlightEspToggle.Size = UDim2.new(1, -20, 0, 30)
    highlightEspToggle.Position = UDim2.new(0, 10, 0, 210)
    highlightEspToggle.BackgroundColor3 = config.secondaryColor
    highlightEspToggle.BorderSizePixel = 0
    highlightEspToggle.Parent = visualsScroll
    
    local highlightEspToggleCorner = Instance.new("UICorner")
    highlightEspToggleCorner.CornerRadius = config.cornerRadius
    highlightEspToggleCorner.Parent = highlightEspToggle
    
    local highlightEspToggleLabel = Instance.new("TextLabel")
    highlightEspToggleLabel.Name = "Label"
    highlightEspToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    highlightEspToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    highlightEspToggleLabel.BackgroundTransparency = 1
    highlightEspToggleLabel.Font = Enum.Font.Gotham
    highlightEspToggleLabel.Text = "Highlight ESP"
    highlightEspToggleLabel.TextColor3 = config.textColor
    highlightEspToggleLabel.TextSize = config.fontSize
    highlightEspToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    highlightEspToggleLabel.Parent = highlightEspToggle
    
    local highlightEspToggleButton = Instance.new("TextButton")
    highlightEspToggleButton.Name = "Button"
    highlightEspToggleButton.Size = UDim2.new(0, 40, 0, 20)
    highlightEspToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    highlightEspToggleButton.BackgroundColor3 = settings.highlightEnabled and config.toggleOnColor or config.toggleOffColor
    highlightEspToggleButton.BorderSizePixel = 0
    highlightEspToggleButton.Text = ""
    highlightEspToggleButton.Parent = highlightEspToggle
    
    local highlightEspToggleButtonCorner = Instance.new("UICorner")
    highlightEspToggleButtonCorner.CornerRadius = UDim.new(1, 0)
    highlightEspToggleButtonCorner.Parent = highlightEspToggleButton
    
    local highlightEspToggleCircle = Instance.new("Frame")
    highlightEspToggleCircle.Name = "Circle"
    highlightEspToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    highlightEspToggleCircle.Position = settings.highlightEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    highlightEspToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    highlightEspToggleCircle.BorderSizePixel = 0
    highlightEspToggleCircle.Parent = highlightEspToggleButton
    
    local highlightEspToggleCircleCorner = Instance.new("UICorner")
    highlightEspToggleCircleCorner.CornerRadius = UDim.new(1, 0)
    highlightEspToggleCircleCorner.Parent = highlightEspToggleCircle
    
    -- Chams toggle
    local chamsToggle = Instance.new("Frame")
    chamsToggle.Name = "ChamsToggle"
    chamsToggle.Size = UDim2.new(1, -20, 0, 30)
    chamsToggle.Position = UDim2.new(0, 10, 0, 250)
    chamsToggle.BackgroundColor3 = config.secondaryColor
    chamsToggle.BorderSizePixel = 0
    chamsToggle.Parent = visualsScroll
    
    local chamsToggleCorner = Instance.new("UICorner")
    chamsToggleCorner.CornerRadius = config.cornerRadius
    chamsToggleCorner.Parent = chamsToggle
    
    local chamsToggleLabel = Instance.new("TextLabel")
    chamsToggleLabel.Name = "Label"
    chamsToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    chamsToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    chamsToggleLabel.BackgroundTransparency = 1
    chamsToggleLabel.Font = Enum.Font.Gotham
    chamsToggleLabel.Text = "Player Chams"
    chamsToggleLabel.TextColor3 = config.textColor
    chamsToggleLabel.TextSize = config.fontSize
    chamsToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    chamsToggleLabel.Parent = chamsToggle
    
    local chamsToggleButton = Instance.new("TextButton")
    chamsToggleButton.Name = "Button"
    chamsToggleButton.Size = UDim2.new(0, 40, 0, 20)
    chamsToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    chamsToggleButton.BackgroundColor3 = settings.chamsEnabled and config.toggleOnColor or config.toggleOffColor
    chamsToggleButton.BorderSizePixel = 0
    chamsToggleButton.Text = ""
    chamsToggleButton.Parent = chamsToggle
    
    local chamsToggleButtonCorner = Instance.new("UICorner")
    chamsToggleButtonCorner.CornerRadius = UDim.new(1, 0)
    chamsToggleButtonCorner.Parent = chamsToggleButton
    
    local chamsToggleCircle = Instance.new("Frame")
    chamsToggleCircle.Name = "Circle"
    chamsToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    chamsToggleCircle.Position = settings.chamsEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    chamsToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    chamsToggleCircle.BorderSizePixel = 0
    chamsToggleCircle.Parent = chamsToggleButton
    
    local chamsToggleCircleCorner = Instance.new("UICorner")
    chamsToggleCircleCorner.CornerRadius = UDim.new(1, 0)
    chamsToggleCircleCorner.Parent = chamsToggleCircle
    
    -- Create aimbot tab content
    local aimbotTab = tabContent[2]
    
    -- Create a scrolling frame for the aimbot tab
    local aimbotScroll = Instance.new("ScrollingFrame")
    aimbotScroll.Name = "AimbotScroll"
    aimbotScroll.Size = UDim2.new(1, -10, 1, -10)
    aimbotScroll.Position = UDim2.new(0, 5, 0, 5)
    aimbotScroll.BackgroundTransparency = 1
    aimbotScroll.BorderSizePixel = 0
    aimbotScroll.ScrollBarThickness = 4
    aimbotScroll.ScrollBarImageColor3 = config.accentColor
    aimbotScroll.CanvasSize = UDim2.new(0, 0, 0, 300) -- Will adjust based on content
    aimbotScroll.Parent = aimbotTab
    
    -- Create a title for the Aimbot section
    local aimbotTitle = Instance.new("TextLabel")
    aimbotTitle.Name = "AimbotTitle"
    aimbotTitle.Size = UDim2.new(1, -20, 0, 30)
    aimbotTitle.Position = UDim2.new(0, 10, 0, 10)
    aimbotTitle.BackgroundTransparency = 1
    aimbotTitle.Font = Enum.Font.GothamBold
    aimbotTitle.Text = "Aimbot Options"
    aimbotTitle.TextColor3 = config.accentColor
    aimbotTitle.TextSize = config.fontSize + 2
    aimbotTitle.TextXAlignment = Enum.TextXAlignment.Left
    aimbotTitle.Parent = aimbotScroll
    
    -- Main Aimbot toggle
    local aimbotToggle = Instance.new("Frame")
    aimbotToggle.Name = "AimbotToggle"
    aimbotToggle.Size = UDim2.new(1, -20, 0, 30)
    aimbotToggle.Position = UDim2.new(0, 10, 0, 50)
    aimbotToggle.BackgroundColor3 = config.secondaryColor
    aimbotToggle.BorderSizePixel = 0
    aimbotToggle.Parent = aimbotScroll
    
    local aimbotToggleCorner = Instance.new("UICorner")
    aimbotToggleCorner.CornerRadius = config.cornerRadius
    aimbotToggleCorner.Parent = aimbotToggle
    
    local aimbotToggleLabel = Instance.new("TextLabel")
    aimbotToggleLabel.Name = "Label"
    aimbotToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    aimbotToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    aimbotToggleLabel.BackgroundTransparency = 1
    aimbotToggleLabel.Font = Enum.Font.Gotham
    aimbotToggleLabel.Text = "Aimbot Enabled"
    aimbotToggleLabel.TextColor3 = config.textColor
    aimbotToggleLabel.TextSize = config.fontSize
    aimbotToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    aimbotToggleLabel.Parent = aimbotToggle
    
    local aimbotToggleButton = Instance.new("TextButton")
    aimbotToggleButton.Name = "Button"
    aimbotToggleButton.Size = UDim2.new(0, 40, 0, 20)
    aimbotToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    aimbotToggleButton.BackgroundColor3 = settings.aimbotEnabled and config.toggleOnColor or config.toggleOffColor
    aimbotToggleButton.BorderSizePixel = 0
    aimbotToggleButton.Text = ""
    aimbotToggleButton.Parent = aimbotToggle
    
    local aimbotToggleButtonCorner = Instance.new("UICorner")
    aimbotToggleButtonCorner.CornerRadius = UDim.new(1, 0)
    aimbotToggleButtonCorner.Parent = aimbotToggleButton
    
    local aimbotToggleCircle = Instance.new("Frame")
    aimbotToggleCircle.Name = "Circle"
    aimbotToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    aimbotToggleCircle.Position = settings.aimbotEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    aimbotToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    aimbotToggleCircle.BorderSizePixel = 0
    aimbotToggleCircle.Parent = aimbotToggleButton
    
    local aimbotToggleCircleCorner = Instance.new("UICorner")
    aimbotToggleCircleCorner.CornerRadius = UDim.new(1, 0)
    aimbotToggleCircleCorner.Parent = aimbotToggleCircle
    
    -- Aimbot Key Setting
    local aimbotKeyFrame = Instance.new("Frame")
    aimbotKeyFrame.Name = "AimbotKeyFrame"
    aimbotKeyFrame.Size = UDim2.new(1, -20, 0, 30)
    aimbotKeyFrame.Position = UDim2.new(0, 10, 0, 90)
    aimbotKeyFrame.BackgroundColor3 = config.secondaryColor
    aimbotKeyFrame.BorderSizePixel = 0
    aimbotKeyFrame.Parent = aimbotScroll
    
    local aimbotKeyFrameCorner = Instance.new("UICorner")
    aimbotKeyFrameCorner.CornerRadius = config.cornerRadius
    aimbotKeyFrameCorner.Parent = aimbotKeyFrame
    
    local aimbotKeyLabel = Instance.new("TextLabel")
    aimbotKeyLabel.Name = "Label"
    aimbotKeyLabel.Size = UDim2.new(0.5, -10, 1, 0)
    aimbotKeyLabel.Position = UDim2.new(0, 10, 0, 0)
    aimbotKeyLabel.BackgroundTransparency = 1
    aimbotKeyLabel.Font = Enum.Font.Gotham
    aimbotKeyLabel.Text = "Aimbot Key"
    aimbotKeyLabel.TextColor3 = config.textColor
    aimbotKeyLabel.TextSize = config.fontSize
    aimbotKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    aimbotKeyLabel.Parent = aimbotKeyFrame
    
    local aimbotKeyButton = Instance.new("TextButton")
    aimbotKeyButton.Name = "KeyButton"
    aimbotKeyButton.Size = UDim2.new(0.4, 0, 0.8, 0)
    aimbotKeyButton.Position = UDim2.new(0.6, -5, 0.1, 0)
    aimbotKeyButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    aimbotKeyButton.BorderSizePixel = 0
    aimbotKeyButton.Font = Enum.Font.Gotham
    aimbotKeyButton.Text = settings.aimbotKey.Name
    aimbotKeyButton.TextColor3 = config.textColor
    aimbotKeyButton.TextSize = config.fontSize
    aimbotKeyButton.Parent = aimbotKeyFrame
    
    local aimbotKeyButtonCorner = Instance.new("UICorner")
    aimbotKeyButtonCorner.CornerRadius = config.cornerRadius
    aimbotKeyButtonCorner.Parent = aimbotKeyButton
    
    -- Aimbot Smoothness Setting
    local smoothnessFrame = Instance.new("Frame")
    smoothnessFrame.Name = "SmoothnessFrame"
    smoothnessFrame.Size = UDim2.new(1, -20, 0, 60)
    smoothnessFrame.Position = UDim2.new(0, 10, 0, 130)
    smoothnessFrame.BackgroundColor3 = config.secondaryColor
    smoothnessFrame.BorderSizePixel = 0
    smoothnessFrame.Parent = aimbotScroll
    
    local smoothnessFrameCorner = Instance.new("UICorner")
    smoothnessFrameCorner.CornerRadius = config.cornerRadius
    smoothnessFrameCorner.Parent = smoothnessFrame
    
    local smoothnessLabel = Instance.new("TextLabel")
    smoothnessLabel.Name = "Label"
    smoothnessLabel.Size = UDim2.new(1, -20, 0, 20)
    smoothnessLabel.Position = UDim2.new(0, 10, 0, 5)
    smoothnessLabel.BackgroundTransparency = 1
    smoothnessLabel.Font = Enum.Font.Gotham
    smoothnessLabel.Text = "Smoothness: " .. tostring(settings.smoothness)
    smoothnessLabel.TextColor3 = config.textColor
    smoothnessLabel.TextSize = config.fontSize
    smoothnessLabel.TextXAlignment = Enum.TextXAlignment.Left
    smoothnessLabel.Parent = smoothnessFrame
    
    local smoothnessSlider = Instance.new("Frame")
    smoothnessSlider.Name = "Slider"
    smoothnessSlider.Size = UDim2.new(1, -20, 0, 5)
    smoothnessSlider.Position = UDim2.new(0, 10, 0, 35)
    smoothnessSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    smoothnessSlider.BorderSizePixel = 0
    smoothnessSlider.Parent = smoothnessFrame
    
    local smoothnessSliderCorner = Instance.new("UICorner")
    smoothnessSliderCorner.CornerRadius = UDim.new(1, 0)
    smoothnessSliderCorner.Parent = smoothnessSlider
    
    local smoothnessKnob = Instance.new("TextButton")
    smoothnessKnob.Name = "Knob"
    smoothnessKnob.Size = UDim2.new(0, 15, 0, 15)
    smoothnessKnob.Position = UDim2.new(settings.smoothness, -7.5, 0.5, -7.5)
    smoothnessKnob.BackgroundColor3 = config.accentColor
    smoothnessKnob.BorderSizePixel = 0
    smoothnessKnob.Text = ""
    smoothnessKnob.Parent = smoothnessSlider
    
    local smoothnessKnobCorner = Instance.new("UICorner")
    smoothnessKnobCorner.CornerRadius = UDim.new(1, 0)
    smoothnessKnobCorner.Parent = smoothnessKnob
    
    -- Aimbot FOV Setting
    local fovFrame = Instance.new("Frame")
    fovFrame.Name = "FOVFrame"
    fovFrame.Size = UDim2.new(1, -20, 0, 60)
    fovFrame.Position = UDim2.new(0, 10, 0, 200)
    fovFrame.BackgroundColor3 = config.secondaryColor
    fovFrame.BorderSizePixel = 0
    fovFrame.Parent = aimbotScroll
    
    local fovFrameCorner = Instance.new("UICorner")
    fovFrameCorner.CornerRadius = config.cornerRadius
    fovFrameCorner.Parent = fovFrame
    
    local fovLabel = Instance.new("TextLabel")
    fovLabel.Name = "Label"
    fovLabel.Size = UDim2.new(1, -20, 0, 20)
    fovLabel.Position = UDim2.new(0, 10, 0, 5)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.Text = "FOV: " .. tostring(settings.fov)
    fovLabel.TextColor3 = config.textColor
    fovLabel.TextSize = config.fontSize
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.Parent = fovFrame
    
    local fovSlider = Instance.new("Frame")
    fovSlider.Name = "Slider"
    fovSlider.Size = UDim2.new(1, -20, 0, 5)
    fovSlider.Position = UDim2.new(0, 10, 0, 35)
    fovSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    fovSlider.BorderSizePixel = 0
    fovSlider.Parent = fovFrame
    
    local fovSliderCorner = Instance.new("UICorner")
    fovSliderCorner.CornerRadius = UDim.new(1, 0)
    fovSliderCorner.Parent = fovSlider
    
    local fovKnob = Instance.new("TextButton")
    fovKnob.Name = "Knob"
    fovKnob.Size = UDim2.new(0, 15, 0, 15)
    fovKnob.Position = UDim2.new(settings.fov / 200, -7.5, 0.5, -7.5)
    fovKnob.BackgroundColor3 = config.accentColor
    fovKnob.BorderSizePixel = 0
    fovKnob.Text = ""
    fovKnob.Parent = fovSlider
    
    local fovKnobCorner = Instance.new("UICorner")
    fovKnobCorner.CornerRadius = UDim.new(1, 0)
    fovKnobCorner.Parent = fovKnob
    
    -- Player panel (moved to its own tab)
    local playerTab = tabContent[3]
    
    -- Create a scrolling frame for the player tab
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Name = "PlayerScroll"
    playerScroll.Size = UDim2.new(1, -10, 1, -10)
    playerScroll.Position = UDim2.new(0, 5, 0, 5)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.ScrollBarImageColor3 = config.accentColor
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerTab
    
    -- Create a title for the Player panel
    local playerTitle = Instance.new("TextLabel")
    playerTitle.Name = "PlayerTitle"
    playerTitle.Size = UDim2.new(1, -20, 0, 30)
    playerTitle.Position = UDim2.new(0, 10, 0, 10)
    playerTitle.BackgroundTransparency = 1
    playerTitle.Font = Enum.Font.GothamBold
    playerTitle.Text = "Player Information"
    playerTitle.TextColor3 = config.accentColor
    playerTitle.TextSize = config.fontSize + 2
    playerTitle.TextXAlignment = Enum.TextXAlignment.Left
    playerTitle.Parent = playerScroll
    
    -- Create player list container
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Name = "PlayerListFrame"
    playerListFrame.Size = UDim2.new(1, -20, 0, 0) -- Height will be set dynamically
    playerListFrame.Position = UDim2.new(0, 10, 0, 50)
    playerListFrame.BackgroundTransparency = 1
    playerListFrame.BorderSizePixel = 0
    playerListFrame.Parent = playerScroll
    
    -- Function to update the player list
    local function updatePlayerList()
        -- Clear existing player entries
        for _, child in pairs(playerListFrame:GetChildren()) do
            child:Destroy()
        end
        
        local yOffset = 0
        
        -- Add player entries
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local playerEntry = Instance.new("Frame")
                playerEntry.Name = player.Name .. "Entry"
                playerEntry.Size = UDim2.new(1, 0, 0, 60)
                playerEntry.Position = UDim2.new(0, 0, 0, yOffset)
                playerEntry.BackgroundColor3 = config.secondaryColor
                playerEntry.BorderSizePixel = 0
                playerEntry.Parent = playerListFrame
                
                local playerEntryCorner = Instance.new("UICorner")
                playerEntryCorner.CornerRadius = config.cornerRadius
                playerEntryCorner.Parent = playerEntry
                
                local playerName = Instance.new("TextLabel")
                playerName.Name = "PlayerName"
                playerName.Size = UDim2.new(1, -20, 0, 25)
                playerName.Position = UDim2.new(0, 10, 0, 5)
                playerName.BackgroundTransparency = 1
                playerName.Font = Enum.Font.GothamBold
                playerName.Text = player.Name
                playerName.TextColor3 = config.textColor
                playerName.TextSize = config.fontSize
                playerName.TextXAlignment = Enum.TextXAlignment.Left
                playerName.Parent = playerEntry
                
                local playerInfo = Instance.new("TextLabel")
                playerInfo.Name = "PlayerInfo"
                playerInfo.Size = UDim2.new(1, -20, 0, 20)
                playerInfo.Position = UDim2.new(0, 10, 0, 30)
                playerInfo.BackgroundTransparency = 1
                playerInfo.Font = Enum.Font.Gotham
                playerInfo.Text = "Loading info..."
                playerInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
                playerInfo.TextSize = config.fontSize - 2
                playerInfo.TextXAlignment = Enum.TextXAlignment.Left
                playerInfo.Parent = playerEntry
                
                yOffset = yOffset + 70
            end
        end
        
        playerListFrame.Size = UDim2.new(1, -20, 0, yOffset)
        playerScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset + 60)
    end
    
    -- Initial update
    updatePlayerList()
    
    -- Update player list when players join or leave
    Players.PlayerAdded:Connect(updatePlayerList)
    Players.PlayerRemoving:Connect(updatePlayerList)
    
    -- Update player info periodically
    RunService.Heartbeat:Connect(function()
        for _, playerEntry in pairs(playerListFrame:GetChildren()) do
            if playerEntry:IsA("Frame") then
                local playerName = playerEntry.Name:gsub("Entry$", "")
                local player = Players:FindFirstChild(playerName)
                
                if player then
                    local character = player.Character
                    local humanoid = character and character:FindFirstChild("Humanoid")
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and rootPart then
                        local health = humanoid.Health
                        local maxHealth = humanoid.MaxHealth
                        local distance = math.floor((rootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude)
                        
                        local infoText = "Health: " .. math.floor(health) .. "/" .. math.floor(maxHealth) .. " | Distance: " .. distance .. " studs"
                        playerEntry.PlayerInfo.Text = infoText
                    else
                        playerEntry.PlayerInfo.Text = "Character not loaded"
                    end
                end
            end
        end
    end)
    
    -- Connect events
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    minimizeButton.MouseButton1Click:Connect(function()
        if mainFrame.Size.Y.Offset > 60 then
            -- Minimize
            local tween = TweenService:Create(mainFrame, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 400, 0, 30)}
            )
            tween:Play()
            tabContentArea.Visible = false
            tabBar.Visible = false
        else
            -- Restore
            local tween = TweenService:Create(mainFrame, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 400, 0, 500)}
            )
            tween:Play()
            tabContentArea.Visible = true
            tabBar.Visible = true
        end
    end)
    
    -- Tab switching functionality
    for i, button in ipairs(tabButtons) do
        button.MouseButton1Click:Connect(function()
            -- Hide all content
            for j, content in ipairs(tabContent) do
                content.Visible = false
                tabButtons[j].BackgroundColor3 = config.secondaryColor
            end
            
            -- Show selected tab
            tabContent[i].Visible = true
            button.BackgroundColor3 = config.accentColor
        end)
    end
    
    -- Toggle events
    espToggleButton.MouseButton1Click:Connect(function()
        if settings.espEnabled then
            settings.espEnabled = false
            espToggleButton.BackgroundColor3 = config.toggleOffColor
            espToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
            ESP:ToggleESP(false)
        else
            settings.espEnabled = true
            espToggleButton.BackgroundColor3 = config.toggleOnColor
            espToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
            ESP:ToggleESP(true)
        end
    end)
    
    boxEspToggleButton.MouseButton1Click:Connect(function()
        if settings.boxEsp then
            settings.boxEsp = false
            boxEspToggleButton.BackgroundColor3 = config.toggleOffColor
            boxEspToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
            ESP:ToggleBoxESP(false)
        else
            settings.boxEsp = true
            boxEspToggleButton.BackgroundColor3 = config.toggleOnColor
            boxEspToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
            ESP:ToggleBoxESP(true)
        end
    end)
    
    nameEspToggleButton.MouseButton1Click:Connect(function()
        if settings.nameEsp then
            settings.nameEsp = false
            nameEspToggleButton.BackgroundColor3 = config.toggleOffColor
            nameEspToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
            ESP:ToggleNameESP(false)
        else
            settings.nameEsp = true
            nameEspToggleButton.BackgroundColor3 = config.toggleOnColor
            nameEspToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
            ESP:ToggleNameESP(true)
        end
    end)
    
    healthEspToggleButton.MouseButton1Click:Connect(function()
        if settings.healthEsp then
            settings.healthEsp = false
            healthEspToggleButton.BackgroundColor3 = config.toggleOffColor
            healthEspToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
            ESP:ToggleHealthESP(false)
        else
            settings.healthEsp = true
            healthEspToggleButton.BackgroundColor3 = config.toggleOnColor
            healthEspToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
            ESP:ToggleHealthESP(true)
        end
    end)
    
    chamsToggleButton.MouseButton1Click:Connect(function()
        if settings.chamsEnabled then
            settings.chamsEnabled = false
            chamsToggleButton.BackgroundColor3 = config.toggleOffColor
            chamsToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
            ESP:ToggleChams(false)
        else
            settings.chamsEnabled = true
            chamsToggleButton.BackgroundColor3 = config.toggleOnColor
            chamsToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
            ESP:ToggleChams(true)
        end
    end)
    
    highlightEspToggleButton.MouseButton1Click:Connect(function()
        if settings.highlightEnabled then
            settings.highlightEnabled = false
            highlightEspToggleButton.BackgroundColor3 = config.toggleOffColor
            highlightEspToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
            ESP:ToggleHighlightESP(false)
        else
            settings.highlightEnabled = true
            highlightEspToggleButton.BackgroundColor3 = config.toggleOnColor
            highlightEspToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
            ESP:ToggleHighlightESP(true)
        end
    end)
    
    aimbotToggleButton.MouseButton1Click:Connect(function()
        if settings.aimbotEnabled then
            settings.aimbotEnabled = false
            aimbotToggleButton.BackgroundColor3 = config.toggleOffColor
            aimbotToggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
        else
            settings.aimbotEnabled = true
            aimbotToggleButton.BackgroundColor3 = config.toggleOnColor
            aimbotToggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
        end
    end)
    
    -- Aimbot Key Button Event
    local keyChanging = false
    aimbotKeyButton.MouseButton1Click:Connect(function()
        if keyChanging then return end
        
        keyChanging = true
        aimbotKeyButton.Text = "Press a key..."
        
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                settings.aimbotKey = input.KeyCode
                aimbotKeyButton.Text = input.KeyCode.Name
                keyChanging = false
                connection:Disconnect()
            end
        end)
    end)
    
    -- Smoothness Slider Events
    local isDraggingSmooth = false
    
    smoothnessKnob.MouseButton1Down:Connect(function()
        isDraggingSmooth = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSmooth = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSmooth and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = smoothnessSlider.AbsolutePosition
            local sliderSize = smoothnessSlider.AbsoluteSize
            
            local relativeX = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            smoothnessKnob.Position = UDim2.new(relativeX, -7.5, 0.5, -7.5)
            
            settings.smoothness = relativeX
            smoothnessLabel.Text = "Smoothness: " .. tostring(settings.smoothness)
        end
    end)
    
    -- FOV Slider Events
    local isDraggingFOV = false
    
    fovKnob.MouseButton1Down:Connect(function()
        isDraggingFOV = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingFOV = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingFOV and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = fovSlider.AbsolutePosition
            local sliderSize = fovSlider.AbsoluteSize
            
            local relativeX = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            fovKnob.Position = UDim2.new(relativeX, -7.5, 0.5, -7.5)
            
            settings.fov = math.floor(relativeX * 200)
            fovLabel.Text = "FOV: " .. tostring(settings.fov)
        end
    end)
    
    -- Initialize ESP module after UI is created
    ESP:Init()
    
    -- Sync initial settings with ESP module
    ESP.Settings.BoxColor = config.accentColor
    ESP.Settings.NameColor = config.textColor
    ESP.Settings.HealthColor = Color3.fromRGB(0, 255, 0)
    ESP.Settings.ChamsColor = config.accentColor
    ESP.Settings.ChamsTransparency = 0.5
    ESP.Settings.TextSize = config.fontSize
    
    -- Update ESP settings based on UI settings
    ESP:ToggleESP(settings.espEnabled)
    ESP:ToggleBoxESP(settings.boxEsp)
    ESP:ToggleNameESP(settings.nameEsp)
    ESP:ToggleHealthESP(settings.healthEsp)
    ESP:ToggleChams(settings.chamsEnabled)
    ESP:ToggleHighlightESP(settings.highlightEnabled)
    
    return screenGui
end

-- Highlight ESP functionality
local highlightInstances = {}

local function applyHighlight(player)
    -- Skip local player if team check is enabled
    if settings.teamCheck and player == localPlayer then
        return
    end
    
    local function onCharacterAdded(character)
        -- Remove existing highlight if it exists
        if highlightInstances[player.Name] then
            pcall(function() highlightInstances[player.Name]:Destroy() end)
        end
        
        -- Create a new Highlight instance and set properties
        local highlight = Instance.new("Highlight")
        highlight.Archivable = true
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Ensures highlight is always visible
        highlight.Enabled = settings.highlightEnabled
        highlight.FillColor = settings.highlightFillColor
        highlight.OutlineColor = settings.highlightOutlineColor
        highlight.FillTransparency = settings.highlightFillTransparency
        highlight.OutlineTransparency = settings.highlightOutlineTransparency
        highlight.Parent = character
        
        highlightInstances[player.Name] = highlight
    end
    
    -- If the player's character already exists, apply the highlight
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    -- Connect to CharacterAdded to ensure highlight is added when character respawns
    player.CharacterAdded:Connect(onCharacterAdded)
end

local function toggleHighlightESP(enabled)
    settings.highlightEnabled = enabled
    
    -- Update all existing highlights
    for playerName, highlight in pairs(highlightInstances) do
        pcall(function() highlight.Enabled = enabled end)
    end
    
    -- If enabled, make sure all players have highlights
    if enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer or not settings.teamCheck then
                applyHighlight(player)
            end
        end
    end
end

-- Listen for new players joining
Players.PlayerAdded:Connect(function(player)
    if settings.highlightEnabled then
        applyHighlight(player)
    end
end)

-- Listen for players leaving
Players.PlayerRemoving:Connect(function(player)
    if highlightInstances[player.Name] then
        pcall(function() highlightInstances[player.Name]:Destroy() end)
        highlightInstances[player.Name] = nil
    end
end)

-- Toggle UI visibility with a keybind
local uiVisible = false
local playerPanel = nil

toggleUI = function()
    if uiVisible and playerPanel then
        playerPanel:Destroy()
        playerPanel = nil
        uiVisible = false
    else
        playerPanel = createUI()
        uiVisible = true
    end
end

-- Main execution
local function main()
    -- Initialize
    print("Player Panel UI initialized")
    
    -- Setup PlayerGui reference
    if localPlayer then
        if localPlayer:FindFirstChild("PlayerGui") then
            PlayerGui = localPlayer.PlayerGui
        else
            PlayerGui = localPlayer:WaitForChild("PlayerGui")
        end
    end
    
    -- Connect keybind (Right Shift)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            toggleUI()
        end
    end)
    
    -- Initialize UI
    toggleUI()
end

-- Error handling wrapper
local success, errorMsg = pcall(main)
if not success then
    warn("Player Panel UI Error: " .. tostring(errorMsg))
    
    -- Try alternative method for executors
    if not PlayerGui then
        -- Create a notification to show the error
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "ErrorNotification"
        
        -- Try to use protected GUI methods with a defensive approach
        local function tryParentErrorGui()
            local env = getfenv(1)
            
            -- Try Synapse X
            if pcall(function() return env["syn"] and env["syn"]["protect_gui"] end) then
                local protectGui = env["syn"]["protect_gui"]
                protectGui(screenGui)
                screenGui.Parent = game:GetService("CoreGui")
                return true
            end
            
            -- Try other protect_gui implementations
            if pcall(function() return env["protect_gui"] end) then
                local protectGui = env["protect_gui"]
                protectGui(screenGui)
                screenGui.Parent = game:GetService("CoreGui")
                return true
            end
            
            -- Try gethui
            if pcall(function() return env["gethui"] end) then
                local getHui = env["gethui"]
                screenGui.Parent = getHui()
                return true
            end
            
            -- Last resort
            screenGui.Parent = game:GetService("CoreGui")
            return true
        end
        
        pcall(tryParentErrorGui)
        
        -- Create error notification UI
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 100)
        frame.Position = UDim2.new(0.5, -150, 0.5, -50)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = frame
        
        local errorText = Instance.new("TextLabel")
        errorText.Size = UDim2.new(1, -20, 1, -20)
        errorText.Position = UDim2.new(0, 10, 0, 10)
        errorText.BackgroundTransparency = 1
        errorText.Font = Enum.Font.Gotham
        errorText.TextColor3 = Color3.fromRGB(255, 100, 100)
        errorText.TextSize = 14
        errorText.Text = "Error: " .. tostring(errorMsg)
        errorText.TextWrapped = true
        errorText.Parent = frame
        
        -- Auto-close after 5 seconds
        task.delay(5, function()
            screenGui:Destroy()
        end)
    end
end
