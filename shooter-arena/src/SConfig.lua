-- SConfig (ModuleScript)
-- Location: ServerScriptService > SConfig
-- Every number of Shooter Arena lives here: guns, game modes, maps, weather, XP, killstreaks, medals.
-- Plain 2016-style Lua.

local C = {}

-- The ONLY admin (also locked in ShooterMain).
C.Admins = { "asdasda" }

------------------------------------------------------------------
-- GUNS
--   slot: "primary" / "secondary" / "melee"
--   damage per bullet, headMult (headshot x), rpm (shots per minute), auto (hold to shoot),
--   burst (shots per click), mag, reserve (spare ammo), reload (seconds), spread (degrees when
--   shooting from the hip), ads (spread when aiming), range (studs), pellets (shotguns),
--   zoom (field of view when aiming: smaller = more zoom, scope = black sniper scope),
--   level (needed to unlock), walk (walk speed while holding it), recoil (camera kick),
--   splash (rocket explosion radius), look = model style, c1/c2 = colours
------------------------------------------------------------------
C.Guns = {
	-- SECONDARIES
	{ name = "M1911", slot = "secondary", damage = 26, headMult = 2, rpm = 420, auto = false, mag = 8, reserve = 48, reload = 1.4,
		spread = 2.2, ads = 0.8, range = 350, zoom = 60, level = 1, walk = 18, recoil = 1.2, look = "pistol", c1 = "Dark stone grey", c2 = "Really black" },
	{ name = "Glock 18", slot = "secondary", damage = 17, headMult = 1.8, rpm = 900, auto = true, mag = 18, reserve = 90, reload = 1.5,
		spread = 3.5, ads = 1.6, range = 250, zoom = 62, level = 4, walk = 18, recoil = 0.7, look = "pistol", c1 = "Really black", c2 = "Dark stone grey" },
	{ name = "Desert Eagle", slot = "secondary", damage = 52, headMult = 2, rpm = 180, auto = false, mag = 7, reserve = 35, reload = 1.8,
		spread = 2.5, ads = 0.6, range = 450, zoom = 55, level = 8, walk = 17, recoil = 3.5, look = "deagle", c1 = "Light stone grey", c2 = "Gold" },
	{ name = "Revolver", slot = "secondary", damage = 62, headMult = 2.2, rpm = 140, auto = false, mag = 6, reserve = 36, reload = 2.4,
		spread = 2, ads = 0.4, range = 500, zoom = 55, level = 12, walk = 17, recoil = 4, look = "revolver", c1 = "Medium stone grey", c2 = "Brown" },
	{ name = "RPG-7", slot = "secondary", damage = 130, headMult = 1, rpm = 40, auto = false, mag = 1, reserve = 4, reload = 3,
		spread = 1.5, ads = 0.5, range = 800, zoom = 50, level = 22, walk = 15, recoil = 6, splash = 16, rocket = true, look = "rpg", c1 = "Earth green", c2 = "Brown" },

	-- PRIMARIES: SMGs
	{ name = "MP5", slot = "primary", damage = 22, headMult = 1.6, rpm = 800, auto = true, mag = 30, reserve = 150, reload = 2,
		spread = 3, ads = 1.2, range = 280, zoom = 58, level = 1, walk = 18, recoil = 0.8, look = "smg", c1 = "Really black", c2 = "Dark stone grey" },
	{ name = "UZI", slot = "primary", damage = 18, headMult = 1.5, rpm = 1000, auto = true, mag = 32, reserve = 160, reload = 1.8,
		spread = 4, ads = 1.8, range = 220, zoom = 60, level = 3, walk = 19, recoil = 0.7, look = "uzi", c1 = "Dark stone grey", c2 = "Really black" },
	{ name = "P90", slot = "primary", damage = 20, headMult = 1.5, rpm = 900, auto = true, mag = 50, reserve = 200, reload = 2.4,
		spread = 3.2, ads = 1.3, range = 260, zoom = 58, level = 10, walk = 18, recoil = 0.6, look = "p90", c1 = "Earth green", c2 = "Really black" },
	-- PRIMARIES: assault rifles
	{ name = "M4A1", slot = "primary", damage = 28, headMult = 1.8, rpm = 750, auto = true, mag = 30, reserve = 150, reload = 2.2,
		spread = 2.4, ads = 0.6, range = 550, zoom = 50, level = 1, walk = 16, recoil = 1, look = "rifle", c1 = "Really black", c2 = "Dark stone grey" },
	{ name = "AK-47", slot = "primary", damage = 34, headMult = 1.8, rpm = 600, auto = true, mag = 30, reserve = 150, reload = 2.4,
		spread = 2.8, ads = 0.8, range = 550, zoom = 50, level = 2, walk = 16, recoil = 1.5, look = "ak", c1 = "Really black", c2 = "Reddish brown" },
	{ name = "FAMAS", slot = "primary", damage = 30, headMult = 1.8, rpm = 950, auto = false, burst = 3, mag = 30, reserve = 150, reload = 2.3,
		spread = 2.2, ads = 0.5, range = 550, zoom = 48, level = 6, walk = 16, recoil = 0.9, look = "famas", c1 = "Dark stone grey", c2 = "Really black" },
	{ name = "SCAR-H", slot = "primary", damage = 40, headMult = 1.8, rpm = 550, auto = true, mag = 20, reserve = 120, reload = 2.5,
		spread = 2.5, ads = 0.6, range = 600, zoom = 48, level = 14, walk = 15, recoil = 1.8, look = "rifle", c1 = "Brick yellow", c2 = "Really black" },
	-- PRIMARIES: shotguns
	{ name = "Pump Shotgun", slot = "primary", damage = 14, pellets = 8, headMult = 1.3, rpm = 70, auto = false, mag = 6, reserve = 30, reload = 2.6,
		spread = 7, ads = 5.5, range = 120, zoom = 60, level = 5, walk = 16, recoil = 4, look = "shotgun", c1 = "Reddish brown", c2 = "Really black" },
	{ name = "AA-12", slot = "primary", damage = 11, pellets = 7, headMult = 1.3, rpm = 300, auto = true, mag = 8, reserve = 40, reload = 2.8,
		spread = 8, ads = 6.5, range = 100, zoom = 60, level = 18, walk = 15, recoil = 2.5, look = "autoshotgun", c1 = "Really black", c2 = "Earth green" },
	-- PRIMARIES: marksman / snipers
	{ name = "M14 DMR", slot = "primary", damage = 55, headMult = 2, rpm = 280, auto = false, mag = 10, reserve = 60, reload = 2.4,
		spread = 3, ads = 0.2, range = 900, zoom = 35, level = 9, walk = 15, recoil = 2.5, look = "dmr", c1 = "Reddish brown", c2 = "Really black" },
	{ name = "Intervention", slot = "primary", damage = 100, headMult = 2.5, rpm = 45, auto = false, mag = 5, reserve = 30, reload = 3,
		spread = 8, ads = 0, range = 2000, zoom = 15, scope = true, level = 7, walk = 14, recoil = 5, look = "sniper", c1 = "Really black", c2 = "Earth green" },
	{ name = "Barrett .50", slot = "primary", damage = 150, headMult = 2, rpm = 80, auto = false, mag = 8, reserve = 32, reload = 3.5,
		spread = 9, ads = 0, range = 2500, zoom = 12, scope = true, level = 20, walk = 13, recoil = 7, look = "barrett", c1 = "Dark stone grey", c2 = "Really black" },
	-- PRIMARIES: heavy
	{ name = "M249 LMG", slot = "primary", damage = 30, headMult = 1.6, rpm = 750, auto = true, mag = 100, reserve = 200, reload = 4.5,
		spread = 3.5, ads = 1.4, range = 500, zoom = 52, level = 16, walk = 13, recoil = 1.2, look = "lmg", c1 = "Really black", c2 = "Earth green" },
	{ name = "Minigun", slot = "primary", damage = 17, headMult = 1.4, rpm = 1500, auto = true, mag = 200, reserve = 400, reload = 6,
		spread = 4.5, ads = 3.5, range = 350, zoom = 62, level = 25, walk = 11, recoil = 0.5, look = "minigun", c1 = "Dark stone grey", c2 = "Really black" },

	-- MELEE (everyone always has a knife)
	{ name = "Knife", slot = "melee", damage = 55, headMult = 1, rpm = 100, auto = false, mag = 0, reserve = 0, reload = 0,
		spread = 0, ads = 0, range = 7, zoom = 70, level = 1, walk = 20, recoil = 0, melee = true, look = "knife", c1 = "Light stone grey", c2 = "Really black" },
}

