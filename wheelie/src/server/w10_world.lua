-- ==== w10_world.lua
------------------------------------------------------------------ a sunny afternoon
pcall(function()
	Lighting.TimeOfDay = "14:30:00"
	Lighting.Brightness = 1.2
	Lighting.Ambient = Color3.new(0.45, 0.45, 0.5)
	Lighting.OutdoorAmbient = Color3.new(0.55, 0.55, 0.6)
	Lighting.FogColor = Color3.new(0.75, 0.85, 1)
	Lighting.FogStart = 300
	Lighting.FogEnd = 1400
end)
local WORLD = model(workspace, "Wheelie City")
local function w(name, sx, sy, sz, x, y0, z, color, mat, opt, ry)
	return blk(WORLD, name, sx, sy, sz, x, y0, z, color, mat, opt, ry)
end
local EDGE = 400                 -- the city goes from -400 to 400 on both sides

------------------------------------------------------------------ the ground, the roads
w("Ground", EDGE * 2 + 40, 2, EDGE * 2 + 40, 0, -2, 0, "Bright green", "Grass")
-- a wall round the edge of the city (hedges outside, invisible wall up high)
for _, s in ipairs({ -1, 1 }) do
	w("Hedge", 4, 8, EDGE * 2, s * (EDGE + 2), 0, 0, "Dark green", "Grass")
	w("EdgeWall", 2, 60, EDGE * 2, s * (EDGE + 3), 8, 0, "White", nil, { tr = 1 })
end
w("Hedge", EDGE * 2, 8, 4, 0, 0, -(EDGE + 2), "Dark green", "Grass")
w("EdgeWall", EDGE * 2, 60, 2, 0, 8, -(EDGE + 3), "White", nil, { tr = 1 })
-- the north side opens onto the HIGHWAY (w15_highway.lua): hedge with gaps where the three streets go through
for _, seg in ipairs({ { -950, -235 }, { -205, -15 }, { 15, 205 }, { 235, 950 } }) do
	w("Hedge", seg[2] - seg[1], 8, 4, (seg[1] + seg[2]) / 2, 0, EDGE + 2, "Dark green", "Grass")
end
local ROADS = {}
local function road(x1, z1, x2, z2)
	local cx, cz, sx, sz = (x1 + x2) / 2, (z1 + z2) / 2, x2 - x1, z2 - z1
	w("Road", sx, 0.2, sz, cx, 0, cz, "Dark stone grey", "Concrete")
	table.insert(ROADS, { x1, z1, x2, z2 })
	-- dashed yellow middle line
	local long = sx >= sz
	local len = long and sx or sz
	for d = -len / 2 + 6, len / 2 - 6, 30 do
		if long then w("Line", 8, 0.05, 0.5, cx + d, 0.2, cz, "New Yeller", "SmoothPlastic", { nc = true })
		else w("Line", 0.5, 0.05, 8, cx, 0.2, cz + d, "New Yeller", "SmoothPlastic", { nc = true }) end
	end
	-- white edges
	for _, e in ipairs({ -1, 1 }) do
		if long then w("Edge", sx, 0.05, 0.5, cx, 0.2, cz + e * (sz / 2 - 1.5), "Institutional white", "SmoothPlastic", { nc = true })
		else w("Edge", 0.5, 0.05, sz, cx + e * (sx / 2 - 1.5), 0.2, cz, "Institutional white", "SmoothPlastic", { nc = true }) end
	end
end
-- WHEELIE BOULEVARD: a long, wide, perfectly straight road for record wheelies
road(-EDGE, -20, EDGE, 20)
road(-EDGE, -215, EDGE, -185)
road(-EDGE, 185, EDGE, 215)
for _, x in ipairs({ -220, 0, 220 }) do
	road(x - 15, -EDGE, x + 15, -215)
	road(x - 15, -185, x + 15, -20)
	road(x - 15, 20, x + 15, 185)
	road(x - 15, 215, x + 15, EDGE)
end
-- distance markers along the boulevard (from the start line at x = -350)
local start = w("StartLine", 2, 0.06, 40, -350, 0.2, 0, "Institutional white", "SmoothPlastic", { nc = true })
for k = 1, 14 do
	local x = -350 + k * 50
	local post = w("MarkerPost", 0.6, 7, 0.6, x, 0, -23, "Institutional white", "Metal")
	local board = w("Marker", 0.4, 3, 6, x, 7, -23, k % 2 == 0 and "Really red" or "Bright blue", "SmoothPlastic")
	sign(board, (k * 50) .. "", "Right", Color3.new(1, 1, 1))
	sign(board, (k * 50) .. "", "Left", Color3.new(1, 1, 1))
	w("Tick", 0.6, 0.06, 40, x, 0.2, 0, "Institutional white", "SmoothPlastic", { nc = true, tr = 0.5 })
