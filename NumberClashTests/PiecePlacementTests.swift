import XCTest
@testable import NumberClash

final class PiecePlacementTests: XCTestCase {
    func testEmptyBoardHasManyCandidatesForEachPiece() {
        let b = Board()
        for k in PieceKind.allCases {
            let candidates = b.placementCandidates(for: k)
            XCTAssertGreaterThan(candidates.count, 10,
                                 "\(k) should have many candidate placements on empty board")
        }
    }

    func testFullBoardHasZeroCandidates() {
        var cells = Array(repeating: Array(repeating: Cell.empty, count: Board.width),
                          count: Board.height)
        for r in 0..<Board.height {
            for c in 0..<Board.width { cells[r][c] = .filled(kind: .I, groupID: 0) }
        }
        let b = Board(cells: cells)
        for k in PieceKind.allCases {
            XCTAssertEqual(b.placementCandidates(for: k).count, 0)
        }
    }

    /// Block Slide uses non-tetromino polyominoes: 3 cells (I, O) or 5
    /// cells (T, S, Z, J, L). 4-cell shapes are deliberately avoided.
    func testEachShapeHasExpectedCellCount() {
        let expected: [PieceKind: Int] = [
            .I: 3, .O: 3,
            .T: 5, .S: 5, .Z: 5, .J: 5, .L: 5,
        ]
        for k in PieceKind.allCases {
            for r in Rotation.allCases {
                XCTAssertEqual(k.shape(for: r).cells.count, expected[k]!,
                               "\(k) at \(r) should have \(expected[k]!) cells")
                XCTAssertNotEqual(k.shape(for: r).cells.count, 4,
                                  "no kind may have 4 cells (tetromino-free design)")
            }
        }
    }

    /// I is the 3-cell bar — horizontal and vertical only.
    func testIPieceHasTwoUniqueRotations() {
        XCTAssertEqual(PieceKind.I.uniqueShapes().count, 2)
    }

    /// O is the 3-cell corner — all four rotations are distinct.
    func testOPieceHasFourUniqueRotations() {
        XCTAssertEqual(PieceKind.O.uniqueShapes().count, 4)
    }

    /// T pentomino: T pointing in each of the 4 directions → 4 unique.
    func testTPieceHasFourUniqueRotations() {
        XCTAssertEqual(PieceKind.T.uniqueShapes().count, 4)
    }

    func testCandidatesAreValidPlacements() {
        let b = Board()
        for k in PieceKind.allCases {
            for cand in b.placementCandidates(for: k).prefix(50) {
                let shape = cand.kind.shape(for: cand.rotation)
                for off in shape.cells {
                    let p = GridPosition(row: cand.origin.row + off.dRow,
                                         col: cand.origin.col + off.dCol)
                    XCTAssertTrue(b.isInBounds(p))
                    XCTAssertTrue(b.isEmpty(at: p))
                }
            }
        }
    }
}
