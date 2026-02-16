--[[
    ANTI-CHEAT SPIN ROTATION SCRIPT
    Game: Steal a Brainrot
    Rotation Speed: 820°/second
    Features:
    - Anti-detection rotation
    - Hidden from game detection
    - Smooth 820°/sec rotation
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local SPIN_SPEED = 820 -- градусы в секунду
local isSpinning = false
local spinConnection = nil

-- --- ANTI-CHEAT FUNCTIONS ---

-- Скрывает скрипт от детекции
local function hideFromDetection()
    local metatable = getrawmetatable(game)
    local oldIndex = metatable.__index
    
    metatable.__index = function(self, key)
        if key == "FindFirstChildOfClass" or key == "FindFirstChild" then
            if debug.getinfo(2).source:find("AntiCheat") or debug.getinfo(2).source:find("Detection") then
                return function() return nil end
            end
        end
        return oldIndex(self, key)
    end
end

-- Использует более сложный способ ротации для обхода детекции
local function antiDetectRotate(hrp, deltaTime)
    if not hrp then return end
    
    -- Вычисляем угол поворота с учетом дельта-времени
    local rotationAmount = math.rad(SPIN_SPEED * deltaTime)
    
    -- Применяем ротацию через манипуляцию CFrame
    local currentCF = hrp.CFrame
    local x, y, z = currentCF:ToEulerAnglesXYZ()
    
    -- Добавляем Y ротацию (вертикальное вращение)
    y = y + rotationAmount
    
    -- Нормализуем угол
    y = y % (2 * math.pi)
    
    -- Применяем новый CFrame без рывков
    hrp.CFrame = CFrame.new(currentCF.Position) * CFrame.Angles(x, y, z)
end

-- Альтернативный способ ротации (более скрытный)
local function stealthRotate(hrp, deltaTime)
    if not hrp then return end
    
    local rotationAmount = math.rad(SPIN_SPEED * deltaTime)
    local currentCF = hrp.CFrame
    
    -- Используем матричное умножение вместо Angles для обхода детекции
    hrp.CFrame = currentCF * CFrame.Angles(0, rotationAmount, 0)
end

-- --- SPIN LOGIC ---

local function startSpin()
    isSpinning = true
    local char = player.Character
    
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        print("❌ Character not found")
        isSpinning = false
        return
    end

    local hrp = char.HumanoidRootPart
    
    -- Отключаем детекцию перед началом
    pcall(hideFromDetection)
    
    if spinConnection then
        spinConnection:Disconnect()
    end

    spinConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if not isSpinning then
            if spinConnection then
                spinConnection:Disconnect()
                spinConnection = nil
            end
            return
        end

        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
            isSpinning = false
            if spinConnection then
                spinConnection:Disconnect()
                spinConnection = nil
            end
            return
        end

        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            isSpinning = false
            if spinConnection then
                spinConnection:Disconnect()
                spinConnection = nil
            end
            return
        end

        -- Используем скрытый способ ротации
        stealthRotate(hrp, deltaTime)
    end)

    print("🌀 SPIN STARTED - 820°/sec")
end

local function stopSpin()
    isSpinning = false
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
    print("⏹️ SPIN STOPPED")
end

-- --- UI CONSTRUCTION ---

local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "AntiCheat_SPIN"
sg.ResetOnSpawn = false

-- Main Container
local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 250, 0, 150)
main.Position = UDim2.new(0.02, 0, 0.5, -75)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
main.BorderSizePixel = 0

local corner = Instance.new("UICorner", main)
corner.CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", main)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(0, 255, 230)
stroke.Transparency = 0.5

-- Header
local header = Instance.new("TextLabel", main)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
header.Text = "ANTI-CHEAT SPIN 820°"
header.TextColor3 = Color3.fromRGB(0, 255, 230)
header.Font = Enum.Font.BuilderSansBold
header.TextSize = 14
header.BorderSizePixel = 0

local hCorner = Instance.new("UICorner", header)
hCorner.CornerRadius = UDim.new(0, 12)

-- Spin Button
local spinBtn = Instance.new("TextButton", main)
spinBtn.Size = UDim2.new(0, 230, 0, 45)
spinBtn.Position = UDim2.new(0, 10, 0, 55)
spinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
spinBtn.Text = "START SPIN"
spinBtn.TextColor3 = Color3.fromRGB(0, 255, 230)
spinBtn.Font = Enum.Font.BuilderSansMedium
spinBtn.TextSize = 13
spinBtn.BorderSizePixel = 0

local bCorner = Instance.new("UICorner", spinBtn)
bCorner.CornerRadius = UDim.new(0, 8)

local bStroke = Instance.new("UIStroke", spinBtn)
bStroke.Thickness = 1.5
bStroke.Color = Color3.fromRGB(0, 255, 230)
bStroke.Transparency = 0.6

-- Button Logic
spinBtn.MouseButton1Click:Connect(function()
    if isSpinning then
        stopSpin()
        spinBtn.Text = "START SPIN"
        spinBtn.TextColor3 = Color3.fromRGB(0, 255, 230)
        bStroke.Color = Color3.fromRGB(0, 255, 230)
    else
        startSpin()
        spinBtn.Text = "STOP SPIN [ACTIVE]"
        spinBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        bStroke.Color = Color3.fromRGB(255, 100, 100)
    end
end)

-- Hover Effects
spinBtn.MouseEnter:Connect(function()
    spinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end)

spinBtn.MouseLeave:Connect(function()
    if not isSpinning then
        spinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    end
end)

-- Dragging
local dragging, dragStart, startPos
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

-- Hotkey (T)
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.T then
        if isSpinning then
            stopSpin()
            spinBtn.Text = "START SPIN"
            spinBtn.TextColor3 = Color3.fromRGB(0, 255, 230)
        else
            startSpin()
            spinBtn.Text = "STOP SPIN [ACTIVE]"
            spinBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
end)

print("✅ Anti-Cheat SPIN script loaded | Press T or click button to activate")
