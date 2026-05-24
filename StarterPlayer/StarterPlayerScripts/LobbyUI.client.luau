local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Lobby UI: Portal hover tooltips, holographic effects, and HUD buttons

-- === CENTRALIZED MENU MANAGEMENT ===
-- Only one menu can be open at a time. All menus call this before opening.
local ALL_MENU_NAMES = {
	"UpgradeTerminalMenu",
	"JetHangarMenu",
	"AetherArsenalShop",
	"PrizeWheel",
	"DailyLoginStreak",
	"IncrementalRewards",
	"RankingMenu",
	"ChestOpener",
}

_G.CloseAllMenus = function()
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	for _, menuName in ipairs(ALL_MENU_NAMES) do
		local menu = playerGui:FindFirstChild(menuName)
		if menu and menu.Enabled then
			menu.Enabled = false
		end
	end
end

-- Global ESC key handler to close any open menu
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		-- Check if any menu is open and close it
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, menuName in ipairs(ALL_MENU_NAMES) do
				local menu = playerGui:FindFirstChild(menuName)
				if menu and menu.Enabled then
					menu.Enabled = false
					return -- Only close one menu per ESC press
				end
			end
		end
	end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LobbyUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Portal tooltip
local tooltip = Instance.new("Frame")
tooltip.Name = "PortalTooltip"
tooltip.Size = UDim2.new(0, 200, 0, 60)
tooltip.Position = UDim2.new(0.5, -100, 0, 0)
tooltip.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
tooltip.BackgroundTransparency = 0.3
tooltip.BorderSizePixel = 0
tooltip.Visible = false
tooltip.Parent = screenGui

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 8)
tooltipCorner.Parent = tooltip

local tooltipStroke = Instance.new("UIStroke")
tooltipStroke.Color = Color3.fromRGB(0, 150, 255)
tooltipStroke.Thickness = 2
tooltipStroke.Parent = tooltip

local tooltipText = Instance.new("TextLabel")
tooltipText.Size = UDim2.new(1, -10, 1, -10)
tooltipText.Position = UDim2.new(0, 5, 0, 5)
tooltipText.BackgroundTransparency = 1
tooltipText.TextColor3 = Color3.new(1, 1, 1)
tooltipText.TextScaled = true
tooltipText.Font = Enum.Font.GothamBold
tooltipText.Text = ""
tooltipText.Parent = tooltip

-- Message display (for VIP required, arena full, etc.)
local messageFrame = Instance.new("Frame")
messageFrame.Name = "MessageDisplay"
messageFrame.Size = UDim2.new(0, 400, 0, 50)
messageFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
messageFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
messageFrame.BackgroundTransparency = 0.2
messageFrame.BorderSizePixel = 0
messageFrame.Visible = false
messageFrame.Parent = screenGui

local msgCorner = Instance.new("UICorner")
msgCorner.CornerRadius = UDim.new(0, 10)
msgCorner.Parent = messageFrame

local msgStroke = Instance.new("UIStroke")
msgStroke.Color = Color3.fromRGB(255, 100, 50)
msgStroke.Thickness = 2
msgStroke.Parent = messageFrame

local msgText = Instance.new("TextLabel")
msgText.Size = UDim2.new(1, -10, 1, -10)
msgText.Position = UDim2.new(0, 5, 0, 5)
msgText.BackgroundTransparency = 1
msgText.TextColor3 = Color3.new(1, 1, 1)
msgText.TextScaled = true
msgText.Font = Enum.Font.GothamBold
msgText.Parent = messageFrame

-- Show message function
local function showMessage(text, duration)
	msgText.Text = text
	messageFrame.Visible = true
	messageFrame.BackgroundTransparency = 0.2
	task.delay(duration or 3, function()
		local tween = TweenService:Create(messageFrame, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			messageFrame.Visible = false
		end)
	end)
end

-- Listen for server messages
local updateClient = remotes:WaitForChild("UpdateClient")
updateClient.OnClientEvent:Connect(function(data)
	if data.message then
		showMessage(data.message, 3)
	end
end)

