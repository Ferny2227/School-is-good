-- ==== s26_hotel.lua
------------------------------------------------------------------ the hotel (right of the terminal, on the new land)
-- Building x 216..296, z 120..280. Lobby floor top HL[1] = 1, then floors 2..6 (HL[2..6]), roof at HOTEL.roof.
-- Floor 2: standard rooms, 3: deluxe rooms (8 each, every one themed differently), 4: four suites, 5: the penthouse,
-- 6: spa, sauna, ballroom and conference room. A real elevator (front middle) stops at every floor and the roof.
local HLIFT = { levels = { HL[1], HL[2], HL[3], HL[4], HL[5], HL[6], HOTEL.roof },
	keys = { "helevator", "hfloor2", "hfloor3", "hfloor4", "hfloor5", "hfloor6", "hroof" }, names = { "L", "2", "3", "4", "5", "6", "R" } }
local ROOM_Z = { 154, 190, 226, 262 }
local HHOLE = { { HOTEL.cx - 4, HOTEL.cx + 4, HOTEL.liftZ - 4, HOTEL.liftZ + 4 } }

local function hotelShaft(b, level)
	local top = HLIFT.levels[level + 1]
	if top then U.shaft(b, HOTEL.cx, HOTEL.liftZ, HLIFT.levels[level], top - HLIFT.levels[level], "+z", "Gold") end
	U.liftDoor(b, "H", level)
end

-- outer walls of one storey: y0 = floor top, door gaps (x ranges) in the front/back walls
local function storey(b, y0, frontGap, backGap, color)
	local H = HOTEL
	local h = 12
	local function wallX(z, gap)
		local cuts = { H.x0, H.x1 }
		if gap then cuts = { H.x0, gap[1], gap[2], H.x1 } end
		for i = 1, #cuts, 2 do
			local a, c = cuts[i], cuts[i + 1]
			U.blk(b, "Wall", c - a, h, 0.8, (a + c) / 2, y0, z, color, "Concrete")
			U.blk(b, "Window", c - a - 2, 4, 0.9, (a + c) / 2, y0 + 4, z, "Pastel light blue", "Glass", { tr = 0.3 })
		end
	end
	wallX(H.z0, frontGap)
	wallX(H.z1, backGap)
	for _, x in ipairs({ H.x0, H.x1 }) do
		U.blk(b, "Wall", 0.8, h, H.z1 - H.z0, x, y0, (H.z0 + H.z1) / 2, color, "Concrete")
		for _, zc in ipairs(ROOM_Z) do U.blk(b, "Window", 0.9, 5, 20, x, y0 + 3.5, zc, "Pastel light blue", "Glass", { tr = 0.3 }) end
	end
	-- a coloured stripe round the top of the storey
	for _, z in ipairs({ H.z0 - 0.5, H.z1 + 0.5 }) do U.blk(b, "Stripe", H.x1 - H.x0 + 2, 1, 0.4, H.cx, y0 + h - 1.5, z, b.plot.color, "SmoothPlastic") end
	for _, x in ipairs({ H.x0 - 0.5, H.x1 + 0.5 }) do U.blk(b, "Stripe", 0.4, 1, H.z1 - H.z0 + 2, x, y0 + h - 1.5, (H.z0 + H.z1) / 2, b.plot.color, "SmoothPlastic") end
end

function K.hotel(b)
	local H = HOTEL
	U.blk(b, "LobbyFloor", H.x1 - H.x0, 1, H.z1 - H.z0, H.cx, 0, (H.z0 + H.z1) / 2, "Institutional white", "Marble")
	storey(b, HL[1], { H.doorX - 8, H.doorX + 8 }, { H.cx - 6, H.cx + 6 }, "Institutional white")
	-- the lobby ceiling only covers the lobby; the floors above bring their own slabs
	U.blk(b, "Canopy", 24, 0.8, 10, H.doorX, HL[1] + 10, H.z0 - 5, b.plot.color, "SmoothPlastic")
	for _, dx in ipairs({ -11, 11 }) do U.blk(b, "CanopyPost", 0.8, 10, 0.8, H.doorX + dx, 0.5, H.z0 - 9.5, "Gold", "Metal") end
	local s = U.blk(b, "HotelSign", 30, 4, 0.6, H.cx + 12, HL[1] + 7.6, H.z0 - 0.8, "Really black", "SmoothPlastic")
	U.text(s, "AIRPORT HOTEL", Color3.new(1, 0.85, 0.3), Color3.new(0.05, 0.05, 0.12), "Front")
	U.light(s, Color3.new(1, 0.85, 0.4), 30)
	U.blk(b, "Path", 8, 0.4, 64, H.doorX, 0, 88, "Light stone grey", "Concrete")
	U.blk(b, "Carpet", 6, 0.1, 30, H.doorX, HL[1], 136, "Bright red", "Fabric", { nc = true })
	for _, dx in ipairs({ -6, 6 }) do U.blk(b, "LobbyDoor", 6, 9, 0.3, H.doorX + dx * 0.5, HL[1], H.z0, "Pastel light blue", "Glass", { tr = 0.65, nc = true }) end
	for _, p in ipairs({ { 290, 128 }, { 222, 190 } }) do U.cyl(b, "Pot", 3, 2.4, p[1], HL[1], p[2], "Reddish brown") U.ball(b, "Plant", 4, p[1], HL[1] + 4, p[2], "Dark green", "Grass") end
	SPOT(b, "bellhop", H.doorX + 7, HL[1], H.z0 + 4, 180)
	SPOT(b, "bellhop", H.doorX - 7, HL[1], H.z0 + 4, 180)
	SPOT(b, "bellhop", 250, HL[1], 140, -90)
	b.plot.hasHotel = true
end

function K.hreception(b)
	local y = HL[1]
	U.blk(b, "Desk", 20, 3.8, 3, 235, y, 160, "Brown", "Wood")
	U.blk(b, "DeskTop", 20.4, 0.4, 3.4, 235, y + 3.8, 160, "Gold", "Metal", { refl = 0.3 })
	U.blk(b, "BackWall", 24, 9, 0.6, 235, y, 168, "Reddish brown", "Wood")
	local s = U.blk(b, "Sign", 16, 2.4, 0.3, 235, y + 6, 167.6, "Really black", "SmoothPlastic")
	U.text(s, "RECEPTION", Color3.new(1, 0.85, 0.3), Color3.new(0.05, 0.05, 0.1), "Back")
	U.blk(b, "KeyRack", 6, 3, 0.3, 245, y + 3, 167.6, "Gold", "Metal")
	U.blk(b, "Computer", 1.6, 1.2, 0.3, 231, y + 4.2, 160.4, "Cyan", "Neon")
	U.ball(b, "Bell", 0.7, 239, y + 4.5, 159.4, "Gold", "Metal")
	SPOT(b, "receptionist", 230, y, 163, 180)
	SPOT(b, "receptionist", 240, y, 163, 180)
	SPOT(b, "receptionist", 226, y, 163, 180)
	PT(b, "hdesk", { q = Vector3.new(235, y, 155) })
end
function K.hsofas(b)
	local y = HL[1]
	U.blk(b, "Rug", 22, 0.1, 30, 281, y, 155, "Royal purple", "Fabric", { nc = true })
	for _, z in ipairs({ 144, 166 }) do
		for i = -1, 1 do U.seat(b, 281 + i * 6, y, z, z < 155 and 180 or 0, "Really black", 5) end
		U.blk(b, "SofaBack", 18, 2.6, 1, 281, y + 0.5, z + (z < 155 and -1.6 or 1.6), "Really black", "Fabric")
	end
	U.blk(b, "CoffeeTable", 10, 1.6, 5, 281, y, 155, "Brown", "Wood")
	PT(b, "hlobby", { p = Vector3.new(272, y, 155), spend = 0 })
