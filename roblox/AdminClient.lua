-- AdminServer.AdminClient: admin panel UI. AdminServer copies it into asdasda's PlayerGui only;
-- it also checks the name itself, and the server re-checks every command.
-- 2016-safe: no AnchorPoint/TweenService/UIListLayout, FontSize instead of TextSize.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do wait() player = Players.LocalPlayer end
if player.Name:lower() ~= "asdasda" then return end
local pg = player:WaitForChild("PlayerGui")
local remote

local old = pg:FindFirstChild("AdminUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "AdminUI"
gui.Parent = pg
-- old engines draw the most recently added ScreenGui on top: move ours to the top after the game's UI loads
spawn(function()
	for i = 1, 3 do
		wait(2)
		if gui.Parent then gui.Parent = nil gui.Parent = pg end
	end
end)

local function box(parent, x, y, w, h, color)
	local f = Instance.new("Frame")
	f.Position = UDim2.new(0, x, 0, y) f.Size = UDim2.new(0, w, 0, h)
	f.BackgroundColor3 = color or Color3.new(0.1, 0.1, 0.14)
	f.BorderSizePixel = 0 f.ZIndex = 10 f.Parent = parent
	return f
end
local function label(parent, text, x, y, w, h, size)
	local l = Instance.new("TextLabel")
	l.Position = UDim2.new(0, x, 0, y) l.Size = UDim2.new(0, w, 0, h)
	l.BackgroundTransparency = 1 l.TextColor3 = Color3.new(1, 1, 1)
	l.Text = text l.FontSize = size or Enum.FontSize.Size14 l.Font = Enum.Font.SourceSans
	l.TextXAlignment = Enum.TextXAlignment.Left l.ZIndex = 10 l.Parent = parent
	return l
end
local function button(parent, text, x, y, w, h, color)
	local b = Instance.new("TextButton")
	b.Position = UDim2.new(0, x, 0, y) b.Size = UDim2.new(0, w, 0, h)
	b.BackgroundColor3 = color or Color3.new(0.25, 0.3, 0.45) b.BorderSizePixel = 0
	b.TextColor3 = Color3.new(1, 1, 1) b.Text = text b.FontSize = Enum.FontSize.Size14
	b.Font = Enum.Font.SourceSansBold b.ZIndex = 10 b.Parent = parent
	return b
end
local function input(parent, hint, x, y, w, h)
	local t = Instance.new("TextBox")
	t.Position = UDim2.new(0, x, 0, y) t.Size = UDim2.new(0, w, 0, h)
	t.BackgroundColor3 = Color3.new(0.2, 0.2, 0.26) t.BorderSizePixel = 0
	t.TextColor3 = Color3.new(1, 1, 1) t.Text = "" t.FontSize = Enum.FontSize.Size14
	t.Font = Enum.Font.SourceSans t.ZIndex = 10 t.Parent = parent
	return t
end

local toggle = button(gui, "ADMIN", 6, 0, 120, 36, Color3.new(0.8, 0.1, 0.1))
toggle.Position = UDim2.new(0, 6, 0.5, -215)
toggle.ZIndex = 10
local panel = box(gui, 140, 0, 360, 420)
panel.Position = UDim2.new(0, 140, 0.5, -215)
panel.ZIndex = 10
panel.Visible = false
toggle.MouseButton1Click:connect(function() panel.Visible = not panel.Visible end)

label(panel, "Admin Panel", 10, 4, 200, 22, Enum.FontSize.Size18)
local status = label(panel, "", 10, 26, 340, 18)
label(panel, "Player (name or prefix):", 10, 48, 200, 16)
local target = input(panel, "", 10, 66, 340, 24)
label(panel, "Reason / value:", 10, 94, 200, 16)
local extra = input(panel, "", 10, 112, 340, 24)

local function send(cmd)
	if not remote then status.Text = "Waiting for server..." return end
	remote:FireServer(cmd, target.Text, extra.Text)
end
local cmds = {
	{"Kick", "kick"}, {"Ban", "ban"}, {"Unban", "unban"},
	{"Kill", "kill"}, {"Respawn", "respawn"}, {"Heal", "heal"},
	{"God", "god"}, {"Ungod", "ungod"}, {"Freeze", "freeze"},
	{"Unfreeze", "unfreeze"}, {"Speed", "speed"}, {"Jump", "jump"},
	{"Bring", "bring"}, {"Goto", "tp"}, {"+Cash", "cash"},
}
for i, c in ipairs(cmds) do
	local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
	local color = (c[2] == "kick" or c[2] == "ban") and Color3.new(0.7, 0.2, 0.2) or nil
	local b = button(panel, c[1], 10 + col * 115, 144 + row * 30, 110, 26, color)
	b.MouseButton1Click:connect(function() send(c[2]) end)
end
local ann = button(panel, "Announce (uses Reason box)", 10, 298, 340, 26, Color3.new(0.2, 0.45, 0.25))
ann.MouseButton1Click:connect(function() if remote then remote:FireServer("announce", "", extra.Text) end end)

label(panel, "Players (click to select):", 10, 328, 200, 16)
local listFrame = box(panel, 10, 346, 168, 66, Color3.new(0.15, 0.15, 0.2))
local banFrame = box(panel, 182, 346, 168, 66, Color3.new(0.2, 0.15, 0.15))
local function fill(frame, items, fn)
	for _, c in pairs(frame:GetChildren()) do c:Destroy() end
	for i, n in ipairs(items) do
		if i > 3 then break end
		local b = button(frame, n, 2, 2 + (i - 1) * 21, 164, 19, Color3.new(0.25, 0.25, 0.32))
		b.MouseButton1Click:connect(function() fn(n) end)
	end
end

local function hook()
remote.OnClientEvent:connect(function(kind, a, b)
	if kind == "msg" then
		status.Text = tostring(a)
	elseif kind == "list" then
		fill(listFrame, a, function(n) target.Text = n end)
		fill(banFrame, b, function(n) target.Text = n end)
	end
end)
remote:FireServer("list", "", "")
end
status.Text = "Waiting for server..."
local rs = game:GetService("ReplicatedStorage")
while not remote do
	remote = rs:FindFirstChild("AdminCmd")
	if not remote then wait(0.5) end
end
status.Text = "Ready. Chat ;cmds for chat commands."
hook()

