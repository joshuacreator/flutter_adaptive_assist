import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A class to detect and respond to adaptive accessibility settings.
///
/// This class provides a unified API to access accessibility settings from the
/// underlying platform (Android and iOS).
///
/// ## Platform Support
/// - **Android**: API 21+ (Android 5.0 Lollipop)
/// - **iOS**: iOS 13.0+
///
/// ## Usage
/// ```dart
/// // Initialize once in your app (e.g., in main())
/// AdaptiveAssist.ensureInitialized();
///
/// // Get current status
/// final isMonochrome = await AdaptiveAssist.getMonochromeModeEnabled();
///
/// // Listen to changes
/// AdaptiveAssist.monochromeModeEnabledStream.listen((isEnabled) {
///   print('Monochrome mode: $isEnabled');
/// });
///
/// // Dispose when done (e.g., in app disposal)
/// AdaptiveAssist.dispose();
/// ```
class AdaptiveAssist {
  // Private constructor to prevent instantiation
  AdaptiveAssist._();

  /// Method channel for testing purposes
  @visibleForTesting
  static MethodChannel? testChannel;

  /// The main MethodChannel for platform communication
  static MethodChannel get _channel =>
      testChannel ?? const MethodChannel('flutter_adaptive_assist');

  // StreamController to pipe events from native code to Dart
  static StreamController<bool>? _monochromeStreamController;
  static bool _isInitialized = false;
  static bool? _cachedMonochromeState;

  /// A reactive stream that emits events when the system's monochrome mode
  /// status changes.
  ///
  /// On Android, this includes "Color Correction" and "Color Inversion".
  /// On iOS, this corresponds to the "Grayscale" setting.
  ///
  /// Emits `true` if monochrome mode is enabled, `false` otherwise.
  ///
  /// **Note**: You must call [ensureInitialized] before using this stream.
  ///
  /// ## Example
  /// ```dart
  /// AdaptiveAssist.ensureInitialized();
  /// AdaptiveAssist.monochromeModeEnabledStream.listen((isEnabled) {
  ///   print('Monochrome mode is ${isEnabled ? 'on' : 'off'}');
  /// });
  /// ```
  static Stream<bool> get monochromeModeEnabledStream {
    ensureInitialized();
    return _monochromeStreamController!.stream;
  }

  /// Initializes the AdaptiveAssist plugin.
  ///
  /// This method sets up the method call handler and stream controller.
  /// It's safe to call multiple times - subsequent calls will be ignored.
  ///
  /// It's recommended to call this early in your app lifecycle (e.g., in main()).
  static void ensureInitialized() {
    if (_isInitialized) return;

    _monochromeStreamController = StreamController<bool>.broadcast();
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;

    log('AdaptiveAssist initialized', name: 'AdaptiveAssist');
  }

