-- A fake Roblox engine for running a real place's scripts outside Roblox (Lua 5.1).
-- The API surface (classes, properties, methods, events, enums) comes from a real Roblox API dump,
-- so anything the chosen engine version doesn't have errors exactly like it would in that version.
-- Server and client run in one process; every thread knows if it is "server" or a player's client.
--
-- Needs: mock.lua from shooter-arena (Vector3, CFrame, Color3, BrickColor, UDim2...) loaded first,
-- and the globals API (from gen_api.py), PLACE (from export.py), OPTIONS.

local API = API
local OPT = OPTIONS or {}
LOG = {}
ERRORS = {}
local function log(kind, msg)
	table.insert(LOG, string.format("[%7.2f] %-6s %s", NOW or 0, kind, msg))
	if OPT.echo then print(LOG[#LOG]) end
end
SIMLOG = log

------------------------------------------------------------------------------- datatypes
-- extend mock.lua's types with what 2016-2018 Roblox had
local UDmeta = getmetatable(UDim2.new(0, 0, 0, 0))
-- Roblox treats anything that isn't a number as 0 in datatype constructors
local rawUDim2 = UDim2.new
UDim2.new = function(a, b, c, d) return rawUDim2(tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0, tonumber(d) or 0) end
local rawV3 = Vector3.new
Vector3.new = function(a, b, c) return rawV3(tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0) end
local rawV2 = Vector2.new
Vector2.new = function(a, b) return rawV2(tonumber(a) or 0, tonumber(b) or 0) end
UDmeta.__add = function(a, b) return UDim2.new(a._a + b._a, a._b + b._b, a._c + b._c, a._d + b._d) end
UDmeta.__sub = function(a, b) return UDim2.new(a._a - b._a, a._b - b._b, a._c - b._c, a._d - b._d) end
UDmeta.__unm = function(a) return UDim2.new(-a._a, -a._b, -a._c, -a._d) end
UDmeta.__eq = function(a, b) return a._a == b._a and a._b == b._b and a._c == b._c and a._d == b._d end
UDmeta.__tostring = function(a) return string.format("{%g, %d}, {%g, %d}", a._a, a._b, a._c, a._d) end
local oldUDIndex = UDmeta.__index
UDmeta.__index = function(u, k)
	if k == "Width" then return UDim.new(u._a, u._b) end
	if k == "Height" then return UDim.new(u._c, u._d) end
	if k == "lerp" or k == "Lerp" then
		if not OPT.udim2Lerp then error("Lerp is not a valid member of UDim2", 2) end
		return function(a, b, t) return UDim2.new(a._a + (b._a - a._a) * t, a._b + (b._b - a._b) * t, a._c + (b._c - a._c) * t, a._d + (b._d - a._d) * t) end
	end
	return oldUDIndex(u, k)
end
local C3meta = getmetatable(Color3.new())
C3meta.__eq = function(a, b) return a._r == b._r and a._g == b._g and a._b == b._b end
C3meta.__tostring = function(c) return string.format("%g, %g, %g", c._r, c._g, c._b) end
local realFromRGB = Color3.fromRGB
Color3.fromRGB = nil
Color3.fromHSV = nil
if OPT.color3FromRGB then Color3.fromRGB = realFromRGB end
if OPT.color3FromHSV then
	Color3.fromHSV = function(h, s, v)
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		i = i % 6
		if i == 0 then return Color3.new(v, t, p) elseif i == 1 then return Color3.new(q, v, p) elseif i == 2 then return Color3.new(p, v, t)
		elseif i == 3 then return Color3.new(p, q, v) elseif i == 4 then return Color3.new(t, p, v) end
		return Color3.new(v, p, q)
	end
end
local V2meta = getmetatable(Vector2.new())
V2meta.__eq = function(a, b) return a._x == b._x and a._y == b._y end
local BCmeta = getmetatable(BrickColor.new("White"))
local oldBrickNew = BrickColor.new
BrickColor.new = function(n, ...)
	if type(n) == "number" then return setmetatable({ _n = "#" .. n }, BCmeta) end
	if type(n) == "table" and getmetatable(n) == C3meta then return setmetatable({ _n = "color" }, BCmeta) end
	return oldBrickNew(n, ...)
end
for _, n in ipairs({ "White", "Gray", "DarkGray", "Black", "Red", "Yellow", "Green", "Blue" }) do
	BrickColor[n] = function() return BrickColor.new(n) end
end
BrickColor.random = function() return BrickColor.new("White") end
BrickColor.palette = function(i) return setmetatable({ _n = "palette" .. tostring(i) }, BCmeta) end
BrickColor.Random = BrickColor.random
for _, n in ipairs({ "DarkGray", "Gray", "White", "Black", "Red", "Yellow", "Green", "Blue" }) do BrickColor[n] = BrickColor[n] end
ColorSequence = { new = function(a, b) return { Keypoints = { a, b } } end }
NumberSequence = { new = function(a, b) return { Keypoints = { a, b } } end }
Rect = nil
if OPT.tweenInfo then
	TweenInfo = { new = function(t, s, d) return { Time = t or 1, EasingStyle = s, EasingDirection = d } end }
end

------------------------------------------------------------------------------- Enums from the dump
local ENUMS = {}
local function enumItem(enumName, itemName)
	local items = API.enums[enumName]
	if not items or items[itemName] == nil then return nil end
	ENUMS[enumName] = ENUMS[enumName] or {}
	local e = ENUMS[enumName][itemName]
	if not e then
		e = setmetatable({ Name = itemName, Value = items[itemName], EnumType = enumName }, {
			__tostring = function() return "Enum." .. enumName .. "." .. itemName end })
		ENUMS[enumName][itemName] = e
	end
	return e
end
local function enumFromValue(enumName, value)
	local items = API.enums[enumName]
	if not items then return nil end
	for name, v in pairs(items) do
		if v == value then return enumItem(enumName, name) end
	end
end
local function isEnumItem(v) return type(v) == "table" and rawget(v, "EnumType") ~= nil end
Enum = setmetatable({}, { __index = function(_, enumName)
	if not API.enums[enumName] then error(tostring(enumName) .. " is not a valid EnumItem", 2) end
	return setmetatable({}, { __index = function(_, item)
		if item == "GetEnumItems" then
			return function()
				local t = {}
				for name in pairs(API.enums[enumName]) do table.insert(t, enumItem(enumName, name)) end
				return t
			end
		end
		local e = enumItem(enumName, item)
		if not e then error(tostring(item) .. " is not a valid member of \"Enum." .. enumName .. "\"", 2) end
		return e
	end })
end })

------------------------------------------------------------------------------- scheduler with contexts
-- Every thread has a context: { kind = "server" } or { kind = "client", player = <Player> }.
NOW = 0
local queue = {}
local CTXOF = setmetatable({}, { __mode = "k" })
local PARENT = setmetatable({}, { __mode = "k" }) -- helper coroutines (pcall/require) -> the real thread
SERVER = { kind = "server" }
CTX = SERVER
local WAITING = setmetatable({}, { __mode = "k" }) -- thread -> what it waits for
local function root(co)
	while PARENT[co] do co = PARENT[co] end
	return co
end
local function current()
	local co = coroutine.running()
	if not co then return nil end
	return root(co)
end
local function schedule(at, co, ...)
	table.insert(queue, { at = at, co = co, args = { ... }, n = select("#", ...), ctx = CTXOF[co] or CTX })
end
local function resume(co, ...)
	local prev = CTX
	CTX = CTXOF[co] or CTX
	WAITING[co] = nil
	local ok, err = coroutine.resume(co, ...)
	CTX = prev
	if not ok then
		local tb = debug.traceback(co)
		table.insert(ERRORS, { msg = tostring(err), tb = tb, ctx = (CTXOF[co] or {}).kind })
		log("ERROR", ((CTXOF[co] or {}).kind or "?") .. ": " .. tostring(err))
	end
	return ok, err
end
function newThread(f, ctx)
	local co = coroutine.create(f)
	CTXOF[co] = ctx or CTX
	return co
end
local function yieldFor(reason)
	local co = current()
	if not co then error("cannot yield here (not in a thread)", 3) end
	WAITING[co] = reason
	return coroutine.yield()
end
function wait(t)
	t = tonumber(t) or 0.03
	local co = current()
	if not co then error("wait() outside a thread", 2) end
	local start = NOW
	schedule(NOW + math.max(t, 0.03), co)
	yieldFor("wait(" .. t .. ")")
	return NOW - start, NOW
end
function spawn(f)
	if type(f) ~= "function" then error("spawn needs a function", 2) end
	local co = newThread(f)
	schedule(NOW + 0.03, co)
end
function delay(t, f)
	if type(f) ~= "function" then error("delay needs a function", 2) end
	local co = newThread(f)
	schedule(NOW + math.max(tonumber(t) or 0, 0.03), co)
end
function tick() return 1700000000 + NOW end
function time() return NOW end
function elapsedTime() return NOW end
-- pcall / xpcall that can yield (Roblox allows waiting inside pcall)
local function packn(...) return { n = select("#", ...), ... } end
local function ypcall(f, ...)
	if type(f) ~= "function" and not (type(f) == "table" and getmetatable(f) and getmetatable(f).__call) then
		return false, "attempt to call a " .. type(f) .. " value"
	end
	local outer = coroutine.running()
	if not outer then return pcall(f, ...) end
	local co = coroutine.create(f)
	PARENT[co] = outer
	local res = packn(coroutine.resume(co, ...))
	while true do
		if not res[1] then return false, res[2] end
		if coroutine.status(co) == "dead" then return true, unpack(res, 2, res.n) end
		local back = packn(coroutine.yield(unpack(res, 2, res.n)))
		res = packn(coroutine.resume(co, unpack(back, 1, back.n)))
	end
end
YPCALL_N = function(f, ...) return packn(ypcall(f, ...)) end
local function yxpcall(f, handler, ...)
	local r = { ypcall(f, ...) }
	if not r[1] then return false, handler(r[2]) end
	return unpack(r, 1, table.maxn(r))
end
function runFor(seconds)
	local stop = NOW + seconds
	while true do
		local best, bi = nil, nil
		for i, q in ipairs(queue) do
			if not best or q.at < best.at then best, bi = q, i end
		end
		if not best or best.at > stop then break end
		table.remove(queue, bi)
		NOW = math.max(NOW, best.at)
		if coroutine.status(best.co) == "suspended" then
			resume(best.co, unpack(best.args, 1, best.n))
		end
		if FRAME then FRAME() end
	end
	NOW = stop
end
function blockedThreads()
	local out = {}
	for co, why in pairs(WAITING) do
		if coroutine.status(co) == "suspended" then
			table.insert(out, { why = why, ctx = (CTXOF[co] or {}).kind, tb = debug.traceback(co) })
		end
	end
	return out
end

------------------------------------------------------------------------------- events (signals)
local Signal = {}
Signal.__index = Signal
local function newSignal(name, owner)
	return setmetatable({ _conns = {}, _name = name, _owner = owner }, Signal)
end
NEWSIGNAL = newSignal
local function connect(self, fn)
	if type(fn) ~= "function" then error("Attempt to connect failed: Passed value is not a function", 2) end
	local c = { fn = fn, ctx = CTX, connected = true }
	table.insert(self._conns, c)
	if self._onConnect then self._onConnect(self) end
	local conn = { connected = true }
	conn.Connected = true
	function conn.disconnect()
		c.connected = false
		conn.connected = false
		conn.Connected = false
	end
	conn.Disconnect = conn.disconnect
	return conn
end
Signal.connect = connect
Signal.Connect = function(self, fn)
	if not OPT.modernSignals then error("Connect is not a valid member of RBXScriptSignal", 2) end
	return connect(self, fn)
end
Signal.connectFirst = connect
function Signal:wait()
	local co = current()
	local res
	local c
	c = connect(self, function(...)
		if c.connected then
			c.disconnect()
			res = { n = select("#", ...), ... }
			schedule(NOW, co)
		end
	end)
	yieldFor("event " .. tostring(self._name) .. (self._owner and (" of " .. self._owner:GetFullName()) or ""))
	return unpack(res or {}, 1, res and res.n or 0)
end
Signal.Wait = function(self)
	if not OPT.modernSignals then error("Wait is not a valid member of RBXScriptSignal", 2) end
	return Signal.wait(self)
end
function Signal:_fire(...)
	local list = {}
	for _, c in ipairs(self._conns) do
		if c.connected then table.insert(list, c) end
	end
	for _, c in ipairs(list) do
		local co = newThread(c.fn, c.ctx)
		resume(co, ...)
	end
	-- drop dead connections
	local keep = {}
	for _, c in ipairs(self._conns) do if c.connected then table.insert(keep, c) end end
	self._conns = keep
end
function Signal:_count()
	local n = 0
	for _, c in ipairs(self._conns) do if c.connected then n = n + 1 end end
	return n
end

------------------------------------------------------------------------------- class info
local CLASS = API.classes
local function classChain(name)
	local t = {}
	while name and CLASS[name] do
		table.insert(t, name)
		name = CLASS[name].super
	end
	return t
end
local memberCache = {}
local function member(className, key)
	local ck = className .. "\0" .. key
	local m = memberCache[ck]
	if m == nil then
		m = false
		for _, cn in ipairs(classChain(className)) do
			local c = CLASS[cn]
			if c.props[key] then m = { kind = "prop", info = c.props[key], owner = cn } break end
			if c.funcs[key] then m = { kind = "func", owner = cn } break end
			if c.events[key] then m = { kind = "event", owner = cn } break end
			if c.callbacks[key] then m = { kind = "callback", owner = cn } break end
		end
		memberCache[ck] = m
	end
	return m or nil
end
function isA(className, other)
	for _, cn in ipairs(classChain(className)) do
		if cn == other then return true end
	end
	return false
end

------------------------------------------------------------------------------- instances
local Inst = {}
METHODS = {} -- name -> function(self, ...)
SIM_MISSING = {}
SIM_METHODS = METHODS
SPECIAL_GET = {} -- [class or "*"][key] -> function(self) value
SPECIAL_SET = {}
local ALL = setmetatable({}, { __mode = "k" })
local function P(o) return rawget(o, "_p") end

local NAMED_DEFAULTS = {
	Visible = true, Archivable = true, Enabled = true, ZIndex = 1, AutoButtonColor = true, Active = false, MaxHealth = 100, Health = 100,
	WalkSpeed = 16, JumpPower = 50, TextTransparency = 0, ImageTransparency = 0, BackgroundTransparency = 0, Transparency = 0, Volume = 0.5,
	ScrollingEnabled = true, ClearTextOnFocus = true, Selectable = true, CanCollide = true, Anchored = false, ResetOnSpawn = true,
	CharacterAutoLoads = true, ScrollBarThickness = 12, Looped = false, Playing = false, FieldOfView = 70, TextSize = 14,
}
local function defaultFor(info, name)
	if name and NAMED_DEFAULTS[name] ~= nil and info.cat == "Primitive" then return NAMED_DEFAULTS[name] end
	if name == "Size" and info.t == "Vector3" then return Vector3.new(4, 1.2, 2) end
	if (name == "BackgroundColor3") then return Color3.new(163 / 255, 162 / 255, 165 / 255) end
	if (name == "TextColor3" or name == "TextStrokeColor3" or name == "BorderColor3") then return Color3.new(0, 0, 0) end
	local t = info.t
	if info.cat == "Primitive" then
		if t == "bool" then return false end
		if t == "string" then return "" end
		if t == "int" or t == "int64" or t == "float" or t == "double" then return 0 end
	elseif info.cat == "Enum" then
		local items = API.enums[t]
		if items then
			local best
			for name, v in pairs(items) do if v == 0 then best = name end end
			if best then return enumItem(t, best) end
			for name in pairs(items) do return enumItem(t, name) end
		end
	elseif info.cat == "DataType" then
		if t == "Vector3" then return Vector3.new() end
		if t == "Vector2" then return Vector2.new() end
		if t == "CFrame" or t == "CoordinateFrame" then return CFrame.new() end
		if t == "Color3" then return Color3.new(1, 1, 1) end
		if t == "UDim2" then return UDim2.new(0, 0, 0, 0) end
		if t == "UDim" then return UDim.new(0, 0) end
		if t == "BrickColor" then return BrickColor.new("Medium stone grey") end
		if t == "Ray" then return Ray.new(Vector3.new(), Vector3.new(0, 0, -1)) end
	end
	return nil
end

local function fullName(o)
	local t = {}
	while o do
		local cls = rawget(o, "_class")
		if cls == "DataModel" then break end
		table.insert(t, 1, P(o).Name)
		o = rawget(o, "_parent")
	end
	return table.concat(t, ".")
end

local function propChanged(o, k)
	local pe = rawget(o, "_propSignals")[k]
	if pe then pe:_fire() end
	local ev = rawget(o, "_events").Changed
	if ev then
		if isA(rawget(o, "_class"), "ValueBase") then
			if k == "Value" then ev:_fire(P(o).Value) end
		else
			ev:_fire(k)
		end
	end
end
PROPCHANGED = propChanged

function makeInstance(className)
	local o = setmetatable({ _class = className, _p = { Name = className }, _children = {}, _parent = nil, _events = {}, _propSignals = {} }, Inst)
	ALL[o] = true
	if NEW_INSTANCE_HOOK then NEW_INSTANCE_HOOK(o) end
	return o
end

local function coerce(o, info, k, v)
	if info.cat == "Enum" then
		if isEnumItem(v) then
			if v.EnumType ~= info.t then error("Invalid value for enum " .. info.t, 3) end
			return v
		end
		local e
		if type(v) == "string" then e = enumItem(info.t, v) elseif type(v) == "number" then e = enumFromValue(info.t, v) end
		if not e then error("bad argument: " .. tostring(v) .. " is not a valid " .. info.t, 3) end
		return e
	end
	if info.cat == "Primitive" then
		if info.t == "bool" then return v and true or false end
		if info.t == "string" then
			if type(v) == "number" then return tostring(v) end
			if type(v) ~= "string" then error("bad argument to " .. k .. " (string expected, got " .. type(v) .. ")", 3) end
		end
		if info.t == "int" or info.t == "float" or info.t == "double" or info.t == "int64" then
			if type(v) == "string" and tonumber(v) then return tonumber(v) end
			if type(v) ~= "number" then error("bad argument to " .. k .. " (number expected, got " .. type(v) .. ")", 3) end
			if info.t == "int" or info.t == "int64" then return math.floor(v) end
		end
	end
	if info.cat == "DataType" and info.t == "UDim2" and getmetatable(v) ~= UDmeta then
		error("bad argument to " .. k .. " (UDim2 expected, got " .. type(v) .. ")", 3)
	end
	if info.cat == "Class" and v ~= nil and not ALL[v] then
		error("bad argument to " .. k .. " (Instance expected)", 3)
	end
	return v
end

local function setParent(o, p)
	local old = rawget(o, "_parent")
	if old == p then return end
	if rawget(o, "_locked") then error("The Parent property of " .. P(o).Name .. " is locked", 3) end
	if p then
		local q = p
		while q do
			if q == o then error("Attempt to set parent of " .. fullName(o) .. " to " .. fullName(p) .. " would result in circular reference", 3) end
			q = rawget(q, "_parent")
		end
	end
	if old then
		local kids = rawget(old, "_children")
		for i, c in ipairs(kids) do
			if c == o then table.remove(kids, i) break end
		end
	end
	rawset(o, "_parent", p)
	if p then table.insert(rawget(p, "_children"), o) end
	-- events
	if old then
		local ev = rawget(old, "_events").ChildRemoved
		if ev then ev:_fire(o) end
	end
	if p then
		local ev = rawget(p, "_events").ChildAdded
		if ev then ev:_fire(o) end
		local a = p
		while a do
			local dv = rawget(a, "_events").DescendantAdded
			if dv then dv:_fire(o) end
			a = rawget(a, "_parent")
		end
	end
	local function ancestry(x)
		local ev = rawget(x, "_events").AncestryChanged
		if ev then ev:_fire(o, p) end
		for _, c in ipairs(rawget(x, "_children")) do ancestry(c) end
	end
	ancestry(o)
	propChanged(o, "Parent")
	if ONPARENT then ONPARENT(o) end
end

Inst.__index = function(o, k)
	local cls = rawget(o, "_class")
	local p = P(o)
	if type(k) ~= "string" then error("invalid key", 2) end
	local sg = SPECIAL_GET[cls] and SPECIAL_GET[cls][k] or SPECIAL_GET["*"][k]
	if sg then return sg(o) end
	if k == "Parent" then return rawget(o, "_parent") end
	if k == "ClassName" then return cls end
	local m = member(cls, k)
	if m then
		if m.kind == "prop" then
			local v = p[k]
			if v == nil and p["\0" .. k] == nil then
				v = defaultFor(m.info, k)
			end
			return v
		elseif m.kind == "func" then
			local f
			for _, cn in ipairs(classChain(cls)) do
				f = METHODS[cn .. "." .. k]
				if f then break end
			end
			f = f or METHODS[k]
			if not f then
				return function()
					SIM_MISSING[m.owner .. "." .. k] = (SIM_MISSING[m.owner .. "." .. k] or 0) + 1
					return nil
				end
			end
			return f
		elseif m.kind == "event" then
			local evs = rawget(o, "_events")
			if not evs[k] then evs[k] = newSignal(k, o) end
			return evs[k]
		elseif m.kind == "callback" then
			return nil -- write-only
		end
	end
	for _, c in ipairs(rawget(o, "_children")) do
		if P(c).Name == k then return c end
	end
	error(k .. " is not a valid member of " .. cls, 2)
end

Inst.__newindex = function(o, k, v)
	local cls = rawget(o, "_class")
	local ss = SPECIAL_SET[cls] and SPECIAL_SET[cls][k] or SPECIAL_SET["*"][k]
	if ss then return ss(o, v) end
	if k == "Parent" then
		if v ~= nil and not ALL[v] then error("bad argument #3 to 'Parent' (Object expected)", 2) end
		if rawget(o, "_destroyed") then error("The Parent property of " .. P(o).Name .. " is locked, current parent: NULL, new parent " .. (v and P(v).Name or "NULL"), 2) end
		return setParent(o, v)
	end
	local m = member(cls, k)
	if not m then error(k .. " is not a valid member of " .. cls, 2) end
	if m.kind == "callback" then
		P(o)[k] = v
		if rawget(o, "_onCallback") then rawget(o, "_onCallback")(o, k, v) end
		return
	end
	if m.kind ~= "prop" then error("can't set value", 2) end
	if m.info.ro then error("can't set value: " .. k .. " is read only", 2) end
	v = coerce(o, m.info, k, v)
	if OPT.traceName and P(o).Name == OPT.traceName and k == OPT.traceProp then
		log("TRACE", fullName(o) .. "." .. k .. " = " .. tostring(v) .. "\n" .. debug.traceback("", 2))
	end
	local p = P(o)
	local old = p[k]
	p[k] = v
	if v == nil then p["\0" .. k] = true end
	if old ~= v then propChanged(o, k) end
end
Inst.__tostring = function(o) return P(o).Name end
Inst.__eq = function(a, b) return rawequal(a, b) end

function isInstance(v) return ALL[v] == true end
function SCHEDULE_NOW(co) schedule(NOW, co) end
function SCHEDULE_AT(at, co) schedule(at, co) end

------------------------------------------------------------------------------- generic Instance methods
SPECIAL_GET["*"] = {}
SPECIAL_SET["*"] = {}
function METHODS.FindFirstChild(self, name, recursive)
	for _, c in ipairs(rawget(self, "_children")) do
		if P(c).Name == name then return c end
	end
	if recursive then
		for _, c in ipairs(rawget(self, "_children")) do
			local f = METHODS.FindFirstChild(c, name, true)
			if f then return f end
		end
	end
	return nil
end
METHODS.findFirstChild = METHODS.FindFirstChild
METHODS.FindFirstChildOfClass = function(self, cn)
	for _, c in ipairs(rawget(self, "_children")) do if rawget(c, "_class") == cn then return c end end
end
METHODS.FindFirstChildWhichIsA = function(self, cn)
	for _, c in ipairs(rawget(self, "_children")) do if isA(rawget(c, "_class"), cn) then return c end end
end
METHODS.FindFirstAncestor = function(self, name)
	local p = rawget(self, "_parent")
	while p do
		if P(p).Name == name then return p end
		p = rawget(p, "_parent")
	end
end
function METHODS.GetChildren(self)
	local t = {}
	for i, c in ipairs(rawget(self, "_children")) do t[i] = c end
	return t
end
METHODS.getChildren = METHODS.GetChildren
METHODS.children = METHODS.GetChildren
function METHODS.GetDescendants(self)
	local t = {}
	local function rec(x)
		for _, c in ipairs(rawget(x, "_children")) do
			table.insert(t, c)
			rec(c)
		end
	end
	rec(self)
	return t
end
function METHODS.WaitForChild(self, name, timeout)
	local c = METHODS.FindFirstChild(self, name)
	if c then return c end
	local start = NOW
	local warned = false
	while true do
		local co = current()
		if not co then error("WaitForChild outside a thread", 2) end
		schedule(NOW + 0.03, co)
		yieldFor("WaitForChild(\"" .. tostring(name) .. "\") on " .. fullName(self))
		c = METHODS.FindFirstChild(self, name)
		if c then return c end
		if timeout and NOW - start >= timeout then return nil end
		if not timeout and not warned and NOW - start > 5 then
			warned = true
			log("WARN", "Infinite yield possible on '" .. fullName(self) .. ":WaitForChild(\"" .. tostring(name) .. "\")'")
		end
	end
end
METHODS.waitForChild = METHODS.WaitForChild
function METHODS.IsA(self, cn) return isA(rawget(self, "_class"), cn) end
METHODS.isA = METHODS.IsA
function METHODS.IsDescendantOf(self, anc)
	local p = rawget(self, "_parent")
	while p do
		if p == anc then return true end
		p = rawget(p, "_parent")
	end
	return false
end
function METHODS.IsAncestorOf(self, d) return METHODS.IsDescendantOf(d, self) end
function METHODS.Destroy(self)
	if rawget(self, "_destroyed") then return end
	setParent(self, nil)
	rawset(self, "_destroyed", true)
	for _, c in ipairs(METHODS.GetChildren(self)) do METHODS.Destroy(c) end
	for _, ev in pairs(rawget(self, "_events")) do ev._conns = {} end
end
METHODS.destroy = METHODS.Destroy
METHODS.Remove = function(self) setParent(self, nil) end
METHODS.remove = METHODS.Remove
function METHODS.ClearAllChildren(self)
	for _, c in ipairs(METHODS.GetChildren(self)) do METHODS.Destroy(c) end
end
local function cloneInst(self)
	if P(self).Archivable == false then return nil end
	local n = makeInstance(rawget(self, "_class"))
	for k, v in pairs(P(self)) do P(n)[k] = v end
	rawset(n, "_scriptSource", rawget(self, "_scriptSource"))
	for _, c in ipairs(rawget(self, "_children")) do
		local cc = cloneInst(c)
		if cc then
			rawset(cc, "_parent", n)
			table.insert(rawget(n, "_children"), cc)
		end
	end
	return n
end
METHODS.Clone = cloneInst
METHODS.clone = cloneInst
METHODS.GetFullName = fullName
function METHODS.GetPropertyChangedSignal(self, prop)
	local m = member(rawget(self, "_class"), prop)
	if not m or m.kind ~= "prop" then error(tostring(prop) .. " is not a valid property name.", 2) end
	local s = rawget(self, "_propSignals")
	if not s[prop] then s[prop] = newSignal(prop .. " changed", self) end
	return s[prop]
end
METHODS.GetAttribute = nil
METHODS.GetDebugId = function(self) return tostring(self) end
METHODS.BreakJoints = function() end
METHODS.MakeJoints = function() end
METHODS.GetMass = function() return 1 end
METHODS.SetPrimaryPartCFrame = function(self, cf) P(self)._cf = cf end
METHODS.GetPrimaryPartCFrame = function(self) return P(self)._cf or CFrame.new() end
METHODS.GetModelCFrame = METHODS.GetPrimaryPartCFrame
METHODS.GetExtentsSize = function() return Vector3.new(4, 4, 4) end

------------------------------------------------------------------------------- GUI helpers
SCREEN = Vector2.new(OPT.screenX or 1366, (OPT.screenY or 768) - 36)
local function absRect(o)
	local cls = rawget(o, "_class")
	if isA(cls, "LayerCollector") or isA(cls, "GuiBase2d") and not isA(cls, "GuiObject") then
		return 0, 0, SCREEN.X, SCREEN.Y
	end
	local parent = rawget(o, "_parent")
	local px, py, pw, ph = 0, 0, SCREEN.X, SCREEN.Y
	if parent and isA(rawget(parent, "_class"), "GuiBase2d") then px, py, pw, ph = absRect(parent) end
	local s = P(o).Size or UDim2.new(0, 0, 0, 0)
	local pos = P(o).Position or UDim2.new(0, 0, 0, 0)
	local w, h = s._a * pw + s._b, s._c * ph + s._d
	local x, y = px + pos._a * pw + pos._b, py + pos._c * ph + pos._d
	local ap = member(cls, "AnchorPoint") and P(o).AnchorPoint
	if ap then x, y = x - ap._x * w, y - ap._y * h end
	return x, y, w, h
end
ABSRECT = absRect
SPECIAL_GET["*"].AbsoluteSize = function(o)
	if not member(rawget(o, "_class"), "AbsoluteSize") then error("AbsoluteSize is not a valid member of " .. rawget(o, "_class"), 2) end
	local x, y, w, h = absRect(o)
	return Vector2.new(w, h)
end
SPECIAL_GET["*"].AbsolutePosition = function(o)
	if not member(rawget(o, "_class"), "AbsolutePosition") then error("AbsolutePosition is not a valid member of " .. rawget(o, "_class"), 2) end
	local x, y = absRect(o)
	return Vector2.new(x, y)
end
SPECIAL_GET["*"].TextBounds = function(o)
	if not member(rawget(o, "_class"), "TextBounds") then error("TextBounds is not a valid member of " .. rawget(o, "_class"), 2) end
	local t = P(o).Text or ""
	return Vector2.new(#t * 8, 18)
end
local function tweenGui(self, props, time, override, callback)
	local t = tonumber(time) or 1
	local id = (rawget(self, "_tweenId") or 0) + 1
	rawset(self, "_tweenId", id)
	delay(t, function()
		if rawget(self, "_tweenId") ~= id then
			if callback then callback(enumItem("TweenStatus", "Canceled")) end
			return
		end
		for k, v in pairs(props) do self[k] = v end
		if callback then callback(enumItem("TweenStatus", "Completed")) end
	end)
	return true
end
local function checkEnumArg(enumName, v)
	if v == nil or isEnumItem(v) then return end
	if type(v) == "string" and not enumItem(enumName, v) then error("bad argument: " .. v .. " is not a valid " .. enumName, 3) end
end
METHODS.TweenPosition = function(self, pos, dir, style, time, override, cb)
	checkEnumArg("EasingDirection", dir) checkEnumArg("EasingStyle", style)
	if getmetatable(pos) ~= UDmeta then error("TweenPosition: UDim2 expected", 2) end
	return tweenGui(self, { Position = pos }, time, override, cb)
end
METHODS.TweenSize = function(self, size, dir, style, time, override, cb)
	checkEnumArg("EasingDirection", dir) checkEnumArg("EasingStyle", style)
	if getmetatable(size) ~= UDmeta then error("TweenSize: UDim2 expected", 2) end
	return tweenGui(self, { Size = size }, time, override, cb)
end
METHODS.TweenSizeAndPosition = function(self, size, pos, dir, style, time, override, cb)
	return tweenGui(self, { Size = size, Position = pos }, time, override, cb)
end
METHODS.CaptureFocus = function() end
METHODS.ReleaseFocus = function() end
METHODS.IsFocused = function() return false end

------------------------------------------------------------------------------- value objects / bindables / remotes
METHODS["BindableEvent.Fire"] = function(self, ...)
	local ev = self.Event
	ev:_fire(...)
end
METHODS["BindableFunction.Invoke"] = function(self, ...)
	local f = P(self).OnInvoke
	while not f do
		wait(0.03)
		f = P(self).OnInvoke
	end
	return f(...)
end
-- RemoteEvent: OnClientEvent exists once per client; messages to a client nobody listens to yet are
-- queued (modern Roblox) or dropped (OPTIONS.dropRemoteQueue)
local function clientEvent(remote, player)
	local t = rawget(remote, "_clientEvents") or {}
	rawset(remote, "_clientEvents", t)
	if not t[player] then
		local s = newSignal("OnClientEvent", remote)
		s._queue = {}
		s._onConnect = function(sig)
			local q = sig._queue
			sig._queue = {}
			for _, args in ipairs(q) do
				local co = newThread(function() sig:_fire(unpack(args, 1, args.n)) end, { kind = "client", player = player })
				schedule(NOW, co)
			end
		end
		t[player] = s
	end
	return t[player]
end
SPECIAL_GET.RemoteEvent = {
	OnClientEvent = function(o)
		if CTX.kind ~= "client" then error("OnClientEvent can only be used on the client", 2) end
		return clientEvent(o, CTX.player)
	end,
	OnServerEvent = function(o)
		local evs = rawget(o, "_events")
		if not evs.OnServerEvent then evs.OnServerEvent = newSignal("OnServerEvent", o) end
		return evs.OnServerEvent
	end,
}
local function copyArgs(...)
	-- remotes copy tables and drop functions
	local n = select("#", ...)
	local out = { n = n }
	local function cp(v, seen)
		if type(v) == "function" then return nil end
		if type(v) ~= "table" or ALL[v] or getmetatable(v) then return v end
		if seen[v] then return seen[v] end
		local t = {}
		seen[v] = t
		for k, x in pairs(v) do t[cp(k, seen)] = cp(x, seen) end
		return t
	end
	for i = 1, n do out[i] = cp((select(i, ...)), {}) end
	return out
end
REMOTE_TRAFFIC = {}
local function sendToClient(remote, player, args)
	table.insert(REMOTE_TRAFFIC, { dir = "S->C", name = P(remote).Name, to = player and P(player).Name, args = args })
	local sig = clientEvent(remote, player)
	local co = newThread(function()
		if sig:_count() == 0 then
			if OPT.dropRemoteQueue then
				log("DROP", "nobody listening on the client for " .. P(remote).Name .. " - message dropped")
			else
				table.insert(sig._queue, args)
			end
			return
		end
		sig:_fire(unpack(args, 1, args.n))
	end, { kind = "client", player = player })
	schedule(NOW + (OPT.latency or 0.05), co)
end
METHODS["RemoteEvent.FireClient"] = function(self, player, ...)
	if CTX.kind ~= "server" then error("FireClient can only be called from the server", 2) end
	if not ALL[player] or rawget(player, "_class") ~= "Player" then error("FireClient: player argument must be a Player object", 2) end
	sendToClient(self, player, copyArgs(...))
end
METHODS["RemoteEvent.FireAllClients"] = function(self, ...)
	if CTX.kind ~= "server" then error("FireAllClients can only be called from the server", 2) end
	local args = copyArgs(...)
	for _, pl in ipairs(PLAYERS_LIST()) do sendToClient(self, pl, args) end
end
METHODS["RemoteEvent.FireServer"] = function(self, ...)
	if CTX.kind ~= "client" then error("FireServer can only be called from the client", 2) end
	local player = CTX.player
	local args = copyArgs(...)
	table.insert(REMOTE_TRAFFIC, { dir = "C->S", name = P(self).Name, from = P(player).Name, args = args })
	local remote = self
	local co = newThread(function()
		SPECIAL_GET.RemoteEvent.OnServerEvent(remote):_fire(player, unpack(args, 1, args.n))
	end, SERVER)
	schedule(NOW + (OPT.latency or 0.05), co)
end
METHODS["RemoteFunction.InvokeServer"] = function(self, ...)
	if CTX.kind ~= "client" then error("InvokeServer can only be called from the client", 2) end
	local player = CTX.player
	local args = copyArgs(...)
	table.insert(REMOTE_TRAFFIC, { dir = "C->S", name = P(self).Name .. "()", from = P(player).Name, args = args })
	local me = current()
	local done, result = false, nil
	local remote = self
	local co = newThread(function()
		local f = P(remote).OnServerInvoke
		while not f do
			wait(0.03)
			f = P(remote).OnServerInvoke
		end
		result = { ypcall(f, player, unpack(args, 1, args.n)) }
		done = true
		schedule(NOW + (OPT.latency or 0.05), me)
	end, SERVER)
	schedule(NOW + (OPT.latency or 0.05), co)
	while not done do yieldFor("InvokeServer " .. P(self).Name) end
	if not result[1] then error(result[2], 2) end
	local back = copyArgs(unpack(result, 2, table.maxn(result)))
	return unpack(back, 1, back.n)
end
METHODS["RemoteFunction.InvokeClient"] = function(self, player, ...)
	error("SIM: InvokeClient not implemented", 2)
end

------------------------------------------------------------------------------- scripts
local REQUIRED = {} -- [ctx kind / player][module] = result
local function envFor(scriptObj, ctx)
	local env = {}
	for k, v in pairs(BASE_ENV) do env[k] = v end
	env.script = scriptObj
	env._G = (ctx.kind == "server") and SERVER_G or CLIENT_G
	env.shared = env._G
	return setmetatable(env, { __index = function(_, k)
		return nil
	end })
end
local function compile(scriptObj)
	local src = rawget(scriptObj, "_scriptSource") or P(scriptObj).Source or ""
	local fn, err = loadstring(src, "=" .. fullName(scriptObj))
	if not fn then error("syntax error in " .. fullName(scriptObj) .. ": " .. tostring(err), 0) end
	return fn
end
function runScript(scriptObj, ctx)
	if rawget(scriptObj, "_ran") then return end
	rawset(scriptObj, "_ran", true)
	log("RUN", (ctx.kind == "client" and "client " or "server ") .. fullName(scriptObj))
	local ok, fn = pcall(compile, scriptObj)
	if not ok then
		table.insert(ERRORS, { msg = fn, tb = "", ctx = ctx.kind })
		log("ERROR", fn)
		return
	end
	setfenv(fn, envFor(scriptObj, ctx))
	local co = newThread(fn, ctx)
	resume(co)
end
function requireModule(mod)
	if not ALL[mod] or rawget(mod, "_class") ~= "ModuleScript" then
		error("Attempted to call require with invalid argument(s).", 2)
	end
	local key = CTX.kind == "server" and "server" or CTX.player
	REQUIRED[key] = REQUIRED[key] or {}
	local cache = REQUIRED[key]
	local entry = cache[mod]
	if entry then
		while entry.loading do
			wait(0.03)
		end
		if entry.failed then error("Requested module experienced an error while loading", 2) end
		return entry.value
	end
	entry = { loading = true }
	cache[mod] = entry
	local fn = compile(mod)
	setfenv(fn, envFor(mod, CTX))
	local res = YPCALL_N(fn)
	entry.loading = false
	if not res[1] then
		entry.failed = true
		log("ERROR", "module " .. fullName(mod) .. ": " .. tostring(res[2]))
		table.insert(ERRORS, { msg = "module " .. fullName(mod) .. ": " .. tostring(res[2]), tb = "", ctx = CTX.kind })
		error("Requested module experienced an error while loading", 2)
	end
	if res.n ~= 2 then
		entry.failed = true
		error("Module code did not return exactly one value", 2)
	end
	entry.value = res[2]
	return res[2]
end

------------------------------------------------------------------------------- the base environment
local function protectedLib(lib, removed)
	local t = {}
	for k, v in pairs(lib) do t[k] = v end
	for _, k in ipairs(removed or {}) do t[k] = nil end
	return t
end
BASE_ENV = {
	print = function(...)
		local t = {}
		for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
		log("print", (CTX.kind == "client" and "[C] " or "[S] ") .. table.concat(t, " "))
	end,
	warn = function(...)
		local t = {}
		for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
		log("warn", (CTX.kind == "client" and "[C] " or "[S] ") .. table.concat(t, " "))
	end,
	wait = wait, Wait = wait, spawn = spawn, Spawn = spawn, delay = delay, Delay = delay,
	tick = tick, time = time, elapsedTime = elapsedTime, ElapsedTime = elapsedTime,
	require = function(m) return requireModule(m) end,
	pcall = ypcall, ypcall = ypcall, xpcall = yxpcall,
	select = select, type = type, tostring = tostring, tonumber = tonumber, pairs = pairs, ipairs = ipairs, next = next,
	unpack = unpack, setmetatable = setmetatable, getmetatable = getmetatable, rawget = rawget, rawset = rawset, rawequal = rawequal,
	error = error, assert = assert, newproxy = newproxy, gcinfo = gcinfo, collectgarbage = function() return 0 end,
	coroutine = coroutine, string = string, table = table,
	math = protectedLib(math, OPT.mathClamp and {} or { "clamp" }),
	os = { time = os.time, clock = function() return NOW end, difftime = os.difftime, date = os.date },
	debug = { traceback = debug.traceback },
	Vector3 = Vector3, Vector2 = Vector2, CFrame = CFrame, Color3 = Color3, BrickColor = BrickColor, UDim2 = UDim2, UDim = UDim,
	Ray = Ray, NumberRange = NumberRange, NumberSequence = NumberSequence, ColorSequence = ColorSequence, Enum = Enum,
	TweenInfo = TweenInfo,
	Instance = { new = function(cn, parent)
		local c = CLASS[cn]
		if not c or c.notCreatable or c.service then error("Unable to create an Instance of type \"" .. tostring(cn) .. "\"", 2) end
		local o = makeInstance(cn)
		if INIT_INSTANCE then INIT_INSTANCE(o) end
		if parent then o.Parent = parent end
		return o
	end },
	loadstring = nil,
}
if OPT.typeof then
	BASE_ENV.typeof = function(v)
		if ALL[v] then return "Instance" end
		if type(v) == "table" then
			local mt = getmetatable(v)
			if mt == UDmeta then return "UDim2" end
			if mt == C3meta then return "Color3" end
			if mt == V2meta then return "Vector2" end
			if isEnumItem(v) then return "EnumItem" end
		end
		return type(v)
	end
end
SERVER_G = {}
CLIENT_G = {}
