local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ESP Settings
local ESP_ENABLED = true
local TEAM_CHECK = false
local BOX_ENABLED = true
local HP_ENABLED = true
local HP_TEXT_ENABLED = true
local LINE_ENABLED = true

-- ESP Drawing Objects Table
local ESP_CACHE = {}

-- Function to create ESP for a player
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local character = player.Character or player.CharacterAdded:Wait()
    if not character then return end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    
    -- ESP Components
    local esp = {
        Box = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        HPBar = Drawing.new("Square"),
        HPText = Drawing.new("Text")
    }
    
    -- Box Setup
    esp.Box.Thickness = 2
    esp.Box.Filled = false
    esp.Box.Color = Color3.fromRGB(255, 255, 255)
    esp.Box.Visible = false
    
    -- Line Setup
    esp.Line.Thickness = 1
    esp.Line.Color = Color3.fromRGB(255, 255, 255)
    esp.Line.Visible = false
    
    -- HP Bar Setup
    esp.HPBar.Thickness = 1
    esp.HPBar.Filled = true
    esp.HPBar.Color = Color3.fromRGB(0, 255, 0)
    esp.HPBar.Visible = false
    
    -- HP Text Setup
    esp.HPText.Size = 14
    esp.HPText.Color = Color3.fromRGB(255, 255, 255)
    esp.HPText.Outline = true
    esp.HPText.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.HPText.Visible = false
    
    ESP_CACHE[player] = esp
    
    -- Update Function
    local function UpdateESP()
        if not ESP_ENABLED then
            esp.Box.Visible = false
            esp.Line.Visible = false
            esp.HPBar.Visible = false
            esp.HPText.Visible = false
            return
        end
        
        if not character or not character.Parent or not humanoidRootPart or humanoid.Health <= 0 then
            esp.Box.Visible = false
            esp.Line.Visible = false
            esp.HPBar.Visible = false
            esp.HPText.Visible = false
            return
        end
        
        local rootPosition, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
        if not onScreen then
            esp.Box.Visible = false
            esp.Line.Visible = false
            esp.HPBar.Visible = false
            esp.HPText.Visible = false
            return
        end
        
        -- Calculate size based on character proportions
        local head = character:FindFirstChild("Head")
        if not head then return end
        
        local headPos = Camera:WorldToViewportPoint(head.Position)
        local feetPos = Camera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))
        
        local height = math.abs(headPos.Y - feetPos.Y)
        local width = height * 0.5  -- Maintain realistic proportions
        
        -- Update Box
        if BOX_ENABLED then
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(rootPosition.X - width/2, rootPosition.Y - height/2)
            esp.Box.Visible = true
        end
        
        -- Update Line
        if LINE_ENABLED then
            esp.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            esp.Line.To = Vector2.new(rootPosition.X, rootPosition.Y)
            esp.Line.Visible = true
        end
        
        -- Update HP
        if HP_ENABLED or HP_TEXT_ENABLED then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            
            if HP_ENABLED then
                esp.HPBar.Size = Vector2.new(2, height * healthPercent)
                esp.HPBar.Position = Vector2.new(rootPosition.X - width/2 - 4, rootPosition.Y - height/2 + height * (1 - healthPercent))
                esp.HPBar.Color = Color3.fromHSV(healthPercent/3, 1, 1)
                esp.HPBar.Visible = true
            end
            
            if HP_TEXT_ENABLED then
                esp.HPText.Text = math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth
                esp.HPText.Position = Vector2.new(rootPosition.X - esp.HPText.TextBounds.X/2, rootPosition.Y - height/2 - 20)
                esp.HPText.Visible = true
            end
        end
    end
    
    -- Connect Updates
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not player.Parent or not ESP_CACHE[player] then
            connection:Disconnect()
            for _, drawing in pairs(esp) do
                drawing:Remove()
            end
            ESP_CACHE[player] = nil
            return
        end
        UpdateESP()
    end)
    
    -- Handle Character Reset
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoid = character:WaitForChild("Humanoid")
    end)
end

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    if not TEAM_CHECK or player.Team ~= LocalPlayer.Team then
        CreateESP(player)
    end
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    if not TEAM_CHECK or player.Team ~= LocalPlayer.Team then
        CreateESP(player)
    end
end)

-- Cleanup on player removal
Players.PlayerRemoving:Connect(function(player)
    if ESP_CACHE[player] then
        for _, drawing in pairs(ESP_CACHE[player]) do
            drawing:Remove()
        end
        ESP_CACHE[player] = nil
    end
end)