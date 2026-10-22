function check()
	if script.Parent.Recoil.Value > 3 then
		script.Parent.Recoil.Value = script.Parent.Recoil.Value - 1
	elseif script.Parent.Recoil.Value <= 3 then
		script.Parent.Recoil.Value = 3
	end
end

function cap()
	if script.Parent.Recoil.Value > 10 then
	script.Parent.Recoil.Value = 10
	end
end

while true do
	check()
	cap()
	wait(0.15)
end
