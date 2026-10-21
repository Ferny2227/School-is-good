-- Runs AirportServer in the mock: claim airports, buy everything, simulate play, save + reload.
-- Globals from the runner: SERVER_SOURCE, SIM_SECONDS
local MOCK = MOCK
local printed = {}
local realprint = print
function print(...)
	local t = {}
	for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
	local s = table.concat(t, " ")
	table.insert(printed, s)
	if s:find("failed") or s:find("rror") then table.insert(MOCK.errors, "printed: " .. s) end
end
-- map: 10 plots like the real place
local map = MOCK.new("Model", workspace) map.Name = "AirportMap"
local plots = MOCK.new("Model", map) plots.Name = "Plots"
local xs = { -1400, -700, 0, 700, 1400 }
for i = 1, 10 do
	local x = xs[(i - 1) % 5 + 1]
	local south = i > 5
	local pm = MOCK.new("Model", plots) pm.Name = "Plot" .. i
	local cf = south and (CFrame.new(x, 0.5, -360) * CFrame.Angles(0, math.pi, 0)) or CFrame.new(x, 0.5, 360)
	MOCK.part(pm, "Origin", Vector3.new(1, 1, 1), cf)
	MOCK.part(pm, "Base", Vector3.new(420, 0.1, 620), cf * CFrame.new(0, -0.4, 310))
	for _, c in ipairs({ { -210, 310, 2, 620 }, { 210, 310, 2, 620 }, { 0, 0.5, 422, 1 }, { 0, 619.5, 422, 1 } }) do
		MOCK.part(pm, "Curb", Vector3.new(c[3], 0.6, c[4]), cf * CFrame.new(c[1], -0.1, c[2]))
	end
end
local trees = MOCK.new("Model", map) trees.Name = "Trees"
for i = 1, 60 do
	local x, z = math.random(-1700, 1700), math.random(-1250, 1250)
	MOCK.part(trees, "Trunk", Vector3.new(2, 10, 2), CFrame.new(x, 5, z))
	MOCK.part(trees, "Leaves", Vector3.new(8, 8, 8), CFrame.new(x, 12, z))
end
local plaza = MOCK.new("Model", map) plaza.Name = "Plaza"
MOCK.part(plaza, "WelcomeBoard", Vector3.new(60, 14, 1), CFrame.new(0, 10, -200))
local hub = MOCK.new("Model", map) hub.Name = "Hub"
MOCK.part(hub, "HubSign", Vector3.new(120, 10, 1), CFrame.new(-300, 40, -177))
MOCK.part(map, "Spawn", Vector3.new(14, 1, 14), CFrame.new(0, 1, -215))
local ground = MOCK.new("Model", map) ground.Name = "Ground"

