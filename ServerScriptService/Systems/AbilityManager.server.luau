local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerManager = require(script.Parent.Parent.Managers.PlayerManager)
local Config = require(ReplicatedStorage.Shared.Config)
local AbilityDefs = require(ReplicatedStorage.Shared.AbilityDefs)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local function fireRemote(name, player, ...)
	local remote = remotes and remotes:FindFirstChild(name)
	if remote then
		remote:FireClient(player, ...)
	end
end

-- === USE ABILITY ===
local useAbility = remotes and remotes:FindFirstChild("UseAbility")
if useAbility then
	useAbility.OnServerEvent:Connect(function(player, abilityId)
		local data = PlayerManager.GetData(player)
		if not data then return end
		if not data.InArena then return end

		local abilityDef = AbilityDefs.GetByID and AbilityDefs.GetByID(abilityId) or AbilityDefs[abilityId]
		if not abilityDef then
			fireRemote("AbilityResult", player, {success = false, message = "Invalid ability!"})
			return
		end

		local owned = false
		for _, id in ipairs(data.OwnedAbilities or {}) do
			if id == abilityId then owned = true break end
		end
		if not owned then
			fireRemote("AbilityResult", player, {success = false, message = "You don't own this ability!"})
			return
		end

		if data.EquippedAbility ~= abilityId then
			fireRemote("AbilityResult", player, {success = false, message = "Ability not equipped!"})
			return
		end

		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- Apply ability effects
		if abilityDef.type == "boost" then
			if abilityDef.stat == "Speed" then
				humanoid.WalkSpeed = humanoid.WalkSpeed * (abilityDef.multiplier or 1.5)
				task.delay(abilityDef.duration or 5, function()
					if humanoid and humanoid.Parent then
						humanoid.WalkSpeed = Config.BASE_SPEED + (data.Stats.Speed or 0) * Config.STAT_SCALE.Speed
					end
				end)
			elseif abilityDef.stat == "Damage" then
				if not data.ActiveBoosts then data.ActiveBoosts = {} end
				data.ActiveBoosts.Damage = os.time() + (abilityDef.duration or 5)
			end
		elseif abilityDef.type == "heal" then
			local healAmount = abilityDef.amount or 50
			humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
		elseif abilityDef.type == "dash" then
			local dashForce = abilityDef.force or 100
			local lookVector = hrp.CFrame.LookVector
			hrp.AssemblyLinearVelocity = lookVector * dashForce + Vector3.new(0, 10, 0)
		elseif abilityDef.type == "shield" then
			local shieldAmount = abilityDef.amount or 50
			humanoid.MaxHealth = humanoid.MaxHealth + shieldAmount
			humanoid.Health = math.min(humanoid.Health + shieldAmount, humanoid.MaxHealth)
			task.delay(abilityDef.duration or 5, function()
				if humanoid and humanoid.Parent then
					humanoid.MaxHealth = 100 + (data.Stats.MaxHP or 0) * 10
					humanoid.Health = math.min(humanoid.Health, humanoid.MaxHealth)
				end
			end)
		end

		fireRemote("AbilityResult", player, {
			success = true,
			action = "use",
			abilityId = abilityId,
		})

		fireRemote("BoostUpdate", player, data.ActiveBoosts or {})
	end)
end

print("[AbilityManager] Initialized successfully")