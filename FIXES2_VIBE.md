# FIXES2_VIBE.md — Perbaikan 11 temuan Ringan (nomor 5–15) dari REVIEW_VIBE.md

Scope: hanya file di bawah `src/`. Temuan Sedang nomor 1–4 (PrimaryPart sky-junk,
leak PadSign/SafeZone, fallback slot >8 pemain, tier shared + harga aktual di HUD)
SUDAH diperbaiki sebelumnya dan tidak disentuh ulang — tidak ada regresi pada bagian itu.
`out/`, `game.rbxl`, `game_fixed.rbxl`, `REVIEW_VIBE.md`, dan `FIXES_VIBE.md` tidak diubah.
Semua file tetap memakai gaya Luau strict (`--!strict`).

---

## Daftar perbaikan

### 5) Debounce rebuild collector stack — `src/server/BasePad.luau`
- **Sebelum:** loop polling 0.5s memanggil `refreshCollector` setiap kali `#profile.owned`
  berubah; dengan cooldown beli 0.25s, beberapa pembelian cepat memicu rebuild
  (~80 part + emitter dibuat lalu di-`Destroy`) beruntun dalam <1 detik.
- **Sesudah:** ditambahkan bookkeeping `lastOwnedChangeAt` (waktu perubahan terakhir)
  dan `collectorOwnedCount` (jumlah owned yang sedang ditampilkan stack, disinkronkan
  di dalam `refreshCollector` dan di-reset di `release`). Loop hanya memanggil
  `refreshCollector` jika jumlah owned sudah **tenang ≥ `COLLECT_DEBOUNCE` (0.5s)**,
  jadi pembelian cepat menyatu menjadi satu rebuild.

### 6) `nearFountain` pakai jarak horizontal 2D — `src/server/World.luau`
- **Sebelum:** `(root.Position - World.fountainTop).Magnitude <= fountainBuyRadius + 6`
  (jarak 3D; karena `fountainTop` ~7.5 stud di atas tanah, radius horizontal efektif
  ≈ 18.5 stud, melebihi radius desain 14 — pemain bisa beli dari pinggir hub).
- **Sesudah:** `math.hypot(dx, dz) <= Data.TUNING.fountainBuyRadius` dengan `dx/dz`
  dihitung dari X/Z saja (Y diabaikan), sesuai radius desain.

### 7) Silinder `SafeZone` tidak diputar horizontal — `src/server/BasePad.luau`
- **Sebelum:** `zone.CFrame = padCFrame(slot) * CFrame.new(0, padRadius, 0) * CFrame.Angles(0, 0, math.pi/2)`
  — rotasi Z 90° membuat sumbu silinder menjadi horizontal.
- **Sesudah:** `* CFrame.Angles(0, 0, math.pi / 2)` dihapus, sumbu silinder kembali
  vertikal di atas pad.

### 8) Tag `CollectionService` yang tidak pernah dibaca dihapus — `src/server/World.luau`, `src/server/BasePad.luau`
- **Sebelum:** `CollectionService:AddTag(pad, "PadSlot")` dan `AddTag(fountain, "Fountain")`
  di World.luau, serta konstanta `SAFE_TAG = "SafeZone"` + `zone.Name = SAFE_TAG` di
  BasePad.luau — tidak ada `GetTagged` sama sekali di project.
- **Sesudah:** semua `AddTag` dan local `CollectionService` di World.luau dihapus;
  `SAFE_TAG` dihapus dan zone dinamai langsung `zone.Name = "SafeZone"`. Lookup
  (via `workspace:FindFirstChild("PadSlot{i}")`) tidak berubah.

### 9) `makeWall` tidak lagi meninggalkan kubus neon di origin — `src/server/TideCycle.luau`
- **Sebelum:** `makeWall()` membuat Part 1×1×1 neon (`Transparency = 0.25`) dan
  langsung di-parent ke workspace di (0,0,0); wall baru dibuat saat `start()` dan
  setiap akhir siklus, sehingga antar siklus ada kubus neon hidup di origin.
- **Sesudah:** `makeWall()` kini membuat part **tersembunyi dan tanpa parent**
  (`Transparency = 1`, `Size = Vector3.zero`, tidak di-parent). Wall baru dibuat
  hanya saat fase sweep dimulai, langsung di-size penuh, diberi `Transparency = 0.25`
  lalu di-parent; setelah animasi, wall di-`Destroy()` dan `TideCycle.wall = nil`.
  Antar siklus tidak ada instance wall sama sekali.

### 10) Hukuman `sweep()` saat wall menyentuh ring pad — `src/server/TideCycle.luau`
- **Sebelum:** `sweep()` dipanggil setelah animasi wall (r = 140 → 0, 30 × 0.12s ≈ 3.6s)
  selesai; pad berada di r = 46, sehingga pemain baru dihukum ~1.2s setelah wall
  secara visual melewati mereka.
