# Codex Task - API Endpoint & Permission Audit Remediation

## Source of Truth

Dokumen ini dibuat dari **API_AUDIT_ENDPOINTS_PERMISSIONS.pdf** (audit 2026-08-26) untuk dijadikan work specification yang bisa langsung dikerjakan oleh Codex di repository AkademiHub / Sekolah Pintar.

> Penting: jangan menganggap angka ringkasan di PDF selalu konsisten dengan daftar route di bawah. **Baris endpoint/route individual adalah referensi utama**, lalu cocokkan dengan route yang benar-benar terdaftar di source code. Bila ada konflik, jangan menebak - catat sebagai discrepancy.

## Objective

Audit dan rapikan autentikasi/otorisasi seluruh API agar implementasi route, middleware, role access, permission key, tenant isolation, serta owner/self access sesuai dengan matriks audit dalam dokumen ini.

Target sistem yang tercakup:

- Laravel backend: `sekolah/src`
- Go Exam Engine: `sekolah_go/exam-engine`
- Go Absensi Worker: `sekolah_go/absensi-worker`
- Go Dashboard Engine: `sekolah_go/dashboard-engine`
- Go Statistik Engine: `sekolah_go/statistik-engine`
- Go EWS Worker: `sekolah_go/ews-worker`

## Mobile Implementation Evidence (2026-08-26)

- `akademihub_mob` stores login token origin from the active tenant Dio base URL, then validates the stored origin before token attachment or refresh.
- A `401` refreshes credentials once, but automatic replay is limited to `GET`, `HEAD`, and `OPTIONS`; writes return their original `401` after refresh because no idempotency contract is available.
- HTTP `403` maps to `ForbiddenException`/`ForbiddenFailure`, preserving the backend message. Backend enforcement remains required.
- EWS alert detail now uses `GET /ews/{id}`. `GET /ews/alerts` remains the alert list endpoint with `mst_siswa_id` filtering.
- Existing verified client gates remain limited to keys readable from the audit/current source. Laravel Akademik route permissions are `UNRESOLVED_FROM_AUDIT`; no keys were inferred.
- Mobile client checks are UX only. Tenant isolation, owner/self controls, JWT authorization, and write idempotency require backend integration tests.
- Mobile discrepancy: client uses `GET /dashboard/`; audit lists `GET /dashboard`.

## Non-Negotiable Rules

1. **Jangan ubah API contract tanpa alasan audit yang jelas.** Pertahankan HTTP method, URL path, parameter route, response shape, dan controller/handler behavior kecuali perubahan memang diperlukan untuk memperbaiki authorization.
2. **Jangan mengarang permission.** Jika sebuah row di audit tidak menampilkan permission/role dengan jelas, inspect route definition, middleware, policy/gate, permission seeder, role-permission mapping, dan test yang ada. Catat sebagai `UNRESOLVED_FROM_AUDIT` bila source of truth tetap tidak cukup.
3. **Public route harus tetap public** jika audit menandainya `Public (No Auth)`. Jangan menambahkan login requirement hanya karena endpoint terlihat sensitif. Untuk webhook publik, validasi signature/provider secret hanya jika memang merupakan mekanisme yang didukung implementasi/provider saat ini.
4. Untuk route bertanda `auth:jwt`, pastikan token wajib dan role restriction sesuai daftar role di audit.
5. Untuk route bertanda `auth:api (Tenant JWT)`, pastikan autentikasi tenant berlaku dan data tidak bocor lintas tenant.
6. Untuk permission Laravel seperti `siswa.view`, `kelas.create`, `reports.generate`, dan seterusnya, gunakan mekanisme permission project yang sudah ada; jangan membuat sistem authorization paralel.
7. Rule `[owner]` atau `[self]` harus benar-benar mengecek ownership/self pada resource, bukan hanya role.
8. Unauthorized user harus ditolak konsisten. Bedakan unauthenticated (`401`) dengan authenticated-but-forbidden (`403`) sesuai conventions project.
9. Hindari N+1 permission lookup atau query authorization yang tidak perlu pada hot path.
10. Jangan menghapus middleware/security check yang sudah lebih ketat kecuali audit secara eksplisit menunjukkan bahwa check tersebut salah dan perubahan aman dapat dibuktikan dengan test.
11. Semua perubahan security-sensitive wajib ditutup dengan test.

## Count Discrepancy - Wajib Diverifikasi

PDF menyebut ringkasan **577 API endpoints** dan **582 routes termasuk 5 health checks**, tetapi beberapa jumlah per-service di ringkasan dan jumlah route pada section detail tidak konsisten. Contohnya section detail menyebut Exam Engine 23 routes, Absensi Worker 32 routes, Dashboard Engine 7 routes, Statistik Engine 13 routes, dan EWS Worker 10 routes.

Codex harus:

- Generate actual route inventory dari source code sebelum edit.
- Bandingkan actual inventory dengan daftar endpoint pada audit.
- Laporkan `missing_in_code`, `extra_in_code`, `method_or_path_mismatch`, `permission_mismatch`, dan `audit_count_mismatch`.
- Jangan memaksa source code mengikuti angka ringkasan jika daftar route individual menunjukkan hal berbeda.

## Execution Plan

### Phase 1 - Inventory

- [ ] Enumerate seluruh Laravel routes yang relevan, termasuk middleware stack per route.
- [ ] Enumerate seluruh route tiap Go service dan middleware/auth wrapper-nya.
- [ ] Buat mapping: `method + path -> controller/handler -> current auth -> current permission/roles`.
- [ ] Cocokkan mapping dengan audit reference pada bagian akhir file ini.
- [ ] Buat discrepancy report sebelum melakukan perubahan massal.

### Phase 2 - Fix Authentication & Authorization

Kerjakan per service/module agar perubahan mudah direview.

- [ ] Go Exam Engine
- [ ] Go Absensi Worker
- [ ] Go Dashboard Engine
- [ ] Go Statistik Engine
- [ ] Go EWS Worker
- [ ] Laravel HEALTH / AUTH
- [ ] Laravel PPDB
- [ ] Laravel LANDING / NOTIFIKASI / FCM / MENUS / FILES
- [ ] Laravel KELAS / MAPEL / GURU / GURU-MAPEL / SISWA / WALI
- [ ] Laravel JADWAL-PELAJARAN
- [ ] Laravel BK / EWS
- [ ] Laravel PERPUSTAKAAN
- [ ] Laravel AKADEMIK
- [ ] Laravel SEKOLAH
- [ ] Laravel ADMIN
- [ ] Laravel KEUANGAN
- [ ] Laravel SPK
- [ ] Laravel EKSTRAKURIKULER
- [ ] Laravel ORGANISASI
- [ ] Laravel ABSENSI-SISWA
- [ ] Laravel REPORTS
- [ ] Laravel WHATSAPP / EMAIL
- [ ] Laravel WEBHOOK / WEBHOOKS
- [ ] Laravel CHATBOT / BROADCASTING

### Phase 3 - Tests

Untuk setiap kategori access, tambahkan/rapikan test minimal berikut:

- [ ] Public endpoint dapat diakses tanpa token bila audit menyatakan public.
- [ ] Protected endpoint tanpa token menghasilkan unauthorized.
- [ ] Role/permission yang benar berhasil.
- [ ] Role/permission yang salah menghasilkan forbidden.
- [ ] Owner/self resource access berhasil untuk pemiliknya sendiri.
- [ ] Owner/self access ke resource user lain ditolak.
- [ ] Tenant A tidak dapat membaca/mengubah resource Tenant B.
- [ ] Write endpoints (`POST`, `PUT`, `PATCH`, `DELETE`) mempunyai negative authorization test.
- [ ] Permission-sensitive bulk/import/generate/export endpoints mempunyai test khusus.

### Phase 4 - Final Verification

- [ ] Re-enumerate routes setelah perubahan.
- [ ] Pastikan tidak ada route audit yang terlewat.
- [ ] Jalankan test suite terkait authorization.
- [ ] Jalankan lint/static analysis/test command yang tersedia di repo.
- [ ] Pastikan tidak ada credential/secret yang ditambahkan ke source.
- [ ] Buat laporan final perubahan dan discrepancy yang belum dapat diputuskan dari audit.

## Required Final Report From Codex

Saat selesai, berikan ringkasan dalam format:

```text
STATUS: completed | partially_completed

CHANGED:
- <service/module>: <what changed>

TESTS:
- <command>: PASS/FAIL

DISCREPANCIES:
- <method> <path>: <audit vs source difference>

UNRESOLVED_FROM_AUDIT:
- <method> <path>: <why it cannot be safely inferred>

SECURITY NOTES:
- <owner/self, tenant isolation, webhook, or other relevant note>
```

## Audit Module Inventory

### Go services

| Service | Detail section count |
|---|---:|
| Exam Engine - port 8084 | 23 routes |
| Absensi Worker - port 8083 | 32 routes |
| Dashboard Engine - port 8081 | 7 routes |
| Statistik Engine - port 8082 | 13 routes |
| EWS Worker - port 8085 | 10 routes |

### Laravel modules

| Module | Audit count |
|---|---:|
| HEALTH | 2 |
| AUTH | 4 |
| PPDB | 60 |
| LANDING | 1 |
| NOTIFIKASI | 4 |
| FCM | 2 |
| MENUS | 1 |
| FILES | 3 |
| KELAS | 9 |
| MAPEL | 7 |
| GURU | 8 |
| GURU-MAPEL | 8 |
| SISWA | 14 |
| WALI | 7 |
| JADWAL-PELAJARAN | 7 |
| BK | 40 |
| EWS | 4 |
| PERPUSTAKAAN | 16 |
| AKADEMIK | 104 |
| SEKOLAH | 16 |
| ADMIN | 77 |
| KEUANGAN | 20 |
| SPK | 20 |
| EKSTRAKURIKULER | 18 |
| ORGANISASI | 22 |
| ABSENSI-SISWA | 4 |
| REPORTS | 9 |
| WHATSAPP | 9 |
| EMAIL | 5 |
| WEBHOOK | 3 |
| WEBHOOKS | 1 |
| CHATBOT | 2 |
| BROADCASTING | 1 |

## How to Use the Reference Below

1. Cari endpoint dengan kombinasi **HTTP method + path**.
2. Cocokkan controller/handler.
3. Terapkan required permission/role yang tertulis bila kolom tersebut tersedia.
4. Jika permission tidak tercetak/terbaca pada audit, **jangan infer hanya dari nama endpoint**. Gunakan existing permission model dan tandai discrepancy/unresolved.
5. Raw reference dipertahankan sedekat mungkin dengan layout PDF agar detail endpoint tidak hilang saat konversi.

---

# Full Audit Reference

## PDF Page 1

