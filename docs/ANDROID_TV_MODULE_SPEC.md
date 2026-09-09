# Spesifikasi Development Modul Android TV AkademiHub

Status: **implementation contract**  
Target: `/Users/bodo/www/akademihub_repo/akademihub_mob`  
Backend: `/Users/bodo/www/akademihub_repo/sekolah/src`  
Versi: 1.0 — 5 September 2026

Dokumen ini wajib diperlakukan AI coding agent sebagai kontrak implementasi. Ikuti konvensi kode aktual bila berbeda. Catat deviasi. Jangan merusak fitur handset.

## 1. Baseline

- Flutter/Dart `^3.11.4`; BLoC/Equatable; Dio; GetIt; GoRouter.
- JWT mobile tersimpan di `flutter_secure_storage`, terikat origin API.
- Manifest belum mendukung Leanback. UI belum memiliki primitive fokus D-pad.
- Backend belum memiliki endpoint pairing/signage TV. Implementasikan backend sebelum wiring production.

## 2. Scope MVP

### Wajib

1. **Signage publik:** jam, identitas sekolah, pengumuman aktif, agenda, jadwal hari ini, presensi agregat.
2. **Display kelas:** identitas kelas, pelajaran aktif/berikutnya, agenda, pengumuman, materi yang ditandai layak tayang.
3. **Pairing:** TV menampilkan kode; admin/guru mengotorisasi via backend/web. Password personal tidak diketik di TV.
4. **Remote:** seluruh aksi memakai D-pad, Select/Enter, Back.
5. **Offline:** snapshot terakhir maksimal 24 jam dengan label waktu sinkronisasi.

### Di luar MVP

- Presensi GPS/selfie, data individual siswa, nilai, rapor, keuangan, BK/EWS personal.
- Pembayaran, ujian, tugas, chat, upload, edit.
- Weather, QR, WebSocket, autoplay video, analytics, autostart boot, device-owner kiosk.

TV adalah layar bersama. Seluruh data bersifat publik/agregat dan seluruh fitur read-only.

## 3. Prinsip Wajib

1. Backend memfilter tenant, role, kelas, visibilitas, tanggal aktif.
2. Pakai satu endpoint snapshot TV; jangan agregasi banyak endpoint mobile di client.
3. Token perangkat hanya scope `tv:read`; jangan mewarisi permission approver.
4. Deteksi TV via Android `UiModeManager`, bukan ukuran/aspect ratio.
5. Satu APK, dua flow: handset tetap; TV mulai `/tv/bootstrap`.
6. Tanpa dependency baru untuk MVP. Pairing code teks cukup; QR ditunda.
7. Semua Timer, subscription, observer, controller, FocusNode wajib di-dispose.

## 4. UX TV

- Acuan 1920×1080 landscape; wajib usable 1280×720 dan 3840×2160.
- Safe margin minimum 48 logical px; hormati `MediaQuery.padding`.
- Body minimum 24sp, label 22sp, judul 36sp, jam 56sp; kontras minimum 4.5:1.
- Elemen interaktif memakai `FocusableActionDetector`/`Focus` + `InkWell`.
- Focus ring minimum 3px; scale fokus maksimum 1.04.
- Fokus kiri-ke-kanan, atas-ke-bawah. Fokus awal pada aksi utama.
- Back menutup detail/dialog; pada root membuka konfirmasi keluar.
- Carousel pause saat interaksi; lanjut setelah idle 30 detik.
- Slide default: overview, schedule, announcements, calendar, attendance.
- Slide kosong tidak dibuat. Durasi server di-clamp 10–120 detik; default 15.
- State wajib: loading, pairing, offline-cache, offline-empty/retry, empty, session revoked.

## 5. Runtime

```text
main.dart
  TvPlatformService.isTelevision()
    false -> flow mobile saat ini
    true  -> /tv/bootstrap
               credential ada -> GET /tv/snapshot -> /tv/signage
               kosong/401 -> POST /tv/pairing/sessions -> poll -> simpan token
```

`TvAuthBloc` menangani pairing/session. `TvSignageBloc` menangani snapshot/cache/refresh. Jangan membuat classroom bloc; classroom adalah konfigurasi snapshot dan susunan slide.

## 6. File

