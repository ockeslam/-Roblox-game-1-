-- Builds the whole place: an island ring around a lagoon, open ocean, a volcano,
-- palm trees, the raft with the shop, coral reef, kelp and clams.
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)

local World = {}

local terrain = workspace.Terrain
local rng = Random.new(Config.Seed + 1)
local S, R = Config.Surface, Config.Radius
local OUT = 1000 -- the map runs from -OUT to OUT
local VOLCANO = Vector3.new(80, 0, -(R + 230))

local CORAL_COLOURS = {
	Color3.fromRGB(255, 111, 97),
	Color3.fromRGB(255, 160, 60),
	Color3.fromRGB(240, 90, 160),
	Color3.fromRGB(160, 90, 220),
	Color3.fromRGB(255, 220, 90),
	Color3.fromRGB(90, 200, 200),
	Color3.fromRGB(230, 60, 80),
}
local KELP_COLOURS = {
	Color3.fromRGB(85, 120, 40),
	Color3.fromRGB(110, 140, 50),
	Color3.fromRGB(70, 100, 45),
	Color3.fromRGB(130, 125, 45),
}
local LEAF_COLOURS = {
	Color3.fromRGB(60, 140, 50),
	Color3.fromRGB(80, 160, 60),
	Color3.fromRGB(50, 120, 45),
}

local islets = {}

local function pick(list)
	return list[rng:NextInteger(1, #list)]
end

local function folder(name)
	local f = workspace:FindFirstChild(name)
	if f then
		f:Destroy()
	end
	f = Instance.new("Folder")
	f.Name = name
	f.Parent = workspace
	return f
end

local rayParams = RaycastParams.new()
rayParams.IgnoreWater = true
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { terrain }

local function floorAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, S + 250, z), Vector3.new(0, -S - 320, 0), rayParams)
	return hit and hit.Position.Y or 0
end

---------------------------------------------------------------- terrain
local function fillBig(centreY, height, material)
	local tile = 500
	for x = -OUT + tile / 2, OUT - tile / 2, tile do
		for z = -OUT + tile / 2, OUT - tile / 2, tile do
			terrain:FillBlock(CFrame.new(x, centreY, z), Vector3.new(tile, height, tile), material)
		end
	end
end

-- a ring of terrain balls around the lagoon
local function ring(radius, y, rMin, rMax, material, spacing, jitter)
	jitter = jitter or 6
	local n = math.floor(2 * math.pi * radius / spacing)
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + rng:NextNumber(-0.03, 0.03)
		local rr = radius + rng:NextNumber(-jitter, jitter)
		local centre = Vector3.new(math.cos(a) * rr, y + rng:NextNumber(-3, 3), math.sin(a) * rr)
		terrain:FillBall(centre, rng:NextNumber(rMin, rMax), material)
	end
end

local function chooseIslets()
	local reefs = Config.reefCenters()
	local tries = 0
	while #islets < 3 and tries < 200 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(105, 135)
		local p = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local ok = true
		for _, c in reefs do
			if (c - p).Magnitude < 50 then
				ok = false
			end
		end
		for _, other in islets do
			if (other - p).Magnitude < 90 then
				ok = false
			end
		end
		if ok then
			table.insert(islets, p)
		end
	end
end

