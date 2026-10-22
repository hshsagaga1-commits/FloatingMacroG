-- FloatingMacroG.lua
-- Botao flutuante para tentar acionar a tecla G.
-- Observacao: keypress/keyrelease dependem do executor; Roblox/iOS pode bloquear a simulacao.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
if not player then
    warn("[FloatingMacroG] LocalPlayer indisponivel.")
    return
end

local guiParent
pcall(function()
    if typeof(gethui) == "function" then
        guiParent = gethui()
    end
end)
if not guiParent then
    pcall(function()
        guiParent = CoreGui
    end)
end
if not guiParent then
    guiParent = player:WaitForChild("PlayerGui")
end

local oldGui
pcall(function()
    oldGui = guiParent:FindFirstChild("FloatingMacroG")
    if oldGui then oldGui:Destroy() end
end)

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
macro.TextScaled = true
macro.Font = Enum.Font.GothamBold
macro.AutoButtonColor = true
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

-- O cadeado fica separado do botao G para nao disparar o macro ao alternar o bloqueio.
local lockButton = Instance.new("TextButton")
lockButton.Name = "PositionLock"
lockButton.Size = UDim2.fromOffset(30, 30)
lockButton.Position = UDim2.new(0.72, 42, 0.58, -42)
lockButton.AnchorPoint = Vector2.new(0.5, 0.5)
lockButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
lockButton.BackgroundTransparency = 0.25
lockButton.BorderSizePixel = 0
lockButton.Text = "🔒"
lockButton.TextScaled = true
lockButton.Font = Enum.Font.GothamBold
lockButton.Active = true
lockButton.ZIndex = 20
lockButton.Parent = screenGui

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(1, 0)
lockCorner.Parent = lockButton

local locked = true
local dragging = false
local dragStart
local startPosition
local activeInput

local function updateLockButton()
    lockButton.Text = locked and "🔒" or "🔓"
end

local function updateLockPosition()
    local p = macro.Position
    lockButton.Position = UDim2.new(p.X.Scale, p.X.Offset + 42, p.Y.Scale, p.Y.Offset - 42)
end

local function pressG()
    local sent = false

    if typeof(keypress) == "function" and typeof(keyrelease) == "function" then
        local ok = pcall(function()
            keypress(0x47)
            task.wait(0.04)
            keyrelease(0x47)
        end)
        sent = ok
    end

    if not sent then
        local ok = pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.G, false, game)
            task.wait(0.04)
            vim:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        end)
        sent = ok
    end

    if not sent then
        warn("[FloatingMacroG] Este executor pode nao permitir simular a tecla G neste dispositivo.")
    end
end

macro.Activated:Connect(pressG)

lockButton.Activated:Connect(function()
    locked = not locked
    updateLockButton()
end)

macro.InputBegan:Connect(function(input)
    if locked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = macro.Position
        if input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
        end
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
        updateLockPosition()
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
updateLockPosition()
