import Flutter
import UIKit
import XCTest
@testable import flutter_adaptive_assist

class RunnerTests: XCTestCase {

  func testGetMonochromeModeEnabled() {
    let plugin = FlutterAdaptiveAssistPlugin(channel: FlutterMethodChannel(name: "flutter_adaptive_assist", binaryMessenger: FlutterBinaryMessenger()))

    let expectation = XCTestExpectation(description: "getMonochromeModeEnabled")

    plugin.handle(FlutterMethodCall(methodName: "getMonochromeModeEnabled", arguments: nil)) { (result) in
      if let result = result as? Bool {
        XCTAssertEqual(result, UIAccessibility.isGrayscaleEnabled)
        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

}
