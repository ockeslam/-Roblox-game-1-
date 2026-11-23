-- Makes the kelp sway. Runs on each player's machine, so it's smooth and costs the server nothing.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Kelp = {}

local stalks = {}

local function add(model)
	local segments = {}
	for _, child in model:GetChildren() do
		local i = tonumber(child.Name)
		if i and child:IsA("BasePart") then
			segments[i] = child
		end
	end
	stalks[model] = {
		segments = segments,
		base = model:GetAttribute("Base"),
		yaw = model:GetAttribute("Yaw") or 0,
		phase = model:GetAttribute("Phase") or 0,
		len = model:GetAttribute("SegLen") or 4,
	}
end

function Kelp.start()
	for _, m in CollectionService:GetTagged("Kelp") do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal("Kelp"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("Kelp"):Connect(function(m)
		stalks[m] = nil
	end)

	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		local parts, cframes = {}, {}
		for _, s in stalks do
			if s.base then
				local cf = CFrame.new(s.base) * CFrame.Angles(0, s.yaw, 0)
				for i, seg in ipairs(s.segments) do
					cf *= CFrame.Angles(
						math.sin(t * 0.9 + s.phase + i * 0.35) * 0.035,
						0,
						math.cos(t * 0.7 + s.phase + i * 0.3) * 0.03
					)
					table.insert(parts, seg)
					table.insert(cframes, cf * CFrame.new(0, s.len / 2, 0) * CFrame.Angles(0, i * 0.6, 0))
					cf *= CFrame.new(0, s.len, 0)
				end
			end
		end
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return Kelp
