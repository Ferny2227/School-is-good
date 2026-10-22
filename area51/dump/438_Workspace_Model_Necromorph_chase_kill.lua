--not sure who made the script but i modded it to make it easier your friend, heysuses
Dmg = 20 --Change the dmg to whatever you want the zombies attack to be
local larm = script.Parent:FindFirstChild("Left Arm")
local rarm = script.Parent:FindFirstChild("Right Arm")

function findNearestTorso(pos)
	local list = game.Workspace:children()
	local torso = nil
	local dist = 200000
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
	return torso
end

function Hit(hit)
	local human = hit.Parent:FindFirstChild("Humanoid")--Change this to Zombie if you want a zombie killing gui but then look in for zombie with a picture uf a robloxian and change the name to "Humanoid" caps Sensitive
	if human ~= nil then
		human.Health =  human.Health - Dmg -- don't change this part but is you want you can make a healer by replacing the - with a +
	end
end

larm.Touched:connect(Hit)
rarm.Touched:connect(Hit)

while true do
	wait(0.1)
	local target = findNearestTorso(script.Parent.Torso.Position)
	if target ~= nil then
		script.Parent.Zombie:MoveTo(target.Position, target)
	end
end
