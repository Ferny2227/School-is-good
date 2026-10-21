-- ServerScriptService.AdminServer: admin commands, usable ONLY by the player named asdasda.
-- 2016-safe: lowercase :connect, ypcall, no TweenService/typeof.
local pcall = ypcall or pcall
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local ADMIN = "asdasda"
local function isAdmin(p) return p and p.Name:lower() == ADMIN end

local remote = RS:FindFirstChild("AdminCmd")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AdminCmd"
	remote.Parent = RS
end

local banned = {}   -- [lowercase name] = reason
local frozen, god = {}, {}
local store
pcall(function() store = game:GetService("DataStoreService"):GetDataStore("AdminBans_v1") end)
local function loadBans()
	if not store then return end
	pcall(function()
		local t = store:GetAsync("bans")
		if type(t) == "table" then for k, v in pairs(t) do banned[k] = v end end
	end)
end
local function saveBans()
	if not store then return end
	pcall(function() store:SetAsync("bans", banned) end)
end
loadBans()

local function find(name)
	name = tostring(name or ""):lower()
	if name == "" then return nil end
	local hit
	for _, p in pairs(Players:GetPlayers()) do
		local n = p.Name:lower()
		if n == name then return p end
		if n:sub(1, #name) == name and not hit then hit = p end
	end
	return hit
end
local function hum(p) local c = p and p.Character return c and c:FindFirstChild("Humanoid") end
local function root(p) local c = p and p.Character return c and (c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart")) end
local function reply(admin, text) pcall(function() remote:FireClient(admin, "msg", text) end) end

local function sendList(admin)
	local names = {}
	for _, p in pairs(Players:GetPlayers()) do table.insert(names, p.Name) end
	local bl = {}
	for k, v in pairs(banned) do table.insert(bl, k) end
	pcall(function() remote:FireClient(admin, "list", names, bl) end)
end

local function applyFreeze(p, on)
	local c = p.Character
	if not c then return end
	for _, part in pairs(c:GetChildren()) do
		if part:IsA("BasePart") then part.Anchored = on end
	end
end

local handlers = {}
function handlers.kick(admin, a, rest)
	local p = find(a)
	if not p then return reply(admin, "No such player: " .. tostring(a)) end
	if isAdmin(p) then return reply(admin, "You can't kick yourself.") end
	local reason = rest ~= "" and rest or "Kicked by admin"
	p:Kick(reason)
	reply(admin, "Kicked " .. p.Name)
end
function handlers.ban(admin, a, rest)
	local p = find(a)
	local name = p and p.Name or tostring(a or "")
	if name == "" then return reply(admin, "Name required.") end
	if name:lower() == ADMIN then return reply(admin, "You can't ban yourself.") end
	banned[name:lower()] = rest ~= "" and rest or "Banned by admin"
	saveBans()
	if p then p:Kick("You are banned: " .. banned[name:lower()]) end
	reply(admin, "Banned " .. name)
end
function handlers.unban(admin, a)
	local k = tostring(a or ""):lower()
	if banned[k] then banned[k] = nil saveBans() reply(admin, "Unbanned " .. k) else reply(admin, k .. " is not banned.") end
end
function handlers.kill(admin, a)
	local p = find(a) local h = hum(p)
	if h then h.Health = 0 reply(admin, "Killed " .. p.Name) else reply(admin, "Can't kill that player.") end
end
function handlers.respawn(admin, a)
	local p = find(a)
	if p then pcall(function() p:LoadCharacter() end) reply(admin, "Respawned " .. p.Name) else reply(admin, "No such player.") end
end
function handlers.heal(admin, a)
	local p = find(a) local h = hum(p)
	if h then h.Health = h.MaxHealth reply(admin, "Healed " .. p.Name) else reply(admin, "No such player.") end
end
function handlers.god(admin, a)
	local p = find(a) local h = hum(p)
	if not h then return reply(admin, "No such player.") end
	god[p.Name] = true h.MaxHealth = math.huge h.Health = math.huge
	reply(admin, "God mode on for " .. p.Name)
end
function handlers.ungod(admin, a)
	local p = find(a) local h = hum(p)
	if not h then return reply(admin, "No such player.") end
	god[p.Name] = nil h.MaxHealth = 100 h.Health = 100
	reply(admin, "God mode off for " .. p.Name)
end
function handlers.freeze(admin, a)
	local p = find(a)
	if not p then return reply(admin, "No such player.") end
	frozen[p.Name] = true applyFreeze(p, true) reply(admin, "Froze " .. p.Name)
end
function handlers.unfreeze(admin, a)
	local p = find(a)
	if not p then return reply(admin, "No such player.") end
	frozen[p.Name] = nil applyFreeze(p, false) reply(admin, "Unfroze " .. p.Name)
end
function handlers.speed(admin, a, rest)
	local p = find(a) local h = hum(p)
	local n = tonumber(rest)
	if h and n then h.WalkSpeed = math.max(0, math.min(n, 500)) reply(admin, p.Name .. " speed " .. n) else reply(admin, "Usage: speed <player> <number>") end
end
function handlers.jump(admin, a, rest)
	local p = find(a) local h = hum(p)
	local n = tonumber(rest)
	if h and n then h.JumpPower = math.max(0, math.min(n, 500)) reply(admin, p.Name .. " jump " .. n) else reply(admin, "Usage: jump <player> <number>") end
end
function handlers.bring(admin, a)
	local p = find(a) local r, ar = root(p), root(admin)
	if r and ar then r.CFrame = ar.CFrame * CFrame.new(3, 0, 0) reply(admin, "Brought " .. p.Name) else reply(admin, "Can't bring that player.") end
end
function handlers.tp(admin, a)
	local p = find(a) local r, ar = root(p), root(admin)
	if r and ar then ar.CFrame = r.CFrame * CFrame.new(3, 0, 0) reply(admin, "Teleported to " .. p.Name) else reply(admin, "Can't teleport to that player.") end
end
function handlers.cash(admin, a, rest)
	local p = find(a)
	local n = tonumber(rest)
	local ls = p and p:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("Cash")
	if c and n then c.Value = c.Value + n reply(admin, "Gave " .. n .. " cash to " .. p.Name) else reply(admin, "Usage: cash <player> <amount>") end
end
function handlers.announce(admin, a, rest)
	local text = (tostring(a or "") .. " " .. rest):gsub("^%s+", "")
	for _, p in pairs(Players:GetPlayers()) do pcall(function() remote:FireClient(p, "announce", text) end) end
end
function handlers.list(admin) sendList(admin) end

remote.OnServerEvent:connect(function(player, cmd, a, rest)
	if not isAdmin(player) then return end  -- everyone else is ignored
	cmd = tostring(cmd or ""):lower()
	rest = tostring(rest or "")
	local fn = handlers[cmd]
	if fn then
		local ok, err = pcall(fn, player, a, rest)
		if not ok then reply(player, "Error: " .. tostring(err)) end
	else
		reply(player, "Unknown command: " .. cmd)
	end
	if cmd ~= "list" then sendList(player) end
end)

local function onChar(p)
	p.CharacterAdded:connect(function(c)
		wait(0.5)
		local h = c:FindFirstChild("Humanoid")
		if god[p.Name] and h then h.MaxHealth = math.huge h.Health = math.huge end
		if frozen[p.Name] then applyFreeze(p, true) end
	end)
end
local function onPlayer(p)
	local reason = banned[p.Name:lower()]
	if reason and not isAdmin(p) then
		wait(0.2)
		p:Kick("You are banned: " .. reason)
		return
	end
	onChar(p)
end
Players.PlayerAdded:connect(onPlayer)
for _, p in pairs(Players:GetPlayers()) do onPlayer(p) end
