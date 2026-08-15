# Prioritas Perbaikan Mobile Pasca-Hardening Backend

**Versi:** 1.2  
**Tanggal audit:** 16 Agustus 2026  
**Terakhir diperbarui:** 16 Agustus 2026  
**Scope:** Auth, multi-tenant, ujian, absensi, dashboard, EWS, statistik, pembayaran SPP, penghapusan PPDB  
**Mobile:** Flutter `akademihub_mob`  
**Backend acuan:** Laravel `sekolah/src` commit `71be22b1` dan Go `sekolah_go/{exam-engine,absensi-worker,dashboard-engine,ews-worker,statistik-engine}`

---

## 1. Mandat Implementasi

Dokumen ini adalah **instruksi implementasi wajib**, bukan daftar ide, rekomendasi opsional, atau bahan perencanaan. AI Agent yang mengerjakan dokumen ini wajib:

1. mengimplementasikan seluruh item `MOB-*` dan `API-*` beserta seluruh butir solusi, acceptance criteria, Definition of Done, test, dokumentasi, serta verifikasi yang tertulis;
2. tidak mengurangi scope, mengganti requirement dengan pendekatan yang lebih lemah, menunda item ke pekerjaan lanjutan, atau menyatakan selesai berdasarkan `flutter analyze`/test lama saja;
3. tidak menghapus validasi trust boundary, penanganan error, keamanan token, isolasi tenant, aksesibilitas UI, atau test dengan alasan penyederhanaan;
4. memperbaiki semua pemanggil, model, state, route, dependency injection, menu, test, fixture, dan dokumentasi yang terdampak; daftar lokasi pada dokumen ini bukan batas maksimum file;
5. memakai kontrak backend aktual sebagai sumber kebenaran. Jika kode mobile, test lama, komentar, README, atau asumsi lokal bertentangan dengan Laravel/Go, semuanya harus diselaraskan ke backend;
6. membuat fixture kontrak dari response backend aktual atau dari serializer/struct/test backend yang menghasilkan response tersebut, bukan menyalin asumsi mobile lama;
7. menjalankan seluruh langkah verifikasi dan melaporkan hasil nyata. Kegagalan tidak boleh disembunyikan, di-skip, atau diubah menjadi test yang selalu lulus;
8. menyelesaikan konflik atau detail teknis yang belum tertulis dengan improvisasi paling aman dan paling kecil, tanpa mengganti, menghapus, atau melemahkan requirement yang sudah ada;
9. menjaga perubahan pengguna yang tidak terkait dan tidak melakukan revert terhadap perubahan tersebut;
10. belum menyatakan pekerjaan selesai selama satu acceptance criterion pun belum terbukti.

Prioritas `P0/P1/P2` menentukan urutan pengerjaan dan tingkat risiko, **bukan** izin untuk melewati item. Semua scope dalam dokumen ini wajib selesai pada implementasi yang sama. Item `API-*` adalah hardening backend wajib karena client bukan security boundary. Satu-satunya cabang produk yang diperbolehkan adalah keputusan eksplisit pada `MOB-TENANT-01`; keputusan tersebut tetap wajib diimplementasikan, didokumentasikan, dan diuji.

---

## 2. Keputusan Produk

PPDB adalah **web-only**. Mobile tidak menyediakan:

- portal atau pendaftaran PPDB publik;
- cek status PPDB;
- administrasi pendaftar, dokumen, seleksi, dan statistik;
- transisi status calon siswa;
- enrollment calon siswa menjadi siswa.

Konsekuensi: modul `lib/features/ppdb` harus dihapus dari mobile. Perubahan PPDB-01 sampai PPDB-06 di backend tidak perlu direplikasi ke mobile.

Mobile tetap berfokus pada pengguna sekolah yang sudah memiliki akun: siswa, guru, wali, dan admin sesuai kebutuhan produk.

---

## 3. Ringkasan Prioritas

