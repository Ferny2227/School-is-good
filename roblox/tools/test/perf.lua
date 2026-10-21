-- Lag check: how many parts, lights and GUIs there are, how many property changes the server sends to every player
-- each second (each one is network traffic, and work for every player's computer), remote message sizes, and how
-- much Lua time the server spends. Uses the same map as run.lua (setup.lua).
local MOCK = MOCK
local D = _G.AirportDebug
local G, A, CATALOG = D.G, D.A, D.CATALOG
local out = {}
local function say(s) table.insert(out, s) end
local function buyAll(plot, player)
	player.leaderstats.Cash.Value = 1e13
	for _ = 1, 400 do
		local any = false
		for _, it in ipairs(CATALOG) do if A.available(plot, it) then A.buy(plot, it, player) any = true end end
		MOCK.run(0.1)
		if not any then break end
	end
end
-- two full airports with their owners standing in them, plus one player at the theme park
local players = {}
for i, k in ipairs({ 3, 8 }) do
	local p = MOCK.addPlayer("perf" .. i, 500 + i)
	MOCK.run(1)
	MOCK.makeCharacter(p)
	A.claim(G.plots[k], p)
	buyAll(G.plots[k], p)
	p.Character.Torso.CFrame = G.plots[k].cf * CFrame.new(0, 4, 150)
	table.insert(players, p)
end
local p3 = MOCK.addPlayer("parkfan", 777)
MOCK.run(1)
MOCK.makeCharacter(p3)
p3.Character.Torso.CFrame = D.RESORT.entrance
MOCK.run(240)   -- let the airports fill up with people and planes

-- what is in the world
local counts, byTop = {}, {}
for _, o in ipairs(workspace:GetDescendants()) do
	counts[o.ClassName] = (counts[o.ClassName] or 0) + 1
	if o:IsA("BasePart") then
		local top, sub = o, nil
		while top.Parent and top.Parent ~= workspace do sub = top top = top.Parent end
		local key = top.Name .. (sub and top.Name:find("^Airport") and ("/" .. sub.Name) or "")
		byTop[key] = (byTop[key] or 0) + 1
	end
end
local function sorted(t, n)
	local l = {}
	for k, v in pairs(t) do table.insert(l, { k, v }) end
	table.sort(l, function(a, b) return a[2] > b[2] end)
	local s = {}
	for i = 1, math.min(n, #l) do table.insert(s, l[i][1] .. "=" .. l[i][2]) end
	return table.concat(s, "  ")
end
local parts = 0
for _, cls in ipairs({ "Part", "WedgePart", "Seat", "VehicleSeat", "SpawnLocation", "TrussPart", "CornerWedgePart" }) do parts = parts + (counts[cls] or 0) end
say("parts in workspace: " .. parts)
say("classes: " .. sorted(counts, 22))
say("parts by area: " .. sorted(byTop, 30))

local items = {}
for _, m in ipairs(G.plots[3].Items:GetChildren()) do
	local n = 0
	for _, o in ipairs(m:GetDescendants()) do if o:IsA("BasePart") then n = n + 1 end end
	if m:IsA("BasePart") then n = n + 1 end
	items[m.Name] = (items[m.Name] or 0) + n
end
say("heaviest things in one airport (parts): " .. sorted(items, 25))
local lights = {}
for _, o in ipairs(workspace:GetDescendants()) do
	if o.ClassName == "PointLight" or o.ClassName == "Sparkles" or o.ClassName == "SurfaceGui" then
		local top = o.Parent and o.Parent.Parent
		local key = o.ClassName .. ":" .. (top and top.Name or "?")
		lights[key] = (lights[key] or 0) + 1
	end
end
say("lights/sparkles/surface text by model: " .. sorted(lights, 20))
-- traffic: count property changes for 30 s
local sent = {}
MOCK.onFireClient = function(remote, p, what, data)
	local n = 0
	local function size(v, depth)
		if depth > 8 then return 0 end
		local t = type(v)
		if t == "string" then return #v + 2 elseif t == "number" then return 8 elseif t == "boolean" then return 1
		elseif t == "table" then local s = 2 for k, x in pairs(v) do s = s + size(k, depth + 1) + size(x, depth + 1) end return s end
		return 4
	end
	n = size(data, 0)
	local key = tostring(what)
	sent[key] = sent[key] or { n = 0, bytes = 0 }
	sent[key].n = sent[key].n + 1
	sent[key].bytes = sent[key].bytes + n
end
MOCK.repl, MOCK.replTop, MOCK.replModel, MOCK.countRepl = {}, {}, {}, true
local c0 = os.clock()
local SECS = 30
MOCK.run(SECS, 1 / 30)
local cpu = os.clock() - c0
MOCK.countRepl = false
local total = 0
for _, v in pairs(MOCK.repl) do total = total + v end
say(string.format("property changes sent to every player: %.0f per second", total / SECS))
local per = {}
for k, v in pairs(MOCK.repl) do per[k] = math.floor(v / SECS) end
say("  by property (per s): " .. sorted(per, 16))
local pt = {}
for k, v in pairs(MOCK.replTop) do pt[k] = math.floor(v / SECS) end
say("  by area (per s): " .. sorted(pt, 16))
local pm = {}
for k, v in pairs(MOCK.replModel) do pm[k] = math.floor(v / SECS) end
say("  by model (per s): " .. sorted(pm, 16))
local ms = {}
for k, v in pairs(sent) do table.insert(ms, string.format("%s: %.1f msgs/s, %.0f bytes/s", k, v.n / SECS, v.bytes / SECS)) end
say("remote messages to clients: " .. table.concat(ms, " | "))
say(string.format("server Lua time in the mock: %.2f s for %d s of game (%.0f%%)", cpu, SECS, 100 * cpu / SECS))
say("walkers " .. #G.walkers .. ", errors " .. #MOCK.errors)
for i = 1, math.min(5, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 300)) end
_G.TEST_OUT = table.concat(out, "\n")
