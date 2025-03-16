-- Prism ESP Module (Instance-based ESP)
local ESP = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Variables
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local espFolder = Instance.new("Folder")

-- Settings (will be updated from UI)
ESP.Settings = {
    Enabled = false,
    BoxEsp = false,
    NameEsp = false,
    HealthEsp = false,
    ChamsEnabled = false,
    HighlightEnabled = false,
    TeamCheck = false,
    MaxDistance = 1000,
    BoxColor = Color3.fromRGB(255, 0, 0),
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 0),
    ChamsColor = Color3.fromRGB(255, 0, 0),
    ChamsTransparency = 0.5,
    HighlightFillColor = Color3.fromRGB(255, 0, 4),
    HighlightOutlineColor = Color3.fromRGB(255, 255, 255),
    HighlightFillTransparency = 0.5,
    HighlightOutlineTransparency = 0,
    TextSize = 14
}

-- Initialize ESP containers
ESP.PlayerESP = {}
ESP.Connections = {}
ESP.HighlightInstances = {}

-- Utility Functions
local function createDrawing(type, properties)
    local drawing = Instance.new(type)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    drawing.Parent = espFolder
    return drawing
end

local function getPlayerTeamColor(player)
    if player.Team then
        return player.TeamColor.Color
    end
    return ESP.Settings.BoxColor
end

local function isPlayerAlive(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return character and humanoid and humanoid.Health > 0
end

local function shouldShowESP(player)
    if player == localPlayer then return false end
    if not ESP.Settings.Enabled then return false end
    
    if ESP.Settings.TeamCheck and player.Team == localPlayer.Team then
        return false
    end
    
    return true
end

-- Create ESP for a player
function ESP:CreatePlayerESP(player)
    if self.PlayerESP[player] then return end
    
    local espData = {
        BoxParts = {},
        NameLabel = nil,
        HealthBar = nil,
        HealthLabel = nil,
        Chams = nil,
        Connections = {}
    }
    
    -- Create Box ESP (4 lines forming a rectangle)
    for i = 1, 4 do
        local line = createDrawing("Frame", {
            BackgroundColor3 = ESP.Settings.BoxColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 1, 0, 1), -- Will be resized dynamically
            Visible = false,
            ZIndex = 2
        })
        espData.BoxParts[i] = line
    end
    
    -- Create Name ESP
    espData.NameLabel = createDrawing("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextColor3 = ESP.Settings.NameColor,
        TextSize = ESP.Settings.TextSize,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        Visible = false,
        ZIndex = 2
    })
    
    -- Create Health Bar Background
    espData.HealthBarBG = createDrawing("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Transparency = 0.5,
        Visible = false,
        ZIndex = 2
    })
    
    -- Create Health Bar Fill
    espData.HealthBar = createDrawing("Frame", {
        BackgroundColor3 = ESP.Settings.HealthColor,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 3
    })
    espData.HealthBar.Parent = espData.HealthBarBG
    
    -- Create Health Label
    espData.HealthLabel = createDrawing("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = ESP.Settings.TextSize - 2,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        Visible = false,
        ZIndex = 3
    })
    
    -- Create Chams (Highlight)
    espData.Chams = Instance.new("Highlight")
    espData.Chams.FillColor = ESP.Settings.ChamsColor
    espData.Chams.OutlineColor = Color3.new(1, 1, 1)
    espData.Chams.FillTransparency = ESP.Settings.ChamsTransparency
    espData.Chams.OutlineTransparency = 0.7
    espData.Chams.Enabled = false
    espData.Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    self.PlayerESP[player] = espData
end

