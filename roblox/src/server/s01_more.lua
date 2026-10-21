-- ==== s01_more.lua
------------------------------------------------------------------ the bigger airport
-- More land (600 x 900 studs instead of 420 x 620), a 2nd and 3rd floor on the terminal full of shops and
-- things to do, a hotel guests really stay in, and an expansion zone with remote stands, cargo jets and a
-- second runway where planes take off and land on their own.
local PLOT_W, PLOT_D = 600, 900
-- floor tops in plot space: LV[1] terminal ground floor, LV[2] 2nd floor, LV[3] 3rd floor; the roof is on top
local LV = { [0] = 0, 1, 32, 48 }
local LV_ROOF = 64
-- hotel: floor tops (lobby, then floors 2..5), the building's footprint, and its elevator
local HL = { 1, 13, 25, 37, 49 }
local HOTEL = { x0 = 216, x1 = 296, z0 = 120, z1 = 280, cx = 256, roof = 61, liftZ = 128, doorX = 236 }
-- terminal elevators (one each side of the central aisle)
local LIFT_Z = 198

-- upper-floor layout. Slots against the walls hold shops/rooms ("booths"), islands in between hold
-- smaller things. Walkers cross the floor along the slot rows, so islands sit between the rows.
local SLOT = {}
do
	local zs = { 90, 120, 150, 180, 210, 240, 270, 300 }
	for i, z in ipairs(zs) do
		SLOT["L" .. i] = { x = -131, z = z, face = "x", px = -120, pz = z }
		SLOT["R" .. i] = { x = 131, z = z, face = "-x", px = 120, pz = z }
	end
	for i, x in ipairs({ -110, -80, -50, 50, 80, 110 }) do
		SLOT["F" .. i] = { x = x, z = 69, face = "+z", px = x, pz = 81 }
		SLOT["B" .. i] = { x = x, z = 311, face = "-z", px = x, pz = 299 }
	end
end

