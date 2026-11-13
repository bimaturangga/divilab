# DiViLab – Flutter Technical Test

Aplikasi pemantauan kesehatan **DiViLab** (gula darah, kolesterol, asam urat, tekanan darah) yang dibangun ulang dengan Flutter berdasarkan desain Figma *DiVi Lab UI Design → Design Final* (Light & Dark Mode).

| Ketentuan soal | Implementasi |
|---|---|
| Aplikasi iOS dengan Flutter | Kode lintas platform (Android & iOS), tanpa dependency khusus Android |
| Running di iOS Emulator | Lihat [Catatan iOS](#catatan-ios). Dikembangkan di Windows → diuji di emulator Android, build iOS Simulator lewat GitHub Actions (macOS) |
| Database SQLite | `sqflite` – tabel `users`, `profiles`, `measurements`, `reminders`, `messages`, `strip_stock` |
| Get API eksternal (List User External) | Halaman **Ganti Akun** → `GET https://dummyjson.com/users` (+ `search`, `users/{id}`) |

---

## Fitur

**Halaman wajib**
- **Splash** – logo + progress, memeriksa sesi login.
- **Onboarding** – 5 slide, tombol *Lewati*, pilihan bahasa.
- **Login** – validasi, show/hide password, lupa password, tombol *Gunakan akun demo*.
- **Registrasi 3 langkah** – (1) email & password dengan aturan password live, (2) verifikasi OTP 6 digit + hitung mundur kirim ulang, (3) data personal (jenis kelamin, tanggal lahir, tinggi/berat, kode produksi + simulasi scan).
- **Dashboard (Beranda)** – profil aktif, poin/voucher/member, carousel perangkat, status koneksi, 4 hasil pengukuran terakhir, kartu bantuan CS.
- **Produk** – banner, rekomendasi, detail produk, pilihan toko.
- **Pengukuran** – pilih perangkat → hubungkan Bluetooth → pengukuran live (strip: gula darah GEN/AC/PC, kolesterol, asam urat; manset: tekanan darah) → dialog *Strip sudah dicabut* (hitung mundur 7 detik) → *Alat siap dipakai*. Sisa strip otomatis berkurang & bisa diedit.

**Halaman tambahan dari Flow Screen**
- Pengukuran manual + layar *Hasil tersimpan*.
- Detail pemeriksaan + gauge Rendah/Normal/Tinggi + tabel nilai rujukan.
- Laporan: kartu per jenis, riwayat (list/grafik), filter 7 hari / pilih periode (kalender rentang), filter GEN/AC/PC, hapus data dengan konfirmasi, export CSV ke clipboard.
- Notifikasi: pengingat (template / kustom, pilih hari & jam, aktif/nonaktif, geser untuk hapus) dan pesan otomatis (hasil di luar normal, strip hampir habis).
- Pengaturan: ubah profil, anggota keluarga, perangkat, bahasa, **Mode Gelap**, syarat & ketentuan, keluar akun.

**Fitur nilai tambah**
- 🤖 **Tanya Asisten** (tombol bulat di Beranda & Laporan) – chatbot yang membaca data pengukuran user dari SQLite sebagai konteks. Memakai Gemini API bila `GEMINI_API_KEY` diberikan; tanpa key tetap berjalan dengan mode offline berbasis aturan.
- 📈 **Prediksi** – regresi linear dari riwayat (min. 7 data) + grafik aktual vs prediksi + insight.
- 🌙 **Dark Mode** – semua warna dari token Figma (`DiVi Tokens`, mode Light/Dark).
- 👨‍👩‍👧 **Multi-profil** – ganti pasien/akun; akun dari API bisa dipakai lewat *Gunakan Akun Ini* (disimpan sebagai profil di SQLite).
- ✅ Unit test (rentang kesehatan, validasi, hash password, prediksi, model).

---

## Menjalankan di Windows (Android)

Prasyarat: Flutter SDK stable (Dart ≥ 3.5), Android Studio + emulator.

```powershell
# 1. Ekstrak project, buka folder di terminal
cd divilab

# 2. Setup otomatis: membuat folder android/ios, izin INTERNET, pub get, test
powershell -ExecutionPolicy Bypass -File .\setup.ps1

# 3. Jalankan di emulator
flutter run

# (opsional) Asisten AI online
flutter run --dart-define=GEMINI_API_KEY=API_KEY_ANDA
```

> Folder `android/` dan `ios/` tidak disertakan karena dibuat oleh `flutter create` sesuai versi Flutter Anda. Script setup juga menambahkan izin `INTERNET` di `AndroidManifest.xml` (wajib untuk build release agar API dummyjson & asisten berjalan).

**Akun demo** (otomatis dibuat saat database pertama kali dibuat, berisi riwayat 10 hari):

| Email | Password |
|---|---|
| `demo@divilab.id` | `Divilab@2026` |

## Catatan iOS

Build dan iOS Simulator membutuhkan macOS + Xcode, sehingga tidak bisa dijalankan dari Windows. Yang sudah disiapkan:

1. Semua package yang dipakai mendukung iOS (`sqflite`, `http`, `shared_preferences`, `provider`, `crypto`, `google_fonts`).
2. Workflow **GitHub Actions** `.github/workflows/build.yml` menjalankan `flutter build ios --simulator --no-codesign` di runner macOS dan mengunggah `Runner.app`. Push repo ke GitHub → tab *Actions* untuk bukti build iOS.
3. Di Mac: `./setup.sh`, lalu `open -a Simulator && flutter run`.

---

## Arsitektur

```
lib/
├── core/                 # tema (token Figma), rentang kesehatan, prediksi, util
│   ├── theme/            # AppPalette (Light/Dark), AppText, AppTheme
│   ├── health.dart       # jenis pengukuran, status, nilai rujukan
│   └── forecast.dart     # regresi linear untuk prediksi
├── data/
│   ├── db/               # AppDatabase (sqflite) + DemoSeeder
│   ├── models/           # AppUser, Profile, Measurement, Reminder, RemoteUser, ...
│   ├── repositories/     # AuthRepository, ProfileRepository, HealthRepository
│   └── services/         # DummyJsonService (API), AssistantService, DeviceSimulator, SessionStore
├── state/                # Provider: AppState, HealthStore, ShellController, DeviceController
└── ui/
    ├── widgets/          # komponen dari design system (Button, Input, Badge, Gauge, Chart, ...)
    └── screens/          # splash, onboarding, auth, home, measure, report, product, settings, accounts, assistant
```

- **State management:** `provider` (`ChangeNotifier`). `HealthStore` otomatis memuat ulang data saat profil aktif berganti (`ChangeNotifierProxyProvider`).
- **Repository pattern:** UI tidak menyentuh SQL secara langsung.
- **Keamanan:** password disimpan sebagai `SHA-256(salt + password)` dengan salt acak per user; API key dibaca dari `--dart-define`, tidak ditulis di kode.
- **Bluetooth:** perangkat fisik tidak tersedia, jadi koneksi & pembacaan disimulasikan oleh `DeviceSimulator` dengan antarmuka stream yang bisa diganti implementasi BLE (mis. `flutter_blue_plus`) tanpa mengubah UI.

### Skema database

| Tabel | Kolom utama |
|---|---|
| `users` | id, email (unik), password_hash, salt, name, gender, birth_date, height, weight, production_code |
| `profiles` | id, owner_id → users, name, relation, gender, age, color_index, remote_id (dummyjson) |
| `measurements` | id, profile_id → profiles, type, subtype (GEN/AC/PC), value, value2, pulse, source, device_name, note, measured_at |
| `reminders` | id, owner_id, title, types, days, hour, minute, enabled |
| `messages` | id, owner_id, title, body, created_at, read |
| `strip_stock` | owner_id, type, qty |

### API eksternal

- `GET /users?limit=20&skip=N` – daftar akun dengan infinite scroll.
- `GET /users/search?q=...` – pencarian (debounce 400 ms).
- `GET /users/{id}` – detail akun.
- Ditangani: loading skeleton, pull-to-refresh, error tanpa koneksi (+ tombol *Coba Lagi*), hasil kosong.

## Testing

```bash
flutter test
```

## Keterbatasan & rencana lanjut

- Notifikasi pengingat tersimpan di database tetapi belum dijadwalkan ke sistem (rencana: `flutter_local_notifications`).
- Bahasa Inggris, peta apotek, video tutorial, dan klaim garansi ditandai *segera hadir*.
- Tombol toko/WhatsApp menyalin teks ke clipboard (rencana: `url_launcher`).
