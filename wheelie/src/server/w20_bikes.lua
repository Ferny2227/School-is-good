-- ==== w20_bikes.lua
------------------------------------------------------------------ saved stuff: Cash, best wheelie, the bikes you own
local store, topStore
pcall(function() store = game:GetService("DataStoreService"):GetDataStore("WheelieLife1") end)
pcall(function() topStore = game:GetService("DataStoreService"):GetOrderedDataStore("WheelieLifeBest1") end)
local DATA = {}           -- player -> { owned = { name = true }, eq = name }
local function idOf(p) local ok, id = pcall(function() return p.UserId end) return ok and id or p.userId end
local function stats(p)
	local ls = p:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("IntValue")
		ls.Name = "leaderstats"
		local c = Instance.new("IntValue") c.Name = "Cash" c.Value = 0 c.Parent = ls
		local b = Instance.new("NumberValue") b.Name = "Best" b.Value = 0 b.Parent = ls
		ls.Parent = p
	end
	return ls
end
local function sendGarage(p)
	local d = DATA[p]
	if not d then return end
	local owned = {}
	for name in pairs(d.owned) do table.insert(owned, name) end
	toClient(p, "garage", owned, d.eq)
end
local function load(p)
	DATA[p] = { owned = { ["Mini Bike"] = true }, eq = "Mini Bike" }
	stats(p)
	if not store then sendGarage(p) return end
	spawn(function()
		local ok, v = pcall(function() return store:GetAsync("u" .. idOf(p)) end)
		if ok and type(v) == "table" and p.Parent then
			local ls = stats(p)
			if tonumber(v.c) then ls.Cash.Value = math.max(ls.Cash.Value, tonumber(v.c)) end
			if tonumber(v.b) then ls.Best.Value = math.max(ls.Best.Value, tonumber(v.b)) end
			if type(v.o) == "table" then for _, n in ipairs(v.o) do if BIKE[n] then DATA[p].owned[n] = true end end end
			if BIKE[v.e or ""] and DATA[p].owned[v.e] then DATA[p].eq = v.e end
		end
		sendGarage(p)
	end)
end
local lastSave = {}
local function save(p, now)
	local d, ls = DATA[p], p:FindFirstChild("leaderstats")
	if not store or not d or not ls then return end
	if not now and tick() - (lastSave[p] or 0) < 20 then return end
	lastSave[p] = tick()
	local owned = {}
	for name in pairs(d.owned) do table.insert(owned, name) end
	local data = { c = ls.Cash.Value, b = ls.Best.Value, o = owned, e = d.eq }
	local key, name, best = "u" .. idOf(p), p.Name, math.floor(ls.Best.Value * 10)
	spawn(function()
		pcall(function() store:SetAsync(key, data) end)
		if topStore and best > 0 then pcall(function() topStore:SetAsync(name, best) end) end
	end)
end

------------------------------------------------------------------ riding: the bike is welded under you; your computer drives it
local riding = {}         -- player -> { model, bike }
local function sitPose(c, on)
	-- legs forward (sitting on the seat), arms forward (holding the bars)
	local torso = c and c:FindFirstChild("Torso")
	if not torso then return end
	for _, jn in ipairs({ "Right Hip", "Left Hip", "Right Shoulder", "Left Shoulder" }) do
		local j = torso:FindFirstChild(jn)
		if j then
			if not j:FindFirstChild("StandC0") then
				local v = Instance.new("CFrameValue")
				v.Name = "StandC0"
				v.Value = j.C0
				v.Parent = j
			end
			local c0 = j.StandC0.Value
			if not on then j.C0 = c0
			else
				local leg = jn:find("Hip") ~= nil
				local side = jn:find("Right") and 1 or -1
				-- (the joints turn round their own axis: hips and shoulders point the limb forwards)
				j.C0 = c0 * CFrame.Angles(0, 0, side * (leg and 1.05 or 1.25))
			end
		end
	end
end
local function getOff(p)
	local r = riding[p]
	riding[p] = nil
	if r and r.model then pcall(function() r.model:Destroy() end) end
	local c = p.Character
	sitPose(c, false)
	local h = c and c:FindFirstChild("Humanoid")
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if root then
		-- upright, so the character doesn't spring up getting back on its feet
		pcall(function()
			local lv = root.CFrame.lookVector
			local flatLook = Vector3.new(lv.X, 0, lv.Z)
			if flatLook.magnitude < 0.1 then flatLook = Vector3.new(0, 0, -1) end
			root.CFrame = CFrame.new(root.Position, root.Position + flatLook.unit)
			root.RotVelocity = Vector3.new()
		end)
	end
	if h then pcall(function() h.PlatformStand = false end) end
	toClient(p, "riding", nil)
end
local function ride(p)
	local c = p.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	local h = c and c:FindFirstChild("Humanoid")
	if not root or not h or h.Health <= 0 then return end
	if riding[p] then getOff(p) end
	local b = BIKE[DATA[p] and DATA[p].eq or ""] or BIKES[1]
	-- build the bike under the rider and weld it on
	local look = root.CFrame.lookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local base = CFrame.new(root.Position.X, root.Position.Y - 3, root.Position.Z) * CFrame.Angles(0, yaw, 0)
	local rootCF = base * RiderOffset(b)
	root.CFrame = rootCF
	local m = buildBikeModel(c, b, base, false, root, "Bike")
	local tag = Instance.new("StringValue")
	tag.Name = "BikeName"
	tag.Value = b.name
	tag.Parent = m
	riding[p] = { model = m, bike = b, since = tick(), lastAward = tick() }
	sitPose(c, true)
	pcall(function() h.PlatformStand = true end)
	toClient(p, "riding", b.name)
end

------------------------------------------------------------------ the garage: buy and pick bikes
local function buy(p, name)
	local b, d = BIKE[name], DATA[p]
	if not b or not d then return end
	local ls = stats(p)
	if d.owned[name] then
		d.eq = name
		say(p, "Riding the " .. name .. " now!", "green")
	elseif ls.Cash.Value >= b.price then
		ls.Cash.Value = ls.Cash.Value - b.price
		d.owned[name] = true
		d.eq = name
		say(p, "You bought the " .. name .. "!", "gold")
		save(p, true)
	else
		say(p, "You need $" .. (b.price - ls.Cash.Value) .. " more for the " .. name .. ".", "red")
		return
	end
	sendGarage(p)
	if riding[p] then ride(p) end
end

------------------------------------------------------------------ wheelies: your computer reports each one when the front wheel comes down
-- The server checks it makes sense (not longer than you've been riding, not faster than the bike, not too often)
-- and pays: seconds x speed. A crash (looping out) pays nothing.
local MAX_WHEELIE = 120
local function wheelie(p, secs, speed, dist)
	local r = riding[p]
	if not r or type(secs) ~= "number" or type(speed) ~= "number" then return end
	secs, speed = math.max(0, secs), math.max(0, speed)
	local now = tick()
	if secs < 0.8 then return end
	-- can't be longer than the time since the last one, or since getting on
	if secs > MAX_WHEELIE or secs > now - r.lastAward + 1 then return end
	speed = math.min(speed, r.bike.speed + 2)
	r.lastAward = now
	local cash = math.floor(secs * (2 + speed / 6))
	local ls = stats(p)
	ls.Cash.Value = ls.Cash.Value + cash
	local best = false
	if secs > ls.Best.Value then
		ls.Best.Value = math.floor(secs * 10) / 10
		best = true
	end
	toClient(p, "paid", cash, secs, best)
	save(p)
end
