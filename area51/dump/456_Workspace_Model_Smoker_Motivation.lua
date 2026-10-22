function waitForChild(parent, childName)
	while true do
		local child = parent:findFirstChild(childName)
		if child then
			return child
		end
		parent.ChildAdded:wait()
	end
end

wait(1)

local w = waitForChild(script.Parent, "Zombie")
set = 1.5
g=script.Parent.Explosion
g.Parent = nil
w.MaxHealth = 40
w.Health = 40
w.WalkSpeed = 14
set = 1.5
local larm = script.Parent:FindFirstChild("Left Arm")
local rarm = script.Parent:FindFirstChild("Right Arm")

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

function onDied()
g.Parent = game.Workspace
g.CFrame = script.Parent.Torso.CFrame
g.Anchored = true 
	for i=1, 25, 2 do wait()
	g.Mesh.Scale = Vector3.new(i,i-1,i)
	end
		for i,v in ipairs(game.Players:GetChildren()) do
			if v.Character~=nil and v.Character:findFirstChild("Torso")~=nil then
				if (v.Character.Torso.CFrame.p - script.Parent.Torso.Position).magnitude < 10 then
				v.Character.Humanoid.Health = v.Character.Humanoid.Health - 0
				end
			end
		end
-- remove
	g:remove()
wait(6)
script.Parent:remove()
end

script.Parent.Zombie.Died:connect(onDied)
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
	elseif hit ~= nil and grabbed ==false and hit.Size.y <= 10 and hit.Parent:findFirstChild("Humanoid") == nil or hit ~= nil and hit.Name == "Baricade" and hit.Parent:findFirstChild("Humanoid") == nil then
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

function checkCast()
hitter = true
db2 = false
Tag = script.Parent.Notification:clone()
weld=Instance.new("Weld")
forceA = Instance.new("BodyForce")
gyroA = Instance.new("BodyGyro")
gyroA.cframe = CFrame.new(Vector3.new(0,0,0), Vector3.new(0,5000000,0))
gyroA.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
forceA.force = Vector3.new(0,-4e+005,0)

p = Instance.new("Part")
p.Parent = script.Parent
p.Size = Vector3.new(1, 1, 1)
p.Shape = "Ball"
p.CanCollide = false
p.TopSurface = "Smooth"
p.BottomSurface = "Smooth"
p.Anchored = false
p.Transparency = 1
p.CFrame = script.Parent.Head.CFrame * CFrame.new(0, -2, -3) 
--p.Velocity = script.Parent.Head.CFrame.lookVector * 100
--p.Velocity = p.Velocity + Vector3.new(math.random(-accuracy, accuracy), math.random(-accuracy, accuracy), math.random(-accuracy, accuracy))

upforce = Instance.new("BodyPosition")
upforce.maxForce = Vector3.new(999999, 999999, 999999)
upforce.Parent = p
upforce.position = target.Position
upforce.P = 60000
con5 = p.Touched:connect(onTouchCast)
wait(1)
con5:disconnect()
p:remove()
	if hitter == false then
		return true
	else
		return false
	end
end

db2 = false

function onTouchCast(hit)
	if hit ~= nil and not db2 then
	db2 = true
		if hit.Parent:findFirstChild("Humanoid") ~= nil then
		hitter = false
		else
		hitter = true
		end
	end
end

