-- ServerScriptService.OceanServer
-- DISASTER OCEAN (2016 edition): an island harbour in the middle of a huge ocean. Between rounds everyone is on the
-- island; click the DOCKMASTER to get a boat (better boats cost Coins). Every round an ocean disaster hits:
-- TORNADO, TSUNAMI, HURRICANE, METEOR SHOWER (plus WHIRLPOOL and SHARK ATTACK). Survive it to earn Coins.
-- Boats are moved by the server (one anchored root, everything welded), so they never tip over or sink by accident:
-- they sink when their health runs out. Players who fall in the water swim (they float at the surface).
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
		local t = P(WORLD, "Ocean", V(1000, 2, 1000), CFrame.new(ix * 1000 + 500, -1, iz * 1000 + 500), "Bright blue", "SmoothPlastic", { tr = 0.25, nc = true })
		pcall(function() t.Reflectance = 0.1 end)
		table.insert(oceanTiles, t)
		P(WORLD, "Seabed", V(1000, 4, 1000), CFrame.new(ix * 1000 + 500, -62, iz * 1000 + 500), "Brick yellow", "Sand")
	end
end
local function setSea(level)
	SEA.level = level
	for _, t in ipairs(oceanTiles) do t.CFrame = CFrame.new(t.Position.X, level - 1, t.Position.Z) end
end

local ISLAND = model(WORLD, "Harbour Island")
cyl(ISLAND, "Beach", 260, 6, 0, -3, 40, "Brick yellow", "Sand")
cyl(ISLAND, "Grass", 220, 6.4, 0, -3, 50, "Bright green", "Grass")
cyl(ISLAND, "Hill", 90, 10, -40, 3, 90, "Bright green", "Grass")
local spawnPad = P(ISLAND, "SpawnLocation", V(14, 1, 14), CFrame.new(0, 3.9, 40), "Bright blue", "SmoothPlastic", { class = "SpawnLocation" })
pcall(function() spawnPad.Duration = 0 end)
-- the dock: a long pier south into the sea, with numbered slips for boats on both sides
blk(ISLAND, "Pier", 16, 1, 250, 0, 2, -125, "Reddish brown", "WoodPlanks")
for z = -248, -20, 14 do
	for _, x in ipairs({ -7.5, 7.5 }) do cyl(ISLAND, "Post", 1.4, 12, x, -9, z, "Brown", "Wood") end
end
for i, z in ipairs({ -120, -150, -180, -210, -240 }) do
	for s, x in ipairs({ -1, 1 }) do
		local sign = blk(ISLAND, "SlipSign", 4, 2, 0.4, x * 9, 3, z, "Institutional white", "SmoothPlastic", { nc = true })
		bill(sign, "SLIP " .. ((i - 1) * 2 + s), 6, 2, 1.5, Color3.new(0.1, 0.2, 0.6))
	end
end
-- buildings and decoration
blk(ISLAND, "Boathouse", 30, 14, 20, 30, 3, -5, "Bright red", "WoodPlanks")
blk(ISLAND, "BoathouseRoof", 34, 1, 24, 30, 17, -5, "Dark stone grey", "Slate")
blk(ISLAND, "Shack", 18, 10, 14, -35, 3, -2, "Brick yellow", "WoodPlanks")
blk(ISLAND, "ShackRoof", 20, 1, 16, -35, 13, -2, "Bright blue", "SmoothPlastic")
local lh = model(ISLAND, "Lighthouse")
cyl(lh, "Tower", 12, 46, 80, 3, 80, "Institutional white", "Concrete")
cyl(lh, "Stripe", 12.4, 6, 80, 20, 80, "Bright red", "SmoothPlastic")
cyl(lh, "Stripe", 12.4, 6, 80, 36, 80, "Bright red", "SmoothPlastic")
local lamp = P(lh, "Lamp", V(8, 8, 8), CFrame.new(80, 53, 80), "New Yeller", "Neon", { shape = "ball" })
light(lamp, Color3.new(1, 0.95, 0.6), 60, 3)
for i = 1, 14 do
	local a = i / 14 * math.pi * 2
	local x, z = math.cos(a) * 112, 40 + math.sin(a) * 112
	if z > -10 or math.abs(x) > 30 then
		local h = math.random(14, 20)
		P(ISLAND, "PalmTrunk", V(1.4, h, 1.4), CFrame.new(x, 3 + h / 2, z) * CFrame.Angles(0, 0, math.rad(6)), "Brown", "Wood")
		for k = 0, 4 do
			local r = k / 5 * math.pi * 2
			P(ISLAND, "PalmLeaf", V(1.6, 0.3, 9), CFrame.new(x + math.cos(r) * 3.5 + h * 0.1, 3 + h, z + math.sin(r) * 3.5) * CFrame.Angles(0, -r + math.pi / 2, 0) * CFrame.Angles(math.rad(-20), 0, 0), "Bright green", "Grass", { nc = true })
		end
	end
