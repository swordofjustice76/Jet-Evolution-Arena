local ProjectileVisuals = {}

-- Trail colors per evolution tier
ProjectileVisuals.TrailColors = {
	Starter = Color3.fromRGB(255, 255, 255),
	Scout = Color3.fromRGB(0, 200, 255),
	Tank = Color3.fromRGB(255, 100, 50),
	Interceptor = Color3.fromRGB(0, 255, 200),
	Phantom = Color3.fromRGB(150, 0, 255),
	Fortress = Color3.fromRGB(255, 150, 0),
	Juggernaut = Color3.fromRGB(255, 50, 50),
	Wraith = Color3.fromRGB(0, 255, 150),
	Striker = Color3.fromRGB(255, 255, 0),
	Spectre = Color3.fromRGB(100, 0, 200),
	Citadel = Color3.fromRGB(255, 200, 0),
	Leviathan = Color3.fromRGB(200, 0, 100),
	Colossus = Color3.fromRGB(0, 200, 100),
	Nemesis = Color3.fromRGB(255, 0, 100),
	Eclipse = Color3.fromRGB(80, 0, 160),
	Vanguard = Color3.fromRGB(255, 200, 50),
	Apex = Color3.fromRGB(255, 50, 200),
	TitanX = Color3.fromRGB(255, 100, 0),
	Omega = Color3.fromRGB(255, 0, 0),
}

-- Titan jet colors
ProjectileVisuals.TitanColors = {
	AetherTitan = Color3.fromRGB(100, 200, 255),
	VoidTitan = Color3.fromRGB(100, 0, 200),
	StormTitan = Color3.fromRGB(0, 200, 255),
	EternalTitan = Color3.fromRGB(255, 200, 50),
}

function ProjectileVisuals.GetTrailColor(evoName)
	return ProjectileVisuals.TrailColors[evoName]
		or ProjectileVisuals.TitanColors[evoName]
		or Color3.fromRGB(255, 255, 255)
end

function ProjectileVisuals.GetProjectileSize(evoName, scale)
	local baseSize = Vector3.new(0.5, 0.5, 2)
	return baseSize * (scale or 1)
end

return ProjectileVisuals