```text
AUDIT LENGKAP ENDPOINT API & PERMISSIONS
AkademiHub / Sekolah Pintar System Ecosystem
  Tanggal Audit: 2026-08-26 04:24:29
  Total Endpoint API: 577 Endpoints (508 Laravel API + 69 Go Microservices + 5 Health Checks)
Ringkasan Eksekutif
 Komponen / Service                                    Kategori                         Total Endpoints
 Laravel Backend ( sekolah/src )                       Monolith API & Tenant Core       508
 Exam Engine ( sekolah_go/exam-engine )                High Concurrency Exam Service    23
 Absensi Worker ( sekolah_go/absensi-worker )          Attendance & Geofencing          28
                                                       Service
 Dashboard Engine ( sekolah_go/dashboard-              Aggregate Analytics Dashboard    6
 engine )

 Statistik Engine ( sekolah_go/statistik-engine )      Deep Data Analytics & Reporting 12
 EWS Worker ( sekolah_go/ews-worker )                  Early Warning Alert Processing 9
 Health Checks                                         Microservices Monitoring        5
 GRAND TOTAL                                                                           582 Routes (577 Endpoints
                                                                                       API)


Bagian 1: Microservices Go Engine (69 Endpoints + 5 Health Checks)
Exam Engine (Go - Port 8084) (23 routes)
 HTTP        Path / Endpoint                                  Handler / Action                  Required Permission
 Method                                                                                         / Role Access
 GET          /health                                         Health                            Public (No Auth)

 GET          /api/v1/akademik/ujian                          UjianHandler@Index                auth:jwt (Role:
                                                                                                admin, guru,
                                                                                                siswa)

 POST         /api/v1/akademik/ujian                          UjianHandler@Store                auth:jwt (Role:
                                                                                                admin, guru)

 GET          /api/v1/akademik/ujian/kelas/{kelasId}          UjianHandler@ByKelas              auth:jwt (Role:
                                                                                                admin, guru,
                                                                                                siswa)

 GET          /api/v1/akademik/ujian/{id}/nilai               UjianHandler@Nilai                auth:jwt (Role:
                                                                                                admin, guru, wali)

 GET          /api/v1/akademik/ujian/{id}                     UjianHandler@Show                 auth:jwt (Role:
                                                                                                admin, guru,
                                                                                                siswa)

 PUT          /api/v1/akademik/ujian/{id}                     UjianHandler@Update               auth:jwt (Role:
                                                                                                admin, guru)
```

## PDF Page 2

```text
 DELETE    /api/v1/akademik/ujian/{id}              UjianHandler@Destroy          auth:jwt (Role:
                                                                                  admin, guru)

 GET       /api/v1/akademik/ujian-user              UjianUserHandler@Index        auth:jwt (Role:
                                                                                  admin, guru,
                                                                                  siswa)

 POST      /api/v1/akademik/ujian-user              UjianUserHandler@Store        auth:jwt (Role:
                                                                                  admin, guru)

 GET       /api/v1/akademik/ujian-user/{id}         UjianUserHandler@Show         auth:jwt (Role:
                                                                                  admin, guru,
                                                                                  siswa)

 GET       /api/v1/akademik/ujian-user/{id}/soal    UjianUserHandler@Soal         auth:jwt (Role:
                                                                                  siswa [owner],
                                                                                  guru, admin)


 PUT       /api/v1/akademik/ujian-user/{id}         UjianUserHandler@Update       auth:jwt (Role:
                                                                                  admin, guru)

 DELETE    /api/v1/akademik/ujian-user/{id}         UjianUserHandler@Destroy      auth:jwt (Role:
                                                                                  admin, guru)

 POST      /api/v1/akademik/ujian-user/{id}/mulai   UjianUserHandler@Mulai        auth:jwt (Role:
                                                                                  siswa [owner])

 POST      /api/v1/akademik/ujian-                  UjianUserHandler@Selesaikan   auth:jwt (Role:
          user/{id}/selesaikan                                                    siswa [owner])

 POST      /api/v1/akademik/ujian-                  UjianUserHandler@Violation    auth:jwt (Role:
          user/{id}/violation                                                     siswa [owner])

 GET       /api/v1/akademik/ujian-jawaban           UjianJawabanHandler@Index     auth:jwt (Role:
                                                                                  admin, guru,
                                                                                  siswa)


 POST      /api/v1/akademik/ujian-jawaban           UjianJawabanHandler@Store     auth:jwt (Role:
                                                                                  siswa [owner])

 GET       /api/v1/akademik/ujian-jawaban/{id}      UjianJawabanHandler@Show      auth:jwt (Role:
                                                                                  admin, guru, siswa
                                                                                  [owner])

 PUT       /api/v1/akademik/ujian-jawaban/{id}      UjianJawabanHandler@Update    auth:jwt (Role:
                                                                                  siswa [owner])

 PATCH     /api/v1/akademik/ujian-                  UjianJawabanHandler@Koreksi   auth:jwt (Role:
          jawaban/{id}/koreksi                                                    admin, guru)

 DELETE    /api/v1/akademik/ujian-jawaban/{id}      UjianJawabanHandler@Destroy   auth:jwt (Role:
                                                                                  admin, guru)


Absensi Worker (Go - Port 8083) (32 routes)
 HTTP Path / Endpoint                                       Handler / Action                       Required
 Method                                                                                            Permission
                                                                                                   / Role
                                                                                                   Access
 GET      /health                                            Health                                Public
                                                                                                   (No Auth)
```

## PDF Page 3

```text
GET    /api/v1/akademik/absensi-siswa                   AbsensiSiswaHandler@Index          auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru,
                                                                                           wali,
                                                                                           siswa)

POST   /api/v1/akademik/absensi-siswa                   AbsensiSiswaHandler@Store          auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru)

POST   /api/v1/akademik/absensi-siswa/check-in          AbsensiSiswaHandler@CheckIn        auth:jwt
                                                                                           (Role:
                                                                                           siswa
                                                                                           [self],
                                                                                           guru,
                                                                                           admin)

POST   /api/v1/akademik/absensi-siswa/bulk              AbsensiSiswaHandler@BulkStore      auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru)

POST   /api/v1/akademik/absensi-siswa/date-range        AbsensiSiswaHandler@DateRange      auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru,
                                                                                           wali,
                                                                                           siswa)


GET    /api/v1/akademik/absensi-siswa/summary           AbsensiSiswaHandler@Summary        auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru)

GET    /api/v1/akademik/absensi-siswa/rekap-bulanan     AbsensiSiswaHandler@RekapBulanan   auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru)

GET    /api/v1/akademik/absensi-siswa/siswa/{siswaId}   AbsensiSiswaHandler@BySiswa        auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru,
                                                                                           wali,
                                                                                           siswa)

GET    /api/v1/akademik/absensi-siswa/{id}              AbsensiSiswaHandler@Show           auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru,
                                                                                           wali,
                                                                                           siswa)

PUT    /api/v1/akademik/absensi-siswa/{id}              AbsensiSiswaHandler@Update         auth:jwt
                                                                                           (Role:
                                                                                           admin,
                                                                                           guru)
```

## PDF Page 4

```text
DELETE   /api/v1/akademik/absensi-siswa/{id}           AbsensiSiswaHandler@Destroy       auth:jwt
                                                                                         (Role:
                                                                                         admin,
                                                                                         guru)

GET      /api/v1/akademik/absensi-guru                 AbsensiGuruHandler@Index          auth:jwt
                                                                                         (Role:
                                                                                         admin,
                                                                                         guru)

POST     /api/v1/akademik/absensi-guru                 AbsensiGuruHandler@Store          auth:jwt
                                                                                         (Role:
                                                                                         admin,
                                                                                         guru)

POST     /api/v1/akademik/absensi-guru/bulk            AbsensiGuruHandler@BulkStore      auth:jwt
                                                                                         (Role:
                                                                                         admin)

GET      /api/v1/akademik/absensi-guru/summary         AbsensiGuruHandler@Summary        auth:jwt
                                                                                         (Role:
                                                                                         admin)

GET      /api/v1/akademik/absensi-guru/rekap-bulanan   AbsensiGuruHandler@RekapBulanan   auth:jwt
                                                                                         (Role:
                                                                                         admin)

GET      /api/v1/akademik/absensi-guru/guru/{guruId}   AbsensiGuruHandler@ByGuru         auth:jwt
                                                                                         (Role:
                                                                                         admin,
                                                                                         guru
                                                                                         [self])


GET      /api/v1/akademik/absensi-guru/{id}            AbsensiGuruHandler@Show           auth:jwt
                                                                                         (Role:
                                                                                         admin,
                                                                                         guru
                                                                                         [self])

PUT      /api/v1/akademik/absensi-guru/{id}            AbsensiGuruHandler@Update         auth:jwt
                                                                                         (Role:
                                                                                         admin)

DELETE   /api/v1/akademik/absensi-guru/{id}            AbsensiGuruHandler@Destroy        auth:jwt
                                                                                         (Role:
                                                                                         admin)

GET      /api/v1/akademik/presensi                     PresensiHandler@Index             auth:jwt
                                                                                         (Role:
                                                                                         admin,
                                                                                         guru)

POST     /api/v1/akademik/presensi                     PresensiHandler@Store             auth:jwt
                                                                                         (Role:
                                                                                         admin,
                                                                                         guru)

POST     /api/v1/akademik/presensi/bulk                PresensiHandler@BulkStore         auth:jwt
                                                                                         (Role:
                                                                                         admin,
                                                                                         guru)
```

## PDF Page 5

```text
 GET      /api/v1/akademik/presensi/rekap                        PresensiHandler@Rekap                auth:jwt
                                                                                                      (Role:
                                                                                                      admin,
                                                                                                      guru)

 GET      /api/v1/akademik/presensi/date                         PresensiHandler@ByDate               auth:jwt
                                                                                                      (Role:
                                                                                                      admin,
                                                                                                      guru)

 GET      /api/v1/akademik/presensi/guru-                        PresensiHandler@ByGuruMapel          auth:jwt
          mapel/{guru_mapel_id}                                                                       (Role:
                                                                                                      admin,
                                                                                                      guru)

 GET      /api/v1/akademik/presensi/siswa/{siswa_id}             PresensiHandler@BySiswa              auth:jwt
                                                                                                      (Role:
                                                                                                      admin,
                                                                                                      guru,
                                                                                                      wali,
                                                                                                      siswa)

 GET      /api/v1/akademik/presensi/siswa/{siswa_id}/summary     PresensiHandler@SummaryBySiswa       auth:jwt
                                                                                                      (Role:
                                                                                                      admin,
                                                                                                      guru,
                                                                                                      wali,
                                                                                                      siswa)

 GET      /api/v1/akademik/presensi/{id}                         PresensiHandler@Show                 auth:jwt
                                                                                                      (Role:
                                                                                                      admin,
                                                                                                      guru)

 PUT      /api/v1/akademik/presensi/{id}                         PresensiHandler@Update               auth:jwt
                                                                                                      (Role:
                                                                                                      admin,
                                                                                                      guru)

 DELETE   /api/v1/akademik/presensi/{id}                         PresensiHandler@Destroy              auth:jwt
                                                                                                      (Role:
                                                                                                      admin,
                                                                                                      guru)


Dashboard Engine (Go - Port 8081) (7 routes)
HTTP Path / Endpoint                        Handler / Action                               Required
Method                                                                                     Permission /
                                                                                           Role Access
 GET      /health                           Health                                         Public (No
                                                                                           Auth)

 GET      /api/v1/dashboard                 DashboardHandler@Index                         auth:jwt
                                                                                           (Role: admin)

 GET      /api/v1/dashboard/summary-        DashboardHandler@SummaryCards                  auth:jwt
          cards                                                                            (Role: admin,
                                                                                           guru, wali,
                                                                                           siswa)
```

