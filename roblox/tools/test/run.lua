-- Runs AirportServer in the mock: claim airports, buy everything, simulate play, save + reload.
-- Globals from the runner: SIM_SECONDS (setup.lua has already started the server)
local MOCK = MOCK
local D = _G.AirportDebug
local G, A, CATALOG = D.G, D.A, D.CATALOG
local out = {}
local function say(s) table.insert(out, s) end
say("catalog items: " .. #CATALOG)
-- the enlarged ground must stay on the ground
for i, pl in ipairs(G.plots) do
	local pm = workspace.AirportMap.Plots:FindFirstChild("Plot" .. i)
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
-- Paradise Island bookkeeping (a player stands in the theme park: rides only run when someone is near)
local RES = D.RESORT
local fan = MOCK.addPlayer("parkfan", 909)
MOCK.run(1)
MOCK.makeCharacter(fan)
fan.Character.Torso.CFrame = RES.entrance
local tripStart, trips, resortStates, resortVisits, maxStands = {}, {}, {}, 0, 0
local minSep, minSepWhat, closeCalls, rideMoved = 1e9, "", 0, {}
local slotLate, slotN = 0, 0
local rideRoots, rideStart = {}, {}
local coaster = RES and RES.RIDES[1]
local coasterMaxV, coasterUpsideDown, coasterLaps, lastCoasterS = 0, false, 0, 0
local parkVisitorsMax, parkProgress, parkStuck = 0, {}, {}
if RES and RES.root then
	for _, p in ipairs(RES.root:GetDescendants()) do
		if p.Name == "Root" and p:IsA("BasePart") then table.insert(rideRoots, p) rideStart[p] = p.CFrame.p end
	end
end
say("Paradise Island built: " .. tostring(RES and RES.ready) .. ", rides: " .. (RES and #RES.RIDES or 0) .. ", moving ride parts: " .. #rideRoots)
if RES then
	local names = {}
	for _, r in ipairs(RES.RIDES) do table.insert(names, r.name) end
	say("rides: " .. table.concat(names, ", "))
	if coaster then say(string.format("coaster track: %d studs, lift top at %d", coaster.T.L, coaster.liftEnd)) end
	local per = {}
	for _, m in ipairs(RES.root:GetChildren()) do
		local n = 0
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then n = n + 1 end end
		table.insert(per, m.Name .. "=" .. n)
	end
	local park = RES.root:FindFirstChild("Paradise Park")
	if park then
		for _, m in ipairs(park:GetChildren()) do
			local n = 0
			for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then n = n + 1 end end
			if n > 150 then table.insert(per, "  " .. m.Name .. "=" .. n) end
		end
	end
	say("island parts: " .. table.concat(per, " "))
end
for s = 1, T do
	MOCK.run(1, 0.05)
	if RES and RES.ready then
		local all = {}
		for _, pl in ipairs(G.plots) do for _, gp in pairs(pl.gatePlanes) do if gp.model.Parent then table.insert(all, gp) end end end
		local used = 0
		for _, st in ipairs(RES.stands) do if st.occ and st.occ.model.Parent and st.occ.stand == st then used = used + 1 end end
		maxStands = math.max(maxStands, used)
		for i, a in ipairs(all) do
			resortStates[a.state] = (resortStates[a.state] or 0) + 1
			local last = tripStart[a] and tripStart[a].state
			if a.state ~= last then
				if a.state == "departing" then tripStart[a] = { state = a.state, t = s }
				else
					if a.state == "arriving" and tripStart[a] and tripStart[a].t then table.insert(trips, s - tripStart[a].t) end
					if a.state == "resortParked" then resortVisits = resortVisits + 1 end
					tripStart[a] = { state = a.state, t = tripStart[a] and tripStart[a].t }
					if a.state == "arriving" then tripStart[a].t = nil end
				end
			end
			if a.state == "resortLanding" and last ~= "resortLanding" and a.slot then
				slotN = slotN + 1
				slotLate = math.max(slotLate, math.abs(tick() - a.slot))
			end
			for j = i + 1, #all do
				local b = all[j]
				if a.state:sub(1, 6) == "resort" and b.state:sub(1, 6) == "resort" and not (a.state == "resortParked" and b.state == "resortParked") then
					local d = (a.root.CFrame.p - b.root.CFrame.p).magnitude
					if d < 40 then
						closeCalls = closeCalls + 1
						if DEBUG_CLOSE and d < 32 then
							local function info(x)
								local q = x.root.CFrame.p
								return string.format("%s#%d.%d at (%.0f,%.0f,%.0f) t=%.1f/%.1f cleared=%s waitingFor=%s stand=%s", x.state, x.n, x.k, q.X, q.Y, q.Z,
									x.lastT or -1, x.path and x.path.total or -1, tostring(x.cleared), tostring(x.waitingFor and (x.waitingFor.n .. "." .. x.waitingFor.k)), tostring(x.stand and x.stand.x))
							end
							say(string.format("CLOSE %.0f s=%d: %s | %s", d, s, info(a), info(b)))
						end
					end
					if d < minSep then minSep, minSepWhat = d, a.state .. "/" .. b.state .. string.format(" at (%.0f, %.0f, %.0f)", a.root.CFrame.p.X, a.root.CFrame.p.Y, a.root.CFrame.p.Z) end
				end
			end
			local p = a.root.CFrame.p
			if p.X ~= p.X or p.Y ~= p.Y then table.insert(MOCK.errors, "plane at NaN in state " .. a.state) end
		end
		if coaster then
			coasterMaxV = math.max(coasterMaxV, coaster.v)
			for _, car in ipairs(coaster.cars) do if car.CFrame.upVector.Y < -0.5 then coasterUpsideDown = true end end
			if coaster.s < lastCoasterS - 100 then coasterLaps = coasterLaps + 1 end
			lastCoasterS = coaster.s
		end
		parkVisitorsMax = math.max(parkVisitorsMax, RES.PARK.visitors)
		for _, p in ipairs(rideRoots) do
			local a, b = p.CFrame, rideStart[p]
			if (a.p - b).magnitude > 1 or math.abs(a.upVector.Y - 1) > 0.01 or math.abs(a.lookVector.Z + 1) > 0.01 then rideMoved[p] = true end
		end
		for _, w in ipairs(G.walkers) do
			if w.plot == RES.PARK then
				local pr = parkProgress[w]
				if not pr or pr.i ~= w.i then parkProgress[w] = { i = w.i, t = s }
				elseif s - pr.t > 150 then parkStuck[w] = "visitor stuck at route point " .. w.i .. "/" .. #w.route .. " " .. tostring(w.pos) end
			end
		end
	end
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
	-- the player steps into the car; while it moves they get carried (BodyVelocity), and it's removed after
	torso.CFrame = CFrame.new(L.plot.cf * Vector3.new(L.x, L.y + 3, L.z))
	btn.ClickDetector.MouseClick:fire(p1)
	local carried = false
	for _ = 1, 160 do
		MOCK.run(0.25)
		local bv = torso:FindFirstChild("ElevatorRide")
		if bv then
			carried = true
			torso.CFrame = CFrame.new(L.plot.cf * Vector3.new(L.x, L.y + 3, L.z))   -- (no physics in the mock: ride along by hand)
		end
		if L.state == "open" and L.idx == 7 then break end
	end
	say("player carried by the moving elevator: " .. tostring(carried) .. ", BodyVelocity removed on arrival: " .. tostring(torso:FindFirstChild("ElevatorRide") == nil))
	say("player elevator test: called to floor 3 = " .. tostring(okCall) .. ", rode to roof = " .. tostring(L.idx == 7) ..
		", car floor height " .. string.format("%.1f", (plot.cf:inverse() * L.parts[1].part.CFrame.p).Y) .. ", door open " .. string.format("%.1f", L.doors[7].t))
end

-- Paradise Island report
if RES then
	local moved, nan, still = 0, 0, {}
	for _, p in ipairs(rideRoots) do
		local q = p.CFrame.p
		if q.X ~= q.X or q.Y ~= q.Y or q.Z ~= q.Z then nan = nan + 1 end
		if rideMoved[p] then moved = moved + 1
		elseif p.Parent then table.insert(still, p.Parent.Name) end
	end
	say(string.format("ride parts that moved: %d / %d (NaN: %d)  not moved: %s", moved, #rideRoots, nan, table.concat(still, ", ")))
	for _, r in ipairs(RES.RIDES) do if r.failed then say("  RIDE FAILED: " .. r.name) end end
	say(string.format("coaster: %d laps, top speed %.0f studs/s, upside down in the loop: %s", coasterLaps, coasterMaxV, tostring(coasterUpsideDown)))
	local rs = {}
	for k, v in pairs(resortStates) do table.insert(rs, k .. "=" .. v) end
	table.sort(rs)
	say("plane-seconds per state (all airports): " .. table.concat(rs, " "))
	local tsum = 0
	for _, v in ipairs(trips) do tsum = tsum + v end
	say(string.format("Paradise: %d landings there, %d full round trips (average %.0f s from take-off to landing back home), most stands in use %d / %d",
		resortVisits, #trips, #trips > 0 and tsum / #trips or 0, maxStands, #RES.stands))
	local forced = 0
	for gp in pairs(tripStart) do if gp.ignoreUntil then forced = forced + 1 end end
	say("planes that ever had to push past a plane after waiting 25 s: " .. forced)
	say(string.format("landings that started at their booked slot: %d, worst miss %.1f s", slotN, slotLate))
	say(string.format("closest two planes at Paradise: %.0f studs (%s); plane-seconds closer than 40 studs: %d", minSep, minSepWhat, closeCalls))
	local ps = {}
	for w, why in pairs(parkStuck) do if w.model.Parent then table.insert(ps, why) end end
	say("park visitors: most at once " .. parkVisitorsMax .. ", now " .. RES.PARK.visitors .. ", stuck " .. #ps)
	for i = 1, math.min(5, #ps) do say("  " .. ps[i]) end
	-- a player asks to go to the park
	local torso = p1.Character.Torso
	G.remote.OnServerEvent:fire(p1, "resort")
	MOCK.run(1)
	say(string.format("player sent to the park: at (%.0f, %.0f, %.0f)", torso.CFrame.p.X, torso.CFrame.p.Y, torso.CFrame.p.Z))
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
