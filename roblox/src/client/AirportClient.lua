-- StarterGui.AirportClient (builds the ScreenGui "AirportUI"): the top bar (money, rating, income,
-- passengers, progress), HIRE / RATINGS / GOALS / AIRPORTS / HELP panels, the flight display, and pop-ups.
-- 2016-safe: no AnchorPoint/TweenService/UIListLayout, FontSize instead of TextSize, ZIndex 1..10.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do wait() player = Players.LocalPlayer end
local pg = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("AirportEvent")

local old = pg:FindFirstChild("AirportUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "AirportUI"

local S = {}   -- last state from the server
local UI = {}

------------------------------------------------------------------ builders
local function rgb(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local C = { dark = rgb(20, 26, 40), panel = rgb(32, 40, 60), line = rgb(55, 66, 92), white = rgb(255, 255, 255),
	gold = rgb(255, 205, 60), green = rgb(70, 200, 100), red = rgb(220, 70, 70), blue = rgb(60, 130, 230),
	grey = rgb(120, 125, 140), cyan = rgb(80, 210, 240), purple = rgb(150, 90, 220), orange = rgb(240, 150, 50) }
local function font(o, size, bold)
	pcall(function() o.Font = bold == false and Enum.Font.SourceSans or Enum.Font.SourceSansBold end)
	pcall(function() o.FontSize = Enum.FontSize["Size" .. size] end)
end
local function frame(parent, pos, size, color, z, tr)
	local f = Instance.new("Frame")
	f.Position, f.Size = pos, size
	f.BackgroundColor3 = color or C.panel
	f.BackgroundTransparency = tr or 0
	f.BorderSizePixel = 0
	f.ZIndex = z or 1
	f.Parent = parent
	return f
end
local function label(parent, pos, size, text, fsize, color, z, align, bold)
	local t = Instance.new("TextLabel")
	t.Position, t.Size = pos, size
	t.BackgroundTransparency = 1
	t.Text = text or ""
	t.TextColor3 = color or C.white
	t.TextStrokeTransparency = 0.7
	t.ZIndex = z or 1
	if align then t.TextXAlignment = align end
	font(t, fsize or 18, bold)
	t.Parent = parent
	return t
end
local function button(parent, pos, size, text, color, z, fsize)
	local b = Instance.new("TextButton")
	b.Position, b.Size = pos, size
	b.BackgroundColor3 = color or C.green
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = C.white
	b.TextStrokeTransparency = 0.6
	b.AutoButtonColor = true
	b.ZIndex = z or 1
	font(b, fsize or 18)
	b.Parent = parent
	return b
end
local function money(n)
	n = math.floor(n or 0)
	local s = tostring(math.abs(n))
	local out = ""
	while #s > 3 do out = "," .. s:sub(-3) .. out s = s:sub(1, -4) end
	return "$" .. s .. out
end
-- five little star boxes, filled to `value` (0..5)
local function starBar(parent, pos, size, z)
	local holder = frame(parent, pos, size, C.dark, z, 1)
	local stars = {}
	for i = 1, 5 do
		local box = frame(holder, UDim2.new((i - 1) / 5, 1, 0, 0), UDim2.new(0.2, -3, 1, 0), C.line, z + 1)
		local fill = frame(box, UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0), C.gold, z + 2)
		stars[i] = fill
	end
	return function(v)
		for i = 1, 5 do stars[i].Size = UDim2.new(math.max(0, math.min(1, v - (i - 1))), 0, 1, 0) end
	end
end
local CATS = { "checkin", "security", "food", "shopping", "comfort", "clean", "gates" }
local CATNAME = { checkin = "Check-in", security = "Security", food = "Food", shopping = "Shopping", comfort = "Comfort",
	clean = "Cleanliness", gates = "Flights" }
local TIPS = { checkin = "Build check-in desks, hire Check-in Agents", security = "Build security lanes, hire Officers",
	food = "Build food stalls and tables, hire Chefs", shopping = "Build shops, hire Shop Clerks",
	comfort = "Seats, restrooms, lounge, spa, glass roof...", clean = "Hire Janitors, build restrooms and bins",
	gates = "Gates, jet bridges, runway, tower, Pilots" }

------------------------------------------------------------------ top bar
local top = frame(gui, UDim2.new(0.5, -310, 0, 4), UDim2.new(0, 620, 0, 52), C.dark, 1, 0.2)
UI.cash = label(top, UDim2.new(0, 10, 0, 2), UDim2.new(0, 170, 0, 30), "$0", 28, C.gold, 2, Enum.TextXAlignment.Left)
UI.income = label(top, UDim2.new(0, 10, 0, 30), UDim2.new(0, 170, 0, 18), "+$0/s", 14, C.green, 2, Enum.TextXAlignment.Left)
local setTopStars = starBar(top, UDim2.new(0, 190, 0, 8), UDim2.new(0, 120, 0, 20), 2)
UI.rating = label(top, UDim2.new(0, 190, 0, 30), UDim2.new(0, 120, 0, 18), "no reviews yet", 14, C.white, 2)
UI.served = label(top, UDim2.new(0, 320, 0, 4), UDim2.new(0, 140, 0, 22), "0 passengers", 18, C.cyan, 2)
UI.ticket = label(top, UDim2.new(0, 320, 0, 28), UDim2.new(0, 140, 0, 18), "", 14, C.white, 2)
UI.progress = label(top, UDim2.new(0, 470, 0, 4), UDim2.new(0, 140, 0, 22), "Airport 0%", 18, C.white, 2)
local barBack = frame(top, UDim2.new(0, 474, 0, 32), UDim2.new(0, 136, 0, 10), C.line, 2)
UI.bar = frame(barBack, UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0), C.green, 3)

