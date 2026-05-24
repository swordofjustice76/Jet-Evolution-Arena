local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Colors
local RED = Color3.fromRGB(255, 50, 50)
local GOLD = Color3.fromRGB(255, 200, 0)
local GREEN = Color3.fromRGB(0, 255, 100)
local WHITE = Color3.new(1, 1, 1)

-- === DAMAGE NUMBERS GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "DamageNumbers"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local camera = workspace.CurrentCamera
local activeNumbers = {}

local function createDamageNumber(position, amount, isHeal)
	local screenPos, onScreen = camera:WorldToScreenPoint(position)
	if not onScreen then return end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 100, 0, 40)
	label.Position = UDim2.new(0, screenPos.X - 50, 0, screenPos.Y - 20)
	label.BackgroundTransparency = 1
	label.TextColor3 = isHeal and GREEN or (amount >= 50 and GOLD or RED)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = isHeal and ("+" .. math.floor(amount)) or ("-" .. math.floor(amount))
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = gui

	-- Animate: float up and fade out
	local startY = screenPos.Y - 20
	local endY = startY - 60

	local floatTween = TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, screenPos.X - 50 + math.random(-20, 20), 0, endY),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})

	floatTween:Play()
	floatTween.Completed:Connect(function()
		label.Parent = nil
		for i, num in ipairs(activeNumbers) do
			if num == label then
				table.remove(activeNumbers, i)
				break
			end
		end
	end)

	table.insert(activeNumbers, label)

	-- Limit active numbers
	while #activeNumbers > 20 do
		local oldest = activeNumbers[1]
		table.remove(activeNumbers, 1)
		if oldest and oldest.Parent then
			oldest.Parent = nil
		end
	end
end

-- === LISTEN FOR DAMAGE NUMBER EVENTS ===
local damageNumber = remotes:WaitForChild("DamageNumber")
damageNumber.OnClientEvent:Connect(function(data)
	if data and data.position and data.amount then
		createDamageNumber(data.position, data.amount, data.isHeal)
	end
end)