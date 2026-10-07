-- ShooterMain (Script)
-- Location: ServerScriptService > ShooterMain
-- SHOOTER ARENA v6: Free For All, Team Deathmatch, Team Elimination, King of the Hill and Gun Game
-- on Nuketown, Skyline Mayhem, Desert Outpost, Frozen Harbor and Timber Forest.
--   * Match loop: lobby + voting (map, mode, weather, bots, your team) -> match -> results -> lobby ...
--   * Teams (v6): pick RED / BLUE / AUTO in the lobby (buttons or the team pads), T to switch in a match.
--     Bots always even out the teams.
--   * Weather (v6): clear, rain, thunderstorm, snow, fog, night (flashlights), sandstorm.
--   * Guns: the client sends "fire" with where you aim; the server checks your ammo
--     and fire rate, shoots the ray(s), deals damage (headshots x), draws tracers, sends hitmarkers.
--   * Reload, knife, frag grenades, rockets, killstreaks (UAV, Armor, Airstrike, NUKE).
--   * XP and levels (saved), guns unlock by level, loadouts, kill feed, scoreboard data,
--     medals (v6: double kill, revenge, longshot ...), assists, ammo drops.
--   * Admin (ONLY asdasda): chat commands, see the README.
-- Talks to clients through ReplicatedStorage.SRemote and the values in ReplicatedStorage.Game.
-- Plain 2016-style Lua (wait / spawn / delay / :connect). Never wait inside pcall.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RS = game:GetService("ReplicatedStorage")

local C = require(script.Parent:WaitForChild("SConfig"))
local Guns = require(script.Parent:WaitForChild("SGuns"))
local Maps = require(script.Parent:WaitForChild("SMaps"))

pcall(function()
	Players.CharacterAutoLoads = false
end)

local world = Maps.buildAll()
local SS = game:GetService("ServerStorage")
local fx = Instance.new("Model")
fx.Name = "ShooterFX"
fx.Parent = game.Workspace

local gunByName = {}
for _, g in ipairs(C.Guns) do
	gunByName[g.name] = g
end
local function mapConfig(id)
	for _, m in ipairs(C.Maps) do
		if m.id == id then
			return m
		end
	end
	return nil
end

------------------------------------------------------------------
-- shared state for the clients (ReplicatedStorage.Game)
------------------------------------------------------------------
local remote = RS:FindFirstChild("SRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "SRemote"
	remote.Parent = RS
end
local G = Instance.new("Folder")
G.Name = "Game"
local function val(class, name, v)
	local o = Instance.new(class)
	o.Name = name
	o.Value = v
	o.Parent = G
	return o
end
local V = {
	state = val("StringValue", "State", "intermission"), -- intermission / playing / ended
	mode = val("StringValue", "Mode", "ffa"),
	modeName = val("StringValue", "ModeName", "FREE FOR ALL"),
	map = val("StringValue", "Map", "nuketown"),
	mapName = val("StringValue", "MapName", "NUKETOWN"),
	time = val("NumberValue", "TimeLeft", 0),
	red = val("NumberValue", "RedScore", 0),
	blue = val("NumberValue", "BlueScore", 0),
	limit = val("NumberValue", "ScoreLimit", 0),
	info = val("StringValue", "Info", ""),
	leader = val("StringValue", "Leader", ""),
	round = val("NumberValue", "Round", 0),
	botLevel = val("StringValue", "BotLevel", C.DefaultBotLevel),
	-- v6
	weather = val("StringValue", "Weather", "clear"),
	weatherName = val("StringValue", "WeatherName", "CLEAR"),
	hillPos = val("Vector3Value", "HillPos", Vector3.new(0, -1000, 0)),
	hillR = val("NumberValue", "HillR", 0),
	hillOwner = val("StringValue", "HillOwner", ""),
}
local function weatherDef()
	return C.Weather[V.weather.Value] or C.Weather.clear
end
-- lists for the vote screen: "id|name" per line (modes: "id|name|info")
do
	local maps, modes, weather = {}, {}, {}
	for _, m in ipairs(C.Maps) do
		if world.maps[m.id] then
			table.insert(maps, m.id .. "|" .. m.name)
		end
	end
	for _, id in ipairs(C.ModeOrder) do
		local md = C.Modes[id]
		table.insert(modes, id .. "|" .. md.name .. "|" .. md.info)
	end
	for _, id in ipairs(C.WeatherOrder) do
		table.insert(weather, id .. "|" .. (C.Weather[id] and C.Weather[id].name or "RANDOM"))
	end
	val("StringValue", "MapList", table.concat(maps, "\n"))
	val("StringValue", "ModeList", table.concat(modes, "\n"))
	val("StringValue", "WeatherList", table.concat(weather, "\n"))
	val("NumberValue", "GunGameGuns", #C.GunGameLadder)
end
local votes = Instance.new("Folder")
votes.Name = "Votes"
votes.Parent = G
local voteValues = {}
for _, m in ipairs(C.Maps) do
	local v = Instance.new("IntValue")
	v.Name = "map_" .. m.id
	v.Parent = votes
	voteValues["map_" .. m.id] = v
end
for _, id in ipairs(C.ModeOrder) do
	local v = Instance.new("IntValue")
	v.Name = "mode_" .. id
	v.Parent = votes
	voteValues["mode_" .. id] = v
end
for _, id in ipairs(C.BotLevelOrder) do
	local v = Instance.new("IntValue")
	v.Name = "bots_" .. id
	v.Parent = votes
	voteValues["bots_" .. id] = v
end
for _, id in ipairs(C.WeatherOrder) do
	local v = Instance.new("IntValue")
	v.Name = "weather_" .. id
	v.Parent = votes
	voteValues["weather_" .. id] = v
end
-- the gun list for the loadout menu: "name|slot|level" per line
local gunList = {}
for _, g in ipairs(C.Guns) do
	-- name|slot|level|damage|rpm|range|mag|walk|pellets|look
	table.insert(gunList, g.name .. "|" .. g.slot .. "|" .. g.level .. "|" .. g.damage .. "|" .. g.rpm .. "|" .. g.range .. "|" .. g.mag .. "|" .. g.walk .. "|" .. (g.pellets or 1) .. "|" .. g.look)
end
val("StringValue", "GunList", table.concat(gunList, "\n"))
G.Parent = RS

------------------------------------------------------------------
-- PICTURES for the menus (v5): a side view of every gun and a top view of every map,
-- made of rectangles. Stored as text in Game.Pics so the client can draw them with Frames.
------------------------------------------------------------------
do
	local pics = Instance.new("Folder")
	pics.Name = "Pics"
	pics.Parent = G
	local function n2(x)
		return string.format("%.2f", x)
	end
	local function colorOf(p)
		local c = p.BrickColor.Color
		return math.floor(c.r * 255) .. "," .. math.floor(c.g * 255) .. "," .. math.floor(c.b * 255)
	end
	-- the 8 corners of a part, in world space
	local function corners(p)
		local out = {}
		local h = p.Size / 2
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					table.insert(out, p.CFrame:pointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)))
				end
			end
		end
		return out
	end
	local function walk(obj, fn)
		for _, c in ipairs(obj:GetChildren()) do
			if c:IsA("BasePart") then
				fn(c)
			end
			walk(c, fn)
		end
	end

	-- GUNS: side view (forward = right, up = up). "z0,y0,z1,y1,r,g,b;..."
	for _, def in ipairs(C.Guns) do
		local ok = pcall(function()
			local tool = Guns.tool(def)
			local handle = tool:FindFirstChild("Handle")
			local rects = {}
			walk(tool, function(p)
				if p.Transparency < 0.8 then
					local z0, y0, z1, y1 = 1e9, 1e9, -1e9, -1e9
					for _, w in ipairs(corners(p)) do
						local l = handle.CFrame:pointToObjectSpace(w)
						z0, z1 = math.min(z0, -l.Z), math.max(z1, -l.Z)
						y0, y1 = math.min(y0, l.Y), math.max(y1, l.Y)
					end
					local depth = handle.CFrame:pointToObjectSpace(p.Position).X
					table.insert(rects, { d = depth, s = n2(z0) .. "," .. n2(y0) .. "," .. n2(z1) .. "," .. n2(y1) .. "," .. colorOf(p) })
				end
			end)
			table.sort(rects, function(a, b)
				return a.d < b.d
			end)
			local out = {}
			for _, r in ipairs(rects) do
				table.insert(out, r.s)
			end
			local v = Instance.new("StringValue")
			v.Name = "Gun_" .. def.name
			v.Value = table.concat(out, ";")
			v.Parent = pics
			tool:Destroy()
		end)
		if not ok then
			print("[Shooter] no picture for " .. def.name)
		end
	end

	-- MAPS: top view. first "minX,minZ,maxX,maxZ", then "x0,z0,x1,z1,r,g,b" (lowest first),
	-- then spawns "S,x,z,team"
	for id, m in pairs(world.maps) do
		local rects = {}
		walk(m.folder, function(p)
			local name = p.Name
			if p.Transparency < 0.9 and name ~= "Boundary" and string.sub(name, 1, 4) ~= "City" and string.sub(name, 1, 3) ~= "Sea" and string.sub(name, 1, 2) ~= "Bg" then
				local x0, z0, x1, z1, top = 1e9, 1e9, -1e9, -1e9, -1e9
				for _, w in ipairs(corners(p)) do
					x0, x1 = math.min(x0, w.X), math.max(x1, w.X)
					z0, z1 = math.min(z0, w.Z), math.max(z1, w.Z)
					top = math.max(top, w.Y)
				end
				local area = (x1 - x0) * (z1 - z0)
				-- (v6) a long thin part turned at an angle (a path, a fence) would draw as a huge box: skip it
				local s = p.Size
				local face = math.max(s.X * s.Z, s.X * s.Y, s.Y * s.Z)
				if area >= 6 and top > m.killY + 5 and area <= face * 3 then
					table.insert(rects, { x0 = x0, z0 = z0, x1 = x1, z1 = z1, top = top, area = area, c = colorOf(p) })
				end
			end
		end)
		table.sort(rects, function(a, b)
			return a.area > b.area
		end)
		while #rects > 450 do
			table.remove(rects)
		end
		table.sort(rects, function(a, b)
			return a.top < b.top
		end)
		local bx0, bz0, bx1, bz1 = 1e9, 1e9, -1e9, -1e9
		for _, r in ipairs(rects) do
			bx0, bz0, bx1, bz1 = math.min(bx0, r.x0), math.min(bz0, r.z0), math.max(bx1, r.x1), math.max(bz1, r.z1)
		end
		local out = { n2(bx0) .. "," .. n2(bz0) .. "," .. n2(bx1) .. "," .. n2(bz1) }
		for _, r in ipairs(rects) do
			table.insert(out, n2(r.x0) .. "," .. n2(r.z0) .. "," .. n2(r.x1) .. "," .. n2(r.z1) .. "," .. r.c)
		end
		for _, team in ipairs({ "red", "blue" }) do
			for _, cf in ipairs(m.spawns[team] or {}) do
				table.insert(out, "S," .. n2(cf.p.X) .. "," .. n2(cf.p.Z) .. "," .. team)
			end
		end
		local v = Instance.new("StringValue")
		v.Name = "Map_" .. id
		v.Value = table.concat(out, ";")
		v.Parent = pics
	end
end

------------------------------------------------------------------
-- (v6) only the map being played is in the Workspace; the others wait in ServerStorage.
-- Slow computers (Chromebooks) only have to load and draw one map.
------------------------------------------------------------------
local function showMap(id)
	for mid, m in pairs(world.maps) do
		pcall(function()
			m.folder.Parent = (mid == id) and game.Workspace or SS
		end)
	end
end
showMap("")

------------------------------------------------------------------
-- teams (Red / Blue) using the Teams service when it exists
------------------------------------------------------------------
local TEAM_COLOR = { red = BrickColor.new("Bright red"), blue = BrickColor.new("Bright blue") }
pcall(function()
	local teams = game:GetService("Teams")
	for _, t in ipairs({ { "Red", "Bright red" }, { "Blue", "Bright blue" } }) do
		local team = Instance.new("Team")
		team.Name = t[1]
		team.TeamColor = BrickColor.new(t[2])
		team.AutoAssignable = false
		team.Parent = teams
	end
end)

------------------------------------------------------------------
-- player data
------------------------------------------------------------------
local pd = {} -- [player] = { xp, kills, deaths, wins, primary, secondary, team, streak, ... }
local store = nil
pcall(function()
	store = game:GetService("DataStoreService"):GetDataStore("ShooterArena_v1")
end)

local function levelOf(xp)
	return math.min(C.MaxLevel, math.floor(xp / C.XPPerLevel) + 1)
