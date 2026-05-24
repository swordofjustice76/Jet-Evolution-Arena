local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local EvolutionTree = require(ReplicatedStorage.Shared.EvolutionTree)
local ShopDefs = require(ReplicatedStorage.Shared.ShopDefs)

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

-- Rarity colors
local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(0, 200, 100),
	Rare = Color3.fromRGB(0, 150, 255),
	Epic = Color3.fromRGB(160, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Titan = Color3.fromRGB(255, 60, 60),
}

-- Jet definitions with full metadata (maps EvolutionTree entries to display data)
local JET_DEFS = {
	-- Starter / Normal Jets
	Starter = {displayName = "Base Jet", rarity = "Common", playstyle = "Balanced starter", price = "Free", priceColor = ACCENT_GREEN},
	Scout = {displayName = "Interceptor", rarity = "Uncommon", playstyle = "Fast strafe-focused fighter", price = "Lv 15", priceColor = ACCENT_CYAN},
	Tank = {displayName = "Heavy Bomber", rarity = "Uncommon", playstyle = "Tanky with bomb drops", price = "Lv 15", priceColor = ACCENT_CYAN},
	Interceptor = {displayName = "Strafing Ace", rarity = "Rare", playstyle = "Extreme sideways mobility", price = "Lv 30", priceColor = ACCENT_CYAN},
	Phantom = {displayName = "Stealth Assassin", rarity = "Rare", playstyle = "Cloaking and hit-and-run", price = "Lv 30", priceColor = ACCENT_CYAN},
	Fortress = {displayName = "Drone Carrier", rarity = "Rare", playstyle = "Deploys support drones", price = "Lv 30", priceColor = ACCENT_CYAN},
	Juggernaut = {displayName = "Rail Sniper", rarity = "Rare", playstyle = "Long-range precision jet", price = "Lv 30", priceColor = ACCENT_CYAN},
	Wraith = {displayName = "Hydra Dominator", rarity = "Epic", playstyle = "Advanced lateral + reverse thrust", price = "Lv 45", priceColor = ACCENT_PURPLE},
	Striker = {displayName = "Striker", rarity = "Epic", playstyle = "Precision strafe rapid fire", price = "Lv 45", priceColor = ACCENT_PURPLE},
	Spectre = {displayName = "Spectre", rarity = "Epic", playstyle = "Ghost reverse dual cannons", price = "Lv 45", priceColor = ACCENT_PURPLE},
	Citadel = {displayName = "Citadel", rarity = "Epic", playstyle = "Flying citadel quad cannons", price = "Lv 45", priceColor = ACCENT_PURPLE},
	Leviathan = {displayName = "Leviathan", rarity = "Epic", playstyle = "Reverse leviathan massive bulk", price = "Lv 45", priceColor = ACCENT_PURPLE},
	Colossus = {displayName = "Colossus", rarity = "Epic", playstyle = "Hydra colossus omni-directional", price = "Lv 45", priceColor = ACCENT_PURPLE},
	Nemesis = {displayName = "Nemesis", rarity = "Legendary", playstyle = "Ultimate hunter quad hydra", price = "Lv 60", priceColor = ACCENT_GOLD},
	Eclipse = {displayName = "Eclipse", rarity = "Legendary", playstyle = "Shadow reverse dark matter", price = "Lv 60", priceColor = ACCENT_GOLD},
	Vanguard = {displayName = "Vanguard", rarity = "Legendary", playstyle = "Elite vanguard quad strafe", price = "Lv 60", priceColor = ACCENT_GOLD},
	Apex = {displayName = "Apex", rarity = "Legendary", playstyle = "Apex predator penta hydra", price = "Lv 80", priceColor = ACCENT_GOLD},
	TitanX = {displayName = "Titan X", rarity = "Legendary", playstyle = "Titan-class evolution six cannons", price = "Lv 105", priceColor = ACCENT_GOLD},
	Omega = {displayName = "Omega", rarity = "Legendary", playstyle = "Final form omega devastation", price = "Lv 130", priceColor = ACCENT_GOLD},
	-- Titan Class (Premium Rental)
	AetherTitan = {displayName = "Aether Titan", rarity = "Titan", playstyle = "Supreme aether power", price = "Rental", priceColor = ACCENT_RED, isTitan = true},
	VoidTitan = {displayName = "Void Titan", rarity = "Titan", playstyle = "Dark void devastation", price = "Rental", priceColor = ACCENT_RED, isTitan = true},
	StormTitan = {displayName = "Storm Titan", rarity = "Titan", playstyle = "Electrical storm fury", price = "Rental", priceColor = ACCENT_RED, isTitan = true},
	EternalTitan = {displayName = "Eternal Titan", rarity = "Titan", playstyle = "Eternal cosmic dominance", price = "Rental", priceColor = ACCENT_RED, isTitan = true},
}

