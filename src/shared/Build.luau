-- Small helpers for making parts from code. Used by server and client.
local Build = {}

function Build.part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
	end
	for key, value in props do
		if key ~= "Shape" then
			(p :: any)[key] = value
		end
	end
	p.Parent = parent
	return p
end

-- A stretched sphere (Ball parts can only be perfectly round).
function Build.ellipsoid(size: Vector3, cf: CFrame, color: Color3, parent: Instance?, extra: { [string]: any }?)
	local props = { Size = size, CFrame = cf, Color = color }
	if extra then
		for k, v in extra do
			props[k] = v
		end
	end
	local p = Build.part(props, parent)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- A cylinder running from point a to point b.
function Build.cylinderBetween(a: Vector3, b: Vector3, thickness: number, props, parent)
	local dir = b - a
	if dir.Magnitude < 0.01 then
		b = a + Vector3.new(0, 0.01, 0)
		dir = b - a
	end
	if math.abs(dir.Unit.Y) > 0.999 then
		b += Vector3.new(0.02, 0, 0.02) -- lookAt breaks when pointing straight up
	end
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new((b - a).Magnitude, thickness, thickness)
	props.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
	return Build.part(props, parent)
end

return Build
