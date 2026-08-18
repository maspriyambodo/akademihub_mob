# DOKUMENTASI REFACTORING: IMPLEMENTASI KIOSK MODE & ANTI-CURANG PADA MODULE UJIAN (CBT)

## 1. Executive Summary & Ringkasan Solusi
Dokumen ini mengatur refactoring teknis pada module Ujian Mobile (`akademihub_mob`) dan Backend (`sekolah_go/exam-engine` & `sekolah`) untuk mengamankan pelaksanaan Ujian Online / CBT dari kecurangan siswa.

### Konsep Utama
Menggabungkan **Kiosk Mode (App Lock)** sebagai proteksi layer utama, **Background Alarm Fallback** (override silent mode), dan **Violation Telemetry Real-time** ke backend.

---

## 2. Arsitektur Proteksi Multi-Layer

```
[ Siswa Mulai Ujian ]
        │
        ├──► Layer 1: OS Kiosk Mode (Hard Lock)
        │      ├── Android: Lock Task Mode (App Pinning)
        │      └── iOS: Guided Access / Autonomous Single App Mode (ASAM)
        │
        ├──► Layer 2: Security Guard (FLAG_SECURE & Screen Capture Detection)
        │
        ├──► Layer 3: AppState Fallback & Sound Override (Bypass Silent)
        │
        └──► Layer 4: Backend Violation Telemetry & Auto-Submit Engine
```

---

## 3. Spesifikasi Implementation Layer

### Layer 1: Native Kiosk Mode Implementation (Flutter Client)

#### A. Android Configuration (`MainActivity.kt`)
```kotlin
package com.akademihub.app

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.akademihub.app/kiosk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKioskMode" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        startLockTask()
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    } else {
                        result.error("UNSUPPORTED", "SDK not supported", null)
                    }
                }
                "stopKioskMode" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        stopLockTask()
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    } else {
                        result.error("UNSUPPORTED", "SDK not supported", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

#### B. iOS Configuration (`AppDelegate.swift`)
```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let kioskChannel = FlutterMethodChannel(name: "com.akademihub.app/kiosk",
                                              binaryMessenger: controller.binaryMessenger)
    
    kioskChannel.setMethodCallHandler({ (call, result) in
      if call.method == "startKioskMode" {
        UIAccessibility.requestGuidedAccessSession(enabled: true) { success in result(success) }
      } else if call.method == "stopKioskMode" {
        UIAccessibility.requestGuidedAccessSession(enabled: false) { success in result(success) }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

### Layer 2: Audio Session Guard (Bypass Silent Switch)

#### Audio Controller (`exam_alarm_service.dart`)
```dart
import 'package:audioplayers/audioplayers.dart';

class ExamAlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> initAudio() async {
    await _audioPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: [AVAudioSessionOptions.duckOthers, AVAudioSessionOptions.mixWithOthers],
      ),
      android: AudioContextAndroid(
        isContentAlarm: true,
        usageType: AndroidUsageType.alarm,
        contentType: AndroidContentType.sonification,
        audioFocus: AndroidAudioFocus.gainTransientExclusive,
      ),
    ));
  }

  static Future<void> triggerViolationAlarm() async {
    await _audioPlayer.play(AssetSource('sounds/cheat_alarm.mp3'), volume: 1.0);
  }

  static Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }
}
```

---

### Layer 3: Exam Screen Lifecycle & Anti-Cheat Logic

#### Flutter Integration (`exam_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExamScreen extends StatefulWidget {
  final String ujianId;
  const ExamScreen({Key? key, required this.ujianId}) : super(key: key);

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  static const kioskChannel = MethodChannel('com.akademihub.app/kiosk');
  int _violationCount = 0;
  final int _maxAllowedViolations = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableKioskSecurity();
  }

  Future<void> _enableKioskSecurity() async {
    try {
      await kioskChannel.invokeMethod('startKioskMode');
      await ExamAlarmService.initAudio();
    } on PlatformException catch (e) {
      debugPrint("Kiosk Error: ${e.message}");
    }
  }

  Future<void> _disableKioskSecurity() async {
    try {
      await kioskChannel.invokeMethod('stopKioskMode');
      await ExamAlarmService.stopAlarm();
    } on PlatformException catch (e) {
      debugPrint("Kiosk Error: ${e.message}");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _handleViolation("APP_MINIMIZED");
    } else if (state == AppLifecycleState.resumed) {
      ExamAlarmService.stopAlarm();
    }
  }

  Future<void> _handleViolation(String type) async {
    _violationCount++;
    await ExamAlarmService.triggerViolationAlarm();
    await _reportViolationToBackend(type, _violationCount);

    if (_violationCount >= _maxAllowedViolations) {
      await _forceSubmitExam("Batas pelanggaran keluar aplikasi terlampaui.");
    }
  }

  Future<void> _reportViolationToBackend(String type, int count) async {
    // API Call: POST /api/v1/akademik/ujian/:id/violation
  }

  Future<void> _forceSubmitExam(String reason) async {
    await _disableKioskSecurity();
    // Auto Submit Exam Logic
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableKioskSecurity();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Blok tombol back
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ujian Online"),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text("Halaman Ujian Berlangsung")),
      ),
    );
  }
}
```

---

## 4. Backend Schema & Telemetry Integration

### Migration (`trx_ujian_violation_logs`)
```sql
CREATE TABLE trx_ujian_violation_logs (
    id BIGSERIAL PRIMARY KEY,
    trx_ujian_id BIGINT NOT NULL,
    mst_siswa_id BIGINT NOT NULL,
    violation_type VARCHAR(50) NOT NULL,
    violation_count INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_violation_ujian FOREIGN KEY (trx_ujian_id) REFERENCES trx_ujian(id) ON DELETE CASCADE,
    CONSTRAINT fk_violation_siswa FOREIGN KEY (mst_siswa_id) REFERENCES mst_siswa(id) ON DELETE CASCADE
);

CREATE INDEX idx_violation_ujian_siswa ON trx_ujian_violation_logs(trx_ujian_id, mst_siswa_id);
```

### Telemetry API Contract
- **Endpoint**: `POST /api/v1/akademik/ujian/{id}/violation`
- **Behavior**: Jika total `violation_count` >= 3, set `status_sesi = 4` (Auto-Submitted / Blocked).

---

## 5. Checklist Verifikasi & QA Testing

- [ ] **Lock Task Test (Android)**: Tombol Home, Recent Apps, dan Status Bar terpencil.
- [ ] **Guided Access Test (iOS)**: Gesture swipe-up ke home screen diblokir.
- [ ] **Silent Bypass Test**: HP Mode Silent -> Minimalkan App -> Alarm tetap berbunyi via `STREAM_ALARM`/`Playback`.
- [ ] **Anti Screenshot Test**: `FLAG_SECURE` aktif, hasil capture hitam/blank.
- [ ] **Telemetry Test**: Violation log tercatat di DB `trx_ujian_violation_logs`.
- [ ] **Auto Force-Submit Test**: 3x pelanggaran otomatis mengunci dan submit sesi ujian.

---
`ponytail:` implementation boundary set for native Flutter method channel bridge & Go telemetry handler. upgrade path: MDM (Mobile Device Management) auto-enrollment for school-owned devices.
