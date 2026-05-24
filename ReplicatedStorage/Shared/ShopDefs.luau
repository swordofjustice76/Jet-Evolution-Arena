local ShopDefs = {
	-- Starter Packs
	StarterPacks = {
		AetherRecruit = {
			name = "Aether Recruit",
			id = "AetherRecruit",
			robuxCost = 399,
			rewards = {
				xp = 25000,
				abilities = {"AfterburnerSurge"},
				boostMinutes = 30,
				boostType = "SpeedAndDamage",
				boostMultiplier = 2,
				medals = 150,
				chests = {Common = 3},
			},
		},
		SkyCommander = {
			name = "Sky Commander",
			id = "SkyCommander",
			robuxCost = 799,
			rewards = {
				xp = 70000,
				abilities = {"MissileSwarm"},
				boostMinutes = 30,
				boostType = "SpeedAndDamage",
				boostMultiplier = 2,
				medals = 350,
				chests = {Rare = 2, Common = 1},
				titanTrialMinutes = 15,
				titanTrialJet = "AetherTitan",
			},
		},
		AetherOverlord = {
			name = "Aether Overlord",
			id = "AetherOverlord",
			robuxCost = 1499,
			rewards = {
				xp = 160000,
				abilities = {"PhoenixRevival"},
				boostMinutes = 30,
				boostType = "SpeedAndDamage",
				boostMultiplier = 2,
				medals = 800,
				chests = {Epic = 3, Rare = 1},
			},
		},
	},

	-- Titan Jet Rentals
	TitanRentals = {
		AetherTitan = {
			name = "Aether Titan",
			id = "AetherTitan",
			prices = {
				[15] = 99,
				[30] = 179,
				[60] = 299,
				[1440] = 999,
			},
		},
		VoidTitan = {
			name = "Void Titan",
			id = "VoidTitan",
			prices = {
				[15] = 119,
				[30] = 199,
				[60] = 349,
				[1440] = 1199,
			},
		},
		StormTitan = {
			name = "Storm Titan",
			id = "StormTitan",
			prices = {
				[15] = 129,
				[30] = 219,
				[60] = 379,
				[1440] = 1299,
			},
		},
		EternalTitan = {
			name = "Eternal Titan",
			id = "EternalTitan",
			prices = {
				[15] = 149,
				[30] = 249,
				[60] = 429,
				[1440] = 1499,
			},
		},
	},

	-- Chest Loot Tables
	ChestLoot = {
		Common = {
			{type = "XP", min = 500, max = 2000, weight = 40},
			{type = "Medals", min = 20, max = 80, weight = 35},
			{type = "XP", min = 2000, max = 5000, weight = 15},
			{type = "Medals", min = 80, max = 200, weight = 8},
			{type = "Ability", id = "AfterburnerSurge", weight = 2},
		},
		Rare = {
			{type = "XP", min = 2000, max = 8000, weight = 30},
			{type = "Medals", min = 100, max = 400, weight = 30},
			{type = "XP", min = 8000, max = 20000, weight = 15},
			{type = "Medals", min = 400, max = 800, weight = 10},
			{type = "Ability", id = "StrafeDash", weight = 5},
			{type = "Ability", id = "MicroShield", weight = 5},
			{type = "TitanTrial", minutes = 15, id = "AetherTitan", weight = 5},
		},
		Epic = {
			{type = "XP", min = 10000, max = 40000, weight = 25},
			{type = "Medals", min = 500, max = 2000, weight = 25},
			{type = "Ability", id = "MissileSwarm", weight = 10},
			{type = "Ability", id = "EMPBurst", weight = 10},
			{type = "Ability", id = "StealthVeil", weight = 8},
			{type = "Ability", id = "RailSnipe", weight = 7},
			{type = "TitanTrial", minutes = 30, id = "VoidTitan", weight = 10},
			{type = "TitanTrial", minutes = 30, id = "StormTitan", weight = 5},
		},
	},

	-- Prize Wheel Segments
	PrizeWheel = {
		{label = "50 Medals", type = "Medals", value = 50, weight = 25},
		{label = "100 XP", type = "XP", value = 100, weight = 20},
		{label = "200 Medals", type = "Medals", value = 200, weight = 15},
		{label = "500 XP", type = "XP", value = 500, weight = 12},
		{label = "Common Chest", type = "Chest", value = "Common", weight = 10},
		{label = "500 Medals", type = "Medals", value = 500, weight = 8},
		{label = "Rare Chest", type = "Chest", value = "Rare", weight = 5},
		{label = "1500 XP", type = "XP", value = 1500, weight = 3},
		{label = "Permanent VIP", type = "PermanentVIP", value = true, weight = 1},
		{label = "Epic Chest", type = "Chest", value = "Epic", weight = 1},
	},
}

function ShopDefs.RollChest(chestType)
	local lootTable = ShopDefs.ChestLoot[chestType]
	if not lootTable then return {type = "XP", value = 100} end

	local totalWeight = 0
	for _, item in ipairs(lootTable) do
		totalWeight = totalWeight + item.weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, item in ipairs(lootTable) do
		cumulative = cumulative + item.weight
		if roll <= cumulative then
			if item.type == "XP" or item.type == "Medals" then
				return {type = item.type, value = math.random(item.min, item.max)}
			else
				return item
			end
		end
	end

	return {type = "XP", value = 100}
end

function ShopDefs.RollWheel()
	local totalWeight = 0
	for _, seg in ipairs(ShopDefs.PrizeWheel) do
		totalWeight = totalWeight + seg.weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, seg in ipairs(ShopDefs.PrizeWheel) do
		cumulative = cumulative + seg.weight
		if roll <= cumulative then
			return seg
		end
	end

	return ShopDefs.PrizeWheel[1]
end

return ShopDefs