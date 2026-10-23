-- StarterGui.HogClient: the HUD (timer, survivors left, what you're holding, which locks are still shut), big
-- announcements, the jumpscare when the Hog gets you, the red edges when it's close, and the bot Hog's walking
-- (the server says where it's going; this computer moves it smoothly and swings its arms and legs).
-- 2016-safe: no AnchorPoint/TweenService, FontSize instead of TextSize.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do wait() player = Players.LocalPlayer end
local pg = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("HogEvent")
local old = pg:FindFirstChild("HogUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "HogUI"

local function rgb(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local C = { dark = rgb(20, 12, 20), panel = rgb(40, 25, 40), white = rgb(255, 255, 255), gold = rgb(255, 210, 70),
	green = rgb(90, 220, 110), red = rgb(235, 60, 70), pink = rgb(255, 130, 170), blue = rgb(70, 150, 240), grey = rgb(170, 170, 170) }
local function frame(parent, pos, size, color, tr)
	local f = Instance.new("Frame")
	f.Position, f.Size = pos, size
	f.BackgroundColor3 = color or C.panel
	f.BackgroundTransparency = tr or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end
local function label(parent, pos, size, text, fs, color)
	local t = Instance.new("TextLabel")
	t.Position, t.Size = pos, size
	t.BackgroundTransparency = 1
	t.Text = text or ""
	t.TextColor3 = color or C.white
	t.TextStrokeTransparency = 0.4
	pcall(function() t.Font = Enum.Font.SourceSansBold end)
	-- only these sizes exist in 2016 (asking for another one silently leaves the text tiny)
	local best = 18
	for _, n in ipairs({ 8, 9, 10, 11, 12, 14, 18, 24, 28, 32, 36, 42, 48 }) do if n <= (fs or 18) then best = n end end
	pcall(function() t.FontSize = Enum.FontSize["Size" .. best] end)
	t.Parent = parent
	return t
end
local function button(parent, pos, size, text, color)
	local b = Instance.new("TextButton")
	b.Position, b.Size = pos, size
	b.BackgroundColor3 = color or C.blue
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = C.white
	pcall(function() b.Font = Enum.Font.SourceSansBold end)
	pcall(function() b.FontSize = Enum.FontSize.Size24 end)
	b.Parent = parent
	return b
end

------------------------------------------------------------------ HUD
local top = frame(gui, UDim2.new(0.5, -230, 0, 6), UDim2.new(0, 460, 0, 74), C.dark, 0.25)
local topTitle = label(top, UDim2.new(0, 0, 0, 2), UDim2.new(1, 0, 0, 40), "ESCAPE THE HOG", 36, C.pink)
local topSub = label(top, UDim2.new(0, 0, 0, 42), UDim2.new(1, 0, 0, 28), "", 24, C.white)
-- your coins / escapes
local mine = label(gui, UDim2.new(0, 10, 0.5, -90), UDim2.new(0, 200, 0, 60), "", 24, C.gold)
pcall(function() mine.TextXAlignment = Enum.TextXAlignment.Left end)
spawn(function()
	while true do
		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Coins") and ls:FindFirstChild("Escapes") then
			mine.Text = "COINS: " .. ls.Coins.Value .. "\nESCAPES: " .. ls.Escapes.Value
		end
		wait(0.5)
	end
end)
-- what you're holding (bottom middle)
local holdBox = frame(gui, UDim2.new(0.5, -170, 1, -120), UDim2.new(0, 340, 0, 46), C.dark, 0.25)
local holdText = label(holdBox, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "", 28, C.gold)
holdBox.Visible = false
-- the locks still to open (right)
local lockBox = frame(gui, UDim2.new(1, -290, 0, 100), UDim2.new(0, 280, 0, 40), C.dark, 0.3)
local lockTitle = label(lockBox, UDim2.new(0, 0, 0, 2), UDim2.new(1, 0, 0, 30), "TO ESCAPE", 24, C.pink)
local lockLines = {}
lockBox.Visible = false
-- big announcement
local big = label(gui, UDim2.new(0.5, -450, 0.22, 0), UDim2.new(0, 900, 0, 60), "", 48, C.pink)
local sub = label(gui, UDim2.new(0.5, -450, 0.22, 62), UDim2.new(0, 900, 0, 34), "", 24, C.white)
local bigUntil = 0
local function announce(a, b)
	big.Text, sub.Text = a or "", b or ""
	bigUntil = tick() + 4.5
end
-- toasts
local toasts = {}
local TOAST_COLORS = { green = C.green, red = C.red, gold = C.gold, white = C.white }
local function toast(text, color)
	local t = label(gui, UDim2.new(0.5, -350, 0, 0), UDim2.new(0, 700, 0, 30), text, 24, TOAST_COLORS[color] or C.white)
	table.insert(toasts, 1, { t = t, born = tick() })
	for i = #toasts, 1, -1 do
		local o = toasts[i]
		if i > 5 or tick() - o.born > 6 then o.t:Destroy() table.remove(toasts, i) end
	end
	for i, o in ipairs(toasts) do o.t.Position = UDim2.new(0.5, -350, 0, 150 + (i - 1) * 30) end
end
-- red edges when the Hog is close
local edges = {}
for i, d in ipairs({ { UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 60) }, { UDim2.new(0, 0, 1, -60), UDim2.new(1, 0, 0, 60) },
	{ UDim2.new(0, 0, 0, 0), UDim2.new(0, 60, 1, 0) }, { UDim2.new(1, -60, 0, 0), UDim2.new(0, 60, 1, 0) } }) do
	edges[i] = frame(gui, d[1], d[2], C.red, 1)
end
-- the Hog player's trap button (handy on a Chromebook)
local trapB = button(gui, UDim2.new(1, -190, 1, -190), UDim2.new(0, 170, 0, 56), "SET TRAP", C.red)
trapB.Visible = false
trapB.MouseButton1Click:connect(function() remote:FireServer("trap") end)
-- help
local helpB = button(gui, UDim2.new(0, 10, 0.5, -20), UDim2.new(0, 56, 0, 56), "?", C.panel)
pcall(function() helpB.FontSize = Enum.FontSize.Size48 end)
local function showHowTo()
	if gui:FindFirstChild("HowTo") then return end
	local f = frame(gui, UDim2.new(0.5, -380, 0.5, -240), UDim2.new(0, 760, 0, 480), C.dark, 0.06)
	f.Name = "HowTo"
	f.ZIndex = 5
	local title = label(f, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 44), "ESCAPE THE HOG - HOW TO PLAY", 36, C.pink)
	title.ZIndex = 6
	local body = label(f, UDim2.new(0, 28, 0, 66), UDim2.new(1, -56, 0, 330),
		"1.  Press PLAY, then vote for the MAP and the HOG (a bot, or one of the players).\n\n" ..
		"2.  You're locked inside. After 15 seconds the Hog gets out of its pen and hunts you.\n\n" ..
		"3.  Find ITEMS (keys, a hammer, a wrench, a fuse...). WALK OVER one to pick it up - only ONE at a time.\n\n" ..
		"4.  Walk up to a locked door or a lock on the EXIT holding the right item to use it. The list on the right shows what's left.\n\n" ..
		"5.  Open every lock on the exit and run out! Escaping = +50 Coins. Caught = out for the round. Watch out for traps!", 24, C.white)
	body.TextWrapped = true
	pcall(function() body.TextXAlignment = Enum.TextXAlignment.Left body.TextYAlignment = Enum.TextYAlignment.Top end)
	body.ZIndex = 6
	local go = button(f, UDim2.new(0.5, -110, 1, -64), UDim2.new(0, 220, 0, 48), "LET'S GO!", C.green)
	go.ZIndex = 6
	go.MouseButton1Click:connect(function() f:Destroy() end)
end
helpB.MouseButton1Click:connect(showHowTo)

------------------------------------------------------------------ the jumpscare
local function jumpscare()
	local f = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), rgb(0, 0, 0), 0)
	f.ZIndex = 8
	local face = frame(f, UDim2.new(0.5, -260, 0.5, -230), UDim2.new(0, 520, 0, 460), rgb(255, 150, 185), 0)
	face.ZIndex = 9
	local function part(x, y, w, h, color) local p = frame(face, UDim2.new(0, x, 0, y), UDim2.new(0, w, 0, h), color, 0) p.ZIndex = 10 return p end
	part(-40, -60, 110, 130, rgb(240, 120, 160))          -- ears
	part(450, -60, 110, 130, rgb(240, 120, 160))
	part(90, 90, 120, 110, C.white)                         -- eyes
	part(310, 90, 120, 110, C.white)
	part(130, 120, 50, 55, C.red)
	part(350, 120, 50, 55, C.red)
	part(70, 60, 150, 22, rgb(0, 0, 0))                     -- angry brows
	part(300, 60, 150, 22, rgb(0, 0, 0))
	part(170, 220, 180, 120, rgb(240, 110, 150))            -- snout
	part(205, 255, 35, 50, rgb(60, 0, 20))
	part(280, 255, 35, 50, rgb(60, 0, 20))
	part(110, 370, 300, 50, rgb(60, 0, 10))                 -- mouth
	for i = 0, 5 do part(120 + i * 48, 370, 26, 22, C.white) end
	local t = label(f, UDim2.new(0.5, -400, 1, -110), UDim2.new(0, 800, 0, 60), "YOU WERE CAUGHT!", 48, C.red)
	t.ZIndex = 10
	spawn(function()
		local t0 = tick()
		while tick() - t0 < 1.8 do
			local k = 1 + (tick() - t0) * 0.6
			face.Size = UDim2.new(0, 520 * k, 0, 460 * k)
			face.Position = UDim2.new(0.5, -260 * k + math.random(-14, 14), 0.5, -230 * k + math.random(-14, 14))
			f.BackgroundColor3 = (math.floor((tick() - t0) * 12) % 2 == 0) and rgb(120, 0, 0) or rgb(0, 0, 0)
			wait()
		end
		f:Destroy()
	end)
