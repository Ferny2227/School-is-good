-- StarterGui.HogClient: everything on the screen.
--  * the MENU (the lobby is just this screen, like Piggy) in front of a dark hallway with the Hog, then the HOG VOTING
--    screen (6 modes, 2 maps) after PLAY
--  * in the round: the timer, your role, the item in your hands, CROUCH (C) and SET TRAP buttons, big announcements,
--    the jumpscare, red screen edges when a Hog is close, flickering lights
--  * clicking: point at an item or a lock and click; this computer tells the server what you clicked
--  * the bot Hogs walk smoothly on this computer (the server says where they're going)
-- 2016-safe: no AnchorPoint/TweenService/UICorner, FontSize instead of TextSize.
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
local screen = "menu"            -- "menu", "vote" or "game"
local role = nil                 -- "survivor", "hog", "traitor" or nil

local function rgb(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local C = { dark = rgb(14, 10, 16), panel = rgb(32, 22, 34), white = rgb(255, 255, 255), gold = rgb(255, 210, 70),
	green = rgb(90, 230, 120), red = rgb(235, 55, 65), pink = rgb(255, 120, 165), blue = rgb(70, 150, 240), grey = rgb(170, 170, 175),
	purple = rgb(175, 90, 235), skin = rgb(240, 150, 175), black = rgb(0, 0, 0) }
local function font(o, name) pcall(function() o.Font = Enum.Font[name] end) end
local function frame(parent, pos, size, color, tr, border, bsize)
	local f = Instance.new("Frame")
	f.Position, f.Size = pos, size
	f.BackgroundColor3 = color or C.panel
	f.BackgroundTransparency = tr or 0
	f.BorderSizePixel = border and (bsize or 3) or 0
	if border then f.BorderColor3 = border end
	f.Parent = parent
	return f
end
local function label(parent, pos, size, text, fs, color, fnt)
	local t = Instance.new("TextLabel")
	t.Position, t.Size = pos, size
	t.BackgroundTransparency = 1
	t.Text = text or ""
	t.TextColor3 = color or C.white
	t.TextStrokeTransparency = 0.3
	font(t, fnt or "SourceSansBold")
	-- only these sizes exist in 2016 (asking for another one silently leaves the text tiny)
	local best = 18
	for _, n in ipairs({ 8, 9, 10, 11, 12, 14, 18, 24, 28, 32, 36, 42, 48 }) do if n <= (fs or 18) then best = n end end
	pcall(function() t.FontSize = Enum.FontSize["Size" .. best] end)
	t.Parent = parent
	return t
end
local function button(parent, pos, size, text, color, border, fs)
	local b = Instance.new("TextButton")
	b.Position, b.Size = pos, size
	b.BackgroundColor3 = color or C.panel
	b.BorderSizePixel = border and 3 or 0
	if border then b.BorderColor3 = border end
	b.Text = text
	b.TextColor3 = C.white
	b.TextStrokeTransparency = 0.4
	font(b, "Cartoon")
	pcall(function() b.FontSize = Enum.FontSize["Size" .. (fs or 24)] end)
	b.Parent = parent
	return b
end
-- put a whole panel (and everything in it) on one layer
local function z(o, n) o.ZIndex = n for _, c in ipairs(o:GetChildren()) do if c:IsA("GuiObject") then z(c, n) end end return o end
-- a little Hog face made of boxes (for the vote cards and the jumpscare)
local function face(parent, x, y, s, skin, eye, extra)
	local root = frame(parent, UDim2.new(0, x, 0, y), UDim2.new(0, s, 0, s), skin, 0)
	local function box(px, py, w, h, c) return frame(root, UDim2.new(0, s * px, 0, s * py), UDim2.new(0, s * w, 0, s * h), c, 0) end
	box(-0.12, -0.14, 0.3, 0.3, skin) box(0.82, -0.14, 0.3, 0.3, skin)                         -- ears
	box(0.18, 0.26, 0.2, 0.2, C.white) box(0.62, 0.26, 0.2, 0.2, C.white)                      -- eyes
	box(0.23, 0.3, 0.1, 0.12, eye or C.black) box(0.67, 0.3, 0.1, 0.12, eye or C.black)
	box(0.14, 0.18, 0.3, 0.06, C.black) box(0.56, 0.18, 0.3, 0.06, C.black)                    -- angry brows
	box(0.3, 0.52, 0.4, 0.26, Color3.new(skin.r * 0.85, skin.g * 0.7, skin.b * 0.75))          -- snout
	box(0.37, 0.59, 0.08, 0.12, C.black) box(0.55, 0.59, 0.08, 0.12, C.black)
	box(0.2, 0.86, 0.6, 0.08, rgb(60, 0, 15))                                                  -- mouth
	if extra == "bat" then
		local bat = box(0.95, 0.1, 0.14, 0.95, rgb(110, 65, 30))
		pcall(function() bat.Rotation = 25 end)
	end
	return root
end

------------------------------------------------------------------ IN THE ROUND: the HUD
local hud = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.black, 1)
-- the timer (top middle)
local timerBox = frame(hud, UDim2.new(0.5, -150, 0, 8), UDim2.new(0, 300, 0, 66), C.dark, 0.15, C.pink)
local timerText = label(timerBox, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 44), "", 42, C.white, "Cartoon")
local timerSub = label(timerBox, UDim2.new(0, 0, 0, 44), UDim2.new(1, 0, 0, 20), "", 14, C.grey)
local infoBar = label(hud, UDim2.new(0.5, -300, 0, 78), UDim2.new(0, 600, 0, 24), "", 18, C.grey)
-- your role (top left) and coins
local roleBox = frame(hud, UDim2.new(0, 10, 0, 10), UDim2.new(0, 170, 0, 40), C.dark, 0.15, C.green)
local roleText = label(roleBox, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "SURVIVOR", 24, C.green, "Cartoon")
local coinBox = frame(hud, UDim2.new(0, 10, 0, 58), UDim2.new(0, 170, 0, 34), C.dark, 0.3)
local coinIcon = frame(coinBox, UDim2.new(0, 10, 0, 7), UDim2.new(0, 20, 0, 20), C.gold, 0)
pcall(function() coinIcon.Rotation = 45 end)
local coinText = label(coinBox, UDim2.new(0, 38, 0, 0), UDim2.new(1, -42, 1, 0), "0", 24, C.gold, "Cartoon")
pcall(function() coinText.TextXAlignment = Enum.TextXAlignment.Left end)
-- the item in your hands (bottom middle)
local slot = frame(hud, UDim2.new(0.5, -45, 1, -154), UDim2.new(0, 90, 0, 90), C.dark, 0.15, C.gold)
local slotIcon = frame(slot, UDim2.new(0.5, -22, 0.5, -22), UDim2.new(0, 44, 0, 44), C.gold, 0, C.white, 2)
slotIcon.Visible = false
local slotName = label(hud, UDim2.new(0.5, -150, 1, -60), UDim2.new(0, 300, 0, 28), "EMPTY HANDS", 24, C.grey, "Cartoon")
local ITEM_COLOR = { ["Keycard"] = rgb(120, 230, 90), ["Red Key"] = rgb(220, 30, 30), ["Blue Key"] = rgb(30, 70, 230), ["Gold Key"] = rgb(240, 200, 60),
	["Hammer"] = rgb(140, 90, 50), ["Wrench"] = rgb(170, 170, 175), ["Fuse"] = rgb(255, 245, 90), ["Stun Gun"] = rgb(30, 30, 30) }
