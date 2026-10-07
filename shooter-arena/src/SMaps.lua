-- SMaps (ModuleScript)
-- Location: ServerScriptService > SMaps
-- Builds the lobby and the five maps out of plain parts (all anchored).
--   M.buildAll() -> { lobby = map, maps = { nuketown = map, skyline = map, desert = map, harbor = map, forest = map } }
--   map = { id, name, folder, spawns = { red = {CFrame}, blue = {CFrame}, any = {CFrame} },
--           killY = falling below this kills you, time = time of day, pads = {jump pads}, teleports = {...},
--           hills = {Vector3} (King of the Hill spots), hillR = hill radius }
-- NUKETOWN: two houses facing each other over a cul-de-sac, school bus, truck, car, backyards.
-- SKYLINE MAYHEM: skyscraper rooftops floating high above a neon city, glass bridges, jump pads,
--   teleporters, a sniper nest on the centre tower and a lower deck. Fall off = you die.
-- DESERT OUTPOST (v6): walled compound, temple ruins, bazaar street, army camp vs oil field.
-- FROZEN HARBOR (v6): container maze, warehouses, cranes, a cargo ship. Fall in the water = you drown.
-- TIMBER FOREST (v6): pine forest with a river, log cabin vs lumber mill, ranger station, campground.
-- Only the map being played is in the Workspace (ShooterMain keeps the others in ServerStorage),
-- so slow computers (Chromebooks!) only have to draw one map.
-- Plain 2016-style Lua.

local M = {}

local function setMat(p, name)
	if name then
		pcall(function()
			p.Material = Enum.Material[name]
		end)
	end
end

local folder = nil

-- MAP SCALE (v2): a whole map can be built bigger. XF = { o = origin, h = sideways scale,
-- v = up scale }. Every part's position and size are stretched, so houses keep the same rooms
-- but every room, door and street is bigger.
local XF = nil
local function xpos(p)
	if not XF then
		return p
	end
	local d = p - XF.o
	return XF.o + Vector3.new(d.X * XF.h, d.Y * XF.v, d.Z * XF.h)
end
local function xcf(cf)
	if not XF then
		return cf
	end
	return CFrame.new(xpos(cf.p)) * (cf - cf.p)
end
local function xsize(size, cf)
	if not XF then
		return size
	end
	local rot = cf - cf.p
	local function f(axis)
		local v = rot * axis
		return math.sqrt((v.X * XF.h) ^ 2 + (v.Y * XF.v) ^ 2 + (v.Z * XF.h) ^ 2)
	end
	return Vector3.new(size.X * f(Vector3.new(1, 0, 0)), size.Y * f(Vector3.new(0, 1, 0)), size.Z * f(Vector3.new(0, 0, 1)))
end

local function part(name, size, cf, color, mat, extra)
	size = xsize(size, cf)
	cf = xcf(cf)
	local p = Instance.new((extra and extra.wedge) and "WedgePart" or ((extra and extra.truss) and "TrussPart" or "Part"))
	p.Name = name
	pcall(function()
		p.FormFactor = Enum.FormFactor.Custom
	end)
	p.Size = size
	p.Anchored = true
	p.CFrame = cf
	p.BrickColor = BrickColor.new(color)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	setMat(p, mat)
	if extra then
		if extra.cyl then
			p.Shape = Enum.PartType.Cylinder
		elseif extra.ball then
			p.Shape = Enum.PartType.Ball
		end
		if extra.t then
			p.Transparency = extra.t
		end
		if extra.nocollide then
			p.CanCollide = false
		end
		if extra.refl then
			p.Reflectance = extra.refl
		end
	end
	p.Parent = (extra and extra.parent) or folder
	return p
end

local function A(x, y, z)
	return CFrame.Angles(x or 0, y or 0, z or 0)
end

-- a wall along local X from -len/2 to len/2, from y = 0 to h, centred on base (a CFrame at floor
-- level). holes = { {x, width, bottom, top} } are cut out (doors and windows).
local function wall(base, len, h, thick, holes, color, mat, frameColor)
	table.sort(holes, function(a, b)
		return a[1] < b[1]
	end)
	local x = -len / 2
	local function solid(x0, x1, y0, y1)
		if x1 - x0 > 0.05 and y1 - y0 > 0.05 then
			part("Wall", Vector3.new(x1 - x0, y1 - y0, thick), base * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0), color, mat)
		end
	end
	for _, hole in ipairs(holes) do
		local hx0, hx1 = hole[1] - hole[2] / 2, hole[1] + hole[2] / 2
		solid(x, hx0, 0, h)
		solid(hx0, hx1, 0, hole[3])
		solid(hx0, hx1, hole[4], h)
		x = hx1
	end
	solid(x, len / 2, 0, h)
	-- white frames around windows and doors (v3: makes the houses look like houses)
	if frameColor then
		local fd = thick + 0.5
		for _, hole in ipairs(holes) do
			local hx0, hx1 = hole[1] - hole[2] / 2, hole[1] + hole[2] / 2
			local hy = hole[4] - hole[3]
			for _, ex in ipairs({ hx0, hx1 }) do
				part("Frame", Vector3.new(0.4, hy + 0.4, fd), base * CFrame.new(ex, hole[3] + hy / 2, 0), frameColor, "SmoothPlastic")
			end
			part("Frame", Vector3.new(hole[2] + 0.8, 0.4, fd), base * CFrame.new(hole[1], hole[4] + 0.2, 0), frameColor, "SmoothPlastic")
			if hole[3] > 0.5 then
				part("Sill", Vector3.new(hole[2] + 1, 0.3, fd + 0.4), base * CFrame.new(hole[1], hole[3] - 0.15, 0), frameColor, "SmoothPlastic")
				-- a cross in the window (thin, so you can still shoot through)
				part("Mullion", Vector3.new(0.15, hy, 0.15), base * CFrame.new(hole[1], hole[3] + hy / 2, 0), frameColor, "SmoothPlastic", { nocollide = true })
			end
		end
	end
end

-- a sign with big text on both sides
local function sign(text, size, cf, bg, fg)
	local p = part("Sign", size, cf, bg, "SmoothPlastic")
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.Parent = p
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, 0, 1, 0)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.SourceSansBold
		t.FontSize = Enum.FontSize.Size96
		t.TextColor3 = fg or Color3.new(1, 1, 1)
		t.Text = text
		pcall(function()
			t.TextScaled = true
		end)
		t.Parent = sg
	end
	return p
end

local function tree(pos, h)
	h = h or 14
	part("TreeTrunk", Vector3.new(h * 0.5, 1.6, 1.6), CFrame.new(pos + Vector3.new(0, h * 0.25, 0)) * A(0, 0, math.pi / 2), "Brown", "Wood", { cyl = true })
	part("TreeLeaves", Vector3.new(h * 0.55, h * 0.55, h * 0.55), CFrame.new(pos + Vector3.new(0, h * 0.6, 0)), "Earth green", "Grass", { ball = true })
	part("TreeLeaves", Vector3.new(h * 0.4, h * 0.4, h * 0.4), CFrame.new(pos + Vector3.new(h * 0.18, h * 0.75, h * 0.1)), "Bright green", "Grass", { ball = true })
end

local function wheel(cf, d)
	part("Wheel", Vector3.new(1, d, d), cf, "Really black", "SmoothPlastic", { cyl = true })
	part("Hubcap", Vector3.new(1.05, d * 0.45, d * 0.45), cf, "Light stone grey", "Metal", { cyl = true })
end

-- a simple vehicle: body box + cab + windows + 4 wheels (cf = centre on the ground, faces -Z)
local function vehicle(cf, len, wid, hgt, color, cabLen, cabH, cabColor)
	part("VehicleBody", Vector3.new(wid, hgt, len), cf * CFrame.new(0, 1.2 + hgt / 2, 0), color, "SmoothPlastic")
	if cabLen then
		part("VehicleCab", Vector3.new(wid * 0.95, cabH, cabLen), cf * CFrame.new(0, 1.2 + hgt + cabH / 2, len / 2 - cabLen / 2 - 1), cabColor or color, "SmoothPlastic")
		part("VehicleWindow", Vector3.new(wid * 0.97, cabH * 0.6, cabLen * 0.8), cf * CFrame.new(0, 1.2 + hgt + cabH * 0.55, len / 2 - cabLen / 2 - 1), "Black", "Glass", { t = 0.3 })
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			wheel(cf * CFrame.new(sx * wid / 2, 1.3, sz * (len / 2 - 2)), 2.6)
		end
	end
end

-- a mannequin (Nuketown!)
local function mannequin(pos, rot)
	local cf = CFrame.new(pos) * A(0, rot or 0, 0)
	local c = "Institutional white"
	for _, sx in ipairs({ -1, 1 }) do
		part("Mannequin", Vector3.new(0.9, 2, 0.9), cf * CFrame.new(sx * 0.5, 1, 0), c, "SmoothPlastic")
		part("Mannequin", Vector3.new(0.8, 2, 0.8), cf * CFrame.new(sx * 1.45, 3, 0) * A(0, 0, sx * 0.2), c, "SmoothPlastic")
	end
	part("Mannequin", Vector3.new(2, 2, 1), cf * CFrame.new(0, 3, 0), c, "SmoothPlastic")
	part("Mannequin", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 4.7, 0), c, "SmoothPlastic", { ball = true })
end


------------------------------------------------------------------
-- MORE HELPERS (v6)
------------------------------------------------------------------
-- a solid ramp (wedge) from the ground up to height h: tall end towards "dir" (+X / -X / +Z / -Z).
-- w = width, len = length on the ground
local function wedgeRamp(pos, w, h, len, dir, color, mat)
	local rot = 0
	if dir == "+X" then
		rot = math.pi / 2
	elseif dir == "-X" then
		rot = -math.pi / 2
	elseif dir == "-Z" then
		rot = math.pi
	end
	return part("Ramp", Vector3.new(w, h, len), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * A(0, rot, 0), color or "Medium stone grey", mat or "Concrete", { wedge = true })
end

-- a straight sloped plank from a to b (both on its top surface)
local function plank(name, a, b, w, color, mat)
	local mid = (a + b) / 2
	local len = (b - a).magnitude
	return part(name, Vector3.new(w, 1, len), CFrame.new(mid, b) * CFrame.new(0, -0.5, 0), color, mat)
end

-- an upright cylinder (tanks, columns, barrels). pos = the centre of its bottom
local function column(name, pos, h, d, color, mat, extra)
	extra = extra or {}
	extra.cyl = true
	return part(name, Vector3.new(h, d, d), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * A(0, 0, math.pi / 2), color, mat, extra)
end

-- a long dune / tent roof: two wedges back to back. The ridge runs along local X.
-- across = width over the ridge, along = length of the ridge, h = height
local function ridge(name, cf, across, along, h, color, mat)
	part(name, Vector3.new(along, h, across / 2), cf * CFrame.new(0, h / 2, -across / 4), color, mat, { wedge = true })
	part(name, Vector3.new(along, h, across / 2), cf * CFrame.new(0, h / 2, across / 4) * A(0, math.pi, 0), color, mat, { wedge = true })
end

-- a low wall of sandbags (2 rows), along local X
local function sandbags(cf, len)
	part("Sandbags", Vector3.new(len, 2, 2.6), cf * CFrame.new(0, 1, 0), "Brick yellow", "Fabric")
	part("Sandbags", Vector3.new(len - 0.8, 1.6, 2.2), cf * CFrame.new(0, 2.8, 0), "Nougat", "Fabric")
end

local function crate(pos, s, rot, color)
	return part("Crate", Vector3.new(s, s, s), CFrame.new(pos + Vector3.new(0, s / 2, 0)) * A(0, rot or 0, 0), color or "Brown", "WoodPlanks")
end

local function barrel(pos, color)
	column("Barrel", pos, 3.4, 2.4, color or "Bright red", "Metal")
end

local function palm(pos, h)
	h = h or 18
	-- a slightly bent trunk (2 pieces) and 5 leaves
	part("PalmTrunk", Vector3.new(h * 0.55, 1.2, 1.2), CFrame.new(pos + Vector3.new(0, h * 0.27, 0)) * A(0, 0, math.pi / 2 - 0.06), "Brown", "Wood", { cyl = true })
	part("PalmTrunk", Vector3.new(h * 0.5, 1, 1), CFrame.new(pos + Vector3.new(0.6, h * 0.75, 0)) * A(0, 0, math.pi / 2 + 0.12), "Brown", "Wood", { cyl = true })
	local top = pos + Vector3.new(0.9, h, 0)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		part("PalmLeaf", Vector3.new(1.6, 0.3, 8), CFrame.new(top) * A(0, a, 0) * A(-0.35, 0, 0) * CFrame.new(0, 0, -3.6), "Bright green", "Grass", { nocollide = true })
	end
end

local function pine(pos, h)
	h = h or 22
	part("PineTrunk", Vector3.new(h * 0.45, 1.5, 1.5), CFrame.new(pos + Vector3.new(0, h * 0.22, 0)) * A(0, 0, math.pi / 2), "Reddish brown", "Wood", { cyl = true })
	local tiers = { { 0.36, 0.6 }, { 0.56, 0.44 }, { 0.74, 0.28 } }
	for i, t in ipairs(tiers) do
		part("PineLeaves", Vector3.new(h * t[2], h * 0.2, h * t[2]), CFrame.new(pos + Vector3.new(0, h * t[1], 0)) * A(0, math.pi / 4 + i * 0.3, 0),
			i == 2 and "Earth green" or "Dark green", "Grass")
	end
end

local function boulder(pos, s, color)
	return part("Rock", Vector3.new(s, s, s), CFrame.new(pos + Vector3.new(0, s * 0.22, 0)), color or "Dark stone grey", "Slate", { ball = true })
end

-- a shipping container (8 wide, 8.6 tall, 20 long along local Z). open = both ends open (walk through)
local function container(cf, color, open)
	if open then
		part("Container", Vector3.new(8, 0.6, 20), cf * CFrame.new(0, 8.3, 0), color, "CorrodedMetal")
		for _, sx in ipairs({ -1, 1 }) do
			part("Container", Vector3.new(0.6, 8.6, 20), cf * CFrame.new(sx * 3.7, 4.3, 0), color, "CorrodedMetal")
		end
	else
		part("Container", Vector3.new(8, 8.6, 20), cf * CFrame.new(0, 4.3, 0), color, "CorrodedMetal")
	end
	-- darker frames at both ends (a solid door, or just the frame when it is open)
	for _, sz in ipairs({ -1, 1 }) do
		if open then
			part("ContainerEnd", Vector3.new(8.4, 0.6, 0.5), cf * CFrame.new(0, 8.6, sz * 10), "Dark stone grey", "Metal")
			for _, sx in ipairs({ -1, 1 }) do
				part("ContainerEnd", Vector3.new(0.5, 8.9, 0.5), cf * CFrame.new(sx * 3.95, 4.45, sz * 10), "Dark stone grey", "Metal")
			end
		else
			part("ContainerEnd", Vector3.new(8.3, 8.9, 0.5), cf * CFrame.new(0, 4.45, sz * 10), "Dark stone grey", "Metal")
		end
	end
