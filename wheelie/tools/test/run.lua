-- Runs WheelieServer and WheelieClient together in the mock Roblox: the city, riding, wheelies, cash, crashing,
-- the garage.
local MOCK = MOCK
local out = {}
local function say(s) table.insert(out, s) end
local realNew = Instance.new
Instance.new = function(cls, parent)
	local o = realNew(cls, parent)
	if cls == "Humanoid" then o.Health, o.MaxHealth, o.WalkSpeed, o.PlatformStand = 100, 100, 16, false
	elseif cls == "IntValue" or cls == "NumberValue" then o.Value = 0
	elseif cls == "StringValue" then o.Value = "" end
	return o
end
-- rays against the parts' boxes (wedges count as boxes here), with the surface normal
local function castRay(ray, ignore)
	local o0, d = ray.Origin, ray.Direction
	local best, bt, bn = nil, 1, nil
	for _, p in ipairs(MOCK.allParts) do
		local skip = not p.Parent or not p:IsDescendantOf(workspace)
		if not skip and ignore then for _, ig in ipairs(ignore) do if p == ig or p:IsDescendantOf(ig) then skip = true break end end end
		if not skip then
			local c, s = p.CFrame.p, p.Size
			local t0, t1, n0 = 0, 1, nil
			local ok = true
			for _, ax in ipairs({ "X", "Y", "Z" }) do
				local lo, hi = c[ax] - s[ax] / 2, c[ax] + s[ax] / 2
				if math.abs(d[ax]) < 1e-9 then
					if o0[ax] < lo or o0[ax] > hi then ok = false break end
				else
					local a, b = (lo - o0[ax]) / d[ax], (hi - o0[ax]) / d[ax]
					local na = ax
					if a > b then a, b = b, a end
					if a > t0 then t0, n0 = a, ax end
					t1 = math.min(t1, b)
					if t0 > t1 then ok = false break end
				end
			end
			if ok and t0 < bt then
				best, bt = p, t0
				local nv = { X = 0, Y = 0, Z = 0 }
				if n0 then nv[n0] = d[n0] > 0 and -1 or 1 else nv.Y = 1 end
				bn = Vector3.new(nv.X, nv.Y, nv.Z)
			end
		end
	end
	if best then return best, o0 + d * bt, bn end
	return nil, o0 + d, nil
end
local mt = getmetatable(workspace)
local oldIndex = mt.__index
mt.__index = function(o, k)
	if k == "Clear" then return function() end end
	if k == "FindPartOnRay" then return function(self, ray, ig) return castRay(ray, ig and { ig } or nil) end end
	if k == "FindPartOnRayWithIgnoreList" then return function(self, ray, list) return castRay(ray, list) end end
	return oldIndex(o, k)
end
Ray = { new = function(o, d) return { Origin = o, Direction = d } end }
local map = MOCK.new("Model", workspace) map.Name = "AirportMap"
-- server <-> the one client in this test
local clientPlayer
MOCK.onFireClient = function(remote, p, ...)
	if p == clientPlayer then local a = { ... } remote.OnClientEvent:fireNow(unpack(a)) end
end
spawn(assert(loadstring(SERVER_SOURCE, "=WheelieServer")))
MOCK.run(1)
local D = _G.WheelieDebug
assert(D, "server did not start: " .. table.concat(MOCK.errors, "\n"))
local parts = 0
for _, o in ipairs(workspace["Wheelie City"]:GetDescendants()) do if o:IsA("BasePart") then parts = parts + 1 end end
say(string.format("Wheelie City built: %d parts, old map removed %s", parts, tostring(workspace:FindFirstChild("AirportMap") == nil)))

-- a player with a proper R6-ish character
local p = MOCK.addPlayer("rider", 7)
clientPlayer = p
MOCK.run(0.5)
local c = MOCK.makeCharacter(p)
local root = MOCK.part(c, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0))
root.Anchored = false
for _, n in ipairs({ "Right Hip", "Left Hip", "Right Shoulder", "Left Shoulder" }) do
	local j = MOCK.new("Motor6D", c.Torso) j.Name = n j.C0 = CFrame.new()
end
-- on the boulevard, facing east
root.CFrame = CFrame.new(-340, 3, 0) * CFrame.Angles(0, -math.pi / 2, 0)
rawget(MOCK.services.Players, "_p").LocalPlayer = p
local remote = MOCK.services.ReplicatedStorage.WheelieEvent
rawset(remote, "FireServer", nil)
rawget(remote, "_p").FireServer = function(self, ...) remote.OnServerEvent:fireNow(p, ...) end
spawn(assert(loadstring(CLIENT_SOURCE, "=WheelieClient")))
MOCK.run(1)
say(string.format("leaderstats: Cash %d, Best %.1f; garage sent to the client %s", p.leaderstats.Cash.Value, p.leaderstats.Best.Value,
	tostring(p.PlayerGui:FindFirstChild("WheelieUI") ~= nil)))