| ID | Prioritas | Area | Perbaikan | Dampak |
|---|---|---|---|---|
| MOB-EXAM-01 | P0 | Ujian | Selaraskan status sesi `1/2/3/4` | Flow ujian saat ini salah membaca seluruh status backend |
| MOB-EXAM-02 | P0 | Ujian | Dukung `awaiting_grading` dan nilai provisional | Ujian essay dapat tampil sebagai belum mulai/nilai nol |
| MOB-EXAM-03 | P1 | Ujian | Gunakan deadline server dan sinkronkan timeout | UI masih aktif setelah deadline server |
| MOB-AUTH-01 | P1 | Auth | Jadikan refresh token single-flight | Refresh paralel dapat memicu reuse dan revoke session family |
| MOB-AUTH-02 | P1 | Auth | Satukan kontrak refresh token | Method manual masih mengirim token melalui Bearer header |
| MOB-PPDB-01 | P1 | Scope | Hapus seluruh modul PPDB mobile | PPDB telah diputuskan web-only |
| MOB-PAY-01 | P2 | Pembayaran | Refresh obligation setelah checkout | Redirect WebView bukan bukti pembayaran lunas |
| MOB-TENANT-01 | P2 | Tenant | Validasi flow superadmin lintas tenant | Backend kini mewajibkan tenant eksplisit |
| MOB-QA-01 | P1 | QA | Tambahkan contract dan integration test | Unit test saat ini belum menangkap perubahan kontrak backend |
| MOB-ABS-01 | P0 | Absensi | Selaraskan fitur check-in dengan route backend aktual | Mobile memanggil endpoint yang tidak tersedia di `absensi-worker` |
| API-ABS-01 | P0 | Absensi/AuthZ | Scope list, detail, rentang, rekap, dan mutasi per role/resource | JWT valid saat ini dapat membuka data absensi di luar kepemilikan |
| MOB-DASH-01 | P1 | Dashboard | Gunakan field Go `total_mapel` | UI guru menampilkan nol walau backend mengirim nilai |
| MOB-DASH-02 | P1 | Dashboard/PPDB | Hapus parser dan kartu PPDB mobile | Dashboard masih melanggar keputusan PPDB web-only |
| API-DASH-01 | P0 | Dashboard/AuthZ | Lindungi endpoint analytics dengan permission | User login dapat meminta analytics sensitif langsung |
| MOB-EWS-01 | P1 | EWS | Sediakan detail alert authoritative | Detail mobile hanya mencari halaman pertama |
| API-EWS-01 | P0 | EWS/AuthZ | Lindungi process, list, detail, dan resolve | Semua user login berpotensi membaca/mengubah alert |
| API-STAT-01 | P0 | Statistik/AuthZ | Lindungi statistik global dan validasi filter | Semua user login berpotensi membaca statistik sensitif |
| API-AUTHZ-01 | P0 | Shared AuthZ | Satukan role canonical dan tenant/resource scope | Service Go memakai sumber role dan enforcement berbeda |
| API-QA-01 | P1 | QA Backend | Tambahkan contract/authorization test seluruh service Go | Mayoritas service lulus build tanpa test keamanan |

### Status Implementasi

- [x] **MOB-EXAM-01** — selesai (`akademihub_mob` commit `c950605`)
- [x] **MOB-EXAM-02** — selesai (`akademihub_mob` commit `0f02e86`)
- [x] **MOB-ABS-01** — selesai (`akademihub_mob` commit `13866ea`; `absensi-worker` commit `0cc97fa`)
- [x] **API-ABS-01** — selesai (`absensi-worker` commit `f803814`, `7d9f6e7`)

Item yang tidak tercantum di atas belum ditandai selesai.

---

## 4. P0 — Ujian

### MOB-EXAM-01 — Selaraskan status sesi ujian

Backend `exam-engine` memakai kontrak:

| `status` | `status_code` | Arti |
|---:|---|---|
| `1` | `not_started` | Belum mulai |
| `2` | `in_progress` | Mengerjakan |
| `3` | `completed` | Selesai dan nilai final tersedia |
| `4` | `awaiting_grading` | Selesai dikerjakan, menunggu koreksi essay |

`status_code` menjadi sumber utama. Angka `status` hanya fallback kompatibilitas.

**Masalah mobile saat ini:**

```dart
1 => mengerjakan
2 => selesai
_ => belumMulai
```

Mapping tersebut bertentangan dengan backend aktual.

**Lokasi terkait:**

- `lib/features/ujian/data/models/ujian_session_model.dart`
- `lib/features/ujian/domain/entities/ujian_session_entity.dart`
- `lib/features/ujian/presentation/pages/ujian_page.dart`
- `lib/features/ujian/presentation/pages/ujian_session_page.dart`

**Solusi minimum:**

1. Parse `status_code` lebih dahulu.
2. Gunakan status angka `1/2/3/4` hanya jika `status_code` tidak tersedia.
3. Status tidak dikenal harus tampil sebagai error kontrak, bukan diam-diam menjadi `belumMulai`.
4. Tombol mulai hanya tersedia pada `not_started`.
5. Form jawaban dan tombol selesai hanya tersedia pada `in_progress`.
6. Nilai final hanya tampil pada `completed`.

**Acceptance criteria:**

- Status `1/not_started` menampilkan tombol mulai dan tidak mengambil soal sebelum sesi dimulai.
- Status `2/in_progress` mengambil soal dan mengaktifkan input jawaban.
- Status `3/completed` tidak menampilkan tombol mulai/selesai dan menampilkan hasil final.
- Status `4/awaiting_grading` tidak mengizinkan mulai ulang atau perubahan jawaban.
- Test model mencakup `status_code`, fallback angka, dan status tidak dikenal.

