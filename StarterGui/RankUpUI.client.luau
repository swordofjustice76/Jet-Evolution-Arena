local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RankDefs = require(ReplicatedStorage.Shared.RankDefs)

-- Colors
local GOLD = Color3.fromRGB(255, 200, 0)
local WHITE = Color3.new(1, 1, 1)

-- === RANK UP GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "RankUpUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

-- Full-screen overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Parent = gui

-- Center panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 500, 0, 250)
panel.Position = UDim2.new(0.5, -250, 0.5, -125)
panel.BackgroundColor3 = Color3.fromRGB(20, 15, 0)
panel.BackgroundTransparency = 1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 20)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = GOLD
panelStroke.Thickness = 4
panelStroke.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.BackgroundTransparency = 1
title.TextColor3 = GOLD
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "RANK UP!"
title.Parent = panel

-- New rank display
local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "NewRank"
rankLabel.Size = UDim2.new(1, 0, 0, 80)
rankLabel.Position = UDim2.new(0, 0, 0.25, 0)
rankLabel.BackgroundTransparency = 1
rankLabel.TextColor3 = WHITE
rankLabel.TextScaled = true
rankLabel.Font = Enum.Font.GothamBold
rankLabel.Text = ""
rankLabel.Parent = panel

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 40)
subtitle.Position = UDim2.new(0, 0, 0.6, 0)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.Text = ""
subtitle.Parent = panel

-- Continue button
local continueBtn = Instance.new("TextButton")
continueBtn.Size = UDim2.new(0.4, 0, 0, 45)
continueBtn.Position = UDim2.new(0.3, 0, 0.78, 0)
continueBtn.BackgroundColor3 = GOLD
continueBtn.TextColor3 = Color3.new(0, 0, 0)
continueBtn.TextScaled = true
continueBtn.Font = Enum.Font.GothamBold
continueBtn.Text = "CONTINUE"
continueBtn.Parent = panel

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = continueBtn

-- === ANIMATION ===
local function showRankUp(newRank)
	local display = RankDefs.GetDisplay(newRank)
	local tier = RankDefs.GetTier(newRank)
	local tierColor = RankDefs.TierColors[tier]
	local color = tierColor and Color3.new(tierColor.r, tierColor.g, tierColor.b) or GOLD

	rankLabel.Text = display
	rankLabel.TextColor3 = color
	subtitle.Text = "You've reached " .. tier .. " tier!"

	overlay.Visible = true
	panel.Visible = true

	-- Animate overlay
	overlay.BackgroundTransparency = 1
	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.5,
	})
	overlayTween:Play()

	-- Animate panel
	panel.BackgroundTransparency = 1
	panel.Size = UDim2.new(0, 100, 0, 50)
	panel.Position = UDim2.new(0.5, -50, 0.5, -25)

	local sizeTween = TweenService:Create(panel, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 500, 0, 250),
		Position = UDim2.new(0.5, -250, 0.5, -125),
		BackgroundTransparency = 0,
	})
	sizeTween:Play()

	-- Pulse the rank label
	task.spawn(function()
		for i = 1, 3 do
			task.wait(0.3)
			local pulse = TweenService:Create(rankLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextColor3 = WHITE,
			})
			pulse:Play()
			pulse.Completed:Wait()
			local unpulse = TweenService:Create(rankLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextColor3 = color,
			})
			unpulse:Play()
			unpulse.Completed:Wait()
		end
	end)
end

local function hideRankUp()
	local fadeTween = TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})
	fadeTween:Play()

	local overlayFade = TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 1,
	})
	overlayFade:Play()

	fadeTween.Completed:Connect(function()
		panel.Visible = false
		overlay.Visible = false
	end)
end

continueBtn.MouseButton1Click:Connect(hideRankUp)

-- === LISTEN FOR RANK UP EVENT ===
local rankUp = remotes:WaitForChild("RankUp")
rankUp.OnClientEvent:Connect(function(data)
	if data and data.newRank then
		showRankUp(data.newRank)
	end
end)