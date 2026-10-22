-- ==== o40_disasters.lua
------------------------------------------------------------------ disasters (all of them aim at the ship)
local junk = model(WORLD, "Disaster")
local WIND = { v = V() }
local function players()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local t, h = torsoOf(c), c and c:FindFirstChild("Humanoid")
		if t and h and h.Health > 0 then table.insert(out, { p = p, t = t, h = h }) end
	end
	return out
end
local function fling(x, vel, time, flat)
	local bv = Instance.new("BodyVelocity")
	bv.maxForce = flat and V(2e4, 0, 2e4) or V(4e4, 4e4, 4e4)
	bv.velocity = vel
	bv.Parent = x.t
	Debris:AddItem(bv, time or 0.4)
end
-- how hard the game is right now: goes up every 5 disasters (o50). Disasters hit harder at higher levels.
local DIFF = { level = 1, mult = 3 }     -- mult: everything hurts 3x (the game was too easy)
local function power() return DIFF.mult * (1 + 0.25 * (DIFF.level - 1)) end
local function hurtNear(pos, radius, dmg, shipDmg)
	dmg = dmg * power()
	for _, x in ipairs(players()) do
		local d = (x.t.Position - pos).magnitude
		if d < radius then x.h:TakeDamage(dmg * (1 - 0.5 * d / radius)) end
	end
	if shipDmg and ship and (pos - ship.root.Position).magnitude < ship.len / 2 + 20 then damageShip(shipDmg) end
end
local function boom(pos, size)
	local e = Instance.new("Explosion")
	e.Position = pos
	e.BlastRadius = size
	pcall(function() e.BlastPressure = 0 end)
	pcall(function() e.DestroyJointRadiusPercent = 0 end)
	e.Parent = workspace
end
-- a random spot on (or just over) the ship
local function onDeck(spread)
	if not ship then return SHIP_AT end
	local l = V(math.random(-ship.wid / 2, ship.wid / 2), ship.deck + 1, math.random(-ship.len / 2, ship.len / 2))
	return shipFrame() * l
end
-- normal waves every round (not a disaster): big rolling swells all the time, and every so often a SET of even
-- bigger ones builds up ahead of the bow, rolls through the boat one after another and dies down again.
local function bigSets(height, gapMin, gapMax, first)
	local alive = true
	spawn(function()
		wait(first or 6)
		while alive do
			if not (SEA.rogueA > 0 and SEA.rogueBump) then     -- never wipe out a tsunami that's on its way
				toAll("toast", "Big waves ahead! Hold on!")
				rogue(height, 600, false)
			end
			wait(math.random(gapMin, gapMax))
		end
	end)
	return function() alive = false end
end
local function oceanWaves()
	SEA.calm = 40
	SEA.waves = math.max(SEA.waves, 40)
	local stopSets = bigSets(20, 35, 50, 12)
	return function() stopSets() SEA.calm = 3 SEA.waves = 3 calmRogue() end
end

