-- ==== o50_rounds.lua
------------------------------------------------------------------ rounds: lobby -> everyone onto the ship -> disaster -> back
local inRound = {}
local function status() toAll("status", STATE.phase, STATE.left, STATE.disaster) end
local function sendShip()
	if ship and ship.model.Parent then toAll("ship", math.max(0, math.floor(ship.hp)), ship.max, ship.sinking ~= nil, ship.kind)
	else toAll("ship", nil) end
end
-- No rounds: once the boat leaves, disasters keep coming one after another (with a short calm in between) until
-- EVERYONE is dead - then it resets: back to the sky lobby, vote, and a new boat. Every disaster you live through pays
-- Coins. If the boat sinks and someone is still alive (in a lifeboat or swimming) a minute later, they win big.
local diedThisGame = {}
-- disasters come out of a shuffled bag: every one of them comes up once before any repeats (and never twice in a row)
local bag, lastDisaster = {}, nil
local function nextDisaster(not_)
	if #bag == 0 then
		for _, d in ipairs(ORDER) do table.insert(bag, d) end
		for i = #bag, 2, -1 do local j = math.random(1, i) bag[i], bag[j] = bag[j], bag[i] end
		if bag[#bag] == lastDisaster and #bag > 1 then bag[1], bag[#bag] = bag[#bag], bag[1] end
	end
	local d = table.remove(bag)
	if d == not_ and #bag > 0 then table.insert(bag, 1, d) d = table.remove(bag) end
	lastDisaster = d
	return d
end
local function aliveAtSea()
	local n = 0
	for _, x in ipairs(players()) do if inRound[x.p] then n = n + 1 end end
	return n
end
local function board(p)
	local t = torsoOf(p.Character)
	if t and ship then
		inRound[p] = true
		t.CFrame = shipFrame() * deckSpot()
	end
end
spawn(function()
	local game_ = 0
	while true do
		while STATE.hold do wait(1) end      -- tests only
		STATE.phase, STATE.disaster = "intermission", ""
		for s = 20, 1, -1 do
			STATE.left = s
			status()
			wait(1)
		end
		while STATE.hold do wait(1) end      -- tests only
		if #Players:GetPlayers() > 0 then
			game_ = game_ + 1
			-- the votes: which theme for the whole map, which boat
			setTheme(winner("theme", THEME_ORDER, theme))
			local kind = winner("boat", BOAT_NAMES, pick(BOAT_NAMES))
			votes.boat, votes.theme = {}, {}
			refreshVotes()
			buildShip(kind)
			seaSailing.Value = true
			seaShipLen.Value = ship.len
			STATE.phase, STATE.left = "boarding", 5
			status()
			inRound, diedThisGame = {}, {}
			for _, x in ipairs(players()) do board(x.p) end
			toAll("big", "ALL ABOARD THE " .. string.upper(kind) .. "!", "Survive as long as you can - it only ends when EVERYONE is dead!")
			wait(6)
			local stops = { oceanWaves() }
			if theme == "Normal" then toAll("weather", "storm") end
			local n, sunkWin = 0, false
			while aliveAtSea() > 0 do
				n = n + 1
				local list = { nextDisaster() }
				if n >= 3 and math.random() < 0.35 then
					local second = nextDisaster(list[1])
					if second ~= list[1] then table.insert(list, second) end
				end
				local names = table.concat(list, " + ")
				STATE.phase, STATE.disaster = "disaster", names
				local texts = {}
				for _, d in ipairs(list) do table.insert(texts, DIS[d].text) end
				toAll("big", string.upper(names), table.concat(texts, "  "))
				local dstops = {}
				for _, d in ipairs(list) do
					local ok, stop = pcall(DIS[d].run)
					if ok and stop then table.insert(dstops, stop) else print("OceanServer: " .. d .. " failed: " .. tostring(stop)) end
				end
				for s = 60, 1, -1 do
					STATE.left = s
					status()
					wait(1)
					if aliveAtSea() == 0 then break end
					if ship and ship.sinking and tick() - ship.sinking > 60 then sunkWin = true break end
				end
				for _, stop in ipairs(dstops) do pcall(stop) end
				junk:ClearAllChildren()
				if aliveAtSea() == 0 or sunkWin then break end
				-- lived through it: Coins for everyone still at sea
				local survivors = {}
				for _, x in ipairs(players()) do
					if inRound[x.p] then
						table.insert(survivors, x.p.Name)
						addCoins(x.p, 40)
						local sv = stats(x.p):FindFirstChild("Survived")
						if sv then sv.Value = sv.Value + 1 end
						toAll("toastTo", x.p.Name, "You survived the " .. names .. "! +40 Coins")
					end
				end
				toAll("survivors", survivors, false)
				STATE.phase, STATE.disaster = "calm", ""
				for s = 12, 1, -1 do
					STATE.left = s
					status()
					wait(1)
					if aliveAtSea() == 0 then break end
				end
			end
			for _, stop in ipairs(stops) do pcall(stop) end
			toAll("weather", "clear")
			if sunkWin then
				local survivors = {}
				for _, x in ipairs(players()) do
					if inRound[x.p] then table.insert(survivors, x.p.Name) addCoins(x.p, 100) toAll("toastTo", x.p.Name, "You survived the sinking! +100 Coins") end
				end
				toAll("survivors", survivors, true)
				toAll("big", "YOU SURVIVED THE SINKING!", "Back to the lobby for a new boat")
			else
				toAll("big", "EVERYONE IS DEAD!", "The game resets - vote for the next boat!")
			end
			STATE.phase = "results"
			for s = 5, 1, -1 do
				STATE.left = s
				status()
				wait(1)
			end
			for _, p in ipairs(Players:GetPlayers()) do toLobby(p) end
			if ship then pcall(function() ship.model:Destroy() end) ship = nil seaShip.Value = nil end
			seaSailing.Value = false
			sendShip()
		end
	end
end)
Players.PlayerAdded:connect(function(p)
	stats(p)
	p.CharacterAdded:connect(function(c)
		local h = c:WaitForChild("Humanoid")
		h.Died:connect(function() inRound[p] = nil diedThisGame[p] = true end)
		-- someone who joins while the boat is out (and hasn't died this game) is put aboard
		if not diedThisGame[p] and ship and not ship.sinking and (STATE.phase == "disaster" or STATE.phase == "calm") then
			delay(2, function() if ship and not inRound[p] then board(p) end end)
		end
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do stats(p) end
Players.PlayerRemoving:connect(function(p) swimmers[p], inRound[p] = nil, nil end)
-- jumping out of the water: a big leap up and towards the boat, high enough to land back on the deck
local swimJump = {}
remote.OnServerEvent:connect(function(p, what)
	if what == "state" then status() sendShip()
	elseif what == "swimjump" and swimmers[p] and (not swimJump[p] or tick() - swimJump[p] > 1.5) then
		local t = torsoOf(p.Character)
		if not t then return end
		swimJump[p] = tick()
		swimJumpAt[p] = tick()
		pcall(function() swimmers[p]:Destroy() end)
		swimmers[p] = nil
		local toShip = V(SHIP_AT.X - t.Position.X, 0, SHIP_AT.Z - t.Position.Z)
		local d = toShip.magnitude
		local side = d > 1 and toShip.unit * math.min(55, d * 0.9) or V()
		local up = ship and math.max(70, (SEA.level + ship.dy + ship.deck + 14 - t.Position.Y) * 2.4) or 70
		local bv = Instance.new("BodyVelocity")
		bv.maxForce = V(1e5, 1e5, 1e5)
		bv.velocity = side + V(0, math.min(160, up), 0)
		bv.Parent = t
		Debris:AddItem(bv, 0.45)
		toClient(p, "swim", false)
	end
end)

------------------------------------------------------------------ the fast loop
spawn(function()
	local last = tick()
	local n = 0
	while true do
		wait()
		local now = tick()
		local dt = math.min(0.2, now - last)
		last = now
		pcall(stepSea, dt)
		local ok, err = pcall(stepShip, dt, now)
		if not ok then print("OceanServer: ship: " .. tostring(err)) end
		n = n + 1
		if n % 3 == 0 then
			ok, err = pcall(stepSwimmers, dt * 3)
			if not ok then print("OceanServer: water: " .. tostring(err)) end
		end
		if n % 10 == 0 then sendShip() end
	end
end)
_G.OceanDebug = { DIS = DIS, SEA = SEA, swimmers = swimmers, STATE = STATE, getShip = function() return ship end,
	buildShip = buildShip, damageShip = damageShip, deckSpot = deckSpot, onShip = onShip, shipFrame = shipFrame,
	votes = votes, setTheme = setTheme, getTheme = function() return theme end, LOBBY_AT = LOBBY_AT, SHIPS = SHIPS, rogue = rogue, waveAt = waveAt, seaTime = seaTime, nextDisaster = function() return nextDisaster() end }
print("OceanServer ready")
