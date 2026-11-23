local Players = game:GetService("Players")

local World = require(script.Parent.World)
local Sharks = require(script.Parent.Sharks)
local PlayerStats = require(script.Parent.PlayerStats)

-- Hold players back until the ocean exists, so nobody spawns in the void.
Players.CharacterAutoLoads = false

PlayerStats.start()
World.build()
Sharks.start()

workspace:SetAttribute("WorldReady", true)
Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
	if not player.Character then
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
end
