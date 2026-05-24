local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage.Shared.Config)

-- Colors
local RED = Color3.fromRGB(255, 50, 50)
local GOLD = Color3.fromRGB(255, 200, 0)
local ACCENT = Color3.fromRGB(0, 150, 255)
local WHITE = Color3.new(1, 1, 1)
local GRAY = Color3.fromRGB(150, 150, 150)

-- === ARENA HUD GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "ArenaHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

gui.Enabled = false

-- === FLIGHT INDICATORS (bottom center cluster) ===
local flightPanel = Instance.new("Frame")
flightPanel.Name = "FlightPanel"
flightPanel.Size = UDim2.new(0.32, 0, 0, 90)
flightPanel.Position = UDim2.new(0.34, 0, 0.87, 0)
flightPanel.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
flightPanel.BackgroundTransparency = 0.25
flightPanel.BorderSizePixel = 0
flightPanel.Parent = gui

local fpCorner = Instance.new("UICorner")
fpCorner.CornerRadius = UDim.new(0, 10)
fpCorner.Parent = flightPanel

-- Movement style label (top of panel)
local styleLabel = Instance.new("TextLabel")
styleLabel.Name = "MovementStyle"
styleLabel.Size = UDim2.new(1, 0, 0, 18)
styleLabel.Position = UDim2.new(0, 0, 0, 2)
styleLabel.BackgroundTransparency = 1
styleLabel.TextColor3 = GRAY
styleLabel.TextScaled = true
styleLabel.Font = Enum.Font.GothamBold
styleLabel.Text = "STANDARD"
styleLabel.ZIndex = 2
styleLabel.Parent = flightPanel

-- Throttle bar (horizontal, left = reverse, center = idle, right = forward)
local throttleFrame = Instance.new("Frame")
throttleFrame.Name = "ThrottleBar"
throttleFrame.Size = UDim2.new(0.9, 0, 0, 14)
throttleFrame.Position = UDim2.new(0.05, 0, 0, 22)
throttleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
throttleFrame.BorderSizePixel = 0
throttleFrame.Parent = flightPanel

local thrCorner = Instance.new("UICorner")
thrCorner.CornerRadius = UDim.new(0, 4)
thrCorner.Parent = throttleFrame

-- Center line
local thrCenter = Instance.new("Frame")
thrCenter.Size = UDim2.new(0, 2, 1, 0)
thrCenter.Position = UDim2.new(0.5, -1, 0, 0)
thrCenter.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
thrCenter.BorderSizePixel = 0
thrCenter.ZIndex = 3
thrCenter.Parent = throttleFrame

local thrFill = Instance.new("Frame")
thrFill.Name = "Fill"
thrFill.Size = UDim2.new(0.5, 0, 1, 0)
thrFill.Position = UDim2.new(0.5, 0, 0, 0)
thrFill.BackgroundColor3 = ACCENT
thrFill.BorderSizePixel = 0
thrFill.ZIndex = 2
thrFill.Parent = throttleFrame

local thrFillCorner = Instance.new("UICorner")
thrFillCorner.CornerRadius = UDim.new(0, 4)
thrFillCorner.Parent = thrFill

local thrLabel = Instance.new("TextLabel")
thrLabel.Size = UDim2.new(1, 0, 1, 0)
thrLabel.BackgroundTransparency = 1
thrLabel.TextColor3 = WHITE
thrLabel.TextScaled = true
thrLabel.Font = Enum.Font.GothamBold
thrLabel.Text = "W/S THRUST"
thrLabel.ZIndex = 4
thrLabel.Parent = throttleFrame

-- Strafe bar (horizontal, center = idle, left/right = strafe)
local strafeFrame = Instance.new("Frame")
strafeFrame.Name = "StrafeBar"
strafeFrame.Size = UDim2.new(0.9, 0, 0, 14)
strafeFrame.Position = UDim2.new(0.05, 0, 0, 40)
strafeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
strafeFrame.BorderSizePixel = 0
strafeFrame.Parent = flightPanel

local stfCorner = Instance.new("UICorner")
stfCorner.CornerRadius = UDim.new(0, 4)
stfCorner.Parent = strafeFrame

