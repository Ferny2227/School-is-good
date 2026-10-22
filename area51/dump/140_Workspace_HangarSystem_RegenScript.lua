system = script.Parent
model1 = system.Station1
backup1 = model1:Clone()
regen = system.Regen

function regenerate1(model,backup)
	model:remove()
	wait(1)
	model1 = backup:Clone()
	model1.Parent = system
	model1:MakeJoints()
end



function checkRegen()
	if regen.Value == 1 then
		regenerate1(model1,backup1)
	end
end
regen.Changed:connect(checkRegen)