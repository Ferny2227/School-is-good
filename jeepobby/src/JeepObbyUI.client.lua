-- StarterGui.JeepObbyClient (builds the ScreenGui "JeepObbyUI"): the HUD (level, stage progress, wins, timer), the garage (cars unlocked by wins),
-- the level select, and the checkpoint / win popups. Built in code so it works on 2016 engines:
-- no AnchorPoint, no TweenService, FontSize instead of TextSize, ZIndex 1..10.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do wait() player = Players.LocalPlayer end
local playerGui = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("JeepObbyEvent")

--#CARS

local old = playerGui:FindFirstChild("JeepObbyUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "JeepObbyUI"

------------------------------------------------------------------ little builders
local function rgb(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local DARK = rgb(24, 28, 40)
local PANEL = rgb(36, 42, 60)
local WHITE = rgb(255, 255, 255)
local GOLD = rgb(255, 205, 60)
local GREEN = rgb(70, 200, 90)
local RED = rgb(220, 70, 70)
local GREY = rgb(110, 115, 130)

local function setFont(o, size, bold)
	pcall(function() o.Font = bold and Enum.Font.SourceSansBold or Enum.Font.SourceSans end)
	pcall(function() o.FontSize = Enum.FontSize["Size" .. size] end)
end

local function frame(parent, name, pos, size, color, z, transp)
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = color or PANEL
	f.BackgroundTransparency = transp or 0
	f.BorderSizePixel = 0
	f.ZIndex = z or 1
	f.Parent = parent
	return f
end

local function label(parent, name, pos, size, text, fsize, color, z, align)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.Position = pos
	t.Size = size
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or WHITE
	t.TextStrokeTransparency = 0.6
	t.ZIndex = z or 1
	if align then t.TextXAlignment = align end
	setFont(t, fsize or 18, true)
	t.Parent = parent
	return t
end

local function button(parent, name, pos, size, text, color, z, fsize)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color or GREEN
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = WHITE
	b.TextStrokeTransparency = 0.5
	b.AutoButtonColor = true
	b.ZIndex = z or 1
	setFont(b, fsize or 18, true)
	b.Parent = parent
	return b
end

------------------------------------------------------------------ state
local leaderstats = player:WaitForChild("leaderstats")
local stageV = leaderstats:WaitForChild("Stage")
local winsV = leaderstats:WaitForChild("Wins")
local bestV = player:WaitForChild("BestStage")
local carV = player:WaitForChild("SelectedCar")

local function levelOf(stage)
	local lv = 1
	for i, L in ipairs(LEVELS) do if stage >= L.stage then lv = i end end
	return lv
end

------------------------------------------------------------------ HUD (top middle)
local hud = frame(gui, "HUD", UDim2.new(0.5, -170, 0, 4), UDim2.new(0, 340, 0, 50), DARK, 1, 0.35)
local levelLbl = label(hud, "Level", UDim2.new(0, 8, 0, 2), UDim2.new(0, 240, 0, 20), "", 18, GOLD, 2, Enum.TextXAlignment.Left)
local stageLbl = label(hud, "Stage", UDim2.new(0, 8, 0, 21), UDim2.new(0, 220, 0, 16), "", 14, WHITE, 2, Enum.TextXAlignment.Left)
local winsLbl = label(hud, "Wins", UDim2.new(1, -98, 0, 2), UDim2.new(0, 90, 0, 20), "", 18, GOLD, 2, Enum.TextXAlignment.Right)
local timeLbl = label(hud, "Time", UDim2.new(1, -98, 0, 21), UDim2.new(0, 90, 0, 16), "0:00", 14, WHITE, 2, Enum.TextXAlignment.Right)
local barBack = frame(hud, "Bar", UDim2.new(0, 8, 1, -9), UDim2.new(1, -16, 0, 5), rgb(60, 66, 86), 2)
local barFill = frame(barBack, "Fill", UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0), GREEN, 3)

-- the run timer lives in _G so it keeps counting after you respawn
_G.JeepObbyRunStart = _G.JeepObbyRunStart or tick()
local runStart = _G.JeepObbyRunStart
local function refreshHud()
	local s = stageV.Value
	local lv = levelOf(s)
	levelLbl.Text = "LEVEL " .. lv .. ": " .. LEVELS[lv].name
	stageLbl.Text = "Stage " .. s .. " / " .. LAST_STAGE .. "   (car: " .. (CARS[carV.Value] and CARS[carV.Value].name or "?") .. ")"
	winsLbl.Text = winsV.Value .. (winsV.Value == 1 and " WIN" or " WINS")
	barFill.Size = UDim2.new((s - 1) / LAST_STAGE, 0, 1, 0)
end

------------------------------------------------------------------ side buttons (big, for touch / chromebook pads)
local side = frame(gui, "Side", UDim2.new(0, 6, 0.5, -84), UDim2.new(0, 96, 0, 168), DARK, 1, 1)
local garageBtn = button(side, "Garage", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 36), "GARAGE", rgb(60, 120, 230), 2, 18)
local spawnBtn = button(side, "NewCar", UDim2.new(0, 0, 0, 42), UDim2.new(1, 0, 0, 36), "NEW CAR", GREEN, 2, 18)
local flipBtn = button(side, "Flip", UDim2.new(0, 0, 0, 84), UDim2.new(1, 0, 0, 36), "FLIP CAR", rgb(230, 140, 40), 2, 18)
local levelsBtn = button(side, "Levels", UDim2.new(0, 0, 0, 126), UDim2.new(1, 0, 0, 36), "LEVELS", rgb(150, 80, 220), 2, 18)
-- small button that hides / shows everything else (key H)
local hideBtn = button(gui, "HideUI", UDim2.new(0, 6, 0.5, -112), UDim2.new(0, 96, 0, 22), "HIDE UI", rgb(70, 75, 95), 2, 14)
local uiHidden = _G.JeepObbyHideUI == true

