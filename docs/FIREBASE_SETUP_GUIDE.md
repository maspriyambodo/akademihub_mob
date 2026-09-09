# Panduan Setup Firebase — AkademiHub Mobile

Dokumentasi lengkap konfigurasi Firebase (Cloud Messaging / Push Notifications) untuk aplikasi AkademiHub Mobile (Android & iOS).

---

## 1. Metadata Proyek

| Parameter | Nilai |
|---|---|
| **Firebase Project Name** | `akademihub` |
| **Firebase Project ID** | `akademihub-40e1c` |
| **Android Package Name** | `id.akademihub.akademihub_mob` |
| **iOS Bundle Identifier** | `id.akademihub.akademihubMob` |
| **Target Directory** | `akademihub_mob/` |

---

## 2. Metode 1: Otomatis via FlutterFire CLI (Direkomendasikan)

### Langkah 1: Install Tools
```bash
# Install Firebase CLI secara global
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

> **Catatan PATH:** Pastikan direktori global Pub ada di `PATH` shell Anda (tambahkan ke `~/.zshrc` jika belum):
> ```bash
> export PATH="$PATH":"$HOME/.pub-cache/bin"
> ```

### Langkah 2: Login ke Firebase
```bash
firebase login
```
*Browser akan terbuka, login menggunakan akun Google yang memiliki akses ke project `akademihub`.*

### Langkah 3: Jalankan Konfigurasi FlutterFire
```bash
cd /Users/bodo/www/akademihub_repo/akademihub_mob
flutterfire configure --project=akademihub-40e1c
```
1. Pilih platform: **android** dan **ios** (gunakan tombol spasi untuk memilih, lalu tekan Enter).
2. Konfirmasi overwrite jika diminta.
3. CLI akan otomatis:
   - Meregistrasikan aplikasi Android & iOS ke Firebase Project `akademihub-40e1c`.
   - Mengunduh `google-services.json` ke `android/app/`.
   - Mengunduh `GoogleService-Info.plist` ke `ios/Runner/`.
   - Membuat file konfigurasi Dart di `lib/firebase_options.dart`.

---

## 3. Metode 2: Setup Manual via Firebase Console

Jika tidak menggunakan CLI, ikuti langkah berikut:

### A. Setup Android
1. Buka [Firebase Console](https://console.firebase.google.com/project/akademihub-40e1c/overview).
2. Klik tombol **Add app** (ikon Android).
3. Isi data:
   - **Android package name**: `id.akademihub.akademihub_mob`
   - **App nickname**: `AkademiHub Android`
4. Download file `google-services.json`.
5. Simpan file ke direktori:
   ```
   akademihub_mob/android/app/google-services.json
   ```
6. Tambahkan Google Services Gradle Plugin:
   - **`android/settings.gradle.kts`**:
     ```kotlin
     plugins {
         id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
         id("com.android.application") version "8.7.0" apply false
         id("org.jetbrains.kotlin.android") version "2.1.0" apply false
         id("com.google.gms.google-services") version "4.4.2" apply false
     }
     ```
   - **`android/app/build.gradle.kts`**:
     ```kotlin
     plugins {
         id("com.android.application")
         id("kotlin-android")
         id("dev.flutter.flutter-gradle-plugin")
         id("com.google.gms.google-services")
     }
     ```

---

### B. Setup iOS
1. Di Firebase Console, klik **Add app** (ikon iOS).
2. Isi data:
   - **Apple bundle ID**: `id.akademihub.akademihubMob`
   - **App nickname**: `AkademiHub iOS`
3. Download file `GoogleService-Info.plist`.
4. Buka workspace Xcode:
   ```bash
   open akademihub_mob/ios/Runner.xcworkspace
   ```
5. Drag and drop file `GoogleService-Info.plist` ke folder `Runner` di navigator Xcode.
   - Pastikan opsi **Copy items if needed** dicentang.
   - Pastikan target **Runner** dicentang.
6. Konfigurasi APNs (Apple Push Notification service):
   - Masuk ke **Project Settings > Cloud Messaging** di Firebase Console.
   - Di bagian **Apple app configuration**, upload **APNs Authentication Key (`.p8`)** dari Apple Developer Console.

---

## 4. Konfigurasi Kode Flutter

### Update `lib/main.dart`
Setelah file `lib/firebase_options.dart` dibuat oleh CLI:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'core/notifications/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await configureDependencies();
  await sl<PushNotificationService>().initialize();
  runApp(const AkademiHubApp());
}
```

---

## 5. Integrasi Push Notification & Backend

Service notifikasi berada di `lib/core/notifications/push_notification_service.dart`.

### Endpoint Backend yang Terlibat:
1. **Pendaftaran Token FCM:**
   - Method: `POST /fcm/token`
   - Body: `{ "token": "<fcm_device_token>" }`
   - Dipanggil saat: Aplikasi inisialisasi & token refresh.
2. **Penghapusan Token FCM:**
   - Method: `DELETE /fcm/token`
   - Dipanggil saat: User logout.

---

## 6. Verifikasi & Pengujian

1. **Jalankan aplikasi di Android Emulator/Device:**
   ```bash
   flutter run -d android
   ```
2. **Kirim Pesan Uji Coba dari Firebase Console:**
   - Masuk ke menu **Engage > Messaging** di Firebase Console.
   - Klik **New campaign > Notifications**.
   - Masukkan judul & isi pesan.
   - Klik **Send test message** menggunakan FCM Token dari log device.
   - Pastikan notifikasi muncul di status bar aplikasi.
