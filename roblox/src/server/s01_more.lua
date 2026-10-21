-- ==== s01_more.lua
------------------------------------------------------------------ the bigger airport
-- More land (600 x 900 studs instead of 420 x 620), a 2nd and 3rd floor on the terminal with real airport
-- rooms (lounges, duty free, medical centre, cinema, food hall...), moving elevators, a hotel guests really stay
-- in (themed rooms, suites, a penthouse), an expansion zone with remote stands, cargo jets and a second runway,
-- and ground operations (vehicles that drive around, a sky train).
local PLOT_W, PLOT_D = 600, 900
-- floor tops in plot space: LV[1] terminal ground floor, LV[2] 2nd floor, LV[3] 3rd floor; the roof is on top
local LV = { [0] = 0, 1, 32, 48 }
local LV_ROOF = 64
-- hotel: floor tops (lobby, then floors 2..6), the building's footprint, and its elevator
local HL = { 1, 13, 25, 37, 49, 61 }
local HOTEL = { x0 = 216, x1 = 296, z0 = 120, z1 = 280, cx = 256, roof = 73, liftZ = 128, doorX = 236 }
-- terminal elevators (one each side of the central aisle)
local LIFT_Z = 198

-- upper-floor layout: rooms along the walls. Side rooms are 26 deep, front/back rooms 20 deep; the door is in the
-- middle of each room's glass front. Walkers reach a door along a "lane" (the row through its middle), so the
-- islands in between sit in rows away from the lanes (ISLAND_Z).
local RSLOT = {}
do
	local sides = { { 80, 130 }, { 130, 165 }, { 165, 200 }, { 200, 235 }, { 235, 265 }, { 265, 300 } }
	for i, r in ipairs(sides) do
		RSLOT["L" .. i] = { x = -127, z = (r[1] + r[2]) / 2, W = r[2] - r[1], D = 26, ry = -90 }
		RSLOT["R" .. i] = { x = 127, z = (r[1] + r[2]) / 2, W = r[2] - r[1], D = 26, ry = 90 }
	end
	for i, r in ipairs({ { -114, -69 }, { -69, -24 }, { 24, 69 }, { 69, 114 } }) do
		RSLOT["F" .. i] = { x = (r[1] + r[2]) / 2, z = 70, W = r[2] - r[1], D = 20, ry = 180 }
		RSLOT["B" .. i] = { x = (r[1] + r[2]) / 2, z = 310, W = r[2] - r[1], D = 20, ry = 0 }
	end
