import Foundation

struct Board: Equatable {
    static let width = 10
    static let height = 10

    private(set) var cells: [[Cell]]

    init() {
        self.cells = Array(
            repeating: Array(repeating: .empty, count: Board.width),
            count: Board.height
        )
    }

    init(cells: [[Cell]]) {
        precondition(cells.count == Board.height)
        precondition(cells.allSatisfy { $0.count == Board.width })
        self.cells = cells
    }

    func cell(at p: GridPosition) -> Cell {
        cells[p.row][p.col]
    }

    func isEmpty(at p: GridPosition) -> Bool {
        guard isInBounds(p) else { return false }
        return cells[p.row][p.col].isEmpty
    }

    func isInBounds(_ p: GridPosition) -> Bool {
        (0..<Board.height).contains(p.row) && (0..<Board.width).contains(p.col)
    }

    /// Places a piece of `kind` at `origin` with cells from `shape`, tagging
    /// every newly-placed cell with the same `groupID` so they slide together
    /// as a rigid unit (FR-004 amended: pieces keep their shape).
    func placed(_ shape: PieceShape, kind: PieceKind, at origin: GridPosition,
                groupID: Int) -> Board {
        var next = self
        for off in shape.cells {
            let p = GridPosition(row: origin.row + off.dRow, col: origin.col + off.dCol)
            next.cells[p.row][p.col] = .filled(kind: kind, groupID: groupID)
        }
        return next
    }

    func placed(_ placement: PiecePlacement, groupID: Int) -> Board {
        let shape = placement.kind.shape(for: placement.rotation)
        return placed(shape, kind: placement.kind, at: placement.origin, groupID: groupID)
    }

    /// All horizontal rows that are completely filled.
    func fullRows() -> [Int] {
        (0..<Board.height).filter { row in
            cells[row].allSatisfy { $0.isFilled }
        }
    }

    /// All vertical columns that are completely filled.
    func fullColumns() -> [Int] {
        (0..<Board.width).filter { col in
            (0..<Board.height).allSatisfy { row in cells[row][col].isFilled }
        }
    }

    /// Clears every cell in the given rows and columns. Surviving cells
    /// retain their original `groupID`, so a partially-cleared piece keeps
    /// its remaining cells grouped together for future slides.
    func cleared(rows: [Int], columns: [Int]) -> Board {
        guard !rows.isEmpty || !columns.isEmpty else { return self }
        var next = self
        let rowSet = Set(rows)
        let colSet = Set(columns)
        for r in 0..<Board.height {
            for c in 0..<Board.width {
                if rowSet.contains(r) || colSet.contains(c) {
                    next.cells[r][c] = .empty
                }
            }
        }
        return next
    }

    var emptyCellCount: Int {
        cells.reduce(0) { acc, row in acc + row.filter { $0.isEmpty }.count }
    }

    /// Whether `placement` can still be applied as-is to the current board.
    /// Used to validate a planned (preview) spawn after the board has changed
    /// from a swipe.
    func placementIsValid(_ placement: PiecePlacement) -> Bool {
        let shape = placement.kind.shape(for: placement.rotation)
        for off in shape.cells {
            let p = GridPosition(row: placement.origin.row + off.dRow,
                                 col: placement.origin.col + off.dCol)
            if !isInBounds(p) || !cells[p.row][p.col].isEmpty { return false }
        }
        return true
    }

    /// Cells that the placement would occupy. Used by the view layer to draw
    /// the planned spawn preview as a ghost outline.
    func cells(of placement: PiecePlacement) -> Set<GridPosition> {
        let shape = placement.kind.shape(for: placement.rotation)
        var out: Set<GridPosition> = []
        for off in shape.cells {
            out.insert(GridPosition(row: placement.origin.row + off.dRow,
                                    col: placement.origin.col + off.dCol))
        }
        return out
    }

    /// Returns a copy of the board with every cell of `groupID` set to empty.
    /// Used by the rotation flow: lift the current piece, validate the new
    /// rotation against the rest of the board, then place the rotated shape.
    func removingGroup(_ groupID: Int) -> Board {
        var next = self
        for r in 0..<Board.height {
            for c in 0..<Board.width {
                if case .filled(_, let g) = next.cells[r][c], g == groupID {
                    next.cells[r][c] = .empty
                }
            }
        }
        return next
    }

