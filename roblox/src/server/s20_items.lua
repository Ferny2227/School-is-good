-- ==== s20_items.lua
------------------------------------------------------------------ item builders
-- K.<kind>(b, o): b = { model, cf (plot origin), plot }, o = the item's "at" table from the catalog.
-- Plot space: x -300..300, z 0 (front) .. 900 (back). Terminal floor top is y = 1 (x -140..140, z 60..320);
-- the 2nd and 3rd floors are LV[2] and LV[3] (see s01_more.lua and s25_floors.lua).
local F = 1
local WALL_H = 28
-- staff stand here (role -> list of CFrames), passengers walk to these points
local function SPOT(b, role, x, y, z, ry)
	local s = b.plot.spots
	s[role] = s[role] or {}
	table.insert(s[role], b.cf * U.L(x, y, z, ry or 0))
end
local POSKEYS = { a = true, b = true, c = true, p = true, q = true, door = true, e = true }
local function PT(b, kind, t)
	local out = {}
	for k, v in pairs(t) do out[k] = POSKEYS[k] and b.cf * v or v end
	local p = b.plot.pts
	p[kind] = p[kind] or {}
	table.insert(p[kind], out)
end
local V = Vector3.new

local function car(b, x, z, ry, color)
	U.blk(b, "Car", 5, 2, 9, x, 0.6, z, color, "SmoothPlastic", nil, ry)
	U.P(b, "CarTop", V(4.4, 1.6, 4.5), U.L(x, 3.4, z, ry) * CFrame.new(0, 0, 0.5), color, "SmoothPlastic")
	U.P(b, "CarGlass", V(4.5, 1.2, 4.6), U.L(x, 3.4, z, ry) * CFrame.new(0, 0, 0.5), "Pastel light blue", "Glass", { tr = 0.5 })
	for _, w in ipairs({ { -2.4, -3 }, { 2.4, -3 }, { -2.4, 3 }, { 2.4, 3 } }) do
		U.P(b, "Wheel", V(0.8, 1.6, 1.6), U.L(x, 0.8, z, ry) * CFrame.new(w[1], 0, w[2]), "Really black", nil, { shape = "cyl" })
	end
end
local function counter(b, w, d, h, x, z, ry, color)
	return U.P(b, "Counter", V(w, h, d), U.L(x, F + h / 2, z, ry), color, "SmoothPlastic")
end
local function hangSign(b, text, w, h, x, y, z, ry, bg, fg)
	local s = U.P(b, "Sign", V(w, h, 0.4), U.L(x, y, z, ry), "Really black", "SmoothPlastic")
	U.text(s, text, fg or Color3.new(1, 1, 1), bg or Color3.new(0.1, 0.12, 0.18), "Front")
	U.text(s, text, fg or Color3.new(1, 1, 1), bg or Color3.new(0.1, 0.12, 0.18), "Back")
	return s
end
-- a booth/room against a wall: frame `c` is the room's centre on the floor, its open front faces -z (local)
local function booth(b, c, w, d, h, color, title, glass)
	local bb = { model = b.model, cf = c, plot = b.plot }
	U.blk(bb, "Back", w, h, 0.6, 0, F, d / 2, color, "SmoothPlastic")
	U.blk(bb, "Side", 0.6, h, d, -w / 2, F, 0, color, "SmoothPlastic")
	U.blk(bb, "Side", 0.6, h, d, w / 2, F, 0, color, "SmoothPlastic")
	U.blk(bb, "Roof", w + 0.6, 0.6, d + 0.6, 0, F + h, 0, color, "SmoothPlastic")
	if glass then U.blk(bb, "Window", w - 6, h - 4, 0.3, 0, F + 3, -d / 2, "Pastel light blue", "Glass", { tr = 0.6, nc = true }) end
	if title then
		local s = U.blk(bb, "Sign", w, 2.4, 0.4, 0, F + h - 2.4, -d / 2 - 0.3, "Really black", "SmoothPlastic")
		U.text(s, title, Color3.new(1, 1, 1), BrickColor.new(color).Color, "Front")
	end
	return bb
end
local function faceCF(x, z, face)
	local ry = 0
	if face == "x" then ry = -90 elseif face == "-x" then ry = 90 end
	return U.L(x, 0, z, ry)
end

------------------------------------------------------------------ 1. arrival
function K.road(b)
	U.blk(b, "Road", PLOT_W, 0.3, 24, 0, 0, 30, "Dark stone grey", "Concrete")
	for x = -290, 290, 20 do U.blk(b, "Line", 8, 0.05, 0.6, x, 0.3, 30, "Institutional white", "SmoothPlastic", { nc = true }) end
	for _, x in ipairs({ -100, 100 }) do U.blk(b, "Driveway", 24, 0.3, 32, x, 0, 2, "Dark stone grey", "Concrete") end
end
function K.sidewalk(b)
	U.blk(b, "Sidewalk", PLOT_W, 0.5, 14, 0, 0, 49, "Light stone grey", "Concrete")
	U.blk(b, "Curb", PLOT_W, 0.7, 0.8, 0, 0, 42.4, "Institutional white", "Concrete")
end
function K.airportsign(b, o)
	for _, dx in ipairs({ -13, 13 }) do U.blk(b, "Post", 1.4, 16, 1.4, o.x + dx, 0, o.z, "Dark stone grey", "Metal") end
	local s = U.blk(b, "Board", 32, 9, 1, o.x, 12, o.z, "Navy blue", "SmoothPlastic")
	b.plot.signLabel = U.text(s, "AIRPORT", Color3.new(1, 0.85, 0.25), Color3.new(0.05, 0.1, 0.3), "Front")
	U.blk(b, "Trim", 32.4, 0.6, 1.2, o.x, 21, o.z, b.plot.color, "Neon")
end
function K.parking(b)
	U.blk(b, "Lot", 55, 0.3, 140, -177.5, 0, 130, "Dark stone grey", "Concrete")
	for z = 64, 196, 12 do U.blk(b, "Line", 14, 0.05, 0.4, -196, 0.3, z, "Institutional white", nil, { nc = true }) U.blk(b, "Line", 14, 0.05, 0.4, -159, 0.3, z, "Institutional white", nil, { nc = true }) end
	local cols = { "Bright red", "Bright blue", "Institutional white", "Really black", "Bright yellow", "Bright green" }
	for i = 0, 5 do car(b, i % 2 == 0 and -196 or -159, 70 + i * 22, 90, cols[i + 1]) end
	local s = U.blk(b, "P", 4, 4, 0.4, -177, 6, 62, "Bright blue", "SmoothPlastic")
	U.text(s, "P", Color3.new(1, 1, 1), nil, "Front")
	U.blk(b, "Pole", 0.4, 6, 0.4, -177, 0, 62.4, "Dark stone grey", "Metal")
	PT(b, "arrive", { p = V(-170, 0, 120) })
end
function K.taxi(b)
	U.blk(b, "Island", 12, 0.6, 40, 168, 0, 80, "Light stone grey", "Concrete")
	U.blk(b, "Pole", 0.4, 8, 0.4, 168, 0, 62, "Dark stone grey", "Metal")
	local s = U.blk(b, "Sign", 8, 3, 0.4, 168, 8, 62, "Bright yellow", "SmoothPlastic")
	U.text(s, "TAXI", Color3.new(0, 0, 0), nil, "Front")
	car(b, 190, 72, 0, "Bright yellow") car(b, 190, 90, 0, "Bright yellow")
	PT(b, "arrive", { p = V(162, 0, 80) })
end
function K.floor(b)
	U.blk(b, "Floor", 280, 1, 260, 0, 0, 190, "Institutional white", "Marble")
	U.blk(b, "Step", 40, 0.5, 4, 0, 0, 58, "Light stone grey", "Marble")
	for _, p in ipairs({ { -60, 140 }, { 70, 120 } }) do SPOT(b, "janitor", p[1], F, p[2], 30) end