```text
android/app/src/main/AndroidManifest.xml                         [ubah]
android/app/src/main/res/drawable-nodpi/tv_banner.png            [buat]
android/app/src/main/kotlin/.../MainActivity.kt                  [ubah]
lib/main.dart                                                    [ubah]
lib/core/di/injection.dart                                       [ubah]
lib/core/router/app_router.dart                                  [ubah]
lib/core/platform/tv_platform_service.dart                       [buat]
lib/features/tv/data/datasources/tv_remote_datasource.dart       [buat]
lib/features/tv/data/models/tv_pairing_model.dart                [buat]
lib/features/tv/data/models/tv_snapshot_model.dart               [buat]
lib/features/tv/data/repositories/tv_repository_impl.dart        [buat]
lib/features/tv/data/storage/tv_storage.dart                     [buat]
lib/features/tv/domain/entities/tv_pairing_session.dart          [buat]
lib/features/tv/domain/entities/tv_snapshot.dart                 [buat]
lib/features/tv/domain/repositories/tv_repository.dart           [buat]
lib/features/tv/presentation/bloc/tv_auth_{bloc,event,state}.dart
lib/features/tv/presentation/bloc/tv_signage_{bloc,event,state}.dart
lib/features/tv/presentation/pages/tv_bootstrap_page.dart
lib/features/tv/presentation/pages/tv_pairing_page.dart
lib/features/tv/presentation/pages/tv_signage_page.dart
lib/features/tv/presentation/widgets/tv_focusable.dart
lib/features/tv/presentation/widgets/tv_shell.dart
lib/features/tv/presentation/widgets/tv_{overview,schedule,announcements,calendar,attendance}_slide.dart
test/core/platform/tv_platform_service_test.dart
test/features/tv/data/models/tv_models_test.dart
test/features/tv/data/datasources/tv_remote_datasource_test.dart
test/features/tv/presentation/bloc/tv_auth_bloc_test.dart
test/features/tv/presentation/bloc/tv_signage_bloc_test.dart
test/features/tv/presentation/pages/tv_pairing_page_test.dart
test/features/tv/presentation/pages/tv_signage_page_test.dart
```

Model kecil boleh digabung per layer. Mapping JSON manual cukup; jangan menambah abstraksi/codegen tanpa kebutuhan aktual.

## 7. Android Native

Tambahkan tanpa menghapus permission mobile:

```xml
<uses-feature android:name="android.hardware.touchscreen" android:required="false" />
<uses-feature android:name="android.software.leanback" android:required="false" />
```

Tambahkan `android:banner="@drawable/tv_banner"` pada application dan kategori berikut pada intent-filter MAIN yang ada:

```xml
<category android:name="android.intent.category.LEANBACK_LAUNCHER"/>
```

Pertahankan `android.intent.category.LAUNCHER`. Banner PNG wajib 320×180, valid, memakai brand aktual, tersimpan `drawable-nodpi`.

Deteksi platform memakai `MethodChannel('id.akademihub/device')`, method `isTelevision`. Handler Kotlin mengembalikan:

```kotlin
getSystemService(UiModeManager::class.java).currentModeType ==
    Configuration.UI_MODE_TYPE_TELEVISION
```

Non-Android mengembalikan false. Panggil sekali sebelum `runApp`, inject hasil immutable. Saat TV:

```dart
await SystemChrome.setPreferredOrientations([
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
]);
await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
```

Pulihkan immersive mode saat resumed. Handset mempertahankan perilaku sekarang.

## 8. Kontrak Backend

Prefix `/api/v1/tv`. Envelope: `{"success":true,"data":...}`. Jangan membuat endpoint client sebelum endpoint backend dan feature test tersedia.

### 8.1 Create pairing

`POST /api/v1/tv/pairing/sessions` — public, rate limited.

```json
{
  "installation_id":"UUID-v4",
  "device_name":"Android TV",
  "app_version":"1.0.0+1"
}
```

Response 201:

```json
{
  "success":true,
  "data":{
    "session_id":"UUID",
    "user_code":"AB7K9Q",
    "expires_at":"2026-09-05T14:15:00Z",
    "poll_interval_seconds":5,
    "verification_url":"https://app.akademihub.id/tv-pair"
  }
}
```

- Code 6 karakter uppercase tanpa `0O1IL`; expiry 10 menit.
- Rate limit: 5/IP/menit dan 10/installation/jam.
- Simpan hash code/installation; jangan kembalikan token di sini.

### 8.2 Poll pairing

`GET /api/v1/tv/pairing/sessions/{session_id}`, header `X-TV-Installation-ID` wajib cocok.

Pending:

```json
{"success":true,"data":{"status":"pending","expires_at":"2026-09-05T14:15:00Z"}}
```

Approved:

```json
{
  "success":true,
  "data":{
    "status":"approved",
    "device_token":"opaque-random-token",
    "device":{"id":42,"name":"TV Lobby Utama","mode":"signage"}
  }
}
```

Status: `pending|approved|denied|expired`. Token hanya dapat diambil sekali. Poll terlalu cepat menghasilkan 429.