-- Player data cache
local playerData = {}
local currentEvolution = "Starter"
local playerLevel = 1

-- Helper: create UI corner
local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

-- Helper: create UI stroke
local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

-- Helper: create glow frame (background gradient effect)
local function addGlow(parent, color, transparency)
	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1.2, 0, 1.2, 0)
	glow.Position = UDim2.new(-0.1, 0, -0.1, 0)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://7669168585"
	glow.ImageColor3 = color
	glow.ImageTransparency = transparency or 0.7
	glow.Parent = parent
	return glow
end

-- === MAIN GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "JetHangarMenu"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
 gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Full-screen dark backdrop (TextButton so clicks close the menu)
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = BG_DARK
backdrop.BackgroundTransparency = 0.3
backdrop.BorderSizePixel = 0
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Parent = gui

-- === MAIN CONTAINER ===
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0.75, 0, 0.82, 0)
container.Position = UDim2.new(0.125, 0, 0.09, 0)
container.BackgroundColor3 = BG_PANEL
container.BorderSizePixel = 0
container.Parent = gui
corner(container, 16)
stroke(container, ACCENT_CYAN, 2)

-- === HEADER BAR ===
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
header.BorderSizePixel = 0
header.Parent = container
corner(header, 12)

-- Header glow line
local headerGlow = Instance.new("Frame")
headerGlow.Size = UDim2.new(1, 0, 0, 2)
headerGlow.Position = UDim2.new(0, 0, 1, -2)
headerGlow.BackgroundColor3 = ACCENT_CYAN
headerGlow.BackgroundTransparency = 0.3
headerGlow.BorderSizePixel = 0
headerGlow.Parent = header

-- Header icon
local headerIcon = Instance.new("TextLabel")
headerIcon.Size = UDim2.new(0, 50, 1, 0)
headerIcon.Position = UDim2.new(0, 15, 0, 0)
headerIcon.BackgroundTransparency = 1
headerIcon.TextColor3 = ACCENT_CYAN
headerIcon.TextScaled = true
headerIcon.Font = Enum.Font.GothamBold
headerIcon.Text = "✈"
headerIcon.Parent = header

-- Header title
local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0.6, 0, 1, 0)
headerTitle.Position = UDim2.new(0, 65, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.TextColor3 = WHITE
headerTitle.TextScaled = true
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "JET HANGAR"
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

-- Header subtitle
local headerSub = Instance.new("TextLabel")
headerSub.Size = UDim2.new(0.3, 0, 0.5, 0)
headerSub.Position = UDim2.new(0.6, 0, 0.25, 0)
headerSub.BackgroundTransparency = 1
headerSub.TextColor3 = GRAY
headerSub.TextScaled = true
headerSub.Font = Enum.Font.Gotham
headerSub.Text = "Select your jet for battle"
headerSub.TextXAlignment = Enum.TextXAlignment.Right
headerSub.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 44, 0, 44)
closeBtn.Position = UDim2.new(1, -55, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
closeBtn.TextColor3 = ACCENT_RED
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "✕"
closeBtn.Parent = header
corner(closeBtn, 10)
stroke(closeBtn, ACCENT_RED, 1)

local function closeJetHangar()
	local tween = TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	})
	tween:Play()
	tween.Completed:Connect(function()
		gui.Enabled = false
		container.Size = UDim2.new(0.75, 0, 0.82, 0)
		container.Position = UDim2.new(0.125, 0, 0.09, 0)
	end)
end

closeBtn.MouseButton1Click:Connect(closeJetHangar)
backdrop.MouseButton1Click:Connect(closeJetHangar)

