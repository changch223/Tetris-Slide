import Foundation

/// A single cell on the board.
///
/// `filled` cells carry both the piece kind (for color) and a `groupID` that
/// identifies which spawned piece they originated from. Cells with the same
/// `groupID` move together as one rigid unit during a swipe. `groupID` is a
/// monotonically increasing integer assigned by `GameEngine` at spawn time.
enum Cell: Equatable {
    case empty
    case filled(kind: PieceKind, groupID: Int)

    var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }

    var isFilled: Bool { !isEmpty }

    var groupID: Int? {
        if case .filled(_, let id) = self { return id }
        return nil
    }

    var kind: PieceKind? {
        if case .filled(let kind, _) = self { return kind }
        return nil
    }
}
