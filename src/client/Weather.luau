-- The storm that rolls in while the Giant Squid is hunting:
-- dark sky, thick clouds, choppy water, rain, lightning, thunder and a creepy drone.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sounds = require(script.Parent:WaitForChild("Sounds"))

local Weather = {}

local S = Config.Surface
local terrain = workspace.Terrain
local FADE = TweenInfo.new(6, Enum.EasingStyle.Sine)

local calm, stormy = {}, {}
local storming = false
local rain: ParticleEmitter
local rainPart: BasePart
local flash: ColorCorrectionEffect
local drone: Sound?

local function snapshot()
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	local clouds = terrain:FindFirstChildOfClass("Clouds")
	calm = {
		lighting = {
			Brightness = Lighting.Brightness,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
		},
		atmosphere = atm and { Density = atm.Density, Color = atm.Color, Decay = atm.Decay, Haze = atm.Haze, Glare = atm.Glare },
		clouds = clouds and { Cover = clouds.Cover, Density = clouds.Density, Color = clouds.Color },
		water = {
			WaterWaveSize = terrain.WaterWaveSize,
			WaterWaveSpeed = terrain.WaterWaveSpeed,
			WaterColor = terrain.WaterColor,
			WaterTransparency = terrain.WaterTransparency,
		},
	}
	stormy = {
		lighting = {
			Brightness = 0.8,
			Ambient = Color3.fromRGB(35, 40, 55),
			OutdoorAmbient = Color3.fromRGB(70, 75, 90),
		},
		atmosphere = { Density = 0.5, Color = Color3.fromRGB(100, 105, 120), Decay = Color3.fromRGB(50, 55, 70), Haze = 3, Glare = 0 },
		clouds = { Cover = 0.95, Density = 0.9, Color = Color3.fromRGB(70, 72, 82) },
		water = {
			WaterWaveSize = 1, -- the biggest waves Roblox allows
			WaterWaveSpeed = 55,
			WaterColor = Color3.fromRGB(20, 65, 85),
			WaterTransparency = 0.6, -- murkier underwater
		},
	}
end

local function apply(set)
	TweenService:Create(Lighting, FADE, set.lighting):Play()
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm and set.atmosphere then
		TweenService:Create(atm, FADE, set.atmosphere):Play()
	end
	local clouds = terrain:FindFirstChildOfClass("Clouds")
	if clouds and set.clouds then
		TweenService:Create(clouds, FADE, set.clouds):Play()
	end
	TweenService:Create(terrain, FADE, set.water):Play()
end

-- a jagged bolt from the sky down to the sea, plus a flash and thunder
local function lightning()
	local a = math.random() * math.pi * 2
	local d = 150 + math.random() * 550
	local x, z = math.cos(a) * d, math.sin(a) * d
	local top = Vector3.new(x, S + 320, z)
	local points = { top }
	local segments = 10
	for i = 1, segments do
		local f = i / segments
		local jitter = i < segments and Vector3.new((math.random() - 0.5) * 30, 0, (math.random() - 0.5) * 30) or Vector3.zero
		table.insert(points, Vector3.new(x, S + 320 * (1 - f), z) + jitter)
	end
	local bolt = Instance.new("Model")
	bolt.Name = "Lightning"
	for i = 1, #points - 1 do
		local p0, p1 = points[i], points[i + 1]
		local seg = Instance.new("Part")
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CastShadow = false
		seg.Material = Enum.Material.Neon
		seg.Color = Color3.fromRGB(220, 230, 255)
		seg.Size = Vector3.new(1.2, 1.2, (p1 - p0).Magnitude)
		seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		seg.Parent = bolt
	end
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 8
	light.Color = Color3.fromRGB(200, 215, 255)
	light.Parent = bolt:GetChildren()[segments]
	bolt.Parent = workspace
	Debris:AddItem(bolt, 0.25)

	local under = workspace.CurrentCamera.CFrame.Position.Y < S
	flash.Brightness = under and 0.15 or 0.6
	TweenService:Create(flash, TweenInfo.new(0.35), { Brightness = 0 }):Play()

	-- thunder arrives a bit later the further away the strike was
	task.delay(d / 900, function()
		Sounds.play("Thunder", 0.3)
	end)
end

local function startStorm()
	if storming then
		return
	end
	storming = true
	apply(stormy)
	Sounds.play("SquidSting")
	drone = Sounds.make("SquidDrone", true)
	if drone then
		local target = drone.Volume
		drone.Volume = 0
		drone:Play()
		TweenService:Create(drone, FADE, { Volume = target }):Play()
	end
	local rainSound = Sounds.make("Rain", true)
	if rainSound then
		rainSound.Name = "StormRain"
		rainSound:Play()
	end

	task.spawn(function()
		task.wait(2)
		while storming do
			lightning()
			task.wait(3 + math.random() * 7)
		end
	end)
end

local function stopStorm()
	if not storming then
		return
	end
	storming = false
	apply(calm)
	if drone then
		local d = drone
		drone = nil
		TweenService:Create(d, FADE, { Volume = 0 }):Play()
		Debris:AddItem(d, 7)
	end
	local SoundService = game:GetService("SoundService")
	local r = SoundService:FindFirstChild("StormRain")
	if r then
		r:Destroy()
	end
end

function Weather.start()
	snapshot()

	flash = Instance.new("ColorCorrectionEffect")
	flash.Name = "LightningFlash"
	flash.Parent = Lighting

	-- rain falls from a big invisible sheet that follows the camera
	rainPart = Instance.new("Part")
	rainPart.Name = "RainSheet"
	rainPart.Anchored = true
	rainPart.CanCollide = false
	rainPart.CanQuery = false
	rainPart.Transparency = 1
	rainPart.Size = Vector3.new(140, 1, 140)
	rainPart.Parent = workspace
	rain = Instance.new("ParticleEmitter")
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Color = ColorSequence.new(Color3.fromRGB(200, 210, 225))
	rain.Transparency = NumberSequence.new(0.35)
	rain.Size = NumberSequence.new(0.12)
	rain.Squash = NumberSequence.new(3)
	rain.Lifetime = NumberRange.new(0.8, 1)
	rain.Speed = NumberRange.new(90, 110)
	rain.Orientation = Enum.ParticleOrientation.VelocityParallel
	rain.Rate = 0
	rain.LightInfluence = 1
	rain.Parent = rainPart

	RunService.RenderStepped:Connect(function()
		local camPos = workspace.CurrentCamera.CFrame.Position
		rainPart.CFrame = CFrame.new(camPos.X, math.max(camPos.Y, S) + 50, camPos.Z)
		-- no rain underwater
		rain.Rate = (storming and camPos.Y > S - 1) and 900 or 0
	end)

	workspace:GetAttributeChangedSignal("Storm"):Connect(function()
		if workspace:GetAttribute("Storm") then
			startStorm()
		else
			stopStorm()
		end
	end)
	if workspace:GetAttribute("Storm") then
		startStorm()
	end
end

return Weather