### MOB-EXAM-02 — Dukung awaiting grading dan nilai provisional

Backend dapat mengirim:

```json
{
  "status": 4,
  "status_code": "awaiting_grading",
  "nilai_akhir": null,
  "nilai_provisional": 50
}
```

**Solusi minimum:**

- Tambah status domain `menungguKoreksi`.
- Ubah `nilaiAkhir` menjadi nullable.
- Tambah `nilaiProvisional` nullable.
- Tampilkan label “Menunggu koreksi essay”.
- Jangan menyebut nilai provisional sebagai nilai akhir.
- Nilai provisional boleh disembunyikan sampai kebijakan produk menetapkan publikasinya.

**Acceptance criteria:**

- `nilai_akhir: null` tidak dikonversi menjadi `0`.
- Sesi `awaiting_grading` tidak terlihat gagal atau belum mulai.
- UI membedakan nilai sementara dan final secara eksplisit.
- Setelah guru menyelesaikan koreksi, refresh mengubah sesi menjadi `completed` dan menampilkan nilai final.

---

## 5. P0 — Absensi dan Authorization Backend

### MOB-ABS-01 — Selaraskan self check-in absensi

**Status:** ✅ Selesai — mobile `13866ea`, backend `0cc97fa`.

Mobile memanggil `POST /api/v1/akademik/absensi-siswa/check-in`, tetapi route tersebut tidak tersedia pada `absensi-worker`.

**Keputusan produk:** self check-in siswa tetap tersedia pada mobile. Backend wajib menyediakan endpoint canonical tersebut; mobile tidak boleh menggantinya dengan `POST /absensi-siswa` yang menerima `mst_siswa_id` bebas.

**Kontrak minimum endpoint:**

- identitas siswa selalu diambil dari JWT/profile server, bukan body request;
- tanggal dan waktu authoritative berasal dari server;
- hanya siswa aktif dengan tenant valid yang dapat check-in;
- check-in idempoten untuk siswa dan tanggal yang sama;
- duplicate/concurrent check-in tidak membuat record ganda;
- response memakai envelope standar dan mengembalikan record absensi aktual;
- status awal ditetapkan backend sesuai kebijakan sekolah, bukan input mobile;
- mobile memuat ulang riwayat setelah sukses dan menampilkan error backend setelah gagal.

**Acceptance criteria:**

- route mobile tidak lagi `404` melalui reverse proxy;
- siswa tidak dapat check-in atas nama siswa lain atau menentukan tanggal/status sendiri;
- dua check-in paralel menghasilkan satu record;
- role non-siswa menerima `403` kecuali terdapat permission eksplisit yang didokumentasikan;
- test integration mencakup sukses, duplicate, concurrent, inactive user, wrong role, dan tenant isolation.

### API-ABS-01 — Authorization absensi per resource

JWT valid tidak cukup. Terapkan authorization pada seluruh endpoint `absensi-siswa`, `absensi-guru`, dan `presensi`, termasuk list, show, summary, date-range, rekap, create, update, delete, dan bulk.

**Aturan scope minimum:**

- admin berizin hanya mengakses data tenant aktif;
- siswa hanya membaca datanya sendiri;
- wali hanya membaca anak yang memiliki relasi wali aktif;
- guru hanya membaca/mengubah siswa dan kelas/mapel assignment yang menjadi kewenangannya;
- guru hanya membaca absensi gurunya sendiri kecuali memiliki permission administrasi;
- ID/filter dari query, path, atau body selalu diverifikasi terhadap claims dan relasi DB;
- list tanpa filter tidak boleh memperluas akses; backend wajib menyuntikkan scope;
- resource di luar scope menghasilkan `403` atau `404` konsisten tanpa membocorkan data;
- bulk operation memvalidasi setiap item dan berjalan atomik agar kegagalan scope tidak menghasilkan perubahan parsial.

**Acceptance criteria:**

- siswa tidak dapat list/show/date-range/rekap absensi siswa lain;
- wali tidak dapat membaca siswa yang bukan anaknya;
- guru tidak dapat membaca atau mengubah kelas/assignment lain;
- filter kosong/invalid tidak menghapus scope authorization;
- seluruh mutation menolak IDOR;
- test handler/service mencakup setiap role, cross-resource, cross-tenant, dan bulk campuran valid/tidak valid.

### API-DASH-01 — Permission endpoint analytics dashboard

Endpoint `/dashboard/financial-analytics`, `/academic-attendance`, `/counseling-insights`, dan `/ppdb-insights` saat ini hanya dilindungi autentikasi.

**Solusi wajib:**