C.DefaultPrimary = "M4A1"
C.DefaultSecondary = "M1911"

-- frag grenades: everyone spawns with this many (G key or the grenade tool)
C.Grenades = 2
C.GrenadeDamage = 110
C.GrenadeRadius = 16
C.GrenadeFuse = 2.5

------------------------------------------------------------------
-- GAME MODES
------------------------------------------------------------------
C.Modes = {
	ffa = { id = "ffa", name = "FREE FOR ALL", short = "FFA", teams = false, respawn = true, scoreLimit = 30, time = 480,
		info = "Everyone for themselves. First to 30 kills wins." },
	tdm = { id = "tdm", name = "TEAM DEATHMATCH", short = "TDM", teams = true, respawn = true, scoreLimit = 75, time = 600,
		info = "Red vs Blue. First team to 75 kills wins." },
	elim = { id = "elim", name = "TEAM ELIMINATION", short = "ELIM", teams = true, respawn = false, roundsToWin = 4, roundTime = 150,
		info = "One life per round. Wipe out the other team. First to 4 rounds wins." },
	-- v6
	koth = { id = "koth", name = "KING OF THE HILL", short = "KOTH", teams = true, respawn = true, scoreLimit = 150, time = 600,
		info = "Stand in the HILL to score for your team. It moves every minute. First to 150 wins." },
	gungame = { id = "gungame", name = "GUN GAME", short = "GUN", teams = false, respawn = true, scoreLimit = 0, time = 600, noStreaks = true,
		info = "Every kill gives you the next gun. Get a kill with the last one (knife) to win. Knifed = you go back a gun." },
}
C.ModeOrder = { "ffa", "tdm", "elim", "koth", "gungame" }

