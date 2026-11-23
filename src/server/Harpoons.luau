-- Guns: building the tools, shooting (creatures and PvP), and buying from the vending machine.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local Remotes = require(script.Parent.Remotes)
local Creatures = require(script.Parent.Creatures)

local Harpoons = {}

local lastShot = {}

---------------------------------------------------------------- building the guns
-- Every gun points down its -Z axis. The hand holds it at (0, -0.8, 0.5).
local DARK = Color3.fromRGB(45, 50, 60)
local METAL = Color3.fromRGB(80, 85, 95)

local function buildTool(def)
	local tool = Instance.new("Tool")
	tool.Name = def.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = def.rarity .. " · " .. def.damage .. " damage"
	tool:SetAttribute("HarpoonId", def.id)

	local handle = Build.part({
		Name = "Handle",
		Size = Vector3.new(0.6, 0.8, 2.6),
		CFrame = CFrame.new(),
		Color = DARK,
		Material = Enum.Material.Metal,
	}, tool)

	local parts = {}
	local function add(p)
		table.insert(parts, p)
		return p
	end
	local function tube(a, b, thick, colour, mat)
		return add(Build.cylinderBetween(a, b, thick, { Color = colour, Material = mat or Enum.Material.Metal }, tool))
	end
	local function box(size, cf, colour, mat)
		return add(Build.part({ Size = size, CFrame = cf, Color = colour, Material = mat or Enum.Material.Metal }, tool))
	end

	local look = def.look or "harpoon"
	local muzzleZ = -4.8

	if look == "harpoon" then
		tube(Vector3.new(0, 0.25, -1.2), Vector3.new(0, 0.25, -3.4), 0.35, METAL)
		tube(Vector3.new(0, 0.25, -3.4), Vector3.new(0, 0.25, -4.4), 0.15, def.colour, Enum.Material.Neon)
		box(Vector3.new(0.35, 0.35, 0.6), CFrame.new(0, 0.25, -4.6) * CFrame.Angles(0, 0, math.rad(45)), def.colour, Enum.Material.Neon)
	elseif look == "triple" then
		for _, x in { -0.25, 0, 0.25 } do
			tube(Vector3.new(x, 0.25, -1.2), Vector3.new(x, 0.25, -3.6), 0.22, METAL)
			tube(Vector3.new(x, 0.25, -3.6), Vector3.new(x, 0.25, -4.4), 0.1, def.colour, Enum.Material.Neon)
		end
	elseif look == "sonic" then
		tube(Vector3.new(0, 0.25, -1.2), Vector3.new(0, 0.25, -3.2), 0.6, METAL)
		for z = -1.6, -3.0, -0.7 do
			box(Vector3.new(0.9, 0.9, 0.12), CFrame.new(0, 0.25, z), def.colour, Enum.Material.Neon)
		end
		box(Vector3.new(0.7, 0.7, 0.3), CFrame.new(0, 0.25, -3.35), def.colour, Enum.Material.Neon)
		muzzleZ = -3.6
	elseif look == "torpedo" then
		tube(Vector3.new(0, 0.35, -0.5), Vector3.new(0, 0.35, -4), 1.1, Color3.fromRGB(70, 75, 60))
		tube(Vector3.new(0, 0.35, -3.9), Vector3.new(0, 0.35, -4.2), 1.25, def.colour, Enum.Material.Neon)
		box(Vector3.new(0.3, 0.6, 0.6), CFrame.new(0, 1.1, -1.5), METAL)
		muzzleZ = -4.4
	elseif look == "trident" then
		tube(Vector3.new(0, 0.25, -1.2), Vector3.new(0, 0.25, -3.6), 0.25, Color3.fromRGB(200, 170, 80))
		box(Vector3.new(1.4, 0.15, 0.2), CFrame.new(0, 0.25, -3.6), Color3.fromRGB(200, 170, 80))
		for _, x in { -0.6, 0, 0.6 } do
			tube(Vector3.new(x, 0.25, -3.6), Vector3.new(x, 0.25, -4.8), 0.12, def.colour, Enum.Material.Neon)
		end
		muzzleZ = -5
	elseif look == "cannon" then
		tube(Vector3.new(0, 0.3, -0.8), Vector3.new(0, 0.3, -4), 0.9, Color3.fromRGB(40, 30, 50))
		for z = -1.2, -3.6, -1.2 do
			tube(Vector3.new(0, 0.3, z), Vector3.new(0, 0.3, z - 0.2), 1.05, def.colour, Enum.Material.Neon)
		end
		tube(Vector3.new(0, 0.3, -4), Vector3.new(0, 0.3, -4.4), 1.1, def.colour, Enum.Material.Neon)
		muzzleZ = -4.6
	end

	-- grip and glowing side stripes
	box(Vector3.new(0.4, 1.0, 0.5), CFrame.new(0, -0.8, 0.5) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
	for _, side in { -1, 1 } do
		box(Vector3.new(0.05, 0.2, 2), CFrame.new(side * 0.32, 0.1, 0), def.colour, Enum.Material.Neon)
	end

	for _, p in parts do
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = p
		w.Parent = p
	end
	for _, p in tool:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
		end
	end

	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, 0.25, muzzleZ)
	muzzle.Parent = handle

	tool.Grip = CFrame.new(0, -0.8, 0.5)
	return tool
