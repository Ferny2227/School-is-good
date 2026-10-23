-- StarterGui.WheelieClient: riding (your computer drives you and your bike, so it's smooth), the wheelie balance,
-- the screen (cash, best, speed, the balance meter, the wheelie timer), touch buttons and the GARAGE.
-- Controls: W / Up = gas, S / Down = brake, A / D or Left / Right = steer, hold SPACE (or Shift) = pull a wheelie.
-- 2016-safe: no TweenService/AnchorPoint, FontSize instead of TextSize.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do wait() player = Players.LocalPlayer end
local pg = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("WheelieEvent")
local old = pg:FindFirstChild("WheelieUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "WheelieUI"

local function rgb(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local C = { dark = rgb(15, 18, 28), white = rgb(255, 255, 255), gold = rgb(255, 210, 60), green = rgb(80, 230, 110),
	red = rgb(240, 70, 70), orange = rgb(255, 140, 30), blue = rgb(60, 150, 255), grey = rgb(160, 165, 175) }
local function font(o, n) pcall(function() o.Font = Enum.Font[n] end) end
local function frame(parent, pos, size, color, tr, border)
	local f = Instance.new("Frame")
	f.Position, f.Size = pos, size
	f.BackgroundColor3 = color or C.dark
	f.BackgroundTransparency = tr or 0
	f.BorderSizePixel = border and 3 or 0
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
	local best = 18
	for _, n in ipairs({ 8, 9, 10, 11, 12, 14, 18, 24, 28, 32, 36, 42, 48 }) do if n <= (fs or 18) then best = n end end
	pcall(function() t.FontSize = Enum.FontSize["Size" .. best] end)
	t.Parent = parent
	return t
end
local function button(parent, pos, size, text, color, border, fs)
	local b = Instance.new("TextButton")
	b.Position, b.Size = pos, size
	b.BackgroundColor3 = color or C.dark
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
local function z(o, n) o.ZIndex = n for _, c in ipairs(o:GetChildren()) do if c:IsA("GuiObject") then z(c, n) end end return o end

------------------------------------------------------------------ the screen
local title = label(gui, UDim2.new(0.5, -200, 0, 4), UDim2.new(0, 400, 0, 40), "WHEELIE LIFE", 36, C.orange, "Cartoon")
title.TextStrokeTransparency = 0
local cashL = label(gui, UDim2.new(0, 14, 0, 50), UDim2.new(0, 240, 0, 34), "$0", 32, C.green, "Cartoon")
local bestL = label(gui, UDim2.new(0, 14, 0, 84), UDim2.new(0, 240, 0, 26), "BEST WHEELIE: 0.0s", 18, C.gold)
for _, t in ipairs({ cashL, bestL }) do pcall(function() t.TextXAlignment = Enum.TextXAlignment.Left end) end
-- the wheelie timer (big, top middle)
local wTimer = label(gui, UDim2.new(0.5, -250, 0, 50), UDim2.new(0, 500, 0, 60), "", 48, C.white, "Cartoon")
wTimer.TextStrokeTransparency = 0
local wSub = label(gui, UDim2.new(0.5, -250, 0, 108), UDim2.new(0, 500, 0, 30), "", 24, C.gold, "Cartoon")
local popUntil = 0
-- speed (bottom middle)
local speedBox = frame(gui, UDim2.new(0.5, -90, 1, -96), UDim2.new(0, 180, 0, 80), C.dark, 0.25, C.orange)
local speedL = label(speedBox, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 56), "0", 48, C.white, "Cartoon")
label(speedBox, UDim2.new(0, 0, 0, 52), UDim2.new(1, 0, 0, 24), "MPH", 18, C.grey)
-- the balance meter (right): keep the white line in the GREEN
local meter = frame(gui, UDim2.new(1, -70, 0.5, -150), UDim2.new(0, 34, 0, 300), C.dark, 0.2, C.white)
local zone = frame(meter, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 40), C.green, 0.1)
local danger = frame(meter, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), C.red, 0.1)
local marker = frame(meter, UDim2.new(0, -6, 0, 290), UDim2.new(1, 12, 0, 6), C.white, 0)
label(gui, UDim2.new(1, -110, 0.5, 152), UDim2.new(0, 110, 0, 24), "BALANCE", 18, C.white)
meter.Visible = false
-- buttons
local rideB = button(gui, UDim2.new(0, 14, 1, -84), UDim2.new(0, 170, 0, 64), "RIDE", rgb(30, 110, 50), C.green, 36)
local garageB = button(gui, UDim2.new(0, 14, 0.5, -30), UDim2.new(0, 150, 0, 54), "GARAGE", rgb(120, 60, 10), C.orange, 28)
local help = label(gui, UDim2.new(0.5, -360, 1, -128), UDim2.new(0, 720, 0, 26),
	"W / S = gas & brake   A / D = steer   HOLD SPACE = WHEELIE - keep the line in the green!", 18, C.white)
