-- Gold coins that drop when you kill something. Swim near them to pick them up.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)

local Coins = {}

local rng = Random.new()
local folder
local live = {} -- coin -> time it disappears
local GOLD = Color3.fromRGB(255, 200, 40)

function Coins.drop(pos: Vector3, total: number)
	if not folder or total <= 0 then
		return
	end
	local count = math.clamp(math.ceil(total / 8), 1, 12)
	local each = math.floor(total / count)
	local extra = total - each * count
	for i = 1, count do
		local value = each + (i <= extra and 1 or 0)
		local offset = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-1, 2), rng:NextNumber(-3, 3))
		local coin = Build.part({
			Name = "Coin",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 1.6, 1.6),
			CFrame = CFrame.new(pos + offset),
			Color = GOLD,
			Material = Enum.Material.Metal,
			Reflectance = 0.3,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
		}, folder)
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 5
		light.Parent = coin
		coin:SetAttribute("Value", value)
		CollectionService:AddTag(coin, "Coin") -- the client spins these
		live[coin] = os.clock() + Config.CoinLifetime
	end
end

function Coins.start()
	folder = Instance.new("Folder")
	folder.Name = "Coins"
	folder.Parent = workspace

	task.spawn(function()
		while true do
			local now = os.clock()
			local collectors = {}
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local stats = player:FindFirstChild("leaderstats")
				if hrp and hum and hum.Health > 0 and stats then
					table.insert(collectors, { hrp = hrp, money = stats:FindFirstChild("Money"), player = player })
				end
			end

			for coin, expires in live do
				local picked = false
				for _, c in collectors do
					if c.money and (c.hrp.Position - coin.Position).Magnitude < Config.CoinPickupRange then
						-- the Double Cash pass doubles every coin
						local mult = c.player:GetAttribute("Pass_DoubleCash") and 2 or 1
						c.money.Value += (coin:GetAttribute("Value") or 1) * mult
						picked = true
						break
					end
				end
				if picked or now > expires then
					live[coin] = nil
					coin:Destroy()
				end
			end
			task.wait(0.15)
		end
	end)
end

return Coins
