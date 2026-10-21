-- A small fake Roblox (2016 API subset) for running AirportServer outside Roblox.
-- Enough for: Instance trees, parts with CFrame/Size, Vector3/CFrame maths, events, RemoteEvents,
-- a virtual clock with spawn/wait/delay, and a recorded error log.
local MOCK = {}
_G.MOCK = MOCK
MOCK.errors = {}
MOCK.log = {}
local now = 1000
function tick() return now end
function time() return now end

------------------------------------------------------------------ scheduler
local tasks = {}
function MOCK.spawnTask(f, at)
	table.insert(tasks, { co = coroutine.create(f), t = at or now })
end
function spawn(f) MOCK.spawnTask(f, now) end
function delay(t, f) MOCK.spawnTask(f, now + (t or 0)) end
function wait(t)
	local co, main = coroutine.running()
	if not co or main then error("wait() called outside a task", 2) end
	t = t or 0.03
	coroutine.yield(math.max(t, 0.03))
	return t, now
end
ypcall = pcall
function MOCK.run(seconds, step)
	step = step or 0.05
	local stop = now + seconds
	while now < stop do
		now = now + step
		local list = tasks
		tasks = {}
		for _, t in ipairs(list) do
			if t.t <= now then
				local ok, w = coroutine.resume(t.co)
				if not ok then
					table.insert(MOCK.errors, tostring(w) .. "\n" .. debug.traceback(t.co))
				elseif coroutine.status(t.co) ~= "dead" then
					table.insert(tasks, { co = t.co, t = now + (w or 0) })
				end
			else
				table.insert(tasks, t)
			end
		end
	end
end
function MOCK.taskCount() return #tasks end

------------------------------------------------------------------ Vector3
local V3 = {}
V3.__index = function(v, k)
	if k == "x" or k == "X" then return rawget(v, 1) end
	if k == "y" or k == "Y" then return rawget(v, 2) end
	if k == "z" or k == "Z" then return rawget(v, 3) end
	if k == "magnitude" or k == "Magnitude" then return math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3]) end
	if k == "unit" or k == "Unit" then
		local m = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
		if m == 0 then return Vector3.new(0, 0, 0) end
		return Vector3.new(v[1] / m, v[2] / m, v[3] / m)
	end
	if k == "Cross" then return function(a, b) return Vector3.new(a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1]) end end
	if k == "Dot" then return function(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end end
	if k == "Lerp" or k == "lerp" then return function(a, b, t) return a + (b - a) * t end end
	error("Vector3 has no member " .. tostring(k), 2)
end
local function isV(v) return getmetatable(v) == V3 end
V3.__add = function(a, b) assert(isV(a) and isV(b), "Vector3 + non-Vector3") return Vector3.new(a[1] + b[1], a[2] + b[2], a[3] + b[3]) end
V3.__sub = function(a, b) assert(isV(a) and isV(b), "Vector3 - non-Vector3") return Vector3.new(a[1] - b[1], a[2] - b[2], a[3] - b[3]) end
V3.__mul = function(a, b)
	if type(a) == "number" then a, b = b, a end
	if type(b) == "number" then return Vector3.new(a[1] * b, a[2] * b, a[3] * b) end
	assert(isV(b), "bad Vector3 multiply")
	return Vector3.new(a[1] * b[1], a[2] * b[2], a[3] * b[3])
end
V3.__div = function(a, b)
	if type(b) == "number" then return Vector3.new(a[1] / b, a[2] / b, a[3] / b) end
	return Vector3.new(a[1] / b[1], a[2] / b[2], a[3] / b[3])
end
V3.__unm = function(a) return Vector3.new(-a[1], -a[2], -a[3]) end
V3.__eq = function(a, b) return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] end
V3.__tostring = function(v) return string.format("%.2f, %.2f, %.2f", v[1], v[2], v[3]) end
Vector3 = { new = function(x, y, z)
	x, y, z = x or 0, y or 0, z or 0
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Vector3.new needs numbers")
	assert(x == x and y == y and z == z, "Vector3.new got NaN")
	return setmetatable({ x, y, z }, V3)
end }
Vector2 = { new = function(x, y) return { X = x, Y = y, x = x, y = y } end }

