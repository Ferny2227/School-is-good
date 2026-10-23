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
local function buildHog(parent, at, name)
	local m = model(parent, name or "Hog")
	local root = P(m, "Root", V(1, 1, 1), at, "Pink", nil, { tr = 1, nc = true })
	local pose = HogPose(at, 0, 0)
	for _, d in ipairs(HOG_PARTS) do
		P(m, d[1], d[2], pose[d[1]], d[4], d[5], { shape = d[6], nc = true })
	end
	return m, root
end

------------------------------------------------------------------ the lobby: a cabin in the woods
local LOBBY = V(-320, 0, 0)
local LW, LD, LH = 76, 56, 16
local lobby = model(WORLD, "Lobby")
local function lb(name, sx, sy, sz, x, y0, z, color, mat, opt, ry)
	return blk(lobby, name, sx, sy, sz, LOBBY.X + x, y0, LOBBY.Z + z, color, mat, opt, ry)
end
lb("Ground", 300, 2, 300, 0, -2, 0, "Earth green", "Grass")
lb("Floor", LW, 1, LD, 0, -1, 0, "Brown", "WoodPlanks")
lb("Rug", 30, 0.1, 20, 0, 0, 2, "Crimson", "Fabric")
for _, s in ipairs({ -1, 1 }) do
	lb("WallSide", 1, LH, LD, s * LW / 2, 0, 0, "Reddish brown", "Wood")
	lb("WallBack", LW / 2 - 7, LH, 1, s * (LW / 4 + 3.5), 0, LD / 2, "Reddish brown", "Wood")
	lb("WallFront", LW / 2 - 7, LH, 1, s * (LW / 4 + 3.5), 0, -LD / 2, "Reddish brown", "Wood")
	-- windows: dark glass showing the night outside
	for _, z in ipairs({ -14, 14 }) do
		lb("Window", 0.4, 5, 8, s * (LW / 2 - 0.3), 5, z, "Black", "Glass", { tr = 0.35 })
	end
end
lb("WallBackTop", 14, LH - 10, 1, 0, 10, LD / 2, "Reddish brown", "Wood")
lb("WallFrontTop", 14, LH - 10, 1, 0, 10, -LD / 2, "Reddish brown", "Wood")
lb("Ceiling", LW, 1, LD, 0, LH, 0, "Dark orange", "Wood")
for _, x in ipairs({ -24, 0, 24 }) do lb("Beam", 1.5, 1.5, LD, x, LH - 1.5, 0, "Reddish brown", "Wood") end
-- the board on the back wall: how to play and how the last round went
local board = lb("Board", 26, 10, 0.6, 0, 3, LD / 2 - 1, "Black", "SmoothPlastic")
local boardText = sign(board, "ESCAPE THE HOG", "Front", Color3.new(1, 0.85, 0.3))
local title = lb("Title", 30, 4, 0.6, 0, 11, -LD / 2 + 1.2, "Really black", "SmoothPlastic")
sign(title, "ESCAPE THE HOG", "Back", Color3.new(1, 0.45, 0.6))
-- warm lamps
for _, x in ipairs({ -24, 0, 24 }) do
	for _, z in ipairs({ -14, 14 }) do
		local lamp = lb("Lamp", 2, 1, 2, x, LH - 2.5, z, "Bright yellow", "Neon")
		light(lamp, Color3.new(1, 0.8, 0.5), 28, 1.2)
	end
end
-- a fireplace and a pig statue
lb("Fireplace", 10, 8, 3, -LW / 2 + 8, 0, LD / 2 - 2.5, "Dark stone grey", "Brick")
local fire = lb("Fire", 5, 2, 1, -LW / 2 + 8, 0.5, LD / 2 - 3.6, "Bright orange", "Neon")
light(fire, Color3.new(1, 0.5, 0.15), 22, 2)
buildHog(lobby, CFrame.new(LOBBY + V(LW / 2 - 8, HOG_UP + 0.5, LD / 2 - 6)) * CFrame.Angles(0, math.rad(200), 0), "HogStatue")
lb("StatueBase", 6, 0.5, 6, LW / 2 - 8, 0, LD / 2 - 6, "Dark stone grey", "Marble")
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "LobbySpawn"
spawnPad.Anchored = true
spawnPad.Size = V(8, 1, 8)
spawnPad.CFrame = CFrame.new(LOBBY + V(0, -0.4, -6))
spawnPad.Transparency = 1
spawnPad.CanCollide = false
pcall(function() spawnPad.Neutral = true end)
spawnPad.Parent = lobby
local function lobbySpot() return LOBBY + V(math.random(-16, 16), 3.5, math.random(-14, 6)) end

------------------------------------------------------------------ voting: the map and the monster
local MAP_NAMES = { "Hog Manor", "School" }
local MODE_NAMES = { "Bot Hog", "Player Hog" }
local votes = { map = {}, mode = {} }
local voteLabels = { map = {}, mode = {} }
local function countVotes(kind)
	local n = {}
	for p, name in pairs(votes[kind]) do
		if p.Parent then n[name] = (n[name] or 0) + 1 else votes[kind][p] = nil end
	end
	return n
end
local function refreshVotes()
	for _, kind in ipairs({ "map", "mode" }) do
		local n = countVotes(kind)
		local names = kind == "map" and MAP_NAMES or MODE_NAMES
		for i, name in ipairs(names) do
			local c = n[name] or 0
			voteLabels[kind][i].Text = name .. "\n" .. c .. (c == 1 and " vote" or " votes")
		end
	end
end
local function votePads(kind, names, colors, x, heading)
	local hs = lb("VoteHeading", 0.6, 3, 18, x + (x < 0 and 0.9 or -0.9), 7.5, 0, "Really black", "SmoothPlastic")
	sign(hs, heading, x < 0 and "Right" or "Left", Color3.new(1, 0.85, 0.3))
	for i, name in ipairs(names) do
		local z = (i - 1.5) * 12
		local padX = x + (x < 0 and 6 or -6)
		local pad = lb("VotePad", 8, 0.4, 8, padX, 0, z, colors[i], "Neon")
		local plate = lb("VoteSign", 0.6, 4.5, 9.4, x + (x < 0 and 1.1 or -1.1), 1.5, z, "Institutional white", "SmoothPlastic")
		voteLabels[kind][i] = sign(plate, name .. "\n0 votes", x < 0 and "Right" or "Left", Color3.new(0.1, 0.1, 0.2))
		pad.Touched:connect(function(hit)
			local p = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
			if p and votes[kind][p] ~= name then
				votes[kind][p] = name
				refreshVotes()
				say(p, "You voted for " .. name .. "!", "green")
			end
		end)
	end
end
votePads("map", MAP_NAMES, { "Bright orange", "Bright blue" }, -LW / 2, "VOTE: MAP")
votePads("mode", MODE_NAMES, { "Lime green", "Hot pink" }, LW / 2, "VOTE: THE HOG")
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
