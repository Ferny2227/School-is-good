-- ==== s60_main.lua
------------------------------------------------------------------ start
A.init()
FLY.initGlobal()
-- text on the plaza's welcome board and the hub
pcall(function()
	local board = MAP.Plaza:FindFirstChild("WelcomeBoard")
	if board then
		U.text(board, "WELCOME TO AIRPORT TYCOON\nPress AIRPORTS to claim your own airport!", Color3.new(1, 0.85, 0.3), Color3.new(0.03, 0.08, 0.25), "Front")
		U.text(board, "10 AIRPORTS - " .. #CATALOG .. " THINGS TO BUILD - 3 FLOORS - HOTEL - FLY YOUR OWN PLANE", Color3.new(1, 1, 1), Color3.new(0.03, 0.08, 0.25), "Back")
	end
	local hs = MAP.Hub:FindFirstChild("HubSign")
	if hs then U.text(hs, "INTERNATIONAL HUB", Color3.new(1, 1, 1), Color3.new(0.03, 0.08, 0.25), "Back") U.text(hs, "INTERNATIONAL HUB", Color3.new(1, 1, 1), Color3.new(0.03, 0.08, 0.25), "Front") end
end)
_G.AirportDebug = { G = G, A = A, FLY = FLY, NPC = NPC, CATALOG = CATALOG, STAFF = STAFF }   -- for the test harness

local function teleport(player, cf)
	local char = player.Character
	local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
	if torso then torso.CFrame = cf end
end
local function home(plot) return plot.cf * CFrame.new(0, 4, 14) end

------------------------------------------------------------------ players
local function setup(player)
	if player:FindFirstChild("leaderstats") then return end
	local ls = Instance.new("IntValue")
	ls.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = CONST.startCash
	cash.Parent = ls
	local rating = Instance.new("StringValue")
	rating.Name = "Rating"
	rating.Value = "-"
	rating.Parent = ls
	ls.Parent = player
	A.load(player)
	player.CharacterAdded:connect(function(char)
		local plot = G.byPlayer[player]
		if plot then
			char:WaitForChild("Torso")
			wait(0.3)
			teleport(player, home(plot))
		end
	end)
end
Players.PlayerAdded:connect(setup)
for _, p in ipairs(Players:GetPlayers()) do setup(p) end

Players.PlayerRemoving:connect(function(player)
	A.save(player)
	local f = G.flyers[player]
	if f then pcall(function() f.model:Destroy() end) G.flyers[player] = nil end
	local plot = G.byPlayer[player]
	G.byPlayer[player] = nil
	if plot then
		for i = #G.walkers, 1, -1 do if G.walkers[i].plot == plot then pcall(function() G.walkers[i].model:Destroy() end) table.remove(G.walkers, i) end end
		A.reset(plot)
	end
	G.saved[player], G.pitch[player], G.ctl[player] = nil, nil, nil
end)
pcall(function()
	game:BindToClose(function()
		for _, p in ipairs(Players:GetPlayers()) do A.save(p) end
		wait(2)
	end)
end)

------------------------------------------------------------------ what the UI asks for
G.remote.OnServerEvent:connect(function(player, what, a, b)
	if what == "hire" then
		A.hire(player, a)
	elseif what == "pitch" then
		G.pitch[player] = U.clamp(tonumber(a) or 0, -1, 1)
	elseif what == "ctl" then
		G.ctl[player] = { t = U.clamp(tonumber(a) or 0, -1, 1), s = U.clamp(tonumber(b) or 0, -1, 1) }
	elseif what == "tp" then
		local plot = G.byPlayer[player]
		if plot then teleport(player, home(plot)) else A.toast(player, "Pick an airport to claim first!", "gold") end
	elseif what == "visit" then
		local plot = G.plots[tonumber(a) or 0]
		if plot then teleport(player, home(plot)) end
	elseif what == "plaza" then
		local sp = MAP:FindFirstChild("Spawn")
		if sp then teleport(player, sp.CFrame + Vector3.new(0, 4, 0)) end
	elseif what == "state" then
		pcall(function() G.remote:FireClient(player, "state", A.state(player)) end)
	end
end)

------------------------------------------------------------------ fast loop: walkers, NPC planes, flying
spawn(function()
	local last = tick()
	while true do
		wait()
		local now = tick()
		local dt = math.min(0.2, now - last)
		last = now
		LIFT.step(dt)
		NPC.step(dt)
		FLY.step(dt)
		OPS.step(dt)
		for _, g in ipairs(G.global) do FLY.place(g, g.path, now + g.off, dt) end
		for _, plot in ipairs(G.plots) do
			for _, gp in pairs(plot.gatePlanes) do FLY.gateStep(gp, dt) end
		end
	end
end)

-- spinning things (radar, rotors)
spawn(function()
	local start = tick()
	while true do
		wait(0.1)
		local t = tick() - start
		for i = #G.spinners, 1, -1 do
			local s = G.spinners[i]
			if not s.parts[1].Parent then
				table.remove(G.spinners, i)
			else
				local a = math.rad(s.speed * t)
				local r = s.axis == "y" and CFrame.Angles(0, a, 0) or CFrame.Angles(0, 0, a)
				for k, p in ipairs(s.parts) do p.CFrame = s.center * r * s.rel[k] end
			end
		end
	end
end)

------------------------------------------------------------------ flight information screens
local DEST = { "LONDON", "TOKYO", "PARIS", "NEW YORK", "DUBAI", "SYDNEY", "ROME", "CAIRO", "RIO" }
local STATUS = { parked = "BOARDING", departing = "DEPARTED", away = "IN FLIGHT", arriving = "LANDING" }
function A.fidsText(plot)
	local list = {}
	for n, gp in pairs(plot.gatePlanes) do table.insert(list, gp) end
	table.sort(list, function(a, b) return a.n < b.n end)
	local lines = { "FLIGHT  TO        GATE  STATUS" }
	for _, gp in ipairs(list) do
		local gate = gp.n <= 4 and ("G" .. gp.n) or (gp.n <= 6 and ("S" .. (gp.n - 4)) or "CGO")
		local dest = DEST[(gp.n - 1) % #DEST + 1]
		table.insert(lines, string.format("SKY%d%02d %-9s %-5s %s", plot.i, gp.n, dest, gate, STATUS[gp.state] or "ON TIME"))
	end
	if #list == 0 then table.insert(lines, "NO FLIGHTS YET - BUILD GATES") end
	return table.concat(lines, "\n")
end

------------------------------------------------------------------ every second: income, passengers, inspector, UI
local screenLines = 0
spawn(function()
	while true do
		wait(1)
		screenLines = screenLines + 1
		local now = tick()
		for _, plot in ipairs(G.plots) do
			local owner = plot.owner
			if owner then
				-- passive income
				local inc = 0
				for key in pairs(plot.bought) do inc = inc + (ITEM[key].eff.inc or 0) end
				local cash = A.cash(owner)
				if cash and inc > 0 then cash.Value = cash.Value + inc end
				-- money per second over the last 30 seconds
				local sum = 0
				for i = #plot.earnLog, 1, -1 do
					if now - plot.earnLog[i].t > 30 then table.remove(plot.earnLog, i) else sum = sum + plot.earnLog[i].a end
				end
				plot.incomeRate = math.floor(inc + sum / 30)
				-- passengers
				if plot.bought.foundation then
					local c = plot.cnt
					local interval = math.max(2.5, 16 / (1 + 0.3 * (c.transport or 0) + 0.15 * (c.desk or 0) + 0.25 * (c.gate or 0)))
					local cap = math.min(26, 3 + (c.desk or 0) + 2 * (c.gate or 0) + 4 * (c.level or 0))
					plot.spawnT = plot.spawnT - 1
					if plot.spawnT <= 0 and #plot.People:GetChildren() < cap then
						plot.spawnT = interval * (0.8 + math.random() * 0.4)
						local ok, err = pcall(NPC.passenger, plot)
						if not ok then print("Airport: passenger failed: " .. tostring(err)) end
					end
					-- hotel guests (they need a reception and at least one room)
					if plot.bought.hreception and plot.pts.hroom and #plot.pts.hroom > 0 then
						plot.guestT = (plot.guestT or 5) - 1
						local rooms = #plot.pts.hroom
						local gcap = math.min(14, 2 + math.ceil(rooms / 2))
						if plot.guestT <= 0 and #plot.Guests:GetChildren() < gcap then
							plot.guestT = math.max(3, 12 / (1 + 0.25 * (plot.staff.bellhop or 0) + rooms / 16)) * (0.8 + math.random() * 0.4)
							local ok, err = pcall(NPC.guest, plot)
							if not ok then print("Airport: hotel guest failed: " .. tostring(err)) end
						end
					end
					if now > plot.nextInspect then
						plot.nextInspect = now + 300
						pcall(NPC.inspector, plot)
					end
				end
				-- leaderboard + the big screen
				local ls = owner:FindFirstChild("leaderstats")
				if ls and ls:FindFirstChild("Rating") then
					ls.Rating.Value = #plot.reviews > 0 and string.format("%.1f", A.rating(plot)) or "-"
				end
				if plot.screenLabel and screenLines % 5 == 0 then
					local lines = { "WELCOME TO " .. string.upper(owner.Name) .. "'S AIRPORT",
						"RATING " .. string.format("%.1f", A.rating(plot)) .. " / 5", plot.served .. " HAPPY PASSENGERS", "HAVE A NICE FLIGHT!" }
					plot.screenLabel.Text = lines[(math.floor(screenLines / 5) % #lines) + 1]
				end
				if #plot.fids > 0 and screenLines % 3 == 0 then
					local text = A.fidsText(plot)
					for _, l in ipairs(plot.fids) do l.Text = text end
				end
				if plot.fireworks and screenLines % 20 == 0 then
					for k = 1, 5 do
						local p = U.newPart()
						p.Anchored = true
						p.CanCollide = false
						p.Size = Vector3.new(2, 2, 2)
						p.Shape = Enum.PartType.Ball
						p.BrickColor = BrickColor.new(U.pick({ "Bright red", "Lime green", "Cyan", "Hot pink", "New Yeller" }))
						pcall(function() p.Material = Enum.Material.Neon end)
						p.CFrame = plot.cf * CFrame.new(math.random(-120, 120), 85 + math.random(0, 40), math.random(80, 300))
						U.fx(p, "Sparkles")
						U.light(p, p.BrickColor.Color, 40, 3)
						p.Parent = plot.Items
						Debris:AddItem(p, 2.5)
					end
				end
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function() G.remote:FireClient(p, "state", A.state(p)) end)
		end
	end
end)

spawn(function()
	while true do
		wait(120)
		for _, p in ipairs(Players:GetPlayers()) do A.save(p) end
	end
end)

print("AirportServer ready: " .. #G.plots .. " airports, " .. #CATALOG .. " things to buy, " .. #STAFF .. " jobs")
