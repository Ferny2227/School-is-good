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
	c.Humanoid.MoveDirection = Vector3.new()
	c.Humanoid.Sit = false
	c.Torso.CFrame = CFrame.new(0, 6, -40)   -- on the pier by the dockmaster
	ps[i] = p
end
MOCK.run(1)
say("coins to start: " .. ps[1].leaderstats.Coins.Value)
-- boats: a free rowboat, a speedboat bought, and one too expensive
local ev = MOCK.services.ReplicatedStorage.OceanEvent.OnServerEvent
ev:fire(ps[1], "buyBoat", "Rowboat")
ev:fire(ps[2], "buyBoat", "Yacht")
ps[3].leaderstats.Coins.Value = 500
ev:fire(ps[3], "buyBoat", "Fishing Boat")
MOCK.run(1)
say(string.format("boats: %d (player 1 %s, player 2 %s (too poor), player 3 %s, coins left %d)", #D.boats,
	tostring(D.boatOf[ps[1]] and D.boatOf[ps[1]].kind.key), tostring(D.boatOf[ps[2]] and D.boatOf[ps[2]].kind.key),
	tostring(D.boatOf[ps[3]] and D.boatOf[ps[3]].kind.key), ps[3].leaderstats.Coins.Value))
-- drive the rowboat out to sea
local b = D.boatOf[ps[1]]
local start = b.pos
b.seat.Throttle = 1
MOCK.run(6)
b.seat.Throttle = 0
MOCK.run(2)   -- let it coast to a stop (the mock has no physics to carry the player along)
say(string.format("rowboat drove %.0f studs, now at (%.0f, %.1f, %.0f)", (b.pos - start).magnitude, b.pos.X, b.pos.Y, b.pos.Z))
-- a player standing on deck gets carried; a player in the water swims
local deck = b.root.CFrame * CFrame.new(0, 5, 0)
ps[1].Character.Torso.CFrame = deck
ps[2].Character.Torso.CFrame = CFrame.new(300, -1, -300)
MOCK.run(0.5)
local l = b.root.CFrame:inverse() * ps[1].Character.Torso.Position
say(string.format("deck check: local %.1f %.1f %.1f, health %s, sit %s, swim %s", l.X, l.Y, l.Z, tostring(ps[1].Character.Humanoid.Health), tostring(ps[1].Character.Humanoid.Sit), tostring(ps[1].Character.Torso:FindFirstChild("Swim") ~= nil)))
say("player on deck carried: " .. tostring(ps[1].Character.Torso:FindFirstChild("OnBoat") ~= nil) ..
	", player in the sea swimming: " .. tostring(ps[2].Character.Torso:FindFirstChild("Swim") ~= nil))
-- every disaster, one after the other
for _, name in ipairs({ "Tornado", "Tsunami", "Hurricane", "Meteor Shower", "Whirlpool", "Shark Attack" }) do
	local before = #MOCK.errors
	for _, p in ipairs(ps) do p.Character.Humanoid.Health = 100 end
	for _, bb in ipairs(D.boats) do bb.hp = bb.kind.hp end
	local stop = D.DIS[name].run(30)
	MOCK.run(name == "Tsunami" and 45 or 25)
	local hurt = 0
	for _, p in ipairs(ps) do hurt = hurt + (100 - p.Character.Humanoid.Health) end
	local bdmg = 0
	for _, bb in ipairs(D.boats) do bdmg = bdmg + (bb.kind.hp - bb.hp) end
	local extra = ""
	if name == "Tsunami" then extra = string.format(", sea level %.1f (island flooded)", D.SEA.level) end
	stop()
	MOCK.run(3)
	say(string.format("%s: players lost %d health, boats lost %d health%s, new errors %d", name, hurt, bdmg, extra, #MOCK.errors - before))
end
say(string.format("after the tsunami the sea is back at %.1f", D.SEA.level))
-- sinking
local victim = D.boatOf[ps[3]] or D.boats[1]
if victim then
	D.damageBoat(victim, 5000, "test")
	MOCK.run(10)
	say("boat with no health sank and was removed: " .. tostring(victim.model.Parent == nil))
end
-- a whole round: intermission, disaster, survivors paid
for _, p in ipairs(ps) do p.Character.Humanoid.Health = 100 end
local c0 = ps[1].leaderstats.Coins.Value
MOCK.run(110)
say(string.format("after a round: player 1 coins %d -> %d, survived %d; messages sent: %s", c0, ps[1].leaderstats.Coins.Value,
	ps[1].leaderstats.Survived.Value, (function() local t = {} for k, v in pairs(fired) do table.insert(t, k .. "=" .. v) end table.sort(t) return table.concat(t, " ") end)()))
say("errors: " .. #MOCK.errors)
for i = 1, math.min(8, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 300)) end
_G.TEST_OUT = table.concat(out, "\n")