-- buttons (bottom right)
local crouchB = button(hud, UDim2.new(1, -190, 1, -140), UDim2.new(0, 170, 0, 56), "CROUCH  [C]", rgb(60, 30, 80), C.purple, 24)
local trapB = button(hud, UDim2.new(1, -190, 1, -204), UDim2.new(0, 170, 0, 56), "SET TRAP", rgb(80, 20, 25), C.red, 24)
local helpB = button(hud, UDim2.new(0, 10, 0, 100), UDim2.new(0, 44, 0, 44), "?", C.dark, C.purple, 36)
-- what your mouse is pointing at
local tip = label(gui, UDim2.new(0, 0, 0, 0), UDim2.new(0, 200, 0, 26), "", 24, C.gold, "Cartoon")
tip.TextStrokeTransparency = 0
tip.Visible = false
local sel = Instance.new("SelectionBox")
sel.Name = "HogSelect"
pcall(function() sel.Color3 = Color3.new(1, 0.85, 0.3) end)
pcall(function() sel.LineThickness = 0.06 end)
sel.Parent = gui
-- big announcement
local big = label(gui, UDim2.new(0.5, -450, 0.24, 0), UDim2.new(0, 900, 0, 64), "", 48, C.pink, "Cartoon")
big.TextStrokeTransparency = 0
big.TextStrokeColor3 = rgb(60, 0, 20)
local sub = label(gui, UDim2.new(0.5, -450, 0.24, 66), UDim2.new(0, 900, 0, 34), "", 24, C.white)
local bigUntil = 0
local function announce(a, b)
	big.Text, sub.Text = a or "", b or ""
	bigUntil = tick() + 4.5
