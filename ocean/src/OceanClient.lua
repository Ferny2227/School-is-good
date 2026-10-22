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
-- The swells are drawn on this computer from the SeaState values, with the same maths (SeaHeight, at the top) the
-- server uses to rock the boat. The surface is a grid of slabs across the boat's path. Every frame each slab is put at
-- the height of the water under it and tilted to its slope, and coloured by height: dark in the troughs, lighter up
-- the faces, turquoise near the top and white foam on the crests. The swells roll from the bow to the stern, so the
-- boat looks like it's sailing into them, and every swell lifts the bow, then the middle, then the stern.
spawn(function()
	local st = game:GetService("ReplicatedStorage"):WaitForChild("SeaState")
	local v = {}
	for _, n in ipairs({ "Amp", "Speed", "Level", "Clock", "ShipAt", "ShipLen", "Sailing", "Theme", "RogueA", "RogueT", "RogueZ", "RogueLen", "RogueBump" }) do
		v[n] = st:WaitForChild(n)
	end
	local S = { shipX = 0, shipZ = 0, amp = 1, speed = 16, rogueA = 0, rogueT = 0, rogueZ = 0, rogueLen = 150, rogueBump = false }
	local function read()
		S.shipX, S.shipZ = v.ShipAt.Value.X, v.ShipAt.Value.Z
		S.amp, S.speed = v.Amp.Value, v.Speed.Value
		S.rogueA, S.rogueT, S.rogueZ, S.rogueLen, S.rogueBump = v.RogueA.Value, v.RogueT.Value, v.RogueZ.Value, math.max(1, v.RogueLen.Value), v.RogueBump.Value
	end
	read()
	for _, o in pairs(v) do o.Changed:connect(read) end
	-- the server's sea clock: jump to it when far off, otherwise slide to it gently (no jerks in the waves)
	local offset = v.Clock.Value - tick()
	local goalOffset = offset
	v.Clock.Changed:connect(function()
		goalOffset = v.Clock.Value - tick()
		if math.abs(goalOffset - offset) > 1 then offset = goalOffset end
	end)
	local PAL = {
		Normal = { "Navy blue", "Earth blue", "Steel blue", "Medium blue", "Pastel blue", "Institutional white" },
		Sunset = { "Navy blue", "Earth blue", "Sand blue", "Medium blue", "Pastel blue", "Institutional white" },
		Halloween = { "Really black", "Black", "Earth green", "Dark green", "Bright bluish green", "Lime green" },
	}
	local folder = Instance.new("Model")
	folder.Name = "SeaFX"
	folder.Parent = workspace.CurrentCamera
	local function part(size, color)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		pcall(function() p.FormFactor = Enum.FormFactor.Custom end)
		p.Size = size
		p.BrickColor = BrickColor.new(color)
		pcall(function() p.Material = Enum.Material.SmoothPlastic end)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = folder
		return p
	end
	-- the grid: fine (12 studs) near the boat, coarser (30) further out; it flattens out to the flat ocean at the edges
	local XS = { -600, -330, -120, 120, 330, 600 }
	local ZS = { -500 }
	while ZS[#ZS] < 500 do
		local z = ZS[#ZS]
		table.insert(ZS, z + ((z >= -200 and z < 200) and 12 or 30))
	end
	local THICK = 6
	local cells = {}
	for k = 1, #ZS - 1 do
		for i = 1, #XS - 1 do
			table.insert(cells, { k = k, i = i, part = part(Vector3.new(XS[i + 1] - XS[i] + 2, THICK, ZS[k + 1] - ZS[k] + 1.5), "Steel blue"), col = 0 })
		end
	end
	local H = {}       -- heights at the grid's corners
	for k = 1, #ZS do H[k] = {} end
	-- bits of foam floating on the swells, streaming past the boat
	local foams = {}
	for i = 1, 40 do
		table.insert(foams, { part = part(Vector3.new(math.random(4, 10), 0.4, math.random(8, 20)), "Institutional white"), x = math.random(-250, 250), z = math.random(-450, 450) })
	end
	-- spray where the bow cuts into the waves
	local spray = {}
	for i = 1, 10 do
		local s = { part = part(Vector3.new(2, 2, 2), "Institutional white"), t = math.random() }
		s.part.Transparency = 0.5
		pcall(function() s.part.Shape = Enum.PartType.Ball end)
		table.insert(spray, s)
	end
	local last = tick()
	while true do
		wait(0.03)
		local now = tick()
		local dt = math.min(0.2, now - last)
		last = now
		offset = offset + (goalOffset - offset) * math.min(1, dt * 0.5)
		local cx, cz = S.shipX, S.shipZ
		local lv = v.Level.Value - 0.6     -- the top of the flat ocean
		local cam = workspace.CurrentCamera
		local near = cam and (cam.CoordinateFrame.p - Vector3.new(cx, lv, cz)).magnitude < 1600
		if folder.Parent ~= (near and cam or nil) then folder.Parent = near and cam or nil end
		if near then
			local t = now + offset
			local pal = PAL[v.Theme.Value] or PAL.Normal
			local norm = 1 / math.max(1, S.amp * 1.4)
			for k = 1, #ZS do
				local row = H[k]
				for i = 1, #XS do row[i] = SeaHeight(cx + XS[i], cz + ZS[k], t, S) end
			end
			for _, c in ipairs(cells) do
				local k, i = c.k, c.i
				local a, b, d, e = H[k][i], H[k][i + 1], H[k + 1][i], H[k + 1][i + 1]
				local dz, dx = ZS[k + 1] - ZS[k], XS[i + 1] - XS[i]
				local h = (a + b + d + e) / 4
				local sz = ((d + e) - (a + b)) / (2 * dz)       -- slope along the boat (+z = towards the stern)
				local sx = ((b + e) - (a + d)) / (2 * dx)       -- slope across
				c.part.CFrame = CFrame.new(cx + (XS[i] + XS[i + 1]) / 2, lv + h, cz + (ZS[k] + ZS[k + 1]) / 2)
					* CFrame.Angles(-math.atan(sz), 0, math.atan(sx)) * CFrame.new(0, -THICK / 2, 0)
				local r = h * norm
				local col = r < -0.5 and 1 or r < -0.15 and 2 or r < 0.2 and 3 or r < 0.45 and 4 or r < 0.7 and 5 or 6
				if col == 5 and sz < -0.15 then col = 6 end    -- the steep front of a big wave breaks white
				if col ~= c.col then
					c.col = col
					c.part.BrickColor = BrickColor.new(pal[col])
				end
			end
			for _, f in ipairs(foams) do
				f.z = f.z + S.speed * 1.3 * dt
				if f.z > 450 then f.z = f.z - 900 f.x = math.random(-250, 250) end
				local x, z = cx + f.x, cz + f.z
				local h = SeaHeight(x, z, t, S)
				local s = (SeaHeight(x, z + 6, t, S) - h) / 6
				f.part.CFrame = CFrame.new(x, lv + h + 0.5, z) * CFrame.Angles(-math.atan(s), 0, 0)
			end
			local bowZ = cz - v.ShipLen.Value / 2 - 5
			local bowH = SeaHeight(cx, bowZ, t, S)
			local moving = v.Sailing.Value
			for i, s in ipairs(spray) do
				s.t = s.t + dt * 0.8
				if s.t > 1 then s.t = s.t - 1 end
				local side = i % 2 == 0 and 1 or -1
				local u = s.t
				s.part.CFrame = CFrame.new(cx + side * (4 + u * 16), lv + bowH + 2 + math.sin(u * math.pi) * (3 + S.amp), bowZ + u * 25)
				s.part.Transparency = moving and (0.35 + u * 0.6) or 1
			end
		end
	end
end)
------------------------------------------------------------------ the boat: move ALL of its parts together
-- The server keeps the boat's parts still and sends how far the boat has moved (SeaState.ShipCF). Here every part of
-- the boat is put there every frame, so the whole boat - hull, decks, rooms, funnels, masts - rocks as one piece.
spawn(function()
	local st = game:GetService("ReplicatedStorage"):WaitForChild("SeaState")
	local cfv, shipv = st:WaitForChild("ShipCF"), st:WaitForChild("Ship")
	local parts, model, conn = {}, nil, nil
	local function add(p) if p:IsA("BasePart") and not parts[p] then parts[p] = p.CFrame end end
	local function all(o)
		for _, c in ipairs(o:GetChildren()) do add(c) all(c) end
	end
	local function setModel(m)
		if conn then conn:disconnect() conn = nil end
		parts, model = {}, m
		if m then
			all(m)
			conn = m.DescendantAdded:connect(add)
		end
	end
	shipv.Changed:connect(function() setModel(shipv.Value) end)
	setModel(shipv.Value)
	local cur = cfv.Value
	local last, frames = tick(), 0
	while true do
		wait()
		local now = tick()
		local dt = math.min(0.2, now - last)
		last = now
		local goal = cfv.Value
		local ok = pcall(function() cur = cur:lerp(goal, math.min(1, dt * 10)) end)
		if not ok then cur = goal end
		if model then
			frames = frames + 1
			local prune = frames % 15 == 0     -- pieces that broke off / lifeboats that dropped are the server's now
			for p, base in pairs(parts) do
				if prune and not p:IsDescendantOf(model) then parts[p] = nil
				else p.CFrame = cur * base end
			end
		end
	end
end)
pcall(function() remote:FireServer("state") end)
