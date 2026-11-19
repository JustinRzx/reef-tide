# HANDOFF — Meme Reef: Tide of the Weird

Building `reef-tide` for make.fun roblox-brainrot-01 per BUILD_TASK.md. Nothing published; no Roblox account touched.

## Done
- Read BUILD_TASK.md; repo surveyed (starter kit: 2 stub scripts, old default.project.json, main.ts, vendor kit).
- Phase 1 in progress: new `default.project.json` (DataModel name "Meme Reef: Tide of the Weird", no baseplate, bright sea), server core `src/server/` (data, Economy, World, BasePad, init) being written.

## Next
- Phase 1: finish `src/server/` (data.luau, Economy.luau, World.luau, BasePad.luau, init.server.luau), `rojo build default.project.json --output game.rbxl`, fix errors, commit.
- Phase 2: TideCycle.luau, Rebirth.luau, client Hud/TideWarning/CameraRig/TitleScreen/Game.client.luau; build; commit.
- Phase 3: polish pass (density, billboards, branding), Luau self-review, improved main.ts, `rojo build` + `MAKEFUN_OUTPUT_DIR=out node main.ts`; commit.

## Known issues
- None yet.