-- Listen for arena join
local joinArena = remotes:WaitForChild("JoinArena")
joinArena.OnClientEvent:Connect(function(arenaType)
	showMessage("Entering " .. arenaType .. " Arena...", 2)
end)

-- Floating rank emblem in lobby
local function createRankEmblem(character)
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "RankEmblem"
	bbGui.Adornee = head
	bbGui.Size = UDim2.new(0, 60, 0, 20)
	bbGui.StudsOffset = Vector3.new(0, 3, 0)
	bbGui.AlwaysOnTop = true
	bbGui.MaxDistance = 100
	bbGui.Parent = head

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(1, 0, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	rankLabel.TextScaled = true
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.Text = "Iron 1"
	rankLabel.Parent = bbGui

	-- Request rank data
	local getData = remotes:WaitForChild("GetData")
	task.spawn(function()
		local data = getData:InvokeServer()
		if data and data.Rank then
			local RankDefs = require(ReplicatedStorage.Shared.RankDefs)
			rankLabel.Text = RankDefs.GetDisplay(data.Rank)
			local tier = RankDefs.GetTier(data.Rank)
			local colors = RankDefs.TierColors[tier]
			if colors then
				rankLabel.TextColor3 = Color3.new(colors.r, colors.g, colors.b)
			end
		end
	end)
end

-- Setup rank emblem on character spawn
player.CharacterAdded:Connect(createRankEmblem)
if player.Character then
	task.spawn(createRankEmblem, player.Character)
end

-- === LOBBY HUD INDICATOR ===
local lobbyHud = Instance.new("Frame")
lobbyHud.Name = "LobbyHud"
lobbyHud.Size = UDim2.new(0, 300, 0, 80)
lobbyHud.Position = UDim2.new(0.5, -150, 1, -100)
lobbyHud.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
lobbyHud.BackgroundTransparency = 0.3
lobbyHud.BorderSizePixel = 0
lobbyHud.Visible = true
lobbyHud.Parent = screenGui

local lobbyHudCorner = Instance.new("UICorner")
lobbyHudCorner.CornerRadius = UDim.new(0, 10)
lobbyHudCorner.Parent = lobbyHud

local lobbyHudStroke = Instance.new("UIStroke")
lobbyHudStroke.Color = Color3.fromRGB(0, 150, 255)
lobbyHudStroke.Thickness = 1.5
lobbyHudStroke.Parent = lobbyHud

local lobbyTitle = Instance.new("TextLabel")
lobbyTitle.Size = UDim2.new(1, -10, 0.4, 0)
lobbyTitle.Position = UDim2.new(0, 5, 0, 2)
lobbyTitle.BackgroundTransparency = 1
lobbyTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
lobbyTitle.TextScaled = true
lobbyTitle.Font = Enum.Font.GothamBold
lobbyTitle.Text = "AETHER AIRBASE - LOBBY"
lobbyTitle.Parent = lobbyHud

local lobbyHint = Instance.new("TextLabel")
lobbyHint.Size = UDim2.new(1, -10, 0.4, 0)
lobbyHint.Position = UDim2.new(0, 5, 0.45, 0)
lobbyHint.BackgroundTransparency = 1
lobbyHint.TextColor3 = Color3.fromRGB(180, 180, 180)
lobbyHint.TextScaled = true
lobbyHint.Font = Enum.Font.Gotham
lobbyHint.Text = "Walk into glowing zones to interact | Portals to enter arena"
lobbyHint.TextXAlignment = Enum.TextXAlignment.Left
lobbyHint.Parent = lobbyHud

-- Hide lobby HUD when in arena
local joinArenaRemote = remotes:FindFirstChild("JoinArena")
if joinArenaRemote then
	joinArenaRemote.OnClientEvent:Connect(function()
		lobbyHud.Visible = false
	end)
end

local leaveArenaRemote = remotes:FindFirstChild("LeaveArena")
if leaveArenaRemote then
	leaveArenaRemote.OnClientEvent:Connect(function()
		lobbyHud.Visible = true
	end)
end

-- === LOBBY MODE INDICATOR ===
local lobbyModeIndicator = Instance.new("Frame")
lobbyModeIndicator.Name = "LobbyModeIndicator"
lobbyModeIndicator.Size = UDim2.new(0, 200, 0, 40)
lobbyModeIndicator.Position = UDim2.new(0.5, -100, 0, 0)
lobbyModeIndicator.BackgroundColor3 = Color3.fromRGB(0, 80, 160)
lobbyModeIndicator.BackgroundTransparency = 0.3
lobbyModeIndicator.BorderSizePixel = 0
lobbyModeIndicator.Visible = true
lobbyModeIndicator.Parent = screenGui

local lmiCorner = Instance.new("UICorner")
lmiCorner.CornerRadius = UDim.new(0, 8)
lmiCorner.Parent = lobbyModeIndicator

local lmiLabel = Instance.new("TextLabel")
lmiLabel.Size = UDim2.new(1, 0, 1, 0)
lmiLabel.BackgroundTransparency = 1
lmiLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
lmiLabel.TextScaled = true
lmiLabel.Font = Enum.Font.GothamBold
lmiLabel.Text = "LOBBY MODE - TAXI"
lmiLabel.Parent = lobbyModeIndicator

-- Hide lobby mode indicator when in arena
if joinArenaRemote then
	joinArenaRemote.OnClientEvent:Connect(function()
		lobbyModeIndicator.Visible = false
	end)
end

if leaveArenaRemote then
	leaveArenaRemote.OnClientEvent:Connect(function()
		lobbyModeIndicator.Visible = true
	end)
end

-- Animate portal glow effects and interaction zone pulses
local animLobbyFolder = workspace:FindFirstChild("Lobby")
task.spawn(function()
	if not animLobbyFolder then return end

	while true do
		for t = 0, 10, 0.03 do
			task.wait(0.03)
			-- Portal pulse
			for _, portalName in ipairs({"NormalPortal", "MEGAPortal", "PVPPortal", "VIPPortal"}) do
				local portal = animLobbyFolder:FindFirstChild(portalName)
				if portal then
					local surface = portal:FindFirstChild("PortalSurface")
					if surface then
						surface.Transparency = 0.3 + 0.2 * math.sin(t * 2)
					end
				end
			end
			-- Interaction zone circle pulse (more dramatic)
			local zonesFolder = animLobbyFolder:FindFirstChild("InteractionZones")
			if zonesFolder then
				for _, circleName in ipairs({"UpgradeTerminalCircle", "JetHangarCircle"}) do
					local circle = zonesFolder:FindFirstChild(circleName)
					if circle then
						circle.Transparency = 0.15 + 0.25 * math.sin(t * 3)
						local light = circle:FindFirstChild("PointLight")
						if light then
							light.Brightness = 2 + 2 * math.sin(t * 3)
						end
					end
				end
			end
		end
	end
end)

-- === ZONE PROXIMITY LABELS ===
local zoneLabels = {
	{partName = "UpgradeTerminalCircle", text = "UPGRADE TERMINAL", color = Color3.fromRGB(0, 255, 100)},
	{partName = "JetHangarCircle", text = "JET HANGAR", color = Color3.fromRGB(0, 150, 255)},
}

local zoneBillboards = {}
if animLobbyFolder then
	local zonesFolder = animLobbyFolder:FindFirstChild("InteractionZones")
	if zonesFolder then
		for _, zoneConfig in ipairs(zoneLabels) do
			local zonePart = zonesFolder:FindFirstChild(zoneConfig.partName)
			if zonePart then
				-- Skip if ZoneLabel already exists (e.g. from previous run)
				if zonePart:FindFirstChild("ZoneLabel") then
					zoneBillboards[zoneConfig.partName] = zonePart:FindFirstChild("ZoneLabel")
					-- Update existing label for new size
					local bb = zonePart:FindFirstChild("ZoneLabel")
					if bb then
						bb.Size = UDim2.new(0, 500, 0, 70)
						bb.StudsOffset = Vector3.new(0, 12, 0)
						bb.MaxDistance = 150
						for _, child in ipairs(bb:GetChildren()) do
							if child:IsA("TextLabel") then
								child.TextStrokeTransparency = 0.3
								child.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
							end
						end
					end
					continue
				end

				local bb = Instance.new("BillboardGui")
				bb.Name = "ZoneLabel"
				bb.Adornee = zonePart
				bb.Size = UDim2.new(0, 500, 0, 70)
				bb.StudsOffset = Vector3.new(0, 12, 0)
				bb.AlwaysOnTop = true
				bb.MaxDistance = 150
				bb.Parent = zonePart

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 0.6, 0)
				label.BackgroundTransparency = 1
				label.TextColor3 = zoneConfig.color
				label.TextScaled = true
				label.Font = Enum.Font.GothamBold
				label.Text = zoneConfig.text
				label.TextStrokeTransparency = 0.3
				label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				label.Parent = bb

				-- Sub-label with instruction
				local subLabel = Instance.new("TextLabel")
				subLabel.Size = UDim2.new(1, 0, 0.4, 0)
				subLabel.Position = UDim2.new(0, 0, 0.6, 0)
				subLabel.BackgroundTransparency = 1
				subLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				subLabel.TextScaled = true
				subLabel.Font = Enum.Font.Gotham
				subLabel.Text = "Walk in to open"
				subLabel.TextStrokeTransparency = 0.5
				subLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				subLabel.Parent = bb

				zoneBillboards[zoneConfig.partName] = bb
			end
		end
	end
