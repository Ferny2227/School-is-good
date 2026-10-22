-- StarterGui.OceanClient: the round status bar, big announcements, the ship's health bar, messages, screen shake
-- when a wave hits, and the storm (rain and lightning flashes, drawn only on this computer).
-- 2016-safe: no AnchorPoint/TweenService, FontSize instead of TextSize.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do wait() player = Players.LocalPlayer end
local pg = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("OceanEvent")
local old = pg:FindFirstChild("OceanUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "OceanUI"

local function rgb(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local C = { dark = rgb(15, 25, 45), panel = rgb(25, 45, 75), white = rgb(255, 255, 255), gold = rgb(255, 210, 70),
	green = rgb(80, 210, 110), red = rgb(230, 70, 70), blue = rgb(60, 140, 240) }
local function frame(parent, pos, size, color, tr)
	local f = Instance.new("Frame")
	f.Position, f.Size = pos, size
	f.BackgroundColor3 = color or C.panel
	f.BackgroundTransparency = tr or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end
local function label(parent, pos, size, text, fs, color)
	local t = Instance.new("TextLabel")
	t.Position, t.Size = pos, size
	t.BackgroundTransparency = 1
	t.Text = text or ""
	t.TextColor3 = color or C.white
	t.TextStrokeTransparency = 0.4
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	pcall(function() t.FontSize = Enum.FontSize["Size" .. (fs or 18)] end)
	t.Parent = parent
	return t
end
local function button(parent, pos, size, text, color)
	local b = Instance.new("TextButton")
	b.Position, b.Size = pos, size
	b.BackgroundColor3 = color or C.blue
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = C.white
	pcall(function() b.Font = Enum.Font.SourceSansBold end)
	pcall(function() b.FontSize = Enum.FontSize.Size18 end)
	b.Parent = parent
	return b
end

-- status bar (top middle)
local bar = frame(gui, UDim2.new(0.5, -200, 0, 4), UDim2.new(0, 400, 0, 40), C.dark, 0.2)
local statusText = label(bar, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "DISASTER OCEAN", 24, C.gold)
-- big announcement
local big = label(gui, UDim2.new(0.5, -400, 0.25, 0), UDim2.new(0, 800, 0, 60), "", 48, C.red)
local sub = label(gui, UDim2.new(0.5, -400, 0.25, 60), UDim2.new(0, 800, 0, 30), "", 24, C.white)
-- toast
local toast = label(gui, UDim2.new(0.5, -300, 0, 82), UDim2.new(0, 600, 0, 28), "", 20, C.green)
local toastId = 0
local function showToast(text, color)
	toastId = toastId + 1
	local id = toastId
	toast.Text = text
	toast.TextColor3 = color == "red" and C.red or (color == "gold" and C.gold or C.green)
	delay(5, function() if toastId == id then toast.Text = "" end end)
end
-- the ship's health bar (top, under the status)
local shipBox = frame(gui, UDim2.new(0.5, -230, 0, 48), UDim2.new(0, 460, 0, 30), C.dark, 0.2)
shipBox.Visible = false
local hpBack = frame(shipBox, UDim2.new(0, 4, 0, 4), UDim2.new(1, -8, 1, -8), rgb(60, 20, 20))
local hpFill = frame(hpBack, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.green)
local hpText = label(shipBox, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "", 18, C.white)
hpText.ZIndex = 2
-- lightning flash
local flash = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.white, 1)
gui.Parent = pg

------------------------------------------------------------------ rain (only on this computer)
local raining = false
local drops = {}
local function rain(on)
	raining = on
	if not on then
		for _, d in ipairs(drops) do d:Destroy() end
		drops = {}
		return
	end
	spawn(function()
		local folder = Instance.new("Model")
		folder.Name = "Rain"
		folder.Parent = workspace.CurrentCamera
		for i = 1, 70 do
			local d = Instance.new("Part")
			d.Anchored = true
			d.CanCollide = false
			d.Size = Vector3.new(0.2, 4, 0.2)
			d.BrickColor = BrickColor.new("Pastel light blue")
			d.Transparency = 0.4
			d.Parent = folder
			table.insert(drops, d)
		end
		table.insert(drops, folder)
		local t = 0
		while raining do
			local dt = wait(0.05)
			t = t + dt
			local cam = workspace.CurrentCamera
			local c = cam and cam.CoordinateFrame.p or Vector3.new()
			for i, d in ipairs(drops) do
				if d:IsA("BasePart") then
					local x = ((i * 37) % 60) - 30
					local z = ((i * 53) % 60) - 30
					local y = 30 - ((t * 60 + i * 7) % 40)
					d.CFrame = CFrame.new(c.X + x, c.Y + y, c.Z + z) * CFrame.Angles(0.2, 0, 0.1)
				end
			end
		end
	end)
end

------------------------------------------------------------------ messages from the server
local survivorsText = label(gui, UDim2.new(0.5, -300, 0.4, 0), UDim2.new(0, 600, 0, 120), "", 24, C.green)
survivorsText.TextWrapped = true
local shaking = 0
remote.OnClientEvent:connect(function(what, a, b, c, d)
	if what == "status" then
		if a == "intermission" then statusText.Text = "INTERMISSION - the ship leaves in " .. b
		elseif a == "boarding" then statusText.Text = "ALL ABOARD!"
		elseif a == "disaster" then statusText.Text = c .. "  -  SURVIVE " .. b .. "s"
		else statusText.Text = "ROUND OVER - back to the island in " .. b end
	elseif what == "big" then
		big.Text = a
		sub.Text = b or ""
		survivorsText.Text = ""
		delay(6, function() if big.Text == a then big.Text = "" sub.Text = "" end end)
	elseif what == "survivors" then
		survivorsText.Text = (b and "THE SHIP SANK!\n" or "") .. (#a > 0 and ("SURVIVORS: " .. table.concat(a, ", ")) or "NOBODY SURVIVED!")
		delay(6, function() survivorsText.Text = "" end)
	elseif what == "toast" then
		showToast(a, b)
	elseif what == "toastTo" then
		if a == player.Name then showToast(b, "green") end
	elseif what == "ship" then
		shipBox.Visible = a ~= nil
		if a then
			local f = b > 0 and a / b or 0
			hpFill.Size = UDim2.new(math.max(0, math.min(1, f)), 0, 1, 0)
			hpFill.BackgroundColor3 = f > 0.5 and C.green or (f > 0.25 and C.gold or C.red)
			hpText.Text = c and "THE SHIP IS SINKING!" or ("SS DISASTER  " .. a .. " / " .. b)
		end
	elseif what == "shake" then
		shaking = math.max(shaking, a or 0.5)
	elseif what == "weather" then
		rain(a == "storm")
	elseif what == "flash" then
		spawn(function()
			flash.BackgroundTransparency = 0.3
			wait(0.08)
			flash.BackgroundTransparency = 0.7
			wait(0.08)
			flash.BackgroundTransparency = 1
		end)
	end
end)
-- camera shake when a wave hits the ship
spawn(function()
	while true do
		wait(0.03)
		if shaking > 0 then
			shaking = shaking - 0.03
			local cam = workspace.CurrentCamera
			if cam then pcall(function() cam.CoordinateFrame = cam.CoordinateFrame * CFrame.Angles(math.random(-10, 10) / 600, math.random(-10, 10) / 600, 0) end) end
		end
	end
end)
pcall(function() remote:FireServer("state") end)