end

local function isAdmin(p)
	return p ~= nil and string.lower(p.Name) == "asdasda"
end

local function setVal(parent, class, name, value)
	local o = parent:FindFirstChild(name)
	if not o then
		o = Instance.new(class)
		o.Name = name
		o.Parent = parent
	end
	o.Value = value
	return o
end

local function sync(p)
	local d = pd[p]
	if not d then
		return
	end
	local ls = p:FindFirstChild("leaderstats")
	if ls then
		setVal(ls, "IntValue", "Kills", d.mKills)
		setVal(ls, "IntValue", "Deaths", d.mDeaths)
		setVal(ls, "IntValue", "Level", levelOf(d.xp))
	end
	local sd = p:FindFirstChild("SData")
	if sd then
		local lv = levelOf(d.xp)
		setVal(sd, "IntValue", "Level", lv)
		setVal(sd, "NumberValue", "XP", d.xp - (lv - 1) * C.XPPerLevel)
		setVal(sd, "NumberValue", "XPNext", C.XPPerLevel)
		setVal(sd, "StringValue", "Primary", d.primary)
		setVal(sd, "StringValue", "Secondary", d.secondary)
		setVal(sd, "StringValue", "Team", d.team or "")
		setVal(sd, "IntValue", "Streak", d.streak)
		setVal(sd, "IntValue", "Score", d.mScore)
		setVal(sd, "NumberValue", "SpeedBonus", d.speedBonus or 0)
		setVal(sd, "IntValue", "TotalKills", d.kills)
		-- your settings (v5)
		local st = d.set or {}
		setVal(sd, "NumberValue", "SetFOV", st.fov or 70)
		setVal(sd, "StringValue", "SetView", st.view or "first")
		setVal(sd, "StringValue", "SetCross", st.cross or "White")
		setVal(sd, "IntValue", "SetZoom", st.zoom or 2)
		setVal(sd, "BoolValue", "SetHitSound", st.hitsound ~= false)
		setVal(sd, "BoolValue", "SetMinimap", st.minimap ~= false)
		setVal(sd, "NumberValue", "SetSens", st.sens or 1)
		setVal(sd, "BoolValue", "SetAimToggle", st.aimtoggle == true)
		setVal(sd, "StringValue", "SetShoulder", st.shoulder or "right")
		setVal(sd, "BoolValue", "SetWeatherFX", st.wfx ~= false)
		-- v6
		setVal(sd, "StringValue", "TeamPref", d.teamPref or "auto")
		setVal(sd, "IntValue", "GG", d.gg or 1)
	end
end

local function save(p)
	local d = pd[p]
	if not store or not d or not d.loaded then
		return
	end
	pcall(function()
		store:SetAsync("p_" .. p.userId, { xp = d.xp, kills = d.kills, deaths = d.deaths, wins = d.wins, primary = d.primary, secondary = d.secondary, set = d.set })
	end)
end

local function toAll(...)
	remote:FireAllClients(...)
end
local function toOne(p, ...)
	local args = { ... }
	local n = select("#", ...)
	pcall(function()
		remote:FireClient(p, unpack(args, 1, n))
	end)
end

local function addXP(p, amount, why)
	local d = pd[p]
	if not d then
		return
	end
	local before = levelOf(d.xp)
	d.xp = d.xp + amount
	local after = levelOf(d.xp)
	toOne(p, "xp", amount, why or "")
	if after > before then
		toOne(p, "levelup", after)
		local unlocked = {}
		for _, g in ipairs(C.Guns) do
			if g.level > before and g.level <= after then
				table.insert(unlocked, g.name)
			end
		end
		if #unlocked > 0 then
			toOne(p, "big", "UNLOCKED: " .. table.concat(unlocked, ", "), Color3.new(1, 0.85, 0.3))
		end
		toAll("feed", "", p.Name .. " reached LEVEL " .. after .. "!", "", false, Color3.new(1, 0.85, 0.3))
	end
	sync(p)
end

------------------------------------------------------------------
-- helpers
------------------------------------------------------------------
-- BOTS are tables { isBot = true, Name, team, model, ... }; most helpers work for players and bots
local bots = {}       -- every bot in the match
local botByModel = {} -- [bot model] = bot
local syncBot         -- (defined in the BOTS section) updates a bot's scoreboard values
local function isBot(e)
	return type(e) == "table" and e.isBot == true
end
local function charOf(p)
	if isBot(p) then
		return p.model
	end
	return p and p.Character
end
local function humOf(p)
	local c = charOf(p)
	return c and c:FindFirstChild("Humanoid")
end
local function rootOf(p)
	local c = charOf(p)
	return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end
local function aliveP(p)
	local h = humOf(p)
	return h ~= nil and h.Health > 0
end

local mode = C.Modes.ffa
local currentMap = world.maps.nuketown
local inMatch = {} -- [player] = true when they play in the current match
local function inMatchOf(p)
	return inMatch[p] == true
end
local forceEnd = false -- end the match now
local skipWait = false -- start the match now

local function enemies(a, b)
	if a == b then
		return false
	end
	if not mode.teams then
		return true
	end
	local da = isBot(a) and a or pd[a]
	local db = isBot(b) and b or pd[b]
	return not (da and db and da.team and da.team == db.team)
end
-- everyone in the match: players and bots
local function combatants()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(out, p)
	end
	for _, b in ipairs(bots) do
		table.insert(out, b)
	end
	return out
end

local function teamColor3(p)
	local d = isBot(p) and p or pd[p]
	if mode.teams and d and d.team == "red" then
		return Color3.new(1, 0.35, 0.35)
	elseif mode.teams and d and d.team == "blue" then
		return Color3.new(0.4, 0.6, 1)
	end
	return Color3.new(1, 1, 1)
end

local TEAM_NAME = { red = "RED", blue = "BLUE", auto = "AUTO" }
local function teamRGB(team)
	if team == "red" then
		return Color3.new(1, 0.35, 0.35)
	elseif team == "blue" then
		return Color3.new(0.4, 0.6, 1)
	end
	return Color3.new(1, 1, 1)
end

-- (v6) NIGHT: a flashlight on your head
local function addFlashlight(head)
	pcall(function()
		if head:FindFirstChild("Flashlight") then
			return
		end
		local s = Instance.new("SpotLight")
		s.Name = "Flashlight"
		s.Range = 55
		s.Angle = 50
		s.Brightness = 2.5
		s.Color = Color3.new(1, 0.95, 0.8)
		s.Face = Enum.NormalId.Front
		s.Parent = head
	end)
end

local function sound(parent, id, vol, pitch)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol or 0.3
	s.Pitch = pitch or 1
	s.Parent = parent
	pcall(function()
		s:Play()
	end)
	Debris:AddItem(s, 2)
end

local function newPart(name, size, color, mat, cf)
	local p = Instance.new("Part")
	p.Name = name
	pcall(function()
		p.FormFactor = Enum.FormFactor.Custom
	end)
	p.Size = size
	p.BrickColor = BrickColor.new(color)
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if mat then
		pcall(function()
			p.Material = Enum.Material[mat]
		end)
	end
	if cf then
		p.CFrame = cf
	end
	return p
end

-- cast a ray, ignoring the shooter and effects. returns hit part, position
local function cast(origin, dir, ignore)
	local ray = Ray.new(origin, dir)
	local hit, pos
	local ok = pcall(function()
		hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
	end)
	if not ok then
		hit, pos = game.Workspace:FindPartOnRay(ray, ignore[1])
	end
	return hit, pos or (origin + dir)
end

-- the player (and humanoid) a part belongs to
local function victimOf(part)
	if not part then
		return nil
	end
	local model = part.Parent
	local hum = model and model:FindFirstChild("Humanoid")
	if not hum and model and model.Parent then
		model = model.Parent -- hats / tools
		hum = model:FindFirstChild("Humanoid")
	end
	if not hum then
		return nil
	end
	return Players:GetPlayerFromCharacter(model) or botByModel[model], hum
end

------------------------------------------------------------------
-- DAMAGE and KILLS
------------------------------------------------------------------
local lastHit = {} -- [victim player] = { by = player, gun = name, head = bool, at = tick() }
local dmgBy = {} -- [victim] = { [attacker] = { amount = damage done, at = tick() } } (v6: assists)
local spawnedAt = {} -- [player] = when the current body spawned (no fall-death right after)
local regenAt = {}

local function damage(attacker, victim, hum, amount, gunName, head)
	if not hum or hum.Health <= 0 then
		return false
	end
	if attacker and victim and attacker ~= victim and not enemies(attacker, victim) then
		return false -- no team kills
	end
	if victim then
		lastHit[victim] = { by = attacker, gun = gunName, head = head, at = tick() }
		regenAt[victim] = tick() + 5
	end
	local before = hum.Health
	hum:TakeDamage(amount)
	local killed = hum.Health <= 0
	if victim and attacker and attacker ~= victim then
		local t = dmgBy[victim]
		if not t then
			t = {}
			dmgBy[victim] = t
		end
		local e = t[attacker] or { amount = 0, at = 0 }
		e.amount = e.amount + math.max(0, before - hum.Health)
		e.at = tick()
		t[attacker] = e
	end
	if attacker and attacker ~= victim and not isBot(attacker) then
		toOne(attacker, "hit", head and true or false, killed, math.floor(amount))
	end
	if victim and not isBot(victim) then
		toOne(victim, "hurt", attacker and attacker.Name or "", rootOf(attacker) and rootOf(attacker).Position or nil)
	end
	return killed
end

-- an explosion: damage falls off with distance; you also hurt yourself (half)
local function explode(pos, radius, dmg, attacker, gunName)
	local ball = newPart("Boom", Vector3.new(2, 2, 2), "Neon orange", "Neon", CFrame.new(pos))
	ball.Shape = Enum.PartType.Ball
	ball.Parent = fx
	spawn(function()
		for i = 1, 6 do
			local d = radius * 0.35 * i
			ball.Size = Vector3.new(d, d, d)
			ball.CFrame = CFrame.new(pos)
			ball.Transparency = i / 7
			wait(0.04)
		end
		ball:Destroy()
	end)
	sound(ball, C.Sounds.boom, 0.4, 0.5)
	for _, p in ipairs(combatants()) do
		local r, h = rootOf(p), humOf(p)
		if r and h and h.Health > 0 then
			local dist = (r.Position - pos).magnitude
			if dist < radius then
				local amount = dmg * (1 - dist / radius * 0.7)
				if p == attacker then
					amount = amount * 0.5
				end
				if p == attacker or enemies(attacker, p) then
					damage(attacker, p, h, amount, gunName, false)
					local bv = Instance.new("BodyVelocity")
					pcall(function()
						bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
					end)
					pcall(function()
						bv.maxForce = Vector3.new(1e5, 1e5, 1e5)
					end)
					local away = r.Position - pos
					away = away.magnitude > 0.1 and away.unit or Vector3.new(0, 1, 0)
					bv.Velocity = away * 40 + Vector3.new(0, 30, 0)
					bv.Parent = r
					Debris:AddItem(bv, 0.2)
				end
			end
		end
	end
end

------------------------------------------------------------------
-- killstreaks
------------------------------------------------------------------
local uavUntil = {}
local killstreak -- defined below
local ggUpgrade -- (GUN GAME) gives the next gun, defined below
local ggWinner = nil -- (GUN GAME) who got a kill with the last gun
local firstBlood = false -- has anyone got a kill this match?