end

-- === LANDING PAD INDICATOR ===
if animLobbyFolder then
	local landingPad = animLobbyFolder:FindFirstChild("LandingPad")
	if landingPad then
		local padBB = Instance.new("BillboardGui")
		padBB.Name = "PadLabel"
		padBB.Adornee = landingPad
		padBB.Size = UDim2.new(0, 300, 0, 40)
		padBB.StudsOffset = Vector3.new(0, 5, 0)
		padBB.AlwaysOnTop = true
		padBB.MaxDistance = 60
		padBB.Parent = landingPad

		local padLabel = Instance.new("TextLabel")
		padLabel.Size = UDim2.new(1, 0, 1, 0)
		padLabel.BackgroundTransparency = 1
		padLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
		padLabel.TextScaled = true
		padLabel.Font = Enum.Font.GothamBold
		padLabel.Text = "AETHER AIRBASE"
		padLabel.Parent = padBB
	end
end

-- === ROBUX SHOP CHEST ICON ===
local chestIcon = Instance.new("TextButton")
chestIcon.Name = "ChestIcon"
chestIcon.Size = UDim2.new(0, 64, 0, 64)
chestIcon.Position = UDim2.new(0, 15, 0.5, -32)
chestIcon.BackgroundColor3 = Color3.fromRGB(0, 60, 30)
chestIcon.BorderSizePixel = 0
chestIcon.Text = ""
chestIcon.AutoButtonColor = false
chestIcon.Parent = screenGui

