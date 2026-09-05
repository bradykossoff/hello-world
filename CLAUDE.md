# Roblox Dev Workstation

This repo is a Claude Code workstation for building Roblox games. It has no
game code yet — it's a team of specialized subagents (`.claude/agents/`) set
up to design, script, and ship a Roblox experience once one is started here.

## The team

Delegate work to these subagents with the `Agent` tool (`subagent_type`) when
a task clearly falls in their lane. For small, single-file edits or quick
questions, just do the work directly instead of routing through an agent.

- **roblox-game-designer** — mechanics, systems, level/progression design,
  game design docs. Start here for "what should this feature do" questions.
- **roblox-scripter** — Luau gameplay code (client, server, and shared
  modules), performance, replication, data stores.
- **roblox-ui-artist** — in-game UI/UX: ScreenGuis, HUD, menus, mobile and
  console layout, UI Luau code.
- **roblox-monetization** — game passes, developer products, in-game economy
  balancing, monetization design that stays within Roblox's Terms of Service.
- **roblox-qa** — test plans, edge cases, exploit/bug hunting, performance
  profiling, review before shipping.

A typical feature flow: game-designer defines the mechanic → scripter and
ui-artist implement it → qa reviews it → monetization weighs in only if the
feature touches purchases or the economy.

## Project conventions (once game code exists)

Use the standard Rojo layout so any subagent can predict where code lives:

```
src/
  client/   -- LocalScripts, UI controllers
  server/   -- Server-side gameplay logic, data stores
  shared/   -- ModuleScripts used by both client and server
```

- Luau, not vanilla Lua — use type annotations (`--!strict` where practical).
- One ModuleScript per system; avoid god-modules.
- Never trust the client: validate all remote event/function input on the
  server.
- Keep monetization logic server-authoritative (grant items/currency only
  after a verified server-side purchase callback).

## Style

No comments unless explaining a non-obvious constraint. No speculative
abstractions — build what the current feature needs.