end
-- toasts
local toasts = {}
local TOAST_COLORS = { green = C.green, red = C.red, gold = C.gold, white = C.white }
local function toast(text, color)
	local t = label(gui, UDim2.new(0.5, -350, 0, 0), UDim2.new(0, 700, 0, 30), text, 24, TOAST_COLORS[color] or C.white, "Cartoon")
	t.TextStrokeTransparency = 0
	table.insert(toasts, 1, { t = t, born = tick() })
	for i = #toasts, 1, -1 do
		local o = toasts[i]
		if i > 5 or tick() - o.born > 6 then o.t:Destroy() table.remove(toasts, i) end
	end
	for i, o in ipairs(toasts) do o.t.Position = UDim2.new(0.5, -350, 0, 160 + (i - 1) * 30) end
end
-- red edges when a Hog is close
local edges = {}
for i, d in ipairs({ { UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 70) }, { UDim2.new(0, 0, 1, -70), UDim2.new(1, 0, 0, 70) },
	{ UDim2.new(0, 0, 0, 0), UDim2.new(0, 70, 1, 0) }, { UDim2.new(1, -70, 0, 0), UDim2.new(0, 70, 1, 0) } }) do
	edges[i] = frame(gui, d[1], d[2], C.red, 1)
end
local function showHowTo()
	if gui:FindFirstChild("Info") then gui.Info:Destroy() end
	local f = frame(gui, UDim2.new(0.5, -380, 0.5, -270), UDim2.new(0, 760, 0, 540), C.dark, 0.04, C.purple)
	f.Name = "Info"
	label(f, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 44), "HOW TO PLAY", 42, C.purple, "Cartoon")
	local body = label(f, UDim2.new(0, 28, 0, 62), UDim2.new(1, -56, 0, 400),
		"1.  Press PLAY and vote for the HOG mode and the MAP.\n\n" ..
		"2.  You're locked inside. After 15 seconds the Hog gets out and hunts you.\n\n" ..
		"3.  Find the items hidden around the map. CLICK an item to pick it up - you can only hold ONE.\n\n" ..
		"4.  Figure out where each item goes and CLICK it there. Find the CODE NOTE for the keypad. Then ESCAPE!\n\n" ..
		"5.  Press C (or CROUCH) to sneak. Crouch and click a VENT grate in the floor to crawl to another room.\n\n" ..
		"6.  Found the STUN GUN? Click at the Hog to freeze it for 20 seconds (2 shots).", 24, C.white)
	body.TextWrapped = true
	pcall(function() body.TextXAlignment = Enum.TextXAlignment.Left body.TextYAlignment = Enum.TextYAlignment.Top end)
	local go = button(f, UDim2.new(0.5, -110, 1, -64), UDim2.new(0, 220, 0, 48), "GOT IT", rgb(20, 60, 30), C.green, 28)
	go.MouseButton1Click:connect(function() f:Destroy() end)
	z(f, 7)
end
helpB.MouseButton1Click:connect(showHowTo)

------------------------------------------------------------------ the jumpscare
local function sound(id, vol, pitch)
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = id
		snd.Volume = vol or 0.7
		pcall(function() snd.Pitch = pitch or 1 end)
		snd.Parent = gui
		snd:Play()
		game:GetService("Debris"):AddItem(snd, 4)
	end)
end
local function jumpscare()
	sound("rbxasset://sounds/uuhhh.mp3", 1, 0.6)
	sound("rbxasset://sounds/electronicpingshort.wav", 1, 0.4)
	local f = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.black, 0)
	local fc = face(f, 0, 0, 460, C.skin, C.red, nil)
	local t = label(f, UDim2.new(0.5, -400, 1, -110), UDim2.new(0, 800, 0, 60), "CAUGHT!", 48, C.red, "Cartoon")
	t.TextStrokeTransparency = 0
	z(f, 9)
	spawn(function()
		local t0 = tick()
		while tick() - t0 < 1.8 do
			fc.Position = UDim2.new(0.5, -230 + math.random(-18, 18), 0.5, -250 + math.random(-18, 18))
			f.BackgroundColor3 = (math.floor((tick() - t0) * 12) % 2 == 0) and rgb(110, 0, 0) or C.black
			wait()
		end
		f:Destroy()
	end)
end

------------------------------------------------------------------ THE MENU
local menu = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.black, 0.5)
local logo = label(menu, UDim2.new(0.5, -380, 0, 26), UDim2.new(0, 760, 0, 120), "ESCAPE THE HOG", 48, C.white, "Antique")
logo.TextScaled = true
logo.TextStrokeTransparency = 0
logo.TextStrokeColor3 = rgb(90, 0, 25)
for _, x in ipairs({ -352, -318 }) do
	local ear = frame(menu, UDim2.new(0.5, x, 0, 18), UDim2.new(0, 28, 0, 28), C.white, 0)
	pcall(function() ear.Rotation = 45 end)
