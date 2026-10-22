------------------------------------------------------------------ the sea (see SeaHeight above): big rolling swells round the boat
-- Players' computers draw the surface (OceanClient) from the SeaState values; the server uses the same maths to
-- rock the boat, float swimmers and lifeboats, and wash people off the deck.
local SHIP_AT = V(0, 0, -650)
local EPOCH = tick()
local function seaTime() return tick() - EPOCH end
SEA.waves, SEA.amp, SEA.rogueA, SEA.rogueT, SEA.rogueZ, SEA.rogueLen, SEA.rogueBump = 3, 3, 0, 0, 0, 150, false
SEA.shipX, SEA.shipZ = SHIP_AT.X, SHIP_AT.Z
local function waveAt(x, z, t) return SeaHeight(x, z, t or seaTime(), SEA) end
local seaState = Instance.new("Model")
seaState.Name = "SeaState"
local function value(cls, name, v)
	local o = Instance.new(cls)
	o.Name = name
	o.Value = v
	o.Parent = seaState
	return o
end
local seaAmp = value("NumberValue", "Amp", SEA.amp)
value("NumberValue", "Speed", SEA.speed)
local seaLevel = value("NumberValue", "Level", 0)
local seaClock = value("NumberValue", "Clock", 0)
value("Vector3Value", "ShipAt", SHIP_AT)
local seaShipLen = value("NumberValue", "ShipLen", 200)
local seaShip = value("ObjectValue", "Ship", nil)          -- the boat's model
local seaShipWid = value("NumberValue", "ShipWid", 30)
-- the boat's pose comes from the waves (ShipPose), worked out on each computer; these are the extras on top
local seaShipAir = value("NumberValue", "ShipAir", 0)       -- lifted by the tornado
local seaShipYaw = value("NumberValue", "ShipYaw", 0)       -- spun by the tornado
local seaShipSink = value("NumberValue", "ShipSink", -1)    -- sea time the boat started sinking (-1: it isn't)
local seaTheme = value("StringValue", "Theme", "Normal")
local seaSailing = value("BoolValue", "Sailing", false)
local rogueVals = { A = value("NumberValue", "RogueA", 0), T = value("NumberValue", "RogueT", 0), Z = value("NumberValue", "RogueZ", 0),
	Len = value("NumberValue", "RogueLen", 150), Bump = value("BoolValue", "RogueBump", false) }
seaState.Parent = RS
local function stepSea(dt)
	SEA.amp = SEA.amp + clamp(SEA.waves - SEA.amp, -4 * dt, 4 * dt)
	if math.abs(seaAmp.Value - SEA.amp) > 0.05 then seaAmp.Value = SEA.amp end
	if seaLevel.Value ~= SEA.level then seaLevel.Value = SEA.level end
end
spawn(function() while true do seaClock.Value = seaTime() wait(5) end end)
-- a set of bigger waves (or one giant swell) that starts far ahead of the bow and rolls through the boat
local function rogue(height, len, bump, from)
	SEA.rogueA, SEA.rogueT, SEA.rogueZ, SEA.rogueLen, SEA.rogueBump = height, seaTime(), from or -700, len, bump and true or false
	rogueVals.A.Value, rogueVals.T.Value, rogueVals.Z.Value, rogueVals.Len.Value, rogueVals.Bump.Value = SEA.rogueA, SEA.rogueT, SEA.rogueZ, len, SEA.rogueBump
end
local function calmRogue() SEA.rogueA = 0 rogueVals.A.Value = 0 end

-- the far, flat ocean all round. Around the boat (the hole in the middle) each player's computer draws the moving
-- swells (OceanClient), which flatten out at the edges to meet this. Under the hole: a deep blue floor.
local HOLE = { x0 = -2000, x1 = 2000, z0 = SHIP_AT.Z - 500, z1 = SHIP_AT.Z + 500 }
local oceanTiles = {}
local function oceanTile(x0, x1, z0, z1, y, color)
	local t = P(WORLD, "Ocean", V(x1 - x0, 2, z1 - z0), CFrame.new((x0 + x1) / 2, y, (z0 + z1) / 2), color or "Deep blue", "SmoothPlastic", { nc = true })
	table.insert(oceanTiles, { part = t, dy = y })
end
-- (the drawn swells reach 2000 studs out in every direction; this sits under their deepest troughs, in the fog)
oceanTile(-6000, 6000, -6000, 6000, -140)
for ix = -2, 1 do
	for iz = -2, 1 do P(WORLD, "Seabed", V(1000, 4, 1000), CFrame.new(ix * 1000 + 500, -260, iz * 1000 + 500), "Brick yellow", "Sand") end
end
local terrainWater = false
local function setSea(level)
	SEA.level = level
	for _, t in ipairs(oceanTiles) do t.part.CFrame = CFrame.new(t.part.Position.X, level + t.dy, t.part.Position.Z) end
end

------------------------------------------------------------------ themes: the look of the whole map (voted in the lobby)
local THEMES = {
	Normal = { time = "14:00:00", amb = Color3.new(0.42, 0.44, 0.48), out = Color3.new(0.46, 0.48, 0.52), fog = Color3.new(0.36, 0.39, 0.44), fogEnd = 1100, bright = 0.55, water = Color3.new(0.07, 0.22, 0.46), sea = Color3.new(0.07, 0.22, 0.46) },
	Sunset = { time = "18:05:00", amb = Color3.new(0.55, 0.42, 0.38), out = Color3.new(0.65, 0.48, 0.42), fog = Color3.new(0.95, 0.62, 0.45), fogEnd = 1800, bright = 1, water = Color3.new(0.12, 0.25, 0.42) , sea = Color3.new(0.12, 0.2, 0.38) },
	Halloween = { time = "23:30:00", amb = Color3.new(0.32, 0.2, 0.38), out = Color3.new(0.38, 0.25, 0.45), fog = Color3.new(0.22, 0.08, 0.28), fogEnd = 650, bright = 0.6, water = Color3.new(0.04, 0.18, 0.14) , sea = Color3.new(0.03, 0.1, 0.08) },
}
local THEME_ORDER = { "Normal", "Sunset", "Halloween" }
local theme = "Normal"
local themeDeco = model(WORLD, "Theme")
local function applyLighting()
	local t = THEMES[theme]
	pcall(function()
		Lighting.TimeOfDay = t.time
		Lighting.Ambient = t.amb
		Lighting.OutdoorAmbient = t.out
		Lighting.FogColor = t.fog
		Lighting.FogEnd = t.fogEnd
		Lighting.Brightness = t.bright
	end)
	pcall(function() workspace.Terrain.WaterColor = t.water end)
	for i, tile in ipairs(oceanTiles) do
		if true then
			local ok = pcall(function() tile.part.Color = t.sea end)
			if not ok then pcall(function() tile.part.BrickColor = BrickColor.new(t.sea) end) end
		end
	end
end
local function pumpkin(parent, cf, size)
	size = size or 2.4
	local p = P(parent, "Pumpkin", V(size, size * 0.85, size), cf, "Neon orange", "SmoothPlastic", { shape = "ball" })
	P(parent, "Stem", V(0.3, 0.6, 0.3), cf * CFrame.new(0, size * 0.5, 0), "Earth green", "Wood")
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	pcall(function() face.Face = Enum.NormalId.Front end)
	face.Parent = p
	light(p, Color3.new(1, 0.5, 0.1), 10, 1.5)
	return p
end

------------------------------------------------------------------ the lobby: a house floating high in the sky
local LOBBY_AT = V(0, 300, -260)
local LOBBY = model(WORLD, "Sky Lobby")
local function L(x, y, z) return CFrame.new(LOBBY_AT + V(x, y, z)) end
local function lb(name, sx, sy, sz, x, y0, z, color, mat, opt) return P(LOBBY, name, V(sx, sy, sz), L(x, y0 + sy / 2, z), color, mat, opt) end
-- the floating rock with a garden on top
P(LOBBY, "Grass", V(6, 150, 150), L(0, -3, 0) * CFrame.Angles(0, 0, math.rad(90)), "Bright green", "Grass", { shape = "cyl" })
for i = 1, 7 do
	P(LOBBY, "Rock", V(12, 150 - i * 20, 150 - i * 20), L(0, -6 - i * 10, 0) * CFrame.Angles(0, 0, math.rad(90)), i % 2 == 0 and "Dark stone grey" or "Brown", "Slate", { shape = "cyl" })
end
for i = 0, 39 do   -- a see-through fence round the edge
	local a = i / 40 * math.pi * 2
	P(LOBBY, "Fence", V(12.5, 6, 0.6), L(math.cos(a) * 74, 3, math.sin(a) * 74) * CFrame.Angles(0, -a + math.pi / 2, 0), "Pastel light blue", "Glass", { tr = 0.75 })
end
-- the house (front door and big porch facing the sea, where the boat is). Inside: the boards on the back wall, boat
-- votes along the left wall, theme votes along the right, a carpet runner down the middle, a fireplace corner.
local HX, HZ, HW, HD, HH = 0, 15, 96, 64, 22
local wallColor = "Institutional white"
lb("Floor", HW, 1, HD, HX, 0, HZ, "Brown", "WoodPlanks")
lb("WallBack", HW, HH, 1, HX, 1, HZ + HD / 2, wallColor, "SmoothPlastic")
for _, s in ipairs({ -1, 1 }) do lb("WallSide", 1, HH, HD, HX + s * HW / 2, 1, HZ, wallColor, "SmoothPlastic") end
-- front wall: big windows either side of a wide door
for _, s in ipairs({ -1, 1 }) do
	local w, x = HW / 2 - 7, HX + s * (HW / 4 + 3.5)
	lb("WallFront", w, 4, 1, x, 1, HZ - HD / 2, wallColor, "SmoothPlastic")
	lb("FrontWindow", w, 10, 0.6, x, 5, HZ - HD / 2, "Pastel light blue", "Glass", { tr = 0.4 })
	lb("WallFront", w, HH - 14, 1, x, 15, HZ - HD / 2, wallColor, "SmoothPlastic")
end
lb("Lintel", 14, HH - 10, 1, HX, 11, HZ - HD / 2, wallColor, "SmoothPlastic")
lb("Ceiling", HW, 0.6, HD, HX, HH + 0.6, HZ, "Light stone grey", "SmoothPlastic")
lb("Roof", HW + 8, 1.2, HD + 10, HX, HH + 1.2, HZ - 2, "Dark stone grey", "Slate")
lb("RoofTrim", HW + 9, 1, HD + 11, HX, HH + 2.4, HZ - 2, "Bright red", "SmoothPlastic")
lb("Chimney", 5, 10, 5, HX + 36, HH + 2, HZ + 24, "Brick yellow", "Brick")
local houseSign = lb("HouseSign", 36, 5, 0.6, HX, HH - 4, HZ - HD / 2 - 0.9, "Navy blue", "SmoothPlastic")
sign(houseSign, "DISASTER OCEAN", "Front", Color3.new(1, 0.85, 0.3))
-- wood panelling on the lower walls with a navy trim line
lb("Panelling", HW - 2, 5, 0.4, HX, 1, HZ + HD / 2 - 0.7, "Reddish brown", "Wood")
lb("PanelTrim", HW - 2, 0.5, 0.5, HX, 6, HZ + HD / 2 - 0.75, "Navy blue", "SmoothPlastic")
for _, s in ipairs({ -1, 1 }) do
	lb("Panelling", 0.4, 5, HD - 2, HX + s * (HW / 2 - 0.7), 1, HZ, "Reddish brown", "Wood")
	lb("PanelTrim", 0.5, 0.5, HD - 2, HX + s * (HW / 2 - 0.75), 6, HZ, "Navy blue", "SmoothPlastic")
end
-- porch with chairs, lamps and a telescope pointing at the boat
lb("Porch", HW + 4, 0.8, 18, HX, 0, HZ - HD / 2 - 9, "Reddish brown", "WoodPlanks")
for _, x in ipairs({ -36, -24, 24, 36 }) do lb("PorchChair", 3, 1.2, 3, x, 1, HZ - HD / 2 - 12, "Bright red", "Fabric", { class = "Seat" }) end
for _, x in ipairs({ -46, 46 }) do
	lb("LampPost", 0.6, 10, 0.6, x, 0.8, HZ - HD / 2 - 16, "Really black", "Metal")
	light(lb("Lamp", 1.6, 1.6, 1.6, x, 10.8, HZ - HD / 2 - 16, "Cool yellow", "Neon"), Color3.new(1, 0.9, 0.6), 22, 1.5)
end
local scope = P(LOBBY, "Telescope", V(1.2, 1.2, 6), L(0, 4.5, HZ - HD / 2 - 15) * CFrame.Angles(math.rad(-20), 0, 0), "Gold", "Metal")
lb("TelescopeLeg", 0.4, 3.6, 0.4, 0, 0.8, HZ - HD / 2 - 14, "Really black", "Metal")
-- inside: the spawn near the door (you face the boards on the back wall), a carpet runner down the middle
local spawnPad = P(LOBBY, "SpawnLocation", V(14, 1, 10), L(HX, 1.5, HZ - HD / 2 + 12) * CFrame.Angles(0, math.pi, 0), "Bright blue", "SmoothPlastic", { class = "SpawnLocation" })
pcall(function() spawnPad.Duration = 0 end)
lb("Runner", 18, 0.2, HD - 4, HX, 1, HZ + 1, "Navy blue", "Fabric", { nc = true })
for _, s in ipairs({ -1, 1 }) do lb("RunnerEdge", 1, 0.25, HD - 4, HX + s * 9.5, 1, HZ + 1, "Gold", "Fabric", { nc = true }) end
-- three chandeliers down the middle
for _, z in ipairs({ HZ - 18, HZ, HZ + 18 }) do
	lb("ChandelierChain", 0.3, 3, 0.3, HX, HH - 2.4, z, "Gold", "Metal", { nc = true })
	local c = P(LOBBY, "Chandelier", V(5, 5, 5), L(HX, HH - 4, z), "Cool yellow", "Neon", { shape = "ball", nc = true })
	light(c, Color3.new(1, 0.9, 0.7), 40, 1.3)
end
-- the fireplace corner at the back right, with couches round it
lb("Fireplace", 12, 9, 3, HX + 34, 1, HZ + HD / 2 - 2, "Brick yellow", "Brick")
lb("Mantel", 14, 0.8, 4, HX + 34, 10, HZ + HD / 2 - 2.5, "Reddish brown", "Wood")
local fire = lb("Fire", 6, 2.5, 1, HX + 34, 2, HZ + HD / 2 - 3.6, "Neon orange", "Neon", { nc = true })
light(fire, Color3.new(1, 0.55, 0.2), 24, 2)
for i = 0, 2 do lb("Couch", 4, 2, 3, HX + 29.5 + i * 4.5, 1, HZ + HD / 2 - 14, "Royal purple", "Fabric", { class = "Seat" }) end
lb("CoffeeTable", 8, 1.6, 4, HX + 34, 1, HZ + HD / 2 - 9, "Brown", "Wood")
-- the back wall: HOW TO PLAY in the middle, the sea board on the left, top winners on the right (all up on the wall)
local BOARD = {}
do
	local how = lb("HowToPlayBoard", 30, 13, 0.6, HX, 6, HZ + HD / 2 - 1, "Navy blue", "SmoothPlastic")
	sign(how, "HOW TO PLAY\n" ..
		"1. Step on a glowing pad to vote for the next BOAT and the map THEME.\n" ..
		"2. Everyone goes aboard. A new EVENT every 10 seconds - every 3 it gets much harder.\n" ..
		"3. Stay on the boat - waves try to throw you off and the water hurts! SPACE leaps you back.\n" ..
		"4. Every event you live through pays Coins. LAST ONE STANDING WINS!\n" ..
		"5. Joined late or died? Wait here, or play as a GHOST (ghosts don't count).", "Front", Color3.new(1, 1, 1))
	for _, s in ipairs({ -1, 1 }) do
		local b = lb(s < 0 and "SeaBoard" or "WinnersBoard", 20, 9, 0.6, HX + s * 27, 11.5, HZ + HD / 2 - 1, s < 0 and "Really black" or "Navy blue", "SmoothPlastic")
		BOARD[s < 0 and "sea" or "top"] = sign(b, "", "Front", Color3.new(1, 0.9, 0.4))
	end
	-- plants in the corners, an aquarium by the window, a bookshelf
	for _, c in ipairs({ { -44, HZ - HD / 2 + 3 }, { 44, HZ - HD / 2 + 3 }, { -44, HZ + HD / 2 - 3 }, { 18, HZ + HD / 2 - 3 } }) do
		lb("PlantPot", 3, 2.4, 3, HX + c[1], 1, c[2], "Brown", "Wood")
		P(LOBBY, "Plant", V(5, 5, 5), L(HX + c[1], 6, c[2]), "Bright green", "Grass", { shape = "ball", nc = true })
	end
	local AQ, AZ = HX - 20, HZ - HD / 2 + 3.5
	lb("AquariumStand", 12, 3, 4, AQ, 1, AZ, "Brown", "Wood")
	lb("Aquarium", 11, 6, 3.4, AQ, 4, AZ, "Pastel light blue", "Glass", { tr = 0.55, nc = true })
	for i = 1, 6 do
		P(LOBBY, "AquariumFish", V(0.7, 0.7, 1.4), L(AQ - 5 + i * 1.5, 5.5 + (i % 3), AZ + (i % 2 == 0 and 0.6 or -0.6)),
			({ "Bright orange", "Bright yellow", "Bright red", "Lime green", "Bright blue", "Hot pink" })[i], "Neon", { nc = true })
	end
	lb("Bookshelf", 10, 11, 2.4, HX + 20, 1, HZ - HD / 2 + 2.4, "Reddish brown", "Wood")
	for i = 0, 3 do lb("Books", 9, 1.8, 1.6, HX + 20, 2.2 + i * 2.5, HZ - HD / 2 + 3.2, ({ "Bright red", "Bright blue", "Bright green", "Bright yellow" })[i + 1], "Fabric", { nc = true }) end
end

-- the vote stations: step on a pad to vote. Boats on the left wall, themes on the right wall.
local votes = { boat = {}, theme = {} }
local voteLabels = { boat = {}, theme = {} }
local BOAT_NAMES = { "Cruise Liner", "Pirate Galleon", "Navy Destroyer", "Fishing Boat" }
local BOAT_COLORS = { "Bright blue", "Brown", "Medium stone grey", "Bright red" }
local THEME_COLORS = { "Bright green", "Bright orange", "Royal purple" }
local function countVotes(kind)
	local n = {}
	for _, v in pairs(votes[kind]) do n[v] = (n[v] or 0) + 1 end
	return n
end
local function refreshVotes()
	for _, kind in ipairs({ "boat", "theme" }) do
		local n = countVotes(kind)
		for name, lab in pairs(voteLabels[kind]) do lab.Text = name .. "\n" .. (n[name] or 0) .. " votes" end
	end
end
local function votePads(kind, names, colors, x, title)
	local board = lb("VoteBoard", 1, 5, 40, x, 12, kind == "boat" and HZ + 4 or HZ - 4, "Navy blue", "SmoothPlastic")
	sign(board, title, x < 0 and "Right" or "Left", Color3.new(1, 0.85, 0.3))
	for i, name in ipairs(names) do
		local z = (kind == "boat" and HZ + 4 or HZ - 4) + (i - (#names + 1) / 2) * 13
		local padX = x + (x < 0 and 7 or -7)
		local pad = lb("VotePad", 8, 0.4, 8, padX, 1, z, colors[i], "Neon")
		local plate = lb("VoteSign", 0.6, 4.5, 9.4, x + (x < 0 and 1.1 or -1.1), 2.5, z, "Institutional white", "SmoothPlastic")
		voteLabels[kind][name] = sign(plate, name .. "\n0 votes", x < 0 and "Right" or "Left", Color3.new(0.1, 0.1, 0.2))
		pad.Touched:connect(function(hit)
			local p = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
			if p and votes[kind][p] ~= name then
				votes[kind][p] = name
				refreshVotes()
				toClient(p, "toast", "You voted for " .. name .. "!", "green")
			end
		end)
	end
end
votePads("boat", BOAT_NAMES, BOAT_COLORS, HX - HW / 2 + 2, "VOTE: WHICH BOAT?")
votePads("theme", THEME_ORDER, THEME_COLORS, HX + HW / 2 - 2, "VOTE: MAP THEME")
local function winner(kind, names, default)
	local n = countVotes(kind)
	local best, top = {}, 0
	for _, name in ipairs(names) do
		local c = n[name] or 0
		if c > top then best, top = { name }, c elseif c == top and c > 0 then table.insert(best, name) end
	end
	if #best == 0 then return default end
	return pick(best)
end
-- clouds round the lobby
for i = 1, 14 do
	local a = i / 14 * math.pi * 2
	local r = math.random(110, 170)
	for k = 1, 3 do
		P(LOBBY, "Cloud", V(26, 14, 26) * (0.7 + math.random() * 0.5), L(math.cos(a) * r + k * 12, -20 + math.random(-10, 10), math.sin(a) * r), "Institutional white", "SmoothPlastic", { shape = "ball", tr = 0.25, nc = true })
	end
end

------------------------------------------------------------------ the theme's decorations (whole map)
local function decorate()
	themeDeco:ClearAllChildren()
	if theme == "Halloween" then
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			pumpkin(themeDeco, L(math.cos(a) * 66, 2, math.sin(a) * 66), 3)
		end
		for _, x in ipairs({ -20, -8, 8, 20 }) do pumpkin(themeDeco, L(x, 2.2, HZ - HD / 2 - 4), 2) end
		for i = 1, 8 do
			local web = P(themeDeco, "Cobweb", V(0.2, 6, 6), L(HX + (i % 2 == 0 and -1 or 1) * (HW / 2 - 1.5), HH - 3, HZ - HD / 2 + i * 5) * CFrame.Angles(math.rad(45), 0, 0), "Institutional white", "SmoothPlastic", { tr = 0.6, nc = true })
		end
		-- a ghost ship drifts past in the fog
		local g = model(themeDeco, "Ghost Ship")
		local at = SHIP_AT + V(-380, 0, -150)
		P(g, "GhostHull", V(24, 12, 90), CFrame.new(at + V(0, 2, 0)), "Institutional white", "SmoothPlastic", { tr = 0.65, nc = true })
		for k = -1, 1 do
			P(g, "GhostMast", V(1.2, 50, 1.2), CFrame.new(at + V(0, 30, k * 28)), "Institutional white", "SmoothPlastic", { tr = 0.6, nc = true })
			P(g, "GhostSail", V(26, 20, 0.4), CFrame.new(at + V(0, 34, k * 28)), "Institutional white", "Fabric", { tr = 0.7, nc = true })
		end
		light(P(g, "GhostLight", V(2, 2, 2), CFrame.new(at + V(0, 12, -40)), "Lime green", "Neon", { nc = true }), Color3.new(0.3, 1, 0.4), 40, 2)
	elseif theme == "Sunset" then
		local sun = P(themeDeco, "Sun", V(120, 120, 120), CFrame.new(SHIP_AT + V(0, 60, -1700)), "Neon orange", "Neon", { shape = "ball", nc = true })
		pcall(function() sun.Transparency = 0.2 end)
	end
end
local function setTheme(name)
	theme = THEMES[name] and name or "Normal"
	seaTheme.Value = theme
	applyLighting()
	decorate()
end
setTheme("Normal")

------------------------------------------------------------------ coins
local function stats(p)
	local ls = p:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("IntValue")
		ls.Name = "leaderstats"
		local c = Instance.new("IntValue")
		c.Name = "Coins"
		c.Parent = ls
		local w = Instance.new("IntValue")
		w.Name = "Wins"
		w.Parent = ls
		local s = Instance.new("IntValue")
		s.Name = "Survived"
		s.Parent = ls
		ls.Parent = p
	end
	return ls
end
local function addCoins(p, n)
	local c = stats(p):FindFirstChild("Coins")
	if c then c.Value = c.Value + n end
end
