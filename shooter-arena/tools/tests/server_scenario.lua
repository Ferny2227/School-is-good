local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local remote = Instance.new("RemoteEvent")
remote.Name = "SRemote"
remote.Parent = RS
hookRemote(remote)
makeModule("SConfig", SRC_SConfig, SSS)
makeModule("SGuns", SRC_SGuns, SSS)
makeModule("SMaps", SRC_SMaps, SSS)
runScript("ShooterMain", SRC_ShooterMain, SSS)
local G = RS:FindFirstChild("Game")
assert(G, "no Game folder")
local function gv(n) return G:FindFirstChild(n).Value end
local function fire(p, ...)
	remote.OnServerEvent:Fire(p, ...)
end
local function chat(p, msg) p.Chatted:Fire(msg) end

local function inWorkspace()
	local t = {}
	for _, c in ipairs(workspace:GetChildren()) do table.insert(t, c.Name) end
	return table.concat(t, ",")
end
local function botInfo()
	local bf = G:FindFirstChild("Bots")
	local r, b, n = 0, 0, 0
	for _, f in ipairs(bf:GetChildren()) do
		n = n + 1
		local t = f:FindFirstChild("Team") and f.Team.Value or ""
		if t == "red" then r = r + 1 elseif t == "blue" then b = b + 1 end
	end
	return n, r, b
end
local function sd(p, n) local v = p:FindFirstChild("SData"):FindFirstChild(n) return v and v.Value end
local function status(label)
	local n, r, b = botInfo()
	local pl = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(pl, p.Name .. "[" .. tostring(sd(p, "Team")) .. " pref=" .. tostring(sd(p, "TeamPref")) .. " K" .. p.leaderstats.Kills.Value .. " D" .. p.leaderstats.Deaths.Value .. " GG" .. tostring(sd(p, "GG")) .. " lvl" .. tostring(sd(p, "Level")) .. "]")
	end
	print(string.format("[%6.1f] %-14s state=%s mode=%s map=%s weather=%s time=%s red=%d blue=%d leader=%s bots=%d (r%d b%d) hill=%s %s ws=%s",
		NOW, label, gv("State"), gv("Mode"), gv("Map"), gv("Weather"), tostring(gv("TimeLeft")), gv("RedScore"), gv("BlueScore"), gv("Leader"), n, r, b,
		gv("HillOwner"), table.concat(pl, " "), inWorkspace()))
end

-- players shoot at the closest enemy (like the client would)
local function enemyHeads(p)
	local out = {}
	for _, m in ipairs(workspace:GetDescendants()) do
		if m.ClassName == "Humanoid" and m.Health > 0 and m.Parent ~= p.Character then
			local h = m.Parent:FindFirstChild("Head")
			if h then table.insert(out, h) end
		end
	end
	return out
end
SHOOTING = true
spawn(function()
	while true do
		wait(0.25)
		if SHOOTING then
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local tool = c and c:FindFirstChildOfClass("Tool")
				local root = c and c:FindFirstChild("HumanoidRootPart")
				if tool and root then
					local best, bd = nil, 1e9
					for _, h in ipairs(enemyHeads(p)) do
						local d = (h.Position - root.Position).magnitude
						if d < bd then best, bd = h, d end
					end
					if best then
						-- walk next to them so we can hit (teleport, the test has no real movement)
						if bd > 30 then
							moveModel(c, CFrame.new(best.Position + Vector3.new(0, 0, 12)))
						end
						local a = tool:FindFirstChild("Ammo")
						if a and a.Value <= 0 then
							fire(p, "reload", tool)
						else
							fire(p, "fire", tool, best.Position, math.random() < 0.5)
						end
					end
				end
			end
		end
	end
end)

local function countSent(what)
	local n = 0
	for _, m in ipairs(SENT) do if m.args[1] == what then n = n + 1 end end
	return n
end

----------------------------------------------------------------- 1) join, vote, pick teams
local admin = addPlayer("asdasda")
local kid = addPlayer("Kid1")
runFor(2)
status("joined")
fire(kid, "vote", "map", "desert")
fire(admin, "vote", "map", "desert")
fire(kid, "vote", "mode", "tdm")
fire(kid, "vote", "weather", "rain")
fire(kid, "vote", "bots", "hard")
fire(kid, "team", "red")
fire(admin, "team", "red")
fire(kid, "settings", "aimtoggle", true)
fire(kid, "settings", "shoulder", "left")
fire(kid, "settings", "wfx", false)
fire(kid, "settings", "view", "third")
fire(kid, "loadout", "AK-47", "Glock 18")
print("settings:", sd(kid, "SetAimToggle"), sd(kid, "SetShoulder"), sd(kid, "SetWeatherFX"), sd(kid, "SetView"), sd(kid, "Primary"), sd(kid, "Secondary"))
runFor(20)
status("loading?")
runFor(4)
status("TDM started")
assert(gv("State") == "playing", "match did not start")
assert(gv("Map") == "desert" and gv("Mode") == "tdm" and gv("Weather") == "rain", "votes ignored")
assert(sd(kid, "Team") == "red" and sd(admin, "Team") == "red", "team prefs ignored")
local n, r, b = botInfo()
print("bots", n, r, b, "(2 players on red -> bots should even out)")
assert(r + 2 == b, "teams not even")
local kc = kid.Character
print("kid holds", kc and kc:FindFirstChildOfClass("Tool") and kc:FindFirstChildOfClass("Tool").Name)
runFor(30)
status("TDM 30s")
-- switch team mid match
fire(kid, "team", "blue")
runFor(1)
status("kid -> blue")
n, r, b = botInfo()
assert(sd(kid, "Team") == "blue", "switch failed")
assert(r + 1 == b + 1, "teams not even after switch: bots r" .. r .. " b" .. b)
fire(kid, "team", "red") -- too soon
runFor(30)
status("TDM 60s")
fire(kid, "grenade", kid.Backpack:FindFirstChild("Frag Grenade") or kid.Character:FindFirstChild("Frag Grenade"), kid.Character.Head.Position + Vector3.new(10, 0, 0))
runFor(5)
print("medals sent:", countSent("medal"), "kills msgs:", countSent("killed"), "pickups:", countSent("pickup"), "hits:", countSent("hit"))
chat(admin, ":end")
runFor(2)
status("ended")
print("matchend msgs", countSent("matchend"))

