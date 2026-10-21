-- ==== s24_lifts.lua
------------------------------------------------------------------ floors with holes, and elevators that really move
-- a slab whose top is at y0, over x0..x1 / z0..z1, with rectangular holes { x0, x1, z0, z1 } left open (for shafts)
function U.slab(b, name, x0, x1, z0, z1, y0, thick, holes, color, mat)
	local xs = { x0, x1 }
	for _, h in ipairs(holes) do
		if h[1] > x0 and h[1] < x1 then table.insert(xs, h[1]) end
		if h[2] > x0 and h[2] < x1 then table.insert(xs, h[2]) end
	end
	table.sort(xs)
	for i = 1, #xs - 1 do
		local a, c = xs[i], xs[i + 1]
		if c - a > 0.05 then
			local cuts = {}
			for _, h in ipairs(holes) do
				if h[1] < c - 0.05 and h[2] > a + 0.05 then table.insert(cuts, { h[3], h[4] }) end
			end
			table.sort(cuts, function(p, q) return p[1] < q[1] end)
			local z = z0
			for _, ct in ipairs(cuts) do
				if ct[1] - z > 0.05 then U.blk(b, name, c - a, thick, ct[1] - z, (a + c) / 2, y0 - thick, (z + ct[1]) / 2, color, mat) end
				z = math.max(z, ct[2])
			end
			if z1 - z > 0.05 then U.blk(b, name, c - a, thick, z1 - z, (a + c) / 2, y0 - thick, (z + z1) / 2, color, mat) end
		end
	end
end

-- An elevator: a car that slides up and down a glass shaft, sliding doors on every floor, a CALL pad and button
-- outside each door and floor buttons (plus UP/DOWN pads) inside the car. Passengers and guests wait for it,
-- step in and ride it too. Levels are floor tops; keys[i] = the item that must be bought before level i opens.
local LIFT = { speed = 9, openTime = 3, maxOpen = 9 }
G.lifts = {}
local FACE = { ["+x"] = -90, ["-x"] = 90, ["+z"] = 180, ["-z"] = 0 }   -- turns local -z towards the open side
local OUT = { ["+x"] = { 1, 0 }, ["-x"] = { -1, 0 }, ["+z"] = { 0, 1 }, ["-z"] = { 0, -1 } }

-- glass walls of one shaft segment (the open side gets doors from U.liftDoor)
function U.shaft(b, x, z, y0, h, open, color)
	local walls = { ["+x"] = { 4, 0, 0.4, 8 }, ["-x"] = { -4, 0, 0.4, 8 }, ["+z"] = { 0, 4, 8, 0.4 }, ["-z"] = { 0, -4, 8, 0.4 } }
	for side, w in pairs(walls) do
		if side ~= open then U.blk(b, "ShaftGlass", w[3], h, w[4], x + w[1], y0, z + w[2], "Pastel light blue", "Glass", { tr = 0.55 }) end
	end
	for _, c in ipairs({ { -4.3, -4.3 }, { 4.3, -4.3 }, { -4.3, 4.3 }, { 4.3, 4.3 } }) do
		U.blk(b, "ShaftPost", 0.6, h, 0.6, x + c[1], y0, z + c[2], color or "Institutional white", "Metal")
	end
end

local function touchedPlayer(hit)
	return hit and hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
end
local function clicker(part, fn)
	local cd = Instance.new("ClickDetector")
	pcall(function() cd.MaxActivationDistance = 20 end)
	cd.Parent = part
	cd.MouseClick:connect(fn)
end

function LIFT.place(L)
	local at = L.plot.cf * CFrame.new(L.x, L.y + 0.05, L.z)
	for _, p in ipairs(L.parts) do p.part.CFrame = at * p.rel end
