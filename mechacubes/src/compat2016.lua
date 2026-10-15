-- compat2016: lets MechaCubes (made for 2017-2018 Roblox) run on 2016 engines.
-- Every script gets these through one line at its top:
--   local __compat = require(game:GetService("ReplicatedStorage"):WaitForChild("compat2016")); local Color3, typeof, math = ...
-- On newer engines everything just uses the real Roblox function.

local C = {}

local function has(f)
	local ok, v = pcall(f)
	return ok and v ~= nil, v
end

---------------------------------------------------------------- Color3.fromRGB / fromHSV
local realColor3 = Color3
local hasRGB, nativeRGB = has(function() return realColor3.fromRGB end)
local hasHSV, nativeHSV = has(function() return realColor3.fromHSV end)
local color3 = {}
color3.new = realColor3.new
color3.fromRGB = hasRGB and nativeRGB or function(r, g, b)
	return realColor3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
end
color3.fromHSV = hasHSV and nativeHSV or function(h, s, v)
	h = (h or 0) % 1
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then return realColor3.new(v, t, p)
	elseif i == 1 then return realColor3.new(q, v, p)
	elseif i == 2 then return realColor3.new(p, v, t)
	elseif i == 3 then return realColor3.new(p, q, v)
	elseif i == 4 then return realColor3.new(t, p, v) end
	return realColor3.new(v, p, q)
end
C.Color3 = setmetatable(color3, {__index = function(_, k) return realColor3[k] end})

---------------------------------------------------------------- typeof
local hasTypeof = (function()
	local ok, f = pcall(function() return typeof end)
	return ok and type(f) == "function" and f
end)()
C.typeof = hasTypeof or function(v)
	local t = type(v)
	if t ~= "userdata" and t ~= "table" then return t end
	if t == "table" and rawget(v, "_class") == nil then
		-- a plain Lua table (in the test engine Roblox objects are tables marked with _class)
		if getmetatable(v) == nil then return "table" end
	end
	local ok, cn = pcall(function() return v.ClassName end)
	if ok and type(cn) == "string" then return "Instance" end
	if pcall(function() return v.lookVector end) then return "CFrame" end
	if pcall(function() return v.Z end) then return "Vector3" end
	if pcall(function() return v.r, v.g, v.b end) then return "Color3" end
	if pcall(function() return v.X.Scale end) then return "UDim2" end
	if pcall(function() return v.X, v.Y end) then return "Vector2" end
	return t
end

---------------------------------------------------------------- math.clamp
local mathLib = {}
for k, v in pairs(math) do mathLib[k] = v end
mathLib.clamp = math.clamp or function(x, lo, hi)
	if x < lo then return lo end
	if x > hi then return hi end
	return x
end
C.math = mathLib

---------------------------------------------------------------- GetPropertyChangedSignal
-- (2017) On older engines: the Changed event, filtered to one property.
local proxies = setmetatable({}, {__mode = "k"})
function C.changed(obj, prop)
	if proxies[obj] then
		return proxies[obj]:signal(prop)
	end
	local ok, sig = pcall(function() return obj:GetPropertyChangedSignal(prop) end)
	if ok and sig then return sig end
	return {
		connect = function(_, fn)
			return obj.Changed:connect(function(p)
				if p == prop then fn() end
			end)
		end,
	}
end

---------------------------------------------------------------- FindFirstChildOfClass / ray whitelist / BindToClose
function C.findClass(obj, className)
	local ok, r = pcall(function() return obj:FindFirstChildOfClass(className) end)
	if not ok then
		r = nil
		for _, c in pairs(obj:GetChildren()) do
			if c.ClassName == className then r = c break end
		end
	end
	if not r and (className == "UIListLayout" or className == "UIGridLayout") then
		r = C.layoutOf(obj)
	end
	return r
end
-- container.someLayout (a UIListLayout / UIGridLayout child by name), real or emulated
function C.layoutChild(container, name)
	local real = container:FindFirstChild(name)
	if real then return real end
	return C.layoutOf(container, name)
end
function C.rayWhitelist(ray, list)
	local ok, hit, pos = pcall(function() return workspace:FindPartOnRayWithWhitelist(ray, list) end)
	if ok then return hit, pos end
	-- old engines: walk along the ray, ignoring anything not in the list
	local ignore = {}
	for _ = 1, 8 do
		local h, p = workspace:FindPartOnRayWithIgnoreList(ray, ignore)
		if not h then return nil, p end
		for _, w in pairs(list) do
			if h == w or h:IsDescendantOf(w) then return h, p end
		end
		table.insert(ignore, h)
	end
	return nil, ray.Origin + ray.Direction
