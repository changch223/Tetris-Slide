import Foundation

enum ScoreCalculator {
    static let placementBonus: Int = 1

    static func lineClearPoints(for clearedRows: Int) -> Int {
        switch clearedRows {
        case 0: return 0
        case 1: return 100
        case 2: return 300
        case 3: return 500
        case 4: return 800
        default: return 800
        }
    }
}
