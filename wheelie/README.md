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
- **The bikes are built like real ones** (real proportions: a rider is 5 studs tall, so a metre is about 2.9 studs),
  with round tubes, raked forks (thick dark upper legs, shiny lower legs), two fork clamps, handlebars with a bar
  pad, grips, levers and mirrors, spoked wheels with tread, rims, hubs, brake discs and red calipers, a swingarm,
  a rear shock with a coloured spring, chain and sprocket, foot pegs, a kickstand, fenders, a tail light and
  number plates with your race number.
  - **Mini Bike / Gold Mini**: a street mini (like a little 125) - fat 5-spoke mag wheels, headlight cowl, chunky
    frame, fat tank, low engine, underslung exhaust, stubby tail.
  - **Pit Bike**: a petrol dirt bike - bigger front wheel, cradle frame, radiator shrouds, tank, finned engine,
    radiator, exhaust header and silencer, side number plates.
  - **Volt Bee / Stinger / Thunder X**: electric dirt bikes - an alloy frame round a big battery, side covers with
    your number and a glowing accent strip, the motor by the swingarm pivot, a long thin seat, front plate with a
    round headlight.
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
