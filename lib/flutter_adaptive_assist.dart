import 'dart:async';
import 'package:flutter/services.dart';

/// A class to detect and respond to adaptive accessibility settings.
///
/// This class provides a unified API to access accessibility settings from the
/// underlying platform (Android and iOS).
class AdaptiveAssist {
  // Define the main MethodChannel
  static const MethodChannel _channel = MethodChannel(
    'flutter_adaptive_assist',
  );

  // StreamController to pipe events from native code to Dart
  static final _monochromeStreamController = StreamController<bool>.broadcast();

  /// A reactive stream that emits events when the system's monochrome mode
  /// status changes.
  ///
  /// On Android, this includes "Color Correction" and "Color Inversion".
  /// On iOS, this corresponds to the "Grayscale" setting.
  ///
  /// Emits `true` if monochrome mode is enabled, `false` otherwise.
  ///
  /// ## Example
  /// ```dart
  /// AdaptiveAssist.monochromeModeEnabledStream.listen((isEnabled) {
  ///   print('Monochrome mode is ${isEnabled ? 'on' : 'off'}');
  /// });
  /// ```
  static Stream<bool> get monochromeModeEnabledStream =>
      _monochromeStreamController.stream;

  /// Retrieves the current status of the system's monochrome mode.
  ///
  /// Returns a `Future<bool>` that completes with `true` if monochrome mode
  /// is enabled, and `false` otherwise.
  ///
  /// On Android, this checks for "Color Correction" and "Color Inversion".
  /// On iOS, this checks for the "Grayscale" setting.
  ///
  /// ## Example
  /// ```dart
  /// Future<void> checkMonochromeStatus() async {
  ///   final isMonochrome = await AdaptiveAssist.getMonochromeModeEnabled();
  ///   print('Monochrome mode is currently ${isMonochrome ? 'on' : 'off'}');
  /// }
  /// ```
  static Future<bool> getMonochromeModeEnabled() async {
    try {
      final bool? isEnabled = await _channel.invokeMethod(
        'getMonochromeModeEnabled',
      );
      return isEnabled ?? false;
    } on PlatformException catch (e) {
      // Log error but return default safe value
      print("Failed to get monochrome status: ${e.message}");
      return false;
    }
  }

  // Private method to initialize the event handler
  static void _init() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onMonochromeModeChange') {
        final bool isEnabled = call.arguments as bool;
        _monochromeStreamController.add(isEnabled);
      }
      return null;
    });
  }

  // Call init on package load (e.g., in a static block or a main package function)
  static final bool _initialized = (() {
    _init();
    return true;
  })();
}

// Optional: Define the config object for the final, integrated provider.
class AdaptiveConfig {
  final bool reduceMotionEnabled;
  final bool monochromeModeEnabled;
  // ... other settings

  AdaptiveConfig({
    this.reduceMotionEnabled = false,
    this.monochromeModeEnabled = false,
  });
}