------------------------------------------------------------------ side buttons
local side = frame(gui, UDim2.new(0, 6, 0.5, -170), UDim2.new(0, 120, 0, 330), C.dark, 1, 1)
local function sideButton(i, text, color) return button(side, UDim2.new(0, 0, 0, (i - 1) * 46), UDim2.new(1, 0, 0, 40), text, color, 2, 18) end
UI.bHome = sideButton(1, "MY AIRPORT", C.green)
UI.bHire = sideButton(2, "HIRE STAFF", C.blue)
UI.bRate = sideButton(3, "RATINGS", C.gold)
UI.bGoals = sideButton(4, "GOALS", C.purple)
UI.bPlots = sideButton(5, "AIRPORTS", C.orange)
UI.bHelp = sideButton(6, "HELP", C.grey)
UI.bHide = sideButton(7, "HIDE UI", C.line)

------------------------------------------------------------------ panels
local panels = {}
local function panel(name, w, h, title, color)
	local p = frame(gui, UDim2.new(0.5, -w / 2, 0.5, -h / 2), UDim2.new(0, w, 0, h), C.panel, 4)
	p.Visible = false
	frame(p, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 44), C.dark, 5)
	label(p, UDim2.new(0, 14, 0, 0), UDim2.new(1, -70, 0, 44), title, 28, color or C.gold, 6, Enum.TextXAlignment.Left)
	local x = button(p, UDim2.new(1, -40, 0, 6), UDim2.new(0, 32, 0, 32), "X", C.red, 6, 18)
	x.MouseButton1Click:connect(function() p.Visible = false end)
	panels[name] = p
	return p
end
local function showPanel(name)
	for n, p in pairs(panels) do p.Visible = (n == name) and not p.Visible end
	if UI.refresh then UI.refresh() end
end
local function scroller(parent, pos, size, z)
	local s = Instance.new("ScrollingFrame")
	s.Position, s.Size = pos, size
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 8
	s.ZIndex = z
	s.CanvasSize = UDim2.new(0, 0, 0, 600)
	s.Parent = parent
	return s
end

-- HIRE
local hire = panel("hire", 560, 440, "HIRE STAFF", C.cyan)
local hireList = scroller(hire, UDim2.new(0, 10, 0, 52), UDim2.new(1, -20, 1, -60), 5)
UI.hireRows = {}
local function hireRow(i)
	local r = frame(hireList, UDim2.new(0, 0, 0, (i - 1) * 62), UDim2.new(1, -12, 0, 56), C.dark, 5)
	local row = {}
	row.name = label(r, UDim2.new(0, 10, 0, 2), UDim2.new(0, 260, 0, 24), "", 18, C.white, 6, Enum.TextXAlignment.Left)
	row.desc = label(r, UDim2.new(0, 10, 0, 26), UDim2.new(0, 300, 0, 26), "", 14, rgb(190, 195, 210), 6, Enum.TextXAlignment.Left, false)
	row.count = label(r, UDim2.new(0, 300, 0, 2), UDim2.new(0, 80, 0, 24), "", 18, C.cyan, 6)
	row.btn = button(r, UDim2.new(1, -150, 0, 8), UDim2.new(0, 140, 0, 40), "", C.green, 6, 18)
	row.btn.MouseButton1Click:connect(function()
		if row.key then pcall(function() remote:FireServer("hire", row.key) end) end
		delay(0.3, function() pcall(function() remote:FireServer("state") end) end)
	end)
	UI.hireRows[i] = row
	return row