end
local playB = button(menu, UDim2.new(0.5, -230, 0, 268), UDim2.new(0, 460, 0, 76), ">   PLAY", rgb(14, 45, 24), C.green, 48)
playB.TextColor3 = rgb(100, 250, 130)
local function smallButton(i, text, border)
	local b = button(menu, UDim2.new(0.5, -230 + (i - 1) * 118, 0, 360), UDim2.new(0, 106, 0, 106), "", rgb(14, 12, 16), border)
	label(b, UDim2.new(0, 0, 1, -28), UDim2.new(1, 0, 0, 26), text, 18, border, "Cartoon")
	return b
end
local function icon(b, x, y, w, h, color, rot)
	local f = frame(b, UDim2.new(0.5, x, 0, y), UDim2.new(0, w, 0, h), color, 0)
	if rot then pcall(function() f.Rotation = rot end) end
	return f
end
local itemsB = smallButton(1, "ITEMS", rgb(225, 50, 60))
icon(itemsB, -26, 20, 22, 22, C.gold) icon(itemsB, -21, 25, 12, 12, rgb(14, 12, 16)) icon(itemsB, -6, 28, 32, 6, C.gold) icon(itemsB, 16, 32, 5, 10, C.gold)
local mapsB = smallButton(2, "MAPS", rgb(55, 95, 235))
icon(mapsB, -18, 36, 36, 26, rgb(210, 180, 120)) icon(mapsB, -16, 20, 32, 32, rgb(170, 40, 40), 45) icon(mapsB, -6, 46, 12, 16, rgb(90, 50, 20))
local helpM = smallButton(3, "HOW TO", C.purple)
label(helpM, UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 60), "?", 48, rgb(205, 120, 255), "Cartoon")
local statsB = smallButton(4, "STATS", rgb(235, 70, 150))
icon(statsB, -20, 18, 40, 40, C.gold, 45) icon(statsB, -12, 26, 24, 24, rgb(255, 235, 120), 45)
label(menu, UDim2.new(0.5, -300, 1, -46), UDim2.new(0, 600, 0, 34), "Don't get caught...", 28, rgb(210, 110, 140), "Antique")
z(menu, 2)
local function infoPanel(title, text, h, color)
	if gui:FindFirstChild("Info") then gui.Info:Destroy() end
	local f = frame(gui, UDim2.new(0.5, -380, 0.5, -(h or 420) / 2), UDim2.new(0, 760, 0, h or 420), C.dark, 0.04, color or C.pink)
	f.Name = "Info"
	label(f, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 44), title, 42, color or C.pink, "Cartoon")
	local body = label(f, UDim2.new(0, 28, 0, 66), UDim2.new(1, -56, 1, -130), text, 24, C.white)
	body.TextWrapped = true
	pcall(function() body.TextXAlignment = Enum.TextXAlignment.Left body.TextYAlignment = Enum.TextYAlignment.Top end)
	local close = button(f, UDim2.new(0.5, -90, 1, -58), UDim2.new(0, 180, 0, 44), "CLOSE", rgb(80, 20, 25), C.red, 28)
	close.MouseButton1Click:connect(function() f:Destroy() end)
	z(f, 7)
	return f
end
itemsB.MouseButton1Click:connect(function()
	local f = infoPanel("ITEMS", "These are hidden somewhere in the maps. Where do they go? That's for you to find out...", 330, rgb(225, 50, 60))
	for i, n in ipairs({ "Red Key", "Blue Key", "Gold Key", "Keycard", "Hammer", "Wrench", "Fuse", "Stun Gun" }) do
		local x = 20 + (i - 1) * 90
		frame(f, UDim2.new(0, x + 22, 0, 150), UDim2.new(0, 56, 0, 56), ITEM_COLOR[n], 0, C.white, 2)
		label(f, UDim2.new(0, x, 0, 212), UDim2.new(0, 100, 0, 26), n, 18, C.white, "Cartoon")
	end
	z(f, 7)
end)
mapsB.MouseButton1Click:connect(function()
	infoPanel("MAPS", "HOG MANOR - a creepy old house in the woods: a bedroom, a bathroom, the kitchen and pantry, a garage, " ..
		"the living room, the dining room and a dark cellar. The Hog sleeps in its pen.\n\n" ..
		"SCHOOL - classrooms, the science lab, the library, the cafeteria, the gym and the principal's office. " ..
		"The Hog hides in the janitor's closet.\n\n" ..
		"CIRCUS - a HUGE open carnival at night: the Big Top, the cafeteria, the arcade, a roller coaster, " ..
		"a ferris wheel, a carousel, food carts and game stalls. The Hog waits in the clowns' trailer.", 460, rgb(55, 95, 235))
end)
statsB.MouseButton1Click:connect(function()
	local ls = player:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("Coins")
	local e = ls and ls:FindFirstChild("Escapes")
	infoPanel("YOUR STATS", "COINS: " .. (c and c.Value or 0) .. "\n\nESCAPES: " .. (e and e.Value or 0) ..
		"\n\nEscape = +50 Coins.  Every lock you open = +5.\nAs a Hog: +10 for each catch, +40 if nobody escapes.", 380, rgb(235, 70, 150))
end)
helpM.MouseButton1Click:connect(showHowTo)

