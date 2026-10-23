-- ==== h10_lobby.lua
------------------------------------------------------------------ night time, a bit of fog
pcall(function()
	Lighting.TimeOfDay = "21:30:00"
	Lighting.Ambient = Color3.new(0.32, 0.3, 0.36)
	Lighting.OutdoorAmbient = Color3.new(0.25, 0.25, 0.32)
	Lighting.Brightness = 0.6
	Lighting.FogColor = Color3.new(0.05, 0.05, 0.1)
	Lighting.FogStart = 60
	Lighting.FogEnd = 420
end)
local WORLD = model(workspace, "Hog World")
local STATE = { phase = "lobby", left = 0 }

------------------------------------------------------------------ the hog (the shape is in src/shared/HogRig.lua)
local function buildHog(parent, at, name, swing, smash)
	local m = model(parent, name or "Hog")
	local root = P(m, "Root", V(1, 1, 1), at, "Pink", nil, { tr = 1, nc = true })
	local pose = HogPose(at, swing or 0, smash or 0)
	for _, d in ipairs(HOG_PARTS) do
		P(m, d[1], d[2], pose[d[1]], d[4], d[5], { shape = d[6], nc = true })
	end
	return m, root
end

------------------------------------------------------------------ the lobby is a menu on the screen (like Piggy)
-- Behind the menu, every player's camera looks down a dark, dirty hallway where the Hog stands with its bat raised
-- (and another one lurks at the far end). Players' characters wait in a closed room nobody sees.
local SCENE = V(-320, 0, -220)
local scene = model(WORLD, "MenuScene")
local function sb(name, sx, sy, sz, x, y0, z, color, mat, opt)
	return blk(scene, name, sx, sy, sz, SCENE.X + x, y0, SCENE.Z + z, color, mat, opt)
end
local HL, HWD, HH = 110, 18, 12
sb("Floor", HWD, 1, HL, 0, -1, -HL / 2 + 8, "Brown", "WoodPlanks")
sb("Ceiling", HWD, 1, HL, 0, HH, -HL / 2 + 8, "Dark stone grey", "SmoothPlastic")
for _, side in ipairs({ -1, 1 }) do
	sb("Wall", 1, HH, HL, side * HWD / 2, 0, -HL / 2 + 8, "Olive", "SmoothPlastic")
	sb("Skirting", 0.6, 1.4, HL, side * (HWD / 2 - 0.6), 0, -HL / 2 + 8, "Brown", "Wood")
	for z = -12, -HL + 14, -22 do
		sb("Door", 0.4, 8, 5, side * (HWD / 2 - 0.6), 0, z + (side > 0 and 8 or 0), "Reddish brown", "Wood")
		sb("Frame", 0.6, 3, 4, side * (HWD / 2 - 0.6), 5, z - 9 + (side > 0 and 4 or 0), "Brick yellow", "SmoothPlastic", { tr = 0.2 })
	end
end
sb("BackWall", HWD, HH, 1, 0, 0, -HL + 8, "Black", "SmoothPlastic")
for z = -6, -HL + 14, -20 do
	local lamp = sb("Lamp", 2, 0.4, 2, 0, HH - 0.4, z, "Olive", "Neon")
	light(lamp, Color3.new(0.75, 0.8, 0.45), 26, 0.7)
end
local hog1 = buildHog(scene, CFrame.new(SCENE + V(-3, HOG_UP, -16)) * CFrame.Angles(0, math.rad(160), 0), "MenuHog", 0, 0.55)
light(hog1:FindFirstChild("PupilL"), Color3.new(1, 0.1, 0.1), 12, 2)
buildHog(scene, CFrame.new(SCENE + V(3, HOG_UP, -62)) * CFrame.Angles(0, math.rad(200), 0), "MenuHog2", 0.3, 0)
local camPart = sb("MenuCam", 1, 1, 1, 1.5, 5.5, 2, "White", nil, { tr = 1, nc = true })
local lookPart = sb("MenuLook", 1, 1, 1, -1, 5, -30, "White", nil, { tr = 1, nc = true })

-- the waiting room (closed, out of sight)
local LOBBY = V(-320, 0, 0)
local lobby = model(WORLD, "Lobby")
local function lb(name, sx, sy, sz, x, y0, z, color, mat, opt)
	return blk(lobby, name, sx, sy, sz, LOBBY.X + x, y0, LOBBY.Z + z, color, mat, opt)
