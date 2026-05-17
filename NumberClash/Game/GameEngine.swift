import Foundation
import Observation

/// State of the just-spawned piece while it is still rotatable. Cleared the
/// moment a valid swipe locks the piece in.
struct CurrentPieceState: Equatable {
    let groupID: Int
    let kind: PieceKind
    var rotation: Rotation
    var origin: GridPosition
}

@Observable
final class GameEngine {
    private(set) var board: Board
    private(set) var score: Int
    private(set) var nextPiece: PieceKind
    private(set) var status: GameStatus

    /// The newly-spawned piece, while it remains rotatable.
    private(set) var currentPiece: CurrentPieceState?

    /// Pre-computed placement of the **upcoming** piece, shown to the player
    /// as a ghost outline so they know where the next piece will appear.
    /// Recomputed at the end of every spawn against the just-updated board.
    /// `nil` only when no placement exists (game over).
    private(set) var plannedNextSpawn: PiecePlacement?

    /// Cells about to fade out for the line-clear animation.
    private(set) var clearingCells: Set<GridPosition> = []

    /// The ghost placement that just got skipped (its spot was destroyed by
    /// the swipe). Drives the red-✕ blink, then is cleared after the blink.
    private(set) var skippedSpawn: PiecePlacement?

    /// Number of turns in a row that ended in a skip. Reset to 0 on any
    /// successful placement. Reaching `maxConsecutiveSkips` ends the game.
    private(set) var consecutiveSkips: Int = 0
    static let maxConsecutiveSkips = 5

    let randomizer: PieceRandomizer
    let highScoreStore: HighScoreStore
    let soundPlayer: SoundPlayer
    let hapticsPlayer: HapticsPlayer

    private var nextGroupID: Int = 0

    static func makeDefault() -> GameEngine {
        GameEngine(
            randomizer: SystemRandomPieceRandomizer(),
            highScoreStore: UserDefaultsHighScoreStore(),
            soundPlayer: AVAudioSoundPlayer(),
            hapticsPlayer: UIFeedbackHapticsPlayer()
        )
    }

    init(randomizer: PieceRandomizer,
         highScoreStore: HighScoreStore,
         soundPlayer: SoundPlayer,
         hapticsPlayer: HapticsPlayer) {
        self.randomizer = randomizer
        self.highScoreStore = highScoreStore
        self.soundPlayer = soundPlayer
        self.hapticsPlayer = hapticsPlayer
        self.board = Board()
        self.score = 0
        self.nextPiece = randomizer.next()
        self.status = .idle
    }

    // MARK: - Public API

    func startNewGame() {
        board = Board()
        score = 0
        nextGroupID = 0
        clearingCells = []
        skippedSpawn = nil
        consecutiveSkips = 0
        currentPiece = nil
        plannedNextSpawn = nil
        nextPiece = randomizer.next()
        status = .playing
        spawnNextPiece(playSwipeFeedback: false)
    }