------------------------------------------------------------------ HOG VOTING (after PLAY)
local voteF = frame(gui, UDim2.new(0.5, -380, 0.5, -255), UDim2.new(0, 760, 0, 520), C.dark, 0.08, C.pink)
local voteTitle = label(voteF, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 44), "HOG VOTING", 42, C.white, "Antique")
local voteSub = label(voteF, UDim2.new(0, 0, 0, 48), UDim2.new(1, 0, 0, 22), "", 18, C.grey)
local MODES = { "Bot", "Player", "Player + Bot", "Infection", "Swarm", "Traitor" }
local MAPS_ = { "Hog Manor", "School", "Circus" }
local cards = { mode = {}, map = {} }
local function card(kind, i, x, y, w, h, name, bg)
	local b = button(voteF, UDim2.new(0, x, 0, y), UDim2.new(0, w, 0, h), "", bg, C.black)
	b.BorderSizePixel = 2
	local n = label(b, UDim2.new(0, 0, 0, 2), UDim2.new(1, -8, 0, 30), name, 28, C.white, "Cartoon")
	pcall(function() n.TextXAlignment = Enum.TextXAlignment.Right end)
	n.TextStrokeTransparency = 0
	local cnt = label(b, UDim2.new(0, 0, 1, -40), UDim2.new(1, -10, 0, 38), "0", 36, C.white, "Cartoon")
	pcall(function() cnt.TextXAlignment = Enum.TextXAlignment.Right end)
	cnt.TextStrokeTransparency = 0
	b.MouseButton1Click:connect(function()
		for _, o in ipairs(cards[kind]) do o.b.BorderColor3 = C.black o.b.BorderSizePixel = 2 end
		b.BorderColor3 = C.gold
		b.BorderSizePixel = 4
		remote:FireServer("vote", kind, name)
	end)
	cards[kind][i] = { b = b, count = cnt }
	return b
end
local MODE_BG = { rgb(40, 40, 52), rgb(70, 30, 40), rgb(60, 30, 70), rgb(30, 60, 30), rgb(50, 40, 70), rgb(60, 15, 15) }
for i, name in ipairs(MODES) do
	local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
	local b = card("mode", i, 20 + col * 244, 76 + row * 150, 232, 140, name, MODE_BG[i])
	-- the picture on each card
	if name == "Bot" then face(b, 14, 30, 82, rgb(150, 150, 160), C.red)
	elseif name == "Player" then face(b, 14, 30, 82, C.skin, nil, "bat")
	elseif name == "Player + Bot" then face(b, 10, 34, 70, C.skin) face(b, 72, 50, 60, rgb(150, 150, 160), C.red)
	elseif name == "Infection" then face(b, 10, 34, 70, rgb(150, 200, 120), rgb(60, 160, 40)) face(b, 70, 52, 58, rgb(130, 180, 100), rgb(60, 160, 40))
	elseif name == "Swarm" then face(b, 8, 44, 50, C.skin) face(b, 52, 62, 50, C.skin) face(b, 96, 44, 50, C.skin)
	else
		local hood = frame(b, UDim2.new(0, 22, 0, 30), UDim2.new(0, 76, 0, 96), rgb(20, 10, 12), 0)
		frame(hood, UDim2.new(0, 18, 0, 30), UDim2.new(0, 12, 0, 8), C.red, 0)
		frame(hood, UDim2.new(0, 46, 0, 30), UDim2.new(0, 12, 0, 8), C.red, 0)
	end
end
local mapHead = label(voteF, UDim2.new(0, 20, 0, 380), UDim2.new(0, 200, 0, 24), "MAP", 24, C.pink, "Cartoon")
pcall(function() mapHead.TextXAlignment = Enum.TextXAlignment.Left end)
for i, name in ipairs(MAPS_) do
	local b = card("map", i, 20 + (i - 1) * 244, 406, 232, 70, name, i == 1 and rgb(80, 45, 25) or i == 2 and rgb(30, 45, 85) or rgb(90, 20, 30))
	if i == 3 then
		for k = 0, 3 do frame(b, UDim2.new(0, 10 + k * 12, 0, 26), UDim2.new(0, 12, 0, 36), k % 2 == 0 and C.red or C.white, 0) end
		local top = frame(b, UDim2.new(0, 16, 0, 10), UDim2.new(0, 26, 0, 26), C.red, 0)
		pcall(function() top.Rotation = 45 end)
	elseif i == 1 then
		frame(b, UDim2.new(0, 14, 0, 30), UDim2.new(0, 40, 0, 30), rgb(210, 180, 120), 0)
		local roof = frame(b, UDim2.new(0, 18, 0, 14), UDim2.new(0, 32, 0, 32), rgb(150, 40, 40), 0)
		pcall(function() roof.Rotation = 45 end)
	else
		frame(b, UDim2.new(0, 10, 0, 22), UDim2.new(0, 60, 0, 40), rgb(200, 90, 60), 0)
		frame(b, UDim2.new(0, 33, 0, 10), UDim2.new(0, 14, 0, 14), rgb(240, 240, 240), 0)
	end
