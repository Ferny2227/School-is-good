-- A tiny fake Roblox for testing Shooter Arena scripts in plain Lua 5.1.
-- Vector3, CFrame (real math), Color3, BrickColor (name check), Enum, UDim2, Instance tree, events,
-- a virtual-time scheduler (wait / spawn / delay / tick) and simple raycasts against part boxes.

WARN = {}
local function warnOnce(msg)
	if not WARN[msg] then
		WARN[msg] = true
		print("WARN: " .. msg)
	end
end

------------------------------------------------------------------ Vector3
Vector3 = {}
local V3 = {}
V3.__index = function(v, k)
	if k == "X" or k == "x" then return rawget(v, "_x") end
	if k == "Y" or k == "y" then return rawget(v, "_y") end
	if k == "Z" or k == "z" then return rawget(v, "_z") end
	if k == "magnitude" or k == "Magnitude" then return math.sqrt(v._x ^ 2 + v._y ^ 2 + v._z ^ 2) end
	if k == "unit" or k == "Unit" then
		local m = math.sqrt(v._x ^ 2 + v._y ^ 2 + v._z ^ 2)
		if m == 0 then return Vector3.new(0 / 0, 0 / 0, 0 / 0) end
		return Vector3.new(v._x / m, v._y / m, v._z / m)
	end
	if k == "Dot" or k == "dot" then return function(a, b) return a._x * b._x + a._y * b._y + a._z * b._z end end
	if k == "Cross" or k == "cross" then return function(a, b) return Vector3.new(a._y * b._z - a._z * b._y, a._z * b._x - a._x * b._z, a._x * b._y - a._y * b._x) end end
	if k == "Lerp" or k == "lerp" then return function(a, b, t) return a + (b - a) * t end end
	error("Vector3 has no member " .. tostring(k), 2)
end
local function isV3(v) return type(v) == "table" and getmetatable(v) == V3 end
function Vector3.new(x, y, z)
	return setmetatable({ _x = x or 0, _y = y or 0, _z = z or 0 }, V3)
end
V3.__add = function(a, b)
	if not isV3(a) or not isV3(b) then error("Vector3 + non-Vector3", 2) end
	return Vector3.new(a._x + b._x, a._y + b._y, a._z + b._z)
end
V3.__sub = function(a, b)
	if not isV3(a) or not isV3(b) then error("Vector3 - non-Vector3", 2) end
	return Vector3.new(a._x - b._x, a._y - b._y, a._z - b._z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(a * b._x, a * b._y, a * b._z) end
	if type(b) == "number" then return Vector3.new(a._x * b, a._y * b, a._z * b) end
	if isV3(a) and isV3(b) then return Vector3.new(a._x * b._x, a._y * b._y, a._z * b._z) end
	error("bad Vector3 *", 2)
end
V3.__div = function(a, b)
	if type(b) == "number" then return Vector3.new(a._x / b, a._y / b, a._z / b) end
	return Vector3.new(a._x / b._x, a._y / b._y, a._z / b._z)
end
V3.__unm = function(a) return Vector3.new(-a._x, -a._y, -a._z) end
V3.__eq = function(a, b) return a._x == b._x and a._y == b._y and a._z == b._z end
V3.__tostring = function(a) return string.format("%.2f, %.2f, %.2f", a._x, a._y, a._z) end

Vector2 = {}
local V2 = {}
V2.__index = function(v, k)
	if k == "X" or k == "x" then return rawget(v, "_x") end
	if k == "Y" or k == "y" then return rawget(v, "_y") end
	if k == "magnitude" then return math.sqrt(v._x ^ 2 + v._y ^ 2) end
	error("Vector2 has no member " .. tostring(k), 2)
end
function Vector2.new(x, y) return setmetatable({ _x = x or 0, _y = y or 0 }, V2) end
V2.__add = function(a, b) return Vector2.new(a._x + b._x, a._y + b._y) end
V2.__sub = function(a, b) return Vector2.new(a._x - b._x, a._y - b._y) end
V2.__mul = function(a, b) if type(b) == "number" then return Vector2.new(a._x * b, a._y * b) end return Vector2.new(a._x * b._x, a._y * b._y) end

------------------------------------------------------------------ CFrame
CFrame = {}
local CF = {}
local function isCF(v) return type(v) == "table" and getmetatable(v) == CF end
local function mk(p, r)
	return setmetatable({ _p = p, _r = r }, CF)
end
local function matmul(a, b)
	local r = {}
	for i = 1, 3 do
		r[i] = {}
		for j = 1, 3 do
			r[i][j] = a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j]
		end
	end
	return r
