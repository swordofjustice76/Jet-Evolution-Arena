local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local PlayerManager = require(script.Parent.Parent.Managers.PlayerManager)
local Config = require(ReplicatedStorage.Shared.Config)
local ShopDefs = require(ReplicatedStorage.Shared.ShopDefs)
local AbilityDefs = require(ReplicatedStorage.Shared.AbilityDefs)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local function fireRemote(name, player, ...)
	local remote = remotes and remotes:FindFirstChild(name)
	if remote then
		remote:FireClient(player, ...)
	end
end

-- === PRIZE WHEEL SPIN ===
local spinWheel = remotes and remotes:FindFirstChild("SpinWheel")
if spinWheel then
	spinWheel.OnServerEvent:Connect(function(player)
		local data = PlayerManager.GetData(player)
		if not data then return end

		local today = os.date("%Y-%m-%d")
		if data.LastSpinDate ~= today then
			data.DailySpins = 0
			data.LastSpinDate = today
		end

		local freeSpinsMax = Config.WHEEL_FREE_SPINS_DAILY or 1
		local freeSpinsUsed = data.DailySpins or 0

		if freeSpinsUsed >= freeSpinsMax then
			fireRemote("WheelResult", player, {success = false, error = "No free spins remaining today"})
			return
		end

		local prize = ShopDefs.RollWheel()
		if not prize then return end

		local segmentIndex = 1
		for i, seg in ipairs(ShopDefs.PrizeWheel) do
			if seg.label == prize.label then
				segmentIndex = i
				break
			end
		end

		if prize.type == "Medals" then
			PlayerManager.AddMedals(player, prize.value)
		elseif prize.type == "XP" then
			PlayerManager.AddXP(player, prize.value)
		elseif prize.type == "Chest" then
			PlayerManager.AddChests(player, prize.value, 1)
		elseif prize.type == "PermanentVIP" then
			data.PermanentVIP = true
			data.IsVIP = true
		end

		data.DailySpins = freeSpinsUsed + 1
		local freeSpinsLeft = math.max(0, freeSpinsMax - data.DailySpins)

		fireRemote("WheelResult", player, {
			success = true,
			segmentIndex = segmentIndex,
			prize = prize,
			freeSpinsLeft = freeSpinsLeft,
		})

		fireRemote("ClaimSound", player, "wheel")
		PlayerManager.UpdateClient(player)
	end)
end

-- === CHEST OPENING ===
local openChest = remotes and remotes:FindFirstChild("OpenChest")
if openChest then
	openChest.OnServerEvent:Connect(function(player, chestType)
		local data = PlayerManager.GetData(player)
		if not data then return end

		if chestType ~= "Common" and chestType ~= "Rare" and chestType ~= "Epic" then return end

		if not data.Chests then data.Chests = {Common = 0, Rare = 0, Epic = 0} end
		if (data.Chests[chestType] or 0) <= 0 then
			fireRemote("ChestResult", player, {success = false, message = "No chests of this type!"})
			return
		end

		data.Chests[chestType] = data.Chests[chestType] - 1

		local loot = ShopDefs.RollChest(chestType)

		if loot.type == "XP" then
			PlayerManager.AddXP(player, loot.value)
		elseif loot.type == "Medals" then
			PlayerManager.AddMedals(player, loot.value)
		elseif loot.type == "Ability" then
			if not data.OwnedAbilities then data.OwnedAbilities = {} end
			local alreadyOwned = false
			for _, id in ipairs(data.OwnedAbilities) do
				if id == loot.id then alreadyOwned = true break end
			end
			if not alreadyOwned then
				table.insert(data.OwnedAbilities, loot.id)
			end
		elseif loot.type == "TitanTrial" then
			if not data.OwnedTitanTrials then data.OwnedTitanTrials = {} end
			table.insert(data.OwnedTitanTrials, {
				id = loot.id,
				minutes = loot.minutes,
				startTime = os.time(),
			})
		end

		fireRemote("ChestResult", player, {
			success = true,
			chestType = chestType,
			loot = loot,
		})

		fireRemote("ClaimSound", player, "chest")
		PlayerManager.UpdateClient(player)
	end)
end

