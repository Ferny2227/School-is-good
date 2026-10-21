-- ==== s27_expansion.lua
------------------------------------------------------------------ the expansion: left strip (x -300..-210) and the back (z 630..900)
function K.xparking(b)
	U.blk(b, "Lot", 82, 0.3, 140, -255, 0, 130, "Dark stone grey", "Concrete")
	for z = 66, 194, 12 do
		U.blk(b, "Line", 14, 0.05, 0.4, -285, 0.3, z, "Institutional white", nil, { nc = true })
		U.blk(b, "Line", 14, 0.05, 0.4, -225, 0.3, z, "Institutional white", nil, { nc = true })
	end
	local cols = { "Bright red", "Bright blue", "Institutional white", "Really black", "Bright yellow", "Bright green", "Royal purple", "Brown" }
	for i = 0, 7 do car(b, i % 2 == 0 and -285 or -225, 72 + i * 15, 90, cols[i + 1]) end
	local s = U.blk(b, "Sign", 12, 3, 0.4, -255, 6, 62, "Bright blue", "SmoothPlastic")
	U.text(s, "OVERFLOW P", Color3.new(1, 1, 1), nil, "Front")
	U.blk(b, "Pole", 0.4, 6, 0.4, -255, 0, 62.4, "Dark stone grey", "Metal")
	PT(b, "arrive", { p = Vector3.new(-240, 0, 130) })
end
function K.xev(b)
	U.blk(b, "Pad", 40, 0.3, 14, -255, 0, 212, "Medium stone grey", "Concrete")
	for i = 0, 3 do
		local x = -270 + i * 10
		U.blk(b, "Charger", 1.6, 4.4, 1.2, x, 0.3, 218, "Institutional white", "SmoothPlastic")
		U.blk(b, "ChargerLight", 1, 1, 0.2, x, 3, 217.3, "Lime green", "Neon")
	end
	car(b, -270, 210, 0, "Institutional white") car(b, -250, 210, 0, "Bright blue")
	U.blk(b, "Canopy", 42, 0.6, 16, -255, 9, 212, "Lime green", "SmoothPlastic")
	for _, x in ipairs({ -274, -236 }) do U.blk(b, "Post", 0.6, 9, 0.6, x, 0, 219, "Dark stone grey", "Metal") end
end
function K.xgas(b)
	U.blk(b, "Forecourt", 60, 0.3, 50, -255, 0, 254, "Medium stone grey", "Concrete")
	U.blk(b, "Canopy", 34, 1.2, 18, -255, 10, 246, "Institutional white", "SmoothPlastic")
	U.blk(b, "CanopyStripe", 34.2, 0.6, 18.2, -255, 10.6, 246, "Bright red", "SmoothPlastic")
	for _, x in ipairs({ -266, -255, -244 }) do
		U.blk(b, "Pump", 2, 4.6, 1.6, x, 0.3, 246, "Bright red", "SmoothPlastic")
		U.blk(b, "PumpScreen", 1.4, 1, 0.1, x, 3, 245.15, "Lime green", "Neon")
		U.blk(b, "Pillar", 1, 9.7, 1, x, 0.3, 249, "Light stone grey", "Metal")
	end
	U.blk(b, "Shop", 26, 10, 12, -266, 0.3, 272, "Institutional white", "SmoothPlastic")
	U.blk(b, "ShopWindow", 20, 4, 0.2, -266, 2.3, 265.9, "Pastel light blue", "Glass", { tr = 0.4 })
	local s = U.blk(b, "Sign", 16, 2.4, 0.3, -266, 10.3, 265.8, "Bright red", "SmoothPlastic")
	U.text(s, "GAS & SNACKS", Color3.new(1, 1, 1), nil, "Front")
	U.blk(b, "PricePole", 1, 14, 1, -226, 0.3, 236, "Dark stone grey", "Metal")
	local p = U.blk(b, "PriceSign", 8, 5, 0.6, -226, 14.3, 236, "Institutional white", "SmoothPlastic")
	U.text(p, "FUEL\n$2.99", Color3.new(0.8, 0, 0), nil, "Front")
	car(b, -260, 240, 0, "Bright yellow")
