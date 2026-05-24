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

-- ═══════════════════════════════════════════════════════════
-- TUNING
-- ═══════════════════════════════════════════════════════════
local SOFT_PUSH_FORCE = Config.BOUNDARY_SOFT_PUSH or 200
local HARD_PUSH_FORCE = Config.BOUNDARY_HARD_PUSH or 600
local WARNING_ZONE = Config.BOUNDARY_WARNING_ZONE or 0.85
local MAX_SPEED_CAP = Config.MAX_SPEED_CAP or 300

-- ═══════════════════════════════════════════════════════════
-- BOUNDARY ENFORCEMENT (server-authoritative)
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(0.1) -- 10Hz for responsive boundary
		for _, player in Players:GetPlayers() do
			if not player.Parent then continue end
			local data = PlayerManager.GetData(player)
			if not data then continue end

			local character = player.Character
			if not character then continue end

			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			if data.InArena then
				-- ── ARENA BOUNDARY (cylindrical, soft push) ──
				local arenaRadius = Config.ARENA_RADIUS or 200
				local flatPos = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
				local distFromCenter = flatPos.Magnitude
				local warningDist = arenaRadius * WARNING_ZONE

				if distFromCenter > warningDist then
					local overFactor = math.clamp((distFromCenter - warningDist) / (arenaRadius - warningDist), 0, 1)
					local pushDir = (Vector3.new(0, 0, 0) - flatPos).Unit

					-- Soft push: ramps up quadratically as you approach the edge
					local pushForce = SOFT_PUSH_FORCE * overFactor * overFactor
					local currentVel = hrp.AssemblyLinearVelocity
					hrp.AssemblyLinearVelocity = currentVel + pushDir * pushForce * 0.1

					-- Hard push if past the boundary
					if distFromCenter > arenaRadius then
						hrp.AssemblyLinearVelocity = currentVel + pushDir * HARD_PUSH_FORCE * 0.1
						fireRemote("ArenaBoundary", player, {pushed = true})
					end

					-- Emergency: if way past boundary, teleport back
					if distFromCenter > arenaRadius * 1.2 then
						local safePos = flatPos.Unit * (arenaRadius * 0.8)
						hrp.CFrame = CFrame.new(safePos.X, hrp.Position.Y, safePos.Z)
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						fireRemote("ArenaBoundary", player, {teleported = true})
					end
				end

				-- ── ANTI-EXPLOIT: Speed clamping ──
				local speed = hrp.AssemblyLinearVelocity.Magnitude
				if speed > MAX_SPEED_CAP then
					hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity.Unit * MAX_SPEED_CAP
				end

				-- ── ALTITUDE ENFORCEMENT ──
				local targetAlt = Config.FLIGHT_ALTITUDE or 100
				local altDiff = math.abs(hrp.Position.Y - targetAlt)
				if altDiff > 50 then
					-- Too far from flight plane, snap back
					hrp.CFrame = CFrame.new(hrp.Position.X, targetAlt, hrp.Position.Z)
				end

			else
				-- ── LOBBY BOUNDARY ──
				local lobbyRadius = Config.LOBBY_RADIUS or 500
				local distFromCenter = (hrp.Position - Vector3.new(0, 0, 0)).Magnitude
				if distFromCenter > lobbyRadius then
					hrp.CFrame = CFrame.new(0, 10, 0)
					fireRemote("ArenaBoundary", player, {returned = true})
				end
			end
		end
	end
end)

print("[BoundaryEnforcer] Initialized successfully")