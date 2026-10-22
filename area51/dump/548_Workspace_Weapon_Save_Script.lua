-------------------------------------------------------------------------
------------KeepWeapons on death script---------
--makes you keep any weapons you pick up after you die-
--and respawn.

--simply put the script in the map and it will work.

local wm = Instance.new("Model")
wm.Name = "Weaps"

function give(weap, player) --add a weap to a player's weaps
	--return if they allready have a copy
	for _, w in ipairs(player.Weaps:GetChildren()) do
		if w.Name == weap.Name then return end
	end
	--return if the weaps is a startpack one
	for _, w in ipairs(game.StarterPack:GetChildren()) do
		if w.Name == weap.Name then return end
	end
	--add it to thier weaps
	weap:clone().Parent = player.Weaps
end

game.Players.ChildAdded:connect(function(p)
	wm:clone().Parent = p
	wait()
	p.Character.ChildAdded:connect(function(wep)
		if wep.className == "Tool" then
			give(wep, p)
		end
	end)
	p.Changed:connect(function(pr)
		if pr == "Character" then
			for _, w in ipairs(p.Weaps:GetChildren()) do
				w:clone().Parent = p.Backpack
			end
			p.Character.ChildAdded:connect(function(wep)
				if wep.className == "Tool" then
					give(wep, p)
				end
			end)
		end
	end)
	p.Backpack.ChildAdded:connect(function(h)
		if h.className == "HopperBin" then
			give(h, p)		
		end
	end)
end)
	
