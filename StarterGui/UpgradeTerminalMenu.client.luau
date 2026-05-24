local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then return end
local ok_evo, EvolutionTree = pcall(function() return require(ReplicatedStorage.Shared.EvolutionTree) end)
EvolutionTree = ok_evo and EvolutionTree or {}

local ok_ability, AbilityDefs = pcall(function() return require(ReplicatedStorage.Shared.AbilityDefs) end)
AbilityDefs = ok_ability and AbilityDefs or { GetAll = function() return {} end, GetByID = function() return nil end }

local ok_rank, RankDefs = pcall(function() return require(ReplicatedStorage.Shared.RankDefs) end)
RankDefs = ok_rank and RankDefs or { GetDisplay = function() return "?" end }

local ok_config, Config = pcall(function() return require(ReplicatedStorage.Shared.Config) end)
Config = ok_config and Config or { STAT_NAMES = {}, MAX_STAT_LEVEL = 100, STAT_SCALE = {} }

-- Premium Color Palette
local BG_DARK = Color3.fromRGB(8, 10, 20)
local BG_PANEL = Color3.fromRGB(15, 20, 35)
local BG_CARD = Color3.fromRGB(22, 28, 48)
local BG_CARD_HOVER = Color3.fromRGB(30, 38, 65)
local ACCENT_CYAN = Color3.fromRGB(0, 180, 255)
local ACCENT_GOLD = Color3.fromRGB(255, 200, 0)
local ACCENT_GREEN = Color3.fromRGB(0, 255, 120)
local ACCENT_RED = Color3.fromRGB(255, 60, 60)
local ACCENT_PURPLE = Color3.fromRGB(160, 80, 255)
local ACCENT_ORANGE = Color3.fromRGB(255, 140, 0)
local WHITE = Color3.new(1, 1, 1)
local GRAY = Color3.fromRGB(140, 140, 160)
local GRAY_DARK = Color3.fromRGB(80, 80, 100)

-- Player data cache
local playerData = nil
local currentEvolution = "Starter"
local playerLevel = 1
local statPoints = 0
local playerStats = {}
local ownedAbilities = {}
local equippedAbility = ""
local playerRank = "Iron1"
local playerMedals = 0

-- Helper functions
local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

-- === MAIN GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "UpgradeTerminalMenu"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Full-screen dark backdrop (clickable to close)
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = BG_DARK
backdrop.BackgroundTransparency = 0.3
backdrop.BorderSizePixel = 0
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Parent = gui

backdrop.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

-- === MAIN CONTAINER ===
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0.7, 0, 0.85, 0)
container.Position = UDim2.new(0.15, 0, 0.075, 0)
container.BackgroundColor3 = BG_PANEL
container.BorderSizePixel = 0
container.Parent = gui
corner(container, 16)
stroke(container, ACCENT_GREEN, 2)

-- === HEADER BAR ===
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 55)
header.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
header.BorderSizePixel = 0
header.Parent = container
corner(header, 12)

-- Header glow line
local headerGlow = Instance.new("Frame")
headerGlow.Size = UDim2.new(1, 0, 0, 2)
headerGlow.Position = UDim2.new(0, 0, 1, -2)
headerGlow.BackgroundColor3 = ACCENT_GREEN
headerGlow.BackgroundTransparency = 0.3
headerGlow.BorderSizePixel = 0
headerGlow.Parent = header

-- Header icon
local headerIcon = Instance.new("TextLabel")
headerIcon.Size = UDim2.new(0, 50, 1, 0)
headerIcon.Position = UDim2.new(0, 15, 0, 0)
headerIcon.BackgroundTransparency = 1
headerIcon.TextColor3 = ACCENT_GREEN
headerIcon.TextScaled = true
headerIcon.Font = Enum.Font.GothamBold
headerIcon.Text = "⬆"
headerIcon.Parent = header

-- Header title
local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.5, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 65, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.TextColor3 = WHITE
headerTitle.TextScaled = true
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "UPGRADE TERMINAL"
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