end
for i = 1, 16 do
	local a = i / 16 * math.pi * 2
	local b = cyl(WORLD, "Buoy", 3, 4, math.cos(a) * 420, -1.5, math.sin(a) * 420, i % 2 == 0 and "Bright red" or "Bright yellow", "SmoothPlastic", { nc = true })
	light(b, Color3.new(1, 0.4, 0.2), 12, 1)
end
-- the dockmaster: click him for a boat
local dock = model(ISLAND, "DOCKMASTER")
blk(dock, "Legs", 2, 2, 1, 0, 3, -30, "Dark blue", "SmoothPlastic")
local dmTorso = blk(dock, "Torso", 2, 2, 1, 0, 5, -30, "Bright yellow", "SmoothPlastic")
blk(dock, "Head", 2, 1, 1, 0, 7, -30, "Pastel brown", "SmoothPlastic")
blk(dock, "Hat", 2.4, 0.6, 1.6, 0, 8, -30, "Navy blue", "SmoothPlastic")
blk(dock, "ArmL", 1, 2, 1, -1.5, 5, -30, "Bright yellow", "SmoothPlastic")
blk(dock, "ArmR", 1, 2, 1, 1.5, 5, -30, "Bright yellow", "SmoothPlastic")
bill(dmTorso, "DOCKMASTER\nclick me for a boat!", 10, 3, 5, Color3.new(1, 0.9, 0.3))
local click = Instance.new("ClickDetector")
click.MaxActivationDistance = 40
click.Parent = dmTorso

------------------------------------------------------------------ coins
local function stats(p)
	local ls = p:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("IntValue")
		ls.Name = "leaderstats"
		local c = Instance.new("IntValue")
		c.Name = "Coins"
		c.Value = 100
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

------------------------------------------------------------------ boats (server-driven, see the top of the file)
local BOATS = {
	{ key = "Rowboat", price = 0, len = 14, wid = 6, speed = 28, turn = 1.4, hp = 100, color = "Brown", deck = "Reddish brown" },
	{ key = "Speedboat", price = 150, len = 20, wid = 7, speed = 60, turn = 1.6, hp = 150, color = "Institutional white", deck = "Bright red" },
	{ key = "Fishing Boat", price = 400, len = 28, wid = 10, speed = 38, turn = 1.0, hp = 320, color = "Bright blue", deck = "Light stone grey", cabin = true },
	{ key = "Yacht", price = 1200, len = 42, wid = 14, speed = 48, turn = 0.8, hp = 600, color = "Institutional white", deck = "Brick yellow", cabin = true, upper = true },
}
local BOAT = {}
for _, b in ipairs(BOATS) do BOAT[b.key] = b end
local boats = {}       -- list of boat states
local damageBoat
local boatOf = {}      -- player -> boat
local slipFree = 1
local SLIPS = {}
for _, z in ipairs({ -120, -150, -180, -210, -240 }) do for _, x in ipairs({ -1, 1 }) do table.insert(SLIPS, { x = x, z = z }) end end

local function sinkBoat(b, why)
	if b.sinking then return end
	b.sinking = true
	b.sinkAt = tick()
	if b.owner and b.owner.Parent then toClient(b.owner, "toast", "Your " .. b.kind.key .. " sank! (" .. (why or "too much damage") .. ")", "red") end
	local s = Instance.new("Smoke")
	s.Parent = b.root
end
function damageBoat(b, n, why)   -- (declared above: sinking, disasters and sharks all use it)
	if not b or b.sinking then return end
	b.hp = b.hp - n
	b.hpValue.Value = math.max(0, math.floor(b.hp))
	if b.hp <= 0 then sinkBoat(b, why) end
