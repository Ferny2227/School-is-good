-- Fake Roblox services for running ShooterMain (needs mock.lua first)
game = Instance.new("DataModel")
game.Name = "Game"
workspace = Instance.new("Workspace")
workspace.Name = "Workspace"
workspace.Parent = game
game.Workspace = workspace

local services = {}
local function service(name, class)
	local s = Instance.new(class or name)
	s.Name = name
	s.Parent = game
	services[name] = s
	return s
end
local Players = service("Players")
service("Debris")
service("ReplicatedStorage")
service("ServerStorage")
service("ServerScriptService")
service("Lighting")
service("Teams")
service("RunService")
service("DataStoreService")
service("UserInputService")
services.Workspace = workspace
rawset(game, "_get", function(o, k)
	if k == "GetService" then
		return function(self, n)
			if not services[n] then error("no service " .. n) end
			return services[n]
		end
	end
end)
local Lighting = services.Lighting
rawset(Lighting, "_get", function(o, k)
	if k == "SetMinutesAfterMidnight" then
		return function(self, m) rawget(self, "_props").ClockTime = m / 60 end
	end
end)
STORE = {}
rawset(services.DataStoreService, "_get", function(o, k)
	if k == "GetDataStore" then
		return function()
			local st = {}
			function st.GetAsync(self, key) return STORE[key] end
			function st.SetAsync(self, key, v) STORE[key] = v end
			return st
		end
	end
end)

-- Players
local playerList = {}
rawset(Players, "_get", function(o, k)
	if k == "GetPlayers" or k == "getPlayers" then
		return function()
			local t = {}
			for _, p in ipairs(Players:GetChildren()) do
				if p.ClassName == "Player" then table.insert(t, p) end
			end
			return t
		end
	end
	if k == "GetPlayerFromCharacter" or k == "getPlayerFromCharacter" then
		return function(self, model)
			for _, p in ipairs(Players:GetChildren()) do
				if p.ClassName == "Player" and p.Character == model and model ~= nil then return p end
			end
			return nil
		end
	end
end)

