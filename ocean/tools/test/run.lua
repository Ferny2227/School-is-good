-- Runs OceanServer in the mock Roblox: boats, driving, swimming, every disaster, rounds and coins.
local MOCK = MOCK
local out = {}
local function say(s) table.insert(out, s) end
local realNew = Instance.new
Instance.new = function(cls, parent)
	local o = realNew(cls, parent)
	if cls == "Humanoid" then o.Health, o.MaxHealth, o.WalkSpeed, o.Sit, o.MoveDirection = 100, 100, 16, false, Vector3.new()
	elseif cls == "IntValue" or cls == "NumberValue" then o.Value = 0
	elseif cls == "VehicleSeat" then o.Throttle, o.Steer = 0, 0 end
	return o
end
local mt = getmetatable(workspace)
local oldIndex = mt.__index
mt.__index = function(o, k)
	if k == "TakeDamage" then return function(self, d) self.Health = math.max(0, self.Health - d) end end
	if k == "Clear" then return function() end end
	return oldIndex(o, k)
end
local map = MOCK.new("Model", workspace) map.Name = "AirportMap"
MOCK.part(map, "Spawn", Vector3.new(4, 1, 4), CFrame.new())
local Lighting = MOCK.services.Lighting
Lighting.TimeOfDay, Lighting.FogEnd, Lighting.FogColor, Lighting.OutdoorAmbient = "14:00:00", 100000, Color3.new(), Color3.new()
local fired = {}
MOCK.onFireClient = function(remote, p, what) fired[what] = (fired[what] or 0) + 1 end
local fn = assert(loadstring(SERVER_SOURCE, "=OceanServer"))
spawn(fn)
MOCK.run(1)
local D = _G.OceanDebug
assert(D, "server did not start: " .. table.concat(MOCK.errors, "\n"))
say("old map removed: " .. tostring(workspace:FindFirstChild("AirportMap") == nil) .. ", world built: " .. tostring(workspace:FindFirstChild("Ocean World") ~= nil))
local ps = {}
for i = 1, 3 do
	local p = MOCK.addPlayer("sailor" .. i, i)
	MOCK.run(0.3)
	local c = MOCK.makeCharacter(p)
	c.Torso.CFrame = CFrame.new(D.LOBBY_AT + Vector3.new(0, 6, 20))   -- in the sky lobby house
	ps[i] = p