-- RIDE
remote.OnServerEvent:fireNow(p, "ride")
MOCK.run(0.2)
local bike = c:FindFirstChild("Bike")
local welds = 0
for _, o in ipairs(root:GetChildren()) do if o.ClassName == "Weld" then welds = welds + 1 end end
local hipTurned = c.Torso["Right Hip"].C0 ~= CFrame.new()
say(string.format("ride: bike %s with %d parts welded on, platform stand %s, sitting pose %s", bike and bike.BikeName.Value or "none", welds,
	tostring(c.Humanoid.PlatformStand), tostring(hipTurned)))
local RS = MOCK.services.RunService
local mouse = p:GetMouse()
local function frames(n, each)
	for i = 1, n do
		MOCK.run(1 / 30)
		if each then each(i) end
		RS.RenderStepped:fireNow()
	end
end
local x0 = root.Position.X
mouse.KeyDown:fireNow("w")
frames(60)
local x1 = root.Position.X
say(string.format("gas for 2 s: rode %.0f studs east (x %.0f -> %.0f), height above the road %.1f", x1 - x0, x0, x1, root.Position.Y))
-- a wheelie: hold space to pull up, let go near the balance point (a simple 'player')
local b = D.BIKES[1]
local maxPitch, cash0 = 0, p.leaderstats.Cash.Value
local function pitchNow()
	-- the bike's pitch from the root's look direction
	local lv = root.CFrame.lookVector
	return math.asin(math.max(-1, math.min(1, lv.Y)))
end
local spaceDown, brakeDown = false, false
frames(240, function()
	local pt = pitchNow()
	maxPitch = math.max(maxPitch, pt)
	-- hold space below the balance point, tap the brake if it goes over
	local want = pt < b.bp - 0.1
	if want ~= spaceDown then
		spaceDown = want
		if want then mouse.KeyDown:fireNow(" ") else mouse.KeyUp:fireNow(" ") end
	end
	local br = pt > b.bp + 0.06
	if br ~= brakeDown then
		brakeDown = br
		if br then mouse.KeyDown:fireNow("s") else mouse.KeyUp:fireNow("s") end
	end
end)
if brakeDown then mouse.KeyUp:fireNow("s") end
mouse.KeyUp:fireNow(" ")
mouse.KeyUp:fireNow("w")
mouse.KeyDown:fireNow("s")
frames(60)
mouse.KeyUp:fireNow("s")
MOCK.run(0.5)
say(string.format("wheelie: highest pitch %.0f deg (balance point %.0f), cash %d -> %d, best wheelie %.1f s, still riding %s",
	math.deg(maxPitch), math.deg(b.bp), cash0, p.leaderstats.Cash.Value, p.leaderstats.Best.Value, tostring(D.riding[p] ~= nil)))
-- loop out: hold space and gas until it goes over
mouse.KeyDown:fireNow("w")
mouse.KeyDown:fireNow(" ")
local crashed = false
frames(300, function() if not D.riding[p] then crashed = true end end)
mouse.KeyUp:fireNow(" ")
mouse.KeyUp:fireNow("w")
say(string.format("held the wheelie too long: looped out %s, bike gone %s, platform stand off %s", tostring(crashed), tostring(c:FindFirstChild("Bike") == nil),
	tostring(not c.Humanoid.PlatformStand)))
-- cheating check: a made-up 100 s wheelie isn't paid
remote.OnServerEvent:fireNow(p, "ride")
MOCK.run(0.3)
local cBefore = p.leaderstats.Cash.Value
remote.OnServerEvent:fireNow(p, "wheelie", 100, 500, 9000)
MOCK.run(0.3)
say(string.format("fake 100 s wheelie right after getting on: paid %d", p.leaderstats.Cash.Value - cBefore))
-- the garage
remote.OnServerEvent:fireNow(p, "buy", "Stinger")
MOCK.run(0.3)
local noMoney = D.DATA[p].owned["Stinger"] == nil
p.leaderstats.Cash.Value = 600
remote.OnServerEvent:fireNow(p, "buy", "Pit Bike")
MOCK.run(0.5)
say(string.format("garage: can't buy the Stinger without money %s; bought the Pit Bike %s (cash 600 -> %d), riding it now %s",
	tostring(noMoney), tostring(D.DATA[p].owned["Pit Bike"] == true), p.leaderstats.Cash.Value,
	tostring(c:FindFirstChild("Bike") and c.Bike.BikeName.Value == "Pit Bike")))
MOCK.run(6)
say("leaderboard: " .. D.boardText.Text:gsub("\n", " / "))
say("ERRORS: " .. #MOCK.errors)
for i = 1, math.min(8, #MOCK.errors) do say("  " .. MOCK.errors[i]:sub(1, 400)) end
TEST_OUT = table.concat(out, "\n")
