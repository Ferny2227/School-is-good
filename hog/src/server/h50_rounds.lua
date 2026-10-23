-- ==== h50_rounds.lua
------------------------------------------------------------------ rounds: lobby -> the map -> the Hog is let out -> escape or get caught
local ROUND_TIME = 8 * 60
local RELEASE = 15
local INTERMISSION = 20
local escaped, caughtList = {}, {}
local modeName, hogName = "Bot Hog", "The Hog"
local function status()
	local n = 0
	for _ in pairs(survivors) do n = n + 1 end
	toAll("status", STATE.phase, math.max(0, math.floor(STATE.left)), n, MAP and MAP.name or "", modeName, hogName)
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
	local t = torsoOf(p.Character)
	if holding[p] then dropItem(p, t and t.Position) end
	toClient(p, "role", nil)
end
function catchPlayer(p)
	if not survivors[p] then return end
	leaveMap(p)
	table.insert(caughtList, p.Name)
	toClient(p, "caught")
	sayAll(p.Name .. " was caught by the Hog!", "red")
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
local function survivorCount() local n = 0 for _ in pairs(survivors) do n = n + 1 end return n end
local function clearMap()
	for _, tr in ipairs(traps) do pcall(function() tr.model:Destroy() end) end
	traps = {}
	if MAP then MAP.model:Destroy() end
	MAP, HOG = nil, nil
end

