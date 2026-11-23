-- Wags tails and waves squid tentacles, and spins dropped coins. Runs locally so it's smooth.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local CreatureAnim = {}

local joints = {} -- Motor6D -> settings
local coins = {} -- coin part -> {pos, phase}

local function addJoint(m)
	if m:IsA("Motor6D") and m.Name == "Wiggle" then
		joints[m] = {
			yaw = m:GetAttribute("Yaw") or 0,
			pitch = m:GetAttribute("Pitch") or 0,
			speed = m:GetAttribute("Speed") or 3,
			phase = m:GetAttribute("Phase") or 0,
		}
	end
end

local function addCreature(model)
	for _, d in model:GetDescendants() do
		addJoint(d)
	end
	model.DescendantAdded:Connect(addJoint)
end

local function addCoin(coin)
	if coin:IsA("BasePart") then
		coins[coin] = { pos = coin.Position, phase = math.random() * 6 }
	end
end

function CreatureAnim.start()
	for _, m in CollectionService:GetTagged("Creature") do
		addCreature(m)
	end
	CollectionService:GetInstanceAddedSignal("Creature"):Connect(addCreature)

	for _, c in CollectionService:GetTagged("Coin") do
		addCoin(c)
	end
	CollectionService:GetInstanceAddedSignal("Coin"):Connect(addCoin)
	CollectionService:GetInstanceRemovedSignal("Coin"):Connect(function(c)
		coins[c] = nil
	end)

	RunService.Stepped:Connect(function(t)
		for m, w in joints do
			if m.Parent then
				local s = math.sin(t * w.speed + w.phase)
				local c = math.cos(t * w.speed * 0.8 + w.phase)
				m.Transform = CFrame.Angles(c * w.pitch, s * w.yaw, 0)
			else
				joints[m] = nil
			end
		end

		local parts, cframes = {}, {}
		for coin, info in coins do
			if coin.Parent then
				table.insert(parts, coin)
				table.insert(cframes, CFrame.new(info.pos + Vector3.new(0, math.sin(t * 2 + info.phase) * 0.3, 0)) * CFrame.Angles(0, t * 3 + info.phase, 0))
			else
				coins[coin] = nil
			end
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

return CreatureAnim
