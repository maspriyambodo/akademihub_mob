# Testing Manual Mobile

## Status Lingkungan

- Backend: `http://127.0.0.1:8002` sehat, health check `200`.
- Android emulator memakai API `http://10.0.2.2:8002/api/v1`.
- Akun uji sudah diverifikasi login pada `2026-08-21`.
- Jika pernah login sebelum database di-reset, logout lalu login ulang untuk token dan izin terbaru.

## Akun Uji

| Role | Email | Password | Fokus |
|---|---|---|---|
| Superadmin | `abiyusuf@sekolah.com` | `12345abi` | Seluruh modul, data lintas kelas |
| Guru | `guru@sman1-example.sch.id` | `password` | Kelas, absensi, nilai, tugas, ujian |
| Siswa | `siswa@sman1-example.sch.id` | `password` | Data pribadi, tugas, ujian, nilai |

## Bukti Uji

Untuk setiap kasus, catat status `Lulus` atau `Gagal`, screenshot, pesan error, waktu, role, dan ID data terkait. Gunakan kasus gagal sebagai temuan bug; jangan lanjutkan perubahan data bila hasilnya tidak sesuai.

## Pra-Kondisi

1. Pastikan Docker backend hidup: `docker compose ps` dari `sekolah_pintar`.
2. Pastikan health `200`: `http://127.0.0.1:8002/api/v1/health`.
3. Jalankan Android emulator, lalu `flutter run -d emulator-5554` dari `akademihub_mob`.
4. Hapus data aplikasi atau logout sebelum mengganti role.

## P0: Autentikasi Dan Navigasi

| ID | Role | Langkah | Hasil Harapan |
|---|---|---|---|
| AUTH-01 | Semua | Buka aplikasi tanpa sesi | Splash lalu Login tampil. |
| AUTH-02 | Semua | Submit email/password kosong | Validasi field wajib tampil. |
| AUTH-03 | Semua | Masukkan email tidak valid | Pesan format email tampil. |
| AUTH-04 | Semua | Password kurang dari 6 karakter | Pesan minimum 6 karakter tampil. |
| AUTH-05 | Semua | Login akun uji | Dashboard role terkait tampil. Tidak ada error HTTP. |
| AUTH-06 | Semua | Login password salah | Pesan kredensial tidak valid. Tetap di Login. |
| AUTH-07 | Semua | Tekan ikon mata password | Password berganti tersembunyi/terlihat. |
| AUTH-08 | Semua | Tutup-buka aplikasi setelah login | Sesi dipulihkan, Dashboard tampil. |
| AUTH-09 | Semua | Dashboard, menu titik tiga, Keluar | Kembali Login. Buka ulang tetap Login. |
| NAV-01 | Semua | Pindah Dashboard, Absensi, Jadwal, Nilai, Tugas | Halaman dan tab aktif berubah sesuai pilihan. |
| NAV-02 | Semua | Ubah portrait/landscape | Tidak overflow, teks dan tombol tetap dapat dijangkau. |

## P0: Dashboard Dan Data Dasar

| ID | Role | Langkah | Hasil Harapan |
|---|---|---|---|
| DASH-01 | Superadmin | Login, tarik refresh Dashboard | Ringkasan admin termuat ulang tanpa error. |
| DASH-02 | Guru | Login, tarik refresh Dashboard | Ringkasan guru termuat, data terkait pengajaran terlihat. |
| DASH-03 | Siswa | Login, tarik refresh Dashboard | Ringkasan siswa termuat, data pribadi relevan. |
| DATA-01 | Semua | Buka Absensi | Daftar/ringkasan tampil sesuai role. |
| DATA-02 | Semua | Buka Jadwal | Jadwal kelas tampil, hari/mapel/jam terbaca. |
| DATA-03 | Semua | Buka Nilai | Nilai tampil sesuai akses role. |
| DATA-04 | Semua | Buka Tugas, buka satu detail | Judul, instruksi, tenggat, status tampil. |
| DATA-05 | Semua | Pull-to-refresh pada halaman berdata | Loading selesai, data tidak duplikat. |

