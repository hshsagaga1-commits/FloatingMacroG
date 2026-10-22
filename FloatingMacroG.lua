-- FloatingMacroG.lua
-- Botao flutuante mobile com trava, arraste e transparencia.
-- Esta versao NAO simula teclas: keypress/keyrelease estavam causando crash no iOS.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then warn("[FloatingMacroG] LocalPlayer indisponivel.") return end

local guiParent = player:WaitForChild("PlayerGui")
local oldGui = guiParent:FindFirstChild("FloatingMacroG")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FloatingMacroG"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = guiParent

local macro = Instance.new("TextButton")
macro.Name = "MacroButton"
macro.Size = UDim2.fromOffset(92, 92)
macro.Position = UDim2.new(0.72, 0, 0.58, 0)
macro.AnchorPoint = Vector2.new(0.5, 0.5)
macro.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
macro.BackgroundTransparency = 0.55
macro.BorderSizePixel = 0
macro.Text = "G"
macro.TextColor3 = Color3.fromRGB(255, 255, 255)
macro.TextTransparency = 0
macro.TextScaled = true
macro.Font = Enum.Font.GothamBold
macro.AutoButtonColor = false
macro.Active = true
macro.ZIndex = 10
macro.Parent = screenGui

local circle = Instance.new("UICorner")
circle.CornerRadius = UDim.new(1, 0)
circle.Parent = macro
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Transparency = 0.25
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Parent = macro

local function makeSmallButton(name, label, size, position, z)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = size
    b.Position = position
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.Text = label
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Active = true
    b.ZIndex = z
    b.Parent = screenGui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = b
    return b
end

local lockButton = makeSmallButton("PositionLock", "🔒", UDim2.fromOffset(30,30), UDim2.new(0.72,42,0.58,-42), 20)
local opacityButton = makeSmallButton("TransparencyButton", "◐", UDim2.fromOffset(30,30), UDim2.new(0.72,42,0.58,42), 20)
local locked, dragging = true, false
local dragStart, startPosition, activeInput
local opacityPercent = 55

local function updateLockButton() lockButton.Text = locked and "🔒" or "🔓" end
local function updateAuxPositions()
    local p = macro.Position
    lockButton.Position = UDim2.new(p.X.Scale, p.X.Offset + 42, p.Y.Scale, p.Y.Offset - 42)
    opacityButton.Position = UDim2.new(p.X.Scale, p.X.Offset + 42, p.Y.Scale, p.Y.Offset + 42)
end
local function applyTransparency()
    local t = math.clamp(opacityPercent / 100, 0, 1)
    macro.BackgroundTransparency = t
    macro.TextTransparency = t
    stroke.Transparency = math.clamp(t + 0.25, 0, 1)
    local hidden = opacityPercent >= 100
    for _, b in ipairs({lockButton, opacityButton}) do
        b.BackgroundTransparency = hidden and 1 or 0.25
        b.TextTransparency = hidden and 1 or 0
    end
    opacityButton.Text = hidden and "" or (tostring(opacityPercent) .. "%")
end

-- Apenas confirma que o toque foi recebido. Nenhuma tecla simulada nesta versao.
macro.Activated:Connect(function()
    local oldColor = macro.BackgroundColor3
    macro.BackgroundColor3 = Color3.fromRGB(40, 150, 90)
    task.delay(0.25, function()
        if macro and macro.Parent then macro.BackgroundColor3 = oldColor end
    end)
end)
lockButton.Activated:Connect(function()
    locked = not locked
    updateLockButton()
end)
opacityButton.Activated:Connect(function()
    opacityPercent = (opacityPercent + 10) % 110
    if opacityPercent > 100 then opacityPercent = 0 end
    applyTransparency()
end)

macro.InputBegan:Connect(function(input)
    if locked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = macro.Position
        if input.UserInputType == Enum.UserInputType.Touch then activeInput = input end
    end
end)
macro.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then activeInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if not dragging or locked or not dragStart or not startPosition then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input == activeInput then
        local delta = input.Position - dragStart
        macro.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        updateAuxPositions()
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPosition, activeInput = false, nil, nil, nil
    end
end)

updateLockButton()
updateAuxPositions()
applyTransparency()
