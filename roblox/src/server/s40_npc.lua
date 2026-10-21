-- ==== s40_npc.lua
------------------------------------------------------------------ walking people
-- route = list of { p = feet position (world), wait = seconds, act = function(walker) }
function NPC.walk(plot, model, root, route, speed, onDone)
	local w = { plot = plot, model = model, root = root, route = route, i = 1, pos = route[1].p, wt = 0,
		speed = speed or CONST.walkSpeed, onDone = onDone, dir = Vector3.new(0, 0, -1), face = Vector3.new(0, 0, -1),
		limbs = M.limbs(root), ph = math.random() * 6 }
	table.insert(G.walkers, w)
	return w
end

function NPC.step(dt)
	local now = tick()
	for i = #G.walkers, 1, -1 do
		local w = G.walkers[i]
		local done = false
		if not w.model.Parent then
			done = true
		elseif w.wt > 0 then
			w.wt = w.wt - dt
		else
			local target = w.route[w.i]
			if not target then
				done = true
			else
				local d = target.p - w.pos
				local dist = d.magnitude
				local step = w.speed * dt
				if dist <= step then
					w.pos = target.p
					if dist > 0.05 then w.dir = d.unit end
					w.wt = target.wait or 0
					w.i = w.i + 1
					if target.act then
						local ok, err = pcall(target.act, w)
						if not ok then print("Airport: walker action failed: " .. tostring(err)) end
					end
				else
					w.dir = d.unit
					w.pos = w.pos + w.dir * step
				end
			end
		end
		if done then
			table.remove(G.walkers, i)
			if w.onDone then pcall(w.onDone, w) end
			pcall(function() w.model:Destroy() end)
		elseif w.model.Parent then
			-- face the way they walk (riding an elevator straight up/down keeps the old direction)
			local flat = Vector3.new(w.dir.x, 0, w.dir.z)
			local walking = w.wt <= 0 and flat.magnitude > 0.3
			if flat.magnitude > 0.3 then w.face = flat.unit end
			local bob = walking and math.abs(math.sin(now * 8 + w.ph)) * 0.15 or 0
			local p = w.pos + Vector3.new(0, 3 + bob, 0)
			w.root.CFrame = CFrame.new(p, p + w.face)
			-- swing arms and legs like a Roblox character (10 times a second is plenty, and it all replicates)
			if walking then
				if now >= (w.nextPose or 0) then
					w.nextPose = now + 0.1
					M.pose(w.limbs, math.sin(now * 8 + w.ph) * 0.7)
					w.posed = true
				end
			elseif w.posed then
				M.pose(w.limbs, 0)
				w.posed = false
			end
		end
	end
end

------------------------------------------------------------------ reviews
local NAMES = { "Sarah", "Tom", "Aisha", "Leo", "Mia", "Carlos", "Yuki", "Noah", "Emma", "Omar", "Lily", "Jack", "Priya",
	"Lucas", "Zoe", "Ivan", "Chloe", "Mateo", "Ava", "Ben", "Grace", "Sam", "Nina", "Kai" }
local GOOD = {
	checkin = { "Check-in was super quick!", "The check-in staff were so nice.", "Checked in in no time!" },
	security = { "Security was smooth and friendly.", "Fastest security line ever!", "I felt really safe here." },
	food = { "The food court was amazing!", "Best sushi I've had at an airport!", "Loved the burgers and ice cream." },
	shopping = { "Great shops, I bought so much!", "Duty free had everything!", "Awesome souvenirs!" },
	comfort = { "So comfy, I loved the lounges.", "The spa was so relaxing.", "Beautiful terminal, so many seats!" },
	clean = { "Spotless airport!", "Everything was so clean.", "The restrooms were sparkling!" },
	gates = { "My flight left right on time!", "Boarding was super easy.", "Smooth takeoff, great airport!" } }
