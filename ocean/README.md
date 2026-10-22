# Disaster Ocean (2016 edition)

An original ocean disaster survival game in the style of Natural Disaster Survival, for 2016 Roblox.
Open/upload `DisasterOcean.rbxl`.

- **Lobby island**: everyone waits here (20 s intermission).
- **The ship**: every round the whole lobby is teleported onto the **SS DISASTER**, a big ocean liner out at sea
  (three decks of cabins with ladders, a bridge, two funnels, a pool, deck chairs, a mast, 8 lifeboats). It rocks on
  the waves.
- **Waves every round**: the open ocean keeps rolling waves into the ship (every 9-15 s), rocking it and wearing it
  down a little, on top of the disaster.
- **Disasters** (75 s, sometimes two at once from round 3): Tsunami, Tornado, Hurricane (rain, wind, lightning),
  Meteor Shower, the Kraken (tentacles slam the deck) and Shark Attack.
- **The ship takes damage**: its health bar is on everyone's screen (1000 + 250 per player); pieces break off and
  fall in the sea. At 0 health it **sinks** and its lifeboats drop into the water.
- **The water hurts** (7 health a second): you float, but get to a lifeboat!
- Everyone still alive at the end survives: +40 Coins (+60 if the ship sank). Then everyone goes back to the lobby.
- Admin for `asdasda` only, FilteringEnabled on.

Build: `python3 tools/build.py` (starts from `../roblox/base/AirportTycoon.rbxl`; the server removes that map and
builds the ocean world when the game starts). Test: `python3 tools/test/runner.py`.