while true do
	wait(0.3)
	target, dist = findNearestTorso(script.Parent.Torso.Position)
	if target ~= nil then
		script.Parent.Zombie:MoveTo(target.Position, target)
		wait(0.3)
		if dist<70 and not grabbed then
		script.Parent.Zombie:MoveTo(script.Parent.Torso.Position, script.Parent.Torso)
			if checkCast() then
			print("Grabbed!")
				if script.Parent.Zombie.Health <=0 then return end
				grabbed = true
				p = Instance.new("Part")
				p.Parent = script.Parent

				place0 = script.Parent.FakeHead.CFrame - Vector3.new(0, 0.5, 0)

				p.Name = "Tongue" 
				p.formFactor = 0 
				m = Instance.new("BlockMesh")
				m.Scale = Vector3.new(0.4,.2,1)
				m.Parent = p
		
				p.BrickColor = BrickColor.new(21)
				p.Anchored = true 
				p.CanCollide = false

				freeze = Instance.new("BodyPosition")
				freeze.Parent = target
				freeze.maxForce = Vector3.new(math.huge, math.huge, math.huge)
				freeze.position = target.Position - Vector3.new(0, 3, 0)

				p.Size = Vector3.new(1,1,(place0.p - target.CFrame.p).magnitude) 
				p.CFrame = CFrame.new((place0.p + target.CFrame.p)/2, place0.p) 

				Tag.Parent = target
				Tag.Adornee = target
				gyroA.Parent = target
				forceA.Parent = target
					for i = 1, 10 do
					wait()
						if target ~= nil then
						place0 = script.Parent.FakeHead.CFrame - Vector3.new(0, 0.2, 0)
						p.Size = Vector3.new(1,1,(place0.p - target.CFrame.p).magnitude) 
						p.CFrame = CFrame.new((place0.p + target.CFrame.p)/2, place0.p) 
						end
					end
			repeat 
			wait(1)
			if target == nil then return end
				if (target.Position - script.Parent.Torso.Position).Magnitude < 6 then
				if p ~= nil then p:remove() end
				weld.Parent = script.Parent.Torso
				weld.Part1= script.Parent.Torso
				weld.C0 = CFrame.new(0,0.2,-2) * CFrame.fromEulerAnglesXYZ(-1, math.pi, -0.1)
				weld.Part0 = target
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
					if target ~= nil then
					target.Parent.Humanoid.Health = target.Parent.Humanoid.Health - 3
					target.RotVelocity = Vector3.new(math.random(-5,5),math.random(-15,5),math.random(-5,5))
					end
				until target.Parent == nil or target.Parent.Humanoid.Health <= 0 or script.Parent.Zombie.Health <= 0
					grabbed = false
					if freeze ~= nil then freeze:remove() end
					if p ~= nil then p:remove() end
					if Tag ~= nil then Tag:remove() end
					if gyroA~= nil then gyroA:remove() end
					if forceA~= nil then forceA:remove() end
					if weld~= nil then weld:remove() end
				else
					target.Parent.Humanoid.Health = target.Parent.Humanoid.Health - 4
					repeats = (target.Position- script.Parent.Torso.Position).magnitude/10
					freeze.position = freeze.position - Vector3.new((target.Position.x - script.Parent.Torso.Position.x) / repeats, (target.Position.y - script.Parent.Torso.Position.y) / repeats, (target.Position.z - script.Parent.Torso.Position.z) / repeats)  - Vector3.new(0, 3, 0)
					for i = 1, 10 do
					wait()
						if target ~= nil then
						place0 = script.Parent.FakeHead.CFrame - Vector3.new(0, 0.2, 0)
						p.Size = Vector3.new(1,1,(place0.p - target.CFrame.p).magnitude) 
						p.CFrame = CFrame.new((place0.p + target.CFrame.p)/2, place0.p) 
						end
					end
				end
			until target.Parent == nil or target.Parent.Humanoid.Health <= 0 or script.Parent.Zombie.Health <= 0
			if freeze ~= nil then freeze:remove() end
			if p ~= nil then p:remove() end
			if Tag ~= nil then Tag:remove() end
			if gyroA~= nil then gyroA:remove() end
			if forceA~= nil then forceA:remove() end
			if weld~= nil then weld:remove() end
			wait(5)
			grabbed = false
			else
				if target ~= nil then
				script.Parent.Zombie:MoveTo(Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)), target)
				wait(1)
				end
			end
		end
	end
end
