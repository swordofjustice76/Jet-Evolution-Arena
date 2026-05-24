local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local EvolutionTree = require(ReplicatedStorage.Shared.EvolutionTree)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FlightController = {}

-- ═══════════════════════════════════════════════════════════
-- TUNING VARIABLES (adjust these for feel)
-- ═══════════════════════════════════════════════════════════
local FORWARD_THRUST_MULT = Config.FORWARD_THRUST_MULT
local REVERSE_THRUST_MULT = Config.REVERSE_THRUST_MULT
local STRAFE_THRUST_MULT = Config.STRAFE_THRUST_MULT
local BOOST_THRUST_MULTIPLIER = Config.BOOST_THRUST_MULTIPLIER
local DRAG_COEFFICIENT = Config.DRAG_COEFFICIENT
local MAX_SPEED_CAP = Config.MAX_SPEED_CAP
local BOUNDARY_WARNING_ZONE = Config.BOUNDARY_WARNING_ZONE
local BOUNDARY_SOFT_PUSH = Config.BOUNDARY_SOFT_PUSH
local BOUNDARY_HARD_PUSH = Config.BOUNDARY_HARD_PUSH
local CAMERA_LERP_SPEED = Config.CAMERA_LERP_SPEED

-- ═══════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════
local isFlying = false
local inArena = false
local throttle = 0       -- -1 to 1
local strafeInput = 0   -- -1 to 1
local isBoosting = false
local boostEnergy = Config.MAX_BOOST_ENERGY
local currentEvolution = "Starter"
local movementStyle = "Standard"

-- Player stats (synced from server via UpdateClient)
local playerStats = {
	Speed = 0,
	Maneuverability = 0,
	Boost = 0,
}

-- Flight altitude (locked Y — the 2D plane)
local flightAltitude = Config.FLIGHT_ALTITUDE

-- Constraints
local alignOrientation = nil
local hrpAttachment = nil

-- Input tracking
local keysHeld = {}

-- Smoothed yaw (radians, 0 = +Z direction)
local currentYaw = 0

-- Momentum: persistent velocity vector for arcade inertia
local velocity = Vector3.new(0, 0, 0)

-- Visual / Audio references
local thrustSound = nil
local boostSound = nil
local engineAttachment = nil
local thrustParticles = nil
local boostParticles = nil
local leftStrafeAttachment = nil
local rightStrafeAttachment = nil
local leftStrafeParticles = nil
local rightStrafeParticles = nil

-- ═══════════════════════════════════════════════════════════
-- EXPOSED GETTERS
-- ═══════════════════════════════════════════════════════════
function FlightController.GetBoostEnergy()
	return boostEnergy
end

function FlightController.GetMaxBoostEnergy()
	return Config.MAX_BOOST_ENERGY
end

function FlightController.GetThrottle()
	return throttle
end

function FlightController.GetStrafeInput()
	return strafeInput
end

function FlightController.GetMovementStyle()
	return movementStyle
end

function FlightController.SetEvolution(evoName)
	currentEvolution = evoName
	movementStyle = EvolutionTree.GetMovementStyle(evoName)
end

function FlightController.SetInArena(val)
	inArena = val
	player:SetAttribute("InArena", val)
end

function FlightController.IsInArena()
	return inArena
end

function FlightController.UpdateStats(stats)
	if stats then
		for key, value in pairs(stats) do
			if playerStats[key] ~= nil then
				playerStats[key] = value
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════
-- STAT SCALING
-- ═══════════════════════════════════════════════════════════
local function getStatValue(baseValue, statName, statPoints)
	local scale = Config.STAT_SCALE[statName] or 1.0
	return baseValue * (scale ^ (statPoints or 0))
end