end
function K.walls(b)
	local h = WALL_H
	-- front: glass with white frames, door gap in the middle
	for _, seg in ipairs({ { -140, -12 }, { 12, 140 } }) do
		local w = seg[2] - seg[1]
		U.blk(b, "FrontGlass", w, h, 0.6, (seg[1] + seg[2]) / 2, F, 60, "Pastel light blue", "Glass", { tr = 0.55 })
		for x = seg[1], seg[2], 16 do U.blk(b, "Frame", 1.2, h, 1.2, x, F, 60, "Institutional white", "SmoothPlastic") end
	end
	U.blk(b, "Lintel", 26, h - 13, 1.2, 0, F + 13, 60, "Institutional white", "SmoothPlastic")
	-- sides
	for _, x in ipairs({ -140, 140 }) do
		U.blk(b, "SideWall", 1.4, h, 261, x, F, 190, "Institutional white", "SmoothPlastic")
		U.blk(b, "Stripe", 1.6, 2, 261, x, F + 20, 190, b.plot.color, "SmoothPlastic")
	end
	-- back (airside): glass with openings for the 4 jet bridges
	local gx = { -105, -35, 35, 105 }
	local edges = { -140 }
	for _, x in ipairs(gx) do table.insert(edges, x - 5) table.insert(edges, x + 5) end
	table.insert(edges, 140)
	for i = 1, #edges, 2 do
		local a, c = edges[i], edges[i + 1]
		U.blk(b, "BackGlass", c - a, h, 0.6, (a + c) / 2, F, 320, "Pastel light blue", "Glass", { tr = 0.55 })
	end
	for _, x in ipairs(gx) do U.blk(b, "Lintel", 10, h - 12, 1.2, x, F + 12, 320, "Institutional white", "SmoothPlastic") end
	for x = -140, 140, 20 do U.blk(b, "Frame", 1.2, h, 1.2, x, F, 320, "Institutional white", "SmoothPlastic") end
	U.blk(b, "Cornice", 284, 2, 2, 0, F + h, 60, b.plot.color, "SmoothPlastic")
	U.blk(b, "Cornice", 284, 2, 2, 0, F + h, 320, b.plot.color, "SmoothPlastic")
end
function K.doors(b)
	for _, x in ipairs({ -6, 6 }) do U.blk(b, "Door", 11.6, 12, 0.4, x, F, 60, "Pastel light blue", "Glass", { tr = 0.65, nc = true }) end
	U.blk(b, "DoorFrame", 26, 1, 1.4, 0, F + 12, 60, "Dark stone grey", "Metal")
	local s = U.blk(b, "Sign", 26, 3, 0.4, 0, F + 13.2, 59.2, "Navy blue", "SmoothPlastic")
	U.text(s, "DEPARTURES", Color3.new(1, 1, 1), Color3.new(0.05, 0.1, 0.3), "Front")
	U.blk(b, "Canopy", 34, 0.8, 10, 0, F + 16, 55, b.plot.color, "SmoothPlastic")
end
function K.lights(b)
	for _, x in ipairs({ -100, -50, 0, 50, 100 }) do
		for _, z in ipairs({ 80, 130, 180, 230, 290 }) do
			local p = U.blk(b, "Light", 10, 0.4, 3, x, F + 25, z, "Institutional white", "Neon", { nc = true })
			if (x == -50 or x == 50) and (z == 130 or z == 230) then U.light(p, Color3.new(1, 0.97, 0.9), 50, 1) end
		end
	end
end
function K.infodesk(b, o)
	U.cyl(b, "Desk", 10, 3.6, o.x, F, o.z, "Institutional white", "Marble")
	U.cyl(b, "Top", 10.6, 0.4, o.x, F + 3.6, o.z, b.plot.color, "SmoothPlastic")
	local s = U.blk(b, "Sign", 4, 4, 0.4, o.x, F + 7, o.z, "Bright blue", "SmoothPlastic")
	U.text(s, "i", Color3.new(1, 1, 1), nil, "Front") U.text(s, "i", Color3.new(1, 1, 1), nil, "Back")
	U.blk(b, "Pole", 0.3, 3, 0.3, o.x, F + 4, o.z, "Dark stone grey")
	SPOT(b, "janitor", o.x + 8, F, o.z + 6, 0)
end
function K.benches(b)
	for _, x in ipairs({ -130, -70, 70, 130 }) do
		U.seat(b, x - 1.6, 0.5, 51.5, 180, "Brown", 3) U.seat(b, x + 1.6, 0.5, 51.5, 180, "Brown", 3)
		U.blk(b, "Back", 6.4, 2, 0.4, x, 1.5, 52.8, "Brown", "Wood")
	end
end
function K.flags(b)
	local cols = { "Bright red", "Bright blue", "Bright green", "Bright yellow" }
	for i, x in ipairs({ -110, -90, 90, 110 }) do
		U.cyl(b, "Pole", 0.5, 20, x, 0.5, 50, "Light stone grey", "Metal")
		U.blk(b, "Flag", 5, 3, 0.2, x + 2.7, 17, 50, cols[i], "Fabric")
	end
end
function K.trash(b)
	for _, p in ipairs({ { 25, 70 }, { -25, 70 }, { 25, 166 }, { -25, 166 }, { 22, 284 }, { -22, 284 } }) do
		U.cyl(b, "Bin", 1.8, 2.8, p[1], F, p[2], "Dark stone grey", "Metal")
		U.cyl(b, "Lid", 2, 0.3, p[1], F + 2.8, p[2], "Bright green", "Metal")
	end
end
function K.bus(b)
	U.blk(b, "Shelter", 10, 0.5, 18, 170, 9, 122, "Light stone grey", "Metal")
	U.blk(b, "Back", 0.4, 8, 18, 175, 0.5, 122, "Pastel light blue", "Glass", { tr = 0.5 })
	U.seat(b, 172, 0.5, 118, 90, "Bright blue", 3) U.seat(b, 172, 0.5, 126, 90, "Bright blue", 3)
	U.blk(b, "Bus", 9, 9, 32, 192, 0.8, 122, "Bright green", "SmoothPlastic")
	U.blk(b, "BusWindows", 9.1, 3, 28, 192, 5, 122, "Really black", "Glass")
	U.blk(b, "BusSign", 7, 1.4, 0.2, 192, 8, 105.9, "Really black", "Neon")
	for _, z in ipairs({ 112, 132 }) do for _, x in ipairs({ 187.5, 196.5 }) do U.P(b, "Wheel", V(1, 3, 3), U.L(x, 1.5, z), "Really black", nil, { shape = "cyl" }) end end
	PT(b, "arrive", { p = V(166, 0, 122) })
end
function K.billboards(b)
	for i, x in ipairs({ -30, 50 }) do
		for _, dx in ipairs({ -8, 8 }) do U.blk(b, "Post", 0.8, 22, 0.8, x + dx, 0, 6, "Dark stone grey", "Metal") end
		local s = U.blk(b, "Billboard", 22, 8, 0.6, x, 20, 6, "Institutional white", "SmoothPlastic")
		U.text(s, i == 1 and "FLY WITH US!" or "BEST AIRPORT IN TOWN", Color3.new(1, 1, 1), BrickColor.new(b.plot.color).Color, "Front")
	end
end

------------------------------------------------------------------ 2. check-in
function K.desk(b, o)
	counter(b, 26, 3, 4, o.x, 100, 0, "Institutional white")
	U.blk(b, "Top", 26.4, 0.4, 3.4, o.x, F + 4, 100, b.plot.color, "SmoothPlastic")
	for _, dx in ipairs({ -6, 6 }) do
		U.blk(b, "Screen", 2.4, 1.6, 0.2, o.x + dx, F + 4.6, 100.6, "Really black", "Neon")
		U.blk(b, "Scale", 3, 0.6, 3, o.x + dx, F, 96.6, "Dark stone grey", "Metal")
	end
	hangSign(b, "CHECK-IN " .. o.n, 14, 3, o.x, F + 14, 101, 0)
	SPOT(b, "agent", o.x, F, 104, 0)
	PT(b, "desk", { q = V(o.x, F, 94), n = o.n, lx = o.x })
