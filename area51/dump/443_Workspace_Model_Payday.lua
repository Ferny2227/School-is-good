--Put both GUIs in the startergui
--Set your group ID below
--Keep this in workspace. Set time for the interval in seconds you want people to be paid out, and below change the values of what they get if they are in your clan or not.

function onPlayerEntered(newPlayer)
	wait(0.5)
	local stats = Instance.new("IntValue")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Credits"
	cash.Value = 0
	cash.Parent = stats
	stats.Parent = newPlayer
end

game.Players.PlayerAdded:connect(onPlayerEntered)

time = 180

while true do
	wait(1)
	time = time - 1
	if (time == 0) then
		time = 180
		players = game.Players:GetChildren()
		for i=1, #players do
			if (players[i]:findFirstChild("leaderstats")) then
				if (players[i]:IsInGroup(199219)==true) then
					players[i].leaderstats.Credits.Value = players[i].leaderstats.Credits.Value + 175
				else
					players[i].leaderstats.Credits.Value = players[i].leaderstats.Credits.Value + 75
				end
			end
		end
	end
	playersa = game.Players:GetChildren()
	for i=1, #playersa do
		playersa[i].PlayerGui.PaydayGui.TextLabel.Text = "Time until next payday: " .. tostring(time)
	end
end
