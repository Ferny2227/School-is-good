# Jeep Obby (fixed for 2016 Roblox engines)

`JeepObby_fixed.rbxl` is the game. Open it in Studio and press Play, or upload it to the revival.

## What changed
- **Cars:** the 8 jeeps that piled up on top of each other are gone. Each player now gets their own car,
  spawned on pads spread across every checkpoint (one car per player; the old one is removed).
  The broken jeep scripts (seat crash, late welding, self-destruct) are replaced.
- **7 cars unlocked by wins:** Jeep (0), Racer (1), Rally (2), Monster (3), Turbo (5), Rocket (7), Golden Jeep (10).
  Each one is faster or stronger than the last, and the top ones have smoke, fire, neon or gold.
- **4 new levels** in the sky after the original course. Each one is harder than the last:
  narrower roads, faster sweepers, spinners, crushers, vanishing tiles, wind, ice and jumps.
  1. Classic Course (the original map), stages 1-2
  2. Sunny Skyway, stages 3-4
  3. Lava Run, stages 5-6
  4. Frozen Peaks, stages 7-8
  5. Neon Nightmare, stages 9-10. The finish is a **win**: +1 win, then back to the start.
- **Checkpoints:** a Stage leaderboard. You respawn at your last checkpoint with a fresh car,
  and kill parts also kill you when your car hits them.
- **UI:** a HUD (level, stage bar, wins, run timer), a GARAGE with every car's stats and lock state,
  NEW CAR, FLIP CAR, LEVELS (go back to any level you've reached), checkpoint pop-ups and a win screen.
  Keys: G garage, L levels, R new car, F flip.
- **Map fixes:** the lag-causing water generator is turned off, the teams are removed (stages replace them),
  falling off the map kills you quickly, and an on-screen error box shows any script errors.
- **Saving:** wins, your best stage and your chosen car are saved by DataStore when the server has one,
  and the game still works without it.

## Rebuilding
    python3 tools/patch.py <original.rbxl> JeepObby_fixed.rbxl
    python3 tests/run.py JeepObby_fixed.rbxl --api v227   # plays it in the fake 2016 engine
