-- a non-VIP player walking into every VIP door: not frozen, not killed, door stays shut
local p = JOINER
local out = {}
for _, d in ipairs(workspace:GetChildren()) do
	if d.Name == "VIP Door" or d.Name == "VIP-Door" or d.Name == "OneWayDoor" then
		CTX = SERVER d.Touched:_fire(p.Character.Torso) runFor(2)
		out[#out + 1] = d.Name .. ": health " .. p.Character.Humanoid.Health .. ", walkspeed " .. p.Character.Humanoid.WalkSpeed .. ", door solid " .. tostring(d.CanCollide)
	end
end
return out
