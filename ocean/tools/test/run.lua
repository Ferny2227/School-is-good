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
	for _, o in ipairs(sh.model:GetDescendants()) do if o:IsA("BasePart") and o.Anchored and o ~= sh.root then unwelded = unwelded + 1 end end
	say(string.format("%s: %d parts, %d rooms, %d seats, %d breakable, %d lifeboats, %d spots, loose anchored parts %d, new errors %d",
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
	MOCK.run(40)
	stop()
	table.insert(results, string.format("%s: ship lost %d%%%s, new errors %d", name, math.floor(100 * (ship.max - ship.hp) / ship.max), ship.sinking and " (SANK)" or "", #MOCK.errors - before))
	MOCK.run(2)
end
for _, r in ipairs(results) do say(r) end
-- sinking: the lifeboats drop into the sea and the water hurts
D.buildShip("Navy Destroyer")
ship = D.getShip()
D.damageShip(ship.max + 10)
MOCK.run(15)
local floating = 0
for _, lb in ipairs(ship.lifeboats) do if lb.hull and math.abs(lb.hull.Position.Y - (D.SEA.level + 1.2)) < 4 then floating = floating + 1 end end
say(string.format("sinking: destroyer went down to y %.0f, lifeboats floating %d/%d", ship.root.Position.Y, floating, #ship.lifeboats))
-- the boat rocks
D.buildShip("Pirate Galleon")
D.SEA.waves = 3
local rolls, pitches = {}, {}
for _ = 1, 40 do MOCK.run(0.5) local sh = D.getShip() table.insert(rolls, sh.roll) table.insert(pitches, sh.pitch) end
local function range(t) local lo, hi = 1e9, -1e9 for _, v in ipairs(t) do lo = math.min(lo, v) hi = math.max(hi, v) end return hi - lo end
say(string.format("galleon rocking over 20 s: roll %.1f deg, pitch %.1f deg", math.deg(range(rolls)), math.deg(range(pitches))))
-- a whole round, coins, back to the lobby
for _, p in ipairs(ps) do p.Character.Humanoid.Health = 100 end
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
spawn(assert(loadstring(CLIENT_SOURCE, "=OceanClient")))
MOCK.run(3)
local fx = cam:FindFirstChild("SeaFX")
say(string.format("client sea effects: %d parts, ship bar shown: %s, new errors %d", fx and #fx:GetChildren() or 0,
	tostring(ps[1].PlayerGui:FindFirstChild("OceanUI") ~= nil), #MOCK.errors - before))
say("errors: " .. #MOCK.errors)
for i = 1, math.min(8, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 300)) end
_G.TEST_OUT = table.concat(out, "\n")
