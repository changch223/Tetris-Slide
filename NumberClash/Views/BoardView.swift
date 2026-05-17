import SwiftUI

struct BoardView: View {
    let board: Board
    let clearingCells: Set<GridPosition>
    /// Cells that the upcoming spawn will occupy + the piece kind, so the
    /// view can draw a ghost preview.
    let plannedSpawn: (kind: PieceKind, positions: Set<GridPosition>)?
    /// Cells of a ghost whose turn was just skipped (red-✕ blink).
    let skippedCells: Set<GridPosition>
    /// Cells of the just-placed piece (bright outline).
    let currentCells: Set<GridPosition>
    let onSwipe: (SlideDirection) -> Void

    init(board: Board,
         clearingCells: Set<GridPosition> = [],
         plannedSpawn: (kind: PieceKind, positions: Set<GridPosition>)? = nil,
         skippedCells: Set<GridPosition> = [],
         currentCells: Set<GridPosition> = [],
         onSwipe: @escaping (SlideDirection) -> Void) {
        self.board = board
        self.clearingCells = clearingCells
        self.plannedSpawn = plannedSpawn
        self.skippedCells = skippedCells
        self.currentCells = currentCells
        self.onSwipe = onSwipe
    }

    private static let swipeThreshold: CGFloat = 30
    private static let axisDominanceRatio: CGFloat = 1.5

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let spacing: CGFloat = 4
            let cellSide = (side - spacing * CGFloat(Board.width + 1)) / CGFloat(Board.width)
            VStack(spacing: spacing) {
                ForEach(0..<Board.height, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<Board.width, id: \.self) { col in
                            let pos = GridPosition(row: row, col: col)
                            CellView(
                                cell: board.cells[row][col],
                                isClearing: clearingCells.contains(pos),
                                ghostKind: ghostKind(at: pos),
                                isSkipped: skippedCells.contains(pos),
                                isCurrent: currentCells.contains(pos)
                            )
                            .frame(width: cellSide, height: cellSide)
                        }
                    }
                }
            }
            .padding(spacing)
            .frame(width: side, height: side)
            .background(Color("BoardBackground"))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(swipeGesture)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("BOARD_A11Y_LABEL"))
        .accessibilityAction(named: Text("KEY_A11Y_SWIPE_UP"))    { onSwipe(.up) }
        .accessibilityAction(named: Text("KEY_A11Y_SWIPE_DOWN"))  { onSwipe(.down) }
        .accessibilityAction(named: Text("KEY_A11Y_SWIPE_LEFT"))  { onSwipe(.left) }
        .accessibilityAction(named: Text("KEY_A11Y_SWIPE_RIGHT")) { onSwipe(.right) }
    }

    private func ghostKind(at pos: GridPosition) -> PieceKind? {
        guard let plan = plannedSpawn, plan.positions.contains(pos) else { return nil }
        return plan.kind
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                let absDx = abs(dx)
                let absDy = abs(dy)
                guard max(absDx, absDy) >= Self.swipeThreshold else { return }
                if absDx > absDy * Self.axisDominanceRatio {
                    onSwipe(dx > 0 ? .right : .left)
                } else if absDy > absDx * Self.axisDominanceRatio {
                    onSwipe(dy > 0 ? .down : .up)
                }
            }
    }
}