end
local lastText = label(voteF, UDim2.new(0, 10, 1, -34), UDim2.new(1, -20, 0, 28), "", 18, C.grey)
lastText.TextWrapped = true
z(voteF, 3)
local menuB = button(gui, UDim2.new(0, 10, 1, -70), UDim2.new(0, 130, 0, 52), "< MENU", C.dark, C.pink, 28)
local function setScreen(s)
	screen = s
	menu.Visible = s == "menu"
	voteF.Visible = s == "vote"
	menuB.Visible = s == "vote"
	hud.Visible = s == "game"
	if s ~= "game" then tip.Visible = false sel.Adornee = nil end
end
playB.MouseButton1Click:connect(function()
	remote:FireServer("play")
	setScreen("vote")
end)
menuB.MouseButton1Click:connect(function()
	remote:FireServer("menu")
	setScreen("menu")
end)
setScreen("menu")

------------------------------------------------------------------ crouching
local crouched = false
local function setCrouched(on)
	if on and role ~= "survivor" then on = false end
	crouched = on
	crouchB.Text = on and "STAND UP  [C]" or "CROUCH  [C]"
	crouchB.BackgroundColor3 = on and rgb(110, 50, 150) or rgb(60, 30, 80)
	local h = player.Character and player.Character:FindFirstChild("Humanoid")
	if h then pcall(function() h.CameraOffset = on and Vector3.new(0, -1.4, 0) or Vector3.new(0, 0, 0) end) end
	remote:FireServer("crouch", on)
end
crouchB.MouseButton1Click:connect(function() setCrouched(not crouched) end)
trapB.MouseButton1Click:connect(function() remote:FireServer("trap") end)
local mouse = player:GetMouse()
local function keyC() if screen == "game" and role == "survivor" then setCrouched(not crouched) end end
local okUIS = pcall(function()
	game:GetService("UserInputService").InputBegan:connect(function(input, busy)
		if not busy and input.KeyCode == Enum.KeyCode.C then keyC() end
	end)
end)
if not okUIS then mouse.KeyDown:connect(function(k) if k == "c" then keyC() end end) end

------------------------------------------------------------------ clicking things in the map
local function clickable(part)
	if not part or not part:FindFirstChild("ClickDetector") then return nil end
	local w = workspace:FindFirstChild("Hog World")
	local map = w and w:FindFirstChild("Map")
	if not map or not part:IsDescendantOf(map) then return nil end
	return part
end
local function itemNameOf(part)
	local m = part.Parent
	local v = m and m:FindFirstChild("ItemName")
	return v and v.Value
end
local holdingName = nil
mouse.Button1Down:connect(function()
	if screen ~= "game" or role ~= "survivor" then return end
	local part = clickable(mouse.Target)
	if part then
		remote:FireServer("click", part)
	elseif holdingName == "Stun Gun" then
		-- shoot where you clicked
		remote:FireServer("shoot", mouse.Hit.p)
	end
end)

