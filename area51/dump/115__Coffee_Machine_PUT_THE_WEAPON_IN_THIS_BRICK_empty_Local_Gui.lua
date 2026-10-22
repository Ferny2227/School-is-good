drinksleft = 3
Bin = script.Parent


function onButton1Down(mouse)
if Bin.Drink.Transparency == 1 then 
m = Instance.new("Hint") 
m.Text = "Your cup is empty!"
m.Parent = Bin.Parent
wait(1)
m:remove()
return end
Bin.Parent.Torso:findFirstChild("Right Shoulder").DesiredAngle = 2
wait()
Bin.Parent.Torso:findFirstChild("Right Shoulder").DesiredAngle = 2
wait()
Bin.Parent.Torso:findFirstChild("Right Shoulder").DesiredAngle = 2
wait()
Bin.Parent.Torso:findFirstChild("Right Shoulder").DesiredAngle = 2
wait()
Bin.Parent.Torso:findFirstChild("Right Shoulder").DesiredAngle = 2
wait()
Bin.Parent.Torso:findFirstChild("Right Shoulder").DesiredAngle = 2
wait()
Bin.Parent.Torso:findFirstChild("Right Shoulder").DesiredAngle = 2
wait()
drinksleft = drinksleft - 1
if drinksleft == 0 then
Bin.Drink.Transparency = 1
Bin.Drink.Reflectance = 0
drinksleft = 3
Bin.Name = "[empty]"
end
end

function onSelected(mouse)
	mouse.Button1Down:connect(function() onButton1Down(mouse) end)
end
Bin.Equipped:connect(onSelected)

