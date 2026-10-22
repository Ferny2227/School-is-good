function waitForChild(parent, childName)
	while true do
		local child = parent:findFirstChild(childName)
		if child then
			return child
		end
		parent.ChildAdded:wait()
	end
end

local w = waitForChild(script.Parent, "Zombie")

local larm = script.Parent:FindFirstChild("Left Arm")
local rarm = script.Parent:FindFirstChild("Right Arm")

g=Instance.new("Weld")
Tag = script.Parent.Notification
forceA = Instance.new("BodyForce")
gyroA = Instance.new("BodyGyro")
gyroA.cframe = CFrame.new(Vector3.new(0,0,0), Vector3.new(0,5000000,0))
gyroA.maxTorque = Vector3.new(math.huge,math.huge,math.huge)
forceA.force = Vector3.new(0,-4e+005,0)
latched = false

w.MaxHealth = 50
w.Health = w.MaxHealth
w.WalkSpeed = 27.5

local larm = script.Parent:FindFirstChild("Left Arm")
local rarm = script.Parent:FindFirstChild("Right Arm")

db = false

function Hit(hit)
if db then return end
db = true
	if hit ~= nil and hit.Size.y >= 10 then
	ran = math.random(1, 2)
		if ran == 1 then
		cf2 = script.Parent.Torso.CFrame*CFrame.new(-20, 0, 5)
		elseif ran == 2 then
		cf2 = script.Parent.Torso.CFrame*CFrame.new(20, 0, 5)	
		end
	
	local part2 = Instance.new("Part")
	part2.Parent = script.Parent
	part2.Transparency = 1
	part2.Size = Vector3.new(1, 1, 1)
	part2.Anchored = true
	part2.Locked = true
	part2.CanCollide = false
	part2.CFrame = cf2
	start2 = part2.Position
	script.Parent.Zombie:MoveTo(start2, part2)
	wait(2)
	part2:remove()
	elseif hit ~= nil and hit.Size.y <= 10 and hit.Parent:findFirstChild("Humanoid") == nil or hit ~= nil and hit.Name == "Baricade" and hit.Parent:findFirstChild("Humanoid") == nil then
	script.Parent.Zombie.Jump = true
	end
	trh=script.Parent.Torso:findFirstChild("Right Shoulder")
	tlh=script.Parent.Torso:findFirstChild("Left Shoulder")
	if trh ~= nil and tlh~=nil then
	trh.CurrentAngle = 0.8
	tlh.CurrentAngle = -0.7
	end
db = false
end

larm.Touched:connect(Hit)
rarm.Touched:connect(Hit)

function findNearestTorso(pos)
	local list = game.Workspace:children()
	local torso = nil
	dist = 30
	local temp = nil
	local human = nil
	local temp2 = nil
	for x = 1, #list do
		temp2 = list[x]
		if (temp2.className == "Model") and (temp2 ~= script.Parent) then
			temp = temp2:findFirstChild("Torso")
			human = temp2:findFirstChild("Humanoid")
			if (temp ~= nil) and (human ~= nil) and (human.Health > 0) then
				if (temp.Position - pos).magnitude < dist then
					torso = temp
					dist = (temp.Position - pos).magnitude
				end
			end
		end
	end
	return torso, dist
end

function dead(time)
wait(time)
script.Parent:remove()
g.Parent = nil
forceA.Parent = nil
gyroA.Parent = nil
Tag.Adornee = nil
end

function healthChanged()
dist = 300
end

script.Parent.Zombie.Health.Changed:connect(healthChanged)
script.Parent.Zombie.Died:connect(function () dead(6) end)
startled = false

while true do
	wait(0.3)
	local target, dist = findNearestTorso(script.Parent.Torso.Position)
	if target ~= nil then
	dist = 300
		if not startled then
		startled = true
		p = game.Players:GetChildren()
			for i = 1, #p do
				if p[i] ~= nil and p[i].PlayerGui ~= nil then
				local warning = script.Parent.Notification:clone()
				warning.Parent = p[i].PlayerGui.Main
				game:GetService("Debris"):AddItem(warning, 3)
				end
			end
		end
		if not latched then
		script.Parent.Zombie:MoveTo(target.Position, target)
		--script.Parent.Torso.CFrame = CFrame.new(script.Parent.Torso.Position, target.Position)
		repeat wait()
		if target == nil then return end
		script.Parent.Zombie:MoveTo(target.Position, target)
		until (target.Position - script.Parent.Torso.Position).magnitude < 5 or script.Parent.Zombie.Health <=0
		if script.Parent.Zombie.Health <=0 then return end
			g.Parent = script.Parent.Torso
			g.Part1= script.Parent.Torso
			g.C0 = CFrame.new(0,0.2,-2) * CFrame.fromEulerAnglesXYZ(-1,math.pi,-0.1)
			g.Part0 = target
			forceA.Parent = target
			Tag.Adornee = target
			gyroA.Parent = target
			latched = true
			target.Parent.Humanoid.Sit = true
			repeat wait(0.4)
				trh=script.Parent.Torso:findFirstChild("Right Shoulder")
				tlh=script.Parent.Torso:findFirstChild("Left Shoulder")
				trh1=target:findFirstChild("Right Shoulder")
				tlh1=target:findFirstChild("Left Shoulder")
				trh2=target:findFirstChild("Right Hip")
				tlh2=target:findFirstChild("Left Hip")
				if trh ~= nil and tlh~=nil and trh1 ~= nil and trh2 ~= nil and trh2 ~= nil and trh1 ~= nil then
				trh.CurrentAngle = math.random(-2,2)
				tlh.CurrentAngle = math.random(-2,2)
				trh1.CurrentAngle = math.random(-2,2)
				tlh1.CurrentAngle = math.random(-2,2)
				trh2.CurrentAngle = 0
				tlh2.CurrentAngle = 0
				end	
			script.Parent.Zombie.Jump = true
			target.Parent.Humanoid.Health = target.Parent.Humanoid.Health - 10
			--target.Velocity = Vector3.new(math.random(-20,20),math.random(-50,20),math.random(-20,20))
			target.RotVelocity = Vector3.new(math.random(-5,5),math.random(-15,5),math.random(-5,5))
			until target.Parent.Humanoid.Health <= 0 or w.Health <=0 or target == nil
			if w.Health <=0 then coroutine.resume(coroutine.create(function () dead(2) end)) end
			script.Parent.Zombie.Sit = false
			g.Parent = nil
			forceA.Parent = nil
			gyroA.Parent = nil
			Tag.Adornee = nil
				if target ~= nil then
				target.Parent.Humanoid.Jump = true
				end
			latched = false
		end
	end
end
