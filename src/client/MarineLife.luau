-- Fish schools, jellyfish, sea turtles, manta rays and crabs.
-- They're made on each player's machine, so they move smoothly and cost the server nothing.
-- Fish scatter when you or a shark swims through them.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Build = require(Shared:WaitForChild("Build"))

local MarineLife = {}

local S, H = Config.Surface, Config.Half
local rng = Random.new(Config.Seed + 7)
local folder: Folder

local rayParams = RaycastParams.new()
rayParams.IgnoreWater = true
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace.Terrain }

local function floorAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, S + 60, z), Vector3.new(0, -S - 120, 0), rayParams)
	return hit and hit.Position.Y or 0
end

local function deco(props)
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return props
end

local function blob(size, colour, extra)
	local p = Build.ellipsoid(size, CFrame.new(), colour, folder, deco(extra or {}))
	return p
end

local function block(size, colour, extra)
	local props = deco(extra or {})
	props.Size = size
	props.Color = colour
	return Build.part(props, folder)
end

local function facing(pos, nextPos)
	local d = nextPos - pos
	if d.Magnitude < 0.001 then
		return CFrame.new(pos)
	end
	return CFrame.lookAt(pos, nextPos)
end

---------------------------------------------------------------- fish
local PALETTES = {
	{ Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 255, 255) },
	{ Color3.fromRGB(40, 110, 255), Color3.fromRGB(255, 220, 0) },
	{ Color3.fromRGB(255, 220, 40), Color3.fromRGB(255, 240, 120) },
	{ Color3.fromRGB(255, 90, 140), Color3.fromRGB(255, 170, 200) },
	{ Color3.fromRGB(80, 220, 180), Color3.fromRGB(30, 140, 200) },
	{ Color3.fromRGB(150, 80, 230), Color3.fromRGB(255, 200, 60) },
}
local SILVER = { Color3.fromRGB(200, 205, 215), Color3.fromRGB(150, 160, 180) }

local schools = {}

local function makeSchool(home, count, palette, size, radius)
	local school = {
		home = home,
		r = radius,
		dy = rng:NextNumber(2, 6),
		w = rng:NextNumber(0.08, 0.15),
		ph = rng:NextNumber(0, math.pi * 2),
		fish = {},
	}
	for _ = 1, count do
		local s = size * rng:NextNumber(0.8, 1.25)
		local body = blob(Vector3.new(0.5, 1, 1.7) * s, palette[1])
		local tail = block(Vector3.new(0.08, 0.8, 0.6) * s, palette[2])
		table.insert(school.fish, {
			body = body,
			tail = tail,
			size = s,
			offset = Vector3.new(rng:NextNumber(-4, 4), rng:NextNumber(-2, 2), rng:NextNumber(-4, 4)),
			ph = rng:NextNumber(0, math.pi * 2),
			lag = rng:NextNumber(0, 0.6),
		})
	end
	table.insert(schools, school)
end

local function schoolCentre(s, t)
	return s.home
		+ Vector3.new(
			math.sin(t * s.w + s.ph) * s.r,
			math.sin(t * s.w * 0.7 + s.ph * 2) * s.dy,
			math.cos(t * s.w * 0.8 + s.ph) * s.r * 0.8
		)
end

local function fishPos(s, f, t)
	local c = schoolCentre(s, t - f.lag)
	local wobble = Vector3.new(math.sin(t * 1.3 + f.ph), math.sin(t * 0.9 + f.ph * 1.7) * 0.5, math.cos(t * 1.1 + f.ph)) * 1.2
	return c + f.offset + wobble
end

---------------------------------------------------------------- jellyfish
local jellies = {}

local function makeJelly()
	local colour = ({ Color3.fromRGB(255, 140, 220), Color3.fromRGB(170, 140, 255), Color3.fromRGB(120, 230, 255) })[rng:NextInteger(1, 3)]
	local bell = blob(Vector3.new(2.6, 1.8, 2.6), colour, { Transparency = 0.35, Material = Enum.Material.Glass })
	local light = Instance.new("PointLight")
	light.Color = colour
	light.Range = 8
	light.Brightness = 1
	light.Parent = bell
	local tentacles = {}
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		table.insert(tentacles, {
			part = block(Vector3.new(0.12, 3, 0.12), colour, { Transparency = 0.4 }),
			off = Vector3.new(math.cos(a) * 0.7, -0.5, math.sin(a) * 0.7),
		})
	end
	table.insert(jellies, {
		bell = bell,
		tentacles = tentacles,
		home = Vector3.new(rng:NextNumber(-H + 40, H - 40), rng:NextNumber(25, S - 15), rng:NextNumber(-H + 40, H - 40)),
		ph = rng:NextNumber(0, math.pi * 2),
	})
end

---------------------------------------------------------------- turtles
local turtles = {}

