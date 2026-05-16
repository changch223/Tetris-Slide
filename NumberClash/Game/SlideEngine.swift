import Foundation

/// Slides every piece group on the board toward the given direction until each
/// group hits a wall or another previously-settled group. Pieces are rigid:
/// every cell that shares a `groupID` moves together by the same vector.
///
/// Algorithm (research R-3, amended for rigid pieces):
///   1. Collect groups (groupID → [GridPosition]).
///   2. Sort groups so that the one closest to the destination wall settles
///      first. This guarantees that following groups stop the moment they
///      touch a settled group.
///   3. For each group, find the largest delta that keeps every member in
///      bounds and clear of already-settled cells. Place the group at that
///      delta in a fresh `settled` board.
///   4. Return the settled board.
enum SlideEngine {
    static func slid(_ board: Board, toward direction: SlideDirection) -> Board {
        let groups = board.groups()
        let sorted = groups.sorted { a, b in
            distanceToWall(of: a.value, direction: direction)
                < distanceToWall(of: b.value, direction: direction)
        }

        var settled = Array(
            repeating: Array(repeating: Cell.empty, count: Board.width),
            count: Board.height
        )

        for (groupID, positions) in sorted {
            // Resolve the original `Cell` instance for kind preservation.
            guard let firstCell = positions.first.map({ board.cell(at: $0) }),
                  case .filled(let kind, _) = firstCell else { continue }

            let delta = maxSlideDelta(
                positions: positions,
                settled: settled,
                direction: direction
            )
            for p in positions {
                let np = p.shifted(by: delta, direction: direction)
                settled[np.row][np.col] = .filled(kind: kind, groupID: groupID)
            }
        }

        return Board(cells: settled)
    }

    /// Distance from the group's edge to the destination wall. Used to order
    /// groups so the closest-to-wall settles first.
    private static func distanceToWall(of positions: [GridPosition],
                                       direction: SlideDirection) -> Int {
        switch direction {
        case .right: return Board.width  - 1 - (positions.map(\.col).max() ?? 0)
        case .left:  return positions.map(\.col).min() ?? 0
        case .down:  return Board.height - 1 - (positions.map(\.row).max() ?? 0)
        case .up:    return positions.map(\.row).min() ?? 0
        }
    }

    /// Maximum integer delta the group can move in `direction` without falling
    /// off the board or overlapping any cell currently filled in `settled`.
    private static func maxSlideDelta(positions: [GridPosition],
                                      settled: [[Cell]],
                                      direction: SlideDirection) -> Int {
        var d = 0
        while true {
            let next = d + 1
            var blocked = false
            for p in positions {
                let np = p.shifted(by: next, direction: direction)
                if !inBounds(np) || settled[np.row][np.col].isFilled {
                    blocked = true
                    break
                }
            }
            if blocked { break }
            d = next
        }
        return d
    }

    private static func inBounds(_ p: GridPosition) -> Bool {
        (0..<Board.height).contains(p.row) && (0..<Board.width).contains(p.col)
    }
}

private extension GridPosition {
    func shifted(by d: Int, direction: SlideDirection) -> GridPosition {
        switch direction {
        case .right: return GridPosition(row: row,         col: col + d)
        case .left:  return GridPosition(row: row,         col: col - d)
        case .down:  return GridPosition(row: row + d,     col: col)
        case .up:    return GridPosition(row: row - d,     col: col)
        }
    }
}