end
-- Players riding a moving car: a car moved by CFrame doesn't carry people (they bounce on the way up and fall on
-- the way down, which looks like glitching). So while it moves, the floor gets the car's speed and every player
-- standing in the car gets a BodyVelocity that moves them up/down with it (it also pulls them back onto the floor
-- if they drift). v = vertical speed, nil when the car is stopped: then everything is removed.
function LIFT.carry(L, v)
	L.riders = L.riders or {}
	local floor = L.parts[1] and L.parts[1].part
	if floor and L.floorV ~= (v or 0) then
		L.floorV = v or 0
		pcall(function() floor.Velocity = Vector3.new(0, L.floorV, 0) end)
	end
	local seen = {}
	if v then
		local c = L.plot.cf * Vector3.new(L.x, L.y, L.z)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
			if torso then
				local p = torso.Position
				local dy = p.Y - c.Y
				if dy > -1 and dy < 9 and Vector3.new(p.X - c.X, 0, p.Z - c.Z).magnitude < 4.3 then
					seen[player] = true
					local bv = L.riders[player]
					if not bv or bv.Parent ~= torso then
						bv = Instance.new("BodyVelocity")
						bv.Name = "ElevatorRide"
						bv.maxForce = Vector3.new(0, 4e5, 0)
						bv.Parent = torso
						L.riders[player] = bv
					end
					bv.velocity = Vector3.new(0, v + (3 - dy) * 4, 0)
				end
			end
		end
	end
	for player, bv in pairs(L.riders) do
		if not seen[player] then
			pcall(function() bv:Destroy() end)
			L.riders[player] = nil
		end
	end
end

-- make the car (called by the item that builds the bottom of the shaft)
function U.lift(b, id, x, z, levels, keys, open, names)
	local plot = b.plot
	local L = { plot = plot, id = id, x = x, z = z, levels = levels, keys = keys, open = open, names = names,
		ox = OUT[open][1], oz = OUT[open][2], y = levels[1], idx = 1, queue = {}, state = "idle", timer = 0, openFor = 0,
		doors = {}, boarding = {}, parts = {}, wait = 0 }
	local cab = Instance.new("Model")
	cab.Name = "Elevator Car"
	local cb = { model = cab, cf = CFrame.Angles(0, math.rad(FACE[open]), 0), plot = plot }
	-- in the car's frame: floor top at y 0, the doors at -z, the back wall at +z
	U.P(cb, "CarFloor", Vector3.new(7.4, 0.6, 7.4), U.L(0, -0.3, 0), "Dark stone grey", "DiamondPlate")
	U.P(cb, "CarCeiling", Vector3.new(7.4, 0.4, 7.4), U.L(0, 9.8, 0), plot.color, "SmoothPlastic", { nc = true })
	U.light(U.P(cb, "CarLight", Vector3.new(3, 0.1, 3), U.L(0, 9.55, 0), "Institutional white", "Neon", { nc = true }), Color3.new(1, 0.97, 0.9), 12, 1)
	U.P(cb, "CarBack", Vector3.new(7.2, 9.6, 0.2), U.L(0, 4.8, 3.55), "Institutional white", "SmoothPlastic", { nc = true })
	for _, sx in ipairs({ -3.55, 3.55 }) do
		U.P(cb, "CarSide", Vector3.new(0.2, 9.6, 7.2), U.L(sx, 4.8, 0), "Pastel light blue", "Glass", { tr = 0.5, nc = true })
		U.P(cb, "Handrail", Vector3.new(0.3, 0.3, 6), U.L(sx * 0.9, 3.4, 0.4), "Gold", "Metal", { nc = true })
	end
	-- floor buttons on the back wall (click them)
	local n = #levels
	for i = 1, n do
		local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
		local btn = U.P(cb, "Button", Vector3.new(0.9, 0.9, 0.2), U.L(1.6 + col * 1.1, 6 - row * 1.1, 3.4), "Really black", "SmoothPlastic", { nc = true })
		U.text(btn, names[i], Color3.new(1, 0.85, 0.3), nil, "Front")
		clicker(btn, function(player) LIFT.call(L, i, player) end)
	end
	local panel = U.P(cb, "ButtonSign", Vector3.new(2.6, 0.6, 0.2), U.L(2.15, 7, 3.4), "Really black", "SmoothPlastic", { nc = true })
	U.text(panel, "CLICK A FLOOR", Color3.new(1, 1, 1), nil, "Front")
	-- or stand on UP / DOWN
	local function pad(text, color, px, dir)
		local p = U.P(cb, "Pad" .. text, Vector3.new(2.6, 0.1, 2.6), U.L(px, 0.05, 1.8), color, "Neon", { nc = true })
		U.text(p, text, Color3.new(1, 1, 1), nil, "Top")
		local busy = {}
		p.Touched:connect(function(hit)
			local player = touchedPlayer(hit)
			if not player or busy[player] or L.state ~= "open" then return end
			busy[player] = true
			LIFT.call(L, L.idx + dir, player)
			wait(3)
			busy[player] = nil
		end)
	end
	pad("UP", "Lime green", -1.8, 1)
	pad("DOWN", "Really red", 1.8, -1)
	-- the whole car is one rig (everything welded to the floor), so moving it is one CFrame a frame, not 16
	local floor = cab:FindFirstChild("CarFloor")
	U.rig(cab, floor, true)
	table.insert(L.parts, { part = floor, rel = floor.CFrame })
	cab.Parent = b.model
	L.cab = cab
	LIFT.place(L)
	plot.lifts = plot.lifts or {}
	plot.lifts[id] = L
	table.insert(G.lifts, L)
	return L
