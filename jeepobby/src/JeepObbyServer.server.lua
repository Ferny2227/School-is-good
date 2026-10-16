-- ServerScriptService.JeepObbyServer
-- Runs the whole obby: stages and checkpoints, one car per player (spawned on spread-out pads),
-- car unlocks from wins, the moving obstacles, kill parts, saving, and the remote the UI talks to.
-- Written for 2016 Roblox engines: lowercase :connect, ypcall, no TweenService/typeof/etc.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

--#CARS

local ROOT = workspace:WaitForChild("JeepObby")
local STAGES = ROOT:WaitForChild("Stages")
local LEVELMODELS = ROOT:WaitForChild("Levels")
local CARFOLDER = ROOT:WaitForChild("Cars")
local TEMPLATE = SS:WaitForChild("CarTemplate")
local STAGEDATA = SS:WaitForChild("StageData")   -- spawn points and car pads (kept out of Workspace)

local remote = RS:FindFirstChild("JeepObbyEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "JeepObbyEvent"
	remote.Parent = RS
end

local function send(player, ...)
	local args = { ... }
	pcall(function() remote:FireClient(player, unpack(args)) end)
end

------------------------------------------------------------------ helpers
local function eachDescendant(obj, fn)
	for _, c in ipairs(obj:GetChildren()) do
		fn(c)
		eachDescendant(c, fn)
	end
end

local function baseParts(obj)
	local out = {}
	eachDescendant(obj, function(c) if c:IsA("BasePart") then table.insert(out, c) end end)
	return out
end

local function stagePad(n) return STAGES:FindFirstChild("Stage" .. n) end

local function stageData(n) return STAGEDATA:FindFirstChild("Stage" .. n) end

local function stageSpawn(n)
	local sd = stageData(n)
	local sp = sd and sd:FindFirstChild("Spawn")
	if sp then return sp.CFrame end
	return CFrame.new(0, 100, 0)
end

local function levelOfStage(stage)
	local lv = 1
	for i, L in ipairs(LEVELS) do
		if stage >= L.stage then lv = i end
	end
	return lv
end

------------------------------------------------------------------ player data
local data = {}       -- [player] = {wins, best, car, stage, carModel, busy, last = {}}

local store
pcall(function() store = game:GetService("DataStoreService"):GetDataStore("JeepObby_v1") end)

local function save(player)
	local d = data[player]
	if not d or not store or not d.loaded then return end
	local key = "p" .. tostring(player.userId)
	local value = { w = d.wins, b = d.best, c = d.car }
	spawn(function()
		pcall(function() store:SetAsync(key, value) end)
	end)
end

local function syncValues(player)
	local d = data[player]
	if not d then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Stage") then ls.Stage.Value = d.stage end
		if ls:FindFirstChild("Wins") then ls.Wins.Value = d.wins end
	end
	if player:FindFirstChild("BestStage") then player.BestStage.Value = d.best end
	if player:FindFirstChild("SelectedCar") then player.SelectedCar.Value = d.car end
end

local function bestCarFor(wins)
	local best = 1
	for i, c in ipairs(CARS) do
		if wins >= c.wins then best = i end
	end
	return best
end

------------------------------------------------------------------ cars
local function driverOf(car)
	local seat = car:FindFirstChild("VehicleSeat")
	local weld = seat and seat:FindFirstChild("SeatWeld")
	if weld and weld.Part1 and weld.Part1.Parent then
		return Players:GetPlayerFromCharacter(weld.Part1.Parent)
	end
	return nil
end

local function carOf(part)
	local x = part
	while x and x.Parent do
		if x.Parent == CARFOLDER then return x end
		x = x.Parent
	end
	return nil
end

local function removeCar(player)
	local d = data[player]
	if d and d.carModel then
		local car = d.carModel
		d.carModel = nil
		pcall(function()
			local seat = car:FindFirstChild("VehicleSeat")
			if seat and seat:FindFirstChild("Sound") then seat.Sound:Stop() end
		end)
		pcall(function() car:Destroy() end)
	end
end

local function nearestCarDistance(pos)
	local best = 1e9
	for _, car in ipairs(CARFOLDER:GetChildren()) do
		local seat = car:FindFirstChild("VehicleSeat")
		if seat then
			local dist = (seat.Position - pos).magnitude
			if dist < best then best = dist end
		end
	end
	return best
end

local function pickSlot(stage)
	local pad = stageData(stage)
	if not pad then return nil end
	local best, bestDist = nil, -1
	for _, s in ipairs(pad:GetChildren()) do
		if s.Name == "Slot" then
			local dist = nearestCarDistance(s.Position)
			if dist > 14 then return s end
			if dist > bestDist then best, bestDist = s, dist end
		end
	end
	return best
end

local function weld(x, y)
	local w = Instance.new("Weld")
	w.Part0 = x
	w.Part1 = y
	local cj = CFrame.new(x.Position)
	w.C0 = x.CFrame:inverse() * cj
	w.C1 = y.CFrame:inverse() * cj
	w.Parent = x
end

local function styleCar(car, def, parts, player)
	local seat = car:FindFirstChild("VehicleSeat")
	seat.MaxSpeed = def.speed
	seat.Torque = def.torque
	seat.TurnSpeed = def.turn
	for _, p in ipairs(parts) do
		if p.Name == "Colour" then
			p.BrickColor = BrickColor.new(def.color)
			if def.extra == "gold" then p.Reflectance = 0.35 end
			if def.extra == "neon" then pcall(function() p.Material = Enum.Material.Neon end) end
		end
	end
	if def.extra == "smoke" then
		local s = Instance.new("Smoke")
		s.Color = Color3.new(0.3, 0.3, 0.3)
		s.Opacity = 0.25
		s.RiseVelocity = 4
		s.Parent = seat
	elseif def.extra == "fire" then
		local f = Instance.new("Fire")
		f.Heat = 6
		f.Size = 4
		f.Parent = seat
	elseif def.extra == "gold" then
		local s = Instance.new("Sparkles")
		s.Parent = seat
	end
	-- glowing strip under the car (between the wheels) with a light in the car's colour
	pcall(function()
		local glow = Instance.new("Part")
		pcall(function() glow.FormFactor = Enum.FormFactor.Custom end)
		glow.Name = "Underglow"
		glow.Size = Vector3.new(5, 0.2, 7)
		glow.CanCollide = false
		glow.Anchored = true
		glow.BrickColor = BrickColor.new(def.color)
		pcall(function() glow.Material = Enum.Material.Neon end)
		glow.TopSurface = Enum.SurfaceType.Smooth
		glow.BottomSurface = Enum.SurfaceType.Smooth
		glow.CFrame = seat.CFrame * CFrame.new(0, -1.6, 1.3)
		local light = Instance.new("PointLight")
		light.Color = BrickColor.new(def.color).Color
		light.Range = 14
		light.Brightness = 3
		light.Parent = glow
		glow.Parent = car
		table.insert(parts, glow)
	end)
	-- name tag over the car (sized in studs, so it shrinks with distance)
	pcall(function()
		local bb = Instance.new("BillboardGui")
		bb.Name = "Tag"
		bb.Size = UDim2.new(7, 0, 1.8, 0)
		bb.StudsOffset = Vector3.new(0, 6, 0)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, 0, 1, 0)
		t.Text = player.Name .. " - " .. def.name
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0.3
		t.TextScaled = true
		pcall(function() t.Font = Enum.Font.SourceSansBold end)
		t.Parent = bb
		bb.Parent = seat
	end)