------------------------------------------------------------------ toast (checkpoint etc.)
local toast = label(gui, "Toast", UDim2.new(0.5, -200, 0, 60), UDim2.new(0, 400, 0, 36), "", 28, GREEN, 6)
toast.Visible = false
local toastId = 0
local function showToast(text, color)
	toastId = toastId + 1
	local my = toastId
	toast.Text = text
	toast.TextColor3 = color or GREEN
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.4
	toast.Visible = true
	spawn(function()
		wait(1.6)
		for i = 1, 10 do
			if toastId ~= my then return end
			toast.TextTransparency = i / 10
			toast.TextStrokeTransparency = 0.4 + i * 0.06
			wait(0.04)
		end
		if toastId == my then toast.Visible = false end
	end)
end

------------------------------------------------------------------ garage
local garage = frame(gui, "Garage", UDim2.new(0.5, -330, 0.5, -215), UDim2.new(0, 660, 0, 430), PANEL, 4)
garage.Visible = false
frame(garage, "Top", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 50), DARK, 5)
label(garage, "Title", UDim2.new(0, 16, 0, 0), UDim2.new(0, 150, 0, 50), "GARAGE", 36, GOLD, 6, Enum.TextXAlignment.Left)
local garageInfo = label(garage, "Info", UDim2.new(0, 176, 0, 0), UDim2.new(0, 420, 0, 50), "", 18, WHITE, 6, Enum.TextXAlignment.Right)
local garageClose = button(garage, "Close", UDim2.new(1, -46, 0, 6), UDim2.new(0, 38, 0, 38), "X", RED, 6, 24)

