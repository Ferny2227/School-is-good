buttons=script.Parent:GetChildren()
amount=script.Parent.Parent.amount--What value to change 
--Name the buttons what the value should be (except TextBoxes)
debounce=false--Don't ask me why this needs debounce, but it does.
-----------
function select(button)
	if not debounce then
		debounce=true
		for a=1, #buttons do
			if buttons[a]~=script then
				if buttons[a]==button then
					button.BackgroundColor3=Color3.new(1,1,1)
					if button:IsA("TextBox") then
						amount.Value=button.Text
						else amount.Value=tonumber(button.Name); print("selection not TextBox: "..button.Name)
					end
					else
					buttons[a].BackgroundColor3=Color3.new(234/255,234/255,234/255)
				end
			end
		end
	wait(2)
	debounce=false
	end
end
--Gotta connect them alllllll
for b=1,#buttons do
	if buttons[b]~=script and not buttons[b]:IsA("TextBox") then
		buttons[b].MouseButton1Click:connect(function() select(buttons[b]) end)
		elseif buttons[b]:IsA("TextBox") then
		buttons[b].Changed:connect(function(prop) if prop=="Text" then if buttons[b].Text~="" then select(buttons[b]) end end end)
	end
end
-----------------