-- GUN GAME: the guns in order (the last one wins it)
C.GunGameLadder = { "MP5", "UZI", "M4A1", "AK-47", "FAMAS", "SCAR-H", "Pump Shotgun", "AA-12", "M14 DMR",
	"Intervention", "M249 LMG", "Desert Eagle", "Revolver", "RPG-7", "Knife" }

-- KING OF THE HILL
C.HillMove = 60    -- seconds before the hill moves
C.HillXP = 25      -- XP every 5 seconds you help hold the hill

-- MAPS (v6: 5 maps). bots = how many fighters bots fill up to on that map (big maps get more).
-- weather = what RANDOM weather can be on that map
C.Maps = {
	{ id = "nuketown", name = "NUKETOWN", bots = 8, weather = { "clear", "clear", "rain", "storm", "fog", "night" } },
	{ id = "skyline", name = "SKYLINE MAYHEM", bots = 8, weather = { "clear", "night", "storm", "fog" } },
	{ id = "desert", name = "DESERT OUTPOST", bots = 10, weather = { "clear", "clear", "sandstorm", "night" } },
	{ id = "harbor", name = "FROZEN HARBOR", bots = 10, weather = { "snow", "snow", "fog", "clear", "storm", "night" } },
	{ id = "forest", name = "TIMBER FOREST", bots = 10, weather = { "rain", "clear", "fog", "storm", "night" } },
}