## PDF Page 6

```text
 GET     /api/v1/dashboard/financial-     DashboardHandler@FinancialAnalytics             auth:jwt
        analytics                                                                        (Role: admin,
                                                                                         bendahara)

 GET     /api/v1/dashboard/academic-      DashboardHandler@AcademicAttendanceAnalytics    auth:jwt
        attendance                                                                       (Role: admin,
                                                                                         guru, wali)

 GET     /api/v1/dashboard/counseling-    DashboardHandler@CounselingInsights             auth:jwt
        insights                                                                         (Role: admin,
                                                                                         guru_bk)

 GET     /api/v1/dashboard/ppdb-          DashboardHandler@PpdbInsights                   auth:jwt
        insights                                                                         (Role: admin,
                                                                                         panitia_ppdb)


Statistik Engine (Go - Port 8082) (13 routes)
 HTTP Path / Endpoint                         Handler / Action                    Required Permission /
 Method                                                                           Role Access
 GET     /health                               Health                             Public (No Auth)

 GET     /api/v1/statistik/overview            StatistikHandler@Overview          auth:jwt (Role:
                                                                                  admin, guru)

 GET     /api/v1/statistik/akademik            StatistikHandler@Akademik          auth:jwt (Role:
                                                                                  admin, guru)

 GET     /api/v1/statistik/kehadiran           StatistikHandler@Kehadiran         auth:jwt (Role:
                                                                                  admin, guru)

 GET     /api/v1/statistik/keuangan            StatistikHandler@Keuangan          auth:jwt (Role:
                                                                                  admin, bendahara)

 GET     /api/v1/statistik/bk                  StatistikHandler@BK                auth:jwt (Role:
                                                                                  admin, guru_bk)

 GET     /api/v1/statistik/ppdb                StatistikHandler@PPDB              auth:jwt (Role:
                                                                                  admin, panitia_ppdb)


 GET     /api/v1/statistik/perpustakaan        StatistikHandler@Perpustakaan      auth:jwt (Role:
                                                                                  admin, guru,
                                                                                  petugas_perpus)

 GET     /api/v1/statistik/ujian               StatistikHandler@Ujian             auth:jwt (Role:
                                                                                  admin, guru)

 GET     /api/v1/statistik/ekstrakurikuler     StatistikHandler@Ekstrakurikuler   auth:jwt (Role:
                                                                                  admin, guru,
                                                                                  pembina)

 GET     /api/v1/statistik/organisasi          StatistikHandler@Organisasi        auth:jwt (Role:
                                                                                  admin, guru,
                                                                                  pembina)

 GET     /api/v1/statistik/guru                StatistikHandler@Guru              auth:jwt (Role:
                                                                                  admin, guru)


 GET     /api/v1/statistik/spk                 StatistikHandler@SPK               auth:jwt (Role:
                                                                                  admin, guru)
```

## PDF Page 7

```text
EWS Worker (Go - Port 8085) (10 routes)
HTTP      Path / Endpoint                        Handler / Action                  Required Permission / Role
Method                                                                             Access
 GET       /health                                Health                           Public (No Auth)

 GET       /api/v1/ews                            EWSHandler@ListAlerts            auth:jwt (Role: admin,
                                                                                   guru_bk)

 GET       /api/v1/ews/alerts                     EWSHandler@ListAlerts            auth:jwt (Role: admin,
                                                                                   guru_bk)

 POST      /api/v1/ews/process                    EWSHandler@Process               auth:jwt (Role: admin,
                                                                                   guru_bk)

 POST      /api/v1/ews/process-                   EWSHandler@ProcessSiswa          auth:jwt (Role: admin,
          siswa/{siswaId}                                                          guru, guru_bk)

 POST      /api/v1/ews/{siswaId}/trigger          EWSHandler@ProcessSiswa          auth:jwt (Role: admin,
                                                                                   guru, guru_bk)

 GET       /api/v1/ews/alerts/{siswaId}           EWSHandler@GetAlertsBySiswa      auth:jwt (Role: admin,
                                                                                   guru_bk, wali, siswa)

 PATCH     /api/v1/ews/alerts/{id}/resolve        EWSHandler@ResolveAlert          auth:jwt (Role: admin,
                                                                                   guru_bk)

 PUT       /api/v1/ews/{id}/resolve               EWSHandler@ResolveAlert          auth:jwt (Role: admin,
                                                                                   guru_bk)


 GET       /api/v1/ews/{id}                       EWSHandler@GetAlert              auth:jwt (Role: admin,
                                                                                   guru_bk)




Bagian 2: Laravel Core API (508 Endpoints)
2.1. Modul: HEALTH (2 endpoints)
HTTP Method Path / Endpoint            Controller Action            Required Permission / Middleware Access
 GET          /api/v1/health           HealthController@health         Public (No Auth)

 GET          /api/v1/health/ping      HealthController@ping           Public (No Auth)


2.2. Modul: AUTH (4 endpoints)
HTTP Method Path / Endpoint             Controller Action           Required Permission / Middleware Access
 POST         /api/v1/auth/login        AuthController@login           Public (No Auth)

 POST         /api/v1/auth/refresh      AuthController@refresh         Public (No Auth)

 POST         /api/v1/auth/logout       AuthController@logout          auth:api (Tenant JWT)

 GET          /api/v1/auth/me           AuthController@me              auth:api (Tenant JWT)


2.3. Modul: PPDB (60 endpoints)
HTTP Path / Endpoint                                                    Controller Action
Method
 GET     /api/v1/ppdb/public/sekolah                                     PpdbPublicController@listSekolah
```

## PDF Page 8

```text
GET      /api/v1/ppdb/public/gelombang/{sekolahId}/active          PpdbPublicController@activeGelombang

POST     /api/v1/ppdb/public/daftar                                PpdbPublicController@daftar

POST     /api/v1/ppdb/public/status                                PpdbPublicController@cekStatus

GET      /api/v1/ppdb/gelombang                                    PpdbGelombangController@index

POST     /api/v1/ppdb/gelombang                                    PpdbGelombangController@store

GET      /api/v1/ppdb/gelombang/sekolah/{sekolahId}/active         PpdbGelombangController@active

GET      /api/v1/ppdb/gelombang/{id}                               PpdbGelombangController@show

PUT      /api/v1/ppdb/gelombang/{id}                               PpdbGelombangController@update

DELETE   /api/v1/ppdb/gelombang/{id}                               PpdbGelombangController@destroy

POST     /api/v1/ppdb/gelombang/{id}/activate                      PpdbGelombangController@activate

POST     /api/v1/ppdb/gelombang/{id}/deactivate                    PpdbGelombangController@deactivate

GET      /api/v1/ppdb/dokumen                                      PpdbDokumenController@index

POST     /api/v1/ppdb/dokumen                                      PpdbDokumenController@store


GET      /api/v1/ppdb/dokumen/pendaftaran/{pendaftaranId}          PpdbDokumenController@byPendaftaran



GET      /api/v1/ppdb/dokumen/{id}                                 PpdbDokumenController@show

PUT      /api/v1/ppdb/dokumen/{id}                                 PpdbDokumenController@update

DELETE   /api/v1/ppdb/dokumen/{id}                                 PpdbDokumenController@destroy

POST     /api/v1/ppdb/dokumen/{id}/verify                          PpdbDokumenController@verify

POST     /api/v1/ppdb/dokumen/{id}/reject                          PpdbDokumenController@reject

GET      /api/v1/ppdb/pendaftaran                                  PpdbPendaftaranController@index

POST     /api/v1/ppdb/pendaftaran                                  PpdbPendaftaranController@store

GET      /api/v1/ppdb/pendaftaran/no/{noPendaftaran}               PpdbPendaftaranController@showByNo

GET      /api/v1/ppdb/pendaftaran/sekolah/{sekolahId}/statistics   PpdbPendaftaranController@statistics

POST     /api/v1/ppdb/pendaftaran/batch-seleksi                    PpdbPendaftaranController@batchSeleksi



GET      /api/v1/ppdb/pendaftaran/{id}                             PpdbPendaftaranController@show

PUT      /api/v1/ppdb/pendaftaran/{id}                             PpdbPendaftaranController@update

PUT      /api/v1/ppdb/pendaftaran/{id}/status                      PpdbPendaftaranController@updateStatus



DELETE   /api/v1/ppdb/pendaftaran/{id}                             PpdbPendaftaranController@destroy

POST     /api/v1/ppdb/pendaftaran/{id}/verify                      PpdbPendaftaranController@verify

POST     /api/v1/ppdb/pendaftaran/{id}/accept                      PpdbPendaftaranController@accept

POST     /api/v1/ppdb/pendaftaran/{id}/enroll                      PpdbPendaftaranController@enroll

POST     /api/v1/ppdb/pendaftaran/{id}/reject                      PpdbPendaftaranController@reject

GET      /api/v1/ppdb/nilai-rapor/pendaftaran/{pendaftaranId}      PpdbPendaftarNilaiRaporController@byPendaf
```

## PDF Page 9

