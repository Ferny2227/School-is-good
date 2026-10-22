function waitForChild(parent, childName)
	while true do
		local child = parent:findFirstChild(childName)
		if child then
			return child
		end
		parent.ChildAdded:wait()
	end
end

-- declarations

local Figure = script.Parent
local Head = waitForChild(Figure, "Head")
local Humanoid = waitForChild(Figure, "Humanoid")
Humanoid.Health=150
-- regeneration
while true do
	local s = wait(4)
	local health = Humanoid.Health
	if health > 0 and health < Humanoid.MaxHealth then
		health = health + 0.08 * s * Humanoid.MaxHealth
		if health * 1.05 < Humanoid.MaxHealth then
			Humanoid.Health = health
		else
			Humanoid.Health = Humanoid.MaxHealth
		end
	end
end