-- Center line
local stfCenter = Instance.new("Frame")
stfCenter.Size = UDim2.new(0, 2, 1, 0)
stfCenter.Position = UDim2.new(0.5, -1, 0, 0)
stfCenter.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
stfCenter.BorderSizePixel = 0
stfCenter.ZIndex = 3
stfCenter.Parent = strafeFrame

local stfFill = Instance.new("Frame")
stfFill.Name = "Fill"
stfFill.Size = UDim2.new(0.5, 0, 1, 0)
stfFill.Position = UDim2.new(0.5, 0, 0, 0)
stfFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
stfFill.BorderSizePixel = 0
stfFill.ZIndex = 2
stfFill.Parent = strafeFrame

local stfFillCorner = Instance.new("UICorner")
stfFillCorner.CornerRadius = UDim.new(0, 4)
stfFillCorner.Parent = stfFill

local stfLabel = Instance.new("TextLabel")
stfLabel.Size = UDim2.new(1, 0, 1, 0)
stfLabel.BackgroundTransparency = 1
stfLabel.TextColor3 = WHITE
stfLabel.TextScaled = true
stfLabel.Font = Enum.Font.GothamBold
stfLabel.Text = "A/D STRAFE"
stfLabel.ZIndex = 4
stfLabel.Parent = strafeFrame

-- === BOOST BAR (bottom of flight panel) ===
local boostFrame = Instance.new("Frame")
boostFrame.Name = "BoostBar"
boostFrame.Size = UDim2.new(0.9, 0, 0, 22)
boostFrame.Position = UDim2.new(0.05, 0, 0, 60)
boostFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
boostFrame.BorderSizePixel = 0
boostFrame.Parent = flightPanel

local boostCorner = Instance.new("UICorner")
boostCorner.CornerRadius = UDim.new(0, 6)
boostCorner.Parent = boostFrame

local boostFill = Instance.new("Frame")
boostFill.Name = "Fill"
boostFill.Size = UDim2.new(1, 0, 1, 0)
boostFill.BackgroundColor3 = ACCENT
boostFill.BorderSizePixel = 0
boostFill.Parent = boostFrame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = boostFill

local boostLabel = Instance.new("TextLabel")
boostLabel.Size = UDim2.new(1, 0, 1, 0)
boostLabel.BackgroundTransparency = 1
boostLabel.TextColor3 = WHITE
boostLabel.TextScaled = true
boostLabel.Font = Enum.Font.GothamBold
boostLabel.Text = "BOOST [SHIFT]: 100%"
boostLabel.ZIndex = 2
boostLabel.Parent = boostFrame

-- === BOUNDARY WARNING (flashing red overlay) ===
local boundaryWarning = Instance.new("Frame")
boundaryWarning.Name = "BoundaryWarning"
boundaryWarning.Size = UDim2.new(1, 0, 1, 0)
boundaryWarning.BackgroundColor3 = RED
boundaryWarning.BackgroundTransparency = 1
boundaryWarning.Visible = false
boundaryWarning.ZIndex = 10
boundaryWarning.Parent = gui

local boundaryLabel = Instance.new("TextLabel")
boundaryLabel.Size = UDim2.new(0.6, 0, 0, 60)
boundaryLabel.Position = UDim2.new(0.2, 0, 0.15, 0)
boundaryLabel.BackgroundTransparency = 1
boundaryLabel.TextColor3 = RED
boundaryLabel.TextScaled = true
boundaryLabel.Font = Enum.Font.GothamBold
boundaryLabel.Text = "BOUNDARY WARNING - RETURN TO ARENA"
boundaryLabel.ZIndex = 11
boundaryLabel.Parent = boundaryWarning

-- === PLAYER COUNT (top-left) ===
local playerCountFrame = Instance.new("Frame")
playerCountFrame.Size = UDim2.new(0, 180, 0, 35)
playerCountFrame.Position = UDim2.new(0, 10, 0, 10)
playerCountFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
playerCountFrame.BackgroundTransparency = 0.3
playerCountFrame.BorderSizePixel = 0
playerCountFrame.Parent = gui

local pcCorner = Instance.new("UICorner")
pcCorner.CornerRadius = UDim.new(0, 8)
pcCorner.Parent = playerCountFrame

