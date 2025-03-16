--[[
    Prism Analytics Loader
    
    This script loads the Prism Analytics GUI with ESP features.
    Simply execute this script to load the entire system.
]]

-- Local variables
local success, errorMsg

-- Replace these with your actual GitHub username and repository name
local githubUser = "Amhim123hd"
local repoName = "PRismWorld"
local branch = "main"

-- Construct the base URL
local baseUrl = "https://raw.githubusercontent.com/" .. githubUser .. "/" .. repoName .. "/" .. branch .. "/"

-- Notification function
local function notify(title, text, duration)
    -- Use getfenv to check for executor functions without directly referencing them
    local env = getfenv(1)
    local hasSynToast = pcall(function() return env["syn"] and env["syn"]["toast_notification"] end)
    
    if hasSynToast then
        local synToast = env["syn"]["toast_notification"]
        synToast({
            Type = "normal",
            Title = title,
            Content = text,
            Duration = duration or 5
        })
    else
        -- Fallback notification
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PrismNotification"
        
        -- Try to use protected GUI methods
        pcall(function()
            local env = getfenv(1)
            if pcall(function() return env["syn"] and env["syn"]["protect_gui"] end) then
                local protectGui = env["syn"]["protect_gui"]
                protectGui(screenGui)
            end
        end)
        
        -- Parent the GUI
        screenGui.Parent = game:GetService("CoreGui")
        
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
        task.delay(duration or 5, function()
            local fadeOut = game:GetService("TweenService"):Create(frame, tweenInfo, {Position = UDim2.new(0.5, -150, 1, 20)})
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                screenGui:Destroy()
            end)
        end)
    end
end

-- Load a module from URL
local function loadModule(name)
    notify("Prism Analytics", "Loading " .. name .. "...", 2)
    
    local url = baseUrl .. name .. ".lua"
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        notify("Prism Analytics", "Failed to load " .. name .. ": " .. tostring(content), 5)
        return nil
    end
    
    local loadSuccess, result = pcall(loadstring, content)
    if not loadSuccess then
        notify("Prism Analytics", "Failed to parse " .. name .. ": " .. tostring(result), 5)
        return nil
    end
    
    local runSuccess, module = pcall(result)
    if not runSuccess then
        notify("Prism Analytics", "Failed to run " .. name .. ": " .. tostring(module), 5)
        return nil
    end
    
    return module
end

-- Main loading function
local function main()
    notify("Prism Analytics", "Loading Prism Analytics...", 3)
    
    -- Load ESP module first
    local espModule = loadModule("prism_esp")
    if not espModule then
        notify("Prism Analytics", "Failed to load ESP module. Trying to continue...", 3)
    end
    
    -- Load UI module
    local uiModule = loadModule("ui")
    if not uiModule then
        notify("Prism Analytics", "Failed to load UI module. Aborting.", 5)
        return
    end
    
    -- Initialize UI
    local ui = uiModule()
    
    notify("Prism Analytics", "Successfully loaded Prism Analytics!", 3)
end

-- Run the loader
main()