end
MOCK.run(1)
say("terrain water: " .. tostring(D.terrainWater))
-- the three boats: parts, rooms, places to stand
local function count(m, pred) local n = 0 for _, o in ipairs(m:GetDescendants()) do if pred(o) then n = n + 1 end end return n end
for _, kind in ipairs({ "Cruise Liner", "Pirate Galleon", "Navy Destroyer" }) do
	local before = #MOCK.errors
	local sh = D.buildShip(kind)
	local parts = count(sh.model, function(o) return o:IsA("BasePart") end)
	local rooms = count(sh.model, function(o) return o.Name:match("Floor$") ~= nil and o.Name ~= "LifeboatFloor" end)
	local seats = count(sh.model, function(o) return o.ClassName == "Seat" end)
	local unwelded = 0
	for _, o in ipairs(sh.model:GetDescendants()) do if o:IsA("BasePart") and not o.Anchored then unwelded = unwelded + 1 end end
	say(string.format("%s: %d parts, %d rooms, %d seats, %d breakable, %d lifeboats, %d spots, unanchored parts %d, new errors %d",
		kind, parts, rooms, seats, #sh.breakable, #sh.lifeboats, #sh.spots, unwelded, #MOCK.errors - before))
end
-- voting in the lobby house: 2 votes for the galleon + Halloween, 1 for the destroyer + Sunset
local function touchPad(p, kind, name)
	for _, o in ipairs(workspace:GetDescendants()) do
		if o.Name == "VotePad" then
			local lab = nil
			-- the sign next to each pad says its name
			for _, s in ipairs(o.Parent:GetChildren()) do
				if s.Name == "VoteSign" and (s.CFrame.p - o.CFrame.p).magnitude < 8 then lab = s end
			end
			local t = lab and lab:FindFirstChild("SurfaceGui") and lab.SurfaceGui:FindFirstChild("TextLabel")
			if t and t.Text:sub(1, #name) == name then o.Touched:fire(p.Character.Torso) return true end
		end
	end
	return false
end
local okv = touchPad(ps[1], "boat", "Pirate Galleon") and touchPad(ps[2], "boat", "Pirate Galleon") and touchPad(ps[3], "boat", "Navy Destroyer")
	and touchPad(ps[1], "theme", "Halloween") and touchPad(ps[2], "theme", "Halloween") and touchPad(ps[3], "theme", "Sunset")
MOCK.run(1)
-- the round starts: the winners are used and everyone goes aboard
for _ = 1, 100 do MOCK.run(0.5) if D.STATE.phase == "boarding" then break end end
MOCK.run(1)
local ship = D.getShip()
local aboard = 0
for _, p in ipairs(ps) do if ship and D.onShip(p.Character.Torso.Position) then aboard = aboard + 1 end end
say(string.format("votes cast: %s; round started with the %s, theme %s, players on board %d/3", tostring(okv), ship and ship.kind or "?", D.getTheme(), aboard))
-- hold the round loop so the next tests aren't mixed up with a real round's disaster
D.STATE.hold = true
for _ = 1, 400 do MOCK.run(0.5) if D.STATE.phase == "intermission" then break end end
-- each disaster on its own, against a fresh cruise liner
local results = {}
for _, name in ipairs({ "Tsunami", "Tornado", "Hurricane", "Meteor Shower", "Kraken", "Shark Attack" }) do
	local before = #MOCK.errors
	D.buildShip("Cruise Liner")
	ship = D.getShip()
	for _, p in ipairs(ps) do
		p.Character.Humanoid.Health = 100
		p.Character.Torso.CFrame = D.shipFrame() * D.deckSpot()
	end
	local stop = D.DIS[name].run()
	local hi, lo, air, maxPitch = -1e9, 1e9, 0, 0
	for _ = 1, 100 do
		MOCK.run(0.5)
		hi, lo = math.max(hi, ship.dy), math.min(lo, ship.dy)
		air, maxPitch = math.max(air, ship.air or 0), math.max(maxPitch, math.abs(ship.pitch))
	end
	stop()
	table.insert(results, string.format("%s: ship lost %d%%%s, boat went up %.0f / down %.0f studs, lifted into the air %.0f, max pitch %.0f deg, new errors %d",
		name, math.floor(100 * (ship.max - ship.hp) / ship.max), ship.sinking and " (SANK)" or "", hi, -lo, air, math.deg(maxPitch), #MOCK.errors - before))
	MOCK.run(2)
end
for _, r in ipairs(results) do say(r) end
-- sinking: the lifeboats drop into the sea and the water hurts
D.buildShip("Navy Destroyer")
ship = D.getShip()
D.damageShip(ship.max + 10)
MOCK.run(15)
local floating = 0
for _, lb in ipairs(ship.lifeboats) do
	local p = lb.hull and lb.hull.Position
	if p and math.abs(p.Y - (D.SEA.level + 1.2 + D.waveAt(p.X, p.Z))) < 2 then floating = floating + 1 end
end
say(string.format("sinking: destroyer went down %.0f studs, lifeboats floating %d/%d", -ship.dy, floating, #ship.lifeboats))
-- the boat rocks with every swell: bow up, then stern up, again and again
D.buildShip("Pirate Galleon")
D.SEA.waves, D.SEA.amp = 60, 60
local function rock(seconds)
	local pitches, rolls, flips, lastSign = {}, {}, 0, 0
	local sh = D.getShip()
	for _ = 1, seconds * 4 do
		MOCK.run(0.25)
		table.insert(pitches, sh.pitch) table.insert(rolls, sh.roll)
		local sg = sh.pitch > 0.02 and 1 or sh.pitch < -0.02 and -1 or 0
		if sg ~= 0 and sg ~= lastSign then flips = flips + 1 lastSign = sg end
	end
	local function range(t) local lo, hi = 1e9, -1e9 for _, v in ipairs(t) do lo = math.min(lo, v) hi = math.max(hi, v) end return hi - lo end
	return math.deg(range(pitches)), math.deg(range(rolls)), flips
end
local p1, r1, f1 = rock(30)
say(string.format("galleon in normal swells (30 s): pitch range %.1f deg, roll range %.1f deg, bow-up/bow-down changes %d", p1, r1, f1))
local hp0 = D.getShip().hp
D.rogue(30, 600, false)
local p2, r2, f2 = rock(45)
say(string.format("a set of big waves rolls through (45 s): pitch range %.1f deg, roll %.1f deg, changes %d, ship lost %d hp of %d", p2, r2, f2, hp0 - D.getShip().hp, D.getShip().max))
-- the server's sea and the drawn sea agree: water height under the bow equals what the client maths gives
say(string.format("sea height at the bow now: %.1f studs (amp %.1f)", D.waveAt(0, -650 - 60), D.SEA.amp))
-- a whole round, coins, back to the lobby
D.STATE.hold = false
for _, p in ipairs(ps) do p.Character.Humanoid.MaxHealth = 1e6 p.Character.Humanoid.Health = 1e6 end
local c0, sv0 = ps[2].leaderstats.Coins.Value, ps[2].leaderstats.Survived.Value
for _ = 1, 400 do MOCK.run(0.5) if D.STATE.phase == "results" then break end end
MOCK.run(7)
say(string.format("after a round: player 2 coins %d -> %d, survived +%d, back in the lobby: %s", c0, ps[2].leaderstats.Coins.Value,
	ps[2].leaderstats.Survived.Value - sv0, tostring((ps[2].Character.Torso.Position - D.LOBBY_AT).magnitude < 80)))
-- someone who falls off the sky lobby in the intermission is put back up
ps[3].Character.Humanoid.Health = 100
ps[3].Character.Torso.CFrame = CFrame.new(50, -1, 50)
MOCK.run(1)
say("fell in the sea during the intermission -> back in the lobby: " .. tostring(ps[3].Character.Torso.Position.Y > 200))
-- the sea effects on a player's computer
local before = #MOCK.errors
rawget(MOCK.services.Players, "_p").LocalPlayer = ps[1]
local cam = MOCK.new("Camera", workspace)
workspace.CurrentCamera = cam
cam.CoordinateFrame = CFrame.new(0, 40, -600)
local csh = D.buildShip("Cruise Liner")
D.SEA.waves, D.SEA.amp = 7, 7
local top
for _, o in ipairs(csh.model:GetDescendants()) do if o:IsA("BasePart") and (not top or o.Position.Y > top.Position.Y) then top = o end end
local hull0, top0 = csh.root.Position, top.Position
spawn(assert(loadstring(CLIENT_SOURCE, "=OceanClient")))
MOCK.run(3)
spawn(assert(loadstring(CLIENT_SOURCE, "=OceanClient")))   -- respawned: a second copy of the script starts
MOCK.run(2)
local want = D.shipFrame() * csh.rest:inverse()
say(string.format("client moves the whole boat: hull moved %.1f, top part (%s) moved %.1f, top part where the server says %.1f studs off, still the same distance apart: %s",
	(csh.root.Position - hull0).magnitude, top.Name, (top.Position - top0).magnitude, ((want * CFrame.new(top0)).p - top.Position).magnitude,
	tostring(math.abs((top.Position - csh.root.Position).magnitude - (top0 - hull0).magnitude) < 0.01)))
local fx = cam:FindFirstChild("SeaFX")
-- the drawn surface follows the swells: slabs at many different heights, several colours
local ys, cols, n = {}, {}, 0
if fx then for _, c in ipairs(fx:GetChildren()) do
	local hasMesh = false
	for _, m in ipairs(c:GetChildren()) do if m.ClassName == "SpecialMesh" then hasMesh = true end end
	if hasMesh then n = n + 1 ys[math.floor(c.Position.Y / 2)] = true cols[tostring(c.Color or c.BrickColor)] = true end
end end
local ny, nc = 0, 0 for _ in pairs(ys) do ny = ny + 1 end for _ in pairs(cols) do nc = nc + 1 end
say(string.format("client surface: %d strips at %d different heights, %d colours", n, ny, nc))
say(string.format("client sea effects: %d parts, ship bar shown: %s, new errors %d", fx and #fx:GetChildren() or 0,
	tostring(ps[1].PlayerGui:FindFirstChild("OceanUI") ~= nil), #MOCK.errors - before))
say("errors: " .. #MOCK.errors)
for i = 1, math.min(8, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 300)) end
_G.TEST_OUT = table.concat(out, "\n")
