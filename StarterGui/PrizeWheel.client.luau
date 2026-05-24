local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopDefs = require(ReplicatedStorage.Shared.ShopDefs)
local Config = require(ReplicatedStorage.Shared.Config)

-- Colors
local BG = Color3.fromRGB(15, 18, 30)
local PANEL = Color3.fromRGB(25, 30, 50)
local ACCENT = Color3.fromRGB(0, 150, 255)
local GOLD = Color3.fromRGB(255, 200, 0)
local GREEN = Color3.fromRGB(0, 255, 100)
local RED = Color3.fromRGB(255, 50, 50)
local WHITE = Color3.new(1, 1, 1)
local GRAY = Color3.fromRGB(150, 150, 150)

local segments = ShopDefs.PrizeWheel
local segmentCount = #segments
local segmentAngle = 360 / segmentCount

-- === SOUND EFFECTS ===
local function createSound(id, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(id)
	sound.Volume = volume or 0.5
	sound.Parent = script
	return sound
end

local tickSound = createSound(6895079853, 0.3)       -- UI tick/click
local winSound = createSound(6895079853, 0.7)        -- Win fanfare (reusing, will pitch shift)
local spinStartSound = createSound(6895079853, 0.5)  -- Spin whoosh

-- === PRIZE WHEEL GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "PrizeWheel"
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
panel.Size = UDim2.new(0, 500, 0, 580)
panel.Position = UDim2.new(0.5, -250, 0.5, -290)
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
title.BackgroundColor3 = Color3.fromRGB(20, 15, 0)
title.BackgroundTransparency = 0.5
title.TextColor3 = GOLD
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "PRIZE WHEEL"
title.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = title

-- Wheel container
local wheelContainer = Instance.new("Frame")
wheelContainer.Size = UDim2.new(0, 350, 0, 350)
wheelContainer.Position = UDim2.new(0.5, -175, 0, 70)
wheelContainer.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
wheelContainer.BorderSizePixel = 0
wheelContainer.ClipsDescendants = true
wheelContainer.Parent = panel

local wheelCorner = Instance.new("UICorner")
wheelCorner.CornerRadius = UDim.new(1, 0)
wheelCorner.Parent = wheelContainer

local wheelStroke = Instance.new("UIStroke")
wheelStroke.Color = GOLD
wheelStroke.Thickness = 4
wheelStroke.Parent = wheelContainer

-- Rotating inner frame
local wheelInner = Instance.new("Frame")
wheelInner.Name = "WheelInner"
wheelInner.Size = UDim2.new(1, 0, 1, 0)
wheelInner.BackgroundTransparency = 1
wheelInner.Parent = wheelContainer

-- Create proper wheel segments using CanvasDraw-style wedges
local segmentColors = {
	Color3.fromRGB(200, 50, 50),
	Color3.fromRGB(50, 150, 200),
	Color3.fromRGB(200, 150, 50),
	Color3.fromRGB(50, 200, 100),
	Color3.fromRGB(150, 50, 200),
	Color3.fromRGB(200, 100, 50),
	Color3.fromRGB(50, 200, 200),
	Color3.fromRGB(200, 50, 150),
	Color3.fromRGB(100, 200, 50),
	Color3.fromRGB(50, 100, 200),
}

for i, seg in ipairs(segments) do
	local midAngle = math.rad((i - 0.5) * segmentAngle)
	local segColor = segmentColors[(i - 1) % #segmentColors + 1]

	-- Segment background wedge
	local wedge = Instance.new("Frame")
	wedge.Size = UDim2.new(0, 160, 0, 30)
	wedge.AnchorPoint = Vector2.new(0.5, 0.5)
	wedge.Position = UDim2.new(0.5 + math.cos(midAngle) * 0.3, 0, 0.5 + math.sin(midAngle) * 0.3, 0)
	wedge.BackgroundColor3 = segColor
	wedge.BackgroundTransparency = 0.15
	wedge.Rotation = (i - 0.5) * segmentAngle
	wedge.Parent = wheelInner

	local wCorner = Instance.new("UICorner")
	wCorner.CornerRadius = UDim.new(0, 4)
	wCorner.Parent = wedge

	-- Segment border for clean separation
	local wStroke = Instance.new("UIStroke")
	wStroke.Color = Color3.fromRGB(255, 255, 255)
	wStroke.Thickness = 1
	wStroke.Transparency = 0.7
	wStroke.Parent = wedge

	local segLabel = Instance.new("TextLabel")
	segLabel.Size = UDim2.new(1, -4, 1, 0)
	segLabel.BackgroundTransparency = 1
	segLabel.TextColor3 = WHITE
	segLabel.TextScaled = true
	segLabel.Font = Enum.Font.GothamBold
	segLabel.Text = seg.label
	segLabel.Parent = wedge
end

-- Center hub
local hub = Instance.new("Frame")
hub.Size = UDim2.new(0, 50, 0, 50)
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.Position = UDim2.new(0.5, 0, 0.5, 0)
hub.BackgroundColor3 = GOLD
hub.Parent = wheelContainer

local hubCorner = Instance.new("UICorner")
hubCorner.CornerRadius = UDim.new(1, 0)
hubCorner.Parent = hub

local hubLabel = Instance.new("TextLabel")
hubLabel.Size = UDim2.new(1, 0, 1, 0)
hubLabel.BackgroundTransparency = 1
hubLabel.TextColor3 = Color3.fromRGB(30, 20, 0)
hubLabel.TextScaled = true
hubLabel.Font = Enum.Font.GothamBold
hubLabel.Text = "SPIN"
hubLabel.Parent = hub

-- Pointer (triangle at top) - improved with a proper arrow shape
local pointerContainer = Instance.new("Frame")
pointerContainer.Size = UDim2.new(0, 40, 0, 40)
pointerContainer.Position = UDim2.new(0.5, -20, 0, 52)
pointerContainer.BackgroundTransparency = 1
pointerContainer.Parent = panel

local pointer = Instance.new("Frame")
pointer.Size = UDim2.new(0, 24, 0, 24)
pointer.Position = UDim2.new(0.5, -12, 0, 0)
pointer.BackgroundColor3 = RED
pointer.BorderSizePixel = 0
pointer.Rotation = 45
pointer.Parent = pointerContainer

local ptrCorner = Instance.new("UICorner")
ptrCorner.CornerRadius = UDim.new(0, 4)
ptrCorner.Parent = pointer

local ptrStroke = Instance.new("UIStroke")
ptrStroke.Color = WHITE
ptrStroke.Thickness = 2
ptrStroke.Parent = pointer

-- Glow effect on pointer
local pointerGlow = Instance.new("ImageLabel")
pointerGlow.Size = UDim2.new(0, 60, 0, 60)
pointerGlow.Position = UDim2.new(0.5, -30, 0, -10)
pointerGlow.BackgroundTransparency = 1
pointerGlow.Image = "rbxassetid://7669168585"
pointerGlow.ImageColor3 = RED
pointerGlow.ImageTransparency = 0.5
pointerGlow.Parent = pointerContainer

-- Spin button
local spinBtn = Instance.new("TextButton")
spinBtn.Name = "SpinBtn"
spinBtn.Size = UDim2.new(0.55, 0, 0, 50)
spinBtn.Position = UDim2.new(0.05, 0, 0, 460)
spinBtn.BackgroundColor3 = GOLD
spinBtn.TextColor3 = Color3.new(0, 0, 0)
spinBtn.TextScaled = true
spinBtn.Font = Enum.Font.GothamBold
spinBtn.Text = "SPIN (Free Today)"
spinBtn.AutoButtonColor = true
spinBtn.Parent = panel

local spinCorner = Instance.new("UICorner")
spinCorner.CornerRadius = UDim.new(0, 10)
spinCorner.Parent = spinBtn

local spinStroke = Instance.new("UIStroke")
spinStroke.Color = Color3.fromRGB(200, 150, 0)
spinStroke.Thickness = 2
spinStroke.Parent = spinBtn

-- Close button - larger and more visible
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.3, 0, 0, 50)
closeBtn.Position = UDim2.new(0.65, 0, 0, 460)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
closeBtn.TextColor3 = WHITE
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "CLOSE"
closeBtn.AutoButtonColor = true
closeBtn.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = Color3.fromRGB(200, 60, 60)
closeStroke.Thickness = 2
closeStroke.Parent = closeBtn

-- Result display with glow
local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "Result"
resultLabel.Size = UDim2.new(0.9, 0, 0, 50)
resultLabel.Position = UDim2.new(0.05, 0, 0, 520)
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

local resStroke = Instance.new("UIStroke")
resStroke.Color = GREEN
resStroke.Thickness = 2
resStroke.Transparency = 0.5
resStroke.Parent = resultLabel

-- Win celebration frame (glow effect)
local winGlow = Instance.new("ImageLabel")
winGlow.Size = UDim2.new(0, 450, 0, 450)
winGlow.Position = UDim2.new(0.5, -225, 0, 20)
winGlow.BackgroundTransparency = 1
winGlow.Image = "rbxassetid://7669168585"
winGlow.ImageColor3 = GOLD
winGlow.ImageTransparency = 1
winGlow.Parent = panel

-- === SPIN LOGIC ===
local isSpinning = false
local currentRotation = 0
local spinTimeout = 15 -- seconds before auto-reset

local function closeWheel()
	if isSpinning then return end
	gui.Enabled = false
	resultLabel.Visible = false
	winGlow.ImageTransparency = 1
end

local function playTickSound()
	tickSound:Play()
end

local function playWinSound()
	winSound.PlaybackSpeed = 1.5
	winSound:Play()
end

local function playSpinStartSound()
	spinStartSound.PlaybackSpeed = 0.8
	spinStartSound:Play()
end

local function showWinEffect()
	-- Glow pulse
	local glowTween = TweenService:Create(winGlow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		ImageTransparency = 0.3,
	})
	glowTween:Play()

	-- Panel border flash
	local flashInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local flash = TweenService:Create(panelStroke, flashInfo, {Color = GREEN})
	flash:Play()
	flash.Completed:Connect(function()
		task.wait(0.5)
		TweenService:Create(panelStroke, TweenInfo.new(0.5), {Color = GOLD}):Play()
	end)

	-- Pointer glow
	TweenService:Create(pointerGlow, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
	task.delay(2, function()
		TweenService:Create(pointerGlow, TweenInfo.new(1), {ImageTransparency = 0.5}):Play()
	end)
end

spinBtn.MouseButton1Click:Connect(function()
	if isSpinning then return end
	isSpinning = true
	spinBtn.Text = "SPINNING..."
	spinBtn.BackgroundColor3 = GRAY
	spinBtn.AutoButtonColor = false
	resultLabel.Visible = false
	winGlow.ImageTransparency = 1

	playSpinStartSound()

	-- Request spin from server
	local spinRemote = remotes:FindFirstChild("SpinWheel")
	if spinRemote then
		spinRemote:FireServer()
	end

	-- Timeout safety: if server doesn't respond, reset
	task.delay(spinTimeout, function()
		if isSpinning then
			isSpinning = false
			spinBtn.Text = "SPIN (Free Today)"
			spinBtn.BackgroundColor3 = GOLD
			spinBtn.AutoButtonColor = true
		end
	end)
end)

-- Listen for wheel result from server
local wheelResult = remotes:WaitForChild("WheelResult")
wheelResult.OnClientEvent:Connect(function(data)
	if not data or not data.segmentIndex then
		isSpinning = false
		spinBtn.Text = "SPIN (Free Today)"
		spinBtn.BackgroundColor3 = GOLD
		spinBtn.AutoButtonColor = true
		return
	end

	-- Calculate target rotation to land on the winning segment
	local targetSeg = data.segmentIndex
	local targetAngle = 360 - ((targetSeg - 0.5) * segmentAngle)
	-- Add multiple full rotations for dramatic effect
	local fullSpins = math.random(5, 8) * 360
	local targetRotation = currentRotation + fullSpins + targetAngle - (currentRotation % 360)

	-- Tick sound during spin
	local lastTickAngle = currentRotation
	local tickConn
	tickConn = wheelInner:GetPropertyChangedSignal("Rotation"):Connect(function()
		local current = wheelInner.Rotation
		-- Play tick every time we pass a segment boundary
		if math.floor(current / segmentAngle) ~= math.floor(lastTickAngle / segmentAngle) then
			playTickSound()
		end
		lastTickAngle = current
	end)

	-- Animate the wheel spin with easing
	local spinInfo = TweenInfo.new(5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local spinTween = TweenService:Create(wheelInner, spinInfo, {
		Rotation = targetRotation,
	})

	spinTween:Play()
	spinTween.Completed:Connect(function()
		if tickConn then tickConn:Disconnect() end
		currentRotation = targetRotation
		isSpinning = false
		spinBtn.AutoButtonColor = true

		-- Show result with effects
		local seg = segments[targetSeg]
		if seg then
			resultLabel.Text = "You won: " .. seg.label .. "!"
			resultLabel.Visible = true
			playWinSound()
			showWinEffect()
		end

		-- Update button text
		if data.freeSpinsLeft and data.freeSpinsLeft > 0 then
			spinBtn.Text = "SPIN (" .. data.freeSpinsLeft .. " Free)"
			spinBtn.BackgroundColor3 = GOLD
		else
			spinBtn.Text = "SPIN (R$" .. (Config.WHEEL_COST_ROBUX or 50) .. ")"
			spinBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		end
	end)
end)

-- Close button - reliable with multiple input types and debounce
local closeDebounce = false
local function closeWheel()
	if isSpinning or closeDebounce then return end
	closeDebounce = true
	gui.Enabled = false
	resultLabel.Visible = false
	winGlow.ImageTransparency = 1
	task.delay(0.5, function() closeDebounce = false end)
end

closeBtn.MouseButton1Click:Connect(closeWheel)
closeBtn.MouseButton2Click:Connect(closeWheel)

-- Overlay click to close
overlay.MouseButton1Click:Connect(closeWheel)

-- ESC key to close
local userInputService = game:GetService("UserInputService")
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		if gui.Enabled then
			closeWheel()
		end
	end
end)

-- === OPEN TRIGGER ===
gui:SetAttribute("CanOpen", true)

local function openWheel()
	-- Close all other menus first
	if _G.CloseAllMenus then _G.CloseAllMenus() end
	gui.Enabled = true
	resultLabel.Visible = false
	winGlow.ImageTransparency = 1

	-- Check free spins
	local getData = remotes:FindFirstChild("GetData")
	if getData then
		task.spawn(function()
			local data = getData:InvokeServer()
			if data then
				local today = os.date("!*t").yday
				local lastSpinDay = tonumber(data.LastSpinDate) or 0
				local freeSpins = (lastSpinDay ~= today) and Config.WHEEL_FREE_SPINS_DAILY or math.max(0, Config.WHEEL_FREE_SPINS_DAILY - (data.DailySpins or 0))
				if freeSpins > 0 then
					spinBtn.Text = "SPIN (" .. freeSpins .. " Free)"
					spinBtn.BackgroundColor3 = GOLD
				else
					spinBtn.Text = "SPIN (R$" .. (Config.WHEEL_COST_ROBUX or 50) .. ")"
					spinBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
				end
			end
		end)
	end
end

-- External open via attribute change
gui:GetAttributeChangedSignal("Open"):Connect(function()
	if gui:GetAttribute("Open") then
		openWheel()
	end
end)

-- Expose open function for other scripts
_G.OpenPrizeWheel = openWheel