-- ShooterClient (LocalScript)
-- Location: StarterGui > ShooterClient   (runs again every time you spawn)
-- Everything you see and press in SHOOTER ARENA (v6):
--   HUD: health, ammo, gun, grenades, XP bar, level, killstreak, timer, scores, kill feed, crosshair,
--        hitmarkers (+ damage numbers), medals, damage flash, sniper scope, big messages, minimap,
--        the hill (King of the Hill), your gun (Gun Game).
--   Menus: VOTE (map / mode / weather / bots / your team), LOADOUT (L), SETTINGS (P), TEAM (T),
--          SCOREBOARD (hold Tab), death screen, match results. Every menu also has a button.
--   Camera: FIRST PERSON, or THIRD PERSON (v6: our own over-the-shoulder camera that turns with the
--           mouse OR a Chromebook touchpad without clicking, and with the arrow keys).
--   Weather (v6): rain, thunderstorm (lightning), snow and sandstorm fall around you.
--   Touch screens (v6): FIRE / AIM / RELOAD / GRENADE / SWAP buttons, drag to look.
--   Keys: click or F = shoot (hold for automatic guns), right click or Q = aim, R = reload,
--         G = grenade, Shift = sprint, V = camera, X = other shoulder, Z = sniper zoom,
--         arrow keys = turn (third person), L = loadout, P = settings, T = team, Tab = scores.
-- The server decides hits and damage; this script only sends where you aim.
-- Plain 2016-style Lua (no ModuleScripts). Newer things (rounded corners, UI scaling) are in pcalls.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local remote = RS:WaitForChild("SRemote")
local G = RS:WaitForChild("Game")
local pg = player:WaitForChild("PlayerGui")
local sd = player:WaitForChild("SData")
local mouse = player:GetMouse()
local camera = game.Workspace.CurrentCamera
local UIS = nil
pcall(function()
	UIS = game:GetService("UserInputService")
end)
local RunService = game:GetService("RunService")

do
	local old = pg:FindFirstChild("ShooterUI")
	if old then
		old:Destroy()
	end
end

------------------------------------------------------------------
-- small UI helpers
------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ShooterUI"
pcall(function()
	gui.ResetOnSpawn = true
end)

local function rgb(r, g, b)
	return Color3.new(r / 255, g / 255, b / 255)
end
local DARK = rgb(16, 18, 26)
local PANEL = rgb(24, 27, 38)
local BTN = rgb(48, 53, 72)
local ACCENT = rgb(255, 190, 60)
local SUB = rgb(165, 172, 190)
local RED = rgb(225, 65, 65)
local BLUE = rgb(60, 120, 235)
local GREEN = rgb(45, 160, 80)
local PICKED = rgb(225, 150, 30)

-- rounded corners and an outline (only on newer Roblox; old ones just skip it)
local function round(o, r)
	pcall(function()
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r or 8)
		c.Parent = o
	end)
	return o
end
local function outline(o, color, thick, trans)
	pcall(function()
		local s = Instance.new("UIStroke")
		s.Color = color or Color3.new(1, 1, 1)
		s.Thickness = thick or 1
		s.Transparency = trans or 0.75
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = o
	end)
	return o
end

local function frame(parent, pos, size, color, trans)
	local f = Instance.new("Frame")
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = color or DARK
	f.BackgroundTransparency = trans or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function label(parent, pos, size, text, fontSize, color, align, trans)
	local t = Instance.new("TextLabel")
	t.Position = pos
	t.Size = size
	t.BackgroundTransparency = trans or 1
	t.BackgroundColor3 = DARK
	t.BorderSizePixel = 0
	t.Font = Enum.Font.SourceSansBold
	t.FontSize = fontSize or Enum.FontSize.Size18
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.6
	t.Text = text or ""
	if align then
		t.TextXAlignment = align
	end
	t.Parent = parent
	return t
end

local function button(parent, pos, size, text, color, fn)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color or BTN
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = Enum.Font.SourceSansBold
	b.FontSize = Enum.FontSize.Size18
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = text
	b.Parent = parent
	round(b, 6)
	if fn then
		b.MouseButton1Click:connect(fn)
	end
	return b
end

-- the size of the screen
local function viewSize()
	local ok, x, y = pcall(function()
		local v = camera.ViewportSize
		return v.X, v.Y
	end)
	if ok and x and x > 0 then
		return x, y
	end
	return mouse.ViewSizeX or 1366, mouse.ViewSizeY or 768
end

-- a menu panel in the middle of the screen. It shrinks to fit small screens (Chromebooks!)
local scalers = {}
local function panel(w, h, title, yOff)
	local f = frame(gui, UDim2.new(0.5, -w / 2, 0.5, -h / 2 + (yOff or 0)), UDim2.new(0, w, 0, h), PANEL, 0.04)
	pcall(function()
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.new(0.5, 0, 0.5, yOff or 0)
	end)
	round(f, 12)
	outline(f, ACCENT, 2, 0.55)
	pcall(function()
		local s = Instance.new("UIScale")
		s.Parent = f
		table.insert(scalers, { s = s, w = w, h = h })
	end)
	if title then
		local bar = frame(f, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 40), DARK, 0)
		round(bar, 12)
		frame(bar, UDim2.new(0, 0, 1, -12), UDim2.new(1, 0, 0, 12), DARK, 0) -- square bottom corners
		label(bar, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), title, Enum.FontSize.Size28, ACCENT)
	end
	f.Visible = false
	return f
end
local function updateScales()
	local vx, vy = viewSize()
	for _, e in ipairs(scalers) do
		e.s.Scale = math.max(0.45, math.min(1, (vx - 24) / e.w, (vy - 70) / e.h))
	end
end
-- (a button with Modal = true frees the mouse in first person while its menu is open)
local function modal(b)
	pcall(function()
		b.Modal = true
	end)
	return b
end

local function fmtTime(s)
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

local function sval(name, default)
	local v = sd:FindFirstChild(name)
	if v then
		return v.Value
	end
	return default
end
local function gval(name, default)
	local v = G:FindFirstChild(name)
	if v then
		return v.Value
	end
	return default
end
-- "id|name|info" lines from the server
local function lines(name)
	local out = {}
	for line in string.gmatch(gval(name, ""), "[^\n]+") do
		local f = {}
		for v in string.gmatch(line, "[^|]+") do
			table.insert(f, v)
		end
		table.insert(out, f)
	end
	return out
end
local TEAM_MODES = { tdm = true, elim = true, koth = true }

------------------------------------------------------------------
-- HUD
------------------------------------------------------------------
-- top centre: mode, map, weather, timer, scores
local top = frame(gui, UDim2.new(0.5, -260, 0, 4), UDim2.new(0, 520, 0, 60), DARK, 0.25)
round(top, 10)
local topMode = label(top, UDim2.new(0, 0, 0, 1), UDim2.new(1, 0, 0, 20), "", Enum.FontSize.Size18, ACCENT)
local topTime = label(top, UDim2.new(0.5, -45, 0, 22), UDim2.new(0, 90, 0, 34), "", Enum.FontSize.Size28)
local redBox = frame(top, UDim2.new(0, 8, 0, 23), UDim2.new(0, 170, 0, 30), rgb(190, 45, 45), 0.1)
round(redBox, 6)
local redText = label(redBox, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "", Enum.FontSize.Size24)
local blueBox = frame(top, UDim2.new(1, -178, 0, 23), UDim2.new(0, 170, 0, 30), rgb(45, 90, 200), 0.1)
round(blueBox, 6)
local blueText = label(blueBox, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "", Enum.FontSize.Size24)
-- under the top bar: the hill (King of the Hill) or your gun (Gun Game)
local objective = label(gui, UDim2.new(0.5, -260, 0, 66), UDim2.new(0, 520, 0, 24), "", Enum.FontSize.Size18, Color3.new(1, 1, 1))

-- kill feed (top right)
local feedLines = {}
for i = 1, 6 do
	feedLines[i] = label(gui, UDim2.new(1, -430, 0, 70 + (i - 1) * 22), UDim2.new(0, 420, 0, 20), "", Enum.FontSize.Size14, Color3.new(1, 1, 1), Enum.TextXAlignment.Right)
end
local feed = {}
local function pushFeed(text, color)
	table.insert(feed, 1, { text = text, color = color or Color3.new(1, 1, 1), t = tick() })
	while #feed > 6 do
		table.remove(feed)
	end
end

-- crosshair + hitmarker + damage number
local cross = {}
for i = 1, 4 do
	cross[i] = frame(gui, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, 2, 0, 10), Color3.new(1, 1, 1), 0.1)
end
local dot = frame(gui, UDim2.new(0.5, -1, 0.5, -1), UDim2.new(0, 2, 0, 2), Color3.new(1, 1, 1), 0)
local hitA = frame(gui, UDim2.new(0.5, -9, 0.5, -1), UDim2.new(0, 18, 0, 3), Color3.new(1, 1, 1), 0)
local hitB = frame(gui, UDim2.new(0.5, -9, 0.5, -1), UDim2.new(0, 18, 0, 3), Color3.new(1, 1, 1), 0)
pcall(function()
	hitA.Rotation = 45
	hitB.Rotation = -45
end)
hitA.Visible, hitB.Visible = false, false
local dmgNum = label(gui, UDim2.new(0.5, 14, 0.5, -34), UDim2.new(0, 80, 0, 22), "", Enum.FontSize.Size18, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)

-- big message, xp popup, "ELIMINATED name", medals
local big = label(gui, UDim2.new(0.5, -350, 0.22, 0), UDim2.new(0, 700, 0, 50), "", Enum.FontSize.Size36, ACCENT)
pcall(function()
	big.TextWrapped = true
end)
local xpPop = label(gui, UDim2.new(0.5, -150, 0.5, 40), UDim2.new(0, 300, 0, 26), "", Enum.FontSize.Size24, rgb(255, 230, 120))
local killNotice = label(gui, UDim2.new(0.5, -200, 0.5, 66), UDim2.new(0, 400, 0, 26), "", Enum.FontSize.Size24, rgb(255, 80, 80))
local medalLabels = {}
for i = 1, 3 do
	local l = label(gui, UDim2.new(0.5, -170, 0.22, 52 + (i - 1) * 32), UDim2.new(0, 340, 0, 28), "", Enum.FontSize.Size24, rgb(255, 215, 90), nil, 0.35)
	l.BackgroundColor3 = DARK
	round(l, 8)
	l.Visible = false
	medalLabels[i] = l
end
local medals = {}
local T = { big = 0, xp = 0, kill = 0, hit = 0, hurt = 0, hurtDir = 0, died = 0, flash = 0, scale = 0 } -- (times when things end)
local function showBig(text, color, secs)
	big.Text = text
	big.TextColor3 = color or ACCENT
	T.big = tick() + (secs or 3)
end

-- bottom left: health, level, XP, streak
local hpBar, hpText, xpBar
do
	local hpBack = frame(gui, UDim2.new(0, 16, 1, -86), UDim2.new(0, 260, 0, 26), rgb(40, 10, 10), 0.2)
	round(hpBack, 6)
	hpBar = frame(hpBack, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), rgb(70, 210, 90), 0)
	round(hpBar, 6)
	hpText = label(hpBack, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "100", Enum.FontSize.Size18)
	local xpBack = frame(gui, UDim2.new(0, 16, 1, -34), UDim2.new(0, 260, 0, 8), rgb(40, 40, 50), 0.2)
	round(xpBack, 4)
	xpBar = frame(xpBack, UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0), ACCENT, 0)
	round(xpBar, 4)
end
local lvlText = label(gui, UDim2.new(0, 16, 1, -56), UDim2.new(0, 260, 0, 20), "", Enum.FontSize.Size18, ACCENT, Enum.TextXAlignment.Left)
local streakText = label(gui, UDim2.new(0, 16, 1, -116), UDim2.new(0, 260, 0, 24), "", Enum.FontSize.Size18, rgb(255, 140, 60), Enum.TextXAlignment.Left)

-- bottom right: ammo, gun, grenades, reload bar
local ammoText = label(gui, UDim2.new(1, -276, 1, -96), UDim2.new(0, 260, 0, 44), "", Enum.FontSize.Size42, Color3.new(1, 1, 1), Enum.TextXAlignment.Right)
local gunText = label(gui, UDim2.new(1, -276, 1, -52), UDim2.new(0, 260, 0, 22), "", Enum.FontSize.Size18, ACCENT, Enum.TextXAlignment.Right)
local nadeText = label(gui, UDim2.new(1, -276, 1, -30), UDim2.new(0, 260, 0, 20), "", Enum.FontSize.Size14, rgb(150, 220, 120), Enum.TextXAlignment.Right)
local reloadBack = frame(gui, UDim2.new(0.5, -80, 0.5, 30), UDim2.new(0, 160, 0, 6), rgb(40, 40, 50), 0.2)
local reloadBar = frame(reloadBack, UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0), ACCENT, 0)
reloadBack.Visible = false

