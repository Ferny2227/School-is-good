-- ==== h40_hog.lua
------------------------------------------------------------------ bot Hogs
-- The server works out where each bot Hog is (no physics, so it can't get stuck) and tells every player's computer
-- where it's walking to through its "Move" value ("x z goalX goalZ speed what seq"); the computers move it smoothly
-- and swing its arms and legs. It walks the map's paths between rooms, can't get through locked doors, chases anyone
-- it can see, and has a harder time seeing and hearing you while you crouch.
local BOT_SPEED = { patrol = 10, look = 13, chase = 15.2 }
local SIGHT, SIGHT_CROUCH = 75, 32
local HEAR, HEAR_CROUCH = 9, 4.5
local CATCH = 4.2
-- the more locks you open, the angrier (and a bit faster) the Hog gets
local function angry() return 1 + math.min(0.06, 0.01 * ((MAP and MAP.solved) or 0)) end
local function sendMove(H, what, goal)
	goal = goal or H.pos
	H.mv.Value = string.format("%.2f %.2f %.2f %.2f %.2f %s %d", H.pos.X, H.pos.Z, goal.X, goal.Z, what == "m" and H.speed or 0, what or "m", H.seq)
	H.seq = H.seq + 1
end
local function newBot(offset, speedK)
	local at = V(MAP.pen.cx, 0, MAP.pen.cz) + (offset or V(0, 0, 0))
	local m = buildHog(MAP.model, CFrame.new(at + V(0, HOG_UP, 0)), "Hog")
	local mv = Instance.new("StringValue")
	mv.Name = "Move"
	mv.Parent = m
	local H = { model = m, pos = at, speed = 0, mv = mv, seq = 0, path = {}, mode = "wait", pause = 0, traps = 4, nextTrap = tick() + 35 + math.random(0, 20),
		k = speedK or 1 }
	table.insert(HOGS, H)
	sendMove(H, "s")
	return H
end
local function canSee(H, char, range)
	local t = torsoOf(char)
	if not t then return false end
	local eye = H.pos + V(0, 4.5, 0)
	local d = t.Position - eye
	if d.magnitude > range then return false end
	local ok, hit = pcall(function() return workspace:FindPartOnRay(Ray.new(eye, d), H.model) end)
	if not ok then return true end
	return hit == nil or hit:IsDescendantOf(char)
end
-- the path point nearest to a spot (in the same room)
local function nodeNear(pos)
	local R = roomAt(pos)
	local best, bd = nil, 1e9
	local list = R and R.nodes or MAP.nodes
	for _, n in ipairs(list) do
		local d = (flat(n.p) - flat(pos)).magnitude
		if d < bd and not nodeShut(n) then best, bd = n, d end
	end
	return best
end
-- the way from one spot to another along the paths (nil if it's shut off)
local function route(from, to)
	local a, b = nodeNear(from), nodeNear(to)
	if not a or not b then return nil end
	local prev, q, seen = {}, { a }, { [a] = true }
	local i = 1
	while q[i] do
		local n = q[i]
		i = i + 1
		if n == b then break end
		for _, l in ipairs(n.links) do
			if not seen[l] and not nodeShut(l) and not (l.door and l.door.exit) then
				seen[l] = true
				prev[l] = n
				table.insert(q, l)
			end
		end
	end
	if not seen[b] then return nil end
	local path = {}
	local n = b
	while n do table.insert(path, 1, n.p) n = prev[n] end
	table.insert(path, V(to.X, 0, to.Z))
	return path
end
local catchPlayer           -- (h50)
local function heard(at, radius)
	for _, H in ipairs(HOGS) do
		if H.mode ~= "chase" and H.mode ~= "wait" and H.pause <= 0 and (not radius or (flat(H.pos) - flat(at)).magnitude < radius) then
			H.path = route(H.pos, at) or {}
			H.mode = "look"
		end
	end
end
onHeard = heard
local traps = {}
local function placeTrap(at)
	local m = model(MAP.model, "Trap")
	local base = P(m, "Jaw", V(2.6, 0.3, 2.6), CFrame.new(V(at.X, 0.15, at.Z)), "Dark stone grey", "Metal", { nc = true })
	for i = -1, 1 do
		P(m, "Tooth", V(0.3, 0.6, 0.3), CFrame.new(V(at.X + i * 0.8, 0.6, at.Z - 1)), "Medium stone grey", "Metal", { nc = true })
		P(m, "Tooth", V(0.3, 0.6, 0.3), CFrame.new(V(at.X + i * 0.8, 0.6, at.Z + 1)), "Medium stone grey", "Metal", { nc = true })
	end
	table.insert(traps, { model = m, at = V(at.X, 0, at.Z), base = base })
end
local function botStep(H, dt)
	if H.mode == "wait" then return end
	if H.pause > 0 then
		H.pause = H.pause - dt
		return
	end
	-- who can it see (or hear right next to it)?
	local seen, sd, visible = nil, 1e9, false
	for p in pairs(survivors) do
		local t = not crawling[p] and torsoOf(p.Character)
		if t then
			local d = (flat(t.Position) - flat(H.pos)).magnitude
			local low = crouching[p]
			if d < sd then
				local v = canSee(H, p.Character, low and SIGHT_CROUCH or SIGHT)
				if v or d < (low and HEAR_CROUCH or HEAR) then seen, sd, visible = p, d, v end
			end
		end
	end
	local target
	if seen then
		local t = torsoOf(seen.Character)
		if H.mode ~= "chase" then H.path = {} end
		H.mode = "chase"
		H.last = t.Position
		H.speed = BOT_SPEED.chase * H.k * angry()
		if visible then
			target = V(t.Position.X, 0, t.Position.Z)
			H.path = {}
		elseif #H.path == 0 or (H.pathTo and (H.pathTo - t.Position).magnitude > 8) then
			H.path = route(H.pos, t.Position) or {}
			H.pathTo = t.Position
		end
	elseif H.mode == "chase" then
		-- lost them: go to where they were last seen, then look around
		if #H.path == 0 then H.path = route(H.pos, H.last) or {} end
		H.mode = "look"
	end
	if not target then
		if #H.path == 0 then
			if H.mode == "look" then H.mode = "patrol" end
			-- wander to a random room
			local rooms = {}
			for _, R in ipairs(MAP.rooms) do if R ~= MAP.pen then table.insert(rooms, R) end end
			local R = pick(rooms)
			local to = V(R.cx + math.random(-4, 4), 0, R.cz + math.random(-4, 4))
			if R.kind == "open" then to = pick(R.nodes).p end       -- (somewhere out in the open fair)
			H.path = route(H.pos, to) or {}
			if #H.path == 0 then H.pause = 1 return end
		end
		H.speed = (H.mode == "look" and BOT_SPEED.look or H.mode == "chase" and BOT_SPEED.chase or BOT_SPEED.patrol) * H.k * angry()
		target = H.path[1]
	end
	local d = target - H.pos
	local step = H.speed * dt
	if d.magnitude <= step then
		H.pos = target
		if not seen and H.path[1] then table.remove(H.path, 1) end
	else
		H.pos = H.pos + d.unit * step
	end
	-- tell the players' computers where it's going (only when that changes)
	local goal = H.path[1] or target
	if not H.sent or H.sentSpeed ~= H.speed or (H.sent - goal).magnitude > 4 or ((H.sent - goal).magnitude > 0.5 and tick() - H.sentAt > 0.2) then
		H.sent, H.sentSpeed, H.sentAt = goal, H.speed, tick()
		sendMove(H, "m", goal)
	end
	-- now and then it sets a trap in a doorway
	if H.traps > 0 and tick() > H.nextTrap and not seen then
		for _, dn in ipairs(MAP.doorNodes) do
			if not dn.door.exit and not dn.lock and (flat(dn.p) - flat(H.pos)).magnitude < 2 then
				H.traps = H.traps - 1
				H.nextTrap = tick() + 50
				placeTrap(dn.p + (dn.vertical and V(math.random() < 0.5 and -3 or 3, 0, 0) or V(0, 0, math.random() < 0.5 and -3 or 3)))
				break
			end
		end
	end
	-- caught anyone?
	for p in pairs(survivors) do
		local t = not crawling[p] and torsoOf(p.Character)
		if t and (flat(t.Position) - flat(H.pos)).magnitude < CATCH and math.abs(t.Position.Y - HOG_UP) < 4.5 then
			catchPlayer(p)
			H.pause = 2.5
			H.path = {}
			H.mode = "look"
			H.sent = nil
			sendMove(H, "e")
			break
		end
	end
end
local function botsStep(dt) for _, H in ipairs(HOGS) do botStep(H, dt) end end

------------------------------------------------------------------ players as the Hog (Player, Player + Bot, Infection)
local hogTrap
local hogTrapsLeft = {}
local function morph(p)
	local c = p.Character
	local head = c and c:FindFirstChild("Head")
	if not head or c:FindFirstChild("HogHead") then return end
	for _, o in ipairs(c:GetChildren()) do
		if o:IsA("Hat") or o:IsA("Accessory") or o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") then pcall(function() o:Destroy() end) end
		if o:IsA("BasePart") and o.Name ~= "HumanoidRootPart" then
			o.BrickColor = BrickColor.new((o.Name:find("Leg") and "Bright blue") or "Pink")
		end
	end
	pcall(function() head.face:Destroy() end)
	pcall(function() head.Flashlight:Destroy() end)
	local rootCF = head.CFrame * CFrame.new(0, -3 + 0.1, 0)
	local pose = HogPose(rootCF, 0, 0)
	for _, d in ipairs(HOG_PARTS) do
		local n = d[1]
		if n == "Head" or n == "Snout" or n:find("Nostril") or n:find("Eye") or n:find("Pupil") or n:find("Brow") or n == "Mouth" or n:find("Ear") then
			local part = P(c, "Hog" .. n, n == "Head" and V(2.3, 2, 2.1) or d[2], pose[n], d[4], d[5], { shape = d[6], anchored = false, nc = true })
			weld(head, part)
		end
	end
	local h = c:FindFirstChild("Humanoid")
	if h then h.WalkSpeed = 17 end
	-- a tool for laying traps
	hogTrapsLeft[p] = 3
	local tool = Instance.new("Tool")
	tool.Name = "Trap"
	pcall(function() tool.CanBeDropped = false end)
	pcall(function() tool.ToolTip = "Click to set a trap at your feet" end)
	local hd = P(tool, "Handle", V(1.6, 0.3, 1.6), CFrame.new(), "Dark stone grey", "Metal", { anchored = false })
	hd.CanCollide = false
	tool.Parent = p:FindFirstChild("Backpack") or c
	tool.Activated:connect(function() if hogTrap then hogTrap(p) end end)
end
local lastTrap = {}
function hogTrap(p)
	if not hogPlayers[p] or (hogTrapsLeft[p] or 0) <= 0 or tick() - (lastTrap[p] or 0) < 1.5 or STATE.phase ~= "hunt" then return end
	local t = torsoOf(p.Character)
	if not t then return end
	lastTrap[p] = tick()
	hogTrapsLeft[p] = hogTrapsLeft[p] - 1
	placeTrap(t.Position)
	say(p, "Trap set! (" .. hogTrapsLeft[p] .. " left)", "gold")
end
-- a Hog player (or the Traitor) catches you by touching you
local hogCool = {}
local function hogPlayerStep()
	local hunters = {}
	for p in pairs(hogPlayers) do table.insert(hunters, { p, 1.5 }) end
	if traitor then table.insert(hunters, { traitor, 25 }) end
	for _, hh in ipairs(hunters) do
		local hp = hh[1]
		local ht = torsoOf(hp.Character)
		if ht and tick() > (hogCool[hp] or 0) then
			for p in pairs(survivors) do
				local t = not crawling[p] and torsoOf(p.Character)
				if p ~= hp and t and (t.Position - ht.Position).magnitude < 5 then
					catchPlayer(p, hp)
					hogCool[hp] = tick() + hh[2]
					addCoins(hp, 10)
					if hp == traitor then toClient(hp, "toast", "Got one! Next catch in 25 seconds.", "red") end
					break
				end
			end
		end
	end
end

------------------------------------------------------------------ crouching (C, or the button): slower, lower, harder to spot
local JOINTS = { "RootJoint", "Right Hip", "Left Hip" }
local function setCrouch(p, on)
	on = on and true or nil
	if not survivors[p] and on then return end
	if not on and crawling[p] and survivors[p] then
		-- no room to stand up in a vent tunnel
		say(p, "No room to stand up in here!", "gold")
		toClient(p, "crouchforce", true)
		return
	end
	if crouching[p] == on then return end
	crouching[p] = on
	local c = p.Character
	local h = c and c:FindFirstChild("Humanoid")
	if h and not stuck[p] then h.WalkSpeed = on and 8 or 16 end
	local root, torso = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChild("Torso")
	pcall(function()
		for _, jn in ipairs(JOINTS) do
			local j = (jn == "RootJoint" and root or torso):FindFirstChild(jn)
			if j then
				if not j:FindFirstChild("StandC0") then
					local v = Instance.new("CFrameValue")
					v.Name = "StandC0"
					v.Value = j.C0
					v.Parent = j
				end
				local c0 = j.StandC0.Value
				if not on then j.C0 = c0
				elseif jn == "RootJoint" then j.C0 = CFrame.new(0, -1.2, 0) * CFrame.Angles(-0.35, 0, 0) * c0
				else j.C0 = CFrame.new(c0.p) * CFrame.Angles(1.35, 0, 0) * (CFrame.new(-c0.p) * c0) end
			end
		end
	end)
end

------------------------------------------------------------------ traps catch your foot
local function trapStep()
	for i = #traps, 1, -1 do
		local tr = traps[i]
		for p in pairs(survivors) do
			local t = torsoOf(p.Character)
			if t and not stuck[p] and (flat(t.Position) - flat(tr.at)).magnitude < 2.2 and t.Position.Y < 6 then
				local h = p.Character:FindFirstChild("Humanoid")
				stuck[p] = true
				tr.base.BrickColor = BrickColor.new("Really red")
				if h then h.WalkSpeed = 0 pcall(function() h.JumpPower = 0 end) end
				toClient(p, "big", "TRAPPED!", "You're stuck for 5 seconds...")
				heard(tr.at)
				local m = tr.model
				table.remove(traps, i)
				delay(5, function()
					stuck[p] = nil
					pcall(function() m:Destroy() end)
					if h and survivors[p] then h.WalkSpeed = crouching[p] and 8 or 16 pcall(function() h.JumpPower = 50 end) end
				end)
				break
			end
		end
	end
end

------------------------------------------------------------------ the STUN GUN: shoot a Hog and it's frozen for 20 seconds
local STUN = 20
local lastShot = {}
local stunnedUntil = {}
local function stunMark(part, secs)
	if not part then return end
	local old = part:FindFirstChild("Stunned")
	if old then old:Destroy() end
	local b = bill(part, "STUNNED!", 8, 2, 5, Color3.new(1, 0.95, 0.3))
	b.Parent.Name = "Stunned"
	delay(secs, function() pcall(function() b.Parent:Destroy() end) end)
end
local function stunBot(H)
	H.pause = STUN
	H.path, H.mode, H.sent = {}, "look", nil
	sendMove(H, "z")
	stunMark(H.model:FindFirstChild("Root"), STUN)
end
local function stunPlayer(hp)
	stunnedUntil[hp] = tick() + STUN
	hogCool[hp] = tick() + STUN
	local h = hp.Character and hp.Character:FindFirstChild("Humanoid")
	if h then h.WalkSpeed = 0 pcall(function() h.JumpPower = 0 end) end
	stunMark(hp.Character and hp.Character:FindFirstChild("Head"), STUN)
	toClient(hp, "big", "STUNNED!", "You can't move for 20 seconds...")
	delay(STUN, function()
		if hogPlayers[hp] and h then h.WalkSpeed = 17 pcall(function() h.JumpPower = 50 end) end
	end)
end
local function rayHit(o, dir, ignore)
	local ok, part, pos = pcall(function() return workspace:FindPartOnRayWithIgnoreList(Ray.new(o, dir), ignore) end)
	if not ok then ok, part, pos = pcall(function() return workspace:FindPartOnRay(Ray.new(o, dir), ignore[1]) end) end
	if not ok then return nil, o + dir end
	if part and not pos then pos = o + dir.unit * math.max(0, (part.Position - o):Dot(dir.unit)) end
	return part, pos or (o + dir)
end
local function shoot(p, at)
	if not MAP or not survivors[p] or holding[p] ~= "Stun Gun" or STATE.phase ~= "hunt" then return end
	if not pcall(function() return at.X + at.Y + at.Z end) then return end
	if tick() - (lastShot[p] or 0) < 0.8 then return end
	local head = p.Character and p.Character:FindFirstChild("Head")
	if not head then return end
	local o = head.Position
	local dir = at - o
	if dir.magnitude < 0.1 then return end
	dir = dir.unit * 90
	lastShot[p] = tick()
	local ignore = { p.Character }
	for _, H in ipairs(HOGS) do table.insert(ignore, H.model) end
	local hitPart, hitPos = rayHit(o, dir, ignore)
	local endPos = hitPos
	local target, hogP = nil, nil
	if hitPart then
		for hp in pairs(hogPlayers) do if hp.Character and hitPart:IsDescendantOf(hp.Character) then hogP = hp end end
	end
	-- a bot Hog: the shot passes close enough to it before hitting anything else
	local wallDist = (hitPos - o).magnitude
	for _, H in ipairs(HOGS) do
		local c = H.pos + V(0, 3, 0)
		local t = (c - o):Dot(dir.unit)
		if t > 0 and t < wallDist + 2 and (o + dir.unit * t - c).magnitude < 3.5 and (not target or t < target.t) then target = { H = H, t = t } end
	end
	if target then endPos = o + dir.unit * target.t hogP = nil end
	local len = (endPos - o).magnitude
	local beam = P(MAP.model, "StunBeam", V(0.3, 0.3, math.max(0.5, len)), CFrame.new((o + endPos) / 2, endPos), "New Yeller", "Neon", { nc = true })
	Debris:AddItem(beam, 0.25)
	gunShots[p] = (gunShots[p] or 1) - 1
	if target then
		stunBot(target.H)
		sayAll(p.Name .. " STUNNED the Hog!", "gold")
		addCoins(p, 10)
	elseif hogP then
		stunPlayer(hogP)
		sayAll(p.Name .. " STUNNED " .. hogP.Name .. "!", "gold")
		addCoins(p, 10)
	end
	if gunShots[p] <= 0 then
		holding[p] = nil
		takeTool(p)
		toClient(p, "hold", nil)
		say(p, "The Stun Gun is empty! Another one will turn up somewhere...", "gold")
		local mapNow = MAP
		delay(40, function() if MAP == mapNow and STATE.phase == "hunt" then spawnItem("Stun Gun") end end)
	else
		toClient(p, "hold", "Stun Gun", gunShots[p])
	end
end