end
function C.bindToClose(fn)
	pcall(function() game:BindToClose(fn) end)
end

---------------------------------------------------------------- AnchorPoint (Dec 2016)
-- The place file has no AnchorPoints any more (positions were converted so every engine shows the
-- same thing). Objects that had one point their SelectionImageObject at a marker in
-- ReplicatedStorage.compat2016.anchors; these helpers keep script moves working like before.
local anchorFolder = script:WaitForChild("anchors")
local anchorCache = setmetatable({}, {__mode = "k"})
local function anchorOf(obj)
	local ok, m = pcall(function() return obj.SelectionImageObject end)
	if not ok or not m then return 0, 0 end
	local a = anchorCache[m]
	if not a then
		if m.Parent ~= anchorFolder then return 0, 0 end
		a = {m.Position.X.Scale, m.Position.Y.Scale}
		anchorCache[m] = a
	end
	return a[1], a[2]
end
C.anchorOf = anchorOf
local function isUDim2(v)
	return (type(v) == "userdata" or type(v) == "table") and pcall(function() return v.X.Scale end)
end
local function shift(p, s, ax, ay, sign)
	return UDim2.new(p.X.Scale + sign * ax * s.X.Scale, p.X.Offset + sign * ax * s.X.Offset,
		p.Y.Scale + sign * ay * s.Y.Scale, p.Y.Offset + sign * ay * s.Y.Offset)
end
function C.getPos(obj)
	local p = obj.Position
	local ax, ay = anchorOf(obj)
	if (ax ~= 0 or ay ~= 0) and isUDim2(p) then return shift(p, obj.Size, ax, ay, 1) end
	return p
end
function C.setPos(obj, p)
	local ax, ay = anchorOf(obj)
	if (ax ~= 0 or ay ~= 0) and isUDim2(p) then
		obj.Position = shift(p, obj.Size, ax, ay, -1)
	else
		obj.Position = p
	end
end
function C.setSize(obj, s)
	local ax, ay = anchorOf(obj)
	if (ax ~= 0 or ay ~= 0) and isUDim2(s) then
		local logical = C.getPos(obj)
		obj.Size = s
		obj.Position = shift(logical, s, ax, ay, -1)
	else
		obj.Size = s
	end
end
function C.tweenPos(obj, p, ...)
	local ax, ay = anchorOf(obj)
	if (ax ~= 0 or ay ~= 0) and isUDim2(p) then p = shift(p, obj.Size, ax, ay, -1) end
	return obj:TweenPosition(p, ...)
end
function C.tweenSize(obj, s, dir, style, time, override, cb)
	local ax, ay = anchorOf(obj)
	if (ax ~= 0 or ay ~= 0) and isUDim2(s) then
		local logical = C.getPos(obj)
		return obj:TweenSizeAndPosition(s, shift(logical, s, ax, ay, -1), dir, style, time, override, cb)
	end
	return obj:TweenSize(s, dir, style, time, override, cb)
end

---------------------------------------------------------------- ZIndex (1..10 before 2017)
-- The place file has every ZIndex squeezed into 1..10 (see tools/zlevels.py), the original number is in
-- the object's marker. Scripts read and write the original numbers through these.
local zTables = {}
pcall(function() zTables = require(script:WaitForChild("zlevels")) end)
local function panelOf(obj)
	local o = obj
	while o.Parent and o.Parent.ClassName ~= "ScreenGui" and o.Parent ~= game do
		o = o.Parent
	end
	return o.Name
end
local function levelFor(panel, z)
	local t = zTables[panel]
	if not t or #t == 0 then return math.max(1, math.min(10, z)) end
	local lv = t[1][2]
	for _, e in ipairs(t) do
		if e[1] <= z then lv = e[2] else break end
	end
	return lv
end
local function markerFor(ax, ay, z)
	local name = string.format("anchor %g %g z%d", ax, ay, z)
	local m = anchorFolder:FindFirstChild(name)
	if not m then
		m = Instance.new("ImageLabel")
		m.Name = name
		m.Visible = false
		m.BackgroundTransparency = 1
		m.ImageTransparency = 1
		m.Position = UDim2.new(ax, 0, ay, 0)
		m.Size = UDim2.new(0, z, 0, 0)
		m.Parent = anchorFolder
	end
	return m
