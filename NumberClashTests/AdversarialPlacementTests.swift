import XCTest
@testable import NumberClash

final class AdversarialPlacementTests: XCTestCase {
    private func board(filling filled: [GridPosition], groupID: Int = 0) -> Board {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for p in filled { cells[p.row][p.col] = .filled(kind: .I, groupID: groupID) }
        return Board(cells: cells)
    }

    // MARK: - badnessMetrics

    func testEmptyBoardHasZeroBadness() {
        let m = Board().badnessMetrics()
        XCTAssertEqual(m, Board.BadnessMetrics(holes: 0, aggregateHeight: 0,
                                               bumpiness: 0, maxHeight: 0))
    }

    func testSingleBottomCellMetrics() {
        let m = board(filling: [GridPosition(row: 9, col: 0)]).badnessMetrics()
        XCTAssertEqual(m.holes, 0)
        XCTAssertEqual(m.maxHeight, 1)
        XCTAssertEqual(m.aggregateHeight, 1)
        XCTAssertEqual(m.bumpiness, 1) // |1 - 0| between col0 and col1
    }

    func testCoveredHolesAreCounted() {
        // Top of column 0 filled, the nine cells under it are holes.
        let m = board(filling: [GridPosition(row: 0, col: 0)]).badnessMetrics()
        XCTAssertEqual(m.holes, 9)
        XCTAssertEqual(m.maxHeight, 10)
    }

    // MARK: - adversarialSpawnPlacement

    func testFullBoardYieldsNilSpawn() {
        let full = board(filling: (0..<Board.height).flatMap { r in
            (0..<Board.width).map { GridPosition(row: r, col: $0) }
        })
        for kind in PieceKind.allCases {
            XCTAssertNil(full.adversarialSpawnPlacement(for: kind),
                         "\(kind): full board must report game over (nil)")
        }
    }

    func testChosenPlacementIsAlwaysAValidCandidate() {
        let b = board(filling: (0..<5).map { GridPosition(row: 9, col: $0) })
        for kind in PieceKind.allCases {
            guard let chosen = b.adversarialSpawnPlacement(for: kind) else {
                XCTFail("\(kind): expected a placement on a mostly-empty board")
                continue
            }
            XCTAssertTrue(b.placementCandidates(for: kind).contains(chosen))
            let shape = chosen.kind.shape(for: chosen.rotation)
            XCTAssertTrue(b.canPlace(shape, at: chosen.origin))
        }
    }

    /// Row 9 is filled in columns 0…8. Any I placement that drops a cell into
    /// (9,9) completes the row — a gift for the player. The adversary must
    /// refuse every such placement.
    func testAdversaryDeniesAnAvailableLineClear() {
        let b = board(filling: (0..<9).map { GridPosition(row: 9, col: $0) })

        // Sanity: a clear-enabling candidate genuinely exists.
        let enablesClear = b.placementCandidates(for: .I).contains { cand in
            b.cells(of: cand).contains(GridPosition(row: 9, col: 9))
        }
        XCTAssertTrue(enablesClear, "test setup should offer a clearing placement")

        guard let chosen = b.adversarialSpawnPlacement(for: .I) else {
            return XCTFail("expected a placement")
        }
        XCTAssertFalse(
            b.cells(of: chosen).contains(GridPosition(row: 9, col: 9)),
            "adversary must not hand the player a row-completing placement"
        )
    }
}
