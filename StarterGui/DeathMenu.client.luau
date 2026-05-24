local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage.Shared.Config)

-- Colors
local BG = Color3.fromRGB(15, 18, 30)
local PANEL = Color3.fromRGB(25, 30, 50)
local RED = Color3.fromRGB(255, 50, 50)
local GOLD = Color3.fromRGB(255, 200, 0)
local GREEN = Color3.fromRGB(0, 255, 100)
local ACCENT = Color3.fromRGB(0, 150, 255)
local WHITE = Color3.new(1, 1, 1)

-- === DEATH SCREEN GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "DeathMenu"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.Parent = gui

-- Death panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 400, 0, 350)
panel.Position = UDim2.new(0.5, -200, 0.5, -175)
panel.BackgroundColor3 = PANEL
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 15)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = RED
panelStroke.Thickness = 3
panelStroke.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.15, 0)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = RED
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "DESTROYED"
title.Parent = panel

-- Killer info
local killerLabel = Instance.new("TextLabel")
killerLabel.Name = "KillerInfo"
killerLabel.Size = UDim2.new(1, -20, 0.1, 0)
killerLabel.Position = UDim2.new(0, 10, 0.15, 0)
killerLabel.BackgroundTransparency = 1
killerLabel.TextColor3 = WHITE
killerLabel.TextScaled = true
killerLabel.Font = Enum.Font.GothamBold
killerLabel.Text = "Killed by: Unknown"
killerLabel.TextXAlignment = Enum.TextXAlignment.Left
killerLabel.Parent = panel