-- Stat points display in header
local pointsDisplay = Instance.new("TextLabel")
pointsDisplay.Name = "PointsDisplay"
pointsDisplay.Size = UDim2.new(0.25, 0, 1, 0)
pointsDisplay.Position = UDim2.new(0.55, 0, 0, 0)
pointsDisplay.BackgroundTransparency = 1
pointsDisplay.TextColor3 = ACCENT_GOLD
pointsDisplay.TextScaled = true
pointsDisplay.Font = Enum.Font.GothamBold
pointsDisplay.Text = "Points: 0"
pointsDisplay.TextXAlignment = Enum.TextXAlignment.Right
pointsDisplay.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 44, 0, 44)
closeBtn.Position = UDim2.new(1, -55, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
closeBtn.TextColor3 = ACCENT_RED
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "✕"
closeBtn.Parent = header
corner(closeBtn, 10)
stroke(closeBtn, ACCENT_RED, 1)

closeBtn.MouseButton1Click:Connect(function()
	local tween = TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	})
	tween:Play()
	tween.Completed:Connect(function()
		gui.Enabled = false
		container.Size = UDim2.new(0.7, 0, 0.85, 0)
		container.Position = UDim2.new(0.15, 0, 0.075, 0)
	end)
end)

-- === TAB BAR ===
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, 45)
tabBar.Position = UDim2.new(0, 0, 0, 55)
tabBar.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
tabBar.BorderSizePixel = 0
tabBar.Parent = container

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

-- Tab definitions
local tabs = {
	{name = "STATS", color = ACCENT_CYAN, icon = "📊"},
	{name = "EVOLUTIONS", color = ACCENT_PURPLE, icon = "🧬"},
	{name = "ABILITIES", color = ACCENT_ORANGE, icon = "⚡"},
}

local tabButtons = {}
local tabFrames = {}
local activeTab = "STATS"

for i, tab in ipairs(tabs) do
	local btn = Instance.new("TextButton")
	btn.Name = tab.name .. "Tab"
	btn.Size = UDim2.new(0.333, 0, 1, 0)
	btn.BackgroundColor3 = BG_PANEL
	btn.TextColor3 = GRAY
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Text = tab.icon .. " " .. tab.name
	btn.LayoutOrder = i
	btn.Parent = tabBar
	corner(btn, 0)

	-- Active indicator bar
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(1, 0, 0, 3)
	indicator.Position = UDim2.new(0, 0, 1, -3)
	indicator.BackgroundColor3 = tab.color
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel = 0
	indicator.Parent = btn

	tabButtons[tab.name] = {btn = btn, indicator = indicator, color = tab.color}

	btn.MouseButton1Click:Connect(function()
		switchTab(tab.name)
	end)
end

-- === CONTENT AREA ===
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -20, 1, -120)
contentArea.Position = UDim2.new(0, 10, 0, 110)
contentArea.BackgroundTransparency = 1
contentArea.Parent = container

-- ==========================
-- TAB 1: STATS
-- ==========================
local statsFrame = Instance.new("ScrollingFrame")
statsFrame.Name = "StatsTab"
statsFrame.Size = UDim2.new(1, 0, 1, 0)
statsFrame.BackgroundTransparency = 1
statsFrame.ScrollBarThickness = 4
statsFrame.ScrollBarImageColor3 = ACCENT_CYAN
statsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
statsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
statsFrame.Visible = true
statsFrame.Parent = contentArea

local statsLayout = Instance.new("UIListLayout")
statsLayout.Padding = UDim.new(0, 8)
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Parent = statsFrame

local statCards = {}
local STAT_NAMES = Config.STAT_NAMES
local STAT_ICONS = {
	Damage = "💥", FireRate = "🔥", ProjectileHealth = "🛡", Speed = "💨",
	Maneuverability = "🔄", MaxHP = "❤", Regen = "💚", Boost = "⚡"
}
local STAT_COLORS = {
	Damage = Color3.fromRGB(255, 80, 80), FireRate = Color3.fromRGB(255, 160, 0),
	ProjectileHealth = Color3.fromRGB(0, 180, 255), Speed = Color3.fromRGB(0, 255, 150),
	Maneuverability = Color3.fromRGB(180, 0, 255), MaxHP = Color3.fromRGB(255, 50, 50),
	Regen = Color3.fromRGB(0, 255, 100), Boost = Color3.fromRGB(255, 220, 0)
}

