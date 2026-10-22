-- StarterGui.OceanClient: the round status bar, disaster announcements, the Dockmaster's boat shop, your boat's
-- health, messages, and the storm (rain and lightning flashes, drawn only on this computer).
-- 2016-safe: no AnchorPoint/TweenService, FontSize instead of TextSize.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do wait() player = Players.LocalPlayer end
local pg = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("OceanEvent")
local old = pg:FindFirstChild("OceanUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "OceanUI"

local function rgb(r, g, b) return Color3.new(r / 255, g / 255, b / 255) end
local C = { dark = rgb(15, 25, 45), panel = rgb(25, 45, 75), white = rgb(255, 255, 255), gold = rgb(255, 210, 70),
	green = rgb(80, 210, 110), red = rgb(230, 70, 70), blue = rgb(60, 140, 240) }
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
	pcall(function() t.FontSize = Enum.FontSize["Size" .. (fs or 18)] end)
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
	pcall(function() b.FontSize = Enum.FontSize.Size18 end)
	b.Parent = parent
	return b
end

-- status bar (top middle)
local bar = frame(gui, UDim2.new(0.5, -200, 0, 4), UDim2.new(0, 400, 0, 40), C.dark, 0.2)
local statusText = label(bar, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "DISASTER OCEAN", 24, C.gold)
-- big announcement
local big = label(gui, UDim2.new(0.5, -400, 0.25, 0), UDim2.new(0, 800, 0, 60), "", 48, C.red)
local sub = label(gui, UDim2.new(0.5, -400, 0.25, 60), UDim2.new(0, 800, 0, 30), "", 24, C.white)
-- toast
local toast = label(gui, UDim2.new(0.5, -300, 0, 50), UDim2.new(0, 600, 0, 28), "", 20, C.green)
local toastId = 0
local function showToast(text, color)
	toastId = toastId + 1
	local id = toastId
	toast.Text = text
	toast.TextColor3 = color == "red" and C.red or (color == "gold" and C.gold or C.green)
	delay(5, function() if toastId == id then toast.Text = "" end end)
end
-- your boat (bottom left)
local boatBox = frame(gui, UDim2.new(0, 10, 1, -110), UDim2.new(0, 230, 0, 60), C.dark, 0.25)
boatBox.Visible = false
local boatName = label(boatBox, UDim2.new(0, 8, 0, 2), UDim2.new(1, -16, 0, 22), "", 18, C.gold)
local hpBack = frame(boatBox, UDim2.new(0, 8, 0, 28), UDim2.new(1, -16, 0, 12), rgb(60, 20, 20))
local hpFill = frame(hpBack, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.green)
local boatInfo = label(boatBox, UDim2.new(0, 8, 0, 40), UDim2.new(1, -16, 0, 18), "", 14, C.white)
-- the boat shop
local shop = frame(gui, UDim2.new(0.5, -210, 0.5, -170), UDim2.new(0, 420, 0, 340), C.panel)
shop.Visible = false
label(shop, UDim2.new(0, 0, 0, 4), UDim2.new(1, 0, 0, 36), "DOCKMASTER - PICK A BOAT", 24, C.gold)
local close = button(shop, UDim2.new(1, -38, 0, 6), UDim2.new(0, 32, 0, 32), "X", C.red)
close.MouseButton1Click:connect(function() shop.Visible = false end)
local shopRows = {}
local function fillShop(list)
	for _, r in ipairs(shopRows) do r:Destroy() end
	shopRows = {}
	for i, b in ipairs(list) do
		local row = frame(shop, UDim2.new(0, 12, 0, 46 + (i - 1) * 70), UDim2.new(1, -24, 0, 62), C.dark)
		label(row, UDim2.new(0, 10, 0, 4), UDim2.new(0, 220, 0, 26), b.key, 24, C.white).TextXAlignment = Enum.TextXAlignment.Left
		label(row, UDim2.new(0, 10, 0, 32), UDim2.new(0, 240, 0, 22), "speed " .. b.speed .. "   health " .. b.hp, 18, rgb(180, 200, 230)).TextXAlignment = Enum.TextXAlignment.Left
		local btn = button(row, UDim2.new(1, -130, 0, 12), UDim2.new(0, 120, 0, 38), b.price == 0 and "FREE" or (b.price .. " Coins"), b.price == 0 and C.green or C.blue)
		btn.MouseButton1Click:connect(function()
			pcall(function() remote:FireServer("buyBoat", b.key) end)
			shop.Visible = false
		end)
		table.insert(shopRows, row)
	end
end
-- lightning flash
local flash = frame(gui, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), C.white, 1)
gui.Parent = pg

