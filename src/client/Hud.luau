-- Oxygen bar, pop-ups, damage flash, squid warning, announcements and the intro tip.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = {}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function popText(gui, text, colour, y)
	local pop = Instance.new("TextLabel")
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.Position = UDim2.fromScale(0.5, y)
	pop.Size = UDim2.fromOffset(300, 50)
	pop.BackgroundTransparency = 1
	pop.Font = Enum.Font.FredokaOne
	pop.TextSize = 34
	pop.TextColor3 = colour
	pop.TextStrokeTransparency = 0.4
	pop.Text = text
	pop.Parent = gui
	local t = TweenService:Create(pop, TweenInfo.new(1.2), {
		Position = UDim2.fromScale(0.5, y - 0.08),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	t:Play()
	t.Completed:Once(function()
		pop:Destroy()
	end)
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
	label.Size = UDim2.fromOffset(240, 20)
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
				flash.BackgroundTransparency = h < last - 25 and 0.35 or 0.55
				TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
			end
			last = h
		end)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	-- "+1 Pearl" and "+$12" pop-ups
	task.spawn(function()
		local stats = player:WaitForChild("leaderstats", 30)
		if not stats then
			return
		end
		local pearls = stats:WaitForChild("Pearls", 10)
		local money = stats:WaitForChild("Money", 10)
		if pearls then
			local last = pearls.Value
			pearls.Changed:Connect(function(v)
				if v == last + 1 then
					popText(gui, "+1 Pearl", Color3.fromRGB(255, 250, 230), 0.42)
				end
				last = v
			end)
		end
		if money then
			local last = money.Value
			local joined = os.clock()
			money.Changed:Connect(function(v)
				if v > last and os.clock() - joined > 3 then
					popText(gui, "+$" .. (v - last), Color3.fromRGB(255, 210, 60), 0.5)
				end
				last = v
			end)
		end
	end)

	-- the squid warning: the screen goes a little dark red, with a creepy line of text
	local gloom = Instance.new("Frame")
	gloom.Size = UDim2.fromScale(1, 1)
	gloom.BackgroundColor3 = Color3.fromRGB(40, 0, 20)
	gloom.BackgroundTransparency = 1
	gloom.ZIndex = 5
	gloom.Parent = gui

	local warning = Instance.new("TextLabel")
	warning.AnchorPoint = Vector2.new(0.5, 0)
	warning.Position = UDim2.new(0.5, 0, 0, 150)
	warning.Size = UDim2.fromOffset(600, 40)
	warning.BackgroundTransparency = 1
	warning.Font = Enum.Font.Fondamento
	warning.TextSize = 30
	warning.TextColor3 = Color3.fromRGB(255, 150, 150)
	warning.TextStrokeTransparency = 0.3
	warning.TextTransparency = 1
	warning.TextStrokeTransparency = 1
	warning.Text = "You feel like you're being watched..."
	warning.Parent = gui

	local function updateStalked()
		local on = player:GetAttribute("Stalked") == true
		TweenService:Create(gloom, TweenInfo.new(1.5), { BackgroundTransparency = on and 0.8 or 1 }):Play()
		TweenService:Create(warning, TweenInfo.new(1), {
			TextTransparency = on and 0 or 1,
			TextStrokeTransparency = on and 0.3 or 1,
		}):Play()
		if on then
			task.delay(5, function()
				TweenService:Create(warning, TweenInfo.new(2), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end)
		end
	end
	player:GetAttributeChangedSignal("Stalked"):Connect(updateStalked)

	-- big announcements (squid appears / is killed)
	local announce = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Announce")
	announce.OnClientEvent:Connect(function(text)
		local banner = Instance.new("TextLabel")
		banner.AnchorPoint = Vector2.new(0.5, 0)
		banner.Position = UDim2.new(0.5, 0, 0, 100)
		banner.Size = UDim2.fromOffset(640, 46)
		banner.BackgroundColor3 = Color3.fromRGB(40, 5, 20)
		banner.BackgroundTransparency = 0.25
		banner.Font = Enum.Font.FredokaOne
		banner.TextSize = 28
		banner.TextColor3 = Color3.fromRGB(255, 200, 200)
		banner.Text = text
		corner(banner, 10)
		banner.Parent = gui
		task.delay(5, function()
			local t = TweenService:Create(banner, TweenInfo.new(1), { BackgroundTransparency = 1, TextTransparency = 1 })
			t:Play()
			t.Completed:Wait()
			banner:Destroy()
		end)
	end)

	-- intro tip
	local tip = Instance.new("TextLabel")
	tip.AnchorPoint = Vector2.new(0.5, 0)
	tip.Position = UDim2.new(0.5, 0, 0, 70)
	tip.Size = UDim2.fromOffset(620, 80)
	tip.BackgroundColor3 = Color3.fromRGB(10, 30, 45)
	tip.BackgroundTransparency = 0.35
	tip.Font = Enum.Font.Gotham
	tip.TextSize = 18
	tip.TextWrapped = true
	tip.TextColor3 = Color3.new(1, 1, 1)
	tip.Text = "Equip your harpoon (press 1) and click to shoot fish for cash. Spend it at the vending machine on the raft.\nGrab pearls, watch your oxygen, and keep an eye out for sharks... and worse."
	corner(tip, 10)
	tip.Parent = gui
	task.delay(12, function()
		TweenService:Create(tip, TweenInfo.new(1), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(1)
		tip:Destroy()
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return Hud
