-- a bot plays one airport from $250: every 2 s it buys the cheapest thing it can afford (or hires the cheapest staff)
local p = JOINER
local dbg = SERVER_G.AirportDebug
local A, CATALOG, STAFF = dbg.A, dbg.CATALOG, dbg.STAFF
local plot = dbg.G.plots[1]
CTX = SERVER workspace.Airport1.Pads.Claim.Touched:_fire(p.Character.Torso) runFor(1)
local out, t, marks = {}, 0, {}
local watch = { foundation = 1, desk1 = 1, lane1 = 1, gate1 = 1, runway = 1, smallplane = 1, jet = 1, intl = 1, privatejet = 1, golden = 1 }
local total = #CATALOG
while t < 150 * 60 do
	local cash = p.leaderstats.Cash
	local best, bestPrice, kind
	for _, it in ipairs(CATALOG) do
		if A.available(plot, it) and (not best or it.price < bestPrice) then best, bestPrice, kind = it, it.price, "item" end
	end
	for _, st in ipairs(STAFF) do
		local n = plot.staff[st.key] or 0
		if n < A.staffCap(plot, st) then
			local fee = A.staffFee(st, n)
			if not best or fee < bestPrice then best, bestPrice, kind = st, fee, "staff" end
		end
	end
	if best and cash.Value >= bestPrice then
		if kind == "item" then
			local pad = plot.pads[best.key]
			if pad then CTX = SERVER pad.Touched:_fire(p.Character.Torso) end
			if watch[best.key] then out[#out + 1] = string.format("%6.1f min  %s", t / 60, best.name) end
		else
			CTX = CLIENT_CTX game.ReplicatedStorage.AirportEvent:FireServer("hire", best.key) CTX = SERVER
		end
	end
	runFor(2)
	t = t + 2
	local n = 0
	for _ in pairs(plot.bought) do n = n + 1 end
	if t % 600 == 0 then out[#out + 1] = string.format("%6.1f min: %d/%d items, cash %d, income %d/s, rating %.2f, served %d", t / 60, n, total, cash.Value, plot.incomeRate, A.rating(plot), plot.served) end
	if n == total then out[#out + 1] = string.format("ALL DONE at %.1f min (served %d passengers, %d reviews)", t / 60, plot.served, #plot.reviews) break end
end
return out
