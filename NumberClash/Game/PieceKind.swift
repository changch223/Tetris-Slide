import Foundation

enum PieceKind: String, CaseIterable {
    case I, O, T, S, Z, J, L

    var colorAssetName: String {
        switch self {
        case .I: return "PieceI"
        case .O: return "PieceO"
        case .T: return "PieceT"
        case .S: return "PieceS"
        case .Z: return "PieceZ"
        case .J: return "PieceJ"
        case .L: return "PieceL"
        }
    }
}
