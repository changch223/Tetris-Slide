import XCTest
@testable import NumberClash

final class BoardTests: XCTestCase {
    func testEmptyBoardHasAllCellsEmpty() {
        let b = Board()
        XCTAssertEqual(b.emptyCellCount, Board.width * Board.height)
        for r in 0..<Board.height {
            for c in 0..<Board.width {
                XCTAssertTrue(b.isEmpty(at: GridPosition(row: r, col: c)))
            }
        }
    }

    func testPlacingPieceMakesCellsFilled() {
        let b = Board()
            .placed(PieceKind.O.shape(for: .deg0), kind: .O,
                    at: GridPosition(row: 0, col: 0), groupID: 1)
        XCTAssertFalse(b.isEmpty(at: GridPosition(row: 0, col: 0)))
        XCTAssertFalse(b.isEmpty(at: GridPosition(row: 0, col: 1)))
        XCTAssertFalse(b.isEmpty(at: GridPosition(row: 1, col: 0)))
        XCTAssertFalse(b.isEmpty(at: GridPosition(row: 1, col: 1)))
        XCTAssertTrue(b.isEmpty(at: GridPosition(row: 2, col: 2)))
    }

    func testEqualityIsValueBased() {
        let a = Board()
        let b = Board()
        XCTAssertEqual(a, b)
        let c = a.placed(PieceKind.I.shape(for: .deg0), kind: .I,
                         at: GridPosition(row: 5, col: 0), groupID: 0)
        XCTAssertNotEqual(a, c)
    }

    func testFullRowsDetectsCompletedRows() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for c in 0..<Board.width { cells[5][c] = .filled(kind: .O, groupID: 0) }
        let b = Board(cells: cells)
        XCTAssertEqual(b.fullRows(), [5])
    }

    func testFullColumnsDetectsCompletedColumns() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for r in 0..<Board.height { cells[r][3] = .filled(kind: .T, groupID: 0) }
        let b = Board(cells: cells)
        XCTAssertEqual(b.fullColumns(), [3])
    }

    func testClearedRemovesGivenRowsAndColumns() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for c in 0..<Board.width {
            cells[3][c] = .filled(kind: .S, groupID: 0)
            cells[7][c] = .filled(kind: .Z, groupID: 1)
        }
        let b = Board(cells: cells)
        let cleared = b.cleared(rows: [3, 7], columns: [])
        XCTAssertTrue(cleared.fullRows().isEmpty)
        XCTAssertEqual(cleared.emptyCellCount, Board.width * Board.height)
    }

    func testGroupsCollectsCellsByGroupID() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        cells[0][0] = .filled(kind: .I, groupID: 7)
        cells[0][1] = .filled(kind: .I, groupID: 7)
        cells[5][5] = .filled(kind: .O, groupID: 12)
        let b = Board(cells: cells)
        let groups = b.groups()
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[7]?.count, 2)
        XCTAssertEqual(groups[12]?.count, 1)
    }
}
