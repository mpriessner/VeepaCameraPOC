import XCTest
@testable import VeepaPOC

final class VeepaPOCTests: XCTestCase {
    func testAppDelegateExists() throws {
        let appDelegate = AppDelegate()
        XCTAssertNotNil(appDelegate)
    }

    func testAppDelegateLaunchReturnsTrue() throws {
        let appDelegate = AppDelegate()
        let result = appDelegate.application(
            UIApplication.shared,
            didFinishLaunchingWithOptions: nil
        )
        XCTAssertTrue(result)
    }
}