end
function K.hchandelier(b)
	local y = HL[1]
	U.blk(b, "Chain", 0.2, 3, 0.2, 256, y + 8.6, 166, "Gold", "Metal", { nc = true })
	local r = U.cyl(b, "Ring", 8, 0.6, 256, y + 8, 166, "Gold", "Metal", { refl = 0.4, nc = true })
	for a = 0, 300, 60 do U.ball(b, "Crystal", 1, 256 + math.cos(math.rad(a)) * 3.6, y + 7.6, 166 + math.sin(math.rad(a)) * 3.6, "Cool yellow", "Neon", { nc = true }) end
	U.light(r, Color3.new(1, 0.9, 0.6), 34)
end
function K.hrestaurant(b)
	local y = HL[1]
	U.blk(b, "Floor", 34, 0.1, 78, 233, y, 240, "Reddish brown", "Wood", { nc = true })
	U.blk(b, "Buffet", 24, 3.6, 3, 233, y, 276, "Institutional white", "Marble")
	for i = -2, 2 do U.cyl(b, "Dish", 2, 0.6, 233 + i * 4.6, y + 3.6, 276, U.pick({ "Bright orange", "Lime green", "Brown", "Bright red" })) end
	for _, p in ipairs({ { 224, 222 }, { 242, 222 }, { 224, 246 }, { 242, 246 } }) do
		U.cyl(b, "Table", 5, 0.4, p[1], y + 3, p[2], "Institutional white")
		U.cyl(b, "Leg", 0.6, 3, p[1], y, p[2], "Dark stone grey", "Metal")
		for a = 0, 270, 90 do U.seat(b, p[1] + math.cos(math.rad(a)) * 3.6, y, p[2] + math.sin(math.rad(a)) * 3.6, -a - 90, "Bright red", 1.6) end
	end
	local s = U.blk(b, "Sign", 16, 2.4, 0.3, 233, y + 8, 202, "Really black")
	U.text(s, "RESTAURANT", Color3.new(1, 1, 1), Color3.new(0.5, 0.1, 0.1), "Front")
	SPOT(b, "chef", 233, y, 279, 180)
	PT(b, "hlobby", { p = Vector3.new(233, y, 234), spend = ITEM.hrestaurant.eff.spend })
end
function K.hgift(b)
	local y = HL[1]
	for _, z in ipairs({ 214, 224, 234 }) do
		U.blk(b, "Shelf", 0.8, 6, 8, 294, y, z, "Light stone grey")
		for i = 1, 3 do U.blk(b, "Goods", 1, 1, 6, 293.4, y + i * 1.8, z, U.pick({ "Bright red", "Bright blue", "Bright yellow", "Hot pink" })) end
	end
	U.blk(b, "Counter", 8, 3.6, 2.4, 272, y, 206, "Institutional white")
	local s = U.blk(b, "Sign", 12, 2, 0.3, 279, y + 8, 200.4, "Bright green")
	U.text(s, "GIFT SHOP", Color3.new(1, 1, 1), nil, "Front")
	SPOT(b, "clerk", 272, y, 208, 180)
	PT(b, "hlobby", { p = Vector3.new(279, y, 216), spend = ITEM.hgift.eff.spend })
end
function K.hgym(b)
	local y = HL[1]
	U.blk(b, "Mat", 34, 0.1, 36, 279, y, 261, "Really black", "Fabric", { nc = true })
	for i = 0, 2 do
		U.blk(b, "Treadmill", 2.6, 0.8, 6, 268 + i * 6, y, 270, "Really black", "Metal")
		U.blk(b, "Console", 2.6, 4, 0.4, 268 + i * 6, y, 267, "Dark stone grey", "Metal")
	end
	U.P(b, "Barbell", Vector3.new(7, 0.3, 0.3), U.L(286, y + 3.4, 250), "Dark stone grey", "Metal")
	U.blk(b, "Bench", 2, 2, 6, 286, y, 252, "Bright red", "Fabric")
	U.blk(b, "Mirror", 0.2, 6, 30, 295.4, y + 2, 261, "Institutional white", "Glass", { refl = 0.5 })
	PT(b, "hlobby", { p = Vector3.new(274, y, 256), spend = 0 })
end

function K.helevator(b)
	U.lift(b, "H", HOTEL.cx, HOTEL.liftZ, HLIFT.levels, HLIFT.keys, "+z", HLIFT.names)
	hotelShaft(b, 1)
	local s = U.blk(b, "LiftSign", 6, 1.4, 0.3, HOTEL.cx, HL[1] + 10.8, HOTEL.liftZ + 4.6, "Really black", "SmoothPlastic")
	U.text(s, "ROOMS", Color3.new(1, 0.85, 0.3), nil, "Back")
end

-- inside walls of a floor: west/east corridor walls (x 251 / 261) with doors at the given z, and walls across
local LAYOUTS = {
	rooms = { dw = ROOM_Z, de = ROOM_Z, xw = { 136, 172, 208, 244 }, xe = { 136, 172, 208, 244 } },
	suites = { dw = { 160, 232 }, de = { 160, 232 }, xw = { 136, 208 }, xe = { 136, 208 } },
	amenity = { dw = { 172, 244 }, de = { 190, 262 }, xw = { 136, 208 }, xe = { 136, 244 } },
}
function K.hfloor(b, o)
	local H = HOTEL
	local y = HL[o.lvl]
	U.slab(b, "Slab", H.x0 - 0.8, H.x1 + 0.8, H.z0 - 0.8, H.z1 + 0.8, y, 1, HHOLE, "Light stone grey", "Concrete")
	storey(b, y, nil, nil, "Institutional white")
	local lay = LAYOUTS[o.layout]
	if lay then
		U.blk(b, "Corridor", 10, 0.1, H.z1 - H.z0 - 18, H.cx, y, (136 + H.z1) / 2, "Bright red", "Fabric", { nc = true })
		for _, side in ipairs({ { 251, lay.dw, lay.xw, (H.x0 + 251) / 2 }, { 261, lay.de, lay.xe, (261 + H.x1) / 2 } }) do
			local cuts = { 136 }
			for _, zc in ipairs(side[2]) do table.insert(cuts, zc - 2.5) table.insert(cuts, zc + 2.5) end
			table.insert(cuts, H.z1)
			for i = 1, #cuts, 2 do U.blk(b, "CorridorWall", 0.6, 11, cuts[i + 1] - cuts[i], side[1], y, (cuts[i] + cuts[i + 1]) / 2, "Brick yellow", "SmoothPlastic") end
			for _, z in ipairs(side[3]) do U.blk(b, "RoomWall", 35, 11, 0.6, side[4], y, z, "Brick yellow", "SmoothPlastic") end
		end
	else
		-- the penthouse: one big open floor behind a foyer wall
		for _, r in ipairs({ { H.x0, H.cx - 6 }, { H.cx + 6, H.x1 } }) do U.blk(b, "FoyerWall", r[2] - r[1], 11, 0.6, (r[1] + r[2]) / 2, y, 136, "Institutional white", "Marble") end
		U.blk(b, "FoyerArch", 12, 2, 0.8, H.cx, y + 9, 136, "Gold", "Metal")
	end
	local s = U.blk(b, "FloorSign", 8, 1.6, 0.3, H.cx, y + 8, 135.4, "Really black")
	U.text(s, o.layout == "penthouse" and "PENTHOUSE" or ("FLOOR " .. o.lvl), Color3.new(1, 0.85, 0.3), nil, "Back")
	U.light(U.blk(b, "CorridorLight", 3, 0.3, 120, H.cx, y + 10.6, 210, "Institutional white", "Neon", { nc = true }), Color3.new(1, 0.95, 0.85), 30, 0.8)
	hotelShaft(b, o.lvl)