end

------------------------------------------------------------------ THE MENU (the lobby is just this screen, like Piggy)
-- behind it the camera looks down a dark hallway at the Hog. PLAY -> the vote screen -> the round.
local screen = "menu"            -- "menu", "vote" or "game"
local function font(o, name) pcall(function() o.Font = Enum.Font[name] end) end
local menu = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), rgb(0, 0, 0), 0.55)
menu.ZIndex = 2
local logo = label(menu, UDim2.new(0.5, -360, 0, 30), UDim2.new(0, 720, 0, 110), "ESCAPE THE HOG", 48, C.white)
logo.TextScaled = true
logo.TextStrokeTransparency = 0
logo.TextStrokeColor3 = rgb(60, 0, 20)
logo.ZIndex = 3
font(logo, "Antique")
-- little pig ears on the logo
for _, x in ipairs({ -330, -300 }) do
	local ear = frame(menu, UDim2.new(0.5, x, 0, 22), UDim2.new(0, 26, 0, 26), C.pink, 0)
	ear.ZIndex = 3
	pcall(function() ear.Rotation = 45 end)
end
local function menuButton(x, y, w, h, text, border, textColor, fs)
	local b = Instance.new("TextButton")
	b.Position, b.Size = UDim2.new(0.5, x, 0, y), UDim2.new(0, w, 0, h)
	b.BackgroundColor3 = rgb(10, 12, 14)
	b.BackgroundTransparency = 0.15
	b.BorderColor3 = border
	b.BorderSizePixel = 3
	b.Text = text
	b.TextColor3 = textColor or border
	b.TextStrokeTransparency = 0.6
	font(b, "Cartoon")
	pcall(function() b.FontSize = Enum.FontSize["Size" .. (fs or 24)] end)
	b.ZIndex = 3
	b.Parent = menu
	return b
