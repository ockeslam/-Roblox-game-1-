-- Sharks patrol the lagoon and chase anyone who swims too close.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)

local Sharks = {}
local rng = Random.new()

local GREY = Color3.fromRGB(105, 120, 135)
local BELLY = Color3.fromRGB(215, 220, 225)

local function randomPatrolPoint()
	local h = Config.Half - 25
	return Vector3.new(rng:NextNumber(-h, h), rng:NextNumber(18, Config.Surface - 12), rng:NextNumber(-h, h))
end

local function clampGoal(p)
	local h = Config.Half - 15
	return Vector3.new(math.clamp(p.X, -h, h), math.clamp(p.Y, 6, Config.Surface - 5), math.clamp(p.Z, -h, h))
end

-- The shark faces -Z (forwards), tail at +Z.
local function buildShark(pos, s)
	local model = Instance.new("Model")
	model.Name = "Shark"

	local root = Build.ellipsoid(Vector3.new(3.2, 3, 12) * s, CFrame.new(pos), GREY, model)
	root.Name = "Body"
	local cf = root.CFrame
	local parts = {}
	local function add(p)
		table.insert(parts, p)
		return p
	end

	add(Build.ellipsoid(Vector3.new(2.6, 2.2, 10) * s, cf * CFrame.new(0, -0.5 * s, 0.2 * s), BELLY, model))
	add(Build.ellipsoid(Vector3.new(1.4, 1.6, 4.5) * s, cf * CFrame.new(0, 0.1 * s, 5.4 * s), GREY, model))

	-- dorsal fin
	add(Build.part({
		Shape = Enum.PartType.Wedge,
		Size = Vector3.new(0.3, 2.6, 2.6) * s,
		CFrame = cf * CFrame.new(0, 2.3 * s, 0.6 * s),
		Color = GREY,
	}, model))

	-- tail lobes
	add(Build.part({
		Size = Vector3.new(0.3, 3.4, 1.2) * s,
		CFrame = cf * CFrame.new(0, 1.2 * s, 7.4 * s) * CFrame.Angles(math.rad(35), 0, 0),
		Color = GREY,
	}, model))
	add(Build.part({
		Size = Vector3.new(0.3, 2, 1) * s,
		CFrame = cf * CFrame.new(0, -0.8 * s, 7.2 * s) * CFrame.Angles(math.rad(-35), 0, 0),
		Color = GREY,
	}, model))

	-- side fins
	for _, side in { -1, 1 } do
		add(Build.part({
			Size = Vector3.new(3, 0.25, 1.6) * s,
			CFrame = cf * CFrame.new(side * 2.3 * s, -0.9 * s, -1 * s) * CFrame.Angles(0, side * 0.4, side * -0.35),
			Color = GREY,
		}, model))
		add(Build.part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.45 * s,
			CFrame = cf * CFrame.new(side * 1.15 * s, 0.4 * s, -4.3 * s),
			Color = Color3.new(0.05, 0.05, 0.05),
		}, model))
	end

	for _, p in parts do
		p.CanCollide = false
		p.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
	end
	root.CanCollide = false
	root.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0)

	local att = Instance.new("Attachment")
	att.Parent = root

	local ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.MaxForce = 1e7
	ap.Responsiveness = 15
	ap.MaxVelocity = Config.SharkPatrolSpeed
	ap.Position = pos
	ap.Parent = root

	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = 1e7
	ao.Responsiveness = 8
	ao.Parent = root

	model.PrimaryPart = root
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
		end
	end
	return model, root, ap, ao
end

local function nearestTarget(pos)
	local bestHum, bestRoot, bestDist = nil, nil, Config.SharkAggroRange
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 and hrp.Position.Y < Config.Surface - 3 then
			local d = (hrp.Position - pos).Magnitude
			if d < bestDist then
				bestHum, bestRoot, bestDist = hum, hrp, d
			end
		end
	end
	return bestHum, bestRoot
end

local function run(model, root, ap, ao)
	local waypoint = randomPatrolPoint()
	local retreatUntil = 0
	local lastBite = 0

	while model.Parent do
		local pos = root.Position
		local now = os.clock()
		local goal, speed

		local hum, hrp
		if now >= retreatUntil then
			hum, hrp = nearestTarget(pos)
		end

		if hum and hrp then
			goal = hrp.Position
			speed = Config.SharkChaseSpeed
			local offset = pos - hrp.Position
			if offset.Magnitude < Config.SharkBiteRange and now - lastBite > Config.SharkBiteCooldown then
				hum:TakeDamage(Config.SharkBiteDamage)
				lastBite = now
				retreatUntil = now + 3
				local away = offset.Magnitude > 0.1 and offset.Unit or Vector3.xAxis
				waypoint = clampGoal(pos + away * 40 + Vector3.new(0, 8, 0))
			end
		else
			if (waypoint - pos).Magnitude < 10 then
				waypoint = randomPatrolPoint()
			end
			goal = waypoint
			speed = now < retreatUntil and Config.SharkChaseSpeed or Config.SharkPatrolSpeed
		end

		goal = clampGoal(goal)
		ap.Position = goal
		ap.MaxVelocity = speed

		local dir = goal - pos
		local flat = Vector3.new(dir.X, dir.Y * 0.4, dir.Z)
		if flat.Magnitude > 1 then
			ao.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit)
		end

		task.wait(0.1)
	end
end

function Sharks.start()
	local folder = Instance.new("Folder")
	folder.Name = "Sharks"
	folder.Parent = workspace

	for _ = 1, Config.SharkCount do
		local spawnAt
		repeat
			spawnAt = randomPatrolPoint()
		until Vector3.new(spawnAt.X, 0, spawnAt.Z).Magnitude > 60

		local model, root, ap, ao = buildShark(spawnAt, rng:NextNumber(0.9, 1.3))
		model.Parent = folder
		root:SetNetworkOwner(nil) -- server controls the sharks
		task.spawn(run, model, root, ap, ao)
	end
end

return Sharks
