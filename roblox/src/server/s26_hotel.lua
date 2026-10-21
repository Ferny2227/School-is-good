-- ==== s26_hotel.lua
------------------------------------------------------------------ the hotel (right of the terminal, on the new land)
-- Building x 216..296, z 120..280. Lobby floor top HL[1] = 1, rooms on floors 2..5 (HL[2..5]), roof at HOTEL.roof.
-- Each upper floor: a corridor down the middle (x 251..261), 4 rooms each side, the elevator at the front.
local HLIFT = { levels = { HL[1], HL[2], HL[3], HL[4], HL[5], HOTEL.roof }, keys = { "helevator", "hfloor2", "hfloor3", "hfloor4", "hfloor5", "hroof" } }
local ROOM_Z = { 154, 190, 226, 262 }

local function hotelLift(b, level)
	local H = HOTEL
	local top = HLIFT.levels[level + 1]
	if top then U.shaft(b, H.cx, H.liftZ, HLIFT.levels[level], top - 1 - HLIFT.levels[level], "+z", "Gold") end
	U.liftPads(b, H.cx, H.liftZ, HLIFT.levels, HLIFT.keys, level, 0, 8)
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
function K.helevator(b)
	hotelLift(b, 1)
	local s = U.blk(b, "LiftSign", 6, 1.4, 0.3, HOTEL.cx, HL[1] + 9.6, HOTEL.liftZ + 4.4, "Really black", "SmoothPlastic")
	U.text(s, "ROOMS", Color3.new(1, 0.85, 0.3), nil, "Back")
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

function K.hfloor(b, o)
	local H = HOTEL
	local y = HL[o.lvl]
	U.blk(b, "Slab", H.x1 - H.x0 + 1.6, 1, H.z1 - H.z0 + 1.6, H.cx, y - 1, (H.z0 + H.z1) / 2, "Light stone grey", "Concrete")
	storey(b, y, nil, nil, "Institutional white")
	U.blk(b, "Corridor", 10, 0.1, H.z1 - H.z0 - 2, H.cx, y, (H.z0 + H.z1) / 2, "Bright red", "Fabric", { nc = true })
	-- corridor walls with a door to every room
	for _, x in ipairs({ 251, 261 }) do
		local cuts = { 136 }
		for _, zc in ipairs(ROOM_Z) do table.insert(cuts, zc - 2.5) table.insert(cuts, zc + 2.5) end
		table.insert(cuts, H.z1)
		for i = 1, #cuts, 2 do U.blk(b, "CorridorWall", 0.6, 11, cuts[i + 1] - cuts[i], x, y, (cuts[i] + cuts[i + 1]) / 2, "Brick yellow", "SmoothPlastic") end
	end
	-- walls between the rooms
	for _, z in ipairs({ 136, 172, 208, 244 }) do
		U.blk(b, "RoomWall", 35, 11, 0.6, (H.x0 + 251) / 2, y, z, "Brick yellow", "SmoothPlastic")
		U.blk(b, "RoomWall", 35, 11, 0.6, (261 + H.x1) / 2, y, z, "Brick yellow", "SmoothPlastic")
	end
	local s = U.blk(b, "FloorSign", 8, 1.6, 0.3, H.cx, y + 8, 135.5, "Really black")
	U.text(s, "FLOOR " .. o.lvl, Color3.new(1, 0.85, 0.3), nil, "Back")
	U.light(U.blk(b, "CorridorLight", 3, 0.3, 120, H.cx, y + 10.6, 210, "Institutional white", "Neon", { nc = true }), Color3.new(1, 0.95, 0.85), 30, 0.8)
	hotelLift(b, o.lvl)
end

