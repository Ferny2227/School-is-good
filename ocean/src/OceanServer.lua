-- ServerScriptService.OceanServer
-- DISASTER OCEAN (2016 edition), Natural Disaster Survival style: everyone waits on the lobby island; every round
-- the whole lobby is put on board a big ship, the SS DISASTER, out at sea. Then a disaster hits it: BIG WAVES,
-- TSUNAMI, TORNADO, HURRICANE, METEOR SHOWER, the KRAKEN or a SHARK ATTACK (sometimes two at once). The ship takes
-- damage (its health bar is on everyone's screen) and pieces break off; at 0 health it SINKS and its lifeboats drop
-- into the sea. The water hurts: get to a lifeboat! Everyone still alive at the end survives and earns Coins.
-- Written for 2016 Roblox: lowercase :connect, ypcall, no TweenService.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local V = Vector3.new

------------------------------------------------------------------ clear the old map, make the remote
pcall(function() workspace:FindFirstChild("AirportMap"):Destroy() end)
pcall(function() workspace.Terrain:Clear() end)
local remote = RS:FindFirstChild("OceanEvent") or Instance.new("RemoteEvent")
remote.Name = "OceanEvent"
remote.Parent = RS
local function toClient(p, ...) local a = { ... } pcall(function() remote:FireClient(p, unpack(a)) end) end
local function toAll(...) local a = { ... } pcall(function() remote:FireAllClients(unpack(a)) end) end

------------------------------------------------------------------ small helpers
local function P(parent, name, size, cf, color, mat, opt)
	opt = opt or {}
	local p = Instance.new(opt.class or "Part")
	p.Name = name
	p.Anchored = opt.anchored ~= false
	pcall(function() p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth end)
	if opt.shape == "ball" then p.Shape = Enum.PartType.Ball elseif opt.shape == "cyl" then p.Shape = Enum.PartType.Cylinder end
	p.Size = size
	p.BrickColor = BrickColor.new(color or "Medium stone grey")
	if mat then pcall(function() p.Material = Enum.Material[mat] end) end
	if opt.tr then p.Transparency = opt.tr end
	if opt.nc then p.CanCollide = false end
	p.CFrame = cf
	p.Parent = parent
	return p
end
local function blk(parent, name, sx, sy, sz, x, y0, z, color, mat, opt, ry)
	return P(parent, name, V(sx, sy, sz), CFrame.new(x, y0 + sy / 2, z) * CFrame.Angles(0, math.rad(ry or 0), 0), color, mat, opt)
end
local function cyl(parent, name, d, h, x, y0, z, color, mat, opt)
	opt = opt or {}
	opt.shape = "cyl"
	return P(parent, name, V(h, d, d), CFrame.new(x, y0 + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), color, mat, opt)
end
local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
local function weld(a, b)
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = a, b
	w.C0 = a.CFrame:inverse() * b.CFrame
	w.Parent = a
	return w
end
local function bill(part, text, w, h, up, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(w, 0, h, 0)
	bb.StudsOffset = V(0, up, 0)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	t.Parent = bb
	bb.Parent = part
	return t
end
local function light(part, color, range, bright)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range or 16
	l.Brightness = bright or 1.5
	l.Parent = part
end
local function torsoOf(c) return c and (c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart")) end
local function clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end
local function pick(t) return t[math.random(1, #t)] end

------------------------------------------------------------------ the world: ocean, harbour island, dock
local WORLD = model(workspace, "Ocean World")
local SEA = { level = 0, base = 0, waves = 1 }   -- water surface height (floods raise it), wave height
local oceanTiles = {}
for ix = -2, 1 do
	for iz = -2, 1 do
		local t = P(WORLD, "Ocean", V(1000, 2, 1000), CFrame.new(ix * 1000 + 500, -5, iz * 1000 + 500), "Navy blue", "SmoothPlastic", { tr = 0.1, nc = true })
		pcall(function() t.Reflectance = 0.1 end)
		table.insert(oceanTiles, t)
		P(WORLD, "Seabed", V(1000, 4, 1000), CFrame.new(ix * 1000 + 500, -62, iz * 1000 + 500), "Brick yellow", "Sand")
	end
end
local function setSea(level)
	SEA.level = level
	for _, t in ipairs(oceanTiles) do t.CFrame = CFrame.new(t.Position.X, level - 5, t.Position.Z) end
end
-- Rolling swells. They travel from the ship's bow to its stern at SEA.speed, so the ship (which stays where it is)
-- looks like it's steaming straight ahead. Players' computers draw the same swells (src/OceanClient.lua) from the
-- SeaState values; SEA.amp follows SEA.waves smoothly so the sea never jumps.
SEA.amp, SEA.speed = 1, 16
local function waveAt(x, z, t)
	return SEA.amp * (0.55 * math.sin(0.018 * x + 0.7 * t) + 0.45 * math.sin(0.024 * (z + SEA.speed * t) + 0.5 * t))
end
local seaState = Instance.new("Model")
seaState.Name = "SeaState"
local function value(cls, name, v)
	local o = Instance.new(cls)
	o.Name = name
	o.Value = v
	o.Parent = seaState
	return o
end
local seaAmp = value("NumberValue", "Amp", 1)
local seaSpeed = value("NumberValue", "Speed", SEA.speed)
local seaLevel = value("NumberValue", "Level", 0)
local seaClock = value("NumberValue", "Clock", tick())
local seaShip = value("Vector3Value", "ShipAt", Vector3.new(0, 0, -650))
seaState.Parent = RS
local function stepSea(dt)
	SEA.amp = SEA.amp + clamp(SEA.waves - SEA.amp, -0.6 * dt, 0.6 * dt)
	if math.abs(seaAmp.Value - SEA.amp) > 0.05 then seaAmp.Value = SEA.amp end
	if seaLevel.Value ~= SEA.level then seaLevel.Value = SEA.level end
end
spawn(function() while true do seaClock.Value = tick() wait(5) end end)

------------------------------------------------------------------ the lobby: a floating island high in the sky, above the sea
-- (built at the origin, then lifted to LOBBY_AT). You can see the ship down below.
local LOBBY_AT = V(0, 260, -330)
local LOBBY = model(WORLD, "Lobby Island")
cyl(LOBBY, "Beach", 200, 6, 0, -3, 0, "Brick yellow", "Sand")
-- the rocky underside, and a see-through wall round the edge so nobody falls off by accident
for i = 1, 6 do cyl(LOBBY, "Rock", 200 - i * 30, 12, 0, -3 - i * 12, 0, i % 2 == 0 and "Dark stone grey" or "Brown", "Slate") end
for i = 0, 35 do
	local a = i / 36 * math.pi * 2
	P(LOBBY, "EdgeWall", V(18, 10, 1), CFrame.new(math.cos(a) * 99, 8, math.sin(a) * 99) * CFrame.Angles(0, -a + math.pi / 2, 0), "Pastel light blue", "Glass", { tr = 0.8 })
end
cyl(LOBBY, "Grass", 160, 6.4, 0, -3, 0, "Bright green", "Grass")
local spawnPad = P(LOBBY, "SpawnLocation", V(16, 1, 16), CFrame.new(0, 3.9, 0), "Bright blue", "SmoothPlastic", { class = "SpawnLocation" })
pcall(function() spawnPad.Duration = 0 end)
local board = blk(LOBBY, "Board", 40, 14, 1, 0, 3.4, 40, "Navy blue", "SmoothPlastic")
local boardText = Instance.new("SurfaceGui")
pcall(function() boardText.Face = Enum.NormalId.Back end)
local bt = Instance.new("TextLabel")
bt.Size = UDim2.new(1, 0, 1, 0)
bt.BackgroundTransparency = 1
bt.TextScaled = true
bt.TextColor3 = Color3.new(1, 0.85, 0.3)
pcall(function() bt.Font = Enum.Font.SourceSansBold end)
bt.Text = "DISASTER OCEAN\nEvery round the whole lobby goes onto the big ship. Survive the waves and disasters!\nIf the ship sinks, get to a lifeboat - the water hurts!"
bt.Parent = boardText
boardText.Parent = board
local lh = model(LOBBY, "Lighthouse")
cyl(lh, "Tower", 10, 40, 55, 3, -45, "Institutional white", "Concrete")
cyl(lh, "Stripe", 10.4, 5, 55, 18, -45, "Bright red", "SmoothPlastic")
local lamp = P(lh, "Lamp", V(7, 7, 7), CFrame.new(55, 46, -45), "New Yeller", "Neon", { shape = "ball" })
light(lamp, Color3.new(1, 0.95, 0.6), 50, 3)
for i = 1, 10 do
	local a = i / 10 * math.pi * 2
	local x, z = math.cos(a) * 70, math.sin(a) * 70
	local h = math.random(13, 18)
	P(LOBBY, "PalmTrunk", V(1.4, h, 1.4), CFrame.new(x, 3 + h / 2, z) * CFrame.Angles(0, 0, math.rad(6)), "Brown", "Wood")
	for k = 0, 4 do
		local r = k / 5 * math.pi * 2
		P(LOBBY, "PalmLeaf", V(1.6, 0.3, 9), CFrame.new(x + math.cos(r) * 3.5 + h * 0.1, 3 + h, z + math.sin(r) * 3.5) * CFrame.Angles(0, -r + math.pi / 2, 0) * CFrame.Angles(math.rad(-20), 0, 0), "Bright green", "Grass", { nc = true })
	end
end

for _, p in ipairs(LOBBY:GetDescendants()) do
	if p:IsA("BasePart") then p.CFrame = p.CFrame + LOBBY_AT end
end
------------------------------------------------------------------ coins
local function stats(p)
	local ls = p:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("IntValue")
		ls.Name = "leaderstats"
		local c = Instance.new("IntValue")
		c.Name = "Coins"
		c.Parent = ls
		local s = Instance.new("IntValue")
		s.Name = "Survived"
		s.Parent = ls
		ls.Parent = p
	end
	return ls
end
local function addCoins(p, n)
	local c = stats(p):FindFirstChild("Coins")
	if c then c.Value = c.Value + n end
end

------------------------------------------------------------------ THE SHIP
-- A big ocean liner out at sea (centre SHIP_AT). Built fresh every round; it rocks on the waves (one anchored root,
-- everything welded to it, moved by one CFrame), takes damage from the disasters (pieces break off and fall in the
-- sea), and sinks when its health runs out. Then its lifeboats drop into the water: get in one!
local SHIP_AT = V(0, 0, -650)
local LEN, WID = 220, 44
local DECK = 12            -- main deck height above the waterline
local ship = nil           -- { model, root, hp, max, base, roll, sinking, breakable = {}, lifeboats = {} }
local function shipCF(dy, pitch, roll)
	return CFrame.new(SHIP_AT + V(0, SEA.level + dy, 0)) * CFrame.Angles(pitch or 0, 0, roll or 0)
end
local function buildShip()
	local m = model(WORLD, "SS DISASTER")
	local base = shipCF(0)
	local parts = {}
	local breakable = {}
	local function part(name, size, x, y, z, color, mat, opt, br)
		local p = P(m, name, size, base * CFrame.new(x, y, z), color, mat, opt)
		table.insert(parts, p)
		if br then table.insert(breakable, p) end
		return p
	end
	-- hull: dark blue with a red bottom stripe and a white top stripe; the bow is a pair of wedges
	local root = part("Hull", V(WID, DECK + 8, LEN), 0, DECK / 2 - 4, 0, "Navy blue", "SmoothPlastic")
	part("Waterline", V(WID + 0.2, 3, LEN + 0.2), 0, -1.5, 0, "Bright red", "SmoothPlastic", { nc = true })
	part("HullTop", V(WID + 0.2, 2, LEN + 0.2), 0, DECK - 1.5, 0, "Institutional white", "SmoothPlastic", { nc = true })
	-- the bow: steps getting narrower towards the front
	for i = 1, 5 do
		local w = WID - i * 8
		part("Bow", V(w, DECK + 8, 8), 0, DECK / 2 - 4, -LEN / 2 - i * 8 + 4, "Navy blue", "SmoothPlastic")
		part("BowDeck", V(w - 2, 1, 8), 0, DECK + 0.5, -LEN / 2 - i * 8 + 4, "Brick yellow", "WoodPlanks")
	end
	-- main deck (walkable), bow deck, stern deck
	part("Deck", V(WID - 2, 1, LEN - 2), 0, DECK + 0.5, 0, "Brick yellow", "WoodPlanks")
	-- railings all round
	for _, s in ipairs({ -1, 1 }) do
		part("Rail", V(0.6, 3, LEN), s * (WID / 2 - 0.5), DECK + 2.5, 0, "Institutional white", "Metal", nil, true)
	end
	part("SternRail", V(WID, 3, 0.6), 0, DECK + 2.5, LEN / 2 - 0.5, "Institutional white", "Metal", nil, true)
	-- the superstructure: three decks of cabins with windows, the bridge at the front, two funnels
	for lvl = 0, 2 do
		local w, l = WID - 8 - lvl * 6, 110 - lvl * 20
		local y = DECK + 1 + lvl * 9
		part("Cabins", V(w, 8, l), 0, y + 4, 10, "Institutional white", "SmoothPlastic")
		part("CabinDeck", V(w + 4, 1, l + 4), 0, y + 8.5, 10, "Brick yellow", "WoodPlanks")
		for _, s in ipairs({ -1, 1 }) do
			part("Windows", V(0.3, 3, l - 6), s * (w / 2 + 0.1), y + 4.5, 10, "Pastel light blue", "Glass", { nc = true }, true)
		end
	end
	part("Bridge", V(WID - 20, 6, 14), 0, DECK + 31, -20, "Institutional white", "SmoothPlastic")
	part("BridgeWindows", V(WID - 19, 3, 0.4), 0, DECK + 32, -27, "Really black", "Glass", { nc = true }, true)
	for i, z in ipairs({ 10, 40 }) do
		local f = P(m, "Funnel", V(18, 12, 12), base * CFrame.new(0, DECK + 36 + 9, z) * CFrame.Angles(0, 0, math.rad(90)), "Bright red", "SmoothPlastic", { shape = "cyl" })
		table.insert(parts, f)
		table.insert(breakable, f)
		local top = P(m, "FunnelTop", V(4, 12.4, 12.4), base * CFrame.new(0, DECK + 36 + 20, z) * CFrame.Angles(0, 0, math.rad(90)), "Really black", "SmoothPlastic", { shape = "cyl" })
		table.insert(parts, top)
		table.insert(breakable, top)
	end
	-- ladders up the superstructure (both sides, at the back of each level)
	for _, s in ipairs({ -1, 1 }) do
		for lvl = 0, 2 do
			local w, l = WID - 8 - lvl * 6, 110 - lvl * 20
			part("Ladder", V(2, 9, 2), s * (w / 2 - 3), DECK + 1 + lvl * 9 + 4.5, 10 + l / 2 + 1, "Dark stone grey", "Metal", { class = "TrussPart" })
		end
	end
	-- deck things: a pool at the back, deck chairs, crates, a mast at the front
	part("Pool", V(20, 0.4, 24), 0, DECK + 1.1, 82, "Cyan", "SmoothPlastic", { tr = 0.3 })
	for i = 0, 7 do
		part("DeckChair", V(3, 1, 6), (i % 2 == 0 and -1 or 1) * 15, DECK + 1.5, 70 + math.floor(i / 2) * 7, "Bright blue", "Fabric", nil, true)
	end
	for i = 1, 6 do part("Crate", V(4, 4, 4), math.random(-14, 14), DECK + 3, -60 - i * 6, "Brown", "Wood", nil, true) end
	part("Mast", V(1.4, 30, 1.4), 0, DECK + 16, -75, "Dark stone grey", "Metal", nil, true)
	part("CrowsNest", V(5, 2, 5), 0, DECK + 30, -75, "Brown", "Wood", nil, true)
	-- lifeboats hanging on both sides (they drop into the sea when the ship sinks)
	local lifeboats = {}
	for _, s in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -40, -10, 20, 50 }) do
			local lb = model(m, "Lifeboat")
			local hull = P(lb, "LifeboatHull", V(7, 2.4, 16), base * CFrame.new(s * (WID / 2 + 4), DECK + 6, z), "Bright orange", "SmoothPlastic")
			local floor = P(lb, "LifeboatFloor", V(6, 0.4, 15), base * CFrame.new(s * (WID / 2 + 4), DECK + 7.3, z), "Institutional white", "SmoothPlastic")
			for _, e in ipairs({ -1, 1 }) do P(lb, "LifeboatSide", V(0.4, 1.4, 15), base * CFrame.new(s * (WID / 2 + 4) + e * 3.3, DECK + 7.9, z), "Bright orange", "SmoothPlastic") end
			table.insert(lifeboats, { model = lb, side = s, z = z })
			for _, p in ipairs(lb:GetChildren()) do table.insert(parts, p) end
		end
	end
	-- the ship's name
	local nameplate = part("NamePlate", V(0.4, 4, 40), -WID / 2 - 0.3, DECK - 4, -LEN / 2 + 30, "Navy blue", "SmoothPlastic", { nc = true })
	local sg = Instance.new("SurfaceGui")
	pcall(function() sg.Face = Enum.NormalId.Left end)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Text = "SS DISASTER"
	t.Parent = sg
	sg.Parent = nameplate
	-- one rig: everything welded to the hull (the parts are already in the world, so the welds work)
	for _, p in ipairs(parts) do
		if p ~= root then weld(root, p) p.Anchored = false end
	end
	root.Anchored = true
	local max = 1000 + 250 * #Players:GetPlayers()
	ship = { model = m, root = root, hp = max, max = max, dy = 0, pitch = 0, roll = 0, breakable = breakable, lifeboats = lifeboats, rel = root.CFrame }
	return ship
end
-- a spot on the ship's decks to put a player
local function deckSpot()
	local spots = {}
	for z = -95, 95, 15 do
		for _, x in ipairs({ -16, -8, 8, 16 }) do
			if math.abs(z - 10) > 56 or math.abs(x) > 16 then table.insert(spots, CFrame.new(x, DECK + 4, z)) end
		end
	end
	return pick(spots)
end
local function breakOff(n)
	if not ship then return end
	for _ = 1, n do
		if #ship.breakable == 0 then return end
		local i = math.random(1, #ship.breakable)
		local p = table.remove(ship.breakable, i)
		pcall(function()
			for _, w in ipairs(ship.root:GetChildren()) do
				if w:IsA("Weld") and w.Part1 == p then w:Destroy() end
			end
			p.Parent = workspace
			p.CanCollide = true
			p.Velocity = V(math.random(-20, 20), 30, math.random(-20, 20))
			Debris:AddItem(p, 15)
		end)
	end
end
local function damageShip(n, why)
	if not ship or ship.sinking then return end
	ship.hp = ship.hp - n
	-- every 6% of its health lost, a piece breaks off
	ship.lostSince = (ship.lostSince or 0) + n
	while ship.lostSince > ship.max * 0.06 do
		ship.lostSince = ship.lostSince - ship.max * 0.06
		breakOff(1)
	end
	if ship.hp <= 0 then
		ship.hp = 0
		ship.sinking = tick()
		toAll("big", "THE SHIP IS SINKING!", "Get to a lifeboat - the water hurts!")
		-- the lifeboats drop into the sea next to the ship
		for _, lb in ipairs(ship.lifeboats) do
			pcall(function()
				for _, w in ipairs(ship.root:GetChildren()) do
					if w:IsA("Weld") and w.Part1 and w.Part1:IsDescendantOf(lb.model) then w:Destroy() end
				end
				lb.model.Parent = WORLD
				local hull = lb.model:FindFirstChild("LifeboatHull")
				for _, p in ipairs(lb.model:GetChildren()) do p.Anchored = true end
				lb.cf = CFrame.new(SHIP_AT + V(lb.side * (WID / 2 + 14), 0, lb.z))
				lb.rel = {}
				for _, p in ipairs(lb.model:GetChildren()) do lb.rel[p] = hull.CFrame:inverse() * p.CFrame end
				lb.hull = hull
			end)
		end
	end
end
-- every frame: the ship rocks with the waves (and the storm), or sinks; lifeboats float
local function stepShip(dt, now)
	if not ship or not ship.model.Parent then return end
	local s = ship
	if s.sinking then
		local t = now - s.sinking
		s.dy = -t * 0.9
		s.pitch = math.min(0.35, t * 0.012)
		s.roll = s.roll * 0.98 + 0.002
	else
		-- heave with the water under the middle, roll with the slope across it, pitch with the slope along it
		local x, z = SHIP_AT.X, SHIP_AT.Z
		local h = waveAt(x, z, now)
		local across = (waveAt(x + WID / 2, z, now) - waveAt(x - WID / 2, z, now)) / WID
		local along = (waveAt(x, z - 45, now) - waveAt(x, z + 45, now)) / 90
		s.dy = h * 0.7 + (s.lift or 0)
		s.lift = (s.lift or 0) * (1 - dt)
		s.pitch = math.atan(along) * 1.4 + (s.kick or 0)
		s.kick = (s.kick or 0) * (1 - 1.5 * dt)
		s.roll = -math.atan(across) * 2.2 + math.sin(now * 0.5) * 0.01 * SEA.amp
	end
	s.root.CFrame = shipCF(s.dy, s.pitch, s.roll) * CFrame.new(0, DECK / 2 - 4, 0)
	for _, lb in ipairs(s.lifeboats) do
		if lb.hull and lb.model.Parent then
			local cf = lb.cf + V(0, SEA.level + 1.2 + waveAt(lb.cf.p.X, lb.cf.p.Z, now) * 0.6, 0)
			for p, rel in pairs(lb.rel) do if p.Parent then p.CFrame = cf * rel end end
		end
	end
end
local function onShip(pos)
	if not ship then return false end
	local l = ship.root.CFrame:inverse() * pos
	return math.abs(l.X) < WID / 2 + 2 and l.Z > -LEN / 2 - 40 and l.Z < LEN / 2 + 2 and l.Y > 0 and l.Y < 70
end

------------------------------------------------------------------ the water: you float, but it hurts (it's freezing)
local swimmers = {}
local WATER_DPS = 7
local STATE_PHASE, toLobbyEarly   -- (set further down)
local function stepSwimmers(dt)
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local t = torsoOf(c)
		local h = c and c:FindFirstChild("Humanoid")
		local bp = swimmers[p]
		local inWater = t and h and h.Health > 0 and not h.Sit and t.Position.Y < SEA.level + 1.5
		if inWater and STATE_PHASE and STATE_PHASE() == "intermission" then
			toLobbyEarly(p)
			inWater = false
		end
		if inWater then
			if not bp or bp.Parent ~= t then
				bp = Instance.new("BodyPosition")
				bp.Name = "Swim"
				bp.maxForce = V(0, 4e4, 0)
				bp.Parent = t
				swimmers[p] = bp
				h.WalkSpeed = 12
			end
			bp.position = V(0, SEA.level - 0.6 + waveAt(t.Position.X, t.Position.Z, tick()) * 0.5, 0)
			h:TakeDamage(WATER_DPS * dt)
		elseif bp and (not t or t.Position.Y > SEA.level + 2.5 or not h or h.Health <= 0 or h.Sit) then
			pcall(function() bp:Destroy() end)
			swimmers[p] = nil
			if h then h.WalkSpeed = 16 end
		end
		if t and t.Position.Y < -50 and h then h.Health = 0 end
	end
end

------------------------------------------------------------------ disasters (all of them aim at the ship)
local junk = model(WORLD, "Disaster")
local WIND = { v = V() }
local function players()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local t, h = torsoOf(c), c and c:FindFirstChild("Humanoid")
		if t and h and h.Health > 0 then table.insert(out, { p = p, t = t, h = h }) end
	end
	return out
end
local function fling(x, vel, time, flat)
	local bv = Instance.new("BodyVelocity")
	bv.maxForce = flat and V(2e4, 0, 2e4) or V(4e4, 4e4, 4e4)
	bv.velocity = vel
	bv.Parent = x.t
	Debris:AddItem(bv, time or 0.4)
end
local function hurtNear(pos, radius, dmg, shipDmg)
	for _, x in ipairs(players()) do
		local d = (x.t.Position - pos).magnitude
		if d < radius then x.h:TakeDamage(dmg * (1 - 0.5 * d / radius)) end
	end
	if shipDmg and ship and (pos - ship.root.Position).magnitude < LEN / 2 + 20 then damageShip(shipDmg) end
end
local function boom(pos, size)
	local e = Instance.new("Explosion")
	e.Position = pos
	e.BlastRadius = size
	pcall(function() e.BlastPressure = 0 end)
	pcall(function() e.DestroyJointRadiusPercent = 0 end)
	e.Parent = workspace
end
-- a random spot on (or just over) the ship
local function onDeck(spread)
	local l = V(math.random(-WID / 2, WID / 2), DECK + 1, math.random(-LEN / 2, LEN / 2))
	if ship then return ship.root.CFrame * CFrame.new(0, -(DECK / 2 - 4), 0) * l end
	return SHIP_AT + l
end
-- a wave wall that sweeps across the ship from one side: damage, a big rock, people on the open deck washed about
local function waveWall(height, shipDmg, dmg, fromSide)
	local m = model(junk, "Wave")
	local dir = fromSide or (math.random() < 0.5 and 1 or -1)
	local x = dir * 400
	local wall = P(m, "Wave", V(50, height, 600), CFrame.new(SHIP_AT.X + x, SEA.level + height / 2 - 4, SHIP_AT.Z), "Bright blue", "SmoothPlastic", { tr = 0.2, nc = true })
	local foam = P(m, "Foam", V(54, 4, 604), CFrame.new(SHIP_AT.X + x, SEA.level + height - 4, SHIP_AT.Z), "Institutional white", "SmoothPlastic", { tr = 0.1, nc = true })
	local hitShip, hit = false, {}
	spawn(function()
		while m.Parent and math.abs(x) <= 420 and x * dir > -420 do
			local dt = wait(0.05)
			x = x - dir * 70 * dt
			wall.CFrame = CFrame.new(SHIP_AT.X + x, SEA.level + height / 2 - 4, SHIP_AT.Z)
			foam.CFrame = CFrame.new(SHIP_AT.X + x, SEA.level + height - 4, SHIP_AT.Z)
			if not hitShip and math.abs(x) < WID / 2 + 20 then
				hitShip = true
				damageShip(shipDmg, "waves")
				if ship then ship.lift = height * 0.25 ship.kick = 0.04 * dir end
				toAll("shake", 0.6)
			end
			for _, p in ipairs(players()) do
				if not hit[p.p] and math.abs(p.t.Position.X - (SHIP_AT.X + x)) < 25 and math.abs(p.t.Position.Z - SHIP_AT.Z) < 300 and p.t.Position.Y < SEA.level + height - 2 then
					hit[p.p] = true
					p.h:TakeDamage(dmg)
					if not p.h.Sit then fling(p, V(-dir * 45, 20, 0), 0.25) end
				end
			end
			if x * dir < -420 then break end
		end
		m:Destroy()
	end)
end

local DIS = {}
-- the open ocean: in every round normal waves keep rolling into the ship (on top of the disaster), rocking it,
-- knocking people about and wearing the ship down a little
local function oceanWaves()
	local alive = true
	SEA.calm = 3
	SEA.waves = math.max(SEA.waves, 3)
	spawn(function()
		wait(4)
		while alive do
			waveWall(math.random(14, 22), 35, 4)
			wait(math.random(9, 15))
		end
	end)
	return function() alive = false SEA.calm = 1 SEA.waves = SEA.calm or 1 end
end
DIS.Tsunami = { text = "TSUNAMI! A giant wave is coming!", run = function()
	local alive = true
	spawn(function()
		wait(8)
		if alive then waveWall(85, 380, 40) end
		wait(25)
		if alive then waveWall(60, 200, 30, -1) end
	end)
	return function() alive = false end
end }
DIS.Tornado = { text = "TORNADO! It's heading for the ship!", run = function()
	local m = model(junk, "Tornado")
	local rings = {}
	for i = 0, 11 do
		local d = 14 + i * 5
		table.insert(rings, { part = cyl(m, "Funnel", d, 10, 0, 0, 0, i % 2 == 0 and "Dark stone grey" or "Medium stone grey", "SmoothPlastic", { tr = 0.45, nc = true }), y = i * 10 + 5 })
	end
	local pos = SHIP_AT + V(math.random(-250, 250), 0, math.random() < 0.5 and -300 or 300)
	local alive = true
	spawn(function()
		while alive do
			local dt = wait(0.1)
			local now = tick()
			-- wander over the ship, back and forth
			local goal = SHIP_AT + V(math.sin(now * 0.15) * 30, 0, math.sin(now * 0.11) * 100)
			local d = V(goal.X - pos.X, 0, goal.Z - pos.Z)
			if d.magnitude > 1 then pos = pos + d.unit * 18 * dt end
			for i, r in ipairs(rings) do
				r.part.CFrame = CFrame.new(pos.X + math.sin(now * 2 + i) * i * 0.6, SEA.level + r.y, pos.Z) * CFrame.Angles(0, now * 4 + i, math.rad(90))
			end
			if ship and (V(pos.X, 0, pos.Z) - V(ship.root.Position.X, 0, ship.root.Position.Z)).magnitude < LEN / 2 then damageShip(11 * dt) end
			for _, x in ipairs(players()) do
				local dd = V(x.t.Position.X - pos.X, 0, x.t.Position.Z - pos.Z)
				if dd.magnitude < 32 then
					x.h:TakeDamage(6 * dt)
					local around = dd.magnitude > 0.1 and dd.unit:Cross(V(0, 1, 0)) or V(1, 0, 0)
					fling(x, around * 55 + V(0, 40, 0) - dd.unit * 15, 0.3)
				end
			end
		end
	end)
	return function() alive = false m:Destroy() end
end }
DIS.Hurricane = { text = "HURRICANE! Wind, rain and lightning!", run = function()
	local alive = true
	local old = { t = Lighting.TimeOfDay, fog = Lighting.FogEnd, fogc = Lighting.FogColor, amb = Lighting.OutdoorAmbient }
	pcall(function()
		Lighting.TimeOfDay = "19:00:00"
		Lighting.FogEnd = 450
		Lighting.FogColor = Color3.new(0.35, 0.38, 0.42)
		Lighting.OutdoorAmbient = Color3.new(0.35, 0.35, 0.4)
	end)
	toAll("weather", "storm")
	SEA.waves = 6
	spawn(function()
		local a = math.random() * 6
		while alive do
			wait(0.2)
			a = a + 0.02
			WIND.v = V(math.cos(a), 0, math.sin(a)) * 18
			for _, x in ipairs(players()) do
				if not x.h.Sit then fling(x, WIND.v * 0.6 + (x.h.MoveDirection or V()) * 12, 0.15, true) end
			end
			damageShip(1.2)
		end
	end)
	spawn(function()
		wait(5)
		while alive do
			waveWall(math.random(20, 32), 55, 6)
			wait(math.random(8, 14))
		end
	end)
	spawn(function()
		while alive do
			wait(math.random(15, 35) / 10)
			local at = onDeck()
			local bolt = P(junk, "Lightning", V(1.2, 300, 1.2), CFrame.new(at + V(0, 150, 0)), "Institutional white", "Neon", { nc = true })
			light(bolt, Color3.new(0.8, 0.9, 1), 60, 5)
			Debris:AddItem(bolt, 0.25)
			toAll("flash")
			hurtNear(at, 8, 25, 25)
		end
	end)
	return function()
		alive = false
		WIND.v = V()
		SEA.waves = SEA.calm or 1
		toAll("weather", "clear")
		pcall(function()
			Lighting.TimeOfDay = old.t
			Lighting.FogEnd = old.fog
			Lighting.FogColor = old.fogc
			Lighting.OutdoorAmbient = old.amb
		end)
	end
end }
DIS["Meteor Shower"] = { text = "METEOR SHOWER! Watch the sky and keep moving!", run = function()
	local alive = true
	spawn(function()
		while alive do
			wait(1.2)
			local at = math.random() < 0.6 and onDeck() or (SHIP_AT + V(math.random(-150, 150), SEA.level, math.random(-200, 200)))
			local m = P(junk, "Meteor", V(6, 6, 6), CFrame.new(at.X + 60, 420, at.Z), "Black", "Slate", { shape = "ball", nc = true })
			local f = Instance.new("Fire")
			f.Size = 12
			f.Heat = 20
			f.Parent = m
			light(m, Color3.new(1, 0.5, 0.1), 30, 3)
			spawn(function()
				local y, x = 420, at.X + 60
				while y > at.Y and m.Parent do
					local dt = wait(0.03)
					y = y - 160 * dt
					x = x - 23 * dt
					m.CFrame = CFrame.new(x, y, at.Z)
				end
				if m.Parent then
					m:Destroy()
					boom(V(x, at.Y, at.Z), 10)
					hurtNear(V(x, at.Y, at.Z), 12, 25, 18)
				end
			end)
		end
	end)
	return function() alive = false end
end }
DIS.Kraken = { text = "THE KRAKEN! Giant tentacles are smashing the ship!", run = function()
	local alive = true
	local m = model(junk, "Kraken")
	spawn(function()
		wait(3)
		while alive do
			-- a tentacle rises out of the sea next to the ship, then slams down across the deck
			local side = math.random() < 0.5 and 1 or -1
			local z = math.random(-90, 90)
			local baseAt = SHIP_AT + V(side * (WID / 2 + 12), SEA.level - 4, z)
			local segs = {}
			for i = 1, 8 do
				local s = P(m, "Tentacle", V(5 - i * 0.4, 6, 5 - i * 0.4), CFrame.new(baseAt), i % 2 == 0 and "Bright violet" or "Royal purple", "SmoothPlastic", { nc = true })
				table.insert(segs, s)
			end
			for t = 0, 1, 0.05 do      -- rise
				for i, s in ipairs(segs) do s.CFrame = CFrame.new(baseAt + V(0, i * 5 * t, 0)) end
				wait(0.05)
			end
			wait(0.6)
			for t = 0, 1, 0.1 do       -- slam across the deck
				local a = t * math.pi / 2
				for i, s in ipairs(segs) do s.CFrame = CFrame.new(baseAt + V(-side * math.sin(a) * i * 5, math.cos(a) * i * 5 + 2, 0)) end
				wait(0.03)
			end
			local hitAt = baseAt + V(-side * 25, DECK + 2 - (SEA.level - 4), 0)
			hurtNear(hitAt, 16, 40, 45)
			toAll("shake", 0.4)
			wait(1)
			for _, s in ipairs(segs) do s:Destroy() end
			wait(math.random(3, 6))
		end
	end)
	return function() alive = false m:Destroy() end
end }
DIS["Shark Attack"] = { text = "SHARK ATTACK! Don't fall in the water!", run = function()
	local sharks = {}
	for i = 1, 8 do
		local m = model(junk, "Shark")
		local at = SHIP_AT + V(math.random(-120, 120), SEA.level - 1.2, math.random(-160, 160))
		local body = P(m, "Body", V(3, 2.5, 12), CFrame.new(at), "Medium stone grey", "SmoothPlastic")
		local fin = P(m, "Fin", V(0.4, 3.5, 3), CFrame.new(at + V(0, 2.5, 0)), "Dark stone grey", "SmoothPlastic", { class = "WedgePart" })
		weld(body, fin)
		fin.Anchored = false
		table.insert(sharks, { m = m, root = body, pos = at, look = V(0, 0, -1), next = 0 })
	end
	local alive = true
	SEA.waves = 3
	spawn(function()
		wait(4)
		while alive do   -- the waves knock people around: some might fall in...
			waveWall(math.random(16, 24), 30, 5)
			wait(math.random(10, 15))
		end
	end)
	spawn(function()
		while alive do
			local dt = wait(0.05)
			local now = tick()
			for _, s in ipairs(sharks) do
				local best, bd
				for _, x in ipairs(players()) do
					if swimmers[x.p] then
						local d = (x.t.Position - s.pos).magnitude
						if not bd or d < bd then best, bd = x.t.Position, d end
					end
				end
				-- no one in the water: circle the ship
				local goal = best or (SHIP_AT + V(math.cos(now * 0.2 + s.pos.Z) * 60, 0, math.sin(now * 0.2 + s.pos.X) * 140))
				local d = V(goal.X - s.pos.X, 0, goal.Z - s.pos.Z)
				if d.magnitude > 0.5 then s.look = (s.look * 0.9 + d.unit * 0.1).unit end
				s.pos = V(s.pos.X, SEA.level - 1.2, s.pos.Z) + s.look * (best and 22 or 12) * dt
				s.root.CFrame = CFrame.new(s.pos, s.pos + s.look)
				if best and bd < 6 and now > s.next then
					s.next = now + 1.5
					hurtNear(s.pos, 7, 25)
				end
			end
		end
	end)
	return function() alive = false SEA.waves = SEA.calm or 1 for _, s in ipairs(sharks) do s.m:Destroy() end end
end }
local ORDER = { "Tsunami", "Tornado", "Hurricane", "Meteor Shower", "Kraken", "Shark Attack" }

------------------------------------------------------------------ rounds: lobby -> everyone onto the ship -> disaster -> back
local STATE = { phase = "intermission", left = 0, disaster = "" }
local inRound = {}
local function status() toAll("status", STATE.phase, STATE.left, STATE.disaster) end
local function sendShip()
	if ship and ship.model.Parent then toAll("ship", math.max(0, math.floor(ship.hp)), ship.max, ship.sinking ~= nil)
	else toAll("ship", nil) end
end
local function toLobby(p)
	local t = torsoOf(p.Character)
	if t then t.CFrame = CFrame.new(LOBBY_AT + V(math.random(-20, 20), 8, math.random(-20, 20))) end
end
toLobbyEarly = toLobby
STATE_PHASE = function() return STATE.phase end
spawn(function()
	local round = 0
	while true do
		STATE.phase, STATE.disaster = "intermission", ""
		for s = 20, 1, -1 do
			STATE.left = s
			status()
			wait(1)
		end
		if #Players:GetPlayers() > 0 then
			round = round + 1
			-- build the ship and put the whole lobby on it
			if ship then pcall(function() ship.model:Destroy() end) end
			buildShip()
			STATE.phase = "boarding"
			STATE.left = 5
			status()
			inRound = {}
			for _, x in ipairs(players()) do
				inRound[x.p] = true
				x.t.CFrame = ship.root.CFrame * CFrame.new(0, -(DECK / 2 - 4), 0) * deckSpot()
			end
			toAll("big", "ALL ABOARD THE SS DISASTER!", "Something is coming...")
			wait(6)
			local list = { pick(ORDER) }
			if round >= 3 and math.random() < 0.3 then
				local second = pick(ORDER)
				if second ~= list[1] then table.insert(list, second) end
			end
			local names = table.concat(list, " + ")
			STATE.phase, STATE.disaster = "disaster", names
			local texts = {}
			for _, n in ipairs(list) do table.insert(texts, DIS[n].text) end
			toAll("big", string.upper(names), table.concat(texts, "  "))
			local stops = { oceanWaves() }
			for _, n in ipairs(list) do
				local ok, stop = pcall(DIS[n].run)
				if ok and stop then table.insert(stops, stop) else print("OceanServer: " .. n .. " failed: " .. tostring(stop)) end
			end
			for s = 75, 1, -1 do
				STATE.left = s
				status()
				wait(1)
			end
			for _, stop in ipairs(stops) do pcall(stop) end
			junk:ClearAllChildren()
			-- who made it? (alive, and in the round from the start)
			local survivors = {}
			local sunk = ship and ship.sinking ~= nil
			for _, x in ipairs(players()) do
				if inRound[x.p] then
					table.insert(survivors, x.p.Name)
					local reward = sunk and 60 or 40   -- surviving a sinking is worth more
					addCoins(x.p, reward)
					local s = stats(x.p):FindFirstChild("Survived")
					if s then s.Value = s.Value + 1 end
					toAll("toastTo", x.p.Name, "You survived the " .. names .. "! +" .. reward .. " Coins")
				end
			end
			toAll("survivors", survivors, sunk)
			STATE.phase = "results"
			for s = 5, 1, -1 do
				STATE.left = s
				status()
				wait(1)
			end
			for _, x in ipairs(players()) do toLobby(x.p) end
			if ship then pcall(function() ship.model:Destroy() end) ship = nil end
			sendShip()
		end
	end
end)
Players.PlayerAdded:connect(function(p)
	stats(p)
	p.CharacterAdded:connect(function(c)
		local h = c:WaitForChild("Humanoid")
		h.Died:connect(function() inRound[p] = nil end)
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do stats(p) end
Players.PlayerRemoving:connect(function(p) swimmers[p], inRound[p] = nil, nil end)
remote.OnServerEvent:connect(function(p, what)
	if what == "state" then status() sendShip() end
end)

------------------------------------------------------------------ the fast loop
spawn(function()
	local last = tick()
	local n = 0
	while true do
		wait()
		local now = tick()
		local dt = math.min(0.2, now - last)
		last = now
		pcall(stepSea, dt)
		local ok, err = pcall(stepShip, dt, now)
		if not ok then print("OceanServer: ship: " .. tostring(err)) end
		n = n + 1
		if n % 3 == 0 then
			ok, err = pcall(stepSwimmers, dt * 3)
			if not ok then print("OceanServer: water: " .. tostring(err)) end
		end
		if n % 10 == 0 then sendShip() end
	end
end)
_G.OceanDebug = { DIS = DIS, SEA = SEA, swimmers = swimmers, STATE = STATE, getShip = function() return ship end,
	buildShip = buildShip, damageShip = damageShip, deckSpot = deckSpot, onShip = onShip }
print("OceanServer ready")
