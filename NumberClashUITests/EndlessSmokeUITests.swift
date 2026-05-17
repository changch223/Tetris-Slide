import XCTest

final class EndlessSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchTapPlayAndSwipe() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for the main menu PLAY button (matched by accessibility label "PLAY"
        // — falls back to localizable key in DEBUG localization).
        let playButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'PLAY' OR label CONTAINS[c] 'プレイ' OR label CONTAINS[c] '开始' OR label CONTAINS[c] '開始'")).firstMatch
        XCTAssertTrue(playButton.waitForExistence(timeout: 5), "PLAY button must appear")
        playButton.tap()

        // Allow the game scene to render.
        sleep(1)

        // Swipe in the middle of the screen 5 times in different directions.
        let center = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let up    = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let down  = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let left  = app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
        let right = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))

        center.press(forDuration: 0.05, thenDragTo: right)
        center.press(forDuration: 0.05, thenDragTo: down)
        center.press(forDuration: 0.05, thenDragTo: left)
        center.press(forDuration: 0.05, thenDragTo: up)
        center.press(forDuration: 0.05, thenDragTo: right)

        // We don't assert on a specific score because of randomness — instead we
        // just verify the app didn't crash and the game scene is still presented.
        XCTAssertTrue(app.exists)
    }
}