local function onKill(killer, victim, gunName, head, dist, victimStreak)
	local kd = isBot(killer) and killer or pd[killer]
	if not kd then
		return
	end
	local vd = isBot(victim) and victim or pd[victim]
	kd.kills = kd.kills + 1
	kd.mKills = kd.mKills + 1
	kd.streak = kd.streak + 1
	kd.mScore = kd.mScore + 100 + (head and 50 or 0)
	if mode.id == "tdm" and kd.team == "red" then
		V.red.Value = V.red.Value + 1
	elseif mode.id == "tdm" and kd.team == "blue" then
		V.blue.Value = V.blue.Value + 1
	end
	-- MEDALS (v6)
	local now = tick()
	local medals = {}
	local function medal(id)
		if C.Medals[id] then
			table.insert(medals, C.Medals[id])
		end
	end
	if not firstBlood then
		firstBlood = true
		medal("firstblood")
	end
	if now - (kd.lastKillAt or -100) <= C.MultiKillTime then
		kd.multi = (kd.multi or 1) + 1
	else
		kd.multi = 1
	end
	kd.lastKillAt = now
	if kd.multi == 2 then
		medal("double")
	elseif kd.multi == 3 then
		medal("triple")
	elseif kd.multi >= 4 then
		medal("multi")
	end
	if dist and dist >= C.LongshotDistance then
		medal("longshot")
	end
	if kd.lastKiller ~= nil and kd.lastKiller == victim then
		medal("revenge")
		kd.lastKiller = nil
	end
	if (victimStreak or 0) >= 5 then
		medal("shutdown")
	end
	if gunName == "Knife" then
		medal("stabbed")
	end
	if vd then
		vd.lastKiller = killer
	end
	-- GUN GAME (v6): the killer gets the next gun; knifed = the victim goes back one
	if mode.id == "gungame" then
		if gunName == "Knife" and vd and (vd.gg or 1) > 1 then
			vd.gg = vd.gg - 1
			if isBot(victim) then
				ggUpgrade(victim)
			else
				toOne(victim, "big", "HUMILIATED! Knifed by " .. killer.Name .. ", you lost a gun", Color3.new(1, 0.4, 0.4))
				sync(victim)
			end
		end
		kd.gg = (kd.gg or 1) + 1
		if kd.gg > #C.GunGameLadder then
			kd.gg = #C.GunGameLadder
			ggWinner = killer
			forceEnd = true
		else
			ggUpgrade(killer)
			if kd.gg == #C.GunGameLadder then
				toAll("feed", "", killer.Name .. " is on the LAST GUN!", "", false, Color3.new(1, 0.6, 0.2))
			end
		end
	end
	if isBot(killer) then
		syncBot(killer)
		return
	end
	local bonus = 0
	for _, m in ipairs(medals) do
		bonus = bonus + m.xp
		toOne(killer, "medal", m.name, m.xp)
	end
	kd.mScore = kd.mScore + bonus
	toOne(killer, "killed", victim.Name, head and true or false)
	addXP(killer, C.XPKill + (head and C.XPHeadshot or 0) + bonus, head and "HEADSHOT" or "KILL")
	if not mode.noStreaks then
		for _, ks in ipairs(C.Killstreaks) do
			if kd.streak == ks.kills then
				killstreak(killer, ks)
			end
		end
	end
	if kd.streak == 5 or kd.streak == 10 or kd.streak == 15 or kd.streak == 20 then
		toAll("feed", "", killer.Name .. " is on a " .. kd.streak .. " KILL STREAK!", "", false, Color3.new(1, 0.6, 0.2))
	end
	sync(killer)
end

local dropPickup -- (v6) an ammo box where someone died, defined below

local function onDied(victim)
	local vd = isBot(victim) and victim or pd[victim]
	if not vd or vd.dead then
		return
	end
	vd.dead = true
	vd.deaths = vd.deaths + 1
	vd.mDeaths = vd.mDeaths + 1
	local victimStreak = vd.streak
	vd.streak = 0
	vd.speedBonus = 0
	local lh = lastHit[victim]
	local killer = nil
	if lh and lh.by and tick() - lh.at < 10 and lh.by ~= victim then
		if (isBot(lh.by) and not lh.by.removed) or (not isBot(lh.by) and lh.by.Parent) then
			killer = lh.by
		end
	end
	local vr = rootOf(victim)
	local deathPos = vr and vr.Position
	if killer then
		local kr = rootOf(killer)
		local dist = (kr and vr) and math.floor((kr.Position - vr.Position).magnitude) or 0
		onKill(killer, victim, lh.gun, lh.head, dist, victimStreak)
		toAll("feed", killer.Name, victim.Name, lh.gun or "", lh.head and true or false, teamColor3(killer), teamColor3(victim))
		local kh = humOf(killer)
		if not isBot(victim) then
			toOne(victim, "died", killer.Name, lh.gun or "", dist, kh and math.floor(kh.Health) or 0)
		end
	else
		toAll("feed", "", victim.Name .. " died", "", false, Color3.new(0.8, 0.8, 0.8))
		if not isBot(victim) then
			toOne(victim, "died", "", "", 0, 0)
		end
	end
	lastHit[victim] = nil
	-- ASSISTS (v6): everyone else who did enough damage in the last 10 seconds
	local hits = dmgBy[victim]
	dmgBy[victim] = nil
	if hits then
		for a, e in pairs(hits) do
			if a ~= killer and not isBot(a) and a.Parent and pd[a] and e.amount >= C.AssistDamage and tick() - e.at < 10 then
				pd[a].mScore = pd[a].mScore + 50
				toOne(a, "medal", C.Medals.assist.name, C.Medals.assist.xp)
				addXP(a, C.Medals.assist.xp, "ASSIST")
			end
		end
	end
	if deathPos and V.state.Value == "playing" and deathPos.Y > currentMap.killY + 5 then
		dropPickup(deathPos)
	end
	if isBot(victim) then
		syncBot(victim)
	else
		sync(victim)
	end
end

-- AMMO DROPS (v6): a green box; walk over it for ammo, a grenade and some health
dropPickup = function(pos)
	local box = newPart("AmmoBox", Vector3.new(1.8, 1.2, 1.2), "Earth green", "Metal", CFrame.new(pos + Vector3.new(0, -1.6, 0)))
	box.Parent = fx
	local stripe = newPart("AmmoStripe", Vector3.new(1.9, 0.3, 1.3), "Lime green", "Neon", CFrame.new(pos + Vector3.new(0, -1.6, 0)))
	stripe.Parent = box
	local taken = false
	box.Touched:connect(function(hit)
		if taken then
			return
		end
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if not p or not pd[p] or not inMatchOf(p) or not aliveP(p) then
			return
		end
		taken = true
		box:Destroy()
		for _, holder in ipairs({ charOf(p), p:FindFirstChild("Backpack") }) do
			if holder then
				for _, t in ipairs(holder:GetChildren()) do
					local def = gunByName[t.Name]
					local res = t:FindFirstChild("Reserve")
					local am = t:FindFirstChild("Ammo")
					if def and res and not def.melee then
						res.Value = math.min(def.reserve * 2, res.Value + def.mag)
					elseif t.Name == "Frag Grenade" and am then
						am.Value = math.min(C.Grenades + 1, am.Value + 1)
					end
				end
			end
		end
		local h = humOf(p)
		if h and h.Health > 0 then
			h.Health = math.min(h.MaxHealth, h.Health + C.DropHeal)
		end
		toOne(p, "pickup", "+AMMO  +1 GRENADE  +" .. C.DropHeal .. " HP")
	end)
	Debris:AddItem(box, C.DropTime)
end

------------------------------------------------------------------
-- SPAWNING and LOADOUTS
------------------------------------------------------------------
local spawnPlayer -- defined below
local applyView -- defined below