end

-- the doors, CALL pad and CALL button of level i (called by the item that builds that floor)
function U.liftDoor(b, id, i)
	local L = b.plot.lifts and b.plot.lifts[id]
	if not L then return end
	local y = L.levels[i]
	local frame = b.plot.cf * CFrame.new(L.x + L.ox * 4, y, L.z + L.oz * 4) * CFrame.Angles(0, math.rad(FACE[L.open]), 0)
	local fb = { model = b.model, cf = frame, plot = b.plot }
	local d = { t = 0, leaves = {} }
	for _, sx in ipairs({ -1, 1 }) do
		local leaf = U.P(fb, "LiftDoor", Vector3.new(3.8, 9.6, 0.3), U.L(sx * 1.9, 4.8, 0), "Light stone grey", "Metal", { tr = 0.15 })
		local win = U.P(fb, "DoorWindow", Vector3.new(1.2, 5, 0.35), U.L(sx * 1.9, 5, 0), "Pastel light blue", "Glass", { tr = 0.4, nc = true })
		table.insert(d.leaves, { part = leaf, base = leaf.CFrame, dir = sx, win = win, winBase = win.CFrame })
	end
	U.P(fb, "DoorHeader", Vector3.new(8.6, 1, 0.6), U.L(0, 10.1, 0), b.plot.color, "SmoothPlastic")
	local sign = U.P(fb, "FloorNumber", Vector3.new(2, 0.9, 0.2), U.L(0, 10.1, -0.4), "Really black", "SmoothPlastic", { nc = true })
	U.text(sign, L.names[i], Color3.new(1, 0.85, 0.3), nil, "Front")
	local callPad = U.P(fb, "CallPad", Vector3.new(4, 0.2, 3), U.L(0, 0.1, -3.4), "Lime green", "Neon", { nc = true })
	U.bill(callPad, "ELEVATOR\nstep here to call", 6, 1.6, 3, Color3.new(0.7, 1, 0.7))
	local busy = {}
	callPad.Touched:connect(function(hit)
		local player = touchedPlayer(hit)
		if not player or busy[player] then return end
		busy[player] = true
		LIFT.call(L, i, player)
		wait(2)
		busy[player] = nil
	end)
	local btn = U.P(fb, "CallButton", Vector3.new(0.8, 1.2, 0.3), U.L(5, 4.5, -0.3), "Really black", "SmoothPlastic")
	U.text(btn, "CALL", Color3.new(0.6, 1, 0.6), nil, "Front")
	clicker(btn, function(player) LIFT.call(L, i, player) end)
	L.doors[i] = d
end

function LIFT.doorPose(d)
	for _, leaf in ipairs(d.leaves) do
		local off = CFrame.new(leaf.dir * d.t * 3.9, 0, 0)
		leaf.part.CFrame = leaf.base * off
		leaf.part.CanCollide = d.t < 0.7
		if leaf.win then leaf.win.CFrame = leaf.winBase * off end
	end
end

function LIFT.available(L, i)
	local key = L.keys[i]
	return L.levels[i] ~= nil and (not key or L.plot.bought[key]) and L.doors[i] ~= nil
