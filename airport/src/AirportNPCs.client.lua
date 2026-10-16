-- ReplicatedFirst.AirportNPCs (runs once per player): draws the moving people and planes of Airport Tycoon.
-- The server moves one invisible marker per NPC (workspace.AirportMovers). What the NPC looks like waits in
-- ReplicatedStorage.AirportNPCModels under the same name. This script keeps a copy of every NPC in the camera
-- (only this player sees it) and puts it on its marker every frame.
-- (2016 clients don't carry welded parts along with an anchored part the server moves, so nothing here uses welds.)
local pcall = ypcall or pcall
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local marks = workspace:WaitForChild("AirportMovers")
local looks = RS:WaitForChild("AirportNPCModels")

local holder = Instance.new("Model")
holder.Name = "AirportNPCs"
local copies = {}    -- marker -> { model, parts, rel, cur, tick }
local waiting = {}   -- markers whose model hasn't arrived yet
local canLerp = pcall(function() return CFrame.new():lerp(CFrame.new(1, 0, 0), 0.5) end)

local function partsOf(m, list)
	for _, c in ipairs(m:GetChildren()) do
		if c:IsA("BasePart") then table.insert(list, c) end
		partsOf(c, list)
	end
	return list
end
local function put(c, cf)
	c.cur = cf
	for i, p in ipairs(c.parts) do p.CFrame = cf * c.rel[i] end
end
local function add(mark)
	if copies[mark] or not mark:IsA("BasePart") then return end
	local src = looks:FindFirstChild(mark.Name)
	local origin = src and src:FindFirstChild("Origin")
	if not origin then waiting[mark] = true return end
	waiting[mark] = nil
	local m = src:Clone()
	local parts = partsOf(m, {})
	local inv = origin.Value:inverse()
	local rel = {}
	for i, p in ipairs(parts) do
		p.Anchored = true
		p.CanCollide = false
		rel[i] = inv * p.CFrame
	end
	m.Parent = holder
	local c = { model = m, parts = parts, rel = rel, n = math.random(0, 2) }
	copies[mark] = c
	put(c, mark.CFrame)
end
local function remove(mark)
	waiting[mark] = nil
	local c = copies[mark]
	copies[mark] = nil
	if c then pcall(function() c.model:Destroy() end) end
end

for _, m in ipairs(marks:GetChildren()) do add(m) end
marks.ChildAdded:connect(add)
marks.ChildRemoved:connect(remove)
looks.ChildAdded:connect(function(m)
	for mark in pairs(waiting) do if mark.Name == m.Name then add(mark) end end
end)

local function camPos()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	if holder.Parent ~= cam then holder.Parent = cam end
	local ok, cf = pcall(function() return cam.CoordinateFrame end)
	return ok and cf and cf.p or nil
end

local frame = 0
RunService.RenderStepped:connect(function(dt)
	frame = frame + 1
	local eye = camPos()
	for mark, c in pairs(copies) do
		if not mark.Parent then
			remove(mark)
		else
			local target = mark.CFrame
			local d = (target.p - c.cur.p).magnitude
			local still = d < 0.01 and (target.lookVector - c.cur.lookVector).magnitude < 0.001
			-- far away things only need an update every few frames
			local far = eye and (target.p - eye).magnitude > 1200
			if not still and (not far or (frame + c.n) % 3 == 0) then
				if canLerp and d < 60 and not far then
					put(c, c.cur:lerp(target, math.min(1, (dt or 1 / 30) * 18)))
				else
					put(c, target)
				end
			end
		end
	end
	if frame % 30 == 0 then
		for mark in pairs(waiting) do
			if mark.Parent then add(mark) else waiting[mark] = nil end
		end
	end
end)
