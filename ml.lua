--[[
    MLML673 HUB - TP BLOCK (V14 ULTRA-PREMIUM) + ADVANCED ESP
    - Animated Shimmer Stroke
    - Spring-based Interactive UI
    - Modern Obsidian Theme
    - Player ESP Highlight System + Invisible Detection
    - Billboard with Name and Held Item
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local REQUIRED_TOOL = "Flying Carpet"
local teleportKey = Enum.KeyCode.F
local isWaitingForKey = false

-- --- ESP CONFIG ---
local espEnabled = false
local espConnections = {}
local espHighlights = {}
local billboardConnections = {}

-- --- THEME CONFIG ---
local Theme = {
    Background = Color3.fromRGB(10, 10, 12),
    Accent = Color3.fromRGB(0, 255, 230),
    AccentSecondary = Color3.fromRGB(0, 120, 255),
    Button = Color3.fromRGB(20, 20, 25),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 160),
    ESPColor = Color3.fromRGB(255, 0, 0),
    ESPOutline = Color3.fromRGB(255, 255, 255)
}

-- --- NOTIFICATION ---
local function notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3,
    })
end

-- --- HELPER FUNCTIONS ---
local function isCharacterInvisible(character)
    if not character then return false end
    
    local invisiblePartCount = 0
    local totalPartCount = 0
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            totalPartCount = totalPartCount + 1
            if part.Transparency >= 0.9 then
                invisiblePartCount = invisiblePartCount + 1
            end
        end
    end
    
    return totalPartCount > 0 and invisiblePartCount >= (totalPartCount * 0.8)
end

local function getHeldItem(character)
    if not character then return "None" end
    
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") or child:IsA("Accessory") then
            return child.Name
        end
    end
    
    return "None"
end

local function createBillboard(parent, playerName, character)
    if parent:FindFirstChild("PlayerInfoBillboard") then
        parent:FindFirstChild("PlayerInfoBillboard"):Destroy()
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerInfoBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.Adornee = parent
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.MaxDistance = 500
    
    -- Container
    local container = Instance.new("Frame", billboard)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    container.BorderSizePixel = 0
    container.BackgroundTransparency = 0.3
    
    local corner = Instance.new("UICorner", container)
    corner.CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Theme.Accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    
    -- Player Name
    local nameLabel = Instance.new("TextLabel", container)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextScaled = true
    nameLabel.TextWrapped = true
    
    -- Held Item
    local itemLabel = Instance.new("TextLabel", container)
    itemLabel.Size = UDim2.new(1, 0, 0.5, 0)
    itemLabel.Position = UDim2.new(0, 0, 0.5, 0)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = "Item: " .. getHeldItem(character)
    itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    itemLabel.Font = Enum.Font.GothamMedium
    itemLabel.TextSize = 12
    itemLabel.TextScaled = true
    itemLabel.TextWrapped = true
    
    billboard.Parent = parent
    
    -- Update item every 0.5 seconds
    if billboardConnections[playerName] then
        billboardConnections[playerName]:Disconnect()
    end
    
    billboardConnections[playerName] = RunService.Heartbeat:Connect(function()
        if character and parent and parent.Parent then
            itemLabel.Text = "Item: " .. getHeldItem(character)
        else
            if billboardConnections[playerName] then
                billboardConnections[playerName]:Disconnect()
                billboardConnections[playerName] = nil
            end
        end
    end)
    
    return billboard
end

local function removeBillboard(parent, playerName)
    local billboard = parent:FindFirstChild("PlayerInfoBillboard")
    if billboard then
        billboard:Destroy()
    end
    
    if billboardConnections[playerName] then
        billboardConnections[playerName]:Disconnect()
        billboardConnections[playerName] = nil
    end
end

-- --- ESP FUNCTIONS ---
local function addESPToCharacter(character, plr)
    if not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    if character:FindFirstChild("Highlight") then
        return
    end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Theme.ESPColor
    highlight.OutlineColor = Theme.ESPOutline
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0
    highlight.Adornee = character
    highlight.Parent = character
    
    espHighlights[plr] = highlight
    
    -- Create Billboard
    if character:FindFirstChild("Head") then
        createBillboard(character.Head, plr.Name, character)
    end
