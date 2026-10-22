print ("VIP T-Shirt Door Script Loaded")

-- list of account names allowed to go through the door.
permission = { "Triculate" } -- This is how many people can still get through, so u don't have to change shirts. You can also have another friend here.

-- TextureId of the VIP shirt.
texture = "http://www.roblox.com/asset/?id=141525946" -- Go to the wiki below this script to find out how to change the shirt. And paste the link in between the "" marks.

function checkOkToLetIn(name) 
	for i = 1,#permission do 
		-- convert strings to all upper case, otherwise we will let in 
		-- "Username" but not "username" or "uSERNAME" 
		if (string.upper(name) == string.upper(permission[i])) then return true end 
	end 
	return false 
end 

local Door = script.Parent

function onTouched(hit) 
	print("Door Hit") 
	local human = hit.Parent:findFirstChild("Humanoid") 
	if (human ~= nil ) then 
		if human.Parent.Torso.roblox.Texture == texture then --the shirt 
			Door.Transparency = 0.7 
			Door.CanCollide = false 
			wait(4) -- this is how long the door is open 
			Door.CanCollide = true 
			Door.Transparency = 0 
			-- a human has touched this door! 
			print("Human touched door") 
			-- test the human's name against the permission list 
		elseif (checkOkToLetIn(human.Parent.Name)) then 
			print("Human passed test") 
			Door.Transparency = 0.7
			Door.CanCollide = false 
			wait(4) -- this is how long the door is open
			Door.CanCollide = true 
			Door.Transparency = 0 
		end 
	end 
end 

script.Parent.Touched:connect(onTouched)