end
function C.getZ(obj)
	local ok, m = pcall(function() return obj.SelectionImageObject end)
	if ok and m and m.Parent == anchorFolder then return m.Size.X.Offset end
	return obj.ZIndex
end
function C.setZ(obj, z)
	z = math.floor(tonumber(z) or 1)
	local ok = pcall(function() return obj.SelectionImageObject end)
	if not ok then
		obj.ZIndex = z
		return
	end
	local ax, ay = anchorOf(obj)
	obj.ZIndex = levelFor(panelOf(obj), z)
	obj.SelectionImageObject = markerFor(ax, ay, z)
end

---------------------------------------------------------------- UIListLayout / UIGridLayout (2017)
-- On engines without them, the containers listed in "layouts" (made from the place file) are
-- arranged by this code instead. Containers made from templates are matched by name pattern.
local hasLayouts = pcall(function() Instance.new("UIListLayout"):Destroy() end)
C.hasLayouts = hasLayouts
local layoutDefs = {}
do
	local ok, defs = pcall(function() return require(script:WaitForChild("layouts")) end)
	if ok and type(defs) == "table" then layoutDefs = defs end
end
local emulated = setmetatable({}, {__mode = "k"}) -- container -> proxy

local Proxy = {}
Proxy.__index = Proxy
function Proxy:signal(prop)
	self._signals[prop] = self._signals[prop] or Instance.new("BindableEvent")
	return self._signals[prop].Event
end
function Proxy:fire(prop)
	if self._signals[prop] then self._signals[prop]:Fire() end
end
function Proxy:GetPropertyChangedSignal(prop) return self:signal(prop) end
function Proxy:ApplyLayout() C.relayout(self.Container) end

local function pathOf(obj, root)
	local t = {}
	while obj and obj ~= root do
		table.insert(t, 1, obj.Name)
		obj = obj.Parent
	end
	if obj ~= root then return nil end
	return t
end
local function matches(def, segs)
	if #def.path ~= #segs then return false end
	for i, s in ipairs(def.path) do
		if s ~= segs[i] and not s:find("emplate") then return false end
	end
	return true
end
local function newProxy(container, def)
	local p = setmetatable({_signals = {}, Container = container, Name = def.name, ClassName = def.class}, Proxy)
	for k, v in pairs(def.props) do p[k] = v end
	p.AbsoluteContentSize = Vector2.new(0, 0)
	return p