local DIS = {}
DIS.Tsunami = { text = "TSUNAMI! A MASSIVE wave is coming!", run = function()
	local alive = true
	spawn(function()
		wait(3)
		if not alive then return end
		-- a MASSIVE wall of water (250 studs high, 1500 wide) rises out of the fog far away and comes for the boat
		local HEIGHT, LEN = 250, 500
		toAll("big", "LOOK AT THE HORIZON...", "A MASSIVE TSUNAMI IS COMING! Get inside and hold on!")
		rogue(HEIGHT, LEN, true, -1700)
		local a = LEN * TSU_A
		local hit = false
		while alive and SEA.rogueA > 0 do
			wait(0.25)
			local front = SEA.rogueZ + 30 * (seaTime() - SEA.rogueT) + a * 0.8      -- where its wall meets the sea
			if not hit and front >= -40 then
				hit = true
				toAll("big", "THE TSUNAMI HITS!", "")
				toAll("shake", 2.5)
				for _, x in ipairs(players()) do
					x.h:TakeDamage(25 * power())
					if not x.h.Sit then fling(x, V(math.random(-15, 15), 30, 35), 0.3) end
				end
			elseif not hit and front >= -400 and math.random() < 0.3 then
				toAll("shake", 0.4)      -- the rumble as it gets close
			end
		end
	end)
	return function() alive = false end
end }
DIS.Tornado = { text = "TORNADO! It's heading for the ship!", run = function()
	local m = model(junk, "Tornado")
	local rings = {}
	for i = 0, 11 do
		local d = 14 + i * 5
		table.insert(rings, { part = cyl(m, "Funnel", d, 10, 0, 0, 0, i % 2 == 0 and "Dark stone grey" or "Medium stone grey", "SmoothPlastic", { tr = 0.45, nc = true }), y = i * 10 + 5 })
	end
	local pos = SHIP_AT + V(math.random(-250, 250), 0, math.random() < 0.5 and -300 or 300)
	local alive = true
	spawn(function()
		while alive do
			local dt = wait(0.1)
			local now = tick()
			-- wander over the ship, back and forth
			local goal = SHIP_AT + V(math.sin(now * 0.15) * 30, 0, math.sin(now * 0.09) * 160)
			local d = V(goal.X - pos.X, 0, goal.Z - pos.Z)
			if d.magnitude > 1 then pos = pos + d.unit * 18 * dt end
			for i, r in ipairs(rings) do
				r.part.CFrame = CFrame.new(pos.X + math.sin(now * 2 + i) * i * 0.6, SEA.level + waveAt(pos.X, pos.Z) + r.y, pos.Z) * CFrame.Angles(0, now * 4 + i, math.rad(90))
			end
			if ship and (V(pos.X, 0, pos.Z) - V(SHIP_AT.X, 0, SHIP_AT.Z)).magnitude < ship.len / 3 then
				damageShip(8 * dt)
				if not ship.twister then toAll("big", "THE TORNADO HAS THE BOAT!", "Hold on - it's lifting us out of the water!") end
				ship.twister = now      -- stepShip lifts and spins it while this is fresh
			end
			for _, x in ipairs(players()) do
				local dd = V(x.t.Position.X - pos.X, 0, x.t.Position.Z - pos.Z)
				if dd.magnitude < 32 then
					x.h:TakeDamage(6 * dt * power())
					local around = dd.magnitude > 0.1 and dd.unit:Cross(V(0, 1, 0)) or V(1, 0, 0)
					fling(x, around * 55 + V(0, 40, 0) - dd.unit * 15, 0.3)
				end
			end
		end
	end)
	return function() alive = false m:Destroy() end
end }
DIS.Hurricane = { text = "HURRICANE! Wind, rain and lightning!", run = function()
	local alive = true
	pcall(function()
		Lighting.TimeOfDay = "19:30:00"
		Lighting.FogEnd = 450
		Lighting.FogColor = Color3.new(0.35, 0.38, 0.42)
		Lighting.OutdoorAmbient = Color3.new(0.35, 0.35, 0.4)
	end)
	toAll("weather", "storm")
	SEA.waves = 55
	spawn(function()
		local a = math.random() * 6
		while alive do
			wait(0.2)
			a = a + 0.02
			WIND.v = V(math.cos(a), 0, math.sin(a)) * 18
			for _, x in ipairs(players()) do
				if not x.h.Sit then fling(x, WIND.v * 0.6 + (x.h.MoveDirection or V()) * 12, 0.15, true) end
			end
			damageShip(1.2)
		end
	end)
	local stopSets = bigSets(22, 25, 35, 5)
	spawn(function()
		while alive do
			wait(math.random(8, 20) / 10)
			local at = onDeck()
			local bolt = P(junk, "Lightning", V(1.2, 300, 1.2), CFrame.new(at + V(0, 150, 0)), "Institutional white", "Neon", { nc = true })
			light(bolt, Color3.new(0.8, 0.9, 1), 60, 5)
			Debris:AddItem(bolt, 0.25)
			toAll("flash")
			hurtNear(at, 8, 25, 25)
		end
	end)
	return function()
		alive = false
		stopSets()
		WIND.v = V()
		SEA.waves = SEA.calm or 3
		if theme ~= "Normal" then toAll("weather", "clear") end
		applyLighting()
	end
end }
DIS["Meteor Shower"] = { text = "METEOR SHOWER! Watch the sky and keep moving!", run = function()
	local alive = true
	spawn(function()
		while alive do
			wait(0.6)
			local at = math.random() < 0.6 and onDeck() or (function() local x, z = SHIP_AT.X + math.random(-150, 150), SHIP_AT.Z + math.random(-200, 200) return V(x, SEA.level + waveAt(x, z), z) end)()
			local m = P(junk, "Meteor", V(6, 6, 6), CFrame.new(at.X + 60, 420, at.Z), "Black", "Slate", { shape = "ball", nc = true })
			local f = Instance.new("Fire")
			f.Size = 12
			f.Heat = 20
			f.Parent = m
			light(m, Color3.new(1, 0.5, 0.1), 30, 3)
			spawn(function()
				local y, x = 420, at.X + 60
				while y > at.Y and m.Parent do
					local dt = wait(0.03)
					y = y - 160 * dt
					x = x - 23 * dt
					m.CFrame = CFrame.new(x, y, at.Z)
				end
				if m.Parent then
					m:Destroy()
					boom(V(x, at.Y, at.Z), 10)
					hurtNear(V(x, at.Y, at.Z), 12, 25, 18)
				end
			end)
		end
	end)
	return function() alive = false end
end }
DIS.Kraken = { text = "THE KRAKEN! Giant tentacles are smashing the ship!", run = function()
	local alive = true
	local m = model(junk, "Kraken")
	spawn(function()
		wait(3)
		while alive do
			-- a tentacle rises out of the sea next to the ship, then slams down across the deck
			local side = math.random() < 0.5 and 1 or -1
			local z = math.random(-60, 60)
			local baseAt = SHIP_AT + V(side * ((ship and ship.wid or 30) / 2 + 12), SEA.level - 4 + (ship and ship.dy or 0), z)
			local segs = {}
			for i = 1, 8 do
				local s = P(m, "Tentacle", V(5 - i * 0.4, 6, 5 - i * 0.4), CFrame.new(baseAt), i % 2 == 0 and "Bright violet" or "Royal purple", "SmoothPlastic", { nc = true })
				table.insert(segs, s)
			end
			for t = 0, 1, 0.05 do      -- rise
				for i, s in ipairs(segs) do s.CFrame = CFrame.new(baseAt + V(0, i * 5 * t, 0)) end
				wait(0.05)
			end
			wait(0.6)
			for t = 0, 1, 0.1 do       -- slam across the deck
				local a = t * math.pi / 2
				for i, s in ipairs(segs) do s.CFrame = CFrame.new(baseAt + V(-side * math.sin(a) * i * 5, math.cos(a) * i * 5 + 2, 0)) end
				wait(0.03)
			end
			local hitAt = baseAt + V(-side * 25, (ship and ship.deck or 10) + 2 - (SEA.level - 4), 0)
			hurtNear(hitAt, 16, 40, 45)
			toAll("shake", 0.4)
			wait(1)
			for _, s in ipairs(segs) do s:Destroy() end
			wait(math.random(3, 6))
		end
	end)
	return function() alive = false m:Destroy() end
end }
DIS["Shark Attack"] = { text = "SHARK ATTACK! Don't fall in the water!", run = function()
	local sharks = {}
	for i = 1, 8 do
		local m = model(junk, "Shark")
		local at = SHIP_AT + V(math.random(-120, 120), SEA.level - 1.2, math.random(-160, 160))
		local body = P(m, "Body", V(3, 2.5, 12), CFrame.new(at), "Medium stone grey", "SmoothPlastic")
		local fin = P(m, "Fin", V(0.4, 3.5, 3), CFrame.new(at + V(0, 2.5, 0)), "Dark stone grey", "SmoothPlastic", { class = "WedgePart" })
		weld(body, fin)
		fin.Anchored = false
		table.insert(sharks, { m = m, root = body, pos = at, look = V(0, 0, -1), next = 0 })
	end
	local alive = true
	SEA.waves = 45       -- rough sea: the waves wash people off the deck... into the sharks
	local stopSets = bigSets(20, 25, 35, 6)
	spawn(function()
		while alive do
			local dt = wait(0.05)
			local now = tick()
			for _, s in ipairs(sharks) do
				local best, bd
				for _, x in ipairs(players()) do
					if swimmers[x.p] then
						local d = (x.t.Position - s.pos).magnitude
						if not bd or d < bd then best, bd = x.t.Position, d end
					end
				end
				-- no one in the water: circle the ship
				local goal = best or (SHIP_AT + V(math.cos(now * 0.2 + s.pos.Z) * 60, 0, math.sin(now * 0.2 + s.pos.X) * 140))
				local d = V(goal.X - s.pos.X, 0, goal.Z - s.pos.Z)
				if d.magnitude > 0.5 then s.look = (s.look * 0.9 + d.unit * 0.1).unit end
				s.pos = V(s.pos.X, SEA.level - 1.2 + waveAt(s.pos.X, s.pos.Z), s.pos.Z) + s.look * (best and 22 or 12) * dt
				s.root.CFrame = CFrame.new(s.pos, s.pos + s.look)
				if best and bd < 6 and now > s.next then
					s.next = now + 1.5
					hurtNear(s.pos, 7, 25)
				end
			end
		end
	end)
	return function() alive = false stopSets() SEA.waves = SEA.calm or 3 for _, s in ipairs(sharks) do s.m:Destroy() end end
end }
DIS.Hailstorm = { text = "HAILSTORM! Giant hailstones are falling - keep moving!", run = function()
	local alive = true
	toAll("weather", "hail")
	pcall(function() Lighting.FogEnd = 700 Lighting.FogColor = Color3.new(0.6, 0.65, 0.7) end)
	spawn(function()
		while alive do
			wait(0.12)
			local huge = math.random() < 0.15
			local at = onDeck()
			local size = huge and 5 or 1.6
			local m = P(junk, "Hail", V(size, size, size), CFrame.new(at + V(0, 160, 0)), "Pastel light blue", "Ice", { shape = "ball", nc = true })
			spawn(function()
				local y = at.Y + 160
				while y > at.Y and m.Parent do
					local dt = wait(0.03)
					y = y - 150 * dt
					m.CFrame = CFrame.new(at.X, y, at.Z)
				end
				if m.Parent then
					m:Destroy()
					hurtNear(at, huge and 8 or 4, huge and 20 or 6, huge and 6 or 1)
				end
			end)
		end
	end)
	return function()
		alive = false
		toAll("weather", theme == "Normal" and "storm" or "clear")
		applyLighting()
	end
end }
DIS.Whirlpool = { text = "WHIRLPOOL! The sea is spinning the ship and pulling it down!", run = function()
	local alive = true
	local m = model(junk, "Whirlpool")
	local rings, bars = {}, {}
	for i = 1, 7 do
		table.insert(rings, { part = cyl(m, "Swirl", 40 + i * 30, 1, 0, 0, 0, i % 2 == 0 and "Institutional white" or "Navy blue", "SmoothPlastic", { tr = 0.5, nc = true }), i = i })
	end
	for i = 1, 10 do
		table.insert(bars, { part = P(m, "Foam", V(3, 0.6, 40), CFrame.new(), "Institutional white", "SmoothPlastic", { nc = true, tr = 0.2 }), r = 30 + i * 18, a = i * 0.9 })
	end
	spawn(function()
		while alive do
			local dt = wait(0.1)
			local now = tick()
			local c = SHIP_AT
			local water = SEA.level + (ship and ship.dy or 0)
			for _, r in ipairs(rings) do
				r.part.CFrame = CFrame.new(c.X, water - 2 - (8 - r.i) * 3, c.Z) * CFrame.Angles(0, now, math.rad(90))
			end
			for _, b in ipairs(bars) do
				b.a = b.a + dt * (1.6 - b.r / 300)
				b.part.CFrame = CFrame.new(c.X + math.cos(b.a) * b.r, water - 1 - (220 - b.r) / 30, c.Z + math.sin(b.a) * b.r) * CFrame.Angles(0, -b.a, 0)
			end
			if ship then
				ship.whirl = now          -- stepShip spins the boat and drags it down while this is fresh
				damageShip(5 * dt)
			end
			for _, x in ipairs(players()) do
				if swimmers[x.p] then     -- swimmers get sucked round and round
					local dd = V(SHIP_AT.X - x.t.Position.X, 0, SHIP_AT.Z - x.t.Position.Z)
					if dd.magnitude > 1 then fling(x, dd.unit:Cross(V(0, 1, 0)) * 30 + dd.unit * 15, 0.15, true) end
					x.h:TakeDamage(4 * dt * power())
				end
			end
		end
	end)
	return function() alive = false m:Destroy() end
end }
DIS.Iceberg = { text = "ICEBERG AHEAD! Brace for impact!", run = function()
	local alive = true
	local m = model(junk, "Iceberg")
	local bits = {
		{ P(m, "Ice", V(70, 60, 80), CFrame.new(), "Institutional white", "Ice", { nc = true }), CFrame.new(0, 10, 0) * CFrame.Angles(0.2, 0.3, 0.1) },
		{ P(m, "Ice", V(50, 45, 50), CFrame.new(), "Pastel light blue", "Ice", { nc = true }), CFrame.new(20, 40, -10) * CFrame.Angles(0.5, 0.1, 0.3) },
		{ P(m, "Ice", V(40, 30, 40), CFrame.new(), "Institutional white", "Ice", { nc = true }), CFrame.new(-25, 30, 15) * CFrame.Angles(0.1, 0.7, 0.4) },
		{ P(m, "Ice", V(90, 20, 100), CFrame.new(), "Pastel light blue", "Ice", { nc = true }), CFrame.new(0, -15, 0) * CFrame.Angles(0, 0.2, 0) },
	}
	spawn(function()
		local z, x, hit = -900, 0, false
		while alive and z < 800 do
			local dt = wait(0.1)
			z = z + (hit and 15 or 45) * dt
			if hit then x = math.min((ship and ship.wid or 30) / 2 + 50, x + 10 * dt) end
			local px, pz = SHIP_AT.X + x, SHIP_AT.Z + z
			local cf = CFrame.new(px, SEA.level + waveAt(px, pz), pz)
			for _, b in ipairs(bits) do b[1].CFrame = cf * b[2] end
			if not hit and ship and z + 45 >= -ship.len / 2 then
				hit = true
				toAll("big", "CRASH!", "The iceberg ripped open the hull!")
				toAll("shake", 1.5)
				damageShip(ship.max * 0.25)
				for _, p in ipairs(players()) do if onShip(p.t.Position) and not p.h.Sit then fling(p, V(math.random(-10, 10), 15, -45), 0.3) end end
			end
		end
	end)
	return function() alive = false m:Destroy() end
end }
DIS["Ghost Ship"] = { text = "GHOST SHIP! Phantom pirates are firing cannons at us!", run = function()
	local alive = true
	local m = model(junk, "GhostShip")
	local hull = P(m, "GhostHull", V(26, 14, 110), CFrame.new(), "Really black", "SmoothPlastic", { nc = true, tr = 0.3 })
	local mast = P(m, "Mast", V(2, 60, 2), CFrame.new(), "Really black", "Wood", { nc = true, tr = 0.3 })
	local sail = P(m, "Sail", V(30, 26, 1), CFrame.new(), "Lime green", "Neon", { nc = true, tr = 0.5 })
	light(sail, Color3.new(0.3, 1, 0.4), 60, 3)
	local a = math.random() * 6.3
	spawn(function()
		local lastShot = tick()
		while alive do
			local dt = wait(0.1)
			local now = tick()
			a = a + dt * 0.09
			local px, pz = SHIP_AT.X + math.cos(a) * 230, SHIP_AT.Z + math.sin(a) * 230
			local water = SEA.level + waveAt(px, pz)
			local cf = CFrame.new(V(px, water + 4, pz), V(px - math.sin(a), water + 4, pz + math.cos(a)))
			hull.CFrame = cf
			mast.CFrame = cf * CFrame.new(0, 35, 0)
			sail.CFrame = cf * CFrame.new(0, 40, 0) * CFrame.Angles(0, math.pi / 2, 0)
			if now - lastShot > 1.4 then
				lastShot = now
				local from, to = cf.p + V(0, 6, 0), onDeck()
				local ball = P(junk, "Cannonball", V(3, 3, 3), CFrame.new(from), "Really black", "SmoothPlastic", { shape = "ball", nc = true })
				local f = Instance.new("Fire")
				f.Size = 5
				pcall(function() f.Color = Color3.new(0.3, 1, 0.4) end)
				f.Parent = ball
				spawn(function()
					for k = 0, 1, 0.05 do
						if not ball.Parent then return end
						ball.CFrame = CFrame.new(from + (to - from) * k + V(0, math.sin(k * math.pi) * 40, 0))
						wait(0.05)
					end
					if ball.Parent then
						ball:Destroy()
						boom(to, 8)
						hurtNear(to, 10, 25, 30)
					end
				end)
			end
		end
	end)
	return function() alive = false m:Destroy() end
end }
local ORDER = { "Tsunami", "Tornado", "Hurricane", "Meteor Shower", "Kraken", "Shark Attack", "Hailstorm", "Whirlpool", "Iceberg", "Ghost Ship" }

