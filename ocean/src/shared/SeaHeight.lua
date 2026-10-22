-- SeaHeight(x, z, t, s): the height of the sea (studs above SEA.level) at (x, z) at sea time t. Shared by the server
-- (rocks the boat, floats swimmers and lifeboats) and OceanClient (draws the surface), so they always agree.
-- Swells roll from the bow (-z) to the stern (+z), one after another; s.rogueA adds a set of bigger waves (or, with
-- s.rogueBump, one giant tsunami swell) travelling at 30 studs/s. The waves die out ~480 studs ahead of/behind the
-- boat, where the flat ocean starts. The height doesn't change across (x), so the drawn surface can be long smooth
-- strips with no steps.
local function SeaHeight(x, z, t, s)
	local dz = math.abs(z - s.shipZ)
	local fade = 1 - math.min(1, math.max(0, dz - 330) / 150)
	if fade <= 0 then return 0 end
	local zz = z - s.speed * t
	local main = math.sin(0.0285 * zz - 0.4 * t)
	local h = s.amp * (main + 0.3 * math.sin(0.07 * zz - 1.1 * t) + 0.1 * math.sin(0.16 * zz - 2.1 * t))
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
