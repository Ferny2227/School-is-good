-- ServerScriptService.ZombieDirector
-- Runs the zombies of Area 51:
--  * every zombie kill pays 30 Credits to the player who killed it (guns tag the zombie with a "creator" value)
--  * new zombie types next to the old ones: Bomber (runs at you and explodes), Shooter (keeps its distance and
--    throws slime balls), Runner (fast but weak) and Brute (slow and tough). None of them are overpowered.
--  * when every zombie is dead, the ZOMBIE KING spawns: a giant boss with a health bar on everyone's screen. The
--    whole lobby has to kill it; when it dies everybody gets a bonus and every zombie comes back.
--  * zombies only chase players who are near, check that their target still exists, and nobody respawns on their
--    own any more (the director brings them all back after the boss), so the old respawn/chase scripts are off.
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local pcall = ypcall or pcall

local KILL_REWARD = 30      -- Credits per zombie
local BOSS_BONUS = 150      -- Credits for everyone in the server when the Zombie King dies
local CHASE_RANGE = 250     -- zombies only chase players this close
local EXTRA = { Bomber = 3, Shooter = 3, Runner = 3, Brute = 2 }   -- new zombies per wave (+1 of each per 3 players)

------------------------------------------------------------------ Credits
local function credits(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Credits")
end
-- make sure every player has exactly one leaderstats with Credits (the old payday scripts made two)
local function setupStats(player)
	wait(2)
	if not player.Parent then return end
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("IntValue")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	if not ls:FindFirstChild("Credits") then
		local c = Instance.new("IntValue")
		c.Name = "Credits"
		c.Parent = ls
	end
end
Players.PlayerAdded:connect(setupStats)
for _, p in ipairs(Players:GetPlayers()) do spawn(function() setupStats(p) end) end

local function killerOf(humanoid)
	local tag = humanoid:FindFirstChild("creator")
	if not tag then return nil end
	local v = tag.Value
	if type(v) == "string" then return Players:FindFirstChild(v) end
	if v and v:IsA("Player") then return v end
	return nil
end

------------------------------------------------------------------ finding zombies
local function humanoidOf(m)
	-- guns hurt the humanoid called "Humanoid", so that one counts when a model has two
	local h = m:FindFirstChild("Humanoid")
	if h and h:IsA("Humanoid") then return h end
	h = m:FindFirstChild("Zombie")
	if h and h:IsA("Humanoid") then return h end
	return nil
end
local function isZombie(m)
	if not m:IsA("Model") or Players:GetPlayerFromCharacter(m) then return false end
	if not humanoidOf(m) then return false end
	local n = m.Name:lower()
	return n:find("zombie") ~= nil or n:find("necromorph") ~= nil or m:FindFirstChild("zarm") ~= nil
		or (m:FindFirstChild("Zombie") ~= nil and m:FindFirstChild("Zombie"):IsA("Humanoid"))
end
local function torsoOf(m) return m:FindFirstChild("Torso") or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head") end
local function allZombieModels()
	local out = {}
	local function scan(o)
		for _, c in ipairs(o:GetChildren()) do
			if c:IsA("Model") then
				if isZombie(c) then table.insert(out, c) else scan(c) end
			end
		end
	end
	scan(workspace)
	return out
end

------------------------------------------------------------------ players
local function nearestPlayer(pos, range)
	local best, bd = nil, range or CHASE_RANGE
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChild("Humanoid")
		local t = c and torsoOf(c)
		if h and t and h.Health > 0 then
			local d = (t.Position - pos).magnitude
			if d < bd then best, bd = c, d end
		end
	end
	return best, bd
end
-- once = a player is hurt by at most one of these every 2 seconds (bombers that arrive together don't stack)
local blasted = {}
local function hurtPlayersNear(pos, radius, damage, once)
	local now = tick()
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChild("Humanoid")
		local t = c and torsoOf(c)
		if h and t and h.Health > 0 then
			local d = (t.Position - pos).magnitude
			if d < radius and not (once and blasted[p] and now - blasted[p] < 2) then
				if once then blasted[p] = now end
				h:TakeDamage(damage * (1 - 0.5 * d / radius))
			end
		end
	end
end

------------------------------------------------------------------ the zombies the director looks after
local Z = {}            -- model -> { kind, humanoid, ... }
local templates = {}    -- { model clone, parent } of every original zombie (to bring them back after the boss)
local spawnPoints = {}  -- where zombies were standing at the start
local boss = nil
local comingBack = false   -- between the boss dying and the zombies coming back
local lastKill = tick()

local function track(m, kind)
	local h = humanoidOf(m)
	if not h then return end
	local z = { model = m, kind = kind or "Classic", h = h, next = 0, hit = 0 }
	Z[m] = z
	h.Died:connect(function()
		if z.dead then return end
		z.dead = true
		lastKill = tick()
		local killer = killerOf(h)
		local c = killer and credits(killer)
		if c then c.Value = c.Value + KILL_REWARD end
		delay(6, function() pcall(function() m:Destroy() end) Z[m] = nil end)
	end)
	return z
end

-- scale a classic zombie (parts, joints) by s, around its torso
local function scale(m, s)
	local torso = torsoOf(m)
	if not torso then return end
	local base = torso.CFrame
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") then
			local rel = base:toObjectSpace(p.CFrame)
			p.Size = p.Size * s
			p.CFrame = base * (CFrame.new(rel.p * s) * (rel - rel.p))
		end
	end
	for _, j in ipairs(m:GetDescendants()) do
		if j:IsA("JointInstance") then
			j.C0 = CFrame.new(j.C0.p * s) * (j.C0 - j.C0.p)
			j.C1 = CFrame.new(j.C1.p * s) * (j.C1 - j.C1.p)
		end
	end
end
local function paint(m, color)
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "Head" then pcall(function() p.BrickColor = BrickColor.new(color) end) end
	end
end
local function label(m, text, color)
	local head = m:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "TypeLabel"
	bb.Size = UDim2.new(0, 120, 0, 24)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = false
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.3
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	pcall(function() t.FontSize = Enum.FontSize.Size18 end)
	t.Parent = bb
	bb.Parent = head
end

-- the classic zombie template the new types are made from
local base
local KINDS = {
	Bomber = { color = "Bright orange", hp = 80, speed = 18, text = "BOMBER", rgb = Color3.new(1, 0.5, 0) },
	Shooter = { color = "Lime green", hp = 110, speed = 12, text = "SHOOTER", rgb = Color3.new(0.4, 1, 0.3) },
	Runner = { color = "Bright yellow", hp = 60, speed = 24, text = "RUNNER", rgb = Color3.new(1, 1, 0.3) },
	Brute = { color = "Really black", hp = 400, speed = 9, text = "BRUTE", rgb = Color3.new(0.8, 0.8, 0.8) },
}
local function makeKind(kind, at)
	if not base then return end
	local k = KINDS[kind]
	local m = base:Clone()
	m.Name = kind .. " Zombie"
	-- the director moves and fights for them: switch their own scripts off (arm-touch damage too)
	for _, s in ipairs(m:GetDescendants()) do
		if s:IsA("Script") then s.Disabled = true end
	end
	paint(m, k.color)
	if kind == "Brute" then scale(m, 1.5) end
	if kind == "Bomber" then
		local torso = torsoOf(m)
		local bomb = Instance.new("Part")
		bomb.Name = "Bomb"
		bomb.Shape = Enum.PartType.Ball
		bomb.Size = Vector3.new(1.6, 1.6, 1.6)
		bomb.BrickColor = BrickColor.new("Really black")
		bomb.CanCollide = false
		bomb.CFrame = torso.CFrame * CFrame.new(0, 0.3, 0.9)
		local w = Instance.new("Weld")
		w.Part0, w.Part1 = torso, bomb
		w.C0 = torso.CFrame:toObjectSpace(bomb.CFrame)
		w.Parent = bomb
		bomb.Parent = m
		local f = Instance.new("Fire")
		f.Size = 2
		f.Parent = bomb
	end
	label(m, k.text, k.rgb)
	m.Parent = workspace
	pcall(function() m:MakeJoints() end)
	m:MoveTo(at + Vector3.new(math.random(-14, 14), 3, math.random(-14, 14)))
	local h = humanoidOf(m)
	h.MaxHealth = k.hp
	h.Health = k.hp
	h.WalkSpeed = k.speed
	return track(m, kind)
end

------------------------------------------------------------------ the Zombie King and its health bar
local function bossBar(player)
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return nil end
	local g = pg:FindFirstChild("BossBar")
	if g then return g end
	g = Instance.new("ScreenGui")
	g.Name = "BossBar"
	pcall(function() g.ResetOnSpawn = false end)
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.new(0, 460, 0, 34)
	back.Position = UDim2.new(0.5, -230, 0, 46)
	back.BackgroundColor3 = Color3.new(0.12, 0.02, 0.02)
	back.BorderSizePixel = 2
	back.BorderColor3 = Color3.new(0, 0, 0)
	back.Parent = g
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.new(0.85, 0.08, 0.08)
	fill.BorderSizePixel = 0
	fill.Parent = back
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	pcall(function() t.FontSize = Enum.FontSize.Size24 end)
	t.ZIndex = 2
	t.Parent = back
	local msg = Instance.new("TextLabel")
	msg.Name = "Message"
	msg.BackgroundTransparency = 1
	msg.Size = UDim2.new(0, 600, 0, 30)
	msg.Position = UDim2.new(0.5, -300, 0, 84)
	msg.TextColor3 = Color3.new(1, 0.85, 0.2)
	msg.TextStrokeTransparency = 0.2
	pcall(function() msg.Font = Enum.Font.SourceSansBold end)
	pcall(function() msg.FontSize = Enum.FontSize.Size24 end)
	msg.Text = ""
	msg.Parent = g
	g.Parent = pg
	return g
end
local function showBar(visible, text, frac, message)
	for _, p in ipairs(Players:GetPlayers()) do
		pcall(function()
			local g = bossBar(p)
			if not g then return end
			g.Back.Visible = visible
			if text then g.Back.Text.Text = text end
			if frac then g.Back.Fill.Size = UDim2.new(math.max(0, math.min(1, frac)), 0, 1, 0) end
			if message then g.Message.Text = message end
		end)
	end
end
local function announce(message, seconds)
	showBar(boss ~= nil, nil, nil, message)
	delay(seconds or 6, function() showBar(boss ~= nil, nil, nil, "") end)
end
Players.PlayerAdded:connect(function(p)
	p.CharacterAdded:connect(function()
		wait(1)
		local g = bossBar(p)
		if g then g.Back.Visible = boss ~= nil end
	end)
end)

local function spawnBoss()
	if not base or #spawnPoints == 0 then return end
	local m = base:Clone()
	m.Name = "ZOMBIE KING"
	for _, s in ipairs(m:GetDescendants()) do if s:IsA("Script") then s.Disabled = true end end
	paint(m, "Royal purple")
	scale(m, 3)
	local head = m:FindFirstChild("Head")
	if head then
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(4, 1.6, 4)
		crown.BrickColor = BrickColor.new("Bright yellow")
		pcall(function() crown.Material = Enum.Material.Neon end)
		crown.CanCollide = false
		crown.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.8, 0)
		local w = Instance.new("Weld")
		w.Part0, w.Part1 = head, crown
		w.C0 = head.CFrame:toObjectSpace(crown.CFrame)
		w.Parent = crown
		crown.Parent = m
	end
	label(m, "ZOMBIE KING", Color3.new(1, 0.2, 0.2))
	local at = spawnPoints[math.random(1, #spawnPoints)]
	m.Parent = workspace
	pcall(function() m:MakeJoints() end)
	m:MoveTo(at + Vector3.new(0, 8, 0))
	local h = humanoidOf(m)
	local hp = 1500 + 750 * #Players:GetPlayers()   -- the more players, the tougher
	h.MaxHealth = hp
	h.Health = hp
	h.WalkSpeed = 12
	boss = track(m, "Boss")
	boss.isBoss = true
	showBar(true, "ZOMBIE KING  " .. hp .. " / " .. hp, 1, "ALL ZOMBIES DOWN! THE ZOMBIE KING IS HERE - EVERYONE ATTACK!")
	delay(8, function() showBar(boss ~= nil, nil, nil, "") end)
	h.Died:connect(function()
		for _, p in ipairs(Players:GetPlayers()) do
			local c = credits(p)
			if c then c.Value = c.Value + BOSS_BONUS end
		end
		boss = nil
		comingBack = true
		showBar(false, nil, nil, "THE ZOMBIE KING IS DEAD! +" .. BOSS_BONUS .. " Credits for everyone. The zombies are coming back...")
		delay(8, function() showBar(boss ~= nil, nil, nil, "") end)
		delay(6, function()
			pcall(bringEveryoneBack)
			comingBack = false
		end)
	end)
end

------------------------------------------------------------------ waves
function bringEveryoneBack()
	for _, t in ipairs(templates) do
		pcall(function()
			local m = t.model:Clone()
			m.Parent = t.parent and t.parent.Parent and t.parent or workspace
			pcall(function() m:MakeJoints() end)
			track(m, "Classic")
		end)
	end
	local n = math.floor(#Players:GetPlayers() / 3)
	for kind, count in pairs(EXTRA) do
		for _ = 1, count + n do
			if #spawnPoints > 0 then pcall(makeKind, kind, spawnPoints[math.random(1, #spawnPoints)]) end
		end
	end
	lastKill = tick()
end

------------------------------------------------------------------ what the zombies do (one loop for all of them)
local function shoot(z, from, target)
	local ball = Instance.new("Part")
	ball.Name = "SlimeBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1.4, 1.4, 1.4)
	ball.BrickColor = BrickColor.new("Lime green")
	pcall(function() ball.Material = Enum.Material.Neon end)
	ball.CanCollide = false
	ball.CFrame = CFrame.new(from + Vector3.new(0, 1.5, 0))
	local dir = (target.Position - ball.Position).unit
	local bv = Instance.new("BodyVelocity")
	bv.maxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.velocity = dir * 55
	bv.Parent = ball
	ball.Parent = workspace
	local done = false
	ball.Touched:connect(function(hit)
		if done or not hit.Parent or hit:IsDescendantOf(z.model) then return end
		local h = hit.Parent:FindFirstChild("Humanoid")
		if h and Players:GetPlayerFromCharacter(hit.Parent) then
			done = true
			h:TakeDamage(8)
			ball:Destroy()
		end
	end)
	Debris:AddItem(ball, 3)
end
local function explode(z, at)
	local e = Instance.new("Explosion")
	e.Position = at
	e.BlastRadius = 10
	pcall(function() e.BlastPressure = 0 end)
	pcall(function() e.DestroyJointRadiusPercent = 0 end)   -- looks big, but only the damage below counts
	e.Parent = workspace
	hurtPlayersNear(at, 12, 25, true)
	z.h.Health = 0
end
local function think(z, now)
	local m = z.model
	local torso = torsoOf(m)
	if not torso or z.dead or z.h.Health <= 0 then return end
	if torso.Position.Y < -100 then z.h.Health = 0 return end   -- fell off the map
	local target, dist = nearestPlayer(torso.Position)
	if not target then return end   -- nobody near: stand still (no wasted work)
	local tt = torsoOf(target)
	local th = target:FindFirstChild("Humanoid")
	if not tt or not th then return end
	local kind = z.kind
	if kind == "Shooter" then
		if dist > 40 then z.h:MoveTo(tt.Position)
		elseif dist < 18 then z.h:MoveTo(torso.Position + (torso.Position - tt.Position).unit * 10)
		else z.h:MoveTo(torso.Position) end
		if dist < 90 and now > z.next then
			z.next = now + 2.5
			shoot(z, torso.Position, tt)
		end
	elseif kind == "Bomber" then
		z.h:MoveTo(tt.Position)
		if dist < 7 then explode(z, torso.Position) end
	else
		z.h:MoveTo(tt.Position)
		-- the director's own hits (classic zombies still hurt with their arms as before)
		local reach = kind == "Boss" and 10 or (kind == "Brute" and 6 or 4.5)
		if kind ~= "Classic" and dist < reach and now > z.hit then
			local dmg, every = 5, 1
			if kind == "Brute" then dmg, every = 10, 1.5 end
			if kind == "Boss" then dmg, every = 22, 1.5 end
			z.hit = now + every
			th:TakeDamage(dmg)
		end
		-- the King stomps every 8 seconds: hurts everyone close
		if kind == "Boss" and now > z.next then
			z.next = now + 8
			hurtPlayersNear(torso.Position, 18, 15)
			local e = Instance.new("Explosion")
			e.Position = torso.Position - Vector3.new(0, 6, 0)
			e.BlastRadius = 1
			pcall(function() e.BlastPressure = 0 end)
			pcall(function() e.DestroyJointRadiusPercent = 0 end)
			e.Parent = workspace
		end
	end
end

------------------------------------------------------------------ start
wait(4)   -- let the map's own clean-up scripts finish first
for _, m in ipairs(allZombieModels()) do
	local torso = torsoOf(m)
	if not torso then
		pcall(function() m:Destroy() end)   -- broken zombie with no body (it only made errors)
	else
		table.insert(spawnPoints, torso.Position)
		local t = m:Clone()
		table.insert(templates, { model = t, parent = m.Parent })
		if not base and m:FindFirstChild("zarm") and m:FindFirstChild("Head") then base = t end
		track(m, "Classic")
	end
end
if not base and templates[1] then base = templates[1].model end
for kind, count in pairs(EXTRA) do
	for _ = 1, count do
		if #spawnPoints > 0 then pcall(makeKind, kind, spawnPoints[math.random(1, #spawnPoints)]) end
	end
end
print("ZombieDirector: " .. #templates .. " zombies, " .. #spawnPoints .. " spawn points")

while true do
	wait(0.4)
	local now = tick()
	local alive = 0
	for m, z in pairs(Z) do
		if not m.Parent then
			Z[m] = nil
		elseif not z.dead and z.h.Health > 0 then
			if not z.isBoss then alive = alive + 1 end
			local ok, err = pcall(think, z, now)
			if not ok then z.dead = true print("ZombieDirector: " .. tostring(err)) end
		end
	end
	if boss and boss.h.Parent then
		local h = boss.h
		showBar(true, "ZOMBIE KING  " .. math.floor(h.Health) .. " / " .. math.floor(h.MaxHealth), h.Health / h.MaxHealth)
	end
	-- zombies left somewhere nobody can reach: after 4 minutes without a kill they give up and the boss comes
	if not boss and alive > 0 and alive <= 3 and now - lastKill > 240 then
		for m, z in pairs(Z) do if not z.dead then pcall(function() z.h.Health = 0 end) end end
		alive = 0
	end
	if alive == 0 and not boss and not comingBack and #Players:GetPlayers() > 0 and #spawnPoints > 0 then
		spawnBoss()
	end
end
