local out = {}
local function say(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out[#out + 1] = table.concat(t, " ") end
local p = JOINER
local function torso() return p.Character.Torso end
local function count(o) local n = 0 for _, c in ipairs(o:GetChildren()) do n = n + 1 + count(c) end return n end
local function touch(part) CTX = SERVER part.Touched:_fire(torso()) runFor(0.7) end
local function fire(...) local a = { ... } CTX = CLIENT_CTX game.ReplicatedStorage.AirportEvent:FireServer(unpack(a)) CTX = SERVER end
local ui = p.PlayerGui:FindFirstChild("AirportUI")
say("UI built:", ui ~= nil, "| cash", p.leaderstats.Cash.Value, "| top:", ui and ui.Frame and "" or "")
local A1 = workspace.Airport1
say("claim pads:", #A1.Pads:GetChildren(), A1.Pads:GetChildren()[1] and A1.Pads:GetChildren()[1].Name)
touch(A1.Pads.Claim) runFor(1)
say("after claim: pads", #A1.Pads:GetChildren(), "| header", tostring(A1:FindFirstChild("PylonSign") and A1.PylonSign.Text and A1.PylonSign.Text.Label.Text))
-- buy everything
p.leaderstats.Cash.Value = 100000000
local bought, fails = 0, {}
for round = 1, 60 do
	local pads = A1.Pads:GetChildren()
	if #pads == 0 then break end
	for _, pad in ipairs(pads) do
		local before = #ERRORS
		touch(pad)
		bought = bought + 1
		if #ERRORS > before then table.insert(fails, pad.Name .. ": " .. ERRORS[#ERRORS].msg) end
	end
end
local items, parts, empty = 0, 0, {}
for _, m in ipairs(A1.Items:GetChildren()) do
	items = items + 1
	local n = count(m)
	parts = parts + n
	if n == 0 then table.insert(empty, m.Name) end
end
say("bought via", bought, "pad touches ->", items, "items,", parts, "objects | empty:", table.concat(empty, ", "))
for _, f in ipairs(fails) do say("  FAIL " .. f) end
-- hire
for round = 1, 8 do
	for _, k in ipairs({ "agent", "officer", "chef", "clerk", "janitor", "gateagent", "pilot", "handler", "atc", "mechanic", "firefighter" }) do fire("hire", k) end
	runFor(0.5)
end
say("staff:", #A1.Staff:GetChildren())
-- let the airport run
local m0 = p.leaderstats.Cash.Value
runFor(180)
local D = SERVER_G.AirportDebug
local people = 0
for _, w in ipairs(D.G.walkers) do if w.plot == D.G.plots[1] then people = people + 1 end end
local holder = workspace.CurrentCamera:FindFirstChild("AirportNPCs")
local copies, marks = holder and #holder:GetChildren() or 0, #workspace.AirportMovers:GetChildren()
-- every copy must sit on its marker
local off = 0
if holder then
	for _, m in ipairs(holder:GetChildren()) do
		local mark = workspace.AirportMovers:FindFirstChild(m.Name)
		local o = m:FindFirstChild("Origin")
		if mark and o then
			for _, p in ipairs(m:GetChildren()) do
				if p:IsA("BasePart") then
					local src = game:GetService("ReplicatedStorage").AirportNPCModels:FindFirstChild(m.Name)
					local sp = src and src:FindFirstChild(p.Name)
					if sp then
						local want = mark.CFrame * (o.Value:inverse() * sp.CFrame)
						off = math.max(off, (want.p - p.CFrame.p).magnitude)
					end
				end
			end
		end
	end
end
say("npc markers", marks, "| client copies", copies, "| worst copy offset", string.format("%.2f", off))
local planesMoving = 0
for _, m in ipairs(A1.Planes:GetChildren()) do planesMoving = planesMoving + 1 end
say("after 3 min: cash +", p.leaderstats.Cash.Value - m0, "| people now", people, "| leaderboard rating", p.leaderstats.Rating.Value)
ui = p.PlayerGui:FindFirstChild("AirportUI")
say("top bar:", ui.Frame:FindFirstChild("TextLabel") and ui.Frame.TextLabel.Text)
-- flyable plane
local pad
for _, it in ipairs(A1.Items:GetChildren()) do local fp = it:FindFirstChild("FlyPad") if fp and it.Name:find("Private") then pad = fp end end
touch(pad) runFor(1)
local plane
for _, m in ipairs(A1.Planes:GetChildren()) do if m:FindFirstChild("PilotSeat") then plane = m end end
say("flyable spawned:", plane and plane.Name)
if plane then
	local w = makeInstance("Weld") w.Name = "SeatWeld" w.Part0 = plane.PilotSeat w.Part1 = torso() w.Parent = plane.PilotSeat
	plane.PilotSeat.Throttle = 1
	runFor(4)
	fire("pitch", 1) runFor(1)
	local g, v = plane.Body.BodyGyro, plane.Body.BodyVelocity
	say("flying: velocity", tostring(v.velocity), "maxForce", tostring(v.maxForce), "| gyro look", tostring(g.cframe.lookVector))
	runFor(1)
	say("flight HUD visible:", ui:FindFirstChild("Frame") and "?" )
end
return out