end
local function matvec(a, v)
	return Vector3.new(a[1][1] * v._x + a[1][2] * v._y + a[1][3] * v._z, a[2][1] * v._x + a[2][2] * v._y + a[2][3] * v._z, a[3][1] * v._x + a[3][2] * v._y + a[3][3] * v._z)
end
local function transpose(a)
	return { { a[1][1], a[2][1], a[3][1] }, { a[1][2], a[2][2], a[3][2] }, { a[1][3], a[2][3], a[3][3] } }
end
local I = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
function CFrame.new(a, b, c, ...)
	local extra = { ... }
	if a == nil then return mk(Vector3.new(0, 0, 0), I) end
	if type(a) == "number" then
		if #extra == 9 then
			local r = { { extra[1], extra[2], extra[3] }, { extra[4], extra[5], extra[6] }, { extra[7], extra[8], extra[9] } }
			return mk(Vector3.new(a, b, c), r)
		end
		return mk(Vector3.new(a, b or 0, c or 0), I)
	end
	if isV3(a) and b == nil then return mk(a, I) end
	if isV3(a) and isV3(b) then
		-- look at
		local f = (b - a)
		if f.magnitude < 1e-9 then return mk(a, I) end
		f = f.unit
		local up = Vector3.new(0, 1, 0)
		if math.abs(f:Dot(up)) > 0.9999 then up = Vector3.new(0, 0, 1) end
		local right = f:Cross(up).unit
		local up2 = right:Cross(f).unit
		local back = -f
		local r = { { right._x, up2._x, back._x }, { right._y, up2._y, back._y }, { right._z, up2._z, back._z } }
		return mk(a, r)
	end
	error("bad CFrame.new args", 2)
end
local function rx(t) local c, s = math.cos(t), math.sin(t) return { { 1, 0, 0 }, { 0, c, -s }, { 0, s, c } } end
local function ry(t) local c, s = math.cos(t), math.sin(t) return { { c, 0, s }, { 0, 1, 0 }, { -s, 0, c } } end
local function rz(t) local c, s = math.cos(t), math.sin(t) return { { c, -s, 0 }, { s, c, 0 }, { 0, 0, 1 } } end
function CFrame.Angles(x, y, z)
	return mk(Vector3.new(0, 0, 0), matmul(matmul(rx(x or 0), ry(y or 0)), rz(z or 0)))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CF.__mul = function(a, b)
	if isCF(a) and isCF(b) then
		return mk(a._p + matvec(a._r, b._p), matmul(a._r, b._r))
	end
	if isCF(a) and isV3(b) then
		return a._p + matvec(a._r, b)
	end
	error("bad CFrame *", 2)
end
CF.__add = function(a, b)
	if not isV3(b) then error("CFrame + non-Vector3", 2) end
	return mk(a._p + b, a._r)
end
CF.__sub = function(a, b)
	if not isV3(b) then error("CFrame - non-Vector3", 2) end
	return mk(a._p - b, a._r)
