# Area 51 Zombie Infection (fixed)

`Area51-Zombies.rbxl` is the place to open/upload. It is built from `base/Area51.rbxl` by `python3 tools/build.py`.

## What changed
- **ServerScriptService.ZombieDirector** (`src/ZombieDirector.lua`) runs all the zombies:
  - every zombie kill pays **30 Credits** to the player who killed it;
  - new zombie types next to the old ones, not overpowered: **Bomber** (runs at you and explodes, max 25 damage,
    once every 2 s per player), **Shooter** (keeps its distance, slime ball 8 damage every 2.5 s), **Runner**
    (fast, 60 health, 5 damage), **Brute** (slow, bigger, 400 health, 10 damage);
  - when every zombie is dead the **ZOMBIE KING** spawns: 3x size, 1500 + 750 health per player, a health bar at the
    top of everyone's screen; the whole lobby fights it; when it dies everyone gets +150 Credits and every zombie
    comes back;
  - zombies only chase players within 250 studs and check their target still exists; zombies that fall off the
    map die; if the last few zombies are unreachable for 4 minutes the boss comes anyway.
- Zombies' own respawn / chase / reward / regen scripts are switched off (the director does that now), including
  the Robot scripts that errored on line 11 (`itlh`) and zombie models with no body (Crawler, Witch, Tank...).
- The two duplicate payday scripts that each created a second `leaderstats` are off (the director makes one), and
  the PlayerPoints script that called AwardPoints on every Credits change is off.
- Badge awarders give a badge once, only if the player doesn't have it yet.

## Test
`python3 tools/test/runner.py` runs the director in a mock Roblox (`../roblox/tools/test/mockrbx.lua`).