### 8.3 Approval

`POST /api/v1/tv/pairing/approve` — JWT user + permission `tv-device.manage`.

```json
{"user_code":"AB7K9Q","name":"TV Lobby Utama","mode":"signage","class_id":null}
```

- `mode`: `signage|classroom`; `class_id` wajib untuk classroom.
- Tenant berasal dari session server, bukan request.
- Validasi class tenant. Audit approver, device, tenant, waktu, IP.

### 8.4 Snapshot

`GET /api/v1/tv/snapshot` — bearer device token dengan scope `tv:read`.

```json
{
  "success":true,
  "data":{
    "generated_at":"2026-09-05T13:10:00Z",
    "refresh_after_seconds":60,
    "device":{"id":42,"name":"TV Lobby Utama","mode":"signage"},
    "school":{"name":"SMA Contoh","logo_url":"https://.../logo.png","timezone":"Asia/Jakarta"},
    "settings":{"slide_duration_seconds":15,"show_attendance":true},
    "schedule":[{"id":1,"subject":"Matematika","teacher":"Budi","class_name":"X-A","starts_at":"07:00","ends_at":"08:30","room":"R101"}],
    "announcements":[{"id":9,"title":"Upacara","body":"Senin pukul 07.00","image_url":null,"starts_at":"2026-09-01T00:00:00Z","ends_at":"2026-09-08T00:00:00Z","priority":"normal"}],
    "calendar":[{"id":3,"title":"PTS","starts_at":"2026-09-12T00:00:00+07:00","ends_at":"2026-09-16T23:59:59+07:00","all_day":true}],
    "attendance":{"present":540,"late":14,"absent":21,"total":575}
  }
}
```

- Maksimum 6 item per list.
- Announcement hanya aktif dan bertanda public-display.
- Attendance agregat. Dilarang mengirim nama/NIS/foto/ID siswa.
- Classroom difilter ke class perangkat.
- Refresh 30–900 detik. Dukung ETag/If-None-Match dan 304.
- 401 token invalid/revoked; 403 disabled; 429/5xx retry dengan cache.

### 8.5 Unpair dan storage backend

- `DELETE /api/v1/tv/devices/current`: self-revoke.
- `DELETE /api/v1/tv/devices/{id}`: admin + `tv-device.manage`.
- Tabel `tv_devices`: tenant FK, class FK nullable, name, mode, installation hash unique, token hash, last_seen, paired_by/at, revoked_at, settings JSON, timestamps.
- Tabel `tv_pairing_sessions`: UUID, installation hash, code hash/index, expiry, approved device nullable, consumed_at, attempts, timestamps.
- Token minimal 256-bit CSPRNG, hash SHA-256/HMAC at rest, plaintext sekali. Semua query tenant-scoped.

### 8.6 Backend wajib dibuat bila belum tersedia

AI agent wajib menjalankan audit berikut sebelum mengerjakan Flutter:

```bash
cd /Users/bodo/www/akademihub_repo/sekolah/src
php artisan route:list --path=api/v1/tv
find app database tests -iname '*Tv*' -o -iname '*tv*'
```

Jika route, model, migration, service, middleware, atau test TV belum ada, statusnya **backend unavailable**. Agent dilarang melewati Fase A, membuat mock production, atau menghubungkan client ke endpoint lain. Agent wajib membuat backend lengkap dahulu, menjalankan test, baru mengerjakan client.

### 8.7 Lokasi file backend exact

```text
sekolah/src/routes/api.php                                      [ubah]
sekolah/src/bootstrap/app.php                                  [ubah: alias middleware]
sekolah/src/app/Providers/AppServiceProvider.php                [ubah: rate limiter, jika pola aktual di sini]
sekolah/src/app/Http/Controllers/Api/V1/TvController.php        [buat]
sekolah/src/app/Http/Middleware/TvDeviceMiddleware.php          [buat]
sekolah/src/app/Http/Requests/Api/V1/CreateTvPairingRequest.php [buat]
sekolah/src/app/Http/Requests/Api/V1/ApproveTvPairingRequest.php[buat]
sekolah/src/app/Models/System/SysTvDevice.php                   [buat]
sekolah/src/app/Models/System/SysTvPairingSession.php           [buat]
sekolah/src/app/Services/TvService.php                          [buat]
sekolah/src/database/migrations/global/<timestamp>_create_sys_tv_devices_table.php
sekolah/src/database/migrations/global/<timestamp>_create_sys_tv_pairing_sessions_table.php
sekolah/src/database/seeders/RbacSeeder.php                     [ubah]
sekolah/src/tests/Feature/Tv/TvPairingTest.php                  [buat]
sekolah/src/tests/Feature/Tv/TvSnapshotTest.php                 [buat]
sekolah/src/tests/Feature/Tv/TvTenantIsolationTest.php          [buat]
```