local function pickSpawn(p)
	local d = isBot(p) and p or pd[p]
	if V.state.Value ~= "playing" or (not inMatch[p] and not isBot(p)) then
		local list = world.lobby.spawns.any
		return list[math.random(1, #list)]
	end
	local list = currentMap.spawns.any
	if mode.teams and d and d.team then
		list = currentMap.spawns[d.team]
	end
	-- the spawn that is furthest from the closest enemy
	local best, bestScore = list[1], -1
	for _, cf in ipairs(list) do
		local closest = 9999
		for _, o in ipairs(combatants()) do
			if o ~= p and enemies(p, o) and aliveP(o) then
				local r = rootOf(o)
				if r then
					closest = math.min(closest, (r.Position - cf.p).magnitude)
				end
			end
		end
		local score = closest + math.random() * 15
		if score > bestScore then
			best, bestScore = cf, score
		end
	end
	return best
end

local function giveLoadout(p)
	local d = pd[p]
	local bp = p:FindFirstChild("Backpack")
	if not d or not bp then
		return
	end
	for _, holder in ipairs({ bp, charOf(p) }) do
		if holder then
			for _, t in ipairs(holder:GetChildren()) do
				if t:IsA("Tool") then
					t:Destroy()
				end
			end
		end
	end
	local first = nil
	local function give(name)
		local def = gunByName[name]
		if def then
			local t = Guns.tool(def)
			t.Parent = bp
			first = first or t
		end
	end
	if mode.id == "gungame" then
		-- GUN GAME: only the gun you are on (and a knife)
		local name = C.GunGameLadder[d.gg or 1] or "Knife"
		give(name)
		if name ~= "Knife" then
			give("Knife")
		end
	else
		give(d.primary)
		give(d.secondary)
		give("Knife")
		local gt = Guns.grenade(C.Grenades)
		gt.Parent = bp
	end
	-- (v6) your first gun is in your hands right away
	local hum = humOf(p)
	if first and hum and hum.Health > 0 then
		pcall(function()
			hum:EquipTool(first)
		end)
	end
end

-- GUN GAME: give a player or a bot the gun they are on now
ggUpgrade = function(e)
	local d = isBot(e) and e or pd[e]
	if not d then
		return
	end
	local name = C.GunGameLadder[d.gg or 1] or "Knife"
	local def = gunByName[name]
	if not def then
		return
	end
	if isBot(e) then
		e.gun = def
		e.ammo = def.mag
		e.reloadUntil = 0
		if e.model and e.model.Parent and not e.dead then
			if e.tool then
				e.tool:Destroy()
			end
			local t = Guns.tool(def)
			t.Parent = e.model
			e.tool = t
		end
		syncBot(e)
		return
	end
	toOne(e, "big", "GUN " .. d.gg .. " / " .. #C.GunGameLadder .. ":  " .. string.upper(name), Color3.new(0.6, 1, 0.6))
	if aliveP(e) and inMatch[e] then
		giveLoadout(e)
	end
	sync(e)
end

-- the camera: FIRST PERSON or THIRD PERSON (over the shoulder) while you play (your setting, V key),
-- a normal camera in the lobby
applyView = function(p)
	local d = pd[p]
	local third = d and d.set and d.set.view == "third"
	pcall(function()
		if V.state.Value == "playing" and inMatch[p] and not third then
			p.CameraMode = Enum.CameraMode.LockFirstPerson
		else
			p.CameraMode = Enum.CameraMode.Classic
			if V.state.Value == "playing" and inMatch[p] then
				p.CameraMinZoomDistance = 7
				p.CameraMaxZoomDistance = 11
			else
				p.CameraMinZoomDistance = 0.5
				p.CameraMaxZoomDistance = 40
			end
		end
	end)
end

local function onCharacter(p, char)
	local d = pd[p]
	if not d then
		return
	end
	d.dead = false
	spawnedAt[p] = tick()
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	wait(0.1) -- let the engine finish spawning first, or it moves you back
	-- team colours on the body
	if mode.teams and d.team and inMatch[p] then
		pcall(function()
			p.TeamColor = TEAM_COLOR[d.team]
			p.Neutral = false
		end)
		local torso = char:FindFirstChild("Torso")
		if torso then
			torso.BrickColor = TEAM_COLOR[d.team]
		end
	else
		pcall(function()
			p.Neutral = true
		end)
	end
	local cf = pickSpawn(p)
	root.CFrame = cf + Vector3.new(0, 2, 0)
	applyView(p)
	if V.state.Value == "playing" and inMatch[p] and weatherDef().lights then
		local head = char:FindFirstChild("Head")
		if head then
			addFlashlight(head)
		end
	end
	local ff = Instance.new("ForceField")
	ff.Parent = char
	Debris:AddItem(ff, C.SpawnShield)
	hum.Died:connect(function()
		onDied(p)
		if V.state.Value == "playing" and inMatch[p] and mode.respawn then
			delay(C.RespawnTime, function()
				if p.Parent and pd[p] and pd[p].dead and V.state.Value == "playing" then
					spawnPlayer(p)
				end
			end)
		elseif V.state.Value ~= "playing" then
			delay(2, function()
				if p.Parent and pd[p] and pd[p].dead then
					spawnPlayer(p)
				end
			end)
		end
	end)
	if V.state.Value == "playing" and inMatch[p] then
		giveLoadout(p)
	else
		local bp = p:FindFirstChild("Backpack")
		if bp then
			for _, t in ipairs(bp:GetChildren()) do
				t:Destroy()
			end
		end
	end
	sync(p)
end

spawnPlayer = function(p)
	pcall(function()
		p:LoadCharacter()
	end)
end

------------------------------------------------------------------
-- GUNS: firing, reloading, knife, rockets, grenades
------------------------------------------------------------------
local nextShot = setmetatable({}, { __mode = "k" }) -- [tool] = time it can shoot again

local function tracer(from, to, color)
	local len = (to - from).magnitude
	if len < 0.5 then
		return
	end
	local t = newPart("Tracer", Vector3.new(0.12, 0.12, len), color or "New Yeller", "Neon", CFrame.new((from + to) / 2, to))
	t.Transparency = 0.25
	t.Parent = fx
	Debris:AddItem(t, 0.06)
end

local function spark(pos)
	local s = newPart("Spark", Vector3.new(0.4, 0.4, 0.4), "Bright orange", "Neon", CFrame.new(pos))
	s.Parent = fx
	Debris:AddItem(s, 0.12)
end

local function muzzleOf(tool, def)
	local h = tool:FindFirstChild("Handle")
	local stats = tool:FindFirstChild("Stats")
	local mz = stats and stats:FindFirstChild("MuzzleZ")
	if h then
		return (h.CFrame * CFrame.new(0, 0.1, mz and mz.Value or -1)).p, h
	end
	return nil
end

local function fireRocket(p, origin, dir, def)
	local rocket = newPart("Rocket", Vector3.new(0.6, 0.6, 2.2), "Dark stone grey", "Metal", CFrame.new(origin, origin + dir))
	rocket.Parent = fx
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Parent = rocket
	local ignore = { charOf(p), fx }
	spawn(function()
		local pos = origin
		local speed = 160
		for i = 1, 120 do
			local step = dir * speed * 0.05
			local hit, at = cast(pos, step, ignore)
			if hit then
				rocket:Destroy()
				explode(at, def.splash or 14, def.damage, p, def.name)
				return
			end
			pos = pos + step
			rocket.CFrame = CFrame.new(pos, pos + dir)
			wait(0.05)
		end
		rocket:Destroy()
	end)
end

local function shoot(p, tool, target, ads)
	local def = gunByName[tool.Name]
	local char = charOf(p)
	if not def or not char or tool.Parent ~= char or not aliveP(p) or V.state.Value ~= "playing" then
		return
	end
	local now = tick()
	local interval = 60 / def.rpm
	if nextShot[tool] and now < nextShot[tool] then
		return
	end
	nextShot[tool] = now + interval * 0.8
	local head = char:FindFirstChild("Head")
	if not head then
		return
	end
	local origin = head.Position
	-- target must be a Vector3
	if not pcall(function()
		return target.X + target.Y + target.Z
	end) then
		return
	end
	-- spawn protection ends the moment you shoot
	local ff = char:FindFirstChild("ForceField")
	if ff then
		ff:Destroy()
	end

	-- KNIFE
	if def.melee then
		sound(head, C.Sounds.knife, 0.4, 1.2)
		local root = rootOf(p)
		local best, bestDist = nil, def.range
		for _, o in ipairs(combatants()) do
			if o ~= p and enemies(p, o) and aliveP(o) then
				local r = rootOf(o)
				if r and root then
					local off = r.Position - root.Position
					local dist = off.magnitude
					if dist < bestDist and root.CFrame.lookVector:Dot(off.unit) > 0.3 then
						best, bestDist = o, dist
					end
				end
			end
		end
		if best then
			-- stab them in the back = instant kill
			local br = rootOf(best)
			local back = br and root and br.CFrame.lookVector:Dot((br.Position - root.Position).unit) > 0.5
			damage(p, best, humOf(best), back and 200 or def.damage, "Knife", false)
		end
		return
	end

	local ammo = tool:FindFirstChild("Ammo")
	local reloading = tool:FindFirstChild("Reloading")
	if not ammo or ammo.Value <= 0 or (reloading and reloading.Value) then
		return
	end
	ammo.Value = ammo.Value - 1

	local muzzle, handle = muzzleOf(tool, def)
	if not muzzle or (muzzle - origin).magnitude > 8 then
		muzzle = origin -- the gun isn't in the hand yet: shoot from the head
	end
	if handle then
		-- (fast guns only make a sound every other shot, so it never gets too loud)
		if def.rpm <= 700 or ammo.Value % 2 == 0 then
			sound(handle, C.Sounds.shot, def.rocket and 0.4 or C.ShotVolume, def.rocket and 0.5 or (1.6 - math.min(def.damage, 100) / 120))
		end
		local flash = handle:FindFirstChild("Flash")
		if flash then
			flash.Enabled = true
			delay(0.05, function()
				flash.Enabled = false
			end)
		end
	end
	local aim = (target - origin)
	if aim.magnitude < 0.1 then
		return
	end
	aim = aim.unit
	local spread = math.rad(ads and def.ads or def.spread)

	if def.rocket then
		fireRocket(p, muzzle, aim, def)
		return
	end

	local ignore = { char, fx }
	for k = 1, (def.pellets or 1) do
		local dir = (CFrame.new(Vector3.new(0, 0, 0), aim) * CFrame.Angles((math.random() - 0.5) * 2 * spread, (math.random() - 0.5) * 2 * spread, 0)).lookVector
		local hit, at = cast(origin, dir * def.range, ignore)
		tracer(muzzle, at, k == 1 and "New Yeller" or "Bright yellow")
		if hit then
			local victim, hum = victimOf(hit)
			if hum then
				if victim ~= p then
					local isHead = hit.Name == "Head"
					local dmg = def.damage * (isHead and def.headMult or 1)
					-- a bit less damage very far away
					local dist = (at - origin).magnitude
					if dist > def.range * 0.6 then
						dmg = dmg * 0.75
					end
					damage(p, victim, hum, dmg, def.name, isHead)
				end
			else
				spark(at)
			end
		end
	end
end

local function reload(p, tool)
	local def = gunByName[tool.Name]
	if not def or def.melee or tool.Parent ~= charOf(p) then
		return
	end
	local ammo, reserve, reloading = tool:FindFirstChild("Ammo"), tool:FindFirstChild("Reserve"), tool:FindFirstChild("Reloading")
	if not ammo or not reserve or not reloading or reloading.Value or ammo.Value >= def.mag or reserve.Value <= 0 then
		return
	end
	reloading.Value = true
	local h = tool:FindFirstChild("Handle")
	if h then
		sound(h, C.Sounds.reload, 0.4, 0.8)
	end
	delay(def.reload, function()
		if not tool.Parent then
			return
		end
		local need = def.mag - ammo.Value
		local take = math.min(need, reserve.Value)
		ammo.Value = ammo.Value + take
		reserve.Value = reserve.Value - take
		reloading.Value = false
		if h then
			sound(h, C.Sounds.reload, 0.4, 1.4)
		end
	end)
end

local function throwGrenade(p, tool, target)
	local char = charOf(p)
	local head = char and char:FindFirstChild("Head")
	if not head or not aliveP(p) or V.state.Value ~= "playing" then
		return
	end
	local count = tool and tool:FindFirstChild("Ammo")
	if not count or count.Value <= 0 or tool.Parent ~= char then
		return
	end
	if nextShot[tool] and tick() < nextShot[tool] then
		return
	end
	nextShot[tool] = tick() + 1
	count.Value = count.Value - 1
	local g = newPart("Grenade", Vector3.new(0.9, 0.9, 0.9), "Earth green", "Metal", CFrame.new(head.Position))
	g.Shape = Enum.PartType.Ball
	g.Parent = fx
	local blink = Instance.new("PointLight")
	blink.Color = Color3.new(1, 0.2, 0.2)
	blink.Range = 6
	blink.Parent = g
	-- fly in an arc towards where you aimed (moved by the script, so it never bounces loudly)
	local aim = target - head.Position
	local flat = Vector3.new(aim.X, 0, aim.Z)
	local dist = math.min(flat.magnitude, 90)
	local dirFlat = flat.magnitude > 0.1 and flat.unit or Vector3.new(0, 0, -1)
	local vel = dirFlat * math.max(25, dist * 1.1) + Vector3.new(0, 35 + aim.Y * 0.4, 0)
	local ignore = { char, fx }
	spawn(function()
		local pos = head.Position
		local landed = false
		local t0 = tick()
		while tick() - t0 < C.GrenadeFuse do
			if not landed then
				local step = vel * 0.05
				local hit, at = cast(pos, step, ignore)
				if hit then
					pos = at + Vector3.new(0, 0.5, 0)
					landed = true
				else
					pos = pos + step
					vel = vel + Vector3.new(0, -196.2 * 0.05, 0)
				end
				g.CFrame = CFrame.new(pos)
			end
			blink.Enabled = not blink.Enabled
			wait(0.05)
		end
		g:Destroy()
		explode(pos, C.GrenadeRadius, C.GrenadeDamage, p, "Frag Grenade")
	end)
end

------------------------------------------------------------------
-- KILLSTREAKS
------------------------------------------------------------------
local function enemiesOf(p)
	local out = {}
	for _, o in ipairs(combatants()) do
		if o ~= p and enemies(p, o) and aliveP(o) and (inMatch[o] or isBot(o)) then
			table.insert(out, o)
		end
	end
	return out
end

killstreak = function(p, ks)
	toOne(p, "big", ks.name .. "! (" .. ks.info .. ")", Color3.new(1, 0.8, 0.2))
	toAll("feed", "", p.Name .. " called in " .. ks.name .. "!", "", false, Color3.new(1, 0.7, 0.2))
	if ks.id == "uav" then
		uavUntil[p] = tick() + 25
	elseif ks.id == "armor" then
		local h = humOf(p)
		if h then
			h.MaxHealth = 160
			h.Health = 160
		end
		pd[p].speedBonus = 3
		sync(p)
	elseif ks.id == "airstrike" then
		spawn(function()
			for i = 1, 8 do
				local list = enemiesOf(p)
				if #list == 0 then
					break
				end
				local target = list[math.random(1, #list)]
				local r = rootOf(target)
				if r then
					local at = r.Position + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
					local bomb = newPart("Bomb", Vector3.new(1.5, 1.5, 3), "Really black", "Metal", CFrame.new(at + Vector3.new(0, 60, 0)))
					bomb.Parent = fx
					for k = 1, 10 do
						bomb.CFrame = CFrame.new(at + Vector3.new(0, 60 - k * 6, 0)) * CFrame.Angles(math.pi / 2, 0, 0)
						wait(0.04)
					end
					bomb:Destroy()
					explode(at, 14, 120, p, "Airstrike")
				end
				wait(0.4)
			end
		end)
	elseif ks.id == "nuke" then
		toAll("big", "NUKE INCOMING! (" .. p.Name .. ")", Color3.new(1, 0.3, 0.2))
		delay(4, function()
			toAll("flash")
			for _, o in ipairs(enemiesOf(p)) do
				damage(p, o, humOf(o), 1000, "NUKE", false)
			end
		end)
	end
end

-- UAV: red markers over enemies, only on the screen of the player who called it
local function uavMarks(p, on)
	local pg = p:FindFirstChild("PlayerGui")
	if not pg then
		return
	end
	local holder = pg:FindFirstChild("UAVMarks")
	if not on then
		if holder then
			holder:Destroy()
		end
		return
	end
	if not holder then
		holder = Instance.new("ScreenGui")
		holder.Name = "UAVMarks"
		holder.Parent = pg
	end
	for _, c in ipairs(holder:GetChildren()) do
		c:Destroy()
	end
	for _, o in ipairs(enemiesOf(p)) do
		local head = charOf(o) and charOf(o):FindFirstChild("Head")
		if head then
			local bb = Instance.new("BillboardGui")
			bb.Adornee = head
			bb.AlwaysOnTop = true
			bb.Size = UDim2.new(0, 60, 0, 24)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, 0, 1, 0)
			t.BackgroundTransparency = 1
			t.Font = Enum.Font.SourceSansBold
			t.FontSize = Enum.FontSize.Size18
			t.TextColor3 = Color3.new(1, 0.2, 0.2)
			t.TextStrokeTransparency = 0
			t.Text = "ENEMY"
			t.Parent = bb
			bb.Parent = holder
		end
	end
end

------------------------------------------------------------------
-- remote: everything the clients ask for
------------------------------------------------------------------
local function isTool(x)
	local ok, yes = pcall(function()
		return x:IsA("Tool")
	end)
	return ok and yes
end
local setTeamPref -- (v6) pick RED / BLUE / AUTO, defined after the BOTS
remote.OnServerEvent:connect(function(p, what, a, b, c)
	if what == "fire" and isTool(a) then
		shoot(p, a, b, c and true or false)
	elseif what == "reload" and isTool(a) then
		reload(p, a)
	elseif what == "grenade" and isTool(a) then
		throwGrenade(p, a, b)
	elseif what == "settings" then
		-- a = setting name, b = value (checked here, the client can send anything)
		local d = pd[p]
		if d then
			local st = d.set
			if a == "fov" and type(b) == "number" then
				st.fov = math.max(50, math.min(120, math.floor(b)))
			elseif a == "view" then
				st.view = (b == "third") and "third" or "first"
				applyView(p)
			elseif a == "cross" and type(b) == "string" and string.len(b) < 30 then
				st.cross = b
			elseif a == "zoom" and type(b) == "number" then
				st.zoom = math.max(1, math.min(3, math.floor(b)))
			elseif a == "hitsound" then
				st.hitsound = b and true or false
			elseif a == "minimap" then
				st.minimap = b and true or false
			elseif a == "sens" and type(b) == "number" then
				st.sens = math.max(0.2, math.min(3, b))
			elseif a == "aimtoggle" then
				st.aimtoggle = b and true or false
			elseif a == "shoulder" then
				st.shoulder = (b == "left") and "left" or "right"
			elseif a == "wfx" then
				st.wfx = b and true or false
			end
			sync(p)
		end
	elseif what == "loadout" then
		local d = pd[p]
		local lv = d and levelOf(d.xp) or 1
		local g1, g2 = gunByName[tostring(a)], gunByName[tostring(b)]
		if d and g1 and g1.slot == "primary" and (g1.level <= lv or isAdmin(p)) then
			d.primary = g1.name
		end
		if d and g2 and g2.slot == "secondary" and (g2.level <= lv or isAdmin(p)) then
			d.secondary = g2.name
		end
		sync(p)
		toOne(p, "big", "Loadout: " .. d.primary .. " + " .. d.secondary .. " (next spawn)", Color3.new(0.6, 0.85, 1))
	elseif what == "team" then
		setTeamPref(p, tostring(a))
	elseif what == "vote" and V.state.Value == "intermission" then
		local d = pd[p]
		local key = tostring(a) .. "_" .. tostring(b)
		if d and voteValues[key] then
			local old = d["vote_" .. tostring(a)]
			if old and voteValues[old] then
				voteValues[old].Value = math.max(0, voteValues[old].Value - 1)
			end
			d["vote_" .. tostring(a)] = key
			voteValues[key].Value = voteValues[key].Value + 1
		end
	end
end)

------------------------------------------------------------------
-- MATCH FLOW
------------------------------------------------------------------
local nextMap, nextMode, nextBots, nextWeather = nil, nil, nil, nil

local function playersList()
	return Players:GetPlayers()
end

local function topVote(prefix, list)
	local best, bestN = nil, -1
	for _, id in ipairs(list) do
		local v = voteValues[prefix .. id]
		local n = v and v.Value or 0
		if n > bestN or (n == bestN and math.random() < 0.5) then
			best, bestN = id, n
		end
	end
	return best
end

-- WEATHER (v6): time of day, fog and light for everyone. The rain / snow / sand you see falling
-- is drawn by each player's own computer (ShooterClient), from Game.Weather.
local LIGHT = game:GetService("Lighting")
local function c3(t)
	return Color3.new(t[1] / 255, t[2] / 255, t[3] / 255)
end
local function setLight(prop, value)
	pcall(function()
		LIGHT[prop] = value
	end)
end
local function applyWeather(id, mapTime)
	local w = C.Weather[id] or C.Weather.clear
	V.weather.Value = C.Weather[id] and id or "clear"
	V.weatherName.Value = w.name
	pcall(function()
		LIGHT:SetMinutesAfterMidnight((w.time or mapTime or 14) * 60)
	end)
	setLight("FogStart", w.fogStart or 0)
	setLight("FogEnd", w.fogEnd or 100000)
	setLight("FogColor", c3(w.fog or { 192, 192, 192 }))
	setLight("Brightness", w.bright or 1)
	setLight("Ambient", c3(w.amb or { 128, 128, 133 }))
	setLight("OutdoorAmbient", c3(w.out or { 140, 140, 153 }))
end

local function sendToLobby()
	for _, p in ipairs(playersList()) do
		inMatch[p] = nil
		spawnPlayer(p)
	end
end

-- (v6) players who picked RED or BLUE get it; AUTO players fill the smaller team.
-- Bots then even the teams out (see Bots.fill).
local function assignTeams()
	local list = playersList()
	for i = #list, 2, -1 do
		local j = math.random(1, i)
		list[i], list[j] = list[j], list[i]
	end
	local r, b = 0, 0
	local autos = {}
	for _, p in ipairs(list) do
		local d = pd[p]
		if d then
			d.nextTeam = nil
			if not mode.teams then
				d.team = nil
			elseif d.teamPref == "red" or d.teamPref == "blue" then
				d.team = d.teamPref
				if d.team == "red" then
					r = r + 1
				else
					b = b + 1
				end
			else
				table.insert(autos, p)
			end
		end
	end
	for _, p in ipairs(autos) do
		if r <= b then
			pd[p].team = "red"
			r = r + 1
		else
			pd[p].team = "blue"
			b = b + 1
		end
	end
end

-- players (no bots) on each team in this match
local function playerTeamCounts()
	local r, b = 0, 0
	for p, d in pairs(pd) do
		if p.Parent and inMatch[p] then
			if d.team == "red" then
				r = r + 1
			elseif d.team == "blue" then
				b = b + 1
			end
		end
	end
	return r, b
end

local function teamCounts()
	local r, b = 0, 0
	for p, d in pairs(pd) do
		if p.Parent and inMatch[p] then
			if d.team == "red" then
				r = r + 1
			elseif d.team == "blue" then
				b = b + 1
			end
		end
	end
	for _, bot in ipairs(bots) do
		if bot.team == "red" then
			r = r + 1
		elseif bot.team == "blue" then
			b = b + 1
		end
	end
	return r, b
end

local function resetMatchStats()
	for p, d in pairs(pd) do
		d.mKills, d.mDeaths, d.mScore, d.streak, d.speedBonus = 0, 0, 0, 0, 0
		d.gg, d.multi, d.lastKiller, d.lastKillAt = 1, 0, nil, nil
		sync(p)
	end
	V.red.Value, V.blue.Value = 0, 0
	V.leader.Value = ""
	firstBlood = false
	ggWinner = nil
end

local function aliveOn(team)
	local n = 0
	for p, d in pairs(pd) do
		if p.Parent and inMatch[p] and d.team == team and not d.dead and aliveP(p) then
			n = n + 1
		end
	end
	for _, bot in ipairs(bots) do
		if bot.team == team and not bot.dead and aliveP(bot) then
			n = n + 1
		end
	end
	return n
end

-- GUN GAME: who is on the highest gun (then most kills)
local function ggLeader()
	local best, bestG, bestK = nil, -1, -1
	for p, d in pairs(pd) do
		if p.Parent and inMatch[p] and ((d.gg or 1) > bestG or ((d.gg or 1) == bestG and d.mKills > bestK)) then
			best, bestG, bestK = p, d.gg or 1, d.mKills
		end
	end
	for _, bot in ipairs(bots) do
		if (bot.gg or 1) > bestG or ((bot.gg or 1) == bestG and bot.mKills > bestK) then
			best, bestG, bestK = bot, bot.gg or 1, bot.mKills
		end
	end
	return best, bestG
end

-- KING OF THE HILL: the hill (a glowing circle + a beam you can see from far away)
local hillParts = {}
local HILL_COLORS = { red = "Bright red", blue = "Bright blue", contested = "Institutional white" }
local function clearHill()
	for _, p in ipairs(hillParts) do
		p:Destroy()
	end
	hillParts = {}
	V.hillPos.Value = Vector3.new(0, -1000, 0)
	V.hillR.Value = 0
	V.hillOwner.Value = ""
end
local function colorHill(owner)
	for _, p in ipairs(hillParts) do
		p.BrickColor = BrickColor.new(HILL_COLORS[owner] or "New Yeller")
	end
end
local function setHill(pos, r)
	clearHill()
	V.hillPos.Value = pos
	V.hillR.Value = r
	local disc = newPart("HillZone", Vector3.new(0.4, r * 2, r * 2), "New Yeller", "Neon", CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2))
	disc.Shape = Enum.PartType.Cylinder
	disc.Transparency = 0.6
	disc.Parent = fx
	local beam = newPart("HillBeam", Vector3.new(1.5, 140, 1.5), "New Yeller", "Neon", CFrame.new(pos + Vector3.new(0, 70, 0)))
	beam.Transparency = 0.55
	beam.Parent = fx
	pcall(function()
		local bb = Instance.new("BillboardGui")
		bb.AlwaysOnTop = true
		bb.Size = UDim2.new(0, 100, 0, 34)
		bb.StudsOffset = Vector3.new(0, -60, 0)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, 0, 1, 0)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.SourceSansBold
		t.FontSize = Enum.FontSize.Size24
		t.TextColor3 = Color3.new(1, 0.95, 0.4)
		t.TextStrokeTransparency = 0
		t.Text = "HILL"
		t.Parent = bb
		bb.Parent = beam
	end)
	hillParts = { disc, beam }
end

local function ffaLeader()
	local best, bestK = nil, -1
	for p, d in pairs(pd) do
		if p.Parent and inMatch[p] and d.mKills > bestK then
			best, bestK = p, d.mKills
		end
	end
	for _, bot in ipairs(bots) do
		if bot.mKills > bestK then
			best, bestK = bot, bot.mKills
		end
	end
	return best, bestK
end

------------------------------------------------------------------
-- BOTS: when there are not many players, bots fill the match up to C.BotFill fighters.
-- Every real player who joins replaces a bot; when a player leaves, a bot comes back.
-- A bot is a normal R6 character (Humanoid:MoveTo to walk) holding a real gun Tool.
-- It looks for the closest enemy it can SEE, walks to a good distance for its gun,
-- strafes, aims (not perfectly) and shoots, reloads, and wanders around when it sees nobody.
------------------------------------------------------------------
local Bots = {}
local botFillOverride = nil -- set by the admin command :botfill
do
	local BOT_NAMES = { "Ghost", "Viper", "Rex", "Blaze", "Shadow", "Nova", "Tank", "Ace", "Bolt", "Echo",
		"Fang", "Hawk", "Jinx", "Kilo", "Lynx", "Moss", "Onyx", "Pike", "Rook", "Zed" }
	local BOT_GUNS = { "M4A1", "AK-47", "MP5", "UZI", "Pump Shotgun", "SCAR-H", "M14 DMR", "Intervention", "P90", "FAMAS" }
	local SKIN = { "Bright yellow", "Nougat", "Brown", "Pastel brown", "Light orange" }
	local botFolder = Instance.new("Folder")
	botFolder.Name = "Bots"
	botFolder.Parent = G
	local botWorld = Instance.new("Model")
	botWorld.Name = "ShooterBots"
	botWorld.Parent = game.Workspace
	local nameN = 0

	syncBot = function(b)
		local f = botFolder:FindFirstChild(b.Name)
		if not f then
			f = Instance.new("Folder")
			f.Name = b.Name
			f.Parent = botFolder
		end
		setVal(f, "IntValue", "Kills", b.mKills)
		setVal(f, "IntValue", "Deaths", b.mDeaths)
		setVal(f, "StringValue", "Team", b.team or "")
		setVal(f, "IntValue", "Score", b.mScore)
		setVal(f, "IntValue", "GG", b.gg or 1)
	end

	-- an R6 body with the standard joints
	local function R(x, y, z, a, b, c, d, e, f, g, h, i)
		return CFrame.new(x, y, z, a, b, c, d, e, f, g, h, i)
	end
	local function buildBody(b, cf)
		local m = Instance.new("Model")
		m.Name = b.Name
		local function bp(name, size, color, offset)
			local p = Instance.new("Part")
			p.Name = name
			pcall(function()
				p.FormFactor = Enum.FormFactor.Custom
			end)
			p.Size = size
			p.BrickColor = BrickColor.new(color)
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.CFrame = cf * offset
			p.Parent = m
			return p
		end
		local skin = SKIN[math.random(1, #SKIN)]
		local teamCol = (mode.teams and b.team == "red") and "Bright red" or ((mode.teams and b.team == "blue") and "Bright blue" or "Dark stone grey")
		local root = bp("HumanoidRootPart", Vector3.new(2, 2, 1), "Medium stone grey", CFrame.new())
		root.Transparency = 1
		local torso = bp("Torso", Vector3.new(2, 2, 1), teamCol, CFrame.new())
		local head = bp("Head", Vector3.new(2, 1, 1), skin, CFrame.new(0, 1.5, 0))
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Head
		mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
		mesh.Parent = head
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Texture = "rbxasset://textures/face.png"
		face.Parent = head
		if weatherDef().lights then
			addFlashlight(head)
		end
		local ra = bp("Right Arm", Vector3.new(1, 2, 1), skin, CFrame.new(1.5, 0, 0))
		local la = bp("Left Arm", Vector3.new(1, 2, 1), skin, CFrame.new(-1.5, 0, 0))
		local rl = bp("Right Leg", Vector3.new(1, 2, 1), "Dark stone grey", CFrame.new(0.5, -2, 0))
		local ll = bp("Left Leg", Vector3.new(1, 2, 1), "Dark stone grey", CFrame.new(-0.5, -2, 0))
		-- a helmet in the team colour
		local helmet = bp("Helmet", Vector3.new(2.1, 0.7, 1.3), teamCol, CFrame.new(0, 2.05, 0))
		local w = Instance.new("Weld")
		w.Part0, w.Part1, w.C0 = head, helmet, CFrame.new(0, 0.55, 0)
		w.Parent = head
		local function joint(name, p0, p1, c0, c1, parent)
			local j = Instance.new("Motor6D")
			j.Name = name
			j.Part0, j.Part1, j.C0, j.C1 = p0, p1, c0, c1
			pcall(function()
				j.MaxVelocity = 0.15
			end)
			j.Parent = parent
			return j
		end
		joint("RootJoint", root, torso, R(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), R(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), root)
		joint("Neck", torso, head, R(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), R(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), torso)
		b.rs = joint("Right Shoulder", torso, ra, R(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), R(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), torso)
		b.ls = joint("Left Shoulder", torso, la, R(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), R(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), torso)
		b.rh = joint("Right Hip", torso, rl, R(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), R(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), torso)
		b.lh = joint("Left Hip", torso, ll, R(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), R(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), torso)
		local hum = Instance.new("Humanoid")
		local lv = C.BotLevels[V.botLevel.Value] or C.BotLevels[C.DefaultBotLevel]
		hum.MaxHealth = lv.health
		hum.Health = lv.health
		hum.WalkSpeed = lv.speed
		hum.Parent = m
		pcall(function()
			hum.AutoRotate = false
		end)
		-- turn to face whatever it is shooting at
		local gyro = Instance.new("BodyGyro")
		pcall(function()
			gyro.MaxTorque = Vector3.new(0, 4e5, 0)
		end)
		pcall(function()
			gyro.maxTorque = Vector3.new(0, 4e5, 0)
		end)
		gyro.P = 30000
		gyro.Parent = root
		b.gyro = gyro
		-- its gun (a real Tool: the Humanoid holds it in the right hand)
		local tool = Guns.tool(b.gun)
		tool.Parent = m
		b.tool = tool
		m.Parent = botWorld
		b.model, b.hum, b.root, b.head = m, hum, root, head
		botByModel[m] = b
		-- arms up holding the gun
		pcall(function()
			b.rs.DesiredAngle = 1.57
			b.rs.CurrentAngle = 1.57
			b.ls.DesiredAngle = -1.2
			b.ls.CurrentAngle = -1.2
		end)
		local ff = Instance.new("ForceField")
		ff.Parent = m
		Debris:AddItem(ff, C.SpawnShield)
		hum.Died:connect(function()
			onDied(b)
			b.dead = true
			delay(3, function()
				if b.model == m then
					m:Destroy()
					botByModel[m] = nil
				end
			end)
			if V.state.Value == "playing" and mode.respawn then
				delay(C.RespawnTime + 1, function()
					if not b.removed and b.dead and V.state.Value == "playing" then
						Bots.spawn(b)
					end
				end)
			end
		end)
	end

	function Bots.spawn(b)
		if b.model and b.model.Parent then
			botByModel[b.model] = nil
			b.model:Destroy()
		end
		b.dead = false
		if mode.id == "gungame" then
			b.gg = b.gg or 1
			b.gun = gunByName[C.GunGameLadder[b.gg]] or b.gun
		end
		b.ammo = b.gun.mag
		b.reloadUntil = 0
		b.nextShot = tick() + 1
		b.target, b.seenAt = nil, 0
		b.spawnedAt = tick()
		local cf = pickSpawn(b)
		buildBody(b, cf + Vector3.new(0, 3, 0))
		syncBot(b)
	end

	local function newBot(team)
		nameN = nameN % #BOT_NAMES + 1
		local name = "[BOT] " .. BOT_NAMES[nameN]
		local b = { isBot = true, Name = name, team = team, mKills = 0, mDeaths = 0, mScore = 0, kills = 0, deaths = 0, streak = 0, dead = true, gg = 1,
			gun = gunByName[BOT_GUNS[math.random(1, #BOT_GUNS)]] or gunByName["M4A1"] }
		table.insert(bots, b)
		syncBot(b)
		return b
	end

	function Bots.remove(b)
		b.removed = true
		for i, o in ipairs(bots) do
			if o == b then
				table.remove(bots, i)
				break
			end
		end
		if b.model then
			botByModel[b.model] = nil
			b.model:Destroy()
		end
		local f = botFolder:FindFirstChild(b.Name)
		if f then
			f:Destroy()
		end
	end

	function Bots.clear()
		while #bots > 0 do
			Bots.remove(bots[1])
		end
	end

	-- how many fighters (players + bots) this match should have
	local function botTarget()
		if C.BotFill <= 0 then
			return 0
		end
		if botFillOverride then
			return botFillOverride
		end
		local mc = mapConfig(currentMap.id)
		return (mc and mc.bots) or C.BotFill
	end

	-- add or remove bots. Free for all: players + bots = the target.
	-- Team modes (v6): every team gets at least half the target, and bots fill the smaller team so
	-- the teams are always even (everybody picked RED? then the bots play BLUE).
	-- spawnNow: put new bots in the map right away
	function Bots.fill(spawnNow)
		if V.state.Value ~= "playing" then
			return
		end
		local pr, pb, pn = 0, 0, 0
		for _, p in ipairs(Players:GetPlayers()) do
			if inMatch[p] and pd[p] then
				pn = pn + 1
				if pd[p].team == "red" then
					pr = pr + 1
				elseif pd[p].team == "blue" then
					pb = pb + 1
				end
			end
		end
		local fill = botTarget()
		local function add(team)
			local b = newBot(team)
			if spawnNow and not (mode.id == "elim" and V.round.Value > 0) then
				Bots.spawn(b)
			end
		end
		if mode.teams then
			-- bots left over without a team go away
			for i = #bots, 1, -1 do
				if not bots[i].team then
					Bots.remove(bots[i])
				end
			end
			local per = 0
			if fill > 0 then
				per = math.max(math.ceil(fill / 2), pr, pb)
			end
			local want = { red = math.max(0, per - pr), blue = math.max(0, per - pb) }
			while want.red + want.blue > C.MaxBots do
				if want.red >= want.blue then
					want.red = want.red - 1
				else
					want.blue = want.blue - 1
				end
			end
			for _, team in ipairs({ "red", "blue" }) do
				local have = {}
				for _, b in ipairs(bots) do
					if b.team == team then
						table.insert(have, b)
					end
				end
				-- remove the extra ones (dead bots first)
				table.sort(have, function(x, y)
					return (x.dead and 1 or 0) > (y.dead and 1 or 0)
				end)
				for i = 1, #have - want[team] do
					Bots.remove(have[i])
				end
				for i = 1, want[team] - #have do
					add(team)
				end
			end
		else
			local want = math.min(C.MaxBots, math.max(0, fill - pn))
			while #bots > want do
				Bots.remove(bots[#bots])
			end
			while #bots < want do
				add(nil)
			end
		end
	end

	function Bots.spawnAll()
		for _, b in ipairs(bots) do
			Bots.spawn(b)
		end
	end

	-- can the bot see this point? (nothing in between)
	local function canSee(b, targetModel, pos)
		local from = b.head.Position
		local hit = cast(from, pos - from, { b.model, fx })
		return hit == nil or hit:IsDescendantOf(targetModel)
	end

	-- walk somewhere (remembered so the edge check knows where the bot is heading)
	local function goTo(b, goal)
		b.goal = goal
		b.hum:MoveTo(goal)
	end

	-- is there floor a few studs ahead? (stops bots walking off rooftops on Skyline)
	local function floorAhead(b, pos)
		if not b.goal then
			return true
		end
		local flat = Vector3.new(b.goal.X - pos.X, 0, b.goal.Z - pos.Z)
		if flat.magnitude < 2 then
			return true
		end
		local ahead = pos + flat.unit * 5 + Vector3.new(0, 2, 0)
		local ignore = { b.model, fx }
		for i = 1, 4 do
			local hit = cast(ahead, Vector3.new(0, -30, 0), ignore)
			if not hit then
				return false
			end
			if hit.CanCollide then
				return true
			end
			-- water or a decoration you can walk through: look below it (v6: bots drowned in the harbor)
			table.insert(ignore, hit)
		end
		return false
	end

	local function level()
		return C.BotLevels[V.botLevel.Value] or C.BotLevels[C.DefaultBotLevel]
	end

	local function botShoot(b, target)
		local lv = level()
		local def = b.gun
		local now = tick()
		if def.melee then
			-- KNIFE (gun game): stab when close enough
			local tr = rootOf(target)
			b.nextShot = now + 0.7 * lv.fireRate
			if tr and (tr.Position - b.root.Position).magnitude <= def.range + 1.5 then
				sound(b.head, C.Sounds.knife, 0.4, 1.2)
				damage(b, target, humOf(target), def.damage * lv.damage * 1.4, def.name, false)
			end
			return
		end
		if now < b.reloadUntil then
			return
		end
		if b.ammo <= 0 then
			b.reloadUntil = now + def.reload
			b.ammo = def.mag
			return
		end
		b.ammo = b.ammo - 1
		b.nextShot = now + math.max(60 / def.rpm, 0.13) * (def.burst and 1.6 or 1) * lv.fireRate
		local tchar = charOf(target)
		local aimPart = tchar and (math.random() < lv.headshot and tchar:FindFirstChild("Head") or tchar:FindFirstChild("Torso"))
		if not aimPart then
			return
		end
		local from = b.head.Position
		local dist = (aimPart.Position - from).magnitude
		-- bots don't aim perfectly (worse far away)
		local err = lv.aim * (0.4 + dist / 40)
		local aimAt = aimPart.Position + Vector3.new((math.random() - 0.5) * err, (math.random() - 0.5) * err, (math.random() - 0.5) * err)
		local h = b.tool and b.tool:FindFirstChild("Handle")
		local muzzle = h and (h.CFrame * CFrame.new(0, 0.1, -1.5)).p or from
		if (muzzle - from).magnitude > 8 then
			muzzle = from
		end
		if h then
			sound(h, C.Sounds.shot, C.ShotVolume * 0.8, 1.4)
		end
		local aim = (aimAt - from).unit
		local spread = math.rad(def.spread * 0.6)
		for k = 1, (def.pellets or 1) do
			local dir = (CFrame.new(Vector3.new(0, 0, 0), aim) * CFrame.Angles((math.random() - 0.5) * 2 * spread, (math.random() - 0.5) * 2 * spread, 0)).lookVector
			local hit, at = cast(from, dir * def.range, { b.model, fx })
			tracer(muzzle, at, "Bright orange")
			if hit then
				local victim, hum = victimOf(hit)
				if hum and victim ~= b then
					local isHead = hit.Name == "Head"
					local dmg = def.damage * (isHead and def.headMult or 1) * lv.damage
					damage(b, victim, hum, dmg, def.name, isHead)
				end
			end
		end
	end

	-- the bot brain (all bots, 5 times a second)
	spawn(function()
		local step = 0
		while true do
			wait(0.2)
			step = step + 1
			local now = tick()
			for _, b in ipairs(bots) do
				if not b.dead and b.model and b.model.Parent and b.hum and b.hum.Health > 0 and V.state.Value == "playing" then
					local root = b.root
					local pos = root.Position
					-- fell off the map
					if pos.Y < currentMap.killY and now - (b.spawnedAt or 0) > 2 then
						b.hum.Health = 0
					else
						-- pick a target: the closest enemy it can see
						if step % 3 == 0 or not b.target then
							-- (v6) rain, fog, night and sandstorms make bots see less far
							local w = weatherDef()
							local best, bestD = nil, math.min(level().sight * (w.sight or 1), (w.fogEnd or 100000) * 0.9)
							for _, o in ipairs(combatants()) do
								if o ~= b and enemies(b, o) and aliveP(o) and (isBot(o) or inMatch[o]) then
									local c = charOf(o)
									local h = c and c:FindFirstChild("Head")
									if h then
										local d = (h.Position - pos).magnitude
										if d < bestD and canSee(b, c, h.Position) then
											best, bestD = o, d
										end
									end
								end
							end
							if best ~= b.target then
								b.target = best
								b.seenAt = now
							end
						end
						local t = b.target
						local tr = t and rootOf(t)
						if t and tr and aliveP(t) then
							local off = tr.Position - pos
							local dist = off.magnitude
							local flat = Vector3.new(off.X, 0, off.Z)
							pcall(function()
								b.gyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), flat.magnitude > 0.1 and flat or Vector3.new(0, 0, -1))
							end)
							-- keep a good distance for its gun, strafe left / right
							local want = b.gun.melee and 2 or (b.gun.pellets and 12 or (b.gun.scope and 80 or (b.gun.rpm >= 800 and 25 or 40)))
							if step % 5 == 0 and now > (b.unstickUntil or 0) then
								local side = Vector3.new(-flat.Z, 0, flat.X)
								side = side.magnitude > 0.1 and side.unit or Vector3.new(1, 0, 0)
								local go
								if dist > want + 12 then
									go = tr.Position
								elseif dist < want - 12 then
									go = pos - flat.unit * 12
								else
									go = pos + side * (math.random() < 0.5 and -10 or 10)
								end
								goTo(b, go)
							end
							-- shoot (after a short reaction time)
							if now - b.seenAt > level().reaction and now >= b.nextShot and (t ~= nil) then
								botShoot(b, t)
							end
						else
							b.target = nil
							-- hunt: walk toward the closest enemy (it "hears" them), sometimes a random spot instead
							if not b.wanderTo or now > (b.wanderUntil or 0) then
								local goal
								if mode.id == "koth" and V.hillR.Value > 0 and math.random() < 0.75 then
									-- KING OF THE HILL: go stand in the hill
									local a, r = math.random() * math.pi * 2, math.random() * V.hillR.Value * 0.6
									goal = V.hillPos.Value + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
								elseif math.random() < 0.75 then
									local bestD = 1e9
									for _, o in ipairs(enemiesOf(b)) do
										local r = rootOf(o)
										if r and (r.Position - pos).magnitude < bestD then
											goal, bestD = r.Position, (r.Position - pos).magnitude
										end
									end
								end
								if not goal then
									local list = currentMap.spawns.any
									goal = list[math.random(1, #list)].p
								end
								b.wanderTo = goal + (mode.id == "koth" and Vector3.new(0, 0, 0) or Vector3.new(math.random(-15, 15), 0, math.random(-15, 15)))
								b.wanderUntil = now + 2.5
								goTo(b, b.wanderTo)
							end
							local flat = Vector3.new(b.wanderTo.X - pos.X, 0, b.wanderTo.Z - pos.Z)
							if flat.magnitude > 1 then
								pcall(function()
									b.gyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), flat)
								end)
							end
						end
						-- about to walk off an edge: stop, back up and go somewhere else
						if not floorAhead(b, pos) then
							local back = Vector3.new(pos.X - b.goal.X, 0, pos.Z - b.goal.Z)
							goTo(b, pos + (back.magnitude > 0.1 and back.unit * 4 or Vector3.new(0, 0, 0)))
							local list = (mode.teams and b.team) and currentMap.spawns[b.team] or currentMap.spawns.any
							b.wanderTo = list[math.random(1, #list)].p
							b.wanderUntil = now + 3
						end
						-- stuck? jump. Still stuck? walk off to the side for a bit (v6). walking legs.
						if step % 10 == 0 then
							if b.lastPos and (b.lastPos - pos).magnitude < 1.5 then
								b.hum.Jump = true
								b.stuck = (b.stuck or 0) + 1
								if b.stuck >= 2 then
									local a = math.random() * math.pi * 2
									b.wanderTo = pos + Vector3.new(math.cos(a) * 22, 0, math.sin(a) * 22)
									b.wanderUntil = now + 2.5
									b.unstickUntil = now + 2.5
									goTo(b, b.wanderTo)
									b.stuck = 0
								end
							else
								b.stuck = 0
							end
							b.lastPos = pos
						end
						pcall(function()
							local swing = (step % 4 < 2) and 0.6 or -0.6
							b.rh.DesiredAngle = swing
							b.lh.DesiredAngle = swing
						end)
					end
				end
			end
		end
	end)
end

-- TEAMS (v6): a player picks RED, BLUE or AUTO (buttons, T key, or the pads in the lobby).
-- In the lobby it is used for the next team match. In a team match you switch right away
-- (you respawn on the new team; Elimination: from the next round). Bots move so teams stay even.
setTeamPref = function(p, team)
	local d = pd[p]
	if not d or (team ~= "red" and team ~= "blue" and team ~= "auto") then
		return
	end
	if not (V.state.Value == "playing" and mode.teams and inMatch[p]) then
		d.teamPref = team
		sync(p)
		toOne(p, "big", team == "auto" and "TEAM: AUTO (you join the team that needs you)" or ("TEAM: " .. TEAM_NAME[team] .. " (in team modes)"), teamRGB(team))
		return
	end
	if team == "auto" or d.team == team then
		d.teamPref = team
		sync(p)
		toOne(p, "big", "You are on the " .. (TEAM_NAME[d.team] or "?") .. " team", teamRGB(d.team))
		return
	end
	if (d.switchAt or 0) > tick() then
		toOne(p, "big", "Wait a few seconds before you switch again", Color3.new(1, 0.6, 0.4))
		return
	end
	d.switchAt = tick() + 8
	d.teamPref = team
	sync(p)
	if mode.id == "elim" and V.round.Value > 0 then
		d.nextTeam = team
		toOne(p, "big", "You join " .. TEAM_NAME[team] .. " next round", teamRGB(team))
		return
	end
	d.team = team
	d.nextTeam = nil
	d.streak = 0
	toAll("feed", "", p.Name .. " joined the " .. TEAM_NAME[team] .. " team", "", false, teamRGB(team))
	Bots.fill(true)
	spawnPlayer(p)
end

-- results: who won, XP for everyone
local function finishMatch()
	V.state.Value = "ended"
	local text
	local winnerTeam, winnerPlayer = nil, nil
	clearHill()
	if mode.teams then
		if V.red.Value > V.blue.Value then
			winnerTeam = "red"
		elseif V.blue.Value > V.red.Value then
			winnerTeam = "blue"
		end
		text = winnerTeam and (string.upper(winnerTeam) .. " TEAM WINS! " .. V.red.Value .. " - " .. V.blue.Value) or ("DRAW! " .. V.red.Value .. " - " .. V.blue.Value)
	elseif mode.id == "gungame" then
		local best = ggWinner
		if not best then
			best = ggLeader()
		end
		winnerPlayer = best
		text = best and (best.Name .. " WINS THE GUN GAME!") or "Nobody won"
	else
		local best, k = ffaLeader()
		winnerPlayer = best
		text = best and (best.Name .. " WINS with " .. k .. " kills!") or "Nobody won"
	end
	-- MVP = most score
	local mvp, mvpS = nil, -1
	for p, d in pairs(pd) do
		if p.Parent and inMatch[p] and d.mScore > mvpS then
			mvp, mvpS = p, d.mScore
		end
	end
	for _, b in ipairs(bots) do
		if b.mScore > mvpS then
			mvp, mvpS = b, b.mScore
		end
	end
	local md = mvp and (isBot(mvp) and mvp or pd[mvp])
	toAll("matchend", text, md and (mvp.Name .. " (" .. md.mKills .. " kills / " .. md.mDeaths .. " deaths)") or "")
	for p, d in pairs(pd) do
		if p.Parent and inMatch[p] then
			local won = (winnerTeam and d.team == winnerTeam) or (winnerPlayer == p)
			if won then
				d.wins = d.wins + 1
			end
			addXP(p, won and C.XPWin or C.XPLose, won and "WIN" or "MATCH")
			save(p)
		end
	end
	for p in pairs(uavUntil) do
		uavUntil[p] = nil
		uavMarks(p, false)
	end
	Bots.clear()
	wait(8)
end

-- true when at least one real player is in the match
local function playersInMatch()
	for _, p in ipairs(playersList()) do
		if inMatch[p] then
			return true
		end
	end
	return false
end

local function runMatch()
	-- pick the map, mode, weather and bots (votes, or what an admin chose)
	local mapIds = {}
	for _, m in ipairs(C.Maps) do
		if world.maps[m.id] then
			table.insert(mapIds, m.id)
		end
	end
	local mapId = nextMap or topVote("map_", mapIds)
	local modeId = nextMode or topVote("mode_", C.ModeOrder)
	local botsId = nextBots or topVote("bots_", C.BotLevelOrder)
	if not nextBots and voteValues["bots_" .. botsId].Value == 0 then
		botsId = C.DefaultBotLevel -- nobody voted
	end
	local weatherId = nextWeather or topVote("weather_", C.WeatherOrder)
	if not nextWeather and voteValues["weather_" .. weatherId].Value == 0 then
		weatherId = "random" -- nobody voted
	end
	V.botLevel.Value = botsId
	nextMap, nextMode, nextBots, nextWeather = nil, nil, nil, nil
	currentMap = world.maps[mapId] or world.maps.nuketown
	if weatherId == "random" or not C.Weather[weatherId] then
		local mc = mapConfig(currentMap.id)
		local list = (mc and mc.weather) or { "clear" }
		weatherId = list[math.random(1, #list)]
	end
	mode = C.Modes[modeId] or C.Modes.ffa
	V.map.Value, V.mapName.Value = currentMap.id, currentMap.name
	V.mode.Value, V.modeName.Value = mode.id, mode.name
	V.info.Value = mode.info
	V.limit.Value = (mode.id == "gungame") and #C.GunGameLadder or (mode.scoreLimit or mode.roundsToWin or 0)
	-- (v6) load the map: only this one goes in the Workspace. Wait a moment so everyone has it.
	V.state.Value = "loading"
	showMap(currentMap.id)
	applyWeather(weatherId, currentMap.time)
	assignTeams()
	resetMatchStats()
	forceEnd = false
	wait(C.MapLoadTime)
	V.state.Value = "playing"
	toAll("big", mode.name .. " on " .. currentMap.name .. "  (" .. V.weatherName.Value .. ")", Color3.new(1, 0.85, 0.3))
	for _, p in ipairs(playersList()) do
		inMatch[p] = true
		pd[p].dead = false
		spawnPlayer(p)
	end
	V.round.Value = 0
	Bots.fill(true)
	if mode.id == "elim" then
		-- ROUNDS: one life each; last team standing wins the round
		local round = 0
		while V.red.Value < mode.roundsToWin and V.blue.Value < mode.roundsToWin and not forceEnd and playersInMatch() do
			round = round + 1
			V.round.Value = round
			if round > 1 then
				for _, p in ipairs(playersList()) do
					if inMatch[p] then
						local d = pd[p]
						if d.nextTeam then
							d.team = d.nextTeam
							d.nextTeam = nil
						end
						d.dead = false
						spawnPlayer(p)
					end
				end
				Bots.fill(false)
				Bots.spawnAll()
			end
			toAll("big", "ROUND " .. round, Color3.new(1, 1, 1))
			local t = mode.roundTime
			wait(2)
			while t > 0 and not forceEnd and playersInMatch() do
				V.time.Value = t
				local r, b = aliveOn("red"), aliveOn("blue")
				local rc, bc = teamCounts()
				if (r == 0 and rc > 0) or (b == 0 and bc > 0) then
					break
				end
				wait(1)
				t = t - 1
			end
			local r, b = aliveOn("red"), aliveOn("blue")
			if r > b then
				V.red.Value = V.red.Value + 1
				toAll("big", "RED TEAM WINS THE ROUND", Color3.new(1, 0.35, 0.35))
			elseif b > r then
				V.blue.Value = V.blue.Value + 1
				toAll("big", "BLUE TEAM WINS THE ROUND", Color3.new(0.4, 0.6, 1))
			else
				toAll("big", "ROUND DRAW", Color3.new(1, 1, 1))
			end
			wait(4)
		end
	elseif mode.id == "koth" then
		-- KING OF THE HILL: the team with people in the hill (and no enemies) scores 1 point a second
		local hills = currentMap.hills or { currentMap.spawns.any[1].p }
		local hr = currentMap.hillR or 16
		local idx, moveAt = 0, 0
		local held = {} -- [player] = seconds they helped hold the hill
		local t = mode.time
		while t > 0 and not forceEnd and playersInMatch() do
			V.time.Value = t
			if tick() >= moveAt then
				idx = idx % #hills + 1
				moveAt = tick() + C.HillMove
				setHill(hills[idx], hr)
				toAll("big", t < mode.time and "THE HILL MOVED!" or "GO TO THE HILL!", Color3.new(1, 0.95, 0.4))
			end
			local inR, inB = {}, {}
			for _, o in ipairs(combatants()) do
				local d = isBot(o) and o or pd[o]
				local r = rootOf(o)
				if d and d.team and r and aliveP(o) and (isBot(o) or inMatch[o]) then
					local off = r.Position - V.hillPos.Value
					if Vector3.new(off.X, 0, off.Z).magnitude <= hr and math.abs(off.Y) <= 14 then
						table.insert(d.team == "red" and inR or inB, o)
					end
				end
			end
			local owner = ""
			if #inR > 0 and #inB == 0 then
				owner = "red"
			elseif #inB > 0 and #inR == 0 then
				owner = "blue"
			elseif #inR > 0 then
				owner = "contested"
			end
			if owner ~= V.hillOwner.Value then
				V.hillOwner.Value = owner
				colorHill(owner)
			end
			if owner == "red" or owner == "blue" then
				local sv = (owner == "red") and V.red or V.blue
				sv.Value = sv.Value + 1
				for _, o in ipairs(owner == "red" and inR or inB) do
					if isBot(o) then
						o.mScore = o.mScore + 10
						syncBot(o)
					else
						pd[o].mScore = pd[o].mScore + 10
						held[o] = (held[o] or 0) + 1
						if held[o] % 5 == 0 then
							addXP(o, C.HillXP, "HILL")
						else
							sync(o)
						end
					end
				end
			end
			if V.red.Value >= mode.scoreLimit or V.blue.Value >= mode.scoreLimit then
				break
			end
			wait(1)
			t = t - 1
		end
		clearHill()
	else
		local t = mode.time
		while t > 0 and not forceEnd and playersInMatch() do
			V.time.Value = t
			if mode.id == "gungame" then
				local best, g = ggLeader()
				V.leader.Value = best and (best.Name .. " " .. g .. "/" .. #C.GunGameLadder) or ""
				if ggWinner then
					break
				end
			elseif mode.teams then
				if V.red.Value >= mode.scoreLimit or V.blue.Value >= mode.scoreLimit then
					break
				end
			else
				local best, k = ffaLeader()
				V.leader.Value = best and (best.Name .. " " .. k) or ""
				if best and isBot(best) then
					V.leader.Value = best.Name .. " " .. k
				end
				if k >= mode.scoreLimit then
					break
				end
			end
			wait(1)
			t = t - 1
		end
	end
	finishMatch()
end

-- the main loop: lobby (voting) -> match -> results -> ...
spawn(function()
	wait(1)
	while true do
		V.state.Value = "intermission"
		for _, v in pairs(voteValues) do
			v.Value = 0
		end
		for _, d in pairs(pd) do
			d.vote_map, d.vote_mode, d.vote_bots, d.vote_weather = nil, nil, nil, nil
		end
		applyWeather("clear", world.lobby.time)
		sendToLobby()
		showMap("")
		local t = C.Intermission
		skipWait = false
		while t > 0 and not skipWait do
			V.time.Value = t
			wait(1)
			if #playersList() >= C.MinPlayers then
				t = t - 1
			end
		end
		runMatch()
	end
end)

------------------------------------------------------------------
-- loops: kill zone, health regen, UAV marks, jump pads, teleporters
------------------------------------------------------------------
spawn(function()
	while true do
		wait(0.5)
		local now = tick()
		for _, p in ipairs(playersList()) do
			local r, h = rootOf(p), humOf(p)
			if r and h and h.Health > 0 then
				-- fell off the map
				local killY = (V.state.Value == "playing" and inMatch[p]) and currentMap.killY or world.lobby.killY
				if r.Position.Y < killY and now - (spawnedAt[p] or 0) > 2 then
					h.Health = 0
				elseif regenAt[p] and now > regenAt[p] and h.Health < h.MaxHealth then
					h.Health = math.min(h.MaxHealth, h.Health + 6)
				end
			end
			if uavUntil[p] then
				if now < uavUntil[p] then
					if math.floor(now * 2) % 4 == 0 then
						uavMarks(p, true)
					end
				else
					uavUntil[p] = nil
					uavMarks(p, false)
				end
			end
		end
	end
end)

-- the team pads in the lobby (v6)
for _, tp in ipairs(world.lobby.teamPads or {}) do
	tp.part.Touched:connect(function(hit)
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if p and pd[p] and pd[p].teamPref ~= tp.team and not inMatch[p] then
			setTeamPref(p, tp.team)
		end
	end)
end

local padCooldown = {}
local function onPadTouch(hit, to, teleport)
	local p = Players:GetPlayerFromCharacter(hit.Parent)
	local r = rootOf(p)
	if not p or not r or (padCooldown[p] and tick() < padCooldown[p]) then
		return
	end
	padCooldown[p] = tick() + 1
	if teleport then
		r.CFrame = CFrame.new(to)
		return
	end
	-- launch in an arc that lands on "to"
	local from = r.Position
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local t = math.max(1.1, math.min(2.2, flat.magnitude / 45))
	local g = 196.2
	local vy = ((to.Y - from.Y) + 0.5 * g * t * t) / t
	local v = flat / t + Vector3.new(0, vy, 0)
	local bv = Instance.new("BodyVelocity")
	pcall(function()
		bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	end)
	pcall(function()
		bv.maxForce = Vector3.new(1e6, 1e6, 1e6)
	end)
	bv.Velocity = v
	bv.Parent = r
	Debris:AddItem(bv, 0.12)
end
for _, m in pairs(world.maps) do
	for _, pad in ipairs(m.pads or {}) do
		pad.part.Touched:connect(function(hit)
			onPadTouch(hit, pad.to, false)
		end)
	end
	for _, tp in ipairs(m.teleports or {}) do
		tp.part.Touched:connect(function(hit)
			onPadTouch(hit, tp.to, true)
		end)
	end
end

------------------------------------------------------------------
-- ADMIN (only asdasda)
--   :map nuketown|skyline|desert|harbor|forest   :mode ffa|tdm|elim|koth|gungame   (next match, or now with :end)
--   :weather clear|rain|storm|snow|fog|night|sandstorm   :bots easy|medium|hard   :botfill n
--   :end   :skip   :xp name amount   :level name n   :give gun name   :nuke   :ammo
------------------------------------------------------------------
local function findPlayer(text, me)
	if not text or text == "" or text == "me" then
		return me
	end
	text = string.lower(text)
	for _, p in ipairs(playersList()) do
		if string.sub(string.lower(p.Name), 1, #text) == text then
			return p
		end
	end
	return nil
end

local function onChat(p, msg)
	if string.sub(msg, 1, 1) ~= ":" or not isAdmin(p) then
		return
	end
	local words = {}
	for w in string.gmatch(string.sub(msg, 2), "%S+") do
		table.insert(words, w)
	end
	local cmd = string.lower(words[1] or "")
	local reply
	if cmd == "map" then
		local id = string.lower(words[2] or "")
		if world.maps[id] then
			nextMap = id
			reply = "Next map: " .. world.maps[id].name
		else
			local ids = {}
			for _, m in ipairs(C.Maps) do
				table.insert(ids, m.id)
			end
			reply = "Maps: " .. table.concat(ids, ", ")
		end
	elseif cmd == "mode" then
		local id = string.lower(words[2] or "")
		if C.Modes[id] then
			nextMode = id
			reply = "Next mode: " .. C.Modes[id].name
		else
			reply = "Modes: " .. table.concat(C.ModeOrder, ", ")
		end
	elseif cmd == "weather" then
		local id = string.lower(words[2] or "")
		if C.Weather[id] then
			nextWeather = id
			if V.state.Value == "playing" then
				applyWeather(id, currentMap.time) -- now, and for the next match
			end
			reply = "Weather: " .. C.Weather[id].name
		else
			reply = "Weather: clear, rain, storm, snow, fog, night, sandstorm"
		end
	elseif cmd == "bots" then
		local id = string.lower(words[2] or "")
		if id == "med" then
			id = "medium"
		end
		if C.BotLevels[id] then
			nextBots = id
			V.botLevel.Value = id -- bots in this match get it right away too
			reply = "Bots: " .. C.BotLevels[id].name
		else
			reply = "Bots: easy, medium, hard"
		end
	elseif cmd == "botfill" then
		local n = tonumber(words[2] or "")
		if n then
			C.BotFill = math.max(0, math.min(16, math.floor(n)))
			botFillOverride = C.BotFill
			Bots.fill(true)
			reply = "Bots fill up to " .. C.BotFill .. " fighters"
		else
			reply = ":botfill number (0 = no bots)"
		end
	elseif cmd == "end" then
		forceEnd = true
		reply = "Ending the match"
	elseif cmd == "skip" then
		skipWait = true
		reply = "Starting now"
	elseif cmd == "xp" or cmd == "level" then
		local t = findPlayer(words[2], p)
		local n = tonumber(words[3]) or 0
		if t and pd[t] then
			if cmd == "level" then
				pd[t].xp = math.max(0, (n - 1) * C.XPPerLevel)
				sync(t)
			else
				addXP(t, n, "ADMIN")
			end
			reply = t.Name .. " is now level " .. levelOf(pd[t].xp)
		end
	elseif cmd == "give" then
		local name = table.concat(words, " ", 2)
		for _, g in ipairs(C.Guns) do
			if string.lower(g.name) == string.lower(name) then
				local bp = p:FindFirstChild("Backpack")
				if bp then
					Guns.tool(g).Parent = bp
					reply = "Gave you a " .. g.name
				end
			end
		end
		reply = reply or "No gun called " .. name
	elseif cmd == "nuke" then
		for _, ks in ipairs(C.Killstreaks) do
			if ks.id == "nuke" then
				killstreak(p, ks)
			end
		end
		reply = "NUKE"
	elseif cmd == "ammo" then
		local char = charOf(p)
		for _, holder in ipairs({ char, p:FindFirstChild("Backpack") }) do
			if holder then
				for _, t in ipairs(holder:GetChildren()) do
					local r = t:FindFirstChild("Reserve")
					if r then
						r.Value = 9999
					end
				end
			end
		end
		reply = "Infinite-ish ammo"
	end
	reply = reply or "Commands: :map name  :mode ffa/tdm/elim/koth/gungame  :weather name  :end  :skip  :xp name n  :level name n  :give gun  :nuke  :ammo  :bots easy/medium/hard  :botfill n"
	toOne(p, "big", reply, Color3.new(0.6, 0.85, 1))
end

------------------------------------------------------------------
-- players joining / leaving
------------------------------------------------------------------
local function onPlayer(p)
	local d = { xp = 0, kills = 0, deaths = 0, wins = 0, primary = C.DefaultPrimary, secondary = C.DefaultSecondary,
		streak = 0, mKills = 0, mDeaths = 0, mScore = 0, loaded = false, dead = true, teamPref = "auto", gg = 1,
		set = { fov = 70, view = "first", cross = "White", zoom = 2, hitsound = true, minimap = true, sens = 1, aimtoggle = false, shoulder = "right", wfx = true } }
	pd[p] = d
	local saved = nil
	if store then
		pcall(function()
			saved = store:GetAsync("p_" .. p.userId)
		end)
	end
	if type(saved) == "table" then
		d.xp = tonumber(saved.xp) or 0
		d.kills = tonumber(saved.kills) or 0
		d.deaths = tonumber(saved.deaths) or 0
		d.wins = tonumber(saved.wins) or 0
		if gunByName[tostring(saved.primary)] then
			d.primary = saved.primary
		end
		if gunByName[tostring(saved.secondary)] then
			d.secondary = saved.secondary
		end
		if type(saved.set) == "table" then
			d.set = saved.set
		end
	end
	d.loaded = true
	local ls = Instance.new("IntValue")
	ls.Name = "leaderstats"
	ls.Parent = p
	local sd = Instance.new("Folder")
	sd.Name = "SData"
	sd.Parent = p
	if isAdmin(p) then
		local flag = Instance.new("BoolValue")
		flag.Name = "SAdmin"
		flag.Value = true
		flag.Parent = p
	end
	sync(p)
	p.CharacterAdded:connect(function(char)
		onCharacter(p, char)
	end)
	p.Chatted:connect(function(msg)
		onChat(p, msg)
	end)
	-- joining in the middle of a match: you play right away (teams: the smaller team)
	if V.state.Value == "playing" then
		if mode.teams then
			local r, b = playerTeamCounts()
			d.team = (r <= b) and "red" or "blue"
		end
		d.gg = 1
		inMatch[p] = true
		d.dead = false
		Bots.fill(true) -- a bot leaves to make room
	end
	-- always get a body right away (even in the middle of an elimination round), so you are never stuck
	spawnPlayer(p)
end

Players.PlayerAdded:connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p)
end
Players.PlayerRemoving:connect(function(p)
	save(p)
	pd[p] = nil
	inMatch[p] = nil
	uavUntil[p] = nil
	lastHit[p] = nil
	dmgBy[p] = nil
	delay(0.5, function()
		-- nobody left playing: stop the match (bots don't play on their own), back to the lobby
		local anyone = false
		for _, o in ipairs(Players:GetPlayers()) do
			if o ~= p and inMatch[o] then
				anyone = true
			end
		end
		if V.state.Value == "playing" and not anyone then
			forceEnd = true
			Bots.clear()
		else
			Bots.fill(true) -- a bot takes their place
		end
	end)
end)

spawn(function()
	while true do
		wait(120)
		for _, p in ipairs(playersList()) do
			save(p)
		end
	end
end)