local help = label(gui, UDim2.new(0.5, -400, 1, -20), UDim2.new(0, 800, 0, 18),
	"Click/F shoot | Right click/Q aim | R reload | G grenade | Shift sprint | V camera | X shoulder | Arrows turn | T team | L loadout | P settings | Tab scores",
	Enum.FontSize.Size14, SUB)

-- red flash when you get hurt, white flash (nuke, lightning)
local hurtFlash = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), rgb(200, 0, 0), 1)
pcall(function()
	hurtFlash.ZIndex = 1
end)
local whiteFlash = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Color3.new(1, 1, 1), 1)

-- sniper scope (black around a square hole, with thin lines)
local scope = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Color3.new(0, 0, 0), 1)
frame(scope, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.5, -170), Color3.new(0, 0, 0), 0)
frame(scope, UDim2.new(0, 0, 0.5, 170), UDim2.new(1, 0, 0.5, -170), Color3.new(0, 0, 0), 0)
frame(scope, UDim2.new(0, 0, 0.5, -170), UDim2.new(0.5, -170, 0, 340), Color3.new(0, 0, 0), 0)
frame(scope, UDim2.new(0.5, 170, 0.5, -170), UDim2.new(0.5, -170, 0, 340), Color3.new(0, 0, 0), 0)
frame(scope, UDim2.new(0.5, -170, 0.5, 0), UDim2.new(0, 340, 0, 1), Color3.new(0, 0, 0), 0)
frame(scope, UDim2.new(0.5, 0, 0.5, -170), UDim2.new(0, 1, 0, 340), Color3.new(0, 0, 0), 0)
for i = -4, 4 do
	if i ~= 0 then
		frame(scope, UDim2.new(0.5, i * 34 - 2, 0.5, -2), UDim2.new(0, 4, 0, 4), Color3.new(0, 0, 0), 0)
		frame(scope, UDim2.new(0.5, -2, 0.5, i * 34 - 2), UDim2.new(0, 4, 0, 4), Color3.new(0, 0, 0), 0)
	end
end
frame(scope, UDim2.new(0.5, -170, 0.5, -1), UDim2.new(0, 120, 0, 3), Color3.new(0, 0, 0), 0)
frame(scope, UDim2.new(0.5, 50, 0.5, -1), UDim2.new(0, 120, 0, 3), Color3.new(0, 0, 0), 0)
frame(scope, UDim2.new(0.5, -1, 0.5, 50), UDim2.new(0, 3, 0, 120), Color3.new(0, 0, 0), 0)
scope.Visible = false

------------------------------------------------------------------
-- MENUS
------------------------------------------------------------------
-- PICTURES: the server sends every gun (side view) and map (top view) as rectangles.
-- drawPic fills a box with one, keeping its shape. Returns the inner frame and the bounds.
local drawPic, pic
do
local function nums(str)
	local t = {}
	for v in string.gmatch(str, "[^,]+") do
		table.insert(t, v)
	end
	return t
end
drawPic = function(box, data, isMap, boxW, boxH)
	box:ClearAllChildren()
	if not data or data == "" then
		return nil
	end
	local items = {}
	for item in string.gmatch(data, "[^;]+") do
		table.insert(items, nums(item))
	end
	local x0, y0, x1, y1
	if isMap then
		local b = table.remove(items, 1)
		x0, y0, x1, y1 = tonumber(b[1]), tonumber(b[2]), tonumber(b[3]), tonumber(b[4])
	else
		x0, y0, x1, y1 = 1e9, 1e9, -1e9, -1e9
		for _, r in ipairs(items) do
			x0, y0 = math.min(x0, tonumber(r[1])), math.min(y0, tonumber(r[2]))
			x1, y1 = math.max(x1, tonumber(r[3])), math.max(y1, tonumber(r[4]))
		end
	end
	local w, h = math.max(0.01, x1 - x0), math.max(0.01, y1 - y0)
	-- fit inside the box, same shape
	local sw, sh = 1, 1
	if w / h > boxW / boxH then
		sh = (boxW * h / w) / boxH
	else
		sw = (boxH * w / h) / boxW
	end
	local inner = frame(box, UDim2.new((1 - sw) / 2, 0, (1 - sh) / 2, 0), UDim2.new(sw, 0, sh, 0), DARK, 1)
	for _, r in ipairs(items) do
		if r[1] == "S" then
			local sx, sy = (tonumber(r[2]) - x0) / w, (tonumber(r[3]) - y0) / h
			frame(inner, UDim2.new(sx, -3, sy, -3), UDim2.new(0, 6, 0, 6), r[4] == "red" and rgb(255, 60, 60) or rgb(70, 130, 255), 0)
		else
			local a, b, c, d = tonumber(r[1]), tonumber(r[2]), tonumber(r[3]), tonumber(r[4])
			local col = rgb(tonumber(r[5]) or 128, tonumber(r[6]) or 128, tonumber(r[7]) or 128)
			if isMap then
				frame(inner, UDim2.new((a - x0) / w, 0, (b - y0) / h, 0), UDim2.new((c - a) / w, 1, (d - b) / h, 1), col, 0)
			else
				-- guns: up is up
				frame(inner, UDim2.new((a - x0) / w, 0, 1 - (d - y0) / h, 0), UDim2.new((c - a) / w, 1, (d - b) / h, 1), col, 0)
			end
		end
	end
	return inner, x0, y0, w, h
end
pic = function(name)
	local pics = G:FindFirstChild("Pics")
	local v = pics and pics:FindFirstChild(name)
	return v and v.Value or ""
end
end

-- LOADOUT: primaries | secondaries | picture + stats of the gun under your mouse
local closeMenus -- (closes every menu; defined after all of them)
local loadout = panel(900, 500, "LOADOUT")
local openLoadout, toggleLoadout
do
label(loadout, UDim2.new(0, 14, 0, 44), UDim2.new(0, 240, 0, 22), "PRIMARY", Enum.FontSize.Size18, rgb(120, 200, 255), Enum.TextXAlignment.Left)
label(loadout, UDim2.new(0, 268, 0, 44), UDim2.new(0, 240, 0, 22), "SECONDARY", Enum.FontSize.Size18, rgb(120, 200, 255), Enum.TextXAlignment.Left)
local pickP, pickS = sval("Primary", "M4A1"), sval("Secondary", "M1911")
local gunButtons = {}
local gunInfo = {} -- [name] = stats from the server
local preview = {}
do
	local px = 526
	local box = frame(loadout, UDim2.new(0, px, 0, 48), UDim2.new(0, 360, 0, 392), rgb(32, 36, 50), 0)
	round(box, 10)
	preview.box = frame(box, UDim2.new(0, 10, 0, 10), UDim2.new(0, 340, 0, 130), rgb(55, 60, 78), 0)
	round(preview.box, 8)
	preview.name = label(box, UDim2.new(0, 10, 0, 146), UDim2.new(0, 340, 0, 28), "", Enum.FontSize.Size24, ACCENT)
	preview.kind = label(box, UDim2.new(0, 10, 0, 172), UDim2.new(0, 340, 0, 20), "", Enum.FontSize.Size14, SUB)
	preview.bars = {}
	for i, nm in ipairs({ "DAMAGE", "FIRE RATE", "RANGE", "MOBILITY", "AMMO" }) do
		local y = 200 + (i - 1) * 34
		label(box, UDim2.new(0, 10, 0, y), UDim2.new(0, 100, 0, 20), nm, Enum.FontSize.Size14, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
		local back = frame(box, UDim2.new(0, 110, 0, y + 4), UDim2.new(0, 180, 0, 12), rgb(50, 52, 62), 0)
		round(back, 6)
		local bar = frame(back, UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 1, 0), ACCENT, 0)
		round(bar, 6)
		local num = label(box, UDim2.new(0, 296, 0, y), UDim2.new(0, 56, 0, 20), "", Enum.FontSize.Size14, rgb(200, 205, 215), Enum.TextXAlignment.Right)
		preview.bars[i] = { bar = bar, num = num }
	end
	preview.lock = label(box, UDim2.new(0, 10, 0, 366), UDim2.new(0, 340, 0, 20), "", Enum.FontSize.Size14, rgb(255, 120, 120))
end
local KIND = { pistol = "PISTOL", deagle = "HAND CANNON", revolver = "REVOLVER", rpg = "ROCKET LAUNCHER", smg = "SMG", uzi = "SMG",
	p90 = "SMG", rifle = "ASSAULT RIFLE", ak = "ASSAULT RIFLE", famas = "BURST RIFLE", shotgun = "SHOTGUN", autoshotgun = "AUTO SHOTGUN",
	dmr = "MARKSMAN RIFLE", sniper = "SNIPER RIFLE", barrett = "SNIPER RIFLE", lmg = "LIGHT MACHINE GUN", minigun = "MINIGUN" }
local function showGun(name)
	local g = gunInfo[name]
	if not g then
		return
	end
	drawPic(preview.box, pic("Gun_" .. name), false, 340, 130)
	preview.name.Text = name
	preview.kind.Text = (KIND[g.look] or "") .. "   |   unlocks at level " .. g.level
	local dmg = g.damage * g.pellets
	local vals = {
		{ math.min(1, dmg / 150), tostring(g.pellets > 1 and (g.damage .. " x" .. g.pellets) or g.damage) },
		{ math.min(1, g.rpm / 1100), tostring(g.rpm) },
		{ math.min(1, g.range / 1200), tostring(g.range) },
		{ math.max(0.05, math.min(1, (g.walk - 10) / 9)), tostring(g.walk) },
		{ math.min(1, g.mag / 100), tostring(g.mag) },
	}
	for i, v in ipairs(vals) do
		preview.bars[i].bar.Size = UDim2.new(v[1], 0, 1, 0)
		preview.bars[i].num.Text = v[2]
	end
	local lv = sval("Level", 1)
	preview.lock.Text = (g.level > lv and player:FindFirstChild("SAdmin") == nil) and ("LOCKED: reach level " .. g.level) or ""
end
local function refreshLoadout()
	local lv = sval("Level", 1)
	local admin = player:FindFirstChild("SAdmin") ~= nil
	for _, gb in ipairs(gunButtons) do
		local locked = gb.level > lv and not admin
		local chosen = (gb.slot == "primary" and gb.name == pickP) or (gb.slot == "secondary" and gb.name == pickS)
		gb.button.Text = gb.name .. (locked and ("   (LEVEL " .. gb.level .. ")") or "")
		gb.button.BackgroundColor3 = chosen and PICKED or (locked and rgb(35, 35, 40) or BTN)
		gb.button.TextColor3 = locked and rgb(120, 120, 120) or Color3.new(1, 1, 1)
	end
end
do
	local py, sy = 70, 70
	for _, f in ipairs(lines("GunList")) do
		local name, slot = f[1], f[2]
		if name then
			gunInfo[name] = { level = tonumber(f[3]) or 1, damage = tonumber(f[4]) or 0, rpm = tonumber(f[5]) or 0, range = tonumber(f[6]) or 0,
				mag = tonumber(f[7]) or 0, walk = tonumber(f[8]) or 16, pellets = tonumber(f[9]) or 1, look = f[10] or "" }
		end
		if name and (slot == "primary" or slot == "secondary") then
			local x = slot == "primary" and 14 or 268
			local y = slot == "primary" and py or sy
			local gb = { name = name, slot = slot, level = gunInfo[name].level }
			gb.button = button(loadout, UDim2.new(0, x, 0, y), UDim2.new(0, 240, 0, 24), name, nil, function()
				showGun(name)
				local lv = sval("Level", 1)
				if gb.level > lv and player:FindFirstChild("SAdmin") == nil then
					return
				end
				if slot == "primary" then
					pickP = name
				else
					pickS = name
				end
				refreshLoadout()
			end)
			gb.button.FontSize = Enum.FontSize.Size14
			pcall(function()
				gb.button.MouseEnter:connect(function()
					showGun(name)
				end)
			end)
			table.insert(gunButtons, gb)
			if slot == "primary" then
				py = py + 26
			else
				sy = sy + 26
			end
		end
	end
end
button(loadout, UDim2.new(0.5, -160, 1, -46), UDim2.new(0, 150, 0, 36), "EQUIP", GREEN, function()
	remote:FireServer("loadout", pickP, pickS)
	loadout.Visible = false
end)
modal(button(loadout, UDim2.new(0.5, 10, 1, -46), UDim2.new(0, 150, 0, 36), "CLOSE", rgb(140, 50, 50), function()
	loadout.Visible = false
end))
openLoadout = function()
	closeMenus()
	pickP, pickS = sval("Primary", pickP), sval("Secondary", pickS)
	refreshLoadout()
	showGun(pickP)
	loadout.Visible = true
end
toggleLoadout = function()
	if loadout.Visible then
		loadout.Visible = false
	else
		openLoadout()
	end
end
end

