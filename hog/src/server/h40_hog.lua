-- ==== h40_hog.lua
------------------------------------------------------------------ the bot Hog
-- The server works out where the Hog is (no physics, so it can't get stuck) and tells every player's computer where
-- it's walking to through the "Move" value ("x z goalX goalZ speed what"); the computers move it smoothly and swing its arms
-- and legs. It walks the map's paths between rooms, can't get through locked doors, and chases anyone it can see.
local BOT_SPEED = { patrol = 10, look = 13, chase = 15.2 }
local SIGHT = 75
local CATCH = 4.2
local function sendMove(what)
	if not HOG then return end
	HOG.mv.Value = string.format("%.2f %.2f %.2f %.2f %.2f %s %d", HOG.pos.X, HOG.pos.Z, HOG.pos.X, HOG.pos.Z, HOG.speed, what or "m", HOG.seq)
	HOG.seq = HOG.seq + 1
end
local function newBot()
	local at = V(MAP.pen.cx, 0, MAP.pen.cz)
	local m = buildHog(MAP.model, CFrame.new(at + V(0, HOG_UP, 0)), "Hog")
	local mv = Instance.new("StringValue")
	mv.Name = "Move"
	mv.Parent = m
	HOG = { model = m, pos = at, speed = 0, mv = mv, seq = 0, path = {}, mode = "wait", pause = 0, traps = 3, nextTrap = tick() + 40,
		goal = nil, sent = nil }
	sendMove("s")
	return HOG
end
local function canSee(from, char)
	local t = torsoOf(char)
	if not t then return false end
	local eye = from + V(0, 4.5, 0)
	local d = t.Position - eye
	if d.magnitude > SIGHT then return false end
	local ok, hit = pcall(function() return workspace:FindPartOnRay(Ray.new(eye, d), HOG and HOG.model or nil) end)
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
local catchPlayer           -- (below)
local function heard(at)
	if HOG and HOG.mode ~= "chase" and HOG.mode ~= "wait" then
		HOG.path = route(HOG.pos, at) or {}
		HOG.mode = "look"
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
local function botStep(dt)
	local H = HOG
	if not H or H.mode == "wait" then return end
	if H.pause > 0 then
		H.pause = H.pause - dt
		return
	end
	-- who can it see?
	local seen, sd = nil, 1e9
	for p in pairs(survivors) do
		local t = torsoOf(p.Character)
		if t then
			local d = (flat(t.Position) - flat(H.pos)).magnitude
			if d < sd and (d < 9 or canSee(H.pos, p.Character)) then seen, sd = p, d end
		end
	end
	local target
	if seen then
		local t = torsoOf(seen.Character)
		if H.mode ~= "chase" then H.path = {} end
		H.mode = "chase"
		H.last = t.Position
		H.lastT = tick()
		H.speed = BOT_SPEED.chase
		if canSee(H.pos, seen.Character) then
			target = V(t.Position.X, 0, t.Position.Z)
			H.path = {}
		else
			if #H.path == 0 or (H.pathTo and (H.pathTo - t.Position).magnitude > 8) then
				H.path = route(H.pos, t.Position) or {}
				H.pathTo = t.Position
			end
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
			H.path = route(H.pos, V(R.cx + math.random(-4, 4), 0, R.cz + math.random(-4, 4))) or {}
			if #H.path == 0 then H.pause = 1 return end
		end
		H.speed = H.mode == "look" and BOT_SPEED.look or H.mode == "chase" and BOT_SPEED.chase or BOT_SPEED.patrol
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
		HOG.mv.Value = string.format("%.2f %.2f %.2f %.2f %.2f m %d", H.pos.X, H.pos.Z, goal.X, goal.Z, H.speed, H.seq)
		H.seq = H.seq + 1
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
		local t = torsoOf(p.Character)
		if t and (flat(t.Position) - flat(H.pos)).magnitude < CATCH and math.abs(t.Position.Y - HOG_UP) < 7 then
			catchPlayer(p)
			H.pause = 2.5
			H.path = {}
			H.mode = "look"
			HOG.mv.Value = string.format("%.2f %.2f %.2f %.2f 0 e %d", H.pos.X, H.pos.Z, H.pos.X, H.pos.Z, H.seq)
			H.seq = H.seq + 1
			H.sent = nil
			break
		end
	end
end

------------------------------------------------------------------ a player as the Hog
local hogTrap
local function morph(p)
	local c = p.Character
	local head = c and c:FindFirstChild("Head")
	if not head then return end
	for _, o in ipairs(c:GetChildren()) do
		if o:IsA("Hat") or o:IsA("Accessory") or o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") then pcall(function() o:Destroy() end) end
		if o:IsA("BasePart") and o.Name ~= "HumanoidRootPart" then
			o.BrickColor = BrickColor.new((o.Name:find("Leg") and "Bright blue") or "Pink")
		end
	end
	pcall(function() head.face:Destroy() end)
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
	local tool = Instance.new("Tool")
	tool.Name = "Trap"
	pcall(function() tool.CanBeDropped = false end)
	pcall(function() tool.ToolTip = "Click to set a trap at your feet" end)
	local hd = P(tool, "Handle", V(1.6, 0.3, 1.6), CFrame.new(), "Dark stone grey", "Metal", { anchored = false })
	hd.CanCollide = false
	tool.Parent = p:FindFirstChild("Backpack") or c
	tool.Activated:connect(function() if hogTrap then hogTrap(p) end end)
end
local hogTrapLeft, lastTrap = 3, 0
function hogTrap(p)
	if p ~= hogPlayer or hogTrapLeft <= 0 or tick() - lastTrap < 1.5 or STATE.phase ~= "hunt" then return end
	local t = torsoOf(p.Character)
	if not t then return end
	lastTrap = tick()
	hogTrapLeft = hogTrapLeft - 1
	placeTrap(t.Position)
	say(p, "Trap set! (" .. hogTrapLeft .. " left)", "gold")
end
local hogCool = 0
local function hogPlayerStep()
	if not hogPlayer then return end
	local ht = torsoOf(hogPlayer.Character)
	if not ht or tick() < hogCool then return end
	for p in pairs(survivors) do
		local t = torsoOf(p.Character)
		if t and (t.Position - ht.Position).magnitude < 5 then
			catchPlayer(p)
			hogCool = tick() + 1.5
			addCoins(hogPlayer, 10)
			break
		end
	end
end

------------------------------------------------------------------ traps catch your foot
local stuck = {}
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
					if h and survivors[p] then h.WalkSpeed = 16 pcall(function() h.JumpPower = 50 end) end
				end)
				break
			end
		end
	end
end
