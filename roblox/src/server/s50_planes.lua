-- ==== s50_planes.lua
------------------------------------------------------------------ paths for NPC planes
-- points = list of { p = Vector3, v = speed (studs/s), back = true while being pushed backwards }
function FLY.path(points, loop)
	local P = { pts = points, t = { 0 }, loop = loop }
	for i = 2, #points do
		local d = (points[i].p - points[i - 1].p).magnitude
		P.t[i] = P.t[i - 1] + d / math.max(1, (points[i].v + points[i - 1].v) / 2)
	end
	P.total = P.t[#points]
	if loop then
		local d = (points[1].p - points[#points].p).magnitude
		P.total = P.total + d / math.max(1, (points[1].v + points[#points].v) / 2)
	end
	return P
end
function FLY.at(P, t)
	if P.loop then t = t % P.total else t = U.clamp(t, 0, P.total) end
	local n = #P.pts
	for i = 1, n do
		local t1 = (i < n) and P.t[i + 1] or P.total
		if t <= t1 or i == n then
			local a = P.pts[i]
			local b = (i < n) and P.pts[i + 1] or (P.loop and P.pts[1] or P.pts[n])
			local span = t1 - P.t[i]
			local f = span > 0 and (t - P.t[i]) / span or 1
			return a.p + (b.p - a.p) * U.clamp(f, 0, 1), a.back
		end
	end
	return P.pts[n].p, false
end
-- round the corners of a path so planes turn smoothly
function FLY.round(points, r)
	local out = { points[1] }
	for i = 2, #points - 1 do
		local a, b, c = points[i - 1], points[i], points[i + 1]
		local d1, d2 = (b.p - a.p), (c.p - b.p)
		if d1.magnitude > 2 * r and d2.magnitude > 2 * r and (d1.unit - d2.unit).magnitude > 0.05 then
			local p0, p2 = b.p - d1.unit * r, b.p + d2.unit * r
			for k = 0, 4 do
				local t = k / 4
				local q = p0 * (1 - t) * (1 - t) + b.p * 2 * (1 - t) * t + p2 * t * t
				table.insert(out, { p = q, v = b.v, back = b.back })
			end
		else
			table.insert(out, b)
		end
	end
	table.insert(out, points[#points])
	return out
end
-- move a plane along a path with a smoothly turning nose
function FLY.place(pl, P, t, dt)
	local p, back = FLY.at(P, t)
	local ahead = FLY.at(P, t + 0.6)
	local behind = FLY.at(P, t - 0.6)
	local dir = ahead - behind
	if dir.magnitude < 0.05 then dir = pl.look or Vector3.new(0, 0, -1) end
	if back then dir = -dir end
	dir = dir.unit
	local old = pl.look or dir
	local a = math.min(1, (dt or 0.05) * 2.5)
	local new = old * (1 - a) + dir * a
	if new.magnitude < 0.05 then new = dir end
	pl.look = new.unit
	-- bank into turns
	local turn = old:Cross(pl.look).y
	pl.bank = (pl.bank or 0) * 0.9 + U.clamp(-turn * 40, -0.6, 0.6) * 0.1
	local cf = CFrame.new(p, p + pl.look) * CFrame.Angles(0, 0, pl.bank)
	pl.root.CFrame = cf
end

------------------------------------------------------------------ planes flying around the whole map
local H = 7.3   -- airliner centre above the ground when it's on its wheels
local function pt(x, y, z, v) return { p = Vector3.new(x, y, z), v = v } end
function FLY.initGlobal()
	local sky = Instance.new("Model")
	sky.Name = "SkyTraffic"
	sky.Parent = workspace
	G.global = {}
	-- touch-and-go on the big runway in the middle of the map, then a big loop to the north
	local loopA = FLY.path(FLY.round({
		pt(-2600, 260, 0, 115), pt(-1400, 70, 0, 100), pt(-1050, H + 0.3, 0, 85), pt(0, H + 0.3, 0, 75), pt(650, H + 0.3, 0, 85),
		pt(1100, 50, 0, 100), pt(1900, 240, 0, 115), pt(2600, 330, 400, 120), pt(2850, 350, 1200, 120), pt(2400, 350, 2000, 120),
		pt(1500, 350, 2300, 120), pt(-1500, 350, 2300, 120), pt(-2400, 340, 2000, 120), pt(-2850, 320, 1200, 120),
		pt(-2900, 290, 400, 115) }, 180), true)
	-- a high loop over the south
	local loopB = FLY.path(FLY.round({
		pt(2900, 480, -300, 130), pt(-2900, 480, -300, 130), pt(-3200, 480, -1300, 130), pt(-2500, 480, -2300, 130),
		pt(2500, 480, -2300, 130), pt(3200, 480, -1300, 130) }, 260), true)
	-- small planes around the edge of the map
	local loopC = FLY.path(FLY.round({
		pt(-1900, 200, -1400, 70), pt(1900, 220, -1400, 70), pt(1900, 240, 1400, 70), pt(-1900, 220, 1400, 70) }, 250), true)
	local tails = { "Bright red", "Bright blue", "Bright green", "Royal purple", "Bright orange" }
	for i = 1, 3 do
		local m, root = M.airliner(sky, CFrame.new(0, 3000, 0), tails[i], "Airliner")
		table.insert(G.global, { root = root, path = loopA, off = (i - 1) * loopA.total / 3 })
	end
	for i = 1, 2 do
		local m, root = M.airliner(sky, CFrame.new(0, 3000, 0), tails[3 + i], "Airliner")
		table.insert(G.global, { root = root, path = loopB, off = (i - 1) * loopB.total / 2 })
	end
	-- airliners parked at the hub terminal next to the plaza
	for i, x in ipairs({ -380, -300, -220 }) do M.airliner(sky, CFrame.new(x, 7.6, -112), tails[i + 1], "Parked Airliner") end
	for i = 1, 2 do
		local m, body, seat, gyro, vel = M.flyable(sky, "small", CFrame.new(0, 3000, 0), i == 1 and "Bright yellow" or "Bright red")
		seat:Destroy() gyro:Destroy() vel:Destroy()
		for _, p in ipairs(m:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
		body.Anchored = true
		table.insert(G.global, { root = body, path = loopC, off = (i - 1) * loopC.total / 2 })
	end
end

------------------------------------------------------------------ airliners at your gates: board, push back, taxi, take off,
-- fly around for about 5 minutes, come back, land, let everyone off, board again.
-- Every gate/stand has a small fleet (opt.count planes): one at the gate, the others in the sky. A plane only comes in
-- to land when its gate is free. Pilots sit in the cockpit; passengers board through the jet bridge.
-- opt (all optional): z = where it parks, dep/arr = path makers (default: the main runway), rz = that runway's z,
-- needs = the plot flag that must be true before it departs, tail = colour, cargo = freighter look, name, count
FLY.CRUISE = 300   -- seconds in the air
function A.gatePlane(plot, n, x, opt)
	if plot.gates[n] then return end
	opt = opt or {}
	local g = { n = n, x = x, z = opt.z or 388, rz = opt.rz or 525, opt = opt, planes = {}, made = 0, count = opt.count or 3,
		dep = opt.dep or FLY.departure, arr = opt.arr or FLY.arrival, needs = opt.needs or "hasRunway", nextSpawn = 0 }
	plot.gates[n] = g
	FLY.newPlane(plot, g, "parked")
end
local NAMES = { "SKY", "AIR", "JET" }
function FLY.newPlane(plot, g, state)
	g.made = g.made + 1
	local park = plot.cf * U.L(g.x, H, g.z)
	local name = (g.opt.name or ("Flight " .. NAMES[(g.made - 1) % 3 + 1] .. plot.i .. g.n)) .. (g.made > 1 and ("-" .. g.made) or "")
	local tail = g.opt.tail or (g.made == 1 and plot.color or U.pick({ "Bright red", "Bright blue", "Bright green", "Royal purple", "Bright orange", "Navy blue" }))
	local m, root = M.airliner(plot.Planes, park, tail, name, g.opt.cargo, true)
	local gp = { plot = plot, g = g, n = g.n, k = g.made, x = g.x, model = m, root = root, state = state, t0 = tick(), park = park, look = park.lookVector,
		dep = g.dep, arr = g.arr, needs = g.needs, pax = 0 }
	table.insert(g.planes, gp)
	plot.gatePlanes[g.n * 10 + g.made] = gp
	if state == "cruising" then FLY.startCruise(gp, math.random() * 0.8) end
	return gp
end
function A.startDepartures(plot)
	for _, gp in pairs(plot.gatePlanes) do if gp.state == "parked" then gp.t0 = tick() - math.random(0, 20) end end
end
local function localPath(plot, list)
	local out = {}
	for _, q in ipairs(list) do table.insert(out, { p = plot.cf * Vector3.new(q[1], q[2], q[3]), v = q[4], back = q[5] }) end
	return FLY.path(FLY.round(out, 10), false)
end
function FLY.departure(plot, x)
	return localPath(plot, {
		{ x, H, 388, 4, true }, { x, H, 425, 4, true }, { x + 6, H, 442, 4, true }, { x - 10, H, 460, 10 }, { -185, H, 460, 14 },
		{ -192, H, 490, 12 }, { -186, H, 525, 12 }, { -150, H, 525, 25 }, { -40, H, 525, 55 }, { 110, H, 525, 85 },
		{ 230, 40, 525, 95 }, { 600, 170, 525, 110 }, { 1200, 320, 525, 120 } })
end
function FLY.arrival(plot, x)
	return localPath(plot, {
		{ -1300, 320, 525, 120 }, { -600, 150, 525, 105 }, { -215, H + 0.3, 525, 90 }, { -60, H, 525, 65 }, { 110, H, 525, 30 },
		{ 182, H, 525, 14 }, { 190, H, 490, 10 }, { 185, H, 460, 10 }, { x + 14, H, 460, 8 }, { x, H, 440, 6 }, { x, H, 388, 4 } })
end
-- cargo jets: park on the cargo apron (z 700), push back, taxi to the second runway (z 820), take off, come back
function FLY.cargoDeparture(plot, x)
	return localPath(plot, {
		{ x, H, 700, 4, true }, { x, H, 735, 4, true }, { x + 6, H, 752, 4, true }, { x - 10, H, 775, 10 }, { -270, H, 775, 14 },
		{ -282, H, 800, 12 }, { -276, H, 820, 12 }, { -240, H, 820, 25 }, { -120, H, 820, 55 }, { 60, H, 820, 85 },
		{ 250, 40, 820, 95 }, { 620, 170, 820, 110 }, { 1200, 320, 820, 120 } })
end
function FLY.cargoArrival(plot, x)
	return localPath(plot, {
		{ -1300, 320, 820, 120 }, { -600, 150, 820, 105 }, { -285, H + 0.3, 820, 90 }, { -100, H, 820, 65 }, { 150, H, 820, 30 },
		{ 265, H, 820, 14 }, { 280, H, 800, 10 }, { 270, H, 775, 10 }, { x + 14, H, 775, 8 }, { x, H, 755, 6 }, { x, H, 700, 4 } })
end

-- the holding loop: straight along the runway line (where departures end at D and arrivals start at A), then a big
-- rectangle out over the sea and back. One lap takes about 70 seconds.
function FLY.loop(plot, rz)
	plot.loops = plot.loops or {}
	if plot.loops[rz] then return plot.loops[rz] end
	local pts = {}
	for _, q in ipairs({ { -1800, 330, rz }, { -1300, 320, rz }, { 1200, 320, rz }, { 1800, 330, rz }, { 1800, 360, rz + 900 }, { -1800, 360, rz + 900 } }) do
		table.insert(pts, { p = plot.cf * Vector3.new(q[1], q[2], q[3]), v = 120 })
	end
	local P = FLY.path(FLY.round(pts, 250), true)
	local A_, D_ = plot.cf * Vector3.new(-1300, 320, rz), plot.cf * Vector3.new(1200, 320, rz)
	for i, q in ipairs(P.pts) do
		if (q.p - A_).magnitude < 0.5 then P.tA = P.t[i] end
		if (q.p - D_).magnitude < 0.5 then P.tD = P.t[i] end
	end
	plot.loops[rz] = P
	return P
end
-- frac = where on the loop to start, as a fraction of a lap ahead of D (0 = just took off)
function FLY.startCruise(gp, frac)
	local P = FLY.loop(gp.plot, gp.g.rz)
	local now = tick()
	gp.state, gp.t0 = "cruising", now
	gp.loop = P
	gp.qoff = (P.tD or 0) + (frac or 0) * P.total - now
	gp.until_ = now + FLY.CRUISE * (0.85 + math.random() * 0.3) - (frac or 0) * 120
	gp.lastQ = nil
	gp.look = nil
end
function FLY.gateFree(g, me)
	local now = tick()
	for _, p in ipairs(g.planes) do
		if p ~= me and p.model.Parent and (p.state == "parked" or p.state == "arriving" or (p.state == "departing" and now - p.t0 < 30)) then return false end
	end
	return true
end
-- the plane at this gate that passengers can board now (parked, everyone off, not about to leave)
function FLY.boarding(g)
	if not g then return nil end
	local now = tick()
	for _, p in ipairs(g.planes) do
		if p.state == "parked" and p.model.Parent and now - p.t0 > 6 and now < (p.leaveAt or 0) - 4 and p.pax < 40 then return p end
	end
	return nil
end
function FLY.boardTime(plot)
	local pilots, atc = plot.staff.pilot or 0, plot.staff.atc or 0
	return math.max(30, 70 - 6 * pilots - 4 * atc)
end

function FLY.gateStep(gp, dt)
	local plot, now = gp.plot, tick()
	if not gp.model.Parent then return end
	if gp.state == "parked" then
		gp.root.CFrame = gp.park
		gp.look = gp.park.lookVector
		gp.leaveAt = gp.t0 + FLY.boardTime(plot)
		-- the crew walks out to the plane a little before it leaves
		if not gp.crewIn and now > gp.leaveAt - 10 and NPC.crew then
			gp.crewIn = true
			pcall(NPC.crew, plot, gp, true)
		end
		if plot[gp.needs] and now > gp.leaveAt then
			gp.state, gp.t0, gp.path = "departing", now, gp.dep(plot, gp.x)
			gp.crewIn, gp.pax = false, 0
		end
	elseif gp.state == "departing" or gp.state == "arriving" then
		local t = now - gp.t0
		FLY.place(gp, gp.path, t, dt)
		if t >= gp.path.total then
			if gp.state == "departing" then
				FLY.startCruise(gp, 0)
			else
				gp.state, gp.t0 = "parked", now
				-- everyone gets off: passengers to baggage claim and the exit, the crew back to the terminal
				if NPC.arrivals then pcall(NPC.arrivals, plot, gp) end
				if NPC.crew then pcall(NPC.crew, plot, gp, false) end
			end
		end
	elseif gp.state == "cruising" then
		local P = gp.loop
		local q = (now + gp.qoff) % P.total
		-- far away in the sky: 15 updates a second is plenty
		if now >= (gp.nextPlace or 0) then
			gp.nextPlace = now + 1 / 15
			FLY.place(gp, P, now + gp.qoff, dt)
		end
		-- time to come home? only when the gate is free, and only from the point where the approach starts
		local last = gp.lastQ
		gp.lastQ = q
		if now > gp.until_ and plot[gp.needs] and last and P.tA and FLY.gateFree(gp.g, gp) then
			local passed = (last <= P.tA and q >= P.tA) or (last > q and (P.tA >= last or P.tA <= q))
			if passed then
				gp.state, gp.t0, gp.path = "arriving", now, gp.arr(plot, gp.x)
			end
		end
	end
end
-- more planes join each fleet once its runway exists (they appear somewhere on the holding loop)
function FLY.fleetStep(plot)
	local now = tick()
	for _, g in pairs(plot.gates) do
		if plot[g.needs] and #g.planes < g.count and now > g.nextSpawn then
			g.nextSpawn = now + 25
			FLY.newPlane(plot, g, "cruising")
		end
	end
end

------------------------------------------------------------------ planes you can fly
function A.flyPad(plot, pad, kind)
	local busy = false
	pad.Touched:connect(function(hit)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if busy or not player then return end
		if player ~= plot.owner then A.toast(player, "Only the owner can fly these planes", "red") return end
		busy = true
		FLY.spawn(plot, kind, player)
		wait(3)
		busy = false
	end)
end

function FLY.spawn(plot, kind, player)
	local old = G.flyers[player]
	if old then pcall(function() old.model:Destroy() end) G.flyers[player] = nil end
	local T = FLY.TYPES[kind]
	local cf = plot.cf * U.L(-268, T.lift + 0.4, 525, -90)
	local m, body, seat, gyro, vel = M.flyable(plot.Planes, kind, cf, plot.color, player)
	local look = cf.lookVector
	G.flyers[player] = { player = player, plot = plot, kind = kind, model = m, body = body, seat = seat, gyro = gyro, vel = vel,
		speed = 0, yaw = math.atan2(-look.x, -look.z), pitch = 0, bank = 0 }
	-- put the pilot on the seat
	local char = player.Character
	local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
	if torso then torso.CFrame = seat.CFrame + Vector3.new(0, 3, 0) end
	A.toast(player, "W/S = speed, A/D = turn, E = up, Q = down. Space to jump out.", "cyan")
end

function FLY.step(dt)
	for player, f in pairs(G.flyers) do
		if not f.model.Parent or not f.body.Parent then
			G.flyers[player] = nil
		else
			local T = FLY.TYPES[f.kind]
			local weld = f.seat and f.seat:FindFirstChild("SeatWeld")
			local driving = weld and weld.Part1 and weld.Part1.Parent == player.Character
			local thr, steer = 0, 0
			if driving then
				thr, steer = f.seat.Throttle, f.seat.Steer
				local c = G.ctl[player]
				if c then
					if c.t and c.t ~= 0 then thr = c.t end
					if c.s and c.s ~= 0 then steer = c.s end
				end
			end
			local max = T.max * (1 + 0.15 * (f.plot.staff.mechanic or 0))
			if driving then
				f.speed = f.speed + thr * T.accel * dt
				if thr == 0 then f.speed = f.speed - 2 * dt end
			else
				f.speed = f.speed - 30 * dt
			end
			f.speed = U.clamp(f.speed, 0, max)
			local air = f.speed >= T.takeoff
			f.yaw = f.yaw - steer * math.rad(T.turn) * dt * (air and 1 or 0.7)
			local pin = driving and (G.pitch[player] or 0) or 0
			local target = air and pin * math.rad(28) or 0
			f.pitch = f.pitch + (target - f.pitch) * math.min(1, dt * 3)
			f.bank = f.bank + ((air and -steer * math.rad(30) or 0) - f.bank) * math.min(1, dt * 3)
			local rot = CFrame.Angles(0, f.yaw, 0) * CFrame.Angles(f.pitch, 0, 0) * CFrame.Angles(0, 0, f.bank)
			f.gyro.cframe = rot
			local look = rot.lookVector
			if air then
				local v = look * f.speed
				if f.body.Position.y > 1500 and v.y > 0 then v = Vector3.new(v.x, 0, v.z) end
				f.vel.maxForce = Vector3.new(4e6, 4e6, 4e6)
				f.vel.velocity = v
			else
				local flat = Vector3.new(look.x, 0, look.z)
				if flat.magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
				f.vel.maxForce = Vector3.new(4e6, 0, 4e6)
				f.vel.velocity = flat.unit * f.speed
			end
			f.air = air
			if f.body.Position.y < -100 then pcall(function() f.model:Destroy() end) end
		end
	end
end