------------------------------------------------------------------
-- WEATHER (v6). Players vote for it in the lobby (RANDOM picks one that fits the map).
--   time = time of day (nil = the map's own), fogStart / fogEnd / fog = fog colour,
--   bright = Lighting brightness, amb / out = Ambient / OutdoorAmbient,
--   sight = bots see this much less far, fx = what falls from the sky on your screen
--   (rain / storm / snow / sand), lights = everyone gets a flashlight
------------------------------------------------------------------
C.Weather = {
	clear = { name = "CLEAR", fogEnd = 100000, fog = { 192, 192, 192 }, bright = 1, amb = { 128, 128, 133 }, out = { 140, 140, 153 }, sight = 1 },
	rain = { name = "RAIN", time = 15, fogStart = 0, fogEnd = 550, fog = { 130, 136, 148 }, bright = 0.5, amb = { 90, 92, 102 },
		out = { 100, 102, 115 }, sight = 0.85, fx = "rain" },
	storm = { name = "THUNDERSTORM", time = 18.6, fogStart = 0, fogEnd = 380, fog = { 70, 75, 90 }, bright = 0.3, amb = { 70, 72, 85 },
		out = { 80, 82, 98 }, sight = 0.7, fx = "storm" },
	snow = { name = "SNOW", time = 13, fogStart = 0, fogEnd = 450, fog = { 225, 230, 240 }, bright = 0.9, amb = { 150, 155, 170 },
		out = { 170, 175, 190 }, sight = 0.8, fx = "snow" },
	fog = { name = "FOG", time = 9, fogStart = 5, fogEnd = 170, fog = { 200, 202, 208 }, bright = 0.7, amb = { 130, 130, 138 },
		out = { 140, 140, 148 }, sight = 0.55 },
	night = { name = "NIGHT", time = 0.5, fogStart = 0, fogEnd = 650, fog = { 10, 12, 22 }, bright = 0.15, amb = { 45, 48, 65 },
		out = { 40, 44, 62 }, sight = 0.6, lights = true },
	sandstorm = { name = "SANDSTORM", time = 15, fogStart = 0, fogEnd = 200, fog = { 205, 165, 105 }, bright = 0.8, amb = { 150, 125, 90 },
		out = { 160, 130, 95 }, sight = 0.5, fx = "sand" },
}
C.WeatherOrder = { "random", "clear", "rain", "storm", "snow", "fog", "night", "sandstorm" }

C.Intermission = 20      -- seconds between matches (voting time)
C.RespawnTime = 3        -- seconds before you come back (FFA / TDM)
C.SpawnShield = 3        -- seconds of spawn protection
C.MinPlayers = 1         -- a match starts with this many players (bots are not a thing here)
C.MapLoadTime = 2        -- seconds to wait after a map loads before everyone spawns in it

-- BOTS: fill the match with bots up to this many fighters (players + bots). Players replace bots.
-- Each map can ask for more (C.Maps ... bots = 10). Set this to 0 to turn bots off everywhere.
-- In team modes every team gets at least half of this, and bots always even out the teams
-- (so if everybody picks RED, the bots play BLUE).
C.BotFill = 8
C.MaxBots = 12

-- BOT DIFFICULTY: players vote EASY / MEDIUM / HARD in the lobby (admin: ":bots hard").
--   aim = how far off they aim (bigger = worse), damage = part of the gun's damage they do,
--   reaction = seconds before they shoot someone they just saw, sight = how far they see,
--   fireRate = slower shooting when bigger, headshot = chance to aim at the head, health, speed
C.BotLevels = {
	easy = { name = "EASY", aim = 3.2, damage = 0.45, reaction = 1.1, sight = 140, fireRate = 1.7, headshot = 0.08, health = 80, speed = 13 },
	medium = { name = "MEDIUM", aim = 1.6, damage = 0.7, reaction = 0.6, sight = 220, fireRate = 1.2, headshot = 0.25, health = 100, speed = 16 },
	hard = { name = "HARD", aim = 0.6, damage = 0.95, reaction = 0.25, sight = 340, fireRate = 1, headshot = 0.45, health = 125, speed = 18 },
}
C.BotLevelOrder = { "easy", "medium", "hard" }
C.DefaultBotLevel = "medium" -- used when nobody votes

------------------------------------------------------------------
-- XP, LEVELS, KILLSTREAKS
------------------------------------------------------------------
C.XPKill = 100
C.XPHeadshot = 50
C.XPWin = 500
C.XPLose = 150
C.XPPerLevel = 1000
C.MaxLevel = 50

-- kills in a row (without dying) -> reward
C.Killstreaks = {
	{ kills = 3, id = "uav", name = "UAV", info = "enemies show on your screen for 25 s" },
	{ kills = 5, id = "armor", name = "ARMOR", info = "+60 max health and a bit faster" },
	{ kills = 7, id = "airstrike", name = "AIRSTRIKE", info = "bombs rain on the enemy" },
	{ kills = 12, id = "nuke", name = "NUKE", info = "every enemy dies" },
}

-- MEDALS (v6): extra XP for special kills
C.Medals = {
	firstblood = { name = "FIRST BLOOD", xp = 50 },
	double = { name = "DOUBLE KILL", xp = 50 },
	triple = { name = "TRIPLE KILL", xp = 100 },
	multi = { name = "MULTI KILL", xp = 150 },
	longshot = { name = "LONGSHOT", xp = 50 },
	revenge = { name = "REVENGE", xp = 50 },
	shutdown = { name = "SHUTDOWN", xp = 100 },
	stabbed = { name = "STABBED", xp = 50 },
	assist = { name = "ASSIST", xp = 50 },
}
C.MultiKillTime = 4      -- seconds between kills for a double / triple kill
C.LongshotDistance = 120 -- studs
C.AssistDamage = 20      -- damage you need to do for an assist

-- AMMO DROPS (v6): everyone who dies drops a green box. Walk over it: ammo, +1 grenade, health.
C.DropTime = 20          -- seconds before it disappears
C.DropHeal = 25

-- sounds (built-in client sounds, quiet on purpose)
C.Sounds = {
	shot = "rbxasset://sounds/collide.wav",
	reload = "rbxasset://sounds/clickfast.wav",
	empty = "rbxasset://sounds/clickfast.wav",
	knife = "rbxasset://sounds/swordslash.wav",
	boom = "rbxasset://sounds/collide.wav",
}
C.ShotVolume = 0.15

return C
