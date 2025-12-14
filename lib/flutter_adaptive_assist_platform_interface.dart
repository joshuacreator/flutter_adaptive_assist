import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_adaptive_assist_method_channel.dart';

abstract class FlutterAdaptiveAssistPlatform extends PlatformInterface {
  /// Constructs a FlutterAdaptiveAssistPlatform.
  FlutterAdaptiveAssistPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAdaptiveAssistPlatform _instance = MethodChannelFlutterAdaptiveAssist();

  /// The default instance of [FlutterAdaptiveAssistPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAdaptiveAssist].
  static FlutterAdaptiveAssistPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAdaptiveAssistPlatform] when
  /// they register themselves.
  static set instance(FlutterAdaptiveAssistPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