local function makeTurtle()
	local shellCol = Color3.fromRGB(110, 95, 55)
	local skin = Color3.fromRGB(120, 150, 90)
	local t = {
		shell = blob(Vector3.new(4, 1.4, 5), shellCol),
		belly = blob(Vector3.new(3.6, 0.8, 4.6), Color3.fromRGB(220, 200, 140)),
		head = blob(Vector3.new(1, 0.9, 1.5), skin),
		front = { block(Vector3.new(2.6, 0.2, 1), skin), block(Vector3.new(2.6, 0.2, 1), skin) },
		back = { block(Vector3.new(1.2, 0.2, 0.8), skin), block(Vector3.new(1.2, 0.2, 0.8), skin) },
		centre = Vector3.new(rng:NextNumber(-H / 2, H / 2), rng:NextNumber(20, 40), rng:NextNumber(-H / 2, H / 2)),
		radius = rng:NextNumber(40, 70),
		speed = rng:NextNumber(3, 5),
		ph = rng:NextNumber(0, math.pi * 2),
	}
	table.insert(turtles, t)
end

---------------------------------------------------------------- manta rays
local rays = {}

local function makeRay()
	local dark = Color3.fromRGB(45, 50, 65)
	table.insert(rays, {
		body = blob(Vector3.new(3, 0.8, 5), dark),
		wings = { blob(Vector3.new(6, 0.35, 3.5), dark), blob(Vector3.new(6, 0.35, 3.5), dark) },
		tail = block(Vector3.new(0.15, 0.15, 5), dark),
		centre = Vector3.new(rng:NextNumber(-H / 2, H / 2), rng:NextNumber(30, 50), rng:NextNumber(-H / 2, H / 2)),
		radius = rng:NextNumber(60, 100),
		ph = rng:NextNumber(0, math.pi * 2),
	})
end

---------------------------------------------------------------- crabs
local crabs = {}

local function makeCrab(home)
	local red = Color3.fromRGB(220, 70, 40)
	local crab = {
		body = blob(Vector3.new(1.6, 0.7, 1.2), red),
		claws = { blob(Vector3.new(0.6, 0.4, 0.5), red), blob(Vector3.new(0.6, 0.4, 0.5), red) },
		legs = {},
		home = home,
		yaw = rng:NextNumber(0, math.pi * 2),
		ph = rng:NextNumber(0, math.pi * 2),
	}
	for _ = 1, 6 do
		table.insert(crab.legs, block(Vector3.new(0.9, 0.12, 0.12), red))
	end
	table.insert(crabs, crab)
end

