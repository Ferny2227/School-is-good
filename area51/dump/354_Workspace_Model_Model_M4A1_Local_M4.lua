local Tool = script.Parent;
local relparts = {Tool.c1, Tool.c2}


enabled = true

function onButton1Down(mouse)
	if not enabled then
		return
	end
	mouse.Icon = "http://www.roblox.com/asset/?id=11001009"
end
function eject(v)
	for i = 1, #relparts do
		relparts[i].Transparency = 1
	end
	local m = Instance.new("Model")
	m.Name = "Magazine"
	m.Parent = workspace
	for i = 1, #relparts do
		local c = relparts[i]:Clone()
		c.CanCollide = true
		c.Parent = m
	end
	local c = m:GetChildren()
	for i = 1, #c do
		c[i].Transparency = 0
		if c[i] ~= m.c1 then
			local c0 = m.c1.CFrame:inverse()
			local c1 = c[i].CFrame:inverse()
			local w = Instance.new("Weld")
			w.Parent = m.c1
			w.Part0 = w.Parent
			w.Part1 = c[i]
			w.C0 = c0
			w.C1 = c1
		end
	end
	local s = Tool.BrickCleanup:Clone()
	s.Disabled = false
	s.Parent = m
end
function reload()
	script.Parent.isReloading.Value = true
	Tool.Enabled = false
	script.Parent.Handle.Reload:play()
	Tool.c1.Transparency = 1
	Tool.c2.Transparency = 1
	eject(lookAt)
	armReload()
	script.Parent.Ammo.Value = 30
	Tool.c1.Transparency = 0
	Tool.c2.Transparency = 0
	wait(0.2)
	gunOut()
	wait(0.4)
	Tool.b2a.Transparency = 0
	Tool.b1b.Transparency = 1
	Tool.b1c.Transparency = 1
	Tool.b2b.Transparency = 0
	Tool.b2c.Transparency = 0
	Tool.r1.Transparency = 1
	LW.C1 = CFrame.new(0.24, 1.4, -0.3)
	wait()
	Tool.b3a.Transparency = 0
	Tool.b2b.Transparency = 1
	Tool.b2c.Transparency = 1
	Tool.b3b.Transparency = 0
	Tool.b3c.Transparency = 0
	Tool.r2.Transparency = 1
	LW.C1 = CFrame.new(0.24, 1, -0.7)
	wait(0.35)
	Tool.b3a.Transparency = 1
	Tool.b3b.Transparency = 1
	Tool.b3c.Transparency = 1
	Tool.b2b.Transparency = 0
	Tool.b2c.Transparency = 0
	Tool.r2.Transparency = 0
	LW.C1 = CFrame.new(0.24, 1.2, -0.5)
	wait()
	Tool.b2a.Transparency = 1
	Tool.b2b.Transparency = 1
	Tool.b2c.Transparency = 1
	Tool.b1b.Transparency = 0
	Tool.b1c.Transparency = 0
	Tool.r1.Transparency = 0
	LW.C1 = CFrame.new(0.24, 1.4, -0.3)
	wait(0.3)
	gunReturn()
	script.Parent.Enabled = true
	script.Parent.isReloading.Value = false
end
function onButton1Up(mouse)
enabled = false
Tool.Enabled = false
wait(0.15)
enabled = true
Tool.Enabled = true
end
Tool.Equipped:connect(onEquippedLocal)
function onEquippedLocal(mouse)
	check2 = Tool.Script:clone()
	if mouse == nil then
		print("Mouse not found")
		return 
	end
	mouse.Icon = "http://www.roblox.com/asset/?id=11001009"
	mouse.Button1Down:connect(function() onButton1Down(mouse) end)
	mouse.Button1Up:connect(function() onButton1Up(mouse)end)
	mouse.KeyDown:connect(onKeyDown)
	local m = Instance.new("Message")
	m.Parent = game.Players.LocalPlayer
	m.Name = ("ID175")
	m.Text = "Weapon made by Xilver101"
	check2.Parent = Tool
	wait(2)
	m:remove()
end
Tool.Equipped:connect(onEquippedLocal)
function onKeyDown(key)
	key:lower()
	if key == "r" then
		if script.Parent.Ammo.Value < 30 and Tool.enabled == true and script.Parent.isReloading.Value == false then		
		reload()
	end
	end
end
selected = false
RSH, LSH = nil, nil
GRP = nil
RW, LW = Instance.new("Weld"), Instance.new("Weld")
anim = "none"
function WaitForChild(obj, ch_n)
	local t = time()
	while not obj:FindFirstChild(ch_n) and time() - t < 10 do wait(0.1) end
	return obj:FindFirstChild(ch_n)