- tambahkan permission guard backend per endpoint;
- jangan mengandalkan route/menu mobile untuk membatasi akses;
- filter kelas/tahun wajib dibatasi ke resource yang boleh diakses role;
- PPDB insights tetap dapat dipakai web oleh role berizin, tetapi tidak diekspos pada mobile;
- response unauthorized menggunakan `403`, bukan data kosong yang menyamarkan pelanggaran.

**Acceptance criteria:** siswa/wali tidak dapat membaca analytics global; guru hanya menerima analytics assignment-nya; admin tanpa permission ditolak; role berizin menerima response yang sama seperti kontrak aktual.

### API-EWS-01 — Authorization EWS

Seluruh operasi EWS bersifat sensitif. Terapkan permission dan resource scope pada batch process, process siswa, list, detail, dan resolve.

**Aturan minimum:**

- batch `/ews/process` hanya untuk permission operasional khusus;
- `/process-siswa/{id}` memverifikasi permission dan assignment siswa;
- list menyuntikkan scope server; `mst_siswa_id` dari client tidak boleh memperluas akses;
- detail memverifikasi akses ke siswa pemilik alert;
- resolve hanya untuk role berizin dan mencatat actor server-side;
- siswa tidak dapat process/resolve; akses baca siswa/wali hanya jika kebijakan produk mengizinkan dan hanya untuk resource sendiri/anak;
- operasi berat memiliki rate limit dan tidak dapat dipicu berulang tanpa batas.

**Acceptance criteria:** direct URL tetap aman; IDOR list/detail/resolve ditolak; actor resolve tercatat; test mencakup siswa, wali, guru assignment/non-assignment, admin berizin/tanpa izin, rate limit, dan tenant isolation.

### API-STAT-01 — Authorization dan validasi statistik

Mobile saat ini tidak memakai `/api/v1/statistik/*`; `features/siswa_insight` memakai endpoint Laravel berbeda. Jangan menambah modul statistik mobile. Backend statistik tetap wajib di-hardening karena endpoint dapat dipanggil langsung.

**Solusi wajib:**

- pasang permission guard pada overview, akademik, kehadiran, keuangan, BK, PPDB, perpustakaan, ujian, ekstrakurikuler, organisasi, guru, dan SPK;
- batasi filter kelas/mapel/tahun ke scope role;
- parameter numerik/tanggal invalid menghasilkan `400`, bukan fallback yang menghapus filter;
- default hanya dipakai ketika parameter tidak dikirim, bukan ketika formatnya salah;
- statistik keuangan, BK, PPDB, guru, dan global tidak tersedia bagi siswa/wali;
- endpoint PPDB tetap web-only dari perspektif client mobile.

**Acceptance criteria:** user tanpa permission menerima `403`; filter invalid menerima `400`; filter di luar scope ditolak; query tanpa filter tetap scoped; test mencakup setiap endpoint sensitif dan cross-tenant.

### API-AUTHZ-01 — Role canonical dan tenant enforcement lintas service

Service Go saat ini tidak konsisten: `dashboard-engine` membaca `sys_roles.code`, sedangkan service lain membaca `sys_roles.name`, lalu membandingkan string role yang sama.

**Solusi wajib:**

- tetapkan `sys_roles.code` sebagai identifier canonical atau gunakan komponen shared yang ekuivalen;
- normalisasi case tanpa memakai label tampilan sebagai keputusan authorization;
- validasi user aktif, role aktif, tenant aktif, dan schema/origin tenant pada setiap service;
- gunakan permission backend aktual, bukan role-only check, untuk operasi sensitif;
- jangan menerima `superadmin` tanpa tenant eksplisit pada endpoint tenant;
- samakan envelope error `401/403/400` agar mobile dapat menangani konsisten.

**Acceptance criteria:** role code yang sama menghasilkan keputusan sama di lima service Go dan Laravel; perubahan `name` role tidak mengubah hak akses; token tenant A tidak mengakses tenant B; contract test shared lulus pada seluruh service.

---

## 6. P1 — Reliability dan Kontrak Mobile Lain

### MOB-EXAM-03 — Deadline server authoritative

Backend mengirim `deadline_at` dan `timed_out_at`, serta menolak jawaban pada atau setelah deadline.

**Masalah mobile saat ini:** countdown dihitung dari `waktu_mulai + sisa_waktu`. Saat nol, timer hanya berhenti; input dan tombol masih dapat terlihat aktif.

**Solusi minimum:**

1. Parse `deadline_at` dan `timed_out_at`.
2. Hitung countdown tampilan dari `deadline_at` memakai waktu server. Ambil offset waktu server dari header HTTP `Date` atau field `server_time`; jangan mengandalkan jam perangkat tanpa koreksi offset.
3. Saat countdown nol, nonaktifkan seluruh input secara langsung.
4. Ambil ulang sesi dari backend.
5. Tampilkan status timeout/finalisasi yang dikembalikan server.
6. Error submit akibat deadline harus memicu refresh sesi, bukan hanya snackbar generik.
7. Jika offset waktu server belum tersedia pada response sesi, tambahkan dukungan generik untuk membaca header `Date` pada client tanpa mengubah otoritas deadline backend.

