-- ==== s29_rides.lua
------------------------------------------------------------------ Paradise Park: 10 rides that really move
-- Every moving piece is a rigged model (one anchored root, everything else welded to it), so a ride moves by setting
-- one CFrame per car/gondola/cup each frame. Seats are real Seats: touch one to sit and ride along, jump to get off.
-- Some seats have a painted rider in them so the rides look busy.
local PARK = { visitors = 0 }
local function rideModel(parent, name, pivot)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local b = { model = m, cf = pivot }
	local root = U.P(b, "Root", V(1, 1, 1), CFrame.new(), "Institutional white", nil, { tr = 1, nc = true })
	return m, b, root
end
local function rig(m, root) U.rig(m, root, true) end
local HAIR = { "Brown", "Really black", "Bright yellow", "Reddish brown", "Bright orange" }
-- someone sitting on a seat whose top-middle is at lcf (in b's frame), facing lcf's -z
local function rider(b, lcf, armsUp)
	local f = lcf
	local shirt, pants, skin = U.pick(SHIRT), U.pick(PANTS), U.pick(SKIN)
	U.P(b, "RiderBody", V(1.6, 1.8, 0.8), f * CFrame.new(0, 0.9, 0.3), shirt, nil, { nc = true })
	local head = U.P(b, "RiderHead", V(1.6, 0.8, 0.8), f * CFrame.new(0, 2.2, 0.3), skin, nil, { nc = true })
	local mesh = Instance.new("SpecialMesh")
	pcall(function() mesh.MeshType = Enum.MeshType.Head end)
	mesh.Scale = V(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	pcall(function() face.Face = Enum.NormalId.Front end)
	face.Parent = head
	U.P(b, "RiderHair", V(1.4, 0.4, 1.3), f * CFrame.new(0, 2.75, 0.35), U.pick(HAIR), nil, { nc = true })
	for _, dx in ipairs({ -0.35, 0.35 }) do U.P(b, "RiderLeg", V(0.7, 0.7, 1.8), f * CFrame.new(dx, 0.35, -0.6), pants, nil, { nc = true }) end
	for _, dx in ipairs({ -1.1, 1.1 }) do
		if armsUp then U.P(b, "RiderArm", V(0.6, 1.8, 0.6), f * CFrame.new(dx, 2.6, 0.3), shirt, nil, { nc = true })
		else U.P(b, "RiderArm", V(0.6, 0.6, 1.6), f * CFrame.new(dx, 1.1, -0.4), shirt, nil, { nc = true }) end
	end
end
-- a seat whose centre is at lcf (facing its -z). npc = a painted rider sits there instead (no Seat).
local function chair(b, lcf, color, npc, armsUp, w)
	if npc then
		U.P(b, "Bench", V(w or 1.8, 0.6, 1.8), lcf, color or "Really black", "Fabric")
		rider(b, lcf * CFrame.new(0, 0.3, 0), armsUp)
	else
		U.P(b, "Seat", V(w or 1.8, 0.6, 1.8), lcf, color or "Really black", "Fabric", { class = "Seat" })
	end
end
local function sign(b, text, x, y, z, w, h, ry, bg, fg)
	local s = U.P(b, "RideSign", V(w, h, 0.4), U.L(x, y, z, ry or 0), "Really black", "SmoothPlastic")
	U.text(s, text, fg or Color3.new(1, 1, 1), bg or Color3.new(0.6, 0.05, 0.05), "Front")
	U.text(s, text, fg or Color3.new(1, 1, 1), bg or Color3.new(0.6, 0.05, 0.05), "Back")
	return s
end

------------------------------------------------------------------ tracks: a closed path resampled every ds studs, with an "up" for every sample
local function resample(ctrl, ds)
	local pts = {}
	for _, c in ipairs(ctrl) do table.insert(pts, c) end
	table.insert(pts, ctrl[1])
	local cum = { 0 }
	for i = 2, #pts do cum[i] = cum[i - 1] + (pts[i].p - pts[i - 1].p).magnitude end
	local L = cum[#pts]
	local n = math.floor(L / ds)
	local T = { P = {}, Up = {}, n = n, ds = ds, L = n * ds }
	local j = 1
	for k = 0, n - 1 do
		local s = k * ds
		while cum[j + 1] < s and j < #pts - 1 do j = j + 1 end
		local f = (s - cum[j]) / math.max(1e-6, cum[j + 1] - cum[j])
		local a, b = pts[j], pts[j + 1]
		T.P[k] = a.p + (b.p - a.p) * f
		local u = (a.up or V(0, 1, 0)) * (1 - f) + (b.up or V(0, 1, 0)) * f
		T.Up[k] = u.magnitude > 0.01 and u.unit or V(0, 1, 0)
	end
	return T
end
-- position + orientation at arc length s (wraps round); the car faces along the track, its top towards "up"
local function trackCF(T, s)
	local n = T.n
	s = s % T.L
	local i = math.floor(s / T.ds)
	local f = s / T.ds - i
	local a, b = T.P[i % n], T.P[(i + 1) % n]
	local p = a + (b - a) * f
	local t = T.P[(i + 2) % n] - T.P[(i - 1) % n]
	if t.magnitude < 1e-4 then t = V(1, 0, 0) end
	t = t.unit
	local up = T.Up[i % n] * (1 - f) + T.Up[(i + 1) % n] * f
	local Z = -t
	local X = up:Cross(Z)
	if X.magnitude < 1e-3 then X = V(0, 0, 1):Cross(Z) end
	X = X.unit
	local Y = Z:Cross(X)
	return CFrame.new(p.x, p.y, p.z, X.x, Y.x, Z.x, X.y, Y.y, Z.y, X.z, Y.z, Z.z)
end
local function heightAt(T, s)
	s = s % T.L
	local i = math.floor(s / T.ds)
	local f = s / T.ds - i
	local a, b = T.P[i % T.n], T.P[(i + 1) % T.n]
	return a.y + (b.y - a.y) * f
end

------------------------------------------------------------------ 1. THE SCREAM MACHINE: lift hill, huge drop, a loop-the-loop, banked turn, camel hills
local function coaster(root)
	local O = CFrame.new(470, 0, 2330)
	local ctrl = {}
	local function add(x, y, z, up) table.insert(ctrl, { p = V(x, y, z), up = up }) end
	for x = 0, 54, 6 do add(x, 4, 0) end                                         -- station
	for i = 1, 14 do local t = i / 14 add(60 + 80 * t, 4 + 66 * t, 0) end          -- chain lift
	add(146, 72, 0) add(152, 72.5, 0) add(158, 71, 0)                              -- the top...
	for i = 1, 12 do local t = i / 12 add(158 + 57 * t, 71 - 66 * (0.5 - 0.5 * math.cos(math.pi * t)), 0) end   -- ...and the drop
	add(235, 4, 0)
	for i = 1, 24 do                                                                -- loop-the-loop (upside down at the top)
		local th = 2 * math.pi * i / 24
		local x, y = 255 + 18 * math.sin(th), 22 - 18 * math.cos(th)
		add(x, y, 10 * i / 24, V(255 - x, 22 - y, 0).unit)
	end
	add(275, 4, 10) add(290, 4, 10)
	for i = 1, 12 do                                                                -- banked turn
		local a = math.pi * i / 12
		local c = V(300, 0, 62)
		local p = c + V(52 * math.sin(a), 4 + 10 * math.sin(a), -52 * math.cos(a))
		local inward = V(c.x - p.x, 0, c.z - p.z).unit
		add(p.x, p.y, p.z, (V(0, 1, 0) + inward * 0.7).unit)
	end
	for x = 290, 50, -10 do                                                         -- camel hills
		local hump = math.sin(math.pi * (300 - x) / 125)
		add(x, 4 + 18 * hump * hump, 114)
	end
	add(30, 4, 114) add(10, 4, 114)
	for i = 0, 11 do                                                                -- turn back into the station
		local a = math.pi * i / 12
		local p = V(-57 * math.sin(a), 4, 57 + 57 * math.cos(a))
		local inward = V(-p.x, 0, 57 - p.z).unit
		add(p.x, p.y, p.z, (V(0, 1, 0) + inward * 0.5).unit)
	end
	local T = resample(ctrl, 1)
	-- the track: two rails, ties, and supports where it isn't upside down
	local m = Instance.new("Model")
	m.Name = "Scream Machine Track"
	m.Parent = root
	local b = { model = m, cf = O }
	for k = 0, T.n - 1, 4 do
		local c1, c2, cm = trackCF(T, k), trackCF(T, k + 4), trackCF(T, k + 2)
		local rot = cm - cm.p
		for _, side in ipairs({ -1.3, 1.3 }) do
			local a, e = (c1 * CFrame.new(side, 0, 0)).p, (c2 * CFrame.new(side, 0, 0)).p
			U.P(b, "Rail", V(0.5, 0.5, (e - a).magnitude + 0.3), CFrame.new((a + e) / 2) * rot, "Bright red", "Metal")
		end
		if k % 8 == 0 then U.P(b, "Tie", V(3.2, 0.3, 0.6), c1 * CFrame.new(0, -0.3, 0), "Dark stone grey", "Metal") end
		local up = T.Up[k]
		if k % 20 == 0 and up.y > 0.6 and T.P[k].y > 6 then
			local p = T.P[k]
			U.blk(b, "Support", 1.2, p.y - 0.6, 1.2, p.x, 0, p.z, "Light stone grey", "Metal")
		end
	end
	for _, z in ipairs({ -5, 15 }) do U.blk(b, "LoopTower", 1.6, 22, 1.6, 255, 0, z, "Light stone grey", "Metal") end
	U.blk(b, "LoopBeam", 1.2, 1.2, 20, 255, 22, 5, "Light stone grey", "Metal")
	-- the station: platform on the south side, roof, signs
	U.blk(b, "Platform", 64, 3.4, 8, 28, 0, -7, "Light stone grey", "Concrete")
	U.P(b, "Steps", V(8, 3.4, 6), U.L(28, 1.7, -14, 180), "Light stone grey", "Concrete", { class = "WedgePart" })
	U.blk(b, "StationRoof", 66, 1, 16, 28, 14, -3, "Really black", "SmoothPlastic")
	for x = -2, 58, 20 do U.blk(b, "RoofPost", 0.8, 10.6, 0.8, x, 3.4, -10.5, "Really black", "Metal") end
	sign(b, "THE SCREAM MACHINE", 28, 17.5, -10.8, 40, 5, 180)
	sign(b, "SCARY! HOLD ON TIGHT!", 28, 9, -11, 22, 2.4, 180, Color3.new(1, 0.85, 0.1), Color3.new(0, 0, 0))
	-- the train: three cars
	local cars = {}
	local colors = { "Bright red", "Bright yellow", "Bright blue" }
	for k = 1, 3 do
		local cm, cb, croot = rideModel(root, "Scream Machine Car " .. k, O * trackCF(T, 30 - (k - 1) * 8))
		U.P(cb, "CarBase", V(4.6, 1, 6.4), CFrame.new(0, 0.9, 0), colors[k], "SmoothPlastic")
		U.P(cb, "CarFront", V(4.6, 1.8, 0.5), CFrame.new(0, 2.1, -3), colors[k], "SmoothPlastic")
		U.P(cb, "CarBack", V(4.6, 2.6, 0.5), CFrame.new(0, 2.5, 3), colors[k], "SmoothPlastic")
		if k == 1 then U.P(cb, "Nose", V(4.6, 1.6, 2.4), CFrame.new(0, 1.2, -4.4) * CFrame.Angles(0, math.pi, 0), colors[k], "SmoothPlastic", { class = "WedgePart" }) end
		for i, x in ipairs({ -1.15, 1.15 }) do
			chair(cb, CFrame.new(x, 1.7, 0.8), "Really black", (k == 1 and i == 1) or (k == 3 and i == 2), true)
			U.P(cb, "LapBar", V(1.8, 0.3, 0.3), CFrame.new(x, 2.8, -0.6), "Gold", "Metal", { nc = true })
		end
		for _, w in ipairs({ { -2, -2.4 }, { 2, -2.4 }, { -2, 2.4 }, { 2, 2.4 } }) do U.P(cb, "Wheel", V(0.6, 0.9, 0.9), CFrame.new(w[1], 0.2, w[2]), "Dark stone grey", "Metal", { shape = "cyl" }) end
		rig(cm, croot)
		cars[k] = croot
	end
	local liftEnd, top = 0, 0
	for k = 0, 260 do if T.P[k].y > top then top, liftEnd = T.P[k].y, k end end
	local R = { name = "The Scream Machine", T = T, O = O, cars = cars, s = 30, v = 0, v_brake = 0, wait = 8, liftEnd = liftEnd,
		path = { { 497, 2290 }, { 497, 2312 } } }
	function R.step(dt)
		if R.wait > 0 then
			R.wait = R.wait - dt
			if R.wait <= 0 then R.v = 6 end
		else
			local s = R.s
			local ns
			if s < 60 then
				R.v = 6
			elseif s < R.liftEnd then
				R.v = 12
			else
				local dy = heightAt(T, s + R.v * dt) - heightAt(T, s)
				R.v = math.sqrt(math.max(64, R.v * R.v - 2 * 60 * dy)) - 1.5 * dt
				R.v = U.clamp(R.v, 8, 75)
				if s > T.L - 170 then R.v = math.max(10, R.v_brake - 25 * dt) end
			end
			R.v_brake = R.v
			ns = s + R.v * dt
			if ns >= T.L then ns = ns - T.L end
			if s < 30 and ns >= 30 then ns, R.wait, R.v = 30, 10, 0 end   -- stop in the station to let people on and off
			R.s = ns
		end
		for k, car in ipairs(R.cars) do car.CFrame = R.O * trackCF(T, R.s - (k - 1) * 8) end
	end
	return R
end

------------------------------------------------------------------ 2. Ferris wheel
local function ferris(root)
	local C = V(0, 52, 2650)
	local wm, wb, wroot = rideModel(root, "Ferris Wheel", CFrame.new(C))
	U.P(wb, "Hub", V(6, 6, 6), CFrame.Angles(0, math.rad(90), 0), "Gold", "Metal", { shape = "cyl" })
	for i = 0, 19 do
		local a1 = math.rad(i * 18)
		local p1 = V(40 * math.sin(a1), -40 * math.cos(a1), 0)
		U.P(wb, "Rim", V(2 * 40 * math.sin(math.rad(9)) + 0.4, 1.2, 1.2), CFrame.Angles(0, 0, a1 + math.rad(9)) * CFrame.new(0, -40 * math.cos(math.rad(9)), 0), "Institutional white", "Metal")
		if i % 2 == 0 then
			U.P(wb, "Spoke", V(0.6, 40, 0.6), CFrame.Angles(0, 0, a1) * CFrame.new(0, -20, 0), "Institutional white", "Metal")
			U.P(wb, "Bulb", V(1.2, 1.2, 1.2), CFrame.new(p1 + V(0, 0, -0.8)), U.pick({ "Bright red", "Bright yellow", "Cyan", "Hot pink" }), "Neon", { shape = "ball", nc = true })
		end
	end
	rig(wm, wroot)
	local gond = {}
	local cols = { "Bright red", "Bright blue", "Bright yellow", "Lime green", "Royal purple", "Bright orange", "Hot pink", "Cyan", "Teal", "Bright red" }
	for k = 0, 9 do
		local gm, gb, groot = rideModel(root, "Gondola " .. (k + 1), CFrame.new(C + V(0, -40, 4.5)))
		U.P(gb, "Hanger", V(0.4, 3, 0.4), CFrame.new(0, -1.5, 0), "Dark stone grey", "Metal")
		U.P(gb, "GondolaRoof", V(6, 0.4, 5), CFrame.new(0, -3.2, 0), cols[k + 1], "SmoothPlastic")
		U.P(gb, "GondolaFloor", V(6, 0.4, 5), CFrame.new(0, -7.4, 0), cols[k + 1], "SmoothPlastic")
		for _, c in ipairs({ { -2.8, -2.3 }, { 2.8, -2.3 }, { -2.8, 2.3 }, { 2.8, 2.3 } }) do U.P(gb, "Post", V(0.3, 4, 0.3), CFrame.new(c[1], -5.3, c[2]), "Institutional white", "Metal") end
		chair(gb, U.L(-1.9, -6.9, 0, -90), "Institutional white", k % 3 == 0, false, 3)
		chair(gb, U.L(1.9, -6.9, 0, 90), "Institutional white", false, false, 3)
		rig(gm, groot)
		gond[k + 1] = groot
	end
	-- the stand it turns on, and a platform to get on at the bottom
	local m = Instance.new("Model")
	m.Name = "Ferris Wheel Stand"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local foot, top = V(sx * 24, 0, C.z + sz * 9), V(0, C.y, C.z + sz * 2.5)
			U.P(b, "Leg", V(1.6, 1.6, (top - foot).magnitude), CFrame.new((foot + top) / 2, top), "Light stone grey", "Metal")
		end
	end
	U.P(b, "Axle", V(9, 1.6, 1.6), CFrame.new(C) * CFrame.Angles(0, math.rad(90), 0), "Dark stone grey", "Metal", { shape = "cyl" })
	U.blk(b, "Platform", 14, 4.6, 10, 0, 0, C.z + 4.5 + 8, "Light stone grey", "Concrete")
	sign(b, "FERRIS WHEEL", 0, 8, C.z + 18, 16, 3, 180, Color3.new(0.1, 0.3, 0.8))
	local R = { name = "Ferris Wheel", th = 0, path = { { 60, 2290 }, { 60, C.z + 22 }, { 0, C.z + 22 } } }
	function R.step(dt)
		R.th = R.th + 0.11 * dt
		wroot.CFrame = CFrame.new(C) * CFrame.Angles(0, 0, R.th)
		for k, g in ipairs(gond) do
			local a = R.th + (k - 1) * 2 * math.pi / 10
			g.CFrame = CFrame.new(C + V(40 * math.sin(a), -40 * math.cos(a), 4.5))
		end
	end
	return R
end

------------------------------------------------------------------ 3. FREE FALL drop tower
local function droptower(root)
	local X, Z = 360, 2180
	local m = Instance.new("Model")
	m.Name = "Free Fall Tower"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	U.blk(b, "Tower", 5, 130, 5, X, 0, Z, "Institutional white", "Metal")
	for y = 10, 120, 15 do U.blk(b, "Stripe", 5.2, 2, 5.2, X, y, Z, "Really red", "Neon") end
	U.blk(b, "Top", 9, 4, 9, X, 130, Z, "Really red", "SmoothPlastic")
	U.light(U.ball(b, "Beacon", 2, X, 136, Z, "Really red", "Neon"), Color3.new(1, 0.1, 0.1), 30)
	U.cyl(b, "Platform", 20, 3.4, X, 0, Z, "Light stone grey", "Concrete")
	sign(b, "FREE FALL", X, 6, Z + 12, 14, 3, 0, Color3.new(0.6, 0, 0))
	local rm, rb, rroot = rideModel(root, "Free Fall Seats", CFrame.new(X, 4.5, Z))
	for k = 0, 7 do
		local a = math.rad(k * 45)
		local dir = V(math.cos(a), 0, math.sin(a))
		local pos = dir * 5.6
		U.P(rb, "RingPart", V(4.6, 0.6, 1), CFrame.new(dir * 3.4, dir * 4) * CFrame.Angles(0, math.rad(90), 0), "Dark stone grey", "Metal")
		chair(rb, CFrame.new(pos + V(0, 0.4, 0), pos + V(0, 0.4, 0) + dir), "Really black", k % 3 == 0, true)
		U.P(rb, "SeatBack", V(1.8, 3, 0.4), CFrame.new(pos + V(0, 2, 0) - dir * 1, pos + V(0, 2, 0)), "Bright yellow", "SmoothPlastic")
		U.P(rb, "Harness", V(1.6, 0.4, 0.4), CFrame.new(pos + V(0, 3.4, 0) + dir * 0.4, pos + V(0, 3.4, 0) + dir * 2), "Gold", "Metal", { nc = true })
	end
	rig(rm, rroot)
	local R = { name = "Free Fall", y = 4.5, v = 0, phase = "wait", t = 8, path = { { X, 2290 }, { X, Z + 18 } } }
	function R.step(dt)
		if R.phase == "wait" then
			R.t = R.t - dt
			if R.t <= 0 then R.phase = "up" end
		elseif R.phase == "up" then
			R.y = math.min(110, R.y + 7 * dt)
			if R.y >= 110 then R.phase, R.t = "top", 3 end
		elseif R.phase == "top" then
			R.t = R.t - dt
			if R.t <= 0 then R.phase, R.v = "drop", 0 end
		elseif R.phase == "drop" then
			R.v = R.v + 70 * dt
			R.y = R.y - R.v * dt
			if R.y <= 30 then R.phase = "brake" end
		elseif R.phase == "brake" then
			R.v = math.max(3, R.v - 140 * dt)
			R.y = math.max(4.5, R.y - R.v * dt)
			if R.y <= 4.5 then R.phase, R.t = "wait", 10 end
		end
		rroot.CFrame = CFrame.new(X, R.y, Z)
	end
	return R
end

------------------------------------------------------------------ 4. Carousel
local function carousel(root)
	local C = V(0, 0, 2200)
	local m = Instance.new("Model")
	m.Name = "Carousel"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	U.cyl(b, "Base", 36, 1.2, C.x, 0, C.z, "Institutional white", "Marble")
	U.cyl(b, "Column", 4, 15, C.x, 1.2, C.z, "Gold", "Metal", { refl = 0.3 })
	U.cyl(b, "Canopy", 38, 1, C.x, 16, C.z, "Really red", "SmoothPlastic")
	U.cyl(b, "Canopy2", 30, 1.5, C.x, 17, C.z, "Institutional white", "SmoothPlastic")
	U.cyl(b, "Canopy3", 20, 1.5, C.x, 18.5, C.z, "Really red", "SmoothPlastic")
	U.cyl(b, "Canopy4", 10, 1.5, C.x, 20, C.z, "Institutional white", "SmoothPlastic")
	U.ball(b, "TopBall", 3, C.x, 22.5, C.z, "Gold", "Metal")
	for a = 0, 330, 30 do U.ball(b, "Bulb", 0.8, C.x + 18.6 * math.cos(math.rad(a)), 16, C.z + 18.6 * math.sin(math.rad(a)), "Bright yellow", "Neon", { nc = true }) end
	sign(b, "CAROUSEL", C.x, 3, C.z + 20, 12, 2.4, 0, Color3.new(0.7, 0.1, 0.5))
	local pm, pb, proot = rideModel(root, "Carousel Ride", CFrame.new(C + V(0, 1.2, 0)))
	U.P(pb, "Platform", V(0.4, 32, 32), CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), "Brick yellow", "Wood", { shape = "cyl" })
	for k = 0, 11 do
		local f = CFrame.Angles(0, math.rad(k * 30), 0) * CFrame.new(11, 0, 0)
		local col = U.pick({ "Institutional white", "Brown", "Really black", "Gold", "Pink" })
		U.P(pb, "Pole", V(0.3, 14, 0.3), f * CFrame.new(0, 7.4, 0), "Gold", "Metal", { nc = true })
		U.P(pb, "HorseBody", V(1.2, 1.6, 3.2), f * CFrame.new(0, 3.2, 0), col, "SmoothPlastic")
		U.P(pb, "HorseHead", V(1, 1.4, 1.6), f * CFrame.new(0, 4.4, -1.9) * CFrame.Angles(math.rad(25), 0, 0), col, "SmoothPlastic")
		for _, l in ipairs({ { -0.4, -1.1 }, { 0.4, -1.1 }, { -0.4, 1.1 }, { 0.4, 1.1 } }) do U.P(pb, "HorseLeg", V(0.3, 1.6, 0.3), f * CFrame.new(l[1], 1.6, l[2]), col, "SmoothPlastic") end
		U.P(pb, "Saddle", V(1.3, 0.2, 1.4), f * CFrame.new(0, 4.05, 0.2), "Really red", "Fabric", { nc = true })
		chair(pb, f * CFrame.new(0, 4.3, 0.2), "Really red", k % 4 == 1, false, 1.2)
	end
	rig(pm, proot)
	local R = { name = "Carousel", th = 0, w = 0, t = 0, path = { { C.x, 2290 }, { C.x, C.z + 26 } } }
	function R.step(dt)
		R.t = (R.t + dt) % 52
		local target = (R.t > 8 and R.t < 38) and 0.55 or 0
		R.w = R.w + U.clamp(target - R.w, -0.12 * dt, 0.12 * dt)
		R.th = R.th + R.w * dt
		proot.CFrame = CFrame.new(C + V(0, 1.2, 0)) * CFrame.Angles(0, R.th, 0)
	end
	return R
end

------------------------------------------------------------------ 5. Pirate ship
local function pirate(root)
	local P = V(0, 34, 2400)
	local m = Instance.new("Model")
	m.Name = "Pirate Ship Frame"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local foot, top = V(sx * 15, 0, P.z + sz * 10), V(0, P.y, P.z + sz * 4)
			U.P(b, "Leg", V(1.8, 1.8, (top - foot).magnitude), CFrame.new((foot + top) / 2, top), "Dark stone grey", "Metal")
		end
	end
	U.P(b, "Axle", V(10, 1.4, 1.4), CFrame.new(P) * CFrame.Angles(0, math.rad(90), 0), "Gold", "Metal", { shape = "cyl" })
	U.blk(b, "Platform", 14, 4.4, 6, 0, 0, P.z + 9, "Light stone grey", "Concrete")
	sign(b, "PIRATE SHIP", 0, 8, P.z + 13, 14, 3, 180, Color3.new(0.1, 0.1, 0.1), Color3.new(1, 0.85, 0.3))
	local sm, sb, sroot = rideModel(root, "Pirate Ship", CFrame.new(P))
	for _, z in ipairs({ -3, 3 }) do U.P(sb, "Arm", V(1, 25, 1), CFrame.new(0, -12.5, z), "Dark stone grey", "Metal") end
	U.P(sb, "Hull", V(34, 1, 9), CFrame.new(0, -28, 0), "Reddish brown", "Wood")
	for _, z in ipairs({ -4.5, 4.5 }) do U.P(sb, "Side", V(34, 3, 0.6), CFrame.new(0, -26.5, z), "Brown", "Wood") end
	U.P(sb, "Bow", V(9, 4.5, 6), CFrame.new(19.5, -26.2, 0) * CFrame.Angles(0, math.rad(-90), 0), "Brown", "Wood", { class = "WedgePart" })
	U.P(sb, "Stern", V(9, 4.5, 6), CFrame.new(-19.5, -26.2, 0) * CFrame.Angles(0, math.rad(90), 0), "Brown", "Wood", { class = "WedgePart" })
	U.P(sb, "Mast", V(0.6, 14, 0.6), CFrame.new(13, -21, 0), "Brown", "Wood", { nc = true })
	local flag = U.P(sb, "Flag", V(0.2, 3, 4.4), CFrame.new(13, -15.5, -2.4), "Really black", "Fabric", { nc = true })
	U.text(flag, "X", Color3.new(1, 1, 1), nil, "Right")
	for i, x in ipairs({ -12, -6, 0, 6, 12 }) do
		for j, z in ipairs({ -2, 2 }) do chair(sb, U.L(x, -27.2, z, x < 0 and -90 or 90), "Brown", (i + j) % 3 == 0, (i + j) % 2 == 0, 3) end
	end
	rig(sm, sroot)
	local R = { name = "Pirate Ship", t = 0, path = { { 60, 2290 }, { 60, P.z + 20 }, { 0, P.z + 20 } } }
	function R.step(dt)
		R.t = (R.t + dt) % 50
		local t = R.t
		local A = 0
		if t >= 8 and t < 20 then A = (t - 8) / 12 elseif t >= 20 and t < 32 then A = 1 elseif t >= 32 and t < 44 then A = 1 - (t - 32) / 12 end
		local th = math.rad(70) * A * math.sin(2 * math.pi * t / 6.5)
		sroot.CFrame = CFrame.new(P) * CFrame.Angles(0, 0, th)
	end
	return R
end

------------------------------------------------------------------ 6. Spinning teacups
local function teacups(root)
	local C = V(120, 0.8, 2200)
	local m = Instance.new("Model")
	m.Name = "Teacups Base"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	U.cyl(b, "Base", 46, 0.8, C.x, 0, C.z, "Institutional white", "Marble")
	sign(b, "SPINNING TEACUPS", C.x, 3, C.z + 25, 18, 2.4, 0, Color3.new(0.9, 0.3, 0.6))
	local pm, pb, proot = rideModel(root, "Teacup Platform", CFrame.new(C))
	U.P(pb, "Disc", V(0.4, 42, 42), CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), "Pastel light blue", "SmoothPlastic", { shape = "cyl" })
	U.P(pb, "Teapot", V(6, 6, 6), CFrame.new(0, 3.4, 0), "Hot pink", "SmoothPlastic", { shape = "ball" })
	U.P(pb, "Lid", V(3, 1, 3), CFrame.new(0, 6.6, 0), "Institutional white", "SmoothPlastic")
	rig(pm, proot)
	local cups = {}
	local cols = { "Hot pink", "Bright yellow", "Cyan", "Lime green" }
	for k = 1, 4 do
		local cm, cb, croot = rideModel(root, "Teacup " .. k, CFrame.new(C + V(11, 0.4, 0)))
		U.P(cb, "CupFloor", V(0.4, 8, 8), CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), cols[k], "SmoothPlastic", { shape = "cyl" })
		for a = 0, 324, 36 do U.P(cb, "CupWall", V(2.5, 2.6, 0.4), CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 1.7, -3.8), cols[k], "SmoothPlastic") end
		U.P(cb, "Wheel", V(1.6, 1.6, 1.6), CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), "Institutional white", "Metal", { shape = "cyl" })
		for i, a in ipairs({ 0, 120, 240 }) do chair(cb, CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 0.9, -2.5) * CFrame.Angles(0, math.pi, 0), "Institutional white", i == 1 and k % 2 == 0, false) end
		rig(cm, croot)
		cups[k] = { root = croot, spin = 0, rate = 1 + k * 0.3 }
	end
	local R = { name = "Spinning Teacups", th = 0, w = 0, t = 0, path = { { C.x, 2290 }, { C.x, C.z + 30 } } }
	function R.step(dt)
		R.t = (R.t + dt) % 50
		local target = (R.t > 8 and R.t < 40) and 0.35 or 0
		R.w = R.w + U.clamp(target - R.w, -0.1 * dt, 0.1 * dt)
		R.th = R.th + R.w * dt
		local base = CFrame.new(C) * CFrame.Angles(0, R.th, 0)
		proot.CFrame = base
		for k, c in ipairs(cups) do
			c.spin = c.spin + c.rate * (R.w / 0.35) * dt
			c.root.CFrame = base * CFrame.Angles(0, (k - 1) * math.pi / 2, 0) * CFrame.new(11, 0.4, 0) * CFrame.Angles(0, c.spin, 0)
		end
	end
	return R
