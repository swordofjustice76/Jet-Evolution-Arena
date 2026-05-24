local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage.Shared.Config)

-- Colors
local BG = Color3.fromRGB(15, 18, 30)
local PANEL = Color3.fromRGB(25, 30, 50)
local GOLD = Color3.fromRGB(255, 200, 0)
local GREEN = Color3.fromRGB(0, 255, 100)
local WHITE = Color3.new(1, 1, 1)
local GRAY = Color3.fromRGB(150, 150, 150)
local CYAN = Color3.fromRGB(0, 200, 255)

-- Claim sound
local claimSound = Instance.new("Sound")
claimSound.SoundId = "rbxassetid://6895079853"
claimSound.Volume = 0.7
claimSound.PlaybackSpeed = 1.2
claimSound.Parent = script

-- === INCREMENTAL REWARDS GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "IncrementalRewards"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Dark overlay (TextButton so clicks close the menu)
local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Parent = gui

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 450, 0, 500)
panel.Position = UDim2.new(0.5, -225, 0.5, -250)
panel.BackgroundColor3 = PANEL
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 15)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = GOLD
panelStroke.Thickness = 3
panelStroke.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(30, 20, 0)
title.BackgroundTransparency = 0.5
title.TextColor3 = GOLD
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "INCREMENTAL REWARDS"
title.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = title

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = WHITE
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Playtime display
local playtimeLabel = Instance.new("TextLabel")
playtimeLabel.Size = UDim2.new(1, -20, 0, 30)
playtimeLabel.Position = UDim2.new(0, 10, 0, 55)
playtimeLabel.BackgroundTransparency = 1
playtimeLabel.TextColor3 = CYAN
playtimeLabel.TextScaled = true
playtimeLabel.Font = Enum.Font.GothamBold
playtimeLabel.Text = "Playtime: 0s"
playtimeLabel.Parent = panel

-- Next reward progress bar
local progressFrame = Instance.new("Frame")
progressFrame.Size = UDim2.new(1, -20, 0, 30)
progressFrame.Position = UDim2.new(0, 10, 0, 90)
progressFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
progressFrame.BorderSizePixel = 0
progressFrame.Parent = panel

local progCorner = Instance.new("UICorner")
progCorner.CornerRadius = UDim.new(0, 8)
progCorner.Parent = progressFrame

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = GOLD
progressFill.BorderSizePixel = 0
progressFill.Parent = progressFrame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 8)
fillCorner.Parent = progressFill

local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(1, 0, 1, 0)
progressLabel.BackgroundTransparency = 1
progressLabel.TextColor3 = WHITE
progressLabel.TextScaled = true
progressLabel.Font = Enum.Font.GothamBold
progressLabel.Text = "Next reward in: --"
progressLabel.Parent = progressFrame

-- Rewards list
local rewardsScroll = Instance.new("ScrollingFrame")
rewardsScroll.Size = UDim2.new(1, -20, 0, 300)
rewardsScroll.Position = UDim2.new(0, 10, 0, 130)
rewardsScroll.BackgroundTransparency = 1
rewardsScroll.ScrollBarThickness = 6
rewardsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
rewardsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rewardsScroll.Parent = panel

local rewardsLayout = Instance.new("UIListLayout")
rewardsLayout.Padding = UDim.new(0, 6)
rewardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
rewardsLayout.Parent = rewardsScroll

