-- Everything you can hunt: fish, sharks and the giant squid.
-- Each creature has health, a brain (AI loop) and drops coins when it dies.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local Coins = require(script.Parent.Coins)
local Remotes = require(script.Parent.Remotes)

local Creatures = {}

local rng = Random.new()
local S = Config.Surface
local folder
local registry = {} -- model -> record

---------------------------------------------------------------- helpers
local function point(minY, maxY, margin)
	local p = Config.randomInLagoon(rng, margin or 25)
	return Vector3.new(p.X, rng:NextNumber(minY, maxY), p.Z)
end

local function clampGoal(p, minY, maxY)
	local c = Config.clampToLagoon(p, 15)
	return Vector3.new(c.X, math.clamp(c.Y, minY or 6, maxY or S - 5), c.Z)
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
	return b
end

-- A joint the client wiggles (tails, tentacles). yaw/pitch are swing sizes in radians.
local function wiggleJoint(p0, p1, jointCF, yaw, pitch, speed, phase)
	local m = Instance.new("Motor6D")
	m.Name = "Wiggle"
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = p0.CFrame:ToObjectSpace(jointCF)
	m.C1 = p1.CFrame:ToObjectSpace(jointCF)
	m:SetAttribute("Yaw", yaw)
	m:SetAttribute("Pitch", pitch)
	m:SetAttribute("Speed", speed)
	m:SetAttribute("Phase", phase)
	m.Parent = p0
	return m
end

-- Players who are alive and under the water.
local function divers()
	local list = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 and hrp.Position.Y < S - 3 then
			table.insert(list, { player = player, hum = hum, hrp = hrp })
		end
	end
	return list
end

local function diverOf(player)
	if not player or not player.Parent then
		return nil
	end
	for _, d in divers() do
		if d.player == player then
			return d
		end
	end
	return nil
end

local function nearestDiver(pos, range)
	local best, bestDist = nil, range
	for _, d in divers() do
		local dist = (d.hrp.Position - pos).Magnitude
		if dist < bestDist then
			best, bestDist = d, dist
		end
	end
	return best
end

local function steer(rec, goal, speed)
	rec.ap.Position = goal
	rec.ap.MaxVelocity = speed
	local dir = goal - rec.root.Position
	local flat = Vector3.new(dir.X, dir.Y * 0.4, dir.Z)
	if flat.Magnitude > 1 then
		rec.ao.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit)
	end
end

local function alive(rec)
	return not rec.dead and rec.model.Parent ~= nil
end

---------------------------------------------------------------- models (all face -Z)
local BLACK = Color3.new(0.05, 0.05, 0.05)

local function buildFish(pos, def)
	local model = Instance.new("Model")
	local b = def.body * rng:NextNumber(0.9, 1.15)
	local root = Build.ellipsoid(b, CFrame.new(pos), def.colours[1], model, { Name = "Body" })
	local cf = root.CFrame

	weld(root, Build.ellipsoid(Vector3.new(b.X * 0.85, b.Y * 0.6, b.Z * 0.85), cf * CFrame.new(0, -b.Y * 0.2, 0), def.colours[2], model))
	weld(root, Build.part({
		Shape = Enum.PartType.Wedge,
		Size = Vector3.new(0.15, b.Y * 0.5, b.Z * 0.4),
		CFrame = cf * CFrame.new(0, b.Y * 0.55, b.Z * 0.05),
		Color = def.colours[1],
	}, model))
	for _, side in { -1, 1 } do
		weld(root, Build.part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * b.Y * 0.18,
			CFrame = cf * CFrame.new(side * b.X * 0.42, b.Y * 0.12, -b.Z * 0.33),
			Color = BLACK,
		}, model))
	end

	local jointCF = cf * CFrame.new(0, 0, b.Z * 0.45)
	local tail = Build.part({
		Size = Vector3.new(0.12, b.Y * 0.9, b.Z * 0.3),
		CFrame = jointCF * CFrame.new(0, 0, b.Z * 0.15),
		Color = def.colours[2],
	}, model)
	wiggleJoint(root, tail, jointCF, 0.5, 0, 8, rng:NextNumber(0, 6))
	return model, root, b.Y + 1
end