end
CF.__index = function(c, k)
	if k == "p" or k == "Position" then return c._p end
	if k == "X" or k == "x" then return c._p._x end
	if k == "Y" or k == "y" then return c._p._y end
	if k == "Z" or k == "z" then return c._p._z end
	if k == "lookVector" or k == "LookVector" then return Vector3.new(-c._r[1][3], -c._r[2][3], -c._r[3][3]) end
	if k == "rightVector" or k == "RightVector" then return Vector3.new(c._r[1][1], c._r[2][1], c._r[3][1]) end
	if k == "upVector" or k == "UpVector" then return Vector3.new(c._r[1][2], c._r[2][2], c._r[3][2]) end
	if k == "inverse" or k == "Inverse" then
		return function(self)
			local rt = transpose(self._r)
			return mk(-matvec(rt, self._p), rt)
		end
	end
	if k == "pointToWorldSpace" or k == "PointToWorldSpace" then return function(self, v) return self * v end end
	if k == "pointToObjectSpace" or k == "PointToObjectSpace" then return function(self, v) return matvec(transpose(self._r), v - self._p) end end
	if k == "vectorToWorldSpace" or k == "VectorToWorldSpace" then return function(self, v) return matvec(self._r, v) end end
	if k == "vectorToObjectSpace" or k == "VectorToObjectSpace" then return function(self, v) return matvec(transpose(self._r), v) end end
	if k == "toObjectSpace" then return function(self, o) return self:inverse() * o end end
	if k == "lerp" or k == "Lerp" then return function(self, o, t) return mk(self._p + (o._p - self._p) * t, o._r) end end
	error("CFrame has no member " .. tostring(k), 2)
end

