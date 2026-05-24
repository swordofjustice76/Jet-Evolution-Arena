local RankDefs = {
	-- Iron 1-10
	Iron1 = {tier = "Iron", sub = 1, xpRequired = 0, next = "Iron2"},
	Iron2 = {tier = "Iron", sub = 2, xpRequired = 100, next = "Iron3"},
	Iron3 = {tier = "Iron", sub = 3, xpRequired = 250, next = "Iron4"},
	Iron4 = {tier = "Iron", sub = 4, xpRequired = 500, next = "Iron5"},
	Iron5 = {tier = "Iron", sub = 5, xpRequired = 800, next = "Iron6"},
	Iron6 = {tier = "Iron", sub = 6, xpRequired = 1200, next = "Iron7"},
	Iron7 = {tier = "Iron", sub = 7, xpRequired = 1700, next = "Iron8"},
	Iron8 = {tier = "Iron", sub = 8, xpRequired = 2300, next = "Iron9"},
	Iron9 = {tier = "Iron", sub = 9, xpRequired = 3000, next = "Iron10"},
	Iron10 = {tier = "Iron", sub = 10, xpRequired = 4000, next = "Bronze1"},

	-- Bronze 1-10
	Bronze1 = {tier = "Bronze", sub = 1, xpRequired = 5000, next = "Bronze2"},
	Bronze2 = {tier = "Bronze", sub = 2, xpRequired = 6500, next = "Bronze3"},
	Bronze3 = {tier = "Bronze", sub = 3, xpRequired = 8500, next = "Bronze4"},
	Bronze4 = {tier = "Bronze", sub = 4, xpRequired = 11000, next = "Bronze5"},
	Bronze5 = {tier = "Bronze", sub = 5, xpRequired = 14000, next = "Bronze6"},
	Bronze6 = {tier = "Bronze", sub = 6, xpRequired = 17500, next = "Bronze7"},
	Bronze7 = {tier = "Bronze", sub = 7, xpRequired = 22000, next = "Bronze8"},
	Bronze8 = {tier = "Bronze", sub = 8, xpRequired = 27000, next = "Bronze9"},
	Bronze9 = {tier = "Bronze", sub = 9, xpRequired = 33000, next = "Bronze10"},
	Bronze10 = {tier = "Bronze", sub = 10, xpRequired = 40000, next = "Silver"},

	-- Silver+
	Silver = {tier = "Silver", sub = 0, xpRequired = 50000, next = "Gold"},
	Gold = {tier = "Gold", sub = 0, xpRequired = 75000, next = "Platinum"},
	Platinum = {tier = "Platinum", sub = 0, xpRequired = 110000, next = "Emerald"},
	Emerald = {tier = "Emerald", sub = 0, xpRequired = 160000, next = "Diamond"},
	Diamond = {tier = "Diamond", sub = 0, xpRequired = 250000, next = nil},
}

-- Tier colors for UI
RankDefs.TierColors = {
	Iron = {r = 0.6, g = 0.6, b = 0.6},
	Bronze = {r = 0.8, g = 0.5, b = 0.2},
	Silver = {r = 0.75, g = 0.75, b = 0.8},
	Gold = {r = 1, g = 0.84, b = 0},
	Platinum = {r = 0.1, g = 0.8, b = 0.7},
	Emerald = {r = 0.1, g = 0.7, b = 0.3},
	Diamond = {r = 0.3, g = 0.6, b = 1},
}

function RankDefs.GetDisplay(rankName)
	local rank = RankDefs[rankName]
	if not rank then return "Unranked" end
	if rank.sub and rank.sub > 0 then
		return rank.tier .. " " .. rank.sub
	end
	return rank.tier
end

function RankDefs.GetTier(rankName)
	local rank = RankDefs[rankName]
	return rank and rank.tier or "Iron"
end

function RankDefs.CanRankUp(currentRank, currentXP)
	local rank = RankDefs[currentRank]
	if not rank or not rank.next then return false end
	local nextRank = RankDefs[rank.next]
	if not nextRank then return false end
	return currentXP >= nextRank.xpRequired
end

function RankDefs.GetNextRank(currentRank)
	local rank = RankDefs[currentRank]
	return rank and rank.next or nil
end

return RankDefs