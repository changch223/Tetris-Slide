import SwiftUI

struct NextPieceView: View {
    let kind: PieceKind

    private static let preview: Int = 4

    var body: some View {
        let shape = kind.shape(for: .deg0)
        let cells = Set(shape.cells)
        VStack(spacing: 2) {
            ForEach(0..<Self.preview, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<Self.preview, id: \.self) { col in
                        let off = GridOffset(dRow: row, dCol: col)
                        let isFilled = cells.contains(off)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isFilled ? Color(kind.colorAssetName) : Color.clear)
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
        .padding(6)
        .background(Color("BoardBackground").opacity(0.4))
        .cornerRadius(6)
    }
}

#Preview {
    HStack {
        ForEach(PieceKind.allCases, id: \.self) { k in
            NextPieceView(kind: k)
        }
    }
}
