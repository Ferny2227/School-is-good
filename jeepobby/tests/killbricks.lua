local p = JOINER
local car = workspace.JeepObby.Cars:GetChildren()[1]
local w = makeInstance("Weld") w.Name = "SeatWeld" w.Part0 = car.VehicleSeat w.Part1 = p.Character.Torso w.Parent = car.VehicleSeat
local kb for _, c in ipairs(workspace:GetChildren()) do if c.Name == "Kill Brick" then kb = c break end end
CTX = SERVER kb.Touched:_fire(car.Colour) runFor(1)
local h1 = p.Character.Humanoid.Health
local kp for _, d in ipairs(workspace.JeepObby.Levels.Level2:GetChildren()) do if d.Name == "KillPart" then kp = d break end end
kp.Touched:_fire(car.Colour) runFor(1)
return {"car on old Kill Brick -> health " .. h1 .. " | car on new KillPart -> health " .. p.Character.Humanoid.Health}
