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
	c.Torso.CFrame = CFrame.new(0, 267, -330)   -- in the lobby (it floats in the sky)
	ps[i] = p
end
MOCK.run(1)
-- the ship is built and everyone is put on board when the intermission ends
MOCK.run(22)
local ship = D.getShip()
local aboard = 0
for _, p in ipairs(ps) do if ship and D.onShip(p.Character.Torso.Position) then aboard = aboard + 1 end end
local nparts = 0
if ship then for _, o in ipairs(ship.model:GetDescendants()) do if o:IsA("BasePart") then nparts = nparts + 1 end end end
say(string.format("ship built: %s (%d parts, health %s), players on board %d/3, phase %s", tostring(ship ~= nil), nparts, ship and ship.hp or "?", aboard, D.STATE.phase))
-- each disaster on its own, against a fresh ship
local results = {}
for _, name in ipairs({ "Tsunami", "Tornado", "Hurricane", "Meteor Shower", "Kraken", "Shark Attack" }) do
	local before = #MOCK.errors
	D.buildShip()
	ship = D.getShip()
	for _, p in ipairs(ps) do
		p.Character.Humanoid.Health = 100
		p.Character.Torso.CFrame = ship.root.CFrame * CFrame.new(0, -2, 0) * D.deckSpot()
	end
	local stop = D.DIS[name].run()
	MOCK.run(60)
	stop()
	local hurt = 0
	for _, p in ipairs(ps) do hurt = hurt + (100 - p.Character.Humanoid.Health) end
	table.insert(results, string.format("%s: ship lost %d%%%s, players lost %d health, new errors %d", name,
		math.floor(100 * (ship.max - ship.hp) / ship.max), ship.sinking and " (SANK)" or "", hurt, #MOCK.errors - before))
	MOCK.run(2)
end
for _, r in ipairs(results) do say(r) end
-- sinking: the lifeboats drop into the sea and the water hurts
D.buildShip()
ship = D.getShip()
D.damageShip(ship.max + 10)
MOCK.run(15)
local floating = 0
for _, lb in ipairs(ship.lifeboats) do if lb.hull and math.abs(lb.hull.Position.Y - (D.SEA.level + 1.2)) < 3 then floating = floating + 1 end end
local swimmer = ps[1].Character
swimmer.Humanoid.Health = 100
swimmer.Torso.CFrame = CFrame.new(0, -1, -900)
MOCK.run(5)
say(string.format("sinking: ship went down to y %.0f, lifeboats floating %d/%d; 5 s in the water: health %d, swimming %s",
	ship.root.Position.Y, floating, #ship.lifeboats, swimmer.Humanoid.Health, tostring(swimmer.Torso:FindFirstChild("Swim") ~= nil)))
-- a whole round with coins
for _, p in ipairs(ps) do p.Character.Humanoid.Health = 100 p.Character.Torso.CFrame = CFrame.new(0, 267, -330) end
local c0 = ps[2].leaderstats.Coins.Value
local sv0 = ps[2].leaderstats.Survived.Value
for _ = 1, 400 do MOCK.run(0.5) if D.STATE.phase == "results" then break end end
MOCK.run(7)
say(string.format("after a round: player 2 coins %d -> %d, survived +%d, back in the lobby: %s; messages: %s", c0, ps[2].leaderstats.Coins.Value,
	ps[2].leaderstats.Survived.Value - sv0, tostring((ps[2].Character.Torso.Position - Vector3.new(0, 267, -330)).magnitude < 40),
	(function() local t = {} for k, v in pairs(fired) do table.insert(t, k .. "=" .. v) end table.sort(t) return table.concat(t, " ") end)()))
-- the ship rocks on the swells
D.buildShip()
D.SEA.waves = 3
local rolls, pitches, heave = {}, {}, {}
for _ = 1, 40 do
	MOCK.run(0.5)
	local sh = D.getShip()
	table.insert(rolls, sh.roll) table.insert(pitches, sh.pitch) table.insert(heave, sh.dy)
end
local function range(t) local lo, hi = 1e9, -1e9 for _, v in ipairs(t) do lo = math.min(lo, v) hi = math.max(hi, v) end return hi - lo end
say(string.format("ship rocking over 20 s: roll range %.1f deg, pitch range %.1f deg, up/down %.1f studs", math.deg(range(rolls)), math.deg(range(pitches)), range(heave)))
-- someone who falls off the sky lobby in the intermission is put back up
for _ = 1, 400 do MOCK.run(0.5) if D.STATE.phase == "intermission" then break end end
ps[3].Character.Humanoid.Health = 100
ps[3].Character.Torso.CFrame = CFrame.new(50, -1, 50)
MOCK.run(1)
say("fell in the sea during the intermission -> back in the lobby: " .. tostring(ps[3].Character.Torso.Position.Y > 200))
-- the swells on a player's computer
local before = #MOCK.errors
rawget(MOCK.services.Players, "_p").LocalPlayer = ps[1]
local cam = MOCK.new("Camera", workspace)
workspace.CurrentCamera = cam
cam.CoordinateFrame = CFrame.new(0, 40, -600)
spawn(assert(loadstring(CLIENT_SOURCE, "=OceanClient")))
MOCK.run(3)
local sw = cam:FindFirstChild("Swells")
local ys = {}
if sw then for _, t in ipairs(sw:GetChildren()) do table.insert(ys, t.CFrame.p.Y) end end
say(string.format("client swells: %d tiles, heights range %.1f studs, ship health bar shown: %s, new errors %d", #ys, range(ys),
	tostring(ps[1].PlayerGui:FindFirstChild("OceanUI") ~= nil), #MOCK.errors - before))
say("errors: " .. #MOCK.errors)
for i = 1, math.min(8, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 300)) end
_G.TEST_OUT = table.concat(out, "\n")