local BAD = {
	checkin = { "The check-in line took forever.", "Not enough check-in desks!", "Waited ages to drop my bag." },
	security = { "Security was a nightmare.", "Only one security lane?!", "The security line was huge." },
	food = { "I was starving, no good food.", "Where is the food court?", "Nothing to eat here..." },
	shopping = { "Nothing to buy here...", "No shops at all!", "I wanted souvenirs but there were none." },
	comfort = { "Nowhere nice to sit!", "So boring, nothing to do.", "My feet hurt, no seats anywhere." },
	clean = { "It was so dirty...", "The bins were overflowing!", "Hire some janitors please!" },
	gates = { "My flight was delayed!", "The gate was so far and crowded.", "Where are the planes?!" } }
-- a random category among the strongest (best) and among the weakest (worst)
local function bestWorst(cats)
	local hi, lo = -1, 2
	for _, k in ipairs(CATS) do hi = math.max(hi, cats[k]) lo = math.min(lo, cats[k]) end
	local tops, bots = {}, {}
	for _, k in ipairs(CATS) do
		if cats[k] >= hi - 0.1 then table.insert(tops, k) end
		if cats[k] <= lo + 0.1 then table.insert(bots, k) end
	end
	return U.pick(tops), U.pick(bots)
end

function NPC.review(plot, flew)
	local stars, cats = A.stars(plot)
	local s = stars + (math.random() - 0.5) * 1.5 - (flew and 0 or 0.8)
	s = U.clamp(math.floor(s + 0.5), 1, 5)
	local best, worst = bestWorst(cats)
	local good, bad = U.pick(GOOD[best]), U.pick(BAD[worst])
	local text
	if s >= 4 then text = good
	elseif s <= 2 then text = bad
	else text = good .. " But " .. bad:sub(1, 1):lower() .. bad:sub(2) end
	if not flew then text = "There were no flights! " .. text end
	local r = { name = U.pick(NAMES), stars = s, text = text }
	table.insert(plot.reviews, r)
	while #plot.reviews > 40 do table.remove(plot.reviews, 1) end
	plot.served = plot.served + 1
	if plot.owner then pcall(function() G.remote:FireClient(plot.owner, "review", r) end) end
end

