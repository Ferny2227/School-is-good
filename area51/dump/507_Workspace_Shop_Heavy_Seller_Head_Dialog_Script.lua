script.Parent.DialogChoiceSelected:connect(function(player, choice)
	if (choice == script.Parent.Choice1) then
		if (player.leaderstats.Credits.Value >= 1) then
			gun = game.Lighting["HG500Gold"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 1
			script.Parent.Choice1.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice1.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice2) then
		if (player.leaderstats.Credits.Value >= 1) then
			gun = game.Lighting["DV99"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 1
			script.Parent.Choice2.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice2.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice3) then
		if (player.leaderstats.Credits.Value >= 1) then
			gun = game.Lighting["GK69Gold"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 1
			script.Parent.Choice3.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice3.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice4) then
		if (player.leaderstats.Credits.Value >= 1) then
			gun = game.Lighting["XDV99Gold"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 1
			script.Parent.Choice4.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice4.ResponseDialog = "You Dont Have Credits..."
		end
		return
   end	
end)