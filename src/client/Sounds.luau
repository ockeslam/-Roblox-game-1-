-- Makes sounds from Config.Sounds, falling back to built-in Roblox sounds
-- reshaped with effects when no ID has been set.
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Sounds = {}

-- placeholder recipes for when Config.Sounds has no ID
local FALLBACKS = {
	Thunder = { id = "rbxasset://sounds/bass.wav", speed = 0.35, volume = 2.5, distort = 0.7, reverb = true },
	SquidSting = { id = "rbxasset://sounds/electronicpingshort.wav", speed = 0.12, volume = 3, distort = 0.4, reverb = true },
	SquidDrone = { id = "rbxasset://sounds/bass.wav", speed = 0.15, volume = 1.2, distort = 0.5, reverb = true, looped = true },
}

function Sounds.make(name: string, looped: boolean?)
	local s = Instance.new("Sound")
	s.Name = name
	local id = Config.Sounds[name]
	if id and id ~= "" then
		s.SoundId = id
		s.Looped = looped or false
	else
		local fb = FALLBACKS[name]
		if not fb then
			return nil -- no sound for this one until an ID is added
		end
		s.SoundId = fb.id
		s.PlaybackSpeed = fb.speed
		s.Volume = fb.volume
		s.Looped = looped or fb.looped or false
		if fb.distort then
			local d = Instance.new("DistortionSoundEffect")
			d.Level = fb.distort
			d.Parent = s
		end
		if fb.reverb then
			local r = Instance.new("ReverbSoundEffect")
			r.DecayTime = 6
			r.Density = 1
			r.WetLevel = 0
			r.Parent = s
		end
	end
	s.Parent = SoundService
	return s
end

-- fire-and-forget one-shot
function Sounds.play(name: string, speedJitter: number?)
	local s = Sounds.make(name)
	if not s then
		return
	end
	if speedJitter then
		s.PlaybackSpeed *= 1 + (math.random() - 0.5) * speedJitter
	end
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(20, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

return Sounds
