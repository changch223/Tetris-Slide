import Foundation

struct GridPosition: Equatable, Hashable {
    let row: Int
    let col: Int
}

struct GridOffset: Equatable, Hashable {
    let dRow: Int
    let dCol: Int
}

enum SlideDirection: CaseIterable {
    case up, down, left, right
}

enum GameStatus: Equatable {
    case idle
    case playing
    case paused
    case gameOver(finalScore: Int, isNewHighScore: Bool)
}
