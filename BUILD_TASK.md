# BUILD: "Meme Reef: Tide of the Weird" — make.fun roblox-brainrot-01

You are building a 3D Roblox game in this repository (`reef-tide`) for make.fun's
roblox-brainrot-01 bounty. A recording is running: work only through your tools,
in this repository, and never delete or rewrite git history.

## Hard rules

- Build with **Rojo**: edit files under `src/`, then `rojo build default.project.json --output game.rbxl`.
  Never open a `.rbxlx`; the delivered place must be binary `game.rbxl`.
- Every script is a `src/**/*.luau` file. `game.rbxl` is generated only from `src/` + `default.project.json`.
- Real 3D world with a real 3D camera. `ScreenGui` is an overlay only (HUD and title screen).
- Original characters, names and assets. Do not copy another game's names or IP.
- Do NOT publish anything, do NOT touch any Roblox account, do NOT run any Open Cloud call,
  do NOT write API keys anywhere. Publishing is a later human step outside this session.
- Do NOT edit `vendor/makefun-roblox.ts` (kit copy, byte-exact), `LICENSE`, or `screenshots/` contents.
- Keep `main.ts` working; you must edit it (it needs real content of yours).

## The game (design law — treat as hard requirements)

World: a floating coral reef hub on a bright turquoise sea. No flat baseplate look —
everything floats over open water. Dense and finished: coral towers, salvage lamps,
signposts, flags, tethered balloons, drifting sky-junk, clouds. Nothing empty.

- Per-player base pad (one pad per playing player, placed on the reef ring), a central
  donation fountain (shop), and a raiders' jetty.
- The threat: **"The Tide"** — a tsunami wall sweeps the reef every 90 s with a 10 s klaxon
  warning (HUD banner). If a player is caught off their own pad when it hits, their two
  rarest brainrots fly up as collectible orbs for 15 s and anyone can grab them.
  Standing on your own pad (safe zone) = nothing lost. Walking home with a fresh catch
  must feel dangerous.
- 10-tier brainrot ladder (data-driven rows, one built model each), income per second:
  1 Soggy Biscuit Guy 1/s, 2 Microwave Prawn 4/s, 3 Corona Crab 12/s, 4 Nyalakan Bae 35/s,
  5 Skibidi Sirens 100/s, 6 Womp Womp Whale 280/s, 7 Sigma Starfish 800/s,
  8 Grimace Reef 2,400/s, 9 Ohio Trench Lord 7,000/s, 10 The Final Boss of the Sea 20,000/s.
- Purchase at the fountain with cash; mutations on purchase (Shiny 1.5x, Glitched 2.5x, ROT 4x
  as colour/particle variants); rebirth at 8 brainrots owned keeps a cash-rate multiplier
  and resets the base. Cash ticks per second with a floating counter above each collector.
- make.fun branding woven in: start gate text "make.fun REEF", a banner
  "make.fun REEF — the Tide is coming", 2 billboards "Built by an AI agent for make.fun".

## HUD

Cash top-center-right, tier list on the right edge, tide klaxon banner bottom-center,
all semi-transparent (~0.45). Nothing in the top-left corner (Roblox menu overlays it).
Title text must not hug the top edge. A real title screen at entry, not a plain spawn.

## Build-quality lessons (from a previous build that scored badly — do not repeat)

- No gaps players can fall through by accident; no kill plane hidden under a solid baseplate.
  Water level sits below the pads; a fall respawns the player on their own pad.
- No decoration loop inside a touch/damage handler (errors every frame).
- Paths between fountain, pads and jetty are continuous and walkable; obstacles span the path.
- Verify spawn: the character must be placed ON the ground at spawn (no players stuck in the sky).
- Self-review the full Luau before you finish: nil-indexing, unbounded loops, RemoteEvent
  argument validation (server never trusts the client's numbers), rate-limited purchases.

## Structure to build

- `src/server/`: `data.luau` (tiers, mutations, tuning constants), `Economy.luau`,
  `TideCycle.luau`, `BasePad.luau`, `World.luau` (dense world build), `Rebirth.luau`,
  plus `init.server.luau` as the entry that requires them.
- `src/client/`: `Hud.luau`, `TideWarning.luau`, `CameraRig.luau`, `TitleScreen.luau`,
  plus `Game.client.luau` as the entry.
- `default.project.json`: `DataModel` name must be **Meme Reef: Tide of the Weird**.

## Phases (work in this order, commit between phases)

1. Data + economy server core + world builder (dense world, pads, fountain, jetty) →
   `rojo build` must succeed. Commit.
2. Tide cycle + orb drop/steal + rebirth + client HUD/camera/title screen → build again. Commit.
3. Polish pass: density details, billboards, lint/self-review of all Luau, then
   `rojo build` again and `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts`. Commit.

Run `rojo build default.project.json --output game.rbxl` after every phase and fix every
build error. Do not finish with a broken build.

## main.ts

Keep its behaviour (copy game.rbxl, src/, screenshots/, PLAY.json to the output dir,
write dossier.json via vendor/makefun-roblox.ts) and add real improvements of your own:
for example a check that `game.rbxl` is binary and newer than `src/`, a script-coverage
report (every `.luau` under src/ present in the place by name), and a readable summary
line per produced file. Keep it standard-library only, Node 22.

## HANDOFF.md

Create and update `HANDOFF.md` in the repo root between phases: what is done, what is
next, any known issue. Write it with your own words.

## Finish

End with: `git add -A && git commit`, then print a short report:
files written, `rojo build` result, `node main.ts` result. Do not publish. Do not submit.
