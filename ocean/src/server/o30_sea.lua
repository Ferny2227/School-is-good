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
			p.Parent = workspace
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

------------------------------------------------------------------ every frame: the boat rides the swells (or sinks), lifeboats bob
local function stepShip(dt, now)
	if not ship or not ship.model.Parent then return end
	local s = ship
	if s.sinking then
		local t = now - s.sinking
		s.dy = -t * 0.9
		s.pitch = math.min(0.35, t * 0.012)
		s.roll = s.roll * 0.98 + 0.002
	else
		-- heave with the water under the middle, roll with the slope across it, pitch with the slope along it
		local x, z = SHIP_AT.X, SHIP_AT.Z
		local h = waveAt(x, z, now)
		local across = (waveAt(x + s.wid / 2, z, now) - waveAt(x - s.wid / 2, z, now)) / s.wid
		local along = (waveAt(x, z - 45, now) - waveAt(x, z + 45, now)) / 90
		s.dy = h * 0.7 + (s.lift or 0)
		s.lift = (s.lift or 0) * (1 - dt)
		s.pitch = math.atan(along) * 1.4 + (s.kick or 0)
		s.kick = (s.kick or 0) * (1 - 1.5 * dt)
		s.roll = -math.atan(across) * 2.2 + math.sin(now * 0.5) * 0.012 * SEA.amp
	end
	s.root.CFrame = shipBase(s.dy, s.pitch, s.roll) * CFrame.new(0, s.hullY, 0)
	for _, lb in ipairs(s.lifeboats) do
		if lb.hull and lb.model.Parent then
			local cf = lb.cf + V(0, SEA.level + 1.2 + waveAt(lb.cf.p.X, lb.cf.p.Z, now) * 0.6, 0)
			for p, rel in pairs(lb.rel) do if p.Parent then p.CFrame = cf * rel end end
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
		local inWater = t and h and h.Health > 0 and not h.Sit and t.Position.Y < SEA.level + 1.5
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
			bp.position = V(0, SEA.level - 0.6 + waveAt(t.Position.X, t.Position.Z, tick()) * 0.5, 0)
			h:TakeDamage(WATER_DPS * dt)
		elseif bp and (not t or t.Position.Y > SEA.level + 2.5 or not h or h.Health <= 0 or h.Sit) then
			pcall(function() bp:Destroy() end)
			swimmers[p] = nil
			if h then h.WalkSpeed = 16 end
		end
		if t and t.Position.Y < -50 and h then h.Health = 0 end
	end
end
