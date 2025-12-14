import Flutter
import UIKit

/**
 * FlutterAdaptiveAssistPlugin
 *
 * Provides adaptive accessibility settings to Flutter applications.
 *
 * Supported iOS versions: 13.0+
 */
public class FlutterAdaptiveAssistPlugin: NSObject, FlutterPlugin {
    private weak var channel: FlutterMethodChannel?
    
    // Notification observers
    private var grayscaleObserver: NSObjectProtocol?
    private var reduceMotionObserver: NSObjectProtocol?
    private var boldTextObserver: NSObjectProtocol?
    private var darkerColorsObserver: NSObjectProtocol?
    
    // Cache for accessibility settings
    private var cachedConfig: [String: Any]?
    private var lastCacheTime: Date?
    private let cacheValidityInterval: TimeInterval = 1.0 // 1 second
    
    // Debounce timer for notifications
    private var notificationTimer: Timer?
    private let notificationDebounceInterval: TimeInterval = 0.1 // 100ms
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        
        setupObservers()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_adaptive_assist",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterAdaptiveAssistPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getMonochromeModeEnabled":
            result(UIAccessibility.isGrayscaleEnabled)
            
        case "getConfig":
            result(getFullConfig())
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Setup Observers
    
    private func setupObservers() {
        // Grayscale status observer
        grayscaleObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.grayscaleStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.grayscaleStatusDidChange()
        }
        
        // Reduce motion observer
        reduceMotionObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.accessibilitySettingDidChange()
        }
        
        // Bold text observer
        boldTextObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.accessibilitySettingDidChange()
        }
        
        // Darker system colors (high contrast) observer
        if #available(iOS 13.0, *) {
            darkerColorsObserver = NotificationCenter.default.addObserver(
                forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.accessibilitySettingDidChange()
            }
        }
    }
    
    // MARK: - Cache Management
    
    /**
     * Checks if the cached config is still valid.
     */
    private func isCacheValid() -> Bool {
        guard let lastTime = lastCacheTime else { return false }
        return Date().timeIntervalSince(lastTime) < cacheValidityInterval
    }
    
    /**
     * Invalidates the config cache.
     */
    private func invalidateCache() {
        cachedConfig = nil
        lastCacheTime = nil
    }
    
    // MARK: - Notification Handlers
    
    @objc private func grayscaleStatusDidChange() {
        invalidateCache()
        scheduleNotification()
    }
    
    @objc private func accessibilitySettingDidChange() {
        invalidateCache()
        // Could add specific handlers for other settings if needed
    }
    
    /**
     * Debounces notifications to avoid rapid-fire updates.
     */
    private func scheduleNotification() {
        // Cancel existing timer
        notificationTimer?.invalidate()
        
        // Schedule new notification
        notificationTimer = Timer.scheduledTimer(withTimeInterval: notificationDebounceInterval, repeats: false) { [weak self] _ in
            guard let self = self, let channel = self.channel else { return }
            
            DispatchQueue.main.async {
                let isEnabled = UIAccessibility.isGrayscaleEnabled
                channel.invokeMethod("onMonochromeModeChange", arguments: isEnabled)
            }
        }
    }
    
    // MARK: - Configuration
    
    /**
     * Returns a complete configuration map of all accessibility settings.
     * Uses caching to improve performance.
     */
    private func getFullConfig() -> [String: Any] {
        // Return cached config if valid
        if isCacheValid(), let cached = cachedConfig {
            return cached
        }
        
        let config: [String: Any] = buildConfig()
        
        // Update cache
        cachedConfig = config
        lastCacheTime = Date()
        
        return config
    }
    
    /**
     * Builds the configuration dictionary from current accessibility settings.
     */
    private func buildConfig() -> [String: Any] {
        var config: [String: Any] = [
            "monochromeModeEnabled": UIAccessibility.isGrayscaleEnabled,
            "reduceMotionEnabled": UIAccessibility.isReduceMotionEnabled,
            "boldTextEnabled": UIAccessibility.isBoldTextEnabled,
            "textScaleFactor": getTextScaleFactor()
        ]
        
        // High contrast is available on iOS 13+
        if #available(iOS 13.0, *) {
            config["highContrastEnabled"] = UIAccessibility.isDarkerSystemColorsEnabled
        } else {
            config["highContrastEnabled"] = false
        }
        
        return config
    }
    
    /**
     * Gets the current text scale factor.
     * Uses the content size category to determine the scale.
     * Cached as part of getFullConfig().
     */
    private func getTextScaleFactor() -> Double {
        let contentSize = UIApplication.shared.preferredContentSizeCategory
        
        // Map content size categories to approximate scale factors
        // These values are optimized for quick lookup
        switch contentSize {
        case .extraSmall: return 0.85
        case .small: return 0.90
        case .medium: return 0.95
        case .large: return 1.0 // Default
        case .extraLarge: return 1.15
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.5
        case .accessibilityMedium: return 1.8
        case .accessibilityLarge: return 2.1
        case .accessibilityExtraLarge: return 2.4
        case .accessibilityExtraExtraLarge: return 2.7
        case .accessibilityExtraExtraExtraLarge: return 3.0
        default: return 1.0
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Cancel any pending timers
        notificationTimer?.invalidate()
        notificationTimer = nil
        
        // Remove all observers
        if let observer = grayscaleObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = reduceMotionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = boldTextObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = darkerColorsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Clear cache
        invalidateCache()
        
        channel = nil
    }
}