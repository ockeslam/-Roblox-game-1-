-- All the numbers you might want to tweak live here.
local Config = {
	Seed = 1337, -- change this to get a different map layout

	Surface = 80, -- height of the water surface (studs)
	Half = 200, -- lagoon is Half*2 studs wide

	-- Sharks
	SharkCount = 4,
	SharkPatrolSpeed = 9,
	SharkChaseSpeed = 14, -- players swim at 16, so you can just about outswim them
	SharkAggroRange = 45,
	SharkBiteRange = 8,
	SharkBiteDamage = 20,
	SharkBiteCooldown = 2.5,

	-- Oxygen
	OxygenSeconds = 60, -- how long you can stay under
	OxygenRefillPerSecond = 35,
	DrownDamagePerSecond = 10,

	-- Pearls
	ClamCount = 25,
	PearlRespawn = 30,

	-- Reef
	ReefCount = 6,
	KelpForests = 4,
}

-- Reef positions come from the seed so server and client agree on them.
function Config.reefCenters()
	local rng = Random.new(Config.Seed)
	local centers = { Vector3.new(10, 0, 10) } -- one reef right under the raft
	for i = 1, Config.ReefCount do
		local angle = (i / Config.ReefCount) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local r = rng:NextNumber(55, Config.Half - 50)
		table.insert(centers, Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r))
	end
	return centers
end

return Config