local GREY = Color3.fromRGB(105, 120, 135)
local BELLY = Color3.fromRGB(215, 220, 225)

local function buildShark(pos)
	local model = Instance.new("Model")
	local s = rng:NextNumber(0.9, 1.3)
	local root = Build.ellipsoid(Vector3.new(3.2, 3, 12) * s, CFrame.new(pos), GREY, model, { Name = "Body" })
	local cf = root.CFrame

	weld(root, Build.ellipsoid(Vector3.new(2.6, 2.2, 10) * s, cf * CFrame.new(0, -0.5 * s, 0.2 * s), BELLY, model))
	weld(root, Build.part({
		Shape = Enum.PartType.Wedge,
		Size = Vector3.new(0.3, 2.6, 2.6) * s,
		CFrame = cf * CFrame.new(0, 2.3 * s, 0.6 * s),
		Color = GREY,
	}, model))
	weld(root, Build.part({
		Size = Vector3.new(1.6, 0.15, 1) * s,
		CFrame = cf * CFrame.new(0, -0.9 * s, -4.4 * s),
		Color = Color3.fromRGB(90, 30, 35),
	}, model))
	for _, side in { -1, 1 } do
		weld(root, Build.part({
			Size = Vector3.new(3, 0.25, 1.6) * s,
			CFrame = cf * CFrame.new(side * 2.3 * s, -0.9 * s, -1 * s) * CFrame.Angles(0, side * 0.4, side * -0.35),
			Color = GREY,
		}, model))
		weld(root, Build.part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.45 * s,
			CFrame = cf * CFrame.new(side * 1.15 * s, 0.4 * s, -4.3 * s),
			Color = BLACK,
		}, model))
	end

	-- tail on a joint
	local jointCF = cf * CFrame.new(0, 0.1 * s, 3.3 * s)
	local stalk = Build.ellipsoid(Vector3.new(1.4, 1.6, 4.5) * s, jointCF * CFrame.new(0, 0, 2.1 * s), GREY, model)
	wiggleJoint(root, stalk, jointCF, 0.3, 0, 3.5, rng:NextNumber(0, 6))
	weld(stalk, Build.part({
		Size = Vector3.new(0.3, 3.4, 1.2) * s,
		CFrame = cf * CFrame.new(0, 1.2 * s, 7.4 * s) * CFrame.Angles(math.rad(35), 0, 0),
		Color = GREY,
	}, model))
	weld(stalk, Build.part({
		Size = Vector3.new(0.3, 2, 1) * s,
		CFrame = cf * CFrame.new(0, -0.8 * s, 7.2 * s) * CFrame.Angles(math.rad(-35), 0, 0),
		Color = GREY,
	}, model))
	return model, root, 4 * s
end

local function chain(model, parentPart, start, dir, count, segLen, thick, colour, phase)
	local prev, joint = parentPart, start
	for k = 1, count do
		local finish = joint + dir * segLen
		local seg = Build.cylinderBetween(joint, finish, thick * (1 - (k - 1) / count * 0.55), { Color = colour }, model)
		wiggleJoint(prev, seg, CFrame.lookAt(joint, finish), 0.25, 0.25, 2, phase + k * 0.8)
		prev, joint = seg, finish
	end
	return prev, joint
end

