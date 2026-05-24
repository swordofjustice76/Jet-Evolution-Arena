local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local AbilityDefs = require(ReplicatedStorage.Shared.AbilityDefs)

-- Ability UI overlay
local abilityGui = Instance.new("ScreenGui")
abilityGui.Name = "AbilityUI"
abilityGui.ResetOnSpawn = false
abilityGui.Parent = player:WaitForChild("PlayerGui")

-- Cooldown overlay on ability slot
local cooldownOverlay = Instance.new("Frame")
cooldownOverlay.Name = "CooldownOverlay"
cooldownOverlay.Size = UDim2.new(0, 70, 0, 70)
cooldownOverlay.Position = UDim2.new(1, -80, 0.85, -80)
cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
cooldownOverlay.BackgroundTransparency = 0.5
cooldownOverlay.BorderSizePixel = 0
cooldownOverlay.Visible = false
cooldownOverlay.ZIndex = 10
cooldownOverlay.Parent = abilityGui

local cdCorner = Instance.new("UICorner")
cdCorner.CornerRadius = UDim.new(0, 10)
cdCorner.Parent = cooldownOverlay

local cdText = Instance.new("TextLabel")
cdText.Size = UDim2.new(1, 0, 1, 0)
cdText.BackgroundTransparency = 1
cdText.TextColor3 = Color3.new(1, 1, 1)
cdText.TextScaled = true
cdText.Font = Enum.Font.GothamBold
cdText.Text = ""
cdText.ZIndex = 11
cdText.Parent = cooldownOverlay

-- Current ability state
local currentAbility = ""
local currentCharges = 0
local cooldownEnd = 0

-- Q key activation (disabled in lobby)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		if currentAbility == "" then return end

		-- Block ability use in lobby - only works in arena
		if not player:GetAttribute("InArena") then
			cdText.Text = "ARENA ONLY"
			cooldownOverlay.Visible = true
			task.delay(1.5, function()
				if os.clock() >= cooldownEnd then
					cooldownOverlay.Visible = false
					cdText.Text = ""
				end
			end)
			return
		end

		local useAbility = remotes:FindFirstChild("UseAbility")
		if useAbility then
			useAbility:FireServer(currentAbility)
		end
	end
end)

-- Listen for ability results
local abilityResult = remotes:WaitForChild("AbilityResult")
abilityResult.OnClientEvent:Connect(function(data)
	if data.success then
		currentCharges = data.chargesLeft or 0

		-- Show cooldown
		if currentAbility ~= "" then
			local def = AbilityDefs.GetByID(currentAbility)
			if def and def.cooldown > 0 then
				cooldownEnd = os.clock() + def.cooldown
				cooldownOverlay.Visible = true
			end
		end

		-- Flash effect
		cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
		task.delay(0.2, function()
			cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		end)
	else
		-- Show error briefly
		cdText.Text = data.error or "Error"
		cooldownOverlay.Visible = true
		task.delay(2, function()
			if os.clock() >= cooldownEnd then
				cooldownOverlay.Visible = false
			end
		end)
	end
end)

-- Cooldown countdown
game:GetService("RunService").Heartbeat:Connect(function()
	if cooldownOverlay.Visible and os.clock() < cooldownEnd then
		local remaining = math.ceil(cooldownEnd - os.clock())
		cdText.Text = tostring(remaining)
	elseif cooldownOverlay.Visible then
		cooldownOverlay.Visible = false
		cdText.Text = ""
	end
end)

-- Sync ability data from server
local updateClient = remotes:WaitForChild("UpdateClient")
updateClient.OnClientEvent:Connect(function(data)
	if data.EquippedAbility then
		currentAbility = data.EquippedAbility
	end
	if data.AbilityCharges and currentAbility ~= "" then
		currentCharges = data.AbilityCharges[currentAbility] or 0
	end
end)

-- Hide ability overlay in lobby, show in arena
task.spawn(function()
	while true do
		task.wait(0.5)
		if not player:GetAttribute("InArena") then
			cooldownOverlay.Visible = false
		end
	end
end)