end

------------------------------------------------------------------ 7. Swing ride (swings fly outwards as it speeds up)
local function swings(root)
	local C = V(240, 20.6, 2200)
	local m = Instance.new("Model")
	m.Name = "Swing Ride Tower"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	U.cyl(b, "Base", 44, 0.6, C.x, 0, C.z, "Institutional white", "Marble")
	U.cyl(b, "Tower", 3, 20, C.x, 0.6, C.z, "Gold", "Metal")
	sign(b, "SKY SWINGS", C.x, 3, C.z + 24, 14, 2.4, 0, Color3.new(0.1, 0.5, 0.9))
	local tm, tb, troot = rideModel(root, "Swing Ride Top", CFrame.new(C))
	U.P(tb, "Canopy", V(1, 18, 18), CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), "Bright blue", "SmoothPlastic", { shape = "cyl" })
	U.P(tb, "Canopy2", V(1.5, 12, 12), CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90)), "Bright yellow", "SmoothPlastic", { shape = "cyl" })
	U.P(tb, "TopBall", V(3, 3, 3), CFrame.new(0, 3.4, 0), "Really red", "SmoothPlastic", { shape = "ball" })
	for a = 0, 330, 30 do U.P(tb, "Bulb", V(0.8, 0.8, 0.8), CFrame.Angles(0, math.rad(a), 0) * CFrame.new(9, 0, 0), "Bright yellow", "Neon", { shape = "ball", nc = true }) end
	rig(tm, troot)
	local seats = {}
	for k = 0, 11 do
		local sm, sb, sroot = rideModel(root, "Swing " .. (k + 1), CFrame.Angles(0, math.rad(k * 30), 0) * CFrame.new(8, 0, 0) + C)
		for _, z in ipairs({ -0.6, 0.6 }) do U.P(sb, "Chain", V(0.15, 18, 0.15), CFrame.new(0, -9, z), "Light stone grey", "Metal", { nc = true }) end
		chair(sb, CFrame.new(0, -18.2, 0), U.pick({ "Bright red", "Bright yellow", "Cyan", "Lime green" }), k % 4 == 2, k % 2 == 0, 1.6)
		U.P(sb, "SwingBack", V(1.6, 1.4, 0.2), CFrame.new(0, -17.3, 0.85), "Really black", "SmoothPlastic", { nc = true })
		rig(sm, sroot)
		seats[k + 1] = sroot
	end
	local R = { name = "Sky Swings", th = 0, w = 0, t = 0, path = { { C.x, 2290 }, { C.x, C.z + 29 } } }
	function R.step(dt)
		R.t = (R.t + dt) % 50
		local target = (R.t > 10 and R.t < 36) and 1.1 or 0
		R.w = R.w + U.clamp(target - R.w, -0.2 * dt, 0.2 * dt)
		R.th = R.th + R.w * dt
		local tilt = 0.75 * (R.w / 1.1) ^ 2
		local base = CFrame.new(C) * CFrame.Angles(0, R.th, 0)
		troot.CFrame = base
		for k, s in ipairs(seats) do s.CFrame = base * CFrame.Angles(0, (k - 1) * math.pi / 6, 0) * CFrame.new(8, 0, 0) * CFrame.Angles(0, 0, tilt) end
	end
	return R
