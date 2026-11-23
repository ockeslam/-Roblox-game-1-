-- All the numbers you might want to tweak live here.
local Config = {
	Seed = 1337, -- change this to get a different map layout

	Surface = 80, -- height of the water surface (studs)
	Radius = 190, -- radius of the lagoon

	-- Oxygen
	OxygenSeconds = 60, -- how long you can stay under
	OxygenRefillPerSecond = 35,
	DrownDamagePerSecond = 10,

	-- Pearls
	ClamCount = 25,
	PearlRespawn = 30,
	PearlMoney = 10, -- each pearl is also worth this much cash

	-- Money coins dropped by creatures
	CoinLifetime = 45,
	CoinPickupRange = 8,

	-- Reef
	ReefCount = 6,
	KelpForests = 4,
}

-- Everything you can hunt. reward = total cash dropped as coins.
Config.Creatures = {
	Snapper = {
		type = "Fish",
		count = 14,
		health = 20,
		reward = 6,
		speed = 7,
		fleeSpeed = 13,
		respawn = 20,
		body = Vector3.new(0.9, 1.5, 3),
		colours = { Color3.fromRGB(230, 90, 70), Color3.fromRGB(255, 190, 160) },
	},
	Grouper = {
		type = "Fish",
		count = 8,
		health = 55,
		reward = 15,
		speed = 5,
		fleeSpeed = 10,
		respawn = 30,
		body = Vector3.new(1.6, 2.2, 4.5),
		colours = { Color3.fromRGB(120, 95, 70), Color3.fromRGB(205, 175, 125) },
	},
	Tuna = {
		type = "Fish",
		count = 6,
		health = 90,
		reward = 25,
		speed = 10,
		fleeSpeed = 15,
		respawn = 40,
		body = Vector3.new(1.4, 2, 5.5),
		colours = { Color3.fromRGB(40, 60, 120), Color3.fromRGB(200, 210, 225) },
	},
	Shark = {
		type = "Shark",
		count = 4,
		health = 220,
		reward = 75,
		respawn = 60,
		speed = 9,
		chaseSpeed = 14, -- players swim at 16, so you can just about outswim them
		aggroRange = 45,
		biteRange = 8,
		biteDamage = 20,
		biteCooldown = 2.5,
	},
	Squid = {
		type = "Squid",
		count = 1,
		health = 800,
		reward = 350,
		respawn = 180,
		speed = 6,
		stalkSpeed = 13,
		chargeSpeed = 21, -- faster than you, so you can't outswim the charge
		reach = 12,
		damage = 35,
		firstStalk = { 45, 90 }, -- seconds after spawning before it first hunts someone
		stalkGap = { 60, 120 }, -- seconds between hunts
	},
}

-- Harpoon guns, cheapest first. splash = legendary area damage radius.
Config.Harpoons = {
	{ id = "Basic", name = "Basic Harpoon", rarity = "Basic", price = 0, damage = 20, cooldown = 1.2, range = 60, speed = 110, colour = Color3.fromRGB(175, 175, 175) },
	{ id = "Uncommon", name = "Reef Harpoon", rarity = "Uncommon", price = 100, damage = 30, cooldown = 1.0, range = 70, speed = 130, colour = Color3.fromRGB(90, 210, 90) },
	{ id = "Rare", name = "Tide Harpoon", rarity = "Rare", price = 300, damage = 45, cooldown = 0.8, range = 85, speed = 150, colour = Color3.fromRGB(70, 140, 255) },
	{ id = "Epic", name = "Abyss Harpoon", rarity = "Epic", price = 800, damage = 70, cooldown = 0.6, range = 100, speed = 170, colour = Color3.fromRGB(175, 80, 255) },
	{ id = "Legendary", name = "Kraken Slayer", rarity = "Legendary", price = 2000, damage = 110, cooldown = 0.45, range = 120, speed = 200, colour = Color3.fromRGB(255, 200, 50), splash = 10 },
}

function Config.harpoon(id)
	for _, h in Config.Harpoons do
		if h.id == id then
			return h
		end
	end
	return nil
end

-- Random point on the lagoon floor plan (Y = 0), at least `margin` studs from the shore.
function Config.randomInLagoon(rng: Random, margin: number)
	local a = rng:NextNumber(0, math.pi * 2)
	local r = (Config.Radius - margin) * math.sqrt(rng:NextNumber())
	return Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

-- Pull a point back inside the lagoon if it's outside.
function Config.clampToLagoon(p: Vector3, margin: number)
	local flat = Vector3.new(p.X, 0, p.Z)
	local max = Config.Radius - margin
	if flat.Magnitude > max then
		flat = flat.Unit * max
	end
	return Vector3.new(flat.X, p.Y, flat.Z)
end

-- Reef positions come from the seed so server and client agree on them.
function Config.reefCenters()
	local rng = Random.new(Config.Seed)
	local centers = { Vector3.new(10, 0, 10) } -- one reef right under the raft
	for i = 1, Config.ReefCount do
		local angle = (i / Config.ReefCount) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local r = rng:NextNumber(55, Config.Radius - 50)
		table.insert(centers, Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r))
	end
	return centers
end

return Config