**Catatan:** countdown mobile hanya presentasi. Backend tetap satu-satunya penentu deadline.

**Acceptance criteria:**

- Perubahan jam perangkat tidak memungkinkan jawaban terlambat tersimpan.
- Perubahan jam perangkat tidak membuat countdown kembali bertambah atau membuka ulang input karena countdown memakai offset waktu server.
- UI menutup input saat deadline tercapai.
- Response deadline dari submit mengubah UI ke state server terbaru.
- `timed_out_at` menghasilkan pesan “Waktu ujian habis”.
- Test widget memakai waktu terkontrol, tanpa menunggu timer nyata panjang.

### MOB-AUTH-01 — Refresh token single-flight

Backend merotasi refresh token. Satu refresh token lama hanya boleh digunakan sekali; reuse dapat mencabut seluruh session family.

**Risiko:** beberapa request paralel menerima `401`, lalu masing-masing mencoba refresh menggunakan token lama yang sama.

**Solusi minimum:**

- Maksimal satu request `/auth/refresh` berjalan pada satu waktu.
- Request lain menunggu Future refresh yang sama.
- Setelah sukses, semua retry memakai access token baru.
- Simpan access dan refresh token baru sebelum retry request asli.
- Jika refresh gagal/reuse terdeteksi, bersihkan token sekali dan arahkan user ke login sekali.
- Jangan melakukan refresh untuk request login, register, refresh, atau logout.
- Gunakan shared `Future`/mutex eksplisit; `QueuedInterceptorsWrapper` saja bukan bukti single-flight.
- Tandai request yang sudah di-retry agar response `401` kedua tidak membentuk loop.
- Pertahankan origin/base URL tenant yang memiliki refresh token selama refresh dan retry; perubahan tenant tidak boleh mengirim token ke origin lain.

**Acceptance criteria:**

- Dua request paralel yang menerima `401` menghasilkan tepat satu request refresh.
- Kedua request asli di-retry menggunakan access token baru.
- Refresh gagal membersihkan token tanpa loop `401`.
- Logout/navigation akibat session expiry hanya dipicu sekali walaupun beberapa request gagal bersamaan.
- Request login, register, refresh, dan logout tidak pernah memicu refresh otomatis.
- Retry tidak menggandakan mutasi non-idempoten secara diam-diam; request mutasi hanya diulang setelah terbukti gagal karena autentikasi sebelum diproses.

### MOB-AUTH-02 — Satu kontrak refresh token

Backend menerima:

```http
POST /api/v1/auth/refresh
Content-Type: application/json

{"refresh_token":"..."}
```

Interceptor mobile sudah memakai body tersebut. `AuthRemoteDataSource.refreshToken()` masih mengirim refresh token sebagai Bearer header.

**Solusi minimum:** pilih satu jalur refresh. Prefer hapus method manual yang tidak dipakai; jika tetap dibutuhkan, kirim `refresh_token` dalam body dan parse envelope `data` yang sama.

**Acceptance criteria:**

- Tidak ada refresh token dikirim sebagai Bearer access token.
- Seluruh jalur refresh menyimpan token hasil rotasi.
- Tidak ada dua implementasi refresh dengan parsing response berbeda.
- Method `AuthRemoteDataSource.refreshToken()` dihapus jika tidak memiliki pemanggil; dead code tidak dipertahankan sebagai compatibility layer.

### MOB-PPDB-01 — Hapus PPDB dari mobile

**Yang dihapus:**

- direktori `lib/features/ppdb/`;
- import, konstanta, permission mapping, dan route PPDB di `lib/core/router/app_router.dart`;
- registrasi PPDB di `lib/core/di/injection.dart`;
- tombol portal PPDB pada `lib/features/auth/presentation/pages/login_page.dart`;
- menu PPDB pada shell/menu konfigurasi;
- test dan dokumentasi yang menyatakan PPDB tersedia di mobile.
- quick action, kartu/ringkasan dashboard, tipe navigasi notifikasi, permission, label, aset, dan parser khusus PPDB yang hanya melayani fitur mobile PPDB.

**Yang tidak dibuat:** client endpoint enrollment, state machine PPDB, form wali, form kelas, atau compatibility layer PPDB.

**Acceptance criteria:**

- Pencarian case-insensitive `ppdb` pada `lib/` dan `test/` menghasilkan nol referensi fitur. Data backend generik tidak boleh dipakai untuk mempertahankan menu, kartu, navigasi, permission, atau UI PPDB.
- Login tidak menawarkan portal PPDB.
- Route `/ppdb` dan `/ppdb/portal` tidak terdaftar.
- Build tree-shaking tidak membawa kode/aset khusus PPDB.
- PPDB tetap tersedia melalui aplikasi web tanpa perubahan backend.

