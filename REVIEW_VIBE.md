# REVIEW_VIBE.md — Code Review "Meme Reef: Tide of the Weird"

Scope: seluruh file Luau dalam project Rojo ini — 12 file di `src/server/` dan `src/client/` (`out/` adalah salinan byte-identik dari `src/`, diverifikasi via md5, sehingga tidak direview dua kali). `main.ts` adalah tooling build Node, bukan kode game, sehingga di luar scope. Tidak ada kode game yang diubah.

Daftar temuan di bawah ini diurutkan menurut severity.

---

## Temuan

### 1. Model sky-junk tidak punya `PrimaryPart`, tapi digerakkan dengan `PivotTo` tiap frame
- **File:** `src/server/World.luau` — baris 281–290 (`skyJunkPiece`, model dibuat tanpa `PrimaryPart`) dan baris 478–484 (loop `RunService.Heartbeat` memanggil `model:GetPivot()` / `model:PivotTo(...)` setiap frame untuk 14 model).
- **Severity:** Sedang
- **Penjelasan:** `buildBrainrot` mengeset `PrimaryPart` (baris 169), tetapi `skyJunkPiece` tidak. `GetPivot` pada model tanpa `PrimaryPart` mengembalikan pivot default (identity di origin), sehingga `PivotTo` bisa memindahkan sky-junk ke sekitar origin / tidak menggerakkannya sesuai desain — dan pada beberapa versi engine, `PivotTo` tanpa `PrimaryPart` melempar error sehingga terjadi **error setiap frame** di konsol server (loop Heartbeat tidak mati saat error, hanya spam).
- **Saran fix:** di `skyJunkPiece`, setelah `p.Parent = model`, tambahkan `model.PrimaryPart = p`.

### 2. `BasePad.release()` tidak menghancurkan `PadSign` dan `SafeZone` → instance leak
- **File:** `src/server/BasePad.luau` — baris 153–167 (`release` hanya me-reset nama/warna pad); part `PadSign` + `SurfaceGui` dibuat di baris 36–56 dan silinder `SafeZone` di baris 60–70 oleh `stylePad`, tapi tidak pernah di-`Destroy()`.
- **Severity:** Sedang
- **Penjelasan:** setiap pemain yang leave (atau rejoin) meninggalkan 2 part + 1 SurfaceGui di workspace. Pada server yang lama dengan banyak join/leave, instance menumpuk tanpa batas (memory + lookup cost).
- **Saran fix:** simpan referensi `sign` dan `zone` per pemain (mis. `BasePad.padDecor[player] = { sign = sign, zone = zone }`) dan panggil `Destroy()` keduanya di `release()`.

### 3. Fallback penentuan slot bisa menimpa slot yang sudah dimiliki (>8 pemain)
- **File:** `src/server/BasePad.luau` — baris 134–143 (`BasePad.assign`): jika semua slot penuh, `slot = ((#Players:GetPlayers() - 1) % World.PAD_SLOTS) + 1` tanpa memeriksa `ownerOfSlot`, lalu `slotOfSlotFix` menimpa `ownerOfSlot[slot]`.
- **Severity:** Sedang
- **Penjelasan:** dengan lebih dari 8 pemain, satu slot bisa diklaim dua pemain sekaligus; `ownerOfSlot` menunjuk pemain baru sementara `slotOfPlayer` pemain lama masih menunjuk slot yang sama — data kepemilikan korup dan pad bisa di-styling ulang/di-reset oleh pemain yang bukan pemilik.
- **Saran fix:** jika semua slot penuh, jangan timpa: biarkan `slot = nil` (pemain spawn di gate, sudah ditangani `spawnCharacter`), atau pilih slot berdasarkan `player.UserId % PAD_SLOTS + 1` hanya jika slot itu benar-benar kosong.

