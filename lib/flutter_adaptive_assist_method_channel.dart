import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_adaptive_assist_platform_interface.dart';

/// An implementation of [FlutterAdaptiveAssistPlatform] that uses method channels.
class MethodChannelFlutterAdaptiveAssist extends FlutterAdaptiveAssistPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_adaptive_assist');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
