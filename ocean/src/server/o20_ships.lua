------------------------------------------------------------------ THE BOATS (voted in the lobby): Cruise Liner, Pirate Galleon, Navy Destroyer
-- Each is built fresh every round at SHIP_AT, in the boat's own frame: x across, y up from the waterline, z along
-- (the bow is at -z). Rooms are real: walls with doorways and windows, furniture inside. Every part stays anchored
-- where it was built on the server; the server works out how the boat moves (ship.dy/pitch/roll/yaw) and sends it in
-- SeaState.ShipCF, and each player's computer moves ALL the boat's parts together with it (OceanClient), smoothly
-- every frame. Some pieces are "breakable": they snap off as the boat takes damage.
local ship = nil   -- { kind, model, root, hp, max, len, wid, deck, hullY, breakable, lifeboats, spots }

local function shipBase(dy, pitch, roll, yaw) return ShipCFrame(SHIP_AT, SEA.level, dy or 0, pitch or 0, roll or 0, yaw or 0) end

-- a builder for one boat: B.part(...) in boat coordinates, rooms, furniture
local function newBuilder(name)
	local B = { model = model(WORLD, name), parts = {}, breakable = {}, spots = {}, lifeboats = {} }
	local base = shipBase(0)
	B.base = base
	function B.part(n, size, lcf, color, mat, opt, br)
		if opt and opt.class == "Seat" then opt.class = nil end      -- no seats on the boats: chairs are just chairs
		local p = P(B.model, n, size, base * lcf, color, mat, opt)
		table.insert(B.parts, p)
		if br then table.insert(B.breakable, p) end
		return p
	end
	-- a box sitting on y0, centred on x, z
	function B.box(n, sx, sy, sz, x, y0, z, color, mat, opt, br)
		return B.part(n, V(sx, sy, sz), CFrame.new(x, y0 + sy / 2, z), color, mat, opt, br)
	end
	function B.spot(x, y, z) table.insert(B.spots, CFrame.new(x, y + 3, z)) end
	-- walls of a room: w across (x), l along (z), h high, standing on y0. doors = { n = offset, s = .., e = .., w = .. }
	-- (n = the bow side). Windows in the outside walls unless opt.noWindows. opt.skip = { n = true } leaves a wall out.
	function B.room(n, cx, y0, cz, w, l, h, doors, opt)
		opt = opt or {}
		doors = doors or {}
		local color = opt.color or "Institutional white"
		local function wallRun(side, len, fixedAt, along, door)
			-- pieces of wall between from..to along the wall, with a doorway at door (offset from the middle)
			local pieces = {}
			if door then
				table.insert(pieces, { -len / 2, door - 2.5 })
				table.insert(pieces, { door + 2.5, len / 2 })
			else
				table.insert(pieces, { -len / 2, len / 2 })
			end
			local function at(a, y, sizeA, sy)
				if along == "x" then return V(sizeA, sy, 0.6), CFrame.new(cx + a, y, fixedAt) end
				return V(0.6, sy, sizeA), CFrame.new(fixedAt, y, cz + a)
			end
			for _, pc in ipairs(pieces) do
				local a0, a1 = pc[1], pc[2]
				local sz = a1 - a0
				if sz > 0.2 then
					local mid = (a0 + a1) / 2
					if opt.noWindows or sz < 5 then
						local s, cf = at(mid, y0 + h / 2, sz, h)
						B.part(n .. "Wall", s, cf, color, "SmoothPlastic")
					else
						local s, cf = at(mid, y0 + 1.5, sz, 3)
						B.part(n .. "Wall", s, cf, color, "SmoothPlastic")
						s, cf = at(mid, y0 + 4.5, sz, 3)
						B.part(n .. "Window", s, cf, "Pastel light blue", "Glass", { tr = 0.45 }, true)
						s, cf = at(mid, y0 + 6 + (h - 6) / 2, sz, h - 6)
						B.part(n .. "Wall", s, cf, color, "SmoothPlastic")
					end
				end
			end
			if door and h > 7.5 then
				local s, cf = at(door, y0 + 7 + (h - 7) / 2, 5, h - 7)
				B.part(n .. "Lintel", s, cf, color, "SmoothPlastic")
			end
		end
		local skip = opt.skip or {}
		if not skip.n then wallRun("n", w, cz - l / 2, "x", doors.n) end
		if not skip.s then wallRun("s", w, cz + l / 2, "x", doors.s) end
		if not skip.w then wallRun("w", l, cx - w / 2, "z", doors.w) end
		if not skip.e then wallRun("e", l, cx + w / 2, "z", doors.e) end
		B.box(n .. "Floor", w - 0.6, 0.3, l - 0.6, cx, y0, cz, opt.floor or "Brick yellow", opt.floorMat or "WoodPlanks", { nc = false })
		if opt.ceiling then B.box(n .. "Ceiling", w + 0.6, 0.6, l + 0.6, cx, y0 + h, cz, opt.ceilColor or color, "SmoothPlastic") end
		local lamp = B.box(n .. "Lamp", 2, 0.3, 2, cx, y0 + h - 0.4, cz, "Institutional white", "Neon", { nc = true })
		light(lamp, Color3.new(1, 0.92, 0.75), math.max(w, l), 1.2)
		B.spot(cx, y0, cz)
		return lamp
	end
	function B.bed(x, y0, z, ry, color)
		local cf = CFrame.new(x, y0, z) * CFrame.Angles(0, math.rad(ry or 0), 0)
		B.part("Bed", V(4, 1.4, 7), cf * CFrame.new(0, 0.7, 0), "Brown", "Wood")
		B.part("Mattress", V(3.8, 0.6, 6.6), cf * CFrame.new(0, 1.7, 0), color or "Institutional white", "Fabric")
		B.part("Pillow", V(3, 0.5, 1.4), cf * CFrame.new(0, 2.2, 2.6), "Institutional white", "Fabric")
		B.part("Blanket", V(3.9, 0.2, 4), cf * CFrame.new(0, 2.05, -1.2), color or "Bright blue", "Fabric")
	end
	function B.tableSet(x, y0, z, n, color)
		B.box("Table", 4, 0.4, 4, x, y0 + 2.6, z, color or "Brown", "Wood")
		B.box("TableLeg", 0.6, 2.6, 0.6, x, y0, z, "Dark stone grey", "Metal")
		for i = 1, n or 4 do
			local a = i / (n or 4) * math.pi * 2
			B.part("Chair", V(1.8, 1, 1.8), CFrame.new(x + math.cos(a) * 3.2, y0 + 1.5, z + math.sin(a) * 3.2), "Bright red", "Fabric", { class = "Seat" })
		end
	end
	function B.lifeboat(x, y0, z, color)
		local lbm = model(B.model, "Lifeboat")
		local function lp(n, size, lcf, c)
			local p = P(lbm, n, size, base * lcf, c, "SmoothPlastic")
			table.insert(B.parts, p)
			return p
		end
		local hull = lp("LifeboatHull", V(7, 2.4, 16), CFrame.new(x, y0, z), color or "Bright orange")
		lp("LifeboatFloor", V(6, 0.4, 15), CFrame.new(x, y0 + 1.3, z), "Institutional white")
		for _, e in ipairs({ -1, 1 }) do lp("LifeboatSide", V(0.4, 1.4, 15), CFrame.new(x + e * 3.3, y0 + 1.9, z), color or "Bright orange") end
		table.insert(B.lifeboats, { model = lbm, side = x < 0 and -1 or 1, z = z })
	end
	function B.ladder(x, y0, z, h)
		B.box("Ladder", 2, h, 2, x, y0, z, "Dark stone grey", "Metal", { class = "TrussPart" })
	end
	function B.halloween(len, wid, deck)
		if theme ~= "Halloween" then return end
		for i = 0, 7 do
			local z = -len / 2 + 12 + i * (len - 24) / 7
			for _, s in ipairs({ -1, 1 }) do
				table.insert(B.parts, pumpkin(B.model, base * CFrame.new(s * (wid / 2 - 2), deck + 2.2, z), 2))
			end
		end
		for _, c in ipairs(B.model:GetChildren()) do
			if c.Name == "Stem" then table.insert(B.parts, c) end
		end
	end
	return B
