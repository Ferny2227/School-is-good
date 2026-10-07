local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local remote = Instance.new("RemoteEvent")
remote.Name = "SRemote"
remote.Parent = RS
hookRemote(remote)
makeModule("SConfig", SRC_SConfig, SSS)
makeModule("SGuns", SRC_SGuns, SSS)
makeModule("SMaps", SRC_SMaps, SSS)
runScript("ShooterMain", SRC_ShooterMain, SSS)
local G = RS:FindFirstChild("Game")
local function gv(n) return G:FindFirstChild(n).Value end

local me = addPlayer("Kid1")
setupLocal(me, remote, SRC_ShooterClient)
runFor(3)
local pg = me.PlayerGui
local ui = pg:FindFirstChild("ShooterUI")
print("client runs:", CLIENT_RUNS, "ui:", ui ~= nil, "objects:", ui and #ui:GetDescendants())
local function show(label)
	local ui = pg:FindFirstChild("ShooterUI")
	local t = ui and textsVisible(ui) or {}
	print(string.format("[%6.1f] %s | state=%s cam=%s mouse=%s fov=%s weatherDrops=%d | %s", NOW, label, gv("State"), tostring(camera.CameraType),
		tostring(UIS.MouseBehavior), tostring(camera.FieldOfView), camera:FindFirstChild("WeatherFX") and #camera.WeatherFX:GetChildren() or -1,
		table.concat(t, " / "):sub(1, 900)))
end
show("lobby")
-- click the vote buttons and the team buttons like a player would
local function click(text)
	local ui = pg:FindFirstChild("ShooterUI")
	for _, d in ipairs(ui:GetDescendants()) do
		if d.ClassName == "TextButton" and string.find(d.Text, text, 1, true) then
			d.MouseButton1Click:Fire()
			return true
		end
	end
	print("  (no button " .. text .. ")")
	return false
end
click("DESERT OUTPOST")
click("TEAM DEATHMATCH")
click("THUNDERSTORM")
click("HARD BOTS")
click("BLUE")
runFor(1)
show("voted")
print("pref:", me.SData.TeamPref.Value)
-- settings: third person
key("P", true) key("P", false)
runFor(0.5)
show("settings open")
click("FIRST PERSON")
runFor(0.5)
print("view:", me.SData.SetView.Value)
click("CLOSE")
key("L", true) key("L", false)
runFor(0.5)
show("loadout open")
key("L", true) key("L", false)
runFor(20)
show("match")
print("my team:", me.SData.Team.Value, "weather:", gv("Weather"))
-- third person camera: moves with the mouse / touchpad and the arrow keys
local before = camera.CoordinateFrame.lookVector
mouseMove(120, 0)
runFor(0.2)
local after = camera.CoordinateFrame.lookVector
print("camera turned by mouse:", string.format("%.3f", (after - before).magnitude), "type", tostring(camera.CameraType), "mouse", tostring(UIS.MouseBehavior))
key("Left", true)
runFor(0.5)
key("Left", false)
local after2 = camera.CoordinateFrame.lookVector
print("camera turned by arrow key:", string.format("%.3f", (after2 - after).magnitude))
-- menus free the mouse in third person
key("T", true) key("T", false)
runFor(0.2)
show("team panel")
print("mouse while menu open:", tostring(UIS.MouseBehavior))
click("RED")
runFor(0.5)
print("team after switch:", me.SData.Team.Value)
-- shoot (F key), aim (Q), grenade, reload, shoulder
CLIENT_LOG = {}
key("F", true)
runFor(1.5)
key("F", false)
key("Q", true) key("Q", false)
runFor(0.3)
print("aiming FOV:", camera.FieldOfView)
key("Q", true) key("Q", false)
key("R", true) key("R", false)
key("G", true) key("G", false)
key("X", true) key("X", false)
runFor(1)
local c = {}
for _, w in ipairs(CLIENT_LOG) do c[w] = (c[w] or 0) + 1 end
local cs = {}
for k, v in pairs(c) do table.insert(cs, k .. "=" .. v) end
print("client sent:", table.concat(cs, " "), "shoulder:", me.SData.SetShoulder.Value)
-- scores (hold tab)
key("Tab", true)
runFor(0.3)
show("tab held")
key("Tab", false)
runFor(10)
show("match +10s")
-- die and respawn: the script restarts
local h = me.Character.Humanoid
h.Health = 0
runFor(5)
show("respawned")
print("client runs:", CLIENT_RUNS, "render binds:", (function() local n = 0 for k in pairs(RENDER) do n = n + 1 end return n end)())
-- back to first person
key("V", true) key("V", false)
runFor(1)
show("first person")
print("camera type:", tostring(camera.CameraType), "view:", me.SData.SetView.Value)
runFor(30)
-- admin ends the match: lobby again
print("ERRORS:", #ERRORS)
for i, e in ipairs(ERRORS) do if i <= 6 then print(e) end end
