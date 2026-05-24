local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.Config)
local RankDefs = require(ReplicatedStorage.Shared.RankDefs)
local EvolutionTree = require(ReplicatedStorage.Shared.EvolutionTree)

-- === HUD ScreenGui ===
local hud = Instance.new("ScreenGui")
hud.Name = "GameHUD"
hud.ResetOnSpawn = false
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hud.Parent = player:WaitForChild("PlayerGui")

-- Track arena state for HUD visibility
local isInArena = false

-- Arena-only elements: health, boost, ability
local arenaOnlyElements = {}

-- === HEALTH BAR (bottom center) ===
local healthFrame = Instance.new("Frame")
healthFrame.Name = "HealthBar"
healthFrame.Size = UDim2.new(0, 300, 0, 25)
healthFrame.Position = UDim2.new(0.5, -150, 0.95, -30)
healthFrame.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
healthFrame.BorderSizePixel = 0
healthFrame.Parent = hud

table.insert(arenaOnlyElements, healthFrame)

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 5)
healthCorner.Parent = healthFrame

local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthFrame

local healthFillCorner = Instance.new("UICorner")
healthFillCorner.CornerRadius = UDim.new(0, 5)
healthFillCorner.Parent = healthFill

local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.TextScaled = true
healthText.Font = Enum.Font.GothamBold
healthText.Text = "100%"
healthText.Parent = healthFrame

-- === BOOST/ENERGY BAR (below health) ===
local boostFrame = Instance.new("Frame")
boostFrame.Name = "BoostBar"
boostFrame.Size = UDim2.new(0, 300, 0, 15)
boostFrame.Position = UDim2.new(0.5, -150, 0.97, -15)
boostFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 30)
boostFrame.BorderSizePixel = 0
boostFrame.Parent = hud

table.insert(arenaOnlyElements, boostFrame)

local boostCorner = Instance.new("UICorner")
boostCorner.CornerRadius = UDim.new(0, 3)
boostCorner.Parent = boostFrame

local boostFill = Instance.new("Frame")
boostFill.Name = "Fill"
boostFill.Size = UDim2.new(1, 0, 1, 0)
boostFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
boostFill.BorderSizePixel = 0
boostFill.Parent = boostFrame

local boostFillCorner = Instance.new("UICorner")
boostFillCorner.CornerRadius = UDim.new(0, 3)
boostFillCorner.Parent = boostFill

local boostText = Instance.new("TextLabel")
boostText.Size = UDim2.new(1, 0, 1, 0)
boostText.BackgroundTransparency = 1
boostText.TextColor3 = Color3.new(1, 1, 1)
boostText.TextScaled = true
boostText.Font = Enum.Font.GothamBold
boostText.Text = "BOOST"
boostText.Parent = boostFrame

-- === LEVEL/XP BAR (top center) ===
local xpFrame = Instance.new("Frame")
xpFrame.Name = "XPBar"
xpFrame.Size = UDim2.new(0, 400, 0, 20)
xpFrame.Position = UDim2.new(0.5, -200, 0, 10)
xpFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
xpFrame.BorderSizePixel = 0
xpFrame.Parent = hud

local xpCorner = Instance.new("UICorner")
xpCorner.CornerRadius = UDim.new(0, 5)
xpCorner.Parent = xpFrame

local xpFill = Instance.new("Frame")
xpFill.Name = "Fill"
xpFill.Size = UDim2.new(0.5, 0, 1, 0)
xpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
xpFill.BorderSizePixel = 0
xpFill.Parent = xpFrame

local xpFillCorner = Instance.new("UICorner")
xpFillCorner.CornerRadius = UDim.new(0, 5)
xpFillCorner.Parent = xpFill

local xpText = Instance.new("TextLabel")
xpText.Size = UDim2.new(1, 0, 1, 0)
xpText.BackgroundTransparency = 1
xpText.TextColor3 = Color3.new(1, 1, 1)
xpText.TextScaled = true
xpText.Font = Enum.Font.GothamBold
xpText.Text = "Lv1 - 0/50 XP"
xpText.Parent = xpFrame