### 4. Data tier diduplikasi manual di client; HUD menampilkan harga statis, bukan harga aktual
- **File:** `src/client/Game.client.luau` — baris 19–30 (tabel `TIERS` hasil copy manual dari server); `src/client/Hud.luau` — baris 74 (menampilkan `${tier.cost}`); bandingkan `src/server/data.luau` — baris 128–135 (`Data.costOf` = `base * 1.6^ownedCount`).
- **Severity:** Sedang
- **Penjelasan:** dua risiko: (a) drift — jika ada perubahan balance di `data.luau`, HUD client menampilkan data basi; (b) UI menyesatkan — harga yang ditampilkan adalah harga dasar, padahal harga beli berikutnya naik 1.6× setiap copy yang dimiliki, sehingga pemain tidak tahu harga sebenarnya.
- **Saran fix:** pindahkan tabel tier/mutasi ke satu modul bersama di `ReplicatedStorage` yang di-`require` oleh server dan client; kirim harga aktual per tier (hasil `costOf` untuk jumlah owned saat ini) di dalam payload `State` dari server, lalu tampilkan dari sana di HUD.

### 5. Rebuild collector stack bisa churn beruntun saat pembelian cepat
- **File:** `src/server/BasePad.luau` — baris 254–271 (loop 0.5s memanggil `refreshCollector` setiap kali `#profile.owned` berubah); `refreshCollector` (baris 81–127) membangun hingga 10 model (≈80 part + `ParticleEmitter`) lalu `Destroy()` yang lama.
- **Severity:** Ringan
- **Penjelasan:** dengan cooldown beli 0.25s (`Economy.luau` baris 117), pemain bisa memicu beberapa rebuild dalam <1 detik; membuat/menghancurkan ~80 part + emitter berulang kali adalah churn yang tidak perlu (walau masih terbatas).
- **Saran fix:** debounce — catat waktu perubahan terakhir per pemain dan baru rebuild jika sudah tenang ≥0.3–0.5s, atau panggil `refreshCollector` langsung dari `Economy.tryBuy`/orb pickup sebagai ganti polling.

### 6. `nearFountain` terlalu longgar — bisa beli dari pinggir hub
- **File:** `src/server/World.luau` — baris 488–495: jarak 3D ke `World.fountainTop` (0, 9.5, 0) dengan radius `fountainBuyRadius + 6` = 20.
- **Severity:** Ringan
- **Penjelasan:** karena titik acuannya 7.5 stud di atas tanah, jangkauan horizontal efektif ≈ √(20² − 7.5²) ≈ 18.5 stud dari poros fountain — melebihi radius desain `fountainBuyRadius = 14`, sehingga pemain bisa membeli dari pinggir hub, bukan harus di fountain.
- **Saran fix:** hitung jarak horizontal 2D saja: `math.hypot(root.Position.X, root.Position.Z) <= Data.TUNING.fountainBuyRadius` (abaikan Y).

### 7. Silinder `SafeZone` diputar sehingga sumbunya horizontal
- **File:** `src/server/BasePad.luau` — baris 60–70, khususnya baris 68: `zone.CFrame = padCFrame(slot) * CFrame.new(0, padRadius, 0) * CFrame.Angles(0, 0, math.pi / 2)`.
- **Severity:** Ringan
- **Penjelasan:** rotasi Z 90° membuat sumbu silinder (sumbu Y lokal) menjadi horizontal; safe-zone yang benar harus vertikal di atas pad. Saat ini tidak berdampak gameplay karena `isOnOwnPad` (baris 172–188) doing manual dengan matematika 2D+dy, tetapi jika nanti zona dipakai via `GetTouchingParts`/fisika, hasilnya salah.
- **Saran fix:** hapus `* CFrame.Angles(0, 0, math.pi / 2)` agar sumbu silinder vertikal.

### 8. Tag `CollectionService` ditambahkan tapi tidak pernah dibaca (dead code)
- **File:** `src/server/World.luau` — baris 326 (`AddTag(pad, "PadSlot")`) dan 349 (`AddTag(fountain, "Fountain")`); `src/server/BasePad.luau` — baris 19 (`SAFE_TAG = "SafeZone"`) dan 62 (`zone.Name = SAFE_TAG`).
- **Severity:** Ringan
- **Penjelasan:** tidak ada pemanggilan `GetTagged`/`GetTaggedWith` di seluruh project; pad justru dicari dengan `workspace:FindFirstChild("PadSlot{i}")` (`World.luau` baris 327, `BasePad.luau` baris 30, 162). Tag yang tidak dipakai hanya menambah noise.
- **Saran fix:** pakai `CollectionService:GetTagged("PadSlot")` untuk lookup pad, atau hapus semua `AddTag`/`SAFE_TAG`.

