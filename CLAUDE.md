# Eat the World — Roblox restaurant tycoon

This repo holds **Eat the World**, a Roblox restaurant tycoon, plus a team of
specialized subagents (`.claude/agents/`) that design, script, and ship it.
Players claim one of 6 hub plots, roll rarity-weighted food from a vendor,
curate a limited menu, and serve customers who fill all seats concurrently
and pay out (scaled by the 5-track upgrade system: Restaurant Size, Kitchen
Speed, Luck, Customer Tips, Menu Slots). Money persists per player via
DataStore.

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

## Project layout

Rojo syncs `src/` into Studio (`default.project.json`). One-way: files are
the source of truth.

```
src/
  server/          -- ServerScriptService: systems (PlotManager, CustomerSystem,
    Modules/          PizzaVendor, ...) + Modules/ (Economy, Upgrades, RarityRoller, ...)
  client/          -- StarterPlayerScripts: UI controllers (one ScreenGui each)
  shared/Data/     -- ReplicatedStorage.Data: UpgradeCatalog, ShopCatalog,
                      RarityTable, Foods/
```

`ReplicatedStorage.Remotes` (the RemoteEvents) is declared in
`default.project.json`. The built world — `Workspace.Plots` / `.Hub` /
`.Destinations`, Lighting — is **not** in Rojo; it lives in
`eattheworld.rbxl`. Runtime code reaches it via `Workspace:WaitForChild(...)`.
`docs/place-structure.txt` snapshots that hierarchy.

- Luau, not vanilla Lua — use type annotations (`--!strict` where practical).
- One ModuleScript per system; avoid god-modules.
- Gameplay-effect formulas (tip multiplier, eat speed, luck, table count)
  live in `Modules/Upgrades.luau` so every system reads the same numbers.
- Never trust the client: validate all remote event/function input on the
  server (type, range, ownership) and rate-limit anything spammable.
- Keep monetization logic server-authoritative (grant items/currency only
  after a verified server-side purchase callback).

## Style

No comments unless explaining a non-obvious constraint. No speculative
abstractions — build what the current feature needs.