end

------------------------------------------------------------------ rooms: every theme looks different
-- in a room, X(d) is d studs in from the outside wall (the bed is there), the door is at the corridor (d = 35)
local THEME = {
	ocean = { carpet = "Pastel light blue", accent = "Bright blue", blanket = "Cyan" },
	forest = { carpet = "Sand green", accent = "Dark green", blanket = "Bright green" },
	modern = { carpet = "Light stone grey", accent = "Really black", blanket = "Institutional white" },
	retro = { carpet = "Bright orange", accent = "Bright yellow", blanket = "Hot pink" },
	kids = { carpet = "Bright yellow", accent = "Bright blue", blanket = "Bright red" },
	space = { carpet = "Really black", accent = "Navy blue", blanket = "Royal purple" },
	japanese = { carpet = "Brick yellow", accent = "Reddish brown", blanket = "Institutional white" },
	royal = { carpet = "Royal purple", accent = "Gold", blanket = "Really red" },
}
local function roomFrame(b, side, y)
	local wx = side < 0 and HOTEL.x0 or HOTEL.x1
	return function(d) return wx - side * d end
end
-- a bed whose head is against the outside wall, centred on z
local function bed(b, X, y, z, theme, size)
	local t = THEME[theme]
	local L, Wd = 8 * (size or 1), 6.4 * (size or 1)
	if theme == "kids" then
		for lvl = 0, 1 do
			U.blk(b, "BunkBed", L, 1.2, 4, X(L / 2 + 0.5), y + lvl * 4.4, z, "Bright blue", "SmoothPlastic")
			U.blk(b, "BunkBlanket", L - 2, 0.3, 4.2, X(L / 2 + 1.5), y + 1.2 + lvl * 4.4, z, U.pick({ "Bright red", "Lime green" }), "Fabric")
		end
		for _, d in ipairs({ 0.6, L + 0.4 }) do U.blk(b, "BunkPost", 0.6, 7.8, 4.4, X(d), y, z, "Bright red", "SmoothPlastic") end
		U.blk(b, "Ladder", 0.3, 5.6, 1.4, X(L + 0.9), y, z - 1.4, "Bright yellow", "SmoothPlastic")
		return
	end
	local h = theme == "japanese" and 0.6 or 1.6
	U.blk(b, "Bed", L, h, Wd, X(L / 2 + 1), y, z, "Institutional white", "Fabric")
	U.blk(b, "Blanket", L * 0.62, 0.3, Wd + 0.2, X(L * 0.62), y + h, z, t.blanket, "Fabric")
	for _, dz in ipairs({ -Wd / 4, Wd / 4 }) do U.blk(b, "Pillow", 1.6, 0.6, Wd / 2 - 0.6, X(2), y + h, z + dz, "Institutional white", "Fabric") end
	if theme ~= "japanese" then U.blk(b, "Headboard", 0.6, 4, Wd + 0.6, X(1), y, z, theme == "royal" and "Gold" or "Brown", "Wood") end
	if theme == "royal" then
		for _, p in ipairs({ { 1, -1 }, { 1, 1 }, { L + 1, -1 }, { L + 1, 1 } }) do U.blk(b, "CanopyPost", 0.4, 8, 0.4, X(p[1]), y, z + p[2] * (Wd / 2 + 0.2), "Gold", "Metal") end
		U.blk(b, "Canopy", L + 0.6, 0.4, Wd + 1, X(L / 2 + 1), y + 8, z, "Really red", "Fabric", { tr = 0.1 })
	end
end
local EXTRA = {}
function EXTRA.ocean(b, X, y, zc)
	U.blk(b, "Aquarium", 6, 3, 1.2, X(9), y + 3, zc + 17, "Cyan", "Glass", { tr = 0.4 })
	for i = 1, 3 do U.blk(b, "Fish", 0.6, 0.3, 0.2, X(9 + math.random(-2, 2)), y + 4 + math.random(), zc + 17, "Bright orange", nil, { nc = true }) end
	U.P(b, "Surfboard", Vector3.new(0.3, 7, 1.6), U.L(X(2), y + 3.6, zc - 12, 0, 0, 10), "Bright yellow", "SmoothPlastic")
	U.seat(b, X(21), y, zc + 12, 0, "Bright blue", 2.4)
end
function EXTRA.forest(b, X, y, zc)
	for _, z in ipairs({ zc + 11, zc - 12 }) do
		U.cyl(b, "Pot", 2.2, 1.6, X(22), y, z, "Brown", "Wood")
		U.cyl(b, "Trunk", 0.5, 4, X(22), y + 1.6, z, "Brown", "Wood")
		U.ball(b, "Leaves", 3.6, X(22), y + 6.6, z, "Bright green", "Grass")
	end
	U.cyl(b, "LogStool", 1.6, 1.8, X(12), y, zc + 12, "Reddish brown", "Wood")
end
function EXTRA.modern(b, X, y, zc)
	U.cyl(b, "LampPole", 0.3, 6, X(22), y, zc - 12, "Dark stone grey", "Metal")
	U.light(U.ball(b, "LampShade", 1.4, X(22), y + 6.4, zc - 12, "Institutional white", "Neon"), Color3.new(1, 1, 1), 12, 0.8)
	for i, c in ipairs({ "Bright red", "Bright yellow", "Bright blue" }) do U.blk(b, "Art", 2, 2, 0.1, X(4 + i * 2.4), y + 6, zc - 17.6, c, "SmoothPlastic") end
	U.seat(b, X(21), y, zc + 12, 0, "Really black", 3)
end
function EXTRA.retro(b, X, y, zc)
	U.blk(b, "Arcade", 3, 6.4, 3, X(21), y, zc + 14, "Really black")
	U.blk(b, "ArcadeScreen", 2.4, 2, 0.1, X(21), y + 4, zc + 12.4, "Lime green", "Neon")
	U.cyl(b, "LavaLamp", 0.8, 2, X(1.6), y + 2, zc - 4.6, "Hot pink", "Neon")
	U.cyl(b, "RecordPlayer", 2, 0.4, X(9), y + 2.6, zc + 15, "Really black")
	U.blk(b, "Stand", 2, 2.6, 2, X(9), y, zc + 15, "Bright orange", "Wood")
end
function EXTRA.kids(b, X, y, zc)
	U.blk(b, "ToyBox", 3, 2, 2, X(14), y, zc + 15, "Bright red", "Wood")
	U.blk(b, "PlayMat", 6, 0.1, 6, X(20), y + 0.1, zc + 10, "Lime green", "Fabric", { nc = true })
	for i = 1, 4 do U.ball(b, "Ball", 1, X(18 + math.random(0, 4)), y + 0.6, zc + 8 + math.random(0, 4), U.pick({ "Bright red", "Bright yellow", "Bright blue" })) end
	U.blk(b, "Teddy", 1.4, 2, 1.2, X(14), y + 2, zc + 15, "Brown", "Fabric")
