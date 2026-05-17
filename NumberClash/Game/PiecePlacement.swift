import Foundation

struct PiecePlacement: Equatable {
    let kind: PieceKind
    let rotation: Rotation
    let origin: GridPosition
}

extension Board {
    /// Picks a random valid placement for `kind` on the current board: any
    /// rotation × any position where all four cells are empty. Returns nil
    /// when no such placement exists (game over).
    ///
    /// This restores 2048-style random spawning. Predictability comes from
    /// the **next-spawn ghost preview**: `GameEngine` pre-computes the
    /// position for the upcoming piece and the view layer draws a faint
    /// outline so the player sees where it will appear.
    func randomSpawnPlacement(for kind: PieceKind) -> PiecePlacement? {
        placementCandidates(for: kind).randomElement()
    }

    /// Enumerates every (rotation, position) pair where the piece can fit
    /// in the current board's empty cells. Currently used only by tests and
    /// the legacy random-spawn flow; production spawn logic uses
    /// `deterministicSpawnPlacement(for:)`.
    func placementCandidates(for kind: PieceKind) -> [PiecePlacement] {
        var out: [PiecePlacement] = []
        for (rotation, shape) in kind.uniqueShapes() {
            let maxRow = Board.height - shape.height
            let maxCol = Board.width - shape.width
            guard maxRow >= 0, maxCol >= 0 else { continue }
            for row in 0...maxRow {
                for col in 0...maxCol {
                    if canPlace(shape, at: GridPosition(row: row, col: col)) {
                        out.append(
                            PiecePlacement(kind: kind, rotation: rotation,
                                           origin: GridPosition(row: row, col: col))
                        )
                    }
                }
            }
        }
        return out
    }

    func canPlace(_ shape: PieceShape, at origin: GridPosition) -> Bool {
        for off in shape.cells {
            let p = GridPosition(row: origin.row + off.dRow, col: origin.col + off.dCol)
            if !isEmpty(at: p) { return false }
        }
        return true
    }
}
