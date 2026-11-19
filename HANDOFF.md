# HANDOFF — Meme Reef: Tide of the Weird

Building `reef-tide` for make.fun roblox-brainrot-01 per BUILD_TASK.md. Nothing published; no Roblox account touched; no Open Cloud calls; no keys anywhere.

## Done
- Phase 1 (93bab8c): project + server core.
  - `default.project.json`: DataModel "Meme Reef: Tide of the Weird", terrain water props, bright lighting, no baseplate, CharacterAutoLoads off.
  - `src/server/data.luau`: 10-tier ladder with the design-law rates (1/s … 20,000/s) and costs, mutations Shiny 1.5x / Glitched 2.5x / ROT 4x with weighted rolls, all tuning constants (90 s tide, 10 s warning, 15 s orbs, pad radius 9, rebirth at 8, x2 per rebirth).
  - `src/server/Economy.luau`: profiles, 1 s cash tick, floating-counter payloads; `BuyBrainrot`/`Rebirth` remotes fully validated server-side (tier id range, fountain proximity, cost, 0.25 s rate limit, owned cap) — the client's numbers are never trusted.
  - `src/server/World.luau`: dense floating reef — hub disc + hanging coral, 8 ring pads with spokes and continuous ring walkway, donation fountain with "make.fun REEF — the Tide is coming" banner, raiders' jetty (between pads) ending at the "make.fun REEF" start gate, 2 "Built by an AI agent for make.fun" billboards, coral towers, salvage lamps, signposts, flags, tethered balloons, drifting sky-junk, clouds, buoys, rocks, sea at y=-6 below every pad. Built brainrot models (one per tier, mutation colour/particle variants) + billboard cash counters.
  - `src/server/BasePad.luau`: one pad per player, safe-zone check, spawn placed ON the ground, fall-into-water respawns on own pad (no kill plane), collector stack refresh on owned-count change.
- Phase 2 (a5ad89e): gameplay + client.
  - `src/server/TideCycle.luau`: 90 s cycle, 10 s klaxon (HUD banner, ticking countdown), animated shrinking tsunami wall sweep; players caught off their own pad drop their two rarest brainrots as orbs for 15 s, grabbable by anyone within 5 studs.
  - `src/server/Rebirth.luau`: rebirth at 8 owned keeps cash-rate multiplier, resets the base.
  - `src/client/`: `Hud.luau` (cash top-center-right, tier ladder right edge with click-to-buy, rebirth button; all ~0.45 transparent, nothing top-left), `TideWarning.luau` (klaxon banner bottom-center), `CameraRig.luau` (real 3D scriptable follow camera, Q/E orbit), `TitleScreen.luau` (entry title screen, title well below the top edge, dismiss spawns the character), `Game.client.luau` entry.
- Phase 3 (7c4ad29): polish + self-review + main.ts.
  - Density pass (buoys, rocks), jetty moved between pad slots so no walkway is blocked, warning countdown rebroadcast every 0.5 s, dead code removed, collector refresh decoupled from Economy (no circular require).
  - Self-review of all Luau: no nil-indexing on remotes (WaitForChild), bounded loops, no decoration loops in touch handlers, RemoteEvent args validated, purchases rate-limited and fountain-checked.
  - `main.ts` improved (behaviour kept): refuses a non-binary or stale `game.rbxl` (magic + mtime vs src/), script-coverage report (every src .luau present in the place by Rojo path), one summary line per produced file. Std-lib only, Node 22.
  - `rojo build default.project.json --output game.rbxl` succeeds; `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts` succeeds (12/12 scripts covered, dossier written).
- Phase 4 (this commit): fresh verification + fix pass.
  - Re-ran `rojo build` and `node main.ts` clean, then self-reviewed every `src/*.luau` against the build-quality lessons.
  - Fixes: spokes/ring walkway/jetty beams now sit with their top flush at WALK_TOP via a `deck()` helper, so hub, pads and walkways are one continuous walkable surface (they were 2 studs proud); added a `GateDeck` platform under the start gate and clamped `World.spawnPoint` to the deck top, so the entry spawn rests on the ground instead of over open water past the jetty end; re-indented the mis-nested `sweep()` body and tide loop in `TideCycle.luau`.
  - Confirmed clean on re-review: spawn placed ON the ground (pad top + 1 stud, drops in), no decoration loops in any touch handler (orb pickup is a bounded Heartbeat distance check; there are no Touched handlers), all RemoteEvent args validated server-side (tier range, fountain proximity, cost, 0.25 s rate limit, owned caps), HUD has nothing in the top-left and the title sits at 0.32 of the screen, water at y=-6 below every pad with fall-respawn on the own pad (no kill plane).
  - `main.ts` revised again (behaviour kept): adds a byte-level source-coverage report via the kit's `matchSources` — every src file's normalised bytes must equal a script's source in the place, not just match by name; fails loudly on any unmatched file. Std-lib only, Node 22.
  - `rojo build` succeeds; `MAKEFUN_OUTPUT_DIR=out node main.ts` succeeds: 12/12 scripts by name, 100.0% of script bytes byte-identical to a src/ file, dossier written.

## Next
- Nothing in this session: publishing is a later human step. PLAY.json still names no place.

## Known issues
- Collector stack shows at most 10 models per pad (HUD lists all owned) — deliberate readability choice.
- Screenshots are still the kit's starter PNGs; real captures need a running Studio session (human step).