local cards = {}
for i, c in ipairs(CARS) do
	local col = (i - 1) % 4
	local row = math.floor((i - 1) / 4)
	local card = frame(garage, "Car" .. i, UDim2.new(0, 14 + col * 160, 0, 62 + row * 182), UDim2.new(0, 150, 0, 172), DARK, 5)
	local swatch = frame(card, "Swatch", UDim2.new(0, 8, 0, 8), UDim2.new(1, -16, 0, 34), BrickColor.new(c.color).Color, 6)
	label(swatch, "Name", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), c.name, #c.name > 8 and 18 or 24, WHITE, 7)
	local function stat(y, name, v, max)
		label(card, name, UDim2.new(0, 8, 0, y), UDim2.new(0, 50, 0, 16), name, 14, rgb(190, 195, 210), 6, Enum.TextXAlignment.Left)
		local back = frame(card, name .. "Bar", UDim2.new(0, 58, 0, y + 4), UDim2.new(1, -66, 0, 8), rgb(60, 66, 86), 6)
		frame(back, "Fill", UDim2.new(0, 0, 0, 0), UDim2.new(math.min(1, v / max), 0, 1, 0), GOLD, 7)
	end
	stat(48, "Speed", c.speed, 240)
	stat(66, "Power", c.torque, 18)
	stat(84, "Turn", c.turn, 2.4)
	label(card, "Desc", UDim2.new(0, 6, 0, 100), UDim2.new(1, -12, 0, 22), c.desc, 14, rgb(200, 205, 220), 6)
	local b = button(card, "Pick", UDim2.new(0, 8, 1, -42), UDim2.new(1, -16, 0, 34), "", GREEN, 6, 18)
	b.MouseButton1Click:connect(function()
		if winsV.Value >= c.wins then
			pcall(function() remote:FireServer("select", i) end)
			garage.Visible = false
			showToast(c.name .. " ready!", GOLD)
		else
			showToast("Win " .. (c.wins - winsV.Value) .. " more time(s) to unlock", RED)
		end
	end)
	cards[i] = { card = card, button = b, car = c }
end

local function refreshGarage()
	local w = winsV.Value
	garageInfo.Text = "You have " .. w .. (w == 1 and " win" or " wins") .. ". Win more to unlock faster cars!"
	for i, cd in ipairs(cards) do
		local b = cd.button
		if i == carV.Value then
			b.Text = "DRIVING"
			setFont(b, 18, true)
			b.BackgroundColor3 = GREY
		elseif w >= cd.car.wins then
			b.Text = "DRIVE"
			setFont(b, 18, true)
			b.BackgroundColor3 = GREEN
		else
			b.Text = "LOCKED - " .. cd.car.wins .. " WINS"
			setFont(b, 14, true)
			b.BackgroundColor3 = rgb(90, 50, 50)
		end
		cd.card.BackgroundColor3 = (w >= cd.car.wins) and DARK or rgb(18, 20, 28)
	end
end

------------------------------------------------------------------ level select
local levels = frame(gui, "Levels", UDim2.new(0.5, -190, 0.5, -185), UDim2.new(0, 380, 0, 370), PANEL, 4)
levels.Visible = false
frame(levels, "Top", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 50), DARK, 5)
label(levels, "Title", UDim2.new(0, 16, 0, 0), UDim2.new(0, 300, 0, 50), "LEVELS", 36, GOLD, 6, Enum.TextXAlignment.Left)
local levelsClose = button(levels, "Close", UDim2.new(1, -46, 0, 6), UDim2.new(0, 38, 0, 38), "X", RED, 6, 24)
local levelButtons = {}
for i, L in ipairs(LEVELS) do
	local b = button(levels, "Level" .. i, UDim2.new(0, 16, 0, 60 + (i - 1) * 60), UDim2.new(1, -32, 0, 50), "", GREEN, 6, 24)
	b.MouseButton1Click:connect(function()
		if bestV.Value >= L.stage then
			pcall(function() remote:FireServer("level", i) end)
			levels.Visible = false
		else
			showToast("Reach level " .. i .. " first!", RED)
		end
	end)
	levelButtons[i] = b
end
local function refreshLevels()
	for i, L in ipairs(LEVELS) do
		local b = levelButtons[i]
		if bestV.Value >= L.stage then
			b.Text = i .. ". " .. L.name
			b.BackgroundColor3 = (levelOf(stageV.Value) == i) and rgb(60, 120, 230) or GREEN
		else
			b.Text = i .. ". LOCKED"
			b.BackgroundColor3 = GREY
		end
	end
end

------------------------------------------------------------------ win popup
local winBox = frame(gui, "Win", UDim2.new(0.5, -220, 0.5, -130), UDim2.new(0, 440, 0, 260), DARK, 8)
winBox.Visible = false
frame(winBox, "Stripe", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 8), GOLD, 9)
label(winBox, "Title", UDim2.new(0, 0, 0, 18), UDim2.new(1, 0, 0, 56), "YOU WIN!", 48, GOLD, 9)
local winCount = label(winBox, "Count", UDim2.new(0, 0, 0, 80), UDim2.new(1, 0, 0, 30), "", 28, WHITE, 9)
local winUnlock = label(winBox, "Unlock", UDim2.new(0, 10, 0, 116), UDim2.new(1, -20, 0, 60), "", 24, GREEN, 9)
winUnlock.TextWrapped = true
local winOk = button(winBox, "OK", UDim2.new(0.5, -90, 1, -62), UDim2.new(0, 180, 0, 48), "DRIVE AGAIN", GREEN, 9, 24)
winOk.MouseButton1Click:connect(function() winBox.Visible = false end)

