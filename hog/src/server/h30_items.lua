-- ==== h30_items.lua
------------------------------------------------------------------ items: click to pick up, you can only carry ONE
local holding = {}          -- player -> item name
local survivors = {}        -- player -> true while they're in the map and not caught / escaped
local hogPlayers = {}       -- players who are a Hog (Player, Player + Bot, Infection)
local traitor = nil         -- Traitor mode: the secret traitor
local HOGS = {}             -- the bot Hogs
local crouching = {}        -- player -> true while crouching
local stuck = {}            -- player -> true while caught in a trap
local onHeard               -- (the Hog hears doors being unlocked; set in h40_hog.lua)
local gunShots = {}         -- player -> shots left in the Stun Gun
local crawling = {}         -- player -> true while down in a vent tunnel (the Hog can't see or catch them)
-- what each item looks like (made of small parts, lying flat, long side along Z). `base` is where it sits; the same
-- shape is used in your hand (the part called "Handle" is where you hold it)
local function itemLook(m, name, base)
	local c = ITEM_LOOK[name] or { "Bright yellow" }
	local main
	local function part(n, size, off, color, mat, opt)
		local pp = P(m, n, size, base * off, color, mat, opt)
		pp.CanCollide = false
		return pp
	end
	local flat = CFrame.Angles(0, 0, math.pi / 2)        -- (turns a cylinder so it lies flat like a coin)
	if name == "Hammer" then
		main = part("Handle", V(0.35, 0.35, 2.6), CFrame.new(0, 0.18, 0.3), "Reddish brown", "Wood")
		part("Grip", V(0.42, 0.42, 0.9), CFrame.new(0, 0.18, 1.1), "Black", "Fabric")
		part("Head", V(1.5, 0.55, 0.55), CFrame.new(0.15, 0.28, -1.1), "Dark stone grey", "Metal")
		part("Claw", V(0.6, 0.4, 0.3), CFrame.new(-0.85, 0.28, -1.0) * CFrame.Angles(0, 0.5, 0), "Dark stone grey", "Metal")
	elseif name == "Wrench" then
		main = part("Handle", V(0.5, 0.2, 2.4), CFrame.new(0, 0.1, 0), "Medium stone grey", "Metal")
		part("JawBase", V(1, 0.22, 0.45), CFrame.new(0, 0.1, -1.35), "Medium stone grey", "Metal")
		part("Jaw", V(0.28, 0.22, 0.7), CFrame.new(-0.36, 0.1, -1.8), "Medium stone grey", "Metal")
		part("Jaw", V(0.28, 0.22, 0.7), CFrame.new(0.36, 0.1, -1.8), "Medium stone grey", "Metal")
		part("Ring", V(0.22, 0.85, 0.85), CFrame.new(0, 0.1, 1.35) * flat, "Medium stone grey", "Metal", { shape = "cyl" })
	elseif name == "Stun Gun" then
		main = part("Handle", V(0.5, 0.8, 1.8), CFrame.new(0, 0.4, 0), "Black", "SmoothPlastic")
		part("Barrel", V(0.32, 0.32, 1), CFrame.new(0, 0.55, -1.3), "Dark stone grey", "Metal")
		part("Tip", V(0.5, 0.5, 0.25), CFrame.new(0, 0.55, -1.85), "New Yeller", "Neon")
		part("Grip", V(0.45, 1.1, 0.5), CFrame.new(0, 0.1, 0.7) * CFrame.Angles(0.35, 0, 0), "Black", "SmoothPlastic")
		part("Stripe", V(0.52, 0.15, 1.4), CFrame.new(0, 0.82, 0), "New Yeller", "SmoothPlastic")
	elseif name == "Fuse" then
		main = part("Handle", V(1.6, 0.6, 0.6), CFrame.new(0, 0.32, 0) * CFrame.Angles(0, math.pi / 2, 0), "Pastel yellow", "Glass", { shape = "cyl", tr = 0.3 })
		part("Wire", V(0.1, 0.1, 1.4), CFrame.new(0, 0.32, 0), "New Yeller", "Neon")
		part("Cap", V(0.3, 0.7, 0.7), CFrame.new(0, 0.32, 0.9) * CFrame.Angles(0, math.pi / 2, 0), "Medium stone grey", "Metal", { shape = "cyl" })
		part("Cap", V(0.3, 0.7, 0.7), CFrame.new(0, 0.32, -0.9) * CFrame.Angles(0, math.pi / 2, 0), "Medium stone grey", "Metal", { shape = "cyl" })
	elseif name == "Keycard" then
		main = part("Handle", V(1.4, 0.08, 2.2), CFrame.new(0, 0.05, 0), "Institutional white", "SmoothPlastic")
		part("Stripe", V(1.42, 0.09, 0.45), CFrame.new(0, 0.06, -0.6), "Lime green", "SmoothPlastic")
		part("Chip", V(0.4, 0.1, 0.35), CFrame.new(-0.3, 0.07, 0.4), "Gold", "Metal")
	else
		-- a key: a round bow with a hole, the shaft and the teeth
		main = part("Handle", V(0.25, 0.2, 1.6), CFrame.new(0, 0.12, 0.3), c[1], "Metal")
		part("Bow", V(0.25, 1.2, 1.2), CFrame.new(0, 0.12, -0.9) * flat, c[1], "Metal", { shape = "cyl" })
		part("Hole", V(0.27, 0.45, 0.45), CFrame.new(0, 0.12, -0.9) * flat, "Really black", "SmoothPlastic", { shape = "cyl" })
		part("Tooth", V(0.45, 0.2, 0.22), CFrame.new(0.3, 0.12, 0.75), c[1], "Metal")
		part("Tooth", V(0.3, 0.2, 0.22), CFrame.new(0.22, 0.12, 1.05), c[1], "Metal")
	end
	light(main, main.BrickColor.Color, 6, 0.8)
	return main
end
local spawnItem
local function giveTool(p, name)
	local c = p.Character
	if not c then return end
	local tool = Instance.new("Tool")
	tool.Name = name
	pcall(function() tool.CanBeDropped = false end)
	pcall(function() tool.ToolTip = name end)
	local h = itemLook(tool, name, CFrame.new())
	for _, o in ipairs(tool:GetChildren()) do
		if o:IsA("BasePart") then
			o.Anchored = false
			if o ~= h then weld(h, o) end
		end
	end
	tool.Parent = c          -- straight into the hand
	return tool
end
local function takeTool(p)
	for _, where in ipairs({ p.Character, p:FindFirstChild("Backpack") }) do
		if where then
			for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and t.Name ~= "Trap" then t:Destroy() end
			end
		end
	end
end
local function dropItem(p, at)
	local name = holding[p]
	if not name then return end
	holding[p] = nil
	takeTool(p)
	toClient(p, "hold", nil)
	if MAP and at then
		local r = roomAt(at)
		if r then spawnItem(name, V(at.X, 0, at.Z)) else spawnItem(name, nil) end
	end
end
function spawnItem(name, at)
	if not MAP then return end
	if not at then
		-- somewhere it's allowed to be
		local def = nil
		for _, it in ipairs(MAP.def.items) do if it[1] == name then def = it end end
		local rooms = {}
		for _, R in ipairs(MAP.rooms) do
			local locked = false
			for _, dn in ipairs(MAP.doorNodes) do
				if dn.lock and not dn.lock.gate and (dn.A == R or dn.B == R) and R.kind ~= "hall" and R.kind ~= "open" then locked = true end
			end
			if (def and def[2] == R.id) or (not def or def[2] == "open") and not locked and R ~= MAP.pen and #R.spots > 0 then
				table.insert(rooms, R)
			end
		end
		local R = pick(rooms)
		local used = {}
		for _, it in pairs(MAP.items) do if it.at then used[tostring(it.at)] = true end end
		local free = {}
		for _, s in ipairs(R.spots) do if not used[tostring(s)] then table.insert(free, s) end end
		at = pick(#free > 0 and free or R.spots)
	end
	if name == "Code Note" then
		local m = model(MAP.model, "CodeNote")
		local paper = P(m, "Note", V(1.8, 0.1, 2.4), CFrame.new(at + V(0, 0.05, 0)) * CFrame.Angles(0, math.random() * 6.28, 0), "Institutional white", "SmoothPlastic", { nc = true })
		sign(paper, "CODE:\n" .. MAP.code, "Top", Color3.new(0.15, 0.1, 0.1))
		P(m, "Stain", V(0.6, 0.11, 0.5), paper.CFrame * CFrame.new(0.5, 0, 0.8), "Brown", "SmoothPlastic", { nc = true })
		MAP.clickable(paper)
		MAP.partNote = MAP.partNote or {}
		MAP.partNote[paper] = true
		return
	end
	local m = model(MAP.model, "Item")
	local main = itemLook(m, name, CFrame.new(at) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	local it = { name = name, model = m, at = at }
	MAP.items[m] = it
	local tag = Instance.new("StringValue")         -- (players' computers show the name when you point at it)
	tag.Name = "ItemName"
	tag.Value = name
	tag.Parent = m
	-- a big invisible box round it, so it's easy to click
	local hit = P(m, "Hitbox", V(3.4, 3, 3.4), CFrame.new(main.Position), "White", nil, { tr = 1, nc = true })
	it.main, it.born = main, tick()
	it.take = function(p)
		if not survivors[p] or not m.Parent then return end
		local t = torsoOf(p.Character)
		if not t or (t.Position - main.Position).magnitude > 18 then return end
		-- swap: drop what you're holding where this one was
		local old = holding[p]
		if onHeard then onHeard(main.Position, 30) end
		MAP.items[m] = nil
		m:Destroy()
		if old then
			holding[p] = nil
			takeTool(p)
			spawnItem(old, at)
		end
		holding[p] = name
		if name == "Stun Gun" then gunShots[p] = 2 end
		giveTool(p, name)
		toClient(p, "hold", name, gunShots[p])
		say(p, "You picked up the " .. name .. "!", "gold")
	end
	for _, part in ipairs(m:GetChildren()) do
		if part:IsA("BasePart") then
			MAP.clickable(part)
			MAP.partItem[part] = it
		end
	end
	return it
end

------------------------------------------------------------------ locks: click with the right item
local function openExit()
	if MAP.exitDone then return end
	MAP.exitDone = true
	for i, half in ipairs(MAP.exitDoor) do
		half.CanCollide = false
		local s = i == 1 and -1 or 1
		half.CFrame = half.CFrame * CFrame.new(s * 2.25, 0, 0) * CFrame.Angles(0, s * math.rad(80), 0) * CFrame.new(-s * 2.25, 0, 0)
	end
	MAP.exitGlow.Transparency = 0.4
	light(MAP.exitGlow, Color3.new(0.3, 1, 0.3), 30, 2)
	toAll("big", "THE EXIT IS OPEN!", "RUN OUT THE DOOR TO ESCAPE!")
end
local function solve(L, p)
	if L.done then return end
	L.done = true
	if L.bulb then
		L.bulb.BrickColor = BrickColor.new("Lime green")
		light(L.bulb, Color3.new(0.3, 1, 0.3), 10, 2)
		if L.parts[1] then L.parts[1].BrickColor = BrickColor.new("Dark stone grey") end
	elseif L.node then
		-- a coloured door swings open
		local d = L.part
		local dn = L.node
		local hinge = d.CFrame * (dn.vertical and CFrame.new(0, 0, -DW / 2) or CFrame.new(-DW / 2, 0, 0))
		local turn = hinge * CFrame.Angles(0, math.rad(85), 0) * hinge:inverse()
		for _, part in ipairs(L.parts) do
			part.CanCollide = false
			part.CFrame = turn * part.CFrame
		end
	else
		for _, part in ipairs(L.parts) do
			part.Anchored = false
			part.CanCollide = false
			Debris:AddItem(part, 3)
		end
	end
	MAP.solved = (MAP.solved or 0) + 1        -- (the Hog gets a little faster with every lock you open)
	local name = p and p.Name or "Someone"
	sayAll(L.keypad and (name .. " typed in the code!") or (name .. " used the " .. (L.need or "?") .. "!"), "green")
	if p then addCoins(p, 5) end
	if onHeard then onHeard((L.part or L.parts[1]).Position) end
	if L.exit then
		local all = true
		for _, e in ipairs(MAP.exitLocks) do if not e.done then all = false end end
		if all then openExit() end
	end
end
local function hookLocks()
	for _, L in ipairs(MAP.locks) do
		if not L.gate then
			for _, part in ipairs(L.parts) do
				MAP.clickable(part)
				MAP.partLock[part] = L
			end
		end
	end
end
-- a player clicked something in the map (their computer sends what the mouse was on)
local lastClick = {}
local function clickPart(p, part)
	if not MAP or not survivors[p] then return end
	if type(part) ~= "userdata" and type(part) ~= "table" then return end
	if tick() - (lastClick[p] or 0) < 0.25 then return end
	lastClick[p] = tick()
	local t = torsoOf(p.Character)
	local ok, pos = pcall(function() return part.Position end)
	if not t or not ok or (t.Position - pos).magnitude > 16 then return end
	if MAP.partNote and MAP.partNote[part] then
		toClient(p, "note", MAP.code)
		return
	end
	local it = MAP.partItem[part]
	if it then
		if MAP.items[it.model] then it.take(p) end
		return
	end
	local L = MAP.partLock[part]
	if L and not L.done then
		if L.keypad then
			toClient(p, "keypad")
		elseif holding[p] == L.need then
			holding[p] = nil
			takeTool(p)
			toClient(p, "hold", nil)
			solve(L, p)
		else
			say(p, "It's locked.", "red")
		end
	end
end
local function openGate()
	local L = MAP and MAP.gate
	if not L or L.done then return end
	L.done = true
	for _, part in ipairs(L.parts) do
		if part.Name == "GateBlock" then part:Destroy() else part.CFrame = part.CFrame - V(0, DH - 0.3, 0) end
	end
end
-- is the way through this path point shut?
local function nodeShut(n) return n.lock ~= nil and not n.lock.done end

-- typing a code into the keypad (wrong codes beep loudly - the Hog comes to look)
local lastCode = {}
local function enterCode(p, code)
	if not MAP or not survivors[p] or tick() - (lastCode[p] or 0) < 1 then return end
	lastCode[p] = tick()
	for _, L in ipairs(MAP.locks) do
		if L.keypad and not L.done then
			local t = torsoOf(p.Character)
			if not t or (t.Position - L.parts[1].Position).magnitude > 18 then return end
			if tostring(code) == MAP.code then
				solve(L, p)
				toClient(p, "keypadok")
			else
				say(p, "WRONG CODE!", "red")
				toClient(p, "keypadbad")
				if onHeard then onHeard(L.parts[1].Position, 80) end
			end
			return
		end
	end
end