local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Name = "Count"
playerCountLabel.Size = UDim2.new(1, 0, 1, 0)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.TextColor3 = WHITE
playerCountLabel.TextScaled = true
playerCountLabel.Font = Enum.Font.GothamBold
playerCountLabel.Text = "Players: 0"
playerCountLabel.Parent = playerCountFrame

-- === BOSS HEALTH BAR (top center, shown when boss is active) ===
local bossFrame = Instance.new("Frame")
bossFrame.Name = "BossHealth"
bossFrame.Size = UDim2.new(0.4, 0, 0, 30)
bossFrame.Position = UDim2.new(0.3, 0, 0.06, 0)
bossFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
bossFrame.BorderSizePixel = 0
bossFrame.Visible = false
bossFrame.Parent = gui

local bossCorner = Instance.new("UICorner")
bossCorner.CornerRadius = UDim.new(0, 8)
bossCorner.Parent = bossFrame

local bossFill = Instance.new("Frame")
bossFill.Name = "Fill"
bossFill.Size = UDim2.new(1, 0, 1, 0)
bossFill.BackgroundColor3 = RED
bossFill.BorderSizePixel = 0
bossFill.Parent = bossFrame

local bossFillCorner = Instance.new("UICorner")
bossFillCorner.CornerRadius = UDim.new(0, 8)
bossFillCorner.Parent = bossFill

local bossLabel = Instance.new("TextLabel")
bossLabel.Size = UDim2.new(1, 0, 1, 0)
bossLabel.BackgroundTransparency = 1
bossLabel.TextColor3 = WHITE
bossLabel.TextScaled = true
bossLabel.Font = Enum.Font.GothamBold
bossLabel.Text = "BOSS"
bossLabel.ZIndex = 2
bossLabel.Parent = bossFrame

-- === QUICK ACCESS BUTTONS (right side) ===
local quickAccessFrame = Instance.new("Frame")
quickAccessFrame.Size = UDim2.new(0, 50, 0, 200)
quickAccessFrame.Position = UDim2.new(1, -60, 0.4, 0)
quickAccessFrame.BackgroundTransparency = 1
quickAccessFrame.Parent = gui

local qaLayout = Instance.new("UIListLayout")
qaLayout.Padding = UDim.new(0, 8)
qaLayout.SortOrder = Enum.SortOrder.LayoutOrder
qaLayout.Parent = quickAccessFrame

-- Wheel button
local wheelBtn = Instance.new("TextButton")
wheelBtn.Size = UDim2.new(0, 50, 0, 50)
wheelBtn.BackgroundColor3 = GOLD
wheelBtn.TextColor3 = Color3.new(0, 0, 0)
wheelBtn.TextScaled = true
wheelBtn.Font = Enum.Font.GothamBold
wheelBtn.Text = "W"
wheelBtn.LayoutOrder = 1
wheelBtn.Parent = quickAccessFrame

local wBtnCorner = Instance.new("UICorner")
wBtnCorner.CornerRadius = UDim.new(0, 10)
wBtnCorner.Parent = wheelBtn

-- Chest button
local chestBtn = Instance.new("TextButton")
chestBtn.Size = UDim2.new(0, 50, 0, 50)
chestBtn.BackgroundColor3 = ACCENT
chestBtn.TextColor3 = WHITE
chestBtn.TextScaled = true
chestBtn.Font = Enum.Font.GothamBold
chestBtn.Text = "C"
chestBtn.LayoutOrder = 2
chestBtn.Parent = quickAccessFrame

local cBtnCorner = Instance.new("UICorner")
cBtnCorner.CornerRadius = UDim.new(0, 10)
cBtnCorner.Parent = chestBtn

-- Menu button
local menuBtn = Instance.new("TextButton")
menuBtn.Size = UDim2.new(0, 50, 0, 50)
menuBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
menuBtn.TextColor3 = WHITE
menuBtn.TextScaled = true
menuBtn.Font = Enum.Font.GothamBold
menuBtn.Text = "M"
menuBtn.LayoutOrder = 3
menuBtn.Parent = quickAccessFrame

local mBtnCorner = Instance.new("UICorner")
mBtnCorner.CornerRadius = UDim.new(0, 10)
mBtnCorner.Parent = menuBtn