local function buildTerrain()
	terrain:Clear()

	-- open ocean everywhere: shallow seabed, water on top
	fillBig(8, 64, Enum.Material.Sand) -- y -24 to 40
	fillBig(S - 20, 40, Enum.Material.Water) -- y 40 to 80

	-- the lagoon is deeper
	terrain:FillCylinder(CFrame.new(0, S / 2, 0), S, R + 30, Enum.Material.Water)

	-- rolling sand dunes
	for _ = 1, 45 do
		local p = Config.randomInLagoon(rng, 20)
		local r = rng:NextNumber(10, 24)
		terrain:FillBall(Vector3.new(p.X, -(r - rng:NextNumber(2, 6)), p.Z), r, Enum.Material.Sand)
	end

	-- boulders
	for _ = 1, 25 do
		local p = Config.randomInLagoon(rng, 30)
		if p.Magnitude > 30 then
			terrain:FillBall(p + Vector3.new(0, rng:NextNumber(0, 3), 0), rng:NextNumber(3, 8), Enum.Material.Rock)
		end
	end

	-- limestone mounds for the reefs to sit on
	for _, c in Config.reefCenters() do
		terrain:FillBall(c + Vector3.new(0, -10, 0), 16, Enum.Material.Limestone)
		for _ = 1, 4 do
			local off = Vector3.new(rng:NextNumber(-16, 16), rng:NextNumber(-5, -3), rng:NextNumber(-16, 16))
			terrain:FillBall(c + off, rng:NextNumber(6, 9), Enum.Material.Limestone)
		end
	end

	-- the island ring: underwater slope, inner beach, jungle hills, outer beach, shelf
	ring(R + 22, 5, 30, 36, Enum.Material.Sand, 18)
	ring(R + 32, 40, 30, 34, Enum.Material.Sand, 18)
	ring(R + 42, 58, 22, 26, Enum.Material.Sand, 16)
	ring(R + 85, 45, 40, 48, Enum.Material.Rock, 26, 10)
	ring(R + 85, 58, 34, 40, Enum.Material.LeafyGrass, 24, 10)
	ring(R + 125, 48, 30, 34, Enum.Material.Sand, 18)
	ring(R + 150, 30, 28, 34, Enum.Material.Sand, 20)

	-- the volcano in the background
	local layers = 36
	for k = 0, layers - 1 do
		local f = k / layers
		local radius = 170 * (1 - f) ^ 1.15 + 14
		local mat = k < 8 and Enum.Material.LeafyGrass or (k < 24 and Enum.Material.Rock or Enum.Material.Basalt)
		terrain:FillCylinder(CFrame.new(VOLCANO.X, 40 + k * 5 + 2.5, VOLCANO.Z), 5, radius, mat)
	end
	terrain:FillCylinder(CFrame.new(VOLCANO.X, 40 + layers * 5 - 2, VOLCANO.Z), 6, 12, Enum.Material.CrackedLava)

	-- distant islands on the horizon
	for _ = 1, 6 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(600, 850)
		local c = Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		if (c - VOLCANO).Magnitude > 320 then
			local r = rng:NextNumber(50, 80)
			terrain:FillBall(c + Vector3.new(0, S + 5 - r * 1.2, 0), r * 1.2, Enum.Material.Sand)
			terrain:FillBall(c + Vector3.new(0, S + 30 - r * 0.8, 0), r * 0.8, Enum.Material.LeafyGrass)
		end
	end

	-- little sandy islands inside the lagoon
	for _, p in islets do
		terrain:FillBall(p + Vector3.new(0, 30, 0), 44, Enum.Material.Limestone)
		terrain:FillBall(p + Vector3.new(0, S - 16, 0), 22, Enum.Material.Sand)
	end
end

---------------------------------------------------------------- lighting
local function buildLighting()
	Lighting.ClockTime = 13
	Lighting.GeographicLatitude = 15
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(60, 95, 115)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 170, 185)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(195, 230, 245)
	atmosphere.Decay = Color3.fromRGB(100, 150, 180)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	rays.Intensity = 0.15
	rays.Spread = 0.8
	rays.Parent = Lighting

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.5
	bloom.Parent = Lighting

	terrain.WaterColor = Color3.fromRGB(25, 140, 165)
	terrain.WaterTransparency = 0.85
	terrain.WaterReflectance = 0.4
	terrain.WaterWaveSize = 0.15
	terrain.WaterWaveSpeed = 12
end

---------------------------------------------------------------- palm trees
local function leaf(a, b, colour, parent)
	local len = (b - a).Magnitude
	Build.part({
		Size = Vector3.new(2.2, 0.15, len),
		CFrame = CFrame.lookAt((a + b) / 2, b),
		Color = colour,
		Material = Enum.Material.Grass,
		CanCollide = false,
		CanQuery = false,
	}, parent)
end