end

------------------------------------------------------------------ 8. Go-karts
local function gokarts(root)
	local m = Instance.new("Model")
	m.Name = "Go-Kart Track"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	U.blk(b, "Straight", 100, 0.3, 14, 180, 0, 2390, "Dark stone grey", "Concrete")
	U.blk(b, "Straight", 100, 0.3, 14, 180, 0, 2450, "Dark stone grey", "Concrete")
	local pts = {}
	for x = 130, 230, 20 do table.insert(pts, { p = V(x, 0.3, 2390), v = 26 }) end
	for i = 1, 8 do local a = math.pi * i / 8 table.insert(pts, { p = V(230 + 30 * math.sin(a), 0.3, 2420 - 30 * math.cos(a)), v = 22 }) end
	for x = 210, 130, -20 do table.insert(pts, { p = V(x, 0.3, 2450), v = 26 }) end
	for i = 1, 7 do local a = math.pi * i / 8 table.insert(pts, { p = V(130 - 30 * math.sin(a), 0.3, 2420 + 30 * math.cos(a)), v = 22 }) end
	for _, c in ipairs({ { 130, -1 }, { 230, 1 } }) do
		for i = 0, 7 do
			local a1, a2 = math.pi * i / 8, math.pi * (i + 1) / 8
			local p1 = V(c[1] + c[2] * 30 * math.sin(a1), 0, 2420 - c[2] * 30 * math.cos(a1))
			local p2 = V(c[1] + c[2] * 30 * math.sin(a2), 0, 2420 - c[2] * 30 * math.cos(a2))
			U.P(b, "Curve", V(14, 0.3, (p2 - p1).magnitude + 1), CFrame.new((p1 + p2) / 2 + V(0, 0.15, 0), p2 + V(0, 0.15, 0)), "Dark stone grey", "Concrete")
			U.ball(b, "Tyre", 2, (p1 + p2).x / 2 + c[2] * 8 * math.sin(a1), 1, (p1 + p2).z / 2 - c[2] * 8 * math.cos(a1), "Really black")
		end
	end
	U.blk(b, "StartLine", 1.4, 0.05, 14, 180, 0.3, 2390, "Institutional white", nil, { nc = true })
	sign(b, "GO-KARTS", 180, 4, 2378, 14, 3, 0, Color3.new(0.1, 0.6, 0.1))
	local P = FLY.path(pts, true)
	local karts = {}
	local cols = { "Bright red", "Bright blue", "Bright yellow", "Lime green" }
	for k = 1, 4 do
		local km, kb, kroot = rideModel(root, "Go-Kart " .. k, CFrame.new(130, 0.3, 2390))
		U.P(kb, "Body", V(3, 1, 5), CFrame.new(0, 0.8, 0), cols[k], "SmoothPlastic")
		chair(kb, CFrame.new(0, 1.6, 0.8), "Really black", k % 2 == 0, false)
		U.P(kb, "SteeringWheel", V(0.3, 1.2, 1.2), CFrame.new(0, 2.2, -0.9) * CFrame.Angles(0, math.rad(90), math.rad(-30)), "Really black", nil, { shape = "cyl", nc = true })
		for _, w in ipairs({ { -1.7, -1.6 }, { 1.7, -1.6 }, { -1.7, 1.6 }, { 1.7, 1.6 } }) do U.P(kb, "Wheel", V(0.8, 1.2, 1.2), CFrame.new(w[1], 0.6, w[2]), "Really black", nil, { shape = "cyl" }) end
		U.P(kb, "Bumper", V(3.4, 0.6, 0.6), CFrame.new(0, 0.6, -2.7), "Institutional white", "SmoothPlastic")
		rig(km, kroot)
		karts[k] = { root = kroot, t = (k - 1) * P.total / 4, wait = 0 }
	end
	local R = { name = "Go-Karts", path = { { 180, 2290 }, { 180, 2374 } } }
	function R.step(dt)
		for _, k in ipairs(karts) do
			-- a 3-second pit stop at the start line every lap, so you can hop in or out
			if k.wait > 0 then
				k.wait = k.wait - dt
			else
				local before = k.t % P.total
				k.t = k.t + dt
				if before > k.t % P.total then k.wait = 3 end
			end
			local p = FLY.at(P, k.t)
			local a = FLY.at(P, k.t + 0.3)
			local d = V(a.x - p.x, 0, a.z - p.z)
			if d.magnitude > 0.05 then k.look = d.unit end
			k.root.CFrame = CFrame.new(p, p + (k.look or V(1, 0, 0)))
		end
	end
	return R