---------------------------------------------------------------- spawn everything
local function spawnAll()
	local centres = Config.reefCenters()
	for _, c in centres do
		local palette = PALETTES[rng:NextInteger(1, #PALETTES)]
		makeSchool(c + Vector3.new(0, rng:NextNumber(12, 18), 0), 12, palette, 1, rng:NextNumber(10, 18))
		for _ = 1, 2 do
			local a = rng:NextNumber(0, math.pi * 2)
			local pos = c + Vector3.new(math.cos(a) * rng:NextNumber(5, 20), 0, math.sin(a) * rng:NextNumber(5, 20))
			makeCrab(Vector3.new(pos.X, 0, pos.Z))
		end
	end
	-- big silver schools out in open water
	for _ = 1, 3 do
		local home = Vector3.new(rng:NextNumber(-H / 2, H / 2), rng:NextNumber(30, 55), rng:NextNumber(-H / 2, H / 2))
		makeSchool(home, 25, SILVER, 0.7, rng:NextNumber(35, 60))
	end
	for _ = 1, 14 do
		makeJelly()
	end
	for _ = 1, 3 do
		makeTurtle()
	end
	for _ = 1, 2 do
		makeRay()
	end
end

---------------------------------------------------------------- animate
local function threats()
	local list = {}
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		table.insert(list, hrp.Position)
	end
	local sharks = workspace:FindFirstChild("Sharks")
	if sharks then
		for _, shark in sharks:GetChildren() do
			if shark:IsA("Model") and shark.PrimaryPart then
				table.insert(list, shark.PrimaryPart.Position)
			end
		end
	end
	return list
end

local function scatter(pos, dangers)
	for _, d in dangers do
		local away = pos - d
		local dist = away.Magnitude
		if dist < 10 and dist > 0.01 then
			pos += away.Unit * (10 - dist) * 0.9
		end
	end
	return Vector3.new(pos.X, math.clamp(pos.Y, 3, S - 2), pos.Z)
end

local function step()
	local t = os.clock()
	local parts, cframes = {}, {}
	local function put(p, cf)
		table.insert(parts, p)
		table.insert(cframes, cf)
	end
	local dangers = threats()

	-- fish
	for _, s in schools do
		for _, f in s.fish do
			local p1 = fishPos(s, f, t)
			local p2 = fishPos(s, f, t + 0.1)
			local pos = scatter(p1, dangers)
			local cf = facing(pos, pos + (p2 - p1))
			put(f.body, cf)
			put(f.tail, cf * CFrame.new(0, 0, 0.95 * f.size) * CFrame.Angles(0, math.sin(t * 12 + f.ph) * 0.5, 0) * CFrame.new(0, 0, 0.25 * f.size))
		end
	end

	-- jellyfish: slow drift plus a pulsing bob
	for _, j in jellies do
		local function at(tt)
			return j.home
				+ Vector3.new(math.sin(tt * 0.05 + j.ph) * 15, math.sin(tt * 0.8 + j.ph) * 1.5 + math.sin(tt * 0.1 + j.ph) * 6, math.cos(tt * 0.04 + j.ph) * 15)
		end
		local pos = at(t)
		local cf = CFrame.new(pos) * CFrame.Angles(math.sin(t * 0.5 + j.ph) * 0.15, 0, math.cos(t * 0.4 + j.ph) * 0.15)
		put(j.bell, cf)
		for i, tent in j.tentacles do
			local sway = CFrame.Angles(math.sin(t * 2 + i + j.ph) * 0.25, 0, math.cos(t * 1.7 + i) * 0.25)
			put(tent.part, cf * CFrame.new(tent.off) * sway * CFrame.new(0, -1.5, 0))
		end
	end

	-- turtles: big slow circles, flapping flippers
	for _, tu in turtles do
		local function at(tt)
			local a = tt * tu.speed / tu.radius + tu.ph
			return tu.centre + Vector3.new(math.cos(a) * tu.radius, math.sin(tt * 0.2 + tu.ph) * 3, math.sin(a) * tu.radius)
		end
		local pos = at(t)
		local cf = facing(pos, at(t + 0.2))
		put(tu.shell, cf * CFrame.new(0, 0.3, 0))
		put(tu.belly, cf * CFrame.new(0, -0.1, 0))
		put(tu.head, cf * CFrame.new(0, 0.1, -3))
		local flap = math.sin(t * 2 + tu.ph) * 0.5
		for i, side in { -1, 1 } do
			put(tu.front[i], cf * CFrame.new(side * 1.6, -0.1, -1.2) * CFrame.Angles(0, side * 0.3, side * flap) * CFrame.new(side * 1.2, 0, 0))
			put(tu.back[i], cf * CFrame.new(side * 1.3, -0.1, 2.2) * CFrame.Angles(0, -side * 0.4, side * flap * 0.4) * CFrame.new(side * 0.5, 0, 0))
		end
	end

	-- manta rays: gliding figure-of-eights
	for _, r in rays do
		local function at(tt)
			local a = tt * 0.05 + r.ph
			return r.centre + Vector3.new(math.sin(a) * r.radius, math.sin(a * 0.7) * 6, math.sin(a * 2) * r.radius * 0.5)
		end
		local pos = at(t)
		local cf = facing(pos, at(t + 0.2))
		put(r.body, cf)
		local flap = math.sin(t * 1.5 + r.ph) * 0.35
		for i, side in { -1, 1 } do
			put(r.wings[i], cf * CFrame.new(side * 1.2, 0, 0) * CFrame.Angles(0, 0, side * flap) * CFrame.new(side * 3, 0, 0.3))
		end
		put(r.tail, cf * CFrame.new(0, 0, 4.8))
	end

	-- crabs: scuttle side to side
	for _, c in crabs do
		local right = CFrame.Angles(0, c.yaw, 0).RightVector
		local x = math.sin(t * 0.6 + c.ph) * 4
		local flat = c.home + right * x
		local y = floorAt(flat.X, flat.Z)
		local cf = CFrame.new(flat.X, y + 0.45 + math.abs(math.sin(t * 8 + c.ph)) * 0.08, flat.Z) * CFrame.Angles(0, c.yaw, 0)
		put(c.body, cf)
		for i, side in { -1, 1 } do
			put(c.claws[i], cf * CFrame.new(side * 0.6, 0.1, -0.9))
		end
		for i, leg in c.legs do
			local side = i <= 3 and -1 or 1
			local row = (i - 1) % 3 - 1
			local kick = math.sin(t * 10 + i + c.ph) * 0.3
			put(leg, cf * CFrame.new(side * 0.8, -0.15, row * 0.4) * CFrame.Angles(0, kick, side * -0.4) * CFrame.new(side * 0.35, 0, 0))
		end
	end

	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

function MarineLife.start()
	folder = Instance.new("Folder")
	folder.Name = "MarineLife"
	folder.Parent = workspace
	spawnAll()
	RunService.Heartbeat:Connect(step)
end

return MarineLife