-- touch buttons (for touch screens)
local touch = {}
local function holdButton(text, pos, size, color, key)
	local b = button(gui, pos, size, text, color, C.white, 24)
	b.BackgroundTransparency = 0.3
	b.MouseButton1Down:connect(function() touch[key] = true end)
	b.MouseButton1Up:connect(function() touch[key] = false end)
	b.MouseLeave:connect(function() touch[key] = false end)
	return b
end
local touchBtns = {
	holdButton("GAS", UDim2.new(1, -230, 1, -100), UDim2.new(0, 100, 0, 84), rgb(30, 120, 50), "gas"),
	holdButton("BRAKE", UDim2.new(1, -340, 1, -100), UDim2.new(0, 100, 0, 84), rgb(140, 30, 30), "brake"),
	holdButton("WHEELIE", UDim2.new(1, -230, 1, -200), UDim2.new(0, 210, 0, 84), rgb(200, 100, 10), "up"),
	holdButton("<", UDim2.new(0, 200, 1, -100), UDim2.new(0, 84, 0, 84), C.dark, "left"),
	holdButton(">", UDim2.new(0, 294, 1, -100), UDim2.new(0, 84, 0, 84), C.dark, "right"),
}
for _, b in ipairs(touchBtns) do b.Visible = false end
-- toasts
local toasts = {}
local TC = { green = C.green, red = C.red, gold = C.gold, white = C.white }
local function toast(text, color)
	local t = label(gui, UDim2.new(0.5, -350, 0, 0), UDim2.new(0, 700, 0, 30), text, 24, TC[color] or C.white, "Cartoon")
	t.TextStrokeTransparency = 0
	table.insert(toasts, 1, { t = t, born = tick() })
	for i = #toasts, 1, -1 do if i > 4 or tick() - toasts[i].born > 5 then toasts[i].t:Destroy() table.remove(toasts, i) end end
	for i, o in ipairs(toasts) do o.t.Position = UDim2.new(0.5, -350, 0, 150 + (i - 1) * 30) end
end

