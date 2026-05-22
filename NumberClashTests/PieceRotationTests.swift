import XCTest
@testable import NumberClash

final class PieceRotationTests: XCTestCase {
    private func filledBoard(_ filled: Set<GridPosition>) -> Board {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for p in filled { cells[p.row][p.col] = .filled(kind: .I, groupID: 99) }
        return Board(cells: cells)
    }

    /// The pre-kick code refused this rotation: I (3-cell bar) at origin
    /// (0,0) would occupy cols 0..2; if cols 0..2 are blocked at row 0 the
    /// bar can't fit there and must kick to the next free row.
    func testRotationKicksAroundAnObstacle() {
        let board = filledBoard([
            GridPosition(row: 0, col: 1) // blocks the middle cell of the horiz bar
        ])
        let resolved = PieceRotation.resolve(
            on: board, kind: .I, to: .deg0,
            origin: GridPosition(row: 0, col: 0), removingGroup: nil
        )
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.rotation, .deg0)
        // (0,0) blocked by middle cell; kick walks to first free origin (1,0).
        XCTAssertEqual(resolved?.origin, GridPosition(row: 1, col: 0))
    }

    func testRotationAtCenterNeedsNoKick() {
        let board = Board()
        let origin = GridPosition(row: 4, col: 4)
        let resolved = PieceRotation.resolve(
            on: board, kind: .T, to: .deg90,
            origin: origin, removingGroup: nil
        )
        XCTAssertEqual(resolved?.origin, origin)
        XCTAssertEqual(resolved?.rotation, .deg90)
    }

    func testRotationRefusedWhenNothingFitsNearby() {
        var cells = Array(repeating: Array(repeating: Cell.filled(kind: .I, groupID: 0),
                                           count: Board.width),
                          count: Board.height)
        // Leave only a single empty cell — no 4-cell shape can ever fit.
        cells[5][5] = .empty
        let board = Board(cells: cells)
        let resolved = PieceRotation.resolve(
            on: board, kind: .I, to: .deg90,
            origin: GridPosition(row: 5, col: 5), removingGroup: nil
        )
        XCTAssertNil(resolved)
    }

    /// A vertical I jammed against the right wall needs a 3-cell shift to
    /// become horizontal — out of the ±2 kick range. The I-only whole-board
    /// fallback must still find a valid origin so it always rotates.
    func testStraightIPieceRotatesEvenJammedAgainstWall() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for r in 0..<4 { cells[r][Board.width - 1] = .filled(kind: .I, groupID: 7) }
        let board = Board(cells: cells)
        let resolved = PieceRotation.resolve(
            on: board, kind: .I, to: .deg0,
            origin: GridPosition(row: 0, col: Board.width - 1),
            removingGroup: 7
        )
        XCTAssertNotNil(resolved, "the straight piece must always rotate when room exists")
        XCTAssertEqual(resolved?.rotation, .deg0)
        if let resolved {
            XCTAssertTrue(board.removingGroup(7)
                .canPlace(PieceKind.I.shape(for: .deg0), at: resolved.origin))
        }
    }

    func testRemovingGroupLiftsThePieceBeforeTesting() {
        // A vertical I occupying col 0 rows 0-3 as group 7; rotating it to
        // horizontal must succeed because the resolver lifts group 7 first.
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for r in 0..<4 { cells[r][0] = .filled(kind: .I, groupID: 7) }
        let board = Board(cells: cells)
        let resolved = PieceRotation.resolve(
            on: board, kind: .I, to: .deg0,
            origin: GridPosition(row: 0, col: 0), removingGroup: 7
        )
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.origin, GridPosition(row: 0, col: 0))
    }
}
