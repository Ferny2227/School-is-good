-- ServerScriptService.Backyard
-- Every tycoon gets a backyard behind the mansion with 100 more things to buy. Walk on a pad to buy it
-- (owner only, like the tycoon buttons). Every item adds money per second to "Cash to collect", and lots of
-- them do something: seats, swings, bounce, speed and jump pads, tool stands, spinning rides, lights.
-- Rows of 10 open up as you buy: buy 5 things in a row to open the next one.
-- Written for 2016 Roblox engines (lowercase :connect, no TweenService/typeof, FormFactor Custom).
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local CELL = 18          -- each item gets an 18x18 stud square
local COLS = 10
local ROWS = 10
local UNLOCK = 5         -- items bought in a row to open the next row

------------------------------------------------------------------ small building kit
local function cf(x, y, z, ry, rx, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

local B = {}   -- builder state: B.model, B.o (cell CFrame), B.spin (list)

local function part(name, size, at, color, mat, opt)
	opt = opt or {}
	local p = Instance.new(opt.class or "Part")
	pcall(function() p.FormFactor = Enum.FormFactor.Custom end)
	p.Name = name
	p.Anchored = true
	if opt.shape == "ball" then p.Shape = Enum.PartType.Ball
	elseif opt.shape == "cyl" then p.Shape = Enum.PartType.Cylinder end
	p.Size = size
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.BrickColor = BrickColor.new(color or "Medium stone grey")
	if mat then pcall(function() p.Material = Enum.Material[mat] end) end
	if opt.tr then p.Transparency = opt.tr end
	if opt.refl then p.Reflectance = opt.refl end
	if opt.nocollide then p.CanCollide = false end
	p.CFrame = B.o * at
	p.Parent = B.model
	return p
end
-- vertical cylinder (Roblox cylinders lie along x)
local function vcyl(name, d, h, x, y, z, color, mat, opt)
	opt = opt or {}
	opt.shape = "cyl"
	return part(name, Vector3.new(h, d, d), cf(x, y, z) * CFrame.Angles(0, 0, math.rad(90)), color, mat, opt)
end
local function ball(name, d, x, y, z, color, mat, opt)
	opt = opt or {}
	opt.shape = "ball"
	return part(name, Vector3.new(d, d, d), cf(x, y, z), color, mat, opt)
end
local function seat(x, y, z, ry, color, w)
	return part("Seat", Vector3.new(w or 2, 1, 2), cf(x, y, z, ry), color or "Reddish brown", "Wood", { class = "Seat" })
end
local function light(p, color, range)
	local l = Instance.new("PointLight")
	l.Color = color or Color3.new(1, 0.9, 0.7)
	l.Range = range or 16
	l.Brightness = 2
	l.Parent = p
	return l
end
local function fx(p, kind)
	local e = Instance.new(kind)
	e.Parent = p
	return e
end
local function spin(parts, center, axis, speed)
	local rel = {}
	for i, p in ipairs(parts) do rel[i] = center:inverse() * p.CFrame end
	table.insert(B.spin, { parts = parts, rel = rel, center = center, axis = axis, speed = speed })
end
local function label(p, text)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(8, 0, 1.5, 0)
	bb.StudsOffset = Vector3.new(0, p.Size.Y / 2 + 1.5, 0)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Text = text
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	t.Parent = bb
	bb.Parent = p
end

------------------------------------------------------------------ things items can do
local function humanoidOf(hit)
	return hit and hit.Parent and hit.Parent:FindFirstChild("Humanoid")
end
local function torsoOf(hum)
	return hum.Parent:FindFirstChild("Torso") or hum.Parent:FindFirstChild("HumanoidRootPart")
end
local function bounce(p, power)
	local busy = {}
	p.Touched:connect(function(hit)
		local hum = humanoidOf(hit)
		if not hum or busy[hum] then return end
		local t = torsoOf(hum)
		if not t then return end
		busy[hum] = true
		local bv = Instance.new("BodyVelocity")
		bv.maxForce = Vector3.new(0, 1e6, 0)
		bv.velocity = Vector3.new(0, power, 0)
		bv.Parent = t
		game:GetService("Debris"):AddItem(bv, 0.25)
		wait(0.6)
		busy[hum] = nil
	end)
end
local function speedPad(p, speed, seconds)
	p.Touched:connect(function(hit)
		local hum = humanoidOf(hit)
		if not hum or hum.WalkSpeed >= speed then return end
		hum.WalkSpeed = speed
		delay(seconds, function() if hum and hum.Parent then hum.WalkSpeed = 16 end end)
	end)
end
local function findTool(name)
	for _, folder in ipairs(Lighting:GetChildren()) do
		local t = folder:FindFirstChild(name)
		if t and t:IsA("Tool") then return t end
	end
	local t = Lighting:FindFirstChild(name)
	if t and t:IsA("Tool") then return t end
	return nil
end
local function toolGiver(p, toolName)
	p.Touched:connect(function(hit)
		local hum = humanoidOf(hit)
		local player = hum and Players:GetPlayerFromCharacter(hum.Parent)
		if not player then return end
		local bp = player:FindFirstChild("Backpack")
		if not bp or bp:FindFirstChild(toolName) or hum.Parent:FindFirstChild(toolName) then return end
		local tool = findTool(toolName)
		if tool then tool:Clone().Parent = bp end
	end)
end
local TELEPORT = {}   -- filled per tycoon: where "back to the mansion" goes
local function teleportPad(p, where)
	local busy = {}
	p.Touched:connect(function(hit)
		local hum = humanoidOf(hit)
		local t = hum and torsoOf(hum)
		if not t or busy[hum] then return end
		busy[hum] = true
		t.CFrame = where() + Vector3.new(0, 4, 0)
		wait(1)
		busy[hum] = nil
	end)
end

------------------------------------------------------------------ the builders (cell centre = 0,0,0 on the grass)
local K = {}
K.mailbox = function(o)
	part("Post", Vector3.new(0.6, 4, 0.6), cf(0, 2, 0), "Reddish brown", "Wood")
	part("Box", Vector3.new(1.6, 1.4, 2.6), cf(0, 4.5, 0), o.color or "Bright blue", "Metal")
	part("Flag", Vector3.new(0.2, 1, 0.4), cf(0.9, 5, 0.6), "Bright red")
end
K.gnome = function(o)
	local c = o.color or "Bright blue"
	part("Body", Vector3.new(1.6, 2, 1.6), cf(0, 1, 0), c, o.mat)
	ball("Head", 1.4, 0, 2.6, 0, o.skin or "Nougat", o.mat)
	ball("Beard", 1.2, 0, 2.1, -0.5, "Institutional white", o.mat)
	part("Hat", Vector3.new(1.4, 1.6, 1.4), cf(0, 3.8, 0), o.hat or "Bright red", o.mat)
	ball("HatTip", 0.8, 0, 4.7, 0, o.hat or "Bright red", o.mat)
	if o.mat == "Neon" or o.gold then light(B.model:FindFirstChild("Head"), Color3.new(1, 0.8, 0.2), 10) end
end
K.flowers = function(o)
	part("Soil", Vector3.new(10, 1, 6), cf(0, 0.5, 0), "Reddish brown", "Grass")
	for i = -2, 2 do
		for j = -1, 1 do
			part("Stem", Vector3.new(0.3, 1.4, 0.3), cf(i * 2, 1.7, j * 1.8), "Dark green")
			ball("Flower", 1, i * 2, 2.6, j * 1.8, (i + j) % 2 == 0 and o.color or (o.color2 or "Bright yellow"))
		end
	end
end
K.birdbath = function(o)
	vcyl("Base", 2, 3, 0, 1.5, 0, "Light stone grey", "Marble")
	vcyl("Bowl", 5, 1, 0, 3.5, 0, "Light stone grey", "Marble")
	vcyl("Water", 4.2, 0.2, 0, 4.05, 0, "Cyan", nil, { tr = 0.3, nocollide = true })
	ball("Bird", 0.8, 1.6, 4.4, 0, "Bright yellow")
end
K.bench = function(o)
	local c = o.color or "Reddish brown"
	seat(-1.5, 2, 0, 0, c, 3) seat(1.5, 2, 0, 0, c, 3)
	part("Back", Vector3.new(6, 2, 0.4), cf(0, 3.2, 1.1), c, o.mat or "Wood")
	for _, x in ipairs({ -2.6, 2.6 }) do part("Leg", Vector3.new(0.4, 1.5, 2), cf(x, 0.75, 0), "Dark stone grey", "Metal") end
	if o.gold then for _, p in ipairs(B.model:GetChildren()) do p.Reflectance = 0.3 end end
end
K.lamp = function(o)
	vcyl("Pole", 0.6, 9, 0, 4.5, 0, "Really black", "Metal")
	local top = ball("Light", 1.6, 0, 9.4, 0, o.color or "Cool yellow", "Neon")
	light(top, Color3.new(1, 0.9, 0.6), 24)
end
K.stand = function(o)
	part("Counter", Vector3.new(8, 3, 3), cf(0, 1.5, 0), o.color or "Bright yellow", "WoodPlanks")
	for _, x in ipairs({ -3.6, 3.6 }) do part("Pole", Vector3.new(0.4, 4, 0.4), cf(x, 5, 1), "Institutional white") end
	part("Roof", Vector3.new(9, 0.4, 4), cf(0, 7.2, 0.5), o.roof or "Bright red", "Fabric")
	local sign = part("Sign", Vector3.new(6, 1.4, 0.3), cf(0, 4.2, -1.6), "Institutional white")
	label(sign, o.sign or "")
	if o.tool then local pad = part("Pickup", Vector3.new(4, 0.3, 3), cf(0, 0.15, -3.5), "Lime green", "Neon") toolGiver(pad, o.tool) end
end
K.tree = function(o)
	local h = o.h or 8
	part("Trunk", Vector3.new(1.4, h, 1.4), cf(0, h / 2, 0), "Reddish brown", "Wood")
	local leaves = o.color or "Bright green"
	local m = o.mat or "Grass"
	if o.pine then
		for i = 0, 3 do part("Leaves", Vector3.new(7 - i * 1.6, 2, 7 - i * 1.6), cf(0, h * 0.5 + i * 2, 0), leaves, m) end
	elseif o.palm then
		for a = 0, 300, 60 do part("Leaf", Vector3.new(6, 0.3, 1.6), cf(0, h, 0, a) * CFrame.new(3, -0.6, 0) * CFrame.Angles(0, 0, math.rad(-15)), leaves, m) end
		ball("Coconut", 0.8, 0.6, h - 0.6, 0, "Brown")
	else
		ball("Leaves", o.size or 7, 0, h + 1, 0, leaves, m, { refl = o.refl })
		ball("Leaves", (o.size or 7) * 0.7, 1.8, h - 0.5, 1, leaves, m, { refl = o.refl })
		ball("Leaves", (o.size or 7) * 0.7, -1.8, h - 0.2, -1, leaves, m, { refl = o.refl })
	end
	if o.fruit then for i = 1, 6 do ball("Fruit", 0.8, math.sin(i) * 2.6, h + math.cos(i * 2), math.cos(i) * 2.6, o.fruit, o.fruitMat, { nocollide = true }) end end
	if o.sparkle then fx(B.model:FindFirstChild("Leaves"), "Sparkles") end
	if o.glow then light(B.model:FindFirstChild("Leaves"), BrickColor.new(leaves).Color, 18) end
end
K.hedge = function(o)
	for i = -2, 2 do part("Hedge", Vector3.new(3, 3, 3), cf(i * 3, 1.5, 0), o.color or "Dark green", "Grass") end
end
K.picnic = function(o)
	part("Table", Vector3.new(7, 0.4, 3.4), cf(0, 3, 0), "Brown", "WoodPlanks")
	for _, x in ipairs({ -2.8, 2.8 }) do part("Leg", Vector3.new(0.4, 2.8, 3), cf(x, 1.4, 0), "Brown", "Wood") end
	for _, z in ipairs({ -2.6, 2.6 }) do seat(-1.5, 1.6, z, 0, "Brown", 3) seat(1.5, 1.6, z, 0, "Brown", 3) end
	part("Cloth", Vector3.new(7.2, 0.1, 3.6), cf(0, 3.25, 0), "Bright red", "Fabric", { nocollide = true })
end
K.doghouse = function(o)
	part("House", Vector3.new(5, 4, 5), cf(0, 2, 0), o.color or "Bright red", "WoodPlanks")
	part("Door", Vector3.new(2, 2.4, 0.2), cf(0, 1.2, -2.5), "Really black")
	part("Roof", Vector3.new(5.6, 2, 3), cf(0, 5, -1.4, 0, 0) , "Dark stone grey", "Slate", { class = "WedgePart" })
	part("Roof", Vector3.new(5.6, 2, 3), cf(0, 5, 1.4, 180), "Dark stone grey", "Slate", { class = "WedgePart" })
	-- the dog
	part("Dog", Vector3.new(1.6, 1.2, 2.6), cf(3.6, 1.2, -2.5), "Nougat")
	ball("DogHead", 1.2, 3.6, 2.1, -3.8, "Nougat")
	for _, p in ipairs({ { 3.1, -1.6 }, { 4.1, -1.6 }, { 3.1, -3.4 }, { 4.1, -3.4 } }) do part("Leg", Vector3.new(0.4, 0.8, 0.4), cf(p[1], 0.4, p[2]), "Nougat") end
end
K.swings = function(o)
	for _, x in ipairs({ -6, 6 }) do
		part("Leg", Vector3.new(0.5, 9, 0.5), cf(x, 4.2, -1.6, 0, 20), "Bright blue", "Metal")
		part("Leg", Vector3.new(0.5, 9, 0.5), cf(x, 4.2, 1.6, 0, -20), "Bright blue", "Metal")
	end
	part("Bar", Vector3.new(13, 0.6, 0.6), cf(0, 8.6, 0), "Bright blue", "Metal")
	for _, x in ipairs({ -3, 0, 3 }) do
		for _, dx in ipairs({ -0.8, 0.8 }) do part("Rope", Vector3.new(0.15, 5.6, 0.15), cf(x + dx, 5.6, 0), "Brown", nil, { nocollide = true }) end
		seat(x, 2.6, 0, 0, "Bright red", 2)
	end
end
K.sandbox = function(o)
	for _, s in ipairs({ { 0, -4, 9, 0.6 }, { 0, 4, 9, 0.6 }, { -4.2, 0, 0.6, 8.4 }, { 4.2, 0, 0.6, 8.4 } }) do
		part("Frame", Vector3.new(s[3], 1, s[4]), cf(s[1], 0.5, s[2]), "Bright blue", "WoodPlanks")
	end
	part("Sand", Vector3.new(7.8, 0.6, 7.4), cf(0, 0.3, 0), "Brick yellow", "Sand")
	part("Bucket", Vector3.new(1, 1, 1), cf(1.5, 1.1, 1), "Bright red")
	ball("SandCastle", 1.8, -1.5, 0.9, -1, "Brick yellow", "Sand")
end
K.campfire = function(o)
	for a = 0, 315, 45 do ball("Stone", 1.2, math.cos(math.rad(a)) * 2.4, 0.5, math.sin(math.rad(a)) * 2.4, "Dark stone grey", "Slate") end
	part("Log", Vector3.new(3.4, 0.7, 0.7), cf(0, 0.5, 0, 30), "Reddish brown", "Wood")
	local l = part("Log", Vector3.new(3.4, 0.7, 0.7), cf(0, 0.9, 0, -30), "Reddish brown", "Wood")
	local f = fx(l, "Fire") f.Size = o.big and 10 or 5 f.Heat = 9
	light(l, Color3.new(1, 0.6, 0.2), o.big and 30 or 20)
	if o.big then fx(l, "Smoke") end
	for a = 0, 270, 90 do part("LogSeat", Vector3.new(3, 1, 1), cf(math.cos(math.rad(a)) * 5.5, 0.5, math.sin(math.rad(a)) * 5.5, -a + 90), "Brown", "Wood", { class = "Seat" }) end
end
K.hammock = function(o)
	for _, x in ipairs({ -5, 5 }) do vcyl("Post", 0.8, 6, x, 3, 0, "Reddish brown", "Wood") end
	seat(-1.5, 2.4, 0, 0, o.color or "Bright orange", 3) seat(1.5, 2.4, 0, 0, o.color or "Bright orange", 3)
	part("Net", Vector3.new(10, 0.2, 2.4), cf(0, 2.95, 0), o.color or "Bright orange", "Fabric", { nocollide = true })
end
K.bbq = function(o)
	part("Grill", Vector3.new(4, 1.6, 2.4), cf(0, 3, 0), "Really black", "Metal")
	part("Lid", Vector3.new(4, 0.4, 2.4), cf(0, 4.4, 1, 0, -60), "Really black", "Metal")
	for _, x in ipairs({ -1.6, 1.6 }) do part("Leg", Vector3.new(0.3, 2.2, 0.3), cf(x, 1.1, 0), "Dark stone grey", "Metal") end
	local g = part("Grate", Vector3.new(3.6, 0.1, 2), cf(0, 3.85, 0), "Dark stone grey", "DiamondPlate")
	fx(g, "Smoke").RiseVelocity = 3
	for i = -1, 1 do part("Burger", Vector3.new(0.8, 0.3, 0.8), cf(i * 1.1, 4, 0), "Brown") end
end
K.hoop = function(o)
	part("Court", Vector3.new(14, 0.2, 14), cf(0, 0.1, 0), "Dark stone grey", "Concrete")
	vcyl("Pole", 0.7, 10, 0, 5, 6, "Dark stone grey", "Metal")
	part("Board", Vector3.new(5, 3.4, 0.3), cf(0, 10.4, 5.4), "Institutional white")
	part("Rim", Vector3.new(2, 0.15, 2), cf(0, 9.4, 4.2), "Bright orange", "Neon", { nocollide = true })
	ball("Ball", 1.2, 2, 0.8, 0, "Bright orange", nil, { nocollide = true })
end
K.rocks = function(o)
	for i = 1, 7 do ball("Rock", 1.2 + (i % 3), math.cos(i * 1.3) * 4, 0.5, math.sin(i * 1.3) * 4, i % 2 == 0 and "Dark stone grey" or "Medium stone grey", "Slate") end
	part("Gravel", Vector3.new(12, 0.2, 12), cf(0, 0.1, 0), "Light stone grey", "Pebble")
end
K.trampoline = function(o)
	for a = 0, 315, 45 do part("Leg", Vector3.new(0.4, 2, 0.4), cf(math.cos(math.rad(a)) * 4.4, 1, math.sin(math.rad(a)) * 4.4), "Dark stone grey", "Metal") end
	vcyl("Ring", 10, 0.6, 0, 2.2, 0, o.color or "Bright blue")
	local mat = vcyl("Mat", 9, 0.7, 0, 2.3, 0, "Really black", "Fabric")
	bounce(mat, o.power or 110)
end
K.slide = function(o)
	part("Tower", Vector3.new(4, 0.6, 4), cf(-4, 7, 0), "Bright yellow", "WoodPlanks")
	for _, p in ipairs({ { -5.8, -1.8 }, { -2.2, -1.8 }, { -5.8, 1.8 }, { -2.2, 1.8 } }) do part("Leg", Vector3.new(0.4, 7, 0.4), cf(p[1], 3.5, p[2]), "Bright red", "Metal") end
	part("Ladder", Vector3.new(2, 7, 2), cf(-7, 3.5, 0), "Bright red", "Metal", { class = "TrussPart" })
	local s = part("Slide", Vector3.new(11, 0.4, 3), cf(2.2, 3.6, 0, 0, 0, -38), o.color or "Bright blue", "SmoothPlastic")
	s.Friction = 0
	for _, z in ipairs({ -1.6, 1.6 }) do part("Side", Vector3.new(11, 1, 0.3), cf(2.2, 4.1, z, 0, 0, -38), o.color or "Bright blue") end
end
K.treehouse = function(o)
	part("Trunk", Vector3.new(3, 14, 3), cf(0, 7, 0), "Reddish brown", "Wood")
	part("Floor", Vector3.new(14, 0.8, 14), cf(0, 12, 0), "Brown", "WoodPlanks")
	for _, w in ipairs({ { 0, -6.6, 14, 0.6 }, { -6.6, 0, 0.6, 14 }, { 6.6, 0, 0.6, 14 } }) do
		part("Wall", Vector3.new(w[3], 5, w[4]), cf(w[1], 14.9, w[2]), "Reddish brown", "WoodPlanks")
	end
	part("Wall", Vector3.new(4.5, 5, 0.6), cf(-4.75, 14.9, 6.6), "Reddish brown", "WoodPlanks")
	part("Wall", Vector3.new(4.5, 5, 0.6), cf(4.75, 14.9, 6.6), "Reddish brown", "WoodPlanks")
	part("Window", Vector3.new(4, 2, 0.2), cf(0, 15.4, -6.6), "Pastel light blue", "Glass", { tr = 0.5 })
	part("Roof", Vector3.new(15, 4, 7.5), cf(0, 19.4, -3.75), "Bright red", "Slate", { class = "WedgePart" })
	part("Roof", Vector3.new(15, 4, 7.5), cf(0, 19.4, 3.75, 180), "Bright red", "Slate", { class = "WedgePart" })
	part("Ladder", Vector3.new(2, 12, 2), cf(0, 6, 8), "Brown", "Wood", { class = "TrussPart" })
	ball("Leaves", 9, 5, 21, 4, "Bright green", "Grass", { nocollide = true, tr = 0.1 })
	seat(-4, 12.9, -4, 180, "Bright blue", 2) seat(4, 12.9, -4, 180, "Bright blue", 2)
	local lamp = ball("Lantern", 0.8, 0, 16.6, 0, "Cool yellow", "Neon", { nocollide = true })
	light(lamp, Color3.new(1, 0.85, 0.5), 14)
end
K.pond = function(o)
	vcyl("Water", 12, 0.4, 0, 0.1, 0, o.color or "Bright blue", nil, { tr = 0.35, refl = 0.2 })
	for a = 0, 330, 30 do ball("Stone", 1.4, math.cos(math.rad(a)) * 6.4, 0.4, math.sin(math.rad(a)) * 6.4, "Medium stone grey", "Slate") end
	if o.koi then for i = 1, 5 do part("Koi", Vector3.new(1.2, 0.3, 0.5), cf(math.cos(i) * 3, 0.35, math.sin(i * 2) * 3, i * 70), i % 2 == 0 and "Bright orange" or "Institutional white", nil, { nocollide = true }) end end
	part("LilyPad", Vector3.new(1.6, 0.1, 1.6), cf(2, 0.35, -2), "Bright green", nil, { nocollide = true })
end
K.bridge = function(o)
	part("Stream", Vector3.new(4, 0.2, 18), cf(0, 0.1, 0), "Bright blue", nil, { tr = 0.3, nocollide = true })
	part("Ramp", Vector3.new(4, 1.5, 4), cf(-4, 0.75, 0, -90), o.color or "Brown", "WoodPlanks", { class = "WedgePart" })
	part("Ramp", Vector3.new(4, 1.5, 4), cf(4, 0.75, 0, 90), o.color or "Brown", "WoodPlanks", { class = "WedgePart" })
	part("Deck", Vector3.new(4, 0.4, 4), cf(0, 1.3, 0), o.color or "Brown", "WoodPlanks")
	for _, z in ipairs({ -1.9, 1.9 }) do part("Rail", Vector3.new(12, 0.3, 0.3), cf(0, 3, z), o.color or "Brown", "Wood") end
	if o.rainbow then
		local cols = { "Bright red", "Bright orange", "Bright yellow", "Bright green", "Bright blue", "Bright violet" }
		for i, c in ipairs(cols) do part("Arc", Vector3.new(12, 0.4, 0.6), cf(0, 6 + i * 0.4, -2.2 + i * 0.6), c, "Neon", { nocollide = true }) end
	end
end
K.flagpole = function(o)
	vcyl("Pole", 0.5, 16, 0, 8, 0, "Light stone grey", "Metal")
	ball("Top", 0.8, 0, 16.2, 0, "Gold", "Metal", { refl = 0.3 })
	part("Flag", Vector3.new(5, 3, 0.2), cf(2.7, 14, 0), o.color or "Bright red", "Fabric")
	part("Stripe", Vector3.new(5, 1, 0.22), cf(2.7, 14, 0), o.color2 or "Institutional white", "Fabric")
end
K.shed = function(o)
	part("Floor", Vector3.new(10, 0.4, 8), cf(0, 0.2, 0), "Brown", "WoodPlanks")
	for _, w in ipairs({ { 0, 3.8, 10, 0.4 }, { -4.8, 0, 0.4, 8 }, { 4.8, 0, 0.4, 8 } }) do part("Wall", Vector3.new(w[3], 6, w[4]), cf(w[1], 3.2, w[2]), o.color or "Dark green", "WoodPlanks") end
	part("Wall", Vector3.new(3, 6, 0.4), cf(-3.5, 3.2, -3.8), o.color or "Dark green", "WoodPlanks")
	part("Wall", Vector3.new(3, 6, 0.4), cf(3.5, 3.2, -3.8), o.color or "Dark green", "WoodPlanks")
	part("Roof", Vector3.new(11, 2.4, 4.6), cf(0, 7.4, -2.1), "Dark stone grey", "Slate", { class = "WedgePart" })
	part("Roof", Vector3.new(11, 2.4, 4.6), cf(0, 7.4, 2.1, 180), "Dark stone grey", "Slate", { class = "WedgePart" })
	part("Mower", Vector3.new(2, 1, 3), cf(2.5, 0.9, 1), "Bright red")
	if o.tool then local pad = part("Pickup", Vector3.new(3, 0.3, 3), cf(0, 0.45, 0), "Lime green", "Neon") toolGiver(pad, o.tool) label(pad, "Free " .. o.tool) end
end
K.gazebo = function(o)
	vcyl("Floor", 14, 0.6, 0, 0.3, 0, "Institutional white", "WoodPlanks")
	for a = 0, 300, 60 do vcyl("Post", 0.6, 7, math.cos(math.rad(a)) * 6, 3.8, math.sin(math.rad(a)) * 6, "Institutional white", "Wood") end
	vcyl("Roof", 15, 0.8, 0, 7.6, 0, o.color or "Bright red", "Slate")
	vcyl("Roof2", 10, 1, 0, 8.4, 0, o.color or "Bright red", "Slate")
	vcyl("Roof3", 5, 1, 0, 9.3, 0, o.color or "Bright red", "Slate")
	for a = 30, 330, 120 do seat(math.cos(math.rad(a)) * 4, 1.1, math.sin(math.rad(a)) * 4, -a - 90, "Brown", 3) end
end
K.hottub = function(o)
	vcyl("Tub", 10, 2.6, 0, 1.3, 0, o.color or "Brown", "WoodPlanks")
	vcyl("Water", 8.6, 0.2, 0, 2.5, 0, "Cyan", nil, { tr = 0.3, nocollide = true })
	local w = B.model:FindFirstChild("Water")
	fx(w, "Sparkles")
	local s = fx(w, "Smoke") s.Opacity = 0.1 s.RiseVelocity = 2 s.Color = Color3.new(1, 1, 1)
	for a = 0, 270, 90 do seat(math.cos(math.rad(a)) * 3.2, 1.9, math.sin(math.rad(a)) * 3.2, -a - 90, "Institutional white", 2) end
	light(w, Color3.new(0.3, 0.8, 1), 14)
end
K.pad = function(o)
	local p = part(o.kind == "jump" and "JumpPad" or "SpeedPad", Vector3.new(8, 0.4, 8), cf(0, 0.2, 0), o.kind == "jump" and "Hot pink" or "Lime green", "Neon")
	label(p, o.kind == "jump" and "JUMP!" or "SPEED BOOST")
	if o.kind == "jump" then bounce(p, o.power or 150) else speedPad(p, o.speed or 40, 12) end
	light(p, BrickColor.new(p.BrickColor.Name).Color, 12)
end
K.statue = function(o)
	local c, m = o.color or "Light stone grey", o.mat or "Marble"
	part("Pedestal", Vector3.new(5, 2, 5), cf(0, 1, 0), "Dark stone grey", "Granite")
	if o.shape == "trophy" then
		vcyl("Stem", 1, 3, 0, 3.5, 0, c, m, { refl = o.refl })
		ball("Cup", 4, 0, 6.4, 0, c, m, { refl = o.refl })
		for _, x in ipairs({ -2.2, 2.2 }) do part("Handle", Vector3.new(0.6, 2, 0.6), cf(x, 6.6, 0), c, m, { refl = o.refl }) end
	elseif o.shape == "crown" then
		vcyl("Band", 4, 1.6, 0, 2.8, 0, c, m, { refl = o.refl })
		for a = 0, 300, 60 do part("Point", Vector3.new(0.8, 1.6, 0.8), cf(math.cos(math.rad(a)) * 1.7, 4.4, math.sin(math.rad(a)) * 1.7), c, m, { refl = o.refl }) ball("Gem", 0.6, math.cos(math.rad(a)) * 1.7, 5.4, math.sin(math.rad(a)) * 1.7, "Bright red", "Neon") end
	elseif o.shape == "moon" then
		ball("Moon", 6, 0, 5.4, 0, c, m, { refl = o.refl })
		light(B.model:FindFirstChild("Moon"), Color3.new(0.8, 0.85, 1), 24)
	elseif o.shape == "dragon" then
		part("Body", Vector3.new(2, 2, 6), cf(0, 3.4, 0), c, m)
		part("Neck", Vector3.new(1.2, 3, 1.2), cf(0, 5.2, -2.6, 0, -30), c, m)
		part("Head", Vector3.new(1.6, 1.4, 2.4), cf(0, 6.8, -3.8), c, m)
		for _, x in ipairs({ -2.5, 2.5 }) do part("Wing", Vector3.new(4, 0.3, 3), cf(x, 5, 0.5, 0, 0, x > 0 and 30 or -30), c, m) end
		part("Tail", Vector3.new(0.8, 0.8, 4), cf(0, 2.8, 4.5, 0, 15), c, m)
		ball("Eye", 0.4, 0.5, 7.1, -4.9, "Bright red", "Neon")
		local f = fx(B.model:FindFirstChild("Head"), "Fire") f.Size = 3
	elseif o.shape == "robot" then
		part("Legs", Vector3.new(2, 2.4, 1), cf(0, 3.2, 0), c, m)
		part("Body", Vector3.new(3, 3, 1.6), cf(0, 5.9, 0), c, m)
		part("Head", Vector3.new(2, 1.8, 1.6), cf(0, 8.3, 0), c, m)
		for _, x in ipairs({ -0.5, 0.5 }) do ball("Eye", 0.5, x, 8.5, -0.8, "Cyan", "Neon") end
		for _, x in ipairs({ -2, 2 }) do part("Arm", Vector3.new(0.8, 2.8, 0.8), cf(x, 6, 0), c, m) end
		part("Tray", Vector3.new(2.4, 0.2, 1.6), cf(2, 4.6, -1), "Light stone grey", "Metal")
	else -- a person-shaped statue
		part("Legs", Vector3.new(2, 2.6, 1), cf(0, 3.3, 0), c, m, { refl = o.refl })
		part("Torso", Vector3.new(2, 2.2, 1), cf(0, 5.7, 0), c, m, { refl = o.refl })
		part("Head", Vector3.new(1.2, 1.2, 1.2), cf(0, 7.4, 0), c, m, { refl = o.refl })
		part("Arm", Vector3.new(0.9, 2.2, 0.9), cf(-1.5, 5.7, 0), c, m, { refl = o.refl })
		part("Arm", Vector3.new(0.9, 2.2, 0.9), cf(1.6, 7.3, 0, 0, 0, 160), c, m, { refl = o.refl })
	end
	if o.glow then light(B.model:FindFirstChild("Pedestal"), BrickColor.new(c).Color, 16) end
	if o.sparkle then fx(B.model:FindFirstChild("Pedestal"), "Sparkles") end
end
K.fountain = function(o)
	vcyl("Basin", 12, 1.6, 0, 0.8, 0, o.color or "Light stone grey", o.mat or "Marble", { refl = o.refl })
	vcyl("Water", 11, 0.2, 0, 1.55, 0, o.water or "Cyan", o.water and "Neon" or nil, { tr = 0.3, nocollide = true })
	vcyl("Pillar", 1.6, 5, 0, 3.5, 0, o.color or "Light stone grey", o.mat or "Marble", { refl = o.refl })
	vcyl("Top", 4, 0.8, 0, 6.2, 0, o.color or "Light stone grey", o.mat or "Marble", { refl = o.refl })
	local w = B.model:FindFirstChild("Top")
	fx(w, "Sparkles")
	light(w, BrickColor.new(o.water or "Cyan").Color, 16)
end
K.greenhouse = function(o)
	part("Base", Vector3.new(12, 0.4, 10), cf(0, 0.2, 0), "Light stone grey", "Concrete")
	for _, w in ipairs({ { 0, 4.8, 12, 0.3 }, { 0, -4.8, 12, 0.3 }, { -5.9, 0, 0.3, 10 } }) do part("Glass", Vector3.new(w[3], 6, w[4]), cf(w[1], 3.2, w[2]), "Pastel light blue", "Glass", { tr = 0.6 }) end
	part("Roof", Vector3.new(12, 0.3, 10), cf(0, 6.3, 0), "Pastel light blue", "Glass", { tr = 0.6 })
	for i = -1, 1 do
		part("Planter", Vector3.new(2, 1, 7), cf(i * 3.5, 0.9, 0), "Reddish brown", "Wood")
		for j = -1, 1 do ball("Plant", 1.4, i * 3.5, 2, j * 2.2, (i + j) % 2 == 0 and "Bright green" or "Bright red", "Grass") end
	end
end
K.solar = function(o)
	for i = -1, 1 do
		part("Stand", Vector3.new(0.4, 2.4, 0.4), cf(i * 5, 1.2, 0), "Light stone grey", "Metal")
		part("Panel", Vector3.new(4.4, 0.2, 6), cf(i * 5, 2.6, 0, 0, 30), "Navy blue", "Glass", { refl = 0.3 })
	end
end
K.carousel = function(o)
	vcyl("Base", 14, 0.8, 0, 0.4, 0, "Institutional white", "WoodPlanks")
	local parts = {}
	table.insert(parts, vcyl("Floor", 13, 0.4, 0, 1, 0, o.color or "Bright red", "WoodPlanks"))
	vcyl("Pole", 1, 9, 0, 5, 0, "Gold", "Metal", { refl = 0.3 })
	table.insert(parts, vcyl("Roof", 14, 0.8, 0, 9.4, 0, o.color or "Bright red", "Fabric"))
	for a = 0, 300, 60 do
		local x, z = math.cos(math.rad(a)) * 4.6, math.sin(math.rad(a)) * 4.6
		table.insert(parts, vcyl("Rod", 0.3, 8, x, 5.2, z, "Gold", "Metal"))
		table.insert(parts, part("Horse", Vector3.new(1, 1.6, 2.6), cf(x, 3.4, z, -a), a % 120 == 0 and "Institutional white" or "Brown"))
		table.insert(parts, seat(x, 4.6, z, -a, "Bright blue", 1.2))
	end
	spin(parts, B.o * CFrame.new(0, 0, 0), "y", 25)
end
K.turbine = function(o)
	vcyl("Tower", 1.2, 18, 0, 9, 0, "Institutional white", "Metal")
	local hub = part("Hub", Vector3.new(1.6, 1.6, 2), cf(0, 18, -1), "Institutional white", "Metal")
	local parts = { hub }
	for a = 0, 240, 120 do table.insert(parts, part("Blade", Vector3.new(0.5, 8, 0.2), cf(0, 18, -2.1) * CFrame.Angles(0, 0, math.rad(a)) * CFrame.new(0, 4, 0), "Institutional white", "SmoothPlastic", { nocollide = true })) end
	spin(parts, B.o * CFrame.new(0, 18, -2), "z", 90)
end
K.windmill = function(o)
	vcyl("Tower", 7, 12, 0, 6, 0, o.color or "Brick yellow", "Brick")
	vcyl("Cap", 7.6, 2.6, 0, 13.3, 0, "Reddish brown", "Slate")
	local parts = {}
	for a = 0, 270, 90 do table.insert(parts, part("Sail", Vector3.new(1.6, 7, 0.2), cf(0, 11, -3.8) * CFrame.Angles(0, 0, math.rad(a)) * CFrame.new(0, 3.6, 0), "Institutional white", "Fabric", { nocollide = true })) end
	spin(parts, B.o * CFrame.new(0, 11, -3.8), "z", 45)
	part("Door", Vector3.new(2, 3.4, 0.2), cf(0, 1.7, -3.5), "Brown", "Wood")
end
K.oven = function(o)
	part("Base", Vector3.new(6, 3, 5), cf(0, 1.5, 0), "Brick yellow", "Brick")
	ball("Dome", 5, 0, 3.2, 0, "Bright orange", "Brick")
	local f = part("Mouth", Vector3.new(2, 1.4, 0.2), cf(0, 3.6, -2.4), "Really black")
	local fire = fx(f, "Fire") fire.Size = 2
	light(f, Color3.new(1, 0.5, 0.1), 12)
	vcyl("Pizza", 1.8, 0.2, 2.5, 3.1, -2, "Bright yellow")
end
K.arcade = function(o)
	for i = -1, 1 do
		part("Cabinet", Vector3.new(2.6, 5.4, 2.4), cf(i * 3.4, 2.7, 0), i == 0 and "Royal purple" or "Really black", "SmoothPlastic")
		part("Screen", Vector3.new(2, 1.6, 0.1), cf(i * 3.4, 3.8, -1.25), i == 0 and "Lime green" or "Cyan", "Neon")
		part("Buttons", Vector3.new(2, 0.3, 0.8), cf(i * 3.4, 2.6, -1.4), "Bright red", "Neon")
	end
	light(B.model:FindFirstChild("Screen"), Color3.new(0.5, 1, 1), 12)
end
K.telescope = function(o)
	for a = 0, 240, 120 do part("Leg", Vector3.new(0.3, 4, 0.3), cf(math.cos(math.rad(a)) * 0.9, 2, math.sin(math.rad(a)) * 0.9, 0, a == 0 and 12 or -12), "Really black", "Metal") end
	vcyl("Tube", 0.9, 5, 0, 4.8, 0, "Institutional white", "Metal")
	B.model:FindFirstChild("Tube").CFrame = B.o * cf(0, 4.8, 0, 0, 0, 40)
end
K.minigolf = function(o)
	part("Green", Vector3.new(14, 0.3, 6), cf(0, 0.15, 0), "Bright green", "Grass")
	for _, z in ipairs({ -3.2, 3.2 }) do part("Edge", Vector3.new(14, 0.8, 0.4), cf(0, 0.4, z), "Brown", "Wood") end
	vcyl("Hole", 1, 0.32, 5, 0.16, 0, "Really black")
	vcyl("FlagPole", 0.2, 4, 5, 2, 0, "Institutional white")
	part("Flag", Vector3.new(1.6, 1, 0.1), cf(5.8, 3.6, 0), "Bright red")
	ball("GolfBall", 0.5, -5, 0.55, 0, "Institutional white")
	part("Windmill", Vector3.new(2, 3, 2), cf(0, 1.8, 0), "Bright red", "WoodPlanks")
end
K.disco = function(o)
	local tiles = {}
	for i = -2, 2 do for j = -2, 2 do table.insert(tiles, part("Tile", Vector3.new(2.6, 0.3, 2.6), cf(i * 2.8, 0.15, j * 2.8), "Bright blue", "Neon")) end end
	table.insert(B.blink, tiles)
	local b = ball("DiscoBall", 2, 0, 8, 0, "Light stone grey", "Metal", { refl = 0.6, nocollide = true })
	vcyl("Chain", 0.15, 4, 0, 11, 0, "Dark stone grey")
	light(b, Color3.new(1, 0.4, 1), 20)
	if o.tool then local pad = part("Pickup", Vector3.new(2.6, 0.32, 2.6), cf(0, 0.16, 0), "Lime green", "Neon") toolGiver(pad, o.tool) label(pad, "Free " .. o.tool) end
end
K.garage = function(o)
	part("Floor", Vector3.new(12, 0.3, 12), cf(0, 0.15, 0), "Medium stone grey", "Concrete")
	for _, w in ipairs({ { 0, 5.8, 12, 0.4 }, { -5.8, 0, 0.4, 12 }, { 5.8, 0, 0.4, 12 } }) do part("Wall", Vector3.new(w[3], 7, w[4]), cf(w[1], 3.5, w[2]), o.color or "Institutional white", "Brick") end
	part("Roof", Vector3.new(12.6, 0.6, 12.6), cf(0, 7.3, 0), "Dark stone grey", "Slate")
	part("DoorTop", Vector3.new(12, 2, 0.4), cf(0, 6, -5.8), "Light stone grey", "Metal")
	if o.tool then local pad = part("Pickup", Vector3.new(4, 0.32, 6), cf(0, 0.32, 0), "Lime green", "Neon") toolGiver(pad, o.tool) label(pad, "Free " .. o.tool) end
end
K.printer = function(o)
	local c = o.color or "Dark stone grey"
	part("Machine", Vector3.new(6, 4, 4), cf(0, 2, 0), c, "DiamondPlate", { refl = o.refl })
	part("Screen", Vector3.new(3, 1, 0.1), cf(0, 3, -2.05), "Lime green", "Neon")
	local tray = part("Tray", Vector3.new(4, 0.4, 2), cf(0, 1.2, -2.6), "Light stone grey", "Metal")
	for i = 1, 3 do part("Cash", Vector3.new(2, 0.15, 1), cf(0, 1.4 + i * 0.16, -2.6, i * 8), "Bright green", nil, { nocollide = true }) end
	fx(tray, "Sparkles")
	light(tray, Color3.new(0.3, 1, 0.3), 12)
end
K.lighthouse = function(o)
	for i = 0, 5 do vcyl("Tower", 5 - i * 0.4, 3, 0, 1.5 + i * 3, 0, i % 2 == 0 and "Institutional white" or "Bright red", "Concrete") end
	local lamp = vcyl("Lamp", 3, 2, 0, 19, 0, "Cool yellow", "Neon")
	vcyl("Cap", 3.6, 1, 0, 20.5, 0, "Bright red", "Metal")
	light(lamp, Color3.new(1, 1, 0.7), 40)
	local beam = part("Beam", Vector3.new(0.6, 0.6, 14), cf(0, 19, -7), "Cool yellow", "Neon", { tr = 0.6, nocollide = true })
	spin({ beam }, B.o * CFrame.new(0, 19, 0), "y", 60)
end
K.atm = function(o)
	part("Booth", Vector3.new(4, 7, 4), cf(0, 3.5, 0), o.color or "Bright blue", "SmoothPlastic")
	part("Screen", Vector3.new(2.4, 1.6, 0.1), cf(0, 4.6, -2.05), "Cyan", "Neon")
	part("Slot", Vector3.new(1.6, 0.2, 0.2), cf(0, 3.4, -2.1), "Really black")
	local s = part("Sign", Vector3.new(4, 1, 0.1), cf(0, 6.6, -2.05), "Lime green", "Neon")
	label(s, o.sign or "ATM")
end
K.dish = function(o)
	vcyl("Post", 0.8, 5, 0, 2.5, 0, "Light stone grey", "Metal")
	local d = vcyl("Dish", 7, 0.4, 0, 6, 0, "Institutional white", "Metal")
	d.CFrame = B.o * cf(0, 6, 0, 0, 0, 55)
	ball("Receiver", 0.6, 1.6, 7.4, 0, "Bright red", "Neon")
end
K.watertower = function(o)
	for _, p in ipairs({ { -2.5, -2.5 }, { 2.5, -2.5 }, { -2.5, 2.5 }, { 2.5, 2.5 } }) do part("Leg", Vector3.new(0.6, 12, 0.6), cf(p[1], 6, p[2]), "Dark stone grey", "Metal") end
	vcyl("Tank", 8, 6, 0, 15, 0, o.color or "Light stone grey", "Metal")
	ball("Top", 8, 0, 18, 0, o.color or "Light stone grey", "Metal")
	part("Ladder", Vector3.new(2, 12, 2), cf(0, 6, -4.6), "Dark stone grey", "Metal", { class = "TrussPart" })
end
K.observatory = function(o)
	vcyl("Building", 12, 7, 0, 3.5, 0, "Institutional white", "Concrete")
	ball("Dome", 12, 0, 7, 0, "Light stone grey", "Metal", { refl = 0.2 })
	part("Slit", Vector3.new(1.6, 6, 0.4), cf(0, 10, -5.2), "Really black")
	part("Door", Vector3.new(3, 5, 0.2), cf(0, 2.5, -6), "Brown", "Wood")
end
K.rocket = function(o)
	local s = o.size or 1
	vcyl("Body", 4 * s, 14 * s, 0, 7 * s + 1, 0, o.color or "Institutional white", "Metal", { refl = o.refl })
	ball("Nose", 4 * s, 0, 14 * s + 1, 0, o.nose or "Bright red", "Metal", { refl = o.refl })
	for a = 0, 240, 120 do part("Fin", Vector3.new(0.4, 4 * s, 3 * s), cf(math.cos(math.rad(a)) * 2.4 * s, 2 * s + 1, math.sin(math.rad(a)) * 2.4 * s, -a), o.nose or "Bright red", "Metal") end
	ball("Window", 1.4 * s, 0, 10 * s + 1, -1.8 * s, "Cyan", "Neon")
	local e = part("Engine", Vector3.new(2 * s, 1, 2 * s), cf(0, 0.5, 0), "Dark stone grey", "Metal")
	if o.fire then local f = fx(e, "Fire") f.Size = 6 * s fx(e, "Smoke") end
end
K.pyramid = function(o)
	for i = 0, 5 do part("Step", Vector3.new(14 - i * 2.4, 2, 14 - i * 2.4), cf(0, 1 + i * 2, 0), o.color or "Brick yellow", o.mat or "Sand", { refl = o.refl }) end
	if o.top then ball("Cap", 1.6, 0, 12.6, 0, o.top, "Neon") light(B.model:FindFirstChild("Cap"), BrickColor.new(o.top).Color, 20) end
end
K.maze = function(o)
	local walls = { { 0, -7, 14, 1 }, { 0, 7, 14, 1 }, { -7, 0, 1, 14 }, { 7, 2, 1, 10 }, { -3, -3, 1, 7 }, { 2, 0, 7, 1 }, { 3, 4, 1, 5 }, { -1, 4, 5, 1 } }
	for _, w in ipairs(walls) do part("Hedge", Vector3.new(w[3], 4, w[4]), cf(w[1], 2, w[2]), "Dark green", "Grass") end
	local prize = ball("Prize", 1.2, 4.5, 1, -4.5, "Gold", "Neon")
	light(prize, Color3.new(1, 0.8, 0.2), 10)
end
K.ferris = function(o)
	for _, z in ipairs({ -2.5, 2.5 }) do
		part("Leg", Vector3.new(0.8, 14, 0.8), cf(-3.6, 6.6, z, 0, 0, -15), "Light stone grey", "Metal")
		part("Leg", Vector3.new(0.8, 14, 0.8), cf(3.6, 6.6, z, 0, 0, 15), "Light stone grey", "Metal")
	end
	local center = B.o * CFrame.new(0, 13.4, 0)
	local parts = { part("Hub", Vector3.new(2, 2, 5.6), cf(0, 13.4, 0), "Bright red", "Metal") }
	for a = 0, 315, 45 do
		local x, y = math.cos(math.rad(a)) * 7, math.sin(math.rad(a)) * 7
		table.insert(parts, part("Spoke", Vector3.new(7, 0.3, 0.3), cf(x / 2, 13.4 + y / 2, 0) * CFrame.Angles(0, 0, math.rad(a)), "Institutional white", "Metal", { nocollide = true }))
		table.insert(parts, part("Car", Vector3.new(2.4, 1.6, 2.4), cf(x, 13.4 + y - 1, 0), a % 90 == 0 and "Bright yellow" or "Bright blue", "SmoothPlastic", { nocollide = true }))
	end
	spin(parts, center, "z", 18)
	light(parts[1], Color3.new(1, 0.7, 0.9), 20)
end
K.vault = function(o)
	part("Vault", Vector3.new(10, 8, 8), cf(0, 4, 0), "Dark stone grey", "DiamondPlate")
	vcyl("Door", 6, 0.6, 0, 4, -4.1, "Light stone grey", "Metal", { refl = 0.3 })
	B.model:FindFirstChild("Door").CFrame = B.o * cf(0, 4, -4.1, 90, 0, 90)
	for i = 0, 2 do for j = 0, 1 do part("GoldBar", Vector3.new(2, 0.8, 1), cf(-3 + i * 2.2, 0.4 + j * 0.8, -6), "Gold", "Metal", { refl = 0.4 }) end end
	fx(B.model:FindFirstChild("GoldBar"), "Sparkles")
end
K.castle = function(o)
	vcyl("Tower", 7, 14, 0, 7, 0, o.color or "Medium stone grey", o.mat or "Brick")
	for a = 0, 315, 45 do part("Merlon", Vector3.new(1.2, 1.4, 1.2), cf(math.cos(math.rad(a)) * 3, 14.7, math.sin(math.rad(a)) * 3), o.color or "Medium stone grey", o.mat or "Brick") end
	part("Door", Vector3.new(2.4, 4, 0.3), cf(0, 2, -3.5), "Brown", "Wood")
	vcyl("FlagPole", 0.3, 5, 0, 16.5, 0, "Brown")
	part("Flag", Vector3.new(2.4, 1.4, 0.1), cf(1.3, 18.2, 0), o.flag or "Bright red", "Fabric")
	if o.mat == "Ice" then light(B.model:FindFirstChild("Tower"), Color3.new(0.6, 0.9, 1), 20) end
end
K.lavalamp = function(o)
	vcyl("Base", 4, 3, 0, 1.5, 0, "Gold", "Metal", { refl = 0.3 })
	vcyl("Glass", 3, 10, 0, 8, 0, "Royal purple", "Glass", { tr = 0.5 })
	local parts = {}
	for i = 1, 4 do table.insert(parts, ball("Blob", 1.6, 0, 4 + i * 2, 0, "Hot pink", "Neon", { nocollide = true })) end
	vcyl("Cap", 3.4, 1.4, 0, 13.7, 0, "Gold", "Metal", { refl = 0.3 })
	light(parts[1], Color3.new(1, 0.3, 0.8), 18)
	table.insert(B.bob, parts)
end
K.neonsign = function(o)
	for _, x in ipairs({ -5, 5 }) do part("Post", Vector3.new(0.6, 8, 0.6), cf(x, 4, 0), "Really black", "Metal") end
	local s = part("Board", Vector3.new(11, 4, 0.4), cf(0, 8, 0), "Really black")
	part("Frame", Vector3.new(11.4, 0.3, 0.5), cf(0, 10.1, 0), o.color or "Hot pink", "Neon")
	part("Frame", Vector3.new(11.4, 0.3, 0.5), cf(0, 5.9, 0), o.color or "Hot pink", "Neon")
	label(s, o.text or "MANSION")
	light(s, BrickColor.new(o.color or "Hot pink").Color, 18)
end
K.ufo = function(o)
	local center = B.o * CFrame.new(0, 12, 0)
	local parts = {}
	table.insert(parts, vcyl("Saucer", 12, 1.2, 0, 12, 0, "Light stone grey", "Metal", { refl = 0.3 }))
	table.insert(parts, ball("Cockpit", 5, 0, 13, 0, "Cyan", "Glass", { tr = 0.4 }))
	for a = 0, 300, 60 do table.insert(parts, ball("Light", 0.8, math.cos(math.rad(a)) * 5.5, 11.4, math.sin(math.rad(a)) * 5.5, a % 120 == 0 and "Lime green" or "Hot pink", "Neon", { nocollide = true })) end
	spin(parts, center, "y", 40)
	part("Beam", Vector3.new(4, 11, 4), cf(0, 5.5, 0), "Lime green", "Neon", { tr = 0.75, nocollide = true })
	light(parts[1], Color3.new(0.4, 1, 0.4), 24)
end
K.volcano = function(o)
	for i = 0, 4 do vcyl("Rock", 14 - i * 2.4, 2, 0, 1 + i * 2, 0, i < 3 and "Dark stone grey" or "Reddish brown", "Slate") end
	local top = vcyl("Lava", 3, 0.4, 0, 10.1, 0, "Neon orange", "Neon")
	local f = fx(top, "Fire") f.Size = 8 f.Heat = 15
	local s = fx(top, "Smoke") s.Color = Color3.new(0.2, 0.2, 0.2) s.Size = 4 s.RiseVelocity = 8
	light(top, Color3.new(1, 0.4, 0), 30)
end
K.chest = function(o)
	part("Chest", Vector3.new(5, 3, 3), cf(0, 1.5, 0), "Brown", "WoodPlanks")
	part("Lid", Vector3.new(5, 1, 3), cf(0, 3.8, 1, 0, -45), "Brown", "WoodPlanks")
	for _, x in ipairs({ -2.4, 2.4 }) do part("Band", Vector3.new(0.3, 3.1, 3.1), cf(x, 1.5, 0), "Gold", "Metal", { refl = 0.4 }) end
	for i = 1, 5 do ball("Coin", 0.8, math.cos(i) * 1.4, 3.2, math.sin(i) * 0.8, "Gold", "Neon", { nocollide = true }) end
	fx(B.model:FindFirstChild("Coin"), "Sparkles")
	light(B.model:FindFirstChild("Coin"), Color3.new(1, 0.8, 0.2), 14)
end
K.waterfall = function(o)
	part("Cliff", Vector3.new(12, 12, 3), cf(0, 6, 4), "Dark stone grey", "Slate")
	part("Fall", Vector3.new(5, 11, 0.4), cf(0, 6.4, 2.3), "Cyan", "Neon", { tr = 0.45, nocollide = true })
	vcyl("Pool", 11, 0.4, 0, 0.2, -2, "Bright blue", nil, { tr = 0.3 })
	for a = 0, 330, 30 do ball("Stone", 1.4, math.cos(math.rad(a)) * 5.6, 0.5, -2 + math.sin(math.rad(a)) * 5.6, "Medium stone grey", "Slate") end
	local s = fx(B.model:FindFirstChild("Pool"), "Smoke") s.Color = Color3.new(1, 1, 1) s.Opacity = 0.15 s.RiseVelocity = 2
end
K.throne = function(o)
	part("Step", Vector3.new(8, 1, 8), cf(0, 0.5, 0), "Bright red", "Fabric")
	seat(0, 2, 0, 0, "Gold", 3)
	part("Back", Vector3.new(3.4, 6, 0.6), cf(0, 4.6, 1.4), "Gold", "Metal", { refl = 0.4 })
	for _, x in ipairs({ -1.8, 1.8 }) do part("Arm", Vector3.new(0.6, 1.4, 3), cf(x, 2.4, 0.2), "Gold", "Metal", { refl = 0.4 }) end
	ball("Gem", 1, 0, 7.8, 1.4, "Bright red", "Neon")
	fx(B.model:FindFirstChild("Back"), "Sparkles")
end
K.portal = function(o)
	for _, x in ipairs({ -4, 4 }) do part("Pillar", Vector3.new(1.6, 10, 1.6), cf(x, 5, 0), "Royal purple", "Marble") end
	part("Top", Vector3.new(9.6, 1.6, 1.6), cf(0, 10.8, 0), "Royal purple", "Marble")
	local p = part("Portal", Vector3.new(6.4, 9.6, 0.6), cf(0, 5, 0), "Hot pink", "Neon", { tr = 0.4, nocollide = true })
	label(p, "TO THE MANSION")
	light(p, Color3.new(1, 0.4, 1), 20)
	teleportPad(p, B.home)
end

------------------------------------------------------------------ the 100 things (rows of 10, cheapest first)
local ITEMS = {
	-- row 1
	{ "Mailbox", "mailbox" }, { "Garden Gnome", "gnome" }, { "Red Flowers", "flowers", { color = "Bright red" } },
	{ "Bird Bath", "birdbath" }, { "Wooden Bench", "bench" }, { "Lamp Post", "lamp" },
	{ "Lemonade Stand", "stand", { sign = "LEMONADE", color = "Bright yellow" } }, { "Small Tree", "tree", { h = 6, size = 5 } },
	{ "Hedge Row", "hedge" }, { "Yellow Flowers", "flowers", { color = "Bright yellow", color2 = "Institutional white" } },
	-- row 2
	{ "Picnic Table", "picnic" }, { "Dog House", "doghouse" }, { "Swing Set", "swings" }, { "Sandbox", "sandbox" },
	{ "Campfire", "campfire" }, { "Hammock", "hammock" }, { "BBQ Grill", "bbq" }, { "Basketball Hoop", "hoop" },
	{ "Rock Garden", "rocks" }, { "Blue Flowers", "flowers", { color = "Bright blue", color2 = "Pink" } },
	-- row 3
	{ "Trampoline", "trampoline" }, { "Slide", "slide" }, { "Tree House", "treehouse" }, { "Pond", "pond" },
	{ "Little Bridge", "bridge" }, { "Flag Pole", "flagpole" }, { "Big Oak Tree", "tree", { h = 10, size = 9 } },
	{ "Hot Dog Stand", "stand", { sign = "HOT DOGS", color = "Bright red", roof = "Bright yellow", tool = "Hot Dog" } },
	{ "Soda Machine", "stand", { sign = "BLOXY COLA", color = "Bright red", roof = "Really black", tool = "BloxyCola" } },
	{ "Garden Shed", "shed" },
	-- row 4
	{ "Gazebo", "gazebo" }, { "Hot Tub", "hottub" }, { "Speed Pad", "pad", { kind = "speed" } },
	{ "Frisbee Shed", "shed", { color = "Bright blue", tool = "Frisbee" } }, { "Stone Statue", "statue" },
	{ "Garden Fountain", "fountain" }, { "Greenhouse", "greenhouse" }, { "Solar Panels", "solar" },
	{ "Pine Trees", "tree", { pine = true, h = 9, color = "Dark green" } }, { "Pink Gnome", "gnome", { color = "Hot pink", hat = "Royal purple" } },
	-- row 5
	{ "Carousel", "carousel" }, { "Wind Turbine", "turbine" }, { "Jump Pad", "pad", { kind = "jump" } },
	{ "Pizza Oven", "oven" }, { "Arcade Corner", "arcade" }, { "Telescope", "telescope" }, { "Mini Golf", "minigolf" },
	{ "Palm Tree", "tree", { palm = true, h = 11, color = "Bright green" } }, { "Koi Pond", "pond", { koi = true } },
	{ "Big Campfire", "campfire", { big = true } },
	-- row 6
	{ "Disco Floor", "disco", { tool = "DiscoBall" } }, { "Spray Paint Shed", "shed", { color = "Hot pink", tool = "Spray" } },
	{ "Cloud Garage", "garage", { color = "Pastel light blue", tool = "Cloud" } }, { "Motorcycle Garage", "garage", { tool = "Motorcycle" } },
	{ "Money Printer", "printer" }, { "Lighthouse", "lighthouse" }, { "Windmill", "windmill" },
	{ "Apple Tree", "tree", { fruit = "Bright red", h = 8 } }, { "Super Trampoline", "trampoline", { color = "Hot pink", power = 170 } },
	{ "Ice Cream Stand", "stand", { sign = "ICE CREAM", color = "Pink", roof = "Pastel light blue" } },
	-- row 7
	{ "ATM", "atm" }, { "Satellite Dish", "dish" }, { "Water Tower", "watertower" }, { "Observatory", "observatory" },
	{ "Rocket Statue", "rocket", { size = 0.7 } }, { "Pyramid", "pyramid" }, { "Hedge Maze", "maze" },
	{ "Ferris Wheel", "ferris" }, { "Golden Bench", "bench", { color = "Gold", mat = "Metal", gold = true } },
	{ "Mega Speed Pad", "pad", { kind = "speed", speed = 60 } },
	-- row 8
	{ "Bank Vault", "vault" }, { "Crystal Tree", "tree", { color = "Cyan", mat = "Neon", glow = true, h = 8 } },
	{ "Lava Lamp Tower", "lavalamp" }, { "Castle Tower", "castle" }, { "Golden Gnome", "gnome", { color = "Gold", hat = "Gold", skin = "Gold", mat = "Metal", gold = true } },
	{ "Diamond Fountain", "fountain", { color = "Cyan", mat = "Ice", refl = 0.3, water = "Toothpaste" } },
	{ "Rainbow Bridge", "bridge", { rainbow = true, color = "Institutional white" } }, { "Neon Sign", "neonsign", { text = "MANSION", color = "Hot pink" } },
	{ "Hero Statue", "statue", { color = "Gold", mat = "Metal", refl = 0.4 } }, { "Dragon Statue", "statue", { shape = "dragon", color = "Dark green", mat = "Slate" } },
	-- row 9
	{ "Robot Butler", "statue", { shape = "robot", color = "Light stone grey", mat = "Metal" } }, { "UFO", "ufo" },
	{ "Volcano", "volcano" }, { "Golden Tree", "tree", { color = "Gold", mat = "Metal", refl = 0.4, sparkle = true, h = 9 } },
	{ "Rocket Ship", "rocket", { size = 1.1, fire = true } }, { "Treasure Chest", "chest" }, { "Waterfall", "waterfall" },
	{ "Ice Castle", "castle", { color = "Pastel light blue", mat = "Ice", flag = "Cyan" } },
	{ "Crown Statue", "statue", { shape = "crown", color = "Gold", mat = "Metal", refl = 0.4, sparkle = true } },
	{ "Mansion Portal", "portal" },
	-- row 10
	{ "Diamond Tree", "tree", { color = "Toothpaste", mat = "Neon", glow = true, sparkle = true, h = 10, size = 8 } },
	{ "Golden Throne", "throne" },
	{ "Money Tree", "tree", { color = "Bright green", fruit = "Gold", fruitMat = "Neon", sparkle = true, h = 10, size = 8 } },
	{ "Mega Printer", "printer", { color = "Gold", refl = 0.4 } }, { "Rainbow Fountain", "fountain", { color = "Institutional white", water = "Hot pink" } },
	{ "Giant Trophy", "statue", { shape = "trophy", color = "Gold", mat = "Metal", refl = 0.5, glow = true } },
	{ "Moon Statue", "statue", { shape = "moon", color = "Light stone grey", mat = "Slate" } },
	{ "Golden Rocket", "rocket", { size = 1.2, color = "Gold", nose = "Gold", refl = 0.4, fire = true } },
	{ "Golden Pyramid", "pyramid", { color = "Gold", mat = "Metal", refl = 0.3, top = "Cyan" } },
	{ "Mansion Monument", "statue", { color = "Institutional white", mat = "Marble", glow = true, sparkle = true } },
}

-- prices go up ~10% per item (from $100 to about $2M); every item pays money per second.
-- Money makers pay much more than decorations.
local MONEY = { ["Lemonade Stand"] = 4, ["Hot Dog Stand"] = 3, ["Soda Machine"] = 3, ["Money Printer"] = 5, ["ATM"] = 4,
	["Bank Vault"] = 5, ["Treasure Chest"] = 4, ["Money Tree"] = 5, ["Mega Printer"] = 6, ["Solar Panels"] = 3, ["Wind Turbine"] = 3,
	["Ice Cream Stand"] = 3, ["Pizza Oven"] = 2, ["Arcade Corner"] = 2 }
local function nice(n)
	local mag = 10 ^ math.max(0, math.floor(math.log10(n)) - 1)
	return math.floor(n / mag + 0.5) * mag
end
for i, it in ipairs(ITEMS) do
	it.price = nice(100 * 1.105 ^ (i - 1))
	it.income = math.max(1, math.floor(it.price / 250 * (MONEY[it[1]] or 1) + 0.5))
	it.row = math.floor((i - 1) / COLS)
	it.col = (i - 1) % COLS
end
assert(#ITEMS == ROWS * COLS, "need 100 items")

local function money(n)
	local s = tostring(math.floor(n))
	local out = ""
	while #s > 3 do out = "," .. s:sub(-3) .. out s = s:sub(1, -4) end
	return "$" .. s .. out
end

------------------------------------------------------------------ remote + values the UI reads
local remote = RS:FindFirstChild("BackyardEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "BackyardEvent"
	remote.Parent = RS
end

------------------------------------------------------------------ one backyard per tycoon
local YARDS = {}
local SPIN, BLINK, BOB = {}, {}, {}

local function ownerOf(Y)
	local f = Y.tycoon:FindFirstChild("Factory")
	local v = f and f:FindFirstChild("OwnerName")
	return v and v.Value or ""
end

local function cellCF(Y, it)
	local x = (it.col - (COLS - 1) / 2) * CELL
	local z = -Y.base.Size.Z / 2 + 14 + CELL / 2 + it.row * CELL
	return Y.base.CFrame * CFrame.new(x, Y.base.Size.Y / 2, z)
end

local function setStats(Y)
	local player = Players:FindFirstChild(Y.owner)
	if not player then return end
	local n, inc = 0, 0
	for i, it in ipairs(ITEMS) do if Y.bought[i] then n = n + 1 inc = inc + it.income end end
	local v = player:FindFirstChild("BackyardItems")
	if v then v.Value = n end
	v = player:FindFirstChild("BackyardIncome")
	if v then v.Value = inc end
end

local function rowOpen(Y, row)
	if row == 0 then return true end      -- the first row always shows (only the owner can buy)
	if Y.owner == "" then return false end
	local n = 0
	for i, it in ipairs(ITEMS) do if it.row == row - 1 and Y.bought[i] then n = n + 1 end end
	return n >= UNLOCK
end

local function refreshPads(Y)
	for i, it in ipairs(ITEMS) do
		local pad = Y.pads[i]
		if Y.bought[i] then
			pad.Parent = nil
		elseif rowOpen(Y, it.row) then
			pad.Parent = Y.padModel
		else
			pad.Parent = nil
		end
	end
end

local function build(Y, i)
	local it = ITEMS[i]
	local m = Instance.new("Model")
	m.Name = it[1]
	B.model = m
	B.o = cellCF(Y, it)
	B.spin, B.blink, B.bob = {}, {}, {}
	B.home = function() return Y.home end
	local ok, err = pcall(function() K[it[2]](it[3] or {}) end)
	if not ok then print("Backyard: building " .. it[1] .. " failed: " .. tostring(err)) end
	m.Parent = Y.items
	for _, s in ipairs(B.spin) do s.model = m table.insert(SPIN, s) end
	for _, t in ipairs(B.blink) do table.insert(BLINK, { model = m, tiles = t }) end
	for _, t in ipairs(B.bob) do
		local base = {}
		for k, p in ipairs(t) do base[k] = p.CFrame end
		table.insert(BOB, { model = m, parts = t, base = base })
	end
	return m
end

local function reset(Y)
	Y.bought = {}
	Y.items:ClearAllChildren()
	refreshPads(Y)
end

local function hint(player, text)
	pcall(function() remote:FireClient(player, "bought", text) end)
end

local function makePad(Y, i)
	local it = ITEMS[i]
	local pad = Instance.new("Part")
	pcall(function() pad.FormFactor = Enum.FormFactor.Custom end)
	pad.Name = "Buy " .. it[1]
	pad.Anchored = true
	pad.Size = Vector3.new(6, 0.4, 6)
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	-- gold, with a light and a beam above it, so pads stand out on the green grass
	pad.BrickColor = BrickColor.new(it.income >= it.price / 100 and "New Yeller" or "Bright yellow")
	pcall(function() pad.Material = Enum.Material.Neon end)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.new(1, 0.85, 0.2)
	glow.Range = 10
	glow.Parent = pad
	local beam = Instance.new("Part")
	pcall(function() beam.FormFactor = Enum.FormFactor.Custom end)
	beam.Name = "Beam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.Size = Vector3.new(0.6, 12, 0.6)
	beam.BrickColor = BrickColor.new("Bright yellow")
	pcall(function() beam.Material = Enum.Material.Neon end)
	beam.Transparency = 0.5
	beam.TopSurface = Enum.SurfaceType.Smooth
	beam.BottomSurface = Enum.SurfaceType.Smooth
	pad.CFrame = cellCF(Y, it) * CFrame.new(0, 0.2, 0)
	beam.CFrame = pad.CFrame * CFrame.new(0, 6.2, 0)
	beam.Parent = pad
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(10, 0, 3, 0)
	bb.StudsOffset = Vector3.new(0, 13.5, 0)   -- above the beam
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	t.Text = it[1] .. "\n" .. money(it.price) .. "  (+" .. money(it.income) .. "/s)"
	t.Parent = bb
	bb.Parent = pad
	local busy = false
	pad.Touched:connect(function(hit)
		if busy or Y.bought[i] then return end
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		if player.Name ~= Y.owner then
			if not busy then
				busy = true
				hint(player, Y.owner == "" and "Touch \"Become Owner\" at this mansion first!" or ("This is " .. Y.owner .. "'s backyard"))
				wait(2)
				busy = false
			end
			return
		end
		local ls = player:FindFirstChild("leaderstats")
		local cash = ls and ls:FindFirstChild("Cash")
		if not cash then return end
		busy = true
		if cash.Value >= it.price then
			cash.Value = cash.Value - it.price
			Y.bought[i] = true
			pad.Parent = nil
			build(Y, i)
			refreshPads(Y)
			setStats(Y)
			hint(player, "Bought " .. it[1] .. "! +" .. money(it.income) .. "/s")
		else
			hint(player, "Need " .. money(it.price - cash.Value) .. " more for " .. it[1])
		end
		wait(0.5)
		busy = false
	end)
	return pad
end

-- set up a backyard for every tycoon, including ones that finish loading after this script starts
-- (big places can still be loading when ServerScriptService runs)
local function setupYard(tycoon)
	if tycoon.Name ~= "tycoon" then return end
	for _, Y in ipairs(YARDS) do if Y.tycoon == tycoon then return end end
	local base = tycoon:FindFirstChild("BackyardBase")
	for _ = 1, 100 do
		if base then break end
		wait(0.3)
		base = tycoon:FindFirstChild("BackyardBase")
	end
	if not base then return end
	for _, Y in ipairs(YARDS) do if Y.tycoon == tycoon then return end end
	local Y = { tycoon = tycoon, base = base, bought = {}, pads = {}, owner = "" }
	table.insert(YARDS, Y)
	Y.padModel = Instance.new("Model", tycoon) Y.padModel.Name = "BackyardPads"
	Y.items = Instance.new("Model", tycoon) Y.items.Name = "BackyardItems"
	-- the mansion side: where the Become Owner button is (it disappears once someone owns the tycoon)
	local f = tycoon:FindFirstChild("Factory")
	local bo = f and f:FindFirstChild("Become Owner")
	local head = bo and bo:FindFirstChild("Head")
	Y.home = head and CFrame.new(head.CFrame.p) or base.CFrame
	Y.entrance = base.CFrame * CFrame.new(0, base.Size.Y / 2, -base.Size.Z / 2 + 6)
	for i = 1, #ITEMS do Y.pads[i] = makePad(Y, i) end
	refreshPads(Y)
end
for _, c in ipairs(workspace:GetChildren()) do spawn(function() setupYard(c) end) end
workspace.ChildAdded:connect(function(c) spawn(function() setupYard(c) end) end)
delay(15, function()
	if #YARDS == 0 then
		error("Backyard: found no tycoon with a BackyardBase after 15 seconds, so there are no backyards")
	end
	print("Backyard: " .. #YARDS .. " backyards set up")
end)

-- owners come and go (the tycoon resets when its owner leaves): reset the backyard with it
spawn(function()
	while true do
		for _, Y in ipairs(YARDS) do
			local o = ownerOf(Y)
			if o ~= Y.owner then
				Y.owner = o
				reset(Y)
				setStats(Y)
			end
		end
		wait(1)
	end
end)

-- money per second goes into the tycoon's "Cash to collect"
local function collector(Y)
	local f = Y.tycoon:FindFirstChild("Factory")
	if not f then return nil end
	for _, c in ipairs(f:GetChildren()) do
		local m = c:FindFirstChild("Money")
		if m and m:IsA("IntValue") then return m end
	end
	return nil
end
spawn(function()
	while true do
		wait(1)
		for _, Y in ipairs(YARDS) do
			if Y.owner ~= "" then
				local inc = 0
				for i, it in ipairs(ITEMS) do if Y.bought[i] then inc = inc + it.income end end
				if inc > 0 then
					local m = collector(Y)
					if m then
						m.Value = m.Value + inc
					else
						local p = Players:FindFirstChild(Y.owner)
						local cash = p and p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Cash")
						if cash then cash.Value = cash.Value + inc end
					end
				end
			end
		end
	end
end)

-- rides spin, disco floors blink, lava lamps bob
spawn(function()
	local start = tick()
	local cols = { "Bright red", "Bright blue", "Lime green", "Hot pink", "New Yeller", "Cyan" }
	local lastBlink = 0
	while true do
		local t = tick() - start
		for i = #SPIN, 1, -1 do
			local s = SPIN[i]
			if not s.model.Parent then table.remove(SPIN, i)
			else
				local a = math.rad(s.speed * t)
				local r = s.axis == "y" and CFrame.Angles(0, a, 0) or (s.axis == "z" and CFrame.Angles(0, 0, a) or CFrame.Angles(a, 0, 0))
				for k, p in ipairs(s.parts) do p.CFrame = s.center * r * s.rel[k] end
			end
		end
		for i = #BOB, 1, -1 do
			local b = BOB[i]
			if not b.model.Parent then table.remove(BOB, i)
			else
				for k, p in ipairs(b.parts) do p.CFrame = b.base[k] + Vector3.new(0, math.sin(t * 0.8 + k * 1.7) * 1.4, 0) end
			end
		end
		if t - lastBlink > 0.5 then
			lastBlink = t
			for i = #BLINK, 1, -1 do
				local b = BLINK[i]
				if not b.model.Parent then table.remove(BLINK, i)
				else for k, p in ipairs(b.tiles) do p.BrickColor = BrickColor.new(cols[math.random(1, #cols)]) end end
			end
		end
		wait(0.05)
	end
end)

------------------------------------------------------------------ players
local function setup(player)
	for _, n in ipairs({ "BackyardItems", "BackyardIncome" }) do
		if not player:FindFirstChild(n) then
			local v = Instance.new("IntValue")
			v.Name = n
			v.Parent = player
		end
	end
end
Players.PlayerAdded:connect(setup)
for _, p in ipairs(Players:GetPlayers()) do setup(p) end

remote.OnServerEvent:connect(function(player, what)
	if what ~= "tp" then return end
	local char = player.Character
	local t = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
	if not t then return end
	for _, Y in ipairs(YARDS) do
		if Y.owner == player.Name then
			local inYard = (t.CFrame.p - Y.base.CFrame.p).magnitude < Y.base.Size.Z * 0.75
			t.CFrame = (inYard and Y.home or Y.entrance) + Vector3.new(0, 4, 0)
			return
		end
	end
	pcall(function() remote:FireClient(player, "bought", "Own a mansion first (touch Become Owner)") end)
end)

print("Backyard script running: " .. #ITEMS .. " things to buy in each backyard")
