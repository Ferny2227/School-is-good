Tool = script.Parent

colors = {199}

function fire(v)

	Tool.Handle.Fire:play()
	

	local vCharacter = Tool.Parent
	local vPlayer = game.Players:playerFromCharacter(vCharacter)

	local missile = Instance.new("Part")

        

	local spawnPos = vCharacter.PrimaryPart.Position
	


	spawnPos  = spawnPos + (v * 8)

	missile.Position = spawnPos
	missile.Size = Vector3.new(0.1,0.1,0.1)
	missile.Velocity = v * 850 + Vector3.new(math.random(-8,8),math.random(-8,8),math.random(-8,8))
	missile.BrickColor = BrickColor.new(colors[math.random(1, #colors)])
	missile.Shape = 0
	missile.BottomSurface = 0
	missile.TopSurface = 0
	missile.Name = "Paintball"
	missile.Elasticity = 0
	missile.Reflectance = 0
	missile.Friction = 0

local mesh = Instance.new("SpecialMesh") 
mesh.MeshType = "Sphere" 
mesh.Scale = Vector3.new(0.4,0.4,0.4) 
mesh.Parent = missile

	local force = Instance.new("BodyForce")
	force.force = Vector3.new(0,100,0)
	force.Parent = missile
	
	Tool.BrickCleanup:clone().Parent = missile

	local new_script = script.Parent.Paintball:clone()
	new_script.Disabled = false
	new_script.Parent = missile

	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Value = vPlayer
	creator_tag.Name = "creator"
	creator_tag.Parent = missile
	


	missile.Parent = game.Workspace
	--wait(0.05)
	--fire(
	

end


function check(en)
---------------------------------------Function start here.
if (Tool.Enabled == false) then
return false
end--end for if!
-------------------------------
if (Tool.Enabled == true) then
return true
end
---------------------------------------Function end here.
end


Tool.Enabled = true
function onActivated()

	if not Tool.Enabled then
		return
	end

	--Tool.Enabled = false

	local character = Tool.Parent;
	local humanoid = character.Humanoid
	if humanoid == nil then
		print("Humanoid not found")
		return 
	end

	local targetPos = humanoid.TargetPoint
	local lookAt = (targetPos - character.Head.Position).unit
	
	if (check()) then
	fire(lookAt)
	wait(0.1)
	onActivated()
	end
	return

	--Tool.Enabled = true
end


script.Parent.Activated:connect(onActivated)