```text
 GET      /api/v1/ppdb/nilai-                                         PpdbPendaftarNilaiRaporController@statisti
          rapor/pendaftaran/{pendaftarId}/statistik

 POST     /api/v1/ppdb/nilai-                                         PpdbPendaftarNilaiRaporController@bulkStor
          rapor/pendaftaran/{pendaftaranId}/bulk

 DELETE   /api/v1/ppdb/nilai-rapor/pendaftaran/{pendaftarId}          PpdbPendaftarNilaiRaporController@destroyB

 POST     /api/v1/ppdb/nilai-rapor                                    PpdbPendaftarNilaiRaporController@store

 GET      /api/v1/ppdb/nilai-rapor/{id}                               PpdbPendaftarNilaiRaporController@show

 PUT      /api/v1/ppdb/nilai-rapor/{id}                               PpdbPendaftarNilaiRaporController@update

 DELETE   /api/v1/ppdb/nilai-rapor/{id}                               PpdbPendaftarNilaiRaporController@destroy

 GET      /api/v1/ppdb/kriteria-seleksi/gelombang/{gelombangId}       PpdbKriteriaSeleksiController@byGelombang

 POST     /api/v1/ppdb/kriteria-                                      PpdbKriteriaSeleksiController@seedDefault
          seleksi/gelombang/{gelombangId}/seed-default

 GET      /api/v1/ppdb/kriteria-seleksi/{id}                          PpdbKriteriaSeleksiController@show


 POST     /api/v1/ppdb/kriteria-seleksi                               PpdbKriteriaSeleksiController@store

 PUT      /api/v1/ppdb/kriteria-seleksi/{id}                          PpdbKriteriaSeleksiController@update

 DELETE   /api/v1/ppdb/kriteria-seleksi/{id}                          PpdbKriteriaSeleksiController@destroy

 GET      /api/v1/ppdb/kuota-jurusan/gelombang/{gelombangId}          PpdbKuotaJurusanController@byGelombang

 GET      /api/v1/ppdb/kuota-                                         PpdbKuotaJurusanController@summary
          jurusan/gelombang/{gelombangId}/summary

 GET      /api/v1/ppdb/kuota-jurusan/{id}                             PpdbKuotaJurusanController@show

 POST     /api/v1/ppdb/kuota-jurusan                                  PpdbKuotaJurusanController@store

 PUT      /api/v1/ppdb/kuota-jurusan/{id}                             PpdbKuotaJurusanController@update

 DELETE   /api/v1/ppdb/kuota-jurusan/{id}                             PpdbKuotaJurusanController@destroy

 GET      /api/v1/ppdb/seleksi/gelombang/{gelombangId}/hasil          PpdbSeleksiController@hasilByGelombang

 GET      /api/v1/ppdb/seleksi/hasil/{id}                             PpdbSeleksiController@showHasil

 POST     /api/v1/ppdb/seleksi/gelombang/{gelombangId}/jalankan       PpdbSeleksiController@jalankan


 POST     /api/v1/ppdb/seleksi/gelombang/{gelombangId}/simulasi       PpdbSeleksiController@simulasi

 POST     /api/v1/ppdb/seleksi/gelombang/{gelombangId}/finalisasi     PpdbSeleksiController@finalisasi

 DELETE   /api/v1/ppdb/seleksi/gelombang/{gelombangId}/reset          PpdbSeleksiController@reset

 POST     /api/v1/ppdb/seleksi/gelombang/{gelombangId}/fraud-scan     PpdbSeleksiController@fraudScan


2.4. Modul: LANDING (1 endpoints)
HTTP         Path / Endpoint              Controller Action                   Required Permission /
Method                                                                        Middleware Access
 POST        /api/v1/landing/referrals      LandingReferralController@store   Public (No Auth)


2.5. Modul: NOTIFIKASI (4 endpoints)
```

## PDF Page 10

```text
 HTTP      Path / Endpoint                     Controller Action                          Required Permission /
 Method                                                                                   Middleware Access
 GET        /api/v1/notifikasi                  SysNotifikasiController@index             auth:api (Tenant
                                                                                          JWT)

 GET        /api/v1/notifikasi/unread-          SysNotifikasiController@unreadCount       auth:api (Tenant
           count                                                                          JWT)

 POST       /api/v1/notifikasi/read-all         SysNotifikasiController@markAllRead       auth:api (Tenant
                                                                                          JWT)

 PUT        /api/v1/notifikasi/{id}/read        SysNotifikasiController@markRead          auth:api (Tenant
                                                                                          JWT)


2.6. Modul: FCM (2 endpoints)
 HTTP Method Path / Endpoint          Controller Action                  Required Permission / Middleware Access
 POST            /api/v1/fcm/token    FcmController@registerToken        auth:api (Tenant JWT)

 DELETE          /api/v1/fcm/token    FcmController@deleteToken          auth:api (Tenant JWT)


2.7. Modul: MENUS (1 endpoints)
 HTTP Method Path / Endpoint           Controller Action                Required Permission / Middleware Access
 GET             /api/v1/menus/tree     SysMenuController@getTree        auth:api (Tenant JWT)


2.8. Modul: FILES (3 endpoints)
 HTTP      Path / Endpoint                Controller Action                           Required Permission /
 Method                                                                               Middleware Access
 POST       /api/v1/files/upload           FileUploadController@upload                 files.upload

 POST       /api/v1/files/presigned-       FileUploadController@getPresignedUrl        files.presigned-url
           url

 DELETE     /api/v1/files/delete           FileUploadController@delete                 files.delete


2.9. Modul: KELAS (9 endpoints)
 HTTP Path / Endpoint                           Controller Action                                Required
 Method                                                                                          Permission /
                                                                                                 Middleware
                                                                                                 Access
 GET       /api/v1/kelas                         KelasController@index                           kelas.view

 POST      /api/v1/kelas                         KelasController@store                           kelas.create

 POST      /api/v1/kelas/import                  KelasController@import                          kelas.create

 GET       /api/v1/kelas/tingkat/{tingkat}       KelasController@byTingkat                       kelas.view


 GET       /api/v1/kelas/{id}                    KelasController@show                            kelas.view

 PUT       /api/v1/kelas/{id}                    KelasController@update                          kelas.update

 DELETE    /api/v1/kelas/{id}                    KelasController@destroy                         kelas.delete

 GET       /api/v1/kelas/{id}/siswa              KelasController@siswa                           kelas.view
```

## PDF Page 11

```text
 GET      /api/v1/kelas/{id}/risk-summary      SiswaInsightController@kelasRiskSummary        siswa.view


2.10. Modul: MAPEL (7 endpoints)
HTTP         Path / Endpoint              Controller Action             Required Permission / Middleware
Method                                                                  Access
 GET         /api/v1/mapel                  MapelController@index       mapel.view

 POST        /api/v1/mapel                  MapelController@store       mapel.create

 POST        /api/v1/mapel/import           MapelController@import      mapel.create

 GET         /api/v1/mapel/{id}             MapelController@show        mapel.view

 PUT         /api/v1/mapel/{id}             MapelController@update      mapel.update

 DELETE      /api/v1/mapel/{id}             MapelController@destroy     mapel.delete

 GET         /api/v1/mapel/{id}/gurus       MapelController@gurus       mapel.view


2.11. Modul: GURU (8 endpoints)
HTTP       Path / Endpoint                      Controller Action                    Required Permission /
Method                                                                               Middleware Access
 GET       /api/v1/guru                         GuruController@index                 guru.view

 POST      /api/v1/guru                         GuruController@store                 guru.create

 POST      /api/v1/guru/import                  GuruController@import                guru.create


 GET       /api/v1/guru/{id}                    GuruController@show                  guru.view

 PUT       /api/v1/guru/{id}                    GuruController@update                guru.update

 DELETE    /api/v1/guru/{id}                    GuruController@destroy               guru.delete

 GET       /api/v1/guru/mapel/{mapelId}         GuruController@byMapel               guru.view

 GET       /api/v1/guru/{id}/absensi-           GuruController@absensiSummary        guru.view
           summary


2.12. Modul: GURU-MAPEL (8 endpoints)
HTTP       Path / Endpoint                     Controller Action                Required Permission /
Method                                                                          Middleware Access
 GET        /api/v1/guru-mapel                 GuruMapelController@index        guru-mapel.view

 POST       /api/v1/guru-mapel                 GuruMapelController@store        guru-mapel.create

 GET        /api/v1/guru-mapel/saya            GuruMapelController@mine         guru-mapel.view

 GET        /api/v1/guru-                      GuruMapelController@byGuru       guru-mapel.view
           mapel/guru/{guruId}


 GET        /api/v1/guru-                      GuruMapelController@byMapel      guru-mapel.view
           mapel/mapel/{mapelId}

 GET        /api/v1/guru-mapel/{id}            GuruMapelController@show         guru-mapel.view

 PUT        /api/v1/guru-mapel/{id}            GuruMapelController@update       guru-mapel.update

 DELETE     /api/v1/guru-mapel/{id}            GuruMapelController@destroy      guru-mapel.delete
```

## PDF Page 12

```text
2.13. Modul: SISWA (14 endpoints)
HTTP Path / Endpoint                                  Controller Action                               Required
Method                                                                                                Permission /
                                                                                                      Middleware
                                                                                                      Access
 GET      /api/v1/siswa                               SiswaController@index                           siswa.view

 POST     /api/v1/siswa                               SiswaController@store                           siswa.create

 POST     /api/v1/siswa/import                        SiswaController@import                          siswa.create

 GET      /api/v1/siswa/kelas/{kelasId}               SiswaController@byKelas                         siswa.view

 GET      /api/v1/siswa/{id}                          SiswaController@show                            siswa.view

 PUT      /api/v1/siswa/{id}                          SiswaController@update                          siswa.update

 DELETE   /api/v1/siswa/{id}                          SiswaController@destroy                         siswa.delete

 GET      /api/v1/siswa/{id}/absensi-summary          SiswaController@absensiSummary                  siswa.view

 POST     /api/v1/siswa/{id}/naik-kelas               SiswaController@naikKelas                       siswa.naik-
                                                                                                      kelas

 POST     /api/v1/siswa/{id}/lulus                    SiswaController@lulus                           siswa.lulus

 GET      /api/v1/siswa/{id}/insight                  SiswaInsightController@insight                  siswa.view

 GET      /api/v1/siswa/{id}/risk-profile             SiswaInsightController@riskProfile              siswa.view

 GET      /api/v1/siswa/{id}/academic-progress        SiswaInsightController@academicProgress         siswa.view

 POST     /api/v1/siswa/{id}/insight/invalidate       SiswaInsightController@invalidateCache          siswa.update


2.14. Modul: WALI (7 endpoints)
HTTP Method Path / Endpoint                 Controller Action             Required Permission / Middleware Access
 GET           /api/v1/wali                 WaliController@index          wali.view

 POST          /api/v1/wali                 WaliController@store          wali.create

 POST          /api/v1/wali/import          WaliController@import         wali.create

 GET           /api/v1/wali/{id}            WaliController@show           wali.view

 PUT           /api/v1/wali/{id}            WaliController@update         wali.update

 DELETE        /api/v1/wali/{id}            WaliController@destroy        wali.delete

 GET           /api/v1/wali/{id}/siswa      WaliController@siswa          wali.view


2.15. Modul: JADWAL-PELAJARAN (7 endpoints)
HTTP      Path / Endpoint                        Controller Action                         Required Permission /
Method                                                                                     Middleware Access
 GET      /api/v1/jadwal-pelajaran                JadwalPelajaranController@index          jadwal-
                                                                                           pelajaran.view

 POST     /api/v1/jadwal-pelajaran                JadwalPelajaranController@store          jadwal-
                                                                                           pelajaran.create
```

