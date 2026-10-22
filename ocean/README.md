# Disaster Ocean (2016 edition)

An original ocean disaster survival game in the style of Natural Disaster Survival, for 2016 Roblox.
Open/upload `DisasterOcean.rbxl`.

- **Lobby**: a house floating high in the sky on a rock island above the clouds, with a porch, a telescope pointed
  at the boat, a fireplace and couches. Inside are the **vote stations**: step on a pad to vote for
  - the **boat**: Cruise Liner, Pirate Galleon or Navy Destroyer;
  - the **theme of the whole map**: Normal, Sunset or **Halloween** (night sky, purple fog, dark water, glowing
    pumpkins on the lobby and the boat, black sails on the galleon, a ghost ship drifting in the fog).
- **The boats have real rooms**:
  - Cruise Liner: dining room, 6 cabins with beds along a corridor, a lounge with sofas, a bar and a piano, a sun
    deck with the bridge and two funnels, a pool deck, 8 lifeboats.
  - Pirate Galleon: captain's cabin under the quarterdeck (chart table, treasure chest, bed), crew quarters with
    hammocks under the forecastle, 3 masts with sails, cannons, the Jolly Roger, 4 rowboats.
  - Navy Destroyer: mess hall, bunk room, a bridge with radar screens, a radar mast, gun turrets, a helipad,
    6 life rafts.
- **The sea**: real Terrain water round the boat (ripples, reflections, you can swim), rolling wave crests with white
  tops and foam streaming past the boat so it looks like it's sailing straight ahead, spray at the bow. The boat rolls,
  pitches and heaves on the swells. Waves crash into it every round.
- **Disasters** (sometimes two at once): Tsunami, Tornado, Hurricane, Meteor Shower, the Kraken, Shark Attack.
- **The boat takes damage** (health bar on screen); pieces break off; at 0 it sinks and the lifeboats drop. The water
  hurts. Survivors get Coins.
- Admin for `asdasda` only, FilteringEnabled on.

Sources: `src/server/o*.lua` (joined into ServerScriptService.OceanServer), `src/OceanClient.lua`.
Build: `python3 tools/build.py`. Test: `python3 tools/test/runner.py`.
