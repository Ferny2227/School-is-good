
game.Players.PlayerAdded:connect(function (player)
	repeat wait() until player.Character
	function chat (msg)
		if msg:lower() == "/fixshop" then 
			game.Workspace.RegShop:remove()
			wait(.05)
			game.ReplicatedStorage.RegShop:Clone().Parent = game.Workspace
			print("Shop Fixed")
			end
	end
	player.Chatted:connect(chat)
end)