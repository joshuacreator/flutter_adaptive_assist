import 'package:flutter/material.dart';
import 'package:flutter_adaptive_assist/flutter_adaptive_assist.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AdaptiveAssist.ensureInitialized();

  runApp(MaterialApp(home: const AdaptiveAssistExample()));
}

class AdaptiveAssistExample extends StatefulWidget {
  const AdaptiveAssistExample({super.key});

  @override
  State<AdaptiveAssistExample> createState() => _AdaptiveAssistExampleState();
}

class _AdaptiveAssistExampleState extends State<AdaptiveAssistExample> {
  bool isMonochromeEnabled = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getMonochromeModeEnabled();

      await AdaptiveAssist.getConfig().then((config) {
        print('Config: ${config.toString()}');
      });

      AdaptiveAssist.monochromeModeEnabledStream.listen((isEnabled) {
        print('Monochrome mode: $isEnabled');
      });
    });
  }

  @override
  void dispose() {
    AdaptiveAssist.dispose();
    super.dispose();
  }

  Future<void> getMonochromeModeEnabled() async {
    final isEnabled = await AdaptiveAssist.getMonochromeModeEnabled();
    setState(() {
      isMonochromeEnabled = isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Assist')),
      body: Center(child: Text('Monochrome Mode: $isMonochromeEnabled...')),
    );
  }
}
