NameOfLeaderstatToDonate="Credits"
position=1

Main=script.Parent
Player=Main.Parent.Parent
button=Main.donate.playerbuttons.player
button.Parent=nil
function clicked()
	Main.donate.Visible=not Main.donate.Visible
end

function donate(to, amt)
	if Player.leaderstats:findFirstChild(NameOfLeaderstatToDonate).Value>= amt then
		if game.Players:findFirstChild(to) then
			Player.leaderstats:findFirstChild(NameOfLeaderstatToDonate).Value=Player.leaderstats:findFirstChild(NameOfLeaderstatToDonate).Value-amt
			game.Players:findFirstChild(to).leaderstats:findFirstChild(NameOfLeaderstatToDonate).Value=game.Players:findFirstChild(to).leaderstats:findFirstChild(NameOfLeaderstatToDonate).Value+amt
		end
	end
end

function playerButtons(plr)
	buttons=Main.donate.playerbuttons:GetChildren()
	if #buttons~=0 then
		for i=1, #buttons do
			buttons[i]:Remove()
		end
	end
	players=game.Players:GetPlayers()
	if #players==1 then
		Main.donate.Size=UDim2.new(0,195,0,180)
		Main.donate.playerbuttons.Size=UDim2.new(.85,0,0,25)
		Main.donate.donate.Position=UDim2.new(.05, 5, 0, 155)
		notif=button:Clone()
		notif.Parent=Main.donate.playerbuttons
		notif.AutoButtonColor=false
		notif.Text="No Players to donate to."
		else
		Main.donate.Size=UDim2.new(0,195,0,155+25*(#players-1))
		Main.donate.playerbuttons.Size=UDim2.new(.85,0,0,25*(#players-1))
		Main.donate.donate.Position=UDim2.new(.05, 5, 0, 130+25*(#players-1))
		pos=0
		for x=1, #players do
			if players[x].Name~=Player.Name then
				but=button:Clone()
				but.Parent=Main.donate.playerbuttons
				but.Text=players[x].Name
				but.Position=UDim2.new(0,0,0,25*pos)
				but.Name=players[x].Name
				but.MouseButton1Click:connect(function() Main.donate.player.Value=players[x].Name end)
				pos=pos+1
			end
		end
	end
end

function checkDonate()
	if Main.donate.amount.Value~=0 and game.Players:findFirstChild(Main.donate.player.Value) then
		Main.donate.Visible=false
		Main.checkdonate.Visible=true
		Main.checkdonate.Frame.to.Text="To: "..Main.donate.player.Value
		Main.checkdonate.Frame.amt.Text="Amount: $"..Main.donate.amount.Value	
		else Main.donate.donate.Text="Invalid amount or player!" wait(3) Main.donate.donate.Text="Donate"
	end
end



playerButtons()
Main.Frame.TextButton.MouseButton1Click:connect(clicked)

game.Players.PlayerAdded:connect(playerButtons)
game.Players.PlayerRemoving:connect(playerButtons)

Main.donate.donate.MouseButton1Click:connect(checkDonate)
Main.checkdonate.Frame.yes.MouseButton1Click:connect(function() donate(Main.donate.player.Value,Main.donate.amount.Value) Main.checkdonate.Visible=false end)

Main.checkdonate.Frame.cancel.MouseButton1Click:connect(function() Main.checkdonate.Visible=false end)
--Main.donate.help.close.MouseButton1Click:connect(function() Main.donate.help.Visible=false end)
Main.donate.close.MouseButton1Click:connect(function() Main.donate.Visible=false end)
--Main.donate.halp.MouseButton1Click:connect(function() --[[HEH]] end)
