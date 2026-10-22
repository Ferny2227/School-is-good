function Enter(newPlayer)
if newPlayer:IsInGroup(script.GroupId.Value) then
	game.Lighting.SR87Gold:clone().Parent = newPlayer.Backpack
	end 
end


game.Players.ChildAdded:connect(Enter)

