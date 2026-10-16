local out = {}
local function say(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out[#out + 1] = table.concat(t, " ") end
local p = JOINER
local function stat(n) return p.leaderstats[n].Value end
local function cars() local n = 0 for _, c in ipairs(workspace.JeepObby.Cars:GetChildren()) do n = n + 1 end return n end
local function myCar() return workspace.JeepObby.Cars:GetChildren()[1] end
local function touch(part, hit) local b = #ERRORS CTX = SERVER part.Touched:_fire(hit) runFor(3) if #ERRORS > b then say("  !! errors after touching", part.Name, ERRORS[#ERRORS].msg) end end
local function click(btn) CTX = CLIENT_CTX btn.MouseButton1Click:_fire() CTX = SERVER runFor(2) end
local function torsoPos() return p.Character.Torso.CFrame.p end
local ui = p.PlayerGui:FindFirstChild("JeepObbyUI")
say("UI built:", ui ~= nil, "| stage", stat("Stage"), "wins", stat("Wins"), "| cars", cars(), myCar() and myCar().Name)
local car = myCar()
if car then
	say("car seat MaxSpeed", car.VehicleSeat.MaxSpeed, "torque", car.VehicleSeat.Torque, "at", tostring(car.VehicleSeat.CFrame.p))
	local welds = 0 for _, c in ipairs(car.VehicleSeat:GetChildren()) do if c:IsA("Weld") then welds = welds + 1 end end
	say("welds on seat", welds)
end
say("hud:", ui and ui.HUD.Level.Text, "|", ui and ui.HUD.Stage.Text, "|", ui and ui.HUD.Wins.Text)
local S = workspace.JeepObby.Stages
-- walk into stage 2
touch(S.Stage2, p.Character.Torso)
say("after Stage2 touch: stage", stat("Stage"), "best", p.BestStage.Value)
-- drive into level end with the car: fake a seat weld from the car to the character
car = myCar()
local w = makeInstance("Weld") w.Name = "SeatWeld" w.Part0 = car.VehicleSeat w.Part1 = p.Character.Torso w.Parent = car.VehicleSeat
say("seat?", car:FindFirstChild("VehicleSeat"), rawget(car.VehicleSeat,"_children") ~= nil, rawget(car.VehicleSeat,"_destroyed"), car.Parent) touch(S.LevelEnd, car.Colour)
say("after LevelEnd (by car): stage", stat("Stage"), "cars", cars(), "torso", tostring(torsoPos()))
for st = 4, 10 do
	local pad = S:FindFirstChild("Stage" .. st)
	touch(pad, p.Character.Torso)
	if st % 2 == 0 and st < 10 then
		for _, e in ipairs(S:GetChildren()) do
			if e.Name == "LevelEnd" and e.NextStage.Value == st + 1 then touch(e, p.Character.Torso) end
		end
	end
end
say("after all stages: stage", stat("Stage"), "best", p.BestStage.Value)
touch(S.WinPad, p.Character.Torso)
say("after WinPad: stage", stat("Stage"), "wins", stat("Wins"), "selected car", p.SelectedCar.Value, "win popup", ui and ui.Parent and ui.Win.Visible)
car = myCar()
say("car now", car and car.Name, "speed", car and car.VehicleSeat.MaxSpeed, "cars", cars())
-- UI buttons
ui = p.PlayerGui:FindFirstChild("JeepObbyUI")
click(ui.Win.OK)
click(ui.Side.Garage)
say("garage visible", ui.Garage.Visible, "| car1 btn", ui.Garage.Car1.Pick.Text, "| car2", ui.Garage.Car2.Pick.Text, "| car3", ui.Garage.Car3.Pick.Text)
click(ui.Garage.Car1.Pick)
say("picked car1 -> selected", p.SelectedCar.Value, "car", myCar() and myCar().Name)
click(ui.Side.Garage) click(ui.Garage.Car3.Pick)
say("picked locked car3 -> selected", p.SelectedCar.Value, "toast", ui.Toast.Text)
click(ui.Side.Levels)
say("levels visible", ui.Levels.Visible, ui.Levels.Level3.Text)
click(ui.Levels.Level3)
say("level3 -> stage", stat("Stage"), "toast", ui.Toast.Text)
click(ui.Side.NewCar) say("new car -> cars", cars())
CTX = CLIENT_CTX ui.Side.Flip.MouseButton1Click:_fire() CTX = SERVER runFor(0.3) say("flip -> gyro", myCar() and myCar().VehicleSeat:FindFirstChild("BodyGyro") ~= nil)
-- dying: kill part and respawn at checkpoint
local kp
for _, d in ipairs(workspace.JeepObby.Levels.Level3:GetChildren()) do if d.Name == "KillPart" then kp = d break end end
touch(kp, p.Character.Torso)
say("kill part -> health", p.Character.Humanoid.Health)
SPAWN_CHARACTER(p) runFor(3)
say("respawned at stage", stat("Stage"), "torso", tostring(torsoPos()), "cars", cars())
-- moving parts move
local m
for _, d in ipairs(workspace.JeepObby.Levels.Level2:GetChildren()) do if d:FindFirstChild("Move") and d.Move.Value:sub(1,5) == "slide" then m = d break end end
local a = m.CFrame.p runFor(0.7) say("sweeper moved", tostring(a), "->", tostring(m.CFrame.p))
ui = p.PlayerGui:FindFirstChild("JeepObbyUI")
say("hud after respawn:", ui and ui.HUD.Level.Text, "|", ui and ui.HUD.Stage.Text, "|", ui and ui.HUD.Time.Text)
PlayersLeave = true
return out
