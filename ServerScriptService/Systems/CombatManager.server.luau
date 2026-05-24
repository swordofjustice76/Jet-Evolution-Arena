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

-- === DAMAGE HANDLING ===
local takeDamage = remotes and remotes:FindFirstChild("TakeDamage")
if takeDamage then
	takeDamage.OnServerEvent:Connect(function(player, targetPlayerName, damage)
		local data = PlayerManager.GetData(player)
		if not data then return end
		if not data.InArena then return end

		damage = tonumber(damage) or 0
		if damage <= 0 then return end

		local targetPlayer = Players:FindFirstChild(targetPlayerName)
		if not targetPlayer then return end

		local targetData = PlayerManager.GetData(targetPlayer)
		if not targetData then return end
		if not targetData.InArena then return end

		local targetCharacter = targetPlayer.Character
		if not targetCharacter then return end

		local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local attackerStats = data.Stats or {}
		local baseDamage = damage + (attackerStats.Damage or 0) * (Config.STAT_SCALE.Damage or 1)

		humanoid:TakeDamage(baseDamage)

		fireRemote("DamageNumber", targetPlayer, baseDamage)
		fireRemote("KillFeed", player, {target = targetPlayerName, damage = baseDamage})

		if humanoid.Health <= 0 then
			local xpReward = Config.KILL_XP or 50
			local medalReward = Config.KILL_MEDALS or 10
			PlayerManager.AddXP(player, xpReward)
			PlayerManager.AddMedals(player, medalReward)

			fireRemote("DeathEvent", targetPlayer, {
				killer = player.Name,
				canRevive = true,
			})
		end
	end)
end

-- === FIRE WEAPON ===
local fireWeapon = remotes and remotes:FindFirstChild("FireWeapon")
if fireWeapon then
	fireWeapon.OnServerEvent:Connect(function(player, direction)
		local data = PlayerManager.GetData(player)
		if not data then return end
		if not data.InArena then return end

		local character = player.Character
		if not character then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local projectileVisuals = ReplicatedStorage.Shared and ReplicatedStorage.Shared:FindFirstChild("ProjectileVisuals")
		if projectileVisuals then
			local visuals = require(projectileVisuals)
			if visuals.CreateProjectile then
				visuals.CreateProjectile(hrp.CFrame, direction)
			end
		end
	end)
end

-- === REVIVE CHOICE ===
local reviveChoice = remotes and remotes:FindFirstChild("ReviveChoice")
if reviveChoice then
	reviveChoice.OnServerEvent:Connect(function(player, choice)
		local data = PlayerManager.GetData(player)
		if not data then return end

		if choice == "respawn" then
			player:LoadCharacter()
		elseif choice == "ad" then
			local today = os.date("%Y-%m-%d")
			if data.AdRevivalsDate ~= today then
				data.AdRevivalsUsed = 0
				data.AdRevivalsDate = today
			end
			local maxAdRevivals = Config.AD_REVIVALS_DAILY or 3
			if (data.AdRevivalsUsed or 0) < maxAdRevivals then
				data.AdRevivalsUsed = (data.AdRevivalsUsed or 0) + 1
				player:LoadCharacter()
			end
		end
	end)
end

print("[CombatManager] Initialized successfully")