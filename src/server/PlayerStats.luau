-- Money, pearls, XP and levels, oxygen, owned harpoons, and saving.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Coins = require(script.Parent.Coins)
local Remotes = require(script.Parent.Remotes)

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
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Parent = stats
	local pearls = Instance.new("IntValue")
	pearls.Name = "Pearls"
	pearls.Parent = stats
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = stats
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = stats
	stats.Parent = player

	player:SetAttribute("Level", 1)
	player:SetAttribute("XP", 0)

	player:SetAttribute("Oxygen", 100)
	player:SetAttribute("Own_Basic", true)
	player:SetAttribute("Equipped", "Basic")
	player.CharacterAdded:Connect(function(char)
		player:SetAttribute("Oxygen", 100)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			hum.Died:Connect(function()
				PlayerStats.onDeath(player, hum)
			end)
		end
	end)

	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if ok and type(saved) == "number" then
			pearls.Value = saved -- old save format
		elseif ok and type(saved) == "table" then
			money.Value = tonumber(saved.Money) or 0
			pearls.Value = tonumber(saved.Pearls) or 0
			kills.Value = tonumber(saved.Kills) or 0
			local lvl = math.clamp(tonumber(saved.Level) or 1, 1, Config.MaxLevel)
			player:SetAttribute("Level", lvl)
			player:SetAttribute("XP", tonumber(saved.XP) or 0)
			level.Value = lvl
			if type(saved.Owned) == "table" then
				for _, id in saved.Owned do
					if Config.harpoon(id) then
						player:SetAttribute("Own_" .. id, true)
					end
				end
			end
			if saved.Equipped and player:GetAttribute("Own_" .. tostring(saved.Equipped)) then
				player:SetAttribute("Equipped", saved.Equipped)
			end
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
	local owned = {}
	for _, h in Config.Harpoons do
		if player:GetAttribute("Own_" .. h.id) then
			table.insert(owned, h.id)
		end
	end
	local data = {
		Money = stats.Money.Value,
		Pearls = stats.Pearls.Value,
		Owned = owned,
		Equipped = player:GetAttribute("Equipped"),
		Level = player:GetAttribute("Level") or 1,
		Kills = stats:FindFirstChild("Kills") and stats.Kills.Value or 0,
		XP = player:GetAttribute("XP") or 0,
	}
	pcall(function()
		store:SetAsync("p_" .. player.UserId, data)
	end)
end

-- Add XP and level up as many times as it covers.
function PlayerStats.addXP(player, amount)
	if not player or not player.Parent or amount <= 0 then
		return
	end
	local level = player:GetAttribute("Level") or 1
	local xp = (player:GetAttribute("XP") or 0) + amount
	while level < Config.MaxLevel and xp >= Config.xpToNext(level) do
		xp -= Config.xpToNext(level)
		level += 1
	end
	player:SetAttribute("XP", xp)
	if level ~= player:GetAttribute("Level") then
		player:SetAttribute("Level", level) -- the client shows the level-up banner
		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Level") then
			stats.Level.Value = level
		end
	end
end

-- When a player dies: if another player hit them in the last 10 seconds, that player
-- gets the kill, XP and a kill-feed line, and the victim drops some of their cash.
function PlayerStats.onDeath(victim, hum)
	local killerId = hum:GetAttribute("LastHitBy")
	local hitAt = hum:GetAttribute("LastHitAt") or 0
	if not killerId or os.clock() - hitAt > 10 then
		return
	end
	local killer = Players:GetPlayerByUserId(killerId)
	if not killer or killer == victim then
		return
	end

	local victimLevel = victim:GetAttribute("Level") or 1
	local stats = killer:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Kills") then
		stats.Kills.Value += 1
	end
	PlayerStats.addXP(killer, 25 + 5 * victimLevel)

	local vStats = victim:FindFirstChild("leaderstats")
	local money = vStats and vStats:FindFirstChild("Money")
	local hrp = victim.Character and victim.Character:FindFirstChild("HumanoidRootPart")
	if money and hrp then
		local drop = math.min(Config.PvP.maxCashDrop, math.floor(money.Value * Config.PvP.cashDrop))
		if drop > 0 then
			money.Value -= drop
			Coins.drop(hrp.Position, drop)
		end
	end
	Remotes.KillFeed:FireAllClients(killer.DisplayName, victim.DisplayName)
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
		stats.Money.Value += Config.PearlMoney
		PlayerStats.addXP(player, 8)
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
				local deep = Config.inDeep(head.Position)
				if head.Position.Y < Config.Surface - 1 then
					o -= 100 / Config.OxygenSeconds * dt * (deep and Config.Deep.oxygenDrain or 1)
				else
					o += Config.OxygenRefillPerSecond * dt
				end
				o = math.clamp(o, 0, 100)
				player:SetAttribute("Oxygen", o)
				if o <= 0 then
					hum:TakeDamage(Config.DrownDamagePerSecond * dt)
				end

				-- The Deep crushes divers who aren't a high enough level
				local tooLow = deep and (player:GetAttribute("Level") or 1) < Config.Deep.minLevel
				if tooLow then
					hum:TakeDamage(Config.Deep.pressureDamage * dt)
				end
				if (player:GetAttribute("Pressure") == true) ~= tooLow then
					player:SetAttribute("Pressure", tooLow)
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
