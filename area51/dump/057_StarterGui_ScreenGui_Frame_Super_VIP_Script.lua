--huner2
function OnMouseHover()
script.Parent.BackgroundColor3 = BrickColor.new(script.OnColor.Value)
end
script.Parent.MouseEnter:connect(OnMouseHover)

function OnMouseNotHover()
script.Parent.BackgroundColor3 = BrickColor.new(script.OffColor.Value)
end
script.Parent.MouseLeave:connect(OnMouseNotHover)