# MechaCubes hub – stuck on "Loading assets.." fix

`MechaCubes_fixed.rbxl` is the fixed place. Open it in Studio (File > Open from File) and press Play.

## Why it was stuck
The loading screen only closes when the server says your data has loaded. The server waited for
Roblox's save servers (DataStores) **forever**. When the place isn't published, Studio API access is
off, or the server can't reach the save servers, they either error (and the code retries forever) or
crash the server script. Either way nobody got past "Loading assets..".

## Fixes (marked `-- [fix]`)
- New `ServerScriptService.server.safeData`: tests the save servers once (max 8 s). If they don't work,
  the game runs in **offline mode**. Everything works, but progress isn't saved, and the Output says so.
  `user`, `hub` and `hub.gameData` use it instead of `DataStoreService`.
- `server`: connects `PlayerAdded` first, then loads players already in the server at the same time
  (before, one waiting player blocked everyone else).
- `user.playerAdded`: waits at most 20 s for the client, and the gamepass checks run at the same time
  with a 5 s limit (before, they ran one after another and could hang).

Tested with a fake save server that errors, one that never answers, and one that works: the original
stays stuck in the first two cases, the fixed version loads in 2 s, 10 s and 2 s.

## Saving in Studio
Publish the place and turn on Game Settings > Security > Enable Studio Access to API Services.

## Note
This is only the **hub** place. Starting a match teleports to the separate MechaCubes "game" place
(`gameId` in `ServerScriptService.server.hub`, currently tunicus's place 868967410). To play matches
you need that place too, with your own place ID set there (see `README_hub`).

`tools/patch.py original.rbxl fixed.rbxl` re-applies the fixes (it uses the place tools in `casino/tools`).
