# HANDOFF — Meme Reef: Tide of the Weird

Building `reef-tide` for make.fun roblox-brainrot-01 per BUILD_TASK.md. Nothing published; no Roblox account touched.

## Done
- Phase 1 committed (93bab8c): `default.project.json` (DataModel "Meme Reef: Tide of the Weird", water terrain, no baseplate, bright lighting), server core:
  - `src/server/data.luau` — 10-tier ladder with exact design-law rates/costs, 3 mutations (Shiny 1.5x / Glitched 2.5x / ROT 4x), weighted rolls, all tuning constants.
  - `src/server/Economy.luau` — per-player profiles, validated + rate-limited `BuyBrainrot`/`Rebirth` remotes, 1 s cash tick, state broadcast.
  - `src/server/World.luau` — dense floating reef: hub disc + underside coral, 8 ring pad slots with spokes and ring walkway, donation fountain with "make.fun REEF — the Tide is coming" banner, raiders' jetty with "make.fun REEF" start gate, 2 "Built by an AI agent for make.fun" billboards, coral towers, salvage lamps, signposts, flags, tethered balloons, drifting sky-junk, clouds, water at y=-6 (below pads). Built brainrot models + floating cash counters.
  - `src/server/BasePad.luau` — one pad per player, safe-zone check, spawn placed ON the ground, fall-into-water respawns on own pad, collector stack per pad.
  - `src/server/init.server.luau` entry. `rojo build` succeeded; `game.rbxl` is binary (magic verified).

## Next
- Phase 2: `TideCycle.luau` (90 s cycle, 10 s klaxon, tsunami wall, orb drop/steal of two rarest, 15 s orbs), `Rebirth.luau`, client side: `Hud.luau` (cash, tier list, klaxon banner, all ~0.45 transparent, nothing top-left), `TideWarning.luau`, `CameraRig.luau` (real 3D camera), `TitleScreen.luau`, `Game.client.luau`. Build, commit.
- Phase 3: polish + self-review + main.ts improvements + `node main.ts`. Commit.

## Known issues
- Collector stack caps at 10 visible models per pad (HUD lists the rest) — deliberate, to keep pads readable.
- Tide/rebirth gameplay lands in phase 2; phase 1 is world + economy only.
