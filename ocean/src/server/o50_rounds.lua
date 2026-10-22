-- ==== o50_rounds.lua
------------------------------------------------------------------ rounds: lobby -> everyone onto the ship -> disaster -> back
local inRound = {}
local function status() toAll("status", STATE.phase, STATE.left, STATE.disaster) end
local function sendShip()
	if ship and ship.model.Parent then toAll("ship", math.max(0, math.floor(ship.hp)), ship.max, ship.sinking ~= nil, ship.kind)
	else toAll("ship", nil) end
end
spawn(function()
	local round = 0
	while true do
		while STATE.hold do wait(1) end      -- tests only
		STATE.phase, STATE.disaster = "intermission", ""
		for s = 20, 1, -1 do
			STATE.left = s
			status()
			wait(1)
		end
		if #Players:GetPlayers() > 0 then
			round = round + 1
			-- the votes: which theme for the whole map, which boat
			setTheme(winner("theme", THEME_ORDER, theme))
			local kind = winner("boat", BOAT_NAMES, pick(BOAT_NAMES))
			votes.boat, votes.theme = {}, {}
			refreshVotes()
			-- build the boat and put the whole lobby on it
			buildShip(kind)
			seaSailing.Value = true
			seaShipLen.Value = ship.len
			STATE.phase = "boarding"
			STATE.left = 5
			status()
			inRound = {}
			for _, x in ipairs(players()) do
				inRound[x.p] = true
				x.t.CFrame = shipFrame() * deckSpot()
			end
			toAll("big", "ALL ABOARD THE " .. string.upper(kind) .. "!", theme .. " theme  -  explore the rooms... something is coming!")
			wait(6)
			local list = { pick(ORDER) }
			if round >= 3 and math.random() < 0.3 then
				local second = pick(ORDER)
				if second ~= list[1] then table.insert(list, second) end
			end
			local names = table.concat(list, " + ")
			STATE.phase, STATE.disaster = "disaster", names
			local texts = {}
			for _, n in ipairs(list) do table.insert(texts, DIS[n].text) end
			toAll("big", string.upper(names), table.concat(texts, "  "))
			local stops = { oceanWaves() }
			for _, n in ipairs(list) do
				local ok, stop = pcall(DIS[n].run)
				if ok and stop then table.insert(stops, stop) else print("OceanServer: " .. n .. " failed: " .. tostring(stop)) end
			end
			for s = 75, 1, -1 do
				STATE.left = s
				status()
				wait(1)
			end
			for _, stop in ipairs(stops) do pcall(stop) end
			junk:ClearAllChildren()
			-- who made it? (alive, and in the round from the start)
			local survivors = {}
			local sunk = ship and ship.sinking ~= nil
			for _, x in ipairs(players()) do
				if inRound[x.p] then
					table.insert(survivors, x.p.Name)
					local reward = sunk and 60 or 40   -- surviving a sinking is worth more
					addCoins(x.p, reward)
					local s = stats(x.p):FindFirstChild("Survived")
					if s then s.Value = s.Value + 1 end
					toAll("toastTo", x.p.Name, "You survived the " .. names .. "! +" .. reward .. " Coins")
				end
			end
			toAll("survivors", survivors, sunk)
			STATE.phase = "results"
			for s = 5, 1, -1 do
				STATE.left = s
				status()
				wait(1)
			end
			for _, x in ipairs(players()) do toLobby(x.p) end
			if ship then pcall(function() ship.model:Destroy() end) ship = nil end
			seaSailing.Value = false
			sendShip()
		end
	end
end)
Players.PlayerAdded:connect(function(p)
	stats(p)
	p.CharacterAdded:connect(function(c)
		local h = c:WaitForChild("Humanoid")
		h.Died:connect(function() inRound[p] = nil end)
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do stats(p) end
Players.PlayerRemoving:connect(function(p) swimmers[p], inRound[p] = nil, nil end)
remote.OnServerEvent:connect(function(p, what)
	if what == "state" then status() sendShip() end
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
	votes = votes, setTheme = setTheme, getTheme = function() return theme end, LOBBY_AT = LOBBY_AT, SHIPS = SHIPS, rogue = rogue, waveAt = waveAt, seaTime = seaTime }
print("OceanServer ready")