end
script.Parent.Equipped:connect(function()
	if selected then return end
	selected = true
	player = game.Players:playerFromCharacter(script.Parent.Parent)
	local ch = script.Parent.Parent
	WaitForChild(ch, "Torso")
	RSH = WaitForChild(ch.Torso, "Right Shoulder")
	LSH = WaitForChild(ch.Torso, "Left Shoulder")
	GRP = WaitForChild(ch["Right Arm"], "RightGrip")
	_G.Grip = GRP
	--
	RSH.Part1 = nil
	LSH.Part1 = nil
	--
	RW.Part0 = ch.Torso
	RW.C0 = CFrame.new(1.5, 0.5, 0) --* CFrame.fromEulerAnglesXYZ(1.3, 0, -0.5)
	RW.C1 = CFrame.new(0, 0.5, 0)
	RW.Part1 = ch["Right Arm"]
	RW.Parent = ch.Torso
	_G.R = RW
	--
	LW.Part0 = ch.Torso
	LW.C0 = CFrame.new(-1.5, 0.5, 0) --* CFrame.fromEulerAnglesXYZ(1.7, 0, 0.8)
	LW.C1 = CFrame.new(0, 0.5, 0)
	LW.Part1 = ch["Left Arm"]
	LW.Parent = ch.Torso
	_G.L = LW
	--
	GRP.C0 = CFrame.new(0, -1, 0) * CFrame.fromEulerAnglesXYZ(-1.22, -0.45, 0.22)
	for i = 0, 1, 0.05 do
		wait()
		RW.C0 = CFrame.new(1.5, 0.5, 0.25) * CFrame.fromEulerAnglesXYZ(1.3*i, 0, -0.5*i)
		LW.C0 = CFrame.new(-1.5, 0.5, 0) * CFrame.fromEulerAnglesXYZ(1.7*i, 0, 0.8*i)	
		LW.C1 = CFrame.new(0.3*i, 1+1*i, 0)
	end
	wait()
	local rg = (ch["Right Arm"]:FindFirstChild("RightGrip") or GRP)
	if rg ~= GRP then
		GRP.Parent = ch["Right Arm"]
		rg:remove()
	end
end)
script.Parent.Unequipped:connect(function()
	selected = false
	local pl = player
	RW.C0 = CFrame.new(0,0,0) * CFrame.fromEulerAnglesXYZ(0,0,0)
	LW.C0 = CFrame.new(0,0,0) * CFrame.fromEulerAnglesXYZ(0,0,0)	
	LW.C1 = CFrame.new(0,0,0)
	RW.Parent = nil
	LW.Parent = nil
	RSH.Part1 = pl.Character["Right Arm"]
	LSH.Part1 = pl.Character["Left Arm"]
end)
function armReload()
	for i = 0, 1, 0.1 do
		wait()
		LW.C0 = CFrame.new(-1.5, 0.5, 0) * CFrame.fromEulerAnglesXYZ(1.3*i, 0, 0.9*i)	
		LW.C1 = CFrame.new(0.3*i, 1+1*i, 0)
	end
end
function gunOut()
	for i = 0, 0.3, 0.06 do
		wait()
		GRP.C0 = CFrame.new(0+i, -1-i, 0+(2*i)) * CFrame.fromEulerAnglesXYZ(-2.22, -0.45, 0.42)
		LW.C0 = CFrame.new(-1, 0.5, 0) * CFrame.fromEulerAnglesXYZ(4.2, 0, 2.9)	
		LW.C1 = CFrame.new(0.8*i, 1.1+i, -0.3)
	end
