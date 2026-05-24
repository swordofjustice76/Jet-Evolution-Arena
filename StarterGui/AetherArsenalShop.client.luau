local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopDefs = require(ReplicatedStorage.Shared.ShopDefs)

-- Colors (Premium Sci-Fi Military: White, Silver, Blue, Gold)
local BG = Color3.fromRGB(230, 235, 245)
local PANEL = Color3.fromRGB(245, 248, 255)
local ACCENT = Color3.fromRGB(0, 120, 220)
local GOLD = Color3.fromRGB(212, 175, 55)
local GREEN = Color3.fromRGB(0, 255, 100)
local RED = Color3.fromRGB(255, 50, 50)
local WHITE = Color3.new(1, 1, 1)
local GRAY = Color3.fromRGB(100, 110, 130)
local SILVER = Color3.fromRGB(180, 190, 210)
local ROBUX_GREEN = Color3.fromRGB(0, 120, 220)

-- === AETHER ARSENAL SHOP GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "AetherArsenalShop"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Light frosted overlay (TextButton so clicks close the menu)
local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(200, 210, 230)
overlay.BackgroundTransparency = 0.6
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Parent = gui

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 600, 0, 650)
panel.Position = UDim2.new(0.5, -300, 0.5, -325)
panel.BackgroundColor3 = PANEL
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 15)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = ACCENT
panelStroke.Thickness = 2
panelStroke.Transparency = 0.3
panelStroke.Parent = panel

local panelShadow = Instance.new("UIStroke")
panelShadow.Color = Color3.fromRGB(150, 170, 200)
panelShadow.Thickness = 6
panelShadow.Transparency = 0.7
panelShadow.Parent = panel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = ACCENT
titleBar.BackgroundTransparency = 0.15
titleBar.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.8, 0, 1, 0)
title.Position = UDim2.new(0.05, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = WHITE
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "AETHER ARSENAL"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Close button (top right)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 190, 210)
closeBtn.TextColor3 = Color3.fromRGB(60, 70, 90)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- === TAB SYSTEM ===
local tabNames = {"Starter Packs", "Titan Rentals"}
local tabColors = {GOLD, ACCENT}
local tabs = {}
local activeTab = "Starter Packs"

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 40)
tabBar.Position = UDim2.new(0, 10, 0, 55)
tabBar.BackgroundColor3 = SILVER
local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 8)
tabCorner.Parent = tabBar
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -20, 1, -115)
contentFrame.Position = UDim2.new(0, 10, 0, 105)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = panel

local function switchTab(tabName)
	activeTab = tabName
	for tName, tBtn in pairs(tabs) do
		local idx = table.find(tabNames, tName)
		tBtn.BackgroundColor3 = (tName == activeTab) and tabColors[idx] or Color3.fromRGB(210, 220, 235)
	end
	for _, child in contentFrame:GetChildren() do
		if child:IsA("ScrollingFrame") then
			child.Visible = (child.Name == activeTab)
		end
	end
end

for i, name in ipairs(tabNames) do
	local tab = Instance.new("TextButton")
	tab.Name = name
	tab.Size = UDim2.new(0.5, -2, 1, 0)
	tab.BackgroundColor3 = (name == activeTab) and tabColors[i] or Color3.fromRGB(210, 220, 235)
	tab.BorderSizePixel = 0
	tab.Text = name
	tab.TextColor3 = (name == activeTab) and WHITE or GRAY
	tab.TextScaled = true
	tab.Font = Enum.Font.GothamBold
	tab.LayoutOrder = i
	tab.Parent = tabBar

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 6)
	tCorner.Parent = tab

	tabs[name] = tab
	tab.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- =====================
-- STARTER PACKS TAB
-- =====================
local packsScroll = Instance.new("ScrollingFrame")
packsScroll.Name = "Starter Packs"
packsScroll.Size = UDim2.new(1, 0, 1, 0)
packsScroll.BackgroundTransparency = 1
packsScroll.ScrollBarThickness = 6
packsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
packsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
packsScroll.Visible = true
packsScroll.Parent = contentFrame

