import XCTest
@testable import NumberClash

final class MergeAdjacentTests: XCTestCase {
    private func emptyCells() -> [[Cell]] {
        Array(repeating: Array(repeating: Cell.empty, count: Board.width),
              count: Board.height)
    }

    private func groupID(of b: Board, _ r: Int, _ c: Int) -> Int? {
        if case .filled(_, let id) = b.cells[r][c] { return id }
        return nil
    }

    func testSameKindAdjacentBlocksMergeIntoOneGroup() {
        var cells = emptyCells()
        // Two separate I groups (ids 7 and 3) touching horizontally on row 9.
        cells[9][0] = .filled(kind: .I, groupID: 7)
        cells[9][1] = .filled(kind: .I, groupID: 7)
        cells[9][2] = .filled(kind: .I, groupID: 3)
        cells[9][3] = .filled(kind: .I, groupID: 3)
        let merged = Board(cells: cells).mergingAdjacentSameKind()

        let ids = (0...3).compactMap { groupID(of: merged, 9, $0) }
        XCTAssertEqual(Set(ids).count, 1, "touching same-kind blocks must share one group")
        XCTAssertEqual(ids.first, 3, "merged region reuses the smallest original id")
        // Kinds untouched.
        for c in 0...3 {
            if case .filled(let k, _) = merged.cells[9][c] {
                XCTAssertEqual(k, .I)
            } else { XCTFail("cell should stay filled") }
        }
    }

    func testDifferentKindsDoNotMerge() {
        var cells = emptyCells()
        cells[9][0] = .filled(kind: .I, groupID: 1)
        cells[9][1] = .filled(kind: .O, groupID: 2)
        let merged = Board(cells: cells).mergingAdjacentSameKind()
        XCTAssertEqual(groupID(of: merged, 9, 0), 1)
        XCTAssertEqual(groupID(of: merged, 9, 1), 2)
    }

    func testDiagonalContactDoesNotMerge() {
        var cells = emptyCells()
        cells[8][0] = .filled(kind: .T, groupID: 4)
        cells[9][1] = .filled(kind: .T, groupID: 6) // diagonal only
        let merged = Board(cells: cells).mergingAdjacentSameKind()
        XCTAssertEqual(groupID(of: merged, 8, 0), 4)
        XCTAssertEqual(groupID(of: merged, 9, 1), 6)
    }

    func testChainOfSameKindAllMergeToMinID() {
        var cells = emptyCells()
        cells[9][0] = .filled(kind: .S, groupID: 5)
        cells[9][1] = .filled(kind: .S, groupID: 2)
        cells[9][2] = .filled(kind: .S, groupID: 9)
        let merged = Board(cells: cells).mergingAdjacentSameKind()
        let ids = (0...2).compactMap { groupID(of: merged, 9, $0) }
        XCTAssertEqual(ids, [2, 2, 2])
    }

    func testLonePieceKeepsItsID() {
        var cells = emptyCells()
        cells[0][0] = .filled(kind: .L, groupID: 11)
        let merged = Board(cells: cells).mergingAdjacentSameKind()
        XCTAssertEqual(groupID(of: merged, 0, 0), 11)
    }

    func testMergedRegionSlidesAsOneRigidUnit() {
        var cells = emptyCells()
        // Two J blocks touching on row 5; after merge a right-slide must keep
        // their relative shape (rigid) and move them flush to the wall.
        cells[5][0] = .filled(kind: .J, groupID: 1)
        cells[5][1] = .filled(kind: .J, groupID: 2)
        let merged = Board(cells: cells).mergingAdjacentSameKind()
        let slid = SlideEngine.slid(merged, toward: .right)
        XCTAssertTrue(slid.cells[5][Board.width - 1].isFilled)
        XCTAssertTrue(slid.cells[5][Board.width - 2].isFilled)
        // Still exactly two filled cells, still one group.
        let filled = slid.cells.flatMap { $0 }.filter { $0.isFilled }
        XCTAssertEqual(filled.count, 2)
        XCTAssertEqual(groupID(of: slid, 5, Board.width - 1),
                       groupID(of: slid, 5, Board.width - 2))
    }
}