local function buildSquid(pos)
	local model = Instance.new("Model")
	local red, pale = Color3.fromRGB(150, 35, 60), Color3.fromRGB(205, 95, 115)

	-- the pointed mantle leads (-Z), arms trail behind (+Z)
	local root = Build.ellipsoid(Vector3.new(7, 7, 20), CFrame.new(pos), red, model, { Name = "Mantle" })
	local cf = root.CFrame
	for _, side in { -1, 1 } do
		weld(root, Build.ellipsoid(Vector3.new(9, 0.6, 6), cf * CFrame.new(side * 4, 0, -6) * CFrame.Angles(0, side * 0.3, 0), pale, model))
	end
	local head = weld(root, Build.ellipsoid(Vector3.new(6.5, 6, 6), cf * CFrame.new(0, 0, 11.5), red, model, { Name = "Head" }))
	for _, side in { -1, 1 } do
		local eye = weld(root, Build.part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 2.4,
			CFrame = cf * CFrame.new(side * 2.9, 0.8, 11.5),
			Color = Color3.fromRGB(255, 210, 60),
			Material = Enum.Material.Neon,
		}, model))
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 120, 60)
		light.Range = 14
		light.Brightness = 2
		light.Parent = eye
		weld(root, Build.part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.1,
			CFrame = cf * CFrame.new(side * 3.85, 0.8, 11.5),
			Color = BLACK,
		}, model))
	end

	local ringCentre = cf * CFrame.new(0, 0, 14)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		local start = (ringCentre * CFrame.new(math.cos(a) * 2.2, math.sin(a) * 2.2, 0)).Position
		local dir = cf:VectorToWorldSpace(Vector3.new(math.cos(a) * 0.3, math.sin(a) * 0.3, 1).Unit)
		chain(model, head, start, dir, 3, 4, 1.1, red, i)
	end
	for _, side in { -1, 1 } do
		local start = (ringCentre * CFrame.new(side * 1.2, -1, 0)).Position
		local dir = cf:VectorToWorldSpace(Vector3.new(side * 0.12, -0.1, 1).Unit)
		local last, tip = chain(model, head, start, dir, 5, 4.5, 0.6, pale, side * 3)
		weld(last, Build.ellipsoid(Vector3.new(1.4, 0.8, 3), CFrame.lookAt(tip, tip + dir) * CFrame.new(0, 0, -1.3), red, model))
	end

	-- ink cloud for when it gets hurt or after it strikes
	local att = Instance.new("Attachment")
	att.Name = "InkAtt"
	att.Parent = root
	local ink = Instance.new("ParticleEmitter")
	ink.Name = "Ink"
	ink.Texture = "rbxasset://textures/particles/smoke_main.dds"
	ink.Color = ColorSequence.new(Color3.fromRGB(10, 5, 20))
	ink.Size = NumberSequence.new(6, 16)
	ink.Transparency = NumberSequence.new(0.1, 1)
	ink.Lifetime = NumberRange.new(3, 5)
	ink.Speed = NumberRange.new(4, 9)
	ink.SpreadAngle = Vector2.new(180, 180)
	ink.Drag = 2
	ink.Rate = 0
	ink.Parent = att

	return model, root, 9
end

local function buildJelly(pos, def)
	local model = Instance.new("Model")
	local colour = def.colours[rng:NextInteger(1, #def.colours)]
	local s = rng:NextNumber(0.8, 1.3)
	local root = Build.ellipsoid(Vector3.new(3, 2, 3) * s, CFrame.new(pos), colour, model, {
		Name = "Bell",
		Transparency = 0.35,
		Material = Enum.Material.Glass,
	})
	weld(root, Build.ellipsoid(Vector3.new(1.8, 1.1, 1.8) * s, CFrame.new(pos + Vector3.new(0, -0.1, 0)), colour, model, {
		Material = Enum.Material.Neon,
		Transparency = 0.4,
	}))
	local light = Instance.new("PointLight")
	light.Color = colour
	light.Range = 9
	light.Brightness = 1.2
	light.Parent = root

	-- tentacles hang down and wave about
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local start = pos + Vector3.new(math.cos(a) * 0.9 * s, -0.5 * s, math.sin(a) * 0.9 * s)
		local dir = Vector3.new(math.cos(a) * 0.08, -1, math.sin(a) * 0.08).Unit
		local prev, joint = root, start
		for k = 1, 3 do
			local finish = joint + dir * 1.4 * s
			local seg = Build.cylinderBetween(joint, finish, 0.14, {
				Color = colour,
				Material = Enum.Material.Neon,
				Transparency = 0.35,
			}, model)
			wiggleJoint(prev, seg, CFrame.lookAt(joint, finish), 0.3, 0.3, 1.5, i + k * 0.6)
			prev, joint = seg, finish
		end
	end
	return model, root, 2.5 * s
end

local BUILDERS = { Fish = buildFish, Shark = buildShark, Squid = buildSquid, Jelly = buildJelly }

local function finish(model, root)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanTouch = false
			if p ~= root then
				p.Massless = true
			end
		end
	end
	root.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0)

	local att = Instance.new("Attachment")
	att.Parent = root
	local ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.MaxForce = 1e7
	ap.Responsiveness = 15
	ap.Position = root.Position
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
	return ap, ao
end

local function healthBar(root, height)
	local bb = Instance.new("BillboardGui")
	bb.Name = "HealthBar"
	bb.Size = UDim2.fromOffset(90, 10)
	bb.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	bb.MaxDistance = 150
	bb.Enabled = false
	bb.Adornee = root
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	bg.BorderSizePixel = 0
	bg.Parent = bb
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	fill.BorderSizePixel = 0
	fill.Parent = bg
	bb.Parent = root
	return bb, fill
end

---------------------------------------------------------------- brains
local function fishBrain(rec)
	local def = rec.def
	local home = rec.root.Position
	local waypoint = home
	while alive(rec) do
		local pos = rec.root.Position
		local now = os.clock()
		local threat = nearestDiver(pos, 20)
		local goal, speed
		if threat or now - rec.hurtAt < 3 then
			local attacker = diverOf(rec.attacker)
			local from = (threat and threat.hrp.Position) or (attacker and attacker.hrp.Position) or (pos + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)))
			local away = pos - from
			if away.Magnitude < 0.1 then
				away = Vector3.xAxis
			end
			goal = pos + away.Unit * 25
			speed = def.fleeSpeed
		else
			if (waypoint - pos).Magnitude < 5 then
				waypoint = clampGoal(home + Vector3.new(rng:NextNumber(-30, 30), rng:NextNumber(-6, 8), rng:NextNumber(-30, 30)), 5, S - 4)
			end
			goal = waypoint
			speed = def.speed
		end
		steer(rec, clampGoal(goal, 5, S - 4), speed)
		task.wait(0.15)
	end
