-- Seagulls circling over the island and lagoon. Made locally so they're smooth.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Build = require(Shared:WaitForChild("Build"))

local Birds = {}

local S, R = Config.Surface, Config.Radius
local rng = Random.new(Config.Seed + 21)
local folder: Folder
local birds = {}

local WHITE = Color3.fromRGB(245, 245, 245)
local GREY = Color3.fromRGB(150, 155, 165)

local function deco(props)
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return props
end

local function blob(size, colour)
	return Build.ellipsoid(size, CFrame.new(), colour, folder, deco({}))
end

local function block(size, colour)
	return Build.part(deco({ Size = size, Color = colour }), folder)
end

local function makeBird(centre, radius, height)
	local s = rng:NextNumber(0.9, 1.3)
	table.insert(birds, {
		s = s,
		body = blob(Vector3.new(0.8, 0.8, 2.2) * s, WHITE),
		head = blob(Vector3.new(0.6, 0.6, 0.7) * s, WHITE),
		beak = block(Vector3.new(0.15, 0.15, 0.5) * s, Color3.fromRGB(250, 180, 40)),
		tail = block(Vector3.new(0.7, 0.08, 0.6) * s, GREY),
		wings = {
			{ inner = block(Vector3.new(1.8, 0.1, 0.9) * s, WHITE), outer = block(Vector3.new(1.8, 0.08, 0.7) * s, GREY) },
			{ inner = block(Vector3.new(1.8, 0.1, 0.9) * s, WHITE), outer = block(Vector3.new(1.8, 0.08, 0.7) * s, GREY) },
		},
		centre = centre,
		radius = radius,
		height = height,
		speed = rng:NextNumber(14, 22),
		dir = rng:NextNumber() < 0.5 and -1 or 1,
		ph = rng:NextNumber(0, math.pi * 2),
	})
end

local function step()
	local t = os.clock()
	local parts, cframes = {}, {}
	local function put(p, cf)
		table.insert(parts, p)
		table.insert(cframes, cf)
	end

	for _, b in birds do
		local function at(tt)
			local a = b.dir * tt * b.speed / b.radius + b.ph
			return b.centre + Vector3.new(math.cos(a) * b.radius, b.height + math.sin(tt * 0.3 + b.ph) * 4, math.sin(a) * b.radius)
		end
		local pos = at(t)
		local ahead = at(t + 0.1)
		-- lean into the turn
		local cf = CFrame.lookAt(pos, ahead) * CFrame.Angles(0, 0, b.dir * 0.35)
		local s = b.s

		-- mostly gliding, with the odd burst of flapping
		local flapping = math.sin(t * 0.7 + b.ph) > 0.4
		local flap = flapping and math.sin(t * 10 + b.ph) * 0.6 or (0.08 + math.sin(t * 2 + b.ph) * 0.05)

		put(b.body, cf)
		put(b.head, cf * CFrame.new(0, 0.25 * s, -1.2 * s))
		put(b.beak, cf * CFrame.new(0, 0.2 * s, -1.7 * s))
		put(b.tail, cf * CFrame.new(0, 0, 1.3 * s))
		for i, side in { -1, 1 } do
			local w = b.wings[i]
			local shoulder = cf * CFrame.new(side * 0.35 * s, 0.15 * s, -0.1 * s) * CFrame.Angles(0, 0, side * flap)
			put(w.inner, shoulder * CFrame.new(side * 0.9 * s, 0, 0))
			local elbow = shoulder * CFrame.new(side * 1.8 * s, 0, 0) * CFrame.Angles(0, 0, side * flap * 0.6 - side * 0.15)
			put(w.outer, elbow * CFrame.new(side * 0.9 * s, 0, 0.1 * s))
		end
	end
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

function Birds.start()
	folder = Instance.new("Folder")
	folder.Name = "Birds"
	folder.Parent = workspace

	for i = 1, Config.BirdCount do
		if i % 3 == 0 then
			-- a small circle over some spot in the lagoon
			local c = Config.randomInLagoon(rng, 40)
			makeBird(c, rng:NextNumber(20, 45), S + rng:NextNumber(15, 35))
		else
			-- a big loop following the beaches
			makeBird(Vector3.zero, R + rng:NextNumber(10, 80), S + rng:NextNumber(20, 50))
		end
	end

	RunService.Heartbeat:Connect(step)

	-- seagull calls, if a sound ID has been set in Config.Sounds.Seagulls
	local Sounds = require(script.Parent:WaitForChild("Sounds"))
	local gulls = Sounds.make("Seagulls", true)
	if gulls then
		gulls.Volume = 0.4
		gulls:Play()
		RunService.Heartbeat:Connect(function()
			local underwater = workspace.CurrentCamera.CFrame.Position.Y < S
			local storm = workspace:GetAttribute("Storm") == true
			gulls.Volume = (underwater or storm) and 0 or 0.4
		end)
	end
end

return Birds