end

local SHIPS = {}
------------------------------------------------------------------ 1. CRUISE LINER: dining room, 6 cabins, a lounge, a bridge, sun deck, pool
SHIPS["Cruise Liner"] = function()
	local B = newBuilder("SS DISASTER (Cruise Liner)")
	local LEN, WID, DECK = 200, 40, 12
	local hull = B.box("Hull", WID, DECK + 8, LEN, 0, -8, 0, "Navy blue", "SmoothPlastic")
	for i = 1, 4 do
		local w = WID - i * 8
		B.box("Bow", w, DECK + 8, 8, 0, -8, -LEN / 2 - i * 8 + 4, "Navy blue", "SmoothPlastic")
		B.box("BowDeck", w - 1, 1, 8, 0, DECK, -LEN / 2 - i * 8 + 4, "Brick yellow", "WoodPlanks")
	end
	B.box("Waterline", WID + 0.2, 2.4, LEN + 0.2, 0, -1.2, 0, "Bright red", "SmoothPlastic", { nc = true })
	B.box("HullStripe", WID + 0.2, 1.4, LEN + 0.2, 0, DECK - 2, 0, "Institutional white", "SmoothPlastic", { nc = true })
	B.box("Deck", WID - 1, 1, LEN - 1, 0, DECK, 0, "Brick yellow", "WoodPlanks")
	local D = DECK + 1
	for _, s in ipairs({ -1, 1 }) do B.box("Rail", 0.5, 3, LEN, s * (WID / 2 - 0.4), D, 0, "Institutional white", "Metal", nil, true) end
	B.box("SternRail", WID, 3, 0.5, 0, D, LEN / 2 - 0.4, "Institutional white", "Metal", nil, true)
	-- level 1: dining room at the front, a corridor with 3 cabins each side, a lounge at the back
	local d = B.room("Dining", 0, D, -32.5, 30, 25, 9, { n = 0, s = 0 })
	B.tableSet(-7, D, -36, 4, "Institutional white") B.tableSet(7, D, -36, 4, "Institutional white")
	B.tableSet(-7, D, -27, 4, "Institutional white") B.tableSet(7, D, -27, 4, "Institutional white")
	local cabinL = 55 / 3
	local colors = { "Bright blue", "Bright red", "Bright green", "Royal purple", "Bright orange", "Hot pink" }
	for _, s in ipairs({ -1, 1 }) do
		for i = 0, 2 do
			local cz = -20 + cabinL / 2 + i * cabinL
			B.room("Cabin", s * 9, D, cz, 12, cabinL, 9, { [s < 0 and "e" or "w"] = 0 }, { skip = { n = true, s = i == 2 }, floor = "Bright red", floorMat = "Fabric" })
			B.bed(s * 11.5, D, cz, 0, colors[(s + 1) / 2 * 3 + i + 1])
			B.box("Nightstand", 2, 2, 2, s * 13, D, cz - 5, "Brown", "Wood")
		end
	end
	B.room("Lounge", 0, D, 45, 30, 20, 9, { n = 0, s = 0 }, { floor = "Royal purple", floorMat = "Fabric" })
	for i = 0, 3 do B.part("Sofa", V(5, 1.4, 2.4), CFrame.new(-10 + i * 6.6, D + 0.7, 52), "Bright violet", "Fabric", { class = "Seat" }) end
	B.box("Bar", 14, 3.4, 2, 0, D, 39, "Brown", "Wood")
	B.box("Piano", 5, 3.5, 3, 11, D, 41, "Really black", "SmoothPlastic", nil, true)
	-- the sun deck on top, with the bridge at the front and two funnels
	local S = D + 9
	B.box("SunDeck", 31, 1, 101, 0, S, 5, "Brick yellow", "WoodPlanks")
	for _, s in ipairs({ -1, 1 }) do
		B.box("SunRail", 0.5, 3, 101, s * 15.4, S + 1, 5, "Institutional white", "Metal", nil, true)
		B.ladder(s * 17, D, 50, 10)
	end
	B.room("Bridge", 0, S + 1, -36, 22, 16, 8, { s = 0 }, { ceiling = true, color = "Institutional white" })
	B.part("Wheel", V(0.4, 3, 3), CFrame.new(0, S + 4, -40) * CFrame.Angles(0, math.rad(90), 0), "Brown", "Wood", { shape = "cyl" })
	B.box("Console", 18, 3, 2, 0, S + 1, -42.5, "Dark stone grey", "Metal")
	B.box("Screens", 16, 1.4, 0.3, 0, S + 4, -43.5, "Lime green", "Neon", { nc = true }, true)
	B.part("CaptainChair", V(2, 1, 2), CFrame.new(0, S + 1.8, -37), "Really black", "Fabric", { class = "Seat" })
	local plate = B.box("BridgeSign", 14, 2.4, 0.3, 0, S + 9.4, -44.2, "Navy blue", "SmoothPlastic", { nc = true })
	sign(plate, "SS DISASTER", "Front", Color3.new(1, 1, 1))
	for _, z in ipairs({ 10, 32 }) do
		B.part("Funnel", V(18, 12, 12), CFrame.new(0, S + 10, z) * CFrame.Angles(0, 0, math.rad(90)), "Bright red", "SmoothPlastic", { shape = "cyl" }, true)
		B.part("FunnelTop", V(4, 12.4, 12.4), CFrame.new(0, S + 21, z) * CFrame.Angles(0, 0, math.rad(90)), "Really black", "SmoothPlastic", { shape = "cyl" }, true)
	end
	for _, z in ipairs({ -15, 50 }) do for _, x in ipairs({ -10, 10 }) do B.spot(x, S + 1, z) end end
	-- the pool deck at the back, the bow with crates and a mast
	B.box("PoolEdge", 22, 1, 26, 0, D - 0.2, 78, "Institutional white", "Marble")
	B.box("Pool", 18, 0.4, 22, 0, D + 0.5, 78, "Cyan", "SmoothPlastic", { tr = 0.25 })
	for i = 0, 5 do B.part("DeckChair", V(3, 1, 6), CFrame.new((i % 2 == 0 and -1 or 1) * 16, D + 0.5, 66 + math.floor(i / 2) * 8), "Bright blue", "Fabric", { class = "Seat" }, true) end
	for i = 1, 6 do B.box("Crate", 4, 4, 4, ((i % 3) - 1) * 10, D, -60 - math.floor(i / 2) * 7, "Brown", "Wood", nil, true) end
	B.box("Mast", 1.4, 30, 1.4, 0, D, -82, "Dark stone grey", "Metal", nil, true)
	B.box("CrowsNest", 5, 2, 5, 0, D + 28, -82, "Brown", "Wood", nil, true)
	for _, z in ipairs({ -70, 66, 86 }) do for _, x in ipairs({ -12, 12 }) do B.spot(x, D, z) end end
	for _, s in ipairs({ -1, 1 }) do for _, z in ipairs({ -75, -55, 62, 82 }) do B.lifeboat(s * (WID / 2 + 4), DECK + 4, z) end end
	B.halloween(LEN, WID, DECK + 1)
	return B, hull, LEN, WID, DECK