end
function K.xpolice(b)
	U.blk(b, "Station", 40, 12, 22, -258, 0, 300, "Institutional white", "Concrete")
	U.blk(b, "Stripe", 40.2, 2, 22.2, -258, 8, 300, "Bright blue", "SmoothPlastic")
	U.blk(b, "Door", 6, 8, 0.3, -246, 0, 288.9, "Pastel light blue", "Glass", { tr = 0.4 })
	local s = U.blk(b, "Sign", 18, 2.6, 0.3, -258, 12.3, 288.8, "Navy blue", "SmoothPlastic")
	U.text(s, "AIRPORT POLICE", Color3.new(1, 1, 1), nil, "Front")
	for i, x in ipairs({ -232, -222 }) do
		car(b, x, 300, 0, "Institutional white")
		U.light(U.blk(b, "Siren", 3, 0.5, 1, x, 5, 300.5, i == 1 and "Bright blue" or "Really red", "Neon"), i == 1 and Color3.new(0.2, 0.3, 1) or Color3.new(1, 0.1, 0.1), 12)
	end
	M.person(b.model, b.cf * U.L(-240, 0.3, 286, 0), { shirt = "Navy blue", pants = "Really black", hat = "cap", hatColor = "Navy blue", tie = "Really black" }, "Police Officer")
end
function K.xstand(b, o)
	local x = o.x
	U.blk(b, "StandApron", 46, 0.3, 124, x, 0, 384, "Medium stone grey", "Concrete")
	U.blk(b, "LeadIn", 0.8, 0.05, 110, x, 0.3, 390, "Bright yellow", nil, { nc = true })
	U.blk(b, "StopBar", 8, 0.05, 0.8, x, 0.3, 356, "Bright yellow", nil, { nc = true })
	U.blk(b, "Edge", 46, 0.05, 1, x, 0.3, 445, "Bright yellow", nil, { nc = true })
	local s = U.blk(b, "StandSign", 8, 3, 0.4, x, 1, 352, "Bright yellow", "SmoothPlastic")
	U.text(s, "STAND " .. (o.n == 5 and "A" or "B"), Color3.new(0, 0, 0), nil, "Back")
	U.blk(b, "Stairs", 4, 6, 10, x - 9, 0.3, 380, "Institutional white", "SmoothPlastic")
	A.gatePlane(b.plot, o.n, x, { count = 2 })
end

------------------------------------------------------------------ the back: second runway, cargo, maintenance
function K.xrunway2(b)
	U.blk(b, "TaxiLane", PLOT_W - 10, 0.3, 16, 0, 0, 775, "Dark stone grey", "Concrete")
	for x = -285, 285, 14 do U.blk(b, "Line", 7, 0.05, 0.6, x, 0.3, 775, "Bright yellow", nil, { nc = true }) end
	for _, x in ipairs({ -280, 280 }) do U.blk(b, "Connector", 22, 0.3, 10, x, 0, 787, "Dark stone grey", "Concrete") end
	U.blk(b, "Runway2", PLOT_W - 10, 0.3, 60, 0, 0, 820, "Really black", "Concrete")
	for x = -255, 255, 25 do U.blk(b, "Center", 12, 0.05, 1, x, 0.3, 820, "Institutional white", nil, { nc = true }) end
	for _, x in ipairs({ -285, 285 }) do for z = 796, 844, 6 do U.blk(b, "Threshold", 10, 0.05, 2.4, x, 0.3, z, "Institutional white", nil, { nc = true }) end end
	for _, e in ipairs({ { -266, "09R", -90 }, { 266, "27L", 90 } }) do
		local n = U.P(b, "Number", Vector3.new(16, 0.05, 10), U.L(e[1], 0.33, 820, e[3]), "Really black", nil, { nc = true })
		U.text(n, e[2], Color3.new(1, 1, 1), nil, "Top")
	end
	U.blk(b, "EdgeL", PLOT_W - 10, 0.05, 1, 0, 0.3, 791, "Institutional white", nil, { nc = true })
	U.blk(b, "EdgeR", PLOT_W - 10, 0.05, 1, 0, 0.3, 849, "Institutional white", nil, { nc = true })
	b.plot.hasRunway2 = true
	A.startDepartures(b.plot)
end
function K.xrw2lights(b)
	for x = -290, 290, 25 do
		for _, z in ipairs({ 789.6, 850.4 }) do U.blk(b, "RunwayLight", 0.8, 0.5, 0.8, x, 0.3, z, x < 0 and "Lime green" or "Really red", "Neon", { nc = true }) end
	end
	for i = 1, 6 do U.blk(b, "Approach", 1, 1, 3, -296, 0.3, 820 + (i - 3.5) * 4, "Bright yellow", "Neon", { nc = true }) end
