-- Kill Brick: kills people on foot. Players sitting in a car are safe (these invisible bricks lie right on
-- top of / under the bridges, and drivers kept dying when their jeep brushed or tipped over them).
local function onTouched(part)
	local h = part.Parent and part.Parent:FindFirstChild("Humanoid")
	if h ~= nil and not h.Sit then
		h.Health = 0
	end
end
script.Parent.Touched:connect(onTouched)
