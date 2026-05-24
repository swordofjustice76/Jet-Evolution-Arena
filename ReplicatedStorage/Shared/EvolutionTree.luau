local EvolutionTree = {
	-- Level 1 starter
	Starter = {
		name = "Starter",
		level = 1,
		parent = nil,
		movementStyle = "Standard",
		visualScale = 1.0,
		projectileCount = 1,
		description = "Basic jet. Forward flight only.",
		children = {"Scout", "Tank"},
	},

	-- Level 15 branch
	Scout = {
		name = "Scout",
		level = 15,
		parent = "Starter",
		movementStyle = "Strafe",
		visualScale = 1.1,
		projectileCount = 1,
		description = "Fast & agile. Unlocks strafe movement.",
		children = {"Interceptor", "Phantom"},
	},
	Tank = {
		name = "Tank",
		level = 15,
		parent = "Starter",
		movementStyle = "Standard",
		visualScale = 1.3,
		projectileCount = 2,
		description = "Heavy & durable. Dual cannons.",
		children = {"Fortress", "Juggernaut"},
	},

	-- Level 30 branch
	Interceptor = {
		name = "Interceptor",
		level = 30,
		parent = "Scout",
		movementStyle = "Strafe",
		visualScale = 1.2,
		projectileCount = 2,
		description = "Speed demon. Dual strafe cannons.",
		children = {"Wraith", "Striker"},
	},
	Phantom = {
		name = "Phantom",
		level = 30,
		parent = "Scout",
		movementStyle = "Reverse",
		visualScale = 1.15,
		projectileCount = 1,
		description = "Reverse thrust. Fly backward.",
		children = {"Spectre"},
	},
	Fortress = {
		name = "Fortress",
		level = 30,
		parent = "Tank",
		movementStyle = "Standard",
		visualScale = 1.5,
		projectileCount = 3,
		description = "Mobile fortress. Triple cannons.",
		children = {"Citadel", "Leviathan"},
	},
	Juggernaut = {
		name = "Juggernaut",
		level = 30,
		parent = "Tank",
		movementStyle = "Strafe",
		visualScale = 1.4,
		projectileCount = 2,
		description = "Heavy strafe tank. Armored agility.",
		children = {"Colossus"},
	},

	-- Level 45 branch
	Wraith = {
		name = "Wraith",
		level = 45,
		parent = "Interceptor",
		movementStyle = "Hydra",
		visualScale = 1.3,
		projectileCount = 3,
		description = "Full lateral freedom. Triple shot.",
		children = {"Nemesis", "Eclipse"},
	},
	Striker = {
		name = "Striker",
		level = 45,
		parent = "Interceptor",
		movementStyle = "Strafe",
		visualScale = 1.25,
		projectileCount = 3,
		description = "Precision strafe. Rapid triple fire.",
		children = {"Vanguard"},
	},
	Spectre = {
		name = "Spectre",
		level = 45,
		parent = "Phantom",
		movementStyle = "Reverse",
		visualScale = 1.2,
		projectileCount = 2,
		description = "Ghost reverse. Dual rear cannons.",
		children = {},
	},
	Citadel = {
		name = "Citadel",
		level = 45,
		parent = "Fortress",
		movementStyle = "Standard",
		visualScale = 1.7,
		projectileCount = 4,
		description = "Flying citadel. Quad cannons.",
		children = {"Leviathan"},
	},
	Leviathan = {
		name = "Leviathan",
		level = 45,
		parent = "Fortress",
		movementStyle = "Reverse",
		visualScale = 1.8,
		projectileCount = 3,
		description = "Reverse leviathan. Massive bulk.",
		children = {},
	},
	Colossus = {
		name = "Colossus",
		level = 45,
		parent = "Juggernaut",
		movementStyle = "Hydra",
		visualScale = 1.6,
		projectileCount = 3,
		description = "Hydra colossus. Omni-directional.",
		children = {},
	},

	-- Level 60 branch
	Nemesis = {
		name = "Nemesis",
		level = 60,
		parent = "Wraith",
		movementStyle = "Hydra",
		visualScale = 1.5,
		projectileCount = 4,
		description = "Ultimate hunter. Quad hydra cannons.",
		children = {"Apex"},
	},
	Eclipse = {
		name = "Eclipse",
		level = 60,
		parent = "Wraith",
		movementStyle = "Reverse",
		visualScale = 1.4,
		projectileCount = 3,
		description = "Shadow reverse. Dark matter guns.",
		children = {"Apex"},
	},
	Vanguard = {
		name = "Vanguard",
		level = 60,
		parent = "Striker",
		movementStyle = "Strafe",
		visualScale = 1.35,
		projectileCount = 4,
		description = "Elite vanguard. Quad strafe.",
		children = {"Apex"},
	},

	-- Level 80
	Apex = {
		name = "Apex",
		level = 80,
		parent = "Nemesis",
		movementStyle = "Hydra",
		visualScale = 1.7,
		projectileCount = 5,
		description = "Apex predator. Penta hydra.",
		children = {"TitanX"},
	},

	-- Level 105
	TitanX = {
		name = "TitanX",
		level = 105,
		parent = "Apex",
		movementStyle = "Hydra",
		visualScale = 2.0,
		projectileCount = 6,
		description = "Titan-class evolution. Six hydra cannons.",
		children = {"Omega"},
	},

	-- Level 130
	Omega = {
		name = "Omega",
		level = 130,
		parent = "TitanX",
		movementStyle = "Hydra",
		visualScale = 2.5,
		projectileCount = 8,
		description = "Final form. Omega devastation.",
		children = {},
	},

	-- Titan Jets (rental only)
	AetherTitan = {
		name = "AetherTitan",
		level = 1,
		parent = nil,
		movementStyle = "Hydra",
		visualScale = 3.0,
		projectileCount = 6,
		description = "Aether Titan. Rental only.",
		children = {},
		isTitan = true,
	},
	VoidTitan = {
		name = "VoidTitan",
		level = 1,
		parent = nil,
		movementStyle = "Hydra",
		visualScale = 3.2,
		projectileCount = 7,
		description = "Void Titan. Rental only.",
		children = {},
		isTitan = true,
	},
	StormTitan = {
		name = "StormTitan",
		level = 1,
		parent = nil,
		movementStyle = "Hydra",
		visualScale = 3.1,
		projectileCount = 7,
		description = "Storm Titan. Rental only.",
		children = {},
		isTitan = true,
	},
	EternalTitan = {
		name = "EternalTitan",
		level = 1,
		parent = nil,
		movementStyle = "Hydra",
		visualScale = 3.5,
		projectileCount = 8,
		description = "Eternal Titan. Rental only.",
		children = {},
		isTitan = true,
	},
}

function EvolutionTree.GetAvailable(playerLevel, currentEvo)
	local current = EvolutionTree[currentEvo]
	if not current then return {} end
	local available = {}
	for _, childName in ipairs(current.children) do
		local child = EvolutionTree[childName]
		if child and playerLevel >= child.level then
			table.insert(available, childName)
		end
	end
	return available
end

function EvolutionTree.GetMovementStyle(evoName)
	local evo = EvolutionTree[evoName]
	return evo and evo.movementStyle or "Standard"
end

function EvolutionTree.GetVisualScale(evoName)
	local evo = EvolutionTree[evoName]
	return evo and evo.visualScale or 1.0
end

function EvolutionTree.GetProjectileCount(evoName)
	local evo = EvolutionTree[evoName]
	return evo and evo.projectileCount or 1
end

return EvolutionTree