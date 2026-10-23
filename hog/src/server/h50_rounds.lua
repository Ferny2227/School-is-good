-- ==== h50_rounds.lua
------------------------------------------------------------------ rounds: lobby -> the map -> the Hog is let out -> escape or get caught
local ROUND_TIME = 8 * 60
local RELEASE = 15
local INTERMISSION = 20
local escaped, caughtList = {}, {}
local modeName, hogName = "Bot", "The Hog"
local PLAYER_MODES = { ["Player"] = true, ["Player + Bot"] = true, ["Infection"] = true, ["Traitor"] = true }
local inRound = {}          -- everyone who started this round (they respawn in the lobby afterwards)
local function status()
	local n = 0
	for _ in pairs(survivors) do n = n + 1 end
	local r = 0
	for p in pairs(ready) do if p.Parent then r = r + 1 end end
	toAll("status", STATE.phase, math.max(0, math.floor(STATE.left)), n, MAP and MAP.name or "", modeName, hogName, r)
end
local function toLobby(p)
	local t = torsoOf(p.Character)
	if t then t.CFrame = CFrame.new(lobbySpot()) end
end
local function flashlight(p)
	local head = p.Character and p.Character:FindFirstChild("Head")
	if not head or head:FindFirstChild("Flashlight") then return end
	local l = Instance.new("SpotLight")
	l.Name = "Flashlight"
	l.Range = 40
	l.Angle = 55
	l.Brightness = 2
	l.Color = Color3.new(1, 0.95, 0.8)
	pcall(function() l.Face = Enum.NormalId.Front end)
	l.Parent = head
end
local function leaveMap(p, why)
	if not survivors[p] then return end
	survivors[p] = nil
	stuck[p] = nil
	setCrouch(p, false)
	local t = torsoOf(p.Character)
	if holding[p] then dropItem(p, t and t.Position) end
	if why ~= "infect" then toClient(p, "role", nil) end
end
function catchPlayer(p, by)
	if not survivors[p] then return end
	leaveMap(p, modeName == "Infection" and "infect")
	toClient(p, "caught")
	if modeName == "Infection" then
		-- infected: you turn into a Hog and hunt the others
		sayAll(p.Name .. " got INFECTED!", "red")
		delay(1.8, function()
			if not p.Parent or STATE.phase ~= "hunt" then return end
			setCrouch(p, false)
			hogPlayers[p] = true
			morph(p)
			toClient(p, "role", "hog")
			toClient(p, "big", "YOU'RE A HOG NOW!", "Catch the others!")
		end)
		return
	end
	table.insert(caughtList, p.Name)
	sayAll(p.Name .. " was caught" .. (by == traitor and by and " by the TRAITOR!" or " by the Hog!"), "red")
	delay(2.5, function() if p.Parent and not survivors[p] then toLobby(p) end end)
end
local function escape(p)
	if not survivors[p] then return end
	leaveMap(p)
	escaped[p] = true
	local ls = stats(p)
	ls.Escapes.Value = ls.Escapes.Value + 1
	addCoins(p, 50)
	saveStats(p)
	toClient(p, "big", "YOU ESCAPED!", "+50 Coins  +1 Escape")
	sayAll(p.Name .. " ESCAPED!", "green")
	delay(2, function() if p.Parent and not survivors[p] then toLobby(p) end end)
end
local function escapeStep()
	if not MAP or not MAP.exitDone then return end
	local z = MAP.exitZone
	for p in pairs(survivors) do
		local t = torsoOf(p.Character)
		if t and t.Position.X > z[1] and t.Position.X < z[3] and t.Position.Z > z[2] and t.Position.Z < z[4] then escape(p) end
	end
end
-- who's down in a vent tunnel (below the floor)?
local function ventStep()
	for p in pairs(survivors) do
		local t = torsoOf(p.Character)
		crawling[p] = (t and t.Position.Y < -1) or nil
	end
end
local function survivorCount() local n = 0 for _ in pairs(survivors) do n = n + 1 end return n end
local function clearMap()
	for _, tr in ipairs(traps) do pcall(function() tr.model:Destroy() end) end
	traps = {}
	if MAP then MAP.model:Destroy() end
	MAP = nil
	HOGS = {}
end
-- when a Hog player is gone and there's no Hog left, a bot takes over
local function needHog(why)
	if STATE.phase ~= "hunt" and STATE.phase ~= "release" or not MAP then return end
	if next(hogPlayers) or #HOGS > 0 or modeName == "Traitor" and traitor then return end
	local H = newBot()
	H.mode = STATE.phase == "hunt" and "patrol" or "wait"
	if STATE.phase == "hunt" then openGate() end
	hogName = "The Hog"
	sayAll(why .. " - a BOT HOG takes over!", "red")
end

