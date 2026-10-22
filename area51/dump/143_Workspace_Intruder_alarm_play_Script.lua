brick=script.Parent
other=brick.Parent.stop
music=brick.Parent.music

function onClicked()

music:Play()

end

script.Parent.ClickDetector.MouseClick:connect(onClicked)