------------------------------------------------------------------ Color3 / BrickColor / UDim2 / Ray / Enum
Color3 = {}
local C3 = { __index = function(c, k)
	if k == "r" or k == "R" then return rawget(c, "_r") end
	if k == "g" or k == "G" then return rawget(c, "_g") end
	if k == "b" or k == "B" then return rawget(c, "_b") end
	if k == "lerp" or k == "Lerp" then return function(a, b, t) return Color3.new(a._r + (b._r - a._r) * t, a._g + (b._g - a._g) * t, a._b + (b._b - a._b) * t) end end
	error("Color3 has no member " .. tostring(k), 2)
end }
function Color3.new(r, g, b) return setmetatable({ _r = r or 0, _g = g or 0, _b = b or 0 }, C3) end
function Color3.fromRGB(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end

local BRICK = {}
for _, n in ipairs({ "White", "Grey", "Light yellow", "Brick yellow", "Light green (Mint)", "Light reddish violet", "Pastel Blue", "Light orange brown",
	"Nougat", "Bright red", "Med. reddish violet", "Bright blue", "Bright yellow", "Earth orange", "Black", "Dark grey", "Dark green", "Medium green",
	"Lig. Yellowich orange", "Bright green", "Dark orange", "Light bluish violet", "Light blue", "Bright orange", "Bright bluish green", "Earth yellow",
	"Bright violet", "Earth blue", "Earth green", "Sand blue", "Sand violet", "Sand yellow", "Sand red", "Sand green", "Medium stone grey",
	"Dark stone grey", "Light stone grey", "Reddish brown", "Brown", "Institutional white", "Mid gray", "Really black", "Really red", "Deep orange",
	"Alder", "Dusty Rose", "Olive", "New Yeller", "Really blue", "Navy blue", "Deep blue", "Cyan", "CGA brown", "Magenta", "Pink", "Teal",
	"Toothpaste", "Lime green", "Camo", "Grime", "Lavender", "Pastel light blue", "Pastel orange", "Pastel violet", "Pastel blue-green",
	"Pastel green", "Pastel yellow", "Pastel brown", "Royal purple", "Hot pink", "Light orange", "Cool yellow", "Gold", "Medium blue",
	"Bright bluish violet", "Bright reddish violet", "Bright yellowish green", "Medium red", "Dark red", "Steel blue", "Neon orange" }) do
	BRICK[n] = true
end
BRICK_RGB = { ["Bright red"]={196,40,28}, ["Bright blue"]={13,105,172}, ["Bright green"]={75,151,75}, ["Dark green"]={40,127,71}, ["Earth green"]={39,70,45},
 ["Brick yellow"]={215,197,154}, ["Nougat"]={204,142,105}, ["Light orange"]={234,184,146}, ["Cool yellow"]={253,234,141}, ["Reddish brown"]={105,64,40},
 ["Brown"]={124,92,70}, ["Medium stone grey"]={163,162,165}, ["Dark stone grey"]={99,95,98}, ["Light stone grey"]={229,228,223}, ["Really black"]={17,17,17},
 ["Institutional white"]={248,248,248}, ["New Yeller"]={255,255,0}, ["Deep blue"]={33,84,185}, ["Bright orange"]={218,133,65}, ["Bright yellow"]={245,205,48},
 ["Sand red"]={149,121,119}, ["Dark orange"]={160,95,53}, ["Olive"]={193,190,66}, ["Navy blue"]={0,32,96}, ["Really red"]={255,0,0}, ["Sand blue"]={116,134,157},
 ["Black"]={27,42,53}, ["Gold"]={239,184,56}, ["Pastel brown"]={255,204,153}, ["Bright violet"]={107,50,124}, ["Cyan"]={4,175,236}, ["Sand green"]={120,144,130},
 ["Hot pink"]={255,0,191}, ["Lime green"]={0,255,0}, ["Slime green"]={80,109,84} }
BrickColor = {}
local BC = { __index = function(b, k)
	if k == "Color" then
		local c = BRICK_RGB[rawget(b, "_n")]
		if c then return Color3.new(c[1] / 255, c[2] / 255, c[3] / 255) end
		return Color3.new(0.5, 0.5, 0.5)
	end
	if k == "Name" then return rawget(b, "_n") end
	error("BrickColor has no member " .. tostring(k), 2)
end }
function BrickColor.new(n)
	if type(n) == "string" and not BRICK[n] then warnOnce("unknown BrickColor " .. n) end
	return setmetatable({ _n = n }, BC)
end
BC.__eq = function(a, b) return a._n == b._n end

UDim2 = {}
local UD = { __index = function(u, k)
	if k == "X" then return { Scale = u._a, Offset = u._b } end
	if k == "Y" then return { Scale = u._c, Offset = u._d } end
	error("UDim2 has no member " .. tostring(k), 2)
end }
function UDim2.new(a, b, c, d)
	for _, v in ipairs({ a, b, c, d }) do
		if type(v) ~= "number" then error("UDim2.new needs 4 numbers", 2) end
	end
	return setmetatable({ _a = a, _b = b, _c = c, _d = d }, UD)
end
UDim = { new = function(a, b) return { Scale = a, Offset = b } end }
NumberRange = { new = function(a, b) return { Min = a, Max = b or a } end }
NumberSequence = { new = function(a) return { a } end }
ColorSequence = { new = function(a) return { a } end }

Ray = {}
function Ray.new(o, d)
	if not isV3(o) or not isV3(d) then error("Ray.new needs Vector3s", 2) end
	return { Origin = o, Direction = d, Unit = { Origin = o, Direction = d.unit } }
end

local MATERIALS = {}
for _, n in ipairs({ "Plastic", "SmoothPlastic", "Neon", "Wood", "WoodPlanks", "Marble", "Slate", "Concrete", "Granite", "Brick", "Pebble",
	"Cobblestone", "CorrodedMetal", "DiamondPlate", "Foil", "Metal", "Grass", "Sand", "Fabric", "Ice", "Glass", "ForceField" }) do
	MATERIALS[n] = true
end
Enum = setmetatable({}, { __index = function(t, enumName)
	local e = setmetatable({}, { __index = function(t2, item)
		if enumName == "Material" and not MATERIALS[item] then
			warnOnce("Material " .. item .. " is not in old (2016) clients (pcall keeps it safe)")
			error("no material " .. item)
		end
		local v = setmetatable({ Name = item, EnumType = enumName, Value = 0 }, { __tostring = function() return "Enum." .. enumName .. "." .. item end })
		rawset(t2, item, v)
		return v
	end })
	rawset(t, enumName, e)
	return e
end })

------------------------------------------------------------------ scheduler (virtual time)
NOW = 0
local queue = {} -- { at, co, args }
function tick() return NOW end
function time() return NOW end
local function schedule(at, co, ...)
	table.insert(queue, { at = at, co = co, args = { ... }, n = select("#", ...) })
end
ERRORS = {}
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		table.insert(ERRORS, tostring(err) .. "\n" .. debug.traceback(co))
		print("ERROR in thread: " .. tostring(err))
		print(debug.traceback(co))
	end
end
function wait(t)
	t = t or 0.03
	local co = coroutine.running()
	if not co then error("wait outside coroutine") end
	schedule(NOW + math.max(t, 0.03), co)
	coroutine.yield()
	return t, NOW
end
function spawn(f)
	local co = coroutine.create(f)
	schedule(NOW + 0.03, co)
end
function delay(t, f)
	local co = coroutine.create(f)
	schedule(NOW + (t or 0), co)
end
function runFor(seconds)
	local stop = NOW + seconds
	while true do
		table.sort(queue, function(a, b) return a.at < b.at end)
		local nxt = queue[1]
		if not nxt or nxt.at > stop then break end
		table.remove(queue, 1)
		NOW = math.max(NOW, nxt.at)
		resume(nxt.co, unpack(nxt.args, 1, nxt.n))
		for _, h in ipairs(HEARTBEAT or {}) do h(NOW) end
	end
	NOW = stop
end
function runMain(f)
	local co = coroutine.create(f)
	resume(co)
end

------------------------------------------------------------------ events
local function newEvent(name)
	local ev = { _fns = {}, _name = name }
	local function connect(self, fn)
		local c = { Connected = true }
		table.insert(self._fns, fn)
		function c.disconnect()
			for i, f in ipairs(self._fns) do
				if f == fn then table.remove(self._fns, i) break end
			end
		end
		c.Disconnect = c.disconnect
		return c
	end
	ev.connect = connect
	ev.Connect = connect
	function ev.wait(self)
		local co = coroutine.running()
		local fired = false
		local res
		local c
		c = connect(self, function(...)
			if not fired then
				fired = true
				res = { ... }
				c.disconnect()
				schedule(NOW, co)
			end
		end)
		coroutine.yield()
		return unpack(res or {})
	end
	ev.Wait = ev.wait
	function ev.Fire(self, ...)
		local fns = {}
		for i, f in ipairs(self._fns) do fns[i] = f end
		for _, f in ipairs(fns) do
			local co = coroutine.create(f)
			resume(co, ...)
		end
	end
	return ev
end
newEventGlobal = newEvent

------------------------------------------------------------------ Instances
local Inst = {}
local CLASS_DEFAULTS = {
	Part = { Size = Vector3.new(4, 1.2, 2), Transparency = 0, CanCollide = true, Anchored = false, Reflectance = 0, LocalTransparencyModifier = 0 },
}
local IS_A = {
	Part = { "BasePart", "PVInstance" }, WedgePart = { "BasePart" }, TrussPart = { "BasePart" }, SpawnLocation = { "BasePart", "Part" },
	MeshPart = { "BasePart" }, Seat = { "BasePart", "Part" },
	Weld = { "JointInstance" }, Motor6D = { "JointInstance", "Motor" }, Motor = { "JointInstance" },
	IntValue = { "ValueBase" }, NumberValue = { "ValueBase" }, StringValue = { "ValueBase" }, BoolValue = { "ValueBase" },
	Vector3Value = { "ValueBase" }, ObjectValue = { "ValueBase" }, Color3Value = { "ValueBase" },
	ScreenGui = { "LayerCollector", "GuiBase2d" }, Frame = { "GuiObject", "GuiBase2d" }, TextLabel = { "GuiObject", "GuiBase2d" },
	TextButton = { "GuiObject", "GuiButton", "GuiBase2d" }, ImageLabel = { "GuiObject" }, ImageButton = { "GuiObject", "GuiButton" },
	PointLight = { "Light" }, SpotLight = { "Light" }, SurfaceLight = { "Light" },
	LocalScript = { "Script", "BaseScript", "LuaSourceContainer" }, Script = { "BaseScript", "LuaSourceContainer" },
	Tool = { "BackpackItem" }, Model = { "PVInstance" }, Workspace = { "Model" },
}
local idN = 0
local function isA(o, c)
	if o.ClassName == c or c == "Instance" then return true end
	for _, x in ipairs(IS_A[o.ClassName] or {}) do
		if x == c then return true end
	end
	return false
end
local function children(o) return rawget(o, "_children") end
local methods = {}
function methods:FindFirstChild(name, recursive)
	for _, c in ipairs(children(self)) do
		if c.Name == name then return c end
	end
	if recursive then
		for _, c in ipairs(children(self)) do
			local f = c:FindFirstChild(name, true)
			if f then return f end
		end
	end
	return nil
end
methods.findFirstChild = methods.FindFirstChild
function methods:FindFirstChildOfClass(cn)
	for _, c in ipairs(children(self)) do
		if c.ClassName == cn then return c end
	end
end
function methods:FindFirstChildWhichIsA(cn)
	for _, c in ipairs(children(self)) do
		if isA(c, cn) then return c end
	end
end
function methods:GetChildren()
	local t = {}
	for i, c in ipairs(children(self)) do t[i] = c end
	return t
end
methods.getChildren = methods.GetChildren
function methods:GetDescendants()
	local t = {}
	local function rec(o)
		for _, c in ipairs(children(o)) do
			table.insert(t, c)
			rec(c)
		end
	end
	rec(self)
	return t
end
function methods:WaitForChild(name, timeout)
	local c = self:FindFirstChild(name)
	local waited = 0
	while not c do
		if not coroutine.running() then error("WaitForChild " .. name .. " outside coroutine") end
		wait(0.1)
		waited = waited + 0.1
		if waited > 30 then error("WaitForChild timed out: " .. name .. " in " .. self.Name) end
		c = self:FindFirstChild(name)
	end
	return c
end
methods.waitForChild = methods.WaitForChild
function methods:IsA(c) return isA(self, c) end
methods.isA = methods.IsA
function methods:IsDescendantOf(anc)
	local p = self.Parent
	while p do
		if p == anc then return true end
		p = p.Parent
	end
	return false
end
function methods:IsAncestorOf(d) return d:IsDescendantOf(self) end
function methods:Destroy()
	self.Parent = nil
	rawset(self, "_destroyed", true)
	for _, c in ipairs(self:GetChildren()) do c:Destroy() end
end
methods.destroy = methods.Destroy
methods.Remove = methods.Destroy
function methods:ClearAllChildren()
	for _, c in ipairs(self:GetChildren()) do c:Destroy() end
end
function methods:Clone()
	local n = Instance.new(self.ClassName)
	for k, v in pairs(rawget(self, "_props")) do
		if k ~= "Parent" then n[k] = v end
	end
	for _, c in ipairs(children(self)) do
		local cc = c:Clone()
		cc.Parent = n
	end
	return n
end
methods.clone = methods.Clone
function methods:GetFullName()
	local t = {}
	local o = self
	while o do
		table.insert(t, 1, o.Name)
		o = o.Parent
	end
	return table.concat(t, ".")
end
function methods:GetPropertyChangedSignal(prop)
	local evs = rawget(self, "_propEvents")
	if not evs[prop] then evs[prop] = newEvent(prop) end
	return evs[prop]
end
function methods:BreakJoints() end
function methods:MakeJoints() end
function methods:SetPrimaryPartCFrame(cf) end
function methods:GetMass() return 1 end
-- Humanoid
function methods:TakeDamage(n)
	if self:FindFirstChildOfClass("ForceField") or (self.Parent and self.Parent:FindFirstChildOfClass("ForceField")) then return end
	self.Health = math.max(0, self.Health - n)
end
function methods:MoveTo(pos) rawget(self, "_props").MoveGoal = pos end
function methods:EquipTool(t)
	if self.Parent then t.Parent = self.Parent end
end
function methods:UnequipTools() end
function methods:LoadAnimation() return { Play = function() end, Stop = function() end } end
function methods:Play() end
function methods:Stop() end
function methods:Resume() end
function methods:Pause() end
-- Sound / Debris
function methods:AddItem(o, t)
	delay(t or 10, function() if o.Parent then o:Destroy() end end)
end
methods.addItem = methods.AddItem

local EVENT_NAMES = { Touched = true, TouchEnded = true, Changed = true, ChildAdded = true, ChildRemoved = true, Died = true, MouseButton1Click = true,
	MouseButton1Down = true, MouseButton1Up = true, MouseEnter = true, MouseLeave = true, CharacterAdded = true, CharacterRemoving = true, Chatted = true,
	OnServerEvent = true, OnClientEvent = true, PlayerAdded = true, PlayerRemoving = true, Equipped = true, Unequipped = true, Activated = true,
	DescendantAdded = true, AncestryChanged = true, InputBegan = true, InputEnded = true, InputChanged = true, HealthChanged = true, FocusLost = true,
	Heartbeat = true, RenderStepped = true, Stepped = true, Button1Down = true, Button1Up = true, Button2Down = true, Button2Up = true,
	KeyDown = true, KeyUp = true, WheelForward = true, WheelBackward = true, Move = true, Idle = true, TouchStarted = true, TouchMoved = true,
	TouchEnded2 = true, LastInputTypeChanged = true, Running = true, StateChanged = true }

local function setParent(o, p)
	local old = rawget(o, "_props").Parent
	if old == p then return end
	if old then
		local kids = children(old)
		for i, c in ipairs(kids) do
			if c == o then table.remove(kids, i) break end
		end
		local ev = rawget(old, "_events").ChildRemoved
		if ev then ev:Fire(o) end
	end
	rawget(o, "_props").Parent = p
	if p then
		if rawget(p, "_destroyed") then warnOnce("parenting to a destroyed object: " .. o.Name) end
		table.insert(children(p), o)
		local ev = rawget(p, "_events").ChildAdded
		if ev then ev:Fire(o) end
		local onAdd = rawget(p, "_onChildAdded")
		if onAdd then onAdd(o) end
	end
end

Inst.__index = function(o, k)
	local props = rawget(o, "_props")
	if k == "Parent" then return props.Parent end
	if props[k] ~= nil then return props[k] end
	if methods[k] then return methods[k] end
	if EVENT_NAMES[k] then
		local evs = rawget(o, "_events")
		if not evs[k] then evs[k] = newEvent(k) end
		return evs[k]
	end
	local custom = rawget(o, "_get")
	if custom then
		local v = custom(o, k)
		if v ~= nil then return v end
	end
	-- BasePart helpers
	if k == "Position" and props.CFrame then return props.CFrame.p end
	if k == "CFrame" and isA(o, "BasePart") then return CFrame.new() end
	if k == "Velocity" or k == "AssemblyLinearVelocity" then return Vector3.new() end
	-- a child by name (like workspace.Part)
	for _, c in ipairs(children(o)) do
		if c.Name == k then return c end
	end
	return nil
end
Inst.__newindex = function(o, k, v)
	local props = rawget(o, "_props")
	if k == "Parent" then
		setParent(o, v)
		return
	end
	if k == "Position" and isA(o, "BasePart") then
		local cf = props.CFrame or CFrame.new()
		props.CFrame = CFrame.new(v) * (cf - cf.p)
		return
	end
	if k == "Size" and isA(o, "BasePart") then
		if not isV3(v) then error("Size must be a Vector3", 2) end
		if props.Shape == Enum.PartType.Ball then
			local m = math.min(v.X, v.Y, v.Z)
			v = Vector3.new(m, m, m)
		end
	end
	if k == "Shape" and v == Enum.PartType.Ball and props.Size then
		local m = math.min(props.Size.X, props.Size.Y, props.Size.Z)
		props.Size = Vector3.new(m, m, m)
	end
	if k == "CFrame" and not isCF(v) then error("CFrame must be a CFrame (got " .. type(v) .. ")", 2) end
	if (k == "Health") then
		local old = props.Health
		props.Health = math.min(v, props.MaxHealth or 100)
		if old and old > 0 and props.Health <= 0 then
			local ev = rawget(o, "_events").Died
			if ev then ev:Fire() end
		end
		return
	end
	local setter = rawget(o, "_set")
	if setter and setter(o, k, v) then return end
	props[k] = v
	local pe = rawget(o, "_propEvents")[k]
	if pe then pe:Fire() end
	local ch = rawget(o, "_events").Changed
	if ch and k == "Value" then ch:Fire(v) end
end
Inst.__tostring = function(o) return o.Name end

INSTANCES = 0
Instance = {}
function Instance.new(class, parent)
	idN = idN + 1
	INSTANCES = INSTANCES + 1
	local o = setmetatable({ _props = { Name = class, ClassName = class }, _children = {}, _events = {}, _propEvents = {} }, Inst)
	local props = rawget(o, "_props")
	props.Archivable = true
	if class == "Part" or class == "WedgePart" or class == "TrussPart" or class == "SpawnLocation" or class == "Seat" then
		props.Size = Vector3.new(4, 1.2, 2)
		props.Transparency = 0
		props.CanCollide = true
		props.Anchored = false
		props.Reflectance = 0
		props.LocalTransparencyModifier = 0
		props.CFrame = CFrame.new()
		props.BrickColor = BrickColor.new("Medium stone grey")
		props.Shape = Enum.PartType.Block
		if class == "TrussPart" then props.Size = Vector3.new(2, 2, 2) end
	elseif class == "Humanoid" then
		props.Health = 100
		props.MaxHealth = 100
		props.WalkSpeed = 16
		props.JumpPower = 50
		props.AutoRotate = true
		props.MoveDirection = Vector3.new()
		props.CameraOffset = Vector3.new()
		props.Jump = false
	elseif class == "IntValue" or class == "NumberValue" then
		props.Value = 0
	elseif class == "StringValue" then
		props.Value = ""
	elseif class == "BoolValue" then
		props.Value = false
	elseif class == "Vector3Value" then
		props.Value = Vector3.new()
	elseif class == "ScreenGui" or class == "Frame" or class == "TextLabel" or class == "TextButton" or class == "ImageLabel" or class == "ImageButton" then
		props.Visible = true
		props.Size = UDim2.new(0, 100, 0, 100)
		props.Position = UDim2.new(0, 0, 0, 0)
		props.AbsolutePosition = Vector2.new(500, 300)
		props.AbsoluteSize = Vector2.new(100, 100)
		props.BackgroundTransparency = 0
		props.Text = ""
	elseif class == "Tool" then
		props.Enabled = true
	elseif class == "Sound" then
		props.Volume = 0.5
	end
	if parent then o.Parent = parent end
	return o
end

------------------------------------------------------------------ geometry tests: is a point inside a part?
function pointInPart(p, pt)
	local cf, s = p.CFrame, p.Size
	local l = cf:pointToObjectSpace(pt)
	local hx, hy, hz = s.X / 2, s.Y / 2, s.Z / 2
	local shape = p.Shape and p.Shape.Name or "Block"
	if p.ClassName == "Part" and shape == "Ball" then
		return l.magnitude <= hx
	end
	if p.ClassName == "Part" and shape == "Cylinder" then
		local r = math.min(hy, hz)
		return math.abs(l.X) <= hx and (l.Y ^ 2 + l.Z ^ 2) <= r * r
	end
	if math.abs(l.X) > hx or math.abs(l.Y) > hy or math.abs(l.Z) > hz then return false end
	if p.ClassName == "WedgePart" then
		-- full height at +Z, zero at -Z
		local h = (l.Z + hz) / (2 * hz) * (2 * hy)
		return (l.Y + hy) <= h
	end
	return true
end
-- bounding sphere radius for quick rejection
function partRadius(p)
	local s = p.Size
	return math.sqrt(s.X * s.X + s.Y * s.Y + s.Z * s.Z) / 2
end
