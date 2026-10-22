ball = script.Parent
damage = 15



function onTouched(hit)
	local humanoid = hit.Parent:findFirstChild("Humanoid")
	if humanoid ~= nil then
		tagHumanoid(humanoid)
		humanoid.Health = humanoid.Health - damage
		wait(.1)
		untagHumanoid(humanoid)
	end
	connection:disconnect()
	ball.Parent = nil
end
function tagHumanoid(humanoid)
	local tag = ball:findFirstChild("creator")
	if tag ~= nil then
		local new_tag = tag:clone()
		new_tag.Parent = humanoid
	end
end
function untagHumanoid(humanoid)
	if humanoid ~= nil then
		local tag = humanoid:findFirstChild("creator")
		if tag ~= nil then
			tag.Parent = nil
		end
	end
end
connection = ball.Touched:connect(onTouched)
wait(8)
ball.Parent = nil