end
function C.layoutOf(container, layoutName)
	if hasLayouts then return nil end
	if emulated[container] then return emulated[container] end
	local root = container
	while root.Parent and not root.Parent:IsA("PlayerGui") do root = root.Parent end
	local segs = pathOf(container, root)
	for _, def in ipairs(layoutDefs) do
		local ok
		if segs and root.Parent then
			ok = matches(def, segs)
		else
			-- not in a PlayerGui yet (a fresh clone): match by its own name and the layout's name
			local last = def.path[#def.path]
			ok = (layoutName == nil or def.name == layoutName) and (last == container.Name or last:find("emplate") ~= nil)
		end
		if ok then
			local p = newProxy(container, def)
			emulated[container] = p
			proxies[p] = p
			return p
		end
	end
	return nil
end
-- TextSize (Oct 2016): older engines only have the FontSize steps
local fontSizes = {{8, "Size8"}, {9, "Size9"}, {10, "Size10"}, {11, "Size11"}, {12, "Size12"}, {14, "Size14"}, {18, "Size18"},
	{24, "Size24"}, {28, "Size28"}, {32, "Size32"}, {36, "Size36"}, {42, "Size42"}, {48, "Size48"}, {60, "Size60"}, {96, "Size96"}}
function C.setTextSize(obj, size)
	if pcall(function() obj.TextSize = size end) then return end
	local best = fontSizes[1]
	for _, fs in ipairs(fontSizes) do
		if fs[1] <= size then best = fs end
	end
	pcall(function() obj.FontSize = Enum.FontSize[best[2]] end)
end

-- LayoutOrder (2017): kept here on engines that don't have it
local layoutOrders = setmetatable({}, {__mode = "k"})
function C.setLayoutOrder(obj, v)
	if not pcall(function() obj.LayoutOrder = v end) then layoutOrders[obj] = v end
end
function C.getLayoutOrder(obj)
	local ok, v = pcall(function() return obj.LayoutOrder end)
	if ok then return v end
	return layoutOrders[obj] or 0
end
local function udimPx(u, size) return (u and (u.Scale * size + u.Offset)) or 0 end
local function sortedChildren(container, proxy)
	local list = {}
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("GuiObject") and c.Visible then table.insert(list, c) end
	end
	local index = {}
	for i, c in ipairs(list) do index[c] = i end
	if proxy.SortOrder == "Name" then
		table.sort(list, function(a, b) return a.Name < b.Name end)
	elseif proxy.SortOrder == "LayoutOrder" then
		table.sort(list, function(a, b)
			local la, lb = C.getLayoutOrder(a), C.getLayoutOrder(b)
			if la ~= lb then return la < lb end
			return index[a] < index[b]
		end)
	end
	return list
end
function C.relayout(container)
	local proxy = emulated[container]
	if not proxy then return end
	local W, H = container.AbsoluteSize.X, container.AbsoluteSize.Y
	local list = sortedChildren(container, proxy)
	local contentX, contentY = 0, 0
	if proxy.ClassName == "UIGridLayout" then
		local cs, cp = proxy.CellSize, proxy.CellPadding
		local cw, ch = cs.X.Scale * W + cs.X.Offset, cs.Y.Scale * H + cs.Y.Offset
		local pw, ph = cp.X.Scale * W + cp.X.Offset, cp.Y.Scale * H + cp.Y.Offset
		local cols = math.max(1, math.floor((W + pw) / math.max(1, cw + pw)))
		if proxy.FillDirectionMaxCells and proxy.FillDirectionMaxCells > 0 then cols = math.min(cols, proxy.FillDirectionMaxCells) end
		local rows = math.ceil(#list / cols)
		local totalW = math.min(#list, cols) * cw + (math.min(#list, cols) - 1) * pw
		local x0 = 0
		if proxy.HorizontalAlignment == "Center" then x0 = (W - totalW) / 2 elseif proxy.HorizontalAlignment == "Right" then x0 = W - totalW end
		for i, c in ipairs(list) do
			local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
			c.Size = UDim2.new(0, cw, 0, ch)
			c.Position = UDim2.new(0, x0 + col * (cw + pw), 0, row * (ch + ph))
		end
		contentX, contentY = totalW, rows * ch + math.max(0, rows - 1) * ph
	else
		local vertical = proxy.FillDirection ~= "Horizontal"
		local pad = udimPx(proxy.Padding, vertical and H or W)
		local total = 0
		for i, c in ipairs(list) do
			total = total + (vertical and c.AbsoluteSize.Y or c.AbsoluteSize.X) + (i > 1 and pad or 0)
		end
		local start = 0
		if vertical then
			if proxy.VerticalAlignment == "Center" then start = (H - total) / 2 elseif proxy.VerticalAlignment == "Bottom" then start = H - total end
		else
			if proxy.HorizontalAlignment == "Center" then start = (W - total) / 2 elseif proxy.HorizontalAlignment == "Right" then start = W - total end
		end
		local at = start
		for _, c in ipairs(list) do
			local w, h = c.AbsoluteSize.X, c.AbsoluteSize.Y
			if vertical then
				local x = 0
				if proxy.HorizontalAlignment == "Center" then x = (W - w) / 2 elseif proxy.HorizontalAlignment == "Right" then x = W - w end
				c.Position = UDim2.new(0, x, 0, at)
				at = at + h + pad
			else
				local y = 0
				if proxy.VerticalAlignment == "Center" then y = (H - h) / 2 elseif proxy.VerticalAlignment == "Bottom" then y = H - h end
				c.Position = UDim2.new(0, at, 0, y)
				at = at + w + pad
			end
		end
		if vertical then contentX, contentY = W, total else contentX, contentY = total, H end
	end
	local old = proxy.AbsoluteContentSize
	proxy.AbsoluteContentSize = Vector2.new(contentX, contentY)
	if not old or old.X ~= contentX or old.Y ~= contentY then proxy:fire("AbsoluteContentSize") end
end
-- watch a ScreenGui: find every container that needs an emulated layout and keep it arranged
function C.watchLayouts(gui)
	if hasLayouts then return end
	local function scan(obj)
		if obj:IsA("GuiObject") then C.layoutOf(obj) end
		for _, c in ipairs(obj:GetChildren()) do scan(c) end
	end
	scan(gui)
	gui.DescendantAdded:connect(function(d)
		if d:IsA("GuiObject") then
			scan(d)
		end
	end)
	spawn(function()
		while gui.Parent do
			for container in pairs(emulated) do
				if container.Parent then pcall(C.relayout, container) end
			end
			wait(0.1)
		end
	end)
end

return C
