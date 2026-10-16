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
	local start = CFrame.new(0, 3000, 0)
	for i = 1, 3 do
		local root = U.mover(M.airliner(nil, start, tails[i], "Airliner"), start)
		table.insert(G.global, { root = root, path = loopA, off = (i - 1) * loopA.total / 3 })
	end
	for i = 1, 2 do
		local root = U.mover(M.airliner(nil, start, tails[3 + i], "Airliner"), start)
		table.insert(G.global, { root = root, path = loopB, off = (i - 1) * loopB.total / 2 })
	end
	-- airliners parked at the hub terminal next to the plaza (they never move: plain anchored parts)
	for i, x in ipairs({ -380, -300, -220 }) do M.airliner(sky, CFrame.new(x, 7.6, -112), tails[i + 1], "Parked Airliner") end
	for i = 1, 2 do
		local m, body, seat, gyro, vel = M.flyable(nil, "small", start, i == 1 and "Bright yellow" or "Bright red")
		seat:Destroy() gyro:Destroy() vel:Destroy()
		for _, c in ipairs(body:GetChildren()) do if c:IsA("JointInstance") then c:Destroy() end end
		for _, p in ipairs(m:GetChildren()) do if p:IsA("BasePart") then p.Anchored = true p.CanCollide = false end end
		local root = U.mover(m, start)
		table.insert(G.global, { root = root, path = loopC, off = (i - 1) * loopC.total / 2 })
	end
end

------------------------------------------------------------------ airliners at your gates: board, push back, taxi, take off, come back, land
function A.gatePlane(plot, n, x)
	if plot.gatePlanes[n] then return end
	local park = plot.cf * U.L(x, H, 388)
	local m = M.airliner(nil, park, plot.color, "Flight " .. plot.i .. "0" .. n)
	local root = U.mover(m, park, plot)
	plot.gatePlanes[n] = { plot = plot, n = n, x = x, model = m, root = root, state = "parked", t0 = tick(), park = park, look = park.lookVector }
end
function A.startDepartures(plot)
	for _, gp in pairs(plot.gatePlanes) do gp.t0 = tick() - math.random(0, 20) end
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
function FLY.gateStep(gp, dt)
	local plot, now = gp.plot, tick()
	if not gp.model.Parent then return end
	if gp.state == "parked" then
		if not gp.atPark then gp.root.CFrame = gp.park gp.atPark = true end
		gp.look = gp.park.lookVector
		local pilots, atc = plot.staff.pilot or 0, plot.staff.atc or 0
		local wait = math.max(18, 50 - 6 * pilots - 4 * atc)
		if plot.hasRunway and now - gp.t0 > wait then
			gp.state, gp.t0, gp.path, gp.atPark = "departing", now, FLY.departure(plot, gp.x), false
		end
	elseif gp.state == "departing" or gp.state == "arriving" then
		local t = now - gp.t0
		FLY.place(gp, gp.path, t, dt)
		if t >= gp.path.total then
			if gp.state == "departing" then
				gp.state, gp.t0 = "away", now
				gp.root.CFrame = CFrame.new(plot.cf.p + Vector3.new(0, 5000, 0))
			else
				gp.state, gp.t0 = "parked", now
			end
		end
	elseif gp.state == "away" then
		if now - gp.t0 > 12 then
			gp.state, gp.t0, gp.path = "arriving", now, FLY.arrival(plot, gp.x)
			gp.look = nil
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
	local cf = plot.cf * U.L(-178, T.lift + 0.4, 525, -90)
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