Gunakan nama `sys_tv_devices` dan `sys_tv_pairing_sessions`, mengikuti model system repo. Jangan membuat tabel ini dalam migration tenant: pairing terjadi sebelum tenant diketahui dan registry harus dapat dicari dari token perangkat. Kedua tabel berada pada schema/global connection yang sama dengan `mst_sekolah` dan `sys_users`.

Kedua model wajib memakai trait existing `UsesControlPlaneConnection`, sama seperti `MstSekolah` dan `SysUser`. Semua lookup pairing/device harus eksplisit berjalan pada control-plane connection, walaupun request sedang berada dalam transaksi tenant. Jangan mengandalkan `search_path` untuk menemukan tabel global.

### 8.8 Schema migration wajib

`sys_tv_devices`:

| Kolom | Tipe/constraint |
|---|---|
| `id` | big primary key |
| `uuid` | UUID unique |
| `mst_sekolah_id` | FK `mst_sekolah.id`, restrict delete, indexed |
| `mst_kelas_id` | unsigned bigint nullable; ID tenant, bukan cross-schema FK |
| `name` | string(100) |
| `mode` | string(20), app validation `signage|classroom` |
| `installation_hash` | char(64) unique |
| `token_hash` | char(64) unique |
| `settings` | JSON nullable |
| `last_seen_at` | timestampTz nullable |
| `paired_by` | FK `sys_users.id`, nullOnDelete |
| `paired_at` | timestampTz |
| `revoked_at` | timestampTz nullable, indexed |
| timestamps | Laravel timestamps |

`sys_tv_pairing_sessions`:

| Kolom | Tipe/constraint |
|---|---|
| `id` | UUID primary key |
| `installation_hash` | char(64), indexed |
| `user_code_hash` | char(64) unique |
| `device_name` | string(100) |
| `app_version` | string(30) |
| `status` | string(20), default `pending`, indexed |
| `expires_at` | timestampTz, indexed |
| `approved_device_id` | FK device nullable, nullOnDelete |
| `approved_by` | FK user nullable, nullOnDelete |
| `approved_at` | timestampTz nullable |
| `consumed_at` | timestampTz nullable |
| `poll_after` | timestampTz nullable |
| `attempts` | unsigned small integer default 0 |
| timestamps | Laravel timestamps |

Jangan menyimpan plaintext `installation_id`, `user_code`, atau device token. Hash canonical:

```php
hash_hmac('sha256', $value, (string) config('app.key'))
```

Raw token dibuat `bin2hex(random_bytes(32))`. Perubahan schema wajib reversible di `down()` dan kompatibel PostgreSQL serta SQLite test.

### 8.9 Middleware autentikasi device dan tenant context

Route snapshot/self-unpair tidak memakai `auth:api`; gunakan middleware baru `tv.device`. Algoritma wajib:

1. Ambil bearer token; kosong menghasilkan 401.
2. Hash token dengan fungsi canonical; query `SysTvDevice` global.
3. Gunakan perbandingan/query hash; jangan scan seluruh row atau decrypt token.
4. Tolak device tidak ditemukan/revoked dengan 401; disabled dengan 403 bila field disabled kelak ditambah.
5. Resolve `MstSekolah` aktif dari `mst_sekolah_id`.
6. Load relasi `databaseNode` dan aktifkan koneksi memakai `TenantConnectionManager::activate($sekolah)`. Ini wajib mendukung tenant pada database node berbeda; jangan berasumsi seluruh tenant berada pada koneksi default.
7. Attach device ke request attribute `tv_device`; jangan mengubah guard user.
8. Ikuti boundary existing `TenantMiddleware`: `DB::beginTransaction()`, PostgreSQL `SELECT set_config('search_path', ?, true)`, `TenantManager::set($sekolah)`, lalu commit/rollback. Pada SQLite test, lewati `set_config` seperti middleware existing.
9. Update `last_seen_at` maksimal sekali per 5 menit agar polling snapshot tidak menulis DB tiap request.
10. Dalam `finally`, selalu panggil `TenantManager::flush()` dan `TenantConnectionManager::deactivate()`. `SET LOCAL` pulih saat transaksi selesai; jangan menjalankan `SET search_path` session-level.

Tambahkan alias di `bootstrap/app.php`:

```php
'tv.device' => TvDeviceMiddleware::class,
```

Test wajib membuktikan koneksi kembali ke schema default setelah request berhasil dan gagal.

### 8.10 Route placement dan middleware exact

Di dalam existing `Route::prefix('v1')`:

```php
Route::prefix('tv')->group(function () {
    Route::post('pairing/sessions', [TvController::class, 'createPairing'])
        ->middleware('throttle:tv-pair-create');
    Route::get('pairing/sessions/{session}', [TvController::class, 'pairingStatus'])
        ->middleware('throttle:tv-pair-poll');

    Route::middleware(['auth:api', 'tenant'])->group(function () {
        Route::post('pairing/approve', [TvController::class, 'approvePairing'])
            ->middleware(PermissionMiddleware::class.':tv-device.manage');
    });

    Route::middleware('tv.device')->group(function () {
        Route::get('snapshot', [TvController::class, 'snapshot']);
        Route::delete('devices/current', [TvController::class, 'unpairCurrent']);
    });

    Route::middleware(['auth:api', 'tenant'])->group(function () {
        Route::delete('devices/{device}', [TvController::class, 'revokeDevice'])
            ->whereNumber('device')
            ->middleware(PermissionMiddleware::class.':tv-device.manage');
    });
});
```

Route static `devices/current` wajib dideklarasikan sebelum dynamic route dan dynamic route wajib `whereNumber('device')`. Beri nama seluruh route mengikuti pola `api.v1.tv.*`. Daftarkan named rate limiter menggunakan cache atomic/Redis pada production. Poll limiter harus mempertimbangkan session + installation, bukan IP saja. Response 429 wajib memiliki `Retry-After`.

Approval/revoke dengan `auth:api,tenant` mengikuti aturan tenant existing: user sekolah selalu memakai `mst_sekolah_id` miliknya; superadmin wajib memberi `X-Tenant-ID`. Service wajib mengambil tenant aktif dari `TenantManager`, bukan body request atau header secara langsung. Device yang di-revoke wajib difilter `mst_sekolah_id` tenant aktif pada query control-plane sebelum mutasi.

### 8.11 Request validation exact

`CreateTvPairingRequest`:

```text
installation_id required|uuid
device_name     required|string|max:100
app_version     required|string|max:30
```

`ApproveTvPairingRequest`:

```text
user_code required|string|size:6|regex:/^[A-HJ-NP-Z2-9]{6}$/
name      required|string|max:100
mode      required|in:signage,classroom
class_id  nullable|integer|min:1|required_if:mode,classroom
```

Jangan memakai global `exists` untuk `class_id`; validasi keberadaan kelas setelah tenant middleware aktif pada schema tenant. Signage harus memaksa `class_id=null` walaupun client mengirim nilai.

### 8.12 Algoritma service wajib

**Create pairing:** validasi; hash installation; batalkan pending session lama installation tersebut; generate code dengan CSPRNG dan retry collision; simpan expiry 10 menit; kembalikan plaintext code hanya pada response create.

**Poll:** verifikasi header installation; lock row transaction; expired mengubah status menjadi expired; enforce `poll_after`; pending mengembalikan status; approved hanya mengembalikan raw token melalui mekanisme one-time delivery. Karena plaintext token tidak disimpan, approval harus menyimpan token sementara secara encrypted cache dengan TTL pendek menggunakan key session ID; poll mengambil via atomic `pull`. Jangan simpan plaintext di DB atau log. Setelah pull, set `consumed_at`; poll berikutnya mengembalikan approved tanpa `device_token`.

**Approve:** normalize uppercase code; transaction + `lockForUpdate`; pastikan pending, belum expiry, tenant/class valid; generate token; buat device; ubah session approved; taruh raw token encrypted cache TTL sampai session expiry; audit. Request approve berulang menghasilkan 409.

**Snapshot:** ambil device dari request; query schema tenant; susun payload DTO/array eksplisit; limit 6; urutkan deterministik; hitung ETag dari JSON canonical; jika `If-None-Match` cocok kembalikan 304 tanpa body; jangan serialize Eloquent model langsung.

**Revoke:** query device wajib `mst_sekolah_id == tenant user`; set `revoked_at` idempotent; jangan hard-delete audit record. Self-unpair hanya boleh mencabut device token saat ini.

Gunakan `DB::transaction()` dan `lockForUpdate()` untuk approve/poll agar token one-time aman pada concurrent request. Controller tipis: validasi → service → `ApiResponseTrait`.

Transaksi pairing/approval global wajib memakai control-plane connection secara eksplisit. Transaksi snapshot tenant memakai koneksi hasil `TenantConnectionManager`. Jangan membungkus operasi dua koneksi dalam asumsi transaksi atomik lintas database; approval hanya menulis control plane, sedangkan validasi kelas adalah read-only tenant query sebelum commit global. Jika validasi gagal, jangan membuat device.