end
local playB = menuButton(-215, 270, 430, 70, ">  PLAY", rgb(70, 200, 110), rgb(90, 240, 120), 48)
playB.BackgroundColor3 = rgb(15, 45, 25)
-- four buttons under PLAY, each with a little picture made of boxes
local function icon(b, x, y, w, h, color, rot)
	local f = frame(b, UDim2.new(0.5, x, 0, y), UDim2.new(0, w, 0, h), color, 0)
	f.ZIndex = 4
	if rot then pcall(function() f.Rotation = rot end) end
	return f
end
local function smallButton(i, text, border)
	local b = menuButton(-215 + (i - 1) * 110, 355, 100, 100, "", border)
	local t = label(b, UDim2.new(0, 0, 1, -28), UDim2.new(1, 0, 0, 26), text, 18, border)
	t.ZIndex = 4
	font(t, "Cartoon")
	return b
end
local itemsB = smallButton(1, "ITEMS", rgb(220, 50, 60))
icon(itemsB, -26, 18, 22, 22, C.gold) icon(itemsB, -21, 23, 12, 12, rgb(10, 12, 14)) icon(itemsB, -6, 26, 32, 6, C.gold) icon(itemsB, 16, 30, 5, 10, C.gold)
local mapsB = smallButton(2, "MAPS", rgb(50, 90, 230))
icon(mapsB, -18, 34, 36, 26, rgb(210, 180, 120)) icon(mapsB, -16, 18, 32, 32, rgb(170, 40, 40), 45) icon(mapsB, -6, 44, 12, 16, rgb(90, 50, 20))
local helpM = smallButton(3, "HOW TO", rgb(170, 60, 220))
local q = label(helpM, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 60), "?", 48, rgb(200, 110, 255)) q.ZIndex = 4 font(q, "Cartoon")
local statsB = smallButton(4, "STATS", rgb(230, 70, 150))
icon(statsB, -20, 16, 40, 40, C.gold, 45) icon(statsB, -12, 24, 24, 24, rgb(255, 235, 120), 45)
local credit = label(menu, UDim2.new(0.5, -300, 1, -40), UDim2.new(0, 600, 0, 30), "Don't get caught...", 24, rgb(200, 120, 140))
credit.ZIndex = 3
font(credit, "Antique")
-- info panels
local function infoPanel(title, text, h)
	local old = gui:FindFirstChild("Info")
	if old then old:Destroy() end
	local f = frame(gui, UDim2.new(0.5, -380, 0.5, -(h or 420) / 2), UDim2.new(0, 760, 0, h or 420), C.dark, 0.06)
	f.Name = "Info"
	f.ZIndex = 6
	f.BorderSizePixel = 3
	f.BorderColor3 = C.pink
	local t = label(f, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 44), title, 36, C.pink) t.ZIndex = 7 font(t, "Cartoon")
	local body = label(f, UDim2.new(0, 28, 0, 64), UDim2.new(1, -56, 1, -130), text, 24, C.white)
	body.TextWrapped = true
	body.ZIndex = 7
	pcall(function() body.TextXAlignment = Enum.TextXAlignment.Left body.TextYAlignment = Enum.TextYAlignment.Top end)
	local close = button(f, UDim2.new(0.5, -90, 1, -58), UDim2.new(0, 180, 0, 44), "CLOSE", C.red)
	close.ZIndex = 7
	close.MouseButton1Click:connect(function() f:Destroy() end)
	return f
