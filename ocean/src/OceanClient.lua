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
-- HOW TO PLAY: shown when you join (once)
local function panel(w, h)
	local f = frame(gui, UDim2.new(0.5, -w / 2, 0.5, -h / 2), UDim2.new(0, w, 0, h), C.dark, 0.08)
	f.ZIndex = 5
	return f
end
if not _G.OceanSeenHowTo then
	_G.OceanSeenHowTo = true
	local f = panel(620, 380)
	local title = label(f, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 44), "DISASTER OCEAN - HOW TO PLAY", 36, C.gold)
	title.ZIndex = 6
	local body = label(f, UDim2.new(0, 24, 0, 62), UDim2.new(1, -48, 0, 250),
		"1.  In the sky lobby, step on a glowing pad to vote for the next BOAT and the map THEME.\n\n" ..
		"2.  Everyone goes aboard. Huge waves rock the boat and disasters strike one after another.\n\n" ..
		"3.  Stay on the boat - the water hurts! Fell in? Press SPACE to leap back aboard.\n\n" ..
		"4.  Every disaster you live through: +40 Coins.  LAST ONE STANDING WINS: +1 Win, +150 Coins.\n\n" ..
		"5.  Joined late or died? Wait in the lobby, or play as a GHOST (ghosts don't count).", 20, C.white)
	body.TextWrapped = true
	pcall(function() body.TextXAlignment = Enum.TextXAlignment.Left body.TextYAlignment = Enum.TextYAlignment.Top end)
	body.ZIndex = 6
	local go = button(f, UDim2.new(0.5, -110, 1, -62), UDim2.new(0, 220, 0, 46), "LET'S GO!", C.green)
	go.ZIndex = 6
	go.MouseButton1Click:connect(function() f:Destroy() end)
end
-- a game is going on and you're not in it: wait for the next one, or play as a ghost
local ghostPanel = panel(560, 200)
ghostPanel.Visible = false
local gt = label(ghostPanel, UDim2.new(0, 10, 0, 12), UDim2.new(1, -20, 0, 80),
	"A game is going on right now!\nWait here in the lobby for the next one, or jump in as a GHOST:\nyou can play along, but you don't count to win.", 20, C.white)
gt.TextWrapped = true
gt.ZIndex = 6
local stayB = button(ghostPanel, UDim2.new(0, 30, 1, -70), UDim2.new(0, 230, 0, 50), "WAIT IN THE LOBBY", C.blue)
local ghostB = button(ghostPanel, UDim2.new(1, -260, 1, -70), UDim2.new(0, 230, 0, 50), "PLAY AS A GHOST", rgb(120, 90, 200))
stayB.ZIndex, ghostB.ZIndex = 6, 6
local ghostSmall = button(gui, UDim2.new(0.5, -110, 1, -70), UDim2.new(0, 220, 0, 40), "PLAY AS A GHOST", rgb(120, 90, 200))
ghostSmall.Visible = false
local function askGhost() pcall(function() remote:FireServer("ghost") end) ghostPanel.Visible = false ghostSmall.Visible = false end
ghostB.MouseButton1Click:connect(askGhost)
ghostSmall.MouseButton1Click:connect(askGhost)
stayB.MouseButton1Click:connect(function() ghostPanel.Visible = false ghostSmall.Visible = true end)
-- in the water: a hint, and jumping asks the server for a big leap back onto the boat
local swimming = false
local swimHint = label(gui, UDim2.new(0.5, -350, 0.62, 0), UDim2.new(0, 700, 0, 34), "", 24, C.gold)
local lastSwimJump = 0
local function swimJump()
	if swimming and tick() - lastSwimJump > 1.5 then
		lastSwimJump = tick()
		pcall(function() remote:FireServer("swimjump") end)
	end
