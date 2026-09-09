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
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await restoreImmersiveMode();
  }

  Future<void> restoreImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}
