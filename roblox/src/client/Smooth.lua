
------------------------------------------------------------------ smooth NPCs (runs on each player's own computer)
-- The server doesn't send every step of every person any more (that was thousands of messages a second and made the
-- game lag). Each person has a "Move" value: "fromX fromY fromZ toX toY toZ speed" = where they are walking to next.
-- This computer walks them there smoothly every frame and swings their arms and legs. "R" means the server is moving
-- them itself (riding an elevator). People far from the camera are updated less often, and only near ones swing
-- their limbs, so slow computers (Chromebooks) keep a good frame rate.
pcall(function()
	local RunService = game:GetService("RunService")
	local V = Vector3.new
	local LIMBS = { ["Left Leg"] = { -0.5, -1, 1 }, ["Right Leg"] = { 0.5, -1, -1 }, ["Left Arm"] = { -1.5, 0.5, -0.8 }, ["Right Arm"] = { 1.5, 0.5, 0.8 } }
	local people = {}
	local function pose(st, a)
		for _, l in ipairs(st.limbs) do
			l.weld.C0 = CFrame.new(l.x, l.y, 0) * CFrame.Angles(a * l.k, 0, 0) * CFrame.new(0, l.y < 0 and -1 or -0.5, 0)
		end
	end
	local function parse(st, text)
		if text == "R" then st.server = true return end
		local n = {}
		for x in string.gmatch(text or "", "[%-%d%.]+") do n[#n + 1] = tonumber(x) end
		if #n < 7 then return end
		local from, to = V(n[1], n[2], n[3]), V(n[4], n[5], n[6])
		if st.server or not st.pos or (from - st.pos).magnitude > 8 then
			st.pos = from   -- just joined, back from the elevator, or too far behind: start where the server says
			st.queue = {}
		end
		st.server = false
		table.insert(st.queue, { p = to, v = n[7] })
		while #st.queue > 3 do table.remove(st.queue, 1) end
	end
	local function add(v)
		local model = v.Parent
		if not model or people[model] then return end
		local root = model:FindFirstChild("Root")
		if not root then return end
		local st = { model = model, root = root, queue = {}, face = root.CFrame.lookVector, ph = math.random() * 6, limbs = {}, acc = 0 }
		st.pos = root.Position - V(0, 3, 0)
		for _, w in ipairs(root:GetChildren()) do
			local d = w:IsA("Weld") and w.Part1 and LIMBS[w.Part1.Name]
			if d then table.insert(st.limbs, { weld = w, x = d[1], y = d[2], k = d[3] }) end
		end
		people[model] = st
		parse(st, v.Value)
		v.Changed:connect(function() parse(st, v.Value) end)
	end
	local function look(o)
		if o.Name == "Move" and o:IsA("StringValue") then
			-- the person's parts arrive just after the value: give them a moment
			delay(0.5, function() pcall(add, o) end)
		end
	end
	for _, o in ipairs(workspace:GetDescendants()) do look(o) end
	workspace.DescendantAdded:connect(look)

	local last = tick()
	RunService.RenderStepped:connect(function()
		local now = tick()
		local dt = math.min(0.25, now - last)
		last = now
		local cam = workspace.CurrentCamera
		local eye = cam and cam.CoordinateFrame.p or V()
		for model, st in pairs(people) do
			if not model.Parent or not st.root.Parent then
				people[model] = nil
			elseif not st.server then
				st.acc = st.acc + dt
				local dist = (st.pos - eye).magnitude
				local every = dist < 180 and 0 or (dist < 500 and 0.1 or (dist < 1200 and 0.4 or 1.5))
				if st.acc >= every then
					local step = st.acc
					st.acc = 0
					local moved = false
					local tgt = st.queue[1]
					while tgt and step > 0 do
						local d = tgt.p - st.pos
						local len = d.magnitude
						local go = tgt.v * step * (#st.queue > 1 and 1.3 or 1)   -- a little faster to catch up
						if len <= go then
							st.pos = tgt.p
							table.remove(st.queue, 1)
							step = (go - len) / math.max(0.1, tgt.v)
							tgt = st.queue[1]
						else
							st.pos = st.pos + d.unit * go
							step = 0
						end
						local flat = V(d.x, 0, d.z)
						if flat.magnitude > 0.05 then st.face = flat.unit end
						moved = true
					end
					local near = dist < 180
					local bob = (moved and near) and math.abs(math.sin(now * 8 + st.ph)) * 0.15 or 0
					local p = st.pos + V(0, 3 + bob, 0)
					st.root.CFrame = CFrame.new(p, p + st.face)
					if moved and near then
						pose(st, math.sin(now * 8 + st.ph) * 0.7)
						st.posed = true
					elseif st.posed then
						pose(st, 0)
						st.posed = false
					end
				end
			end
		end
	end)
end)

------------------------------------------------------------------ low graphics (on by default: the game is played on Chromebooks)
-- Only on this computer: lights and sparkles are switched off, no shadows or outlines. (Nothing the server owns is
-- ever moved or removed here: in old Roblox that can stop the server's updates reaching it, which froze the rides.)
-- The GRAPHICS button (bottom left) switches between LOW and HIGH.
pcall(function()
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local Lighting = game:GetService("Lighting")
	local low = true
	local FX = { PointLight = true, SpotLight = true, SurfaceLight = true, Sparkles = true, Fire = true, Smoke = true, ParticleEmitter = true }
	local function fx(o, on)
		if FX[o.ClassName] then pcall(function() o.Enabled = on end) end
	end
	local function setLow(v)
		low = v
		pcall(function() Lighting.GlobalShadows = not v end)
		pcall(function() Lighting.Outlines = not v end)
		for _, o in ipairs(workspace:GetDescendants()) do fx(o, not v) end
	end
	workspace.DescendantAdded:connect(function(o) if low then fx(o, false) end end)
	setLow(true)
	-- the button
	local sg = pg:FindFirstChild("AirportUI")
	if sg then
		local b = Instance.new("TextButton")
		b.Name = "Graphics"
		b.Size = UDim2.new(0, 150, 0, 26)
		b.Position = UDim2.new(0, 8, 1, -34)
		b.BackgroundColor3 = Color3.new(0.1, 0.13, 0.2)
		b.BorderSizePixel = 0
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = "GRAPHICS: LOW"
		pcall(function() b.Font = Enum.Font.SourceSansBold end)
		pcall(function() b.FontSize = Enum.FontSize.Size14 end)
		b.MouseButton1Click:connect(function()
			setLow(not low)
			b.Text = low and "GRAPHICS: LOW" or "GRAPHICS: HIGH"
		end)
		b.Parent = sg
	end
end)

------------------------------------------------------------------ Ghost Manor: floating ghosts and a spider on a thread (only drawn here)
spawn(function()
	local RunService = game:GetService("RunService")
	-- (keep looking until the park has arrived)
	local manor
	while not manor do
		local island = workspace:FindFirstChild("Paradise Island")
		local park = island and island:FindFirstChild("Paradise Park")
		manor = park and park:FindFirstChild("Ghost Manor")
		if not manor then wait(5) end
	end
	wait(1)
	local floor = manor:FindFirstChild("Floor")
	local centre = floor and floor.Position or Vector3.new(330, 6, 2420)
	local float = {}
	for _, p in ipairs(manor:GetChildren()) do
		local i = tonumber(p.Name:match("^Ghost(%d+)$") or p.Name:match("^GhostEye(%d+)$") or "")
		if i then table.insert(float, { part = p, base = p.CFrame, ph = i * 1.3 })
		elseif p.Name == "Spider" then table.insert(float, { part = p, base = p.CFrame, spider = true }) end
	end
	RunService.RenderStepped:connect(function()
		local cam = workspace.CurrentCamera
		if not cam or (cam.CoordinateFrame.p - centre).magnitude > 300 then return end
		local now = tick()
		for _, f in ipairs(float) do
			if f.spider then
				f.part.CFrame = f.base + Vector3.new(0, math.sin(now * 1.5) * 2.5 - 2, 0)
			else
				f.part.CFrame = CFrame.new(math.sin(now * 0.7 + f.ph) * 2, math.sin(now * 2 + f.ph) * 1.5, 0) * f.base
			end
		end
	end)
end)
