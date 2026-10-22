brick=script.Parent
other=brick.Parent.play
music=brick.Parent.music

function onClicked()

music:Stop()

end

script.Parent.ClickDetector.MouseClick:connect(onClicked)
