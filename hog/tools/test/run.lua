-- Runs HogServer (and HogClient) in the mock Roblox: lobby, voting, both maps, items, locks, the exit, the bot Hog,
-- traps, a Player Hog round, and the client's HUD and Hog walking.
local MOCK = MOCK
local out = {}
local function say(s) table.insert(out, s) end
local realNew = Instance.new
Instance.new = function(cls, parent)
	local o = realNew(cls, parent)
	if cls == "Humanoid" then o.Health, o.MaxHealth, o.WalkSpeed, o.Sit = 100, 100, 16, false
	elseif cls == "IntValue" or cls == "NumberValue" then o.Value = 0
	elseif cls == "StringValue" then o.Value = "" end
	return o
end
local mt = getmetatable(workspace)
local oldIndex = mt.__index
mt.__index = function(o, k)
	if k == "TakeDamage" then return function(self, d) self.Health = math.max(0, self.Health - d) end end
	if k == "Clear" then return function() end end
	if k == "Activated" or k == "Button1Down" then
		local props = rawget(o, "_p")
		props[k] = props[k] or MOCK.Event(k)
		return props[k]
	end
	if k == "FindPartOnRay" then
		-- ray against the parts' boxes (good enough: walls and doors aren't turned)
		return function(self, ray, ignore)
			local o0, d = ray.Origin, ray.Direction
			local best, bt = nil, 1
			for _, p in ipairs(MOCK.allParts) do
				if p.Parent and p:IsDescendantOf(workspace) and not (ignore and p:IsDescendantOf(ignore)) then
					local c, s = p.CFrame.p, p.Size
					local t0, t1 = 0, 1
					local ok = true
					for _, ax in ipairs({ "X", "Y", "Z" }) do
						local lo, hi = c[ax] - s[ax] / 2, c[ax] + s[ax] / 2
						if math.abs(d[ax]) < 1e-9 then
							if o0[ax] < lo or o0[ax] > hi then ok = false break end
						else
							local a, b = (lo - o0[ax]) / d[ax], (hi - o0[ax]) / d[ax]
							if a > b then a, b = b, a end
							t0, t1 = math.max(t0, a), math.min(t1, b)
							if t0 > t1 then ok = false break end
						end
					end
					if ok and t0 < bt then best, bt = p, t0 end
				end
			end
			return best
		end
	end
	return oldIndex(o, k)
end
Ray = { new = function(o, d) return { Origin = o, Direction = d } end }
local map = MOCK.new("Model", workspace) map.Name = "AirportMap"
local Lighting = MOCK.services.Lighting
local fired = {}
local lastMsg = {}
MOCK.onFireClient = function(remote, p, what, ...)
	fired[what] = (fired[what] or 0) + 1
	lastMsg[p.Name .. ":" .. tostring(what)] = { ... }
end
local fn = assert(loadstring(SERVER_SOURCE, "=HogServer"))
spawn(fn)
MOCK.run(1)
local D = _G.HogDebug
assert(D, "server did not start: " .. table.concat(MOCK.errors, "\n"))
say("old map removed: " .. tostring(workspace:FindFirstChild("AirportMap") == nil) .. ", lobby built: " .. tostring(workspace["Hog World"]:FindFirstChild("Lobby") ~= nil))

