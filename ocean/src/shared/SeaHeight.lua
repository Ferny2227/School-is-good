-- SeaHeight(x, z, t, s): the height of the sea (studs above SEA.level) at (x, z) at sea time t. Shared by the server
-- (rocks the boat, floats swimmers and lifeboats) and OceanClient (draws the surface), so they always agree.
-- Huge swells (~800 studs long, up to 120+ studs from trough to crest) roll in one after another. The direction they come from slowly turns (SeaDir), so
-- over a round they hit the boat from ahead, from the side, from behind... s.rogueA adds a set of even bigger waves
-- (or, with s.rogueBump, one giant tsunami swell) that starts 700 studs away and travels at 30 studs/s.
-- u = distance along the direction the waves travel (0 at the boat).
local function SeaDir(t) return 0.025 * t + 0.8 * math.sin(0.021 * t) end
-- Each swell is a long smooth rounded ridge (an ellipse across it), so the sea can be drawn with a few giant smooth
-- shapes (OceanClient) and SeaHeight is exactly the surface they make: the higher of the two ridges either side.
local SEA_K = 0.0078                          -- ~805 studs from crest to crest
local SEA_L = 2 * math.pi / SEA_K
local RIDGE_A = 0.62 * SEA_L                  -- half the width of one ridge (they overlap; the troughs are where they meet)
local RIDGE_B = 2 / (1 - math.sqrt(1 - (0.5 * SEA_L / RIDGE_A) ^ 2))   -- ridge height / crest height: trough = -crest
-- where crest number 0 is now (u along the waves' direction); the crests are SEA_L apart
local function SeaCrest(t, s) return s.speed * t + 0.4 * t / SEA_K end
-- how high the crest at u = uc stands: the normal swell, plus a set of big waves passing through, fading far away
local function CrestAmp(uc, t, s)
	local A = s.amp
	if s.rogueA > 0 and not s.rogueBump then
		local e = (uc - s.rogueZ - 30 * (t - s.rogueT)) / s.rogueLen
		if e > -3 and e < 3 then A = A + s.rogueA * math.exp(-e * e) end
	end
	return A * (1 - math.min(1, math.max(0, math.abs(uc) - 1500) / 450))
end
local function ridgeAt(x, A, a, b)
	if x <= -a or x >= a then return -1e9 end
	return A - b + b * math.sqrt(1 - (x / a) ^ 2)
end
local function SeaHeight(x, z, t, s)
	local th = SeaDir(t)
	local u = (x - s.shipX) * math.sin(th) + (z - s.shipZ) * math.cos(th)
	local c0 = SeaCrest(t, s)
	local u1 = c0 + math.floor((u - c0) / SEA_L) * SEA_L
	local u2 = u1 + SEA_L
	local A1, A2 = CrestAmp(u1, t, s), CrestAmp(u2, t, s)
	local h = math.max(ridgeAt(u - u1, A1, RIDGE_A, RIDGE_B * A1), ridgeAt(u - u2, A2, RIDGE_A, RIDGE_B * A2))
	-- the tsunami: one giant ridge rising out of the sea
	if s.rogueA > 0 and s.rogueBump then
		local c = s.rogueZ + 30 * (t - s.rogueT)
		h = math.max(h, ridgeAt(u - c, s.rogueA, s.rogueLen * 1.5, s.rogueA * 1.5))
	end
	return h
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
	local MAXT = 0.42    -- ~24 degrees: the bow points up the wave, then tips over the top and drops
	local pitch = math.max(-MAXT, math.min(MAXT, math.atan((hb - hs) / (2 * L)) * 1.1))
	local roll = math.max(-MAXT, math.min(MAXT, math.sin(t * 0.85) * (0.012 + 0.002 * s.amp) + math.atan((hst - hp) / (2 * W)) * 1.3))
	return (h0 + (hb + hs) / 2) / 2 * 0.95, pitch, roll
end
-- the boat's frame: at the ship's spot, raised by dy, turned by yaw, tipped by pitch and roll
local function ShipCFrame(at, level, dy, pitch, roll, yaw)
	return CFrame.new(at + Vector3.new(0, level + dy, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, roll)
end