-- run the server
MOCK.pushOnResize = true
local fn, err = loadstring(SERVER_SOURCE, "=AirportServer")
if not fn then error(err) end
spawn(fn)
MOCK.run(3)
local D = _G.AirportDebug
assert(D, "server did not start: " .. table.concat(MOCK.errors, "\n"))
local G, A, CATALOG = D.G, D.A, D.CATALOG
local out = {}
local function say(s) table.insert(out, s) end
say("catalog items: " .. #CATALOG)
-- the enlarged ground must stay on the ground
for i, pl in ipairs(G.plots) do
	local pm = plots:FindFirstChild("Plot" .. i)
	for _, part in ipairs(pm:GetChildren()) do
		local l = pl.cf:inverse() * part.CFrame.p
		if math.abs(l.Y) > 1 then table.insert(MOCK.errors, "Plot" .. i .. "." .. part.Name .. " is at height " .. l.Y) end
	end
	local base = pm:FindFirstChild("Base")
	if i == 1 then say(string.format("plot 1 base: size %s, centre local %s", tostring(base.Size), tostring(pl.cf:inverse() * base.CFrame.p))) end
end

local function cashOf(p) return p.leaderstats.Cash end
local function buyAll(plot, player)
	cashOf(player).Value = 1e13
	local rounds = 0
	while true do
		rounds = rounds + 1
		local any = false
		for _, it in ipairs(CATALOG) do
			if A.available(plot, it) then
				A.buy(plot, it, player)
				any = true
			end
		end
		MOCK.run(0.1)
		if not any or rounds > 400 then break end
	end
	local n = 0
	for _ in pairs(plot.bought) do n = n + 1 end
	return n, rounds
end

D.FLY.CRUISE = CRUISE_SECONDS or D.FLY.CRUISE   -- shorter flights so the test sees whole trips
D.FLY.MINCRUISE = math.floor(D.FLY.CRUISE * 0.8)
local p1 = MOCK.addPlayer("tester", 111)
MOCK.run(1)
MOCK.makeCharacter(p1)
MOCK.run(1)
local plot = G.plots[3]
A.claim(plot, p1)
MOCK.run(1)
-- pads: every pad must stand on something (checked by the runner via MOCK.pads)
local n, rounds = buyAll(plot, p1)
say("plot 3 bought " .. n .. " / " .. #CATALOG .. " in " .. rounds .. " rounds")
local notBought = {}
for _, it in ipairs(CATALOG) do if not plot.bought[it.key] then table.insert(notBought, it.key) end end
if #notBought > 0 then say("NOT BOUGHT: " .. table.concat(notBought, ", ")) end

-- simulate
local npts = {}
for k, v in pairs(plot.pts) do table.insert(npts, k .. "=" .. #v) end
table.sort(npts)
say("visit points: " .. table.concat(npts, " "))
local inv = plot.cf:inverse()
local levels, states, guestRooms, maxPeople = {}, {}, 0, 0
local liftStats, progress, stuck = {}, {}, {}
local maxPax = {}
local gateWaitSum, walkSum, boardSum, gaveUp = 0, 0, 0, 0
local skyTimes, lastState = {}, {}
local seenKinds = {}
local T = SIM_SECONDS or 240
for s = 1, T do
	MOCK.run(1, 0.05)
	maxPeople = math.max(maxPeople, #plot.People:GetChildren())
	for _, w in ipairs(G.walkers) do
		if w.plot == plot then
			local l = inv * w.pos
			local y = math.floor(l.y + 0.5)
			levels[y] = (levels[y] or 0) + 1
			if w.kind then seenKinds[w.kind] = true end
			if w.inRoom then guestRooms = guestRooms + 1 end
		end
	end
	for k, gp in pairs(plot.gatePlanes) do
		-- whole trips only: from take-off (departing -> cruising) to starting the approach (cruising -> arriving)
		local ls = lastState[gp]
		if not ls then
			lastState[gp] = { state = gp.state }
		elseif ls.state ~= gp.state then
			if ls.state == "cruising" and ls.since then table.insert(skyTimes, s - ls.since) end
			lastState[gp] = { state = gp.state, since = (ls.state == "departing" and gp.state == "cruising") and s or nil }
		end
		states[tostring(gp.n) .. ":" .. gp.state] = true
		if gp.state == "cruising" then
			local h = (plot.cf:inverse() * gp.root.CFrame.p).Y
			minCruise = math.min(minCruise or 1e9, h)
		end
		if gp.state == "parked" and gp.pax > (maxPax[gp.n] or 0) then maxPax[gp.n] = gp.pax end
	end
	for _, w in ipairs(G.walkers) do
		if w.plot == plot and w.kind then seenKinds[w.kind] = true end
		if w.plot == plot and w.kind == "passenger" then
			local t = w.route[w.i]
			if t and t.planeWait and w.waiting then gateWaitSum = gateWaitSum + 1 else walkSum = walkSum + 1 end
			if t and t == w.route[1] and w.route[1].p and w.giveUpSeen == nil and w.route ~= w.origRoute and w.origRoute then gaveUp = gaveUp + 1 w.giveUpSeen = true end
			w.origRoute = w.origRoute or w.route
		end
	end
	for _, g in pairs(plot.gates) do if g.n <= 4 and D.FLY.boarding(g) then boardSum = boardSum + 1 end end
	for id, L in pairs(plot.lifts) do
		local st = liftStats[id] or { stops = {}, opens = 0, last = nil }
		liftStats[id] = st
		if L.state == "open" and st.last ~= L.idx then st.opens = st.opens + 1 st.stops[L.idx] = true end
		st.last = L.state == "open" and L.idx or nil
	end
	for _, w in ipairs(G.walkers) do
		if w.plot == plot then
			local pr = progress[w]
			if not pr or pr.i ~= w.i then progress[w] = { i = w.i, t = s }
			elseif s - pr.t > 200 then stuck[w] = (w.kind or "?") .. " stuck at route point " .. w.i .. "/" .. #w.route .. (w.route[w.i] and (w.route[w.i].liftWait and " (waiting for lift)" or (w.route[w.i].ride and " (riding lift)" or "")) or "") end
		end
	end
end
local ls = {}
for id, st in pairs(liftStats) do
	local stops = {}
	for i in pairs(st.stops) do table.insert(stops, i) end
	table.sort(stops)
	table.insert(ls, id .. ": opened " .. st.opens .. " times at levels " .. table.concat(stops, ","))
end
table.sort(ls)
say("lifts: " .. table.concat(ls, " | "))
local sk = {}
for w, why in pairs(stuck) do if w.model.Parent then table.insert(sk, why) end end
say("stuck walkers: " .. #sk)
for i = 1, math.min(8, #sk) do say("  " .. sk[i]) end
local ys = {}
for y, c in pairs(levels) do table.insert(ys, y) end
table.sort(ys)
local lv = {}
for _, y in ipairs(ys) do table.insert(lv, y .. "=" .. levels[y]) end
say("walker feet heights (local y = samples): " .. table.concat(lv, " "))
local st = {}
for k in pairs(states) do table.insert(st, k) end
table.sort(st)
say("plane states seen: " .. table.concat(st, " "))
local fl = {}
for n, g in pairs(plot.gates) do table.insert(fl, n .. "=" .. #g.planes) end
table.sort(fl)
say("fleets (planes per gate/stand): " .. table.concat(fl, " ") .. "   lowest cruising height " .. tostring(minCruise and math.floor(minCruise)))
local mp = {}
for n, v in pairs(maxPax) do table.insert(mp, n .. "=" .. v) end
table.sort(mp)
say("most passengers on board a parked plane, per gate: " .. table.concat(mp, " "))
local sum = 0
for _, v in ipairs(skyTimes) do sum = sum + v end
say(string.format("%d full trips in the sky, average %.0f s in the air", #skyTimes, #skyTimes > 0 and sum / #skyTimes or 0))
say(string.format("passengers: on average %.1f walking around and %.1f waiting at a gate; gates boarding %.0f%% of the time; %d gave up",
	walkSum / T, gateWaitSum / T, 100 * boardSum / (4 * T), gaveUp))
local kinds = {}
for k in pairs(seenKinds) do table.insert(kinds, k) end
say("walker kinds: " .. table.concat(kinds, " ") .. "  guest-in-room samples: " .. guestRooms .. "  max people: " .. maxPeople)
say("served " .. plot.served .. "  reviews " .. #plot.reviews .. "  income/s " .. tostring(plot.incomeRate) .. "  cash " .. cashOf(p1).Value)

-- a player uses the hotel elevator: step on the CALL pad on floor 3, then click the "R" button in the car
do
	local L = plot.lifts.H
	local pad, btn
	for _, p in ipairs(plot.Items:GetDescendants()) do
		if p.Name == "CallPad" and math.abs((plot.cf:inverse() * p.CFrame.p).Y - 25.1) < 0.5 and math.abs((plot.cf:inverse() * p.CFrame.p).X - 256) < 1 then pad = p end
		if p.Name == "Button" and p.Parent == L.cab and p:FindFirstChild("Text") and p.Text.Label.Text == "R" then btn = p end
	end
	local torso = p1.Character.Torso
	pad.Touched:fire(torso)
	for _ = 1, 40 do MOCK.run(0.5) if L.state == "open" and L.idx == 3 then break end end
	local okCall = L.idx == 3 and L.state == "open"
	btn.ClickDetector.MouseClick:fire(p1)
	for _ = 1, 80 do MOCK.run(0.5) if L.state == "open" and L.idx == 7 then break end end
	say("player elevator test: called to floor 3 = " .. tostring(okCall) .. ", rode to roof = " .. tostring(L.idx == 7) ..
		", car floor height " .. string.format("%.1f", (plot.cf:inverse() * L.parts[1].part.CFrame.p).Y) .. ", door open " .. string.format("%.1f", L.doors[7].t))
end

-- a south (rotated) plot too
local p2 = MOCK.addPlayer("tester2", 222)
MOCK.run(1)
MOCK.makeCharacter(p2)
MOCK.run(1)
A.claim(G.plots[8], p2)
local n2 = buyAll(G.plots[8], p2)
say("plot 8 bought " .. n2)
MOCK.run(60)

-- save, leave, come back, claim again: everything rebuilds
A.save(p1)
MOCK.run(1)
MOCK.services.Players.PlayerRemoving:fire(p1)
p1.Parent = nil
MOCK.run(2)
local p1b = MOCK.addPlayer("tester", 111)
MOCK.run(3)
MOCK.makeCharacter(p1b)
A.claim(G.plots[4], p1b)
MOCK.run(5)
local n3 = 0
for _ in pairs(G.plots[4].bought) do n3 = n3 + 1 end
say("after rejoin, plot 4 rebuilt " .. n3 .. " items")
MOCK.run(30)

say("parts in world: " .. #MOCK.allParts)
say("errors: " .. #MOCK.errors)
for i = 1, math.min(15, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 600)) end
_G.TEST_OUT = table.concat(out, "\n")
_G.TEST_PRINTED = printed
