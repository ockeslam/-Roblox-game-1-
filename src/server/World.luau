-- Builds the whole ocean: terrain, lighting, raft, coral reef, kelp and clams.
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)

local World = {}

local terrain = workspace.Terrain
local rng = Random.new(Config.Seed + 1)
local S, H = Config.Surface, Config.Half

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
	local hit = workspace:Raycast(Vector3.new(x, S + 60, z), Vector3.new(0, -S - 120, 0), rayParams)
	return hit and hit.Position.Y or 0
end

---------------------------------------------------------------- terrain
local function buildTerrain()
	terrain:Clear()
	local big = H * 2 + 160

	-- sandy seabed, then fill the lagoon with water
	terrain:FillBlock(CFrame.new(0, -12, 0), Vector3.new(big, 24, big), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, S / 2, 0), Vector3.new(H * 2, S, H * 2), Enum.Material.Water)

	-- rolling sand dunes
	for _ = 1, 45 do
		local r = rng:NextNumber(10, 24)
		local x, z = rng:NextNumber(-H + 20, H - 20), rng:NextNumber(-H + 20, H - 20)
		terrain:FillBall(Vector3.new(x, -(r - rng:NextNumber(2, 6)), z), r, Enum.Material.Sand)
	end

	-- boulders
	for _ = 1, 25 do
		local x, z = rng:NextNumber(-H + 30, H - 30), rng:NextNumber(-H + 30, H - 30)
		if Vector3.new(x, 0, z).Magnitude > 30 then
			terrain:FillBall(Vector3.new(x, rng:NextNumber(0, 3), z), rng:NextNumber(3, 8), Enum.Material.Rock)
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

	-- cliffs all the way round, so it's a lagoon
	local edge = H + 10
	local step = 22
	for i = -edge, edge, step do
		local spots = {
			Vector3.new(i, 0, -edge),
			Vector3.new(i, 0, edge),
			Vector3.new(-edge, 0, i),
			Vector3.new(edge, 0, i),
		}
		for _, p in spots do
			local jitter = Vector3.new(rng:NextNumber(-6, 6), 0, rng:NextNumber(-6, 6))
			local base = p + jitter
			terrain:FillBall(base + Vector3.new(0, 10, 0), rng:NextNumber(28, 34), Enum.Material.Rock)
			terrain:FillBall(base + Vector3.new(0, 45, 0), rng:NextNumber(26, 32), Enum.Material.Rock)
			terrain:FillBall(base + Vector3.new(0, S - 5, 0), rng:NextNumber(20, 26), Enum.Material.Rock)
			terrain:FillBall(base + Vector3.new(0, S + 15, 0), rng:NextNumber(7, 10), Enum.Material.Grass)
		end
	end
end

---------------------------------------------------------------- lighting
local function buildLighting()
	Lighting.ClockTime = 12.5
	Lighting.GeographicLatitude = 15
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(60, 95, 115)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 165, 185)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(190, 225, 240)
	atmosphere.Decay = Color3.fromRGB(90, 140, 170)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 1
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

	terrain.WaterColor = Color3.fromRGB(25, 130, 165)
	terrain.WaterTransparency = 0.85
	terrain.WaterReflectance = 0.4
	terrain.WaterWaveSize = 0.15
	terrain.WaterWaveSpeed = 12
end

---------------------------------------------------------------- raft + spawn
local function buildRaft()
	local raft = Instance.new("Model")
	raft.Name = "Raft"
	local wood = Color3.fromRGB(140, 100, 60)

	for i = -3, 3 do
		Build.part({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(16, 2, 2),
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
	spawn.Size = Vector3.new(12, 0.4, 12)
	spawn.CFrame = CFrame.new(0, S + 1.8, 0)
	spawn.Color = Color3.fromRGB(170, 125, 75)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = raft

	local pole = Build.part({
		Size = Vector3.new(0.5, 10, 0.5),
		CFrame = CFrame.new(-5, S + 7, -5),
		Color = wood,
		Material = Enum.Material.Wood,
	}, raft)
	local flag = Build.part({
		Size = Vector3.new(0.1, 2.5, 4),
		CFrame = CFrame.new(-5, S + 10.5, -3),
		Color = Color3.fromRGB(230, 60, 60),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}, raft)
	flag.Name = "Flag"

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

local function farFromReefs(p, minDist)
	for _, c in Config.reefCenters() do
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
	buildTerrain()
	buildLighting()
	task.wait() -- let terrain settle before raycasting onto it
	buildRaft()

	local reefFolder = folder("Reefs")
	for _, c in Config.reefCenters() do
		buildReef(c, reefFolder)
	end

	local kelpFolder = folder("KelpForest")
	for _ = 1, Config.KelpForests do
		local centre
		for _ = 1, 30 do
			local p = Vector3.new(rng:NextNumber(-H + 40, H - 40), 0, rng:NextNumber(-H + 40, H - 40))
			if farFromReefs(p, 40) then
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
			x, z = rng:NextNumber(-H + 40, H - 40), rng:NextNumber(-H + 40, H - 40)
		end
		buildClam(Vector3.new(x, floorAt(x, z), z), clamFolder)
	end
end

return World