-- Level info
local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelInfo"
levelLabel.Size = UDim2.new(1, -20, 0.1, 0)
levelLabel.Position = UDim2.new(0, 10, 0.25, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.TextColor3 = ACCENT
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.GothamBold
levelLabel.Text = "Level: 1"
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = panel

-- === REVIVAL OPTIONS ===
local optionsLayout = Instance.new("UIListLayout")
optionsLayout.Padding = UDim.new(0, 8)
optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
optionsLayout.Parent = panel

local optionsPadding = Instance.new("UIPadding")
optionsPadding.PaddingTop = UDim.new(0, 140)
optionsPadding.PaddingLeft = UDim.new(0, 20)
optionsPadding.PaddingRight = UDim.new(0, 20)
optionsPadding.Parent = panel

-- Option 1: Keep Level (Medals)
local keepMedalsBtn = Instance.new("TextButton")
keepMedalsBtn.Name = "KeepLevelMedals"
keepMedalsBtn.Size = UDim2.new(1, 0, 0, 40)
keepMedalsBtn.BackgroundColor3 = GOLD
keepMedalsBtn.TextColor3 = Color3.new(0, 0, 0)
keepMedalsBtn.TextScaled = true
keepMedalsBtn.Font = Enum.Font.GothamBold
keepMedalsBtn.Text = "Keep Level (500 Medals)"
keepMedalsBtn.LayoutOrder = 1
keepMedalsBtn.Parent = panel

local kmCorner = Instance.new("UICorner")
kmCorner.CornerRadius = UDim.new(0, 8)
kmCorner.Parent = keepMedalsBtn

-- Option 2: Keep Level (Robux)
local keepRobuxBtn = Instance.new("TextButton")
keepRobuxBtn.Name = "KeepLevelRobux"
keepRobuxBtn.Size = UDim2.new(1, 0, 0, 40)
keepRobuxBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
keepRobuxBtn.TextColor3 = Color3.new(0, 0, 0)
keepRobuxBtn.TextScaled = true
keepRobuxBtn.Font = Enum.Font.GothamBold
keepRobuxBtn.Text = "Keep Level (R$25)"
keepRobuxBtn.LayoutOrder = 2
keepRobuxBtn.Parent = panel

local krCorner = Instance.new("UICorner")
krCorner.CornerRadius = UDim.new(0, 8)
krCorner.Parent = keepRobuxBtn

-- Option 3: Revenge Kill
local revengeBtn = Instance.new("TextButton")
revengeBtn.Name = "RevengeKill"
revengeBtn.Size = UDim2.new(1, 0, 0, 40)
revengeBtn.BackgroundColor3 = RED
revengeBtn.TextColor3 = WHITE
revengeBtn.TextScaled = true
revengeBtn.Font = Enum.Font.GothamBold
revengeBtn.Text = "Revenge Kill (Free)"
revengeBtn.LayoutOrder = 3
revengeBtn.Parent = panel

local rvCorner = Instance.new("UICorner")
rvCorner.CornerRadius = UDim.new(0, 8)
rvCorner.Parent = revengeBtn

-- Option 4: Watch Ad
local adBtn = Instance.new("TextButton")
adBtn.Name = "WatchAd"
adBtn.Size = UDim2.new(1, 0, 0, 40)
adBtn.BackgroundColor3 = ACCENT
adBtn.TextColor3 = WHITE
adBtn.TextScaled = true
adBtn.Font = Enum.Font.GothamBold
adBtn.Text = "Watch Ad (Keep Level)"
adBtn.LayoutOrder = 4
adBtn.Parent = panel

local adCorner = Instance.new("UICorner")
adCorner.CornerRadius = UDim.new(0, 8)
adCorner.Parent = adBtn

-- Option 5: Respawn at Level 1
local respawnBtn = Instance.new("TextButton")
respawnBtn.Name = "RespawnLevel1"
respawnBtn.Size = UDim2.new(1, 0, 0, 40)
respawnBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
respawnBtn.TextColor3 = GRAY
respawnBtn.TextScaled = true
respawnBtn.Font = Enum.Font.GothamBold
respawnBtn.Text = "Respawn at Level 1 (Free)"
respawnBtn.LayoutOrder = 5
respawnBtn.Parent = panel

local rpCorner = Instance.new("UICorner")
rpCorner.CornerRadius = UDim.new(0, 8)
rpCorner.Parent = respawnBtn

-- Option 6: Return to Lobby
local lobbyBtn = Instance.new("TextButton")
lobbyBtn.Name = "ReturnToLobby"
lobbyBtn.Size = UDim2.new(1, 0, 0, 40)
lobbyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
lobbyBtn.TextColor3 = WHITE
lobbyBtn.TextScaled = true
lobbyBtn.Font = Enum.Font.GothamBold
lobbyBtn.Text = "Return to Lobby"
lobbyBtn.LayoutOrder = 6
lobbyBtn.Parent = panel

local lbCorner = Instance.new("UICorner")
lbCorner.CornerRadius = UDim.new(0, 8)
lbCorner.Parent = lobbyBtn
local function closeDeathMenu()
	gui.Enabled = false
end

keepMedalsBtn.MouseButton1Click:Connect(function()
	local reviveChoice = remotes:FindFirstChild("ReviveChoice")
	if reviveChoice then
		reviveChoice:FireServer("KeepLevelMedals")
	end
	closeDeathMenu()
end)

keepRobuxBtn.MouseButton1Click:Connect(function()
	local reviveChoice = remotes:FindFirstChild("ReviveChoice")
	if reviveChoice then
		reviveChoice:FireServer("KeepLevelRobux")
	end
	closeDeathMenu()
end)

revengeBtn.MouseButton1Click:Connect(function()
	local reviveChoice = remotes:FindFirstChild("ReviveChoice")
	if reviveChoice then
		reviveChoice:FireServer("RevengeKill")
	end
	closeDeathMenu()
end)

adBtn.MouseButton1Click:Connect(function()
	local reviveChoice = remotes:FindFirstChild("ReviveChoice")
	if reviveChoice then
		reviveChoice:FireServer("WatchAd")
	end
	closeDeathMenu()
end)

respawnBtn.MouseButton1Click:Connect(function()
	local reviveChoice = remotes:FindFirstChild("ReviveChoice")
	if reviveChoice then
		reviveChoice:FireServer("RespawnLevel1")
	end
	closeDeathMenu()
end)

lobbyBtn.MouseButton1Click:Connect(function()
	local returnRemote = remotes:FindFirstChild("ReturnToLobby")
	if returnRemote then
		returnRemote:FireServer()
	end
	closeDeathMenu()
end)

-- === LISTEN FOR DEATH EVENT ===
local deathEvent = remotes:WaitForChild("DeathEvent")
deathEvent.OnClientEvent:Connect(function(data)
	gui.Enabled = true
	killerLabel.Text = "Killed by: " .. (data.killer or "Unknown")
	levelLabel.Text = "Level: " .. (data.level or 1)
	keepMedalsBtn.Text = "Keep Level (" .. (data.medalCost or 500) .. " Medals)"
	keepRobuxBtn.Text = "Keep Level (R$" .. (data.robuxCost or 25) .. ")"

	-- Disable ad button if max reached
	if data.adRevivalsUsed and data.maxAdRevivals then
		if data.adRevivalsUsed >= data.maxAdRevivals then
			adBtn.Text = "Watch Ad (" .. data.maxAdRevivals .. "/" .. data.maxAdRevivals .. " Used)"
			adBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			adBtn.TextColor3 = GRAY
		else
			adBtn.Text = "Watch Ad (" .. data.adRevivalsUsed .. "/" .. data.maxAdRevivals .. " Used)"
		end
	end

	-- Animate in
	panel.Position = UDim2.new(0.5, -200, 0.5, -175)
	panel.BackgroundTransparency = 1
	local tween = TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	})
	tween:Play()
end)