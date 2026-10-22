-- FloatingMacroG.lua
-- Botao flutuante G com controle de transparencia.
-- Delta/iOS: nao usa VirtualInputManager como fallback, pois pode fechar o cliente.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then
    warn("[FloatingMacroG] LocalPlayer indisponivel.")
    return
end

-- PlayerGui e a opcao mais conservadora para evitar problemas com CoreGui/gethui.
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

local function makeSmallButton(name, text, size, position, z)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = size
    b.Position = position
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.Text = text
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

local locked = true
local dragging = false
local dragStart
local startPosition
local activeInput

local opacityLevels = {0.55, 0.75, 0.9, 1}
local opacityIndex = 1

local function updateLockButton()
    lockButton.Text = locked and "🔒" or "🔓"
end

local function updateAuxPositions()
    local p = macro.Position
    lockButton.Position = UDim2.new(p.X.Scale, p.X.Offset + 42, p.Y.Scale, p.Y.Offset - 42)
    opacityButton.Position = UDim2.new(p.X.Scale, p.X.Offset + 42, p.Y.Scale, p.Y.Offset + 42)
end

local function applyTransparency()
    local t = opacityLevels[opacityIndex]
    macro.BackgroundTransparency = t
    macro.TextTransparency = t
    stroke.Transparency = math.min(1, t + 0.25)
    -- Mantem os controles pequenos visiveis para que seja possivel alterar a opcao.
    opacityButton.Text = (opacityIndex == #opacityLevels) and "◌" or "◐"
end

local function pressG()
    -- Sem fallback para VirtualInputManager: em alguns ambientes mobile essa chamada
    -- pode encerrar o cliente. Se Delta nao disponibilizar keypress, apenas avisa.
    if typeof(keypress) ~= "function" or typeof(keyrelease) ~= "function" then
        warn("[FloatingMacroG] Delta nao disponibilizou keypress/keyrelease neste ambiente.")
        return
    end
    local ok, err = pcall(function()
        keypress(0x47)
        task.wait(0.04)
        keyrelease(0x47)
    end)
    if not ok then
        warn("[FloatingMacroG] Falha ao enviar G: " .. tostring(err))
    end
end

macro.Activated:Connect(pressG)
lockButton.Activated:Connect(function()
    locked = not locked
    updateLockButton()
end)
opacityButton.Activated:Connect(function()
    opacityIndex = (opacityIndex % #opacityLevels) + 1
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
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        activeInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or locked or not dragStart or not startPosition then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input == activeInput then
        local delta = input.Position - dragStart
        macro.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
        updateAuxPositions()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        dragStart = nil
        startPosition = nil
        activeInput = nil
    end
end)

updateLockButton()
updateAuxPositions()
applyTransparency()
