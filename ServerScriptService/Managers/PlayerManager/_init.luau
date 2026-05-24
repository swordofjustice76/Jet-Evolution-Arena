local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local Config = require(ReplicatedStorage:FindFirstChild("Shared"):FindFirstChild("Config"))
local DataTemplate = require(ReplicatedStorage:FindFirstChild("Shared"):FindFirstChild("DataTemplate"))
local RankDefs = require(ReplicatedStorage:FindFirstChild("Shared"):FindFirstChild("RankDefs"))

-- DataStore setup (wrapped in pcall for studio/privacy mode)
local dataStore
local ok, err = pcall(function()
	dataStore = DataStoreService:GetDataStore("PlayerData_v1")
end)
if not ok then
	warn("[PlayerManager] DataStore unavailable: " .. tostring(err))
end

-- Player data cache
local playerDataCache = {}
local autoSaveInterval = Config.AUTOSAVE_INTERVAL or 120

-- === DATA OPERATIONS ===
local function loadData(player)
	local key = "Player_" .. player.UserId
	if dataStore then
		local success, savedData = pcall(function()
			return dataStore:GetAsync(key)
		end)
		if success and savedData then
			return DataTemplate.Merge(savedData)
		end
	end
	return DataTemplate.New()
end

local function saveData(player)
	local data = playerDataCache[player]
	if not data then return end
	if dataStore then
		local key = "Player_" .. player.UserId
		local persistData = {}
		for k, v in pairs(data) do
			if k ~= "InArena" and k ~= "ArenaType" then
				persistData[k] = v
			end
		end
		local success, saveErr = pcall(function()
			dataStore:SetAsync(key, persistData)
		end)
		if not success then
			warn("[PlayerManager] Failed to save data for " .. player.Name .. ": " .. tostring(saveErr))
		end
	end
end

local function getData(player)
	return playerDataCache[player]
end

local function updateClient(player)
	local data = playerDataCache[player]
	if not data then return end
	local updateRemote = Remotes and Remotes:FindFirstChild("UpdateClient")
	if updateRemote then
		updateRemote:FireClient(player, data)
	end
end

-- === XP / LEVEL / RANK ===
local function addXP(player, amount)
	local data = playerDataCache[player]
	if not data then return 0 end
	if data.IsVIP then
		amount = math.floor(amount * (Config.VIP_XP_MULTIPLIER or 1))
	end
	if data.ActiveBoosts and data.ActiveBoosts.Speed and data.ActiveBoosts.Speed > os.time() then
		amount = math.floor(amount * 1.5)
	end
	data.XP = data.XP + amount
	while data.Level < Config.MAX_LEVEL do
		local required = Config.XP_CURVE(data.Level)
		if data.XP >= required then
			data.XP = data.XP - required
			data.Level = data.Level + 1
			data.StatPoints = data.StatPoints + (Config.STAT_PER_LEVEL or 1)
		else
			break
		end
	end
	data.RankXP = (data.RankXP or 0) + amount
	while RankDefs.CanRankUp(data.Rank, data.RankXP) do
		local nextRank = RankDefs.GetNextRank(data.Rank)
		if nextRank then
			data.Rank = nextRank
			data.PendingRankUpReward = nextRank
			local rankUpRemote = Remotes and Remotes:FindFirstChild("RankUp")
			if rankUpRemote then
				rankUpRemote:FireClient(player, {
					rank = nextRank,
					display = RankDefs.GetDisplay(nextRank),
				})
			end
		else
			break
		end
	end
	updateClient(player)
	return amount
end

local function addMedals(player, amount)
	local data = playerDataCache[player]
	if not data then return 0 end
	if data.IsVIP then
		amount = math.floor(amount * (Config.VIP_MEDAL_MULTIPLIER or 1))
	end
	data.Medals = data.Medals + amount
	updateClient(player)
	return amount
end

local function spendMedals(player, amount)
	local data = playerDataCache[player]
	if not data then return false end
	if data.Medals < amount then return false end
	data.Medals = data.Medals - amount
	updateClient(player)
	return true
end

local function addChests(player, chestType, count)
	local data = playerDataCache[player]
	if not data then return end
	if not data.Chests then data.Chests = {Common = 0, Rare = 0, Epic = 0} end
	data.Chests[chestType] = (data.Chests[chestType] or 0) + count
	updateClient(player)
end

local function addPlaytime(player, seconds)
	local data = playerDataCache[player]
	if not data then return end
	data.TotalPlayTime = (data.TotalPlayTime or 0) + seconds
end