end
local function makeBoat(owner, kind, cf)
	local k = BOAT[kind]
	local m = model(WORLD, owner.Name .. "'s " .. k.key)
	local L, W = k.len, k.wid
	local root = P(m, "Hull", V(W, 3, L), cf, k.color, "SmoothPlastic")
	local function part(name, size, lcf, color, mat, opt) return P(m, name, size, cf * lcf, color, mat, opt) end
	part("Deck", V(W - 1, 0.6, L - 2), CFrame.new(0, 1.7, 0), k.deck, "WoodPlanks")
	part("Bow", V(W, 3, 5), CFrame.new(0, 0, -L / 2 - 2.5) * CFrame.Angles(0, math.pi, 0), k.color, "SmoothPlastic", { class = "WedgePart" })
	for _, s in ipairs({ -1, 1 }) do part("Rail", V(0.4, 1.4, L - 2), CFrame.new(s * (W / 2 - 0.2), 2.7, 0), k.color, "SmoothPlastic") end
	part("Stern", V(W, 1.4, 0.4), CFrame.new(0, 2.7, L / 2 - 0.2), k.color, "SmoothPlastic")
	part("Stripe", V(W + 0.1, 0.5, L + 0.1), CFrame.new(0, 0.6, 0), "Bright red", "SmoothPlastic", { nc = true })
	local seat = part("DriverSeat", V(2, 1, 2), CFrame.new(0, 2.5, L / 2 - 4), "Really black", "Fabric", { class = "VehicleSeat" })
	pcall(function() seat.MaxSpeed = 0 seat.Torque = 0 end)   -- the server moves the boat, not the seat
	part("Wheel", V(0.3, 2, 2), CFrame.new(0, 3.6, L / 2 - 5.4) * CFrame.Angles(0, math.rad(90), 0), "Brown", "Wood", { shape = "cyl", nc = true })
	local n = 0
	for z = -L / 2 + 4, L / 2 - 8, 4 do
		for _, x in ipairs({ -W / 2 + 1.6, W / 2 - 1.6 }) do
			n = n + 1
			if n <= 8 then part("Seat", V(2, 1, 2), CFrame.new(x, 2.5, z), "Bright blue", "Fabric", { class = "Seat" }) end
		end
	end
	if k.cabin then
		part("CabinBack", V(W - 2, 6, 0.4), CFrame.new(0, 5, -L / 4 + 3), "Institutional white", "SmoothPlastic")
		part("CabinRoof", V(W - 1, 0.5, L / 3), CFrame.new(0, 8.2, -L / 4 + 3 + L / 6), k.color, "SmoothPlastic")
		for _, s in ipairs({ -1, 1 }) do part("CabinPost", V(0.5, 6, 0.5), CFrame.new(s * (W / 2 - 1), 5, -L / 4 + 3 + L / 3 - 0.5), "Institutional white", "SmoothPlastic") end
	end
	if k.upper then
		part("UpperDeck", V(W - 3, 0.5, L / 3), CFrame.new(0, 8.6, L / 6), "Brick yellow", "WoodPlanks")
		part("Ladder", V(2, 7, 0.4), CFrame.new(W / 2 - 2, 5.2, L / 3 + 1.6), "Dark stone grey", "Metal", { class = "TrussPart" })
	end
	local flag = part("Flag", V(0.2, 2.4, 3.6), CFrame.new(0, 7, L / 2 - 1), "Bright green", "Fabric", { nc = true })
	bill(flag, owner.Name, 8, 2, 3, Color3.new(1, 1, 1))
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p ~= root then weld(root, p) p.Anchored = false end
	end
	root.Anchored = true
	local hpv = Instance.new("IntValue")
	hpv.Name = "Health"
	hpv.Value = k.hp
	hpv.Parent = m
	local look = cf.lookVector
	local b = { model = m, root = root, seat = seat, owner = owner, kind = k, hp = k.hp, hpValue = hpv,
		pos = cf.p, yaw = math.atan2(-look.x, -look.z), speed = 0, vel = V(), lift = 0, spin = 0, riders = {} }
	table.insert(boats, b)
	return b
end
local function giveBoat(player, kind)
	local k = BOAT[kind]
	if not k then return end
	local c = stats(player):FindFirstChild("Coins")
	if k.price > 0 and (not c or c.Value < k.price) then toClient(player, "toast", "You need " .. k.price .. " Coins for the " .. k.key, "red") return end
	if k.price > 0 then c.Value = c.Value - k.price end
	local old = boatOf[player]
	if old then pcall(function() old.model:Destroy() end) end
	local slip = SLIPS[slipFree]
	slipFree = slipFree % #SLIPS + 1
	local x = slip.x * (8 + k.wid / 2 + 3)
	local cf = CFrame.new(x, SEA.level + 1.2, slip.z)   -- bow (-z) out to sea, to the south
	local b = makeBoat(player, kind, cf)
	boatOf[player] = b
	-- put the player in the driver's seat area
	local t = torsoOf(player.Character)
	if t then t.CFrame = b.seat.CFrame + V(0, 4, 0) end
	toClient(player, "toast", "Here's your " .. k.key .. "! Sit in the black seat to drive (W/S/A/D).", "green")
