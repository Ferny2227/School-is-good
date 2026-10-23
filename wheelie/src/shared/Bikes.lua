-- shared (server + every player's computer): the bikes - prices, how they ride, and what they look like.
-- speed = top speed (studs/s), lift = how hard you can pull the front up, bp = the balance point (radians: the angle
-- where the bike balances on its back wheel - higher is easier to hold), r = wheel radius, base = wheelbase,
-- seat = seat height. The bike's own frame: the ground is y = 0, the front points to -Z.
local BIKES = {
	{ name = "Mini Bike", kind = "mini", price = 0, speed = 38, accel = 22, lift = 5.6, bp = 1.12, r = 0.75, base = 3.4, seat = 2.3,
		body = "Really red", trim = "Institutional white", rim = "Medium stone grey" },
	{ name = "Pit Bike", kind = "mini", price = 400, speed = 48, accel = 26, lift = 6.0, bp = 1.16, r = 0.95, base = 3.9, seat = 2.7,
		body = "Bright orange", trim = "Black", rim = "Black" },
	{ name = "Volt Bee", kind = "emoto", price = 1200, speed = 58, accel = 30, lift = 6.4, bp = 1.2, r = 1.15, base = 4.5, seat = 3.2,
		body = "Really black", trim = "Toothpaste", rim = "Black", led = "Toothpaste" },
	{ name = "Stinger", kind = "emoto", price = 2500, speed = 66, accel = 34, lift = 6.8, bp = 1.23, r = 1.2, base = 4.7, seat = 3.3,
		body = "Medium stone grey", trim = "Lime green", rim = "Gold", led = "Lime green" },
	{ name = "Thunder X", kind = "emoto", price = 5000, speed = 76, accel = 38, lift = 7.3, bp = 1.27, r = 1.25, base = 4.9, seat = 3.4,
		body = "Royal purple", trim = "New Yeller", rim = "Really black", led = "Hot pink" },
	{ name = "Gold Mini", kind = "mini", price = 9000, speed = 56, accel = 32, lift = 6.6, bp = 1.3, r = 0.8, base = 3.5, seat = 2.4,
		body = "Gold", trim = "Really black", rim = "Gold" },
}
local BIKE = {}
for i, b in ipairs(BIKES) do b.index = i BIKE[b.name] = b end

-- the parts of a bike: { name, size, CFrame in the bike's frame, colour, material, shape }
local function BikeParts(b)
	local out = {}
	local function add(n, size, cf, c, mat, shape) table.insert(out, { n, size, cf, c, mat or "SmoothPlastic", shape }) end
	local r, half = b.r, b.base / 2
	local sideways = CFrame.Angles(0, math.pi / 2, 0)     -- (a cylinder's round faces point sideways, like a wheel)
	for _, w in ipairs({ { "Front", -half }, { "Rear", half } }) do
		add(w[1] .. "Tire", Vector3.new(0.55, r * 2, r * 2), CFrame.new(0, r, w[2]) * sideways, "Really black", "SmoothPlastic", "cyl")
		add(w[1] .. "Rim", Vector3.new(0.6, r * 1.2, r * 1.2), CFrame.new(0, r, w[2]) * sideways, b.rim, "Metal", "cyl")
		add(w[1] .. "Hub", Vector3.new(0.7, r * 0.4, r * 0.4), CFrame.new(0, r, w[2]) * sideways, "Medium stone grey", "Metal", "cyl")
	end
	if b.kind == "mini" then
		-- a chunky little bike: tube frame, gas tank, engine, exhaust, a fat seat
		add("Frame", Vector3.new(0.4, 0.4, b.base * 0.8), CFrame.new(0, r + 0.5, 0), b.body, "Metal")
		add("Engine", Vector3.new(0.9, 0.9, 1.2), CFrame.new(0, r + 0.15, 0.2), "Dark stone grey", "Metal")
		add("Exhaust", Vector3.new(0.3, 0.3, 1.6), CFrame.new(0.5, r + 0.1, half * 0.6), "Medium stone grey", "Metal")
		add("Tank", Vector3.new(1, 0.8, 1.3), CFrame.new(0, b.seat - 0.1, -half * 0.35), b.body, "SmoothPlastic")
		add("Seat", Vector3.new(0.9, 0.35, 1.6), CFrame.new(0, b.seat, half * 0.3), "Really black", "Fabric")
		add("SeatPost", Vector3.new(0.3, b.seat - r - 0.5, 0.3), CFrame.new(0, (b.seat + r + 0.5) / 2, half * 0.3), b.body, "Metal")
		add("Fork", Vector3.new(0.3, b.seat - 0.2, 0.3), CFrame.new(0, (b.seat + r) / 2 + 0.2, -half + 0.2) * CFrame.Angles(-0.35, 0, 0), b.trim, "Metal")
		add("Bars", Vector3.new(2.2, 0.25, 0.25), CFrame.new(0, b.seat + 0.6, -half * 0.75), "Black", "Metal")
		add("Fender", Vector3.new(0.8, 0.2, 1.2), CFrame.new(0, r * 2 + 0.15, half), b.trim, "SmoothPlastic")
		add("Light", Vector3.new(0.5, 0.4, 0.2), CFrame.new(0, b.seat + 0.15, -half * 0.85), "New Yeller", "Neon")
	else
		-- an e-moto: skinny frame, a big battery with a glowing strip, long seat, long front fork, number plate
		add("Frame", Vector3.new(0.35, 0.35, b.base * 0.85), CFrame.new(0, b.seat - 0.6, 0) * CFrame.Angles(0.12, 0, 0), b.body, "Metal")
		add("Battery", Vector3.new(0.9, 1.6, 1.6), CFrame.new(0, r + 1, -0.2), b.body, "SmoothPlastic")
		add("LED", Vector3.new(0.95, 0.15, 1.5), CFrame.new(0, r + 1.5, -0.2), b.led or "Toothpaste", "Neon")
		add("Motor", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, r + 0.1, 0.6), "Dark stone grey", "Metal")
		add("Swingarm", Vector3.new(0.25, 0.25, half), CFrame.new(0.35, r + 0.2, half / 2 + 0.3), b.trim, "Metal")
		add("Seat", Vector3.new(0.8, 0.35, b.base * 0.5), CFrame.new(0, b.seat, half * 0.25), "Really black", "Fabric")
		add("Tail", Vector3.new(0.6, 0.3, 1), CFrame.new(0, b.seat - 0.05, half * 0.85), b.trim, "SmoothPlastic")
		add("Fork", Vector3.new(0.35, b.seat + 0.4 - r, 0.35), CFrame.new(0, (b.seat + 0.4 + r) / 2, -half + 0.35) * CFrame.Angles(-0.32, 0, 0), b.trim, "Metal")
		add("Bars", Vector3.new(2.6, 0.25, 0.25), CFrame.new(0, b.seat + 1, -half * 0.68), "Black", "Metal")
		add("Plate", Vector3.new(1, 1.1, 0.15), CFrame.new(0, b.seat + 0.35, -half * 0.8), b.trim, "SmoothPlastic")
		add("Light", Vector3.new(0.6, 0.4, 0.2), CFrame.new(0, b.seat + 0.35, -half * 0.85), "Institutional white", "Neon")
		add("Fender", Vector3.new(0.7, 0.2, 1.4), CFrame.new(0, r * 2 + 0.2, -half + 0.2), b.trim, "SmoothPlastic")
	end
	return out
end
-- where the rider's root sits on the bike (in the bike's frame)
local function RiderOffset(b) return CFrame.new(0, b.seat + 1.05, b.base * 0.12) end
