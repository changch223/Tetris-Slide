import Foundation
import UIKit

enum GameHaptic {
    case swipeLight
    case lineClearMedium
    case tetrisStrong
    case gameOverError
}

protocol HapticsPlayer {
    func play(_ haptic: GameHaptic)
}

struct NoOpHapticsPlayer: HapticsPlayer {
    func play(_ haptic: GameHaptic) {}
}

/// UIFeedbackGenerator-backed implementation (research R-6). Pre-instantiated
/// generators are kept and re-used; `prepare()` is called eagerly to reduce
/// engine spin-up latency.
final class UIFeedbackHapticsPlayer: HapticsPlayer {
    private let light  = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let notify = UINotificationFeedbackGenerator()
    private let settings: SettingsStore

    init(settings: SettingsStore = UserDefaultsSettingsStore()) {
        self.settings = settings
        light.prepare()
        medium.prepare()
        notify.prepare()
    }

    func play(_ haptic: GameHaptic) {
        guard settings.load().hapticsEnabled else { return }
        switch haptic {
        case .swipeLight:        light.impactOccurred()
        case .lineClearMedium:   medium.impactOccurred()
        case .tetrisStrong:      notify.notificationOccurred(.success)
        case .gameOverError:     notify.notificationOccurred(.error)
        }
    }
}