-- TEAMS: everyone's RED / BLUE / AUTO choice (for the counts on the buttons)
local function teamPrefCounts()
	local c = { red = 0, blue = 0, auto = 0 }
	for _, p in ipairs(Players:GetPlayers()) do
		local s = p:FindFirstChild("SData")
		local v = s and s:FindFirstChild("TeamPref")
		local t = v and v.Value or "auto"
		c[t] = (c[t] or 0) + 1
	end
	return c
end
local TEAM_COLOR = { red = RED, blue = BLUE, auto = BTN }
local function pickTeam(t)
	remote:FireServer("team", t)
end

-- VOTE (between matches): map, mode, weather, bots, your team
local vote = panel(1000, 560, "NEXT MATCH: VOTE!")
local voteTime = label(vote, UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 0, 22), "", Enum.FontSize.Size18)
local myVote = {}
local voteButtons = {}
local teamButtons = {}
do
local MAPS, MODES, WEATHERS = lines("MapList"), lines("ModeList"), lines("WeatherList")
local MAP_NAME = {}
for _, m in ipairs(MAPS) do
	MAP_NAME[m[1]] = m[2]
end
local function voteButton(kind, id, name, x, y, w, h)
	local b = button(vote, UDim2.new(0, x, 0, y), UDim2.new(0, w or 230, 0, h or 32), name, nil, function()
		myVote[kind] = id
		remote:FireServer("vote", kind, id)
	end)
	b.FontSize = Enum.FontSize.Size14
	local vb = { b = b, key = kind .. "_" .. id, kind = kind, id = id, name = name }
	table.insert(voteButtons, vb)
	return vb
end
local function header(text, x, y)
	label(vote, UDim2.new(0, x, 0, y), UDim2.new(0, 230, 0, 22), text, Enum.FontSize.Size18, rgb(120, 200, 255), Enum.TextXAlignment.Left)
