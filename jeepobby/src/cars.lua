-- Car list (shared by JeepObbyServer and JeepObbyUI; patch.py pastes it into both).
-- wins = how many wins unlock it. speed/torque/turn go straight onto the VehicleSeat.
local CARS = {
	{ name = "Jeep",        wins = 0,  speed = 120, torque = 10, turn = 1.5, color = "Bright green",  desc = "Old faithful, now tuned." },
	{ name = "Racer",       wins = 1,  speed = 145, torque = 11, turn = 1.7, color = "Bright blue",   desc = "Quicker and sharper." },
	{ name = "Rally",       wins = 2,  speed = 160, torque = 12, turn = 1.9, color = "Bright orange", desc = "Grips the corners." },
	{ name = "Monster",     wins = 3,  speed = 150, torque = 18, turn = 1.7, color = "Really black",  desc = "Huge torque for hills.", extra = "smoke" },
	{ name = "Turbo",       wins = 5,  speed = 190, torque = 14, turn = 2.0, color = "Really red",    desc = "Flames out the back.", extra = "fire" },
	{ name = "Rocket",      wins = 7,  speed = 215, torque = 15, turn = 2.2, color = "Cyan",          desc = "Glowing and fast.", extra = "neon" },
	{ name = "Golden Jeep", wins = 10, speed = 240, torque = 17, turn = 2.4, color = "Bright yellow", desc = "The best there is.", extra = "gold" },
}
local LEVELS = {
	{ name = "Classic Course", stage = 1 },
	{ name = "Sunny Skyway",   stage = 3 },
	{ name = "Lava Run",       stage = 5 },
	{ name = "Frozen Peaks",   stage = 7 },
	{ name = "Neon Nightmare", stage = 9 },
}
local LAST_STAGE = 10
