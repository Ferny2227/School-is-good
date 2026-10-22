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
- **The sea**: huge rolling swells (like Sea of Thieves, ~30 studs from trough to crest, taller than the boats) come
  one after another, and the direction they come from slowly turns (ahead, the side, behind...). Invisible walls round
  the deck keep everyone on board (they go away when the boat sinks). Each swell lifts the bow,
  then the middle, then the stern, so the boat rocks with every wave; every so often a set of even bigger waves
  builds up, rolls through the boat (screen shake, damage, water washing over the deck) and dies down again. The
  swells are drawn on each player's computer (dark troughs, turquoise faces, white foam on the crests) with the same
  maths the server uses to move the boat (`src/shared/SeaHeight.lua`), so the boat always sits on the drawn water.
- **Last one standing**: once the boat leaves, disasters keep coming one after another (12 s of calm in between,
  +40 Coins for each one you live through) until only ONE player is left alive: they win (+1 Win, +150 Coins). Alone,
  it goes on until you die. Then it resets to the sky lobby. The boats can't break or sink. Fell in? Press jump to
  leap back onto the boat.
- **Disasters** (sometimes two at once): Hailstorm, Whirlpool (spins the boat and drags it down), Iceberg (rips the
  hull open), Ghost Ship (fires cannonballs), Tsunami (one giant swell rises ahead and lifts the whole boat), Tornado (picks
  the boat up out of the sea, spins it and drops it), Hurricane (even bigger seas, wind, lightning), Meteor Shower,
  the Kraken, Shark Attack.
- **The boat takes damage** (health bar on screen); pieces break off; at 0 it sinks and the lifeboats drop. The water
  hurts. Survivors get Coins.
- Admin for `asdasda` only, FilteringEnabled on.

Sources: `src/server/o*.lua` (joined into ServerScriptService.OceanServer), `src/OceanClient.lua`.
Build: `python3 tools/build.py`. Test: `python3 tools/test/runner.py`.