end
-- column 1: maps (+ a picture of the map under your mouse)
header("MAP", 16, 66)
local mapPreview = frame(vote, UDim2.new(0, 16, 0, 92 + #MAPS * 36), UDim2.new(0, 230, 0, 170), rgb(32, 36, 50), 0)
round(mapPreview, 8)
local mapPreviewName = label(vote, UDim2.new(0, 16, 0, 264 + #MAPS * 36), UDim2.new(0, 230, 0, 18), "", Enum.FontSize.Size14, SUB)
local function showMap(id)
	drawPic(mapPreview, pic("Map_" .. id), true, 230, 170)
	mapPreviewName.Text = (MAP_NAME[id] or id) .. "  (red / blue = spawns)"
end
for i, m in ipairs(MAPS) do
	local vb = voteButton("map", m[1], m[2], 16, 92 + (i - 1) * 36)
	pcall(function()
		vb.b.MouseEnter:connect(function()
			showMap(m[1])
		end)
	end)
	vb.b.MouseButton1Click:connect(function()
		showMap(m[1])
	end)
end
if MAPS[1] then
	showMap(MAPS[1][1])
end
-- column 2: modes (+ what the mode under your mouse is about)
header("MODE", 262, 66)
local modeInfo = label(vote, UDim2.new(0, 262, 0, 100 + #MODES * 36), UDim2.new(0, 230, 0, 120), "", Enum.FontSize.Size14, SUB, Enum.TextXAlignment.Left)
pcall(function()
	modeInfo.TextWrapped = true
	modeInfo.TextYAlignment = Enum.TextYAlignment.Top
end)
for i, m in ipairs(MODES) do
	local vb = voteButton("mode", m[1], m[2], 262, 92 + (i - 1) * 36)
	local function info()
		modeInfo.Text = m[2] .. ": " .. (m[3] or "")
	end
	pcall(function()
		vb.b.MouseEnter:connect(info)
	end)
	vb.b.MouseButton1Click:connect(info)
end
if MODES[1] then
	modeInfo.Text = MODES[1][2] .. ": " .. (MODES[1][3] or "")
end
-- column 3: weather (2 columns) and bots
header("WEATHER", 508, 66)
for i, w in ipairs(WEATHERS) do
	local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
	voteButton("weather", w[1], w[2], 508 + col * 117, 92 + row * 36, 113)
end
local botsY = 92 + math.ceil(#WEATHERS / 2) * 36 + 12
header("BOTS", 508, botsY)
for i, b in ipairs({ { "easy", "EASY BOTS" }, { "medium", "MEDIUM BOTS" }, { "hard", "HARD BOTS" } }) do
	voteButton("bots", b[1], b[2], 508, botsY + 26 + (i - 1) * 36)
end
label(vote, UDim2.new(0, 508, 0, botsY + 136), UDim2.new(0, 230, 0, 36), "Easy: bad aim, 80 HP. Hard: good aim,\nheadshots, 125 HP.", Enum.FontSize.Size14, SUB, Enum.TextXAlignment.Left)
-- column 4: your team
header("YOUR TEAM", 754, 66)
for i, t in ipairs({ { "red", "RED" }, { "auto", "AUTO" }, { "blue", "BLUE" } }) do
	local b = button(vote, UDim2.new(0, 754, 0, 92 + (i - 1) * 44), UDim2.new(0, 230, 0, 38), t[2], TEAM_COLOR[t[1]], function()
		pickTeam(t[1])
	end)
	teamButtons[t[1]] = { b = b, name = t[2] }
end
local teamNote = label(vote, UDim2.new(0, 754, 0, 230), UDim2.new(0, 230, 0, 110),
	"For team modes (TDM, ELIMINATION, KING OF THE HILL). AUTO = the team that needs you. Bots always make the teams even. In a match press T to switch.",
	Enum.FontSize.Size14, SUB, Enum.TextXAlignment.Left)
pcall(function()
	teamNote.TextWrapped = true
	teamNote.TextYAlignment = Enum.TextYAlignment.Top
end)
end
local function refreshTeamButtons(list)
	local c = teamPrefCounts()
	local mine = sval("TeamPref", "auto")
	for id, tb in pairs(list) do
		tb.b.Text = (id == mine and "> " or "") .. tb.name .. "   (" .. (c[id] or 0) .. ")" .. (id == mine and " <" or "")
		pcall(function()
			tb.b.BorderSizePixel = id == mine and 3 or 0
			tb.b.BorderColor3 = Color3.new(1, 1, 1)
		end)
	end
end

-- DEATH screen
local deathBox = frame(gui, UDim2.new(0.5, -260, 0.62, 0), UDim2.new(0, 520, 0, 100), DARK, 0.15)
round(deathBox, 10)
deathBox.Visible = false
local deathText = label(deathBox, UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 30), "", Enum.FontSize.Size24, rgb(255, 90, 90))
local deathSub = label(deathBox, UDim2.new(0, 0, 0, 36), UDim2.new(1, 0, 0, 22), "", Enum.FontSize.Size18)
modal(button(deathBox, UDim2.new(0.5, -190, 1, -34), UDim2.new(0, 180, 0, 28), "CHANGE LOADOUT (L)", PICKED, function()
	openLoadout()
end))
local deathTeamBtn = button(deathBox, UDim2.new(0.5, 10, 1, -34), UDim2.new(0, 180, 0, 28), "SWITCH TEAM (T)", BTN, nil)

-- MATCH END
local endBox = frame(gui, UDim2.new(0.5, -320, 0.3, 0), UDim2.new(0, 640, 0, 110), DARK, 0.1)
round(endBox, 12)
outline(endBox, ACCENT, 2, 0.4)
endBox.Visible = false
local endText = label(endBox, UDim2.new(0, 0, 0, 10), UDim2.new(1, 0, 0, 44), "", Enum.FontSize.Size36, ACCENT)
local endSub = label(endBox, UDim2.new(0, 0, 0, 60), UDim2.new(1, 0, 0, 30), "", Enum.FontSize.Size18)

-- SCOREBOARD (hold Tab, or the SCORES button)
local board = panel(700, 490, "SCOREBOARD")
local refreshBoard
do
local boardTeams = label(board, UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 0, 22), "", Enum.FontSize.Size18)
local boardHead = {}
for _, h in ipairs({ { "PLAYER", 20, 300, Enum.TextXAlignment.Left }, { "SCORE", 330, 70 }, { "KILLS", 410, 60 }, { "DEATHS", 480, 70 }, { "LEVEL", 560, 100 } }) do
	boardHead[h[1]] = label(board, UDim2.new(0, h[2], 0, 64), UDim2.new(0, h[3], 0, 20), h[1], Enum.FontSize.Size14, rgb(150, 160, 180), h[4])
end
local rows = {}
for i = 1, 16 do
	local r = frame(board, UDim2.new(0, 14, 0, 86 + (i - 1) * 24), UDim2.new(1, -28, 0, 22), rgb(40, 44, 58), 0.2)
	round(r, 4)
	rows[i] = {
		frame = r,
		name = label(r, UDim2.new(0, 8, 0, 0), UDim2.new(0, 300, 1, 0), "", Enum.FontSize.Size14, Color3.new(1, 1, 1), Enum.TextXAlignment.Left),
		s = label(r, UDim2.new(0, 316, 0, 0), UDim2.new(0, 70, 1, 0), "", Enum.FontSize.Size14),
		k = label(r, UDim2.new(0, 396, 0, 0), UDim2.new(0, 60, 1, 0), "", Enum.FontSize.Size14),
		d = label(r, UDim2.new(0, 466, 0, 0), UDim2.new(0, 70, 1, 0), "", Enum.FontSize.Size14),
		l = label(r, UDim2.new(0, 546, 0, 0), UDim2.new(0, 100, 1, 0), "", Enum.FontSize.Size14),
	}
end
refreshBoard = function()
	local gungame = gval("Mode", "") == "gungame"
	boardHead.LEVEL.Text = gungame and "GUN" or "LEVEL"
	local total = gval("GunGameGuns", 15)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		local s = p:FindFirstChild("SData")
		local function v(holder, n, d)
			local o = holder and holder:FindFirstChild(n)
			if o then
				return o.Value
			end
			return d
		end
		table.insert(list, { name = p.Name, me = p == player, k = v(ls, "Kills", 0), d = v(ls, "Deaths", 0), s = v(s, "Score", 0),
			l = gungame and (v(s, "GG", 1) .. "/" .. total) or v(s, "Level", 1), t = v(s, "Team", "") })
	end
	local bf = G:FindFirstChild("Bots")
	if bf then
		for _, b in ipairs(bf:GetChildren()) do
			local function v(n, d)
				local o = b:FindFirstChild(n)
				if o then
					return o.Value
				end
				return d
			end
			table.insert(list, { name = b.Name, k = v("Kills", 0), d = v("Deaths", 0), s = v("Score", 0), l = gungame and (v("GG", 1) .. "/" .. total) or "BOT", t = v("Team", "") })
		end
	end
	table.sort(list, function(a, b)
		if a.t ~= b.t then
			return a.t > b.t
		end
		if a.s ~= b.s then
			return a.s > b.s
		end
		return a.k > b.k
	end)
	for i, r in ipairs(rows) do
		local e = list[i]
		r.frame.Visible = e ~= nil
		if e then
			r.name.Text = e.name .. (e.me and "  (you)" or "")
			r.s.Text = tostring(e.s)
			r.k.Text = tostring(e.k)
			r.d.Text = tostring(e.d)
			r.l.Text = tostring(e.l)
			r.frame.BackgroundColor3 = (e.t == "red" and rgb(110, 35, 35)) or (e.t == "blue" and rgb(35, 55, 120)) or rgb(40, 44, 58)
			r.name.TextColor3 = e.me and ACCENT or Color3.new(1, 1, 1)
		end
	end
	if TEAM_MODES[gval("Mode", "")] and gval("State", "") ~= "intermission" then
		boardTeams.Text = "RED " .. gval("RedScore", 0) .. "   -   " .. gval("BlueScore", 0) .. " BLUE"
	else
		boardTeams.Text = gval("ModeName", "") .. "  |  " .. gval("MapName", "")
	end
end
end
local boardHeld = false
local function toggleBoard()
	board.Visible = not board.Visible
	if board.Visible then
		refreshBoard()
	end
end
modal(button(board, UDim2.new(0.5, -60, 1, -36), UDim2.new(0, 120, 0, 28), "CLOSE", rgb(140, 50, 50), function()
	board.Visible = false
end))

-- SETTINGS (P): saved on the server, so they stay next time you play
local CROSS_RGB = { White = rgb(255, 255, 255), Green = rgb(80, 255, 90), Red = rgb(255, 60, 60), Cyan = rgb(60, 230, 255),
	Yellow = rgb(255, 230, 60), Pink = rgb(255, 110, 220) }
local settings = panel(520, 580, "SETTINGS")
local refreshSettings
do
	local CROSS_COLORS = { "White", "Green", "Red", "Cyan", "Yellow", "Pink" }
	local ZOOM_NAMES = { "LOW (2x)", "MEDIUM (4x)", "HIGH (8x)" }
	local rowsS = {}
	local function set(name, value)
		remote:FireServer("settings", name, value)
	end
	local function row(i, title, onMinus, onPlus, onClick)
		local y = 50 + (i - 1) * 46
		label(settings, UDim2.new(0, 20, 0, y), UDim2.new(0, 200, 0, 38), title, Enum.FontSize.Size18, Color3.new(1, 1, 1), Enum.TextXAlignment.Left)
		local r = {}
		if onClick then
			r.value = button(settings, UDim2.new(0, 240, 0, y + 3), UDim2.new(0, 260, 0, 32), "", BTN, onClick)
		else
			button(settings, UDim2.new(0, 240, 0, y + 3), UDim2.new(0, 50, 0, 32), "-", rgb(140, 50, 50), onMinus)
			r.value = label(settings, UDim2.new(0, 295, 0, y + 3), UDim2.new(0, 150, 0, 32), "", Enum.FontSize.Size24, ACCENT)
			button(settings, UDim2.new(0, 450, 0, y + 3), UDim2.new(0, 50, 0, 32), "+", GREEN, onPlus)
		end
		rowsS[i] = r
		return r
	end
	row(1, "FIELD OF VIEW", function()
		set("fov", sval("SetFOV", 70) - 5)
	end, function()
		set("fov", sval("SetFOV", 70) + 5)
	end)
	row(2, "CAMERA (V)", nil, nil, function()
		set("view", sval("SetView", "first") == "first" and "third" or "first")
	end)
	row(3, "SHOULDER (X)", nil, nil, function()
		set("shoulder", sval("SetShoulder", "right") == "right" and "left" or "right")
	end)
	row(4, "AIM BUTTON", nil, nil, function()
		set("aimtoggle", not sval("SetAimToggle", false))
	end)
	row(5, "LOOK SPEED", function()
		set("sens", sval("SetSens", 1) - 0.1)
	end, function()
		set("sens", sval("SetSens", 1) + 0.1)
	end)
	row(6, "SNIPER ZOOM (Z)", nil, nil, function()
		set("zoom", sval("SetZoom", 2) % 3 + 1)
	end)
	row(7, "CROSSHAIR COLOUR", nil, nil, function()
		local cur = sval("SetCross", "White")
		local n = 1
		for i, c in ipairs(CROSS_COLORS) do
			if c == cur then
				n = i % #CROSS_COLORS + 1
			end
		end
		set("cross", CROSS_COLORS[n])
	end)
	row(8, "HIT SOUND", nil, nil, function()
		set("hitsound", not sval("SetHitSound", true))
	end)
	row(9, "MINIMAP", nil, nil, function()
		set("minimap", not sval("SetMinimap", true))
	end)
	row(10, "WEATHER EFFECTS", nil, nil, function()
		set("wfx", not sval("SetWeatherFX", true))
	end)
	modal(button(settings, UDim2.new(0.5, -75, 1, -46), UDim2.new(0, 150, 0, 36), "CLOSE", rgb(140, 50, 50), function()
		settings.Visible = false
	end))
	refreshSettings = function()
		rowsS[1].value.Text = tostring(sval("SetFOV", 70))
		rowsS[2].value.Text = sval("SetView", "first") == "third" and "THIRD PERSON" or "FIRST PERSON"
		rowsS[3].value.Text = sval("SetShoulder", "right") == "left" and "LEFT" or "RIGHT"
		rowsS[4].value.Text = sval("SetAimToggle", false) and "TOGGLE (click once)" or "HOLD"
		rowsS[5].value.Text = string.format("%.1f", sval("SetSens", 1))
		rowsS[6].value.Text = ZOOM_NAMES[sval("SetZoom", 2)] or "MEDIUM (4x)"
		rowsS[7].value.Text = sval("SetCross", "White")
		rowsS[7].value.TextColor3 = CROSS_RGB[sval("SetCross", "White")] or Color3.new(1, 1, 1)
		rowsS[8].value.Text = sval("SetHitSound", true) and "ON" or "OFF"
		rowsS[9].value.Text = sval("SetMinimap", true) and "ON" or "OFF"
		rowsS[10].value.Text = sval("SetWeatherFX", true) and "ON" or "OFF (faster)"
	end
end
local function toggleSettings()
	if settings.Visible then
		settings.Visible = false
	else
		closeMenus()
		settings.Visible = true
		refreshSettings()
	end
end

-- TEAM (T): switch team in a match (or pick one for the next team match)
local teamPanel = panel(460, 250, "PICK YOUR TEAM")
local teamPanelButtons = {}
for i, t in ipairs({ { "red", "RED" }, { "auto", "AUTO" }, { "blue", "BLUE" } }) do
	local b = button(teamPanel, UDim2.new(0, 20 + (i - 1) * 145, 0, 56), UDim2.new(0, 130, 0, 60), t[2], TEAM_COLOR[t[1]], function()
		pickTeam(t[1])
		if t[1] ~= "auto" then
			teamPanel.Visible = false
		end
	end)
	b.FontSize = Enum.FontSize.Size24
	teamPanelButtons[t[1]] = { b = b, name = t[2] }
end
local teamPanelInfo = label(teamPanel, UDim2.new(0, 20, 0, 126), UDim2.new(1, -40, 0, 60), "", Enum.FontSize.Size14, SUB)
pcall(function()
	teamPanelInfo.TextWrapped = true
end)
modal(button(teamPanel, UDim2.new(0.5, -60, 1, -42), UDim2.new(0, 120, 0, 30), "CLOSE", rgb(140, 50, 50), function()
	teamPanel.Visible = false
end))
local function toggleTeam()
	if teamPanel.Visible then
		teamPanel.Visible = false
	else
		closeMenus()
		teamPanel.Visible = true
	end
end
deathTeamBtn.MouseButton1Click:connect(toggleTeam)

closeMenus = function()
	loadout.Visible = false
	settings.Visible = false
	teamPanel.Visible = false
	board.Visible = false
end
local function anyMenu()
	return loadout.Visible or settings.Visible or teamPanel.Visible or board.Visible or vote.Visible
end

-- ACTION BAR (bottom left): every menu has a button too (good for touchpads and touch screens)
local actionBar = frame(gui, UDim2.new(0, 16, 1, -152), UDim2.new(0, 430, 0, 28), DARK, 1)
local changeView -- (defined in VIEW)
for i, a in ipairs({ { "SETTINGS (P)", function()
	toggleSettings()
end }, { "LOADOUT (L)", function()
	toggleLoadout()
end }, { "TEAM (T)", function()
	toggleTeam()
end }, { "SCORES (TAB)", function()
	toggleBoard()
end }, { "CAMERA (V)", function()
	changeView()
end } }) do
	local b = button(actionBar, UDim2.new(0, (i - 1) * 86, 0, 0), UDim2.new(0, 82, 1, 0), a[1], BTN, a[2])
	b.FontSize = Enum.FontSize.Size12
	b.BackgroundTransparency = 0.15
end
button(vote, UDim2.new(0.5, -230, 1, -48), UDim2.new(0, 220, 0, 36), "LOADOUT (L)", PICKED, openLoadout)
button(vote, UDim2.new(0.5, 10, 1, -48), UDim2.new(0, 220, 0, 36), "SETTINGS (P)", BTN, toggleSettings)

-- MINIMAP (top left): the map from above, you (yellow), your team, the hill
local updateMinimap
do
local mini = frame(gui, UDim2.new(0, 16, 0, 16), UDim2.new(0, 190, 0, 190), rgb(20, 22, 30), 0.15)
round(mini, 10)
mini.Visible = false
local miniBox = frame(mini, UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 1, -10), rgb(20, 22, 30), 1)
local miniMap, miniInner, miniX, miniZ, miniW, miniH = nil, nil, 0, 0, 1, 1
local miniDots, miniMe, miniLook, miniHill = {}, nil, nil, nil
local HILL_RGB = { red = rgb(255, 70, 70), blue = rgb(80, 140, 255), contested = rgb(255, 255, 255) }
updateMinimap = function(show)
	mini.Visible = show
	if not show then
		return
	end
	local mapId = gval("Map", "")
	if mapId ~= miniMap then
		miniMap = mapId
		miniInner, miniX, miniZ, miniW, miniH = drawPic(miniBox, pic("Map_" .. mapId), true, 180, 180)
		if miniInner then
			-- the hill, then the dots (drawn last = on top)
			miniHill = frame(miniInner, UDim2.new(0, 0, 0, 0), UDim2.new(0, 10, 0, 10), rgb(255, 230, 60), 0.35)
			round(miniHill, 100)
			miniHill.Visible = false
			miniDots = {}
			for i = 1, 20 do
				miniDots[i] = frame(miniInner, UDim2.new(0, 0, 0, 0), UDim2.new(0, 6, 0, 6), Color3.new(1, 1, 1), 0)
				miniDots[i].Visible = false
			end
			miniLook = frame(miniInner, UDim2.new(0, 0, 0, 0), UDim2.new(0, 4, 0, 4), rgb(255, 230, 40), 0)
			miniMe = frame(miniInner, UDim2.new(0, 0, 0, 0), UDim2.new(0, 8, 0, 8), rgb(255, 230, 40), 0)
		end
	end
	if not miniInner then
		return
	end
	local function place(f, pos, half)
		local sx = math.max(0, math.min(1, (pos.X - miniX) / miniW))
		local sy = math.max(0, math.min(1, (pos.Z - miniZ) / miniH))
		f.Position = UDim2.new(sx, -half, sy, -half)
	end
	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if myRoot then
		place(miniMe, myRoot.Position, 4)
		local look = camera.CoordinateFrame.lookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.magnitude > 0.01 then
			place(miniLook, myRoot.Position + flat.unit * (miniW / 25), 2)
		end
	end
	-- the hill
	local hr = gval("HillR", 0)
	if hr > 0 then
		local px = math.max(6, hr * 2 / miniW * 180)
		miniHill.Size = UDim2.new(0, px, 0, px)
		place(miniHill, gval("HillPos", Vector3.new(0, 0, 0)), px / 2)
		miniHill.BackgroundColor3 = HILL_RGB[gval("HillOwner", "")] or rgb(255, 230, 60)
		miniHill.Visible = true
	else
		miniHill.Visible = false
	end
	-- teammates (players and bots); nobody in free for all
	local myTeam = sval("Team", "")
	local n = 0
	if myTeam ~= "" then
		for _, o in ipairs(Players:GetPlayers()) do
			local osd = o:FindFirstChild("SData")
			local t = osd and osd:FindFirstChild("Team")
			local r = o.Character and o.Character:FindFirstChild("HumanoidRootPart")
			if o ~= player and t and t.Value == myTeam and r and n < #miniDots then
				n = n + 1
				place(miniDots[n], r.Position, 3)
				miniDots[n].BackgroundColor3 = myTeam == "red" and rgb(255, 80, 80) or rgb(90, 150, 255)
				miniDots[n].Visible = true
			end
		end
		local bf = G:FindFirstChild("Bots")
		local bw = game.Workspace:FindFirstChild("ShooterBots")
		if bf and bw then
			for _, m in ipairs(bw:GetChildren()) do
				local info = bf:FindFirstChild(m.Name)
				local r = m:FindFirstChild("HumanoidRootPart")
				local h = m:FindFirstChild("Humanoid")
				if info and info:FindFirstChild("Team") and info.Team.Value == myTeam and r and h and h.Health > 0 and n < #miniDots then
					n = n + 1
					place(miniDots[n], r.Position, 3)
					miniDots[n].BackgroundColor3 = myTeam == "red" and rgb(255, 80, 80) or rgb(90, 150, 255)
					miniDots[n].Visible = true
				end
			end
		end
	end
	for i = n + 1, #miniDots do
		miniDots[i].Visible = false
	end
end
end

gui.Parent = pg
updateScales()

------------------------------------------------------------------
-- GUN HANDLING
------------------------------------------------------------------
local char = player.Character or player.CharacterAdded:wait()
local hum = char:WaitForChild("Humanoid")

local equipped = nil
local firing, aiming, sprinting = false, false, false
local fireLoop = false
local bloom = 0
local lastShot = 0
local zoomLevel = sval("SetZoom", 2) -- sniper zoom: 1 = 2x, 2 = 4x, 3 = 8x (mouse wheel / Z while scoped)
local function isMoving()
	local ok, m = pcall(function()
		return hum.MoveDirection.magnitude > 0.1
	end)
	return ok and m
end
local function baseFOV()
	return sval("SetFOV", 70)
end
local function thirdPerson()
	return sval("SetView", "first") == "third" and gval("State", "") == "playing"
end

local function stat(tool, name, default)
	local s = tool and tool:FindFirstChild("Stats")
	local v = s and s:FindFirstChild(name)
	if v then
		return v.Value
	end
	return default
end

local function setFOV(f)
	pcall(function()
		camera.FieldOfView = f
	end)
end

local function updateSpeed()
	local base = equipped and stat(equipped, "Walk", 16) or 16
	if sprinting and not aiming then
		base = base + 7
	end
	if aiming then
		base = base - 5
	end
	hum.WalkSpeed = base + sval("SpeedBonus", 0)
end

-- field of view while aiming. Snipers have 3 zoom levels; other guns zoom a bit (scaled with your FOV setting)
local function aimFOV()
	local z = stat(equipped, "Zoom", 60)
	if stat(equipped, "Scope", false) then
		local lv = { 34, 17, 8.5 }
		return lv[zoomLevel] or 17
	end
	return z * baseFOV() / 70
end
local scopeZoomText = label(scope, UDim2.new(0.5, 180, 0.5, 140), UDim2.new(0, 170, 0, 24), "", Enum.FontSize.Size18, rgb(120, 255, 120), Enum.TextXAlignment.Left)
local cam3 = { on = false, yaw = 0, pitch = 0 } -- (THIRD PERSON camera, see VIEW)
local function setSens()
	-- slower mouse while zoomed in, so aiming feels the same.
	-- (third person: our own camera reads the mouse, so Roblox's own speed stays at 1)
	pcall(function()
		local sens = sval("SetSens", 1)
		if aiming then
			sens = sens * math.max(0.15, aimFOV() / baseFOV())
		end
		if cam3.on then
			sens = 1
		end
		UIS.MouseDeltaSensitivity = sens
	end)
end
local function setAim(on)
	if on and (not equipped or stat(equipped, "Melee", false) or stat(equipped, "Slot", "") == "grenade") then
		on = false
	end
	aiming = on
	if on then
		setFOV(aimFOV())
		scope.Visible = stat(equipped, "Scope", false)
		scopeZoomText.Text = "ZOOM " .. ({ "2x", "4x", "8x" })[zoomLevel] .. "   (wheel / Z)"
	else
		setFOV(baseFOV())
		scope.Visible = false
	end
	setSens()
	updateSpeed()
end
local function changeZoom(dir)
	zoomLevel = math.max(1, math.min(3, zoomLevel + dir))
	if aiming then
		setAim(true)
	end
end
changeView = function()
	remote:FireServer("settings", "view", sval("SetView", "first") == "first" and "third" or "first")
end

------------------------------------------------------------------
-- VIEW: your gun + arms in front of the camera in first person; THIRD PERSON camera (v6);
-- the aim ray (through the crosshair, ignores your body, the view gun and the weather)
------------------------------------------------------------------
local vmShot -- call when you shoot: kick + muzzle flash
for _, n in ipairs({ "ViewGun", "WeatherFX" }) do
	local o = camera:FindFirstChild(n)
	if o then
		o:Destroy() -- from your last life
	end
end
local vmHolder = Instance.new("Model")
vmHolder.Name = "ViewGun"
vmHolder.Parent = camera
local wfx = Instance.new("Model")
wfx.Name = "WeatherFX"
wfx.Parent = camera
mouse.TargetFilter = vmHolder

-- the ray from the camera through the middle of the crosshair
local aimPoint
do
local function aimRay()
	local ok, o, d = pcall(function()
		local p = dot.AbsolutePosition
		local r = camera:ScreenPointToRay(p.X + 1, p.Y + 1)
		return r.Origin, r.Direction
	end)
	if ok and o then
		return o, d
	end
	local u = mouse.UnitRay
	return u.Origin, u.Direction
end
aimPoint = function()
	local o, d = aimRay()
	local ok, pos = pcall(function()
		local hit, at = game.Workspace:FindPartOnRayWithIgnoreList(Ray.new(o, d * 1500), { char, vmHolder, wfx })
		return at
	end)
	if ok and pos then
		return pos
	end
	return mouse.Hit.p
end
end

do
	local vm = { tool = nil, parts = {}, rel = {}, top = 0.3, kick = 0, flashUntil = 0, muzzleZ = 2 }
	local flash = Instance.new("Part")
	flash.Name = "ViewFlash"
	pcall(function()
		flash.FormFactor = Enum.FormFactor.Custom
	end)
	flash.Size = Vector3.new(0.3, 0.3, 0.6)
	flash.BrickColor = BrickColor.new("New Yeller")
	flash.Anchored = true
	flash.CanCollide = false
	pcall(function()
		flash.Material = Enum.Material.Neon
	end)
	flash.Transparency = 1
	flash.Parent = vmHolder
	local function clear()
		for _, p in ipairs(vm.parts) do
			p:Destroy()
		end
		vm.parts, vm.rel, vm.tool = {}, {}, nil
	end
	local function addPart(p, rel)
		p.Anchored = true
		p.CanCollide = false
		p.Parent = vmHolder
		table.insert(vm.parts, p)
		table.insert(vm.rel, rel)
	end
	-- copy the gun you hold (its parts, without welds) and add two arms
	local function build(tool)
		clear()
		local handle = tool and tool:FindFirstChild("Handle")
		if not handle then
			return
		end
		vm.tool = tool
		vm.top = 0.3
		local inv = handle.CFrame:inverse()
		local function walk(obj)
			for _, c in ipairs(obj:GetChildren()) do
				if c:IsA("BasePart") then
					local copy = c:Clone()
					for _, k in ipairs(copy:GetChildren()) do
						if k:IsA("JointInstance") or k:IsA("Script") or k:IsA("LocalScript") or k:IsA("Light") then
							k:Destroy()
						end
					end
					local rel = inv * c.CFrame
					addPart(copy, rel)
					if math.abs(rel.p.Z) < 1.5 then
						vm.top = math.max(vm.top, math.min(1, rel.p.Y + c.Size.Y / 2))
					end
				end
				if not c:IsA("BasePart") then
					walk(c)
				end
			end
		end
		walk(tool)
		vm.muzzleZ = stat(tool, "MuzzleZ", 2)
		-- arms (skin colour, sleeves in your shirt colour)
		local skin = char:FindFirstChild("Right Arm") and char["Right Arm"].BrickColor or BrickColor.new("Light orange")
		local sleeve = char:FindFirstChild("Torso") and char.Torso.BrickColor or BrickColor.new("Dark stone grey")
		local function arm(color, size, rel)
			local a = Instance.new("Part")
			pcall(function()
				a.FormFactor = Enum.FormFactor.Custom
			end)
			a.Size = size
			a.BrickColor = color
			a.TopSurface = Enum.SurfaceType.Smooth
			a.BottomSurface = Enum.SurfaceType.Smooth
			addPart(a, rel)
		end
		arm(skin, Vector3.new(0.45, 0.45, 1.3), CFrame.new(0.15, -0.45, 0.75) * CFrame.Angles(0.35, 0, 0))
		arm(sleeve, Vector3.new(0.55, 0.55, 1.4), CFrame.new(0.3, -0.85, 1.95) * CFrame.Angles(0.35, 0, 0))
		if not stat(tool, "Melee", false) and stat(tool, "Slot", "") ~= "grenade" then
			arm(skin, Vector3.new(0.45, 0.45, 1.4), CFrame.new(-0.35, -0.35, -0.9) * CFrame.Angles(0.2, -0.6, 0))
			arm(sleeve, Vector3.new(0.55, 0.55, 1.5), CFrame.new(-0.95, -0.65, 0.2) * CFrame.Angles(0.2, -0.6, 0))
		end
	end
	vmShot = function()
		vm.kick = math.min(0.35, vm.kick + 0.12)
		vm.flashUntil = tick() + 0.05
	end

	------------------------------------------------------------------
	-- THIRD PERSON (v6). Roblox's own camera only turns while you HOLD the right mouse button,
	-- which you can't really do on a Chromebook touchpad. So in third person we move the camera
	-- ourselves: the mouse is locked in the middle and just moving it (or sliding a finger on the
	-- touchpad) turns you. The arrow keys turn too, and on a touch screen you drag to look.
	-- When a menu is open the mouse is free so you can click the buttons.
	------------------------------------------------------------------
	local lookKeys = { left = false, right = false, up = false, down = false }
	local camTouches = {} -- touches that started on the right side of a touch screen
	local function look(dx, dy)
		if not cam3.on then
			return
		end
		local s = 0.0055 * sval("SetSens", 1)
		if aiming then
			s = s * math.max(0.15, aimFOV() / baseFOV())
		end
		cam3.yaw = cam3.yaw - dx * s
		cam3.pitch = math.max(-1.35, math.min(1.35, cam3.pitch - dy * s))
	end
	cam3.look = look
	if UIS then
		pcall(function()
			UIS.InputChanged:connect(function(input, gp)
				if not gui.Parent then
					return -- (an old copy of this script from your last life)
				end
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					if not anyMenu() then
						look(input.Delta.X, input.Delta.Y)
					end
				elseif input.UserInputType == Enum.UserInputType.Touch and camTouches[input] then
					look(input.Delta.X * 1.6, input.Delta.Y * 1.6)
				end
			end)
			UIS.InputBegan:connect(function(input, gp)
				if gui.Parent and input.UserInputType == Enum.UserInputType.Touch and not gp then
					local vx = viewSize()
					if input.Position.X > vx * 0.35 then
						camTouches[input] = true
					end
				end
			end)
			UIS.InputEnded:connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then
					camTouches[input] = nil
				end
			end)
		end)
	end
	local function hideBody(hidden)
		for _, c in ipairs(char:GetChildren()) do
			pcall(function()
				if c:IsA("BasePart") then
					c.LocalTransparencyModifier = hidden and 1 or 0
				elseif c:IsA("Accoutrement") or c:IsA("Accessory") then
					c.Handle.LocalTransparencyModifier = hidden and 1 or 0
				end
			end)
		end
	end
	local function cam3Stop()
		if not cam3.on then
			return
		end
		cam3.on = false
		pcall(function()
			camera.CameraType = Enum.CameraType.Custom
		end)
		pcall(function()
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end)
		hideBody(false)
		setSens()
	end
	cam3.stop = cam3Stop
	local function cam3Step(dt, root, head)
		if not cam3.on then
			cam3.on = true
			-- start looking where the camera was looking
			local lv = camera.CoordinateFrame.lookVector
			cam3.yaw = math.atan2(-lv.X, -lv.Z)
			cam3.pitch = math.max(-1, math.min(1, math.asin(math.max(-1, math.min(1, lv.Y)))))
			pcall(function()
				camera.CameraType = Enum.CameraType.Scriptable
			end)
			setSens()
		end
		-- arrow keys turn (good when you have no mouse)
		local turn = 2.4 * dt * math.max(0.4, sval("SetSens", 1))
		if aiming then
			turn = turn * 0.5
		end
		if UIS then
			pcall(function()
				if UIS:IsKeyDown(Enum.KeyCode.Left) then
					cam3.yaw = cam3.yaw + turn
				end
				if UIS:IsKeyDown(Enum.KeyCode.Right) then
					cam3.yaw = cam3.yaw - turn
				end
			end)
		end
		pcall(function()
			UIS.MouseBehavior = anyMenu() and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
		end)
		local focus = root.Position + Vector3.new(0, 1.6, 0)
		local rot = CFrame.new(focus) * CFrame.Angles(0, cam3.yaw, 0) * CFrame.Angles(cam3.pitch, 0, 0)
		local scoped = aiming and stat(equipped, "Scope", false)
		local cf
		if scoped then
			-- looking through a sniper scope: the camera is at your eyes
			cf = CFrame.new(head.Position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, cam3.yaw, 0) * CFrame.Angles(cam3.pitch, 0, 0)
			hideBody(true)
		else
			hideBody(false)
			local side = sval("SetShoulder", "right") == "left" and -1 or 1
			local sx, sy, back = 2.2 * side, 0.8, 9
			if aiming then
				sx, back = 1.7 * side, 5
			end
			local pivot = (rot * CFrame.new(sx * 0.4, sy, 0)).p
			local want = (rot * CFrame.new(sx, sy, back)).p
			-- don't go through walls: stop the camera in front of them
			local ok, hit, at = pcall(function()
				return game.Workspace:FindPartOnRayWithIgnoreList(Ray.new(pivot, want - pivot), { char, vmHolder, wfx })
			end)
			if ok and hit and hit.CanCollide and hit.Transparency < 0.9 then
				local d = (at - pivot)
				want = pivot + d.unit * math.max(0.5, d.magnitude - 0.8)
			end
			cf = CFrame.new(want) * (rot - rot.p)
		end
		camera.CoordinateFrame = cf
		pcall(function()
			camera.Focus = CFrame.new(focus)
		end)
	end
	cam3.recoil = function(up, side)
		cam3.pitch = math.max(-1.35, math.min(1.35, cam3.pitch + up))
		cam3.yaw = cam3.yaw + side
	end

	local gyro = nil
	local t0 = tick()
	local function step(dt)
		if not gui.Parent then
			return
		end
		local cam = camera.CoordinateFrame
		local head = char:FindFirstChild("Head")
		local root = char:FindFirstChild("HumanoidRootPart")
		local alive = hum.Health > 0 and head ~= nil and root ~= nil
		-- THIRD PERSON camera
		local third = thirdPerson() and alive
		if third then
			cam3Step(dt or 1 / 60, root, head)
			cam = camera.CoordinateFrame
		else
			cam3Stop()
		end
		pcall(function()
			hum.CameraOffset = Vector3.new(0, 0, 0)
		end)
		local firstPerson = alive and (cam.p - head.Position).magnitude < 1.6 and not third
		local tool = (equipped and equipped.Parent == char) and equipped or nil
		-- FIRST PERSON gun
		local show = firstPerson and tool ~= nil and not scope.Visible
		if show and vm.tool ~= tool then
			build(tool)
		elseif not tool and vm.tool then
			clear()
		end
		if show and #vm.parts > 0 then
			local now = tick() - t0
			local moving = isMoving()
			local bob = moving and (sprinting and 0.09 or 0.05) or 0.012
			local speed = moving and (sprinting and 12 or 8) or 2
			local bx, by = math.sin(now * speed) * bob, math.abs(math.cos(now * speed)) * bob
			vm.kick = math.max(0, vm.kick - 0.04)
			local off
			if aiming then
				off = CFrame.new(0, -vm.top - 0.02, -1.6 + vm.kick)
				bx, by = bx * 0.2, by * 0.2
			elseif sprinting and moving then
				off = CFrame.new(0.8, -1.0, -1.6) * CFrame.Angles(-0.3, 0.6, 0)
			else
				off = CFrame.new(0.95, -0.95, -1.9 + vm.kick)
			end
			local base = cam * CFrame.new(bx, by, 0) * off * CFrame.Angles(vm.kick * 0.5, 0, 0)
			for i, p in ipairs(vm.parts) do
				p.CFrame = base * vm.rel[i]
				p.Transparency = 0
			end
			flash.CFrame = base * CFrame.new(0, 0.1, -vm.muzzleZ - 0.4)
			flash.Transparency = tick() < vm.flashUntil and 0.1 or 1
			-- hide the real gun (you only see the view gun)
			pcall(function()
				for _, c in ipairs(tool:GetChildren()) do
					if c:IsA("BasePart") then
						c.LocalTransparencyModifier = 1
					end
				end
			end)
		else
			for _, p in ipairs(vm.parts) do
				p.Transparency = 1
			end
			flash.Transparency = 1
			if tool and not firstPerson then
				pcall(function()
					for _, c in ipairs(tool:GetChildren()) do
						if c:IsA("BasePart") then
							c.LocalTransparencyModifier = 0
						end
					end
				end)
			end
		end
		-- third person: your body turns with the camera
		if third and root then
			if not gyro or gyro.Parent ~= root then
				gyro = Instance.new("BodyGyro")
				gyro.Name = "AimGyro"
				pcall(function()
					gyro.MaxTorque = Vector3.new(0, 4e5, 0)
				end)
				pcall(function()
					gyro.maxTorque = Vector3.new(0, 4e5, 0)
				end)
				gyro.P = 20000
				gyro.Parent = root
			end
			gyro.CFrame = CFrame.Angles(0, cam3.yaw, 0)
			pcall(function()
				hum.AutoRotate = false
			end)
		elseif gyro then
			gyro:Destroy()
			gyro = nil
			pcall(function()
				hum.AutoRotate = true
			end)
		end
	end
	-- run right after Roblox's own camera every frame (so ours wins), or every frame on old Roblox
	local ok = pcall(function()
		RunService:UnbindFromRenderStep("ShooterView")
	end)
	ok = pcall(function()
		local last = tick()
		RunService:BindToRenderStep("ShooterView", Enum.RenderPriority.Camera.Value + 1, function()
			local now = tick()
			local dt = math.min(0.1, now - last)
			last = now
			local fine, err = pcall(step, dt)
			if not fine and not cam3.printed then
				cam3.printed = true
				print("[ShooterClient] view: " .. tostring(err))
			end
			if not gui.Parent then
				pcall(function()
					RunService:UnbindFromRenderStep("ShooterView")
				end)
			end
		end)
	end)
	if not ok then
		spawn(function()
			local last = tick()
			while gui.Parent do
				local now = tick()
				pcall(step, math.min(0.1, now - last))
				last = now
				wait()
			end
		end)
	end
	-- if the script is restarted (you respawned), let go of the camera
	gui.AncestryChanged:connect(function()
		if not gui.Parent then
			cam3Stop()
		end
	end)
end

------------------------------------------------------------------
-- WEATHER (v6): rain / thunderstorm / snow / sandstorm falling around your camera.
-- (fog and night are just the lighting, set by the server). Settings > WEATHER EFFECTS turns it off.
------------------------------------------------------------------
local weather = { kind = nil, drops = {}, covered = false, checkAt = 0, slow = 0, nextBolt = tick() + 8 }
do
local FX_OF = { rain = "rain", storm = "storm", snow = "snow", sandstorm = "sand" }
local FX = {
	rain = { n = 110, size = Vector3.new(0.08, 0.08, 2.4), color = "Light blue", trans = 0.45, vel = Vector3.new(0, -95, 0), r = 48, top = 45 },
	storm = { n = 150, size = Vector3.new(0.09, 0.09, 2.8), color = "Light blue", trans = 0.4, vel = Vector3.new(14, -120, 6), r = 48, top = 45 },
	snow = { n = 130, size = Vector3.new(0.3, 0.3, 0.3), color = "Institutional white", trans = 0.1, vel = Vector3.new(1.5, -9, 0.8), r = 45, top = 30, sway = 1.6 },
	sand = { n = 120, size = Vector3.new(0.22, 0.22, 0.5), color = "Brick yellow", trans = 0.25, vel = Vector3.new(48, -3, 18), r = 40, top = 14, sway = 2 },
}
local function clearDrops()
	for _, d in ipairs(weather.drops) do
		d.part:Destroy()
	end
	weather.drops = {}
end
local function randomDropPos(f, cp, anywhere)
	local a = math.random() * math.pi * 2
	local r = math.sqrt(math.random()) * f.r
	local y = anywhere and (cp.Y - 10 + math.random() * (f.top + 10)) or (cp.Y + f.top * (0.6 + math.random() * 0.4))
	if f == FX.sand then
		-- sand blows in from the side
		return cp + Vector3.new(math.cos(a) * r - f.vel.unit.X * f.r * (anywhere and 0 or 0.9), y - cp.Y, math.sin(a) * r - f.vel.unit.Z * f.r * (anywhere and 0 or 0.9))
	end
	return Vector3.new(cp.X + math.cos(a) * r, y, cp.Z + math.sin(a) * r)
end
local function lightning(cp)
	-- a bright flash, a zig-zag bolt somewhere around you, then thunder
	pcall(function()
		local a = math.random() * math.pi * 2
		local base = cp + Vector3.new(math.cos(a) * (80 + math.random() * 120), -15, math.sin(a) * (80 + math.random() * 120))
		local pos = base + Vector3.new(0, 170, 0)
		local bolt = {}
		for i = 1, 7 do
			local nxt = pos + Vector3.new((math.random() - 0.5) * 22, -170 / 7, (math.random() - 0.5) * 22)
			local p = Instance.new("Part")
			pcall(function()
				p.FormFactor = Enum.FormFactor.Custom
			end)
			p.Anchored = true
			p.CanCollide = false
			p.Size = Vector3.new(0.6, 0.6, (nxt - pos).magnitude)
			p.CFrame = CFrame.new((pos + nxt) / 2, nxt)
			p.BrickColor = BrickColor.new("Institutional white")
			pcall(function()
				p.Material = Enum.Material.Neon
			end)
			p.Parent = wfx
			table.insert(bolt, p)
			pos = nxt
		end
		delay(0.18, function()
			for _, p in ipairs(bolt) do
				p:Destroy()
			end
		end)
	end)
	whiteFlash.BackgroundTransparency = 0.6
	delay(0.08, function()
		whiteFlash.BackgroundTransparency = 0.85
	end)
	delay(0.5 + math.random() * 1.2, function()
		pcall(function()
			for _, pitch in ipairs({ 0.22, 0.16 }) do
				local s = Instance.new("Sound")
				s.SoundId = "rbxasset://sounds/collide.wav"
				s.Volume = 0.55
				s.Pitch = pitch
				s.Parent = gui
				s:Play()
				game:GetService("Debris"):AddItem(s, 4)
			end
		end)
	end)
end
local function weatherStep(dt)
	local id = gval("Weather", "clear")
	local kind = nil
	if sval("SetWeatherFX", true) and gval("State", "") == "playing" then
		kind = FX_OF[id]
	end
	if kind ~= weather.kind then
		clearDrops()
		weather.kind = kind
		weather.nextBolt = tick() + 6 + math.random() * 8
	end
	if not kind then
		return
	end
	local f = FX[kind]
	local cp = camera.CoordinateFrame.p
	-- slow computer? use fewer drops
	if dt > 1 / 25 then
		weather.slow = weather.slow + dt
	else
		weather.slow = math.max(0, weather.slow - dt * 0.5)
	end
	local want = f.n
	if weather.slow > 3 then
		want = math.floor(f.n * 0.45)
	end
	while #weather.drops < want do
		local p = Instance.new("Part")
		pcall(function()
			p.FormFactor = Enum.FormFactor.Custom
		end)
		p.Anchored = true
		p.CanCollide = false
		p.Size = f.size
		p.BrickColor = BrickColor.new(f.color)
		pcall(function()
			p.Material = Enum.Material.SmoothPlastic
			p.CastShadow = false
		end)
		p.Transparency = f.trans
		p.Parent = wfx
		table.insert(weather.drops, { part = p, pos = randomDropPos(f, cp, true), ph = math.random() * 6 })
	end
	while #weather.drops > want do
		table.remove(weather.drops).part:Destroy()
	end
	-- under a roof? then no rain on your screen
	local now = tick()
	if now > weather.checkAt then
		weather.checkAt = now + 0.4
		local ok, hit = pcall(function()
			return game.Workspace:FindPartOnRayWithIgnoreList(Ray.new(cp, Vector3.new(0, 80, 0)), { char, vmHolder, wfx })
		end)
		weather.covered = ok and hit ~= nil and hit.CanCollide and hit.Transparency < 0.9
	end
	local vel = f.vel
	for _, d in ipairs(weather.drops) do
		local v = vel
		if f.sway then
			v = v + Vector3.new(math.sin(now * 1.3 + d.ph) * f.sway, 0, math.cos(now * 1.1 + d.ph) * f.sway)
		end
		d.pos = d.pos + v * dt
		local off = d.pos - cp
		if off.Y < -14 or (off.X * off.X + off.Z * off.Z) > f.r * f.r * 1.3 then
			d.pos = randomDropPos(f, cp, false)
		end
		if weather.covered then
			d.part.Transparency = 1
		else
			d.part.Transparency = f.trans
			if kind == "snow" then
				d.part.CFrame = CFrame.new(d.pos)
			else
				d.part.CFrame = CFrame.new(d.pos, d.pos + v)
			end
		end
	end
	-- thunderstorm: lightning now and then
	if kind == "storm" and now > weather.nextBolt then
		weather.nextBolt = now + 7 + math.random() * 12
		lightning(cp)
	end
end
pcall(function()
	RunService:UnbindFromRenderStep("ShooterWeather")
end)
local weatherOk = pcall(function()
	local last = tick()
	RunService:BindToRenderStep("ShooterWeather", Enum.RenderPriority.Camera.Value + 2, function()
		local now = tick()
		local dt = math.min(0.1, now - last)
		last = now
		if gui.Parent then
			pcall(weatherStep, dt)
		else
			clearDrops()
			pcall(function()
				RunService:UnbindFromRenderStep("ShooterWeather")
			end)
		end
	end)
end)
if not weatherOk then
	spawn(function()
		local last = tick()
		while gui.Parent do
			local now = tick()
			pcall(weatherStep, math.min(0.1, now - last))
			last = now
			wait()
		end
		clearDrops()
	end)
end
end

------------------------------------------------------------------
-- SHOOTING
------------------------------------------------------------------
local findGrenade, startFiring, stopFiring, throwGrenade, reload, swapWeapon, aimButton
do
local function recoil(amount)
	if cam3.on then
		cam3.recoil(math.rad(amount * (aiming and 0.5 or 0.8)), math.rad((math.random() - 0.5) * amount * 0.6))
		return
	end
	pcall(function()
		local kick = math.rad(amount * (aiming and 0.5 or 0.8))
		camera.CoordinateFrame = camera.CoordinateFrame * CFrame.Angles(kick, math.rad((math.random() - 0.5) * amount * 0.6), 0)
	end)
end

local function fireOnce(tool)
	local ammo = tool:FindFirstChild("Ammo")
	if not stat(tool, "Melee", false) and ammo and ammo.Value <= 0 then
		remote:FireServer("reload", tool)
		return false
	end
	remote:FireServer("fire", tool, aimPoint(), aiming)
	if vmShot then
		vmShot()
	end
	bloom = math.min(bloom + stat(tool, "Recoil", 1) * 4, 40)
	recoil(stat(tool, "Recoil", 1))
	return true
end

findGrenade = function()
	for _, holder in ipairs({ char, player:FindFirstChild("Backpack") }) do
		if holder then
			for _, t in ipairs(holder:GetChildren()) do
				if t:IsA("Tool") and stat(t, "Slot", "") == "grenade" then
					return t
				end
			end
		end
	end
	return nil
end

startFiring = function()
	local tool = equipped
	if not tool or fireLoop then
		return
	end
	if stat(tool, "Slot", "") == "grenade" then
		remote:FireServer("grenade", tool, aimPoint())
		return
	end
	local rpm = stat(tool, "RPM", 600)
	local interval = 60 / rpm
	local burst = stat(tool, "Burst", 1)
	local auto = stat(tool, "Auto", false)
	if tick() - lastShot < interval then
		return
	end
	firing = true
	fireLoop = true
	spawn(function()
		repeat
			if equipped ~= tool then
				break
			end
			local r = tool:FindFirstChild("Reloading")
			if r and r.Value then
				break
			end
			for i = 1, burst do
				if not fireOnce(tool) then
					break
				end
				lastShot = tick()
				if burst > 1 then
					wait(0.07)
				end
			end
			if burst > 1 then
				wait(math.max(0.05, interval * 3))
			else
				wait(interval)
			end
		until not (firing and auto)
		fireLoop = false
	end)
end
stopFiring = function()
	firing = false
end
throwGrenade = function()
	local g = findGrenade()
	if g then
		-- the grenade has to be in your hand for a moment to throw it
		local was = equipped
		if g.Parent ~= char then
			hum:EquipTool(g)
			wait(0.1)
		end
		remote:FireServer("grenade", g, aimPoint())
		wait(0.2)
		if was and was ~= g and was.Parent then
			hum:EquipTool(was)
		end
	end
end
reload = function()
	if equipped then
		remote:FireServer("reload", equipped)
	end
end
-- the next weapon in your backpack (touch screens)
swapWeapon = function()
	local bp = player:FindFirstChild("Backpack")
	if not bp then
		return
	end
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") and stat(t, "Slot", "") ~= "grenade" then
			hum:EquipTool(t)
			return
		end
	end
end
aimButton = function(down)
	if sval("SetAimToggle", false) then
		if down then
			setAim(not aiming)
		end
	else
		setAim(down)
	end
end

pcall(function()
	mouse.WheelForward:connect(function()
		if gui.Parent and aiming and stat(equipped, "Scope", false) then
			changeZoom(1)
		end
	end)
	mouse.WheelBackward:connect(function()
		if gui.Parent and aiming and stat(equipped, "Scope", false) then
			changeZoom(-1)
		end
	end)
end)
local function lastInputWasTouch()
	local ok, t = pcall(function()
		return UIS:GetLastInputType() == Enum.UserInputType.Touch
	end)
	return ok and t
end
-- (the mouse is the same after you respawn, so every handler first checks that this copy of the
-- script is still the live one: gui.Parent)
mouse.Button1Down:connect(function()
	if not gui.Parent or anyMenu() or lastInputWasTouch() then
		return -- (touch screens shoot with the FIRE button)
	end
	startFiring()
end)
mouse.Button1Up:connect(function()
	if gui.Parent then
		stopFiring()
	end
end)
mouse.Button2Down:connect(function()
	if gui.Parent and not anyMenu() then
		aimButton(true)
	end
end)
mouse.Button2Up:connect(function()
	if gui.Parent then
		aimButton(false)
	end
end)
end

------------------------------------------------------------------
-- KEYS
------------------------------------------------------------------
do
local function onKey(key, down)
	if not gui.Parent then
		return
	end
	if not down then
		if key == "f" then
			stopFiring()
		elseif key == "shift" then
			sprinting = false
			updateSpeed()
		elseif key == "tab" then
			if boardHeld then
				board.Visible = false
				boardHeld = false
			end
		end
		return
	end
	if key == "r" then
		reload()
	elseif key == "g" then
		throwGrenade()
	elseif key == "f" then
		if not anyMenu() then
			startFiring()
		end
	elseif key == "q" then
		setAim(not aiming)
	elseif key == "l" then
		toggleLoadout()
	elseif key == "p" then
		toggleSettings()
	elseif key == "t" then
		toggleTeam()
	elseif key == "v" then
		changeView()
	elseif key == "x" then
		remote:FireServer("settings", "shoulder", sval("SetShoulder", "right") == "right" and "left" or "right")
	elseif key == "z" then
		if aiming and stat(equipped, "Scope", false) then
			changeZoom(zoomLevel % 3 + 1 - zoomLevel)
		else
			remote:FireServer("settings", "zoom", sval("SetZoom", 2) % 3 + 1)
			zoomLevel = sval("SetZoom", 2) % 3 + 1
		end
	elseif key == "shift" then
		sprinting = true
		updateSpeed()
	elseif key == "tab" then
		if not board.Visible then
			closeMenus()
			board.Visible = true
			boardHeld = true
			refreshBoard()
		end
	end
end
local KEYS = {}
local usedUIS = pcall(function()
	for _, k in ipairs({ "R", "G", "F", "Q", "L", "P", "T", "V", "X", "Z", "Tab" }) do
		KEYS[Enum.KeyCode[k]] = string.lower(k)
	end
	KEYS[Enum.KeyCode.LeftShift] = "shift"
	KEYS[Enum.KeyCode.RightShift] = "shift"
	UIS.InputBegan:connect(function(input, gp)
		local k = KEYS[input.KeyCode]
		if k and not gp then
			onKey(k, true)
		end
	end)
	UIS.InputEnded:connect(function(input)
		local k = KEYS[input.KeyCode]
		if k then
			onKey(k, false)
		end
	end)
end)
if not usedUIS then
	-- very old Roblox: the mouse object gives us the keys
	mouse.KeyDown:connect(function(key)
		if string.byte(key) == 48 then
			onKey("shift", true)
		elseif key == "\t" then
			onKey("tab", true)
		else
			onKey(string.lower(key), true)
		end
	end)
	mouse.KeyUp:connect(function(key)
		if string.byte(key) == 48 then
			onKey("shift", false)
		elseif key == "\t" then
			onKey("tab", false)
		else
			onKey(string.lower(key), false)
		end
	end)
end
end

------------------------------------------------------------------
-- TOUCH SCREENS (v6): big buttons on the right
------------------------------------------------------------------
local touchUI = nil
if UIS and UIS.TouchEnabled then
	touchUI = frame(gui, UDim2.new(1, -400, 1, -350), UDim2.new(0, 400, 0, 350), DARK, 1)
	local function tbtn(text, x, y, s, color, down, up)
		local b = button(touchUI, UDim2.new(0, x, 0, y), UDim2.new(0, s, 0, s), text, color, nil)
		round(b, s)
		b.BackgroundTransparency = 0.25
		b.FontSize = s > 80 and Enum.FontSize.Size24 or Enum.FontSize.Size14
		b.MouseButton1Down:connect(down)
		if up then
			b.MouseButton1Up:connect(up)
			pcall(function()
				b.MouseLeave:connect(up)
			end)
		end
		return b
	end
	tbtn("FIRE", 110, 140, 100, rgb(200, 60, 50), startFiring, stopFiring)
	tbtn("AIM", 210, 50, 70, BTN, function()
		setAim(not aiming)
	end)
	tbtn("RELOAD", 290, 50, 70, BTN, reload)
	tbtn("NADE", 110, 50, 70, GREEN, function()
		spawn(throwGrenade)
	end)
	tbtn("SWAP", 30, 50, 70, BTN, swapWeapon)
	help.Text = "Drag on the right side to look. Buttons: FIRE, AIM, RELOAD, NADE (grenade), SWAP (next gun)."
end

-- which tool is in your hand
char.ChildAdded:connect(function(c)
	if c:IsA("Tool") then
		equipped = c
		bloom = 10
		updateSpeed()
	end
end)
char.ChildRemoved:connect(function(c)
	if c == equipped then
		equipped = nil
		firing = false
		setAim(false)
		updateSpeed()
	end
end)
for _, c in ipairs(char:GetChildren()) do
	if c:IsA("Tool") then
		equipped = c
	end
end

------------------------------------------------------------------
-- messages from the server
------------------------------------------------------------------
local hurtFrom = nil
local spectateText = label(gui, UDim2.new(0.5, -200, 0, 92), UDim2.new(0, 400, 0, 26), "", Enum.FontSize.Size24, rgb(150, 220, 255))
local hurtDir = frame(gui, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0, 34, 0, 8), rgb(255, 40, 40), 0.1)
hurtDir.Visible = false
local reloadHint = label(gui, UDim2.new(0.5, -150, 0.5, 92), UDim2.new(0, 300, 0, 24), "PRESS R TO RELOAD", Enum.FontSize.Size18, rgb(255, 120, 90))
reloadHint.Visible = false
if touchUI then
	reloadHint.Text = "TAP RELOAD"
end
local function playSound(id, vol, pitch)
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = vol
		s.Pitch = pitch
		s.Parent = gui
		s:Play()
		game:GetService("Debris"):AddItem(s, 1.5)
	end)
end
remote.OnClientEvent:connect(function(what, a, b, c, d, e, f)
	if not gui.Parent then
		return
	end
	if what == "hit" then
		-- a = headshot, b = killed, c = damage
		hitA.Visible, hitB.Visible = true, true
		local col = b and rgb(255, 60, 60) or (a and rgb(255, 210, 60) or Color3.new(1, 1, 1))
		hitA.BackgroundColor3, hitB.BackgroundColor3 = col, col
		dmgNum.Text = tostring(c or "") .. (a and " HEAD" or "")
		dmgNum.TextColor3 = col
		T.hit = tick() + 0.25
		if sval("SetHitSound", true) then
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.15, b and 1.2 or 2)
		end
	elseif what == "hurt" then
		T.hurt = tick() + 0.35
		-- b = where the shot came from: a red marker around the crosshair points at them
		if b and pcall(function()
			return b.X + b.Z
		end) then
			hurtFrom = b
			T.hurtDir = tick() + 1.2
		end
	elseif what == "feed" then
		-- a = killer, b = victim (or a message), c = gun, d = headshot, e = colour
		if a ~= "" then
			pushFeed(a .. "  [" .. c .. (d and " / HEADSHOT" or "") .. "]  " .. b, e)
		else
			pushFeed(b, e)
		end
	elseif what == "died" then
		T.died = tick()
		deathBox.Visible = true
		if a ~= "" then
			deathText.Text = "KILLED BY " .. a
			deathSub.Text = b .. "  |  " .. tostring(c) .. " studs away  |  they had " .. tostring(d) .. " HP left"
		else
			deathText.Text = "YOU DIED"
			deathSub.Text = ""
		end
		firing = false
		setAim(false)
	elseif what == "killed" then
		-- you got a kill: a = who, b = headshot
		killNotice.Text = (b and "HEADSHOT  " or "ELIMINATED  ") .. tostring(a)
		T.kill = tick() + 2
	elseif what == "medal" then
		table.insert(medals, 1, { text = tostring(a) .. "   +" .. tostring(b), t = tick() })
		while #medals > 3 do
			table.remove(medals)
		end
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.12, 1.5)
	elseif what == "pickup" then
		xpPop.Text = tostring(a)
		xpPop.TextColor3 = rgb(130, 255, 130)
		T.xp = tick() + 1.5
		playSound("rbxasset://sounds/clickfast.wav", 0.3, 1.4)
	elseif what == "big" then
		showBig(a, b, 3)
	elseif what == "xp" then
		xpPop.Text = "+" .. tostring(a) .. " XP  " .. tostring(b)
		xpPop.TextColor3 = rgb(255, 230, 120)
		T.xp = tick() + 1.5
	elseif what == "levelup" then
		showBig("LEVEL UP! You are now level " .. tostring(a), rgb(255, 220, 80), 4)
	elseif what == "matchend" then
		endBox.Visible = true
		endText.Text = tostring(a)
		endSub.Text = (b and b ~= "") and ("MVP: " .. b) or ""
		delay(8, function()
			endBox.Visible = false
		end)
	elseif what == "flash" then
		T.flash = tick() + 1.5
	end
end)

