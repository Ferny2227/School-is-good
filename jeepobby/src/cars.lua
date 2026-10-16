-- Car list (shared by JeepObbyServer and JeepObbyUI; patch.py pastes it into both).
-- wins = how many wins unlock it. speed/torque/turn go straight onto the VehicleSeat.
local CARS = {
	{ name = "Jeep",        wins = 0,  speed = 100, torque = 8,  turn = 1.2, color = "Bright green",  desc = "Old faithful." },
	{ name = "Racer",       wins = 1,  speed = 125, torque = 9,  turn = 1.5, color = "Bright blue",   desc = "Quicker and sharper." },
	{ name = "Rally",       wins = 2,  speed = 140, torque = 10, turn = 1.7, color = "Bright orange", desc = "Grips the corners." },
	{ name = "Monster",     wins = 3,  speed = 135, torque = 15, turn = 1.5, color = "Really black",  desc = "Huge torque for hills.", extra = "smoke" },
	{ name = "Turbo",       wins = 5,  speed = 170, torque = 12, turn = 1.9, color = "Really red",    desc = "Flames out the back.", extra = "fire" },
	{ name = "Rocket",      wins = 7,  speed = 195, torque = 13, turn = 2.0, color = "Cyan",          desc = "Glowing and fast.", extra = "neon" },
	{ name = "Golden Jeep", wins = 10, speed = 215, torque = 15, turn = 2.2, color = "Bright yellow", desc = "The best there is.", extra = "gold" },
}
local LEVELS = {
	{ name = "Classic Course", stage = 1 },
	{ name = "Sunny Skyway",   stage = 3 },
	{ name = "Lava Run",       stage = 5 },
	{ name = "Frozen Peaks",   stage = 7 },
	{ name = "Neon Nightmare", stage = 9 },
}
local LAST_STAGE = 10