for i, statName in ipairs(STAT_NAMES) do
	local statColor = STAT_COLORS[statName] or ACCENT_CYAN

	local card = Instance.new("Frame")
	card.Name = statName .. "Card"
	card.Size = UDim2.new(1, 0, 0, 65)
	card.BackgroundColor3 = BG_CARD
	card.BorderSizePixel = 0
	card.LayoutOrder = i
	card.Parent = statsFrame
	corner(card, 10)
	stroke(card, statColor, 1)

	-- Stat icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 1, 0)
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.BackgroundTransparency = 1
	icon.TextColor3 = statColor
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Text = STAT_ICONS[statName] or "•"
	icon.Parent = card

	-- Stat name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.2, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 55, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = WHITE
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = statName
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Stat level
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	levelLabel.Position = UDim2.new(0.2, 55, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.TextColor3 = statColor
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.Text = "Lv 0"
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = card

	-- Progress bar background
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.35, 0, 0.3, 0)
	barBg.Position = UDim2.new(0, 55, 0.55, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(10, 12, 25)
	barBg.BorderSizePixel = 0
	barBg.Parent = card
	corner(barBg, 4)

	-- Progress bar fill
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = statColor
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	corner(barFill, 4)

	-- Scaling info
	local scaleLabel = Instance.new("TextLabel")
	scaleLabel.Name = "ScaleLabel"
	scaleLabel.Size = UDim2.new(0.2, 0, 0.5, 0)
	scaleLabel.Position = UDim2.new(0.55, 55, 0, 0)
	scaleLabel.BackgroundTransparency = 1
	scaleLabel.TextColor3 = GRAY
	scaleLabel.TextScaled = true
	scaleLabel.Font = Enum.Font.Gotham
	scaleLabel.Text = "x1.00"
	scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
	scaleLabel.Parent = card

	-- +1 Button
	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Name = "UpgradeBtn"
	upgradeBtn.Size = UDim2.new(0, 50, 0, 40)
	upgradeBtn.Position = UDim2.new(1, -60, 0.5, -20)
	upgradeBtn.BackgroundColor3 = ACCENT_GREEN
	upgradeBtn.TextColor3 = Color3.new(0, 0, 0)
	upgradeBtn.TextScaled = true
	upgradeBtn.Font = Enum.Font.GothamBold
	upgradeBtn.Text = "+1"
	upgradeBtn.Parent = card
	corner(upgradeBtn, 8)
	stroke(upgradeBtn, Color3.fromRGB(0, 200, 100), 1)

	-- +5 Button
	local upgrade5Btn = Instance.new("TextButton")
	upgrade5Btn.Name = "Upgrade5Btn"
	upgrade5Btn.Size = UDim2.new(0, 50, 0, 40)
	upgrade5Btn.Position = UDim2.new(1, -120, 0.5, -20)
	upgrade5Btn.BackgroundColor3 = ACCENT_CYAN
	upgrade5Btn.TextColor3 = Color3.new(0, 0, 0)
	upgrade5Btn.TextScaled = true
	upgrade5Btn.Font = Enum.Font.GothamBold
	upgrade5Btn.Text = "+5"
	upgrade5Btn.Parent = card
	corner(upgrade5Btn, 8)
	stroke(upgrade5Btn, ACCENT_CYAN, 1)

	upgradeBtn.MouseButton1Click:Connect(function()
		local remote = remotes:FindFirstChild("UpgradeStat")
		if remote then
			remote:FireServer(statName, 1)
		end
	end)

	upgrade5Btn.MouseButton1Click:Connect(function()
		local remote = remotes:FindFirstChild("UpgradeStat")
		if remote then
			remote:FireServer(statName, 5)
		end
	end)

	statCards[statName] = {
		card = card,
		levelLabel = levelLabel,
		barFill = barFill,
		scaleLabel = scaleLabel,
		upgradeBtn = upgradeBtn,
		upgrade5Btn = upgrade5Btn,
	}
end

-- ==========================
-- TAB 2: EVOLUTIONS
-- ==========================
local evoFrame = Instance.new("ScrollingFrame")
evoFrame.Name = "EvolutionsTab"
evoFrame.Size = UDim2.new(1, 0, 1, 0)
evoFrame.BackgroundTransparency = 1
evoFrame.ScrollBarThickness = 4
evoFrame.ScrollBarImageColor3 = ACCENT_PURPLE
evoFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
evoFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
evoFrame.Visible = false
evoFrame.Parent = contentArea

local evoLayout = Instance.new("UIListLayout")
evoLayout.Padding = UDim.new(0, 6)
evoLayout.SortOrder = Enum.SortOrder.LayoutOrder
evoLayout.Parent = evoFrame

-- Build evolution tree display
local evoCards = {}
local function buildEvolutionTree()
	-- Clear existing
	for _, child in ipairs(evoFrame:GetChildren()) do
		if child:IsA("Frame") then child.Parent = nil end
	end

	-- Build tree by level tiers
	local tiers = {}
	local function addToTier(name, level)
		local tier = tostring(level)
		if not tiers[tier] then tiers[tier] = {} end
		table.insert(tiers[tier], name)
	end

	for name, evo in pairs(EvolutionTree) do
		if type(evo) == "table" and evo.name and not evo.isTitan then
			addToTier(name, evo.level)
		end
	end

	-- Sort tier keys
	local tierKeys = {}
	for k in pairs(tiers) do table.insert(tierKeys, tonumber(k)) end
	table.sort(tierKeys)

	local layoutOrder = 0
	for _, level in ipairs(tierKeys) do
		local tierJets = tiers[tostring(level)]
		table.sort(tierJets)

		-- Tier header
		layoutOrder = layoutOrder + 1
		local tierHeader = Instance.new("Frame")
		tierHeader.Size = UDim2.new(1, 0, 0, 30)
		tierHeader.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
		tierHeader.BorderSizePixel = 0
		tierHeader.LayoutOrder = layoutOrder
		tierHeader.Parent = evoFrame
		corner(tierHeader, 6)

		local tierLabel = Instance.new("TextLabel")
		tierLabel.Size = UDim2.new(1, -10, 1, 0)
		tierLabel.Position = UDim2.new(0, 10, 0, 0)
		tierLabel.BackgroundTransparency = 1
		tierLabel.TextColor3 = ACCENT_PURPLE
		tierLabel.TextScaled = true
		tierLabel.Font = Enum.Font.GothamBold
		tierLabel.Text = level == 1 and "▸ STARTER" or "▸ LEVEL " .. level .. " EVOLUTION"
		tierLabel.TextXAlignment = Enum.TextXAlignment.Left
		tierLabel.Parent = tierHeader

		-- Jets in this tier
		for _, jetName in ipairs(tierJets) do
			local evo = EvolutionTree[jetName]
			if not evo then continue end
			layoutOrder = layoutOrder + 1

			local isCurrent = (jetName == currentEvolution)
			local isUnlocked = playerLevel >= evo.level
			local isOnPath = false

			-- Check if this jet is on the player's evolution path
			if playerData and playerData.EvolutionPath then
				for _, pathEvo in ipairs(playerData.EvolutionPath) do
					if pathEvo == jetName then
						isOnPath = true
						break
					end
				end
			end

			local card = Instance.new("Frame")
			card.Name = jetName .. "Evo"
			card.Size = UDim2.new(1, 0, 0, 70)
			card.Position = UDim2.new(0, 0, 0, 0)
			card.BackgroundColor3 = isCurrent and Color3.fromRGB(0, 50, 20) or (isUnlocked and BG_CARD or Color3.fromRGB(15, 15, 25))
			card.BorderSizePixel = 0
			card.LayoutOrder = layoutOrder
			card.Parent = evoFrame
			corner(card, 8)

			local borderColor = isCurrent and ACCENT_GOLD or (isOnPath and ACCENT_PURPLE or (isUnlocked and ACCENT_CYAN or GRAY_DARK))
			stroke(card, borderColor, isCurrent and 2 or 1)

			-- Jet name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, 0, 0.35, 0)
			nameLabel.Position = UDim2.new(0, 10, 0, 3)
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextColor3 = isUnlocked and WHITE or GRAY_DARK
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Text = jetName
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = card

			-- Movement style
			local styleLabel = Instance.new("TextLabel")
			styleLabel.Size = UDim2.new(0.4, 0, 0.25, 0)
			styleLabel.Position = UDim2.new(0.6, 0, 0.05, 0)
			styleLabel.BackgroundTransparency = 1
			styleLabel.TextColor3 = ACCENT_CYAN
			styleLabel.TextScaled = true
			styleLabel.Font = Enum.Font.Gotham
			styleLabel.Text = evo.movementStyle
			styleLabel.TextXAlignment = Enum.TextXAlignment.Right
			styleLabel.Parent = card

			-- Description
			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -20, 0.25, 0)
			descLabel.Position = UDim2.new(0, 10, 0.35, 0)
			descLabel.BackgroundTransparency = 1
			descLabel.TextColor3 = GRAY
			descLabel.TextScaled = true
			descLabel.Font = Enum.Font.Gotham
			descLabel.Text = evo.description or ""
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.TextWrapped = true
			descLabel.Parent = card

			-- Status / Select button
			local statusBtn = Instance.new("TextButton")
			statusBtn.Name = "StatusBtn"
			statusBtn.Size = UDim2.new(0.3, 0, 0.25, 0)
			statusBtn.Position = UDim2.new(0.65, 0, 0.65, 0)
			statusBtn.BackgroundColor3 = isCurrent and ACCENT_GOLD or (isUnlocked and ACCENT_GREEN or GRAY_DARK)
			statusBtn.TextColor3 = isUnlocked and Color3.new(0, 0, 0) or GRAY
			statusBtn.TextScaled = true
			statusBtn.Font = Enum.Font.GothamBold
			statusBtn.Text = isCurrent and "EQUIPPED" or (isUnlocked and "SELECT" or "LOCKED")
			statusBtn.Parent = card
			corner(statusBtn, 6)

			-- Cannons indicator
			local cannonLabel = Instance.new("TextLabel")
			cannonLabel.Size = UDim2.new(0.3, 0, 0.25, 0)
			cannonLabel.Position = UDim2.new(0, 10, 0.65, 0)
			cannonLabel.BackgroundTransparency = 1
			cannonLabel.TextColor3 = ACCENT_ORANGE
			cannonLabel.TextScaled = true
			cannonLabel.Font = Enum.Font.GothamBold
			cannonLabel.Text = "🔫 x" .. (evo.projectileCount or 1)
			cannonLabel.TextXAlignment = Enum.TextXAlignment.Left
			cannonLabel.Parent = card

			if isUnlocked and not isCurrent then
				statusBtn.MouseButton1Click:Connect(function()
					local evolveRemote = remotes:FindFirstChild("Evolve")
					if evolveRemote then
						evolveRemote:FireServer(jetName)
					end
					gui.Enabled = false
				end)
			end

			evoCards[jetName] = card
		end
	end -- end if AbilityDefs
