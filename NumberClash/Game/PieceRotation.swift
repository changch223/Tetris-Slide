import Foundation

/// Shared rotation logic with wall-kick. Both the live game
/// (`GameEngine.rotateCurrentPiece`) and the adversarial placement search
/// resolve rotations through this so the AI predicts exactly what the player
/// can actually do.
///
/// Without a kick, a rotated shape only fit at the identical origin, so a
/// piece next to a wall or another block silently refused to rotate even
/// when shifting it one cell would have made room. The kick search tries the
/// current origin first, then nearby origins (Manhattan ≤ 2), nearest first.
enum PieceRotation {
    static let kickOffsets: [GridOffset] = [
        GridOffset(dRow: 0, dCol: 0),
        GridOffset(dRow: 0, dCol: -1), GridOffset(dRow: 0, dCol: 1),
        GridOffset(dRow: -1, dCol: 0), GridOffset(dRow: 1, dCol: 0),
        GridOffset(dRow: 0, dCol: -2), GridOffset(dRow: 0, dCol: 2),
        GridOffset(dRow: -2, dCol: 0), GridOffset(dRow: 2, dCol: 0),
        GridOffset(dRow: -1, dCol: -1), GridOffset(dRow: -1, dCol: 1),
        GridOffset(dRow: 1, dCol: -1), GridOffset(dRow: 1, dCol: 1),
    ]

    static func nextRotation(_ r: Rotation) -> Rotation {
        switch r {
        case .deg0:   return .deg90
        case .deg90:  return .deg180
        case .deg180: return .deg270
        case .deg270: return .deg0
        }
    }

    /// Resolves rotating `kind` to `rotation`, kicking around `origin` until
    /// the shape fits on `board`. Pass the rotating piece's `groupID` to lift
    /// it off the board before testing (live game); pass `nil` when the board
    /// already excludes it (AI simulation). Returns the settled
    /// (rotation, origin) or `nil` if no kick offset fits.
    static func resolve(on board: Board,
                        kind: PieceKind,
                        to rotation: Rotation,
                        origin: GridPosition,
                        removingGroup groupID: Int?) -> (rotation: Rotation, origin: GridPosition)? {
        let target = groupID.map { board.removingGroup($0) } ?? board
        let shape = kind.shape(for: rotation)
        for off in kickOffsets {
            let cand = GridPosition(row: origin.row + off.dRow,
                                    col: origin.col + off.dCol)
            if target.canPlace(shape, at: cand) {
                return (rotation, cand)
            }
        }

        // The straight I-piece needs up to a 3-cell shift to flip when it's
        // jammed against a wall — more than the ±2 kick set can reach. So for
        // I, fall back to the nearest valid origin anywhere on the board: it
        // always rotates as long as the flipped bar fits somewhere.
        if kind == .I {
            let maxRow = Board.height - shape.height
            let maxCol = Board.width - shape.width
            guard maxRow >= 0, maxCol >= 0 else { return nil }
            var best: GridPosition?
            var bestDistance = Int.max
            for r in 0...maxRow {
                for c in 0...maxCol {
                    let cand = GridPosition(row: r, col: c)
                    guard target.canPlace(shape, at: cand) else { continue }
                    let d = abs(r - origin.row) + abs(c - origin.col)
                    if d < bestDistance {
                        bestDistance = d
                        best = cand
                    }
                }
            }
            if let best { return (rotation, best) }
        }
        return nil
    }
}
