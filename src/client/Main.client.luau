local Players = game:GetService("Players")

-- Simple loading screen while the server builds the world.
local loading = Instance.new("ScreenGui")
loading.Name = "Loading"
loading.IgnoreGuiInset = true
loading.DisplayOrder = 100
local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(10, 50, 70)
bg.Parent = loading
local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.Font = Enum.Font.FredokaOne
text.TextSize = 40
text.TextColor3 = Color3.new(1, 1, 1)
text.Text = "Building the island..."
text.Parent = bg
loading.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

while not workspace:GetAttribute("WorldReady") do
	task.wait(0.2)
end
loading:Destroy()

local here = script.Parent
require(here:WaitForChild("Effects")).start()
require(here:WaitForChild("Hud")).start()
require(here:WaitForChild("Kelp")).start()
require(here:WaitForChild("MarineLife")).start()
require(here:WaitForChild("CreatureAnim")).start()
require(here:WaitForChild("Weapons")).start()
require(here:WaitForChild("Shop")).start()
