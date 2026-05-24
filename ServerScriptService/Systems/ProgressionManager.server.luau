local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerManager = require(script.Parent.Parent.Managers.PlayerManager)
local Config = require(ReplicatedStorage.Shared.Config)
local EvolutionTree = require(ReplicatedStorage.Shared.EvolutionTree)
local AbilityDefs = require(ReplicatedStorage.Shared.AbilityDefs)
local RankDefs = require(ReplicatedStorage.Shared.RankDefs)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local function fireRemote(name, player, ...)
	local remote = remotes and remotes:FindFirstChild(name)
	if remote then
		remote:FireClient(player, ...)
	end
end

-- === STAT UPGRADE ===
local upgradeStat = remotes and remotes:FindFirstChild("UpgradeStat")
if upgradeStat then
	upgradeStat.OnServerEvent:Connect(function(player, statName, amount)
		amount = tonumber(amount) or 1
		amount = math.clamp(amount, 1, 5)

		local data = PlayerManager.GetData(player)
		if not data then return end

		local validStat = false
		for _, name in ipairs(Config.STAT_NAMES) do
			if name == statName then validStat = true break end
		end
		if not validStat then return end

		if not data.Stats then data.Stats = {} end
		local currentLevel = data.Stats[statName] or 0
		local roomLeft = Config.MAX_STAT_LEVEL - currentLevel

		if data.StatPoints <= 0 or roomLeft <= 0 then
			fireRemote("StatResult", player, {
				success = false,
				stat = statName,
				error = roomLeft <= 0 and "Stat maxed" or "Not enough stat points",
			})
			return
		end

		local actualAmount = math.min(amount, data.StatPoints, roomLeft)
		data.Stats[statName] = currentLevel + actualAmount
		data.StatPoints = data.StatPoints - actualAmount

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				if statName == "MaxHP" then
					humanoid.MaxHealth = 100 + data.Stats.MaxHP * 10
					humanoid.Health = math.min(humanoid.Health, humanoid.MaxHealth)
				elseif statName == "Speed" then
					if data.InArena then
						humanoid.WalkSpeed = Config.BASE_SPEED + data.Stats.Speed * Config.STAT_SCALE.Speed
					end
				end
			end
		end

		fireRemote("StatResult", player, {
			success = true,
			stat = statName,
			newLevel = data.Stats[statName],
			statPoints = data.StatPoints,
		})

		PlayerManager.UpdateClient(player)
	end)
end

-- === EVOLUTION ===
local evolveRemote = remotes and remotes:FindFirstChild("Evolve")
if evolveRemote then
	evolveRemote.OnServerEvent:Connect(function(player, jetName)
		local data = PlayerManager.GetData(player)
		if not data then return end

		local evo = EvolutionTree[jetName]
		if not evo then
			fireRemote("EvolveResult", player, {success = false, error = "Invalid evolution!"})
			return
		end

		if evo.isTitan then
			fireRemote("EvolveResult", player, {success = false, error = "Cannot evolve to titans!"})
			return
		end

		if data.Level < evo.level then
			fireRemote("EvolveResult", player, {success = false, error = "Level " .. evo.level .. " required!"})
			return
		end

		if evo.parent and evo.parent ~= data.CurrentEvolution then
			local currentEvo = EvolutionTree[data.CurrentEvolution]
			if not currentEvo or currentEvo.parent ~= evo.parent then
				if data.Level < evo.level then
					fireRemote("EvolveResult", player, {success = false, error = "Previous evolution required!"})
					return
				end
			end
		end

		if not data.EvolutionPath then data.EvolutionPath = {} end
		local alreadyOnPath = false
		for _, pathEvo in ipairs(data.EvolutionPath) do
			if pathEvo == jetName then alreadyOnPath = true break end
		end
		if not alreadyOnPath then
			table.insert(data.EvolutionPath, data.CurrentEvolution)
		end

		data.CurrentEvolution = jetName

		fireRemote("EvolveResult", player, {
			success = true,
			evolution = jetName,
		})

		PlayerManager.UpdateClient(player)
	end)
end

-- === EQUIP ABILITY ===
local equipAbility = remotes and remotes:FindFirstChild("EquipAbility")
if equipAbility then
	equipAbility.OnServerEvent:Connect(function(player, abilityId)
		local data = PlayerManager.GetData(player)
		if not data then return end

		local owned = false
		for _, id in ipairs(data.OwnedAbilities or {}) do
			if id == abilityId then owned = true break end
		end
		if not owned then
			fireRemote("AbilityResult", player, {success = false, message = "You don't own this ability!"})
			return
		end

		data.EquippedAbility = abilityId

		fireRemote("AbilityResult", player, {
			success = true,
			action = "equip",
			abilityId = abilityId,
		})

		PlayerManager.UpdateClient(player)
	end)
end

print("[ProgressionManager] Initialized successfully")