end
lb("Floor", 40, 1, 40, 0, -1, 0, "Brown", "WoodPlanks")
lb("Ceiling", 40, 1, 40, 0, 12, 0, "Dark stone grey", "SmoothPlastic")
for _, s in ipairs({ -1, 1 }) do
	lb("Wall", 1, 12, 40, s * 20, 0, 0, "Reddish brown", "Wood")
	lb("Wall", 40, 12, 1, 0, 0, s * 20, "Reddish brown", "Wood")
end
light(lb("Lamp", 3, 0.5, 3, 0, 11.5, 0, "Bright yellow", "Neon"), Color3.new(1, 0.85, 0.6), 40, 1)
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "LobbySpawn"
spawnPad.Anchored = true
spawnPad.Size = V(8, 1, 8)
spawnPad.CFrame = CFrame.new(LOBBY + V(0, -0.4, 0))
spawnPad.Transparency = 1
spawnPad.CanCollide = false
pcall(function() spawnPad.Neutral = true end)
spawnPad.Parent = lobby
local function lobbySpot() return LOBBY + V(math.random(-12, 12), 3.5, math.random(-12, 12)) end
local boardText = { Text = "" }       -- (the last round's result; shown on the menu)

------------------------------------------------------------------ voting (on the menu screen): the map and the Hog
local MAP_NAMES = { "Hog Manor", "School" }
local MODE_NAMES = { "Bot Hog", "Player Hog" }
local votes = { map = {}, mode = {} }
local ready = {}            -- players who pressed PLAY (they're in the next round)
local function countVotes(kind)
	local n = {}
	for p, name in pairs(votes[kind]) do
		if p.Parent then n[name] = (n[name] or 0) + 1 else votes[kind][p] = nil end
	end
	return n
end
local function refreshVotes()
	local out = {}
	for _, kind in ipairs({ "map", "mode" }) do
		local n = countVotes(kind)
		local names = kind == "map" and MAP_NAMES or MODE_NAMES
		out[kind] = {}
		for i, name in ipairs(names) do out[kind][i] = n[name] or 0 end
	end
	toAll("votes", out.map, out.mode)
end
local function vote(p, kind, name)
	local names = kind == "map" and MAP_NAMES or kind == "mode" and MODE_NAMES
	if not names then return end
	for _, n in ipairs(names) do
		if n == name then
			votes[kind][p] = name
			refreshVotes()
			return
		end
	end
end
local function winner(kind, names)
	local n = countVotes(kind)
	local best, top = {}, 0
	for _, name in ipairs(names) do
		local c = n[name] or 0
		if c > top then best, top = { name }, c elseif c == top and c > 0 then table.insert(best, name) end
	end
	if #best == 0 then return pick(names) end
	return pick(best)
end

------------------------------------------------------------------ coins and escapes (saved between visits)
local store
pcall(function() store = game:GetService("DataStoreService"):GetDataStore("EscapeTheHog1") end)
local function idOf(p) local ok, id = pcall(function() return p.UserId end) return ok and id or p.userId end
local function stats(p)
	local ls = p:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("IntValue")
		ls.Name = "leaderstats"
		for _, n in ipairs({ "Coins", "Escapes" }) do
			local v = Instance.new("IntValue")
			v.Name = n
			v.Value = 0
			v.Parent = ls
		end
		ls.Parent = p
	end
	return ls
end
local function loadStats(p)
	if not store then return end
	spawn(function()
		local ok, v = pcall(function() return store:GetAsync("u" .. idOf(p)) end)
		if ok and type(v) == "table" then
			local ls = stats(p)
			if tonumber(v.c) then ls.Coins.Value = math.max(ls.Coins.Value, tonumber(v.c)) end
			if tonumber(v.e) then ls.Escapes.Value = math.max(ls.Escapes.Value, tonumber(v.e)) end
		end
	end)
end
local function saveStats(p)
	local ls = p:FindFirstChild("leaderstats")
	if not store or not ls then return end
	local key, data = "u" .. idOf(p), { c = ls.Coins.Value, e = ls.Escapes.Value }
	spawn(function() pcall(function() store:SetAsync(key, data) end) end)
end
local function addCoins(p, n)
	local ls = stats(p)
	ls.Coins.Value = ls.Coins.Value + n
end
