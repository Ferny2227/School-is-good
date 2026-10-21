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
spawn(fn)
MOCK.run(5)
-- press every side button and every hire button
local gui = me.PlayerGui:FindFirstChild("AirportUI")
assert(gui, "client made no AirportUI")
local clicks = 0
for _, o in ipairs(gui:GetDescendants()) do
	if o.ClassName == "TextButton" then
		local e = rawget(o, "_p").MouseButton1Click
		if e then e:fireNow() clicks = clicks + 1 end
	end
end
MOCK.run(3)
local phases = 0
for _, o in ipairs(gui:GetDescendants()) do if o.ClassName == "TextLabel" and tostring(o.Text):match("^%d+%. ") then phases = phases + 1 end end
_G.CLIENT_OUT = "client: state messages " .. got .. ", buttons clicked " .. clicks .. ", phase rows filled " .. phases .. ", new errors " .. (#MOCK.errors - before)
for i = before + 1, math.min(#MOCK.errors, before + 10) do _G.CLIENT_OUT = _G.CLIENT_OUT .. "\n  " .. MOCK.errors[i]:sub(1, 400) end
