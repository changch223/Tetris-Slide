import Foundation
import AVFoundation

enum GameSound: String {
    case swipe    = "swipe"
    case lineClear = "clear"
    case tetris   = "tetris"
    case gameOver = "gameover"
}

protocol SoundPlayer {
    func play(_ sound: GameSound)
}

struct NoOpSoundPlayer: SoundPlayer {
    func play(_ sound: GameSound) {}
}

/// AVAudioPlayer-backed implementation. Loads the four short clips at init
/// time and replays each with `currentTime = 0` to avoid session warm-up
/// latency (research R-5).
final class AVAudioSoundPlayer: SoundPlayer {
    private let players: [GameSound: AVAudioPlayer]
    private let settings: SettingsStore

    init(settings: SettingsStore = UserDefaultsSettingsStore()) {
        self.settings = settings

        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        var built: [GameSound: AVAudioPlayer] = [:]
        for sound in [GameSound.swipe, .lineClear, .tetris, .gameOver] {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                built[sound] = player
            }
        }
        self.players = built
    }

    func play(_ sound: GameSound) {
        guard settings.load().soundEnabled, let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }
}
