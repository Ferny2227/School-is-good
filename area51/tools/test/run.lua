-- Runs ZombieDirector in the mock Roblox (roblox/tools/test/mockrbx.lua): kills pay 30, new zombie types appear,
-- the boss comes when all are dead and has a health bar, and everyone comes back after it dies.
local MOCK = MOCK
local out = {}
local function say(s) table.insert(out, s) end
local Inst = getmetatable(workspace).__index
-- a few things the airport mock doesn't need
local died = {}
local function addMethods(o)
	if o.ClassName == "Humanoid" then
		o.Health, o.MaxHealth, o.WalkSpeed = 100, 100, 16
	elseif o.ClassName == "IntValue" or o.ClassName == "NumberValue" then
		o.Value = 0
	end
end
local realNew = Instance.new
Instance.new = function(cls, parent)
	local o = realNew(cls, parent)
	addMethods(o)
	return o
end
local mt = getmetatable(workspace)
local oldIndex = mt.__index
mt.__index = function(o, k)
	if k == "TakeDamage" then return function(self, d) self.Health = math.max(0, self.Health - d) end end
	if k == "MoveTo" then return function(self, v) rawget(self, "_p").moveTarget = v end end
	if k == "toObjectSpace" then return nil end
	return oldIndex(o, k)
end
local function part(parent, name, size, pos)
	local p = MOCK.part(parent, name, size, CFrame.new(pos))
	return p
end
local function zombie(name, pos, broken)
	local m = MOCK.new("Model", workspace)
	m.Name = name
	if not broken then
		part(m, "Head", Vector3.new(2, 1, 1), pos + Vector3.new(0, 4.5, 0))
		part(m, "Torso", Vector3.new(2, 2, 1), pos + Vector3.new(0, 3, 0))
		part(m, "Left Leg", Vector3.new(1, 2, 1), pos + Vector3.new(-0.5, 1, 0))
		part(m, "zarm", Vector3.new(1, 1, 3), pos + Vector3.new(1.5, 3.5, -1))
	end
	local h = Instance.new("Humanoid", m)
	h.Name = broken and "Zombie" or "Humanoid"
	return m
end
for i = 1, 6 do zombie(i % 2 == 0 and "Zombie" or "Soldier Zombie", Vector3.new(i * 30, 0, 100)) end
zombie("Crawler", Vector3.new(0, 0, 0), true)
local players = {}
for i = 1, 2 do
	local p = MOCK.addPlayer("p" .. i, i)
	MOCK.run(0.5)
	local c = MOCK.makeCharacter(p)
	c.Torso.CFrame = CFrame.new(400 + i * 10, 3, 400)
	players[i] = p
end
-- Died events whenever a humanoid's health reaches 0
spawn(function()
	while true do
		wait(0.1)
		for _, o in ipairs(workspace:GetDescendants()) do
			if o.ClassName == "Humanoid" and (o.Health or 100) <= 0 and not died[o] then
				died[o] = true
				o.Died:fire()
			end
		end
	end
end)
local fn = assert(loadstring(DIRECTOR_SOURCE, "=ZombieDirector"))
spawn(fn)
MOCK.run(8)
local function zombies()
	local list = {}
	for _, m in ipairs(workspace:GetChildren()) do
		local h = m:FindFirstChild("Humanoid")
		if m.ClassName == "Model" and h and not MOCK.services.Players:GetPlayerFromCharacter(m) and h.Health > 0 then table.insert(list, m) end
	end
	return list
end
local kinds = {}
for _, m in ipairs(zombies()) do kinds[m.Name] = (kinds[m.Name] or 0) + 1 end
local ks = {}
for k, v in pairs(kinds) do table.insert(ks, k .. "=" .. v) end
table.sort(ks)
say("zombies at start: " .. table.concat(ks, " ") .. "; broken Crawler removed: " .. tostring(workspace:FindFirstChild("Crawler") == nil))
say("leaderstats: " .. tostring(players[1]:FindFirstChild("leaderstats") ~= nil and players[1].leaderstats:FindFirstChild("Credits") ~= nil))
-- a bomber explodes when a player gets close: damage must be small
local bomber
for _, m in ipairs(zombies()) do if m.Name == "Bomber Zombie" then bomber = m end end
if bomber then
	local c = players[2].Character
	c.Torso.CFrame = bomber.Torso.CFrame * CFrame.new(3, 0, 0)
	local before = c.Humanoid.Health
	MOCK.run(1)
	say(string.format("bomber exploded next to a player: player health %d -> %d, bomber dead %s", before, c.Humanoid.Health, tostring(bomber.Humanoid.Health <= 0)))
	c.Humanoid.Health = 100
	c.Torso.CFrame = CFrame.new(420, 3, 400)
end
-- shooters shoot
local shooter
for _, m in ipairs(zombies()) do if m.Name == "Shooter Zombie" then shooter = m end end
if shooter then
	players[1].Character.Torso.CFrame = shooter.Torso.CFrame * CFrame.new(0, 0, 30)
	MOCK.run(3)
	local balls = 0
	for _, o in ipairs(workspace:GetChildren()) do if o.Name == "SlimeBall" then balls = balls + 1 end end
	say("shooter's slime balls in the air: " .. balls)
	players[1].Character.Torso.CFrame = CFrame.new(410, 3, 400)
end
-- player 1 kills every zombie
local killed = 0
for _, m in ipairs(zombies()) do
	local h = m.Humanoid
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = players[1]
	tag.Parent = h
	h.Health = 0
	killed = killed + 1
end
MOCK.run(3)
say(string.format("player 1 killed %d zombies: Credits %d (expected %d)", killed, players[1].leaderstats.Credits.Value, killed * 30))
local king = workspace:FindFirstChild("ZOMBIE KING")
local bar = players[2].PlayerGui:FindFirstChild("BossBar")
say("boss spawned: " .. tostring(king ~= nil) .. (king and (", health " .. king.Humanoid.Health .. "/" .. king.Humanoid.MaxHealth) or "") ..
	", bar on screen: " .. tostring(bar ~= nil and bar.Back.Visible) .. (bar and (" '" .. bar.Back.Text.Text .. "'") or ""))
if king then
	king.Humanoid.Health = king.Humanoid.MaxHealth / 2
	MOCK.run(1)
	say("bar at half health: " .. tostring(bar.Back.Fill.Size))
	-- the whole lobby hits it; player 2 lands the last hit
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = players[2]
	tag.Parent = king.Humanoid
	local c1, c2 = players[1].leaderstats.Credits.Value, players[2].leaderstats.Credits.Value
	king.Humanoid.Health = 0
	MOCK.run(2)
	say(string.format("boss dead: player 1 +%d, player 2 +%d, bar hidden %s", players[1].leaderstats.Credits.Value - c1,
		players[2].leaderstats.Credits.Value - c2, tostring(not bar.Back.Visible)))
	MOCK.run(8)
	local back = {}
	for _, m in ipairs(zombies()) do back[m.Name] = (back[m.Name] or 0) + 1 end
	local bs = {}
	for k, v in pairs(back) do table.insert(bs, k .. "=" .. v) end
	table.sort(bs)
	say("zombies back after the boss: " .. table.concat(bs, " "))
end
say("errors: " .. #MOCK.errors)
for i = 1, math.min(8, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 300)) end
_G.TEST_OUT = table.concat(out, "\n")