-- ═══════════════════════════════════════════════════════════
-- VISUAL & AUDIO SETUP
-- ═══════════════════════════════════════════════════════════
local function createEffects(hrp)
	-- Engine attachment (behind the jet)
	engineAttachment = Instance.new("Attachment")
	engineAttachment.Name = "EngineAttachment"
	engineAttachment.Position = Vector3.new(0, 0, 5)
	engineAttachment.Parent = hrp

	-- Thrust particles (normal flight)
	thrustParticles = Instance.new("ParticleEmitter")
	thrustParticles.Name = "ThrustParticles"
	thrustParticles.Rate = 0
	thrustParticles.Speed = NumberRange.new(15, 40)
	thrustParticles.Lifetime = NumberRange.new(0.3, 0.8)
	thrustParticles.SpreadAngle = Vector2.new(20, 20)
	thrustParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 0.6, 0.2)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 0.2, 0)),
	})
	thrustParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	thrustParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	thrustParticles.LightEmission = 0.8
	thrustParticles.LightInfluence = 0
	thrustParticles.Parent = engineAttachment

	-- Boost particles (stronger, blue-shifted)
	boostParticles = Instance.new("ParticleEmitter")
	boostParticles.Name = "BoostParticles"
	boostParticles.Rate = 0
	boostParticles.Speed = NumberRange.new(30, 80)
	boostParticles.Lifetime = NumberRange.new(0.4, 1.2)
	boostParticles.SpreadAngle = Vector2.new(15, 15)
	boostParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.4, 0.7, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.2, 0.4, 1)),
	})
	boostParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	boostParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	boostParticles.LightEmission = 1
	boostParticles.LightInfluence = 0
	boostParticles.Parent = engineAttachment

	-- Strafe attachments (left and right sides)
	leftStrafeAttachment = Instance.new("Attachment")
	leftStrafeAttachment.Name = "LeftStrafeAttachment"
	leftStrafeAttachment.Position = Vector3.new(-3, 0, 0)
	leftStrafeAttachment.Parent = hrp

	rightStrafeAttachment = Instance.new("Attachment")
	rightStrafeAttachment.Name = "RightStrafeAttachment"
	rightStrafeAttachment.Position = Vector3.new(3, 0, 0)
	rightStrafeAttachment.Parent = hrp

	local strafeColorSeq = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 0.8, 0.4)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 0.4, 0.1)),
	})
	local strafeSizeSeq = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	local strafeTransSeq = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})

	leftStrafeParticles = Instance.new("ParticleEmitter")
	leftStrafeParticles.Name = "StrafeParticles"
	leftStrafeParticles.Rate = 0
	leftStrafeParticles.Speed = NumberRange.new(10, 25)
	leftStrafeParticles.Lifetime = NumberRange.new(0.2, 0.5)
	leftStrafeParticles.SpreadAngle = Vector2.new(30, 30)
	leftStrafeParticles.Color = strafeColorSeq
	leftStrafeParticles.Size = strafeSizeSeq
	leftStrafeParticles.Transparency = strafeTransSeq
	leftStrafeParticles.LightEmission = 0.5
	leftStrafeParticles.Parent = leftStrafeAttachment

	rightStrafeParticles = Instance.new("ParticleEmitter")
	rightStrafeParticles.Name = "StrafeParticles"
	rightStrafeParticles.Rate = 0
	rightStrafeParticles.Speed = NumberRange.new(10, 25)
	rightStrafeParticles.Lifetime = NumberRange.new(0.2, 0.5)
	rightStrafeParticles.SpreadAngle = Vector2.new(30, 30)
	rightStrafeParticles.Color = strafeColorSeq
	rightStrafeParticles.Size = strafeSizeSeq
	rightStrafeParticles.Transparency = strafeTransSeq
	rightStrafeParticles.LightEmission = 0.5
	rightStrafeParticles.Parent = rightStrafeAttachment

	-- Thrust sound (looping engine hum)
	thrustSound = Instance.new("Sound")
	thrustSound.Name = "ThrustSound"
	thrustSound.SoundId = Config.THRUST_SOUND_ID
	thrustSound.Looped = true
	thrustSound.Volume = 0
	thrustSound.PlaybackSpeed = 0.8
	thrustSound.Parent = hrp
	thrustSound:Play()

	-- Boost sound (overlay, higher pitch)
	boostSound = Instance.new("Sound")
	boostSound.Name = "BoostSound"
	boostSound.SoundId = Config.BOOST_SOUND_ID
	boostSound.Looped = true
	boostSound.Volume = 0
	boostSound.PlaybackSpeed = 1.4
	boostSound.Parent = hrp
	boostSound:Play()
end

local function destroyEffects()
	if thrustSound then thrustSound:Stop() thrustSound:Destroy() thrustSound = nil end
	if boostSound then boostSound:Stop() boostSound:Destroy() boostSound = nil end
	if engineAttachment then engineAttachment:Destroy() engineAttachment = nil end
	if leftStrafeAttachment then leftStrafeAttachment:Destroy() leftStrafeAttachment = nil end
	if rightStrafeAttachment then rightStrafeAttachment:Destroy() rightStrafeAttachment = nil end
	-- ParticleEmitters are destroyed with their parent attachments
	thrustParticles = nil
	boostParticles = nil
	leftStrafeParticles = nil
	rightStrafeParticles = nil
end

