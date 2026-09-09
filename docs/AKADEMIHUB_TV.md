Android TV AkademiHub berfungsi sebagai **layar informasi sekolah dan pendukung kegiatan kelas**, bukan versi penuh aplikasi HP.

## 1. Mode Signage Publik

Dipasang di lobi, koridor, ruang tunggu, kantin, atau ruang guru.

### Yang ditampilkan

1. **Overview sekolah**
   - Logo dan nama sekolah
   - Jam dan tanggal
   - Pesan sambutan
   - Status koneksi/data terakhir diperbarui

2. **Jadwal hari ini**
   - Mata pelajaran
   - Nama guru
   - Kelas dan ruang
   - Jam mulai–selesai
   - Pelajaran yang sedang berlangsung

3. **Pengumuman**
   - Informasi sekolah
   - Perubahan jadwal
   - Pengingat upacara
   - Informasi lomba/kegiatan
   - Poster atau gambar pengumuman

4. **Kalender dan agenda**
   - Ujian
   - Libur sekolah
   - Rapat
   - Kegiatan sekolah
   - Agenda ekstrakurikuler

5. **Ringkasan presensi**
   - Jumlah hadir
   - Terlambat
   - Tidak hadir
   - Total siswa
   - Persentase kehadiran

Data presensi hanya agregat. **Nama, NIS, foto, dan detail siswa tidak ditampilkan.**

### Fungsinya

- Menggantikan papan pengumuman manual.
- Menyebarkan informasi secara otomatis.
- Menampilkan agenda dan jadwal terbaru.
- Memberikan gambaran operasional sekolah hari itu.
- Berjalan sebagai carousel otomatis tanpa operator.

---

## 2. Mode Display Kelas

Dipasang pada Smart TV di ruang kelas atau laboratorium.

### Yang ditampilkan

1. **Identitas kelas**
   - Nama kelas
   - Wali kelas
   - Ruangan
   - Tanggal dan jam

2. **Pelajaran aktif**
   - Mata pelajaran saat ini
   - Nama guru
   - Jam selesai
   - Countdown pergantian pelajaran

3. **Pelajaran berikutnya**
   - Mata pelajaran selanjutnya
   - Guru
   - Jam mulai

4. **Agenda kelas**
   - Jadwal ujian
   - Deadline tugas
   - Kegiatan kelas
   - Jadwal piket jika datanya tersedia

5. **Pengumuman kelas**
   - Pengumuman khusus kelas
   - Perubahan jadwal
   - Informasi dari wali kelas atau sekolah

6. **Materi pembelajaran**
   - Judul materi
   - Gambar/poster pembelajaran
   - Materi yang secara khusus ditandai layak tayang
   - Detail materi sederhana

### Fungsinya

- Menjadi dashboard kegiatan kelas.
- Membantu siswa melihat pelajaran aktif dan berikutnya.
- Menampilkan informasi tanpa guru membuka aplikasi HP.
- Menjadi layar presentasi materi sederhana.
- Mengurangi keterlambatan pergantian jam pelajaran.

---

## 3. Sistem Pairing TV

Saat pertama dipasang, TV menampilkan:

- Kode pairing 6 karakter, contoh `AB7K9Q`
- Alamat halaman aktivasi
- Batas waktu kode
- Status menunggu persetujuan
- Tombol membuat kode baru

Admin memasukkan kode melalui web/mobile, lalu menentukan:

- Nama perangkat, misalnya `TV Lobby Utama`
- Mode `signage` atau `classroom`
- Kelas terkait jika memakai mode classroom

### Fungsinya

- Tidak perlu mengetik username/password di remote TV.
- Satu TV dapat dibatasi untuk satu sekolah atau kelas.
- Perangkat dapat dinonaktifkan dari dashboard admin.
- TV tidak menerima seluruh permission akun admin.

---

## 4. Operasional Otomatis

Setelah pairing, TV akan:

- Mengambil data terbaru secara berkala.
- Memindahkan slide otomatis.
- Menyimpan snapshot terakhir.
- Tetap menampilkan data terakhir saat internet terputus.
- Menampilkan label **“Offline — terakhir diperbarui …”**.
- Pairing ulang jika perangkat dicabut oleh admin.
- Pause saat pengguna memakai remote.
- Melanjutkan carousel setelah 30 detik tanpa interaksi.

Remote dapat digunakan untuk:

- Kiri/kanan: pindah slide.
- Atas/bawah: memilih kontrol.
- OK/Enter: membuka detail atau retry.
- Back: kembali atau membuka konfirmasi keluar.

---

## Tidak Ditampilkan di Android TV

Karena TV merupakan layar bersama:

- Nilai individual siswa
- Rapor
- Detail pembayaran atau tunggakan
- Kasus BK dan EWS individual
- Nama siswa yang absen
- Presensi GPS/selfie
- Chat pribadi
- Pengerjaan ujian
- Pengumpulan tugas
- Form input/edit data
- Informasi pribadi wali, guru, atau siswa

## Ringkasnya

| Lokasi | Mode | Fungsi utama |
|---|---|---|
| Lobi | Signage | Pengumuman dan profil sekolah |
| Koridor | Signage | Jadwal, agenda, informasi kegiatan |
| Ruang guru | Signage internal | Jadwal dan ringkasan presensi |
| Ruang kelas | Classroom | Pelajaran aktif, agenda, materi |
| Laboratorium | Classroom | Jadwal lab dan materi pembelajaran |

**MVP paling berguna:** jam + pengumuman + jadwal + agenda + presensi agregat dalam carousel otomatis.