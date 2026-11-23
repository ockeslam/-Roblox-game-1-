local Players = game:GetService("Players")

-- Hold players back until the world exists, so nobody spawns in the void.
Players.CharacterAutoLoads = false

require(script.Parent.Remotes) -- make the remotes before anything else
local World = require(script.Parent.World)
local Coins = require(script.Parent.Coins)
local Creatures = require(script.Parent.Creatures)
local Harpoons = require(script.Parent.Harpoons)
local PlayerStats = require(script.Parent.PlayerStats)

PlayerStats.start()
Harpoons.start()
World.build()
Coins.start()
Creatures.start()

workspace:SetAttribute("WorldReady", true)
Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
	if not player.Character then
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end