local packsLayout = Instance.new("UIListLayout")
packsLayout.Padding = UDim.new(0, 8)
packsLayout.SortOrder = Enum.SortOrder.LayoutOrder
packsLayout.Parent = packsScroll

local packsPadding = Instance.new("UIPadding")
packsPadding.PaddingTop = UDim.new(0, 5)
packsPadding.PaddingLeft = UDim.new(0, 5)
packsPadding.PaddingRight = UDim.new(0, 5)
packsPadding.Parent = packsScroll

local packColors = {
	AetherRecruit = Color3.fromRGB(0, 120, 200),
	SkyCommander = Color3.fromRGB(150, 50, 200),
	AetherOverlord = Color3.fromRGB(200, 150, 0),
}

for packId, packDef in pairs(ShopDefs.StarterPacks) do
	local card = Instance.new("Frame")
	card.Name = packId
	card.Size = UDim2.new(1, 0, 0, 140)
	card.BackgroundColor3 = WHITE
	card.BackgroundTransparency = 0.1
	card.LayoutOrder = packDef.robuxCost
	card.Parent = packsScroll

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = packColors[packId] or ACCENT
	cardStroke.Thickness = 1.5
	cardStroke.Transparency = 0.3
	cardStroke.Parent = card

	local cardShadow = Instance.new("UIStroke")
	cardShadow.Color = SILVER
	cardShadow.Thickness = 4
	cardShadow.Transparency = 0.6
	cardShadow.Parent = card

	-- Pack name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = packColors[packId] or ACCENT
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = packDef.name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Price badge
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.35, 0, 0, 30)
	priceLabel.Position = UDim2.new(0.6, 0, 0, 5)
	priceLabel.BackgroundColor3 = ACCENT
	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0, 6)
	priceCorner.Parent = priceLabel
	priceLabel.TextColor3 = WHITE
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Text = "R$" .. packDef.robuxCost
	priceLabel.Parent = card

	-- Rewards list
	local rewardTexts = {}
	if packDef.rewards.xp then table.insert(rewardTexts, packDef.rewards.xp .. " XP") end
	if packDef.rewards.medals then table.insert(rewardTexts, packDef.rewards.medals .. " Medals") end
	if packDef.rewards.abilities then
		for _, abId in packDef.rewards.abilities do
			table.insert(rewardTexts, abId)
		end
	end
	if packDef.rewards.boostMinutes then table.insert(rewardTexts, packDef.rewards.boostMinutes .. "min Boost") end
	if packDef.rewards.titanTrialMinutes then table.insert(rewardTexts, packDef.rewards.titanTrialMinutes .. "min Titan") end
	if packDef.rewards.chests then
		for chestType, count in packDef.rewards.chests do
			table.insert(rewardTexts, count .. "x " .. chestType .. " Chest")
		end
	end

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(0.6, 0, 0, 70)
	rewardLabel.Position = UDim2.new(0, 10, 0, 35)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.TextColor3 = GRAY
	rewardLabel.TextScaled = true
	rewardLabel.Font = Enum.Font.Gotham
	rewardLabel.Text = table.concat(rewardTexts, " | ")
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
	rewardLabel.TextWrapped = true
	rewardLabel.Parent = card

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0.35, 0, 0, 40)
	buyBtn.Position = UDim2.new(0.6, 0, 0, 90)
	buyBtn.BackgroundColor3 = GOLD
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyBtn
	buyBtn.TextColor3 = WHITE
	buyBtn.TextScaled = true
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Text = "BUY R$" .. packDef.robuxCost
	buyBtn.Parent = card

	buyBtn.MouseButton1Click:Connect(function()
		local buyRemote = remotes:FindFirstChild("BuyShopItem")
		if buyRemote then
			buyRemote:FireServer("StarterPack", packId, "Robux")
		end
	end)
end

