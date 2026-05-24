local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerManager = require(script.Parent.Parent.Managers.PlayerManager)
local Config = require(ReplicatedStorage.Shared.Config)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local jetTemplate = ReplicatedStorage:FindFirstChild("JetTemplate")

local function fireRemote(name, player, ...)
	local remote = remotes and remotes:FindFirstChild(name)
	if remote then
		remote:FireClient(player, ...)
	end
end

-- ═══════════════════════════════════════════════════════════
-- JET MODEL ATTACHMENT
-- ═══════════════════════════════════════════════════════════
local function attachJetModel(character)
	if not jetTemplate then return end
	if character:FindFirstChild("JetModel") then return end -- already attached

	local jet = jetTemplate:Clone()
	jet.Name = "JetModel"

	-- Configure all parts for character attachment
	for _, part in jet:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
			part.CastShadow = true
		end
	end

	-- Parent to character first so CFrame operations work
	jet.Parent = character

	-- Position the jet relative to HumanoidRootPart
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and jet.PrimaryPart then
		-- Offset the jet so the HRP is at the cockpit area
		jet:PivotTo(hrp.CFrame * CFrame.new(0, 0, 2))

		-- Weld the jet's primary part to the HRP
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = jet.PrimaryPart
		weld.Parent = hrp
	end
end

local function removeJetModel(character)
	local jet = character:FindFirstChild("JetModel")
	if jet then
		-- Remove any welds connecting jet to HRP
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			for _, child in hrp:GetChildren() do
				if child:IsA("WeldConstraint") and child.Part1 and child.Part1:IsDescendantOf(jet) then
					child:Destroy()
				end
			end
		end
		jet:Destroy()
	end
end

-- ═══════════════════════════════════════════════════════════
-- ARENA SPAWNING
-- ═══════════════════════════════════════════════════════════
local function spawnInArena(player)
	local data = PlayerManager.GetData(player)
	if not data then return end

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local arenaType = data.ArenaType or "PvP"

	-- Spawn at a random position within the inner arena at flight altitude
	local angle = math.random() * math.pi * 2
	local radius = math.random() * (Config.ARENA_RADIUS * 0.3) -- spawn in inner 30%
	local spawnPos = Vector3.new(
		math.cos(angle) * radius,
		Config.FLIGHT_ALTITUDE,
		math.sin(angle) * radius
	)
	hrp.CFrame = CFrame.new(spawnPos)

	-- Kill default humanoid movement (flight controller takes over)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Attach jet model to character
	attachJetModel(character)

	-- Zero out any residual velocity
	hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

	fireRemote("PlayerCountUpdate", player, {
		count = #Players:GetPlayers(),
		arenaType = arenaType,
	})
end

local function respawnInArena(player)
	local data = PlayerManager.GetData(player)
	if not data then return end
	if not data.InArena then return end

	task.delay(1, function()
		local character = player.Character
		if not character then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local angle = math.random() * math.pi * 2
		local radius = math.random() * (Config.ARENA_RADIUS * 0.3)
		local spawnPos = Vector3.new(
			math.cos(angle) * radius,
			Config.FLIGHT_ALTITUDE,
			math.sin(angle) * radius
		)
		hrp.CFrame = CFrame.new(spawnPos)

		-- Re-attach jet model on respawn
		attachJetModel(character)

		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end)
end

-- ═══════════════════════════════════════════════════════════
-- BOSS SPAWNING
-- ═══════════════════════════════════════════════════════════
local bossSpawn = remotes and remotes:FindFirstChild("BossSpawn")
if bossSpawn then
	bossSpawn.OnServerEvent:Connect(function(player)
		local data = PlayerManager.GetData(player)
		if not data then return end
		if not data.InArena then return end

		fireRemote("BossSpawn", player, {spawned = true})
	end)
end

-- ═══════════════════════════════════════════════════════════
-- BOSS DAMAGE
-- ═══════════════════════════════════════════════════════════
local bossDamage = remotes and remotes:FindFirstChild("BossDamage")
if bossDamage then
	bossDamage.OnServerEvent:Connect(function(player, damage)
		local data = PlayerManager.GetData(player)
		if not data then return end
		if not data.InArena then return end

		damage = tonumber(damage) or 0
		if damage <= 0 then return end

		local xpReward = math.floor(damage * 0.5)
		local medalReward = math.floor(damage * 0.1)
		PlayerManager.AddXP(player, xpReward)
		PlayerManager.AddMedals(player, medalReward)

		fireRemote("BossDamage", player, {damage = damage})
	end)
end

-- ═══════════════════════════════════════════════════════════
-- PLAYER COUNT UPDATES
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(5)
		local count = #Players:GetPlayers()
		for _, player in Players:GetPlayers() do
			local data = PlayerManager.GetData(player)
			if data and data.InArena then
				fireRemote("PlayerCountUpdate", player, {
					count = count,
					arenaType = data.ArenaType or "PvP",
				})
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- CLEANUP: Remove jet model when leaving arena
-- ═══════════════════════════════════════════════════════════
local leaveArena = remotes and remotes:FindFirstChild("LeaveArena")
if leaveArena then
	leaveArena.OnServerEvent:Connect(function(player)
		local character = player.Character
		if character then
			removeJetModel(character)
		end
	end)
end

local returnToLobby = remotes and remotes:FindFirstChild("ReturnToLobby")
if returnToLobby then
	returnToLobby.OnServerEvent:Connect(function(player)
		local character = player.Character
		if character then
			removeJetModel(character)
		end
	end)
end

-- Also clean up jet on character removal
Players.PlayerRemoving:Connect(function(player)
	local character = player.Character
	if character then
		removeJetModel(character)
	end
end)

-- Export via _G
_G.ArenaManager = {
	SpawnInArena = spawnInArena,
	RespawnInArena = respawnInArena,
	AttachJetModel = attachJetModel,
	RemoveJetModel = removeJetModel,
}

print("[ArenaManager] Initialized successfully")