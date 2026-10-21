-- ==== s25_floors.lua
------------------------------------------------------------------ the terminal's upper floors
-- Footprint x -140..140, z 60..320 like the ground floor. Two elevators (x -30 and 30, z LIFT_Z) go from the
-- ground floor to the 2nd floor, 3rd floor and the roof. Rooms line the walls (RSLOT, see s01_more.lua);
-- islands stand in rows between the walkways that lead to the room doors.
local TLIFT = { levels = { LV[1], LV[2], LV[3], LV_ROOF }, keys = { "elevators", "f2floor", "f3floor", "f3roof" }, names = { "G", "2", "3", "R" } }
local LIFTS = { { id = "TL", x = -30, open = "+x" }, { id = "TR", x = 30, open = "-x" } }
local HOLES = { { -34, -26, LIFT_Z - 4, LIFT_Z + 4 }, { 26, 34, LIFT_Z - 4, LIFT_Z + 4 } }

local function shaftSegment(b, level)
	local y0, y1 = TLIFT.levels[level], TLIFT.levels[level + 1]
	for _, l in ipairs(LIFTS) do
		if y1 then U.shaft(b, l.x, LIFT_Z, y0, y1 - y0, l.open, b.plot.color) end
		U.liftDoor(b, l.id, level)
	end
end

function K.elevators(b)
	for _, l in ipairs(LIFTS) do U.lift(b, l.id, l.x, LIFT_Z, TLIFT.levels, TLIFT.keys, l.open, TLIFT.names) end
	shaftSegment(b, 1)
	for _, l in ipairs(LIFTS) do
		local s = U.blk(b, "LiftSign", 0.3, 1.6, 7, l.x + (l.x < 0 and 4.6 or -4.6), LV[1] + 11.6, LIFT_Z, "Really black", "SmoothPlastic")
		U.text(s, "ELEVATOR", Color3.new(1, 1, 1), nil, "Left")
		U.text(s, "ELEVATOR", Color3.new(1, 1, 1), nil, "Right")
	end
end

function K.upfloor(b, o)
	local y = LV[o.fl]
	U.slab(b, "Floor" .. o.fl, -141, 141, 59, 321, y, 1, HOLES, o.fl == 2 and "Institutional white" or "Light stone grey", "Marble")
	U.blk(b, "Edge", 284, 1, 1, 0, y - 1, 58.5, b.plot.color, "SmoothPlastic")
	U.blk(b, "Edge", 284, 1, 1, 0, y - 1, 321.5, b.plot.color, "SmoothPlastic")
	U.blk(b, "Runner", 22, 0.1, 236, 0, y, 190, o.fl == 2 and "Bright red" or "Navy blue", "Fabric", { nc = true })
	shaftSegment(b, o.fl)
	for _, p in ipairs({ { -70, 112 }, { 70, 245 } }) do SPOT(b, "janitor", p[1], y, p[2], 45) end
end

function K.upwalls(b, o)
	local y, h = LV[o.fl], 15
	for _, z in ipairs({ 60, 320 }) do
		U.blk(b, "Glass", 280, h, 0.6, 0, y, z, "Pastel light blue", "Glass", { tr = 0.5 })
		for x = -140, 140, 20 do U.blk(b, "Frame", 1.2, h, 1.2, x, y, z, "Institutional white", "SmoothPlastic") end
	end
	for _, x in ipairs({ -140, 140 }) do
		U.blk(b, "SideGlass", 0.6, h, 260, x, y, 190, "Pastel light blue", "Glass", { tr = 0.5 })
		for z = 60, 320, 20 do U.blk(b, "Frame", 1.2, h, 1.2, x, y, z, "Institutional white", "SmoothPlastic") end
	end
	U.blk(b, "Cornice", 284, 1.4, 2, 0, y + h - 0.4, 60, b.plot.color, "SmoothPlastic")
	U.blk(b, "Cornice", 284, 1.4, 2, 0, y + h - 0.4, 320, b.plot.color, "SmoothPlastic")
	local s = U.blk(b, "FloorSign", 40, 5, 0.4, 0, y + 5, 58.8, "Really black", "SmoothPlastic")
	U.text(s, o.fl == 2 and "DEPARTURES CONCOURSE" or "SKY DECK", Color3.new(1, 0.85, 0.3), Color3.new(0.04, 0.06, 0.15), "Front")
	U.light(s, Color3.new(1, 0.85, 0.5), 30)
end

function K.uplights(b, o)
	local y = LV[o.fl] + 14.2
	for _, x in ipairs({ -85, -55, 0, 55, 85 }) do
		for _, z in ipairs({ 105, 165, 225, 285 }) do
			local p = U.blk(b, "Light", 12, 0.4, 3, x, y, z, "Institutional white", "Neon", { nc = true })
			if x ~= 0 and (z == 165 or z == 285) then U.light(p, Color3.new(1, 0.97, 0.9), 45, 1) end
		end
	end
end

-- moving walkways down the middle: stand on one and it carries you (an anchored part with a Velocity is a conveyor)
function K.walkway(b, o)
	local y = LV[o.fl]
	local fwd = (b.cf - b.cf.p) * Vector3.new(0, 0, 1)
	for _, side in ipairs({ -1, 1 }) do
		local x = side * 3.6
		local belt = U.blk(b, "MovingWalkway", 5, 0.3, 200, x, y, 190, "Really black", "DiamondPlate")
		belt.Velocity = fwd * (side < 0 and 12 or -12)
		for z = 96, 284, 24 do
			U.P(b, "Arrow", Vector3.new(1.6, 0.05, 1.6), U.L(x, y + 0.32, z, side < 0 and 0 or 180) * CFrame.Angles(0, math.rad(45), 0), "Lime green", "Neon", { nc = true })
		end
		for _, e in ipairs({ 89, 291 }) do U.blk(b, "Comb", 5.4, 0.4, 1.4, x, y, e, "Light stone grey", "Metal") end
		U.blk(b, "Rail", 0.3, 1.1, 200, x + side * 2.7, y + 0.3, 190, "Pastel light blue", "Glass", { tr = 0.4, nc = true })
	end
	U.blk(b, "Divider", 0.6, 1.4, 200, 0, y + 0.3, 190, b.plot.color, "SmoothPlastic", { nc = true })
end

-- flight information screens over the walkways; the main loop writes the live flight list on them
function K.fids(b, o)
	local y = LV[o.fl]
	for _, z in ipairs({ 120, 260 }) do
		U.blk(b, "Cable", 0.2, 3, 0.2, -6, y + 11.5, z, "Dark stone grey", nil, { nc = true })
		U.blk(b, "Cable", 0.2, 3, 0.2, 6, y + 11.5, z, "Dark stone grey", nil, { nc = true })
		local s = U.blk(b, "FlightScreen", 16, 6, 0.6, 0, y + 6, z, "Really black", "SmoothPlastic", { nc = true })
		for _, face in ipairs({ "Front", "Back" }) do
			local l = U.text(s, "DEPARTURES", Color3.new(1, 0.85, 0.2), Color3.new(0.02, 0.02, 0.06), face, Enum.Font.Code)
			table.insert(b.plot.fids, l)
		end
	end
end

function K.uproof(b)
	local y = LV_ROOF
	U.slab(b, "Roof", -142, 142, 58, 322, y, 1, HOLES, "Dark stone grey", "Concrete")
	for _, z in ipairs({ 58.5, 321.5 }) do U.blk(b, "Parapet", 284, 2, 1, 0, y, z, b.plot.color, "SmoothPlastic") end
	for _, x in ipairs({ -141.5, 141.5 }) do U.blk(b, "Parapet", 1, 2, 264, x, y, 190, b.plot.color, "SmoothPlastic") end
	for _, p in ipairs({ { -90, 140 }, { 90, 140 }, { -90, 250 }, { 90, 250 } }) do
		U.blk(b, "Skylight", 30, 1, 40, p[1], y, p[2], "Pastel light blue", "Glass", { tr = 0.3 })
	end
	for _, p in ipairs({ { -40, 300 }, { 40, 300 } }) do
		U.blk(b, "AirCon", 10, 5, 8, p[1], y, p[2], "Light stone grey", "Metal")
		U.cyl(b, "Fan", 5, 0.4, p[1], y + 5, p[2], "Dark stone grey", "Metal")
	end
	U.cyl(b, "Antenna", 0.6, 20, 120, y, 300, "Light stone grey", "Metal")
	U.light(U.ball(b, "AntennaLight", 1.2, 120, y + 20.6, 300, "Really red", "Neon"), Color3.new(1, 0.2, 0.2), 20)
	-- the elevator machine rooms on the roof (open towards the middle, where the doors are)
	for _, l in ipairs(LIFTS) do
		local back = l.x < 0 and -4.6 or 4.6
		U.blk(b, "LiftRoom", 0.6, 11, 9.8, l.x + back, y, LIFT_Z, "Light stone grey", "Concrete")
		U.blk(b, "LiftRoom", 9.8, 11, 0.6, l.x, y, LIFT_Z - 4.6, "Light stone grey", "Concrete")
		U.blk(b, "LiftRoom", 9.8, 11, 0.6, l.x, y, LIFT_Z + 4.6, "Light stone grey", "Concrete")
		U.blk(b, "LiftRoof", 10.4, 0.6, 10.4, l.x, y + 11, LIFT_Z, b.plot.color, "SmoothPlastic")
		U.liftDoor(b, l.id, 4)
	end
end

function K.roofgarden(b)
	local y = LV_ROOF
	for _, p in ipairs({ { -60, 100 }, { 60, 100 }, { -100, 205 }, { 100, 205 }, { -60, 290 }, { 60, 290 } }) do
		U.blk(b, "Grass", 24, 0.6, 24, p[1], y, p[2], "Bright green", "Grass")
		U.cyl(b, "Trunk", 1.4, 7, p[1], y + 0.6, p[2], "Brown", "Wood")
		U.ball(b, "Leaves", 8, p[1], y + 9, p[2], "Dark green", "Grass")
		U.seat(b, p[1] + 9, y + 0.6, p[2], 90, "Brown", 4)
	end
	for x = -120, 120, 40 do U.blk(b, "FlowerBox", 12, 1.6, 3, x, y, 72, U.pick({ "Bright red", "Bright yellow", "Hot pink", "Royal purple" }), "Grass") end
	U.seat(b, -10, y, 150, 0, "Brown", 6) U.seat(b, 10, y, 150, 0, "Brown", 6)
end

