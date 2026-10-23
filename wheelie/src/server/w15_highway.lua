-- ==== w15_highway.lua
------------------------------------------------------------------ THE HIGHWAY: a long highway north of the city, with traffic
-- Four lanes (two each way) and a concrete barrier down the middle, 1880 studs from one tunnel to the other - the
-- longest straight in the game. The three city streets lead onto it. Cars, trucks and buses drive along it all the
-- time: every player's computer moves them (from the game clock, so everyone sees the same traffic) - riding into
-- one knocks you off your bike.
local HW = { x1 = -940, x2 = 940, z = 480 }      -- the middle of the highway
HW.L = HW.x2 - HW.x1
HW.lanes = { { z = 462, dir = 1, speed = 55 }, { z = 473, dir = 1, speed = 75 }, { z = 487, dir = -1, speed = 60 }, { z = 498, dir = -1, speed = 82 } }
w("HighwayGround", 1920, 2, 160, 0, -2, 480, "Bright green", "Grass")
w("Highway", HW.L, 0.3, 50, 0, 0, HW.z, "Dark stone grey", "Concrete")
-- lane lines and edge lines
for _, lz in ipairs({ 467.5, 492.5 }) do
	for x = HW.x1 + 10, HW.x2 - 10, 30 do w("LaneLine", 10, 0.05, 0.5, x, 0.3, lz, "Institutional white", "SmoothPlastic", { nc = true }) end
end
for _, ez in ipairs({ 457, 503 }) do w("EdgeLine", HW.L, 0.05, 0.6, 0, 0.3, ez, "Institutional white", "SmoothPlastic", { nc = true }) end
for _, ez in ipairs({ 478.4, 481.6 }) do w("EdgeLine", HW.L, 0.05, 0.5, 0, 0.3, ez, "New Yeller", "SmoothPlastic", { nc = true }) end
-- the concrete barrier down the middle (gaps where the streets meet it, so you can cross)
local gaps = { -220, 0, 220 }
local x = HW.x1
for _, gx in ipairs(gaps) do
	w("Barrier", (gx - 18) - x, 4.5, 2, (x + gx - 18) / 2, 0.3, HW.z, "Light stone grey", "Concrete")
	x = gx + 18
end
w("Barrier", HW.x2 - x, 4.5, 2, (x + HW.x2) / 2, 0.3, HW.z, "Light stone grey", "Concrete")
-- the three streets run up onto the highway
for _, gx in ipairs(gaps) do road(gx - 15, EDGE, gx + 15, 455) end
-- an outside wall, and the tunnels at both ends (the traffic comes out of one and goes into the other)
w("Hedge", 1900, 8, 4, 0, 0, 512, "Dark green", "Grass")
w("EdgeWall", 1900, 60, 2, 0, 8, 513, "White", nil, { tr = 1 })
for _, sx in ipairs({ -1, 1 }) do
	local tx = sx * 952
	w("Tunnel", 24, 26, 120, tx, 0, 470, "Medium stone grey", "Concrete")
	for _, tz in ipairs({ 468, 492 }) do
		w("TunnelMouth", 0.6, 12, 20, tx - sx * 12.1, 0.3, tz, "Really black", "SmoothPlastic")
	end
	local ts = w("TunnelSign", 0.6, 4, 30, tx - sx * 12.2, 15, 480, "Dark green", "SmoothPlastic")
	sign(ts, sx < 0 and "WHEELIE CITY  >" or "<  WHEELIE CITY", sx < 0 and "Right" or "Left", Color3.new(1, 1, 1))
end
-- big green signs over the road, and lights down the middle
for _, gx in ipairs({ -520, 520 }) do
	for _, gz in ipairs({ 455, 505 }) do w("GantryLeg", 1.2, 20, 1.2, gx, 0, gz, "Medium stone grey", "Metal") end
	w("Gantry", 1.2, 1.2, 52, gx, 19, HW.z, "Medium stone grey", "Metal")
	local g1 = w("HighwaySign", 0.6, 6, 22, gx, 12.5, 468, "Dark green", "SmoothPlastic")
	sign(g1, "HIGHWAY 66\nEXIT: WHEELIE CITY", "Left", Color3.new(1, 1, 1))
	local g2 = w("HighwaySign", 0.6, 6, 22, gx, 12.5, 492, "Dark green", "SmoothPlastic")
	sign(g2, "HIGHWAY 66\nEXIT: WHEELIE CITY", "Right", Color3.new(1, 1, 1))
end
for lx = HW.x1 + 40, HW.x2 - 40, 90 do
	w("HighwayLamp", 0.6, 16, 0.6, lx, 4.8, HW.z, "Dark stone grey", "Metal")
	w("HighwayLampArm", 0.4, 0.4, 12, lx, 20.8, HW.z, "Dark stone grey", "Metal")