------------------------------------------------------------------ the GARAGE
local owned, equipped = { ["Mini Bike"] = true }, "Mini Bike"
local garage = frame(gui, UDim2.new(0.5, -360, 0.5, -250), UDim2.new(0, 720, 0, 500), C.dark, 0.05, C.orange)
garage.Visible = false
label(garage, UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 44), "GARAGE", 42, C.orange, "Cartoon")
local rows = {}
local function refreshGarage()
	for _, r in ipairs(rows) do r:Destroy() end
	rows = {}
	for i, b in ipairs(BIKES) do
		local row = frame(garage, UDim2.new(0, 20, 0, 58 + (i - 1) * 68), UDim2.new(1, -40, 0, 60), rgb(30, 34, 48), 0)
		table.insert(rows, row)
		local sw = frame(row, UDim2.new(0, 8, 0, 8), UDim2.new(0, 44, 0, 44), BrickColor.new(b.body).Color, 0, BrickColor.new(b.trim).Color)
		local n = label(row, UDim2.new(0, 64, 0, 4), UDim2.new(0, 260, 0, 28), b.name, 28, C.white, "Cartoon")
		local k = label(row, UDim2.new(0, 64, 0, 32), UDim2.new(0, 300, 0, 22), (b.kind == "emoto" and "E-MOTO" or "MINI BIKE") ..
			"   top speed " .. math.floor(b.speed * 0.6) .. " mph   balance " .. (b.bp >= 1.25 and "EASY" or b.bp >= 1.18 and "OK" or "HARD"), 14, C.grey)
		for _, t in ipairs({ n, k }) do pcall(function() t.TextXAlignment = Enum.TextXAlignment.Left end) end
		local txt, col
		if equipped == b.name then txt, col = "RIDING", rgb(60, 60, 70)
		elseif owned[b.name] then txt, col = "USE", rgb(30, 110, 50)
		else txt, col = "BUY $" .. b.price, rgb(160, 90, 10) end
		local bb = button(row, UDim2.new(1, -170, 0, 8), UDim2.new(0, 160, 0, 44), txt, col, nil, 24)
		bb.MouseButton1Click:connect(function() if equipped ~= b.name then remote:FireServer("buy", b.name) end end)
	end
	local close = button(garage, UDim2.new(0.5, -80, 1, -50), UDim2.new(0, 160, 0, 40), "CLOSE", rgb(120, 30, 30), nil, 24)
	table.insert(rows, close)
	close.MouseButton1Click:connect(function() garage.Visible = false end)
	z(garage, 5)
end
refreshGarage()
garageB.MouseButton1Click:connect(function() garage.Visible = not garage.Visible end)

------------------------------------------------------------------ input
local keys = {}
local function setKey(k, down)
	if k == "w" or k == "up" then keys.gas = down
	elseif k == "s" or k == "down" then keys.brake = down
	elseif k == "a" or k == "left" then keys.left = down
	elseif k == "d" or k == "right" then keys.right = down
	elseif k == "space" or k == "shift" then keys.up = down end
end
local mouse = player:GetMouse()
local okUIS = pcall(function()
	local UIS = game:GetService("UserInputService")
	local map = { [Enum.KeyCode.W] = "w", [Enum.KeyCode.Up] = "up", [Enum.KeyCode.S] = "s", [Enum.KeyCode.Down] = "down",
		[Enum.KeyCode.A] = "a", [Enum.KeyCode.Left] = "left", [Enum.KeyCode.D] = "d", [Enum.KeyCode.Right] = "right",
		[Enum.KeyCode.Space] = "space", [Enum.KeyCode.LeftShift] = "shift", [Enum.KeyCode.RightShift] = "shift" }
	UIS.InputBegan:connect(function(i, busy) if map[i.KeyCode] then setKey(map[i.KeyCode], true) end end)
	UIS.InputEnded:connect(function(i) if map[i.KeyCode] then setKey(map[i.KeyCode], false) end end)
end)
if not okUIS then
	local K = { w = "w", s = "s", a = "a", d = "d", [" "] = "space" }
	mouse.KeyDown:connect(function(k) if K[k] then setKey(K[k], true) end end)
	mouse.KeyUp:connect(function(k) if K[k] then setKey(K[k], false) end end)
end
local function held(k) return keys[k] or touch[k] end

------------------------------------------------------------------ riding
local R = nil              -- the ride: bike stats and the simulation state
local ignore = {}
spawn(function()
	while true do
		ignore = {}
		for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
		wait(1)
	end
end)
local function ray(from, dir)
	local ok, part, pos, normal = pcall(function() return workspace:FindPartOnRayWithIgnoreList(Ray.new(from, dir), ignore) end)
	if not ok then ok, part, pos, normal = pcall(function() return workspace:FindPartOnRay(Ray.new(from, dir), player.Character) end) end
	if not ok or not part then return nil end
	if not pos then pos = from + dir * 0.5 end
	return part, pos, normal or Vector3.new(0, 1, 0)
end
local function groundAt(p, fromY)
	local part, pos = ray(Vector3.new(p.X, fromY + 4, p.Z), Vector3.new(0, -60, 0))
	return part and pos.Y or nil
