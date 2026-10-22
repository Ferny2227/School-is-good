-- ServerScriptService.OceanServer (built from ocean/src/server/o*.lua, joined in file-name order)
-- DISASTER OCEAN (2016 edition), Natural Disaster Survival style:
--  * the lobby is a house floating high in the sky. Inside you vote for the BOAT (Cruise Liner, Pirate Galleon,
--    Navy Destroyer) and the THEME of the whole map (Normal, Sunset, Halloween).
--  * every round the whole lobby goes aboard the winning boat, out on the open ocean. Huge swells roll in from ahead
--    one after another (each one lifts the bow, then the middle, then the stern, so the boat rocks with every wave),
--    and every so often a set of even bigger ones rolls through. The boats have real rooms.
--  * plus a disaster every round: Tsunami (one giant swell), Tornado (lifts the boat out of the sea and drops it),
--    Hurricane (even bigger seas), Meteor Shower, Kraken, Sharks.
--  * the boat has a health bar; pieces break off; at 0 it sinks and its lifeboats drop. The water hurts.
-- Written for 2016 Roblox: lowercase :connect, ypcall, no TweenService / GetDescendants (U.desc instead).
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local V = Vector3.new

------------------------------------------------------------------ clear the old map, make the remote
pcall(function() workspace:FindFirstChild("AirportMap"):Destroy() end)
pcall(function() workspace.Terrain:Clear() end)
local remote = RS:FindFirstChild("OceanEvent") or Instance.new("RemoteEvent")
remote.Name = "OceanEvent"
remote.Parent = RS
local function toClient(p, ...) local a = { ... } pcall(function() remote:FireClient(p, unpack(a)) end) end
local function toAll(...) local a = { ... } pcall(function() remote:FireAllClients(unpack(a)) end) end

------------------------------------------------------------------ helpers
local U = {}
-- all descendants (GetDescendants doesn't exist in every 2016 engine)
function U.desc(o, out)
	out = out or {}
	for _, c in ipairs(o:GetChildren()) do
		table.insert(out, c)
		U.desc(c, out)
	end
	return out
end
local function P(parent, name, size, cf, color, mat, opt)
	opt = opt or {}
	local p = Instance.new(opt.class or "Part")
	p.Name = name
	p.Anchored = opt.anchored ~= false
	pcall(function() p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth end)
	if opt.shape == "ball" then p.Shape = Enum.PartType.Ball elseif opt.shape == "cyl" then p.Shape = Enum.PartType.Cylinder end
	p.Size = size
	p.BrickColor = BrickColor.new(color or "Medium stone grey")
	if mat then pcall(function() p.Material = Enum.Material[mat] end) end
	if opt.tr then p.Transparency = opt.tr end
	if opt.nc then p.CanCollide = false end
	p.CFrame = cf
	p.Parent = parent
	return p
end
local function blk(parent, name, sx, sy, sz, x, y0, z, color, mat, opt, ry)
	return P(parent, name, V(sx, sy, sz), CFrame.new(x, y0 + sy / 2, z) * CFrame.Angles(0, math.rad(ry or 0), 0), color, mat, opt)
end
local function cyl(parent, name, d, h, x, y0, z, color, mat, opt)
	opt = opt or {}
	opt.shape = "cyl"
	return P(parent, name, V(h, d, d), CFrame.new(x, y0 + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), color, mat, opt)
end
local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
local function weld(a, b)
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = a, b
	w.C0 = a.CFrame:inverse() * b.CFrame
	w.Parent = a
	return w
end
local function bill(part, text, w, h, up, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(w, 0, h, 0)
	bb.StudsOffset = V(0, up, 0)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	t.Parent = bb
	bb.Parent = part
	return t
end
local function sign(part, text, face, color, bg)
	local sg = Instance.new("SurfaceGui")
	pcall(function() sg.Face = Enum.NormalId[face or "Front"] end)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = bg and 0 or 1
	if bg then t.BackgroundColor3 = bg end
	t.TextScaled = true
	t.TextWrapped = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	t.Parent = sg
	sg.Parent = part
	return t
end
local function light(part, color, range, bright)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range or 16
	l.Brightness = bright or 1.5
	l.Parent = part
	return l
end
local function torsoOf(c) return c and (c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart")) end
local function clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end
local function pick(t) return t[math.random(1, #t)] end

local WORLD = model(workspace, "Ocean World")
local SEA = { level = 0, base = 0, waves = 1, amp = 1, speed = 16, calm = 1 }