end
function gunReturn()
	RW.C0 = CFrame.new(1.5, 0.5, 0.25) * CFrame.fromEulerAnglesXYZ(1.3, 0, -0.5)
	LW.C0 = CFrame.new(-1.5, 0.5, 0) * CFrame.fromEulerAnglesXYZ(1.7, 0, 0.8)	
	LW.C1 = CFrame.new(0.3, 1+1, 0)
	GRP.C0 = CFrame.new(0, -1, 0) * CFrame.fromEulerAnglesXYZ(-1.22, -0.45, 0.22)
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Tool = script.Parent
local relparts = {Tool.c1, Tool.c2}
colors = {26}
function fire(v)
	Tool.Handle.Fire:play()
	local vCharacter = Tool.Parent
	local vPlayer = game.Players:GetPlayerFromCharacter(Tool.Parent)
	local missile = Instance.new("Part")
	local shellcasing = Instance.new("Part")
	local spawnPos = Tool.Barrel.Position
	local otherspawnPos = Tool.r2.Position
	spread = Tool.Recoil.Value
	spawnPos  = spawnPos + (v* 8)
	missile.Position = spawnPos
	missile.Locked = true
	missile.Size = Vector3.new(1,1,1)
	missile.Velocity = v * 750 + Vector3.new(math.random(-(spread),(spread)),math.random(-(spread),(spread)),math.random(-(spread),(spread)))
	missile.BrickColor = BrickColor.new(colors[math.random(1, #colors)])
	missile.Shape = 0
	missile.BottomSurface = 0
	missile.TopSurface = 0
	missile.Name = "Paintball"
	missile.Elasticity = 0
	missile.Friction = 0
	shellcasing.Position = otherspawnPos
	shellcasing.Size = Vector3.new(1,1,1)
	shellcasing.Velocity = v * (math.random(5,15))
	shellcasing.BrickColor = BrickColor.new(24)
	shellcasing.Shape = 1
	shellcasing.BottomSurface = 0
	shellcasing.TopSurface = 0
	shellcasing.Name = "Shell Casing"
	shellcasing.Reflectance = 0.2
	local force = Instance.new("BodyForce")
	force.force = Vector3.new(0,100,0)
	force.Parent = missile
	local rot= Instance.new("BodyAngularVelocity")
	rot.angularvelocity = Vector3.new((math.random(20,30)), 0, 0)
	rot.Parent = shellcasing
	Tool.BrickCleanup:clone().Parent = missile
	local new_mesh = script.Parent.Mesh:clone()
	new_mesh.Parent = shellcasing
	local new_mesh2 = script.Parent.Mesh1:clone()
	new_mesh2.Parent = missile
	local new_script = script.Parent.Paintball:clone()
	new_script.Disabled = false
	new_script.Parent = missile
	local thingy = script.Parent.BrickCleanup:clone()
	thingy.Disabled = false
	thingy.Parent = shellcasing
	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Value = vPlayer
	creator_tag.Name = "creator"
	creator_tag.Parent = missile
	missile.Parent = game.Workspace
	Tool.Recoil.Value = Tool.Recoil.Value + 1
	shellcasing.Parent = game.Workspace
end
function check(en)
if (Tool.Enabled == false) then
return false
end
if (Tool.Enabled == true) then
return true
end
end
Tool.Enabled = true
function onActivated()
	if not Tool.Enabled then
		return
	end
	local character = Tool.Parent;
	local humanoid = character.Humanoid
	if humanoid == nil then
		print("Humanoid not found")
		return 
	end
	local targetPos = humanoid.TargetPoint
	local lookAt = (targetPos - character.Head.Position).unit
	local aim = Tool.Recoil.Value
	local targetPos = humanoid.TargetPoint
	if (check()) then
		if script.Parent.Ammo.Value >= 1 and script.Parent.isReloading.Value == false then
		fire(lookAt)
		script.Parent.Ammo.Value = script.Parent.Ammo.Value - 1
		Tool.r1.Transparency = 1
		Tool.r2.Transparency = 1
		Tool.r3.Transparency = 1
		RW.C0 = CFrame.new(1.5, 0.6, 0.55) * CFrame.fromEulerAnglesXYZ(1.3, 0, -0.5)
		LW.C0 = CFrame.new(-1.5, 0.55, 0.3) * CFrame.fromEulerAnglesXYZ(1.7, 0, 0.8)	
		wait()
		RW.C0 = CFrame.new(1.5, 0.6, 0.35) * CFrame.fromEulerAnglesXYZ(1.3, 0, -0.5)
		LW.C0 = CFrame.new(-1.5, 0.55, 0.1) * CFrame.fromEulerAnglesXYZ(1.7, 0, 0.8)	
		wait()
		RW.C0 = CFrame.new(1.5, 0.5, 0.25) * CFrame.fromEulerAnglesXYZ(1.3, 0, -0.5)
		LW.C0 = CFrame.new(-1.5, 0.5, 0) * CFrame.fromEulerAnglesXYZ(1.7, 0, 0.8)	
		Tool.r3.Transparency = 0
		Tool.r2.Transparency = 0
		wait()
		Tool.r1.Transparency = 0
		wait()
		onActivated()
		else
		Tool.Handle.Sound:play()
		end
	return
end
end
script.Parent.Activated:connect(onActivated)