    @MainActor func handleSwipe(_ direction: SlideDirection) {
        guard status == .playing else { return }

        let slid = SlideEngine.slid(board, toward: direction)
        // After the slide settles, same-colour blocks that now touch fuse
        // into one rigid shape and move together from here on.
        let merged = slid.mergingAdjacentSameKind()
        let clearResult = LineClearer.clearFullLines(merged)
        let didClear = clearResult.totalLineCount > 0

        // A swipe that moves nothing is still a valid turn: it lets the
        // player deliberately leave the board untouched so the ghost's spot
        // survives and the piece is placed exactly where it was shown.

        currentPiece = nil

        if didClear {
            board = merged
            clearingCells = clearResult.clearedCells
            score += ScoreCalculator.lineClearPoints(for: clearResult.totalLineCount)

            if clearResult.totalLineCount >= 4 {
                soundPlayer.play(.tetris)
                hapticsPlayer.play(.tetrisStrong)
            } else {
                soundPlayer.play(.lineClear)
                hapticsPlayer.play(.lineClearMedium)
            }

            let (split, newNextID) = clearResult.board.splittingDisconnectedGroups(
                nextGroupID: nextGroupID
            )
            nextGroupID = newNextID

            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 250_000_000)
                self?.commitClearAndSpawn(clearedBoard: split,
                                           soundOnSpawn: false)
            }
        } else {
            board = merged
            relocateGhostIfNeededThenSpawn(soundOnSpawn: true)
        }
    }

    func rotateCurrentPiece() {
        guard status == .playing, var current = currentPiece else { return }

        let nextRot: Rotation
        switch current.rotation {
        case .deg0:   nextRot = .deg90
        case .deg90:  nextRot = .deg180
        case .deg180: nextRot = .deg270
        case .deg270: nextRot = .deg0
        }

        let withoutPiece = board.removingGroup(current.groupID)
        guard let resolved = PieceRotation.resolve(
            on: withoutPiece, kind: current.kind, to: nextRot,
            origin: current.origin, removingGroup: nil
        ) else {
            return
        }
        board = withoutPiece.placed(current.kind.shape(for: resolved.rotation),
                                    kind: current.kind,
                                    at: resolved.origin, groupID: current.groupID)
        current.rotation = resolved.rotation
        current.origin = resolved.origin
        currentPiece = current

        // Rotation may have freed cells the planned spawn was using, OR
        // started overlapping with it. Re-validate; recompute if invalid.
        if let planned = plannedNextSpawn, !board.placementIsValid(planned) {
            plannedNextSpawn = board.adversarialSpawnPlacement(for: nextPiece)
        }

        soundPlayer.play(.swipe)
        hapticsPlayer.play(.swipeLight)
    }

    func togglePause() {
        switch status {
        case .playing: status = .paused
        case .paused: status = .playing
        default: break
        }
    }

    func resumeFromBackground() {
        if case .paused = status { status = .playing }
    }

    // MARK: - Private helpers

    @MainActor
    private func commitClearAndSpawn(clearedBoard: Board, soundOnSpawn: Bool) {
        board = clearedBoard
        clearingCells = []
        relocateGhostIfNeededThenSpawn(soundOnSpawn: soundOnSpawn)
    }

    /// The ghost the player saw is authoritative: the piece is placed exactly
    /// where the ghost was shown. If the swipe destroyed that spot, the turn
    /// is **skipped** — the piece is discarded, the **next** random piece
    /// starts a fresh turn (new adversarial ghost on the current board), and
    /// a red-✕ blink marks where the skipped piece would have gone. Five
    /// skips in a row, or the new piece fitting nowhere, ends the game.
    @MainActor
    private func relocateGhostIfNeededThenSpawn(soundOnSpawn: Bool) {
        if let planned = plannedNextSpawn, !board.placementIsValid(planned) {
            consecutiveSkips += 1
            skippedSpawn = planned
            currentPiece = nil
            hapticsPlayer.play(.gameOverError)

            if consecutiveSkips >= Self.maxConsecutiveSkips {
                finalizeGameOver()
                return
            }

            // Discard the skipped piece, draw the next one as a brand-new
            // block, and place it now so the new turn starts with a visible
            // block (game over inside spawn if it fits nowhere). The skip
            // streak and the red-✕ blink are preserved (resetSkips: false).
            nextPiece = randomizer.next()
            plannedNextSpawn = board.adversarialSpawnPlacement(for: nextPiece)
            spawnNextPiece(playSwipeFeedback: soundOnSpawn, resetSkips: false)

            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 700_000_000)
                self?.skippedSpawn = nil
            }
            return
        }
        spawnNextPiece(playSwipeFeedback: soundOnSpawn, resetSkips: true)
    }

    private func spawnNextPiece(playSwipeFeedback: Bool = true,
                                resetSkips: Bool = true) {
        // Invariant: by the time we reach this method, `plannedNextSpawn` has
        // already been validated (or relocated) by `relocateGhostIfNeededThenSpawn`,
        // so we can use it directly. The first-spawn-of-the-game path bypasses
        // that helper, so we still fall back to a random placement for safety.
        let placementOpt: PiecePlacement? = plannedNextSpawn
            ?? board.adversarialSpawnPlacement(for: nextPiece)

        guard let placement = placementOpt else {
            finalizeGameOver()
            return
        }

        // A clean placement (the ghost survived the swipe) breaks the skip
        // streak. A skip-placement keeps the streak and its red-✕ blink.
        if resetSkips {
            consecutiveSkips = 0
            skippedSpawn = nil
        }

        let groupID = nextGroupID
        nextGroupID += 1
        board = board.placed(placement, groupID: groupID)
        score += ScoreCalculator.placementBonus

        currentPiece = CurrentPieceState(
            groupID: groupID,
            kind: placement.kind,
            rotation: placement.rotation,
            origin: placement.origin
        )

        // Pick the kind for the *next-next* piece and pre-compute its spawn
        // so the player can see it as a ghost on the current board.
        nextPiece = randomizer.next()
        plannedNextSpawn = board.adversarialSpawnPlacement(for: nextPiece)

        // NOTE: clears are swipe-driven only. If placing this piece itself
        // completes a row/column we deliberately do NOT clear it here — the
        // block must be visible. The full line stays until the player's next
        // swipe, where handleSwipe's slide → LineClearer animates the clear.

        if playSwipeFeedback {
            soundPlayer.play(.swipe)
            hapticsPlayer.play(.swipeLight)
        }

        // Game-over check: if even after this turn the next piece can't fit
        // anywhere, the game is over.
        if plannedNextSpawn == nil {
            finalizeGameOver()
        }
    }

    private func finalizeGameOver() {
        let isNewHigh = highScoreStore.recordIfHigher(score)
        soundPlayer.play(.gameOver)
        hapticsPlayer.play(.gameOverError)
        status = .gameOver(finalScore: score, isNewHighScore: isNewHigh)
    }
}
