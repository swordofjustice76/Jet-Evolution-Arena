local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerManager = require(script.Parent.Parent.Managers.PlayerManager)
local Config = require(ReplicatedStorage.Shared.Config)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

-- ═══════════════════════════════════════════════════════════
-- PORTAL CONFIGURATION
-- ═══════════════════════════════════════════════════════════
-- Maps portal model names to arena types
local PORTAL_ARENA_MAP = {
	NormalPortal = "Normal",
	MEGAPortal = "MEGA",
	PVPPortal = "PvP",
	VIPPortal = "VIP",
}

-- Cooldown to prevent rapid re-entry (seconds)
local PORTAL_COOLDOWN = 3
local playerCooldowns = {}

-- ═══════════════════════════════════════════════════════════
-- PORTAL TOUCH HANDLER
-- ═══════════════════════════════════════════════════════════
local function onPortalTouch(otherPart, portalModel)
	local character = otherPart.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Check cooldown
	local now = tick()
	if playerCooldowns[player] and (now - playerCooldowns[player]) < PORTAL_COOLDOWN then
		return
	end

	-- Check if already in arena
	local data = PlayerManager.GetData(player)
	if not data then return end
	if data.InArena then return end

	-- Determine arena type from portal name
	local arenaType = PORTAL_ARENA_MAP[portalModel.Name]
	if not arenaType then return end

	-- VIP check for VIP portal
	if arenaType == "VIP" and not (data.IsVIP or data.PermanentVIP) then
		return -- Non-VIP players can't use VIP portal
	end

	-- Set cooldown
	playerCooldowns[player] = now

	-- Trigger arena join (same flow as the JoinArena remote)
	data.InArena = true
	data.ArenaType = arenaType

	-- Notify client to enable flight mode
	local joinArena = remotes and remotes:FindFirstChild("JoinArena")
	if joinArena then
		joinArena:FireClient(player, arenaType)
	end

	-- Spawn in arena
	local arenaManager = _G.ArenaManager
	if arenaManager and arenaManager.SpawnInArena then
		arenaManager.SpawnInArena(player)
	end

	PlayerManager.UpdateClient(player)
end

-- ═══════════════════════════════════════════════════════════
-- SETUP: Connect touch events to all portal surfaces
-- ═══════════════════════════════════════════════════════════
local function setupPortal(portalModel)
	local arenaType = PORTAL_ARENA_MAP[portalModel.Name]
	if not arenaType then return end

	-- Find the PortalSurface part (the walk-in trigger)
	local surface = portalModel:FindFirstChild("PortalSurface")
	if surface and surface:IsA("BasePart") then
		surface.Anchored = true
		surface.CanCollide = false
		surface.CanTouch = true
		surface.Touched:Connect(function(otherPart)
			onPortalTouch(otherPart, portalModel)
		end)
	end

	-- Also connect to the arch parts for a larger trigger zone
	for _, part in portalModel:GetDescendants() do
		if part:IsA("BasePart") and part ~= surface then
			part.Touched:Connect(function(otherPart)
				onPortalTouch(otherPart, portalModel)
			end)
		end
	end
end

-- Setup existing portals
local lobby = game.Workspace:FindFirstChild("Lobby")
if lobby then
	for name, _ in pairs(PORTAL_ARENA_MAP) do
		local portal = lobby:FindFirstChild(name)
		if portal then
			setupPortal(portal)
		end
	end
end

-- Handle portals added later
if lobby then
	lobby.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Model") and PORTAL_ARENA_MAP[descendant.Name] then
			task.wait(0.5) -- Wait for children to load
			setupPortal(descendant)
		end
	end)
end

-- Clean up cooldowns when players leave
Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player] = nil
end)

print("[PortalHandler] Initialized successfully")