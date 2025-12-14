import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_adaptive_assist/flutter_adaptive_assist.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_adaptive_assist');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getMonochromeModeEnabled') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getMonochromeModeEnabled', () async {
    expect(await AdaptiveAssist.getMonochromeModeEnabled(), true);
  });
}
