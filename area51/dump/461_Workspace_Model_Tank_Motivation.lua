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
--gyroA.cframe = CFrame.new(Vector3.new(0,0,0), Vector3.new(5000000,5000000,5000000))
gyroA.maxTorque = Vector3.new(math.huge,math.huge,math.huge)
forceA.force = Vector3.new(0,-9000,0)
latched = false

w.MaxHealth = 200
w.Health = w.MaxHealth
w.WalkSpeed = 10

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
	local dist = 300
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

script.Parent.Zombie.Died:connect(function () dead(6) end)



function onTouchRock(hit)
	if hit ~= nil and hit.Parent ~= nil and db3 == false then
	h = hit.Parent:findFirstChild("Humanoid")
		if h ~= nil then
		db3 = true
		h.Health = h.Health - 15
		local forceB = Instance.new("BodyForce")
		forceB.force = Vector3.new(0,-9000,0)
		local gyroB = Instance.new("BodyGyro")
		gyroB.cframe = CFrame.new(Vector3.new(0,0,0), Vector3.new(5000,5000,5000))
		gyroB.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
		local freeze = Instance.new("BodyPosition")
		freeze.Parent = hit.Parent.Torso
		freeze.maxForce = Vector3.new(math.huge, math.huge, math.huge)
		freeze.position = hit.Parent.Torso.Position - Vector3.new(0, 3, 0)
		hit.Parent.Torso.CFrame = hit.Parent.Torso.CFrame * CFrame.fromEulerAnglesXYZ(4.6, math.pi , 0.1)
		tag2 = script.Parent.Notification2:clone()
		tag2.Parent = hit.Parent.Torso
		tag2.Adornee = hit.Parent.Torso

		game:GetService("Debris"):AddItem(forceB, 2)
		game:GetService("Debris"):AddItem(gyroB, 2)
		game:GetService("Debris"):AddItem(freeze, 2)
		game:GetService("Debris"):AddItem(tag2, 2)
		end
	end
end

function smash()
local h = target.Parent:findFirstChild("Humanoid")
local trh=script.Parent.Torso:findFirstChild("Right Shoulder")
local tlh=script.Parent.Torso:findFirstChild("Left Shoulder")
	if trh ~= nil and tlh~=nil then
	trh.CurrentAngle = 5
	tlh.CurrentAngle = -5
	end		
h.Health = h.Health - 10
F = Instance.new("BodyVelocity")
F.velocity = script.Parent.Torso.CFrame.lookVector * 50
F.maxForce = Vector3.new(4e+006,4e+004,4e+006)
F.Parent = h.Parent.Torso
game:GetService("Debris"):AddItem(F, 0.5)
h.Parent.Torso.CFrame = h.Parent.Torso.CFrame * CFrame.fromEulerAnglesXYZ(4.6, math.pi , 0.1)
wait(2)
--h.Parent.Torso.CFrame = h.Parent.Torso.CFrame * CFrame.fromEulerAnglesXYZ(4.6, math.pi , 0.1)
	if target ~= nil then
	local forceB = Instance.new("BodyForce")
	forceB.force = Vector3.new(0,-9000,0)
	local gyroB = Instance.new("BodyGyro")
	gyroB.cframe = CFrame.new(Vector3.new(0,0,0), Vector3.new(5000,5000,5000))
	gyroB.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
	local freeze = Instance.new("BodyPosition")
	freeze.Parent = h.Parent.Torso
	freeze.maxForce = Vector3.new(math.huge, math.huge, math.huge)
	freeze.position = h.Parent.Torso.Position - Vector3.new(0, 3, 0)
	tag2 = script.Parent.Notification2:clone()
	tag2.Parent = h.Parent.Torso
	tag2.Adornee = h.Parent.Torso

	game:GetService("Debris"):AddItem(forceB, 1)
	game:GetService("Debris"):AddItem(gyroB, 1)
	game:GetService("Debris"):AddItem(freeze, 1)
	game:GetService("Debris"):AddItem(tag2, 1)
	end
end

function throwRock()
db3 = false
p2=Instance.new("Part") 

