-- Wait for the server to finish building the ocean, then start the client side.
while not workspace:GetAttribute("WorldReady") do
	task.wait(0.2)
end

local here = script.Parent
require(here:WaitForChild("Effects")).start()
require(here:WaitForChild("Hud")).start()
require(here:WaitForChild("Kelp")).start()
require(here:WaitForChild("MarineLife")).start()