-- Update ESP for a player
function ESP:UpdatePlayerESP(player)
    local espData = self.PlayerESP[player]
    if not espData then return end
    
    -- Check if ESP should be shown
    if not shouldShowESP(player) then
        self:HidePlayerESP(player)
        return
    end
    
    -- Get player character and check if alive
    local character = player.Character
    if not character or not isPlayerAlive(player) then
        self:HidePlayerESP(player)
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoidRootPart or not humanoid then
        self:HidePlayerESP(player)
        return
    end
    
    -- Check distance
    local distance = (humanoidRootPart.Position - camera.CFrame.Position).Magnitude
    if distance > ESP.Settings.MaxDistance then
        self:HidePlayerESP(player)
        return
    end
    
    -- Get character size and position
    local size = character:GetExtentsSize()
    local position = humanoidRootPart.Position
    
    -- Calculate 2D box corners from 3D position
    local topLeft = camera:WorldToViewportPoint(position + Vector3.new(-size.X/2, size.Y/2, 0))
    local topRight = camera:WorldToViewportPoint(position + Vector3.new(size.X/2, size.Y/2, 0))
    local bottomLeft = camera:WorldToViewportPoint(position + Vector3.new(-size.X/2, -size.Y/2, 0))
    local bottomRight = camera:WorldToViewportPoint(position + Vector3.new(size.X/2, -size.Y/2, 0))
    
    -- Check if player is on screen
    if not (topLeft.Z > 0 and topRight.Z > 0 and bottomLeft.Z > 0 and bottomRight.Z > 0) then
        self:HidePlayerESP(player)
        return
    end
    
    -- Convert 3D points to 2D screen points
    local boxWidth = math.abs(topRight.X - topLeft.X)
    local boxHeight = math.abs(topLeft.Y - bottomLeft.Y)
    
    -- Update Box ESP
    if ESP.Settings.BoxEsp then
        local boxColor = ESP.Settings.TeamCheck and getPlayerTeamColor(player) or ESP.Settings.BoxColor
        
        -- Top line
        espData.BoxParts[1].Position = UDim2.new(0, topLeft.X, 0, topLeft.Y)
        espData.BoxParts[1].Size = UDim2.new(0, boxWidth, 0, 1)
        espData.BoxParts[1].BackgroundColor3 = boxColor
        espData.BoxParts[1].Visible = true
        
        -- Right line
        espData.BoxParts[2].Position = UDim2.new(0, topRight.X, 0, topRight.Y)
        espData.BoxParts[2].Size = UDim2.new(0, 1, 0, boxHeight)
        espData.BoxParts[2].BackgroundColor3 = boxColor
        espData.BoxParts[2].Visible = true
        
        -- Bottom line
        espData.BoxParts[3].Position = UDim2.new(0, bottomLeft.X, 0, bottomLeft.Y)
        espData.BoxParts[3].Size = UDim2.new(0, boxWidth, 0, 1)
        espData.BoxParts[3].BackgroundColor3 = boxColor
        espData.BoxParts[3].Visible = true
        
        -- Left line
        espData.BoxParts[4].Position = UDim2.new(0, topLeft.X, 0, topLeft.Y)
        espData.BoxParts[4].Size = UDim2.new(0, 1, 0, boxHeight)
        espData.BoxParts[4].BackgroundColor3 = boxColor
        espData.BoxParts[4].Visible = true
    else
        for _, part in pairs(espData.BoxParts) do
            part.Visible = false
        end
    end
    
    -- Update Name ESP
    if ESP.Settings.NameEsp then
        espData.NameLabel.Text = player.Name
        espData.NameLabel.Position = UDim2.new(0, (topLeft.X + topRight.X) / 2, 0, topLeft.Y - 20)
        espData.NameLabel.TextColor3 = ESP.Settings.NameColor
        espData.NameLabel.Visible = true
    else
        espData.NameLabel.Visible = false
    end
    
    -- Update Health ESP
    if ESP.Settings.HealthEsp and humanoid then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = health / maxHealth
        
        -- Position health bar to the left of the box
        local barWidth = 4
        local barHeight = boxHeight
        local barPosX = topLeft.X - barWidth - 2
        local barPosY = topLeft.Y
        
        -- Update health bar background
        espData.HealthBarBG.Position = UDim2.new(0, barPosX, 0, barPosY)
        espData.HealthBarBG.Size = UDim2.new(0, barWidth, 0, barHeight)
        espData.HealthBarBG.Visible = true
        
        -- Update health bar fill
        espData.HealthBar.Size = UDim2.new(0, barWidth, 0, barHeight * healthPercent)
        espData.HealthBar.Position = UDim2.new(0, 0, 1, -barHeight * healthPercent)
        espData.HealthBar.BackgroundColor3 = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        espData.HealthBar.Visible = true
        
        -- Update health text
        espData.HealthLabel.Text = math.floor(health) .. "/" .. math.floor(maxHealth)
        espData.HealthLabel.Position = UDim2.new(0, barPosX - 20, 0, barPosY + barHeight / 2 - 8)
        espData.HealthLabel.Visible = true
    else
        espData.HealthBarBG.Visible = false
        espData.HealthBar.Visible = false
        espData.HealthLabel.Visible = false
    end
    
    -- Update Chams
    if ESP.Settings.ChamsEnabled then
        espData.Chams.Parent = character
        espData.Chams.FillColor = ESP.Settings.ChamsColor
        espData.Chams.FillTransparency = ESP.Settings.ChamsTransparency
        espData.Chams.Enabled = true
    else
        espData.Chams.Enabled = false
        espData.Chams.Parent = nil
    end
    
    -- Update Highlight
    if ESP.Settings.HighlightEnabled then
        if not self.HighlightInstances[player.Name] then
            self:ApplyHighlight(player)
        end
    else
        if self.HighlightInstances[player.Name] then
            self.HighlightInstances[player.Name]:Destroy()
            self.HighlightInstances[player.Name] = nil
        end
    end
end

-- Hide ESP for a player
function ESP:HidePlayerESP(player)
    local espData = self.PlayerESP[player]
    if not espData then return end
    
    for _, part in pairs(espData.BoxParts) do
        part.Visible = false
    end
    
    espData.NameLabel.Visible = false
    espData.HealthBarBG.Visible = false
    espData.HealthBar.Visible = false
    espData.HealthLabel.Visible = false
    
    if espData.Chams then
        espData.Chams.Enabled = false
        espData.Chams.Parent = nil
    end
end