## P1: Modul Akademik

| ID | Role | Langkah | Hasil Harapan |
|---|---|---|---|
| AKA-01 | Superadmin | Buka Ujian, pilih kelas, buka daftar ujian | Daftar ujian kelas tampil. |
| AKA-02 | Guru | Buka Ujian, pilih kelas yang diajar | Daftar ujian dan ranking sesuai izin tampil. |
| AKA-03 | Siswa | Buka Ujian | Hanya ujian/sesi kelas siswa tampil. Tidak dapat melihat nilai seluruh kelas. |
| AKA-04 | Guru/Superadmin | Buka detail nilai ujian | Nilai siswa, statistik, status ujian tampil. |
| AKA-05 | Siswa | Buka sesi ujian, mulai, jawab satu soal, kembali | Jawaban tersimpan dan status sesi konsisten. |
| AKA-06 | Guru/Superadmin | Buka Ranking kelas | Ranking tampil sesuai kelas terpilih. |
| AKA-07 | Guru/Superadmin | Ubah kelas dari pemilih | Semua data berubah ke kelas baru, bukan data kelas lama. |
| AKA-08 | Semua | Jika muncul `403 Forbidden` pada Ujian | Catat role, kelas, URL, waktu. Logout-login ulang sekali. Bila berulang, tandai gagal. |

## P1: Modul Pendukung

| ID | Role | Langkah | Hasil Harapan |
|---|---|---|---|
| SUP-01 | Semua | Buka notifikasi dari lonceng Dashboard | Daftar notifikasi tampil. |
| SUP-02 | Semua | Buka Profil | Profil user dan role benar. |
| SUP-03 | Semua | Buka Materi, lalu detail/lampiran | Detail tampil; lampiran/video dapat dibuka atau pesan error jelas. |
| SUP-04 | Semua | Buka Forum | Daftar diskusi tampil; buka detail. |
| SUP-05 | Semua | Buka Ekstrakurikuler | Daftar dan keanggotaan sesuai role tampil. |
| SUP-06 | Semua | Buka Kalender | Event akademik tampil. |
| SUP-07 | Superadmin/Guru berizin | Buka BK dan EWS | Kasus/risk alert tampil bila permission tersedia. |
| SUP-08 | Semua | Buka Keuangan | Tagihan/riwayat sesuai role tampil. |
| SUP-09 | Semua | Buka Tes Minat Bakat | Daftar tes/hasil sesuai role tampil. |

## P1: PPDB Publik

| ID | Role | Langkah | Hasil Harapan |
|---|---|---|---|
| PPDB-01 | Tanpa login | Dari Login buka Portal PPDB | Portal terbuka tanpa autentikasi. |
| PPDB-02 | Tanpa login | Tab Gelombang, pilih sekolah | Gelombang aktif tampil. |
| PPDB-03 | Tanpa login | Tab Daftar, submit form kosong | Pesan validasi field/sekolah/gelombang/dokumen tampil. |
| PPDB-04 | Tanpa login | Upload PDF/JPG/PNG <=2 MB | File diterima. |
| PPDB-05 | Tanpa login | Upload file >2 MB | File ditolak dengan pesan ukuran maksimum. |
| PPDB-06 | Tanpa login | Lengkapi form dan 4 dokumen valid | Nomor pendaftaran sukses tampil. |
| PPDB-07 | Tanpa login | Tab Cek Status, nomor kosong/valid | Validasi nomor kosong; status tampil untuk nomor valid. |

## P1: Ketahanan

