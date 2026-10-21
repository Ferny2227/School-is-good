-- Runs AirportClient against the live mock server for the rejoined player and pushes it a few state updates.
local MOCK = MOCK
local D = _G.AirportDebug
local G, A = D.G, D.A
local Players = MOCK.services.Players
local me
for _, p in ipairs(Players:GetPlayers()) do if p.Name == "tester" then me = p end end
assert(me, "no tester player")
rawget(Players, "_p").LocalPlayer = me
local remote = MOCK.services.ReplicatedStorage:FindFirstChild("AirportEvent")
local got = 0
local prev = MOCK.onFireClient
function MOCK.onFireClient(r, p, ...)
	if r == remote and p == me then
		got = got + 1
		remote.OnClientEvent:fireNow(...)
	end
end
local fn = assert(loadstring(CLIENT_SOURCE, "=AirportClient"))
local before = #MOCK.errors
-- a camera, and RenderStepped 30 times a second
local cam = MOCK.new("Camera", workspace)
cam.Name = "Camera"
workspace.CurrentCamera = cam
cam.CoordinateFrame = CFrame.new(G.plots[4].cf * Vector3.new(0, 30, 150))
spawn(function() while true do wait(1 / 30) MOCK.services.RunService.RenderStepped:fireNow(1 / 30) end end)
spawn(fn)
MOCK.run(5)
-- smooth NPCs: people near the camera should be drawn close to where the server has them, and keep moving
local near, close, moving = 0, 0, 0
local seen = {}
for _, w in ipairs(G.walkers) do
	if w.plot == G.plots[4] and not w.riding and w.model.Parent and (w.pos - cam.CoordinateFrame.p).magnitude < 160 then
		seen[w] = w.root.CFrame.p
	end
end
MOCK.run(1)
for w, p0 in pairs(seen) do
	if w.model.Parent and not w.riding then
		near = near + 1
		local p = w.root.CFrame.p
		if (p - (w.pos + Vector3.new(0, 3, 0))).magnitude < 6 then close = close + 1
		elseif DEBUG_SMOOTH then SMOOTH_DBG = (SMOOTH_DBG or "") .. "\nFAR " .. table.concat({tostring(p), tostring(w.pos), w.move.Value, w.i, #w.route, w.wt, tostring(w.waiting)}, " ") end
		if (p - p0).magnitude > 0.5 then moving = moving + 1 end
	end
end
SMOOTH_OUT = string.format("smooth NPCs: %d people near the camera, %d drawn within 6 studs of the server's position, %d moved in the last second", near, close, moving)
-- low graphics: far-away airports and the island are put away on this computer, lights are off
local gui = me.PlayerGui:FindFirstChild("AirportUI")
assert(gui, "client made no AirportUI")
local away, lightsOn = {}, 0
for i = 1, 10 do if not G.plots[i].Items.Parent then table.insert(away, i) end end
for _, o in ipairs(workspace:GetDescendants()) do if o.ClassName == "PointLight" and o.Enabled ~= false then lightsOn = lightsOn + 1 end end
local islandAway = not D.RESORT.root:FindFirstChild("Paradise Park")
LOWGFX_OUT = "low graphics: airports put away " .. table.concat(away, ",") .. "; island put away " .. tostring(islandAway) .. "; lights still on " .. lightsOn
local gb = gui:FindFirstChild("Graphics")
if gb then
	rawget(gb, "_p").MouseButton1Click:fireNow()   -- HIGH: everything comes back
	local back = 0
	for i = 1, 10 do if G.plots[i].Items.Parent then back = back + 1 end end
	LOWGFX_OUT = LOWGFX_OUT .. "; after HIGH: airports shown " .. back .. "/10, island back " .. tostring(D.RESORT.root:FindFirstChild("Paradise Park") ~= nil)
end
-- press every side button and every hire button
local clicks = 0
for _, o in ipairs(gui:GetDescendants()) do
	if o.ClassName == "TextButton" then
		local e = rawget(o, "_p").MouseButton1Click
		if e then e:fireNow() clicks = clicks + 1 end
	end
end
MOCK.run(3)
local gb2 = gui:FindFirstChild("Graphics")
if gb2 and gb2.Text == "GRAPHICS: LOW" then rawget(gb2, "_p").MouseButton1Click:fireNow() end   -- leave everything shown for later tests
local phases = 0
for _, o in ipairs(gui:GetDescendants()) do if o.ClassName == "TextLabel" and tostring(o.Text):match("^%d+%. ") then phases = phases + 1 end end
_G.CLIENT_OUT = LOWGFX_OUT .. "\n" .. SMOOTH_OUT .. (SMOOTH_DBG or "") .. "\nclient: state messages " .. got .. ", buttons clicked " .. clicks .. ", phase rows filled " .. phases .. ", new errors " .. (#MOCK.errors - before)
for i = before + 1, math.min(#MOCK.errors, before + 10) do _G.CLIENT_OUT = _G.CLIENT_OUT .. "\n  " .. MOCK.errors[i]:sub(1, 400) end
