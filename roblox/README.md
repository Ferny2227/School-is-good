# Airport Tycoon

`AirportTycoon-Admin.rbxl` is the place file to open in Studio. It is built from the sources in `src/`.
The text at the bottom of the screen ("build 11") tells you which build is running.

## What's in it
- **Bigger land**: every airport is 600 x 900 studs (was 420 x 620). The ground is cloned, resized and swapped in
  (old Roblox shoves a part upwards if you resize it in the world), and trees on it are cleared.
- **311 things to buy** (was 104), in 13 phases:
  - 9. **Departures Concourse (2nd floor)**: real airport rooms (Sky Priority Lounge, Duty Free, Pharmacy, Currency
    Exchange, Medical Center, Prayer Room, Family Room, Showers, Sleep Pods, Business Center, Kids Play Zone,
    Electronics, Transfer Desk, Lost & Found, Luggage Wrap, SIM shop, Sports Bar, Coffee House, Bookstore, Fashion),
    28 islands (gate seating, water refill, recycling, info kiosk, phone booths, prize car...), moving walkways and
    live flight information screens.
  - 10. **Sky Deck (3rd floor)**: First Class / Business / Airline Club lounges, Champagne Bar, Food Hall, Sushi,
    Steakhouse, Pizza, Noodles, Desserts, Cinema, Arcade, Gym, Art Gallery, Library, Butterfly Garden, Observation
    Deck, Aviation Museum, Flight Simulators, Pilot Academy, 28 islands, roof and rooftop garden.
  - 11. **Hotel**: lobby, reception, restaurant, gift shop, gym; floor 2 and 3 rooms in 8 themes (ocean, forest,
    modern, retro, kids with bunk beds, space, japanese, royal with canopy bed; floor 3 is deluxe); floor 4 has 4 suites
    (living room + bedroom + jacuzzi); floor 5 is the penthouse (plus living room, hot tub, bar, cinema, piano and pool
    table to buy); floor 6 has a spa, sauna, ballroom and conference room; rooftop bar; pool area outside.
  - 12. **Expansion**: overflow parking, gas station, police, 2 remote stands with airliners, a second runway with
    3 cargo jets, maintenance hangar, catering, de-icing, water tower, weather station, solar farm, wind turbines.
  - 13. **Ground Operations**: vehicles that drive around on their own (shuttle buses, taxis, police car, ambulance,
    rental and hotel vans, mail truck, baggage tugs, fuel truck, crew bus, follow-me car, fire truck, catering truck,
    runway sweeper), a sky train with three stations, meet & greet drivers, ground power units, pushback tugs,
    ILS antennas, guard lights, a water salute, a perimeter fence.
- **Elevators that really move**: a car slides up and down the shaft and sliding doors open on each floor. Step on
  the green CALL pad (or click CALL), walk in, then click a floor button or stand on UP/DOWN. Passengers and hotel
  guests wait for the car and ride it too. Terminal: 2 elevators (ground, 2, 3, roof). Hotel: lobby to roof.
- **Real flights to Paradise Island**: every gate has a fleet of 4 airliners (remote stands and cargo stands 2). Two
  pilots sit in each see-through cockpit and fly it. At the gate, arriving passengers get off through the jet bridge
  (to baggage claim and out the front), the crew walks off, then new passengers board (they wait at the gate up to
  90 s), the crew walks back on, and the plane pushes back, taxis and takes off. Then it flies far out over the
  northern sea to **Paradise Island**, lands there, taxis to a stand, lets its passengers off (they walk through the
  terminal into the theme park), takes off again and flies home, where it lands as soon as its gate is free. A round
  trip takes about 6 minutes. The flight screens show every step (EN ROUTE, HOLDING, LANDING THERE, AT PARADISE,
  LEAVING PARADISE, COMING BACK...).
- **Paradise Island** (`s29_resort.lua`, world x -1320..900, z 1840..3000): a second airport with a landing runway,
  a separate take-off runway, a taxiway, 18 stands, a glass terminal and a control tower. Air traffic control is
  built in: each plane books a landing slot when it leaves home (9 s apart) and slows down or laps a holding stack
  (each plane at its own height) to meet it; take-offs are 12 s apart; on the ground everyone taxis the same way and
  stops behind the plane in front; a plane waits at its stand while others taxi past. If the island is full, a plane
  flies a sightseeing loop near home instead (`FLY.CRUISE`).
