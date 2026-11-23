-- Blue underwater tint, breathing bubbles, and the darkness (plus a head torch) in The Deep.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Effects = {}

function Effects.start()
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "UnderwaterTint"
	tint.TintColor = Color3.fromRGB(170, 220, 255)
	tint.Saturation = 0.15
	tint.Contrast = 0.05
	tint.Enabled = false
	tint.Parent = Lighting

	local blur = Instance.new("BlurEffect")
	blur.Name = "UnderwaterBlur"
	blur.Size = 3
	blur.Enabled = false
	blur.Parent = Lighting

	local bubbles: ParticleEmitter? = nil
	local headTorch: SpotLight? = nil
	local head: BasePart? = nil

	local function onCharacter(char)
		local h = char:WaitForChild("Head", 10)
		if not h then
			return
		end
		local att = Instance.new("Attachment")
		att.Position = Vector3.new(0, 0, -0.6)
		att.Parent = h

		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(210, 240, 255))
		pe.Size = NumberSequence.new(0.25, 0.4)
		pe.Transparency = NumberSequence.new(0.2, 0.8)
		pe.Lifetime = NumberRange.new(2, 3)
		pe.Rate = 4
		pe.Speed = NumberRange.new(2, 4)
		pe.SpreadAngle = Vector2.new(20, 20)
		pe.Acceleration = Vector3.new(0, 6, 0)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.Enabled = false
		pe.Parent = att

		bubbles, head = pe, h

		-- head torch that switches on in The Deep
		local torch = Instance.new("SpotLight")
		torch.Name = "HeadTorch"
		torch.Face = Enum.NormalId.Front
		torch.Angle = 70
		torch.Range = 45
		torch.Brightness = 3
		torch.Color = Color3.fromRGB(220, 235, 255)
		torch.Enabled = false
		torch.Parent = h
		headTorch = torch
	end

	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	RunService.RenderStepped:Connect(function()
		local camPos = workspace.CurrentCamera.CFrame.Position
		local camY = camPos.Y
		local under = camY < Config.Surface
		tint.Enabled = under
		blur.Enabled = under

		-- The Deep gets darker and bluer the further down you go
		local deep = Config.inDeep(camPos)
		local darkness = deep and math.clamp((20 - camY) / 140, 0, 1) or 0
		tint.Brightness = -0.45 * darkness
		tint.TintColor = Color3.fromRGB(170, 220, 255):Lerp(Color3.fromRGB(90, 120, 255), darkness)
		if headTorch then
			headTorch.Enabled = deep
		end
		if bubbles and head and head.Parent then
			bubbles.Enabled = head.Position.Y < Config.Surface - 1
		end
	end)
end

return Effects
