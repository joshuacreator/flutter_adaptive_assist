import Flutter
import UIKit

public class FlutterAdaptiveAssistPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(grayscaleStatusDidChange),
            name: UIAccessibility.grayscaleStatusDidChangeNotification,
            object: nil
        )
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_adaptive_assist", binaryMessenger: registrar.messenger())
        let instance = FlutterAdaptiveAssistPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getMonochromeModeEnabled" {
            result(UIAccessibility.isGrayscaleEnabled)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    @objc private func grayscaleStatusDidChange() {
        channel.invokeMethod("onMonochromeModeChange", arguments: UIAccessibility.isGrayscaleEnabled)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
