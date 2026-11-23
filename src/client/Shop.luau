-- The vending machine menu: buy and equip guns, Basic up to Mythic. Better guns need higher levels.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local buyRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyHarpoon")

local Shop = {}

local player = Players.LocalPlayer

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

function Shop.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HarpoonShop"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.DisplayOrder = 10

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(580, 520)
	panel.BackgroundColor3 = Color3.fromRGB(15, 30, 55)
	panel.BackgroundTransparency = 0.05
	corner(panel, 14)
	panel.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 200, 255)
	stroke.Thickness = 2
	stroke.Parent = panel

	label(panel, {
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.new(1, -80, 0, 36),
		Font = Enum.Font.FredokaOne,
		TextSize = 30,
		Text = "GUN SHOP",
	})
	local moneyLabel = label(panel, {
		Position = UDim2.new(1, -230, 0, 18),
		Size = UDim2.fromOffset(160, 26),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(255, 210, 60),
	})

	local close = Instance.new("TextButton")
	close.Position = UDim2.new(1, -50, 0, 12)
	close.Size = UDim2.fromOffset(36, 36)
	close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 20
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	corner(close, 8)
	close.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(16, 60)
	list.Size = UDim2.new(1, -32, 1, -100)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	local status = label(panel, {
		Position = UDim2.new(0, 20, 1, -36),
		Size = UDim2.new(1, -40, 0, 26),
		TextSize = 16,
		Font = Enum.Font.Gotham,
		Text = "",
	})

	local rows = {}
	for i, def in ipairs(Config.Harpoons) do
		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -12, 0, 66)
		row.BackgroundColor3 = Color3.fromRGB(25, 45, 75)
		corner(row, 10)
		row.Parent = list

		local stripe = Instance.new("Frame")
		stripe.Size = UDim2.new(0, 8, 1, 0)
		stripe.BackgroundColor3 = def.colour
		corner(stripe, 4)
		stripe.Parent = row

		label(row, {
			Position = UDim2.fromOffset(20, 6),
			Size = UDim2.new(1, -170, 0, 24),
			TextSize = 20,
			TextColor3 = def.colour,
			Text = def.name .. "  ·  " .. def.rarity,
		})
		local stats = string.format("Dmg %d   Reload %.2fs   Range %d", def.damage, def.cooldown, def.range)
		if def.pellets then
			stats ..= "   x" .. def.pellets .. " shots"
		end
		if def.auto then
			stats ..= "   Full-auto"
		end
		if def.splash then
			stats ..= "   Splash"
		end
		if def.chain then
			stats ..= "   Chain x" .. def.chain
		end
		label(row, {
			Position = UDim2.fromOffset(20, 34),
			Size = UDim2.new(1, -170, 0, 20),
			TextSize = 14,
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(200, 215, 230),
			Text = stats,
		})

		local button = Instance.new("TextButton")
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, -12, 0.5, 0)
		button.Size = UDim2.fromOffset(130, 40)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 18
		button.TextColor3 = Color3.new(1, 1, 1)
		corner(button, 8)
		button.Parent = row

		rows[def.id] = { def = def, button = button }
	end

	local function money()
		local stats = player:FindFirstChild("leaderstats")
		local m = stats and stats:FindFirstChild("Money")
		return m and m.Value or 0
	end

	local function refresh()
		moneyLabel.Text = "$" .. money()
		local equippedId = player:GetAttribute("Equipped") or "Basic"
		local level = player:GetAttribute("Level") or 1
		for id, row in rows do
			local owned = player:GetAttribute("Own_" .. id) or row.def.price == 0
			local b = row.button
			if equippedId == id then
				b.Text = "EQUIPPED"
				b.BackgroundColor3 = Color3.fromRGB(60, 70, 90)
			elseif owned then
				b.Text = "EQUIP"
				b.BackgroundColor3 = Color3.fromRGB(40, 150, 220)
			elseif level < (row.def.level or 1) then
				b.Text = "LEVEL " .. row.def.level
				b.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
			else
				b.Text = "BUY $" .. row.def.price
				b.BackgroundColor3 = money() >= row.def.price and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(110, 60, 60)
			end
		end
	end

	for id, row in rows do
		row.button.MouseButton1Click:Connect(function()
			local ok, msg = buyRemote:InvokeServer(id)
			status.Text = msg or ""
			status.TextColor3 = ok and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(255, 120, 120)
			refresh()
		end)
	end

	close.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	player.AttributeChanged:Connect(function(name)
		if gui.Enabled and (name == "Equipped" or name == "Level" or string.sub(name, 1, 4) == "Own_") then
			refresh()
		end
	end)
	task.spawn(function()
		local stats = player:WaitForChild("leaderstats", 30)
		local m = stats and stats:WaitForChild("Money", 10)
		if m then
			m.Changed:Connect(function()
				if gui.Enabled then
					refresh()
				end
			end)
		end
	end)

	local function hookPrompt(prompt)
		if prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function()
				status.Text = ""
				refresh()
				gui.Enabled = true
			end)
		end
	end
	for _, p in CollectionService:GetTagged("ShopPrompt") do
		hookPrompt(p)
	end
	CollectionService:GetInstanceAddedSignal("ShopPrompt"):Connect(hookPrompt)

	-- close it when you walk away from the machine
	RunService.Heartbeat:Connect(function()
		if not gui.Enabled then
			return
		end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local prompt = CollectionService:GetTagged("ShopPrompt")[1]
		local body = prompt and prompt.Parent
		if hrp and body and body:IsA("BasePart") and (hrp.Position - body.Position).Magnitude > 16 then
			gui.Enabled = false
		end
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return Shop