end
function EXTRA.space(b, X, y, zc)
	local cols = { "Bright orange", "Bright blue", "Brick yellow" }
	for i = 1, 3 do U.ball(b, "Planet", 1 + i * 0.5, X(6 + i * 5), y + 9, zc + 6 - i * 4, cols[i], nil, { nc = true }) end
	for i = 1, 8 do U.ball(b, "Star", 0.3, X(math.random(3, 30)), y + 10.6, zc + math.random(-16, 16), "Institutional white", "Neon", { nc = true }) end
	U.cyl(b, "Rocket", 1.4, 4, X(21), y, zc + 14, "Institutional white") U.ball(b, "RocketTip", 1.4, X(21), y + 4.4, zc + 14, "Bright red")
end
function EXTRA.japanese(b, X, y, zc)
	U.blk(b, "LowTable", 4, 1.2, 3, X(20), y, zc + 11, "Reddish brown", "Wood")
	for _, dz in ipairs({ -2.6, 2.6 }) do U.blk(b, "Cushion", 2, 0.4, 2, X(20), y, zc + 11 + dz, "Really red", "Fabric") end
	U.cyl(b, "BonsaiPot", 1.6, 0.8, X(1.6), y, zc - 12, "Dark stone grey") U.ball(b, "Bonsai", 2, X(1.6), y + 1.8, zc - 12, "Dark green", "Grass")
	U.light(U.cyl(b, "Lantern", 1.6, 2.4, X(9), y + 7, zc + 12, "Institutional white", "Neon", { nc = true }), Color3.new(1, 0.85, 0.6), 10)
end
function EXTRA.royal(b, X, y, zc)
	local ch = U.cyl(b, "Chandelier", 3.4, 0.4, X(14), y + 10, zc + 6, "Gold", "Metal", { refl = 0.4, nc = true })
	U.light(ch, Color3.new(1, 0.85, 0.5), 18)
	U.fx(ch, "Sparkles")
	U.seat(b, X(21), y, zc + 12, 0, "Royal purple", 3)
	U.blk(b, "ArmchairBack", 3, 3, 0.6, X(21), y + 0.5, zc + 13.4, "Gold", "Fabric")
end

function K.hroom(b, o)
	local y, side, zc = HL[o.lvl], o.side, o.z
	local X = roomFrame(b, side, y)
	local t = THEME[o.theme] or THEME.modern
	U.blk(b, "Carpet", 34, 0.1, 35, X(17.5), y, zc, t.carpet, "Fabric", { nc = true })
	U.blk(b, "AccentWall", 34, 10.6, 0.15, X(17.5), y, zc + 17.6, t.accent, "SmoothPlastic")
	bed(b, X, y, zc, o.theme, o.deluxe and 1.25 or 1)
	for _, dz in ipairs({ -5.6, 5.6 }) do
		U.blk(b, "Nightstand", 2, 2, 2, X(1.6), y, zc + dz * (o.deluxe and 1.2 or 1), "Brown", "Wood")
		U.light(U.ball(b, "Lamp", 1, X(1.6), y + 2.6, zc + dz * (o.deluxe and 1.2 or 1), "Cool yellow", "Neon"), Color3.new(1, 0.9, 0.6), 10, 0.8)
	end
	U.blk(b, "TV", 5, 3, 0.3, X(14), y + 4, zc + 17.3, "Really black")
	U.blk(b, "TVScreen", 4.6, 2.6, 0.1, X(14), y + 4.2, zc + 17.1, "Cyan", "Neon")
	U.blk(b, "Desk", 4, 2.8, 2, X(17), y, zc - 16.4, "Brown", "Wood")
	U.seat(b, X(17), y, zc - 14.4, 180, "Really black", 1.6)
	U.blk(b, "Bathroom", 9, 10, 0.4, X(30.5), y, zc + 8, "Institutional white", "SmoothPlastic")
	U.blk(b, "Bathroom", 0.4, 10, 9.6, X(26), y, zc + 12.8, "Institutional white", "SmoothPlastic")
	U.blk(b, "Tub", 4, 2, 8, X(31.5), y, zc + 13, "Institutional white", "Marble")
	if EXTRA[o.theme] then EXTRA[o.theme](b, X, y, zc) end
	if o.deluxe then
		U.blk(b, "Minibar", 2, 3, 2, X(25), y, zc - 16.4, "Really black", "SmoothPlastic")
		U.blk(b, "MinibarLight", 1.6, 0.3, 0.1, X(25), y + 2.4, zc - 15.35, "Lime green", "Neon")
		U.seat(b, X(9), y, zc + 14, 0, THEME[o.theme].accent, 5)
		U.blk(b, "SofaBack", 1, 2.4, 5, X(9) - side * 1.6, y + 0.5, zc + 14, THEME[o.theme].accent, "Fabric")
	end
	local cx = side < 0 and 251 or 261
	local sign = U.blk(b, "RoomNumber", 0.2, 1, 2, cx + side * -0.4, y + 7, zc + 4, "Gold", "Metal")
	U.text(sign, tostring(o.n), Color3.new(0, 0, 0), nil, side < 0 and "Right" or "Left")
	SPOT(b, "housekeeper", HOTEL.cx + side * 2, y, zc + 6, side < 0 and 90 or -90)
	PT(b, "hroom", { p = Vector3.new(X(12), y, zc - 4.6), door = Vector3.new(cx + side * 3, y, zc), e = Vector3.new(HOTEL.cx, y, zc),
		lvl = o.lvl, n = o.n, rate = ITEM[o.key] and ITEM[o.key].eff.spend or 40, busy = false })
end

-- suites: a living room at the front (door from the corridor) and a bedroom with a jacuzzi behind it
function K.hsuite(b, o)
	local y, side, zc = HL[o.lvl], o.side, o.z
	local X = roomFrame(b, side, y)
	local t = THEME[o.theme]
	U.blk(b, "Carpet", 34, 0.1, 71, X(17.5), y, zc, t.carpet, "Marble", { nc = true })
	U.blk(b, "Partition", 27, 11, 0.6, X(13.5), y, zc, t.accent, "SmoothPlastic")
	-- living room
	for i = -1, 1 do U.seat(b, X(7), y, zc - 20 + i * 3.4, side < 0 and -90 or 90, "Really black", 3) end
	U.blk(b, "SofaBack", 1, 2.6, 10.6, X(5.4), y + 0.5, zc - 20, "Really black", "Fabric")
	U.blk(b, "CoffeeTable", 3, 1.4, 5, X(12), y, zc - 20, "Brown", "Wood")
	U.blk(b, "TV", 0.3, 4, 7, X(20), y + 3, zc - 20, "Really black")
	U.blk(b, "TVScreen", 0.1, 3.4, 6.4, X(19.8), y + 3.3, zc - 20, "Cyan", "Neon")
	U.cyl(b, "DiningTable", 5, 3, X(24), y, zc - 30, "Institutional white", "Marble")
	for a = 0, 270, 90 do U.seat(b, X(24) + math.cos(math.rad(a)) * 3.6, y, zc - 30 + math.sin(math.rad(a)) * 3.6, -a - 90, t.accent, 1.6) end
	U.blk(b, "Minibar", 3, 3.4, 2, X(2), y, zc - 33, "Really black")
	-- bedroom
	bed(b, X, y, zc + 16, o.theme, 1.4)
	for _, dz in ipairs({ -6.2, 6.2 }) do U.blk(b, "Nightstand", 2, 2, 2, X(1.6), y, zc + 16 + dz, "Brown", "Wood") end
	U.cyl(b, "Jacuzzi", 8, 2, X(22), y, zc + 28, "Institutional white", "Marble")
	U.fx(U.cyl(b, "JacuzziWater", 7, 0.2, X(22), y + 1.9, zc + 28, "Cyan", "Neon", { tr = 0.3, nc = true }), "Sparkles")
	U.blk(b, "Wardrobe", 8, 9, 2.4, X(31), y, zc + 33.6, "Brown", "Wood")
	if EXTRA[o.theme] then EXTRA[o.theme](b, X, y, zc + 15) end
	local cx = side < 0 and 251 or 261
	local sign = U.blk(b, "SuiteName", 0.2, 1.2, 5, cx + side * -0.4, y + 7.6, zc - 12, "Gold", "Metal")
	U.text(sign, o.title, Color3.new(0, 0, 0), nil, side < 0 and "Right" or "Left")
	SPOT(b, "housekeeper", HOTEL.cx + side * 2, y, zc - 6, side < 0 and 90 or -90)
	PT(b, "hroom", { p = Vector3.new(X(14), y, zc + 8), door = Vector3.new(cx + side * 3, y, zc - 12), e = Vector3.new(HOTEL.cx, y, zc - 12),
		via = { b.cf * Vector3.new(X(20), y, zc - 12), b.cf * Vector3.new(X(31), y, zc) },
		lvl = o.lvl, n = o.n, rate = ITEM[o.key] and ITEM[o.key].eff.spend or 150, busy = false, suite = true })