end
function K.queue(b)
	for _, g in ipairs({ { -128, -32 }, { 32, 128 } }) do
		for x = g[1], g[2], 8 do
			for _, z in ipairs({ 82, 88 }) do U.cyl(b, "Post", 0.5, 3, x, F, z, "Light stone grey", "Metal") end
		end
		for _, z in ipairs({ 82, 88 }) do U.blk(b, "Rope", g[2] - g[1], 0.3, 0.2, (g[1] + g[2]) / 2, F + 2.6, z, "Bright red", "Fabric", { nc = true }) end
	end
end
function K.carts(b)
	for i = 0, 3 do
		local x = 30 + i * 3.2
		U.blk(b, "Cart", 2.4, 0.3, 4, x, F + 1, 84, "Light stone grey", "Metal")
		U.blk(b, "Handle", 2.4, 2.4, 0.2, x, F + 1, 86, "Light stone grey", "Metal")
		U.blk(b, "Suitcase", 1.8, 1.4, 2, x, F + 1.3, 83.5, U.pick({ "Bright red", "Bright blue", "Really black" }))
	end
end
function K.belt(b)
	for _, g in ipairs({ { -128, -32 }, { 32, 128 } }) do
		U.blk(b, "Belt", g[2] - g[1], 1.2, 3, (g[1] + g[2]) / 2, F, 112, "Really black", "DiamondPlate")
		U.blk(b, "BeltSide", g[2] - g[1], 0.4, 0.4, (g[1] + g[2]) / 2, F + 1.2, 113.6, "Dark stone grey", "Metal")
		for x = g[1] + 8, g[2] - 8, 18 do U.blk(b, "Bag", 2, 1.4, 1.6, x, F + 1.2, 112, U.pick({ "Bright red", "Bright blue", "Bright yellow", "Royal purple" })) end
	end
	for _, x in ipairs({ -100, -60, 60, 100 }) do SPOT(b, "handler", x, F, 116, 180) end
end
function K.kiosks(b, o)
	for _, dx in ipairs({ -6, 6 }) do
		U.blk(b, "Kiosk", 2.4, 5, 1.6, o.x + dx, F, 70, "Institutional white", "SmoothPlastic")
		U.blk(b, "Screen", 2, 1.6, 0.2, o.x + dx, F + 3.2, 69.1, "Cyan", "Neon")
	end
	PT(b, "desk", { q = V(o.x, F, 66), kiosk = true, lx = o.x })
end
function K.board(b)
	local s = U.P(b, "Board", V(44, 10, 1), U.L(0, F + 19, 123), "Really black", "SmoothPlastic")
	local lines = "DEPARTURES\nSKY 101   LONDON     BOARDING\nSKY 202   TOKYO      ON TIME\nSKY 303   PARIS      ON TIME\nSKY 404   NEW YORK   DELAYED"
	U.text(s, lines, Color3.new(1, 0.85, 0.2), Color3.new(0.02, 0.02, 0.05), "Front", Enum.Font.Code)
	U.text(s, lines, Color3.new(1, 0.85, 0.2), Color3.new(0.02, 0.02, 0.05), "Back", Enum.Font.Code)
	for _, dx in ipairs({ -18, 18 }) do U.blk(b, "Cable", 0.2, 6, 0.2, dx, F + 24, 123, "Dark stone grey", nil, { nc = true }) end
end
function K.atm(b)
	for _, x in ipairs({ -26, -32 }) do
		U.blk(b, "ATM", 4, 7, 2.4, x, F, 61.6, "Bright green", "SmoothPlastic")
		U.blk(b, "Screen", 2.4, 1.6, 0.2, x, F + 4.4, 62.9, "Cyan", "Neon")
	end
end

------------------------------------------------------------------ 3. security
function K.secwall(b)
	local edges = { { -140, -96 }, { -88, -64 }, { -56, -34 }, { -26, -4 }, { 4, 26 }, { 34, 56 }, { 64, 88 }, { 96, 140 } }
	for _, e in ipairs(edges) do
		U.blk(b, "Partition", e[2] - e[1], 7, 0.5, (e[1] + e[2]) / 2, F, 126, "Pastel light blue", "Glass", { tr = 0.5 })
		U.blk(b, "PartitionTop", e[2] - e[1], 0.4, 0.7, (e[1] + e[2]) / 2, F + 7, 126, "Dark stone grey", "Metal")
	end
	hangSign(b, "SECURITY", 24, 3.4, 0, F + 15, 126, 0, Color3.new(0.6, 0.05, 0.05))
end
local function lanePoints(b, x)
	PT(b, "lane", { a = V(x, F, 120), b = V(x, F, 140), c = V(x, F, 156), lx = x })
end
function K.lane(b, o)
	local x = o.x
	U.blk(b, "XRay", 3.6, 3.6, 8, x + 5.5, F + 0.8, 136, "Light stone grey", "Metal")
	U.blk(b, "XRayHole", 3.7, 1.6, 2, x + 5.5, F + 1.4, 136, "Really black", nil, { nc = true })
	U.blk(b, "Conveyor", 2.4, 1, 20, x + 5.5, F, 136, "Really black", "DiamondPlate")
	U.blk(b, "Screen", 2, 1.4, 0.2, x + 8.8, F + 4, 132, "Lime green", "Neon")
	for _, dx in ipairs({ -2.4, 2.4 }) do U.blk(b, "Detector", 0.8, 7, 1.2, x + dx, F, 140, "Light stone grey", "Metal") end
	U.blk(b, "DetectorTop", 5.6, 0.8, 1.2, x, F + 7, 140, "Light stone grey", "Metal")
	U.blk(b, "DetectorLight", 1.2, 0.4, 0.4, x, F + 7.9, 140, "Lime green", "Neon")
	U.blk(b, "Bins", 1.8, 1.4, 2.6, x + 9, F, 126.5, "Dark stone grey")
	SPOT(b, "officer", x - 4.5, F, 140, -90)
	SPOT(b, "officer", x + 9.5, F, 144, 90)
	lanePoints(b, x)
end
function K.office(b)
	local c = { model = b.model, cf = b.cf * U.L(-126, 0, 143), plot = b.plot }
	U.blk(c, "Wall", 28, 10, 0.5, 0, F, -15, "Light stone grey", "SmoothPlastic")
	U.blk(c, "Wall", 28, 10, 0.5, 0, F, 15, "Light stone grey", "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 10, 10, 14, F, -10, "Light stone grey", "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 10, 10, 14, F, 10, "Light stone grey", "SmoothPlastic")
	U.blk(c, "Window", 0.4, 4, 8, 14, F + 4, 0, "Pastel light blue", "Glass", { tr = 0.5 })
	U.blk(c, "Desk", 8, 3, 3, -5, F, 0, "Brown", "Wood")
	for _, z in ipairs({ -1, 1 }) do U.blk(c, "Monitor", 0.3, 2, 2.4, -5.5, F + 3, z * 1.6, "Lime green", "Neon") end
	local s = U.blk(c, "Sign", 0.4, 2, 12, 14.4, F + 10.5, 0, "Really black")
	U.text(s, "SECURITY OFFICE", Color3.new(1, 1, 1), Color3.new(0.5, 0.05, 0.05), "Right")
	SPOT(b, "officer", -130, F, 143, 90)
end
function K.cctv(b)
	for _, p in ipairs({ { -139, 130 }, { -139, 200 }, { 139, 130 }, { 139, 200 }, { -139, 270 }, { 139, 270 } }) do
		local x = p[1]
		local cam = U.blk(b, "Camera", 1.2, 1.2, 2.2, x + (x < 0 and 1 or -1), F + 20, p[2], "Institutional white", "SmoothPlastic", nil, x < 0 and -60 or 60)
		U.blk(b, "CameraLight", 0.4, 0.4, 0.4, x + (x < 0 and 1.8 or -1.8), F + 20.4, p[2], "Really red", "Neon", { nc = true })
	end