------------------------------------------------------------------
-- the HUD loop
------------------------------------------------------------------
local HILL_TEXT = { red = "RED HOLDS THE HILL", blue = "BLUE HOLDS THE HILL", contested = "HILL CONTESTED!" }
while gui.Parent do
	local now = tick()
	local state = gval("State", "intermission")
	local modeId = gval("Mode", "ffa")
	local myTeam = sval("Team", "")
	if now > T.scale then
		T.scale = now + 1
		updateScales()
	end
	-- top bar
	objective.Text = ""
	if state == "intermission" then
		topMode.Text = "LOBBY  |  next match in"
		topTime.Text = fmtTime(gval("TimeLeft", 0))
		redBox.Visible, blueBox.Visible = false, false
	elseif state == "loading" then
		topMode.Text = "LOADING " .. gval("MapName", "") .. "..."
		topTime.Text = ""
		redBox.Visible, blueBox.Visible = false, false
	else
		local round = gval("Round", 0)
		topMode.Text = gval("ModeName", "") .. "  |  " .. gval("MapName", "") .. "  |  " .. gval("WeatherName", "")
			.. ((modeId == "elim" and round > 0) and ("  |  ROUND " .. round) or "")
			.. ((G:FindFirstChild("Bots") and #G.Bots:GetChildren() > 0) and ("  |  BOTS: " .. string.upper(gval("BotLevel", ""))) or "")
		topTime.Text = fmtTime(gval("TimeLeft", 0))
		redBox.Visible, blueBox.Visible = true, true
		if not TEAM_MODES[modeId] then
			redBox.BackgroundColor3 = rgb(60, 65, 85)
			blueBox.BackgroundColor3 = rgb(160, 110, 30)
			local ls = player:FindFirstChild("leaderstats")
			if modeId == "gungame" then
				redText.Text = "YOU: GUN " .. sval("GG", 1) .. " / " .. gval("GunGameGuns", 15)
			else
				redText.Text = "YOU " .. ((ls and ls:FindFirstChild("Kills")) and ls.Kills.Value or 0) .. " / " .. gval("ScoreLimit", 0)
			end
			redText.FontSize = Enum.FontSize.Size18
			local leader = gval("Leader", "")
			blueText.Text = leader ~= "" and ("1st: " .. leader) or "1st: -"
			blueText.FontSize = Enum.FontSize.Size18
		else
			redBox.BackgroundColor3 = rgb(190, 45, 45)
			blueBox.BackgroundColor3 = rgb(45, 90, 200)
			redText.Text = "RED " .. gval("RedScore", 0) .. (myTeam == "red" and " (you)" or "")
			blueText.Text = "BLUE " .. gval("BlueScore", 0) .. (myTeam == "blue" and " (you)" or "")
			redText.FontSize = Enum.FontSize.Size24
			blueText.FontSize = Enum.FontSize.Size24
		end
		-- the hill / your gun
		if modeId == "koth" and gval("HillR", 0) > 0 then
			local owner = gval("HillOwner", "")
			local txt = HILL_TEXT[owner] or "GO TO THE HILL (yellow beam)"
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local off = root.Position - gval("HillPos", Vector3.new(0, 0, 0))
				local dist = Vector3.new(off.X, 0, off.Z).magnitude
				if dist > gval("HillR", 0) then
					txt = txt .. "   -   " .. math.floor(dist) .. " studs away"
				else
					txt = txt .. "   -   YOU ARE IN THE HILL"
				end
			end
			objective.Text = txt
			objective.TextColor3 = (owner == "red" and rgb(255, 110, 110)) or (owner == "blue" and rgb(120, 170, 255)) or rgb(255, 235, 120)
		elseif modeId == "gungame" and equipped then
			objective.Text = "GUN " .. sval("GG", 1) .. " / " .. gval("GunGameGuns", 15) .. ":  " .. equipped.Name .. "   (every kill = next gun)"
			objective.TextColor3 = rgb(150, 255, 150)
		end
	end
	-- voting panel
	vote.Visible = state == "intermission" and not loadout.Visible and not settings.Visible and not teamPanel.Visible and not board.Visible
	if vote.Visible then
		voteTime.Text = "Starting in " .. fmtTime(gval("TimeLeft", 0))
		local votes = G:FindFirstChild("Votes")
		for _, vb in ipairs(voteButtons) do
			local v = votes and votes:FindFirstChild(vb.key)
			local mine = myVote[vb.kind] == vb.id
			vb.b.Text = (mine and "> " or "") .. vb.name .. "  (" .. (v and v.Value or 0) .. ")"
			vb.b.BackgroundColor3 = mine and PICKED or BTN
		end
		refreshTeamButtons(teamButtons)
	else
		myVote = state == "intermission" and myVote or {}
	end
	if teamPanel.Visible then
		refreshTeamButtons(teamPanelButtons)
		if state == "playing" and TEAM_MODES[modeId] then
			teamPanelInfo.Text = "You are on " .. string.upper(myTeam) .. ". Pick the other team to switch now (you respawn there)." .. (modeId == "elim" and " Elimination: from the next round." or "")
		else
			teamPanelInfo.Text = "This is used in the team modes (TDM, ELIMINATION, KING OF THE HILL). AUTO = the team that needs you."
		end
	end
	deathTeamBtn.Visible = TEAM_MODES[modeId] == true
	if state ~= "playing" then
		deathBox.Visible = false
	end
	actionBar.Visible = true
	if touchUI then
		touchUI.Visible = state == "playing" and hum.Health > 0 and not anyMenu()
	end
	-- health
	local hp = math.max(0, hum.Health)
	local maxHp = math.max(1, hum.MaxHealth)
	hpBar.Size = UDim2.new(hp / maxHp, 0, 1, 0)
	hpBar.BackgroundColor3 = hp / maxHp > 0.5 and rgb(70, 210, 90) or (hp / maxHp > 0.25 and rgb(240, 190, 40) or rgb(230, 50, 50))
	hpText.Text = math.floor(hp) .. " HP"
	-- level / xp / streak
	local lv = sval("Level", 1)
	lvlText.Text = "LEVEL " .. lv .. "   (" .. math.floor(sval("XP", 0)) .. " / " .. math.floor(sval("XPNext", 1000)) .. " XP)"
	xpBar.Size = UDim2.new(math.min(1, sval("XP", 0) / math.max(1, sval("XPNext", 1000))), 0, 1, 0)
	local streak = sval("Streak", 0)
	streakText.Text = streak > 0 and ("KILL STREAK: " .. streak) or ""
	-- ammo
	if equipped and equipped.Parent == char then
		local ammo, res = equipped:FindFirstChild("Ammo"), equipped:FindFirstChild("Reserve")
		if stat(equipped, "Melee", false) then
			ammoText.Text = "KNIFE"
			ammoText.TextColor3 = Color3.new(1, 1, 1)
		elseif stat(equipped, "Slot", "") == "grenade" then
			ammoText.Text = (ammo and ammo.Value or 0) .. " left"
			ammoText.TextColor3 = Color3.new(1, 1, 1)
		else
			ammoText.Text = (ammo and ammo.Value or 0) .. " / " .. (res and res.Value or 0)
			ammoText.TextColor3 = (ammo and ammo.Value <= math.max(1, stat(equipped, "Mag", 30) * 0.25)) and rgb(255, 90, 90) or Color3.new(1, 1, 1)
		end
		gunText.Text = equipped.Name
		local r = equipped:FindFirstChild("Reloading")
		reloadBack.Visible = r ~= nil and r.Value
		if reloadBack.Visible then
			reloadBar.Size = UDim2.new((now * 1.5) % 1, 0, 1, 0)
		end
	else
		ammoText.Text = ""
		gunText.Text = ""
		reloadBack.Visible = false
	end
	local g = findGrenade()
	local gn = g and g:FindFirstChild("Ammo")
	nadeText.Text = g and ("GRENADES: " .. (gn and gn.Value or 0) .. "  (G)") or ""
	-- crosshair (opens up while shooting / moving, closes while aiming)
	bloom = math.max(0, bloom - 1.5)
	local base = equipped and (aiming and stat(equipped, "AdsSpread", 1) or stat(equipped, "Spread", 2)) or 2
	local gap = 4 + base * 4 + bloom
	local showCross = not scope.Visible and state == "playing"
	cross[1].Position, cross[1].Size = UDim2.new(0.5, -1, 0.5, -gap - 10), UDim2.new(0, 2, 0, 10)
	cross[2].Position, cross[2].Size = UDim2.new(0.5, -1, 0.5, gap), UDim2.new(0, 2, 0, 10)
	cross[3].Position, cross[3].Size = UDim2.new(0.5, -gap - 10, 0.5, -1), UDim2.new(0, 10, 0, 2)
	cross[4].Position, cross[4].Size = UDim2.new(0.5, gap, 0.5, -1), UDim2.new(0, 10, 0, 2)
	local cc = CROSS_RGB[sval("SetCross", "White")] or Color3.new(1, 1, 1)
	for i = 1, 4 do
		cross[i].Visible = showCross
		cross[i].BackgroundColor3 = cc
	end
	dot.Visible = showCross
	dot.BackgroundColor3 = cc
	-- your field of view (a little wider while sprinting)
	if not aiming then
		setFOV(baseFOV() + ((sprinting and isMoving()) and 5 or 0))
	end
	-- hit direction marker
	if hurtFrom and now < T.hurtDir then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local lookV = camera.CoordinateFrame.lookVector
			local to = hurtFrom - root.Position
			local a1 = math.atan2(lookV.X, -lookV.Z)
			local a2 = math.atan2(to.X, -to.Z)
			local ang = a2 - a1
			hurtDir.Position = UDim2.new(0.5, math.sin(ang) * 110 - 17, 0.5, -math.cos(ang) * 110 - 4)
			pcall(function()
				hurtDir.Rotation = math.deg(ang)
			end)
			hurtDir.Visible = true
		end
	else
		hurtDir.Visible = false
	end
	-- dead: respawn countdown, or (elimination) watch a living teammate until the next round
	spectateText.Text = ""
	if hum.Health <= 0 and state == "playing" then
		if modeId == "elim" then
			local target, tname = nil, ""
			for _, o in ipairs(Players:GetPlayers()) do
				local osd = o:FindFirstChild("SData")
				local h = o.Character and o.Character:FindFirstChild("Humanoid")
				if o ~= player and osd and osd:FindFirstChild("Team") and osd.Team.Value == myTeam and h and h.Health > 0 then
					target, tname = h, o.Name
				end
			end
			local bf, bw = G:FindFirstChild("Bots"), game.Workspace:FindFirstChild("ShooterBots")
			if not target and bf and bw then
				for _, m in ipairs(bw:GetChildren()) do
					local info = bf:FindFirstChild(m.Name)
					local h = m:FindFirstChild("Humanoid")
					if info and info:FindFirstChild("Team") and info.Team.Value == myTeam and h and h.Health > 0 then
						target, tname = h, m.Name
					end
				end
			end
			if target then
				pcall(function()
					camera.CameraSubject = target
				end)
				spectateText.Text = "SPECTATING " .. tname .. "  (next round soon)"
			else
				spectateText.Text = "WAITING FOR THE NEXT ROUND"
			end
		else
			local left = math.max(0, math.ceil(3 - (now - T.died)))
			spectateText.Text = left > 0 and ("RESPAWNING IN " .. left) or "RESPAWNING..."
		end
	end
	-- empty gun hint
	local am = equipped and equipped:FindFirstChild("Ammo")
	local rl = equipped and equipped:FindFirstChild("Reloading")
	reloadHint.Visible = state == "playing" and am ~= nil and am.Value == 0 and not stat(equipped, "Melee", false) and not (rl and rl.Value)
	-- minimap and settings
	updateMinimap(state == "playing" and sval("SetMinimap", true) and not scope.Visible)
	if settings.Visible then
		refreshSettings()
	end
	-- hitmarker, flashes, messages, medals
	if now > T.hit then
		hitA.Visible, hitB.Visible = false, false
		dmgNum.Text = ""
	end
	hurtFlash.BackgroundTransparency = now < T.hurt and 0.75 or 1
	if now < T.flash then
		whiteFlash.BackgroundTransparency = 0.1 + (1 - (T.flash - now) / 1.5) * 0.9
	elseif whiteFlash.BackgroundTransparency < 1 and weather.kind ~= "storm" then
		whiteFlash.BackgroundTransparency = 1
	elseif weather.kind == "storm" and whiteFlash.BackgroundTransparency < 1 then
		whiteFlash.BackgroundTransparency = math.min(1, whiteFlash.BackgroundTransparency + 0.05)
	end
	big.Visible = now < T.big
	xpPop.Visible = now < T.xp
	killNotice.Visible = now < T.kill
	for i, l in ipairs(medalLabels) do
		local m = medals[i]
		if m and now - m.t < 2.5 then
			l.Text = m.text
			l.Visible = true
		else
			l.Visible = false
		end
	end
	-- kill feed (lines fade after 8 s)
	for i, l in ipairs(feedLines) do
		local e = feed[i]
		if e and now - e.t < 8 then
			l.Text = e.text
			l.TextColor3 = e.color
		else
			l.Text = ""
		end
	end
	if board.Visible then
		refreshBoard()
	end
	wait(0.05)
end
