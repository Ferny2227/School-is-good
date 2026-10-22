-- Recommended: Place this in the VIP Door
----------------------------------------------------------------------- 
PassOrShirtID = 139486132 -- Change this to your asset/shirt/badge/pass ID
Door = script.Parent -- Change this to the door (if needed)
OpenTime = 1 -- Change how long you want the door open
Prompt = true -- true = if the player doesn't have the item, prompt a screen to let them buy it. false = kill the player.
-----------------------------------------------------------------------
-- Made by Nikilis --


--Do not touch below--
Serv = game:GetService("BadgeService")
MServ = game:GetService("MarketplaceService")
if not _G.Players then
	_G.Players = {
		[PassOrShirtID] = {};
	}
	print("Players Created")
elseif not _G.Players[PassOrShirtID] then
	_G.Players[PassOrShirtID] = {};
	print("Players.Pass created")
end

Table = _G.Players[PassOrShirtID]

function CheckPlayer(player2)
	for i = 1,#Table do
		if Table[i] == player2 then
			return true
		end
	end
	return false
end

Door.Touched:connect(function(hit)
	if game.Players:GetPlayerFromCharacter(hit.Parent) then
		player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if Serv:UserHasBadge(player.userId,PassOrShirtID) or CheckPlayer(player) then
			Door.CanCollide = false; Door.Transparency = 0.5;
			wait(OpenTime);
			Door.CanCollide = true; Door.Transparency = 0;
		else
			if Prompt then -- nikilis
				MServ:PromptPurchase(player,PassOrShirtID)
				h = player.Character:FindFirstChild("Humanoid")
				if h then h.WalkSpeed = 16 end
				local con;
				con = MServ.PromptPurchaseFinished:connect(function(ply,asset,purch)
					if ply == player and asset == PassOrShirtID then
						con:disconnect()
						if purch then
							if h then h.WalkSpeed = 16 end
							table.insert(Table,player)
						else
							h.Walkspeed = 16
						end
					end	
				end)
			else
				h.Walkspeed = 16
				end
		end
	end
end)




















-- Made by Nikilis

