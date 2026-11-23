-- Oxygen bar, pearl pop-ups, damage flash and the intro tip.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hud = {}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

function Hud.start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "ReefHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- oxygen bar
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -100)
	bar.Size = UDim2.fromOffset(260, 16)
	bar.BackgroundColor3 = Color3.fromRGB(10, 30, 45)
	bar.BackgroundTransparency = 0.3
	corner(bar, 8)
	bar.Parent = gui

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 210, 255)
	corner(fill, 8)
	fill.Parent = bar

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 0, -2)
	label.Size = UDim2.fromOffset(200, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Text = "OXYGEN"
	label.Parent = bar

	local function updateOxygen()
		local o = player:GetAttribute("Oxygen") or 100
		fill.Size = UDim2.fromScale(math.max(o, 0) / 100, 1)
		fill.BackgroundColor3 = o < 25 and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(90, 210, 255)
		label.Text = o < 25 and "OXYGEN LOW - SWIM UP!" or "OXYGEN"
	end
	player:GetAttributeChangedSignal("Oxygen"):Connect(updateOxygen)
	updateOxygen()

	-- red flash when hurt
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	flash.BackgroundTransparency = 1
	flash.ZIndex = 10
	flash.Parent = gui

	local function onCharacter(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then
			return
		end
		local last = hum.Health
		hum.HealthChanged:Connect(function(h)
			if h < last - 1 then
				flash.BackgroundTransparency = 0.55
				TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
			end
			last = h
		end)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	-- "+1 Pearl" pop-up
	task.spawn(function()
		local stats = player:WaitForChild("leaderstats", 30)
		local pearls = stats and stats:WaitForChild("Pearls", 10)
		if not pearls then
			return
		end
		local last = pearls.Value
		pearls.Changed:Connect(function(v)
			if v == last + 1 then
				local pop = Instance.new("TextLabel")
				pop.AnchorPoint = Vector2.new(0.5, 0.5)
				pop.Position = UDim2.fromScale(0.5, 0.42)
				pop.Size = UDim2.fromOffset(300, 50)
				pop.BackgroundTransparency = 1
				pop.Font = Enum.Font.FredokaOne
				pop.TextSize = 36
				pop.TextColor3 = Color3.fromRGB(255, 250, 230)
				pop.TextStrokeTransparency = 0.4
				pop.Text = "+1 Pearl"
				pop.Parent = gui
				local t = TweenService:Create(pop, TweenInfo.new(1.2), {
					Position = UDim2.fromScale(0.5, 0.34),
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				})
				t:Play()
				t.Completed:Once(function()
					pop:Destroy()
				end)
			end
			last = v
		end)
	end)

	-- intro tip
	local tip = Instance.new("TextLabel")
	tip.AnchorPoint = Vector2.new(0.5, 0)
	tip.Position = UDim2.new(0.5, 0, 0, 70)
	tip.Size = UDim2.fromOffset(560, 60)
	tip.BackgroundColor3 = Color3.fromRGB(10, 30, 45)
	tip.BackgroundTransparency = 0.35
	tip.Font = Enum.Font.Gotham
	tip.TextSize = 18
	tip.TextWrapped = true
	tip.TextColor3 = Color3.new(1, 1, 1)
	tip.Text = "Dive in and grab the glowing pearls from the clams.\nWatch your oxygen, and keep away from the sharks."
	corner(tip, 10)
	tip.Parent = gui
	task.delay(10, function()
		TweenService:Create(tip, TweenInfo.new(1), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(1)
		tip:Destroy()
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return Hud
