------------------------------------------------------------------ the sea surface (shared: the server and every player use this same maths)
-- Height of the water above the still-water level at (x, z), time t, for sea state s. Big rolling swells about
-- 220 studs long travel from the boat's bow (-z) to its stern (+z) at about 30 studs a second, with smaller waves on
-- top, so the boat (which stays put) rides over one swell after another as if sailing into them. Sets of bigger
-- waves (s.rogueA) or one giant swell (a tsunami, s.rogueBump) roll through now and then. Far from the boat the
-- swells fade into the flat sea.
local function SeaHeight(x, z, t, s)
	local dx, dz = math.abs(x - s.shipX), math.abs(z - s.shipZ)
	local fade = (1 - math.min(1, math.max(0, dx - 330) / 250)) * (1 - math.min(1, math.max(0, dz - 330) / 150))
	if fade <= 0 then return 0 end
	local zz = z - s.speed * t
	local main = math.sin(0.0285 * zz - 0.4 * t)
	local h = s.amp * (main + 0.35 * math.sin(0.07 * zz + 0.011 * x - 1.1 * t) + 0.12 * math.sin(0.16 * zz - 0.04 * x - 2.1 * t))
	if s.rogueA > 0 then
		local c = s.rogueZ + 30 * (t - s.rogueT)
		local e = (z - c) / s.rogueLen
		if e > -3 and e < 3 then
			if s.rogueBump then h = h + s.rogueA * math.exp(-e * e)
			else h = h + s.rogueA * math.exp(-e * e) * main end
		end
	end
	return h * fade
end