end
function K.xcargoapron(b)
	U.blk(b, "CargoApron", 290, 0.3, 126, -151, 0, 703, "Medium stone grey", "Concrete")
	for _, x in ipairs({ -245, -180, -115 }) do
		U.blk(b, "LeadIn", 0.8, 0.05, 100, x, 0.3, 712, "Bright yellow", nil, { nc = true })
		U.blk(b, "StopBar", 8, 0.05, 0.8, x, 0.3, 668, "Bright yellow", nil, { nc = true })
	end
	local cols = { "Bright red", "Bright blue", "Bright green", "Bright orange" }
	for i = 0, 3 do U.blk(b, "Container", 8, 6, 6, -60 + i * 10, 0.3, 652, cols[i + 1], "CorrodedMetal") end
	for i = 0, 2 do U.blk(b, "Dolly", 6, 1, 8, -55 + i * 9, 0.3, 676, "Light stone grey", "Metal") U.blk(b, "ULD", 5, 4, 6, -55 + i * 9, 1.3, 676, "Light stone grey", "CorrodedMetal") end
	U.blk(b, "Tug", 4, 2.6, 5, -40, 0.3, 690, "Bright yellow", "SmoothPlastic")
	local s = U.blk(b, "Sign", 30, 4, 0.4, -151, 1, 641, "Bright orange", "SmoothPlastic")
	U.text(s, "CARGO", Color3.new(1, 1, 1), nil, "Back")
	SPOT(b, "handler", -70, 0.3, 665, 0)
	SPOT(b, "handler", -48, 0.3, 700, 90)
end
function K.xcargojet(b, o)
	U.blk(b, "StandMark", 10, 0.05, 2, o.x, 0.3, 672, "Institutional white", nil, { nc = true })
	A.gatePlane(b.plot, o.n, o.x, { z = 700, rz = 820, count = 2, dep = FLY.cargoDeparture, arr = FLY.cargoArrival, needs = "hasRunway2",
		tail = U.pick({ "Bright orange", "Brown", "Navy blue" }), cargo = true, name = "Cargo " .. (o.n - 6) })
end
function K.xmhangar(b)
	U.blk(b, "Floor", 130, 0.3, 76, 150, 0, 700, "Medium stone grey", "Concrete")
	U.blk(b, "Back", 130, 26, 1, 150, 0, 662, "Light stone grey", "CorrodedMetal")
	U.blk(b, "Side", 1, 26, 76, 85, 0, 700, "Light stone grey", "CorrodedMetal")
	U.blk(b, "Side", 1, 26, 76, 215, 0, 700, "Light stone grey", "CorrodedMetal")
	U.P(b, "Roof", Vector3.new(132, 8, 38.5), U.L(150, 30, 681), "Medium stone grey", "CorrodedMetal", { class = "WedgePart" })
	U.P(b, "Roof", Vector3.new(132, 8, 38.5), U.L(150, 30, 719, 180), "Medium stone grey", "CorrodedMetal", { class = "WedgePart" })
	U.blk(b, "DoorTop", 130, 4, 1, 150, 22, 738, "Light stone grey", "CorrodedMetal")
	local s = U.blk(b, "Sign", 50, 4, 0.4, 150, 22, 738.7, b.plot.color, "SmoothPlastic")
	U.text(s, "MAINTENANCE", Color3.new(1, 1, 1), nil, "Back")
	M.airliner(b.model, b.cf * U.L(150, 7.3, 702, 180), "Institutional white", "Airliner In Maintenance")
	U.blk(b, "Scaffold", 6, 14, 6, 120, 0.3, 702, "Bright yellow", "DiamondPlate", { tr = 0.3 })
	for _, x in ipairs({ 110, 190 }) do SPOT(b, "mechanic", x, 0.3, 720, 0) end
end
function K.xcatering(b)
	U.blk(b, "Kitchen", 50, 12, 28, 45, 0, 659, "Institutional white", "SmoothPlastic")
	U.blk(b, "Stripe", 50.2, 2, 28.2, 45, 9, 659, b.plot.color, "SmoothPlastic")
	local s = U.blk(b, "Sign", 26, 3, 0.3, 45, 12.2, 673.2, "Really black", "SmoothPlastic")
	U.text(s, "SKY CATERING", Color3.new(1, 0.85, 0.3), nil, "Back")
	for i, x in ipairs({ 30, 60 }) do
		U.blk(b, "TruckCab", 6, 5, 4, x, 0.6, 683, "Institutional white", "SmoothPlastic")
		U.blk(b, "TruckBox", 7, 7, 12, x, 0.6, 692, "Institutional white", "SmoothPlastic")
		U.blk(b, "TruckLogo", 0.2, 3, 8, x + 3.6, 3, 692, b.plot.color, "SmoothPlastic")
	end
	SPOT(b, "chef", 45, 0, 676, 0)