------------------------------------------------------------------ messages from the server
local ROLE_LOOK = { survivor = { "SURVIVOR", C.green }, hog = { "THE HOG", C.pink }, traitor = { "TRAITOR", C.red } }
remote.OnClientEvent:connect(function(what, a, b, c, d, e, f, g)
	if what == "status" then
		local phase, left, alive, mapName, mode = a, b, c, d, e
		local mm, ss = math.floor(left / 60), left % 60
		local clock = mm .. ":" .. (ss < 10 and "0" or "") .. ss
		if phase == "lobby" then
			voteTitle.Text = "HOG VOTING - " .. left
			voteSub.Text = (g or 0) == 0 and "Waiting for players..." or (g .. (g == 1 and " player" or " players") .. " ready")
		elseif phase == "release" then
			voteTitle.Text = "ROUND STARTING..."
			timerText.Text = tostring(left)
			timerSub.Text = "THE HOG GETS OUT IN"
		elseif phase == "hunt" then
			voteTitle.Text = "ROUND IN PROGRESS"
			voteSub.Text = mapName .. " - " .. mode .. " - " .. alive .. " left. You're in the next one!"
			timerText.Text = clock
			timerSub.Text = "TIME LEFT"
		else
			voteTitle.Text = "ROUND OVER"
			timerText.Text = "0:00"
		end
		infoBar.Text = string.upper(mapName or "") .. "   |   " .. string.upper(mode or "") .. "   |   SURVIVORS: " .. tostring(alive)
	elseif what == "role" then
		role = a
		if role then
			setScreen("game")
			local look = ROLE_LOOK[role]
			roleText.Text, roleText.TextColor3, roleBox.BorderColor3 = look[1], look[2], look[2]
		elseif screen == "game" then
			setScreen("vote")
		end
		if role ~= "survivor" and crouched then setCrouched(false) end
		trapB.Visible = role == "hog"
		crouchB.Visible = role == "survivor"
		slot.Visible = role == "survivor"
		slotName.Visible = role == "survivor"
	elseif what == "hold" then
		holdingName = a
		slotIcon.Visible = a ~= nil
		slotIcon.BackgroundColor3 = ITEM_COLOR[a or ""] or C.gold
		slotName.Text = a and (string.upper(a) .. (b and ("  (" .. b .. " SHOTS)") or "")) or "EMPTY HANDS"
		slotName.TextColor3 = a and C.gold or C.grey
	elseif what == "big" then
		announce(a, b)
	elseif what == "toast" then
		toast(a, b)
	elseif what == "caught" then
		jumpscare()
	elseif what == "note" then
		-- the code note, big on your screen
		if gui:FindFirstChild("NoteView") then gui.NoteView:Destroy() end
		local f = frame(gui, UDim2.new(0.5, -170, 0.5, -130), UDim2.new(0, 340, 0, 260), rgb(245, 240, 220), 0, rgb(120, 90, 60))
		f.Name = "NoteView"
		local nt = label(f, UDim2.new(0, 0, 0, 20), UDim2.new(1, 0, 0, 40), "the code is...", 28, rgb(90, 60, 40), "Antique")
		nt.TextStrokeTransparency = 1
		local code = label(f, UDim2.new(0, 0, 0, 80), UDim2.new(1, 0, 0, 100), tostring(a), 48, rgb(120, 0, 0), "Antique")
		code.TextScaled = true
		code.TextStrokeTransparency = 1
		frame(f, UDim2.new(0, 230, 0, 190), UDim2.new(0, 50, 0, 40), rgb(150, 110, 70), 0.4)
		z(f, 7)
		sound("rbxasset://sounds/swoosh.wav", 0.5)
		delay(3.5, function() pcall(function() f:Destroy() end) end)
	elseif what == "keypad" then
		if gui:FindFirstChild("KeypadView") then return end
		local f = frame(gui, UDim2.new(0.5, -130, 0.5, -200), UDim2.new(0, 260, 0, 400), rgb(30, 30, 34), 0, rgb(90, 90, 100))
		f.Name = "KeypadView"
		local disp = frame(f, UDim2.new(0, 20, 0, 20), UDim2.new(1, -40, 0, 56), rgb(10, 30, 10), 0, rgb(60, 60, 60), 2)
		local dt = label(disp, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "----", 42, rgb(90, 255, 120), "Code")
		local typed = ""
		local function show() dt.Text = typed .. string.rep("-", 4 - #typed) end
		local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK" }
		for i, k in ipairs(keys) do
			local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
			local b = button(f, UDim2.new(0, 20 + col * 76, 0, 92 + row * 66), UDim2.new(0, 68, 0, 58), k,
				k == "OK" and rgb(30, 110, 50) or k == "C" and rgb(120, 30, 30) or rgb(60, 60, 68), rgb(20, 20, 20), 36)
			b.MouseButton1Click:connect(function()
				sound("rbxasset://sounds/electronicpingshort.wav", 0.3, 1.5)
				if k == "C" then typed = ""
				elseif k == "OK" then
					if #typed == 4 then remote:FireServer("code", typed) end
					typed = ""
				elseif #typed < 4 then typed = typed .. k end
				show()
			end)
		end
		local close = button(f, UDim2.new(0.5, -50, 1, -42), UDim2.new(0, 100, 0, 32), "CLOSE", rgb(50, 50, 55), nil, 18)
		close.MouseButton1Click:connect(function() f:Destroy() end)
		z(f, 7)
	elseif what == "keypadok" then
		if gui:FindFirstChild("KeypadView") then gui.KeypadView:Destroy() end
		sound("rbxasset://sounds/electronicpingshort.wav", 0.8, 2)
	elseif what == "keypadbad" then
		sound("rbxasset://sounds/electronicpingshort.wav", 1, 0.5)
	elseif what == "vent" then
		-- crawling through a vent: dark for a moment
		local f = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.black, 0)
		label(f, UDim2.new(0.5, -300, 0.5, -30), UDim2.new(0, 600, 0, 60), "crawling through the vent...", 36, C.grey, "Cartoon")
		z(f, 8)
		delay(1.5, function() f:Destroy() end)
	elseif what == "howto" then
		showHowTo()
	elseif what == "votes" then
		for i, o in ipairs(cards.map) do o.count.Text = tostring(a and a[i] or 0) end
		for i, o in ipairs(cards.mode) do o.count.Text = tostring(b and b[i] or 0) end
	elseif what == "last" then
		lastText.Text = a or ""
	end
end)
gui.Parent = pg
spawn(function()
	while true do
		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Coins") then coinText.Text = tostring(ls.Coins.Value) end
		wait(0.5)
	end
end)

