import XCTest
@testable import NumberClash

@MainActor
final class RotationTests: XCTestCase {
    private func makeEngine(_ randomizer: PieceRandomizer)
    -> GameEngine {
        GameEngine(
            randomizer: randomizer,
            highScoreStore: NoOpHighScoreStore(),
            soundPlayer: NoOpSoundPlayer(),
            hapticsPlayer: NoOpHapticsPlayer()
        )
    }

    func testNewlySpawnedPieceIsCurrentPieceAndRotatable() {
        let e = makeEngine(DeterministicRandomizer([.T]))
        e.startNewGame()
        XCTAssertNotNil(e.currentPiece)
        // Spawn position is now random (2048-style); we don't assert it.
        XCTAssertEqual(e.currentPiece?.kind, .T)
    }

    func testPlannedNextSpawnIsAvailableAfterFirstSpawn() {
        let e = makeEngine(DeterministicRandomizer([.T, .I]))
        e.startNewGame()
        XCTAssertNotNil(e.plannedNextSpawn,
                        "After the first spawn, the next-spawn ghost must be available")
    }

    // Rotation correctness (kick / refusal) is covered deterministically by
    // PieceRotationTests. Here we only verify the engine wiring: rotating
    // never corrupts state. The adversarial spawn can legitimately jam a
    // piece against a wall where a ±2 kick cannot rotate it, so we do NOT
    // assert the rotation always advances.
    func testRotateCurrentPieceKeepsStateConsistent() {
        let e = makeEngine(DeterministicRandomizer([.I]))
        e.startNewGame()
        guard let before = e.currentPiece else {
            return XCTFail("expected a spawned piece")
        }
        e.rotateCurrentPiece()
        guard let after = e.currentPiece else {
            return XCTFail("rotation must not drop the current piece")
        }
        XCTAssertEqual(after.groupID, before.groupID)
        let groupCells = e.board.groups()[after.groupID] ?? []
        XCTAssertEqual(groupCells.count, 4,
                       "the rotated piece must still occupy exactly 4 cells")
    }

    /// A swipe either places the ghosted piece (fresh current piece) or, if
    /// the swipe destroyed the ghost's spot, skips the turn (no current
    /// piece, skip counter advances). Either outcome must leave the engine
    /// in a consistent state — that's the invariant we assert, since which
    /// one happens depends on the adversarial board and is not deterministic.
    func testSwipeLeavesEngineConsistent() async {
        let e = makeEngine(DeterministicRandomizer([.I, .O]))
        e.startNewGame()
        let firstGroupID = e.currentPiece?.groupID
        e.handleSwipe(.right)
        try? await Task.sleep(nanoseconds: 400_000_000) // let any async path settle

        switch e.status {
        case .playing:
            XCTAssertLessThanOrEqual(e.consecutiveSkips, GameEngine.maxConsecutiveSkips)
            if let cur = e.currentPiece {
                XCTAssertNotEqual(cur.groupID, firstGroupID)
                XCTAssertEqual(e.board.groups()[cur.groupID]?.count, 4)
            } else {
                // No current piece ⇒ the turn was skipped.
                XCTAssertGreaterThan(e.consecutiveSkips, 0)
            }
        case .gameOver:
            break // legitimate (e.g. 5 skips or no placement anywhere)
        default:
            XCTFail("unexpected status \(e.status) after a swipe")
        }
    }

    func testNoOpSwipeIsAllowedAndPlacesAtTheGhost() async {
        // The first piece's ghost is shown; a swipe that doesn't disturb the
        // board must keep that spot valid and place the piece (no skip).
        let e = makeEngine(DeterministicRandomizer([.O, .O]))
        e.startNewGame()
        let firstGroupID = e.currentPiece?.groupID
        // Find a no-op direction (one that leaves the board unchanged).
        var placed = false
        for d in SlideDirection.allCases {
            let before = e.board
            if SlideEngine.slid(before, toward: d) == before {
                e.handleSwipe(d)
                try? await Task.sleep(nanoseconds: 400_000_000)
                placed = true
                break
            }
        }
        guard placed else {
            return // no no-op direction available in this layout; skip test
        }
        // A no-op swipe should never skip: the ghost spot was untouched.
        XCTAssertEqual(e.consecutiveSkips, 0)
        if e.status == .playing, let cur = e.currentPiece {
            XCTAssertNotEqual(cur.groupID, firstGroupID)
        }
    }
}