end
for i = 1, 14 do hireRow(i) end
hireList.CanvasSize = UDim2.new(0, 0, 0, 14 * 62)

-- RATINGS
local rate = panel("rate", 600, 460, "AIRPORT RATING", C.gold)
local setBigStars = starBar(rate, UDim2.new(0, 16, 0, 54), UDim2.new(0, 200, 0, 34), 6)
UI.bigRating = label(rate, UDim2.new(0, 224, 0, 54), UDim2.new(0, 200, 0, 34), "", 28, C.gold, 6, Enum.TextXAlignment.Left)
UI.catRows = {}
for i, k in ipairs(CATS) do
	local y = 96 + (i - 1) * 30
	label(rate, UDim2.new(0, 16, 0, y), UDim2.new(0, 100, 0, 24), CATNAME[k], 18, C.white, 6, Enum.TextXAlignment.Left)
	local back = frame(rate, UDim2.new(0, 120, 0, y + 6), UDim2.new(0, 130, 0, 12), C.line, 6)
	local fill = frame(back, UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0), C.green, 7)
	local tip = label(rate, UDim2.new(0, 258, 0, y), UDim2.new(0, 330, 0, 24), TIPS[k], 14, rgb(180, 185, 200), 6, Enum.TextXAlignment.Left, false)
	UI.catRows[k] = { fill = fill, tip = tip }
end
UI.report = label(rate, UDim2.new(0, 16, 0, 310), UDim2.new(1, -32, 0, 24), "The Airport Inspector visits every few minutes.", 14, C.gold, 6, Enum.TextXAlignment.Left)
label(rate, UDim2.new(0, 16, 0, 334), UDim2.new(0, 300, 0, 22), "LATEST REVIEWS", 18, C.cyan, 6, Enum.TextXAlignment.Left)
UI.reviewLines = {}
for i = 1, 5 do
	UI.reviewLines[i] = label(rate, UDim2.new(0, 16, 0, 354 + (i - 1) * 20), UDim2.new(1, -32, 0, 20), "", 14, C.white, 6, Enum.TextXAlignment.Left, false)
end

-- GOALS
local goals = panel("goals", 520, 520, "GOALS", C.purple)
UI.phaseRows = {}
for i = 1, 12 do
	local y = 52 + (i - 1) * 26
	local name = label(goals, UDim2.new(0, 16, 0, y), UDim2.new(0, 180, 0, 24), "", 18, C.white, 6, Enum.TextXAlignment.Left)
	local back = frame(goals, UDim2.new(0, 200, 0, y + 6), UDim2.new(0, 220, 0, 12), C.line, 6)
	local fill = frame(back, UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0), C.purple, 7)
	local n = label(goals, UDim2.new(0, 426, 0, y), UDim2.new(0, 80, 0, 24), "", 14, C.white, 6)
	UI.phaseRows[i] = { name = name, fill = fill, n = n }
end
label(goals, UDim2.new(0, 16, 0, 370), UDim2.new(0, 300, 0, 22), "BUY NEXT (gold pads in your airport)", 18, C.gold, 6, Enum.TextXAlignment.Left)
UI.nextLines = {}
for i = 1, 5 do UI.nextLines[i] = label(goals, UDim2.new(0, 16, 0, 392 + (i - 1) * 22), UDim2.new(1, -32, 0, 22), "", 18, C.white, 6, Enum.TextXAlignment.Left, false) end

-- AIRPORTS (claim / visit)
local plotsP = panel("plots", 420, 470, "AIRPORTS", C.orange)
label(plotsP, UDim2.new(0, 16, 0, 48), UDim2.new(1, -32, 0, 22), "Go to a free airport and step on its green pad to claim it.", 14, C.white, 6, Enum.TextXAlignment.Left, false)
UI.plotRows = {}
for i = 1, 10 do
	local y = 74 + (i - 1) * 38
	local l = label(plotsP, UDim2.new(0, 16, 0, y), UDim2.new(0, 260, 0, 32), "", 18, C.white, 6, Enum.TextXAlignment.Left)
	local b = button(plotsP, UDim2.new(1, -120, 0, y), UDim2.new(0, 104, 0, 32), "GO", C.green, 6, 18)
	b.MouseButton1Click:connect(function()
		pcall(function() remote:FireServer("visit", i) end)
		plotsP.Visible = false
	end)
	UI.plotRows[i] = { label = l, btn = b }
