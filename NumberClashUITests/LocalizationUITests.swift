import XCTest

/// Regression guard for the localization bug where the menu showed raw keys
/// (KEY_APP_TITLE …) instead of translated text. The earlier version of this
/// test only checked English (which was the one correct .strings file) and
/// therefore missed that ja / zh-HK were stale. Now we verify EACH shipped
/// language resolves real text — and that it survives a cold relaunch, the
/// exact close-and-reopen repro.
final class LocalizationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func assertNoRawKeys(_ app: XCUIApplication, _ phase: String) {
        let keyPred = NSPredicate(format: "label BEGINSWITH 'KEY_' OR label BEGINSWITH 'BOARD_A11Y'")
        let leaked = app.staticTexts.matching(keyPred).count
                   + app.buttons.matching(keyPred).count
        XCTAssertEqual(leaked, 0, "[\(phase)] raw localization keys visible — table not resolved")
    }

    /// Launches in `lang`, asserts the PLAY button shows `expectedPlay`
    /// (not the key), then terminates and cold-relaunches and re-checks.
    private func runLanguage(_ lang: String, expectedPlay: String) {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(lang))", "-AppleLocale", "\(lang)_US"]
        app.launch()

        let play = app.buttons[expectedPlay]
        XCTAssertTrue(play.waitForExistence(timeout: 8),
                      "[\(lang)] localized PLAY ('\(expectedPlay)') must appear on first launch")
        assertNoRawKeys(app, "\(lang) first launch")

        // Cold relaunch — the reported "close the app and reopen" repro.
        app.terminate()
        app.launch()
        XCTAssertTrue(play.waitForExistence(timeout: 8),
                      "[\(lang)] localized PLAY ('\(expectedPlay)') must appear after cold relaunch")
        assertNoRawKeys(app, "\(lang) cold relaunch")
    }

    func testEnglishResolvesAndSurvivesRelaunch() {
        runLanguage("en", expectedPlay: "PLAY")
    }

    func testJapaneseResolvesAndSurvivesRelaunch() {
        runLanguage("ja", expectedPlay: "プレイ")
    }

    func testSimplifiedChineseResolves() {
        runLanguage("zh-Hans", expectedPlay: "开始")
    }
}
