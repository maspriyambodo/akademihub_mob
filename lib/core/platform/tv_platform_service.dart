import 'package:flutter/services.dart';

class TvPlatformService {
  final MethodChannel _channel;

  const TvPlatformService([
    MethodChannel channel = const MethodChannel('id.akademihub/device'),
  ]) : _channel = channel;

  Future<bool> isTelevision() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTelevision');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> applyTvDisplayMode() async {
    // Android TV hardware is natively landscape. Calling setPreferredOrientations
    // before the first frame triggers redundant window insets resize and
    // SurfaceSyncGroup timeouts on Android TV emulators.
    await restoreImmersiveMode();
  }

  Future<void> restoreImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}