### MOB-DASH-01 — Selaraskan kontrak dashboard guru

`dashboard-engine` mengirim `summary.total_mapel`; widget guru masih membaca `total_mata_pelajaran`.

**Solusi minimum:** baca `total_mapel` sebagai field authoritative. `total_mata_pelajaran` boleh menjadi fallback legacy sementara hanya jika fixture Laravel lama masih membutuhkannya.

**Acceptance criteria:**

- payload Go `{"summary":{"total_mapel":7}}` menampilkan `7`, bukan `0`;
- fallback legacy tetap teruji bila dipertahankan;
- widget test memakai fixture dashboard Go aktual;
- komentar/model tidak menyatakan field legacy sebagai kontrak utama.

### MOB-DASH-02 — Hapus PPDB dari dashboard mobile

Hapus field/parser `ppdb`, pembacaan `ppdb_summary`, kartu PPDB admin, quick action, permission, dan test terkait dari mobile. Backend dashboard/statistik boleh mempertahankan PPDB untuk web; mobile wajib mengabaikannya tanpa compatibility UI.

**Acceptance criteria:** fixture admin yang masih memuat field PPDB tidak menampilkan UI PPDB; pencarian case-insensitive `ppdb` pada `lib/` dan `test/` tetap kosong; dashboard non-PPDB tidak berubah.

### MOB-EWS-01 — Detail alert authoritative

Mobile saat ini mencari detail ID melalui halaman pertama `GET /ews/alerts` yang default-nya 20 item. Alert di luar halaman pertama dianggap tidak ditemukan.

**Solusi minimum:** tambahkan endpoint backend detail canonical yang tidak ambigu, misalnya `GET /api/v1/ews/alerts/detail/{id}`, dengan authorization `API-EWS-01`; ubah mobile memakai endpoint tersebut. Hindari mengunduh seluruh pagination hanya untuk satu detail.

Perbarui dokumentasi repository mobile yang masih menyebut endpoint legacy `GET /ews/{id}`, `PUT /ews/{id}/resolve`, dan `POST /ews/{siswaId}/trigger` agar sesuai dengan route Go aktual.

**Acceptance criteria:**

- detail alert ditemukan walau tidak masuk halaman pertama;
- detail di luar scope menghasilkan `403/404` sesuai kebijakan tanpa fallback list;
- resolve tetap memakai `PATCH /ews/alerts/{id}/resolve`;
- trigger tetap memakai `POST /ews/process-siswa/{siswaId}`;
- contract test memakai fixture Go aktual, termasuk field opsional yang memang tidak dikirim backend.

### MOB-QA-01 — Contract dan integration test

Test minimum:

1. Parsing empat status sesi ujian.
2. Parsing `nilai_akhir: null` dan `nilai_provisional`.
3. UI `awaiting_grading` tanpa tombol mulai/selesai.
4. Deadline menonaktifkan input dan memuat ulang sesi.
5. Dua response `401` paralel menghasilkan satu refresh.
6. Refresh gagal membersihkan session tanpa loop.
7. Checkout ditutup lalu status pembayaran dimuat ulang.
8. Tidak ada route/menu PPDB.
9. Request login, register, refresh, dan logout tidak memicu refresh otomatis.
10. Retry yang kembali menerima `401` berhenti, membersihkan session sekali, dan tidak loop.
11. Countdown memakai waktu terkontrol plus offset server; perubahan jam perangkat tidak membuka input kembali.
12. Self check-in memakai endpoint canonical dan riwayat dimuat ulang.
13. Dashboard guru menampilkan `total_mapel` dari fixture Go.
14. Dashboard mobile mengabaikan payload PPDB tanpa menampilkan UI.
15. Detail EWS di luar halaman pertama tetap dapat dimuat melalui endpoint detail.
16. Response `403` dari absensi/EWS/dashboard ditampilkan sebagai akses ditolak tanpa retry refresh.

Contract fixture harus berasal dari response backend aktual, bukan payload buatan berdasarkan asumsi mobile.

### API-QA-01 — Contract dan authorization test backend

Status `go test ./...` bukan gate yang cukup ketika package handler/middleware tidak memiliki test. Tambahkan test minimum:

1. matrix role/permission/resource/tenant untuk `absensi-worker`;
2. permission analytics dan kontrak role dashboard untuk `dashboard-engine`;
3. process/list/detail/resolve EWS untuk role berizin dan tidak berizin;
4. permission semua endpoint sensitif serta validasi filter `400` pada `statistik-engine`;
5. role canonical dan tenant isolation shared pada seluruh service;
6. fixture response yang dikonsumsi test kontrak Flutter;
7. negative test direct URL/IDOR; menyembunyikan menu mobile tidak dihitung sebagai test keamanan.

