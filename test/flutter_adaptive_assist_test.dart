// Run with: flutter test test/adaptive_assist_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_adaptive_assist/flutter_adaptive_assist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdaptiveAssist - Initialization', () {
    late MethodChannel testChannel;
    late List<MethodCall> methodCallLog;

    setUp(() {
      AdaptiveAssist.reset();
      testChannel = const MethodChannel('flutter_adaptive_assist');
      methodCallLog = [];
      AdaptiveAssist.testChannel = testChannel;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            methodCallLog.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
      AdaptiveAssist.reset();
    });

    test('ensureInitialized can be called multiple times safely', () {
      AdaptiveAssist.ensureInitialized();
      AdaptiveAssist.ensureInitialized();
      AdaptiveAssist.ensureInitialized();

      expect(() => AdaptiveAssist.ensureInitialized(), returnsNormally);
    });

    test('ensureInitialized sets up method call handler', () {
      AdaptiveAssist.ensureInitialized();
      // The stream should be available after initialization
      expect(AdaptiveAssist.monochromeModeEnabledStream, isNotNull);
    });

    test('dispose cleans up resources', () {
      AdaptiveAssist.ensureInitialized();
      AdaptiveAssist.dispose();

      // After dispose, should be able to initialize again
      expect(() => AdaptiveAssist.ensureInitialized(), returnsNormally);
    });

    test('reset clears all state', () {
      AdaptiveAssist.ensureInitialized();
      AdaptiveAssist.reset();

      // Should be able to initialize again after reset
      expect(() => AdaptiveAssist.ensureInitialized(), returnsNormally);
    });
  });

  group('AdaptiveAssist - getMonochromeModeEnabled', () {
    late MethodChannel testChannel;
    late List<MethodCall> methodCallLog;

    setUp(() {
      AdaptiveAssist.reset();
      testChannel = const MethodChannel('flutter_adaptive_assist');
      methodCallLog = [];
      AdaptiveAssist.testChannel = testChannel;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            methodCallLog.add(call);
            if (call.method == 'getMonochromeModeEnabled') {
              return true;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
      AdaptiveAssist.reset();
    });

    test('returns true when platform returns true', () async {
      final result = await AdaptiveAssist.getMonochromeModeEnabled();

      expect(result, true);
      expect(methodCallLog.length, 1);
      expect(methodCallLog[0].method, 'getMonochromeModeEnabled');
    });

    test('returns false when platform returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            if (call.method == 'getMonochromeModeEnabled') {
              return false;
            }
            return null;
          });

      final result = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result, false);
    });

    test('returns false when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            return null;
          });

      final result = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result, false);
    });

    test('uses cache on second call', () async {
      final result1 = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result1, true);
      expect(methodCallLog.length, 1);

      final result2 = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result2, true);
      expect(methodCallLog.length, 1); // Should still be 1 (cached)
    });

    test('clearCache forces fresh platform query', () async {
      await AdaptiveAssist.getMonochromeModeEnabled();
      expect(methodCallLog.length, 1);

      AdaptiveAssist.clearCache();

      await AdaptiveAssist.getMonochromeModeEnabled();
      expect(methodCallLog.length, 2);
    });

    test('handles PlatformException gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            throw PlatformException(code: 'ERROR', message: 'Test error');
          });

      final result = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result, false);
    });

    test('handles generic exceptions gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            throw Exception('Unexpected error');
          });

      final result = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result, false);
    });
  });

  group('AdaptiveAssist - getConfig', () {
    late MethodChannel testChannel;
    late List<MethodCall> methodCallLog;

    setUp(() {
      AdaptiveAssist.reset();
      testChannel = const MethodChannel('flutter_adaptive_assist');
      methodCallLog = [];
      AdaptiveAssist.testChannel = testChannel;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            methodCallLog.add(call);
            if (call.method == 'getConfig') {
              return {
                'monochromeModeEnabled': true,
                'reduceMotionEnabled': false,
                'boldTextEnabled': true,
                'highContrastEnabled': false,
                'textScaleFactor': 1.5,
              };
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
      AdaptiveAssist.reset();
    });

    test('returns full configuration from platform', () async {
      final config = await AdaptiveAssist.getConfig();

      expect(config.monochromeModeEnabled, true);
      expect(config.reduceMotionEnabled, false);
      expect(config.boldTextEnabled, true);
      expect(config.highContrastEnabled, false);
      expect(config.textScaleFactor, 1.5);
      expect(methodCallLog.length, 1);
      expect(methodCallLog[0].method, 'getConfig');
    });

    test('returns default config when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            return null;
          });

      final config = await AdaptiveAssist.getConfig();

      expect(config.monochromeModeEnabled, false);
      expect(config.reduceMotionEnabled, false);
      expect(config.boldTextEnabled, false);
      expect(config.highContrastEnabled, false);
      expect(config.textScaleFactor, 1.0);
    });

    test('handles PlatformException gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            throw PlatformException(code: 'ERROR', message: 'Test error');
          });

      final config = await AdaptiveAssist.getConfig();
      expect(config.monochromeModeEnabled, false);
    });

    test('handles partial config data', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            return {
              'monochromeModeEnabled': true,
              // Missing other fields
            };
          });

      final config = await AdaptiveAssist.getConfig();
      expect(config.monochromeModeEnabled, true);
      expect(config.reduceMotionEnabled, false); // Default value
    });
  });

  group('AdaptiveAssist - Streams', () {
    late MethodChannel testChannel;

    setUp(() {
      AdaptiveAssist.reset();
      testChannel = const MethodChannel('flutter_adaptive_assist');
      AdaptiveAssist.testChannel = testChannel;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
      AdaptiveAssist.reset();
    });

    test('monochromeModeEnabledStream emits values', () async {
      final stream = AdaptiveAssist.monochromeModeEnabledStream;
      final future = stream.first;

      // Simulate platform sending a change notification
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            testChannel.name,
            testChannel.codec.encodeMethodCall(
              const MethodCall('onMonochromeModeChange', true),
            ),
            (_) {},
          );

      final result = await future;
      expect(result, true);
    });

    test('stream emits multiple values', () async {
      final stream = AdaptiveAssist.monochromeModeEnabledStream;
      final values = <bool>[];

      final subscription = stream.listen(values.add);

      // Send multiple notifications
      for (final value in [true, false, true]) {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              testChannel.name,
              testChannel.codec.encodeMethodCall(
                MethodCall('onMonochromeModeChange', value),
              ),
              (_) {},
            );
      }

      await Future.delayed(const Duration(milliseconds: 100));

      expect(values, [true, false, true]);
      await subscription.cancel();
    });

    test('multiple listeners receive the same events', () async {
      final stream = AdaptiveAssist.monochromeModeEnabledStream;
      final values1 = <bool>[];
      final values2 = <bool>[];

      final sub1 = stream.listen(values1.add);
      final sub2 = stream.listen(values2.add);

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            testChannel.name,
            testChannel.codec.encodeMethodCall(
              const MethodCall('onMonochromeModeChange', true),
            ),
            (_) {},
          );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(values1, [true]);
      expect(values2, [true]);

      await sub1.cancel();
      await sub2.cancel();
    });

    test('stream handles invalid argument types gracefully', () async {
      final stream = AdaptiveAssist.monochromeModeEnabledStream;
      final values = <bool>[];

      final subscription = stream.listen(values.add);

      // Send invalid argument type
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            testChannel.name,
            testChannel.codec.encodeMethodCall(
              const MethodCall('onMonochromeModeChange', 'invalid'),
            ),
            (_) {},
          );

      await Future.delayed(const Duration(milliseconds: 100));

      // Should not emit any values
      expect(values, isEmpty);

      await subscription.cancel();
    });
  });

  group('AdaptiveConfig', () {
    test('default constructor creates config with default values', () {
      const config = AdaptiveConfig();

      expect(config.monochromeModeEnabled, false);
      expect(config.reduceMotionEnabled, false);
      expect(config.boldTextEnabled, false);
      expect(config.highContrastEnabled, false);
      expect(config.textScaleFactor, 1.0);
    });

    test('fromMap creates config correctly', () {
      final map = {
        'monochromeModeEnabled': true,
        'reduceMotionEnabled': false,
        'boldTextEnabled': true,
        'highContrastEnabled': false,
        'textScaleFactor': 1.3,
      };

      final config = AdaptiveConfig.fromMap(map);

      expect(config.monochromeModeEnabled, true);
      expect(config.reduceMotionEnabled, false);
      expect(config.boldTextEnabled, true);
      expect(config.highContrastEnabled, false);
      expect(config.textScaleFactor, 1.3);
    });

    test('fromMap handles missing values with defaults', () {
      final map = <String, dynamic>{};
      final config = AdaptiveConfig.fromMap(map);

      expect(config.monochromeModeEnabled, false);
      expect(config.reduceMotionEnabled, false);
      expect(config.boldTextEnabled, false);
      expect(config.highContrastEnabled, false);
      expect(config.textScaleFactor, 1.0);
    });

    test('fromMap handles int textScaleFactor', () {
      final map = {'textScaleFactor': 2}; // int instead of double
      final config = AdaptiveConfig.fromMap(map);

      expect(config.textScaleFactor, 2.0);
    });

    test('toMap converts config correctly', () {
      const config = AdaptiveConfig(
        monochromeModeEnabled: true,
        reduceMotionEnabled: true,
        boldTextEnabled: false,
        highContrastEnabled: true,
        textScaleFactor: 2.0,
      );

      final map = config.toMap();

      expect(map['monochromeModeEnabled'], true);
      expect(map['reduceMotionEnabled'], true);
      expect(map['boldTextEnabled'], false);
      expect(map['highContrastEnabled'], true);
      expect(map['textScaleFactor'], 2.0);
    });

    test('equality works correctly', () {
      const config1 = AdaptiveConfig(
        monochromeModeEnabled: true,
        textScaleFactor: 1.5,
      );

      const config2 = AdaptiveConfig(
        monochromeModeEnabled: true,
        textScaleFactor: 1.5,
      );

      const config3 = AdaptiveConfig(
        monochromeModeEnabled: false,
        textScaleFactor: 1.5,
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
    });

    test('copyWith creates modified copy', () {
      const original = AdaptiveConfig(
        monochromeModeEnabled: true,
        textScaleFactor: 1.0,
      );

      final modified = original.copyWith(
        textScaleFactor: 2.0,
        reduceMotionEnabled: true,
      );

      expect(modified.monochromeModeEnabled, true);
      expect(modified.textScaleFactor, 2.0);
      expect(modified.reduceMotionEnabled, true);
      expect(original.textScaleFactor, 1.0); // Original unchanged
      expect(original.reduceMotionEnabled, false);
    });

    test('copyWith with no changes returns equivalent config', () {
      const original = AdaptiveConfig(monochromeModeEnabled: true);
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('toString returns readable format', () {
      const config = AdaptiveConfig(
        monochromeModeEnabled: true,
        textScaleFactor: 1.5,
      );
      final str = config.toString();

      expect(str, contains('AdaptiveConfig'));
      expect(str, contains('monochromeModeEnabled: true'));
      expect(str, contains('textScaleFactor: 1.5'));
    });
  });

  group('AdaptiveAssist - Edge Cases', () {
    late MethodChannel testChannel;

    setUp(() {
      AdaptiveAssist.reset();
      testChannel = const MethodChannel('flutter_adaptive_assist');
      AdaptiveAssist.testChannel = testChannel;
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
      AdaptiveAssist.reset();
    });

    test('accessing stream before initialization initializes plugin', () {
      // Should not throw
      expect(() => AdaptiveAssist.monochromeModeEnabledStream, returnsNormally);
    });

    test('calling methods before initialization initializes plugin', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall call) async {
            return true;
          });

      // Should not throw
      final result = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result, true);
    });

    test('multiple dispose calls are safe', () {
      AdaptiveAssist.ensureInitialized();
      AdaptiveAssist.dispose();
      AdaptiveAssist.dispose();
      AdaptiveAssist.dispose();

      expect(() => AdaptiveAssist.dispose(), returnsNormally);
    });
  });
}