------------------------------------------------------------------ rooms along the walls
-- Inside a room's frame: (0, F, 0) is the middle of its floor, the door is in the glass front at z = -D/2,
-- x runs along the wall (width W). Furniture stays at |x| >= 3.5 except right at the back, so the middle
-- stays a clear walkway: visitors walk in through the door and stop along it.
local ROOM = {}
local BR = { "Bright red", "Bright blue", "Bright yellow", "Lime green", "Hot pink", "Cyan", "Bright orange", "Royal purple" }
local function backCounter(bb, W, D, color, h, w)
	h = h or 3.6
	U.blk(bb, "Counter", w or (W - 8), h, 2.2, 0, F, D / 2 - 4, "Institutional white", "SmoothPlastic")
	U.blk(bb, "CounterTop", (w or (W - 8)) + 0.4, 0.4, 2.6, 0, F + h, D / 2 - 4, color, "SmoothPlastic")
end
local function backSign(bb, D, text, color, w)
	local s = U.blk(bb, "WallSign", w or 12, 2.4, 0.2, 0, F + 8, D / 2 - 0.4, color, "Neon")
	U.text(s, text, Color3.new(1, 1, 1), nil, "Front")
end
local function sideShelves(bb, W, D, colors, rows)
	for _, s in ipairs({ -1, 1 }) do
		local x = s * (W / 2 - 1.3)
		U.blk(bb, "Shelf", 1.6, 7, D - 9, x, F, -0.5, "Light stone grey", "SmoothPlastic")
		for row = 1, rows or 2 do
			for z = -D / 2 + 5, D / 2 - 5, 4 do U.blk(bb, "Goods", 1.2, 1.1, 2.6, x - s * 0.1, F + row * 2.2, z, U.pick(colors), nil, { nc = true }) end
		end
	end
end
local function tables(bb, W, D, top, chair)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 5, D / 2 - 8, 7 do
			local x = s * (W / 4 + 2)
			U.cyl(bb, "Table", 3.4, 0.3, x, F + 2.8, z, top or "Institutional white", "SmoothPlastic")
			U.cyl(bb, "TableLeg", 0.5, 2.8, x, F, z, "Dark stone grey", "Metal")
			U.seat(bb, x - 2.4, F, z, 90, chair or "Bright red", 1.4)
			U.seat(bb, x + 2.4, F, z, -90, chair or "Bright red", 1.4)
		end
	end
end
local function armchairs(bb, W, D, color, gap)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 4, D / 2 - 7, gap or 5 do
			local x = s * (W / 2 - 4)
			U.blk(bb, "ChairBase", 2.6, 0.6, 2.6, x, F, z, "Dark stone grey")
			U.seat(bb, x, F + 0.6, z, s < 0 and -90 or 90, color, 2.6)
			U.blk(bb, "ChairBack", 0.8, 2.4, 2.6, x + s * 1.5, F + 1, z, color, "Fabric")
		end
	end
end
local function plantAt(bb, x, z, size)
	U.cyl(bb, "Pot", 2 * (size or 1), 2, x, F, z, "Reddish brown")
	U.ball(bb, "Plant", 3 * (size or 1), x, F + 3, z, "Dark green", "Grass")
end
local function sideBeds(bb, W, D, sheet)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 5, D / 2 - 6, 7 do
			local x = s * (W / 2 - 4)
			U.blk(bb, "Bed", 3.4, 2.2, 6, x, F, z, "Institutional white", "Fabric")
			U.blk(bb, "Sheet", 3.5, 0.2, 4, x, F + 2.2, z + 0.8, sheet or "Pastel light blue", "Fabric")
			U.blk(bb, "Curtain", 0.2, 7, 6, x - s * 2.4, F, z, "Pastel light blue", "Fabric", { tr = 0.3, nc = true })
		end
	end
end

function ROOM.dutyfree(bb, W, D, o)
	sideShelves(bb, W, D, { "Royal purple", "Gold", "Institutional white", "Hot pink", "Really black" }, 3)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 6, D / 2 - 8, 8 do
			U.blk(bb, "Display", 4, 3, 3, s * (W / 4 + 1), F, z, "Institutional white", "Marble")
			for k = -1, 1 do U.cyl(bb, "Perfume", 0.6, 1.2, s * (W / 4 + 1) + k * 1.2, F + 3, z, U.pick({ "Gold", "Hot pink", "Cyan" }), "Glass", { tr = 0.2 }) end
		end
	end
	backCounter(bb, W, D, o.color)
	backSign(bb, D, "TAX FREE", o.color, 16)
	SPOT(bb, "clerk", -3, F, D / 2 - 2, 180) SPOT(bb, "clerk", 3, F, D / 2 - 2, 180)
end
function ROOM.pharmacy(bb, W, D, o)
	sideShelves(bb, W, D, { "Institutional white", "Bright green", "Bright red", "Pastel light blue" }, 3)
	backCounter(bb, W, D, "Bright green")
	local c1 = U.blk(bb, "Cross", 3, 1, 0.2, 0, F + 8, D / 2 - 0.4, "Lime green", "Neon")
	U.blk(bb, "Cross", 1, 3, 0.2, 0, F + 7, D / 2 - 0.4, "Lime green", "Neon")
	U.light(c1, Color3.new(0.3, 1, 0.3), 14)
	SPOT(bb, "clerk", 0, F, D / 2 - 2, 180)
end
function ROOM.exchange(bb, W, D, o)
	backCounter(bb, W, D, o.color)
	U.blk(bb, "Glass", W - 8, 3, 0.2, 0, F + 4, D / 2 - 5, "Pastel light blue", "Glass", { tr = 0.5 })
	local s = U.blk(bb, "Rates", 14, 4, 0.2, 0, F + 8, D / 2 - 0.4, "Really black", "SmoothPlastic")
	U.text(s, "USD 1.00  EUR 0.92\nGBP 0.79  JPY 150", Color3.new(1, 0.6, 0.1), Color3.new(0, 0, 0), "Front", Enum.Font.Code)
	for _, s2 in ipairs({ -1, 1 }) do
		U.blk(bb, "ATM", 3, 6, 2, s2 * (W / 2 - 2.5), F, -2, "Bright green", "SmoothPlastic")
		U.blk(bb, "Screen", 0.2, 1.4, 1.6, s2 * (W / 2 - 4.1), F + 4, -2, "Cyan", "Neon")
	end
	SPOT(bb, "clerk", 0, F, D / 2 - 2, 180)
end
function ROOM.medical(bb, W, D, o)
	sideBeds(bb, W, D)
	backCounter(bb, W, D, "Really red", 3.4, 10)
	backSign(bb, D, "MEDICAL", "Really red", 10)
	U.blk(bb, "Wheelchair", 2, 2, 2.4, W / 2 - 8, F + 0.5, D / 2 - 5, "Dark stone grey", "Metal")
	SPOT(bb, "clerk", 0, F, D / 2 - 2, 180)