end
click.MouseClick:connect(function(player) toClient(player, "shop", BOATS) end)

-- every frame: drive, float on the waves, get pushed by wind/whirlpools, carry the people standing on deck
local WIND = { v = V() }
local pulls = {}   -- functions(boat, dt) -> extra velocity (whirlpool etc.)
local function waveAt(x, z, t)
	return SEA.waves * (math.sin(x * 0.02 + t * 1.3) + math.sin(z * 0.025 + t * 0.9)) * 0.5
end
local function stepBoats(dt, now)
	for i = #boats, 1, -1 do
		local b = boats[i]
		if not b.model.Parent then
			table.remove(boats, i)
			for p, bv in pairs(b.riders) do pcall(function() bv:Destroy() end) end
			if b.owner and boatOf[b.owner] == b then boatOf[b.owner] = nil end
		else
			local k = b.kind
			if b.sinking then
				b.lift = b.lift - 4 * dt
				b.speed = b.speed * 0.95
				if now - b.sinkAt > 8 then b.model:Destroy() end
			else
				local thr, steer = b.seat.Throttle, b.seat.Steer
				b.yaw = b.yaw - steer * k.turn * dt + b.spin * dt
				b.spin = b.spin * 0.97
				local target = thr * k.speed * (thr < 0 and 0.4 or 1)
				b.speed = b.speed + clamp(target - b.speed, -25 * dt, 18 * dt)
				b.lift = b.lift * (1 - dt)   -- big waves lift a boat, then it settles
			end
			local fwd = V(-math.sin(b.yaw), 0, -math.cos(b.yaw))
			local extra = WIND.v
			for _, f in pairs(pulls) do extra = extra + (f(b, dt) or V()) end
			b.vel = fwd * b.speed + extra
			local np = b.pos + b.vel * dt
			-- the island is solid: boats stop at the shore (the pier slips are outside it)
			local fromIsland = V(np.X, 0, np.Z - 40)
			if fromIsland.magnitude < 128 + k.len / 2 then
				np = V(0, 0, 40) + fromIsland.unit * (128 + k.len / 2)
				b.speed = b.speed * 0.5
			end
			if math.abs(np.X) > 1900 or math.abs(np.Z) > 1900 then np = b.pos b.speed = 0 end   -- the edge of the world
			local wave = waveAt(np.X, np.Z, now)
			local y = SEA.level + 1.2 + wave + b.lift
			b.pos = V(np.X, y, np.Z)
			local roll = math.sin(now * 1.7 + b.pos.X * 0.01) * 0.04 * SEA.waves + (b.sinking and 0.25 or 0)
			local pitch = math.sin(now * 1.3 + b.pos.Z * 0.01) * 0.03 * SEA.waves - clamp(b.speed / 400, -0.05, 0.12)
			b.root.CFrame = CFrame.new(b.pos) * CFrame.Angles(0, b.yaw, 0) * CFrame.Angles(pitch, 0, roll)
			-- people standing on deck move with the boat (seated people are welded to it already)
			local seen = {}
			local inv = b.root.CFrame:inverse()
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local t = torsoOf(c)
				local h = c and c:FindFirstChild("Humanoid")
				if t and h and h.Health > 0 and not h.Sit then
					local l = inv * t.Position
					if math.abs(l.X) < k.wid / 2 + 0.5 and math.abs(l.Z) < k.len / 2 + 2 and l.Y > 0 and l.Y < 14 then
						seen[p] = true
						local bv = b.riders[p]
						if not bv or bv.Parent ~= t then
							bv = Instance.new("BodyVelocity")
							bv.Name = "OnBoat"
							bv.maxForce = V(3e4, 0, 3e4)
							bv.Parent = t
							b.riders[p] = bv
						end
						bv.velocity = V(b.vel.X, 0, b.vel.Z) + h.MoveDirection * 16
					end
				end
			end
			for p, bv in pairs(b.riders) do
				if not seen[p] then pcall(function() bv:Destroy() end) b.riders[p] = nil end
			end
		end
	end
end

------------------------------------------------------------------ swimming: people in the water float at the surface
local swimmers = {}
local function onBoat(t)
	for _, b in ipairs(boats) do
		local l = b.root.CFrame:inverse() * t.Position
		if math.abs(l.X) < b.kind.wid / 2 + 1 and math.abs(l.Z) < b.kind.len / 2 + 3 and l.Y > -1 and l.Y < 14 then return b end
	end
	return nil