local chestCorner = Instance.new("UICorner")
chestCorner.CornerRadius = UDim.new(0, 12)
chestCorner.Parent = chestIcon

local chestStroke = Instance.new("UIStroke")
chestStroke.Color = Color3.fromRGB(0, 200, 100)
chestStroke.Thickness = 2
chestStroke.Parent = chestIcon

-- Chest icon (using Unicode treasure chest)
local chestLabel = Instance.new("TextLabel")
chestLabel.Size = UDim2.new(1, 0, 0.7, 0)
chestLabel.Position = UDim2.new(0, 0, 0, 0)
chestLabel.BackgroundTransparency = 1
chestLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
chestLabel.TextScaled = true
chestLabel.Font = Enum.Font.GothamBold
chestLabel.Text = "\xe2\x9a\xa1" -- lightning bolt as placeholder
chestLabel.Parent = chestIcon

-- "SHOP" label below icon
local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.new(1, 0, 0.3, 0)
shopLabel.Position = UDim2.new(0, 0, 0.7, 0)
shopLabel.BackgroundTransparency = 1
shopLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
shopLabel.TextScaled = true
shopLabel.Font = Enum.Font.GothamBold
shopLabel.Text = "SHOP"
shopLabel.Parent = chestIcon

-- Glow effect behind chest icon
local chestGlow = Instance.new("ImageLabel")
chestGlow.Size = UDim2.new(0, 100, 0, 100)
chestGlow.Position = UDim2.new(0.5, -50, 0.5, -50)
chestGlow.BackgroundTransparency = 1
chestGlow.Image = "rbxassetid://7669168585"
chestGlow.ImageColor3 = Color3.fromRGB(0, 200, 100)
chestGlow.ImageTransparency = 0.6
chestGlow.Parent = chestIcon

