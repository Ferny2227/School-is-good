-- CarTemplate.VehicleSeat.Sound.Control: engine sound pitch follows the throttle; stops when the car is gone.
local sound = script.Parent
local seat = sound.Parent
sound:Play()
local pitch = 0.7
while wait(0.05) do
	if not seat.Parent or not sound.Parent then break end
	if math.abs(seat.Throttle) == 1 then
		pitch = math.min(1.5, pitch + 0.05)
	else
		pitch = math.max(0.7, pitch - 0.1)
	end
	sound.Pitch = pitch
end
pcall(function() sound:Stop() end)
