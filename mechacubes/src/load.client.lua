local pcall = ypcall or pcall -- [fix] old engines: pcall can't wait, ypcall can
-- ReplicatedFirst.load: the loading screen.
-- [fix] Rewritten so it works on 2016 engines too: no Color3.fromHSV, the animation can't crash the
-- script, it stays on top without DisplayOrder, and it closes even if a server message gets lost.

local players = game:GetService("Players")
local player = players.LocalPlayer
while not player do
	wait()
	player = players.LocalPlayer
end
local playerGui = player:WaitForChild("PlayerGui")
local RS = game:GetService("RunService").RenderStepped
local loadGui = script:WaitForChild("loadGui")
local loadscreen = loadGui:WaitForChild("loadscreen")
local spinner = loadscreen:WaitForChild("spinner")
local label = loadscreen:WaitForChild("label")

loadscreen.Visible = true
label.Text = "Loading"
loadGui.Parent = playerGui
pcall(function() script.Parent:RemoveDefaultLoadingScreen() end)

local saturation = 100 / 255
local value = 210 / 255
local function hsv(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then return Color3.new(v, t, p) elseif i == 1 then return Color3.new(q, v, p)
	elseif i == 2 then return Color3.new(p, v, t) elseif i == 3 then return Color3.new(p, q, v)
	elseif i == 4 then return Color3.new(t, p, v) end
	return Color3.new(v, p, q)
end

local hue = 0
local text = "Loading"
local mode = 0
local lastDots = 0
local active = false
local running = false

local function frame(delta)
	hue = (hue + (tonumber(delta) or 1 / 60) / 10) % 1
	loadscreen.BackgroundColor3 = hsv(hue, saturation, value)
	spinner.Rotation = spinner.Rotation + math.max(math.sin(((hue * 7) % 1) * math.pi) * 10, 2)
	if tick() - lastDots > .4 then
		lastDots = tick()
		label.Text = text .. string.rep(".", mode)
		mode = (mode + 1) % 4
	end
end

local function startLoop()
	if running then return end
	running = true
	spawn(function()
		while active do
			local delta = RS:wait()
			pcall(frame, delta)
		end
		running = false
	end)
end

-- old engines have no DisplayOrder: the last ScreenGui added is drawn on top, so move ours last
local function bringToFront()
	if active and loadGui.Parent == playerGui then
		local kids = playerGui:GetChildren()
		if kids[#kids] ~= loadGui then
			loadGui.Parent = nil
			loadGui.Parent = playerGui
		end
	end
end
playerGui.ChildAdded:connect(function(child)
	if child ~= loadGui then
		delay(0, bringToFront)
	end
end)

local function deactivate()
	if active then
		active = false
		loadscreen.Visible = false
	end
end

local function activate(loadText)
	text = loadText
	label.Text = text
	if not active then
		active = true
		loadscreen.Visible = true
		if loadGui.Parent ~= playerGui then loadGui.Parent = playerGui end
		bringToFront()
		startLoop()
	end
end

local bindables = game:GetService("ReplicatedStorage"):WaitForChild("bindables")

-- messages from the server: "Loading user data", "Loading match", ... and nil = done
spawn(function()
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("remotes"):WaitForChild("userLoadscreen")
	remote.OnClientEvent:connect(function(newText)
		if newText then activate(newText) else deactivate() end
	end)
end)
-- messages from the client scripts (interface.loadscreen)
bindables:WaitForChild("load").Event:connect(function(newText)
	if newText then activate(newText) else deactivate() end
end)

-- backup: the server makes your stats right before it says "done", so close the first loading
-- screen once they exist (after 3 s, in case the server still has something to show)
spawn(function()
	player:WaitForChild("leaderstats")
	wait(3)
	if active and (text == "Loading game" or text == "Loading assets" or text == "Loading user data") then
		deactivate()
	end
end)

activate("Loading game")
activate("Loading assets")
wait(2)
bindables:WaitForChild("loaded"):Fire()
game:GetService("ReplicatedStorage"):WaitForChild("properties"):WaitForChild("loaded").Value = true