-- Floating animation
local floatUp = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local floatDown = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function floatChest()
	while true do
		local up = TweenService:Create(chestIcon, floatUp, {Position = UDim2.new(0, 15, 0.5, -38)})
		up:Play()
		up.Completed:Wait()
		local down = TweenService:Create(chestIcon, floatDown, {Position = UDim2.new(0, 15, 0.5, -26)})
		down:Play()
		down.Completed:Wait()
	end
end
task.spawn(floatChest)

-- Glow pulse animation
local function pulseGlow()
	while true do
		local pulse = TweenService:Create(chestGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			ImageTransparency = 0.3,
		})
		pulse:Play()
		pulse.Completed:Wait()
		local dim = TweenService:Create(chestGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			ImageTransparency = 0.8,
		})
		dim:Play()
		dim.Completed:Wait()
	end
end
task.spawn(pulseGlow)

-- Hover effect
chestIcon.MouseEnter:Connect(function()
	TweenService:Create(chestIcon, TweenInfo.new(0.2), {Size = UDim2.new(0, 72, 0, 72)}):Play()
	TweenService:Create(chestStroke, TweenInfo.new(0.2), {Thickness = 3, Color = Color3.fromRGB(0, 255, 150)}):Play()
end)

chestIcon.MouseLeave:Connect(function()
	TweenService:Create(chestIcon, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 64)}):Play()
	TweenService:Create(chestStroke, TweenInfo.new(0.2), {Thickness = 2, Color = Color3.fromRGB(0, 200, 100)}):Play()
end)

-- Click to open Aether Arsenal shop
chestIcon.MouseButton1Click:Connect(function()
	-- Click feedback
	TweenService:Create(chestIcon, TweenInfo.new(0.1), {Size = UDim2.new(0, 56, 0, 56)}):Play()
	task.delay(0.1, function()
		TweenService:Create(chestIcon, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 64)}):Play()
	end)

	-- Open the Aether Arsenal shop
	if _G.OpenAetherArsenal then
		_G.OpenAetherArsenal()
	end
end)

-- === PRIZE WHEEL BUTTON ===
local wheelBtn = Instance.new("TextButton")
wheelBtn.Name = "WheelBtn"
wheelBtn.Size = UDim2.new(0, 64, 0, 64)
wheelBtn.Position = UDim2.new(0, 15, 0.5, 42)
wheelBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 0)
wheelBtn.BorderSizePixel = 0
wheelBtn.Text = ""
wheelBtn.AutoButtonColor = false
wheelBtn.Parent = screenGui

local wheelBtnCorner = Instance.new("UICorner")
wheelBtnCorner.CornerRadius = UDim.new(0, 12)
wheelBtnCorner.Parent = wheelBtn

local wheelBtnStroke = Instance.new("UIStroke")
wheelBtnStroke.Color = Color3.fromRGB(255, 200, 0)
wheelBtnStroke.Thickness = 2
wheelBtnStroke.Parent = wheelBtn

local wheelIcon = Instance.new("TextLabel")
wheelIcon.Size = UDim2.new(1, 0, 0.7, 0)
wheelIcon.BackgroundTransparency = 1
wheelIcon.TextColor3 = Color3.fromRGB(255, 200, 0)
wheelIcon.TextScaled = true
wheelIcon.Font = Enum.Font.GothamBold
wheelIcon.Text = "\xe2\x9a\x99" -- gear symbol
wheelIcon.Parent = wheelBtn