-- === EVOLUTION/RANK DISPLAY (top left) ===
local infoFrame = Instance.new("Frame")
infoFrame.Name = "PlayerInfo"
infoFrame.Size = UDim2.new(0, 200, 0, 60)
infoFrame.Position = UDim2.new(0, 10, 0, 40)
infoFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
infoFrame.BackgroundTransparency = 0.3
infoFrame.BorderSizePixel = 0
infoFrame.Parent = hud

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 8)
infoCorner.Parent = infoFrame

local evoLabel = Instance.new("TextLabel")
evoLabel.Name = "Evolution"
evoLabel.Size = UDim2.new(1, -10, 0.5, 0)
evoLabel.Position = UDim2.new(0, 5, 0, 0)
evoLabel.BackgroundTransparency = 1
evoLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
evoLabel.TextScaled = true
evoLabel.Font = Enum.Font.GothamBold
evoLabel.Text = "Starter"
evoLabel.TextXAlignment = Enum.TextXAlignment.Left
evoLabel.Parent = infoFrame

local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "Rank"
rankLabel.Size = UDim2.new(1, -10, 0.5, 0)
rankLabel.Position = UDim2.new(0, 5, 0.5, 0)
rankLabel.BackgroundTransparency = 1
rankLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
rankLabel.TextScaled = true
rankLabel.Font = Enum.Font.GothamBold
rankLabel.Text = "Iron 1"
rankLabel.TextXAlignment = Enum.TextXAlignment.Left
rankLabel.Parent = infoFrame

-- === ABILITY INDICATOR (bottom right) ===
local abilityFrame = Instance.new("Frame")
abilityFrame.Name = "AbilitySlot"
abilityFrame.Size = UDim2.new(0, 70, 0, 70)
abilityFrame.Position = UDim2.new(1, -80, 0.85, -80)
abilityFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
abilityFrame.BackgroundTransparency = 0.3
abilityFrame.BorderSizePixel = 0
abilityFrame.Parent = hud

table.insert(arenaOnlyElements, abilityFrame)

local abilityCorner = Instance.new("UICorner")
abilityCorner.CornerRadius = UDim.new(0, 10)
abilityCorner.Parent = abilityFrame

local abilityStroke = Instance.new("UIStroke")
abilityStroke.Color = Color3.fromRGB(0, 150, 255)
abilityStroke.Thickness = 2
abilityStroke.Parent = abilityFrame

local abilityIcon = Instance.new("TextLabel")
abilityIcon.Size = UDim2.new(1, -10, 0.6, 0)
abilityIcon.Position = UDim2.new(0, 5, 0, 5)
abilityIcon.BackgroundTransparency = 1
abilityIcon.TextColor3 = Color3.new(1, 1, 1)
abilityIcon.TextScaled = true
abilityIcon.Font = Enum.Font.GothamBold
abilityIcon.Text = "Q"
abilityIcon.Parent = abilityFrame

local abilityCharges = Instance.new("TextLabel")
abilityCharges.Name = "Charges"
abilityCharges.Size = UDim2.new(1, -10, 0.3, 0)
abilityCharges.Position = UDim2.new(0, 5, 0.65, 0)
abilityCharges.BackgroundTransparency = 1
abilityCharges.TextColor3 = Color3.fromRGB(0, 200, 255)
abilityCharges.TextScaled = true
abilityCharges.Font = Enum.Font.GothamBold
abilityCharges.Text = "0"
abilityCharges.Parent = abilityFrame

-- === MEDALS DISPLAY (top right) ===
local medalFrame = Instance.new("Frame")
medalFrame.Name = "Medals"
medalFrame.Size = UDim2.new(0, 150, 0, 30)
medalFrame.Position = UDim2.new(1, -160, 0, 10)
medalFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
medalFrame.BackgroundTransparency = 0.3
medalFrame.BorderSizePixel = 0
medalFrame.Parent = hud

local medalCorner = Instance.new("UICorner")
medalCorner.CornerRadius = UDim.new(0, 5)
medalCorner.Parent = medalFrame

local medalText = Instance.new("TextLabel")
medalText.Size = UDim2.new(1, 0, 1, 0)
medalText.BackgroundTransparency = 1
medalText.TextColor3 = Color3.fromRGB(255, 200, 0)
medalText.TextScaled = true
medalText.Font = Enum.Font.GothamBold
medalText.Text = "0 Medals"
medalText.Parent = medalFrame

