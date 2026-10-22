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
			hpText.Text = c and ("THE " .. string.upper(d or "SHIP") .. " IS SINKING!") or (string.upper(d or "SHIP") .. "  " .. a .. " / " .. b)
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
------------------------------------------------------------------ the sea round the boat (only drawn here)
-- The water itself is real Terrain water (it ripples and reflects). On top of it this computer draws rolling wave
-- crests (long ridges with white tops) and streaks of foam that stream from the bow to the stern, so the boat looks
-- like it's ploughing straight ahead through a rough sea, plus spray at the bow. Same wave maths as the server.
spawn(function()
	local st = game:GetService("ReplicatedStorage"):WaitForChild("SeaState")
	local amp, speed, level, clock, shipAt, sailing = st:WaitForChild("Amp"), st:WaitForChild("Speed"), st:WaitForChild("Level"),
		st:WaitForChild("Clock"), st:WaitForChild("ShipAt"), st:WaitForChild("Sailing")
	local offset = clock.Value - tick()
	clock.Changed:connect(function() offset = clock.Value - tick() end)
	local folder = Instance.new("Model")
	folder.Name = "SeaFX"
	folder.Parent = workspace.CurrentCamera
	local function part(size, color, tr, wedge)
		local p = Instance.new(wedge and "WedgePart" or "Part")
		p.Anchored = true
		p.CanCollide = false
		p.Size = size
		p.BrickColor = BrickColor.new(color)
		p.Transparency = tr
		pcall(function() p.Material = Enum.Material.SmoothPlastic end)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = folder
		return p
	end
	-- wave crests: ridges across the boat's path, one every SPACING studs, sliding towards the stern
	local SPACING, RIDGES, WIDTH = 70, 12, 700
	local ridges = {}
	for i = 1, RIDGES do
		local r = { front = part(Vector3.new(WIDTH, 2, 14), "Bright blue", 0.35, true), back = part(Vector3.new(WIDTH, 2, 26), "Steel blue", 0.4, true),
			cap = part(Vector3.new(WIDTH, 0.6, 5), "Institutional white", 0.3), k = i, wobble = math.random() * 6 }
		table.insert(ridges, r)
	end
	-- foam streaks
	local foams = {}
	for i = 1, 70 do
		table.insert(foams, { part = part(Vector3.new(math.random(4, 10), 0.3, math.random(10, 26)), "Institutional white", 0.45), x = math.random(-300, 300), z = math.random(-400, 400) })
	end
	-- spray at the bow
	local spray = {}
	for i = 1, 10 do table.insert(spray, { part = part(Vector3.new(2, 2, 2), "Institutional white", 0.5), t = math.random() }) end
	for _, s in ipairs(spray) do pcall(function() s.part.Shape = Enum.PartType.Ball end) end
	local last = tick()
	while true do
		wait(0.05)
		local now = tick()
		local dt = now - last
		last = now
		local c = shipAt.Value
		local lv = level.Value
		local a = math.max(0.6, amp.Value)
		local cam = workspace.CurrentCamera
		local near = cam and (cam.CoordinateFrame.p - c).magnitude < 1600
		folder.Parent = near and cam or nil
		if near then
			local moving = sailing.Value
			local flow = (moving and speed.Value or 4) * 2.2
			local t = now + offset
			-- crests: height follows the sea's roughness
			local h = a * 1.8
			for _, r in ipairs(ridges) do
				local z = ((r.k * SPACING + t * flow) % (SPACING * RIDGES)) - SPACING * RIDGES / 2
				local y = lv - 2 + h / 2
				local base = CFrame.new(c.X + math.sin(t * 0.3 + r.wobble) * 30, y, c.Z + z)
				r.front.Size = Vector3.new(WIDTH, h, 14)
				r.back.Size = Vector3.new(WIDTH, h, 26)
				r.cap.Size = Vector3.new(WIDTH, 0.6, 5)
				r.front.CFrame = base * CFrame.new(0, 0, 7) * CFrame.Angles(0, math.pi, 0)
				r.back.CFrame = base * CFrame.new(0, 0, -13)
				r.cap.CFrame = base * CFrame.new(0, h / 2, 1)
			end
			for _, f in ipairs(foams) do
				f.z = f.z + flow * dt
				if f.z > 400 then f.z = f.z - 800 f.x = math.random(-300, 300) end
				f.part.CFrame = CFrame.new(c.X + f.x, lv + 0.2, c.Z + f.z)
			end
			for i, s in ipairs(spray) do
				s.t = s.t + dt * 0.8
				if s.t > 1 then s.t = s.t - 1 end
				local side = i % 2 == 0 and 1 or -1
				local u = s.t
				s.part.CFrame = CFrame.new(c.X + side * (4 + u * 16), lv + 2 + math.sin(u * math.pi) * (3 + a * 2), c.Z - 120 + u * 25)
				s.part.Transparency = moving and (0.35 + u * 0.6) or 1
			end
		end
	end
end)
pcall(function() remote:FireServer("state") end)