### 8.13 Sumber data snapshot

Agent wajib menginspeksi model/service aktual sebelum menulis query. Gunakan tabel/model yang sudah ada, bukan tabel duplikat:

- sekolah: `MstSekolah` global + setting timezone/logo yang berlaku;
- jadwal: `TrxJadwalPelajaran` beserta relasi mapel/guru/kelas/ruang;
- kalender: `TrxKalenderAkademik`;
- presensi: model absensi siswa yang menjadi sumber dashboard aktual;
- announcement: hanya sumber yang memiliki flag publik dan window tayang.

Jika announcement atau materi belum mempunyai flag publik, agent wajib membuat migration tenant untuk field eksplisit seperti `is_public_display`, `display_start_at`, `display_end_at`; default false. Jangan menganggap seluruh notifikasi/forum/materi aman untuk TV. Tambahkan admin UI/API pengelolaan flag hanya bila belum ada jalur existing untuk mengubahnya.

Timezone memakai setting sekolah, fallback `Asia/Jakarta`. Jadwal dihitung berdasarkan tanggal lokal sekolah, bukan timezone server container. Attendance harus memenuhi `present + late + absent <= total`; dokumentasikan kategori lain jika total tidak sama.

### 8.14 RBAC dan audit

Tambah permission berikut ke `RbacSeeder::getAllPermissions()`:

```php
['code' => 'tv-device.manage', 'name' => 'Kelola Perangkat TV', 'module' => 'tv-device'],
```

Assign hanya ke role administratif sesuai mapping role aktual. Guru tidak otomatis mendapat permission; berikan melalui role bila kebijakan produk menyetujui. Jalankan auditor RBAC repo setelah menambah route.

Audit event minimum: `tv.pairing.approved`, `tv.device.revoked`; metadata hanya device UUID/name/mode dan actor. Dilarang mencatat raw code, installation ID, token, Authorization header.

### 8.15 Response/status contract backend

| Kasus | HTTP |
|---|---:|
| Pairing dibuat | 201 |
| Pending/approved/denied status | 200 |
| Validation gagal | 422 |
| Bearer device kosong/invalid/revoked | 401 |
| Device disabled/permission gagal | 403 |
| Session tidak ditemukan/expired poll | 404 atau 200 expired; pilih satu lalu konsisten dengan client test |
| Session sudah diproses saat approve | 409 |
| Poll/create rate limit | 429 + `Retry-After` |
| Snapshot ETag cocok | 304 tanpa body |

Gunakan `ApiResponseTrait` untuk JSON normal. Jangan mengembalikan exception message, SQL, schema, atau secret.

### 8.16 Gate backend sebelum client

Fase backend dianggap lolos hanya jika seluruh command berhasil:

```bash
cd /Users/bodo/www/akademihub_repo/sekolah/src
php artisan migrate:status
php artisan route:list --path=api/v1/tv
php artisan test --filter=Tv
php artisan test --filter=TenantMiddlewareTest
php scripts/audit_rbac_contract.php --self-test
```

Lalu lakukan HTTP smoke test nyata: create → pending → approve sebagai admin → approved token satu kali → snapshot → ETag 304 → revoke → snapshot 401. Simpan status code dan response yang sudah disensor pada laporan agent. **Client Flutter tidak boleh dimulai sebelum gate ini hijau.**

## 9. Domain dan Parsing

Entity immutable + Equatable.

`TvPairingSession`: `sessionId`, `userCode`, `verificationUrl`, `expiresAt` UTC, `pollInterval`.

`TvSnapshot`: `generatedAt`, `refreshAfter`, `device`, `school`, `settings`, `schedule`, `announcements`, `calendar`, `attendance?`.

Aturan parser:

- Object wajib hilang/salah tipe: gagal parsing.
- List hilang: list kosong. `image_url` invalid: null.
- Clamp refresh 30–900 detik; slide 10–120 detik.
- Waktu absolut: `DateTime.parse(...).toUtc()`.
- Jam `HH:mm`: validasi regex dan range.
- JSON invalid tidak boleh menimpa cache valid.

## 10. Storage dan HTTP Client

Secure keys:

```text
tv_installation_id
tv_device_token
tv_device_id
tv_device_mode
tv_token_origin
```

Cache `SharedPreferences`:

```text
tv_snapshot_json_v1
tv_snapshot_cached_at_v1
tv_snapshot_etag_v1
```

- `clearSession()` menghapus credential+cache, mempertahankan installation ID.
- Cache maksimum 24 jam.
- Origin API berubah: hapus token+cache.
- Device token dilarang memakai `AppConfig.tokenKey`. Buat Dio/interceptor TV terpisah agar session mobile tidak tertimpa.
- Jangan log Authorization, token, pairing code, atau payload privat.

