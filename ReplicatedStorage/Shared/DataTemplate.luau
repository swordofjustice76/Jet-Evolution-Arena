local DataTemplate = {
	-- Identity
	Version = 1,

	-- Progression
	Level = 1,
	XP = 0,
	StatPoints = 0,
	Stats = {
		Damage = 0,
		FireRate = 0,
		ProjectileHealth = 0,
		Speed = 0,
		Maneuverability = 0,
		MaxHP = 0,
		Regen = 0,
		Boost = 0,
	},

	-- Evolution
	CurrentEvolution = "Starter",
	EvolutionPath = {},

	-- Ranking
	Rank = "Iron1",
	RankXP = 0,
	PendingRankUpReward = "",

	-- Currency
	Medals = 0,

	-- Abilities
	OwnedAbilities = {},
	EquippedAbility = "",
	AbilityCharges = {},

	-- Boosts
	ActiveBoosts = {
		Speed = 0,
		Damage = 0,
	},

	-- Shop / Items
	OwnedTitanTrials = {},
	Chests = {Common = 0, Rare = 0, Epic = 0},
	OwnedJets = {"Starter"},

	-- VIP
	IsVIP = false,
	PermanentVIP = false,
	VIPGamepass = false,

	-- Daily / Limits
	DailySpins = 0,
	LastSpinDate = "",
	AdRevivalsUsed = 0,
	AdRevivalsDate = "",

	-- Daily Login Streak
	LoginStreak = 1,
	DailyRewardClaimed = false,
	LastLoginDate = "",

	-- Playtime Rewards
	PlaytimeRewardsClaimed = {},

	-- Session
	TotalKills = 0,
	TotalDeaths = 0,
	TotalBossDamage = 0,
	TotalPlayTime = 0,

	-- Arena state (not persisted)
	InArena = false,
	ArenaType = "",
}

function DataTemplate.New()
	local data = {}
	for k, v in pairs(DataTemplate) do
		if k ~= "New" and k ~= "Merge" then
			if type(v) == "table" then
				local copy = {}
				for sk, sv in pairs(v) do
					copy[sk] = sv
				end
				data[k] = copy
			else
				data[k] = v
			end
		end
	end
	return data
end

function DataTemplate.Merge(savedData)
	local data = DataTemplate.New()
	if not savedData then return data end
	for k, v in pairs(savedData) do
		if data[k] ~= nil then
			if type(v) == "table" and type(data[k]) == "table" then
				for sk, sv in pairs(v) do
					data[k][sk] = sv
				end
			else
				data[k] = v
			end
		end
	end
	return data
end

return DataTemplate