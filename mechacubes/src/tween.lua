-- tween(instance, goal, property, time, style, direction, callback)
-- tween(startValue, endValue, function, time, style, direction)
-- [fix] Uses TweenService when the engine has it (2017+); otherwise animates the value itself,
-- so it also works on 2016 engines.

local ok, TweenService = pcall(function() return game:GetService("TweenService") end)
local hasTweenService = ok and TweenService and pcall(function()
	return TweenInfo.new(1) and TweenService.Create
end)
local RunService = game:GetService("RunService")
-- [fix] objects that had an AnchorPoint keep growing / moving around it (see compat2016)
local compat = require(game:GetService("ReplicatedStorage"):WaitForChild("compat2016"))

local nativeTypeof = (function() local ok, f = pcall(function() return typeof end) return ok and type(f) == "function" and f end)()
local function typeOf(v)
	if nativeTypeof then return nativeTypeof(v) end
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

local function lerp(a, b, t)
	local kind = typeOf(a)
	if kind == "number" then return a + (b - a) * t end
	if kind == "Color3" then return Color3.new(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t) end
	if kind == "UDim2" then
		return UDim2.new(a.X.Scale + (b.X.Scale - a.X.Scale) * t, a.X.Offset + (b.X.Offset - a.X.Offset) * t,
			a.Y.Scale + (b.Y.Scale - a.Y.Scale) * t, a.Y.Offset + (b.Y.Offset - a.Y.Offset) * t)
	end
	if kind == "Vector3" or kind == "CFrame" then return a:lerp(b, t) end
	return t < 1 and a or b
end

local function ease(t, style, direction)
	local name = style and (type(style) == "string" and style or style.Name) or "Linear"
	local dir = direction and (type(direction) == "string" and direction or direction.Name) or "In"
	local function f(x)
		if name == "Quad" then return x * x end
		if name == "Cubic" then return x * x * x end
		if name == "Quart" then return x * x * x * x end
		if name == "Quint" then return x * x * x * x * x end
		if name == "Sine" then return 1 - math.cos(x * math.pi / 2) end
		return x
	end
	if dir == "In" then return f(t) end
	if dir == "Out" then return 1 - f(1 - t) end
	if t < 0.5 then return f(t * 2) / 2 end
	return 1 - f((1 - t) * 2) / 2
end

-- one running animation per (object, property); a new one replaces the old one
local running = setmetatable({}, {__mode = "k"})

local function animate(key, from, to, apply, time, style, direction, callback)
	running[key] = running[key] or {}
	local id = {}
	running[key].id = id
	spawn(function()
		local start = tick()
		time = math.max(time or 0, 0)
		while time > 0 do
			local t = (tick() - start) / time
			if t >= 1 or running[key].id ~= id then break end
			apply(lerp(from, to, ease(t, style, direction)))
			RunService.RenderStepped:wait()
		end
		if running[key].id == id then
			apply(to)
			if callback then callback() end
		end
	end)
end

local keys = setmetatable({}, {__mode = "k"})

return function(variant1, goal, variant2, time, style, direction, callback)
	if (variant2 == "Size" or variant2 == "Position") and typeOf(variant1) == "Instance" then
		local ax, ay = compat.anchorOf(variant1)
		if ax ~= 0 or ay ~= 0 then
			local obj = variant1
			keys[obj] = keys[obj] or {}
			keys[obj][variant2] = keys[obj][variant2] or {}
			if variant2 == "Size" then
				animate(keys[obj][variant2], obj.Size, goal, function(v) compat.setSize(obj, v) end, time, style, direction, callback)
			else
				animate(keys[obj][variant2], compat.getPos(obj), goal, function(v) compat.setPos(obj, v) end, time, style, direction, callback)
			end
			return
		end
	end
	if hasTweenService then
		local tweenInfo = TweenInfo.new(time, style or Enum.EasingStyle.Linear, direction or Enum.EasingDirection.In)
		if (typeOf(variant1) == "Instance") then
			local property = {}
			property[variant2] = goal
			local tween = TweenService:Create(variant1, tweenInfo, property)
			if (callback) then
				tween.Completed:connect(function(playbackState)
					if (playbackState == Enum.PlaybackState.Completed) then
						callback()
					end
				end)
			end
			tween:Play()
			return
		end
	end

	if (typeOf(variant1) == "Instance") then
		local obj, prop = variant1, variant2
		keys[obj] = keys[obj] or {}
		keys[obj][prop] = keys[obj][prop] or {}
		animate(keys[obj][prop], obj[prop], goal, function(v) obj[prop] = v end, time, style, direction, callback)
	else
		-- tween(startValue, endValue, function, ...): calls the function with each value
		local fn = variant2
		keys[fn] = keys[fn] or {}
		animate(keys[fn], variant1, goal, fn, time, style, direction, callback)
	end
end