-- start a round with everyone who pressed PLAY
local function startRound()
	local plist = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local h = p.Character and p.Character:FindFirstChild("Humanoid")
		if ready[p] and h and h.Health > 0 and torsoOf(p.Character) then table.insert(plist, p) end
	end
	if #plist == 0 then return false end
	local mapName = winner("map", MAP_NAMES)
	modeName = winner("mode", MODE_NAMES)
	if #plist < 2 and PLAYER_MODES[modeName] then modeName = "Bot" end
	votes.map, votes.mode = {}, {}
	refreshVotes()
	clearMap()
	buildMap(mapName)
	MAP.code = string.format("%04d", math.random(0, 9999))
	for _, it in ipairs(MAP.def.items) do spawnItem(it[1]) end
	spawnItem("Code Note")
	hookLocks()
	escaped, caughtList, survivors, holding, stuck, crouching, inRound = {}, {}, {}, {}, {}, {}, {}
	gunShots, crawling = {}, {}
	hogPlayers, traitor = {}, nil
	hogName = "The Hog"
	shuffle(plist)
	if modeName == "Player" or modeName == "Player + Bot" or modeName == "Infection" then
		hogPlayers[plist[1]] = true
		hogName = plist[1].Name
	elseif modeName == "Traitor" then
		traitor = plist[1]
	end
	local S = MAP.start
	for i, p in ipairs(plist) do
		inRound[p] = true
		local t = torsoOf(p.Character)
		if hogPlayers[p] then
			t.CFrame = CFrame.new(V(MAP.pen.cx, 3.5, MAP.pen.cz))
			morph(p)
			toClient(p, "role", "hog")
			toClient(p, "big", "YOU ARE THE HOG!", modeName == "Infection" and "Everyone you catch turns into a Hog too!" or "Catch everyone before they escape. Use the Trap tool to set traps.")
		else
			local a = (i / #plist) * math.pi * 2
			t.CFrame = CFrame.new(V(S.cx + math.cos(a) * 5, 3.5, S.cz + math.sin(a) * 5))
			local h = p.Character:FindFirstChild("Humanoid")
			if h then h.WalkSpeed = 16 end
			flashlight(p)
			if p == traitor then
				toClient(p, "role", "traitor")
				toClient(p, "big", "YOU ARE THE TRAITOR!", "Shh... walk up to the others and tag them (once every 25 seconds). Don't let them escape!")
			else
				survivors[p] = true
				toClient(p, "role", "survivor")
				toClient(p, "hold", nil)
				toClient(p, "big", "FIND THE ITEMS - ESCAPE!", modeName == "Traitor" and "One of you is a TRAITOR..." or "Click things to pick them up. Figure out where they go.")
			end
		end
	end
	if modeName == "Bot" or modeName == "Player + Bot" or modeName == "Traitor" then newBot() end
	if modeName == "Swarm" then
		for i, off in ipairs({ V(-4, 0, -5), V(4, 0, 0), V(-3, 0, 5) }) do newBot(off, 0.92) end
	end
	STATE.phase, STATE.left = "release", RELEASE
	return true
end
local function endRound()
	local names = {}
	for p in pairs(escaped) do if p.Parent then table.insert(names, p.Name) end end
	local text
	if #names == 0 then
		text = modeName == "Traitor" and traitor and ("THE TRAITOR (" .. traitor.Name .. ") WINS!") or "THE HOG WINS!"
		for p in pairs(hogPlayers) do if p.Parent then addCoins(p, 40) end end
		if traitor and traitor.Parent then addCoins(traitor, 60) end
	else
		text = (#names == 1 and names[1] or (#names .. " PLAYERS")) .. " ESCAPED!"
	end
	toAll("big", text, #caughtList > 0 and ("Caught: " .. table.concat(caughtList, ", ")) or "Nobody was caught.")
	boardText.Text = "LAST ROUND (" .. (MAP and MAP.name or "?") .. ", " .. modeName .. "): " .. text ..
		"   Escaped: " .. (#names > 0 and table.concat(names, ", ") or "nobody")
	toAll("last", boardText.Text)
	STATE.phase, STATE.left = "results", 6
	status()
	wait(6)
	for p in pairs(survivors) do survivors[p] = nil end
	for _, p in ipairs(Players:GetPlayers()) do
		toClient(p, "role", nil)
		toClient(p, "hold", nil)
		takeTool(p)
		-- everyone who played starts fresh in the lobby (no pig mask, no crouch, no flashlight)
		if inRound[p] then pcall(function() p:LoadCharacter() end) else toLobby(p) end
		saveStats(p)
	end
	hogPlayers, traitor, inRound, crouching = {}, nil, {}, {}
	clearMap()
end

------------------------------------------------------------------ players
local function setup(p)
	stats(p)
	loadStats(p)
	p.CharacterAdded:connect(function(c)
		wait(0.2)
		if not survivors[p] and not hogPlayers[p] and p ~= traitor then toLobby(p) end
		local h = c:WaitForChild("Humanoid")
		h.Died:connect(function()
			if survivors[p] then
				leaveMap(p)
				table.insert(caughtList, p.Name)
			end
			if hogPlayers[p] then
				hogPlayers[p] = nil
				needHog("The Hog player is gone")
			end
			if p == traitor then traitor = nil end
		end)
	end)
	refreshVotes()
	if boardText.Text ~= "" then toClient(p, "last", boardText.Text) end
end
for _, p in ipairs(Players:GetPlayers()) do spawn(function() setup(p) end) end
Players.PlayerAdded:connect(setup)
Players.PlayerRemoving:connect(function(p)
	saveStats(p)
	survivors[p], holding[p], votes.map[p], votes.mode[p], ready[p], crouching[p] = nil, nil, nil, nil, nil, nil
	if p == traitor then traitor = nil end
	if hogPlayers[p] then
		hogPlayers[p] = nil
		needHog("The Hog player left")
	end
end)
remote.OnServerEvent:connect(function(p, what, a, b)
	if what == "click" then clickPart(p, a)
	elseif what == "shoot" then shoot(p, a)
	elseif what == "code" then enterCode(p, a)
	elseif what == "crouch" then setCrouch(p, a == true)
	elseif what == "trap" then hogTrap(p)
	elseif what == "play" then ready[p] = true status()
	elseif what == "menu" then ready[p] = nil
	elseif what == "vote" then vote(p, a, b) end
end)
pcall(function() game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do saveStats(p) end wait(2) end) end)

------------------------------------------------------------------ the main loop
_G.HogDebug = { STATE = STATE, MAPS = MAPS, buildMap = buildMap, getMap = function() return MAP end, getHog = function() return HOGS[1] end,
	hogs = function() return HOGS end, survivors = function() return survivors end, holding = function() return holding end, spawnItem = spawnItem,
	solve = solve, votes = votes, route = route, roomAt = roomAt, catchPlayer = catchPlayer, hogPlayer = function() return next(hogPlayers) end,
	hogPlayers = function() return hogPlayers end, traitor = function() return traitor end, crouching = function() return crouching end,
	traps = function() return traps end, placeTrap = placeTrap, shoot = shoot, enterCode = enterCode, crawling = function() return crawling end, LOBBY = LOBBY, ready = ready, clickPart = clickPart, mode = function() return modeName end }
spawn(function()
	-- fast systems: the bots, Hog players' and the Traitor's tags, traps, the exit
	local last = tick()
	local reported = {}
	while true do
		wait(0.1)
		local now = tick()
		local dt = math.min(0.3, now - last)
		last = now
		if STATE.phase == "hunt" and MAP and not STATE.hold then
			for _, sys in ipairs({ { "vents", ventStep }, { "bot", function() botsStep(dt) end }, { "hog", hogPlayerStep }, { "traps", trapStep }, { "exit", escapeStep } }) do
				local name, f = sys[1], sys[2]
				local ok, err = pcall(f)
				if not ok and not reported[name] then
					reported[name] = true
					spawn(function() error("Hog " .. name .. ": " .. tostring(err)) end)
				end
			end
		end
	end
end)
spawn(function()
	while true do
		STATE.phase, STATE.left = "lobby", INTERMISSION
		while STATE.left > 0 do
			status()
			wait(1)
			-- the countdown only runs while someone has pressed PLAY
			local any = false
			for p in pairs(ready) do if p.Parent then any = true else ready[p] = nil end end
			if any then STATE.left = STATE.left - 1 else STATE.left = INTERMISSION end
		end
		local ok, started = pcall(startRound)
		if not ok then spawn(function() error("startRound: " .. tostring(started)) end) end
		if ok and started then
			-- the Hog waits in its pen
			while STATE.left > 0 do
				status()
				wait(1)
				STATE.left = STATE.left - 1
			end
			openGate()
			for i, H in ipairs(HOGS) do
				H.mode = "patrol"
				H.pause = (i - 1) * 4
			end
			local who = modeName == "Swarm" and "THREE HOGS ARE LOOSE!" or "THE HOG IS LOOSE!"
			toAll("big", who, next(hogPlayers) and (hogName .. " is the Hog!") or "Hide... and find those items!")
			STATE.phase, STATE.left = "hunt", ROUND_TIME
			while STATE.left > 0 and survivorCount() > 0 do
				status()
				wait(1)
				if not STATE.hold then STATE.left = STATE.left - 1 end
			end
			if survivorCount() > 0 then
				-- time's up: anyone still inside is caught
				for p in pairs(survivors) do leaveMap(p) table.insert(caughtList, p.Name) end
			end
			endRound()
		end
	end
end)
