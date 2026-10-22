-- StarterGui.OceanClient: the round status bar, big announcements, the ship's health bar, messages, screen shake
-- when a wave hits, and the storm (rain and lightning flashes, drawn only on this computer).
-- 2016-safe: no AnchorPoint/TweenService, FontSize instead of TextSize.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do wait() player = Players.LocalPlayer end
local pg = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("OceanEvent")
local old = pg:FindFirstChild("OceanUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "OceanUI"

local function rgb(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local C = { dark = rgb(15, 25, 45), panel = rgb(25, 45, 75), white = rgb(255, 255, 255), gold = rgb(255, 210, 70),
	green = rgb(80, 210, 110), red = rgb(230, 70, 70), blue = rgb(60, 140, 240) }
local function frame(parent, pos, size, color, tr)
	local f = Instance.new("Frame")
	f.Position, f.Size = pos, size
	f.BackgroundColor3 = color or C.panel
	f.BackgroundTransparency = tr or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end
local function label(parent, pos, size, text, fs, color)
	local t = Instance.new("TextLabel")
	t.Position, t.Size = pos, size
	t.BackgroundTransparency = 1
	t.Text = text or ""
	t.TextColor3 = color or C.white
	t.TextStrokeTransparency = 0.4
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	pcall(function() t.FontSize = Enum.FontSize["Size" .. (fs or 18)] end)
	t.Parent = parent
	return t
end
local function button(parent, pos, size, text, color)
	local b = Instance.new("TextButton")
	b.Position, b.Size = pos, size
	b.BackgroundColor3 = color or C.blue
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = C.white
	pcall(function() b.Font = Enum.Font.SourceSansBold end)
	pcall(function() b.FontSize = Enum.FontSize.Size18 end)
	b.Parent = parent
	return b
end

-- status bar (top middle)
local bar = frame(gui, UDim2.new(0.5, -200, 0, 4), UDim2.new(0, 400, 0, 40), C.dark, 0.2)
local statusText = label(bar, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "DISASTER OCEAN", 24, C.gold)
-- big announcement
local big = label(gui, UDim2.new(0.5, -400, 0.25, 0), UDim2.new(0, 800, 0, 60), "", 48, C.red)
local sub = label(gui, UDim2.new(0.5, -400, 0.25, 60), UDim2.new(0, 800, 0, 30), "", 24, C.white)
-- toast
local toast = label(gui, UDim2.new(0.5, -300, 0, 82), UDim2.new(0, 600, 0, 28), "", 20, C.green)
local toastId = 0
local function showToast(text, color)
	toastId = toastId + 1
	local id = toastId
	toast.Text = text
	toast.TextColor3 = color == "red" and C.red or (color == "gold" and C.gold or C.green)
	delay(5, function() if toastId == id then toast.Text = "" end end)
end
-- the ship's health bar (top, under the status)
local shipBox = frame(gui, UDim2.new(0.5, -230, 0, 48), UDim2.new(0, 460, 0, 30), C.dark, 0.2)
shipBox.Visible = false
local hpBack = frame(shipBox, UDim2.new(0, 4, 0, 4), UDim2.new(1, -8, 1, -8), rgb(60, 20, 20))
local hpFill = frame(hpBack, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.green)
local hpText = label(shipBox, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "", 18, C.white)
hpText.ZIndex = 2
-- lightning flash
local flash = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.white, 1)
gui.Parent = pg

------------------------------------------------------------------ rain (only on this computer)
local raining = false
local drops = {}
local function rain(on)
	raining = on
	if not on then
		for _, d in ipairs(drops) do d:Destroy() end
		drops = {}
		return
	end
	spawn(function()
		local folder = Instance.new("Model")
		folder.Name = "Rain"
		folder.Parent = workspace.CurrentCamera
		for i = 1, 70 do
			local d = Instance.new("Part")
			d.Anchored = true
			d.CanCollide = false
			d.Size = Vector3.new(0.2, 4, 0.2)
			d.BrickColor = BrickColor.new("Pastel light blue")
			d.Transparency = 0.4
			d.Parent = folder
			table.insert(drops, d)
		end
		table.insert(drops, folder)
		local t = 0
		while raining do
			local dt = wait(0.05)
			t = t + dt
			local cam = workspace.CurrentCamera
			local c = cam and cam.CoordinateFrame.p or Vector3.new()
			for i, d in ipairs(drops) do
				if d:IsA("BasePart") then
					local x = ((i * 37) % 60) - 30
					local z = ((i * 53) % 60) - 30
					local y = 30 - ((t * 60 + i * 7) % 40)
					d.CFrame = CFrame.new(c.X + x, c.Y + y, c.Z + z) * CFrame.Angles(0.2, 0, 0.1)
				end
			end
		end
	end)
end

------------------------------------------------------------------ messages from the server
local survivorsText = label(gui, UDim2.new(0.5, -300, 0.4, 0), UDim2.new(0, 600, 0, 120), "", 24, C.green)
survivorsText.TextWrapped = true
local shaking = 0
remote.OnClientEvent:connect(function(what, a, b, c, d)
	if what == "status" then
		if a == "intermission" then statusText.Text = "INTERMISSION - the ship leaves in " .. b
		elseif a == "boarding" then statusText.Text = "ALL ABOARD!"
		elseif a == "disaster" then statusText.Text = c .. "  -  SURVIVE " .. b .. "s"
		else statusText.Text = "ROUND OVER - back to the island in " .. b end
	elseif what == "big" then
		big.Text = a
		sub.Text = b or ""
		survivorsText.Text = ""
		delay(6, function() if big.Text == a then big.Text = "" sub.Text = "" end end)
	elseif what == "survivors" then
		survivorsText.Text = (b and "THE SHIP SANK!\n" or "") .. (#a > 0 and ("SURVIVORS: " .. table.concat(a, ", ")) or "NOBODY SURVIVED!")
		delay(6, function() survivorsText.Text = "" end)
	elseif what == "toast" then
		showToast(a, b)
	elseif what == "toastTo" then
		if a == player.Name then showToast(b, "green") end
	elseif what == "ship" then
		shipBox.Visible = a ~= nil
		if a then
			local f = b > 0 and a / b or 0
			hpFill.Size = UDim2.new(math.max(0, math.min(1, f)), 0, 1, 0)
			hpFill.BackgroundColor3 = f > 0.5 and C.green or (f > 0.25 and C.gold or C.red)
			hpText.Text = c and ("THE " .. string.upper(d or "SHIP") .. " IS SINKING!") or (string.upper(d or "SHIP") .. "  " .. a .. " / " .. b)
		end
	elseif what == "shake" then
		shaking = math.max(shaking, a or 0.5)
	elseif what == "weather" then
		rain(a == "storm")
	elseif what == "flash" then
		spawn(function()
			flash.BackgroundTransparency = 0.3
			wait(0.08)
			flash.BackgroundTransparency = 0.7
			wait(0.08)
			flash.BackgroundTransparency = 1
		end)
	end
end)
-- camera shake when a wave hits the ship
spawn(function()
	while true do
		wait(0.03)
		if shaking > 0 then
			shaking = shaking - 0.03
			local cam = workspace.CurrentCamera
			if cam then pcall(function() cam.CoordinateFrame = cam.CoordinateFrame * CFrame.Angles(math.random(-10, 10) / 600, math.random(-10, 10) / 600, 0) end) end
		end
	end
end)
------------------------------------------------------------------ the sea round the boat (only drawn here)
-- The swells are drawn on this computer from the SeaState values, with the same maths (SeaHeight, at the top) the
-- server uses to rock the boat. The surface is a row of long strips across the boat's path (as wide as the whole
-- ocean). Every frame each strip is laid from the water height at its front edge to the height at its back edge, so
-- neighbouring strips meet exactly: one smooth, unbroken surface of rolling swells, no steps. Coloured by height: deep
-- blue in the troughs, lighter up the faces, and white foam only where a big wave's top is breaking.
spawn(function()
	local st = game:GetService("ReplicatedStorage"):WaitForChild("SeaState")
	local v = {}
	for _, n in ipairs({ "Amp", "Speed", "Level", "Clock", "ShipAt", "ShipLen", "ShipWid", "ShipAir", "ShipYaw", "ShipSink", "Sailing", "Theme",
		"RogueA", "RogueT", "RogueZ", "RogueLen", "RogueBump" }) do
		v[n] = st:WaitForChild(n)
	end
	local S = { shipX = 0, shipZ = 0, amp = 1, speed = 16, rogueA = 0, rogueT = 0, rogueZ = 0, rogueLen = 150, rogueBump = false }
	local function read()
		S.shipX, S.shipZ = v.ShipAt.Value.X, v.ShipAt.Value.Z
		S.amp, S.speed = v.Amp.Value, v.Speed.Value
		S.rogueA, S.rogueT, S.rogueZ, S.rogueLen, S.rogueBump = v.RogueA.Value, v.RogueT.Value, v.RogueZ.Value, math.max(1, v.RogueLen.Value), v.RogueBump.Value
	end
	read()
	for _, o in pairs(v) do o.Changed:connect(read) end
	-- the server's sea clock: jump to it when far off, otherwise slide to it gently (no jerks in the waves)
	local offset = v.Clock.Value - tick()
	local goalOffset = offset
	v.Clock.Changed:connect(function()
		goalOffset = v.Clock.Value - tick()
		if math.abs(goalOffset - offset) > 1 then offset = goalOffset end
	end)
	-- colours: trough -> middle (same as the flat ocean far away) -> top of a swell, and the foam
	local c3 = Color3.new
	local PAL = {
		Normal = { lo = c3(0.03, 0.12, 0.28), mid = c3(0.08, 0.25, 0.45), hi = c3(0.18, 0.45, 0.6), foam = c3(0.82, 0.9, 0.95) },
		Sunset = { lo = c3(0.05, 0.08, 0.2), mid = c3(0.12, 0.2, 0.38), hi = c3(0.25, 0.32, 0.52), foam = c3(0.9, 0.85, 0.82) },
		Halloween = { lo = c3(0.01, 0.03, 0.03), mid = c3(0.03, 0.1, 0.08), hi = c3(0.06, 0.28, 0.2), foam = c3(0.35, 0.9, 0.4) },
	}
	local function mix(a, b, u) return c3(a.r + (b.r - a.r) * u, a.g + (b.g - a.g) * u, a.b + (b.b - a.b) * u) end
	local useColor = pcall(function() local p = Instance.new("Part") p.Color = c3(0, 0, 1) end)
	local folder = Instance.new("Model")
	folder.Name = "SeaFX"
	folder.Parent = workspace.CurrentCamera
	local function part(size, color)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		pcall(function() p.FormFactor = Enum.FormFactor.Custom end)
		p.Size = size
		p.BrickColor = BrickColor.new(color)
		pcall(function() p.Material = Enum.Material.SmoothPlastic end)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = folder
		return p
	end
	local function paint(p, c)
		if useColor then p.Color = c else p.BrickColor = BrickColor.new(c) end
	end
	-- the strips: 10 studs deep near the boat, 25 further out, 80 far away (in the fog). They turn with the direction
	-- the waves come from (SeaDir), always lying across it.
	local WIDTH, THICK = 4000, 4
	local ZS = { -2000 }
	while ZS[#ZS] < 2000 do
		local z = ZS[#ZS]
		local a = math.abs(z + 1)
		table.insert(ZS, z + (a < 220 and 10 or a < 700 and 25 or 80))
	end
	local strips = {}
	for k = 1, #ZS - 1 do table.insert(strips, { part = part(Vector3.new(WIDTH, THICK, ZS[k + 1] - ZS[k]), "Steel blue"), col = -1, len = 0, far = ZS[k + 1] - ZS[k] > 50 }) end
	local H = {}
	-- bits of foam floating on the swells, streaming past the boat
	local foams = {}
	for i = 1, 20 do
		table.insert(foams, { part = part(Vector3.new(math.random(4, 10), 0.4, math.random(8, 20)), "Institutional white"), x = math.random(-250, 250), z = math.random(-450, 450) })
	end
	-- spray where the bow cuts into the waves
	local spray = {}
	for i = 1, 10 do
		local s = { part = part(Vector3.new(2, 2, 2), "Institutional white"), t = math.random() }
		s.part.Transparency = 0.5
		pcall(function() s.part.Shape = Enum.PartType.Ball end)
		table.insert(spray, s)
	end
	-- THE BOAT: every part of it is moved here, together, every frame, to sit on the waves drawn above (ShipPose, the
	-- same maths the server uses). The server only sends the extras: tornado lift and spin, sinking. Where each part
	-- was built is remembered once for this whole computer (_G), so a restarted copy of this script (after you
	-- respawn) can't pick up a part that was already tilted.
	local bases = _G.OceanShipBases or setmetatable({}, { __mode = "k" })
	_G.OceanShipBases = bases
	local world = workspace:WaitForChild("Ocean World")
	-- To keep it light, every part is welded (on this computer only) to the hull, so moving the hull moves the whole
	-- boat in one go. If welds don't carry the parts on this computer, it falls back to moving each part itself.
	local tracked, model, hull, welds, perPart, lastMove = {}, nil, nil, {}, false, nil
	local function add(p)
		if p:IsA("BasePart") and not tracked[p] then
			if not bases[p] then bases[p] = p.CFrame end
			tracked[p] = bases[p]
			if hull and p ~= hull and not perPart then
				pcall(function()
					if lastMove then p.CFrame = lastMove * bases[p] end
					local w = Instance.new("Weld")
					w.Part0, w.Part1 = hull, p
					w.C0 = bases[hull]:inverse() * bases[p]
					w.Parent = hull
					welds[p] = w
					p.Anchored = false
				end)
			end
		end
	end
	local function unweld(p)
		if welds[p] then pcall(function() welds[p]:Destroy() end) welds[p] = nil end
	end
	local function all(o) for _, c in ipairs(o:GetChildren()) do add(c) all(c) end end
	local function findShip()
		for _, c in ipairs(world:GetChildren()) do if c:FindFirstChild("IsShip") then return c end end
	end
	local air, yaw, frames = 0, 0, 0
	local function moveBoat(t, dt)
		frames = frames + 1
		if frames % 15 == 0 then      -- find the boat (and parts that arrived late); drop pieces that broke off
			local m = findShip()
			if m ~= model then
				tracked, model, welds, perPart, lastMove = {}, m, {}, false, nil
				hull = m and m:FindFirstChild("Hull")
				if hull then
					if not bases[hull] then bases[hull] = hull.CFrame end
					tracked[hull] = bases[hull]
				end
			end
			if m then
				-- check the welds really carry the boat here (a welded part must be where the last move put it)
				if not perPart and lastMove then
					for p, w in pairs(welds) do
						if p.Parent and ((lastMove * tracked[p]).p - p.Position).magnitude > 1 then
							perPart = true
							for q in pairs(welds) do pcall(function() q.Anchored = true end) unweld(q) end
						end
						break
					end
				end
				all(m)
				for p in pairs(tracked) do
					if not p:IsDescendantOf(m) then unweld(p) tracked[p] = nil end   -- broke off / lifeboat dropped
				end
			end
		end
		if not model then return end
		air = air + (v.ShipAir.Value - air) * math.min(1, dt * 8)
		yaw = yaw + (v.ShipYaw.Value - yaw) * math.min(1, dt * 8)
		local sink = v.ShipSink.Value
		local dy, pitch, roll = ShipPose(t, S, v.ShipLen.Value, v.ShipWid.Value, sink >= 0 and sink or nil)
		if air > 0.1 then
			local k = math.min(1, air / 10)
			pitch, roll = pitch + math.sin(t * 2) * 0.15 * k, roll + math.sin(t * 2.6) * 0.2 * k
		end
		local at, lv = v.ShipAt.Value, v.Level.Value
		local move = ShipCFrame(at, lv, dy + air, pitch, roll, yaw) * ShipCFrame(at, lv, 0, 0, 0, 0):inverse()
		lastMove = move
		if perPart or not hull then
			for p, base in pairs(tracked) do p.CFrame = move * base end
		else
			hull.CFrame = move * tracked[hull]
		end
	end
	-- only the newest copy of this script runs (an old copy stops and takes its water with it)
	local RUN = {}
	_G.OceanClientRun = RUN
	local lastTheme
	local last = tick()
	local tick2 = 0
	while true do
		wait(0.03)
		tick2 = tick2 + 1
		local now = tick()
		local dt = math.min(0.2, now - last)
		last = now
		if _G.OceanClientRun ~= RUN then pcall(function() folder:Destroy() end) return end
		offset = offset + (goalOffset - offset) * math.min(1, dt * 0.5)
		pcall(moveBoat, now + offset, dt)
		local cx, cz = S.shipX, S.shipZ
		local lv = v.Level.Value - 0.6     -- the top of the flat ocean
		local cam = workspace.CurrentCamera
		local near = cam and (cam.CoordinateFrame.p - Vector3.new(cx, lv, cz)).magnitude < 1600
		if folder.Parent ~= (near and cam or nil) then folder.Parent = near and cam or nil end
		if near and tick2 % 2 == 0 then
			local t = now + offset
			local pal = PAL[v.Theme.Value] or PAL.Normal
			if pal ~= lastTheme then lastTheme = pal for _, s in ipairs(strips) do s.col = -1 end end
			local norm = 1 / math.max(1, S.amp * 1.3)
			local th = SeaDir(t)
			local dx, dz = math.sin(th), math.cos(th)
			local turn = CFrame.Angles(0, th, 0)
			for k = 1, #ZS do H[k] = SeaHeight(cx + dx * ZS[k], cz + dz * ZS[k], t, S) end
			local odd = tick2 % 4 == 0
			for k, s in ipairs(strips) do
			if not s.far or odd then
				local a, b = H[k], H[k + 1]
				local dz, dh = ZS[k + 1] - ZS[k], b - a
				local len = math.sqrt(dz * dz + dh * dh)
				-- from (front edge, height a) to (back edge, height b): the top face runs exactly between them
				if math.abs(len - s.len) > 0.3 then
					s.len = len
					s.part.Size = Vector3.new(WIDTH, THICK, len + 0.4)
				end
				local um = (ZS[k] + ZS[k + 1]) / 2
				s.part.CFrame = CFrame.new(cx + dx * um, lv + (a + b) / 2, cz + dz * um) * turn
					* CFrame.Angles(-math.atan2(dh, dz), 0, 0) * CFrame.new(0, -THICK / 2, 0)
				-- colour: 8 shades from trough to top, foam where a big wave's steep front is breaking
				local r = math.max(-1, math.min(1, (a + b) / 2 * norm))
				local col = math.floor((r + 1) * 4 + 0.5)
				if r > 0.7 and dh / dz < -0.18 then col = 99 end
				if col ~= s.col then
					s.col = col
					local u = col / 8
					paint(s.part, col == 99 and pal.foam or (u < 0.5 and mix(pal.lo, pal.mid, u * 2) or mix(pal.mid, pal.hi, u * 2 - 1)))
				end
			end
			end
			for _, f in ipairs(foams) do
				f.z = f.z + S.speed * 1.3 * dt
				if f.z > 450 then f.z = f.z - 900 f.x = math.random(-250, 250) end
				local x, z = cx + f.x, cz + f.z
				local h = SeaHeight(x, z, t, S)
				local sl = (SeaHeight(x, z + 6, t, S) - h) / 6
				f.part.CFrame = CFrame.new(x, lv + h + 0.5, z) * CFrame.Angles(-math.atan(sl), 0, 0)
			end
			local bowZ = cz - v.ShipLen.Value / 2 - 5
			local bowH = SeaHeight(cx, bowZ, t, S)
			local moving = v.Sailing.Value
			for i, s in ipairs(spray) do
				s.t = s.t + dt * 0.8
				if s.t > 1 then s.t = s.t - 1 end
				local side = i % 2 == 0 and 1 or -1
				local u = s.t
				s.part.CFrame = CFrame.new(cx + side * (4 + u * 16), lv + bowH + 2 + math.sin(u * math.pi) * (3 + S.amp), bowZ + u * 25)
				s.part.Transparency = moving and (0.35 + u * 0.6) or 1
			end
		end
	end
end)
pcall(function() remote:FireServer("state") end)
