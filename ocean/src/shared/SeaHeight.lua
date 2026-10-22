-- SeaHeight(x, z, t, s): the height of the sea (studs above SEA.level) at (x, z) at sea time t. Shared by the server
-- (rocks the boat, floats swimmers and lifeboats) and OceanClient (draws the surface), so they always agree.
-- Huge swells (~380 studs long) roll in one after another. The direction they come from slowly turns (SeaDir), so
-- over a round they hit the boat from ahead, from the side, from behind... s.rogueA adds a set of even bigger waves
-- (or, with s.rogueBump, one giant tsunami swell) that starts 700 studs away and travels at 30 studs/s.
-- u = distance along the direction the waves travel (0 at the boat).
local function SeaDir(t) return 0.025 * t + 0.8 * math.sin(0.021 * t) end
local function SeaHeight(x, z, t, s)
	local th = SeaDir(t)
	local u = (x - s.shipX) * math.sin(th) + (z - s.shipZ) * math.cos(th)
	local fade = 1 - math.min(1, math.max(0, math.abs(u) - 1500) / 450)
	if fade <= 0 then return 0 end
	local uu = u - s.speed * t
	local main = math.sin(0.0165 * uu - 0.4 * t)
	local h = s.amp * (main + 0.25 * math.sin(0.045 * uu - 0.9 * t) + 0.08 * math.sin(0.11 * uu - 1.7 * t))
	if s.rogueA > 0 then
		local e = (u - s.rogueZ - 30 * (t - s.rogueT)) / s.rogueLen
		if e > -3 and e < 3 then
			if s.rogueBump then h = h + s.rogueA * math.exp(-e * e)
			else h = h + s.rogueA * math.exp(-e * e) * main end
		end
	end
	return h * fade
end
