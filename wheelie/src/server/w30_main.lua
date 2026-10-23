-- ==== w30_main.lua
------------------------------------------------------------------ players
local function setup(p)
	load(p)
	p.CharacterAdded:connect(function(c)
		riding[p] = nil
		local h = c:WaitForChild("Humanoid")
		h.Died:connect(function() if riding[p] then getOff(p) end end)
		toClient(p, "riding", nil)
	end)
end
for _, p in ipairs(Players:GetPlayers()) do spawn(function() setup(p) end) end
Players.PlayerAdded:connect(setup)
Players.PlayerRemoving:connect(function(p)
	save(p, true)
	riding[p], DATA[p] = nil, nil
end)
pcall(function() game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do save(p, true) end wait(2) end) end)
local lastAsk = {}
remote.OnServerEvent:connect(function(p, what, a, b, c)
	if tick() - (lastAsk[p] or 0) < 0.1 then return end
	lastAsk[p] = tick()
	if what == "ride" then ride(p)
	elseif what == "off" then getOff(p)
	elseif what == "buy" then buy(p, a)
	elseif what == "wheelie" then wheelie(p, a, b, c)
	elseif what == "crash" then
		if riding[p] then
			getOff(p)
			say(p, "LOOPED OUT! Press RIDE to get back on.", "red")
		end
	elseif what == "garage" then sendGarage(p) end
end)

------------------------------------------------------------------ the leaderboard: best wheelies of all time (and who's here now)
local allTime = nil
spawn(function()
	while topStore do
		pcall(function()
			local page = topStore:GetSortedAsync(false, 8):GetCurrentPage()
			local list = {}
			for _, e in ipairs(page) do table.insert(list, { e.key, e.value / 10 }) end
			allTime = list
		end)
		wait(60)
	end
end)
spawn(function()
	while true do
		local lines = { "BEST WHEELIES" }
		local list = allTime
		if not list or #list == 0 then
			list = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local ls = p:FindFirstChild("leaderstats")
				if ls then table.insert(list, { p.Name, ls.Best.Value }) end
			end
			table.sort(list, function(x, y) return x[2] > y[2] end)
		end
		for i = 1, math.min(8, #list) do table.insert(lines, i .. ". " .. list[i][1] .. "  -  " .. string.format("%.1f", list[i][2]) .. "s") end
		pcall(function() boardText.Text = table.concat(lines, "\n") end)
		wait(5)
	end
end)
_G.WheelieDebug = { riding = riding, DATA = DATA, ride = ride, getOff = getOff, buy = buy, wheelie = wheelie, BIKES = BIKES, boardText = boardText }
