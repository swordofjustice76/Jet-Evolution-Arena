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

-- === DAILY LOGIN STREAK CLAIM ===
local claimDailyLogin = remotes and remotes:FindFirstChild("ClaimDailyLogin")
if claimDailyLogin then
	claimDailyLogin.OnServerEvent:Connect(function(player)
		local data = PlayerManager.GetData(player)
		if not data then return end

		if data.DailyRewardClaimed then
			fireRemote("DailyLoginResult", player, {
				success = false,
				streak = data.LoginStreak or 1,
				claimed = true,
			})
			return
		end

		local streakDay = data.LoginStreak or 1
		local reward = Config.LOGIN_STREAK_REWARDS and Config.LOGIN_STREAK_REWARDS[streakDay]

		if reward then
			if reward.medals then
				PlayerManager.AddMedals(player, reward.medals)
			end
			if reward.xp then
				PlayerManager.AddXP(player, reward.xp)
			end
			if reward.chests then
				for chestType, count in pairs(reward.chests) do
					PlayerManager.AddChests(player, chestType, count)
				end
			end
			if reward.boostMinutes then
				local boostSeconds = reward.boostMinutes * 60
				if not data.ActiveBoosts then data.ActiveBoosts = {} end
				data.ActiveBoosts.Speed = (data.ActiveBoosts.Speed or 0) + boostSeconds
			end
		end

		data.DailyRewardClaimed = true

		fireRemote("DailyLoginResult", player, {
			success = true,
			streak = streakDay,
			claimed = true,
			rewards = reward,
		})

		fireRemote("ClaimSound", player, "dailyLogin")
		PlayerManager.UpdateClient(player)
	end)
end

-- === PLAYTIME REWARD CLAIM ===
local claimPlaytimeReward = remotes and remotes:FindFirstChild("ClaimPlaytimeReward")
if claimPlaytimeReward then
	claimPlaytimeReward.OnServerEvent:Connect(function(player, rewardTime)
		rewardTime = tonumber(rewardTime) or 0
		local data = PlayerManager.GetData(player)
		if not data then return end

		local rewardConfig = nil
		for _, reward in ipairs(Config.PLAYTIME_REWARDS) do
			if reward.time == rewardTime then
				rewardConfig = reward
				break
			end
		end
		if not rewardConfig then return end

		if (data.TotalPlayTime or 0) < rewardTime then
			fireRemote("PlaytimeRewardResult", player, {success = false, time = rewardTime})
			return
		end

		if not data.PlaytimeRewardsClaimed then data.PlaytimeRewardsClaimed = {} end
		for _, t in ipairs(data.PlaytimeRewardsClaimed) do
			if t == rewardTime then
				fireRemote("PlaytimeRewardResult", player, {success = false, time = rewardTime})
				return
			end
		end

		if rewardConfig.xp then
			PlayerManager.AddXP(player, rewardConfig.xp)
		end
		if rewardConfig.medals then
			PlayerManager.AddMedals(player, rewardConfig.medals)
		end

		table.insert(data.PlaytimeRewardsClaimed, rewardTime)

		fireRemote("PlaytimeRewardResult", player, {
			success = true,
			time = rewardTime,
			xp = rewardConfig.xp,
			medals = rewardConfig.medals,
		})

		fireRemote("ClaimSound", player, "playtime")
		PlayerManager.UpdateClient(player)
	end)
end

-- === PLAYTIME TRACKING ===
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			if not player.Parent then continue end
			PlayerManager.AddPlaytime(player, 1)

			local data = PlayerManager.GetData(player)
			if data then
				local totalPlayTime = data.TotalPlayTime or 0
				local claimedTimes = data.PlaytimeRewardsClaimed or {}

				for _, reward in ipairs(Config.PLAYTIME_REWARDS) do
					if totalPlayTime >= reward.time then
						local isClaimed = false
						for _, t in ipairs(claimedTimes) do
							if t == reward.time then isClaimed = true break end
						end
						if not isClaimed then
							fireRemote("PlaytimeRewardResult", player, {available = true, time = reward.time})
						end
					end
				end
			end
		end
	end
end)

-- === INTERVAL REWARDS (Arena-only) ===
local arenaTimeTracker = {}

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			if not player.Parent then continue end
			local data = PlayerManager.GetData(player)
			if not data or not data.InArena then
				arenaTimeTracker[player] = nil
				continue
			end

			arenaTimeTracker[player] = (arenaTimeTracker[player] or 0) + 1
			local timeInArena = arenaTimeTracker[player]

			for _, reward in ipairs(Config.INTERVAL_REWARDS or {}) do
				if timeInArena == reward.time then
					PlayerManager.AddXP(player, reward.xp)
					PlayerManager.AddMedals(player, reward.medals)

					fireRemote("IntervalReward", player, {
						xp = reward.xp,
						medals = reward.medals,
						time = reward.time,
					})
				end
			end

			local intervalRewards = Config.INTERVAL_REWARDS or {}
			if #intervalRewards > 0 and timeInArena > intervalRewards[#intervalRewards].time then
				local lastTime = intervalRewards[#intervalRewards].time
				local recurTime = Config.INTERVAL_RECUR or 300
				local timeSinceLast = timeInArena - lastTime
				if timeSinceLast > 0 and timeSinceLast % recurTime == 0 then
					local xpReward = intervalRewards[#intervalRewards].xp
					local medalReward = intervalRewards[#intervalRewards].medals
					PlayerManager.AddXP(player, xpReward)
					PlayerManager.AddMedals(player, medalReward)

					fireRemote("IntervalReward", player, {
						xp = xpReward,
						medals = medalReward,
						time = timeInArena,
					})
				end
			end
		end
	end
end)

-- === CLAIM RANK UP REWARD ===
local claimRankUpReward = remotes and remotes:FindFirstChild("ClaimRankUpReward")
if claimRankUpReward then
	claimRankUpReward.OnServerEvent:Connect(function(player)
		local data = PlayerManager.GetData(player)
		if not data then return end
		if not data.PendingRankUpReward or data.PendingRankUpReward == "" then return end

		local reward = Config.RANK_UP_REWARDS
		PlayerManager.AddXP(player, reward.xp)
		PlayerManager.AddMedals(player, reward.medals)

		data.PendingRankUpReward = ""
		PlayerManager.UpdateClient(player)

		fireRemote("RankUpRewardResult", player, {
			success = true,
			xp = reward.xp,
			medals = reward.medals,
		})

		fireRemote("ClaimSound", player, "rankUp")
	end)
end

Players.PlayerRemoving:Connect(function(player)
	arenaTimeTracker[player] = nil
end)

print("[RewardManager] Initialized successfully")