- **Paradise Park** (`s29_rides.lua`), next to the island's airport, with 10 rides that really move. Every ride has
  real seats (touch one to sit and ride along, jump to get off) and painted riders:
  1. **The Scream Machine**: roller coaster with a 70-stud chain lift, a huge drop (75 studs/s), a loop-the-loop
     (you go upside down), a banked turn and camel hills; the train stops in the station to load.
  2. Ferris Wheel (10 gondolas), 3. Free Fall drop tower (up 105 studs, then a free fall), 4. Carousel,
  5. Pirate Ship (swings up to 70 degrees), 6. Spinning Teacups, 7. Sky Swings (swing out as it speeds up),
  8. Go-Karts (pit stop every lap), 9. **Ghost Manor** haunted house dark ride (floating ghosts, a spider, a coffin,
  skeletons, red lights), 10. Log Flume with a splash drop.
  Plus snack stands, benches, palms, a fountain, lamps, an entrance arch and visitors who queue at the rides.
- The park is packed close together (about 650 x 390 studs): Carousel, Teacups, Sky Swings and Free Fall along one
  side of the main path, Pirate Ship, Ferris Wheel, Go-Karts and Ghost Manor on the other, the coaster and the log
  flume right behind. Rides stop longer to let you on (coaster 15 s, flume and ghost cars 10 s, karts 6 s).
- **Low graphics** (default, GRAPHICS button) only switches off lights, sparkles, shadows and outlines on your own
  screen; it never moves or removes anything the server owns (that froze the rides in build 10).
- **Getting there**: AIRPORTS panel > FLY TO PARADISE PARK, or the pink pad next to the spawn. The green FLY HOME pad
  at the park takes you back to your airport.
- **Roblox-style people** with swinging arms and legs; the visible body is welded to an invisible root part.
- New staff: Receptionist, Housekeeper, Bellhop.

## Admin (only the player named `asdasda`)
- ServerScriptService.AdminServer (`src/AdminServer.lua`): runs every command and only obeys `asdasda`.
- AdminServer.AdminClient (`src/AdminClient.lua`): the red ADMIN button and panel. The server copies it into asdasda's PlayerGui only.
- StarterGui.AdminAnnounce (`src/AdminAnnounce.lua`): shows announcements to everyone.
- Workspace.FilteringEnabled is on.
- Chat commands: `;kick name reason`, `;ban name reason`, `;unban name`, `;kill`, `;respawn`, `;heal`, `;god`, `;ungod`,
  `;freeze`, `;unfreeze`, `;speed name 50`, `;jump name 100`, `;bring`, `;tp`, `;cash name 1000`, `;announce text`, `;cmds`.

## Sources
- `src/server/s*.lua` are joined in file-name order into ServerScriptService.AirportServer:
  `s00` header and catalog, `s01` the new catalog (floors, hotel, expansion, operations), `s10` people and planes,
  `s20` original item builders, `s24` elevators and floor slabs, `s25` upper floors (rooms, islands), `s26` hotel and
  guests, `s27` expansion, `s28` ground operations, `s29_resort` Paradise Island and its air traffic control,
  `s29_rides` the theme park and its rides, `s30` airports and pads, `s40` passengers, `s50` plane paths and flights,
  `s60` main loops.
- `src/client/AirportClient.lua` + `src/client/BuildTag.lua` make StarterGui.AirportClient.
- `base/AirportTycoon.rbxl` is the original place the build starts from.

## Build and test
```
pip install lz4 lupa
python3 tools/build.py                          # writes AirportTycoon-Admin.rbxl (syntax-checks every script)
python3 tools/test/runner.py 300 45 --client --geo  # runs the server in a mock Roblox (300 s, 45 s flights)
python3 tools/test/runner.py 900                    # 15 minutes: round trips to Paradise, landing slots, plane spacing
```
The test claims airports, buys all 311 items on two of them, and simulates play. It checks that passengers reach every
floor, guests stay in rooms, elevators stop at every level, nobody gets stuck, and planes board, depart, cruise
high and land. A player
uses the hotel elevator (CALL pad, then a floor button). It also saves, rejoins and checks everything rebuilds, runs the
client UI, and looks for buy pads blocked by parts and people walking through walls. For Paradise Island it checks
that all 10 rides move (and the coaster goes upside down), that planes land at their booked slot, how close two
planes ever get there, round-trip times, stands in use, park visitors (nobody stuck or walking through anything),
that moving ride parts never pass through the park's fixed parts, and that a player gets sent to the park.

## Modern look
A ModernLook script makes the place look newer with only what a 2016 game has: smooth surfaces everywhere (no studs),
no outlines, shadows, light colour grading, a soft glow on bright/neon things and sun rays (effects only if the
Roblox version has them).
