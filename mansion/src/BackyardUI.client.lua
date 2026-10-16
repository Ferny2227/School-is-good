-- StarterGui.BackyardClient: a BACKYARD button (teleports between the mansion and its backyard), how many of
-- the 100 backyard things you own and what they pay, and a pop-up when you buy something.
-- 2016-safe: no AnchorPoint/TweenService, FontSize instead of TextSize.
local pcall = ypcall or pcall
local player = game:GetService("Players").LocalPlayer
while not player do wait() player = game:GetService("Players").LocalPlayer end
local pg = player:WaitForChild("PlayerGui")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BackyardEvent")
local itemsV = player:WaitForChild("BackyardItems")
local incomeV = player:WaitForChild("BackyardIncome")

local old = pg:FindFirstChild("BackyardUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "BackyardUI"

local function font(o, size)
	pcall(function() o.Font = Enum.Font.SourceSansBold end)
	pcall(function() o.FontSize = Enum.FontSize["Size" .. size] end)
end

local box = Instance.new("Frame")
box.Name = "Box"
box.Position = UDim2.new(0, 8, 0.5, 50)   -- left side, under the Reset button (the chat button lives bottom-left)
box.Size = UDim2.new(0, 210, 0, 88)
box.BackgroundColor3 = Color3.new(0.1, 0.12, 0.16)
box.BackgroundTransparency = 0.25
box.BorderSizePixel = 0
box.Parent = gui

local btn = Instance.new("TextButton")
btn.Name = "Backyard"
btn.Position = UDim2.new(0, 6, 0, 6)
btn.Size = UDim2.new(1, -12, 0, 40)
btn.BackgroundColor3 = Color3.new(0.25, 0.7, 0.3)
btn.BorderSizePixel = 0
btn.Text = "BACKYARD / MANSION"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.ZIndex = 2
font(btn, 18)
btn.Parent = box

local stat = Instance.new("TextLabel")
stat.Name = "Stats"
stat.Position = UDim2.new(0, 6, 0, 50)
stat.Size = UDim2.new(1, -12, 0, 32)
stat.BackgroundTransparency = 1
stat.TextColor3 = Color3.new(1, 0.85, 0.3)
stat.TextWrapped = true
stat.ZIndex = 2
font(stat, 14)
stat.Parent = box

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Position = UDim2.new(0.5, -220, 0, 70)
toast.Size = UDim2.new(0, 440, 0, 40)
toast.BackgroundColor3 = Color3.new(0.1, 0.12, 0.16)
toast.BackgroundTransparency = 0.3
toast.BorderSizePixel = 0
toast.TextColor3 = Color3.new(0.5, 1, 0.5)
toast.Visible = false
toast.ZIndex = 3
font(toast, 24)
toast.Parent = gui

local function money(n)
	local s = tostring(math.floor(n))
	local out = ""
	while #s > 3 do out = "," .. s:sub(-3) .. out s = s:sub(1, -4) end
	return "$" .. s .. out
end
local function refresh()
	local owns = player:FindFirstChild("Tycoon")
	if owns and owns.Value == 0 then
		stat.Text = "Touch \"Become Owner\" at a mansion to get one!"
	elseif itemsV.Value == 0 then
		stat.Text = "Go to your backyard and step on the GOLD pads to buy!"
	else
		stat.Text = "Backyard: " .. itemsV.Value .. "/100 things  |  +" .. money(incomeV.Value) .. "/s"
	end
end
itemsV.Changed:connect(refresh)
spawn(function()
	local owns = player:WaitForChild("Tycoon", 30)
	if owns then owns.Changed:connect(refresh) refresh() end
end)
incomeV.Changed:connect(refresh)
refresh()

local n = 0
remote.OnClientEvent:connect(function(what, text)
	if what ~= "bought" then return end
	n = n + 1
	local my = n
	toast.Text = tostring(text)
	toast.TextColor3 = (tostring(text):sub(1, 6) == "Bought") and Color3.new(0.5, 1, 0.5) or Color3.new(1, 0.6, 0.4)
	toast.Visible = true
	delay(2.5, function() if n == my then toast.Visible = false end end)
end)

btn.MouseButton1Click:connect(function()
	pcall(function() remote:FireServer("tp") end)
end)

gui.Parent = pg