Semua service wajib memiliki test nyata pada handler/middleware atau integration layer yang membuktikan status HTTP dan scope data, bukan hanya test repository happy path.

---

## 7. P2 — Penyempurnaan

### MOB-PAY-01 — Rekonsiliasi pembayaran setelah checkout

PAY-01 sampai PAY-05 tidak mengubah endpoint mobile secara breaking. Mobile tetap menerima:

```json
{
  "pembayaran_id": 12,
  "checkout_url": "https://...",
  "midtrans_order_id": "..."
}
```

Alias `redirect_url` dan `order_id` boleh tetap dipertahankan untuk kompatibilitas.

**Aturan UI:**

- redirect, kembalinya aplikasi dari browser eksternal, atau penutupan WebView bukan bukti pembayaran lunas;
- setelah kembali dari checkout, muat ulang obligation/status dari backend;
- tampilkan pending sampai webhook tervalidasi mengubah status;
- retry checkout dapat menghasilkan payment attempt/order ID baru;
- jangan menyimpan asumsi satu obligation selalu memiliki satu order ID.
- implementasi wajib menangani lifecycle aplikasi `resumed` untuk checkout browser eksternal dan hasil penutupan untuk checkout WebView bila jalur tersebut tersedia;
- refresh/poll harus memiliki batas, dapat dibatalkan saat halaman ditutup, dan tidak boleh membentuk loop tanpa akhir.

**Acceptance criteria:**

- Menutup checkout tidak menandai pembayaran lunas secara lokal.
- Kembali dari browser eksternal atau WebView memicu pengambilan ulang obligation/status dari backend.
- Settlement webhook terlihat setelah refresh/poll status.
- Callback tertunda tetap menampilkan pending, bukan gagal permanen.
- Test lifecycle membuktikan resume/penutupan checkout melakukan refresh tanpa mengubah status menjadi lunas secara lokal.

### MOB-TENANT-01 — Tenant eksplisit untuk superadmin

User sekolah biasa tetap memakai tenant dari base URL tervalidasi. Untuk superadmin lintas sekolah:

- tenant target wajib dipilih sebelum membuka data tenant;
- request global tetap memakai endpoint global;
- jangan mengandalkan `mst_sekolah_id=null`;
- perpindahan tenant harus membersihkan cache/state data tenant sebelumnya;
- refresh token harus tetap dikirim ke origin yang benar.

**Keputusan produk untuk implementasi ini:** superadmin lintas tenant adalah **web-only**. Jangan menambah flow pemilih tenant superadmin atau akses data lintas sekolah pada mobile.

Implementasi mobile tetap wajib:

- menolak atau tidak menampilkan entry point data tenant untuk role superadmin;
- mendokumentasikan batasan superadmin lintas tenant sebagai web-only pada README/dokumentasi role;
- membersihkan cache/state data tenant saat user sekolah biasa berpindah tenant atau logout;
- mengikat access token dan refresh token ke origin tenant tempat token diterbitkan;
- membersihkan session dan meminta login ulang, bukan mengirim refresh token ke origin berbeda, jika origin tenant aktif tidak cocok dengan origin token;
- menyediakan test bahwa perpindahan tenant tidak membawa state tenant lama dan tidak mengirim refresh token lintas origin.

---

## 8. Tidak Perlu Diubah

| Backend item | Alasan |
|---|---|
| PAY-01 | Tenant webhook diselesaikan server-side; mobile tidak menerima webhook |
| PAY-02 | Retry merupakan kontrak provider ke backend |
| PAY-03 | Validasi callback dan transisi monotonic server-side |
| PAY-04 | Parser checkout mobile sudah mendukung field response yang dibutuhkan |
| PAY-05 | Deduplikasi webhook/event server-side |
| EXAM-01 | Mobile tetap memakai satu base URL; reverse proxy memilih `exam-engine` |
| EXAM-02 | Perubahan denominator memperbaiki hasil; format response tidak harus berubah |
| EXAM-04 | Otorisasi assignment ditegakkan server; mobile cukup menangani `403` standar |
| AUTH-02 | Logout satu device mobile sudah mengirim access Bearer token dan membersihkan storage |
| PPDB-01–06 | PPDB web-only; seluruh modul mobile dihapus |
| STAT mobile | Mobile belum memiliki requirement statistik global; jangan membuat feature/client `/statistik/*` baru |
| EWS parser nullable | `data_pendukung` dan `resolved_by` boleh tetap nullable; Go saat ini tidak wajib mengirim field tersebut |

---

## 9. Urutan Implementasi

### Tahap 1 — Tutup celah authorization backend