local function buildPalm(base, parent)
	local model = Instance.new("Model")
	model.Name = "Palm"
	local height = rng:NextNumber(14, 22)
	local leanDir = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
	if leanDir.Magnitude < 0.1 then
		leanDir = Vector3.xAxis
	end
	local lean = leanDir.Unit * rng:NextNumber(0.15, 0.4)
	local trunk = Color3.fromRGB(140, 105, 70)

	local prev = base
	for i = 1, 6 do
		local f = i / 6
		local p = base + Vector3.new(0, height * f, 0) + lean * height * f * f
		Build.cylinderBetween(prev, p, 1.4 - f * 0.5, { Color = trunk, Material = Enum.Material.Wood }, model)
		prev = p
	end
	local top = prev

	local colour = pick(LEAF_COLOURS)
	for k = 1, 8 do
		local a = k / 8 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local mid = top + out * 4 + Vector3.new(0, 1.2, 0)
		local tip = top + out * 8.5 + Vector3.new(0, -2.5, 0)
		leaf(top, mid, colour, model)
		leaf(mid, tip, colour, model)
	end
	for k = 1, 3 do
		local a = k / 3 * math.pi * 2
		Build.part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.9,
			CFrame = CFrame.new(top + Vector3.new(math.cos(a) * 0.7, -0.8, math.sin(a) * 0.7)),
			Color = Color3.fromRGB(90, 65, 35),
			CanCollide = false,
		}, model)
	end
	model.Parent = parent
end

local function scatterPalms(parent)
	local placed = 0
	for _ = 1, 500 do
		if placed >= 75 then
			break
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(R + 36, R + 140)
		local x, z = math.cos(a) * r, math.sin(a) * r
		local y = floorAt(x, z)
		if y > S + 1.5 and y < S + 25 then
			buildPalm(Vector3.new(x, y - 0.5, z), parent)
			placed += 1
		end
	end
	for _, p in islets do
		for _ = 1, 3 do
			local x, z = p.X + rng:NextNumber(-9, 9), p.Z + rng:NextNumber(-9, 9)
			local y = floorAt(x, z)
			if y > S + 1 then
				buildPalm(Vector3.new(x, y - 0.5, z), parent)
			end
		end
	end
end

local function volcanoSmoke()
	local top = Build.part({
		Name = "VolcanoVent",
		Size = Vector3.new(4, 1, 4),
		CFrame = CFrame.new(VOLCANO.X, 40 + 36 * 5 + 2, VOLCANO.Z),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
	}, workspace)
	local smoke = Instance.new("Smoke")
	smoke.Size = 40
	smoke.Opacity = 0.12
	smoke.RiseVelocity = 8
	smoke.Color = Color3.fromRGB(120, 120, 120)
	smoke.Parent = top
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 120, 40)
	glow.Range = 40
	glow.Brightness = 3
	glow.Parent = top
end