local wheelLabel = Instance.new("TextLabel")
wheelLabel.Size = UDim2.new(1, 0, 0.3, 0)
wheelLabel.Position = UDim2.new(0, 0, 0.7, 0)
wheelLabel.BackgroundTransparency = 1
wheelLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
wheelLabel.TextScaled = true
wheelLabel.Font = Enum.Font.GothamBold
wheelLabel.Text = "WHEEL"
wheelLabel.Parent = wheelBtn

-- Glow for wheel button
local wheelGlow = Instance.new("ImageLabel")
wheelGlow.Size = UDim2.new(0, 100, 0, 100)
wheelGlow.Position = UDim2.new(0.5, -50, 0.5, -50)
wheelGlow.BackgroundTransparency = 1
wheelGlow.Image = "rbxassetid://7669168585"
wheelGlow.ImageColor3 = Color3.fromRGB(255, 200, 0)
wheelGlow.ImageTransparency = 0.6
wheelGlow.Parent = wheelBtn

-- Wheel glow pulse
local function pulseWheelGlow()
	while true do
		local pulse = TweenService:Create(wheelGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			ImageTransparency = 0.3,
		})
		pulse:Play()
		pulse.Completed:Wait()
		local dim = TweenService:Create(wheelGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			ImageTransparency = 0.8,
		})
		dim:Play()
		dim.Completed:Wait()
	end
end
task.spawn(pulseWheelGlow)

-- Hover effect
wheelBtn.MouseEnter:Connect(function()
	TweenService:Create(wheelBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 72, 0, 72)}):Play()
	TweenService:Create(wheelBtnStroke, TweenInfo.new(0.2), {Thickness = 3, Color = Color3.fromRGB(255, 230, 50)}):Play()
end)

wheelBtn.MouseLeave:Connect(function()
	TweenService:Create(wheelBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 64)}):Play()
	TweenService:Create(wheelBtnStroke, TweenInfo.new(0.2), {Thickness = 2, Color = Color3.fromRGB(255, 200, 0)}):Play()
end)

-- Click to open Prize Wheel
wheelBtn.MouseButton1Click:Connect(function()
	TweenService:Create(wheelBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 56, 0, 56)}):Play()
	task.delay(0.1, function()
		TweenService:Create(wheelBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 64)}):Play()
	end)

	if _G.OpenPrizeWheel then
		_G.OpenPrizeWheel()
	end
end)

-- Hide both icons when in arena
if joinArenaRemote then
	joinArenaRemote.OnClientEvent:Connect(function()
		chestIcon.Visible = false
		wheelBtn.Visible = false
	end)
end

if leaveArenaRemote then
	leaveArenaRemote.OnClientEvent:Connect(function()
		chestIcon.Visible = true
		wheelBtn.Visible = true
	end)
end

-- === RANK EMBLEM BUTTON (Right Side) ===
local rankBtn = Instance.new("TextButton")
rankBtn.Name = "RankBtn"
rankBtn.Size = UDim2.new(0, 64, 0, 64)
rankBtn.Position = UDim2.new(1, -79, 0.5, -32)
rankBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
rankBtn.BorderSizePixel = 0
rankBtn.Text = ""
rankBtn.AutoButtonColor = false
rankBtn.Parent = screenGui

local rankCorner = Instance.new("UICorner")
rankCorner.CornerRadius = UDim.new(0, 12)
rankCorner.Parent = rankBtn

local rankStroke = Instance.new("UIStroke")
rankStroke.Color = Color3.fromRGB(200, 150, 255)
rankStroke.Thickness = 2
rankStroke.Parent = rankBtn

local rankIcon = Instance.new("TextLabel")
rankIcon.Size = UDim2.new(1, 0, 0.7, 0)
rankIcon.BackgroundTransparency = 1
rankIcon.TextColor3 = Color3.fromRGB(200, 150, 255)
rankIcon.TextScaled = true
rankIcon.Font = Enum.Font.GothamBold
rankIcon.Text = "\xe2\x98\x85"
rankIcon.Parent = rankBtn

