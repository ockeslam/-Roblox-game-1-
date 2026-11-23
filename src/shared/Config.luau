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

	-- Harpoon aim assist: if you miss by less than this many degrees, the shot bends onto the target
	AimAssistDegrees = 4,

	-- Birds flying over the island
	BirdCount = 16,
}

-- Sounds. Leave "" to use the built-in placeholder sound.
-- To use a better one: in Studio open Toolbox > Creator Store > Audio, search
-- (e.g. "thunder", "heavy rain", "horror sting", "sea monster", "seagulls"),
-- right-click a sound > Copy Asset ID, and paste it here like "rbxassetid://123456".
Config.Sounds = {
	Thunder = "",
	Rain = "",
	SquidSting = "", -- plays when the squid starts hunting
	SquidDrone = "", -- loops during the storm
	Seagulls = "",
}

-- Rarity scale: 1 = Common ... 5 = Legendary.
-- Health, coins and XP all come from a creature's rarity (times its own multipliers).
Config.Rarities = {
	-- count = how many of EACH species of this rarity are alive at once
	-- respawn = seconds before a killed one comes back
	{ name = "Common", colour = Color3.fromRGB(210, 210, 210), health = 15, reward = 5, xp = 5, count = 8, respawn = 10 },
	{ name = "Uncommon", colour = Color3.fromRGB(90, 210, 90), health = 30, reward = 12, xp = 10, count = 6, respawn = 20 },
	{ name = "Rare", colour = Color3.fromRGB(70, 140, 255), health = 60, reward = 25, xp = 20, count = 4, respawn = 45 },
	{ name = "Epic", colour = Color3.fromRGB(175, 80, 255), health = 120, reward = 50, xp = 40, count = 2, respawn = 90 },
	{ name = "Legendary", colour = Color3.fromRGB(255, 200, 50), health = 300, reward = 120, xp = 100, count = 1, respawn = 240 },
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Everything you can hunt.
-- type: Fish / Crab / Jelly / Shark / Squid. How many spawn comes from rarity (see Config.Rarities).
-- speed = normal swim speed, fleeSpeed = speed when scared (players swim at 16).
-- body = fish size, colours = {main, second}. Optional looks: stripes, spots, spikes, spines, bill, sail,
-- mahi, sunfish, eel, ray, hammer, glow. bottom = lives near the seabed.
Config.Creatures = {
	---------------- Rarity 1: Common
	Sardine = { type = "Fish", rarity = 1, healthMult = 0.7, speed = 8, fleeSpeed = 15,
		body = Vector3.new(0.5, 0.8, 2.2), colours = { rgb(190, 200, 215), rgb(235, 240, 245) } },
	Snapper = { type = "Fish", rarity = 1, speed = 7, fleeSpeed = 13,
		body = Vector3.new(0.9, 1.5, 3), colours = { rgb(230, 90, 70), rgb(255, 190, 160) } },
	Mackerel = { type = "Fish", rarity = 1, speed = 9, fleeSpeed = 16,
		body = Vector3.new(0.7, 1.1, 3.2), colours = { rgb(70, 110, 140), rgb(220, 230, 240) } },
	Damselfish = { type = "Fish", rarity = 1, healthMult = 0.8, speed = 6, fleeSpeed = 13,
		body = Vector3.new(0.6, 1.2, 2), colours = { rgb(40, 90, 255), rgb(120, 200, 255) } },
	Crab = { type = "Crab", rarity = 1, size = 1, speed = 3, fleeSpeed = 7,
		colours = { rgb(220, 70, 40), rgb(240, 150, 110) } },
	Jellyfish = { type = "Jelly", rarity = 1, healthMult = 0.7, speed = 2,
		sting = 10, -- damage if you swim into one
		shootSting = 6, -- damage you take for shooting one
		stingRange = 4, stingCooldown = 1.5,
		colours = { rgb(255, 140, 220), rgb(170, 140, 255), rgb(120, 230, 255) } },

		BlueChromis = { type = "Fish", rarity = 1, speed = 6, fleeSpeed = 13,
		body = Vector3.new(0.5, 1, 1.8), colours = { rgb(60, 170, 230), rgb(150, 230, 255) } },
	Goby = { type = "Fish", rarity = 1, healthMult = 0.8, speed = 4, fleeSpeed = 10, bottom = true,
		body = Vector3.new(0.6, 0.6, 2.2), colours = { rgb(200, 180, 140), rgb(240, 225, 190) }, spots = true },

	---------------- Rarity 2: Uncommon
	Clownfish = { type = "Fish", rarity = 2, speed = 5, fleeSpeed = 12,
		body = Vector3.new(0.8, 1.2, 2.4), colours = { rgb(255, 120, 20), rgb(255, 255, 255) }, stripes = 3 },
	Parrotfish = { type = "Fish", rarity = 2, speed = 6, fleeSpeed = 12,
		body = Vector3.new(1.1, 1.8, 3.4), colours = { rgb(40, 200, 180), rgb(255, 120, 200) } },
	Butterflyfish = { type = "Fish", rarity = 2, speed = 5, fleeSpeed = 12,
		body = Vector3.new(0.45, 2.2, 2.2), colours = { rgb(255, 220, 40), rgb(255, 250, 220) }, stripes = 1, stripeColour = rgb(30, 30, 30) },
	Angelfish = { type = "Fish", rarity = 2, speed = 5, fleeSpeed = 12,
		body = Vector3.new(0.4, 2.6, 2.4), colours = { rgb(90, 110, 255), rgb(255, 220, 60) }, stripes = 2, stripeColour = rgb(255, 220, 60) },
	Pufferfish = { type = "Fish", rarity = 2, healthMult = 1.3, speed = 3, fleeSpeed = 7,
		body = Vector3.new(1.6, 1.6, 2.2), colours = { rgb(200, 180, 120), rgb(245, 240, 220) }, spikes = true },

		BlueTang = { type = "Fish", rarity = 2, speed = 6, fleeSpeed = 13,
		body = Vector3.new(0.5, 1.8, 2.6), colours = { rgb(30, 80, 230), rgb(255, 220, 30) } },
	Wrasse = { type = "Fish", rarity = 2, speed = 7, fleeSpeed = 13,
		body = Vector3.new(0.7, 1.2, 3), colours = { rgb(60, 200, 120), rgb(255, 110, 180) }, stripes = 3, stripeColour = rgb(80, 120, 255) },
	MoorishIdol = { type = "Fish", rarity = 2, speed = 5, fleeSpeed = 12,
		body = Vector3.new(0.4, 2.4, 2.2), colours = { rgb(250, 240, 210), rgb(255, 210, 40) }, stripes = 2, stripeColour = rgb(25, 25, 25), sail = true },

	---------------- Rarity 3: Rare
	Grouper = { type = "Fish", rarity = 3, speed = 5, fleeSpeed = 10,
		body = Vector3.new(1.6, 2.2, 4.5), colours = { rgb(120, 95, 70), rgb(205, 175, 125) } },
	Tuna = { type = "Fish", rarity = 3, speed = 10, fleeSpeed = 15,
		body = Vector3.new(1.4, 2, 5.5), colours = { rgb(40, 60, 120), rgb(200, 210, 225) } },
	Barracuda = { type = "Fish", rarity = 3, speed = 9, fleeSpeed = 17,
		body = Vector3.new(0.8, 1.2, 6.5), colours = { rgb(150, 160, 175), rgb(220, 225, 235) } },
	Triggerfish = { type = "Fish", rarity = 3, healthMult = 1.2, speed = 5, fleeSpeed = 11,
		body = Vector3.new(1, 1.9, 3.2), colours = { rgb(60, 60, 70), rgb(255, 200, 60) }, stripes = 2, stripeColour = rgb(250, 250, 250) },
	Lionfish = { type = "Fish", rarity = 3, speed = 4, fleeSpeed = 9,
		body = Vector3.new(1, 1.6, 3), colours = { rgb(190, 60, 40), rgb(255, 255, 255) }, stripes = 4, spines = true },
	KingCrab = { type = "Crab", rarity = 3, size = 1.8, speed = 2, fleeSpeed = 5,
		colours = { rgb(150, 40, 90), rgb(230, 120, 150) } },

		MorayEel = { type = "Fish", rarity = 3, healthMult = 1.2, speed = 4, fleeSpeed = 9, bottom = true, eel = true,
		body = Vector3.new(0.9, 1.1, 8), colours = { rgb(90, 120, 40), rgb(200, 210, 90) }, spots = true },
	Stingray = { type = "Fish", rarity = 3, speed = 5, fleeSpeed = 10, bottom = true, ray = true,
		body = Vector3.new(6, 0.6, 5), colours = { rgb(120, 110, 95), rgb(225, 220, 210) }, spots = true },

	---------------- Rarity 4: Epic
	MahiMahi = { type = "Fish", rarity = 4, speed = 10, fleeSpeed = 18,
		body = Vector3.new(1.2, 2.4, 6), colours = { rgb(60, 180, 90), rgb(240, 210, 60) }, mahi = true,
		-- rarely darts at you at huge speed
		dash = { chance = 0.05, speed = 38, damage = 12, range = 35, cooldown = 15 } },
	Swordfish = { type = "Fish", rarity = 4, speed = 11, fleeSpeed = 20,
		body = Vector3.new(1.2, 2, 7), colours = { rgb(40, 50, 90), rgb(190, 200, 215) }, bill = 4 },
	Shark = { type = "Shark", rarity = 4, count = 4, healthMult = 1.8, respawn = 60,
		speed = 9, chaseSpeed = 14, -- players swim at 16, so you can just about outswim them
		aggroRange = 45, biteRange = 8, biteDamage = 20, biteCooldown = 2.5 },

		Hammerhead = { type = "Fish", rarity = 4, healthMult = 1.3, speed = 8, fleeSpeed = 14, hammer = true,
		body = Vector3.new(1.8, 2, 8), colours = { rgb(110, 120, 130), rgb(215, 220, 225) } },
	Marlin = { type = "Fish", rarity = 4, speed = 12, fleeSpeed = 21, bill = 3.5, sail = true,
		body = Vector3.new(1.2, 2.2, 7), colours = { rgb(30, 60, 140), rgb(200, 210, 230) } },

	---------------- Rarity 5: Legendary
	Sunfish = { type = "Fish", rarity = 5, healthMult = 1.5, speed = 3, fleeSpeed = 6,
		body = Vector3.new(1.2, 6, 6), colours = { rgb(150, 155, 165), rgb(210, 210, 215) }, sunfish = true },
	GoldenFish = { type = "Fish", rarity = 5, healthMult = 0.3, speed = 10, fleeSpeed = 22,
		body = Vector3.new(0.8, 1.3, 2.8), colours = { rgb(255, 200, 40), rgb(255, 235, 120) }, glow = true },
	Coelacanth = { type = "Fish", rarity = 5, healthMult = 1.2, speed = 4, fleeSpeed = 9, bottom = true,
		body = Vector3.new(1.4, 2, 5.5), colours = { rgb(40, 60, 110), rgb(90, 110, 160) }, spots = true },
	Squid = { type = "Squid", rarity = 5, count = 1, healthMult = 2.7, rewardMult = 3, respawn = 180,
		speed = 6, stalkSpeed = 13,
		chargeSpeed = 21, -- faster than you, so you can't outswim the charge
		reach = 12, damage = 35,
		firstStalk = { 45, 90 }, -- seconds after spawning before it first hunts someone
		stalkGap = { 60, 120 } }, -- seconds between hunts (shorter at higher levels)
}

-- How many of a species are alive at once, and how long one takes to come back.
-- Comes from its rarity unless the species sets its own (sharks and the squid do).
function Config.spawnFor(def)
	local r = Config.Rarities[def.rarity or 1]
	return def.count or r.count, def.respawn or r.respawn
end

function Config.creatureStats(def)
	local r = Config.Rarities[def.rarity or 1]
	return {
		health = math.floor(r.health * (def.healthMult or 1)),
		reward = math.floor(r.reward * (def.rewardMult or 1)),
		xp = math.floor(r.xp * (def.rewardMult or 1)),
	}
end

-- Levels: you earn XP from kills and pearls. Each level makes creatures tougher
-- and hit harder (for you), but they pay out more.
Config.MaxLevel = 50

function Config.xpToNext(level)
	return math.floor(100 * level ^ 1.4)
end

function Config.difficulty(level)
	local l = math.clamp(level or 1, 1, Config.MaxLevel) - 1
	return {
		health = 1 + 0.15 * l, -- your shots do less
		damage = 1 + 0.12 * l, -- creatures hit you harder
		reward = 1 + 0.1 * l, -- but drop more coins
	}
end

-- Harpoon guns, cheapest first. splash = legendary area damage radius.
Config.Harpoons = {
	{ id = "Basic", name = "Basic Harpoon", rarity = "Basic", price = 0, damage = 20, cooldown = 0.7, range = 60, speed = 110, colour = Color3.fromRGB(175, 175, 175) },
	{ id = "Uncommon", name = "Reef Harpoon", rarity = "Uncommon", price = 100, damage = 30, cooldown = 0.55, range = 70, speed = 130, colour = Color3.fromRGB(90, 210, 90) },
	{ id = "Rare", name = "Tide Harpoon", rarity = "Rare", price = 300, damage = 45, cooldown = 0.45, range = 85, speed = 150, colour = Color3.fromRGB(70, 140, 255) },
	{ id = "Epic", name = "Abyss Harpoon", rarity = "Epic", price = 800, damage = 70, cooldown = 0.35, range = 100, speed = 170, colour = Color3.fromRGB(175, 80, 255) },
	{ id = "Legendary", name = "Kraken Slayer", rarity = "Legendary", price = 2000, damage = 110, cooldown = 0.25, range = 120, speed = 200, colour = Color3.fromRGB(255, 200, 50), splash = 10 },
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