end

buildEvolutionTree()

-- ==========================
-- TAB 3: ABILITIES
-- ==========================
local abilityFrame = Instance.new("Frame")
abilityFrame.Name = "AbilitiesTab"
abilityFrame.Size = UDim2.new(1, 0, 1, 0)
abilityFrame.BackgroundTransparency = 1
abilityFrame.Visible = false
abilityFrame.Parent = contentArea

-- Two sections: Owned (backpack) and Shop
local abilityScroll = Instance.new("ScrollingFrame")
abilityScroll.Size = UDim2.new(1, 0, 1, 0)
abilityScroll.BackgroundTransparency = 1
abilityScroll.ScrollBarThickness = 4
abilityScroll.ScrollBarImageColor3 = ACCENT_ORANGE
abilityScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
abilityScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
abilityScroll.Parent = abilityFrame

local abilityListLayout = Instance.new("UIListLayout")
abilityListLayout.Padding = UDim.new(0, 6)
abilityListLayout.SortOrder = Enum.SortOrder.LayoutOrder
abilityListLayout.Parent = abilityScroll

-- Section: Owned Abilities (Backpack)
local ownedSection = Instance.new("Frame")
ownedSection.Name = "OwnedSection"
ownedSection.Size = UDim2.new(1, 0, 0, 30)
ownedSection.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
ownedSection.BorderSizePixel = 0
ownedSection.LayoutOrder = 1
ownedSection.Parent = abilityScroll
corner(ownedSection, 6)

