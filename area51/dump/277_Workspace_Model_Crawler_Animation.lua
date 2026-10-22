------------------
--SPAWNING--
------------------
------------------
------------------


wait(1)
function waitForChild(parent, childName)
	while true do
		local child = parent:findFirstChild(childName)
		if child then
			return child
		end
		parent.ChildAdded:wait()
	end
end

local Figure = script.Parent
local Torso = waitForChild(Figure, "Torso")
local RightShoulder = waitForChild(Torso, "Right Shoulder")
local LeftShoulder = waitForChild(Torso, "Left Shoulder")
local RightHip = waitForChild(Torso, "Right Hip")
local LeftHip = waitForChild(Torso, "Left Hip")
local Neck = waitForChild(Torso, "Neck")
local Humanoid = waitForChild(Figure, "Zombie")
local pose = "Standing"

local toolAnim = "None"
local toolAnimTime = 0

local isSeated = false

Skins = {"Sand red","Sand green", "Medium green", "Sand blue", "Brick yellow"}
Skin = Skins[math.random(1,#Skins)]
Shirts = {"Reddish brown","Brown", "Medium stone grey", "Lavender", "Grime"}
Shirt = Shirts[math.random(1,#Shirts)]
Pants = {"Reddish brown","Brown", "Medium stone grey", "Lavender", "Grime"}
Pant = Pants[math.random(1,#Pants)]

miked=script.Parent

itlh=miked.Torso:findFirstChild("Left Hip")
itlh.Part0=miked.Torso
itlh.Part1=miked:findFirstChild("Left Leg")
miked:findFirstChild("Left Leg").BrickColor = BrickColor.new(Pant)
itlh.C0=CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) * CFrame.fromEulerAnglesXYZ(-0.1,0,0)

itrh=miked.Torso:findFirstChild("Right Hip")
itrh.Part0=miked.Torso
itrh.Part1=miked:findFirstChild("Right Leg")
miked:findFirstChild("Right Leg").BrickColor = BrickColor.new(Pant)
itrh.C0=CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)* CFrame.fromEulerAnglesXYZ(-0.1,0,0)

itls=miked.Torso:findFirstChild("Left Shoulder")
itls.Part1=miked.Torso
itls.C0=CFrame.new(1.4, 2.3, 2.4, 0, 0, -1, 0, 1, 0, 1, 0, 0) * CFrame.fromEulerAnglesXYZ(0.1,0,0)
itls.Part0=miked:findFirstChild("Left Arm")
miked:findFirstChild("Left Arm").BrickColor = BrickColor.new(Skin)

ith=miked.Torso:findFirstChild("HunchMotor")
ith.Part0=miked.Torso
ith.Part1=miked:findFirstChild("Hunch")
ith.C0=CFrame.new(-0.5, -1, -0.8, 0, 0, 1, 0, 1, 0, -1, 0, 0) * CFrame.fromEulerAnglesXYZ(0,0,math.rad(90))
miked:findFirstChild("Hunch").BrickColor = BrickColor.new(Shirt)

itrs=miked.Torso:findFirstChild("Right Shoulder")
itrs.Part1=miked.Torso
itrs.C0=CFrame.new(-1.4, 2.3, 2.4, 0, 0, 1, 0, 1, 0, -1, 0, 0)* CFrame.fromEulerAnglesXYZ(0.1,0,0)
itrs.Part0=miked:findFirstChild("Right Arm")
miked:findFirstChild("Right Arm").BrickColor = BrickColor.new(Skin)

ithe=miked.Head:findFirstChild("HeadMotor")
ithe.Part0=miked.Head
ithe.Part1=miked:findFirstChild("FakeHead")
ithe.C0=CFrame.new(-0.5, -1.5, -2.5, 0, 0, 1, 0, 1, 0, -1, 0, 0) * CFrame.fromEulerAnglesXYZ(0,0, 0.3)
miked:findFirstChild("FakeHead").BrickColor = BrickColor.new(Skin)
miked.Head:makeJoints()
for i,v in ipairs(script.Parent:GetChildren()) do
	if v.className == "Part" then
	v.Anchored = false
	end
end

function onRunning(speed)
	if isSeated then return end

	if speed>0 then
		pose = "Running"
	else
		pose = "Standing"
	end
end

function onDied()
	pose = "Dead"

	local parts = Figure:GetChildren()
	for i=1,#parts do
		if parts.className == "Part" then
			Debris.AddItem(parts[i], 60)
		end
	end
end

function getTool()
	
	kidTable = Figure:children()
	if (kidTable ~= nil) then
		numKids = #kidTable
		for i=1,numKids do
			if (kidTable[i].className == "Tool") then return kidTable[i] end
		end
	end
	
	return nil
end

function getToolAnim(tool)

	c = tool:children()
	for i=1,#c do
		if (c[i].Name == "toolanim" and c[i].className == "StringValue") then
			return c[i]
		end
	end
	return nil
end

function animateTool()
	
	if (toolAnim == "None") then
		RightShoulder.DesiredAngle = -1.57
		return
	end

	if (toolAnim == "Slash") then
		RightShoulder.MaxVelocity = 0.5
		RightShoulder.DesiredAngle = 0
		return
	end

	if (toolAnim == "Lunge") then
		RightShoulder.MaxVelocity = 0.5
		LeftShoulder.MaxVelocity = 0.5
		RightHip.MaxVelocity = 0.5
		LeftHip.MaxVelocity = 0.5
		RightShoulder.DesiredAngle = -1.57
		LeftShoulder.DesiredAngle = 1.0
		RightHip.DesiredAngle = 1.57
		LeftHip.DesiredAngle = 1.0
		return
	end
end

function move(time)
	local amplitude
	local frequency

	amplitude = 0.1
	frequency = 1

	RightShoulder.MaxVelocity = 0.15
	LeftShoulder.MaxVelocity = 0.15
	if (pose == "Running") then
		amplitude = .2
		frequency = 9
	end


	desiredAngle = amplitude * math.sin(time*frequency)
	if pose~="Dancing" then
		RightShoulder.DesiredAngle = -desiredAngle
		LeftShoulder.DesiredAngle = -desiredAngle
		RightHip.DesiredAngle = -desiredAngle
		LeftHip.DesiredAngle = -desiredAngle
	end
		


	local tool = getTool()

	if tool ~= nil then
	
		animStringValueObject = getToolAnim(tool)

		if animStringValueObject ~= nil then
			toolAnim = animStringValueObject.Value
			-- message recieved, delete StringValue
			animStringValueObject.Parent = nil
			toolAnimTime = time + .3
		end

		if time > toolAnimTime then
			toolAnimTime = 0
			toolAnim = "None"
		end

		animateTool()

		
	else
		toolAnim = "None"
		toolAnimTime = 0
	end
end


-- connect events
-----------------------------------------------------------------------------------------------------------------------

function unequip()
	local items=script.Parent:children()
	for i=1, #items do
		if items[i].className=="Tool" then items[i]:remove() end
	end
end




-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------


Humanoid.Died:connect(onDied)
Humanoid.Running:connect(onRunning)
Humanoid.Jumping:connect(onJumping)
Humanoid.Climbing:connect(onClimbing)
Humanoid.GettingUp:connect(onGettingUp)
Humanoid.FreeFalling:connect(onFreeFall)
Humanoid.FallingDown:connect(onFallingDown)
Humanoid.Seated:connect(onSeated)


--[[

function newSound(id)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Parent = script.Parent.Head
	return sound
end


local sDied = newSound("rbxasset://sounds/uuhhh.wav")
local sFallingDown = newSound("rbxasset://sounds/splat.wav")
local sFreeFalling = newSound("rbxasset://sounds/swoosh.wav")
local sGettingUp = newSound("rbxasset://sounds/hit.wav")
local sJumping = newSound("rbxasset://sounds/button.wav")
local sRunning = newSound("rbxasset://sounds/bfsl-minifigfoots1.mp3")
sRunning.Looped = true

local Figure = script.Parent
local Head = waitForChild(Figure, "Head")
local Humanoid = waitForChild(Figure, "Humanoid")


function onDied()
	sDied:play()
end

function onState(state, sound)
	if state then
		sound:play()
	else
		sound:pause()
	end
end

function onRunning(speed)
	if speed>0 then
		sRunning:play()
	else
		sRunning:pause()
	end
end


Humanoid.Died:connect(onDied)
Humanoid.Running:connect(onRunning)
Humanoid.Jumping:connect(function(state) onState(state, sJumping) end)
Humanoid.GettingUp:connect(function(state) onState(state, sGettingUp) end)
Humanoid.FreeFalling:connect(function(state) onState(state, sFreeFalling) end)
Humanoid.FallingDown:connect(function(state) onState(state, sFallingDown) end)
--]]

local nextTime = 0
local runService = game:service("RunService");

while Figure.Parent~=nil do
	time = runService.Stepped:wait()
	if time > nextTime then
		move(time)
		nextTime = time + 0.1
	end
end
