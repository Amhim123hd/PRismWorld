--[[
    Prism Analytics UI Module
    
    This module handles the UI for Prism Analytics using Fluent UI library.
    Updated with enhanced features and improved design.
]]

-- Initialize module
local module = {}

-- UI state variables
local uiVisible = false
local playerPanel = nil

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
        print("Loaded ESP module from local script")
    end)
end

-- Player variables
local localPlayer = Players.LocalPlayer
local PlayerGui

-- Settings
local settings = {
    -- ESP Settings
    highlightEnabled = false,
    highlightColor = Color3.fromRGB(255, 0, 0),
    highlightTransparency = 0.5,
    teamCheck = true,
    showDistance = true,
    showHealth = true,
    maxDistance = 1000,
    refreshRate = 10,
    
    -- Aimbot Settings
    aimbotEnabled = false,
    aimbotKey = Enum.KeyCode.MouseButton2,
    aimbotSmoothness = 0.5,
    aimbotFOV = 100,
    aimbotTeamCheck = true,
    
    -- Performance Settings
    optimizePerformance = true,
    renderDistance = 500,
    
    -- Theme Settings
    theme = "Dark",
    accentColor = Color3.fromRGB(0, 170, 255)
}

-- Highlight instances
local highlightInstances = {}

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Advanced ESP functionality
local function loadAdvancedESP()
    local success, error = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Exunys-ESP/main/ESP.lua"))()
    end)
    
    if success then
        print("Advanced ESP loaded successfully")
        Fluent:Notify({
            Title = "Prism Analytics",
            Content = "Advanced ESP loaded successfully",
            Duration = 3
        })
    else
        warn("Failed to load Advanced ESP: " .. tostring(error))
        Fluent:Notify({
            Title = "Error",
            Content = "Failed to load Advanced ESP",
            SubContent = tostring(error),
            Duration = 5
        })
    end
end

-- Highlight ESP functionality
local function applyHighlight(player)
    if player == localPlayer and settings.teamCheck then return end
    
    local function onCharacterAdded(character)
        if highlightInstances[player.Name] then
            pcall(function() highlightInstances[player.Name]:Destroy() end)
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "PrismHighlight"
        highlight.FillColor = settings.highlightColor
        highlight.FillTransparency = settings.highlightTransparency
        highlight.OutlineColor = settings.highlightColor
        highlight.OutlineTransparency = 0.4
        highlight.Enabled = settings.highlightEnabled
        highlight.Adornee = character
        highlight.Parent = character
        
        highlightInstances[player.Name] = highlight
    end
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
end

local function toggleHighlightESP(enabled)
    settings.highlightEnabled = enabled
    
    -- Update all existing highlights
    for playerName, highlight in pairs(highlightInstances) do
        pcall(function() highlight.Enabled = enabled end)
    end
    
    -- Apply to all current players
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            applyHighlight(player)
        end
    end
end

-- Apply highlight to existing players
for _, player in ipairs(Players:GetPlayers()) do
    applyHighlight(player)
end

