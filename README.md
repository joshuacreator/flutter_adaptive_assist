# Flutter Adaptive Assist

A Flutter plugin that provides unified access to platform-specific accessibility settings, enabling developers to create truly adaptive user interfaces that respect system accessibility preferences.

## Features

- 🎨 **Monochrome Mode Detection** - Detect when users have enabled grayscale/color correction
- 🎬 **Reduce Motion Support** - Respond to user preferences for reduced animations
- 📝 **Bold Text Detection** - Identify when users prefer bold text (iOS)
- 🌗 **High Contrast Mode** - Detect high contrast preferences
- 📏 **Text Scale Factor** - Access the system's text size multiplier
- 📡 **Reactive Streams** - Listen to real-time changes in accessibility settings
- 🔒 **Type-Safe** - Full null-safety support
- 🧪 **Testable** - Built with testing in mind

## Platform Support

| Feature | Android | iOS |
|---------|---------|-----|
| Monochrome Mode | ✅ (API 21+) | ✅ (iOS 13.0+) |
| Reduce Motion | ✅ (API 21+) | ✅ (iOS 13.0+) |
| Bold Text | ❌ | ✅ (iOS 13.0+) |
| High Contrast | ✅ (API 21+) | ✅ (iOS 13.0+) |
| Text Scale Factor | ✅ (API 21+) | ✅ (iOS 13.0+) |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_adaptive_assist: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Setup

Initialize the plugin early in your app (e.g., in `main()`):

```dart
import 'package:flutter_adaptive_assist/adaptive_assist.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AdaptiveAssist.ensureInitialized();
  runApp(MyApp());
}
```

### Check Current Settings

```dart
// Check individual settings
final isMonochrome = await AdaptiveAssist.getMonochromeModeEnabled();

if (isMonochrome) {
  // Apply monochrome-friendly color scheme
}

// Or get all settings at once (more efficient)
final config = await AdaptiveAssist.getConfig();

if (config.monochromeModeEnabled) {
  // Apply monochrome-friendly colors
}

if (config.reduceMotionEnabled) {
  // Disable or simplify animations
}

if (config.textScaleFactor > 1.5) {
  // Adjust layout for larger text
}
```

### Listen to Changes

```dart
@override
void initState() {
  super.initState();
  
  // Listen to monochrome mode changes
  AdaptiveAssist.monochromeModeEnabledStream.listen((isEnabled) {
    setState(() {
      _isMonochrome = isEnabled;
    });
  });
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_assist/adaptive_assist.dart';

class AdaptiveHomePage extends StatefulWidget {
  @override
  _AdaptiveHomePageState createState() => _AdaptiveHomePageState();
}

class _AdaptiveHomePageState extends State<AdaptiveHomePage> {
  AdaptiveConfig _config = AdaptiveConfig();

  @override
  void initState() {
    super.initState();
    _loadConfig();
    
    // Listen to changes
    AdaptiveAssist.monochromeModeEnabledStream.listen((enabled) {
      _loadConfig();
    });
  }

  Future<void> _loadConfig() async {
    final config = await AdaptiveAssist.getConfig();
    setState(() {
      _config = config;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adaptive UI Demo'),
      ),
      body: AnimatedContainer(
        duration: _config.reduceMotionEnabled 
            ? Duration.zero 
            : Duration(milliseconds: 300),
        color: _config.monochromeModeEnabled 
            ? Colors.grey[300] 
            : Colors.blue[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Accessibility Status',
                style: TextStyle(
                  fontSize: 20 * _config.textScaleFactor,
                  fontWeight: _config.boldTextEnabled 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
              SizedBox(height: 20),
              _buildStatusCard('Monochrome Mode', _config.monochromeModeEnabled),
              _buildStatusCard('Reduce Motion', _config.reduceMotionEnabled),
              _buildStatusCard('Bold Text', _config.boldTextEnabled),
              _buildStatusCard('High Contrast', _config.highContrastEnabled),
              _buildStatusCard('Text Scale', '${_config.textScaleFactor.toStringAsFixed(2)}x'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String label, dynamic value) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Optional: dispose if you want to clean up
    // AdaptiveAssist.dispose();
    super.dispose();
  }
}
```

## API Reference

### AdaptiveAssist

#### Methods

- `static void ensureInitialized()` - Initialize the plugin (safe to call multiple times)
- `static Future<bool> getMonochromeModeEnabled()` - Check if monochrome mode is enabled
- `static Future<AdaptiveConfig> getConfig()` - Get all accessibility settings at once
- `static void clearCache()` - Force fresh platform queries on next call
- `static void dispose()` - Clean up resources (typically called on app disposal)

#### Streams

- `static Stream<bool> monochromeModeEnabledStream` - Stream of monochrome mode changes

### AdaptiveConfig

A data class containing all accessibility settings:

```dart
class AdaptiveConfig {
  final bool reduceMotionEnabled;
  final bool monochromeModeEnabled;
  final bool boldTextEnabled;
  final bool highContrastEnabled;
  final double textScaleFactor;
}
```

## Testing

The plugin is designed to be testable. Use the provided test channel for unit tests:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_adaptive_assist/adaptive_assist.dart';

void main() {
  setUp(() {
    AdaptiveAssist.reset();
    
    // Set up mock channel
    final testChannel = MethodChannel('flutter_adaptive_assist');
    AdaptiveAssist.testChannel = testChannel;
    
    // Mock responses
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(testChannel, (call) async {
      if (call.method == 'getMonochromeModeEnabled') {
        return true;
      }
      return null;
    });
  });

  test('getMonochromeModeEnabled returns mocked value', () async {
    final result = await AdaptiveAssist.getMonochromeModeEnabled();
    expect(result, true);
  });
}
```

## Platform-Specific Notes

### Android

- **Monochrome Mode**: Checks both Color Correction (Daltonizer) and Color Inversion settings
- **Reduce Motion**: Checks if animation scales are set to very low values (< 0.1)
- **Bold Text**: Not available system-wide on Android (returns `false`)
- **High Contrast**: Available on Android 5.0+ (API 21)
- **Minimum SDK**: API 21 (Android 5.0 Lollipop)

### iOS

- **Monochrome Mode**: Uses `UIAccessibility.isGrayscaleEnabled`
- **Reduce Motion**: Uses `UIAccessibility.isReduceMotionEnabled`
- **Bold Text**: Uses `UIAccessibility.isBoldTextEnabled`
- **High Contrast**: Uses `UIAccessibility.isDarkerSystemColorsEnabled` (iOS 13.0+)
- **Text Scale Factor**: Maps `UIApplication.shared.preferredContentSizeCategory` to numeric values
- **Minimum Version**: iOS 13.0

## Performance Considerations

- The plugin caches values to minimize platform calls
- Cache is automatically updated when settings change
- Use `getConfig()` instead of multiple individual calls when you need several values
- Streams are broadcast streams - safe to have multiple listeners

## Troubleshooting

### Stream not emitting values

Make sure you call `AdaptiveAssist.ensureInitialized()` before subscribing to streams.

### Values not updating on Android

Check that your app has the necessary permissions and that ContentObserver registration succeeded (check logs).

### iOS notifications not working

Ensure you're testing on a real device, as some accessibility features may not work correctly in the simulator.

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Developed with ❤️ for the Flutter community.