Repository minimum:

```dart
abstract class TvRepository {
  Future<Result<TvPairingSession>> createPairingSession();
  Future<Result<TvPairingStatus>> getPairingStatus(String sessionId);
  Future<Result<TvSnapshotFetch>> getSnapshot({String? etag});
  Future<Result<TvSnapshot?>> readCachedSnapshot();
  Future<Result<void>> unpair();
  Future<bool> hasDeviceToken();
}
```

`TvSnapshotFetch` membedakan modified dan notModified. Mapping error: network/timeout menjadi `NetworkFailure`; 401/403 `AuthFailure`; JSON malformed `ServerFailure` dengan pesan aman.

## 11. State Machine

### TvAuthBloc

Events: `TvAuthStarted`, `TvPairingRequested`, `TvPairingPollTicked`, `TvPairingRetryRequested`, `TvUnpairRequested`.

States: `TvAuthInitial`, `TvAuthChecking`, `TvAuthPaired`, `TvPairingLoading`, `TvPairingPending`, `TvPairingDenied`, `TvPairingExpired`, `TvAuthFailure`.

Rules:

1. Started: credential ada menjadi paired; kosong membuat session.
2. Hanya satu polling timer; minimum interval 3 detik.
3. Stop timer saat terminal state, close, paused.
4. Approved: simpan token dulu, baru emit paired.
5. Network backoff 5, 10, 20, 30 detik + jitter; expiry tetap dihormati.

### TvSignageBloc

Events: `TvSignageStarted`, `TvSignageRefreshRequested`, `TvSignageRefreshTicked`, `TvSignageConnectivityRestored`, `TvSignageSessionRejected`.

States: `TvSignageInitial`, `TvSignageLoading`, `TvSignageLoaded`, `TvSignageEmpty`, `TvSignageFailure`, `TvSignageUnauthorized`.

Rules:

- Baca/render cache segera, lalu network.
- Fetch sukses: validasi, cache atomik, emit loaded.
- Refresh mengikuti payload; satu timer.
- 304 mempertahankan snapshot dan memperbarui waktu cek.
- 401/403 membersihkan session lalu pairing.
- Network backoff maksimal 5 menit; retry manual tersedia.

## 12. Router, DI, Lifecycle

Route:

```dart
static const tvBootstrap = '/tv/bootstrap';
static const tvPairing = '/tv/pairing';
static const tvSignage = '/tv/signage';
```

- Route TV di luar `MainShell` dan guard `AuthBloc` mobile.
- TV initial `/tv/bootstrap`; non-TV `/`.
- Bootstrap memakai `context.go`, bukan menumpuk route.
- Deep link `/tv/*` pada handset dialihkan `/` kecuali test inject `isTv=true`.
- DI manual: platform/storage/datasource/repository lazy singleton; kedua bloc factory dan page-scoped.
- `tv_signage_page.dart` menjadi `WidgetsBindingObserver`.
- Pause/inactive menghentikan carousel/refresh. Resume memulihkan immersive, refresh bila stale.
- `PageView` memakai `NeverScrollableScrollPhysics`; D-pad kiri/kanan pindah slide.
- Clock update per menit. Index dinormalisasi saat jumlah slide berubah.

## 13. Security/Error Matrix

| Kondisi | Respons client |
|---|---|
| Timeout/offline | cache ≤24 jam + backoff |
| 304 | pertahankan snapshot |
| 401/403 snapshot | clear session, pairing ulang |
| 404 pairing | expired |
| 429 | hormati `Retry-After` |
| 5xx | cache + retry, pesan generik |
| JSON invalid | pertahankan cache |
| Gambar gagal | placeholder brand |

- URL gambar wajib HTTPS pada release. Jangan longgarkan cleartext global.
- Announcement ditampilkan plain text/sanitized dan dibatasi panjang.
- Jangan tampilkan stack trace/error backend.
- Unpair memerlukan konfirmasi dua langkah.

## 14. Urutan Implementasi

### Fase A — Backend

1. Migration/model/service/controller/request/policy/routes.
2. Create/poll/approve/snapshot/unpair.
3. Seed `tv-device.manage` ke role admin sesuai RBAC aktual.
4. Feature test tenant isolation, expiry, one-time token, revocation, privacy, rate limit.

### Fase B — Platform shell

1. Manifest/banner/MethodChannel/platform service.
2. Initial route TV/mobile tanpa regresi.
3. Test deteksi dan routing.

### Fase C — Pairing

1. Storage/model/entity/datasource/repository.
2. Auth bloc dan pairing page.
3. Polling, expiry, retry, secure save; test timer disposal.