-- === SECTION LABELS ===
local normalLabel = Instance.new("TextLabel")
normalLabel.Name = "NormalSectionLabel"
normalLabel.Size = UDim2.new(1, -30, 0, 30)
normalLabel.Position = UDim2.new(0, 15, 0, 65)
normalLabel.BackgroundTransparency = 1
normalLabel.TextColor3 = ACCENT_CYAN
normalLabel.TextScaled = true
normalLabel.Font = Enum.Font.GothamBold
normalLabel.Text = "▸ STANDARD JETS"
normalLabel.TextXAlignment = Enum.TextXAlignment.Left
normalLabel.Parent = container

local titanLabel = Instance.new("TextLabel")
titanLabel.Name = "TitanSectionLabel"
titanLabel.Size = UDim2.new(1, -30, 0, 30)
titanLabel.Position = UDim2.new(0, 15, 0, 0) -- will be repositioned dynamically
titanLabel.BackgroundTransparency = 1
titanLabel.TextColor3 = ACCENT_RED
titanLabel.TextScaled = true
titanLabel.Font = Enum.Font.GothamBold
titanLabel.Text = "▸ TITAN CLASS (PREMIUM RENTAL)"
titanLabel.TextXAlignment = Enum.TextXAlignment.Left
titanLabel.Parent = container

-- === NORMAL JETS SCROLL ===
local normalScroll = Instance.new("ScrollingFrame")
normalScroll.Name = "NormalScroll"
normalScroll.Size = UDim2.new(1, -30, 0.35, 0)
normalScroll.Position = UDim2.new(0, 15, 0, 95)
normalScroll.BackgroundTransparency = 1
normalScroll.ScrollBarThickness = 4
normalScroll.ScrollBarImageColor3 = ACCENT_CYAN
normalScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
normalScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
normalScroll.Parent = container

local normalGrid = Instance.new("UIGridLayout")
normalGrid.CellSize = UDim2.new(0.24, 0, 0, 155)
normalGrid.CellPadding = UDim2.new(0.01, 0, 0, 8)
normalGrid.SortOrder = Enum.SortOrder.LayoutOrder
normalGrid.Parent = normalScroll

-- === TITAN JETS SCROLL ===
local titanScroll = Instance.new("ScrollingFrame")
titanScroll.Name = "TitanScroll"
titanScroll.Size = UDim2.new(1, -30, 0.35, 0)
titanScroll.Position = UDim2.new(0, 15, 0, 0) -- repositioned dynamically
titanScroll.BackgroundTransparency = 1
titanScroll.ScrollBarThickness = 4
titanScroll.ScrollBarImageColor3 = ACCENT_RED
titanScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
titanScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
titanScroll.Parent = container

local titanGrid = Instance.new("UIGridLayout")
titanGrid.CellSize = UDim2.new(0.24, 0, 0, 200)
titanGrid.CellPadding = UDim2.new(0.01, 0, 0, 8)
titanGrid.SortOrder = Enum.SortOrder.LayoutOrder
titanGrid.Parent = titanScroll

-- === DETAIL PANEL (right side, shows when a jet is selected) ===
local detailPanel = Instance.new("Frame")
detailPanel.Name = "DetailPanel"
detailPanel.Size = UDim2.new(1, -30, 0.25, 0)
detailPanel.Position = UDim2.new(0, 15, 0, 0) -- repositioned dynamically
detailPanel.BackgroundColor3 = Color3.fromRGB(12, 16, 30)
detailPanel.BorderSizePixel = 0
detailPanel.Visible = false
detailPanel.Parent = container
corner(detailPanel, 12)
stroke(detailPanel, ACCENT_CYAN, 1)

-- Detail content
local detailName = Instance.new("TextLabel")
detailName.Name = "JetName"
detailName.Size = UDim2.new(0.5, 0, 0.2, 0)
detailName.Position = UDim2.new(0, 20, 0, 10)
detailName.BackgroundTransparency = 1
detailName.TextColor3 = WHITE
detailName.TextScaled = true
detailName.Font = Enum.Font.GothamBold
detailName.Text = ""
detailName.TextXAlignment = Enum.TextXAlignment.Left
detailName.Parent = detailPanel

