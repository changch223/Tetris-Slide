import XCTest
@testable import NumberClash

final class ScoreCalculatorTests: XCTestCase {
    func testLineClearPointsTable() {
        XCTAssertEqual(ScoreCalculator.lineClearPoints(for: 0), 0)
        XCTAssertEqual(ScoreCalculator.lineClearPoints(for: 1), 100)
        XCTAssertEqual(ScoreCalculator.lineClearPoints(for: 2), 300)
        XCTAssertEqual(ScoreCalculator.lineClearPoints(for: 3), 500)
        XCTAssertEqual(ScoreCalculator.lineClearPoints(for: 4), 800)
    }

    func testPlacementBonusIsOne() {
        XCTAssertEqual(ScoreCalculator.placementBonus, 1)
    }
}
