-- Fake client pieces (camera, mouse, UserInputService, render steps) on top of server_env.lua
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

camera = Instance.new("Camera")
camera.Name = "Camera"
camera.Parent = workspace
camera.CoordinateFrame = CFrame.new(0, 610, 20)
camera.FieldOfView = 70
camera.CameraType = Enum.CameraType.Custom
camera.ViewportSize = Vector2.new(1366, 768)
workspace.CurrentCamera = camera
rawset(camera, "_get", function(o, k)
	if k == "ScreenPointToRay" or k == "ViewportPointToRay" then
		return function(self, x, y)
			local cf = self.CoordinateFrame
			return { Origin = cf.p, Direction = cf.lookVector }
		end
	end
	if k == "CFrame" then return rawget(o, "_props").CoordinateFrame end
end)

UIS.MouseBehavior = Enum.MouseBehavior.Default
UIS.TouchEnabled = TOUCH or false
UIS.MouseDeltaSensitivity = 1
KEYS_DOWN = {}
rawset(UIS, "_get", function(o, k)
	if k == "IsKeyDown" then return function(self, kc) return KEYS_DOWN[kc] == true end end
	if k == "GetLastInputType" then return function() return Enum.UserInputType.MouseMovement end end
end)

RENDER = {}
rawset(RunService, "_get", function(o, k)
	if k == "BindToRenderStep" then return function(self, name, pr, fn) RENDER[name] = fn end end
	if k == "UnbindFromRenderStep" then return function(self, name) RENDER[name] = nil end end
	if k == "IsClient" then return function() return true end end
end)
spawn(function()
	while true do
		wait(1 / 30)
		for name, fn in pairs(RENDER) do
			local co = coroutine.create(fn)
			local ok, err = coroutine.resume(co)
			if not ok then
				table.insert(ERRORS, "render " .. name .. ": " .. tostring(err))
				print("ERROR render " .. name .. ": " .. tostring(err))
			end
		end
	end
end)

function makeMouse()
	local m = Instance.new("Mouse")
	m.Hit = CFrame.new(0, 600, -50)
	m.UnitRay = { Origin = Vector3.new(0, 610, 0), Direction = Vector3.new(0, 0, -1) }
	m.ViewSizeX = 1366
	m.ViewSizeY = 768
	return m
end

-- the local player gets its mouse; remote messages go both ways
function setupLocal(p, remote, srcClient)
	Players.LocalPlayer = p
	local mouse = makeMouse()
	MOUSE = mouse
	local oldGet = rawget(p, "_get")
	rawset(p, "_get", function(o, k)
		if k == "GetMouse" then return function() return mouse end end
		return oldGet(o, k)
	end)
	-- client -> server
	rawset(remote, "_clientGet", true)
	local hook = rawget(remote, "_get")
	rawset(remote, "_get", function(o, k)
		if k == "FireServer" then
			return function(self, ...)
				CLIENT_SENT = (CLIENT_SENT or 0) + 1
				local args = { ... }
				CLIENT_LOG = CLIENT_LOG or {}
				table.insert(CLIENT_LOG, args[1])
				remote.OnServerEvent:Fire(p, unpack(args, 1, select("#", ...)))
			end
		end
		if k == "FireClient" then
			return function(self, who, ...)
				table.insert(SENT, { to = who, args = { ... } })
				if who == p then remote.OnClientEvent:Fire(...) end
			end
		end
		if k == "FireAllClients" then
			return function(self, ...)
				table.insert(SENT, { to = "all", args = { ... } })
				remote.OnClientEvent:Fire(...)
			end
		end
		return hook and hook(o, k)
	end)
	-- the LocalScript runs again every time you spawn (PlayerGui resets)
	local runs = 0
	local function run()
		runs = runs + 1
		local pg = p:FindFirstChild("PlayerGui")
		for _, g in ipairs(pg:GetChildren()) do
			if g.ClassName == "ScreenGui" then g:Destroy() end
		end
		local s = Instance.new("LocalScript")
		s.Name = "ShooterClient"
		s.Parent = pg
		local fn, err = loadstring(srcClient, "ShooterClient")
		if not fn then error(err) end
		setfenv(fn, setmetatable({ script = s }, { __index = _G, __newindex = _G }))
		local co = coroutine.create(fn)
		local ok, e = coroutine.resume(co)
		if not ok then
			table.insert(ERRORS, "client start: " .. tostring(e) .. "\n" .. debug.traceback(co))
			print("ERROR client start: " .. tostring(e))
			print(debug.traceback(co))
		end
		CLIENT_RUNS = runs
	end
	p.CharacterAdded:connect(function()
		delay(0.05, run)
	end)
	if p.Character then run() end
end

function key(kc, down)
	local input = { KeyCode = Enum.KeyCode[kc], UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(0, 0, 0), Delta = Vector3.new(0, 0, 0) }
	KEYS_DOWN[Enum.KeyCode[kc]] = down
	if down then UIS.InputBegan:Fire(input, false) else UIS.InputEnded:Fire(input, false) end
end
function mouseMove(dx, dy)
	UIS.InputChanged:Fire({ KeyCode = Enum.KeyCode.Unknown, UserInputType = Enum.UserInputType.MouseMovement, Delta = Vector3.new(dx, dy, 0), Position = Vector3.new(683, 384, 0) }, false)
end
function findGui(root, name)
	for _, d in ipairs(root:GetDescendants()) do
		if d.Name == name then return d end
	end
end
function textsVisible(root)
	local t = {}
	for _, d in ipairs(root:GetDescendants()) do
		if (d.ClassName == "TextLabel" or d.ClassName == "TextButton") and d.Text ~= "" then
			local vis = true
			local o = d
			while o and o.ClassName ~= "ScreenGui" do
				if o.Visible == false then vis = false break end
				o = o.Parent
			end
			if vis then table.insert(t, d.Text) end
		end
	end
	return t
end