function K.hroom(b, o)
	local y, side, zc = HL[o.lvl], o.side, o.z
	local wx = side < 0 and HOTEL.x0 or HOTEL.x1   -- the outside wall
	local function X(d) return wx - side * d end    -- d studs in from the outside wall
	U.blk(b, "Carpet", 34, 0.1, 35, X(17.5), y, zc, U.pick({ "Sand blue", "Brick yellow", "Pastel brown", "Sand green" }), "Fabric", { nc = true })
	-- bed against the outside wall
	U.blk(b, "Bed", 8, 1.6, 6.4, X(5), y, zc, "Institutional white", "Fabric")
	U.blk(b, "Blanket", 5, 0.3, 6.6, X(6.4), y + 1.6, zc, U.pick({ "Bright blue", "Bright red", "Royal purple", "Teal" }), "Fabric")
	U.blk(b, "Pillow", 1.6, 0.6, 2.4, X(2), y + 1.6, zc - 1.6, "Institutional white", "Fabric")
	U.blk(b, "Pillow", 1.6, 0.6, 2.4, X(2), y + 1.6, zc + 1.6, "Institutional white", "Fabric")
	U.blk(b, "Headboard", 0.6, 4, 7, X(1), y, zc, "Brown", "Wood")
	for _, dz in ipairs({ -4.6, 4.6 }) do
		U.blk(b, "Nightstand", 2, 2, 2, X(1.6), y, zc + dz, "Brown", "Wood")
		U.light(U.ball(b, "Lamp", 1, X(1.6), y + 2.6, zc + dz, "Cool yellow", "Neon"), Color3.new(1, 0.9, 0.6), 10, 0.8)
	end
	-- TV on the far wall, a desk, and a bathroom by the door
	U.blk(b, "TV", 5, 3, 0.3, X(17), y + 4, zc + 17.3, "Really black")
	U.blk(b, "TVScreen", 4.6, 2.6, 0.1, X(17), y + 4.2, zc + 17.1, "Cyan", "Neon")
	U.blk(b, "Desk", 4, 2.8, 2, X(17), y, zc - 16.4, "Brown", "Wood")
	U.seat(b, X(17), y, zc - 14.4, 180, "Really black", 1.6)
	U.blk(b, "Bathroom", 9, 10, 0.4, X(30.5), y, zc + 8, "Institutional white", "SmoothPlastic")
	U.blk(b, "Bathroom", 0.4, 10, 9.6, X(26), y, zc + 12.8, "Institutional white", "SmoothPlastic")
	U.blk(b, "Tub", 4, 2, 8, X(31.5), y, zc + 13, "Institutional white", "Marble")
	-- room number by the door, on the corridor side
	local cx = side < 0 and 251 or 261
	local sign = U.blk(b, "RoomNumber", 0.2, 1, 2, cx + side * -0.4, y + 7, zc + 4, "Gold", "Metal")
	U.text(sign, tostring(o.n), Color3.new(0, 0, 0), nil, side < 0 and "Right" or "Left")
	SPOT(b, "housekeeper", HOTEL.cx + side * 2, y, zc + 6, side < 0 and 90 or -90)
	PT(b, "hroom", { p = Vector3.new(X(12), y, zc - 4.6), door = Vector3.new(cx + side * 3, y, zc), e = Vector3.new(HOTEL.cx, y, zc),
		lvl = o.lvl, n = o.n, rate = ITEM[o.key] and ITEM[o.key].eff.spend or 40, busy = false })
end