end
itemsB.MouseButton1Click:connect(function()
	infoPanel("ITEMS", "Walk over an item to pick it up (or click it). You can only hold ONE - click another to swap.\n" ..
		"Walk up to a lock holding the right item and it's used.\n\n" ..
		"RED KEY - opens the Red Door          BLUE KEY - opens the Blue Door\n" ..
		"HAMMER - smashes the Boards on the exit\n" ..
		"GOLD KEY - opens the Padlock on the exit\n" ..
		"WRENCH - undoes the Bolt (Hog Manor)     FUSE - goes in the Fuse Box (School)", 440)
end)
mapsB.MouseButton1Click:connect(function()
	infoPanel("MAPS", "HOG MANOR - a creepy old house: bedroom, bathroom, kitchen, pantry, garage, living room, dining room " ..
		"and a dark cellar. The Hog sleeps in its pen behind the pantry.\n\n" ..
		"SCHOOL - classrooms, the science lab, the library, the cafeteria, the gym and the principal's office. " ..
		"The Hog hides in the janitor's closet.\n\nVote for the map after you press PLAY!", 420)
end)
statsB.MouseButton1Click:connect(function()
	local ls = player:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("Coins")
	local e = ls and ls:FindFirstChild("Escapes")
	infoPanel("YOUR STATS", "COINS: " .. (c and c.Value or 0) .. "\n\nESCAPES: " .. (e and e.Value or 0) ..
		"\n\nEscape = +50 Coins.  Every lock you open = +5.\nAs the Hog: +10 for each catch, +40 if nobody escapes.", 380)
end)