end

-- a building: a floor, 4 walls with holes, a flat roof. Local frame: X across, -Z = front.
-- holes = { front = {...}, back = {...}, left = {...}, right = {...} } (see wall(); for the side walls
-- a positive x is towards the front). ramp = true: a ramp along the back wall goes up to a hatch in
-- the roof, and the roof gets a low wall (a sniper spot).
local function building(base, W, D, H, opts)
	local function at(x, y, z)
		return base * CFrame.new(x, y, z)
	end
	local wc, mat, trim = opts.wall or "Brick yellow", opts.mat or "Concrete", opts.trim
	local holes = opts.holes or {}
	part("BuildingFloor", Vector3.new(W, 1, D), at(0, 0.5, 0), opts.floor or "Medium stone grey", "Concrete")
	wall(at(0, 1, -D / 2), W, H, 1, holes.front or {}, wc, mat, trim)
	wall(at(0, 1, D / 2), W, H, 1, holes.back or {}, wc, mat, trim)
	wall(at(-W / 2, 1, 0) * A(0, math.pi / 2, 0), D, H, 1, holes.left or {}, wc, mat, trim)
	wall(at(W / 2, 1, 0) * A(0, math.pi / 2, 0), D, H, 1, holes.right or {}, wc, mat, trim)
	local RY = H + 1
	local roofC = opts.roof or "Dark stone grey"
	if opts.ramp then
		local rw = 5
		local L = math.min(W - 6, (H + 1) * 1.45)
		local x0 = -W / 2 + 1.5
		local rz = D / 2 - 0.5 - rw / 2
		part("Ramp", Vector3.new(rw, H + 1, L), at(x0 + L / 2, 1 + (H + 1) / 2, rz) * A(0, math.pi / 2, 0), opts.rampColor or "Medium stone grey", "Concrete", { wedge = true })
		local hx0, hx1 = x0 + L * 0.35, x0 + L
		local hz0 = D / 2 - 0.5 - rw - 0.5
		part("Roof", Vector3.new(W, 1, hz0 + D / 2), at(0, RY + 0.5, (hz0 - D / 2) / 2), roofC, "Concrete")
		part("Roof", Vector3.new(hx0 + W / 2, 1, D / 2 - hz0), at((hx0 - W / 2) / 2, RY + 0.5, (hz0 + D / 2) / 2), roofC, "Concrete")
		part("Roof", Vector3.new(W / 2 - hx1, 1, D / 2 - hz0), at((hx1 + W / 2) / 2, RY + 0.5, (hz0 + D / 2) / 2), roofC, "Concrete")
		for _, sz in ipairs({ -1, 1 }) do
			part("RoofWall", Vector3.new(W, 2.6, 0.6), at(0, RY + 2.3, sz * (D / 2 - 0.3)), wc, mat)
		end
		for _, sx in ipairs({ -1, 1 }) do
			part("RoofWall", Vector3.new(0.6, 2.6, D), at(sx * (W / 2 - 0.3), RY + 2.3, 0), wc, mat)
		end
	else
		part("Roof", Vector3.new(W + 1.2, 1, D + 1.2), at(0, RY + 0.5, 0), roofC, "Concrete")
	end
	return at
end

-- a sloped plank with railings on both sides (gangways, bridges)
local function walkway(a, b, w, color, mat, railColor)
	local p = plank("Walkway", a, b, w, color, mat)
	for _, s in ipairs({ -1, 1 }) do
		part("Rail", Vector3.new(0.3, 3, p.Size.Z), p.CFrame * CFrame.new(s * (w / 2 - 0.15), 2, 0), railColor or "Dark stone grey", "Metal")
	end
	return p
end

-- a number generator that always gives the same numbers (so trees are always in the same place)
local seed = 1
local function rnd(a, b)
	seed = (seed * 16807) % 2147483647
	return a + (b - a) * (seed / 2147483647)
end
local function freeSpot(x, z, zones)
	for _, r in ipairs(zones) do
		if x > r[1] and x < r[3] and z > r[2] and z < r[4] then
			return false
		end
	end
	return true
end

------------------------------------------------------------------
-- LOBBY (floating box high in the sky; everyone waits here between matches)
------------------------------------------------------------------
local function buildLobby()
	folder = Instance.new("Model")
	folder.Name = "Lobby"
	folder.Parent = game.Workspace
	local O = Vector3.new(0, 600, 0)
	part("LobbyFloor", Vector3.new(90, 2, 90), CFrame.new(O + Vector3.new(0, -1, 0)), "Dark stone grey", "Concrete")
	part("LobbyStripe", Vector3.new(90.2, 0.2, 4), CFrame.new(O + Vector3.new(0, 0.05, 0)), "Bright red", "Neon")
	part("LobbyStripe", Vector3.new(4, 0.2, 90.2), CFrame.new(O + Vector3.new(0, 0.06, 0)), "Bright blue", "Neon")
	for _, s in ipairs({ { 45, 0 }, { -45, 0 }, { 0, 45 }, { 0, -45 } }) do
		local horiz = s[2] == 0
		part("LobbyWall", horiz and Vector3.new(2, 24, 90) or Vector3.new(90, 24, 2), CFrame.new(O + Vector3.new(s[1], 12, s[2])), "Black", "Glass", { t = 0.5 })
	end
	part("LobbyRoof", Vector3.new(90, 2, 90), CFrame.new(O + Vector3.new(0, 25, 0)), "Black", "Glass", { t = 0.6 })
	sign("SHOOTER ARENA", Vector3.new(50, 10, 1), CFrame.new(O + Vector3.new(0, 15, -43)), "Really black", Color3.new(1, 0.75, 0.2))
	sign("VOTE FOR THE NEXT MAP AND MODE", Vector3.new(50, 4, 1), CFrame.new(O + Vector3.new(0, 7, -43)), "Really black", Color3.new(0.6, 0.85, 1))
	-- a spawn so the game always has somewhere to put new players
	local sp = Instance.new("SpawnLocation")
	sp.Name = "LobbySpawn"
	sp.Anchored = true
	sp.Size = Vector3.new(8, 1, 8)
	sp.CFrame = CFrame.new(O + Vector3.new(0, 0.5, 10))
	sp.BrickColor = BrickColor.new("Medium stone grey")
	sp.Transparency = 1
	sp.CanCollide = false
	pcall(function()
		sp.Neutral = true
		sp.Duration = 0
	end)
	sp.Parent = folder
	-- TEAM PADS (v6): stand on one to pick your team for the team modes (same as the TEAM buttons)
	local teamPads = {}
	for _, t in ipairs({ { -22, "red", "Bright red", "JOIN RED", Color3.new(1, 0.35, 0.35) }, { 0, "auto", "Medium stone grey", "AUTO TEAM", Color3.new(1, 1, 1) },
		{ 22, "blue", "Bright blue", "JOIN BLUE", Color3.new(0.45, 0.65, 1) } }) do
		local pad = part("TeamPad", Vector3.new(14, 0.4, 10), CFrame.new(O + Vector3.new(t[1], 0.2, 32)), t[3], "Neon", { t = 0.2 })
		table.insert(teamPads, { part = pad, team = t[2] })
		sign(t[4], Vector3.new(14, 3, 0.5), CFrame.new(O + Vector3.new(t[1], 8, 37.5)), "Really black", t[5])
	end
	local spawns = {}
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		table.insert(spawns, CFrame.new(O + Vector3.new(math.cos(a) * 25, 3, math.sin(a) * 25)))
	end
	return { id = "lobby", name = "LOBBY", folder = folder, spawns = { red = spawns, blue = spawns, any = spawns }, killY = 400, time = 14, teamPads = teamPads }
end

