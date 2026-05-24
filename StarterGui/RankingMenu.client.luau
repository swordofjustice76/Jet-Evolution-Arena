local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RankDefs = require(ReplicatedStorage.Shared.RankDefs)

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
claimSound.PlaybackSpeed = 1.4
claimSound.Parent = script

-- === RANKING MENU GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "RankingMenu"
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
panel.Size = UDim2.new(0, 500, 0, 550)
panel.Position = UDim2.new(0.5, -250, 0.5, -275)
panel.BackgroundColor3 = PANEL
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 15)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(200, 150, 255)
panelStroke.Thickness = 3
panelStroke.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(30, 15, 50)
title.BackgroundTransparency = 0.5
title.TextColor3 = Color3.fromRGB(200, 150, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "RANKING SYSTEM"
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

-- Current rank display
local currentRankFrame = Instance.new("Frame")
currentRankFrame.Size = UDim2.new(1, -20, 0, 60)
currentRankFrame.Position = UDim2.new(0, 10, 0, 55)
currentRankFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
currentRankFrame.BorderSizePixel = 0
currentRankFrame.Parent = panel

local crCorner = Instance.new("UICorner")
crCorner.CornerRadius = UDim.new(0, 10)
crCorner.Parent = currentRankFrame

local crStroke = Instance.new("UIStroke")
crStroke.Color = GOLD
crStroke.Thickness = 2
crStroke.Parent = currentRankFrame

local currentRankLabel = Instance.new("TextLabel")
currentRankLabel.Size = UDim2.new(0.5, 0, 1, 0)
currentRankLabel.BackgroundTransparency = 1
currentRankLabel.TextColor3 = GOLD
currentRankLabel.TextScaled = true
currentRankLabel.Font = Enum.Font.GothamBold
currentRankLabel.Text = "Iron 1"
currentRankLabel.TextXAlignment = Enum.TextXAlignment.Left
currentRankLabel.Parent = currentRankFrame

local rankXPLabel = Instance.new("TextLabel")
rankXPLabel.Size = UDim2.new(0.5, 0, 1, 0)
rankXPLabel.Position = UDim2.new(0.5, 0, 0, 0)
rankXPLabel.BackgroundTransparency = 1
rankXPLabel.TextColor3 = CYAN
rankXPLabel.TextScaled = true
rankXPLabel.Font = Enum.Font.Gotham
rankXPLabel.Text = "0 / 100 XP"
rankXPLabel.TextXAlignment = Enum.TextXAlignment.Right
rankXPLabel.Parent = currentRankFrame

-- Rank progress bar
local progFrame = Instance.new("Frame")
progFrame.Size = UDim2.new(1, -20, 0, 20)
progFrame.Position = UDim2.new(0, 10, 0, 120)
progFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
progFrame.BorderSizePixel = 0
progFrame.Parent = panel

local progCorner = Instance.new("UICorner")
progCorner.CornerRadius = UDim.new(0, 8)
progCorner.Parent = progFrame

local progFill = Instance.new("Frame")
progFill.Size = UDim2.new(0, 0, 1, 0)
progFill.BackgroundColor3 = GOLD
progFill.BorderSizePixel = 0
progFill.Parent = progFrame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 8)
fillCorner.Parent = progFill

local progLabel = Instance.new("TextLabel")
progLabel.Size = UDim2.new(1, 0, 1, 0)
progLabel.BackgroundTransparency = 1
progLabel.TextColor3 = WHITE
progLabel.TextScaled = true
progLabel.Font = Enum.Font.GothamBold
progLabel.Text = "0%"
progLabel.Parent = progFrame

-- Claim rank up reward button (hidden by default)
local claimRankBtn = Instance.new("TextButton")
claimRankBtn.Size = UDim2.new(0.8, 0, 0, 45)
claimRankBtn.Position = UDim2.new(0.1, 0, 0, 150)
claimRankBtn.BackgroundColor3 = GOLD
claimRankBtn.TextColor3 = Color3.new(0, 0, 0)
claimRankBtn.TextScaled = true
claimRankBtn.Font = Enum.Font.GothamBold
claimRankBtn.Text = "CLAIM RANK UP REWARD!"
claimRankBtn.Visible = false
claimRankBtn.Parent = panel

local claimRankCorner = Instance.new("UICorner")
claimRankCorner.CornerRadius = UDim.new(0, 10)
claimRankCorner.Parent = claimRankBtn

-- Rank list
local rankScroll = Instance.new("ScrollingFrame")
rankScroll.Size = UDim2.new(1, -20, 0, 310)
rankScroll.Position = UDim2.new(0, 10, 0, 205)
rankScroll.BackgroundTransparency = 1
rankScroll.ScrollBarThickness = 6
rankScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
rankScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
rankScroll.Parent = panel

local rankLayout = Instance.new("UIListLayout")
rankLayout.Padding = UDim.new(0, 4)
rankLayout.SortOrder = Enum.SortOrder.LayoutOrder
rankLayout.Parent = rankScroll

