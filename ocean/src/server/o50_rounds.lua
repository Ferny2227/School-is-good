-- ==== o50_rounds.lua
------------------------------------------------------------------ rounds: lobby -> everyone onto the ship -> disaster -> back
local inRound = {}
local function status() toAll("status", STATE.phase, STATE.left, STATE.disaster) end
local function sendShip()
	if SHIP_UNBREAKABLE then toAll("ship", nil) return end      -- no health bar: the boat can't break
	if ship and ship.model.Parent then toAll("ship", math.max(0, math.floor(ship.hp)), ship.max, ship.sinking ~= nil, ship.kind)
	else toAll("ship", nil) end
end
-- LAST ONE STANDING: once the boat leaves, disasters keep coming one after another (with a short calm in between)
-- until only ONE player is left alive - they win (+1 Win, +150 Coins). Playing alone, it goes on until you die.
-- Then it resets: back to the sky lobby, vote, and a new boat. Every disaster you live through pays Coins.
local multi = false     -- did this game start with (or get) more than one player?
-- GHOSTS: people who join (or die) while a game is going are sent to the lobby and asked: wait for the next game,
-- or play as a ghost - aboard and see-through, everything hits them as normal, but they don't count (no Coins, no
-- Win, and the game doesn't wait for them).
local ghosts = {}
local function gameOn() return ship ~= nil and (STATE.phase == "boarding" or STATE.phase == "disaster" or STATE.phase == "calm") end
local function makeGhost(p)
	local c = p.Character
	local t = torsoOf(c)
	if not t or not gameOn() or inRound[p] or ghosts[p] then return end
	ghosts[p] = true
	for _, o in ipairs(U.desc(c)) do
		if o:IsA("BasePart") and o.Name ~= "HumanoidRootPart" then o.Transparency = math.max(o.Transparency, 0.55) end
	end
	local head = c:FindFirstChild("Head")
	if head then bill(head, "GHOST", 4, 1, 2.5, Color3.new(0.7, 0.9, 1)) end
	t.CFrame = shipFrame() * deckSpot()
	toClient(p, "ghostOffer", false)
	toClient(p, "toast", "You're a GHOST: play along, but you don't count this game.", "gold")