-- Connect player added/removed events
Players.PlayerAdded:Connect(function(player)
    applyHighlight(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if highlightInstances[player.Name] then
        pcall(function() highlightInstances[player.Name]:Destroy() end)
        highlightInstances[player.Name] = nil
    end
end)

-- Get player distance
local function getPlayerDistance(player)
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not localPlayer or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return "N/A"
    end
    
    local distance = (player.Character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
    return math.floor(distance + 0.5) -- Round to nearest integer
end

-- Get player health
local function getPlayerHealth(player)
    if not player or not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return "N/A"
    end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    return math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
end

-- Create UI
module.createUI = function()
    -- Create Fluent Window
    local Window = Fluent:CreateWindow({
        Title = "Prism Analytics",
        SubTitle = "by Prism Team",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = settings.theme,
        MinimizeKey = Enum.KeyCode.RightShift
    })

    -- Create Tabs
    local Tabs = {
        Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
        Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "target" }),
        Players = Window:AddTab({ Title = "Players", Icon = "users" }),
        Performance = Window:AddTab({ Title = "Performance", Icon = "zap" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    -- Options reference
    local Options = Fluent.Options

    -- Visuals Tab
    Tabs.Visuals:AddParagraph({
        Title = "ESP Options",
        Content = "Configure player highlighting and ESP features"
    })

    -- Highlight ESP Toggle
    local HighlightToggle = Tabs.Visuals:AddToggle("HighlightESP", {
        Title = "Highlight Players",
        Description = "Highlight players with a colored overlay",
        Default = settings.highlightEnabled
    })

    HighlightToggle:OnChanged(function()
        toggleHighlightESP(Options.HighlightESP.Value)
    end)

    -- Highlight Color Picker
    local HighlightColor = Tabs.Visuals:AddColorpicker("HighlightColor", {
        Title = "Highlight Color",
        Description = "Change the color of the player highlights",
        Default = settings.highlightColor
    })

    HighlightColor:OnChanged(function()
        settings.highlightColor = HighlightColor.Value
        -- Update existing highlights
        for _, highlight in pairs(highlightInstances) do
            pcall(function()
                highlight.FillColor = settings.highlightColor
                highlight.OutlineColor = settings.highlightColor
            end)
        end
    end)

    -- Highlight Transparency Slider
    local TransparencySlider = Tabs.Visuals:AddSlider("HighlightTransparency", {
        Title = "Highlight Transparency",
        Description = "Adjust the transparency of the highlights",
        Default = settings.highlightTransparency * 100,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            settings.highlightTransparency = Value / 100
            -- Update existing highlights
            for _, highlight in pairs(highlightInstances) do
                pcall(function()
                    highlight.FillTransparency = settings.highlightTransparency
                end)
            end
        end
    })

    -- Team Check Toggle
    local TeamCheckToggle = Tabs.Visuals:AddToggle("TeamCheck", {
        Title = "Team Check",
        Description = "Don't highlight players on your team",
        Default = settings.teamCheck
    })

    TeamCheckToggle:OnChanged(function()
        settings.teamCheck = Options.TeamCheck.Value
        
        -- Re-apply highlights with new team check setting
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer or not settings.teamCheck then
                applyHighlight(player)
            elseif highlightInstances[player.Name] then
                pcall(function() highlightInstances[player.Name]:Destroy() end)
                highlightInstances[player.Name] = nil
            end
        end
    end)
    
    -- Show Distance Toggle
    local ShowDistanceToggle = Tabs.Visuals:AddToggle("ShowDistance", {
        Title = "Show Distance",
        Description = "Show distance to players in ESP",
        Default = settings.showDistance
    })
    
    ShowDistanceToggle:OnChanged(function()
        settings.showDistance = Options.ShowDistance.Value
    end)
    
    -- Show Health Toggle
    local ShowHealthToggle = Tabs.Visuals:AddToggle("ShowHealth", {
        Title = "Show Health",
        Description = "Show player health in ESP",
        Default = settings.showHealth
    })
    
    ShowHealthToggle:OnChanged(function()
        settings.showHealth = Options.ShowHealth.Value
    end)
    
    -- Max Distance Slider
    local MaxDistanceSlider = Tabs.Visuals:AddSlider("MaxDistance", {
        Title = "Max ESP Distance",
        Description = "Maximum distance to show ESP",
        Default = settings.maxDistance,
        Min = 100,
        Max = 5000,
        Rounding = 0
    })
    
    MaxDistanceSlider:OnChanged(function()
        settings.maxDistance = Options.MaxDistance.Value
    end)

    -- Advanced ESP Button
    Tabs.Visuals:AddButton({
        Title = "Load Advanced ESP",
        Description = "Load external ESP with additional features",
        Callback = function()
            loadAdvancedESP()
        end
    })

    -- Aimbot Tab
    Tabs.Aimbot:AddParagraph({
        Title = "Aimbot Settings",
        Description = "Configure aimbot functionality"
    })

    -- Aimbot Toggle
    local AimbotToggle = Tabs.Aimbot:AddToggle("AimbotEnabled", {
        Title = "Enable Aimbot",
        Description = "Toggle aimbot functionality",
        Default = settings.aimbotEnabled
    })
    
    AimbotToggle:OnChanged(function()
        settings.aimbotEnabled = Options.AimbotEnabled.Value
    end)

    -- Aimbot Keybind
    local AimbotKey = Tabs.Aimbot:AddKeybind("AimbotKey", {
        Title = "Aimbot Key",
        Description = "Key to activate aimbot",
        Mode = "Hold",
        Default = settings.aimbotKey,
        Callback = function(Value)
            settings.aimbotKey = Value
        end
    })

    -- Aimbot Smoothness
    local SmoothnessSlider = Tabs.Aimbot:AddSlider("AimbotSmoothness", {
        Title = "Aimbot Smoothness",
        Description = "Adjust how smoothly the aimbot moves",
        Default = settings.aimbotSmoothness,
        Min = 0,
        Max = 1,
        Rounding = 2
    })
    
    SmoothnessSlider:OnChanged(function()
        settings.aimbotSmoothness = Options.AimbotSmoothness.Value
    end)

    -- FOV Settings
    local FovSlider = Tabs.Aimbot:AddSlider("AimbotFOV", {
        Title = "Aimbot FOV",
        Description = "Field of view for aimbot targeting",
        Default = settings.aimbotFOV,
        Min = 10,
        Max = 500,
        Rounding = 0
    })
    
    FovSlider:OnChanged(function()
        settings.aimbotFOV = Options.AimbotFOV.Value
    end)
    
    -- Aimbot Team Check
    local AimbotTeamCheckToggle = Tabs.Aimbot:AddToggle("AimbotTeamCheck", {
        Title = "Team Check",
        Description = "Don't aim at players on your team",
        Default = settings.aimbotTeamCheck
    })
    
    AimbotTeamCheckToggle:OnChanged(function()
        settings.aimbotTeamCheck = Options.AimbotTeamCheck.Value
    end)
    
    -- Show FOV Circle
    local ShowFOVToggle = Tabs.Aimbot:AddToggle("ShowFOV", {
        Title = "Show FOV Circle",
        Description = "Display the FOV circle on screen",
        Default = false
    })

    -- Players Tab
    Tabs.Players:AddParagraph({
        Title = "Player List",
        Content = "View and interact with players in the game"
    })

    -- Create a section to display players
    local PlayerSection = Tabs.Players:AddSection("Players")
    
    -- Function to update player list
    local function updatePlayerList()
        -- Clear existing player entries
        PlayerSection:Clear()
        
        -- Add all players
        for _, player in ipairs(Players:GetPlayers()) do
            local playerName = player.Name
            local displayName = player.DisplayName
            local distance = getPlayerDistance(player)
            local health = getPlayerHealth(player)
            local teamColor = player.Team and player.TeamColor.Color or Color3.fromRGB(200, 200, 200)
            
            PlayerSection:AddButton({
                Title = displayName,
                Description = playerName .. (player == localPlayer and " (You)" or "") .. 
                              "\nDistance: " .. distance .. 
                              "\nHealth: " .. health,
                RightLabel = player.Team and player.Team.Name or "No Team",
                Callback = function()
                    -- Show player options in a dialog
                    Window:Dialog({
                        Title = "Player Options: " .. displayName,
                        Content = "Select an action for this player",
                        Buttons = {
                            {
                                Title = "Teleport To",
                                Callback = function()
                                    if player.Character and localPlayer.Character then
                                        localPlayer.Character:SetPrimaryPartCFrame(player.Character:GetPrimaryPartCFrame())
                                    end
                                end
                            },
                            {
                                Title = "Spectate",
                                Callback = function()
                                    -- Spectate logic would go here
                                    local camera = workspace.CurrentCamera
                                    if player.Character then
                                        camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
                                    end
                                end
                            },
                            {
                                Title = "Reset Camera",
                                Callback = function()
                                    local camera = workspace.CurrentCamera
                                    if localPlayer.Character then
                                        camera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
                                    end
                                end
                            },
                            {
                                Title = "Cancel",
                                Callback = function() end
                            }
                        }
                    })
                end
            })
        end
    end
    
    -- Initial player list update
    updatePlayerList()
    
    -- Update player list periodically
    RunService.Heartbeat:Connect(function()
        -- Only update every 5 seconds to avoid performance issues
        if tick() % 5 < 0.1 then
            updatePlayerList()
        end
    end)
    
    -- Performance Tab
    Tabs.Performance:AddParagraph({
        Title = "Performance Settings",
        Content = "Optimize performance for smoother gameplay"
    })
    
    -- Performance Optimization Toggle
    local OptimizeToggle = Tabs.Performance:AddToggle("OptimizePerformance", {
        Title = "Optimize Performance",
        Description = "Enable performance optimizations",
        Default = settings.optimizePerformance
    })
    
    OptimizeToggle:OnChanged(function()
        settings.optimizePerformance = Options.OptimizePerformance.Value
    end)
    
    -- Render Distance Slider
    local RenderDistanceSlider = Tabs.Performance:AddSlider("RenderDistance", {
        Title = "Render Distance",
        Description = "Maximum distance to render ESP elements",
        Default = settings.renderDistance,
        Min = 100,
        Max = 2000,
        Rounding = 0
    })
    
    RenderDistanceSlider:OnChanged(function()
        settings.renderDistance = Options.RenderDistance.Value
    end)
    
    -- Refresh Rate Slider
    local RefreshRateSlider = Tabs.Performance:AddSlider("RefreshRate", {
        Title = "ESP Refresh Rate",
        Description = "How often to update ESP (Hz)",
        Default = settings.refreshRate,
        Min = 1,
        Max = 60,
        Rounding = 0
    })
    
    RefreshRateSlider:OnChanged(function()
        settings.refreshRate = Options.RefreshRate.Value
    end)
    
    -- Performance Tips
    Tabs.Performance:AddParagraph({
        Title = "Performance Tips",
        Content = "• Lower the ESP Refresh Rate for better performance\n• Reduce Render Distance to improve FPS\n• Disable ESP features you don't need\n• Close other applications while playing"
    })

    -- Settings Tab
    Tabs.Settings:AddParagraph({
        Title = "Prism Analytics Settings",
        Content = "Configure general settings for Prism Analytics"
    })
    
    -- Theme Dropdown
    local ThemeDropdown = Tabs.Settings:AddDropdown("Theme", {
        Title = "UI Theme",
        Description = "Change the UI theme",
        Values = {"Dark", "Light", "Discord", "Aqua", "Rose"},
        Default = settings.theme,
        Multi = false
    })
    
    ThemeDropdown:OnChanged(function()
        settings.theme = Options.Theme.Value
        Fluent:ChangeTheme(settings.theme)
    end)
    
    -- Accent Color Picker
    local AccentColorPicker = Tabs.Settings:AddColorpicker("AccentColor", {
        Title = "Accent Color",
        Description = "Change the UI accent color",
        Default = settings.accentColor
    })
    
    AccentColorPicker:OnChanged(function()
        settings.accentColor = AccentColorPicker.Value
        Fluent:ChangeAccentColor(settings.accentColor)
    end)
    
    -- Add Interface and Save Manager sections
    InterfaceManager:SetFolder("PrismAnalytics")
    SaveManager:SetFolder("PrismAnalytics/configs")
    
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
    
    -- Credits Section
    local CreditsSection = Tabs.Settings:AddSection("Credits")
    
    Tabs.Settings:AddParagraph({
        Title = "Prism Analytics",
        Content = "Created by Prism Team\nUI Library: Fluent UI by dawid-scripts"
    })
    
    -- Select the first tab by default
    Window:SelectTab(1)
    
    -- Notification on load
    Fluent:Notify({
        Title = "Prism Analytics",
        Content = "UI has been loaded successfully",
        Duration = 3
    })
    
    return Window
end

-- Toggle UI visibility
module.toggleUI = function()
    if uiVisible and playerPanel then
        playerPanel:Destroy()
        playerPanel = nil
        uiVisible = false
    else
        playerPanel = module.createUI()
        uiVisible = true
    end
end

-- Main initialization function
module.init = function()
    -- Initialize
    print("Prism Analytics UI initialized")
    
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
            module.toggleUI()
        end
    end)
    
    -- Initialize UI
    module.toggleUI()
end

-- Error handling wrapper
local success, errorMsg = pcall(module.init)
if not success then
    warn("Prism Analytics UI Error: " .. tostring(errorMsg))
    
    -- Display error to user
    local function showErrorMessage(errorMsg)
        -- Create a simple error GUI
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PrismAnalyticsError"
        
        -- Try to parent to appropriate location
        local env = getfenv()
        local function tryParentErrorGui()
            -- Try Synapse X (using pcall to avoid undefined global errors)
            if pcall(function() return env["syn"] ~= nil and env["syn"]["protect_gui"] ~= nil end) then
                env["syn"]["protect_gui"](screenGui)
                screenGui.Parent = game:GetService("CoreGui")
                return true
            end
            
            -- Try other exploits (using pcall to avoid undefined global errors)
            if pcall(function() return env["protect_gui"] ~= nil end) then
                env["protect_gui"](screenGui)
                screenGui.Parent = game:GetService("CoreGui")
                return true
            end
            
            -- Try gethui (using pcall to avoid undefined global errors)
            if pcall(function() return env["gethui"] ~= nil end) then
                screenGui.Parent = env["gethui"]()
                return true
            end
            
            -- Default to PlayerGui
            if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
                screenGui.Parent = localPlayer.PlayerGui
                return true
            end
            
            return false
        end
        
        if not tryParentErrorGui() then
            warn("Could not parent error GUI")
            return
        end
        
        -- Create frame
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 100)
        frame.Position = UDim2.new(0.5, -150, 0.5, -50)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        -- Create error text
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
    
    showErrorMessage(errorMsg)
end

return module
