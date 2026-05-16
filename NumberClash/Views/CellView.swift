import SwiftUI

struct CellView: View {
    let cell: Cell
    let isClearing: Bool
    /// When the cell is empty, an upcoming-spawn ghost is drawn in the
    /// piece's color at low opacity to hint at where the next piece will
    /// land. Setting this to `nil` while the previous value was non-nil
    /// fades the ghost out; setting it to a new kind fades a new ghost in.
    let ghostKind: PieceKind?
    /// True for the cells of a ghost whose turn was just skipped — drawn as
    /// a blinking red ✕ so the player sees the piece was NOT placed.
    let isSkipped: Bool
    /// True for the cells of the just-placed piece (the one the player will
    /// move with the next swipe) so it stands out from older blocks.
    let isCurrent: Bool

    init(cell: Cell,
         isClearing: Bool = false,
         ghostKind: PieceKind? = nil,
         isSkipped: Bool = false,
         isCurrent: Bool = false) {
        self.cell = cell
        self.isClearing = isClearing
        self.ghostKind = ghostKind
        self.isSkipped = isSkipped
        self.isCurrent = isCurrent
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(fillColor)
                .aspectRatio(1, contentMode: .fit)

            // Just-placed piece: bright outline so it's obvious which block
            // the next swipe will move (especially after a skip / merges).
            if isCurrent, cell.isFilled {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.white, lineWidth: 2.5)
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: .white.opacity(0.9), radius: 3)
                    .opacity(currentPulse ? 1.0 : 0.55)
                    .onAppear { currentPulse = true }
                    .onDisappear { currentPulse = false }
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                               value: currentPulse)
                    .transition(.opacity)
            }

            // Ghost layer: always laid out so SwiftUI can animate
            // opacity/scale changes when the planned spawn moves.
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(ghostStroke, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ghostFill)
                )
                .aspectRatio(1, contentMode: .fit)
                .opacity(showGhost ? 1.0 : 0.0)
                .scaleEffect(showGhost ? 1.0 : 0.7)
                .animation(.easeInOut(duration: 0.3), value: ghostKind)
                .animation(.easeInOut(duration: 0.3), value: cell)

            // Skipped-turn marker: blinking red border + ✕.
            if isSkipped {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.red, lineWidth: 2.5)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red.opacity(0.22))
                    )
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Color.red)
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .opacity(skipBlink ? 1.0 : 0.25)
                    .onAppear { skipBlink = true }
                    .onDisappear { skipBlink = false }
                    .animation(.easeInOut(duration: 0.28).repeatForever(autoreverses: true),
                               value: skipBlink)
                    .transition(.opacity)
            }

            // Line-clear flash: a bright pulse so it's obvious which row /
            // column completed before the cells fade away.
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .aspectRatio(1, contentMode: .fit)
                .opacity(isClearing ? 0.85 : 0.0)
                .animation(.easeOut(duration: 0.3), value: isClearing)
        }
        .scaleEffect(isClearing ? 1.2 : 1.0)
        .opacity(isClearing ? 0.0 : 1.0)
        .animation(.easeOut(duration: 0.32), value: isClearing)
        .animation(.easeOut(duration: 0.18), value: fillColor)
    }

    @State private var skipBlink = false
    @State private var currentPulse = false

    private var showGhost: Bool {
        cell.isEmpty && ghostKind != nil
    }

    private var ghostStroke: Color {
        ghostKind.map { Color($0.colorAssetName) } ?? Color.clear
    }

    private var ghostFill: Color {
        ghostKind.map { Color($0.colorAssetName).opacity(0.18) } ?? Color.clear
    }

    private var fillColor: Color {
        switch cell {
        case .empty:
            return Color("BoardCellEmpty")
        case .filled(let kind, _):
            return Color(kind.colorAssetName)
        }
    }
}

#Preview {
    HStack {
        CellView(cell: .empty)
        CellView(cell: .empty, ghostKind: .T)
        ForEach(PieceKind.allCases, id: \.self) { kind in
            CellView(cell: .filled(kind: kind, groupID: 0))
        }
    }
    .padding()
}
