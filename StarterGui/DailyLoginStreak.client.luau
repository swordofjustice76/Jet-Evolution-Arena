local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Safely require Config with error handling
local Config
local ok, err = pcall(function()
	Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
end)
if not ok or not Config then
	warn("[DailyLoginStreak] Failed to load Config: " .. tostring(err))
	return
end

-- Colors
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
claimSound.PlaybackSpeed = 1.3
claimSound.Parent = script

-- === DAILY LOGIN STREAK GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "DailyLoginStreak"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Dark overlay
local overlay = Instance.new("TextButton")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Parent = gui

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 500, 0, 450)
panel.Position = UDim2.new(0.5, -250, 0.5, -225)
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
title.Text = "DAILY LOGIN STREAK"
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

-- Streak counter
local streakLabel = Instance.new("TextLabel")
streakLabel.Size = UDim2.new(1, -20, 0, 40)
streakLabel.Position = UDim2.new(0, 10, 0, 55)
streakLabel.BackgroundTransparency = 1
streakLabel.TextColor3 = CYAN
streakLabel.TextScaled = true
streakLabel.Font = Enum.Font.GothamBold
streakLabel.Text = "Current Streak: Day 1"
streakLabel.Parent = panel

-- Day cards container
local daysFrame = Instance.new("Frame")
daysFrame.Size = UDim2.new(1, -20, 0, 200)
daysFrame.Position = UDim2.new(0, 10, 0, 100)
daysFrame.BackgroundTransparency = 1
daysFrame.Parent = panel

local daysLayout = Instance.new("UIGridLayout")
daysLayout.CellSize = UDim2.new(0, 62, 0, 90)
daysLayout.CellPadding = UDim2.new(0, 6, 0, 6)
daysLayout.SortOrder = Enum.SortOrder.LayoutOrder
daysLayout.Parent = daysFrame

-- Build 7 day cards
local dayCards = {}
local loginRewards = Config.LOGIN_STREAK_REWARDS or {}

for day = 1, 7 do
	local reward = loginRewards[day]
	local card = Instance.new("Frame")
	card.Name = "Day" .. day
	card.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
	card.LayoutOrder = day
	card.Parent = daysFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = GRAY
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- Day number
	local dayLabel = Instance.new("TextLabel")
	dayLabel.Size = UDim2.new(1, 0, 0, 25)
	dayLabel.BackgroundTransparency = 1
	dayLabel.TextColor3 = WHITE
	dayLabel.TextScaled = true
	dayLabel.Font = Enum.Font.GothamBold
	dayLabel.Text = "Day " .. day
	dayLabel.Parent = card

	-- Reward text
	local rewardTexts = {}
	if reward then
		if reward.medals then table.insert(rewardTexts, tostring(reward.medals) .. "M") end
		if reward.xp then table.insert(rewardTexts, tostring(reward.xp) .. "XP") end
		if reward.chests then
			for ct, cnt in pairs(reward.chests) do
				table.insert(rewardTexts, tostring(cnt) .. "x" .. tostring(ct))
			end
		end
		if reward.boostMinutes then table.insert(rewardTexts, tostring(reward.boostMinutes) .. "min") end
	end

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, -4, 0, 55)
	rewardLabel.Position = UDim2.new(0, 2, 0, 25)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.TextColor3 = GOLD
	rewardLabel.TextScaled = true
	rewardLabel.Font = Enum.Font.Gotham
	rewardLabel.TextWrapped = true
	rewardLabel.Text = table.concat(rewardTexts, "\n")
	rewardLabel.Parent = card

	-- Claimed checkmark (hidden by default)
	local checkLabel = Instance.new("TextLabel")
	checkLabel.Name = "Check"
	checkLabel.Size = UDim2.new(1, 0, 0, 20)
	checkLabel.Position = UDim2.new(0, 0, 0, 70)
	checkLabel.BackgroundTransparency = 1
	checkLabel.TextColor3 = GREEN
	checkLabel.TextScaled = true
	checkLabel.Font = Enum.Font.GothamBold
	checkLabel.Text = ""
	checkLabel.Visible = false
	checkLabel.Parent = card

	dayCards[day] = {card = card, stroke = cardStroke, check = checkLabel}
end

-- Claim button
local claimBtn = Instance.new("TextButton")
claimBtn.Size = UDim2.new(0.6, 0, 0, 50)
claimBtn.Position = UDim2.new(0.2, 0, 0, 320)
claimBtn.BackgroundColor3 = GOLD
claimBtn.TextColor3 = Color3.new(0, 0, 0)
claimBtn.TextScaled = true
claimBtn.Font = Enum.Font.GothamBold
claimBtn.Text = "CLAIM TODAY'S REWARD"
claimBtn.Parent = panel

