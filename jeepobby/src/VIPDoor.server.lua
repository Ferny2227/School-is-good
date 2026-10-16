-- VIP door: opens for owners of the pass/badge; everyone else just bumps into it.
-- (The old script froze non-VIP players and killed them when the purchase didn't go through, and
-- purchases never go through on a revival server.)
local pcall = ypcall or pcall
local door = script.Parent
local ID = --#ID
local owns = {}
door.Touched:connect(function(hit)
	local player = hit.Parent and game.Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	if owns[player] == nil then
		local ok1, r1 = pcall(function() return game:GetService("BadgeService"):UserHasBadge(player.userId, ID) end)
		local ok2, r2 = pcall(function() return game:GetService("GamePassService"):PlayerHasPass(player, ID) end)
		owns[player] = (ok1 and r1 == true) or (ok2 and r2 == true) or false
	end
	if owns[player] and door.CanCollide then
		door.CanCollide = false
		door.Transparency = 0.5
		wait(1.5)
		door.CanCollide = true
		door.Transparency = 0
	end
end)
