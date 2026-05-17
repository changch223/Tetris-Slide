import Foundation

/// Weights for the player-favorability score the adversary minimises.
/// `clear` dominates so the AI's first priority is denying line clears;
/// the geometric terms then push toward the messiest reachable board.
/// Tune from playtest feedback (quickstart §4 smoke pass).
enum AdversarialWeights {
    static let clear     = 1000
    static let holes     = 8
    static let aggHeight = 1
    static let bumpiness = 2
    static let maxHeight = 3
}

extension Board {
    struct BadnessMetrics: Equatable {
        let holes: Int
        let aggregateHeight: Int
        let bumpiness: Int
        let maxHeight: Int
    }

    /// Column heights / holes / bumpiness proxy. There is no gravity and
    /// slides go four ways, so this is an approximation of "how full and
    /// messy" the board is, not literal Tetris stack geometry.
    func badnessMetrics() -> BadnessMetrics {
        var heights = [Int](repeating: 0, count: Board.width)
        var holes = 0
        for c in 0..<Board.width {
            var topRow = -1
            for r in 0..<Board.height where cells[r][c].isFilled {
                topRow = r
                break
            }
            guard topRow >= 0 else { continue }
            heights[c] = Board.height - topRow
            for r in (topRow + 1)..<Board.height where cells[r][c].isEmpty {
                holes += 1
            }
        }
        let agg = heights.reduce(0, +)
        var bump = 0
        for c in 0..<(Board.width - 1) {
            bump += abs(heights[c] - heights[c + 1])
        }
        return BadnessMetrics(holes: holes,
                              aggregateHeight: agg,
                              bumpiness: bump,
                              maxHeight: heights.max() ?? 0)
    }

    /// Minimax spawn placement. For every valid (rotation, origin) candidate
    /// the AI simulates the player's best reply — any reachable rotation
    /// (kicked, like the real rotate button) followed by any of the four
    /// slides — and keeps the candidate whose best reply is worst for the
    /// player. Ties are broken randomly so the board doesn't lock into a
    /// repeating pattern. Returns `nil` only when nothing fits (game over),
    /// preserving the existing game-over path.
    func adversarialSpawnPlacement(for kind: PieceKind) -> PiecePlacement? {
        let candidates = placementCandidates(for: kind)
        guard !candidates.isEmpty else { return nil }

        let tempGroupID = (groups().keys.max() ?? -1) + 1

        var worstScore = Int.max
        var worst: [PiecePlacement] = []
        for cand in candidates {
            let placed = self.placed(cand, groupID: tempGroupID)
            let best = Self.playerBestScore(on: placed,
                                            kind: cand.kind,
                                            rotation: cand.rotation,
                                            origin: cand.origin,
                                            groupID: tempGroupID)
            if best < worstScore {
                worstScore = best
                worst = [cand]
            } else if best == worstScore {
                worst.append(cand)
            }
        }
        return worst.randomElement()
    }

    /// Highest player-favorability score over the player's reachable replies:
    /// rotate the just-placed piece 0…3 times (each step kicked, mirroring
    /// `GameEngine.rotateCurrentPiece`), then slide in any direction.
    private static func playerBestScore(on board: Board,
                                        kind: PieceKind,
                                        rotation: Rotation,
                                        origin: GridPosition,
                                        groupID: Int) -> Int {
        var best = Int.min
        var curBoard = board
        var curRot = rotation
        var curOrigin = origin

        for step in 0..<4 {
            for dir in SlideDirection.allCases {
                let slid = SlideEngine.slid(curBoard, toward: dir)
                let cleared = LineClearer.clearFullLines(slid)
                let s = score(of: cleared.board,
                              linesCleared: cleared.totalLineCount)
                if s > best { best = s }
            }
            if step == 3 { break }

            let nextRot = PieceRotation.nextRotation(curRot)
            let lifted = curBoard.removingGroup(groupID)
            guard let resolved = PieceRotation.resolve(
                on: lifted, kind: kind, to: nextRot,
                origin: curOrigin, removingGroup: nil
            ) else { break }
            curBoard = lifted.placed(kind.shape(for: resolved.rotation),
                                     kind: kind,
                                     at: resolved.origin,
                                     groupID: groupID)
            curRot = resolved.rotation
            curOrigin = resolved.origin
            if curRot == rotation { break } // completed a full cycle
        }
        return best
    }

    private static func score(of board: Board, linesCleared: Int) -> Int {
        let m = board.badnessMetrics()
        return AdversarialWeights.clear * linesCleared
             - AdversarialWeights.holes * m.holes
             - AdversarialWeights.aggHeight * m.aggregateHeight
             - AdversarialWeights.bumpiness * m.bumpiness
             - AdversarialWeights.maxHeight * m.maxHeight
    }
}
