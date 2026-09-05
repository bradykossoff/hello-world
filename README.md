# Roblox Dev Workstation

A Claude Code workstation for building Roblox games with a team of
specialized AI subagents instead of one generalist.

## The team (`.claude/agents/`)

| Agent | Role |
|---|---|
| `roblox-game-designer` | Mechanics, systems, progression, game design docs |
| `roblox-scripter` | Luau gameplay code — client, server, shared modules |
| `roblox-ui-artist` | In-game UI/UX (HUD, menus, mobile/console layout) |
| `roblox-monetization` | Game passes, dev products, economy balance, policy |
| `roblox-qa` | Test plans, exploit/edge-case review, performance review |

See `CLAUDE.md` for how the team collaborates and the project's Luau/Rojo
conventions. There's no game here yet — this is the workstation it'll be
built in.
