# Airport Tycoon admin panel
`AirportTycoon-Admin.rbxl` = your place with:
- ServerScriptService.AdminServer (AdminServer.lua) - all commands; only obeyed for the player named `asdasda`
- ServerScriptService.AdminServer.AdminClient (AdminClient.lua) - the red ADMIN button/panel; the server
  copies it into asdasda's PlayerGui only, so other players never receive it
- StarterGui.AdminAnnounce (AdminAnnounce.lua) - shows announcements to everyone
- Workspace.FilteringEnabled turned on (anti-exploit)
- a small "build: admin-3" tag at the bottom of the screen (BuildTag.lua, appended to AirportClient)

Chat commands (asdasda only): `;kick name reason`, `;ban name reason`, `;unban name`, `;kill`, `;respawn`,
`;heal`, `;god`, `;ungod`, `;freeze`, `;unfreeze`, `;speed name 50`, `;jump name 100`, `;bring`, `;tp`,
`;cash name 1000`, `;announce text`, `;cmds`.
