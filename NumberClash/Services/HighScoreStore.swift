import Foundation

protocol HighScoreStore {
    func current() -> Int
    @discardableResult
    func recordIfHigher(_ score: Int) -> Bool
}

/// Replaced with `UserDefaultsHighScoreStore` in T035 (User Story 2).
struct NoOpHighScoreStore: HighScoreStore {
    func current() -> Int { 0 }
    func recordIfHigher(_ score: Int) -> Bool { false }
}

/// Implemented in T035 (User Story 2). Defined here to satisfy `GameEngine`'s
/// default initializer at MVP time.
final class UserDefaultsHighScoreStore: HighScoreStore {
    static let key = "tetris2048.highScore"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func current() -> Int {
        defaults.integer(forKey: Self.key)
    }

    @discardableResult
    func recordIfHigher(_ score: Int) -> Bool {
        let prev = current()
        guard score > prev else { return false }
        defaults.set(score, forKey: Self.key)
        return true
    }
}
