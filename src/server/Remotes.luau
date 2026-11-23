-- Creates the RemoteEvents the client and server talk through.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local function get(className, name)
	local r = folder:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = folder
	end
	return r
end

return {
	Fire = get("RemoteEvent", "FireHarpoon"), -- client -> server: shoot at a point
	Fx = get("RemoteEvent", "HarpoonFx"), -- server -> clients: draw shots and hits
	Buy = get("RemoteFunction", "BuyHarpoon"), -- client -> server: buy or equip a harpoon
	Announce = get("RemoteEvent", "Announce"), -- server -> clients: big messages
}
