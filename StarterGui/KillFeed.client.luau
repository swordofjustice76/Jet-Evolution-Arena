local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Colors
local BG = Color3.fromRGB(15, 18, 30)
local PANEL = Color3.fromRGB(25, 30, 50)
local ACCENT = Color3.fromRGB(0, 150, 255)
local GOLD = Color3.fromRGB(255, 200, 0)
local GREEN = Color3.fromRGB(0, 255, 100)
local RED = Color3.fromRGB(255, 50, 50)
local WHITE = Color3.new(1, 1, 1)

-- === KILL FEED GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "KillFeed"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Feed container (top-right corner)
local feedContainer = Instance.new("Frame")
feedContainer.Name = "FeedContainer"
feedContainer.Size = UDim2.new(0, 350, 0, 300)
feedContainer.Position = UDim2.new(1, -360, 0, 10)
feedContainer.BackgroundTransparency = 1
feedContainer.Parent = gui

local feedLayout = Instance.new("UIListLayout")
feedLayout.Padding = UDim.new(0, 4)
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.VerticalAlignment = Enum.VerticalAlignment.Top
feedLayout.Parent = feedContainer

-- Track entries for cleanup
local feedEntries = {}
local MAX_ENTRIES = 8
local ENTRY_LIFETIME = 6

local function createFeedEntry(killer, victim, method)
	local entry = Instance.new("Frame")
	entry.Size = UDim2.new(1, 0, 0, 30)
	entry.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
	entry.BackgroundTransparency = 0.3
	entry.BorderSizePixel = 0
	entry.Parent = feedContainer

	local eCorner = Instance.new("UICorner")
	eCorner.CornerRadius = UDim.new(0, 6)
	eCorner.Parent = entry

	-- Killer name
	local killerLabel = Instance.new("TextLabel")
	killerLabel.Size = UDim2.new(0.4, 0, 1, 0)
	killerLabel.Position = UDim2.new(0, 8, 0, 0)
	killerLabel.BackgroundTransparency = 1
	killerLabel.TextColor3 = ACCENT
	killerLabel.TextScaled = true
	killerLabel.Font = Enum.Font.GothamBold
	killerLabel.Text = killer
	killerLabel.TextXAlignment = Enum.TextXAlignment.Right
	killerLabel.Parent = entry

	-- Method icon/text
	local methodLabel = Instance.new("TextLabel")
	methodLabel.Size = UDim2.new(0.2, 0, 1, 0)
	methodLabel.Position = UDim2.new(0.4, 0, 0, 0)
	methodLabel.BackgroundTransparency = 1
	methodLabel.TextColor3 = RED
	methodLabel.TextScaled = true
	methodLabel.Font = Enum.Font.GothamBold
	methodLabel.Text = method or "[X]"
	methodLabel.Parent = entry

	-- Victim name
	local victimLabel = Instance.new("TextLabel")
	victimLabel.Size = UDim2.new(0.4, 0, 1, 0)
	victimLabel.Position = UDim2.new(0.6, 0, 0, 0)
	victimLabel.BackgroundTransparency = 1
	victimLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	victimLabel.TextScaled = true
	victimLabel.Font = Enum.Font.GothamBold
	victimLabel.Text = victim
	victimLabel.TextXAlignment = Enum.TextXAlignment.Left
	victimLabel.Parent = entry

	-- Animate in
	entry.BackgroundTransparency = 1
	local tweenIn = TweenService:Create(entry, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.3,
	})
	tweenIn:Play()

	-- Schedule fade out and removal
	task.delay(ENTRY_LIFETIME, function()
		if not entry.Parent then return end
		local tweenOut = TweenService:Create(entry, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			entry.Parent = nil
			for i, e in ipairs(feedEntries) do
				if e == entry then
					table.remove(feedEntries, i)
					break
				end
			end
		end)
	end)

	table.insert(feedEntries, entry)

	-- Remove oldest if too many
	while #feedEntries > MAX_ENTRIES do
		local oldest = feedEntries[1]
		table.remove(feedEntries, 1)
		if oldest and oldest.Parent then
			oldest.Parent = nil
		end
	end
end

-- === LISTEN FOR KILL FEED EVENTS ===
local killFeed = remotes:WaitForChild("KillFeed")
killFeed.OnClientEvent:Connect(function(data)
	createFeedEntry(
		data.killer or "Unknown",
		data.victim or "Unknown",
		data.method or "[X]"
	)
end)