end

-- HELP
local help = panel("help", 540, 470, "HOW TO PLAY", C.white)
local helpText = label(help, UDim2.new(0, 16, 0, 52), UDim2.new(1, -32, 1, -60),
	"1. Press AIRPORTS, go to a free airport, step on its green CLAIM pad.\n" ..
	"2. Step on the gold pads to build. New pads appear as you build.\n" ..
	"3. Passengers check in, go through security, eat, shop and fly.\n" ..
	"    They pay you and leave reviews.\n" ..
	"4. Better rating = more money. See RATINGS, then HIRE STAFF.\n" ..
	"5. The Airport Inspector visits and pays a bonus for a good airport.\n" ..
	"6. Build a runway + hangar, then step on a blue FLY pad to fly!\n" ..
	"    W/S speed, A/D turn, E up, Q down, Space to jump out.\n" ..
	"7. Build the Terminal Elevators, then a 2nd and 3rd floor full of\n" ..
	"    shops, food and fun. Step on the green UP / red DOWN pads.\n" ..
	"8. Build the Airport Hotel: guests check in, sleep in the rooms\n" ..
	"    you buy, swim in the pool and pay you for every night.\n" ..
	"9. Remote stands, cargo jets and a 2nd runway: planes take off\n" ..
	"    and land on their own. Can you build all of it?",
	18, C.white, 6, Enum.TextXAlignment.Left, false)
helpText.TextWrapped = true
helpText.TextYAlignment = Enum.TextYAlignment.Top

------------------------------------------------------------------ pop-ups: toast + review feed
UI.toast = label(gui, UDim2.new(0.5, -260, 0, 62), UDim2.new(0, 520, 0, 34), "", 24, C.green, 8)
UI.toast.BackgroundColor3 = C.dark
UI.toast.BackgroundTransparency = 0.3
UI.toast.Visible = false
local toastN = 0
local COLORS = { green = C.green, red = C.red, gold = C.gold, cyan = C.cyan, white = C.white }
local function toast(text, color)
	toastN = toastN + 1
	local my = toastN
	UI.toast.Text = text
	UI.toast.TextColor3 = COLORS[color] or C.white
	UI.toast.Visible = true
	delay(3, function() if toastN == my then UI.toast.Visible = false end end)
end
local feed = frame(gui, UDim2.new(1, -290, 1, -150), UDim2.new(0, 280, 0, 140), C.dark, 1, 1)
UI.feed = {}
for i = 1, 4 do
	local l = label(feed, UDim2.new(0, 0, 0, (i - 1) * 34), UDim2.new(1, 0, 0, 32), "", 14, C.white, 2, Enum.TextXAlignment.Left, false)
	l.TextWrapped = true
	l.BackgroundColor3 = C.dark
	l.BackgroundTransparency = 1
	UI.feed[i] = l
end
local feedItems = {}
local function pushFeed(text)
	table.insert(feedItems, 1, text)
	while #feedItems > 4 do table.remove(feedItems) end
	for i = 1, 4 do
		UI.feed[i].Text = feedItems[i] or ""
		UI.feed[i].BackgroundTransparency = feedItems[i] and 0.35 or 1
	end
end

------------------------------------------------------------------ flight display
local flight = frame(gui, UDim2.new(0.5, -230, 1, -150), UDim2.new(0, 460, 0, 144), C.dark, 3, 0.2)
flight.Visible = false
UI.fSpeed = label(flight, UDim2.new(0, 10, 0, 4), UDim2.new(0, 200, 0, 28), "SPEED 0", 24, C.cyan, 4, Enum.TextXAlignment.Left)
UI.fAlt = label(flight, UDim2.new(0, 10, 0, 32), UDim2.new(0, 200, 0, 28), "ALTITUDE 0", 24, C.white, 4, Enum.TextXAlignment.Left)
label(flight, UDim2.new(0, 10, 0, 62), UDim2.new(0, 220, 0, 76), "W/S speed  A/D turn\nE up  Q down\nSpace = jump out", 14, rgb(190, 200, 220), 4, Enum.TextXAlignment.Left, false)
local ctl = { t = 0, s = 0 }
local function sendCtl() pcall(function() remote:FireServer("ctl", ctl.t, ctl.s) end) end
local function sendPitch(v) pcall(function() remote:FireServer("pitch", v) end) end
local function holdButton(text, x, y, down, up)
	local b = button(flight, UDim2.new(0, x, 0, y), UDim2.new(0, 70, 0, 40), text, C.blue, 4, 18)
	b.MouseButton1Down:connect(down)
	b.MouseButton1Up:connect(up)
	b.MouseLeave:connect(up)
	return b
