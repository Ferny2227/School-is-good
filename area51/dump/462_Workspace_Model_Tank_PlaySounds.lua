local soundIds = {25954372, 25954392, 25954407}
local sounds = {}
pitch = .3

for i=1,#soundIds do
	local s = Instance.new("Sound")
	s.SoundId = "http://www.roblox.com/asset/?id=" .. soundIds[i]
	s.Volume = 1
	s.Parent = script.Parent.Head
	sounds[#sounds + 1] = s
end

function onDied()
	local i = 1
	sounds[i].Pitch = pitch + (math.random() * .2)
	sounds[i]:Play()
end

script.Parent.Zombie.Died:connect(onDied)

while true do
	wait(math.random(5,10))
	if script.Parent.Zombie.Health == 0 then break end
	local i = math.random(1, #sounds)
	sounds[i].Pitch = pitch + (math.random() * .2)
	sounds[i]:Play()
end