-- ═══════════════════════════════════════════════════════════
-- ENABLE / DISABLE
-- ═══════════════════════════════════════════════════════════
function FlightController.Enable(character)
	if isFlying then return end
	isFlying = true

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Kill default humanoid movement
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Snap to flight altitude on the 2D plane
	local pos = hrp.Position
	hrp.CFrame = CFrame.new(pos.X, flightAltitude, pos.Z)

	-- Reset momentum
	velocity = Vector3.new(0, 0, 0)

	-- Attachment for AlignOrientation
	hrpAttachment = Instance.new("Attachment")
	hrpAttachment.Name = "FlightAttachment"
	hrpAttachment.Parent = hrp

	-- AlignOrientation smoothly rotates the jet toward the mouse aim direction
	alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Attachment0 = hrpAttachment
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxTorque = 100000
	alignOrientation.Responsiveness = Config.YAW_RESPONSIVENESS * 10
	alignOrientation.CFrame = hrp.CFrame.Rotation
	alignOrientation.Parent = hrp

	-- Seed yaw from current facing
	local look = hrp.CFrame.LookVector
	currentYaw = math.atan2(look.X, look.Z)

	-- Create visual/audio effects
	createEffects(hrp)

	-- Camera: fixed top-down angle, script-controlled
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 0.5
	player.CameraMinZoomDistance = 0.5
end

function FlightController.Disable()
	local wasFlying = isFlying
	isFlying = false
	velocity = Vector3.new(0, 0, 0)

	-- Clean up constraints
	if alignOrientation then alignOrientation:Destroy() alignOrientation = nil end
	if hrpAttachment then hrpAttachment:Destroy() hrpAttachment = nil end

	-- Clean up effects
	destroyEffects()

	-- Always restore lobby movement, even if isFlying was already false
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.LOBBY_TAXI_SPEED
			humanoid.JumpPower = Config.LOBBY_JUMP_POWER
		end

		-- Zero out velocity so character doesn't drift
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end

	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 128
	player.CameraMinZoomDistance = 0.5
end

function FlightController.SetLobbyMode(character)
	if isFlying then
		FlightController.Disable()
	end

	-- Always force lobby movement settings
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.LOBBY_TAXI_SPEED
			humanoid.JumpPower = Config.LOBBY_JUMP_POWER
		end
	else
		-- Character might be respawning, try again shortly
		task.delay(0.5, function()
			local char = player.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Config.LOBBY_TAXI_SPEED
					humanoid.JumpPower = Config.LOBBY_JUMP_POWER
				end
			end
		end)
	end

	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 128
	player.CameraMinZoomDistance = 0.5
end

-- ═══════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ═══════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not inArena then return end

	keysHeld[input.KeyCode] = true

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isBoosting = true
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	keysHeld[input.KeyCode] = nil

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isBoosting = false
	end
end)

-- ═══════════════════════════════════════════════════════════
-- MOUSE → WORLD (project onto flight plane)
-- ═══════════════════════════════════════════════════════════
local function getMouseWorldPosition()
	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local origin = ray.Origin
	local direction = ray.Direction

	-- Ray-plane intersection at Y = flightAltitude
	if math.abs(direction.Y) < 0.001 then
		return nil
	end

	local t = (flightAltitude - origin.Y) / direction.Y
	if t < 0 then
		return nil
	end

	return origin + direction * t
end

-- ═══════════════════════════════════════════════════════════
-- ANGLE HELPERS
-- ═══════════════════════════════════════════════════════════
local function normalizeAngle(a)
	while a > math.pi do a = a - 2 * math.pi end
	while a < -math.pi do a = a + 2 * math.pi end
	return a
end

