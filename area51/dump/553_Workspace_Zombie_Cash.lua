local Humanoid = script.Parent.Zombie -- Or Zombie Or Whatever 
function PwntX_X() 
local tag = Humanoid:findFirstChild("creator") 
	if tag ~= nil then 
		if tag.Value ~= nil then 
local Leaderstats = tag.Value:findFirstChild("leaderstats") 
			if Leaderstats ~= nil then 
Leaderstats.Cash.Value = Leaderstats.Cash.Value + 14 
wait(0.1)
script:remove()
			end 
		end 
	end 
end 
Humanoid.Died:connect(PwntX_X) 