local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 10)
claimCorner.Parent = claimBtn

-- Result display
local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(0.9, 0, 0, 40)
resultLabel.Position = UDim2.new(0.05, 0, 0, 380)
resultLabel.BackgroundColor3 = Color3.fromRGB(0, 60, 0)
resultLabel.BackgroundTransparency = 0.5
resultLabel.TextColor3 = GREEN
resultLabel.TextScaled = true
resultLabel.Font = Enum.Font.GothamBold
resultLabel.Text = ""
resultLabel.Visible = false
resultLabel.Parent = panel

local resCorner = Instance.new("UICorner")
resCorner.CornerRadius = UDim.new(0, 8)
resCorner.Parent = resultLabel

-- === STATE ===
local currentStreak = 1
local todayClaimed = false

-- === UPDATE DISPLAY ===
local function updateDisplay()
	streakLabel.Text = "Current Streak: Day " .. currentStreak

	for day = 1, 7 do
		local dc = dayCards[day]
		if dc then
			if day < currentStreak then
				dc.stroke.Color = GREEN
				dc.check.Visible = true
				dc.check.Text = "\xe2\x9c\x93"
			elseif day == currentStreak then
				if todayClaimed then
					dc.stroke.Color = GREEN
					dc.check.Visible = true
				dc.check.Text = "\xe2\x9c\x93"
				else
					dc.stroke.Color = GOLD
					dc.check.Visible = false
				end
			else
				dc.stroke.Color = GRAY
				dc.check.Visible = false
			end
		end
	end

	if todayClaimed then
		claimBtn.Text = "ALREADY CLAIMED TODAY"
		claimBtn.BackgroundColor3 = GRAY
	else
		claimBtn.Text = "CLAIM DAY " .. currentStreak .. " REWARD"
		claimBtn.BackgroundColor3 = GOLD
	end
end

-- === CLAIM LOGIC ===
local claimRemote = remotes:WaitForChild("ClaimDailyLogin", 10)
claimBtn.MouseButton1Click:Connect(function()
	if todayClaimed then return end
	if claimRemote then
		claimBtn.Text = "CLAIMING..."
		claimBtn.BackgroundColor3 = GRAY
		claimRemote:FireServer()
	else
		warn("[DailyLoginStreak] ClaimDailyLogin remote not found")
	end
end)

-- Listen for claim result from server
local dailyLoginResult = remotes:WaitForChild("DailyLoginResult", 10)
if dailyLoginResult then
	dailyLoginResult.OnClientEvent:Connect(function(data)
		if not data then return end
		if data.streak then
			currentStreak = data.streak
		end
		if data.claimed ~= nil then
			todayClaimed = data.claimed
		end
		if data.success then
			resultLabel.Text = "Claimed Day " .. currentStreak .. " rewards!"
			resultLabel.Visible = true
			claimSound:Play()
			task.delay(4, function() resultLabel.Visible = false end)
		elseif data.claimed == true and data.success == false then
			-- Already claimed today — update state so button greys out
			resultLabel.Text = "Already claimed today!"
			resultLabel.Visible = true
			task.delay(3, function() resultLabel.Visible = false end)
		end
		updateDisplay()
	end)
else
	warn("[DailyLoginStreak] DailyLoginResult remote not found")
end

-- === OPEN / CLOSE ===
local function openDailyLogin()
	-- Close all other menus first
	if _G.CloseAllMenus then _G.CloseAllMenus() end
	gui.Enabled = true
	resultLabel.Visible = false

	-- Fetch current data from server
	local getData = remotes:WaitForChild("GetData", 10)
	if getData then
		task.spawn(function()
			local ok2, data = pcall(function()
				return getData:InvokeServer()
			end)
			if ok2 and data then
				currentStreak = data.LoginStreak or 1
				todayClaimed = data.DailyRewardClaimed or false
				updateDisplay()
			end
		end)
	end
end

local function closeDailyLogin()
	gui.Enabled = false
end

closeBtn.MouseButton1Click:Connect(closeDailyLogin)
overlay.MouseButton1Click:Connect(closeDailyLogin)

-- Expose open function globally
_G.OpenDailyLoginStreak = openDailyLogin

-- Auto-show on login if reward is claimable
task.delay(3, function()
	local getData = remotes:WaitForChild("GetData", 10)
	if getData then
		task.spawn(function()
			local ok2, data = pcall(function()
				return getData:InvokeServer()
			end)
			if ok2 and data and data.DailyRewardClaimed == false then
				openDailyLogin()
			end
		end)
	end
end)

print("[DailyLoginStreak] Initialized")