end
function K.xdeice(b)
	U.blk(b, "Pad", 50, 0.3, 38, 45, 0, 741, "Dark stone grey", "Concrete")
	U.blk(b, "Border", 50, 0.05, 1, 45, 0.3, 722.5, "Bright orange", nil, { nc = true })
	for _, x in ipairs({ 28, 62 }) do
		U.blk(b, "Truck", 5, 4, 10, x, 0.6, 745, "Bright orange", "SmoothPlastic")
		U.P(b, "Boom", Vector3.new(1, 1, 12), U.L(x, 9, 742, 0, 35), "Light stone grey", "Metal")
		U.blk(b, "Bucket", 2.4, 2, 2.4, x, 11.5, 736.5, "Bright yellow", "Metal")
	end
end
function K.xwater(b)
	for _, p in ipairs({ { -4, -4 }, { 4, -4 }, { -4, 4 }, { 4, 4 } }) do U.blk(b, "Leg", 1, 34, 1, 272 + p[1], 0, 655 + p[2], "Light stone grey", "Metal") end
	U.cyl(b, "Tank", 16, 10, 272, 34, 655, "Institutional white", "Metal")
	U.ball(b, "Dome", 16, 272, 44, 655, "Institutional white", "Metal")
	local s = U.blk(b, "Band", 16.4, 3, 0.2, 272, 38, 646.9, b.plot.color, "SmoothPlastic")
	U.text(s, "AIRPORT", Color3.new(1, 1, 1), nil, "Front")
end
function K.xtower2(b)
	U.cyl(b, "Shaft", 7, 42, 272, 0, 705, "Light stone grey", "Concrete")
	U.cyl(b, "Cab", 13, 7, 272, 42, 705, "Pastel light blue", "Glass", { tr = 0.35 })
	U.cyl(b, "CabFloor", 14, 1, 272, 41.5, 705, "Dark stone grey", "Metal")
	U.cyl(b, "Roof", 15, 1.2, 272, 49, 705, b.plot.color, "SmoothPlastic")
	U.light(U.ball(b, "Beacon", 1, 272, 51, 705, "Lime green", "Neon"), Color3.new(0.3, 1, 0.3), 20)
	SPOT(b, "atc", 272, 42.5, 708, 0)
end
function K.xweather(b)
	U.cyl(b, "Mast", 0.8, 16, 272, 0, 745, "Light stone grey", "Metal")
	U.ball(b, "RadarDome", 6, 262, 3, 745, "Institutional white", "SmoothPlastic")
	U.blk(b, "Hut", 6, 4, 6, 262, 0, 752, "Institutional white")
	local cups = {}
	for a = 0, 240, 120 do
		local x, z = 272 + math.cos(math.rad(a)) * 1.6, 745 + math.sin(math.rad(a)) * 1.6
		table.insert(cups, U.ball(b, "Cup", 0.8, x, 16.4, z, "Bright red", nil, { nc = true }))
		table.insert(cups, U.blk(b, "CupArm", 0.2, 0.2, 1.6, (x + 272) / 2, 16.3, (z + 745) / 2, "Light stone grey", nil, { nc = true }, -a + 90))
	end
	U.spin(cups, b.cf * U.L(272, 16.4, 745), "y", 200)
	U.P(b, "Vane", Vector3.new(0.2, 1, 2.4), U.L(272, 13, 746), "Bright orange", "Metal")
end
function K.xsolar(b)
	for row = 0, 2 do
		local z = 864 + row * 12
		for i = 0, 8 do
			local x = -270 + i * 40
			U.P(b, "SolarPanel", Vector3.new(38, 0.3, 8), U.L(x, 3.2, z, 0, 25), "Navy blue", "SmoothPlastic", { refl = 0.25 })
			U.blk(b, "Stand", 30, 2.4, 0.6, x, 0, z + 1, "Light stone grey", "Metal")
		end
	end
	local s = U.blk(b, "Sign", 20, 3, 0.3, -120, 0.5, 857, "Bright green", "SmoothPlastic")
	U.text(s, "SOLAR FARM", Color3.new(1, 1, 1), nil, "Back")
end
function K.xwind(b)
	for _, x in ipairs({ 120, 200, 280 }) do
		U.cyl(b, "Tower", 2.6, 50, x, 0, 880, "Institutional white", "SmoothPlastic")
		U.blk(b, "Nacelle", 3, 3, 7, x, 49, 881, "Institutional white", "SmoothPlastic")
		local hub = U.ball(b, "Hub", 2.4, x, 50.5, 877, "Institutional white", "SmoothPlastic")
		local blades = { hub }
		for a = 0, 240, 120 do
			local r = math.rad(a)
			table.insert(blades, U.P(b, "Blade", Vector3.new(1.4, 16, 0.4), U.L(x + math.sin(r) * 8.4, 50.5 + math.cos(r) * 8.4, 876.6, 0, 0, -a), "Institutional white", "SmoothPlastic", { nc = true }))
		end
		U.spin(blades, b.cf * U.L(x, 50.5, 876.6), "z", 45)
	end
end