p2.Anchored = false
p2.Size = Vector3.new(3,3,3)
p2.TopSurface = "Smooth"
p2.BottomSurface = "Smooth"
mesh = Instance.new("SpecialMesh")
mesh.MeshId = "http://www.roblox.com/asset/?id=1290033"
mesh.Parent = p2
mesh.Scale = Vector3.new(2, 2, 2)

p2.Touched:connect(onTouchRock)

p2.CFrame = script.Parent.Head.CFrame * CFrame.new(0, 0, -5) 
p2.Velocity = script.Parent.Head.CFrame.lookVector * 100

p2.Parent = workspace
game:GetService("Debris"):AddItem(p2, 5)

local trh=script.Parent.Torso:findFirstChild("Right Shoulder")
local tlh=script.Parent.Torso:findFirstChild("Left Shoulder")
	if trh ~= nil and tlh~=nil then
	trh.CurrentAngle = 5
	tlh.CurrentAngle = -5
	end	
end

function latchTarget()
g.Parent = script.Parent.Torso
g.Part1= script.Parent.Torso
g.C0 = CFrame.new(0, -2.5,-3) * CFrame.fromEulerAnglesXYZ(4.6, math.pi , 0.1)
g.Part0 = target
forceA.Parent = script.Parent.Torso
Tag.Adornee = target
gyroA.Parent = script.Parent.Torso
latched = true
target.Parent.Humanoid.Sit = true
script.Parent.Zombie:MoveTo(script.Parent.Torso.Position, target)
	if tag2 ~= nil then
	tag2:remove()
	end
	repeat wait(1)
	trh=script.Parent.Torso:findFirstChild("Right Shoulder")
	tlh=script.Parent.Torso:findFirstChild("Left Shoulder")
	trh1=target:findFirstChild("Right Shoulder")
	tlh1=target:findFirstChild("Left Shoulder")
	trh2=target:findFirstChild("Right Hip")
	tlh2=target:findFirstChild("Left Hip")
		if trh ~= nil and tlh~=nil and trh1 ~= nil and trh2 ~= nil and trh2 ~= nil and trh1 ~= nil then
		trh.CurrentAngle = 2
		tlh.CurrentAngle = -2
		trh1.CurrentAngle = math.random(-2,2)
		tlh1.CurrentAngle = math.random(-2,2)
		trh2.CurrentAngle = 0
		tlh2.CurrentAngle = 0
		end	
	--script.Parent.Zombie.Jump = true
		if target ~= nil then
		target.Parent.Humanoid.Health = target.Parent.Humanoid.Health - 12
		--target.Velocity = Vector3.new(math.random(-20,20),math.random(-50,20),math.random(-20,20))
		target.RotVelocity = Vector3.new(math.random(-5,5),math.random(-15,5),math.random(-5,5))
		end
	until target.Parent.Humanoid.Health <= 0 or w.Health <=0 or target == nil
end


function loop()
	while true do
		wait(0.3)
		target, dist = findNearestTorso(script.Parent.Torso.Position)
		if target ~= nil then
			if not latched then
			script.Parent.Zombie:MoveTo(target.Position, target)
			--script.Parent.Torso.CFrame = CFrame.new(script.Parent.Torso.Position, target.Position)
			repeat wait(0.1)
				if target ~= nil then
				script.Parent.Zombie:MoveTo(target.Position, target)
				end
			wait(0.2)
			local ran = math.random(1, 20)
				if ran == 1 and (target.Position - script.Parent.Torso.Position).magnitude > 10 then
					if target ~= nil then
					script.Parent.Zombie:MoveTo(script.Parent.Torso.Position, target)
					throwRock()
					end
				end
			until (target.Position - script.Parent.Torso.Position).magnitude < 5 or script.Parent.Zombie.Health <=0 or target == nil
			if target == nil then loop() end
			local ran = math.random(1, 4)
				if ran <= 3 then
				smash()
				loop()
				else
					if target ~= nil then
					latchTarget()
					end
				if script.Parent.Zombie.Health <=0 then return end
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
	end
end

loop()
