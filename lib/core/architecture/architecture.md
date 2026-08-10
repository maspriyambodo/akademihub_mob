# Arsitektur AkademiHub Mobile

Pola yang dipakai: **feature-first Clean Architecture** + **BLoC** (bukan MVVM/`ChangeNotifier`).

Skill “Architecting Flutter Applications” memetakan ViewModel → BLoC, Service → DataSource, Domain Model → Entity.

## Lapisan

```
presentation/   → pages, widgets, bloc (event/state)   UI + state
domain/         → entities, repositories (abstrak), usecases
data/           → models, datasources, repository_impl
core/           → api, di, router, theme, storage, utils
```

Alur dependensi **hanya ke dalam**:

```
Page → Bloc → UseCase → Repository (interface) → RepositoryImpl → DataSource → ApiClient
```

## Aturan wajib

1. **Page/widget tidak memanggil HTTP, repository, atau datasource.** Hanya `Bloc` + event.
2. **Bloc tidak mengimpor `data/`.** Hanya UseCase / Entity / storage core.
3. **Domain tidak mengimpor Flutter UI** (`package:flutter/material`).
4. **Data tidak mengimpor presentation.**
5. Registrasi DI di `core/di/injection.dart` untuk setiap feature baru.
6. Page form “bodoh” (mis. `ForumFormPage`) boleh tanpa Bloc jika hanya `Navigator.pop(result)` — pemanggil yang mengirim event ke Bloc.

## Struktur satu fitur

```text
features/[nama]/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

## Fitur yang terdaftar di DI

absensi, auth, bk, dashboard, ews, ekstrakurikuler, forum, jadwal, kalender, keuangan, materi, nilai, notifications, ppdb, profil, rapor, **siswa_insight**, **tenant**, tmb, tugas, ujian.