-- ═══════════════════════════════════════════════════════════
-- PHYSICS LOOP (every frame)
-- ═══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)
	if not isFlying or not inArena then return end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- ── MOUSE AIMING (yaw on the 2D plane) ──
	local mouseWorldPos = getMouseWorldPosition()
	if mouseWorldPos then
		local toMouse = mouseWorldPos - hrp.Position
		local flat = Vector3.new(toMouse.X, 0, toMouse.Z)

		if flat.Magnitude > 2 then
			local targetYaw = math.atan2(flat.X, flat.Z)
			local yawDiff = normalizeAngle(targetYaw - currentYaw)

			-- Maneuverability stat makes turning snappier
			local yawSpeed = getStatValue(Config.YAW_RESPONSIVENESS, "Maneuverability", playerStats.Maneuverability)
			currentYaw = currentYaw + yawDiff * math.min(1, yawSpeed * dt)
		end
	end

	-- ── THROTTLE (W / S) ──
	throttle = 0
	if keysHeld[Enum.KeyCode.W] then
		throttle = 1
	elseif keysHeld[Enum.KeyCode.S] then
		if movementStyle == "Reverse" or movementStyle == "Hydra" then
			local reversePower = getStatValue(Config.REVERSE_THRUST_BASE, "Boost", playerStats.Boost)
			throttle = -math.clamp(reversePower, 0.3, 1.0)
		else
			throttle = -REVERSE_THRUST_MULT
		end
	end

	-- ── STRAFE (A / D) — nose stays independent ──
	strafeInput = 0
	if keysHeld[Enum.KeyCode.A] then
		if movementStyle == "Strafe" or movementStyle == "Hydra" then
			strafeInput = -1
		else
			strafeInput = -STRAFE_THRUST_MULT
		end
	end
	if keysHeld[Enum.KeyCode.D] then
		if movementStyle == "Strafe" or movementStyle == "Hydra" then
			strafeInput = 1
		else
			strafeInput = STRAFE_THRUST_MULT
		end
	end

	-- ── STAT-SCALED FORCES ──
	local baseSpeed = getStatValue(Config.BASE_SPEED, "Speed", playerStats.Speed)
	local maneuverability = getStatValue(Config.BASE_MANEUVERABILITY, "Maneuverability", playerStats.Maneuverability)

	-- ── BOOST (Left Shift + energy bar) ──
	if isBoosting and boostEnergy > 0 then
		boostEnergy = math.max(0, boostEnergy - Config.BOOST_DRAIN_RATE * dt)
	elseif not isBoosting then
		local refillRate = getStatValue(Config.BOOST_REFILL_RATE, "Boost", playerStats.Boost)
		boostEnergy = math.min(Config.MAX_BOOST_ENERGY, boostEnergy + refillRate * dt)
	end

	local activeBoost = isBoosting and boostEnergy > 0
	local thrustPower = baseSpeed * FORWARD_THRUST_MULT
	local strafePower = maneuverability * STRAFE_THRUST_MULT

	if activeBoost then
		thrustPower = thrustPower * BOOST_THRUST_MULTIPLIER
		strafePower = strafePower * BOOST_THRUST_MULTIPLIER
	end

	-- ── MOMENTUM-BASED PHYSICS ──
	-- Forward / backward along jet nose on XZ
	local forwardDir = Vector3.new(math.sin(currentYaw), 0, math.cos(currentYaw))
	-- Right perpendicular (nose-independent strafe)
	local rightDir = Vector3.new(math.cos(currentYaw), 0, -math.sin(currentYaw))

	-- Apply thrust as acceleration (force → velocity change)
	local thrustAccel = forwardDir * throttle * thrustPower
	local strafeAccel = rightDir * strafeInput * strafePower
	local totalAccel = thrustAccel + strafeAccel

	-- Integrate acceleration into velocity
	velocity = velocity + totalAccel * dt

	-- Apply drag (exponential decay for smooth arcade feel)
	local dragFactor = math.exp(-DRAG_COEFFICIENT * dt)
	velocity = velocity * dragFactor

	-- ── ANTI-EXPLOIT: Speed clamping ──
	local speed = velocity.Magnitude
	local currentMaxSpeed = activeBoost
		and getStatValue(Config.BASE_BOOST_SPEED, "Boost", playerStats.Boost) * 2
		or baseSpeed * 2.5

	-- Hard cap (absolute maximum, catches any exploit)
	if speed > MAX_SPEED_CAP then
		velocity = velocity.Unit * MAX_SPEED_CAP
	elseif speed > currentMaxSpeed then
		-- Soft cap (normal gameplay limit)
		velocity = velocity.Unit * currentMaxSpeed
	end

	-- ── BOUNDARY ENFORCEMENT (client-side soft push) ──
	local flatPos = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
	local distFromCenter = flatPos.Magnitude
	local arenaRadius = Config.ARENA_RADIUS
	local warningDist = arenaRadius * BOUNDARY_WARNING_ZONE

	if distFromCenter > warningDist then
		local overFactor = math.clamp((distFromCenter - warningDist) / (arenaRadius - warningDist), 0, 1)
		local pushDir = (Vector3.new(0, 0, 0) - flatPos).Unit

		-- Soft push ramps up as you get closer to the edge
		local pushForce = BOUNDARY_SOFT_PUSH * overFactor * overFactor
		velocity = velocity + pushDir * pushForce * dt

		-- Hard push if past the boundary
		if distFromCenter > arenaRadius then
			velocity = velocity + pushDir * BOUNDARY_HARD_PUSH * dt
		end
	end

	-- ── ALTITUDE LOCK (spring-correct Y toward flight plane) ──
	local altError = flightAltitude - hrp.Position.Y
	local yVel = altError * Config.ALTITUDE_SPRING

	-- Compose final 3D velocity (XZ momentum + Y spring)
	local finalVelocity = Vector3.new(velocity.X, yVel, velocity.Z)

	-- Apply to physics
	hrp.AssemblyLinearVelocity = finalVelocity

	-- ── ROTATION (AlignOrientation + visual tilt) ──
	if alignOrientation then
		local pitchRad = throttle * math.rad(Config.PITCH_TILT_MAX_DEG)
		local rollRad = -strafeInput * math.rad(Config.ROLL_TILT_MAX_DEG)

		local baseCF = CFrame.Angles(0, currentYaw, 0)
		local tiltCF = CFrame.Angles(pitchRad, 0, rollRad)

		alignOrientation.CFrame = baseCF * tiltCF
	end

	-- ── VISUAL EFFECTS UPDATE ──
	-- Thrust particles
	if thrustParticles then
		local absThrottle = math.abs(throttle)
		thrustParticles.Rate = absThrottle * Config.THRUST_PARTICLE_RATE
	end

	-- Boost particles
	if boostParticles then
		boostParticles.Rate = activeBoost and Config.BOOST_PARTICLE_RATE or 0
	end

	-- Strafe particles
	if leftStrafeParticles then
		leftStrafeParticles.Rate = (strafeInput > 0.1) and Config.STRAFE_PARTICLE_RATE or 0
	end
	if rightStrafeParticles then
		rightStrafeParticles.Rate = (strafeInput < -0.1) and Config.STRAFE_PARTICLE_RATE or 0
	end

	-- Thrust sound (volume & pitch scale with throttle)
	if thrustSound then
		local absThrottle = math.abs(throttle)
		local targetVol = absThrottle * 0.6
		local targetPitch = 0.8 + absThrottle * 0.6
		thrustSound.Volume = math.min(thrustSound.Volume + (targetVol - thrustSound.Volume) * 5 * dt, 1)
		thrustSound.PlaybackSpeed = math.min(
			thrustSound.PlaybackSpeed + (targetPitch - thrustSound.PlaybackSpeed) * 5 * dt, 2
		)
	end

	-- Boost sound (fade in/out)
	if boostSound then
		local targetVol = activeBoost and 0.5 or 0
		boostSound.Volume = math.min(boostSound.Volume + (targetVol - boostSound.Volume) * 8 * dt, 1)
	end

	-- ── CAMERA (smooth lerp top-down) ──
	local camOffset = Config.CAMERA_OFFSET
	local desiredCamPos = hrp.Position + camOffset
	local currentCamPos = camera.CFrame.Position
	local lerpAlpha = 1 - math.exp(-CAMERA_LERP_SPEED * dt)
	local newCamPos = currentCamPos:Lerp(desiredCamPos, lerpAlpha)
	camera.CFrame = CFrame.new(newCamPos, hrp.Position)

	-- ── PUBLISH STATE FOR HUD / SERVER ──
	character:SetAttribute("BoostEnergy", boostEnergy)
	character:SetAttribute("Throttle", throttle)
	character:SetAttribute("StrafeInput", strafeInput)
	character:SetAttribute("MovementStyle", movementStyle)
	character:SetAttribute("Speed", speed)