end

local function spawnCar(player, stage)
	local d = data[player]
	if not d then return end
	removeCar(player)
	local slot = pickSlot(stage or d.stage)
	if not slot then return end
	local def = CARS[d.car] or CARS[1]
	local car = TEMPLATE:Clone()
	car.Name = player.Name .. "'s " .. def.name
	local seat = car:FindFirstChild("VehicleSeat")
	local move = slot.CFrame * seat.CFrame:inverse()
	local parts = baseParts(car)
	for _, p in ipairs(parts) do
		p.Anchored = true
		p.CFrame = move * p.CFrame
	end
	styleCar(car, def, parts, player)
	local owner = Instance.new("ObjectValue")
	owner.Name = "Owner"
	owner.Value = player
	owner.Parent = car
	car.Parent = CARFOLDER
	d.carModel = car
	pcall(function() car:MakeJoints() end)
	-- never let the car be joined to anything that isn't part of it (that pins it in the air)
	local inCar = {}
	for _, p in ipairs(parts) do inCar[p] = true end
	for _, p in ipairs(parts) do
		for _, j in ipairs(p:GetChildren()) do
			if j:IsA("JointInstance") then
				local a, b = j.Part0, j.Part1
				if (a and not inCar[a]) or (b and not inCar[b]) then j:Destroy() end
			end
		end
	end
	for _, p in ipairs(parts) do
		if p ~= seat and p.Name ~= "Wheel" then weld(seat, p) end
	end
	for _, p in ipairs(parts) do p.Anchored = false end
	return car