local rankLabel = Instance.new("TextLabel")
rankLabel.Size = UDim2.new(1, 0, 0.3, 0)
rankLabel.Position = UDim2.new(0, 0, 0.7, 0)
rankLabel.BackgroundTransparency = 1
rankLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
rankLabel.TextScaled = true
rankLabel.Font = Enum.Font.GothamBold
rankLabel.Text = "RANK"
rankLabel.Parent = rankBtn

local rankGlow = Instance.new("ImageLabel")
rankGlow.Size = UDim2.new(0, 100, 0, 100)
rankGlow.Position = UDim2.new(0.5, -50, 0.5, -50)
rankGlow.BackgroundTransparency = 1
rankGlow.Image = "rbxassetid://7669168585"
rankGlow.ImageColor3 = Color3.fromRGB(200, 150, 255)
rankGlow.ImageTransparency = 0.6
rankGlow.Parent = rankBtn

rankBtn.MouseEnter:Connect(function()
	TweenService:Create(rankBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 72, 0, 72)}):Play()
	TweenService:Create(rankStroke, TweenInfo.new(0.2), {Thickness = 3, Color = Color3.fromRGB(255, 180, 255)}):Play()
end)
rankBtn.MouseLeave:Connect(function()
	TweenService:Create(rankBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 64)}):Play()
	TweenService:Create(rankStroke, TweenInfo.new(0.2), {Thickness = 2, Color = Color3.fromRGB(200, 150, 255)}):Play()
end)
rankBtn.MouseButton1Click:Connect(function()
	if _G.OpenRankingMenu then _G.OpenRankingMenu() end
end)

-- === GIFT / PRESENT BUTTON (Right Side, below Rank) ===
local giftBtn = Instance.new("TextButton")
giftBtn.Name = "GiftBtn"
giftBtn.Size = UDim2.new(0, 64, 0, 64)
giftBtn.Position = UDim2.new(1, -79, 0.5, 42)
giftBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 0)
giftBtn.BorderSizePixel = 0
giftBtn.Text = ""
giftBtn.AutoButtonColor = false
giftBtn.Parent = screenGui

local giftCorner = Instance.new("UICorner")
giftCorner.CornerRadius = UDim.new(0, 12)
giftCorner.Parent = giftBtn

local giftStroke = Instance.new("UIStroke")
giftStroke.Color = Color3.fromRGB(255, 200, 0)
giftStroke.Thickness = 2
giftStroke.Parent = giftBtn

local giftIcon = Instance.new("TextLabel")
giftIcon.Size = UDim2.new(1, 0, 0.7, 0)
giftIcon.BackgroundTransparency = 1
giftIcon.TextColor3 = Color3.fromRGB(255, 200, 0)
giftIcon.TextScaled = true
giftIcon.Font = Enum.Font.GothamBold
giftIcon.Text = "\xf0\x9f\x8e\x81"
giftIcon.Parent = giftBtn

local giftLabel = Instance.new("TextLabel")
giftLabel.Size = UDim2.new(1, 0, 0.3, 0)
giftLabel.Position = UDim2.new(0, 0, 0.7, 0)
giftLabel.BackgroundTransparency = 1
giftLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
giftLabel.TextScaled = true
giftLabel.Font = Enum.Font.GothamBold
giftLabel.Text = "GIFTS"
giftLabel.Parent = giftBtn

local giftGlow = Instance.new("ImageLabel")
giftGlow.Size = UDim2.new(0, 100, 0, 100)
giftGlow.Position = UDim2.new(0.5, -50, 0.5, -50)
giftGlow.BackgroundTransparency = 1
giftGlow.Image = "rbxassetid://7669168585"
giftGlow.ImageColor3 = Color3.fromRGB(255, 200, 0)
giftGlow.ImageTransparency = 0.6
giftGlow.Parent = giftBtn

giftBtn.MouseEnter:Connect(function()
	TweenService:Create(giftBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 72, 0, 72)}):Play()
	TweenService:Create(giftStroke, TweenInfo.new(0.2), {Thickness = 3, Color = Color3.fromRGB(255, 230, 50)}):Play()
end)
giftBtn.MouseLeave:Connect(function()
	TweenService:Create(giftBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 64)}):Play()
	TweenService:Create(giftStroke, TweenInfo.new(0.2), {Thickness = 2, Color = Color3.fromRGB(255, 200, 0)}):Play()
