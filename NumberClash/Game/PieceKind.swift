import Foundation

/// The 7 piece kinds (case names kept for compatibility — the shapes
/// themselves were redesigned to non-tetromino polyominoes; see PieceShape).
/// Each kind is rendered with one of two brand colors:
///   - I, O (3-cell triominoes)  →  PiecePrimary  (indigo)
///   - T, S, Z, J, L (5-cell pentominoes) → PieceSecondary  (coral)
enum PieceKind: String, CaseIterable {
    case I, O, T, S, Z, J, L

    var colorAssetName: String {
        switch self {
        case .I, .O:
            return "PiecePrimary"
        case .T, .S, .Z, .J, .L:
            return "PieceSecondary"
        }
    }
}
