import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class ExamAlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _initialized = false;

  static Future<void> initAudio() async {
    try {
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('ExamAlarmService init error: $e');
    }
  }

  static Future<void> triggerViolationAlarm() async {
    try {
      if (!_initialized) {
        await initAudio();
      }
      await _audioPlayer.play(
        AssetSource('sounds/cheat_alarm.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('ExamAlarmService trigger error: $e');
    }
  }

  static Future<void> stopAlarm() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('ExamAlarmService stop error: $e');
    }
  }
}

