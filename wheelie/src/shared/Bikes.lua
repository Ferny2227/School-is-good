-- shared (server + every player's computer): the bikes - prices, how they ride, and what they look like.
-- speed = top speed (studs/s), lift = how hard you can pull the front up, bp = the balance point (radians: the angle
-- where the bike balances on its back wheel - higher is easier to hold), r = wheel radius, base = wheelbase,
-- seat = seat height (r / base / seat are in "bike units" and get scaled by BIKE_SCALE so the bikes are a good size
-- next to a Roblox rider). The bike's own frame: the ground is y = 0, the front points to -Z.
local BIKE_SCALE = 1.55
local BIKES = {
	{ name = "Mini Bike", kind = "mini", price = 0, speed = 38, accel = 22, lift = 5.6, bp = 1.12, r = 0.75, base = 3.4, seat = 2.3,
		body = "Really red", trim = "Institutional white", rim = "Medium stone grey", num = "7" },
	{ name = "Pit Bike", kind = "mini", price = 400, speed = 48, accel = 26, lift = 6.0, bp = 1.16, r = 0.9, base = 3.9, seat = 2.6,
		body = "Bright orange", trim = "Black", rim = "Black", num = "21" },
	{ name = "Volt Bee", kind = "emoto", price = 1200, speed = 58, accel = 30, lift = 6.4, bp = 1.2, r = 1.05, base = 4.4, seat = 3,
		body = "Really black", trim = "Toothpaste", rim = "Black", led = "Toothpaste", num = "B1" },
	{ name = "Stinger", kind = "emoto", price = 2500, speed = 66, accel = 34, lift = 6.8, bp = 1.23, r = 1.1, base = 4.6, seat = 3.1,
		body = "Medium stone grey", trim = "Lime green", rim = "Gold", led = "Lime green", num = "99" },
	{ name = "Thunder X", kind = "emoto", price = 5000, speed = 76, accel = 38, lift = 7.3, bp = 1.27, r = 1.15, base = 4.8, seat = 3.2,
		body = "Royal purple", trim = "New Yeller", rim = "Really black", led = "Hot pink", num = "X" },
	{ name = "Gold Mini", kind = "mini", price = 9000, speed = 56, accel = 32, lift = 6.6, bp = 1.3, r = 0.8, base = 3.5, seat = 2.4,
		body = "Gold", trim = "Really black", rim = "Gold", num = "1" },
}
local BIKE = {}
for i, b in ipairs(BIKES) do
	b.index = i
	b.r, b.base, b.seat = b.r * BIKE_SCALE, b.base * BIKE_SCALE, b.seat * BIKE_SCALE
	BIKE[b.name] = b
end

-- the parts of a bike: { name, size, CFrame in the bike's frame, colour, material, shape, sign text }
local function BikeParts(b)
	local out = {}
	local S = BIKE_SCALE
	local function add(n, size, cf, c, mat, shape, text) table.insert(out, { n, size * S, cf, c, mat or "SmoothPlastic", shape, text }) end
	-- a straight tube from a to b (both in the bike's frame)
	local function tube(n, a, b2, thick, c, mat)
		local len = (b2 - a).magnitude
		table.insert(out, { n, Vector3.new(thick * S, thick * S, len), CFrame.new((a + b2) / 2, b2), c, mat or "Metal" })
	end
	local r, half, seat = b.r, b.base / 2, b.seat
	local side = CFrame.Angles(0, math.pi / 2, 0)              -- (a cylinder's round faces point sideways, like a wheel)
	local front, rear = Vector3.new(0, r, -half), Vector3.new(0, r, half)
	-- WHEELS: knobbly tyre, rim, spokes, hub, brake disc
	for _, w in ipairs({ { "Front", front }, { "Rear", rear } }) do
		local at = CFrame.new(w[2])
		add(w[1] .. "Tire", Vector3.new(0.5, r * 2 / S, r * 2 / S), at * side, "Really black", "SmoothPlastic", "cyl")
		add(w[1] .. "Tread", Vector3.new(0.52, r * 2 / S - 0.12, r * 2 / S - 0.12), at * side, "Dark stone grey", "Slate", "cyl")
		add(w[1] .. "Rim", Vector3.new(0.55, r * 1.45 / S, r * 1.45 / S), at * side, b.rim, "Metal", "cyl")
		add(w[1] .. "RimIn", Vector3.new(0.57, r * 1.25 / S, r * 1.25 / S), at * side, "Really black", "SmoothPlastic", "cyl")
		local spokes = b.kind == "emoto" and 3 or 6
		for k = 1, spokes do
			local a = k / spokes * math.pi * 2
			table.insert(out, { w[1] .. "Spoke", Vector3.new(0.6 * S, b.kind == "emoto" and 0.32 * S or 0.1 * S, r * 0.7), at * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, -r * 0.35), b.rim, "Metal" })
		end
		add(w[1] .. "Hub", Vector3.new(0.66, 0.36, 0.36), at * side, "Medium stone grey", "Metal", "cyl")
		add(w[1] .. "Disc", Vector3.new(0.06, r * 0.9 / S, r * 0.9 / S), at * CFrame.new(-0.3 * S, 0, 0) * side, "Institutional white", "DiamondPlate", "cyl")
	end
	-- FRONT END: two fork legs (dark lowers, shiny uppers), triple clamp, handlebars with grips, headlight, fender
	local head = Vector3.new(0, seat + 0.25 * S, -half + 0.55 * S)
	for _, sx in ipairs({ -0.3, 0.3 }) do
		local axle = front + Vector3.new(sx * S, 0, 0)
		local top = head + Vector3.new(sx * S, 0, 0)
		local mid = axle + (top - axle) * 0.45
		tube("ForkLower", axle, mid, 0.26, "Dark stone grey")
		tube("ForkUpper", mid, top, 0.2, b.kind == "emoto" and "Gold" or "Medium stone grey")
	end
	add("Clamp", Vector3.new(0.9, 0.2, 0.35), CFrame.new(head), b.trim, "Metal")
	local bars = head + Vector3.new(0, 0.55 * S, 0.25 * S)
	add("Bars", Vector3.new(2.1, 0.13, 0.13), CFrame.new(bars), "Really black", "Metal")
	add("BarPad", Vector3.new(0.6, 0.22, 0.22), CFrame.new(bars + Vector3.new(0, 0.05, 0)), b.trim, "Fabric")
	for _, sx in ipairs({ -1, 1 }) do add("Grip", Vector3.new(0.42, 0.2, 0.2), CFrame.new(bars + Vector3.new(sx * 0.9 * S, 0, 0)), "Really black", "Fabric") end
	tube("Riser", head, bars, 0.16, "Really black")
	add("FrontFender", Vector3.new(0.55, 0.12, 1.5), CFrame.new(front + Vector3.new(0, r + 0.3 * S, -0.15 * S)) * CFrame.Angles(0.15, 0, 0), b.trim)
	add("NumberPlate", Vector3.new(1, 1, 0.1), CFrame.new(head + Vector3.new(0, 0.15 * S, -0.3 * S)) * CFrame.Angles(0.3, 0, 0), b.trim, "SmoothPlastic", nil, b.num)
	add("Headlight", Vector3.new(0.18, 0.5, 0.5), CFrame.new(head + Vector3.new(0, -0.15 * S, -0.38 * S)) * side, "Institutional white", "Neon", "cyl")
	-- REAR: swingarm on both sides, a shock with a spring, the chain, the rear fender and tail light
	local pivot = Vector3.new(0, r + 0.35 * S, half * 0.18)
	for _, sx in ipairs({ -0.32, 0.32 }) do tube("Swingarm", pivot + Vector3.new(sx * S, 0, 0), rear + Vector3.new(sx * S, 0, 0), 0.2, b.trim) end
	local shockTop = Vector3.new(0, seat - 0.35 * S, half * 0.15)
	local shockBot = pivot + (rear - pivot) * 0.45
	tube("Shock", shockTop, shockBot, 0.16, "Medium stone grey")
	tube("Spring", shockTop + (shockBot - shockTop) * 0.15, shockTop + (shockBot - shockTop) * 0.85, 0.3, b.kind == "emoto" and b.led or "Really red", "SmoothPlastic")
	tube("Chain", pivot + Vector3.new(0.38 * S, -0.1 * S, 0), rear + Vector3.new(0.38 * S, 0, 0), 0.1, "Dark stone grey")
	add("Sprocket", Vector3.new(0.08, r * 0.8 / S, r * 0.8 / S), CFrame.new(rear + Vector3.new(0.4 * S, 0, 0)) * side, "Medium stone grey", "Metal", "cyl")
	add("RearFender", Vector3.new(0.5, 0.12, 1.6), CFrame.new(0, seat + 0.05 * S, half * 0.95) * CFrame.Angles(-0.25, 0, 0), b.trim)
	add("TailLight", Vector3.new(0.4, 0.18, 0.1), CFrame.new(0, seat - 0.05 * S, half * 1.18), "Really red", "Neon")
	-- foot pegs
	for _, sx in ipairs({ -1, 1 }) do add("Peg", Vector3.new(0.5, 0.12, 0.22), CFrame.new(sx * 0.45 * S, r + 0.15 * S, half * 0.1), "Medium stone grey", "DiamondPlate") end
	if b.kind == "mini" then
		-- a chunky little petrol bike: tube frame, fuel tank with a cap, a finned engine, exhaust with a muffler
		local neck = head + Vector3.new(0, -0.15 * S, 0.2 * S)
		local under = Vector3.new(0, r + 0.2 * S, -half * 0.15)
		tube("DownTube", neck, under, 0.3, b.body)
		tube("TopTube", neck, Vector3.new(0, seat - 0.25 * S, half * 0.35), 0.3, b.body)
		tube("SeatTube", Vector3.new(0, seat - 0.25 * S, half * 0.35), pivot, 0.28, b.body)
		add("Tank", Vector3.new(0.95, 0.65, 1.3), CFrame.new(0, seat + 0.05 * S, -half * 0.3) * CFrame.Angles(0.15, 0, 0), b.body, "SmoothPlastic")
		add("TankCap", Vector3.new(0.1, 0.3, 0.3), CFrame.new(0, seat + 0.42 * S, -half * 0.3) * CFrame.Angles(0, 0, math.pi / 2), "Medium stone grey", "Metal", "cyl")
		add("Engine", Vector3.new(0.8, 0.85, 1.1), CFrame.new(0, r + 0.25 * S, -0.05 * S), "Dark stone grey", "Metal")
		for k = -1, 1 do add("Fin", Vector3.new(0.95, 0.08, 0.95), CFrame.new(0, r + 0.55 * S + k * 0.15 * S, -0.05 * S), "Medium stone grey", "Metal") end
		add("AirFilter", Vector3.new(0.3, 0.45, 0.45), CFrame.new(-0.55 * S, r + 0.5 * S, 0.35 * S) * side, "Really red", "SmoothPlastic", "cyl")
		tube("Exhaust", Vector3.new(0.45 * S, r + 0.4 * S, -0.3 * S), Vector3.new(0.5 * S, seat - 0.35 * S, half * 0.7), 0.16, "Medium stone grey")
		add("Muffler", Vector3.new(0.35, 0.35, 1.1), CFrame.new(0.52 * S, seat - 0.3 * S, half * 0.75) * CFrame.Angles(0.25, 0, 0), "Dark stone grey", "Metal")
		add("Seat", Vector3.new(0.85, 0.32, 1.7), CFrame.new(0, seat + 0.12 * S, half * 0.38), "Really black", "Fabric")
		for _, sx in ipairs({ -1, 1 }) do add("SidePlate", Vector3.new(0.06, 0.6, 0.8), CFrame.new(sx * 0.46 * S, seat - 0.25 * S, half * 0.45), b.trim, "SmoothPlastic", nil, b.num) end
	else
		-- an e-moto: a skinny frame round a big battery with a glowing strip, a long thin seat, motor and belt
		local neck = head + Vector3.new(0, -0.2 * S, 0.25 * S)
		for _, sx in ipairs({ -0.28, 0.28 }) do
			tube("Frame", neck + Vector3.new(sx * S, 0, 0), Vector3.new(sx * S, r + 0.25 * S, half * 0.05), 0.2, b.trim)
			tube("Frame", neck + Vector3.new(sx * S, 0, 0), Vector3.new(sx * S, seat - 0.3 * S, half * 0.25), 0.2, b.trim)
		end
		add("Battery", Vector3.new(0.75, 1.4, 1.5), CFrame.new(0, r + 0.95 * S, -half * 0.15) * CFrame.Angles(0.2, 0, 0), b.body, "SmoothPlastic")
		for _, sx in ipairs({ -1, 1 }) do
			add("SideCover", Vector3.new(0.06, 1.1, 1.2), CFrame.new(sx * 0.4 * S, r + 1 * S, -half * 0.15) * CFrame.Angles(0.2, 0, 0), b.trim, "SmoothPlastic", nil, b.num)
			add("LED", Vector3.new(0.07, 0.12, 1.25), CFrame.new(sx * 0.41 * S, r + 1.55 * S, -half * 0.15) * CFrame.Angles(0.2, 0, 0), b.led or "Toothpaste", "Neon")
		end
		add("Motor", Vector3.new(0.6, 0.65, 0.65), CFrame.new(0, r + 0.25 * S, half * 0.12) * side, "Dark stone grey", "Metal", "cyl")
		add("Controller", Vector3.new(0.45, 0.3, 0.6), CFrame.new(0, r + 0.2 * S, -half * 0.25), "Really black", "Metal")
		add("Seat", Vector3.new(0.7, 0.3, 2.3), CFrame.new(0, seat + 0.1 * S, half * 0.42), "Really black", "Fabric")
		add("TailPlastic", Vector3.new(0.6, 0.35, 0.9), CFrame.new(0, seat - 0.05 * S, half * 0.82), b.body, "SmoothPlastic")
		add("FrontPlastic", Vector3.new(0.85, 0.5, 0.6), CFrame.new(0, seat + 0.05 * S, -half * 0.55), b.body, "SmoothPlastic")
	end
	return out
end
-- where the rider's root sits on the bike (in the bike's frame)
local function RiderOffset(b) return CFrame.new(0, b.seat + 0.2 * BIKE_SCALE + 1.0, b.base * 0.1) end
