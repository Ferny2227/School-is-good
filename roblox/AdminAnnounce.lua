-- StarterGui.AdminAnnounce: shows admin announcements to every player.
local pcall = ypcall or pcall
local player = game:GetService("Players").LocalPlayer
while not player do wait() player = game:GetService("Players").LocalPlayer end
local pg = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("AdminCmd")
local gui = Instance.new("ScreenGui")
gui.Name = "AdminAnnounceUI"
gui.Parent = pg
local l = Instance.new("TextLabel")
l.Position = UDim2.new(0, 0, 0, 40) l.Size = UDim2.new(1, 0, 0, 40)
l.BackgroundColor3 = Color3.new(0, 0, 0) l.BackgroundTransparency = 0.3
l.TextColor3 = Color3.new(1, 1, 0.4) l.FontSize = Enum.FontSize.Size24
l.Visible = false l.Parent = gui
local n = 0
remote.OnClientEvent:connect(function(kind, text)
	if kind ~= "announce" then return end
	n = n + 1
	local mine = n
	l.Text = "ANNOUNCEMENT: " .. tostring(text)
	l.Visible = true
	wait(8)
	if n == mine then l.Visible = false end
end)
