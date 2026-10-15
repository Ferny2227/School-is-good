# Fixes the MechaCubes hub place getting stuck on "Loading assets..".
#   python3 patch.py <original.rbxl> <fixed.rbxl>
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'casino', 'tools'))
from rbxlw import Editable

src_path, out_path = sys.argv[1], sys.argv[2]
E = Editable(open(src_path, 'rb').read())
LOG = []
paths = {}
for r in E.loc:
    paths.setdefault(E.path(r), []).append(r)

def find(path):
    refs = paths.get(path, [])
    assert len(refs) == 1, (path, len(refs))
    return refs[0]

def edit(path, old, new, count=1):
    r = find(path)
    src = E.get_string(r, 'Source').decode('utf8')
    assert src.count(old) == count, (path, src.count(old), old[:70])
    E.set_string(r, 'Source', src.replace(old, new))
    LOG.append('edited ' + path)

S = 'ServerScriptService.server'

# 1. New ModuleScript safeData: DataStores that can't freeze the game (offline mode)
safe = E.add_instance(find(S + '.user.permission'), find(S), 'safeData')
E.set_string(safe, 'Source', open(os.path.join(HERE, '..', 'src', 'safeData.lua'), 'rb').read())
LOG.append('added ' + S + '.safeData')

edit(S + '.user', 'local dataStoreService = game:GetService("DataStoreService")',
     'local dataStoreService = require(script.Parent.safeData) -- [fix] never freezes; offline mode when saving is unavailable')
edit(S + '.hub', 'local dataStoreService = game:GetService("DataStoreService")',
     'local dataStoreService = require(script.Parent.safeData) -- [fix]')
edit(S + '.hub.gameData', 'local dataStoreService = game:GetService("DataStoreService")',
     'local dataStoreService = require(script.Parent.Parent.safeData) -- [fix]')

# 2. server: players already in the game were loaded one at a time BEFORE PlayerAdded was
#    connected, and each one waits for its client, so other players were never loaded
edit(S, '''for _, player in pairs(game.Players:GetPlayers()) do
	user.playerAdded(player)
end

playerService.PlayerAdded:connect(user.playerAdded)''', '''playerService.PlayerAdded:connect(user.playerAdded)

-- [fix] connect first, then load players who were already here, all at the same time
for _, player in pairs(game.Players:GetPlayers()) do
	spawn(function()
		user.playerAdded(player)
	end)
end''')

# 3. user.playerAdded
edit(S + '.user', '''	repeat
		wait(.1)
	until (initializeQueue[player])''', '''	-- [fix] don't wait forever for the client's "initialize" message (max 20 s)
	local waitStart = tick()
	repeat
		wait(.1)
	until (initializeQueue[player] or tick() - waitStart > 20 or not player.Parent)

	if (not player.Parent) then
		return
	end''')
# gamepass checks one after another could hang (revival servers / no web access): now parallel, max 5 s
edit(S + '.user', '''	for _, gamepass in pairs(ref.gamepasses) do
		pcall(function()
			user.gamepasses[gamepass.name] = game:GetService("MarketplaceService"):PlayerOwnsAsset(player, gamepass.assetId)
		end)

		if (not player or not player.Parent) then
			return
		end
	end''', '''	-- [fix] all gamepass checks at the same time, and never wait longer than 5 seconds
	for _, gamepass in pairs(ref.gamepasses) do
		spawn(function()
			pcall(function()
				local owned = game:GetService("MarketplaceService"):PlayerOwnsAsset(player, gamepass.assetId)
				user.gamepasses[gamepass.name] = owned
				if (owned and users[user.userKey] == user and user.settings) then -- finished late: log it now
					logGamepassOwnership(user, gamepass.name)
				end
			end)
		end)
	end

	local gamepassStart = tick()
	repeat
		wait(.1)
		local count = 0
		for _ in pairs(user.gamepasses) do
			count = count + 1
		end
	until (count >= #ref.gamepasses or tick() - gamepassStart > 5)

	if (not player or not player.Parent) then
		return
	end''')

# 4. Loading screen never closed on older engines: the server's "done loading" message
#    (userLoadscreen with no text) arrived before the interface module was listening, and old
#    engines drop remote messages nobody is listening to. The loading screen now listens itself
#    from the start, and also closes once your stats exist (leaderstats) as a backup.
edit('ReplicatedFirst.load', '''--if (not game:GetService("RunService"):IsStudio()) then
load()''', '''-- [fix] listen for the server's loading messages from the very start
spawn(function()
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("remotes"):WaitForChild("userLoadscreen")
	remote.OnClientEvent:connect(function(text)
		if (text) then
			activate(text)
		else
			deactivate()
		end
	end)
end)

-- [fix] backup: your stats only appear after the server has loaded you, so close the first
-- loading screen then (it waits 3 s in case the server still has something to show)
spawn(function()
	local player = game.Players.LocalPlayer
	while (not player) do
		wait(.5)
		player = game.Players.LocalPlayer
	end
	player:WaitForChild("leaderstats")
	wait(3)
	if (active and (text == "Loading game" or text == "Loading assets" or text == "Loading user data")) then
		deactivate()
	end
end)

--if (not game:GetService("RunService"):IsStudio()) then
load()''')

data = E.save()
open(out_path, 'wb').write(data)
for l in LOG:
    print(l)
print('wrote', out_path, len(data), 'bytes')