## PDF Page 13

```text
 GET      /api/v1/jadwal-pelajaran/{id}       JadwalPelajaranController@show         jadwal-
                                                                                    pelajaran.view

 PUT      /api/v1/jadwal-pelajaran/{id}       JadwalPelajaranController@update       jadwal-
                                                                                    pelajaran.update

 DELETE   /api/v1/jadwal-pelajaran/{id}       JadwalPelajaranController@destroy      jadwal-
                                                                                    pelajaran.delete

 GET      /api/v1/jadwal-                     JadwalPelajaranController@byKelas      jadwal-
          pelajaran/kelas/{kelasId}                                                 pelajaran.view

 GET      /api/v1/jadwal-                     JadwalPelajaranController@byHari       jadwal-
          pelajaran/kelas/{kelasId}/hari                                            pelajaran.view


2.16. Modul: BK (40 endpoints)
HTTP       Path / Endpoint                    Controller Action                Required Permission /
Method                                                                         Middleware Access
 GET       /api/v1/bk/kategori                BkKategoriController@index         bk-kategori.view

 POST      /api/v1/bk/kategori                BkKategoriController@store         bk-kategori.manage


 GET       /api/v1/bk/kategori/{id}           BkKategoriController@show          bk-kategori.view

 PUT       /api/v1/bk/kategori/{id}           BkKategoriController@update        bk-kategori.manage

 DELETE    /api/v1/bk/kategori/{id}           BkKategoriController@destroy       bk-kategori.manage

 GET       /api/v1/bk/jenis                   BkJenisController@index            bk-jenis.view

 POST      /api/v1/bk/jenis                   BkJenisController@store            bk-jenis.create

 GET       /api/v1/bk/jenis/{id}              BkJenisController@show             bk-jenis.view

 PUT       /api/v1/bk/jenis/{id}              BkJenisController@update           bk-jenis.update

 DELETE    /api/v1/bk/jenis/{id}              BkJenisController@destroy          bk-jenis.delete

 GET       /api/v1/bk/kasus                   BkKasusController@index            bk-kasus.view

 POST      /api/v1/bk/kasus                   BkKasusController@store            bk-kasus.create

 GET       /api/v1/bk/kasus/{id}              BkKasusController@show             bk-kasus.view

 PUT       /api/v1/bk/kasus/{id}              BkKasusController@update           bk-kasus.update

 DELETE    /api/v1/bk/kasus/{id}              BkKasusController@destroy          bk-kasus.delete


 GET       /api/v1/bk/kasus/siswa/{siswaId}   BkKasusController@bySiswa          bk-kasus.view

 GET       /api/v1/bk/sesi                    BkSesiController@index             bk-sesi.view

 POST      /api/v1/bk/sesi                    BkSesiController@store             bk-sesi.manage

 GET       /api/v1/bk/sesi/{id}               BkSesiController@show              bk-sesi.view

 PUT       /api/v1/bk/sesi/{id}               BkSesiController@update            bk-sesi.manage

 DELETE    /api/v1/bk/sesi/{id}               BkSesiController@destroy           bk-sesi.manage

 GET       /api/v1/bk/hasil                   BkHasilController@index            bk-hasil.view

 POST      /api/v1/bk/hasil                   BkHasilController@store            bk-hasil.manage
```

## PDF Page 14

```text
 GET        /api/v1/bk/hasil/{id}                 BkHasilController@show                bk-hasil.view

 PUT        /api/v1/bk/hasil/{id}                 BkHasilController@update              bk-hasil.manage

 DELETE     /api/v1/bk/hasil/{id}                 BkHasilController@destroy             bk-hasil.manage

 GET        /api/v1/bk/tindakan                   BkTindakanController@index            bk-tindakan.view

 POST       /api/v1/bk/tindakan                   BkTindakanController@store            bk-tindakan.manage

 GET        /api/v1/bk/tindakan/{id}              BkTindakanController@show             bk-tindakan.view

 PUT        /api/v1/bk/tindakan/{id}              BkTindakanController@update           bk-tindakan.manage

 DELETE     /api/v1/bk/tindakan/{id}              BkTindakanController@destroy          bk-tindakan.manage

 GET        /api/v1/bk/lampiran                   BkLampiranController@index            bk-lampiran.view

 POST       /api/v1/bk/lampiran                   BkLampiranController@store            bk-lampiran.manage

 GET        /api/v1/bk/lampiran/{id}              BkLampiranController@show             bk-lampiran.view

 DELETE     /api/v1/bk/lampiran/{id}              BkLampiranController@destroy          bk-lampiran.manage

 GET        /api/v1/bk/wali                       BkWaliController@index                bk-wali.view


 POST       /api/v1/bk/wali                       BkWaliController@store                bk-wali.manage

 GET        /api/v1/bk/wali/{id}                  BkWaliController@show                 bk-wali.view

 PUT        /api/v1/bk/wali/{id}                  BkWaliController@update               bk-wali.manage

 DELETE     /api/v1/bk/wali/{id}                  BkWaliController@destroy              bk-wali.manage


2.17. Modul: EWS (4 endpoints)
HTTP        Path / Endpoint                     Controller Action                 Required Permission /
Method                                                                            Middleware Access
 GET         /api/v1/ews                        EwsController@index               ews.view

 GET         /api/v1/ews/{id}                   EwsController@show                ews.view

 PUT         /api/v1/ews/{id}/resolve           EwsController@resolve             ews.manage

 POST        /api/v1/ews/{siswaId}/trigger      EwsController@triggerCheck        ews.manage


2.18. Modul: PERPUSTAKAAN (16 endpoints)
HTTP Path / Endpoint                                                Controller Action                        Required
Method                                                                                                       Middlewa
 GET      /api/v1/perpustakaan/buku                                 BukuController@index                     buku.vie

 POST     /api/v1/perpustakaan/buku                                 BukuController@store                     buku.cre

 POST     /api/v1/perpustakaan/buku/import                          BukuController@import                    buku.cre


 GET      /api/v1/perpustakaan/buku/available                       BukuController@available                 buku.vie

 GET      /api/v1/perpustakaan/buku/{id}                            BukuController@show                      buku.vie

 PUT      /api/v1/perpustakaan/buku/{id}                            BukuController@update                    buku.upd

 DELETE   /api/v1/perpustakaan/buku/{id}                            BukuController@destroy                   buku.del
```

## PDF Page 15

```text
 GET      /api/v1/perpustakaan/buku/{id}/peminjaman           BukuController@peminjaman                buku.vie

 GET      /api/v1/perpustakaan/peminjaman                     PeminjamanBukuController@index           peminjam

 POST     /api/v1/perpustakaan/peminjaman                     PeminjamanBukuController@store           peminjam

 GET      /api/v1/perpustakaan/peminjaman/overdue             PeminjamanBukuController@overdue         peminjam

 GET      /api/v1/perpustakaan/peminjaman/{id}                PeminjamanBukuController@show            peminjam

 PUT      /api/v1/perpustakaan/peminjaman/{id}                PeminjamanBukuController@update          peminjam

 DELETE   /api/v1/perpustakaan/peminjaman/{id}                PeminjamanBukuController@destroy         peminjam

 POST     /api/v1/perpustakaan/peminjaman/{id}/pengembalian   PeminjamanBukuController@pengembalian    peminjam

 GET      /api/v1/perpustakaan/peminjaman/siswa/{siswaId}     PeminjamanBukuController@bySiswa         peminjam


2.19. Modul: AKADEMIK (104 endpoints)
HTTP Path / Endpoint                                           Controller Action
Method
 GET      /api/v1/akademik/tes-minat-bakat                      TesMinatBakatController@index



 POST     /api/v1/akademik/tes-minat-bakat                      TesMinatBakatController@store



 GET      /api/v1/akademik/tes-minat-bakat/{id}                 TesMinatBakatController@show



 PUT      /api/v1/akademik/tes-minat-bakat/{id}                 TesMinatBakatController@update



 DELETE   /api/v1/akademik/tes-minat-bakat/{id}                 TesMinatBakatController@destroy



 GET      /api/v1/akademik/tes-minat-bakat/kelas/{kelasId}      TesMinatBakatController@byKelas



 GET      /api/v1/akademik/tes-minat-bakat-aspek                TesMinatBakatAspekController@index



 POST     /api/v1/akademik/tes-minat-bakat-aspek                TesMinatBakatAspekController@store



 GET      /api/v1/akademik/tes-minat-bakat-aspek/{id}           TesMinatBakatAspekController@show



 PUT      /api/v1/akademik/tes-minat-bakat-aspek/{id}           TesMinatBakatAspekController@update



 DELETE   /api/v1/akademik/tes-minat-bakat-aspek/{id}           TesMinatBakatAspekController@destroy



 GET      /api/v1/akademik/tes-minat-bakat-pertanyaan           TesMinatBakatPertanyaanController@index



 POST     /api/v1/akademik/tes-minat-bakat-pertanyaan           TesMinatBakatPertanyaanController@store



 GET      /api/v1/akademik/tes-minat-bakat-                     TesMinatBakatPertanyaanController@byTes
          pertanyaan/tes/{tesId}
```

## PDF Page 16

