import XCTest
@testable import VeepaPOC

class FlutterEngineManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        FlutterEngineManager.shared.destroyEngine()
        super.tearDown()
    }

    func testSharedInstanceExists() {
        XCTAssertNotNil(FlutterEngineManager.shared)
    }

    func testEngineIsNilBeforeInitialization() {
        // Destroy any existing engine first
        FlutterEngineManager.shared.destroyEngine()
        XCTAssertNil(FlutterEngineManager.shared.engine)
    }

    func testEngineIsNotNilAfterInitialization() {
        FlutterEngineManager.shared.initializeEngine()
        XCTAssertNotNil(FlutterEngineManager.shared.engine)
    }

    func testGetViewControllerReturnsNilBeforeInit() {
        FlutterEngineManager.shared.destroyEngine()
        XCTAssertNil(FlutterEngineManager.shared.getViewController())
    }

    func testGetViewControllerReturnsViewControllerAfterInit() {
        FlutterEngineManager.shared.initializeEngine()
        XCTAssertNotNil(FlutterEngineManager.shared.getViewController())
    }

    func testDestroyEngineRemovesEngine() {
        FlutterEngineManager.shared.initializeEngine()
        XCTAssertNotNil(FlutterEngineManager.shared.engine)

        FlutterEngineManager.shared.destroyEngine()
        XCTAssertNil(FlutterEngineManager.shared.engine)
    }

    func testMultipleInitializationsOnlyCreateOneEngine() {
        FlutterEngineManager.shared.initializeEngine()
        let firstEngine = FlutterEngineManager.shared.engine

        FlutterEngineManager.shared.initializeEngine()
        let secondEngine = FlutterEngineManager.shared.engine

        XCTAssertTrue(firstEngine === secondEngine)
    }
}