end

------------------------------------------------------------------ the traffic
-- Each vehicle is built hidden far below the map at CAR_HOME; players' computers move it along its lane.
local TRAFFIC = model(WORLD, "Traffic")
local CAR_HOME = CFrame.new(0, -500, 0)
local CAR_COLORS = { "Really red", "Bright blue", "Institutional white", "Black", "Medium stone grey", "Bright yellow", "Dark green", "Bright orange" }
local function vehicle(kind, color)
	local m = model(TRAFFIC, "Vehicle")
	local function part(n, size, off, c, mat, shape)
		local q = P(m, n, size, CAR_HOME * off, c, mat or "SmoothPlastic", { shape = shape, nc = true })
		return q
	end
	local len, wid
	if kind == "truck" then
		len, wid = 26, 6
		part("Cab", V(6, 6, 6), CFrame.new(0, 4, -10), color)
		part("Windshield", V(5.6, 2.2, 0.2), CFrame.new(0, 5.4, -13.05), "Black", "Glass")
		part("Trailer", V(6.4, 8, 18), CFrame.new(0, 5.4, 3), "Institutional white", "Metal")
		part("Stripe", V(6.5, 1, 17), CFrame.new(0, 3.2, 3), color)
		for _, z in ipairs({ -10, 0, 8 }) do
			for _, sx in ipairs({ -1, 1 }) do part("Wheel", V(1, 2.6, 2.6), CFrame.new(sx * 2.8, 1.3, z) * CFrame.Angles(0, math.pi / 2, 0), "Really black", "SmoothPlastic", "cyl") end
		end
	elseif kind == "bus" then
		len, wid = 24, 6
		part("Body", V(6.4, 7, 24), CFrame.new(0, 4.5, 0), "Bright yellow")
		part("Windows", V(6.5, 2.2, 21), CFrame.new(0, 6, 0.5), "Black", "Glass")
		part("Front", V(6, 2.6, 0.2), CFrame.new(0, 6, -12.05), "Black", "Glass")
		part("Stripe", V(6.5, 0.4, 24.1), CFrame.new(0, 3.6, 0), "Black")
		for _, z in ipairs({ -8, 8 }) do
			for _, sx in ipairs({ -1, 1 }) do part("Wheel", V(1, 2.6, 2.6), CFrame.new(sx * 3, 1.3, z) * CFrame.Angles(0, math.pi / 2, 0), "Really black", "SmoothPlastic", "cyl") end
		end
	else
		local suv = kind == "suv"
		len, wid = suv and 12 or 11, 5
		part("Body", V(5, suv and 2.6 or 2, len), CFrame.new(0, suv and 2.2 or 1.8, 0), color)
		part("Top", V(4.6, suv and 2.4 or 1.8, suv and 7.5 or 5.5), CFrame.new(0, suv and 4.6 or 3.7, suv and 0.8 or 0.5), color)
		part("Glass", V(4.7, suv and 1.8 or 1.4, suv and 7.6 or 5.6), CFrame.new(0, suv and 4.7 or 3.7, suv and 0.8 or 0.5), "Black", "Glass")
		part("Headlights", V(4, 0.5, 0.2), CFrame.new(0, 2, -len / 2 - 0.05), "Institutional white", "Neon")
		part("Taillights", V(4, 0.5, 0.2), CFrame.new(0, 2, len / 2 + 0.05), "Really red", "Neon")
		for _, z in ipairs({ -len / 2 + 2.4, len / 2 - 2.4 }) do
			for _, sx in ipairs({ -1, 1 }) do part("Wheel", V(1, 2.2, 2.2), CFrame.new(sx * 2.4, 1.1, z) * CFrame.Angles(0, math.pi / 2, 0), "Really black", "SmoothPlastic", "cyl") end
		end
	end
	return m, len, wid
end
local KINDS = { "car", "car", "suv", "car", "truck", "suv", "bus", "car" }
local nVehicles = 0
for li, lane in ipairs(HW.lanes) do
	for k = 1, 4 do
		nVehicles = nVehicles + 1
		local kind = KINDS[(li * 3 + k) % #KINDS + 1]
		local m, len, wid = vehicle(kind, CAR_COLORS[(li * 5 + k * 3) % #CAR_COLORS + 1])
		local v = Instance.new("StringValue")
		v.Name = "Lane"
		-- "z dir speed offset length width"
		v.Value = string.format("%d %d %d %d %d %d", lane.z, lane.dir, lane.speed, math.floor((k - 1) * HW.L / 4 + li * 97), len, wid)
		v.Parent = m
	end
end
