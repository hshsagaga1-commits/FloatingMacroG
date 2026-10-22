-- TouchMacro.lua
-- Macro de pontos configuraveis para Delta/iOS.
-- Nota: a simulacao de cliques depende de o executor expor VirtualInputManager.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local player = Players.LocalPlayer
if not player then warn("[TouchMacro] LocalPlayer indisponivel") return end

local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("FloatingMacroG")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FloatingMacroG"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local points = {}
local selected
local dragging = false
local dragStart, startPos, activeTouch
local running = false
local opacity = 35

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.Size = UDim2.fromOffset(176, 142)
panel.Position = UDim2.new(0, 12, 0.35, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local function makeButton(name, text, pos, size, parent)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = text
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = Color3.fromRGB(55, 60, 72)
    b.BackgroundTransparency = 0.1
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local add = makeButton("AddPoint", "+ Bolinha", UDim2.fromOffset(8, 8), UDim2.new(1, -16, 0, 30), panel)
local alpha = makeButton("Opacity", "Transparência: 35%", UDim2.fromOffset(8, 45), UDim2.new(1, -16, 0, 30), panel)
local clear = makeButton("ClearPoints", "Apagar bolinhas", UDim2.fromOffset(8, 82), UDim2.new(1, -16, 0, 30), panel)
local run = makeButton("RunSequence", "EXECUTAR (G)", UDim2.fromOffset(8, 115), UDim2.new(1, -16, 0, 30), panel)
run.BackgroundColor3 = Color3.fromRGB(35, 125, 75)

local function refreshNumbers()
    for i, p in ipairs(points) do
        if p and p.Parent then p.Text = tostring(i) end
    end
end

local function tapAt(guiObject)
    if not VIM then
        warn("[TouchMacro] VirtualInputManager indisponivel neste executor.")
        return false
    end
    local pos = guiObject.AbsolutePosition + guiObject.AbsoluteSize / 2
    -- Esconde temporariamente a bolinha para o clique atingir o controle abaixo dela.
    guiObject.Visible = false
    task.wait()
    local ok = pcall(function()
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait()
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    task.wait()
    if guiObject and guiObject.Parent then guiObject.Visible = true end
    if not ok then
        warn("[TouchMacro] O executor bloqueou a simulacao de clique.")
        return false
    end
    return true
end

local function addPoint()
    local index = #points + 1
    local p = Instance.new("TextButton")
    p.Name = "Point" .. index
    p.Size = UDim2.fromOffset(52, 52)
    p.Position = UDim2.new(0.5, (index - 1) * 8, 0.55, (index - 1) * 8)
    p.AnchorPoint = Vector2.new(0.5, 0.5)
    p.BackgroundColor3 = Color3.fromRGB(40, 155, 230)
    p.BackgroundTransparency = opacity / 100
    p.BorderSizePixel = 0
    p.Text = tostring(index)
    p.TextColor3 = Color3.new(1, 1, 1)
    p.TextScaled = true
    p.Font = Enum.Font.GothamBold
    p.AutoButtonColor = false
    p.ZIndex = 20 + index
    p.Parent = gui
    Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", p)
    s.Color = Color3.new(1, 1, 1)
    s.Transparency = 0.2
    table.insert(points, p)

    p.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            selected = p
            dragging = true
            dragStart = input.Position
            startPos = p.Position
            activeTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
        end
    end)
    p.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            if input.UserInputType == Enum.UserInputType.Touch then activeTouch = input end
        end
    end)
end

UIS.InputChanged:Connect(function(input)
    if not dragging or not selected or not dragStart or not startPos then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input == activeTouch then
        local d = input.Position - dragStart
        selected.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos, activeTouch = false, nil, nil, nil
    end
end)

local function executeSequence()
    if running then return end
    running = true
    task.spawn(function()
        for _, p in ipairs(points) do
            if not p.Parent then continue end
            if not tapAt(p) then break end
            task.wait()
        end
        running = false
    end)
end

add.Activated:Connect(addPoint)
alpha.Activated:Connect(function()
    opacity = (opacity + 15) % 105
    if opacity > 100 then opacity = 0 end
    alpha.Text = "Transparência: " .. opacity .. "%"
    for _, p in ipairs(points) do
        p.BackgroundTransparency = opacity / 100
        p.TextTransparency = opacity >= 100 and 1 or 0
    end
end)
clear.Activated:Connect(function()
    for _, p in ipairs(points) do p:Destroy() end
    table.clear(points)
    selected = nil
end)
run.Activated:Connect(executeSequence)
UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.G then executeSequence() end
end)

print("[TouchMacro] Carregado. Adicione pontos, posicione-os e use G.")