- **Sesudah:** di dalam loop animasi, begitu `r <= World.RING_RADIUS` (sekitar step 21),
  `sweep()` dipanggil saat itu juga (`swept` di-set agar hanya sekali); ada safety net
  `if not swept then sweep()` setelah loop. Hukuman kini sinkron dengan wall visual
  menyentuh ring pad.

### 11) Nil guard / retry loop untuk `WaitForChild(..., 10)` di client — `src/client/Game.client.luau`, `src/client/Hud.luau`
- **Sebelum:** `releaseSpawn()` (Game.client.luau) dan `remotes()` (Hud.luau) memakai
  `WaitForChild("Remotes"/"State"/..., 10)` yang bisa mengembalikan `nil` saat server
  lambat start, lalu langsung di-index/di-cast (`nil:FireServer()` → error).
- **Sesudah:** kedua file memakai helper `waitForChild(parent, name)` yang melakukan
  **loop retry** sampai hasilnya benar-benar non-nil, plus `assert(IsA("RemoteEvent"))`
  sebelum dipakai. Tidak ada lagi indexing pada kemungkinan nil.

### 12) Koneksi `InputBegan` title screen di-`Disconnect` — `src/client/TitleScreen.luau`
- **Sebelum:** `UserInputService.InputBegan:Connect(...)` tidak pernah di-`Disconnect`;
  setelah dismiss, koneksi + closure-nya tetap hidup dan dievaluasi tiap input.
- **Sesudah:** koneksi disimpan di `local inputConn: RBXScriptConnection?` dan
  `dismiss()` memanggil `inputConn:Disconnect()` (lalu di-nil-kan) sebelum
  menghancurkan gui.

### 13) `CharacterAdded` menunggu `HumanoidRootPart`/`Humanoid` — `src/server/BasePad.luau`
- **Sebelum:** handler langsung memanggil `spawnCharacter` (yang `FindFirstChild`
  dan bisa return diam-diam jika root belum ada) serta `FindFirstChild("Humanoid")`
  untuk hook `Died` — pada frame pertama bisa terlewat sehingga pemain spawn di
  tengah hub, bukan di padnya.
- **Sesudah:** handler melakukan `char:WaitForChild("HumanoidRootPart")` dan
  `char:WaitForChild("Humanoid")` sebelum `spawnCharacter(player)` dan sebelum
  menghubungkan `humanoid.Died`.

### 14) Notifikasi `OrbTaken` memakai label tersendiri — `src/client/Hud.luau`
- **Sebelum:** handler `OrbTaken` menulis `"{takerName} grabbed a brainrot orb!"` ke
  `Hud.cashLabel.Text`, menimpa teks cash sampai `CashTick` berikutnya (≤1s).
- **Sesudah:** HUD membuat `NotifyLabel` terpisah (top-center, di bawah area klaxon),
  handler `OrbTaken` menulis ke label itu saja (lalu otomatis kosong setelah 3s via
  `task.delay` dengan token `notifySeq`); `cashLabel` tidak pernah disentuh lagi.

### 15) Dead code dihapus — `src/server/Economy.luau`, `src/server/data.luau`
- **Sebelum:** `Economy.broadcastAll()` (Economy.luau) dan `Data.tierByName()`
  (data.luau) tidak pernah dipanggil di mana pun.
- **Sesudah:** kedua fungsi dihapus penuh. Tidak ada pemanggil yang berubah
  ( diverifikasi dengan grep — tidak ada referensi tersisa).

---

## File yang berubah

| File | Temuan |
|------|--------|
| `src/server/BasePad.luau` | 5, 7, 8, 13 |
| `src/server/World.luau` | 6, 8 |
| `src/server/TideCycle.luau` | 9, 10 |
| `src/client/Game.client.luau` | 11 |
| `src/client/Hud.luau` | 11, 14 |
| `src/client/TitleScreen.luau` | 12 |
| `src/server/Economy.luau` | 15 |
| `src/server/data.luau` | 15 |

## Hasil build

Perintah yang dijalankan dari root project:

```
rojo build --output game_fixed2.rbxl
```

Output (Rojo 7.5.1):

```
Building project 'Meme Reef: Tide of the Weird'
Built project to game_fixed2.rbxl
```

**Status: BUILD BERHASIL** (exit code 0, file `game_fixed2.rbxl` terbentuk, ~35 KB).
Log build juga disimpan di `vibe_fix2.log`.

Catatan balance: hanya dua perubahan yang mengubah gameplay sesuai temuan 6 dan 10 —
radius beli fountain kini benar-benar horizontal 2D sejauh `fountainBuyRadius` (14),
dan hukuman sweep terjadi saat wall visual mencapai `RING_RADIUS` (46), bukan setelah
animasi selesai. Tidak ada perubahan balance lain.
