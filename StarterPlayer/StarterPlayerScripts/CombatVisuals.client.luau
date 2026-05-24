local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Arena state tracking
local inArena = false
local joinArenaRemote = remotes:FindFirstChild("JoinArena")
if joinArenaRemote then
	joinArenaRemote.OnClientEvent:Connect(function()
		inArena = true
	end)
end
local leaveArenaRemote = remotes:FindFirstChild("LeaveArena")
if leaveArenaRemote then
	leaveArenaRemote.OnClientEvent:Connect(function()
		inArena = false
	end)
end

-- === SHOOTING (Mouse Click) ===
local mouse = player:GetMouse()
local isShooting = false
local fireRate = 0.3
local lastFireTime = 0

mouse.Button1Down:Connect(function()
	isShooting = true
end)

mouse.Button1Up:Connect(function()
	isShooting = false
end)

-- Fire loop
game:GetService("RunService").Heartbeat:Connect(function()
	if not isShooting then return end

	if not inArena then return end

	local now = os.clock()
	if now - lastFireTime < fireRate then return end
	lastFireTime = now

	-- Get aim direction from camera
	local camera = workspace.CurrentCamera
	local mousePos = mouse.Hit.Position
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local direction = (mousePos - hrp.Position).Unit

	-- Fire to server
	local fireWeapon = remotes:FindFirstChild("FireWeapon")
	if fireWeapon then
		fireWeapon:FireServer(direction)
	end
end)

-- === DAMAGE NUMBERS ===
local damageNumberGui = Instance.new("ScreenGui")
damageNumberGui.Name = "DamageNumbers"
damageNumberGui.ResetOnSpawn = false
damageNumberGui.Parent = player:WaitForChild("PlayerGui")

local function showDamageNumber(data)
	-- Server sends: {position, amount, isHeal}
	local amount = type(data) == "table" and data.amount or data
	local isHeal = type(data) == "table" and data.isHeal or false
	if type(amount) ~= "number" then return end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 100, 0, 40)
	label.Position = UDim2.new(0.5, math.random(-50, 50), 0.5, math.random(-30, 30))
	label.BackgroundTransparency = 1
	label.Text = (isHeal and "+" or "-") .. math.floor(amount)
	label.TextColor3 = isHeal and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = damageNumberGui

	local tween = TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = label.Position + UDim2.new(0, 0, 0, -80),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

local dmgNumRemote = remotes:WaitForChild("DamageNumber")
dmgNumRemote.OnClientEvent:Connect(showDamageNumber)

-- === KILL FEED ===
local killFeedGui = Instance.new("ScreenGui")
killFeedGui.Name = "KillFeed"
killFeedGui.ResetOnSpawn = false
killFeedGui.Parent = player:WaitForChild("PlayerGui")

local killFeedFrame = Instance.new("Frame")
killFeedFrame.Name = "Feed"
killFeedFrame.Size = UDim2.new(0, 300, 1, 0)
killFeedFrame.Position = UDim2.new(1, -310, 0, 10)
killFeedFrame.BackgroundTransparency = 1
killFeedFrame.Parent = killFeedGui

local killFeedLayout = Instance.new("UIListLayout")
killFeedLayout.SortOrder = Enum.SortOrder.LayoutOrder
killFeedLayout.Padding = UDim.new(0, 5)
killFeedLayout.VerticalAlignment = Enum.VerticalAlignment.Top
killFeedLayout.Parent = killFeedFrame

local function addKillFeedEntry(data)
	local entry = Instance.new("Frame")
	entry.Size = UDim2.new(1, 0, 0, 25)
	entry.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0
	entry.Parent = killFeedFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = entry

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -10, 1, 0)
	text.Position = UDim2.new(0, 5, 0, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Text = (data.killer or "?") .. " > " .. (data.victim or "?")
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Parent = entry

	-- Fade out after 5 seconds
	task.delay(5, function()
		local tween = TweenService:Create(entry, TweenInfo.new(1), {
			BackgroundTransparency = 1,
		})
		tween:Play()
		local textTween = TweenService:Create(text, TweenInfo.new(1), {
			TextTransparency = 1,
		})
		textTween:Play()
		textTween.Completed:Connect(function()
			entry:Destroy()
		end)
	end)
end

local killFeedRemote = remotes:WaitForChild("KillFeed")
killFeedRemote.OnClientEvent:Connect(addKillFeedEntry)