do
	local function add(t)
		t.deps = t.deps or {}
		t.at = t.at or {}
		t.eff = t.eff or {}
		t.floor = t.floor or 0
		t.at.key = t.key
		table.insert(CATALOG, t)
		return t
	end

	-- the old hotel block becomes a real hotel on the new land to the right
	for _, it in ipairs(CATALOG) do
		if it.key == "hotel" then it.pad = { 236, 104 } it.eff.cnt = { hotel = 1 } end
		if it.key == "intl" then table.insert(it.deps, "f3roof") end
		if it.key == "fireworks" then it.deps = { "f3roof" } end
	end

	---------------------------------------------------------------- 9. second floor: the sky mall
	add({ key = "elevators", name = "Terminal Elevators", price = 30000, deps = { "lane1", "walls" }, kind = "elevators", pad = { 0, 186 }, floor = 1, phase = 9,
		eff = { cat = { comfort = 0.03 } } })
	add({ key = "f2floor", name = "2nd Floor", price = 90000, deps = { "elevators" }, kind = "upfloor", at = { fl = 2 }, pad = { -12, 176 }, floor = 1, phase = 9,
		eff = { cnt = { level = 1 }, cat = { comfort = 0.05 } } })
	add({ key = "f2walls", name = "2nd Floor Walls", price = 45000, deps = { "f2floor" }, kind = "upwalls", at = { fl = 2 }, pad = { -12, 176, LV[2] }, floor = 2, phase = 9, eff = {} })
	add({ key = "f2lights", name = "2nd Floor Lights", price = 20000, deps = { "f2walls" }, kind = "uplights", at = { fl = 2 }, pad = { 12, 176, LV[2] }, floor = 2, phase = 9, eff = { cat = { comfort = 0.02 } } })
	add({ key = "f2banners", name = "Mall Banners", price = 15000, deps = { "f2walls" }, kind = "banners", at = { fl = 2 }, pad = { 0, 140, LV[2] }, floor = 2, phase = 9, eff = { cat = { shopping = 0.02 } } })

	-- slot, key, name, price, style, color, spend
	local F2 = {
		{ "L1", "f2noodle", "Noodle House", 18000, "food", "Bright red", 9 },
		{ "L2", "f2steak", "Steakhouse", 26000, "food", "Reddish brown", 14 },
		{ "L3", "f2bakery", "Bakery", 14000, "bakery", "Brick yellow", 7 },
		{ "L4", "f2juice", "Juice Bar", 12000, "juice", "Lime green", 6 },
		{ "L5", "f2donut", "Donut Shop", 15000, "bakery", "Hot pink", 7 },
		{ "L6", "f2bbq", "BBQ Smokehouse", 30000, "food", "Brown", 15 },
		{ "L7", "f2hotdog", "Hot Dog Stand", 10000, "food", "Bright yellow", 5 },
		{ "L8", "f2boba", "Bubble Tea", 16000, "juice", "Royal purple", 7 },
		{ "R1", "f2toys", "Toy Store", 22000, "toys", "Bright blue", 10 },
		{ "R2", "f2shoes", "Shoe Store", 24000, "shoes", "Really black", 11 },
		{ "R3", "f2sports", "Sports Shop", 26000, "sports", "Bright green", 11 },
		{ "R4", "f2jewel", "Jewelry Store", 48000, "jewel", "Gold", 20 },
		{ "R5", "f2candy", "Candy Shop", 14000, "candy", "Pink", 6 },
		{ "R6", "f2music", "Music Store", 28000, "music", "Really black", 12 },
		{ "R7", "f2perfume", "Perfume Shop", 34000, "shop", "Royal purple", 14 },
		{ "R8", "f2watch", "Watch Shop", 42000, "jewel", "Navy blue", 18 },
		{ "F1", "f2bank", "Bank", 30000, "bank", "Dark green", 6 },
		{ "F2", "f2exchange", "Currency Exchange", 22000, "bank", "Bright orange", 8 },
		{ "F3", "f2post", "Post Office", 16000, "post", "Bright red", 5 },
		{ "F4", "f2travel", "Travel Agency", 26000, "service", "Cyan", 10 },
		{ "F5", "f2barber", "Barber Shop", 18000, "barber", "Bright blue", 8 },
		{ "F6", "f2nails", "Nail Salon", 20000, "barber", "Hot pink", 9 },
		{ "B1", "f2games", "Gaming Store", 36000, "games", "Really black", 15 },
		{ "B2", "f2phones", "Phone Store", 40000, "phones", "Institutional white", 16 },
		{ "B3", "f2camera", "Camera Shop", 30000, "phones", "Dark stone grey", 13 },
		{ "B4", "f2luggage", "Luggage Store", 24000, "luggage", "Brown", 11 },
		{ "B5", "f2shades", "Sunglasses Hut", 20000, "shop", "Bright orange", 9 },
		{ "B6", "f2news", "Newsstand", 9000, "news", "Navy blue", 4 },
	}
	local prev = "f2walls"
	for i, s in ipairs(F2) do
		local sl = SLOT[s[1]]
		local food = s[5] == "food" or s[5] == "bakery" or s[5] == "juice"
		add({ key = s[2], name = s[3], price = s[4], deps = { i <= 8 and "f2walls" or (i <= 16 and "f2lights" or "f2banners") }, kind = "ubooth",
			at = { fl = 2, slot = s[1], style = s[5], color = s[6], title = string.upper(s[3]) }, pad = { sl.px, sl.pz, LV[2] }, floor = 2, phase = 9,
			eff = { spend = s[7], cnt = food and { stall = 1 } or { shop = 1 }, cat = food and { food = 0.03 } or { shopping = 0.03 } } })
	end
	-- islands: x, z, key, name, price, style, spend (0 = they just sit/look)
	local I2 = {
		{ -85, 105, "f2tablesA", "Dining Tables A", 6000, "tables", 0 }, { -55, 105, "f2popcorn", "Popcorn Cart", 7000, "cart", 4 },
		{ 55, 105, "f2massage", "Massage Chairs", 14000, "massage", 6 }, { 85, 105, "f2caseKiosk", "Phone Case Kiosk", 9000, "kiosk", 5 },
		{ -85, 135, "f2tablesB", "Dining Tables B", 7000, "tables", 0 }, { -55, 135, "f2coffeeCart", "Coffee Cart", 8000, "cart", 4 },
		{ 55, 135, "f2claw", "Claw Machines", 12000, "claw", 5 }, { 85, 135, "f2shadesKiosk", "Hat Kiosk", 9000, "kiosk", 5 },
		{ -85, 165, "f2tablesC", "Dining Tables C", 8000, "tables", 0 }, { -55, 165, "f2pretzel", "Pretzel Cart", 8000, "cart", 4 },
		{ 55, 165, "f2photo", "Photo Booth", 11000, "photobooth", 5 }, { 85, 165, "f2perfKiosk", "Perfume Kiosk", 10000, "kiosk", 5 },
		{ -85, 195, "f2tablesD", "Dining Tables D", 9000, "tables", 0 }, { -55, 195, "f2cotton", "Cotton Candy Cart", 9000, "cart", 4 },
		{ 55, 195, "f2piano", "Grand Piano", 25000, "piano", 0 }, { 85, 195, "f2toyKiosk", "Toy Kiosk", 10000, "kiosk", 5 },
		{ -85, 225, "f2tablesE", "Dining Tables E", 10000, "tables", 0 }, { -55, 225, "f2icecart", "Ice Cream Cart", 10000, "cart", 5 },
		{ 55, 225, "f2benchA", "Waiting Benches A", 6000, "benches", 0 }, { 85, 225, "f2charge", "Charging Bar", 12000, "charging", 3 },
		{ -85, 255, "f2tablesF", "Dining Tables F", 11000, "tables", 0 }, { -55, 255, "f2smoothie", "Smoothie Cart", 10000, "cart", 5 },
		{ 55, 255, "f2benchB", "Waiting Benches B", 7000, "benches", 0 }, { 85, 255, "f2rides", "Kids Ride-ons", 16000, "rides", 6 },
		{ -85, 285, "f2tablesG", "Dining Tables G", 12000, "tables", 0 }, { -55, 285, "f2churro", "Churro Cart", 11000, "cart", 5 },
		{ 55, 285, "f2benchC", "Waiting Benches C", 8000, "benches", 0 }, { 85, 285, "f2sculpt", "Art Sculpture", 30000, "sculpture", 0 },
		{ 0, 105, "f2plantA", "Mall Planters A", 5000, "planter", 0 }, { 0, 165, "f2screen", "Info Screen", 9000, "infoscreen", 0 },
		{ 0, 225, "f2plantB", "Mall Planters B", 6000, "planter", 0 }, { 0, 285, "f2fountain", "Mall Fountain", 28000, "minifountain", 0 },
	}
	for _, s in ipairs(I2) do
		local cat = (s[6] == "tables" or s[6] == "cart") and { food = 0.02 } or { comfort = 0.02 }
		add({ key = s[3], name = s[4], price = s[5], deps = { "f2walls" }, kind = "uisland", at = { fl = 2, x = s[1], z = s[2], style = s[6] },
			pad = { s[1], s[2], LV[2] }, floor = 2, phase = 9, eff = { spend = s[7] > 0 and s[7] or nil, cat = cat } })
	end

	---------------------------------------------------------------- 10. third floor: fun, wellness and aviation
	add({ key = "f3floor", name = "3rd Floor", price = 300000, deps = { "f2walls" }, kind = "upfloor", at = { fl = 3 }, pad = { 12, 140, LV[2] }, floor = 2, phase = 10,
		eff = { cnt = { level = 1 }, cat = { comfort = 0.05 } } })
	add({ key = "f3walls", name = "3rd Floor Walls", price = 140000, deps = { "f3floor" }, kind = "upwalls", at = { fl = 3 }, pad = { -12, 176, LV[3] }, floor = 3, phase = 10, eff = {} })
	add({ key = "f3lights", name = "3rd Floor Lights", price = 60000, deps = { "f3walls" }, kind = "uplights", at = { fl = 3 }, pad = { 12, 176, LV[3] }, floor = 3, phase = 10, eff = { cat = { comfort = 0.02 } } })
	add({ key = "f3roof", name = "Terminal Roof", price = 160000, deps = { "f3walls" }, kind = "uproof", pad = { 0, 140, LV[3] }, floor = 3, phase = 10, eff = { cat = { clean = 0.03 } } })
	add({ key = "f3garden", name = "Rooftop Garden", price = 120000, deps = { "f3roof" }, kind = "roofgarden", pad = { 0, 120, LV[3] }, floor = 3, phase = 10, eff = { inc = 30, cat = { comfort = 0.04 } } })

	local F3 = {
		{ "L1", "f3cinema", "Cinema", 140000, "cinema", "Really black", 30 },
		{ "L2", "f3bowling", "Bowling Alley", 120000, "bowling", "Navy blue", 26 },
		{ "L3", "f3laser", "Laser Tag", 100000, "laser", "Royal purple", 24 },
		{ "L4", "f3vr", "VR Arcade", 110000, "vr", "Cyan", 24 },
		{ "L5", "f3escape", "Escape Room", 90000, "escape", "Dark stone grey", 22 },
		{ "L6", "f3karaoke", "Karaoke Room", 80000, "karaoke", "Hot pink", 20 },
		{ "L7", "f3comedy", "Comedy Club", 85000, "comedy", "Bright red", 20 },
		{ "L8", "f3golf", "Mini Golf", 95000, "minigolf", "Bright green", 22 },
		{ "R1", "f3gym", "Gym", 90000, "gym", "Dark stone grey", 18 },
		{ "R2", "f3yoga", "Yoga Studio", 70000, "yoga", "Teal", 16 },
		{ "R3", "f3pods", "Sleep Pods", 110000, "pods", "Institutional white", 26 },
		{ "R4", "f3business", "Business Center", 100000, "business", "Navy blue", 24 },
		{ "R5", "f3library", "Library", 60000, "library", "Brown", 10 },
		{ "R6", "f3gallery", "Art Gallery", 130000, "gallery", "Institutional white", 22 },
		{ "R7", "f3science", "Science Museum", 150000, "science", "Bright blue", 26 },
		{ "R8", "f3prayer", "Quiet Room", 40000, "quiet", "Sand blue", 4 },
		{ "F1", "f3skybar", "Sky Bar", 160000, "bar", "Navy blue", 34 },
		{ "F2", "f3wine", "Wine Bar", 140000, "bar", "Reddish brown", 30 },
		{ "F3", "f3sushi", "Sushi Lounge", 150000, "food", "Institutional white", 32 },
		{ "F4", "f3tea", "Tea House", 90000, "juice", "Dark green", 18 },
		{ "F5", "f3choc", "Chocolate Shop", 80000, "candy", "Brown", 18 },
		{ "F6", "f3lobster", "Steak & Lobster", 200000, "food", "Bright red", 40 },
		{ "B1", "f3museum", "Aviation Museum", 180000, "planemuseum", "Bright blue", 30 },
		{ "B2", "f3sim", "Flight Simulator", 170000, "simulator", "Really black", 36 },
		{ "B3", "f3academy", "Pilot Academy", 150000, "academy", "Navy blue", 28 },
		{ "B4", "f3spotting", "Plane Spotting Deck", 90000, "spotting", "Sand blue", 14 },
		{ "B5", "f3first", "First Class Lounge", 260000, "lounge", "Gold", 44 },
		{ "B6", "f3club", "Airline Club", 220000, "lounge", "Royal purple", 38 },
	}
	for i, s in ipairs(F3) do
		local sl = SLOT[s[1]]
		local food = s[5] == "food" or s[5] == "bar" or s[5] == "juice" or s[5] == "candy"
		add({ key = s[2], name = s[3], price = s[4], deps = { i <= 8 and "f3walls" or (i <= 16 and "f3lights" or "f3roof") }, kind = "ubooth",
			at = { fl = 3, slot = s[1], style = s[5], color = s[6], title = string.upper(s[3]) }, pad = { sl.px, sl.pz, LV[3] }, floor = 3, phase = 10,
			eff = { spend = s[7], cnt = food and { stall = 1 } or { shop = 1 }, cat = food and { food = 0.03 } or { comfort = 0.03 } } })
	end
	local I3 = {
		{ -85, 105, "f3pool", "Pool Tables", 30000, "pooltable", 8 }, { -55, 105, "f3pingpong", "Ping Pong", 22000, "pingpong", 6 },
		{ 55, 105, "f3loungeA", "Lounge Chairs A", 18000, "loungechairs", 0 }, { 85, 105, "f3beanbags", "Bean Bags", 14000, "beanbags", 0 },
		{ -85, 135, "f3hockey", "Air Hockey", 26000, "airhockey", 7 }, { -55, 135, "f3foosball", "Foosball", 20000, "foosball", 6 },
		{ 55, 135, "f3loungeB", "Lounge Chairs B", 20000, "loungechairs", 0 }, { 85, 135, "f3reading", "Reading Nook", 16000, "reading", 0 },
		{ -85, 165, "f3racers", "Arcade Racers", 40000, "racers", 10 }, { -55, 165, "f3pinball", "Pinball Machines", 30000, "pinball", 8 },
		{ 55, 165, "f3treesA", "Indoor Trees A", 15000, "trees", 0 }, { 85, 165, "f3telescope", "Telescope", 24000, "telescope", 4 },
		{ -85, 195, "f3hoops", "Basketball Hoops", 32000, "hoops", 8 }, { -55, 195, "f3dance", "Dance Floor", 45000, "dancefloor", 9 },
		{ 55, 195, "f3koi", "Koi Pond", 50000, "koi", 0 }, { 85, 195, "f3rocket", "Rocket Model", 60000, "rocket", 0 },
		{ -85, 225, "f3tramp", "Trampolines", 38000, "trampoline", 9 }, { -55, 225, "f3dj", "DJ Booth", 42000, "dj", 0 },
		{ 55, 225, "f3treesB", "Indoor Trees B", 16000, "trees", 0 }, { 85, 225, "f3dino", "Dinosaur Skeleton", 90000, "dino", 0 },
		{ -85, 255, "f3climb", "Climbing Wall", 55000, "climbwall", 10 }, { -55, 255, "f3carousel", "Mini Carousel", 70000, "carousel", 10 },
		{ 55, 255, "f3zen", "Zen Garden", 35000, "zen", 0 }, { 85, 255, "f3balloon", "Hot Air Balloon Model", 65000, "balloon", 0 },
		{ -85, 285, "f3chess", "Giant Chess", 28000, "chess", 0 }, { -55, 285, "f3jukebox", "Jukebox Lounge", 30000, "jukebox", 5 },
		{ 55, 285, "f3massage", "Massage Pods", 48000, "massage", 12 }, { 85, 285, "f3robot", "Robot Butler", 80000, "robot", 0 },
		{ 0, 105, "f3plantA", "Sky Planters A", 12000, "planter", 0 }, { 0, 165, "f3statue", "Golden Globe Statue", 100000, "globe", 0 },
		{ 0, 225, "f3plantB", "Sky Planters B", 14000, "planter", 0 }, { 0, 285, "f3lightart", "Light Sculpture", 70000, "lightart", 0 },
	}
	for _, s in ipairs(I3) do
		add({ key = s[3], name = s[4], price = s[5], deps = { "f3walls" }, kind = "uisland", at = { fl = 3, x = s[1], z = s[2], style = s[6] },
			pad = { s[1], s[2], LV[3] }, floor = 3, phase = 10, eff = { spend = s[7] > 0 and s[7] or nil, cat = { comfort = 0.02 } } })
	end

	---------------------------------------------------------------- 11. the hotel
	local H = HOTEL
	local function hadd(key, name, price, deps, kind, at, pad, eff)
		return add({ key = key, name = name, price = price, deps = deps, kind = kind, at = at or {}, pad = pad, floor = 0, phase = 11, eff = eff or {} })
	end
	hadd("hreception", "Hotel Reception", 25000, { "hotel" }, "hreception", nil, { 235, 150, HL[1] }, { cnt = { reception = 1 }, cat = { comfort = 0.02 } })
	hadd("hsofas", "Lobby Sofas", 12000, { "hotel" }, "hsofas", nil, { 281, 155, HL[1] }, { cat = { comfort = 0.02 } })
	hadd("hchandelier", "Lobby Chandelier", 20000, { "hreception" }, "hchandelier", nil, { 256, 166, HL[1] }, { cat = { comfort = 0.01 } })
	hadd("helevator", "Hotel Elevator", 40000, { "hreception" }, "helevator", nil, { 256, 142, HL[1] }, { cat = { comfort = 0.01 } })
	hadd("hrestaurant", "Hotel Restaurant", 45000, { "hreception" }, "hrestaurant", nil, { 233, 240, HL[1] }, { spend = 14, cnt = { stall = 1 }, inc = 10 })
	hadd("hgift", "Hotel Gift Shop", 30000, { "hreception" }, "hgift", nil, { 279, 219, HL[1] }, { spend = 10, cnt = { shop = 1 }, inc = 6 })
	hadd("hgym", "Hotel Gym", 40000, { "hreception" }, "hgym", nil, { 279, 261, HL[1] }, { cat = { comfort = 0.02 }, inc = 8 })
	local floorPrice = { 0, 60000, 90000, 130000, 180000 }
	local roomPrice = { 0, 9000, 15000, 22000, 32000 }
	local roomRate = { 0, 40, 55, 70, 95 }
	for lvl = 2, 5 do
		hadd("hfloor" .. lvl, "Hotel Floor " .. lvl, floorPrice[lvl], { lvl == 2 and "helevator" or ("hfloor" .. (lvl - 1)) }, "hfloor", { lvl = lvl },
			{ 256, 150, HL[lvl - 1] }, { cat = { comfort = 0.01 } })
		for r = 1, 8 do
			local side = r <= 4 and -1 or 1
			local zc = ({ 154, 190, 226, 262 })[(r - 1) % 4 + 1]
			hadd("h" .. lvl .. "0" .. r, "Room " .. lvl .. "0" .. r, roomPrice[lvl] + r * 500, { "hfloor" .. lvl }, "hroom",
				{ lvl = lvl, side = side, z = zc, n = lvl * 100 + r }, { side < 0 and 233 or 279, zc, HL[lvl] }, { spend = roomRate[lvl], cnt = { hroom = 1 } })
		end
	end
	hadd("hroof", "Hotel Roof & Sign", 50000, { "hfloor5" }, "hroof", nil, { 256, 150, HL[5] }, { cat = { comfort = 0.01 } })
	hadd("hrooftop", "Rooftop Bar", 120000, { "hroof" }, "hrooftop", nil, { 240, 200, H.roof }, { spend = 25, inc = 20 })
	hadd("hgarden", "Hotel Garden", 25000, { "hotel" }, "hgarden", nil, { 222, 76 }, { cat = { comfort = 0.02 } })
	hadd("hfountain", "Hotel Fountain", 30000, { "hgarden" }, "hfountain", nil, { 248, 88 }, { cat = { comfort = 0.01 } })
	hadd("hvalet", "Valet Parking", 35000, { "hotel" }, "hvalet", nil, { 283, 86 }, { inc = 15, cnt = { transport = 1 } })
	hadd("hpool", "Swimming Pool", 60000, { "hreception" }, "hpool", nil, { 256, 330 }, { spend = 8, cat = { comfort = 0.03 } })
	hadd("hloungers", "Pool Loungers", 15000, { "hpool" }, "hloungers", nil, { 222, 330 }, { cat = { comfort = 0.01 } })
	hadd("humbrellas", "Pool Umbrellas", 10000, { "hloungers" }, "humbrellas", nil, { 290, 330 }, {})
	hadd("hpoolbar", "Pool Bar", 35000, { "hpool" }, "hpoolbar", nil, { 256, 378 }, { spend = 10, inc = 8 })
	hadd("hslide", "Water Slide", 80000, { "hpool" }, "hslide", nil, { 288, 300 }, { inc = 15 })
	hadd("hhottub", "Hot Tub", 40000, { "hpool" }, "hhottub", nil, { 228, 386 }, { cat = { comfort = 0.01 } })
	hadd("htennis", "Tennis Court", 50000, { "hpool" }, "htennis", nil, { 256, 424 }, { inc = 10 })

	---------------------------------------------------------------- 12. expansion: left strip and the back
	local function xadd(key, name, price, deps, kind, pad, eff, at)
		return add({ key = key, name = name, price = price, deps = deps, kind = kind, at = at or {}, pad = pad, floor = 0, phase = 12, eff = eff or {} })
	end
	xadd("xparking", "Overflow Parking", 30000, { "parking" }, "xparking", { -255, 70 }, { inc = 25, cnt = { transport = 1 } })
	xadd("xev", "EV Chargers", 20000, { "xparking" }, "xev", { -255, 212 }, { inc = 15 })
	xadd("xgas", "Gas Station", 60000, { "xparking" }, "xgas", { -230, 236 }, { inc = 50 })
	xadd("xpolice", "Airport Police", 80000, { "xparking" }, "xpolice", { -235, 296 }, { cat = { security = 0.05 } })
	xadd("xstandA", "Remote Stand A", 90000, { "runway" }, "xstand", { -255, 336 }, { inc = 40, cat = { gates = 0.03 } }, { x = -278, n = 5 })
	xadd("xstandB", "Remote Stand B", 120000, { "xstandA" }, "xstand", { -232, 440 }, { inc = 50, cat = { gates = 0.03 } }, { x = -232, n = 6 })
	xadd("xrunway2", "Second Runway", 250000, { "runway", "hangar" }, "xrunway2", { 0, 640 }, { cat = { gates = 0.05 } })
	xadd("xrw2lights", "Runway 2 Lights", 60000, { "xrunway2" }, "xrw2lights", { 40, 640 }, {})
	xadd("xcargoapron", "Cargo Apron", 120000, { "xrunway2" }, "xcargoapron", { -150, 640 }, { inc = 40 })
	xadd("xcargo1", "Cargo Jet 1", 150000, { "xcargoapron" }, "xcargojet", { -245, 662 }, { inc = 60 }, { x = -245, n = 7 })
	xadd("xcargo2", "Cargo Jet 2", 200000, { "xcargo1" }, "xcargojet", { -180, 662 }, { inc = 70 }, { x = -180, n = 8 })
	xadd("xcargo3", "Cargo Jet 3", 260000, { "xcargo2" }, "xcargojet", { -115, 662 }, { inc = 80 }, { x = -115, n = 9 })
	xadd("xmhangar", "Maintenance Hangar", 180000, { "xrunway2" }, "xmhangar", { 150, 642 }, { inc = 40 })
	xadd("xcatering", "Catering Kitchen", 70000, { "xrunway2" }, "xcatering", { 45, 690 }, { inc = 30, cat = { food = 0.03 } })
	xadd("xdeice", "De-icing Pad", 50000, { "xrunway2" }, "xdeice", { 45, 745 }, { cat = { gates = 0.02 } })
	xadd("xwater", "Water Tower", 40000, { "xrunway2" }, "xwater", { 272, 642 }, { cat = { clean = 0.03 } })
	xadd("xweather", "Weather Station", 35000, { "xrunway2" }, "xweather", { 272, 745 }, { cat = { gates = 0.02 } })
	xadd("xtower2", "Runway 2 Tower", 110000, { "xrunway2" }, "xtower2", { 272, 700 }, { cat = { gates = 0.03 } })
	xadd("xsolar", "Solar Farm", 150000, { "xrunway2" }, "xsolar", { -120, 868 }, { inc = 120 })
	xadd("xwind", "Wind Turbines", 220000, { "xsolar" }, "xwind", { 200, 868 }, { inc = 160 })
end

-- three new kinds of staff for the hotel
table.insert(STAFF, { key = "receptionist", name = "Receptionist", fee = 2500, need = "reception", capbase = 0, capper = 2,
	cat = { comfort = 0.02 }, desc = "Works the hotel reception. Guests check in faster.", shirt = "Navy blue" })
table.insert(STAFF, { key = "housekeeper", name = "Housekeeper", fee = 2000, need = "hroom", capbase = 0, capper = 0.25,
	cat = { clean = 0.02 }, desc = "Cleans hotel rooms. Guests pay more per night.", shirt = "Institutional white" })
table.insert(STAFF, { key = "bellhop", name = "Bellhop", fee = 1800, need = "reception", capbase = 0, capper = 2,
	cat = { comfort = 0.01 }, desc = "Carries guests' bags. More hotel guests come.", shirt = "Bright red" })