-- Leave Arena button (top-right)
local leaveBtn = Instance.new("TextButton")
leaveBtn.Name = "LeaveArenaBtn"
leaveBtn.Size = UDim2.new(0, 120, 0, 35)
leaveBtn.Position = UDim2.new(1, -135, 0, 10)
leaveBtn.BackgroundColor3 = RED
leaveBtn.TextColor3 = WHITE
leaveBtn.TextScaled = true
leaveBtn.Font = Enum.Font.GothamBold
leaveBtn.Text = "LEAVE ARENA"
leaveBtn.Visible = false
leaveBtn.Parent = gui

local leaveBtnCorner = Instance.new("UICorner")
leaveBtnCorner.CornerRadius = UDim.new(0, 8)
leaveBtnCorner.Parent = leaveBtn

leaveBtn.MouseButton1Click:Connect(function()
	local leaveRemote = remotes:FindFirstChild("LeaveArena")
	if leaveRemote then
		leaveRemote:FireServer()
	end
end)

-- === EVENT HANDLERS ===

-- Boost update
local boostUpdate = remotes:WaitForChild("BoostUpdate")
boostUpdate.OnClientEvent:Connect(function(boosts)
	-- Update boost bar based on energy (client-side tracking)
end)

-- Boundary warning
local arenaBoundary = remotes:WaitForChild("ArenaBoundary")
arenaBoundary.OnClientEvent:Connect(function(data)
	if data and data.nearBoundary then
		boundaryWarning.Visible = true
		-- Flash effect
		task.spawn(function()
			while boundaryWarning.Visible do
				local flash = TweenService:Create(boundaryWarning, TweenInfo.new(0.3), {
					BackgroundTransparency = 0.7,
				})
				flash:Play()
				flash.Completed:Wait()
				local unflash = TweenService:Create(boundaryWarning, TweenInfo.new(0.3), {
					BackgroundTransparency = 1,
				})
				unflash:Play()
				unflash.Completed:Wait()
			end
		end)
	else
		boundaryWarning.Visible = false
	end
end)

-- Player count
local playerCountUpdate = remotes:WaitForChild("PlayerCountUpdate")
playerCountUpdate.OnClientEvent:Connect(function(data)
	if data and data.count then
		playerCountLabel.Text = "Players: " .. data.count
	end
end)

-- Boss health
local bossHealthUpdate = remotes:WaitForChild("BossHealthUpdate")
bossHealthUpdate.OnClientEvent:Connect(function(data)
	if data and data.active then
		bossFrame.Visible = true
		bossLabel.Text = data.name or "BOSS"
		local healthPercent = math.clamp(data.healthPercent or 0, 0, 1)
		bossFill.Size = UDim2.new(healthPercent, 0, 1, 0)
	elseif data and not data.active then
		bossFrame.Visible = false
	end
end)

-- Quick access buttons
wheelBtn.MouseButton1Click:Connect(function()
	local prizeWheelGui = player.PlayerGui:FindFirstChild("PrizeWheel")
	if prizeWheelGui then
		prizeWheelGui:SetAttribute("Open", true)
		prizeWheelGui.Enabled = true
	end
end)

chestBtn.MouseButton1Click:Connect(function()
	local chestGui = player.PlayerGui:FindFirstChild("ChestOpener")
	if chestGui then
		chestGui:SetAttribute("Open", true)
		chestGui:SetAttribute("ChestType", "Common")
		chestGui.Enabled = true
	end
end)

menuBtn.MouseButton1Click:Connect(function()
	local mainMenuGui = player.PlayerGui:FindFirstChild("MainMenu")
	if mainMenuGui then
		mainMenuGui.Enabled = not mainMenuGui.Enabled
	end
end)

-- Show/hide leave button based on arena state
local joinArenaForHUD = remotes:FindFirstChild("JoinArena")
if joinArenaForHUD then
	joinArenaForHUD.OnClientEvent:Connect(function()
		leaveBtn.Visible = true
	end)
end

local leaveArenaForHUD = remotes:FindFirstChild("LeaveArena")
if leaveArenaForHUD then
	leaveArenaForHUD.OnClientEvent:Connect(function()
		leaveBtn.Visible = false
	end)
end

