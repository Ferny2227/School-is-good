-- ==== h30_items.lua
------------------------------------------------------------------ items: click to pick up, you can only carry ONE
local holding = {}          -- player -> item name
local survivors = {}        -- player -> true while they're in the map and not caught / escaped
local hogPlayer = nil       -- the player who is the Hog (Player Hog mode)
local HOG = nil             -- the bot Hog (Bot Hog mode)
local onHeard               -- (the Hog hears doors being unlocked; set in h40_hog.lua)
local function itemLook(m, name, at)
	local c = ITEM_LOOK[name] or { "Bright yellow" }
	local main
	if name == "Hammer" then
		main = P(m, "Handle", V(0.4, 2.6, 0.4), CFrame.new(at + V(0, 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2), c[1], "Wood")
		P(m, "Head", V(0.8, 0.6, 1.4), CFrame.new(at + V(1.2, 0.35, 0)), c[2], "Metal")
	elseif name == "Wrench" then
		main = P(m, "Handle", V(0.4, 2.4, 0.3), CFrame.new(at + V(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), c[1], "Metal")
		P(m, "Jaw", V(0.9, 0.3, 0.9), CFrame.new(at + V(1.3, 0.2, 0)), c[1], "Metal")
	elseif name == "Fuse" then
		main = P(m, "Handle", V(1.4, 0.7, 0.7), CFrame.new(at + V(0, 0.4, 0)) * CFrame.Angles(0, 0, 0), c[1], "Neon", { shape = "cyl" })
	else
		main = P(m, "Handle", V(1.6, 0.25, 0.4), CFrame.new(at + V(0, 0.15, 0)), c[1], "Metal")
		P(m, "Ring", V(0.8, 0.25, 0.8), CFrame.new(at + V(-1, 0.15, 0)), c[1], "Metal")
		P(m, "Tooth", V(0.25, 0.25, 0.5), CFrame.new(at + V(0.6, 0.15, 0.3)), c[1], "Metal")
	end
	for _, o in ipairs(m:GetChildren()) do if o:IsA("BasePart") then o.CanCollide = false end end
	light(main, main.BrickColor.Color, 7, 1)
	return main
end
local spawnItem
local function giveTool(p, name)
	local c = p.Character
	if not c then return end
	local tool = Instance.new("Tool")
	tool.Name = name
	pcall(function() tool.CanBeDropped = false end)
	pcall(function() tool.ToolTip = "Click a lock to use it" end)
	local col = (ITEM_LOOK[name] or { "Bright yellow" })[1]
	local h = P(tool, "Handle", name == "Fuse" and V(0.7, 1.4, 0.7) or V(0.4, 1.8, 0.4), CFrame.new(), col, name == "Fuse" and "Neon" or "Metal", { anchored = false })
	h.CanCollide = false
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
				if dn.lock and not dn.lock.gate and (dn.A == R or dn.B == R) and R.kind ~= "hall" then locked = true end
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
	local m = model(MAP.model, "Item")
	local main = itemLook(m, name, at)
	local it = { name = name, model = m, at = at }
	MAP.items[m] = it
	local b = bill(main, name, 5, 1, 1.6, Color3.new(1, 1, 0.6))
	pcall(function() b.Parent.MaxDistance = 40 end)
	MAP.clicker(main, function(p)
		if not survivors[p] or not m.Parent then return end
		local t = torsoOf(p.Character)
		if not t or (t.Position - main.Position).magnitude > 18 then return end
		-- swap: drop what you're holding where this one was
		local old = holding[p]
		MAP.items[m] = nil
		m:Destroy()
		if old then
			holding[p] = nil
			takeTool(p)
			spawnItem(old, at)
		end
		holding[p] = name
		giveTool(p, name)
		toClient(p, "hold", name)
		say(p, "You picked up the " .. name .. "!", "gold")
	end)
	return it
end

------------------------------------------------------------------ locks: click with the right item
local function sendLocks(p)
	if not MAP then return end
	local list = {}
	for _, L in ipairs(MAP.locks) do
		if not L.gate then table.insert(list, { L.name, L.need, L.done and true or false, L.exit and true or false }) end
	end
	if p then toClient(p, "locks", list, MAP.name) else toAll("locks", list, MAP.name) end
end
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
		d.CanCollide = false
		local dn = L.node
		local hinge = dn.vertical and CFrame.new(0, 0, -DW / 2) or CFrame.new(-DW / 2, 0, 0)
		d.CFrame = d.CFrame * hinge * CFrame.Angles(0, math.rad(85), 0) * hinge:inverse()
		d.Transparency = 0.2
	else
		for _, part in ipairs(L.parts) do
			part.Anchored = false
			part.CanCollide = false
			Debris:AddItem(part, 3)
		end
	end
	local name = p and p.Name or "Someone"
	sayAll(name .. " used the " .. (L.need or "?") .. " on the " .. L.name .. "!", "green")
	if p then addCoins(p, 5) end
	if onHeard then onHeard((L.part or L.parts[1]).Position) end
	sendLocks()
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
				MAP.clicker(part, function(p)
					if L.done or not survivors[p] then return end
					local t = torsoOf(p.Character)
					if not t or (t.Position - part.Position).magnitude > 20 then return end
					if holding[p] == L.need then
						holding[p] = nil
						takeTool(p)
						toClient(p, "hold", nil)
						solve(L, p)
					else
						say(p, "The " .. L.name .. " needs the " .. L.need .. (holding[p] and (" - you have the " .. holding[p]) or "") .. ".", "red")
					end
				end)
			end
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
