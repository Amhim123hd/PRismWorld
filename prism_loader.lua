--[[
    Prism Analytics Loader
    
    This script loads the Prism Analytics GUI with ESP features.
    Simply execute this script to load the entire system.
]]

-- GitHub repository information
local githubUser = "Amhim123hd"
local repoName = "PRismWorld"
local branch = "main"

-- Construct the base URL
local baseUrl = "https://raw.githubusercontent.com/" .. githubUser .. "/" .. repoName .. "/" .. branch .. "/"

-- Simple notification function that works with any executor
local function notify(title, text, duration)
    duration = duration or 5
    
    -- Create GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PrismNotification"
    
    -- Try to parent to CoreGui
    pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    
    -- If failed, try PlayerGui
    if not screenGui.Parent then
        pcall(function()
            screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    
    -- Create frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(0.5, -150, 0.8, -40)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 40)
    messageLabel.Position = UDim2.new(0, 10, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.Gotham
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
            screenGui:Destroy()
        end)
    end)
    
    return screenGui
end

-- Main loading function with error handling
local function main()
    notify("Prism Analytics", "Loading Prism Analytics...", 3)
    
    -- First, try loading the UI directly (which will load ESP internally)
    local uiSuccess, uiError = pcall(function()
        loadstring(game:HttpGet(baseUrl .. "ui.lua"))()
    end)
    
    if uiSuccess then
        notify("Prism Analytics", "Successfully loaded Prism Analytics!", 3)
        return
    else
        notify("Prism Analytics", "Failed to load UI directly: " .. tostring(uiError), 3)
        warn("Failed to load UI directly: " .. tostring(uiError))
    end
    
    -- If direct UI loading failed, try loading ESP first then UI
    notify("Prism Analytics", "Trying alternative loading method...", 2)
    
    -- Load ESP module
    local espSuccess, espModule = pcall(function()
        return loadstring(game:HttpGet(baseUrl .. "prism_esp.lua"))()
    end)
    
    if not espSuccess then
        notify("Prism Analytics", "Failed to load ESP module: " .. tostring(espModule), 5)
        warn("Failed to load ESP module: " .. tostring(espModule))
    else
        notify("Prism Analytics", "ESP module loaded successfully!", 2)
        
        -- Try loading UI again
        local uiRetrySuccess, uiRetryError = pcall(function()
            loadstring(game:HttpGet(baseUrl .. "ui.lua"))()
        end)
        
        if uiRetrySuccess then
            notify("Prism Analytics", "Successfully loaded Prism Analytics!", 3)
            return
        else
            notify("Prism Analytics", "Failed to load UI after ESP: " .. tostring(uiRetryError), 3)
            warn("Failed to load UI after ESP: " .. tostring(uiRetryError))
        end
    end
    
    -- If all else fails, try the simple version as fallback
    notify("Prism Analytics", "Trying to load simple version instead...", 3)
    
    local simpleSuccess, simpleError = pcall(function()
        loadstring(game:HttpGet(baseUrl .. "prism_simple.lua"))()
    end)
    
    if not simpleSuccess then
        notify("Prism Analytics", "Failed to load simple version: " .. tostring(simpleError), 5)
        warn("Failed to load simple version: " .. tostring(simpleError))
        return
    else
        notify("Prism Analytics", "Simple version loaded successfully!", 3)
    end
end

-- Run the loader with error handling
local success, error = pcall(main)
if not success then
    warn("Prism Analytics Error: " .. tostring(error))
    notify("Prism Analytics Error", tostring(error), 10)
end
