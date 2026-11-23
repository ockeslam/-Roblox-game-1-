-- Robux purchases: developer products (cash packs, XP boost) and passes
-- (double cash, big oxygen tank, golden harpoon). IDs live in Config.Robux.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Monetization = {}

-- remembers which purchases have already been handed out, so nobody is ever
-- given an item twice (or charged without getting it) if a server crashes
local receipts
pcall(function()
	receipts = DataStoreService:GetDataStore("ReefDive_Receipts")
end)

local function productById(id)
	for _, p in Config.Robux.Products do
		if p.id ~= 0 and p.id == id then
			return p
		end
	end
	return nil
end

local function grantProduct(player, product)
	local stats = player:FindFirstChild("leaderstats")
	if product.cash then
		if not stats or not stats:FindFirstChild("Money") then
			return false
		end
		stats.Money.Value += product.cash
	end
	if product.xpBoostMinutes then
		local now = os.time()
		local current = player:GetAttribute("XPBoostUntil") or 0
		player:SetAttribute("XPBoostUntil", math.max(now, current) + product.xpBoostMinutes * 60)
	end
	return true
end

-- Roblox calls this for every developer product purchase. We only say
-- "PurchaseGranted" once the item has really been given.
local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox will try again when they're back
	end
	local product = productById(info.ProductId)
	if not product then
		warn("[Reef Dive] unknown product " .. tostring(info.ProductId) .. " - is its ID in Config.Robux?")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local key = "r_" .. info.PurchaseId
	if receipts then
		local ok, done = pcall(function()
			return receipts:GetAsync(key)
		end)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if done then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- already given
		end
	end

	if not grantProduct(player, product) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receipts then
		local ok = pcall(function()
			receipts:SetAsync(key, true)
		end)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function applyPass(player, pass)
	player:SetAttribute("Pass_" .. pass.key, true)
	if pass.key == "GoldenHarpoon" then
		player:SetAttribute("Own_Golden", true)
	end
end

local function checkPasses(player)
	for _, pass in Config.Robux.Passes do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				applyPass(player, pass)
			end
		end
	end
end

function Monetization.start()
	MarketplaceService.ProcessReceipt = processReceipt

	Players.PlayerAdded:Connect(checkPasses)
	for _, p in Players:GetPlayers() do
		task.spawn(checkPasses, p)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, pass in Config.Robux.Passes do
			if pass.id == passId then
				applyPass(player, pass)
			end
		end
	end)
end

return Monetization