-- the vote screen (after PLAY)
local voteF = frame(gui, UDim2.new(0.5, -330, 0.5, -170), UDim2.new(0, 660, 0, 380), rgb(10, 8, 12), 0.2)
voteF.BorderSizePixel = 3
voteF.BorderColor3 = C.pink
voteF.Visible = false
local vt = label(voteF, UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 36), "VOTE", 36, C.pink) font(vt, "Cartoon")
local voteCards = { map = {}, mode = {} }
local myVote = {}
local VOTE_NAMES = { map = { "Hog Manor", "School" }, mode = { "Bot Hog", "Player Hog" } }
for row, kind in ipairs({ "map", "mode" }) do
	local y = 52 + (row - 1) * 140
	local h = label(voteF, UDim2.new(0, 0, 0, y), UDim2.new(1, 0, 0, 28), kind == "map" and "THE MAP" or "THE HOG", 24, C.white)
	font(h, "Cartoon")
	for i, name in ipairs(VOTE_NAMES[kind]) do
		local b = button(voteF, UDim2.new(0.5, -310 + (i - 1) * 320, 0, y + 32), UDim2.new(0, 300, 0, 96), name .. "\n0 votes",
			kind == "map" and (i == 1 and rgb(150, 70, 30) or rgb(40, 80, 170)) or (i == 1 and rgb(40, 130, 60) or rgb(170, 50, 110)))
		b.BorderColor3 = C.gold
		pcall(function() b.FontSize = Enum.FontSize.Size28 end)
		font(b, "Cartoon")
		b.MouseButton1Click:connect(function()
			myVote[kind] = name
			for j, o in ipairs(voteCards[kind]) do o.BorderSizePixel = (j == i) and 4 or 0 end
			remote:FireServer("vote", kind, name)
		end)
		voteCards[kind][i] = b
	end
end
local lastText = label(voteF, UDim2.new(0, 10, 1, -44), UDim2.new(1, -20, 0, 36), "", 18, C.grey)
lastText.TextWrapped = true
local menuB = button(gui, UDim2.new(0, 10, 1, -70), UDim2.new(0, 120, 0, 50), "MENU", C.panel)
menuB.Visible = false
font(menuB, "Cartoon")
local function setScreen(s)
	screen = s
	menu.Visible = s == "menu"
	voteF.Visible = s == "vote"
	menuB.Visible = s == "vote"
	top.Visible = s ~= "menu"
	helpB.Visible = s == "game"
	mine.Visible = s ~= "menu"
	if s ~= "game" then holdBox.Visible = false lockBox.Visible = false trapB.Visible = false end
end
playB.MouseButton1Click:connect(function()
	remote:FireServer("play")
	setScreen("vote")
end)
menuB.MouseButton1Click:connect(function()
	remote:FireServer("menu")
	setScreen("menu")
end)
helpM.MouseButton1Click:connect(showHowTo)
setScreen("menu")

