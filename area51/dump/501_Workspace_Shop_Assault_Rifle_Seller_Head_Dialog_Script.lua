script.Parent.DialogChoiceSelected:connect(function(player, choice)
	if (choice == script.Parent.Choice1) then
		if (player.leaderstats.Credits.Value >= 100) then
			gun = game.Lighting["MG16"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 100
			script.Parent.Choice1.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice1.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice2) then
		if (player.leaderstats.Credits.Value >= 172) then
			gun = game.Lighting["BR58"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 172
			script.Parent.Choice2.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice2.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice3) then
		if (player.leaderstats.Credits.Value >= 225) then
			gun = game.Lighting["2xMG16"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 225
			script.Parent.Choice3.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice3.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice4) then
		if (player.leaderstats.Credits.Value >= 315) then
			gun = game.Lighting["SR87"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 315
			script.Parent.Choice4.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice4.ResponseDialog = "You Dont Have Credits..."
		end
		return
   end	
end)