-- a character model (R6-ish) whose parts follow the root
local function part(name, size, cf, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Parent = parent
	return p
end
function moveModel(model, newRootCF)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local old = rawget(root, "_props").CFrame
	local delta = newRootCF * old:inverse()
	for _, c in ipairs(model:GetDescendants()) do
		if c:IsA("BasePart") then
			rawget(c, "_props").CFrame = delta * rawget(c, "_props").CFrame
		end
	end
end
local function makeCharacter(p)
	local m = Instance.new("Model")
	m.Name = p.Name
	local cf = CFrame.new(0, 600, 0)
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), cf, m)
	part("Torso", Vector3.new(2, 2, 1), cf, m)
	part("Head", Vector3.new(2, 1, 1), cf * CFrame.new(0, 1.5, 0), m)
	part("Right Arm", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0, 0), m)
	part("Left Arm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0), m)
	part("Right Leg", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), m)
	part("Left Leg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), m)
	rawset(root, "_set", function(o, k, v)
		if k == "CFrame" then
			moveModel(m, v)
			return true
		end
	end)
	local h = Instance.new("Humanoid")
	h.Parent = m
	return m
end

NEXT_ID = 1
function addPlayer(name)
	local p = Instance.new("Player")
	p.Name = name
	p.userId = NEXT_ID
	p.UserId = NEXT_ID
	NEXT_ID = NEXT_ID + 1
	local bp = Instance.new("Backpack")
	bp.Parent = p
	local pg = Instance.new("PlayerGui")
	pg.Name = "PlayerGui"
	pg.Parent = p
	rawset(p, "_get", function(o, k)
		if k == "LoadCharacter" then
			return function(self)
				local old = self.Character
				if old then old:Destroy() end
				for _, t in ipairs(bp:GetChildren()) do t:Destroy() end
				local m = makeCharacter(self)
				rawget(self, "_props").Character = m
				m.Parent = workspace
				rawget(self, "_events").CharacterAdded = rawget(self, "_events").CharacterAdded
				local ev = self.CharacterAdded
				ev:Fire(m)
			end
		end
		if k == "Kick" then return function() end end
	end)
	rawset(p, "_set", function(o, k, v)
		if k == "Character" then rawget(o, "_props").Character = v return true end
	end)
	p.Parent = Players
	Players.PlayerAdded:Fire(p)
	return p
end
function removePlayer(p)
	Players.PlayerRemoving:Fire(p)
	if p.Character then p.Character:Destroy() end
	p.Parent = nil
end

-- remote events: remember what the server sends
SENT = {}
rawset(game, "_onRemote", true)
function hookRemote(remote)
	rawset(remote, "_get", function(o, k)
		if k == "FireAllClients" then
			return function(self, ...)
				table.insert(SENT, { to = "all", args = { ... } })
			end
		end
		if k == "FireClient" then
			return function(self, p, ...)
				if type(p) ~= "table" or p.ClassName ~= "Player" then error("FireClient needs a Player") end
				table.insert(SENT, { to = p, args = { ... } })
			end
		end
	end)
end

-- raycasts against the parts in the Workspace
local function allParts(root, out)
	for _, c in ipairs(root:GetChildren()) do
		if c:IsA("BasePart") then table.insert(out, c) end
		allParts(c, out)
	end
	return out
end
local cache, cacheAt = nil, -1
RAYS = 0
local function raycast(ray, ignore)
	RAYS = RAYS + 1
	if cacheAt ~= NOW then
		cache = allParts(workspace, {})
		cacheAt = NOW
	end
	local o, d = ray.Origin, ray.Direction
	local len = d.magnitude
	if len < 1e-6 then return nil, o end
	local u = d / len
	local best, bestT = nil, len
	for _, p in ipairs(cache) do
		local skip = false
		for _, ig in ipairs(ignore) do
			if ig and (p == ig or p:IsDescendantOf(ig)) then skip = true break end
		end
		if not skip then
			local c = p.CFrame.p
			local t = (c - o):Dot(u)
			local r = partRadius(p)
			if t > -r and t < bestT + r then
				local closest = o + u * math.max(0, math.min(len, t))
				if (closest - c).magnitude <= r then
					local t0, t1 = math.max(0, t - r), math.min(bestT, t + r)
					local step = math.max(0.25, math.min(1, (t1 - t0) / 40))
					local tt = t0
					while tt <= t1 do
						if pointInPart(p, o + u * tt) then
							if tt < bestT then best, bestT = p, tt end
							break
						end
						tt = tt + step
					end
				end
			end
		end
	end
	return best, o + u * bestT
end
rawset(workspace, "_get", function(o, k)
	if k == "FindPartOnRayWithIgnoreList" then
		return function(self, ray, ignore) return raycast(ray, ignore or {}) end
	end
	if k == "FindPartOnRay" then
		return function(self, ray, ig) return raycast(ray, { ig }) end
	end
end)

-- "physics": humanoids walk to their MoveTo goal, BodyVelocity pushes, gravity is ignored
spawn(function()
	while true do
		wait(0.1)
		for _, m in ipairs(workspace:GetDescendants()) do
			if m.ClassName == "Humanoid" and m.Health > 0 and m.Parent then
				local goal = rawget(m, "_props").MoveGoal
				local root = m.Parent:FindFirstChild("HumanoidRootPart")
				if goal and root then
					local pos = root.CFrame.p
					local flat = Vector3.new(goal.X - pos.X, 0, goal.Z - pos.Z)
					if flat.magnitude > 0.5 then
						local step = flat.unit * math.min(flat.magnitude, (m.WalkSpeed or 16) * 0.1)
						moveModel(m.Parent, root.CFrame + step)
					end
				end
			end
		end
	end
end)

-- modules
function makeModule(name, src, parent)
	local ms = Instance.new("ModuleScript")
	ms.Name = name
	ms.Source = src
	ms.Parent = parent
	return ms
end
local loaded = {}
function require(ms)
	if loaded[ms] ~= nil then return loaded[ms] end
	local fn, err = loadstring(ms.Source, ms.Name)
	if not fn then error(err) end
	setfenv(fn, setmetatable({ script = ms }, { __index = _G, __newindex = _G }))
	local r = fn()
	loaded[ms] = r
	return r
end
function runScript(name, src, parent)
	local s = Instance.new("Script")
	s.Name = name
	s.Parent = parent
	local fn, err = loadstring(src, name)
	if not fn then error(err) end
	setfenv(fn, setmetatable({ script = s }, { __index = _G, __newindex = _G }))
	runMain(fn)
	return s
end