function K.hroof(b)
	local H, y = HOTEL, HOTEL.roof
	U.blk(b, "Roof", H.x1 - H.x0 + 2, 1, H.z1 - H.z0 + 2, H.cx, y - 1, (H.z0 + H.z1) / 2, "Dark stone grey", "Concrete")
	for _, z in ipairs({ H.z0 - 0.5, H.z1 + 0.5 }) do U.blk(b, "Parapet", H.x1 - H.x0 + 2, 2.4, 1, H.cx, y, z, b.plot.color, "SmoothPlastic") end
	for _, x in ipairs({ H.x0 - 0.5, H.x1 + 0.5 }) do U.blk(b, "Parapet", 1, 2.4, H.z1 - H.z0 + 2, x, y, (H.z0 + H.z1) / 2, b.plot.color, "SmoothPlastic") end
	local s = U.blk(b, "BigSign", 60, 10, 1, H.cx, y + 2.4, H.z0 + 4, "Really black", "SmoothPlastic")
	U.text(s, "HOTEL", Color3.new(1, 0.85, 0.3), Color3.new(0.05, 0.05, 0.12), "Front")
	U.light(s, Color3.new(1, 0.85, 0.4), 50, 2)
	for _, x in ipairs({ H.cx - 25, H.cx + 25 }) do U.blk(b, "SignPost", 1, 4, 1, x, y, H.z0 + 4, "Dark stone grey", "Metal") end
	U.cyl(b, "WaterTank", 8, 8, 285, y, 265, "Brown", "Wood")
	-- elevator room on the roof
	U.blk(b, "LiftRoom", 9, 9, 0.6, H.cx, y, H.liftZ - 4.3, "Light stone grey", "Concrete")
	for _, dx in ipairs({ -4.3, 4.3 }) do U.blk(b, "LiftRoom", 0.6, 9, 9, H.cx + dx, y, H.liftZ, "Light stone grey", "Concrete") end
	U.blk(b, "LiftRoof", 9.6, 0.6, 9.6, H.cx, y + 9, H.liftZ, b.plot.color, "SmoothPlastic")
	U.liftPads(b, H.cx, H.liftZ, HLIFT.levels, HLIFT.keys, 6, 0, 8)
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

------------------------------------------------------------------ hotel guests: check in, ride up, stay the night, maybe swim, check out
function NPC.guest(plot)
	local pts = plot.pts
	local rooms = {}
	for _, r in ipairs(pts.hroom or {}) do if not r.busy then table.insert(rooms, r) end end
	if #rooms == 0 or not pts.hdesk then return false end
	local room = U.pick(rooms)
	room.busy = true
	local function W(x, y, z) return plot.cf * Vector3.new(x, y, z) end
	local route = {}
	local function go(v, wait, act) table.insert(route, { p = v, wait = wait, act = act }) end
	local H = HOTEL
	local start = W(H.doorX + math.random(-3, 3), 0.5, 50)
	if pts.hstart and math.random() < 0.5 then start = pts.hstart[1].p end
	go(start)
	go(W(H.doorX, 0.5, 112))
	go(W(H.doorX, HL[1], H.z0 + 2))
	local desk = pts.hdesk[1]
	local recep = plot.staff.receptionist or 0
	go(desk.q, math.max(0.8, 3 / (1 + recep * 0.5)), function(w) A.pay(plot, 6, w.model) end)
	local function ride(fromY, toY)
		go(W(H.cx, fromY, H.liftZ + 9))
		go(W(H.cx, fromY, H.liftZ), 0.4)
		go(W(H.cx, toY, H.liftZ), 0.3)
		go(W(H.cx, toY, H.liftZ + 9))
	end
	local y = HL[room.lvl]
	ride(HL[1], y)
	go(room.e)
	go(room.door)
	go(room.p, 18 + math.random() * 14, function(w) w.inRoom = true end)
	go(room.door, 0, function(w)
		w.inRoom = false
		room.busy = false
		A.pay(plot, room.rate * (1 + 0.1 * (plot.staff.housekeeper or 0)), w.model)
	end)
	go(room.e)
	-- the rooftop bar on the way down?
	if pts.hroof and #pts.hroof > 0 and math.random() < 0.35 then
		go(W(H.cx, y, H.liftZ + 9))
		go(W(H.cx, y, H.liftZ), 0.3)
		go(W(H.cx, H.roof, H.liftZ), 0.3)
		go(W(H.cx, H.roof, H.liftZ + 9))
		local s = U.pick(pts.hroof)
		go(s.p, 4, function(w) if s.spend > 0 then A.pay(plot, s.spend, w.model) end end)
		go(W(H.cx, H.roof, H.liftZ + 9))
		y = H.roof
	end
	ride(y, HL[1])
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
	local model, root = M.person(plot.Guests, CFrame.new(route[1].p), look, "Hotel Guest")
	U.rig(model, root, false)
	local w = NPC.walk(plot, model, root, route, CONST.walkSpeed + math.random() * 2, function(w)
		room.busy = false
		NPC.review(plot, true)
	end)
	w.kind = "guest"
	w.room = room
	return true
end