end

-- the penthouse: the whole 5th floor. The base item is the master bedroom; the rest are bought one by one.
local PENT_EXTRAS = { "hpentliving", "hpenttub", "hpentbar", "hpentcinema", "hpentpiano", "hpentpool" }
function K.hpent(b)
	local H, y = HOTEL, HL[5]
	U.blk(b, "MarbleFloor", H.x1 - H.x0 - 1, 0.1, H.z1 - 137, H.cx, y, (137 + H.z1) / 2, "Institutional white", "Marble", { nc = true })
	for _, r in ipairs({ { H.x0, 240 }, { 272, H.x1 } }) do U.blk(b, "BedroomWall", r[2] - r[1], 11, 0.6, (r[1] + r[2]) / 2, y, 240, "Gold", "SmoothPlastic") end
	U.blk(b, "Bed", 12, 2, 10, H.cx, y, 271, "Institutional white", "Fabric")
	U.blk(b, "Blanket", 12.2, 0.3, 6, H.cx, y + 2, 268, "Really red", "Fabric")
	U.blk(b, "Headboard", 14, 6, 0.8, H.cx, y, 278.6, "Gold", "Metal", { refl = 0.3 })
	for _, x in ipairs({ H.cx - 8.6, H.cx + 8.6 }) do
		U.blk(b, "Nightstand", 3, 2.4, 3, x, y, 276, "Really black", "Marble")
		U.light(U.ball(b, "Lamp", 1.4, x, y + 3.2, 276, "Cool yellow", "Neon"), Color3.new(1, 0.9, 0.6), 12)
	end
	U.blk(b, "Bathtub", 6, 2.4, 12, 223, y, 260, "Institutional white", "Marble")
	U.blk(b, "Closet", 10, 10, 2, 290, y, 262, "Brown", "Wood")
	local ch = U.cyl(b, "Chandelier", 6, 0.6, H.cx, y + 10, 200, "Gold", "Metal", { refl = 0.4, nc = true })
	U.light(ch, Color3.new(1, 0.85, 0.5), 40)
	U.fx(ch, "Sparkles")
	local s = U.blk(b, "PenthouseSign", 10, 1.6, 0.3, H.cx, y + 7.2, 136.6, "Gold", "Metal")
	U.text(s, "THE PENTHOUSE", Color3.new(0, 0, 0), nil, "Front")
	PT(b, "hroom", { p = Vector3.new(H.cx - 3, y, 258), door = Vector3.new(H.cx, y, 140), e = Vector3.new(H.cx, y, 138),
		via = { b.cf * Vector3.new(H.cx, y, 236) }, lvl = 5, n = 500, rate = 400, busy = false, pent = true })
end
function K.hpentliving(b)
	local y = HL[5]
	U.blk(b, "Rug", 26, 0.1, 22, 276, y + 0.1, 160, "Royal purple", "Fabric", { nc = true })
	for i = -1, 1 do U.seat(b, 276 + i * 6, y, 152, 180, "Really black", 5) U.seat(b, 290, y, 160 + i * 5, -90, "Really black", 4) end
	U.blk(b, "CoffeeTable", 8, 1.4, 5, 276, y, 162, "Gold", "Metal", { refl = 0.3 })
	U.blk(b, "Fireplace", 10, 6, 2, 276, y, 172.6, "Reddish brown", "Brick")
	U.light(U.blk(b, "Fire", 6, 1.6, 0.6, 276, y + 1, 171.4, "Neon orange", "Neon"), Color3.new(1, 0.5, 0.2), 16)
	PT(b, "hpentx", { p = Vector3.new(268, y, 160), spend = 0 })
end
function K.hpenttub(b)
	local y = HL[5]
	U.cyl(b, "HotTub", 10, 2, 284, y, 214, "Institutional white", "Marble")
	U.fx(U.cyl(b, "Water", 9, 0.2, 284, y + 1.9, 214, "Cyan", "Neon", { tr = 0.3, nc = true }), "Sparkles")
	PT(b, "hpentx", { p = Vector3.new(284, y + 0.4, 214), spend = 0 })
end
function K.hpentbar(b)
	local y = HL[5]
	U.blk(b, "Bar", 3, 3.6, 18, 222, y, 210, "Really black", "Marble")
	U.blk(b, "BarTop", 3.4, 0.4, 18.4, 222, y + 3.6, 210, "Gold", "Metal", { refl = 0.3 })
	for i = -2, 2 do U.seat(b, 226, y + 1.4, 210 + i * 3.4, -90, "Really red", 1.4) end
	for i = 0, 5 do U.cyl(b, "Bottle", 0.5, 1.4, 217.5, y + 4, 203 + i * 2.6, U.pick({ "Lime green", "Gold", "Bright orange" }), "Glass") end
	PT(b, "hpentx", { p = Vector3.new(229, y, 210), spend = 0 })
end
function K.hpentcinema(b)
	local y = HL[5]
	U.blk(b, "Screen", 0.2, 8, 16, 217, y + 2, 160, "Institutional white", "Neon")
	for row = 0, 1 do for i = -2, 2 do U.seat(b, 228 + row * 5, y + row * 0.6, 160 + i * 3, 90, "Really red", 2.4) end end
	U.blk(b, "Popcorn", 2, 4, 2, 240, y, 148, "Bright red")
	PT(b, "hpentx", { p = Vector3.new(238, y, 160), spend = 0 })
end
function K.hpentpiano(b)
	local y = HL[5]
	U.blk(b, "Piano", 6, 2.4, 7, 268, y + 1.6, 194, "Really black", "SmoothPlastic", { refl = 0.3 })
	U.P(b, "Lid", Vector3.new(6, 0.2, 7), U.L(268, y + 5, 194.8, 0, 30), "Really black", "SmoothPlastic", { refl = 0.3 })
	for _, p in ipairs({ { -2.6, -2.6 }, { 2.6, -2.6 }, { 0, 3 } }) do U.blk(b, "Leg", 0.6, 1.6, 0.6, 268 + p[1], y, 194 + p[2], "Really black") end
	U.blk(b, "Bench", 4, 1.8, 1.6, 268, y, 188, "Really black", "Fabric")
	PT(b, "hpentx", { p = Vector3.new(262, y, 188), spend = 0 })