------------------------------------------------------------------ the bot Hogs walk (smoothly, on this computer)
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
		local x, zz, gx, gz, sp, what = mv.Value:match("^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+)")
		if not x then return end
		local at = Vector3.new(tonumber(x), 0, tonumber(zz))
		S.goal, S.speed = Vector3.new(tonumber(gx), 0, tonumber(gz)), tonumber(sp) or 0
		-- way off from where the server has it (just spawned, or this computer fell behind): jump there
		if what == "s" or (S.pos - at).magnitude > 12 then S.pos = at end
		if what == "e" then S.smash = 1.2 end
		if what == "z" then S.stun = tick() + 20 end
	end
	read()
	mv.Changed:connect(read)
	hogs[m] = S
end
local lamps = {}
local function findHogs()
	local w = workspace:FindFirstChild("Hog World")
	local map = w and w:FindFirstChild("Map")
	if map then
		for _, o in ipairs(map:GetChildren()) do if o.Name == "Hog" then track(o) end end
		-- a few of the lamps flicker
		if #lamps == 0 or not lamps[1].part.Parent then
			lamps = {}
			for _, o in ipairs(map:GetChildren()) do
				local l = o.Name == "Lamp" and o:FindFirstChild("PointLight")
				if l and math.random() < 0.35 then table.insert(lamps, { part = o, light = l, b = l.Brightness }) end
			end
		end
	else
		lamps = {}
	end
	for m in pairs(hogs) do if not m.Parent then hogs[m] = nil end end
end
spawn(function() while true do pcall(findHogs) wait(1) end end)
local RunService = game:GetService("RunService")
local lastT = tick()
local nextFlicker = 0
RunService.RenderStepped:connect(function()
	local now = tick()
	local dt = math.min(0.1, now - lastT)
	lastT = now
	if tick() > bigUntil then big.Text, sub.Text = "", "" end
	-- behind the menu, the camera looks down the hallway at the Hog
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
	-- the PLAY button glows
	local pulse = 0.5 + 0.5 * math.sin(now * 3)
	playB.BorderColor3 = Color3.new(0.2 + 0.25 * pulse, 0.6 + 0.35 * pulse, 0.3 + 0.2 * pulse)
	-- pointing at something you can click: it lights up (items show their name)
	if screen == "game" and role == "survivor" then
		local part = clickable(mouse.Target)
		sel.Adornee = part
		local n = part and itemNameOf(part)
		tip.Visible = n ~= nil
		if n then
			tip.Text = n
			tip.Position = UDim2.new(0, mouse.X + 16, 0, mouse.Y - 30)
		end
	end
	-- flickering lights
	if now > nextFlicker then
		nextFlicker = now + 0.08
		for _, L in ipairs(lamps) do
			if L.part.Parent then
				local on = math.random() > 0.12
				L.light.Brightness = on and L.b or L.b * 0.15
				L.part.Transparency = on and 0 or 0.6
			end
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
			if S.stun and now < S.stun then rootCF = rootCF * CFrame.Angles(0, 0, math.sin(now * 5) * 0.25) end
			local pose = HogPose(rootCF, swing, S.smash > 0 and math.sin(math.min(1, S.smash) * math.pi) or 0)
			for name, part in pairs(S.parts) do
				local cf = pose[name]
				if cf and part.Parent then part.CFrame = cf end
			end
			if S.root then S.root.CFrame = rootCF end
			if me then closest = math.min(closest, (me.Position - p).magnitude) end
		end
	end
	-- Hog players (Player / Infection modes) count too
	if me and role == "survivor" then
		for _, other in ipairs(Players:GetPlayers()) do
			local c = other ~= player and other.Character
			local t = c and c:FindFirstChild("HogHead") and (c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart"))
			if t then closest = math.min(closest, (me.Position - t.Position).magnitude) end
		end
	end
	-- red edges: the closer a Hog, the redder
	local k = closest < 40 and (1 - closest / 40) or 0
	local beat = 0.5 + 0.5 * math.sin(now * (6 + k * 8))
	for _, e in ipairs(edges) do e.BackgroundTransparency = 1 - k * (0.35 + 0.35 * beat) end
end)
