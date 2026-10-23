-- shared (server + every player's computer): the bikes - prices, how they ride, and what they look like.
-- speed = top speed (studs/s), lift = how hard you can pull the front up, bp = the balance point (radians: the angle
-- where the bike balances on its back wheel - higher is easier to hold), rF / rR = front / rear wheel radius,
-- base = wheelbase, seat = seat height (all in studs; a rider is 5 studs tall, so 1 metre is about 2.9 studs).
-- kind: "mini" (a little street mini-bike with mag wheels), "dirt" (a pit / dirt bike) or "emoto" (an electric
-- dirt bike: alloy frame round a battery, long thin seat, spoked wheels). The bike's frame: the ground is y = 0, the
-- front points to -Z.
local BIKES = {
	{ name = "Mini Bike", kind = "mini", price = 0, speed = 38, accel = 22, lift = 5.6, bp = 1.12, rF = 0.8, rR = 0.8, base = 4.3, seat = 2.9,
		body = "Really red", trim = "Institutional white", frame = "Really black", rim = "Medium stone grey", num = "7" },
	{ name = "Pit Bike", kind = "dirt", price = 400, speed = 48, accel = 26, lift = 6.0, bp = 1.16, rF = 0.95, rR = 0.85, base = 4.6, seat = 3.2,
		body = "Bright orange", trim = "Institutional white", frame = "Really black", rim = "Really black", num = "21" },
	{ name = "Volt Bee", kind = "emoto", price = 1200, speed = 58, accel = 30, lift = 6.4, bp = 1.2, rF = 0.98, rR = 0.98, base = 5.3, seat = 3.35,
		body = "Really black", trim = "Really black", frame = "Medium stone grey", rim = "Really black", accent = "Toothpaste", num = "B1" },
	{ name = "Stinger", kind = "emoto", price = 2500, speed = 66, accel = 34, lift = 6.8, bp = 1.23, rF = 1.0, rR = 1.0, base = 5.4, seat = 3.4,
		body = "Institutional white", trim = "Lime green", frame = "Really black", rim = "Gold", accent = "Lime green", num = "99" },
	{ name = "Thunder X", kind = "emoto", price = 5000, speed = 76, accel = 38, lift = 7.3, bp = 1.27, rF = 1.1, rR = 1.05, base = 5.9, seat = 3.7,
		body = "Royal purple", trim = "New Yeller", frame = "Really black", rim = "Really black", accent = "Hot pink", num = "X" },
	{ name = "Gold Mini", kind = "mini", price = 9000, speed = 56, accel = 32, lift = 6.6, bp = 1.3, rF = 0.8, rR = 0.8, base = 4.3, seat = 2.9,
		body = "Gold", trim = "Really black", frame = "Really black", rim = "Gold", num = "1" },
}
local BIKE = {}
for i, b in ipairs(BIKES) do
	b.index = i
	b.r = math.max(b.rF, b.rR)
	BIKE[b.name] = b
end

-- the parts of a bike: { name, size, CFrame in the bike's frame, colour, material, shape, sign text }
local function BikeParts(b)
	local out = {}
	local V3 = Vector3.new
	local function box(n, size, cf, c, mat, text) table.insert(out, { n, size, cf, c, mat or "SmoothPlastic", nil, text }) end
	local function cylAt(n, d, len, cf, c, mat) table.insert(out, { n, V3(len, d, d), cf, c, mat or "Metal", "cyl" }) end
	-- a round tube from a to b
	local function tube(n, a, b2, d, c, mat)
		local len = (b2 - a).magnitude
		if len < 0.05 then return end
		table.insert(out, { n, V3(len, d, d), CFrame.new((a + b2) / 2, b2) * CFrame.Angles(0, math.pi / 2, 0), c, mat or "Metal", "cyl" })
	end
	local half, seat = b.base / 2, b.seat
	local wheelW = b.kind == "mini" and 0.6 or 0.42
	-- WHEELS: tyre with tread, rim, spokes (mag spokes on the mini), hub, brake disc and caliper, sprocket
	local function wheel(n, at, r, front)
		cylAt(n .. "Tire", r * 2, wheelW, at, "Really black", "SmoothPlastic")
		cylAt(n .. "Tread", r * 2 - 0.1, wheelW + 0.04, at, "Dark stone grey", "Slate")
		cylAt(n .. "Rim", r * 1.5, wheelW + 0.08, at, b.rim, "Metal")
		cylAt(n .. "RimIn", r * 1.38, wheelW + 0.1, at, "Really black", "SmoothPlastic")
		local spokes = b.kind == "mini" and 5 or 10
		local thick = b.kind == "mini" and 0.36 or 0.2
		local len = r * 0.69 - 0.22
		for k = 1, spokes do
			local a = k / spokes * math.pi * 2
			box(n .. "Spoke", V3(wheelW + 0.14, thick, len), at * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, -(0.22 + len / 2)), b.kind == "mini" and b.rim or "Medium stone grey", "Metal")
		end
		cylAt(n .. "Hub", 0.5, wheelW + 0.2, at, "Medium stone grey", "Metal")
		cylAt(n .. "Disc", r * 1.0, 0.2, at * CFrame.new(-(wheelW / 2 + 0.2), 0, 0), "Institutional white", "DiamondPlate")
		box(n .. "Caliper", V3(0.3, 0.45, 0.35), at * CFrame.new(-(wheelW / 2 + 0.3), r * 0.45, front and 0.15 or 0.3), "Really red", "Metal")
		if not front then cylAt("Sprocket", r * 0.95, 0.2, at * CFrame.new(wheelW / 2 + 0.22, 0, 0), "Dark stone grey", "Metal") end
	end
	local fA = V3(0, b.rF, -half)        -- front axle
	local rA = V3(0, b.rR, half)         -- rear axle
	wheel("Front", CFrame.new(fA), b.rF, true)
	wheel("Rear", CFrame.new(rA), b.rR, false)
	-- FRONT END: raked fork legs (thick dark uppers, shiny lowers), two clamps, bars with grips and levers
	local rake = math.rad(b.kind == "mini" and 24 or 27)
	local headY = seat + (b.kind == "mini" and 0.55 or 0.75)
	local up = V3(0, math.cos(rake), math.sin(rake))     -- along the fork, up and back
	local forkLen = (headY - b.rF) / math.cos(rake)
	local headTop = fA + up * forkLen
	for _, sx in ipairs({ -0.36, 0.36 }) do
		local a = fA + V3(sx, 0, 0)
		local mid = a + up * (forkLen * 0.5)
		tube("ForkLower", a, mid, 0.24, (b.kind == "emoto" and b.rim == "Gold") and "Gold" or "Medium stone grey", "Metal")
		tube("ForkUpper", mid - up * 0.15, a + up * forkLen, 0.36, "Really black", "Metal")
		box("AxleNut", V3(0.2, 0.3, 0.3), CFrame.new(a + V3(sx > 0 and 0.15 or -0.15, 0, 0)), "Medium stone grey", "Metal")
	end
	local clampLo, clampHi = fA + up * (forkLen - 0.45), headTop
	box("LowerClamp", V3(1.0, 0.22, 0.45), CFrame.new(clampLo, clampLo + up) * CFrame.Angles(-math.pi / 2, 0, 0), b.frame, "Metal")
	box("UpperClamp", V3(1.0, 0.2, 0.45), CFrame.new(clampHi, clampHi + up) * CFrame.Angles(-math.pi / 2, 0, 0), b.frame, "Metal")
	local barC = clampHi + V3(0, b.kind == "mini" and 0.35 or 0.55, 0.15)
	tube("Riser", clampHi + V3(-0.25, 0, 0), barC + V3(-0.25, 0, 0), 0.2, "Really black")
	tube("Riser", clampHi + V3(0.25, 0, 0), barC + V3(0.25, 0, 0), 0.2, "Really black")
	local bw = b.kind == "mini" and 1.05 or 1.3
	tube("Handlebar", barC + V3(-bw, 0.08, 0.1), barC + V3(bw, 0.08, 0.1), 0.17, b.kind == "emoto" and "Really black" or "Medium stone grey")
	if b.kind ~= "mini" then tube("BarPad", barC + V3(-0.35, 0.18, 0.1), barC + V3(0.35, 0.18, 0.1), 0.3, b.trim, "Fabric") end
	for _, sx in ipairs({ -1, 1 }) do
		tube("Grip", barC + V3(sx * (bw - 0.4), 0.08, 0.1), barC + V3(sx * (bw + 0.05), 0.08, 0.1), 0.26, "Really black", "Fabric")
		box("Lever", V3(0.75, 0.08, 0.12), CFrame.new(barC + V3(sx * (bw - 0.45), 0.05, -0.12)) * CFrame.Angles(0, sx * 0.25, 0), "Medium stone grey", "Metal")
		box("Mirror", V3(0.3, 0.2, 0.06), CFrame.new(barC + V3(sx * (bw - 0.6), 0.75, 0.05)), "Really black", "SmoothPlastic")
		tube("MirrorStem", barC + V3(sx * (bw - 0.6), 0.12, 0.08), barC + V3(sx * (bw - 0.6), 0.65, 0.05), 0.1, "Really black")
	end
	-- headlight / number plate and the front mudguard
	local lamp = clampLo - up * 0.35 + V3(0, 0, -0.45)
	if b.kind == "mini" then
		box("Cowl", V3(1.1, 1.0, 0.8), CFrame.new(lamp + V3(0, 0.35, 0.1)) * CFrame.Angles(-rake, 0, 0), b.body, "SmoothPlastic")
		cylAt("Headlight", 0.65, 0.2, CFrame.new(lamp + V3(0, 0.3, -0.32)) * CFrame.Angles(0, math.pi / 2, 0), "Institutional white", "Neon")
		box("FrontFender", V3(0.7, 0.14, 1.5), CFrame.new(fA + V3(0, b.rF + 0.22, 0)) * CFrame.Angles(0.1, 0, 0), b.trim, "SmoothPlastic")
	else
		box("NumberPlate", V3(1.0, 1.0, 0.12), CFrame.new(lamp + V3(0, 0.15, 0)) * CFrame.Angles(-rake * 0.6, 0, 0), b.trim, "SmoothPlastic", b.num)
		cylAt("Headlight", 0.5, 0.18, CFrame.new(lamp + V3(0, -0.05, -0.12)) * CFrame.Angles(0, math.pi / 2, 0), "Institutional white", "Neon")
		local f0 = clampLo - up * 0.15
		box("FrontFender", V3(0.62, 0.12, 1.3), CFrame.new(f0 + V3(0, -0.15, -0.55)) * CFrame.Angles(0.28, 0, 0), b.trim, "SmoothPlastic")
		box("FenderTail", V3(0.6, 0.12, 0.7), CFrame.new(f0 + V3(0, -0.15, 0.4)) * CFrame.Angles(-0.35, 0, 0), b.trim, "SmoothPlastic")
	end
	-- REAR: swingarm on both sides, a shock with a coloured spring, chain, mudguard, tail light, plate
	local pivot = V3(0, b.rR + (b.kind == "mini" and 0.45 or 0.6), half * 0.08)
	for _, sx in ipairs({ -0.34, 0.34 }) do
		tube("Swingarm", pivot + V3(sx, 0, 0), rA + V3(sx, 0, 0), b.kind == "emoto" and 0.3 or 0.26, b.kind == "emoto" and b.frame or "Medium stone grey", "Metal")
	end
	local shockTop = V3(0, seat - 0.55, half * 0.22)
	local shockBot = pivot + (rA - pivot) * 0.35 + V3(0, 0.1, 0)
	tube("Shock", shockTop, shockBot, 0.18, "Medium stone grey")
	tube("Spring", shockTop + (shockBot - shockTop) * 0.12, shockTop + (shockBot - shockTop) * 0.82, 0.34, b.kind == "emoto" and b.accent or "Really red", "SmoothPlastic")
	local cx = wheelW / 2 + 0.22
	tube("Chain", pivot + V3(cx, 0.12, -0.1), rA + V3(cx, b.rR * 0.45, 0), 0.14, "Dark stone grey")
	tube("Chain", pivot + V3(cx, -0.25, -0.1), rA + V3(cx, -b.rR * 0.45, 0), 0.14, "Dark stone grey")
	-- foot pegs, kickstand
	for _, sx in ipairs({ -1, 1 }) do box("Peg", V3(0.55, 0.16, 0.28), CFrame.new(sx * 0.55, b.rR + 0.25, half * 0.02), "Medium stone grey", "DiamondPlate") end
	tube("Kickstand", V3(-0.4, b.rR + 0.15, half * 0.05), V3(-0.85, 0.08, half * 0.25), 0.12, "Really black")
	if b.kind == "emoto" then
		-- ELECTRIC: alloy beams round a big battery, side covers with the race number, motor, long thin seat
		local neck = clampLo + V3(0, -0.1, 0.3)
		local seatFront = V3(0, seat - 0.3, -half * 0.12)
		for _, sx in ipairs({ -0.3, 0.3 }) do
			tube("Frame", neck + V3(sx, 0, 0), pivot + V3(sx, 0.15, -0.35), 0.28, b.frame)
			tube("TopRail", neck + V3(sx, 0.1, 0), seatFront + V3(sx, 0, 0), 0.22, b.frame)
			tube("SubFrame", seatFront + V3(sx, 0, 0), V3(sx, seat - 0.15, half * 0.85), 0.18, b.frame)
			tube("SubBrace", pivot + V3(sx, 0.2, 0), V3(sx, seat - 0.35, half * 0.6), 0.16, b.frame)
		end
		local bat = (neck + pivot) / 2 + V3(0, 0.12, 0.1)
		box("Battery", V3(0.62, 1.35, 1.7), CFrame.new(bat) * CFrame.Angles(0.42, 0, 0), b.body == "Institutional white" and "Really black" or b.body, "SmoothPlastic")
		for _, sx in ipairs({ -1, 1 }) do
			box("SideCover", V3(0.08, 1.05, 1.35), CFrame.new(bat + V3(sx * 0.36, 0.05, 0)) * CFrame.Angles(0.42, 0, 0), b.body, "SmoothPlastic", b.num)
			box("Accent", V3(0.09, 0.12, 1.3), CFrame.new(bat + V3(sx * 0.37, 0.62, -0.25)) * CFrame.Angles(0.42, 0, 0), b.accent or "Toothpaste", "Neon")
		end
		cylAt("Motor", 0.75, 0.6, CFrame.new(pivot + V3(0, -0.15, -0.3)), "Dark stone grey", "Metal")
		box("Controller", V3(0.4, 0.3, 0.55), CFrame.new(V3(0, seat - 0.6, half * 0.4)), "Really black", "Metal")
		box("Seat", V3(0.62, 0.28, 2.5), CFrame.new(0, seat, half * 0.32) * CFrame.Angles(-0.04, 0, 0), "Really black", "Fabric")
		box("SeatNose", V3(0.55, 0.26, 0.4), CFrame.new(0, seat - 0.06, -half * 0.18) * CFrame.Angles(0.35, 0, 0), "Really black", "Fabric")
		box("RearFender", V3(0.55, 0.13, 1.5), CFrame.new(0, seat - 0.05, half * 0.98) * CFrame.Angles(-0.32, 0, 0), b.body, "SmoothPlastic")
		box("TailLight", V3(0.4, 0.16, 0.12), CFrame.new(0, seat + 0.05, half * 1.22), "Really red", "Neon")
		box("Plate", V3(0.7, 0.5, 0.06), CFrame.new(0, seat - 0.55, half * 1.22) * CFrame.Angles(-0.2, 0, 0), "Institutional white", "SmoothPlastic")
	elseif b.kind == "dirt" then
		-- PETROL DIRT BIKE: frame, radiator shrouds, tank, engine with a cylinder, exhaust pipe and silencer
		local neck = clampLo + V3(0, -0.05, 0.3)
		local low = V3(0, b.rR + 0.15, -half * 0.18)
		tube("DownTube", neck, low, 0.3, b.frame)
		tube("Cradle", low, pivot + V3(0, -0.2, 0), 0.26, b.frame)
		tube("TopTube", neck + V3(0, 0.05, 0), V3(0, seat - 0.3, half * 0.05), 0.28, b.frame)
		tube("SeatRail", V3(0, seat - 0.3, half * 0.05), V3(0, seat - 0.1, half * 0.85), 0.2, b.frame)
		box("Engine", V3(0.75, 0.95, 1.1), CFrame.new(0, b.rR + 0.5, -0.05), "Dark stone grey", "Metal")
		box("Cylinder", V3(0.6, 0.7, 0.6), CFrame.new(0, b.rR + 1.15, -0.3) * CFrame.Angles(-0.35, 0, 0), "Medium stone grey", "Metal")
		for k = 0, 2 do box("Fin", V3(0.75, 0.08, 0.75), CFrame.new(0, b.rR + 1.0 + k * 0.18, -0.3) * CFrame.Angles(-0.35, 0, 0), "Medium stone grey", "Metal") end
		box("Tank", V3(0.85, 0.65, 1.2), CFrame.new(0, seat - 0.08, -half * 0.22) * CFrame.Angles(0.15, 0, 0), b.body, "SmoothPlastic")
		for _, sx in ipairs({ -1, 1 }) do
			box("Shroud", V3(0.1, 0.95, 1.25), CFrame.new(sx * 0.5, seat - 0.3, -half * 0.33) * CFrame.Angles(0.35, sx * 0.12, 0), b.body, "SmoothPlastic")
			box("SidePlate", V3(0.08, 0.85, 1.0), CFrame.new(sx * 0.42, seat - 0.4, half * 0.55) * CFrame.Angles(-0.1, 0, 0), b.trim, "SmoothPlastic", b.num)
		end
		box("Radiator", V3(0.8, 0.8, 0.2), CFrame.new(0, seat - 0.6, -half * 0.42) * CFrame.Angles(0.35, 0, 0), "Dark stone grey", "DiamondPlate")
		local ex1 = V3(0.38, b.rR + 1.0, -0.65)
		tube("Header", ex1, V3(0.42, b.rR + 0.35, -0.2), 0.2, "Medium stone grey")
		tube("Header", V3(0.42, b.rR + 0.35, -0.2), V3(0.48, seat - 0.55, half * 0.5), 0.2, "Medium stone grey")
		cylAt("Silencer", 0.48, 1.4, CFrame.new(V3(0.5, seat - 0.3, half * 0.78), V3(0.5, seat - 0.1, half * 1.4)) * CFrame.Angles(0, math.pi / 2, 0), "Medium stone grey", "Metal")
		box("Seat", V3(0.66, 0.3, 2.3), CFrame.new(0, seat + 0.02, half * 0.32) * CFrame.Angles(-0.03, 0, 0), "Really black", "Fabric")
		box("RearFender", V3(0.55, 0.13, 1.6), CFrame.new(0, seat - 0.02, half * 1.0) * CFrame.Angles(-0.3, 0, 0), b.trim, "SmoothPlastic")
		box("TailLight", V3(0.35, 0.15, 0.1), CFrame.new(0, seat + 0.1, half * 1.25), "Really red", "Neon")
	else
		-- STREET MINI: chunky frame, a fat tank, the engine down low, an underslung exhaust, a stubby tail
		local neck = clampLo + V3(0, -0.05, 0.3)
		tube("Spine", neck, V3(0, seat - 0.35, half * 0.1), 0.42, b.frame)
		tube("Spine", V3(0, seat - 0.35, half * 0.1), pivot, 0.36, b.frame)
		box("Engine", V3(0.8, 0.9, 1.1), CFrame.new(0, b.rR + 0.35, -0.05), "Medium stone grey", "Metal")
		box("EngineCover", V3(0.86, 0.5, 0.6), CFrame.new(0, b.rR + 0.4, 0.05), "Really black", "Metal")
		box("Tank", V3(1.05, 0.7, 1.25), CFrame.new(0, seat - 0.05, -half * 0.25) * CFrame.Angles(0.12, 0, 0), b.body, "SmoothPlastic")
		for _, sx in ipairs({ -1, 1 }) do box("TankSide", V3(0.1, 0.55, 1.0), CFrame.new(sx * 0.55, seat - 0.2, -half * 0.25) * CFrame.Angles(0.12, 0, 0), b.trim, "SmoothPlastic", b.num) end
		box("Seat", V3(0.75, 0.3, 1.7), CFrame.new(0, seat + 0.02, half * 0.3), "Really black", "Fabric")
		box("Tail", V3(0.65, 0.35, 0.9), CFrame.new(0, seat, half * 0.85) * CFrame.Angles(-0.15, 0, 0), b.body, "SmoothPlastic")
		box("TailLight", V3(0.4, 0.15, 0.1), CFrame.new(0, seat + 0.05, half * 1.12), "Really red", "Neon")
		box("Exhaust", V3(0.45, 0.4, 1.3), CFrame.new(0.3, b.rR - 0.1, half * 0.4), "Dark stone grey", "Metal")
		box("RearFender", V3(0.62, 0.12, 0.9), CFrame.new(0, b.rR * 2 + 0.25, half * 0.95) * CFrame.Angles(-0.4, 0, 0), b.frame, "SmoothPlastic")
	end
	return out
end
-- where the rider's root sits on the bike (in the bike's frame): about a stud above the seat
local function RiderOffset(b) return CFrame.new(0, b.seat + 1.15, b.base * 0.1) end
