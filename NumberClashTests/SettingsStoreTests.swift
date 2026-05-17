import XCTest
@testable import NumberClash

final class SettingsStoreTests: XCTestCase {
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

    func testDefaultsAreBothEnabled() {
        let store = UserDefaultsSettingsStore(defaults: defaults)
        let s = store.load()
        XCTAssertTrue(s.soundEnabled)
        XCTAssertTrue(s.hapticsEnabled)
    }

    func testSavingPersistsAcrossInstances() {
        let s1 = UserDefaultsSettingsStore(defaults: defaults)
        s1.save(Settings(soundEnabled: false, hapticsEnabled: true))
        let s2 = UserDefaultsSettingsStore(defaults: defaults)
        let loaded = s2.load()
        XCTAssertFalse(loaded.soundEnabled)
        XCTAssertTrue(loaded.hapticsEnabled)
    }

    func testToggleEachIndependently() {
        let s = UserDefaultsSettingsStore(defaults: defaults)
        s.save(Settings(soundEnabled: true, hapticsEnabled: false))
        XCTAssertEqual(s.load(), Settings(soundEnabled: true, hapticsEnabled: false))
        s.save(Settings(soundEnabled: false, hapticsEnabled: false))
        XCTAssertEqual(s.load(), Settings(soundEnabled: false, hapticsEnabled: false))
    }
}