| ID | Role | Langkah | Hasil Harapan |
|---|---|---|---|
| ERR-01 | Semua | Matikan jaringan perangkat, buka halaman data | Pesan gagal jelas, aplikasi tidak crash. |
| ERR-02 | Semua | Aktifkan jaringan, tekan Coba Lagi/refresh | Data berhasil dimuat kembali. |
| ERR-03 | Semua | Tekan Back Android dari halaman detail | Kembali halaman sebelumnya tanpa logout. |
| ERR-04 | Semua | Perbesar ukuran teks sistem | Layout dapat dibaca, tidak ada tombol utama hilang. |

## Kriteria Selesai

- Semua P0 lulus untuk Superadmin, Guru, Siswa.
- Semua P1 yang permission-nya tersedia lulus atau memiliki temuan tercatat.
- Tidak ada crash, layar putih, loop loading, atau `500`.
- Setiap `401` setelah login atau `403` pada modul yang seharusnya tersedia dicatat sebagai bug dengan screenshot dan URL.

## Audit Cakupan Guru Dan Siswa

Status ini adalah cakupan frontend saat ini. Izin backend, tenant isolation,
serta owner/self tetap wajib diverifikasi oleh integration test backend.

| Modul | Guru | Siswa | Status frontend |
|---|---|---|---|
| Absensi | Lihat absensi guru/kelas menurut izin | Check-in dan riwayat sendiri | Perlu uji owner/self backend |
| Jadwal | Jadwal mengajar dan pemilih kelas | Jadwal kelas sendiri | Read-only |
| Nilai | Cari/filter dan CRUD dengan `nilai.*` | Nilai/ringkasan sendiri | Selector hanya dari data scoped yang sudah dimuat |
| Rapor | Daftar/detail/export dan CRUD dengan `rapor.*` | Lihat rapor sendiri | Selector hanya dari data scoped yang sudah dimuat |
| Tugas | Publikasi, edit/hapus milik sendiri, nilai pengumpulan | Lihat/detail/kumpulkan dengan `tugas-siswa.create` | Backend tetap menentukan ownership |
| Materi | Publikasi, edit/hapus milik sendiri, statistik | Lihat materi dan catat akses | Backend tetap menentukan ownership |
| Forum | Buat/ubah/hapus menurut `forum.*` | Buat/ubah/hapus menurut `forum.*` | Tidak ada balasan forum pada API mobile |
| Ujian | Lihat ujian/ranking, generate/export menurut `ranking.*` | Sesi, jawab, selesai | CRUD ujian dan koreksi jawaban belum tersedia |
| BK | Kasus, sesi, hasil, tindakan menurut izin | Tidak tersedia | Edit/hapus dan lampiran belum tersedia |
| EWS | Proses siswa menurut izin | Tidak tersedia | Detail/resolve bergantung EWS worker |
| Ekstrakurikuler | Lihat ekskul binaan | Daftar dan keluar | Kelola program/status pendaftaran belum lengkap |
| Keuangan | Lihat laporan; pembayaran hanya `pembayaran-spp.bayar` | Riwayat/tunggakan, pembayaran online bila izin | Wali memilih anak dari relasi backend; pelunasan tunai diblokir |
| TMB | Lihat tes/peserta menurut izin | Daftar, mulai, jawab, selesai menurut izin | Wali memilih anak dari relasi backend |
| Perpustakaan | Katalog buku menurut izin | Katalog dan riwayat pinjaman sendiri | Read-only, tanpa pinjam/kembali |
| Organisasi | Katalog/detail/anggota menurut izin | Katalog/detail/anggota menurut izin | Read-only, tanpa mutasi anggota |
| PPDB Publik | Tidak perlu login | Tidak perlu login | Sekolah, gelombang, daftar dokumen, cek status |

### Gap Yang Harus Ditutup Bertahap

- [ ] Ujian: CRUD ujian/sesi, koreksi jawaban, role owner/self backend test.
- [ ] BK/EWS/Ekstrakurikuler/Keuangan: operasi manajemen yang tersedia di API.
- [ ] Wali: perlu pemilih anak terintegrasi ke absensi, jadwal, nilai, rapor, tugas.
- [ ] Semua modul ID-based: backend test untuk tenant dan owner/self.