end
holdButton("UP", 300, 6, function() sendPitch(1) end, function() sendPitch(0) end)
holdButton("DOWN", 300, 52, function() sendPitch(-1) end, function() sendPitch(0) end)
holdButton("FAST", 380, 6, function() ctl.t = 1 sendCtl() end, function() ctl.t = 0 sendCtl() end)
holdButton("SLOW", 380, 52, function() ctl.t = -1 sendCtl() end, function() ctl.t = 0 sendCtl() end)
holdButton("LEFT", 220, 98, function() ctl.s = -1 sendCtl() end, function() ctl.s = 0 sendCtl() end)
holdButton("RIGHT", 300, 98, function() ctl.s = 1 sendCtl() end, function() ctl.s = 0 sendCtl() end)

------------------------------------------------------------------ filling it in
function UI.refresh()
	local d = S
	local ls = player:FindFirstChild("leaderstats")
	local cash = ls and ls:FindFirstChild("Cash")
	UI.cash.Text = money(cash and cash.Value or 0)
	if not d.plots then return end
	-- airports list
	for i = 1, 10 do
		local owner = d.plots[i] or ""
		local row = UI.plotRows[i]
		row.label.Text = "Airport " .. i .. ":  " .. (owner == "" and "FREE" or owner)
		row.label.TextColor3 = owner == "" and C.green or (owner == player.Name and C.gold or C.white)
		row.btn.Text = owner == "" and "CLAIM" or (owner == player.Name and "HOME" or "VISIT")
	end
	if (d.plot or 0) == 0 then
		UI.income.Text = "Claim an airport to start!"
		UI.rating.Text = "press AIRPORTS"
		UI.progress.Text = "Airport 0%"
		UI.served.Text = ""
		UI.ticket.Text = ""
		setTopStars(0)
		return
	end
	UI.income.Text = "+" .. money(d.income or 0) .. "/s"
	local r = d.rating or 0
	setTopStars(r)
	UI.rating.Text = (d.nreviews or 0) > 0 and string.format("%.1f / 5 (%d reviews)", r, d.nreviews) or "no reviews yet"
	UI.served.Text = (d.served or 0) .. " passengers"
	UI.ticket.Text = "ticket " .. money(d.ticket or 0)
	local pct = math.floor(100 * (d.bought or 0) / math.max(1, d.total or 1))
	UI.progress.Text = "Airport " .. pct .. "%"
	UI.bar.Size = UDim2.new(pct / 100, 0, 1, 0)
	-- hire
	for i, row in ipairs(UI.hireRows) do
		local st = d.staff and d.staff[i]
		row.key = st and st.key
		if st then
			row.name.Text = st.name
			row.desc.Text = st.desc
			row.count.Text = st.n .. " / " .. st.cap
			if st.cap == 0 then
				row.btn.Text = "NEEDS " .. string.upper(st.need)
				row.btn.BackgroundColor3 = C.grey
				font(row.btn, 14)
			elseif st.n >= st.cap then
				row.btn.Text = "FULL"
				row.btn.BackgroundColor3 = C.grey
				font(row.btn, 18)
			else
				row.btn.Text = "HIRE " .. money(st.fee)
				row.btn.BackgroundColor3 = (cash and cash.Value >= st.fee) and C.green or C.red
				font(row.btn, 18)
			end
		end
	end
	-- ratings
	setBigStars(r)
	UI.bigRating.Text = string.format("%.1f / 5", r)
	for _, k in ipairs(CATS) do
		local v = d.cats and d.cats[k] or 0
		local row = UI.catRows[k]
		row.fill.Size = UDim2.new(v, 0, 1, 0)
		row.fill.BackgroundColor3 = v >= 0.7 and C.green or (v >= 0.35 and C.gold or C.red)
		row.tip.Text = v >= 0.95 and "Perfect!" or TIPS[k]
	end
	if d.report then
		UI.report.Text = string.format("Inspector: %.1f stars. Best: %s. Needs work: %s. Bonus %s", d.report.stars, d.report.best, d.report.worst, money(d.report.bonus))
	end
	for i = 1, 5 do
		local rv = d.reviews and d.reviews[i]
		UI.reviewLines[i].Text = rv and (string.rep("*", rv.stars) .. string.rep("-", 5 - rv.stars) .. "  " .. rv.name .. ": " .. rv.text) or ""
	end
	-- goals
	for i, row in ipairs(UI.phaseRows) do
		local ph = d.phases and d.phases[i]
		if ph then
			row.name.Text = i .. ". " .. ph.name
			row.fill.Size = UDim2.new(ph.b / math.max(1, ph.t), 0, 1, 0)
			row.fill.BackgroundColor3 = ph.b >= ph.t and C.green or C.purple
			row.n.Text = ph.b .. " / " .. ph.t
		end
	end
	for i = 1, 5 do
		local n = d.next and d.next[i]
		UI.nextLines[i].Text = n and (n.name .. "  -  " .. (n.price == 0 and "FREE" or money(n.price))) or ""
	end
	if (d.bought or 0) >= (d.total or 1) then UI.nextLines[1].Text = "Everything is built! Your airport is COMPLETE!" end