end
function K.hpentpool(b)
	local y = HL[5]
	U.blk(b, "PoolTable", 4.4, 0.6, 8, 246, y + 2.6, 228, "Dark green", "Fabric")
	U.blk(b, "Rim", 4.8, 0.4, 8.4, 246, y + 2.4, 228, "Reddish brown", "Wood")
	U.blk(b, "Legs", 3.6, 2.4, 7, 246, y, 228, "Reddish brown", "Wood")
	for i = 1, 4 do U.ball(b, "Ball", 0.5, 246 + math.random(-1, 1), y + 3.4, 228 + math.random(-3, 3), U.pick({ "Bright red", "Bright yellow", "Really black" })) end
	PT(b, "hpentx", { p = Vector3.new(251, y, 228), spend = 0 })
end

------------------------------------------------------------------ floor 6: spa, sauna, ballroom, conference room
local function amenity(b, side, zc, spend, d)
	local y = HL[6]
	local cx = side < 0 and 251 or 261
	local X = roomFrame(b, side, y)
	PT(b, "hamen", { p = Vector3.new(X(d or 16), y, zc + math.random(-3, 3)), door = Vector3.new(cx + side * 3, y, zc), e = Vector3.new(HOTEL.cx, y, zc), spend = spend })
	return X, y
end
function K.hspa(b)
	local X, y = amenity(b, -1, 172, ITEM.hspa.eff.spend)
	U.blk(b, "Floor", 34, 0.1, 71, X(17.5), y, 172, "Institutional white", "Marble", { nc = true })
	for _, z in ipairs({ 148, 160, 184, 196 }) do
		U.blk(b, "MassageBed", 6, 2.4, 3, X(6), y, z, "Institutional white", "Fabric")
		U.blk(b, "Towel", 3, 0.2, 3.1, X(5), y + 2.4, z, "Teal", "Fabric")
		U.light(U.cyl(b, "Candle", 0.4, 0.8, X(10), y, z + 2, "Cool yellow", "Neon"), Color3.new(1, 0.7, 0.4), 6, 0.5)
	end
	for _, z in ipairs({ 140, 204 }) do U.cyl(b, "Pot", 2.4, 2, X(28), y, z, "Reddish brown") U.ball(b, "Plant", 3.4, X(28), y + 3.4, z, "Dark green", "Grass") end
	local s = U.blk(b, "Sign", 0.2, 1.6, 6, 251.4, y + 8, 168, "Teal")
	U.text(s, "SPA", Color3.new(1, 1, 1), nil, "Right")
end
function K.hsauna(b)
	local X, y = amenity(b, -1, 244, ITEM.hsauna.eff.spend)
	U.blk(b, "WoodFloor", 34, 0.1, 71, X(17.5), y, 244, "Brown", "WoodPlanks", { nc = true })
	for lvl = 0, 2 do U.blk(b, "Bench", 4, 1.2, 28, X(2 + lvl * 4), y + lvl * 1.2, 230, "Reddish brown", "Wood") end
	U.blk(b, "Heater", 3, 3, 3, X(4), y, 258, "Dark stone grey", "Slate")
	U.fx(U.blk(b, "Stones", 2.6, 0.6, 2.6, X(4), y + 3, 258, "Neon orange", "Neon"), "Sparkles")
	U.blk(b, "SteamRoom", 14, 10, 0.4, X(9), y, 262, "Pastel light blue", "Glass", { tr = 0.5 })
	local s = U.blk(b, "Sign", 0.2, 1.6, 8, 251.4, y + 8, 239, "Reddish brown")
	U.text(s, "SAUNA", Color3.new(1, 1, 1), nil, "Right")
end
function K.hballroom(b)
	local X, y = amenity(b, 1, 190, ITEM.hballroom.eff.spend)
	U.blk(b, "DanceFloor", 20, 0.15, 30, X(17), y, 190, "Brown", "WoodPlanks", { nc = true })
	U.blk(b, "Stage", 10, 1.4, 20, X(4), y, 190, "Really black", "Wood")
	for _, z in ipairs({ 152, 228 }) do
		U.cyl(b, "RoundTable", 6, 3, X(17), y, z, "Institutional white", "Fabric")
		for a = 0, 300, 60 do U.seat(b, X(17) + math.cos(math.rad(a)) * 4.4, y, z + math.sin(math.rad(a)) * 4.4, -a - 90, "Gold", 1.6) end
	end
	for _, z in ipairs({ 160, 190, 220 }) do
		local ch = U.cyl(b, "Chandelier", 5, 0.6, X(17), y + 10, z, "Gold", "Metal", { refl = 0.4, nc = true })
		U.light(ch, Color3.new(1, 0.85, 0.5), 24)
	end
	local s = U.blk(b, "Sign", 0.2, 1.6, 8, 260.6, y + 8, 185, "Gold")
	U.text(s, "BALLROOM", Color3.new(0, 0, 0), nil, "Left")
end
function K.hconference(b)
	local X, y = amenity(b, 1, 262, ITEM.hconference.eff.spend, 30)
	U.blk(b, "Table", 6, 3, 24, X(15), y, 262, "Brown", "Wood")
	for i = -3, 3 do
		U.seat(b, X(10), y, 262 + i * 3.2, 90, "Really black", 1.6)
		U.seat(b, X(20), y, 262 + i * 3.2, -90, "Really black", 1.6)
	end
	U.blk(b, "Screen", 0.2, 6, 12, X(1), y + 3, 262, "Cyan", "Neon")
	local s = U.blk(b, "Sign", 0.2, 1.6, 10, 260.6, y + 8, 256, "Navy blue")
	U.text(s, "CONFERENCE", Color3.new(1, 1, 1), nil, "Left")
end

function K.hroof(b)
	local H, y = HOTEL, HOTEL.roof
	U.slab(b, "Roof", H.x0 - 1, H.x1 + 1, H.z0 - 1, H.z1 + 1, y, 1, HHOLE, "Dark stone grey", "Concrete")
	for _, z in ipairs({ H.z0 - 0.5, H.z1 + 0.5 }) do U.blk(b, "Parapet", H.x1 - H.x0 + 2, 2.4, 1, H.cx, y, z, b.plot.color, "SmoothPlastic") end
	for _, x in ipairs({ H.x0 - 0.5, H.x1 + 0.5 }) do U.blk(b, "Parapet", 1, 2.4, H.z1 - H.z0 + 2, x, y, (H.z0 + H.z1) / 2, b.plot.color, "SmoothPlastic") end
	local s = U.blk(b, "BigSign", 60, 10, 1, H.cx, y + 2.4, H.z0 + 0.5, "Really black", "SmoothPlastic")
	U.text(s, "HOTEL", Color3.new(1, 0.85, 0.3), Color3.new(0.05, 0.05, 0.12), "Front")
	U.light(s, Color3.new(1, 0.85, 0.4), 50, 2)
	U.cyl(b, "WaterTank", 8, 8, 285, y, 270, "Brown", "Wood")
	-- elevator machine room on the roof (open to the back, where the door is)
	U.blk(b, "LiftRoom", 9.8, 11, 0.6, H.cx, y, H.liftZ - 4.6, "Light stone grey", "Concrete")
	for _, dx in ipairs({ -4.6, 4.6 }) do U.blk(b, "LiftRoom", 0.6, 11, 9.8, H.cx + dx, y, H.liftZ, "Light stone grey", "Concrete") end
	U.blk(b, "LiftRoof", 10.4, 0.6, 10.4, H.cx, y + 11, H.liftZ, b.plot.color, "SmoothPlastic")
	U.liftDoor(b, "H", 7)
end