end
local function stepSwimmers()
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local t = torsoOf(c)
		local h = c and c:FindFirstChild("Humanoid")
		local bp = swimmers[p]
		local inWater = t and h and h.Health > 0 and not h.Sit and t.Position.Y < SEA.level + 1.5 and not onBoat(t)
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
		elseif bp and (not t or t.Position.Y > SEA.level + 2.5 or not h or h.Health <= 0 or h.Sit) then
			pcall(function() bp:Destroy() end)
			swimmers[p] = nil
			if h then h.WalkSpeed = 16 end
		end
		if t and t.Position.Y < -50 and h then h.Health = 0 end
	end
end

------------------------------------------------------------------ disasters
local active = {}      -- running disasters: { name, stop() }
local junk = model(WORLD, "Disaster")
local function players()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local t, h = torsoOf(c), c and c:FindFirstChild("Humanoid")
		if t and h and h.Health > 0 then table.insert(out, { p = p, t = t, h = h }) end
	end
	return out
end
local function hurtNear(pos, radius, dmg, boatDmg, why)
	for _, x in ipairs(players()) do
		local d = (x.t.Position - pos).magnitude
		if d < radius then x.h:TakeDamage(dmg * (1 - 0.5 * d / radius)) end
	end
	for _, b in ipairs(boats) do
		if (b.pos - pos).magnitude < radius + b.kind.len / 2 then damageBoat(b, boatDmg, why) end
	end
end
local function fling(x, vel, time, flat)
	local bv = Instance.new("BodyVelocity")
	bv.maxForce = flat and V(2e4, 0, 2e4) or V(4e4, 4e4, 4e4)
	bv.velocity = vel
	bv.Parent = x.t
	Debris:AddItem(bv, time or 0.4)
end
local function boom(pos, size)
	local e = Instance.new("Explosion")
	e.Position = pos
	e.BlastRadius = size
	pcall(function() e.BlastPressure = 0 end)
	pcall(function() e.DestroyJointRadiusPercent = 0 end)
	e.Parent = workspace
end
local function somewhereNear(radius)
	local list = players()
	local c = #list > 0 and pick(list).t.Position or V(0, 0, -300)
	return V(c.X + math.random(-radius, radius), SEA.level, c.Z + math.random(-radius, radius))
end
local function seaSpot(minR, maxR)
	local a, r = math.random() * math.pi * 2, math.random(minR, maxR)
	return V(math.cos(a) * r, SEA.level, 40 + math.sin(a) * r)
end

