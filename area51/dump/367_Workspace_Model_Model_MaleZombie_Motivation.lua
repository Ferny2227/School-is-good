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
w.MaxHealth = 270
w.Health = 270
w.WalkSpeed = 14
set = 1.5
local larm = script.Parent:FindFirstChild("Left Arm")
local rarm = script.Parent:FindFirstChild("Right Arm")

function findNearestTorso(pos)
	local list = game.Workspace:children()
	local torso = nil
	local dist = 5000000
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

function Hit(hit)
	local human = hit.Parent:FindFirstChild("Humanoid")
	if human ~= nil then
		human.Health =  human.Health - 8
	end
	trh=script.Parent.Torso:findFirstChild("Right Shoulder")
	tlh=script.Parent.Torso:findFirstChild("Left Shoulder")
	if trh and tlh~=nil then
	trh.CurrentAngle = 0.8
	tlh.CurrentAngle = -0.7
	end
end

larm.Touched:connect(Hit)
rarm.Touched:connect(Hit)
script.Parent.Zombie.Died:connect(function ()
wait(6)
script.Parent:remove()
larm:disconnect()
rarm:disconnect()
end)

coroutine.resume(coroutine.create(function ()
wait(math.random(40/70))
script.Parent.Zombie.Jump = true
end))

coroutine.resume(coroutine.create(function ()
wait(46)
script.Parent.Zombie.Health = 100
end))

while true do
	wait(0.1)
	local target, dist = findNearestTorso(script.Parent.Torso.Position)
	if target ~= nil then
		script.Parent.Zombie:MoveTo(target.Position, target)
		if dist<4 then
		target.Parent.Humanoid.Health = target.Parent.Humanoid.Health - 1
				local b = game:GetService("BadgeService")
				b:AwardBadge(game.Players:GetPlayerFromCharacter(target.Parent).userId, 28674796)
			trh=script.Parent.Torso:findFirstChild("Right Shoulder")
			tlh=script.Parent.Torso:findFirstChild("Left Shoulder")
			if trh and tlh~=nil then
			trh.CurrentAngle = set
			tlh.CurrentAngle = -set
			if set == 1 then set = 1.5 else set = 1 end 
			end
		wait(0.2)
		end
	end
end
