-- ==== s29_resort.lua
------------------------------------------------------------------ Paradise Island: a far-away airport with a theme park
-- An island in the northern sea (world x -1320..900, z 1840..3000), built once when the server starts. Every airliner
-- flies there from its home airport, lands, parks at one of 18 stands, takes off again and flies home (s50_planes.lua).
-- Planes land on the north runway (heading east) and take off from the south runway (also heading east), so they never
-- meet on a runway. Each plane gets a landing slot when it leaves home (slots are a few seconds apart); if its slot is
-- later than it would arrive, it flies slower and/or laps the holding pattern (each plane at its own height) first.
-- On the ground a plane stops behind any plane in front of it, and waits at the holding point for the take-off runway.
-- The theme park next to the airport (s29_rides.lua) has 10 rides that really move; sit in any seat to ride.
-- Everything here is in world coordinates.
local RESORT = { x0 = -1320, x1 = 900, z0 = 1840, z1 = 3000, rz = 1990, dz = 1895, H = 7.3, stands = {},
	entrance = CFrame.new(-150, 4, 2290), nextLanding = 0, nextTakeoff = 0, ready = false,
	gap = 9,             -- seconds between landings
	takeoffGap = 12,     -- seconds between take-offs
	maxDelay = 90,       -- a plane whose landing slot is further away than this flies a sightseeing loop at home instead
	planes = {}, level = 0, holds = {} }
local RIDES = {}           -- ride objects with .step(dt)
local V = Vector3.new
local function WB(model) return { model = model, cf = CFrame.new() } end

