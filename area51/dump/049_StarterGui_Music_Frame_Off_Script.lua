function onClicked()
script.Parent.Parent.Sound.Volume = 0.5
script.Parent.Parent.TextLabel.Text = "Music On"
script.Parent.Parent.On.Visible = true
script.Parent.Visible = false

end 

script.Parent.ClickDetector.MouseClick:connect(onClicked)
