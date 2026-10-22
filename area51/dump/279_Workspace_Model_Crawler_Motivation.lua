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
w.MaxHealth = 60
w.Health = 60
w.WalkSpeed = 20
set = 1.5
local head = script.Parent:FindFirstChild("FakeHead")

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

con = head.Touched:connect(Hit)

function died()
con:disconnect()
wait(5)
script.Parent:remove()
end

script.Parent.Zombie.Died:connect(died)

while true do
	wait(0.3)
	local target, dist = findNearestTorso(script.Parent.Torso.Position)
	if target ~= nil then
		script.Parent.Zombie:MoveTo(target.Position, target)
		if dist<5 then
		target.Parent.Humanoid.Health = target.Parent.Humanoid.Health - 4
			trh=script.Parent.Torso:findFirstChild("Right Shoulder")
			tlh=script.Parent.Torso:findFirstChild("Left Shoulder")
			if trh ~= nil and tlh~=nil then
			trh.CurrentAngle = set
			tlh.CurrentAngle = -set
			if set == 0.1 then set = 0.1 else set = 0.1 end 
			end
		wait(0.2)
		end
	end
end