end

local function removeESPFromCharacter(character, plr)
    local highlight = character:FindFirstChild("Highlight")
    if highlight then
        highlight:Destroy()
    end
    
    if character:FindFirstChild("Head") then
        removeBillboard(character.Head, plr.Name)
    end
    
    espHighlights[plr] = nil
end

local function enableESP()
    espEnabled = true
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            addESPToCharacter(p.Character, p)
        end
    end
    
    for plr, conn in pairs(espConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    espConnections = {}
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            espConnections[p] = p.CharacterAdded:Connect(function(character)
                character:WaitForChild("HumanoidRootPart", 3)
                if espEnabled then
                    addESPToCharacter(character, p)
                end
            end)
        end
    end
    
    notify("✅ ESP", "ESP Enabled")
end

local function disableESP()
    espEnabled = false
    
    for plr, conn in pairs(espConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    espConnections = {}
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            removeESPFromCharacter(p.Character, p)
        end
    end
    
    for playerName, conn in pairs(billboardConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    billboardConnections = {}
    
    notify("❌ ESP", "ESP Disabled")
end

local function toggleESP()
    if espEnabled then
        disableESP()
    else
        enableESP()
    end
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(p)
    if p ~= player then
        espConnections[p] = p.CharacterAdded:Connect(function(character)
            character:WaitForChild("HumanoidRootPart", 3)
            if espEnabled then
                addESPToCharacter(character, p)
            end
        end)
    end
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(p)
    if espConnections[p] then
        espConnections[p]:Disconnect()
        espConnections[p] = nil
    end
    if p.Character then
        removeESPFromCharacter(p.Character, p)
    end
end)

-- Monitor for invisible players and update item
RunService.Heartbeat:Connect(function()
    if not espEnabled then return end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local character = p.Character
            local isInvisible = isCharacterInvisible(character)
            
            -- Always show highlight if ESP is on
            if not character:FindFirstChild("Highlight") then
                addESPToCharacter(character, p)
            end
            
            -- Ensure billboard exists
            if not character.Head:FindFirstChild("PlayerInfoBillboard") then
                createBillboard(character.Head, p.Name, character)
            end
        end
    end
end)

-- --- LOGIC ---
local spots = {
    CFrame.new(-402.18, -6.34, 131.83) * CFrame.Angles(0, math.rad(-20.08), 0),
    CFrame.new(-416.66, -6.34, -2.05) * CFrame.Angles(0, math.rad(-62.89), 0),
    CFrame.new(-329.37, -4.68, 18.12) * CFrame.Angles(0, math.rad(-30.53), 0),
}

local function fastClick()
    task.wait(0.7)
    local size = workspace.CurrentCamera.ViewportSize
    for _ = 1, 5 do
        VirtualInputManager:SendMouseButtonEvent(size.X/2, size.Y/2 + 23, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(size.X/2, size.Y/2 + 23, 0, false, game, 1)
        task.wait(0.01)
    end
end

local function executeAction()
    local tool = player.Backpack:FindFirstChild(REQUIRED_TOOL) or player.Character:FindFirstChild(REQUIRED_TOOL)
    if not tool then
        notify("❌ MISSING", "Requires: " .. REQUIRED_TOOL)
        return
    end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if tool.Parent ~= char then char.Humanoid:EquipTool(tool) end

    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then target = p break end
    end

    for _, spot in ipairs(spots) do
        char.HumanoidRootPart.CFrame = spot
        task.wait(0.1)
    end

    if target then
        StarterGui:SetCore("PromptBlockPlayer", target)
        fastClick()
    end
end

-- --- UI CONSTRUCTION ---
if player.PlayerGui:FindFirstChild("MLML673 HUB") then
    player.PlayerGui:FindFirstChild("MLML673 HUB"):Destroy()
end

local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "MLML673 HUB"
sg.ResetOnSpawn = false

-- Main Container
local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 280, 0, 310)
main.Position = UDim2.new(0.5, -140, 0.5, -155)
main.BackgroundColor3 = Theme.Background
main.BorderSizePixel = 0

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 16)

-- THE SHINING STROKE
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Thickness = 2.5
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local strokeGradient = Instance.new("UIGradient", mainStroke)
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(0.5, Theme.AccentSecondary),
    ColorSequenceKeypoint.new(1, Theme.Accent)
})

