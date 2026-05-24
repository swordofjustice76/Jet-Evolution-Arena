local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerManager = require(script.Parent.Parent.Managers.PlayerManager)
local Config = require(ReplicatedStorage.Shared.Config)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local function fireRemote(name, player, ...)
	local remote = remotes and remotes:FindFirstChild(name)
	if remote then
		remote:FireClient(player, ...)
	end
end

-- === LOBBY SETUP ===
local function getSpawnCFrame()
	local lobby = workspace:FindFirstChild("Lobby")
	local spawnLoc = lobby and lobby:FindFirstChild("SpawnLocation")
	if spawnLoc and spawnLoc:IsA("SpawnLocation") then
		return spawnLoc.CFrame + Vector3.new(0, 3, 0)
	end
	return CFrame.new(0, 135, -120) -- fallback near lobby floor
end

local function setupLobbyCharacter(player)
	local data = PlayerManager.GetData(player)
	if not data then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.WalkSpeed = Config.LOBBY_TAXI_SPEED or 80
	humanoid.JumpPower = Config.LOBBY_JUMP_POWER or 50

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = getSpawnCFrame()
	end
end

-- === JOIN ARENA ===
local joinArena = remotes and remotes:FindFirstChild("JoinArena")
if joinArena then
	joinArena.OnServerEvent:Connect(function(player, arenaType)
		local data = PlayerManager.GetData(player)
		if not data then return end

		if data.InArena then return end

		data.InArena = true
		data.ArenaType = arenaType or "PvP"

		-- Kill humanoid movement (flight controller takes over on client)
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
			end
		end

		PlayerManager.UpdateClient(player)

		local arenaManager = _G.ArenaManager
		if arenaManager and arenaManager.SpawnInArena then
			arenaManager.SpawnInArena(player)
		end
	end)
end

-- === LEAVE ARENA ===
local leaveArena = remotes and remotes:FindFirstChild("LeaveArena")
if leaveArena then
	leaveArena.OnServerEvent:Connect(function(player)
		local data = PlayerManager.GetData(player)
		if not data then return end

		data.InArena = false
		data.ArenaType = ""

		local character = player.Character
		if character then
			-- Remove jet model
			local jet = character:FindFirstChild("JetModel")
			if jet then jet:Destroy() end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.LOBBY_TAXI_SPEED or 80
				humanoid.JumpPower = Config.LOBBY_JUMP_POWER or 50
			end

			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				hrp.CFrame = getSpawnCFrame()
			end
		end

		PlayerManager.UpdateClient(player)
	end)
end

-- === RETURN TO LOBBY ===
local returnToLobby = remotes and remotes:FindFirstChild("ReturnToLobby")
if returnToLobby then
	returnToLobby.OnServerEvent:Connect(function(player)
		local data = PlayerManager.GetData(player)
		if not data then return end

		data.InArena = false
		data.ArenaType = ""

		local character = player.Character
		if character then
			-- Remove jet model
			local jet = character:FindFirstChild("JetModel")
			if jet then jet:Destroy() end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.LOBBY_TAXI_SPEED or 80
				humanoid.JumpPower = Config.LOBBY_JUMP_POWER or 50
			end

			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				hrp.CFrame = getSpawnCFrame()
			end
		end

		PlayerManager.UpdateClient(player)
	end)
end

-- === REQUEST DATA ===
local requestData = remotes and remotes:FindFirstChild("RequestData")
if requestData then
	requestData.OnServerEvent:Connect(function(player)
		PlayerManager.UpdateClient(player)
	end)
end

-- === VIP CHECK ===
local vipCheck = remotes and remotes:FindFirstChild("VIPCheck")
if vipCheck then
	vipCheck.OnServerEvent:Connect(function(player)
		local data = PlayerManager.GetData(player)
		if not data then return end

		local isVIP = data.IsVIP or data.PermanentVIP or false
		fireRemote("VIPCheck", player, isVIP)
	end)
end

print("[LobbyManager] Initialized successfully")