------------------------------------------------------------------ CFrame (position p + rotation matrix r[1..9], row-major)
local CF = {}
local function mkcf(px, py, pz, r)
	return setmetatable({ p = Vector3.new(px, py, pz), r = r }, CF)
end
local ID = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function rmul(a, b)
	local o = {}
	for i = 0, 2 do
		for j = 0, 2 do
			o[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return o
end
local function rvec(r, v) return r[1] * v[1] + r[2] * v[2] + r[3] * v[3], r[4] * v[1] + r[5] * v[2] + r[6] * v[3], r[7] * v[1] + r[8] * v[2] + r[9] * v[3] end
CF.__index = function(c, k)
	if k == "p" or k == "Position" then return rawget(c, "p") end
	local p, r = rawget(c, "p"), rawget(c, "r")
	if k == "x" or k == "X" then return p[1] end
	if k == "y" or k == "Y" then return p[2] end
	if k == "z" or k == "Z" then return p[3] end
	if k == "lookVector" or k == "LookVector" then return Vector3.new(-r[3], -r[6], -r[9]) end
	if k == "rightVector" or k == "RightVector" then return Vector3.new(r[1], r[4], r[7]) end
	if k == "upVector" or k == "UpVector" then return Vector3.new(r[2], r[5], r[8]) end
	if k == "inverse" or k == "Inverse" then
		return function(cf)
			local q = cf.r
			local t = { q[1], q[4], q[7], q[2], q[5], q[8], q[3], q[6], q[9] }
			local x, y, z = rvec(t, cf.p)
			return mkcf(-x, -y, -z, t)
		end
	end
	if k == "toObjectSpace" then return function(a, b) return a:inverse() * b end end
	if k == "pointToObjectSpace" then return function(a, v) return a:inverse() * v end end
	if k == "pointToWorldSpace" then return function(a, v) return a * v end end
	if k == "components" then return function(cf) local q = cf.r return cf.p[1], cf.p[2], cf.p[3], q[1], q[2], q[3], q[4], q[5], q[6], q[7], q[8], q[9] end end
	if k == "lerp" or k == "Lerp" then return function(a, b, t) return mkcf(a.p[1] + (b.p[1] - a.p[1]) * t, a.p[2] + (b.p[2] - a.p[2]) * t, a.p[3] + (b.p[3] - a.p[3]) * t, t < 0.5 and a.r or b.r) end end
	error("CFrame has no member " .. tostring(k), 2)
end
CF.__mul = function(a, b)
	assert(getmetatable(a) == CF, "CFrame * : left side is not a CFrame")
	if getmetatable(b) == CF then
		local x, y, z = rvec(a.r, b.p)
		return mkcf(a.p[1] + x, a.p[2] + y, a.p[3] + z, rmul(a.r, b.r))
	elseif isV(b) then
		local x, y, z = rvec(a.r, b)
		return Vector3.new(a.p[1] + x, a.p[2] + y, a.p[3] + z)
	end
	error("CFrame * " .. type(b), 2)
end
CF.__add = function(a, b) assert(isV(b), "CFrame + non-Vector3") return mkcf(a.p[1] + b[1], a.p[2] + b[2], a.p[3] + b[3], a.r) end
CF.__sub = function(a, b) assert(isV(b), "CFrame - non-Vector3") return mkcf(a.p[1] - b[1], a.p[2] - b[2], a.p[3] - b[3], a.r) end
CF.__tostring = function(c) return "CFrame(" .. tostring(c.p) .. ")" end
local function angles(rx, ry, rz)
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	local Rx = { 1, 0, 0, 0, cx, -sx, 0, sx, cx }
	local Ry = { cy, 0, sy, 0, 1, 0, -sy, 0, cy }
	local Rz = { cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
	return rmul(rmul(Rx, Ry), Rz)
end
CFrame = {}
function CFrame.new(a, b, c, ...)
	if a == nil then return mkcf(0, 0, 0, ID) end
	if isV(a) then
		if b == nil then return mkcf(a[1], a[2], a[3], ID) end
		assert(isV(b), "CFrame.new(pos, lookAt) needs two Vector3")
		local z = (a - b)
		if z.magnitude < 1e-6 then return mkcf(a[1], a[2], a[3], ID) end
		z = z.unit
		local x = Vector3.new(0, 1, 0):Cross(z)
		if x.magnitude < 1e-6 then x = Vector3.new(1, 0, 0) end
		x = x.unit
		local y = z:Cross(x)
		return mkcf(a[1], a[2], a[3], { x[1], y[1], z[1], x[2], y[2], z[2], x[3], y[3], z[3] })
	end
	assert(type(a) == "number" and type(b) == "number" and type(c) == "number", "CFrame.new needs numbers")
	assert(a == a and b == b and c == c, "CFrame.new got NaN")
	local rest = { ... }
	if #rest == 9 then return mkcf(a, b, c, rest) end
	return mkcf(a, b, c, ID)
end
function CFrame.Angles(rx, ry, rz)
	assert(type(rx) == "number" and type(ry) == "number" and type(rz) == "number", "CFrame.Angles needs numbers")
	return mkcf(0, 0, 0, angles(rx, ry, rz))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.fromAxisAngle(axis, a)
	if math.abs(axis.y) > 0.5 then return CFrame.Angles(0, a, 0) elseif math.abs(axis.x) > 0.5 then return CFrame.Angles(a, 0, 0) end
	return CFrame.Angles(0, 0, a)
end
MOCK.isCFrame = function(c) return getmetatable(c) == CF end

------------------------------------------------------------------ colours, UDim2, Enum
local KNOWN_COLORS = {}
BrickColor = { new = function(name)
	assert(type(name) == "string", "BrickColor.new needs a name")
	KNOWN_COLORS[name] = true
	return { Name = name, Color = { r = 0.5, g = 0.5, b = 0.5 }, Number = 1 }
end, Random = function() return BrickColor.new("Bright red") end }
MOCK.colors = KNOWN_COLORS
Color3 = { new = function(r, g, b) return { r = r, g = g, b = b } end, fromRGB = function(r, g, b) return { r = r / 255, g = g / 255, b = b / 255 } end }
UDim2 = { new = function(...) return { ... } end }
local function enumSet(name)
	return setmetatable({}, { __index = function(t, k)
		local v = { Name = k, EnumType = name }
		rawset(t, k, v)
		return v
	end })
end
Enum = setmetatable({}, { __index = function(t, k) local s = enumSet(k) rawset(t, k, s) return s end })

------------------------------------------------------------------ events
local function Event(name)
	local e = { fns = {}, name = name }
	function e:connect(f)
		table.insert(self.fns, f)
		local c = {}
		function c.disconnect() for i, g in ipairs(e.fns) do if g == f then table.remove(e.fns, i) break end end end
		c.Disconnect = c.disconnect
		return c
	end
	e.Connect = e.connect
	function e:wait() local got repeat wait() until got return end
	function e:fire(...)
		local a, n = { ... }, select("#", ...)
		for _, f in ipairs(self.fns) do spawn(function() f(unpack(a, 1, n)) end) end
	end
	function e:fireNow(...)
		for _, f in ipairs(self.fns) do
			local ok, err = pcall(f, ...)
			if not ok then table.insert(MOCK.errors, tostring(err)) end
		end
	end
	return e
end
MOCK.Event = Event

------------------------------------------------------------------ instances
local EVENTS = { Touched = true, Changed = true, ChildAdded = true, ChildRemoved = true, PlayerAdded = true, PlayerRemoving = true,
	CharacterAdded = true, Chatted = true, OnServerEvent = true, OnClientEvent = true, MouseButton1Click = true, Error = true,
	MessageOut = true, Died = true, AncestryChanged = true, DescendantAdded = true, MouseButton1Down = true, MouseButton1Up = true,
	MouseLeave = true, MouseEnter = true, KeyDown = true, KeyUp = true, FocusLost = true }
local Inst = {}
local imt = {}
local allParts = {}
MOCK.allParts = allParts
local function isPart(cls)
	return cls == "Part" or cls == "WedgePart" or cls == "Seat" or cls == "VehicleSeat" or cls == "SpawnLocation" or cls == "TrussPart" or cls == "CornerWedgePart"
end
imt.__index = function(o, k)
	local props = rawget(o, "_p")
	local v = props[k]
	if v ~= nil then return v end
	if Inst[k] then return Inst[k] end
	if EVENTS[k] then local e = Event(k) props[k] = e return e end
	if k == "Position" and props.CFrame then return props.CFrame.p end
	if k == "Velocity" or k == "RotVelocity" then return Vector3.new() end
	for _, c in ipairs(rawget(o, "_c")) do if rawget(c, "_p").Name == k then return c end end
	return nil
end
imt.__newindex = function(o, k, v)
	local props = rawget(o, "_p")
	if k == "Parent" then
		local old = props.Parent
		if old == v then return end
		if old then
			local c = rawget(old, "_c")
			for i, x in ipairs(c) do if x == o then table.remove(c, i) break end end
		end
		props.Parent = v
		if v then table.insert(rawget(v, "_c"), o) end
		return
	end
	if k == "Position" then
		local cf = props.CFrame or CFrame.new()
		props.CFrame = setmetatable({ p = v, r = cf.r }, CF)
		return
	end
	if k == "CFrame" then assert(MOCK.isCFrame(v), "CFrame property set to a non-CFrame") end
	if k == "Size" and isPart(props.ClassName) then
		assert(getmetatable(v) == V3, "Size set to a non-Vector3")
		-- like old Roblox: resizing a part that is already in the world pushes it up out of whatever it overlaps
		if MOCK.pushOnResize and o:IsDescendantOf(workspace) and props.CFrame then
			props.CFrame = props.CFrame + Vector3.new(0, 40, 0)
		end
	end
	if k == "BrickColor" then assert(type(v) == "table" and v.Name, "BrickColor set to a non-BrickColor") end
	if k == "Material" then assert(type(v) == "table" and v.EnumType == "Material", "Material set to a non-material") end
	props[k] = v
end
imt.__tostring = function(o) return rawget(o, "_p").Name end
local function new(cls, parent)
	local o = setmetatable({ _p = { ClassName = cls, Name = cls }, _c = {} }, imt)
	if isPart(cls) then
		local p = rawget(o, "_p")
		p.Size = Vector3.new(4, 1, 2)
		p.CFrame = CFrame.new()
		p.Anchored = false
		p.CanCollide = true
		p.Transparency = 0
		p.BrickColor = BrickColor.new("Medium stone grey")
		table.insert(allParts, o)
	end
	if parent then o.Parent = parent end
	return o
end
MOCK.new = new
Instance = { new = function(cls, parent)
	assert(type(cls) == "string", "Instance.new needs a class name")
	return new(cls, parent)
end }
function Inst:FindFirstChild(n, rec)
	for _, c in ipairs(rawget(self, "_c")) do if c.Name == n then return c end end
	if rec then for _, c in ipairs(rawget(self, "_c")) do local f = c:FindFirstChild(n, true) if f then return f end end end
	return nil
end
function Inst:WaitForChild(n, timeout)
	local t0 = tick()
	while true do
		local c = self:FindFirstChild(n)
		if c then return c end
		if timeout and tick() - t0 > timeout then return nil end
		if tick() - t0 > 30 then error("infinite WaitForChild(" .. n .. ") on " .. tostring(self.Name)) end
		wait()
	end
end
function Inst:GetChildren() local t = {} for i, c in ipairs(rawget(self, "_c")) do t[i] = c end return t end
function Inst:GetDescendants()
	local t = {}
	local function rec(o) for _, c in ipairs(rawget(o, "_c")) do table.insert(t, c) rec(c) end end
	rec(self)
	return t
end
function Inst:ClearAllChildren() for _, c in ipairs(self:GetChildren()) do c:Destroy() end end
function Inst:Destroy()
	rawget(self, "_p").destroyed = true
	self.Parent = nil
	for _, c in ipairs(self:GetChildren()) do c:Destroy() end
end
Inst.Remove = Inst.Destroy
function Inst:IsA(c)
	local cls = self.ClassName
	if c == cls or c == "Instance" then return true end
	if c == "BasePart" then return isPart(cls) end
	if c == "Part" then return cls == "Part" or cls == "SpawnLocation" end
	if c == "GuiObject" then return cls:find("Text") ~= nil or cls == "Frame" end
	return false
end
function Inst:IsDescendantOf(a) local p = self.Parent while p do if p == a then return true end p = p.Parent end return false end
function Inst:Clone()
	local o = new(self.ClassName)
	for k, v in pairs(rawget(self, "_p")) do if k ~= "Parent" and type(v) ~= "table" or k == "CFrame" or k == "Size" or k == "BrickColor" then rawget(o, "_p")[k] = v end end
	for _, c in ipairs(self:GetChildren()) do c:Clone().Parent = o end
	return o
end
function Inst:GetFullName() local n = self.Name local p = self.Parent while p and p.ClassName ~= "DataModel" do n = p.Name .. "." .. n p = p.Parent end return n end
function Inst:GetService(n) return MOCK.services[n] or error("no service " .. n) end
function Inst:GetPlayers() local t = {} for _, c in ipairs(rawget(self, "_c")) do if c.ClassName == "Player" then table.insert(t, c) end end return t end
function Inst:GetPlayerFromCharacter(ch) for _, p in ipairs(self:GetPlayers()) do if p.Character == ch then return p end end return nil end
function Inst:Kick(r) table.insert(MOCK.log, "KICK " .. self.Name .. " " .. tostring(r)) self.Parent = nil end
function Inst:LoadCharacter() MOCK.makeCharacter(self) end
function Inst:FireClient(p, ...) MOCK.onFireClient(self, p, ...) end
function Inst:FireAllClients(...) for _, p in ipairs(MOCK.services.Players:GetPlayers()) do MOCK.onFireClient(self, p, ...) end end
function Inst:FireServer(...) error("FireServer on the server") end
function Inst:GetDataStore() return MOCK.store end
function Inst:GetMouse() local m = rawget(self, "_p").mouse or new("Mouse") rawget(self, "_p").mouse = m return m end
function Inst:AddItem(o, t) delay(t or 10, function() pcall(function() o:Destroy() end) end) end
function Inst:BindToClose(f) MOCK.onClose = f end
function Inst:MoveTo(v) end
function Inst:BreakJoints() end
function Inst:GetMass() return 1 end
function Inst:SetPrimaryPartCFrame(cf) end
function Inst:MakeJoints() end
function MOCK.onFireClient(remote, p, ...) end
MOCK.store = { data = {} }
function MOCK.store:GetAsync(k) return self.data[k] end
function MOCK.store:SetAsync(k, v) self.data[k] = v end

------------------------------------------------------------------ the game tree
game = new("DataModel")
game.Name = "Game"
MOCK.services = {}
for _, n in ipairs({ "Workspace", "Players", "ReplicatedStorage", "ReplicatedFirst", "ServerScriptService", "ServerStorage",
	"StarterGui", "Lighting", "Debris", "DataStoreService", "ScriptContext", "LogService", "SoundService", "Teams" }) do
	local s = new(n, game)
	s.Name = n
	MOCK.services[n] = s
end
workspace = MOCK.services.Workspace
Workspace = workspace

function MOCK.part(parent, name, size, cf)
	local p = new("Part", parent)
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	return p
end

function MOCK.makeCharacter(player)
	local c = new("Model")
	c.Name = player.Name
	local torso = MOCK.part(c, "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0))
	MOCK.part(c, "Head", Vector3.new(2, 1, 1), CFrame.new(0, 4.5, 0))
	local h = new("Humanoid", c)
	h.Name = "Humanoid"
	h.Health, h.MaxHealth, h.WalkSpeed, h.JumpPower = 100, 100, 16, 50
	c.Parent = workspace
	player.Character = c
	player.CharacterAdded:fire(c)
	return c
end

function MOCK.addPlayer(name, id)
	local p = new("Player")
	p.Name = name
	p.userId = id or math.random(1, 1e6)
	p.UserId = p.userId
	local pg = new("PlayerGui", p)
	pg.Name = "PlayerGui"
	p.Parent = MOCK.services.Players
	MOCK.services.Players.PlayerAdded:fire(p)
	return p
end

return MOCK