end

------------------------------------------------------------------ 2. PIRATE GALLEON: captain's cabin, crew quarters, 3 masts with sails, cannons
SHIPS["Pirate Galleon"] = function()
	local B = newBuilder("The Black Pearl (Pirate Galleon)")
	local LEN, WID, DECK = 130, 28, 9
	local wood, dark = "Reddish brown", "Brown"
	local hull = B.box("Hull", WID, DECK + 7, LEN, 0, -7, 0, wood, "Wood")
	for i = 1, 4 do
		local w = WID - i * 6
		B.box("Bow", w, DECK + 7 - i, 7, 0, -7 + i, -LEN / 2 - i * 7 + 3.5, wood, "Wood")
	end
	B.part("Bowsprit", V(1.2, 1.2, 40), CFrame.new(0, DECK + 6, -LEN / 2 - 34) * CFrame.Angles(math.rad(18), 0, 0), dark, "Wood", nil, true)
	B.box("Stripe", WID + 0.2, 1.2, LEN + 0.2, 0, DECK - 3, 0, "Gold", "SmoothPlastic", { nc = true })
	B.box("Deck", WID - 1, 1, LEN - 1, 0, DECK, 0, "Brick yellow", "WoodPlanks")
	local D = DECK + 1
	for _, s in ipairs({ -1, 1 }) do B.box("Bulwark", 0.8, 3, LEN, s * (WID / 2 - 0.4), D, 0, dark, "Wood", nil, true) end
	-- the captain's cabin under the raised quarterdeck at the back
	B.room("CaptainsCabin", 0, D, 50, 26, 30, 9, { n = 0 }, { color = dark, floor = "Bright red", floorMat = "Fabric" })
	B.box("ChartTable", 8, 0.4, 5, 0, D + 2.6, 46, "Brown", "Wood")
	B.box("ChartLeg", 1, 2.6, 1, 0, D, 46, dark, "Wood")
	B.box("Map", 6, 0.05, 3.6, 0, D + 3, 46, "Brick yellow", "SmoothPlastic", { nc = true })
	B.box("TreasureChest", 4, 2.6, 3, -9, D, 60, "Gold", "Metal", nil, true)
	B.bed(9, D, 58, 0, "Bright red")
	for _, x in ipairs({ -4, 4 }) do B.part("Chair", V(1.8, 1, 1.8), CFrame.new(x, D + 1.5, 46), "Bright red", "Fabric", { class = "Seat" }) end
	B.box("Quarterdeck", WID - 1, 1, 30, 0, D + 9, 50, "Brick yellow", "WoodPlanks")
	for _, s in ipairs({ -1, 1 }) do B.box("QuarterRail", 0.6, 3, 30, s * 13.2, D + 10, 50, dark, "Wood", nil, true) end
	B.box("QuarterRailFront", 20, 3, 0.6, 0, D + 10, 35.3, dark, "Wood", nil, true)
	B.part("ShipsWheel", V(0.5, 5, 5), CFrame.new(0, D + 12.5, 60) * CFrame.Angles(0, math.rad(90), 0), dark, "Wood", { shape = "cyl" })
	for _, s in ipairs({ -1, 1 }) do B.ladder(s * 11, D, 33.5, 10) end
	for _, x in ipairs({ -8, 8 }) do B.spot(x, D + 10, 50) end
	-- the crew quarters under the forecastle at the front: hammocks and barrels
	B.room("CrewQuarters", 0, D, -50, 24, 24, 8, { s = 0 }, { color = dark })
	for i = 0, 3 do
		B.part("Hammock", V(3, 0.4, 8), CFrame.new((i % 2 == 0 and -7 or 7), D + 3, -56 + math.floor(i / 2) * 9), "Brick yellow", "Fabric")
	end
	for i = 1, 5 do B.part("Barrel", V(3, 2.4, 2.4), CFrame.new(-9 + i * 3, D + 1.5, -44) * CFrame.Angles(0, 0, math.rad(90)), "Brown", "Wood", { shape = "cyl" }, true) end
	B.box("Forecastle", WID - 4, 1, 24, 0, D + 8, -50, "Brick yellow", "WoodPlanks")
	B.ladder(-9, D, -36.5, 9)
	B.spot(0, D + 9, -52)
	-- three masts with sails (black ones on Halloween), a crow's nest and the Jolly Roger
	local sail = theme == "Halloween" and "Really black" or "Institutional white"
	for i, m in ipairs({ { -25, 62 }, { 2, 74 }, { 25, 58 } }) do
		local z, h = m[1], m[2]
		B.box("Mast", 1.8, h, 1.8, 0, D, z, dark, "Wood", nil, true)
		for k, y in ipairs({ h * 0.42, h * 0.72 }) do
			local w, sh = 30 - k * 6, 17 - k * 3
			B.part("Sail", V(w - 2, sh, 0.4), CFrame.new(0, D + y, z + 0.6), sail, "Fabric", { nc = true }, true)
			B.part("Yard", V(w, 1, 1), CFrame.new(0, D + y + sh / 2 + 0.5, z), dark, "Wood", nil, true)
		end
		if i == 2 then B.box("CrowsNest", 6, 2.4, 6, 0, D + h * 0.85, z, dark, "Wood", nil, true) end
	end
	local flag = B.part("JollyRoger", V(0.3, 5, 8), CFrame.new(0, D + 78, 6), "Really black", "Fabric", { nc = true }, true)
	sign(flag, "X", "Right", Color3.new(1, 1, 1))
	-- cannons along both sides
	for _, s in ipairs({ -1, 1 }) do
		for z = -28, 28, 14 do
			B.part("Cannon", V(5, 1.6, 1.6), CFrame.new(s * (WID / 2 - 2.4), D + 1.6, z), "Really black", "Metal", { shape = "cyl" }, true)
			B.box("CannonCart", 2.4, 1, 2.6, s * (WID / 2 - 3.6), D, z, dark, "Wood")
		end
	end
	for i = 1, 4 do B.part("Lantern", V(1, 1.6, 1), CFrame.new((i % 2 == 0 and -1 or 1) * 12, D + 5, -30 + i * 14), "Bright yellow", "Neon", { nc = true }, true) end
	for _, z in ipairs({ -30, -10, 10, 25 }) do for _, x in ipairs({ -6, 6 }) do B.spot(x, D, z) end end
	for _, s in ipairs({ -1, 1 }) do for _, z in ipairs({ -20, 15 }) do B.lifeboat(s * (WID / 2 + 4), DECK + 3, z, "Brown") end end
	B.halloween(LEN, WID, DECK + 1)
	return B, hull, LEN, WID, DECK
