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
local function hurtNear(pos, radius, dmg, shipDmg)
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
-- a wave that rolls across the boat from one side: a sloped ridge of water with a white foaming crest. When it
-- reaches the boat: damage, a big lurch, and people on the open deck get washed about.
local function waveWall(height, shipDmg, dmg, fromSide)
	local m = model(junk, "Wave")
	local dir = fromSide or (math.random() < 0.5 and 1 or -1)
	local x = dir * 400
	local depth = height * 2.2
	local front = P(m, "WaveFront", V(600, height, depth * 0.35), CFrame.new(), theme == "Halloween" and "Teal" or "Bright blue", "SmoothPlastic", { class = "WedgePart", tr = 0.25, nc = true })
	local back = P(m, "WaveBack", V(600, height, depth * 0.65), CFrame.new(), theme == "Halloween" and "Teal" or "Steel blue", "SmoothPlastic", { class = "WedgePart", tr = 0.25, nc = true })
	local crest = P(m, "Crest", V(600, height * 0.18, height * 0.3), CFrame.new(), "Institutional white", "SmoothPlastic", { tr = 0.15, nc = true })
	local spray = P(m, "Spray", V(600, height * 0.12, height * 0.45), CFrame.new(), "Institutional white", "SmoothPlastic", { tr = 0.55, nc = true })
	local function place()
		-- the wave travels along -dir in x; its steep face leads
		local base = CFrame.new(SHIP_AT.X + x, SEA.level - 2 + height / 2, SHIP_AT.Z) * CFrame.Angles(0, dir > 0 and math.rad(90) or math.rad(-90), 0)
		front.CFrame = base * CFrame.new(0, 0, -depth * 0.175) * CFrame.Angles(0, math.pi, 0)
		back.CFrame = base * CFrame.new(0, 0, depth * 0.325)
		crest.CFrame = base * CFrame.new(0, height / 2, -depth * 0.02)
		spray.CFrame = base * CFrame.new(0, height / 2 + height * 0.12, -depth * 0.12)
	end
	place()
	local hitShip, hit = false, {}
	spawn(function()
		while m.Parent and x * dir > -420 do
			local dt = wait(0.05)
			x = x - dir * 70 * dt
			place()
			if not hitShip and ship and math.abs(x) < ship.wid / 2 + 20 then
				hitShip = true
				damageShip(shipDmg)
				ship.lift = height * 0.25
				ship.kick = 0.04 * dir
				toAll("shake", 0.6)
			end
			for _, p in ipairs(players()) do
				if not hit[p.p] and math.abs(p.t.Position.X - (SHIP_AT.X + x)) < 25 and math.abs(p.t.Position.Z - SHIP_AT.Z) < 300 and p.t.Position.Y < SEA.level + height - 2 then
					hit[p.p] = true
					p.h:TakeDamage(dmg)
					if not p.h.Sit then fling(p, V(-dir * 45, 20, 0), 0.25) end
				end
			end
		end
		m:Destroy()
	end)
end
-- normal waves in every round (not a disaster): the open ocean keeps rolling into the boat
local function oceanWaves()
	local alive = true
	SEA.calm = 3
	SEA.waves = math.max(SEA.waves, 3)
	spawn(function()
		wait(4)
		while alive do
			waveWall(math.random(12, 20), 35, 4)
			wait(math.random(9, 15))
		end
	end)
	return function() alive = false SEA.calm = 1 SEA.waves = 1 end
end

local DIS = {}
DIS.Tsunami = { text = "TSUNAMI! A giant wave is coming!", run = function()
	local alive = true
	spawn(function()
		wait(8)
		if alive then waveWall(85, 380, 40) end
		wait(25)
		if alive then waveWall(60, 200, 30, -1) end
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
			local goal = SHIP_AT + V(math.sin(now * 0.15) * 30, 0, math.sin(now * 0.11) * 100)
			local d = V(goal.X - pos.X, 0, goal.Z - pos.Z)
			if d.magnitude > 1 then pos = pos + d.unit * 18 * dt end
			for i, r in ipairs(rings) do
				r.part.CFrame = CFrame.new(pos.X + math.sin(now * 2 + i) * i * 0.6, SEA.level + r.y, pos.Z) * CFrame.Angles(0, now * 4 + i, math.rad(90))
			end
			if ship and (V(pos.X, 0, pos.Z) - V(SHIP_AT.X, 0, SHIP_AT.Z)).magnitude < ship.len / 2 then damageShip(11 * dt) end
			for _, x in ipairs(players()) do
				local dd = V(x.t.Position.X - pos.X, 0, x.t.Position.Z - pos.Z)
				if dd.magnitude < 32 then
					x.h:TakeDamage(6 * dt)
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
	SEA.waves = 6
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
	spawn(function()
		wait(5)
		while alive do
			waveWall(math.random(20, 32), 55, 6)
			wait(math.random(8, 14))
		end
	end)
	spawn(function()
		while alive do
			wait(math.random(15, 35) / 10)
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
		WIND.v = V()
		SEA.waves = SEA.calm or 1
		toAll("weather", "clear")
		applyLighting()
	end
end }
DIS["Meteor Shower"] = { text = "METEOR SHOWER! Watch the sky and keep moving!", run = function()
	local alive = true
	spawn(function()
		while alive do
			wait(1.2)
			local at = math.random() < 0.6 and onDeck() or (SHIP_AT + V(math.random(-150, 150), SEA.level, math.random(-200, 200)))
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
			local baseAt = SHIP_AT + V(side * ((ship and ship.wid or 30) / 2 + 12), SEA.level - 4, z)
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
	SEA.waves = 3
	spawn(function()
		wait(4)
		while alive do   -- the waves knock people around: some might fall in...
			waveWall(math.random(16, 24), 30, 5)
			wait(math.random(10, 15))
		end
	end)
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
				s.pos = V(s.pos.X, SEA.level - 1.2, s.pos.Z) + s.look * (best and 22 or 12) * dt
				s.root.CFrame = CFrame.new(s.pos, s.pos + s.look)
				if best and bd < 6 and now > s.next then
					s.next = now + 1.5
					hurtNear(s.pos, 7, 25)
				end
			end
		end
	end)
	return function() alive = false SEA.waves = SEA.calm or 1 for _, s in ipairs(sharks) do s.m:Destroy() end end
end }
local ORDER = { "Tsunami", "Tornado", "Hurricane", "Meteor Shower", "Kraken", "Shark Attack" }

