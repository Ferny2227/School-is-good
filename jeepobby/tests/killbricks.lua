-- old map Kill Bricks: driver (sitting) is safe, walker dies; new levels' KillParts kill drivers
local p = JOINER
local out = {}
local car = workspace.JeepObby.Cars:GetChildren()[1]
local w = makeInstance("Weld") w.Name = "SeatWeld" w.Part0 = car.VehicleSeat w.Part1 = p.Character.Torso w.Parent = car.VehicleSeat
local hum = p.Character.Humanoid
local kb for _, c in ipairs(workspace:GetChildren()) do if c.Name == "Kill Brick" then kb = c break end end
hum.Sit = true
CTX = SERVER kb.Touched:_fire(car.Colour) kb.Touched:_fire(p.Character.Torso) runFor(1)
out[#out + 1] = "driver (sitting) touches old Kill Brick -> health " .. hum.Health
hum.Sit = false
kb.Touched:_fire(p.Character.Torso) runFor(1)
out[#out + 1] = "walker touches old Kill Brick -> health " .. hum.Health
SPAWN_CHARACTER(p) runFor(3)
car = workspace.JeepObby.Cars:GetChildren()[1]
w = makeInstance("Weld") w.Name = "SeatWeld" w.Part0 = car.VehicleSeat w.Part1 = p.Character.Torso w.Parent = car.VehicleSeat
local kp for _, d in ipairs(workspace.JeepObby.Levels.Level2:GetChildren()) do if d.Name == "KillPart" then kp = d break end end
kp.Touched:_fire(car.Colour) runFor(1)
out[#out + 1] = "car hits new-level KillPart -> health " .. p.Character.Humanoid.Health
return out