-- Build reward cards
local rewardCards = {}
for i, reward in ipairs(Config.PLAYTIME_REWARDS) do
	local card = Instance.new("Frame")
	card.Name = "Reward_" .. reward.time
	card.Size = UDim2.new(1, 0, 0, 50)
	card.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
	card.LayoutOrder = i
	card.Parent = rewardsScroll

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = GRAY
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- Time label
	local timeStr = ""
	if reward.time < 60 then
		timeStr = reward.time .. "s"
	elseif reward.time < 3600 then
		timeStr = (reward.time / 60) .. "min"
	else
		timeStr = (reward.time / 3600) .. "hr"
	end

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(0.3, 0, 1, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = CYAN
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.Text = timeStr
	timeLabel.Parent = card

	-- Reward text
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(0.4, 0, 1, 0)
	rewardLabel.Position = UDim2.new(0.3, 0, 0, 0)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.TextColor3 = GOLD
	rewardLabel.TextScaled = true
	rewardLabel.Font = Enum.Font.Gotham
	rewardLabel.Text = reward.xp .. " XP | " .. reward.medals .. " Medals"
	rewardLabel.Parent = card

	-- Claim button
	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimBtn"
	claimBtn.Size = UDim2.new(0.25, -5, 0, 35)
	claimBtn.Position = UDim2.new(0.72, 0, 0, 7)
	claimBtn.BackgroundColor3 = GRAY
	claimBtn.TextColor3 = WHITE
	claimBtn.TextScaled = true
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.Text = "LOCKED"
claimBtn.Parent = card

	local claimCorner = Instance.new("UICorner")
	claimCorner.CornerRadius = UDim.new(0, 6)
	claimCorner.Parent = claimBtn

	rewardCards[i] = {
		card = card,
		stroke = cardStroke,
		claimBtn = claimBtn,
		time = reward.time,
	}
end

-- === STATE ===
local totalPlayTime = 0
local claimedTimes = {}

-- === UPDATE DISPLAY ===
local function updateDisplay()
	playtimeLabel.Text = "Playtime: " .. math.floor(totalPlayTime) .. "s"

	-- Find next unclaimed reward
	local nextRewardTime = nil
	for i, reward in ipairs(Config.PLAYTIME_REWARDS) do
		local isClaimed = false
		for _, t in claimedTimes do
			if t == reward.time then isClaimed = true; break end
		end

		local dc = rewardCards[i]
		if isClaimed then
			dc.stroke.Color = GREEN
			dc.claimBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
			dc.claimBtn.Text = "CLAIMED"
		elseif totalPlayTime >= reward.time then
			dc.stroke.Color = GOLD
			dc.claimBtn.BackgroundColor3 = GOLD
			dc.claimBtn.Text = "CLAIM"
			if not nextRewardTime then nextRewardTime = reward.time end
		else
			dc.stroke.Color = GRAY
			dc.claimBtn.BackgroundColor3 = GRAY
			dc.claimBtn.Text = "LOCKED"
			if not nextRewardTime then nextRewardTime = reward.time end
		end
	end

	-- Update progress bar
	if nextRewardTime then
		local prevTime = 0
		for i, reward in ipairs(Config.PLAYTIME_REWARDS) do
			if reward.time == nextRewardTime then
				prevTime = (i > 1) and Config.PLAYTIME_REWARDS[i-1].time or 0
				break
			end
		end
		local progress = math.clamp((totalPlayTime - prevTime) / (nextRewardTime - prevTime), 0, 1)
		progressFill.Size = UDim2.new(progress, 0, 1, 0)
		local remaining = math.max(0, nextRewardTime - totalPlayTime)
		local remainStr = ""
		if remaining < 60 then remainStr = math.ceil(remaining) .. "s"
		else remainStr = string.format("%.1fmin", remaining / 60) end
		progressLabel.Text = "Next reward in: " .. remainStr
	else
		progressFill.Size = UDim2.new(1, 0, 1, 0)
		progressLabel.Text = "All rewards claimed!"
	end
end

-- === CLAIM LOGIC ===
for i, rc in rewardCards do
	rc.claimBtn.MouseButton1Click:Connect(function()
		if totalPlayTime < rc.time then return end
		local isClaimed = false
		for _, t in claimedTimes do
			if t == rc.time then isClaimed = true; break end
		end
		if isClaimed then return end

		local claimRemote = remotes:FindFirstChild("ClaimPlaytimeReward")
		if claimRemote then
			claimRemote:FireServer(rc.time)
		end
	end)
end

-- Listen for results
local playtimeResult = remotes:FindFirstChild("PlaytimeRewardResult")
if playtimeResult then
	playtimeResult.OnClientEvent:Connect(function(data)
		if data.available then
			-- A new reward is available, refresh
			updateDisplay()
		elseif data.success then
			table.insert(claimedTimes, data.time)
			claimSound:Play()
			updateDisplay()
		end
	end)
end

-- === OPEN / CLOSE ===
local function openIncrementalRewards()
	-- Close all other menus first
	if _G.CloseAllMenus then _G.CloseAllMenus() end
	gui.Enabled = true

	-- Fetch current data
	local getData = remotes:FindFirstChild("GetData")
	if getData then
		task.spawn(function()
			local data = getData:InvokeServer()
			if data then
				totalPlayTime = data.TotalPlayTime or 0
				claimedTimes = data.PlaytimeRewardsClaimed or {}
				updateDisplay()
			end
		end)
	end
end

local function closeIncrementalRewards()
	gui.Enabled = false
end

closeBtn.MouseButton1Click:Connect(closeIncrementalRewards)
overlay.MouseButton1Click:Connect(closeIncrementalRewards)

-- Expose open function
_G.OpenIncrementalRewards = openIncrementalRewards

-- Update playtime from server periodically
task.spawn(function()
	while true do
		task.wait(5)
		if gui.Enabled then
			local getData = remotes:FindFirstChild("GetData")
			if getData then
				local data = getData:InvokeServer()
				if data then
					totalPlayTime = data.TotalPlayTime or 0
					claimedTimes = data.PlaytimeRewardsClaimed or {}
					updateDisplay()
				end
			end
		end
	end
end)

print("[IncrementalRewards] Initialized")