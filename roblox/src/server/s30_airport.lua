-- ==== s30_airport.lua
------------------------------------------------------------------ airports (plots)
local PLOT_COLORS = { "Bright red", "Bright blue", "Bright green", "Bright orange", "Royal purple",
	"Cyan", "Hot pink", "Teal", "Bright yellow", "Navy blue" }
local remote = RS:FindFirstChild("AirportEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AirportEvent"
	remote.Parent = RS
end
G.remote = remote

function A.toast(player, text, color)
	if player then pcall(function() remote:FireClient(player, "toast", text, color or "white") end) end
end
function A.cash(player)
	local ls = player and player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Cash")
end

local function folder(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function A.init()
	local plots = MAP:WaitForChild("Plots")
	for i = 1, 10 do
		local pm = plots:WaitForChild("Plot" .. i)
		local plot = { i = i, cf = pm:WaitForChild("Origin").CFrame, color = PLOT_COLORS[i] }
		plot.root = folder(workspace, "Airport" .. i)
		for _, n in ipairs({ "Items", "Pads", "Staff", "People", "Guests", "Crowd", "Planes" }) do plot[n] = folder(plot.root, n) end
		A.enlarge(plot, pm)
		-- the pylon at the front-left corner shows who owns it
		local b = { model = plot.root, cf = plot.cf, plot = plot }
		U.blk(b, "Pylon", 3, 22, 3, -294, 0, 4, "Dark stone grey", "Metal")
		local s = U.blk(b, "PylonSign", 16, 8, 1, -294, 22, 4, "Really black", "SmoothPlastic")
		plot.header = U.text(s, "AIRPORT " .. i, Color3.new(1, 1, 1), BrickColor.new(plot.color).Color, "Front")
		U.text(s, "AIRPORT " .. i, Color3.new(1, 1, 1), BrickColor.new(plot.color).Color, "Back")
		G.plots[i] = plot
		A.reset(plot)
	end
end

-- every airport gets more land: the base and curbs grow to PLOT_W x PLOT_D and trees on it are cleared
function A.enlarge(plot, pm)
	-- Never resize a part that is already in the world: old Roblox shoves it upwards out of whatever it overlaps
	-- (that is what lifted the ground over the runway). Instead each part is cloned, sized and placed while it is
	-- outside the world, then swapped in for the original.
	local trees = MAP:FindFirstChild("Trees")
	if trees then
		local inv = plot.cf:inverse()
		for _, t in ipairs(trees:GetChildren()) do
			if t:IsA("BasePart") then
				local l = inv * t.Position
				if math.abs(l.x) < PLOT_W / 2 + 10 and l.z > -6 and l.z < PLOT_D + 10 then t:Destroy() end
			end
		end
	end
	local function swap(old, size, x, z)
		local y = old.CFrame.p.Y - plot.cf.p.Y
		local new = old:Clone()
		new.Size = size
		new.CFrame = plot.cf * CFrame.new(x, y, z)
		new.Anchored = true
		old:Destroy()
		new.Parent = pm
	end
	local base = pm:FindFirstChild("Base")
	if base then swap(base, Vector3.new(PLOT_W, base.Size.Y, PLOT_D), 0, PLOT_D / 2) end
	local curbs = {}
	for _, c in ipairs(pm:GetChildren()) do if c.Name == "Curb" then table.insert(curbs, c) end end
	local spec = { { -PLOT_W / 2, PLOT_D / 2, 2, PLOT_D }, { PLOT_W / 2, PLOT_D / 2, 2, PLOT_D }, { 0, 0.5, PLOT_W + 2, 1 }, { 0, PLOT_D - 0.5, PLOT_W + 2, 1 } }
	for k, c in ipairs(curbs) do
		local sp = spec[k]
		if sp then swap(c, Vector3.new(sp[3], c.Size.Y, sp[4]), sp[1], sp[2]) end
	end
end

function A.reset(plot)
	for _, n in ipairs({ "Items", "Pads", "Staff", "People", "Guests", "Crowd", "Planes" }) do plot[n]:ClearAllChildren() end
	for _, f in pairs(G.flyers) do if f.plot == plot then pcall(function() f.model:Destroy() end) end end
	plot.owner = nil
	plot.bought, plot.staff, plot.spots, plot.pts, plot.cnt, plot.items, plot.pads = {}, {}, {}, {}, {}, {}, {}
	plot.reviews, plot.served, plot.earnLog, plot.incomeRate = {}, 0, {}, 0
	plot.gatePlanes, plot.flyPads, plot.gates, plot.loops = {}, {}, {}, {}
	plot.hasRunway, plot.intl, plot.fireworks = false, false, false
	plot.hasRunway2, plot.hasHotel, plot.guestT = false, false, 5
	plot.lifts, plot.movers, plot.fids = {}, {}, {}
	plot.signLabel, plot.screenLabel, plot.lastReport = nil, nil, nil
	plot.spawnT, plot.nextInspect = 3, tick() + 150
	plot.header.Text = "AIRPORT " .. plot.i .. "\nFREE"
	-- claim pad
	local pad = U.blk({ model = plot.Pads, cf = plot.cf }, "Claim", 10, 0.4, 10, 0, 0, 9, "Lime green", "Neon")
	U.bill(pad, "CLAIM AIRPORT " .. plot.i .. "\n(step here, it's free)", 14, 3.5, 5, Color3.new(0.6, 1, 0.6))
	U.light(pad, Color3.new(0.4, 1, 0.4), 14)
	local busy = false
	pad.Touched:connect(function(hit)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if not player or busy then return end
		busy = true
		A.claim(plot, player)
		wait(1)
		busy = false
	end)
end

function A.claim(plot, player)
	if plot.owner then
		if plot.owner ~= player then A.toast(player, "Airport " .. plot.i .. " belongs to " .. plot.owner.Name, "red") end
		return
	end
	local mine = G.byPlayer[player]
	if mine then A.toast(player, "You already own Airport " .. mine.i, "red") return end
	plot.owner = player
	G.byPlayer[player] = plot
	plot.Pads:ClearAllChildren()
	plot.header.Text = player.Name .. "'s\nAIRPORT " .. plot.i
	plot.nextInspect = tick() + 150
	-- rebuild what this player had saved
	local saved = G.saved[player]
	if saved and saved.items then
		local have = {}
		for _, k in ipairs(saved.items) do have[k] = true end
		for _, it in ipairs(CATALOG) do
			if have[it.key] and ITEM[it.key] then A.build(plot, it, true) end
		end
		if saved.staff then
			for _, st in ipairs(STAFF) do
				local n = tonumber(saved.staff[st.key]) or 0
				for _ = 1, math.min(n, A.staffCap(plot, st)) do
					plot.staff[st.key] = (plot.staff[st.key] or 0) + 1
					NPC.spawnStaff(plot, st.key, plot.staff[st.key])
				end
			end
		end
		plot.served = tonumber(saved.served) or 0
	end
	A.refreshPads(plot)
	A.updateSigns(plot)
	A.toast(player, "Welcome to your airport! Step on the gold pads to build it.", "green")
end

------------------------------------------------------------------ buy pads
function A.available(plot, it)
	if plot.bought[it.key] then return false end
	for _, d in ipairs(it.deps) do if not plot.bought[d] then return false end end
	return true
end

function A.refreshPads(plot)
	for _, it in ipairs(CATALOG) do
		local pad = plot.pads[it.key]
		local show = plot.owner ~= nil and A.available(plot, it)
		if show and not pad then
			plot.pads[it.key] = A.makePad(plot, it)
		elseif not show and pad then
			pad:Destroy()
			plot.pads[it.key] = nil
		end
	end
end

function A.makePad(plot, it)
	local y = it.pad[3] or LV[it.floor] or 0
	local pad = U.newPart()
	pad.Name = "Buy " .. it.name
	pad.Anchored = true
	pad.Size = Vector3.new(6, 0.4, 6)
	pad.BrickColor = BrickColor.new(it.price == 0 and "Lime green" or "Bright yellow")
	pcall(function() pad.Material = Enum.Material.Neon end)
	pad.CFrame = plot.cf * CFrame.new(it.pad[1], y + 0.25, it.pad[2])
	U.bill(pad, it.name .. "\n" .. (it.price == 0 and "FREE" or U.money(it.price)), 11, 3, 9, Color3.new(1, 1, 1))
	local beam = U.newPart()
	beam.Name = "Beam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.Size = Vector3.new(0.5, 7, 0.5)
	beam.BrickColor = pad.BrickColor
	pcall(function() beam.Material = Enum.Material.Neon end)
	beam.Transparency = 0.5
	beam.CFrame = pad.CFrame * CFrame.new(0, 3.7, 0)
	beam.Parent = pad
	local busy = false
	pad.Touched:connect(function(hit)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if busy or not player then return end
		busy = true
		A.buy(plot, it, player)
		wait(0.6)
		busy = false
	end)
	pad.Parent = plot.Pads
	return pad
end

function A.buy(plot, it, player)
	if plot.owner ~= player then
		A.toast(player, "This is " .. (plot.owner and plot.owner.Name or "nobody") .. "'s airport", "red")
		return
	end
	if not A.available(plot, it) then return end
	local cash = A.cash(player)
	if not cash then return end
	if cash.Value < it.price then
		A.toast(player, "You need " .. U.money(it.price - cash.Value) .. " more for " .. it.name, "red")
		return
	end
	cash.Value = cash.Value - it.price
	A.build(plot, it, false)
	A.refreshPads(plot)
	A.toast(player, "Built: " .. it.name .. "!", "green")
	local n = 0
	for _ in pairs(plot.bought) do n = n + 1 end
	if n == #CATALOG then
		-- the whole airport is done: fireworks and a shout-out to everyone
		plot.fireworks = true
		for _, p in ipairs(Players:GetPlayers()) do
			A.toast(p, player.Name .. " finished the ULTIMATE INTERNATIONAL AIRPORT!", "gold")
		end
	end
end

function A.build(plot, it, quiet)
	if plot.bought[it.key] then return end
	plot.bought[it.key] = true
	if plot.pads[it.key] then plot.pads[it.key]:Destroy() plot.pads[it.key] = nil end
	local cnt = it.eff.cnt
	if cnt then for k, v in pairs(cnt) do plot.cnt[k] = (plot.cnt[k] or 0) + v end end
	local m = Instance.new("Model")
	m.Name = it.name
	local b = { model = m, cf = plot.cf, plot = plot }
	local ok, err = pcall(function() K[it.kind](b, it.at) end)
	if not ok then print("Airport: building " .. it.name .. " failed: " .. tostring(err)) end
	m.Parent = plot.Items
	plot.items[it.key] = m
	if not quiet then A.updateSigns(plot) end
end

function A.updateSigns(plot)
	local name = plot.owner and plot.owner.Name or "?"
	if plot.signLabel then plot.signLabel.Text = string.upper(name) .. "'S AIRPORT" end
end

------------------------------------------------------------------ ratings
function A.cats(plot)
	local c = {}
	for _, k in ipairs(CATS) do c[k] = 0 end
	c.clean = CONST.clean_base
	for key in pairs(plot.bought) do
		local e = ITEM[key] and ITEM[key].eff.cat
		if e then for k, v in pairs(e) do c[k] = c[k] + v end end
	end
	for role, n in pairs(plot.staff) do
		local st = ROLE[role]
		if st then for k, v in pairs(st.cat) do c[k] = c[k] + v * n end end
	end
	for k, v in pairs(c) do c[k] = math.min(1, v) end
	return c
end
function A.stars(plot)
	local c = A.cats(plot)
	local s = 0
	for _, k in ipairs(CATS) do s = s + c[k] end
	return 1 + 4 * s / #CATS, c
end
function A.rating(plot)
	local n = #plot.reviews
	if n == 0 then return (A.stars(plot)) end
	local s, cnt = 0, 0
	for i = math.max(1, n - 29), n do s = s + plot.reviews[i].stars cnt = cnt + 1 end
	return s / cnt
end
function A.mult(plot) return 0.5 + 0.3 * A.rating(plot) end

function A.pay(plot, amount, who)
	if not plot.owner then return end
	local cash = A.cash(plot.owner)
	if not cash then return end
	amount = math.floor(amount * A.mult(plot) * CONST.paxMult + 0.5)
	if amount <= 0 then return end
	cash.Value = cash.Value + amount
	table.insert(plot.earnLog, { t = tick(), a = amount })
	if who and who.Parent then
		local head = who:FindFirstChild("Head")
		if head then
			local l = U.bill(head, "+" .. U.money(amount), 4, 1.2, 2.5, Color3.new(0.4, 1, 0.4))
			Debris:AddItem(l.Parent, 1.4)
		end
	end
end

function A.ticket(plot)
	local t = CONST.baseTicket
	local tm = 1
	for key in pairs(plot.bought) do
		local e = ITEM[key].eff
		t = t + (e.ticket or 0)
		tm = tm * (e.tmult or 1)
	end
	local pilots = plot.staff.pilot or 0
	return t * tm * (1 + 0.1 * pilots)
end

------------------------------------------------------------------ staff
function A.staffCap(plot, st)
	local cap = st.capbase + (st.need and (plot.cnt[st.need] or 0) * st.capper or 0)
	if st.capextra then cap = cap + (plot.cnt[st.capextra[1]] or 0) * st.capextra[2] end
	return math.floor(cap)
end
function A.staffFee(st, n) return math.floor(st.fee * 1.35 ^ n) end

function A.hire(player, key)
	local plot = G.byPlayer[player]
	local st = ROLE[key]
	if not plot or not st then return end
	local n = plot.staff[key] or 0
	local cap = A.staffCap(plot, st)
	if n >= cap then
		A.toast(player, cap == 0 and ("Build what a " .. st.name .. " needs first") or ("No more room for a " .. st.name), "red")
		return
	end
	local fee = A.staffFee(st, n)
	local cash = A.cash(player)
	if not cash or cash.Value < fee then A.toast(player, "You need " .. U.money(fee - (cash and cash.Value or 0)) .. " more to hire a " .. st.name, "red") return end
	cash.Value = cash.Value - fee
	plot.staff[key] = n + 1
	NPC.spawnStaff(plot, key, n + 1)
	A.toast(player, "Hired a " .. st.name .. "!", "green")
end

------------------------------------------------------------------ what the UI shows
local NEED_NAME = { desk = "check-in desks", lane = "security lanes", stall = "food stalls", shop = "shops", gate = "gates",
	bridge = "jet bridges", belt = "a baggage belt", tower = "a control tower", hangar = "a hangar", fire = "a fire station",
	reception = "a hotel reception", hroom = "hotel rooms" }
function A.state(player)
	local plot = G.byPlayer[player]
	local list = {}
	for i, p in ipairs(G.plots) do list[i] = p.owner and p.owner.Name or "" end
	local d = { plot = plot and plot.i or 0, plots = list }
	if not plot then return d end
	local stars, cats = A.stars(plot)
	d.rating = A.rating(plot)
	d.stars = stars
	d.nreviews = #plot.reviews
	d.cats = cats
	d.reviews = {}
	for i = #plot.reviews, math.max(1, #plot.reviews - 7), -1 do table.insert(d.reviews, plot.reviews[i]) end
	d.staff = {}
	for _, st in ipairs(STAFF) do
		local n = plot.staff[st.key] or 0
		table.insert(d.staff, { key = st.key, name = st.name, n = n, cap = A.staffCap(plot, st), fee = A.staffFee(st, n),
			desc = st.desc, need = st.need and NEED_NAME[st.need] or "" })
	end
	d.income = plot.incomeRate
	d.served = plot.served
	local bought = 0
	for _ in pairs(plot.bought) do bought = bought + 1 end
	d.bought, d.total = bought, #CATALOG
	d.phases = {}
	for pi, name in ipairs(PHASES) do
		local b, t = 0, 0
		for _, it in ipairs(CATALOG) do if it.phase == pi then t = t + 1 if plot.bought[it.key] then b = b + 1 end end end
		table.insert(d.phases, { name = name, b = b, t = t })
	end
	local avail = {}
	for _, it in ipairs(CATALOG) do if A.available(plot, it) then table.insert(avail, it) end end
	table.sort(avail, function(a, b) return a.price < b.price end)
	d.next = {}
	for i = 1, math.min(5, #avail) do table.insert(d.next, { name = avail[i].name, price = avail[i].price }) end
	d.report = plot.lastReport
	d.ticket = math.floor(A.ticket(plot) * A.mult(plot) * CONST.paxMult)
	return d
end

------------------------------------------------------------------ saving (DataStores may be missing on some servers: the game works without)
pcall(function() G.store = game:GetService("DataStoreService"):GetDataStore("AirportTycoon_v1") end)
function A.load(player)
	G.saved[player] = { loaded = false }
	spawn(function()
		local data
		if G.store then
			local ok, res = pcall(function() return G.store:GetAsync("p" .. tostring(player.userId)) end)
			if ok then data = res end
		end
		local s = type(data) == "table" and data or {}
		s.loaded = true
		G.saved[player] = s
		local cash = A.cash(player)
		if cash and tonumber(s.cash) and tonumber(s.cash) > cash.Value then cash.Value = tonumber(s.cash) end
	end)
end
function A.save(player)
	local s = G.saved[player]
	if not G.store or not s or not s.loaded then return end
	local plot = G.byPlayer[player]
	local cash = A.cash(player)
	local data = { cash = cash and cash.Value or 0, items = s.items, staff = s.staff, served = s.served }
	if plot then
		data.items = {}
		for _, it in ipairs(CATALOG) do if plot.bought[it.key] then table.insert(data.items, it.key) end end
		data.staff = {}
		for k, n in pairs(plot.staff) do data.staff[k] = n end
		data.served = plot.served
	end
	spawn(function() pcall(function() G.store:SetAsync("p" .. tostring(player.userId), data) end) end)
end