end
function K.scanner(b, o)
	local x = o.x
	U.cyl(b, "Base", 6, 0.4, x, F, 140, "Light stone grey", "Metal")
	for _, dx in ipairs({ -2.6, 2.6 }) do U.blk(b, "Panel", 0.8, 8, 4, x + dx, F + 0.4, 140, "Institutional white", "SmoothPlastic") end
	U.cyl(b, "Top", 6, 0.6, x, F + 8.4, 140, "Institutional white", "SmoothPlastic")
	U.blk(b, "Scan", 4.4, 7.6, 0.2, x, F + 0.6, 140, "Cyan", "Neon", { tr = 0.5, nc = true })
	SPOT(b, "officer", x + (x < 0 and -5 or 5), F, 140, x < 0 and -90 or 90)
	lanePoints(b, x)
end
function K.k9(b)
	local c = { model = b.model, cf = b.cf * U.L(118, F, 143, 90), plot = b.plot }
	U.blk(c, "Dog", 1.4, 1.4, 3.4, 0, 1, -4, "Brown")
	U.P(c, "DogHead", V(1.2, 1.2, 1.6), U.L(0, 2.6, -6.1), "Brown")
	U.P(c, "Ear", V(0.3, 0.8, 0.3), U.L(0.4, 3.4, -5.9), "Really black")
	U.P(c, "Ear", V(0.3, 0.8, 0.3), U.L(-0.4, 3.4, -5.9), "Really black")
	for _, p in ipairs({ { -0.5, -5.3 }, { 0.5, -5.3 }, { -0.5, -2.7 }, { 0.5, -2.7 } }) do U.blk(c, "Leg", 0.4, 1, 0.4, p[1], 0, p[2], "Brown") end
	U.blk(c, "Vest", 1.5, 0.8, 2, 0, 1.6, -4, "Really black", "Fabric")
	M.person(b.model, b.cf * U.L(118, F, 143, 90), { shirt = "Really black", pants = "Navy blue", hat = "cap", hatColor = "Really black" }, "K9 Officer")
end

------------------------------------------------------------------ 4. gates, planes and airside
function K.gate(b, o)
	local x = o.x
	U.blk(b, "GateDesk", 8, 3.6, 2.4, x + 10, F, 308, "Institutional white", "SmoothPlastic")
	U.blk(b, "GateDeskTop", 8.4, 0.4, 2.8, x + 10, F + 3.6, 308, b.plot.color, "SmoothPlastic")
	for row = 0, 1 do
		for i = 0, 5 do U.seat(b, x - 16 + i * 2.4, F, 286 + row * 6, 180, b.plot.color, 2) end
		U.blk(b, "SeatBack", 14.4, 2.4, 0.4, x - 10, F + 1, 287.3 + row * 6, "Dark stone grey", "Metal")
	end
	hangSign(b, "GATE " .. o.n, 12, 3.6, x, F + 15, 317, 0, Color3.new(0.95, 0.75, 0.1), Color3.new(0, 0, 0))
	SPOT(b, "gateagent", x + 10, F, 311, 0)
	PT(b, "gate", { p = V(x, F, 300), door = V(x, F, 317), n = o.n, lx = x })
end
function K.apron(b)
	U.blk(b, "Apron", 420, 0.3, 124, 0, 0, 384, "Medium stone grey", "Concrete")
	for _, x in ipairs({ -105, -35, 35, 105 }) do
		U.blk(b, "LeadIn", 0.8, 0.05, 110, x, 0.3, 390, "Bright yellow", nil, { nc = true })
		U.blk(b, "StopBar", 8, 0.05, 0.8, x, 0.3, 356, "Bright yellow", nil, { nc = true })
	end
	U.blk(b, "Edge", 420, 0.05, 1, 0, 0.3, 445, "Bright yellow", nil, { nc = true })
end
function K.bridge(b, o)
	local x = o.x
	-- a tube from the terminal back wall (z 320, floor height) rising to the plane door (z 352, y ~6)
	local a, c = Vector3.new(x, F + 4, 321), Vector3.new(x, 9.2, 350)
	local mid = (a + c) / 2
	local len = (c - a).magnitude
	U.P(b, "Tube", V(7, 8, len), CFrame.new(mid, c), "Light stone grey", "Metal")
	U.P(b, "TubeWindows", V(7.1, 1.6, len - 4), CFrame.new(mid + Vector3.new(0, 1.4, 0), c + Vector3.new(0, 1.4, 0)), "Really black", "Glass")
	U.blk(b, "Rotunda", 10, 9, 8, x, 4.8, 352, "Light stone grey", "Metal")
	U.blk(b, "Leg", 1, 5, 1, x - 3, 0.3, 346, "Dark stone grey", "Metal")
	U.blk(b, "Leg", 1, 5, 1, x + 3, 0.3, 346, "Dark stone grey", "Metal")
	U.blk(b, "Wheels", 6, 1.4, 2, x, 0.3, 346, "Really black")
	-- the cab that reaches round to the plane's door (front left of the fuselage)
	local d1, d2 = Vector3.new(x - 4, 9.2, 355), Vector3.new(x - 7.6, 9.2, 375)
	U.P(b, "BridgeCab", V(6.4, 7.6, (d2 - d1).magnitude), CFrame.new((d1 + d2) / 2, d2), "Light stone grey", "Metal")
	U.P(b, "CabWindows", V(6.5, 1.4, (d2 - d1).magnitude - 3), CFrame.new((d1 + d2) / 2 + Vector3.new(0, 1.4, 0), d2 + Vector3.new(0, 1.4, 0)), "Really black", "Glass")
	U.blk(b, "CabLeg", 1, 5, 1, x - 6.6, 0.3, 370, "Dark stone grey", "Metal")
	U.blk(b, "CabWheels", 4, 1.4, 2, x - 6.6, 0.3, 370, "Really black")
	SPOT(b, "pilot", x + 2, 5.2, 350, 0)
	-- a = the rotunda, e = the plane's door
	PT(b, "bridge", { a = V(x, 6, 352), e = V(x - 4.8, 6, 374), lx = x, n = o.n })
	A.gatePlane(b.plot, o.n, x)
end
function K.groundvehicles(b)
	-- baggage tug + carts, fuel truck, stairs truck
	U.blk(b, "Tug", 4, 2.6, 5, 60, 0.3, 436, "Bright yellow", "SmoothPlastic")
	for i = 1, 3 do U.blk(b, "BagCart", 4, 2.4, 5, 60, 0.6, 436 + i * 6.4, "Light stone grey", "Metal") U.blk(b, "Bags", 3.4, 1.4, 4, 60, 3, 436 + i * 6.4, U.pick({ "Bright red", "Bright blue", "Really black" })) end
	U.blk(b, "FuelTruck", 5, 5, 14, -70, 0.6, 438, "Institutional white", "SmoothPlastic")
	U.P(b, "FuelTank", V(10, 4.4, 4.4), U.L(-70, 4.8, 440, 90), "Light stone grey", "Metal", { shape = "cyl" })
	U.blk(b, "Stairs", 4, 6, 10, 0, 0.3, 436, "Institutional white", "SmoothPlastic")
	U.P(b, "StairRamp", V(3.6, 6, 8), U.L(0, 9, 434), "Light stone grey", "Metal", { class = "WedgePart" })
end
function K.taxiway(b)
	U.blk(b, "Taxiway", PLOT_W, 0.3, 24, 0, 0, 460, "Dark stone grey", "Concrete")
	for x = -290, 290, 14 do U.blk(b, "Line", 7, 0.05, 0.6, x, 0.3, 460, "Bright yellow", nil, { nc = true }) end
	for _, x in ipairs({ -190, 190 }) do U.blk(b, "Connector", 24, 0.3, 20, x, 0, 481, "Dark stone grey", "Concrete") end