end

------------------------------------------------------------------ 9. GHOST MANOR: a dark ride through a haunted house
local function haunted(root)
	local m = Instance.new("Model")
	m.Name = "Ghost Manor"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	local x0, x1, z0, z1, h = 300, 360, 2395, 2445, 18
	U.blk(b, "Floor", 60, 0.4, 50, 330, 0, 2420, "Really black", "WoodPlanks")
	U.blk(b, "WallN", 60, h, 1, 330, 0, z1, "Dark stone grey", "Brick")
	U.blk(b, "WallW", 1, h, 50, x0, 0, 2420, "Dark stone grey", "Brick")
	U.blk(b, "WallE", 1, h, 50, x1, 0, 2420, "Dark stone grey", "Brick")
	for _, seg in ipairs({ { 300, 304 }, { 314, 346 }, { 356, 360 } }) do U.blk(b, "WallS", seg[2] - seg[1], h, 1, (seg[1] + seg[2]) / 2, 0, z0, "Dark stone grey", "Brick") end
	for _, x in ipairs({ 309, 351 }) do U.blk(b, "Lintel", 10, h - 10, 1, x, 10, z0, "Dark stone grey", "Brick") end
	U.blk(b, "Roof", 62, 1, 52, 330, h, 2420, "Really black", "Slate")
	for _, x in ipairs({ 306, 354 }) do
		U.blk(b, "TowerBlock", 8, 14, 8, x, h, z0 + 5, "Dark stone grey", "Brick")
		U.P(b, "Spire", V(8, 10, 8), CFrame.new(x, h + 19, z0 + 5), "Really black", "Slate", { class = "WedgePart" })
		U.light(U.blk(b, "TowerWindow", 3, 4, 0.2, x, h + 6, z0 + 0.9, "Bright yellow", "Neon"), Color3.new(1, 0.8, 0.2), 12)
	end
	local sg = U.blk(b, "ManorSign", 30, 5, 0.6, 330, 12.5, z0 - 0.8, "Really black", "SmoothPlastic")
	local spooky
	pcall(function() spooky = Enum.Font.Fantasy end)
	U.text(sg, "GHOST MANOR", Color3.new(1, 0.1, 0.1), Color3.new(0, 0, 0), "Front", spooky)
	U.light(sg, Color3.new(1, 0, 0), 20)
	for i = 0, 5 do
		local x = 296 + i * 14
		U.blk(b, "Tombstone", 2.4, 3, 0.8, x, 0, z0 - 26, "Medium stone grey", "Slate")
		U.blk(b, "FencePost", 0.4, 4, 0.4, x + 7, 0, z0 - 30, "Really black", "Metal")
	end
	U.blk(b, "Fence", 84, 0.3, 0.3, 330, 3.4, z0 - 30, "Really black", "Metal")
	U.blk(b, "Platform", 16, 1, 6, 322, 0, 2374, "Dark stone grey", "WoodPlanks")
	-- spooky things inside (the ghosts and the spider float on players' own computers: src/client/Smooth.lua)
	for i, p in ipairs({ { 320, 2410 }, { 345, 2408 }, { 352, 2432 }, { 325, 2436 }, { 336, 2422 } }) do
		U.ball(b, "Ghost" .. i, 3, p[1], 6, p[2], "Institutional white", "Neon", { tr = 0.3, nc = true })
		U.ball(b, "GhostEye" .. i, 0.5, p[1] - 0.6, 6.4, p[2] - 1.4, "Really black", nil, { nc = true })
		U.ball(b, "GhostEye" .. i, 0.5, p[1] + 0.6, 6.4, p[2] - 1.4, "Really black", nil, { nc = true })
	end
	U.blk(b, "Coffin", 3, 1.4, 7, 342, 0.4, 2425, "Reddish brown", "Wood")
	U.blk(b, "CoffinLid", 3.2, 0.3, 7.2, 343.2, 2.2, 2425, "Brown", "Wood", nil, 20)
	for _, p in ipairs({ { 312, 2440 }, { 357, 2400 } }) do
		U.blk(b, "Skeleton", 1.4, 4, 0.6, p[1], 0.4, p[2], "Institutional white", "SmoothPlastic")
		U.ball(b, "Skull", 1.6, p[1], 5.4, p[2], "Institutional white")
	end
	U.ball(b, "Spider", 2.4, 330, 13, 2412, "Really black")
	U.blk(b, "Web", 0.1, 4, 0.1, 330, 14.2, 2412, "Institutional white", nil, { nc = true })
	U.blk(b, "Boo", 6, 3, 0.2, 358, 7, 2420, "Really red", "Neon", nil, 90)
	for _, p in ipairs({ { 310, 2405 }, { 350, 2440 }, { 330, 2420 } }) do U.light(U.ball(b, "RedLight", 0.8, p[1], 15, p[2], "Really red", "Neon", { nc = true }), Color3.new(1, 0, 0), 22, 2) end
	local pts = {}
	for _, q in ipairs({ { 314, 2380 }, { 330, 2380 }, { 346, 2383 }, { 351, 2398 }, { 352, 2412 }, { 345, 2436 }, { 330, 2438 }, { 314, 2432 },
		{ 312, 2418 }, { 324, 2410 }, { 338, 2414 }, { 336, 2426 }, { 320, 2426 }, { 309, 2410 }, { 309, 2390 } }) do
		table.insert(pts, { p = V(q[1], 0.4, q[2]), v = 5 })
	end
	local P = FLY.path(FLY.round(pts, 3), true)
	local cars = {}
	for k = 1, 2 do
		local cm, cb, croot = rideModel(root, "Ghost Car " .. k, CFrame.new(314, 0.4, 2380))
		U.P(cb, "Tub", V(3.6, 2, 4), CFrame.new(0, 1.2, 0), "Royal purple", "SmoothPlastic")
		chair(cb, CFrame.new(-0.85, 2.4, 0.4), "Really black", k == 2, false, 1.6)
		chair(cb, CFrame.new(0.85, 2.4, 0.4), "Really black", false, false, 1.6)
		U.P(cb, "Bar", V(3.6, 0.3, 0.3), CFrame.new(0, 3.2, -1.2), "Gold", "Metal", { nc = true })
		rig(cm, croot)
		cars[k] = { root = croot, t = (k - 1) * P.total / 2, wait = 0 }
	end
	local R = { name = "Ghost Manor", path = { { 322, 2290 }, { 322, 2360 } } }
	function R.step(dt)
		for _, c in ipairs(cars) do
			if c.wait > 0 then
				c.wait = c.wait - dt
			else
				local before = c.t % P.total
				c.t = c.t + dt
				if before > c.t % P.total then c.wait = 6 end   -- back at the platform: let people on and off
			end
			local p = FLY.at(P, c.t)
			local a = FLY.at(P, c.t + 0.4)
			local d = V(a.x - p.x, 0, a.z - p.z)
			if d.magnitude > 0.02 then c.look = d.unit end
			c.root.CFrame = CFrame.new(p, p + (c.look or V(1, 0, 0)))
		end
	end
	return R
end

------------------------------------------------------------------ 10. Log flume: up the lift, along the top, down the big splash drop
local function flume(root)
	local ctrl = {}
	local function add(x, y, z) table.insert(ctrl, { p = V(x, y, z) }) end
	for x = 110, 170, 10 do add(x, 3, 2640) end
	for i = 1, 8 do local t = i / 8 add(170 + 70 * t, 3 + 27 * t, 2640) end
	for i = 1, 12 do local a = math.pi * i / 12 add(240 + 40 * math.sin(a), 30, 2680 - 40 * math.cos(a)) end
	add(225, 30, 2720)
	for i = 1, 10 do local t = i / 10 add(215 - 40 * t, 30 - 27 * (0.5 - 0.5 * math.cos(math.pi * t)), 2720) end
	add(150, 3, 2720) add(130, 3, 2720)
	for i = 0, 11 do local a = math.pi * i / 12 add(110 - 40 * math.sin(a), 3, 2680 + 40 * math.cos(a)) end
	local T = resample(ctrl, 1)
	local m = Instance.new("Model")
	m.Name = "Log Flume Channel"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	for k = 0, T.n - 1, 5 do
		local c1, c2 = trackCF(T, k), trackCF(T, k + 5)
		local a, e = c1.p, c2.p
		local len = (e - a).magnitude + 0.4
		local mid = CFrame.new((a + e) / 2, e)
		U.P(b, "Trough", V(5.6, 0.4, len), mid * CFrame.new(0, -0.6, 0), "Brown", "WoodPlanks")
		for _, sx in ipairs({ -2.9, 2.9 }) do U.P(b, "Wall", V(0.4, 2.4, len), mid * CFrame.new(sx, 0.4, 0), "Reddish brown", "WoodPlanks") end
		U.P(b, "Water", V(5, 0.2, len), mid * CFrame.new(0, -0.3, 0), "Cyan", "Glass", { tr = 0.35, nc = true })
		if k % 15 == 0 and a.y > 5 then U.blk(b, "Support", 1.2, a.y - 0.8, 1.2, a.x, 0, a.z, "Brown", "Wood") end
	end
	U.fx(U.cyl(b, "SplashPool", 16, 0.4, 160, 1.6, 2720, "Cyan", "Neon", { tr = 0.4, nc = true }), "Sparkles")
	U.blk(b, "Platform", 40, 2.4, 6, 140, 0, 2633, "Light stone grey", "WoodPlanks")
	sign(b, "SPLASH MOUNTAIN LOGS", 140, 8, 2630, 20, 3, 0, Color3.new(0.1, 0.4, 0.7))
	local logs = {}
	for k = 1, 2 do
		local lm, lb, lroot = rideModel(root, "Log Boat " .. k, trackCF(T, 20))
		U.P(lb, "Log", V(10, 3, 3), U.L(0, 0.9, 0, 90), "Brown", "Wood", { shape = "cyl" })
		U.P(lb, "Hollow", V(2.4, 0.3, 7.6), CFrame.new(0, 2.25, 0), "Reddish brown", "Wood", { nc = true })
		chair(lb, CFrame.new(0, 2.3, -1.8), "Reddish brown", k == 1, true, 2)
		chair(lb, CFrame.new(0, 2.3, 1.8), "Reddish brown", false, false, 2)
		rig(lm, lroot)
		logs[k] = { root = lroot, s = 20 + (k - 1) * T.L / 2, v = 6, wait = 0 }
	end
	local peak, dropEnd = 0, 0
	for k = 0, T.n - 1 do if T.P[k].y > T.P[peak].y then peak = k end end
	for k = peak, T.n - 1 do if T.P[k].y < 3.5 then dropEnd = k break end end
	local R = { name = "Log Flume", path = { { 60, 2290 }, { 60, 2550 }, { 140, 2550 }, { 140, 2626 } } }
	function R.step(dt)
		for _, l in ipairs(logs) do
			if l.wait > 0 then
				l.wait = l.wait - dt
			else
				local s = l.s % T.L
				if s < 60 then l.v = 5
				elseif s < 135 then l.v = 8
				elseif s > dropEnd then l.v = math.max(6, l.v - 12 * dt)   -- splash!
				else
					local dy = heightAt(T, s + l.v * dt) - heightAt(T, s)
					l.v = U.clamp(math.sqrt(math.max(64, l.v * l.v - 2 * 50 * dy)) - 4 * dt, 8, 45)
				end
				local ns = l.s + l.v * dt
				if s < 20 and (ns % T.L) >= 20 then ns, l.wait = l.s - s + 20, 6 end
				l.s = ns
			end
			l.root.CFrame = trackCF(T, l.s)
		end
	end
	return R
end

------------------------------------------------------------------ the park around the rides
local function parkGrounds(root)
	local m = Instance.new("Model")
	m.Name = "Park Grounds"
	m.Parent = root
	local b = { model = m, cf = CFrame.new() }
	U.blk(b, "AvenueA", 660, 0.4, 16, 180, 0, 2290, "Brick yellow", "Concrete")
	U.blk(b, "AvenueB", 16, 0.4, 470, 60, 0, 2525, "Brick yellow", "Concrete")
	U.blk(b, "AvenueC", 400, 0.4, 14, 260, 0, 2550, "Brick yellow", "Concrete")
	-- the entrance arch
	for _, z in ipairs({ 2280, 2300 }) do U.blk(b, "ArchPillar", 3, 22, 3, -120, 0, z, "Bright red", "SmoothPlastic") end
	local s = U.blk(b, "ArchSign", 3, 7, 26, -120, 22, 2290, "Bright yellow", "SmoothPlastic")
	U.text(s, "PARADISE PARK", Color3.new(0.8, 0, 0), nil, "Left")
	U.text(s, "PARADISE PARK", Color3.new(0.8, 0, 0), nil, "Right")
	for _, p in ipairs({ { -130, 2268 }, { -130, 2312 } }) do
		U.blk(b, "TicketBooth", 6, 8, 6, p[1], 0, p[2], "Institutional white", "SmoothPlastic")
		U.blk(b, "BoothRoof", 7, 1, 7, p[1], 8, p[2], "Bright red", "SmoothPlastic")
	end
	U.cyl(b, "FountainBasin", 18, 1.6, -60, 0, 2290 + 20, "Light stone grey", "Marble")
	U.fx(U.cyl(b, "FountainWater", 16, 0.3, -60, 1.4, 2310, "Cyan", "Neon", { tr = 0.4, nc = true }), "Sparkles")
	-- snack stands and benches along the avenue
	local stands = { { "POPCORN", "Bright red" }, { "COTTON CANDY", "Hot pink" }, { "ICE CREAM", "Cyan" }, { "HOT DOGS", "Bright yellow" }, { "CHURROS", "Bright orange" } }
	for i, st in ipairs(stands) do
		local x = -40 + i * 75
		U.blk(b, "Stand", 6, 4, 4, x, 0, 2306, "Institutional white", "SmoothPlastic")
		U.blk(b, "Awning", 7, 0.6, 5, x, 6, 2306, st[2], "Fabric")
		for _, dx in ipairs({ -3, 3 }) do U.blk(b, "AwningPost", 0.3, 2, 0.3, x + dx, 4, 2304, "Institutional white", "Metal") end
		local sg = U.blk(b, "StandSign", 6, 1.2, 0.2, x, 6.8, 2303.8, st[2], "SmoothPlastic")
		U.text(sg, st[1], Color3.new(1, 1, 1), nil, "Front")
		U.seat(b, x, 0.4, 2275, 0, "Brown", 5)
	end
	for x = -100, 880, 60 do RESORT.palm(b, x, 2265, 12) end
	for z = 2320, 2760, 60 do RESORT.palm(b, 75, z, 12) end
	for _, p in ipairs({ { -100, 2600 }, { -100, 2800 }, { 300, 2850 }, { 600, 2800 }, { 800, 2650 }, { 450, 2600 } }) do RESORT.palm(b, p[1], p[2], 15) end
	-- lamp posts
	for x = -80, 860, 80 do
		U.blk(b, "LampPost", 0.5, 9, 0.5, x, 0, 2299, "Really black", "Metal")
		U.light(U.ball(b, "Lamp", 1.4, x, 9.4, 2299, "Cool yellow", "Neon"), Color3.new(1, 0.9, 0.6), 18)
	end
end

------------------------------------------------------------------ visitors: people who come off the planes (or out of the
-- terminal), walk to the park, queue at a few rides, then walk back to the airport
PARK.MAX = 18
function PARK.visitor(fromX)
	if PARK.visitors >= PARK.MAX or not PARK.root or #RIDES == 0 then return end
	local route = {}
	local function go(x, y, z, wait) table.insert(route, { p = V(x, y, z), wait = wait }) end
	fromX = fromX or math.random(-700, -300)
	go(fromX, 1, 2180 + math.random(-6, 6))
	go(-262, 1, 2180 + math.random(-3, 3))
	go(-240, 0.4, 2184)
	go(-235, 0.4, 2214)
	go(-148, 0.4, 2214)
	go(-148, 0.4, 2290)
	local last
	for _ = 1, math.random(2, 4) do
		local r = U.pick(RIDES)
		if r ~= last then
			last = r
			for i, q in ipairs(r.path) do go(q[1], 0.4, q[2], i == #r.path and math.random(6, 14) or nil) end
			for i = #r.path - 1, 1, -1 do go(r.path[i][1], 0.4, r.path[i][2]) end
		end
	end
	go(-148, 0.4, 2290)
	go(-148, 0.4, 2214)
	go(-235, 0.4, 2214)
	go(-240, 0.4, 2184)
	go(-262, 1, 2176)
	go(-330 - math.random(0, 200), 1, 2176)
	local model, root = M.person(PARK.crowd, CFrame.new(route[1].p), M.passengerLook(), "Park Visitor")
	U.rig(model, root, false)
	PARK.visitors = PARK.visitors + 1
	local w = NPC.walk(PARK, model, root, route, CONST.walkSpeed + math.random() * 2, function() PARK.visitors = PARK.visitors - 1 end)
	w.kind = "visitor"
	return w
end

------------------------------------------------------------------ build it all, and the pads that take you there and back
local function pad(parent, cf, text, color, fn)
	local p = U.newPart()
	p.Name = "TravelPad"
	p.Anchored = true
	p.Size = V(10, 0.4, 10)
	p.BrickColor = BrickColor.new(color)
	pcall(function() p.Material = Enum.Material.Neon end)
	p.CFrame = cf
	U.bill(p, text, 14, 3.5, 5, Color3.new(1, 1, 1))
	U.light(p, BrickColor.new(color).Color, 16)
	p.Parent = parent
	local busy = {}
	p.Touched:connect(function(hit)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if not player or busy[player] then return end
		busy[player] = true
		fn(player)
		wait(2)
		busy[player] = nil
	end)
end
function RESORT.toPark(player)
	local char = player.Character
	local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
	if torso then torso.CFrame = RESORT.entrance + V(math.random(-4, 4), 0, math.random(-4, 4)) end
	A.toast(player, "Welcome to Paradise Park! Sit in any ride seat to ride. Jump to get off.", "gold")
end
function RESORT.goHome(player)
	local char = player.Character
	local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
	if not torso then return end
	local plot = G.byPlayer[player]
	if plot then torso.CFrame = plot.cf * CFrame.new(0, 4, 14)
	else
		local sp = MAP:FindFirstChild("Spawn")
		if sp then torso.CFrame = sp.CFrame + V(0, 4, 0) end
	end
end
function RESORT.build()
	local root = Instance.new("Model")
	root.Name = "Paradise Island"
	root.Parent = workspace
	RESORT.root = root
	local centre = Instance.new("Vector3Value")
	centre.Name = "Centre"
	centre.Value = V(-210, 0, 2420)
	centre.Parent = root
	RESORT.buildIsland(root)
	RESORT.buildAirport(root)
	local park = Instance.new("Model")
	park.Name = "Paradise Park"
	park.Parent = root
	PARK.root = park
	PARK.crowd = Instance.new("Model")
	PARK.crowd.Name = "Visitors"
	PARK.crowd.Parent = park
	parkGrounds(park)
	for _, make in ipairs({ coaster, ferris, droptower, carousel, pirate, teacups, swings, gokarts, haunted, flume }) do
		local ok, r = pcall(make, park)
		if ok and r then table.insert(RIDES, r) else print("Airport: building a ride failed: " .. tostring(r)) end
	end
	RESORT.ready = true
	pad(root, CFrame.new(-176, 0.6, 2250), "FLY HOME", "Lime green", RESORT.goHome)
	pad(workspace, CFrame.new(35, 0.6, -205), "FLY TO PARADISE PARK\n(10 rides!)", "Hot pink", RESORT.toPark)
end
RESORT.parkCenter = V(300, 0, 2450)
-- the rides only run while someone is close enough to see them, and more smoothly the closer they are
function RESORT.step(dt)
	RESORT.rideAcc = (RESORT.rideAcc or 0) + dt
	local d = U.nearest(RESORT.parkCenter)
	if d > 1500 then RESORT.rideAcc = 0 return end
	if RESORT.rideAcc < (d < 700 and 0.05 or 0.1) then return end   -- 20 updates a second near, 10 further away
	dt = RESORT.rideAcc
	RESORT.rideAcc = 0
	for _, r in ipairs(RIDES) do
		local ok, err = pcall(r.step, dt)
		if not ok and not r.failed then
			r.failed = true
			print("Airport: ride " .. r.name .. " failed: " .. tostring(err))
		end
	end
end
RESORT.RIDES, RESORT.PARK = RIDES, PARK