-- every map on its own: rooms, paths, furniture out of the doorways, items not inside furniture
local function count(m, pred) local n = 0 for _, o in ipairs(m:GetDescendants()) do if pred(o) then n = n + 1 end end return n end
for _, name in ipairs({ "Hog Manor", "School", "Circus" }) do
	local before = #MOCK.errors
	local M = D.buildMap(name)
	for _, it in ipairs(M.def.items) do D.spawnItem(it[1]) end
	local parts = count(M.model, function(o) return o:IsA("BasePart") end)
	-- furniture in a doorway?
	local inDoor = 0
	for _, o in ipairs(M.model:GetChildren()) do
		if o:IsA("BasePart") and o.Name ~= "Wall" and o.Name ~= "Floor" and o.Name ~= "Ceiling" and o.Name ~= "Ground" and o.Name ~= "Roof"
			and o.Name ~= "Runner" and o.Name ~= "Skirting" and o.Name ~= "Keyhole" and o.Name ~= "Handle" and o.Name ~= "Rug" and not o.Name:find("Window") and not o.Name:find("Vent") and o.Name ~= "CardReader" and o.Name ~= "ReaderLight" and o.Name ~= "DoorStripe" and o.Name ~= "Bulb" and o.Name ~= "Stripe" and o.Name ~= "TentRoof" and o.Name ~= "Boards" and o.Name ~= "Padlock" and o.Name ~= "Bolt" and not o.Name:find("Fuse") and not o.Name:find("Door") and not o.Name:find("Gate") and o.Name ~= "Lamp" then
			for _, dn in ipairs(M.doorNodes) do
				local p = o.Position
				if math.abs(p.X - dn.p.X) < 4 and math.abs(p.Z - dn.p.Z) < 4 and p.Y < 9 then inDoor = inDoor + 1 if #MOCK.log < 30 then table.insert(MOCK.log, name .. " door " .. o.Name .. " " .. tostring(p.X) .. "," .. tostring(p.Z)) end end
			end
		end
	end
	-- can the Hog get everywhere (once the locks are open)? and not into locked rooms before?
	local pen = Vector3.new(M.pen.cx, 0, M.pen.cz)
	M.gate.done = true
	local locked, reach0 = 0, 0
	for _, R in ipairs(M.rooms) do
		if D.route(pen, Vector3.new(R.cx, 0, R.cz)) then reach0 = reach0 + 1 end
	end
	for _, L in ipairs(M.locks) do L.done = true end
	local reach = 0
	for _, R in ipairs(M.rooms) do if D.route(pen, Vector3.new(R.cx, 0, R.cz)) then reach = reach + 1 end end
	local spots, itemsOk = 0, 0
	for _, R in ipairs(M.rooms) do spots = spots + #R.spots end
	local where = {}
	for _, it in pairs(M.items) do
		local R = D.roomAt(it.at)
		table.insert(where, it.name .. "@" .. (R and R.id or "?"))
		local want
		for _, d in ipairs(M.def.items) do if d[1] == it.name then want = d[2] end end
		local lockedRoom = ({ bedroom = 1, cellar = 1, lab = 1, office = 1, storage = 1, coaster = 1, pen = 1, security = 1, computers = 1 })[R and R.id or ""]
		if R and (want == "open" and not lockedRoom or want == R.id) then itemsOk = itemsOk + 1 end
	end
	table.sort(where)
	-- open fair: the Hog's paths never go through a building's wall (only through its doorways)
	local fair, badPath, lonelyDoors = nil, 0, 0
	for _, R in ipairs(M.rooms) do if R.kind == "open" then fair = R end end
	if fair then
		for _, dn in ipairs(M.doorNodes) do
			if dn.B == fair or dn.A == fair then
				local g = 0
				for _, l in ipairs(dn.links) do if l.room == fair then g = g + 1 end end
				if g == 0 then lonelyDoors = lonelyDoors + 1 end
			end
		end
		for k = 1, 40 do
			local nd = fair.nodes[(k * 7) % #fair.nodes + 1]
			local path = D.route(pen, nd.p) or {}
			if #path == 0 then badPath = badPath + 1 end
			for i = 2, #path do
				local a, b = path[i - 1], path[i]
				for t = 0, 1, 0.05 do
					local q = a + (b - a) * t
					for _, Q in ipairs(M.rooms) do
						if Q ~= fair and q.X > Q.x1 + 0.6 and q.X < Q.x2 - 0.6 and q.Z > Q.z1 + 0.6 and q.Z < Q.z2 - 0.6 then
							-- inside a building: fine if it's that building's own path (between its door and its centre)
						elseif Q ~= fair and (math.abs(q.X - Q.x1) < 0.5 or math.abs(q.X - Q.x2) < 0.5) and q.Z > Q.z1 and q.Z < Q.z2 or Q ~= fair and (math.abs(q.Z - Q.z1) < 0.5 or math.abs(q.Z - Q.z2) < 0.5) and q.X > Q.x1 and q.X < Q.x2 then
							local nearDoor = false
							for _, dn in ipairs(M.doorNodes) do if (dn.p - q).magnitude < 6 then nearDoor = true end end
							if not nearDoor then badPath = badPath + 1 end
						end
					end
				end
			end
		end
		say(string.format("  %s open fair: %d grid points, doorways with no path out %d, Hog paths through a wall %d", name, #fair.nodes, lonelyDoors, badPath))
	end
	local ventsOk = 0
	for _, v in ipairs(M.vents) do
		local ra, rb = D.roomAt(v.a.at), D.roomAt(v.b.at)
		if ra and rb and ra ~= rb then ventsOk = ventsOk + 1 end
	end
	local w, d = M.maxX - M.minX, M.maxZ - M.minZ
	say(string.format("%s: %dx%d studs, %d parts, %d rooms, %d path points, furniture in doorways %d, Hog reaches %d/%d rooms (%d before the locks open), %d item spots, items in allowed rooms %d/%d [%s], vent ends %d/%d ok, new errors %d",
		name, w, d, parts, #M.rooms, #M.nodes, inDoor, reach, #M.rooms, reach0, spots, itemsOk, #M.def.items, table.concat(where, " "), ventsOk, #M.vents, #MOCK.errors - before))
	M.model:Destroy()
end

-- three players in the lobby vote: Hog Manor, Bot Hog
local realMake = MOCK.makeCharacter
MOCK.makeCharacter = function(p)
	local c = realMake(p)
	local root = MOCK.part(c, "HumanoidRootPart", Vector3.new(2, 2, 1), c.Torso.CFrame)
	local rj = MOCK.new("Motor6D", root) rj.Name = "RootJoint" rj.C0 = CFrame.new()
	for _, n in ipairs({ "Right Hip", "Left Hip" }) do
		local j = MOCK.new("Motor6D", c.Torso) j.Name = n j.C0 = CFrame.new(n == "Right Hip" and 1 or -1, -1, 0)
	end
	return c
end
local ps = {}
for i = 1, 3 do
	local p = MOCK.addPlayer("kid" .. i, i)
	MOCK.new("Backpack", p).Name = "Backpack"
	MOCK.run(0.3)
	MOCK.makeCharacter(p)
	ps[i] = p
end
MOCK.run(1)
local inLobby = 0
for _, p in ipairs(ps) do if (p.Character.Torso.Position - D.LOBBY).magnitude < 60 then inLobby = inLobby + 1 end end
local remoteS = MOCK.services.ReplicatedStorage.HogEvent
local function touchPad(p, name)
	local kind = (name == "Hog Manor" or name == "School" or name == "Circus") and "map" or "mode"
	remoteS.OnServerEvent:fireNow(p, "vote", kind, name)
	return true
end
-- nobody pressed PLAY yet: the countdown waits
MOCK.run(5)
local waited = D.STATE.left
for _, p in ipairs(ps) do remoteS.OnServerEvent:fireNow(p, "play") end
local okv0 = true
local okv = touchPad(ps[1], "Hog Manor") and touchPad(ps[2], "Hog Manor") and touchPad(ps[3], "School")
	and touchPad(ps[1], "Bot") and touchPad(ps[2], "Bot")
for _ = 1, 100 do MOCK.run(0.5) if D.STATE.phase == "release" then break end end
local M = D.getMap()
local nsurv = 0
for p in pairs(D.survivors()) do
	if D.roomAt(p.Character.Torso.Position) == M.start then nsurv = nsurv + 1 end
end
local hasLight = ps[1].Character.Head:FindFirstChild("Flashlight") ~= nil
say(string.format("countdown waited for PLAY: %s (left %d); in the lobby %d/3, votes ok %s, round: %s (%s), survivors in the start room %d/3, flashlight %s, items %d, status sent %d",
	tostring(waited >= 19), waited, inLobby, tostring(okv), M.name, tostring(D.getHog() ~= nil and "Bot Hog" or "?"), nsurv, tostring(hasLight), (function() local n = 0 for _ in pairs(M.items) do n = n + 1 end return n end)(), fired.status or 0))
-- the Hog waits in its pen, then gets out
local hog = D.getHog()
if not hog then error("no hog; phase " .. D.STATE.phase .. "\n" .. table.concat(out, "\n") .. "\n" .. table.concat(MOCK.errors, "\n")) end
local penPos = hog.pos
MOCK.run(5)
local stillIn = (hog.pos - penPos).magnitude < 1
for _ = 1, 40 do MOCK.run(0.5) if D.STATE.phase == "hunt" then break end end
MOCK.run(6)
say(string.format("Hog stayed in its pen until released: %s, phase now '%s', Hog walked %.0f studs from the pen in 6 s",
	tostring(stillIn), D.STATE.phase, (hog.pos - penPos).magnitude))

-- items: pick up, swap, wrong lock, right lock, the exit
D.STATE.hold = true             -- (stop the clock and the Hog while we play the puzzle)
local p1 = ps[1]
local function itemPart(name)
	for m, it in pairs(M.items) do if it.name == name then return m.Handle, it end end
end
local function goTo(p, pos)
	p.Character.Torso.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	p.Character.Head.CFrame = CFrame.new(pos + Vector3.new(0, 4.5, 0))
end
local function click(p, part)
	goTo(p, part.Position + Vector3.new(2, 0, 0))
	MOCK.run(0.3)
	remoteS.OnServerEvent:fireNow(p, "click", part)
end
local function lockPart(name) for _, L in ipairs(M.locks) do if L.name == name then return L.parts[1], L end end end
local hammer = itemPart("Hammer")
click(p1, hammer)
local h1 = D.holding()[p1]
local hasTool = p1.Character:FindFirstChild("Hammer") ~= nil and (#p1.Character.Hammer:GetChildren() .. " parts welded")
local redKey = itemPart("Red Key")
click(p1, redKey)
local h2 = D.holding()[p1]
local hammerBack = itemPart("Hammer") ~= nil
local boards = lockPart("Boards")
click(p1, boards)
local wrongMsg = lastMsg["kid1:toast"] and lastMsg["kid1:toast"][1] or ""
local redDoor, RL = lockPart("Red Door")
click(p1, redDoor)
say(string.format("picked up: %s (in hand %s); then the Red Key: holding %s, hammer dropped back on the floor %s; wrong lock says '%s'; Red Door open %s, door walkable %s",
	tostring(h1), tostring(hasTool), tostring(h2), tostring(hammerBack), wrongMsg, tostring(RL.done), tostring(not redDoor.CanCollide)))
local looks = {}
for _, it in pairs(M.items) do local n = 0 for _, o in ipairs(it.model:GetChildren()) do if o:IsA("BasePart") then n = n + 1 end end table.insert(looks, it.name .. "=" .. n) end
say("items are made of parts: " .. table.concat(looks, " "))
-- walking over an item doesn't pick it up (you click it); clicking from far away doesn't work either
local p3w = ps[3]
local bk = itemPart("Blue Key")
goTo(p3w, bk.Position + Vector3.new(1, 0, 1))
MOCK.run(0.5)
local walked = D.holding()[p3w]
goTo(p3w, bk.Position + Vector3.new(40, 0, 0))
MOCK.run(0.3)
remoteS.OnServerEvent:fireNow(p3w, "click", bk)
local far = D.holding()[p3w]
local bd, BL = lockPart("Blue Door")
local doorParts = #BL.parts
local signs = 0
for _, o in ipairs(M.model:GetDescendants()) do if o.ClassName == "SurfaceGui" and o.Parent and (o.Parent.Name == "LockedDoor" or o.Parent.Name == "Fuse Box") then signs = signs + 1 end end
say(string.format("walking over the Blue Key picks it up: %s, clicking it from 40 studs away: %s; the locked door is %d parts (handle + keyhole in the key's colour), hint signs on locks %d",
	tostring(walked), tostring(far), doorParts, signs))
-- VENTS: a hole in the floor, a tunnel too low to stand in, a ladder out at the other end
local vent = M.vents[1]
local A, B = vent.a.at, vent.b.at
local hitA = workspace:FindPartOnRay(Ray.new(A + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0)))
local hitB = workspace:FindPartOnRay(Ray.new(B + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0)))
local height = vent.top - vent.bot
-- walk the tunnel: nothing in the way at crouching height (0.5 .. 3.9 above its floor), but a standing player's
-- head (5 studs up) hits the ceiling
local function blockedAt(q, y)
	return workspace:FindPartOnRay(Ray.new(Vector3.new(q.X, vent.bot + y, q.Z), Vector3.new(0, 0.01, 0))) ~= nil
end
local C = Vector3.new(B.X, 0, A.Z)
local clearRun, n = true, 0
for t = 0.15, 0.85, 0.05 do
	for _, seg in ipairs({ { A, C }, { C, B } }) do
		local q = seg[1] + (seg[2] - seg[1]) * t
		n = n + 1
		for _, y in ipairs({ 1, 2, 3, 3.9 }) do
			local r = workspace:FindPartOnRay(Ray.new(Vector3.new(q.X, vent.bot + y, q.Z), Vector3.new(0.01, 0, 0.01)))
			if r then clearRun = false end
		end
	end
end
say(string.format("vent: hole goes down to the tunnel %s/%s (%s / %s), tunnel %.1f studs high (standing needs 5, crouching 3.9), tunnel clear to crawl %s",
	tostring(hitA and (hitA.Name == "DuctFloor" or hitA.Name == "VentLadder")), tostring(hitB and (hitB.Name == "DuctFloor" or hitB.Name == "VentLadder")), hitA and hitA.Name or "-", hitB and hitB.Name or "-", height, tostring(clearRun)))
-- down in the tunnel the Hog can't see or catch you, and you can't stand up
remoteS.OnServerEvent:fireNow(p3w, "crouch", true)
goTo(p3w, Vector3.new(A.X, vent.bot + 0.05, A.Z))
local Hv = D.getHog()
local backTo = {}
for _, p in ipairs(ps) do if p ~= p3w then backTo[p] = p.Character.Torso.Position goTo(p, Vector3.new(-320, 0, 0)) end end
Hv.pos, Hv.mode, Hv.path, Hv.pause = Vector3.new(A.X + 2, 0, A.Z), "patrol", {}, 0
D.STATE.hold = false
MOCK.run(1)
D.STATE.hold = true
local safe = D.survivors()[p3w] == true and Hv.mode ~= "chase"
for p, at in pairs(backTo) do goTo(p, at - Vector3.new(0, 3, 0)) end
remoteS.OnServerEvent:fireNow(p3w, "crouch", false)
say(string.format("in the vent: marked as crawling %s, Hog right above didn't catch or chase %s (survivor %s, hog %s), standing up refused %s",
	tostring(D.crawling()[p3w] == true), tostring(safe), tostring(D.survivors()[p3w]), Hv.mode, tostring(D.crouching()[p3w] == true)))
goTo(p3w, Vector3.new(M.start.cx, 0, M.start.cz))
D.STATE.hold = false
MOCK.run(0.3)
D.STATE.hold = true
remoteS.OnServerEvent:fireNow(p3w, "crouch", false)
-- the STUN GUN: pick it up, shoot the Hog, it's frozen for 20 s
local gun = itemPart("Stun Gun")
click(p3w, gun)
local hasGun = D.holding()[p3w] == "Stun Gun"
local H0 = D.getHog()
local R0 = D.roomAt(p3w.Character.Torso.Position)
goTo(p3w, Vector3.new(R0.cx - 4, 0, R0.cz))
H0.pos = Vector3.new(R0.cx + 6, 0, R0.cz)
H0.pause = 0
D.STATE.hold = true
D.shoot(p3w, H0.pos + Vector3.new(0, 3, 0))
local pauseAfter = H0.pause
MOCK.run(1)
D.shoot(p3w, H0.pos + Vector3.new(0, 3, 0) + Vector3.new(0, 40, 0))
MOCK.run(0.5)
say(string.format("stun gun: picked up %s, shot the Hog -> frozen for %.0f s, 2nd shot (missed) -> gun used up %s",
	tostring(hasGun), pauseAfter, tostring(D.holding()[p3w] == nil)))
H0.pause = 0
H0.pos = Vector3.new(M.pen.cx, 0, M.pen.cz)
-- the rest of the puzzle
local order = { { "Blue Key", "Blue Door" }, { "Keycard", "Green Door" }, { "Hammer", "Boards" }, { "Gold Key", "Padlock" }, { "Wrench", "Generator" } }
for _, s in ipairs(order) do
	local part = itemPart(s[1])
	if part then click(p1, part) end
	local lp = lockPart(s[2])
	click(p1, lp)
end
-- the keypad: read the note, try a wrong code (the Hog hears it), then the right one
local notePart
for part in pairs(M.partNote or {}) do notePart = part end
click(p1, notePart)
local noteSaid = lastMsg["kid1:note"] and lastMsg["kid1:note"][1]
local kp, KL = lockPart("Keypad")
click(p1, kp)
local padOpened = lastMsg["kid1:keypad"] ~= nil
local Hk = D.getHog()
Hk.pos, Hk.mode, Hk.path, Hk.pause = Vector3.new(M.byId.dining.cx, 0, M.byId.dining.cz), "patrol", {}, 0
local wrong = M.code == "0000" and "1111" or "0000"
D.enterCode(p1, wrong)
local wentToLook = Hk.mode == "look" and #Hk.path > 0
MOCK.run(1.2)
D.enterCode(p1, noteSaid)
say(string.format("code note says %s (map code %s), keypad opened %s, wrong code -> Hog comes to look %s, right code -> keypad done %s",
	tostring(noteSaid), M.code, tostring(padOpened), tostring(wentToLook), tostring(KL.done)))
MOCK.run(1)
local c0 = p1.leaderstats.Coins.Value
local z = M.exitZone
goTo(p1, Vector3.new((z[1] + z[3]) / 2, 0, (z[2] + z[4]) / 2))
D.STATE.hold = false
MOCK.run(1)
D.STATE.hold = true
local locksOpen = 0
for _, L in ipairs(M.locks) do if L.done then locksOpen = locksOpen + 1 end end
say(string.format("locks open %d/%d, exit open %s, kid1 escaped %s (coins +%d, escapes %d), survivors left %d",
	locksOpen, #M.locks, tostring(M.exitDone), tostring(D.survivors()[p1] == nil), p1.leaderstats.Coins.Value - c0, p1.leaderstats.Escapes.Value,
	(function() local n = 0 for _ in pairs(D.survivors()) do n = n + 1 end return n end)()))

-- the bot Hog hunts: kid2 stands still in the dining room; it should find and catch them, never walking through walls
local p2, p3 = ps[2], ps[3]
goTo(p2, Vector3.new(M.byId.dining.cx + 3, 0, M.byId.dining.cz + 3))
goTo(p3, Vector3.new(M.byId.garage.cx, 0, M.byId.garage.cz))
hog.pos = Vector3.new(M.byId.kitchen.cx, 0, M.byId.kitchen.cz)
hog.path, hog.mode = {}, "patrol"
D.STATE.hold = false
local tCatch, outside, maxStep = nil, 0, 0
local prev = hog.pos
for i = 1, 600 do
	MOCK.run(0.2)
	if not D.roomAt(hog.pos) then outside = outside + 1 end
	maxStep = math.max(maxStep, (hog.pos - prev).magnitude)
	prev = hog.pos
	if not D.survivors()[p2] then tCatch = i * 0.2 break end
end
local jump = fired.caught or 0
say(string.format("bot Hog caught kid2 after %s s (jumpscare sent %d), steps off the map %d, biggest step %.1f studs per 0.2 s, Move value '%s'",
	tCatch and string.format("%.0f", tCatch) or "NEVER", jump, outside, maxStep, hog.mv.Value))
-- traps catch your foot
D.STATE.hold = true
local tp = p3.Character.Torso.Position
D.placeTrap(tp)
D.STATE.hold = false
MOCK.run(0.5)
local ws = p3.Character.Humanoid.WalkSpeed
MOCK.run(6)
say(string.format("trap: kid3 stuck (walk speed %s), after 6 s walk speed %s, traps left on the map %d", tostring(ws), tostring(p3.Character.Humanoid.WalkSpeed), #D.traps()))
-- the end: let the Hog get kid3
for i = 1, 900 do MOCK.run(0.2) if D.STATE.phase ~= "hunt" then break end end
for i = 1, 60 do MOCK.run(0.5) if D.STATE.phase == "lobby" then break end end
MOCK.run(1)
local back = 0
for _, p in ipairs(ps) do if (p.Character.Torso.Position - D.LOBBY).magnitude < 60 then back = back + 1 end end
say(string.format("round over -> '%s', everyone back in the lobby %d/3, map cleared %s, board: '%s'", D.STATE.phase, back, tostring(D.getMap() == nil),
	((lastMsg["kid1:last"] or { "" })[1]:gsub("\n", " / "))))

-- a Player Hog round in the School
touchPad(ps[1], "School") touchPad(ps[2], "School") touchPad(ps[1], "Player") touchPad(ps[2], "Player")
for _ = 1, 100 do MOCK.run(0.5) if D.STATE.phase == "release" then break end end
M = D.getMap()
local hp = D.hogPlayer()
local masked = hp and hp.Character:FindFirstChild("HogSnout") ~= nil
local hasTrap = hp and (hp.Backpack and hp.Backpack:FindFirstChild("Trap") or hp.Character:FindFirstChild("Trap")) ~= nil
for _ = 1, 40 do MOCK.run(0.5) if D.STATE.phase == "hunt" then break end end
local victim
for p in pairs(D.survivors()) do victim = p break end
goTo(victim, hp.Character.Torso.Position - Vector3.new(0, 3, 0) + Vector3.new(2, 0, 0))
MOCK.run(0.5)
local caught = D.survivors()[victim] == nil
local trapTool = hp.Backpack:FindFirstChild("Trap") or hp.Character:FindFirstChild("Trap")
trapTool.Activated:fireNow()
MOCK.run(0.2)
say(string.format("Player Hog round: map %s, hog is %s, pig mask %s, trap tool %s, tagging a survivor catches them %s, trap tool set a trap %s",
	M and M.name or "?", hp and hp.Name or "nobody", tostring(masked), tostring(hasTrap), tostring(caught), tostring(#D.traps() > 0)))
-- the Hog player leaves: the bot takes over
local others = 0
for p in pairs(D.survivors()) do others = others + 1 end
hp.Character.Humanoid.Health = 0
hp.Character.Humanoid.Died:fireNow()
MOCK.run(1)
say(string.format("Hog player died with %d survivors left: bot took over %s", others, tostring(D.getHog() ~= nil)))
-- the other modes: each one a short round
local function finishRound()
	D.STATE.hold = false
	for p in pairs(D.survivors()) do D.catchPlayer(p) end
	for _ = 1, 200 do MOCK.run(0.5) if D.STATE.phase == "lobby" then break end end
	for _, p in ipairs(ps) do if not p.Character or p.Character.Humanoid.Health <= 0 then MOCK.makeCharacter(p) end end
	MOCK.run(1)
end
local function playMode(mode, map)
	finishRound()
	for _, p in ipairs(ps) do touchPad(p, mode) touchPad(p, map) end
	for _ = 1, 100 do MOCK.run(0.5) if D.STATE.phase == "release" then break end end
	for _ = 1, 40 do MOCK.run(0.5) if D.STATE.phase == "hunt" then break end end
	return D.getMap()
end
-- SWARM: three bot Hogs
playMode("Swarm", "Hog Manor")
MOCK.run(10)
local moving = 0
for _, H in ipairs(D.hogs()) do if (H.pos - Vector3.new(D.getMap().pen.cx, 0, D.getMap().pen.cz)).magnitude > 5 then moving = moving + 1 end end
say(string.format("Swarm: mode %s, bot Hogs %d, out of the pen after 10 s %d", D.mode(), #D.hogs(), moving))
-- CROUCH: slower, lower, and the Hog can't see you from as far away
D.STATE.hold = true
local cp
for p in pairs(D.survivors()) do cp = p break end
local M2 = D.getMap()
local H1 = D.hogs()[1]
for i = 2, #D.hogs() do D.hogs()[i].model:Destroy() D.hogs()[i] = nil end
H1.pos = Vector3.new(10, 0, 39)
H1.mode, H1.path, H1.pause = "patrol", {}, 0
for _, p in ipairs(ps) do if p ~= cp and p.Character then p.Character.Torso.CFrame = CFrame.new(-320, 3, 0) end end
cp.Character.Torso.CFrame = CFrame.new(60, 3, 39)
D.STATE.hold = false
MOCK.run(0.25)
local seenStanding = H1.mode == "chase"
D.STATE.hold = true
H1.pos, H1.mode, H1.path = Vector3.new(10, 0, 39), "patrol", {}
remoteS.OnServerEvent:fireNow(cp, "crouch", true)
cp.Character.Torso.CFrame = CFrame.new(60, 3, 39)
D.STATE.hold = false
MOCK.run(0.25)
local seenCrouching = H1.mode == "chase"
D.STATE.hold = true
local rj = cp.Character.HumanoidRootPart.RootJoint
say(string.format("crouch: walk speed %s, body lowered %s, Hog 50 studs down the hall sees you standing %s / crouching %s",
	tostring(cp.Character.Humanoid.WalkSpeed), tostring(rj.C0.p.Y < -1), tostring(seenStanding), tostring(seenCrouching)))
remoteS.OnServerEvent:fireNow(cp, "crouch", false)
-- THE CIRCUS
local CM = playMode("Bot", "Circus")
local inStart = 0
for p in pairs(D.survivors()) do if D.roomAt(p.Character.Torso.Position) == CM.start then inStart = inStart + 1 end end
MOCK.run(15)
say(string.format("Circus round: map %s, survivors in the Food Court %d, items %d, Hog walked out of the lion cage %s",
	CM.name, inStart, (function() local n = 0 for _ in pairs(CM.items) do n = n + 1 end return n end)(),
	tostring((D.getHog().pos - Vector3.new(CM.pen.cx, 0, CM.pen.cz)).magnitude > 10)))
-- INFECTION: whoever the Hog catches becomes a Hog
playMode("Infection", "School")
local first = D.hogPlayer()
local victim2
for p in pairs(D.survivors()) do victim2 = p break end
victim2.Character.Torso.CFrame = first.Character.Torso.CFrame + Vector3.new(2, 0, 0)
MOCK.run(3)
say(string.format("Infection: first Hog %s, caught %s is now a Hog %s (pig mask %s), Hogs %d",
	first and first.Name or "?", victim2.Name, tostring(D.hogPlayers()[victim2] == true), tostring(victim2.Character:FindFirstChild("HogSnout") ~= nil),
	(function() local n = 0 for _ in pairs(D.hogPlayers()) do n = n + 1 end return n end)()))
-- TRAITOR: one survivor is secretly a traitor
playMode("Traitor", "Hog Manor")
local tr = D.traitor()
local victim3
for p in pairs(D.survivors()) do victim3 = p break end
D.STATE.hold = true
for _, H in ipairs(D.hogs()) do H.pos = Vector3.new(D.getMap().pen.cx, 0, D.getMap().pen.cz) H.mode = "wait" end
D.STATE.hold = false
victim3.Character.Torso.CFrame = tr.Character.Torso.CFrame + Vector3.new(2, 0, 0)
MOCK.run(1)
local tagged = D.survivors()[victim3] == nil
say(string.format("Traitor: traitor %s (not a survivor %s, role sent %s), plus a bot Hog %s, traitor's tag caught %s",
	tr and tr.Name or "?", tostring(tr and not D.survivors()[tr]), tostring(lastMsg[(tr and tr.Name or "") .. ":role"] and lastMsg[tr.Name .. ":role"][1] == "traitor"),
	tostring(#D.hogs() > 0), tostring(tagged)))
D.STATE.hold = true

-- the client: HUD, locks list, the jumpscare, the Hog walking smoothly
rawget(MOCK.services.Players, "_p").LocalPlayer = ps[3]
local cam = MOCK.new("Camera", workspace)
cam.Name = "Camera"
cam.CameraType = Enum.CameraType.Custom
rawget(workspace, "_p").CurrentCamera = cam
local before = #MOCK.errors
spawn(assert(loadstring(CLIENT_SOURCE, "=HogClient")))
MOCK.run(2)
local remote = MOCK.services.ReplicatedStorage.HogEvent
local ui = ps[3].PlayerGui:FindFirstChild("HogUI")
if not ui then error(table.concat(out, "\n") .. "\nCLIENT FAILED:\n" .. table.concat(MOCK.errors, "\n"):sub(1, 3000)) end
MOCK.services.RunService.RenderStepped:fireNow()
local menuF
for _, o in ipairs(ui:GetChildren()) do if o.ClassName == "Frame" and o:FindFirstChild("TextButton") then for _, b in ipairs(o:GetChildren()) do if b.Text == ">   PLAY" then menuF = o end end end end
local menuShown, camMenu = menuF and menuF.Visible, cam.CameraType == Enum.CameraType.Scriptable
remote.OnClientEvent:fireNow("votes", { 2, 1 }, { 0, 3, 1, 0, 2, 0 })
remote.OnClientEvent:fireNow("status", "lobby", 10, 0, "", "Bot", "The Hog", 2)
local voteTitleOk = false
for _, o in ipairs(ui:GetDescendants()) do if o.ClassName == "TextLabel" and o.Text == "HOG VOTING - 10" then voteTitleOk = true end end
remote.OnClientEvent:fireNow("status", "hunt", 345, 2, "School", "Bot", "The Hog", 0)
remote.OnClientEvent:fireNow("role", "survivor")
MOCK.services.RunService.RenderStepped:fireNow()
local inGame = not menuF.Visible and cam.CameraType == Enum.CameraType.Custom
remote.OnClientEvent:fireNow("hold", "Red Key")
remote.OnClientEvent:fireNow("big", "THE HOG IS LOOSE!", "Hide")
remote.OnClientEvent:fireNow("toast", "hello", "green")
remote.OnClientEvent:fireNow("caught")
remote.OnClientEvent:fireNow("howto")
local texts = {}
for _, o in ipairs(ui:GetDescendants()) do if o.ClassName == "TextLabel" and o.Text ~= "" and #texts < 40 then table.insert(texts, o.Text) end end
local hasTimer, hasHold, hasLock = false, false, false
for _, t in ipairs(texts) do
	if t == "5:45" then hasTimer = true end
	if t == "RED KEY" then hasHold = true end
	if t == "HOG VOTING - 10" then hasLock = true end
end
-- the Hog walks on this computer
local H = D.getHog()
local m = H.model
H.mv.Value = string.format("%.2f %.2f %.2f %.2f %.2f s 1", 50, 44, 50, 44, 0)
MOCK.run(0.2)
local RS = MOCK.services.RunService
for i = 1, 30 do MOCK.run(1 / 30) RS.RenderStepped:fireNow() end
H.mv.Value = string.format("%.2f %.2f %.2f %.2f %.2f m 2", 50, 44, 110, 44, 15)
for i = 1, 6 do MOCK.run(1 / 30) RS.RenderStepped:fireNow() end
local x0 = m.Torso.Position.X
local legs = {}
for i = 1, 30 do
	MOCK.run(1 / 30)
	RS.RenderStepped:fireNow()
	table.insert(legs, m.LeftLeg.CFrame.p.X - m.Root.CFrame.p.X)
end
local lo, hi = 1e9, -1e9
for _, v in ipairs(legs) do lo, hi = math.min(lo, v), math.max(hi, v) end
say(string.format("client menu: shown at start %s, camera on the Hog hallway %s, after the round starts menu gone + normal camera %s", tostring(menuShown), tostring(camMenu), tostring(inGame)))
say(string.format("client: timer %s, holding %s, vote title %s, jumpscare+how-to shown, Hog moved %.1f studs in 1.5 s (speed 15), legs swing %.2f studs, new errors %d",
	tostring(hasTimer), tostring(hasHold), tostring(voteTitleOk), m.Torso.Position.X - x0, hi - lo, #MOCK.errors - before))

for i = 1, math.min(14, #MOCK.log) do say("  log " .. MOCK.log[i]) end
say("ERRORS: " .. #MOCK.errors)
for i = 1, math.min(8, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 400)) end
TEST_OUT = table.concat(out, "\n")
