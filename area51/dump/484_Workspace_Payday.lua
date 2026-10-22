time = 180

while true do
	wait(1)
	time = time - 1
	if (time == 0) then
		time = 180
		players = game.Players:GetChildren()
		for i=1, #players do
			if (players[i]:findFirstChild("leaderstats")) then
				if (players[i]:IsInGroup(1003658)==true) then
					players[i].leaderstats.Credits.Value = players[i].leaderstats.Credits.Value + 1250
				else
					players[i].leaderstats.Credits.Value = players[i].leaderstats.Credits.Value + 250	
				end
			end
		end
	end
	playersa = game.Players:GetChildren()
	for i=1, #playersa do
		playersa[i].PlayerGui.PaydayGui.TextLabel.Text = "Time until next payday: " .. tostring(time)
	end
end
