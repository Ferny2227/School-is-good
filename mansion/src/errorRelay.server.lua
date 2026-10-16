-- ServerScriptService.errorRelay: sends server errors to players' screens (ReplicatedFirst.errorReport).
local pcall = ypcall or pcall
local rs = game:GetService("ReplicatedStorage")
local remote = rs:FindFirstChild("errorReport")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "errorReport"
	remote.Parent = rs
end
-- missing sounds/textures/meshes on the server (HTTP 404 etc.) are harmless: don't show them
local function harmless(text)
	text = tostring(text)
	return text:find("Content failed") or text:find("HTTP 404") or text:find("Failed to load sound")
		or text:find("Image failed") or text:find("Mesh failed") or text:find("asset") and text:find("HTTP")
end
local recent = {}
local function send(text)
	if harmless(text) then return end
	text = tostring(text):sub(1, 220)
	if recent[text] then return end
	recent[text] = true
	table.insert(recent, text)
	pcall(function() remote:FireAllClients(text) end)
end
pcall(function()
	game:GetService("ScriptContext").Error:connect(function(message, trace, scriptObj)
		local where = ""
		pcall(function() where = " [" .. scriptObj:GetFullName() .. "]" end)
		send(tostring(message) .. where)
	end)
end)
pcall(function()
	game:GetService("LogService").MessageOut:connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageError or tostring(message):find("Infinite yield") then
			send(message)
		end
	end)
end)
-- players who join later still see what went wrong
game:GetService("Players").PlayerAdded:connect(function(player)
	wait(8)
	for _, text in ipairs(recent) do
		pcall(function() remote:FireClient(player, text) end)
	end
end)
