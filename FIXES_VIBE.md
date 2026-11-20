# FIXES_VIBE.md — Perbaikan 4 Temuan Sedang dari REVIEW_VIBE.md

Scope: hanya file di bawah `src/` yang diubah (ditambah `src/server/SharedTiers.luau` baru). `out/`, `game.rbxl`, dan `REVIEW_VIBE.md` tidak disentuh. Semua file tetap `--!strict`, dan tidak ada perubahan balance (tabel tier/mutasi/TUNING dipindahkan apa adanya — diverifikasi byte-identik dengan `diff`).

---

## Temuan 1 — Model sky-junk tidak punya `PrimaryPart` tapi digerakkan dengan `PivotTo` tiap frame

- **File yang diubah:** `src/server/World.luau` (fungsi `skyJunkPiece`).
- **Sebelum:** `skyJunkPiece` membuat model lalu meng-`Parent`-kan part `Junk` ke dalamnya, tetapi tidak pernah mengeset `model.PrimaryPart`. Loop `RunService.Heartbeat` di `World.build()` memanggil `model:GetPivot()` / `model:PivotTo(...)` setiap frame untuk 14 model; tanpa `PrimaryPart`, `GetPivot` mengembalikan pivot default (identity di origin), sehingga `PivotTo` bisa memindahkan sky-junk ke sekitar origin / tidak sesuai desain, dan pada beberapa versi engine malah melempar error setiap frame.
- **Sesudah:** setelah `p.Parent = model`, ditambahkan `model.PrimaryPart = p`, sehingga pivot model = CFrame part `Junk` dan `GetPivot`/`PivotTo` pada loop drift bekerja sebagaimana mestinya.

## Temuan 2 — `BasePad.release()` tidak menghancurkan `PadSign` dan `SafeZone` (instance leak)

- **File yang diubah:** `src/server/BasePad.luau`.
- **Sebelum:** `stylePad` membuat part `PadSign` (+ `SurfaceGui`) dan silinder `SafeZone` per pemain, tetapi `release()` hanya me-reset nama/warna pad — kedua instance itu tertinggal di workspace setiap pemain leave/rejoin, menumpuk tanpa batas.
- **Sesudah:** `BasePad` kini punya tabel `padDecor :: { [Player]: { sign: BasePart?, zone: BasePart? } }`; `stylePad` menyimpan referensi `sign` dan `zone` ke `padDecor[player]`, dan `release()` memanggil `Destroy()` pada keduanya (lalu menghapus entrinya) sebelum mereset visual pad. Tidak ada lagi instance yang bocor.

## Temuan 3 — Fallback penentuan slot bisa menimpa slot yang sudah dimiliki (>8 pemain)

- **File yang diubah:** `src/server/BasePad.luau` (fungsi `BasePad.assign`).
- **Sebelum:** jika semua slot penuh, fallback `slot = ((#Players:GetPlayers() - 1) % World.PAD_SLOTS) + 1` dipilih tanpa memeriksa `ownerOfSlot`, lalu `slotOfSlotFix` menimpa `ownerOfSlot[slot]` — satu slot bisa diklaim dua pemain sekaligus dan data kepemilikan korup.
- **Sesudah:** jika tidak ada slot kosong, `assign` langsung `return` tanpa mengubah `ownerOfSlot`/`slotOfPlayer` — pemain tidak mendapat slot (spawn di gate, sudah ditangani `spawnCharacter` yang memanggilnya dengan slot `nil`). Slot yang sudah dimiliki tidak pernah ditimpa.

## Temuan 4 — Data tier diduplikasi di client; HUD menampilkan harga dasar, bukan harga aktual

- **File yang diubah:** `src/server/SharedTiers.luau` (baru), `src/server/init.server.luau`, `src/server/data.luau`, `src/server/Economy.luau`, `src/client/Game.client.luau`, `src/client/Hud.luau`.
- **Sebelum:** tabel `TIERS` ada dua salinannya — di `src/server/data.luau` dan hasil copy manual di `src/client/Game.client.luau` (baris 19–30) — sehingga bisa drift; HUD menampilkan `${tier.cost}` (harga dasar), padahal server mengenakan `Data.costOf` = `base * 1.6^owned`.
- **Sesudah:**
  1. Tabel tier/mutasi (`TIERS`, `MUTATIONS`, `MUTATION_WEIGHTS` + tipe `Tier`/`Mutation`/`MutationId`) kini hanya ada di satu modul bersama: `src/server/SharedTiers.luau`. Karena `default.project.json` hanya me-map `src/server` dan `src/client` (dan hanya file di bawah `src/` yang boleh diubah), `init.server.luau` mem-publish module itu ke **ReplicatedStorage** saat boot (`ReplicatedStorage.Shared.Tiers`, hasil clone dari seed) sebelum me-require module lain — sehingga server (via `data.luau`) dan client (`Game.client.luau`) sama-sama me-`require` instance module yang sama di bawah ReplicatedStorage.
  2. `data.luau` kini menjadi facade: konstanta `TUNING` dan helper tetap di sana, tetapi tabel diambil dari `ReplicatedStorage.Shared.Tiers` (tipe statis dari seed agar tetap presisi di strict mode).
  3. `Economy.serialize` kini menyertakan field **`prices`** di payload `State` — harga aktual per tier saat ini (`Data.costOf(tierId, ownedOfTier)` untuk jumlah owned saat ini), dihitung lewat helper `ownedOfTier` yang juga dipakai `tryBuy`.
  4. `Hud.luau` menyimpan setiap baris ladder (`tierRows`) dan mengisi teks lewat `tierText`, yang membaca harga aktual dari `state.prices[tier.id]`; setiap event `State` me-refresh seluruh baris. Harga dasar (`tier.cost` dari modul bersama) dipakai sebagai fallback saja sebelum payload `State` pertama tiba.

---

## Build

`rojo` tersedia di mesin ini (Rojo 7.5.1, `/usr/local/bin/rojo`). Perintah yang dijalankan di root project:

```sh
rojo build --output game_fixed.rbxl
```

**Hasil: BERHASIL (exit code 0).** Output:

```
Building project 'Meme Reef: Tide of the Weird'
Built project to game_fixed.rbxl
```

`game_fixed.rbxl` (33.442 byte) adalah place biner (`<roblox!` magic) yang di-build dari `src/` + `default.project.json`. Verifikasi tambahan dengan reader place milik project (`vendor/makefun-roblox.ts`): 13/13 file `.luau` di `src/` (termasuk `SharedTiers.luau` baru) muncul sebagai script di place berdasarkan nama (`ServerScriptService.Server.SharedTiers` dst.), dan source coverage 100% — seluruh byte source script di place byte-identik dengan file di `src/`.