function K.hrooftop(b)
	local y = HOTEL.roof
	U.blk(b, "Deck", 60, 0.3, 90, HOTEL.cx, y, 215, "Brown", "Wood")
	U.blk(b, "Bar", 20, 3.6, 3, 256, y + 0.3, 250, "Really black", "SmoothPlastic")
	U.blk(b, "BarTop", 20.4, 0.4, 3.4, 256, y + 3.9, 250, "Gold", "Metal", { refl = 0.3 })
	for i = -3, 3 do U.seat(b, 256 + i * 2.8, y + 1.5, 246.6, 180, "Bright red", 1.4) end
	for _, p in ipairs({ { 232, 190 }, { 280, 190 }, { 232, 220 }, { 280, 220 } }) do
		U.cyl(b, "Table", 4, 3, p[1], y + 0.3, p[2], "Institutional white")
		U.cyl(b, "UmbrellaPole", 0.3, 7, p[1], y + 3.3, p[2], "Institutional white")
		U.cyl(b, "Umbrella", 8, 0.4, p[1], y + 10, p[2], U.pick({ "Bright red", "Bright yellow", "Cyan" }), "Fabric")
	end
	U.fx(U.blk(b, "PoolGlow", 16, 0.2, 10, 256, y + 0.3, 170, "Cyan", "Neon", { tr = 0.4, nc = true }), "Sparkles")
	PT(b, "hroof", { p = Vector3.new(256, y + 0.3, 242), spend = ITEM.hrooftop.eff.spend })
	PT(b, "hroof", { p = Vector3.new(240, y + 0.3, 205), spend = 0 })
end

------------------------------------------------------------------ outside: garden, fountain, valet parking
function K.hgarden(b)
	for _, p in ipairs({ { 222, 64, 10, 10 }, { 222, 108, 10, 10 }, { 250, 64, 18, 6 }, { 250, 112, 18, 6 } }) do
		U.blk(b, "Bed", p[3], 0.8, p[4], p[1], 0, p[2], "Reddish brown", "Grass")
		for i = 1, 3 do U.ball(b, "Flowers", 2, p[1] + math.random(-3, 3), 1.4, p[2] + math.random(-2, 2), U.pick({ "Hot pink", "Bright yellow", "Bright red", "Royal purple" }), "Grass") end
	end
	for _, p in ipairs({ { 222, 86 } }) do
		U.cyl(b, "Trunk", 1.4, 8, p[1], 0, p[2], "Brown", "Wood")
		U.ball(b, "Leaves", 9, p[1], 11, p[2], "Dark green", "Grass")
	end
	U.blk(b, "Hedge", 2, 3, 50, 213, 0, 88, "Dark green", "Grass")
end
function K.hfountain(b)
	U.cyl(b, "Basin", 12, 1.6, 256, 0, 90, "Light stone grey", "Marble")
	U.cyl(b, "Water", 11, 0.2, 256, 1.5, 90, "Cyan", "Neon", { tr = 0.4, nc = true })
	U.cyl(b, "Pillar", 1.6, 5, 256, 1.6, 90, "Light stone grey", "Marble")
	local top = U.cyl(b, "Top", 4, 0.6, 256, 6.6, 90, "Gold", "Metal")
	U.fx(top, "Sparkles")
	U.light(top, Color3.new(0.5, 0.9, 1), 18)
end
function K.hvalet(b)
	U.blk(b, "Lot", 28, 0.3, 52, 283, 0, 88, "Dark stone grey", "Concrete")
	local cols = { "Really black", "Institutional white", "Gold", "Bright red" }
	for i = 0, 3 do car(b, 283, 68 + i * 13, 90, cols[i + 1]) end
	U.blk(b, "ValetStand", 3, 4, 2, 268, 0, 116, b.plot.color, "SmoothPlastic")
	local s = U.blk(b, "Sign", 4, 1.4, 0.2, 268, 4, 114.9, "Really black")
	U.text(s, "VALET", Color3.new(1, 0.85, 0.3), nil, "Front")
	PT(b, "hstart", { p = Vector3.new(270, 0.5, 70) })
end

------------------------------------------------------------------ pool area (behind the hotel)
function K.hpool(b)
	U.blk(b, "Deck", 80, 0.4, 155, 256, 0, 367, "Light stone grey", "Concrete")
	U.blk(b, "PoolRim", 56, 1, 60, 256, 0.3, 328, "Institutional white", "Marble")
	U.blk(b, "Water", 52, 0.3, 56, 256, 0.95, 328, "Cyan", "Glass", { tr = 0.3, nc = true })
	U.blk(b, "PoolFloor", 52, 0.2, 56, 256, 0.35, 328, "Bright blue", "SmoothPlastic", { nc = true })
	U.blk(b, "Lane", 0.4, 0.05, 50, 256, 0.6, 328, "Institutional white", nil, { nc = true })
	U.blk(b, "Ladder", 2, 3, 0.3, 240, 0.4, 299.6, "Light stone grey", "Metal")
	U.blk(b, "Path", 8, 0.45, 12, 256, 0, 286, "Light stone grey", "Concrete")
	for _, p in ipairs({ { 244, 318 }, { 268, 318 }, { 256, 340 }, { 244, 338 }, { 268, 336 } }) do PT(b, "hpool", { p = Vector3.new(p[1], 0.4, p[2]), spend = ITEM.hpool.eff.spend, swim = true }) end
end
function K.hloungers(b)
	for _, x in ipairs({ 222, 290 }) do
		for i = 0, 3 do
			local z = 310 + i * 13
			U.blk(b, "Lounger", 3, 1.2, 7, x, 0.4, z, "Institutional white", "Fabric")
			U.P(b, "LoungerBack", Vector3.new(3, 0.6, 3), U.L(x, 2.2, z + 3.4, 0, 35), "Institutional white", "Fabric")
			U.blk(b, "Towel", 2.6, 0.1, 4, x, 1.6, z - 0.5, U.pick({ "Bright red", "Bright blue", "Bright yellow", "Hot pink" }), "Fabric", { nc = true })
		end
		PT(b, "hpool", { p = Vector3.new(x + (x < 256 and 3 or -3), 0.4, 316), spend = 0 })
	end
end
function K.humbrellas(b)
	for _, x in ipairs({ 222, 290 }) do
		for i = 0, 2 do
			local z = 316.5 + i * 13
			U.cyl(b, "Pole", 0.3, 7, x, 0.4, z, "Institutional white")
			U.cyl(b, "Umbrella", 7, 0.4, x, 7.4, z, U.pick({ "Bright red", "Bright yellow", "Cyan", "Lime green" }), "Fabric")
		end
	end
end
function K.hpoolbar(b)
	U.cyl(b, "Bar", 12, 3.6, 256, 0.4, 378, "Brown", "Wood")
	U.cyl(b, "BarTop", 12.6, 0.4, 256, 4, 378, "Bright yellow", "SmoothPlastic")
	for _, dx in ipairs({ -4, 4 }) do U.cyl(b, "Post", 0.6, 8, 256 + dx, 4.4, 378, "Brown", "Wood") end
	U.P(b, "Thatch", Vector3.new(16, 3, 8), U.L(256, 13.9, 374), "Brick yellow", "Grass", { class = "WedgePart" })
	U.P(b, "Thatch", Vector3.new(16, 3, 8), U.L(256, 13.9, 382, 180), "Brick yellow", "Grass", { class = "WedgePart" })
	for a = 0, 330, 45 do U.seat(b, 256 + math.cos(math.rad(a)) * 8, 1.4, 378 + math.sin(math.rad(a)) * 8, -a - 90, "Bright red", 1.4) end
	SPOT(b, "chef", 256, 0.4, 378, 0)
	PT(b, "hpool", { p = Vector3.new(256, 0.4, 368), spend = ITEM.hpoolbar.eff.spend })