-- Remove ESP for a player
function ESP:RemovePlayerESP(player)
    local espData = self.PlayerESP[player]
    if not espData then return end
    
    for _, part in pairs(espData.BoxParts) do
        part:Destroy()
    end
    
    espData.NameLabel:Destroy()
    espData.HealthBarBG:Destroy()
    espData.HealthBar:Destroy()
    espData.HealthLabel:Destroy()
    
    if espData.Chams then
        espData.Chams:Destroy()
    end
    
    for _, connection in pairs(espData.Connections) do
        connection:Disconnect()
    end
    
    self.PlayerESP[player] = nil
    
    -- Clean up highlight
    if self.HighlightInstances[player.Name] then
        self.HighlightInstances[player.Name]:Destroy()
        self.HighlightInstances[player.Name] = nil
    end
end

-- Apply highlight to a player
function ESP:ApplyHighlight(player)
    -- Skip local player if team check is enabled
    if self.Settings.TeamCheck and player == localPlayer then
        return
    end
    
    local function onCharacterAdded(character)
        -- Remove existing highlight if it exists
        if self.HighlightInstances[player.Name] then
            self.HighlightInstances[player.Name]:Destroy()
        end
        
        -- Create a new Highlight instance and set properties
        local highlight = Instance.new("Highlight")
        highlight.Archivable = true
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Ensures highlight is always visible
        highlight.Enabled = self.Settings.HighlightEnabled
        highlight.FillColor = self.Settings.HighlightFillColor
        highlight.OutlineColor = self.Settings.HighlightOutlineColor
        highlight.FillTransparency = self.Settings.HighlightFillTransparency
        highlight.OutlineTransparency = self.Settings.HighlightOutlineTransparency
        highlight.Parent = character
        
        self.HighlightInstances[player.Name] = highlight
    end
    
    -- If the player's character already exists, apply the highlight
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    -- Connect to CharacterAdded to ensure highlight is added when character respawns
    if not self.Connections[player.Name .. "_CharacterAdded"] then
        self.Connections[player.Name .. "_CharacterAdded"] = player.CharacterAdded:Connect(onCharacterAdded)
    end
end

-- Toggle highlight ESP
function ESP:ToggleHighlightESP(enabled)
    self.Settings.HighlightEnabled = enabled
    
    -- Update all existing highlights
    for playerName, highlight in pairs(self.HighlightInstances) do
        pcall(function() highlight.Enabled = enabled end)
    end
    
    -- If enabled, make sure all players have highlights
    if enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer or not self.Settings.TeamCheck then
                self:ApplyHighlight(player)
            end
        end
    end
end

-- Initialize the ESP system
function ESP:Init()
    -- Create ESP folder
    espFolder.Name = "PrismESP"
    
    -- Try to parent the folder safely
    local function tryParentFolder()
        -- We use getfenv to check for executor functions without directly referencing them
        -- This avoids lint warnings while still allowing the code to work with different executors
        local env = getfenv(1)
        
        -- Try Synapse X
        if pcall(function() return env["syn"] and env["syn"]["protect_gui"] end) then
            local protectGui = env["syn"]["protect_gui"]
            protectGui(espFolder)
            espFolder.Parent = CoreGui
            return true
        end
        
        -- Try Scriptware
        if pcall(function() return env["get_hidden_gui"] end) then
            local getHiddenGui = env["get_hidden_gui"]
            espFolder.Parent = getHiddenGui()
            return true
        end
        
        -- Try other executors
        if pcall(function() return env["gethui"] end) then
            local getHui = env["gethui"]
            espFolder.Parent = getHui()
            return true
        end
        
        -- Fallback to CoreGui
        espFolder.Parent = CoreGui
        return true
    end
    
    -- Try to parent the folder
    pcall(tryParentFolder)

    -- Create ESP for existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            self:CreatePlayerESP(player)
        end
    end
    
    -- Connect events
    table.insert(self.Connections, Players.PlayerAdded:Connect(function(player)
        self:CreatePlayerESP(player)
    end))
    
    table.insert(self.Connections, Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayerESP(player)
    end))
    
    -- Main update loop
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        for player, _ in pairs(self.PlayerESP) do
            if player.Parent == Players then -- Check if player still exists
                self:UpdatePlayerESP(player)
            else
                self:RemovePlayerESP(player)
            end
        end
    end))
    
    return self
end

-- Toggle ESP features
function ESP:ToggleESP(enabled)
    self.Settings.Enabled = enabled
    if not enabled then
        for player, _ in pairs(self.PlayerESP) do
            self:HidePlayerESP(player)
        end
    end
end

function ESP:ToggleBoxESP(enabled)
    self.Settings.BoxEsp = enabled
end

function ESP:ToggleNameESP(enabled)
    self.Settings.NameEsp = enabled
end

function ESP:ToggleHealthESP(enabled)
    self.Settings.HealthEsp = enabled
end

function ESP:ToggleChams(enabled)
    self.Settings.ChamsEnabled = enabled
end

-- Clean up ESP
function ESP:Destroy()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    
    for player, _ in pairs(self.PlayerESP) do
        self:RemovePlayerESP(player)
    end
    
    espFolder:Destroy()
    
    self.PlayerESP = {}
    self.Connections = {}
    self.HighlightInstances = {}
end

return ESP
