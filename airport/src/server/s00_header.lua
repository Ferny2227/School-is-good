-- ServerScriptService.AirportServer  (built from airport/src/server/*.lua by airport/tools/build.py)
-- Airport Tycoon: 10 airports to claim, 100+ things to buy in each, staff to hire, passengers who walk
-- through your airport, pay and leave reviews, an inspector, NPC airliners, and planes you can fly.
-- Written for 2016 Roblox engines: lowercase :connect, ypcall, no TweenService/typeof/AnchorPoint,
-- FormFactor Custom on new parts, BodyGyro/BodyVelocity with lowercase property names.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

--#CATALOG

local MAP = workspace:WaitForChild("AirportMap")
local G = { plots = {}, byPlayer = {}, walkers = {}, movers = {}, spinners = {}, flyers = {}, saved = {}, pitch = {}, ctl = {} }
local U = {}     -- small helpers
local M = {}     -- models: people, airliners, flyable planes
local K = {}     -- item builders (one per catalog "kind")
local A = {}     -- airport logic
local NPC = {}   -- passengers, staff, inspector
local FLY = {}   -- planes

------------------------------------------------------------------ helpers
function U.money(n)
	n = math.floor(n or 0)
	local s = tostring(math.abs(n))
	local out = ""
	while #s > 3 do out = "," .. s:sub(-3) .. out s = s:sub(1, -4) end
	return (n < 0 and "-$" or "$") .. s .. out
end

function U.L(x, y, z, ry, rx, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

function U.newPart(class)
	local p = Instance.new(class or "Part")
	pcall(function() p.FormFactor = Enum.FormFactor.Custom end)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- b = { model = parent, cf = CFrame everything is relative to }
function U.P(b, name, size, lcf, color, mat, opt)
	opt = opt or {}
	local p = U.newPart(opt.class)
	p.Name = name
	p.Anchored = true
	if opt.shape == "ball" then p.Shape = Enum.PartType.Ball
	elseif opt.shape == "cyl" then p.Shape = Enum.PartType.Cylinder end
	p.Size = size
	p.BrickColor = BrickColor.new(color or "Medium stone grey")
	if mat then pcall(function() p.Material = Enum.Material[mat] end) end
	if opt.tr then p.Transparency = opt.tr end
	if opt.refl then p.Reflectance = opt.refl end
	if opt.nc then p.CanCollide = false end
	p.CFrame = b.cf * lcf
	p.Parent = b.model
	return p
end
-- a box standing on y0 (bottom), centred on x, z
function U.blk(b, name, sx, sy, sz, x, y0, z, color, mat, opt, ry)
	return U.P(b, name, Vector3.new(sx, sy, sz), U.L(x, y0 + sy / 2, z, ry), color, mat, opt)
end
-- vertical cylinder standing on y0
function U.cyl(b, name, d, h, x, y0, z, color, mat, opt)
	opt = opt or {}
	opt.shape = "cyl"
	return U.P(b, name, Vector3.new(h, d, d), U.L(x, y0 + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), color, mat, opt)
end
function U.ball(b, name, d, x, y, z, color, mat, opt)
	opt = opt or {}
	opt.shape = "ball"
	return U.P(b, name, Vector3.new(d, d, d), U.L(x, y, z), color, mat, opt)
end
function U.seat(b, x, y0, z, ry, color, w)
	return U.P(b, "Seat", Vector3.new(w or 2, 1, 2), U.L(x, y0 + 0.5, z, ry), color or "Bright blue", "Fabric", { class = "Seat" })
end
function U.light(p, color, range, bright)
	local l = Instance.new("PointLight")
	l.Color = color or Color3.new(1, 0.95, 0.8)
	l.Range = range or 16
	l.Brightness = bright or 1.5
	l.Parent = p
	return l
end
function U.fx(p, kind)
	local e = Instance.new(kind)
	e.Parent = p
	return e
end
-- text on a face of a part
function U.text(p, text, color, bg, face, font)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Text"
	pcall(function() sg.Face = Enum.NormalId[face or "Front"] end)
	local w, h = p.Size.X, p.Size.Y
	if face == "Top" or face == "Bottom" then h = p.Size.Z end
	if face == "Left" or face == "Right" then w = p.Size.Z end
	pcall(function() sg.CanvasSize = Vector2.new(math.max(50, w * 25), math.max(20, h * 25)) end)
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = bg and 0 or 1
	if bg then t.BackgroundColor3 = bg end
	t.BorderSizePixel = 0
	t.TextScaled = true
	t.TextWrapped = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	-- font = a name ("Code"): fonts that a 2016 engine doesn't have fall back to SourceSansBold
	if not pcall(function() t.Font = Enum.Font[font or "SourceSansBold"] end) then pcall(function() t.Font = Enum.Font.SourceSansBold end) end
	t.Parent = sg
	sg.Parent = p
	return t
end
-- floating label (sized in studs so it shrinks with distance)
function U.bill(p, text, w, h, up, color)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = UDim2.new(w or 10, 0, h or 2.5, 0)
	bb.StudsOffset = Vector3.new(0, up or 3, 0)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.TextScaled = true
	t.TextWrapped = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	t.Parent = bb
	bb.Parent = p
	return t
end
function U.weld(root, p)
	local w = Instance.new("Weld")
	w.Part0 = root
	w.Part1 = p
	w.C0 = root.CFrame:inverse() * p.CFrame
	w.Parent = root
	return w
end
-- make a model move as one piece by setting root.CFrame: root anchored, everything else welded to it
------------------------------------------------------------------ moving NPC models (people, airliners, small planes)
-- 2016 clients don't carry welded parts along when the server moves an anchored part, so moving models work like
-- this: the model itself (every part anchored) waits in ReplicatedStorage.AirportNPCModels, and the server moves
-- one invisible anchored marker with the same name in workspace.AirportMovers. Every client (the AirportNPCs
-- LocalScript) keeps its own copy of the model in its camera and puts it on the marker every frame.
local function plainFolder(name, parent)
	local f
	pcall(function() f = Instance.new("Folder") end)
	f = f or Instance.new("Model")
	f.Name = name
	f.Parent = parent
	return f
end
G.npcModels = plainFolder("AirportNPCModels", RS)
G.npcMarks = plainFolder("AirportMovers", workspace)
G.moverOf = {}
local moverCount = 0
-- model: built around CFrame `origin` (not parented yet). Returns the marker: set marker.CFrame to move the model.
function U.mover(model, origin, plot)
	moverCount = moverCount + 1
	local key = "NPC" .. moverCount
	local o = Instance.new("CFrameValue")
	o.Name = "Origin"
	o.Value = origin
	o.Parent = model
	local title = Instance.new("StringValue")
	title.Name = "Title"
	title.Value = model.Name
	title.Parent = model
	model.Name = key
	model.Parent = G.npcModels
	local mark = U.newPart()
	mark.Name = key
	mark.Anchored = true
	mark.CanCollide = false
	mark.Transparency = 1
	mark.Size = Vector3.new(1, 1, 1)
	mark.CFrame = origin
	mark.Parent = G.npcMarks
	G.moverOf[mark] = { model = model, plot = plot }
	if plot then plot.movers[mark] = true end
	return mark
end
function U.unmover(mark)
	local m = G.moverOf[mark]
	G.moverOf[mark] = nil
	if m and m.plot then m.plot.movers[mark] = nil end
	pcall(function() mark:Destroy() end)
	if m then pcall(function() m.model:Destroy() end) end
end
function U.spin(parts, center, axis, speed)
	local rel = {}
	for i, p in ipairs(parts) do rel[i] = center:inverse() * p.CFrame end
	table.insert(G.spinners, { parts = parts, rel = rel, center = center, axis = axis, speed = speed })
end
function U.pick(t) return t[math.random(1, #t)] end
function U.clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end

local CATNAME = { checkin = "Check-in", security = "Security", food = "Food", shopping = "Shopping",
	comfort = "Comfort", clean = "Cleanliness", gates = "Flights" }
local ITEM = {}       -- key -> catalog item
for i, it in ipairs(CATALOG) do it.index = i ITEM[it.key] = it end
local ROLE = {}
for _, st in ipairs(STAFF) do ROLE[st.key] = st end
