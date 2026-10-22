script.Parent.DialogChoiceSelected:connect(function(player, choice)
	if (choice == script.Parent.Choice1) then
		if (player.leaderstats.Credits.Value >= 563) then
			gun = game.Lighting["HG500"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 563
			script.Parent.Choice1.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice1.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice2) then
		if (player.leaderstats.Credits.Value >= 750) then
			gun = game.Lighting["DV99"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 750
			script.Parent.Choice2.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice2.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice3) then
		if (player.leaderstats.Credits.Value >= 375) then
			gun = game.Lighting["GK69"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 375
			script.Parent.Choice3.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice3.ResponseDialog = "You Dont Have Credits..."
		end
		return
	end
	if (choice == script.Parent.Choice4) then
		if (player.leaderstats.Credits.Value >= 1875) then
			gun = game.Lighting["XDV99"]:clone()
			gun.Parent = player.Backpack
			player.leaderstats.Credits.Value = player.leaderstats.Credits.Value - 1875
			script.Parent.Choice4.ResponseDialog = "Good Bye!"
		else
			script.Parent.Choice4.ResponseDialog = "You Dont Have Credits..."
		end
		return
   end	
end)