end
function K.runway(b)
	U.blk(b, "Runway", PLOT_W - 10, 0.3, 70, 0, 0, 525, "Really black", "Concrete")
	for x = -260, 260, 25 do U.blk(b, "Center", 12, 0.05, 1, x, 0.3, 525, "Institutional white", nil, { nc = true }) end
	for _, x in ipairs({ -285, 285 }) do
		for z = 498, 552, 6 do U.blk(b, "Threshold", 10, 0.05, 2.4, x, 0.3, z, "Institutional white", nil, { nc = true }) end
	end
	for _, e in ipairs({ { -268, "09", -90 }, { 268, "27", 90 } }) do
		local n = U.P(b, "Number", V(14, 0.05, 10), U.L(e[1], 0.33, 525, e[3]), "Really black", nil, { nc = true })
		U.text(n, e[2], Color3.new(1, 1, 1), nil, "Top")
	end
	U.blk(b, "EdgeL", PLOT_W - 10, 0.05, 1, 0, 0.3, 491, "Institutional white", nil, { nc = true })
	U.blk(b, "EdgeR", PLOT_W - 10, 0.05, 1, 0, 0.3, 559, "Institutional white", nil, { nc = true })
	b.plot.hasRunway = true
	A.startDepartures(b.plot)
end
function K.rwlights(b)
	for x = -290, 290, 25 do
		for _, z in ipairs({ 489.6, 560.4 }) do U.blk(b, "RunwayLight", 0.8, 0.5, 0.8, x, 0.3, z, x < 0 and "Lime green" or "Really red", "Neon", { nc = true }) end
	end
	for i = 1, 5 do U.blk(b, "Approach", 1, 1, 3, -296, 0.3, 525 + (i - 3) * 4, "Bright yellow", "Neon", { nc = true }) end
end
function K.windsock(b)
	U.cyl(b, "Pole", 0.4, 10, 205, 0, 575, "Light stone grey", "Metal")
	U.P(b, "Sock", V(1.6, 1.6, 6), U.L(205, 9.5, 572, 0, -10), "Bright orange", "Fabric", { class = "WedgePart" })
end
function K.tower(b)
	U.cyl(b, "Shaft", 8, 52, -192, 0, 338, "Institutional white", "Concrete")
	U.cyl(b, "Cab", 15, 8, -192, 52, 338, "Pastel light blue", "Glass", { tr = 0.35 })
	U.cyl(b, "CabFloor", 16, 1, -192, 51.5, 338, "Dark stone grey", "Metal")
	U.cyl(b, "Roof", 17, 1.4, -192, 60, 338, b.plot.color, "SmoothPlastic")
	U.cyl(b, "Antenna", 0.4, 8, -192, 61.4, 338, "Really red", "Metal")
	U.light(U.ball(b, "Beacon", 1, -192, 69.6, 338, "Really red", "Neon"), Color3.new(1, 0.2, 0.2), 20)
	U.blk(b, "Desk", 6, 2.5, 2, -192, 52.5, 334, "Dark stone grey")
	SPOT(b, "atc", -194, 52.5, 340, 180)
	SPOT(b, "atc", -189, 52.5, 340, 180)
end
function K.radar(b)
	U.cyl(b, "Mast", 1.2, 10, -168, 0, 362, "Light stone grey", "Metal")
	local dish = U.P(b, "Dish", V(9, 4, 0.6), U.L(-168, 11.5, 362, 0, 15), "Institutional white", "Metal")
	local arm = U.P(b, "Arm", V(0.4, 0.4, 3), U.L(-168, 11, 363), "Dark stone grey", "Metal")
	U.spin({ dish, arm }, b.cf * U.L(-168, 11, 362), "y", 60)
end
function K.helipad(b)
	U.cyl(b, "Pad", 32, 0.3, 178, 0, 400, "Dark stone grey", "Concrete")
	U.blk(b, "H1", 1.6, 0.05, 12, 174, 0.3, 400, "Institutional white", nil, { nc = true })
	U.blk(b, "H2", 1.6, 0.05, 12, 182, 0.3, 400, "Institutional white", nil, { nc = true })
	U.blk(b, "H3", 8, 0.05, 1.6, 178, 0.3, 400, "Institutional white", nil, { nc = true })
	-- helicopter
	U.P(b, "HeliBody", V(5, 5, 7), U.L(178, 3.4, 410), b.plot.color, "SmoothPlastic", { shape = "ball" })
	U.P(b, "HeliTail", V(1, 1, 9), U.L(178, 3.8, 417), b.plot.color, "SmoothPlastic")
	U.P(b, "HeliGlass", V(4, 2.4, 2), U.L(178, 4, 407), "Really black", "Glass", { tr = 0.3 })
	for _, x in ipairs({ -2, 2 }) do U.P(b, "Skid", V(0.4, 0.4, 7), U.L(178 + x, 0.6, 410), "Dark stone grey", "Metal") end
	local r1 = U.P(b, "Rotor", V(14, 0.2, 0.8), U.L(178, 6.4, 410), "Really black", nil, { nc = true })
	local r2 = U.P(b, "Rotor", V(0.8, 0.2, 14), U.L(178, 6.4, 410), "Really black", nil, { nc = true })
	U.spin({ r1, r2 }, b.cf * U.L(178, 6.4, 410), "y", 140)
end
function K.hangar(b)
	U.blk(b, "Floor", 80, 0.3, 44, 160, 0, 593, "Medium stone grey", "Concrete")
	U.blk(b, "Back", 80, 20, 1, 160, 0, 615, "Light stone grey", "CorrodedMetal")
	U.blk(b, "Side", 1, 20, 44, 120, 0, 593, "Light stone grey", "CorrodedMetal")
	U.blk(b, "Side", 1, 20, 44, 200, 0, 593, "Light stone grey", "CorrodedMetal")
	U.P(b, "Roof", V(81, 6, 22.5), U.L(160, 23, 582), "Medium stone grey", "CorrodedMetal", { class = "WedgePart" })
	U.P(b, "Roof", V(81, 6, 22.5), U.L(160, 23, 604, 180), "Medium stone grey", "CorrodedMetal", { class = "WedgePart" })
	U.blk(b, "DoorTop", 80, 3, 1, 160, 17, 571, "Light stone grey", "CorrodedMetal")
	local s = U.blk(b, "Sign", 30, 4, 0.4, 160, 21, 570.4, b.plot.color, "SmoothPlastic")
	U.text(s, "HANGAR", Color3.new(1, 1, 1), nil, "Front")
	U.blk(b, "Toolbox", 4, 4, 2, 192, 0.3, 610, "Bright red", "Metal")
	SPOT(b, "mechanic", 135, 0.3, 600, 180)
	SPOT(b, "mechanic", 185, 0.3, 600, 180)
end
function K.planepad(b, o)
	local pad = U.blk(b, "FlyPad", 9, 0.4, 7, o.x, 0, 566, "Cyan", "Neon")
	local names = { small = "FLY SMALL PLANE", jet = "FLY FIGHTER JET", private = "FLY PRIVATE JET" }
	U.bill(pad, names[o.plane] .. "\n(step here)", 12, 3, 5, Color3.new(0.6, 1, 1))
	U.light(pad, Color3.new(0.3, 0.9, 1), 12)
	b.plot.flyPads[o.plane] = pad
	A.flyPad(b.plot, pad, o.plane)
end
function K.fuel(b)
	U.blk(b, "Base", 52, 0.3, 44, -176, 0, 593, "Medium stone grey", "Concrete")
	for i, x in ipairs({ -192, -176, -160 }) do
		U.cyl(b, "Tank", 12, 12, x, 0.3, 598, "Institutional white", "Metal")
		U.cyl(b, "TankTop", 12.4, 0.6, x, 12.3, 598, "Bright red", "Metal")
	end
	U.blk(b, "Pipe", 40, 1, 1, -176, 1.5, 588, "Bright yellow", "Metal")
	local s = U.blk(b, "Sign", 14, 3, 0.4, -176, 14, 590.8, "Bright red", "SmoothPlastic")
	U.text(s, "FUEL", Color3.new(1, 1, 1), nil, "Front")
