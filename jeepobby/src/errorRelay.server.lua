-- ServerScriptService.errorRelay: sends server errors to players' screens (ReplicatedFirst.errorReport).
local pcall = ypcall or pcall
local rs = game:GetService("ReplicatedStorage")
local remote = rs:FindFirstChild("errorReport")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "errorReport"
	remote.Parent = rs
end
local recent = {}
local function send(text)
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