-- Build rank list
local allRanks = {}
for rankName, rankData in pairs(RankDefs) do
	if type(rankData) == "table" and rankData.tier then
		table.insert(allRanks, {name = rankName, tier = rankData.tier, sub = rankData.sub, xpRequired = rankData.xpRequired, next = rankData.next})
	end
end
table.sort(allRanks, function(a, b) return a.xpRequired < b.xpRequired end)

for i, rankInfo in ipairs(allRanks) do
	local tierColors = RankDefs.TierColors[rankInfo.tier]
	local tierColor = tierColors and Color3.new(tierColors.r, tierColors.g, tierColors.b) or GRAY

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 35)
	card.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
	card.LayoutOrder = i
	card.Parent = rankScroll

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 6)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = tierColor
	cardStroke.Thickness = 1
	cardStroke.Transparency = 0.5
	cardStroke.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = tierColor
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = RankDefs.GetDisplay(rankInfo.name)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.new(0.6, 0, 1, 0)
	xpLabel.Position = UDim2.new(0.4, 0, 0, 0)
	xpLabel.BackgroundTransparency = 1
	xpLabel.TextColor3 = GRAY
	xpLabel.TextScaled = true
	xpLabel.Font = Enum.Font.Gotham
	xpLabel.Text = rankInfo.xpRequired .. " Rank XP"
	xpLabel.TextXAlignment = Enum.TextXAlignment.Right
	xpLabel.Parent = card

	card.Name = "RankCard_" .. rankInfo.name
end

-- === STATE ===
local currentRank = "Iron1"
local currentRankXP = 0
local pendingReward = ""

-- === UPDATE DISPLAY ===
local function updateDisplay()
	local display = RankDefs.GetDisplay(currentRank)
	local tier = RankDefs.GetTier(currentRank)
	local tierColors = RankDefs.TierColors[tier]
	local tierColor = tierColors and Color3.new(tierColors.r, tierColors.g, tierColors.b) or GRAY

	currentRankLabel.Text = display
	currentRankLabel.TextColor3 = tierColor

	-- Progress bar
	local rankData = RankDefs[currentRank]
	local nextRankName = rankData and rankData.next
	if nextRankName and RankDefs[nextRankName] then
		local nextXP = RankDefs[nextRankName].xpRequired
		local currentXP = rankData.xpRequired
		local progress = math.clamp((currentRankXP - currentXP) / (nextXP - currentXP), 0, 1)
		progFill.Size = UDim2.new(progress, 0, 1, 0)
		rankXPLabel.Text = currentRankXP .. " / " .. nextXP .. " XP"
		progLabel.Text = math.floor(progress * 100) .. "%"
	else
		progFill.Size = UDim2.new(1, 0, 1, 0)
		rankXPLabel.Text = "MAX RANK"
		progLabel.Text = "MAX"
	end

	-- Highlight current rank in list
	for _, child in rankScroll:GetChildren() do
		if child:IsA("Frame") and child.Name == "RankCard_" .. currentRank then
			child.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
		end
	end

	-- Show claim button if pending reward
	claimRankBtn.Visible = pendingReward ~= "" and pendingReward ~= nil
end

-- === CLAIM RANK UP REWARD ===
claimRankBtn.MouseButton1Click:Connect(function()
	local claimRemote = remotes:FindFirstChild("ClaimRankUpReward")
	if claimRemote then
		claimRemote:FireServer()
	end
end)

local rankUpRewardResult = remotes:FindFirstChild("RankUpRewardResult")
if rankUpRewardResult then
	rankUpRewardResult.OnClientEvent:Connect(function(data)
		if data.success then
			claimSound:Play()
			pendingReward = ""
			claimRankBtn.Visible = false
			updateDisplay()
		end
	end)
end

-- Listen for rank up events
local rankUpRemote = remotes:FindFirstChild("RankUp")
if rankUpRemote then
	rankUpRemote.OnClientEvent:Connect(function(data)
		if data.rank then
			currentRank = data.rank
			pendingReward = data.rank
			updateDisplay()
		end
	end)
end

-- === OPEN / CLOSE ===
local function openRankingMenu()
	-- Close all other menus first
	if _G.CloseAllMenus then _G.CloseAllMenus() end
	gui.Enabled = true

	local getData = remotes:FindFirstChild("GetData")
	if getData then
		task.spawn(function()
			local data = getData:InvokeServer()
			if data then
				currentRank = data.Rank or "Iron1"
				currentRankXP = data.RankXP or 0
				pendingReward = data.PendingRankUpReward or ""
				updateDisplay()
			end
		end)
	end
end

local function closeRankingMenu()
	gui.Enabled = false
end

closeBtn.MouseButton1Click:Connect(closeRankingMenu)
overlay.MouseButton1Click:Connect(closeRankingMenu)

-- Expose open function
_G.OpenRankingMenu = openRankingMenu

print("[RankingMenu] Initialized")