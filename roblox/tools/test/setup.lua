-- Shared test setup: a mock map like the real place (10 plots, plaza, hub, spawn), then start AirportServer.
-- Globals from the runner: SERVER_SOURCE. Sets _G.TEST_PRINTED (everything the server printed).
local MOCK = MOCK
local printed = {}
local realprint = print
function print(...)
	local t = {}
	for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
	local s = table.concat(t, " ")
	table.insert(printed, s)
	if s:find("failed") or s:find("rror") then table.insert(MOCK.errors, "printed: " .. s) end
end
-- map: 10 plots like the real place
local map = MOCK.new("Model", workspace) map.Name = "AirportMap"
local plots = MOCK.new("Model", map) plots.Name = "Plots"
local xs = { -1400, -700, 0, 700, 1400 }
for i = 1, 10 do
	local x = xs[(i - 1) % 5 + 1]
	local south = i > 5
	local pm = MOCK.new("Model", plots) pm.Name = "Plot" .. i
	local cf = south and (CFrame.new(x, 0.5, -360) * CFrame.Angles(0, math.pi, 0)) or CFrame.new(x, 0.5, 360)
	MOCK.part(pm, "Origin", Vector3.new(1, 1, 1), cf)
	MOCK.part(pm, "Base", Vector3.new(420, 0.1, 620), cf * CFrame.new(0, -0.4, 310))
	for _, c in ipairs({ { -210, 310, 2, 620 }, { 210, 310, 2, 620 }, { 0, 0.5, 422, 1 }, { 0, 619.5, 422, 1 } }) do
		MOCK.part(pm, "Curb", Vector3.new(c[3], 0.6, c[4]), cf * CFrame.new(c[1], -0.1, c[2]))
	end
end
local trees = MOCK.new("Model", map) trees.Name = "Trees"
for i = 1, 60 do
	local x, z = math.random(-1700, 1700), math.random(-1250, 1250)
	MOCK.part(trees, "Trunk", Vector3.new(2, 10, 2), CFrame.new(x, 5, z))
	MOCK.part(trees, "Leaves", Vector3.new(8, 8, 8), CFrame.new(x, 12, z))
end
local plaza = MOCK.new("Model", map) plaza.Name = "Plaza"
MOCK.part(plaza, "WelcomeBoard", Vector3.new(60, 14, 1), CFrame.new(0, 10, -200))
local hub = MOCK.new("Model", map) hub.Name = "Hub"
MOCK.part(hub, "HubSign", Vector3.new(120, 10, 1), CFrame.new(-300, 40, -177))
MOCK.part(map, "Spawn", Vector3.new(14, 1, 14), CFrame.new(0, 1, -215))
local ground = MOCK.new("Model", map) ground.Name = "Ground"

-- run the server
MOCK.pushOnResize = true
local fn, err = loadstring(SERVER_SOURCE, "=AirportServer")
if not fn then error(err) end
spawn(fn)
MOCK.run(3)
local D = _G.AirportDebug
assert(D, "server did not start: " .. table.concat(MOCK.errors, "\n"))
_G.TEST_PRINTED = printed