end
function K.firestation(b)
	U.blk(b, "Station", 58, 16, 40, 70, 0, 595, "Bright red", "Brick")
	for _, x in ipairs({ 56, 84 }) do U.blk(b, "Door", 18, 12, 0.4, x, 0, 574.8, "Light stone grey", "Metal") end
	local s = U.blk(b, "Sign", 30, 3, 0.4, 70, 12.5, 574.6, "Institutional white", "SmoothPlastic")
	U.text(s, "FIRE STATION", Color3.new(0.8, 0, 0), nil, "Front")
	-- fire truck parked outside
	U.blk(b, "Truck", 8, 7, 18, 100, 0.8, 578, "Bright red", "SmoothPlastic", nil, 90)
	U.blk(b, "Ladder", 1.4, 0.8, 14, 100, 7.8, 578, "Light stone grey", "Metal", nil, 90)
	U.light(U.blk(b, "Siren", 3, 0.6, 1, 100, 7.8, 578, "Really red", "Neon", nil, 90), Color3.new(1, 0.1, 0.1), 14)
	for _, x in ipairs({ 50, 64, 78 }) do SPOT(b, "firefighter", x, 0.3, 571, 0) end
end
function K.cargo(b)
	U.blk(b, "Warehouse", 90, 18, 30, -85, 0, 600, "Sand blue", "CorrodedMetal")
	U.blk(b, "Dock", 90, 2, 6, -85, 0, 582, "Medium stone grey", "Concrete")
	local cols = { "Bright red", "Bright blue", "Bright green", "Bright orange", "Bright yellow" }
	for i = 0, 4 do U.blk(b, "Container", 14, 6, 6, -120 + i * 17, 0.3, 576, cols[i + 1], "CorrodedMetal") end
	U.blk(b, "Container", 14, 6, 6, -103, 6.3, 576, "Teal", "CorrodedMetal")
	local s = U.blk(b, "Sign", 30, 3, 0.4, -85, 18.5, 584.8, "Institutional white", "SmoothPlastic")
	U.text(s, "CARGO", Color3.new(0.1, 0.2, 0.5), nil, "Front")
end

------------------------------------------------------------------ 5. food court
function K.foodcourt(b)
	U.blk(b, "FoodFloor", 120, 0.1, 86, -80, F, 205, "Brick yellow", "SmoothPlastic", { nc = true })
	hangSign(b, "FOOD COURT", 30, 4, -80, F + 16, 163, 0, Color3.new(0.85, 0.35, 0.1))
end
function K.stall(b, o)
	local c = b.cf * faceCF(o.x, o.z, o.face)
	local bb = booth(b, c, 16, 10, 10, o.color, o.title)
	U.blk(bb, "Counter", 14, 3.6, 2, 0, F, -3.5, "Institutional white", "SmoothPlastic")
	U.blk(bb, "CounterTop", 14.4, 0.4, 2.4, 0, F + 3.6, -3.5, o.color, "SmoothPlastic")
	U.blk(bb, "Menu", 10, 3, 0.2, 0, F + 5.4, 4.6, "Really black", "Neon")
	for i = -1, 1 do U.blk(bb, "Food", 1.4, 0.8, 1.4, i * 4, F + 4, -3.5, U.pick({ "Bright yellow", "Bright orange", "Brown", "Bright red" })) end
	U.light(U.blk(bb, "Lamp", 2, 0.4, 2, 0, F + 9.2, 0, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.9, 0.6), 14)
	b.plot.spots.chef = b.plot.spots.chef or {}
	table.insert(b.plot.spots.chef, c * U.L(0, F, 1, 0))
	local lp = b.cf:inverse() * (c * Vector3.new(0, F, -9))
	PT(b, "stall", { p = lp, spend = ITEM["stall" .. o.n].eff.spend, lx = lp.x, n = o.n })
end
function K.tables(b, o)
	for _, dx in ipairs({ -6, 6 }) do
		local x = o.x + dx
		U.cyl(b, "Table", 4.4, 0.4, x, F + 3, o.z, "Institutional white", "SmoothPlastic")
		U.cyl(b, "TableLeg", 0.6, 3, x, F, o.z, "Dark stone grey", "Metal")
		for a = 0, 270, 90 do
			local r = math.rad(a)
			U.seat(b, x + math.cos(r) * 3.4, F, o.z + math.sin(r) * 3.4, -a - 90, "Bright orange", 1.6)
		end
	end
end
function K.vending(b)
	local cols = { "Bright red", "Bright blue", "Bright green" }
	for i, z in ipairs({ 147, 152, 157 }) do
		U.blk(b, "Vending", 3, 7, 4.4, 137, F, z, cols[i], "SmoothPlastic")
		U.blk(b, "Glass", 0.2, 4, 3, 135.4, F + 2.4, z, "Pastel light blue", "Neon", { tr = 0.3 })
	end
end

------------------------------------------------------------------ 6. shops and comfort
function K.shop(b, o)
	local c = b.cf * faceCF(o.x, o.z, o.face)
	local bb = booth(b, c, 16, 10, 12, o.color, o.title, true)
	for _, dx in ipairs({ -5, 0, 5 }) do
		U.blk(bb, "Shelf", 3.6, 6, 1.6, dx, F, 3, "Light stone grey", "SmoothPlastic")
		for y = 1, 3 do U.blk(bb, "Goods", 3, 1, 1.2, dx, F + y * 1.6, 3, U.pick({ "Bright red", "Bright blue", "Bright yellow", "Lime green", "Hot pink", "Cyan" })) end
	end
	U.blk(bb, "Till", 4, 3.6, 2, 5, F, -2.5, "Institutional white", "SmoothPlastic")
	U.light(U.blk(bb, "Lamp", 3, 0.4, 3, 0, F + 11.2, 0, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.95, 0.8), 14)
	b.plot.spots.clerk = b.plot.spots.clerk or {}
	table.insert(b.plot.spots.clerk, c * U.L(5, F, 0, 0))
	local lp = b.cf:inverse() * (c * Vector3.new(0, F, -9))
	PT(b, "shop", { p = lp, spend = ITEM["shop" .. o.n].eff.spend, lx = lp.x, n = o.n })
end
function K.seats(b, o)
	for row = 0, 1 do
		for i = -3, 3 do U.seat(b, o.x + i * 2.3, F, o.z + row * 5, 0, b.plot.color, 2) end
		U.blk(b, "SeatBack", 16, 2.4, 0.4, o.x, F + 1, o.z + row * 5 + 1.2, "Dark stone grey", "Metal")
	end
	PT(b, "seat", { p = V(o.x + math.random(-6, 6), F, o.z - 2.5), lx = o.x })
end
function K.restrooms(b)
	local c = { model = b.model, cf = b.cf * U.L(-126, 0, 266), plot = b.plot }
	U.blk(c, "Wall", 28, 12, 0.5, 0, F, -14, "Pastel light blue", "SmoothPlastic")
	U.blk(c, "Wall", 28, 12, 0.5, 0, F, 14, "Pastel light blue", "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 12, 9, 14, F, -9.5, "Pastel light blue", "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 12, 9, 14, F, 9.5, "Pastel light blue", "SmoothPlastic")
	for z = -10, 10, 5 do U.blk(c, "Stall", 6, 7, 0.3, -9, F, z, "Institutional white") end
	for z = -9, 9, 6 do U.blk(c, "Sink", 2, 3, 2, 10, F, z, "Institutional white", "Marble") end
	local s = U.blk(c, "Sign", 0.4, 2.4, 12, 14.4, F + 12.5, 0, "Bright blue")
	U.text(s, "RESTROOMS", Color3.new(1, 1, 1), nil, "Right")
	for _, z in ipairs({ -6, 0, 6 }) do SPOT(b, "janitor", -118, F, 266 + z, 90) end