```text
GET      /api/v1/akademik/tes-minat-bakat-pertanyaan/{id}      TesMinatBakatPertanyaanController@show



PUT      /api/v1/akademik/tes-minat-bakat-pertanyaan/{id}      TesMinatBakatPertanyaanController@update



DELETE   /api/v1/akademik/tes-minat-bakat-pertanyaan/{id}      TesMinatBakatPertanyaanController@destroy



GET      /api/v1/akademik/tes-minat-bakat-peserta              TesMinatBakatPesertaController@index



POST     /api/v1/akademik/tes-minat-bakat-peserta              TesMinatBakatPesertaController@store



GET      /api/v1/akademik/tes-minat-bakat-                     TesMinatBakatPesertaController@byTes
         peserta/tes/{tesId}

GET      /api/v1/akademik/tes-minat-bakat-                     TesMinatBakatPesertaController@bySiswa
         peserta/siswa/{siswaId}

GET      /api/v1/akademik/tes-minat-bakat-peserta/{id}         TesMinatBakatPesertaController@show



PUT      /api/v1/akademik/tes-minat-bakat-peserta/{id}         TesMinatBakatPesertaController@update



DELETE   /api/v1/akademik/tes-minat-bakat-peserta/{id}         TesMinatBakatPesertaController@destroy



POST     /api/v1/akademik/tes-minat-bakat-peserta/{id}/mulai   TesMinatBakatPesertaController@mulaiTes



POST     /api/v1/akademik/tes-minat-bakat-                     TesMinatBakatPesertaController@selesaikanTes
         peserta/{id}/selesaikan

GET      /api/v1/akademik/tes-minat-bakat-jawaban              TesMinatBakatJawabanController@index



POST     /api/v1/akademik/tes-minat-bakat-jawaban              TesMinatBakatJawabanController@store



GET      /api/v1/akademik/tes-minat-bakat-jawaban/{id}         TesMinatBakatJawabanController@show



PUT      /api/v1/akademik/tes-minat-bakat-jawaban/{id}         TesMinatBakatJawabanController@update



DELETE   /api/v1/akademik/tes-minat-bakat-jawaban/{id}         TesMinatBakatJawabanController@destroy



GET      /api/v1/akademik/tes-minat-bakat-hasil                TesMinatBakatHasilController@index



GET      /api/v1/akademik/tes-minat-bakat-                     TesMinatBakatHasilController@byPeserta
         hasil/peserta/{pesertaId}

GET      /api/v1/akademik/tes-minat-bakat-hasil/{id}           TesMinatBakatHasilController@show



POST     /api/v1/akademik/soals/generate                       SoalsController@generate

GET      /api/v1/akademik/soals                                SoalsController@index
```

## PDF Page 17

```text
POST     /api/v1/akademik/soals                                SoalsController@store

GET      /api/v1/akademik/soals/{id}                           SoalsController@show

PUT      /api/v1/akademik/soals/{id}                           SoalsController@update

DELETE   /api/v1/akademik/soals/{id}                           SoalsController@destroy

GET      /api/v1/akademik/nilai                                NilaiController@index

POST     /api/v1/akademik/nilai                                NilaiController@store

GET      /api/v1/akademik/nilai/siswa/{siswaId}/export         NilaiController@export

GET      /api/v1/akademik/nilai/{id}                           NilaiController@show

PUT      /api/v1/akademik/nilai/{id}                           NilaiController@update

DELETE   /api/v1/akademik/nilai/{id}                           NilaiController@destroy

GET      /api/v1/akademik/nilai/siswa/{siswaId}                NilaiController@bySiswa

GET      /api/v1/akademik/nilai/ujian/{ujianId}                NilaiController@byUjian

GET      /api/v1/akademik/nilai/siswa/{siswaId}/rata-rata      NilaiController@rataRata


GET      /api/v1/akademik/ranking                              RankingController@index

POST     /api/v1/akademik/ranking                              RankingController@store

POST     /api/v1/akademik/ranking/generate                     RankingController@generate

GET      /api/v1/akademik/ranking/kelas/{kelasId}/export       RankingController@export

GET      /api/v1/akademik/ranking/{id}                         RankingController@show

PUT      /api/v1/akademik/ranking/{id}                         RankingController@update

DELETE   /api/v1/akademik/ranking/{id}                         RankingController@destroy

GET      /api/v1/akademik/ranking/kelas/{kelasId}              RankingController@byKelas

GET      /api/v1/akademik/rapor                                RaporController@index

POST     /api/v1/akademik/rapor                                RaporController@store

POST     /api/v1/akademik/rapor/generate-dari-nilai            RaporController@generateDariNilai

POST     /api/v1/akademik/rapor/generate-kelas                 RaporController@generateDariNilaiKelas

GET      /api/v1/akademik/rapor/siswa/{siswaId}/export         RaporController@export


GET      /api/v1/akademik/rapor/kelas/{kelasId}/rekap/export   RaporController@exportRekapKelas

GET      /api/v1/akademik/rapor/{id}                           RaporController@show

PUT      /api/v1/akademik/rapor/{id}                           RaporController@update

DELETE   /api/v1/akademik/rapor/{id}                           RaporController@destroy

GET      /api/v1/akademik/rapor/siswa/{siswaId}                RaporController@bySiswa

GET      /api/v1/akademik/rapor/{id}/detail                    RaporController@detail

POST     /api/v1/akademik/rapor/{id}/generate-narasi           RaporController@generateNarasi



GET      /api/v1/akademik/tugas                                TugasController@index
```

## PDF Page 18

```text
POST     /api/v1/akademik/tugas                             TugasController@store

GET      /api/v1/akademik/tugas/{id}                        TugasController@show

PUT      /api/v1/akademik/tugas/{id}                        TugasController@update

DELETE   /api/v1/akademik/tugas/{id}                        TugasController@destroy

GET      /api/v1/akademik/tugas/kelas/{kelasId}             TugasController@byKelas

GET      /api/v1/akademik/tugas/guru-mapel/{guruMapelId}    TugasController@byGuruMapel

GET      /api/v1/akademik/tugas-siswa                       TugasSiswaController@index

POST     /api/v1/akademik/tugas-siswa                       TugasSiswaController@store



GET      /api/v1/akademik/tugas-siswa/{id}                  TugasSiswaController@show

PUT      /api/v1/akademik/tugas-siswa/{id}                  TugasSiswaController@update



DELETE   /api/v1/akademik/tugas-siswa/{id}                  TugasSiswaController@destroy



GET      /api/v1/akademik/tugas-siswa/tugas/{tugasId}       TugasSiswaController@byTugas

GET      /api/v1/akademik/tugas-siswa/siswa/{siswaId}       TugasSiswaController@bySiswa

POST     /api/v1/akademik/tugas-siswa/{id}/nilai            TugasSiswaController@nilai

POST     /api/v1/akademik/tugas-                            TugasSiswaController@kumpulkan
         siswa/siswa/{siswaId}/tugas/{tugasId}/kumpulkan

GET      /api/v1/akademik/forum                             ForumController@index

POST     /api/v1/akademik/forum                             ForumController@store

GET      /api/v1/akademik/forum/{id}                        ForumController@show

PUT      /api/v1/akademik/forum/{id}                        ForumController@update

DELETE   /api/v1/akademik/forum/{id}                        ForumController@destroy

GET      /api/v1/akademik/forum/user/{userId}               ForumController@byUser

GET      /api/v1/akademik/materi                            MateriController@index


POST     /api/v1/akademik/materi                            MateriController@store

GET      /api/v1/akademik/materi/{id}                       MateriController@show

PUT      /api/v1/akademik/materi/{id}                       MateriController@update

DELETE   /api/v1/akademik/materi/{id}                       MateriController@destroy

GET      /api/v1/akademik/materi/guru-mapel/{guruMapelId}   MateriController@byGuruMapel

GET      /api/v1/akademik/log-akses-materi                  LogAksesMateriController@index



POST     /api/v1/akademik/log-akses-materi                  LogAksesMateriController@store



GET      /api/v1/akademik/log-akses-materi/popular          LogAksesMateriController@popular
```

## PDF Page 19

```text
 GET      /api/v1/akademik/log-akses-materi/materi/{materiId}     LogAksesMateriController@byMateri



 GET      /api/v1/akademik/log-akses-materi/siswa/{siswaId}       LogAksesMateriController@bySiswa



 GET      /api/v1/akademik/log-akses-materi/{id}                  LogAksesMateriController@show



 PUT      /api/v1/akademik/log-akses-materi/{id}/durasi           LogAksesMateriController@updateDurasi




2.20. Modul: SEKOLAH (16 endpoints)
HTTP Path / Endpoint                                  Controller Action                           Required Permissio
Method                                                                                            Middleware Access
 GET      /api/v1/sekolah                             SekolahController@index                     sekolah.view

 POST     /api/v1/sekolah                             SekolahController@store                     sekolah.create

 GET      /api/v1/sekolah/{id}                        SekolahController@show                      sekolah.view

 PUT      /api/v1/sekolah/{id}                        SekolahController@update                    sekolah.update


 DELETE   /api/v1/sekolah/{id}                        SekolahController@destroy                   sekolah.delete

 GET      /api/v1/sekolah/uuid/{uuid}                 SekolahController@showByUuid                sekolah.view

 GET      /api/v1/sekolah/{sekolahId}/settings        SysSekolahSettingsController@index          sekolah.settings

 PUT      /api/v1/sekolah/{sekolahId}/settings/ai     SysSekolahSettingsController@updateAi       sekolah.settings

 POST     /api/v1/sekolah/{sekolahId}/settings        SysSekolahSettingsController@store          sekolah.settings

 GET      /api/v1/sekolah/{sekolahId}/settings/{id}   SysSekolahSettingsController@show           sekolah.settings

 PUT      /api/v1/sekolah/{sekolahId}/settings/{id}   SysSekolahSettingsController@update         sekolah.settings

 DELETE   /api/v1/sekolah/{sekolahId}/settings/{id}   SysSekolahSettingsController@destroy        sekolah.settings

 GET      /api/v1/sekolah/{sekolahId}/settings-       SysSekolahSettingsController@byKey          sekolah.settings
          key/{key}

 GET      /api/v1/sekolah/{id}/settings-list          SekolahController@settings                  sekolah.settings

 POST     /api/v1/sekolah/{id}/set-setting            SekolahController@setSetting                sekolah.settings

 DELETE   /api/v1/sekolah/{id}/setting/{key}          SekolahController@deleteSetting             sekolah.settings


2.21. Modul: ADMIN (77 endpoints)
HTTP Path / Endpoint                                      Controller Action                           Required Perm
Method                                                                                                Middleware Ac
 GET      /api/v1/admin/users                             UserController@index                        users.view

 POST     /api/v1/admin/users                             UserController@store                        users.create

 GET      /api/v1/admin/users/{id}                        UserController@show                         users.view

 PUT      /api/v1/admin/users/{id}                        UserController@update                       users.update

 DELETE   /api/v1/admin/users/{id}                        UserController@destroy                      users.delete
```

## PDF Page 20