### Fase D — Signage

1. Snapshot parser/cache/ETag.
2. Signage bloc/slides/focus/carousel/lifecycle.
3. Test empty, error, offline, unauthorized, 720p/1080p.

### Fase E — Release

1. Audit secret/log/privacy.
2. Uji emulator TV, TV fisik, handset.
3. Build signed release; validasi Leanback/banner.

Setiap fase wajib hijau sebelum lanjut.

## 15. Test Wajib

### Backend

- Tenant A tidak dapat approve/read/revoke TV tenant B.
- Code expired/denied/consumed tidak menghasilkan token.
- Poll concurrent hanya satu menerima token.
- Device token hanya mengakses TV read-only.
- Snapshot bebas nama/ID/NIS/foto/nilai/keuangan/BK siswa.
- Classroom hanya memuat kelas terikat.
- Revoked token ditolak.
- Device registry selalu dibaca dari control-plane walau tenant `search_path` aktif.
- TV tenant pada database node A tidak pernah query node tenant B/default.
- Superadmin tanpa `X-Tenant-ID` tidak dapat approve/revoke; header tenant yang tidak cocok tidak dapat menyentuh device tenant lain.
- Route `DELETE /tv/devices/current` selalu menuju self-unpair, bukan binding `{device}`.
- PostgreSQL integration test membuktikan `SET LOCAL` dan reset context; SQLite test saja tidak cukup untuk menyatakan isolasi production aman.

### Dart/widget

- Payload lengkap/minimal/malformed/null URL/timezone.
- Clamp durasi; seluruh status pairing; timer close/pause.
- Cache bertahan saat network/parser gagal; 304 tidak menghapus data.
- 401 clear session tetapi mempertahankan installation ID.
- Pairing code/countdown; fokus awal; arrows/Enter/Back.
- Tidak overflow pada 1280×720 dan 1920×1080.
- Slide kosong tidak dibuat; offline timestamp tampil; semantics tersedia.

### Manual

| Target | Pemeriksaan |
|---|---|
| Android TV emulator | install, launcher, D-pad, pairing, resume |
| TV fisik 1080p | safe area, focus, reconnect, sleep/resume |
| Google TV 4K | scaling, image memory, stabilitas 2 jam |
| Handset Android | launcher/login/dashboard/GPS tidak regresi |

Soak test release minimum 8 jam: tanpa crash, request/timer leak, memory growth, atau portrait rotation.

## 16. Validasi

Dari `/Users/bodo/www/akademihub_repo/akademihub_mob`:

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
apkanalyzer manifest print build/app/outputs/flutter-apk/app-debug.apk | grep -E "leanback|touchscreen|banner"
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p id.akademihub.akademihub_mob 1
adb shell dumpsys package id.akademihub.akademihub_mob | grep -i leanback
```

Release signing saat ini masih debug di `android/app/build.gradle.kts`; wajib diganti melalui secret lokal/CI. Jangan commit keystore/password.

## 17. Definition of Done

- APK tampil di TV launcher dengan banner benar; APK sama normal di handset.
- Deteksi memakai `UiModeManager`.
- Pairing tanpa password end-to-end, tenant-safe, rate-limited.
- Device token terpisah dari token mobile, encrypted at rest, revocable.
- Hanya data publik/agregat tampil.
- Semua kontrol usable remote D-pad.
- Offline, expiry, 304, 401/403, 429, 5xx tertangani.
- Tidak ada timer/subscription leak.
- `flutter analyze`, seluruh `flutter test`, backend TV tests hijau.
- Manual matrix dan soak test memiliki bukti hasil.
- Tidak ada secret/pairing code/data siswa/signing credential di log/repo.

## 18. Larangan Agent

- Jangan menganggap penambahan Leanback saja berarti fitur selesai.
- Jangan reuse halaman mobile tanpa audit fokus/privacy.
- Jangan menjadikan password login sebagai flow utama TV.
- Jangan hardcode/mock permanen data sekolah.
- Jangan menambah package untuk deteksi, carousel, state, cache.
- Jangan mengubah kontrak auth mobile atau menerima `tenant_id` dari pairing request.
- Jangan tampilkan data individual atau longgarkan TLS/cleartext release.
- Jangan lanjut fase saat test fase aktif gagal.

## 19. Laporan Akhir Agent

Wajib mencantumkan:

1. File dibuat/diubah.
2. Endpoint, migration, permission ditambahkan.
3. Perintah validasi dan hasil aktual.
4. Device/emulator yang benar-benar diuji.
5. Deviasi dan alasan.
6. Risiko tersisa: signing release, approval web UI, physical-device soak test.