---------------------------------------------------------------- raft, spawn and shop
local function buildVendingMachine(base, parent)
	local m = Instance.new("Model")
	m.Name = "HarpoonShop"
	local cf = CFrame.new(base) -- the front faces +Z

	local body = Build.part({
		Name = "Body",
		Size = Vector3.new(6, 9, 3.5),
		CFrame = cf * CFrame.new(0, 4.5, 0),
		Color = Color3.fromRGB(25, 40, 80),
		Material = Enum.Material.Metal,
	}, m)
	Build.part({
		Size = Vector3.new(4.2, 6, 0.2),
		CFrame = cf * CFrame.new(-0.6, 5, 1.8),
		Color = Color3.fromRGB(170, 220, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		CanQuery = false,
	}, m)
	for i, def in ipairs(Config.Harpoons) do
		local y = 2.6 + (i - 1) * 1.2
		Build.part({
			Size = Vector3.new(4, 0.15, 2.5),
			CFrame = cf * CFrame.new(-0.6, y - 0.35, 0.4),
			Color = Color3.fromRGB(60, 60, 70),
			Material = Enum.Material.Metal,
		}, m)
		Build.part({
			Size = Vector3.new(3.2, 0.25, 0.25),
			CFrame = cf * CFrame.new(-0.6, y, 0.9),
			Color = def.colour,
			Material = Enum.Material.Neon,
		}, m)
	end
	Build.part({
		Size = Vector3.new(1.2, 3, 0.2),
		CFrame = cf * CFrame.new(2.2, 5, 1.8),
		Color = Color3.fromRGB(40, 40, 50),
		Material = Enum.Material.Metal,
	}, m)
	local buttonColours = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 255, 120), Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 210, 60) }
	for k = 0, 3 do
		Build.part({
			Size = Vector3.new(0.6, 0.35, 0.1),
			CFrame = cf * CFrame.new(2.2, 6 - k * 0.6, 1.92),
			Color = buttonColours[k + 1],
			Material = Enum.Material.Neon,
		}, m)
	end
	Build.part({
		Size = Vector3.new(4, 0.8, 0.3),
		CFrame = cf * CFrame.new(-0.6, 1.2, 1.8),
		Color = Color3.new(0.05, 0.05, 0.05),
	}, m)

	local sign = Build.part({
		Size = Vector3.new(6, 1.6, 3.7),
		CFrame = cf * CFrame.new(0, 9.8, 0),
		Color = Color3.fromRGB(0, 200, 255),
		Material = Enum.Material.Neon,
	}, m)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back -- the +Z side
	sg.PixelsPerStud = 50
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "HARPOON SHOP"
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(10, 25, 60)
	text.Parent = sg
	sg.Parent = sign
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(0, 200, 255)
	light.Range = 16
	light.Parent = sign

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Open shop"
	prompt.ObjectText = "Harpoon Vending Machine"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	CollectionService:AddTag(prompt, "ShopPrompt")

	m.Parent = parent
end

local function buildRaft()
	local raft = Instance.new("Model")
	raft.Name = "Raft"
	local wood = Color3.fromRGB(140, 100, 60)

	for i = -5, 5 do
		Build.part({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(26, 2, 2),
			CFrame = CFrame.new(0, S + 0.6, i * 2.1),
			Color = wood,
			Material = Enum.Material.Wood,
		}, raft)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "RaftSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = CFrame.new(-4, S + 1.8, 4)
	spawn.Color = Color3.fromRGB(170, 125, 75)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = raft

	local pole = Build.part({
		Size = Vector3.new(0.5, 10, 0.5),
		CFrame = CFrame.new(-11, S + 6.6, -9),
		Color = wood,
		Material = Enum.Material.Wood,
	}, raft)
	Build.part({
		Size = Vector3.new(0.1, 2.5, 4),
		CFrame = CFrame.new(-11, S + 10.2, -7),
		Color = Color3.fromRGB(230, 60, 60),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}, raft)

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(320, 80)
	sign.StudsOffset = Vector3.new(0, 4, 0)
	sign.MaxDistance = 150
	sign.Adornee = pole
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "REEF DIVE"
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = sign
	sign.Parent = pole

	buildVendingMachine(Vector3.new(6, S + 1.6, -7.5), raft)
	raft.Parent = workspace

	-- get rid of the template baseplate/spawn if this was opened in a Baseplate place
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("SpawnLocation") and d ~= spawn then
			d.Enabled = false
		end
	end
end

---------------------------------------------------------------- coral types
local function smallProps(colour, extra)
	local props = {
		Color = colour,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
	}
	if extra then
		for k, v in extra do
			props[k] = v
		end
	end
	return props
end

local function branch(model, from, dir, length, thick, depth, colour)
	local to = from + dir * length
	Build.cylinderBetween(from, to, thick, smallProps(colour), model)
	if depth <= 0 then
		Build.part(
			smallProps(colour:Lerp(Color3.new(1, 1, 1), 0.35), {
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * thick * 1.4,
				CFrame = CFrame.new(to),
			}),
			model
		)
		return
	end
	for _ = 1, rng:NextInteger(2, 3) do
		local newDir = (dir + Vector3.new(rng:NextNumber(-0.8, 0.8), rng:NextNumber(0.1, 0.6), rng:NextNumber(-0.8, 0.8))).Unit
		branch(model, to, newDir, length * 0.75, thick * 0.7, depth - 1, colour)
	end
end