-- start a round with everyone who's in the lobby
local function startRound()
	local plist = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local h = p.Character and p.Character:FindFirstChild("Humanoid")
		if h and h.Health > 0 and torsoOf(p.Character) then table.insert(plist, p) end
	end
	if #plist == 0 then return false end
	local mapName = winner("map", MAP_NAMES)
	modeName = winner("mode", MODE_NAMES)
	if #plist < 2 then modeName = "Bot Hog" end
	votes.map, votes.mode = {}, {}
	refreshVotes()
	clearMap()
	buildMap(mapName)
	for _, it in ipairs(MAP.def.items) do spawnItem(it[1]) end
	hookLocks()
	escaped, caughtList, survivors, holding, stuck = {}, {}, {}, {}, {}
	hogPlayer, hogTrapLeft = nil, 3
	if modeName == "Player Hog" then
		hogPlayer = pick(plist)
		hogName = hogPlayer.Name
	else
		hogName = "The Hog"
	end
	local S = MAP.start
	for i, p in ipairs(plist) do
		local t = torsoOf(p.Character)
		if p == hogPlayer then
			t.CFrame = CFrame.new(V(MAP.pen.cx, 3.5, MAP.pen.cz))
			morph(p)
			toClient(p, "role", "hog")
			toClient(p, "big", "YOU ARE THE HOG!", "Catch everyone before they escape. Click with the Trap tool to set traps.")
		else
			survivors[p] = true
			local a = (i / #plist) * math.pi * 2
			t.CFrame = CFrame.new(V(S.cx + math.cos(a) * 5, 3.5, S.cz + math.sin(a) * 5))
			local h = p.Character:FindFirstChild("Humanoid")
			if h then h.WalkSpeed = 16 end
			flashlight(p)
			toClient(p, "role", "survivor")
			toClient(p, "hold", nil)
			toClient(p, "big", "FIND THE ITEMS - ESCAPE!", "Click items to pick them up (one at a time) and click locks to use them.")
		end
	end
	if modeName == "Bot Hog" then newBot() end
	sendLocks()
	STATE.phase, STATE.left = "release", RELEASE
	return true
end
local function endRound()
	local names = {}
	for p in pairs(escaped) do if p.Parent then table.insert(names, p.Name) end end
	local text
	if #names == 0 then
		text = "THE HOG WINS!"
		if hogPlayer and hogPlayer.Parent then addCoins(hogPlayer, 40) end
	else
		text = (#names == 1 and names[1] or (#names .. " PLAYERS")) .. " ESCAPED!"
	end
	toAll("big", text, #caughtList > 0 and ("Caught: " .. table.concat(caughtList, ", ")) or "Nobody was caught.")
	pcall(function()
		boardText.Text = "ESCAPE THE HOG\n\nLAST ROUND (" .. (MAP and MAP.name or "?") .. "): " .. text ..
			"\nEscaped: " .. (#names > 0 and table.concat(names, ", ") or "nobody") ..
			"\n\nFind items, unlock the doors, open the EXIT.\nOnly ONE item at a time!"
	end)
	STATE.phase, STATE.left = "results", 6
	status()
	wait(6)
	for p in pairs(survivors) do survivors[p] = nil end
	for _, p in ipairs(Players:GetPlayers()) do
		toClient(p, "role", nil)
		toClient(p, "hold", nil)
		takeTool(p)
		if p == hogPlayer then
			pcall(function() p:LoadCharacter() end)
		else
			toLobby(p)
		end
		saveStats(p)
	end
	hogPlayer = nil
	clearMap()
	toAll("locks", {}, "")
end

------------------------------------------------------------------ players
local function setup(p)
	stats(p)
	loadStats(p)
	p.CharacterAdded:connect(function(c)
		wait(0.2)
		if not survivors[p] and p ~= hogPlayer then toLobby(p) end
		local h = c:WaitForChild("Humanoid")
		h.Died:connect(function()
			if survivors[p] then
				leaveMap(p)
				table.insert(caughtList, p.Name)
			end
			if p == hogPlayer and STATE.phase == "hunt" and MAP then
				-- the Hog player died: the bot takes over
				hogPlayer = nil
				modeName = "Bot Hog"
				hogName = "The Hog"
				newBot()
				HOG.mode = "patrol"
				sayAll("The Hog player is gone - the BOT HOG takes over!", "red")
			end
		end)
	end)
	toClient(p, "howto")
end
for _, p in ipairs(Players:GetPlayers()) do spawn(function() setup(p) end) end
Players.PlayerAdded:connect(setup)
Players.PlayerRemoving:connect(function(p)
	saveStats(p)
	survivors[p], holding[p], votes.map[p], votes.mode[p] = nil, nil, nil, nil
	if p == hogPlayer and STATE.phase == "hunt" and MAP then
		hogPlayer = nil
		modeName, hogName = "Bot Hog", "The Hog"
		newBot()
		HOG.mode = "patrol"
		sayAll("The Hog player left - the BOT HOG takes over!", "red")
	end
end)
remote.OnServerEvent:connect(function(p, what)
	if what == "trap" then hogTrap(p) end
end)
pcall(function() game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do saveStats(p) end wait(2) end) end)

------------------------------------------------------------------ the main loop
_G.HogDebug = { STATE = STATE, MAPS = MAPS, buildMap = buildMap, getMap = function() return MAP end, getHog = function() return HOG end,
	survivors = function() return survivors end, holding = function() return holding end, spawnItem = spawnItem, solve = solve,
	votes = votes, route = route, roomAt = roomAt, catchPlayer = catchPlayer, hogPlayer = function() return hogPlayer end,
	traps = function() return traps end, placeTrap = placeTrap, LOBBY = LOBBY }
spawn(function()
	-- fast systems: the bot, the Player Hog's tag, traps, the exit
	local last = tick()
	local reported = {}
	while true do
		wait(0.1)
		local now = tick()
		local dt = math.min(0.3, now - last)
		last = now
		if STATE.phase == "hunt" and MAP and not STATE.hold then
			for name, f in pairs({ bot = function() botStep(dt) end, hog = hogPlayerStep, traps = trapStep, exit = escapeStep }) do
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
			if #Players:GetPlayers() > 0 then STATE.left = STATE.left - 1 end
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
			if HOG then HOG.mode = "patrol" end
			toAll("big", "THE HOG IS LOOSE!", modeName == "Player Hog" and (hogName .. " is the Hog!") or "Hide... and find those items!")
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
