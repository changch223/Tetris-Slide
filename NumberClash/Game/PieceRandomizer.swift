import Foundation

protocol PieceRandomizer {
    func next() -> PieceKind
}

struct SystemRandomPieceRandomizer: PieceRandomizer {
    func next() -> PieceKind {
        PieceKind.allCases.randomElement()!
    }
}

/// Test-only deterministic randomizer that yields a fixed sequence.
/// When the sequence is exhausted, it loops.
final class DeterministicRandomizer: PieceRandomizer {
    private let sequence: [PieceKind]
    private var index = 0

    init(_ sequence: [PieceKind]) {
        precondition(!sequence.isEmpty)
        self.sequence = sequence
    }

    func next() -> PieceKind {
        defer { index = (index + 1) % sequence.count }
        return sequence[index]
    }
}
