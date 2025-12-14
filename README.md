# flutter_adaptive_assist

[![pub package](https://img.shields.io/pub/v/flutter_adaptive_assist.svg)](https://pub.dev/packages/flutter_adaptive_assist)

A Flutter plugin to detect and respond to adaptive accessibility settings on iOS and Android, such as monochrome mode, color correction, and grayscale.

## Features

- **Monochrome Mode Detection**: Detects if the system is in a monochrome state, including:
  - **Android**: Color Correction (`accessibility_display_daltonizer_enabled`) and Color Inversion (`accessibility_display_inversion_enabled`).
  - **iOS**: Grayscale (`UIAccessibility.isGrayscaleEnabled`).
- **Reactive Stream**: Provides a `Stream<bool>` that emits events when the monochrome status changes.
- **Cross-Platform**: Unified API for both Android and iOS.

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_adaptive_assist: ^1.0.0
```

Then, install packages from the command line:

```shell
flutter pub get
```

### Usage

Import the package:

```dart
import 'package:flutter_adaptive_assist/flutter_adaptive_assist.dart';
```

#### Get the current monochrome mode status:

```dart
final bool isMonochrome = await AdaptiveAssist.getMonochromeModeEnabled();
```

#### Listen for changes in monochrome mode:

```dart
final Stream<bool> monochromeModeStream = AdaptiveAssist.monochromeModeEnabledStream;

monochromeModeStream.listen((bool isEnabled) {
  print('Monochrome mode is now ${isEnabled ? 'enabled' : 'disabled'}');
});
```

## API

- `Future<bool> getMonochromeModeEnabled()`: Retrieves the current status of monochrome mode.
- `Stream<bool> get monochromeModeEnabledStream`: A stream that emits `true` when monochrome mode is enabled and `false` when it is disabled.

## Platform Specifics

### Android

The plugin checks for two system settings:

- `accessibility_display_daltonizer_enabled`: For color correction.
- `accessibility_display_inversion_enabled`: For color inversion.

If either of these is enabled, `getMonochromeModeEnabled()` will return `true`.

### iOS

The plugin checks the `UIAccessibility.isGrayscaleEnabled` property. If it's `true`, `getMonochromeModeEnabled()` will return `true`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

