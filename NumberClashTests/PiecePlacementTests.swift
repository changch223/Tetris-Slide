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

    func testEachShapeHasFourCells() {
        for k in PieceKind.allCases {
            for r in Rotation.allCases {
                XCTAssertEqual(k.shape(for: r).cells.count, 4,
                               "\(k) at \(r) should have 4 cells")
            }
        }
    }

    func testOPieceHasOneUniqueRotation() {
        XCTAssertEqual(PieceKind.O.uniqueShapes().count, 1)
    }

    func testIPieceHasTwoUniqueRotations() {
        XCTAssertEqual(PieceKind.I.uniqueShapes().count, 2)
    }

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
