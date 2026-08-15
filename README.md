# AkademiHub Mobile

Aplikasi Flutter untuk siswa, guru, wali murid, dan admin sekolah.  
Repo ini: **`akademihub_mob`** — client mobile yang mengonsumsi API backend **`sekolah_pintar`**.

---

## Daftar isi

- [Stack](#stack)
- [Prasyarat](#prasyarat)
- [Setup cepat](#setup-cepat)
- [Menjalankan app](#menjalankan-app)
- [Konfigurasi API](#konfigurasi-api)
- [Arsitektur](#arsitektur)
- [Menambah fitur baru](#menambah-fitur-baru)
- [Codegen](#codegen)
- [State management](#state-management)
- [Routing](#routing)
- [Layout & UI mobile](#layout--ui-mobile)
- [Modul / fitur](#modul--fitur)
- [Perintah harian](#perintah-harian)
- [Troubleshooting](#troubleshooting)
- [Konvensi kontribusi](#konvensi-kontribusi)

---

## Stack

| Area | Teknologi |
|------|-----------|
| Framework | Flutter (Dart SDK `^3.11.4`) |
| State | `flutter_bloc` + `equatable` |
| Networking | `dio` + `retrofit` |
| DI | `get_it` + `injectable` |
| Navigation | `go_router` |
| Storage | `flutter_secure_storage`, `shared_preferences`, `hive_flutter` |
| Push | Firebase Messaging + local notifications |
| Realtime | `pusher_channels_flutter` (Laravel Reverb) |
| JSON | `json_serializable` / `json_annotation` |

---

## Prasyarat

1. **Flutter stable** (cocok dengan SDK di `pubspec.yaml`)
2. Android Studio / Xcode (device atau emulator)
3. Backend API berjalan (default dev: port **8002**)
4. Untuk Android emulator: host machine = `10.0.2.2`

Cek:

```bash
flutter doctor
flutter --version
```

---

## Setup cepat

```bash
cd akademihub_mob
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Firebase (jika push notification dibutuhkan): pastikan file platform (`google-services.json` / `GoogleService-Info.plist`) sudah ada sesuai environment proyek.

---

## Menjalankan app

```bash
# List device
flutter devices

# Debug
flutter run

# Device / emulator spesifik
flutter run -d <device_id>

# Release (uji performa)
flutter run --release
```

Hot reload: `r` · Hot restart: `R` · Quit: `q`

---

## Konfigurasi API

File: `lib/core/config/app_config.dart`

| Mode | Base URL (default) |
|------|--------------------|
| Debug (`kDebugMode`) | `http://10.0.2.2:8002/api/v1` |
| Release | `https://api.akademihub.id/api/v1` |

Catatan:

- **Android emulator** → `10.0.2.2` = localhost PC.
- **iOS simulator** → gunakan `http://127.0.0.1:8002/api/v1` (ubah `_apiBaseUrlDev` jika perlu).
- **Device fisik** → ganti ke IP LAN mesin backend, mis. `http://192.168.1.10:8002/api/v1`.
- Multi-tenant: user bisa memilih tenant; base URL tenant disimpan lewat `tenant` config/storage.
- Token Origin & Tenant Binding: access/refresh token diikat ke origin tenant tempat token diterbitkan (`token_origin`). Jika origin tenant aktif berbeda dengan origin token, session dibersihkan dan meminta login ulang (mencegah kebocoran refresh token lintas origin). Perpindahan tenant atau logout selalu membersihkan cache `TenantStorage` dan `TokenStorage`.
- Batasan Superadmin: manajemen dan switching superadmin lintas tenant adalah **web-only**. Aplikasi mobile khusus melayani user tenant sekolah terdaftar dan tidak menyediakan entry point pemilih tenant superadmin.

Client HTTP: `lib/core/api/api_client.dart`  
- Inject JWT dari secure storage  
- Refresh token otomatis saat 401 (jika refresh tersedia)

---

## Arsitektur

Clean Architecture per fitur + layer `core` bersama.

```
lib/
├── main.dart                 # bootstrap, theme, global BlocProvider
├── core/
│   ├── api/                  # Dio client, interceptors
│   ├── config/               # AppConfig, tenant
│   ├── di/                   # GetIt registration (injection.dart)
│   ├── error/                # Failure, Result, exceptions
│   ├── router/               # go_router
│   ├── storage/              # token & tenant storage
│   ├── theme/                # AppTheme, AppColors
│   ├── utils/                # Responsive helpers
│   └── widgets/              # shell, shared widgets
└── features/
    └── <nama_fitur>/
        ├── data/
        │   ├── datasources/  # remote API calls
        │   ├── models/       # JSON DTO (+ *.g.dart)
        │   └── repositories/ # repository impl
        ├── domain/
        │   ├── entities/     # pure Dart entities
        │   ├── repositories/ # abstract contracts
        │   └── usecases/     # one use-case ≈ one action
        └── presentation/
            ├── bloc/         # event, state, bloc
            ├── pages/        # screens
            └── widgets/      # UI potongan fitur
```

**Alur data:** UI → Bloc → UseCase → Repository → RemoteDataSource → API

---

## Menambah fitur baru

Contoh fitur `contoh` (ikuti pola `auth` / `nilai` / `tugas`).

### 1. Folder

```
lib/features/contoh/
  data/datasources/
  data/models/
  data/repositories/
  domain/entities/
  domain/repositories/
  domain/usecases/
  presentation/bloc/
  presentation/pages/
  presentation/widgets/   # opsional
```

### 2. Domain

- Entity (tanpa JSON)
- Abstract repository
- Use case (`call(...)`)

### 3. Data

- Model + `@JsonSerializable` → generate `*.g.dart`
- Remote datasource (Dio / Retrofit)
- Repository impl: map model → entity, bungkus error ke `Failure` / `Result`

### 4. Presentation

- `contoh_event.dart`, `contoh_state.dart`, `contoh_bloc.dart`
- Page: `BlocProvider` + `BlocBuilder` / `BlocListener`
- Widget UI terpisah jika kompleks

### 5. DI

Daftarkan di `lib/core/di/injection.dart`:

```dart
// datasource → repository → usecase → bloc
sl.registerLazySingleton<ContohRemoteDataSource>(...);
sl.registerLazySingleton<ContohRepository>(...);
sl.registerLazySingleton(() => GetContohUseCase(sl()));
sl.registerFactory(() => ContohBloc(sl()));
```

### 6. Router

Tambah route di `lib/core/router/app_router.dart` (dan menu/shell jika perlu).

### 7. Codegen + cek

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

---

## Codegen

Dijalankan ulang setelah ubah model JSON, Retrofit API, atau anotasi injectable:

```bash
# sekali jalan
dart run build_runner build --delete-conflicting-outputs

# watch mode saat dev
dart run build_runner watch --delete-conflicting-outputs
```

File ter-generate biasanya: `*.g.dart`, `*.config.dart` — **jangan edit manual**.

Opsi `json_serializable` ada di `build.yaml` (`explicit_to_json: true`).

---

## State management

Pola BLoC standar:

| File | Isi |
|------|-----|
| `*_event.dart` | aksi user / lifecycle |
| `*_state.dart` | `Initial` / `Loading` / `Loaded` / `Error` (+ data) |
| `*_bloc.dart` | map event → usecase → emit state |

- Global: `AuthBloc`, `DashboardBloc` di `main.dart`
- Per halaman: `BlocProvider(create: (_) => sl<XxxBloc>()..add(...))`
- Bandingkan state dengan `equatable` (`props`)

---

## Routing

- `go_router` di `lib/core/router/app_router.dart`
- Shell navigasi: `lib/core/widgets/main_shell.dart`
- Guard auth: cek token / state `AuthBloc` sebelum masuk route terproteksi

Saat menambah halaman: daftarkan path, builder, dan (jika perlu) redirect.

---

## Layout & UI mobile

Aturan Flutter: **constraints down, sizes up, parent positions**.

Hindari:

| Error | Penyebab umum | Perbaikan |
|-------|----------------|-----------|
| Vertical viewport unbounded | `ListView` di dalam `Column` tanpa batas tinggi | Bungkus `Expanded` / `SizedBox` / `shrinkWrap` + non-scroll physics jika nested |
| InputDecorator unbounded width | `TextField` di `Row` tanpa flex | `Expanded` / `Flexible` |
| RenderFlex overflowed | teks/badge panjang di `Row` | `Expanded`/`Flexible` + `maxLines` + `ellipsis` |
| ParentDataWidget salah | `Expanded` di luar Flex, `Positioned` di luar `Stack` | pindahkan ke parent yang benar |

Praktik di proyek ini:

- List utama: `Column` → filter → `Expanded` → `ListView` / `CustomScrollView`
- Nested grid: `shrinkWrap: true` + `NeverScrollableScrollPhysics`
- Badge/chip: `maxWidth` + ellipsis
- Helper: `lib/core/utils/responsive.dart` (`pagePadding`, `gridDelegate`, `lebarKontenMaks`)
- Skala font sistem di-clamp di `main.dart` (0.85–1.3) agar kartu tetap stabil

Theme & warna: `lib/core/theme/app_theme.dart`.

---

## Modul / fitur

| Folder fitur | Fungsi ringkas |
|--------------|----------------|
| `auth` | login, session, user |
| `tenant` | pilih sekolah / base URL |
| `dashboard` | ringkasan per role |
| `absensi` | kehadiran siswa/guru |
| `jadwal` | jadwal pelajaran |
| `nilai` | nilai & ringkasan |
| `rapor` | daftar & detail rapor |
| `tugas` | tugas & pengumpulan |
| `materi` | materi ajar |
| `ujian` | ujian & ranking |
| `tmb` | tes minat bakat |
| `keuangan` | SPP / pembayaran |
| `ppdb` | pendaftaran siswa baru |
| `bk` | bimbingan konseling |
| `kalender` | agenda sekolah |
| `forum` | diskusi |
| `ekstrakurikuler` | ekskul |
| `ews` | early warning system |
| `siswa_insight` | insight 360° per siswa |
| `notifications` | notifikasi in-app |
| `profil` | profil & perangkat |

---

## Perintah harian

```bash
# dependensi
flutter pub get

# analisis statis
flutter analyze

# test
flutter test

# codegen
dart run build_runner build --delete-conflicting-outputs

# clean build (jika aneh)
flutter clean && flutter pub get

# build APK debug
flutter build apk --debug

# build APK release
flutter build apk --release
```

---

## Troubleshooting

| Gejala | Cek |
|--------|-----|
| Gagal connect API di emulator | Backend hidup? Port 8002? URL `10.0.2.2`? |
| Gagal connect di HP fisik | Firewall, IP LAN, HTTP cleartext (Android network security) |
| 401 berulang | Token expired; cek refresh; login ulang |
| `*.g.dart` missing / error | Jalankan `build_runner` |
| DI `GetIt` not registered | Lupa daftar di `injection.dart` / salah scope factory vs singleton |
| Layout overflow kuning-hitam | Lihat [Layout & UI mobile](#layout--ui-mobile) |
| Hot reload tidak memuat DI baru | Hot **restart** (`R`) |
| Ikon/asset hilang | Path di `pubspec.yaml` → `flutter:` → `assets:` |

---

## Konvensi kontribusi

1. **Ikuti struktur fitur yang sudah ada** — jangan campur domain ke UI.
2. **Satu use case = satu aksi bisnis** yang jelas.
3. **Entity domain tidak bergantung Flutter/JSON**; mapping di data layer.
4. **Jangan commit secret** (token, key Firebase produksi di channel publik tanpa kebijakan tim).
5. **UI:** prefer komponen/widget existing; gunakan `AppColors` / theme.
6. **Sebelum PR / serah kerja:**
   - `dart run build_runner build --delete-conflicting-outputs` (jika sentuh model/API)
   - `flutter analyze`
   - `flutter test`
   - Uji di emulator/device untuk flow utama fitur
7. **Layout:** selalu jaga constraint di `Row`/`Column`/scrollable (lihat bagian layout).
8. **Naming:** file snake_case (`nilai_page.dart`); class PascalCase (`NilaiPage`).

---

## Backend terkait

API utama: folder monorepo **`sekolah_pintar`** (Laravel).  
Pastikan endpoint yang dipanggil mobile sudah tersedia dan sesuai kontrak response (pagination, field JSON, kode error).

---

## Lisensi / status

Proyek internal AkademiHub — `publish_to: 'none'`.  
Versi app: lihat `version` di `pubspec.yaml`.
