local soundIds = {25954372, 25954392, 25954407}
local sounds = {}

for i=1,#soundIds do
	local s = Instance.new("Sound")
	s.SoundId = "http://www.roblox.com/asset/?id=" .. soundIds[i]
	s.Volume = 1
	s.Parent = script.Parent.Head
	sounds[#sounds + 1] = s
end

while true do
	wait(math.random(5,10))
	local i = math.random(1, #sounds)
	sounds[i].Pitch = .8 + (math.random() * .2)
	sounds[i]:Play()
end
