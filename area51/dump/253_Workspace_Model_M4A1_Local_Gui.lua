local Tool = script.Parent;

enabled = true
function onButton1Down(mouse)
	if not enabled then
		return
	end

	enabled = true
	mouse.Icon = "http://www.roblox.com/asset/?id=2966012"

	--wait(.8)
	--mouse.Icon = "rbxasset://textures\\GunCursor.png"
	--enabled = true
	--mouse.Button1Up:connect(function() onButton1Up(mouse) end)

end


function onButton1Up(mouse)
enabled = false
Tool.Enabled = false
mouse.Icon = "http://www.roblox.com/asset/?id=2966012"

wait(.8)

mouse.Icon = "http://www.roblox.com/asset/?id=2966012"
enabled = true
Tool.Enabled = true
end

function onEquippedLocal(mouse)

	if mouse == nil then
		print("Mouse not found")
		return 
	end

	mouse.Icon = "http://www.roblox.com/asset/?id=2966012"
	mouse.Button1Down:connect(function() onButton1Down(mouse) end)	
	mouse.Button1Up:connect(function() onButton1Up(mouse)end)
end


Tool.Equipped:connect(onEquippedLocal)