end
function K.hslide(b)
	U.blk(b, "Tower", 6, 14, 6, 290, 0.4, 300, "Bright yellow", "SmoothPlastic")
	U.blk(b, "Platform", 7, 0.6, 7, 290, 14.4, 300, "Bright red", "SmoothPlastic")
	local a, c = Vector3.new(290, 15, 304), Vector3.new(272, 2, 318)
	U.P(b, "Slide", Vector3.new(3, 0.6, (c - a).magnitude), CFrame.new((a + c) / 2, c), "Bright blue", "SmoothPlastic")
	U.P(b, "SlideRail", Vector3.new(0.4, 1.2, (c - a).magnitude), CFrame.new((a + c) / 2 + Vector3.new(1.4, 0.6, 0), c + Vector3.new(1.4, 0.6, 0)), "Bright red", "SmoothPlastic")
	U.blk(b, "Ladder", 2, 14, 0.4, 290, 0.4, 296.8, "Light stone grey", "Metal")
end
function K.hhottub(b)
	U.cyl(b, "Tub", 12, 1.6, 228, 0.4, 386, "Brown", "Wood")
	local w = U.cyl(b, "HotWater", 10.6, 0.2, 228, 1.9, 386, "Cyan", "Neon", { tr = 0.3, nc = true })
	U.fx(w, "Sparkles")
	PT(b, "hpool", { p = Vector3.new(228, 0.6, 386), spend = 0, swim = true })
end
function K.htennis(b)
	U.blk(b, "Court", 68, 0.3, 38, 256, 0.4, 421, "Bright green", "SmoothPlastic")
	U.blk(b, "Inner", 56, 0.05, 28, 256, 0.7, 421, "Bright blue", "SmoothPlastic", { nc = true })
	U.blk(b, "Line", 56, 0.06, 0.3, 256, 0.7, 421, "Institutional white", nil, { nc = true })
	U.blk(b, "Net", 0.2, 3, 30, 256, 0.7, 421, "Institutional white", "Fabric")
	for _, z in ipairs({ 401.5, 440.5 }) do U.blk(b, "Fence", 68, 8, 0.2, 256, 0.7, z, "Dark stone grey", "DiamondPlate", { tr = 0.5 }) end
	U.ball(b, "TennisBall", 0.4, 262, 1.2, 416, "New Yeller")
end

------------------------------------------------------------------ hotel guests: check in, take the elevator, stay the night, maybe swim, check out
function NPC.guest(plot)
	local pts = plot.pts
	local L = plot.lifts and plot.lifts.H
	local rooms = {}
	for _, r in ipairs(pts.hroom or {}) do if not r.busy then table.insert(rooms, r) end end
	if #rooms == 0 or not pts.hdesk or not L then return false end
	local room = U.pick(rooms)
	room.busy = true
	local function W(x, y, z) return plot.cf * Vector3.new(x, y, z) end
	local route = {}
	local function go(v, wait, act, extra)
		local t = { p = v, wait = wait, act = act }
		if extra then for k, x in pairs(extra) do t[k] = x end end
		table.insert(route, t)
	end
	local H = HOTEL
	local start = W(H.doorX + math.random(-3, 3), 0.5, 50)
	if pts.hstart and math.random() < 0.5 then start = pts.hstart[1].p end
	go(start)
	go(W(H.doorX, 0.5, 112))
	go(W(H.doorX, HL[1], H.z0 + 2))
	local desk = pts.hdesk[1]
	local recep = plot.staff.receptionist or 0
	go(desk.q, math.max(0.8, 3 / (1 + recep * 0.5)), function(w) A.pay(plot, 6, w.model) end)
	local level = 1
	local function rideTo(j)
		LIFT.route(go, plot, L, level, j)
		level = j
	end
	-- a room on another floor's corridor: in through the door (and the suite's rooms), out the same way
	local function visitRoom(r, wait, act)
		go(r.e)
		go(r.door)
		for _, v in ipairs(r.via or {}) do go(v) end
		go(r.p, wait, act)
		for k = #(r.via or {}), 1, -1 do go(r.via[k]) end
		go(r.door)
		go(r.e)
	end
	rideTo(room.lvl)
	local stay = room.pent and 30 or (room.suite and 26 or 18)
	-- penthouse guests use the penthouse's extras first
	if room.pent and pts.hpentx and #pts.hpentx > 0 then
		go(W(H.cx, HL[5], 150))
		for _ = 1, math.min(2, #pts.hpentx) do go(U.pick(pts.hpentx).p, 4) end
	end
	visitRoom(room, stay + math.random() * 12, function(w) w.inRoom = true end)
	route[#route].act = function(w)
		w.inRoom = false
		room.busy = false
		local rate = room.rate
		if room.pent then for _, k in ipairs(PENT_EXTRAS) do if plot.bought[k] then rate = rate + (ITEM[k].eff.spend or 0) end end end
		A.pay(plot, rate * (1 + 0.1 * (plot.staff.housekeeper or 0)), w.model)
	end
	-- the spa, sauna, ballroom or conference room on floor 6?
	if pts.hamen and #pts.hamen > 0 and math.random() < 0.45 then
		rideTo(6)
		local a = U.pick(pts.hamen)
		visitRoom(a, 5, function(w) A.pay(plot, a.spend or 0, w.model) end)
	end
	-- the rooftop bar?
	if pts.hroof and #pts.hroof > 0 and math.random() < 0.35 then
		rideTo(7)
		local s = U.pick(pts.hroof)
		go(s.p, 4, function(w) if s.spend > 0 then A.pay(plot, s.spend, w.model) end end)
		go(W(H.cx, H.roof, H.liftZ + 9))
	end
	rideTo(1)
	-- restaurant, gift shop or gym
	if pts.hlobby and #pts.hlobby > 0 and math.random() < 0.5 then
		local s = U.pick(pts.hlobby)
		go(s.p, 3, function(w) if s.spend > 0 then A.pay(plot, s.spend, w.model) end end)
	end
	-- a swim?
	if pts.hpool and #pts.hpool > 0 and math.random() < 0.55 then
		go(W(H.cx, HL[1], H.z1 - 4))
		go(W(H.cx, HL[1], H.z1 + 2))
		go(W(H.cx, 0.4, 292))
		local s = U.pick(pts.hpool)
		go(s.p, 6, function(w) if s.spend > 0 then A.pay(plot, s.spend, w.model) end end)
		go(W(H.cx, 0.4, 292))
		go(W(H.cx, HL[1], H.z1 + 2))
		go(W(H.cx, HL[1], H.z1 - 4))
	end
	go(W(H.cx - 4, HL[1], 140))   -- round the reception desk
	go(W(H.doorX, HL[1], H.z0 + 2))
	go(W(H.doorX, 0.5, 112))
	go(W(H.doorX + math.random(-3, 3), 0.5, 50))
	local look = M.passengerLook()
	look.bag = U.pick({ "Bright red", "Really black", "Gold", "Royal purple" })
	if room.pent then look.shirt, look.pants, look.tie, look.arms = "Really black", "Really black", "Gold", nil end
	local model, root = M.person(plot.Guests, CFrame.new(route[1].p), look, room.pent and "VIP Guest" or "Hotel Guest")
	if room.pent then
		local head = model:FindFirstChild("Head")
		if head then U.bill(head, "VIP", 3, 1, 2.2, Color3.new(1, 0.85, 0.2)) end
	end
	U.rig(model, root, false)
	local w = NPC.walk(plot, model, root, route, CONST.walkSpeed + math.random() * 2, function(w)
		room.busy = false
		NPC.review(plot, true)
	end)
	w.kind = "guest"
	w.room = room
	return true
end