end
function ROOM.prayer(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 5, D / 2 - 5, 4 do U.blk(bb, "Mat", 3, 0.15, 2.6, s * (W / 4 + 2), F, z, U.pick({ "Sand blue", "Dark green", "Reddish brown" }), "Fabric", { nc = true }) end
	end
	U.blk(bb, "ShoeRack", 1.4, 2, 6, -(W / 2 - 1.5), F, -D / 2 + 4, "Brown", "Wood")
	U.light(U.blk(bb, "SoftLight", 8, 0.3, 1, 0, F + 13.5, 0, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.9, 0.7), 16, 0.6)
	plantAt(bb, W / 2 - 3, D / 2 - 3)
end
function ROOM.nursery(bb, W, D, o)
	U.blk(bb, "SoftMat", 10, 0.3, 10, -(W / 4 + 1), F, 0, "Bright yellow", "Fabric")
	for i = 1, 6 do U.blk(bb, "Toy", 1.2, 1.2, 1.2, -(W / 4 + 1) + math.random(-4, 4), F + 0.3, math.random(-4, 4), U.pick(BR)) end
	for z = -D / 2 + 5, D / 2 - 6, 6 do
		U.blk(bb, "ChangingTable", 3, 3.4, 4, W / 2 - 3, F, z, "Institutional white", "SmoothPlastic")
		U.blk(bb, "Pad", 2.6, 0.4, 3.4, W / 2 - 3, F + 3.4, z, "Pastel light blue", "Fabric")
	end
	U.blk(bb, "Crib", 4, 3, 6, 6, F, D / 2 - 4, "Brown", "Wood", { tr = 0.1 })
	U.seat(bb, -6, F, D / 2 - 4, 180, "Hot pink", 3)
end
function ROOM.lounge(bb, W, D, o)
	U.blk(bb, "Carpet", W - 1, 0.1, D - 1, 0, F + 0.1, 0, o.color, "Fabric", { nc = true })
	armchairs(bb, W, D, o.lux and "Gold" or "Really black", 5)
	-- buffet and bar along the back
	U.blk(bb, "Buffet", W - 8, 3.4, 2.4, 0, F, D / 2 - 4, "Brown", "Wood")
	U.blk(bb, "BuffetTop", W - 7.6, 0.4, 2.8, 0, F + 3.4, D / 2 - 4, o.lux and "Gold" or "Institutional white", "Marble")
	for x = -(W / 2 - 6), W / 2 - 6, 3.4 do
		U.cyl(bb, "Dish", 1.8, 0.5, x, F + 3.8, D / 2 - 4, "Institutional white")
		U.ball(bb, "Food", 1, x, F + 4.5, D / 2 - 4, U.pick({ "Bright orange", "Lime green", "Brown", "Bright red", "Bright yellow" }))
	end
	U.blk(bb, "TV", 10, 5, 0.3, 0, F + 8, D / 2 - 0.4, "Really black")
	U.blk(bb, "TVScreen", 9.4, 4.4, 0.1, 0, F + 8.3, D / 2 - 0.6, "Cyan", "Neon")
	plantAt(bb, -(W / 2 - 2.5), -D / 2 + 2.5) plantAt(bb, W / 2 - 2.5, -D / 2 + 2.5)
	if o.lux then
		local ch = U.cyl(bb, "Chandelier", 6, 0.6, 0, F + 12.5, 0, "Gold", "Metal", { refl = 0.4, nc = true })
		U.light(ch, Color3.new(1, 0.85, 0.5), 30)
		U.fx(ch, "Sparkles")
	end
	SPOT(bb, "chef", -4, F, D / 2 - 2, 180) SPOT(bb, "chef", 4, F, D / 2 - 2, 180)
end
function ROOM.showers(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 5, D / 2 - 6, 6 do
			local x = s * (W / 2 - 3)
			U.blk(bb, "Cubicle", 0.3, 8, 5.6, x - s * 2.9, F, z, "Pastel light blue", "Glass", { tr = 0.5 })
			U.blk(bb, "Tile", 5.6, 8, 0.3, x, F, z + 2.9, "Institutional white", "Marble")
			U.cyl(bb, "ShowerHead", 1, 0.3, x, F + 7.6, z, "Light stone grey", "Metal")
		end
	end
	backCounter(bb, W, D, o.color, 3.4, 10)
	for i = 0, 3 do U.blk(bb, "Towel", 1.4, 0.6, 1.8, -3 + i * 2, F + 3.8, D / 2 - 4, "Institutional white", "Fabric") end
	SPOT(bb, "clerk", 0, F, D / 2 - 2, 180)
end
function ROOM.pods(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 4, D / 2 - 5, 4.4 do
			for lvl = 0, 1 do
				U.P(bb, "Pod", Vector3.new(7, 3.6, 3.6), U.L(s * (W / 2 - 4.5), F + 2 + lvl * 4, z), "Institutional white", "SmoothPlastic", { shape = "cyl" })
				U.blk(bb, "PodLight", 0.3, 0.6, 0.6, s * (W / 2 - 8.1), F + 1.7 + lvl * 4, z, "Cyan", "Neon", { nc = true })
			end
		end
	end
	backSign(bb, D, "SLEEP PODS", o.color, 12)
end
function ROOM.business(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 4, D / 2 - 6, 5 do
			local x = s * (W / 2 - 2.5)
			U.blk(bb, "Desk", 3, 3, 4, x, F, z, "Institutional white", "SmoothPlastic")
			U.blk(bb, "Monitor", 0.2, 1.6, 2.4, x + s * 0.8, F + 3, z, "Cyan", "Neon")
			U.seat(bb, x - s * 2.6, F, z, s < 0 and -90 or 90, "Really black", 1.6)
		end
	end
	U.blk(bb, "MeetingTable", 10, 3, 4, 0, F, D / 2 - 4, "Brown", "Wood")
	U.blk(bb, "Printer", 2, 1.6, 2, W / 2 - 2, F, D / 2 - 2, "Light stone grey")
end
function ROOM.kidsplay(bb, W, D, o)
	U.blk(bb, "SoftFloor", W - 1, 0.2, D - 1, 0, F + 0.05, 0, "Bright blue", "Fabric", { nc = true })
	U.blk(bb, "SlideTower", 5, 5, 5, -(W / 2 - 4), F, D / 2 - 5, "Bright red", "SmoothPlastic")
	U.P(bb, "Slide", Vector3.new(3, 0.4, 9), U.L(-(W / 2 - 4), F + 2.6, D / 2 - 12, 0, 28), "Bright yellow", "SmoothPlastic")
	U.blk(bb, "BallPit", 8, 1.6, 8, W / 2 - 6, F, 0, "Lime green", "SmoothPlastic")
	for i = 1, 12 do U.ball(bb, "Ball", 1, W / 2 - 6 + math.random(-3, 3), F + 1.8, math.random(-3, 3), U.pick(BR), nil, { nc = true }) end
	for i = 0, 3 do U.blk(bb, "Block", 2, 2, 2, -(W / 4 + 2) + (i % 2) * 2.2, F + math.floor(i / 2) * 2, -D / 2 + 5, U.pick(BR), "Fabric") end
end
function ROOM.electronics(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 5, D / 2 - 8, 7 do
			local x = s * (W / 4 + 2)
			U.blk(bb, "Table", 5, 3.4, 3, x, F, z, "Institutional white", "SmoothPlastic")
			for k = -1, 1 do U.blk(bb, "Gadget", 1, 0.1, 1.6, x + k * 1.5, F + 3.4, z, "Cyan", "Neon") end
		end
	end
	for x = -(W / 2 - 6), W / 2 - 6, 8 do
		U.blk(bb, "TV", 7, 4, 0.3, x, F + 6, D / 2 - 0.5, "Really black")
		U.blk(bb, "TVScreen", 6.4, 3.4, 0.1, x, F + 6.2, D / 2 - 0.7, U.pick({ "Cyan", "Lime green", "Hot pink" }), "Neon")
	end
	backCounter(bb, W, D, o.color, 3.4, 8)
	SPOT(bb, "clerk", 0, F, D / 2 - 2, 180)
end
function ROOM.helpdesk(bb, W, D, o)
	backCounter(bb, W, D, o.color)
	for x = -(W / 2 - 8), W / 2 - 8, 8 do
		U.blk(bb, "Screen", 3, 2, 0.2, x, F + 5, D / 2 - 3, "Cyan", "Neon")
		SPOT(bb, "agent", x, F, D / 2 - 2, 180)
	end
	backSign(bb, D, o.title, o.color, 18)
	for _, s in ipairs({ -1, 1 }) do for z = -D / 2 + 3, 0, 4 do U.cyl(bb, "QueuePost", 0.5, 3, s * 4.5, F, z, "Light stone grey", "Metal") end end
end
function ROOM.lostfound(bb, W, D, o)
	sideShelves(bb, W, D, { "Bright red", "Really black", "Bright blue", "Brown", "Bright yellow" }, 2)
	for i = 0, 3 do U.cyl(bb, "Umbrella", 0.3, 4, -(W / 2 - 3) + i, F, D / 2 - 3, U.pick(BR)) end
	backCounter(bb, W, D, o.color, 3.6, 12)
	backSign(bb, D, "LOST & FOUND", o.color, 14)
	SPOT(bb, "clerk", 0, F, D / 2 - 2, 180)
end
function ROOM.wrap(bb, W, D, o)
	U.cyl(bb, "WrapMachine", 6, 1, -(W / 4 + 2), F, 0, "Dark stone grey", "Metal")
	U.blk(bb, "WrapFilm", 3, 5, 3, -(W / 4 + 2), F + 1, 0, "Lime green", "Glass", { tr = 0.4 })
	for _, s in ipairs({ -1, 1 }) do for z = -D / 2 + 4, D / 2 - 6, 3 do U.blk(bb, "Locker", 1.6, 8, 2.8, s * (W / 2 - 1.2), F, z, "Light stone grey", "Metal") end end
	for i = 0, 3 do U.blk(bb, "Suitcase", 2, 3, 1.2, W / 4 + 1 + (i % 2) * 2.4, F + math.floor(i / 2) * 3, -2, U.pick(BR)) end
	backCounter(bb, W, D, o.color, 3.4, 10)
	SPOT(bb, "clerk", 0, F, D / 2 - 2, 180)
end
function ROOM.simshop(bb, W, D, o)
	ROOM.electronics(bb, W, D, o)
end
function ROOM.sportsbar(bb, W, D, o)
	U.blk(bb, "Bar", W - 8, 3.6, 2.4, 0, F, D / 2 - 4, "Brown", "Wood")
	U.blk(bb, "BarTop", W - 7.6, 0.4, 2.8, 0, F + 3.6, D / 2 - 4, "Really black", "Marble")
	for x = -(W / 2 - 6), W / 2 - 6, 3 do U.cyl(bb, "Tap", 0.3, 1.2, x, F + 4, D / 2 - 3.6, "Gold", "Metal") end
	tables(bb, W, D, "Really black", "Bright red")
	for _, s in ipairs({ -1, 1 }) do
		U.blk(bb, "TV", 0.3, 4, 7, s * (W / 2 - 0.6), F + 7, -2, "Really black")
		U.blk(bb, "Game", 0.1, 3.4, 6.4, s * (W / 2 - 0.8), F + 7.2, -2, "Bright green", "Neon")
	end
	SPOT(bb, "chef", 0, F, D / 2 - 2, 180)
end
function ROOM.cafe(bb, W, D, o)
	backCounter(bb, W, D, o.color)
	for x = -4, 4, 4 do U.blk(bb, "CoffeeMachine", 2, 2.4, 1.6, x, F + 4, D / 2 - 4.2, "Dark stone grey", "Metal") end
	U.blk(bb, "CakeCase", 5, 1.8, 2, W / 2 - 7, F + 4, D / 2 - 4, "Pastel light blue", "Glass", { tr = 0.4 })
	tables(bb, W, D, "Brown", "Institutional white")
	backSign(bb, D, "COFFEE", "Brown", 10)
	SPOT(bb, "chef", -3, F, D / 2 - 2, 180) SPOT(bb, "chef", 3, F, D / 2 - 2, 180)
end
function ROOM.bookstore(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		local x = s * (W / 2 - 1.3)
		U.blk(bb, "Bookcase", 1.6, 9, D - 6, x, F, 0, "Brown", "Wood")
		for row = 1, 3 do for z = -D / 2 + 4, D / 2 - 4, 3 do U.blk(bb, "Books", 1, 1.6, 2.6, x - s * 0.4, F + row * 2.6, z, U.pick(BR), nil, { nc = true }) end end
		U.blk(bb, "Display", 6, 3, 3, s * (W / 4 + 1), F, -2, "Institutional white")
		for k = -1, 1 do U.blk(bb, "Book", 1.2, 0.4, 1.6, s * (W / 4 + 1) + k * 1.8, F + 3, -2, U.pick(BR)) end
	end
	backCounter(bb, W, D, o.color, 3.4, 8)
	SPOT(bb, "clerk", 0, F, D / 2 - 2, 180)
end
function ROOM.fashion(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 4, D / 2 - 7, 6 do
			local x = s * (W / 2 - 3)
			U.blk(bb, "Rail", 0.3, 0.3, 5, x, F + 5, z, "Light stone grey", "Metal")
			for k = -2, 2 do U.blk(bb, "Clothes", 1.6, 3, 0.4, x, F + 2, z + k, U.pick(BR), "Fabric", { nc = true }) end
		end
		U.blk(bb, "Mannequin", 1.6, 5, 1, s * (W / 4 + 1), F, -D / 2 + 3, "Institutional white")
		U.blk(bb, "Outfit", 1.8, 2.4, 1.1, s * (W / 4 + 1), F + 2.2, -D / 2 + 3, o.color, "Fabric")
	end
	U.blk(bb, "Mirror", 6, 7, 0.2, 0, F + 1, D / 2 - 0.4, "Institutional white", "Glass", { refl = 0.6 })
	U.blk(bb, "FittingRoom", 6, 8, 0.2, -(W / 2 - 4), F, D / 2 - 6, "Bright red", "Fabric")
	SPOT(bb, "clerk", 4, F, D / 2 - 2, 180)
end
function ROOM.foodhall(bb, W, D, o)
	local cols = { "Bright red", "Bright orange", "Lime green", "Bright blue", "Hot pink" }
	local n = math.max(2, math.floor((W - 6) / 9))
	for i = 1, n do
		local x = -(W - 6) / 2 + (i - 0.5) * (W - 6) / n
		U.blk(bb, "Counter", (W - 6) / n - 1, 3.6, 2.2, x, F, D / 2 - 4, "Institutional white")
		U.blk(bb, "Awning", (W - 6) / n - 1, 1, 2.6, x, F + 7, D / 2 - 4, cols[(i - 1) % #cols + 1], "SmoothPlastic")
		SPOT(bb, "chef", x, F, D / 2 - 2, 180)
	end
	for _, s in ipairs({ -1, 1 }) do
		local x = s * (W / 4 + 2)
		U.blk(bb, "LongTable", 3, 0.4, D - 12, x, F + 2.8, -2, "Brown", "Wood")
		U.blk(bb, "TableBase", 1, 2.8, D - 14, x, F, -2, "Dark stone grey", "Metal")
		for z = -D / 2 + 3, D / 2 - 9, 3 do U.seat(bb, x - 2.3, F, z, 90, "Bright orange", 1.4) U.seat(bb, x + 2.3, F, z, -90, "Bright orange", 1.4) end
	end
end
function ROOM.sushi(bb, W, D, o)
	U.blk(bb, "Conveyor", W - 8, 3.6, 2.4, 0, F, D / 2 - 4, "Really black", "DiamondPlate")
	for x = -(W / 2 - 6), W / 2 - 6, 2.4 do
		U.cyl(bb, "Plate", 1.4, 0.2, x, F + 3.6, D / 2 - 4, U.pick({ "Bright red", "Bright blue", "Bright yellow" }))
		U.blk(bb, "Sushi", 0.8, 0.5, 0.5, x, F + 3.8, D / 2 - 4, "Institutional white")
	end
	for x = -(W / 2 - 6), W / 2 - 6, 3 do if math.abs(x) > 3 then U.seat(bb, x, F + 1, D / 2 - 6.4, 180, "Brown", 1.4) end end
	tables(bb, W, D, "Brown", "Really black")
	backSign(bb, D, "SUSHI", "Bright red", 8)
	SPOT(bb, "chef", 0, F, D / 2 - 1.6, 180)
end
function ROOM.steak(bb, W, D, o)
	tables(bb, W, D, "Institutional white", "Really black")
	for _, s in ipairs({ -1, 1 }) do for z = -D / 2 + 5, D / 2 - 8, 7 do U.light(U.cyl(bb, "Candle", 0.3, 0.6, s * (W / 4 + 2), F + 3.1, z, "Cool yellow", "Neon"), Color3.new(1, 0.7, 0.3), 6, 0.6) end end
	U.blk(bb, "Grill", 8, 3.4, 2.4, -4, F, D / 2 - 4, "Dark stone grey", "Metal")
	U.blk(bb, "Fire", 7, 0.3, 2, -4, F + 3.4, D / 2 - 4, "Neon orange", "Neon", { nc = true })
	U.blk(bb, "WineRack", 6, 7, 1.2, 6, F, D / 2 - 1, "Brown", "Wood")
	for i = 0, 5 do U.cyl(bb, "Wine", 0.4, 1.2, 4 + (i % 3) * 2, F + 2 + math.floor(i / 3) * 2.5, D / 2 - 1.6, "Really red", "Glass") end
	SPOT(bb, "chef", -4, F, D / 2 - 1.6, 180)
end
function ROOM.pizza(bb, W, D, o)
	U.ball(bb, "Oven", 7, W / 2 - 5, F + 1.5, D / 2 - 4, "Reddish brown", "Brick")
	U.blk(bb, "OvenFire", 2, 1, 0.5, W / 2 - 5, F + 1.5, D / 2 - 7.4, "Neon orange", "Neon", { nc = true })
	backCounter(bb, W, D, "Bright red", 3.6, W - 16)
	tables(bb, W, D, "Bright red", "Institutional white")
	SPOT(bb, "chef", -2, F, D / 2 - 2, 180)
end
function ROOM.noodle(bb, W, D, o)
	backCounter(bb, W, D, o.color)
	for x = -(W / 2 - 6), W / 2 - 6, 3 do
		U.cyl(bb, "Bowl", 1.4, 0.8, x, F + 4, D / 2 - 4, "Institutional white")
		if math.abs(x) > 3 then U.seat(bb, x, F + 1, D / 2 - 6.4, 180, "Bright red", 1.4) end
	end
	for _, x in ipairs({ -(W / 2 - 4), W / 2 - 4 }) do U.light(U.ball(bb, "Lantern", 2, x, F + 10, -2, "Really red", "Neon", { nc = true }), Color3.new(1, 0.3, 0.2), 12) end
	tables(bb, W, D, "Brown", "Bright red")
	SPOT(bb, "chef", 0, F, D / 2 - 2, 180)
end
function ROOM.dessert(bb, W, D, o)
	U.blk(bb, "Display", W - 8, 3.4, 2.4, 0, F, D / 2 - 4, "Pastel light blue", "Glass", { tr = 0.4 })
	for x = -(W / 2 - 6), W / 2 - 6, 2.6 do U.cyl(bb, "Cake", 1.8, 1.2, x, F + 1.6, D / 2 - 4, U.pick({ "Hot pink", "Brown", "Institutional white", "Bright yellow", "Lime green" })) end
	tables(bb, W, D, "Pink", "Institutional white")
	backSign(bb, D, "SWEETS", "Hot pink", 10)
	SPOT(bb, "chef", 0, F, D / 2 - 2, 180)
end
function ROOM.cinema(bb, W, D, o)
	U.blk(bb, "DarkFloor", W - 1, 0.1, D - 1, 0, F + 0.05, 0, "Really black", "Fabric", { nc = true })
	U.blk(bb, "Screen", W - 4, 8, 0.2, 0, F + 3, D / 2 - 0.4, "Institutional white", "Neon")
	for _, s in ipairs({ -1, 1 }) do
		for row = 0, 2 do
			for x = 4.5, W / 2 - 2, 3 do U.seat(bb, s * x, F + row * 0.5, -D / 2 + 4 + row * 3.4, 0, "Bright red", 2.4) end
		end
	end
	U.blk(bb, "Popcorn", 2, 4, 2, -(W / 2 - 2), F, D / 2 - 3, "Bright red")
	U.blk(bb, "PopcornTop", 2, 2, 2, -(W / 2 - 2), F + 4, D / 2 - 3, "Bright yellow", "Glass", { tr = 0.3 })
end
function ROOM.arcade(bb, W, D, o)
	U.blk(bb, "DarkFloor", W - 1, 0.1, D - 1, 0, F + 0.05, 0, "Really black", "Fabric", { nc = true })
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 4, D / 2 - 6, 4 do
			local x = s * (W / 2 - 2.2)
			U.blk(bb, "Cabinet", 3, 6.4, 3, x, F, z, "Really black", "SmoothPlastic")
			U.blk(bb, "Screen", 0.2, 2, 2.4, x - s * 1.55, F + 4, z, U.pick({ "Lime green", "Cyan", "Hot pink", "Bright yellow" }), "Neon")
		end
	end
	U.blk(bb, "PrizeCounter", 12, 3.4, 2.4, 0, F, D / 2 - 4, "Royal purple", "Neon")
	for i = 1, 6 do U.ball(bb, "Prize", 1.2, -5 + i * 1.6, F + 4.2, D / 2 - 4, U.pick(BR)) end
	U.light(U.blk(bb, "Glow", 3, 0.3, 3, 0, F + 13.5, 0, "Hot pink", "Neon", { nc = true }), Color3.new(1, 0.3, 1), 26)
end
function ROOM.gym(bb, W, D, o)
	U.blk(bb, "RubberFloor", W - 1, 0.1, D - 1, 0, F + 0.05, 0, "Really black", "Fabric", { nc = true })
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 4, D / 2 - 6, 5 do
			local x = s * (W / 2 - 3.5)
			U.blk(bb, "Treadmill", 2.6, 0.8, 5, x, F, z, "Dark stone grey", "Metal")
			U.blk(bb, "Console", 2.6, 4, 0.4, x, F, z - 2.4, "Light stone grey", "Metal")
		end
	end
	U.blk(bb, "Mirror", W - 4, 7, 0.2, 0, F + 1, D / 2 - 0.4, "Institutional white", "Glass", { refl = 0.6 })
	U.blk(bb, "WeightRack", 8, 2, 1.6, 0, F, D / 2 - 2, "Dark stone grey", "Metal")
	for i = -3, 3 do U.P(bb, "Dumbbell", Vector3.new(1.2, 0.6, 0.6), U.L(i * 1.1, F + 2.3, D / 2 - 2), "Really black", "Metal") end
end
function ROOM.gallery(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 5, D / 2 - 4, 7 do
			U.blk(bb, "Frame", 0.3, 5, 5, s * (W / 2 - 0.5), F + 4, z, "Gold", "Metal")
			U.blk(bb, "Painting", 0.2, 4.2, 4.2, s * (W / 2 - 0.7), F + 4.4, z, U.pick(BR), "SmoothPlastic")
		end
		U.cyl(bb, "Pedestal", 2.4, 3.6, s * (W / 4 + 1), F, 0, "Institutional white", "Marble")
		U.ball(bb, "Sculpture", 2.2, s * (W / 4 + 1), F + 4.7, 0, U.pick({ "Gold", "Institutional white", "Bright blue" }), "Metal", { refl = 0.3 })
	end
	U.seat(bb, 0, F, D / 2 - 4, 180, "Really black", 6)
end
function ROOM.library(bb, W, D, o)
	ROOM.bookstore(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do U.light(U.ball(bb, "Lamp", 1.2, s * (W / 4 + 1), F + 5, 2, "Cool yellow", "Neon", { nc = true }), Color3.new(1, 0.9, 0.6), 10) end
end
function ROOM.garden(bb, W, D, o)
	U.blk(bb, "Grass", W - 1, 0.3, D - 1, 0, F, 0, "Bright green", "Grass")
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 5, D / 2 - 5, 8 do
			U.cyl(bb, "Trunk", 0.8, 5, s * (W / 2 - 4), F + 0.3, z, "Brown", "Wood")
			U.ball(bb, "Leaves", 5, s * (W / 2 - 4), F + 7, z, U.pick({ "Dark green", "Bright green" }), "Grass")
			U.ball(bb, "Flowers", 1.6, s * (W / 4 + 1), F + 0.9, z, U.pick({ "Hot pink", "Bright yellow", "Bright red", "Royal purple" }), "Grass")
		end
	end
	for i = 1, 8 do U.P(bb, "Butterfly", Vector3.new(0.8, 0.1, 0.6), U.L(math.random(-math.floor(W / 2) + 3, math.floor(W / 2) - 3), F + 5 + math.random() * 5, math.random(-math.floor(D / 2) + 3, math.floor(D / 2) - 3), math.random(0, 180)), U.pick({ "Bright orange", "Cyan", "Bright yellow", "Hot pink" }), "Neon", { nc = true }) end
	U.cyl(bb, "Pond", 7, 0.3, 0, F + 0.3, D / 2 - 5, "Bright blue", "Glass", { tr = 0.3 })
end
function ROOM.champagne(bb, W, D, o)
	U.blk(bb, "Bar", W - 8, 3.6, 2.4, 0, F, D / 2 - 4, "Institutional white", "Marble")
	U.blk(bb, "BarTop", W - 7.6, 0.4, 2.8, 0, F + 3.6, D / 2 - 4, "Gold", "Metal", { refl = 0.3 })
	for x = -(W / 2 - 6), W / 2 - 6, 2 do U.cyl(bb, "Bottle", 0.5, 1.6, x, F + 4, D / 2 - 4, U.pick({ "Dark green", "Gold" }), "Glass") end
	for _, s in ipairs({ -1, 1 }) do for z = -D / 2 + 4, D / 2 - 8, 6 do U.cyl(bb, "HighTable", 2.4, 4, s * (W / 4 + 2), F, z, "Gold", "Metal") end end
	local ch = U.cyl(bb, "Chandelier", 5, 0.6, 0, F + 12.5, 0, "Gold", "Metal", { refl = 0.4, nc = true })
	U.light(ch, Color3.new(1, 0.85, 0.5), 26)
	U.fx(ch, "Sparkles")
	SPOT(bb, "chef", 0, F, D / 2 - 2, 180)
end
function ROOM.observation(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		for x = 5, W / 2 - 3, 6 do
			U.cyl(bb, "Telescope", 0.4, 3.4, s * x, F, D / 2 - 3, "Dark stone grey", "Metal")
			U.P(bb, "Scope", Vector3.new(0.8, 0.8, 2.4), U.L(s * x, F + 3.8, D / 2 - 2.6, 0, 15), "Institutional white", "Metal")
		end
		U.seat(bb, s * (W / 4 + 2), F, -2, 0, "Navy blue", 8)
	end
	local s2 = U.blk(bb, "SpottersBoard", 10, 3, 0.2, 0, F + 10, D / 2 - 0.4, "Really black")
	U.text(s2, "PLANE SPOTTERS DECK", Color3.new(1, 0.85, 0.3), nil, "Front")
end
function ROOM.museum(bb, W, D, o)
	U.P(bb, "OldPlane", Vector3.new(10, 1.8, 1.8), U.L(0, F + 9, 1, 90), "Bright red", "SmoothPlastic", { shape = "cyl", nc = true })
	U.blk(bb, "Wing", 14, 0.3, 2.4, 0, F + 9.6, 1, "Bright red", "SmoothPlastic", { nc = true })
	U.blk(bb, "Wing", 14, 0.3, 2.4, 0, F + 8.2, 1, "Bright red", "SmoothPlastic", { nc = true })
	U.blk(bb, "Prop", 0.3, 4, 0.4, 0, F + 7, -4.2, "Brown", "Wood", { nc = true })
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 4, D / 2 - 5, 6 do
			U.blk(bb, "Case", 3, 3, 3, s * (W / 2 - 3), F, z, "Institutional white", "Marble")
			U.blk(bb, "Glass", 3, 2, 3, s * (W / 2 - 3), F + 3, z, "Pastel light blue", "Glass", { tr = 0.5 })
			U.blk(bb, "Model", 1.6, 0.6, 2, s * (W / 2 - 3), F + 3.4, z, U.pick(BR))
		end
	end
end
function ROOM.simulator(bb, W, D, o)
	for _, s in ipairs({ -1, 1 }) do
		local x = s * (W / 4 + 2)
		U.P(bb, "Cockpit", Vector3.new(7, 5, 6), U.L(x, F + 2.5, 1, 180), "Institutional white", "SmoothPlastic", { class = "WedgePart" })
		U.blk(bb, "Window", 6, 2.4, 0.2, x, F + 3.4, 4.2, "Cyan", "Neon")
		U.seat(bb, x, F, 1.4, 180, "Really black", 2)
		U.blk(bb, "Yoke", 1.6, 0.4, 0.4, x, F + 2.6, 2.6, "Dark stone grey", "Metal")
	end
	backSign(bb, D, "FLY THE SIMULATOR", o.color, 16)
end
function ROOM.academy(bb, W, D, o)
	U.blk(bb, "Whiteboard", W - 8, 5, 0.2, 0, F + 3, D / 2 - 0.4, "Institutional white")
	for _, s in ipairs({ -1, 1 }) do
		for z = -D / 2 + 4, D / 2 - 6, 4 do
			local x = s * (W / 4 + 2)
			U.blk(bb, "Desk", 5, 2.6, 1.6, x, F, z, "Brown", "Wood")
			U.seat(bb, x, F, z - 1.6, 180, o.color, 1.6)
		end
	end
	U.P(bb, "ModelPlane", Vector3.new(6, 1, 1), U.L(0, F + 11, 0, 90), "Institutional white", nil, { shape = "cyl", nc = true })
	U.blk(bb, "ModelWing", 7, 0.2, 1.2, 0, F + 11, 0, o.color, nil, { nc = true })
end

local FOODROOM = { lounge = true, sportsbar = true, cafe = true, foodhall = true, sushi = true, steak = true, pizza = true, noodle = true, dessert = true, champagne = true }
function K.uroom(b, o)
	local rs = RSLOT[o.slot]
	local W, D = rs.W, rs.D
	local cf = b.cf * U.L(rs.x, LV[o.fl] - F, rs.z, rs.ry)
	local bb = { model = b.model, cf = cf, plot = b.plot }
	-- shell: floor, side walls, glass shop front with a door in the middle, sign, light
	U.blk(bb, "RoomFloor", W - 0.4, 0.1, D - 0.4, 0, F, 0, o.floor or "Institutional white", "Marble", { nc = true })
	for _, s in ipairs({ -1, 1 }) do
		U.blk(bb, "Partition", 0.5, 14, D, s * W / 2, F, 0, "Institutional white", "SmoothPlastic")
		U.blk(bb, "ShopGlass", W / 2 - 4, 10, 0.3, s * (W / 4 + 2), F, -D / 2, "Pastel light blue", "Glass", { tr = 0.55 })
		U.blk(bb, "DoorPost", 0.6, 10, 0.6, s * 4, F, -D / 2, o.color, "Metal")
	end
	U.blk(bb, "Fascia", W, 4, 0.5, 0, F + 10, -D / 2, o.color, "SmoothPlastic")
	local sign = U.blk(bb, "Sign", math.min(W - 4, 28), 2.6, 0.3, 0, F + 10.7, -D / 2 - 0.4, "Really black", "SmoothPlastic")
	U.text(sign, o.title, Color3.new(1, 1, 1), BrickColor.new(o.color).Color, "Front")
	U.light(U.blk(bb, "RoomLight", 6, 0.3, 6, 0, F + 13.6, 0, "Institutional white", "Neon", { nc = true }), Color3.new(1, 0.96, 0.88), math.max(W, D), 1)
	local ok, err = pcall(ROOM[o.style] or ROOM.lounge, bb, W, D, o)
	if not ok then print("Airport: room " .. tostring(o.style) .. " failed: " .. tostring(err)) end
	-- where visitors go: the walkway outside the door, the door, then a spot on the room's middle walkway
	local inv = b.cf:inverse()
	local function P(x, z) return inv * (cf * Vector3.new(x, F, z)) end
	local it = ITEM[o.key]
	for _, z in ipairs({ -D / 2 + 4, -1, D / 2 - 7 }) do
		PT(b, "up" .. o.fl, { p = P(0, -D / 2 - 4), door = P(0, -D / 2 + 1), e = P(math.random(-15, 15) / 10, z),
			spend = it and it.eff.spend or 0, wait = FOODROOM[o.style] and 5 or 4 })
	end
end

------------------------------------------------------------------ things on the islands between the walkways
-- inside an island (0, F, 0) is its middle on the floor; keep within x -10..10, z -6..6
local BRIGHT = { "Bright red", "Bright blue", "Bright yellow", "Lime green", "Hot pink", "Cyan", "Bright orange", "Royal purple" }
local ISLAND = {}
function ISLAND.tables(bb)
	for _, dx in ipairs({ -5, 5 }) do
		U.cyl(bb, "Table", 4, 0.4, dx, F + 3, 0, "Institutional white", "SmoothPlastic")
		U.cyl(bb, "TableLeg", 0.6, 3, dx, F, 0, "Dark stone grey", "Metal")
		for a = 0, 270, 90 do
			local r = math.rad(a)
			U.seat(bb, dx + math.cos(r) * 3, F, math.sin(r) * 3, -a - 90, "Bright orange", 1.4)
		end
	end
end
function ISLAND.cart(bb)
	local col = U.pick(BRIGHT)
	U.blk(bb, "Cart", 6, 3.4, 3, 0, F + 0.6, 0, col, "SmoothPlastic")
	for _, x in ipairs({ -2.4, 2.4 }) do U.P(bb, "Wheel", Vector3.new(0.6, 1.4, 1.4), U.L(x, F + 0.7, 1.6), "Really black", nil, { shape = "cyl" }) end
	U.cyl(bb, "UmbrellaPole", 0.3, 5, 0, F + 4, 0, "Institutional white")
	U.cyl(bb, "Umbrella", 7, 0.4, 0, F + 9, 0, col, "Fabric")
	for i = -1, 1 do U.ball(bb, "Treat", 0.9, i * 1.6, F + 4.5, -0.6, U.pick({ "Bright yellow", "Hot pink", "Brown", "Institutional white" })) end
end
function ISLAND.massage(bb)
	for i = -1, 1 do
		U.seat(bb, i * 5, F + 0.8, 0, 180, "Really black", 3)
		U.P(bb, "ChairBack", Vector3.new(3, 3.6, 1), U.L(i * 5, F + 3, 1.6, 0, -12), "Really black", "Fabric")
		U.blk(bb, "Base", 3, 0.8, 3, i * 5, F, 0, "Dark stone grey", "Metal")
	end
end
function ISLAND.kiosk(bb)
	U.cyl(bb, "Kiosk", 7, 3.6, 0, F, 0, "Institutional white", "SmoothPlastic")
	U.cyl(bb, "Top", 8, 0.6, 0, F + 8, 0, U.pick(BRIGHT), "SmoothPlastic")
	U.cyl(bb, "Post", 0.6, 4.4, 0, F + 3.6, 0, "Dark stone grey", "Metal")
	for a = 0, 300, 60 do U.blk(bb, "Item", 1, 1, 1, math.cos(math.rad(a)) * 2.6, F + 3.6, math.sin(math.rad(a)) * 2.6, U.pick(BRIGHT), "Neon") end
end
function ISLAND.claw(bb)
	for _, x in ipairs({ -4, 4 }) do
		U.blk(bb, "Base", 4, 3, 4, x, F, 0, "Hot pink", "SmoothPlastic")
		U.blk(bb, "Glass", 4, 4, 4, x, F + 3, 0, "Pastel light blue", "Glass", { tr = 0.6 })
		for i = 1, 4 do U.ball(bb, "Prize", 1, x + math.random(-1, 1), F + 3.5, math.random(-1, 1), U.pick(BRIGHT)) end
		U.blk(bb, "Claw", 0.6, 1, 0.6, x, F + 6, 0, "Gold", "Metal")
		U.blk(bb, "Top", 4.2, 0.6, 4.2, x, F + 7, 0, "Hot pink", "Neon")
	end
end
function ISLAND.photobooth(bb)
	U.blk(bb, "Booth", 6, 8, 5, 0, F, 0, "Royal purple", "SmoothPlastic")
	U.blk(bb, "Curtain", 3, 6, 0.2, -1.2, F + 1, -2.6, "Bright red", "Fabric")
	U.blk(bb, "Sign", 5, 1.2, 0.2, 0, F + 7, -2.6, "Bright yellow", "Neon")
	U.light(U.blk(bb, "Flash", 1, 1, 0.2, 2, F + 5, -2.6, "Institutional white", "Neon"), Color3.new(1, 1, 1), 8)
end
function ISLAND.piano(bb)
	U.blk(bb, "Piano", 6, 2.4, 7, 0, F + 1.6, 0, "Really black", "SmoothPlastic", { refl = 0.3 })
	U.P(bb, "Lid", Vector3.new(6, 0.2, 7), U.L(0, F + 5, 0.8, 0, 30), "Really black", "SmoothPlastic", { refl = 0.3 })
	U.blk(bb, "Keys", 6, 0.3, 1.2, 0, F + 3, -4, "Institutional white")
	for _, p in ipairs({ { -2.6, -2.6 }, { 2.6, -2.6 }, { 0, 3 } }) do U.blk(bb, "Leg", 0.6, 1.6, 0.6, p[1], F, p[2], "Really black") end
	U.blk(bb, "Bench", 4, 1.8, 1.6, 0, F, -6, "Really black", "Fabric")
end
function ISLAND.benches(bb)
	for row = 0, 1 do
		for i = -3, 3 do U.seat(bb, i * 2.4, F, -2 + row * 4, row == 0 and 180 or 0, bb.plot.color, 2) end
		U.blk(bb, "SeatBack", 17, 2.4, 0.4, 0, F + 1, -0.8 + row * 1.6, "Dark stone grey", "Metal")
	end
end
function ISLAND.charging(bb)
	U.blk(bb, "Bar", 14, 3.6, 2, 0, F, 0, "Institutional white", "SmoothPlastic")
	for i = -2, 2 do U.blk(bb, "Charger", 0.8, 0.8, 0.8, i * 2.8, F + 3.6, 0, "Lime green", "Neon") end
	for i = -2, 2 do U.seat(bb, i * 2.8, F + 1.4, -2.2, 180, "Really black", 1.4) end
end
function ISLAND.rides(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.cyl(bb, "Base", 4, 0.8, x, F, 0, "Bright yellow", "SmoothPlastic")
		U.blk(bb, "RideCar", 2.2, 1.8, 3.4, x, F + 0.8, 0, U.pick({ "Bright red", "Bright blue", "Lime green" }), "SmoothPlastic")
		U.seat(bb, x, F + 2.6, 0.4, 0, "Really black", 1.4)
		U.ball(bb, "Light", 0.6, x, F + 3.4, -1.6, "Bright yellow", "Neon")
	end
end
function ISLAND.sculpture(bb)
	U.blk(bb, "Plinth", 6, 1, 6, 0, F, 0, "Institutional white", "Marble")
	U.blk(bb, "Cube", 3, 3, 3, 0, F + 1, 0, "Gold", "Metal", { refl = 0.4 }, 45)
	U.ball(bb, "Orb", 2.4, 0, F + 5.2, 0, "Gold", "Metal", { refl = 0.5 })
	U.P(bb, "Ring", Vector3.new(0.5, 6, 6), U.L(0, F + 7.6, 0, 0, 0, 0), "Gold", "Metal", { shape = "cyl", refl = 0.4 })
end
function ISLAND.planter(bb)
	U.blk(bb, "Planter", 8, 2, 8, 0, F, 0, "Brown", "Wood")
	U.blk(bb, "Soil", 7.4, 0.2, 7.4, 0, F + 2, 0, "Reddish brown", "Grass")
	U.cyl(bb, "Trunk", 0.8, 5, 0, F + 2, 0, "Brown", "Wood")
	U.ball(bb, "Leaves", 5, 0, F + 8, 0, "Bright green", "Grass")
	for _, p in ipairs({ { -2.6, -2.6 }, { 2.6, 2.6 } }) do U.ball(bb, "Flowers", 1.6, p[1], F + 2.6, p[2], U.pick({ "Hot pink", "Bright yellow", "Bright red" }), "Grass") end
end
function ISLAND.infoscreen(bb)
	U.blk(bb, "Pillar", 4, 9, 4, 0, F, 0, "Institutional white", "SmoothPlastic")
	for _, f in ipairs({ "Front", "Back", "Left", "Right" }) do
		local s = U.blk(bb, "Screen", 4.2, 3, 4.2, 0, F + 5, 0, "Really black", "SmoothPlastic", { nc = true })
		U.text(s, "SKY MALL\nSHOPS - FOOD - FUN", Color3.new(1, 0.85, 0.3), Color3.new(0.02, 0.05, 0.15), f)
	end
end
function ISLAND.minifountain(bb)
	U.cyl(bb, "Basin", 10, 1.4, 0, F, 0, "Light stone grey", "Marble")
	U.cyl(bb, "Water", 9, 0.2, 0, F + 1.3, 0, "Cyan", "Neon", { tr = 0.4, nc = true })
	U.cyl(bb, "Spout", 1, 4, 0, F + 1.4, 0, "Light stone grey", "Marble")
	U.fx(U.ball(bb, "Jet", 1.6, 0, F + 5.8, 0, "Cyan", "Neon", { tr = 0.3, nc = true }), "Sparkles")
end
function ISLAND.pooltable(bb)
	for _, x in ipairs({ -5, 5 }) do
		U.blk(bb, "Table", 4.4, 0.6, 8, x, F + 2.6, 0, "Dark green", "Fabric")
		U.blk(bb, "Rim", 4.8, 0.4, 8.4, x, F + 2.4, 0, "Reddish brown", "Wood")
		U.blk(bb, "Legs", 3.6, 2.4, 7, x, F, 0, "Reddish brown", "Wood")
		for i = 1, 3 do U.ball(bb, "Ball", 0.5, x + math.random(-1, 1), F + 3.4, math.random(-3, 3), U.pick(BRIGHT)) end
	end
end
function ISLAND.pingpong(bb)
	U.blk(bb, "Table", 5, 0.3, 9, 0, F + 2.6, 0, "Bright blue", "SmoothPlastic")
	U.blk(bb, "Net", 5.4, 0.6, 0.1, 0, F + 2.9, 0, "Institutional white", "Fabric")
	U.blk(bb, "Legs", 4, 2.6, 7, 0, F, 0, "Dark stone grey", "Metal")
	U.ball(bb, "Ball", 0.3, 1, F + 3.4, -2, "Bright orange")
end
function ISLAND.loungechairs(bb)
	for i = 0, 3 do
		local x = -7.5 + i * 5
		U.seat(bb, x, F + 0.6, 0, 180, U.pick({ "Bright red", "Navy blue", "Sand blue" }), 3)
		U.blk(bb, "Back", 3.4, 3, 0.8, x, F + 0.6, 1.6, "Dark stone grey", "Fabric")
		U.blk(bb, "Base", 3, 0.6, 3, x, F, 0, "Dark stone grey")
	end
end
function ISLAND.beanbags(bb)
	for i = 0, 5 do U.blk(bb, "BeanBag", 3, 1.8, 3, -7 + (i % 3) * 7, F, -2 + math.floor(i / 3) * 4, U.pick(BRIGHT), "Fabric") end
end
function ISLAND.airhockey(bb)
	U.blk(bb, "Table", 4.6, 3, 8, 0, F, 0, "Institutional white", "SmoothPlastic")
	U.blk(bb, "Rim", 5, 0.4, 8.4, 0, F + 3, 0, "Really red", "Neon")
	U.cyl(bb, "Puck", 0.8, 0.2, 0, F + 3.1, 0, "Really black")
	for _, z in ipairs({ -3, 3 }) do U.cyl(bb, "Paddle", 1, 0.5, 0, F + 3.1, z, "Bright blue") end
end
function ISLAND.foosball(bb)
	for _, x in ipairs({ -4, 4 }) do
		U.blk(bb, "Table", 3.4, 3, 6, x, F, 0, "Brown", "Wood")
		U.blk(bb, "Field", 3, 0.1, 5.6, x, F + 3, 0, "Bright green", "Grass")
		for z = -2, 2, 1.3 do U.blk(bb, "Rod", 5, 0.2, 0.2, x, F + 3.3, z, "Light stone grey", "Metal") end
	end
end
function ISLAND.reading(bb)
	U.blk(bb, "Shelf", 10, 6, 1.4, 0, F, 3.6, "Brown", "Wood")
	for y = 1, 2 do for i = -2, 2 do U.blk(bb, "Book", 1.6, 1.6, 1.2, i * 2, F + y * 2.4, 3.6, U.pick(BRIGHT)) end end
	for _, x in ipairs({ -4, 4 }) do U.seat(bb, x, F + 0.6, -1, 180, "Bright red", 3) U.blk(bb, "ArmChair", 3.6, 3, 1, x, F, 0.6, "Bright red", "Fabric") end
	U.cyl(bb, "Lamp", 0.3, 5, 0, F, -1, "Dark stone grey") U.light(U.ball(bb, "Bulb", 1.4, 0, F + 5.4, -1, "Cool yellow", "Neon"), Color3.new(1, 0.9, 0.6), 10)
end
function ISLAND.racers(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.blk(bb, "Cabinet", 4, 6, 2, x, F, 3, "Really black", "SmoothPlastic")
		U.blk(bb, "Screen", 3.4, 2.4, 0.2, x, F + 3.4, 1.9, "Cyan", "Neon")
		U.seat(bb, x, F, -1.6, 0, "Bright red", 2)
		U.P(bb, "Wheel", Vector3.new(0.3, 1.6, 1.6), U.L(x, F + 2.6, 0.6, 90), "Really black", nil, { shape = "cyl" })
	end
end
function ISLAND.pinball(bb)
	for i = -1, 1 do
		U.P(bb, "Pinball", Vector3.new(2.4, 1, 5), U.L(i * 5, F + 3.2, 0, 0, 8), U.pick({ "Bright red", "Royal purple", "Bright blue" }), "SmoothPlastic")
		U.blk(bb, "Legs", 2, 2.8, 4, i * 5, F, 0, "Dark stone grey", "Metal")
		U.blk(bb, "Backbox", 2.4, 3, 0.6, i * 5, F + 3.6, 2.4, "Really black")
		U.blk(bb, "Lights", 2, 2, 0.1, i * 5, F + 4, 2.05, U.pick({ "Lime green", "Hot pink" }), "Neon")
	end
end
function ISLAND.trees(bb)
	for _, x in ipairs({ -5, 5 }) do
		U.cyl(bb, "Pot", 4, 2.4, x, F, 0, "Reddish brown", "SmoothPlastic")
		U.cyl(bb, "Trunk", 0.8, 6, x, F + 2.4, 0, "Brown", "Wood")
		U.ball(bb, "Leaves", 6, x, F + 10, 0, "Dark green", "Grass")
		U.ball(bb, "Leaves", 4, x + 1, F + 12, 0.6, "Bright green", "Grass")
	end
end
function ISLAND.telescope(bb)
	for _, a in ipairs({ 0, 120, 240 }) do U.P(bb, "TripodLeg", Vector3.new(0.3, 4, 0.3), U.L(math.cos(math.rad(a)) * 0.8, F + 1.9, math.sin(math.rad(a)) * 0.8, 0, 0, 12), "Dark stone grey", "Metal") end
	U.P(bb, "Tube", Vector3.new(1.2, 1.2, 5), U.L(0, F + 4.4, 1, 0, 20), "Institutional white", "Metal", { shape = "cyl" })
	U.P(bb, "Tube", Vector3.new(5, 1.2, 1.2), U.L(0, F + 4.4, 1, 90, 0, 20), "Institutional white", "Metal", { shape = "cyl" })
	U.blk(bb, "Sign", 2, 1, 0.2, 0, F, -2.4, "Navy blue")
end
function ISLAND.hoops(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.blk(bb, "Ramp", 3.6, 2.6, 7, x, F, 0, "Bright orange", "SmoothPlastic")
		U.blk(bb, "Backboard", 3.6, 3, 0.3, x, F + 6, 3.4, "Institutional white")
		U.P(bb, "Hoop", Vector3.new(0.2, 2, 2), U.L(x, F + 6, 2.2, 0, 0, 90), "Bright red", "Metal", { shape = "cyl", nc = true })
		U.ball(bb, "Basketball", 1, x, F + 3.1, -1, "Bright orange")
	end
end
function ISLAND.dancefloor(bb)
	for i = 0, 15 do
		local t = U.blk(bb, "Tile", 4.6, 0.2, 2.3, -6.9 + (i % 4) * 4.6, F, -3.45 + math.floor(i / 4) * 2.3, U.pick({ "Hot pink", "Cyan", "Lime green", "Bright yellow", "Royal purple" }), "Neon")
		if i == 5 then U.light(t, Color3.new(1, 0.3, 1), 20) end
	end
	U.fx(U.ball(bb, "DiscoBall", 2, 0, F + 12, 0, "Institutional white", "Glass", { refl = 0.8, nc = true }), "Sparkles")
end
function ISLAND.koi(bb)
	U.cyl(bb, "Rim", 10, 1.2, 0, F, 0, "Dark stone grey", "Slate")
	U.cyl(bb, "Water", 9, 0.2, 0, F + 1, 0, "Bright blue", "Glass", { tr = 0.3, nc = true })
	for i = 1, 5 do U.blk(bb, "Koi", 1.2, 0.3, 0.5, math.random(-3, 3), F + 0.8, math.random(-3, 3), U.pick({ "Bright orange", "Institutional white", "Bright red" }), nil, { nc = true }, math.random(0, 180)) end
	U.ball(bb, "Rock", 2, 3, F + 1.2, 2, "Medium stone grey", "Slate")
end
function ISLAND.rocket(bb)
	U.cyl(bb, "Pad", 6, 0.6, 0, F, 0, "Dark stone grey", "Metal")
	U.cyl(bb, "Body", 3, 9, 0, F + 0.6, 0, "Institutional white", "Metal")
	U.ball(bb, "Nose", 3, 0, F + 9.8, 0, "Bright red", "Metal")
	for _, a in ipairs({ 0, 120, 240 }) do U.P(bb, "Fin", Vector3.new(0.3, 3, 2), U.L(math.cos(math.rad(a)) * 1.8, F + 2.1, math.sin(math.rad(a)) * 1.8, -a), "Bright red", "Metal") end
	U.blk(bb, "Flame", 1.6, 0.6, 1.6, 0, F + 0.6, 0, "Neon orange", "Neon", { nc = true })
end
function ISLAND.trampoline(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.cyl(bb, "Frame", 7, 0.6, x, F + 1.4, 0, "Bright blue", "Metal")
		U.cyl(bb, "Mat", 6, 0.3, x, F + 1.7, 0, "Really black", "Fabric")
		for _, d in ipairs({ -2.6, 2.6 }) do U.blk(bb, "Leg", 0.4, 1.4, 0.4, x + d, F, 0, "Dark stone grey", "Metal") end
	end
end
function ISLAND.dj(bb)
	U.blk(bb, "Booth", 8, 3.6, 3, 0, F, 0, "Really black", "SmoothPlastic")
	U.blk(bb, "Front", 8, 2, 0.1, 0, F + 1, -1.55, "Royal purple", "Neon")
	for _, x in ipairs({ -2, 2 }) do U.cyl(bb, "Deck", 2, 0.3, x, F + 3.6, 0, "Dark stone grey", "Metal") end
	for _, x in ipairs({ -7, 7 }) do U.blk(bb, "Speaker", 3, 6, 3, x, F, 0, "Really black") U.cyl(bb, "Cone", 2, 0.2, x, F + 4, -1.5, "Dark stone grey") end
end
function ISLAND.carousel(bb)
	U.cyl(bb, "Base", 10, 1, 0, F, 0, "Bright red", "SmoothPlastic")
	U.cyl(bb, "Pole", 1, 8, 0, F + 1, 0, "Gold", "Metal")
	U.cyl(bb, "Top", 10, 1, 0, F + 9, 0, "Bright yellow", "SmoothPlastic")
	local turning = {}
	for a = 0, 270, 90 do
		local x, z = math.cos(math.rad(a)) * 3.4, math.sin(math.rad(a)) * 3.4
		table.insert(turning, U.blk(bb, "Horse", 1, 2, 2.6, x, F + 2.4, z, U.pick({ "Institutional white", "Brown", "Pink" }), nil, { nc = true }, -a))
		table.insert(turning, U.blk(bb, "HorsePole", 0.3, 8, 0.3, x, F + 1, z, "Gold", "Metal", { nc = true }))
	end
	U.spin(turning, bb.cf * U.L(0, F, 0), "y", 40)
end
function ISLAND.zen(bb)
	U.blk(bb, "Sand", 16, 0.4, 8, 0, F, 0, "Brick yellow", "Sand")
	for i = -3, 3 do U.blk(bb, "Rake", 15, 0.05, 0.2, 0, F + 0.4, i, "Light stone grey", nil, { nc = true }) end
	for _, p in ipairs({ { -4, 1 }, { 3, -1 }, { 6, 2 } }) do U.ball(bb, "Stone", 2, p[1], F + 0.8, p[2], "Dark stone grey", "Slate") end
	U.cyl(bb, "Bonsai", 0.6, 2, -6, F + 0.4, -2, "Brown") U.ball(bb, "BonsaiTop", 2.4, -6, F + 3, -2, "Dark green", "Grass")
end
function ISLAND.balloon(bb)
	U.blk(bb, "Basket", 3, 2, 3, 0, F + 1, 0, "Brown", "Wood")
	for _, p in ipairs({ { -1.2, -1.2 }, { 1.2, -1.2 }, { -1.2, 1.2 }, { 1.2, 1.2 } }) do U.blk(bb, "Rope", 0.1, 3, 0.1, p[1], F + 3, p[2], "Brown", nil, { nc = true }) end
	U.ball(bb, "Balloon", 8, 0, F + 9, 0, U.pick({ "Bright red", "Bright yellow", "Royal purple" }), "Fabric", { nc = true })
	U.blk(bb, "Stand", 0.4, 1, 0.4, 0, F, 0, "Dark stone grey")
end
function ISLAND.chess(bb)
	for i = 0, 15 do
		local x, z = i % 4, math.floor(i / 4)
		U.blk(bb, "Square", 2.4, 0.2, 2.4, -3.6 + x * 2.4, F, -3.6 + z * 2.4, (x + z) % 2 == 0 and "Institutional white" or "Really black", "Marble")
	end
	U.cyl(bb, "King", 1.4, 4, -1.2, F + 0.2, -1.2, "Institutional white") U.ball(bb, "Crown", 1, -1.2, F + 4.6, -1.2, "Gold", "Metal")
	U.cyl(bb, "Pawn", 1.2, 2, 1.2, F + 0.2, 1.2, "Really black") U.ball(bb, "Head", 1.2, 1.2, F + 2.6, 1.2, "Really black")
end
function ISLAND.jukebox(bb)
	U.blk(bb, "Jukebox", 3.4, 6, 2, 0, F, 2.4, "Bright red", "SmoothPlastic")
	U.blk(bb, "Glow", 2.6, 2.4, 0.1, 0, F + 3, 1.35, "Bright yellow", "Neon")
	for _, x in ipairs({ -6, 6 }) do U.cyl(bb, "Table", 3, 3, x, F, 0, "Institutional white") U.seat(bb, x, F, -2.6, 180, "Bright red", 1.6) end
end
function ISLAND.robot(bb)
	U.blk(bb, "Legs", 2.4, 3, 1.4, 0, F, 0, "Light stone grey", "Metal")
	U.blk(bb, "Body", 3.4, 3.4, 2, 0, F + 3, 0, "Light stone grey", "Metal")
	U.blk(bb, "Head", 2.4, 2, 2, 0, F + 6.4, 0, "Light stone grey", "Metal")
	for _, x in ipairs({ -0.6, 0.6 }) do U.blk(bb, "Eye", 0.5, 0.5, 0.1, x, F + 7.4, -1.05, "Cyan", "Neon") end
	for _, x in ipairs({ -2.2, 2.2 }) do U.blk(bb, "Arm", 0.8, 3, 0.8, x, F + 3.2, 0, "Dark stone grey", "Metal") end
	U.blk(bb, "Tray", 3, 0.2, 1.6, 2.2, F + 4.6, -1.2, "Institutional white", "Metal")
end
function ISLAND.globe(bb)
	U.cyl(bb, "Pedestal", 5, 3, 0, F, 0, "Institutional white", "Marble")
	local g = U.ball(bb, "Globe", 5, 0, F + 6, 0, "Gold", "Metal", { refl = 0.5 })
	U.fx(g, "Sparkles")
	U.P(bb, "Ring", Vector3.new(0.4, 6.6, 6.6), U.L(0, F + 6, 0, 90, 0, 23), "Gold", "Metal", { shape = "cyl", nc = true })
end
function ISLAND.lightart(bb)
	for i = 0, 4 do U.P(bb, "Ring", Vector3.new(0.4, 6 - i, 6 - i), U.L(0, F + 2 + i * 2, 0, i * 36, 0, 90), U.pick({ "Hot pink", "Cyan", "Lime green", "Bright yellow" }), "Neon", { shape = "cyl", nc = true }) end
	U.cyl(bb, "Base", 3, 1, 0, F, 0, "Really black", "Metal")
end

-- more islands: the everyday things a real terminal has
function ISLAND.gateseats(bb)
	for row = 0, 1 do
		for i = -3, 3 do U.seat(bb, i * 2.4, F, -2 + row * 4, row == 0 and 180 or 0, "Navy blue", 2) end
		U.blk(bb, "SeatBack", 17, 2.4, 0.4, 0, F + 1, -0.8 + row * 1.6, "Dark stone grey", "Metal")
	end
	for _, x in ipairs({ -9, 9 }) do U.blk(bb, "PowerPost", 0.8, 3, 0.8, x, F, 0, "Institutional white") U.blk(bb, "Plug", 0.85, 0.4, 0.4, x, F + 2.4, 0, "Lime green", "Neon") end
end
function ISLAND.water(bb)
	U.blk(bb, "Fountain", 2.4, 3.6, 1.6, -2, F, 0, "Light stone grey", "Metal")
	U.blk(bb, "Refill", 2.4, 6, 1.6, 2, F, 0, "Institutional white", "SmoothPlastic")
	U.blk(bb, "RefillScreen", 1.6, 1, 0.1, 2, F + 4.4, -0.85, "Cyan", "Neon")
	local s = U.blk(bb, "Sign", 4, 1, 0.2, 2, F + 6.4, 0, "Bright blue")
	U.text(s, "WATER REFILL", Color3.new(1, 1, 1), nil, "Front")
end
function ISLAND.recycle(bb)
	local cols = { "Bright blue", "Bright yellow", "Bright green", "Dark stone grey" }
	for i = 1, 4 do
		U.blk(bb, "Bin", 2, 3.4, 2, -3.3 + (i - 1) * 2.2, F, 0, cols[i], "SmoothPlastic")
		U.blk(bb, "Slot", 1.2, 0.3, 0.1, -3.3 + (i - 1) * 2.2, F + 2.8, -1.05, "Really black")
	end
end
function ISLAND.infokiosk(bb)
	U.cyl(bb, "Base", 3, 1, 0, F, 0, "Dark stone grey", "Metal")
	U.blk(bb, "Kiosk", 2.4, 6, 1, 0, F + 1, 0, "Institutional white", "SmoothPlastic")
	for _, z in ipairs({ -0.55, 0.55 }) do U.blk(bb, "Screen", 2, 3, 0.1, 0, F + 3.4, z, "Cyan", "Neon") end
	U.blk(bb, "i", 1.2, 1.2, 1.2, 0, F + 7.2, 0, "Bright blue", "Neon")
end
function ISLAND.workpods(bb)
	for _, x in ipairs({ -4.5, 4.5 }) do
		U.blk(bb, "PodWalls", 4, 7, 4, x, F, 0, "Institutional white", "SmoothPlastic", { tr = 0.1 })
		U.blk(bb, "PodGlass", 3, 5, 0.2, x, F + 1, -2.05, "Pastel light blue", "Glass", { tr = 0.5 })
		U.blk(bb, "PodSign", 3, 0.8, 0.2, x, F + 6.2, -2.1, "Lime green", "Neon")
	end
end
function ISLAND.adscreen(bb)
	U.blk(bb, "Stand", 1, 2, 1, 0, F, 0, "Dark stone grey", "Metal")
	local s = U.blk(bb, "AdScreen", 6, 9, 0.6, 0, F + 2, 0, "Really black", "SmoothPlastic")
	for _, f in ipairs({ "Front", "Back" }) do U.text(s, U.pick({ "VISIT DUTY FREE!", "FLY FIRST CLASS", "TRY THE SUSHI!", "SPA - 2ND FLOOR" }), Color3.new(1, 1, 1), BrickColor.new(U.pick(BRIGHT)).Color, f) end
end
function ISLAND.plantwall(bb)
	U.blk(bb, "Wall", 14, 8, 1, 0, F, 0, "Brown", "Wood")
	for i = 1, 14 do U.ball(bb, "Leaf", 1.8, math.random(-6, 6), F + 1 + math.random() * 6, -0.7, U.pick({ "Dark green", "Bright green", "Lime green" }), "Grass", { nc = true }) end
	U.blk(bb, "Planter", 14, 1, 2, 0, F, -1.2, "Reddish brown")
end
function ISLAND.cartbay(bb)
	U.blk(bb, "Bay", 10, 0.2, 4, 0, F, 0, "Dark stone grey", "Metal", { nc = true })
	for i = 0, 3 do
		local x = -3.6 + i * 2.4
		U.blk(bb, "Cart", 2, 0.3, 3.4, x, F + 1, 0, "Light stone grey", "Metal")
		U.blk(bb, "Handle", 2, 2.4, 0.2, x, F + 1, 1.6, "Light stone grey", "Metal")
	end
	local s = U.blk(bb, "Sign", 4, 1, 0.2, 0, F + 4.4, 1.8, "Bright yellow")
	U.text(s, "FREE CARTS", Color3.new(0, 0, 0), nil, "Front")
end
function ISLAND.lockers(bb)
	for i = 0, 4 do
		U.blk(bb, "Locker", 2, 7, 2, -4 + i * 2.05, F, 0, "Light stone grey", "Metal")
		U.blk(bb, "Light", 0.4, 0.4, 0.1, -4 + i * 2.05, F + 5, -1.05, i % 2 == 0 and "Lime green" or "Really red", "Neon")
	end
end
function ISLAND.transferkiosk(bb)
	for _, x in ipairs({ -3, 0, 3 }) do
		U.blk(bb, "Kiosk", 2.2, 5, 1.4, x, F, 0, "Institutional white", "SmoothPlastic")
		U.blk(bb, "Screen", 1.8, 1.4, 0.1, x, F + 3.2, -0.75, "Lime green", "Neon")
	end
	local s = U.blk(bb, "Sign", 9, 1.2, 0.2, 0, F + 6.4, 0, "Navy blue")
	U.text(s, "FLIGHT TRANSFERS", Color3.new(1, 1, 1), nil, "Front")
end
function ISLAND.photospot(bb)
	U.blk(bb, "Backdrop", 10, 7, 0.4, 0, F, 2, "Navy blue", "SmoothPlastic")
	local s = U.blk(bb, "Words", 9, 2.4, 0.2, 0, F + 4, 1.7, "Navy blue")
	U.text(s, "I LOVE THIS AIRPORT", Color3.new(1, 0.85, 0.3), nil, "Front")
	U.blk(bb, "Heart", 2, 2, 0.4, 0, F + 1.5, 1.7, "Hot pink", "Neon", nil, 0)
	U.blk(bb, "Wings", 8, 1.4, 0.3, 0, F + 6.5, 1.7, "Institutional white")
end
function ISLAND.aquariumcol(bb)
	U.cyl(bb, "Base", 6, 1.2, 0, F, 0, "Dark stone grey", "Metal")
	U.cyl(bb, "Tank", 5.4, 11, 0, F + 1.2, 0, "Cyan", "Glass", { tr = 0.5 })
	for i = 1, 6 do U.blk(bb, "Fish", 1, 0.5, 0.4, math.random(-1, 1), F + 2 + math.random() * 8, math.random(-1, 1), U.pick({ "Bright orange", "Bright yellow", "Hot pink" }), nil, { nc = true }, math.random(0, 180)) end
	U.cyl(bb, "Top", 6, 1.2, 0, F + 12.2, 0, "Dark stone grey", "Metal")
end
function ISLAND.perfume(bb)
	U.blk(bb, "Table", 8, 3.4, 4, 0, F, 0, "Institutional white", "Marble")
	for i = -2, 2 do U.cyl(bb, "Bottle", 0.7, 1.4, i * 1.4, F + 3.4, 0, U.pick({ "Gold", "Hot pink", "Royal purple", "Cyan" }), "Glass", { tr = 0.2 }) end
	local s = U.blk(bb, "Poster", 6, 4, 0.2, 0, F + 5, 1.9, "Royal purple", "SmoothPlastic")
	U.text(s, "NEW SCENT\nDUTY FREE", Color3.new(1, 1, 1), nil, "Front")
end
function ISLAND.cardisplay(bb)
	U.cyl(bb, "Turntable", 12, 0.6, 0, F, 0, "Institutional white", "Marble")
	local c = { model = bb.model, cf = bb.cf * U.L(0, F + 0.6, 0, 30), plot = bb.plot }
	U.blk(c, "CarBody", 5, 2, 9, 0, 0.6, 0, "Really red", "SmoothPlastic", { refl = 0.3 })
	U.blk(c, "CarTop", 4.4, 1.6, 4.5, 0, 2.6, 0.5, "Really red", "SmoothPlastic", { refl = 0.3 })
	U.blk(c, "CarGlass", 4.5, 1.2, 4.6, 0, 2.8, 0.5, "Really black", "Glass", { tr = 0.3 })
	for _, w in ipairs({ { -2.4, -3 }, { 2.4, -3 }, { -2.4, 3 }, { 2.4, 3 } }) do U.P(c, "Wheel", Vector3.new(0.8, 1.6, 1.6), U.L(w[1], 0.8, w[2]), "Really black", nil, { shape = "cyl" }) end
	local s = U.blk(bb, "Sign", 6, 1.4, 0.2, 0, F + 0.6, -5.5, "Gold", "Neon")
	U.text(s, "WIN THIS CAR!", Color3.new(0, 0, 0), nil, "Front")
end
function ISLAND.shoeshine(bb)
	for _, x in ipairs({ -3, 3 }) do
		U.blk(bb, "Platform", 4, 2, 4, x, F, 0, "Brown", "Wood")
		U.seat(bb, x, F + 2, 0.6, 180, "Bright red", 2.4)
		U.blk(bb, "SeatBack", 2.4, 2.4, 0.4, x, F + 2.4, 1.8, "Bright red", "Fabric")
	end
	local s = U.blk(bb, "Sign", 6, 1, 0.2, 0, F + 6, 2, "Really black")
	U.text(s, "SHOE SHINE", Color3.new(1, 0.85, 0.3), nil, "Front")
end

function K.uisland(b, o)
	local c = b.cf * U.L(o.x, LV[o.fl] - F, o.z)
	local bb = { model = b.model, cf = c, plot = b.plot }
	local ok, err = pcall(ISLAND[o.style] or ISLAND.planter, bb, o)
	if not ok then print("Airport: island " .. tostring(o.style) .. " failed: " .. tostring(err)) end
	-- people come and look/sit/play here, from the walkway in front of it
	local it = ITEM[o.key]
	PT(b, "up" .. o.fl, { p = Vector3.new(o.x + math.random(-3, 3), LV[o.fl], o.z - 9), spend = it and it.eff.spend or 0, wait = 4 })
end
