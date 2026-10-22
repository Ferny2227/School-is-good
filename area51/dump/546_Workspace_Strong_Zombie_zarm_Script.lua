local debounce = false 
local HealthLoss = 30 -- Change this to the damage you need. 
function OnTouched(Part) 
if Part.Parent ~= nil then--Keep Parentless blocks from breaking it. 
if debounce == false and Part.Parent:findFirstChild("Humanoid") ~= nil then 
debounce = true 
Part.Parent:findFirstChild("Humanoid"):TakeDamage(HealthLoss) 
wait(2)--Wait two seconds before the brick can hurt someone. 
debounce = false 
end 
end 
end 
script.Parent.Touched:connect(OnTouched)