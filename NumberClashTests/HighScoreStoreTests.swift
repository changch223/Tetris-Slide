import XCTest
@testable import NumberClash

final class HighScoreStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        super.setUp()
        suite = "test-\(UUID())"
        defaults = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        suite = nil
        super.tearDown()
    }

    func testInitialHighScoreIsZero() {
        let store = UserDefaultsHighScoreStore(defaults: defaults)
        XCTAssertEqual(store.current(), 0)
    }

    func testRecordIfHigherUpdatesAndReturnsTrue() {
        let store = UserDefaultsHighScoreStore(defaults: defaults)
        XCTAssertTrue(store.recordIfHigher(100))
        XCTAssertEqual(store.current(), 100)
    }

    func testRecordIfHigherIgnoresLowerScore() {
        let store = UserDefaultsHighScoreStore(defaults: defaults)
        store.recordIfHigher(500)
        XCTAssertFalse(store.recordIfHigher(200))
        XCTAssertEqual(store.current(), 500)
    }

    func testRecordIfHigherIgnoresEqualScore() {
        let store = UserDefaultsHighScoreStore(defaults: defaults)
        store.recordIfHigher(300)
        XCTAssertFalse(store.recordIfHigher(300))
        XCTAssertEqual(store.current(), 300)
    }

    func testValuePersistsAcrossInstances() {
        let s1 = UserDefaultsHighScoreStore(defaults: defaults)
        s1.recordIfHigher(777)
        let s2 = UserDefaultsHighScoreStore(defaults: defaults)
        XCTAssertEqual(s2.current(), 777)
    }
}