local detailRarity = Instance.new("TextLabel")
detailRarity.Name = "Rarity"
detailRarity.Size = UDim2.new(0.2, 0, 0.15, 0)
detailRarity.Position = UDim2.new(0, 20, 0.2, 0)
detailRarity.BackgroundTransparency = 1
detailRarity.TextScaled = true
detailRarity.Font = Enum.Font.GothamBold
detailRarity.Text = ""
detailRarity.TextXAlignment = Enum.TextXAlignment.Left
detailRarity.Parent = detailPanel

local detailStyle = Instance.new("TextLabel")
detailStyle.Name = "Playstyle"
detailStyle.Size = UDim2.new(0.5, 0, 0.12, 0)
detailStyle.Position = UDim2.new(0, 20, 0.35, 0)
detailStyle.BackgroundTransparency = 1
detailStyle.TextColor3 = GRAY
detailStyle.TextScaled = true
detailStyle.Font = Enum.Font.Gotham
detailStyle.Text = ""
detailStyle.TextXAlignment = Enum.TextXAlignment.Left
detailStyle.Parent = detailPanel

local detailDesc = Instance.new("TextLabel")
detailDesc.Name = "Description"
detailDesc.Size = UDim2.new(0.5, 0, 0.15, 0)
detailDesc.Position = UDim2.new(0, 20, 0.48, 0)
detailDesc.BackgroundTransparency = 1
detailDesc.TextColor3 = GRAY_DARK
detailDesc.TextScaled = true
detailDesc.Font = Enum.Font.Gotham
detailDesc.Text = ""
detailDesc.TextXAlignment = Enum.TextXAlignment.Left
detailDesc.TextWrapped = true
detailDesc.Parent = detailPanel

-- Detail stats
local detailStats = Instance.new("Frame")
detailStats.Name = "StatsFrame"
detailStats.Size = UDim2.new(0.5, 0, 0.25, 0)
detailStats.Position = UDim2.new(0, 20, 0.65, 0)
detailStats.BackgroundTransparency = 1
detailStats.Parent = detailPanel

local statsLabels = {}
local statNames = {"Movement", "Cannons", "Scale"}
for i, statName in ipairs(statNames) do
	local sl = Instance.new("TextLabel")
	sl.Size = UDim2.new(0.33, 0, 1, 0)
	sl.Position = UDim2.new((i-1) * 0.33, 0, 0, 0)
	sl.BackgroundTransparency = 1
	sl.TextColor3 = ACCENT_CYAN
	sl.TextScaled = true
	sl.Font = Enum.Font.GothamBold
	sl.Text = ""
	sl.Parent = detailStats
	statsLabels[statName] = sl
end

-- Detail action button
local detailAction = Instance.new("TextButton")
detailAction.Name = "ActionButton"
detailAction.Size = UDim2.new(0.2, 0, 0.35, 0)
detailAction.Position = UDim2.new(0.75, 0, 0.35, 0)
detailAction.BackgroundColor3 = ACCENT_GREEN
detailAction.TextColor3 = Color3.new(0, 0, 0)
detailAction.TextScaled = true
detailAction.Font = Enum.Font.GothamBold
detailAction.Text = "SELECT"
detailAction.Parent = detailPanel
corner(detailAction, 8)
stroke(detailAction, Color3.fromRGB(0, 200, 100), 2)

-- Detail price label
local detailPrice = Instance.new("TextLabel")
detailPrice.Name = "PriceLabel"
detailPrice.Size = UDim2.new(0.2, 0, 0.15, 0)
detailPrice.Position = UDim2.new(0.75, 0, 0.72, 0)
detailPrice.BackgroundTransparency = 1
detailPrice.TextColor3 = ACCENT_GOLD
detailPrice.TextScaled = true
detailPrice.Font = Enum.Font.GothamBold
detailPrice.Text = ""
detailPrice.Parent = detailPanel

-- Rental duration buttons (for Titan jets)
local rentalFrame = Instance.new("Frame")
rentalFrame.Name = "RentalOptions"
rentalFrame.Size = UDim2.new(0.2, 0, 0.35, 0)
rentalFrame.Position = UDim2.new(0.75, 0, 0.35, 0)
rentalFrame.BackgroundTransparency = 1
rentalFrame.Visible = false
rentalFrame.Parent = detailPanel