local function branchCoral(model, base)
	local up = (Vector3.yAxis + Vector3.new(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2))).Unit
	branch(model, base, up, rng:NextNumber(1.8, 3), rng:NextNumber(0.5, 0.8), 2, pick(CORAL_COLOURS))
end

local function brainCoral(model, base)
	local d = rng:NextNumber(3, 6)
	Build.part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * d,
		CFrame = CFrame.new(base + Vector3.new(0, d * 0.1, 0)),
		Color = pick(CORAL_COLOURS):Lerp(Color3.fromRGB(200, 180, 140), 0.4),
		Material = Enum.Material.Pebble,
	}, model)
end

local function fanCoral(model, base)
	local colour = pick(CORAL_COLOURS)
	local yaw = rng:NextNumber(0, math.pi * 2)
	local height = rng:NextNumber(3.5, 6)
	for i = -3, 3 do
		local a = math.rad(i * 18)
		local dir = (CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, a)).UpVector
		Build.cylinderBetween(base, base + dir * height * (1 - math.abs(i) * 0.08), 0.22, smallProps(colour), model)
	end
end

local function tubeCoral(model, base)
	local colour = pick(CORAL_COLOURS)
	for _ = 1, rng:NextInteger(4, 7) do
		local off = Vector3.new(rng:NextNumber(-1.2, 1.2), 0, rng:NextNumber(-1.2, 1.2))
		local h = rng:NextNumber(1.5, 4)
		Build.cylinderBetween(base + off, base + off + Vector3.new(0, h, 0), rng:NextNumber(0.6, 1), smallProps(colour), model)
	end
end

local function anemone(model, base)
	local colour = pick({ Color3.fromRGB(255, 150, 200), Color3.fromRGB(140, 255, 180), Color3.fromRGB(255, 200, 120) })
	Build.cylinderBetween(base, base + Vector3.new(0, 0.8, 0), 1.4, smallProps(colour:Lerp(Color3.new(0, 0, 0), 0.3)), model)
	local top = base + Vector3.new(0, 0.8, 0)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		local dir = Vector3.new(math.cos(a) * 0.6, 1, math.sin(a) * 0.6).Unit
		Build.cylinderBetween(top, top + dir * rng:NextNumber(1.2, 1.8), 0.18, smallProps(colour), model)
	end
end

local function starfish(model, base)
	local colour = pick({ Color3.fromRGB(255, 120, 40), Color3.fromRGB(230, 50, 70), Color3.fromRGB(150, 70, 200) })
	local yaw = rng:NextNumber(0, math.pi * 2)
	for i = 0, 4 do
		local cf = CFrame.new(base + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, yaw + i * math.pi * 2 / 5, 0)
		Build.part(smallProps(colour, { Size = Vector3.new(0.5, 0.3, 1.4), CFrame = cf * CFrame.new(0, 0, -0.7) }), model)
	end
end

local CORAL_BUILDERS = {
	{ 0.30, branchCoral },
	{ 0.50, brainCoral },
	{ 0.68, fanCoral },
	{ 0.85, tubeCoral },
	{ 0.95, anemone },
	{ 1.00, starfish },
}

local function buildReef(center, parent)
	local model = Instance.new("Model")
	model.Name = "Reef"
	for _ = 1, 28 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = 24 * math.sqrt(rng:NextNumber())
		local x, z = center.X + math.cos(a) * r, center.Z + math.sin(a) * r
		local base = Vector3.new(x, floorAt(x, z) - 0.3, z)
		local roll = rng:NextNumber()
		for _, entry in CORAL_BUILDERS do
			if roll <= entry[1] then
				entry[2](model, base)
				break
			end
		end
	end
	model.Parent = parent
end

