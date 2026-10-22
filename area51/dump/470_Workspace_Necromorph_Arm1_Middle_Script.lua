function onTouched(part)
local h = part.Parent:findFirstChild("Humanoid")
if h~=nil then
h.Health = 0
end
end
script.Parent.Touched:connect(onTouched)


