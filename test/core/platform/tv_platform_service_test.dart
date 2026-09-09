import 'package:akademihub_mob/core/platform/tv_platform_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('id.akademihub/device');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('TvPlatformService', () {
    test('isTelevision returns true when native method returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isTelevision') return true;
            return null;
          });

      const service = TvPlatformService(channel);
      final isTv = await service.isTelevision();
      expect(isTv, isTrue);
    });

    test(
      'isTelevision returns false when native method returns false',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'isTelevision') return false;
              return null;
            });

        const service = TvPlatformService(channel);
        final isTv = await service.isTelevision();
        expect(isTv, isFalse);
      },
    );

    test(
      'isTelevision returns false when native method returns null',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async => null);

        const service = TvPlatformService(channel);
        final isTv = await service.isTelevision();
        expect(isTv, isFalse);
      },
    );

    test(
      'isTelevision returns false when native call throws PlatformException',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              throw PlatformException(
                code: 'UNAVAILABLE',
                message: 'Not android',
              );
            });

        const service = TvPlatformService(channel);
        final isTv = await service.isTelevision();
        expect(isTv, isFalse);
      },
    );

    test(
      'isTelevision returns false when native call throws MissingPluginException',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              throw MissingPluginException();
            });

        const service = TvPlatformService(channel);
        final isTv = await service.isTelevision();
        expect(isTv, isFalse);
      },
    );

    test(
      'applyTvDisplayMode invokes system orientations and immersive mode',
      () async {
        final log = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              log.add(call);
              return null;
            });

        const service = TvPlatformService(channel);
        await service.applyTvDisplayMode();

        expect(
          log.any(
            (call) =>
                call.method == 'SystemChrome.setPreferredOrientations' &&
                (call.arguments as List).contains(
                  'DeviceOrientation.landscapeLeft',
                ) &&
                (call.arguments as List).contains(
                  'DeviceOrientation.landscapeRight',
                ),
          ),
          isTrue,
        );
        expect(
          log.any(
            (call) =>
                call.method == 'SystemChrome.setEnabledSystemUIMode' &&
                call.arguments == 'SystemUiMode.immersiveSticky',
          ),
          isTrue,
        );
      },
    );

    test(
      'restoreImmersiveMode invokes immersiveSticky system UI mode',
      () async {
        final log = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              log.add(call);
              return null;
            });

        const service = TvPlatformService(channel);
        await service.restoreImmersiveMode();

        expect(
          log.any(
            (call) =>
                call.method == 'SystemChrome.setEnabledSystemUIMode' &&
                call.arguments == 'SystemUiMode.immersiveSticky',
          ),
          isTrue,
        );
      },
    );
  });
}
