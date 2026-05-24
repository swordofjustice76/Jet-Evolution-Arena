local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local EvolutionTree = require(ReplicatedStorage.Shared.EvolutionTree)

-- Colors
local GOLD = Color3.fromRGB(255, 200, 0)
local ACCENT = Color3.fromRGB(0, 150, 255)
local GREEN = Color3.fromRGB(0, 255, 100)
local WHITE = Color3.new(1, 1, 1)

-- === EVOLUTION NOTIFY GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "EvolutionNotify"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 99
gui.Parent = player:WaitForChild("PlayerGui")

-- Notification panel (center-top)
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 400, 0, 120)
panel.Position = UDim2.new(0.5, -200, 0, -130)
panel.BackgroundColor3 = Color3.fromRGB(10, 30, 10)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 15)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = GREEN
panelStroke.Thickness = 3
panelStroke.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.TextColor3 = GREEN
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "EVOLUTION AVAILABLE!"
title.Parent = panel

-- Evolution name
local evoLabel = Instance.new("TextLabel")
evoLabel.Name = "EvoName"
evoLabel.Size = UDim2.new(1, 0, 0, 35)
evoLabel.Position = UDim2.new(0, 0, 0.3, 0)
evoLabel.BackgroundTransparency = 1
evoLabel.TextColor3 = GOLD
evoLabel.TextScaled = true
evoLabel.Font = Enum.Font.GothamBold
evoLabel.Text = ""
evoLabel.Parent = panel

-- Info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 30)
infoLabel.Position = UDim2.new(0, 0, 0.6, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.TextScaled = true
infoLabel.Font = Enum.Font.Gotham
infoLabel.Text = "Open menu to evolve!"
infoLabel.Parent = panel

-- === ANIMATION ===
local isShowing = false

local function showEvolutionNotify(evoName)
	local evo = EvolutionTree[evoName]
	if not evo then return end

	evoLabel.Text = evoName .. " (Lv" .. evo.level .. ") - " .. evo.movementStyle

	-- Slide down from top
	panel.Position = UDim2.new(0.5, -200, 0, -130)
	local slideDown = TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0, 20),
	})
	slideDown:Play()

	isShowing = true

	-- Auto-hide after 5 seconds
	task.delay(5, function()
		if not isShowing then return end
		hideEvolutionNotify()
	end)
end

local function hideEvolutionNotify()
	isShowing = false
	local slideUp = TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -200, 0, -130),
	})
	slideUp:Play()
end

-- === LISTEN FOR EVOLUTION RESULT ===
local evolveResult = remotes:WaitForChild("EvolveResult")
evolveResult.OnClientEvent:Connect(function(data)
	if data and data.success and data.evolution then
		showEvolutionNotify(data.evolution)
	end
end)