-- Animate the Shine
RunService.RenderStepped:Connect(function()
    strokeGradient.Rotation = (strokeGradient.Rotation + 1.5) % 360
end)

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundTransparency = 1

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, 0, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "MLML673 HUB"
title.TextColor3 = Theme.Text
title.Font = Enum.Font.BuilderSansBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1

local glow = Instance.new("ImageLabel", main)
glow.Name = "Glow"
glow.BackgroundTransparency = 1
glow.Position = UDim2.new(0, -15, 0, -15)
glow.Size = UDim2.new(1, 30, 1, 30)
glow.Image = "rbxassetid://5028822351"
glow.ImageColor3 = Theme.Accent
glow.ImageTransparency = 0.8
glow.ZIndex = 0

-- --- BUTTON GENERATOR ---
local function createBtn(text, y)
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0, 250, 0, 50)
    btn.Position = UDim2.new(0.5, -125, 0, y)
    btn.BackgroundColor3 = Theme.Button
    btn.Text = text
    btn.TextColor3 = Theme.TextDim
    btn.Font = Enum.Font.BuilderSansMedium
    btn.TextSize = 15
    btn.AutoButtonColor = false
    
    local bCorner = Instance.new("UICorner", btn)
    bCorner.CornerRadius = UDim.new(0, 10)
    
    local bStroke = Instance.new("UIStroke", btn)
    bStroke.Thickness = 1.2
    bStroke.Color = Theme.Accent
    bStroke.Transparency = 0.8

    -- Fancy Hover & Click Anims
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(30, 30, 40), TextColor3 = Theme.Text}):Play()
        TweenService:Create(bStroke, TweenInfo.new(0.3), {Transparency = 0.2, Thickness = 2}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Button, TextColor3 = Theme.TextDim}):Play()
        TweenService:Create(bStroke, TweenInfo.new(0.3), {Transparency = 0.8, Thickness = 1.2}):Play()
    end)

    btn.MouseButton1Down:Connect(function()
        btn:TweenSize(UDim2.new(0, 240, 0, 45), "Out", "Quad", 0.1, true)
    end)
    
    btn.MouseButton1Up:Connect(function()
        btn:TweenSize(UDim2.new(0, 250, 0, 50), "Out", "Elastic", 0.4, true)
    end)

    return btn
end

local actionBtn = createBtn("EXECUTE TELEPORT", 70)
local espBtn = createBtn("ESP: OFF", 130)
local keyBtn = createBtn("KEYBIND: " .. teleportKey.Name, 190)

-- Interaction
actionBtn.MouseButton1Click:Connect(function()
    executeAction()
end)

espBtn.MouseButton1Click:Connect(function()
    toggleESP()
    espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    if espEnabled then
        espBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        espBtn.TextColor3 = Theme.TextDim
    end
end)

keyBtn.MouseButton1Click:Connect(function()
    if isWaitingForKey then return end
    isWaitingForKey = true
    keyBtn.Text = "WAITING..."
    keyBtn.TextColor3 = Theme.Accent
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if isWaitingForKey and input.UserInputType == Enum.UserInputType.Keyboard then
        teleportKey = input.KeyCode
        keyBtn.Text = "KEYBIND: " .. teleportKey.Name
        keyBtn.TextColor3 = Theme.TextDim
        isWaitingForKey = false
    elseif not gp and input.KeyCode == teleportKey then
        executeAction()
    end
end)

-- --- DRAGGING ---
local dragging, dragInput, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

notify("MLML673 HUB", "Ultra-Premium UI Loaded + Advanced ESP Ready")
