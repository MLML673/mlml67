--[[
    MLML673 HUB - TP BLOCK (V14 ULTRA-PREMIUM)
    - Animated Shimmer Stroke
    - Spring-based Interactive UI
    - Modern Obsidian Theme
    - ESP System with Glow Effects for Invisible Players
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
local espGlows = {}
local originalSurfaceGuis = {}

-- --- THEME CONFIG ---
local Theme = {
    Background = Color3.fromRGB(10, 10, 12),
    Accent = Color3.fromRGB(0, 255, 230),
    AccentSecondary = Color3.fromRGB(0, 120, 255),
    Button = Color3.fromRGB(20, 20, 25),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 160)
}

-- --- NOTIFICATION ---
local function notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3,
    })
end

-- --- ESP LOGIC ---
local function createGlowForPlayer(targetPlayer)
    if targetPlayer == player or not targetPlayer.Character then return nil end
    
    local playerId = targetPlayer.UserId
    if espGlows[playerId] then return espGlows[playerId] end
    
    local character = targetPlayer.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart then return nil end
    
    -- Проверяем, невидимый ли игрок
    local isInvisible = false
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency >= 0.9 then
            isInvisible = true
            break
        end
    end
    
    local glowColor = isInvisible and Color3.fromRGB(255, 0, 150) or Color3.fromRGB(0, 255, 230)
    
    -- Создаём свечение для каждой части персонажа
    local glowParts = {}
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            local glow = Instance.new("Part")
            glow.Shape = Enum.PartType.Ball
            glow.CanCollide = false
            glow.CFrame = part.CFrame
            glow.Size = part.Size * 1.1
            glow.Color = glowColor
            glow.TopSurface = Enum.SurfaceType.Smooth
            glow.BottomSurface = Enum.SurfaceType.Smooth
            glow.Material = Enum.Material.Neon
            glow.Transparency = 0.3
            glow.Parent = workspace
            
            -- Сварка свечения с частью
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = part
            weld.Part1 = glow
            weld.Parent = glow
            
            table.insert(glowParts, glow)
        end
    end
    
    espGlows[playerId] = {
        Player = targetPlayer,
        GlowParts = glowParts,
        IsInvisible = isInvisible,
        Color = glowColor
    }
    
    return espGlows[playerId]
end

local function updateGlowForPlayer(playerId)
    local espData = espGlows[playerId]
    if not espData or not espData.Player or not espData.Player.Character then
        return false
    end
    
    local character = espData.Player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    
    -- Проверяем, изменился ли статус невидимости
    local isInvisible = false
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency >= 0.9 then
            isInvisible = true
            break
        end
    end
    
    -- Обновляем цвет если изменился статус
    if isInvisible ~= espData.IsInvisible then
        local newColor = isInvisible and Color3.fromRGB(255, 0, 150) or Color3.fromRGB(0, 255, 230)
        espData.Color = newColor
        espData.IsInvisible = isInvisible
        
        for _, glow in ipairs(espData.GlowParts) do
            glow.Color = newColor
        end
    end
    
    return true
end

local function enableESP()
    espEnabled = true
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            task.wait(0.05)
            createGlowForPlayer(targetPlayer)
        end
    end
    
    notify("✅ ESP", "Свечение включено")
end

local function disableESP()
    espEnabled = false
    
    for playerId, espData in pairs(espGlows) do
        for _, glow in ipairs(espData.GlowParts) do
            if glow and glow.Parent then
                glow:Destroy()
            end
        end
    end
    
    espGlows = {}
    notify("❌ ESP", "Свечение отключено")
end

local function toggleESP()
    if espEnabled then
        disableESP()
    else
        enableESP()
    end
end

-- Мониторинг новых игроков
Players.PlayerAdded:Connect(function(newPlayer)
    if espEnabled and newPlayer ~= player then
        task.wait(0.1)
        createGlowForPlayer(newPlayer)
    end
end)

-- Мониторинг удаления игроков
Players.PlayerRemoving:Connect(function(removingPlayer)
    local playerId = removingPlayer.UserId
    if espGlows[playerId] then
        for _, glow in ipairs(espGlows[playerId].GlowParts) do
            if glow and glow.Parent then
                glow:Destroy()
            end
        end
        espGlows[playerId] = nil
    end
end)

-- Обновление свечения каждый кадр
RunService.RenderStepped:Connect(function()
    if espEnabled then
        for playerId, espData in pairs(espGlows) do
            if not updateGlowForPlayer(playerId) then
                for _, glow in ipairs(espData.GlowParts) do
                    if glow and glow.Parent then
                        glow:Destroy()
                    end
                end
                espGlows[playerId] = nil
            end
        end
    end
end)

-- Мониторинг новых частей персонажа (для динамических объектов)
Players.PlayerAdded:Connect(function(newPlayer)
    newPlayer.CharacterAdded:Connect(function(character)
        if espEnabled then
            task.wait(0.2)
            local playerId = newPlayer.UserId
            if espGlows[playerId] then
                -- Очищаем старые свечения
                for _, glow in ipairs(espGlows[playerId].GlowParts) do
                    if glow and glow.Parent then
                        glow:Destroy()
                    end
                end
            end
            createGlowForPlayer(newPlayer)
        end
    end)
end)

player.CharacterAdded:Connect(function()
    if espEnabled then
        -- Пересоздаём ESP для текущего игрока после возрождения
        disableESP()
        task.wait(0.5)
        enableESP()
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
main.Size = UDim2.new(0, 280, 0, 300)
main.Position = UDim2.new(0.5, -140, 0.5, -150)
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
local keyBtn = createBtn("KEYBIND: " .. teleportKey.Name, 130)
local espBtn = createBtn("ESP: OFF", 190)

-- Interaction
actionBtn.MouseButton1Click:Connect(function()
    executeAction()
end)

keyBtn.MouseButton1Click:Connect(function()
    if isWaitingForKey then return end
    isWaitingForKey = true
    keyBtn.Text = "WAITING..."
    keyBtn.TextColor3 = Theme.Accent
end)

espBtn.MouseButton1Click:Connect(function()
    toggleESP()
    espBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
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

notify("MLML673 HUB", "Ultra-Premium UI Loaded")