end
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
local function gameOver() return aliveAtSea() <= (multi and 1 or 0) end
local function board(p)
	local t = torsoOf(p.Character)
	if t and ship then
		inRound[p] = true
		t.CFrame = shipFrame() * deckSpot()
		local n = 0
		for _ in pairs(inRound) do n = n + 1 end
		if n > 1 then multi = true end
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
			inRound, diedThisGame, multi, ghosts = {}, {}, false, {}
			toAll("ghostOffer", false)
			for _, x in ipairs(players()) do board(x.p) end
			toAll("big", "ALL ABOARD THE " .. string.upper(kind) .. "!", "Survive as long as you can - it only ends when EVERYONE is dead!")
			wait(6)
			local stops = { oceanWaves() }
			if theme == "Normal" then toAll("weather", "storm") end
			local n, sunkWin = 0, false
			DIFF.level = 1
			while not gameOver() do
				n = n + 1
				-- CHALLENGE: every 4 disasters it gets harder: one more disaster stacked at once (up to 4), bigger
				-- waves, disasters hit harder, shorter calms, more Coins
				local level = math.floor((n - 1) / 4) + 1
				if level ~= DIFF.level then
					DIFF.level = level
					toAll("big", "LEVEL " .. level .. "!", "It's getting harder: " .. math.min(level, 4) .. " disasters at once, bigger waves!")
					toAll("shake", 0.6)
					wait(4)
				end
				SEA.calm = 40 + 8 * (level - 1)
				SEA.waves = math.max(SEA.waves, SEA.calm)
				local list = { nextDisaster() }
				while #list < math.min(level, 4) do
					local d = nextDisaster(list[#list])
					local dup = false
					for _, x in ipairs(list) do if x == d then dup = true end end
					if not dup then table.insert(list, d) end
				end
				local names = table.concat(list, " + ")
				STATE.phase, STATE.disaster = "disaster", "LV" .. level .. ": " .. names
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
					if gameOver() then break end
				end
				for _, stop in ipairs(dstops) do pcall(stop) end
				junk:ClearAllChildren()
				if gameOver() then break end
				-- lived through it: Coins for everyone still at sea
				local survivors = {}
				for _, x in ipairs(players()) do
					if inRound[x.p] then
						table.insert(survivors, x.p.Name)
						addCoins(x.p, 40 * DIFF.level)
						local sv = stats(x.p):FindFirstChild("Survived")
						if sv then sv.Value = sv.Value + 1 end
						x.h.Health = math.min(x.h.MaxHealth, x.h.Health + 20)      -- a little health back
						toAll("toastTo", x.p.Name, "You survived the " .. names .. "! +" .. 40 * DIFF.level .. " Coins")
					end
				end
				toAll("survivors", survivors, false)
				STATE.phase, STATE.disaster = "calm", ""
				for s = math.max(4, 10 - 2 * (DIFF.level - 1)), 1, -1 do
					STATE.left = s
					status()
					wait(1)
					if gameOver() then break end
				end
			end
			for _, stop in ipairs(stops) do pcall(stop) end
			toAll("weather", "clear")
			local winner
			for _, x in ipairs(players()) do if inRound[x.p] then winner = x.p end end
			if multi and winner then
				addCoins(winner, 150)
				local w = stats(winner):FindFirstChild("Wins")
				if w then w.Value = w.Value + 1 end
				toAll("big", string.upper(winner.Name) .. " WINS!", "Last one standing! +1 Win, +150 Coins")
				toAll("survivors", { winner.Name }, false)
			else
				toAll("big", "EVERYONE IS DEAD!", "The game resets - vote for the next boat!")
			end
			STATE.phase = "results"
			for s = 5, 1, -1 do
				STATE.left = s
				status()
				wait(1)
			end
			for _, p in ipairs(Players:GetPlayers()) do
				if ghosts[p] then pcall(function() p:LoadCharacter() end) else toLobby(p) end   -- ghosts come back solid
			end
			ghosts = {}
			toAll("ghostOffer", false)
			if ship then pcall(function() ship.model:Destroy() end) ship = nil seaShip.Value = nil end
			seaSailing.Value = false
			sendShip()
		end
	end
end)
-- the lobby boards: what's happening at sea, and the top winners
spawn(function()
	while true do
		pcall(function()
			if gameOn() then
				local alive, gh = {}, 0
				for _, x in ipairs(players()) do if inRound[x.p] then table.insert(alive, x.p.Name) end end
				for _ in pairs(ghosts) do gh = gh + 1 end
				BOARD.sea.Text = "AT SEA NOW: " .. ship.kind .. "\n" .. (STATE.disaster ~= "" and STATE.disaster or "calm...") ..
					"\nStill alive (" .. #alive .. "): " .. table.concat(alive, ", ") .. (gh > 0 and ("\nGhosts: " .. gh) or "")
			else
				BOARD.sea.Text = "NEXT BOAT LEAVES IN " .. STATE.left .. "s\nVote on the pads!"
			end
			local list = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local w = stats(p):FindFirstChild("Wins")
				table.insert(list, { n = p.Name, w = w and w.Value or 0 })
			end
			table.sort(list, function(a, b) return a.w > b.w end)
			local lines = { "TOP WINNERS" }
			for i = 1, math.min(5, #list) do table.insert(lines, i .. ". " .. list[i].n .. "  -  " .. list[i].w .. " wins") end
			BOARD.top.Text = table.concat(lines, "\n")
		end)
		wait(2)
	end
end)
Players.PlayerAdded:connect(function(p)
	stats(p)
	p.CharacterAdded:connect(function(c)
		local h = c:WaitForChild("Humanoid")
		h.Died:connect(function() inRound[p] = nil diedThisGame[p] = true ghosts[p] = nil end)
		-- HARDER: no health coming back by itself (you only get a little back for each disaster you survive)
		delay(1, function() pcall(function() local r = c:FindFirstChild("Health") if r and r:IsA("Script") then r:Destroy() end end) end)
		-- joined (or died) while a game is going: you're in the lobby - wait, or play as a ghost
		delay(2, function()
			if gameOn() and not inRound[p] and not ghosts[p] then toClient(p, "ghostOffer", true) end
		end)
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do stats(p) end
Players.PlayerRemoving:connect(function(p) swimmers[p], inRound[p] = nil, nil end)
-- jumping out of the water: a big leap up and towards the boat, high enough to land back on the deck
local swimJump = {}
remote.OnServerEvent:connect(function(p, what)
	if what == "state" then status() sendShip()
	elseif what == "ghost" then makeGhost(p)
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
	votes = votes, setTheme = setTheme, getTheme = function() return theme end, LOBBY_AT = LOBBY_AT, SHIPS = SHIPS, rogue = rogue, waveAt = waveAt, ghosts = function() return ghosts end, makeGhost = makeGhost, BOARD = BOARD, seaTime = seaTime, nextDisaster = function() return nextDisaster() end }
print("OceanServer ready")