```text
POST     /api/v1/admin/users/{id}/toggle-active        UserController@toggleActive           users.toggle

POST     /api/v1/admin/users/{id}/assign-roles         UserController@assignRoles            users.assign

GET      /api/v1/admin/user-devices/user/{userId}      SysUserDeviceController@byUser        users.view

GET      /api/v1/admin/user-devices/{id}               SysUserDeviceController@show          users.view

POST     /api/v1/admin/user-devices                    SysUserDeviceController@store         users.create

PUT      /api/v1/admin/user-devices/{id}               SysUserDeviceController@update        users.update

DELETE   /api/v1/admin/user-devices/{id}               SysUserDeviceController@destroy       users.delete

POST     /api/v1/admin/user-devices/{id}/touch         SysUserDeviceController@touch         users.update

GET      /api/v1/admin/roles                           RoleController@index                  roles.view

POST     /api/v1/admin/roles                           RoleController@store                  roles.create

GET      /api/v1/admin/roles/{id}                      RoleController@show                   roles.view

PUT      /api/v1/admin/roles/{id}                      RoleController@update                 roles.update

DELETE   /api/v1/admin/roles/{id}                      RoleController@destroy                roles.delete


GET      /api/v1/admin/roles/{id}/permissions          RoleController@permissions            roles.permis

POST     /api/v1/admin/roles/{id}/assign-permissions   RoleController@assignPermissions      roles.assign
                                                                                             permissions

GET      /api/v1/admin/permissions                     PermissionController@index            permissions.

POST     /api/v1/admin/permissions                     PermissionController@store            permissions.

GET      /api/v1/admin/permissions/{id}                PermissionController@show             permissions.

PUT      /api/v1/admin/permissions/{id}                PermissionController@update           permissions.

DELETE   /api/v1/admin/permissions/{id}                PermissionController@destroy          permissions.

GET      /api/v1/admin/role-permissions                SysRolePermissionController@index     role_permiss

POST     /api/v1/admin/role-permissions                SysRolePermissionController@store     role_permiss

GET      /api/v1/admin/role-permissions/{id}           SysRolePermissionController@show      role_permiss

PUT      /api/v1/admin/role-permissions/{id}           SysRolePermissionController@update    role_permiss

DELETE   /api/v1/admin/role-permissions/{id}           SysRolePermissionController@destroy   role_permiss


GET      /api/v1/admin/menus                           SysMenuController@index               menus.view

POST     /api/v1/admin/menus                           SysMenuController@store               menus.create

GET      /api/v1/admin/menus/{id}                      SysMenuController@show                menus.view

PUT      /api/v1/admin/menus/{id}                      SysMenuController@update              menus.update

DELETE   /api/v1/admin/menus/{id}                      SysMenuController@destroy             menus.delete

GET      /api/v1/admin/activity-logs                   SysActivityLogController@index        activity-log

GET      /api/v1/admin/activity-logs/statistics        SysActivityLogController@statistics   activity-
                                                                                             logs.statist

GET      /api/v1/admin/activity-logs/user/{userId}     SysActivityLogController@byUser       activity-log
```

## PDF Page 21

```text
GET      /api/v1/admin/activity-logs/module/list        SysActivityLogController@byModule        activity-log

GET      /api/v1/admin/activity-                        SysActivityLogController@byRecord        activity-log
         logs/record/{table}/{id}

DELETE   /api/v1/admin/activity-logs/clear-old          SysActivityLogController@clearOld        activity-log

GET      /api/v1/admin/activity-logs/{id}               SysActivityLogController@show            activity-log

DELETE   /api/v1/admin/activity-logs/{id}               SysActivityLogController@destroy         activity-log

GET      /api/v1/admin/references                       SysReferenceController@index             sys-referenc

GET      /api/v1/admin/references/category/{category}   SysReferenceController@byCategory        sys-referenc

POST     /api/v1/admin/references                       SysReferenceController@store             sys-referenc

GET      /api/v1/admin/references/{id}                  SysReferenceController@show              sys-referenc

PUT      /api/v1/admin/references/{id}                  SysReferenceController@update            sys-referenc

DELETE   /api/v1/admin/references/{id}                  SysReferenceController@destroy           sys-referenc

GET      /api/v1/admin/tahun-ajaran                     TahunAjaranController@index              tahun-ajaran


POST     /api/v1/admin/tahun-ajaran                     TahunAjaranController@store              tahun-ajaran

POST     /api/v1/admin/tahun-ajaran/import              TahunAjaranController@import             tahun-ajaran

GET      /api/v1/admin/tahun-ajaran/active              TahunAjaranController@getActive          tahun-ajaran

POST     /api/v1/admin/tahun-ajaran/{id}/set-active     TahunAjaranController@setActive          tahun-ajaran

GET      /api/v1/admin/tahun-ajaran/{id}                TahunAjaranController@show               tahun-ajaran

PUT      /api/v1/admin/tahun-ajaran/{id}                TahunAjaranController@update             tahun-ajaran

DELETE   /api/v1/admin/tahun-ajaran/{id}                TahunAjaranController@destroy            tahun-ajaran

GET      /api/v1/admin/semester                         SemesterController@index                 semester.vie

POST     /api/v1/admin/semester                         SemesterController@store                 semester.man

GET      /api/v1/admin/semester/{id}                    SemesterController@show                  semester.vie

PUT      /api/v1/admin/semester/{id}                    SemesterController@update                semester.man

DELETE   /api/v1/admin/semester/{id}                    SemesterController@destroy               semester.man

GET      /api/v1/admin/hari-operasional                 HariOperasionalController@index          hari-operasi


PUT      /api/v1/admin/hari-operasional/{id}            HariOperasionalController@update         hari-operasi

GET      /api/v1/admin/kalender-tipe                    KalenderAkademikTipeController@index     kalender-tip

POST     /api/v1/admin/kalender-tipe                    KalenderAkademikTipeController@store     kalender-tip

GET      /api/v1/admin/kalender-tipe/{id}               KalenderAkademikTipeController@show      kalender-tip

PUT      /api/v1/admin/kalender-tipe/{id}               KalenderAkademikTipeController@update    kalender-tip

DELETE   /api/v1/admin/kalender-tipe/{id}               KalenderAkademikTipeController@destroy   kalender-tip

GET      /api/v1/admin/kalender-akademik                KalenderAkademikController@index         kalender-aka

POST     /api/v1/admin/kalender-akademik                KalenderAkademikController@store         kalender-
                                                                                                 akademik.man
```

## PDF Page 22

```text
 GET      /api/v1/admin/kalender-akademik/{id}               KalenderAkademikController@show                 kalender-aka

 PUT      /api/v1/admin/kalender-akademik/{id}               KalenderAkademikController@update               kalender-
                                                                                                           akademik.man

 DELETE   /api/v1/admin/kalender-akademik/{id}               KalenderAkademikController@destroy              kalender-
                                                                                                           akademik.man

 GET      /api/v1/admin/kalender-harian                      KalenderHarianController@index                  kalender-har

 POST     /api/v1/admin/kalender-harian/generate             KalenderHarianController@generate               kalender-har

 PUT      /api/v1/admin/kalender-harian/{id}                 KalenderHarianController@update                 kalender-har


2.22. Modul: KEUANGAN (20 endpoints)
HTTP   Path / Endpoint                           Controller Action                            Required
Method                                                                                        Permission /
                                                                                              Middleware
                                                                                              Access
 GET      /api/v1/keuangan/tarif-spp             TarifSppController@index                     tarif-spp.view

 POST     /api/v1/keuangan/tarif-spp             TarifSppController@store                     tarif-
                                                                                              spp.create

 POST     /api/v1/keuangan/tarif-                TarifSppController@import                    tarif-
          spp/import                                                                          spp.create

 GET      /api/v1/keuangan/tarif-                TarifSppController@byKelas                   tarif-spp.view
          spp/kelas/{kelasId}

 GET      /api/v1/keuangan/tarif-spp/{id}        TarifSppController@show                      tarif-spp.view


 PUT      /api/v1/keuangan/tarif-spp/{id}        TarifSppController@update                    tarif-
                                                                                              spp.update

 DELETE   /api/v1/keuangan/tarif-spp/{id}        TarifSppController@destroy                   tarif-
                                                                                              spp.delete

 GET      /api/v1/keuangan/pembayaran-spp        PembayaranSppController@index                pembayaran-
                                                                                              spp.view

 POST     /api/v1/keuangan/pembayaran-spp        PembayaranSppController@store                pembayaran-
                                                                                              spp.create

 POST     /api/v1/keuangan/pembayaran-           PembayaranSppController@bayar                pembayaran-
          spp/bayar                                                                           spp.bayar

 POST     /api/v1/keuangan/pembayaran-           PembayaranSppController@bayarMultiple        pembayaran-
          spp/bayar-multiple                                                                  spp.bayar

 POST     /api/v1/keuangan/pembayaran-           PembayaranSppController@bayarOnline          pembayaran-
          spp/bayar-online                                                                    spp.bayar

 GET      /api/v1/keuangan/pembayaran-           PembayaranSppController@hitungDenda          pembayaran-
          spp/hitung-denda                                                                    spp.view

 GET      /api/v1/keuangan/pembayaran-           PembayaranSppController@laporanPeriode       pembayaran-
          spp/laporan-periode                                                                 spp.view

 GET      /api/v1/keuangan/pembayaran-           PembayaranSppController@bySiswa              pembayaran-
          spp/siswa/{siswaId}                                                                 spp.view
```

## PDF Page 23

```text
 GET      /api/v1/keuangan/pembayaran-        PembayaranSppController@statusSiswa        pembayaran-
          spp/siswa/{siswaId}/status                                                     spp.view

 GET      /api/v1/keuangan/pembayaran-        PembayaranSppController@tunggakan          pembayaran-
          spp/siswa/{siswaId}/tunggakan                                                  spp.view

 GET      /api/v1/keuangan/pembayaran-        PembayaranSppController@show               pembayaran-
          spp/{id}                                                                       spp.view

 PUT      /api/v1/keuangan/pembayaran-        PembayaranSppController@update             pembayaran-
          spp/{id}                                                                       spp.update

 DELETE   /api/v1/keuangan/pembayaran-        PembayaranSppController@destroy            pembayaran-
          spp/{id}                                                                       spp.delete


2.23. Modul: SPK (20 endpoints)
HTTP Path / Endpoint                                    Controller Action                    Required
Method                                                                                       Permission /
                                                                                             Middleware Access
 GET      /api/v1/spk/kriteria                          SpkKriteriaController@index           spk-
                                                                                             kriteria.view

 POST     /api/v1/spk/kriteria                          SpkKriteriaController@store           spk-
                                                                                             kriteria.create

 GET      /api/v1/spk/kriteria/total-bobot              SpkKriteriaController@totalBobot      spk-
                                                                                             kriteria.view

 GET      /api/v1/spk/kriteria/{id}                     SpkKriteriaController@show            spk-
                                                                                             kriteria.view

 PUT      /api/v1/spk/kriteria/{id}                     SpkKriteriaController@update          spk-
                                                                                             kriteria.update

 DELETE   /api/v1/spk/kriteria/{id}                     SpkKriteriaController@destroy         spk-
                                                                                             kriteria.delete

 GET      /api/v1/spk/penilaian                         SpkPenilaianController@index          spk-
                                                                                             penilaian.view

 POST     /api/v1/spk/penilaian                         SpkPenilaianController@store          spk-
                                                                                             penilaian.create

 GET      /api/v1/spk/penilaian/siswa/{siswaId}         SpkPenilaianController@bySiswa        spk-
                                                                                             penilaian.view

 GET      /api/v1/spk/penilaian/kriteria/{kriteriaId}   SpkPenilaianController@byKriteria     spk-
                                                                                             penilaian.view

 GET      /api/v1/spk/penilaian/{id}                    SpkPenilaianController@show           spk-
                                                                                             penilaian.view

 PUT      /api/v1/spk/penilaian/{id}                    SpkPenilaianController@update         spk-
                                                                                             penilaian.update

 DELETE   /api/v1/spk/penilaian/{id}                    SpkPenilaianController@destroy        spk-
                                                                                             penilaian.delete

 GET      /api/v1/spk/hasil                             SpkHasilController@index              spk-hasil.view
```