end

------------------------------------------------------------------ 3. NAVY DESTROYER: mess hall, bunk room, a bridge with radar, gun turrets, a helipad
SHIPS["Navy Destroyer"] = function()
	local B = newBuilder("USS Thunder (Navy Destroyer)")
	local LEN, WID, DECK = 170, 26, 10
	local grey = "Medium stone grey"
	local hull = B.box("Hull", WID, DECK + 8, LEN, 0, -8, 0, "Dark stone grey", "Metal")
	for i = 1, 5 do
		local w = WID - i * 4.4
		B.box("Bow", w, DECK + 8, 7, 0, -8, -LEN / 2 - i * 7 + 3.5, "Dark stone grey", "Metal")
		B.box("BowDeck", w - 1, 1, 7, 0, DECK, -LEN / 2 - i * 7 + 3.5, grey, "Metal")
	end
	B.box("Waterline", WID + 0.2, 2, LEN + 0.2, 0, -1, 0, "Really black", "SmoothPlastic", { nc = true })
	local num = B.box("HullNumber", 0.3, 5, 10, -WID / 2 - 0.2, DECK - 6, -60, "Dark stone grey", "SmoothPlastic", { nc = true })
	sign(num, "87", "Left", Color3.new(1, 1, 1))
	B.box("Deck", WID - 1, 1, LEN - 1, 0, DECK, 0, grey, "DiamondPlate")
	local D = DECK + 1
	for _, s in ipairs({ -1, 1 }) do B.box("Rail", 0.4, 3, LEN, s * (WID / 2 - 0.3), D, 0, "Light stone grey", "Metal", nil, true) end
	-- level 1: mess hall (front) and bunk room (back)
	B.room("MessHall", 0, D, -12.5, 20, 25, 9, { n = 0, s = 0 }, { color = grey, floor = "Light stone grey", floorMat = "SmoothPlastic" })
	for _, x in ipairs({ -5, 5 }) do
		B.box("MessTable", 3, 0.4, 16, x, D + 2.6, -13, "Light stone grey", "Metal")
		B.box("MessLeg", 1, 2.6, 1, x, D, -13, "Dark stone grey", "Metal")
		for _, e in ipairs({ -1, 1 }) do B.part("Bench", V(1.4, 1, 14), CFrame.new(x + e * 2.6, D + 1.5, -13), "Navy blue", "Fabric", { class = "Seat" }) end
	end
	B.room("BunkRoom", 0, D, 12.5, 20, 25, 9, { s = 0 }, { color = grey, skip = { n = true }, floor = "Light stone grey", floorMat = "SmoothPlastic" })
	for _, s in ipairs({ -1, 1 }) do
		for k = 0, 2 do
			for lvl = 0, 1 do
				local z = 4 + k * 8
				B.part("Bunk", V(4, 0.6, 7), CFrame.new(s * 7.4, D + 1 + lvl * 3.6, z), "Dark stone grey", "Metal")
				B.part("BunkMattress", V(3.6, 0.5, 6.6), CFrame.new(s * 7.4, D + 1.5 + lvl * 3.6, z), "Olive", "Fabric")
			end
		end
	end
	-- level 2: the bridge, and the radar mast
	local R = D + 9
	B.box("Roof1", 21, 1, 51, 0, R, 0, grey, "DiamondPlate")
	for _, s in ipairs({ -1, 1 }) do B.ladder(s * 12, D, 22, 10) end
	B.room("Bridge", 0, R + 1, -10, 16, 16, 8, { s = 0 }, { ceiling = true, color = grey })
	B.part("Wheel", V(0.4, 3, 3), CFrame.new(0, R + 4, -14) * CFrame.Angles(0, math.rad(90), 0), "Really black", "Metal", { shape = "cyl" })
	B.box("RadarScreens", 14, 2.4, 1, 0, R + 1, -17, "Dark stone grey", "Metal")
	B.box("ScreenGlow", 12, 1.4, 0.3, 0, R + 3.6, -17.6, "Lime green", "Neon", { nc = true }, true)
	B.part("CaptainChair", V(2, 1, 2), CFrame.new(0, R + 1.8, -11), "Really black", "Fabric", { class = "Seat" })
	B.box("RadarMast", 2, 22, 2, 0, R + 1, 8, "Light stone grey", "Metal", nil, true)
	B.box("RadarDish", 10, 1.6, 2, 0, R + 23, 8, "Institutional white", "Metal", nil, true)
	B.spot(0, R + 1, 15)
	-- gun turrets front and back, and the helipad
	for _, t in ipairs({ { -48, 0 }, { 52, 180 } }) do
		local z, ry = t[1], t[2]
		B.box("Turret", 9, 4, 10, 0, D, z, grey, "Metal", nil, true)
		for _, x in ipairs({ -1.6, 1.6 }) do
			B.part("Barrel", V(1, 1, 14), CFrame.new(x, D + 2.6, z + (ry == 0 and -11 or 11)), "Dark stone grey", "Metal", nil, true)
		end
	end
	B.box("Helipad", 22, 0.3, 22, 0, D, 70, "Dark stone grey", "SmoothPlastic", { nc = true })
	B.box("HelipadH1", 2, 0.35, 12, -4, D, 70, "Bright yellow", "SmoothPlastic", { nc = true })
	B.box("HelipadH2", 2, 0.35, 12, 4, D, 70, "Bright yellow", "SmoothPlastic", { nc = true })
	B.box("HelipadH3", 8, 0.35, 2, 0, D, 70, "Bright yellow", "SmoothPlastic", { nc = true })
	for _, z in ipairs({ -65, -35, 40, 70 }) do for _, x in ipairs({ -7, 7 }) do B.spot(x, D, z) end end
	for _, s in ipairs({ -1, 1 }) do for _, z in ipairs({ -30, 30, 55 }) do B.lifeboat(s * (WID / 2 + 4), DECK + 3, z) end end
	B.halloween(LEN, WID, DECK + 1)
	return B, hull, LEN, WID, DECK