-- =====================
-- TITAN RENTALS TAB
-- =====================
local titanScroll = Instance.new("ScrollingFrame")
titanScroll.Name = "Titan Rentals"
titanScroll.Size = UDim2.new(1, 0, 1, 0)
titanScroll.BackgroundTransparency = 1
titanScroll.ScrollBarThickness = 6
titanScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
titanScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
titanScroll.Visible = false
titanScroll.Parent = contentFrame

local titanLayout = Instance.new("UIListLayout")
titanLayout.Padding = UDim.new(0, 8)
titanLayout.SortOrder = Enum.SortOrder.LayoutOrder
titanLayout.Parent = titanScroll

local titanPadding = Instance.new("UIPadding")
titanPadding.PaddingTop = UDim.new(0, 5)
titanPadding.PaddingLeft = UDim.new(0, 5)
titanPadding.PaddingRight = UDim.new(0, 5)
titanPadding.Parent = titanScroll

local titanColors = {
	AetherTitan = Color3.fromRGB(0, 200, 255),
	VoidTitan = Color3.fromRGB(150, 0, 200),
	StormTitan = Color3.fromRGB(255, 200, 0),
	EternalTitan = Color3.fromRGB(200, 50, 50),
}

local durationLabels = {[15] = "15 min", [30] = "30 min", [60] = "1 hour", [1440] = "24 hours"}

for titanId, titanDef in pairs(ShopDefs.TitanRentals) do
	local card = Instance.new("Frame")
	card.Name = titanId
	card.Size = UDim2.new(1, 0, 0, 120)
	card.BackgroundColor3 = WHITE
	card.BackgroundTransparency = 0.1
	card.LayoutOrder = (titanDef.prices[15] or 0)
	card.Parent = titanScroll

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = titanColors[titanId] or ACCENT
	cardStroke.Thickness = 1.5
	cardStroke.Transparency = 0.3
	cardStroke.Parent = card

	local cardShadow = Instance.new("UIStroke")
	cardShadow.Color = SILVER
	cardShadow.Thickness = 4
	cardShadow.Transparency = 0.6
	cardShadow.Parent = card

	-- Titan name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = titanColors[titanId] or ACCENT
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = titanDef.name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Duration/price buttons
	local btnX = 0.4
	for duration, price in titanDef.prices do
		local durBtn = Instance.new("TextButton")
		durBtn.Size = UDim2.new(0.14, 0, 0, 35)
		durBtn.Position = UDim2.new(btnX, 0, 0, 5)
		durBtn.BackgroundColor3 = ACCENT
		local durCorner = Instance.new("UICorner")
		durCorner.CornerRadius = UDim.new(0, 6)
		durCorner.Parent = durBtn
		durBtn.TextColor3 = WHITE
		durBtn.TextScaled = true
		durBtn.Font = Enum.Font.GothamBold
		durBtn.Text = (durationLabels[duration] or duration .. "m") .. "\nR$" .. price
		durBtn.Parent = card

		durBtn.MouseButton1Click:Connect(function()
			local buyRemote = remotes:FindFirstChild("BuyShopItem")
			if buyRemote then
				buyRemote:FireServer("TitanRental", titanId, duration)
			end
		end)

		btnX = btnX + 0.15
	end

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 60)
	descLabel.Position = UDim2.new(0, 10, 0, 45)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = GRAY
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = "Rent the " .. titanDef.name .. " for devastating aerial combat. Choose your duration above."
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = card
end

-- === CLOSE LOGIC ===
local function closeShop()
	gui.Enabled = false
end

closeBtn.MouseButton1Click:Connect(closeShop)
closeBtn.MouseButton2Click:Connect(closeShop)

overlay.MouseButton1Click:Connect(closeShop)

-- === OPEN FUNCTION ===
_G.OpenAetherArsenal = function()
	-- Close all other menus first
	if _G.CloseAllMenus then _G.CloseAllMenus() end
	gui.Enabled = true
	switchTab("Starter Packs")
end

print("[AetherArsenalShop] Initialized")