end)
giftBtn.MouseButton1Click:Connect(function()
	if _G.OpenIncrementalRewards then _G.OpenIncrementalRewards() end
end)

-- === DAILY LOGIN STREAK BUTTON (near Gift button) ===
local streakDisplay = Instance.new("TextButton")
streakDisplay.Name = "StreakDisplay"
streakDisplay.Size = UDim2.new(0, 80, 0, 30)
streakDisplay.Position = UDim2.new(1, -87, 0.5, 110)
streakDisplay.BackgroundColor3 = Color3.fromRGB(40, 20, 0)
streakDisplay.BackgroundTransparency = 0.3
streakDisplay.BorderSizePixel = 0
streakDisplay.Text = ""
streakDisplay.AutoButtonColor = false
streakDisplay.Parent = screenGui

local streakCorner = Instance.new("UICorner")
streakCorner.CornerRadius = UDim.new(0, 8)
streakCorner.Parent = streakDisplay

local streakStroke = Instance.new("UIStroke")
streakStroke.Color = Color3.fromRGB(255, 150, 0)
streakStroke.Thickness = 1.5
streakStroke.Parent = streakDisplay

local streakLabel = Instance.new("TextLabel")
streakLabel.Name = "StreakLabel"
streakLabel.Size = UDim2.new(1, 0, 1, 0)
streakLabel.BackgroundTransparency = 1
streakLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
streakLabel.TextScaled = true
streakLabel.Font = Enum.Font.GothamBold
streakLabel.Text = "Day 1"
streakLabel.Parent = streakDisplay

-- Click streak display to open Daily Login menu
streakDisplay.MouseButton1Click:Connect(function()
	if _G.OpenDailyLoginStreak then _G.OpenDailyLoginStreak() end
end)

-- Hover effect for streak display
streakDisplay.MouseEnter:Connect(function()
	TweenService:Create(streakDisplay, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	TweenService:Create(streakStroke, TweenInfo.new(0.2), {Thickness = 2.5, Color = Color3.fromRGB(255, 200, 0)}):Play()
end)
streakDisplay.MouseLeave:Connect(function()
	TweenService:Create(streakDisplay, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
	TweenService:Create(streakStroke, TweenInfo.new(0.2), {Thickness = 1.5, Color = Color3.fromRGB(255, 150, 0)}):Play()
end)

-- Update streak display from server data
local dailyLoginResult = remotes:FindFirstChild("DailyLoginResult")
if dailyLoginResult then
	dailyLoginResult.OnClientEvent:Connect(function(data)
		if data.streak then
			streakLabel.Text = "Day " .. data.streak
			if data.streak >= 7 then
				streakLabel.Text = "Day " .. data.streak .. " \xf0\x9f\x94\xa5"
			elseif data.streak >= 3 then
				streakLabel.Text = "Day " .. data.streak .. " \xe2\x9c\xa8"
			end
		end
	end)
end

-- Request streak data on load
task.spawn(function()
	local getData = remotes:FindFirstChild("GetData")
	if getData then
		local data = getData:InvokeServer()
		if data and data.LoginStreak then
			streakLabel.Text = "Day " .. data.LoginStreak
			if data.LoginStreak >= 7 then
				streakLabel.Text = "Day " .. data.LoginStreak .. " \xf0\x9f\x94\xa5"
			elseif data.LoginStreak >= 3 then
				streakLabel.Text = "Day " .. data.LoginStreak .. " \xe2\x9c\xa8"
			end
		end
	end
end)

-- Hide new buttons when in arena
if joinArenaRemote then
	joinArenaRemote.OnClientEvent:Connect(function()
		rankBtn.Visible = false
		giftBtn.Visible = false
		streakDisplay.Visible = false
	end)
end

-- Show all HUD buttons when leaving arena
if leaveArenaRemote then
	leaveArenaRemote.OnClientEvent:Connect(function()
		rankBtn.Visible = true
		giftBtn.Visible = true
		streakDisplay.Visible = true
	end)
end