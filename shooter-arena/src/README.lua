-- README (disabled script, just notes)
--[==[
# Shooter Arena: Setup Guide (v6)

Open the .rbxlx in Roblox Studio (File > Open from File) and press Play (or host it on your server).
Everything (lobby, maps, guns, UI) is built by the scripts when the server starts.
Plain 2016-style Lua (wait / spawn / :connect). Newer things are wrapped in pcall, so old servers still work.

## What is new in v6
- TEAM SELECTION: pick RED, BLUE or AUTO in the lobby (vote screen buttons, or stand on the coloured
  team pads). In a match press T (or the TEAM button) to switch; you respawn on the new team
  (Elimination: from the next round). Bots always even out the teams.
- THIRD PERSON THAT WORKS ON A CHROMEBOOK: our own over-the-shoulder camera. Just slide your finger on
  the touchpad (no clicking) to look around. Arrow keys turn too. Q aims (no right click needed),
  F shoots (or tap the touchpad), X swaps shoulder. Menus free the mouse so you can click buttons.
- 3 NEW BIG MAPS (2-3x the size of Nuketown): DESERT OUTPOST, FROZEN HARBOR, TIMBER FOREST.
- WEATHER: clear, rain, thunderstorm (lightning), snow, fog, night (everyone gets a flashlight),
  sandstorm. Vote for it; RANDOM picks one that fits the map. Bots see less far in bad weather.
- 2 NEW MODES: KING OF THE HILL and GUN GAME.
- MEDALS: first blood, double / triple / multi kill, longshot, revenge, shutdown, stabbed, assist.
- AMMO DROPS: everyone who dies drops a green box (ammo, +1 grenade, +25 HP).
- BETTER UI: rounded panels, a bigger vote screen, a scoreboard with score, kill notices, medals,
  buttons for every menu, everything shrinks to fit small screens.
- TOUCH SCREENS: FIRE / AIM / RELOAD / NADE / SWAP buttons, drag on the right side to look.
- FASTER: only the map being played is loaded (the others wait in ServerStorage). Weather effects
  use fewer drops on slow computers, and can be turned off in Settings.
- Fixed: some Skyline spawns were inside AC units / water tanks, a Nuketown spawn was inside a tree.

## Explorer layout
```
Workspace            (empty: the lobby and the maps are built at runtime)
ReplicatedStorage    SRemote (RemoteEvent), Game (folder of values, made at runtime)
ServerScriptService  SConfig, SGuns, SMaps (ModuleScripts), ShooterMain (Script), README (disabled)
StarterGui           ShooterClient (LocalScript: HUD, menus, camera, weather, shooting)
```

## How a game goes
1. LOBBY (20 s): vote for the MAP, MODE, WEATHER and BOT difficulty, pick your TEAM and LOADOUT.
2. The map loads (2 s), then the MATCH.
3. RESULTS (winner + MVP, XP for everyone), then back to the lobby.

## Modes
- FREE FOR ALL: everyone for themselves, first to 30 kills (8 min).
- TEAM DEATHMATCH: Red vs Blue, first team to 75 kills (10 min).
- TEAM ELIMINATION: one life per round, last team standing wins the round, first to 4 rounds.
- KING OF THE HILL (v6): stand in the glowing circle (follow the yellow beam). Your team scores 1 point
  every second while only your team is in it. It moves every minute. First to 150 wins.
- GUN GAME (v6): everyone starts with an MP5. Every kill gives you the next gun (15 guns). The last one is
  the knife: get a knife kill to win. If someone knifes you, you go back one gun. No killstreaks.

## Teams (v6)
Pick RED / BLUE / AUTO. AUTO puts you on the team with fewer players. Bots fill up the teams so they are
always even: if everybody picks RED, the bots are BLUE. In team modes each team gets at least half of the
bot count. (The pads in the lobby do the same as the buttons.)

## Bots
When there are not many players, bots fill the match (8 fighters on Nuketown / Skyline, 10 on the big maps,
see SConfig.Maps). Every player who joins takes a bot's place; when a player leaves, a bot comes back.
Bots are named [BOT] ..., show on the scoreboard, hunt enemies, keep a good distance for their gun,
strafe, reload, walk around things they get stuck on, go to the hill in King of the Hill, and see less far
in rain / fog / night / sandstorms. Vote EASY / MEDIUM / HARD BOTS (nobody votes = MEDIUM).
Tune each level in SConfig.BotLevels. Set SConfig.BotFill = 0 to turn bots off.

## Maps
- NUKETOWN: a yellow house and a green house facing each other over a cul-de-sac, school bus, cars.
- SKYLINE MAYHEM: skyscraper rooftops over a neon city, glass bridges, jump pads, teleporters, sniper nest.
- DESERT OUTPOST (v6): a walled compound in the middle (walk on the walls, climb the keep to its roof),
  temple ruins on a platform (north), a bazaar street with houses (south), RED army camp with a
  watchtower and a tank (west), BLUE oil field with tanks, pumpjacks and a hangar (east).
- FROZEN HARBOR (v6): a snowy dock in the sea. A maze of shipping containers (some open to run through),
  two warehouses (RED west, BLUE east), an office with a roof to snipe from, two big cranes, and a cargo
  ship you walk onto with the gangways (bridge tower with a roof). Fall in the water and you drown.
- TIMBER FOREST (v6): a pine forest with a river down the middle (walk down the banks or use the bridges),
  RED log cabin camp (west), BLUE lumber mill with a water tower (east), a ranger station and a lookout
  tower (north), a campground and a red barn (south).

## Weather (v6)
CLEAR, RAIN, THUNDERSTORM, SNOW, FOG, NIGHT, SANDSTORM (and RANDOM). The server sets the light and the fog
for everyone; the rain / snow / sand you see falling is drawn by your own computer (Settings > WEATHER
EFFECTS turns it off). At NIGHT everybody has a flashlight. Change them in SConfig.Weather.

## Controls
Click or F: shoot (hold for automatic guns) | Right click or Q: aim / scope | R reload | G grenade |
Shift sprint | V first / third person | X other shoulder | Arrow keys: turn (third person) |
Z or mouse wheel: sniper zoom (2x / 4x / 8x) | L loadout | P settings | T team | Tab scoreboard |
1-4 switch weapons. Every menu also has a button (bottom left).
Touch screens: FIRE, AIM, RELOAD, NADE, SWAP buttons; drag on the right side of the screen to look.

## Settings (P, saved for next time)
Field of view, camera (first / third person), shoulder (right / left), aim button (hold / toggle),
look speed, sniper zoom, crosshair colour, hit sound, minimap, weather effects.

## Guns (unlock by level)
Secondaries: M1911 (1), Glock 18 (4), Desert Eagle (8), Revolver (12), RPG-7 (22)
Primaries: MP5 (1), M4A1 (1), AK-47 (2), UZI (3), Pump Shotgun (5), FAMAS burst (6), Intervention sniper (7),
M14 DMR (9), P90 (10), SCAR-H (14), M249 LMG (16), AA-12 (18), Barrett .50 (20), Minigun (25)
Everyone: Knife (backstab = instant kill), 2 frag grenades. Your first gun is in your hands when you spawn.
Headshots do more damage. All numbers are in SConfig.Guns.

## Killstreaks (kills in a row without dying)
3 UAV (enemies marked on your screen) | 5 ARMOR (+60 HP, faster) | 7 AIRSTRIKE | 12 NUKE

## Medals (v6, extra XP)
FIRST BLOOD 50 | DOUBLE KILL 50 | TRIPLE KILL 100 | MULTI KILL 150 | LONGSHOT (120+ studs) 50 |
REVENGE 50 | SHUTDOWN (kill someone on a 5+ streak) 100 | STABBED 50 | ASSIST 50

## Other stuff
XP and levels (saved), kill feed, hitmarkers with damage numbers, kill notices, kill streak counter,
death screen (who killed you, with what, how far, their HP), spawn protection, health regen,
spawn picking away from enemies, team colours, scoreboard with score, match results with MVP,
minimap (with the hill), hit direction marker, ammo boxes.

## Admin (ONLY asdasda, locked in ShooterMain)
:map nuketown/skyline/desert/harbor/forest   :mode ffa/tdm/elim/koth/gungame   (for the next match)
:weather clear/rain/storm/snow/fog/night/sandstorm   (now and the next match)
:end (end the match now)   :skip (start now)   :xp name amount   :level name n   :give gun name
:nuke   :ammo   :bots easy/medium/hard   :botfill n
Admins can also pick any gun in the loadout menu.

## Saving
XP, kills, deaths, wins, your loadout and your settings save to a DataStore (ShooterArena_v1)
when the server has one.
]==]
