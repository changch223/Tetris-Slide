import XCTest
@testable import NumberClash

final class LineClearerTests: XCTestCase {
    private func boardWithFilledRows(_ rows: [Int]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for r in rows {
            for c in 0..<Board.width { cells[r][c] = .filled(kind: .I, groupID: 0) }
        }
        return Board(cells: cells)
    }

    private func boardWithFilledColumns(_ cols: [Int]) -> Board {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for c in cols {
            for r in 0..<Board.height { cells[r][c] = .filled(kind: .I, groupID: 0) }
        }
        return Board(cells: cells)
    }

    func testClearsSingleFullRow() {
        let b = boardWithFilledRows([4])
        let r = LineClearer.clearFullLines(b)
        XCTAssertEqual(r.clearedRows, [4])
        XCTAssertEqual(r.clearedColumns, [])
        XCTAssertTrue(r.board.fullRows().isEmpty)
    }

    func testClearsSingleFullColumn() {
        let b = boardWithFilledColumns([3])
        let r = LineClearer.clearFullLines(b)
        XCTAssertEqual(r.clearedColumns, [3])
        XCTAssertEqual(r.clearedRows, [])
        XCTAssertTrue(r.board.fullColumns().isEmpty)
    }

    func testClearsRowAndColumnSimultaneously() {
        // Fill row 5 fully and column 3 fully — they intersect at (5,3).
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for c in 0..<Board.width { cells[5][c] = .filled(kind: .S, groupID: 0) }
        for r in 0..<Board.height { cells[r][3] = .filled(kind: .S, groupID: 0) }
        let b = Board(cells: cells)
        let res = LineClearer.clearFullLines(b)
        XCTAssertEqual(res.clearedRows, [5])
        XCTAssertEqual(res.clearedColumns, [3])
        XCTAssertEqual(res.totalLineCount, 2)
        // Cell (5, 3) only counted once in clearedCells.
        let count = res.clearedCells.count
        XCTAssertEqual(count, Board.width + Board.height - 1)
    }

    func testNoClearWhenNoFullLine() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for c in 0..<Board.width - 1 { cells[3][c] = .filled(kind: .O, groupID: 0) }
        let b = Board(cells: cells)
        let r = LineClearer.clearFullLines(b)
        XCTAssertEqual(r.clearedRows, [])
        XCTAssertEqual(r.clearedColumns, [])
        XCTAssertEqual(r.board, b)
    }

    func testSurvivingCellsKeepGroupID() {
        // T-piece at (0,0)(0,1)(0,2)(1,1) — groupID = 7.
        // Fill row 0 fully with various other groups so row 0 clears.
        // The (1, 1) cell from groupID 7 should survive with groupID 7 intact.
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        cells[0][0] = .filled(kind: .T, groupID: 7)
        cells[0][1] = .filled(kind: .T, groupID: 7)
        cells[0][2] = .filled(kind: .T, groupID: 7)
        cells[1][1] = .filled(kind: .T, groupID: 7)
        // Fill the rest of row 0.
        for c in 3..<Board.width { cells[0][c] = .filled(kind: .I, groupID: 9) }
        let b = Board(cells: cells)
        let r = LineClearer.clearFullLines(b)
        XCTAssertEqual(r.clearedRows, [0])
        XCTAssertEqual(r.board.cell(at: GridPosition(row: 1, col: 1)).groupID, 7)
    }
}
