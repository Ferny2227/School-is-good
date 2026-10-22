PointsService = game:GetService("PointsService")
Stat = "Credits" --Change to the stats name
Needed = 400 --Change to the amount needed to get the playerpoints.
game.Players.PlayerAdded:connect(function(p)
repeat wait() until p:FindFirstChild("leaderstats") ~= nil
print("Found \"leaderstats\" object!")
repeat wait() until p.leaderstats:findFirstChild(Stat) ~= nil
print("Found "..Stat.." object!")
p.leaderstats[Stat].Changed:connect(function(prop)
print("Value changed!")
if prop >= Needed then
game:GetService("PointsService"):AwardPoints(p.userId,1000)
end
end)
end)
