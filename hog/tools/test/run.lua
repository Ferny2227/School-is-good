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
	if k == "Activated" then
		local props = rawget(o, "_p")
		props.Activated = props.Activated or MOCK.Event("Activated")
		return props.Activated
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
for _, name in ipairs({ "Hog Manor", "School" }) do
	local before = #MOCK.errors
	local M = D.buildMap(name)
	for _, it in ipairs(M.def.items) do D.spawnItem(it[1]) end
	local parts = count(M.model, function(o) return o:IsA("BasePart") end)
	-- furniture in a doorway?
	local inDoor = 0
	for _, o in ipairs(M.model:GetChildren()) do
		if o:IsA("BasePart") and o.Name ~= "Wall" and o.Name ~= "Floor" and o.Name ~= "Ceiling" and o.Name ~= "Ground" and o.Name ~= "Roof"
			and o.Name ~= "Runner" and o.Name ~= "Boards" and o.Name ~= "Padlock" and o.Name ~= "Bolt" and not o.Name:find("Fuse") and not o.Name:find("Door") and not o.Name:find("Gate") and o.Name ~= "Lamp" then
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
		if R and (want == "open" and R.id ~= "bedroom" and R.id ~= "cellar" and R.id ~= "lab" and R.id ~= "office" and R.id ~= "pen" or want == R.id) then itemsOk = itemsOk + 1 end
	end
	table.sort(where)
	say(string.format("%s: %d parts, %d rooms, %d path points, furniture in doorways %d, Hog reaches %d/%d rooms (%d before the locks open), %d item spots, items in allowed rooms %d/%d [%s], new errors %d",
		name, parts, #M.rooms, #M.nodes, inDoor, reach, #M.rooms, reach0, spots, itemsOk, #M.def.items, table.concat(where, " "), #MOCK.errors - before))
	M.model:Destroy()
end

-- three players in the lobby vote: Hog Manor, Bot Hog
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
	local kind = (name == "Bot Hog" or name == "Player Hog") and "mode" or "map"
	remoteS.OnServerEvent:fireNow(p, "vote", kind, name)
	return true
end
-- nobody pressed PLAY yet: the countdown waits
MOCK.run(5)
local waited = D.STATE.left
for _, p in ipairs(ps) do remoteS.OnServerEvent:fireNow(p, "play") end
local okv = touchPad(ps[1], "Hog Manor") and touchPad(ps[2], "Hog Manor") and touchPad(ps[3], "School")
	and touchPad(ps[1], "Bot Hog") and touchPad(ps[2], "Bot Hog")
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
local function goTo(p, pos) p.Character.Torso.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
local function click(p, part)
	goTo(p, part.Position + Vector3.new(2, 0, 0))
	part.ClickDetector.MouseClick:fireNow(p)
end
local function lockPart(name) for _, L in ipairs(M.locks) do if L.name == name then return L.parts[1], L end end end
local hammer = itemPart("Hammer")
click(p1, hammer)
local h1 = D.holding()[p1]
local hasTool = p1.Character:FindFirstChild("Hammer") ~= nil
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
-- no clicking: walk over an item with empty hands, walk up to its lock
local p3w = ps[3]
local bk = itemPart("Blue Key")
D.STATE.hold = false
goTo(p3w, bk.Position + Vector3.new(1, 0, 1))
MOCK.run(0.5)
local walked = D.holding()[p3w]
local bd, BL = lockPart("Blue Door")
goTo(p3w, bd.Position + Vector3.new(0, -3, 4))
MOCK.run(0.5)
D.STATE.hold = true
say(string.format("walking over the Blue Key picked it up: %s; walking up to the Blue Door opened it: %s", tostring(walked), tostring(BL.done)))
-- the rest of the puzzle
local order = { { "Blue Key", "Blue Door" }, { "Hammer", "Boards" }, { "Gold Key", "Padlock" }, { "Wrench", "Bolt" } }
for _, s in ipairs(order) do
	local part = itemPart(s[1])
	if part then click(p1, part) end
	local lp = lockPart(s[2])
	click(p1, lp)
end
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
local back = 0
for _, p in ipairs(ps) do if (p.Character.Torso.Position - D.LOBBY).magnitude < 60 then back = back + 1 end end
say(string.format("round over -> '%s', everyone back in the lobby %d/3, map cleared %s, board: '%s'", D.STATE.phase, back, tostring(D.getMap() == nil),
	((lastMsg["kid1:last"] or { "" })[1]:gsub("\n", " / "))))

-- a Player Hog round in the School
touchPad(ps[1], "School") touchPad(ps[2], "School") touchPad(ps[1], "Player Hog") touchPad(ps[2], "Player Hog")
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
MOCK.services.RunService.RenderStepped:fireNow()
local menuF
for _, o in ipairs(ui:GetChildren()) do if o.ClassName == "Frame" and o:FindFirstChild("TextButton") then for _, b in ipairs(o:GetChildren()) do if b.Text == ">  PLAY" then menuF = o end end end end
local menuShown, camMenu = menuF and menuF.Visible, cam.CameraType == Enum.CameraType.Scriptable
remote.OnClientEvent:fireNow("votes", { 2, 1 }, { 0, 3 })
remote.OnClientEvent:fireNow("status", "hunt", 345, 2, "School", "Bot Hog", "The Hog")
remote.OnClientEvent:fireNow("role", "survivor")
MOCK.services.RunService.RenderStepped:fireNow()
local inGame = not menuF.Visible and cam.CameraType == Enum.CameraType.Custom
remote.OnClientEvent:fireNow("hold", "Red Key")
remote.OnClientEvent:fireNow("locks", { { "Red Door", "Red Key", false, false }, { "Boards", "Hammer", true, true }, { "Padlock", "Gold Key", false, true } }, "School")
remote.OnClientEvent:fireNow("big", "THE HOG IS LOOSE!", "Hide")
remote.OnClientEvent:fireNow("toast", "hello", "green")
remote.OnClientEvent:fireNow("caught")
remote.OnClientEvent:fireNow("howto")
local texts = {}
for _, o in ipairs(ui:GetDescendants()) do if o.ClassName == "TextLabel" and o.Text ~= "" and #texts < 40 then table.insert(texts, o.Text) end end
local hasTimer, hasHold, hasLock = false, false, false
for _, t in ipairs(texts) do
	if t == "TIME LEFT 5:45" then hasTimer = true end
	if t == "HOLDING: Red Key" then hasHold = true end
	if t:find("%[OPEN%] Boards") then hasLock = true end
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
say(string.format("client: timer %s, holding %s, locks list %s, jumpscare+how-to shown, Hog moved %.1f studs in 1.5 s (speed 15), legs swing %.2f studs, new errors %d",
	tostring(hasTimer), tostring(hasHold), tostring(hasLock), m.Torso.Position.X - x0, hi - lo, #MOCK.errors - before))

for i = 1, math.min(14, #MOCK.log) do say("  log " .. MOCK.log[i]) end
say("ERRORS: " .. #MOCK.errors)
for i = 1, math.min(8, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 400)) end
TEST_OUT = table.concat(out, "\n")