local rentalLayout = Instance.new("UIListLayout")
rentalLayout.Padding = UDim.new(0, 3)
rentalLayout.SortOrder = Enum.SortOrder.LayoutOrder
rentalLayout.Parent = rentalFrame

-- === BUILD JET CARDS ===
local jetCards = {}
local selectedJet = nil

-- Collect normal jets in tree order
local normalJetOrder = {}
local function collectNormalJets()
	local visited = {}
	local function traverse(name)
		if visited[name] then return end
		visited[name] = true
		local evo = EvolutionTree[name]
		if not evo then return end
		if not evo.isTitan then
			table.insert(normalJetOrder, name)
		end
		for _, childName in ipairs(evo.children or {}) do
			traverse(childName)
		end
	end
	traverse("Starter")
end
collectNormalJets()

-- Collect titan jets
local titanJetOrder = {}
for name, evo in pairs(EvolutionTree) do
	if type(evo) == "table" and evo.isTitan then
		table.insert(titanJetOrder, name)
	end
end
table.sort(titanJetOrder)

-- Create a single jet card
local function createJetCard(jetName, parentScroll, layoutOrder, isTitan)
	local evo = EvolutionTree[jetName]
	if not evo then return nil end
	local jetDef = JET_DEFS[jetName] or {}
	local rarityColor = RARITY_COLORS[jetDef.rarity] or GRAY

	local card = Instance.new("Frame")
	card.Name = jetName
	card.BackgroundColor3 = BG_CARD
	card.BackgroundTransparency = 0
	card.LayoutOrder = layoutOrder
	card.Parent = parentScroll
	corner(card, 10)
	stroke(card, rarityColor, 1)

	-- Rarity top bar
	local rarityBar = Instance.new("Frame")
	rarityBar.Size = UDim2.new(1, 0, 0, 3)
	rarityBar.BackgroundColor3 = rarityColor
	rarityBar.BorderSizePixel = 0
	rarityBar.Parent = card

	-- Jet icon/visual preview area
	local previewArea = Instance.new("Frame")
	previewArea.Name = "Preview"
	previewArea.Size = UDim2.new(1, -10, 0, 50)
	previewArea.Position = UDim2.new(0, 5, 0, 8)
	previewArea.BackgroundColor3 = Color3.fromRGB(10, 12, 25)
	previewArea.BorderSizePixel = 0
	previewArea.Parent = card
	corner(previewArea, 8)

	-- Visual preview: jet silhouette icon
	local previewIcon = Instance.new("TextLabel")
	previewIcon.Size = UDim2.new(1, 0, 1, 0)
	previewIcon.BackgroundTransparency = 1
	previewIcon.TextColor3 = rarityColor
	previewIcon.TextScaled = true
	previewIcon.Font = Enum.Font.GothamBold
	previewIcon.Text = isTitan and "⚡" or "✈"
	previewIcon.Parent = previewArea

	-- Rotating glow effect on preview
	local previewGlow = Instance.new("ImageLabel")
	previewGlow.Size = UDim2.new(1.4, 0, 1.4, 0)
	previewGlow.Position = UDim2.new(-0.2, 0, -0.2, 0)
	previewGlow.BackgroundTransparency = 1
	previewGlow.Image = "rbxassetid://7669168585"
	previewGlow.ImageColor3 = rarityColor
	previewGlow.ImageTransparency = 0.85
	previewGlow.Parent = previewArea

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 18)
	nameLabel.Position = UDim2.new(0, 5, 0, 62)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = WHITE
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = jetDef.displayName or jetName
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Rarity tag
	local rarityTag = Instance.new("TextLabel")
	rarityTag.Size = UDim2.new(0.45, 0, 0, 14)
	rarityTag.Position = UDim2.new(0.55, -5, 0, 62)
	rarityTag.BackgroundColor3 = rarityColor
	rarityTag.BackgroundTransparency = 0.3
	rarityTag.TextColor3 = WHITE
	rarityTag.TextScaled = true
	rarityTag.Font = Enum.Font.GothamBold
	rarityTag.Text = string.upper(jetDef.rarity or "Common")
	rarityTag.Parent = card
	corner(rarityTag, 4)

	-- Playstyle description
	local styleLabel = Instance.new("TextLabel")
	styleLabel.Size = UDim2.new(1, -10, 0, 14)
	styleLabel.Position = UDim2.new(0, 5, 0, 82)
	styleLabel.BackgroundTransparency = 1
	styleLabel.TextColor3 = GRAY
	styleLabel.TextScaled = true
	styleLabel.Font = Enum.Font.Gotham
	styleLabel.Text = jetDef.playstyle or ""
	styleLabel.TextXAlignment = Enum.TextXAlignment.Left
	styleLabel.TextWrapped = true
	styleLabel.Parent = card

	-- Price / Level requirement
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Size = UDim2.new(0.5, 0, 0, 14)
	priceLabel.Position = UDim2.new(0, 5, 0, 98)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = jetDef.priceColor or ACCENT_CYAN
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = jetDef.price or ""
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = card

	-- Select / Rent button
	local selectBtn = Instance.new("TextButton")
	selectBtn.Name = "SelectBtn"
	selectBtn.Size = UDim2.new(1, -10, 0, 22)
	selectBtn.Position = UDim2.new(0, 5, 1, -28)
	selectBtn.BackgroundColor3 = ACCENT_GREEN
	selectBtn.TextColor3 = Color3.new(0, 0, 0)
	selectBtn.TextScaled = true
	selectBtn.Font = Enum.Font.GothamBold
	selectBtn.Text = isTitan and "RENT" or "SELECT"
	selectBtn.Parent = card
	corner(selectBtn, 6)

	-- Titan rental prices (shown on titan cards)
	if isTitan then
		local rentalInfo = ShopDefs.TitanRentals[jetName]
		if rentalInfo then
			local rentalPrices = Instance.new("TextLabel")
			rentalPrices.Size = UDim2.new(1, -10, 0, 28)
			rentalPrices.Position = UDim2.new(0, 5, 0, 115)
			rentalPrices.BackgroundTransparency = 1
			rentalPrices.TextColor3 = ACCENT_GOLD
			rentalPrices.TextScaled = true
			rentalPrices.Font = Enum.Font.Gotham
			local priceTexts = {}
			for mins, robux in pairs(rentalInfo.prices) do
				local timeStr = mins >= 60 and (mins / 60 .. "hr") or (mins .. "min")
				table.insert(priceTexts, timeStr .. ": R$" .. robux)
			end
			table.sort(priceTexts)
			rentalPrices.Text = table.concat(priceTexts, " | ")
			rentalPrices.TextXAlignment = Enum.TextXAlignment.Left
			rentalPrices.TextWrapped = true
			rentalPrices.Parent = card
		end
	end

	-- Card hover effect
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = BG_CARD_HOVER}):Play()
		end
	end)
	card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = BG_CARD}):Play()
		end
	end)

	-- Card click -> show detail
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			selectedJet = jetName
			showDetail(jetName)
		end
	end)

	-- Select button click
	selectBtn.MouseButton1Click:Connect(function()
		if isTitan then
			showTitanRental(jetName)
		else
			local evolveRemote = remotes:FindFirstChild("Evolve")
			if evolveRemote then
				evolveRemote:FireServer(jetName)
			end
			gui.Enabled = false
		end
	end)

	jetCards[jetName] = {
		card = card,
		selectBtn = selectBtn,
		priceLabel = priceLabel,
		rarityBar = rarityBar,
		rarityTag = rarityTag,
	}

	return card