end

------------------------------------------------------------------ 4. FISHING BOAT: small, with lots of rooms below deck
-- The hull is hollow: the deck is high (y 15) and under it, on a dry floor above the waves (y 5), a corridor runs
-- down the middle with 4 rooms on each side and the engine room at the back. Two hatches with ladders go down.
SHIPS["Fishing Boat"] = function()
	local B = newBuilder("Lucky Catch (Fishing Boat)")
	local LEN, WID, DECK = 80, 24, 15
	local LOW = 5                       -- the floor below deck
	local red, white = "Bright red", "Institutional white"
	local hull = B.box("Hull", WID, LOW + 6, LEN, 0, -6, 0, red, "SmoothPlastic")
	for i = 1, 3 do B.box("Bow", WID - i * 6, DECK + 6 - i, 6, 0, -6 + i, -LEN / 2 - i * 6 + 3, red, "SmoothPlastic") end
	for _, s in ipairs({ -1, 1 }) do
		B.box("HullSide", 1, DECK - LOW, LEN, s * (WID / 2 - 0.5), LOW, 0, white, "SmoothPlastic")
		B.box("Stripe", 1.2, 1.2, LEN, s * (WID / 2 - 0.5), DECK - 4, 0, "Navy blue", "SmoothPlastic", { nc = true })
		for z = -32, 32, 8 do       -- portholes
			B.part("Porthole", V(1.4, 2, 2), CFrame.new(s * (WID / 2 - 0.4), LOW + 5, z), "Pastel light blue", "Glass", { tr = 0.3 })
		end
	end
	B.box("HullFront", WID - 2, DECK - LOW, 1, 0, LOW, -LEN / 2 + 0.5, white, "SmoothPlastic")
	B.box("HullStern", WID - 2, DECK - LOW, 1, 0, LOW, LEN / 2 - 0.5, white, "SmoothPlastic")
	B.box("LowerFloor", WID - 2, 0.3, LEN - 2, 0, LOW, 0, "Medium stone grey", "DiamondPlate")
	-- the deck, with two hatches (6 x 6) at z = -26 and z = 8
	local function deckPiece(z0, z1, x0, x1) B.box("Deck", x1 - x0, 1, z1 - z0, (x0 + x1) / 2, DECK - 1, (z0 + z1) / 2, "Brick yellow", "WoodPlanks") end
	local H = WID / 2
	deckPiece(-LEN / 2, -29, -H, H)
	deckPiece(-29, -23, -H, -3) deckPiece(-29, -23, 3, H)
	deckPiece(-23, 5, -H, H)
	deckPiece(5, 11, -H, -3) deckPiece(5, 11, 3, H)
	deckPiece(11, LEN / 2, -H, H)
	for _, z in ipairs({ -26, 8 }) do
		B.ladder(0, LOW, z + 2, DECK - LOW)
		for _, s in ipairs({ -1, 1 }) do B.box("HatchRail", 0.4, 2.5, 6, s * 3.2, DECK, z, "Bright yellow", "Metal") end
		local sg = B.box("HatchSign", 6, 1.4, 0.3, 0, DECK + 1.2, z - 3.2, "Navy blue", "SmoothPlastic", { nc = true })
		sign(sg, "BELOW DECK", "Front", Color3.new(1, 1, 1))
	end
	-- BELOW DECK: a corridor down the middle, 4 rooms each side, the engine room at the back
	local RH = DECK - 1 - LOW
	local function room(n, side, zc, color)
		return B.room(n, side * 7.5, LOW, zc, 9, 16, RH, side < 0 and { e = 0 } or { w = 0 }, { noWindows = true, color = color or "Sand blue", floor = "Brick yellow" })
	end
	-- port side
	room("Galley", -1, -28, "Institutional white")
	B.box("Stove", 3, 3, 3, -10.3, LOW, -32, "Dark stone grey", "Metal")
	B.box("Counter", 2.5, 3, 8, -10.5, LOW, -25, "Brown", "Wood")
	B.box("Fridge", 3, 6, 3, -10.3, LOW, -20.5, "Institutional white", "SmoothPlastic")
	B.part("Pot", V(1.6, 1.4, 1.6), CFrame.new(-10.3, LOW + 3.7, -32), "Black", "Metal", { shape = "cyl" })
	room("MessRoom", -1, -12, "Bright orange")
	B.tableSet(-7.5, LOW, -12, 4, "Brown")
	room("BunkRoom", -1, 4)
	for _, z in ipairs({ -1, 9 }) do
		B.bed(-9, LOW, z, 0, "Bright blue")
		B.bed(-9, LOW + 4, z, 0, "Bright red")
		B.box("BunkPost", 0.4, 6, 0.4, -11, LOW, z + 3.4, "Dark stone grey", "Metal")
	end
	room("CaptainsCabin", -1, 20, "Brown")
	B.bed(-9, LOW, 24, 0, "Navy blue")
	B.box("Desk", 3, 2.6, 5, -10.5, LOW, 15, "Brown", "Wood")
	B.box("Chart", 2.6, 0.05, 3.6, -10.5, LOW + 2.65, 15, "Brick yellow", "SmoothPlastic", { nc = true })
	-- starboard side
	room("FishHold", 1, -28, "Medium stone grey")
	for i = 0, 5 do
		local x, z = 6 + (i % 2) * 4, -33 + math.floor(i / 2) * 4.5
		B.box("Crate", 3.4, 2, 3.4, x, LOW, z, "Brown", "Wood")
		B.box("Ice", 3, 0.6, 3, x, LOW + 2, z, "Pastel light blue", "Ice")
		for f = -1, 1, 2 do B.part("Fish", V(0.6, 0.5, 2), CFrame.new(x + f * 0.7, LOW + 2.9, z) * CFrame.Angles(0, f * 0.4, 0), "Medium stone grey", "SmoothPlastic", { nc = true }) end
	end
	room("NetLocker", 1, -12, "Olive")
	for i = 0, 2 do B.box("Net", 6, 1.2, 4, 7.5, LOW + i * 1.2, -16 + i * 3, "Brick yellow", "Fabric") end
	for i = 0, 3 do B.part("Buoy", V(1.8, 1.8, 1.8), CFrame.new(10, LOW + 1, -8 + i * 2), "Bright orange", "SmoothPlastic", { shape = "ball" }) end
	room("Storage", 1, 4, "Dark stone grey")
	for i = 0, 3 do B.part("Barrel", V(2.4, 3, 2.4), CFrame.new(10, LOW + 1.5, -2 + i * 3), "Brown", "Wood", { shape = "cyl" }) end
	for i = 0, 2 do B.box("Box", 3, 3, 3, 5.5, LOW, -1 + i * 4, "Brick yellow", "Wood") end
	room("RadioRoom", 1, 20, "Navy blue")
	B.box("RadioDesk", 3, 2.6, 7, 10.5, LOW, 20, "Dark stone grey", "Metal")
	local radio = B.box("Radio", 2, 2, 3, 10.7, LOW + 2.6, 19, "Really black", "Metal")
	local screen = B.box("RadarScreen", 0.2, 1.6, 2.4, 9.5, LOW + 3.2, 22, "Lime green", "Neon", { nc = true })
	light(screen, Color3.new(0.3, 1, 0.3), 10, 1)
	-- the engine room at the back
	B.room("EngineRoom", 0, LOW, 33.5, 22, 10, RH, { n = 0 }, { noWindows = true, color = "Dark stone grey", floor = "Medium stone grey", floorMat = "DiamondPlate" })
	B.box("Engine", 8, 4.5, 5, 0, LOW, 34, "Dark stone grey", "Metal")
	for _, x in ipairs({ -3, 0, 3 }) do B.part("Pipe", V(1, 4, 1), CFrame.new(x, LOW + 6.5, 34), "Bright yellow", "Metal", { shape = "cyl" }) end
	local warn = B.box("WarningLight", 1, 1, 1, 9, LOW + RH - 2, 30, "Really red", "Neon", { nc = true })
	light(warn, Color3.new(1, 0.2, 0.1), 16, 1.5)
	B.spot(0, LOW, -26 + 6) B.spot(0, LOW, 0) B.spot(0, LOW, 20)
	-- ON DECK: the wheelhouse at the back, a crane, nets, outriggers, life rings
	B.room("Wheelhouse", 0, DECK, 26, 16, 14, 8, { n = 0 }, { ceiling = true, color = white })
	B.part("Wheel", V(0.4, 3, 3), CFrame.new(0, DECK + 3.5, 30) * CFrame.Angles(0, math.rad(90), 0), "Brown", "Wood", { shape = "cyl" })
	B.box("Console", 10, 3, 1.5, 0, DECK, 32, "Dark stone grey", "Metal")
	local beacon = B.box("Beacon", 1.4, 1.4, 1.4, 0, DECK + 8.6, 26, "Bright yellow", "Neon", { nc = true })
	light(beacon, Color3.new(1, 0.85, 0.3), 30, 2)
	B.box("CraneMast", 1.6, 16, 1.6, 0, DECK, -10, "Bright yellow", "Metal")
	B.part("CraneBoom", V(1, 1, 22), CFrame.new(0, DECK + 15, -18) * CFrame.Angles(math.rad(-25), 0, 0), "Bright yellow", "Metal")
	B.part("CraneHook", V(0.6, 6, 0.6), CFrame.new(0, DECK + 15, -27), "Dark stone grey", "Metal", { nc = true })
	for _, s in ipairs({ -1, 1 }) do
		B.part("Outrigger", V(0.6, 0.6, 26), CFrame.new(s * 16, DECK + 14, -10) * CFrame.Angles(0, 0, s * math.rad(-50)) * CFrame.Angles(math.rad(90), 0, 0), "Dark stone grey", "Metal", { nc = true })
		B.part("LifeRing", V(0.6, 3, 3), CFrame.new(s * (H - 0.2), DECK + 2.5, 0), "Bright orange", "SmoothPlastic", { shape = "cyl" })
		B.box("DeckNet", 6, 0.8, 8, s * 6, DECK, -36 + 3, "Brick yellow", "Fabric")
	end
	for _, z in ipairs({ -36, -16, -4, 14 }) do for _, x in ipairs({ -7, 7 }) do B.spot(x, DECK, z) end end
	for _, s in ipairs({ -1, 1 }) do B.lifeboat(s * (WID / 2 + 4), DECK - 4, -6, "Bright orange") end
	B.halloween(LEN, WID, DECK)
	return B, hull, LEN, WID, DECK
