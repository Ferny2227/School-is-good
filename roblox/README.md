# Airport Tycoon

`AirportTycoon-Admin.rbxl` is the place file to open in Studio. It is built from the sources in `src/`.
The text at the bottom of the screen ("build 4: 3 floors + hotel") tells you which build is running.

## What's in it
- **Bigger land**: every airport is 600 x 900 studs (was 420 x 620). Trees on it are cleared when the server starts.
- **309 things to buy** (was 104), in 12 phases:
  - 9. **Second Floor (Sky Mall)**: terminal elevators, 28 shops/restaurants around the walls, 32 smaller things in between.
  - 10. **Third Floor (Sky Deck)**: cinema, bowling, gym, aviation museum, lounges, plus games and decorations, and a roof with a rooftop garden.
  - 11. **Hotel**: lobby, reception, restaurant, gift shop, gym, an elevator, 4 floors with 8 rooms each (bought one by one), a rooftop bar, a pool with loungers, a pool bar, a water slide, a hot tub and a tennis court. Guests check in, ride up, sleep in a room, maybe swim, and pay for every night.
  - 12. **Expansion**: overflow parking, a gas station, police, 2 remote stands with airliners, a second runway with 3 cargo jets, a maintenance hangar, a solar farm and wind turbines.
- **Planes take off and land on their own**: the gate, remote-stand and cargo airliners push back, taxi, take off, fly away and come back to land.
- **Roblox-style people**: separate arms and legs that swing as they walk, the classic head and face.
- **Elevators**: step on the green UP or red DOWN pad inside an elevator to change floors.
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
  `s00` header and catalog, `s01` the new catalog (floors, hotel, expansion), `s10` people and planes, `s20` original
  item builders, `s25` upper floors and elevators, `s26` hotel and guests, `s27` expansion, `s30` airports and pads,
  `s40` passengers, `s50` plane paths, `s60` main loops.
- `src/client/AirportClient.lua` + `src/client/BuildTag.lua` make StarterGui.AirportClient.
- `base/AirportTycoon.rbxl` is the original place the build starts from.

## Build and test
```
pip install lz4 lupa
python3 tools/build.py                          # writes AirportTycoon-Admin.rbxl (syntax-checks every script)
python3 tools/test/runner.py 150 --client --geo  # runs the server in a mock Roblox
```
The test claims airports, buys all 309 items on two of them, and simulates play. It checks that passengers reach every
floor, guests stay in rooms and planes depart and land. It also saves, rejoins and checks everything rebuilds, runs the
client UI, and looks for buy pads blocked by parts and people walking through walls.