-- === BUY SHOP ITEM ===
local buyShopItem = remotes and remotes:FindFirstChild("BuyShopItem")
if buyShopItem then
	buyShopItem.OnServerEvent:Connect(function(player, category, itemId, currency)
		local data = PlayerManager.GetData(player)
		if not data then return end

		if category == "Ability" then
			local abilityDef = AbilityDefs.GetByID and AbilityDefs.GetByID(itemId) or AbilityDefs[itemId]
			if not abilityDef then
				fireRemote("PurchaseResult", player, {success = false, error = "Invalid ability!"})
				return
			end

			for _, id in ipairs(data.OwnedAbilities or {}) do
				if id == itemId then
					fireRemote("PurchaseResult", player, {success = false, error = "Already owned!"})
					return
				end
			end

			local cost = abilityDef.medalCost or 0
			if not PlayerManager.SpendMedals(player, cost) then
				fireRemote("PurchaseResult", player, {success = false, error = "Not enough medals!"})
				return
			end

			if not data.OwnedAbilities then data.OwnedAbilities = {} end
			table.insert(data.OwnedAbilities, itemId)

			if data.EquippedAbility == "" then
				data.EquippedAbility = itemId
			end

			fireRemote("PurchaseResult", player, {
				success = true,
				category = "Ability",
				itemId = itemId,
			})

			PlayerManager.UpdateClient(player)

		elseif category == "TitanRental" then
			local titanDef = ShopDefs.TitanRentals and ShopDefs.TitanRentals[itemId]
			if not titanDef then
				fireRemote("PurchaseResult", player, {success = false, error = "Invalid titan!"})
				return
			end

			local duration = tonumber(currency) or 30
			local cost = titanDef.prices and titanDef.prices[duration]
			if not cost then
				fireRemote("PurchaseResult", player, {success = false, error = "Invalid duration!"})
				return
			end

			if not PlayerManager.SpendMedals(player, cost) then
				fireRemote("PurchaseResult", player, {success = false, error = "Not enough medals!"})
				return
			end

			if not data.OwnedTitanTrials then data.OwnedTitanTrials = {} end
			table.insert(data.OwnedTitanTrials, {
				titan = itemId,
				expiresAt = os.time() + duration * 60,
			})

			fireRemote("PurchaseResult", player, {
				success = true,
				category = "TitanRental",
				itemId = itemId,
				duration = duration,
			})

			PlayerManager.UpdateClient(player)
		end
	end)
end

-- === ROBUX SHOP VALIDATION ===
local validatePurchase = remotes and remotes:FindFirstChild("ValidatePurchase")
if validatePurchase and validatePurchase:IsA("RemoteFunction") then
	validatePurchase.OnServerInvoke = function(player, category, itemId)
		if category == "StarterPack" then
			local pack = ShopDefs.StarterPacks and ShopDefs.StarterPacks[itemId]
			if pack then
				return {valid = true, productId = pack.robuxCost, name = pack.name}
			end
		elseif category == "TitanRental" then
			local titan = ShopDefs.TitanRentals and ShopDefs.TitanRentals[itemId]
			if titan then
				return {valid = true, prices = titan.prices, name = titan.name}
			end
		end
		return {valid = false}
	end
end

-- === PROCESS ROBUX RECEIPT ===
local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = PlayerManager.GetData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	for packId, pack in pairs(ShopDefs.StarterPacks or {}) do
		if pack.robuxCost == receiptInfo.ProductId then
			if pack.rewards then
				if pack.rewards.xp then PlayerManager.AddXP(player, pack.rewards.xp) end
				if pack.rewards.medals then PlayerManager.AddMedals(player, pack.rewards.medals) end
				if pack.rewards.abilities then
					for _, abilityId in ipairs(pack.rewards.abilities) do
						if not data.OwnedAbilities then data.OwnedAbilities = {} end
						local alreadyOwned = false
						for _, id in ipairs(data.OwnedAbilities) do
							if id == abilityId then alreadyOwned = true break end
						end
						if not alreadyOwned then
							table.insert(data.OwnedAbilities, abilityId)
						end
					end
				end
				if pack.rewards.chests then
					for chestType, count in pairs(pack.rewards.chests) do
						PlayerManager.AddChests(player, chestType, count)
					end
				end
				if pack.rewards.boostMinutes then
					local boostSeconds = pack.rewards.boostMinutes * 60
					if not data.ActiveBoosts then data.ActiveBoosts = {} end
					data.ActiveBoosts.Speed = (data.ActiveBoosts.Speed or 0) + boostSeconds
				end
				if pack.rewards.titanTrialMinutes then
					if not data.OwnedTitanTrials then data.OwnedTitanTrials = {} end
					table.insert(data.OwnedTitanTrials, {
						id = pack.rewards.titanTrialJet or "AetherTitan",
						minutes = pack.rewards.titanTrialMinutes,
						startTime = os.time(),
					})
			end
			end

			PlayerManager.UpdateClient(player)
			PlayerManager.SaveData(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = processReceipt

print("[ShopManager] Initialized successfully")