-- Pearls (score), oxygen, and saving.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerStats = {}

-- Saving only works once the game is published and
-- "Enable Studio Access to API Services" is on. Otherwise it's skipped quietly.
local store
pcall(function()
	store = DataStoreService:GetDataStore("ReefDive_v1")
end)

local function setup(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local pearls = Instance.new("IntValue")
	pearls.Name = "Pearls"
	pearls.Parent = stats
	stats.Parent = player

	player:SetAttribute("Oxygen", 100)
	player.CharacterAdded:Connect(function()
		player:SetAttribute("Oxygen", 100)
	end)

	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if ok and type(saved) == "number" then
			pearls.Value = saved
		end
	end
end

local function save(player)
	if not store then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	pcall(function()
		store:SetAsync("p_" .. player.UserId, stats.Pearls.Value)
	end)
end

local function hookPearl(pearl)
	local ready = true
	local glow = pearl:FindFirstChildOfClass("PointLight")
	pearl.Touched:Connect(function(hit)
		if not ready then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local stats = player and player:FindFirstChild("leaderstats")
		if not stats then
			return
		end
		ready = false
		stats.Pearls.Value += 1
		pearl.Transparency = 1
		if glow then
			glow.Enabled = false
		end
		task.delay(Config.PearlRespawn, function()
			pearl.Transparency = 0
			if glow then
				glow.Enabled = true
			end
			ready = true
		end)
	end)
end

local function oxygenLoop()
	local dt = 0.25
	while true do
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local head = char and char:FindFirstChild("Head")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if head and hum and hum.Health > 0 then
				local o = player:GetAttribute("Oxygen") or 100
				if head.Position.Y < Config.Surface - 1 then
					o -= 100 / Config.OxygenSeconds * dt
				else
					o += Config.OxygenRefillPerSecond * dt
				end
				o = math.clamp(o, 0, 100)
				player:SetAttribute("Oxygen", o)
				if o <= 0 then
					hum:TakeDamage(Config.DrownDamagePerSecond * dt)
				end
			end
		end
		task.wait(dt)
	end
end

function PlayerStats.start()
	Players.PlayerAdded:Connect(setup)
	for _, p in Players:GetPlayers() do
		task.spawn(setup, p)
	end
	Players.PlayerRemoving:Connect(save)
	game:BindToClose(function()
		for _, p in Players:GetPlayers() do
			save(p)
		end
	end)

	for _, pearl in CollectionService:GetTagged("Pearl") do
		hookPearl(pearl)
	end
	CollectionService:GetInstanceAddedSignal("Pearl"):Connect(hookPearl)

	task.spawn(oxygenLoop)
end

return PlayerStats