end
-- a banner over the start of the boulevard
for _, s in ipairs({ -1, 1 }) do w("BannerPost", 1, 16, 1, -350, 0, s * 22, "Medium stone grey", "Metal") end
local banner = w("Banner", 1, 4, 46, -350, 16, 0, "Really red", "SmoothPlastic")
sign(banner, "WHEELIE BOULEVARD", "Right", Color3.new(1, 1, 1))
sign(banner, "WHEELIE BOULEVARD", "Left", Color3.new(1, 1, 1))

------------------------------------------------------------------ city blocks: buildings, trees, parked cars, lamps
local function tree(x, z)
	w("Trunk", 1.6, 8, 1.6, x, 0, z, "Brown", "Wood")
	w("Leaves", 8, 6, 8, x, 7, z, "Bright green", "Grass")
	w("Leaves", 5, 3, 5, x, 13, z, "Earth green", "Grass")
end
local function building(x, z, sx, sz, h, color)
	w("Building", sx, h, sz, x, 0, z, color, "Brick")
	w("RoofTrim", sx + 1, 1, sz + 1, x, h, z, "Dark stone grey", "Concrete")
	-- rows of windows on all four sides
	for y = 4, h - 4, 6 do
		w("Windows", sx + 0.2, 2.6, sz - 4, x, y, z, "Pastel light blue", "Glass", { tr = 0.1 })
		w("Windows", sx - 4, 2.6, sz + 0.2, x, y, z, "Pastel light blue", "Glass", { tr = 0.1 })
	end
	w("Door", 4, 7, sz + 0.3, x, 0, z, "Brown", "Wood")
end
local function car(x, z, color, ry)
	local c = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(ry or 0), 0)
	P(WORLD, "CarBody", V(5, 2, 10), c * CFrame.new(0, 1.8, 0), color, "SmoothPlastic")
	P(WORLD, "CarTop", V(4.6, 1.8, 5), c * CFrame.new(0, 3.7, 0.5), color, "SmoothPlastic")
	P(WORLD, "CarGlass", V(4.7, 1.4, 5.1), c * CFrame.new(0, 3.7, 0.5), "Black", "Glass", { tr = 0.3 })
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			P(WORLD, "CarWheel", V(1, 2, 2), c * CFrame.new(sx * 2.4, 1, sz * 3.2) * CFrame.Angles(0, math.pi / 2, 0), "Really black", "SmoothPlastic", { shape = "cyl" })
		end
	end