  /// Handles method calls from the platform side
  static Future<void> _handleMethodCall(MethodCall call) async {
    try {
      if (call.method == 'onMonochromeModeChange') {
        if (call.arguments is! bool) {
          log(
            'Invalid argument type for onMonochromeModeChange: ${call.arguments.runtimeType}',
            name: 'AdaptiveAssist',
            level: 900, // WARNING
          );
          return;
        }

        final bool isEnabled = call.arguments as bool;
        _cachedMonochromeState = isEnabled;
        _monochromeStreamController?.add(isEnabled);
      }
    } catch (e, stackTrace) {
      log(
        'Error handling method call: ${call.method}',
        name: 'AdaptiveAssist',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
    }
  }

  /// Retrieves the current status of the system's monochrome mode.
  ///
  /// Returns a `Future<bool>` that completes with `true` if monochrome mode
  /// is enabled, and `false` otherwise.
  ///
  /// On Android, this checks for "Color Correction" and "Color Inversion".
  /// On iOS, this checks for the "Grayscale" setting.
  ///
  /// This method uses caching to improve performance. The cache is automatically
  /// updated when the system setting changes.
  ///
  /// ## Example
  /// ```dart
  /// Future<void> checkMonochromeStatus() async {
  ///   final isMonochrome = await AdaptiveAssist.getMonochromeModeEnabled();
  ///   print('Monochrome mode is currently ${isMonochrome ? 'on' : 'off'}');
  /// }
  /// ```
  static Future<bool> getMonochromeModeEnabled() async {
    ensureInitialized();

    // Return cached value if available
    if (_cachedMonochromeState != null) {
      return _cachedMonochromeState!;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'getMonochromeModeEnabled',
      );
      final isEnabled = result ?? false;
      _cachedMonochromeState = isEnabled;
      return isEnabled;
    } on PlatformException catch (e) {
      log(
        "Failed to get monochrome status: '${e.code}' - ${e.message}",
        name: 'AdaptiveAssist',
        error: e,
        level: 1000, // ERROR
      );
      return false;
    } catch (e, stackTrace) {
      log(
        'Unexpected error getting monochrome status',
        name: 'AdaptiveAssist',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return false;
    }
  }

  /// Retrieves comprehensive accessibility configuration from the platform.
  ///
  /// Returns an [AdaptiveConfig] object containing all available accessibility
  /// settings. This is more efficient than calling individual getters when you
  /// need multiple values.
  ///
  /// ## Example
  /// ```dart
  /// final config = await AdaptiveAssist.getConfig();
  /// if (config.monochromeModeEnabled) {
  ///   // Apply monochrome-friendly colors
  /// }
  /// if (config.reduceMotionEnabled) {
  ///   // Disable animations
  /// }
  /// ```
  static Future<AdaptiveConfig> getConfig() async {
    ensureInitialized();

    try {
      final result = await _channel.invokeMethod<Map>('getConfig');
      if (result == null) {
        return const AdaptiveConfig();
      }

      return AdaptiveConfig.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      log(
        "Failed to get config: '${e.code}' - ${e.message}",
        name: 'AdaptiveAssist',
        error: e,
        level: 1000,
      );
      return const AdaptiveConfig();
    } catch (e, stackTrace) {
      log(
        'Unexpected error getting config',
        name: 'AdaptiveAssist',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return const AdaptiveConfig();
    }
  }

  /// Clears the internal cache.
  ///
  /// Call this if you want to force a fresh platform query on the next
  /// getter call. This is rarely needed as the cache is automatically
  /// updated when settings change.
  static void clearCache() {
    _cachedMonochromeState = null;
  }

  /// Disposes of resources used by AdaptiveAssist.
  ///
  /// Call this when your app is shutting down or when you no longer need
  /// accessibility monitoring. After calling dispose, you must call
  /// [ensureInitialized] again before using other methods.
  ///
  /// ## Example
  /// ```dart
  /// @override
  /// void dispose() {
  ///   AdaptiveAssist.dispose();
  ///   super.dispose();
  /// }
  /// ```
  static void dispose() {
    if (!_isInitialized) return;

    _monochromeStreamController?.close();
    _monochromeStreamController = null;
    _channel.setMethodCallHandler(null);
    _cachedMonochromeState = null;
    _isInitialized = false;

    log('AdaptiveAssist disposed', name: 'AdaptiveAssist');
  }

  /// Resets the plugin to its initial state.
  ///
  /// This is primarily useful for testing. It disposes current resources
  /// and clears initialization state.
  @visibleForTesting
  static void reset() {
    dispose();
  }
}

/// Configuration object containing accessibility settings from the platform.
///
/// This class represents the current state of various accessibility features
/// available on the device.
@immutable
class AdaptiveConfig {
  /// Whether reduce motion is enabled.
  ///
  /// On iOS: corresponds to UIAccessibility.isReduceMotionEnabled
  /// On Android: checks for animation_duration_scale and transition_animation_scale
  final bool reduceMotionEnabled;

  /// Whether monochrome/grayscale mode is enabled.
  ///
  /// On iOS: corresponds to UIAccessibility.isGrayscaleEnabled
  /// On Android: checks for color correction and color inversion
  final bool monochromeModeEnabled;

  /// Whether bold text is enabled.
  ///
  /// On iOS: corresponds to UIAccessibility.isBoldTextEnabled
  /// On Android: checks for font_weight_adjustment settings
  final bool boldTextEnabled;

  /// Whether high contrast mode is enabled.
  ///
  /// On iOS: corresponds to UIAccessibility.isDarkerSystemColorsEnabled
  /// On Android: checks for high_text_contrast_enabled
  final bool highContrastEnabled;

  /// The current text scale factor.
  ///
  /// Returns a multiplier for text size (1.0 is default).
  /// Values typically range from 0.85 to 3.0.
  final double textScaleFactor;

  const AdaptiveConfig({
    this.reduceMotionEnabled = false,
    this.monochromeModeEnabled = false,
    this.boldTextEnabled = false,
    this.highContrastEnabled = false,
    this.textScaleFactor = 1.0,
  });

  /// Creates an [AdaptiveConfig] from a map received from the platform.
  factory AdaptiveConfig.fromMap(Map<String, dynamic> map) {
    return AdaptiveConfig(
      reduceMotionEnabled: map['reduceMotionEnabled'] as bool? ?? false,
      monochromeModeEnabled: map['monochromeModeEnabled'] as bool? ?? false,
      boldTextEnabled: map['boldTextEnabled'] as bool? ?? false,
      highContrastEnabled: map['highContrastEnabled'] as bool? ?? false,
      textScaleFactor: (map['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Converts this config to a map.
  Map<String, dynamic> toMap() {
    return {
      'reduceMotionEnabled': reduceMotionEnabled,
      'monochromeModeEnabled': monochromeModeEnabled,
      'boldTextEnabled': boldTextEnabled,
      'highContrastEnabled': highContrastEnabled,
      'textScaleFactor': textScaleFactor,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AdaptiveConfig &&
        other.reduceMotionEnabled == reduceMotionEnabled &&
        other.monochromeModeEnabled == monochromeModeEnabled &&
        other.boldTextEnabled == boldTextEnabled &&
        other.highContrastEnabled == highContrastEnabled &&
        other.textScaleFactor == textScaleFactor;
  }

  @override
  int get hashCode {
    return Object.hash(
      reduceMotionEnabled,
      monochromeModeEnabled,
      boldTextEnabled,
      highContrastEnabled,
      textScaleFactor,
    );
  }

  @override
  String toString() {
    return 'AdaptiveConfig('
        'reduceMotionEnabled: $reduceMotionEnabled, '
        'monochromeModeEnabled: $monochromeModeEnabled, '
        'boldTextEnabled: $boldTextEnabled, '
        'highContrastEnabled: $highContrastEnabled, '
        'textScaleFactor: $textScaleFactor)';
  }

  /// Creates a copy of this config with the specified fields replaced.
  AdaptiveConfig copyWith({
    bool? reduceMotionEnabled,
    bool? monochromeModeEnabled,
    bool? boldTextEnabled,
    bool? highContrastEnabled,
    double? textScaleFactor,
  }) {
    return AdaptiveConfig(
      reduceMotionEnabled: reduceMotionEnabled ?? this.reduceMotionEnabled,
      monochromeModeEnabled:
          monochromeModeEnabled ?? this.monochromeModeEnabled,
      boldTextEnabled: boldTextEnabled ?? this.boldTextEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }
}