    /// Returns every distinct group on the board with the positions of its
    /// member cells.
    func groups() -> [Int: [GridPosition]] {
        var out: [Int: [GridPosition]] = [:]
        for r in 0..<Board.height {
            for c in 0..<Board.width {
                if case .filled(_, let id) = cells[r][c] {
                    out[id, default: []].append(GridPosition(row: r, col: c))
                }
            }
        }
        return out
    }

    /// Unifies every 4-connected region of **same-kind** filled cells into a
    /// single group, so that once two blocks of the same colour touch they
    /// move together as one rigid shape from then on. Each region reuses the
    /// smallest original `groupID` it contains (stable — no ID growth, and a
    /// lone piece keeps its own ID). Different colours never merge even when
    /// adjacent; diagonal-only contact does not merge (4-connectivity).
    func mergingAdjacentSameKind() -> Board {
        var newCells = cells
        var visited = Array(
            repeating: Array(repeating: false, count: Board.width),
            count: Board.height
        )
        let neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        for r in 0..<Board.height {
            for c in 0..<Board.width {
                guard !visited[r][c],
                      case .filled(let kind, _) = cells[r][c] else { continue }

                var component: [GridPosition] = []
                var minID = Int.max
                var stack = [GridPosition(row: r, col: c)]
                while let p = stack.popLast() {
                    if visited[p.row][p.col] { continue }
                    guard case .filled(let k, let id) = cells[p.row][p.col],
                          k == kind else { continue }
                    visited[p.row][p.col] = true
                    component.append(p)
                    minID = min(minID, id)
                    for (dr, dc) in neighbors {
                        let nr = p.row + dr, nc = p.col + dc
                        guard nr >= 0, nr < Board.height,
                              nc >= 0, nc < Board.width,
                              !visited[nr][nc],
                              case .filled(let k2, _) = cells[nr][nc],
                              k2 == kind else { continue }
                        stack.append(GridPosition(row: nr, col: nc))
                    }
                }
                for p in component {
                    newCells[p.row][p.col] = .filled(kind: kind, groupID: minID)
                }
            }
        }
        return Board(cells: newCells)
    }

    /// For each existing group, examines whether its surviving cells form a
    /// single 4-connected component. If a group is split into N > 1
    /// components (e.g., by a line clear cutting through it), each component
    /// is reassigned a fresh `groupID` so it slides independently from now
    /// on. Single-component groups keep their original `groupID`.
    ///
    /// Returns the rewritten board and the next free `groupID` after any new
    /// IDs were assigned.
    func splittingDisconnectedGroups(nextGroupID: Int) -> (board: Board, nextGroupID: Int) {
        var newCells = cells
        var nextID = nextGroupID

        for (_, positions) in groups() {
            let components = Self.connectedComponents(in: positions)
            guard components.count > 1 else { continue }
            // Re-tag every component with a fresh ID so adjacency to other
            // unrelated cells doesn't create accidental merges.
            for component in components {
                let id = nextID
                nextID += 1
                for p in component {
                    if case .filled(let kind, _) = cells[p.row][p.col] {
                        newCells[p.row][p.col] = .filled(kind: kind, groupID: id)
                    }
                }
            }
        }
        return (Board(cells: newCells), nextID)
    }

    /// 4-connected components inside the given positions. Two positions are
    /// in the same component iff there is a path of orthogonally-adjacent
    /// cells between them, using only positions in the input set.
    private static func connectedComponents(in positions: [GridPosition]) -> [[GridPosition]] {
        let posSet = Set(positions)
        var visited: Set<GridPosition> = []
        var components: [[GridPosition]] = []
        let neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        for start in positions where !visited.contains(start) {
            var comp: [GridPosition] = []
            var stack: [GridPosition] = [start]
            while let p = stack.popLast() {
                if !visited.insert(p).inserted { continue }
                comp.append(p)
                for (dr, dc) in neighbors {
                    let np = GridPosition(row: p.row + dr, col: p.col + dc)
                    if posSet.contains(np) && !visited.contains(np) {
                        stack.append(np)
                    }
                }
            }
            components.append(comp)
        }
        return components
    }
}