------------------------------------------------------------------ passengers
local F = 1
function NPC.passenger(plot)
	local inv = plot.cf:inverse()
	local function W(x, y, z) return plot.cf * Vector3.new(x, y, z) end
	local function loc(v) return inv * v end
	local route = {}
	local cur
	local function go(v, wait, act) table.insert(route, { p = v, wait = wait, act = act }) cur = loc(v) end
	local aisle = (math.random() < 0.5 and -12 or 12) + math.random(-2, 2)
	-- walk along the central aisle, then across to the target (keeps people out of the rooms)
	local function moveTo(v, wait, act)
		local l = loc(v)
		if cur and cur.z > 58 and math.abs(l.z - cur.z) > 6 then
			go(W(aisle, l.y, cur.z))
			go(W(aisle, l.y, l.z))
		end
		go(v, wait, act)
	end
	-- the terminal elevators: walk to the one on this side of the aisle, ride, step back out to the aisle
	local liftX = aisle < 0 and -30 or 30
	local function rideTo(y)
		if math.abs(cur.z - LIFT_Z) > 1 then
			go(W(aisle, cur.y, cur.z))
			go(W(aisle, cur.y, LIFT_Z))
		end
		go(W(liftX, cur.y, LIFT_Z), 0.5)
		go(W(liftX, y, LIFT_Z), 0.3)
		go(W(aisle, y, LIFT_Z))
	end
	local function pay(s) return function(w) if (s.spend or 0) > 0 then A.pay(plot, s.spend, w.model) end end end
	local function visitFloor(list, n)
		local picked = {}
		for _ = 1, n do
			local s = U.pick(list)
			if not picked[s] then
				picked[s] = true
				moveTo(s.p, s.wait or 3, pay(s))
			end
		end
	end
	local pts = plot.pts
	local look = M.passengerLook()
	-- where they come from
	local start = W(math.random(-40, 40), 0.5, 50)
	if pts.arrive and #pts.arrive > 0 and math.random() < 0.7 then start = U.pick(pts.arrive).p end
	go(start)
	-- walk outside the terminal to the sidewalk first (straight lines from the car park cut through the walls)
	if cur.z > 54 or cur.z < 40 then go(W(cur.x, 0.5, 51)) end
	go(W(math.random(-6, 6), 0.5, 52))
	go(W(math.random(-4, 4), F, 64))
	local flew = false
	local mult = 1
	-- check-in
	if pts.desk and #pts.desk > 0 then
		local d = U.pick(pts.desk)
		local agents = plot.staff.agent or 0
		local desks = math.max(1, plot.cnt.desk or 1)
		local wait = d.kiosk and 1.5 or (3 / (1 + agents / desks) - 0.1 * (plot.staff.handler or 0))
		moveTo(d.q, math.max(0.8, wait), function(w) A.pay(plot, CONST.checkinFee, w.model) end)
	end
	-- security
	if pts.lane and #pts.lane > 0 then
		local l = U.pick(pts.lane)
		moveTo(l.a)
		local officers = plot.staff.officer or 0
		go(l.b, math.max(0.6, 2.4 - 0.25 * officers))
		go(l.c)
	else
		-- no lanes yet: through the opening in the middle of the security wall
		moveTo(W(aisle, F, 120))
		go(W(0, F, 122)) go(W(0, F, 131)) go(W(aisle, F, 150))
	end
	go(W(aisle, F, 166))
	-- food, shops, seats
	if pts.stall and #pts.stall > 0 and math.random() < 0.6 then
		local s = U.pick(pts.stall)
		moveTo(s.p, 3, function(w) A.pay(plot, s.spend * (1 + 0.1 * (plot.staff.chef or 0)), w.model) end)
	end
	if pts.shop and #pts.shop > 0 and math.random() < 0.5 then
		local s = U.pick(pts.shop)
		moveTo(s.p, 3, function(w) A.pay(plot, s.spend * (1 + 0.1 * (plot.staff.clerk or 0)), w.model) end)
	end
	if pts.seat and #pts.seat > 0 and math.random() < 0.35 then
		moveTo(U.pick(pts.seat).p, 4)
	end
	-- up the elevators to the sky mall (2nd floor) and the sky deck (3rd floor)
	if pts.up2 and #pts.up2 > 0 and math.random() < 0.75 then
		rideTo(LV[2])
		visitFloor(pts.up2, math.random(1, 3))
		if pts.up3 and #pts.up3 > 0 and math.random() < 0.65 then
			rideTo(LV[3])
			visitFloor(pts.up3, math.random(1, 3))
		end
		rideTo(LV[1])
	end
	-- board a flight
	if pts.gate and #pts.gate > 0 then
		local g = U.pick(pts.gate)
		moveTo(g.p, 2)
		go(g.door)
		local bridge
		for _, br in ipairs(pts.bridge or {}) do if br.n == g.n then bridge = br end end
		local function board(w) flew = true A.pay(plot, A.ticket(plot), w.model) end
		if bridge then go(bridge.e, 0.2, board) else route[#route].act = board end
	else
		moveTo(W(aisle, F, 250), 2)
		moveTo(W(aisle, F, 134))
		go(W(0, F, 131)) go(W(0, F, 122)) go(W(aisle, F, 116))
		moveTo(W(0, F, 64))
		go(W(0, 0.5, 50))
	end
	local feet = route[1].p
	local model, root = M.person(plot.People, CFrame.new(feet), look, "Passenger")
	U.rig(model, root, false)
	local w = NPC.walk(plot, model, root, route, CONST.walkSpeed + math.random() * 2, function() NPC.review(plot, flew) end)
	w.kind = "passenger"
end

------------------------------------------------------------------ the airport inspector: walks everything, gives an official rating and a bonus
function NPC.inspector(plot)
	local route = {}
	local function W(x, y, z) return plot.cf * Vector3.new(x, y, z) end
	local function go(v, wait) table.insert(route, { p = v, wait = wait }) end
	go(W(0, 0.5, 46))
	go(W(0, F, 64), 1)
	local pts = plot.pts
	for _, kind in ipairs({ "desk", "lane", "stall", "shop", "gate" }) do
		local p = pts[kind] and pts[kind][1]
		if p then
			local v = p.q or p.a or p.p
			local l = plot.cf:inverse() * v
			go(W(0, F, l.z))
			go(v, 2.5)
			go(W(0, F, l.z))
		end
	end
	go(W(0, F, 64))
	go(W(0, 0.5, 46))
	local model, root = M.person(plot.People, CFrame.new(route[1].p), { shirt = "Really black", pants = "Really black", skin = "Nougat",
		tie = "Gold", clipboard = true, hat = "cap", hatColor = "Gold" }, "Inspector")
	local head = model:FindFirstChild("Head")
	if head then U.bill(head, "AIRPORT INSPECTOR", 7, 1.4, 2.5, Color3.new(1, 0.85, 0.2)) end
	U.rig(model, root, false)
	local iw = NPC.walk(plot, model, root, route, 7, function()
		if not plot.owner then return end
		local stars, cats = A.stars(plot)
		local best, worst = bestWorst(cats)
		local bonus = math.floor(150 * stars ^ 3 + 10 * (plot.incomeRate or 0) * stars)
		local cash = A.cash(plot.owner)
		if cash then cash.Value = cash.Value + bonus end
		plot.lastReport = { stars = math.floor(stars * 10 + 0.5) / 10, best = CATNAME[best], worst = CATNAME[worst], bonus = bonus }
		pcall(function() G.remote:FireClient(plot.owner, "inspector", plot.lastReport) end)
	end)
	iw.kind = "inspector"
	if plot.owner then A.toast(plot.owner, "The Airport Inspector has arrived! Make your airport shine!", "gold") end
end

------------------------------------------------------------------ staff (they stand at their station)
local LOOKS = {
	agent = { shirt = "Bright blue", pants = "Navy blue", tie = "Bright red" },
	officer = { shirt = "Really black", pants = "Navy blue", hat = "cap", hatColor = "Really black" },
	chef = { shirt = "Institutional white", pants = "Really black", hat = "chef" },
	clerk = { shirt = "Bright green", pants = "Really black" },
	janitor = { shirt = "Bright orange", pants = "Navy blue", hat = "cap", hatColor = "Bright orange", mop = true },
	gateagent = { shirt = "Navy blue", pants = "Navy blue", tie = "Gold" },
	pilot = { shirt = "Institutional white", pants = "Really black", hat = "cap", hatColor = "Navy blue", tie = "Really black" },
	handler = { shirt = "Bright yellow", pants = "Navy blue", hat = "helmet", hatColor = "Bright orange" },
	atc = { shirt = "Sand blue", pants = "Really black", hat = "cap", hatColor = "Sand blue" },
	mechanic = { shirt = "Dark stone grey", pants = "Dark stone grey", hat = "helmet", hatColor = "Bright yellow" },
	firefighter = { shirt = "Bright red", pants = "Really black", hat = "helmet", hatColor = "Bright yellow" },
	receptionist = { shirt = "Navy blue", pants = "Really black", tie = "Gold", hat = "bun", hatColor = "Brown" },
	housekeeper = { shirt = "Institutional white", pants = "Navy blue", hat = "cap", hatColor = "Institutional white", mop = true },
	bellhop = { shirt = "Bright red", pants = "Really black", hat = "cap", hatColor = "Bright red", tie = "Gold", bag = "Brown" },
}
function NPC.spawnStaff(plot, role, index)
	local spots = plot.spots[role] or {}
	local cf = spots[index] or (plot.cf * U.L(-30 + index * 3, F, 70, 0))
	local look = {}
	for k, v in pairs(LOOKS[role] or {}) do look[k] = v end
	local st = ROLE[role]
	local m = M.person(plot.Staff, cf, look, st and st.name or role)
	local head = m:FindFirstChild("Head")
	if head and st then U.bill(head, st.name, 6, 1.1, 2.2, Color3.new(0.8, 0.9, 1)) end
end