end

local function flipCar(player)
	local d = data[player]
	local car = d and d.carModel
	local seat = car and car.Parent and car:FindFirstChild("VehicleSeat")
	if not seat then return end
	local lv = seat.CFrame.lookVector
	local flat = Vector3.new(lv.x, 0, lv.z)
	if flat.magnitude < 0.1 then flat = Vector3.new(1, 0, 0) end
	local g = Instance.new("BodyGyro")
	g.maxTorque = Vector3.new(4e6, 4e6, 4e6)
	g.cframe = CFrame.new(Vector3.new(0, 0, 0), flat)
	g.Parent = seat
	local bp = Instance.new("BodyPosition")
	bp.maxForce = Vector3.new(0, 4e6, 0)
	bp.position = seat.Position + Vector3.new(0, 7, 0)
	bp.Parent = seat
	Debris:AddItem(g, 1.5)
	Debris:AddItem(bp, 0.8)
end

------------------------------------------------------------------ moving the player around
local function placeCharacter(player, stage)
	local char = player.Character
	if not char then return end
	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if hum then pcall(function() hum.Sit = false end) end
	if torso then
		local cf = stageSpawn(stage)
		torso.CFrame = cf + Vector3.new(0, 3, 0)
		pcall(function() torso.Velocity = Vector3.new(0, 0, 0) end)
	end
end

local function goToStage(player, stage, why)
	local d = data[player]
	if not d then return end
	d.stage = stage
	if stage > d.best then d.best = stage end
	syncValues(player)
	removeCar(player)
	wait(0.1)
	placeCharacter(player, stage)
	wait(0.2)
	spawnCar(player, stage)
	if why then send(player, why, stage, levelOfStage(stage)) end
end

------------------------------------------------------------------ touching things
local function playerFromHit(hit)
	if not hit or not hit.Parent then return nil end
	local p = Players:GetPlayerFromCharacter(hit.Parent)
	if p then return p end
	if hit.Parent.Parent then
		p = Players:GetPlayerFromCharacter(hit.Parent.Parent)
		if p then return p end
	end
	local car = carOf(hit)
	if car then return driverOf(car), car end
	return nil
end

local function killPlayer(player)
	local char = player and player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if hum and hum.Health > 0 then hum.Health = 0 end
end

local function onKill(hit)
	local hum = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
	if hum then hum.Health = 0 return end
	local car = carOf(hit)
	if car then killPlayer(driverOf(car)) end
end

local function onKillFloor(hit)
	local hum = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
	if hum then hum.Health = 0 return end
	local car = carOf(hit)
	if car then
		killPlayer(driverOf(car))
		for p, d in pairs(data) do
			if d.carModel == car then d.carModel = nil end
		end
		pcall(function() car:Destroy() end)
	end
end