end
local ISLAND_Z = { 126, 165, 200, 234, 266 }
local ISLAND_X = { -100, -70, -40, 40, 70, 100 }

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

	local FOOD = { lounge = true, sportsbar = true, cafe = true, foodhall = true, sushi = true, steak = true, pizza = true, noodle = true, dessert = true, champagne = true }
	local function rooms(fl, phase, list, deps)
		for i, r in ipairs(list) do
			local sl = RSLOT[r[1]]
			local food = FOOD[r[5]]
			add({ key = r[2], name = r[3], price = r[4], deps = { deps[math.floor((i - 1) / 7) + 1] or deps[#deps] }, kind = "uroom",
				at = { fl = fl, slot = r[1], style = r[5], color = r[6], title = string.upper(r[3]), lux = r[8] },
				pad = { sl.x, sl.z, LV[fl] }, floor = fl, phase = phase,
				eff = { spend = r[7] > 0 and r[7] or nil, cnt = food and { stall = 1 } or { shop = 1 },
					cat = food and { food = 0.03 } or (r[7] > 0 and { shopping = 0.03 } or { comfort = 0.03 }) } })
		end
	end
	local function islands(fl, phase, list, dep)
		for _, r in ipairs(list) do
			add({ key = r[3], name = r[4], price = r[5], deps = { dep }, kind = "uisland", at = { fl = fl, x = r[1], z = r[2], style = r[6] },
				pad = { r[1], r[2], LV[fl] }, floor = fl, phase = phase, eff = { spend = r[7] > 0 and r[7] or nil, cat = { comfort = 0.02 } } })
		end
	end

	---------------------------------------------------------------- 9. second floor: the departures concourse
	add({ key = "elevators", name = "Terminal Elevators", price = 30000, deps = { "lane1", "walls" }, kind = "elevators", pad = { 0, 186 }, floor = 1, phase = 9,
		eff = { cat = { comfort = 0.03 } } })
	add({ key = "f2floor", name = "2nd Floor", price = 90000, deps = { "elevators" }, kind = "upfloor", at = { fl = 2 }, pad = { -12, 176 }, floor = 1, phase = 9,
		eff = { cnt = { level = 1 }, cat = { comfort = 0.05 } } })
	add({ key = "f2walls", name = "2nd Floor Walls", price = 45000, deps = { "f2floor" }, kind = "upwalls", at = { fl = 2 }, pad = { -12, 176, LV[2] }, floor = 2, phase = 9, eff = {} })
	add({ key = "f2lights", name = "2nd Floor Lights", price = 20000, deps = { "f2walls" }, kind = "uplights", at = { fl = 2 }, pad = { 12, 176, LV[2] }, floor = 2, phase = 9, eff = { cat = { comfort = 0.02 } } })
	add({ key = "f2walkway", name = "Moving Walkways (2nd Floor)", price = 35000, deps = { "f2walls" }, kind = "walkway", at = { fl = 2 }, pad = { -12, 140, LV[2] }, floor = 2, phase = 9, eff = { cat = { gates = 0.02 } } })
	add({ key = "f2fids", name = "Flight Info Screens (2nd Floor)", price = 25000, deps = { "f2walls" }, kind = "fids", at = { fl = 2 }, pad = { 12, 140, LV[2] }, floor = 2, phase = 9, eff = { cat = { gates = 0.03 } } })
	-- slot, key, name, price, style, color, spend, luxury
	rooms(2, 9, {
		{ "R1", "f2lounge", "Sky Priority Lounge", 80000, "lounge", "Navy blue", 30 },
		{ "L1", "f2dutyfree", "Duty Free", 60000, "dutyfree", "Royal purple", 22 },
		{ "L2", "f2pharmacy", "Pharmacy", 20000, "pharmacy", "Bright green", 8 },
		{ "L3", "f2exchange", "Currency Exchange", 18000, "exchange", "Bright orange", 6 },
		{ "L4", "f2medical", "Medical Center", 30000, "medical", "Really red", 0 },
		{ "L5", "f2prayer", "Prayer & Quiet Room", 15000, "prayer", "Sand blue", 0 },
		{ "L6", "f2family", "Family & Baby Room", 16000, "nursery", "Pink", 0 },
		{ "R2", "f2showers", "Showers & Spa", 35000, "showers", "Teal", 12 },
		{ "R3", "f2pods", "Sleep Pods", 45000, "pods", "Institutional white", 20 },
		{ "R4", "f2business", "Business Center", 40000, "business", "Dark stone grey", 15 },
		{ "R5", "f2kids", "Kids Play Zone", 30000, "kidsplay", "Bright yellow", 6 },
		{ "R6", "f2tech", "Electronics Store", 38000, "electronics", "Really black", 16 },
		{ "F1", "f2transfer", "Transfer Desk", 15000, "helpdesk", "Bright blue", 4 },
		{ "F2", "f2lost", "Lost & Found", 10000, "lostfound", "Brown", 0 },
		{ "F3", "f2wrap", "Luggage Wrap & Lockers", 12000, "wrap", "Bright orange", 6 },
		{ "F4", "f2sim", "Phone & SIM Shop", 14000, "simshop", "Cyan", 8 },
		{ "B1", "f2sportsbar", "Sports Bar", 45000, "sportsbar", "Bright red", 16 },
		{ "B2", "f2cafe", "Coffee House", 25000, "cafe", "Brown", 8 },
		{ "B3", "f2books", "Bookstore & News", 22000, "bookstore", "Navy blue", 7 },
		{ "B4", "f2fashion", "Fashion Boutique", 42000, "fashion", "Hot pink", 18 },
	}, { "f2walls", "f2lights", "f2walkway" })
	islands(2, 9, {
		{ -100, 126, "f2seatsA", "Gate Seating A", 6000, "gateseats", 0 }, { -70, 126, "f2water", "Water Refill Station", 5000, "water", 0 },
		{ -40, 126, "f2coffeecart", "Coffee Cart", 8000, "cart", 4 }, { 40, 126, "f2recycle", "Recycling Station", 4000, "recycle", 0 },
		{ 70, 126, "f2info", "Info Kiosk", 7000, "infokiosk", 0 }, { 100, 126, "f2massage", "Massage Chairs", 14000, "massage", 6 },
		{ -100, 165, "f2seatsB", "Gate Seating B", 7000, "gateseats", 0 }, { -70, 165, "f2workpods", "Phone Booths", 12000, "workpods", 3 },
		{ -40, 165, "f2perfume", "Perfume Promo Stand", 9000, "perfume", 5 }, { 40, 165, "f2charge", "Charging Bar", 12000, "charging", 3 },
		{ 70, 165, "f2transferk", "Transfer Kiosks", 10000, "transferkiosk", 2 }, { 100, 165, "f2claw", "Claw Machines", 12000, "claw", 5 },
		{ -100, 200, "f2seatsC", "Gate Seating C", 8000, "gateseats", 0 }, { -70, 200, "f2car", "Prize Car Display", 40000, "cardisplay", 5 },
		{ 70, 200, "f2piano", "Grand Piano", 25000, "piano", 0 }, { 100, 200, "f2lockers", "Luggage Lockers", 10000, "lockers", 3 },
		{ -100, 234, "f2seatsD", "Gate Seating D", 9000, "gateseats", 0 }, { -70, 234, "f2icecart", "Ice Cream Cart", 10000, "cart", 5 },
		{ -40, 234, "f2plantwall", "Living Plant Wall", 14000, "plantwall", 0 }, { 40, 234, "f2ads", "Digital Ad Screen", 8000, "adscreen", 0 },
		{ 70, 234, "f2cartbay", "Free Luggage Carts", 6000, "cartbay", 0 }, { 100, 234, "f2shoeshine", "Shoe Shine", 9000, "shoeshine", 4 },
		{ -100, 266, "f2seatsE", "Gate Seating E", 10000, "gateseats", 0 }, { -70, 266, "f2aquarium", "Aquarium Column", 35000, "aquariumcol", 0 },
		{ -40, 266, "f2photo", "Photo Spot", 8000, "photospot", 0 }, { 40, 266, "f2pretzel", "Pretzel Cart", 8000, "cart", 4 },
		{ 70, 266, "f2rides", "Kids Ride-ons", 16000, "rides", 6 }, { 100, 266, "f2sculpt", "Art Sculpture", 30000, "sculpture", 0 },
	}, "f2walls")

	---------------------------------------------------------------- 10. third floor: the sky deck
	add({ key = "f3floor", name = "3rd Floor", price = 300000, deps = { "f2walls" }, kind = "upfloor", at = { fl = 3 }, pad = { 12, 110, LV[2] }, floor = 2, phase = 10,
		eff = { cnt = { level = 1 }, cat = { comfort = 0.05 } } })
	add({ key = "f3walls", name = "3rd Floor Walls", price = 140000, deps = { "f3floor" }, kind = "upwalls", at = { fl = 3 }, pad = { -12, 176, LV[3] }, floor = 3, phase = 10, eff = {} })
	add({ key = "f3lights", name = "3rd Floor Lights", price = 60000, deps = { "f3walls" }, kind = "uplights", at = { fl = 3 }, pad = { 12, 176, LV[3] }, floor = 3, phase = 10, eff = { cat = { comfort = 0.02 } } })
	add({ key = "f3walkway", name = "Moving Walkways (3rd Floor)", price = 80000, deps = { "f3walls" }, kind = "walkway", at = { fl = 3 }, pad = { -12, 110, LV[3] }, floor = 3, phase = 10, eff = { cat = { gates = 0.02 } } })
	add({ key = "f3fids", name = "Flight Info Screens (3rd Floor)", price = 50000, deps = { "f3walls" }, kind = "fids", at = { fl = 3 }, pad = { 12, 110, LV[3] }, floor = 3, phase = 10, eff = { cat = { gates = 0.03 } } })
	add({ key = "f3roof", name = "Terminal Roof", price = 160000, deps = { "f3walls" }, kind = "uproof", pad = { -12, 140, LV[3] }, floor = 3, phase = 10, eff = { cat = { clean = 0.03 } } })
	add({ key = "f3garden", name = "Rooftop Garden", price = 120000, deps = { "f3roof" }, kind = "roofgarden", pad = { 12, 140, LV[3] }, floor = 3, phase = 10, eff = { inc = 30, cat = { comfort = 0.04 } } })
	rooms(3, 10, {
		{ "F1", "f3first", "First Class Lounge", 220000, "lounge", "Gold", 44, true },
		{ "L1", "f3foodhall", "Food Hall", 90000, "foodhall", "Bright orange", 14 },
		{ "L2", "f3sushi", "Sushi Restaurant", 60000, "sushi", "Institutional white", 18 },
		{ "L3", "f3steak", "Steakhouse", 70000, "steak", "Reddish brown", 22 },
		{ "L4", "f3pizza", "Pizza & Pasta", 45000, "pizza", "Bright red", 12 },
		{ "L5", "f3noodle", "Noodle Bar", 40000, "noodle", "Really black", 10 },
		{ "L6", "f3dessert", "Dessert Bar", 35000, "dessert", "Hot pink", 9 },
		{ "R1", "f3cinema", "Cinema", 120000, "cinema", "Really black", 24 },
		{ "R2", "f3arcade", "Gaming Arcade", 70000, "arcade", "Royal purple", 14 },
		{ "R3", "f3gym", "Gym & Fitness", 60000, "gym", "Dark stone grey", 10 },
		{ "R4", "f3gallery", "Art Gallery", 55000, "gallery", "Institutional white", 8 },
		{ "R5", "f3library", "Library & Reading Room", 40000, "library", "Brown", 4 },
		{ "R6", "f3butterfly", "Butterfly Garden", 65000, "garden", "Bright green", 10 },
		{ "F2", "f3business", "Business Class Lounge", 150000, "lounge", "Navy blue", 30 },
		{ "F3", "f3club", "Airline Club Lounge", 160000, "lounge", "Royal purple", 32 },
		{ "F4", "f3champagne", "Champagne Bar", 120000, "champagne", "Gold", 26 },
		{ "B1", "f3observe", "Observation Deck", 80000, "observation", "Sand blue", 6 },
		{ "B2", "f3museum", "Aviation Museum", 110000, "museum", "Bright blue", 16 },
		{ "B3", "f3sim", "Flight Simulator Center", 130000, "simulator", "Really black", 28 },
		{ "B4", "f3academy", "Pilot Academy", 90000, "academy", "Navy blue", 18 },
	}, { "f3walls", "f3lights", "f3roof" })
	islands(3, 10, {
		{ -100, 126, "f3pool", "Pool Tables", 30000, "pooltable", 8 }, { -70, 126, "f3pingpong", "Ping Pong", 22000, "pingpong", 6 },
		{ -40, 126, "f3loungeA", "Lounge Chairs A", 18000, "loungechairs", 0 }, { 40, 126, "f3beanbags", "Bean Bags", 14000, "beanbags", 0 },
		{ 70, 126, "f3water", "Water Refill (3rd Floor)", 6000, "water", 0 }, { 100, 126, "f3reading", "Reading Nook", 16000, "reading", 0 },
		{ -100, 165, "f3hockey", "Air Hockey", 26000, "airhockey", 7 }, { -70, 165, "f3racers", "Arcade Racers", 40000, "racers", 10 },
		{ -40, 165, "f3pinball", "Pinball Machines", 30000, "pinball", 8 }, { 40, 165, "f3trees", "Indoor Trees", 15000, "trees", 0 },
		{ 70, 165, "f3telescope", "Telescope", 24000, "telescope", 4 }, { 100, 165, "f3koi", "Koi Pond", 50000, "koi", 0 },
		{ -100, 200, "f3hoops", "Basketball Hoops", 32000, "hoops", 8 }, { -70, 200, "f3dance", "Dance Floor", 45000, "dancefloor", 9 },
		{ 70, 200, "f3rocket", "Rocket Model", 60000, "rocket", 0 }, { 100, 200, "f3dino", "Dinosaur Skeleton", 90000, "dino", 0 },
		{ -100, 234, "f3tramp", "Trampolines", 38000, "trampoline", 9 }, { -70, 234, "f3dj", "DJ Booth", 42000, "dj", 0 },
		{ -40, 234, "f3zen", "Zen Garden", 35000, "zen", 0 }, { 40, 234, "f3balloon", "Hot Air Balloon Model", 65000, "balloon", 0 },
		{ 70, 234, "f3massage", "Massage Pods", 48000, "massage", 12 }, { 100, 234, "f3robot", "Robot Butler", 80000, "robot", 0 },
		{ -100, 266, "f3climb", "Climbing Wall", 55000, "climbwall", 10 }, { -70, 266, "f3carousel", "Mini Carousel", 70000, "carousel", 10 },
		{ -40, 266, "f3chess", "Giant Chess", 28000, "chess", 0 }, { 40, 266, "f3globe", "Golden Globe Statue", 100000, "globe", 0 },
		{ 70, 266, "f3jukebox", "Jukebox Lounge", 30000, "jukebox", 5 }, { 100, 266, "f3lightart", "Light Sculpture", 70000, "lightart", 0 },
	}, "f3walls")

	---------------------------------------------------------------- 11. the hotel
	local H = HOTEL
	local function hadd(key, name, price, deps, kind, at, pad, eff)
		return add({ key = key, name = name, price = price, deps = deps, kind = kind, at = at or {}, pad = pad, floor = 0, phase = 11, eff = eff or {} })
	end
	hadd("hreception", "Hotel Reception", 25000, { "hotel" }, "hreception", nil, { 235, 150, HL[1] }, { cnt = { reception = 1 }, cat = { comfort = 0.02 } })
	hadd("hsofas", "Lobby Sofas", 12000, { "hotel" }, "hsofas", nil, { 281, 155, HL[1] }, { cat = { comfort = 0.02 } })
	hadd("hchandelier", "Lobby Chandelier", 20000, { "hreception" }, "hchandelier", nil, { 256, 166, HL[1] }, { cat = { comfort = 0.01 } })
	hadd("helevator", "Hotel Elevator", 40000, { "hreception" }, "helevator", nil, { 256, 144, HL[1] }, { cat = { comfort = 0.01 } })
	hadd("hrestaurant", "Hotel Restaurant", 45000, { "hreception" }, "hrestaurant", nil, { 233, 240, HL[1] }, { spend = 14, cnt = { stall = 1 }, inc = 10 })
	hadd("hgift", "Hotel Gift Shop", 30000, { "hreception" }, "hgift", nil, { 279, 219, HL[1] }, { spend = 10, cnt = { shop = 1 }, inc = 6 })
	hadd("hgym", "Hotel Gym", 40000, { "hreception" }, "hgym", nil, { 279, 261, HL[1] }, { cat = { comfort = 0.02 }, inc = 8 })
	-- floors: 2 = standard rooms, 3 = deluxe rooms, 4 = suites, 5 = the penthouse, 6 = spa and ballroom
	local LAYOUT = { [2] = "rooms", [3] = "rooms", [4] = "suites", [5] = "penthouse", [6] = "amenity" }
	local floorPrice = { 0, 60000, 90000, 150000, 250000, 200000 }
	for lvl = 2, 6 do
		hadd("hfloor" .. lvl, "Hotel Floor " .. lvl, floorPrice[lvl], { lvl == 2 and "helevator" or ("hfloor" .. (lvl - 1)) }, "hfloor",
			{ lvl = lvl, layout = LAYOUT[lvl] }, { 256, 150, HL[lvl - 1] }, { cat = { comfort = 0.01 } })
	end
	local THEMES = { "ocean", "forest", "modern", "retro", "kids", "space", "japanese", "royal" }
	local TNAME = { ocean = "Ocean", forest = "Forest", modern = "Modern", retro = "Retro", kids = "Kids", space = "Space", japanese = "Japanese", royal = "Royal" }
	for lvl = 2, 3 do
		for r = 1, 8 do
			local side = r <= 4 and -1 or 1
			local zc = ({ 154, 190, 226, 262 })[(r - 1) % 4 + 1]
			local theme = THEMES[(r + (lvl == 3 and 3 or 0) - 1) % 8 + 1]
			local deluxe = lvl == 3
			hadd("h" .. lvl .. "0" .. r, "Room " .. lvl .. "0" .. r .. " (" .. TNAME[theme] .. (deluxe and " Deluxe)" or ")"),
				(deluxe and 16000 or 9000) + r * 600, { "hfloor" .. lvl }, "hroom",
				{ lvl = lvl, side = side, z = zc, n = lvl * 100 + r, theme = theme, deluxe = deluxe }, { side < 0 and 233 or 279, zc, HL[lvl] },
				{ spend = deluxe and 65 or 42, cnt = { hroom = 1 } })
		end
	end
	local SUITES = { { "Ocean Suite", "ocean", -1, 172 }, { "Royal Suite", "royal", -1, 244 }, { "Garden Suite", "forest", 1, 172 }, { "Sky Suite", "space", 1, 244 } }
	for i, su in ipairs(SUITES) do
		hadd("hsuite" .. i, su[1], 60000 + i * 8000, { "hfloor4" }, "hsuite", { lvl = 4, side = su[3], z = su[4], n = 400 + i, theme = su[2], title = su[1] },
			{ su[3] < 0 and 233 or 279, su[4], HL[4] }, { spend = 150, cnt = { hroom = 2 } })
	end
	hadd("hpent", "Penthouse Suite", 300000, { "hfloor5" }, "hpent", nil, { 256, 262, HL[5] }, { spend = 400, cnt = { hroom = 4 } })
	local PENT = { { "hpentliving", "Penthouse Living Room", 80000, { 274, 160 } }, { "hpenttub", "Penthouse Hot Tub", 90000, { 284, 214 } },
		{ "hpentbar", "Penthouse Bar", 70000, { 228, 210 } }, { "hpentcinema", "Penthouse Cinema", 100000, { 230, 160 } },
		{ "hpentpiano", "Penthouse Grand Piano", 60000, { 262, 190 } }, { "hpentpool", "Penthouse Pool Table", 50000, { 248, 230 } } }
	for _, p in ipairs(PENT) do
		hadd(p[1], p[2], p[3], { "hpent" }, p[1], nil, { p[4][1], p[4][2], HL[5] }, { spend = math.floor(p[3] / 1000), cat = { comfort = 0.01 } })
	end
	hadd("hspa", "Hotel Spa", 80000, { "hfloor6" }, "hspa", nil, { 233, 172, HL[6] }, { spend = 25, cat = { comfort = 0.02 } })
	hadd("hsauna", "Sauna & Steam Room", 60000, { "hspa" }, "hsauna", nil, { 233, 246, HL[6] }, { spend = 15 })
	hadd("hballroom", "Ballroom", 150000, { "hfloor6" }, "hballroom", nil, { 279, 190, HL[6] }, { spend = 30, inc = 30 })
	hadd("hconference", "Conference Room", 70000, { "hfloor6" }, "hconference", nil, { 279, 262, HL[6] }, { spend = 20, inc = 20 })
	hadd("hroof", "Hotel Roof & Sign", 50000, { "hfloor6" }, "hroof", nil, { 256, 150, HL[6] }, { cat = { comfort = 0.01 } })
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

	---------------------------------------------------------------- 13. ground operations: vehicles that drive around, a sky train
	local function oadd(key, name, price, deps, kind, pad, eff)
		return add({ key = key, name = name, price = price, deps = deps, kind = kind, pad = pad, floor = 0, phase = 13, eff = eff or {} })
	end
	oadd("opsGreeters", "Arrivals Meet & Greet", 20000, { "doors" }, "greeters", { -30, 56 }, { cat = { comfort = 0.02 } })
	oadd("opsShuttle", "Airport Shuttle Bus", 40000, { "bus" }, "shuttle", { 140, 9 }, { inc = 30, cnt = { transport = 1 } })
	oadd("opsTaxis", "Taxi Fleet", 30000, { "taxi" }, "taxis", { 150, 50 }, { inc = 25, cnt = { transport = 1 } })
	oadd("opsTugs", "Baggage Tugs", 45000, { "apron", "belt" }, "tugs", { -150, 330 }, { cat = { checkin = 0.03 } })
	oadd("opsFuel", "Fuel Truck", 50000, { "fuel", "apron" }, "fueltruck", { 150, 330 }, { cat = { gates = 0.02 } })
	oadd("opsFollow", "Follow-Me Car", 35000, { "taxiway" }, "followme", { -270, 470 }, { cat = { gates = 0.02 } })
	oadd("opsFireTruck", "Fire Truck Patrol", 60000, { "fire" }, "firetruck", { 100, 566 }, { cat = { security = 0.02 } })
	oadd("opsPolice", "Police Patrol Car", 40000, { "xpolice" }, "policecar", { -210, 50 }, { cat = { security = 0.03 } })
	oadd("opsCatering", "Catering Truck", 45000, { "xcatering", "xcargoapron" }, "cateringtruck", { 10, 700 }, { inc = 20 })
	oadd("opsSweeper", "Runway Sweeper", 55000, { "xrunway2" }, "sweeper", { -200, 762 }, { cat = { clean = 0.02 } })
	oadd("opsGPU", "Ground Power Units", 20000, { "bridge1" }, "gpu", { 0, 360 }, { cat = { gates = 0.02 } })
	oadd("opsILS", "ILS Landing Antennas", 40000, { "runway" }, "ils", { 280, 580 }, { cat = { gates = 0.03 } })
	oadd("opsFence", "Perimeter Fence", 25000, { "runway" }, "fence", { -280, 600 }, { cat = { security = 0.03 } })
	oadd("opsAmbulance", "Airport Ambulance", 45000, { "f2medical" }, "ambulance", { -150, 50 }, { cat = { comfort = 0.02 } })
	oadd("opsRental", "Car Rental Shuttle", 30000, { "rental" }, "rentalshuttle", { 200, 50 }, { inc = 20 })
	oadd("opsHotelVan", "Hotel Shuttle Van", 35000, { "hvalet" }, "hotelvan", { 260, 50 }, { inc = 20 })
	oadd("opsCrewBus", "Crew Bus", 40000, { "apron", "opsTugs" }, "crewbus", { 0, 336 }, { cat = { gates = 0.02 } })
	oadd("opsMail", "Air Mail Truck", 40000, { "cargo" }, "mailtruck", { -200, 9 }, { inc = 30 })
	oadd("opsPushback", "Pushback Tugs", 30000, { "bridge1" }, "pushback", { -60, 360 }, { cat = { gates = 0.02 } })
	oadd("opsSalute", "Water Salute Fire Trucks", 50000, { "fire", "taxiway" }, "watersalute", { -230, 470 }, { cat = { comfort = 0.02 } })
	oadd("opsGuard", "Runway Guard Lights", 25000, { "runway" }, "guardlights", { -170, 480 }, { cat = { gates = 0.02, security = 0.02 } })
	oadd("opsSkyTrack", "Sky Train Track", 200000, { "train", "hotel" }, "skytrack", { -40, 9 }, { cnt = { transport = 1 } })
	oadd("opsSkyTrain", "Sky Train", 300000, { "opsSkyTrack" }, "skytrain", { 40, 9 }, { inc = 150, cnt = { transport = 2 } })
end

-- three new kinds of staff for the hotel
table.insert(STAFF, { key = "receptionist", name = "Receptionist", fee = 2500, need = "reception", capbase = 0, capper = 2,
	cat = { comfort = 0.02 }, desc = "Works the hotel reception. Guests check in faster.", shirt = "Navy blue" })
table.insert(STAFF, { key = "housekeeper", name = "Housekeeper", fee = 2000, need = "hroom", capbase = 0, capper = 0.25,
	cat = { clean = 0.02 }, desc = "Cleans hotel rooms. Guests pay more per night.", shirt = "Institutional white" })
table.insert(STAFF, { key = "bellhop", name = "Bellhop", fee = 1800, need = "reception", capbase = 0, capper = 2,
	cat = { comfort = 0.01 }, desc = "Carries guests' bags. More hotel guests come.", shirt = "Bright red" })
