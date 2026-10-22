hits = script.Parent.hit --This keeps track of how much "hp" the tree has left
local newtree = script.Parent:clone() --for inserting a new tree later

while true do --infinite loop
if hits.Value < 1 then --if the tree has less than 1 "hp" then
	script.Parent:BreakJoints() --make tree able to fall over. 
	wait(3) --wait a while
	script.Parent:remove() --remove the tree
	wait(10) --wait a while
	newtree.Parent = game.Workspace --insert a new tree
	newtree:MakeJoints() --make tree unable to fall over
end
wait(1) --wait a while before checking trees hp again
end