------------------------------------------------------------------ messages from the server
local role = nil
local hogPlayerName = nil      -- (Player Hog rounds: the red edges warn you about them too)
remote.OnClientEvent:connect(function(what, a, b, c, d, e, f, g)
	if what == "status" then
		local phase, left, alive, mapName, mode, hogName = a, b, c, d, e, f
		hogPlayerName = (mode == "Player Hog" and phase ~= "lobby") and hogName or nil
		local mm, ss = math.floor(left / 60), left % 60
		local clock = mm .. ":" .. (ss < 10 and "0" or "") .. ss
		if phase == "lobby" then
			if (g or 0) == 0 then
				topTitle.Text = "WAITING FOR PLAYERS..."
				topSub.Text = "Press PLAY to join the next round"
			else
				topTitle.Text = "NEXT ROUND IN " .. left
				topSub.Text = g .. (g == 1 and " player" or " players") .. " ready - vote for the map and the Hog!"
			end
		elseif screen == "vote" and phase ~= "results" then
			topTitle.Text = "ROUND IN PROGRESS"
			topSub.Text = mapName .. "  |  SURVIVORS LEFT: " .. alive .. "  |  you're in the next one"
		elseif phase == "release" then
			topTitle.Text = "THE HOG GETS OUT IN " .. left
			topSub.Text = mapName .. "  |  " .. mode .. "  |  SURVIVORS: " .. alive
		elseif phase == "hunt" then
			topTitle.Text = "TIME LEFT " .. clock
			topSub.Text = mapName .. "  |  " .. (mode == "Player Hog" and ("HOG: " .. hogName) or "BOT HOG") .. "  |  SURVIVORS: " .. alive
		else
			topTitle.Text = "ROUND OVER"
			topSub.Text = ""
		end
	elseif what == "role" then
		role = a
		trapB.Visible = role == "hog"
		holdBox.Visible = role == "survivor"
		if role == "survivor" then holdText.Text = "HOLDING: nothing" end
		if not role then holdBox.Visible = false end
		if role then setScreen("game") elseif screen == "game" then setScreen("vote") end
		trapB.Visible = role == "hog"
		holdBox.Visible = role == "survivor"
	elseif what == "hold" then
		holdText.Text = "HOLDING: " .. (a or "nothing")
	elseif what == "locks" then
		for _, l in ipairs(lockLines) do l:Destroy() end
		lockLines = {}
		local list = a or {}
		lockBox.Visible = #list > 0 and screen == "game"
		local y = 34
		local function line(text, color)
			local t = label(lockBox, UDim2.new(0, 10, 0, y), UDim2.new(1, -20, 0, 26), text, 18, color)
			pcall(function() t.TextXAlignment = Enum.TextXAlignment.Left end)
			table.insert(lockLines, t)
			y = y + 26
		end
		for _, L in ipairs(list) do if not L[4] then line((L[3] and "[OPEN] " or "[  ] ") .. L[1] .. "  <- " .. L[2], L[3] and C.green or C.white) end end
		line("EXIT:", C.gold)
		for _, L in ipairs(list) do if L[4] then line((L[3] and "[OPEN] " or "[  ] ") .. L[1] .. "  <- " .. L[2], L[3] and C.green or C.white) end end
		lockBox.Size = UDim2.new(0, 280, 0, y + 8)
	elseif what == "big" then
		announce(a, b)
	elseif what == "toast" then
		toast(a, b)
	elseif what == "caught" then
		jumpscare()
	elseif what == "howto" then
		showHowTo()
	elseif what == "votes" then
		for _, kind in ipairs({ "map", "mode" }) do
			local counts = kind == "map" and a or b
			for i, card in ipairs(voteCards[kind]) do
				local n = counts and counts[i] or 0
				card.Text = VOTE_NAMES[kind][i] .. "\n" .. n .. (n == 1 and " vote" or " votes")
			end
		end
	elseif what == "last" then
		lastText.Text = (a or ""):gsub("\n+", "  ")
	end
end)
gui.Parent = pg

------------------------------------------------------------------ the bot Hog walks (smoothly, on this computer)
local hogs = {}       -- model -> state
local function track(m)
	local mv = m:FindFirstChild("Move")
	if not mv or hogs[m] then return end
	local parts = {}
	for _, d in ipairs(HOG_PARTS) do parts[d[1]] = m:FindFirstChild(d[1]) end
	local root = m:FindFirstChild("Root")
	local p0 = root and root.Position or Vector3.new()
	local S = { mv = mv, parts = parts, root = root, pos = Vector3.new(p0.X, 0, p0.Z), goal = Vector3.new(p0.X, 0, p0.Z), speed = 0,
		look = Vector3.new(0, 0, -1), phase = 0, smash = 0 }
	local function read()
		local x, z, gx, gz, sp, what = mv.Value:match("^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+)")
		if not x then return end
		local at = Vector3.new(tonumber(x), 0, tonumber(z))
		S.goal, S.speed = Vector3.new(tonumber(gx), 0, tonumber(gz)), tonumber(sp) or 0
		-- way off from where the server has it (just spawned, or this computer fell behind): jump there
		if what == "s" or (S.pos - at).magnitude > 12 then S.pos = at end
		if what == "e" then S.smash = 1.2 end
	end
	read()
	mv.Changed:connect(read)
	hogs[m] = S
