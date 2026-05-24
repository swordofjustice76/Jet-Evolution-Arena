local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Colors
local GOLD = Color3.fromRGB(255, 200, 0)
local GREEN = Color3.fromRGB(0, 255, 100)
local RED = Color3.fromRGB(255, 50, 50)
local WHITE = Color3.new(1, 1, 1)

-- === PURCHASE RESULT GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "PurchaseResult"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Notification panel (center-top)
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 350, 0, 60)
panel.Position = UDim2.new(0.5, -175, 0, -70)
panel.BackgroundColor3 = Color3.fromRGB(10, 30, 10)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Name = "Stroke"
panelStroke.Color = GREEN
panelStroke.Thickness = 2
panelStroke.Parent = panel

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, 0, 1, 0)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = WHITE
resultLabel.TextScaled = true
resultLabel.Font = Enum.Font.GothamBold
resultLabel.Text = ""
resultLabel.Parent = panel

-- === ANIMATION ===
local function showResult(data)
	if not data then return end

	if data.success then
		resultLabel.Text = "Purchase Successful!"
		resultLabel.TextColor3 = GREEN
		panelStroke.Color = GREEN
		panel.BackgroundColor3 = Color3.fromRGB(10, 30, 10)
	elseif data.pending then
		resultLabel.Text = "Processing Purchase..."
		resultLabel.TextColor3 = GOLD
		panelStroke.Color = GOLD
		panel.BackgroundColor3 = Color3.fromRGB(30, 25, 0)
	else
		resultLabel.Text = data.reason or "Purchase Failed"
		resultLabel.TextColor3 = RED
		panelStroke.Color = RED
		panel.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
	end

	-- Slide down
	panel.Position = UDim2.new(0.5, -175, 0, -70)
	local slideDown = TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -175, 0, 20),
	})
	slideDown:Play()

	-- Auto-hide
	task.delay(3, function()
		local slideUp = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -175, 0, -70),
		})
		slideUp:Play()
	end)
end

-- === LISTEN FOR PURCHASE RESULT ===
local purchaseResult = remotes:WaitForChild("PurchaseResult")
purchaseResult.OnClientEvent:Connect(showResult)

-- Also listen for ability and evolve results
local abilityResult = remotes:WaitForChild("AbilityResult")
abilityResult.OnClientEvent:Connect(function(data)
	if data then
		if data.success then
			showResult({success = true})
		else
			showResult({success = false, reason = data.reason or "Ability failed"})
		end
	end
end)

local evolveResult = remotes:WaitForChild("EvolveResult")
evolveResult.OnClientEvent:Connect(function(data)
	if data and not data.success then
		showResult({success = false, reason = data.reason or "Evolution failed"})
	end
end)

local statResult = remotes:WaitForChild("StatResult")
statResult.OnClientEvent:Connect(function(data)
	if data and not data.success then
		showResult({success = false, reason = data.reason or "Stat upgrade failed"})
	end
end)