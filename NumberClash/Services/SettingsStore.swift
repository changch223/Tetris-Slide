import Foundation

struct Settings: Codable, Equatable {
    var soundEnabled: Bool
    var hapticsEnabled: Bool

    static let defaults = Settings(soundEnabled: true, hapticsEnabled: true)
}

protocol SettingsStore {
    func load() -> Settings
    func save(_ settings: Settings)
}

final class UserDefaultsSettingsStore: SettingsStore {
    static let soundKey   = "tetris2048.settings.soundEnabled"
    static let hapticsKey = "tetris2048.settings.hapticsEnabled"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Settings {
        Settings(
            soundEnabled:   defaultsBool(forKey: Self.soundKey,   default: true),
            hapticsEnabled: defaultsBool(forKey: Self.hapticsKey, default: true)
        )
    }

    func save(_ settings: Settings) {
        defaults.set(settings.soundEnabled,   forKey: Self.soundKey)
        defaults.set(settings.hapticsEnabled, forKey: Self.hapticsKey)
    }

    private func defaultsBool(forKey key: String, default: Bool) -> Bool {
        if defaults.object(forKey: key) == nil { return `default` }
        return defaults.bool(forKey: key)
    }
}