-- stands: one row along the apron, planes park nose north (towards the terminal)
for i = 0, 17 do table.insert(RESORT.stands, { x = -1140 + i * 48, z = 2115 }) end
function RESORT.standCF(st) return CFrame.new(st.x, RESORT.H, st.z) * CFrame.Angles(0, math.pi, 0) end
-- reserve a free stand for a plane (nil if they're all taken)
function RESORT.reserve(gp)
	for _, st in ipairs(RESORT.stands) do
		local o = st.occ
		if not o or not o.model.Parent or o.stand ~= st then
			st.occ = gp
			gp.stand = st
			return st
		end
	end
	return nil
end

------------------------------------------------------------------ flight paths at the island (world space)
local function wpath(list, from, loop, r)
	local out = {}
	if from then table.insert(out, { p = from, v = 125 }) end
	for _, q in ipairs(list) do table.insert(out, { p = V(q[1], q[2], q[3]), v = q[4], back = q[5] }) end
	return FLY.path(FLY.round(out, r or 10), loop)
end
local H, RZ, DZ = RESORT.H, RESORT.rz, RESORT.dz
-- approach from the west, land heading east on the north runway, roll to its east end, turn off, then taxi west to
-- the stand (everyone on the taxiway goes west, so planes never meet head-on)
function RESORT.landing(st, from)
	return wpath({
		{ -2000, 320, RZ, 120 }, { -1500, 150, RZ, 105 }, { -1150, H + 0.3, RZ, 90 }, { -950, H, RZ, 60 }, { -700, H, RZ, 38 },
		{ -450, H, RZ, 24 }, { -305, H, RZ, 16 }, { -272, H, 2018, 12 }, { -276, H, 2044, 12 }, { -300, H, 2050, 16 },
		{ st.x + 30, H, 2050, 18 }, { st.x + 16, H, 2050, 10 }, { st.x + 2, H, 2066, 6 }, { st.x, H, 2080, 5 }, { st.x, H, st.z, 4 } }, from)
end
-- push back, taxi west, cross to the south runway at its west end, wait there until it's free, take off heading east
function RESORT.takeoff(st)
	local P = wpath({
		{ st.x, H, st.z, 4, true }, { st.x, H, 2078, 4, true }, { st.x + 6, H, 2062, 4, true }, { st.x - 10, H, 2050, 12 },
		{ st.x - 40, H, 2050, 18 }, { -1205, H, 2050, 18 }, { -1222, H, 2050, 12 }, { -1240, H, 2034, 12 }, { -1240, H, 1940, 16 }, { -1236, H, 1912, 8 }, { -1222, H, DZ, 10 },
		{ -1190, H, DZ, 25 }, { -1080, H, DZ, 55 }, { -880, H, DZ, 85 }, { -700, 40, DZ, 95 }, { -300, 170, DZ, 110 },
		{ 700, 320, DZ, 120 } })
	-- the holding point: just before the plane rolls onto the runway
	P.holdT = P.total
	for i, q in ipairs(P.pts) do
		if q.p.z < 1950 and q.p.x < -1200 then P.holdT = P.t[i] break end
	end
	return P
end
-- the holding pattern west of the island: from the approach point climb to this plane's height, fly `laps` laps,
-- then come back down to the approach point, heading east
function RESORT.holdPath(laps, level)
	local key = laps .. ":" .. level
	if RESORT.holds[key] then return RESORT.holds[key] end
	local alt = 420 + 60 * level
	local pts = { { -2000, 320, RZ, 120 } }
	for _ = 1, laps do
		for _, q in ipairs({ { -1400, alt, RZ }, { -1400, alt, RZ + 700 }, { -2700, alt, RZ + 700 }, { -2700, alt, RZ } }) do
			table.insert(pts, { q[1], q[2], q[3], 120 })
		end
	end
	table.insert(pts, { -2000, 320, RZ, 120 })
	local P = wpath(pts, nil, false, 250)
	RESORT.holds[key] = P
	return P
end
-- Book a landing slot for a plane that is about to fly the outbound leg (leg = its path from home to the approach
-- point). Returns false if Paradise is too busy (no stand, or the slot is too far away). Otherwise sets
-- gp.speed (how fast it flies the leg, 1 = normal) and gp.holdPath / gp.holdSpeed (laps to fly before landing).
function RESORT.book(gp, leg, now)
	local eta = now + leg.total
	local slot = math.max(eta, RESORT.nextLanding)
	local d = slot - eta
	if d > RESORT.maxDelay then return false end
	if not RESORT.reserve(gp) then return false end
	RESORT.nextLanding = slot + RESORT.gap
	RESORT.planes[gp] = true
	gp.slot = slot
	-- whole holding laps first (as many as fit in the wait), then fly the leg slower for whatever is left
	local hold
	RESORT.level = (RESORT.level + 1) % 4
	for laps = 1, 4 do
		local P = RESORT.holdPath(laps, RESORT.level)
		if P.total <= d then hold = P else break end
	end
	local rest = d - (hold and hold.total or 0)
	gp.speed = leg.total / (leg.total + rest)
	gp.holdPath, gp.holdSpeed = hold, 1
	return true
end
-- a parked plane only pushes back when no other plane is taxiing near its stand or coming along the taxiway towards it
-- (everyone on the taxiway goes west, so they come from the east)
function RESORT.clearToPush(st)
	for o in pairs(RESORT.planes) do
		if o.model.Parent and (o.state == "resortLanding" or (o.state == "resortTakeoff" and not o.cleared)) then
			local q = o.root.CFrame.p
			local dx = q.x - st.x
			if q.y < 12 and dx > -70 and dx < 170 and q.z > 2005 then return false end
		end
	end
	return true
end
-- on the ground: the plane right in front of this one (it stops and waits), if any. Two planes never wait for each
-- other, a plane being pushed back never waits, and a plane that has waited a long time goes anyway, so they can
-- never get stuck for ever.
function RESORT.blocker(gp, t, now)
	if gp.ignoreUntil and now < gp.ignoreUntil then return nil end
	local P = gp.path
	-- a pushback, once started, always finishes (it only starts when the taxiway near the stand is clear), and
	-- everyone else waits for it: stopping halfway would leave its tail on the taxiway
	local _, back = FLY.at(P, t)
	if back then gp.waitSince = nil return nil end
	local d = FLY.at(P, t + 1) - FLY.at(P, math.max(0, t - 0.2))
	d = V(d.x, 0, d.z)
	if d.magnitude < 0.01 then return nil end
	d = d.unit
	local me = gp.root.CFrame.p
	for o in pairs(RESORT.planes) do
		if not o.model.Parent then
			RESORT.planes[o] = nil
		elseif o ~= gp and o.waitingFor ~= gp and (o.state == "resortLanding" or o.state == "resortTakeoff") then
			local q = o.root.CFrame.p
			local off = V(q.x - me.x, 0, q.z - me.z)
			if q.y < 12 and off.magnitude < 64 and off.magnitude > 0.01 and (d.x * off.x + d.z * off.z) > 0.6 * off.magnitude then
				gp.waitSince = gp.waitSince or now
				if now - gp.waitSince > 25 then gp.ignoreUntil, gp.waitSince = now + 10, nil return nil end
				return o
			end
		end
	end
	gp.waitSince = nil
	return nil
end
-- a long flight between two points: away from a in direction da, up high in the middle, then towards b in direction db
function RESORT.leg(a, da, b, db)
	local a2, b2 = a + da * 700, b - db * 700
	local mid = (a2 + b2) / 2 + V(0, 160, 0)
	return FLY.path(FLY.round({ { p = a, v = 120 }, { p = a2, v = 130 }, { p = mid, v = 140 }, { p = b2, v = 130 }, { p = b, v = 120 } }, 250), false)
end
RESORT.approachStart = V(-2000, 320, RZ)
RESORT.departEnd = V(700, 320, DZ)

------------------------------------------------------------------ the island and its airport
local function palm(b, x, z, h)
	h = h or 14
	U.P(b, "PalmTrunk", V(1.2, h, 1.2), CFrame.new(x, h / 2, z) * CFrame.Angles(0, 0, math.rad(6)), "Brown", "Wood")
	for a = 0, 300, 60 do
		local r = math.rad(a)
		U.P(b, "PalmLeaf", V(1.6, 0.3, 8), CFrame.new(x + math.cos(r) * 3.4 + h * 0.1, h, z + math.sin(r) * 3.4) * CFrame.Angles(0, -r + math.pi / 2, 0) * CFrame.Angles(math.rad(-20), 0, 0), "Bright green", "Grass", { nc = true })
	end
	U.ball(b, "Coconut", 1.2, x + h * 0.1, h - 0.6, z, "Brown")
end
RESORT.palm = palm

function RESORT.buildIsland(root)
	local m = Instance.new("Model")
	m.Name = "Island"
	m.Parent = root
	local b = WB(m)
	local cx, cz = (RESORT.x0 + RESORT.x1) / 2, (RESORT.z0 + RESORT.z1) / 2
	local w, d = RESORT.x1 - RESORT.x0, RESORT.z1 - RESORT.z0
	U.blk(b, "Sand", w + 60, 3.6, d + 60, cx, -3.8, cz, "Brick yellow", "Sand")
	U.blk(b, "Grass", w, 4, d, cx, -4, cz, "Bright green", "Grass")
	for i = 1, 40 do
		local side = i % 4
		local x = side < 2 and math.random(RESORT.x0, RESORT.x1) or (side == 2 and RESORT.x0 - 18 or RESORT.x1 + 18)
		local z = side >= 2 and math.random(RESORT.z0, RESORT.z1) or (side == 0 and RESORT.z0 - 18 or RESORT.z1 + 18)
		if not (x < -150 and z < 2240) then palm(b, x, z, math.random(11, 17)) end
	end
	local s = U.blk(b, "IslandSign", 60, 12, 1.2, 0, 4, 1860, "Navy blue", "SmoothPlastic")
	U.text(s, "PARADISE ISLAND", Color3.new(1, 0.85, 0.3), nil, "Front")
	U.text(s, "PARADISE ISLAND", Color3.new(1, 0.85, 0.3), nil, "Back")
	for _, dx in ipairs({ -24, 24 }) do U.blk(b, "SignPost", 1, 4, 1, dx, 0, 1860, "Dark stone grey", "Metal") end
end

function RESORT.buildAirport(root)
	local m = Instance.new("Model")
	m.Name = "Paradise Airport"
	m.Parent = root
	local b = WB(m)
	-- two runways (north: landings, south: take-offs), the taxiway, the apron
	for _, r in ipairs({ { RZ, -700, 60, -1150 }, { DZ, -790, 50, -1240 } }) do
		local z, cx, wd, x0 = r[1], r[2], r[3], r[4]
		U.blk(b, "Runway", 920, 0.3, wd, cx, 0, z, "Really black", "Concrete")
		for x = x0 + 20, cx + 430, 30 do U.blk(b, "Center", 14, 0.05, 1, x, 0.3, z, "Institutional white", nil, { nc = true }) end
		for dz = -wd / 2 + 6, wd / 2 - 6, 6 do U.blk(b, "Threshold", 12, 0.05, 2.4, x0 + 2, 0.3, z + dz, "Institutional white", nil, { nc = true }) end
		for x = cx - 455, cx + 455, 35 do
			for _, s in ipairs({ -1, 1 }) do U.blk(b, "RunwayLight", 0.8, 0.5, 0.8, x, 0.3, z + s * (wd / 2 + 0.4), "Lime green", "Neon", { nc = true }) end
		end
	end
	U.blk(b, "Taxiway", 1020, 0.3, 24, -750, 0, 2050, "Dark stone grey", "Concrete")
	for x = -1250, -250, 14 do U.blk(b, "TaxiLine", 7, 0.05, 0.6, x, 0.3, 2050, "Bright yellow", nil, { nc = true }) end
	U.blk(b, "Connector", 30, 0.3, 36, -268, 0, 2032, "Dark stone grey", "Concrete")
	U.blk(b, "Connector", 24, 0.3, 160, -1240, 0, 1972, "Dark stone grey", "Concrete")
	U.blk(b, "HoldLine", 24, 0.05, 1, -1240, 0.3, 1946, "Bright yellow", nil, { nc = true })
	U.blk(b, "Apron", 860, 0.3, 90, -740, 0, 2107, "Medium stone grey", "Concrete")
	for i, st in ipairs(RESORT.stands) do
		U.blk(b, "LeadIn", 0.8, 0.05, 60, st.x, 0.3, 2100, "Bright yellow", nil, { nc = true })
		local n = U.P(b, "StandNumber", V(6, 0.05, 4), CFrame.new(st.x, 0.33, 2142), "Bright yellow", nil, { nc = true })
		U.text(n, tostring(i), Color3.new(0, 0, 0), nil, "Top")
	end
	-- terminal: a long glass hall; visitors walk through it to the theme park at its east end
	U.blk(b, "TerminalFloor", 910, 1, 50, -705, 0, 2182, "Institutional white", "Marble")
	U.blk(b, "TerminalGlass", 900, 16, 0.6, -705, 1, 2158, "Pastel light blue", "Glass", { tr = 0.45 })
	U.blk(b, "TerminalBack", 900, 16, 0.6, -705, 1, 2206, "Institutional white", "SmoothPlastic")
	for x = -1160, -250, 30 do U.blk(b, "Frame", 1, 16, 1, x, 1, 2158, "Institutional white", "SmoothPlastic") end
	U.blk(b, "TerminalRoof", 912, 1.2, 52, -705, 17, 2182, "Bright orange", "SmoothPlastic")
	U.blk(b, "RoofWave", 912, 2, 6, -705, 18, 2160, "Cyan", "SmoothPlastic")
	local s = U.blk(b, "TerminalSign", 120, 10, 1, -705, 19, 2157, "Navy blue", "SmoothPlastic")
	U.text(s, "PARADISE INTERNATIONAL AIRPORT", Color3.new(1, 0.85, 0.3), nil, "Front")
	U.text(s, "PARADISE INTERNATIONAL AIRPORT", Color3.new(1, 0.85, 0.3), nil, "Back")
	for x = -1100, -300, 100 do
		U.seat(b, x - 6, 1, 2200, 180, "Cyan", 6)
		U.seat(b, x + 6, 1, 2200, 180, "Cyan", 6)
		U.light(U.blk(b, "HallLamp", 2, 0.4, 2, x, 16.6, 2182, "Institutional white", "Neon", { nc = true }), nil, 30)
	end
	local ws = U.blk(b, "ParkSign", 30, 5, 0.6, -270, 9, 2205.5, "Hot pink", "SmoothPlastic")
	U.text(ws, "THEME PARK  >>>", Color3.new(1, 1, 1), nil, "Front")
	-- tower
	U.cyl(b, "TowerShaft", 7, 44, -1185, 0, 2235, "Institutional white", "Concrete")
	U.cyl(b, "TowerCab", 13, 7, -1185, 44, 2235, "Pastel light blue", "Glass", { tr = 0.35 })
	U.cyl(b, "TowerRoof", 15, 1.2, -1185, 51, 2235, "Bright orange", "SmoothPlastic")
	-- the walk from the terminal to the theme park
	U.blk(b, "Walkway", 120, 0.4, 16, -200, 0, 2214, "Brick yellow", "Concrete")
	U.blk(b, "Walkway", 16, 0.4, 90, -148, 0, 2255, "Brick yellow", "Concrete")
	U.blk(b, "Walkway", 30, 0.4, 50, -240, 0, 2190, "Brick yellow", "Concrete")
	for x = -1100, -300, 100 do palm(b, x, 2228, 13) end
	-- a few ground vehicles parked on the apron
	for _, x in ipairs({ -1170, -290 }) do
		U.blk(b, "Tug", 4, 2.6, 5, x, 0.3, 2148, "Bright yellow", "SmoothPlastic")
		U.blk(b, "BagCart", 4, 2.4, 5, x, 0.6, 2141, "Light stone grey", "Metal")
	end
end
