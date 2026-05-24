local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopDefs = require(ReplicatedStorage.Shared.ShopDefs)

-- Colors
local BG = Color3.fromRGB(15, 18, 30)
local PANEL = Color3.fromRGB(25, 30, 50)
local ACCENT = Color3.fromRGB(0, 150, 255)
local GOLD = Color3.fromRGB(255, 200, 0)
local GREEN = Color3.fromRGB(0, 255, 100)
local RED = Color3.fromRGB(255, 50, 50)
local WHITE = Color3.new(1, 1, 1)
local GRAY = Color3.fromRGB(150, 150, 150)

local chestColors = {
	Common = {bg = Color3.fromRGB(80, 80, 80), accent = Color3.fromRGB(180, 180, 180)},
	Rare = {bg = Color3.fromRGB(30, 60, 120), accent = Color3.fromRGB(80, 150, 255)},
	Epic = {bg = Color3.fromRGB(80, 20, 100), accent = Color3.fromRGB(200, 80, 255)},
}

-- === CHEST OPENER GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "ChestOpener"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Dark overlay (TextButton so clicks close the menu)
local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.6
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

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(20, 15, 0)
title.BackgroundTransparency = 0.5
title.TextColor3 = GOLD
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "OPEN CHEST"
title.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = title

-- Chest visual (large box)
local chestBox = Instance.new("Frame")
chestBox.Name = "ChestBox"
chestBox.Size = UDim2.new(0, 200, 0, 200)
chestBox.Position = UDim2.new(0.5, -100, 0, 70)
chestBox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
chestBox.BorderSizePixel = 0
chestBox.Parent = panel

local chestCorner = Instance.new("UICorner")
chestCorner.CornerRadius = UDim.new(0, 20)
chestCorner.Parent = chestBox

local chestStroke = Instance.new("UIStroke")
chestStroke.Name = "ChestStroke"
chestStroke.Color = Color3.fromRGB(180, 180, 180)
chestStroke.Thickness = 4
chestStroke.Parent = chestBox

-- Chest icon (question mark)
local chestIcon = Instance.new("TextLabel")
chestIcon.Size = UDim2.new(1, 0, 1, 0)
chestIcon.BackgroundTransparency = 1
chestIcon.TextColor3 = WHITE
chestIcon.TextScaled = true
chestIcon.Font = Enum.Font.GothamBold
chestIcon.Text = "?"
chestIcon.Parent = chestBox

-- Chest count display
local chestCountLabel = Instance.new("TextLabel")
chestCountLabel.Name = "ChestCount"
chestCountLabel.Size = UDim2.new(1, 0, 0, 30)
chestCountLabel.Position = UDim2.new(0, 0, 0, 280)
chestCountLabel.BackgroundTransparency = 1
chestCountLabel.TextColor3 = WHITE
chestCountLabel.TextScaled = true
chestCountLabel.Font = Enum.Font.GothamBold
chestCountLabel.Text = "0 Common Chests"
chestCountLabel.Parent = panel

-- Open button
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenBtn"
openBtn.Size = UDim2.new(0.6, 0, 0, 50)
openBtn.Position = UDim2.new(0.2, 0, 0, 320)
openBtn.BackgroundColor3 = GOLD
openBtn.TextColor3 = Color3.new(0, 0, 0)
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.Text = "OPEN"
openBtn.Parent = panel

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 10)
openCorner.Parent = openBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.25, 0, 0, 50)
closeBtn.Position = UDim2.new(0.72, 0, 0, 320)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
closeBtn.TextColor3 = WHITE
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "Close"
closeBtn.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

-- Result display
local resultFrame = Instance.new("Frame")
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(0.9, 0, 0, 100)
resultFrame.Position = UDim2.new(0.05, 0, 0, 385)
resultFrame.BackgroundColor3 = Color3.fromRGB(0, 60, 0)
resultFrame.BackgroundTransparency = 0.5
resultFrame.BorderSizePixel = 0
resultFrame.Visible = false
resultFrame.Parent = panel