local ownedLabel = Instance.new("TextLabel")
ownedLabel.Size = UDim2.new(1, -10, 1, 0)
ownedLabel.Position = UDim2.new(0, 10, 0, 0)
ownedLabel.BackgroundTransparency = 1
ownedLabel.TextColor3 = ACCENT_GREEN
ownedLabel.TextScaled = true
ownedLabel.Font = Enum.Font.GothamBold
ownedLabel.Text = "▸ ABILITY BACKPACK (OWNED)"
ownedLabel.TextXAlignment = Enum.TextXAlignment.Left
ownedLabel.Parent = ownedSection

-- Section: Ability Shop
local shopSection = Instance.new("Frame")
shopSection.Name = "ShopSection"
shopSection.Size = UDim2.new(1, 0, 0, 30)
shopSection.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
shopSection.BorderSizePixel = 0
shopSection.LayoutOrder = 100
shopSection.Parent = abilityScroll
corner(shopSection, 6)

local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.new(1, -10, 1, 0)
shopLabel.Position = UDim2.new(0, 10, 0, 0)
shopLabel.BackgroundTransparency = 1
shopLabel.TextColor3 = ACCENT_ORANGE
shopLabel.TextScaled = true
shopLabel.Font = Enum.Font.GothamBold
shopLabel.Text = "▸ ABILITY SHOP (UNLOCK)"
shopLabel.TextXAlignment = Enum.TextXAlignment.Left
shopLabel.Parent = shopSection

