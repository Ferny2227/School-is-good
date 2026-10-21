-- Geometry checks, run after run.lua's setup: pads blocked by solid parts, and walkers passing through solid parts.
local MOCK = MOCK
local D = _G.AirportDebug
local G, A, CATALOG = D.G, D.A, D.CATALOG
local out = {}
local function say(s) table.insert(out, s) end

-- spatial grid of solid parts in one plot
local function solids(plot)
	local grid, CELL = {}, 16
	local list = plot.Items:GetDescendants()
	for _, p in ipairs(list) do
		if p:IsA("BasePart") and p.CanCollide ~= false and (p.Transparency or 0) < 0.9 and p.ClassName ~= "Seat" and p.ClassName ~= "VehicleSeat" then
			local s = p.Size
			if s.Y > 1.2 then -- floors/carpets/thin pads don't block
				local c = p.CFrame.p
				local r = math.sqrt(s.X * s.X + s.Y * s.Y + s.Z * s.Z) / 2
				for gx = math.floor((c.X - r) / CELL), math.floor((c.X + r) / CELL) do
					for gz = math.floor((c.Z - r) / CELL), math.floor((c.Z + r) / CELL) do
						local k = gx .. ":" .. gz
						grid[k] = grid[k] or {}
						table.insert(grid[k], p)
					end
				end
			end
		end
	end
	local function inside(pt, shrink)
		local k = math.floor(pt.X / CELL) .. ":" .. math.floor(pt.Z / CELL)
		for _, p in ipairs(grid[k] or {}) do
			if p.Parent then
				local l = p.CFrame:inverse() * pt
				local s = p.Size
				if math.abs(l.X) < s.X / 2 - shrink and math.abs(l.Y) < s.Y / 2 - shrink and math.abs(l.Z) < s.Z / 2 - shrink then return p end
			end
		end
	end
	return inside
end

-- 1. walkers inside solid parts
local plot = G.plots[4]
local inside = solids(plot)
local hits, samples = {}, 0
for t = 1, (GEO_SECONDS or 150) * 2 do
	MOCK.run(0.5, 0.05)
	for _, w in ipairs(G.walkers) do
		if w.plot == plot and w.model.Parent then
			samples = samples + 1
			for _, dy in ipairs({ 1, 3, 4.5 }) do
				local p = inside(w.pos + Vector3.new(0, dy, 0), 0.3)
				if p then
					local key = (w.kind or "?") .. " in " .. p.Parent.Name .. "/" .. p.Name
					local l = plot.cf:inverse() * w.pos
					hits[key] = hits[key] or { n = 0, at = string.format("(%.0f, %.0f, %.0f)", l.X, l.Y, l.Z) }
					hits[key].n = hits[key].n + 1
					break
				end
			end
		end
	end
end
local hl = {}
for k, v in pairs(hits) do table.insert(hl, { k = k, n = v.n, at = v.at }) end
table.sort(hl, function(a, b) return a.n > b.n end)
say("walker samples " .. samples .. ", inside solid parts: " .. #hl .. " kinds")
for i = 1, math.min(40, #hl) do say(string.format("  %4d  %s  e.g. at %s", hl[i].n, hl[i].k, hl[i].at)) end

-- 2. buy pads blocked: rebuild a fresh plot step by step and check every pad when it appears
local p3 = MOCK.addPlayer("padcheck", 333)
MOCK.run(1)
MOCK.makeCharacter(p3)
local plot5 = G.plots[5]
A.claim(plot5, p3)
p3.leaderstats.Cash.Value = 1e13
local blocked = {}
local done = 0
while done < #CATALOG do
	local insideNow = solids(plot5)
	local any = false
	for _, it in ipairs(CATALOG) do
		local pad = plot5.pads[it.key]
		if pad and pad.Parent then
			local c = pad.CFrame.p
			for _, off in ipairs({ { 0, 0 }, { 2.5, 2.5 }, { -2.5, 2.5 }, { 2.5, -2.5 }, { -2.5, -2.5 } }) do
				local hit = insideNow(c + Vector3.new(off[1], 2, off[2]), 0.05)
				if hit then blocked[it.key] = it.name .. " pad is inside " .. hit.Parent.Name .. "/" .. hit.Name break end
			end
			A.buy(plot5, it, p3)
			any = true
			break
		end
	end
	if not any then break end
	done = done + 1
	if done % 40 == 0 then MOCK.run(0.1) end
end
local bl = {}
for k, v in pairs(blocked) do table.insert(bl, v) end
table.sort(bl)
say("pad check bought " .. done .. " items; blocked pads: " .. #bl)
for _, v in ipairs(bl) do say("  " .. v) end
_G.GEO_OUT = table.concat(out, "\n")