end
local function stopRide()
	if not R then return end
	-- stand the rider up straight on the ground first (being tipped over when the bike goes away made the
	-- character jump up hard while getting back on its feet)
	pcall(function()
		local fwd = Vector3.new(-math.sin(R.yaw), 0, -math.cos(R.yaw))
		local at = R.pos - fwd * (R.b.base / 2 + 1.5)
		local g = groundAt(at, R.y) or R.y
		R.root.CFrame = CFrame.new(at.X, g + 3.2, at.Z) * CFrame.Angles(0, R.yaw, 0)
		R.root.Velocity = Vector3.new()
		R.root.RotVelocity = Vector3.new()
	end)
	for _, n in ipairs({ "RideGyro", "RidePos" }) do
		local o = R.root and R.root:FindFirstChild(n)
		if o then o:Destroy() end
	end
	R = nil
	meter.Visible = false
	for _, b in ipairs(touchBtns) do b.Visible = false end
	rideB.Text = "RIDE"
	wTimer.Text = ""
end
local function startRide(name)
	stopRide()
	local b = BIKE[name]
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if not b or not root then return end
	local origin = root.CFrame * RiderOffset(b):inverse()
	local look = origin.lookVector
	R = { b = b, root = root, pos = Vector3.new(origin.p.X, 0, origin.p.Z), y = origin.p.Y, vy = 0, yaw = math.atan2(-look.X, -look.Z),
		speed = 0, pitch = 0, w = 0, slope = 0, air = false, wt = 0, wdist = 0 }
	local gyro = Instance.new("BodyGyro")
	gyro.Name = "RideGyro"
	gyro.maxTorque = Vector3.new(4e6, 4e6, 4e6)
	gyro.P = 3e4
	gyro.cframe = root.CFrame
	gyro.Parent = root
	local bp = Instance.new("BodyPosition")
	bp.Name = "RidePos"
	bp.maxForce = Vector3.new(4e6, 4e6, 4e6)
	bp.P = 3e4
	bp.D = 1200
	bp.position = root.Position
	bp.Parent = root
	local h = c:FindFirstChild("Humanoid")
	if h then pcall(function() h.PlatformStand = true end) end
	meter.Visible = true
	for _, tb in ipairs(touchBtns) do tb.Visible = true end
	rideB.Text = "GET OFF"
	-- the balance meter: the green zone is the bike's balance point
	local function y(p) return math.floor(300 * (1 - p / 1.5)) end
	zone.Position = UDim2.new(0, 0, 0, y(b.bp + 0.12))
	zone.Size = UDim2.new(1, 0, 0, y(b.bp - 0.12) - y(b.bp + 0.12))
	danger.Size = UDim2.new(1, 0, 0, y(1.38))
end
local function endWheelie()
	if R and R.wt >= 0.8 then remote:FireServer("wheelie", R.wt, R.wdist / R.wt, R.wdist) end
	if R then R.wt, R.wdist = 0, 0 end
end
local function crash(why)
	if not R then return end
	local root = R.root
	local back = Vector3.new(math.sin(R.yaw), 0, math.cos(R.yaw))
	stopRide()
	pcall(function() root.Velocity = back * 10 + Vector3.new(0, 8, 0) end)
	remote:FireServer("crash", why)
	popUntil = tick() + 2
	wTimer.Text = "LOOPED OUT!"
	wTimer.TextColor3 = C.red
	wSub.Text = ""
end
rideB.MouseButton1Click:connect(function()
	if R then
		endWheelie()
		remote:FireServer("off")
	else
		remote:FireServer("ride")
	end
end)