-- Build ability cards
local abilityCards = {}
local allAbilities = AbilityDefs.GetAll()

for i, abilityDef in ipairs(allAbilities) do
	local isOwned = false
	for _, ownedId in ipairs(ownedAbilities) do
		if ownedId == abilityDef.id then
			isOwned = true
			break
		end
	end
	local isEquipped = (equippedAbility == abilityDef.id)

	local card = Instance.new("Frame")
	card.Name = abilityDef.id .. "Card"
	card.Size = UDim2.new(1, 0, 0, 80)
	card.BackgroundColor3 = isEquipped and Color3.fromRGB(0, 50, 20) or (isOwned and BG_CARD or Color3.fromRGB(15, 15, 25))
	card.BorderSizePixel = 0
	card.LayoutOrder = isOwned and (i + 1) or (i + 200)
	card.Parent = abilityScroll
	corner(card, 10)

	local borderColor = isEquipped and ACCENT_GOLD or (isOwned and ACCENT_GREEN or GRAY_DARK)
	stroke(card, borderColor, isEquipped and 2 or 1)

	-- Ability icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 1, 0)
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.BackgroundTransparency = 1
	icon.TextColor3 = isOwned and ACCENT_ORANGE or GRAY_DARK
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Text = "⚡"
	icon.Parent = card

	-- Ability name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.35, 0, 0.3, 0)
	nameLabel.Position = UDim2.new(0, 55, 0, 3)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = isOwned and WHITE or GRAY_DARK
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = abilityDef.name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Rank requirement
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0.2, 0, 0.3, 0)
	rankLabel.Position = UDim2.new(0.35, 55, 0, 3)
	rankLabel.BackgroundTransparency = 1
	rankLabel.TextColor3 = ACCENT_CYAN
	rankLabel.TextScaled = true
	rankLabel.Font = Enum.Font.Gotham
	rankLabel.Text = RankDefs.GetDisplay(abilityDef.rankRequired)
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.6, 0, 0.25, 0)
	descLabel.Position = UDim2.new(0, 55, 0.3, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = GRAY
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = abilityDef.description
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = card

	-- Charges / Cooldown info
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(0.4, 0, 0.2, 0)
	infoLabel.Position = UDim2.new(0, 55, 0.55, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = GRAY_DARK
	infoLabel.TextScaled = true
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.Text = "Charges: " .. abilityDef.charges .. " | CD: " .. abilityDef.cooldown .. "s"
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = card

	-- Action button
	local actionBtn = Instance.new("TextButton")
	actionBtn.Name = "ActionBtn"
	actionBtn.Size = UDim2.new(0.15, 0, 0.5, 0)
	actionBtn.Position = UDim2.new(0.82, 0, 0.25, 0)

	if isEquipped then
		actionBtn.BackgroundColor3 = ACCENT_GOLD
		actionBtn.TextColor3 = Color3.new(0, 0, 0)
		actionBtn.Text = "EQUIPPED"
	elseif isOwned then
		actionBtn.BackgroundColor3 = ACCENT_GREEN
		actionBtn.TextColor3 = Color3.new(0, 0, 0)
		actionBtn.Text = "EQUIP"
	else
		actionBtn.BackgroundColor3 = ACCENT_ORANGE
		actionBtn.TextColor3 = Color3.new(0, 0, 0)
		actionBtn.Text = "BUY"
	end
	actionBtn.TextScaled = true
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.Parent = card
	corner(actionBtn, 6)

	-- Price display (for unowned)
	if not isOwned then
		local priceFrame = Instance.new("Frame")
		priceFrame.Size = UDim2.new(0.15, 0, 0.3, 0)
		priceFrame.Position = UDim2.new(0.82, 0, 0.75, 0)
		priceFrame.BackgroundTransparency = 1
		priceFrame.Parent = card

		local medalPrice = Instance.new("TextLabel")
		medalPrice.Size = UDim2.new(1, 0, 1, 0)
		medalPrice.BackgroundTransparency = 1
		medalPrice.TextColor3 = ACCENT_GOLD
		medalPrice.TextScaled = true
		medalPrice.Font = Enum.Font.Gotham
		medalPrice.Text = "🪙" .. abilityDef.medalCost
		medalPrice.Parent = priceFrame

		local robuxPrice = Instance.new("TextLabel")
		robuxPrice.Size = UDim2.new(1, 0, 1, 0)
		robuxPrice.Position = UDim2.new(0.5, 0, 0, 0)
		robuxPrice.BackgroundTransparency = 1
		robuxPrice.TextColor3 = ACCENT_GREEN
		robuxPrice.TextScaled = true
		robuxPrice.Font = Enum.Font.Gotham
		robuxPrice.Text = "R$" .. abilityDef.robuxCost
		robuxPrice.Parent = priceFrame
	end

	-- Button handlers
	actionBtn.MouseButton1Click:Connect(function()
		if isEquipped then return end
		if isOwned then
			local equipRemote = remotes:FindFirstChild("EquipAbility")
			if equipRemote then
				equipRemote:FireServer(abilityDef.id)
			end
		else
			local buyRemote = remotes:FindFirstChild("BuyShopItem")
			if buyRemote then
				buyRemote:FireServer("Ability", abilityDef.id)
			end
		end
	end)

	abilityCards[abilityDef.id] = {
		card = card,
		actionBtn = actionBtn,
	}
end

-- === TAB SWITCHING ===
function switchTab(tabName)
	activeTab = tabName

	-- Hide all tab content
	statsFrame.Visible = (tabName == "STATS")
	evoFrame.Visible = (tabName == "EVOLUTIONS")
	abilityFrame.Visible = (tabName == "ABILITIES")

	-- Update tab button styles
	for name, tabData in pairs(tabButtons) do
		if name == tabName then
			tabData.btn.TextColor3 = tabData.color
			tabData.indicator.BackgroundTransparency = 0
			tabData.btn.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
		else
			tabData.btn.TextColor3 = GRAY
			tabData.indicator.BackgroundTransparency = 1
			tabData.btn.BackgroundColor3 = BG_PANEL
		end
	end

	-- Rebuild evolution tree when switching to that tab
	if tabName == "EVOLUTIONS" then
		buildEvolutionTree()
	end
end

-- Initialize first tab
switchTab("STATS")

-- === UPDATE ALL UI ===
local function updateUI(data)
	if data then
		playerData = data
		if data.Level then playerLevel = data.Level end
		if data.CurrentEvolution then currentEvolution = data.CurrentEvolution end
		if data.StatPoints then statPoints = data.StatPoints end
		if data.Stats then playerStats = data.Stats end
		if data.OwnedAbilities then ownedAbilities = data.OwnedAbilities end
		if data.EquippedAbility then equippedAbility = data.EquippedAbility end
		if data.Rank then playerRank = data.Rank end
		if data.Medals then playerMedals = data.Medals end
	end

	-- Update stat points display
	pointsDisplay.Text = "Points: " .. statPoints

	-- Update stat cards
	for statName, cardData in pairs(statCards) do
		local level = playerStats[statName] or 0
		local maxLevel = Config.MAX_STAT_LEVEL
		local scale = Config.STAT_SCALE[statName] or 1
		local multiplier = scale ^ level

		cardData.levelLabel.Text = "Lv " .. level
		cardData.barFill.Size = UDim2.new(level / maxLevel, 0, 1, 0)
		cardData.scaleLabel.Text = "x" .. string.format("%.2f", multiplier)

		-- Enable/disable upgrade buttons based on available points
		local canUpgrade = statPoints > 0 and level < maxLevel
		cardData.upgradeBtn.BackgroundColor3 = canUpgrade and ACCENT_GREEN or GRAY_DARK
		cardData.upgradeBtn.TextColor3 = canUpgrade and Color3.new(0, 0, 0) or GRAY
		cardData.upgrade5Btn.BackgroundColor3 = (canUpgrade and statPoints >= 5) and ACCENT_CYAN or GRAY_DARK
		cardData.upgrade5Btn.TextColor3 = (canUpgrade and statPoints >= 5) and Color3.new(0, 0, 0) or GRAY
	end

	-- Rebuild evolution tree if on that tab
	if activeTab == "EVOLUTIONS" then
		buildEvolutionTree()
	end

	-- Rebuild ability cards
	if AbilityDefs then
		for abilityId, cardData in pairs(abilityCards) do
			local abilityDef = AbilityDefs.GetByID(abilityId)
			if not abilityDef then continue end

		local isOwned = false
		for _, ownedId in ipairs(ownedAbilities) do
			if ownedId == abilityId then isOwned = true; break end
		end
		local isEquipped = (equippedAbility == abilityId)

		cardData.card.BackgroundColor3 = isEquipped and Color3.fromRGB(0, 50, 20) or (isOwned and BG_CARD or Color3.fromRGB(15, 15, 25))

		local borderColor = isEquipped and ACCENT_GOLD or (isOwned and ACCENT_GREEN or GRAY_DARK)
		local s = cardData.card:FindFirstChildOfClass("UIStroke")
		if s then s.Color = borderColor; s.Thickness = isEquipped and 2 or 1 end

		if isEquipped then
			cardData.actionBtn.Text = "EQUIPPED"
			cardData.actionBtn.BackgroundColor3 = ACCENT_GOLD
		elseif isOwned then
			cardData.actionBtn.Text = "EQUIP"
			cardData.actionBtn.BackgroundColor3 = ACCENT_GREEN
		else
			cardData.actionBtn.Text = "BUY"
			cardData.actionBtn.BackgroundColor3 = ACCENT_ORANGE
		end
	end
end

-- === DATA SYNC ===
local updateClient = remotes:FindFirstChild("UpdateClient")
if updateClient then
	updateClient.OnClientEvent:Connect(function(data)
		updateUI(data)
	end)
end

-- Stat upgrade result listener (visual feedback)
local statResultRemote = remotes:FindFirstChild("StatResult")
if statResultRemote then
	statResultRemote.OnClientEvent:Connect(function(result)
		if result.success and result.stat then
			local cardData = statCards[result.stat]
			if cardData then
				local flash = TweenService:Create(cardData.card, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(0, 80, 40)
				})
				flash:Play()
				flash.Completed:Connect(function()
					TweenService:Create(cardData.card, TweenInfo.new(0.3), {
						BackgroundColor3 = BG_CARD
					}):Play()
				end)
			end
		end
	end)
end

-- Request initial data
local getData = remotes:FindFirstChild("GetData")
if getData then
	task.spawn(function()
		local ok, data = pcall(function()
			return getData:InvokeServer()
		end)
		if ok and data then updateUI(data) end
	end)
end

-- === OPEN MENU REMOTE ===
local openUpgradeTerminal = remotes:FindFirstChild("OpenUpgradeTerminal")
if openUpgradeTerminal then
	openUpgradeTerminal.OnClientEvent:Connect(function()
		-- Close all other menus first
		if _G.CloseAllMenus then _G.CloseAllMenus() end
		-- Refresh data
		local getDataRemote = remotes:FindFirstChild("GetData")
		if getDataRemote then
			task.spawn(function()
				local ok, data = pcall(function()
					return getDataRemote:InvokeServer()
				end)
				if ok and data then updateUI(data) end
			end)
		end
		gui.Enabled = true
		-- Animate in
		container.Size = UDim2.new(0, 0, 0, 0)
		container.Position = UDim2.new(0.5, 0, 0.5, 0)
		TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.7, 0, 0.85, 0),
			Position = UDim2.new(0.15, 0, 0.075, 0),
		}):Play()
	end)
end

-- Close when entering arena
local joinArenaRemote = remotes:FindFirstChild("JoinArena")
if joinArenaRemote then
	joinArenaRemote.OnClientEvent:Connect(function()
		gui.Enabled = false
	end)
end