-- Show/hide based on arena state
local joinArenaForVis = remotes:FindFirstChild("JoinArena")
if joinArenaForVis then
	joinArenaForVis.OnClientEvent:Connect(function()
		gui.Enabled = true
	end)
end

local leaveArenaForVis = remotes:FindFirstChild("LeaveArena")
if leaveArenaForVis then
	leaveArenaForVis.OnClientEvent:Connect(function()
		gui.Enabled = false
	end)
end

-- === LOCAL FLIGHT PANEL UPDATE ===
-- Reads character attributes published by FlightController each frame
local lastBoostEnergy = 100
local lastThrottle = 0
local lastStrafe = 0
local lastStyle = "Standard"

task.spawn(function()
	-- Wait for character to exist
	for i = 1, 30 do
		if player.Character then break end
		task.wait(1)
	end

	local runService = game:GetService("RunService")
	runService.Heartbeat:Connect(function()
		local char = player.Character
		if not char then return end

		-- Read attributes from FlightController
		local energy = char:GetAttribute("BoostEnergy")
		if energy then lastBoostEnergy = energy end

		local thr = char:GetAttribute("Throttle")
		if thr then lastThrottle = thr end

		local stf = char:GetAttribute("StrafeInput")
		if stf then lastStrafe = stf end

		local sty = char:GetAttribute("MovementStyle")
		if sty then lastStyle = sty end

		-- ── Boost bar ──
		local percent = math.clamp(lastBoostEnergy / Config.MAX_BOOST_ENERGY, 0, 1)
		boostFill.Size = UDim2.new(percent, 0, 1, 0)
		boostLabel.Text = "BOOST [SHIFT]: " .. math.floor(percent * 100) .. "%"

		if percent > 0.5 then
			boostFill.BackgroundColor3 = ACCENT
		elseif percent > 0.25 then
			boostFill.BackgroundColor3 = GOLD
		else
			boostFill.BackgroundColor3 = RED
		end

		-- ── Throttle bar ──
		-- Positive throttle = fill right from center, negative = fill left from center
		if lastThrottle >= 0 then
			thrFill.Position = UDim2.new(0.5, 0, 0, 0)
			thrFill.Size = UDim2.new(lastThrottle * 0.5, 0, 1, 0)
			thrFill.BackgroundColor3 = ACCENT
		else
			local w = math.abs(lastThrottle) * 0.5
			thrFill.Position = UDim2.new(0.5 - w, 0, 0, 0)
			thrFill.Size = UDim2.new(w, 0, 1, 0)
			thrFill.BackgroundColor3 = Color3.fromRGB(255, 140, 0)  -- orange for reverse
		end

		-- ── Strafe bar ──
		if lastStrafe >= 0 then
			stfFill.Position = UDim2.new(0.5, 0, 0, 0)
			stfFill.Size = UDim2.new(lastStrafe * 0.5, 0, 1, 0)
		else
			local w = math.abs(lastStrafe) * 0.5
			stfFill.Position = UDim2.new(0.5 - w, 0, 0, 0)
			stfFill.Size = UDim2.new(w, 0, 1, 0)
		end

		-- Dim strafe bar when full strafe is locked
		local fullStrafe = (lastStyle == "Strafe" or lastStyle == "Hydra")
		stfFill.BackgroundTransparency = fullStrafe and 0 or 0.5
		strafeFrame.BackgroundTransparency = fullStrafe and 0 or 0.3

		-- ── Movement style label ──
		local styleText = string.upper(lastStyle)
		if lastStyle == "Standard" then
			styleLabel.TextColor3 = GRAY
			styleLabel.Text = styleText .. " — STRAFE LOCKED"
		elseif lastStyle == "Strafe" then
			styleLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
			styleLabel.Text = styleText .. " — FULL STRAFE"
		elseif lastStyle == "Reverse" then
			styleLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
			styleLabel.Text = styleText .. " — REVERSE THRUST"
		elseif lastStyle == "Hydra" then
			styleLabel.TextColor3 = Color3.fromRGB(200, 50, 255)
			styleLabel.Text = styleText .. " — OMNI"
		else
			styleLabel.TextColor3 = GRAY
			styleLabel.Text = styleText
		end
	end)
end)