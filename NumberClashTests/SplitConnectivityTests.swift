import XCTest
@testable import NumberClash

final class SplitConnectivityTests: XCTestCase {
    func testContiguousRemnantKeepsSingleGroupID() {
        // T-piece: (0,0)(0,1)(0,2)(1,1) all groupID 5.
        // Remove (0,0) → remaining (0,1)(0,2)(1,1) is still 4-connected.
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        cells[0][1] = .filled(kind: .T, groupID: 5)
        cells[0][2] = .filled(kind: .T, groupID: 5)
        cells[1][1] = .filled(kind: .T, groupID: 5)
        let b = Board(cells: cells)
        let (out, _) = b.splittingDisconnectedGroups(nextGroupID: 100)
        // All 3 surviving cells share the same group.
        let g1 = out.cell(at: GridPosition(row: 0, col: 1)).groupID
        let g2 = out.cell(at: GridPosition(row: 0, col: 2)).groupID
        let g3 = out.cell(at: GridPosition(row: 1, col: 1)).groupID
        XCTAssertEqual(g1, g2)
        XCTAssertEqual(g1, g3)
    }

    func testDisconnectedRemnantSplitsIntoIndependentGroups() {
        // I-piece horizontal: (0,0)(0,1)(0,2)(0,3) all groupID 7.
        // Remove (0,1)(0,2) → remaining (0,0) and (0,3) are no longer connected.
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        cells[0][0] = .filled(kind: .I, groupID: 7)
        cells[0][3] = .filled(kind: .I, groupID: 7)
        let b = Board(cells: cells)
        let (out, nextID) = b.splittingDisconnectedGroups(nextGroupID: 100)
        let g1 = out.cell(at: GridPosition(row: 0, col: 0)).groupID
        let g2 = out.cell(at: GridPosition(row: 0, col: 3)).groupID
        XCTAssertNotNil(g1)
        XCTAssertNotNil(g2)
        XCTAssertNotEqual(g1, g2, "Disconnected remnants must get different groupIDs")
        XCTAssertGreaterThanOrEqual(nextID, 102, "Two new IDs should have been assigned")
    }

    func testSeparatePiecesTouchingDoNotMergeAfterSplit() {
        // Two distinct groups (groupID 1 and groupID 2) sit adjacent.
        // splittingDisconnectedGroups should NOT merge them — they keep
        // their original IDs because each group is internally connected.
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        cells[5][3] = .filled(kind: .O, groupID: 1)
        cells[5][4] = .filled(kind: .O, groupID: 1)
        cells[5][5] = .filled(kind: .I, groupID: 2)  // adjacent but different group
        cells[5][6] = .filled(kind: .I, groupID: 2)
        let b = Board(cells: cells)
        let (out, _) = b.splittingDisconnectedGroups(nextGroupID: 100)
        XCTAssertEqual(out.cell(at: GridPosition(row: 5, col: 3)).groupID, 1)
        XCTAssertEqual(out.cell(at: GridPosition(row: 5, col: 4)).groupID, 1)
        XCTAssertEqual(out.cell(at: GridPosition(row: 5, col: 5)).groupID, 2)
        XCTAssertEqual(out.cell(at: GridPosition(row: 5, col: 6)).groupID, 2)
    }

    func testRandomSpawnReturnsAValidPlacementOnEmptyBoard() {
        let b = Board()
        for k in PieceKind.allCases {
            let p = b.randomSpawnPlacement(for: k)
            XCTAssertNotNil(p, "\(k) should have a placement on empty board")
            if let p = p {
                XCTAssertTrue(b.placementIsValid(p))
            }
        }
    }

    func testRandomSpawnReturnsNilWhenBoardIsFull() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for r in 0..<Board.height {
            for c in 0..<Board.width { cells[r][c] = .filled(kind: .O, groupID: 99) }
        }
        let b = Board(cells: cells)
        XCTAssertNil(b.randomSpawnPlacement(for: .I))
    }

    func testPlacementIsValidDetectsConflict() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        cells[0][0] = .filled(kind: .O, groupID: 99)
        let b = Board(cells: cells)
        let conflicting = PiecePlacement(
            kind: .I, rotation: .deg0,
            origin: GridPosition(row: 0, col: 0)  // I-piece would occupy (0,0)
        )
        XCTAssertFalse(b.placementIsValid(conflicting))
    }

    func testCellsOfPlacementReturnsCorrectPositions() {
        let b = Board()
        let placement = PiecePlacement(
            kind: .O, rotation: .deg0,
            origin: GridPosition(row: 2, col: 3)
        )
        let cells = b.cells(of: placement)
        XCTAssertEqual(cells, Set([
            GridPosition(row: 2, col: 3),
            GridPosition(row: 2, col: 4),
            GridPosition(row: 3, col: 3),
            GridPosition(row: 3, col: 4),
        ]))
    }
}