end

local function sharkBrain(rec)
	local def = rec.def
	local waypoint = point(18, S - 12)
	local retreatUntil, lastBite = 0, 0
	while alive(rec) do
		local pos = rec.root.Position
		local now = os.clock()
		local target
		if now >= retreatUntil then
			-- whoever shot it recently gets hunted from further away
			if rec.attacker and now - rec.hurtAt < 8 then
				target = diverOf(rec.attacker)
			end
			target = target or nearestDiver(pos, def.aggroRange)
		end

		local goal, speed
		if target then
			goal, speed = target.hrp.Position, def.chaseSpeed
			local offset = pos - target.hrp.Position
			if offset.Magnitude < def.biteRange and now - lastBite > def.biteCooldown then
				target.hum:TakeDamage(def.biteDamage)
				lastBite = now
				retreatUntil = now + 3
				local away = offset.Magnitude > 0.1 and offset.Unit or Vector3.xAxis
				waypoint = clampGoal(pos + away * 40 + Vector3.new(0, 8, 0))
			end
		else
			if (waypoint - pos).Magnitude < 10 then
				waypoint = point(18, S - 12)
			end
			goal = waypoint
			speed = now < retreatUntil and def.chaseSpeed or def.speed
		end
		steer(rec, clampGoal(goal), speed)
		task.wait(0.1)
	end
end