------------------------------------------------------------------
-- NUKETOWN
------------------------------------------------------------------
-- one house. cx, cz = centre, rot = turn so the front door faces the middle of the map.
-- local frame: X = across the front, -Z = front (towards the street), floors 12 high.
local function house(cx, cz, rot, wallColor, trimColor, roofColor, shutterColor)
	local base = CFrame.new(cx, 0, cz) * A(0, rot, 0)
	local W, D, H = 30, 24, 12
	local function at(x, y, z)
		return base * CFrame.new(x, y, z)
	end
	-- floors
	part("HouseFloor", Vector3.new(W, 1, D), at(0, 0.5, 0), "Light stone grey", "Concrete")
	-- upstairs floor in 4 pieces, leaving a hole over the stairs (x 9..15, z -6.8..12)
	part("HouseFloor", Vector3.new(24, 1, 14), at(-3, H + 0.5, 5), "Brown", "WoodPlanks")
	part("HouseFloor", Vector3.new(16, 1, 10), at(-7, H + 0.5, -7), "Brown", "WoodPlanks")
	part("HouseFloor", Vector3.new(14, 1, 5.2), at(8, H + 0.5, -9.4), "Brown", "WoodPlanks")
	part("HouseFloor", Vector3.new(8, 1, 4.8), at(5, H + 0.5, -4.4), "Brown", "WoodPlanks")
	-- walls, ground floor: front (door + 2 windows), back (door + window), sides (window)
	wall(at(0, 1, -D / 2), W, H, 1, { { 0, 5, 0, 8 }, { -9, 6, 4, 8.5 }, { 9, 6, 4, 8.5 } }, wallColor, "SmoothPlastic", trimColor)
	wall(at(0, 1, D / 2), W, H, 1, { { -4, 5, 0, 8 }, { -11, 5, 4, 8.5 } }, wallColor, "SmoothPlastic", trimColor)
	wall(at(-W / 2, 1, 0) * A(0, math.pi / 2, 0), D, H, 1, { { 0, 5, 0, 8 } }, wallColor, "SmoothPlastic", trimColor) -- door to the garage
	wall(at(W / 2, 1, 0) * A(0, math.pi / 2, 0), D, H, 1, { { 6, 5, 4, 8.5 } }, wallColor, "SmoothPlastic", trimColor)
	-- inside wall with a doorway
	wall(at(2, 1, 2) * A(0, math.pi / 2, 0), 20, H, 0.6, { { 0, 5, 0, 8 } }, "Institutional white", "SmoothPlastic")
	-- upstairs walls with big windows (good sniping spots over the street)
	wall(at(0, H + 1, -D / 2), W, 10, 1, { { -8, 8, 3, 8 }, { 8, 8, 3, 8 } }, wallColor, "SmoothPlastic", trimColor)
	wall(at(0, H + 1, D / 2), W, 10, 1, { { 0, 10, 3, 8 } }, wallColor, "SmoothPlastic", trimColor)
	wall(at(-W / 2, H + 1, 0) * A(0, math.pi / 2, 0), D, 10, 1, { { 0, 8, 3, 8 } }, wallColor, "SmoothPlastic", trimColor)
	wall(at(W / 2, H + 1, 0) * A(0, math.pi / 2, 0), D, 10, 1, { { 0, 8, 3, 8 } }, wallColor, "SmoothPlastic", trimColor)
	-- trim: a band between the floors, corner boards, a concrete foundation, shutters
	-- (only OUTSIDE the walls: a solid slab here used to block the stairs)
	for _, sz in ipairs({ -1, 1 }) do
		part("Trim", Vector3.new(W + 1, 0.6, 0.5), at(0, H + 1, sz * (D / 2 + 0.6)), trimColor, "SmoothPlastic")
	end
	for _, sx in ipairs({ -1, 1 }) do
		part("Trim", Vector3.new(0.5, 0.6, D + 1.7), at(sx * (W / 2 + 0.6), H + 1, 0), trimColor, "SmoothPlastic")
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part("CornerBoard", Vector3.new(1.3, H + 10, 1.3), at(sx * W / 2, (H + 11) / 2 + 0.5, sz * D / 2), trimColor, "SmoothPlastic")
		end
	end
	part("Foundation", Vector3.new(W + 1.2, 1.2, D + 1.2), at(0, 0.35, 0), "Medium stone grey", "Concrete")
	for _, wx in ipairs({ -9, 9 }) do
		for _, sx in ipairs({ -1, 1 }) do
			part("Shutter", Vector3.new(1.4, 5, 0.3), at(wx + sx * 4.1, 6.3, -D / 2 - 0.75), shutterColor, "SmoothPlastic")
		end
	end
	for _, wx in ipairs({ -8, 8 }) do
		for _, sx in ipairs({ -1, 1 }) do
			part("Shutter", Vector3.new(1.4, 5.5, 0.3), at(wx + sx * 5.1, H + 6.5, -D / 2 - 0.75), shutterColor, "SmoothPlastic")
		end
	end
	-- the front door itself (open, swung inside) and a doormat
	part("Door", Vector3.new(0.4, 7.8, 4.6), at(-2.3, 4.9, -D / 2 + 2.6), "Reddish brown", "Wood")
	part("DoorKnob", Vector3.new(0.3, 0.3, 0.3), at(-2.0, 4.8, -D / 2 + 4.4), "Gold", "Metal", { ball = true })
	part("Doormat", Vector3.new(4, 0.2, 2.5), at(0, 1.1, -D / 2 - 1.8), "Bright red", "Fabric")
	-- stairs up (right side: start at the back, climb towards the front landing).
	-- You walk on a smooth ramp (easy to climb in any size); the steps on it are just for looks.
	part("StairRamp", Vector3.new(5, 12, 16.8), at(11.5, 7, 1.6) * A(0, math.pi, 0), "Brown", "WoodPlanks", { wedge = true })
	for i = 1, 12 do
		part("Stair", Vector3.new(5, 0.3, 1.4), at(11.5, i * 1 + 0.9, 10 - i * 1.4 + 0.7), "Reddish brown", "WoodPlanks", { nocollide = true })
	end
	-- upstairs: a railing around the stair hole (so you don't fall in) and a light
	part("Railing", Vector3.new(0.4, 0.4, 18.8), at(8.8, H + 4, 2.6), trimColor, "SmoothPlastic")
	for z = -6.4, 12, 3.1 do
		part("RailPost", Vector3.new(0.3, 3, 0.3), at(8.8, H + 2.5, z), trimColor, "SmoothPlastic")
	end
	part("CeilingLamp", Vector3.new(2, 0.5, 2), at(-4, H + 9.7, 0), "Institutional white", "Neon")
	part("Crate", Vector3.new(3, 3, 3), at(-12, H + 2.5, -9), "Brown", "WoodPlanks")
	part("Desk", Vector3.new(5, 3, 2.5), at(-1, H + 2.5, -9.5), "Reddish brown", "Wood")
		-- roof (pitched, two wedges) + chimney
	local RH = 7
	part("Roof", Vector3.new(W + 2, RH, D / 2 + 1), at(0, H + 11 + RH / 2, -D / 4), roofColor, "Slate", { wedge = true })
	part("Roof", Vector3.new(W + 2, RH, D / 2 + 1), at(0, H + 11 + RH / 2, D / 4) * A(0, math.pi, 0), roofColor, "Slate", { wedge = true })
	part("Chimney", Vector3.new(3, 9, 3), at(-9, H + 14, 6), "Bright red", "Brick")
	-- fill the triangles at both ends of the roof (gables) and add white boards along the edges
	for _, sx in ipairs({ -1, 1 }) do
		part("Gable", Vector3.new(1, RH, D / 2), at(sx * (W / 2 - 0.2), H + 11 + RH / 2, -D / 4), wallColor, "SmoothPlastic", { wedge = true })
		part("Gable", Vector3.new(1, RH, D / 2), at(sx * (W / 2 - 0.2), H + 11 + RH / 2, D / 4) * A(0, math.pi, 0), wallColor, "SmoothPlastic", { wedge = true })
		part("AtticVent", Vector3.new(1.2, 1.6, 1.6), at(sx * (W / 2 - 0.1), H + 13, 0), trimColor, "SmoothPlastic")
	end
	for _, sz in ipairs({ -1, 1 }) do
		part("Fascia", Vector3.new(W + 2.6, 0.7, 0.5), at(0, H + 11.1, sz * (D / 2 + 0.6)), trimColor, "SmoothPlastic")
		part("Gutter", Vector3.new(W + 2.6, 0.4, 0.5), at(0, H + 10.8, sz * (D / 2 + 1)), "Medium stone grey", "Metal")
	end
	part("RoofRidge", Vector3.new(W + 2.4, 0.5, 0.8), at(0, H + 11 + RH + 0.1, 0), roofColor, "Slate")
	-- front porch with a little roof
	part("Porch", Vector3.new(12, 1, 6), at(0, 0.5, -D / 2 - 3), "Brown", "WoodPlanks")
	part("PorchStep", Vector3.new(6, 0.5, 2), at(0, 0.25, -D / 2 - 7), "Light stone grey", "Concrete")
	for _, x in ipairs({ -5.5, 5.5 }) do
		part("PorchPost", Vector3.new(0.6, 8, 0.6), at(x, 5, -D / 2 - 5.5), "Institutional white", "SmoothPlastic")
	end
	part("PorchRoof", Vector3.new(13, 0.6, 7), at(0, 9.3, -D / 2 - 3), roofColor, "Slate")
	-- garage on the left side (open door), flat roof you can stand on
	local gx = -W / 2 - 7
	part("GarageFloor", Vector3.new(14, 1, 20), at(gx, 0.5, 2), "Medium stone grey", "Concrete")
	wall(at(gx, 1, 12) , 14, 10, 1, {}, wallColor, "SmoothPlastic")
	wall(at(gx - 7, 1, 2) * A(0, math.pi / 2, 0), 20, 10, 1, { { 4, 3, 3, 7 } }, wallColor, "SmoothPlastic")
	part("GarageRoof", Vector3.new(15, 1, 21), at(gx, 11.5, 2), roofColor, "Slate")
	part("GarageDoorTop", Vector3.new(14, 2.5, 1), at(gx, 9.75, -8), trimColor, "SmoothPlastic")
	vehicle(at(gx, 0.5, 3) * A(0, 0, 0), 11, 5.5, 2.5, "Bright red", 5, 2.2, "Bright red")
	-- furniture (cover inside)
	part("Couch", Vector3.new(8, 2.5, 3), at(-8, 2.25, 6), "Bright blue", "Fabric")
	part("CouchBack", Vector3.new(8, 2, 1), at(-8, 3.5, 7.5), "Bright blue", "Fabric")
	part("Table", Vector3.new(5, 3, 3), at(-6, 2.5, -4), "Reddish brown", "Wood")
	part("Fridge", Vector3.new(3, 7, 3), at(-13, 4.5, 9.5), "Institutional white", "Metal")
	part("Bed", Vector3.new(6, 2, 8), at(-9, H + 2, 6), "Bright red", "Fabric")
	part("Dresser", Vector3.new(5, 4, 2), at(4, H + 3, 10.5), "Reddish brown", "Wood")
	-- backyard: fence, shed, picnic table
	local by = D / 2 + 16
	for _, x in ipairs({ -W / 2 - 14, W / 2 + 2 }) do
		part("Fence", Vector3.new(0.6, 4, 17), at(x, 2, (D / 2 + by + 1) / 2), "Institutional white", "Wood")
	end
	part("Fence", Vector3.new(W + 16, 4, 0.6), at(-6, 2, by + 1), "Institutional white", "Wood")
	part("Shed", Vector3.new(8, 8, 8), at(10, 4, by - 5), "Brown", "WoodPlanks")
	part("ShedRoof", Vector3.new(9, 1, 9), at(10, 8.5, by - 5), roofColor, "Slate")
	part("PicnicTable", Vector3.new(8, 0.6, 3.5), at(-8, 3, by - 6), "Reddish brown", "Wood")
	for _, z in ipairs({ -2.6, 2.6 }) do
		part("PicnicBench", Vector3.new(8, 0.5, 1.2), at(-8, 1.8, by - 6 + z), "Reddish brown", "Wood")
	end
	-- mailbox
	part("MailboxPost", Vector3.new(0.4, 3.5, 0.4), at(10, 1.75, -D / 2 - 14), "Brown", "Wood")
	part("Mailbox", Vector3.new(1, 1.2, 2), at(10, 4, -D / 2 - 14), "Really black", "Metal")
end

local function buildNuketown()
	XF = { o = Vector3.new(0, 0, 0), h = 1.8, v = 1.3 } -- Nuketown is built 1.8x wider and 1.3x taller
	folder = Instance.new("Model")
	folder.Name = "Nuketown"
	folder.Parent = game.Workspace
	-- ground, lawns and the cul-de-sac
	part("Ground", Vector3.new(280, 2, 220), CFrame.new(0, -1, 0), "Bright green", "Grass")
	part("Road", Vector3.new(0.4, 76, 76), CFrame.new(0, 0.05, 0) * A(0, 0, math.pi / 2), "Dark stone grey", "Concrete", { cyl = true })
	part("Road", Vector3.new(26, 0.4, 70), CFrame.new(0, 0.05, -70), "Dark stone grey", "Concrete")
	part("Road", Vector3.new(26, 0.4, 40), CFrame.new(0, 0.05, 55), "Dark stone grey", "Concrete")
	part("RoadLine", Vector3.new(0.6, 0.45, 60), CFrame.new(0, 0.07, -72), "New Yeller", "SmoothPlastic")
	part("Sidewalk", Vector3.new(0.4, 84, 84), CFrame.new(0, -0.05, 0) * A(0, 0, math.pi / 2), "Light stone grey", "Concrete", { cyl = true })
	-- driveways
	part("Driveway", Vector3.new(24, 0.4, 14), CFrame.new(-42, 0.05, -16), "Light stone grey", "Concrete")
	part("Driveway", Vector3.new(24, 0.4, 14), CFrame.new(42, 0.05, 28), "Light stone grey", "Concrete")
	-- the two houses: yellow (west, RED team side) and green (east, BLUE team side)
	house(-62, 6, -math.pi / 2, "Bright yellow", "Institutional white", "Reddish brown", "Earth green")
	house(62, 6, math.pi / 2, "Sand green", "Institutional white", "Dark stone grey", "Really black")
	-- centre: the school bus, a truck, a car, mannequins
	local bus = CFrame.new(-4, 0, 14) * A(0, 0.25, 0)
	part("Bus", Vector3.new(8, 8, 30), bus * CFrame.new(0, 5.2, 0), "New Yeller", "SmoothPlastic")
	part("BusStripe", Vector3.new(8.1, 0.6, 30.1), bus * CFrame.new(0, 4, 0), "Really black", "SmoothPlastic")
	part("BusWindows", Vector3.new(8.2, 2.2, 24), bus * CFrame.new(0, 7.2, 2), "Black", "Glass", { t = 0.2 })
	part("BusHood", Vector3.new(8, 4, 4), bus * CFrame.new(0, 3.2, -17), "New Yeller", "SmoothPlastic")
	part("BusSign", Vector3.new(6, 1.2, 0.3), bus * CFrame.new(0, 8.5, -15.1), "Really black", "SmoothPlastic")
	for _, z in ipairs({ -12, 10 }) do
		for _, sx in ipairs({ -1, 1 }) do
			wheel(bus * CFrame.new(sx * 4, 1.4, z), 2.8)
		end
	end
	vehicle(CFrame.new(-26, 0, -34) * A(0, 1.2, 0), 14, 6.5, 3.5, "Bright blue", 5, 3, "Bright blue")
	part("TruckBed", Vector3.new(6.5, 2, 7), CFrame.new(-26, 0, -34) * A(0, 1.2, 0) * CFrame.new(0, 5.6, -3), "Bright blue", "SmoothPlastic")
	vehicle(CFrame.new(28, 0, -30) * A(0, -0.6, 0), 11, 5.5, 2.4, "Bright red", 5, 2.4, "Bright red")
	vehicle(CFrame.new(24, 0, 36) * A(0, 2.3, 0), 11, 5.5, 2.4, "Institutional white", 5, 2.4, "Institutional white")
	for _, m in ipairs({ { -20, 0, 0.6 }, { 18, -12, 2.2 }, { 8, 30, 3.5 }, { -36, -14, 1.2 }, { 40, 20, -1.5 }, { -12, -46, 0 }, { 14, -48, 3 } }) do
		mannequin(Vector3.new(m[1], 0.1, m[2]), m[3])
	end
	-- low walls, hedges and trees for cover
	for _, h in ipairs({ { -30, 34, 0 }, { 30, -8, 0.5 }, { -32, -50, 1.57 }, { 32, 50, 1.57 }, { -8, 50, 0 } }) do
		part("Hedge", Vector3.new(14, 4, 3), CFrame.new(h[1], 2, h[2]) * A(0, h[3], 0), "Earth green", "Grass")
	end
	for _, w in ipairs({ { -18, 28, 0.3 }, { 16, -40, 0 }, { 40, 2, 1.57 } }) do
		part("LowWall", Vector3.new(10, 3.2, 1.6), CFrame.new(w[1], 1.6, w[2]) * A(0, w[3], 0), "Light stone grey", "Brick")
	end
	for _, t in ipairs({ { -100, -70 }, { 100, -70 }, { -100, 80 }, { 100, 80 }, { -40, 86 }, { 40, -88 }, { -120, 0 }, { 120, -10 } }) do
		tree(Vector3.new(t[1], 0, t[2]), 16)
	end
	part("HoopPole", Vector3.new(0.5, 10, 0.5), CFrame.new(-40, 5, -60), "Dark stone grey", "Metal")
	part("HoopBoard", Vector3.new(5, 3.5, 0.3), CFrame.new(-40, 10.5, -59.6), "Institutional white", "SmoothPlastic")
	sign("NUKETOWN", Vector3.new(26, 6, 1), CFrame.new(0, 14, -102), "Really black", Color3.new(1, 0.8, 0.2))
	part("SignPost", Vector3.new(1, 12, 1), CFrame.new(-11, 6, -102), "Dark stone grey", "Metal")
	part("SignPost", Vector3.new(1, 12, 1), CFrame.new(11, 6, -102), "Dark stone grey", "Metal")
	-- walls around the map (you can't leave)
	for _, s in ipairs({ { 140, 0, 2, 220 }, { -140, 0, 2, 220 }, { 0, 110, 280, 2 }, { 0, -110, 280, 2 } }) do
		part("Boundary", Vector3.new(s[3], 60, s[4]), CFrame.new(s[1], 30, s[2]), "Medium stone grey", "SmoothPlastic", { t = 1 })
		part("BoundaryFence", Vector3.new(s[3], 6, s[4]), CFrame.new(s[1], 3, s[2]), "Institutional white", "Wood")
	end
	-- spawns: RED behind the yellow house, BLUE behind the green house, FFA all over
	local red, blue, any = {}, {}, {}
	for i = -2, 2 do
		table.insert(red, xcf(CFrame.new(-112, 3, i * 14 + 6) * A(0, -math.pi / 2, 0)))
		table.insert(blue, xcf(CFrame.new(112, 3, i * 14 + 6) * A(0, math.pi / 2, 0)))
	end
	for _, s in ipairs({ { -112, -30 }, { 112, 40 }, { -60, -60 }, { 60, 66 }, { -60, 70 }, { 60, -62 }, { 0, -95 }, { 0, 90 },
		{ -100, 70 }, { 88, -62 }, { -35, 0 }, { 35, 10 }, { -110, 30 }, { 110, -20 } }) do
		table.insert(any, xcf(CFrame.new(s[1], 3, s[2])))
	end
	-- King of the Hill spots: the cul-de-sac, the road south, the road north
	local hills = { xpos(Vector3.new(14, 0, -14)), xpos(Vector3.new(0, 0, -75)), xpos(Vector3.new(0, 0, 62)) }
	XF = nil
	return { id = "nuketown", name = "NUKETOWN", folder = folder, spawns = { red = red, blue = blue, any = any }, killY = -50, time = 14.5, pads = {}, teleports = {},
		hills = hills, hillR = 20 }
end

------------------------------------------------------------------
-- SKYLINE MAYHEM
------------------------------------------------------------------
local function buildSkyline()
	XF = { o = Vector3.new(1500, 200, 0), h = 1.45, v = 1 } -- rooftops, bridges and gaps 1.45x bigger
	folder = Instance.new("Model")
	folder.Name = "Skyline"
	folder.Parent = game.Workspace
	local OX, Y = 1500, 200 -- far away from Nuketown, high in the sky
	local function P(x, y, z)
		return Vector3.new(OX + x, Y + y, z)
	end
	local pads, teleports = {}, {}
	-- the city far below (just for looks)
	part("CityGround", Vector3.new(900, 2, 900), CFrame.new(P(0, -200, 0)), "Really black", "Concrete")
	local NEON = { "Cyan", "Hot pink", "Bright violet", "New Yeller", "Lime green" }
	local n = 0
	for gx = -4, 4 do
		for gz = -4, 4 do
			if math.abs(gx) > 1 or math.abs(gz) > 1 then
				n = n + 1
				local h = 60 + ((gx * 7 + gz * 13) % 9) * 22
				local x, z = gx * 90 + ((gz % 2) * 20), gz * 90
				part("CityTower", Vector3.new(40, h, 40), CFrame.new(P(x, -200 + h / 2, z)), n % 3 == 0 and "Dark stone grey" or "Really black", "Concrete")
				part("CityLights", Vector3.new(40.4, 1.5, 40.4), CFrame.new(P(x, -200 + h * 0.7, z)), NEON[n % #NEON + 1], "Neon")
				part("CityLights", Vector3.new(40.4, 1.5, 40.4), CFrame.new(P(x, -200 + h * 0.4, z)), NEON[(n + 2) % #NEON + 1], "Neon")
			end
		end
	end
	-- four corner rooftops (RED: west two, BLUE: east two) + their skyscrapers
	local corners = { { -75, -75, "Bright red" }, { -75, 75, "Bright red" }, { 75, -75, "Bright blue" }, { 75, 75, "Bright blue" } }
	for i, c in ipairs(corners) do
		local x, z = c[1], c[2]
		part("Roof", Vector3.new(56, 2, 56), CFrame.new(P(x, -1, z)), "Dark stone grey", "Concrete")
		part("Tower", Vector3.new(54, 180, 54), CFrame.new(P(x, -92, z)), "Really black", "Glass", { refl = 0.2 })
		for k = 1, 5 do
			part("TowerLight", Vector3.new(54.4, 1, 54.4), CFrame.new(P(x, -20 - k * 30, z)), NEON[(i + k) % #NEON + 1], "Neon")
		end
		part("RoofEdge", Vector3.new(56.4, 1, 56.4), CFrame.new(P(x, -0.4, z)), c[3], "Neon")
		-- low walls on the edges (with gaps)
		for _, e in ipairs({ { 0, 27.5, 56, 1 }, { 0, -27.5, 56, 1 }, { 27.5, 0, 1, 56 }, { -27.5, 0, 1, 56 } }) do
			part("Parapet", Vector3.new(e[3] == 56 and 20 or 1, 3, e[3] == 56 and 1 or 20), CFrame.new(P(x + e[1] + (e[3] == 56 and -18 or 0), 1.5, z + e[2] + (e[3] == 56 and 0 or -18))), "Medium stone grey", "Concrete")
			part("Parapet", Vector3.new(e[3] == 56 and 20 or 1, 3, e[3] == 56 and 1 or 20), CFrame.new(P(x + e[1] + (e[3] == 56 and 18 or 0), 1.5, z + e[2] + (e[3] == 56 and 0 or 18))), "Medium stone grey", "Concrete")
		end
		-- cover: AC units, crates, a water tank
		part("ACUnit", Vector3.new(8, 5, 6), CFrame.new(P(x - 12, 2.5, z + 10)), "Light stone grey", "Metal")
		part("ACFan", Vector3.new(0.5, 4, 4), CFrame.new(P(x - 12, 5.3, z + 10)) * A(0, 0, math.pi / 2), "Dark stone grey", "Metal", { cyl = true })
		part("Crate", Vector3.new(5, 5, 5), CFrame.new(P(x + 10, 2.5, z - 12)), "Brown", "WoodPlanks")
		part("Crate", Vector3.new(4, 4, 4), CFrame.new(P(x + 13, 7, z - 11)) * A(0, 0.4, 0), "Brown", "WoodPlanks")
		part("Crate", Vector3.new(5, 5, 5), CFrame.new(P(x - 4, 2.5, z - 14)), "Brown", "WoodPlanks")
		part("WaterTank", Vector3.new(10, 9, 9), CFrame.new(P(x + 12, 9, z + 12)) * A(0, 0, math.pi / 2), "Reddish brown", "Wood", { cyl = true })
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part("TankLeg", Vector3.new(0.6, 5, 0.6), CFrame.new(P(x + 12 + sx * 3, 2.5, z + 12 + sz * 3)), "Dark stone grey", "Metal")
			end
		end
		sign(c[3] == "Bright red" and "RED" or "BLUE", Vector3.new(18, 6, 1), CFrame.new(P(x, 9, z + (z > 0 and 27 or -27))), "Really black", c[3] == "Bright red" and Color3.new(1, 0.3, 0.3) or Color3.new(0.4, 0.6, 1))
	end
	-- helicopter on one roof
	local hc = CFrame.new(P(-75, 0, 75)) * A(0, 0.6, 0) * CFrame.new(-6, 0, -4)
	part("Helipad", Vector3.new(0.3, 18, 18), hc * CFrame.new(0, 0.1, 0) * A(0, 0, math.pi / 2), "Institutional white", "SmoothPlastic", { cyl = true })
	part("HeliBody", Vector3.new(6, 6, 12), hc * CFrame.new(0, 4, 0), "Dark green", "Metal")
	part("HeliTail", Vector3.new(1.5, 1.5, 12), hc * CFrame.new(0, 5, 11), "Dark green", "Metal")
	part("HeliRotor", Vector3.new(26, 0.3, 1), hc * CFrame.new(0, 7.5, 0), "Really black", "Metal")
	part("HeliRotor", Vector3.new(1, 0.3, 26), hc * CFrame.new(0, 7.5, 0), "Really black", "Metal")
	part("HeliGlass", Vector3.new(5.6, 3, 4), hc * CFrame.new(0, 4.5, -5), "Cyan", "Glass", { t = 0.4 })
	-- glass bridges between neighbouring corners
	for _, b in ipairs({ { -75, 0, 8, 96 }, { 75, 0, 8, 96 }, { 0, -75, 96, 8 }, { 0, 75, 96, 8 } }) do
		part("Bridge", Vector3.new(b[3], 1, b[4]), CFrame.new(P(b[1], -0.5, b[2])), "Cyan", "Glass", { t = 0.35 })
		local alongX = b[3] > b[4]
		for _, s in ipairs({ -1, 1 }) do
			part("BridgeRail", Vector3.new(alongX and b[3] or 0.4, 3, alongX and 0.4 or b[4]), CFrame.new(P(b[1] + (alongX and 0 or s * 4), 1.5, b[2] + (alongX and s * 4 or 0))), "Cyan", "Glass", { t = 0.5 })
			part("BridgeNeon", Vector3.new(alongX and b[3] or 0.3, 0.3, alongX and 0.3 or b[4]), CFrame.new(P(b[1] + (alongX and 0 or s * 4), 3.1, b[2] + (alongX and s * 4 or 0))), "Hot pink", "Neon")
		end
	end
	-- the centre tower (higher), with a sniper nest on top (climb the ladder)
	part("CentreRoof", Vector3.new(44, 2, 44), CFrame.new(P(0, 14, 0)), "Dark stone grey", "Concrete")
	part("CentreTower", Vector3.new(42, 120, 42), CFrame.new(P(0, -47, 0)), "Really black", "Glass", { refl = 0.3 })
	part("CentreEdge", Vector3.new(44.4, 1, 44.4), CFrame.new(P(0, 14.6, 0)), "Bright violet", "Neon")
	for _, c in ipairs({ { -12, 4 }, { 12, -4 }, { 4, 12 }, { -4, -12 } }) do
		part("Crate", Vector3.new(5, 5, 5), CFrame.new(P(c[1], 17.5, c[2])), "Dark stone grey", "Metal")
	end
	part("NestBase", Vector3.new(12, 1, 12), CFrame.new(P(0, 30.5, 0)), "Dark stone grey", "Metal")
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part("NestLeg", Vector3.new(1, 15, 1), CFrame.new(P(sx * 5.5, 22.5, sz * 5.5)), "Dark stone grey", "Metal")
		end
	end
	for _, e in ipairs({ { 0, 6, 12, 1 }, { 0, -6, 12, 1 }, { 6, 0, 1, 12 } }) do
		part("NestWall", Vector3.new(e[3], 3, e[4]), CFrame.new(P(e[1], 32.5, e[2])), "Dark stone grey", "Metal")
	end
	part("NestRoof", Vector3.new(13, 0.6, 13), CFrame.new(P(0, 38, 0)), "Bright violet", "Neon", { t = 0.3 })
	part("Ladder", Vector3.new(2, 16, 2), CFrame.new(P(-7, 23, 0)), "Dark stone grey", "Metal", { truss = true })
	part("Antenna", Vector3.new(0.6, 30, 0.6), CFrame.new(P(4, 54, 4)), "Light stone grey", "Metal")
	part("AntennaLight", Vector3.new(1.4, 1.4, 1.4), CFrame.new(P(4, 69.5, 4)), "Really red", "Neon", { ball = true })
	sign("SKYLINE MAYHEM", Vector3.new(30, 7, 1), CFrame.new(P(0, 22, -21)), "Really black", Color3.new(1, 0.4, 0.9))
	-- the lower deck under the middle (stairs down from every bridge)
	part("LowerDeck", Vector3.new(60, 2, 60), CFrame.new(P(0, -21, 0)), "Dark stone grey", "DiamondPlate")
	part("LowerDeckEdge", Vector3.new(60.4, 0.6, 60.4), CFrame.new(P(0, -20.4, 0)), "Lime green", "Neon")
	-- (the deck is a ring around the centre tower)
	for _, c in ipairs({ { -26, 8 }, { 26, -8 }, { 8, 26 }, { -8, -26 }, { -26, -26 }, { 26, 26 } }) do
		part("DeckCover", Vector3.new(4, 4, 4), CFrame.new(P(c[1], -18, c[2])), "Medium stone grey", "Concrete")
	end
	for _, d in ipairs({ { 0, -1, 0 }, { 0, 1, math.pi }, { -1, 0, -math.pi / 2 }, { 1, 0, math.pi / 2 } }) do
		-- a ramp from the middle of each bridge down to the deck
		local mx, mz = d[1] * 71, d[2] * 71
		local tx, tz = d[1] * 30, d[2] * 30
		local mid = (Vector3.new(mx, 0, mz) + Vector3.new(tx, -20, tz)) / 2
		local len = (Vector3.new(mx - tx, 20, mz - tz)).magnitude
		part("Ramp", Vector3.new(8, 1, len), CFrame.new(P(mid.X, mid.Y, mid.Z), P(tx, -20, tz)), "Dark stone grey", "DiamondPlate")
	end
	-- jump pads: from each corner up to the centre roof, and from the centre roof out to each corner
	local function pad(from, to)
		local p = part("JumpPad", Vector3.new(0.5, 6, 6), CFrame.new(from + Vector3.new(0, 0.2, 0)) * A(0, 0, math.pi / 2), "Cyan", "Neon", { cyl = true })
		table.insert(pads, { part = p, to = xpos(to) })
	end
	for _, c in ipairs(corners) do
		local x, z = c[1], c[2]
		pad(P(x * 0.72, 0, z * 0.72), P(x * 0.25, 16, z * 0.25))
		pad(P(x * 0.2, 15, z * 0.2), P(x * 0.9, 1, z * 0.9))
	end
	-- teleporters: red roof <-> blue roof across the map
	local function tele(a, b)
		local pa = part("Teleporter", Vector3.new(0.5, 6, 6), CFrame.new(a + Vector3.new(0, 0.2, 0)) * A(0, 0, math.pi / 2), "Bright violet", "Neon", { cyl = true })
		local pb = part("Teleporter", Vector3.new(0.5, 6, 6), CFrame.new(b + Vector3.new(0, 0.2, 0)) * A(0, 0, math.pi / 2), "Bright violet", "Neon", { cyl = true })
		table.insert(teleports, { part = pa, to = xpos(b) + Vector3.new(0, 4, 4) })
		table.insert(teleports, { part = pb, to = xpos(a) + Vector3.new(0, 4, 4) })
	end
	tele(P(-90, 0, -60), P(90, 0, 60))
	tele(P(-90, 0, 60), P(90, 0, -60))
	-- spawns
	local red, blue, any = {}, {}, {}
	for _, c in ipairs(corners) do
		for k = -1, 1 do
			-- (v6: moved to the open outer side of the roof; some v5 spawns were inside AC units and water tanks)
			local cf = xcf(CFrame.new(P(c[1] + k * 8, 3, c[2] + (c[2] > 0 and 20 or -20))))
			if c[3] == "Bright red" then
				table.insert(red, cf)
			else
				table.insert(blue, cf)
			end
			table.insert(any, cf)
		end
	end
	for _, s in ipairs({ { 0, -18, -26 }, { 26, -18, 0 }, { -26, -18, 0 }, { 0, -18, 26 } }) do
		table.insert(any, xcf(CFrame.new(P(s[1], s[2], s[3]))))
	end
	-- King of the Hill spots: the centre roof, the lower deck (north and south)
	local hills = { xpos(P(0, 15, 0)), xpos(P(0, -20, -28)), xpos(P(0, -20, 28)) }
	XF = nil
	return { id = "skyline", name = "SKYLINE MAYHEM", folder = folder, spawns = { red = red, blue = blue, any = any }, killY = Y - 60, time = 20.5, pads = pads, teleports = teleports,
		hills = hills, hillR = 16 }
end


------------------------------------------------------------------
-- DESERT OUTPOST (v6, big: 560 x 460)
-- RED: a military outpost in the west. BLUE: an oil field in the east.
-- Middle: a walled compound (walk on the walls, climb the keep to its roof).
-- North: temple ruins on a raised platform. South: a bazaar street with houses.
------------------------------------------------------------------
local function buildDesert()
	folder = Instance.new("Model")
	folder.Name = "Desert"
	folder.Parent = game.Workspace
	local OX = -1600
	local function P(x, y, z)
		return Vector3.new(OX + x, y, z)
	end
	local function C(x, y, z, rot)
		return CFrame.new(P(x, y, z)) * A(0, rot or 0, 0)
	end
	local SAND, WALL, DARKWALL = "Brick yellow", "Nougat", "Light orange"
	part("Ground", Vector3.new(560, 2, 460), CFrame.new(P(0, -1, 0)), SAND, "Sand")
	-- far away mesas and dunes (just for looks)
	for _, m in ipairs({ { -380, -200, 90, 50, 0.3 }, { -360, 160, 120, 40, -0.4 }, { 390, -120, 100, 60, 0.2 }, { 370, 210, 80, 45, 0.6 },
		{ 0, -330, 160, 35, 0 }, { -150, 320, 120, 30, 0.2 }, { 200, 330, 140, 38, -0.1 } }) do
		part("BgMesa", Vector3.new(m[3], m[4], m[3] * 0.7), C(m[1], m[4] / 2 - 2, m[2], m[5]), "Dark orange", "Slate")
		part("BgMesa", Vector3.new(m[3] * 0.6, m[4] * 0.4, m[3] * 0.5), C(m[1] + m[3] * 0.3, m[4] + m[4] * 0.2 - 2, m[2], m[5] + 0.3), "Sand red", "Slate")
	end
	-- roads
	part("Road", Vector3.new(204, 0.2, 18), CFrame.new(P(-148, 0, 0)), "Nougat", "Sand")
	part("Road", Vector3.new(204, 0.2, 18), CFrame.new(P(148, 0, 0)), "Nougat", "Sand")
	part("Road", Vector3.new(16, 0.2, 86), CFrame.new(P(0, 0, -89)), "Nougat", "Sand")
	part("Road", Vector3.new(16, 0.2, 62), CFrame.new(P(0, 0, 77)), "Nougat", "Sand")

	-- THE COMPOUND (middle): 90 x 90 walls with a gate on every side
	for _, w in ipairs({ { 0, -45, 0 }, { 0, 45, 0 }, { -45, 0, math.pi / 2 }, { 45, 0, math.pi / 2 } }) do
		wall(C(w[1], 0, w[2], w[3]), 90, 14.5, 2, { { 0, 14, 0, 10 }, { -28, 3, 7, 10 }, { 28, 3, 7, 10 } }, WALL, "Concrete")
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part("CornerTower", Vector3.new(8, 18, 8), CFrame.new(P(sx * 45, 9, sz * 45)), DARKWALL, "Concrete")
			part("CornerTowerTop", Vector3.new(9, 1, 9), CFrame.new(P(sx * 45, 18.5, sz * 45)), WALL, "Concrete")
		end
	end
	-- walkways on top of the walls (the wall sticks up 3.5 above them, so you can hide and shoot over)
	part("Rampart", Vector3.new(88, 1, 4), CFrame.new(P(0, 10.5, -42)), "Reddish brown", "WoodPlanks")
	part("Rampart", Vector3.new(88, 1, 4), CFrame.new(P(0, 10.5, 42)), "Reddish brown", "WoodPlanks")
	part("Rampart", Vector3.new(4, 1, 80), CFrame.new(P(-42, 10.5, 0)), "Reddish brown", "WoodPlanks")
	part("Rampart", Vector3.new(4, 1, 80), CFrame.new(P(42, 10.5, 0)), "Reddish brown", "WoodPlanks")
	-- two ramps up to the walkways (along the north and south walls, away from the gates)
	wedgeRamp(P(-24, 0, -37), 6, 11, 28, "+X", DARKWALL, "Concrete")
	wedgeRamp(P(24, 0, 37), 6, 11, 28, "-X", DARKWALL, "Concrete")
	-- the keep (2 floors high, a ramp inside goes up to the roof)
	building(C(0, 0, 0), 30, 24, 12, { wall = SAND, mat = "Concrete", trim = "Reddish brown", roof = WALL, ramp = true,
		holes = { front = { { 0, 5, 0, 8 }, { -9, 4, 4, 8 }, { 9, 4, 4, 8 } }, left = { { 4, 5, 0, 8 } }, right = { { 4, 5, 0, 8 } } } })
	-- market stalls, a well, crates and barrels in the courtyard
	local CLOTH = { "Bright red", "Bright blue", "Bright orange", "Bright violet", "Bright green" }
	local function stall(cf, cloth)
		part("StallTable", Vector3.new(8, 3, 3), cf * CFrame.new(0, 1.5, 0), "Reddish brown", "Wood")
		for _, sx in ipairs({ -1, 1 }) do
			part("StallPost", Vector3.new(0.4, 7.5, 0.4), cf * CFrame.new(sx * 4, 3.75, 2), "Brown", "Wood")
			part("StallPost", Vector3.new(0.4, 6.5, 0.4), cf * CFrame.new(sx * 4, 3.25, -2), "Brown", "Wood")
		end
		part("StallCloth", Vector3.new(9, 0.3, 5.4), cf * CFrame.new(0, 7.1, 0) * A(-0.2, 0, 0), cloth, "Fabric")
		part("Goods", Vector3.new(1.5, 1, 1.5), cf * CFrame.new(-2, 3.5, 0), "Bright orange", "SmoothPlastic", { ball = true })
		part("Goods", Vector3.new(2, 1, 1.4), cf * CFrame.new(1.8, 3.5, 0.2), "Bright yellow", "Fabric")
	end
	stall(C(-25, 0, -28), CLOTH[1])
	stall(C(25, 0, -28, 0.2), CLOTH[2])
	stall(C(-24, 0, 33, math.pi), CLOTH[3])
	stall(C(22, 0, 26, math.pi), CLOTH[4])
	column("Well", P(0, 0, -28), 3, 7, "Light stone grey", "Brick")
	part("WellWater", Vector3.new(0.3, 5.6, 5.6), CFrame.new(P(0, 3.05, -28)) * A(0, 0, math.pi / 2), "Deep blue", "Glass", { cyl = true, nocollide = true })
	for _, sx in ipairs({ -1, 1 }) do
		part("WellPost", Vector3.new(0.5, 6, 0.5), CFrame.new(P(sx * 3, 6, -28)), "Brown", "Wood")
	end
	part("WellRoof", Vector3.new(7.5, 0.5, 4), CFrame.new(P(0, 9.2, -28)), "Reddish brown", "WoodPlanks")
	crate(P(-31, 0, -10), 4, 0.2)
	crate(P(-31, 4, -10), 3, 0.5)
	crate(P(30, 0, 9), 4.5, 0.1)
	crate(P(-12, 0, 30), 4, 0.6)
	crate(P(14, 0, -36), 4, 0.3)
	barrel(P(18, 0, 30), "Bright red")
	barrel(P(20.5, 0, 31), "Bright blue")
	barrel(P(-18, 0, -38), "Earth green")
	palm(P(-36, 0, 36), 20)
	palm(P(36, 0, -36), 18)

	-- RED BASE (west): a military outpost behind big sand barriers
	part("Hesco", Vector3.new(60, 6, 5), CFrame.new(P(-205, 3, -45)), SAND, "Fabric")
	part("Hesco", Vector3.new(60, 6, 5), CFrame.new(P(-205, 3, 45)), SAND, "Fabric")
	part("Hesco", Vector3.new(5, 6, 33), CFrame.new(P(-172, 3, -28.5)), SAND, "Fabric")
	part("Hesco", Vector3.new(5, 6, 33), CFrame.new(P(-172, 3, 28.5)), SAND, "Fabric")
	for _, z in ipairs({ -45, 45 }) do
		for x = -232, -178, 9 do
			part("HescoPost", Vector3.new(0.4, 6.2, 5.2), CFrame.new(P(x, 3.1, z)), "Dark stone grey", "Metal")
		end
	end
	ridge("Tent", C(-212, 0, -24), 12, 16, 7, "Olive", "Fabric")
	ridge("Tent", C(-212, 0, 24), 12, 16, 7, "Olive", "Fabric")
	-- watchtower (climb the ladder on the back)
	local wt = P(-188, 0, -30)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part("TowerLeg", Vector3.new(1, 20, 1), CFrame.new(wt + Vector3.new(sx * 4, 10, sz * 4)), "Reddish brown", "Wood")
		end
	end
	part("TowerFloor", Vector3.new(10, 1, 10), CFrame.new(wt + Vector3.new(0, 14, 0)), "Reddish brown", "WoodPlanks")
	part("TowerWall", Vector3.new(10, 3, 0.6), CFrame.new(wt + Vector3.new(0, 16, -4.7)), "Brick yellow", "Fabric")
	part("TowerWall", Vector3.new(10, 3, 0.6), CFrame.new(wt + Vector3.new(0, 16, 4.7)), "Brick yellow", "Fabric")
	part("TowerWall", Vector3.new(0.6, 3, 10), CFrame.new(wt + Vector3.new(4.7, 16, 0)), "Brick yellow", "Fabric")
	part("TowerRoof", Vector3.new(11, 0.6, 11), CFrame.new(wt + Vector3.new(0, 20.3, 0)), "Olive", "Fabric")
	part("Ladder", Vector3.new(2, 14, 2), CFrame.new(wt + Vector3.new(-6, 7.5, 0)), "Dark stone grey", "Metal", { truss = true })
	-- a tank and a jeep in front of the base (cover), a flag
	local tank = C(-140, 0, 8, 0.15)
	part("TankTrack", Vector3.new(20, 3, 2.6), tank * CFrame.new(0, 1.5, -5), "Really black", "DiamondPlate")
	part("TankTrack", Vector3.new(20, 3, 2.6), tank * CFrame.new(0, 1.5, 5), "Really black", "DiamondPlate")
	part("TankHull", Vector3.new(19, 3.5, 9), tank * CFrame.new(0, 4, 0), "Olive", "Metal")
	part("TankTurret", Vector3.new(8, 3, 7), tank * CFrame.new(-1, 7.2, 0), "Olive", "Metal")
	part("TankGun", Vector3.new(14, 1, 1), tank * CFrame.new(10, 7.4, 0), "Dark stone grey", "Metal", { cyl = true })
	vehicle(C(-200, 0, 2, math.pi / 2), 12, 6, 2.6, "Olive", 5, 2.6, "Olive")
	sandbags(C(-150, 0, -55, 0.4), 12)
	sandbags(C(-150, 0, 55, -0.4), 12)
	sandbags(C(-180, 0, -8, math.pi / 2), 8)
	part("FlagPole", Vector3.new(0.6, 22, 0.6), CFrame.new(P(-228, 11, 0)), "Light stone grey", "Metal")
	part("Flag", Vector3.new(0.2, 5, 8), CFrame.new(P(-228, 19.5, 4.2)), "Bright red", "Fabric")

	-- BLUE BASE (east): an oil field with big tanks, pipes, pumpjacks and a hangar
	for _, t in ipairs({ { 200, -75, 24, 16 }, { 200, 75, 24, 16 }, { 232, -112, 16, 12 }, { 232, 112, 16, 12 } }) do
		column("OilTank", P(t[1], 0, t[2]), t[4], t[3], "Institutional white", "Metal")
		column("OilTankTop", P(t[1], t[4], t[2]), 1.2, t[3] * 0.85, "Light stone grey", "Metal")
		part("OilTankBand", Vector3.new(1.2, t[3] + 0.3, t[3] + 0.3), CFrame.new(P(t[1], t[4] * 0.6, t[2])) * A(0, 0, math.pi / 2), "Bright blue", "SmoothPlastic", { cyl = true })
	end
	for _, z in ipairs({ -52, 52 }) do
		part("Pipe", Vector3.new(60, 2.6, 2.6), CFrame.new(P(178, 2.3, z)), "Dark stone grey", "Metal", { cyl = true })
		for x = 154, 202, 12 do
			part("PipeStand", Vector3.new(1, 1.2, 3), CFrame.new(P(x, 0.6, z)), "Medium stone grey", "Concrete")
		end
	end
	local function pumpjack(cf)
		part("PumpBase", Vector3.new(4, 1.5, 12), cf * CFrame.new(0, 0.75, 0), "Dark stone grey", "Concrete")
		for _, sx in ipairs({ -1, 1 }) do
			part("PumpLeg", Vector3.new(0.8, 9, 0.8), cf * CFrame.new(sx * 1.4, 5.5, 0) * A(0, 0, sx * 0.12), "Bright yellow", "Metal")
		end
		part("PumpBeam", Vector3.new(1.2, 1.4, 15), cf * CFrame.new(0, 10, 0) * A(0.15, 0, 0), "Bright yellow", "Metal")
		part("PumpHead", Vector3.new(1.4, 4, 2), cf * CFrame.new(0, 9.4, -7.4), "Bright yellow", "Metal")
		part("PumpWeight", Vector3.new(1.6, 3, 3), cf * CFrame.new(0, 6, 5), "Really black", "Metal")
	end
	pumpjack(C(160, 0, -26))
	pumpjack(C(160, 0, 30, math.pi))
	-- hangar: open at both ends (east and west), walls on the north and south
	part("HangarRoof", Vector3.new(34, 1, 44), CFrame.new(P(197, 15.5, 0)), "Medium stone grey", "CorrodedMetal")
	part("HangarWall", Vector3.new(34, 15, 1), CFrame.new(P(197, 7.5, -21.5)), "Light stone grey", "CorrodedMetal")
	part("HangarWall", Vector3.new(34, 15, 1), CFrame.new(P(197, 7.5, 21.5)), "Light stone grey", "CorrodedMetal")
	vehicle(C(195, 0, -8, math.pi / 2), 16, 7, 3.5, "Bright blue", 5, 3, "Institutional white")
	crate(P(205, 0, 12), 5, 0.1)
	crate(P(201, 0, 13), 4, 0.4)
	barrel(P(186, 0, 14), "Bright blue")
	barrel(P(188, 0, 16), "Bright blue")
	sandbags(C(150, 0, -55, -0.4), 12)
	sandbags(C(150, 0, 55, 0.4), 12)
	part("FlagPole", Vector3.new(0.6, 22, 0.6), CFrame.new(P(228, 11, 0)), "Light stone grey", "Metal")
	part("Flag", Vector3.new(0.2, 5, 8), CFrame.new(P(228, 19.5, 4.2)), "Bright blue", "Fabric")

	-- NORTH: temple ruins on a platform (ramps on 3 sides), broken columns, an obelisk
	part("TemplePlatform", Vector3.new(44, 4, 32), CFrame.new(P(0, 2, -160)), "Cool yellow", "Slate")
	wedgeRamp(P(0, 0, -139), 16, 4, 10, "-Z", "Cool yellow", "Slate")
	wedgeRamp(P(27, 0, -160), 12, 4, 10, "-X", "Cool yellow", "Slate")
	wedgeRamp(P(-27, 0, -160), 12, 4, 10, "+X", "Cool yellow", "Slate")
	for i, c in ipairs({ { -18, -170, 14 }, { -6, -170, 9 }, { 6, -170, 14 }, { 18, -170, 6 }, { -18, -150, 11 }, { 18, -150, 14 }, { -6, -150, 5 } }) do
		column("TempleColumn", P(c[1], 4, c[2]), c[3], 3, "Cool yellow", "Slate")
	end
	part("TempleLintel", Vector3.new(30, 2, 4), CFrame.new(P(-6, 19, -170)), "Cool yellow", "Slate")
	part("TempleWall", Vector3.new(14, 6, 2), CFrame.new(P(-8, 7, -158)), "Brick yellow", "Slate")
	part("TempleWall", Vector3.new(2, 6, 10), CFrame.new(P(9, 7, -162)), "Brick yellow", "Slate")
	part("Obelisk", Vector3.new(3, 18, 3), CFrame.new(P(0, 13, -168)), "Brick yellow", "Slate")
	part("ObeliskTip", Vector3.new(2, 2, 2), CFrame.new(P(0, 23, -168)) * A(math.pi / 4, 0, math.pi / 4), "Gold", "Metal")
	for _, a in ipairs({ { -52, -128 }, { 52, -128 } }) do
		for _, sx in ipairs({ -1, 1 }) do
			part("ArchPillar", Vector3.new(3, 13, 3), CFrame.new(P(a[1] + sx * 6, 6.5, a[2])), "Cool yellow", "Slate")
		end
		part("ArchTop", Vector3.new(15, 2.5, 3.2), CFrame.new(P(a[1], 14.2, a[2])), "Cool yellow", "Slate")
	end
	for _, f in ipairs({ { -36, -186, 0.4 }, { 40, -176, -0.7 }, { -40, -142, 1.2 } }) do
		part("FallenColumn", Vector3.new(12, 3, 3), CFrame.new(P(f[1], 1.5, f[2])) * A(0, f[3], 0), "Cool yellow", "Slate", { cyl = true })
	end
	for _, b in ipairs({ { 30, -132, 5 }, { -26, -196, 6 }, { 34, -196, 4 } }) do
		part("RuinBlock", Vector3.new(b[3], b[3] * 0.8, b[3]), CFrame.new(P(b[1], b[3] * 0.4, b[2])) * A(0, b[3] * 0.3, 0), "Cool yellow", "Slate")
	end

	-- SOUTH: the bazaar, a street with small houses on both sides (go in through the doors)
	part("Road", Vector3.new(176, 0.2, 16), CFrame.new(P(0, 0, 150)), "Nougat", "Sand")
	local HOUSE = { "Brick yellow", "Nougat", "Light orange", "Cool yellow", "Pastel brown" }
	for i, x in ipairs({ -64, -32, 0, 32, 64 }) do
		building(C(x, 0, 128, math.pi), 20, 14, 9, { wall = HOUSE[i], mat = "Concrete", roof = WALL,
			holes = { front = { { -4, 4.5, 0, 7.5 }, { 5, 3.5, 3.5, 6.5 } }, back = { { 4, 3, 3.5, 6.5 } }, left = { { 0, 4, 0, 7.5 } } } })
		building(C(x, 0, 172), 20, 14, 9, { wall = HOUSE[(i + 2) % 5 + 1], mat = "Concrete", roof = WALL,
			holes = { front = { { 4, 4.5, 0, 7.5 }, { -5, 3.5, 3.5, 6.5 } }, back = { { -4, 3, 3.5, 6.5 } }, right = { { 0, 4, 0, 7.5 } } } })
	end
	stall(C(-48, 0, 142), CLOTH[5])
	stall(C(16, 0, 142), CLOTH[1])
	stall(C(-16, 0, 158, math.pi), CLOTH[2])
	stall(C(48, 0, 158, math.pi), CLOTH[3])
	crate(P(-84, 0, 146), 4, 0.3)
	crate(P(84, 0, 154), 4, 0.8)
	barrel(P(-6, 0, 162), "Earth green")
	palm(P(-90, 0, 128), 19)
	palm(P(90, 0, 172), 21)
	palm(P(-90, 0, 176), 17)

	-- the open desert: dunes, rocks, a little oasis, wrecks
	for _, d in ipairs({ { -105, -78, 0.2 }, { -100, 82, -0.3 }, { 105, -95, 0.1 }, { 110, 85, -0.2 }, { -70, -118, 1.2 }, { 72, 112, 1.3 } }) do
		ridge("Dune", C(d[1], 0, d[2], math.pi / 2 + d[3]), 26, 40, 6, SAND, "Sand")
	end
	for _, r in ipairs({ { -240, -190, 30, 0.5 }, { -250, 185, 26, 1.1 }, { 245, -190, 28, 0.2 }, { 240, 192, 32, 0.8 }, { -130, -200, 18, 0.3 }, { 130, 205, 18, 0.9 } }) do
		part("Rock", Vector3.new(r[3], r[3] * 0.8, r[3] * 0.9), CFrame.new(P(r[1], r[3] * 0.3, r[2])) * A(0.1, r[4], 0.05), "Sand red", "Slate")
		part("Rock", Vector3.new(r[3] * 0.5, r[3] * 0.4, r[3] * 0.5), CFrame.new(P(r[1] + r[3] * 0.5, r[3] * 0.15, r[2] + r[3] * 0.4)) * A(0, r[4] + 0.8, 0), "Dark orange", "Slate")
	end
	for _, b in ipairs({ { -80, 40, 5 }, { 85, -40, 6 }, { -60, -70, 4 }, { 60, 70, 5 }, { -150, 120, 6 }, { 150, -130, 5 }, { -130, -150, 4 }, { 120, 140, 4 } }) do
		boulder(P(b[1], 0, b[2]), b[3], "Dark orange")
	end
	column("OasisWater", P(150, -0.4, -170), 0.6, 30, "Bright blue", "Glass", { nocollide = true, t = 0.2 })
	palm(P(138, 0, -180), 18)
	palm(P(162, 0, -160), 22)
	palm(P(160, 0, -184), 16)
	vehicle(C(-90, 0, -150, 2.2), 12, 6, 2.6, "Reddish brown", 5, 2.6, "Reddish brown")
	part("WreckSmoke", Vector3.new(3, 1, 3), CFrame.new(P(-90, 6, -150)), "Really black", "Slate")
	vehicle(C(95, 0, 160, -0.8), 14, 6.5, 3, "Dark stone grey", 5, 3, "Dark stone grey")
	sign("DESERT OUTPOST", Vector3.new(30, 6, 1), CFrame.new(P(0, 17, -46.5)), "Really black", Color3.new(1, 0.75, 0.3))

	-- walls around the map
	for _, s in ipairs({ { 280, 0, 2, 460 }, { -280, 0, 2, 460 }, { 0, 230, 560, 2 }, { 0, -230, 560, 2 } }) do
		part("Boundary", Vector3.new(s[3], 80, s[4]), CFrame.new(P(s[1], 40, s[2])), "Medium stone grey", "SmoothPlastic", { t = 1 })
		part("BoundaryFence", Vector3.new(s[3], 5, s[4]), CFrame.new(P(s[1], 2.5, s[2])), DARKWALL, "Brick")
	end

	-- spawns: RED west, BLUE east, free for all everywhere
	local red, blue, any = {}, {}, {}
	for i = -2, 2 do
		table.insert(red, C(-248, 3, i * 18, -math.pi / 2))
		table.insert(blue, C(248, 3, i * 18, math.pi / 2))
	end
	for _, s in ipairs({ { -248, -120 }, { -248, 120 }, { 248, -120 }, { 248, 120 }, { -108, -172 }, { 118, -192 }, { -112, 194 }, { 108, 184 },
		{ 0, -205 }, { 0, 208 }, { -70, 15 }, { 70, -15 }, { -27, -14 }, { 27, 14 }, { -160, -100 }, { 160, 100 } }) do
		table.insert(any, CFrame.new(P(s[1], 3, s[2])))
	end
	local hills = { P(0, 0, 0), P(0, 4, -160), P(0, 0, 150) }
	return { id = "desert", name = "DESERT OUTPOST", folder = folder, spawns = { red = red, blue = blue, any = any }, killY = -50, time = 13,
		pads = {}, teleports = {}, hills = hills, hillR = 20 }
end

------------------------------------------------------------------
-- FROZEN HARBOR (v6, big: 500 x 300 dock + a cargo ship)
-- A snowy dock in the sea: a maze of shipping containers in the middle, two warehouses
-- (RED west, BLUE east), an office building with a roof to snipe from, two big cranes and
-- a cargo ship you can walk onto (gangways) with a bridge tower. Fall in the water = you drown.
------------------------------------------------------------------
local function buildHarbor()
	folder = Instance.new("Model")
	folder.Name = "Harbor"
	folder.Parent = game.Workspace
	local OZ = 1700
	local function P(x, y, z)
		return Vector3.new(x, y, OZ + z)
	end
	local function C(x, y, z, rot)
		return CFrame.new(P(x, y, z)) * A(0, rot or 0, 0)
	end
	local COLORS = { "Bright red", "Bright blue", "Bright orange", "Earth green", "Dark stone grey", "Bright yellow", "Sand blue", "Reddish brown" }
	-- the sea (you can't stand on it) and the dock
	part("SeaWater", Vector3.new(1400, 1, 1400), CFrame.new(P(0, -6, 0)), "Deep blue", "Glass", { t = 0.25, nocollide = true })
	part("SeaFloor", Vector3.new(1400, 2, 1400), CFrame.new(P(0, -41, 0)), "Black", "Slate")
	part("Dock", Vector3.new(500, 6, 300), CFrame.new(P(0, -3, -30)), "Medium stone grey", "Concrete")
	for _, l in ipairs({ { -60, -30 }, { 60, -30 }, { 0, -30 } }) do
		part("DockLine", Vector3.new(0.6, 0.1, 290), CFrame.new(P(l[1], 0.05, l[2])), "New Yeller", "SmoothPlastic")
	end
	-- yellow curbs along the edges (gaps where the gangways are)
	local function curb(x0, x1, z0, z1)
		part("Curb", Vector3.new(math.max(1, x1 - x0), 1.2, math.max(1, z1 - z0)), CFrame.new(P((x0 + x1) / 2, 0.6, (z0 + z1) / 2)), "New Yeller", "Concrete")
	end
	curb(-250, -43, 119, 120)
	curb(-37, 47, 119, 120)
	curb(53, 250, 119, 120)
	curb(-250, 250, -180, -179)
	curb(-250, -249, -180, 120)
	curb(249, 250, -180, 120)
	for x = -230, 230, 30 do
		column("Bollard", P(x, 0, 116), 2, 1.6, "Really black", "Metal")
	end
	-- snow piles (cover) and lamp posts
	for _, s in ipairs({ { -150, 95, 9 }, { 140, -20, 8 }, { -150, -120, 10 }, { 160, -110, 9 }, { -20, 95, 7 }, { 115, 70, 8 }, { -110, 75, 7 },
		{ 0, -168, 8 }, { -60, -165, 6 }, { 75, -160, 7 } }) do
		part("SnowPile", Vector3.new(s[3], s[3], s[3]), CFrame.new(P(s[1], s[3] * 0.15, s[2])), "Institutional white", "Snow", { ball = true })
	end
	for _, l in ipairs({ { -130, -90 }, { 130, -90 }, { -130, 50 }, { 130, 50 }, { -75, 100 }, { 80, 100 }, { 0, -175 } }) do
		part("LampPost", Vector3.new(0.6, 16, 0.6), CFrame.new(P(l[1], 8, l[2])), "Dark stone grey", "Metal")
		local lamp = part("Lamp", Vector3.new(2.4, 0.8, 2.4), CFrame.new(P(l[1], 16.2, l[2])), "Institutional white", "Neon")
		local light = Instance.new("PointLight")
		light.Range = 32
		light.Brightness = 1.4
		light.Color = Color3.new(1, 0.9, 0.7)
		light.Parent = lamp
	end

	-- THE CONTAINER YARD (middle): rows of containers, some stacked, some open to run through
	local yard = {
		-- { x, z, along x?, stack, open }
		{ -84, -60, true, 2 }, { -62, -60, true, 1 }, { -20, -60, true, 1 }, { 22, -60, true, 2 }, { 64, -60, true, 1 }, { 86, -60, true, 1 },
		{ -95, -30, false, 1 }, { -70, -30, false, 2 }, { -40, -30, false, 1 }, { 0, -30, false, 1, true }, { 40, -30, false, 1 }, { 70, -30, false, 2 }, { 95, -30, false, 1 },
		{ -80, 0, true, 1 }, { -35, 0, true, 1, true }, { 15, 0, true, 1 }, { 60, 0, true, 2 },
		{ -95, 30, false, 1 }, { -60, 30, false, 2 }, { -25, 30, false, 1 }, { 25, 30, false, 1, true }, { 60, 30, false, 1 }, { 95, 30, false, 2 },
		{ -70, 60, true, 1 }, { -48, 60, true, 1 }, { 0, 60, true, 2 }, { 48, 60, true, 1 }, { 70, 60, true, 1 },
		-- more cover around the yard (north, south, and between the yard and the warehouses)
		{ -95, -118, true, 2 }, { -60, -140, false, 1 }, { 60, -140, false, 1 }, { 95, -118, true, 1, true },
		{ -85, 92, true, 1 }, { 0, 92, true, 1, true }, { 80, 92, true, 2 },
		{ -122, -40, false, 2 }, { 122, 40, false, 2 }, { -122, 40, false, 1 }, { 122, -40, false, 1 },
	}
	for i, c in ipairs(yard) do
		local rot = c[3] and math.pi / 2 or 0
		container(C(c[1], 0, c[2], rot), COLORS[i % #COLORS + 1], c[5])
		if c[4] == 2 then
			container(C(c[1], 8.6, c[2], rot), COLORS[(i + 3) % #COLORS + 1], false)
		end
	end
	-- crates to climb onto two containers
	crate(P(28, 0, 0), 4, 0.1, "Reddish brown")
	crate(P(-58, 0, -44), 4, 0.3, "Reddish brown")

	-- two big cranes at the edge of the dock (their arms reach over the ship)
	local function crane(x)
		for _, sx in ipairs({ -1, 1 }) do
			for _, z in ipairs({ 88, 114 }) do
				part("CraneLeg", Vector3.new(2.4, 36, 2.4), CFrame.new(P(x + sx * 14, 18, z)), "Bright orange", "Metal")
			end
			part("CraneBeam", Vector3.new(2.4, 3, 28), CFrame.new(P(x + sx * 14, 37.5, 101)), "Bright orange", "Metal")
			part("CraneBrace", Vector3.new(30, 2, 2), CFrame.new(P(x, 8, 88 + (sx + 1) * 13)), "Bright orange", "Metal")
		end
		part("CraneTop", Vector3.new(32, 3, 30), CFrame.new(P(x, 40.5, 101)), "Bright orange", "Metal")
		part("CraneArm", Vector3.new(5, 3, 110), CFrame.new(P(x, 43.5, 120)), "Bright orange", "Metal")
		part("CraneCab", Vector3.new(7, 5, 7), CFrame.new(P(x, 36.5, 128)), "Institutional white", "Metal")
		part("CraneCabGlass", Vector3.new(7.2, 2.5, 7.2), CFrame.new(P(x, 37, 128)), "Black", "Glass", { t = 0.3 })
		part("CraneWeight", Vector3.new(10, 6, 8), CFrame.new(P(x, 45, 60)), "Dark stone grey", "Concrete")
		part("CraneHook", Vector3.new(0.4, 18, 0.4), CFrame.new(P(x, 33, 150)), "Really black", "Metal")
		part("CraneHook", Vector3.new(2, 1.5, 2), CFrame.new(P(x, 23.5, 150)), "New Yeller", "Metal")
	end
	crane(-120)
	crane(110)

	-- WAREHOUSES: RED (west) and BLUE (east). Big doors on every side, shelves inside
	local function warehouse(x, wallColor, sideRot)
		building(C(x, 0, -60, sideRot), 80, 60, 18, { wall = wallColor, mat = "CorrodedMetal", roof = "Dark stone grey",
			holes = { front = { { 0, 16, 0, 14 }, { -28, 8, 11, 15 }, { 28, 8, 11, 15 } }, back = { { 0, 10, 0, 10 } },
				left = { { 0, 12, 0, 12 } }, right = { { 0, 12, 0, 12 } } } })
		for _, dz in ipairs({ -40, -20 }) do
			part("Shelf", Vector3.new(26, 9, 3), CFrame.new(P(x, 4.5, -60)) * A(0, sideRot, 0) * CFrame.new(-6, 0, dz + 30), "Bright blue", "Metal")
			crate(P(x, 9, -60) + (CFrame.new() * A(0, sideRot, 0) * CFrame.new(-10, 0, dz + 30)).p, 3, 0.2)
		end
		part("Shelf", Vector3.new(3, 9, 22), CFrame.new(P(x, 4.5, -60)) * A(0, sideRot, 0) * CFrame.new(24, 0, 0), "Bright blue", "Metal")
		vehicle(CFrame.new(P(x, 0, -60)) * A(0, sideRot, 0) * CFrame.new(12, 0, 4) * A(0, 0.6, 0), 7, 4, 2, "New Yeller", 3, 3, "New Yeller")
		crate(P(x, 0, -60) + (CFrame.new() * A(0, sideRot, 0) * CFrame.new(-26, 0, -18)).p, 5, 0.1)
		crate(P(x, 0, -60) + (CFrame.new() * A(0, sideRot, 0) * CFrame.new(-26, 0, 18)).p, 5, 0.5)
	end
	-- (turned so the big front door faces the middle of the map)
	warehouse(-185, "Bright red", -math.pi / 2)
	warehouse(185, "Bright blue", math.pi / 2)
	for _, sx in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -10, 10 }) do
			part("Barrier", Vector3.new(10, 3, 2), CFrame.new(P(sx * 140, 1.5, z)) * A(0, math.pi / 2, 0), "Light stone grey", "Concrete")
		end
		part("Barrier", Vector3.new(10, 3, 2), CFrame.new(P(sx * 120, 1.5, -125)), "Light stone grey", "Concrete")
	end

	-- OFFICE (north middle, door towards the containers): a ramp inside goes up to the roof
	building(C(0, 0, -140, math.pi), 36, 24, 14, { wall = "Light stone grey", mat = "Concrete", trim = "Dark stone grey", roof = "Dark stone grey", ramp = true,
		holes = { front = { { 0, 6, 0, 9 }, { -12, 6, 5, 10 }, { 12, 6, 5, 10 } }, left = { { 5, 5, 0, 8 } }, right = { { 5, 5, 0, 8 } } } })
	sign("FROZEN HARBOR", Vector3.new(26, 5, 1), CFrame.new(P(0, 20, -127.3)), "Really black", Color3.new(0.6, 0.9, 1))
	-- lighthouse (north-west corner)
	column("Lighthouse", P(-225, 0, -160), 34, 10, "Institutional white", "Concrete")
	for _, y in ipairs({ 8, 20 }) do
		column("LighthouseBand", P(-225, y, -160), 4, 10.3, "Bright red", "Concrete")
	end
	column("LighthouseLamp", P(-225, 34, -160), 5, 7, "New Yeller", "Neon", { t = 0.2 })
	column("LighthouseRoof", P(-225, 39, -160), 2, 8, "Bright red", "Metal")

	-- THE CARGO SHIP (south): walk up a gangway; containers on the deck, a bridge tower at the back
	part("ShipHull", Vector3.new(220, 16, 44), CFrame.new(P(0, 0, 150)), "Navy blue", "Metal")
	part("ShipHullLow", Vector3.new(220, 8, 42), CFrame.new(P(0, -12, 150)), "Really red", "Metal")
	part("ShipBow", Vector3.new(31.1, 16, 31.1), CFrame.new(P(110, 0, 150)) * A(0, math.pi / 4, 0), "Navy blue", "Metal")
	part("ShipBowLow", Vector3.new(29.7, 8, 29.7), CFrame.new(P(110, -12, 150)) * A(0, math.pi / 4, 0), "Really red", "Metal")
	part("ShipDeck", Vector3.new(220, 0.4, 42), CFrame.new(P(0, 8.2, 150)), "Dark stone grey", "DiamondPlate")
	part("ShipName", Vector3.new(30, 3, 0.3), CFrame.new(P(60, 3, 127.8)), "Institutional white", "SmoothPlastic")
	for _, r in ipairs({ { -110, -44 }, { -36, 46 }, { 54, 110 } }) do
		part("ShipRail", Vector3.new(r[2] - r[1], 3, 0.4), CFrame.new(P((r[1] + r[2]) / 2, 9.9, 129.4)), "Institutional white", "Metal")
	end
	part("ShipRail", Vector3.new(220, 3, 0.4), CFrame.new(P(0, 9.9, 170.6)), "Institutional white", "Metal")
	part("ShipRail", Vector3.new(0.4, 3, 42), CFrame.new(P(-109.8, 9.9, 150)), "Institutional white", "Metal")
	-- the bridge tower (front door faces the bow)
	building(C(-88, 8, 150, -math.pi / 2), 34, 24, 12, { wall = "Institutional white", mat = "Metal", trim = "Dark stone grey", roof = "Dark stone grey", ramp = true,
		holes = { front = { { 0, 5, 0, 8 }, { -11, 6, 4, 9 }, { 11, 6, 4, 9 } }, left = { { 5, 5, 0, 8 }, { -5, 4, 4, 8 } }, right = { { 5, 5, 0, 8 }, { -5, 4, 4, 8 } } } })
	part("Smokestack", Vector3.new(6, 24, 9), CFrame.new(P(-105, 20, 150)), "Really red", "Metal")
	part("SmokestackTop", Vector3.new(6.2, 2, 9.2), CFrame.new(P(-105, 33, 150)), "Really black", "Metal")
	for i, c in ipairs({ { -55, 140, 1 }, { -55, 160, 2 }, { -25, 140, 2 }, { 5, 160, 1 }, { 35, 140, 1 }, { 35, 160, 2 }, { 65, 150, 1, true }, { 90, 150, 1 } }) do
		container(C(c[1], 8.4, c[2], math.pi / 2), COLORS[(i * 3) % #COLORS + 1], c[4])
		if c[3] == 2 then
			container(C(c[1], 17, c[2], math.pi / 2), COLORS[(i * 5) % #COLORS + 1], false)
		end
	end
	-- gangways from the dock up to the deck
	walkway(P(-40, 0, 100), P(-40, 8.4, 127.6), 6, "Dark stone grey", "DiamondPlate", "New Yeller")
	walkway(P(50, 0, 100), P(50, 8.4, 127.6), 6, "Dark stone grey", "DiamondPlate", "New Yeller")

	-- spawns: RED west, BLUE east (beside the warehouses), free for all everywhere
	local red, blue, any = {}, {}, {}
	for i = -2, 2 do
		table.insert(red, C(-237, 3, i * 18, -math.pi / 2))
		table.insert(blue, C(237, 3, i * 18, math.pi / 2))
	end
	for _, s in ipairs({ { -150, 3, 60 }, { 150, 3, 60 }, { 0, 3, -110 }, { -30, 3, -45 }, { 30, 3, 45 }, { -200, 3, 70 }, { 200, 3, 70 },
		{ -200, 3, -140 }, { 200, 3, -140 }, { 50, 11, 160 }, { -10, 11, 150 }, { -237, 3, -120 }, { 237, 3, -120 }, { -110, 3, -150 }, { 110, 3, -150 } }) do
		table.insert(any, CFrame.new(P(s[1], s[2], s[3])))
	end
	local hills = { P(-10, 0, -16), P(0, 8.4, 150), P(0, 0, -105) }
	return { id = "harbor", name = "FROZEN HARBOR", folder = folder, spawns = { red = red, blue = blue, any = any }, killY = -15, time = 12,
		pads = {}, teleports = {}, hills = hills, hillR = 18 }
end

------------------------------------------------------------------
-- TIMBER FOREST (v6, big: 560 x 460)
-- A pine forest with a river down the middle (walk down the banks, or cross the 2 bridges).
-- RED: a log cabin camp in the west. BLUE: a lumber mill in the east.
-- North: a ranger station (roof) and a tall lookout tower (ladder). South: a campground and a red barn.
------------------------------------------------------------------
local function buildForest()
	folder = Instance.new("Model")
	folder.Name = "Forest"
	folder.Parent = game.Workspace
	local OZ = -1700
	local function P(x, y, z)
		return Vector3.new(x, y, OZ + z)
	end
	local function C(x, y, z, rot)
		return CFrame.new(P(x, y, z)) * A(0, rot or 0, 0)
	end
	local GRASS = "Bright green"
	-- ground on both sides of the river, the river bed and its sloped banks
	part("Ground", Vector3.new(260, 2, 460), CFrame.new(P(-150, -1, 0)), GRASS, "Grass")
	part("Ground", Vector3.new(260, 2, 460), CFrame.new(P(150, -1, 0)), GRASS, "Grass")
	part("RiverBed", Vector3.new(40, 2, 460), CFrame.new(P(0, -7, 0)), "Reddish brown", "Slate")
	part("RiverBank", Vector3.new(460, 6, 10), CFrame.new(P(-15, -3, 0)) * A(0, -math.pi / 2, 0), "Brown", "Grass", { wedge = true })
	part("RiverBank", Vector3.new(460, 6, 10), CFrame.new(P(15, -3, 0)) * A(0, math.pi / 2, 0), "Brown", "Grass", { wedge = true })
	part("RiverWater", Vector3.new(22, 1, 460), CFrame.new(P(0, -5.6, 0)), "Bright blue", "Glass", { t = 0.35, nocollide = true })
	for _, r in ipairs({ { -4, -150 }, { 6, -30 }, { -5, 40 }, { 4, 170 } }) do
		boulder(P(r[1], -6, r[2]), 4, "Dark stone grey")
	end
	-- two wooden bridges
	for _, z in ipairs({ -90, 80 }) do
		part("Bridge", Vector3.new(52, 1, 10), CFrame.new(P(0, 0.5, z)), "Reddish brown", "WoodPlanks")
		for _, sz in ipairs({ -1, 1 }) do
			part("BridgeRail", Vector3.new(52, 0.5, 0.5), CFrame.new(P(0, 3.5, z + sz * 4.8)), "Brown", "Wood")
			for x = -24, 24, 8 do
				part("BridgePost", Vector3.new(0.6, 3, 0.6), CFrame.new(P(x, 2.5, z + sz * 4.8)), "Brown", "Wood")
			end
		end
		for _, sx in ipairs({ -1, 1 }) do
			part("BridgePillar", Vector3.new(2, 7, 2), CFrame.new(P(sx * 8, -3, z)), "Brown", "Wood")
		end
	end
	-- dirt paths
	local function path(a, b)
		local pa, pb = P(a[1], 0, a[2]), P(b[1], 0, b[2])
		local len = (pb - pa).magnitude
		part("Path", Vector3.new(8, 0.2, len + 6), CFrame.new((pa + pb) / 2, pb), "Brown", "Slate")
	end
	path({ -230, 0 }, { -120, -40 })
	path({ -120, -40 }, { -26, -90 })
	path({ -120, -40 }, { -60, 60 })
	path({ -60, 60 }, { -26, 80 })
	path({ 230, 0 }, { 120, 40 })
	path({ 120, 40 }, { 26, 80 })
	path({ 120, 40 }, { 60, -60 })
	path({ 60, -60 }, { 26, -90 })
	path({ -26, -90 }, { -55, -140 })
	path({ 26, -90 }, { 50, -140 })
	path({ -26, 80 }, { -60, 130 })
	path({ 26, 80 }, { 66, 128 })
	-- mountains behind the trees (just for looks)
	for _, m in ipairs({ { -460, -100, 0.4 }, { -470, 150, -0.3 }, { 470, -160, 0.2 }, { 460, 120, -0.5 }, { -100, -420, 0.1 }, { 140, -420, -0.2 }, { -150, 420, 0.3 }, { 120, 430, -0.1 } }) do
		part("BgMountain", Vector3.new(160, 90, 160), CFrame.new(P(m[1], 10, m[2])) * A(0.5, m[3], 0.5), "Dark green", "Grass")
		part("BgSnowCap", Vector3.new(60, 40, 60), CFrame.new(P(m[1], 68, m[2])) * A(0.5, m[3], 0.5), "Institutional white", "Snow")
	end

	-- RED BASE (west): a log cabin (ramp up to its roof deck), a wood shed, a campfire and a truck
	building(C(-200, 0, -30, -math.pi / 2), 36, 24, 11, { wall = "Brown", mat = "Wood", trim = "Reddish brown", roof = "Reddish brown", ramp = true,
		holes = { front = { { 0, 5, 0, 8 }, { -11, 5, 4, 8 }, { 11, 5, 4, 8 } }, left = { { 5, 5, 0, 8 } }, right = { { 5, 5, 0, 8 } } } })
	part("Chimney", Vector3.new(3, 8, 3), CFrame.new(P(-192, 15, -46)), "Dark stone grey", "Cobblestone")
	part("WoodShed", Vector3.new(10, 7, 14), CFrame.new(P(-196, 3.5, 30)), "Reddish brown", "WoodPlanks")
	part("WoodShedRoof", Vector3.new(12, 0.6, 16), CFrame.new(P(-196, 7.3, 30)), "Dark stone grey", "Slate")
	for i = 0, 2 do
		part("Firewood", Vector3.new(8, 1.2, 1.2), CFrame.new(P(-185.5, 0.6 + i * 1.1, 26 + i * 0.6)), "Brown", "Wood", { cyl = true })
	end
	column("Campfire", P(-170, 0, 20), 0.6, 5, "Dark stone grey", "Cobblestone")
	local fire = part("FireGlow", Vector3.new(1.5, 1.5, 1.5), CFrame.new(P(-170, 1.2, 20)), "Bright orange", "Neon", { nocollide = true })
	pcall(function()
		local f = Instance.new("Fire")
		f.Size = 4
		f.Parent = fire
		local l = Instance.new("PointLight")
		l.Color = Color3.new(1, 0.6, 0.2)
		l.Range = 24
		l.Parent = fire
	end)
	for _, a in ipairs({ 0, 2.1, 4.2 }) do
		part("LogSeat", Vector3.new(7, 1.6, 1.6), CFrame.new(P(-170 + math.cos(a) * 6, 0.8, 20 + math.sin(a) * 6)) * A(0, -a + math.pi / 2, 0), "Brown", "Wood", { cyl = true })
	end
	vehicle(C(-160, 0, -70, 0.4), 14, 6.5, 3.5, "Bright red", 5, 3, "Bright red")
	for _, f in ipairs({ { -235, -60, -165, -60 }, { -235, 60, -165, 60 } }) do
		local a, b = P(f[1], 0, f[2]), P(f[3], 0, f[4])
		local len = (b - a).magnitude
		part("LogFence", Vector3.new(0.8, 3.2, len), CFrame.new((a + b) / 2 + Vector3.new(0, 1.6, 0), b + Vector3.new(0, 1.6, 0)), "Brown", "Wood")
	end
	part("FlagPole", Vector3.new(0.6, 22, 0.6), CFrame.new(P(-226, 11, 0)), "Light stone grey", "Metal")
	part("Flag", Vector3.new(0.2, 5, 8), CFrame.new(P(-226, 19.5, 4.2)), "Bright red", "Fabric")

	-- BLUE BASE (east): the lumber mill (a big roof on posts), log piles, a water tower, an office
	part("MillFloor", Vector3.new(60, 1, 38), CFrame.new(P(185, 0.5, 30)), "Reddish brown", "WoodPlanks")
	for _, x in ipairs({ -28, -9, 9, 28 }) do
		for _, z in ipairs({ -18, 18 }) do
			part("MillPost", Vector3.new(1.4, 15, 1.4), CFrame.new(P(185 + x, 8, 30 + z)), "Brown", "Wood")
		end
	end
	ridge("MillRoof", C(185, 15.5, 30), 42, 64, 6, "Dark stone grey", "CorrodedMetal")
	part("SawTable", Vector3.new(14, 3, 5), CFrame.new(P(180, 2.5, 30)), "Medium stone grey", "Metal")
	part("SawBlade", Vector3.new(0.3, 4, 4), CFrame.new(P(180, 4.4, 30)) * A(0, math.pi / 2, 0), "Light stone grey", "Metal", { cyl = true })
	part("Conveyor", Vector3.new(26, 2, 4), CFrame.new(P(196, 2, 22)), "Dark stone grey", "DiamondPlate")
	for _, lp in ipairs({ { 165, 5 }, { 205, 58 }, { 150, 70 } }) do
		for row = 0, 2 do
			for k = 0, 3 - row do
				part("Log", Vector3.new(16, 2.4, 2.4), CFrame.new(P(lp[1], 1.2 + row * 2.1, lp[2] - 3.6 + k * 2.4 + row * 1.2)), "Brown", "Wood", { cyl = true })
			end
		end
	end
	local wtp = P(215, 0, -40)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part("WaterTowerLeg", Vector3.new(1, 22, 1), CFrame.new(wtp + Vector3.new(sx * 5, 11, sz * 5)), "Brown", "Wood")
		end
	end
	column("WaterTowerTank", wtp + Vector3.new(0, 22, 0), 10, 13, "Reddish brown", "WoodPlanks")
	ridge("WaterTowerRoof", CFrame.new(wtp + Vector3.new(0, 32, 0)), 14, 14, 4, "Dark stone grey", "Slate")
	building(C(185, 0, -80, math.pi / 2), 30, 20, 10, { wall = "Sand blue", mat = "WoodPlanks", trim = "Institutional white", roof = "Dark stone grey", ramp = true,
		holes = { front = { { 0, 5, 0, 8 }, { -9, 4, 4, 7 }, { 9, 4, 4, 7 } }, left = { { 4, 4.5, 0, 8 } }, right = { { 4, 4.5, 0, 8 } } } })
	vehicle(C(160, 0, -20, -0.3), 16, 7, 3.5, "Bright blue", 5, 3, "Institutional white")
	for _, f in ipairs({ { 235, -100, 160, -100 }, { 235, 80, 160, 80 } }) do
		local a, b = P(f[1], 0, f[2]), P(f[3], 0, f[4])
		local len = (b - a).magnitude
		part("LogFence", Vector3.new(0.8, 3.2, len), CFrame.new((a + b) / 2 + Vector3.new(0, 1.6, 0), b + Vector3.new(0, 1.6, 0)), "Brown", "Wood")
	end
	part("FlagPole", Vector3.new(0.6, 22, 0.6), CFrame.new(P(226, 11, 0)), "Light stone grey", "Metal")
	part("Flag", Vector3.new(0.2, 5, 8), CFrame.new(P(226, 19.5, 4.2)), "Bright blue", "Fabric")

	-- NORTH: ranger station on the west bank (ramp to the roof), a lookout tower on the east bank (ladder)
	building(C(-62, 0, -160, math.pi), 32, 22, 12, { wall = "Earth green", mat = "WoodPlanks", trim = "Institutional white", roof = "Reddish brown", ramp = true,
		holes = { front = { { 0, 5, 0, 8 }, { -10, 5, 4, 8 } }, back = {}, left = { { 4, 5, 0, 8 } }, right = { { 4, 5, 0, 8 } } } })
	local lt = P(55, 0, -160)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			part("LookoutLeg", Vector3.new(1.2, 32, 1.2), CFrame.new(lt + Vector3.new(sx * 5, 16, sz * 5)), "Brown", "Wood")
		end
	end
	part("LookoutFloor", Vector3.new(13, 1, 13), CFrame.new(lt + Vector3.new(0, 26, 0)), "Reddish brown", "WoodPlanks")
	for _, w in ipairs({ { 0, -6.2, 13, 0.6 }, { 0, 6.2, 13, 0.6 }, { 6.2, 0, 0.6, 13 } }) do
		part("LookoutWall", Vector3.new(w[3], 3, w[4]), CFrame.new(lt + Vector3.new(w[1], 28, w[2])), "Brown", "WoodPlanks")
	end
	ridge("LookoutRoof", CFrame.new(lt + Vector3.new(0, 32, 0)), 15, 15, 4, "Reddish brown", "Slate")
	part("Ladder", Vector3.new(2, 26, 2), CFrame.new(lt + Vector3.new(-7.5, 13.5, 0)), "Dark stone grey", "Metal", { truss = true })
	sign("TIMBER FOREST", Vector3.new(24, 5, 1), CFrame.new(P(-62, 18, -148.5)), "Really black", Color3.new(0.6, 1, 0.5))

	-- SOUTH-WEST: campground (tents, picnic tables, a camper van, a big campfire)
	for i, t in ipairs({ { -98, 140, 0.3, "Bright orange" }, { -84, 180, -0.4, "Bright blue" }, { -42, 180, 0.5, "Bright yellow" }, { -36, 136, -0.2, "Bright violet" } }) do
		ridge("Tent", C(t[1], 0, t[2], t[3]), 10, 12, 6, t[4], "Fabric")
	end
	column("Campfire", P(-64, 0, 152), 0.6, 6, "Dark stone grey", "Cobblestone")
	local fire2 = part("FireGlow", Vector3.new(1.8, 1.8, 1.8), CFrame.new(P(-64, 1.3, 152)), "Bright orange", "Neon", { nocollide = true })
	pcall(function()
		local f = Instance.new("Fire")
		f.Size = 5
		f.Parent = fire2
		local l = Instance.new("PointLight")
		l.Color = Color3.new(1, 0.6, 0.2)
		l.Range = 28
		l.Parent = fire2
	end)
	for _, pt in ipairs({ { -78, 124 }, { -48, 122 } }) do
		part("PicnicTable", Vector3.new(8, 0.6, 3.5), CFrame.new(P(pt[1], 3, pt[2])), "Reddish brown", "Wood")
		for _, dz in ipairs({ -2.6, 2.6 }) do
			part("PicnicBench", Vector3.new(8, 0.5, 1.2), CFrame.new(P(pt[1], 1.8, pt[2] + dz)), "Reddish brown", "Wood")
		end
	end
	vehicle(C(-64, 0, 196, math.pi / 2), 22, 7, 5, "Institutional white", 6, 3, "Bright orange")
	-- SOUTH-EAST: a red barn (ramp up to the hayloft roof), hay bales and a tractor
	building(C(70, 0, 150, math.pi), 34, 26, 13, { wall = "Bright red", mat = "WoodPlanks", trim = "Institutional white", roof = "Dark stone grey", ramp = true,
		holes = { front = { { 0, 10, 0, 10 }, { -12, 4, 5, 9 }, { 12, 4, 5, 9 } }, left = { { 5, 6, 0, 9 } }, right = { { 5, 6, 0, 9 } } } })
	for _, h in ipairs({ { 46, 128, 0.2 }, { 49, 131, 0.9 }, { 94, 132, 0.4 }, { 96, 172, 1.2 }, { 44, 172, 0.1 } }) do
		part("HayBale", Vector3.new(5, 3.5, 3.5), CFrame.new(P(h[1], 1.75, h[2])) * A(0, h[3], 0), "Bright yellow", "Fabric")
	end
	vehicle(C(100, 0, 150, 0.3), 10, 5, 3, "Bright green", 4, 3.5, "Bright green")

	-- free for all spawns (trees stay away from them)
	local ffa = { { -120, 3, -40 }, { 120, 3, 40 }, { -60, 3, 60 }, { 60, 3, -60 }, { 0, -3, -20 }, { 0, -3, 20 }, { -40, 3, -125 }, { 40, 3, 125 },
		{ -248, 3, -140 }, { 248, 3, 140 }, { -200, 3, 130 }, { 200, 3, -150 }, { -62, 3, 168 }, { -35, 3, -200 }, { 35, 3, 200 } }
	-- trees, rocks and fallen logs everywhere (not on paths, buildings or the river)
	local zones = {
		{ -30, -240, 30, 240 },      -- river
		{ -245, -75, -150, 75 },     -- red camp
		{ 145, -110, 245, 90 },      -- blue mill
		{ -92, -185, -32, -135 },    -- ranger station
		{ 38, -178, 72, -142 },      -- lookout tower
		{ -115, 110, -22, 212 },     -- campground
		{ 40, 120, 112, 180 },       -- barn
		{ -265, -50, -225, 50 },     -- red spawn
		{ 225, -50, 265, 50 },       -- blue spawn
		{ -70, -105, 70, -75 },      -- north bridge
		{ -70, 65, 70, 95 },         -- south bridge
	}
	for _, s in ipairs(ffa) do
		table.insert(zones, { s[1] - 10, s[3] - 10, s[1] + 10, s[3] + 10 })
	end
	-- the paths (keep them clear)
	local paths = { { -230, 0, -120, -40 }, { -120, -40, -26, -90 }, { -120, -40, -60, 60 }, { -60, 60, -26, 80 }, { 230, 0, 120, 40 },
		{ 120, 40, 26, 80 }, { 120, 40, 60, -60 }, { 60, -60, 26, -90 }, { -26, -90, -55, -140 }, { 26, -90, 50, -140 }, { -26, 80, -60, 130 }, { 26, 80, 66, 128 } }
	local function nearPath(x, z)
		for _, pth in ipairs(paths) do
			local ax, az, bx, bz = pth[1], pth[2], pth[3], pth[4]
			local dx, dz = bx - ax, bz - az
			local t = ((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz)
			t = math.max(0, math.min(1, t))
			local px, pz = ax + dx * t, az + dz * t
			if (x - px) ^ 2 + (z - pz) ^ 2 < 10 * 10 then
				return true
			end
		end
		return false
	end
	local placed = {}
	local function spotOK(x, z, gap)
		if not freeSpot(x, z, zones) or nearPath(x, z) then
			return false
		end
		for _, q in ipairs(placed) do
			if (q[1] - x) ^ 2 + (q[2] - z) ^ 2 < gap * gap then
				return false
			end
		end
		return true
	end
	seed = 4242
	local trees, tries = 0, 0
	while trees < 95 and tries < 3000 do
		tries = tries + 1
		local x, z = rnd(-265, 265), rnd(-218, 218)
		if spotOK(x, z, 14) then
			table.insert(placed, { x, z })
			trees = trees + 1
			if rnd(0, 1) < 0.75 then
				pine(P(x, 0, z), rnd(20, 30))
			else
				tree(P(x, 0, z), rnd(14, 19))
			end
		end
	end
	local rocks = 0
	tries = 0
	while rocks < 22 and tries < 2000 do
		tries = tries + 1
		local x, z = rnd(-260, 260), rnd(-215, 215)
		if spotOK(x, z, 10) then
			table.insert(placed, { x, z })
			rocks = rocks + 1
			if rocks % 2 == 0 then
				boulder(P(x, 0, z), rnd(5, 10))
			else
				part("FallenLog", Vector3.new(rnd(10, 16), 2.4, 2.4), CFrame.new(P(x, 1.2, z)) * A(0, rnd(0, 3.1), 0), "Brown", "Wood", { cyl = true })
			end
		end
	end

	-- walls around the map
	for _, s in ipairs({ { 280, 0, 2, 460 }, { -280, 0, 2, 460 }, { 0, 230, 560, 2 }, { 0, -230, 560, 2 } }) do
		part("Boundary", Vector3.new(s[3], 80, s[4]), CFrame.new(P(s[1], 40, s[2])), "Medium stone grey", "SmoothPlastic", { t = 1 })
		part("BoundaryFence", Vector3.new(s[3], 4, s[4]), CFrame.new(P(s[1], 2, s[2])), "Brown", "Wood")
	end

	local red, blue, any = {}, {}, {}
	for i = -2, 2 do
		table.insert(red, C(-248, 3, i * 18, -math.pi / 2))
		table.insert(blue, C(248, 3, i * 18, math.pi / 2))
	end
	for _, s in ipairs(ffa) do
		table.insert(any, CFrame.new(P(s[1], s[2], s[3])))
	end
	local hills = { P(0, -6, 0), P(-62, 0, -160), P(70, 0, 150), P(-64, 0, 152) }
	return { id = "forest", name = "TIMBER FOREST", folder = folder, spawns = { red = red, blue = blue, any = any }, killY = -50, time = 16,
		pads = {}, teleports = {}, hills = hills, hillR = 20 }
end

function M.buildAll()
	local lobby = buildLobby()
	local maps = {}
	for _, build in ipairs({ buildNuketown, buildSkyline, buildDesert, buildHarbor, buildForest }) do
		local ok, m = pcall(build)
		if ok and m then
			maps[m.id] = m
		else
			print("[Shooter] a map failed to build: " .. tostring(m))
		end
	end
	return { lobby = lobby, maps = maps }
end

return M