end)

-- ═══════════════════════════════════════════════════════════
-- ARENA JOIN / LEAVE
-- ═══════════════════════════════════════════════════════════
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local joinArena = remotes:WaitForChild("JoinArena")
	joinArena.OnClientEvent:Connect(function(arenaType)
		inArena = true
		player:SetAttribute("InArena", true)
		local character = player.Character or player.CharacterAdded:Wait()
		FlightController.Enable(character)
	end)

	local leaveArena = remotes:WaitForChild("LeaveArena")
	leaveArena.OnClientEvent:Connect(function()
		inArena = false
		player:SetAttribute("InArena", false)
		FlightController.Disable()
	end)
end

-- ═══════════════════════════════════════════════════════════
-- STAT SYNC (from server)
-- ═══════════════════════════════════════════════════════════
if remotes then
	local updateClient = remotes:WaitForChild("UpdateClient")
	updateClient.OnClientEvent:Connect(function(data)
		if data.Stats then
			FlightController.UpdateStats(data.Stats)
		end
		if data.CurrentEvolution then
			FlightController.SetEvolution(data.CurrentEvolution)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- RESPAWN
-- ═══════════════════════════════════════════════════════════
player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	if inArena then
		FlightController.Enable(character)
	else
		FlightController.SetLobbyMode(character)
	end
end)

return FlightController