local DIS = {}
-- TORNADO: a spinning funnel that chases people; close up it flings you and spins boats round
DIS.Tornado = { text = "TORNADO! Stay away from the funnel!", run = function(dur)
	local m = model(junk, "Tornado")
	local rings = {}
	for i = 0, 11 do
		local d = 14 + i * 5
		local r = cyl(m, "Funnel", d, 10, 0, i * 10, 0, i % 2 == 0 and "Dark stone grey" or "Medium stone grey", "SmoothPlastic", { tr = 0.45, nc = true })
		table.insert(rings, { part = r, y = i * 10 + 5, d = d })
	end
	local pos = seaSpot(250, 400)
	local t0 = tick()
	local alive = true
	pulls.tornado = function(b, dt)
		local d = V(pos.X - b.pos.X, 0, pos.Z - b.pos.Z)
		local dist = d.magnitude
		if dist < 70 then
			b.spin = b.spin + 3 * dt
			damageBoat(b, 18 * dt, "tornado")
			return d.unit:Cross(V(0, 1, 0)) * 25
		end
		return nil
	end
	spawn(function()
		while alive do
			local dt = wait(0.1)
			local now = tick()
			-- drift towards the nearest player
			local best, bd
			for _, x in ipairs(players()) do
				local d = (V(x.t.Position.X, 0, x.t.Position.Z) - V(pos.X, 0, pos.Z)).magnitude
				if not bd or d < bd then best, bd = x, d end
			end
			local dir = best and (V(best.t.Position.X, 0, best.t.Position.Z) - V(pos.X, 0, pos.Z)) or V(1, 0, 0)
			if dir.magnitude > 1 then pos = pos + dir.unit * 16 * dt + V(math.sin(now) * 6, 0, math.cos(now * 0.7) * 6) * dt end
			for i, r in ipairs(rings) do
				r.part.CFrame = CFrame.new(pos.X + math.sin(now * 2 + i) * i * 0.6, SEA.level + r.y, pos.Z) * CFrame.Angles(0, now * 4 + i, math.rad(90))
			end
			for _, x in ipairs(players()) do
				local d = V(x.t.Position.X - pos.X, 0, x.t.Position.Z - pos.Z)
				if d.magnitude < 35 then
					x.h:TakeDamage(12 * dt * 2)
					local around = d.magnitude > 0.1 and d.unit:Cross(V(0, 1, 0)) or V(1, 0, 0)
					fling(x, around * 60 + V(0, 45, 0) - d.unit * 20, 0.3)
				end
			end
		end
	end)
	return function() alive = false pulls.tornado = nil m:Destroy() end
end }
-- TSUNAMI: a giant wave sweeps across the whole map. In a boat you ride it out; on the island or in the water it
-- knocks you down hard, and the island floods for a while afterwards.
DIS.Tsunami = { text = "TSUNAMI! Get on a boat and ride the wave!", run = function(dur)
	local m = model(junk, "Tsunami")
	local wall = P(m, "Wave", V(2000, 70, 50), CFrame.new(0, 30, 1100), "Bright blue", "SmoothPlastic", { tr = 0.2, nc = true })
	local foam = P(m, "Foam", V(2000, 6, 54), CFrame.new(0, 66, 1100), "Institutional white", "SmoothPlastic", { tr = 0.1, nc = true })
	local z = 1100
	local alive = true
	local hit = {}
	spawn(function()
		wait(6)   -- you can see it coming
		while alive and z > -1100 do
			local dt = wait(0.05)
			z = z - 55 * dt
			wall.CFrame = CFrame.new(0, SEA.level + 30, z)
			foam.CFrame = CFrame.new(0, SEA.level + 66, z)
			for _, b in ipairs(boats) do
				if not hit[b] and math.abs(b.pos.Z - z) < 30 then
					hit[b] = true
					b.lift = 28
					damageBoat(b, b.kind.hp * 0.2, "tsunami")
				end
			end
			for _, x in ipairs(players()) do
				if not hit[x.p] and math.abs(x.t.Position.Z - z) < 28 and not onBoat(x.t) and not x.h.Sit then
					hit[x.p] = true
					x.h:TakeDamage(65)
					fling(x, V(0, 40, -80), 0.5)
				end
			end
			-- the island floods when the wave reaches it
			if z < 60 and SEA.level < 9 then setSea(math.min(9, SEA.level + 6 * dt)) end
		end
		wall.Transparency = 1
		foam.Transparency = 1
	end)
	return function()
		alive = false
		m:Destroy()
		spawn(function()
			while SEA.level > SEA.base + 0.05 do wait(0.1) setSea(math.max(SEA.base, SEA.level - 0.3)) end
		end)
	end
end }
-- HURRICANE: dark sky, rain, big waves, strong wind that pushes boats around, and lightning strikes
DIS.Hurricane = { text = "HURRICANE! Strong wind, huge waves and lightning!", run = function(dur)
	local alive = true
	local old = { t = Lighting.TimeOfDay, fog = Lighting.FogEnd, fogc = Lighting.FogColor, amb = Lighting.OutdoorAmbient }
	pcall(function()
		Lighting.TimeOfDay = "19:00:00"
		Lighting.FogEnd = 450
		Lighting.FogColor = Color3.new(0.35, 0.38, 0.42)
		Lighting.OutdoorAmbient = Color3.new(0.35, 0.35, 0.4)
	end)
	toAll("weather", "storm")
	SEA.waves = 4
	spawn(function()
		local a = math.random() * 6
		while alive do
			wait(0.2)
			a = a + 0.02
			WIND.v = V(math.cos(a), 0, math.sin(a)) * 22
			for _, x in ipairs(players()) do
				if not x.h.Sit and not onBoat(x.t) then fling(x, WIND.v * 0.6 + x.h.MoveDirection * 12, 0.15, true) end
			end
		end
	end)
	spawn(function()
		while alive do
			wait(math.random(15, 35) / 10)
			local at = somewhereNear(60)
			local bolt = P(junk, "Lightning", V(1.2, 300, 1.2), CFrame.new(at + V(0, 150, 0)), "Institutional white", "Neon", { nc = true })
			light(bolt, Color3.new(0.8, 0.9, 1), 60, 5)
			Debris:AddItem(bolt, 0.25)
			toAll("flash")
			hurtNear(at, 10, 30, 40, "lightning")
		end
	end)
	return function()
		alive = false
		WIND.v = V()
		SEA.waves = 1
		toAll("weather", "clear")
		pcall(function()
			Lighting.TimeOfDay = old.t
			Lighting.FogEnd = old.fog
			Lighting.FogColor = old.fogc
			Lighting.OutdoorAmbient = old.amb
		end)
	end
end }
-- METEOR SHOWER: burning rocks fall out of the sky near people and explode
DIS["Meteor Shower"] = { text = "METEOR SHOWER! Watch the sky!", run = function(dur)
	local alive = true
	spawn(function()
		while alive do
			wait(0.7)
			local at = somewhereNear(90)
			local land = at.Y + 2
			local m = P(junk, "Meteor", V(6, 6, 6), CFrame.new(at.X + 60, 420, at.Z), "Black", "Slate", { shape = "ball", nc = true })
			local f = Instance.new("Fire")
			f.Size = 12
			f.Heat = 20
			f.Parent = m
			light(m, Color3.new(1, 0.5, 0.1), 30, 3)
			spawn(function()
				local y, x = 420, at.X + 60
				while y > land and m.Parent do
					local dt = wait(0.03)
					y = y - 160 * dt
					x = x - 23 * dt
					m.CFrame = CFrame.new(x, y, at.Z)
				end
				if m.Parent then
					m:Destroy()
					boom(V(x, land, at.Z), 10)
					hurtNear(V(x, land, at.Z), 14, 35, 45, "meteor")
				end
			end)
		end
	end)
	return function() alive = false end
end }
-- WHIRLPOOL: a giant whirlpool pulls boats and swimmers round and in; the middle hurts
DIS.Whirlpool = { text = "WHIRLPOOL! Don't get pulled into the middle!", run = function(dur)
	local m = model(junk, "Whirlpool")
	local c = seaSpot(200, 320)
	local rings = {}
	for i = 1, 6 do
		local r = cyl(m, "Swirl", i * 30, 0.6, c.X, SEA.level - 0.2 - i * 0.3, c.Z, i % 2 == 0 and "Navy blue" or "Bright bluish green", "SmoothPlastic", { tr = 0.35, nc = true })
		table.insert(rings, r)
	end
	local alive = true
	pulls.whirlpool = function(b, dt)
		local d = V(c.X - b.pos.X, 0, c.Z - b.pos.Z)
		local dist = d.magnitude
		if dist > 220 or dist < 0.1 then return nil end
		local s = (220 - dist) / 220
		if dist < 25 then damageBoat(b, 30 * dt, "whirlpool") end
		return (d.unit * 14 + d.unit:Cross(V(0, 1, 0)) * 30) * s
	end
	spawn(function()
		while alive do
			local dt = wait(0.1)
			for i, r in ipairs(rings) do r.CFrame = CFrame.new(c.X, SEA.level - 0.2 - i * 0.3, c.Z) * CFrame.Angles(0, tick() * (2 - i * 0.2), math.rad(90)) end
			for _, x in ipairs(players()) do
				local d = V(c.X - x.t.Position.X, 0, c.Z - x.t.Position.Z)
				if d.magnitude < 200 and swimmers[x.p] then
					fling(x, (d.unit * 10 + d.unit:Cross(V(0, 1, 0)) * 18), 0.15, true)
					if d.magnitude < 25 then x.h:TakeDamage(20 * dt) end
				end
			end
		end
	end)
	return function() alive = false pulls.whirlpool = nil m:Destroy() end
end }
-- SHARK ATTACK: sharks hunt anyone in the water and bump into small boats
DIS["Shark Attack"] = { text = "SHARK ATTACK! Stay out of the water!", run = function(dur)
	local sharks = {}
	for i = 1, 6 do
		local m = model(junk, "Shark")
		local at = seaSpot(150, 400)
		local body = P(m, "Body", V(3, 2.5, 12), CFrame.new(at), "Medium stone grey", "SmoothPlastic")
		local fin = P(m, "Fin", V(0.4, 3.5, 3), CFrame.new(at + V(0, 2.5, 0)), "Dark stone grey", "SmoothPlastic", { class = "WedgePart" })
		local tail = P(m, "Tail", V(0.4, 3, 2.5), CFrame.new(at + V(0, 0.5, 6.5)), "Medium stone grey", "SmoothPlastic", { class = "WedgePart" })
		weld(body, fin) weld(body, tail)
		fin.Anchored, tail.Anchored = false, false
		table.insert(sharks, { m = m, root = body, pos = at, look = V(0, 0, -1), next = 0 })
	end
	local alive = true
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
				if not best then
					for _, b in ipairs(boats) do
						if b.kind.len < 25 and not b.sinking then
							local d = (b.pos - s.pos).magnitude
							if not bd or d < bd then best, bd = b.pos, d end
						end
					end
				end
				local goal = best or (s.pos + s.look * 20)
				local d = V(goal.X - s.pos.X, 0, goal.Z - s.pos.Z)
				if d.magnitude > 0.5 then s.look = (s.look * 0.9 + d.unit * 0.1).unit end
				s.pos = V(s.pos.X, SEA.level - 1.2, s.pos.Z) + s.look * (best and 20 or 10) * dt
				s.root.CFrame = CFrame.new(s.pos, s.pos + s.look)
				if best and bd < 6 and now > s.next then
					s.next = now + 1.5
					hurtNear(s.pos, 7, 25, 15, "sharks")
				end
			end
		end
	end)
	return function() alive = false for _, s in ipairs(sharks) do s.m:Destroy() end end