### 9. `makeWall()` meninggalkan kubus neon 1×1×1 di origin antar siklus
- **File:** `src/server/TideCycle.luau` — baris 23–33 (`makeWall` membuat Part default 1×1×1 di (0,0,0) yang baru di-resize saat sweep), baris 143 (dipanggil saat `start()`), baris 179 (dipanggil lagi setelah `wall:Destroy()` tiap siklus).
- **Severity:** Ringan
- **Penjelasan:** antara siklus, ada part neon biru 1×1×1 dengan `Transparency = 0.25` yang melayang di (0,0,0) (di dalam hub — saat ini tidak terlihat, tapi tetap instance hidup yang sia-sia), dan tiap siklus membuat wall baru yang menganggur sampai sweep berikutnya.
- **Saran fix:** buat wall hanya saat fase sweep dimulai (atau set `wall.Transparency = 1` / `Size = Vector3.zero` selama fase calm).

### 10. Hukuman `sweep()` tidak sinkron dengan wall menyentuh reef
- **File:** `src/server/TideCycle.luau` — baris 165–181: `setPhase("sweep", 0)` lalu animasi wall dari r=140 ke r=0 (30 × `task.wait(0.12)` ≈ 3.6s), dan `sweep()` baru dipanggil di baris 181 setelah animasi selesai.
- **Severity:** Ringan
- **Penjelasan:** ring pad berada di r=46, sehingga wall visual melewati pemain sekitar t≈2.4s, tetapi pemain baru dihukum (kehilangan 2 brainrot terlangka) saat wall sudah mencapai r=0 (t≈3.6s). Pemain yang kabur sesaat sebelum itu lolos walau secara visual sudah "terSapu".
- **Saran fix:** panggil `sweep()` saat radius wall mencapai `World.RING_RADIUS` (sekitar step 20), bukan setelah animasi selesai.

### 11. `WaitForChild(..., 10)` di client bisa mengembalikan `nil` lalu di-index → error
- **File:** `src/client/Game.client.luau` — baris 36–38 (`remoteFolder:WaitForChild("State", 10)` lalu `state:FireServer()`); `src/client/Hud.luau` — baris 22–27 (`remotes()` melakukan `WaitForChild` ber-timeout lalu di-cast `:: RemoteEvent`).
- **Severity:** Ringan
- **Penjelasan:** `WaitForChild` dengan timeout mengembalikan `nil` jika server belum membuat `Remotes` dalam 10 detik (mis. server lambat start); `nil:WaitForChild(...)` / `nil:FireServer()` akan error di LocalScript. Cast `:: RemoteEvent` tidak melindungi saat runtime.
- **Saran fix:** periksa hasilnya (`if folder == nil then retry/loop end`) atau gunakan pola "server-ready": server membuat folder Remotes di awal require (sudah terjadi di `Economy.luau` baris 46), dan client cukup melakukan loop retry sampai tidak nil.

### 12. Koneksi `InputBegan` TitleScreen tidak di-`Disconnect` setelah dismiss
- **File:** `src/client/TitleScreen.luau` — baris 99–106 (koneksi `UserInputService.InputBegan`); `dismiss()` di baris 87–96 hanya menghancurkan gui.
- **Severity:** Ringan
- **Penjelasan:** setelah title screen ditutup, handler input tetap terhubung selamanya (tidak fatal karena ada guard `dismissed`, tapi koneksi dan closure-nya leak dan tetap dievaluasi tiap input).
- **Saran fix:** simpan koneksi ke variabel (`local inputConn = UserInputService.InputBegan:Connect(...)`) dan panggil `inputConn:Disconnect()` di dalam `dismiss()`.