end
pcall(function()
	game:GetService("UserInputService").InputBegan:connect(function(i)
		if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.ButtonA then swimJump() end
	end)
end)
spawn(function()     -- phones/tablets: the jump button sets Humanoid.Jump
	while true do
		wait(0.1)
		local h = player.Character and player.Character:FindFirstChild("Humanoid")
		if h and h.Jump then swimJump() end
	end
end)
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
local rainGen = 0
local function rain(on, hail)
	raining = on
	rainGen = rainGen + 1
	local gen = rainGen
	for _, d in ipairs(drops) do d:Destroy() end
	drops = {}
	if not on then return end
	spawn(function()
		local folder = Instance.new("Model")
		folder.Name = "Rain"
		folder.Parent = workspace.CurrentCamera
		for i = 1, 70 do
			local d = Instance.new("Part")
			d.Anchored = true
			d.CanCollide = false
			d.Size = hail and Vector3.new(0.8, 0.8, 0.8) or Vector3.new(0.2, 4, 0.2)
			d.BrickColor = BrickColor.new(hail and "Institutional white" or "Pastel light blue")
			d.Transparency = hail and 0.1 or 0.4
			d.Parent = folder
			table.insert(drops, d)
		end
		table.insert(drops, folder)
		local t = 0
		while raining and rainGen == gen do
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
		elseif a == "calm" then statusText.Text = "CALM... the next disaster comes in " .. b
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
	elseif what == "ghostOffer" then
		ghostPanel.Visible = a and true or false
		ghostSmall.Visible = false
	elseif what == "swim" then
		swimming = a
		swimHint.Text = a and "YOU'RE IN THE WATER! Press SPACE (jump) to leap back onto the boat!" or ""
	elseif what == "weather" then
		rain(a == "storm" or a == "hail", a == "hail")
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
			if cam then pcall(function() cam.CoordinateFrame = cam.CoordinateFrame * CFrame.Angles(math.random(-10, 10) / 2000, math.random(-10, 10) / 2000, 0) end) end
		end
	end
end)
------------------------------------------------------------------ the sea round the boat (only drawn here)
-- The swells are drawn on this computer from the SeaState values, with the same maths (SeaHeight, at the top) the
-- server uses to rock the boat: a few giant smooth rounded swells (one per wave), choppy little waves and foam riding
-- on them, spray, and the boat itself moved to sit on them.
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
		Normal = { lo = c3(0.05, 0.16, 0.36), mid = c3(0.09, 0.26, 0.5), hi = c3(0.2, 0.42, 0.68), foam = c3(0.93, 0.96, 1) },
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
	-- THE SWELLS: one giant smooth rounded shape per wave (a stretched sphere: an ellipse across the wave, 8000 studs
	-- long), so the sea is smooth rolling hills of water with no lines. They are exactly the surface SeaHeight
	-- describes, so the boat sits right on them. Each is a tiny part stretched by its mesh (cheap to move).
	local function blob(color, tr)
		local p = part(Vector3.new(4, 4, 4), color)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		p.Transparency = tr or 0
		p.CFrame = CFrame.new(0, -2000, 0)
		return p, mesh
	end
	local ridges = {}
	for i = 1, 9 do
		local p, mesh = blob("Steel blue")
		pcall(function() p.Material = Enum.Material.Glass end)
		p.Reflectance = 0.2
		table.insert(ridges, { part = p, mesh = mesh, col = -1 })
	end
	-- choppy little waves riding on the swells, and wispy white streaks of foam all over the water round the boat
	-- (in clumps of 5, all roughly the same way, like the foam on a stormy sea)
	local chops, foams = {}, {}
	for i = 1, 35 do
		local p, mesh = blob("Steel blue")
		local w, l = math.random(30, 70), math.random(40, 110)
		mesh.Scale = Vector3.new(w / 4, 7 / 4, l / 4)
		pcall(function() p.Material = Enum.Material.Glass end)
		p.Reflectance = 0.2
		table.insert(chops, { part = p, u = math.random(-900, 900), w = math.random(-700, 700), rot = math.random() * 6.3 })
	end
	for c = 1, 28 do
		local clump = { u = math.random(-330, 330), w = math.random(-330, 330), rot = math.random() * 6.3 }
		for i = 1, 5 do
			local p, mesh = blob("Institutional white", 0.2 + math.random() * 0.45)
			mesh.Scale = Vector3.new((0.8 + math.random() * 2.2) / 4, 0.4 / 4, math.random(14, 50) / 4)
			table.insert(foams, { part = p, clump = clump, du = math.random(-18, 18), dw = math.random(-18, 18), rot = clump.rot + (math.random() - 0.5) * 1.2 })
		end
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
	local air, yaw, frames, lastShipCF, pose = 0, 0, 0, nil, {}
	local function moveBoat(t, dt)
		frames = frames + 1
		if frames % 15 == 0 then      -- find the boat (and parts that arrived late); drop pieces that broke off
			local m = findShip()
			if m ~= model then
				tracked, model, welds, perPart, lastMove, lastShipCF, pose = {}, m, {}, false, nil, nil, {}
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
		local dy, pitch, roll = ShipPose(t, S, v.ShipLen.Value, v.ShipWid.Value, sink >= 0 and sink or nil, pose, dt)
		if air > 0.1 then
			local k = math.min(1, air / 10)
			pitch, roll = pitch + math.sin(t * 1.2) * 0.08 * k, roll + math.sin(t * 1.5) * 0.1 * k
		end
		local at, lv = v.ShipAt.Value, v.Level.Value
		local shipCF = ShipCFrame(at, lv, dy + air, pitch, roll, yaw)
		local move = shipCF * ShipCFrame(at, lv, 0, 0, 0, 0):inverse()
		-- carry YOU with the boat (like a moving platform): on a slow computer the deck could otherwise jump past your
		-- feet between two frames and you'd drop through it into the sea
		local me = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso"))
		if me and lastShipCF and not swimming then
			local l = lastShipCF:inverse() * me.Position
			if math.abs(l.X) < v.ShipWid.Value / 2 + 4 and math.abs(l.Z) < v.ShipLen.Value / 2 + 6 and l.Y > -4 and l.Y < 80 then
				pcall(function() me.CFrame = shipCF * lastShipCF:inverse() * me.CFrame end)
			end
		end
		lastShipCF = shipCF
		lastMove = move
		if perPart or not hull then
			for p, base in pairs(tracked) do p.CFrame = move * base end
		else
			hull.CFrame = move * tracked[hull]
		end
	end
	-- LIFE ROUND THE BOAT (only drawn here): seagulls circling, a whale leaping out of the waves now and then, white
	-- water bursting up when the bow crashes down into a wave, and a foaming wake behind the boat.
	local hidden = CFrame.new(0, -1000, 0)
	local gulls = {}
	for i = 1, 6 do
		table.insert(gulls, { body = part(Vector3.new(1, 0.7, 2), "Institutional white"), l = part(Vector3.new(3, 0.2, 1.1), "Light stone grey"),
			r = part(Vector3.new(3, 0.2, 1.1), "Light stone grey"), a = math.random() * 6.3, rad = math.random(50, 130), hgt = math.random(35, 70),
			sp = (math.random() < 0.5 and 1 or -1) * (0.25 + math.random() * 0.2) })
	end
	local drops = {}
	for i = 1, 28 do
		local r = 1.5 + math.random() * 2.5
		local d = { part = part(Vector3.new(r, r, r), "Institutional white"), life = 0 }
		d.part.Transparency = 1
		d.part.CFrame = hidden
		pcall(function() d.part.Shape = Enum.PartType.Ball end)
		table.insert(drops, d)
	end
	local nextDrop = 1
	local function splash(pos, n, power)
		for _ = 1, n do
			local d = drops[nextDrop]
			nextDrop = nextDrop % #drops + 1
			d.pos = pos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
			d.vel = Vector3.new(math.random(-10, 10) / 20 * power, power * (0.7 + math.random() * 0.6), math.random(-10, 10) / 20 * power)
			d.life = 1.6
		end
	end
	local whale = { body = part(Vector3.new(9, 7, 30), "Dark stone grey"), belly = part(Vector3.new(7, 2, 24), "Light stone grey"),
		tail = part(Vector3.new(14, 1.2, 5), "Dark stone grey"), t = -1, next = tick() + 15 }
	for _, p in ipairs({ whale.body, whale.belly, whale.tail }) do p.CFrame = hidden end
	local wake = {}
	for i = 1, 14 do table.insert(wake, { part = part(Vector3.new(6, 0.4, 12), "Institutional white"), u = i / 14 }) end
	local lastPitch, nextSlam = 0, 0
	local function life(t, dt, cx, cz, lv)
		local now = tick()
		local len = v.ShipLen.Value
		local dy, pitch = ShipPose(t, S, len, v.ShipWid.Value)
		local deckY = lv + dy + 10
		for _, g in ipairs(gulls) do
			g.a = g.a + g.sp * dt
			local x, z = cx + math.cos(g.a) * g.rad, cz + math.sin(g.a) * g.rad
			local y = deckY + g.hgt + math.sin(now * 0.7 + g.rad) * 6
			local cf = CFrame.new(Vector3.new(x, y, z), Vector3.new(x - math.sin(g.a) * g.sp, y, z + math.cos(g.a) * g.sp))
			local flap = math.sin(now * 9 + g.rad) * 0.5
			g.body.CFrame = cf
			g.l.CFrame = cf * CFrame.new(-0.4, 0, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-1.5, 0, 0)
			g.r.CFrame = cf * CFrame.new(0.4, 0, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(1.5, 0, 0)
		end
		-- the bow crashing down into a wave: a burst of white water
		if v.ShipSink.Value < 0 and (pitch - lastPitch) / math.max(dt, 0.01) < -0.03 and pitch < -0.04 and now > nextSlam then
			nextSlam = now + 2.5
			local bz = cz - len / 2
			splash(Vector3.new(cx, lv + SeaHeight(cx, bz, t, S), bz), 14, 40)
		end
		lastPitch = pitch
		-- a whale leaps out of the waves
		if whale.t < 0 and now > whale.next then
			local a = math.random() * 6.3
			local r = math.random(160, 320)
			whale.x, whale.z, whale.dir = cx + math.cos(a) * r, cz + math.sin(a) * r, a + math.pi / 2
			whale.t = 0
			splash(Vector3.new(whale.x, lv + SeaHeight(whale.x, whale.z, t, S), whale.z), 10, 35)
		end
		if whale.t >= 0 then
			whale.t = whale.t + dt
			local u = whale.t / 3.2
			local fx, fz = math.cos(whale.dir), math.sin(whale.dir)
			local x, z = whale.x + fx * (u - 0.5) * 70, whale.z + fz * (u - 0.5) * 70
			local water = lv + SeaHeight(x, z, t, S)
			local y = water - 10 + math.sin(math.min(1, u) * math.pi) * 45
			local cf = CFrame.new(Vector3.new(x, y, z), Vector3.new(x + fx, y + math.cos(math.min(1, u) * math.pi) * 1.4, z + fz))
			whale.body.CFrame = cf
			whale.belly.CFrame = cf * CFrame.new(0, -3.5, 0)
			whale.tail.CFrame = cf * CFrame.new(0, 1, 16) * CFrame.Angles(math.sin(now * 4) * 0.3, 0, 0)
			if u >= 1 then
				splash(Vector3.new(x, water, z), 18, 45)
				whale.t = -1
				whale.next = now + math.random(20, 40)
				for _, p in ipairs({ whale.body, whale.belly, whale.tail }) do p.CFrame = hidden end
			end
		end
		for _, d in ipairs(drops) do
			if d.life > 0 then
				d.life = d.life - dt
				d.vel = d.vel - Vector3.new(0, 60 * dt, 0)
				d.pos = d.pos + d.vel * dt
				if d.life > 0 then
					d.part.CFrame = CFrame.new(d.pos)
					d.part.Transparency = 0.15 + (1 - d.life / 1.6) * 0.8
				else
					d.part.Transparency = 1
					d.part.CFrame = hidden
				end
			end
		end
		-- spray blown off the tops of the waves round the boat
		if math.random() < dt * 4 then
			local x, z = cx + math.random(-250, 250), cz + math.random(-300, 300)
			local h = SeaHeight(x, z, t, S)
			if h > S.amp * 0.7 then splash(Vector3.new(x, lv + h, z), 4, 25) end
		end
		-- the wake: two lines of foam spreading out behind the stern
		local sailing = v.Sailing.Value
		for i, w in ipairs(wake) do
			w.u = w.u + dt * 0.12
			if w.u > 1 then w.u = w.u - 1 end
			local dist = 10 + w.u * 260
			local x, z = cx + (i % 2 == 0 and 1 or -1) * (6 + dist * 0.25), cz + len / 2 + dist
			w.part.CFrame = sailing and CFrame.new(x, lv + SeaHeight(x, z, t, S) + 0.5, z) or hidden
			w.part.Transparency = 0.2 + w.u * 0.75
		end
	end
	-- only the newest copy of this script runs (an old copy stops and takes its water with it)
	local RUN = {}
	_G.OceanClientRun = RUN
	local lastTheme, foamPal
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
			if pal ~= lastTheme then
				lastTheme = pal
				for _, r in ipairs(ridges) do r.col = -1 end
				for _, c in ipairs(chops) do paint(c.part, mix(pal.mid, pal.hi, 0.6)) end
				for _, f in ipairs(foams) do paint(f.part, pal.foam) end
			end
			local th = SeaDir(t)
			local dx, dz = math.sin(th), math.cos(th)
			local turn = CFrame.Angles(0, th, 0)
			-- the swells: a ridge on every crest within 2000 studs
			local c0 = SeaCrest(t, S)
			local n = math.ceil((-2000 - RIDGE_A - c0) / SEA_L)
			for i, r in ipairs(ridges) do
				local uc, A, a, b
				if i < #ridges then
					uc = c0 + (n + i - 1) * SEA_L
					A = CrestAmp(uc, t, S)
					a, b = RIDGE_A, math.max(1, RIDGE_B * A)
				elseif S.rogueA > 0 and S.rogueBump then       -- the tsunami
					uc, A = S.rogueZ + 30 * (t - S.rogueT), S.rogueA
					a, b = S.rogueLen * 1.5, S.rogueA * 1.5
				end
				if uc and math.abs(uc) < 2000 + a then
					r.part.CFrame = CFrame.new(cx + dx * uc, lv + A - b, cz + dz * uc) * turn
					r.mesh.Scale = Vector3.new(8000 / 4, 2 * b / 4, 2 * a / 4)
					local col = math.floor(math.min(1, A / math.max(1, S.amp * 1.6)) * 20 + 0.5)
					if col ~= r.col then
						r.col = col
						paint(r.part, mix(pal.lo, pal.hi, 0.35 + col / 20 * 0.5))
					end
				else
					r.part.CFrame = CFrame.new(0, -2000, 0)
				end
			end
			-- chop and foam drift along with the water, sitting on the swells
			local moved = {}
			local function onSea(list, speed, sink, lim)
				for _, f in ipairs(list) do
					local g = f.clump or f      -- foam streaks move with their clump
					if not moved[g] then
						moved[g] = true
						g.u = g.u + speed * dt * 2
						if g.u > lim then g.u = g.u - 2 * lim g.w = math.random(-lim, lim) end
					end
					local fu, fw = g.u + (f.du or 0), g.w + (f.dw or 0)
					local x, z = cx + dx * fu + dz * fw, cz + dz * fu - dx * fw
					local h = SeaHeight(x, z, t, S)
					local sl = (SeaHeight(x + dx * 10, z + dz * 10, t, S) - h) / 10
					f.part.CFrame = CFrame.new(x, lv + h - sink, z) * turn * CFrame.Angles(-math.atan(sl), 0, 0) * CFrame.Angles(0, f.rot, 0)
				end
			end
			onSea(chops, 10, 1.2, 900)
			onSea(foams, 14, -0.4, 330)
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
			pcall(life, t, dt * 2, cx, cz, lv)
		end
	end
end)
pcall(function() remote:FireServer("state") end)