------------------------------------------------------------------ hooking it up
local function closeAll()
	garage.Visible = false
	levels.Visible = false
end
garageBtn.MouseButton1Click:connect(function()
	local show = not garage.Visible
	closeAll()
	refreshGarage()
	garage.Visible = show
end)
levelsBtn.MouseButton1Click:connect(function()
	local show = not levels.Visible
	closeAll()
	refreshLevels()
	levels.Visible = show
end)
local function applyHidden()
	hud.Visible = not uiHidden
	side.Visible = not uiHidden
	hideBtn.Text = uiHidden and "SHOW UI" or "HIDE UI"
	if uiHidden then closeAll() end
end
local function toggleHidden()
	uiHidden = not uiHidden
	_G.JeepObbyHideUI = uiHidden
	applyHidden()
end
hideBtn.MouseButton1Click:connect(toggleHidden)
applyHidden()
garageClose.MouseButton1Click:connect(function() garage.Visible = false end)
levelsClose.MouseButton1Click:connect(function() levels.Visible = false end)
spawnBtn.MouseButton1Click:connect(function()
	pcall(function() remote:FireServer("spawn") end)
	showToast("New car at your checkpoint", WHITE)
end)
flipBtn.MouseButton1Click:connect(function()
	pcall(function() remote:FireServer("flip") end)
end)

local lastStage = stageV.Value
stageV.Changed:connect(function()
	if stageV.Value == 1 and lastStage > 1 then runStart = tick() _G.JeepObbyRunStart = runStart end
	lastStage = stageV.Value
	refreshHud()
	if levels.Visible then refreshLevels() end
end)
winsV.Changed:connect(function() refreshHud() refreshGarage() end)
carV.Changed:connect(function() refreshHud() refreshGarage() end)
bestV.Changed:connect(function() if levels.Visible then refreshLevels() end end)

remote.OnClientEvent:connect(function(what, a, b)
	if what == "checkpoint" then
		showToast("CHECKPOINT " .. tostring(a) .. "!", GREEN)
	elseif what == "level" then
		local L = LEVELS[b or 1]
		showToast("LEVEL " .. tostring(b) .. ": " .. (L and L.name or ""), GOLD)
	elseif what == "win" then
		runStart = tick() _G.JeepObbyRunStart = runStart
		winCount.Text = "Total wins: " .. tostring(a)
		if b and b ~= "" then
			winUnlock.Text = "NEW CAR UNLOCKED: " .. b .. "\n(it's waiting at the start!)"
		else
			local nextCar
			for _, c in ipairs(CARS) do
				if c.wins > (a or 0) then nextCar = c break end
			end
			winUnlock.Text = nextCar and ("Next car: " .. nextCar.name .. " at " .. nextCar.wins .. " wins") or "You have every car!"
		end
		closeAll()
		winBox.Visible = true
	end
end)

-- keyboard shortcuts: G garage, R new car, F flip, L levels, H hide the UI
pcall(function()
	local mouse = player:GetMouse()
	mouse.KeyDown:connect(function(k)
		k = string.lower(k)
		if k == "g" then garage.Visible = not garage.Visible levels.Visible = false refreshGarage()
		elseif k == "l" then levels.Visible = not levels.Visible garage.Visible = false refreshLevels()
		elseif k == "r" then pcall(function() remote:FireServer("spawn") end)
		elseif k == "f" then pcall(function() remote:FireServer("flip") end)
		elseif k == "h" then toggleHidden()
		end
	end)
end)

refreshHud()
refreshGarage()
refreshLevels()
gui.Parent = playerGui

spawn(function()
	while gui.Parent do
		local t = math.floor(tick() - runStart)
		timeLbl.Text = string.format("%d:%02d", math.floor(t / 60), t % 60)
		wait(0.5)
	end
end)