### 13. `CharacterAdded` bisa berjalan sebelum `HumanoidRootPart`/`Humanoid` ada
- **File:** `src/server/BasePad.luau` — baris 224–236: handler `CharacterAdded` langsung memanggil `BasePad.spawnCharacter(player)` (baris 197–199 melakukan `FindFirstChild("HumanoidRootPart")` yang bisa `nil` pada frame pertama) dan `char:FindFirstChild("Humanoid")` (baris 226).
- **Severity:** Ringan
- **Penjelasan:** jika `HumanoidRootPart` belum ada saat `CharacterAdded` terpanggil, `spawnCharacter` return diam-diam dan pemain bisa muncul di `SpawnLocation` default (tengah hub), bukan di padnya; koneksi `Humanoid.Died` juga bisa terlewat.
- **Saran fix:** di dalam handler `CharacterAdded`, pakai `local root = char:WaitForChild("HumanoidRootPart")` dan `local humanoid = char:WaitForChild("Humanoid")` sebelum memposisikan karakter.

### 14. Notifikasi `OrbTaken` menimpa teks cash HUD
- **File:** `src/client/Hud.luau` — baris 170–173: handler `OrbTaken` mengeset `Hud.cashLabel.Text` menjadi pesan "{takerName} grabbed a brainrot orb!".
- **Severity:** Ringan
- **Penjelasan:** teks cash (informasi utama) tertimpa pesan dan baru pulih saat `CashTick` berikutnya (≤1 detik). Kosmetik, tetapi membingungkan saat event terjadi.
- **Saran fix:** buat `TextLabel` terpisah untuk notifikasi (mis. di bawah banner klaxon) dan jangan menimpa `cashLabel`.

### 15. Dead code: `Economy.broadcastAll` dan `Data.tierByName` tidak pernah dipakai
- **File:** `src/server/Economy.luau` — baris 179–183 (`Economy.broadcastAll`); `src/server/data.luau` — baris 93–100 (`Data.tierByName`).
- **Severity:** Ringan
- **Penjelasan:** kedua fungsi tidak dipanggil di titik mana pun dalam project; hanya membebani pembacaan kode.
- **Saran fix:** hapus, atau pakai (`broadcastAll` bisa dipakai saat `TideCycle` mem-broadcast state global).

---

## Catatan positif (hal yang sudah benar)

- **Validasi server-side atas semua RemoteEvent sudah solid:** `BuyBrainrot` memvalidasi tipe/range tier id, cooldown 0.25s per pemain, jarak ke fountain, cap per tier, dan saldo (`Economy.luau` baris 110–147); `Rebirth` divalidasi dari jumlah owned; orb pickup divalidasi server-side via jarak. Server tidak pernah mempercayai angka mentah dari client.
- **Boundary client/server benar:** dengan `CharacterAutoLoads = false`, server yang memanggil `player:LoadCharacter()` (`BasePad.luau` baris 223, 232, 245) — client tidak memanggilnya (mencegah join soft-lock); RemoteEvent dibuat di server di `ReplicatedStorage.Remotes`.
- **Tidak ditemukan API deprecated** pada kode yang dibaca (menggunakan `task.wait`, `PivotTo`, `Enum.PartType`, `task.spawn` — semua masih berlaku).
- Semua loop berjalan terjadwal (`task.wait` di dalamnya), tidak ada loop tanpa yield yang bisa membekukan thread.

---

## Ringkasan

| Severity | Jumlah |
|----------|--------|
| Kritis   | 0      |
| Sedang   | 4      |
| Ringan   | 11     |
| **Total**| **15** |

## Verdict kualitas kode (3 kalimat)

Kode ini secara keseluruhan rapi dan aman: Luau `--!strict` dipakai konsisten, pemisahan client/server benar, dan semua input RemoteEvent dari client divalidasi dengan baik di server sehingga tidak ditemukan celah cheat yang jelas maupun API deprecated. Masalah terkonsentrasi pada beberapa titik yang perlu diperbaiki sebelum publish: animasi sky-junk kemungkinan rusak/error tiap frame karena model tanpa `PrimaryPart`, part dekorasi pad bocor saat pemain keluar, penentuan slot bisa korup ketika jumlah pemain melebihi 8, dan data tier yang diduplikasi di client berisiko drift serta menampilkan harga yang salah di HUD. Jika 4 temuan Sedang itu diperbaiki, kode ini sudah cukup solid untuk game jam skala kecil ini.
