# Wheelie Life (2016 edition)

An original wheelie game with e-motos and mini bikes, for 2016 Roblox. Open/upload `WheelieLife.rbxl`.

- **Ride**: press **RIDE** and your bike appears under you. **W / S** (or Up / Down) = gas and brake,
  **A / D** (or Left / Right) = steer, **hold SPACE** (or Shift) = pull the front wheel up. Touch screens get
  GAS / BRAKE / WHEELIE / < / > buttons.
- **Wheelies**: hold to lift the front, then keep the white line on the **BALANCE** meter in the **green zone**
  (the bike's balance point). Below it the front falls back down; past it the bike slowly tips over backwards -
  tap the brake to save it. Go too far (the red zone) and you **loop out** (crash, no pay). The timer at the top
  counts your wheelie; "PERFECT BALANCE!" when you're in the green.
- **Cash**: when the front wheel comes back down you get paid: seconds x speed. Your best wheelie is on the
  leaderboard. Cash, best wheelie and your bikes are saved (DataStore); the board in the plaza shows the best
  wheelies of all time.
- **The bikes look like real ones**: knobbly tyres, rims with spokes (e-motos have 3-spoke mag wheels), brake
  discs, twin fork legs, a rear shock with a coloured spring, swingarm, chain and sprocket, foot pegs, handlebars
  with grips, headlight, tail light, fenders and number plates. Mini bikes have a tube frame, fuel tank, a finned
  engine, an air filter and an exhaust with a muffler; e-motos have a big battery with glowing light strips, side
  covers with your race number, a motor and a long thin seat. The rider sits on the seat holding the bars.
- **Bikes** (GARAGE button, or see them all on show in the garage in the plaza):
  - Mini bikes: **Mini Bike** (free), **Pit Bike** ($400), **Gold Mini** ($9000, very easy to balance).
  - E-motos (big battery with a glowing light strip, long fork, number plate): **Volt Bee** ($1200),
    **Stinger** ($2500), **Thunder X** ($5000). Faster bikes pay more; higher balance points are easier to hold.
- **Wheelie City**: the long, wide, dead-straight **Wheelie Boulevard** with distance markers every 50 studs and a
  start banner, streets and city blocks with buildings, parked cars, trees and street lamps, the spawn plaza (with
  the garage, a fountain and the leaderboard), a **bike park** (kickers, a funbox, quarter pipes, a big launch ramp),
  a **dirt track** (table-tops and whoops) and a park with a pond. Ramps tilt the bike and launch you.
- **HIGHWAY 66**: a long highway north of the city (1880 studs, tunnel to tunnel - the longest straight in the game),
  four lanes and a concrete barrier down the middle, big green signs and lamps. The three streets lead onto it.
  Cars, SUVs, trucks and school buses drive along it all the time (your own computer moves them using the game clock,
  so everyone sees the same traffic, with no lag) - ride into one and you're knocked off your bike.
- **How it works**: your own computer moves you and your bike (smooth, no lag) and tells the server about each
  wheelie; the server checks it makes sense (not longer than you've been riding, not faster than the bike) before
  paying. Admin panel only for asdasda (FilteringEnabled on).

Build: `python3 tools/build.py`. Test (mock Roblox): `python3 tools/test/runner.py`.
