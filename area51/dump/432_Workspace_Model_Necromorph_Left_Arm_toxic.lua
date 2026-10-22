wait(1)
owner=script.Parent.Parent.Name

function onTouched(part)
	if part.Parent ~= nil then
		local h = part.Parent:findFirstChild("Humanoid")
			if h~=nil then
				if cantouch~=0 then
					if h.Parent.Name~=owner then
						
						if h.Parent:findFirstChild("Left Arm")~=nil then return end

						cantouch=0

						local larm=h.Parent:findFirstChild("Left Arm")
						local rarm=h.Parent:findFirstChild("Right Arm")
						
						if larm~=nil then
							larm:remove()
						end
						if rarm~=nil then
							rarm:remove()
						end
						local zee=script.Parent.Parent:findFirstChild("Left Arm")
						if zee~=nil then
							local zlarm=zee:clone()
							local zrarm=zee:clone()
							if zlarm~=nil then

							local rot=CFrame.new(0, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
								zlarm.CFrame=h.Parent.Torso.CFrame * CFrame.new(Vector3.new(-1.5,0.5,-0.5)) * rot
								zrarm.CFrame=h.Parent.Torso.CFrame * CFrame.new(Vector3.new(1.5,0.5,-0.5)) * rot
								zlarm.Parent=h.Parent
								zrarm.Parent=h.Parent
								zlarm:makeJoints()
								zrarm:makeJoints()
								zlarm.Anchored=false
								zrarm.Anchored=false
								wait(0.1)
								h.Parent.Head.Color=zee.Color
							else print("no zee"); return end
						end
						wait(1)
						cantouch=1
					end
				end
			end
	end
end

script.Parent.Touched:connect(onTouched)
