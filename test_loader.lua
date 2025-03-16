-- Simple test loader
print("Prism Analytics Test Loader")
print("If you see this message in your console, GitHub loading is working!")

-- Create a simple notification
local function createNotification(message)
    -- Create GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TestNotification"
    
    -- Try to parent to CoreGui
    pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    
    -- If failed, try PlayerGui
    if not screenGui.Parent then
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Create frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 100)
    frame.Position = UDim2.new(0.5, -150, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Create corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = frame
    
    -- Create text
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, -20)
    text.Position = UDim2.new(0, 10, 0, 10)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.Gotham
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextSize = 14
    text.Text = message
    text.TextWrapped = true
    text.Parent = frame
    
    -- Auto-destroy after 5 seconds
    task.delay(5, function()
        screenGui:Destroy()
    end)
    
    return screenGui
end

-- Show notification
createNotification("Prism Analytics Test Loader\nIf you see this message, GitHub loading is working!")

return true
