-- Harpoon guns: building the tools, shooting, and buying from the vending machine.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local Remotes = require(script.Parent.Remotes)
local Creatures = require(script.Parent.Creatures)

local Harpoons = {}

local lastShot = {}

-- The gun points down its -Z axis.
local function buildTool(def)
	local tool = Instance.new("Tool")
	tool.Name = def.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = def.rarity .. " · " .. def.damage .. " damage"
	tool:SetAttribute("HarpoonId", def.id)

	local dark = Color3.fromRGB(45, 50, 60)
	local handle = Build.part({
		Name = "Handle",
		Size = Vector3.new(0.6, 0.8, 2.6),
		CFrame = CFrame.new(),
		Color = dark,
		Material = Enum.Material.Metal,
	}, tool)

	local parts = {}
	local function add(p)
		table.insert(parts, p)
	end
	add(Build.cylinderBetween(Vector3.new(0, 0.25, -1.2), Vector3.new(0, 0.25, -3.4), 0.35, {
		Color = Color3.fromRGB(80, 85, 95),
		Material = Enum.Material.Metal,
	}, tool))
	add(Build.cylinderBetween(Vector3.new(0, 0.25, -3.4), Vector3.new(0, 0.25, -4.4), 0.15, {
		Color = def.colour,
		Material = Enum.Material.Neon,
	}, tool))
	add(Build.part({
		Size = Vector3.new(0.35, 0.35, 0.6),
		CFrame = CFrame.new(0, 0.25, -4.6) * CFrame.Angles(0, 0, math.rad(45)),
		Color = def.colour,
		Material = Enum.Material.Neon,
	}, tool))
	add(Build.part({
		Size = Vector3.new(0.4, 1.0, 0.5),
		CFrame = CFrame.new(0, -0.8, 0.5) * CFrame.Angles(math.rad(-15), 0, 0),
		Color = Color3.fromRGB(110, 75, 45),
		Material = Enum.Material.Wood,
	}, tool))
	for _, side in { -1, 1 } do
		add(Build.part({
			Size = Vector3.new(0.05, 0.2, 2),
			CFrame = CFrame.new(side * 0.32, 0.1, 0),
			Color = def.colour,
			Material = Enum.Material.Neon,
		}, tool))
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
	muzzle.Position = Vector3.new(0, 0.25, -4.8)
	muzzle.Parent = handle

	-- where the hand holds it
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

local shotParams = RaycastParams.new()
shotParams.FilterType = Enum.RaycastFilterType.Exclude
shotParams.IgnoreWater = true

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
	local dir = aim.Unit * def.range

	local ignore = { char }
	for _, name in { "Coins", "MarineLife" } do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(ignore, f)
		end
	end
	shotParams.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(muzzle, dir, shotParams)
	local endPos = hit and hit.Position or (muzzle + dir)
	local target = hit and Creatures.fromPart(hit.Instance)
	local travel = (endPos - muzzle).Magnitude / def.speed

	Remotes.Fx:FireAllClients("shot", player, muzzle, endPos, def.id, travel)

	task.delay(travel, function()
		if target then
			local killed = Creatures.damage(target, def.damage, player)
			Remotes.Fx:FireClient(player, "hit", endPos, def.damage, killed)
		end
		if def.splash then
			Remotes.Fx:FireAllClients("splash", endPos, def.splash, def.id)
			for _, other in Creatures.near(endPos, def.splash) do
				if other ~= target then
					local killed = Creatures.damage(other, math.floor(def.damage * 0.5), player)
					Remotes.Fx:FireClient(player, "hit", endPos, math.floor(def.damage * 0.5), killed)
				end
			end
		end
	end)
end

local function onBuy(player, id)
	local def = Config.harpoon(id)
	if not def then
		return false, "That harpoon doesn't exist."
	end
	if not player:GetAttribute("Own_" .. id) then
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