end
function K.plants(b)
	for _, p in ipairs({ { -134, 70 }, { 134, 70 }, { -134, 120 }, { 134, 120 }, { -20, 160 }, { 20, 160 }, { -20, 244 }, { 20, 244 } }) do
		U.cyl(b, "Pot", 3, 2.4, p[1], F, p[2], "Reddish brown", "SmoothPlastic")
		U.ball(b, "Leaves", 4, p[1], F + 4, p[2], "Bright green", "Grass")
		U.ball(b, "Leaves", 3, p[1] + 0.8, F + 5.6, p[2], "Dark green", "Grass")
	end
end
function K.charging(b)
	for i, z in ipairs({ 196, 201, 206 }) do
		U.blk(b, "Charger", 1.6, 4.4, 1.6, 69, F, z, "Institutional white", "SmoothPlastic")
		U.blk(b, "Screen", 1.2, 1.2, 0.2, 69, F + 3, z - 0.9, "Lime green", "Neon")
	end
end
local function room(b, x0, x1, title, color, floorColor)
	local c = { model = b.model, cf = b.cf * U.L((x0 + x1) / 2, 0, 266), plot = b.plot }
	local w = x1 - x0
	U.blk(c, "RoomFloor", w, 0.1, 28, 0, F, 0, floorColor or color, "Fabric", { nc = true })
	U.blk(c, "Wall", w, 10, 0.5, 0, F, 14, color, "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 10, 28, -w / 2, F, 0, color, "SmoothPlastic")
	U.blk(c, "Wall", 0.5, 10, 28, w / 2, F, 0, color, "SmoothPlastic")
	local s = U.blk(c, "Sign", w - 2, 2.6, 0.4, 0, F + 10, -13.8, "Really black", "SmoothPlastic")
	U.text(s, title, Color3.new(1, 1, 1), BrickColor.new(color).Color, "Front")
	return c
end
function K.arcade(b)
	local c = room(b, -54, -24, "ARCADE", "Royal purple", "Really black")
	for i = -1, 1 do
		U.blk(c, "Cabinet", 3.4, 6.4, 3, i * 8, F, 8, "Really black", "SmoothPlastic")
		U.blk(c, "Screen", 2.6, 2, 0.2, i * 8, F + 4, 6.4, U.pick({ "Lime green", "Cyan", "Hot pink" }), "Neon")
		U.blk(c, "Buttons", 2.6, 0.4, 1, i * 8, F + 2.8, 6, "Bright red", "Neon")
	end
	U.light(U.blk(c, "Glow", 2, 0.4, 2, 0, F + 9.4, 0, "Hot pink", "Neon", { nc = true }), Color3.new(1, 0.3, 1), 20)
end
function K.kids(b)
	local c = room(b, 100, 140, "KIDS PLAY AREA", "Bright yellow", "Bright blue")
	U.blk(c, "SlideTower", 6, 5, 6, 10, F, 6, "Bright red", "SmoothPlastic")
	U.P(c, "Slide", V(3, 0.4, 10), U.L(10, F + 2.8, -2, 0, -28), "Bright yellow", "SmoothPlastic")
	U.blk(c, "BallPit", 12, 1.6, 10, -8, F, 4, "Bright blue", "SmoothPlastic")
	for i = 1, 14 do U.ball(c, "Ball", 1, -8 + math.random(-5, 5), F + 1.8, 4 + math.random(-4, 4), U.pick({ "Bright red", "Bright yellow", "Lime green", "Hot pink" }), nil, { nc = true }) end
end
function K.lounge(b)
	local c = room(b, -108, -60, "VIP LOUNGE", "Gold", "Bright red")
	for i = -2, 2 do U.seat(c, i * 7, F, 2, 180, "Really black", 4) U.blk(c, "SofaBack", 4.4, 2.4, 1, i * 7, F + 0.5, 3.6, "Really black", "Fabric") end
	U.blk(c, "Bar", 20, 4, 2.4, 0, F, 10, "Brown", "Wood")
	U.blk(c, "BarTop", 20.4, 0.4, 2.8, 0, F + 4, 10, "Gold", "Metal", { refl = 0.3 })
	U.light(U.blk(c, "Glow", 2, 0.4, 2, 0, F + 9.4, 0, "Gold", "Neon", { nc = true }), Color3.new(1, 0.8, 0.4), 22)
end
function K.spa(b)
	local c = room(b, 24, 56, "SPA & MASSAGE", "Teal", "Institutional white")
	for i = -1, 1 do
		U.seat(c, i * 9, F, 4, 180, "Institutional white", 3)
		U.P(c, "ChairBack", V(3, 3, 1), U.L(i * 9, F + 2.4, 5.6, 0, -15), "Institutional white", "Fabric")
	end
	for _, x in ipairs({ -13, 13 }) do U.cyl(c, "Pot", 2.4, 2, x, F, 10, "Reddish brown") U.ball(c, "Plant", 3, x, F + 3.2, 10, "Dark green", "Grass") end
end
function K.aquarium(b)
	local c = room(b, 60, 96, "AQUARIUM", "Navy blue", "Navy blue")
	U.blk(c, "Tank", 30, 9, 8, 0, F + 0.5, 6, "Cyan", "Glass", { tr = 0.45 })
	for i = 1, 8 do
		local fish = U.blk(c, "Fish", 1.4, 0.6, 0.5, math.random(-12, 12), F + 2 + math.random() * 6, 6 + math.random(-2, 2), U.pick({ "Bright orange", "Bright yellow", "Hot pink", "Institutional white" }), nil, { nc = true })
	end
	U.blk(c, "Coral", 4, 2, 3, -6, F + 0.5, 6, "Hot pink", "Slate")
	U.light(U.blk(c, "Glow", 2, 0.4, 2, 0, F + 9.4, 6, "Cyan", "Neon", { nc = true }), Color3.new(0.3, 0.8, 1), 22)
end
function K.fountain(b)
	U.cyl(b, "Basin", 13, 1.6, 0, F, 205, "Light stone grey", "Marble")
	U.cyl(b, "Water", 12, 0.2, 0, F + 1.5, 205, "Cyan", "Neon", { tr = 0.4, nc = true })
	U.cyl(b, "Pillar", 1.6, 5, 0, F + 1.6, 205, "Light stone grey", "Marble")
	local top = U.cyl(b, "Top", 4, 0.6, 0, F + 6.6, 205, "Light stone grey", "Marble")
	U.fx(top, "Sparkles")
	U.light(top, Color3.new(0.5, 0.9, 1), 18)
end
function K.roof(b)
	U.blk(b, "GlassRoof", 282, 0.6, 262, 0, F + WALL_H + 0.6, 190, "Pastel light blue", "Glass", { tr = 0.6 })
	for x = -140, 140, 35 do U.blk(b, "Beam", 1.2, 1.4, 262, x, F + WALL_H, 190, "Institutional white", "Metal") end
	for z = 60, 320, 40 do U.blk(b, "Beam", 282, 1.4, 1.2, 0, F + WALL_H, z, "Institutional white", "Metal") end
end
function K.chandeliers(b)
	for _, p in ipairs({ { -60, 140 }, { 60, 140 }, { -60, 230 }, { 60, 230 } }) do
		U.blk(b, "Chain", 0.2, 6, 0.2, p[1], F + 22, p[2], "Gold", "Metal", { nc = true })
		local c = U.cyl(b, "Ring", 7, 0.6, p[1], F + 21.4, p[2], "Gold", "Metal", { refl = 0.4, nc = true })
		for a = 0, 300, 60 do U.ball(b, "Crystal", 1, p[1] + math.cos(math.rad(a)) * 3.2, F + 21, p[2] + math.sin(math.rad(a)) * 3.2, "Cool yellow", "Neon", { nc = true }) end
		U.light(c, Color3.new(1, 0.9, 0.6), 30)
	end
end
function K.bigscreen(b)
	local s = U.P(b, "Screen", V(44, 12, 1), U.L(0, F + 21, 59), "Really black", "SmoothPlastic")
	b.plot.screenLabel = U.text(s, "WELCOME!", Color3.new(1, 1, 1), Color3.new(0.05, 0.05, 0.12), "Front")
	U.blk(b, "ScreenFrame", 45.4, 0.8, 1.4, 0, F + 27, 59, b.plot.color, "Neon")
	U.blk(b, "ScreenFrame", 45.4, 0.8, 1.4, 0, F + 14.2, 59, b.plot.color, "Neon")
end
function K.planestatue(b, o)
	U.cyl(b, "Pedestal", 8, 3, o.x, 0, o.z, "Light stone grey", "Marble")
	U.cyl(b, "Pole", 1, 8, o.x, 3, o.z, "Dark stone grey", "Metal")
	local c = { model = b.model, cf = b.cf * U.L(o.x, 13, o.z, 30, 20), plot = b.plot }
	U.P(c, "Body", V(14, 2.4, 2.4), U.L(0, 0, 0, 90), "Gold", "Metal", { shape = "cyl", refl = 0.4 })
	U.P(c, "Nose", V(2.4, 2.4, 2.4), U.L(0, 0, -7), "Gold", "Metal", { shape = "ball", refl = 0.4 })
	U.P(c, "Wing", V(14, 0.4, 3), U.L(0, -0.4, 1), "Gold", "Metal", { refl = 0.4 })
	U.P(c, "Tail", V(0.4, 3, 2.4), U.L(0, 1.6, 6.4), "Gold", "Metal", { class = "WedgePart", refl = 0.4 })
	U.fx(b.model:FindFirstChild("Pedestal"), "Sparkles")
end

------------------------------------------------------------------ 7. landside business
function K.rental(b)
	U.blk(b, "Office", 14, 9, 10, 196, 0, 150, "Institutional white", "SmoothPlastic")
	local s = U.blk(b, "Sign", 14, 2.6, 0.4, 196, 9, 144.8, "Bright orange", "SmoothPlastic")
	U.text(s, "CAR RENTAL", Color3.new(1, 1, 1), nil, "Front")
	U.blk(b, "Lot", 40, 0.3, 36, 178, 0, 176, "Dark stone grey", "Concrete")
	local cols = { "Institutional white", "Really black", "Bright red", "Bright blue" }
	for i = 0, 3 do car(b, 164 + i * 10, 178, 0, cols[i + 1]) end
end
function K.garage(b)
	for lvl = 0, 2 do
		U.blk(b, "Deck", 55, 1, 92, -177.5, lvl * 8, 252, "Light stone grey", "Concrete")
		if lvl > 0 then
			local cols = { "Bright red", "Institutional white", "Bright blue", "Really black" }
			for i = 0, 3 do car(b, -196, 215 + i * 22, 90, U.pick(cols)) end
		end
	end
	for _, x in ipairs({ -203, -152 }) do for z = 210, 294, 21 do U.blk(b, "Pillar", 1.6, 24, 1.6, x, 0, z, "Light stone grey", "Concrete") end end
	U.blk(b, "Roof", 55, 1, 92, -177.5, 24, 252, "Medium stone grey", "Concrete")
	local s = U.blk(b, "Sign", 20, 4, 0.4, -177.5, 18, 205.6, "Bright blue", "SmoothPlastic")
	U.text(s, "PARKING", Color3.new(1, 1, 1), nil, "Front")
end
function K.train(b)
	U.blk(b, "Platform", 80, 1.2, 8, -80, 0, 12, "Light stone grey", "Concrete")
	U.blk(b, "Canopy", 80, 0.6, 9, -80, 9, 12, b.plot.color, "SmoothPlastic")
	for x = -116, -44, 18 do U.blk(b, "Post", 0.6, 8, 0.6, x, 1.2, 15, "Dark stone grey", "Metal") end
	for _, dz in ipairs({ -1.2, 1.2 }) do U.blk(b, "Rail", 80, 0.4, 0.4, -80, 0, 3 + dz, "Dark stone grey", "Metal") end
	for i = 0, 2 do
		local x = -105 + i * 25
		U.blk(b, "TrainCar", 22, 8, 6, x, 0.6, 3, i == 0 and "Bright red" or "Institutional white", "SmoothPlastic")
		U.blk(b, "TrainWindows", 18, 2, 6.1, x, 4.4, 3, "Really black", "Glass")
	end
	local s = U.blk(b, "Sign", 20, 2.4, 0.4, -80, 9.6, 7.4, "Navy blue", "SmoothPlastic")
	U.text(s, "AIRPORT EXPRESS", Color3.new(1, 1, 1), nil, "Front")
	PT(b, "arrive", { p = V(-80, 1.2, 14) })
end

------------------------------------------------------------------ 8. mega airport
function K.intlsign(b)
	local s = U.P(b, "IntlSign", V(110, 9, 1), U.L(0, LV_ROOF + 6, 63), "Really black", "SmoothPlastic")
	U.text(s, "INTERNATIONAL AIRPORT", Color3.new(1, 0.85, 0.25), Color3.new(0.05, 0.05, 0.1), "Front")
	U.light(s, Color3.new(1, 0.85, 0.4), 40)
	local cols = { "Bright red", "Bright blue", "Bright green", "Bright yellow", "Royal purple", "Bright orange", "Cyan", "Hot pink" }
	for i, x in ipairs({ -126, -90, -54, -18, 18, 54, 90, 126 }) do
		U.cyl(b, "Pole", 0.4, 10, x, LV_ROOF, 66, "Light stone grey", "Metal")
		U.blk(b, "Flag", 4, 2.4, 0.2, x + 2.2, LV_ROOF + 7, 66, cols[i], "Fabric")
	end
	b.plot.intl = true
end
function K.fireworks(b)
	for _, x in ipairs({ -130, 130 }) do U.blk(b, "Launcher", 4, 3, 4, x, LV_ROOF, 70, "Really black", "Metal") end
	b.plot.fireworks = true
end
function K.mascot(b)
	local c = { model = b.model, cf = b.cf * U.L(180, 0, 9), plot = b.plot }
	U.cyl(c, "Base", 10, 2, 0, 0, 0, "Light stone grey", "Marble")
	U.P(c, "Body", V(18, 9, 9), U.L(0, 10, 0, 90), b.plot.color, "SmoothPlastic", { shape = "cyl" })
	U.P(c, "Face", V(9, 9, 9), U.L(0, 10, -9), "Institutional white", "SmoothPlastic", { shape = "ball" })
	for _, x in ipairs({ -2, 2 }) do U.ball(c, "Eye", 2, x, 11.5, -13, "Really black") end
	U.blk(c, "Smile", 4, 0.6, 0.4, 0, 8.4, -13.3, "Really black")
	U.P(c, "Wing", V(26, 1, 6), U.L(0, 9, 1), "Institutional white", "SmoothPlastic")
	U.P(c, "Tail", V(1, 8, 6), U.L(0, 15, 9), b.plot.color, "SmoothPlastic", { class = "WedgePart" })
	U.P(c, "Cap", V(5, 1.6, 5), U.L(0, 15.2, -8), "Navy blue", "SmoothPlastic")
end
function K.golden(b)
	for _, x in ipairs({ -60, -36, -18, 18, 36, 60 }) do
		U.cyl(b, "GoldPillar", 3, 26, x, F, 57, "Gold", "Metal", { refl = 0.4 })
	end
	U.blk(b, "GoldTrim", 284, 1, 2.4, 0, F + WALL_H + 2, 59, "Gold", "Metal", { refl = 0.4 })
	U.blk(b, "GoldCarpet", 20, 0.1, 40, 0, F, 80, "Gold", "Fabric", { nc = true })
	U.fx(b.model:FindFirstChild("GoldTrim"), "Sparkles")
end