-- === STAT POINTS NOTIFICATION ===
local statPointFrame = Instance.new("Frame")
statPointFrame.Name = "StatPoints"
statPointFrame.Size = UDim2.new(0, 200, 0, 30)
statPointFrame.Position = UDim2.new(0.5, -100, 0.06, 0)
statPointFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
statPointFrame.BackgroundTransparency = 0.3
statPointFrame.BorderSizePixel = 0
statPointFrame.Visible = false
statPointFrame.Parent = hud

local spCorner = Instance.new("UICorner")
spCorner.CornerRadius = UDim.new(0, 5)
spCorner.Parent = statPointFrame

local spText = Instance.new("TextLabel")
spText.Size = UDim2.new(1, 0, 1, 0)
spText.BackgroundTransparency = 1
spText.TextColor3 = Color3.new(1, 1, 1)
spText.TextScaled = true
spText.Font = Enum.Font.GothamBold
spText.Text = "0 Stat Points Available"
spText.Parent = statPointFrame

-- === UPDATE LOOP ===
game:GetService("RunService").Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local healthRatio = humanoid.Health / humanoid.MaxHealth
		healthFill.Size = UDim2.new(healthRatio, 0, 1, 0)
		healthText.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
	end

	-- Boost energy (from FlightController attribute)
	local boostAttr = character:GetAttribute("BoostEnergy")
	if boostAttr then
		local ratio = boostAttr / Config.MAX_BOOST_ENERGY
		boostFill.Size = UDim2.new(ratio, 0, 1, 0)
	end
end)

-- === DATA SYNC FROM SERVER ===
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local updateClient = remotes:WaitForChild("UpdateClient")
	updateClient.OnClientEvent:Connect(function(data)
		if data.Level then
			local required = Config.XP_CURVE(data.Level)
			xpText.Text = "Lv" .. data.Level .. " - " .. data.XP .. "/" .. required .. " XP"
			local ratio = data.XP / required
			xpFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
		end

		if data.CurrentEvolution then
			evoLabel.Text = data.CurrentEvolution
		end

		if data.Rank then
			rankLabel.Text = RankDefs.GetDisplay(data.Rank)
			local tier = RankDefs.GetTier(data.Rank)
			local colors = RankDefs.TierColors[tier]
			if colors then
				rankLabel.TextColor3 = Color3.new(colors.r, colors.g, colors.b)
			end
		end

		if data.Medals then
			medalText.Text = data.Medals .. " Medals"
		end

		if data.StatPoints and data.StatPoints > 0 then
			statPointFrame.Visible = true
			spText.Text = data.StatPoints .. " Stat Points Available!"
		else
			statPointFrame.Visible = false
		end

		if data.EquippedAbility and data.EquippedAbility ~= "" then
			local AbilityDefs = require(ReplicatedStorage.Shared.AbilityDefs)
			local def = AbilityDefs.GetByID(data.EquippedAbility)
			if def then
				abilityIcon.Text = def.name:sub(1, 3)
				local charges = data.AbilityCharges and data.AbilityCharges[data.EquippedAbility] or 0
				abilityCharges.Text = tostring(charges)
			end
		end
	end)

	-- Request initial data
	local getData = remotes:FindFirstChild("GetData")
	if getData then
		task.spawn(function()
			local data = getData:InvokeServer()
			if data then
				updateClient:Fire(data)
			end
		end)
	end

	-- Arena state listeners for HUD visibility
	local joinArenaRemote = remotes:FindFirstChild("JoinArena")
	if joinArenaRemote then
		joinArenaRemote.OnClientEvent:Connect(function()
			isInArena = true
			for _, elem in ipairs(arenaOnlyElements) do
				elem.Visible = true
			end
		end)
	end

	local leaveArenaRemote = remotes:FindFirstChild("LeaveArena")
	if leaveArenaRemote then
		leaveArenaRemote.OnClientEvent:Connect(function()
			isInArena = false
			for _, elem in ipairs(arenaOnlyElements) do
				elem.Visible = false
			end
		end)
	end
end

-- Initially hide arena-only elements (player starts in lobby)
for _, elem in ipairs(arenaOnlyElements) do
	elem.Visible = false
end