shlock = script.Parent.open
function onClick()
	if shlock.Value == false then
	script.Parent.Text = "Close VIP Shop"
	script.Parent.Parent.Frame.Visible = true
	shlock.Value = true
	else
	script.Parent.Parent.Frame.Visible = false
	script.Parent.Text = "Open VIP Shop"
	shlock.Value = false
	end
end
script.Parent.MouseButton1Up:connect(onClick)

 