end

remote.OnClientEvent:connect(function(what, a, b)
	if what == "state" then
		S = a or {}
		UI.refresh()
	elseif what == "toast" then
		toast(tostring(a), b)
	elseif what == "review" and a then
		pushFeed(string.rep("*", a.stars) .. string.rep("-", 5 - a.stars) .. " " .. a.name .. ": " .. a.text)
	elseif what == "inspector" and a then
		toast(string.format("Inspector gave you %.1f stars! Bonus %s", a.stars, money(a.bonus)), "gold")
	end
end)

------------------------------------------------------------------ buttons and keys
UI.bHome.MouseButton1Click:connect(function()
	if (S.plot or 0) == 0 then showPanel("plots") else pcall(function() remote:FireServer("tp") end) end
end)
UI.bHire.MouseButton1Click:connect(function() showPanel("hire") end)
UI.bRate.MouseButton1Click:connect(function() showPanel("rate") end)
UI.bGoals.MouseButton1Click:connect(function() showPanel("goals") end)
UI.bPlots.MouseButton1Click:connect(function() showPanel("plots") end)
UI.bHelp.MouseButton1Click:connect(function() showPanel("help") end)
local hidden = false
UI.bHide.MouseButton1Click:connect(function()
	hidden = not hidden
	top.Visible = not hidden
	feed.Visible = not hidden
	for _, b in ipairs(side:GetChildren()) do if b ~= UI.bHide then b.Visible = not hidden end end
	for _, p in pairs(panels) do p.Visible = false end
	UI.bHide.Text = hidden and "SHOW UI" or "HIDE UI"
end)

pcall(function()
	local mouse = player:GetMouse()
	mouse.KeyDown:connect(function(k)
		k = string.lower(k)
		if k == "e" then sendPitch(1) elseif k == "q" then sendPitch(-1) end
	end)
	mouse.KeyUp:connect(function(k)
		k = string.lower(k)
		if k == "e" or k == "q" then sendPitch(0) end
	end)
end)

-- am I flying? (my character is in a PilotSeat)
local function myPlane()
	local char = player.Character
	local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
	if not torso then return nil end
	for _, a in ipairs(workspace:GetChildren()) do
		local planes = a.Name:sub(1, 7) == "Airport" and a:FindFirstChild("Planes")
		if planes then
			for _, m in ipairs(planes:GetChildren()) do
				local seat = m:FindFirstChild("PilotSeat")
				local w = seat and seat:FindFirstChild("SeatWeld")
				if w and w.Part1 == torso then return m end
			end
		end
	end
	return nil
end
spawn(function()
	while gui.Parent do
		local m = myPlane()
		flight.Visible = m ~= nil
		if m then
			local body = m:FindFirstChild("Body")
			if body then
				UI.fSpeed.Text = "SPEED " .. math.floor(body.Velocity.magnitude)
				UI.fAlt.Text = "ALTITUDE " .. math.floor(math.max(0, body.Position.y - 3))
			end
		end
		wait(0.2)
	end
end)

gui.Parent = pg
pcall(function() remote:FireServer("state") end)
spawn(function()
	local ls = player:WaitForChild("leaderstats")
	local cash = ls:WaitForChild("Cash")
	cash.Changed:connect(function() UI.cash.Text = money(cash.Value) end)
	UI.refresh()
end)
