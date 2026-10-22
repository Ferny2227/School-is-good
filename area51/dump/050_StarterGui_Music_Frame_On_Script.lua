function onClicked()
script.Parent.Parent.Sound.Volume = 0
script.Parent.Parent.TextLabel.Text = "Music Off"
script.Parent.Parent.Off.Visible = true
script.Parent.Visible = false

end 

script.Parent.ClickDetector.MouseClick:connect(onClicked)
