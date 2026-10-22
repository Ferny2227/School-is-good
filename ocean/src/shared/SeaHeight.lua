-- SeaHeight(x, z, t, s): the height of the sea (studs above SEA.level) at (x, z) at sea time t. Shared by the server
-- (rocks the boat, floats swimmers and lifeboats) and OceanClient (draws the surface), so they always agree.
-- Huge swells (~1100 studs long, up to 120+ studs from trough to crest) roll in one after another. The direction they come from slowly turns (SeaDir), so
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
	-- the big swell (~1100 studs from crest to crest), plus smaller waves riding on it
	local main = math.sin(0.0055 * uu - 0.4 * t)
	local chop = math.min(s.amp, 14)
	local h = s.amp * main + chop * (0.3 * math.sin(0.03 * uu - 0.7 * t) + 0.12 * math.sin(0.08 * uu - 1.4 * t))
	if s.rogueA > 0 then
		local e = (u - s.rogueZ - 30 * (t - s.rogueT)) / s.rogueLen
		if e > -3 and e < 3 then
			if s.rogueBump then h = h + s.rogueA * math.exp(-e * e)
			else h = h + s.rogueA * math.exp(-e * e) * main end
		end
	end
	return h * fade
end
-- ShipPose: how the boat sits on the waves at sea time t (height, pitch, roll), worked out from the same SeaHeight.
-- The server and every player's computer use it, so the boat always sits exactly on the water that is drawn.
-- sinkAt: the sea time the boat started sinking (or nil).
local function ShipPose(t, s, len, wid, sinkAt)
	if sinkAt and sinkAt >= 0 then
		local st = math.max(0, t - sinkAt)
		return -st * 0.9, math.min(0.35, st * 0.012), math.min(0.12, st * 0.006)
	end
	local x, z = s.shipX, s.shipZ
	local L, W = len * 0.35, math.max(45, wid / 2)
	local h0 = SeaHeight(x, z, t, s)
	local hb, hs = SeaHeight(x, z - L, t, s), SeaHeight(x, z + L, t, s)
	local hp, hst = SeaHeight(x - W, z, t, s), SeaHeight(x + W, z, t, s)
	local MAXT = 0.28    -- ~16 degrees: big waves rock it hard, but nobody tips over
	local pitch = math.max(-MAXT, math.min(MAXT, math.atan((hb - hs) / (2 * L)) * 1.1))
	local roll = math.max(-MAXT, math.min(MAXT, math.sin(t * 0.85) * (0.012 + 0.002 * s.amp) + math.atan((hst - hp) / (2 * W)) * 1.3))
	return (h0 + (hb + hs) / 2) / 2 * 0.95, pitch, roll
end
-- the boat's frame: at the ship's spot, raised by dy, turned by yaw, tipped by pitch and roll
local function ShipCFrame(at, level, dy, pitch, roll, yaw)
	return CFrame.new(at + Vector3.new(0, level + dy, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, roll)
end