local function onStage(pad, n)
	pad.Touched:connect(function(hit)
		local player = playerFromHit(hit)
		local d = player and data[player]
		if not d or d.busy then return end
		if n > d.stage then
			d.stage = n
			if n > d.best then d.best = n end
			syncValues(player)
			send(player, "checkpoint", n, levelOfStage(n))
		end
	end)
end

local function onLevelEnd(pad, nextStage)
	pad.Touched:connect(function(hit)
		local player = playerFromHit(hit)
		local d = player and data[player]
		if not d or d.busy then return end
		d.busy = true
		goToStage(player, nextStage, "level")
		save(player)
		wait(1.5)
		d.busy = false
	end)
end

local function onWin(pad)
	pad.Touched:connect(function(hit)
		local player = playerFromHit(hit)
		local d = player and data[player]
		if not d or d.busy then return end
		d.busy = true
		d.wins = d.wins + 1
		local unlocked = {}
		for i, c in ipairs(CARS) do
			if c.wins == d.wins then table.insert(unlocked, c.name) end
		end
		if #unlocked > 0 then d.car = bestCarFor(d.wins) end
		syncValues(player)
		send(player, "win", d.wins, table.concat(unlocked, ", "))
		save(player)
		goToStage(player, 1, nil)
		wait(1.5)
		d.busy = false
	end)
end

------------------------------------------------------------------ signs over checkpoints
local function sign(part, text, color)
	pcall(function()
		local bb = Instance.new("BillboardGui")
		bb.Name = "Sign"
		bb.Size = UDim2.new(24, 0, 4, 0)   -- in studs: small from far away, never covers the screen
		bb.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 4, 0)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, 0, 1, 0)
		t.Text = text
		t.TextColor3 = color or Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0
		t.TextScaled = true
		pcall(function() t.Font = Enum.Font.SourceSansBold end)
		t.Parent = bb
		bb.Parent = part
	end)
end

for _, pad in ipairs(STAGES:GetChildren()) do
	local n = tonumber(pad.Name:match("^Stage(%d+)$") or "")
	if n then
		onStage(pad, n)
		local lv = levelOfStage(n)
		if n > 1 and LEVELS[lv].stage == n then
			sign(pad, "LEVEL " .. lv .. ": " .. LEVELS[lv].name, Color3.new(1, 0.9, 0.3))
		elseif n > 1 and pad.Transparency < 1 then
			sign(pad, "CHECKPOINT " .. n, Color3.new(0.5, 1, 0.5))
		end
	elseif pad.Name == "LevelEnd" and pad:FindFirstChild("NextStage") then
		onLevelEnd(pad, pad.NextStage.Value)
		sign(pad, "NEXT LEVEL >>", Color3.new(0.4, 1, 0.4))
	elseif pad.Name == "WinPad" then
		onWin(pad)
		sign(pad, "FINISH!", Color3.new(1, 0.85, 0.2))
	end
end

local moving = {}
local function scan(obj)
	for _, c in ipairs(obj:GetChildren()) do
		if c:IsA("BasePart") then
			if c.Name == "KillPart" or c.Name == "Kill Brick" then
				c.Touched:connect(function(hit) onKill(hit) end)
			elseif c.Name == "KillFloor" then
				c.Touched:connect(function(hit) onKillFloor(hit) end)
			end
			local mv = c:FindFirstChild("Move")
			if mv and mv:IsA("StringValue") then
				local words = {}
				for w in mv.Value:gmatch("%S+") do table.insert(words, w) end
				local kind = words[1]
				local nums = {}
				for i = 2, #words do nums[i - 1] = tonumber(words[i]) or 0 end
				table.insert(moving, { part = c, kind = kind, n = nums, base = c.CFrame, solid = true, tr = c.Transparency })
			end
		end
		if c ~= CARFOLDER then scan(c) end
	end
end
scan(workspace)