end
local COLORS = { "Bright red", "Bright blue", "Brick yellow", "Sand red", "Pastel blue-green", "Light orange", "Medium stone grey", "Pastel yellow" }
-- the blocks between the roads (x from -400 to 400 split by streets at -220 / 0 / 220; z split at -200 / 0 / 200)
local XS = { { -385, -235 }, { -205, -15 }, { 15, 205 }, { 235, 385 } }
local ZS = { { -385, -215 }, { -185, -20 }, { 20, 185 }, { 215, 385 } }
local SPECIAL = { ["3,2"] = "plaza", ["4,2"] = "bikepark", ["1,3"] = "dirt", ["2,3"] = "park" }
local blocks = {}
for i, xr in ipairs(XS) do
	for j, zr in ipairs(ZS) do
		local kind = SPECIAL[i .. "," .. j]
		local cx, cz = (xr[1] + xr[2]) / 2, (zr[1] + zr[2]) / 2
		local bw, bd = xr[2] - xr[1], zr[2] - zr[1]
		-- a pavement round every block
		w("Sidewalk", bw + 6, 0.4, bd + 6, cx, 0, cz, "Light stone grey", "Concrete")
		table.insert(blocks, { kind = kind, cx = cx, cz = cz, w = bw, d = bd })
		if not kind then
			-- two or three buildings, trees and a parked car
			local n = (i + j) % 2 == 0 and 2 or 3
			for k = 1, n do
				local bx = xr[1] + (k - 0.5) * bw / n
				building(bx, cz, bw / n - 14, bd - 40, 20 + ((i * 7 + j * 3 + k * 5) % 4) * 10, COLORS[(i + j + k) % #COLORS + 1])
			end
			tree(xr[1] + 8, zr[1] + 8) tree(xr[2] - 8, zr[2] - 8)
			car(xr[1] + 20, zr[2] - 8, COLORS[(i * 3 + j) % #COLORS + 1], 90)
		end
	end
end
-- street lamps along the boulevard
for x = -360, 360, 60 do
	for _, s in ipairs({ -1, 1 }) do
		w("LampPole", 0.6, 14, 0.6, x, 0, s * 23, "Dark stone grey", "Metal")
		w("LampArm", 0.4, 0.4, 3, x, 14, s * 21.5, "Dark stone grey", "Metal")
		w("LampHead", 1.4, 0.6, 1.4, x, 13.6, s * 20, "Pastel yellow", "Neon")
	end
end

------------------------------------------------------------------ ramps
local function wedge(x, z, sx, h, len, yaw, color, mat)
	local p = P(WORLD, "Ramp", V(sx, h, len), CFrame.new(x, h / 2, z) * CFrame.Angles(0, math.rad(yaw or 0), 0), color or "Medium stone grey", mat or "Concrete", { class = "WedgePart" })
	return p
end
-- a kicker ramp you ride up toward local +Z (yaw turns it)
local function kicker(x, z, h, len, yaw, color, mat) return wedge(x, z, 10, h, len, yaw, color, mat) end
-- a table-top jump: up, flat, down
local function tabletop(x, z, h, yaw, color, mat)
	local c = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	local up = P(WORLD, "Ramp", V(10, h, 10), c * CFrame.new(0, h / 2, -12), color, mat, { class = "WedgePart" })
	P(WORLD, "Table", V(10, h, 14), c * CFrame.new(0, h / 2, 0), color, mat)
	local down = P(WORLD, "Ramp", V(10, h, 10), c * CFrame.new(0, h / 2, 12) * CFrame.Angles(0, math.pi, 0), color, mat, { class = "WedgePart" })
end

------------------------------------------------------------------ the special blocks
local PLAZA
for _, b in ipairs(blocks) do
	if b.kind == "plaza" then
		-- SPAWN PLAZA: tiles, a fountain, the garage (bike shop) and the leaderboard
		PLAZA = b
		w("Plaza", b.w, 0.5, b.d, b.cx, 0, b.cz, "Institutional white", "Marble")
		for k = -2, 2 do w("PlazaStripe", b.w, 0.06, 2, b.cx, 0.5, b.cz + k * 18, "Bright orange", "SmoothPlastic", { nc = true }) end
		P(WORLD, "Fountain", V(2, 18, 18), CFrame.new(b.cx - 40, 1, b.cz) * CFrame.Angles(0, 0, math.pi / 2), "Medium stone grey", "Marble", { shape = "cyl" })
		P(WORLD, "Water", V(0.4, 15, 15), CFrame.new(b.cx - 40, 2, b.cz) * CFrame.Angles(0, 0, math.pi / 2), "Bright blue", "Glass", { shape = "cyl", tr = 0.3, nc = true })
		w("FountainTop", 3, 6, 3, b.cx - 40, 2, b.cz, "Institutional white", "Marble")
		tree(b.cx - 80, b.cz - 60) tree(b.cx - 80, b.cz + 60) tree(b.cx + 80, b.cz + 60)
	elseif b.kind == "bikepark" then
		-- BIKE PARK: concrete, kickers, a funbox, quarter pipes, a big launch ramp
		w("ParkFloor", b.w, 0.5, b.d, b.cx, 0, b.cz, "Light stone grey", "Concrete")
		local s = w("ParkSign", 30, 5, 1, b.cx, 14, b.cz + b.d / 2 - 2, "Bright orange", "SmoothPlastic")
		sign(s, "BIKE PARK", "Back", Color3.new(1, 1, 1))
		for _, sx in ipairs({ -1, 1 }) do w("SignPost", 1, 14, 1, b.cx + sx * 14, 0, b.cz + b.d / 2 - 2, "Dark stone grey", "Metal") end
		kicker(b.cx - 40, b.cz - 40, 3, 8, 0, "Bright orange", "SmoothPlastic")
		kicker(b.cx + 40, b.cz - 40, 4, 10, 0, "Bright blue", "SmoothPlastic")
		kicker(b.cx, b.cz + 30, 6, 14, 180, "Bright red", "SmoothPlastic")
		-- the funbox: up one side, flat, down the other
		tabletop(b.cx, b.cz - 10, 3, 90, "Medium stone grey", "Concrete")
		-- quarter pipes on the far side
		for k = -2, 2 do wedge(b.cx + b.w / 2 - 6, b.cz + k * 22, 20, 8, 8, 90, "Light stone grey", "Concrete") end
		-- the big launch
		wedge(b.cx - b.w / 2 + 20, b.cz + 50, 12, 9, 22, 0, "Really red", "SmoothPlastic")
	elseif b.kind == "dirt" then
		-- DIRT TRACK: a loop of dirt with table-tops and whoops
		w("Dirt", b.w, 0.5, b.d, b.cx, 0, b.cz, "Brown", "Sand")
		w("Infield", b.w - 50, 0.6, b.d - 60, b.cx, 0, b.cz, "Bright green", "Grass")
		tabletop(b.cx, b.cz - b.d / 2 + 15, 4, 90, "Reddish brown", "Sand")
		tabletop(b.cx, b.cz + b.d / 2 - 15, 4, -90, "Reddish brown", "Sand")
		for k = -2, 2 do wedge(b.cx - b.w / 2 + 12, b.cz + k * 14, 10, 2, 6, 0, "Reddish brown", "Sand") end
		local s = w("DirtSign", 26, 5, 1, b.cx, 12, b.cz - b.d / 2 + 2, "Brown", "WoodPlanks")
		sign(s, "DIRT TRACK", "Front", Color3.new(1, 0.9, 0.5))
		for _, sx in ipairs({ -1, 1 }) do w("SignPost", 1, 12, 1, b.cx + sx * 12, 0, b.cz - b.d / 2 + 2, "Brown", "Wood") end
	elseif b.kind == "park" then
		-- a park: trees, a pond, a path
		w("Pond", 60, 0.3, 40, b.cx, 0, b.cz, "Bright blue", "Glass", { tr = 0.2 })
		for k = 0, 7 do tree(b.cx + math.cos(k) * 70, b.cz + math.sin(k) * 60) end
	end
end

------------------------------------------------------------------ the garage (bike shop) in the plaza, with every bike on show
-- build a bike (anchored for the show room, or welded under a rider when weldTo is given)
local function buildBikeModel(parent, b, at, anchored, weldTo, name)
	local m = model(parent, name or b.name)
	for _, d in ipairs(BikeParts(b)) do
		local part = P(m, d[1], d[2], at * d[3], d[4], d[5], { shape = d[6], anchored = anchored, nc = true })
		if d[7] then
			-- race numbers on the plates
			local face = d[1] == "NumberPlate" and "Front" or (d[3].p.X > 0 and "Right" or "Left")
			sign(part, d[7], face, BrickColor.new(d[4] == "Really black" and "White" or "Really black").Color)
		end
		if weldTo then weld(weldTo, part) end
	end
	return m
end
local GARAGE = PLAZA and V(PLAZA.cx + 50, 0, PLAZA.cz - 40) or V(110, 0, -100)
w("GarageFloor", 60, 0.6, 30, GARAGE.X, 0, GARAGE.Z, "Dark stone grey", "DiamondPlate")
w("GarageBack", 60, 18, 1, GARAGE.X, 0, GARAGE.Z - 15, "Bright blue", "Metal")
for _, s in ipairs({ -1, 1 }) do w("GarageSide", 1, 18, 30, GARAGE.X + s * 30, 0, GARAGE.Z, "Bright blue", "Metal") end
w("GarageRoof", 62, 1, 32, GARAGE.X, 18, GARAGE.Z, "Institutional white", "Metal")
local gs = w("GarageSign", 40, 5, 1, GARAGE.X, 19, GARAGE.Z + 15, "Bright orange", "SmoothPlastic")
sign(gs, "GARAGE  -  BIKES & E-MOTOS", "Back", Color3.new(1, 1, 1))
for i, b in ipairs(BIKES) do
	local x = GARAGE.X - 25 + (i - 1) * 10
	w("ShowPad", 7, 0.4, 9, x, 0.6, GARAGE.Z - 4, "Institutional white", "Marble")
	buildBikeModel(WORLD, b, CFrame.new(x, 1, GARAGE.Z - 4), true)
	local tag = w("PriceTag", 6, 2, 0.3, x, 1, GARAGE.Z + 2, "Really black", "SmoothPlastic")
	sign(tag, b.name .. "\n" .. (b.price == 0 and "FREE" or ("$" .. b.price)), "Back", Color3.new(1, 0.9, 0.3))
end

------------------------------------------------------------------ the leaderboard and the spawn
local LB = PLAZA and V(PLAZA.cx + 10, 0, PLAZA.cz + 50) or V(110, 0, -50)
for _, s in ipairs({ -1, 1 }) do w("BoardPost", 1, 6, 1, LB.X + s * 11, 0, LB.Z, "Dark stone grey", "Metal") end
local board = w("Leaderboard", 24, 16, 1, LB.X, 6, LB.Z, "Really black", "SmoothPlastic")
local boardText = sign(board, "BEST WHEELIES", "Front", Color3.new(1, 0.85, 0.2))
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "Spawn"
spawnPad.Anchored = true
spawnPad.Size = V(12, 1, 12)
spawnPad.CFrame = CFrame.new((PLAZA and V(PLAZA.cx, 0, PLAZA.cz) or V(110, 0, -100)) + V(0, 0.1, 0))
spawnPad.BrickColor = BrickColor.new("Bright orange")
pcall(function() spawnPad.Material = Enum.Material.Neon end)
pcall(function() spawnPad.Neutral = true end)
spawnPad.Parent = WORLD
