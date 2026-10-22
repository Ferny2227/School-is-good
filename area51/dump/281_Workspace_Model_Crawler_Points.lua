local Humanoid = script.Parent.Zombie
function PwntX_X() 
local tag = Humanoid:findFirstChild("creator") 
	if game.Players:findFirstChild(tag.Value) ~= nil then 
	local leaderstats =game.Players[tag.Value]:findFirstChild("leaderstats") 
		if leaderstats ~= nil then 
		leaderstats.Credits.Value = leaderstats.Credits.Value + 3
		wait(0.1)
		script:remove()
		end 
	end 
end 
Humanoid.Died:connect(PwntX_X) 