end }
local ORDER = { "Tornado", "Tsunami", "Hurricane", "Meteor Shower", "Whirlpool", "Shark Attack" }

------------------------------------------------------------------ rounds
local STATE = { phase = "intermission", left = 0, disaster = "" }
local inRound = {}
local function status()
	toAll("status", STATE.phase, STATE.left, STATE.disaster)
end
local function sendBoat(p)
	local b = boatOf[p]
	toClient(p, "boat", b and b.kind.key or nil, b and math.max(0, math.floor(b.hp)) or 0, b and b.kind.hp or 0, b and math.floor(math.abs(b.speed)) or 0)
end
spawn(function()
	local round = 0
	while true do
		-- intermission: everyone gets their boat ready
		STATE.phase, STATE.disaster = "intermission", ""
		for s = 25, 1, -1 do
			STATE.left = s
			status()
			wait(1)
		end
		if #Players:GetPlayers() > 0 then
			round = round + 1
			local list = { pick(ORDER) }
			if round >= 3 and math.random() < 0.3 then   -- sometimes two at once
				local second = pick(ORDER)
				if second ~= list[1] then table.insert(list, second) end
			end
			local names = table.concat(list, " + ")
			STATE.phase, STATE.disaster = "disaster", names
			inRound = {}
			for _, x in ipairs(players()) do inRound[x.p] = true end
			local texts = {}
			for _, n in ipairs(list) do table.insert(texts, DIS[n].text) end
			toAll("disaster", names, table.concat(texts, "  "))
			local stops = {}
			for _, n in ipairs(list) do
				local ok, stop = pcall(DIS[n].run, 70)
				if ok and stop then table.insert(stops, stop) else print("OceanServer: " .. n .. " failed: " .. tostring(stop)) end
			end
			for s = 70, 1, -1 do
				STATE.left = s
				status()
				wait(1)
			end
			for _, stop in ipairs(stops) do pcall(stop) end
			junk:ClearAllChildren()
			-- who made it?
			local survivors = {}
			for _, x in ipairs(players()) do
				if inRound[x.p] then
					table.insert(survivors, x.p.Name)
					local bonus = (boatOf[x.p] and not boatOf[x.p].sinking) and 20 or 0
					addCoins(x.p, 40 + bonus)
					local s = stats(x.p):FindFirstChild("Survived")
					if s then s.Value = s.Value + 1 end
					toClient(x.p, "toast", "You survived the " .. names .. "! +" .. (40 + bonus) .. " Coins", "green")
				end
			end
			toAll("survivors", survivors)
			STATE.phase = "results"
			for s = 6, 1, -1 do
				STATE.left = s
				status()
				wait(1)
			end
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
Players.PlayerRemoving:connect(function(p)
	local b = boatOf[p]
	if b then pcall(function() b.model:Destroy() end) end
	boatOf[p], swimmers[p], inRound[p] = nil, nil, nil
end)
remote.OnServerEvent:connect(function(p, what, a)
	if what == "buyBoat" and type(a) == "string" and BOAT[a] then
		local t = torsoOf(p.Character)
		if t and (t.Position - dmTorso.Position).magnitude < 60 then giveBoat(p, a)
		else toClient(p, "toast", "Go to the Dockmaster on the pier to get a boat", "red") end
	elseif what == "state" then
		status()
	end
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
		local ok, err = pcall(stepBoats, dt, now)
		if not ok then print("OceanServer: boats: " .. tostring(err)) end
		n = n + 1
		if n % 3 == 0 then
			ok, err = pcall(stepSwimmers)
			if not ok then print("OceanServer: swimming: " .. tostring(err)) end
		end
		if n % 15 == 0 then for _, p in ipairs(Players:GetPlayers()) do sendBoat(p) end end
	end
end)
_G.OceanDebug = { boats = boats, boatOf = boatOf, giveBoat = giveBoat, DIS = DIS, SEA = SEA, swimmers = swimmers, STATE = STATE, damageBoat = damageBoat }
print("OceanServer ready")
