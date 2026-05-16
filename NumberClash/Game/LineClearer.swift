import Foundation

enum LineClearer {
    struct Result: Equatable {
        let board: Board
        let clearedRows: [Int]
        let clearedColumns: [Int]

        var totalLineCount: Int { clearedRows.count + clearedColumns.count }

        /// Every cell position that just got cleared. Used by the view layer
        /// to drive the fade-out + scale animation.
        var clearedCells: Set<GridPosition> {
            var out = Set<GridPosition>()
            for r in clearedRows {
                for c in 0..<Board.width {
                    out.insert(GridPosition(row: r, col: c))
                }
            }
            for c in clearedColumns {
                for r in 0..<Board.height {
                    out.insert(GridPosition(row: r, col: c))
                }
            }
            return out
        }
    }

    /// Clears every horizontal row and every vertical column that is fully
    /// filled. Cells that survive keep their original `groupID` (a partially
    /// cleared piece keeps the rest of its cells grouped — see Cell.swift).
    static func clearFullLines(_ board: Board) -> Result {
        let rows = board.fullRows()
        let cols = board.fullColumns()
        let cleared = board.cleared(rows: rows, columns: cols)
        return Result(board: cleared, clearedRows: rows, clearedColumns: cols)
    }
}
