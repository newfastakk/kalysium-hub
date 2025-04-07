-- Settings
local FOV_RADIUS = 100
local AIM_SMOOTHNESS = 0.3
local TARGET_PART = "Head" -- "Head" or "HumanoidRootPart"
local TEAM_CHECK = false

-- Setup
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Drawing API Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Transparency = 0.6
fovCircle.Filled = false
fovCircle.Radius = FOV_RADIUS
fovCircle.Visible = true

-- Functions
local function isVisible(part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 1000

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, rayParams)
    return result and result.Instance and result.Instance:IsDescendantOf(part.Parent)
end

local function getClosestTarget()
    local closest = nil
    local shortestDist = FOV_RADIUS

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(TARGET_PART) then
            if TEAM_CHECK and player.Team == LocalPlayer.Team then
                continue
            end

            local part = player.Character[TARGET_PART]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if distance < shortestDist and isVisible(part) then
                    shortestDist = distance
                    closest = part
                end
            end
        end
    end

    return closest
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    local target = getClosestTarget()
    if target then
        local camCF = Camera.CFrame
        local direction = (target.Position - camCF.Position).Unit
        local newCF = CFrame.new(camCF.Position, camCF.Position + direction)
        Camera.CFrame = camCF:Lerp(newCF, AIM_SMOOTHNESS)
    end
end)