## PDF Page 24

```text
 POST     /api/v1/spk/hasil/calculate                   SpkHasilController@calculate           spk-
                                                                                              hasil.calculate

 POST     /api/v1/spk/hasil/auto-calculate              SpkHasilController@autoCalculate       spk-
                                                                                              hasil.calculate

 GET      /api/v1/spk/hasil/periode/{periode}           SpkHasilController@byPeriode           spk-hasil.view

 GET      /api/v1/spk/hasil/siswa/{siswaId}             SpkHasilController@bySiswa             spk-hasil.view

 GET      /api/v1/spk/hasil/{id}                        SpkHasilController@show                spk-hasil.view

 DELETE   /api/v1/spk/hasil/{id}                        SpkHasilController@destroy             spk-
                                                                                              hasil.delete


2.24. Modul: EKSTRAKURIKULER (18 endpoints)
HTTP Path / Endpoint                                                                 Controller Action
Method
 GET      /api/v1/ekstrakurikuler                                                    EkstrakurikulerController@

 POST     /api/v1/ekstrakurikuler                                                    EkstrakurikulerController@

 GET      /api/v1/ekstrakurikuler/aktif                                              EkstrakurikulerController@


 GET      /api/v1/ekstrakurikuler/pembina/{pembinaGuruId}                            EkstrakurikulerController@

 GET      /api/v1/ekstrakurikuler/pendaftaran                                        EkstrakurikulerSiswaContro

 POST     /api/v1/ekstrakurikuler/pendaftaran                                        EkstrakurikulerSiswaContro

 POST     /api/v1/ekstrakurikuler/pendaftaran/check-status                           EkstrakurikulerSiswaContro

 GET      /api/v1/ekstrakurikuler/pendaftaran/ekstrakurikuler/{ekstrakurikulerId}    EkstrakurikulerSiswaContro

 GET      /api/v1/ekstrakurikuler/pendaftaran/siswa/{siswaId}/riwayat                EkstrakurikulerSiswaContro

 GET      /api/v1/ekstrakurikuler/pendaftaran/siswa/{siswaId}                        EkstrakurikulerSiswaContro

 GET      /api/v1/ekstrakurikuler/pendaftaran/{id}                                   EkstrakurikulerSiswaContro

 PUT      /api/v1/ekstrakurikuler/pendaftaran/{id}/status                            EkstrakurikulerSiswaContro

 POST     /api/v1/ekstrakurikuler/pendaftaran/{id}/keluar                            EkstrakurikulerSiswaContro

 DELETE   /api/v1/ekstrakurikuler/pendaftaran/{id}                                   EkstrakurikulerSiswaContro

 GET      /api/v1/ekstrakurikuler/{id}                                               EkstrakurikulerController@

 PUT      /api/v1/ekstrakurikuler/{id}                                               EkstrakurikulerController@


 DELETE   /api/v1/ekstrakurikuler/{id}                                               EkstrakurikulerController@

 GET      /api/v1/ekstrakurikuler/{id}/statistik                                     EkstrakurikulerController@


2.25. Modul: ORGANISASI (22 endpoints)
HTTP Path / Endpoint                                            Controller Action                               Re
Method                                                                                                          Mi
 GET      /api/v1/organisasi/jabatan                             OrganisasiJabatanController@index              or

 POST     /api/v1/organisasi/jabatan                             OrganisasiJabatanController@store              or

 GET      /api/v1/organisasi/jabatan/all                         OrganisasiJabatanController@all                or
```

## PDF Page 25

```text
 GET      /api/v1/organisasi/jabatan/{id}                          OrganisasiJabatanController@show           or

 PUT      /api/v1/organisasi/jabatan/{id}                          OrganisasiJabatanController@update         or

 DELETE   /api/v1/organisasi/jabatan/{id}                          OrganisasiJabatanController@destroy        or

 GET      /api/v1/organisasi                                       OrganisasiController@index                 or

 POST     /api/v1/organisasi                                       OrganisasiController@store                 or

 GET      /api/v1/organisasi/aktif                                 OrganisasiController@aktif                 or

 GET      /api/v1/organisasi/pembina/{pembinaGuruId}               OrganisasiController@byPembina             or

 GET      /api/v1/organisasi/anggota                               OrganisasiAnggotaController@index          or

 POST     /api/v1/organisasi/anggota                               OrganisasiAnggotaController@store          or

 GET      /api/v1/organisasi/anggota/aktif                         OrganisasiAnggotaController@aktif          or

 GET      /api/v1/organisasi/anggota/organisasi/{organisasiId}     OrganisasiAnggotaController@byOrganisasi   or

 GET      /api/v1/organisasi/anggota/siswa/{siswaId}               OrganisasiAnggotaController@bySiswa        or

 GET      /api/v1/organisasi/anggota/{id}                          OrganisasiAnggotaController@show           or


 PUT      /api/v1/organisasi/anggota/{id}                          OrganisasiAnggotaController@update         or

 DELETE   /api/v1/organisasi/anggota/{id}                          OrganisasiAnggotaController@destroy        or

 GET      /api/v1/organisasi/{id}                                  OrganisasiController@show                  or

 PUT      /api/v1/organisasi/{id}                                  OrganisasiController@update                or

 DELETE   /api/v1/organisasi/{id}                                  OrganisasiController@destroy               or

 GET      /api/v1/organisasi/{id}/statistik                        OrganisasiController@statistik             or


2.26. Modul: ABSENSI-SISWA (4 endpoints)
HTTP      Path / Endpoint                      Controller Action                       Required
Method                                                                                 Permission /
                                                                                       Middleware Access
 GET       /api/v1/absensi-                    AbsensiSiswaController@bySiswa          absensi-
          siswa/siswa/{siswaId}                                                        siswa.view


 GET       /api/v1/absensi-                    AbsensiSiswaController@summary          absensi-
          siswa/siswa/{siswaId}/summary                                                siswa.view

 POST      /api/v1/absensi-siswa/date-range    AbsensiSiswaController@byDateRange      absensi-
                                                                                       siswa.view

 GET       /api/v1/absensi-siswa/{id}          AbsensiSiswaController@show             absensi-
                                                                                       siswa.view


2.27. Modul: REPORTS (9 endpoints)
HTTP Path / Endpoint                           Controller Action                         Required
Method                                                                                   Permission /
                                                                                         Middleware Access
 POST     /api/v1/reports/generate              JasperReportController@generate           reports.generate


 POST     /api/v1/reports/generate-async        JasperReportController@generateAsync      reports.generate
```

## PDF Page 26

```text
 GET      /api/v1/reports/status                    JasperReportController@status             reports.view

 GET      /api/v1/reports/list                      JasperReportController@list               reports.view

 GET      /api/v1/reports/parameters                JasperReportController@parameters         reports.view

 GET      /api/v1/reports/test                      JasperReportController@test               reports.test

 DELETE   /api/v1/reports/delete                    JasperReportController@delete             reports.delete

 DELETE   /api/v1/reports/clean                     JasperReportController@clean              reports.clean

 GET      /api/v1/reports/download/{filename}       Closure@                                  reports.view


2.28. Modul: WHATSAPP (9 endpoints)
HTTP   Path / Endpoint                        Controller Action                         Required Permission /
Method                                                                                  Middleware Access
 GET      /api/v1/whatsapp/session             WahaWebhookController@sessionStatus       waha.view

 POST     /api/v1/whatsapp/session/start       WahaWebhookController@startSession        waha.manage

 POST     /api/v1/whatsapp/session/stop        WahaWebhookController@stopSession         waha.manage

 GET      /api/v1/whatsapp/qr                  WahaWebhookController@qrCode              waha.view

 GET      /api/v1/whatsapp/devices             WahaWebhookController@listDevices         waha.view


 POST     /api/v1/whatsapp/send                WahaWebhookController@sendMessage         waha.send

 POST     /api/v1/whatsapp/notify/spp          WahaWebhookController@notifySpp           waha.notify.spp

 POST     /api/v1/whatsapp/notify/ppdb         WahaWebhookController@notifyPpdb          waha.notify.ppdb

 POST     /api/v1/whatsapp/notify/ews          WahaWebhookController@notifyEws           waha.notify.ews


2.29. Modul: EMAIL (5 endpoints)
HTTP        Path / Endpoint               Controller Action                          Required Permission /
Method                                                                               Middleware Access
 POST       /api/v1/email/offer           MarketingEmailController@sendOffer         email.send

 POST       /api/v1/email/send            MarketingEmailController@sendCustom        email.send

 GET        /api/v1/email/inbox           MarketingEmailController@getInbox          Role: superadmin &
                                                                                     Perm: email.view

 GET        /api/v1/email/inbox/{id}      MarketingEmailController@showInbox         Role: superadmin &
                                                                                     Perm: email.view

 DELETE     /api/v1/email/inbox/{id}      MarketingEmailController@deleteInbox       Role: superadmin &
                                                                                     Perm: email.send


2.30. Modul: WEBHOOK (3 endpoints)
HTTP        Path / Endpoint          Controller Action                             Required Permission /
Method                                                                             Middleware Access
 POST       /api/webhook/saungwa       WahaWebhookController@receive                Public (No Auth)

 POST       /api/webhook/waha          WahaWebhookController@receive                Public (No Auth)

 POST       /api/webhook/resend        ResendInboundWebhookController@receive       Public (No Auth)
```

## PDF Page 27

```text
2.31. Modul: WEBHOOKS (1 endpoints)
HTTP          Path / Endpoint               Controller Action                   Required Permission /
Method                                                                          Middleware Access
 POST         /api/v1/webhooks/midtrans     MidtransWebhookController@handle    Public (No Auth)


2.32. Modul: CHATBOT (2 endpoints)
HTTP          Path / Endpoint             Controller Action                 Required Permission / Middleware
Method                                                                      Access
 POST          /api/v1/chatbot/message    ChatbotController@message         chatbot.message

 DELETE        /api/v1/chatbot/session    ChatbotController@clearSession    chatbot.session


2.33. Modul: BROADCASTING (1 endpoints)
HTTP Method       Path / Endpoint   Controller Action            Required Permission / Middleware Access
`GET              POST`             /api/broadcasting/auth       BroadcastController@authenticate
```
