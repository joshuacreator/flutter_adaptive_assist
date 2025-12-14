import 'package:flutter/material.dart';
import 'package:flutter_adaptive_assist/flutter_adaptive_assist.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AdaptiveAssist.ensureInitialized();

  runApp(MaterialApp(home: AdaptiveHomePage()));
}

class AdaptiveHomePage extends StatefulWidget {
  const AdaptiveHomePage({super.key});

  @override
  State<AdaptiveHomePage> createState() => _AdaptiveHomePageState();
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
      appBar: AppBar(title: Text('Adaptive UI Demo')),
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
              _buildStatusCard(
                'Monochrome Mode',
                _config.monochromeModeEnabled,
              ),
              _buildStatusCard('Reduce Motion', _config.reduceMotionEnabled),
              _buildStatusCard('Bold Text', _config.boldTextEnabled),
              _buildStatusCard('High Contrast', _config.highContrastEnabled),
              _buildStatusCard(
                'Text Scale',
                '${_config.textScaleFactor.toStringAsFixed(2)}x',
              ),
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
