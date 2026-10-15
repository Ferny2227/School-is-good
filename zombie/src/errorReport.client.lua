-- ReplicatedFirst.errorReport: shows script errors (yours and the server's) in a box at the bottom of the
-- screen, so they can be screenshotted. Click the box to hide it.
local pcall = ypcall or pcall
local players = game:GetService("Players")
local player = players.LocalPlayer
while not player do wait() player = players.LocalPlayer end
local playerGui = player:WaitForChild("PlayerGui")

local lines = {}
local gui, label

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "errorReport"
	pcall(function() gui.ResetOnSpawn = false end)
	label = Instance.new("TextButton")
	label.Name = "box"
	label.AutoButtonColor = false
	label.Size = UDim2.new(0.5, 0, 0.3, 0)
	label.Position = UDim2.new(0.5, -4, 0.7, -4)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.new(1, 0.45, 0.45)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	pcall(function() label.Font = Enum.Font.SourceSans end)
	if not pcall(function() label.TextSize = 14 end) then pcall(function() label.FontSize = Enum.FontSize.Size14 end) end
	pcall(function() label.ZIndex = 10 end)
	label.Visible = false
	label.Text = ""
	label.MouseButton1Click:connect(function() label.Visible = false end)
	label.Parent = gui
	gui.Parent = playerGui
end
build()

local function add(text)
	text = tostring(text):sub(1, 220)
	for _, l in ipairs(lines) do if l == text then return end end
	table.insert(lines, text)
	while #lines > 8 do table.remove(lines, 1) end
	if not gui.Parent then build() end
	label.Text = "ERRORS (screenshot this, click to hide):\n" .. table.concat(lines, "\n")
	label.Visible = true
	-- stay on top of the other GUIs (old engines draw the last one added on top)
	gui.Parent = nil
	gui.Parent = playerGui
end

pcall(function()
	game:GetService("ScriptContext").Error:connect(function(message, trace, scriptObj)
		local where = ""
		pcall(function() where = " [" .. scriptObj:GetFullName() .. "]" end)
		add("client: " .. tostring(message) .. where)
	end)
end)
pcall(function()
	game:GetService("LogService").MessageOut:connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageError then
			add("client: " .. message)
		elseif tostring(message):find("Infinite yield") or tostring(message):find("failed to load") then
			add("client: " .. message)
		end
	end)
end)
spawn(function()
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("errorReport", 30)
	if remote then
		remote.OnClientEvent:connect(function(message) add("server: " .. tostring(message)) end)
	end
end)
