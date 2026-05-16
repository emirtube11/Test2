local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character:Model
local Humanoid:Humanoid
local HumanoidRootPart:BasePart

local Data = {Ping = 0, Target = nil}

local function onCharacterAdded()
	Character = Player.Character or Player.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

onCharacterAdded()
Player.CharacterAdded:Connect(onCharacterAdded)

local function Predict(Velocity:Vector3, Ping:Number)
    return (Velocity * Ping)
end

local function FindMurderer()
    local myRoot = HumanoidRootPart
    local best, bestDist = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player then continue end
        local char = plr.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local hasKnife = false
        for _, obj in pairs(char:GetChildren()) do
            if obj.Name == "Knife" then hasKnife = true; break end
        end
        if not hasKnife then
            local bp = plr:FindFirstChild("Backpack")
            if bp then
                for _, obj in pairs(bp:GetChildren()) do
                    if obj.Name == "Knife" then hasKnife = true; break end
                end
            end
        end

        if hasKnife then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and myRoot then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = plr
                end
            else
                best = plr
            end
        end
    end

    Data.Target = best
    return best
end

local function GetGun()
    return Player.Character and Player.Character:FindFirstChild("Gun")
end

local function EquipGun()
    local bp = Player:FindFirstChild("Backpack")
    if not Character or not bp then return false end
    local gun = bp:FindFirstChild("Gun")
    if not gun then return false end
    local h = Character:FindFirstChildOfClass("Humanoid")
    if not h then return false end
    h:EquipTool(gun)
    task.wait(0.05)
    return GetGun() ~= nil
end

local function Shoot()
        FindMurderer()
    if not Data.Target then return end

    local char = Data.Target.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

    if not hrp or not hum or hum.Health <= 0 or not myRoot then return end
    Data.Ping = (Player:GetNetworkPing() * 5)
    local predicted = Predict(hrp.AssemblyLinearVelocity, Data.Ping)

    local Origin = hrp.Position
    local Direction = Vector3.new(0, -500, 0)
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {char}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.IgnoreWater = true

    local raycastResult = Workspace:Raycast(Origin, Direction, Params)

    local Minimum, Max = raycastResult.Position.Y + 2, raycastResult.Position.Y + 6

    local aimPos = CFrame.new(Vector3.new(hrp.Position.X, math.clamp(hrp.Position.Y, Minimum, Max), hrp.Position.Z)) + predicted

    local gun = GetGun()
    if not gun then
        if not EquipGun() then return end
        gun = GetGun()
    end
    if not gun then return end

    local shootRemote = gun:FindFirstChild("Shoot")
    if not shootRemote then return end

    local bp = Player:FindFirstChild("Backpack")
    gun.Parent = Player.Character
    task.wait(0.02)

    shootRemote:FireServer(myRoot.CFrame, aimPos)

    task.wait(0.02)
    if bp then gun.Parent = bp end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SilentShot_Live"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local ShootBtn = Instance.new("TextButton")
ShootBtn.Name = "Shoot_Btn"
ShootBtn.Size = UDim2.fromOffset(90, 90)
ShootBtn.Position = UDim2.new(0.5, -45, 0.75, 0)
ShootBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ShootBtn.BackgroundTransparency = 0.2
ShootBtn.Text = "SHOOT"
ShootBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ShootBtn.TextScaled = true
ShootBtn.Font = Enum.Font.GothamBlack
ShootBtn.Parent = ScreenGui

Instance.new("UICorner", ShootBtn).CornerRadius = UDim.new(1, 0)
local Stroke = Instance.new("UIStroke", ShootBtn)
Stroke.Thickness = 2.5
Stroke.Color = Color3.fromRGB(0, 255, 150)

local dragging, dragStart, startPos, dragInput = false
ShootBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ShootBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
ShootBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        ShootBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

ShootBtn.MouseButton1Click:Connect(function()
    Shoot()
end)

local Connection
Connection = Player.Chatted:Connect(function(Msg)
    if Msg == "." then
        ScreenGui:Destroy()
        Connection:Disconnect()
        return
    end
end)

print("Version 1")