end

local function buildShip(kind)
	if ship then pcall(function() ship.model:Destroy() end) end
	local B, hull, LEN, WID, DECK = SHIPS[kind]()
	-- the name on the hull
	local nameplate = B.box("NamePlate", 0.3, 3, 30, -WID / 2 - 0.25, DECK - 5, -LEN / 2 + 25, "Institutional white", "SmoothPlastic", { nc = true })
	sign(nameplate, B.model.Name:match("^(.-) %(") or kind, "Left", Color3.new(0.05, 0.05, 0.2))
	-- invisible walls round the deck (8 studs high): the boat can rock on huge waves and nobody falls off, but you can
	-- leap back over them out of the water (gone when it sinks)
	local guards = {}
	for _, g in ipairs({ { 1, LEN + 2, -WID / 2 - 0.6, 0 }, { 1, LEN + 2, WID / 2 + 0.6, 0 }, { WID + 2, 1, 0, -LEN / 2 - 0.6 }, { WID + 2, 1, 0, LEN / 2 + 0.6 } }) do
		table.insert(guards, B.box("Guard", g[1], 10, g[2], g[3], DECK - 2, g[4], "Institutional white", "SmoothPlastic", { tr = 1 }))
	end
	for _, p in ipairs(B.parts) do p.Anchored = true end
	local max = 1000 + 250 * #Players:GetPlayers()
	ship = { kind = kind, model = B.model, root = hull, hp = max, max = max, len = LEN, wid = WID, deck = DECK,
		hullY = hull.CFrame.p.Y - SEA.level - SHIP_AT.Y, breakable = B.breakable, lifeboats = B.lifeboats, spots = B.spots, guards = guards,
		dy = 0, pitch = 0, roll = 0, yaw = 0, rest = shipBase(0, 0, 0, 0) }
	seaShipAir.Value, seaShipYaw.Value, seaShipSink.Value = 0, 0, -1
	seaShipLen.Value, seaShipWid.Value = LEN, WID
	seaShip.Value = B.model
	local tag = Instance.new("StringValue")      -- players' computers find the boat by this tag
	tag.Name = "IsShip"
	tag.Parent = B.model
	return ship
end
-- the boat's frame (the hull's CFrame without its height offset)
local function shipFrame() return shipBase(ship.dy, ship.pitch, ship.roll, ship.yaw) end
-- where a part built on the server really is now (the boat has moved since it was built)
local function shipMoved() return shipFrame() * ship.rest:inverse() end
local function deckSpot() return pick(ship.spots) end
