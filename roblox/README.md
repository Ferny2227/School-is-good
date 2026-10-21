# Airport Tycoon

`AirportTycoon-Admin.rbxl` is the place file to open in Studio. It is built from the sources in `src/`.
The text at the bottom of the screen ("build 8") tells you which build is running.

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
- **Real flights**: every gate has a fleet of 4 airliners (remote stands and cargo stands 2). Two pilots sit in each
  see-through cockpit and fly it. At the gate, arriving passengers get off through the jet bridge (to baggage claim and
  out the front), the crew walks off, then new passengers board (they wait at the gate up to 90 s), the crew
  walks back on, and the plane pushes back, taxis, takes off, flies a big loop around the airport for about
  5 minutes (`FLY.CRUISE`, at least `FLY.MINCRUISE`), and comes back to land as its gate frees up: when a plane
  leaves, the fleet's next plane is already on its way in, so gates stay busy. The flight screens show it all.
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
  guests, `s27` expansion, `s28` ground operations, `s30` airports and pads, `s40` passengers, `s50` plane paths,
  `s60` main loops.
- `src/client/AirportClient.lua` + `src/client/BuildTag.lua` make StarterGui.AirportClient.
- `base/AirportTycoon.rbxl` is the original place the build starts from.

## Build and test
```
pip install lz4 lupa
python3 tools/build.py                          # writes AirportTycoon-Admin.rbxl (syntax-checks every script)
python3 tools/test/runner.py 300 45 --client --geo  # runs the server in a mock Roblox (300 s, 45 s flights)
python3 tools/test/runner.py 900 300                # 15 minutes with real 5-minute flights: time in the air, busy gates
```
The test claims airports, buys all 311 items on two of them, and simulates play. It checks that passengers reach every
floor, guests stay in rooms, elevators stop at every level, nobody gets stuck, and planes board, depart, cruise
high and land. A player
uses the hotel elevator (CALL pad, then a floor button). It also saves, rejoins and checks everything rebuilds, runs the
client UI, and looks for buy pads blocked by parts and people walking through walls.
