// A working roblox-brainrot-01 entry (Node 22, standard library only): the game is this directory's Rojo
// project, built into game.rbxl with `rojo build default.project.json --output game.rbxl`, and the program
// hands it in. It copies game.rbxl, src/, screenshots/ and PLAY.json from beside this file to /output and
// writes /output/dossier.json, the summary the judge reads, with the vendored make.fun library.
//
// Every name under /output starts with a letter, a digit or _ and holds only letters, digits, . _ and -: the
// grader fails an entry whose output holds any other, so a file such as .gitkeep or .DS_Store copied in fails it.
// So src/ and screenshots/ are copied without any name that starts with a dot, at any depth.
//
// On top of the starter behaviour it checks what it hands in before writing anything: game.rbxl must be a
// binary place (magic `<roblox!`) and newer than every file under src/ (a stale build fails loudly), and every
// .luau/.lua under src/ must appear as a script of the built place by name (script-coverage report) and, byte
// for byte after source normalisation, equal some script's source (source-coverage report). Each produced
// file gets one readable summary line.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, lstatSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier, matchSources, readPlace, rojoPath } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

/** Every regular file under root, as POSIX paths relative to it. */
const filesUnder = (root: string, rel = ''): string[] =>
  readdirSync(rel === '' ? root : join(root, rel), { withFileTypes: true }).flatMap((e) => {
    const p = rel === '' ? e.name : `${rel}/${e.name}`;
    return e.isDirectory() ? filesUnder(root, p) : e.isFile() ? [p] : [];
  });

/** The binary-place magic every .rbxl/.rbxm opens with. */
const RBXL_MAGIC = Buffer.from([0x3c, 0x72, 0x6f, 0x62, 0x6c, 0x6f, 0x78, 0x21, 0x89, 0xff, 0x0d, 0x0a, 0x1a, 0x0a]);

// --- checks on the built place, before anything is copied -------------------------------

const gamePath = join(here, 'game.rbxl');
const gameBytes = readFileSync(gamePath);
if (gameBytes.subarray(0, RBXL_MAGIC.length).equals(RBXL_MAGIC) === false) {
  throw new Error(`${gamePath} is not a binary Roblox place: it does not open with the <roblox! magic (build with \`rojo build default.project.json --output game.rbxl\`)`);
}
const gameMtime = statSync(gamePath).mtimeMs;

const srcFiles = filesUnder(join(here, 'src')).filter((p) => /\.(luau|lua)$/.test(p));
const stale = srcFiles.filter((p) => statSync(join(here, 'src', p)).mtimeMs > gameMtime);
if (stale.length > 0) {
  throw new Error(`game.rbxl is older than src/ (${stale.length} file${stale.length === 1 ? '' : 's'}, e.g. ${stale[0]}): rebuild with \`rojo build default.project.json --output game.rbxl\` before handing in`);
}

const place = readPlace(new Uint8Array(gameBytes));
// A file's script path in the place, relative to its mount: init.* names its directory,
// else the file's path less its suffix, with the mount's top folder (server, client)
// dropped — that is the path Rojo gives it below ServerScriptService.Server /
// StarterPlayer.StarterPlayerScripts.Client.
const scriptPaths = [...new Set(place.scripts.map((s) => s.path))];
const missing = srcFiles.filter((p) => {
  const r = rojoPath(p);
  if (r === null) return true;
  // init.* at a mount's top names its directory (''), which is no path below the
  // mount: match the mount folder itself in that case.
  const rel = r.path === '' ? '' : r.path.split('.').slice(1).join('.');
  if (rel === '') return !scriptPaths.some((sp) => /(^|\.)Server$/.test(sp) || /(^|\.)Client$/.test(sp));
  return !scriptPaths.some((sp) => sp === rel || sp.endsWith(`.${rel}`));
});
if (missing.length > 0) {
  throw new Error(`script coverage: ${missing.length} of ${srcFiles.length} src/ files are not scripts of game.rbxl (${missing.join(', ')})`);
}
// Byte-level coverage: each src file's normalised bytes must equal a script's source in
// the place, so a place that merely carries the right names is not enough.
const srcSources = srcFiles.map((p) => ({ path: p, bytes: new Uint8Array(readFileSync(join(here, 'src', p))) }));
const match = matchSources(place, srcSources);
if (match.unmatched.length > 0) {
  throw new Error(`source coverage: ${match.unmatched.length} of ${srcFiles.length} src/ files differ from every script of game.rbxl (${match.unmatched.join(', ')})`);
}
const scriptBytes = place.scripts.reduce((n, s) => n + (s.source?.length ?? 0), 0);
console.log(`game.rbxl: binary place, ${place.instances} instances, ${place.scripts.length} scripts (${scriptBytes} bytes of source), built ${new Date(gameMtime).toISOString()}`);
console.log(`script coverage: ${srcFiles.length}/${srcFiles.length} src/ .luau files present in the place by name`);
console.log(`source coverage: ${(match.coverage * 100).toFixed(1)}% of script bytes byte-identical to a src/ file (${match.matched.length}/${srcFiles.length} files matched)`);

// --- hand in -----------------------------------------------------------------------------

mkdirSync(out, { recursive: true });
const report: string[] = [];

const copyOne = (from: string, to: string, note: string): void => {
  copyFileSync(from, to);
  const size = lstatSync(to).size;
  report.push(`${basename(to)}: ${size} bytes${note === '' ? '' : ` — ${note}`}`);
};

copyOne(join(here, 'game.rbxl'), join(out, 'game.rbxl'), 'binary place built from src/ + default.project.json');
copyOne(join(here, 'PLAY.json'), join(out, 'PLAY.json'), 'published place (filled in by a human after publishing)');
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
report.push(`src/: ${srcFiles.length} script files copied (${srcFiles.map((p) => p).join(', ')})`);
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
const shots = existsSync(join(here, 'screenshots')) ? filesUnder(join(here, 'screenshots')).filter((p) => !basename(p).startsWith('.')) : [];
report.push(`screenshots/: ${shots.length} image${shots.length === 1 ? '' : 's'} copied${shots.length > 0 ? ` (${shots.join(', ')}, first is the cover)` : ''}`);

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
const dossier = buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 });
writeFileSync(join(out, 'dossier.json'), dossier);
report.push(`dossier.json: ${dossier.length} bytes of canonical JSON (makefun/dossier/v1)`);

for (const line of report) console.log(line);
console.log(`handed in to ${out}`);
