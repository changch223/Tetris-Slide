import XCTest
@testable import NumberClash

final class SlideEngineTests: XCTestCase {
    /// Builds a board where each tuple is (row, col, kind, groupID).
    private func boardWith(_ filled: [(Int, Int, PieceKind, Int)]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for (r, c, k, g) in filled { cells[r][c] = .filled(kind: k, groupID: g) }
        return Board(cells: cells)
    }

    func testEmptyBoardIsNoOpForAllDirections() {
        let b = Board()
        for d in SlideDirection.allCases {
            XCTAssertEqual(SlideEngine.slid(b, toward: d), b)
        }
    }

    func testRigidPieceKeepsItsShapeWhenSlidingRight() {
        // T piece occupying (0,0), (1,0), (1,1), (1,2) — all groupID 0.
        let b = boardWith([
            (0, 0, .T, 0),
            (1, 0, .T, 0), (1, 1, .T, 0), (1, 2, .T, 0)
        ])
        let r = SlideEngine.slid(b, toward: .right)

        // After slide right the T should be flush against the right wall:
        // (0, 7), (1, 7), (1, 8), (1, 9)
        XCTAssertEqual(r.cell(at: GridPosition(row: 0, col: 7)).kind, .T)
        XCTAssertEqual(r.cell(at: GridPosition(row: 1, col: 7)).kind, .T)
        XCTAssertEqual(r.cell(at: GridPosition(row: 1, col: 8)).kind, .T)
        XCTAssertEqual(r.cell(at: GridPosition(row: 1, col: 9)).kind, .T)

        // Original T position should now be empty.
        XCTAssertTrue(r.isEmpty(at: GridPosition(row: 0, col: 0)))
    }

    func testTwoPiecesStackAgainstWallWithoutMerging() {
        // Two horizontal I-pieces in same row, separate groupIDs.
        let b = boardWith([
            (0, 0, .I, 1), (0, 1, .I, 1), (0, 2, .I, 1), (0, 3, .I, 1),
            (0, 5, .I, 2), (0, 6, .I, 2), (0, 7, .I, 2), (0, 8, .I, 2)
        ])
        let r = SlideEngine.slid(b, toward: .right)

        // Group 2 hits right wall: (0, 6..9), Group 1 stops adjacent: (0, 2..5)
        XCTAssertEqual(r.cell(at: GridPosition(row: 0, col: 6)).groupID, 2)
        XCTAssertEqual(r.cell(at: GridPosition(row: 0, col: 9)).groupID, 2)
        XCTAssertEqual(r.cell(at: GridPosition(row: 0, col: 5)).groupID, 1)
        XCTAssertEqual(r.cell(at: GridPosition(row: 0, col: 2)).groupID, 1)
        XCTAssertTrue(r.isEmpty(at: GridPosition(row: 0, col: 1)))
    }

    func testSlideDownStacksPieces() {
        let b = boardWith([
            (0, 4, .O, 1), (0, 5, .O, 1), (1, 4, .O, 1), (1, 5, .O, 1)
        ])
        let r = SlideEngine.slid(b, toward: .down)
        XCTAssertEqual(r.cell(at: GridPosition(row: 8, col: 4)).groupID, 1)
        XCTAssertEqual(r.cell(at: GridPosition(row: 9, col: 5)).groupID, 1)
        XCTAssertTrue(r.isEmpty(at: GridPosition(row: 0, col: 4)))
    }

    func testSlideIsIdempotentInSameDirection() {
        let b = boardWith([
            (0, 0, .I, 1), (0, 1, .I, 1), (0, 2, .I, 1), (0, 3, .I, 1)
        ])
        let once = SlideEngine.slid(b, toward: .right)
        let twice = SlideEngine.slid(once, toward: .right)
        XCTAssertEqual(once, twice)
    }
}
