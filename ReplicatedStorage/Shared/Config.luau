local Config = {
	-- Arena
	ARENA_RADIUS = 2400,
	ARENA_HEIGHT = 2000,
	VIP_ANNEX_RADIUS = 800,
	VIP_ANNEX_HEIGHT = 2000,
	VIP_ANNEX_OFFSET = Vector3.new(3200, 0, 0),
	BOUNDARY_PUSH_FORCE = 80,
	HOT_ZONE_RADIUS = 200,

	-- 2D Flight (arcade jet on flat plane)
	FLIGHT_ALTITUDE = 100,
	CAMERA_OFFSET = Vector3.new(0, 80, -35),
	CAMERA_LERP_SPEED = 5,
	PITCH_TILT_MAX_DEG = 15,
	ROLL_TILT_MAX_DEG = 20,
	REVERSE_THRUST_BASE = 0.5,
	YAW_RESPONSIVENESS = 8,
	ALTITUDE_SPRING = 10,

	-- Momentum & Drag (arcade feel)
	DRAG_COEFFICIENT = 2.0,
	FORWARD_THRUST_MULT = 1.0,
	REVERSE_THRUST_MULT = 0.35,
	STRAFE_THRUST_MULT = 0.7,
	BOOST_THRUST_MULTIPLIER = 2.5,
	MAX_SPEED_CAP = 300,

	-- Boundary
	BOUNDARY_WARNING_ZONE = 0.85,
	BOUNDARY_SOFT_PUSH = 200,
	BOUNDARY_HARD_PUSH = 600,

	-- Sound placeholders (replace IDs with real assets)
	THRUST_SOUND_ID = "rbxassetid://9125404536",
	BOOST_SOUND_ID = "rbxassetid://9125404536",

	-- Particle tuning
	THRUST_PARTICLE_RATE = 40,
	BOOST_PARTICLE_RATE = 100,
	STRAFE_PARTICLE_RATE = 25,

	-- Flight
	BASE_SPEED = 60,
	BASE_BOOST_SPEED = 120,
	BASE_MANEUVERABILITY = 40,
	BOOST_DRAIN_RATE = 25,
	BOOST_REFILL_RATE = 15,
	MAX_BOOST_ENERGY = 100,

	-- Stats
	STAT_NAMES = {"Damage", "FireRate", "ProjectileHealth", "Speed", "Maneuverability", "MaxHP", "Regen", "Boost"},
	STAT_PER_LEVEL = 1,
	MAX_STAT_LEVEL = 100,

	-- Stat scaling multipliers per point
	STAT_SCALE = {
		Damage = 1.08,
		FireRate = 1.06,
		ProjectileHealth = 1.07,
		Speed = 1.04,
		Maneuverability = 1.05,
		MaxHP = 1.06,
		Regen = 1.08,
		Boost = 1.05,
	},

	-- Leveling
	XP_CURVE = function(level)
		return math.floor(50 * (level ^ 1.5))
	end,
	MAX_LEVEL = 130,

	-- Blobs
	BLOB_XP = {small = 5, medium = 15, large = 40},
	BLOB_SPAWN_INTERVAL = 2,
	BLOB_MAX_MAIN = 200,
	BLOB_MAX_HOTZONE = 80,
	BLOB_MAX_VIP = 150,

	-- Bosses
	BOSS_SPAWN_INTERVAL = 180,
	BOSS_HP_BASE = 5000,
	BOSS_HP_SCALE = 500,
	MINI_BOSS_SPAWN_INTERVAL = 90,
	MINI_BOSS_HP = 2000,

	-- Projectiles
	PROJECTILE_SPEED = 200,
	PROJECTILE_LIFETIME = 3,
	PROJECTILE_BASE_DAMAGE = 10,
	PROJECTILE_BASE_HEALTH = 1,
	FIRE_RATE_BASE = 0.3,

	-- Rewards
	INTERVAL_REWARDS = {
		{time = 60, xp = 50, medals = 5},
		{time = 150, xp = 100, medals = 10},
		{time = 300, xp = 150, medals = 15}, -- then every 300s
	},
	INTERVAL_RECUR = 300,

	KILL_XP = 100,
	KILL_MEDALS = 10,
	KILL_RANK_XP = 25,
	BOSS_DAMAGE_RANK_XP = 0.5,

	-- Death
	KEEP_LEVEL_MEDAL_COST = 500,
	KEEP_LEVEL_ROBUX_COST = 25,
	MAX_AD_REVIVALS = 4,

	-- Boosts
	BOOST_DURATION = 1800, -- 30 min in seconds
	BOOST_COUNTDOWN_ONLY_IN_ARENA = true,

	-- VIP
	VIP_BLOB_MULTIPLIER = 5,
	VIP_XP_MULTIPLIER = 1.8,
	VIP_MEDAL_MULTIPLIER = 1.8,
	VIP_TITAN_TRIAL_MINUTES = 2.5,

	-- Lobby
	LOBBY_TAXI_SPEED = 80,
	LOBBY_JUMP_POWER = 50,
	LOBBY_RADIUS = 500,

	-- Arena player caps
	ARENA_NORMAL_MAX = 10,
	ARENA_MEGA_MAX = 50,
	ARENA_PVP_MAX = 25,

	-- Prize Wheel
	WHEEL_FREE_SPINS_DAILY = 1,
	WHEEL_COST_ROBUX = 50,

	-- Auto-save
	AUTOSAVE_INTERVAL = 120,

	-- Daily Login Streaks
	LOGIN_STREAK_MAX = 7,
	LOGIN_STREAK_GRACE_HOURS = 36,
	LOGIN_STREAK_REWARDS = {
		[1] = {medals = 50, xp = 200},
		[2] = {medals = 100, xp = 500},
		[3] = {medals = 150, xp = 800, chests = {Common = 1}},
		[4] = {medals = 200, xp = 1200},
		[5] = {medals = 300, xp = 1800, chests = {Rare = 1}},
		[6] = {medals = 400, xp = 2500, boostMinutes = 30},
		[7] = {medals = 1000, xp = 5000, chests = {Epic = 1, Rare = 2}, boostMinutes = 60},
	},

	-- Incremental Playtime Rewards (lobby + arena)
	PLAYTIME_REWARDS = {
		{time = 30, xp = 25, medals = 3},
		{time = 150, xp = 75, medals = 8},
		{time = 300, xp = 150, medals = 15},
		{time = 600, xp = 250, medals = 25},
		{time = 900, xp = 400, medals = 40},
	},
	PLAYTIME_RECUR = 300,

	-- Rank Up Rewards
	RANK_UP_REWARDS = {
		medals = 100,
		xp = 500,
	},
}

return Config