local function step(dt)
	local S = R
	if not S or not S.root.Parent then stopRide() return end
	local b = S.b
	-- gas, brakes, steering
	if held("gas") then S.speed = math.min(b.speed, S.speed + b.accel * dt * (S.speed < 0 and 3 or 1))
	elseif held("brake") then
		if S.speed > 0 then S.speed = math.max(0, S.speed - 45 * dt) else S.speed = math.max(-10, S.speed - 12 * dt) end
	else S.speed = S.speed - S.speed * math.min(1, 0.7 * dt) end
	local steer = (held("left") and 1 or 0) - (held("right") and 1 or 0)
	S.yaw = S.yaw + steer * 1.9 * dt * math.max(-1, math.min(1, S.speed / 12)) * (S.pitch > 0.3 and 0.45 or 1)
	-- the WHEELIE: hold to pull the front up; gravity pulls it back down below the balance point and over the back
	-- above it. Brake to bring it down. Go too far and you loop out.
	-- (past the balance point it tips back slowly, so there's time to save it with the brake)
	local over = S.pitch > b.bp
	local torque = (over and -2 or -4.6) * math.sin(b.bp - S.pitch)
	if held("up") and S.speed > 5 and not S.air then torque = torque + b.lift * math.min(1, 0.45 + S.speed / 30) * (over and 0.35 or 1) end
	if held("gas") and S.pitch > 0.05 then torque = torque + 0.5 end
	if held("brake") and S.pitch > 0 then torque = torque - 7 end
	S.w = S.w + torque * dt
	S.w = S.w - S.w * math.min(1, 2.4 * dt)
	S.pitch = S.pitch + S.w * dt
	if S.pitch <= 0 then S.pitch = 0 if S.w < 0 then S.w = 0 end end
	if S.pitch > 1.48 then crash() return end
	-- move, unless a wall is in the way
	local fwd = Vector3.new(-math.sin(S.yaw), 0, -math.cos(S.yaw))
	local move = fwd * S.speed * dt
	local dirSign = S.speed >= 0 and 1 or -1
	local hit, hitPos, normal = ray(S.pos + Vector3.new(0, S.y + b.r + 1.6, 0) - Vector3.new(0, 0, 0), fwd * dirSign * (math.abs(S.speed * dt) + b.base / 2 + 0.6))
	if hit and normal.Y < 0.55 then
		S.speed = -S.speed * 0.2
		move = Vector3.new()
	end
	S.pos = S.pos + move
	-- the ground under the back and front wheels (ramps tilt the bike; ramp ends launch you)
	local rear = S.pos - fwd * (b.base / 2)
	local front = S.pos + fwd * (b.base / 2)
	local gR = groundAt(rear, S.y) or (S.y - 50)
	local gF = groundAt(front, S.y) or gR
	if S.air then
		S.vy = S.vy - 90 * dt
		S.y = S.y + S.vy * dt
		S.slope = S.slope * (1 - math.min(1, 0.8 * dt))
		if S.y <= gR then S.y, S.vy, S.air = gR, 0, false end
	else
		if gR < S.y - 0.7 then
			S.air = true
			S.vy = math.max(S.vy, 0)
		else
			S.vy = (gR - S.y) / math.max(dt, 0.01)
			S.y = gR
			S.slope = math.max(-0.6, math.min(0.6, math.atan2(gF - gR, b.base)))
		end
	end
	-- score the wheelie (on the ground, front up, moving)
	if S.pitch > 0.2 and S.speed > 6 then
		if not S.air then
			S.wt = S.wt + dt
			S.wdist = S.wdist + S.speed * dt
		end
	elseif S.wt > 0 and S.pitch < 0.08 then
		endWheelie()
	end
	-- place the rider (the bike is welded on): pivot round the back wheel
	local half = b.base / 2
	local base = CFrame.new(S.pos.X, S.y, S.pos.Z) * CFrame.Angles(0, S.yaw, 0) * CFrame.new(0, 0, half) * CFrame.Angles(S.slope + S.pitch, 0, 0) * CFrame.new(0, 0, -half)
	local cf = base * RiderOffset(b)
	local root = S.root
	root.CFrame = cf
	pcall(function()
		root.Velocity = fwd * S.speed + Vector3.new(0, S.air and S.vy or 0, 0)
		root.RotVelocity = Vector3.new()
	end)
	local g, p = root:FindFirstChild("RideGyro"), root:FindFirstChild("RidePos")
	if g then g.cframe = cf end
	if p then p.position = cf.p end
end

------------------------------------------------------------------ the highway traffic (moved on this computer, from the game clock)
local HWX1, HWL, CAR_HOME = -940, 1880, CFrame.new(0, -500, 0)
local cars = {}
local function findCars()
	local w = workspace:FindFirstChild("Wheelie City")
	local tf = w and w:FindFirstChild("Traffic")
	if not tf then return end
	for _, m in ipairs(tf:GetChildren()) do
		local lane = m:FindFirstChild("Lane")
		if lane and not cars[m] then
			local z0, dir, speed, off, len, wid = lane.Value:match("^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+)")
			local parts = {}
			for _, q in ipairs(m:GetChildren()) do
				if q:IsA("BasePart") then table.insert(parts, { q, CAR_HOME:inverse() * q.CFrame }) end
			end
			cars[m] = { z = tonumber(z0), dir = tonumber(dir), speed = tonumber(speed), off = tonumber(off), len = tonumber(len), wid = tonumber(wid), parts = parts }
		end
	end
end
spawn(function() for _ = 1, 30 do pcall(findCars) wait(1) end end)
local function gameTime()
	local ok, t = pcall(function() return workspace.DistributedGameTime end)
	return (ok and t) or tick()
end
local function moveTraffic()
	local t = gameTime()
	for m, cdat in pairs(cars) do
		local d = (t * cdat.speed + cdat.off) % HWL
		local x = cdat.dir > 0 and (HWX1 + d) or (HWX1 + HWL - d)
		local root = CFrame.new(x, 0.3, cdat.z) * CFrame.Angles(0, cdat.dir > 0 and -math.pi / 2 or math.pi / 2, 0)
		cdat.x = x
		for _, pp in ipairs(cdat.parts) do pp[1].CFrame = root * pp[2] end
	end
end
-- a car hits you: off the bike you go
local function hitByCar()
	if not R then return false end
	local p = R.pos
	if R.y > 7 then return false end
	for _, cdat in pairs(cars) do
		if cdat.x and math.abs(p.Z - cdat.z) < cdat.wid / 2 + 1.5 and math.abs(p.X - cdat.x) < cdat.len / 2 + 1.5 then return true end
	end
	return false
end

------------------------------------------------------------------ messages from the server
remote.OnClientEvent:connect(function(what, a, b, c)
	if what == "riding" then
		if a then startRide(a) else stopRide() end
	elseif what == "garage" then
		owned = {}
		for _, n in ipairs(a or {}) do owned[n] = true end
		equipped = b or equipped
		refreshGarage()
	elseif what == "paid" then
		popUntil = tick() + 2.5
		wTimer.TextColor3 = C.green
		wTimer.Text = string.format("%.1fs WHEELIE!", b)
		wSub.Text = "+$" .. a .. (c and "   NEW BEST!" or "")
	elseif what == "toast" then
		toast(a, b)
	end
end)
gui.Parent = pg
remote:FireServer("garage")

local RunService = game:GetService("RunService")
local last = tick()
RunService.RenderStepped:connect(function()
	local now = tick()
	local dt = math.min(0.05, now - last)
	last = now
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Cash") then
		cashL.Text = "$" .. ls.Cash.Value
		bestL.Text = string.format("BEST WHEELIE: %.1fs", ls.Best.Value)
	end
	pcall(moveTraffic)
	if R then
		local ok, err = pcall(step, dt)
		if not ok then stopRide() end
		if R and hitByCar() then
			crash("car")
			wTimer.Text = "HIT BY A CAR!"
		end
	end
	if R then
		speedL.Text = tostring(math.floor(math.abs(R.speed) * 0.6))
		marker.Position = UDim2.new(0, -6, 0, math.floor(300 * (1 - math.min(1.5, R.pitch) / 1.5)) - 3)
		local inZone = math.abs(R.pitch - R.b.bp) < 0.12
		marker.BackgroundColor3 = inZone and C.green or C.white
		if R.wt > 0.3 then
			wTimer.TextColor3 = inZone and C.green or C.white
			wTimer.Text = string.format("%.1fs", R.wt)
			wSub.Text = inZone and "PERFECT BALANCE!" or ""
		elseif now > popUntil then
			wTimer.Text, wSub.Text = "", ""
		end
	else
		speedL.Text = "0"
		if now > popUntil then wTimer.Text, wSub.Text = "", "" end
	end
end)