-- The squid lurks deep, now and then picks a diver, follows them from behind
-- for a while, then charges. After striking (or getting badly hurt) it inks and retreats.
local function squidBrain(rec)
	local def = rec.def
	local state = "lurk"
	local nextHunt = os.clock() + rng:NextNumber(def.firstStalk[1], def.firstStalk[2])
	local waypoint = point(8, 22, 40)
	local target = nil
	local stateEnds, lastHit = 0, 0
	local ink = rec.root:FindFirstChild("InkAtt") and rec.root.InkAtt:FindFirstChild("Ink")

	-- a storm rolls in while the squid is hunting (clients handle the weather)
	local function setStorm(on)
		if (workspace:GetAttribute("Storm") == true) ~= on then
			workspace:SetAttribute("Storm", on)
			if on then
				Remotes.Announce:FireAllClients("The sky darkens... the Giant Squid is hunting.")
			end
		end
	end

	local function setTarget(player)
		if target and target ~= player and target.Parent then
			target:SetAttribute("Stalked", nil)
		end
		target = player
		if player then
			player:SetAttribute("Stalked", true)
			setStorm(true)
		end
	end

	local function retreat(now)
		state = "retreat"
		stateEnds = now + 7
		local pos = rec.root.Position
		local p = point(8, 20, 40)
		for _ = 1, 10 do
			if (p - pos).Magnitude > 80 then
				break
			end
			p = point(8, 20, 40)
		end
		waypoint = p
		setTarget(nil)
		nextHunt = now + rng:NextNumber(def.stalkGap[1], def.stalkGap[2])
	end

	while alive(rec) do
		local pos = rec.root.Position
		local now = os.clock()
		local goal, speed = waypoint, def.speed
		local d = target and diverOf(target)

		if (state == "stalk" or state == "charge") and not d then
			retreat(now) -- they got out of the water or died
		end

		if state == "lurk" then
			if (waypoint - pos).Magnitude < 10 then
				waypoint = point(8, 22, 40)
			end
			goal = waypoint
			if rec.attacker and now - rec.hurtAt < 1 and diverOf(rec.attacker) then
				setTarget(rec.attacker)
				state, stateEnds = "charge", now + 5
			elseif now >= nextHunt then
				local list = divers()
				if #list > 0 then
					setTarget(list[rng:NextInteger(1, #list)].player)
					state, stateEnds = "stalk", now + rng:NextNumber(15, 25)
				else
					nextHunt = now + 10
				end
			end
		elseif state == "stalk" and d then
			local look = d.hrp.CFrame.LookVector
			local back = Vector3.new(look.X, 0, look.Z)
			back = back.Magnitude > 0.1 and back.Unit or Vector3.zAxis
			goal = d.hrp.Position - back * 30 + Vector3.new(0, -7, 0)
			speed = def.stalkSpeed
			if now >= stateEnds or now - rec.hurtAt < 0.5 then
				state, stateEnds = "charge", now + 5
			end
		elseif state == "charge" and d then
			goal, speed = d.hrp.Position, def.chargeSpeed
			if (d.hrp.Position - pos).Magnitude < def.reach and now - lastHit > 1.5 then
				d.hum:TakeDamage(def.damage)
				lastHit = now
				if ink then
					ink:Emit(60)
				end
				retreat(now)
			elseif now >= stateEnds then
				retreat(now)
			end
		elseif state == "retreat" then
			goal, speed = waypoint, def.chargeSpeed * 0.8
			if now >= stateEnds then
				state = "lurk"
				setStorm(false)
			end
		end

		if not rec.inked and rec.health < def.health * 0.35 then
			rec.inked = true
			if ink then
				ink:Emit(100)
			end
			retreat(now)
		end

		steer(rec, clampGoal(goal, 6, S - 6), speed)
		task.wait(0.1)
	end
	setTarget(nil)
	setStorm(false)
end

local function sting(d, amount)
	d.hum:TakeDamage(amount)
	Remotes.Fx:FireClient(d.player, "sting", d.hrp.Position)
end

-- Jellyfish drift slowly and bob. Swim into the tentacles and you get stung.
local function jellyBrain(rec)
	local def = rec.def
	local home = rec.root.Position
	local waypoint = home
	local lastSting = {}
	local phase = rng:NextNumber(0, math.pi * 2)
	while alive(rec) do
		local pos = rec.root.Position
		local now = os.clock()
		if (waypoint - pos).Magnitude < 3 then
			waypoint = clampGoal(home + Vector3.new(rng:NextNumber(-25, 25), rng:NextNumber(-8, 8), rng:NextNumber(-25, 25)), 10, S - 8)
		end
		local bob = Vector3.new(0, math.sin(now * 0.8 + phase) * 1.5, 0)
		rec.ap.Position = clampGoal(waypoint + bob, 10, S - 6)
		rec.ap.MaxVelocity = def.speed
		rec.ao.CFrame = CFrame.Angles(math.sin(now * 0.5 + phase) * 0.12, 0, math.cos(now * 0.4 + phase) * 0.12)

		-- the stinging bit is the bell and the tentacles just under it
		local stingPoint = pos + Vector3.new(0, -2, 0)
		for _, d in divers() do
			if (d.hrp.Position - stingPoint).Magnitude < def.stingRange then
				local last = lastSting[d.player]
				if not last or now - last > def.stingCooldown then
					lastSting[d.player] = now
					sting(d, def.sting)
				end
			end
		end
		task.wait(0.15)
	end
end

local BRAINS = { Fish = fishBrain, Shark = sharkBrain, Squid = squidBrain, Jelly = jellyBrain }

---------------------------------------------------------------- spawning
local function spawnPoint(def)
	if def.type == "Jelly" then
		local p = Config.randomInLagoon(rng, 40)
		return Vector3.new(p.X, rng:NextNumber(25, S - 15), p.Z)
	end
	if def.type == "Fish" then
		local centres = Config.reefCenters()
		local c = centres[rng:NextInteger(1, #centres)]
		return Vector3.new(c.X + rng:NextNumber(-20, 20), rng:NextNumber(10, 28), c.Z + rng:NextNumber(-20, 20))
	end
	local p = point(18, S - 12)
	for _ = 1, 20 do
		if Vector3.new(p.X, 0, p.Z).Magnitude > 70 then
			break
		end
		p = point(18, S - 12)
	end
	if def.type == "Squid" then
		p = Vector3.new(p.X, 14, p.Z)
	end
	return p
end

function Creatures.spawn(kind)
	local def = Config.Creatures[kind]
	if not def or not folder then
		return
	end
	local model, root, barHeight = BUILDERS[def.type](spawnPoint(def), def)
	model.Name = kind
	local ap, ao = finish(model, root)
	local bb, fill = healthBar(root, barHeight)

	model:SetAttribute("Kind", kind)
	model:SetAttribute("Type", def.type)
	model:SetAttribute("Health", def.health)
	model:SetAttribute("MaxHealth", def.health)
	CollectionService:AddTag(model, "Creature")
	model.Parent = folder
	root:SetNetworkOwner(nil) -- the server drives creatures

	local rec = {
		kind = kind,
		def = def,
		model = model,
		root = root,
		ap = ap,
		ao = ao,
		billboard = bb,
		bar = fill,
		health = def.health,
		hurtAt = 0,
		attacker = nil,
		dead = false,
	}
	registry[model] = rec
	task.spawn(BRAINS[def.type], rec)

	if def.type == "Squid" then
		Remotes.Announce:FireAllClients("Something huge stirs in the deep...")
	end
end

-- Returns true if this hit killed it.
function Creatures.damage(model, amount, player)
	local rec = registry[model]
	if not rec or rec.dead then
		return false
	end
	-- shooting a jellyfish zaps you through the harpoon line
	if rec.def.type == "Jelly" and player and player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 then
			sting({ player = player, hum = hum, hrp = hrp }, rec.def.shootSting)
		end
	end

	rec.health -= amount
	rec.hurtAt = os.clock()
	rec.attacker = player
	model:SetAttribute("Health", math.max(0, rec.health))
	rec.bar.Size = UDim2.fromScale(math.clamp(rec.health / rec.def.health, 0, 1), 1)
	rec.billboard.Enabled = true

	if rec.health <= 0 then
		rec.dead = true
		registry[model] = nil
		Coins.drop(rec.root.Position, rec.def.reward)
		if rec.def.type == "Squid" then
			local who = player and player.DisplayName or "Someone"
			Remotes.Announce:FireAllClients(who .. " slew the Giant Squid!")
		end
		model:Destroy()
		task.delay(rec.def.respawn, Creatures.spawn, rec.kind)
		return true
	end
	return false
end

function Creatures.fromPart(part)
	local node = part
	while node and node ~= workspace do
		if node:IsA("Model") and registry[node] then
			return node
		end
		node = node.Parent
	end
	return nil
end

function Creatures.near(pos, radius)
	local list = {}
	for model, rec in registry do
		if not rec.dead and (rec.root.Position - pos).Magnitude <= radius then
			table.insert(list, model)
		end
	end
	return list
end

function Creatures.start()
	folder = Instance.new("Folder")
	folder.Name = "Creatures"
	folder.Parent = workspace
	for kind, def in Config.Creatures do
		for _ = 1, def.count do
			Creatures.spawn(kind)
		end
	end
end

return Creatures