1. API-AUTHZ-01
2. API-ABS-01
3. API-EWS-01
4. API-DASH-01
5. API-STAT-01

### Tahap 2 — Pulihkan kontrak P0 mobile

1. MOB-ABS-01
2. MOB-EXAM-01
3. MOB-EXAM-02
4. MOB-EXAM-03

### Tahap 3 — Amankan sesi

1. MOB-AUTH-01
2. MOB-AUTH-02

### Tahap 4 — Selaraskan dashboard dan EWS

1. MOB-DASH-01
2. MOB-EWS-01

### Tahap 5 — Kurangi scope

1. MOB-PPDB-01
2. MOB-DASH-02
3. Perbarui README dan dokumentasi modul

### Tahap 6 — Hardening dan QA

1. MOB-PAY-01
2. MOB-TENANT-01 dengan keputusan superadmin lintas tenant web-only dan hardening origin/cache mobile
3. API-QA-01
4. MOB-QA-01

---

## 10. Definition of Done

Perbaikan mobile selesai jika:

- tidak ada referensi atau route PPDB di aplikasi mobile;
- self check-in siswa memakai route backend canonical, identity server-side, idempotensi, dan tenant isolation;
- list/detail/rentang/rekap/mutasi absensi menegakkan scope role dan resource;
- empat state ujian backend tampil benar;
- nilai provisional tidak pernah dipresentasikan sebagai nilai final;
- deadline server menutup input dan menyinkronkan sesi;
- request paralel hanya memicu satu refresh token;
- logout/refresh tidak membentuk loop `401`;
- status pembayaran selalu direkonsiliasi ke backend setelah checkout;
- dashboard guru menampilkan `total_mapel` dan tidak menampilkan PPDB;
- endpoint analytics dashboard menegakkan permission;
- EWS process/list/detail/resolve menegakkan permission dan resource scope;
- detail EWS mobile tidak bergantung pada halaman pertama;
- seluruh endpoint statistik sensitif menegakkan permission dan filter invalid menghasilkan `400`;
- lima service Go memakai role canonical dan tenant enforcement konsisten;
- superadmin lintas tenant terdokumentasi web-only dan tidak memiliki entry point data tenant pada mobile;
- perpindahan tenant/logout membersihkan state tenant lama dan token tidak pernah dikirim lintas origin;
- `flutter analyze` lulus tanpa issue;
- `flutter test` lulus;
- test kontrak baru mencakup auth, ujian, absensi, dashboard, dan EWS;
- test authorization backend mencakup positive/negative matrix, IDOR, filter invalid, bulk atomicity, dan cross-tenant;
- smoke test device mencakup login, refresh, check-in, riwayat absensi, dashboard guru, detail/resolve EWS sesuai permission, mulai ujian, submit, timeout, awaiting grading, hasil final, dan pembayaran online.

Perintah validasi:

```bash
cd /Users/bodo/www/akademihub_repo/akademihub_mob
flutter analyze
flutter test
grep -RIni --exclude-dir=.dart_tool --exclude-dir=build 'ppdb' lib test

cd /Users/bodo/www/akademihub_repo/sekolah_go/exam-engine && go test ./...
cd /Users/bodo/www/akademihub_repo/sekolah_go/absensi-worker && go test ./...
cd /Users/bodo/www/akademihub_repo/sekolah_go/dashboard-engine && go test ./...
cd /Users/bodo/www/akademihub_repo/sekolah_go/ews-worker && go test ./...
cd /Users/bodo/www/akademihub_repo/sekolah_go/statistik-engine && go test ./...
```

Hasil `grep` terakhir wajib kosong. Setelah validasi otomatis, lakukan smoke test pada device/emulator. Jika backend fixture/service tersedia secara lokal, jalankan juga test backend relevan untuk memastikan fixture kontrak belum menyimpang.

---

## 11. Baseline Audit

Pada 16 Agustus 2026 sebelum implementasi dokumen ini:

```text
flutter analyze: lulus, tanpa issue
flutter test: 27 test lulus
```

Baseline tersebut belum mencakup kontrak status ujian terbaru, refresh paralel, atau keputusan PPDB web-only. Jumlah test bukan gate; skenario pada dokumen ini yang menjadi gate.

Baseline backend tambahan:

```text
exam-engine: go test ./... lulus; repository/service memiliki sebagian test
absensi-worker: go test ./... lulus; hanya sebagian service memiliki test
dashboard-engine: go test ./... lulus; tidak ada test package
ews-worker: go test ./... lulus; tidak ada test package
statistik-engine: go test ./... lulus; tidak ada test package
```

Kelulusan tersebut terutama membuktikan build. Baseline belum membuktikan authorization handler, permission, IDOR, tenant isolation, filter invalid, endpoint self check-in, atau kontrak detail EWS.