local resCorner = Instance.new("UICorner")
resCorner.CornerRadius = UDim.new(0, 10)
resCorner.Parent = resultFrame

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultText"
resultLabel.Size = UDim2.new(1, 0, 1, 0)
resultLabel.BackgroundTransparency = 1
resultLabel.TextColor3 = GREEN
resultLabel.TextScaled = true
resultLabel.Font = Enum.Font.GothamBold
resultLabel.Text = ""
resultLabel.Parent = resultFrame

-- === STATE ===
local currentChestType = "Common"
local isOpening = false

local function updateChestVisual(chestType)
	currentChestType = chestType
	local colors = chestColors[chestType] or chestColors.Common
	chestBox.BackgroundColor3 = colors.bg
	chestStroke.Color = colors.accent
	title.Text = "OPEN " .. string.upper(chestType) .. " CHEST"
end

local function updateChestCount(data)
	if not data or not data.Chests then return end
	local count = data.Chests[currentChestType] or 0
	chestCountLabel.Text = count .. " " .. currentChestType .. " Chests"
	openBtn.Visible = count > 0
end

-- === OPEN LOGIC ===
openBtn.MouseButton1Click:Connect(function()
	if isOpening then return end
	isOpening = true
	openBtn.Text = "OPENING..."
	openBtn.BackgroundColor3 = GRAY
	resultFrame.Visible = false

	-- Shake animation
	local shakeInfo = TweenInfo.new(0.05, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 8, true, 0)
	local shakeTween = TweenService:Create(chestBox, shakeInfo, {
		Position = UDim2.new(0.5, -100, 0, 65),
	})
	shakeTween:Play()

	-- Request open from server
	local openRemote = remotes:FindFirstChild("OpenChest")
	if openRemote then
		openRemote:FireServer(currentChestType)
	end
end)

-- Listen for chest result
local chestResult = remotes:WaitForChild("ChestResult")
chestResult.OnClientEvent:Connect(function(data)
	isOpening = false
	openBtn.Text = "OPEN"
	openBtn.BackgroundColor3 = GOLD

	if data and data.success then
		-- Flash the chest
		local flashInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 3, true)
		local flashTween = TweenService:Create(chestBox, flashInfo, {
			BackgroundColor3 = Color3.fromRGB(255, 255, 200),
		})
		flashTween:Play()

		-- Show result
		local rewardText = ""
		if data.reward then
			if data.reward.type == "XP" then
				rewardText = "+" .. data.reward.value .. " XP!"
			elseif data.reward.type == "Medals" then
				rewardText = "+" .. data.reward.value .. " Medals!"
			elseif data.reward.type == "Ability" then
				rewardText = "Unlocked: " .. (data.reward.id or "Ability") .. "!"
			elseif data.reward.type == "TitanTrial" then
				rewardText = "Titan Trial: " .. (data.reward.id or "Titan") .. " (" .. (data.reward.minutes or 0) .. "min)!"
			end
		end

		resultLabel.Text = rewardText
		resultFrame.Visible = true

		-- Update chest count
		local getData = remotes:FindFirstChild("GetData")
		if getData then
			task.spawn(function()
				local d = getData:InvokeServer()
				if d then updateChestCount(d) end
			end)
		end
	else
		resultLabel.Text = "No chests available!"
		resultLabel.TextColor3 = RED
		resultFrame.Visible = true
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

overlay.MouseButton1Click:Connect(function()
	if not isOpening then
		gui.Enabled = false
	end
end)

-- === OPEN TRIGGER ===
gui:SetAttribute("CanOpen", true)

gui:GetAttributeChangedSignal("Open"):Connect(function()
	if gui:GetAttribute("Open") then
		if _G.CloseAllMenus then _G.CloseAllMenus() end
		gui.Enabled = true
		resultFrame.Visible = false
		local chestType = gui:GetAttribute("ChestType") or "Common"
		updateChestVisual(chestType)

		-- Get chest counts
		local getData = remotes:FindFirstChild("GetData")
		if getData then
			task.spawn(function()
				local data = getData:InvokeServer()
				if data then updateChestCount(data) end
			end)
		end
	end
end)