end
function LIFT.call(L, i, player)
	if not L.levels[i] then return end
	if not LIFT.available(L, i) then
		if player then
			local key = L.keys[i]
			A.toast(player, "Build " .. (key and ITEM[key] and ITEM[key].name or "that floor") .. " first!", "red")
		end
		return
	end
	if L.state == "open" and L.idx == i then
		L.timer = math.max(L.timer, LIFT.openTime)
		return
	end
	if L.state == "moving" and L.target == i then return end
	for qi, q in ipairs(L.queue) do
		if q == i then
			if player and qi > 1 then table.remove(L.queue, qi) table.insert(L.queue, 1, i) end
			return
		end
	end
	-- players go to the front of the queue (the guests can wait)
	if player then table.insert(L.queue, 1, i) else table.insert(L.queue, i) end
end
-- can a walker waiting at level i get in now?
function LIFT.ready(L, i)
	if L.dead then return true end
	local d = L.doors[i]
	return L.state == "open" and L.idx == i and L.openFor < LIFT.maxOpen and (not d or d.t > 0.9)
end
function LIFT.arrived(L, i)
	if L.dead then return true end
	local d = L.doors[i]
	return L.state == "open" and L.idx == i and (not d or d.t > 0.9)
end

function LIFT.step(dt)
	local now = tick()
	for k = #G.lifts, 1, -1 do
		local L = G.lifts[k]
		if not L.cab.Parent then
			LIFT.carry(L, nil)   -- nobody keeps floating if the airport is reset mid-ride
			L.dead = true
			table.remove(G.lifts, k)
		else
			local boarding = false
			for w, t in pairs(L.boarding) do
				if not w.model.Parent or now - t > 8 then L.boarding[w] = nil else boarding = true end
			end
			if L.state == "open" then
				L.timer = L.timer - dt
				L.openFor = L.openFor + dt
				if L.timer <= 0 and (not boarding or L.openFor > LIFT.maxOpen + 4) then L.state = "idle" end
			elseif L.state == "idle" then
				local nxt = table.remove(L.queue, 1)
				if nxt then
					if nxt == L.idx then
						L.state, L.timer, L.openFor = "open", LIFT.openTime, 0
					else
						L.state, L.target, L.wait = "moving", nxt, 0.7   -- give the doors time to close
					end
				end
			elseif L.state == "moving" then
				if L.wait > 0 then
					L.wait = L.wait - dt
				else
					local goal = L.levels[L.target]
					local dir = goal > L.y and 1 or -1
					local ny = L.y + dir * LIFT.speed * dt
					-- stop on the way for anyone waiting at a floor we pass
					for qi, q in ipairs(L.queue) do
						local ly = L.levels[q]
						if (ly - L.y) * dir > 0.01 and (ly - ny) * dir <= 0 and (goal - ly) * dir > 0 then
							table.remove(L.queue, qi)
							table.insert(L.queue, 1, L.target)
							L.target, goal = q, ly
							break
						end
					end
					if (goal - ny) * dir <= 0 then
						L.y, L.idx, L.state, L.timer, L.openFor = goal, L.target, "open", LIFT.openTime, 0
						L.target = nil
					else
						L.y = ny
					end
					LIFT.place(L)
					LIFT.carry(L, L.state == "moving" and dir * LIFT.speed or nil)
				end
			end
			for i, d in pairs(L.doors) do
				local want = (L.state == "open" and L.idx == i) and 1 or 0
				if d.t ~= want then
					if want > d.t then d.t = math.min(1, d.t + dt * 2.5) else d.t = math.max(0, d.t - dt * 2.5) end
					LIFT.doorPose(d)
				end
			end
		end
	end
end

-- route points for a walker riding lift L from level a to level b. go(v, wait, act, extra) adds a point.
function LIFT.route(go, plot, L, a, b)
	local function W(x, y, z) return plot.cf * Vector3.new(x, y, z) end
	local ya, yb = L.levels[a], L.levels[b]
	local rx, rz = math.random(-15, 15) / 10, math.random(-10, 15) / 10
	go(W(L.x + L.ox * 7, ya, L.z + L.oz * 7), 0, nil, { liftWait = L, level = a })
	go(W(L.x + rx, ya, L.z + rz))
	go(W(L.x + rx, yb, L.z + rz), 0, nil, { ride = L, level = b })
	go(W(L.x + L.ox * 7, yb, L.z + L.oz * 7))
end
NPC.LIFT = LIFT
