# Disaster Ocean (2016 edition)

An original ocean survival game in the style of Disaster Ocean, for 2016 Roblox. Open/upload `DisasterOcean.rbxl`.

- **Harbour island** in the middle of a huge ocean: a pier with 10 boat slips, the **Dockmaster** (click him for a
  boat), a lighthouse, a boathouse, palms and buoys.
- **Boats** (one per player): Rowboat (free), Speedboat (150 Coins), Fishing Boat (400), Yacht (1200, two decks).
  Sit in the black seat to drive (W/S/A/D). Everyone can ride along on the seats or stand on deck. Boats have health
  and sink when it runs out.
- **Rounds**: 25 s intermission, then a disaster for 70 s; survivors get 40 Coins (+20 if their boat is still afloat).
  From round 3 two disasters sometimes hit at once.
- **Disasters**: Tornado (chases people, flings them, spins boats), Tsunami (a giant wave sweeps the map; ride it in
  a boat, the island floods), Hurricane (dark sky, rain, big waves, wind and lightning), Meteor Shower, Whirlpool
  and Shark Attack.
- People who fall in the water swim at the surface.
- Admin for `asdasda` only (same admin as the airport), FilteringEnabled on.

Build: `python3 tools/build.py` (starts from `../roblox/base/AirportTycoon.rbxl`; the server removes that map and builds
the ocean world when the game starts). Test: `python3 tools/test/runner.py`.
