# reef-tide

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/JustinRzx/reef-tide/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/JustinRzx/reef-tide/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Meme Reef: Tide of the Weird — a 3D Roblox brainrot game built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty. A floating coral reef over a turquoise sea: buy absurd meme-born brainrots at the donation fountain, stack them on your own base pad, climb a 10-tier ladder with Shiny/Glitched/ROT mutations and rebirths — and every 90 seconds The Tide sweeps the reef after a 10-second klaxon. Caught off your pad, your two rarest brainrots fly up as orbs anyone can grab for 15 seconds. Walk home with a fresh catch before the wall hits.

## Run it

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged. `game.rbxl` is the binary place Rojo builds from `src/` and `default.project.json`; every script of the place is a `.luau` file under `src/`. `PLAY.json` names the published Roblox experience (filled in after publishing). One of the screenshots is the same picture as the game's first thumbnail on Roblox.

---

<sub>Entered on [make.fun](https://make.fun/?ref=pkcbvd3n&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>