----------------------------------------------------------------- 2) KOTH on harbor in snow (admin)
chat(admin, ":map harbor")
chat(admin, ":mode koth")
chat(admin, ":weather snow")
runFor(10)
chat(admin, ":skip")
runFor(5)
status("KOTH start")
assert(gv("Mode") == "koth" and gv("Map") == "harbor" and gv("Weather") == "snow", "admin choices ignored")
print("hill", tostring(gv("HillPos")), gv("HillR"))
-- stand in the hill
local hp = gv("HillPos")
SHOOTING = false
moveModel(kid.Character, CFrame.new(hp + Vector3.new(0, 3, 0)))
moveModel(admin.Character, CFrame.new(hp + Vector3.new(2, 3, 0)))
runFor(6)
status("in hill 6s")
SHOOTING = true
runFor(70)
status("KOTH 76s")
print("hill moved to", tostring(gv("HillPos")))
chat(admin, ":end")
runFor(10)

----------------------------------------------------------------- 3) GUN GAME on forest at night
chat(admin, ":map forest")
chat(admin, ":mode gungame")
chat(admin, ":weather night")
runFor(5)
chat(admin, ":skip")
runFor(5)
status("GUNGAME start")
assert(gv("Mode") == "gungame", "not gun game")
local head = kid.Character and kid.Character:FindFirstChild("Head")
print("flashlight:", head and head:FindFirstChild("Flashlight") ~= nil)
print("kid tools:", (function() local t = {} for _, x in ipairs(kid.Character:GetChildren()) do if x:IsA("Tool") then table.insert(t, x.Name) end end for _, x in ipairs(kid.Backpack:GetChildren()) do table.insert(t, x.Name) end return table.concat(t, ",") end)())
runFor(90)
status("GUNGAME 90s")
print("kid tools:", (function() local t = {} if kid.Character then for _, x in ipairs(kid.Character:GetChildren()) do if x:IsA("Tool") then table.insert(t, x.Name) end end end for _, x in ipairs(kid.Backpack:GetChildren()) do table.insert(t, x.Name) end return table.concat(t, ",") end)())
runFor(200)
status("GUNGAME 290s")
chat(admin, ":end")
runFor(10)

----------------------------------------------------------------- 4) ELIM on skyline, a player leaves, one joins
chat(admin, ":map skyline")
chat(admin, ":mode elim")
chat(admin, ":weather storm")
runFor(5)
chat(admin, ":skip")
runFor(5)
status("ELIM start")
local kid2 = addPlayer("Kid2")
runFor(2)
status("Kid2 joined")
fire(kid2, "team", "red")
runFor(60)
status("ELIM 60s")
removePlayer(kid2)
runFor(2)
status("Kid2 left")
runFor(120)
status("ELIM 180s")
chat(admin, ":end")
runFor(10)

----------------------------------------------------------------- 5) FFA on nuketown (votes), fog
fire(kid, "vote", "map", "nuketown")
fire(kid, "vote", "mode", "ffa")
fire(kid, "vote", "weather", "fog")
runFor(25)
status("FFA start")
runFor(60)
status("FFA 60s")
chat(admin, ":botfill 4")
runFor(2)
status("botfill 4")
chat(admin, ":nuke")
runFor(6)
status("after nuke")
chat(admin, ":end")
runFor(12)
status("lobby")
-- lobby team pads
local lobbyPads = {}
for _, p in ipairs(workspace.Lobby:GetChildren()) do if p.Name == "TeamPad" then table.insert(lobbyPads, p) end end
lobbyPads[3].Touched:Fire(kid.Character.Head)
runFor(1)
print("pad pref:", sd(kid, "TeamPref"))

print("---------------------------------------------")
print("rays cast:", RAYS, " messages:", #SENT)
local kinds = {}
for _, m in ipairs(SENT) do kinds[m.args[1]] = (kinds[m.args[1]] or 0) + 1 end
local ks = {}
for k, v in pairs(kinds) do table.insert(ks, k .. "=" .. v) end
table.sort(ks)
print(table.concat(ks, " "))
print("ERRORS:", #ERRORS)
for i, e in ipairs(ERRORS) do if i <= 5 then print(e) end end