-- === PLAYER SETUP ===
local function onPlayerAdded(player)
	playerDataCache[player] = loadData(player)
	local data = playerDataCache[player]

	local today = os.date("%Y-%m-%d")
	if data.LastSpinDate ~= today then
		data.DailySpins = 0
		data.LastSpinDate = today
	end
	if data.AdRevivalsDate ~= today then
		data.AdRevivalsUsed = 0
		data.AdRevivalsDate = today
	end

	-- Daily Login Streak
	local lastLogin = data.LastLoginDate or ""
	if lastLogin == "" then
		data.LoginStreak = 1
		data.DailyRewardClaimed = false
	elseif lastLogin == today then
		-- Same day rejoin
	elseif lastLogin ~= today then
		local lastParts = string.split(lastLogin, "-")
		local todayParts = string.split(today, "-")
		local lastTime = os.time({
			year = tonumber(lastParts[1]) or 2024,
			month = tonumber(lastParts[2]) or 1,
			day = tonumber(lastParts[3]) or 1,
			hour = 0, min = 0, sec = 0
		})
		local todayTime = os.time({
			year = tonumber(todayParts[1]) or 2024,
			month = tonumber(todayParts[2]) or 1,
			day = tonumber(todayParts[3]) or 1,
			hour = 0, min = 0, sec = 0
		})
		local hoursDiff = (todayTime - lastTime) / 3600
		if hoursDiff <= (Config.LOGIN_STREAK_GRACE_HOURS or 36) then
			data.LoginStreak = math.min((data.LoginStreak or 0) + 1, Config.LOGIN_STREAK_MAX or 7)
		else
			data.LoginStreak = 1
		end
		data.DailyRewardClaimed = false
	end
	data.LastLoginDate = today

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then return end
		local maxHP = 100 + (data.Stats.MaxHP or 0) * 10
		humanoid.MaxHealth = maxHP
		humanoid.Health = maxHP
		if data.InArena then
			humanoid.WalkSpeed = Config.BASE_SPEED + (data.Stats.Speed or 0) * Config.STAT_SCALE.Speed
			task.defer(function()
				local am = _G.ArenaManager
				if am and am.RespawnInArena then
					am.RespawnInArena(player)
				end
			end)
		else
			humanoid.WalkSpeed = Config.LOBBY_TAXI_SPEED or 80
			humanoid.JumpPower = Config.LOBBY_JUMP_POWER or 50
		end
		character:SetAttribute("BoostEnergy", Config.MAX_BOOST_ENERGY)
		character:SetAttribute("Level", data.Level)
		character:SetAttribute("InArena", data.InArena)
	end)

	task.delay(1, function()
		updateClient(player)
		local dailyLoginResult = Remotes and Remotes:FindFirstChild("DailyLoginResult")
		if dailyLoginResult then
			dailyLoginResult:FireClient(player, {
				success = false,
				streak = data.LoginStreak or 1,
				claimed = data.DailyRewardClaimed or false,
				lastLogin = data.LastLoginDate or today,
			})
		end
	end)

	print("[PlayerManager] Loaded data for " .. player.Name .. " (Level " .. data.Level .. ", Streak: " .. (data.LoginStreak or 1) .. ")")
end

local function onPlayerRemoving(player)
	saveData(player)
	playerDataCache[player] = nil
	print("[PlayerManager] Saved data for " .. player.Name)
end

-- Remote handlers
local getDataRemote = Remotes and Remotes:FindFirstChild("GetData")
if getDataRemote and getDataRemote:IsA("RemoteFunction") then
	getDataRemote.OnServerInvoke = function(player)
		return playerDataCache[player]
	end
end

-- Auto-save
task.spawn(function()
	while true do
		task.wait(autoSaveInterval)
		for player, _ in pairs(playerDataCache) do
			saveData(player)
		end
	end
end)

game:BindToClose(function()
	print("[PlayerManager] Game closing, saving all data...")
	for player, _ in pairs(playerDataCache) do
		saveData(player)
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Export via _G
_G.PlayerManager = {
	GetData = getData,
	SetData = function(player, key, value)
		local data = playerDataCache[player]
		if data and data[key] ~= nil then
			data[key] = value
		end
	end,
	AddXP = addXP,
	AddMedals = addMedals,
	SpendMedals = spendMedals,
	AddChests = addChests,
	AddPlaytime = addPlaytime,
	SaveData = saveData,
	UpdateClient = updateClient,
	NotifyClient = updateClient,
}

print("[PlayerManager] Initialized successfully")

return _G.PlayerManager