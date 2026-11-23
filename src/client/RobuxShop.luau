-- The "R$ SHOP" button and window. Buying opens Roblox's own purchase prompt;
-- the server (Monetization.luau) hands out the item once Roblox confirms the payment.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local RobuxShop = {}

local player = Players.LocalPlayer
local GREEN = Color3.fromRGB(0, 170, 95)

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

local function text(parent, props)
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

-- ask Roblox for the live price so the shop always matches what's on the website
local function priceOf(id, infoType)
	if id == 0 then
		return nil
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, infoType)
	end)
	return ok and info and info.PriceInRobux or nil
end

function RobuxShop.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RobuxShop"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 11

	local open = Instance.new("TextButton")
	open.AnchorPoint = Vector2.new(0, 0.5)
	open.Position = UDim2.new(0, 16, 0.5, 0)
	open.Size = UDim2.fromOffset(110, 44)
	open.BackgroundColor3 = GREEN
	open.Font = Enum.Font.FredokaOne
	open.TextSize = 22
	open.TextColor3 = Color3.new(1, 1, 1)
	open.Text = "R$ SHOP"
	corner(open, 10)
	open.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(560, 500)
	panel.BackgroundColor3 = Color3.fromRGB(15, 35, 30)
	panel.Visible = false
	corner(panel, 14)
	panel.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = GREEN
	stroke.Thickness = 2
	stroke.Parent = panel

	text(panel, { Position = UDim2.fromOffset(20, 12), Size = UDim2.new(1, -80, 0, 36), Font = Enum.Font.FredokaOne, TextSize = 30, Text = "ROBUX SHOP" })

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
	list.Size = UDim2.new(1, -32, 1, -76)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local order = 0
	local function header(label)
		order += 1
		text(list, { LayoutOrder = order, Size = UDim2.new(1, -12, 0, 28), TextSize = 18, TextColor3 = Color3.fromRGB(150, 255, 200), Text = label })
	end

	local passRows = {}
	local function row(item, isPass)
		order += 1
		local r = Instance.new("Frame")
		r.LayoutOrder = order
		r.Size = UDim2.new(1, -12, 0, 62)
		r.BackgroundColor3 = Color3.fromRGB(25, 55, 45)
		corner(r, 10)
		r.Parent = list
		text(r, { Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -170, 0, 24), TextSize = 19, Text = item.name })
		text(r, { Position = UDim2.fromOffset(14, 32), Size = UDim2.new(1, -170, 0, 20), TextSize = 14, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(200, 225, 215), Text = item.desc })

		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, -12, 0.5, 0)
		b.Size = UDim2.fromOffset(130, 40)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 18
		b.TextColor3 = Color3.new(1, 1, 1)
		b.BackgroundColor3 = item.id ~= 0 and GREEN or Color3.fromRGB(70, 80, 80)
		b.Text = item.id ~= 0 and "R$ ..." or "SOON"
		corner(b, 8)
		b.Parent = r

		if item.id ~= 0 then
			task.spawn(function()
				local price = priceOf(item.id, isPass and Enum.InfoType.GamePass or Enum.InfoType.Product)
				if price then
					b.Text = "R$ " .. price
				end
				if isPass and player:GetAttribute("Pass_" .. item.key) then
					b.Text = "OWNED"
				end
			end)
			b.MouseButton1Click:Connect(function()
				if isPass then
					if not player:GetAttribute("Pass_" .. item.key) then
						MarketplaceService:PromptGamePassPurchase(player, item.id)
					end
				else
					MarketplaceService:PromptProductPurchase(player, item.id)
				end
			end)
		end
		if isPass then
			passRows[item.key] = b
		end
	end

	header("Cash & boosts")
	for _, p in Config.Robux.Products do
		row(p, false)
	end
	header("Passes (yours forever)")
	for _, p in Config.Robux.Passes do
		row(p, true)
	end

	player.AttributeChanged:Connect(function(name)
		if string.sub(name, 1, 5) == "Pass_" then
			local b = passRows[string.sub(name, 6)]
			if b and player:GetAttribute(name) then
				b.Text = "OWNED"
			end
		end
	end)

	open.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)
	close.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return RobuxShop