end

local function removeHarpoons(player)
	for _, container in { player:FindFirstChild("Backpack"), player.Character } do
		if container then
			for _, t in container:GetChildren() do
				if t:IsA("Tool") and t:GetAttribute("HarpoonId") then
					t:Destroy()
				end
			end
		end
	end
end

function Harpoons.give(player)
	if not player.Character then
		return
	end
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end
	local def = Config.harpoon(player:GetAttribute("Equipped") or "Basic") or Config.Harpoons[1]
	removeHarpoons(player)
	buildTool(def).Parent = backpack
end

---------------------------------------------------------------- shooting
local shotParams = RaycastParams.new()
shotParams.FilterType = Enum.RaycastFilterType.Exclude
shotParams.IgnoreWater = true

local function playerFromPart(part)
	local model = part:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

local function alivePlayer(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then
		return hum, hrp
	end
	return nil
end

-- PvP hit. Remembers who did it so the kill can be credited.
local function hitPlayer(shooter, victim, damage)
	if not Config.PvP.enabled or victim == shooter then
		return false
	end
	local hum, hrp = alivePlayer(victim)
	local _, shooterRoot = alivePlayer(shooter)
	if not hum or not shooterRoot then
		return false
	end
	if Config.inSafeZone(hrp.Position) or Config.inSafeZone(shooterRoot.Position) then
		return false
	end
	if victim.Character:FindFirstChildOfClass("ForceField") then
		return false
	end
	hum:SetAttribute("LastHitBy", shooter.UserId)
	hum:SetAttribute("LastHitAt", os.clock())
	hum:TakeDamage(damage)
	Remotes.Fx:FireClient(shooter, "hit", hrp.Position, damage, hum.Health <= 0)
	return true
end

local function damageCreature(player, target, damage, pos)
	local killed = Creatures.damage(target, damage, player)
	Remotes.Fx:FireClient(player, "hit", pos, damage, killed)
end

-- one projectile: raycast, aim assist, visuals, then damage when it arrives
local function fireOne(player, def, muzzle, aimDir, creatureDamage, ignore, assist)
	local dir = aimDir * def.range
	shotParams.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(muzzle, dir, shotParams)
	local endPos = hit and hit.Position or (muzzle + dir)
	local target = hit and Creatures.fromPart(hit.Instance)
	local victim = hit and not target and playerFromPart(hit.Instance)

	-- slight aim assist onto creatures (never jellyfish, never players)
	if assist and not target and not victim then
		local best, bestAngle = nil, math.rad(Config.AimAssistDegrees)
		for _, m in Creatures.near(muzzle, def.range) do
			local root = m.PrimaryPart
			if root and m:GetAttribute("Type") ~= "Jelly" then
				local to = root.Position - muzzle
				if to.Magnitude > 0.1 then
					local angle = math.acos(math.clamp(aimDir:Dot(to.Unit), -1, 1))
					if angle < bestAngle then
						best, bestAngle = m, angle
					end
				end
			end
		end
		if best then
			local to = best.PrimaryPart.Position - muzzle
			local check = workspace:Raycast(muzzle, to.Unit * math.min(to.Magnitude + 3, def.range), shotParams)
			if check and Creatures.fromPart(check.Instance) == best then
				endPos = check.Position
				target = best
			end
		end
	end

	local travel = (endPos - muzzle).Magnitude / def.speed
	Remotes.Fx:FireAllClients("shot", player, muzzle, endPos, def.id, travel)

	local pvpDamage = math.max(1, math.floor(def.damage * Config.PvP.damageMult))

	task.delay(travel, function()
		if target then
			damageCreature(player, target, creatureDamage, endPos)
		elseif victim then
			hitPlayer(player, victim, pvpDamage)
		end

		-- lightning chains from the creature it hit to others nearby
		if def.chain and target then
			local hitSet = { [target] = true }
			local from = endPos
			local points = { endPos }
			for _ = 1, def.chain do
				local nextOne, bestDist = nil, 22
				for _, m in Creatures.near(from, 22) do
					if not hitSet[m] and m.PrimaryPart then
						local dist = (m.PrimaryPart.Position - from).Magnitude
						if dist < bestDist then
							nextOne, bestDist = m, dist
						end
					end
				end
				if not nextOne then
					break
				end
				hitSet[nextOne] = true
				from = nextOne.PrimaryPart.Position
				table.insert(points, from)
				damageCreature(player, nextOne, math.max(1, math.floor(creatureDamage * 0.6)), from)
			end
			if #points > 1 then
				Remotes.Fx:FireAllClients("chain", points, def.id)
			end
		end

		-- area damage: creatures and other players
		if def.splash then
			Remotes.Fx:FireAllClients("splash", endPos, def.splash, def.id)
			local splashDamage = math.max(1, math.floor(creatureDamage * 0.5))
			for _, other in Creatures.near(endPos, def.splash) do
				if other ~= target then
					damageCreature(player, other, splashDamage, endPos)
				end
			end
			for _, other in Players:GetPlayers() do
				if other ~= player and other ~= victim then
					local _, hrp = alivePlayer(other)
					if hrp and (hrp.Position - endPos).Magnitude <= def.splash then
						hitPlayer(player, other, math.max(1, math.floor(pvpDamage * 0.5)))
					end
				end
			end
		end
	end)
end

local function onFire(player, aimPoint)
	if typeof(aimPoint) ~= "Vector3" then
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool or not tool:GetAttribute("HarpoonId") then
		return
	end
	local def = Config.harpoon(tool:GetAttribute("HarpoonId"))
	local handle = tool:FindFirstChild("Handle")
	local muzzleAtt = handle and handle:FindFirstChild("Muzzle")
	if not def or not muzzleAtt then
		return
	end

	local now = os.clock()
	if lastShot[player] and now - lastShot[player] < def.cooldown * 0.85 then
		return
	end
	lastShot[player] = now

	local muzzle = muzzleAtt.WorldPosition
	local aim = aimPoint - muzzle
	if aim.Magnitude < 0.1 then
		return
	end
	local aimDir = aim.Unit

	local ignore = { char }
	for _, name in { "Coins", "MarineLife", "Birds" } do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(ignore, f)
		end
	end

	-- creatures get tougher as you level up, so your shots do a bit less to them
	local toughness = Config.difficulty(player:GetAttribute("Level") or 1).health
	local creatureDamage = math.max(1, math.floor(def.damage / toughness + 0.5))

	local pellets = def.pellets or 1
	for i = 1, pellets do
		local dir = aimDir
		if pellets > 1 then
			-- fan the pellets out evenly, with a little randomness
			local spread = math.rad(def.spread or 6)
			local yaw = (i - (pellets + 1) / 2) / math.max(1, (pellets - 1) / 2) * spread
			local pitch = (math.random() - 0.5) * spread * 0.6
			dir = (CFrame.lookAt(Vector3.zero, aimDir) * CFrame.Angles(pitch, yaw, 0)).LookVector
		end
		fireOne(player, def, muzzle, dir, creatureDamage, ignore, i == math.ceil(pellets / 2))
	end
end

---------------------------------------------------------------- buying
local function onBuy(player, id)
	local def = Config.harpoon(id)
	if not def then
		return false, "That gun doesn't exist."
	end
	if not player:GetAttribute("Own_" .. id) then
		if (player:GetAttribute("Level") or 1) < (def.level or 1) then
			return false, "You need to be level " .. def.level .. " for that."
		end
		local stats = player:FindFirstChild("leaderstats")
		local money = stats and stats:FindFirstChild("Money")
		if not money or money.Value < def.price then
			return false, "Not enough money."
		end
		money.Value -= def.price
		player:SetAttribute("Own_" .. id, true)
	end
	player:SetAttribute("Equipped", id)
	return true, "Equipped the " .. def.name .. "!"
end

local function setup(player)
	player.CharacterAdded:Connect(function()
		player:WaitForChild("Backpack")
		task.wait() -- let the new backpack settle
		Harpoons.give(player)
	end)
	player:GetAttributeChangedSignal("Equipped"):Connect(function()
		Harpoons.give(player)
	end)
	if player.Character then
		Harpoons.give(player)
	end
end

function Harpoons.start()
	Remotes.Fire.OnServerEvent:Connect(onFire)
	Remotes.Buy.OnServerInvoke = onBuy
	Players.PlayerAdded:Connect(setup)
	for _, p in Players:GetPlayers() do
		task.spawn(setup, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastShot[p] = nil
	end)
end

return Harpoons
