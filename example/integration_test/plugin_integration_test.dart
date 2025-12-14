// File Location: example/integration_test/plugin_integration_test.dart
// Run with: cd example && flutter test integration_test/plugin_integration_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_assist/flutter_adaptive_assist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AdaptiveAssist Plugin Integration Tests', () {
    setUpAll(() {
      // Initialize plugin once for all tests
      AdaptiveAssist.ensureInitialized();
    });

    testWidgets('Plugin initializes without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Integration Test')),
        ),
      ));

      expect(find.text('Integration Test'), findsOneWidget);
    });

    testWidgets('getMonochromeModeEnabled returns boolean', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));

      final result = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result, isA<bool>());
    });

    testWidgets('getConfig returns valid configuration', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));

      final config = await AdaptiveAssist.getConfig();

      expect(config, isA<AdaptiveConfig>());
      expect(config.monochromeModeEnabled, isA<bool>());
      expect(config.reduceMotionEnabled, isA<bool>());
      expect(config.boldTextEnabled, isA<bool>());
      expect(config.highContrastEnabled, isA<bool>());
      expect(config.textScaleFactor, isA<double>());
      
      // Text scale should be in reasonable range
      expect(config.textScaleFactor, greaterThanOrEqualTo(0.5));
      expect(config.textScaleFactor, lessThanOrEqualTo(5.0));
    });

    testWidgets('monochromeModeEnabledStream is accessible', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));

      final stream = AdaptiveAssist.monochromeModeEnabledStream;
      expect(stream, isNotNull);
    });

    testWidgets('Multiple queries return consistent results', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));

      final result1 = await AdaptiveAssist.getMonochromeModeEnabled();
      final result2 = await AdaptiveAssist.getMonochromeModeEnabled();
      final result3 = await AdaptiveAssist.getMonochromeModeEnabled();

      expect(result1, equals(result2));
      expect(result2, equals(result3));
    });

    testWidgets('Widget can use accessibility settings', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AccessibilityDemoWidget(),
        ),
      ));

      await tester.pumpAndSettle();

      // Widget should display accessibility status
      expect(find.byType(AccessibilityDemoWidget), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('clearCache forces fresh query', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));

      // First query
      await AdaptiveAssist.getMonochromeModeEnabled();

      // Clear cache
      AdaptiveAssist.clearCache();

      // Second query should work
      final result = await AdaptiveAssist.getMonochromeModeEnabled();
      expect(result, isA<bool>());
    });

    testWidgets('Config contains all expected fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SizedBox()),
      ));

      final config = await AdaptiveAssist.getConfig();
      final map = config.toMap();

      expect(map.containsKey('monochromeModeEnabled'), true);
      expect(map.containsKey('reduceMotionEnabled'), true);
      expect(map.containsKey('boldTextEnabled'), true);
      expect(map.containsKey('highContrastEnabled'), true);
      expect(map.containsKey('textScaleFactor'), true);
    });
  });
}

/// Demo widget that uses AdaptiveAssist
class AccessibilityDemoWidget extends StatefulWidget {
  const AccessibilityDemoWidget({Key? key}) : super(key: key);

  @override
  State<AccessibilityDemoWidget> createState() => _AccessibilityDemoWidgetState();
}

class _AccessibilityDemoWidgetState extends State<AccessibilityDemoWidget> {
  AdaptiveConfig _config = const AdaptiveConfig();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AdaptiveAssist.getConfig();
    if (mounted) {
      setState(() {
        _config = config;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibility Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          _buildSettingRow('Monochrome Mode', _config.monochromeModeEnabled),
          _buildSettingRow('Reduce Motion', _config.reduceMotionEnabled),
          _buildSettingRow('Bold Text', _config.boldTextEnabled),
          _buildSettingRow('High Contrast', _config.highContrastEnabled),
          const SizedBox(height: 10),
          Text(
            'Text Scale: ${_config.textScaleFactor.toStringAsFixed(2)}x',
            style: TextStyle(
              fontSize: 16 * _config.textScaleFactor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
}