-- obstacles move on the server; anchored parts set by CFrame (works on every engine)
spawn(function()
	local start = tick()
	while true do
		local t = tick() - start
		for _, m in ipairs(moving) do
			local n = m.n
			if m.kind == "slide" then
				local s = math.sin((t / n[4] + n[5]) * math.pi * 2)
				m.part.CFrame = m.base + Vector3.new(n[1] * s, n[2] * s, n[3] * s)
			elseif m.kind == "spin" then
				m.part.CFrame = m.base * CFrame.Angles(0, math.rad(n[1] * t), 0)
			elseif m.kind == "blink" then
				local c = (t / n[1] + n[3]) % 1
				local solid = c < n[2]
				local warn = solid and c > n[2] - 0.18
				if solid ~= m.solid then
					m.solid = solid
					m.part.CanCollide = solid
				end
				local tr = solid and (warn and 0.5 or m.tr) or 0.85
				if m.part.Transparency ~= tr then m.part.Transparency = tr end
			end
		end
		wait()
	end
end)

------------------------------------------------------------------ joining and leaving
local function setup(player)
	if data[player] then return end
	local d = { wins = 0, best = 1, car = 1, stage = 1, loaded = false }
	data[player] = d
	local ls = Instance.new("IntValue")
	ls.Name = "leaderstats"
	local st = Instance.new("IntValue")
	st.Name = "Stage"
	st.Value = 1
	st.Parent = ls
	local w = Instance.new("IntValue")
	w.Name = "Wins"
	w.Parent = ls
	ls.Parent = player
	local b = Instance.new("IntValue")
	b.Name = "BestStage"
	b.Value = 1
	b.Parent = player
	local c = Instance.new("IntValue")
	c.Name = "SelectedCar"
	c.Value = 1
	c.Parent = player
	syncValues(player)

	-- load saved wins in the background (DataStores can be missing or slow on some servers)
	spawn(function()
		if not store then d.loaded = true return end
		local ok, saved = pcall(function() return store:GetAsync("p" .. tostring(player.userId)) end)
		if ok then
			d.loaded = true
			if type(saved) == "table" then
				d.wins = math.max(d.wins, tonumber(saved.w) or 0)
				d.best = math.max(d.best, tonumber(saved.b) or 1)
				local car = tonumber(saved.c) or 1
				if CARS[car] and d.wins >= CARS[car].wins then d.car = car end
				syncValues(player)
			end
		end
	end)

	local function onCharacter(char)
		local torso = char:WaitForChild("Torso")
		wait(0.25)
		if player.Character ~= char then return end
		placeCharacter(player, d.stage)
		wait(0.25)
		spawnCar(player, d.stage)
	end
	player.CharacterAdded:connect(onCharacter)
	if player.Character then spawn(function() onCharacter(player.Character) end) end
end

Players.PlayerAdded:connect(setup)
for _, p in ipairs(Players:GetPlayers()) do spawn(function() setup(p) end) end

Players.PlayerRemoving:connect(function(player)
	removeCar(player)
	save(player)
	data[player] = nil
end)

pcall(function()
	game:BindToClose(function()
		for p in pairs(data) do save(p) end
		wait(2)
	end)
end)

spawn(function()
	while true do
		wait(90)
		for p in pairs(data) do save(p) end
	end
end)

------------------------------------------------------------------ what the UI can ask for
remote.OnServerEvent:connect(function(player, what, arg)
	local d = data[player]
	if not d then return end
	local now = tick()
	d.last = d.last or {}
	if d.last[what] and now - d.last[what] < 1 then return end
	d.last[what] = now
	if what == "select" then
		local i = tonumber(arg)
		if i and CARS[i] and d.wins >= CARS[i].wins then
			d.car = i
			syncValues(player)
			spawnCar(player, d.stage)
			save(player)
		end
	elseif what == "spawn" then
		spawnCar(player, d.stage)
	elseif what == "flip" then
		flipCar(player)
	elseif what == "level" then
		local i = tonumber(arg)
		if i and LEVELS[i] and LEVELS[i].stage <= d.best and not d.busy then
			d.busy = true
			goToStage(player, LEVELS[i].stage, "level")
			d.busy = false
		end
	end
end)

print("JeepObbyServer ready: " .. #moving .. " moving obstacles, " .. #CARS .. " cars")
