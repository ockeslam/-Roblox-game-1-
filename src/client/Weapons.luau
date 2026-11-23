-- Shooting the harpoon: aim with the mouse (or tap), click to fire.
-- Also draws everyone's harpoon shots and your damage numbers.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fireRemote = remotes:WaitForChild("FireHarpoon")
local fxRemote = remotes:WaitForChild("HarpoonFx")

local Weapons = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local hooked = setmetatable({}, { __mode = "k" })
local lastFire = 0
local equipped = 0

local aimParams = RaycastParams.new()
aimParams.FilterType = Enum.RaycastFilterType.Exclude
aimParams.IgnoreWater = true

local function aimPoint()
	local ignore = {}
	if player.Character then
		table.insert(ignore, player.Character)
	end
	for _, name in { "MarineLife", "Coins" } do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(ignore, f)
		end
	end
	aimParams.FilterDescendantsInstances = ignore
	local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, aimParams)
	return hit and hit.Position or (ray.Origin + ray.Direction * 500)
end

local function hookTool(tool)
	if not tool:IsA("Tool") or not tool:GetAttribute("HarpoonId") or hooked[tool] then
		return
	end
	hooked[tool] = true
	tool.Equipped:Connect(function()
		equipped += 1
		mouse.Icon = "rbxasset://textures/GunCursor.png"
	end)
	tool.Unequipped:Connect(function()
		equipped = math.max(0, equipped - 1)
		if equipped == 0 then
			mouse.Icon = ""
		end
	end)
	tool.Activated:Connect(function()
		local def = Config.harpoon(tool:GetAttribute("HarpoonId"))
		local now = os.clock()
		if not def or now - lastFire < def.cooldown then
			return
		end
		lastFire = now
		fireRemote:FireServer(aimPoint())
	end)
end

local function watch(container)
	for _, c in container:GetChildren() do
		hookTool(c)
	end
	container.ChildAdded:Connect(hookTool)
end

-- floating number where the harpoon hit
local function damageNumber(pos, text, colour)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.1
	anchor.CFrame = CFrame.new(pos)
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 40)
	bb.AlwaysOnTop = true
	bb.Adornee = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = colour
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = bb
	bb.Parent = anchor
	TweenService:Create(bb, TweenInfo.new(0.9), { StudsOffset = Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

local function drawShot(shooter, from, to, id, travel)
	local def = Config.harpoon(id) or Config.Harpoons[1]
	local bolt = Instance.new("Part")
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanQuery = false
	bolt.Material = Enum.Material.Neon
	bolt.Color = def.colour
	bolt.Size = Vector3.new(0.25, 0.25, 2.4)
	bolt.CFrame = CFrame.lookAt(from, to)
	bolt.Parent = workspace

	-- a rope from the gun to the harpoon
	local boltAtt = Instance.new("Attachment")
	boltAtt.Position = Vector3.new(0, 0, 1.2)
	boltAtt.Parent = bolt
	local char = shooter and shooter.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	local muzzle = handle and handle:FindFirstChild("Muzzle")
	if muzzle then
		local rope = Instance.new("Beam")
		rope.Attachment0 = muzzle
		rope.Attachment1 = boltAtt
		rope.Width0 = 0.08
		rope.Width1 = 0.08
		rope.Color = ColorSequence.new(Color3.fromRGB(220, 220, 200))
		rope.FaceCamera = true
		rope.Parent = bolt
	end

	local dir = to - from
	local endCF = CFrame.lookAt(to, to + (dir.Magnitude > 0.01 and dir or Vector3.zAxis))
	local tween = TweenService:Create(bolt, TweenInfo.new(math.max(travel, 0.05), Enum.EasingStyle.Linear), { CFrame = endCF })
	tween:Play()
	tween.Completed:Once(function()
		task.wait(0.25)
		bolt:Destroy()
	end)
end

local function drawSplash(pos, radius, id)
	local def = Config.harpoon(id) or Config.Harpoons[1]
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.Material = Enum.Material.Neon
	ball.Color = def.colour
	ball.Transparency = 0.3
	ball.Size = Vector3.one
	ball.CFrame = CFrame.new(pos)
	ball.Parent = workspace
	TweenService:Create(ball, TweenInfo.new(0.4), { Size = Vector3.one * radius * 2, Transparency = 1 }):Play()
	Debris:AddItem(ball, 0.5)
end

function Weapons.start()
	watch(player:WaitForChild("Backpack"))
	player.CharacterAdded:Connect(function(char)
		equipped = 0
		mouse.Icon = ""
		watch(char)
		watch(player:WaitForChild("Backpack"))
	end)
	if player.Character then
		watch(player.Character)
	end

	fxRemote.OnClientEvent:Connect(function(kind, ...)
		if kind == "shot" then
			drawShot(...)
		elseif kind == "hit" then
			local pos, dmg, killed = ...
			damageNumber(pos, killed and ("-" .. dmg .. "  KILL!") or ("-" .. dmg), killed and Color3.fromRGB(255, 220, 60) or Color3.new(1, 1, 1))
		elseif kind == "splash" then
			drawSplash(...)
		end
	end)
end

return Weapons