end
local function findHogs()
	local w = workspace:FindFirstChild("Hog World")
	local map = w and w:FindFirstChild("Map")
	if map then for _, o in ipairs(map:GetChildren()) do if o.Name == "Hog" then track(o) end end end
	for m in pairs(hogs) do if not m.Parent then hogs[m] = nil end end
end
spawn(function() while true do pcall(findHogs) wait(1) end end)
local RunService = game:GetService("RunService")
local lastT = tick()
RunService.RenderStepped:connect(function()
	local now = tick()
	local dt = math.min(0.1, now - lastT)
	lastT = now
	if tick() > bigUntil then big.Text, sub.Text = "", "" end
	local cam = workspace.CurrentCamera
	if cam then
		if screen ~= "game" then
			local w = workspace:FindFirstChild("Hog World")
			local sc = w and w:FindFirstChild("MenuScene")
			local cp, lp = sc and sc:FindFirstChild("MenuCam"), sc and sc:FindFirstChild("MenuLook")
			if cp and lp then
				if cam.CameraType ~= Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Scriptable end
				local sway = Vector3.new(math.sin(now * 0.4) * 0.6, math.sin(now * 0.7) * 0.25, 0)
				cam.CFrame = CFrame.new(cp.Position + sway, lp.Position)
			end
		elseif cam.CameraType == Enum.CameraType.Scriptable then
			cam.CameraType = Enum.CameraType.Custom
			local h = player.Character and player.Character:FindFirstChild("Humanoid")
			if h then cam.CameraSubject = h end
		end
	end
	local closest = 1e9
	local me = player.Character and (player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("HumanoidRootPart"))
	for m, S in pairs(hogs) do
		if m.Parent then
			local d = S.goal - S.pos
			local dist = d.magnitude
			local moved = 0
			if dist > 0.05 then
				local step = math.min(dist, S.speed * 1.05 * dt)
				S.pos = S.pos + d.unit * step
				moved = step
				S.look = d.unit
			end
			S.phase = S.phase + moved * 0.55
			local swing = moved > 0 and math.sin(S.phase) * 0.8 or 0
			S.smash = math.max(0, S.smash - dt)
			local p = S.pos + Vector3.new(0, HOG_UP, 0)
			local rootCF = CFrame.new(p, p + S.look)
			local pose = HogPose(rootCF, swing, S.smash > 0 and math.sin(math.min(1, S.smash) * math.pi) or 0)
			for name, part in pairs(S.parts) do
				if part and part.Parent then
					local cf = pose[name]
					-- (the snout's cylinder is turned to point forwards)
					if cf then part.CFrame = cf end
				end
			end
			if S.root then S.root.CFrame = rootCF end
			if me then closest = math.min(closest, (me.Position - p).magnitude) end
		end
	end
	if me and hogPlayerName and hogPlayerName ~= player.Name then
		local hp = Players:FindFirstChild(hogPlayerName)
		local ht = hp and hp.Character and (hp.Character:FindFirstChild("Torso") or hp.Character:FindFirstChild("HumanoidRootPart"))
		if ht then closest = math.min(closest, (me.Position - ht.Position).magnitude) end
	end
	-- red edges: the closer the Hog, the redder
	local k = closest < 40 and (1 - closest / 40) or 0
	local beat = 0.5 + 0.5 * math.sin(now * (6 + k * 8))
	for _, e in ipairs(edges) do e.BackgroundTransparency = 1 - k * (0.35 + 0.35 * beat) end
end)