end

-- Build normal jet cards
for i, jetName in ipairs(normalJetOrder) do
	createJetCard(jetName, normalScroll, i, false)
end

-- Build titan jet cards
for i, jetName in ipairs(titanJetOrder) do
	createJetCard(jetName, titanScroll, i + 100, true)
end

-- === SHOW DETAIL PANEL ===
function showDetail(jetName)
	local evo = EvolutionTree[jetName]
	local jetDef = JET_DEFS[jetName] or {}
	if not evo then return end

	detailPanel.Visible = true
	detailName.Text = jetDef.displayName or jetName
	detailRarity.Text = string.upper(jetDef.rarity or "Common")
	detailRarity.TextColor3 = RARITY_COLORS[jetDef.rarity] or GRAY
	detailStyle.Text = "Playstyle: " .. (jetDef.playstyle or "")
	detailDesc.Text = evo.description or ""

	-- Stats
	statsLabels["Movement"].Text = "Move: " .. (evo.movementStyle or "Standard")
	statsLabels["Cannons"].Text = "Guns: " .. (evo.projectileCount or 1)
	statsLabels["Scale"].Text = "Scale: " .. (evo.visualScale or 1) .. "x"

	-- Price / action
	local isCurrent = (jetName == currentEvolution)
	local isUnlocked = evo.isTitan or (playerLevel >= evo.level)

	rentalFrame.Visible = false
	detailAction.Visible = true

	if isCurrent then
		detailAction.Text = "EQUIPPED"
		detailAction.BackgroundColor3 = ACCENT_GOLD
		detailAction.TextColor3 = Color3.new(0, 0, 0)
		detailPrice.Text = "Currently Active"
		detailPrice.TextColor3 = ACCENT_GOLD
	elseif isUnlocked then
		detailAction.Text = "SELECT"
		detailAction.BackgroundColor3 = ACCENT_GREEN
		detailAction.TextColor3 = Color3.new(0, 0, 0)
		detailPrice.Text = jetDef.price or "Free"
		detailPrice.TextColor3 = jetDef.priceColor or ACCENT_GREEN
	else
		detailAction.Text = "LOCKED"
		detailAction.BackgroundColor3 = GRAY_DARK
		detailAction.TextColor3 = GRAY
		detailPrice.Text = "Requires Lv " .. evo.level
		detailPrice.TextColor3 = ACCENT_RED
	end

	-- Detail action button handler
	detailAction.MouseButton1Click:Connect(function()
		if isCurrent then return end
		if not isUnlocked then return end
		local evolveRemote = remotes:FindFirstChild("Evolve")
		if evolveRemote then
			evolveRemote:FireServer(jetName)
		end
		gui.Enabled = false
	end)

	-- Animate in
	detailPanel.BackgroundTransparency = 1
	TweenService:Create(detailPanel, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
end

-- === SHOW TITAN RENTAL OPTIONS ===
function showTitanRental(jetName)
	local rentalInfo = ShopDefs.TitanRentals[jetName]
	if not rentalInfo then return end

	selectedJet = jetName
	showDetail(jetName)

	-- Show rental options instead of single action button
	detailAction.Visible = false
	rentalFrame.Visible = true

	-- Clear old rental buttons
	for _, child in ipairs(rentalFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child.Parent = nil
		end
	end

	-- Create rental duration buttons
	local durations = {}
	for mins, robux in pairs(rentalInfo.prices) do
		table.insert(durations, {mins = mins, robux = robux})
	end
	table.sort(durations, function(a, b) return a.mins < b.mins end)

	for i, dur in ipairs(durations) do
		local timeStr = dur.mins >= 60 and (dur.mins / 60 .. "hr") or (dur.mins .. "min")
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.BackgroundColor3 = ACCENT_RED
		btn.TextColor3 = WHITE
		btn.TextScaled = true
		btn.Font = Enum.Font.GothamBold
		btn.Text = timeStr .. " - R$" .. dur.robux
		btn.LayoutOrder = i
		btn.Parent = rentalFrame
		corner(btn, 6)
		stroke(btn, Color3.fromRGB(255, 100, 100), 1)

		btn.MouseButton1Click:Connect(function()
			local buyRemote = remotes:FindFirstChild("BuyShopItem")
			if buyRemote then
				buyRemote:FireServer("TitanRental", jetName, dur.mins)
			end
		end)
	end

	detailPrice.Text = "Rental - Robux Only"
	detailPrice.TextColor3 = ACCENT_RED
end

-- === UPDATE UI ===
local function updateJetCards(data)
	if data then
		playerData = data
		if data.Level then playerLevel = data.Level end
		if data.CurrentEvolution then currentEvolution = data.CurrentEvolution end
	end

	for jetName, cardData in pairs(jetCards) do
		local evo = EvolutionTree[jetName]
		if not evo then continue end
		local jetDef = JET_DEFS[jetName] or {}
		local rarityColor = RARITY_COLORS[jetDef.rarity] or GRAY

		local isCurrent = (jetName == currentEvolution)
		local isUnlocked = evo.isTitan or (playerLevel >= evo.level)

		if isCurrent then
			cardData.card.BackgroundColor3 = Color3.fromRGB(0, 50, 20)
			cardData.selectBtn.Text = "EQUIPPED"
			cardData.selectBtn.BackgroundColor3 = ACCENT_GOLD
			cardData.selectBtn.TextColor3 = Color3.new(0, 0, 0)
			-- Highlight border
			local s = cardData.card:FindFirstChildOfClass("UIStroke")
			if s then s.Color = ACCENT_GOLD; s.Thickness = 2 end
		elseif isUnlocked then
			cardData.card.BackgroundColor3 = BG_CARD
			cardData.selectBtn.Text = evo.isTitan and "RENT" or "SELECT"
			cardData.selectBtn.BackgroundColor3 = ACCENT_GREEN
			cardData.selectBtn.TextColor3 = Color3.new(0, 0, 0)
			local s = cardData.card:FindFirstChildOfClass("UIStroke")
			if s then s.Color = rarityColor; s.Thickness = 1 end
		else
			cardData.card.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
			cardData.selectBtn.Text = "LOCKED"
			cardData.selectBtn.BackgroundColor3 = GRAY_DARK
			cardData.selectBtn.TextColor3 = GRAY
			local s = cardData.card:FindFirstChildOfClass("UIStroke")
			if s then s.Color = GRAY_DARK; s.Thickness = 1 end
		end
	end

	-- Reposition sections based on content
	local normalContentHeight = normalScroll.CanvasSize.Y.Offset
	titanLabel.Position = UDim2.new(0, 15, 0, 95 + normalContentHeight + 10)
	titanScroll.Position = UDim2.new(0, 15, 0, 95 + normalContentHeight + 40)

	-- Detail panel below titan section
	local titanContentHeight = titanScroll.CanvasSize.Y.Offset
	detailPanel.Position = UDim2.new(0, 15, 0, 95 + normalContentHeight + 40 + titanContentHeight + 40 + 10)
end

-- === DATA SYNC ===
local updateClient = remotes:WaitForChild("UpdateClient")
updateClient.OnClientEvent:Connect(function(data)
	updateJetCards(data)
end)

-- Request initial data
local getData = remotes:FindFirstChild("GetData")
if getData then
	task.spawn(function()
		local data = getData:InvokeServer()
		if data then updateJetCards(data) end
	end)
end

-- === OPEN JET HANGAR REMOTE ===
local openJetHangar = remotes:WaitForChild("OpenJetHangar")
openJetHangar.OnClientEvent:Connect(function()
	-- Close all other menus first
	if _G.CloseAllMenus then _G.CloseAllMenus() end
	-- Refresh data before showing
	local getDataRemote = remotes:FindFirstChild("GetData")
	if getDataRemote then
		task.spawn(function()
			local data = getDataRemote:InvokeServer()
			if data then updateJetCards(data) end
		end)
	end
	gui.Enabled = true
	-- Animate in
	container.Size = UDim2.new(0, 0, 0, 0)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.75, 0, 0.82, 0),
		Position = UDim2.new(0.125, 0, 0.09, 0),
	}):Play()
end)

-- Close when entering arena
local joinArenaRemote = remotes:FindFirstChild("JoinArena")
if joinArenaRemote then
	joinArenaRemote.OnClientEvent:Connect(function()
		gui.Enabled = false
	end)
end

-- Animate preview glow effects
local glowTime = 0
task.spawn(function()
	while true do
		task.wait(0.05)
		glowTime = glowTime + 0.05
		for jetName, cardData in pairs(jetCards) do
			local preview = cardData.card:FindFirstChild("Preview")
			if preview then
				local glow = preview:FindFirstChild("ImageLabel")
				if glow then
					glow.ImageTransparency = 0.7 + 0.15 * math.sin(glowTime * 3)
				end
			end
		end
	end
end)