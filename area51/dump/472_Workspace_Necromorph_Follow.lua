local larm = script.Parent:FindFirstChild("Left Arm")
local rarm = script.Parent:FindFirstChild("Right Arm")

function findNearestTorso(pos)
	local list = game.Workspace:children()
	local torso = nil
	local dist = 10000000000 --This Line Right Here
	local temp = nil
	local human = nil
	local temp2 = nil
	for x = 1, #list do
		temp2 = list[x]
		if (temp2.className == "Model") and (temp2 ~= script.Parent) then
			temp = temp2:findFirstChild("Head")
			human = temp2:findFirstChild("Humanoid")
			Friend = temp2:findFirstChild("Friend")
			if (temp ~= nil) and (human ~= nil) and (Friend == nil) or (temp ~= nil) and (human ~= nil) and (human.Health > 0) and (Friend.Value ~= script.Parent.Friend.Value)  then
				if (temp.Position - pos).magnitude < dist then
					torso = temp
					dist = (temp.Position - pos).magnitude
				end
			end
		end
	end
	return torso
end

while true do
	wait(0.1)
	local target = findNearestTorso(script.Parent.Torso.Position)
	if target ~= nil then
		script.Parent.Humanoid:MoveTo(target.Position, target)
	end
end 