---------------------------------------------------------------- kelp
local function buildKelp(x, z, parent)
	local y = floorAt(x, z) - 0.5
	if y > S - 20 then
		return -- too shallow here
	end
	local segLen = 4
	local top = S - rng:NextNumber(3, 18)
	local count = math.max(3, math.floor((top - y) / segLen))
	local yaw = rng:NextNumber(0, math.pi * 2)
	local colour = pick(KELP_COLOURS)

	local model = Instance.new("Model")
	model.Name = "Kelp"
	local cf = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
	for i = 1, count do
		Build.part({
			Name = tostring(i),
			Size = Vector3.new(0.3, segLen, rng:NextNumber(1.2, 2)),
			CFrame = cf * CFrame.new(0, segLen / 2, 0) * CFrame.Angles(0, i * 0.6, 0),
			Color = colour,
			CanCollide = false,
			CanQuery = false,
			CastShadow = false,
		}, model)
		cf *= CFrame.new(0, segLen, 0)
	end
	-- the client uses these to make the kelp sway
	model:SetAttribute("Base", Vector3.new(x, y, z))
	model:SetAttribute("Yaw", yaw)
	model:SetAttribute("Phase", rng:NextNumber(0, math.pi * 2))
	model:SetAttribute("SegLen", segLen)
	CollectionService:AddTag(model, "Kelp")
	model.Parent = parent
end

local function clearSpot(p, minDist)
	for _, c in Config.reefCenters() do
		if (Vector3.new(p.X, 0, p.Z) - c).Magnitude < minDist then
			return false
		end
	end
	for _, c in islets do
		if (Vector3.new(p.X, 0, p.Z) - c).Magnitude < minDist then
			return false
		end
	end
	return Vector3.new(p.X, 0, p.Z).Magnitude > 30
end

---------------------------------------------------------------- clams
local function buildClam(pos, parent)
	local model = Instance.new("Model")
	model.Name = "Clam"
	local shell = Color3.fromRGB(150, 120, 170)
	local yaw = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	local cf = CFrame.new(pos) * yaw

	Build.ellipsoid(Vector3.new(3, 0.9, 2.4), cf * CFrame.new(0, 0.3, 0), shell, model)
	Build.ellipsoid(
		Vector3.new(3, 0.8, 2.4),
		cf * CFrame.new(0, 0.9, 1) * CFrame.Angles(math.rad(-40), 0, 0),
		shell:Lerp(Color3.new(1, 1, 1), 0.15),
		model
	)
	local pearl = Build.part({
		Name = "Pearl",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.9,
		CFrame = cf * CFrame.new(0, 0.9, 0),
		Color = Color3.fromRGB(250, 248, 255),
		Reflectance = 0.4,
		CanCollide = false,
		CanQuery = false,
	}, model)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(220, 240, 255)
	glow.Range = 7
	glow.Brightness = 1.5
	glow.Parent = pearl
	CollectionService:AddTag(pearl, "Pearl")
	model.Parent = parent
end

---------------------------------------------------------------- build it all
function World.build()
	chooseIslets()
	buildTerrain()
	buildLighting()
	task.wait() -- let terrain settle before raycasting onto it
	buildRaft()
	volcanoSmoke()

	scatterPalms(folder("Palms"))

	local reefFolder = folder("Reefs")
	for _, c in Config.reefCenters() do
		buildReef(c, reefFolder)
	end

	local kelpFolder = folder("KelpForest")
	for _ = 1, Config.KelpForests do
		local centre
		for _ = 1, 40 do
			local p = Config.randomInLagoon(rng, 45)
			if clearSpot(p, 45) then
				centre = p
				break
			end
		end
		if centre then
			for _ = 1, 12 do
				local a = rng:NextNumber(0, math.pi * 2)
				local r = 20 * math.sqrt(rng:NextNumber())
				buildKelp(centre.X + math.cos(a) * r, centre.Z + math.sin(a) * r, kelpFolder)
			end
		end
	end

	local clamFolder = folder("Clams")
	local centers = Config.reefCenters()
	for _ = 1, Config.ClamCount do
		local x, z
		if rng:NextNumber() < 0.7 then
			local c = centers[rng:NextInteger(1, #centers)]
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(8, 26)
			x, z = c.X + math.cos(a) * r, c.Z + math.sin(a) * r
		else
			local p = Config.randomInLagoon(rng, 40)
			x, z = p.X, p.Z
		end
		buildClam(Vector3.new(x, floorAt(x, z), z), clamFolder)
	end
end

return World
