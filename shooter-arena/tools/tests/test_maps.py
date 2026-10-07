# Runs SMaps.buildAll() in the fake Roblox and checks spawns / hills / part counts.
import sys, os
from lupa import lua51
SP = os.path.dirname(os.path.abspath(__file__))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(SP, '..', '..', 'src')
L = lua51.LuaRuntime(unpack_returned_tuples=True)
L.execute(open(os.path.join(SP, 'mock.lua')).read())
L.execute('''
game = Instance.new("DataModel")
game.Name = "Game"
workspace = Instance.new("Workspace")
workspace.Name = "Workspace"
workspace.Parent = game
game.Workspace = workspace
''')
maps_src = open(os.path.join(SRC, 'SMaps.lua')).read()
L.execute('MAPS_SRC = ...', ) if False else None
f = L.eval('function(src) local fn, err = loadstring(src, "SMaps") if not fn then error(err) end return fn() end')
M = f(maps_src)
L.globals().M = M
L.execute(r'''
local world = M.buildAll()
WORLD = world
local function collect(folder)
	local parts = {}
	local function rec(o)
		for _, c in ipairs(o:GetChildren()) do
			if c:IsA("BasePart") then table.insert(parts, c) end
			rec(c)
		end
	end
	rec(folder)
	return parts
end
local function solids(parts)
	local t = {}
	for _, p in ipairs(parts) do
		if p.CanCollide then table.insert(t, p) end
	end
	return t
end
local function inAny(list, pt, skip)
	for _, p in ipairs(list) do
		if p ~= skip and (p.CFrame.p - pt).magnitude <= partRadius(p) + 0.01 then
			if pointInPart(p, pt) then return p end
		end
	end
	return nil
end
-- floor under a point: the highest solid surface within 'down' studs below
local function floorUnder(list, pt, down)
	local y = pt.Y
	while y > pt.Y - down do
		local hit = inAny(list, Vector3.new(pt.X, y, pt.Z))
		if hit then return y, hit end
		y = y - 0.1
	end
	return nil
end
local problems = 0
local function checkSpawn(mapName, list, cf, kind, i)
	local base = cf.p + Vector3.new(0, 2, 0)   -- the server puts the root here
	local fy, fpart = floorUnder(list, base, 25)
	if not fy then
		print(string.format("  !! %s %s spawn %d at (%s): NO FLOOR within 25 studs", mapName, kind, i, tostring(cf.p)))
		problems = problems + 1
		return
	end
	-- body: 2 wide, 5 tall, 1 deep standing on the floor
	for _, dx in ipairs({ -1, 0, 1 }) do
		for _, dz in ipairs({ -0.5, 0, 0.5 }) do
			for _, dy in ipairs({ 0.6, 1.5, 2.5, 3.5, 4.5 }) do
				local pt = Vector3.new(base.X + dx, fy + dy, base.Z + dz)
				local hit = inAny(list, pt)
				if hit then
					print(string.format("  !! %s %s spawn %d at (%s): body inside %s", mapName, kind, i, tostring(cf.p), hit.Name))
					problems = problems + 1
					return
				end
			end
		end
	end
	if base.Y - fy > 8 then
		print(string.format("  .. %s %s spawn %d drops %.1f studs", mapName, kind, i, base.Y - fy))
	end
end
local function report(name, m)
	local parts = collect(m.folder)
	local list = solids(parts)
	print(string.format("%s: %d parts (%d solid)", name, #parts, #list))
	for _, kind in ipairs({ "red", "blue", "any" }) do
		for i, cf in ipairs(m.spawns[kind] or {}) do
			checkSpawn(name, list, cf, kind, i)
		end
	end
	for i, h in ipairs(m.hills or {}) do
		local fy = floorUnder(list, h + Vector3.new(0, 3, 0), 10)
		if not fy then
			print("  !! hill " .. i .. " has no floor near " .. tostring(h))
			problems = problems + 1
		elseif math.abs(fy - h.Y) > 2 then
			print(string.format("  .. hill %d floor at %.1f (hill y %.1f)", i, fy, h.Y))
		end
	end
	for i, pad in ipairs(m.teamPads or {}) do
		print("  team pad " .. pad.team)
	end
end
report("lobby", world.lobby)
for _, id in ipairs({ "nuketown", "skyline", "desert", "harbor", "forest" }) do
	if world.maps[id] then
		report(id, world.maps[id])
	else
		print("MISSING MAP " .. id)
		problems = problems + 1
	end
end
print("problems: " .. problems)
''')