------------------------------------------------------------------ rain (only on this computer)
local raining = false
local drops = {}
local function rain(on)
	raining = on
	if not on then
		for _, d in ipairs(drops) do d:Destroy() end
		drops = {}
		return
	end
	spawn(function()
		local folder = Instance.new("Model")
		folder.Name = "Rain"
		folder.Parent = workspace.CurrentCamera
		for i = 1, 70 do
			local d = Instance.new("Part")
			d.Anchored = true
			d.CanCollide = false
			d.Size = Vector3.new(0.2, 4, 0.2)
			d.BrickColor = BrickColor.new("Pastel light blue")
			d.Transparency = 0.4
			d.Parent = folder
			table.insert(drops, d)
		end
		table.insert(drops, folder)
		local t = 0
		while raining do
			local dt = wait(0.05)
			t = t + dt
			local cam = workspace.CurrentCamera
			local c = cam and cam.CoordinateFrame.p or Vector3.new()
			for i, d in ipairs(drops) do
				if d:IsA("BasePart") then
					local x = ((i * 37) % 60) - 30
					local z = ((i * 53) % 60) - 30
					local y = 30 - ((t * 60 + i * 7) % 40)
					d.CFrame = CFrame.new(c.X + x, c.Y + y, c.Z + z) * CFrame.Angles(0.2, 0, 0.1)
				end
			end
		end
	end)
end

------------------------------------------------------------------ messages from the server
local survivorsText = label(gui, UDim2.new(0.5, -300, 0.4, 0), UDim2.new(0, 600, 0, 120), "", 24, C.green)
survivorsText.TextWrapped = true
remote.OnClientEvent:connect(function(what, a, b, c, d)
	if what == "status" then
		if a == "intermission" then statusText.Text = "INTERMISSION - next disaster in " .. b .. "  (get a boat!)"
		elseif a == "disaster" then statusText.Text = c .. "  -  SURVIVE " .. b .. "s"
		else statusText.Text = "ROUND OVER - " .. b end
	elseif what == "disaster" then
		big.Text = a
		sub.Text = b
		survivorsText.Text = ""
		delay(6, function() if big.Text == a then big.Text = "" sub.Text = "" end end)
	elseif what == "survivors" then
		survivorsText.Text = #a > 0 and ("SURVIVORS: " .. table.concat(a, ", ")) or "NOBODY SURVIVED!"
		delay(6, function() survivorsText.Text = "" end)
	elseif what == "toast" then
		showToast(a, b)
	elseif what == "shop" then
		fillShop(a)
		shop.Visible = true
	elseif what == "boat" then
		boatBox.Visible = a ~= nil
		if a then
			boatName.Text = "YOUR " .. string.upper(a)
			local f = c > 0 and b / c or 0
			hpFill.Size = UDim2.new(math.max(0, math.min(1, f)), 0, 1, 0)
			hpFill.BackgroundColor3 = f > 0.5 and C.green or (f > 0.25 and C.gold or C.red)
			boatInfo.Text = "health " .. b .. "/" .. c .. "    speed " .. d
		end
	elseif what == "weather" then
		rain(a == "storm")
	elseif what == "flash" then
		spawn(function()
			flash.BackgroundTransparency = 0.3
			wait(0.08)
			flash.BackgroundTransparency = 0.7
			wait(0.08)
			flash.BackgroundTransparency = 1
		end)
	end
end)
pcall(function() remote:FireServer("state") end)
