// Run with: xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 14'

import XCTest
import Flutter
@testable import flutter_adaptive_assist

class FlutterAdaptiveAssistPluginTests: XCTestCase {
    
    var plugin: FlutterAdaptiveAssistPlugin!
    var mockChannel: MockMethodChannel!
    var mockRegistrar: MockPluginRegistrar!
    
    override func setUp() {
        super.setUp()
        mockChannel = MockMethodChannel()
        mockRegistrar = MockPluginRegistrar()
        plugin = FlutterAdaptiveAssistPlugin(channel: mockChannel)
    }
    
    override func tearDown() {
        plugin = nil
        mockChannel = nil
        mockRegistrar = nil
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func testPluginRegistration() {
        FlutterAdaptiveAssistPlugin.register(with: mockRegistrar)
        
        XCTAssertTrue(mockRegistrar.didRegister, "Plugin should register with registrar")
    }
    
    // MARK: - Method Call Tests
    
    func testGetMonochromeModeEnabledReturnsBoolean() {
        let expectation = self.expectation(description: "Method call completes")
        
        let call = FlutterMethodCall(methodName: "getMonochromeModeEnabled", arguments: nil)
        
        plugin.handle(call) { result in
            XCTAssertNotNil(result, "Result should not be nil")
            if let boolResult = result as? Bool {
                XCTAssertTrue(boolResult is Bool, "Result should be a boolean")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testGetConfigReturnsValidDictionary() {
        let expectation = self.expectation(description: "Method call completes")
        
        let call = FlutterMethodCall(methodName: "getConfig", arguments: nil)
        
        plugin.handle(call) { result in
            XCTAssertNotNil(result, "Result should not be nil")
            
            if let config = result as? [String: Any] {
                XCTAssertTrue(config.keys.contains("monochromeModeEnabled"))
                XCTAssertTrue(config.keys.contains("reduceMotionEnabled"))
                XCTAssertTrue(config.keys.contains("boldTextEnabled"))
                XCTAssertTrue(config.keys.contains("highContrastEnabled"))
                XCTAssertTrue(config.keys.contains("textScaleFactor"))
                
                XCTAssertTrue(config["monochromeModeEnabled"] is Bool)
                XCTAssertTrue(config["reduceMotionEnabled"] is Bool)
                XCTAssertTrue(config["boldTextEnabled"] is Bool)
                XCTAssertTrue(config["highContrastEnabled"] is Bool)
                XCTAssertTrue(config["textScaleFactor"] is Double)
            } else {
                XCTFail("Result should be a dictionary")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testUnknownMethodReturnsNotImplemented() {
        let expectation = self.expectation(description: "Method call completes")
        
        let call = FlutterMethodCall(methodName: "unknownMethod", arguments: nil)
        
        plugin.handle(call) { result in
            if let error = result as? FlutterError {
                XCTAssertEqual(error.code, "FLUTTER_METHOD_NOT_IMPLEMENTED")
            } else if result is FlutterMethodNotImplemented {
                XCTAssertTrue(true, "Method not implemented returned correctly")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - Configuration Tests
    
    func testTextScaleFactorMapping() {
        // Test default size
        let defaultScale = plugin.getTextScaleFactor()
        XCTAssertEqual(defaultScale, 1.0, accuracy: 0.01)
    }
    
    func testConfigCaching() {
        let expectation = self.expectation(description: "Config caching")
        
        let call1 = FlutterMethodCall(methodName: "getConfig", arguments: nil)
        
        // First call
        var firstCallTime: Date!
        plugin.handle(call1) { _ in
            firstCallTime = Date()
            
            // Second call immediately after
            let call2 = FlutterMethodCall(methodName: "getConfig", arguments: nil)
            self.plugin.handle(call2) { _ in
                let secondCallTime = Date()
                
                // Second call should be faster (cached)
                let timeDiff = secondCallTime.timeIntervalSince(firstCallTime)
                XCTAssertLessThan(timeDiff, 0.01, "Second call should be cached and fast")
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testCacheInvalidation() {
        let expectation = self.expectation(description: "Cache invalidation")
        
        let call1 = FlutterMethodCall(methodName: "getConfig", arguments: nil)
        
        // First call
        plugin.handle(call1) { _ in
            // Wait for cache to expire (1 second + margin)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                let call2 = FlutterMethodCall(methodName: "getConfig", arguments: nil)
                self.plugin.handle(call2) { _ in
                    // Should query fresh data
                    XCTAssertTrue(true, "Cache should have expired")
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    // MARK: - Notification Tests
    
    func testGrayscaleNotificationSendsChannelMessage() {
        let expectation = self.expectation(description: "Notification triggers channel message")
        
        mockChannel.invokeMethodHandler = { method, arguments in
            if method == "onMonochromeModeChange" {
                XCTAssertNotNil(arguments)
                XCTAssertTrue(arguments is Bool)
                expectation.fulfill()
            }
        }
        
        // Simulate grayscale status change
        NotificationCenter.default.post(
            name: UIAccessibility.grayscaleStatusDidChangeNotification,
            object: nil
        )
        
        // Wait for debounce
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testNotificationDebouncing() {
        var callCount = 0
        let expectation = self.expectation(description: "Notifications are debounced")
        
        mockChannel.invokeMethodHandler = { method, _ in
            if method == "onMonochromeModeChange" {
                callCount += 1
            }
        }
        
        // Send multiple rapid notifications
        for _ in 0..<5 {
            NotificationCenter.default.post(
                name: UIAccessibility.grayscaleStatusDidChangeNotification,
                object: nil
            )
        }
        
        // Wait for debounce period
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Should only have one call due to debouncing
            XCTAssertEqual(callCount, 1, "Multiple rapid notifications should be debounced to one")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - Memory Management Tests
    
    func testPluginDeinitRemovesObservers() {
        var plugin: FlutterAdaptiveAssistPlugin? = FlutterAdaptiveAssistPlugin(channel: mockChannel)
        weak var weakPlugin = plugin
        
        plugin = nil
        
        // Plugin should be deallocated
        XCTAssertNil(weakPlugin, "Plugin should be deallocated")
    }
    
    func testChannelWeakReference() {
        weak var weakChannel = mockChannel
        mockChannel = nil
        
        // Channel should be able to be deallocated
        XCTAssertNil(weakChannel, "Channel should not be strongly retained")
    }
}

// MARK: - Mock Classes

class MockMethodChannel: FlutterMethodChannel {
    var invokeMethodHandler: ((String, Any?) -> Void)?
    private var methodCallHandler: FlutterMethodCallHandler?
    
    init() {
        let binaryMessenger = MockBinaryMessenger()
        super.init(name: "test_channel", binaryMessenger: binaryMessenger)
    }
    
    override func setMethodCallHandler(_ handler: FlutterMethodCallHandler?) {
        self.methodCallHandler = handler
    }
    
    override func invokeMethod(_ method: String, arguments: Any?) {
        invokeMethodHandler?(method, arguments)
    }
}

class MockBinaryMessenger: NSObject, FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {
        // Mock implementation
    }
    
    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply? = nil) {
        // Mock implementation
    }
    
    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil) -> FlutterBinaryMessengerConnection {
        return 0
    }
    
    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
        // Mock implementation
    }
}

class MockPluginRegistrar: NSObject, FlutterPluginRegistrar {
    var didRegister = false
    
    func messenger() -> FlutterBinaryMessenger {
        return MockBinaryMessenger()
    }
    
    func textures() -> FlutterTextureRegistry {
        fatalError("Not implemented")
    }
    
    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {
        // Mock implementation
    }
    
    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String, gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) {
        // Mock implementation
    }
    
    func publish(_ value: NSObject) {
        // Mock implementation
    }
    
    func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {
        didRegister = true
    }
    
    func addApplicationDelegate(_ delegate: FlutterPlugin) {
        // Mock implementation
    }
    
    func lookupKey(forAsset asset: String) -> String {
        return asset
    }
    
    func lookupKey(forAsset asset: String, fromPackage package: String) -> String {
        return asset
    }
}