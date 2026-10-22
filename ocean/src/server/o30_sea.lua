------------------------------------------------------------------ damage: pieces break off, at 0 the boat sinks and the lifeboats drop
local function breakOff(n)
	if not ship then return end
	for _ = 1, n do
		if #ship.breakable == 0 then return end
		local p = table.remove(ship.breakable, math.random(1, #ship.breakable))
		pcall(function()
			for _, w in ipairs(ship.root:GetChildren()) do
				if w:IsA("Weld") and w.Part1 == p then w:Destroy() end
			end
			p.CFrame = shipMoved() * p.CFrame
			p.Parent = workspace
			p.Anchored = false
			p.CanCollide = true
			p.Velocity = V(math.random(-20, 20), 30, math.random(-20, 20))
			Debris:AddItem(p, 15)
		end)
	end
end
local function damageShip(n)
	if not ship or ship.sinking then return end
	ship.hp = ship.hp - n
	ship.lostSince = (ship.lostSince or 0) + n
	while ship.lostSince > ship.max * 0.05 do   -- a piece breaks off for every 5% of its health
		ship.lostSince = ship.lostSince - ship.max * 0.05
		breakOff(1)
	end
	if ship.hp <= 0 then
		ship.hp = 0
		ship.sinking = tick()
		for _, g in ipairs(ship.guards or {}) do pcall(function() g.CanCollide = false end) end
		toAll("big", "THE " .. string.upper(ship.kind) .. " IS SINKING!", "Get to a lifeboat - the water hurts!")
		for _, lb in ipairs(ship.lifeboats) do
			pcall(function()
				for _, w in ipairs(ship.root:GetChildren()) do
					if w:IsA("Weld") and w.Part1 and w.Part1:IsDescendantOf(lb.model) then w:Destroy() end
				end
				lb.model.Parent = WORLD
				local hull = lb.model:FindFirstChild("LifeboatHull")
				for _, p in ipairs(lb.model:GetChildren()) do p.Anchored = true end
				lb.cf = CFrame.new(SHIP_AT + V(lb.side * (ship.wid / 2 + 14), 0, lb.z))
				lb.rel = {}
				for _, p in ipairs(lb.model:GetChildren()) do lb.rel[p] = hull.CFrame:inverse() * p.CFrame end
				lb.hull = hull
			end)
		end
	end
end

------------------------------------------------------------------ every frame: the boat rides the swells (or flies in a tornado, or sinks)
-- Each swell lifts the bow, then the middle, then the stern: the boat heaves with the water under its middle, pitches
-- with the difference between bow and stern and rolls with the difference between its sides. It has some weight, so
-- it follows the water a little behind (smooth), and big waves slam it (damage, screen shake, water over the deck).
local function follow(cur, target, rate, dt) return cur + (target - cur) * math.min(1, rate * dt) end
local function stepShip(dt, now)
	if not ship or not ship.model.Parent then return end
	local s = ship
	local t = seaTime()
	s.yaw = s.yaw or 0
	s.air = s.air or 0
	if s.sinking then
		s.sinkAt = s.sinkAt or t
		if seaShipSink.Value ~= s.sinkAt then seaShipSink.Value = s.sinkAt end
		s.dy, s.pitch, s.roll = ShipPose(t, SEA, s.len, s.wid, s.sinkAt)
	else
		-- the tornado: while it's over the boat, the boat is lifted and spun; then it drops back into the sea
		if s.twister and now - s.twister < 0.5 then
			s.air = math.min(55, s.air + 10 * dt)
			s.yaw = s.yaw + 0.9 * dt
			s.wasUp = math.max(s.wasUp or 0, s.air)
		elseif s.air > 0 then
			s.air = math.max(0, s.air - 30 * dt)
			if s.air == 0 and (s.wasUp or 0) > 12 then
				damageShip(s.max * 0.003 * s.wasUp)
				toAll("shake", 1)
				toAll("big", "SPLASH!", "The tornado dropped the boat!")
				s.wasUp = 0
			end
		end
		local dy, pitch, roll = ShipPose(t, SEA, s.len, s.wid)
		if s.air > 0.1 then      -- swinging about in the tornado (players' computers do the same)
			local k = math.min(1, s.air / 10)
			pitch, roll = pitch + math.sin(t * 2) * 0.15 * k, roll + math.sin(t * 2.6) * 0.2 * k
		end
		s.dy, s.pitch, s.roll = dy + s.air, pitch, roll
		-- big waves hurt: while a set of big waves rolls through, the bow slams into them
		if SEA.rogueA > 0 then
			local c = SEA.rogueZ + 30 * (t - SEA.rogueT)    -- along the waves' direction; the boat is at 0
			local e = -c / SEA.rogueLen
			local hit = math.exp(-e * e)
			if hit > 0.3 then
				damageShip(SEA.rogueA * (SEA.rogueBump and 0.4 or 0.3) * hit * dt)
				if not s.slammed or now - s.slammed > 2.5 then
					s.slammed = now
					toAll("shake", 0.5 + SEA.rogueA / 30)
				end
			end
			if c > SEA.rogueLen * 3 then calmRogue() end
		end
	end
	if s.air <= 0 then s.yaw = s.yaw * (1 - 0.15 * dt) end
	if not s.sent or now - s.sent > 0.05 then      -- the extras, 20 times a second (players' computers smooth them)
		s.sent = now
		if math.abs(seaShipAir.Value - s.air) > 0.05 then seaShipAir.Value = s.air end
		if math.abs(seaShipYaw.Value - s.yaw) > 0.002 then seaShipYaw.Value = s.yaw end
	end
	for _, lb in ipairs(s.lifeboats) do
		if lb.hull and lb.model.Parent then
			local p = lb.cf.p
			local h = waveAt(p.X, p.Z, t)
			local tilt = math.atan((waveAt(p.X, p.Z - 8, t) - waveAt(p.X, p.Z + 8, t)) / 16)
			local cf = CFrame.new(p.X, SEA.level + 1.2 + h, p.Z) * CFrame.Angles(tilt, 0, 0)
			for part, rel in pairs(lb.rel) do if part.Parent then part.CFrame = cf * rel end end
		end
	end
end
local function onShip(pos)
	if not ship then return false end
	local l = shipFrame():inverse() * pos
	return math.abs(l.X) < ship.wid / 2 + 2 and l.Z > -ship.len / 2 - 45 and l.Z < ship.len / 2 + 2 and l.Y > 0 and l.Y < 90
end

------------------------------------------------------------------ the water: you float, but it hurts (it's freezing)
local swimmers = {}
local washed = {}
local WATER_DPS = 7
local STATE = { phase = "intermission", left = 0, disaster = "" }
local function toLobby(p)
	local t = torsoOf(p.Character)
	if t then t.CFrame = CFrame.new(LOBBY_AT + V(math.random(-12, 12), 6, 20 + math.random(-6, 6))) end
end
local function stepSwimmers(dt)
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local t = torsoOf(c)
		local h = c and c:FindFirstChild("Humanoid")
		local bp = swimmers[p]
		local inWater = t and h and h.Health > 0 and not h.Sit and t.Position.Y < SEA.level + 1.5 + (ship and onShip(t.Position) and -100 or waveAt(t.Position.X, t.Position.Z))
		if STATE.phase == "intermission" and t and h and h.Health > 0 and t.Position.Y < LOBBY_AT.Y - 120 then inWater = true end
		if inWater and STATE.phase == "intermission" then   -- fell off the sky lobby: back up you go
			toLobby(p)
			inWater = false
		end
		if inWater then
			if not bp or bp.Parent ~= t then
				bp = Instance.new("BodyPosition")
				bp.Name = "Swim"
				bp.maxForce = V(0, 4e4, 0)
				bp.Parent = t
				swimmers[p] = bp
				h.WalkSpeed = 12
			end
			bp.position = V(0, SEA.level - 0.6 + waveAt(t.Position.X, t.Position.Z), 0)
			h:TakeDamage(WATER_DPS * dt)
		elseif bp and (not t or t.Position.Y > SEA.level + 2.5 or not h or h.Health <= 0 or h.Sit) then
			pcall(function() bp:Destroy() end)
			swimmers[p] = nil
			if h then h.WalkSpeed = 16 end
		end
		if t and t.Position.Y < -50 and h then h.Health = 0 end
	end
end
